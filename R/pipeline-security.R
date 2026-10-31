#' Pipeline stage: test security
#'
#' Looks for evidence that a score may not reflect the test taker's own
#' ability, before scores are reported. Each check runs when the data it
#' needs are there. Security flags are evidence for an investigation, not
#' proof of misconduct, so the respondents involved are kept in
#' `p$security$persons` and never appear in score reports; flags and the
#' report give counts only.
#'
#' The checks (thresholds from [mv_rules()]):
#'
#' * `preknowledge` (review): with `leaked` items named, test takers who do
#'   much better on the leaked items than on the secure ones (likelihood
#'   ratio test of one ability against separate abilities for the two sets,
#'   p below `preknowledge_alpha`, leaked ability higher).
#' * `item_leakage` (review): with `window` given, items whose proportion
#'   correct rose by more than `leak_p` in the latest window compared with
#'   the earlier ones and, when response times are available, whose median
#'   time fell by more than `leak_rt`.
#' * `parameter_drift` (review): with an item bank, items whose difficulty
#'   (or slope) on the bank scale moved more than `drift_b` (`drift_a`) from
#'   the bank value.
#' * `answer_copying` (review): pairs of test takers who share far more
#'   identical incorrect answers than expected from their scores (Poisson
#'   tail probability below `copy_alpha` after a Bonferroni correction over
#'   all pairs). Needs raw responses scored with a key.
#' * `aberrant_timing` (review): test takers whose response times are much
#'   shorter than expected (standardized log-time residual below `rt_resid`
#'   on at least `rt_share` of the items, from a lognormal model with item
#'   time intensities and person speeds; [fit_rt()] fits the full model).
#' * `site_anomaly` (review): with `site` given, sites or classrooms with a
#'   larger share of flagged test takers than chance allows (binomial test,
#'   p below `site_alpha`).
#' * `score_gain` (info): with `prior` scores, gains above `gain_sem` times
#'   the standard error of the difference.
#'
#' @param p a calibrated pipeline.
#' @param leaked optional item ids suspected to be leaked or exposed.
#' @param window optional administration window of each respondent (in time
#'   order: numbers, dates, or an ordered factor).
#' @param site optional site, school or classroom of each respondent.
#' @param prior optional earlier scores: a data frame with columns `id`,
#'   `theta` and optionally `se`, on the same scale.
#' @return The pipeline with `p$security`: `persons` (respondent-level
#'   evidence, for investigators only), and tables for the item checks.
#' @examples
#' \donttest{
#' p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key, id = "id")
#' p <- calibrate(drop_items(p, "Q14"), model = "2PL")
#' p <- check_security(p, leaked = c("Q01", "Q02", "Q03", "Q04", "Q05"))
#' flags(p, stage = "security")
#' }
#' @export
check_security <- function(p, leaked = NULL, window = NULL, site = NULL, prior = NULL) {
  check_pipeline(p)
  cl <- match.call()
  if (is.null(p$model)) stop("Calibrate the pipeline with calibrate() first.", call. = FALSE)
  enforce_gate(p, "security")
  n <- nrow(p$data$responses)
  for (v in c("window", "site"))
    if (!is.null(get(v)) && length(get(v)) != n)
      stop(sprintf("`%s` must have one value per respondent.", v), call. = FALSE)
  r <- p$rules
  items <- pipeline_bank_rows(p, p$title)
  resp <- as.matrix(p$data$responses[, items$item, drop = FALSE])
  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("security", ...)
  persons <- list()
  add_persons <- function(rows, check, value) if (length(rows))
    persons[[length(persons) + 1L]] <<- data.frame(row = rows, id = p$data$id[rows],
                                                   check = check, value = as.character(value),
                                                   stringsAsFactors = FALSE)
  sec <- list(checks = character(0))

  if (!is.null(leaked)) {
    bad <- setdiff(leaked, items$item)
    if (length(bad)) stop("Leaked items not in the model: ", paste(bad, collapse = ", "),
                          call. = FALSE)
    pk <- preknowledge_lr(items, resp, items$item %in% leaked)
    hit <- which(!is.na(pk$p) & pk$p < r$preknowledge_alpha & pk$theta_leaked > pk$theta_secure)
    add_persons(hit, "preknowledge", sprintf("p = %.1e, gain %.2f", pk$p[hit],
                                              pk$theta_leaked[hit] - pk$theta_secure[hit]))
    if (length(hit))
      add("preknowledge", sprintf("%d test takers", length(hit)),
          sprintf("%.1f%% of test takers", 100 * length(hit) / n),
          sprintf("likelihood ratio p < %s on %d leaked items", r$preknowledge_alpha,
                  length(leaked)), "review",
          "Investigate before reporting these scores; consider retiring the leaked items. See p$security$persons.")
    sec$preknowledge <- as_tbl(pk)
    sec$checks <- c(sec$checks, "preknowledge")
  }

  rt <- if (!is.null(p$data$rt)) as.matrix(p$data$rt[, items$item, drop = FALSE])
  if (!is.null(window)) {
    lk <- leakage_table(resp, rt, window)
    sec$leakage <- lk
    up <- lk$p_change > r$leak_p & (is.na(lk$rt_change) | lk$rt_change < -r$leak_rt)
    add("item_leakage", lk$item[up],
        sprintf("p-value %+.2f%s", lk$p_change[up],
                ifelse(is.na(lk$rt_change[up]), "",
                       sprintf(", median time %+.0f%%", 100 * lk$rt_change[up]))),
        sprintf("p-value up by more than %s%s", r$leak_p,
                if (!is.null(rt)) sprintf(" and time down by more than %.0f%%", 100 * r$leak_rt) else ""),
        "review", "The item may be circulating; review its exposure and consider retiring it.")
    sec$checks <- c(sec$checks, "item_leakage")
  }

  if (!is.null(p$bank)) {
    old <- p$bank$items[p$bank$items$source != p$title & p$bank$items$item %in% items$item, ,
                        drop = FALSE]
    if (nrow(old)) {
      cur <- items[match(old$item, items$item), , drop = FALSE]
      dr <- data.frame(item = old$item, bank_a = old$a, a = cur$a, bank_b = old$b, b = cur$b,
                       stringsAsFactors = FALSE)
      dr$shift_a <- dr$a - dr$bank_a
      dr$shift_b <- dr$b - dr$bank_b
      sec$drift <- as_tbl(dr)
      moved <- abs(dr$shift_b) > r$drift_b | abs(dr$shift_a) > r$drift_a
      moved[is.na(moved)] <- FALSE
      add("parameter_drift", dr$item[moved],
          sprintf("b %+.2f, a %+.2f", dr$shift_b[moved], dr$shift_a[moved]),
          sprintf("|shift| <= %s (b) and %s (a)", r$drift_b, r$drift_a), "review",
          "The item behaves differently from its bank values; check for exposure or changes, and recalibrate or retire it.")
      sec$checks <- c(sec$checks, "parameter_drift")
    }
  }

  if (!is.null(p$data$key)) {
    key <- p$data$key
    if (is.null(names(key))) names(key) <- names(p$data$raw)
    mc <- intersect(items$item, intersect(names(p$data$raw), names(key)))
    cp <- answer_copying(p$data$raw[, mc, drop = FALSE], key[mc],
                         rowSums(p$data$responses[, mc, drop = FALSE], na.rm = TRUE),
                         r$copy_alpha)
    if (!is.null(cp)) {
      sec$copying <- cp
      if (nrow(cp)) {
        rows <- sort(unique(c(cp$row_a, cp$row_b)))
        add_persons(rows, "answer_copying", "identical incorrect answers")
        add("answer_copying", sprintf("%d pairs", nrow(cp)),
            sprintf("%d test takers involved", length(rows)),
            sprintf("Bonferroni-corrected p < %s", r$copy_alpha), "review",
            "Check seating charts and timing for these pairs. See p$security$copying.")
      }
      sec$checks <- c(sec$checks, "answer_copying")
    }
  }

  if (!is.null(rt)) {
    z <- rt_residuals(rt)
    share <- rowMeans(z < r$rt_resid, na.rm = TRUE)
    hit <- which(share >= r$rt_share)
    add_persons(hit, "aberrant_timing", sprintf("%.0f%% of items much too fast", 100 * share[hit]))
    if (length(hit))
      add("aberrant_timing", sprintf("%d test takers", length(hit)),
          sprintf("%.1f%% of test takers", 100 * length(hit) / n),
          sprintf("log-time residual < %s on %.0f%% of items", r$rt_resid, 100 * r$rt_share),
          "review", "Very fast answers can mean preknowledge or rapid guessing; check these test takers. See p$security$persons.")
    sec$checks <- c(sec$checks, "aberrant_timing")
  }

  if (!is.null(prior)) {
    prior <- as.data.frame(prior)
    if (!all(c("id", "theta") %in% names(prior)))
      stop("`prior` needs columns id and theta.", call. = FALSE)
    now <- if (!is.null(p$scores)) p$scores else {
      fs <- mirt::fscores(p$model, full.scores.SE = TRUE, verbose = FALSE)
      th <- fs[, 1]; se <- fs[, 2]
      if (!is.null(p$link) && p$link$method != "fixed") {
        th <- p$link$A * th + p$link$B; se <- p$link$A * se
      }
      data.frame(id = p$data$id, theta = th, se = se)
    }
    j <- match(as.character(now$id), as.character(prior$id))
    pse <- if ("se" %in% names(prior)) prior$se[j] else now$se
    gain <- now$theta - prior$theta[j]
    z <- gain / sqrt(now$se^2 + pse^2)
    hit <- which(!is.na(z) & z > r$gain_sem)
    add_persons(hit, "score_gain", sprintf("gain %.2f (%.1f SE)", gain[hit], z[hit]))
    if (length(hit))
      add("score_gain", sprintf("%d test takers", length(hit)),
          sprintf("%.1f%% of retesters", 100 * length(hit) / sum(!is.na(z))),
          sprintf("gain <= %s standard errors", r$gain_sem), "info",
          "Large gains can be real learning; look at them together with other evidence.")
    sec$checks <- c(sec$checks, "score_gain")
  }

  pers <- if (length(persons)) do.call(rbind, persons) else
    data.frame(row = integer(0), id = character(0), check = character(0), value = character(0))
  if (!is.null(site)) {
    flagged <- seq_len(n) %in% pers$row
    base <- mean(flagged)
    st <- do.call(rbind, lapply(split(seq_len(n), site), function(rows)
      data.frame(n = length(rows), flagged = sum(flagged[rows]))))
    st$site <- rownames(st)
    st$p <- if (base > 0 && base < 1)
      stats::pbinom(st$flagged - 1, st$n, base, lower.tail = FALSE) else 1
    sec$sites <- as_tbl(st[, c("site", "n", "flagged", "p")])
    odd <- st$p < r$site_alpha & st$n >= r$min_group_n
    add("site_anomaly", st$site[odd],
        sprintf("%d of %d flagged (overall %.1f%%)", st$flagged[odd], st$n[odd], 100 * base),
        sprintf("binomial p >= %s", r$site_alpha), "review",
        "Look into how the test was given at this site.")
    sec$checks <- c(sec$checks, "site_anomaly")
  }
  if (!length(sec$checks))
    stop("No security check could run: give `leaked`, `window`, `site` or `prior`, ",
         "or add response times, a key or a bank.", call. = FALSE)

  sec$persons <- as_tbl(pers)
  p$security <- sec
  p <- set_stage_flags(p, "security", bind_flags(out))
  p <- set_stage(p, "security", "done",
                 sprintf("%d checks; %d test takers with evidence", length(sec$checks),
                         length(unique(pers$row))))
  p <- stage_rerun(p, "reporting")
  p <- log_event(p, "check security", paste(sec$checks, collapse = ", "))
  p <- add_code(p, cl)
  report_stage_flags(p, "security")
  p
}

