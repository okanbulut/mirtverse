# Tidy item statistics and item fit in one table

Combines classical item statistics
([`mirt::itemstats()`](https://philchalmers.github.io/mirt/reference/itemstats.html)),
IRT parameters and item fit
([`mirt::itemfit()`](https://philchalmers.github.io/mirt/reference/itemfit.html))
into one row per item, with a `flag` column that marks items worth
reviewing.

## Usage

``` r
item_table(x, fit_stats = "S_X2", p_adjust = "none", alpha = 0.01)
```

## Arguments

- x:

  a model returned by
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- fit_stats:

  fit statistic passed to
  [`mirt::itemfit()`](https://philchalmers.github.io/mirt/reference/itemfit.html).

- p_adjust:

  p-value adjustment method (see
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html)).

- alpha:

  significance level used for misfit flags.

## Value

A tibble with one row per item.

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
item_table(mod)
#> # A tibble: 5 × 12
#>   item   itemtype     N  mean item_total_r discrimination location   S_X2    df
#>   <chr>  <chr>    <int> <dbl>        <dbl>          <dbl>    <dbl>  <dbl> <dbl>
#> 1 Item.1 2PL       1000 0.828        0.246          0.988   -1.88   4.75      2
#> 2 Item.2 2PL       1000 0.658        0.247          1.08    -0.748 14.5       2
#> 3 Item.3 2PL       1000 0.772        0.313          1.71    -1.06   1.27      2
#> 4 Item.4 2PL       1000 0.606        0.223          0.765   -0.635  5.24      2
#> 5 Item.5 2PL       1000 0.843        0.175          0.736   -2.52   0.941     2
#> # ℹ 3 more variables: RMSEA <dbl>, p.value <dbl>, flag <chr>
```
