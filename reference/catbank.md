# Math placement item bank for the CAT design lab

A fictional calibrated 2PL item bank of 180 items for a college math
placement test, 45 in each of four content areas. 40 items make up the
college's current fixed-length test. The bank has weaknesses built in on
purpose for the [CAT design
lab](https://www.okanbulut.com/mirtverse/reference/run_lab.md);
`lab_truth("catbank")` lists them.

## Usage

``` r
catbank
```

## Format

A data frame with 180 rows and 5 columns: `item` (item ID), `area`
(factor: Algebra, Functions, Geometry or Statistics), `a`
(discrimination), `b` (difficulty) and `fixed` (logical, `TRUE` for the
items on the current fixed test).

## Source

Simulated; the script is `data-raw/catbank.R` in the package's GitHub
repository.

## Examples

``` r
table(catbank$area, catbank$fixed)
#>             
#>              FALSE TRUE
#>   Algebra       35   10
#>   Functions     35   10
#>   Geometry      35   10
#>   Statistics    35   10
tapply(catbank$a, catbank$area, mean)
#>    Algebra  Functions   Geometry Statistics 
#>   1.735556   1.129556   1.046444   1.075111 
```
