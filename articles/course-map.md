# A course map for instructors

This page is a suggested 12-week syllabus for an introductory course in
item response theory (IRT), for graduate students in education,
psychology or the health sciences. Each week lists what students should
be able to do by the end of it, what to read on this site, what to run
in R, and which lab and dataset to use. Take it as a starting point:
drop weeks, merge them, or swap in your own readings.

Everything here runs on a laptop with mirt and mirtverse installed. No
internet connection is needed once the packages are installed, and none
of the examples take more than a few seconds to run.

## Before the first class

Ask students to install the packages and check that a lab opens:

``` r

install.packages(c("mirt", "learnr"))
# install mirtverse as shown on the home page, then:
library(mirtverse)
list_labs()
```

Students who are new to R can do much of the course without writing
code. The
[workbench](https://www.okanbulut.com/mirtverse/articles/workbench.md)
([`launch_workbench()`](https://www.okanbulut.com/mirtverse/reference/launch_workbench.md))
runs a full analysis by pointing and clicking and shows the R code for
every step, and
[`mv_ask()`](https://www.okanbulut.com/mirtverse/articles/mv-ask-guide.md)
writes a script from a plain-language request. Both make good bridges to
writing code by hand later in the term.

## The 12 weeks at a glance

| Week | Topic | Lab | Main data |
|----|----|----|----|
| 1 | Measurement, scoring and classical item analysis | Lab 1, first two sections | `certexam` |
| 2 | From classical test theory to IRT: the Rasch, 2PL and 3PL models |  | `LSAT7` |
| 3 | Estimation and comparing models |  | `LSAT7`, `SAT12` |
| 4 | Dimensionality and local independence | [Lab 1](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md) in class | `certexam` |
| 5 | Item fit, person fit and item quality |  | `SAT12` |
| 6 | Information, precision and reliability |  | `certexam` |
| 7 | Scoring people | [Lab 2](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md) in class | `certexam` |
| 8 | Polytomous items and open-ended responses | Open-ended scoring lab (coming soon) | `Science` |
| 9 | Differential item functioning and fairness | DIF lab (coming soon) | `certexam` |
| 10 | Linking and equating | Linking lab (coming soon) | `certexam` |
| 11 | Item banks, test assembly and adaptive testing | CAT lab (coming soon) | `certexam` bank |
| 12 | Cut scores, reporting and communicating results | Final project | students’ own data |

The [glossary](#planned-resources) (coming soon) defines each term used
below, and the [cheat sheet](#planned-resources) (coming soon) lists the
main functions by task; both work well as handouts from week 1.

## Week by week

### Week 1. Measurement, scoring and classical item analysis

**By the end of the week, students can** score multiple-choice responses
against a key, compute proportion correct and item-total correlations,
and read a distractor analysis.

- **Read:** [Getting
  started](https://www.okanbulut.com/mirtverse/articles/mirtverse.md);
  “The story” and “Start a lab” in [Teaching
  labs](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md).
- **Run:**
  [`key2binary()`](https://philchalmers.github.io/mirt/reference/key2binary.html),
  [`itemstats()`](https://philchalmers.github.io/mirt/reference/itemstats.html)
  (mirt),
  [`profile_data()`](https://www.okanbulut.com/mirtverse/reference/profile_data.md).
- **Lab:** the first two sections of Lab 1 (`run_lab("model-choice")`),
  “Score the responses” and “Screen the items”. Students meet a miskeyed
  item without being told it is there.
- **Data:** `certexam`, `certexam_key`.
- **Discuss:** what a number-correct score can and cannot tell us.

### Week 2. From classical test theory to IRT

**By the end of the week, students can** explain the Rasch, 2PL and 3PL
models, fit them with
[`mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html), and
read an item characteristic curve.

- **Read:** sections 1 to 4 of [Getting
  started](https://www.okanbulut.com/mirtverse/articles/mirtverse.md).
- **Run:**
  [`mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html),
  `coef(mod, IRTpars = TRUE)`,
  [`gg_trace()`](https://www.okanbulut.com/mirtverse/reference/gg_trace.md),
  [`item_table()`](https://www.okanbulut.com/mirtverse/reference/item_table.md),
  [`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md).
- **Data:** `LSAT7` (expand it with
  [`expand.table()`](https://philchalmers.github.io/mirt/reference/expand.table.html)).
- **Activity:** ask students to sketch trace lines for items they invent
  (an easy item, a hard item, a flat item) and then find the closest
  real item in the data.

### Week 3. Estimation and comparing models

**By the end of the week, students can** describe marginal maximum
likelihood in words, recognise a model that has not converged, and
compare nested models with likelihood-ratio tests and information
criteria.

- **Read:** “Let mirtverse pick a model” in [Getting
  started](https://www.okanbulut.com/mirtverse/articles/mirtverse.md).
- **Run:**
  [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md),
  [`anova()`](https://rdrr.io/r/stats/anova.html),
  [`M2()`](https://philchalmers.github.io/mirt/reference/M2.html),
  [`glance_mirt()`](https://www.okanbulut.com/mirtverse/reference/glance_mirt.md),
  [`tidy_mirt()`](https://www.okanbulut.com/mirtverse/reference/tidy_mirt.md).
- **Data:** `LSAT7` and `SAT12` (scored with
  [`key2binary()`](https://philchalmers.github.io/mirt/reference/key2binary.html)).
- **Discuss:** why AIC and BIC can disagree, and what sample size has to
  do with fitting a 3PL.

### Week 4. Dimensionality and local independence

**By the end of the week, students can** check whether one dimension is
enough, read standardized residuals and the Q3 statistic, and tell local
dependence from a second trait.

- **Run:** a one- vs two-factor model with
  [`anova()`](https://rdrr.io/r/stats/anova.html),
  [`summary()`](https://rdrr.io/r/base/summary.html) for rotated
  loadings, `residuals(mod, type = "Q3")` and
  [`gg_q3()`](https://www.okanbulut.com/mirtverse/reference/gg_q3.md).
- **Lab:** all of Lab 1 (`run_lab("model-choice")`, about 75 minutes).
  It ends with a model choice the student has to justify in writing.
- **Data:** `certexam` (the passage pair Q21 and Q22).
- **Assignment:** hand in the decision table and justification from the
  end of Lab 1.

### Week 5. Item fit, person fit and item quality

**By the end of the week, students can** read S-X² item fit, compare an
empirical and a model-implied curve, and flag aberrant response
patterns.

- **Run:**
  [`itemfit()`](https://philchalmers.github.io/mirt/reference/itemfit.html)
  and
  [`gg_itemfit()`](https://www.okanbulut.com/mirtverse/reference/gg_itemfit.md),
  [`gg_empirical()`](https://www.okanbulut.com/mirtverse/reference/gg_empirical.md),
  [`personfit()`](https://philchalmers.github.io/mirt/reference/personfit.html)
  (mirt),
  [`item_card()`](https://www.okanbulut.com/mirtverse/reference/item_card.md)
  and
  [`item_cards()`](https://www.okanbulut.com/mirtverse/reference/item_cards.md).
- **Data:** `SAT12`.
- **Activity:** students pick the three weakest items from the item
  cards and write one sentence each on what an item writer should
  change.

### Week 6. Information, precision and reliability

**By the end of the week, students can** read item and test information
curves, convert information to a standard error, and explain why
reliability depends on where on the scale you look.

- **Run:**
  [`gg_info()`](https://www.okanbulut.com/mirtverse/reference/gg_info.md),
  [`testinfo()`](https://philchalmers.github.io/mirt/reference/testinfo.html),
  [`marginal_rxx()`](https://philchalmers.github.io/mirt/reference/marginal_rxx.html)
  and
  [`empirical_rxx()`](https://philchalmers.github.io/mirt/reference/empirical_rxx.html)
  (mirt).
- **Lab:** the “Precision at the pass mark” section of Lab 2 previews
  next week.
- **Data:** `certexam`.

### Week 7. Scoring people

**By the end of the week, students can** compare EAP, MAP, ML and WLE
scores, explain why ML fails for perfect scores, and read a Wright map.

- **Run:**
  [`fscores()`](https://philchalmers.github.io/mirt/reference/fscores.html)
  (mirt),
  [`gg_scores()`](https://www.okanbulut.com/mirtverse/reference/gg_scores.md),
  [`gg_wright()`](https://www.okanbulut.com/mirtverse/reference/gg_wright.md),
  [`augment_mirt()`](https://www.okanbulut.com/mirtverse/reference/augment_mirt.md).
- **Lab:** all of Lab 2 (`run_lab("decisions")`, about 75 minutes).
  Students choose a scoring method, estimate classification accuracy,
  look for DIF and write a memo to the board. Lab 2 fits its own model,
  so students who missed Lab 1 can still do it.
- **Data:** `certexam`.
- **Assignment:** the memo from the end of Lab 2.

### Week 8. Polytomous items and open-ended responses

**By the end of the week, students can** fit the partial credit,
generalized partial credit and graded response models, read category
curves, and say when categories should be collapsed.

- **Read:** [Assessment
  pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md),
  section “9. Scoring”, for scoring open-ended responses with
  [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md).
- **Run:**
  [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md)
  on polytomous data,
  [`gg_trace()`](https://www.okanbulut.com/mirtverse/reference/gg_trace.md),
  [`gg_info()`](https://www.okanbulut.com/mirtverse/reference/gg_info.md).
- **Lab:** open-ended scoring lab (coming soon).
- **Data:** `Science` (four Likert-type items).
- **Students coming from ltm, eRm or TAM:**
  [`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md)
  translates their old code ([Coming from other IRT
  packages](https://www.okanbulut.com/mirtverse/articles/mirtify.md)).

### Week 9. Differential item functioning and fairness

**By the end of the week, students can** tell impact from DIF, run a DIF
analysis with anchor items, and explain uniform and non-uniform DIF.

- **Run:**
  [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md),
  [`gg_dif()`](https://www.okanbulut.com/mirtverse/reference/gg_dif.md),
  [`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md)
  on the result;
  [`multipleGroup()`](https://philchalmers.github.io/mirt/reference/multipleGroup.html)
  and [`DIF()`](https://philchalmers.github.io/mirt/reference/DIF.html)
  (mirt) for the model behind it.
- **Lab:** the “Fairness across languages” section of Lab 2 for a short
  version; the DIF lab (coming soon) for a full session.
- **Data:** `certexam` (English and French candidates).
- **Discuss:** what a content review panel should do with a flagged
  item.

### Week 10. Linking and equating

**By the end of the week, students can** explain why two forms need a
common scale, describe anchor-item and common-person designs, and link a
new calibration to an existing one.

- **Read:** [Assessment
  pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md),
  sections “3. Field-test design” and “6. The item bank”.
- **Run:**
  [`design_field_test()`](https://www.okanbulut.com/mirtverse/reference/design_field_test.md),
  [`link_to_bank()`](https://www.okanbulut.com/mirtverse/reference/link_to_bank.md);
  [`multipleGroup()`](https://philchalmers.github.io/mirt/reference/multipleGroup.html)
  with anchors and
  [`fixedCalib()`](https://philchalmers.github.io/mirt/reference/fixedCalib.html)
  (mirt).
- **Lab:** linking lab (coming soon).
- **Data:** `certexam`, split into two field-test forms by
  [`design_field_test()`](https://www.okanbulut.com/mirtverse/reference/design_field_test.md).

### Week 11. Item banks, test assembly and adaptive testing

**By the end of the week, students can** describe an item bank, assemble
a form to a target information curve, and explain how a computerized
adaptive test picks items and when it stops.

- **Read:** [Assessment
  pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md),
  sections “6. The item bank” and “7. Forms, adaptive and multistage
  tests”.
- **Run:**
  [`mv_bank()`](https://www.okanbulut.com/mirtverse/reference/mv_bank.md),
  [`assemble_forms()`](https://www.okanbulut.com/mirtverse/reference/assemble_forms.md),
  [`simulate_cat()`](https://www.okanbulut.com/mirtverse/reference/simulate_cat.md),
  [`assemble_mst()`](https://www.okanbulut.com/mirtverse/reference/assemble_mst.md).
- **Lab:** CAT lab (coming soon).
- **Data:** the `certexam` bank built in the pipeline article.

### Week 12. Cut scores, reporting and communicating results

**By the end of the week, students can** describe a Bookmark standard
setting, estimate classification accuracy at a cut score, and explain
IRT results to someone who does not use R.

- **Read:** [Assessment
  pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md),
  sections “8. Cut scores” and “11. The report”; [Sharing results with a
  dashboard](https://www.okanbulut.com/mirtverse/articles/dashboards.md).
- **Run:**
  [`item_map()`](https://www.okanbulut.com/mirtverse/reference/item_map.md),
  [`set_cuts()`](https://www.okanbulut.com/mirtverse/reference/set_cuts.md),
  [`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md),
  [`mv_dashboard()`](https://www.okanbulut.com/mirtverse/reference/mv_dashboard.md).
- **Final project:** see below.

## Assessment ideas

| Weight | Task | When |
|----|----|----|
| 20% | Lab 1 decision table and model justification | Week 4 |
| 20% | Lab 2 memo to the board | Week 7 |
| 20% | Two short problem sets (one on fit and precision, one on DIF or linking) | Weeks 6 and 10 |
| 40% | Final project: a full analysis of a dataset of the student’s choice, handed in as an [`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md) or a dashboard plus a two-page memo | Week 12 |

For the final project, students can follow the [assessment
pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md)
from calibration to the report. Its flags point out what to check before
each next step, which works well as a checklist for the write-up.

## Adapting the course

- **A shorter course (8 weeks):** combine weeks 2 and 3, and weeks 5 and
  6; drop week 10 and treat week 11 as a lecture without a lab.
- **An undergraduate course:** spend two weeks on week 1, use the
  [workbench](https://www.okanbulut.com/mirtverse/articles/workbench.md)
  instead of code until week 4, and end at week 9.
- **A second course:** add multidimensional and bifactor models
  ([`mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html)
  with more factors,
  [`bfactor()`](https://philchalmers.github.io/mirt/reference/bfactor.html)),
  [response-time
  models](https://www.okanbulut.com/mirtverse/articles/response-times.md)
  ([`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md),
  [`sim_rt()`](https://www.okanbulut.com/mirtverse/reference/sim_rt.md)),
  and the remaining stages of the [assessment
  pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md),
  such as test security and bank monitoring.

## Planned resources

These resources are being built and will be linked from the weeks above
when they are released.

| Resource                                   | Used in   | Status      |
|--------------------------------------------|-----------|-------------|
| Glossary of IRT terms on this site         | All weeks | Coming soon |
| Two-page cheat sheet of the main functions | All weeks | Coming soon |
| DIF and fairness lab                       | Week 9    | Coming soon |
| Linking two forms lab                      | Week 10   | Coming soon |
| CAT design lab                             | Week 11   | Coming soon |
| Open-ended scoring lab                     | Week 8    | Coming soon |
