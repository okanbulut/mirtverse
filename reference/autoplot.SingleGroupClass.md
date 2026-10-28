# Plot a mirt model with ggplot2

A single entry point to the mirtverse graphics.

## Usage

``` r
# S3 method for class 'SingleGroupClass'
autoplot(
  object,
  type = c("trace", "expected", "info", "iteminfo", "se", "wright", "itemfit", "q3",
    "scores"),
  ...
)
```

## Arguments

- object:

  a model returned by
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- type:

  one of `"trace"`, `"expected"`, `"info"`, `"iteminfo"`, `"se"`,
  `"wright"`, `"itemfit"`, `"q3"`, or `"scores"`.

- ...:

  passed to the matching `gg_*()` function.

## Value

A ggplot object.

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
ggplot2::autoplot(mod, "wright")
```
