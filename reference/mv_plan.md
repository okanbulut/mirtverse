# An analysis plan for mv_ask()

A plan lists, in a structured form, what the generated script should do:
which columns are items, which model to fit, which group to test for DIF
and which outputs to produce.
[`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
fills a plan from a plain-language request, but a plan can also be
written by hand and passed to `mv_ask(plan = )`, or changed with
`update_plan()`.

## Usage

``` r
mv_plan(
  items = NULL,
  model = "auto",
  nfact = 1,
  group = NULL,
  missing = NULL,
  key = NULL,
  rt = NULL,
  steps = c("describe", "fitcheck", "interpret"),
  options = list(),
  assumptions = character()
)

update_plan(plan, ...)
```

## Arguments

- items:

  item columns: a character vector of names, a range such as `"Q1:Q20"`,
  or `NULL` for all columns that look like items.

- model:

  `"auto"` (compare models with
  [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md)),
  `"Rasch"`, `"2PL"`, `"3PL"`, `"graded"` or `"gpcm"`.

- nfact:

  number of latent dimensions (1 to 3).

- group:

  name of a grouping column (e.g. `"gender"`) for a DIF analysis.
  Setting it adds the `"dif"` step.

- missing:

  numeric codes that mean "missing", e.g. `c(9, 99)`.

- key:

  answer key for multiple-choice items that are not yet scored.

- rt:

  response-time columns, one per item and in the same order. Setting it
  adds the `"rt"` step.

- steps:

  the analysis steps, any of `"describe"`, `"fitcheck"`, `"dif"`,
  `"scores"`, `"plots"`, `"interpret"`, `"cards"`, `"report"` and
  `"rt"`. A model is always fitted.

- options:

  per-step options as a named list of lists, e.g.
  `list(scores = list(method = "MAP", file = "scores.csv"), report = list(file = "report.html"), fit = list(criterion = "AIC"))`.

- assumptions:

  notes about how the request was understood; they are printed with the
  plan and written as comments in the script.

- plan:

  an `mv_plan` object.

- ...:

  fields to change, as in `mv_plan()`.

## Value

An object of class `mv_plan`.

## Examples

``` r
mv_plan(model = "2PL", group = "gender", steps = c("fitcheck", "report"))
#> Analysis plan
#>   - Items: all columns that look like items 
#>   - Model: 2PL, 1 dimension 
#>   - DIF by: gender 
#>   - Steps: fit, fitcheck, dif, report 
```
