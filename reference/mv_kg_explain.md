# Explain item difficulty with a knowledge graph

Fits an explanatory item response model in which the knowledge graph
predicts how hard each item is: A linear logistic test model (LLTM;
Fischer, 1973) with a random item effect for the part of difficulty the
graph leaves unexplained (De Boeck, 2008), estimated with the eirm
package (Bulut et al., 2021). Two sets of predictors are offered:

## Usage

``` r
mv_kg_explain(kg, data, predictors = c("concepts", "depth"))
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
}
#> <mv_kg_explain> Grade 5 fractions: Item difficulty explained by learning-order depth
#> 24 items, N = 1200. The graph explains 50% of the item variance.
#>                 label difficulty   se p.value
#>  Learning-order depth       0.44 0.12  <0.001
#>    Number of concepts       0.03 0.39    0.94
# }
```
