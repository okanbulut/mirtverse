# Sharing results with a dashboard

The
[workbench](https://www.okanbulut.com/mirtverse/articles/workbench.md)
is for doing an analysis, and
[`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md)
writes a static record of it.
[`mv_dashboard()`](https://www.okanbulut.com/mirtverse/reference/mv_dashboard.md)
fills the gap in between: a small, read-only app you can hand to people
who do not use R, such as teachers, clients, committees or students, so
they can explore the results themselves.

## Build a dashboard

Fit a model as usual, then pass it to
[`mv_dashboard()`](https://www.okanbulut.com/mirtverse/reference/mv_dashboard.md):

``` r

library(mirtverse)

data <- key2binary(SAT12, key = c(1,4,5,2,3,1,2,1,3,1,2,4,2,1,5,3,4,4,1,4,3,3,
                                  4,1,3,5,1,3,1,5,4,5))
mod <- mirt(data, 1, verbose = FALSE)

mv_dashboard(mod, title = "SAT12 results",
             subtitle = "Science test, 32 items, scored 0/1")
```

The dashboard opens in your browser. Assign it
(`app <- mv_dashboard(...)`) if you want to keep it without opening it.

## Choose the panels

| Panel | What it shows |
|----|----|
| `"summary"` | Respondents, items, reliability and items to review, with the plain-language interpretation from [`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md) |
| `"items"` | The item table with a traffic-light status; select a row to see its item health card |
| `"curves"` | Trace curves for chosen items and a slider that reads off the probabilities at any ability level |
| `"information"` | Test information and standard error, and item information curves |
| `"wright"` | The Wright map |
| `"scores"` | The distribution of ability estimates and the sum-score conversion table |
| `"persons"` | A searchable table of every person’s score, SE and percentile (off by default) |
| `"dif"` | DIF results from [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md) |
| `"rt"` | Response-time results from [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md) |

``` r

res <- dif(data, group = gender)

mv_dashboard(mod, panels = c("summary", "items", "dif"), dif = res,
             title = "Fairness review", logo = "logo.png")
```

The curves, information, Wright map, scores and persons panels need a
unidimensional model. For other models they are left out with a message.

## Share it

A ‘shiny’ app needs a server to run on.
[`export_dashboard()`](https://www.okanbulut.com/mirtverse/reference/export_dashboard.md)
writes a folder that is ready to deploy:

``` r

export_dashboard(mod, "sat12-dashboard", title = "SAT12 results")

shiny::runApp("sat12-dashboard")          # try it locally
rsconnect::deployApp("sat12-dashboard")   # publish to shinyapps.io or Posit Connect
```

The folder holds `app.R` and `dashboard.rds`. The server installs
mirtverse the same way you installed it, so install it from r-universe
or GitHub, not from a local copy, before you deploy.

## What the dashboard contains

Everything is computed once, when you build the dashboard; the app never
refits or rescores anything, so it starts quickly. The saved dashboard
holds only summaries: item statistics, parameters, curves, the binned
score distribution and pictures of the item cards. It never holds the
item responses.

Individual scores are included only when you add the `"persons"` panel,
and
[`export_dashboard()`](https://www.okanbulut.com/mirtverse/reference/export_dashboard.md)
reminds you to check that you may share them. Use `ids` to show your own
identifiers instead of row numbers:

``` r

mv_dashboard(mod, panels = c("summary", "persons"), ids = students$id)
```
