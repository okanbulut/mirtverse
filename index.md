# mirtverse

**mirtverse** is a friendly workflow and reporting layer for the
[mirt](https://philchalmers.github.io/mirt/) package. mirt estimates
item response theory (IRT) models; mirtverse helps you choose a model,
understand the results, make publication-ready figures, and share
everything, with or without writing R code.

## About mirt

[mirt](https://philchalmers.github.io/mirt/), developed and maintained
by [Dr. R. Philip Chalmers](https://chalmers.info.yorku.ca/), is one of
the most comprehensive open-source packages for item response theory. It
was introduced in the *Journal of Statistical Software* ([Chalmers,
2012](https://doi.org/10.18637/jss.v048.i06)) and has been developed
continuously since, with version 1.48 released on CRAN in October 2026.
It is widely used in research on educational and psychological
measurement.

mirt can:

- **Estimate a wide range of models:** unidimensional and
  multidimensional, exploratory and confirmatory, bifactor and two-tier,
  with more than 30 item types (Rasch, 2PL to 4PL, graded response,
  (generalized) partial credit, nominal, ideal-point, nonparametric
  spline items and more), plus user-defined items.
- **Handle complex designs:** multiple-group analysis and measurement
  invariance, mixed-effects and explanatory IRT
  ([`mixedmirt()`](https://philchalmers.github.io/mirt/reference/mixedmirt.html)),
  and latent class and diagnostic classification models
  ([`mdirt()`](https://philchalmers.github.io/mirt/reference/mdirt.html)).
- **Use several estimation engines:** EM with fixed or quasi-Monte Carlo
  quadrature, and the Metropolis-Hastings Robbins-Monro (MHRM) algorithm
  for high-dimensional models, with several standard-error methods.
- **Check and use the models:** item and person fit, limited-information
  fit (M2), local dependence, DIF and differential test functioning, and
  ability estimation (EAP, MAP, ML, WLE, plausible values).

mirtverse leaves all of this untouched and adds the workflow,
interpretation and reporting tools around it.

## What it adds

| Feature | Functions |
|----|----|
| Point-and-click workbench with R code export | [`launch_workbench()`](https://www.okanbulut.com/mirtverse/reference/launch_workbench.md) |
| Model selection assistant | [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md) |
| Plain-language interpretation | [`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md), [`interpret_prompt()`](https://www.okanbulut.com/mirtverse/reference/interpret_prompt.md) |
| Tidy outputs | [`tidy()`](https://generics.r-lib.org/reference/tidy.html), [`glance()`](https://generics.r-lib.org/reference/glance.html), [`augment()`](https://generics.r-lib.org/reference/augment.html), [`item_table()`](https://www.okanbulut.com/mirtverse/reference/item_table.md) |
| ggplot2 graphics, including Wright maps | [`gg_trace()`](https://www.okanbulut.com/mirtverse/reference/gg_trace.md), [`gg_info()`](https://www.okanbulut.com/mirtverse/reference/gg_info.md), [`gg_wright()`](https://www.okanbulut.com/mirtverse/reference/gg_wright.md), [`gg_itemfit()`](https://www.okanbulut.com/mirtverse/reference/gg_itemfit.md), [`gg_q3()`](https://www.okanbulut.com/mirtverse/reference/gg_q3.md), [`gg_scores()`](https://www.okanbulut.com/mirtverse/reference/gg_scores.md), [`gg_empirical()`](https://www.okanbulut.com/mirtverse/reference/gg_empirical.md), [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html) |
| Item health cards | [`item_card()`](https://www.okanbulut.com/mirtverse/reference/item_card.md), [`item_cards()`](https://www.okanbulut.com/mirtverse/reference/item_cards.md) |
| One-call HTML report | [`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md) |
| Response-time modelling and rapid-guessing detection | [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md), [`sim_rt()`](https://www.okanbulut.com/mirtverse/reference/sim_rt.md) |

## Installation

``` r

# install.packages("remotes")
remotes::install_github("okanbulut/mirtverse")
```

## A five-minute tour

``` r

library(mirtverse)

data <- expand.table(LSAT7)

sel <- select_model(data)   # compares Rasch, 2PL and 3PL and recommends one
mod <- sel$best             # an ordinary mirt model

interpret(mod)              # what the results mean, in plain language
tidy(mod)                   # parameters as a data frame
item_table(mod)             # item statistics, fit and flags in one table

gg_wright(mod)              # person-item map
item_card(mod, "Item.2")    # one-page item review

mv_report(sel, file = "report.html")   # everything in one HTML file
```

Prefer clicking? Run
[`launch_workbench()`](https://www.okanbulut.com/mirtverse/reference/launch_workbench.md).

## Relationship to mirt

**mirtverse depends on mirt and never changes how models are
estimated**. Every function accepts a model created with
[`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html),
so you can move between the two packages at any point. Please cite mirt
(Chalmers, 2012) whenever you use mirtverse.

Chalmers, R. P. (2012). mirt: A multidimensional item response theory
package for the R environment. *Journal of Statistical Software, 48*(6),
1-29. <https://doi.org/10.18637/jss.v048.i06>

## Citation

If you use mirtverse, please cite it together with mirt. Run
`citation("mirtverse")` in R, or use:

Bulut, O. (2026). *mirtverse: A friendly workflow and reporting layer
for ‘mirt’* (Version 0.1.0) \[R package\]. Zenodo.
<https://doi.org/10.5281/zenodo.23719385>
