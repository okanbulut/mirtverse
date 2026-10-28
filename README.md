# mirtverse

<!-- badges: start -->
<!-- badges: end -->

**mirtverse** is a friendly workflow and reporting layer for the
[mirt](https://philchalmers.github.io/mirt/) package. mirt estimates item response
theory (IRT) models; mirtverse helps you choose a model, understand the results,
make publication-ready figures, and share everything, with or without writing R code.

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

## Response times

```r
sim <- sim_rt(N = 1500, J = 20, rapid = 0.08, seed = 1)
mod <- mirt(sim$responses, 1)
fit <- fit_rt(mod, sim$rt)   # van der Linden (2007) hierarchical model
interpret(fit)               # speed-ability relation, rapid guessing, effort
```

## Relationship to mirt

mirtverse depends on mirt and never changes how models are estimated. Every
function accepts a model created with `mirt::mirt()`, so you can move between the
two packages at any point. Please cite mirt (Chalmers, 2012) whenever you use
mirtverse.

Chalmers, R. P. (2012). mirt: A multidimensional item response theory package for the
R environment. *Journal of Statistical Software, 48*(6), 1-29.
