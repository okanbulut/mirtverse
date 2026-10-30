# Pipeline stage: cut scores and decision quality

Records the cut scores that turn scores into decisions (pass/fail or
performance levels) and estimates how accurate and consistent those
decisions are. Cut scores come from a standard-setting study such as
Bookmark or Angoff
([`item_map()`](https://www.okanbulut.com/mirtverse/reference/item_map.md)
gives the ordered item booklet for a Bookmark panel); give them
directly, or give the panelists' ratings in `panel` and the cuts are
their means.

## Usage

``` r
set_cuts(
  p,
  cuts = NULL,
  scale = c("theta", "raw"),
  labels = NULL,
  panel = NULL,
  form = NULL,
  theta = NULL
)
```

## Arguments

- p:

  a calibrated pipeline from
  [`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md).

- cuts:

  the cut scores, in increasing order. Can be omitted when `panel` is
  given.

- scale:

  `"theta"` (ability, on the bank scale if linked) or `"raw"` (summed
  score on the test or form, where a score at or above the cut is in the
  higher category).

- labels:

  names of the categories, one more than the number of cuts. Defaults to
  `"Level 1"`, `"Level 2"`, and so on.

- panel:

  optional ratings from a standard-setting panel: a matrix or data frame
  with one row per panelist and one column per cut, on the same `scale`
  as `cuts`.

- form:

  optional number of a fixed form from
  [`assemble_forms()`](https://www.okanbulut.com/mirtverse/reference/assemble_forms.md);
  the decision quality is then estimated for that form instead of the
  calibrated test.

- theta:

  optional population of abilities to average over (for example draws
  from the expected test-taker distribution).

## Value

The pipeline with `p$cuts`: a list with the cuts on both scales
(`table`), overall decision quality (`summary`), results by cut
(`by_cut`) and the share of the population expected in each category
(`categories`).

## Details

Decision quality is estimated from the IRT model over a population of
abilities (by default the calibration sample's EAP estimates, on the
bank scale if the pipeline is linked):

- With cuts on the ability scale (`scale = "theta"`), Rudner's (2001)
  method: the ability estimate is taken as normal around the true
  ability with the standard error from the test information.

- With cuts on the summed-score scale (`scale = "raw"`), Lee's (2010)
  method: the summed-score distribution at each ability comes from the
  Lord-Wingersky recursion, and the true category is set by the expected
  (true) score.

Classification accuracy is the probability that the observed decision
matches the true one; classification consistency is the probability that
two parallel administrations give the same decision. Both are reported
overall and for each cut, with Cohen's kappa for consistency and the
false positive and false negative rates at each cut.

The checks (thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

- `class_accuracy` (review): overall accuracy below `cut_accuracy`.

- `class_consistency` (review): overall consistency below
  `cut_consistency`.

- `cut_precision` (review): the standard error of measurement at a cut
  is above `cut_sem`; the test has too little information there.

- `panel_agreement` (info): the panelists' cuts have a standard
  deviation (in ability units) above `panel_sd`.

## References

Lee, W.-C. (2010). Classification consistency and accuracy for complex
assessments using item response theory. *Journal of Educational
Measurement, 47*(1), 1-17.

Rudner, L. M. (2001). Computing the expected proportions of
misclassified examinees. *Practical Assessment, Research, and
Evaluation, 7*, Article 14.

## Examples

``` r
# \donttest{
p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
p <- calibrate(drop_items(p, "Q14"), model = "2PL")
p <- set_cuts(p, cuts = 20, scale = "raw", labels = c("Fail", "Pass"))
#> Warning: Cut scores is running with 1 review open flag(s) from earlier stages:
#>   #2 [review] local_dependence: Q21 & Q22 (Q3 = 0.27)
#> Flags only warn because strict = FALSE. See flags(p).
p$cuts$summary
#> # A tibble: 1 × 3
#>   accuracy consistency kappa
#>      <dbl>       <dbl> <dbl>
#> 1    0.881       0.836 0.620
p$cuts$by_cut
#> # A tibble: 1 × 7
#>     cut label accuracy consistency kappa false_positive false_negative
#>   <int> <chr>    <dbl>       <dbl> <dbl>          <dbl>          <dbl>
#> 1     1 Pass     0.881       0.836 0.620         0.0863         0.0331
# }
```
