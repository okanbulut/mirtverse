# Add or drop edges of a knowledge graph by hand

Makes the changes a reviewer decides on: Add or drop item links,
prerequisite edges or related edges. Use it after
[`mv_kg_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_fit.md)
or
[`mv_kg_compare()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_compare.md)
for the changes that
[`mv_kg_refine()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_refine.md)
does not make on its own, such as dropping a prerequisite edge the data
do not support.

## Usage

``` r
mv_kg_edit(kg, add = NULL, drop = NULL, name = NULL)
```

## Arguments

- kg:

  a knowledge graph from
  [`mv_kg_build()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md)
  or
  [`as_mv_kg()`](https://www.okanbulut.com/mirtverse/reference/as_mv_kg.md).

- add, drop:

  optional edges: Data frames with columns `from` and `to` and an
  optional `type`. An edge from an item is an item link (`"measures"`);
  other edges are `"prerequisite"` unless `type` says `"related"`. Edges
  are dropped before they are added.

- name:

  optional new name; by default the name is kept.

## Value

An `mv_kg` object, with the item metadata kept. An item whose last link
is dropped leaves the graph, with a warning.

## Examples

``` r
# the two changes the data suggest for the published fractions graph
kg <- mv_kg_edit(fractions_kg,
  add = data.frame(from = c("equivalent", "F14"), to = c("compare", "common_denominator")),
  drop = data.frame(from = "F14", to = "compare"))
mv_kg_compare(kg, lab_truth("fractions")$graph)
#> <mv_kg_compare> Grade 5 fractions vs Grade 5 fractions (true graph)
#> Item links: 27 of the 27 reference links are in the graph (recall
#>   1.00), and 27 of the graph's 27 links are in the reference (precision
#>   1.00).
#> 24 of 24 items are linked to exactly the same concepts.
#> Prerequisites: 6 of 6 reference edges found (recall 1.00).
```
