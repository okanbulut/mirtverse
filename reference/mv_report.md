# One-call HTML report

Writes a self-contained HTML report (no internet connection or extra
software needed to open it) covering the plain-language summary, model
fit, item statistics and parameters, graphics, a sum-score conversion
table, optional item health cards and the R code needed to reproduce the
analysis.

## Usage

``` r
mv_report(
  x,
  file = "mirtverse-report.html",
  title = "IRT analysis report",
  author = NULL,
  cards = NULL,
  alpha = 0.01,
  dif = NULL,
  code = NULL,
  extra = NULL,
  open = interactive() && !isTRUE(getOption("mirtverse.dry_run"))
)
```

## Arguments

- x:

  a unidimensional model from
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html),
  or an `mv_model_selection` object from
  [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md)
  (the report then adds the model comparison and describes the
  recommended model).

- file:

  path of the `.html` file to write.

- title:

  report title.

- author:

  optional author line.

- cards:

  logical; include an item health card for every item. Defaults to
  `TRUE` for tests of up to 40 items.

- alpha:

  significance level for item misfit.

- dif:

  optional `mv_dif` object from
  [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md); adds
  a section on differential item functioning.

- code:

  optional character vector of R code to show in the reproducibility
  section (the workbench fills this in automatically).

- extra:

  optional named list of extra sections, each a piece of HTML built with
  htmltools, placed before the reproducibility section; the names are
  the section titles.
  [`pipeline_report()`](https://www.okanbulut.com/mirtverse/reference/pipeline_report.md)
  uses this for its decisions section.

- open:

  logical; open the report in a browser afterwards.

## Value

The path to the report, invisibly.

## Examples

``` r
# \donttest{
mod <- mirt(Science, 1, verbose = FALSE)
f <- mv_report(mod, file = tempfile(fileext = ".html"))
# }
```
