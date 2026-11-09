# Turn other objects into a knowledge graph

`as_mv_kg()` builds an
[mv_kg](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md)
object from objects you may already have:

## Usage

``` r
as_mv_kg(x, ...)

# S3 method for class 'mv_kg'
as_mv_kg(x, ...)

# S3 method for class 'matrix'
as_mv_kg(x, ...)

# S3 method for class 'data.frame'
as_mv_kg(x, ...)

# S3 method for class 'SingleGroupClass'
as_mv_kg(x, ...)

# S3 method for class 'igraph'
as_mv_kg(x, ...)
```

## Arguments

- x:

  the object to convert.

- ...:

  passed on to
  [`mv_kg_build()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md)
  (for example `name`), or for a Q-matrix, `edges` with relations
  between its concepts.

## Value

An `mv_kg` object.

## Details

- A Q-matrix (a 0/1 matrix or data frame, one row per item and one
  column per concept): Concepts and `measures` edges, with no relations
  between concepts.

- An edge list (a data frame with `from`, `to` and `type`): Rows with
  type `"measures"` become item links, the others concept relations.

- A fitted confirmatory model from
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html):
  Each factor becomes a concept and each non-zero slope a `measures`
  edge, so a graph can be drawn from a model you have already fitted.

- An igraph object: Vertices with a `kind` attribute of `"item"` become
  items, the others concepts; edge `type` attributes are kept.

## Examples

``` r
q <- matrix(c(1, 0,
              1, 0,
              0, 1,
              1, 1), ncol = 2, byrow = TRUE,
            dimnames = list(paste0("Q", 1:4), c("number", "algebra")))
as_mv_kg(q, edges = data.frame(from = "number", to = "algebra"))
#> <mv_kg> 2 concept(s), 4 item(s)
#> Edges: 1 prerequisite, 0 related, 5 measures
#> Learning order (by prerequisite depth):
#>   0: number
#>   1: algebra
```
