# Item characteristic (trace) curves

Item characteristic (trace) curves

## Usage

``` r
gg_trace(
  x,
  which.items = NULL,
  type = c("prob", "expected"),
  facet = TRUE,
  theta_lim = c(-4, 4)
)
```

## Arguments

- x:

  a unidimensional model returned by
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- which.items:

  items to plot, by position or name. Defaults to all.

- type:

  `"prob"` for category probability curves or `"expected"` for the
  expected item score.

- facet:

  logical; one panel per item. If `FALSE` all items share one panel
  (only sensible for `type = "expected"` or dichotomous items).

- theta_lim:

  range of the latent trait.

## Value

A ggplot object.

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
gg_trace(mod)

gg_trace(mod, facet = FALSE)
```
