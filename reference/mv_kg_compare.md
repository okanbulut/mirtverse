# Compare a knowledge graph with a reference graph

Measures how far a graph, such as a draft from
[`mv_kg_extract()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_extract.md),
agrees with a reference graph, such as an expert Q-matrix: Which item
links and prerequisite edges the two share, which only one has, and how
many items are linked to exactly the same concepts.

## Usage

``` r
mv_kg_compare(kg, reference, match = c("auto", "name", "items"))
```

## Arguments

- kg:

  the graph to check.

- reference:

  the reference graph.

- match:

  `"auto"` (the default) matches concepts by name when every concept of
  `kg` is in `reference` and by their items otherwise; `"name"` or
  `"items"` force one.

## Value

An object of class `mv_kg_compare` with `summary` (precision, recall and
F1 for item links and prerequisite edges), `items` (one row per shared
item, with the concepts each graph gives it and the links missing from
or extra to `kg`), `concepts` (the matching) and `prerequisites` (every
edge in either graph and whether it is shared, reversed or in one graph
only). Precision is the share of `kg`'s links that are in the reference;
recall is the share of the reference's links that `kg` has.

## Details

When the graphs use different concept names (for example when a model
proposed its own concepts), each concept of `kg` is matched to the
reference concept whose items overlap most (the largest Jaccard index),
and the comparison uses the matched names. `tidy(x, "concepts")` shows
the matching.

## Examples

``` r
# two hand-made Q-matrices for the same four items
expert <- as_mv_kg(matrix(c(1, 0, 1, 0, 0, 1, 1, 1), ncol = 2,
                          dimnames = list(paste0("Q", 1:4), c("number", "algebra"))))
other <- as_mv_kg(matrix(c(1, 1, 1, 0, 0, 0, 1, 1), ncol = 2,
                         dimnames = list(paste0("Q", 1:4), c("number", "algebra"))))
cmp <- mv_kg_compare(other, expert)
cmp
#> <mv_kg_compare> Graph vs Reference
#> Item links: 4 of the 5 reference links are in the graph (recall 0.80),
#>   and 4 of the graph's 5 links are in the reference (precision 0.80).
#> 3 of 4 items are linked to exactly the same concepts.
#> Items that differ: Q2 (missing algebra; extra number).
#> Prerequisites: The graph has 0; the reference has none to compare with.
tidy(cmp, "items")
#> # A tibble: 4 × 6
#>   item  graph           reference       missing   extra    agree
#>   <chr> <chr>           <chr>           <chr>     <chr>    <lgl>
#> 1 Q1    number          number          ""        ""       TRUE 
#> 2 Q2    number          algebra         "algebra" "number" FALSE
#> 3 Q3    algebra, number algebra, number ""        ""       TRUE 
#> 4 Q4    algebra         algebra         ""        ""       TRUE 

# a language model's draft against Tatsuoka's Q-matrix
if (requireNamespace("ellmer", quietly = TRUE)) {
  old <- mv_llm_replay()
  draft <- mv_kg_extract(fraction_subtraction_kg,
                         subject = "Middle school fraction subtraction")
  print(mv_kg_compare(draft, fraction_subtraction_kg))
  options(old)
}
#> Language model calls now answer from examples.json (26 recorded requests).
#> <mv_kg_compare> Fraction subtraction (Tatsuoka) (drafted) vs Fraction subtraction (Tatsuoka)
#> Item links: 53 of the 56 reference links are in the graph (recall
#>   0.95), and 53 of the graph's 54 links are in the reference (precision
#>   0.98).
#> 16 of 20 items are linked to exactly the same concepts.
#> Items that differ: FS01 (missing column_borrow), FS04 (missing
#>   borrow_whole), FS08 (extra reduce_answer), FS13 (missing
#>   common_denominator).
#> Prerequisites: The graph has 7; the reference has none to compare with.
```
