# Interactive IRT teaching labs

mirtverse ships interactive [learnr](https://rstudio.github.io/learnr/)
tutorials for measurement courses. Students work through a realistic
testing scenario with live R exercises and make the decisions an analyst
would make, getting feedback on each one. Labs 1 and 2 share one
storyline, a certification board's 32-item exam
([certexam](https://www.okanbulut.com/mirtverse/reference/certexam.md)).
Labs 3 to 9 each have their own: a provincial numeracy test
([numeracy](https://www.okanbulut.com/mirtverse/reference/numeracy.md)),
a licensure exam with two forms
([linking](https://www.okanbulut.com/mirtverse/reference/linking.md)), a
placement test's item bank
([catbank](https://www.okanbulut.com/mirtverse/reference/catbank.md)),
rater-scored science tasks
([openended](https://www.okanbulut.com/mirtverse/reference/openended.md)),
written science explanations
([essays](https://www.okanbulut.com/mirtverse/reference/essays.md)), the
text of numeracy items
([itemtext](https://www.okanbulut.com/mirtverse/reference/itemtext.md))
and a field test of generated items
([aigfield](https://www.okanbulut.com/mirtverse/reference/aigfield.md)).

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

- `"model-choice"` (Lab 1): Score the responses, screen the items, check
  dimensionality, compare the Rasch, 2PL and 3PL models, check item fit
  and local dependence, and commit to a model the board can defend.

- `"decisions"` (Lab 2): Read the item parameters, check precision at
  the pass mark, choose a scoring method, estimate classification
  accuracy, test for DIF between English and French candidates, write a
  memo, and compare the results with the truth behind the data.

- `"fairness"` (Lab 3): Is a numeracy test biased against English
  language learners? Separate impact from DIF, run Mantel-Haenszel and
  IRT likelihood-ratio DIF tests, purify the anchor, judge how much the
  DIF matters for students' scores and plan a content review.

- `"linking"` (Lab 4): A licensure exam's pass rate jumped on a new
  form. Calibrate both forms, link them through common items, catch a
  drifted anchor, compare separate and concurrent calibration, and carry
  the pass mark over with IRT true-score equating.

- `"cat-design"` (Lab 5): Could a computerized adaptive test replace a
  40-item placement test? Inspect the item bank, run a CAT by hand,
  simulate students, and choose a stopping rule, exposure control and
  content balancing.

- `"open-ended"` (Lab 6): Are the rubric scores on a science assessment
  trustworthy? Check rater agreement, find a severe and an inconsistent
  rater, resolve final scores, fit polytomous IRT models, collapse
  categories that do not work, and decide whether an automated scoring
  engine can replace a human reader.

- `"auto-scoring"` (Lab 7): Can an automated scoring engine score
  written science explanations on its own? Train an engine with
  [`train_scorer()`](https://www.okanbulut.com/mirtverse/reference/train_scorer.md),
  judge it on new students with
  [`agreement_report()`](https://www.okanbulut.com/mirtverse/reference/agreement_report.md),
  check it for English language learners, find what drives the
  difference, and choose the engine's role.

- `"item-text"` (Lab 8): Can item difficulty be predicted from the text
  before field testing? Describe items with
  [`item_features()`](https://www.okanbulut.com/mirtverse/reference/item_features.md),
  find near-duplicates and miskeyed items, compare an LLTM with a lasso
  and a random forest in
  [`predict_difficulty()`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md),
  catch a leaky feature, hold out whole item models, and decide what
  predictions can replace.

- `"aig"` (Lab 9): Can a family mean replace the field test of a
  generated item? Write an item model with
  [`item_model()`](https://www.okanbulut.com/mirtverse/reference/item_model.md)
  and fix its constraints, calibrate a field test of 60 isomorphs, find
  the families that are not isomorphic with
  [`calibrate_families()`](https://www.okanbulut.com/mirtverse/reference/calibrate_families.md)
  and why, and test the family means on held-out items.

`run_lab()` opens a lab in the browser (or the RStudio Viewer). The labs
also appear in RStudio's Tutorial pane once mirtverse and learnr are
installed. Progress is saved in the browser, so students can stop and
come back later.

## Examples

``` r
list_labs()
#> # A tibble: 9 × 3
#>   name         title                                             description    
#>   <chr>        <chr>                                             <chr>          
#> 1 aig          Lab 9: Building an item factory                   A numeracy pro…
#> 2 auto-scoring Lab 7: Can the engine score alone?                A science prog…
#> 3 cat-design   Lab 5: Designing an adaptive test                 A college want…
#> 4 decisions    Lab 2: From parameters to decisions               The certificat…
#> 5 fairness     Lab 3: Is the test fair? Detecting DIF            An advocacy gr…
#> 6 item-text    Lab 8: Predicting difficulty before field testing A numeracy pro…
#> 7 linking      Lab 4: Linking two forms                          A licensure ex…
#> 8 model-choice Lab 1: Choosing a model the board can defend      You are the ne…
#> 9 open-ended   Lab 6: Scoring open-ended responses               A science asse…
if (interactive()) run_lab("model-choice")
```
