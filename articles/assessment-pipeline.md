# An assessment pipeline from blueprint to bank monitoring

A test passes through many hands before a score reaches a test taker: a
blueprint, item writing, review, a field test, calibration, form
assembly, standard setting, scoring, security checks, a report and,
after each administration, a look at the health of the item bank. The
**assessment pipeline** in mirtverse puts these steps in one object.
Each stage does its work, then runs a *gate*: a set of checks that
records what it finds as **flags** for you to consider before the next
stage.

This article takes the `certexam` data (a simulated 32-item
certification exam taken by 1,200 candidates in English or French)
through every stage. The data have problems planted in them, and the
gates find them.

The map below shows the whole flow. Click a stage, or play the tour, to
see its functions, what its gate checks and what the gate found in this
example.

ran, no decision needed review flag block flag skipped here

◀ Prev

▶ Play the tour

Next ▶

The pipeline runs blueprint, item generation, item review, field-test
design, data intake, calibration, item bank and linking, forms, cut
scores, scoring, test security, the report and bank monitoring, with a
gate of checks after each stage.

``` r

library(mirtverse)
#> Loading required package: mirt
#> Loading required package: stats4
#> Loading required package: lattice
```

## The pipeline object and its rules

``` r

p <- mv_pipeline("Certification exam")
p
#> <mv_pipeline> Certification exam
#> flags warn (strict = FALSE); rules: standards
#> 
#> [ ] 0  Blueprint         not run
#> [ ] 1  Item generation   not run
#> [ ] 2  Item review       not run
#> [ ] 3  Field-test design not run
#> [ ] 4  Data intake       not run
#> [ ] 5  Calibration       not run
#> [ ] 6  Linking and bank  not run
#> [ ] 7  Forms             not run
#> [ ] 8  Cut scores        not run
#> [ ] 9  Scoring           not run
#> [ ] 10 Test security     not run
#> [ ] 11 Reporting         not run
#> [ ] 12 Bank monitoring   not run
#> 
#> No open flags.
```

Every check compares a statistic with a threshold from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md).
The defaults follow common operational practice and every one can be
changed by name, for example `mv_rules(q3 = 0.25)`, or relaxed for a
pilot study with `mv_rules(preset = "lenient")`.

Flags have three levels:

- **info**: for awareness.
- **review**: something a psychometrician should look at.
- **block**: a problem that makes later stages unsafe.

By default flags only warn, so every stage still runs. With
`mv_pipeline(strict = TRUE)`, a stage refuses to start while an earlier
stage has open review or block flags.

## 0. Blueprint

The blueprint is the contract that later stages check against: what the
test measures, how scores will be used, and how many items each content
area needs on a form.

``` r

p <- set_blueprint(p, c(Ethics = 4, Practice = 5, Law = 3),
                   construct = "Professional knowledge for certification",
                   use = "pass/fail certification", reliability = 0.85)
p$blueprint$cells
#> # A tibble: 3 × 4
#>   cell     content  cognitive     n
#>   <chr>    <chr>    <chr>     <dbl>
#> 1 Ethics   Ethics   NA            4
#> 2 Practice Practice NA            5
#> 3 Law      Law      NA            3
```

Because the score supports a pass/fail decision, we asked for a
reliability of at least 0.85. That target replaces the default
`reliability` rule, so the calibration gate will hold the test to it.

## 1–2. Item writing and review

