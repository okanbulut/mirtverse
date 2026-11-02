# Train an automated scorer on human-scored text

Fits a simple, transparent automated scoring engine: A ridge regression
of human scores on the words of the responses ("bag of words"). It runs
in base R with no internet connection and no API key, so it suits
teaching and small programs, and it plugs straight into
[`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md)
through its [`predict()`](https://rdrr.io/r/stats/predict.html) method.

## Usage

``` r
train_scorer(
  data,
  response = "response",
  score = "human1",
  by = NULL,
  ngrams = 1:2,
  length = FALSE,
  min_docs = 3,
  lambda = NULL,
  folds = 5,
  seed = 1
)

# S3 method for class 'mv_scorer'
tidy(x, ...)
```

## Arguments

- data:

  a data frame with one row per human-scored response.

- response, score:

  names of the columns that hold the response text and the human score
  used for training.

- by:

  optional name of a column (such as the prompt or item) to train a
  separate scorer for each of its values.

- ngrams:

  `1` for single words, `1:2` to add two-word phrases.

- length:

  logical; add the log number of words as a feature.

- min_docs:

  smallest number of training responses a word must appear in to be
  used.

- lambda:

  the ridge penalty; `NULL` chooses it by cross-validation.

- folds:

  number of cross-validation folds.

- seed:

  random seed for the fold split, or `NULL`.

- x:

  a scorer from `train_scorer()`.

- ...:

  not used.

## Value

An object of class `mv_scorer`: A list with one model per value of `by`
(`models`), the settings, and `cv`, a tibble of out-of-fold predictions
for the training responses (`row`, `by`, `human`, `predicted`,
`machine`). Use [`predict()`](https://rdrr.io/r/stats/predict.html) to
score new responses,
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) for the word
weights, and
[`agreement_report()`](https://www.okanbulut.com/mirtverse/reference/agreement_report.md)
to check it.

[`tidy()`](https://generics.r-lib.org/reference/tidy.html) returns a
tibble with one row per feature and model: `by`, `term` and `weight`,
the change in the predicted score for one more use of the word (on the
`log(1 + count)` scale), sorted from the largest positive weight.

## Details

Each response is turned into counts of its words and, with
`ngrams = 1:2`, of its two-word phrases, kept when they appear in at
least `min_docs` training responses. The counts enter as
`log(1 + count)`. With `length = TRUE` the log of the number of words is
added as a feature, as many commercial engines do. The ridge penalty
`lambda` is chosen by `folds`-fold cross-validation unless you give it,
and the cross-validated predictions are kept, so the scorer's agreement
with people can be judged on responses it was not trained on (see
[`agreement_report()`](https://www.okanbulut.com/mirtverse/reference/agreement_report.md)).

A ridge regression treats scoring as prediction: It learns which words
go with high human scores in the training responses, whatever the
reason. Words that signal a key idea help, but so can words that merely
go with longer or more fluent answers. That is why the scorer's
agreement must be checked overall and within groups before its scores
are used.

## See also

[`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md)
to use the scorer in an assessment pipeline,
[`agreement_report()`](https://www.okanbulut.com/mirtverse/reference/agreement_report.md)
to check it; the [AI
Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.html).

## Examples

``` r
e1 <- essays[essays$prompt == "E1", ]
s <- train_scorer(e1, response = "response", score = "human1")
s
#> <mv_scorer> ridge regression on words and two-word phrases
#>   400 responses, 662 features, lambda = 10, cross-validated RMSE = 0.56, QWK = 0.89
#> Check it with agreement_report(); use it with predict() or score_open().
head(tidy(s))
#> # A tibble: 6 × 3
#>   by    term    weight
#>   <chr> <chr>    <dbl>
#> 1 all   less     0.425
#> 2 all   with     0.347
#> 3 all   is less  0.314
#> 4 all   than     0.281
#> 5 all   on       0.249
#> 6 all   are      0.244
predict(s, c("Ice is less dense than water, so it floats.", "I don't know."))
#> [1] 1 0
```
