# Apply suggested changes to a knowledge graph

Returns a new graph with the changes
[`mv_kg_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_fit.md)
suggested: Items moved to (or also linked to) another concept, weak
links dropped, and missing prerequisite or related edges added. Flags
without a suggested change, such as `weak_relation` or `order`, are left
for you to decide.

## Usage

``` r
mv_kg_refine(fit, accept = "all")
```

## Arguments

- fit:

  a result of
  [`mv_kg_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_fit.md).

- accept:

  which suggestions to apply: `"all"`, `"items"` (only the item link
  changes), `"relations"` (only the new edges), or row numbers of
  `tidy(fit)`.

## Value

An `mv_kg` object. Its name ends in "(refined)".

## Examples

``` r
# \donttest{
fit <- mv_kg_fit(fractions_kg, fractions)
refined <- mv_kg_refine(fit, "items")
refined
#> <mv_kg> Grade 5 fractions (refined): 6 concept(s), 24 item(s)
#> Edges: 5 prerequisite, 0 related, 27 measures
#> Item metadata: text
#> Learning order (by prerequisite depth):
#>   0: meaning, compare
#>   1: equivalent, mixed
#>   2: common_denominator
#>   3: add_subtract
# }
```
