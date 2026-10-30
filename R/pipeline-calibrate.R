#' Pipeline stage: calibration
#'
#' Fits a unidimensional IRT model to the responses in a pipeline and checks
#' whether the items are fit to enter an item bank. The checks (thresholds
#' from [mv_rules()]):
#'
#' * `not_converged` (block): the estimation did not converge.
#' * `model_fit` (review): M2-based RMSEA above `rmsea` or CFI below `cfi`,
#'   which suggests more than one dimension or a poorly fitting model.
#' * `local_dependence` (review): pairs of items whose absolute Q3 residual
#'   correlation exceeds `q3`.
#' * `item_misfit` (review): S-X2 item fit p-value below `fit_alpha` after
#'   `fit_adjust` adjustment.
#' * `parameter_range` (review): discrimination outside `a_min` to `a_max`,
#'   an absolute difficulty above `b_max`, or a guessing parameter above
#'   `c_max`.
#' * `dif_large` (block) and `dif_moderate` (review): differential item
#'   functioning between the groups given to [add_responses()], classified
#'   with the ETS A/B/C rules. 0/1 items use the Mantel-Haenszel D-DIF
#'   statistic (category C: |D-DIF| at least `dif_c` and a significant
#'   Mantel-Haenszel test; B: at least `dif_b` and significant). Polytomous
#'   items use the standardized mean difference divided by the item's
#'   standard deviation with the Mantel test (`dif_poly_c`, `dif_poly_b`).
#'   Respondents are matched on their total score; with more than two groups
#'   each group is compared with the reference group.
#' * `low_reliability` (review): marginal reliability below `reliability`.
#' * `person_misfit` (info): the share of respondents whose Zh (lz) person-fit
#'   statistic is below `person_misfit`; they are listed in `p$persons`.
#'
#' @param p a pipeline with responses from [add_responses()].
#' @param model the item type passed to [mirt::mirt()], such as `"Rasch"`,
#'   `"2PL"`, `"3PL"`, `"graded"` or `"gpcm"`, or `"auto"` to let
#'   [select_model()] choose.
#' @param dif logical; test for DIF. Defaults to `TRUE` when the pipeline has
#'   a grouping variable.
#' @param reference the reference group for DIF. Defaults to the largest
#'   group.
#' @param ... further arguments passed to [mirt::mirt()].
#' @return The pipeline with the fitted model (`p$model`), the DIF results
#'   (`p$dif`) and the calibration flags added.
#' @examples
#' \donttest{
#' p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key,
#'                    group = "language")
#' p <- calibrate(p, model = "3PL")
#' flags(p, stage = "calibration")
#' }
#' @export
calibrate <- function(p, model = "auto", dif = NULL, reference = NULL, ...) {
  check_pipeline(p)
  cl <- match.call()
  if (is.null(p$data)) stop("Add responses with add_responses() first.", call. = FALSE)
  enforce_gate(p, "calibration")
  resp <- p$data$responses
  sel <- NULL
  if (identical(model, "auto")) {
    sel <- select_model(resp, verbose = FALSE, ...)
    mod <- sel$best
    how <- sprintf("%s (chosen by %s)", sel$best_name, sel$criterion)
  } else {
    mod <- mirt::mirt(resp, 1, itemtype = model, verbose = FALSE, ...)
    how <- model
  }
  if (is.null(dif)) dif <- !is.null(p$data$group)
  if (dif && is.null(p$data$group))
    stop("DIF needs a `group` in add_responses().", call. = FALSE)
  dif_tab <- if (dif) mh_dif(resp, p$data$group, reference, p$rules) else NULL

  checks <- calibration_checks(mod, dif_tab, p$data$id, p$rules)
  p$model <- mod
  p$selection <- sel
  p$dif <- dif_tab
  p$persons <- rbind(p$persons[p$persons$check != "person_misfit", , drop = FALSE],
                     checks$persons)
  p <- set_stage_flags(p, "calibration", checks$flags)
  rxx <- checks$reliability
  p <- set_stage(p, "calibration", "done",
                 sprintf("%s, %s%s", how,
                         if (isTRUE(mirt::extract.mirt(mod, "converged"))) "converged" else "NOT converged",
                         if (!is.na(rxx)) sprintf(", reliability %.2f", rxx) else ""))
  p$link <- NULL
  p$forms <- NULL
  for (s in c("linking", "forms", "reporting"))
    if (p$stages$status[p$stages$stage == s] != "not run")
      p <- set_stage(p, s, "needs rerun", "model changed since this stage ran")
  p <- log_event(p, "calibrate", how)
  p <- add_code(p, cl)
  report_stage_flags(p, "calibration")
  p
}

