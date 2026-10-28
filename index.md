# mirtverse

**mirtverse** is a friendly workflow and reporting layer for the
[mirt](https://philchalmers.github.io/mirt/) package. mirt estimates
item response theory (IRT) models; mirtverse helps you choose a model,
understand the results, make publication-ready figures, and share
everything, with or without writing R code.

## What it adds

| Feature | Functions |
|----|----|
| Point-and-click workbench with R code export | [`launch_workbench()`](https://okanbulut.github.io/mirtverse/reference/launch_workbench.md) |
| Model selection assistant | [`select_model()`](https://okanbulut.github.io/mirtverse/reference/select_model.md) |
| Plain-language interpretation | [`interpret()`](https://okanbulut.github.io/mirtverse/reference/interpret.md), [`interpret_prompt()`](https://okanbulut.github.io/mirtverse/reference/interpret_prompt.md) |
| Tidy outputs | [`tidy()`](https://generics.r-lib.org/reference/tidy.html), [`glance()`](https://generics.r-lib.org/reference/glance.html), [`augment()`](https://generics.r-lib.org/reference/augment.html), [`item_table()`](https://okanbulut.github.io/mirtverse/reference/item_table.md) |
| ggplot2 graphics, including Wright maps | [`gg_trace()`](https://okanbulut.github.io/mirtverse/reference/gg_trace.md), [`gg_info()`](https://okanbulut.github.io/mirtverse/reference/gg_info.md), [`gg_wright()`](https://okanbulut.github.io/mirtverse/reference/gg_wright.md), [`gg_itemfit()`](https://okanbulut.github.io/mirtverse/reference/gg_itemfit.md), [`gg_q3()`](https://okanbulut.github.io/mirtverse/reference/gg_q3.md), [`gg_scores()`](https://okanbulut.github.io/mirtverse/reference/gg_scores.md), [`gg_empirical()`](https://okanbulut.github.io/mirtverse/reference/gg_empirical.md), [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html) |
| Item health cards | [`item_card()`](https://okanbulut.github.io/mirtverse/reference/item_card.md), [`item_cards()`](https://okanbulut.github.io/mirtverse/reference/item_cards.md) |
| One-call HTML report | [`mv_report()`](https://okanbulut.github.io/mirtverse/reference/mv_report.md) |
| Response-time modelling and rapid-guessing detection | [`fit_rt()`](https://okanbulut.github.io/mirtverse/reference/fit_rt.md), [`sim_rt()`](https://okanbulut.github.io/mirtverse/reference/sim_rt.md) |

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
[`launch_workbench()`](https://okanbulut.github.io/mirtverse/reference/launch_workbench.md).

## Response times

``` r

sim <- sim_rt(N = 1500, J = 20, rapid = 0.08, seed = 1)
mod <- mirt(sim$responses, 1)
fit <- fit_rt(mod, sim$rt)   # van der Linden (2007) hierarchical model
interpret(fit)               # speed-ability relation, rapid guessing, effort
```

## Relationship to mirt

mirtverse depends on mirt and never changes how models are estimated.
Every function accepts a model created with
[`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html),
so you can move between the two packages at any point. Please cite mirt
(Chalmers, 2012) whenever you use mirtverse.

Chalmers, R. P. (2012). mirt: A multidimensional item response theory
package for the R environment. *Journal of Statistical Software, 48*(6),
1-29.
