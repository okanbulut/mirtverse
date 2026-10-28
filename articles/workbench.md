# The mirtverse workbench

The workbench is a point-and-click app for people who would rather not
write R code. It runs the same functions you would call yourself, and it
writes the R code for everything you do, so you can rerun the analysis
later or learn R along the way.

``` r

library(mirtverse)
launch_workbench()

# or start with your own data already loaded
launch_workbench(my_data)
```

## The seven steps

| Tab | What you do |
|----|----|
| 1\. Data | Pick an example dataset or upload CSV, Excel, SPSS, Stata or RDS. Choose the item columns, enter an answer key to score multiple-choice items, and declare missing-value codes. |
| 2\. Explore | Classical item statistics, Cronbach’s alpha and the total-score distribution. |
| 3\. Model | Let mirtverse compare models and recommend one, or choose the item type and number of dimensions yourself. |
| 4\. Results | Plain-language interpretation, item table with flags, parameters, all graphics, and item health cards. |
| 5\. Scores | Person scores (EAP, MAP, ML or WLE) with standard errors, a CSV download, and the sum-score conversion table. |
| 6\. Response times | Upload response times to fit the joint model and flag rapid guessing. |
| 7\. Report & code | Download the HTML report and the R script that reproduces the analysis. |

## Sharing the app

The workbench is an ordinary Shiny app. To host it for colleagues or
students, put this in an `app.R` file and deploy it to shinyapps.io or
Posit Connect:

``` r

library(mirtverse)
workbench_app()
```
