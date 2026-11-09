# Tatsuoka's fraction subtraction data with its Q-matrix

Right/wrong responses of 536 middle school students to 20 fraction
subtraction items (Tatsuoka, 1984), with the 8-attribute Q-matrix used
by de la Torre and Douglas (2004) and DeCarlo (2011), stored as a
knowledge graph. It is the best-known real dataset in cognitive
diagnosis, and it is the real-data example for the knowledge graph
functions.

## Usage

``` r
fraction_subtraction

fraction_subtraction_kg
```

## Format

`fraction_subtraction` is a data frame with 536 rows and 20 columns,
`FS01` to `FS20` (1 = correct, 0 = incorrect), in the order of `Item1`
to `Item20` in the CDM package. `fraction_subtraction_kg` is an
[mv_kg](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md)
knowledge graph with 8 concepts, 20 items and the item-to-attribute
links of the Q-matrix.

An object of class `mv_kg` of length 3.

## Source

Copied from the `fraction.subtraction.data` and
`fraction.subtraction.qmatrix` datasets of the CDM package (Robitzsch,
Kiefer, George and Uenlue; GPL). The data first appeared in Tatsuoka
(1984) and are published in Tatsuoka (2002).

## Details

The eight attributes are: Convert a whole number to a fraction
(`convert_whole`), separate a whole number from a fraction
(`separate_whole`), simplify before subtracting (`simplify_first`), find
a common denominator (`common_denominator`), borrow from the whole
number part (`borrow_whole`), column borrow to subtract the second
numerator from the first (`column_borrow`), subtract numerators
(`subtract_numerators`) and reduce answers to simplest form
(`reduce_answer`). No prerequisite relations between the attributes were
published with the Q-matrix, so the graph has none; add your own with
[`mv_kg_build()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md).

## References

DeCarlo, L. T. (2011). On the analysis of fraction subtraction data: The
DINA model, classification, latent class sizes, and the Q-matrix.
*Applied Psychological Measurement, 35*, 8-26.

de la Torre, J., & Douglas, J. (2004). Higher-order latent trait models
for cognitive diagnosis. *Psychometrika, 69*, 333-353.

Tatsuoka, C. (2002). Data analytic methods for latent partially ordered
classification models. *Journal of the Royal Statistical Society, Series
C, 51*, 337-350.

Tatsuoka, K. K. (1984). *Analysis of errors in fraction addition and
subtraction problems* (Final report for NIE-G-81-0002). University of
Illinois, Urbana-Champaign.

## Examples

``` r
fraction_subtraction_kg
#> <mv_kg> Fraction subtraction (Tatsuoka): 8 concept(s), 20 item(s)
#> Edges: 0 prerequisite, 0 related, 56 measures
mv_kg_check(fraction_subtraction_kg)
#> <mv_kg_check> 0 block, 1 review, 0 info
#> * [review] few_items: column_borrow is measured by 2 item(s); at least
#>   3 are needed to estimate it as its own dimension.
gg_kg(fraction_subtraction_kg)
```
