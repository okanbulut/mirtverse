# mirtverse

**From item responses to defensible decisions, with or without writing R
code.**

**mirtverse** is a friendly workflow and reporting layer for the
[mirt](https://philchalmers.github.io/mirt/) package by R. Philip
Chalmers. mirt estimates item response theory (IRT) models; mirtverse
helps you choose a model, understand the results, make publication-ready
figures, and share everything with people who never open R.

![The mirtverse workflow in four steps: Bring your data, fit and choose
a model, understand the results, share and
decide](reference/figures/home-workflow.svg)

[![Four mirtverse outputs: A results dashboard, an item health card, a
Wright map and a DIF
plot](reference/figures/home-showcase.png)](https://www.okanbulut.com/mirtverse/articles/gallery.html)

**Try it without installing anything:** [Open the live example
dashboard](https://www.okanbulut.com/mirtverse/dashboard/sat12-demo.html)
or browse the
[Gallery](https://www.okanbulut.com/mirtverse/articles/gallery.html) of
figures and outputs.

**Or watch a short demo** (about 90 seconds each, with captions):

[![Video: A tour of the point-and-click
workbench](reference/figures/home-video-workbench.png)](https://youtu.be/huSxZzaFNs0)
[![Video: The AI Hub, with automated scoring checked like a
psychometrician
would](reference/figures/home-video-ai-hub.png)](https://youtu.be/4cFjnpSkcMQ)
[![Video: The thesis kit, from a fitted model to an APA Methods
paragraph](reference/figures/home-video-thesis-kit.png)](https://youtu.be/J3us00sk34g)

## Find your way in

| I am… | Start here |
|----|----|
| A student learning IRT or analysing thesis data | [Students](https://www.okanbulut.com/mirtverse/articles/for-students.html) · [Thesis kit](https://www.okanbulut.com/mirtverse/articles/thesis-kit.html) |
| An instructor teaching measurement (book, ten labs, sample syllabus) | [Instructors](https://www.okanbulut.com/mirtverse/articles/for-instructors.html) · [Adopt for your course](https://www.okanbulut.com/mirtverse/articles/adopt.html) |
| A psychometrician at a testing or credentialing program | [Testing programs](https://www.okanbulut.com/mirtverse/articles/for-practitioners.html) · [Case study](https://www.okanbulut.com/mirtverse/articles/case-study.html) |
| A researcher who already uses mirt, ltm, eRm, TAM or irtQ | [Researchers](https://www.okanbulut.com/mirtverse/articles/for-researchers.html) · [Moving to mirt](https://www.okanbulut.com/mirtverse/articles/mirtify.html) |
| New to R, or coming from Winsteps, SPSS or Excel | [New to R](https://www.okanbulut.com/mirtverse/articles/for-new-to-r.html) |
| Curious about AI in measurement | [AI Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.html): Book chapters, labs and a workshop kit |

[![Animated: Item text and responses flow through a neural network and
come out as a calibrated item characteristic
curve](reference/figures/home-ai.svg)](https://www.okanbulut.com/mirtverse/articles/ai-hub.html)

## Get started

``` r

install.packages("mirtverse", repos = c("https://okanbulut.r-universe.dev", "https://cloud.r-project.org"))
# Development version: remotes::install_github("okanbulut/mirtverse")

library(mirtverse)

data <- expand.table(LSAT7)

sel <- select_model(data)   # compares Rasch, 2PL and 3PL and recommends one
mod <- sel$best             # an ordinary mirt model

interpret(mod)              # what the results mean, in plain language
item_table(mod)             # item statistics, fit and flags in one table
gg_wright(mod)              # person-item map
item_card(mod, "Item.2")    # one-page item review

mv_report(sel, file = "report.html")        # everything in one HTML file
mv_dashboard(mod, title = "LSAT results")   # interactive dashboard to share
```

Prefer clicking? Run
[`launch_workbench()`](https://www.okanbulut.com/mirtverse/reference/launch_workbench.md),
which writes the R code for you. Every function is listed in the
[Reference](https://www.okanbulut.com/mirtverse/reference/), and the
[cheat sheet
(PDF)](https://www.okanbulut.com/mirtverse/cheatsheet/mirtverse-cheatsheet.pdf)
groups them by task.

## Beyond the usual IRT toolkit

- **Describe the analysis, get the script.**
  `mv_ask("fit a 2PL, check DIF by gender and make a report", data = mydata)`
  writes a tested R script from one sentence, with Claude, an OpenAI
  model, a local model or an offline parser. [How it
  works](https://www.okanbulut.com/mirtverse/articles/mv-ask-guide.html)
- **Generate items.**
  [`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
  drafts multiple-choice items with keys and open-ended items with
  rubrics from a test blueprint, and
  [`generate_isomorphs()`](https://www.okanbulut.com/mirtverse/reference/generate_isomorphs.md)
  builds item families from an item model. [Book
  chapter](https://www.okanbulut.com/mirtverse/book/aig.html)
- **Score open-ended responses.**
  [`train_scorer()`](https://www.okanbulut.com/mirtverse/reference/train_scorer.md)
  trains a transparent scoring engine that runs offline, and
  [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md)
  scores with it or with a language model, checking agreement with human
  raters before any score is used. [Book
  chapter](https://www.okanbulut.com/mirtverse/book/auto-scoring.html)
- **Run a whole testing program.**
  [`mv_pipeline()`](https://www.okanbulut.com/mirtverse/reference/mv_pipeline.md)
  takes a test from blueprint to bank monitoring in 13 stages, with
  flags that catch problems before the next step. [The
  pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.html)
  · [Case
  study](https://www.okanbulut.com/mirtverse/articles/case-study.html)

## About mirt

[mirt](https://philchalmers.github.io/mirt/), developed and maintained
by [Dr. R. Philip Chalmers](https://chalmers.info.yorku.ca/), is one of
the most comprehensive open-source packages for item response theory. It
estimates unidimensional and multidimensional models with more than 30
item types, multiple-group and mixed-effects models, and latent class
and diagnostic models, with EM and MHRM estimation, fit statistics, DIF
and ability estimation.

**mirtverse depends on mirt and never changes how models are
estimated.** Every function accepts a model created with
[`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html),
so you can move between the two packages at any point.

## Citation

Please cite mirtverse together with mirt. Run `citation("mirtverse")` in
R, or use:

Bulut, O. (2026). *mirtverse: A friendly workflow and reporting layer
for ‘mirt’* (Version 0.2.0) \[R package\]. Zenodo.
<https://doi.org/10.5281/zenodo.23836292>

Chalmers, R. P. (2012). mirt: A multidimensional item response theory
package for the R environment. *Journal of Statistical Software, 48*(6),
1-29. <https://doi.org/10.18637/jss.v048.i06>

To cite all versions of mirtverse, use
<https://doi.org/10.5281/zenodo.23719384>, which always resolves to the
latest release. The online book has its own DOI:
[10.5281/zenodo.23885605](https://doi.org/10.5281/zenodo.23885605).
