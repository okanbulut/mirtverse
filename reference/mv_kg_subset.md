# Keep part of a knowledge graph

Returns the part of a graph that covers chosen concepts or items: The
concepts kept, the relations among them, and the items that measure at
least one of them. Useful for fitting a model to a few well-measured
concepts, or to the items a data set actually has.

## Usage

``` r
mv_kg_subset(kg, concepts = NULL, items = NULL)
```

## Arguments

- kg:

  a knowledge graph from
  [`mv_kg_build()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md)
  or
  [`as_mv_kg()`](https://www.okanbulut.com/mirtverse/reference/as_mv_kg.md).

- concepts:

  concepts to keep (default: All).

- items:

  optional items to keep, as names or a data frame whose column names
  are used; other columns (such as an ID) are skipped.

## Value

An `mv_kg` object. Items left without a concept are dropped.

## Examples

``` r
kg3 <- mv_kg_subset(fraction_subtraction_kg,
                    c("separate_whole", "borrow_whole", "common_denominator"))
kg3
#> <mv_kg> Fraction subtraction (Tatsuoka): 3 concept(s), 16 item(s)
#> Edges: 0 prerequisite, 0 related, 26 measures
```
