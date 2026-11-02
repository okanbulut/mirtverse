# AI Hub: artificial intelligence for psychometricians

Artificial intelligence (AI) now writes test items, scores essays,
predicts item difficulty and drafts analysis code. If you were trained
in item response theory (IRT), classical test theory and validity
theory, you already have the tools to judge these systems. What is
usually missing is the vocabulary, a sense of how the methods work, and
practice checking them.

The AI Hub is for that reader: a psychometrician, graduate student or
testing-program analyst who knows IRT and some R, but has not trained a
machine learning model or called a large language model (LLM). Every
topic starts from a job you already do and puts the AI method beside the
classical one.

## What changes and what does not

AI changes **how** some parts of a test are produced: items can be
drafted in minutes, constructed responses can be scored as they arrive,
and item properties can be estimated before a field test. It does not
change **what** a test has to show. The scores still need evidence that
they mean what we say they mean, for the people we use them with. The
*Standards for Educational and Psychological Testing* apply to an
AI-scored test just as they apply to any other.

That is why every AI feature in mirtverse sits behind a psychometric
check: generated items are verified and calibrated, machine scores must
agree with human scores overall and within groups, and anything
uncertain goes back to a person.

## A learning path

Work through the steps in order, or jump to the job you face now. Each
step names the question it answers, what to read and what to try in R.

| Step | The question | Read | Try in R |
|----|----|----|----|
| 1\. Vocabulary | What do machine learning words mean in measurement terms? | [Translation table](https://www.okanbulut.com/mirtverse/articles/ai-translation.md); the AI section of the [glossary](https://www.okanbulut.com/mirtverse/articles/glossary.html#ai) | — |
| 2\. ML through an IRT lens | How do prediction models differ from measurement models? | Book chapter on machine learning (coming soon) | — |
| 3\. LLMs in your workflow | How do I use a language model safely for analysis and writing? | [Scripts from plain language](https://www.okanbulut.com/mirtverse/articles/mv-ask-guide.md); book chapter on LLMs (coming soon) | [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md) |
| 4\. Automated scoring | Can a machine score constructed responses as well as raters? | [Reading list: automated scoring](https://www.okanbulut.com/mirtverse/articles/ai-reading.html#automated-scoring) | [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md); [Lab 6](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md) |
| 5\. Item text and difficulty | What does the wording of an item tell us before anyone answers it? | [Reading list: item text](https://www.okanbulut.com/mirtverse/articles/ai-reading.html#item-text) | coming soon |
| 6\. Automatic item generation | How do I generate items and know which ones to keep? | [Assessment pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md); [reading list: AIG](https://www.okanbulut.com/mirtverse/articles/ai-reading.html#aig) | [`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md), [`verify_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md) |
| 7\. Validity and fairness | What evidence does an AI component need before it is used? | [Reading list: validity](https://www.okanbulut.com/mirtverse/articles/ai-reading.html#validity) | [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md); audit tools coming soon |

## What you can do with AI in mirtverse today

These functions use a language model through the
[ellmer](https://ellmer.tidyverse.org) package. Set one up once with
[`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md):
Claude or OpenAI with your own API key, or a local model through Ollama
if your data must stay on your computer.

### Write analysis code from a plain-language request

``` r

library(mirtverse)
mv_ask_setup()                       # choose a provider, store the key
mv_ask("fit a 2PL to SAT12 and plot item information", data = SAT12)
```

[`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
turns the request into a plan, fills tested code templates and shows you
the script before anything runs. Without a provider it falls back to an
offline keyword parser. The
[guide](https://www.okanbulut.com/mirtverse/articles/mv-ask-guide.md)
explains what is sent to the model and how to keep column names private.

### Generate and verify items

``` r

p <- mv_pipeline("Grade 6 numeracy")
p <- set_blueprint(p, blueprint)     # content areas x cognitive levels
p <- generate_items(p, n = 40)       # drafts with keys and rationales
p <- verify_items(p)                 # a second model answers each item blind
flags(p)                             # wrong keys, weak distractors, duplicates
```

A second, independent model call answers each multiple-choice item
without seeing the key; disagreements are flagged before any person
reviews the items. `review_packet(p, ai_screen = TRUE)` then prepares
the human review.

### Score open-ended responses, and check the scores

``` r

p <- score_open(p, responses, scorer = "llm")   # or a trained model
flags(p)                                        # agreement and fairness gates
```

Machine scores pass the same gates whether they come from a language
model or from a model you trained yourself: quadratic weighted kappa
against human scores, standardized mean differences overall and within
groups, and low-confidence responses routed back to human raters.

## How the AI Hub teaches

- **Familiar job first.** Each topic opens with a task you already do
  and shows the AI method next to the classical one, on the same data.
- **Evidence before adoption.** Every AI output passes a psychometric
  check before it counts.
- **Offline by default.** Labs and book examples will run without an API
  key or an internet connection, using recorded model outputs, so a
  classroom never depends on a provider being up. Live models are an
  optional extra.
- **Known answers.** As in the teaching labs, the AI datasets are
  simulated with planted problems, such as a scorer that is harsher on
  one group, and each lab ends by revealing them.

## For instructors

[Lab 6](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md),
on scoring open-ended responses, already compares an automated engine
with human raters and fits well at the end of an IRT course. More AI
labs, book chapters and an optional AI module for the [course
map](https://www.okanbulut.com/mirtverse/articles/course-map.md) are
being written; they will be listed on this page and in the AI Hub menu
as they are released.

## Read more

The [reading
list](https://www.okanbulut.com/mirtverse/articles/ai-reading.md)
collects the books, papers and guidelines behind each step of the path,
with a sentence on why each is worth reading. Start with the overviews
at the top.
