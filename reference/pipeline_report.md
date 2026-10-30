# Pipeline stage: technical report

Writes the HTML technical report for a calibrated pipeline: everything
[`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md)
shows (summary, model fit, items, graphics, scores, item health cards),
plus a *Pipeline decisions* section with the stages, every flag and its
status, the decision log with notes, and the rules in effect, and a
*Groups* section with score summaries by group. The reproducibility
section lists the pipeline code that was run.

## Usage

``` r
pipeline_report(
  p,
  file = "pipeline-report.html",
  title = p$title,
  author = NULL,
  open = interactive() && !isTRUE(getOption("mirtverse.dry_run")),
  ...
)
```

## Arguments

- p:

  a calibrated pipeline from
  [`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md).

- file:

  path of the `.html` file to write.

- title:

  report title; defaults to the pipeline title.

- author:

  optional author line.

- open:

  logical; open the report in a browser afterwards.

- ...:

  further arguments passed to
  [`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md),
  such as `cards`.

## Value

The pipeline, invisibly, with the reporting stage recorded. The report
path is stored in `p$report`.

## Details

Before writing, the report gate checks one thing (threshold from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

- `small_group` (block): a group with fewer than `min_group_n`
  respondents. Its summary is left out of the report so that individuals
  cannot be identified.

Flags from earlier stages that are still open are listed in the report
as open.

## Examples

``` r
# \donttest{
p <- add_responses(mv_pipeline("Certification exam"), certexam, items = 3:34,
                   key = certexam_key, group = "language")
p <- calibrate(p, model = "3PL")
#> Warning: Calibration is running with 1 block open flag(s) from earlier stages:
#>   #1 [block] possible_miskey: Q14 (p = 0.18, item-total r = -0.23)
#> Flags only warn because strict = FALSE. See flags(p).
p <- pipeline_report(p, file = tempfile(fileext = ".html"))
#> Warning: Reporting is running with 3 block and 4 review open flag(s) from earlier stages:
#>   #1 [block] possible_miskey: Q14 (p = 0.18, item-total r = -0.23)
#>   #2 [block] not_converged: test (not converged)
#>   #3 [review] local_dependence: Q21 & Q22 (Q3 = 0.28)
#>   #4 [review] parameter_range: Q14 (a = -0.71)
#>   #5 [review] parameter_range: Q21 (c = 0.62)
#>   #6 [block] dif_large: Q09 (MH D-DIF = -2.01, French vs English (favours English))
#>   #7 [review] dif_moderate: Q27 (MH D-DIF = -1.04, French vs English (favours English))
#> Flags only warn because strict = FALSE. See flags(p).
# }
```
