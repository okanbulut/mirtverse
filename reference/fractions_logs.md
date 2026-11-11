# Practice logs for the fractions knowledge graph

Simulated practice logs of 400 students on the Grade 5 fractions items
of
[fractions_kg](https://www.okanbulut.com/mirtverse/reference/fractions.md).
Students practise the six concepts in blocks, mostly in the curriculum
order; a block ends after three correct answers in a row or 15 attempts.
The logs follow a Bayesian knowledge tracing model in which a concept is
learned much more slowly while its prerequisites are not yet known.
[`lab_truth()`](https://www.okanbulut.com/mirtverse/reference/lab_truth.md)
(`"fractions_logs"`) returns the generating values and each student's
true state at every attempt.

## Usage

``` r
fractions_logs
```

## Format

A tibble with one row per attempt and 4 columns: `student` (`P001` to
`P400`), `attempt` (the student's attempt number over the whole
session), `item` (an item of
[fractions_kg](https://www.okanbulut.com/mirtverse/reference/fractions.md);
F14 is not practised) and `correct` (1 = correct, 0 = wrong). There is
no skill column: Fit it with
`mv_kt_fit(fractions_logs, kg = fractions_kg)`.

## Source

Simulated; the script is `data-raw/kt.R` in the package's GitHub
repository.

## See also

[`mv_kt_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_fit.md),
[fractions](https://www.okanbulut.com/mirtverse/reference/fractions.md)

## Examples

``` r
head(fractions_logs)
#> # A tibble: 6 × 4
#>   student attempt item  correct
#>   <chr>     <int> <chr>   <int>
#> 1 P001          1 F01         0
#> 2 P001          2 F02         1
#> 3 P001          3 F04         1
#> 4 P001          4 F02         1
#> 5 P001          5 F11         0
#> 6 P001          6 F10         1
table(table(fractions_logs$student))
#> 
#> 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 
#>  1  1  1  1  1  1  8  4  3  8  5  4  5 10 12  8 10 17 18 18 12 17 14 10 10 11 
#> 50 51 52 53 54 55 56 57 58 59 61 62 63 64 65 66 67 68 69 70 71 73 74 75 76 77 
#> 11  9 17 10 11 11  8 10  3  4  4  7  7  6 10  6  5  4  4  4  6  7  2  1  2  3 
#> 78 79 80 81 83 84 85 87 88 
#>  2  5  1  3  1  3  1  1  1 
```
