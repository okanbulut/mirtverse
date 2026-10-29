# Summarise a data set without revealing its values

Describes each column of a data set (type, number of distinct values,
range, share missing) and guesses its role: an `item` (whole numbers
with few categories), a `group` variable (few categories, e.g. gender),
an `id`, a response time (`rt`), or `other`. This summary is the only
information
[`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
ever shares with an AI model; individual responses are never included.
Category labels are kept only for likely grouping variables.

## Usage

``` r
profile_data(data)
```

## Arguments

- data:

  a data frame.

## Value

A tibble of class `mv_profile` with one row per column: `column`,
`type`, `n_distinct`, `min`, `max`, `prop_missing`, `role` and `levels`.
The number of rows of `data` is stored in the `n` attribute.

## Examples

``` r
profile_data(Science)
#> Data profile: 392 rows, 4 columns (4 look like items)
#>   column    type n_distinct min max prop_missing role levels
#>  Comfort integer          4   1   4            0 item       
#>     Work integer          4   1   4            0 item       
#>   Future integer          4   1   4            0 item       
#>  Benefit integer          4   1   4            0 item       
```
