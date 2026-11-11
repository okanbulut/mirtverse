# Predict answers with a knowledge tracing model

Runs a fitted model over new practice logs: Before each attempt, the
probability that the student knows the skill and the predicted
probability of a correct answer, using only the student's earlier
attempts; after it, the updated probability of knowing the skill.

## Usage

``` r
# S3 method for class 'mv_kt'
predict(object, newdata = NULL, ...)
```

## Arguments

- object:

  an `mv_kt` object from
  [`mv_kt_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_fit.md).

- newdata:

  practice logs with the same columns as the logs the model was fitted
  to (by default, those logs).

- ...:

  unused.

## Value

A tibble with one row per attempt: `student`, `skill`, `item`, `step`,
`correct`, `p_known_before`, `p_correct` and `p_known`. Attempts on
skills the model has not seen are dropped.

## Examples

``` r
kt <- mv_kt_fit(cognitive_tutor, skills = "Plot pi")
head(predict(kt))
#> # A tibble: 6 × 8
#>   student skill   item   step correct p_known_before p_correct p_known
#>   <chr>   <chr>   <chr> <int>   <int>          <dbl>     <dbl>   <dbl>
#> 1 3cjD21W Plot pi NA        1       1          0.676     0.619   0.973
#> 2 JJGL4Ig Plot pi NA        1       0          0.676     0.619   0.192
#> 3 JJGL4Ig Plot pi NA        2       1          0.696     0.636   0.976
#> 4 Y6120Vs Plot pi NA        1       1          0.676     0.619   0.973
#> 5 ZBj33oo Plot pi NA        1       0          0.676     0.619   0.192
#> 6 1T4w47X Plot pi NA        1       1          0.676     0.619   0.973
```
