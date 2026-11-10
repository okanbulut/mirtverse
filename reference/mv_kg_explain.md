# Explain item difficulty with a knowledge graph

Fits an explanatory item response model in which the knowledge graph
predicts how hard each item is: A linear logistic test model (LLTM;
Fischer, 1973) with a random item effect for the part of difficulty the
graph leaves unexplained (De Boeck, 2008), estimated with the eirm
package (Bulut et al., 2021). Two sets of predictors are offered:

## Usage

``` r
mv_kg_explain(kg, data, predictors = c("concepts", "depth"), covariates = NULL)
```

## Arguments

- kg:

  a knowledge graph from
  [`mv_kg_build()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md)
  or
  [`as_mv_kg()`](https://www.okanbulut.com/mirtverse/reference/as_mv_kg.md).

- data:

  a data frame or matrix of 0/1 item scores; columns that are not items
  of the graph, such as an ID, are skipped.

- predictors:

  `"concepts"` or `"depth"`.

- covariates:

  optional names of item metadata columns to add as predictors (see
  [`mv_kg_annotate()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_annotate.md)).

## Value

An object of class `mv_kg_explain`: A list with `effects` (one row per
predictor, with its `difficulty`, standard error and p value), `items`
(each item's difficulty in the Rasch model, the difficulty the graph
predicts, and the residual), `fit` (the two models' variances and
information criteria), and the two
[`eirm::eirm()`](https://rdrr.io/pkg/eirm/man/eirm.html) fits in `model`
and `base`. Difficulties are on the logit scale, with higher values for
harder items.

## Details

- `"concepts"`: One indicator per concept, from the graph's Q-matrix.
  Each concept gets its own difficulty, and an item that needs several
  concepts gets the sum.

- `"depth"`: The item's place in the learning order (the largest
  prerequisite depth among its concepts) and the number of concepts it
  needs. This tests the graph's claim that later concepts are harder.

Item metadata added with
[`mv_kg_annotate()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_annotate.md),
such as word count or item format, can join either set through
`covariates`. Numeric columns are centred, so the concept difficulties
refer to an item of average value; other columns get one 0/1 indicator
for each value but the first. This asks whether a feature of the items
explains difficulty beyond what the graph does.

A Rasch model with random items and no predictors is fitted too, and
`explained` in
[`glance()`](https://generics.r-lib.org/reference/glance.html) is the
share of its item variance that the predictors account for.

## References

Bulut, O., Gorgun, G., & Yildirim-Erbasli, S. N. (2021). Estimating
explanatory extensions of dichotomous and polytomous Rasch models: The
eirm package in R. *Psych, 3*(3), 308-321.

De Boeck, P. (2008). Random item IRT models. *Psychometrika, 73*(4),
533-559.

Fischer, G. H. (1973). The linear logistic test model as an instrument
in educational research. *Acta Psychologica, 37*(6), 359-374.

## See also

[`predict_difficulty()`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md)
for difficulty from item text features.

## Examples

``` r
# \donttest{
if (requireNamespace("eirm", quietly = TRUE)) {
  ex <- mv_kg_explain(fractions_kg, fractions)
  ex
  tidy(ex)
  mv_kg_explain(fractions_kg, fractions, predictors = "depth")

  # does the item format explain difficulty beyond the concepts?
  kg <- mv_kg_annotate(fractions_kg, data.frame(
    item = sprintf("F%02d", 1:24), format = rep(c("choice", "open"), 12)))
  mv_kg_explain(kg, fractions, covariates = "format")
}
#> <mv_kg_explain> Grade 5 fractions: Item difficulty explained by concepts and item metadata
#> 24 items, N = 1200. The graph explains 91% of the item variance.
#>                     label difficulty   se p.value
#>                   meaning      -1.53 0.13  <0.001
#>                equivalent      -0.43 0.13  <0.001
#>                     mixed      -0.39 0.11  <0.001
#>                   compare       0.05 0.13    0.68
#>        common_denominator       0.01 0.12    0.96
#>              add_subtract       0.67 0.12  <0.001
#>  format: open (vs choice)      -0.03 0.09    0.74
#> Items the graph predicts poorly: F22 (-0.59).
# }
```
