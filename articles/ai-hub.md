# AI Hub: Artificial intelligence for psychometricians

Artificial intelligence (AI) now writes test items, scores essays,
predicts item difficulty and drafts analysis code. If you were trained
in item response theory (IRT), classical test theory and validity
theory, you already have the tools to judge these systems. What is
usually missing is the vocabulary, a sense of how the methods work, and
practice checking them.

The AI Hub is for that reader: A psychometrician, graduate student or
testing-program analyst who knows IRT and some R, but has not trained a
machine learning model or called a large language model (LLM). Every
topic starts from a job you already do and puts the AI method beside the
classical one.

## What changes and what does not

AI changes **how** some parts of a test are produced: Items can be
drafted in minutes, constructed responses can be scored as they arrive,
and item properties can be estimated before a field test. It does not
change **what** a test has to show. The scores still need evidence that
they mean what we say they mean, for the people we use them with. The
*Standards for Educational and Psychological Testing* apply to an
AI-scored test just as they apply to any other.

That is why every AI feature in mirtverse sits behind a psychometric
check: Generated items are verified and calibrated, machine scores must
agree with human scores overall and within groups, and anything
uncertain goes back to a person.

## A learning path

Work through the steps in order, or jump to the job you face now. Each
step names the question it answers, what to read and what to try in R.

