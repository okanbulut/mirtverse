# Item health card

A one-page visual summary of a single item for item review meetings:
trace curves, information, observed versus expected scores, the response
distribution and a key-statistics panel with a traffic-light status.

## Usage

``` r
item_card(x, item, alpha = 0.01, tab = NULL)
```

## Arguments

- x:

  a unidimensional model from
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- item:

  a single item, by position or name.

- alpha:

  significance level for item misfit.

- tab:

  optional precomputed
  [`item_table()`](https://www.okanbulut.com/mirtverse/reference/item_table.md)
  (saves time when making many cards).

## Value

A patchwork object.

## Details

Status rules: **red** for misfit, low discrimination (a \< 0.5) or an
item-total correlation below .10; **amber** for any other flag (see
[`item_table()`](https://www.okanbulut.com/mirtverse/reference/item_table.md));
**green** otherwise.

## Examples

``` r
mod <- mirt(Science, 1, verbose = FALSE)
item_card(mod, "Work")
```
