# Style guide for chapters and lecture notes

Chapters (in `chapters/`) are R Markdown files that read like a short
textbook chapter or detailed lecture notes, in the style of the mirtverse
online book.

## Structure

1. A title (`# Title` or YAML `title:`) and a short opening that says what
   the reader will learn and why it matters.
2. **Concepts** before code: Define each term in plain words, with a formula
   only where it helps, and link to the mirtverse glossary
   (https://www.okanbulut.com/mirtverse/articles/glossary.html) for terms.
3. **Worked example**: Load data, fit, look, interpret. Each code chunk is
   followed by a paragraph that reads the output.
4. **Try it yourself**: Two or three short exercises with the answers hidden
   at the end of the chapter (or in a separate answer key).
5. **Summary**: Three to five bullet points.

## Data chunks

Chunks that load the example data are labelled `data-<chapter>-<n>` so the
toolkit's `swap_chapter_data` can replace them with an instructor's own
data. Keep every later chunk working from the objects those chunks create
(for example `resp` for the item responses and `group` for a grouping
variable), so swapping data does not break the chapter.

## Code

- Start with `library(mirtverse)` (it loads mirt).
- Prefer the mirtverse layer for students: `select_model()`, `tidy()`,
  `item_table()`, `gg_trace()`, `gg_info()`, `gg_itemfit()`, `augment()`,
  `dif()`, `interpret()`. Show the underlying mirt call when the chapter
  teaches mirt.
- Use `verbose = FALSE` in model fitting chunks, set a seed for anything
  random, and keep chunks fast (under a minute each).
- Look every function up with `mirtverse_help` before using it.
