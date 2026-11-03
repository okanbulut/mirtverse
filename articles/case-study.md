# Case study: A certification exam, from field test to pass/fail

[Download the technical report
(PDF)](https://www.okanbulut.com/mirtverse/case-study/certification-technical-report.pdf)
[Open it as a web
page](https://www.okanbulut.com/mirtverse/case-study/certification-technical-report.md)

## The situation

A professional certification board (fictional) field-tested a new
32-item exam with 1,200 candidates, who could sit it in English or
French. The board needs a pass/fail decision it can defend to
candidates, to its accreditor and, if it comes to that, in an appeal.
Its psychometrics team used the [assessment
pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md)
in mirtverse to run the analysis, record every decision and produce the
technical report.

The data are the `certexam` dataset that ships with mirtverse. It has
real problems planted in it, and the point of the case is to see whether
the checks find them.

## Eight decisions

Each stage of the pipeline ends with a gate: Checks that raise
**flags**. A *block* flag stops the work until someone decides; a
*review* flag asks for a recorded judgement. Here is everything the
gates found and what the team decided.

| Stage | What the gate found | Level | Decision recorded in the report |
|----|----|----|----|
| Field-test design | Slopes recovered with an RMSE of 0.22, a little above the 0.20 target | Review | Accepted: The sample size was fixed by the testing window |
| Data intake | **Q14 looks miskeyed:** Proportion correct 0.18, item-total correlation −0.23 | Block | The item writer confirmed the key was wrong; Q14 was dropped |
| Calibration | **Large DIF on Q09** (MH D-DIF = −2.01), favouring English candidates | Block | Translation reviewed and the French version revised |
| Calibration | Moderate DIF on Q27 (MH D-DIF = −1.01) | Review | Sent to the bias review panel |
| Calibration | Local dependence between Q21 and Q22 (Q3 = 0.27) | Review | They share a case; never put them on the same form |
| Calibration | Marginal reliability 0.83, below the 0.85 target | Review | Operational forms will be longer than the field test |
| Cut scores | Standard error of 0.42 at the cut, above 0.35 | Review | Add items near the cut to the operational forms |
| Scoring | Empirical reliability 0.83 | Review | Field-test scores are not reported to candidates |

Two block flags would have changed results if missed. A miskeyed item
lowers every candidate’s score on it and distorts the scale; an item
with large DIF makes the exam harder for French candidates of the same
ability.

## The outcome

- **The model:** A 2PL model on 31 items fits closely (RMSEA = 0.016,
  CFI = 0.987).
- **The decision:** A raw cut score of 18 classifies candidates with an
  estimated accuracy of 0.86 and consistency of 0.81 (kappa = 0.61).
- **Security:** No candidate shows signs of preknowledge of the five
  items suspected of having leaked.
- **The record:** Every flag, every decision and the R code that
  reproduces the analysis are in the [technical
  report](https://www.okanbulut.com/mirtverse/case-study/certification-technical-report.pdf)
  (34 pages), ready for an accreditor or an appeal panel.

## Reproduce it

The whole analysis is about 40 lines of R. Every function returns the
pipeline, so the record builds up as you go.

``` r

library(mirtverse)

p <- mv_pipeline("Certification exam: Form A field test")
p <- set_blueprint(p, c(Ethics = 4, Practice = 5, Law = 3),
                   construct = "Professional knowledge for certification",
                   use = "pass/fail certification", reliability = 0.85)
p <- design_field_test(p, n_forms = 2, n_per_form = 600, items = 32,
                       reps = 2, seed = 1)
p <- acknowledge(p, check = "recovery", note = "Sample fixed by the testing window")

p <- add_responses(p, certexam, items = 3:34, key = certexam_key,
                   id = "id", group = "language")
flags(p)                                  # Q14: possible miskey (block)
p <- drop_items(p, "Q14", note = "Key confirmed wrong by the item writer")

p <- calibrate(p, model = "2PL")
flags(p, stage = "calibration")           # DIF, local dependence, reliability
p <- override(p, check = "dif_large",
              note = "Translation reviewed; French version revised")
p <- acknowledge(p, check = "dif_moderate", note = "Sent to the bias panel")
p <- acknowledge(p, check = "local_dependence",
                 note = "Q21 and Q22 share a case; keep them apart on forms")
p <- acknowledge(p, check = "low_reliability",
                 note = "Operational forms will be longer than the field test")

p <- bank_items(p, name = "Certification bank")
p <- set_cuts(p, cuts = 18, scale = "raw", labels = c("Fail", "Pass"))
p$cuts$summary                            # accuracy, consistency, kappa
p <- score_persons(p)
p <- acknowledge(p, check = "cut_precision",
                 note = "Add items near the cut to the operational forms")
p <- acknowledge(p, check = "score_reliability",
                 note = "Field-test scores are not reported to candidates")
p <- check_security(p, leaked = c("Q01", "Q02", "Q03", "Q04", "Q05"))

pipeline_report(p, file = "technical-report.html")
```

The full [pipeline
walk-through](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md)
runs the same exam through every stage, including assembling parallel
forms and monitoring the item bank after the exam goes live.

## Using this in your program

- Every flag rule is listed by
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md),
  and you can change the thresholds to match your program’s standards.
- `mv_pipeline(strict = TRUE)` stops at any open review or block flag
  instead of warning, which suits operational use.
- The report is a single HTML file. Open it in a browser and print it to
  PDF for your records.

[Start here: Testing
programs](https://www.okanbulut.com/mirtverse/articles/for-practitioners.md)
has a shorter introduction for psychometricians at testing
organizations.
