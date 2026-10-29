# Results dashboard for sharing

Builds a small, read-only 'shiny' dashboard of a fitted model for people
who do not use R: teachers, clients, committees or students. Where the
[workbench](https://www.okanbulut.com/mirtverse/reference/launch_workbench.md)
is for doing an analysis, the dashboard is for showing one. Pick the
panels you want, give it a title, and run it, or save it as a
ready-to-deploy app or a single offline HTML file with
[`export_dashboard()`](https://www.okanbulut.com/mirtverse/reference/export_dashboard.md).

## Usage

``` r
mv_dashboard(
  x,
  panels = NULL,
  title = "Assessment results",
  subtitle = NULL,
  logo = NULL,
  dif = NULL,
  rt = NULL,
  ids = NULL,
  method = "EAP",
  cards = NULL,
  alpha = 0.01
)
```

## Arguments

- x:

  a model from
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html),
  an `mv_model_selection` object from
  [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md)
  (its recommended model is shown), or a dashboard object saved by
  [`export_dashboard()`](https://www.okanbulut.com/mirtverse/reference/export_dashboard.md).

- panels:

  character vector of panels to show, in order. The default shows
  `"summary"`, `"items"`, `"curves"`, `"information"`, `"wright"` and
  `"scores"`, plus `"dif"` and `"rt"` when those results are supplied.

- title, subtitle:

  text for the dashboard header.

- logo:

  optional path to a PNG, JPEG or SVG image shown in the header.

- dif:

  optional `mv_dif` object from
  [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md).

- rt:

  optional `mv_rt` object from
  [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md).

- ids:

  optional vector of person identifiers for the `"persons"` panel, one
  per row of the data the model was fitted to. Defaults to row numbers.

- method:

  scoring method for person scores, passed to
  [`mirt::fscores()`](https://philchalmers.github.io/mirt/reference/fscores.html).

- cards:

  logical; prepare an item health card for every item (shown when you
  select an item). Defaults to `TRUE` for unidimensional tests of up to
  40 items, because each card takes a moment to draw.

- alpha:

  significance level for item misfit flags.

## Value

A 'shiny' app object. Printing it (or calling the function at the
console) opens the dashboard;
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html) accepts
it too. The summary object is stored in its `"mv_dashboard"` attribute.

## Details

Everything the dashboard shows is computed once when it is built and
kept in a summary object; the app never refits or rescores anything.
That summary holds no item responses. Individual person scores are
included only when you ask for the `"persons"` panel, so check that you
may share them before you deploy a dashboard that has it.

Available panels:

- `"summary"`: headline numbers (respondents, items, reliability,
  flagged items) and the plain-language interpretation from
  [`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md).

- `"items"`: the item table with traffic-light status; select a row to
  see that item's health card
  ([`item_card()`](https://www.okanbulut.com/mirtverse/reference/item_card.md)).

- `"curves"`: trace curves for chosen items, with a slider that reads
  off the probabilities at any ability level.

- `"information"`: test information and standard error, plus item
  information curves.

- `"wright"`: the Wright map.

- `"scores"`: the distribution of ability estimates and the sum-score
  conversion table (no individual scores).

- `"persons"`: a searchable table of every person's score, standard
  error and percentile.

- `"dif"`: differential item functioning results (needs `dif`).

- `"rt"`: response-time results (needs `rt`).

`"curves"`, `"information"`, `"wright"`, `"scores"` and `"persons"` need
a unidimensional model and are dropped, with a message, for other
models.

## See also

[`export_dashboard()`](https://www.okanbulut.com/mirtverse/reference/export_dashboard.md)
to save a dashboard for deployment,
[`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md)
for a static HTML report.

## Examples

``` r
# \donttest{
mod <- mirt(Science, 1, verbose = FALSE)
app <- mv_dashboard(mod, title = "Science attitudes survey",
                    panels = c("summary", "items", "curves"))
#> Drawing 4 item health cards...
if (interactive()) app
# }
```