# ---- Preknowledge -----------------------------------------------------------

# log-likelihood of each person's responses on a theta grid (persons x grid)
loglik_grid <- function(items, resp, grid) {
  ll <- matrix(0, nrow(resp), length(grid))
  for (j in seq_len(nrow(items))) {
    P <- item_probs(items$pars[[j]], items$itemtype[j], grid)
    x <- resp[, j]
    ok <- !is.na(x)
    ll[ok, ] <- ll[ok, ] + log(pmax(t(P)[x[ok] + 1L, , drop = FALSE], 1e-12))
  }
  ll
}

preknowledge_lr <- function(items, resp, is_leaked, grid = seq(-4, 4, by = 0.05)) {
  ll_l <- loglik_grid(items[is_leaked, , drop = FALSE], resp[, is_leaked, drop = FALSE], grid)
  ll_s <- loglik_grid(items[!is_leaked, , drop = FALSE], resp[, !is_leaked, drop = FALSE], grid)
  best <- function(ll) apply(ll, 1L, max)
  arg <- function(ll) grid[apply(ll, 1L, which.max)]
  lr <- 2 * (best(ll_l) + best(ll_s) - best(ll_l + ll_s))
  data.frame(theta_leaked = arg(ll_l), theta_secure = arg(ll_s), lr = pmax(lr, 0),
             p = stats::pchisq(pmax(lr, 0), 1, lower.tail = FALSE))
}

