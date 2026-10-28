# One-row model summary

Collects sample size, information criteria, convergence,
limited-information fit (M2 or C2) and marginal reliability in a single
row, which makes it easy to compare models with
[`rbind()`](https://rdrr.io/r/base/cbind.html).

## Usage

``` r
# S3 method for class 'SingleGroupClass'
glance(x, fit = TRUE, ...)

# S3 method for class 'MultipleGroupClass'
glance(x, ...)
```

## Arguments

- x:

  a model returned by
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- fit:

  logical; compute the M2-family fit statistics. For polytomous items
  the C2 statistic is used.

- ...:

  unused.

## Value

A one-row tibble.

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
glance(mod)
#> # A tibble: 1 × 20
#>    nobs nitems nfact itemtype  npar logLik   AIC   BIC SABIC converged method
#>   <int>  <int> <int> <chr>    <int>  <dbl> <dbl> <dbl> <dbl> <lgl>     <chr> 
#> 1  1000      5     1 2PL         10 -2659. 5338. 5387. 5355. TRUE      EM    
#> # ℹ 9 more variables: fit_stat <chr>, M2 <dbl>, df <int>, p.value <dbl>,
#> #   RMSEA <dbl>, SRMSR <dbl>, CFI <dbl>, TLI <dbl>, reliability <dbl>
```
