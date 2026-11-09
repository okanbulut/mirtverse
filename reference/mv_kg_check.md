# Check a knowledge graph for problems

Runs structural checks on a knowledge graph before it is used to build a
model. The flags use the same three levels as the [assessment
pipeline](https://www.okanbulut.com/mirtverse/reference/mv_pipeline.md):
`block` (the graph cannot be used as it is), `review` (a psychometrician
should look) and `info`.

## Usage

``` r
mv_kg_check(kg, min_items = 3)
```

## Arguments

- kg:

  a knowledge graph from
  [`mv_kg_build()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md)
  or
  [`as_mv_kg()`](https://www.okanbulut.com/mirtverse/reference/as_mv_kg.md).

- min_items:

  smallest number of items per concept before a `few_items` flag.

## Value

A tibble of class `mv_kg_check` with columns `check`, `level`, `nodes`
(the concepts or items involved) and `message`; zero rows when nothing
was found.

## Details

The checks:

- `cycle` (block): Prerequisite edges form a cycle, so no learning order
  exists.

- `self_loop` (block): A concept is listed as its own prerequisite.

- `few_items` (review): A concept is measured by fewer than `min_items`
  items, too few to estimate it as its own dimension.

- `unmeasured` (review): A concept is measured by no item. This is fine
  for a concept that only organizes the graph, but it cannot be scored.

- `same_items` (review): Two concepts are measured by exactly the same
  items, so the data cannot tell them apart.

- `redundant_prerequisite` (info): A prerequisite edge is implied by a
  longer path (A before B before C makes A before C redundant).

- `isolated` (info): A concept has no relations to other concepts, in a
  graph where other concepts do have relations.

- `duplicate_edge` (info): The same edge is listed more than once.

## Examples

``` r
mv_kg_check(fractions_kg)
#> <mv_kg_check> 0 block, 0 review, 1 info
#> * [info] isolated: compare has no relations to other concepts.
mv_kg_check(fraction_subtraction_kg)
#> <mv_kg_check> 0 block, 1 review, 0 info
#> * [review] few_items: column_borrow is measured by 2 item(s); at least
#>   3 are needed to estimate it as its own dimension.
```
