# Changelog

## mirtverse (development version)

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
