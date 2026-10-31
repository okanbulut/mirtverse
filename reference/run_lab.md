# Interactive IRT teaching labs

mirtverse ships interactive [learnr](https://rstudio.github.io/learnr/)
tutorials for measurement courses. Students work through a realistic
testing scenario with live R exercises and make the decisions an analyst
would make, getting feedback on each one. Labs 1 and 2 share one
storyline, a certification board's 32-item exam
([certexam](https://www.okanbulut.com/mirtverse/reference/certexam.md)).
Labs 3 to 6 each have their own: a provincial numeracy test
([numeracy](https://www.okanbulut.com/mirtverse/reference/numeracy.md)),
a licensure exam with two forms
([linking](https://www.okanbulut.com/mirtverse/reference/linking.md)), a
placement test's item bank
([catbank](https://www.okanbulut.com/mirtverse/reference/catbank.md))
and rater-scored science tasks
([openended](https://www.okanbulut.com/mirtverse/reference/openended.md)).

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

- `"fairness"` (Lab 3): is a numeracy test biased against English
  language learners? Separate impact from DIF, run Mantel-Haenszel and
  IRT likelihood-ratio DIF tests, purify the anchor, judge how much the
  DIF matters for students' scores and plan a content review.

- `"linking"` (Lab 4): a licensure exam's pass rate jumped on a new
  form. Calibrate both forms, link them through common items, catch a
  drifted anchor, compare separate and concurrent calibration, and carry
  the pass mark over with IRT true-score equating.

- `"cat-design"` (Lab 5): could a computerized adaptive test replace a
  40-item placement test? Inspect the item bank, run a CAT by hand,
  simulate students, and choose a stopping rule, exposure control and
  content balancing.

- `"open-ended"` (Lab 6): are the rubric scores on a science assessment
  trustworthy? Check rater agreement, find a severe and an inconsistent
  rater, resolve final scores, fit polytomous IRT models, collapse
  categories that do not work, and decide whether an automated scoring
  engine can replace a human reader.

`run_lab()` opens a lab in the browser (or the RStudio Viewer). The labs
also appear in RStudio's Tutorial pane once mirtverse and learnr are
installed. Progress is saved in the browser, so students can stop and
come back later.

## Examples

``` r
list_labs()
#> # A tibble: 6 × 3
#>   name         title                                        description         
#>   <chr>        <chr>                                        <chr>               
#> 1 cat-design   Lab 5: Designing an adaptive test            A college wants to …
#> 2 decisions    Lab 2: From parameters to decisions          The certification b…
#> 3 fairness     Lab 3: Is the test fair? Detecting DIF       An advocacy group s…
#> 4 linking      Lab 4: Linking two forms                     A licensure exam ha…
#> 5 model-choice Lab 1: Choosing a model the board can defend You are the new psy…
#> 6 open-ended   Lab 6: Scoring open-ended responses          A science assessmen…
if (interactive()) run_lab("model-choice")
```
