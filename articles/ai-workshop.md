# AI in measurement: A one-day workshop

The workshop takes a room of people who know item response theory (IRT)
through the AI topics of the [AI
Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.md) in one day:
Automated scoring, item text and difficulty, automatic item generation,
and the audit of an AI-scored test, ending with governance and a plan
for each participant’s own program. It suits 8 to 30 psychometricians,
testing-program staff or graduate students who have used R. No one needs
to have trained a model or used a language model before.

Everything runs offline. The four labs use simulated data with problems
planted on purpose, and the language-model examples answer from
recordings
([`mv_llm_replay()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md)),
so no API key or internet connection is needed on the day and every
participant sees the same results.

## Get the kit

``` r

library(mirtverse)
kit <- copy_workshop("ai-workshop")   # slides, facilitator's guide, README
rmarkdown::render(file.path(kit, "slides.Rmd"))
rmarkdown::render(file.path(kit, "facilitator-guide.Rmd"))
```

| File | What it is |
|----|----|
| `slides.Rmd` | The day’s slides, one section per session, with the code for each topic. Edit them to add your own program’s examples. |
| `facilitator-guide.Rmd` | Preparation, the schedule, the goal of each session, what to watch for in each lab, discussion questions, and what to do when something goes wrong. |
| `README.md` | What is in the folder. |

## The day

| Time | Session | Material |
|----|----|----|
| 9:00 to 9:45 | AI in measurement: What changes and what does not | Slides; book chapter [Machine learning through an IRT lens](https://www.okanbulut.com/mirtverse/book/ml-lens.md) |
| 9:45 to 11:00 | Automated scoring | [Lab 7](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#lab-7), `run_lab("auto-scoring")` |
| 11:15 to 12:30 | Item text and difficulty | [Lab 8](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#lab-8), `run_lab("item-text")` |
| 13:30 to 14:45 | Automatic item generation | [Lab 9](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#lab-9), `run_lab("aig")` |
| 15:00 to 16:15 | Auditing an AI-scored test | [Lab 10](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#lab-10), `run_lab("ai-audit")` |
| 16:15 to 17:00 | Governance, and what to do on Monday | Slides; book chapter [Validity, fairness and governance of AI](https://www.okanbulut.com/mirtverse/book/ai-validity.md) |

With half a day, keep the opening, Labs 7 and 10, and the governance
session. For a semester instead of a day, the [course
map](https://www.okanbulut.com/mirtverse/articles/course-map.html#ai-module)
spreads the same material over four weeks with a book chapter as each
week’s reading.

## Before the day

Ask participants to install the packages and open one lab:

``` r

install.packages(c("mirt", "learnr", "remotes"))
remotes::install_github("okanbulut/mirtverse")
library(mirtverse)
run_lab("auto-scoring")
```

Run each of the four labs to the end yourself, with the answer key in
[Teaching
labs](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#answer-key)
open, and read the facilitator’s guide. Labs work best in pairs.

## Make it yours

- **Your own data.** The [instructor
  toolkit](https://www.okanbulut.com/mirtverse/articles/instructor-toolkit.html#ai-sections)
  builds labs with AI sections on your own items or your own engine’s
  scores, which can replace a built-in lab in the afternoon.
- **Your own examples.** The slides are plain R Markdown: Add a slide on
  an AI use in your program, or a live model with
  [`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md)
  if your room has internet and your data can leave it.
- **An assistant.** The [teaching
  assistant](https://www.okanbulut.com/mirtverse/articles/instructor-mcp.md)
  can adapt the slides or build a lab for you from a plain-language
  request.
