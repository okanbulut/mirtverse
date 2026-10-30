# Answer key and true values for the lab dataset

Instructor helper: returns how
[certexam](https://www.okanbulut.com/mirtverse/reference/certexam.md)
was generated, so you can check students' conclusions. Students meet the
same information in the reveal at the end of the labs.

## Usage

``` r
lab_truth()
```

## Value

A list with the true `model`, the correct `key`, the `miskeyed` item,
the `testlet` items, the `dif` items and their type, the group `impact`
(mean ability difference in SD units), the generating item parameters
`pars` and the pass mark `cut_raw`.

## Examples

``` r
lab_truth()$dif
#>           Q09           Q27 
#>     "uniform" "non-uniform" 
```
