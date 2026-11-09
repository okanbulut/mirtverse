# Write the Methods paragraph for an IRT analysis

Drafts the software, model, estimation, fit and reliability sentences of
a Methods section in APA style, with the references they cite. Give it a
fitted model, or the result of
[`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md)
to also describe how the model was chosen. The text is a starting point:
Read it, check that it describes what you did, and edit it.

## Usage

``` r
cite_methods(
  x,
  sample = NULL,
  items = NULL,
  fit = TRUE,
  item_fit = TRUE,
  alpha = 0.01,
  dropped = NULL,
  dropped_reason = NULL,
  file = NULL
)
```

## Arguments

- x:

  a unidimensional or multidimensional model from
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html),
  or an `mv_model_selection` object from
  [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md).

- sample:

  optional description of the respondents, such as
  `"undergraduate students"`. Used as "the responses of 1,200
  undergraduate students".

- items:

  optional description of the items, such as
  `"multiple-choice items from a statistics exam"`.

- fit:

  logical; report limited-information fit (M2, or C2 for polytomous
  items).

- item_fit:

  logical; report how many items show misfit on the S-X2 statistic.

- alpha:

  significance level for item misfit.

- dropped:

  optional character vector of items removed before the final
  calibration, with the reason in `dropped_reason`.

- dropped_reason:

  optional reason for dropping the items, such as
  `"a negative item-total correlation"`.

- file:

  optional output file. A `.docx` file is written with pandoc (through
  rmarkdown); any other extension gets Markdown text.

## Value

An object of class `mv_methods` with `text` (the paragraphs, as a
character vector) and `references` (APA references, alphabetical).
[`format()`](https://rdrr.io/r/base/format.html) and
[`as.character()`](https://rdrr.io/r/base/character.html) give the whole
text as one string, and printing shows it.

## Details

Numbers follow APA conventions: Statistics that cannot exceed 1 (p
values, RMSEA, SRMSR, CFI, reliability) have no leading zero, and p
values below .001 are reported as `p < .001`.

## See also

The [thesis
kit](https://www.okanbulut.com/mirtverse/articles/thesis-kit.html)
article.

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
cite_methods(mod, sample = "law school applicants",
             items = "items from the Law School Admission Test")
#> Analyses were conducted in R (version 4.6.2; R Core Team, 2026) with
#> the mirt package (version 1.48; Chalmers, 2012) for item response
#> theory (IRT) and the mirtverse package (version 0.4.0; Bulut, 2026) for
#> model comparison, fit summaries and reporting.
#> 
#> A unidimensional two-parameter logistic (2PL) model (Birnbaum, 1968)
#> was fitted to the responses of 1,000 law school applicants to 5
#> dichotomously scored items from the Law School Admission Test, using
#> marginal maximum likelihood with the expectation-maximization (EM)
#> algorithm (Bock & Aitkin, 1981).
#> 
#> Overall model fit was evaluated with the limited-information M2
#> statistic (Maydeu-Olivares & Joe, 2006): M2(5) = 11.94, p = .036, RMSEA
#> = .037, SRMSR = .032, CFI = .968. Item fit was examined with the S-X²
#> statistic (Orlando & Thissen, 2000); 1 of the 5 items (Item.2) showed
#> misfit at α = .01. Marginal reliability was .44.
#> 
#> References
#> 
#> Birnbaum, A. (1968). Some latent trait models and their use in
#>     inferring an examinee's ability. In F. M. Lord & M. R. Novick
#>     (Eds.), *Statistical theories of mental test scores* (pp. 397–479).
#>     Addison-Wesley.
#> Bock, R. D., & Aitkin, M. (1981). Marginal maximum likelihood
#>     estimation of item parameters: Application of an EM algorithm.
#>     *Psychometrika, 46*(4), 443–459. https://doi.org/10.1007/BF02293801
#> Bulut, O. (2026). *mirtverse: A friendly workflow and reporting layer
#>     for 'mirt'* (Version 0.4.0) [R package]. Zenodo.
#>     https://doi.org/10.5281/zenodo.23719384
#> Chalmers, R. P. (2012). mirt: A multidimensional item response theory
#>     package for the R environment. *Journal of Statistical Software,
#>     48*(6), 1–29. https://doi.org/10.18637/jss.v048.i06
#> Maydeu-Olivares, A., & Joe, H. (2006). Limited information
#>     goodness-of-fit testing in multidimensional contingency tables.
#>     *Psychometrika, 71*(4), 713–732.
#>     https://doi.org/10.1007/s11336-005-1295-9
#> Orlando, M., & Thissen, D. (2000). Likelihood-based item-fit indices
#>     for dichotomous item response theory models. *Applied Psychological
#>     Measurement, 24*(1), 50–64.
#>     https://doi.org/10.1177/01466216000241003
#> R Core Team. (2026). *R: A language and environment for statistical
#>     computing*. R Foundation for Statistical Computing.
#>     https://www.R-project.org/
#> 
#> Check the text against your analysis before you use it.
# \donttest{
sel <- select_model(expand.table(LSAT7), verbose = FALSE)
cite_methods(sel)
#> Analyses were conducted in R (version 4.6.2; R Core Team, 2026) with
#> the mirt package (version 1.48; Chalmers, 2012) for item response
#> theory (IRT) and the mirtverse package (version 0.4.0; Bulut, 2026) for
#> model comparison, fit summaries and reporting.
#> 
#> A unidimensional Rasch model (Rasch, 1960) was fitted to the responses
#> of 1,000 respondents to 5 dichotomously scored items, using marginal
#> maximum likelihood with the expectation-maximization (EM) algorithm
#> (Bock & Aitkin, 1981).
#> 
#> To choose the model, the Rasch, 2PL, and 3PL models were compared on
#> the Bayesian information criterion (Schwarz, 1978); the Rasch model had
#> the lowest value (BIC = 5371.2, compared with 5386.7 for the 2PL and
#> 5419.7 for the 3PL). Likelihood-ratio tests between nested models gave
#> χ²(4) = 12.19, p = .016 for the 2PL against the Rasch and χ²(9) =
#> 13.69, p = .134 for the 3PL against the Rasch.
#> 
#> Overall model fit was evaluated with the limited-information M2
#> statistic (Maydeu-Olivares & Joe, 2006): M2(9) = 23.17, p = .006, RMSEA
#> = .040, SRMSR = .047, CFI = .936. Item fit was examined with the S-X²
#> statistic (Orlando & Thissen, 2000); 1 of the 5 items (Item.2) showed
#> misfit at α = .01. Marginal reliability was .42.
#> 
#> References
#> 
#> Bock, R. D., & Aitkin, M. (1981). Marginal maximum likelihood
#>     estimation of item parameters: Application of an EM algorithm.
#>     *Psychometrika, 46*(4), 443–459. https://doi.org/10.1007/BF02293801
#> Bulut, O. (2026). *mirtverse: A friendly workflow and reporting layer
#>     for 'mirt'* (Version 0.4.0) [R package]. Zenodo.
#>     https://doi.org/10.5281/zenodo.23719384
#> Chalmers, R. P. (2012). mirt: A multidimensional item response theory
#>     package for the R environment. *Journal of Statistical Software,
#>     48*(6), 1–29. https://doi.org/10.18637/jss.v048.i06
#> Maydeu-Olivares, A., & Joe, H. (2006). Limited information
#>     goodness-of-fit testing in multidimensional contingency tables.
#>     *Psychometrika, 71*(4), 713–732.
#>     https://doi.org/10.1007/s11336-005-1295-9
#> Orlando, M., & Thissen, D. (2000). Likelihood-based item-fit indices
#>     for dichotomous item response theory models. *Applied Psychological
#>     Measurement, 24*(1), 50–64.
#>     https://doi.org/10.1177/01466216000241003
#> R Core Team. (2026). *R: A language and environment for statistical
#>     computing*. R Foundation for Statistical Computing.
#>     https://www.R-project.org/
#> Rasch, G. (1960). *Probabilistic models for some intelligence and
#>     attainment tests*. Danish Institute for Educational Research.
#> Schwarz, G. (1978). Estimating the dimension of a model. *The Annals of
#>     Statistics, 6*(2), 461–464. https://doi.org/10.1214/aos/1176344136
#> 
#> Check the text against your analysis before you use it.
# }
```
