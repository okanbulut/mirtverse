# Answer key and true values for the lab datasets

Instructor helper: returns how a lab dataset was generated, so you can
check students' conclusions. Students meet the same information in the
reveal at the end of the labs.

## Usage

``` r
lab_truth(data = c("certexam", "numeracy"))
```

## Arguments

- data:

  the dataset: `"certexam"` (Labs 1 and 2) or `"numeracy"` (Lab 3).

## Value

For `"certexam"`, a list with the true `model`, the correct `key`, the
`miskeyed` item, the `testlet` items, the `dif` items and their type,
the group `impact` (mean ability difference in SD units), the generating
item parameters `pars` and the pass mark `cut_raw`. For `"numeracy"`, a
list with the true `model`, the `dif` items and their type, the
`impact`, the generating item parameters `pars` (with separate values
for ELL students) and `no_dif_long`, long word problems without DIF.

## Examples

``` r
lab_truth()$dif
#>           Q09           Q27 
#>     "uniform" "non-uniform" 
lab_truth("numeracy")$dif
#>                     N07                     N18                     N20 
#>               "uniform"               "uniform"               "uniform" 
#>                     N25                     N30                     N02 
#>               "uniform"               "uniform"           "non-uniform" 
#>                     N21                     N03 
#> "uniform (favours ELL)"            "negligible" 
```
