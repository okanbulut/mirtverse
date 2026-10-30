# Interactive IRT teaching labs

mirtverse ships interactive [learnr](https://rstudio.github.io/learnr/)
tutorials for measurement courses. Students work through a realistic
testing scenario with live R exercises and make the decisions an analyst
would make, getting feedback on each one. The labs share one storyline:
a certification board's 32-item exam
([certexam](https://www.okanbulut.com/mirtverse/reference/certexam.md)).

## Usage

``` r
run_lab(name = "model-choice", ...)

list_labs()
```

## Arguments

- name:

  the lab to run; see `list_labs()`.

- ...:

  passed to
  [`learnr::run_tutorial()`](https://pkgs.rstudio.com/learnr/reference/run_tutorial.html),
  for example `shiny_args = list(launch.browser = FALSE)`.

## Value

`list_labs()` returns a data frame with one row per lab: `name`, `title`
and `description`. `run_lab()` runs the lab and returns nothing useful.

## Details

- `"model-choice"` (Lab 1): score the responses, screen the items, check
  dimensionality, compare the Rasch, 2PL and 3PL models, check item fit
  and local dependence, and commit to a model the board can defend.

- `"decisions"` (Lab 2): read the item parameters, check precision at
  the pass mark, choose a scoring method, estimate classification
  accuracy, test for DIF between English and French candidates, write a
  memo, and compare the results with the truth behind the data.

`run_lab()` opens a lab in the browser (or the RStudio Viewer). The labs
also appear in RStudio's Tutorial pane once mirtverse and learnr are
installed. Progress is saved in the browser, so students can stop and
come back later.

## Examples

``` r
list_labs()
#> # A tibble: 2 × 3
#>   name         title                                        description         
#>   <chr>        <chr>                                        <chr>               
#> 1 decisions    Lab 2: From parameters to decisions          The certification b…
#> 2 model-choice Lab 1: Choosing a model the board can defend You are the new psy…
if (interactive()) run_lab("model-choice")
```
