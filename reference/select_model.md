# Model selection assistant

Fits a set of candidate IRT models to the same data, compares them on
information criteria, likelihood-ratio tests and limited-information
fit, and recommends one with a plain-language explanation.

## Usage

``` r
select_model(
  data,
  candidates = NULL,
  dims = 1,
  criterion = c("BIC", "AIC", "SABIC"),
  fit = TRUE,
  verbose = TRUE,
  ...
)
```

## Arguments

- data:

  a data frame or matrix of item responses.

- candidates:

  optional character vector of `itemtype` values passed to
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- dims:

  number(s) of latent dimensions to try.

- criterion:

  information criterion used to rank models.

- fit:

  logical; compute M2/C2 fit statistics for each model.

- verbose:

  logical; print progress.

- ...:

  further arguments passed to
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

## Value

An object of class `mv_model_selection` with elements `table`
(comparison table), `models` (fitted models), `best` (the recommended
model), `lrt` (likelihood-ratio tests between nested models) and
`explanation` (text).

## Details

By default the candidates depend on the data: for dichotomous items the
Rasch, 2PL and 3PL models; for polytomous (or mixed) items the partial
credit (Rasch), generalized partial credit and graded response models.
Set `dims = 1:2` to also try two-factor exploratory versions.

## Examples

``` r
# \donttest{
sel <- select_model(expand.table(LSAT7))
#> Fitting Rasch ...
#> Fitting 2PL ...
#> Fitting 3PL ...
sel
#> mirtverse model selection (ranked by BIC)
#> 
#>  model npar    logLik      AIC      BIC    SABIC RMSEA   CFI  delta weight
#>  Rasch    6 -2664.901 5341.802 5371.248 5352.192 0.040 0.936  0.000      1
#>    2PL   10 -2658.805 5337.610 5386.688 5354.927 0.037 0.968 15.439      0
#>    3PL   15 -2658.055 5346.110 5419.726 5372.085    NA    NA 48.478      0
#> 
#> The Rasch model is recommended because it has the lowest BIC (5371.2). The
#> runner-up, 2PL, is 15.4 BIC points worse, which is very strong evidence for the
#> Rasch model. Likelihood-ratio test Rasch vs. 2PL: chi-square(4) = 12.19, p =
#> .016; the 2PL model fits significantly better. Likelihood-ratio test Rasch vs.
#> 3PL: chi-square(9) = 13.69, p = .134; the extra parameters of 3PL are not
#> needed. Note the tension: the likelihood-ratio test prefers 2PL, while BIC
#> penalizes extra parameters and prefers Rasch. Choose Rasch if parsimony matters
#> most, or 2PL if fit to these data matters most. AIC would instead select the
#> 2PL model. Absolute fit of the Rasch model: RMSEA = 0.040 (close fit), CFI =
#> 0.936, SRMSR = 0.047.
sel$best
#> 
#> Call:
#> mirt::mirt(data = data, model = grid$nfact[i], itemtype = grid$itemtype[i], 
#>     verbose = FALSE)
#> 
#> Full-information item factor analysis with 1 factor(s).
#> Converged within 1e-04 tolerance after 27 EM iterations.
#> mirt version: 1.48 
#> M-step optimizer: nlminb 
#> EM acceleration: Ramsay 
#> Number of rectangular quadrature: 61
#> Latent density type: Gaussian 
#> 
#> Log-likelihood = -2664.901
#> Estimated parameters: 6 
#> AIC = 5341.802
#> BIC = 5371.248; SABIC = 5352.192
#> G2 (25) = 43.89, p = 0.0112
#> RMSEA = 0.028, CFI = NaN, TLI = NaN
# }
```
