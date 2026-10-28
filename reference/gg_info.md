# Test and item information curves

Test and item information curves

## Usage

``` r
gg_info(
  x,
  type = c("test", "items", "se"),
  which.items = NULL,
  theta_lim = c(-4, 4)
)
```

## Arguments

- x:

  a unidimensional model returned by
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- type:

  `"test"` for the test information function with its conditional
  standard error, `"items"` for item information curves, or `"se"` for
  the conditional standard error of measurement alone.

- which.items:

  items to include for `type = "items"`.

- theta_lim:

  range of the latent trait.

## Value

A ggplot object.

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
gg_info(mod)

gg_info(mod, type = "items")
```
