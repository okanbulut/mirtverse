# Pipeline stage: bank monitoring

Keeps an item bank healthy from one administration to the next. Each run
records the current administration in the bank (how many test takers saw
each item, and the test's marginal reliability) under a window name,
then checks the bank's history. Items it flags can be retired or sent
back to review with
[`retire_items()`](https://www.okanbulut.com/mirtverse/reference/retire_items.md).
Drift and compromise checks are in
[`check_security()`](https://www.okanbulut.com/mirtverse/reference/check_security.md).

## Usage

``` r
monitor_bank(
  p,
  bank = NULL,
  window = p$title,
  date = Sys.Date(),
  content = NULL,
  min_items = NULL,
  record = TRUE
)
```

## Arguments

- p:

  a pipeline.

- bank:

  the item bank, from
  [`mv_bank()`](https://www.okanbulut.com/mirtverse/reference/mv_bank.md)
  or
  [`bank_items()`](https://www.okanbulut.com/mirtverse/reference/bank_items.md);
  defaults to `p$bank`.

- window:

  a name for the current administration, such as `"2026 spring"`.
  Defaults to the pipeline title. Recording a window again replaces it.
  Use `record = FALSE` to check the bank without recording.

- date:

  the date of the administration.

- content:

  optional content cell of each bank item: a named vector (item id =
  cell). It is stored in the bank. By default the cells come from the
  bank, or from the items in the pipeline
  ([`add_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md),
  [`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)).

- min_items:

  optional fewest active items per cell: one number, or a named vector
  by cell.

- record:

  logical; record the current administration in the bank. It needs a
  calibrated pipeline.

## Value

The pipeline with the updated bank in `p$bank` and `p$monitoring`:
`windows` (one row per administration), `items` (use of each bank item),
and `cells` (active items per content cell). Save the bank with
`saveRDS(p$bank, ...)` to keep its history.

## Details

The checks (thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

- `over_exposure` (review): active items seen by more than
  `max_exposure` of the test takers in each of the last
  `exposure_windows` windows.

- `bank_depth` (review): a content cell with fewer active items than its
  minimum: `min_items`, or by default `cell_depth` times the cell's
  count in the blueprint from
  [`set_blueprint()`](https://www.okanbulut.com/mirtverse/reference/set_blueprint.md).

- `reliability_trend` (review): marginal reliability in the latest
  window more than `reliability_drop` below its value in the first
  window.

- `unused_items` (info): more than `unused_share` of the active items
  (that have been in the bank for `unused_days`) not used in the last
  `unused_days` days.

## See also

[`retire_items()`](https://www.okanbulut.com/mirtverse/reference/retire_items.md)

## Examples

``` r
# \donttest{
p <- add_responses(mv_pipeline("Spring"), certexam, items = 3:34, key = certexam_key)
p <- calibrate(drop_items(p, "Q14"), model = "2PL")
p <- bank_items(p, name = "Certification bank")
p <- monitor_bank(p, window = "2026 spring", date = as.Date("2026-04-15"))
#> Warning: Bank monitoring is running with 1 review open flag(s) from earlier stages:
#>   #2 [review] local_dependence: Q21 & Q22 (Q3 = 0.27)
#> Flags only warn because strict = FALSE. See flags(p).
p$monitoring$windows
#> # A tibble: 1 × 4
#>   window      date           n reliability
#>   <chr>       <date>     <int>       <dbl>
#> 1 2026 spring 2026-04-15  1200       0.831
flags(p, stage = "monitoring")
#> # A tibble: 0 × 10
#> # ℹ 10 variables: id <int>, stage <chr>, check <chr>, target <chr>,
#> #   value <chr>, rule <chr>, level <chr>, advice <chr>, status <chr>,
#> #   note <chr>
# }
```
