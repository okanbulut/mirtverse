# Tidy a comparison of knowledge tracing and IRT

Tidy a comparison of knowledge tracing and IRT

## Usage

``` r
# S3 method for class 'mv_kt_irt'
tidy(x, what = c("accuracy", "items", "difficulty"), ...)

# S3 method for class 'mv_kt_irt'
glance(x, ...)
```

## Arguments

- x:

  a result of
  [`mv_kt_irt()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_irt.md).

- what:

  `"accuracy"` (one row per skill and model, the default), `"items"`
  (one row per skill: The correlation between IRT difficulty and the log
  of the BKT guess) or `"difficulty"` (one row per item).

- ...:

  unused.

## Value

A tibble. [`glance()`](https://generics.r-lib.org/reference/glance.html)
gives the mean RMSE, accuracy and AUC of each model over skills.
