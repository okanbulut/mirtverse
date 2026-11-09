# Q-matrix from a knowledge graph

Returns the item-by-concept Q-matrix stored in a knowledge graph: A 1
where an item measures a concept, else 0. Weights given to the
`measures` edges are kept.

## Usage

``` r
mv_kg_qmatrix(kg, items = NULL, drop_empty = FALSE)
```

## Arguments

- kg:

  a knowledge graph from
  [`mv_kg_build()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md)
  or
  [`as_mv_kg()`](https://www.okanbulut.com/mirtverse/reference/as_mv_kg.md).

- items:

  optional item names (or a data frame whose column names are used) to
  set the order of the rows; columns of a data frame that are not items
  of the graph, such as an ID column, are skipped.

- drop_empty:

  logical; drop concepts that no item measures.

## Value

A numeric matrix with one row per item and one column per concept.

## See also

[`mv_kg_model()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_model.md)
and
[`mv_kg_irt()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_irt.md)
to fit the matching mirt model;
[`mv_kg_hierarchy()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_hierarchy.md)
for the mastery patterns the prerequisites allow.

## Examples

``` r
mv_kg_qmatrix(fractions_kg)
#>     meaning equivalent mixed compare common_denominator add_subtract
#> F01       1          0     0       0                  0            0
#> F02       1          0     0       0                  0            0
#> F03       1          0     0       0                  0            0
#> F04       1          0     0       0                  0            0
#> F05       0          1     0       0                  0            0
#> F06       0          1     0       0                  0            0
#> F07       0          1     0       0                  0            0
#> F08       0          1     0       0                  0            0
#> F09       0          0     1       0                  0            0
#> F10       0          0     1       0                  0            0
#> F11       0          0     1       0                  0            0
#> F12       0          0     1       0                  0            0
#> F13       0          0     0       1                  0            0
#> F14       0          0     0       1                  0            0
#> F15       0          0     0       1                  0            0
#> F16       0          0     0       1                  0            0
#> F17       0          0     0       0                  1            0
#> F18       0          0     0       0                  1            0
#> F19       0          0     0       0                  1            0
#> F20       0          0     0       0                  0            1
#> F21       0          0     0       0                  0            1
#> F22       0          0     0       0                  1            1
#> F23       0          0     1       0                  0            1
#> F24       0          0     0       0                  1            1
mv_kg_qmatrix(fraction_subtraction_kg, fraction_subtraction)
#>      convert_whole separate_whole simplify_first common_denominator
#> FS01             0              0              0                  1
#> FS02             0              0              0                  1
#> FS03             0              0              0                  1
#> FS04             0              1              1                  0
#> FS05             0              1              0                  1
#> FS06             0              0              0                  0
#> FS07             1              1              0                  0
#> FS08             0              0              0                  0
#> FS09             0              1              0                  0
#> FS10             0              1              0                  0
#> FS11             0              1              0                  0
#> FS12             0              0              0                  0
#> FS13             0              1              0                  1
#> FS14             0              1              0                  0
#> FS15             1              0              0                  0
#> FS16             0              1              0                  0
#> FS17             0              1              0                  0
#> FS18             0              1              0                  0
#> FS19             1              1              1                  0
#> FS20             0              1              1                  0
#>      borrow_whole column_borrow subtract_numerators reduce_answer
#> FS01            0             1                   1             0
#> FS02            0             0                   1             0
#> FS03            0             0                   1             0
#> FS04            1             0                   1             0
#> FS05            0             0                   1             1
#> FS06            0             0                   1             0
#> FS07            0             0                   1             0
#> FS08            0             0                   1             0
#> FS09            0             0                   0             0
#> FS10            1             0                   1             1
#> FS11            1             0                   1             0
#> FS12            0             0                   1             1
#> FS13            1             0                   1             0
#> FS14            0             0                   1             0
#> FS15            0             0                   1             0
#> FS16            0             0                   1             0
#> FS17            1             0                   1             0
#> FS18            1             1                   1             0
#> FS19            1             0                   1             0
#> FS20            1             0                   1             0
```
