#' Thresholds for the pipeline checks
#'
#' Every check that [mv_pipeline()] runs compares a statistic with a threshold
#' from this list. The defaults follow common practice in operational testing
#' (the *Standards for Educational and Psychological Testing*, the ETS
#' classification of differential item functioning); change any of them by
#' name.
#'
#' | Rule | Default | Check |
#' | --- | --- | --- |
#' | `miskey_p` | 0.10 | proportion correct below this suggests a miskeyed item |
#' | `miskey_r` | 0 | corrected item-total correlation below this suggests a miskey |
#' | `missing_item` | 0.20 | share of missing responses on an item |
#' | `missing_person` | 0.50 | share of items a respondent skipped |
#' | `straight_min_items` | 5 | minimum test length for straight-lining checks |
#' | `rapid_rt` | 0.10 | response time below this share of the item's median is a rapid guess |
#' | `rapid_person` | 0.10 | share of rapid guesses that flags a respondent |
#' | `min_category_n` | 10 | responses needed in each score category |
#' | `rmsea` | 0.06 | maximum M2-based RMSEA |
#' | `cfi` | 0.95 | minimum M2-based CFI |
#' | `q3` | 0.20 | maximum absolute Q3 residual correlation between two items |
#' | `fit_alpha` | 0.01 | significance level for S-X2 item misfit |
#' | `fit_adjust` | `"BH"` | p-value adjustment for item misfit ([stats::p.adjust()]) |
#' | `a_min`, `a_max` | 0.3, 4 | acceptable range of discrimination (slope) |
#' | `b_max` | 4 | largest acceptable absolute difficulty (location) |
#' | `c_max` | 0.35 | largest acceptable lower asymptote (guessing) |
#' | `dif_alpha` | 0.05 | significance level of the Mantel-Haenszel test |
#' | `dif_b`, `dif_c` | 1, 1.5 | absolute MH D-DIF for ETS categories B and C (0/1 items) |
#' | `dif_poly_b`, `dif_poly_c` | 0.17, 0.25 | absolute SMD/SD for categories B and C (polytomous items) |
#' | `reliability` | 0.80 | minimum marginal reliability |
#' | `person_misfit` | -1.96 | Zh (lz) person-fit value below which a respondent misfits |
#' | `min_anchors` | 5 | fewest anchor items for linking to a bank |
#' | `min_anchor_share` | 0.20 | smallest share of the test that should be anchors |
#' | `anchor_displacement` | 0.3 | largest change in an anchor's location (logits) after linking |
#' | `link_slope_min`, `link_slope_max` | 0.8, 1.2 | acceptable range of the linking slope A |
#' | `parallel_tol` | 0.10 | largest relative difference in information between parallel forms |
#' | `cat_sem` | 0.35 | largest acceptable standard error of a form, CAT or MST (and the CAT stopping rule) |
#' | `cat_bias` | 0.1 | largest acceptable average bias of simulated CAT or MST scores |
#' | `max_exposure` | 0.25 | largest share of CAT simulees who should see an item |
#' | `unused_share` | 0.20 | largest share of the bank a CAT may leave unused |
#' | `bank_depth` | 10 | bank size, in multiples of the CAT length, below which the bank is shallow |
#' | `mst_routing` | 0.15 | largest share of MST simulees routed to the wrong module |
#' | `cut_accuracy` | 0.85 | smallest acceptable classification accuracy |
#' | `cut_consistency` | 0.80 | smallest acceptable classification consistency |
#' | `cut_sem` | 0.35 | largest acceptable standard error of measurement at a cut score |
#' | `panel_sd` | 0.5 | largest standard deviation of standard-setting panelists' cuts (ability units) |
#' | `duplicate_sim` | 0.90 | largest word overlap (Jaccard) between two items before they are near-duplicates |
#' | `coverage_ratio` | 3 | items to write per blueprint target (items are lost in review and field testing) |
#' | `min_reviewers` | 2 | fewest reviewers per item |
#' | `review_kappa` | 0.40 | smallest acceptable Fleiss' kappa between reviewers' decisions |
#' | `n_rasch`, `n_2pl`, `n_3pl` | 200, 500, 1000 | respondents needed per item in a field test (Rasch; 2PL; 3PL or polytomous models) |
#' | `recovery_rmse` | 0.2 | largest acceptable RMSE of simulated slope recovery in a field-test design |
#' | `n_validation` | 200 | double-scored responses needed per open-ended item to validate machine scores |
#' | `qwk_min` | 0.70 | smallest acceptable quadratic weighted kappa (human-human and machine-human) |
#' | `qwk_drop` | 0.10 | largest acceptable drop from human-human to machine-human QWK |
#' | `score_smd` | 0.15 | largest standardized mean difference between machine and human scores |
#' | `subgroup_smd` | 0.10 | largest machine-human standardized mean difference within a group |
#' | `min_confidence`, `min_words` | 0.5, 3 | machine scores below this confidence, or responses shorter than this, go to human scoring |
#' | `max_se` | 1 | standard error above which a test taker's score is flagged as imprecise |
#' | `preknowledge_alpha` | 0.001 | significance level of the preknowledge likelihood ratio test |
#' | `leak_p`, `leak_rt` | 0.15, 0.25 | rise in proportion correct and relative fall in median time that suggest a leaked item |
#' | `drift_a`, `drift_b` | 0.3, 0.3 | largest change in an item's slope and difficulty from its bank value |
#' | `copy_alpha` | 0.001 | family-wise significance level of the identical-incorrect-answers index |
#' | `rt_resid`, `rt_share` | -3, 0.20 | log-time residual, and share of items below it, that flag aberrant timing |
#' | `site_alpha` | 0.001 | significance level for a site with too many flagged test takers |
#' | `gain_sem` | 3 | score gain, in standard errors of the difference, that is unusual |
#' | `min_group_n` | 10 | smallest group summarized in a report |
#'
#' `preset = "lenient"` relaxes the rules for pilot studies and small samples
#' (`rmsea = 0.08`, `cfi = 0.90`, `q3 = 0.30`, `a_min = 0.2`,
#' `reliability = 0.70`, `missing_item = 0.30`); values given by name are
#' applied on top of the preset.
#'
#' @param ... rules to change, by name, e.g. `q3 = 0.25`.
#' @param preset starting values: `"standards"` (the defaults above) or
#'   `"lenient"`.
#' @return A list of class `mv_rules`.
#' @examples
#' mv_rules()
#' mv_rules(q3 = 0.25, reliability = 0.85)
#' mv_rules(preset = "lenient")
#' @export
mv_rules <- function(..., preset = c("standards", "lenient")) {
  preset <- match.arg(preset)
  rules <- default_rules
  if (preset == "lenient")
    rules[names(lenient_rules)] <- lenient_rules
  changes <- list(...)
  if (length(changes)) {
    if (is.null(names(changes)) || any(names(changes) == ""))
      stop("Give every rule by name, e.g. mv_rules(q3 = 0.25).", call. = FALSE)
    bad <- setdiff(names(changes), names(default_rules))
    if (length(bad))
      stop("Unknown rule(s): ", paste(bad, collapse = ", "),
           ". See ?mv_rules for the list.", call. = FALSE)
    for (nm in names(changes)) {
      v <- changes[[nm]]
      if (!identical(class(v), class(default_rules[[nm]])) &&
          !(is.numeric(v) && is.numeric(default_rules[[nm]])))
        stop(sprintf("Rule `%s` must be %s.", nm,
                     if (is.numeric(default_rules[[nm]])) "a number" else "a string"),
             call. = FALSE)
      if (length(v) != 1L || is.na(v))
        stop(sprintf("Rule `%s` must be a single value.", nm), call. = FALSE)
    }
    rules[names(changes)] <- changes
  }
  attr(rules, "preset") <- preset
  attr(rules, "changed") <- names(changes)
  structure(rules, class = "mv_rules")
}

