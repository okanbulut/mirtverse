#' Pipeline stage: cut scores and decision quality
#'
#' Records the cut scores that turn scores into decisions (pass/fail or
#' performance levels) and estimates how accurate and consistent those
#' decisions are. Cut scores come from a standard-setting study such as
#' Bookmark or Angoff ([item_map()] gives the ordered item booklet for a
#' Bookmark panel); give them directly, or give the panelists' ratings in
#' `panel` and the cuts are their means.
#'
#' Decision quality is estimated from the IRT model over a population of
#' abilities (by default the calibration sample's EAP estimates, on the bank
#' scale if the pipeline is linked):
#'
#' * With cuts on the ability scale (`scale = "theta"`), Rudner's (2001)
#'   method: the ability estimate is taken as normal around the true ability
#'   with the standard error from the test information.
#' * With cuts on the summed-score scale (`scale = "raw"`), Lee's (2010)
#'   method: the summed-score distribution at each ability comes from the
#'   Lord-Wingersky recursion, and the true category is set by the expected
#'   (true) score.
#'
#' Classification accuracy is the probability that the observed decision
#' matches the true one; classification consistency is the probability that
#' two parallel administrations give the same decision. Both are reported
#' overall and for each cut, with Cohen's kappa for consistency and the
#' false positive and false negative rates at each cut.
#'
#' The checks (thresholds from [mv_rules()]):
#'
#' * `class_accuracy` (review): overall accuracy below `cut_accuracy`.
#' * `class_consistency` (review): overall consistency below
#'   `cut_consistency`.
#' * `cut_precision` (review): the standard error of measurement at a cut is
#'   above `cut_sem`; the test has too little information there.
#' * `panel_agreement` (info): the panelists' cuts have a standard deviation
#'   (in ability units) above `panel_sd`.
#'
#' @param p a calibrated pipeline from [calibrate()].
#' @param cuts the cut scores, in increasing order. Can be omitted when
#'   `panel` is given.
#' @param scale `"theta"` (ability, on the bank scale if linked) or `"raw"`
#'   (summed score on the test or form, where a score at or above the cut is
#'   in the higher category).
#' @param labels names of the categories, one more than the number of cuts.
#'   Defaults to `"Level 1"`, `"Level 2"`, and so on.
#' @param panel optional ratings from a standard-setting panel: a matrix or
#'   data frame with one row per panelist and one column per cut, on the same
#'   `scale` as `cuts`.
#' @param form optional number of a fixed form from [assemble_forms()]; the
#'   decision quality is then estimated for that form instead of the
#'   calibrated test.
#' @param theta optional population of abilities to average over (for example
#'   draws from the expected test-taker distribution).
#' @return The pipeline with `p$cuts`: a list with the cuts on both scales
#'   (`table`), overall decision quality (`summary`), results by cut
#'   (`by_cut`) and the share of the population expected in each category
#'   (`categories`).
#' @references
#' Lee, W.-C. (2010). Classification consistency and accuracy for complex
#' assessments using item response theory. *Journal of Educational
#' Measurement, 47*(1), 1-17.
#'
#' Rudner, L. M. (2001). Computing the expected proportions of misclassified
#' examinees. *Practical Assessment, Research, and Evaluation, 7*, Article 14.
#' @examples
#' \donttest{
#' p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
#' p <- calibrate(drop_items(p, "Q14"), model = "2PL")
#' p <- set_cuts(p, cuts = 20, scale = "raw", labels = c("Fail", "Pass"))
#' p$cuts$summary
#' p$cuts$by_cut
#' }
#' @export
set_cuts <- function(p, cuts = NULL, scale = c("theta", "raw"), labels = NULL, panel = NULL,
                     form = NULL, theta = NULL) {
  check_pipeline(p)
  cl <- match.call()
  scale <- match.arg(scale)
  if (is.null(p$model)) stop("Calibrate the pipeline with calibrate() first.", call. = FALSE)
  enforce_gate(p, "cuts")
  items <- cut_items(p, form)
  if (!is.null(panel)) {
    panel <- as.matrix(panel)
    if (is.null(cuts)) cuts <- colMeans(panel, na.rm = TRUE)
    if (ncol(panel) != length(cuts))
      stop("`panel` needs one column per cut.", call. = FALSE)
  }
  if (is.null(cuts) || !is.numeric(cuts) || anyNA(cuts))
    stop("Give the cut scores in `cuts`, or the panel's ratings in `panel`.", call. = FALSE)
  if (is.unsorted(cuts, strictly = TRUE)) stop("`cuts` must be increasing.", call. = FALSE)
  nc <- length(cuts)
  if (is.null(labels)) labels <- paste("Level", seq_len(nc + 1L))
  if (length(labels) != nc + 1L)
    stop(sprintf("Give %d labels, one more than the number of cuts.", nc + 1L), call. = FALSE)

  max_raw <- sum(items$ncat - 1L)
  if (scale == "raw") {
    if (any(cuts <= 0 | cuts > max_raw))
      stop(sprintf("Raw cuts must be between 1 and the maximum score (%d).", max_raw),
           call. = FALSE)
    raw_cuts <- ceiling(cuts)
    theta_cuts <- vapply(cuts, function(x) tcc_inverse(items, x), numeric(1))
  } else {
    theta_cuts <- cuts
    raw_cuts <- test_tcc(items, theta_cuts)
  }
  if (is.null(theta)) theta <- population_theta(p)

  probs <- if (scale == "raw") lee_probs(items, theta, raw_cuts) else
    rudner_probs(items, theta, theta_cuts)
  true_cat <- findInterval(theta, theta_cuts) + 1L
  quality <- decision_quality(probs, true_cat)
  sem <- 1 / sqrt(colSums(pool_info(items, theta_cuts)))

  tab <- as_tbl(data.frame(cut = seq_len(nc), label = labels[-1], theta = theta_cuts,
                           raw = raw_cuts, sem = sem))
  by_cut <- as_tbl(cbind(data.frame(cut = seq_len(nc), label = labels[-1]), quality$by_cut))
  cats <- as_tbl(data.frame(category = labels, expected = colMeans(probs),
                            true = as.numeric(table(factor(true_cat, levels = seq_len(nc + 1L)))) /
                              length(theta)))
  panel_sd <- if (!is.null(panel)) {
    pt <- if (scale == "raw")
      apply(panel, c(1, 2), function(x) if (is.na(x)) NA_real_ else tcc_inverse(items, x))
    else panel
    apply(pt, 2L, stats::sd, na.rm = TRUE)
  }

  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("cuts", ...)
  r <- p$rules
  s <- quality$summary
  if (s$accuracy < r$cut_accuracy)
    add("class_accuracy", "decisions", sprintf("accuracy = %.3f", s$accuracy),
        sprintf("accuracy >= %s", r$cut_accuracy), "review",
        "Too many test takers would get the wrong decision; add items that are informative near the cuts, or lengthen the test.")
  if (s$consistency < r$cut_consistency)
    add("class_consistency", "decisions", sprintf("consistency = %.3f (kappa = %.2f)",
                                                  s$consistency, s$kappa),
        sprintf("consistency >= %s", r$cut_consistency), "review",
        "A retest would often give a different decision; add items near the cuts or reduce the number of levels.")
  wide <- sem > r$cut_sem
  add("cut_precision", sprintf("cut %d (%s)", which(wide), labels[-1][wide]),
      sprintf("SEM = %.2f at theta = %.2f", sem[wide], theta_cuts[wide]),
      sprintf("SEM <= %s", r$cut_sem), "review",
      "The test has little information at this cut; assemble forms targeted at it (assemble_forms(theta = cut)).")
  if (!is.null(panel_sd)) {
    spread <- !is.na(panel_sd) & panel_sd > r$panel_sd
    add("panel_agreement", sprintf("cut %d (%s)", which(spread), labels[-1][spread]),
        sprintf("panel SD = %.2f", panel_sd[spread]), sprintf("SD <= %s", r$panel_sd), "info",
        "Panelists disagree; discuss the ratings in another round before adopting the cut.")
  }

  p$cuts <- list(scale = scale, method = if (scale == "raw") "Lee (2010)" else "Rudner (2001)",
                 labels = labels, table = tab, summary = as_tbl(as.data.frame(s)),
                 by_cut = by_cut, categories = cats, panel_sd = panel_sd, form = form,
                 n_theta = length(theta), max_raw = max_raw)
  p <- set_stage_flags(p, "cuts", bind_flags(out))
  p <- set_stage(p, "cuts", "done",
                 sprintf("%d cut%s, accuracy %.2f, consistency %.2f", nc,
                         if (nc > 1) "s" else "", s$accuracy, s$consistency))
  p <- stage_rerun(p, "reporting")
  p <- log_event(p, "set cuts", sprintf("%s cuts at %s", scale, paste(round(cuts, 2), collapse = ", ")))
  p <- add_code(p, cl)
  report_stage_flags(p, "cuts")
  p
}

