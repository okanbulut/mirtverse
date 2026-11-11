# Check prerequisites against practice logs

**Experimental.** Asks the practice logs which concepts are learned
faster once another concept is known. If A is a prerequisite of B,
students who do not yet know A should learn B slowly, and pick it up
quickly once A is known. For every ordered pair of skills, the learn
rate of B is estimated twice from a knowledge tracing model
([`mv_kt_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_fit.md)):
On the attempts made while A was probably known (its probability of
being known, from the student's earlier attempts on A, is above 0.5) and
on those made while it was not. A likelihood ratio test compares this
with one learn rate.

## Usage

``` r
mv_kt_prereq(kt, kg = NULL, alpha = 0.001, min_ratio = 2, min_share = 0.05)
```

## Arguments

- kt:

  a knowledge tracing model from
  [`mv_kt_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_fit.md);
  its skills must be concepts of `kg`.

- kg:

  the knowledge graph to check; by default the graph `kt` was fitted
  with.

- alpha:

  significance level of the likelihood ratio tests.

- min_ratio:

  smallest speed-up (learn rate with the prerequisite known divided by
  the rate without) that suggests a missing edge.

- min_share:

  smallest share of the attempts in each group for a pair to be judged;
  pairs where nearly everyone (or no one) knows A cannot show a
  difference.

## Value

An `mv_kt_prereq` object: A list with `pairs` (one row per ordered pair:
`from`, `to`, `edge`, `learn_without`, `learn_with`, `ratio`, `lr` (the
likelihood ratio statistic), `p_value`, `share_with`, `n_attempts` and
`verdict`), `flags`, `kg` and `settings`. Use
[`tidy()`](https://generics.r-lib.org/reference/tidy.html),
[`glance()`](https://generics.r-lib.org/reference/glance.html) and
[`print()`](https://rdrr.io/r/base/print.html).

## Details

Concepts on the same learning path all speed each other up, so each test
is run on the attempts where B's other prerequisites in the graph are
already known: An indirect prerequisite then adds little. A graph edge
whose test fails is flagged `weak_prerequisite`; a pair without an edge
whose test is clearly significant, with a large speed-up and enough
attempts in both groups, is flagged `missing_prerequisite`. Of two
concepts that speed each other up, only the stronger direction is
suggested. Like
[`mv_kg_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_fit.md),
the flags are leads for content experts, not verdicts; add or drop edges
with
[`mv_kg_edit()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_edit.md)
and check again.

## See also

[`mv_kg_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_fit.md)
checks the same graph against test answers.

## Examples

``` r
kt <- mv_kt_fit(fractions_logs, kg = fractions_kg)
check <- mv_kt_prereq(kt)
check
#> <mv_kt_prereq> (EXPERIMENTAL) Prerequisites checked against practice logs
#> Graph: Grade 5 fractions; 5 prerequisite edge(s), 5 supported by the logs
#> 1 flag(s)
#> * [missing_prerequisite] compare is learned 10.1 times as fast once
#>   equivalent is known (learn 0.17 vs 0.02, LR = 155.6); add the
#>   prerequisite equivalent -> compare? 
tidy(check)
#> # A tibble: 30 × 11
#>    from   to    edge  learn_without learn_with  ratio     lr  p_value share_with
#>    <chr>  <chr> <lgl>         <dbl>      <dbl>  <dbl>  <dbl>    <dbl>      <dbl>
#>  1 equiv… comp… FALSE        0.0173      0.175 10.1   156.   1.05e-35     0.699 
#>  2 commo… add_… TRUE         0.0263      0.127  4.82   96.6  8.29e-23     0.580 
#>  3 meani… equi… TRUE         0.0620      0.210  3.39   89.4  3.24e-21     0.583 
#>  4 equiv… comm… TRUE         0.0186      0.153  8.22   88.4  5.45e-21     0.790 
#>  5 meani… mixed TRUE         0.0594      0.202  3.40   44.1  3.20e-11     0.852 
#>  6 mixed  add_… TRUE         0.0196      0.127  6.46   23.9  1.00e- 6     0.909 
#>  7 commo… mixed FALSE        0.195       0.430  2.20   11.1  8.54e- 4     0.0490
#>  8 equiv… add_… FALSE        0.0393      0.133  3.40    9.69 1.85e- 3     0.937 
#>  9 compa… mixed FALSE        0.191       0.276  1.45    6.86 8.82e- 3     0.155 
#> 10 mixed  comm… FALSE        0.238       0.148  0.619   5.89 1.52e- 2     0.920 
#> # ℹ 20 more rows
#> # ℹ 2 more variables: n_attempts <int>, verdict <chr>
```
