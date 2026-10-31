# Pipeline stage: test blueprint and construct definition

States what the test measures and how it is built: the construct, the
content cells with a target number of items in each, the item types, the
intended score use and the target reliability. The blueprint is the
contract later stages check against:
[`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
fills its cells, item coverage is counted against its targets, and the
target reliability replaces the `reliability` rule used at calibration.

## Usage

``` r
set_blueprint(
  p,
  cells,
  construct = NULL,
  use = NULL,
  item_types = "mc",
  length = NULL,
  population = NULL,
  grade_level = NULL,
  reliability = NULL
)
```

## Arguments

- p:

  a pipeline from
  [`mv_pipeline()`](https://www.okanbulut.com/mirtverse/reference/mv_pipeline.md).

- cells:

  the content cells: a data frame with a column `content`, an optional
  column `cognitive` (cognitive level, such as recall or application)
  and a column `n` with the target number of items per test form; or a
  named vector of target counts, with content areas as names.

- construct:

  a sentence describing what the test measures.

- use:

  the intended use of the scores, such as `"pass/fail"`,
  `"classification"`, `"ranking"`, `"diagnostic"` or `"growth"`.

- item_types:

  item types to write: `"mc"` (multiple choice) and/or `"open"`
  (open-ended, scored with a rubric).

- length:

  number of items on a form; defaults to the sum of the cell targets.

- population:

  a description of the test takers (used when writing items).

- grade_level:

  optional target reading grade level for item text.

- reliability:

  optional target reliability; replaces the `reliability` rule.

## Value

The pipeline with `p$blueprint`, a list holding the settings and
`cells`, a tibble with one row per cell (`cell`, `content`, `cognitive`,
`n`).

## Details

The checks:

- `empty_cell` (block): a content cell has no target count (zero or
  missing).

- `score_use` (review): the intended use of the scores is not stated;
  decisions about cut scores, reliability and reporting depend on it.

- `target_reliability` (info): no target reliability was given, so the
  `reliability` rule (0.80 by default) is used.

- `test_length` (info): the stated test length differs from the sum of
  the cell targets.

## Examples

``` r
bp <- data.frame(content = c("Algebra", "Algebra", "Geometry"),
                 cognitive = c("Recall", "Application", "Application"),
                 n = c(5, 10, 5))
p <- set_blueprint(mv_pipeline(), bp, construct = "Grade 8 mathematics",
                   use = "pass/fail", reliability = 0.85)
p$blueprint$cells
#> # A tibble: 3 × 4
#>   cell                   content  cognitive       n
#>   <chr>                  <chr>    <chr>       <dbl>
#> 1 Algebra / Recall       Algebra  Recall          5
#> 2 Algebra / Application  Algebra  Application    10
#> 3 Geometry / Application Geometry Application     5
```
