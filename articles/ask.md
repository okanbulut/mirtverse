# Describe your analysis in words

[`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
writes a complete R script from a plain-language description of the
analysis you want. You check the script, then run it or save it. The
script is ordinary, commented R code, so you can rerun it later, share
it with a colleague, or learn R from it.

``` r

library(mirtverse)
#> Loading required package: mirt
#> Loading required package: stats4
#> Loading required package: lattice
```

## A first request

Here is a small data set: twelve 0/1 items, a gender column and a
student ID.

``` r

set.seed(1)
a <- matrix(rlnorm(12, 0.2, 0.25)); d <- matrix(rnorm(12))
mydata <- data.frame(student_id = 1:800, simdata(a, d, 800, itemtype = "2PL"),
                     gender = rep(c("F", "M"), 400))
names(mydata)[2:13] <- paste0("Q", 1:12)

scr <- mv_ask("Fit a 2PL, check DIF by gender and make a report", data = mydata,
              provider = "none")
scr
#> Request: Fit a 2PL, check DIF by gender and make a report 
#> Understood by the built-in keyword parser
#> 
#> Analysis plan
#>   - Data: mydata 
#>   - Items: 12 items (Q1 ... Q12) 
#>   - Model: 2PL, 1 dimension 
#>   - DIF by: gender 
#>   - Steps: fit, dif, report 
#> Assumptions
#>   - Used the 12 columns that look like item responses as items. 
#> 
#> R script (run it with run_script(), save it with save_script())
#> ----------------------------------------------------------------
#> # Analysis script written by mirtverse::mv_ask()
#> # 2026-10-29 15:53
#> # Request: Fit a 2PL, check DIF by gender and make a report
#> # Assumptions:
#> #  - Used the 12 columns that look like item responses as items.
#> library(mirtverse)
#> 
#> # Data
#> raw <- mydata
#> items <- raw[, c("Q1", "Q2", "Q3", "Q4", "Q5", "Q6", "Q7", "Q8", "Q9", "Q10", "Q11",
#>   "Q12")]
#> group <- raw$gender
#> 
#> # Fit the 2PL model
#> mod <- mirt(items, 1, itemtype = "2PL")
#> glance(mod)
#> 
#> # Differential item functioning by gender
#> dif_res <- dif(items, group = group, model = "2PL")
#> dif_res
#> gg_dif(dif_res)
#> interpret(dif_res)
#> 
#> # Report
#> mv_report(mod, file = "mirtverse-report.html", dif = dif_res)
```

The printout shows how the request was understood (the *plan*), any
assumptions mirtverse made, and the script. Nothing has been run yet.

- `run_script(scr)` runs it and returns the objects it created (`mod`,
  `dif_res`, …). `run_script(scr, check = TRUE)` first runs the whole
  script on simulated data with the same structure as yours, so errors
  show up before your data are touched.
- `save_script(scr, "analysis.R", open = TRUE)` writes it to a file and
  opens it in RStudio or Positron.

## Changing the script

Pass the script back with the change you want; the rest of the plan is
kept.

``` r

scr <- mv_ask(scr, "use a 3PL instead and save EAP scores to scores.csv")
scr$plan
#> Analysis plan
#>   - Data: mydata 
#>   - Items: 12 items (Q1 ... Q12) 
#>   - Model: 3PL, 1 dimension 
#>   - DIF by: gender 
#>   - Steps: fit, dif, scores, report 
#> Assumptions
#>   - Used the 12 columns that look like item responses as items.
```

## Who understands the request?

By default a built-in keyword parser reads the request. It works
offline, needs nothing installed, and when something is unclear (for
example, “check DIF” in a data set with several possible grouping
columns) it asks a short question in the console.

For freer wording, connect an AI model once with
[`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md):

``` r

mv_ask_setup("claude")                     # Anthropic Claude, your own API key
mv_ask_setup("openai")                     # OpenAI GPT, your own API key
mv_ask_setup("ollama", model = "qwen2.5")  # a free model on your own computer
```