| Step | The question | Read | Try in R |
|----|----|----|----|
| 1\. Vocabulary | What do machine learning words mean in measurement terms? | [Translation table](https://www.okanbulut.com/mirtverse/articles/ai-translation.md); the AI section of the [glossary](https://www.okanbulut.com/mirtverse/articles/glossary.html#ai) | — |
| 2\. ML through an IRT lens | How do prediction models differ from measurement models? | Book: [Machine learning through an IRT lens](https://www.okanbulut.com/mirtverse/book/ml-lens.md) | — |
| 3\. LLMs in your workflow | How do I use a language model safely for analysis and writing? | [Scripts from plain language](https://www.okanbulut.com/mirtverse/articles/mv-ask-guide.md); book: [Large language models as a colleague](https://www.okanbulut.com/mirtverse/book/llms.md) | [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md), [`mv_llm_replay()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md); [`simulate_llm_respondents()`](https://www.okanbulut.com/mirtverse/reference/simulate_llm_respondents.md) (experimental) |
| 4\. Automated scoring | Can a machine score constructed responses as well as raters? | Book: [Automated scoring](https://www.okanbulut.com/mirtverse/book/auto-scoring.md); [reading list: Automated scoring](https://www.okanbulut.com/mirtverse/articles/ai-reading.html#automated-scoring) | [`train_scorer()`](https://www.okanbulut.com/mirtverse/reference/train_scorer.md), [`agreement_report()`](https://www.okanbulut.com/mirtverse/reference/agreement_report.md), [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md); [Lab 7](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#lab-7) |
| 5\. Item text and difficulty | What does the wording of an item tell us before anyone answers it? | Book: [What item text tells us](https://www.okanbulut.com/mirtverse/book/item-text.md); [reading list: Item text](https://www.okanbulut.com/mirtverse/articles/ai-reading.html#item-text) | [`item_features()`](https://www.okanbulut.com/mirtverse/reference/item_features.md), [`predict_difficulty()`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md); [Lab 8](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#lab-8) |
| 6\. Automatic item generation | How do I generate items and know which ones to keep? | Book: [Generating items](https://www.okanbulut.com/mirtverse/book/aig.md); [assessment pipeline](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md); [reading list: AIG](https://www.okanbulut.com/mirtverse/articles/ai-reading.html#aig) | [`item_model()`](https://www.okanbulut.com/mirtverse/reference/item_model.md), [`generate_isomorphs()`](https://www.okanbulut.com/mirtverse/reference/generate_isomorphs.md), [`calibrate_families()`](https://www.okanbulut.com/mirtverse/reference/calibrate_families.md), [`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md), [`verify_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md); [Lab 9](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#lab-9) |
| 7\. Validity and fairness | What evidence does an AI component need before it is used? | Book: [Validity, fairness and governance of AI](https://www.okanbulut.com/mirtverse/book/ai-validity.md); [reading list: Validity](https://www.okanbulut.com/mirtverse/articles/ai-reading.html#validity) | [`ai_audit()`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md), [`validity_argument()`](https://www.okanbulut.com/mirtverse/reference/validity_argument.md), [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md); [Lab 10](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#lab-10) |

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
include the language-model examples below. Their responses were written
by hand to show what a model returns, with a few deliberate mistakes for
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

### Predict item difficulty from the text

``` r

feats <- item_features(itemtext)          # length, readability, numbers, options, near-duplicates
items <- merge(itemtext, feats)
m <- predict_difficulty(items, c("family", "sentences", "decimals", "max_digits"),
                        se = "b_se")      # LLTM, lasso and random forest, cross-validated
m
tidy(m)                                   # what each feature adds to difficulty
predict_difficulty(items, c("family", "sentences", "decimals"),
                   group = "family")      # hold out whole item families
```

The LLTM’s weights say what makes items harder; the lasso and the random
forest show how much more a flexible model can predict.
[`predict_difficulty()`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md)
warns when a feature looks like it was computed from the field test
itself, and `group` checks whether predictions hold for a new kind of
item rather than a new item of a known kind.

### Generate items from item models, and calibrate their families

``` r

area <- item_model(
  stem = "A rectangle is {l} cm long and {w} cm wide. What is its area?",
  key = "{l * w} square cm",
  distractors = c(perimeter = "{2 * (l + w)} square cm", added = "{l + w} square cm",
                  half = "{l * w / 2} square cm"),
  values = list(l = 4:12, w = 2:8), constraints = c("l > w", "(l * w) %% 2 == 0"),
  name = "ARE")
area                                       # how many items it can make, and how many are flawed
items <- generate_isomorphs(area, n = 10)  # isomorphs, with the values they came from
# after the field test, with b and its standard error for each item:
calibrate_families(calibrated, family = "model", se = "b_se")
```

An item model generates items whose every option comes from a template,
so an error in the model can be caught for all its items at once.
[`calibrate_families()`](https://www.okanbulut.com/mirtverse/reference/calibrate_families.md)
then checks after the field test whether the isomorphs are equally
difficult, and how large a field test the family mean can replace for a
new item.

### Audit an AI component, and draft the validity argument

``` r

audit <- ai_audit(aiscored_cr, human2 = "human2", group = "group",
                  item = "item", period = "year")   # agreement, fairness, drift
audit                                               # block / review / info flags
autoplot(audit)
va <- validity_argument(audit, construct = "Grade 8 science",
                        use = "school accountability")
va                                                  # claims, threats, evidence by inference
mv_report(fit, extra = list("Validity argument" = va))
```

[`ai_audit()`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md)
checks a scoring engine against human scores overall, within groups at
the same human score, and across administrations or engine versions;
with `responses` it adds DIF on the test as scored, and with
`components` it checks difficulty models and item families too.
[`validity_argument()`](https://www.okanbulut.com/mirtverse/reference/validity_argument.md)
maps the results to the inferences of a validity argument and lists the
evidence still owed, such as human oversight and appeals.

### Simulate respondents (experimental)

``` r

items <- itemtext[endsWith(itemtext$id, "-01"), ]
syn <- simulate_llm_respondents(items, personas)   # one request per described respondent
compare_synthetic(syn, setNames(items$p_field, items$id))
```

[`simulate_llm_respondents()`](https://www.okanbulut.com/mirtverse/reference/simulate_llm_respondents.md)
asks a language model to answer items as described test takers would,
and
[`compare_synthetic()`](https://www.okanbulut.com/mirtverse/reference/compare_synthetic.md)
checks the answers against real data. Both are experimental: Simulated
respondents tend to find items too easy, to answer alike when they are
described alike and to play stereotypes, so they can help find unclear
items but cannot replace a field test. The book’s [chapter on large
language models](https://www.okanbulut.com/mirtverse/book/llms.md) runs
the example from the recordings, with the twelve personas in
`examples.R`.

### Score open-ended responses, and check the scores

``` r

q <- score_open(q, responses, scorer = "llm")   # or a trained model
q$agreement                                     # machine-human agreement
flags(q)                                        # agreement and fairness gates
```

The full example in `examples.R` scores 40 answers from the `essays`
data against a four-point rubric.

To train your own engine instead of calling a language model, use
[`train_scorer()`](https://www.okanbulut.com/mirtverse/reference/train_scorer.md).
It learns from human-scored answers, runs offline, and works with
[`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md)
like any other trained model:

``` r

e1 <- essays[essays$prompt == "E1", ]
engine <- train_scorer(e1[1:300, ])                 # words and phrases -> human score
test <- e1[301:400, ]
agreement_report(predict(engine, test), test$human1, test$human2,
                 group = test$group)                # QWK, SMD and PRMSE by group
```

Machine scores pass the same gates whether they come from a language
model or from a model you trained yourself: Quadratic weighted kappa
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
  are longer at the same score; `aigfield` is a field test of 60 items
  generated from six item models; `aiscored` is a test whose written
  answers an engine scored for two years.

## For instructors

[Lab 6](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md),
on scoring open-ended responses, compares an automated engine with human
raters and fits well at the end of an IRT course. [Lab
7](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#lab-7)
goes further: Students train their own engine, judge it on new students,
find why it underscores English language learners, and decide how much
of the scoring it should do. In [Lab
8](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#lab-8)
they predict item difficulty from the text of 192 numeracy items, find
miskeyed items and near-duplicates, catch a leaky feature, and decide
how far predictions can replace a field test. [Lab
9](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#lab-9)
builds an item factory: Students fix an item model, calibrate a field
test of generated items, find the two families that are not isomorphic
and why, and decide when a family mean can stand in for a field test. In
[Lab
10](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#lab-10)
they audit an AI-scored test before its scores are released, and turn
the audit into a validity argument for a technical advisory committee.
The [online book](https://www.okanbulut.com/mirtverse/book/index.md) has
a part on AI in measurement whose chapters work offline, so they can be
assigned as readings. The [course
map](https://www.okanbulut.com/mirtverse/articles/course-map.html#ai-module)
puts the chapters and labs together as a four-week module or a one-day
workshop, and the [workshop
kit](https://www.okanbulut.com/mirtverse/articles/ai-workshop.md) has
slides and a facilitator’s guide for the day. To teach the same topics
on your own items or your own engine’s scores, the [instructor
toolkit](https://www.okanbulut.com/mirtverse/articles/instructor-toolkit.html#ai-sections)
builds labs with AI sections on your data, and the [teaching
assistant](https://www.okanbulut.com/mirtverse/articles/instructor-mcp.md)
can build them for you.

## Read more

The [reading
list](https://www.okanbulut.com/mirtverse/articles/ai-reading.md)
collects the books, papers and guidelines behind each step of the path,
with a sentence on why each is worth reading. Start with the overviews
at the top.