#' Item map for Bookmark standard setting
#'
#' Locates every item (and every score category of a polytomous item) on the
#' ability scale at the response probability `rp`: the ability at which a test
#' taker has probability `rp` of answering correctly (or of reaching that
#' category or higher). Sorted by location, this is the ordered item booklet
#' of the Bookmark method; a panelist's bookmark translates to a cut at the
#' location of the bookmarked item.
#'
#' @param p a calibrated pipeline.
#' @param rp response probability, commonly 0.67 (or 0.50).
#' @param form optional fixed form number from [assemble_forms()].
#' @return A tibble with one row per item category: `page` (position in the
#'   booklet), `item`, `category`, and `theta`, the location at `rp`. Items
#'   that never reach `rp` (a lower asymptote above it) have `NA` and come
#'   last.
#' @examples
#' \donttest{
#' p <- calibrate(add_responses(mv_pipeline(), Science), model = "graded")
#' item_map(p)
#' }
#' @export
item_map <- function(p, rp = 0.67, form = NULL) {
  check_pipeline(p)
  if (is.null(p$model)) stop("Calibrate the pipeline with calibrate() first.", call. = FALSE)
  if (!is.numeric(rp) || length(rp) != 1L || rp <= 0 || rp >= 1)
    stop("`rp` must be a probability between 0 and 1.", call. = FALSE)
  items <- cut_items(p, form)
  rows <- lapply(seq_len(nrow(items)), function(j) {
    k <- seq_len(items$ncat[j] - 1L)
    loc <- vapply(k, function(cat) {
      f <- function(t) sum(item_probs(items$pars[[j]], items$itemtype[j], t)[1, -seq_len(cat)]) - rp
      if (f(-10) > 0 || f(10) < 0) return(NA_real_)
      stats::uniroot(f, c(-10, 10), tol = 1e-8)$root
    }, numeric(1))
    data.frame(item = items$item[j], category = k, theta = loc, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  out <- out[order(out$theta, na.last = TRUE), , drop = FALSE]
  as_tbl(data.frame(page = seq_len(nrow(out)), out, row.names = NULL))
}

# The items that make the scores: a fixed form, or the calibrated test (on the
# bank scale if the pipeline is linked)
cut_items <- function(p, form) {
  if (is.null(form)) return(pipeline_bank_rows(p, p$title))
  if (is.null(p$forms) || p$forms$method != "ata")
    stop("`form` needs fixed forms from assemble_forms().", call. = FALSE)
  ids <- p$forms$items$item[p$forms$items$form == form]
  if (!length(ids)) stop(sprintf("There is no form %s.", form), call. = FALSE)
  pool <- item_pool(p)
  pool[match(ids, pool$item), , drop = FALSE]
}

# EAP estimates of the calibration sample, on the bank scale if linked
population_theta <- function(p) {
  th <- mirt::fscores(p$model, method = "EAP", verbose = FALSE)[, 1]
  if (!is.null(p$link) && p$link$method != "fixed") th <- p$link$A * th + p$link$B
  th[is.finite(th)]
}

# test characteristic curve: expected summed score at each theta
test_tcc <- function(items, theta) {
  rowSums(matrix(vapply(seq_len(nrow(items)), function(j) {
    P <- item_probs(items$pars[[j]], items$itemtype[j], theta)
    drop(P %*% (seq_len(ncol(P)) - 1))
  }, numeric(length(theta))), nrow = length(theta)))
}

tcc_inverse <- function(items, x) {
  f <- function(t) test_tcc(items, t) - x
  lo <- -10; hi <- 10
  if (f(lo) > 0 || f(hi) < 0)
    stop(sprintf("Raw score %s cannot be reached by the expected score; choose a cut inside the scale.", x),
         call. = FALSE)
  stats::uniroot(f, c(lo, hi), tol = 1e-8)$root
}

# Lord-Wingersky recursion: probability of each summed score (columns 0..max)
# at each theta (rows)
lord_wingersky <- function(items, theta) {
  out <- matrix(1, length(theta), 1L)
  for (j in seq_len(nrow(items))) {
    P <- item_probs(items$pars[[j]], items$itemtype[j], theta)
    K <- ncol(P)
    new <- matrix(0, length(theta), ncol(out) + K - 1L)
    for (k in seq_len(K)) {
      idx <- k - 1L + seq_len(ncol(out))
      new[, idx] <- new[, idx] + out * P[, k]
    }
    out <- new
  }
  out
}

# probability of each category at each theta, from the summed-score distribution
lee_probs <- function(items, theta, raw_cuts) {
  dist <- lord_wingersky(items, theta)
  cat_of_score <- findInterval(seq_len(ncol(dist)) - 1L, raw_cuts) + 1L
  vapply(seq_len(length(raw_cuts) + 1L), function(k)
    rowSums(dist[, cat_of_score == k, drop = FALSE]), numeric(length(theta)))
}

# probability of each category at each theta, with a normal ability estimate
rudner_probs <- function(items, theta, theta_cuts) {
  se <- 1 / sqrt(colSums(pool_info(items, theta)))
  bounds <- c(-Inf, theta_cuts, Inf)
  vapply(seq_len(length(theta_cuts) + 1L), function(k)
    stats::pnorm((bounds[k + 1L] - theta) / se) - stats::pnorm((bounds[k] - theta) / se),
    numeric(length(theta)))
}

decision_quality <- function(probs, true_cat) {
  probs <- matrix(probs, ncol = max(2L, ncol(probs)))
  acc <- probs[cbind(seq_along(true_cat), true_cat)]
  cons <- rowSums(probs^2)
  chance <- sum(colMeans(probs)^2)
  pc <- mean(cons)
  by_cut <- do.call(rbind, lapply(seq_len(ncol(probs) - 1L), function(k) {
    above <- rowSums(probs[, (k + 1L):ncol(probs), drop = FALSE])
    truly <- true_cat > k
    ca <- mean(ifelse(truly, above, 1 - above))
    cc <- mean(above^2 + (1 - above)^2)
    ch <- mean(above)^2 + (1 - mean(above))^2
    data.frame(accuracy = ca, consistency = cc, kappa = (cc - ch) / (1 - ch),
               false_positive = mean((!truly) * above), false_negative = mean(truly * (1 - above)))
  }))
  list(summary = list(accuracy = mean(acc), consistency = pc,
                      kappa = (pc - chance) / (1 - chance)),
       by_cut = by_cut)
}
