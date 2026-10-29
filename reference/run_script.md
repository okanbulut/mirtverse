# Run or save a script written by mv_ask()

`run_script()` runs the script in a fresh environment and returns the
objects it created (for example `mod`, `sel`, `dif_res`, `scores`). With
`check = TRUE` it first runs the whole script on simulated data with the
same structure as yours (same items, categories and groups) in a
temporary folder, so errors show up before your data are touched.
`save_script()` writes the script to a `.R` file.

## Usage

``` r
run_script(x, check = FALSE, echo = interactive())

save_script(x, file = "analysis.R", open = FALSE)
```

## Arguments

- x:

  an `mv_script` from
  [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md).

- check:

  logical; do a dry run on simulated data first.

- echo:

  logical; print each line and its output as it runs.

- file:

  path of the `.R` file to write.

- open:

  logical; open the file in the RStudio or Positron editor (needs the
  rstudioapi package).

## Value

`run_script()`: a named list of the objects the script created,
invisibly. `save_script()`: the file path, invisibly.

## Examples

``` r
scr <- mv_ask(data = Science, plan = mv_plan(model = "graded", steps = "fitcheck"))
f <- save_script(scr, tempfile(fileext = ".R"))
# \donttest{
res <- run_script(scr, echo = FALSE)
# }
```
