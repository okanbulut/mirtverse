# mirtverse (development version)

## Assessment pipeline

* New assessment pipeline (first phase). `mv_pipeline()` starts a pipeline
  that takes a test from response data to a technical report in stages, with
  a gate of checks after each stage: `add_responses()` scores and screens the
  data (miskeyed items, missing data, straight-lining, rapid guessing, sparse
  categories), `calibrate()` fits the model and checks convergence, model fit,
  local dependence, item fit, parameter ranges, DIF (Mantel-Haenszel and
  standardized mean difference with the ETS A/B/C rules) and reliability, and
  `pipeline_report()` writes the HTML report with a section listing every
  flag and decision. Flags are `info`, `review` or `block`; they warn by
  default, and with `strict = TRUE` open review and block flags stop the next
  stage until a decision is recorded with `acknowledge()` or `override()`, or
  the item is removed with `drop_items()`. `flags()` lists them, and
  `mv_rules()` holds every threshold, which users can change by name.
  `mv_report()` gains an `extra` argument for additional sections.

* Blueprint and item generation for the assessment pipeline (stages 0 and
  1). `set_blueprint()` records the construct, content cells with target
  counts, item types, score use and target reliability, and flags empty
  cells and a missing score use. `generate_items()` writes multiple-choice
  items (with keys and option rationales) and open-ended items (with rubrics
  and anchor responses) for each cell through ellmer, using the provider set
  up with `mv_ask_setup()`, and `verify_items()` has an independent model
  call answer each item without the key. `add_items()` adds items written by
  people. The checks flag invalid or disputed keys, weak distractors,
  incomplete rubrics, near-duplicates, thin blueprint coverage and hard
  reading levels, and the pipeline report gains blueprint and item
  development sections. `mv_rules()` gains `duplicate_sim` and
  `coverage_ratio`.

* Item review and field-test design for the assessment pipeline (stages 2
  and 3). `review_packet()` writes a review form with one row per item and
  reviewer (optionally after an AI bias and accessibility screen), and
  `read_reviews()` reads the decisions back, sets each item's status by
  majority and flags items with too few reviewers, alignment disagreements,
  sensitivity concerns, revision requests, low reviewer agreement (Fleiss'
  kappa) and missing provenance. `design_field_test()` spreads the approved
  items over forms with anchor items, and flags small samples per item, too
  few anchors, cells without an anchor and poor simulated parameter
  recovery. `mv_rules()` gains `min_reviewers`, `review_kappa`, `n_rasch`,
  `n_2pl`, `n_3pl` and `recovery_rmse`.

* Item banks and linking for the assessment pipeline (stage 6). `mv_bank()`
  starts an item bank from a calibrated model or pipeline, `link_to_bank()`
  puts a new calibration on the bank's scale through anchor items
  (Stocking-Lord, Haebara, mean-sigma, mean-mean or fixed-anchor calibration)
  and flags drifting anchors, too few anchors and unusual linking constants,
  and `bank_items()` adds the new items to the bank. The pipeline report gains
  a linking section, and `mv_rules()` gains `min_anchors`,
  `min_anchor_share`, `anchor_displacement`, `link_slope_min` and
  `link_slope_max`.

* Test forms for the assessment pipeline (stage 7). `assemble_forms()` builds
  one or more fixed forms by automated test assembly (eatATA), with a content
  blueprint, enemy items and parallel forms; `simulate_cat()` simulates a
  computerized adaptive test with mirtCAT; and `assemble_mst()` assembles a
  two-stage multistage test and simulates its routing. The checks flag
  unbuildable forms, blueprint and enemy violations, non-parallel forms,
  imprecise forms or CATs, over-exposed and unused items, shallow banks and
  misrouting. The pipeline report gains a forms section, and `mv_rules()`
  gains `parallel_tol`, `cat_sem`, `cat_bias`, `max_exposure`,
  `unused_share`, `bank_depth`, `mst_routing` and `min_group_n`. eatATA and
  mirtCAT are suggested packages.