The setup asks for the key with a masked prompt, sends one tiny test
request, and offers to save the settings in your `.Renviron` file or the
system keychain, so you only do it once. Keys are never written into
scripts or reports. Ollama (<https://ollama.com>) runs the model on your
own machine, so nothing leaves it; it needs about 8 GB of memory for a
mid-size model.

Whatever the model, it only fills in the plan. The R code always comes
from mirtverse’s tested templates, and the plan is checked against your
data before any code is written (do the columns exist, does the group
have at least two levels, is a 2PL being asked of items with more than
two categories).

## What is sent to the AI model

Never individual responses. The model receives your request and a
summary of each column: its type, number of distinct values, range,
share missing, its guessed role, and the category labels of likely
grouping columns. This is what
[`profile_data()`](https://www.okanbulut.com/mirtverse/reference/profile_data.md)
shows:

``` r

profile_data(mydata)
#> Data profile: 800 rows, 14 columns (12 look like items)
#>      column    type n_distinct min max prop_missing  role levels
#>  student_id integer        800   1 800            0    id       
#>          Q1 integer          2   0   1            0  item       
#>          Q2 integer          2   0   1            0  item       
#>          Q3 integer          2   0   1            0  item       
#>          Q4 integer          2   0   1            0  item       
#>          Q5 integer          2   0   1            0  item       
#>          Q6 integer          2   0   1            0  item       
#>          Q7 integer          2   0   1            0  item       
#>          Q8 integer          2   0   1            0  item       
#>          Q9 integer          2   0   1            0  item       
#>         Q10 integer          2   0   1            0  item       
#>         Q11 integer          2   0   1            0  item       
#>         Q12 integer          2   0   1            0  item       
#>      gender    text          2  NA  NA            0 group   F, M
```

To see exactly what would be sent, use `dry_run = TRUE`. With
`anonymize = TRUE` the column names are replaced by V1, V2, … (also
inside your request) and category labels are dropped; mirtverse maps the
names back locally.

``` r

mv_ask("check DIF by gender", data = mydata, anonymize = TRUE, dry_run = TRUE)
#> No AI model is set up, so nothing would be sent; an AI model would receive:
#> 
#> Request: check DIF by V14
#> 
#> Data: 800 rows, 14 columns.
#> Columns (name | type | distinct values | min | max | share missing | guessed role | categories):
#> - V1 | integer | 800 | 1 | 800 | 0.00 | id | 
#> - V2 | integer | 2 | 0 | 1 | 0.00 | item | 
#> - V3 | integer | 2 | 0 | 1 | 0.00 | item | 
#> - V4 | integer | 2 | 0 | 1 | 0.00 | item | 
#> - V5 | integer | 2 | 0 | 1 | 0.00 | item | 
#> - V6 | integer | 2 | 0 | 1 | 0.00 | item | 
#> - V7 | integer | 2 | 0 | 1 | 0.00 | item | 
#> - V8 | integer | 2 | 0 | 1 | 0.00 | item | 
#> - V9 | integer | 2 | 0 | 1 | 0.00 | item | 
#> - V10 | integer | 2 | 0 | 1 | 0.00 | item | 
#> - V11 | integer | 2 | 0 | 1 | 0.00 | item | 
#> - V12 | integer | 2 | 0 | 1 | 0.00 | item | 
#> - V13 | integer | 2 | 0 | 1 | 0.00 | item | 
#> - V14 | text | 2 |  |  | 0.00 | group |
```

## Writing a plan by hand

The plan is an ordinary R object, so you can also skip the request and
write it yourself:

``` r

pl <- mv_plan(items = "Q1:Q10", model = "Rasch", missing = 9,
              steps = c("describe", "fitcheck", "scores", "report"))
mv_ask(data = mydata, plan = pl)
#> Analysis plan
#>   - Data: mydata 
#>   - Items: 10 items (Q1 ... Q10) 
#>   - Missing codes: 9 
#>   - Model: Rasch, 1 dimension 
#>   - Steps: fit, describe, fitcheck, scores, report 
#> 
#> R script (run it with run_script(), save it with save_script())
#> ----------------------------------------------------------------
#> # Analysis script written by mirtverse::mv_ask()
#> # 2026-10-29 15:53
#> library(mirtverse)
#> 
#> # Data
#> raw <- mydata
#> items <- raw[, c("Q1", "Q2", "Q3", "Q4", "Q5", "Q6", "Q7", "Q8", "Q9", "Q10")]
#> items[items == 9] <- NA
#> 
#> # Describe the items
#> itemstats(items)
#> 
#> # Fit the Rasch model
#> mod <- mirt(items, 1, itemtype = "Rasch")
#> glance(mod)
#> 
#> # Check model and item fit
#> item_table(mod)
#> gg_itemfit(mod)
#> gg_q3(mod)
#> 
#> # Person scores
#> scores <- augment(mod, method = "EAP")
#> gg_scores(mod)
#> 
#> # Report
#> mv_report(mod, file = "mirtverse-report.html")
```
