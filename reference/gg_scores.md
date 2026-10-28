# Distribution of person scores

Distribution of person scores

## Usage

``` r
gg_scores(x, method = "EAP")
```

## Arguments

- x:

  a model returned by
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- method:

  scoring method passed to
  [`mirt::fscores()`](https://philchalmers.github.io/mirt/reference/fscores.html).

## Value

A ggplot object.

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
gg_scores(mod)
```