* Cut scores for the assessment pipeline (stage 8). `set_cuts()` records cut
  scores on the ability or summed-score scale (or from a standard-setting
  panel's ratings) and estimates classification accuracy and consistency,
  overall and by cut, with kappa and false positive and negative rates: by
  Lee's (2010) method for summed-score cuts and Rudner's (2001) method for
  ability cuts, for the calibrated test or a fixed form. It flags low
  accuracy or consistency, imprecise cuts and panel disagreement, and the
  pipeline report gains a cut score section. `item_map()` gives the ordered
  item booklet for Bookmark standard setting. `mv_rules()` gains
  `cut_accuracy`, `cut_consistency`, `cut_sem` and `panel_sd`.

* Scoring for the assessment pipeline (stage 9). `score_open()` scores
  open-ended responses against their rubrics with a language model through
  ellmer, or with any trained model that has a `predict()` method, and
  checks the machine scores against human scores (Williamson, Xi and Breyer,
  2012): too few double-scored responses, low human-human or machine-human
  quadratic weighted kappa, shifted score distributions and subgroup
  differences. Short, off-topic and low-confidence responses are routed to
  human scoring, and the final scores can join the response data for a
  mixed-format calibration. `score_persons()` estimates abilities and flags
  low reliability and extreme scores. `mv_rules()` gains `n_validation`,
  `qwk_min`, `qwk_drop`, `score_smd`, `subgroup_smd`, `min_confidence`,
  `min_words` and `max_se`.

* Test security for the assessment pipeline (stage 10). `check_security()`
  looks for item preknowledge (a likelihood ratio test of leaked against
  secure items), item leakage across administration windows (proportion
  correct up, response times down), parameter drift from the bank, answer
  copying (identical incorrect answers against their expected number),
  aberrant response times (lognormal residuals), sites with too many flagged
  test takers and unusual score gains. Respondent-level evidence stays in
  `p$security$persons`; flags and the report give counts only. `mv_rules()`
  gains `preknowledge_alpha`, `leak_p`, `leak_rt`, `drift_a`, `drift_b`,
  `copy_alpha`, `rt_resid`, `rt_share`, `site_alpha` and `gain_sem`.

* Bank monitoring for the assessment pipeline (stage 12). `monitor_bank()`
  records each administration in the item bank (item exposure and marginal
  reliability by window) and checks the bank over time: items over-exposed
  in consecutive windows, content cells with too few active items,
  reliability falling from its first value, and items unused for a year.
  `retire_items()` retires bank items or sends them back to review.
  `mv_rules()` gains `exposure_windows`, `cell_depth`, `reliability_drop`
  and `unused_days`.

* The workbench gains a Pipeline tab: run the data through the assessment
  pipeline's intake and calibration gates (or load a saved pipeline), follow
  the stage tracker, record decisions on flags, drop items and recalibrate,
  and download the pipeline and its report. The SAT12 example in the
  workbench now loads correctly.

* New article, "An assessment pipeline from blueprint to bank monitoring",
  takes the `certexam` data through every stage of the pipeline.

## Coming from other IRT packages

* New `mirtify()` translates code written for ltm, eRm, TAM and irtQ into
  mirt code, with a note on every difference between the packages (for
  example CML versus MML in eRm, the scaling constant `D` in irtQ, and the
  number of quadrature points). It covers the model functions and their
  follow-ups: person scores, item and person fit, information, plots and
  Andersen's likelihood-ratio test. `run = TRUE` also runs the translated
  code. `mirtify_crosswalk()` lists every supported function, and the new
  article "Moving from ltm, eRm, TAM or irtQ to mirt" walks through examples
  and shows how closely the translated models match the originals.

* The homepage has a `mirtify()` section with a short example.

## Teaching labs

* New interactive teaching labs for measurement courses, built with learnr.
  `run_lab("model-choice")` opens Lab 1, "Choosing a model the board can
  defend": students score a certification exam, find a miskeyed item, check
  dimensionality, compare the Rasch, 2PL and 3PL models, check item fit and
  local dependence, and justify a model, with feedback on every decision and a
  summary of their choices at the end. `run_lab("decisions")` opens Lab 2,
  "From parameters to decisions": reading item parameters, precision at the
  pass mark, choosing a scoring method, classification accuracy, DIF between
  English and French candidates, a memo to the board, and a reveal of the
  truth behind the data. `list_labs()` lists the labs. The new
  `certexam` data (with `certexam_key`) are simulated with known problems
  planted for the labs; `lab_truth()` reveals them for instructors. The
  article "Teaching labs for measurement courses" introduces the labs for
  students, followed by an instructor guide and an answer key.

* New article, "A course map for instructors": a suggested 12-week IRT
  syllabus that links each week to articles, labs, functions and datasets.

## Sharing results

* New `mv_dashboard()` builds a read-only 'shiny' dashboard of your results for
  people who do not use R. Choose the panels (summary, items with health
  cards, item curves with an ability slider, information, Wright map, score
  distribution and conversion table, and optionally person scores, DIF and
  response times), add a title and logo, and run it. `export_dashboard()`
  saves it as an `app.R` folder ready for shinyapps.io or Posit Connect. The
  saved dashboard holds summaries only, never the item responses, and holds
  individual scores only when you add the `"persons"` panel.

* `export_dashboard(format = "html")` saves the dashboard as one
  self-contained HTML file that needs no server, no R and no internet
  connection. The item table, item curves with the ability slider, item
  information and person lookup stay interactive.

* The article "Sharing results with a dashboard" is now a full guide: when to
  use a dashboard rather than the workbench or the report, every panel,
  sharing as one HTML file or as a Shiny app, privacy, and a live example
  dashboard to open.

## Scripts from plain language

* New `mv_ask()` writes a complete, commented analysis script from a
  plain-language request such as "fit a 2PL, check DIF by gender and make a
  report". Requests are understood by Claude, OpenAI GPT or a local Ollama
  model (set up once with `mv_ask_setup()`), or offline by a built-in keyword
  parser that asks follow-up questions. Only a column summary is ever sent;
  `anonymize = TRUE` hides column names and `dry_run = TRUE` shows exactly
  what would be sent. Scripts can be refined (`mv_ask(scr, "use a 3PL
  instead")`) and are built from an analysis plan (`mv_plan()`): data
  preparation, model fitting or selection, fit checks, DIF, scores,
  graphics, item cards, reports and response times. `run_script()` runs
  it, optionally after a dry run on simulated data with the same
  structure, and `save_script()` writes it to a file. `profile_data()`
  shows the column summary that is the only information shared with an AI
  model. The workbench now writes its code with the same templates.

* `mv_ask()` reads plans from local models that write text before the JSON
  (such as Qwen on Ollama), and accepts a plan with no extra steps (for
  example DIF requested without a grouping variable), instead of falling back
  to the keyword parser.

* The internal request benchmark (`mirtverse:::ask_benchmark()`) no longer
  stops when a provider cannot be reached; those requests are scored as
  wrong and the reason is printed.

* New article, "mv_ask(): from a sentence to a tested R script", shows the
  workflow and benchmarks Claude, GPT and local Qwen models against the
  keyword parser.

## Differential item functioning

* New `dif()` tests every item for differential item functioning between
  groups in one call, with likelihood-ratio tests, adjusted p-values and
  expected-score effect sizes. `gg_dif()` plots the effects or the item curves
  by group, `interpret()` describes the results, and `mv_report(dif = )` adds a
  DIF section to the report.

## Response times

* `fit_rt()` gains the normative threshold rules `flag_method = "nt15"` and
  `"nt20"` for rapid guessing (15% and 20% of each item's mean response time),
  next to `"nt10"`, and the workbench offers all three. Following Wise and Ma
  (2012), the item thresholds of all three rules are now capped at 10 seconds;
  change the cap with the new `nt_max` argument (`nt_max = Inf` removes it).
  The thresholds used are returned in `$thresholds`.

* `fit_rt()` no longer fails when some persons have no item responses. mirt
  drops those rows from the fitted data; `fit_rt()` now keeps them, and their
  response times still inform speed.

## Other changes

* The package website moved to <https://www.okanbulut.com/mirtverse/>.

* mirtverse can be cited through its Zenodo DOI; see `citation("mirtverse")`
  or `CITATION.cff`.

* "Get started" gains sections on dashboards, `mv_ask()` and the teaching
  labs, and the workbench article covers the NT10, NT15 and NT20 rules.

# mirtverse 0.1.0

First release.

* `launch_workbench()`: a seven-step Shiny app that writes reproducible R code.
* `select_model()`: compares candidate IRT models and explains the recommendation.
* `interpret()` and `interpret_prompt()`: plain-language summaries of mirt results.
* `tidy()`, `glance()`, `augment()` and `item_table()` for mirt models.
* ggplot2 graphics: `gg_trace()`, `gg_info()`, `gg_wright()`, `gg_itemfit()`,
  `gg_q3()`, `gg_scores()`, `gg_empirical()` and `autoplot()`.
* `item_card()` and `item_cards()`: item health cards with a traffic-light status.
* `mv_report()`: a self-contained HTML report.
* `fit_rt()` and `sim_rt()`: joint modelling of responses and response times with
  rapid-guessing flags, response time effort and l_t person fit.
