# Start an assessment pipeline

An assessment pipeline takes a test from response data to a score report
in stages. Each stage does its work, then runs a set of checks (a
*gate*) and records what it finds as *flags* that the user should
consider before the next stage. The stages available so far (numbered as
in the pipeline plan; start at any of them):

## Usage

``` r
mv_pipeline(
  title = "Assessment pipeline",
  rules = mv_rules(),
  strict = FALSE,
  verbose = interactive()
)

# S3 method for class 'mv_pipeline'
tidy(x, ...)
```

## Arguments

- title:

  a name for the pipeline, used as the report title.

- rules:

  thresholds for the checks, from
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md).

- strict:

  logical; if `TRUE`, open `review` and `block` flags stop the next
  stage until a decision is recorded.

- verbose:

  logical; print a summary of each stage's flags.

- x:

  a pipeline.

- ...:

  not used.

## Value

An object of class `mv_pipeline`. Use
[`flags()`](https://www.okanbulut.com/mirtverse/reference/flags.md) to
list its flags and
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) to get all of
them as a tibble.

## Details

1.  [`set_blueprint()`](https://www.okanbulut.com/mirtverse/reference/set_blueprint.md):
    the construct, content cells and score use.

2.  [`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
    or
    [`add_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md):
    item writing with a language model or by people (keys, distractors,
    rubrics, duplicates, coverage).

3.  [`add_responses()`](https://www.okanbulut.com/mirtverse/reference/add_responses.md):
    data intake and cleaning (scoring with a key, missing data, miskeyed
    items, straight-lining, rapid guessing, sparse categories).

4.  [`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md):
    model fitting with mirt (convergence, model fit, local dependence,
    item fit, parameter ranges, DIF, reliability, person fit).

5.  [`link_to_bank()`](https://www.okanbulut.com/mirtverse/reference/link_to_bank.md)
    and
    [`bank_items()`](https://www.okanbulut.com/mirtverse/reference/bank_items.md)
    (optional): put the calibration on the scale of an item bank through
    anchor items and add the new items to the bank (anchor drift,
    linking constants).

6.  [`assemble_forms()`](https://www.okanbulut.com/mirtverse/reference/assemble_forms.md),
    [`simulate_cat()`](https://www.okanbulut.com/mirtverse/reference/simulate_cat.md)
    or
    [`assemble_mst()`](https://www.okanbulut.com/mirtverse/reference/assemble_mst.md):
    fixed forms, adaptive or multistage tests (blueprint, parallelism,
    precision, exposure, routing).

7.  [`set_cuts()`](https://www.okanbulut.com/mirtverse/reference/set_cuts.md):
    cut scores and classification accuracy and consistency.

8.  [`pipeline_report()`](https://www.okanbulut.com/mirtverse/reference/pipeline_report.md):
    an HTML technical report that also lists every flag and every
    decision made about it.

Flags have three levels. `info` flags are shown for awareness. `review`
flags point at something a psychometrician should look at. `block` flags
point at problems that make later stages unsafe, such as a model that
did not converge or an item with large DIF.

By default flags only warn: every stage runs, and a warning lists the
open flags it is moving past. With `strict = TRUE`, a stage refuses to
run while an earlier stage has open `review` flags (record a decision
with
[`acknowledge()`](https://www.okanbulut.com/mirtverse/reference/acknowledge.md))
or open `block` flags (fix the problem, for example with
[`drop_items()`](https://www.okanbulut.com/mirtverse/reference/drop_items.md),
or record a reason with
[`override()`](https://www.okanbulut.com/mirtverse/reference/acknowledge.md)).
Every decision is logged with its time and note and printed in the
report.

## See also

[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md),
[`flags()`](https://www.okanbulut.com/mirtverse/reference/flags.md),
[`acknowledge()`](https://www.okanbulut.com/mirtverse/reference/acknowledge.md),
[`override()`](https://www.okanbulut.com/mirtverse/reference/acknowledge.md),
[`drop_items()`](https://www.okanbulut.com/mirtverse/reference/drop_items.md)

## Examples

``` r
# \donttest{
p <- mv_pipeline("Certification exam")
p <- add_responses(p, certexam, items = 3:34, key = certexam_key,
                   id = "id", group = "language")
flags(p)
#> # A tibble: 1 × 10
#>      id stage  check           target value      rule  level advice status note 
#>   <int> <chr>  <chr>           <chr>  <chr>      <chr> <chr> <chr>  <chr>  <chr>
#> 1     1 intake possible_miskey Q14    p = 0.18,… p < … block Check… open   ""   
p <- drop_items(p, "Q14", note = "Miskeyed; confirmed with the item writer")
p <- calibrate(p, model = "3PL")
p
#> <mv_pipeline> Certification exam
#> flags warn (strict = FALSE); rules: standards
#> 
#> [ ] 0  Blueprint        not run
#> [ ] 1  Item generation  not run
#> [x] 4  Data intake      1,200 respondents, 32 items, scored with key
#> [x] 5  Calibration      3PL, NOT converged, reliability 0.83  | open: 2 block, 4 review, 1 info
#> [ ] 6  Linking and bank not run
#> [ ] 7  Forms            not run
#> [ ] 8  Cut scores       not run
#> [ ] 11 Reporting        not run
#> 
#> Open flags: 2 block, 4 review, 1 info. See flags(p). 1 decision(s) recorded.
f <- pipeline_report(p, file = tempfile(fileext = ".html"))
#> Warning: Reporting is running with 2 block and 4 review open flag(s) from earlier stages:
#>   #2 [block] not_converged: test (not converged)
#>   #3 [review] local_dependence: Q21 & Q22 (Q3 = 0.28)
#>   #4 [review] parameter_range: Q17 (c = 0.41)
#>   #5 [review] parameter_range: Q21 (c = 0.60)
#>   #6 [block] dif_large: Q09 (MH D-DIF = -2.01, French vs English (favours English))
#>   #7 [review] dif_moderate: Q27 (MH D-DIF = -1.01, French vs English (favours English))
#> Flags only warn because strict = FALSE. See flags(p).
# }
```
