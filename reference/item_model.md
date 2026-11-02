# Write an item model for automatic item generation

An item model (Gierl & Haladyna, 2013) is a parent item with variable
elements: A stem, a key and distractors written as templates, the values
each variable can take, and constraints that every generated item must
meet.
[`generate_isomorphs()`](https://www.okanbulut.com/mirtverse/reference/generate_isomorphs.md)
fills the templates to produce **isomorphs**: Items that test the same
thing in the same way and differ only in their surface. This is the
classical, template-based route to automatic item generation (AIG); it
is deterministic and every item can be traced to its values.
[`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
is the language-model route.

## Usage

``` r
item_model(
  stem,
  key,
  distractors,
  values,
  constraints = NULL,
  name = "M",
  digits = 2
)
```

## Arguments

- stem:

  the stem template.

- key:

  the template of the correct answer.

- distractors:

  a character vector of distractor templates, one per wrong option. Name
  them to record the misconception behind each.

- values:

  a named list with the values each variable can take.

- constraints:

  optional character vector of R expressions of the variables, each of
  which must be `TRUE` for a combination of values to be used.

- name:

  a short name for the item model, used in item ids.

- digits:

  largest number of decimals printed for computed values.

## Value

An object of class `mv_item_model`. Print it to see the templates and
how many isomorphs it can generate.

## Details

Templates mark variable parts with braces. Inside the braces is any R
expression of the variables, so `"{l}"` inserts the value of `l` and
`"{2 * (l + w)}"` inserts the computed perimeter. Whole numbers are
printed without decimals and with a thousands separator, other numbers
with up to `digits` decimals. Two helpers can be used in templates:
`money(x)` prints `$12.50`, and `fmt(x, d)` prints `x` with exactly `d`
decimals.

Write each distractor from a **misconception**: The answer a student
with a specific misunderstanding would give, such as the area for the
perimeter. Write constraints for what the values must satisfy (for
example that a result is a whole number), and to keep the distractors
different from the key and from each other for every combination of
values.

## References

Gierl, M. J., & Haladyna, T. M. (Eds.). (2013). *Automatic item
generation: Theory and practice.* Routledge.

## See also

[`generate_isomorphs()`](https://www.okanbulut.com/mirtverse/reference/generate_isomorphs.md)
to generate items,
[`calibrate_families()`](https://www.okanbulut.com/mirtverse/reference/calibrate_families.md)
to check after field testing that the isomorphs are equally difficult;
the [AI Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.html).

## Examples

``` r
perimeter <- item_model(
  stem = "A garden is {l} m long and {w} m wide. What is its perimeter?",
  key = "{2 * (l + w)} m",
  distractors = c(area = "{l * w} m", one_length_one_width = "{l + w} m",
                  two_lengths_only = "{2 * l + w} m"),
  values = list(l = 5:15, w = 2:9),
  constraints = "l > w",
  name = "PER")
perimeter
#> <mv_item_model> PER
#>   Stem: A garden is {l} m long and {w} m wide. What is its perimeter?
#>   Key:  {2 * (l + w)} m
#>   Distractor 1: {l * w} m  (area)
#>   Distractor 2: {l + w} m  (one length one width)
#>   Distractor 3: {2 * l + w} m  (two lengths only)
#>   l: 5, 6, 7, ..., 14, 15
#>   w: 2, 3, 4, ..., 8, 9
#>   Constraints: l > w 
#>   73 combinations of values meet the constraints; 72 give items whose options all differ.
generate_isomorphs(perimeter, n = 3)
#> PER: 1 of 73 combinations of values give two identical options or cannot be computed, and were left out. Add a constraint to rule them out.
#> # A tibble: 3 × 11
#>   id     model stem              A     B     C     D     key       l     w flag 
#>   <chr>  <chr> <chr>             <chr> <chr> <chr> <chr> <chr> <int> <int> <chr>
#> 1 PER-01 PER   A garden is 5 m … 10 m  14 m  7 m   12 m  B         5     2 ""   
#> 2 PER-02 PER   A garden is 12 m… 60 m  29 m  34 m  17 m  C        12     5 ""   
#> 3 PER-03 PER   A garden is 11 m… 40 m  31 m  20 m  99 m  A        11     9 ""   
```
