# The instructor toolkit

mirtverse comes with six [teaching
labs](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md), a
[course map](https://www.okanbulut.com/mirtverse/articles/course-map.md)
and a
[glossary](https://www.okanbulut.com/mirtverse/articles/glossary.md).
They are written around the package’s own datasets. The instructor
toolkit is for the next step: Teaching with **your** data, **your**
examples and **your** course’s order of topics, without writing a learnr
tutorial from scratch.

With the toolkit you can:

- keep all of a course’s materials in one folder
  ([`new_course()`](https://www.okanbulut.com/mirtverse/reference/new_course.md));
- build an interactive lab on any response dataset in one call
  ([`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)),
  with text, answer checks and quiz questions that adapt to the data;
- add ready-made sections, your own coding exercises and your own
  multiple-choice questions
  ([`add_lab_section()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md),
  [`add_lab_exercise()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md),
  [`add_lab_question()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md));
- replace a lab’s data, for example with next year’s class
  ([`swap_lab_data()`](https://www.okanbulut.com/mirtverse/reference/swap_lab_data.md));
- copy and edit a built-in lab
  ([`copy_lab()`](https://www.okanbulut.com/mirtverse/reference/copy_lab.md))
  or a chapter of the mirtverse book
  ([`copy_chapter()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md),
  [`swap_chapter_data()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md));
- check that every exercise’s solution passes its own check before
  students see it
  ([`check_material()`](https://www.okanbulut.com/mirtverse/reference/check_material.md)),
  and try the lab yourself
  ([`preview_lab()`](https://www.okanbulut.com/mirtverse/reference/preview_lab.md)).

Every function takes file paths, returns what it wrote, and never asks a
question, so you can also drive the toolkit from a script or an AI
assistant.

You need mirtverse and learnr:

``` r

install.packages("learnr")
library(mirtverse)
```

## 1. Start a course folder

``` r

new_course("EDPY507", title = "EDPY 507: Item response theory",
           instructor = "Your Name")
```

This creates:

| Path | What it holds |
|----|----|
| `course.json` | The course title and instructor. |
| `README.md` | A short how-to for whoever opens the folder next (a TA, or you next year). |
| `labs/` | One folder per interactive lab, each with an `.Rmd` file and a `data/` folder. |
| `chapters/` | Notes chapters (R Markdown), one file each. |
| `data/` | Your raw data files, kept for reference. |

The rest of this page assumes your R session is in the course folder
(`setwd("EDPY507")`, or open it as an RStudio project). Every function
also takes a `course` argument if you prefer full paths.

[`course_materials()`](https://www.okanbulut.com/mirtverse/reference/new_course.md)
lists what is in the folder at any time, including labs and chapters you
add by hand:

``` r

course_materials()
#> # A tibble: 3 x 6
#>   name     type    title                                 path              source   data
#>   <chr>    <chr>   <chr>                                 <chr>             <chr>    <chr>
#> 1 midterm  lab     An IRT analysis of the midterm        ./labs/midterm    toolkit  the midterm
#> 2 w9       lab     Lab 3: Is the test fair? Detecting DIF ./labs/w9        built-in <NA>
#> 3 09-dif   chapter Differential item functioning ...     ./chapters/09-dif.Rmd book <NA>
```

## 2. Build a lab on your own data

Give
[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)
a name and your responses: A data frame, or a file (`.csv`, `.xlsx`,
`.sav`, `.dta`, `.sas7bdat` or `.rds`).

``` r

new_lab("midterm", data = "data/midterm-2026.csv",
        group = "language",
        data_title = "the EDPY 507 midterm",
        story = paste("The department wants to know whether the midterm worked:",
                      "which items were weak, which model to score it with,",
                      "and whether it was fair to students writing in French."))
```

What the data need:

- **Scored items.** Items scored 0/1, or in ordered categories 0, 1, 2
  and so on (a lab on polytomous items compares the partial credit and
  graded response models instead of the Rasch model and the 2PL). For
  unscored multiple-choice responses, give the answer key in `key` and
  the items are scored for you.
- **Item columns.** By default every column with whole-number scores
  from 0 to 9 is treated as an item. ID columns and the `group` column
  are left out. Name the items yourself with
  `items = c("Q1", "Q2", ...)` or `items = 3:42` when the guess is
  wrong.
- **An optional group** with exactly two values (a column name, or a
  vector with one value per row) turns on the DIF section.
- **At least about 200 people** for stable estimates;
  [`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)
  warns below that. Missing responses are fine.

The data are copied into the lab’s `data/` folder, so the lab works on
any computer without your original file.

### What students get

By default the lab has every section that suits the data, in this order.
Choose and order them yourself with `sections =`.

``` r

lab_section_types()
```

| Section | What students do |
|----|----|
| `intro` | Read your story, see the size of the data and look at the responses. |
| `classical` | Compute item means; read item-total correlations; find the weakest item. |
| `dimensionality` | Compare one- and two-factor models with [`anova()`](https://rdrr.io/r/stats/anova.html) and BIC. |
| `models` | Compare the Rasch model with the 2PL (or the graded model); try [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md). |
| `item-fit` | Run [`itemfit()`](https://philchalmers.github.io/mirt/reference/itemfit.html) and [`gg_itemfit()`](https://www.okanbulut.com/mirtverse/reference/gg_itemfit.md); count the misfitting items. |
| `information` | Plot test information and the standard error; say where the test is precise. |
| `scoring` | Estimate EAP scores and compare them with sum scores. |
| `dif` | Run likelihood-ratio DIF tests with [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md) (needs a `group`). |
| `reflection` | Write a recommendation (free text, good for a short assignment). |
| `wrap-up` | A summary and pointers to reports and the other labs. |

Nothing in these sections is written for one dataset. The numbers in the
text, the checks on students’ code and the right answers to the quiz
questions (“Which item has the lowest item-total correlation?”, “Which
model does BIC prefer?”, “How many items misfit?”) are all computed from
the data when the lab is built. That is what lets you reuse the same lab
next term with new data.

## 3. Add your own content

### Ready-made sections

``` r

add_lab_section("labs/midterm", "dif")
add_lab_section("labs/midterm", "information", after = "models")
```

New sections go before the `wrap-up` section unless you say where with
`after`.
[`lab_outline()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
shows each section’s `id`, which is what `after` and
[`remove_lab_section()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
use:

``` r

lab_outline("labs/midterm")
remove_lab_section("labs/midterm", "dimensionality")
```

### Your own coding exercises

[`add_lab_exercise()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
adds a section with an exercise box, an optional hint, a solution and a
check. Inside every toolkit lab, the scored responses are `resp`, the
group (if any) is `group`, and `models` holds the two item types the lab
compares. With `use_fit = TRUE` the exercise also starts from `fit`, a
one-factor model of the data.

``` r

add_lab_exercise("labs/midterm",
  title = "The hardest items",
  prompt = c("Which five items had the lowest mean score?",
             "Save their names as `hardest`."),
  starter = "hardest <- ",
  hint = "# sort(colMeans(resp, na.rm = TRUE)) puts the hardest items first",
  solution = "hardest <- names(sort(colMeans(resp, na.rm = TRUE)))[1:5]",
  check = c(
    "expected <- names(sort(colMeans(resp, na.rm = TRUE)))[1:5]",
    "lab_need(exists('hardest'), 'Save the item names as `hardest`.')",
    "lab_need(setequal(hardest, expected), 'Not quite: sort the item means from low to high.')",
    "'Right. Look at these items before the next exam.'"))
```

The check runs after the student’s code, in the same environment, so it
can see every object the student made. `lab_need(condition, message)`
fails the exercise with your message when the condition is not `TRUE`;
`.result` holds the value of the student’s last line; and the last value
of the check, if it is a string, is shown when every condition passes.
Compute the expected answer from `resp` rather than typing it in, and
the exercise will keep working when the data change.

### Your own questions

``` r

add_lab_question("labs/midterm",
  question = "An item has a negative item-total correlation. What do you check first?",
  answers = c("The answer key", "The item's position on the test", "The sample size"),
  correct = 1,
  messages = c("Right: a miskeyed item is the most common cause.",
               "Position rarely reverses a correlation; check the key first.",
               "A small sample adds noise but rarely flips the sign; check the key first."))
```

Give more than one correct answer and students get a
check-all-that-apply question instead.

### Editing by hand

The lab is an ordinary learnr tutorial (`labs/midterm/midterm.Rmd`), so
you can open it in RStudio and change anything: Reword the text, add
images, move sections. The learnr documentation
(<https://pkgs.rstudio.com/learnr/>) covers exercises and questions in
detail. Two rules keep the toolkit functions working:

- keep the `<!-- mv-section: ... -->` comment above each section’s `##`
  heading, and
- keep chunk labels unique
  ([`check_material()`](https://www.okanbulut.com/mirtverse/reference/check_material.md)
  tells you if they are not).

## 4. Swap in other data

``` r

swap_lab_data("labs/midterm", data = "data/midterm-2027.csv",
              data_title = "the 2027 midterm")
check_material("labs/midterm")
```

The text, checks and questions are recomputed from the new data, and any
exercises you added keep working as long as their checks compute their
answers from `resp`. Settings you leave out are kept (for example the
`group` column and the story).

The built-in labs are different: Each tells the story of its own
dataset, with problems planted on purpose (a miskeyed item, a drifted
anchor, a severe rater), and the feedback talks about them. To teach the
same topic on your data, build a toolkit lab with the matching sections.
To keep the built-in story but change the wording, the order or the
questions, copy it:

``` r

copy_lab("fairness", as = "week9-fairness")
add_lab_question("labs/week9-fairness", ...)
```

## 5. Notes chapters

The [mirtverse book](https://www.okanbulut.com/mirtverse/book/) has one
chapter per week of the course map. Copy a chapter into your course to
edit it:

``` r

book_chapters()
copy_chapter("dif")    # downloads book/09-dif.Rmd into chapters/
```

Every example in a book chapter starts with a chunk labelled
`data-<chapter>-<n>` that loads the data and defines `resp`. Replace it
to run the example on your data:

``` r

swap_chapter_data("chapters/09-dif.Rmd", chunk = "data-dif-1",
                  code = c("midterm <- read.csv('../data/midterm-2026.csv')",
                           "resp <- midterm[, 3:42]",
                           "group <- midterm$language"))
```

Leave out `chunk` to replace every data chunk at once.
[`new_chapter()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)
starts an empty chapter with the book’s headings (learning goals, key
terms, two examples, exercises, the matching lab and further reading).

## 6. Check, preview and share

``` r

res <- check_material("labs/midterm")
res[res$status != "pass", ]
```

[`check_material()`](https://www.okanbulut.com/mirtverse/reference/check_material.md)
works on a copy of the lab, so nothing in your folder changes. It checks
the chunk labels, loads the data, runs every chunk that runs when the
lab is built (including the quiz questions), and runs each exercise’s
solution followed by its check, so it catches a solution that its own
check rejects. Add `render = TRUE` to build the whole tutorial too. Run
it on the course folder to check everything at once:
`check_material(".")`.

Then try the lab as a student would:

``` r

preview_lab("labs/midterm")
```

To give the lab to students, either

- share the lab folder: Students open it with
  `learnr::run_tutorial("path/to/midterm")` (they need mirtverse and
  learnr); or
- host it, so students need nothing but a browser:
  `rsconnect::deployApp("labs/midterm")` deploys it to shinyapps.io or
  Posit Connect. learnr’s event recorder can log students’ answers
  there; the [teaching labs
  page](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#tips-for-running-the-labs)
  has more tips.

## A checklist for a new term

1.  [`new_course()`](https://www.okanbulut.com/mirtverse/reference/new_course.md)
    once, and keep the folder under version control or in a synced
    folder.
2.  For each week,
    [`copy_lab()`](https://www.okanbulut.com/mirtverse/reference/copy_lab.md)
    a built-in lab or
    [`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)
    on your data.
3.  Add or remove sections, exercises and questions.
4.  [`copy_chapter()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)
    the matching book chapters and
    [`swap_chapter_data()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)
    where you use your own data.
5.  `check_material(".")` until nothing fails, then
    [`preview_lab()`](https://www.okanbulut.com/mirtverse/reference/preview_lab.md)
    each lab.
6.  Next term:
    [`swap_lab_data()`](https://www.okanbulut.com/mirtverse/reference/swap_lab_data.md)
    with the new data, and check again.