default_rules <- list(
  miskey_p = 0.10, miskey_r = 0, missing_item = 0.20, missing_person = 0.50,
  straight_min_items = 5, rapid_rt = 0.10, rapid_person = 0.10, min_category_n = 10,
  rmsea = 0.06, cfi = 0.95, q3 = 0.20, fit_alpha = 0.01, fit_adjust = "BH",
  a_min = 0.3, a_max = 4, b_max = 4, c_max = 0.35,
  dif_alpha = 0.05, dif_b = 1, dif_c = 1.5, dif_poly_b = 0.17, dif_poly_c = 0.25,
  reliability = 0.80, person_misfit = -1.96, min_anchors = 5, min_anchor_share = 0.20,
  anchor_displacement = 0.3, link_slope_min = 0.8, link_slope_max = 1.2,
  parallel_tol = 0.10, cat_sem = 0.35, cat_bias = 0.1, max_exposure = 0.25,
  unused_share = 0.20, bank_depth = 10, mst_routing = 0.15, cut_accuracy = 0.85,
  cut_consistency = 0.80, cut_sem = 0.35, panel_sd = 0.5, duplicate_sim = 0.90,
  coverage_ratio = 3, min_reviewers = 2, review_kappa = 0.40, n_rasch = 200, n_2pl = 500,
  n_3pl = 1000, recovery_rmse = 0.2, n_validation = 200, qwk_min = 0.70, qwk_drop = 0.10,
  score_smd = 0.15, subgroup_smd = 0.10, min_confidence = 0.5, min_words = 3, max_se = 1,
  preknowledge_alpha = 0.001, leak_p = 0.15, leak_rt = 0.25, drift_a = 0.3, drift_b = 0.3,
  copy_alpha = 0.001, rt_resid = -3, rt_share = 0.20, site_alpha = 0.001, gain_sem = 3,
  min_group_n = 10)

lenient_rules <- list(rmsea = 0.08, cfi = 0.90, q3 = 0.30, a_min = 0.2,
                      reliability = 0.70, missing_item = 0.30)

#' @export
print.mv_rules <- function(x, ...) {
  changed <- attr(x, "changed")
  cat(sprintf("<mv_rules> preset: %s%s\n", attr(x, "preset"),
              if (length(changed)) paste0("; changed: ", paste(changed, collapse = ", ")) else ""))
  vals <- vapply(unclass(x), function(v) format(v), character(1))
  w <- max(nchar(names(vals)))
  for (nm in names(vals)) cat(sprintf("  %-*s %s\n", w, nm, vals[[nm]]))
  invisible(x)
}

rules_table <- function(rules) {
  changed <- attr(rules, "changed")
  data.frame(rule = names(rules),
             value = vapply(unclass(rules), function(v) format(v), character(1)),
             changed = names(rules) %in% changed,
             stringsAsFactors = FALSE, row.names = NULL)
}
