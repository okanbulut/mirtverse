# Health cards for many items

Health cards for many items

## Usage

``` r
item_cards(x, which.items = NULL, file = NULL, alpha = 0.01)
```

## Arguments

- x:

  a unidimensional model from
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- which.items:

  items to include (default: all).

- file:

  optional path to an `.html` file. When given, all cards are written to
  one self-contained page with a status overview table.

- alpha:

  significance level for item misfit.

## Value

A named list of cards (invisibly when `file` is given).

## Examples

``` r
# \donttest{
mod <- mirt(Science, 1, verbose = FALSE)
cards <- item_cards(mod)
item_cards(mod, file = tempfile(fileext = ".html"))
# }
```
