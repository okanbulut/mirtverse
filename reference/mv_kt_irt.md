# Compare knowledge tracing with IRT

**Experimental.** Puts Bayesian knowledge tracing and a Rasch (1PL) IRT
model side by side on the same practice logs, as in the second and third
case studies of Bulut et al. (2023):

## Usage

``` r
mv_kt_irt(data, ..., holdout = 0.3)
```

## Arguments

- data, ...:

  practice logs and the arguments of
  [`mv_kt_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_fit.md)
  (such as `kg`, `skills` or the column names). The logs need an item
  column.

- holdout:

  share of each student's attempts on a skill held out for forecasting
  (students with fewer than three attempts on a skill are used for
  fitting only).

## Value

An `mv_kt_irt` object: A list with `accuracy` (one row per skill and
model: `skill`, `model`, `n_test`, `rmse`, `accuracy`, `auc`) and
`items` (one row per skill: `n_items`, the `correlation` between IRT
difficulty and the log of the BKT guess, and the item table in
`tidy(x, "difficulty")`). Use
[`print()`](https://rdrr.io/r/base/print.html),
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) and
[`glance()`](https://generics.r-lib.org/reference/glance.html).

## Details

- **Forecasting.** For every student and skill, the last `holdout` share
  of the attempts is held out. Both models are fitted to the earlier
  attempts. BKT predicts each held-out answer from the student's answers
  up to it (it updates after every answer, which is the point of
  knowledge tracing); IRT predicts from the student's ability and the
  item's difficulty, which stay fixed. RMSE, accuracy and AUC are
  reported per skill.

- **Item difficulty.** Per skill, the correlation between the IRT item
  difficulties and the log of the BKT item guess parameters (from a
  `multigs` model): Items that are easy to guess should be easy items.

The IRT model is fitted per skill as a crossed random effects logistic
model (`correct ~ 1 + (1 | student) + (1 | item)`) with the lme4
package, which suits sparse logs where most students see only some
items.

## References

Bulut, O., Shin, J., Yildirim-Erbasli, S. N., Gorgun, G., & Pardos, Z.
A. (2023). An introduction to Bayesian knowledge tracing with pyBKT.
*Psych, 5*(3), 770-786.
[doi:10.3390/psych5030050](https://doi.org/10.3390/psych5030050)

## Examples

``` r
# \donttest{
if (requireNamespace("lme4", quietly = TRUE)) {
  cmp <- mv_kt_irt(cognitive_tutor, item = "problem",
                   skills = c("Plot pi", "Plot imperfect radical"))
  cmp
}
#> <mv_kt_irt> (EXPERIMENTAL) Knowledge tracing vs IRT on the same logs
#> Forecasts of the last 30% of each student's attempts (2 skill(s)):
#>   BKT:       RMSE 0.461, accuracy 0.741, AUC 0.784
#>   IRT (1PL): RMSE 0.469, accuracy 0.670, AUC 0.780
#> (means over skills)
#> IRT item difficulty vs log BKT guess: Median correlation -0.90 over 2 skill(s)
# }
```
