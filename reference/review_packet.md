# Pipeline stage: item review

Items, whether written by people or generated, need human content and
sensitivity (bias) review before they are field-tested.
`review_packet()` writes a review form (a CSV file that opens in a
spreadsheet) with one row per item and reviewer, ready for reviewers to
fill in. `read_reviews()` reads their decisions back, sets each item's
status (`"approved"`, `"revise"` or `"rejected"`, by majority) and runs
the review checks.

## Usage

``` r
review_packet(
  p,
  file = "review-packet.csv",
  reviewers = NULL,
  ai_screen = FALSE,
  provider = NULL,
  model = NULL
)

read_reviews(p, reviews)
```

## Arguments

- p:

  a pipeline with items from
  [`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
  or
  [`add_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md).

- file:

  path of the CSV file to write.

- reviewers:

  optional reviewer names; the packet then has one row per item and
  reviewer.

- ai_screen:

  logical; screen items with a language model first.

- provider, model:

  the language model for the screen.

- reviews:

  the completed packet: a path to the CSV file or a data frame with
  columns `id`, `reviewer`, `decision` (`accept`, `revise` or `reject`),
  `aligned` (`yes`/`no`), `sensitivity` (`yes`/`no`) and optionally
  `comment`. Rows with an empty decision are ignored.

## Value

`review_packet()` returns the pipeline (with the screen's notes in
`p$items$ai_screen`) invisibly and writes `file`.

`read_reviews()` returns the pipeline with the reviews in `p$reviews`,
an agreement summary in `p$review_agreement`, and the items' status
updated.

## Details

With `ai_screen = TRUE`, a language model (see
[`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md))
first screens every item for possible bias, sensitivity and
accessibility problems; its notes go into the packet for reviewers to
weigh. The screen assists reviewers and does not replace them.

The checks (thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

- `under_reviewed` (block): an item reviewed by fewer than
  `min_reviewers` reviewers.

- `alignment` (review): a reviewer does not agree the item measures its
  blueprint cell.

- `sensitivity` (review): a reviewer (or the AI screen) raised a bias or
  sensitivity concern.

- `needs_revision` (review): reviewers asked for the item to be revised.

- `reviewer_agreement` (info): Fleiss' kappa for the reviewers'
  decisions is below `review_kappa`.

- `provenance` (info): an item without a recorded source (person or
  model), which testing programs now need to disclose.

## Examples

``` r
items <- data.frame(stem = c("2 + 2 = ?", "3 x 3 = ?"), A = c("4", "6"),
                    B = c("5", "9"), key = c("A", "B"), cell = "Arithmetic")
p <- add_items(mv_pipeline(verbose = FALSE), items)
f <- tempfile(fileext = ".csv")
p <- review_packet(p, f, reviewers = c("Ana", "Ben"))
rv <- utils::read.csv(f)
rv$decision <- "accept"; rv$aligned <- "yes"; rv$sensitivity <- "no"
p <- read_reviews(p, rv)
p$items$status
#> [1] "approved" "approved"
```
