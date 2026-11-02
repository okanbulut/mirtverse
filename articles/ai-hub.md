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
| 2\. ML through an IRT lens | How do prediction models differ from measurement models? | Book: [Machine learning through an IRT lens](https://www.okanbulut.com/mirtverse/book/ml-lens.md) | — |
| 3\. LLMs in your workflow | How do I use a language model safely for analysis and writing? | [Scripts from plain language](https://www.okanbulut.com/mirtverse/articles/mv-ask-guide.md); book: [Large language models as a colleague](https://www.okanbulut.com/mirtverse/book/llms.md) | [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md), [`mv_llm_replay()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md) |
| 4\. Automated scoring | Can a machine score constructed responses as well as raters? | [Reading list: automated scoring](https://www.okanbulut.com/mirtverse/articles/ai-reading.html#automated-scoring) | [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md); [Lab 6](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md) |
| 5\. Item text and difficulty | What does the wording of an item tell us before anyone answers it? | [Reading list: item text](https://www.okanbulut.com/mirtverse/articles/ai-reading.html#item-text) | the `itemtext` data; modelling tools coming soon |
| 6\. Automatic item generation | How do I generate items and know which ones to keep? | [Assessment pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md); [reading list: AIG](https://www.okanbulut.com/mirtverse/articles/ai-reading.html#aig) | [`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md), [`verify_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md) |
| 7\. Validity and fairness | What evidence does an AI component need before it is used? | [Reading list: validity](https://www.okanbulut.com/mirtverse/articles/ai-reading.html#validity) | [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md); audit tools coming soon |

## What you can do with AI in mirtverse today

These functions use a language model through the
[ellmer](https://ellmer.tidyverse.org) package. Set one up once with
[`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md):
Claude or OpenAI with your own API key, or a local model through Ollama
if your data must stay on your computer.

To try them with no key and no internet connection, turn on replay mode
first. Every request is then answered from a file of recorded responses,
so the same call always gives the same answer:

``` r

library(mirtverse)
mv_llm_replay()      # answer from the example recordings
mv_llm_recordings()  # which requests they cover
```

The example recordings answer the calls in
`system.file("replay", "examples.R", package = "mirtverse")`, which
include the three examples below. Their responses were written by hand
to show what a model returns, with a few deliberate mistakes for
mirtverse’s checks to catch. To capture your own session with a live
model and replay it in class, use
[`mv_llm_record()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md).

### Write analysis code from a plain-language request

``` r

mv_ask("Fit a graded response model to these attitude items, check the fit and explain the results.",
       data = Science, ask = FALSE)
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

q <- score_open(q, responses, scorer = "llm")   # or a trained model
q$agreement                                     # machine-human agreement
flags(q)                                        # agreement and fairness gates
```

The full example in `examples.R` scores 40 answers from the `essays`
data against a four-point rubric.

Machine scores pass the same gates whether they come from a language
model or from a model you trained yourself: quadratic weighted kappa
against human scores, standardized mean differences overall and within
groups, and low-confidence responses routed back to human raters.

## How the AI Hub teaches

- **Familiar job first.** Each topic opens with a task you already do
  and shows the AI method next to the classical one, on the same data.
- **Evidence before adoption.** Every AI output passes a psychometric
  check before it counts.
- **Offline by default.** Labs and book examples run without an API key
  or an internet connection, using recorded model outputs
  ([`mv_llm_replay()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md)),
  so a classroom never depends on a provider being up. Live models are
  an optional extra.
- **Known answers.** As in the teaching labs, the AI datasets are
  simulated with planted problems, and
  [`lab_truth()`](https://www.okanbulut.com/mirtverse/reference/lab_truth.md)
  reveals them. `itemtext` has 192 numeracy items from 12 item families
  with field-test difficulties; `essays` has 1,600 short science
  explanations scored by raters, written so that fluent writers’ answers
  are longer at the same score.

## For instructors

[Lab 6](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md),
on scoring open-ended responses, already compares an automated engine
with human raters and fits well at the end of an IRT course. The [online
book](https://www.okanbulut.com/mirtverse/book/index.md) has a part on
AI in measurement whose chapters work offline, so they can be assigned
as readings. More AI labs, chapters and an optional AI module for the
[course map](https://www.okanbulut.com/mirtverse/articles/course-map.md)
are being written; they will be listed on this page and in the AI Hub
menu as they are released.

## Read more

The [reading
list](https://www.okanbulut.com/mirtverse/articles/ai-reading.md)
collects the books, papers and guidelines behind each step of the path,
with a sentence on why each is worth reading. Start with the overviews
at the top.
