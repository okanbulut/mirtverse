# Start here: Testing programs

Operational work needs decisions you can defend and reports that
non-statisticians can read. mirtverse wraps mirt’s estimation in a
documented workflow: Each step checks the results and raises flags that
a person reviews before the next step.

## Your path in three steps

**Read the [case
study](https://www.okanbulut.com/mirtverse/articles/case-study.md)
first.** It follows a fictional certification board through eight
decisions and ends with a technical report you can download.

**1. Walk through the assessment pipeline.**
[`mv_pipeline()`](https://www.okanbulut.com/mirtverse/reference/mv_pipeline.md)
takes a test through 13 stages, from the blueprint to bank monitoring.
The [pipeline
article](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md)
runs a full example:

``` r

library(mirtverse)
# certexam is a built-in certification exam with a scoring key
p <- mv_pipeline("Certification exam, form A")
p <- add_responses(p, certexam, items = 3:34, key = certexam_key)
p <- calibrate(p)          # fits the model and flags miskeys, misfit and DIF
flags(p)                   # what needs a decision before you move on
```

**2. Check fairness and precision.** DIF in one call, item health cards
for review meetings, and information and conditional precision at the
cut score:

``` r

mod <- p$model             # an ordinary mirt model
item_card(mod, "Q14")      # one-page review of a flagged item
res <- dif(scored, group = gender)   # your scored 0/1 data and a grouping variable
gg_dif(res)
```

**3. Report to people who do not use R.** A technical report from the
pipeline, a static HTML report, or an [interactive
dashboard](https://www.okanbulut.com/mirtverse/articles/dashboards.md)
that runs in any browser:

``` r

pipeline_report(p, file = "technical-report.html")
export_dashboard(mod, "results.html", format = "html")
```

[Open the live example
dashboard](https://www.okanbulut.com/mirtverse/dashboard/sat12-demo.md)
to see what your stakeholders would get.

## Why you can trust the numbers

- mirtverse never changes how models are estimated; every result comes
  from mirt, and every function accepts an ordinary
  [`mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html)
  model.
- The package has an automated test suite and passes `R CMD check` on
  every change ([check
  status](https://github.com/okanbulut/mirtverse/actions/workflows/R-CMD-check.yaml)).
- Every flag rule is listed by
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)
  and can be changed, and every decision you acknowledge is recorded in
  the report.
- The workbench and
  [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
  show the R code they run, so analyses can be reviewed and rerun.

## Related

- [Response times and rapid
  guessing](https://www.okanbulut.com/mirtverse/articles/response-times.md)
  with
  [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md).
- [Linking and
  equating](https://www.okanbulut.com/mirtverse/book/linking.md) and
  [item banks and adaptive
  testing](https://www.okanbulut.com/mirtverse/book/banks-cat.md) in the
  book.
- [Auditing AI
  components](https://www.okanbulut.com/mirtverse/reference/ai_audit.md)
  if your program uses automated scoring.
