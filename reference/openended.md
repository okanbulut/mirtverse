# Rater-scored science tasks for the open-ended scoring lab

Simulated scores of 1,200 Grade 9 students on six open-ended tasks of a
fictional science assessment, each scored 0 to 4 against a rubric. Every
response was read by two of eight raters assigned at random, an expert
gave a third read when the two scores were two or more points apart, and
an automated scoring engine scored every response. Problems were planted
on purpose for the [open-ended scoring
lab](https://www.okanbulut.com/mirtverse/reference/run_lab.md);
`lab_truth("openended")` lists them.

## Usage

``` r
openended
```

## Format

A data frame with 7,200 rows (one per response) and 9 columns: `student`
(student ID), `ell` (factor, `Fluent` or `ELL`), `task` (`T1` to `T6`),
`rater1` and `rater2` (rater IDs, `R1` to `R8`), `score1` and `score2`
(their scores), `score3` (the expert's third read, `NA` when there was
none) and `machine` (the engine's score).

## Source

Simulated; the script is `data-raw/openended.R` in the package's GitHub
repository.

## Examples

``` r
head(openended)
#>   student    ell task rater1 score1 rater2 score2 score3 machine
#> 1   S0001 Fluent   T1     R4      4     R1      4     NA       4
#> 2   S0001 Fluent   T2     R4      3     R6      3     NA       3
#> 3   S0001 Fluent   T3     R7      4     R8      3     NA       3
#> 4   S0001 Fluent   T4     R7      2     R8      2     NA       2
#> 5   S0001 Fluent   T5     R2      2     R6      2     NA       2
#> 6   S0001 Fluent   T6     R4      4     R6      4     NA       4
tapply(openended$score1 == openended$score2, openended$task, mean)
#>        T1        T2        T3        T4        T5        T6 
#> 0.5808333 0.6000000 0.5825000 0.6275000 0.5908333 0.4325000 
```
