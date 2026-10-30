# Pipeline stage: add items to a bank

Adds the items of a calibrated pipeline to an item bank, on the bank's
scale. With no `bank`, a new bank is started from the pipeline. With an
existing bank, the pipeline should first be linked to it with
[`link_to_bank()`](https://www.okanbulut.com/mirtverse/reference/link_to_bank.md)
so that the new items are on the same scale; items already in the bank
(the anchors) keep their bank parameters unless `update_anchors = TRUE`.

## Usage

``` r
bank_items(p, bank = NULL, name = "Item bank", update_anchors = FALSE)
```

## Arguments

- p:

  a calibrated pipeline from
  [`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md).

- bank:

  optional existing bank from
  [`mv_bank()`](https://www.okanbulut.com/mirtverse/reference/mv_bank.md).

- name:

  name for a new bank.

- update_anchors:

  logical; replace the bank parameters of items that are already in the
  bank with the new estimates.

## Value

The pipeline with the bank in `p$bank`. Get it with `p$bank` and save it
with [`saveRDS()`](https://rdrr.io/r/base/readRDS.html).

## Examples

``` r
# \donttest{
p <- add_responses(mv_pipeline("Form A"), certexam, items = 3:34,
                   key = certexam_key)
p <- calibrate(drop_items(p, "Q14"), model = "2PL")
p <- bank_items(p, name = "Certification bank")
p$bank
#> <mv_bank> Certification bank: 31 items (31 active)
#> Item types: 2PL 31 
#> Location (b) from -2.37 to 3.05; median discrimination 0.90
#> Sources: Form A 
# }
```
