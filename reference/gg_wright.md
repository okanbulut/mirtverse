# Wright map (person-item map)

Places the distribution of person estimates beside the item locations on
the same latent scale, so you can see whether the test is targeted at
the examinees. Polytomous items show each threshold.

## Usage

``` r
gg_wright(x, method = "EAP", thresholds = TRUE, bins = 30)
```

## Arguments

- x:

  a unidimensional model returned by
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- method:

  scoring method for persons, passed to
  [`mirt::fscores()`](https://philchalmers.github.io/mirt/reference/fscores.html).

- thresholds:

  logical; plot every threshold of polytomous items rather than their
  average location.

- bins:

  number of histogram bins for persons.

## Value

A patchwork object (a combined ggplot).

## Examples

``` r
mod <- mirt(Science, 1, verbose = FALSE)
gg_wright(mod)
```
