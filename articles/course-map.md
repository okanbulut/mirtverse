# A course map for instructors

This page is a suggested 12-week syllabus for an introductory course in
item response theory (IRT), for graduate students in education,
psychology or the health sciences. Each week lists what students should
be able to do by the end of it, what to read on this site, what to run
in R, and which lab and dataset to use. Take it as a starting point:
Drop weeks, merge them, or swap in your own readings. The [instructor
toolkit](https://www.okanbulut.com/mirtverse/articles/instructor-toolkit.md)
helps with that: It builds labs on your own datasets and lets you edit
the built-in labs and add your own exercises.

The online book [*Item Response Theory with mirt and
mirtverse*](https://www.okanbulut.com/mirtverse/book/index.md) has one
chapter for each week below, with the ideas, two worked examples on
different data, exercises with solutions and a pointer to the matching
lab. Assign the chapter as the week’s reading.

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
| 2 | From classical test theory to IRT: The Rasch, 2PL and 3PL models |  | `LSAT7` |
| 3 | Estimation and comparing models |  | `LSAT7`, `SAT12` |
| 4 | Dimensionality and local independence | [Lab 1](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md) in class | `certexam` |
| 5 | Item fit, person fit and item quality |  | `SAT12` |
| 6 | Information, precision and reliability |  | `certexam` |
| 7 | Scoring people | [Lab 2](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md) in class | `certexam` |
| 8 | Polytomous items and open-ended responses | Lab 6, `run_lab("open-ended")` | `openended`, `Science` |
| 9 | Differential item functioning and fairness | Lab 3, `run_lab("fairness")` | `numeracy`, `certexam` |
| 10 | Linking and equating | Lab 4, `run_lab("linking")` | `linking`, `certexam` |
| 11 | Item banks, test assembly and adaptive testing | Lab 5, `run_lab("cat-design")` | `catbank`, `certexam` bank |
| 12 | Cut scores, reporting and communicating results | Final project | students’ own data |

The [glossary](https://www.okanbulut.com/mirtverse/articles/glossary.md)
defines each term used below, and each week links to its key terms
there. The [cheat
sheet](https://www.okanbulut.com/mirtverse/cheatsheet/mirtverse-cheatsheet.pdf)
lists the main functions on two printable pages; both work well as
handouts from week 1.

## Week by week

### Week 1. Measurement, scoring and classical item analysis

**By the end of the week, students can** score multiple-choice responses
against a key, compute proportion correct and item-total correlations,
and read a distractor analysis.

- **Key terms:** [Classical test
  theory](https://www.okanbulut.com/mirtverse/articles/glossary.html#classical-test-theory),
  [sum
  score](https://www.okanbulut.com/mirtverse/articles/glossary.html#sum-score),
  [p-value](https://www.okanbulut.com/mirtverse/articles/glossary.html#p-value),
  [item-total
  correlation](https://www.okanbulut.com/mirtverse/articles/glossary.html#item-total-correlation).
- **Read:** [Getting
  started](https://www.okanbulut.com/mirtverse/articles/mirtverse.md);
  “The story” and “Start a lab” in [Teaching
  labs](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md).
- **Run:**
  [`key2binary()`](https://philchalmers.github.io/mirt/reference/key2binary.html),
  [`itemstats()`](https://philchalmers.github.io/mirt/reference/itemstats.html)
  (mirt),
  [`profile_data()`](https://www.okanbulut.com/mirtverse/reference/profile_data.md).
- **Lab:** The first two sections of Lab 1 (`run_lab("model-choice")`),
  “Score the responses” and “Screen the items”. Students meet a miskeyed
  item without being told it is there.
- **Data:** `certexam`, `certexam_key`.
- **Discuss:** What a number-correct score can and cannot tell us.

### Week 2. From classical test theory to IRT

**By the end of the week, students can** explain the Rasch, 2PL and 3PL
models, fit them with
[`mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html), and
read an item characteristic curve.

- **Key terms:** [Item response
  theory](https://www.okanbulut.com/mirtverse/articles/glossary.html#item-response-theory),
  [latent
  trait](https://www.okanbulut.com/mirtverse/articles/glossary.html#latent-trait),
  [Rasch
  model](https://www.okanbulut.com/mirtverse/articles/glossary.html#rasch-model),
  [2PL](https://www.okanbulut.com/mirtverse/articles/glossary.html#two-pl),
  [3PL](https://www.okanbulut.com/mirtverse/articles/glossary.html#three-pl),
  [item characteristic
  curve](https://www.okanbulut.com/mirtverse/articles/glossary.html#item-characteristic-curve),
  [difficulty](https://www.okanbulut.com/mirtverse/articles/glossary.html#difficulty),
  [discrimination](https://www.okanbulut.com/mirtverse/articles/glossary.html#discrimination),
  [guessing](https://www.okanbulut.com/mirtverse/articles/glossary.html#guessing).
- **Read:** Sections 1 to 4 of [Getting
  started](https://www.okanbulut.com/mirtverse/articles/mirtverse.md).
- **Run:**
  [`mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html),
  `coef(mod, IRTpars = TRUE)`,
  [`gg_trace()`](https://www.okanbulut.com/mirtverse/reference/gg_trace.md),
  [`item_table()`](https://www.okanbulut.com/mirtverse/reference/item_table.md),
  [`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md).
- **Data:** `LSAT7` (expand it with
  [`expand.table()`](https://philchalmers.github.io/mirt/reference/expand.table.html)).
- **Activity:** Ask students to sketch trace lines for items they invent
  (an easy item, a hard item, a flat item) and then find the closest
  real item in the data.

### Week 3. Estimation and comparing models

**By the end of the week, students can** describe marginal maximum
likelihood in words, recognise a model that has not converged, and
compare nested models with likelihood-ratio tests and information
criteria.

- **Key terms:**
  [Calibration](https://www.okanbulut.com/mirtverse/articles/glossary.html#calibration),
  [marginal maximum
  likelihood](https://www.okanbulut.com/mirtverse/articles/glossary.html#marginal-maximum-likelihood),
  [convergence](https://www.okanbulut.com/mirtverse/articles/glossary.html#convergence),
  [likelihood-ratio
  test](https://www.okanbulut.com/mirtverse/articles/glossary.html#likelihood-ratio-test),
  [information
  criteria](https://www.okanbulut.com/mirtverse/articles/glossary.html#information-criteria),
  [M2](https://www.okanbulut.com/mirtverse/articles/glossary.html#m2),
  [RMSEA](https://www.okanbulut.com/mirtverse/articles/glossary.html#rmsea).
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
- **Discuss:** Why AIC and BIC can disagree, and what sample size has to
  do with fitting a 3PL.

### Week 4. Dimensionality and local independence

**By the end of the week, students can** check whether one dimension is
enough, read standardized residuals and the Q3 statistic, and tell local
dependence from a second trait.

- **Key terms:**
  [Dimensionality](https://www.okanbulut.com/mirtverse/articles/glossary.html#dimensionality),
  [local
  independence](https://www.okanbulut.com/mirtverse/articles/glossary.html#local-independence),
  [local
  dependence](https://www.okanbulut.com/mirtverse/articles/glossary.html#local-dependence),
  [Q3](https://www.okanbulut.com/mirtverse/articles/glossary.html#q3).
- **Run:** A one- vs two-factor model with
  [`anova()`](https://rdrr.io/r/stats/anova.html),
  [`summary()`](https://rdrr.io/r/base/summary.html) for rotated
  loadings, `residuals(mod, type = "Q3")` and
  [`gg_q3()`](https://www.okanbulut.com/mirtverse/reference/gg_q3.md).
- **Lab:** All of Lab 1 (`run_lab("model-choice")`, about 75 minutes).
  It ends with a model choice the student has to justify in writing.
- **Data:** `certexam` (the passage pair Q21 and Q22).
- **Assignment:** Hand in the decision table and justification from the
  end of Lab 1.

### Week 5. Item fit, person fit and item quality

**By the end of the week, students can** read S-X² item fit, compare an
empirical and a model-implied curve, and flag aberrant response
patterns.

- **Key terms:** [Item
  fit](https://www.okanbulut.com/mirtverse/articles/glossary.html#item-fit),
  [S-X²](https://www.okanbulut.com/mirtverse/articles/glossary.html#s-x2),
  [empirical item
  curve](https://www.okanbulut.com/mirtverse/articles/glossary.html#empirical-item-curve),
  [person
  fit](https://www.okanbulut.com/mirtverse/articles/glossary.html#person-fit),
  [Zh](https://www.okanbulut.com/mirtverse/articles/glossary.html#zh).
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
- **Activity:** Students pick the three weakest items from the item
  cards and write one sentence each on what an item writer should
  change.

### Week 6. Information, precision and reliability

**By the end of the week, students can** read item and test information
curves, convert information to a standard error, and explain why
reliability depends on where on the scale you look.

- **Key terms:** [Item
  information](https://www.okanbulut.com/mirtverse/articles/glossary.html#item-information),
  [test
  information](https://www.okanbulut.com/mirtverse/articles/glossary.html#test-information),
  [standard error of
  measurement](https://www.okanbulut.com/mirtverse/articles/glossary.html#standard-error-of-measurement),
  [marginal
  reliability](https://www.okanbulut.com/mirtverse/articles/glossary.html#marginal-reliability),
  [targeting](https://www.okanbulut.com/mirtverse/articles/glossary.html#targeting).
- **Run:**
  [`gg_info()`](https://www.okanbulut.com/mirtverse/reference/gg_info.md),
  [`testinfo()`](https://philchalmers.github.io/mirt/reference/testinfo.html),
  [`marginal_rxx()`](https://philchalmers.github.io/mirt/reference/marginal_rxx.html)
  and
  [`empirical_rxx()`](https://philchalmers.github.io/mirt/reference/empirical_rxx.html)
  (mirt).
- **Lab:** The “Precision at the pass mark” section of Lab 2 previews
  next week.
- **Data:** `certexam`.

### Week 7. Scoring people

**By the end of the week, students can** compare EAP, MAP, ML and WLE
scores, explain why ML fails for perfect scores, and read a Wright map.

- **Key terms:**
  [EAP](https://www.okanbulut.com/mirtverse/articles/glossary.html#eap),
  [MAP](https://www.okanbulut.com/mirtverse/articles/glossary.html#map),
  [ML](https://www.okanbulut.com/mirtverse/articles/glossary.html#ml-scoring),
  [WLE](https://www.okanbulut.com/mirtverse/articles/glossary.html#wle),
  [Wright
  map](https://www.okanbulut.com/mirtverse/articles/glossary.html#wright-map),
  [classification
  accuracy](https://www.okanbulut.com/mirtverse/articles/glossary.html#classification-accuracy).
- **Run:**
  [`fscores()`](https://philchalmers.github.io/mirt/reference/fscores.html)
  (mirt),
  [`gg_scores()`](https://www.okanbulut.com/mirtverse/reference/gg_scores.md),
  [`gg_wright()`](https://www.okanbulut.com/mirtverse/reference/gg_wright.md),
  [`augment_mirt()`](https://www.okanbulut.com/mirtverse/reference/augment_mirt.md).
- **Lab:** All of Lab 2 (`run_lab("decisions")`, about 75 minutes).
  Students choose a scoring method, estimate classification accuracy,
  look for DIF and write a memo to the board. Lab 2 fits its own model,
  so students who missed Lab 1 can still do it.
- **Data:** `certexam`.
- **Assignment:** The memo from the end of Lab 2.

### Week 8. Polytomous items and open-ended responses

**By the end of the week, students can** fit the partial credit,
generalized partial credit and graded response models, read category
curves, and say when categories should be collapsed.

- **Key terms:** [Polytomous
  item](https://www.okanbulut.com/mirtverse/articles/glossary.html#polytomous-item),
  [graded response
  model](https://www.okanbulut.com/mirtverse/articles/glossary.html#graded-response-model),
  [GPCM](https://www.okanbulut.com/mirtverse/articles/glossary.html#gpcm),
  [category response
  curve](https://www.okanbulut.com/mirtverse/articles/glossary.html#category-response-curve),
  [QWK](https://www.okanbulut.com/mirtverse/articles/glossary.html#qwk).
- **Read:** [Assessment
  pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md),
  section “9. Scoring”, for scoring open-ended responses with
  [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md).
- **Run:**
  [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md)
  on polytomous data,
  [`gg_trace()`](https://www.okanbulut.com/mirtverse/reference/gg_trace.md),
  [`gg_info()`](https://www.okanbulut.com/mirtverse/reference/gg_info.md).
- **Lab:** Lab 6 (`run_lab("open-ended")`, about 75 minutes): Rater
  agreement and quadratic weighted kappa, rater severity and
  consistency, resolving two reads, PCM versus GPCM versus GRM,
  collapsing categories with disordered steps, and checking an automated
  scoring engine, including for subgroups.
- **Data:** `openended` (six rater-scored science tasks) in Lab 6;
  `Science` (four Likert-type items) for extra practice.
- **Students coming from ltm, eRm or TAM:**
  [`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md)
  translates their old code ([Coming from other IRT
  packages](https://www.okanbulut.com/mirtverse/articles/mirtify.md)).

### Week 9. Differential item functioning and fairness

**By the end of the week, students can** tell impact from DIF, run a DIF
analysis with anchor items, and explain uniform and non-uniform DIF.

- **Key terms:**
  [DIF](https://www.okanbulut.com/mirtverse/articles/glossary.html#dif),
  [reference and focal
  groups](https://www.okanbulut.com/mirtverse/articles/glossary.html#reference-focal-group),
  [uniform and non-uniform
  DIF](https://www.okanbulut.com/mirtverse/articles/glossary.html#uniform-nonuniform-dif),
  [DIF effect
  size](https://www.okanbulut.com/mirtverse/articles/glossary.html#dif-effect-size),
  [anchor
  items](https://www.okanbulut.com/mirtverse/articles/glossary.html#anchor-items).
- **Run:**
  [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md),
  [`gg_dif()`](https://www.okanbulut.com/mirtverse/reference/gg_dif.md),
  [`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md)
  on the result;
  [`multipleGroup()`](https://philchalmers.github.io/mirt/reference/multipleGroup.html)
  and [`DIF()`](https://philchalmers.github.io/mirt/reference/DIF.html)
  (mirt) for the model behind it.
- **Lab:** The “Fairness across languages” section of Lab 2 for a short
  version; Lab 3 (`run_lab("fairness")`, about 75 minutes) for a full
  session, with Mantel-Haenszel, anchor purification and differential
  test functioning.
- **Data:** `numeracy` (English language learners and fluent students)
  in Lab 3; `certexam` (English and French candidates) in Lab 2.
- **Discuss:** What a content review panel should do with a flagged
  item.

### Week 10. Linking and equating

**By the end of the week, students can** explain why two forms need a
common scale, describe anchor-item and common-person designs, and link a
new calibration to an existing one.

- **Key terms:**
  [Linking](https://www.okanbulut.com/mirtverse/articles/glossary.html#linking),
  [anchor
  items](https://www.okanbulut.com/mirtverse/articles/glossary.html#anchor-items),
  [moment
  linking](https://www.okanbulut.com/mirtverse/articles/glossary.html#moment-linking),
  [characteristic curve
  linking](https://www.okanbulut.com/mirtverse/articles/glossary.html#characteristic-curve-linking),
  [parameter
  drift](https://www.okanbulut.com/mirtverse/articles/glossary.html#parameter-drift).
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
- **Lab:** Lab 4 (`run_lab("linking")`, about 75 minutes): Separate and
  concurrent calibration, mean-sigma linking, anchor drift and IRT
  true-score equating of a pass mark.
- **Data:** `linking` (two forms with common items) in Lab 4;
  `certexam`, split into two field-test forms by
  [`design_field_test()`](https://www.okanbulut.com/mirtverse/reference/design_field_test.md),
  for the pipeline functions.

### Week 11. Item banks, test assembly and adaptive testing

**By the end of the week, students can** describe an item bank, assemble
a form to a target information curve, and explain how a computerized
adaptive test picks items and when it stops.

- **Key terms:** [Item
  bank](https://www.okanbulut.com/mirtverse/articles/glossary.html#item-bank),
  [automated test
  assembly](https://www.okanbulut.com/mirtverse/articles/glossary.html#automated-test-assembly),
  [computerized adaptive
  test](https://www.okanbulut.com/mirtverse/articles/glossary.html#computerized-adaptive-test),
  [multistage
  test](https://www.okanbulut.com/mirtverse/articles/glossary.html#multistage-test),
  [exposure](https://www.okanbulut.com/mirtverse/articles/glossary.html#exposure).
- **Read:** [Assessment
  pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md),
  sections “6. The item bank” and “7. Forms, adaptive and multistage
  tests”.
- **Run:**
  [`mv_bank()`](https://www.okanbulut.com/mirtverse/reference/mv_bank.md),
  [`assemble_forms()`](https://www.okanbulut.com/mirtverse/reference/assemble_forms.md),
  [`simulate_cat()`](https://www.okanbulut.com/mirtverse/reference/simulate_cat.md),
  [`assemble_mst()`](https://www.okanbulut.com/mirtverse/reference/assemble_mst.md).
- **Lab:** Lab 5 (`run_lab("cat-design")`, about 75 minutes): Bank
  information, a CAT by hand, simulation, exposure control, content
  balancing and stopping rules.
- **Data:** `catbank` (a 180-item placement bank) in Lab 5; the
  `certexam` bank built in the pipeline article for the pipeline
  functions.

### Week 12. Cut scores, reporting and communicating results

**By the end of the week, students can** describe a Bookmark standard
setting, estimate classification accuracy at a cut score, and explain
IRT results to someone who does not use R.

- **Key terms:** [Cut
  score](https://www.okanbulut.com/mirtverse/articles/glossary.html#cut-score),
  [standard
  setting](https://www.okanbulut.com/mirtverse/articles/glossary.html#standard-setting),
  [response
  probability](https://www.okanbulut.com/mirtverse/articles/glossary.html#response-probability),
  [classification
  accuracy](https://www.okanbulut.com/mirtverse/articles/glossary.html#classification-accuracy),
  [classification
  consistency](https://www.okanbulut.com/mirtverse/articles/glossary.html#classification-consistency).
- **Read:** [Assessment
  pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md),
  sections “8. Cut scores” and “11. The report”; [Sharing results with a
  dashboard](https://www.okanbulut.com/mirtverse/articles/dashboards.md).
- **Run:**
  [`item_map()`](https://www.okanbulut.com/mirtverse/reference/item_map.md),
  [`set_cuts()`](https://www.okanbulut.com/mirtverse/reference/set_cuts.md),
  [`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md),
  [`mv_dashboard()`](https://www.okanbulut.com/mirtverse/reference/mv_dashboard.md).
- **Final project:** See below.

## An optional module: AI in measurement

Four more weeks take the course into AI. They follow week 12 in a
16-week term, or replace weeks 10 and 11 in a course that wants AI more
than linking and adaptive testing. Each week pairs an AI method with the
psychometric check that goes with it, uses one chapter of the
[book](https://www.okanbulut.com/mirtverse/book/index.md) as the reading
and one lab in class. Everything runs offline: The labs use simulated
data, and language-model examples run from recorded answers
([`mv_llm_replay()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md)).
The [AI Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.md) is
the students’ starting page.

| Week | Topic | Lab | Main data |
|----|----|----|----|
| 13 | Machine learning through an IRT lens; item text and difficulty | Lab 8, `run_lab("item-text")` | `itemtext` |
| 14 | Automatic item generation and item families | Lab 9, `run_lab("aig")` | `aigfield` |
| 15 | Automated scoring and large language models | Lab 7, `run_lab("auto-scoring")` | `essays` |
| 16 | Validity, fairness and governance of AI | Lab 10, `run_lab("ai-audit")` | `aiscored` |

### Week 13. Machine learning through an IRT lens; item text and difficulty

**By the end of the week, students can** translate machine learning
terms into measurement terms, explain why a prediction model is judged
by cross-validation, and predict item difficulty from item text with an
LLTM and a lasso.

- **Key terms:** [Machine
  learning](https://www.okanbulut.com/mirtverse/articles/glossary.html#machine-learning),
  [feature](https://www.okanbulut.com/mirtverse/articles/glossary.html#feature),
  [overfitting and
  cross-validation](https://www.okanbulut.com/mirtverse/articles/glossary.html#cross-validation),
  [LLTM](https://www.okanbulut.com/mirtverse/articles/glossary.html#lltm).
- **Read:** Book chapters [Machine learning through an IRT
  lens](https://www.okanbulut.com/mirtverse/book/ml-lens.md) and [What
  item text tells
  us](https://www.okanbulut.com/mirtverse/book/item-text.md); the
  [translation
  table](https://www.okanbulut.com/mirtverse/articles/ai-translation.md).
- **Run:**
  [`item_features()`](https://www.okanbulut.com/mirtverse/reference/item_features.md),
  [`predict_difficulty()`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md).
- **Lab:** Lab 8 (`run_lab("item-text")`, about 75 minutes).

### Week 14. Automatic item generation and item families

**By the end of the week, students can** write an item model with
constraints, generate isomorphs, and check after a field test whether
the items of each family are equally difficult.

- **Key terms:** [Automatic item
  generation](https://www.okanbulut.com/mirtverse/articles/glossary.html#aig),
  [item
  model](https://www.okanbulut.com/mirtverse/articles/glossary.html#item-model).
- **Read:** Book chapter [Generating
  items](https://www.okanbulut.com/mirtverse/book/aig.md); the
  [assessment
  pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.html#stage-1-2),
  section “1–2. Item writing and review”.
- **Run:**
  [`item_model()`](https://www.okanbulut.com/mirtverse/reference/item_model.md),
  [`generate_isomorphs()`](https://www.okanbulut.com/mirtverse/reference/generate_isomorphs.md),
  [`calibrate_families()`](https://www.okanbulut.com/mirtverse/reference/calibrate_families.md).
- **Lab:** Lab 9 (`run_lab("aig")`, about 75 minutes).

### Week 15. Automated scoring and large language models

**By the end of the week, students can** train a scoring engine, judge
it against human raters with QWK, SMD and PRMSE overall and within
groups, and describe safe uses of a language model in an analysis.

- **Key terms:** [Automated
  scoring](https://www.okanbulut.com/mirtverse/articles/glossary.html#automated-scoring),
  [QWK](https://www.okanbulut.com/mirtverse/articles/glossary.html#qwk),
  [PRMSE](https://www.okanbulut.com/mirtverse/articles/glossary.html#prmse),
  [large language
  model](https://www.okanbulut.com/mirtverse/articles/glossary.html#llm),
  [hallucination](https://www.okanbulut.com/mirtverse/articles/glossary.html#hallucination).
- **Read:** Book chapters [Automated
  scoring](https://www.okanbulut.com/mirtverse/book/auto-scoring.md) and
  [Large language models as a
  colleague](https://www.okanbulut.com/mirtverse/book/llms.md).
- **Run:**
  [`train_scorer()`](https://www.okanbulut.com/mirtverse/reference/train_scorer.md),
  [`agreement_report()`](https://www.okanbulut.com/mirtverse/reference/agreement_report.md),
  [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md),
  [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
  with
  [`mv_llm_replay()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md).
- **Lab:** Lab 7 (`run_lab("auto-scoring")`, about 75 minutes).

### Week 16. Validity, fairness and governance of AI

**By the end of the week, students can** audit an AI component for
agreement, differential scoring and drift, separate DIF caused by an
engine from DIF in an item, and write the validity argument for using
its scores.

- **Key terms:** [Differential
  scoring](https://www.okanbulut.com/mirtverse/articles/glossary.html#differential-scoring),
  [validity
  argument](https://www.okanbulut.com/mirtverse/articles/glossary.html#validity-argument).
- **Read:** Book chapter [Validity, fairness and governance of
  AI](https://www.okanbulut.com/mirtverse/book/ai-validity.md); the
  [reading
  list](https://www.okanbulut.com/mirtverse/articles/ai-reading.html#validity),
  section “Validity, fairness and governance”.
- **Run:**
  [`ai_audit()`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md),
  [`validity_argument()`](https://www.okanbulut.com/mirtverse/reference/validity_argument.md),
  [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md).
- **Lab:** Lab 10 (`run_lab("ai-audit")`, about 75 minutes).
- **Assessment:** The lab’s memo to the technical advisory committee
  makes a good final task for the module.

### On your own data

The [instructor
toolkit](https://www.okanbulut.com/mirtverse/articles/instructor-toolkit.md)
has three section types that teach these topics on your own data:
`"item-features"` (needs the text of your items), `"aig"` (needs the
family of each item) and `"ai-scoring"` (needs machine and human
scores). Give the extra data to
[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md):

``` r

new_lab("our-engine", data = "data/responses.csv",
        scores = "data/engine_scores.csv",       # machine, human1, human2, group
        sections = c("intro", "models", "ai-scoring", "reflection", "wrap-up"))
```

### A one-day workshop

For practitioners who already know IRT, the module fits in one day. Ask
participants to install the packages before they come and to read the
[AI Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.md) page.
The [workshop
kit](https://www.okanbulut.com/mirtverse/articles/ai-workshop.md)
([`copy_workshop()`](https://www.okanbulut.com/mirtverse/reference/copy_workshop.md))
has the slides and a facilitator’s guide for this schedule.

| Time | Session | Material |
|----|----|----|
| 9:00 to 9:45 | AI in measurement: What changes and what does not | [AI Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.md); book chapter [Machine learning through an IRT lens](https://www.okanbulut.com/mirtverse/book/ml-lens.md) |
| 9:45 to 11:00 | Automated scoring | Lab 7, `run_lab("auto-scoring")` |
| 11:15 to 12:30 | Item text and difficulty | Lab 8, `run_lab("item-text")` |
| 13:30 to 14:45 | Automatic item generation | Lab 9, `run_lab("aig")` |
| 15:00 to 16:15 | Auditing an AI-scored test | Lab 10, `run_lab("ai-audit")` |
| 16:15 to 17:00 | Governance, and what to do on Monday | Book chapter [Validity, fairness and governance of AI](https://www.okanbulut.com/mirtverse/book/ai-validity.md), section on governance |

With less time, keep Labs 7 and 10: Together they cover an engine from
its training to its audit.

## Assessment ideas

| Weight | Task | When |
|----|----|----|
| 20% | Lab 1 decision table and model justification | Week 4 |
| 20% | Lab 2 memo to the board | Week 7 |
| 20% | Two short problem sets (one on fit and precision, one on DIF or linking) | Weeks 6 and 10 |
| 40% | Final project: A full analysis of a dataset of the student’s choice, handed in as an [`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md) or a dashboard plus a two-page memo | Week 12 |

For the final project, students can follow the [assessment
pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md)
from calibration to the report. Its flags point out what to check before
each next step, which works well as a checklist for the write-up.

## Adapting the course

- **A shorter course (8 weeks):** Combine weeks 2 and 3, and weeks 5 and
  6; drop week 10 and treat week 11 as a lecture without a lab.
- **An undergraduate course:** Spend two weeks on week 1, use the
  [workbench](https://www.okanbulut.com/mirtverse/articles/workbench.md)
  instead of code until week 4, and end at week 9.
- **A second course:** Add multidimensional and bifactor models
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
- **AI in measurement:** Add the [four-week AI module](#ai-module), or
  run it as a one-day workshop.

## Planned resources

These resources are being built and will be linked from the weeks above
when they are released.

| Resource | Used in | Status |
|----|----|----|
| Online book with a chapter per week | All weeks | Available: [Book](https://www.okanbulut.com/mirtverse/book/index.md) |
| Glossary of IRT terms on this site | All weeks | Available: [Glossary](https://www.okanbulut.com/mirtverse/articles/glossary.md) |
| Two-page cheat sheet of the main functions | All weeks | Available: [PDF](https://www.okanbulut.com/mirtverse/cheatsheet/mirtverse-cheatsheet.pdf) |
| DIF and fairness lab | Week 9 | Available: `run_lab("fairness")` |
| Linking two forms lab | Week 10 | Available: `run_lab("linking")` |
| CAT design lab | Week 11 | Available: `run_lab("cat-design")` |
| Open-ended scoring lab | Week 8 | Available: `run_lab("open-ended")` |
| Instructor toolkit: Labs on your own data, editable copies of the labs | All weeks | Available: [Guide](https://www.okanbulut.com/mirtverse/articles/instructor-toolkit.md) |
| AI in measurement module: Four chapters and four labs, with toolkit sections for your own data | Weeks 13 to 16 | Available: [AI module](#ai-module) |