[`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
drafts multiple-choice and open-ended items for each blueprint cell with
a language model through the ellmer package. It checks the drafts (a
second model call verifies each key) and flags disputed keys, weak
distractors, near-duplicate items and readability above the grade level.
Items written by people come in with
[`add_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
and pass the same checks.

[`review_packet()`](https://www.okanbulut.com/mirtverse/reference/review_packet.md)
writes a CSV review form (it opens in Excel) for content and sensitivity
reviewers, optionally with an AI screen.
[`read_reviews()`](https://www.okanbulut.com/mirtverse/reference/review_packet.md)
reads their decisions back and flags items without enough reviewers,
items judged misaligned or biased, and low agreement between reviewers.

``` r

# generate_items() needs an API key for the model provider
p <- generate_items(p, n = 3)
p <- review_packet(p, "review.csv", reviewers = c("Ana", "Ben", "Chen"))
p <- read_reviews(p, "review-returned.csv")
```

The certexam items already exist, so we skip these steps here.

## 3. Field-test design

Before calibration data exist,
[`design_field_test()`](https://www.okanbulut.com/mirtverse/reference/design_field_test.md)
plans the field test: how many forms, which anchor items they share, and
how many candidates each form needs. It then simulates parameter
recovery under that plan.

``` r

p <- design_field_test(p, n_forms = 2, n_per_form = 600, items = 32,
                       reps = 2, seed = 1)
p$field_test$recovery
#> # A tibble: 1 × 4
#>    reps rmse_a rmse_d converged
#>   <dbl>  <dbl>  <dbl>     <dbl>
#> 1     2  0.220  0.121         1
flags(p, stage = "field_test")
#> # A tibble: 1 × 10
#>      id stage      check    target value         rule  level advice status note 
#>   <int> <chr>      <chr>    <chr>  <chr>         <chr> <chr> <chr>  <chr>  <chr>
#> 1     1 field_test recovery design RMSE of slop… RMSE… revi… Param… open   ""
```

Two forms of 600 candidates recover the slopes with an RMSE a little
above the 0.2 target. The usual answer is more candidates per form. Here
we accept the plan and record why:

``` r

p <- acknowledge(p, check = "recovery",
                 note = "Sample fixed by the testing window")
```

## 4. Data intake

[`add_responses()`](https://www.okanbulut.com/mirtverse/reference/add_responses.md)
scores the raw answers with the key, then checks for missing data,
possible miskeys, straight-lining, rapid guessing and sparse score
categories.

``` r

p <- add_responses(p, certexam, items = 3:34, key = certexam_key,
                   id = "id", group = "language")
flags(p, stage = "intake")
#> # A tibble: 1 × 10
#>      id stage  check           target value      rule  level advice status note 
#>   <int> <chr>  <chr>           <chr>  <chr>      <chr> <chr> <chr>  <chr>  <chr>
#> 1     2 intake possible_miskey Q14    p = 0.18,… p < … block Check… open   ""
```

Q14 is answered correctly by almost nobody and has a negative item-total
correlation, which is the signature of a miskey. That is a block flag.
Once the item writer confirms the key was wrong, we drop the item, which
marks its flag as fixed:

``` r

p <- drop_items(p, "Q14", note = "Key confirmed wrong by the item writer")
```

## 5. Calibration

``` r

p <- calibrate(p, model = "2PL")
flags(p, stage = "calibration")
#> # A tibble: 5 × 10
#>      id stage       check           target value rule  level advice status note 
#>   <int> <chr>       <chr>           <chr>  <chr> <chr> <chr> <chr>  <chr>  <chr>
#> 1     4 calibration dif_large       Q09    MH D… ETS … block Have … open   ""   
#> 2     3 calibration local_dependen… Q21 &… Q3 =… |Q3|… revi… The i… open   ""   
#> 3     5 calibration dif_moderate    Q27    MH D… ETS … revi… Revie… open   ""   
#> 4     6 calibration low_reliability test   marg… reli… revi… Score… open   ""   
#> 5     7 calibration person_misfit   22 re… 1.8%… Zh <… info  About… open   ""
```

The calibration gate checks convergence, model fit, local dependence,
item fit, parameter ranges, DIF between the language groups, reliability
and person fit. It finds three planted problems:

- Q21 and Q22 are locally dependent.
- Q09 has large DIF (block).
- Q27 has moderate DIF.

It also reports that reliability falls short of the 0.85 target from the
blueprint. Each needs a decision:

``` r

p <- acknowledge(p, check = "local_dependence",
                 note = "Q21 and Q22 share a case; keep them apart on forms")
p <- override(p, check = "dif_large",
              note = "Translation reviewed; French version revised")
p <- acknowledge(p, check = "dif_moderate", note = "Sent to the bias panel")
p <- acknowledge(p, check = "low_reliability",
                 note = "Operational forms will be longer than the field test")
```

[`override()`](https://www.okanbulut.com/mirtverse/reference/acknowledge.md)
needs a written reason;
[`acknowledge()`](https://www.okanbulut.com/mirtverse/reference/acknowledge.md)
takes an optional note. Every decision is logged and printed in the
report. Run `flags(p, status = "all")` to see decided flags too.

## 6. The item bank

[`bank_items()`](https://www.okanbulut.com/mirtverse/reference/bank_items.md)
stores the calibrated items in an item bank. In a later administration,
[`link_to_bank()`](https://www.okanbulut.com/mirtverse/reference/link_to_bank.md)
puts a new calibration on the bank’s scale through anchor items and
checks the anchors for drift.

``` r

p <- bank_items(p, name = "Certification bank")
p$bank
#> <mv_bank> Certification bank: 31 items (31 active)
#> Item types: 2PL 31 
#> Location (b) from -2.37 to 3.05; median discrimination 0.90
#> Sources: Certification exam
```

## 7. Forms, adaptive and multistage tests

[`assemble_forms()`](https://www.okanbulut.com/mirtverse/reference/assemble_forms.md)
builds parallel fixed forms with automated test assembly (through
eatATA), meeting a content blueprint and keeping enemy items apart.
[`simulate_cat()`](https://www.okanbulut.com/mirtverse/reference/simulate_cat.md)
and
[`assemble_mst()`](https://www.okanbulut.com/mirtverse/reference/assemble_mst.md)
simulate adaptive and multistage tests with mirtCAT.

``` r

content <- setNames(rep(c("Ethics", "Practice", "Law"), c(10, 12, 10)),
                    sprintf("Q%02d", 1:32))
p <- assemble_forms(p, length = 12, n_forms = 2, theta = c(-1, 0, 1),
                    content = content[names(content) != "Q14"],
                    blueprint = c(Ethics = 4, Practice = 5, Law = 3),
                    enemies = list(c("Q21", "Q22")))
p$forms$info
#> # A tibble: 6 × 4
#>    form theta information   sem
#>   <int> <dbl>       <dbl> <dbl>
#> 1     1    -1        2.62 0.617
#> 2     1     0        2.67 0.612
#> 3     1     1        1.86 0.734
#> 4     2    -1        2.76 0.602
#> 5     2     0        2.58 0.623
#> 6     2     1        1.82 0.742
```

The two forms meet the blueprint, keep Q21 and Q22 apart and are
parallel: their information differs by less than 10% at each ability
level. The forms gate also checks measurement precision:

``` r

flags(p, stage = "forms")[, c("check", "target", "value", "rule")]
#> # A tibble: 6 × 4
#>   check          target               value      rule       
#>   <chr>          <chr>                <chr>      <chr>      
#> 1 form_precision form 1 at theta = -1 SEM = 0.62 SEM <= 0.35
#> 2 form_precision form 1 at theta = 0  SEM = 0.61 SEM <= 0.35
#> 3 form_precision form 1 at theta = 1  SEM = 0.73 SEM <= 0.35
#> 4 form_precision form 2 at theta = -1 SEM = 0.60 SEM <= 0.35
#> 5 form_precision form 2 at theta = 0  SEM = 0.62 SEM <= 0.35
#> 6 form_precision form 2 at theta = 1  SEM = 0.74 SEM <= 0.35
```

Twelve items cannot reach a standard error of 0.35. For a pass/fail
decision, precision matters most near the cut score, which the next
stage checks.

## 8. Cut scores

[`set_cuts()`](https://www.okanbulut.com/mirtverse/reference/set_cuts.md)
takes cut scores on the ability or raw-score scale (or a
standard-setting panel’s ratings) and estimates classification accuracy
and consistency.

``` r

p <- set_cuts(p, cuts = 18, scale = "raw", labels = c("Fail", "Pass"))
p$cuts$summary
#> # A tibble: 1 × 3
#>   accuracy consistency kappa
#>      <dbl>       <dbl> <dbl>
#> 1    0.861       0.809 0.613
flags(p, stage = "cuts")[, c("check", "target", "value", "rule")]
#> # A tibble: 1 × 4
#>   check         target       value                      rule       
#>   <chr>         <chr>        <chr>                      <chr>      
#> 1 cut_precision cut 1 (Pass) SEM = 0.42 at theta = 0.16 SEM <= 0.35
```

Accuracy (0.86) and consistency (0.81) meet the defaults of 0.85 and
0.80, but the standard error at the cut is above 0.35. More items near
the cut would help, which is the same message the reliability flag gave.

## 9. Scoring

[`score_persons()`](https://www.okanbulut.com/mirtverse/reference/score_persons.md)
estimates each candidate’s ability and flags imprecise and extreme
scores. Open-ended responses are scored first with
[`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md),
either by a language model against the item rubrics or by a trained
model you supply. The scores are checked against human scores (quadratic
weighted kappa, standardized mean differences overall and by group).

``` r

p <- score_persons(p)
head(p$scores)
#> # A tibble: 6 × 4
#>   id     theta    se group  
#>   <chr>  <dbl> <dbl> <fct>  
#> 1 C0001  0.921 0.433 French 
#> 2 C0002  0.917 0.432 English
#> 3 C0003 -0.459 0.381 English
#> 4 C0004  0.628 0.413 English
#> 5 C0005  0.357 0.399 English
#> 6 C0006 -0.861 0.384 French
```

## 10. Test security

[`check_security()`](https://www.okanbulut.com/mirtverse/reference/check_security.md)
looks for evidence that a score may not reflect the candidate’s own
ability:

- preknowledge of items suspected to have leaked;
- items leaking across administration windows;
- parameter drift from the bank;
- answer copying;
- aberrant response times;
- sites with too many flagged candidates;
- unusual score gains.

``` r

p <- check_security(p, leaked = c("Q01", "Q02", "Q03", "Q04", "Q05"))
flags(p, stage = "security")
#> # A tibble: 0 × 10
#> # ℹ 10 variables: id <int>, stage <chr>, check <chr>, target <chr>,
#> #   value <chr>, rule <chr>, level <chr>, advice <chr>, status <chr>,
#> #   note <chr>
```

Here no candidate shows evidence of preknowledge of those five items.
Security flags are evidence for an investigation, not proof of
misconduct. The candidates involved are kept in `p$security$persons` for
investigators. Flags and reports give counts only.

## 11. The report

[`pipeline_report()`](https://www.okanbulut.com/mirtverse/reference/pipeline_report.md)
writes an HTML technical report that covers:

- the model and the item statistics;
- a section for each stage that ran;
- every flag and every decision recorded about it;
- the R code that reproduces the pipeline.

``` r

pipeline_report(p, file = "certification-report.html")
```

The code is also in `p$code`:

``` r

cat(p$code, sep = "\n")
#> library(mirtverse)
#> p <- mv_pipeline(title = "Certification exam")
#> p <- set_blueprint(p, cells = c(Ethics = 4, Practice = 5, Law = 3), construct = "Professional knowledge for certification", 
#>     use = "pass/fail certification", reliability = 0.85)
#> p <- design_field_test(p, n_forms = 2, n_per_form = 600, items = 32, reps = 2, seed = 1)
#> p <- acknowledge(p, check = "recovery", note = "Sample fixed by the testing window")
#> p <- add_responses(p, data = certexam, items = 3:34, key = certexam_key, group = "language", 
#>     id = "id")
#> p <- drop_items(p, items = "Q14", note = "Key confirmed wrong by the item writer")
#> p <- calibrate(p, model = "2PL")
#> p <- acknowledge(p, check = "local_dependence", note = "Q21 and Q22 share a case; keep them apart on forms")
#> p <- override(p, check = "dif_large", note = "Translation reviewed; French version revised")
#> p <- acknowledge(p, check = "dif_moderate", note = "Sent to the bias panel")
#> p <- acknowledge(p, check = "low_reliability", note = "Operational forms will be longer than the field test")
#> p <- bank_items(p, name = "Certification bank")
#> p <- assemble_forms(p, length = 12, n_forms = 2, theta = c(-1, 0, 1), content = content[names(content) != 
#>     "Q14"], blueprint = c(Ethics = 4, Practice = 5, Law = 3), enemies = list(c("Q21", 
#>     "Q22")))
#> p <- set_cuts(p, cuts = 18, scale = "raw", labels = c("Fail", "Pass"))
#> p <- score_persons(p)
#> p <- check_security(p, leaked = c("Q01", "Q02", "Q03", "Q04", "Q05"))
```

## 12. Bank monitoring

After each administration,
[`monitor_bank()`](https://www.okanbulut.com/mirtverse/reference/monitor_bank.md)
records it in the bank under a window name, then checks the bank’s
history:

- items over-exposed in consecutive windows;
- content cells with too few active items;
- reliability falling from its first value;
- items unused for a year.

``` r

p <- monitor_bank(p, window = "2026 spring", date = "2026-04-15",
                  content = content)
p$monitoring$windows
#> # A tibble: 1 × 4
#>   window      date           n reliability
#>   <chr>       <date>     <int>       <dbl>
#> 1 2026 spring 2026-04-15  1200       0.831
p$monitoring$cells
#> # A tibble: 3 × 3
#>   cell     active minimum
#>   <chr>     <int>   <dbl>
#> 1 Ethics       10       8
#> 2 Practice     11      10
#> 3 Law          10       6
```

The cell minimums come from the blueprint: by default the bank should
hold at least `cell_depth` (2) times each cell’s count on a form. Items
that a check flags can be retired or sent back to review with
[`retire_items()`](https://www.okanbulut.com/mirtverse/reference/retire_items.md);
they stay in the bank with their history but are no longer used for
forms or linking.

``` r

p <- retire_items(p, c("Q01", "Q02", "Q03", "Q04", "Q05"),
                  note = "Posted on a study forum; retired as a precaution")
p <- monitor_bank(p, record = FALSE)
flags(p, stage = "monitoring")
#> # A tibble: 1 × 10
#>      id stage      check      target value       rule  level advice status note 
#>   <int> <chr>      <chr>      <chr>  <chr>       <chr> <chr> <chr>  <chr>  <chr>
#> 1    16 monitoring bank_depth Ethics 5 active i… enou… revi… Write… open   ""
```

Retiring five Ethics items leaves that cell with fewer active items than
the blueprint needs, so the next round of item writing should start
there. Retiring items also marks the forms as needing a rerun. Save the
bank with `saveRDS(p$bank, "bank.rds")` to keep its history for the next
administration.

## Where everything stands

Printing the pipeline shows each stage, its summary and its open flags:

``` r

p
#> <mv_pipeline> Certification exam
#> flags warn (strict = FALSE); rules: standards
#> 
#> [x] 0  Blueprint         3 cells, 12 items per form
#> [ ] 1  Item generation   not run
#> [ ] 2  Item review       not run
#> [x] 3  Field-test design 2 forms of 18 items, 4 anchors, 1,200 test takers
#> [x] 4  Data intake       1,200 respondents, 32 items, scored with key
#> [x] 5  Calibration       2PL, converged, reliability 0.83  | open: 1 info
#> [x] 6  Linking and bank  31 items added to the bank
#> [!] 7  Forms             earlier stages changed since this stage ran  | open: 6 review
#> [x] 8  Cut scores        1 cut, accuracy 0.86, consistency 0.81  | open: 1 review
#> [x] 9  Scoring           EAP scores for 1,200 test takers, reliability 0.83  | open: 1 review
#> [x] 10 Test security     2 checks; 0 test takers with evidence
#> [ ] 11 Reporting         not run
#> [x] 12 Bank monitoring   1 window, 26 active items  | open: 1 review
#> 
#> Open flags: 9 review, 1 info. See flags(p). 6 decision(s) recorded.
```

## Strict mode and the workbench

For operational work, start the pipeline with `strict = TRUE`. Then a
stage will not run while an earlier stage has open review or block
flags, so no problem can be passed over without a recorded decision.

The **Pipeline** tab of
[`launch_workbench()`](https://www.okanbulut.com/mirtverse/reference/launch_workbench.md)
runs uploaded data through the intake and calibration gates, or loads a
pipeline saved with [`saveRDS()`](https://rdrr.io/r/base/readRDS.html).
It shows the stage tracker and the flags. Select flags there to
acknowledge, override or drop items, then recalibrate. The tab shows the
R code for every step as you go.
