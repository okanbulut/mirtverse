# Local dependence heatmap (Yen's Q3)

Local dependence heatmap (Yen's Q3)

## Usage

``` r
gg_q3(x, cutoff = 0.2, label = TRUE)
```

## Arguments

- x:

  a model returned by
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- cutoff:

  absolute residual correlation above the average Q3 that is marked as
  possible local dependence (0.2 by default, Christensen et al., 2017).

- label:

  logical; print values in flagged cells.

## Value

A ggplot object.

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
gg_q3(mod)
```
