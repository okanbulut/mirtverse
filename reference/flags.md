# List the flags raised by a pipeline

List the flags raised by a pipeline

## Usage

``` r
flags(p, status = "open", level = NULL, stage = NULL)
```

## Arguments

- p:

  a pipeline from
  [`mv_pipeline()`](https://www.okanbulut.com/mirtverse/reference/mv_pipeline.md).

- status:

  which flags to show: `"open"` (the default), `"all"`, or any of
  `"acknowledged"`, `"overridden"` and `"fixed"`.

- level:

  optional levels to keep (`"info"`, `"review"`, `"block"`).

- stage:

  optional stages to keep (`"blueprint"`, `"generation"`, `"review"`,
  `"field_test"`, `"intake"`, `"calibration"`, `"linking"`, `"forms"`,
  `"cuts"`, `"scoring"`, `"reporting"`).

## Value

A tibble with one row per flag: `id`, `stage`, `check`, `target` (an
item, a pair of items, a group, or the whole test), `value` (the
statistic), `rule` (the threshold that fired), `level`, `advice` (what
to do about it), `status` and `note` (the reason recorded with a
decision).

## Examples

``` r
# \donttest{
p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
flags(p)
#> # A tibble: 1 × 10
#>      id stage  check           target value      rule  level advice status note 
#>   <int> <chr>  <chr>           <chr>  <chr>      <chr> <chr> <chr>  <chr>  <chr>
#> 1     1 intake possible_miskey Q14    p = 0.18,… p < … block Check… open   ""   
flags(p, level = "block")
#> # A tibble: 1 × 10
#>      id stage  check           target value      rule  level advice status note 
#>   <int> <chr>  <chr>           <chr>  <chr>      <chr> <chr> <chr>  <chr>  <chr>
#> 1     1 intake possible_miskey Q14    p = 0.18,… p < … block Check… open   ""   
# }
```
