# Numeracy test data for the DIF and fairness lab

Simulated right/wrong responses of 2,000 Grade 6 students, 500 of them
English language learners (ELL), to a fictional 30-item provincial
numeracy test. Some items are word problems, some are bare calculations.
DIF was planted on purpose for the [fairness
lab](https://www.okanbulut.com/mirtverse/reference/run_lab.md);
`lab_truth("numeracy")` lists it.

## Usage

``` r
numeracy

numeracy_items
```

## Format

`numeracy` is a data frame with 2,000 rows and 33 columns: `id` (student
ID), `ell` (factor, `Fluent` or `ELL`), `gender` (factor, `Girl` or
`Boy`) and `N01` to `N30` (1 = right, 0 = wrong). `numeracy_items`
describes the items: `item`, curriculum `strand`, `format` (`Symbolic`
or `Word problem`) and `words` (word count).

An object of class `data.frame` with 30 rows and 4 columns.

## Source

Simulated; the script is `data-raw/numeracy.R` in the package's GitHub
repository.

## Examples

``` r
head(numeracy[, 1:6])
#>      id    ell gender N01 N02 N03
#> 1 S0001 Fluent    Boy   0   1   1
#> 2 S0002 Fluent    Boy   0   0   1
#> 3 S0003 Fluent   Girl   0   0   0
#> 4 S0004 Fluent   Girl   0   1   1
#> 5 S0005 Fluent    Boy   0   1   1
#> 6 S0006    ELL    Boy   0   0   1
tapply(rowSums(numeracy[, -(1:3)]), numeracy$ell, mean)
#> Fluent    ELL 
#> 14.734 11.264 
```
