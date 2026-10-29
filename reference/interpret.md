# Plain-language interpretation of IRT results

Turns a fitted model into short, readable statements about model fit,
reliability, test targeting, problem items, local dependence and person
fit. Each statement quotes the numbers it rests on, so the text can go
straight into a report. The rules used are documented in the Details.

## Usage

``` r
# S3 method for class 'mv_dif'
interpret(x, ...)

interpret(x, ...)

# S3 method for class 'SingleGroupClass'
interpret(x, alpha = 0.01, ...)

# S3 method for class 'mv_model_selection'
interpret(x, ...)

# S3 method for class 'mv_rt'
interpret(x, ...)
```

## Arguments

- x:

  a model from
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html),
  an `mv_model_selection` object from
  [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md),
  or an `mv_rt` object from
  [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md).

- ...:

  unused.

- alpha:

  significance level for item misfit.

## Value

An object of class `mv_interpretation`: a named list of character
vectors, one per section. It prints as formatted text; use
[`as.character()`](https://rdrr.io/r/base/character.html) or
`format(x, "markdown")` to reuse it.

## Details

Rules of thumb used:

- RMSEA (M2/C2): \<= .05 close, \<= .08 reasonable, \<= .10 mediocre,
  otherwise poor.

- Marginal reliability: \>= .90 excellent, \>= .80 good, \>= .70
  acceptable.

- Discrimination: \< 0.5 low, \> 4 suspiciously high; location beyond
  +/- 3 extreme; guessing \> .30 high; S-X2 p \< `alpha` misfit.

- Local dependence: Q3 more than 0.2 above the average Q3.

- Person fit: Zh \< -1.96 flags aberrant response patterns.

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
interpret(mod)
#> Overview
#> --------
#> * A 2PL model with 1 dimension was fitted to 1000 respondents and 5 items (EM
#>   estimation). 
#> * The estimation converged normally. 
#> 
#> Model fit
#> ---------
#> * Overall model fit is close: M2 = 11.94, df = 5, RMSEA = 0.037, CFI = 0.968,
#>   SRMSR = 0.032. 
#> * The chi-square test is significant, but with large samples this is common;
#>   the RMSEA indicates the misfit is small in practical terms. 
#> 
#> Reliability
#> -----------
#> * Marginal reliability is 0.44 (low). 
#> * Scores are too imprecise for decisions about individuals; consider adding
#>   items or using the scores only for group-level summaries. 
#> 
#> Targeting
#> ---------
#> * The average item location is -1.37 and the average person score is 0.00, so
#>   the test is relatively easy for this group. 
#> * Measurement is most precise around theta = -1.08 (information = 1.47, SE =
#>   0.83). 
#> 
#> Items
#> -----
#> * Low item-total correlation: Item.5 (r = 0.17). These items relate weakly to
#>   the rest of the test. 
#> * Misfit: Item.2 (S-X2 p < .001). The model does not describe responses to
#>   these items well (alpha = 0.01); inspect them with gg_empirical() or
#>   item_card(). 
#> 
#> Local dependence
#> ----------------
#> * No item pairs show signs of local dependence (Q3). 
#> 
#> Person fit
#> ----------
#> * 2.1% of respondents have unusual response patterns (Zh < -1.96), which is
#>   within what chance alone would produce. 
#> 
```
