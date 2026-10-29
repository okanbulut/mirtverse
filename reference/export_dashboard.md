# Save a results dashboard to share

Saves a dashboard in one of two forms:

## Usage

``` r
export_dashboard(
  x,
  path = NULL,
  ...,
  format = c("shiny", "html"),
  overwrite = FALSE,
  open = interactive()
)
```

## Arguments

- x:

  a model, `mv_model_selection` object, or the app returned by
  [`mv_dashboard()`](https://www.okanbulut.com/mirtverse/reference/mv_dashboard.md).

- path:

  for `format = "shiny"`, the folder to write (created if needed); for
  `format = "html"`, the file to write (`.html` is added if missing).
  Defaults to `"mirtverse-dashboard"` or `"mirtverse-dashboard.html"`.

- ...:

  arguments passed to
  [`mv_dashboard()`](https://www.okanbulut.com/mirtverse/reference/mv_dashboard.md)
  when `x` is a model, such as `panels`, `title` or `dif`.

- format:

  `"shiny"` for a deployable app folder or `"html"` for a single file
  that works offline.

- overwrite:

  logical; replace an existing dashboard at `path`.

- open:

  logical; for `format = "html"`, open the file in a browser afterwards.

## Value

The folder or file path, invisibly.

## Details

- `format = "shiny"` writes a folder with an `app.R` file and the
  dashboard summary (`dashboard.rds`). Run it locally with
  `shiny::runApp(path)`, or publish the folder to
  [shinyapps.io](https://www.shinyapps.io) or Posit Connect with
  `rsconnect::deployApp(path)`. The server installs mirtverse the way
  you installed it, so install it from GitHub or r-universe (not from a
  local folder) before you deploy.

- `format = "html"` writes a single self-contained `.html` file that
  needs no server, no R and no internet connection: email it, put it on
  a shared drive or a course page, and it opens in any browser. It has
  the same panels, with the item table, item curves, ability slider and
  person lookup still interactive.

Neither form holds item responses. Individual scores are included only
if the dashboard has the `"persons"` panel.

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

f <- export_dashboard(mod, file.path(tempdir(), "science.html"), format = "html",
                      title = "Science attitudes survey")
#> Drawing 4 item health cards...
# }
```
