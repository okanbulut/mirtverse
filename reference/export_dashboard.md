# Save a results dashboard as a deployable app

Writes a folder with an `app.R` file and the dashboard summary
(`dashboard.rds`). Run it locally with `shiny::runApp(dir)`, or publish
the folder to [shinyapps.io](https://www.shinyapps.io) or Posit Connect
with `rsconnect::deployApp(dir)`. The server installs mirtverse the way
you installed it, so install it from GitHub or r-universe (not from a
local folder) before you deploy.

## Usage

``` r
export_dashboard(x, dir = "mirtverse-dashboard", ..., overwrite = FALSE)
```

## Arguments

- x:

  a model, `mv_model_selection` object, or the app returned by
  [`mv_dashboard()`](https://www.okanbulut.com/mirtverse/reference/mv_dashboard.md).

- dir:

  folder to write. Created if needed.

- ...:

  arguments passed to
  [`mv_dashboard()`](https://www.okanbulut.com/mirtverse/reference/mv_dashboard.md)
  when `x` is a model, such as `panels`, `title` or `dif`.

- overwrite:

  logical; replace an existing `app.R` or `dashboard.rds`.

## Value

The folder path, invisibly.

## Details

The folder holds no item responses. It holds individual scores only if
the dashboard has the `"persons"` panel.

## Examples

``` r
# \donttest{
mod <- mirt(Science, 1, verbose = FALSE)
dir <- export_dashboard(mod, file.path(tempdir(), "science-dashboard"),
                        title = "Science attitudes survey")
#> Drawing 4 item health cards...
list.files(dir)
#> [1] "app.R"         "dashboard.rds"
if (interactive()) shiny::runApp(dir)
# }
```
