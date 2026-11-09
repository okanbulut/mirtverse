# Write a mirt model from a knowledge graph

Turns a knowledge graph into a confirmatory multidimensional model for
[`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html):
Each concept that items measure becomes a factor, each item loads on the
concepts it measures, and the graph decides which factors may correlate.

## Usage

``` r
mv_kg_model(
  kg,
  data = NULL,
  structure = c("correlated", "graph", "orthogonal")
)
```

## Arguments

- kg:

  a knowledge graph from
  [`mv_kg_build()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md)
  or
  [`as_mv_kg()`](https://www.okanbulut.com/mirtverse/reference/as_mv_kg.md).

- data:

  optional response data; only its items that are in the graph are used,
  in the order of the data. Defaults to the items of the graph.

- structure:

  `"correlated"`, `"graph"` or `"orthogonal"`.

## Value

A
[`mirt::mirt.model()`](https://philchalmers.github.io/mirt/reference/mirt.model.html)
object. The `mirt` syntax is in its `"item_syntax"` attribute, and
[`print()`](https://rdrr.io/r/base/print.html) shows it.

## Details

The `structure` sets the factor correlations:

- `"correlated"` (the default): All concepts correlate, the usual
  confirmatory model.

- `"graph"`: Only concepts joined directly by a prerequisite or related
  edge correlate; the others are fixed to be uncorrelated. This is a
  strict reading of the graph. Concepts on the same learning path
  usually correlate even when they are not neighbours, so expect
  [`anova()`](https://rdrr.io/r/stats/anova.html) to favour
  `"correlated"`; the size of the gap shows how much the indirect links
  matter.

- `"orthogonal"`: No correlations.

## Examples

``` r
spec <- mv_kg_model(fractions_kg)
cat(attr(spec, "item_syntax"))
#> meaning = F01, F02, F03, F04
#> equivalent = F05, F06, F07, F08
#> mixed = F09, F10, F11, F12, F23
#> compare = F13, F14, F15, F16
#> common_denominator = F17, F18, F19, F22, F24
#> add_subtract = F20, F21, F22, F23, F24
#> COV = meaning*equivalent, meaning*mixed, meaning*compare, meaning*common_denominator, meaning*add_subtract, equivalent*mixed, equivalent*compare, equivalent*common_denominator, equivalent*add_subtract, mixed*compare, mixed*common_denominator, mixed*add_subtract, compare*common_denominator, compare*add_subtract, common_denominator*add_subtract
```
