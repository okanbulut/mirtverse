# Copy the AI in measurement workshop kit

Copies the kit for a one-day workshop on AI in measurement into a folder
you can edit: The slides (`slides.Rmd`, an ioslides presentation), a
facilitator's guide (`facilitator-guide.Rmd`) and a `README.md`. The day
uses Labs 7 to 10
([`run_lab()`](https://www.okanbulut.com/mirtverse/reference/run_lab.md))
and runs offline. Render the slides and the guide with
[`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html).

## Usage

``` r
copy_workshop(dest = "ai-workshop", overwrite = FALSE)
```

## Arguments

- dest:

  the folder to copy the kit into. Inside a course folder made with
  [`new_course()`](https://www.okanbulut.com/mirtverse/reference/new_course.md),
  use `file.path(course, "workshop")`.

- overwrite:

  replace files that already exist in `dest`.

## Value

The path of the folder, invisibly.

## See also

The course map's AI module and workshop schedule, and the [workshop
article](https://www.okanbulut.com/mirtverse/articles/ai-workshop.html).

## Examples

``` r
kit <- copy_workshop(file.path(tempdir(), "ai-workshop"))
list.files(kit)
#> [1] "README.md"             "facilitator-guide.Rmd" "slides.Rmd"           
```
