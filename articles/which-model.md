# Which IRT model? A one-page flowchart

Choosing a model is the first real decision in an IRT analysis, and the
one a committee or a technical advisory panel asks about first. The
flowchart below starts from what a single item score looks like, asks
one or two questions, and ends at a model and the `itemtype` that fits
it in mirt.

[Download the poster
(PDF)](https://www.okanbulut.com/mirtverse/which-model/which-irt-model.pdf)
[Open it as an
image](https://www.okanbulut.com/mirtverse/which-model/which-irt-model.png)

[![Flowchart: What does one item's score look like? Right or wrong items
lead to the 3PL, Rasch or 2PL model; ordered categories lead to the
generalized partial credit, rating scale or graded response model;
unordered options lead to the nominal response model; ideal-point
attitude items lead to the GGUM. A side box suggests select_model() when
unsure, and a row of cards covers dimensionality, testlets, groups, item
features, response times and latent
classes.](../which-model/which-irt-model.png)](https://www.okanbulut.com/mirtverse/which-model/which-irt-model.pdf)

The poster is US Letter, landscape, and prints well in colour or
greyscale. The QR code links back to this page. Feel free to put it on a
classroom wall, in a course pack or on a conference poster.

## Not sure? Let the data compare

If the questions do not settle it, fit the usual candidates and compare
them.
[`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md)
picks the candidates from the data (Rasch, 2PL and 3PL for 0/1 items;
partial credit, generalized partial credit and graded for ordered
items), ranks them by BIC, runs likelihood-ratio tests between nested
models, and explains its pick:

``` r

library(mirtverse)
sel <- select_model(expand.table(LSAT7))
sel            # comparison table and a plain-language explanation
mod <- sel$best
interpret(mod)
```

The statistics are only half of the decision. The purpose of the test
matters too: A Rasch model can be the right choice even when a 2PL fits
a little better, because it keeps the sum score as the whole story.

## Right or wrong (0/1) items

**Could low scorers guess the right answer?** On multiple-choice items
with a few options, they often can. The 3PL adds a lower asymptote for
guessing, but it needs large samples (about 1,000 people or more) to
estimate well.

``` r

data <- expand.table(LSAT7)
mod3 <- mirt(data, 1, itemtype = "3PL")
```

**Should every item count the same in the score?** If yes, use the Rasch
model: All items share one slope, the sum score carries all the
information about ability, and it works with smaller samples (from about
100 people). If items should be allowed to discriminate differently, use
the 2PL (aim for about 500 people or more).

``` r

mod1 <- mirt(data, 1, itemtype = "Rasch")
mod2 <- mirt(data, 1, itemtype = "2PL")
anova(mod1, mod2)   # does the extra slope per item pay off?
gg_trace(mod2)
```

## Ordered categories

**Are points earned step by step on a rubric?** For constructed
responses and tasks scored 0, 1, 2 and so on, the generalized partial
credit model treats each score as a step. Its Rasch version, the partial
credit model, is `itemtype = "Rasch"` in mirt when items have more than
two categories.

``` r

mod_gpcm <- mirt(Science, 1, itemtype = "gpcm")
mod_pcm  <- mirt(Science, 1, itemtype = "Rasch")
```

**Same rating scale on every item, and a Rasch model wanted?** The
rating scale model gives all items the same set of thresholds, which
makes it the most compact choice. Otherwise, the graded response model
is the usual pick for Likert scales.

``` r

mod_rsm <- mirt(Science, 1, itemtype = "rsm")
mod_grm <- mirt(Science, 1, itemtype = "graded")
gg_trace(mod_grm)
```

## Unordered options

When you care about which wrong option a person chose, keep the raw
responses and fit the nominal response model. It shows which distractors
attract lower-ability test takers and which ones do not work. `SAT12`
stores the raw option chosen (1 to 5) for 32 items.

``` r

raw <- SAT12
raw[raw == 8] <- NA            # 8 marks an omitted item
mod_nom <- mirt(raw, 1, itemtype = "nominal")
gg_trace(mod_nom, items = 1:4)
```

## Agree only if close (unfolding)

Some attitude statements describe a middle position, such as “Social
media is fine in moderation”. People on both extremes disagree with it,
for opposite reasons. Ideal-point (unfolding) models handle this, and
the generalized graded unfolding model (GGUM) is available in mirt:

``` r

mod_ggum <- mirt(Science, 1, itemtype = "ggum")
```

## Then think about the structure

Each of these questions adds one argument or one function to the model
you picked above.

| Question | What to do | Learn more |
|----|----|----|
| More than one trait? | Check local dependence with `gg_q3(mod)`, then fit `mirt(data, 2)` or a confirmatory [`mirt.model()`](https://philchalmers.github.io/mirt/reference/mirt.model.html) | [Glossary: Dimensionality](https://www.okanbulut.com/mirtverse/articles/glossary.html#dimensionality) |
| Items in clusters (testlets, shared passages)? | A general factor plus specific factors with `bfactor(data, specific)` | [`?bfactor`](https://philchalmers.github.io/mirt/reference/bfactor.html) |
| Groups to compare? | Screen items with `dif(mod, group)`, then put groups on one scale with [`multipleGroup()`](https://philchalmers.github.io/mirt/reference/multipleGroup.html) | [Lab 3: DIF](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md) |
| Item features explain difficulty? | Explanatory IRT (LLTM) with [`predict_difficulty()`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md), the [eirm](https://CRAN.R-project.org/package=eirm) package or [`mixedmirt()`](https://philchalmers.github.io/mirt/reference/mixedmirt.html) | [Book: Item text](https://www.okanbulut.com/mirtverse/book/item-text.md) |
| Response times too? | Model speed together with ability with `fit_rt(mod, rt)` | [Response times](https://www.okanbulut.com/mirtverse/articles/response-times.md) |
| Classes rather than a continuum? | Mastery groups or latent classes with `mdirt(data, 2)` | [`?mdirt`](https://philchalmers.github.io/mirt/reference/mdirt.html) |

## Before you trust the model

Whatever path you took, check the result before you report it:

``` r

glance(mod)       # overall fit: M2, RMSEA, CFI, SRMSR
gg_itemfit(mod)   # items that misfit
gg_trace(mod)     # curves that look strange
interpret(mod)    # a plain-language summary
```

A simpler model that fits is easier to explain. Move to a richer one
only when the fit checks or the purpose of the test call for it. The
[thesis kit](https://www.okanbulut.com/mirtverse/articles/thesis-kit.md)
turns these checks into a Methods paragraph.

## A note on sample sizes

The sample sizes on the poster are rough rules of thumb drawn from the
IRT literature, not guarantees. More items, well-targeted items and
simpler models all need fewer people; the 3PL and the nominal model need
the most. When in doubt, simulate:
[`simdata()`](https://philchalmers.github.io/mirt/reference/simdata.html)
in mirt can show how well your planned sample recovers the parameters.
