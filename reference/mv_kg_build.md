# Build a knowledge graph of concepts and items

A knowledge graph describes what a test measures as a network: Concepts
(skills, attributes, learning objectives), the items that measure them,
and the relations between concepts. `mv_kg_build()` puts these pieces
into one `mv_kg` object that the other `mv_kg_*()` functions and
[`gg_kg()`](https://www.okanbulut.com/mirtverse/reference/gg_kg.md)
read. The graph is stored as two tibbles, one of nodes and one of edges,
so no graph package is needed.

## Usage

``` r
mv_kg_build(concepts, edges = NULL, items = NULL, name = NULL, meta = NULL)
```

## Arguments

- concepts:

  the concepts: A character vector of names, or a data frame with a
  column `concept` and optional columns `label` (a longer name for
  plots) and `description`.

- edges:

  optional relations between concepts: A data frame with columns `from`
  and `to` and an optional column `type` (`"prerequisite"`, the default,
  or `"related"`) and `weight`.

- items:

  optional item-to-concept links: Either a data frame in long form with
  columns `item` and `concept` (one row per link, optional `weight`), or
  a Q-matrix (a matrix or data frame of 0/1 with one row per item and
  one column per concept; item names come from the row names or a column
  `item`).

- name:

  optional name of the graph, shown when it is printed.

- meta:

  optional item metadata: A data frame with one row per item, an id
  column `item` (or `id`) and any other columns, such as item text,
  format or word count. See
  [`mv_kg_annotate()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_annotate.md).

## Value

An object of class `mv_kg`: A list with `nodes` (a tibble with `node`,
`kind` (`"concept"` or `"item"`), `label` and `description`), `edges` (a
tibble with `from`, `to`, `type` and `weight`), `name`, and, when
metadata is given, `meta` (a tibble with one row per item).

## Details

Three kinds of edges are used:

- `prerequisite`: A directed edge between two concepts. `from` must be
  learned before `to` (for example, equivalent fractions before adding
  fractions with unlike denominators). Prerequisite edges should form a
  directed acyclic graph;
  [`mv_kg_check()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_check.md)
  flags cycles.

- `related`: An undirected link between two concepts that are connected
  but where neither comes first.

- `measures`: A link from an item to a concept it measures. The items
  and their concepts are the rows of a Q-matrix.

## See also

[`as_mv_kg()`](https://www.okanbulut.com/mirtverse/reference/as_mv_kg.md)
to build a graph from a Q-matrix, an edge list, a fitted confirmatory
mirt model or an igraph object;
[`mv_kg_check()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_check.md)
and [`gg_kg()`](https://www.okanbulut.com/mirtverse/reference/gg_kg.md);
the
[fractions_kg](https://www.okanbulut.com/mirtverse/reference/fractions.md)
and
[fraction_subtraction_kg](https://www.okanbulut.com/mirtverse/reference/fraction_subtraction.md)
examples.

## Examples

``` r
kg <- mv_kg_build(
  concepts = c("meaning", "equivalent", "add"),
  edges = data.frame(from = c("meaning", "equivalent"),
                     to = c("equivalent", "add")),
  items = data.frame(item = c("Q1", "Q2", "Q3", "Q4"),
                     concept = c("meaning", "equivalent", "add", "add")))
kg
#> <mv_kg> 3 concept(s), 4 item(s)
#> Edges: 2 prerequisite, 0 related, 4 measures
#> Learning order (by prerequisite depth):
#>   0: meaning
#>   1: equivalent
#>   2: add
tidy(kg, "edges")
#> # A tibble: 6 × 4
#>   from       to         type         weight
#>   <chr>      <chr>      <chr>         <dbl>
#> 1 meaning    equivalent prerequisite      1
#> 2 equivalent add        prerequisite      1
#> 3 Q1         meaning    measures          1
#> 4 Q2         equivalent measures          1
#> 5 Q3         add        measures          1
#> 6 Q4         add        measures          1
gg_kg(kg)
```
