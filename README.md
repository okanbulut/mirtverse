# mirtverse <img src="man/figures/logo.png" align="right" height="139" alt="mirtverse hex logo" />

<!-- badges: start -->
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23719385.svg)](https://doi.org/10.5281/zenodo.23719385)
[![R-CMD-check](https://github.com/okanbulut/mirtverse/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/okanbulut/mirtverse/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**mirtverse** is a friendly workflow and reporting layer for the
[mirt](https://philchalmers.github.io/mirt/) package. mirt estimates item response
theory (IRT) models; mirtverse helps you choose a model, understand the results,
make publication-ready figures, and share everything, with or without writing R code.

## About mirt

[mirt](https://philchalmers.github.io/mirt/), developed and maintained by
[Dr. R. Philip Chalmers](https://chalmers.info.yorku.ca/), is one of the most comprehensive open-source packages for item
response theory. It was introduced in the *Journal of Statistical Software*
([Chalmers, 2012](https://doi.org/10.18637/jss.v048.i06)) and has been developed continuously since, with version 1.48
released on CRAN in October 2026. It is widely used in research on educational
and psychological measurement.

mirt can:

- **Estimate a wide range of models:** unidimensional and multidimensional,
  exploratory and confirmatory, bifactor and two-tier, with more than 30 item types
  (Rasch, 2PL to 4PL, graded response, (generalized) partial credit, nominal,
  ideal-point, nonparametric spline items and more), plus user-defined items.
- **Handle complex designs:** multiple-group analysis and measurement invariance,
  mixed-effects and explanatory IRT (`mixedmirt()`), and latent class and
  diagnostic classification models (`mdirt()`).
- **Use several estimation engines:** EM with fixed or quasi-Monte Carlo
  quadrature, and the Metropolis-Hastings Robbins-Monro (MHRM) algorithm for
  high-dimensional models, with several standard-error methods.
- **Check and use the models:** item and person fit, limited-information fit (M2),
  local dependence, DIF and differential test functioning, and ability estimation
  (EAP, MAP, ML, WLE, plausible values).

mirtverse leaves all of this untouched and adds the workflow, interpretation and
reporting tools around it.

## What it adds

| Feature | Functions |
|---|---|
| Point-and-click workbench with R code export | `launch_workbench()` |
| Model selection assistant | `select_model()` |
| Plain-language interpretation | `interpret()`, `interpret_prompt()` |
| Tidy outputs | `tidy()`, `glance()`, `augment()`, `item_table()` |
| ggplot2 graphics, including Wright maps | `gg_trace()`, `gg_info()`, `gg_wright()`, `gg_itemfit()`, `gg_q3()`, `gg_scores()`, `gg_empirical()`, `autoplot()` |
| Item health cards | `item_card()`, `item_cards()` |
| One-call HTML report | `mv_report()` |
| Response-time modelling and rapid-guessing detection | `fit_rt()`, `sim_rt()` |

## Installation

```r
# install.packages("remotes")
remotes::install_github("okanbulut/mirtverse")
```

## A five-minute tour

```r
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

Prefer clicking? Run `launch_workbench()`.


## Relationship to mirt

**mirtverse depends on mirt and never changes how models are estimated**. Every
function accepts a model created with `mirt::mirt()`, so you can move between the
two packages at any point. Please cite mirt (Chalmers, 2012) whenever you use
mirtverse.

Chalmers, R. P. (2012). mirt: A multidimensional item response theory package for the
R environment. *Journal of Statistical Software, 48*(6), 1-29. <https://doi.org/10.18637/jss.v048.i06>

## Citation

If you use mirtverse, please cite it together with mirt. Run `citation("mirtverse")` in R, or use:

Bulut, O. (2026). *mirtverse: A friendly workflow and reporting layer for 'mirt'* (Version 0.1.0) [R package]. Zenodo. https://doi.org/10.5281/zenodo.23719385
