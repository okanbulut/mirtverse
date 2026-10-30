# An item bank

An item bank holds calibrated items on one common scale, with their mirt
parameters, a summary of their location and discrimination, where they
came from and whether they are in use. Start a bank from a calibrated
model or pipeline with `mv_bank()`, put a new calibration on the bank's
scale with
[`link_to_bank()`](https://www.okanbulut.com/mirtverse/reference/link_to_bank.md),
and add its new items with
[`bank_items()`](https://www.okanbulut.com/mirtverse/reference/bank_items.md).
A bank is an ordinary R object: keep it between administrations with
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html) and
[`readRDS()`](https://rdrr.io/r/base/readRDS.html).

## Usage

``` r
mv_bank(x, name = "Item bank", source = NULL)

# S3 method for class 'mv_bank'
tidy(x, ...)
```

## Arguments

- x:

  a unidimensional model from
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html),
  or a calibrated pipeline from
  [`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md)
  (if the pipeline was linked with
  [`link_to_bank()`](https://www.okanbulut.com/mirtverse/reference/link_to_bank.md),
  its parameters are taken on the bank's scale).

- name:

  a name for the bank.

- source:

  a label for where the items came from, such as the administration.
  Defaults to the pipeline title, or `"calibration"`.

- ...:

  not used.

## Value

An object of class `mv_bank`: a list with `name`, `items` (a tibble with
one row per item: `item`, `itemtype`, `ncat`, `a` (discrimination), `b`
(location; the mean threshold for polytomous items), `g` (lower
asymptote), `source`, `added`, `status` and the list column `pars` with
the mirt slope-intercept parameters) and `history`.

## Details

Supported item types are the unidimensional `"Rasch"`, `"2PL"`, `"3PL"`,
`"graded"` and `"gpcm"` models.

## See also

[`bank_items()`](https://www.okanbulut.com/mirtverse/reference/bank_items.md),
[`link_to_bank()`](https://www.okanbulut.com/mirtverse/reference/link_to_bank.md)

## Examples

``` r
# \donttest{
mod <- mirt(expand.table(LSAT7), 1, itemtype = "2PL", verbose = FALSE)
bank <- mv_bank(mod, name = "LSAT bank")
bank
#> <mv_bank> LSAT bank: 5 items (5 active)
#> Item types: 2PL 5 
#> Location (b) from -2.52 to -0.64; median discrimination 0.99
#> Sources: calibration 
# }
```
