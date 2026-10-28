# Item fit plot

Shows the RMSEA of the S-X2 item-fit statistic for each item and marks
items whose p-value falls below `alpha`.

## Usage

``` r
gg_itemfit(x, alpha = 0.01, p_adjust = "none")
```

## Arguments

- x:

  a model returned by
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- alpha:

  significance level for flagging misfit.

- p_adjust:

  p-value adjustment (see
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html)).

## Value

A ggplot object.

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
gg_itemfit(mod)
```
