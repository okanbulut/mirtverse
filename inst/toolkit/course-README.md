# {{title}}

{{instructor_line}}This folder is a mirtverse course: teaching materials you
can edit, extend and re-run with your own data. It was made with
`mirtverse::new_course()` ({{made_with}}).

## What is here

| Folder | What it holds |
|---|---|
| `course.json` | The course title and instructor. mirtverse reads it; you can edit it. |
| `labs/` | One folder per interactive lab (learnr tutorial). Each has an `.Rmd` file and a `data/` folder. |
| `chapters/` | Notes chapters (R Markdown), one file each. |
| `data/` | Your own raw data files, kept here for reference. |

## Common tasks

```r
library(mirtverse)
course_materials()                                   # what is in the course
new_lab("week3", data = "data/my-test.csv")          # a lab built on your data
copy_lab("fairness")                                 # an editable copy of a built-in lab
add_lab_section("labs/week3", "dif")                 # add a ready-made section
add_lab_exercise("labs/week3", title = "...", prompt = "...", solution = "...")
swap_lab_data("labs/week3", data = "data/next-year.csv")
copy_chapter("dif")                                  # a chapter of the mirtverse book
check_material("labs/week3")                         # run every solution and check
preview_lab("labs/week3")                            # open the lab in the browser
```

The full guide is at
<https://www.okanbulut.com/mirtverse/articles/instructor-toolkit.html>.
