# Replace the data in a toolkit lab

Swaps the responses behind a lab made with
[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)
for another dataset, for example next year's class or your own test. The
lab's text, answer checks and questions are computed from the data, so
nothing else needs to change. Settings you leave out (`group`,
`data_title`, `story`) are kept from the current data, except that
`items` and `key` are always worked out again. The `item_info` and
`scores` of the AI sections are kept unless you give new ones. Run
[`check_material()`](https://www.okanbulut.com/mirtverse/reference/check_material.md)
afterwards.

## Usage

``` r
swap_lab_data(
  lab,
  data,
  items = NULL,
  group = NULL,
  key = NULL,
  item_info = NULL,
  scores = NULL,
  data_title = NULL,
  story = NULL
)
```

## Arguments

- lab:

  the lab folder.

- data:

  the responses: A data frame or matrix, or the path of a file (`.csv`,
  `.tsv`, `.txt`, `.xlsx`, `.xls`, `.sav`, `.dta`, `.sas7bdat` or
  `.rds`). Items must be scored 0/1 or in ordered integer categories,
  unless you give a `key`. A frequency table (one row per response
  pattern with a `freq` or `count` column, such as
  [mirt::LSAT7](https://philchalmers.github.io/mirt/reference/LSAT7.html))
  is expanded to one row per person.

- items:

  the item columns, by name or position. By default, every column whose
  values are whole numbers from 0 to 9 (other than `group` and ID-like
  columns), or the names of a named `key`.

- group:

  optional grouping variable with two values, for the DIF section: A
  column name of `data`, or a vector with one value per row.

- key:

  optional answer key for unscored multiple-choice responses, one value
  per item; the items are scored with
  [`mirt::key2binary()`](https://philchalmers.github.io/mirt/reference/key2binary.html).

- item_info:

  optional data frame (or the path of a data file) with one row per
  item, for the AI sections. It needs a column `item` (or `id`) with the
  item names used in `data`. A `stem` column (and, for multiple-choice
  items, option columns `A` to `E` and a `key` column with the letter of
  the keyed option) enables the `"item-features"` section; a `family`
  column naming each item's item model or family enables the `"aig"`
  section.

- scores:

  optional data frame (or the path of a data file) of machine scores of
  constructed responses, for the `"ai-scoring"` section: One row per
  scored response, with columns `machine` and `human1` (the human score,
  `NA` where no person read the response) and, optionally, `human2` (a
  second reading), `group` (for fairness checks), `item` and `period`
  (an administration or engine version, for drift checks). Rename your
  columns to these names first.

- data_title:

  a short name for the data used in the lab's text, for example
  `"the Grade 8 science test"`.

- story:

  a paragraph that sets the scene, shown at the start of the lab.

## Value

The lab folder, invisibly.

## Details

If the lab has a DIF section and the new data have no `group`, the DIF
section will fail; remove it with
[`remove_lab_section()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md).

## See also

[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md),
[`lab_data()`](https://www.okanbulut.com/mirtverse/reference/lab_data.md)

## Examples

``` r
course <- file.path(tempdir(), "swap-demo")
lab <- new_lab("demo", data = expand.table(LSAT7), course = course,
               sections = c("intro", "classical"))
swap_lab_data(lab, data = expand.table(LSAT6), data_title = "the LSAT section 6 items")
lab_data(file.path(lab, "data"))$info$data_title
#> [1] "the LSAT section 6 items"
```
