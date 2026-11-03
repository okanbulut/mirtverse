# Start here: New to R

You do not need to know R to use mirtverse. You need to install it once
and type one line; after that, you can work with buttons or plain
language.

Watch the workbench in action first (about 90 seconds, with captions):

# An error occurred.

Unable to execute JavaScript.

## Try it before you install anything

[Open the live example
dashboard](https://www.okanbulut.com/mirtverse/dashboard/sat12-demo.md).
It shows the results for a 32-item test: Which items work, which need
review, and how scores are distributed. It runs in your browser, and you
can make one like it for your own test.

## Your path in three steps

**1. Install R, RStudio and mirtverse (once, about 10 minutes).**

- Install R from [CRAN](https://cloud.r-project.org/) and [RStudio
  Desktop](https://posit.co/download/rstudio-desktop/), both free.
- Open RStudio and paste this line into the Console (bottom left), then
  press Enter:

``` r

install.packages("mirtverse", repos = c("https://okanbulut.r-universe.dev", "https://cloud.r-project.org"))
```

**2. Open the workbench.** Paste these two lines:

``` r

library(mirtverse)
launch_workbench()
```

A window opens with eight steps: Load your data (CSV, Excel, SPSS),
choose a model, check items, score people and download a report. The
[workbench
guide](https://www.okanbulut.com/mirtverse/articles/workbench.md) walks
through each step.

**3. Or describe what you want in words.**
[`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
writes the analysis for you, and you can read it before it runs:

``` r

mv_ask("fit a Rasch model, check item fit and make a report", data = mydata)
```

It works offline for common analyses; see the
[guide](https://www.okanbulut.com/mirtverse/articles/mv-ask-guide.md).

## Coming from other software?

- **Winsteps or other Rasch software:** The workbench fits the Rasch
  model, item fit and a Wright map, and writes the R code so you can see
  the equivalent of each step.
- **SPSS or Excel:** Load your `.sav`, `.xlsx` or `.csv` file directly
  in the workbench.
- **ltm, eRm, TAM or irtQ in R:**
  [`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md)
  translates your code; see [Moving to
  mirt](https://www.okanbulut.com/mirtverse/articles/mirtify.md).

## Words you will see

The [glossary](https://www.okanbulut.com/mirtverse/articles/glossary.md)
explains each term (discrimination, information, DIF and so on) in plain
language.