calibration_checks <- function(mod, dif_tab, ids, rules) {
  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("calibration", ...)
  nms <- item_names(mod)

  if (!isTRUE(mirt::extract.mirt(mod, "converged")))
    add("not_converged", "test", "not converged", "estimation must converge", "block",
        "Try another model, more iterations (technical = list(NCYCLES = 2000)), or check the data.")

  g <- safe(as.data.frame(glance(mod)))
  if (!is.null(g) && !is.null(g$RMSEA) && !is.na(g$RMSEA)) {
    bad <- g$RMSEA > rules$rmsea || (!is.null(g$CFI) && !is.na(g$CFI) && g$CFI < rules$cfi)
    if (bad)
      add("model_fit", "test", sprintf("RMSEA = %.3f, CFI = %.3f", g$RMSEA, g$CFI),
          sprintf("RMSEA > %s or CFI < %s", rules$rmsea, rules$cfi), "review",
          "The test may measure more than one dimension; compare with a two-factor model (select_model(dims = 1:2)).")
  }

  q3 <- safe(mirt::residuals(mod, type = "Q3", verbose = FALSE))
  if (is.matrix(q3)) {
    idx <- which(abs(q3) > rules$q3 & upper.tri(q3), arr.ind = TRUE)
    if (nrow(idx))
      add("local_dependence", paste(nms[idx[, 1]], nms[idx[, 2]], sep = " & "),
          sprintf("Q3 = %.2f", q3[idx]), sprintf("|Q3| > %s", rules$q3), "review",
          "The items may share a stimulus or cue each other; review them together or treat them as a testlet.")
  }

  it <- safe(as.data.frame(item_table(mod, p_adjust = rules$fit_adjust, alpha = rules$fit_alpha)))
  if (!is.null(it) && !is.null(it$p.value)) {
    mf <- !is.na(it$p.value) & it$p.value < rules$fit_alpha
    add("item_misfit", it$item[mf], sprintf("S-X2 = %.1f, adjusted p = %s", it$S_X2[mf],
                                            fmt_p(it$p.value[mf])),
        sprintf("adjusted p < %s (%s)", rules$fit_alpha, rules$fit_adjust), "review",
        "Look at the item's empirical curve (gg_empirical()) and content; revise or drop it.")
  }

  pr <- parameter_issues(mod, rules)
  add("parameter_range", pr$item, pr$value,
      sprintf("a in [%s, %s], |b| <= %s, c <= %s", rules$a_min, rules$a_max, rules$b_max,
              rules$c_max), "review",
      "Extreme parameters make scores unstable; check the item and consider a simpler model.")

  if (!is.null(dif_tab) && nrow(dif_tab)) {
    for (cat_ in c("C", "B")) {
      d <- dif_tab[dif_tab$ets == cat_, , drop = FALSE]
      add(if (cat_ == "C") "dif_large" else "dif_moderate", d$item,
          sprintf("%s = %.2f, %s vs %s (favours %s)", d$statistic, d$effect, d$focal,
                  d$reference, ifelse(d$favours == "focal", d$focal, d$reference)),
          sprintf("ETS category %s", cat_), if (cat_ == "C") "block" else "review",
          if (cat_ == "C") "Have a fairness panel review the item; drop or revise it unless the difference is construct-relevant."
          else "Review the item for content that may favour one group.")
    }
  }

  rxx <- safe(mirt::marginal_rxx(mod), NA_real_)
  if (!is.na(rxx) && rxx < rules$reliability)
    add("low_reliability", "test", sprintf("marginal reliability = %.2f", rxx),
        sprintf("reliability < %s", rules$reliability), "review",
        "Scores are less precise than planned; add items or report wider score bands.")

  persons <- empty_person_flags()
  pf <- safe(mirt::personfit(mod))
  if (!is.null(pf) && !is.null(pf$Zh)) {
    rows <- which(pf$Zh < rules$person_misfit)
    if (length(rows)) {
      persons <- data.frame(row = rows, id = ids[rows], check = "person_misfit",
                            value = sprintf("Zh = %.2f", pf$Zh[rows]), stringsAsFactors = FALSE)
      add("person_misfit", sprintf("%d respondents", length(rows)),
          sprintf("%.1f%% of respondents", 100 * length(rows) / nrow(pf)),
          sprintf("Zh < %s", rules$person_misfit), "info",
          "About 2.5% are expected by chance; many more may point to guessing, cheating or careless responding. See p$persons.")
    }
  }

  list(flags = if (length(out)) do.call(rbind, out) else empty_flags(),
       persons = persons, reliability = rxx)
}

