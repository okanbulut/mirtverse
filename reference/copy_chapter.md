# Notes chapters for a course

`copy_chapter()` copies a chapter of the mirtverse online book into the
course's `chapters/` folder so you can edit it. `new_chapter()` starts a
blank chapter with the same headings as the book's chapters ("Learning
goals", "Key terms", "Example 1", "Example 2", "Your turn", "In the
lab", "Further reading"). `swap_chapter_data()` replaces the code that
loads an example's data.

## Usage

``` r
copy_chapter(id, course = ".", from = NULL, overwrite = FALSE)

new_chapter(
  id,
  course = ".",
  title = NULL,
  data_code = NULL,
  overwrite = FALSE
)

swap_chapter_data(chapter, chunk = NULL, code)

book_chapters()
```

## Arguments

- id:

  the chapter's id. For `copy_chapter()`, one of `book_chapters()$id`;
  for `new_chapter()`, a new id (letters, digits, - and \_).

- course:

  the course folder.

- from:

  where to copy from: a local copy of the book's source folder (`book/`
  in the package's GitHub repository), or `NULL` (the default) to
  download the chapter from GitHub.

- overwrite:

  replace an existing file. `copy_chapter()` also copies the book's
  `_common.R` (packages, chunk options and seed, sourced before each
  chapter) into `chapters/` the first time, and
  [`check_material()`](https://www.okanbulut.com/mirtverse/reference/check_material.md)
  runs it before a chapter's chunks.

- title:

  the chapter title.

- data_code:

  R code that loads the examples' data. It should define `resp`, a data
  frame of scored item responses. Defaults to the LSAT7 data from mirt.

- chapter:

  the chapter's `.Rmd` file.

- chunk:

  the label of the data chunk to replace, for example `"data-dif-1"`.
  `NULL` (the default) replaces every `data-` chunk.

- code:

  the new R code for the chunk(s).

## Value

`copy_chapter()` and `new_chapter()` return the chapter's path,
invisibly. `book_chapters()` returns a tibble with the `id`, `file` and
`title` of each book chapter.

## Details

Each example in a book chapter opens with a chunk labelled
`data-<chapter>-<n>` that loads its data, and the rest of the example
uses what that chunk defines. To use your own data, rewrite that chunk;
the easiest way is `swap_chapter_data()`.

## See also

[`new_course()`](https://www.okanbulut.com/mirtverse/reference/new_course.md),
[`check_material()`](https://www.okanbulut.com/mirtverse/reference/check_material.md)

## Examples

``` r
book_chapters()
#> # A tibble: 17 × 3
#>    id             file                  title                                   
#>    <chr>          <chr>                 <chr>                                   
#>  1 measurement    01-measurement.Rmd    Measurement, scoring and classical item…
#>  2 irt-models     02-irt-models.Rmd     From classical test theory to IRT       
#>  3 estimation     03-estimation.Rmd     Estimation and comparing models         
#>  4 dimensionality 04-dimensionality.Rmd Dimensionality and local independence   
#>  5 fit            05-fit.Rmd            Item fit, person fit and item quality   
#>  6 information    06-information.Rmd    Information, precision and reliability  
#>  7 scoring        07-scoring.Rmd        Scoring people                          
#>  8 polytomous     08-polytomous.Rmd     Polytomous items and open-ended respons…
#>  9 dif            09-dif.Rmd            Differential item functioning and fairn…
#> 10 linking        10-linking.Rmd        Linking and equating                    
#> 11 banks-cat      11-banks-cat.Rmd      Item banks, test assembly and adaptive …
#> 12 reporting      12-reporting.Rmd      Cut scores, reporting and communicating…
#> 13 ml-lens        13-ml-lens.Rmd        Machine learning through an IRT lens    
#> 14 auto-scoring   16-auto-scoring.Rmd   Automated scoring                       
#> 15 llms           17-llms.Rmd           Large language models as a colleague    
#> 16 datasets       90-datasets.Rmd       Appendix: the datasets                  
#> 17 adapting       91-adapting.Rmd       Appendix: adapting the book             
course <- file.path(tempdir(), "chapter-demo")
ch <- new_chapter("my-week", course, title = "Our own data",
                  data_code = "resp <- expand.table(LSAT7)")
swap_chapter_data(ch, code = "resp <- expand.table(LSAT6)")
if (FALSE) { # \dontrun{
copy_chapter("dif", course)   # downloads from GitHub
} # }
```
