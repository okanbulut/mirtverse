# Sections you can add to a toolkit lab

The ready-made sections that
[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)
and
[`add_lab_section()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
use. Each works with any dataset: Its numbers, checks and questions are
computed from the lab's data.

## Usage

``` r
lab_section_types()
```

## Value

A tibble with the section `type`, its `title`, a `description`, and
`needs`: What the section needs besides the responses (`"group"`,
`"item text"`, `"item families"` or `"scores"`), or `""`.

## Details

The last three sections teach AI in measurement with the lab's data and
need more than responses (see the `item_info` and `scores` arguments of
[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)):
`"item-features"` predicts item difficulty from the item text, `"aig"`
checks whether the items of each family are equally difficult, and
`"ai-scoring"` audits machine scores against human scores.

## Examples

``` r
lab_section_types()
#> # A tibble: 13 × 4
#>    type           title                           description              needs
#>    <chr>          <chr>                           <chr>                    <chr>
#>  1 intro          Meet the data                   The story, the size of … ""   
#>  2 classical      Classical item statistics       Item means and item-tot… ""   
#>  3 dimensionality How many dimensions?            Compare one- and two-fa… ""   
#>  4 models         Compare IRT models              Compare the Rasch model… ""   
#>  5 item-fit       Item fit                        S-X2 item fit with item… ""   
#>  6 information    Information and precision       Test information and st… ""   
#>  7 scoring        Scoring people                  EAP scores with fscores… ""   
#>  8 dif            Are the items fair?             Likelihood-ratio DIF te… "gro…
#>  9 reflection     Your recommendation             A written recommendatio… ""   
#> 10 wrap-up        Where to next                   A summary and pointers … ""   
#> 11 item-features  What the item text tells us     Text features with item… "ite…
#> 12 aig            Item families                   Are the items of each f… "ite…
#> 13 ai-scoring     Machine scores and human scores Machine-human agreement… "sco…
```
