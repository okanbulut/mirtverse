# Build a lab from your own data

`new_lab()` writes an interactive lab (a learnr tutorial) that walks
students through an IRT analysis of *your* dataset: The data, classical
item statistics, dimensionality, model comparison, item fit,
information, scoring and, when you give a grouping variable, DIF. With
`item_info` or `scores` it can also teach AI in measurement on your
data: What the item text says about difficulty, how equally difficult
the items of each item family are, and whether machine scores agree with
human scores. Every number in the text, every answer check and every
multiple-choice question is computed from the data when the lab is
rendered, so the same lab works with any dataset and
[`swap_lab_data()`](https://www.okanbulut.com/mirtverse/reference/swap_lab_data.md)
can replace the data later without touching the text.

## Usage

``` r
new_lab(
  name,
  data,
  course = ".",
  items = NULL,
  group = NULL,
  key = NULL,
  item_info = NULL,
  scores = NULL,
  title = NULL,
  data_title = NULL,
  story = NULL,
  sections = NULL,
  overwrite = FALSE
)
```

## Arguments

- name:

  the lab's name: Letters, digits, `-` and `_`.

- data:

  the responses: A data frame or matrix, or the path of a file (`.csv`,
  `.tsv`, `.txt`, `.xlsx`, `.xls`, `.sav`, `.dta`, `.sas7bdat` or
  `.rds`). Items must be scored 0/1 or in ordered integer categories,
  unless you give a `key`. A frequency table (one row per response
  pattern with a `freq` or `count` column, such as
  [mirt::LSAT7](https://philchalmers.github.io/mirt/reference/LSAT7.html))
  is expanded to one row per person.

- course:

  the course folder (see
  [`new_course()`](https://www.okanbulut.com/mirtverse/reference/new_course.md));
  the lab goes in its `labs/` folder.

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

- title:

  the lab's title.

- data_title:

  a short name for the data used in the lab's text, for example
  `"the Grade 8 science test"`.

- story:

  a paragraph that sets the scene, shown at the start of the lab.

- sections:

  the sections to include, in order; see
  [`lab_section_types()`](https://www.okanbulut.com/mirtverse/reference/lab_section_types.md).
  The default includes every section that suits the data: `"dif"` only
  with a `group`, and the AI sections only when `item_info` or `scores`
  provide what they need.

- overwrite:

  replace an existing lab of the same name.

## Value

The path of the lab folder, invisibly.

## Details

The lab is a folder `labs/<name>/` inside the course folder, holding
`<name>.Rmd` and a `data/` folder (`responses.rds` and `lab.json`). Edit
the `.Rmd` freely;
[`add_lab_section()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md),
[`add_lab_exercise()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
and
[`add_lab_question()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
add content, and
[`check_material()`](https://www.okanbulut.com/mirtverse/reference/check_material.md)
runs every exercise's solution through its check.

## See also

[`new_course()`](https://www.okanbulut.com/mirtverse/reference/new_course.md),
[`swap_lab_data()`](https://www.okanbulut.com/mirtverse/reference/swap_lab_data.md),
[`add_lab_section()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md),
[`check_material()`](https://www.okanbulut.com/mirtverse/reference/check_material.md),
[`preview_lab()`](https://www.okanbulut.com/mirtverse/reference/preview_lab.md)

## Examples

``` r
course <- file.path(tempdir(), "lab-demo")
new_course(course)
lab <- new_lab("lsat", data = expand.table(LSAT7), course = course,
               data_title = "the LSAT section 7 items",
               sections = c("intro", "classical", "models", "wrap-up"))
lab_outline(lab)
#> # A tibble: 4 × 5
#>   id        type      title                     exercises questions
#>   <chr>     <chr>     <chr>                         <int>     <int>
#> 1 intro     intro     Meet the data                     1         0
#> 2 classical classical Classical item statistics         2         1
#> 3 models    models    Compare IRT models                2         1
#> 4 wrap-up   wrap-up   Where to next                     0         0

# an AI lab: item text and item families of 60 generated items
lab2 <- new_lab("aig", data = aigfield, course = course,
                item_info = transform(aigfield_items, family = model),
                data_title = "the generated items",
                sections = c("intro", "item-features", "aig", "wrap-up"))
lab_outline(lab2)
#> # A tibble: 4 × 5
#>   id            type          title                       exercises questions
#>   <chr>         <chr>         <chr>                           <int>     <int>
#> 1 intro         intro         Meet the data                       1         0
#> 2 item-features item-features What the item text tells us         2         3
#> 3 aig           aig           Item families                       2         2
#> 4 wrap-up       wrap-up       Where to next                       0         0
```
