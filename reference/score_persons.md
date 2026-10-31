# Pipeline stage: score test takers

Estimates each test taker's ability from the calibrated model with
[`mirt::fscores()`](https://philchalmers.github.io/mirt/reference/fscores.html)
and checks the scores (thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

## Usage

``` r
score_persons(p, method = c("EAP", "MAP", "ML", "WLE"))
```

## Arguments

- p:

  a calibrated pipeline.

- method:

  scoring method passed to
  [`mirt::fscores()`](https://philchalmers.github.io/mirt/reference/fscores.html):
  `"EAP"`, `"MAP"`, `"ML"` or `"WLE"`.

## Value

The pipeline with `p$scores`, a tibble with one row per test taker
(`id`, `theta`, `se`, and `group` if the data have one).

## Details

- `score_reliability` (review): the empirical reliability of the scores
  is below `reliability` (the blueprint's target, if one was set).

- `extreme_scores` (info): maximum-likelihood estimates that are
  infinite (all or none correct) or standard errors above `max_se`.

## Examples

``` r
# \donttest{
p <- calibrate(add_responses(mv_pipeline(), expand.table(LSAT7)), model = "2PL")
p <- score_persons(p)
#> Warning: Scoring is running with 3 review open flag(s) from earlier stages:
#>   #1 [review] local_dependence: Item.1 & Item.3 (Q3 = -0.21)
#>   #2 [review] item_misfit: Item.2 (S-X2 = 14.5, adjusted p = .004)
#>   #3 [review] low_reliability: test (marginal reliability = 0.44)
#> Flags only warn because strict = FALSE. See flags(p).
head(p$scores)
#> # A tibble: 6 × 3
#>   id    theta    se
#>   <chr> <dbl> <dbl>
#> 1 1     -1.87 0.693
#> 2 2     -1.87 0.693
#> 3 3     -1.87 0.693
#> 4 4     -1.87 0.693
#> 5 5     -1.87 0.693
#> 6 6     -1.87 0.693
# }
```
