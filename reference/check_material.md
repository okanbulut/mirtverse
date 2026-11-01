# Check a lab, a chapter or a whole course

Runs a teaching material the way students will meet it and reports what
works. Run it after every edit, and after
[`swap_lab_data()`](https://www.okanbulut.com/mirtverse/reference/swap_lab_data.md).

## Usage

``` r
check_material(path, render = FALSE, quiet = TRUE)
```

## Arguments

- path:

  a lab folder, a chapter `.Rmd` file or a course folder.

- render:

  also render the material with
  [`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html),
  which catches problems in the Markdown and YAML as well as the code.
  Slower.

- quiet:

  suppress the progress messages.

## Value

A tibble with one row per check: `material`, `check` (`"structure"`,
`"data"`, `"chunk"`, `"exercise"` or `"render"`), `label`, `status`
(`"pass"`, `"fail"` or `"skip"`) and `message`.
`all(result$status != "fail")` is `TRUE` when the material is ready.

## Details

For a **lab** (a folder with a learnr `.Rmd`), it checks that chunk
labels are unique and that every `-solution`, `-hint` and `-check` chunk
belongs to an exercise; runs the setup chunk and every chunk that runs
when the lab is rendered (including the multiple-choice questions); and
runs each exercise's solution (or its starting code, when there is no
solution) followed by its `-check` chunk through
[`lab_checker()`](https://www.okanbulut.com/mirtverse/reference/lab_checker.md),
so a solution that its own check rejects is reported. For a **chapter**
(an `.Rmd` file), it runs every chunk in order. For a **course** folder
(with `course.json`), it checks every material in
[`course_materials()`](https://www.okanbulut.com/mirtverse/reference/new_course.md).

Everything runs in a temporary copy, so nothing in your folder changes.

## See also

[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md),
[`preview_lab()`](https://www.okanbulut.com/mirtverse/reference/preview_lab.md)

## Examples

``` r
# \donttest{
course <- file.path(tempdir(), "check-demo")
lab <- new_lab("demo", data = expand.table(LSAT7), course = course,
               sections = c("intro", "classical"))
check_material(lab)
#> # A tibble: 7 × 5
#>   material check     label           status message                             
#>   <chr>    <chr>     <chr>           <chr>  <chr>                               
#> 1 demo     structure labels          pass   11 chunks, all labels unique.       
#> 2 demo     data      data            pass   1000 people, 5 items.               
#> 3 demo     chunk     setup           pass   Runs.                               
#> 4 demo     chunk     all             pass   Every chunk that runs at render tim…
#> 5 demo     exercise  intro-look      pass   Each row is a person and each colum…
#> 6 demo     exercise  classical-means pass   Right. The easiest item is Item.5 a…
#> 7 demo     exercise  classical-stats pass   Look down the cor_if_rm (or total.r…
# }
```
