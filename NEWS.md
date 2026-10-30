# mirtverse (development version)

* Item banks and linking for the assessment pipeline (stage 6). `mv_bank()`
  starts an item bank from a calibrated model or pipeline, `link_to_bank()`
  puts a new calibration on the bank's scale through anchor items
  (Stocking-Lord, Haebara, mean-sigma, mean-mean or fixed-anchor calibration)
  and flags drifting anchors, too few anchors and unusual linking constants,
  and `bank_items()` adds the new items to the bank. The pipeline report gains
  a linking section, and `mv_rules()` gains `min_anchors`,
  `min_anchor_share`, `anchor_displacement`, `link_slope_min` and
  `link_slope_max`.

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

* New `mirtify()` translates code written for ltm, eRm, TAM and irtQ into
  mirt code, with a note on every difference between the packages (for
  example CML versus MML in eRm, the scaling constant `D` in irtQ, and the
  number of quadrature points). It covers the model functions and their
  follow-ups: person scores, item and person fit, information, plots and
  Andersen's likelihood-ratio test. `run = TRUE` also runs the translated
  code. `mirtify_crosswalk()` lists every supported function, and the new
  article "Moving from ltm, eRm, TAM or irtQ to mirt" walks through examples
  and shows how closely the translated models match the originals.
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
  planted for the labs; `lab_truth()` reveals them for instructors. The new
  "Learn IRT by doing" article introduces the labs, and the "Teaching labs"
  article is an instructor guide with an answer key.
* `fit_rt()` gains the normative threshold rules `flag_method = "nt15"` and
  `"nt20"` for rapid guessing (15% and 20% of each item's mean response time),
  next to `"nt10"`, and the workbench offers all three. Following Wise and Ma
  (2012), the item thresholds of all three rules are now capped at 10 seconds;
  change the cap with the new `nt_max` argument (`nt_max = Inf` removes it).
  The thresholds used are returned in `$thresholds`.
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
* New `mv_ask()` writes a complete, commented analysis script from a
  plain-language request such as "fit a 2PL, check DIF by gender and make a
  report". Requests are understood by Claude, OpenAI GPT or a local Ollama
  model (set up once with `mv_ask_setup()`), or offline by a built-in keyword
  parser that asks follow-up questions. Only a column summary is ever sent;
  `anonymize = TRUE` hides column names and `dry_run = TRUE` shows exactly
  what would be sent. Scripts can be refined (`mv_ask(scr, "use a 3PL
  instead")`) and are built from an analysis plan (`mv_plan()`): data preparation, model fitting or selection,
  fit checks, DIF, scores, graphics, item cards, reports and response times.
  `run_script()` runs it, optionally after a dry run on simulated data with the
  same structure, and `save_script()` writes it to a file. `profile_data()`
  shows the column summary that is the only information shared with an AI
  model. The workbench now writes its code with the same templates.
* New `dif()` tests every item for differential item functioning between
  groups in one call, with likelihood-ratio tests, adjusted p-values and
  expected-score effect sizes. `gg_dif()` plots the effects or the item curves
  by group, `interpret()` describes the results, and `mv_report(dif = )` adds a
  DIF section to the report.
* `fit_rt()` no longer fails when some persons have no item responses. mirt
  drops those rows from the fitted data; `fit_rt()` now keeps them, and their
  response times still inform speed.

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
