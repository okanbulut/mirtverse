# Pipeline stage: data intake and cleaning

Adds item responses to a pipeline, scores them with an answer key if one
is given, and screens items and respondents before calibration. The
checks (thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

## Usage

``` r
add_responses(
  p,
  data,
  items = NULL,
  key = NULL,
  group = NULL,
  id = NULL,
  rt = NULL
)
```

## Arguments

- p:

  a pipeline from
  [`mv_pipeline()`](https://www.okanbulut.com/mirtverse/reference/mv_pipeline.md).

- data:

  a data frame (or matrix) of responses, possibly with other columns
  such as an ID or a grouping variable.

- items:

  the item columns, by name or position. Defaults to every column that
  is not `id`, `group` or `rt`.

- key:

  optional answer key: one correct option per item. Responses are then
  scored 1 (correct) or 0 (incorrect); missing responses stay missing.

- group:

  optional grouping variable for DIF and group summaries: a column name
  of `data` or a vector with one value per respondent.

- id:

  optional respondent IDs: a column name of `data` or a vector.

- rt:

  optional response times: a matrix or data frame with one column per
  item (same order), or the names of those columns in `data`.

## Value

The pipeline with the data and the intake flags added.

## Details

- `zero_variance` (block): every respondent gave the same answer, so the
  item cannot be calibrated.

- `possible_miskey` (block): a 0/1 item with a very low proportion
  correct or a negative corrected item-total correlation, or a
  polytomous item with a negative correlation (possibly reverse-coded).

- `item_missing` (review): an item with many missing responses.

- `person_missing` (review): respondents who skipped most items.

- `straight_lining` (review): respondents who gave the same answer to
  every item of a rating-scale (polytomous, unkeyed) test.

- `rapid_guessing` (review): respondents with many responses faster than
  `rapid_rt` times the item's median response time (needs `rt`).

- `sparse_category` (review): score categories with few responses.

- `small_group` (info): groups too small for stable DIF results (fewer
  than 100 respondents).

Respondent-level checks raise one flag each, with the number of
respondents as the target; the respondents themselves are listed in
`p$persons`.

## Examples

``` r
# \donttest{
p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key,
                   id = "id", group = "language")
flags(p)
#> # A tibble: 1 × 10
#>      id stage  check           target value      rule  level advice status note 
#>   <int> <chr>  <chr>           <chr>  <chr>      <chr> <chr> <chr>  <chr>  <chr>
#> 1     1 intake possible_miskey Q14    p = 0.18,… p < … block Check… open   ""   
# }
```
