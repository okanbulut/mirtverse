# Item map for Bookmark standard setting

Locates every item (and every score category of a polytomous item) on
the ability scale at the response probability `rp`: the ability at which
a test taker has probability `rp` of answering correctly (or of reaching
that category or higher). Sorted by location, this is the ordered item
booklet of the Bookmark method; a panelist's bookmark translates to a
cut at the location of the bookmarked item.

## Usage

``` r
item_map(p, rp = 0.67, form = NULL)
```

## Arguments

- p:

  a calibrated pipeline.

- rp:

  response probability, commonly 0.67 (or 0.50).

- form:

  optional fixed form number from
  [`assemble_forms()`](https://www.okanbulut.com/mirtverse/reference/assemble_forms.md).

## Value

A tibble with one row per item category: `page` (position in the
booklet), `item`, `category`, and `theta`, the location at `rp`. Items
that never reach `rp` (a lower asymptote above it) have `NA` and come
last.

## Examples

``` r
# \donttest{
p <- calibrate(add_responses(mv_pipeline(), Science), model = "graded")
#> Warning: Calibration is running with 1 review open flag(s) from earlier stages:
#>   #1 [review] sparse_category: Comfort (category 1: n = 5)
#> Flags only warn because strict = FALSE. See flags(p).
item_map(p)
#> # A tibble: 12 × 4
#>     page item    category theta
#>    <int> <chr>      <int> <dbl>
#>  1     1 Comfort        1 -3.99
#>  2     2 Benefit        1 -2.41
#>  3     3 Future         1 -1.97
#>  4     4 Work           1 -1.81
#>  5     5 Comfort        2 NA   
#>  6     6 Comfort        3 NA   
#>  7     7 Work           2 NA   
#>  8     8 Work           3 NA   
#>  9     9 Future         2 NA   
#> 10    10 Future         3 NA   
#> 11    11 Benefit        2 NA   
#> 12    12 Benefit        3 NA   
# }
```
