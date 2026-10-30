# Changelog

## mirtverse (development version)

- New interactive teaching labs for measurement courses, built with
  learnr. `run_lab("model-choice")` opens Lab 1, “Choosing a model the
  board can defend”: students score a certification exam, find a
  miskeyed item, check dimensionality, compare the Rasch, 2PL and 3PL
  models, check item fit and local dependence, and justify a model, with
  feedback on every decision and a summary of their choices at the end.
  `run_lab("decisions")` opens Lab 2, “From parameters to decisions”:
  reading item parameters, precision at the pass mark, choosing a
  scoring method, classification accuracy, DIF between English and
  French candidates, a memo to the board, and a reveal of the truth
  behind the data.
  [`list_labs()`](https://www.okanbulut.com/mirtverse/reference/run_lab.md)
  lists the labs. The new `certexam` data (with `certexam_key`) are
  simulated with known problems planted for the labs;
  [`lab_truth()`](https://www.okanbulut.com/mirtverse/reference/lab_truth.md)
  reveals them for instructors. The new “Learn IRT by doing” article
  introduces the labs, and the “Teaching labs” article is an instructor
  guide with an answer key.
- [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md)
  gains the normative threshold rules `flag_method = "nt15"` and
  `"nt20"` for rapid guessing (15% and 20% of each item’s mean response
  time), next to `"nt10"`, and the workbench offers all three. Following
  Wise and Ma (2012), the item thresholds of all three rules are now
  capped at 10 seconds; change the cap with the new `nt_max` argument
  (`nt_max = Inf` removes it). The thresholds used are returned in
  `$thresholds`.
- New
  [`mv_dashboard()`](https://www.okanbulut.com/mirtverse/reference/mv_dashboard.md)
  builds a read-only ‘shiny’ dashboard of your results for people who do
  not use R. Choose the panels (summary, items with health cards, item
  curves with an ability slider, information, Wright map, score
  distribution and conversion table, and optionally person scores, DIF
  and response times), add a title and logo, and run it.
  [`export_dashboard()`](https://www.okanbulut.com/mirtverse/reference/export_dashboard.md)
  saves it as an `app.R` folder ready for shinyapps.io or Posit Connect.
  The saved dashboard holds summaries only, never the item responses,
  and holds individual scores only when you add the `"persons"` panel.
- `export_dashboard(format = "html")` saves the dashboard as one
  self-contained HTML file that needs no server, no R and no internet
  connection. The item table, item curves with the ability slider, item
  information and person lookup stay interactive.
- New
  [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
  writes a complete, commented analysis script from a plain-language
  request such as “fit a 2PL, check DIF by gender and make a report”.
  Requests are understood by Claude, OpenAI GPT or a local Ollama model
  (set up once with
  [`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md)),
  or offline by a built-in keyword parser that asks follow-up questions.
  Only a column summary is ever sent; `anonymize = TRUE` hides column
  names and `dry_run = TRUE` shows exactly what would be sent. Scripts
  can be refined (`mv_ask(scr, "use a 3PL instead")`) and are built from
  an analysis plan
  ([`mv_plan()`](https://www.okanbulut.com/mirtverse/reference/mv_plan.md)):
  data preparation, model fitting or selection, fit checks, DIF, scores,
  graphics, item cards, reports and response times.
  [`run_script()`](https://www.okanbulut.com/mirtverse/reference/run_script.md)
  runs it, optionally after a dry run on simulated data with the same
  structure, and
  [`save_script()`](https://www.okanbulut.com/mirtverse/reference/run_script.md)
  writes it to a file.
  [`profile_data()`](https://www.okanbulut.com/mirtverse/reference/profile_data.md)
  shows the column summary that is the only information shared with an
  AI model. The workbench now writes its code with the same templates.
- New [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md)
  tests every item for differential item functioning between groups in
  one call, with likelihood-ratio tests, adjusted p-values and
  expected-score effect sizes.
  [`gg_dif()`](https://www.okanbulut.com/mirtverse/reference/gg_dif.md)
  plots the effects or the item curves by group,
  [`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md)
  describes the results, and `mv_report(dif = )` adds a DIF section to
  the report.
- [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md)
  no longer fails when some persons have no item responses. mirt drops
  those rows from the fitted data;
  [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md)
  now keeps them, and their response times still inform speed.

## mirtverse 0.1.0

First release.

- [`launch_workbench()`](https://www.okanbulut.com/mirtverse/reference/launch_workbench.md):
  a seven-step Shiny app that writes reproducible R code.
- [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md):
  compares candidate IRT models and explains the recommendation.
- [`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md)
  and
  [`interpret_prompt()`](https://www.okanbulut.com/mirtverse/reference/interpret_prompt.md):
  plain-language summaries of mirt results.
- [`tidy()`](https://generics.r-lib.org/reference/tidy.html),
  [`glance()`](https://generics.r-lib.org/reference/glance.html),
  [`augment()`](https://generics.r-lib.org/reference/augment.html) and
  [`item_table()`](https://www.okanbulut.com/mirtverse/reference/item_table.md)
  for mirt models.
- ggplot2 graphics:
  [`gg_trace()`](https://www.okanbulut.com/mirtverse/reference/gg_trace.md),
  [`gg_info()`](https://www.okanbulut.com/mirtverse/reference/gg_info.md),
  [`gg_wright()`](https://www.okanbulut.com/mirtverse/reference/gg_wright.md),
  [`gg_itemfit()`](https://www.okanbulut.com/mirtverse/reference/gg_itemfit.md),
  [`gg_q3()`](https://www.okanbulut.com/mirtverse/reference/gg_q3.md),
  [`gg_scores()`](https://www.okanbulut.com/mirtverse/reference/gg_scores.md),
  [`gg_empirical()`](https://www.okanbulut.com/mirtverse/reference/gg_empirical.md)
  and
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html).
- [`item_card()`](https://www.okanbulut.com/mirtverse/reference/item_card.md)
  and
  [`item_cards()`](https://www.okanbulut.com/mirtverse/reference/item_cards.md):
  item health cards with a traffic-light status.
- [`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md):
  a self-contained HTML report.
- [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md)
  and
  [`sim_rt()`](https://www.okanbulut.com/mirtverse/reference/sim_rt.md):
  joint modelling of responses and response times with rapid-guessing
  flags, response time effort and l_t person fit.
