# Pipeline stage: test security

Looks for evidence that a score may not reflect the test taker's own
ability, before scores are reported. Each check runs when the data it
needs are there. Security flags are evidence for an investigation, not
proof of misconduct, so the respondents involved are kept in
`p$security$persons` and never appear in score reports; flags and the
report give counts only.

## Usage

``` r
check_security(p, leaked = NULL, window = NULL, site = NULL, prior = NULL)
```

## Arguments

- p:

  a calibrated pipeline.

- leaked:

  optional item ids suspected to be leaked or exposed.

- window:

  optional administration window of each respondent (in time order:
  numbers, dates, or an ordered factor).

- site:

  optional site, school or classroom of each respondent.

- prior:

  optional earlier scores: a data frame with columns `id`, `theta` and
  optionally `se`, on the same scale.

## Value

The pipeline with `p$security`: `persons` (respondent-level evidence,
for investigators only), and tables for the item checks.

## Details

The checks (thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

- `preknowledge` (review): with `leaked` items named, test takers who do
  much better on the leaked items than on the secure ones (likelihood
  ratio test of one ability against separate abilities for the two sets,
  p below `preknowledge_alpha`, leaked ability higher).

- `item_leakage` (review): with `window` given, items whose proportion
  correct rose by more than `leak_p` in the latest window compared with
  the earlier ones and, when response times are available, whose median
  time fell by more than `leak_rt`.

- `parameter_drift` (review): with an item bank, items whose difficulty
  (or slope) on the bank scale moved more than `drift_b` (`drift_a`)
  from the bank value.

- `answer_copying` (review): pairs of test takers who share far more
  identical incorrect answers than expected from their scores (Poisson
  tail probability below `copy_alpha` after a Bonferroni correction over
  all pairs). Needs raw responses scored with a key.

- `aberrant_timing` (review): test takers whose response times are much
  shorter than expected (standardized log-time residual below `rt_resid`
  on at least `rt_share` of the items, from a lognormal model with item
  time intensities and person speeds;
  [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md)
  fits the full model).

- `site_anomaly` (review): with `site` given, sites or classrooms with a
  larger share of flagged test takers than chance allows (binomial test,
  p below `site_alpha`).

- `score_gain` (info): with `prior` scores, gains above `gain_sem` times
  the standard error of the difference.

## Examples

``` r
# \donttest{
p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key, id = "id")
p <- calibrate(drop_items(p, "Q14"), model = "2PL")
p <- check_security(p, leaked = c("Q01", "Q02", "Q03", "Q04", "Q05"))
#> Warning: Test security is running with 1 review open flag(s) from earlier stages:
#>   #2 [review] local_dependence: Q21 & Q22 (Q3 = 0.27)
#> Flags only warn because strict = FALSE. See flags(p).
flags(p, stage = "security")
#> # A tibble: 0 × 10
#> # ℹ 10 variables: id <int>, stage <chr>, check <chr>, target <chr>,
#> #   value <chr>, rule <chr>, level <chr>, advice <chr>, status <chr>,
#> #   note <chr>
# }
```
