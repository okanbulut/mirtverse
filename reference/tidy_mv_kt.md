# Tidy a knowledge tracing model

Tidy a knowledge tracing model

## Usage

``` r
# S3 method for class 'mv_kt'
tidy(x, what = c("parameters", "items", "trace", "mastery"), ...)

# S3 method for class 'mv_kt'
glance(x, ...)
```

## Arguments

- x:

  an `mv_kt` object from
  [`mv_kt_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_fit.md).

- what:

  `"parameters"` (one row per skill, the default), `"items"` (per-item
  guess and slip of a `multigs` model), `"trace"` (one row per attempt)
  or `"mastery"` (each student's probability of knowing each skill after
  their last attempt).

- ...:

  unused.

## Value

A tibble. [`glance()`](https://generics.r-lib.org/reference/glance.html)
returns the numbers of skills, students and attempts, the
log-likelihood, AIC and BIC, and the RMSE, accuracy and AUC of the
one-step-ahead predictions on the logs the model was fitted to (use
[`mv_kt_cv()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_cv.md)
for new students).
