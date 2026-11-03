# mirtverse <img src="man/figures/logo.png" align="right" height="139" alt="mirtverse hex logo" />

<!-- badges: start -->
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23719384.svg)](https://doi.org/10.5281/zenodo.23719384)
[![R-CMD-check](https://github.com/okanbulut/mirtverse/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/okanbulut/mirtverse/actions/workflows/R-CMD-check.yaml)
[![r-universe](https://okanbulut.r-universe.dev/badges/mirtverse)](https://okanbulut.r-universe.dev/mirtverse)
<!-- badges: end -->


**From item responses to defensible decisions, with or without writing R code.**

**mirtverse** is a friendly workflow and reporting layer for the
[mirt](https://philchalmers.github.io/mirt/) package by R. Philip Chalmers.
mirt estimates item response theory (IRT) models; mirtverse helps you choose a
model, understand the results, make publication-ready figures, and share
everything with people who never open R.

<img src="man/figures/home-workflow.svg" width="100%" alt="The mirtverse workflow in four steps: Bring your data, fit and choose a model, understand the results, share and decide">

**Try it without installing anything:** [Open the live example dashboard](https://www.okanbulut.com/mirtverse/dashboard/sat12-demo.html)
or browse the [Gallery](https://www.okanbulut.com/mirtverse/articles/gallery.html) of figures and outputs.

<a href="https://www.okanbulut.com/mirtverse/articles/gallery.html"><img src="man/figures/home-showcase.png" width="100%" alt="Four mirtverse outputs: A results dashboard, an item health card, a Wright map and a DIF plot"></a>

<a href="https://www.okanbulut.com/mirtverse/articles/ai-hub.html"><img src="man/figures/home-ai.svg" width="100%" alt="Animated: Item text and responses flow through a neural network and come out as a calibrated item characteristic curve"></a>

> **New: AI in measurement hub.** A home for psychometricians who want to
> learn AI in their own terms: Six book chapters (machine learning through an
> IRT lens, item text and difficulty, automatic item generation, automated
> scoring, large language models, and validity and fairness), four labs, a
> one-day workshop kit, and tools to audit AI components. Replay mode runs
> the examples offline, with no API key.
> [Start here](https://www.okanbulut.com/mirtverse/articles/ai-hub.html).

## Find your way in

| I am... | Start here |
|---|---|
| A student learning IRT or analysing thesis data | [Start here: Students](https://www.okanbulut.com/mirtverse/articles/for-students.html) · [Thesis kit](https://www.okanbulut.com/mirtverse/articles/thesis-kit.html) |
| An instructor teaching measurement (book, ten labs, sample syllabus) | [Start here: Instructors](https://www.okanbulut.com/mirtverse/articles/for-instructors.html) |
| A psychometrician at a testing or credentialing program | [Start here: Testing programs](https://www.okanbulut.com/mirtverse/articles/for-practitioners.html) · [Case study](https://www.okanbulut.com/mirtverse/articles/case-study.html) |
| A researcher who already uses mirt | [Start here: Researchers](https://www.okanbulut.com/mirtverse/articles/for-researchers.html) |
| New to R, or coming from Winsteps, SPSS or Excel | [Start here: New to R](https://www.okanbulut.com/mirtverse/articles/for-new-to-r.html) |
| Curious about AI in measurement | [AI Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.html) |

## Quick start

```r
install.packages("mirtverse", repos = c("https://okanbulut.r-universe.dev", "https://cloud.r-project.org"))

library(mirtverse)
launch_workbench()        # point and click, with R code written for you
```

> **How to cite:** Please cite mirtverse together with mirt. Package:
> Bulut (2026), [doi:10.5281/zenodo.23719384](https://doi.org/10.5281/zenodo.23719384).
> Book: [doi:10.5281/zenodo.23885605](https://doi.org/10.5281/zenodo.23885605).
> mirt: Chalmers (2012), [doi:10.18637/jss.v048.i06](https://doi.org/10.18637/jss.v048.i06).
> Full references are under [Citation](#citation).

## What mirtverse adds

| Feature | Functions |
|---|---|
| Point-and-click workbench with R code export | `launch_workbench()` |
| Analysis scripts written from a plain-language request | `mv_ask()`, `mv_ask_setup()`, `run_script()` |
| Model selection assistant | `select_model()` |
| Differential item functioning in one call | `dif()`, `gg_dif()` |
| Plain-language interpretation | `interpret()`, `interpret_prompt()` |
| APA Methods paragraph with references, for theses and papers | `cite_methods()` |
| Tidy outputs | `tidy()`, `glance()`, `augment()`, `item_table()` |
| ggplot2 graphics, including Wright maps | `gg_trace()`, `gg_info()`, `gg_wright()`, `gg_itemfit()`, `gg_q3()`, `gg_scores()`, `gg_empirical()`, `autoplot()` |
| Item health cards | `item_card()`, `item_cards()` |
| One-call HTML report | `mv_report()` |
| Results dashboard to share with non-R users, as a Shiny app or one offline HTML file | `mv_dashboard()`, `export_dashboard()` |
| Response-time modelling and rapid-guessing detection | `fit_rt()`, `sim_rt()` |
| Interactive teaching labs for measurement courses (learnr) | `run_lab()`, `list_labs()` |
| Instructor toolkit: Labs on your own data, editable labs and chapters | `new_course()`, `new_lab()`, `swap_lab_data()`, `check_material()` |
| Translate ltm, eRm, TAM and irtQ code into mirt code | `mirtify()`, `mirtify_crosswalk()` |
| Let Claude or an OpenAI assistant revise and adapt your teaching materials (MCP server) | `mv_mcp_server()`, `mv_mcp_config()` |

## Installation

Install a prebuilt version from r-universe (no Rtools or GitHub token needed):

```r
install.packages("mirtverse", repos = c("https://okanbulut.r-universe.dev", "https://cloud.r-project.org"))
```

Or install the development version from GitHub:

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
mv_dashboard(mod, title = "LSAT results")   # interactive dashboard to share
```

Prefer clicking? Run `launch_workbench()`. Prefer describing the analysis in
words? `mv_ask("fit a 2PL, check DIF by gender and make a report", data = mydata)`
writes the whole script for you.

Teaching a measurement course? `run_lab("model-choice")` opens an interactive
lab in which students work through a realistic testing scenario with live
models; there are ten labs (see [Teaching labs](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html)).
The online book [*Item Response Theory with mirt and
mirtverse*](https://www.okanbulut.com/mirtverse/book/) gives extended notes for
each week of a course, with worked examples and exercises. It is also
available as a PDF and EPUB and can be cited with its own DOI,
[10.5281/zenodo.23885605](https://doi.org/10.5281/zenodo.23885605).
To teach with your own data, `new_lab()` builds a lab on any response
dataset (see [The instructor toolkit](https://www.okanbulut.com/mirtverse/articles/instructor-toolkit.html)).

## About mirt

[mirt](https://philchalmers.github.io/mirt/), developed and maintained by
[Dr. R. Philip Chalmers](https://chalmers.info.yorku.ca/), is one of the most comprehensive open-source packages for item
response theory. It was introduced in the *Journal of Statistical Software*
([Chalmers, 2012](https://doi.org/10.18637/jss.v048.i06)) and has been developed continuously since, with version 1.48
released on CRAN in October 2026. It is widely used in research on educational
and psychological measurement.

mirt can:

- **Estimate a wide range of models:** Unidimensional and multidimensional,
  exploratory and confirmatory, bifactor and two-tier, with more than 30 item types
  (Rasch, 2PL to 4PL, graded response, (generalized) partial credit, nominal,
  ideal-point, nonparametric spline items and more), plus user-defined items.
- **Handle complex designs:** Multiple-group analysis and measurement invariance,
  mixed-effects and explanatory IRT (`mixedmirt()`), and latent class and
  diagnostic classification models (`mdirt()`).
- **Use several estimation engines:** EM with fixed or quasi-Monte Carlo
  quadrature, and the Metropolis-Hastings Robbins-Monro (MHRM) algorithm for
  high-dimensional models, with several standard-error methods.
- **Check and use the models:** Item and person fit, limited-information fit (M2),
  local dependence, DIF and differential test functioning, and ability estimation
  (EAP, MAP, ML, WLE, plausible values).

mirtverse leaves all of this untouched and adds the workflow, interpretation and
reporting tools around it.

## Cheat sheet

<a href="https://www.okanbulut.com/mirtverse/cheatsheet/mirtverse-cheatsheet.pdf"><img src="https://www.okanbulut.com/mirtverse/cheatsheet/mirtverse-cheatsheet-1.png" width="49%" alt="Page 1 of the mirtverse cheat sheet"></a> <a href="https://www.okanbulut.com/mirtverse/cheatsheet/mirtverse-cheatsheet.pdf"><img src="https://www.okanbulut.com/mirtverse/cheatsheet/mirtverse-cheatsheet-2.png" width="49%" alt="Page 2 of the mirtverse cheat sheet"></a>

A printable two-page [cheat sheet (PDF)](https://www.okanbulut.com/mirtverse/cheatsheet/mirtverse-cheatsheet.pdf)
covers the main functions by task: Page 1 for analysis and sharing, page 2 for
the assessment pipeline.

## Coming from ltm, eRm, TAM or irtQ?

`mirtify()` rewrites code written for these packages as mirt code, without
running the original, and adds a comment wherever the packages differ (for
example, conditional versus marginal likelihood in eRm, or the scaling
constant `D = 1.702` in irtQ):

```r
mirtify({
  library(eRm)
  fit <- RM(raschdat1)
  pp <- person.parameter(fit)
  itemfit(pp)
  LRtest(fit)
})
```

It translates the model calls and the usual next steps (scores, item and
person fit, plots, Andersen's LR test), and `run = TRUE` also runs the result.
In the package tests, most translated models reproduce the original estimates
to within about 0.006. `mirtify_crosswalk()` lists every supported function.
See [Moving from ltm, eRm, TAM or irtQ to mirt](https://www.okanbulut.com/mirtverse/articles/mirtify.html).

## Relationship to mirt

**mirtverse depends on mirt and never changes how models are estimated**. Every
function accepts a model created with `mirt::mirt()`, so you can move between the
two packages at any point. Please cite mirt (Chalmers, 2012) whenever you use
mirtverse.

Chalmers, R. P. (2012). mirt: A multidimensional item response theory package for the
R environment. *Journal of Statistical Software, 48*(6), 1-29. <https://doi.org/10.18637/jss.v048.i06>

## Citation

If you use mirtverse, please cite it together with mirt. Run `citation("mirtverse")` in R, or use:

Bulut, O. (2026). *mirtverse: A friendly workflow and reporting layer for 'mirt'* (Version 0.2.0) [R package]. Zenodo. https://doi.org/10.5281/zenodo.23836292

To cite all versions, use <https://doi.org/10.5281/zenodo.23719384>, which always resolves to the latest release.
