# Certification exam data for the teaching labs

Simulated responses of 1,200 candidates to a fictional 32-item,
five-option certification exam taken in English or French. Item
parameters are based on a 3PL calibration of mirt's
[mirt::SAT12](https://philchalmers.github.io/mirt/reference/SAT12.html)
data, so the items behave like real ones. Some problems were planted on
purpose for the [teaching
labs](https://www.okanbulut.com/mirtverse/reference/run_lab.md);
[`lab_truth()`](https://www.okanbulut.com/mirtverse/reference/lab_truth.md)
lists them.

## Usage

``` r
certexam

certexam_key
```

## Format

`certexam` is a data frame with 1,200 rows and 34 columns: `id`
(candidate ID), `language` (factor, English or French) and `Q01` to
`Q32` (the option chosen, A to E). `certexam_key` is a named character
vector with the published answer key for `Q01` to `Q32`.

An object of class `character` of length 32.

## Source

Simulated; the script is `data-raw/certexam.R` in the package's GitHub
repository.

## Examples

``` r
head(certexam[, 1:6])
#>      id language Q01 Q02 Q03 Q04
#> 1 C0001   French   E   B   C   B
#> 2 C0002  English   E   B   A   D
#> 3 C0003  English   B   C   E   D
#> 4 C0004  English   C   C   E   C
#> 5 C0005  English   A   B   A   B
#> 6 C0006   French   B   C   E   E
scored <- key2binary(certexam[, -(1:2)], certexam_key)
```
