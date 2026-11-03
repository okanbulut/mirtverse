# An AI-scored science test over two years, for the AI Hub

Simulated scores of 3,000 Grade 8 students (1,500 in 2025 and 1,500 in
2026, a quarter of them English language learners, ELL) on a science
test with 16 multiple-choice items and 4 constructed-response items, as
scored operationally: The constructed responses (`CR1` to `CR4`, 0 to 3
points) are scored by an automated scoring engine. The human scores of
the validity sample are in
[aiscored_cr](https://www.okanbulut.com/mirtverse/reference/aiscored_cr.md).

## Usage

``` r
aiscored
```

## Format

A data frame with 3,000 rows (one per student) and 23 columns:
`student`, `year` (2025 or 2026), `group` (factor, `Fluent` or `ELL`),
`MC01` to `MC16` (0/1) and `CR1` to `CR4` (machine scores, 0 to 3).

## Source

Simulated; the script is `data-raw/aiscored.R` in the package's GitHub
repository.

## Details

The dataset is for learning to audit an AI component with
[`ai_audit()`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md).
Some problems were planted on purpose; `lab_truth("aiscored")` lists
them and the true scores.

## See also

[aiscored_cr](https://www.okanbulut.com/mirtverse/reference/aiscored_cr.md);
[`ai_audit()`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md).

## Examples

``` r
table(aiscored$year, aiscored$group)
#>       
#>        Fluent  ELL
#>   2025   1148  352
#>   2026   1129  371
colMeans(aiscored[, c("CR1", "CR2", "CR3", "CR4")])
#>      CR1      CR2      CR3      CR4 
#> 1.441333 1.261667 1.751333 1.402000 
```