parameter_issues <- function(mod, rules) {
  co <- safe(mirt::coef(mod, IRTpars = TRUE, simplify = TRUE)$items)
  if (is.null(co)) {
    a <- as.numeric(item_slopes(mod))
    co <- cbind(a = a)
    rownames(co) <- item_names(mod)
  }
  co <- as.matrix(co)
  issues <- vapply(seq_len(nrow(co)), function(j) {
    msg <- character(0)
    a <- if ("a" %in% colnames(co)) co[j, "a"] else NA
    if (!is.na(a) && (a < rules$a_min || a > rules$a_max)) msg <- c(msg, sprintf("a = %.2f", a))
    bcols <- grep("^b[0-9]*$", colnames(co))
    b <- co[j, bcols]
    b <- b[!is.na(b)]
    if (length(b) && any(abs(b) > rules$b_max))
      msg <- c(msg, sprintf("b = %.2f", b[which.max(abs(b))]))
    g <- if ("g" %in% colnames(co)) co[j, "g"] else NA
    if (!is.na(g) && g > rules$c_max) msg <- c(msg, sprintf("c = %.2f", g))
    paste(msg, collapse = ", ")
  }, character(1))
  hit <- nzchar(issues)
  list(item = rownames(co)[hit], value = issues[hit])
}

# Mantel-Haenszel DIF (0/1 items) and the standardized mean difference with
# Mantel's test (polytomous items), matching on the total score. Each group is
# compared with the reference group and classified with the ETS A/B/C rules.
mh_dif <- function(resp, group, reference = NULL, rules) {
  group <- as.character(group)
  keep <- !is.na(group)
  resp <- resp[keep, , drop = FALSE]
  group <- group[keep]
  sizes <- sort(table(group), decreasing = TRUE)
  if (length(sizes) < 2L) stop("DIF needs at least two groups.", call. = FALSE)
  if (is.null(reference)) reference <- names(sizes)[1]
  if (!reference %in% names(sizes))
    stop(sprintf("Reference group \"%s\" is not in the data.", reference), call. = FALSE)
  total <- rowSums(resp, na.rm = TRUE)
  rows <- list()
  for (focal in setdiff(names(sizes), reference)) {
    for (j in names(resp)) {
      y <- resp[[j]]
      use <- !is.na(y) & group %in% c(reference, focal)
      r <- mantel_item(y[use], group[use] == focal, total[use])
      if (is.null(r)) next
      dich <- all(y[use] %in% c(0, 1))
      if (dich) {
        effect <- r$mh_d
        stat <- "MH D-DIF"
        ets <- if (isTRUE(abs(effect) >= rules$dif_c && r$p < rules$dif_alpha)) "C" else
          if (isTRUE(abs(effect) >= rules$dif_b && r$p < rules$dif_alpha)) "B" else "A"
        favours <- if (isTRUE(effect > 0)) "focal" else "reference"
      } else {
        effect <- r$smd / stats::sd(y[use])
        stat <- "SMD/SD"
        ets <- if (isTRUE(abs(effect) >= rules$dif_poly_c && r$p < rules$dif_alpha)) "C" else
          if (isTRUE(abs(effect) >= rules$dif_poly_b && r$p < rules$dif_alpha)) "B" else "A"
        favours <- if (isTRUE(effect > 0)) "focal" else "reference"
      }
      rows[[length(rows) + 1L]] <- data.frame(
        item = j, reference = reference, focal = focal, statistic = stat, effect = effect,
        chisq = r$chisq, p.value = r$p, ets = ets, favours = favours, stringsAsFactors = FALSE)
    }
  }
  if (!length(rows)) return(NULL)
  as_tbl(do.call(rbind, rows))
}

mantel_item <- function(y, focal, total) {
  strata <- split(seq_along(y), total)
  num <- den <- 0
  F_ <- E <- V <- 0
  smd <- 0
  nF_all <- sum(focal)
  for (s in strata) {
    yf <- y[s][focal[s]]
    yr <- y[s][!focal[s]]
    nf <- length(yf); nr <- length(yr); N <- nf + nr
    if (nf == 0L || nr == 0L || N < 2L) next
    ys <- y[s]
    sum_y <- sum(ys); sum_y2 <- sum(ys^2)
    v <- nr * nf * (N * sum_y2 - sum_y^2) / (N^2 * (N - 1))
    F_ <- F_ + sum(yf)
    E <- E + nf * sum_y / N
    V <- V + v
    # Mantel-Haenszel common odds ratio (0/1 items): reference correct x focal
    # incorrect over reference incorrect x focal correct
    num <- num + sum(yr == 1) * sum(yf == 0) / N
    den <- den + sum(yr == 0) * sum(yf == 1) / N
    smd <- smd + nf / nF_all * (mean(yf) - mean(yr))
  }
  if (V <= 0) return(NULL)
  chisq <- (abs(F_ - E) - if (all(y %in% c(0, 1))) 0.5 else 0)^2 / V
  alpha <- if (num > 0 && den > 0) num / den else NA_real_
  list(chisq = chisq, p = stats::pchisq(chisq, 1, lower.tail = FALSE),
       mh_d = -2.35 * log(alpha), smd = smd)
}
