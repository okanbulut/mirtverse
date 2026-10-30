# The ltm, eRm, TAM and irtQ to mirt crosswalk

Lists the functions that
[`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md)
translates, with the mirt (or mirtverse) code each one becomes and the
main difference to keep in mind.

## Usage

``` r
mirtify_crosswalk(package = NULL)
```

## Arguments

- package:

  optional; one or more of `"ltm"`, `"eRm"`, `"TAM"` and `"irtQ"` to
  keep only those packages.

## Value

A tibble with columns `package`, `function`, `mirt` and `notes`.

## Examples

``` r
mirtify_crosswalk("TAM")
#> # A tibble: 10 × 4
#>    package `function`           mirt                                       notes
#>    <chr>   <chr>                <chr>                                      <chr>
#>  1 TAM     tam.mml()            "mirt(data, 1, itemtype = \"Rasch\")"      "RSM…
#>  2 TAM     tam.mml.2pl()        "mirt(data, 1, itemtype = \"2PL\" or \"gp… "Slo…
#>  3 TAM     tam.mml.3pl()        "mirt(data, 1, itemtype = \"3PL\")"        "Onl…
#>  4 TAM     tam.wle()            "fscores(fit, method = \"WLE\")"           ""   
#>  5 TAM     IRT.factor.scores()  "fscores(fit, method = ...)"               ""   
#>  6 TAM     tam.fit()            "itemfit(fit, fit_stats = \"infit\")"      "Per…
#>  7 TAM     tam.modelfit()       "M2(fit), residuals(fit, type = \"Q3\")"   ""   
#>  8 TAM     tam.personfit()      "personfit(fit)"                           ""   
#>  9 TAM     IRT.compareModels()  "anova(fit1, fit2)"                        ""   
#> 10 TAM     fit$xsi, fit$EAP.rel "tidy(fit), empirical_rxx(fscores(...))"   ""   
```
