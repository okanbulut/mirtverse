# The mirtverse agent for Claude

The **mirtverse agent** is Claude working as a psychometrician on your
computer. You put your data in a folder, open the folder in [Claude
Code](https://claude.com/claude-code), and ask in plain words:

> *Analyze `exam.csv`. It is a 40-item end-of-year math test taken by
> 1,200 grade 8 students. The `lang` column says whether a student is an
> English language learner.*

Claude reads the data, fits and compares IRT models with mirtverse and
mirt, checks every item, tests the items for DIF across `lang`, scores
the students, looks at the plots, and explains the results in plain
language. It writes the scores, plots and an HTML report to a
`mirtverse-output` folder, together with an R script that reproduces
every step. You do not need to know R, but everything it does is R code
you can check and rerun.

It is not a chatbot that answers from memory. Every number comes from
mirtverse running on your data, on your computer.

## How it works

The plugin gives Claude three things:

- **Tools.** An MCP server,
  [`mv_agent_server()`](https://www.okanbulut.com/mirtverse/reference/mv_agent_server.md),
  runs in R and gives Claude tools to read your data, fit models, check
  items, test DIF, score people, draw plots, interpret results, write a
  report, save the script, and run other R code.
  ([MCP](https://modelcontextprotocol.io) is the standard way AI
  assistants connect to tools.)
- **Skills.** Instructions that tell Claude how a careful
  psychometrician works: Check the data first, explain the model choice,
  discuss every flagged item with its evidence, separate statistical
  from practical DIF, and never invent a number.
- **An analyst agent.** A subagent that runs a whole analysis by itself,
  so Claude can analyze several files or subgroups side by side.

| Skill | Ask for example |
|----|----|
| `analyze-test` | “Analyze exam.csv”, “Calibrate this test”, “Is this test any good?” |
| `check-dif` | “Are any items unfair to English language learners?” |
| `review-items` | “Which items should we revise before next year?” |
| `write-report` | “Write up the results for the school board” |
| `setup` | “The mirtverse tools are missing” |

Claude picks the skill from your request; you can also call one
directly, for example `/mirtverse:check-dif`.

## Install

You need three things on your computer.

1.  **R** (4.1 or later) from [CRAN](https://cran.r-project.org).

2.  **mirtverse**. In R:

    ``` r

    install.packages("remotes")
    remotes::install_github("okanbulut/mirtverse")
    ```

3.  **Claude Code**. Follow the [installation
    guide](https://code.claude.com/docs/en/setup); it runs in a
    terminal, in the Claude desktop app, and in VS Code and JetBrains.

Then add the plugin. In Claude Code, type:

    /plugin marketplace add okanbulut/mirtverse
    /plugin install mirtverse@mirtverse

(Recent versions of Claude Code also accept
`/plugin install mirtverse --marketplace okanbulut/mirtverse` in one
step.)

Finally, connect the mirtverse server, once. The plugin brings the
skills and the analyst agent; the tools come from the MCP server in the
mirtverse package, which runs on your computer and is connected
separately. In a terminal, run:

    claude mcp add --scope user mirtverse -- Rscript -e "mirtverse::mv_agent_server()"

(If `Rscript` is not on your PATH, which is common on Windows, run
`mirtverse::mv_mcp_config(NULL, client = "claude-code", mode = "analysis")`
in R; it prints the same command with the full path to Rscript. You can
also just ask Claude to “set up mirtverse”: the `setup` skill walks
through it.) Restart Claude Code, and the mirtverse tools are ready in
every folder you open.

## Use it

1.  Put your data file in a folder, for example `~/projects/math-test`.
    CSV, Excel, SPSS, Stata and R files work.
2.  Open the folder in Claude Code (in a terminal:
    `cd ~/projects/math-test` then `claude`).
3.  Ask. Say what the test is and what you need, the way you would brief
    a colleague. Claude asks if something is unclear, such as which
    columns are items or whether `9` means “not answered”.

A typical exchange, here on the `SAT12` data that ship with mirt (the
numbers are what the tools return):

> **You:** Analyze the SAT12 data from mirt. The answer key is 1, 4, 5,
> 2, 3, 1, 2, 1, 3, 1, 2, 4, 2, 1, 5, 3, 4, 4, 1, 4, 3, 3, 4, 1, 3, 5,
> 1, 3, 1, 5, 4, 5, and 8 means not answered.
>
> **Claude:** *(describes the data, scores the responses with the key,
> fits the Rasch, 2PL and 3PL models, checks the items, then)* The 2PL
> model is the best choice: Its BIC is 111 points lower than the Rasch
> model’s, and the 3PL model did not converge. The test works reasonably
> well (RMSEA .028, CFI .954) and its reliability is .84, adequate for
> reporting individual scores. Nine of the 32 items are flagged. Item.32
> barely separates weaker from stronger students (discrimination 0.12)
> and its location, 14.2, is far beyond anyone who took the test, so
> check its key first … The files are in `mirtverse-output/`: Scores,
> plots, `model-report.html`, and `analysis.R`, which reproduces
> everything.

You can keep going: “Drop Q17 and compare”, “Check DIF by school”, “Make
the report for teachers, not psychometricians”.

The built-in datasets work too, so you can try it without data of your
own, for example *“Fit a graded model to the Science data”*.

## What the tools do

| Tool | What it does |
|----|----|
| `project_overview` | Data files, models fitted so far, and output files |
| `describe_dataset` | Columns, item types, missing values, likely IDs and groups |
| `fit_model` | Fits a model or compares models ([`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md)), with missing codes and answer keys |
| `check_items` | Item statistics, fit and flags ([`item_table()`](https://www.okanbulut.com/mirtverse/reference/item_table.md)) |
| `check_dif` | DIF tests and effect sizes ([`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md)) |
| `score_people` | Ability estimates and standard errors, written to a CSV |
| `plot_model` | Item curves, information, Wright map, item fit, scores, DIF; Claude sees the picture |
| `interpret_model` | Plain-language interpretation ([`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md)) |
| `write_report` | HTML technical report ([`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md)) |
| `save_script` | The R code of every step, as one script |
| `run_r` | Any other R code, in the same session |
| `guide`, `mirtverse_help` | The analysis guides and the mirtverse help pages |

Fitted models are kept between sessions (in `.mirtverse-mcp/models`), so
you can come back tomorrow and ask “Write the report for yesterday’s
model”.

## Your data

The analysis runs on your computer. Your data files are only read, never
changed, and results go to `mirtverse-output/`. What Claude sees is what
the tools return: Column summaries, model and item statistics, plots and
interpretations, not the full data. Code that Claude runs with `run_r`
can print rows of the data, so for sensitive data tell Claude not to
print individual records, or remove names and IDs before you start. Your
organization’s rules for AI tools apply.

## Without the plugin

**A CLAUDE.md for one folder.**
[`mv_agent_init()`](https://www.okanbulut.com/mirtverse/reference/mv_agent_init.md)
writes the two files that turn a folder into a mirtverse project for
Claude Code: A `CLAUDE.md` with the agent’s instructions, and a
`.mcp.json` that starts the server with the full path to `Rscript`. This
is also the way to go on Windows when `Rscript` is not on the PATH.

``` r

mirtverse::mv_agent_init("~/projects/math-test",
                         title = "Grade 8 math test, spring 2026")
```

Open `CLAUDE.md` and fill in the “About this project” section (what the
test measures, who took it, what the results are for); Claude reads it
at the start of every session. Then start Claude Code in the folder and
approve the `mirtverse` server.

**Claude Desktop and other assistants.** The same server works with any
MCP client.
[`mv_mcp_config()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_config.md)
prints the settings:

``` r

mv_mcp_config("~/projects/math-test", client = "claude-desktop", mode = "analysis")
mv_mcp_config("~/projects/math-test", client = "codex", mode = "analysis")
```

The skills are written for Claude Code, but the server carries its own
guides (`guide("analysis")` and `guide("interpreting")`) and three
prompts, “Analyze my test”, “Check items for fairness” and “Write a
technical report”, so other clients get the same workflow.

## Related

- [Scripts from plain
  language](https://www.okanbulut.com/mirtverse/articles/mv-ask-guide.md):
  [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
  writes an analysis script from a request, inside R.
- [An AI assistant for your course
  materials](https://www.okanbulut.com/mirtverse/articles/instructor-mcp.md):
  The instructor MCP server, for labs, chapters and lecture notes.
