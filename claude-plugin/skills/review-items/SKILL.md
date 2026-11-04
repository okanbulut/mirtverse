---
name: review-items
description: Review the quality of individual test items after an IRT analysis with mirtverse and recommend what to keep, revise or drop. Use when the user asks which items are bad, weak, misfitting, too easy or too hard, or wants item-by-item feedback for test revision or an item bank.
---

# Review items

Use the `mirtverse` MCP tools. If no model exists yet, run the
`analyze-test` skill through step 3 first.

1. `check_items` on the model, and `guide` topic `interpreting` (Items).
2. `plot_model` with `type = "trace"` and `items` set to the flagged items
   (at most about six per plot), and `type = "itemfit"`. View the images.
3. If the user has the item text (stems, options, keys) in a file, read it
   and connect the statistics to the content: A low or negative item-total
   correlation often means a miskeyed item or two defensible answers; a very
   high discrimination can mean a near-duplicate item; a guessing parameter
   far above 1/options suggests a clue in the stem.
4. Give an item-by-item table: Item, verdict (keep, revise, review key,
   drop candidate), evidence (numbers), and a concrete suggestion.
5. If the user wants to try dropping items, refit with `fit_model` on the
   remaining `items` under a new `name`, then compare reliability, fit and
   test information between the two models (`plot_model` `test_info` for
   both). Removing items lowers precision; say by how much.
6. `save_script`.
