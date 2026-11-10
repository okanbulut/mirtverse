# Tidy and glance methods for explained item difficulty

Tidy and glance methods for explained item difficulty

## Usage

``` r
# S3 method for class 'mv_kg_explain'
tidy(x, what = c("effects", "items"), ...)

# S3 method for class 'mv_kg_explain'
glance(x, ...)
```

## Arguments

- x:

  a result of
  [`mv_kg_explain()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_explain.md).

- what:

  `"effects"` (the default) or `"items"` for
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html).

- ...:

  unused.

## Value

A tibble.
