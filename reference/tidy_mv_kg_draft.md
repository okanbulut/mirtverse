# Tidy methods for drafted knowledge graphs

Tidy methods for drafted knowledge graphs

## Usage

``` r
# S3 method for class 'mv_kg_draft'
tidy(x, what = c("nodes", "edges", "items", "reasons", "flags"), ...)
```

## Arguments

- x:

  a draft from
  [`mv_kg_extract()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_extract.md).

- what:

  `"nodes"`, `"edges"` or `"items"` as for any knowledge graph (see
  [`tidy.mv_kg()`](https://www.okanbulut.com/mirtverse/reference/tidy_mv_kg.md));
  `"reasons"` for the model's reason for every link and prerequisite
  edge it returned (with `kept = FALSE` for those the checks dropped);
  or `"flags"` for the problems the checks found.

- ...:

  unused.

## Value

A tibble.
