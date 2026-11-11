# Cross-validate a knowledge tracing model

Splits the students into folds, fits
[`mv_kt_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_fit.md)
on the other folds and predicts each held-out student's answers one
attempt ahead, as pyBKT's `crossvalidate()` does. This shows how well
the model predicts new students, which the fit on the same logs
overstates.

## Usage

``` r
mv_kt_cv(data, ..., folds = 5, seed = NULL)
```

## Arguments

- data, ...:

  practice logs and the arguments of
  [`mv_kt_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_fit.md).

- folds:

  number of folds.

- seed:

  optional random seed for the folds and the starting values.

## Value

A tibble with one row per skill and fold: `skill`, `fold`, `rmse`,
`accuracy` and `auc`, plus a `"mean"` row per skill.

## Examples

``` r
# \donttest{
mv_kt_cv(cognitive_tutor, skills = c("Plot pi", "Plot whole number"), folds = 3, seed = 1)
#> # A tibble: 8 × 5
#>   skill             fold   rmse accuracy   auc
#>   <chr>             <chr> <dbl>    <dbl> <dbl>
#> 1 Plot whole number 1     0.283    0.914 0.464
#> 2 Plot whole number 2     0.285    0.912 0.540
#> 3 Plot whole number 3     0.307    0.895 0.537
#> 4 Plot whole number mean  0.292    0.907 0.514
#> 5 Plot pi           1     0.460    0.706 0.553
#> 6 Plot pi           2     0.465    0.646 0.612
#> 7 Plot pi           3     0.461    0.662 0.577
#> 8 Plot pi           mean  0.462    0.671 0.581
# }
```
