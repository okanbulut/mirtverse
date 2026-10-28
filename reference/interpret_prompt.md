# Build a prompt for an AI assistant from a fitted model

Packs the key results of a model (parameters, fit, reliability and the
rule-based interpretation) into a text prompt you can paste into any
large language model to get a longer narrative or a draft
technical-report section. Nothing is sent anywhere by this function.

## Usage

``` r
interpret_prompt(x, audience = "a psychometric technical report")
```

## Arguments

- x:

  a model from
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- audience:

  who the text is for, e.g. `"teachers"` or
  `"a psychometric technical report"`.

## Value

A single character string.

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
cat(interpret_prompt(mod))
#> You are an expert psychometrician. Write a clear, accurate summary of the following item response theory results for a psychometric technical report. Quote numbers where they support a point and do not invent results.
#> 
#> ## Model summary
#>  nobs nitems nfact itemtype npar    logLik     AIC      BIC    SABIC converged
#>  1000      5     1      2PL   10 -2658.805 5337.61 5386.688 5354.927      TRUE
#>  method fit_stat       M2 df    p.value     RMSEA      SRMSR       CFI
#>      EM       M2 11.93769  5 0.03565165 0.0372683 0.03195919 0.9684666
#>        TLI reliability
#>  0.9369332   0.4417618
#> 
#> ## Item parameters
#>    item itemtype term   estimate std.error
#>  Item.1      2PL    a  0.9879254        NA
#>  Item.1      2PL    b -1.8787456        NA
#>  Item.2      2PL    a  1.0808847        NA
#>  Item.2      2PL    b -0.7475160        NA
#>  Item.3      2PL    a  1.7058006        NA
#>  Item.3      2PL    b -1.0576962        NA
#>  Item.4      2PL    a  0.7651853        NA
#>  Item.4      2PL    b -0.6351358        NA
#>  Item.5      2PL    a  0.7357980        NA
#>  Item.5      2PL    b -2.5204102        NA
#> 
#> ## Rule-based findings
#> ### Overview
#> 
#> - A 2PL model with 1 dimension was fitted to 1000 respondents and 5 items (EM estimation).
#> - The estimation converged normally.
#> 
#> ### Model fit
#> 
#> - Overall model fit is close: M2 = 11.94, df = 5, RMSEA = 0.037, CFI = 0.968, SRMSR = 0.032.
#> - The chi-square test is significant, but with large samples this is common; the RMSEA indicates the misfit is small in practical terms.
#> 
#> ### Reliability
#> 
#> - Marginal reliability is 0.44 (low).
#> - Scores are too imprecise for decisions about individuals; consider adding items or using the scores only for group-level summaries.
#> 
#> ### Targeting
#> 
#> - The average item location is -1.37 and the average person score is 0.00, so the test is relatively easy for this group.
#> - Measurement is most precise around theta = -1.08 (information = 1.47, SE = 0.83).
#> 
#> ### Items
#> 
#> - Low item-total correlation: Item.5 (r = 0.17). These items relate weakly to the rest of the test.
#> - Misfit: Item.2 (S-X2 p < .001). The model does not describe responses to these items well (alpha = 0.01); inspect them with gg_empirical() or item_card().
#> 
#> ### Local dependence
#> 
#> - No item pairs show signs of local dependence (Q3).
#> 
#> ### Person fit
#> 
#> - 2.1% of respondents have unusual response patterns (Zh < -1.96), which is within what chance alone would produce.
```
