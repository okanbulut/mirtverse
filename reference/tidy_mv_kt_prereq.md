# Tidy a prerequisite check

Tidy a prerequisite check

## Usage

``` r
# S3 method for class 'mv_kt_prereq'
tidy(x, what = c("pairs", "flags"), ...)

# S3 method for class 'mv_kt_prereq'
glance(x, ...)
```

## Arguments

- x:

  a result of
  [`mv_kt_prereq()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_prereq.md).

- what:

  `"pairs"` (every ordered pair of skills, the default) or `"flags"`.

- ...:

  unused.

## Value

A tibble. [`glance()`](https://generics.r-lib.org/reference/glance.html)
counts the graph's edges, the supported and weak ones, and the suggested
missing ones.
