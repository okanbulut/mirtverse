# Pipeline stage: item generation

`generate_items()` writes candidate items for the blueprint's cells with
a large language model through the ellmer package, using the provider
set up with
[`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md)
(Claude, OpenAI or a local Ollama model). Multiple-choice items come
with a key and a rationale for every option; open-ended items come with
a scoring rubric that has a descriptor and an anchor response for every
score point. `add_items()` adds items written by people (or another
generator) to the same pool, so the checks treat both alike.

## Usage

``` r
generate_items(
  p,
  n = NULL,
  cells = NULL,
  type = NULL,
  n_options = 4,
  instructions = NULL,
  provider = NULL,
  model = NULL,
  verify = TRUE,
  batch = 5
)

add_items(p, items)

verify_items(p, ids = NULL, provider = NULL, model = NULL, .rerun = TRUE)
```

## Arguments

- p:

  a pipeline; `generate_items()` needs a blueprint from
  [`set_blueprint()`](https://www.okanbulut.com/mirtverse/reference/set_blueprint.md).

- n:

  number of items to write per cell and item type. Defaults to
  `coverage_ratio` times the cell's target count, less the items the
  cell already has.

- cells:

  optional cells to write for (by name, as in `p$blueprint$cells$cell`);
  defaults to all.

- type:

  item types to write; defaults to the blueprint's.

- n_options:

  number of options of a multiple-choice item.

- instructions:

  optional extra instructions for the item writer, such as a style guide
  or a reading passage.

- provider, model:

  the language model; see
  [`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md).

- verify:

  logical; run the verifying pass on multiple-choice items.

- batch:

  number of items to ask for in one call.

- items:

  for `add_items()`, a data frame with one row per item and columns
  `stem`, `cell`, `type` (`"mc"` or `"open"`, default `"mc"`), the
  options either as a list column `options` or as columns `A`, `B`, `C`,
  ..., `key` (the letter of the correct option), and optionally `id`,
  `rubric` (a list column of data frames with columns `score`,
  `descriptor` and `anchor`) and `source` (default `"human"`).

- ids:

  items to verify; defaults to every multiple-choice item not yet
  verified.

- .rerun:

  internal.

## Value

The pipeline with the new items in `p$items`: a tibble with one row per
item (`id`, `cell`, `type`, `stem`, `options`, `key`, `rationales`,
`rubric`, `max_score`, `grade`, `source`, `status` and the verification
results).

## Details

With `verify = TRUE` (the default), a second, independent model call
answers each multiple-choice item without seeing the key and judges each
distractor (`verify_items()` runs this pass on its own).

The checks (thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

- `invalid_key` (block): a multiple-choice key that is not one of the
  options.

- `key_check` (block): the verifying pass chose another answer, or found
  more than one defensible answer.

- `rubric_incomplete` (block): an open-ended item without a descriptor
  and an anchor response for every score point from 0 to the maximum.

- `distractor` (review): a distractor the verifying pass judged
  implausible or partly correct.

- `near_duplicate` (review): two items whose wording overlaps by more
  than `duplicate_sim` (Jaccard similarity of their words).

- `coverage` (review): a blueprint cell with fewer than `coverage_ratio`
  times its target count of items (items are lost in review and field
  testing).

- `readability` (info): item text above the blueprint's grade level
  (Flesch-Kincaid grade).

Generated items are drafts: they need human content and sensitivity
review before they are field-tested, and every item records its source.

## Examples

``` r
if (FALSE) { # \dontrun{
p <- set_blueprint(mv_pipeline(), c(Fractions = 4, Decimals = 4),
                   construct = "Grade 5 number sense", use = "diagnostic",
                   population = "Grade 5 students", grade_level = 5)
p <- generate_items(p, n = 3)
p$items
flags(p)
} # }
```
