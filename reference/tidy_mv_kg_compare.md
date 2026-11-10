# Tidy and glance methods for graph comparisons

Tidy and glance methods for graph comparisons

## Usage

``` r
# S3 method for class 'mv_kg_compare'
tidy(x, what = c("summary", "items", "concepts", "prerequisites"), ...)

# S3 method for class 'mv_kg_compare'
glance(x, ...)
```

## Arguments

- x:

  a result of
  [`mv_kg_compare()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_compare.md).

- what:

  `"summary"` (the default), `"items"`, `"concepts"` or
  `"prerequisites"` for
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html).

- ...:

  unused.

## Value

A tibble.
