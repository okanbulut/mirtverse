# Machine and human scores of the AI-scored test

The constructed responses of
[aiscored](https://www.okanbulut.com/mirtverse/reference/aiscored.md),
one row per student and item, with the engine's score and, for the
validity sample, human scores: 20% of students were scored by a human
rater as well, and half of those by a second rater.

## Usage

``` r
aiscored_cr
```

## Format

A data frame with 12,000 rows and 7 columns: `student`, `year`, `group`,
`item` (`CR1` to `CR4`), `machine` (the engine's score, 0 to 3),
`human1` and `human2` (the human scores, `NA` when the response was not
read).

## Source

Simulated; the script is `data-raw/aiscored.R` in the package's GitHub
repository.

## See also

[aiscored](https://www.okanbulut.com/mirtverse/reference/aiscored.md);
[`ai_audit()`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md),
[`agreement_report()`](https://www.okanbulut.com/mirtverse/reference/agreement_report.md).

## Examples

``` r
cr <- aiscored_cr[!is.na(aiscored_cr$human1), ]
agreement_report(cr$machine, cr$human1, cr$human2, by = cr$item)
#> Machine-human agreement
#>   by group   n n_double mean_human mean_machine exact adjacent  qwk qwk_human
#>  CR1   All 589      295       1.48         1.45  0.73     0.98 0.87      0.89
#>  CR2   All 589      295       1.39         1.31  0.65     0.97 0.81      0.84
#>  CR3   All 589      295       1.59         1.74  0.65     0.96 0.79      0.84
#>  CR4   All 589      295       1.48         1.48  0.51     0.91 0.68      0.66
#>  corr   smd prmse           verdict
#>  0.87 -0.03  0.82             meets
#>  0.81 -0.07  0.74             meets
#>  0.80  0.14  0.72             meets
#>  0.68  0.00  0.56 agreement too low
#> Meets: QWK >= 0.7 and within 0.1 of human-human QWK; |SMD| <= 0.15 overall and <= 0.1 within groups (mv_rules()).
```
