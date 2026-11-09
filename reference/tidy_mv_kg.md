# Tidy and glance methods for knowledge graphs

[`tidy()`](https://generics.r-lib.org/reference/tidy.html) returns the
nodes or edges of a knowledge graph as a tibble;
[`glance()`](https://generics.r-lib.org/reference/glance.html) returns a
one-row summary.

## Usage

``` r
# S3 method for class 'mv_kg'
tidy(x, what = c("nodes", "edges"), ...)

# S3 method for class 'mv_kg'
glance(x, ...)
```

## Arguments

- x:

  a knowledge graph from
  [`mv_kg_build()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md)
  or
  [`as_mv_kg()`](https://www.okanbulut.com/mirtverse/reference/as_mv_kg.md).

- what:

  `"nodes"` or `"edges"` for
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html). Nodes get
  the number of items (for concepts) or concepts (for items) they are
  linked to and, for concepts, their prerequisite `depth`.

- ...:

  unused.

## Value

A tibble.

## Examples

``` r
tidy(fractions_kg)
#> # A tibble: 30 × 6
#>    node               kind    label                  description     links depth
#>    <chr>              <chr>   <chr>                  <chr>           <dbl> <dbl>
#>  1 meaning            concept Fraction meaning       A fraction nam…     4     0
#>  2 equivalent         concept Equivalent fractions   Different frac…     4     1
#>  3 mixed              concept Mixed numbers          Moving between…     5     1
#>  4 compare            concept Comparing fractions    Ordering fract…     4     0
#>  5 common_denominator concept Common denominators    Rewriting frac…     5     2
#>  6 add_subtract       concept Adding and subtracting Adding and sub…     5     3
#>  7 F01                item    F01                    NA                  1    NA
#>  8 F02                item    F02                    NA                  1    NA
#>  9 F03                item    F03                    NA                  1    NA
#> 10 F04                item    F04                    NA                  1    NA
#> # ℹ 20 more rows
tidy(fractions_kg, "edges")
#> # A tibble: 32 × 4
#>    from               to                 type         weight
#>    <chr>              <chr>              <chr>         <dbl>
#>  1 meaning            equivalent         prerequisite      1
#>  2 meaning            mixed              prerequisite      1
#>  3 equivalent         common_denominator prerequisite      1
#>  4 common_denominator add_subtract       prerequisite      1
#>  5 mixed              add_subtract       prerequisite      1
#>  6 F01                meaning            measures          1
#>  7 F02                meaning            measures          1
#>  8 F03                meaning            measures          1
#>  9 F04                meaning            measures          1
#> 10 F05                equivalent         measures          1
#> # ℹ 22 more rows
glance(fractions_kg)
#> # A tibble: 1 × 7
#>   concepts items prerequisite related measures acyclic depth
#>      <int> <int>        <int>   <int>    <int> <lgl>   <dbl>
#> 1        6    24            5       0       27 TRUE        3
```
