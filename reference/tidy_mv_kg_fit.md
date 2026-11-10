# Tidy and glance methods for knowledge graph checks

Tidy and glance methods for knowledge graph checks

## Usage

``` r
# S3 method for class 'mv_kg_fit'
tidy(x, what = c("flags", "items", "relations"), ...)

# S3 method for class 'mv_kg_fit'
glance(x, ...)
```

## Arguments

- x:

  a result of
  [`mv_kg_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_fit.md).

- what:

  `"flags"` (the default), `"items"` for the evidence on each item, or
  `"relations"` for the evidence on each pair of concepts.

- ...:

  unused.

## Value

A tibble.