# ---- Leakage ----------------------------------------------------------------

leakage_table <- function(resp, rt, window) {
  w <- if (is.factor(window)) as.integer(window) else match(window, sort(unique(window)))
  last <- w == max(w, na.rm = TRUE)
  if (all(last)) stop("`window` needs at least two administration windows.", call. = FALSE)
  pc <- colMeans(resp[last, , drop = FALSE], na.rm = TRUE) -
    colMeans(resp[!last, , drop = FALSE], na.rm = TRUE)
  rc <- if (!is.null(rt)) {
    med <- function(m) apply(m, 2L, stats::median, na.rm = TRUE)
    med(rt[last, , drop = FALSE]) / med(rt[!last, , drop = FALSE]) - 1
  } else rep(NA_real_, ncol(resp))
  as_tbl(data.frame(item = colnames(resp), p_change = unname(pc), rt_change = unname(rc)))
}

# ---- Answer copying ---------------------------------------------------------

# identical incorrect answers for every pair, against the number expected
# from option choices among test takers with similar total scores
answer_copying <- function(raw, key, total, alpha, max_n = 5000L) {
  n <- nrow(raw)
  if (n > max_n) {
    warning(sprintf("Answer copying is checked only for up to %d test takers.", max_n),
            call. = FALSE)
    return(NULL)
  }
  strata <- cut(rank(total, ties.method = "first"), breaks = min(10L, n), labels = FALSE)
  obs <- matrix(0, n, n)
  expct <- matrix(0, n, n)
  for (j in seq_len(ncol(raw))) {
    x <- as.character(raw[[j]])
    wrong <- !is.na(x) & x != "" & x != as.character(key[[j]])
    opts <- setdiff(unique(x[wrong]), NA)
    if (!length(opts)) next
    M <- vapply(opts, function(o) as.numeric(wrong & x == o), numeric(n))
    M <- matrix(M, n)
    Q <- apply(M, 2L, function(col) stats::ave(col, strata))
    Q <- matrix(Q, n)
    obs <- obs + tcrossprod(M)
    expct <- expct + tcrossprod(Q)
  }
  up <- which(upper.tri(obs), arr.ind = TRUE)
  o <- obs[up]
  e <- expct[up]
  pv <- stats::ppois(o - 1, pmax(e, 1e-8), lower.tail = FALSE)
  npairs <- n * (n - 1) / 2
  hit <- pv * npairs < alpha & o > 0
  as_tbl(data.frame(row_a = up[hit, 1], row_b = up[hit, 2], identical_incorrect = o[hit],
                    expected = e[hit], p = pv[hit]))
}

# ---- Timing -----------------------------------------------------------------

# standardized residuals of log response times under a lognormal model with
# item time intensity (beta), person speed (tau) and item precision (alpha),
# estimated by moments
rt_residuals <- function(rt) {
  lt <- log(pmax(as.matrix(rt), 1e-3))
  lt[!is.finite(lt)] <- NA
  beta <- colMeans(lt, na.rm = TRUE)
  tau <- rowMeans(sweep(-lt, 2L, beta, "+"), na.rm = TRUE)
  res <- lt - outer(-tau, beta, "+")
  alpha <- 1 / apply(res, 2L, stats::sd, na.rm = TRUE)
  sweep(res, 2L, alpha, "*")
}
