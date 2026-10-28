# Joint model for responses and response times

Fits van der Linden's (2007) hierarchical framework on top of a fitted
mirt model. Response times follow a lognormal model, \$\$\log T\_{ij}
\sim N(\beta_j - \tau_i, \alpha_j^{-2}),\$\$ where \\\beta_j\\ is the
time intensity of item *j*, \\\alpha_j\\ its time discrimination and
\\\tau_i\\ the speed of person *i*. Ability and speed are bivariate
normal with correlation \\\rho\\.

## Usage

``` r
fit_rt(
  x,
  rt,
  flag_method = c("residual", "nt10"),
  z_crit = 1.96,
  quadpts = c(41, 21),
  tol = 1e-04,
  maxit = 500,
  verbose = FALSE
)
```

## Arguments

- x:

  a unidimensional model from
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html)
  fitted to the item responses.

- rt:

  a matrix or data frame of response times (in seconds, or any positive
  unit) with the same rows and columns as the response data. Missing
  values are allowed.

- flag_method:

  `"residual"` or `"nt10"`; see Details.

- z_crit:

  critical value for the residual method.

- quadpts:

  number of quadrature points per dimension.

- tol:

  convergence tolerance (largest parameter change).

- maxit:

  maximum number of EM iterations.

- verbose:

  logical; print the log-likelihood during estimation.

## Value

An object of class `mv_rt` with elements `items` (time intensity and
discrimination with SEs), `population` (speed SD and ability-speed
correlation), `persons` (joint ability and speed estimates, RTE and
\\l_t\\), `flags` (logical matrix of rapid responses), `logLik`,
`iterations` and `converged`. Use
[`tidy()`](https://generics.r-lib.org/reference/tidy.html),
[`glance()`](https://generics.r-lib.org/reference/glance.html),
[`augment()`](https://generics.r-lib.org/reference/augment.html),
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
and
[`interpret()`](https://okanbulut.github.io/mirtverse/reference/interpret.md)
on it.

## Details

The item response parameters are taken from `x` and held fixed; the
response-time parameters, the speed variance and the ability-speed
correlation are estimated by marginal maximum likelihood with an EM
algorithm on a two-dimensional quadrature grid. Persons are then scored
jointly, so response times act as collateral information for ability.
Standard errors come from the cross-product of the individual score
contributions.

Rapid responses are flagged in two ways: `"residual"` marks responses
that are much faster than expected for that person on that item
(standardized log-time residual below `-z_crit`); `"nt10"` uses the
normative threshold of 10% of the item's mean time (Wise & Ma, 2012).
Response time effort (RTE; Wise & Kong, 2005) is the proportion of a
person's responses that are not flagged. The \\l_t\\ person-fit
statistic (van der Linden & Guo, 2008) flags aberrant overall timing.

## References

van der Linden, W. J. (2007). A hierarchical framework for modeling
speed and accuracy on test items. *Psychometrika, 72*, 287-308.

van der Linden, W. J., & Guo, F. (2008). Bayesian procedures for
identifying aberrant response-time patterns in adaptive testing.
*Psychometrika, 73*, 365-384.

Wise, S. L., & Kong, X. (2005). Response time effort: A new measure of
examinee motivation in computer-based tests. *Applied Measurement in
Education, 18*, 163-183.

Wise, S. L., & Ma, L. (2012). Setting response time thresholds for a CAT
item pool: The normative threshold method. Paper presented at NCME.

## Examples

``` r
# \donttest{
sim <- sim_rt(N = 1000, J = 15, rho = -0.4, seed = 1)
mod <- mirt(sim$responses, 1, verbose = FALSE)
fit <- fit_rt(mod, sim$rt)
fit
#> Joint model for responses and response times (van der Linden, 2007)
#> 1000 persons, 15 items; converged after 8 iterations; logLik = -20051.23
#> 
#> Speed SD = 0.307 (SE 0.008); ability-speed correlation = -0.360 (SE 0.035)
#> 
#>    item  beta se_beta alpha se_alpha prop_rapid
#>  Item01 4.549   0.021 1.723    0.042      0.027
#>  Item02 3.940   0.024 1.492    0.035      0.037
#>  Item03 4.166   0.018 2.110    0.053      0.022
#>  Item04 3.974   0.016 2.512    0.061      0.020
#>  Item05 3.455   0.017 2.252    0.054      0.019
#>  Item06 3.847   0.016 2.325    0.053      0.022
#>  Item07 3.867   0.019 1.921    0.047      0.021
#>  Item08 3.966   0.019 1.982    0.046      0.019
#>  Item09 4.420   0.016 2.375    0.059      0.019
#>  Item10 4.308   0.017 2.209    0.054      0.020
#>  Item11 3.938   0.018 2.091    0.053      0.021
#>  Item12 3.899   0.020 1.818    0.042      0.026
#>  Item13 4.264   0.021 1.742    0.040      0.025
#>  Item14 4.214   0.017 2.398    0.060      0.015
#>  Item15 3.731   0.017 2.148    0.056      0.025
#> 
#> Rapid responses (residual): 2.3% overall; mean response time effort = 0.977
tidy(fit)
#> # A tibble: 32 × 5
#>    component item   term                  estimate std.error
#>    <chr>     <chr>  <chr>                    <dbl>     <dbl>
#>  1 item      Item01 beta (time intensity)     4.55    0.0208
#>  2 item      Item02 beta (time intensity)     3.94    0.0235
#>  3 item      Item03 beta (time intensity)     4.17    0.0183
#>  4 item      Item04 beta (time intensity)     3.97    0.0157
#>  5 item      Item05 beta (time intensity)     3.45    0.0171
#>  6 item      Item06 beta (time intensity)     3.85    0.0163
#>  7 item      Item07 beta (time intensity)     3.87    0.0194
#>  8 item      Item08 beta (time intensity)     3.97    0.0186
#>  9 item      Item09 beta (time intensity)     4.42    0.0165
#> 10 item      Item10 beta (time intensity)     4.31    0.0173
#> # ℹ 22 more rows
# }
```
