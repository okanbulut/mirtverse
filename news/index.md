# Changelog

## mirtverse (development version)

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
