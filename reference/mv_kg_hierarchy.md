# Mastery patterns allowed by the prerequisites

Lists the mastery patterns (profiles of mastered and not mastered
concepts) that respect the prerequisite edges of a knowledge graph: A
concept can be mastered only when all its prerequisites are. This is the
attribute hierarchy of Leighton, Gierl and Hunka (2004) and of
hierarchical diagnostic classification models (Templin and Bradshaw,
2014). Without prerequisites all 2^K patterns are allowed; each
prerequisite edge rules some out, which makes diagnostic models smaller
and easier to estimate.

## Usage

``` r
mv_kg_hierarchy(kg, concepts = NULL)
```

## Arguments

- kg:

  a knowledge graph from
  [`mv_kg_build()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md)
  or
  [`as_mv_kg()`](https://www.okanbulut.com/mirtverse/reference/as_mv_kg.md).

- concepts:

  optional concepts to keep (default: All concepts). Prerequisite paths
  through left-out concepts are kept, so A before B before C still makes
  A a prerequisite of C when B is left out.

## Value

A tibble with one row per allowed pattern and one 0/1 column per
concept, plus `mastered` (the number of concepts mastered). The number
of patterns without the hierarchy (2^K) is in attribute `"possible"`.

## Details

The patterns can be passed as `customTheta` to
[`mirt::mdirt()`](https://philchalmers.github.io/mirt/reference/mdirt.html)
to fit a diagnostic model that respects the hierarchy.

## References

Leighton, J. P., Gierl, M. J., & Hunka, S. M. (2004). The attribute
hierarchy method for cognitive assessment: A variation on Tatsuoka's
rule-space approach. *Journal of Educational Measurement, 41*, 205-237.

Templin, J., & Bradshaw, L. (2014). Hierarchical diagnostic
classification models: A family of models for estimating and testing
attribute hierarchies. *Psychometrika, 79*, 317-339.

## Examples

``` r
pat <- mv_kg_hierarchy(fractions_kg)
nrow(pat)
#> [1] 16
attr(pat, "possible")
#> [1] 64
pat
#> # A tibble: 16 × 7
#>    meaning equivalent mixed compare common_denominator add_subtract mastered
#>      <int>      <int> <int>   <int>              <int>        <int>    <int>
#>  1       0          0     0       0                  0            0        0
#>  2       1          0     0       0                  0            0        1
#>  3       0          0     0       1                  0            0        1
#>  4       1          1     0       0                  0            0        2
#>  5       1          0     1       0                  0            0        2
#>  6       1          0     0       1                  0            0        2
#>  7       1          1     1       0                  0            0        3
#>  8       1          1     0       1                  0            0        3
#>  9       1          1     0       0                  1            0        3
#> 10       1          0     1       1                  0            0        3
#> 11       1          1     1       1                  0            0        4
#> 12       1          1     1       0                  1            0        4
#> 13       1          1     0       1                  1            0        4
#> 14       1          1     1       1                  1            0        5
#> 15       1          1     1       0                  1            1        5
#> 16       1          1     1       1                  1            1        6
```
