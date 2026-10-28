# Empirical versus model-implied item curve

Groups examinees by their ability estimate and compares the observed
mean item score in each group (with 95% intervals) with the
model-implied curve. Large departures point to misfit.

## Usage

``` r
gg_empirical(x, item, bins = 10, theta_lim = c(-3, 3))
```

## Arguments

- x:

  a unidimensional model returned by
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- item:

  a single item, by position or name.

- bins:

  number of ability groups.

- theta_lim:

  range of the latent trait.

## Value

A ggplot object.

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
gg_empirical(mod, 1)
```
