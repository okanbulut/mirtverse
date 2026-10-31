# Retire bank items or send them back to review

Takes items out of use in an item bank. Retired items stay in the bank
with their history but are no longer used for linking, forms or
monitoring. Items sent to review are also out of use until they are made
active again (`status = "active"`).

## Usage

``` r
retire_items(x, items, status = c("retired", "review", "active"), note = "")
```

## Arguments

- x:

  a pipeline with a bank (`p$bank`), or a bank from
  [`mv_bank()`](https://www.okanbulut.com/mirtverse/reference/mv_bank.md).

- items:

  item ids.

- status:

  `"retired"`, `"review"` or `"active"`.

- note:

  the reason, kept in the bank's history.

## Value

`x`, with the bank updated.

## Examples

``` r
# \donttest{
mod <- mirt(expand.table(LSAT7), 1, itemtype = "2PL", verbose = FALSE)
bank <- retire_items(mv_bank(mod), "Item.1", note = "Exposed on a forum")
tidy(bank)
#> # A tibble: 5 × 9
#>   item   itemtype  ncat     a      b     g source      added      status 
#>   <chr>  <chr>    <int> <dbl>  <dbl> <dbl> <chr>       <chr>      <chr>  
#> 1 Item.1 2PL          2 0.988 -1.88      0 calibration 2026-10-31 retired
#> 2 Item.2 2PL          2 1.08  -0.748     0 calibration 2026-10-31 active 
#> 3 Item.3 2PL          2 1.71  -1.06      0 calibration 2026-10-31 active 
#> 4 Item.4 2PL          2 0.765 -0.635     0 calibration 2026-10-31 active 
#> 5 Item.5 2PL          2 0.736 -2.52      0 calibration 2026-10-31 active 
# }
```
