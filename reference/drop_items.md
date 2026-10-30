# Remove items from a pipeline

Drops items from the response data (and the response times), marks every
open flag about them as fixed, and logs the decision. A model fitted
earlier no longer matches the data, so
[`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md)
has to be run again.

## Usage

``` r
drop_items(p, items, note = "")
```

## Arguments

- p:

  a pipeline with responses from
  [`add_responses()`](https://www.okanbulut.com/mirtverse/reference/add_responses.md).

- items:

  item names to remove.

- note:

  the reason, kept in the log and the report.

## Value

The pipeline without the items.

## Examples

``` r
# \donttest{
p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
p <- drop_items(p, "Q14", note = "Miskeyed")
# }
```
