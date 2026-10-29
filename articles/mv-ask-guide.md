# mv_ask(): from a sentence to a tested R script

Many people who need an IRT analysis know what they want to find out but
not which functions, arguments and checks get them there.
[`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
closes that gap. You describe the analysis in a sentence, and mirtverse
writes the full, commented R script: reading the data, recoding missing
values, fitting and checking the model, testing for DIF, scoring,
plotting and reporting. You read the script, change it if you like, and
then run or save it.

This article explains how
[`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
works, walks through examples, and reports how accurately it understands
requests with each of the supported language models. For a shorter
introduction, see
[`vignette("ask", package = "mirtverse")`](https://www.okanbulut.com/mirtverse/articles/ask.md).

``` r

library(mirtverse)
#> Loading required package: mirt
#> Loading required package: stats4
#> Loading required package: lattice
```

## How it works

![Workflow of mv_ask(): your request and a summary of your data are
turned into an analysis plan by the keyword parser or an optional AI
model; the plan is checked against the data and tested templates write
the R script, which you run or save.](figures/mv-ask-workflow.svg)

[`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
follows a **hybrid design**: a language model (or a built-in keyword
parser) decides *what* to do, and mirtverse decides *how* to do it.

1.  **Summarise the data.**
    [`profile_data()`](https://www.okanbulut.com/mirtverse/reference/profile_data.md)
    describes each column: its type, number of distinct values, range,
    share missing and likely role (item, grouping variable, ID or
    response time). Individual responses are never part of this summary.
2.  **Understand the request.** The request and the summary go to the
    understanding step. By default this is a keyword parser that runs
    offline and needs no setup. If you connect a model with
    [`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md),
    Claude, GPT or a local Ollama model does this step instead. The
    model never writes code. It fills in a structured form with a fixed
    set of choices: which columns are items, which model, how many
    dimensions, which grouping variable, which missing-value codes and
    which outputs.
3.  **Check the plan.** The filled-in form becomes an
    [`mv_plan()`](https://www.okanbulut.com/mirtverse/reference/mv_plan.md)
    object, which is checked against your data before any code is
    written. Do the columns exist? Does the grouping variable have at
    least two groups? Is a 2PL being asked of items with more than two
    categories? Problems are reported in plain language, and anything
    mirtverse assumed is listed.
4.  **Write the script.** Tested templates turn the plan into R code
    that uses only mirt and mirtverse functions with checked arguments.
    The same templates power the code export in the
    [workbench](https://www.okanbulut.com/mirtverse/articles/workbench.md).
5.  **Run or save.** Nothing runs until you ask.
    `run_script(scr, check = TRUE)` first runs the whole script on
    simulated data shaped like yours, so any error shows up before your
    real data are touched.

Because the language model only chooses among options that mirtverse
already knows how to code, a model cannot invent a function or an
argument that does not exist. The worst a misunderstanding can do is
produce a valid script for a different analysis than the one you meant,
and the printed plan makes that easy to spot.

## Examples

The examples use a small simulated data set: 800 students, twelve 0/1
items (`Q1` to `Q12`), a gender column and a student ID. They use the
built-in keyword parser (`provider = "none"`) so that this page builds
without an API key. With an AI model connected, the same requests work,
and so does much freer wording.

``` r

set.seed(1)
a <- matrix(rlnorm(12, 0.2, 0.25))
d <- matrix(rnorm(12))
mydata <- data.frame(student_id = 1:800, simdata(a, d, 800, itemtype = "2PL"),
                     gender = rep(c("F", "M"), 400))
names(mydata)[2:13] <- paste0("Q", 1:12)
```

### A complete analysis in one sentence

``` r

scr <- mv_ask("Fit a 2PL, check DIF by gender and make a report",
              data = mydata, provider = "none")
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
#> # 2026-10-29 21:58
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

The printout has three parts: the plan (what will be done), the
assumptions mirtverse made (here, that `Q1` to `Q12` are the items
because they look like item responses), and the script itself.

### Refining a script

Pass the script back with the change you want. The rest of the plan is
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

### Letting mirtverse choose the model

When you don’t name a model, mirtverse compares the candidates with
[`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md)
and keeps the best one.

``` r

mv_ask("Which IRT model fits my data best? Explain the results in plain language.",
       data = mydata, provider = "none")
#> Request: Which IRT model fits my data best? Explain the results in plain
#> language. 
#> Understood by the built-in keyword parser
#> 
#> Analysis plan
#>   - Data: mydata 
#>   - Items: 12 items (Q1 ... Q12) 
#>   - Model: compare candidate models and keep the best (1 dimension) 
#>   - Steps: fit, fitcheck, interpret 
#> Assumptions
#>   - Used the 12 columns that look like item responses as items. 
#> 
#> R script (run it with run_script(), save it with save_script())
#> ----------------------------------------------------------------
#> # Analysis script written by mirtverse::mv_ask()
#> # 2026-10-29 21:58
#> # Request: Which IRT model fits my data best? Explain the results in
#> #   plain language.
#> # Assumptions:
#> #  - Used the 12 columns that look like item responses as items.
#> library(mirtverse)
#> 
#> # Data
#> raw <- mydata
#> items <- raw[, c("Q1", "Q2", "Q3", "Q4", "Q5", "Q6", "Q7", "Q8", "Q9", "Q10", "Q11",
#>   "Q12")]
#> 
#> # Choose and fit a model
#> sel <- select_model(items)
#> sel
#> mod <- sel$best
#> 
#> # Check model and item fit
#> item_table(mod)
#> gg_itemfit(mod)
#> gg_q3(mod)
#> 
#> # Plain-language summary
#> interpret(mod)
```

### Missing-value codes and a subset of items

``` r

coded <- mydata
coded$Q3[c(5, 17, 40)] <- 9
mv_ask("Rasch model for Q1 to Q10 only; 9 means missing. Give me person scores.",
       data = coded, provider = "none")$plan
#> Analysis plan
#>   - Data: coded 
#>   - Items: 10 items (Q1 ... Q10) 
#>   - Missing codes: 9 
#>   - Model: Rasch, 1 dimension 
#>   - Steps: fit, scores
```

### Using an AI model

Connect a model once. The key is asked for in a masked prompt and stored
in your `.Renviron` file or the system keychain, never in scripts or
reports.

``` r

mv_ask_setup("claude")                         # Anthropic Claude, your own key
mv_ask_setup("openai")                         # OpenAI GPT, your own key
mv_ask_setup("ollama", model = "qwen3.8:27b")  # free, runs on your computer
```

After that,
[`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
uses the model automatically, and requests can be as loose as you would
write them to a colleague:

``` r

mv_ask("I want to know whether boys and girls with the same ability answer
        the items differently, and I need a report for my committee",
       data = mydata)
```

### Seeing exactly what is sent

`dry_run = TRUE` prints what would be sent to the model without sending
it. With `anonymize = TRUE`, column names are replaced by `V1`, `V2`, …
(also inside your request) and category labels are dropped. mirtverse
maps the names back on your computer.

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

### Writing a plan by hand

The plan is an ordinary R object, so you can skip the request entirely:

``` r

pl <- mv_plan(items = "Q1:Q10", model = "Rasch",
              steps = c("describe", "fitcheck", "scores", "report"))
mv_ask(data = mydata, plan = pl)
#> Analysis plan
#>   - Data: mydata 
#>   - Items: 10 items (Q1 ... Q10) 
#>   - Model: Rasch, 1 dimension 
#>   - Steps: fit, describe, fitcheck, scores, report 
#> 
#> R script (run it with run_script(), save it with save_script())
#> ----------------------------------------------------------------
#> # Analysis script written by mirtverse::mv_ask()
#> # 2026-10-29 21:58
#> library(mirtverse)
#> 
#> # Data
#> raw <- mydata
#> items <- raw[, c("Q1", "Q2", "Q3", "Q4", "Q5", "Q6", "Q7", "Q8", "Q9", "Q10")]
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

## How accurate is it?

We wrote 100 requests of the kind users actually type, from “1PL please”
to “Fit a 2PL to my data, check DIF by gender, and make a report”, each
with the plan a careful analyst would choose. A few are deliberately
vague (such as “check DIF” when the data have several possible grouping
columns), and the right response to these is to ask a question rather
than guess. The requests and expected plans are in
[`inst/benchmark/ask-requests.csv`](https://github.com/okanbulut/mirtverse/blob/main/inst/benchmark/ask-requests.csv).

A plan counts as **fully correct** only if every field matches: whether
a question was needed, the model, the number of dimensions, the grouping
variable, the missing-value codes, the items and the analysis steps.

| Parser | Fully correct | Question | Model | Dimensions | Group | Missing | Items | Steps |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| Claude (claude-opus-5-5) | 95 | 96 | 99 | 100 | 99 | 100 | 100 | 98 |
| OpenAI GPT (gpt-5.6-terra) | 90 | 98 | 97 | 100 | 99 | 100 | 100 | 94 |
| Ollama: Qwen 3 8B | 35 | 83 | 91 | 100 | 99 | 100 | 100 | 46 |
| Built-in keyword parser\* | 98 | 100 | 100 | 100 | 100 | 100 | 100 | 98 |

Percentage of the 100 benchmark requests understood correctly. {.table
style="width:100%;"}

\* The keyword parser’s patterns were tuned on these same 100 requests,
so its score is an upper bound. On new wording it will do worse, which
is where the AI models earn their place.

What the results show:

- **Claude** understood 95 of 100 requests completely, and no field fell
  below 96%. Its misses were mostly about whether to ask a clarifying
  question and which outputs to include.
- **GPT** reached 90%. Its weakest field was the analysis steps (94%):
  it added or left out outputs, such as a report or plots, more often
  than Claude.
- **Local models (Ollama)** keep everything on your computer and cost
  nothing per request, but small models struggle. Qwen 3 8B got the
  model, items, group and missing codes right almost always, yet chose
  the right set of analysis steps only 46% of the time, so only 35% of
  its plans were fully correct. Always read the printed plan before
  running a script written with a small local model.
- **Every field except steps and questions is at least 97% for all
  parsers.** Choosing the model, the items, the group and the missing
  codes is easy. The harder part is reading how much the user wants
  done.

To run the benchmark yourself, for example to try another Ollama model:

``` r

mirtverse:::ask_benchmark("claude")
mirtverse:::ask_benchmark("openai")
mirtverse:::ask_benchmark("ollama", model = "qwen3:8b")
```

Each run sends the 100 requests with the column summary of a simulated
data set. With Claude or GPT this costs roughly one or two US dollars. A
local model costs nothing but takes longer: from about ten minutes to an
hour, depending on the model and your computer.

## Privacy in brief

- Individual responses are never sent. The model sees your request and
  the column summary from
  [`profile_data()`](https://www.okanbulut.com/mirtverse/reference/profile_data.md).
- `anonymize = TRUE` hides column names and category labels.
- `dry_run = TRUE` shows exactly what would be sent.
- With Ollama, nothing leaves your computer at all.
- Without any setup, the keyword parser runs fully offline.
