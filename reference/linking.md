# Two-form licensure exam data for the linking lab

Simulated right/wrong responses to two forms of a fictional 40-item
licensure exam in a common-item nonequivalent groups (NEAT) design. Form
A was taken by 1,000 candidates in 2025 and Form B by 1,000 candidates
in 2026. Each form has 28 unique items and 12 common anchor items.
Problems were planted on purpose for the [linking
lab](https://www.okanbulut.com/mirtverse/reference/run_lab.md);
`lab_truth("linking")` lists them.

## Usage

``` r
linking
```

## Format

A data frame with 2,000 rows and 70 columns: `id` (candidate ID), `form`
(factor, `A` or `B`), the Form A items `A01` to `A28`, the Form B items
`B01` to `B28` and the anchors `C01` to `C12` (1 = right, 0 = wrong,
`NA` = not on the candidate's form).

## Source

Simulated; the script is `data-raw/linking.R` in the package's GitHub
repository.

## Examples

``` r
table(linking$form)
#> 
#>    A    B 
#> 1000 1000 
form_a <- linking[linking$form == "A", c(sprintf("A%02d", 1:28), sprintf("C%02d", 1:12))]
summary(rowSums(form_a))
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>    0.00   14.00   22.00   20.86   27.00   40.00 
```
