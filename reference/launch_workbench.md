# Launch the mirtverse workbench

Opens a point-and-click application for a complete IRT analysis: load
and score data, explore items, let mirtverse pick a model or choose one
yourself, read the plain-language interpretation, inspect item health
cards and graphics, score examinees, analyse response times, and
download an HTML report. The Pipeline tab runs the data through the
assessment pipeline's intake and calibration checks (or loads a pipeline
saved from R), shows the stage tracker, and lets you record decisions
about flags. Every step is written into an R script you can download, so
the analysis is reproducible and a good way to learn the R code.

## Usage

``` r
launch_workbench(data = NULL, ...)

workbench_app(data = NULL)
```

## Arguments

- data:

  optional data frame of item responses to start with.

- ...:

  passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html) (e.g.
  `launch.browser`, `port`).

## Value

Runs the app; returns nothing useful.

## Examples

``` r
if (interactive()) {
  launch_workbench()
  launch_workbench(expand.table(LSAT7))
}
```
