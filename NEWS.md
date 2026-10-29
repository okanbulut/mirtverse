# mirtverse (development version)

* `fit_rt()` gains the normative threshold rules `flag_method = "nt15"` and
  `"nt20"` for rapid guessing (15% and 20% of each item's mean response time),
  next to `"nt10"`, and the workbench offers all three. Following Wise and Ma
  (2012), the item thresholds of all three rules are now capped at 10 seconds;
  change the cap with the new `nt_max` argument (`nt_max = Inf` removes it).
  The thresholds used are returned in `$thresholds`.
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
