# Compare simulated respondents with real ones (experimental)

**Experimental.** Checks whether the respondents simulated with
[`simulate_llm_respondents()`](https://www.okanbulut.com/mirtverse/reference/simulate_llm_respondents.md)
answer like real test takers. With a vector of real proportions correct,
it compares the items' difficulty. With real responses, it also compares
the spread of total scores and how well each item separates high and low
scorers (item-total correlations). For the simulated answers alone it
counts the distinct response patterns: Real respondents rarely give
identical answers, while language models playing similar personas often
do.

## Usage

``` r
compare_synthetic(synthetic, real, tolerance = 0.1)
```

## Arguments

- synthetic:

  an `mv_synthetic` object.

- real:

  the real data: A data frame or matrix of 0/1 responses with the items
  as columns (named as in `synthetic`), or a named numeric vector of
  proportions correct.

- tolerance:

  the difference in mean proportion correct, and in the correlation of
  item difficulties below 1, that the notes treat as meaningful.

## Value

An object of class `mv_synthetic_comparison`: A list with `items` (a
tibble with `item`, `p_real`, `p_synthetic` and `difference`, plus
`rit_real` and `rit_synthetic` with real responses), `summary` (a
one-row tibble) and `notes` (what the comparison shows, in sentences).
It has [`print()`](https://rdrr.io/r/base/print.html) and
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
methods.

## See also

[`simulate_llm_respondents()`](https://www.okanbulut.com/mirtverse/reference/simulate_llm_respondents.md)

## Examples

``` r
# a small made-up example: synthetic answers that are too easy
syn <- structure(list(
  responses = data.frame(I1 = c(1, 1, 1, 1), I2 = c(1, 1, 1, 0), I3 = c(1, 1, 0, 0)),
  provider = "example", model = ""), class = "mv_synthetic")
compare_synthetic(syn, c(I1 = 0.7, I2 = 0.5, I3 = 0.3))
#> <mv_synthetic_comparison> 4 simulated respondents, 3 items (EXPERIMENTAL)
#>  item p_real p_synthetic difference
#>    I1    0.7        1.00       0.30
#>    I2    0.5        0.75       0.25
#>    I3    0.3        0.50       0.20
#> 
#> * The simulated respondents find the items easier than real test
#>   takers: Mean proportion correct 0.75 against 0.50.
#> * They order the items by difficulty much like real test takers
#>   (Spearman correlation 1.00); this still says nothing about any single
#>   new item.
#> * Their answers vary little: 3 distinct response patterns among 4
#>   simulated respondents. Respondents described alike answer alike.
#> * Simulated respondents are experimental: Use them to find unclear
#>   items or to plan a study, not to estimate item parameters or to
#>   replace a field test.
```
