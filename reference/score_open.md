# Pipeline stage: scoring open-ended responses

Scores open-ended (constructed) responses by one of two routes, chosen
by the user, and checks the machine scores against human scores before
they are used:

## Usage

``` r
score_open(
  p,
  responses,
  scorer = "llm",
  provider = NULL,
  model = NULL,
  add_to_data = FALSE,
  batch = 10
)
```

## Arguments

- p:

  a pipeline whose item pool has the open-ended items (with rubrics) or,
  for a trained model, at least their ids.

- responses:

  a data frame with one row per response and columns `person`, `item`
  (an item id in `p$items`), `response` (the text), and optionally
  `human1`, `human2` (human scores) and `group`.

- scorer:

  `"llm"` or a fitted model with a
  [`predict()`](https://rdrr.io/r/stats/predict.html) method.

- provider, model:

  the language model for `scorer = "llm"`.

- add_to_data:

  logical; add the final scores to the response data.

- batch:

  responses scored in one model call.

## Value

The pipeline with `p$open_scores`, a tibble with one row per response
(`machine`, `rationale`, `confidence`, `routed` and `final` scores), and
`p$agreement`, a tibble of agreement statistics per item.

## Details

- `scorer = "llm"`: a language model (see
  [`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md))
  scores each response against the item's rubric from
  [`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
  or
  [`add_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
  and returns a score, a one-sentence rationale and its confidence.

- `scorer = <a fitted model>`: any object with a
  [`predict()`](https://rdrr.io/r/stats/predict.html) method trained on
  human scores, such as a tidymodels workflow. It is called as
  `predict(scorer, newdata)` with the responses data frame (columns
  `item`, `response` and any other columns you supply) and must return
  one score per row; predictions are rounded and kept within the item's
  score range.

Both routes pass the same agreement gate, computed on the responses that
have human scores (`human1`, and `human2` for double-scored responses),
following Williamson, Xi and Breyer (2012) (thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

- `validation_n` (review): fewer than `n_validation` double-scored
  responses for an item.

- `human_agreement` (block): quadratic weighted kappa (QWK) between the
  two human scores below `qwk_min`.

- `machine_agreement` (block): QWK between machine and human scores
  below `qwk_min`, or more than `qwk_drop` below the human-human QWK.

- `score_distribution` (review): the standardized mean difference
  between machine and human scores is beyond `score_smd` in absolute
  value.

- `subgroup_fairness` (review): the machine-human standardized mean
  difference within a group is beyond `subgroup_smd`.

- `low_confidence` (review): responses that are off topic, shorter than
  `min_words` words, or scored with confidence below `min_confidence`.
  They are routed to human scoring: their final score is the human score
  if there is one, otherwise missing.

With `add_to_data = TRUE` the final scores join the pipeline's response
data as polytomous items (matched by respondent id), so a mixed test can
be calibrated with
[`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md).

## References

Williamson, D. M., Xi, X., & Breyer, F. J. (2012). A framework for
evaluation and use of automated scoring. *Educational Measurement:
Issues and Practice, 31*(1), 2-13.

## Examples

``` r
if (FALSE) { # \dontrun{
p <- score_open(p, essays, scorer = "llm")
p$agreement
# or a model trained on human scores
p <- score_open(p, essays, scorer = my_workflow)
} # }
```
