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
links of the Q-matrix. Its item metadata (see
[`mv_kg_annotate()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_annotate.md))
has the problem each item asks, in a column `text` (for example
`"3 1/2 - 2 3/2"`), which
[`mv_kg_extract()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_extract.md)
can read.

An object of class `mv_kg` of length 4.

## Source

Copied from the `fraction.subtraction.data` and
`fraction.subtraction.qmatrix` datasets of the CDM package (Robitzsch,
Kiefer, George and Uenlue; GPL). The data first appeared in Tatsuoka
(1984) and are published in Tatsuoka (2002). The item text follows the
problems as listed by de la Torre and Douglas (2004).

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
#> Item metadata: text
mv_kg_check(fraction_subtraction_kg)
#> <mv_kg_check> 0 block, 1 review, 0 info
#> * [review] few_items: column_borrow is measured by 2 item(s); at least
#>   3 are needed to estimate it as its own dimension.
tidy(fraction_subtraction_kg, "items")
#> # A tibble: 20 × 4
#>    item  concepts                                               n_concepts text 
#>    <chr> <chr>                                                       <int> <chr>
#>  1 FS01  common_denominator, column_borrow, subtract_numerators          3 5/3 …
#>  2 FS02  common_denominator, subtract_numerators                         2 3/4 …
#>  3 FS03  common_denominator, subtract_numerators                         2 5/6 …
#>  4 FS04  separate_whole, simplify_first, borrow_whole, subtrac…          4 3 1/…
#>  5 FS05  separate_whole, common_denominator, subtract_numerato…          4 4 3/…
#>  6 FS06  subtract_numerators                                             1 6/7 …
#>  7 FS07  convert_whole, separate_whole, subtract_numerators              3 3 - …
#>  8 FS08  subtract_numerators                                             1 2/3 …
#>  9 FS09  separate_whole                                                  1 3 7/…
#> 10 FS10  separate_whole, borrow_whole, subtract_numerators, re…          4 4 4/…
#> 11 FS11  separate_whole, borrow_whole, subtract_numerators               3 4 1/…
#> 12 FS12  subtract_numerators, reduce_answer                              2 11/8…
#> 13 FS13  separate_whole, common_denominator, borrow_whole, sub…          4 3 3/…
#> 14 FS14  separate_whole, subtract_numerators                             2 3 4/…
#> 15 FS15  convert_whole, subtract_numerators                              2 2 - …
#> 16 FS16  separate_whole, subtract_numerators                             2 4 5/…
#> 17 FS17  separate_whole, borrow_whole, subtract_numerators               3 7 3/…
#> 18 FS18  separate_whole, borrow_whole, column_borrow, subtract…          4 4 1/…
#> 19 FS19  convert_whole, separate_whole, simplify_first, borrow…          5 4 - …
#> 20 FS20  separate_whole, simplify_first, borrow_whole, subtrac…          4 4 1/…
gg_kg(fraction_subtraction_kg)
```
