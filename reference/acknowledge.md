# Record a decision about a flag

`acknowledge()` records that a flag was looked at and the pipeline may
move on; it is meant for `info` and `review` flags. `override()` records
a decision to continue despite a `block` flag (or any other flag) and
needs a written reason. Both are logged with the time and the note, and
the report from
[`pipeline_report()`](https://www.okanbulut.com/mirtverse/reference/pipeline_report.md)
lists them. Choose flags by `id`, `check`, `target` or `level`; with
none of these, every open flag that the function can take is chosen.

## Usage

``` r
acknowledge(p, id = NULL, check = NULL, target = NULL, level = NULL, note = "")

override(p, id = NULL, check = NULL, target = NULL, level = NULL, note)
```

## Arguments

- p:

  a pipeline from
  [`mv_pipeline()`](https://www.okanbulut.com/mirtverse/reference/mv_pipeline.md).

- id:

  flag numbers, as shown by
  [`flags()`](https://www.okanbulut.com/mirtverse/reference/flags.md).

- check:

  names of checks, e.g. `"item_misfit"`.

- target:

  items (or other targets) the flags are about.

- level:

  levels to choose, e.g. `"review"`.

- note:

  the reason for the decision. Required for `override()`.

## Value

The pipeline, with the chosen flags' status changed.

## Details

To fix a problem instead, remove the item with
[`drop_items()`](https://www.okanbulut.com/mirtverse/reference/drop_items.md)
or rerun the stage with corrected input; flags that no longer apply
disappear.

## Examples

``` r
# \donttest{
p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
p <- acknowledge(p, level = "review", note = "Checked with the content team")
#> Warning: No open flags match; nothing was acknowledged.
p <- override(p, check = "possible_miskey",
              note = "Keep Q14 until the item writer replies")
flags(p, status = "all")
#> # A tibble: 1 × 10
#>      id stage  check           target value      rule  level advice status note 
#>   <int> <chr>  <chr>           <chr>  <chr>      <chr> <chr> <chr>  <chr>  <chr>
#> 1     1 intake possible_miskey Q14    p = 0.18,… p < … block Check… overr… Keep…
# }
```
