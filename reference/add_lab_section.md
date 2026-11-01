# Add, remove and list the sections of a lab

`add_lab_section()` adds one of the ready-made sections in
[`lab_section_types()`](https://www.okanbulut.com/mirtverse/reference/lab_section_types.md).
`add_lab_exercise()` adds a coding exercise you write yourself, and
`add_lab_question()` a multiple-choice question. `remove_lab_section()`
deletes a section and `lab_outline()` lists them.

## Usage

``` r
add_lab_section(lab, type, after = NULL, id = NULL)

add_lab_exercise(
  lab,
  title,
  prompt,
  solution,
  starter = NULL,
  check = NULL,
  hint = NULL,
  use_fit = FALSE,
  after = NULL,
  id = NULL
)

add_lab_question(
  lab,
  question,
  answers,
  correct,
  messages = NULL,
  title = NULL,
  after = NULL,
  id = NULL
)

remove_lab_section(lab, id)

lab_outline(lab)
```

## Arguments

- lab:

  the lab folder (or its `.Rmd` file).

- type:

  the kind of section; see
  [`lab_section_types()`](https://www.okanbulut.com/mirtverse/reference/lab_section_types.md).

- after:

  the `id` of the section to put the new one after (see
  `lab_outline()`).

- id:

  the new section's id, used in its chunk labels. Defaults to the type
  (for `add_lab_section()`) or a slug of the title, made unique.

- title:

  the section heading.

- prompt:

  the instructions students read, in Markdown (a character vector is
  joined with line breaks).

- solution:

  R code that solves the exercise.

- starter:

  R code students start from, for example with a blank to fill. Defaults
  to an empty exercise box.

- check:

  R code that checks the student's result, run after their code. Use
  `lab_need(condition, "message")` to fail with a message, and `.result`
  for the value of the student's last line; the last value, if a string,
  is shown on success. Defaults to accepting any code that runs.

- hint:

  optional hint (R code or comments).

- use_fit:

  logical; start from the lab's fitted one-factor model `fit` (labs made
  with
  [`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)
  only).

- question:

  the question text.

- answers:

  the answer options (character).

- correct:

  which answers are correct: their positions in `answers`, or the
  answers themselves. More than one makes a check-all-that-apply
  question.

- messages:

  optional feedback for each answer, in the same order.

## Value

`lab_outline()` returns a tibble with one row per section: `id`, `type`
(`"built-in"` for unmarked sections), `title`, and the number of
`exercises` and `questions` in it. The other functions return the `.Rmd`
path, invisibly.

## Details

Sections start with a level-2 heading (`## `), marked by an
`<!-- mv-section: ... -->` comment in labs made with the toolkit. These
functions also work on copies of the built-in labs made with
[`copy_lab()`](https://www.okanbulut.com/mirtverse/reference/copy_lab.md),
whose sections are identified by their headings.

New content goes before the lab's `"wrap-up"` section if it has one,
otherwise at the end, unless you name a section in `after`.

## See also

[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md),
[`check_material()`](https://www.okanbulut.com/mirtverse/reference/check_material.md)

## Examples

``` r
course <- file.path(tempdir(), "sections-demo")
lab <- new_lab("demo", data = expand.table(LSAT7), course = course,
               sections = c("intro", "wrap-up"))
add_lab_section(lab, "classical")
add_lab_exercise(lab, title = "Total scores",
  prompt = "Compute each person's total score and save it as `total`.",
  solution = "total <- rowSums(resp)",
  check = c("lab_need(exists('total'), 'Save the totals as `total`.')",
            "lab_need(length(total) == nrow(resp), 'One total per person.')",
            "'Well done.'"))
add_lab_question(lab, "What does a low item mean tell you?",
  answers = c("The item is hard", "The item is easy"), correct = 1)
lab_outline(lab)
#> # A tibble: 5 × 5
#>   id                               type      title           exercises questions
#>   <chr>                            <chr>     <chr>               <int>     <int>
#> 1 intro                            intro     Meet the data           1         0
#> 2 classical                        classical Classical item…         2         1
#> 3 total-scores                     exercise  Total scores            1         0
#> 4 q-what-does-a-low-item-mean-tell question  Check your und…         0         1
#> 5 wrap-up                          wrap-up   Where to next           0         0
remove_lab_section(lab, "classical")
```
