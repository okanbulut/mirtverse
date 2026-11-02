# Score new responses with a trained scorer

Score new responses with a trained scorer

## Usage

``` r
# S3 method for class 'mv_scorer'
predict(object, newdata, type = c("score", "raw"), ...)
```

## Arguments

- object:

  a scorer from
  [`train_scorer()`](https://www.okanbulut.com/mirtverse/reference/train_scorer.md).

- newdata:

  a character vector of responses, or a data frame with the response
  column used in training (or a column `response`, as in
  [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md)).
  When the scorer was trained with `by`, the data frame needs that
  column, or a column `item` with the same values.

- type:

  `"score"` for whole-number scores within the training range, `"raw"`
  for the unrounded predictions.

- ...:

  not used.

## Value

A numeric vector with one score per response.
