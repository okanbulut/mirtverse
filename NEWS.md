# mirtverse (development version)

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
