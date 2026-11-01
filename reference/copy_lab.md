# Copy a built-in lab into a course to edit it

Copies one of the package's teaching labs (see
[`list_labs()`](https://www.okanbulut.com/mirtverse/reference/run_lab.md))
into the course's `labs/` folder. The copy is yours: change the story,
cut sections, add exercises with
[`add_lab_exercise()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
or questions with
[`add_lab_question()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md),
then run
[`check_material()`](https://www.okanbulut.com/mirtverse/reference/check_material.md)
and
[`preview_lab()`](https://www.okanbulut.com/mirtverse/reference/preview_lab.md).

## Usage

``` r
copy_lab(name, course = ".", as = name, overwrite = FALSE)
```

## Arguments

- name:

  the built-in lab, e.g. `"model-choice"`.

- course:

  the course folder (it need not have a `course.json`).

- as:

  the name of the copy. Defaults to `name`.

- overwrite:

  replace an existing copy.

## Value

The path of the copied lab folder, invisibly.

## Details

The built-in labs' feedback is written for their own datasets (each has
problems planted on purpose), so to teach with your own data, start from
[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)
instead: its text and answer checks adapt to any dataset.

## See also

[`new_course()`](https://www.okanbulut.com/mirtverse/reference/new_course.md),
[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)

## Examples

``` r
course <- file.path(tempdir(), "copy-demo")
lab <- copy_lab("fairness", course, as = "week9-fairness")
lab_outline(lab)
#> # A tibble: 9 × 5
#>   id                       type     title                    exercises questions
#>   <chr>                    <chr>    <chr>                        <int>     <int>
#> 1 the-brief                built-in The brief                        1         0
#> 2 impact-or-bias           built-in Impact or bias?                  1         1
#> 3 match-on-the-total-score built-in Match on the total score         2         1
#> 4 the-irt-approach         built-in The IRT approach                 2         1
#> 5 choose-clean-anchors     built-in Choose clean anchors             2         2
#> 6 how-much-does-it-matter  built-in How much does it matter?         2         1
#> 7 content-review           built-in Content review                   1         1
#> 8 the-memo                 built-in The memo                         1         1
#> 9 the-reveal               built-in The reveal                       2         1
```
