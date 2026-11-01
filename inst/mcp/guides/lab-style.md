# Style guide for mirtverse labs

mirtverse labs are [learnr](https://rstudio.github.io/learnr/) tutorials: one
R Markdown file per lab, in its own folder, with live R exercises that are
checked automatically and multiple-choice questions that record the
student's decisions. Students open them with `run_lab()` (built-in labs) or
`learnr::run_tutorial()` / the Run Document button (course labs).

## File layout

```
labs/<name>/<name>.Rmd     the lab
labs/<name>/data/           the lab's data (responses.rds, lab.json)
```

## YAML header

```yaml
---
title: "Lab N: A question the lab answers"
description: >
  Two or three sentences: the scenario, what students will do, and how long
  it takes ("About 60 minutes.").
output:
  learnr::tutorial:
    progressive: true
    allow_skip: true
runtime: shiny_prerendered
---
```

## Setup chunk

```{r setup, include = FALSE}
library(learnr)
library(mirtverse)
tutorial_options(exercise.checker = mirtverse::lab_checker,
                 exercise.timelimit = 120, exercise.lines = 6)
knitr::opts_chunk$set(echo = FALSE, fig.width = 7, fig.height = 4.5)
# objects every exercise needs
```

Exercises that need objects created earlier get their own `setup-<name>`
chunk (with `include = FALSE`) and `exercise.setup = "setup-<name>"`, because
each learnr exercise runs in a fresh environment.

## Story

Every lab is a realistic, **fictional** scenario: an organization, a decision
to make, and a person who asks for it ("The deputy minister has asked you
three questions"). Sections follow the analysis an analyst would do, and the
lab ends with a decision log and a short wrap-up. Write for students who are
new to R: short paragraphs, bold key terms on first use, and one idea per
section.

## Exercises

Each exercise has up to four chunks with the same label stem:

````
```{r gap, exercise = TRUE}
p_ell <- colMeans(scored[ell == "ELL", ])
gap <-
```

```{r gap-hint}
gap <- p_ell - p_fluent
```

```{r gap-solution}
p_ell <- colMeans(scored[ell == "ELL", ])
gap <- p_ell - p_fluent
```

```{r gap-check}
lab_need(exists("gap") && is.numeric(gap), "Save the differences as `gap`.")
"Feedback shown when the answer is right: what the result means."
```
````

- The exercise chunk gives a starting point with blanks for the student to
  complete, not an empty box.
- The `-check` chunk uses `lab_need(condition, message)`: the message tells
  the student what is wrong and how to fix it. `.result` holds the value of
  the student's last expression. The last line is the feedback string, which
  interprets the result (it is the teaching moment, not "Correct!").
- Checks must only use exported functions (`mirtverse::...`, base R): learnr
  runs them outside the package.
- Long-running exercises (model fitting) get `exercise.timelimit = 180` or
  more.

## Questions

```{r q-impact}
question_radio("What can you conclude?",
  answer("The right answer.", correct = TRUE,
         message = "Why it is right, with the concept named in bold."),
  answer("A tempting wrong answer.",
         message = "Why it is tempting and why it is wrong."),
  allow_retry = TRUE, random_answer_order = TRUE
)
```

Question labels start with `q-`. Every answer, right or wrong, has a
`message` that teaches. Use `question_checkbox()` when several answers are
right.

## Decision log

The last section lists the student's answers with `lab_decisions()`:

````
```{r decision-log-ui}
tableOutput("decision_log")
```

```{r decision-log-server, context = "server"}
output$decision_log <- renderTable({
  mirtverse::lab_decisions(learnr::get_tutorial_state(), c(
    "q-impact" = "Raw group differences"
  ))
})
```
````

When you add a question, add its label to the decision log.

## Text conventions

- Use typographic apostrophes and quotes (’ “ ”) in question and answer text;
  learnr strips straight apostrophes there.
- Round reported numbers sensibly (two decimals for parameters).
- Do not reveal answers before the student answers: explanations belong in
  question messages, exercise feedback or the instructor's answer key, which
  sits at the very end of instructor documents.
- Prefer mirtverse functions (`select_model()`, `tidy()`, `gg_trace()`,
  `dif()`, `interpret()`) where they make the code shorter for students, and
  plain mirt where the lab teaches mirt itself.
