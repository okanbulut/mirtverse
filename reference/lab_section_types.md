# Sections you can add to a toolkit lab

The ready-made sections that
[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)
and
[`add_lab_section()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
use. Each works with any dataset: its numbers, checks and questions are
computed from the lab's data.

## Usage

``` r
lab_section_types()
```

## Value

A tibble with the section `type`, its `title`, a `description`, and
`needs` (`"group"` when the section needs a grouping variable).

## Examples

``` r
lab_section_types()
#> # A tibble: 10 × 4
#>    type           title                     description                    needs
#>    <chr>          <chr>                     <chr>                          <chr>
#>  1 intro          Meet the data             The story, the size of the da… ""   
#>  2 classical      Classical item statistics Item means and item-total cor… ""   
#>  3 dimensionality How many dimensions?      Compare one- and two-factor m… ""   
#>  4 models         Compare IRT models        Compare the Rasch model with … ""   
#>  5 item-fit       Item fit                  S-X2 item fit with itemfit() … ""   
#>  6 information    Information and precision Test information and standard… ""   
#>  7 scoring        Scoring people            EAP scores with fscores(), co… ""   
#>  8 dif            Are the items fair?       Likelihood-ratio DIF tests be… "gro…
#>  9 reflection     Your recommendation       A written recommendation (fre… ""   
#> 10 wrap-up        Where to next             A summary and pointers to rep… ""   
```
