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
  reliability = 0.80, person_misfit = -1.96, min_group_n = 10)

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
