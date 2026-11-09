# Fit a confirmatory IRT model built from a knowledge graph

Writes the model with
[`mv_kg_model()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_model.md)
and fits it with
[`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).
The result is an ordinary mirt model, so
[`tidy()`](https://generics.r-lib.org/reference/tidy.html),
[`glance()`](https://generics.r-lib.org/reference/glance.html),
[`anova()`](https://rdrr.io/r/stats/anova.html),
[`mirt::M2()`](https://philchalmers.github.io/mirt/reference/M2.html)
and the other mirtverse and mirt functions work on it; the graph is kept
in its `"mv_kg"` attribute.

## Usage

``` r
mv_kg_irt(
  kg,
  data,
  structure = c("correlated", "graph", "orthogonal"),
  itemtype = "2PL",
  method = NULL,
  ...
)
```

## Arguments

- kg:

  a knowledge graph from
  [`mv_kg_build()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md)
  or
  [`as_mv_kg()`](https://www.okanbulut.com/mirtverse/reference/as_mv_kg.md).

- data:

  response data. Columns that are not items of the graph, such as an ID
  column, are dropped.

- structure:

  `"correlated"`, `"graph"` or `"orthogonal"`.

- itemtype:

  item type passed to
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html),
  such as `"2PL"` or `"graded"`.

- method:

  estimation method; defaults to `"EM"` with up to three concepts and
  `"QMCEM"` with more.

- ...:

  further arguments passed to
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

## Value

A fitted mirt model (class `SingleGroupClass`) with the graph in
attribute `"mv_kg"` and the structure in attribute `"mv_kg_structure"`.

## Details

With more than three concepts the default estimation method is
quasi-Monte Carlo EM (`"QMCEM"`), which is much faster than standard EM
in many dimensions; set `method` to change it.

## Examples

``` r
# \donttest{
# about two minutes each: six concepts, 1,200 students
published <- mv_kg_irt(fractions_kg, fractions)
glance(published)
#> # A tibble: 1 × 20
#>    nobs nitems nfact itemtype  npar  logLik    AIC    BIC  SABIC converged
#>   <int>  <int> <int> <chr>    <int>   <dbl>  <dbl>  <dbl>  <dbl> <lgl>    
#> 1  1200     24     6 2PL         66 -16742. 33617. 33953. 33743. TRUE     
#> # ℹ 10 more variables: method <chr>, fit_stat <chr>, M2 <dbl>, df <int>,
#> #   p.value <dbl>, RMSEA <dbl>, SRMSR <dbl>, CFI <dbl>, TLI <dbl>,
#> #   reliability <dbl>
# the strict reading of the graph: Only neighbours correlate
strict <- mv_kg_irt(fractions_kg, fractions, structure = "graph")
#> Warning: Observed log-likelihood may still be increasing.
#>   Final log-likelihood values were: 
#>   -17122.247, -17122.244, -17122.241
anova(strict, published)
#>                AIC    SABIC       HQ      BIC    logLik      X2 df p
#> strict    34356.48 34463.64 34463.85 34641.52 -17122.24             
#> published 33616.61 33742.92 33743.16 33952.56 -16742.31 759.865 10 0
# the true graph (lab_truth) fits better than the published one
true <- mv_kg_irt(lab_truth("fractions")$graph, fractions)
#> Warning: Log-likelihood was decreasing near the ML solution. EM method may be unstable
anova(published, true)
#>                AIC    SABIC       HQ      BIC    logLik     X2 df   p
#> published 33616.61 33742.92 33743.16 33952.56 -16742.31              
#> true      33565.68 33691.99 33692.23 33901.63 -16716.84 50.927  0 NaN
# }
# a quick two-concept model
kg2 <- mv_kg_build(c("meaning", "equivalent"),
                   items = data.frame(item = sprintf("F%02d", 1:8),
                                      concept = rep(c("meaning", "equivalent"), each = 4)))
mod <- mv_kg_irt(kg2, fractions)
tidy(mod)
#> # A tibble: 24 × 5
#>    item  itemtype term  estimate std.error
#>    <chr> <chr>    <chr>    <dbl>     <dbl>
#>  1 F01   2PL      a1        1.53        NA
#>  2 F01   2PL      a2        0           NA
#>  3 F01   2PL      d         1.75        NA
#>  4 F02   2PL      a1        1.32        NA
#>  5 F02   2PL      a2        0           NA
#>  6 F02   2PL      d         1.32        NA
#>  7 F03   2PL      a1        1.79        NA
#>  8 F03   2PL      a2        0           NA
#>  9 F03   2PL      d         2.16        NA
#> 10 F04   2PL      a1        1.42        NA
#> # ℹ 14 more rows
```
