# Start a course folder for the instructor toolkit

The instructor toolkit keeps a course's teaching materials in one folder
that you can edit, extend and re-run with your own data. `new_course()`
creates the folder:

## Usage

``` r
new_course(path, title = NULL, instructor = NULL, overwrite = FALSE)

course_materials(course = ".")
```

## Arguments

- path:

  the folder to create. It may exist already, but must not already hold
  a `course.json` unless `overwrite = TRUE`.

- title:

  course title. Defaults to the folder name.

- instructor:

  instructor name(s), optional.

- overwrite:

  replace an existing `course.json` and `README.md`.

- course:

  the course folder.

## Value

`new_course()` returns the course path, invisibly. `course_materials()`
returns a tibble with one row per material: `name`, `type` (`"lab"` or
`"chapter"`), `title`, `path`, `source` (`"toolkit"` for labs built with
[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md),
`"built-in"` for copies of the package's labs, `"book"` for chapters
copied from the mirtverse book, `"own"` otherwise) and `data` (the data
a toolkit lab uses).

## Details

- `course.json`: The course title and instructor.

- `README.md`: A short how-to for whoever opens the folder next.

- `labs/`: Interactive labs (learnr tutorials), one folder each, made
  with
  [`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)
  or
  [`copy_lab()`](https://www.okanbulut.com/mirtverse/reference/copy_lab.md).

- `chapters/`: Notes chapters (R Markdown), made with
  [`new_chapter()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)
  or
  [`copy_chapter()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md).

- `data/`: Your raw data files, for reference.

`course_materials()` lists the labs and chapters in a course folder. It
scans `labs/` and `chapters/`, so materials you add by hand are listed
too.

All toolkit functions take paths, never ask questions, and return the
path they wrote (invisibly) or a tibble, so they can be scripted.

## See also

[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md),
[`copy_lab()`](https://www.okanbulut.com/mirtverse/reference/copy_lab.md),
[`copy_chapter()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md),
[`check_material()`](https://www.okanbulut.com/mirtverse/reference/check_material.md)

## Examples

``` r
course <- file.path(tempdir(), "irt-course")
new_course(course, title = "EDPY 507: Item response theory")
copy_lab("model-choice", course)
course_materials(course)
#> # A tibble: 1 × 6
#>   name         type  title                                    path  source data 
#>   <chr>        <chr> <chr>                                    <chr> <chr>  <chr>
#> 1 model-choice lab   Lab 1: Choosing a model the board can d… /tmp… built… NA   
```
