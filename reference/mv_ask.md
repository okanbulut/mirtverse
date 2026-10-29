# Write an analysis script from a plan or a plain-language request

`mv_ask()` writes a complete, commented R script for an IRT analysis.
The script is built from tested templates, so it only uses mirt and
mirtverse functions with checked arguments. Nothing is run until you
call
[`run_script()`](https://www.okanbulut.com/mirtverse/reference/run_script.md).

## Usage

``` r
mv_ask(request = NULL, data = NULL, plan = NULL)
```

## Arguments

- request:

  a plain-language description of the analysis, or an existing
  `mv_script` to refine.

- data:

  the data: a data frame, or the path of a `.csv`, `.xlsx`, `.sav`,
  `.dta`, `.sas7bdat` or `.rds` file. The script refers to a data frame
  by the name you pass, so pass a named object (e.g. `data = mydata`).

- plan:

  an
  [`mv_plan()`](https://www.okanbulut.com/mirtverse/reference/mv_plan.md)
  to use instead of a request.

## Value

An object of class `mv_script` with elements `script` (the code as a
character vector), `plan`, `profile` (see
[`profile_data()`](https://www.okanbulut.com/mirtverse/reference/profile_data.md)),
`request` and `data_name`. Printing it shows the plan, any assumptions
and the code.

## See also

[`run_script()`](https://www.okanbulut.com/mirtverse/reference/run_script.md),
[`save_script()`](https://www.okanbulut.com/mirtverse/reference/run_script.md),
[`mv_plan()`](https://www.okanbulut.com/mirtverse/reference/mv_plan.md).

## Examples

``` r
scr <- mv_ask(data = Science,
              plan = mv_plan(model = "graded", steps = c("fitcheck", "plots")))
scr
#> Analysis plan
#>   - Data: Science 
#>   - Items: Comfort, Work, Future, Benefit 
#>   - Model: graded response, 1 dimension 
#>   - Steps: fit, fitcheck, plots 
#> Assumptions
#>   - Used the 4 columns that look like item responses as items. 
#> 
#> R script (run it with run_script(), save it with save_script())
#> ----------------------------------------------------------------
#> # Analysis script written by mirtverse::mv_ask()
#> # 2026-10-29 01:32
#> # Assumptions:
#> #  - Used the 4 columns that look like item responses as items.
#> library(mirtverse)
#> 
#> # Data
#> raw <- Science
#> items <- raw
#> 
#> # Fit the graded response model
#> mod <- mirt(items, 1, itemtype = "graded")
#> glance(mod)
#> 
#> # Check model and item fit
#> item_table(mod)
#> gg_itemfit(mod)
#> gg_q3(mod)
#> 
#> # Graphics
#> gg_trace(mod)
#> gg_info(mod)
#> gg_wright(mod)
# \donttest{
res <- run_script(scr, echo = FALSE)
res$mod
#> 
#> Call:
#> mirt(data = items, model = 1, itemtype = "graded")
#> 
#> Full-information item factor analysis with 1 factor(s).
#> Converged within 1e-04 tolerance after 36 EM iterations.
#> mirt version: 1.48 
#> M-step optimizer: BFGS 
#> EM acceleration: Ramsay 
#> Number of rectangular quadrature: 61
#> Latent density type: Gaussian 
#> 
#> Log-likelihood = -1608.87
#> Estimated parameters: 16 
#> AIC = 3249.739
#> BIC = 3313.279; SABIC = 3262.512
#> G2 (239) = 213.56, p = 0.8804
#> RMSEA = 0, CFI = NaN, TLI = NaN
# }
```
