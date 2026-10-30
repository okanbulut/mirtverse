# Write an analysis script from a plain-language request

Describe the analysis in your own words, for example "fit a 2PL, check
DIF by gender and make a report", and `mv_ask()` writes a complete,
commented R script for it. The request is turned into an analysis plan
(see
[`mv_plan()`](https://www.okanbulut.com/mirtverse/reference/mv_plan.md)),
checked against your data, and the script is built from tested
templates, so it only uses mirt and mirtverse functions with checked
arguments. Nothing is run until you call
[`run_script()`](https://www.okanbulut.com/mirtverse/reference/run_script.md).

## Usage

``` r
mv_ask(
  request = NULL,
  data = NULL,
  plan = NULL,
  provider = NULL,
  model = NULL,
  anonymize = FALSE,
  dry_run = FALSE,
  ask = interactive(),
  ...
)
```

## Arguments

- request:

  a plain-language description of the analysis. To change an earlier
  script, pass it first: `mv_ask(scr, "use a 3PL instead")`.

- data:

  the data: a data frame, or the path of a `.csv`, `.xlsx`, `.sav`,
  `.dta`, `.sas7bdat` or `.rds` file. The script refers to a data frame
  by the name you pass, so pass a named object (e.g. `data = mydata`).

- plan:

  an
  [`mv_plan()`](https://www.okanbulut.com/mirtverse/reference/mv_plan.md)
  to use instead of a request.

- provider:

  `"claude"`, `"openai"`, `"ollama"` or `"none"` (keyword parser).
  Defaults to the provider chosen with
  [`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md),
  then to whichever API key is available, then to `"none"`.

- model:

  the AI model name; see
  [`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md).

- anonymize:

  logical; replace column names with V1, V2, ... (and drop category
  labels) before anything is sent to the AI model. The names are
  restored locally.

- dry_run:

  logical; print exactly what would be sent to the AI model and return
  it, without sending anything or writing a script.

- ask:

  logical; ask follow-up questions in the console when the keyword
  parser needs more information. If `FALSE` the questions are reported
  as an error instead.

- ...:

  unused; there to catch a mistyped argument such as `plan`.

## Value

An object of class `mv_script` with elements `script` (the code as a
character vector), `plan`, `profile` (see
[`profile_data()`](https://www.okanbulut.com/mirtverse/reference/profile_data.md)),
`request`, `data_name` and `parser` (what understood the request).
Printing it shows the plan, any assumptions and the code. With
`dry_run = TRUE`, the text that would be sent, invisibly.

## Details

Requests are understood by an AI model set up with
[`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md)
(Claude, OpenAI GPT or a local Ollama model), or, when none is set up,
by a built-in keyword parser that works offline and asks follow-up
questions in the console when something is unclear. The AI model only
sees your request and a summary of the columns
([`profile_data()`](https://www.okanbulut.com/mirtverse/reference/profile_data.md));
never individual responses. Use `dry_run = TRUE` to see exactly what
would be sent.

## See also

[`run_script()`](https://www.okanbulut.com/mirtverse/reference/run_script.md),
[`save_script()`](https://www.okanbulut.com/mirtverse/reference/run_script.md),
[`mv_plan()`](https://www.okanbulut.com/mirtverse/reference/mv_plan.md),
[`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md).

## Examples

``` r
scr <- mv_ask("fit a graded response model, plot the curves and summarise",
              data = Science, provider = "none")
scr
#> Request: fit a graded response model, plot the curves and summarise 
#> Understood by the built-in keyword parser
#> 
#> Analysis plan
#>   - Data: Science 
#>   - Items: Comfort, Work, Future, Benefit 
#>   - Model: graded response, 1 dimension 
#>   - Steps: fit, plots, interpret 
#> Assumptions
#>   - Used the 4 columns that look like item responses as items. 
#> 
#> R script (run it with run_script(), save it with save_script())
#> ----------------------------------------------------------------
#> # Analysis script written by mirtverse::mv_ask()
#> # 2026-10-30 19:27
#> # Request: fit a graded response model, plot the curves and summarise
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
#> # Graphics
#> gg_trace(mod)
#> gg_info(mod)
#> gg_wright(mod)
#> 
#> # Plain-language summary
#> interpret(mod)
scr <- mv_ask(scr, "also make a report")
mv_ask("check DIF by gender", data = Science, dry_run = TRUE)
#> No AI model is set up, so nothing would be sent; an AI model would receive:
#> 
#> Request: check DIF by gender
#> 
#> Data: 392 rows, 4 columns.
#> Columns (name | type | distinct values | min | max | share missing | guessed role | categories):
#> - Comfort | integer | 4 | 1 | 4 | 0.00 | item | 
#> - Work | integer | 4 | 1 | 4 | 0.00 | item | 
#> - Future | integer | 4 | 1 | 4 | 0.00 | item | 
#> - Benefit | integer | 4 | 1 | 4 | 0.00 | item |  
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
