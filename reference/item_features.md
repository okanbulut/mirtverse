# Text features of test items

Describes each item by features that can be read off its text before
anyone answers it: How long and how hard to read the stem is, how many
and how large its numbers are, whether it uses decimals or fractions or
a negation, and, for multiple-choice items, what its options look like.
It also finds each item's most similar other item, to flag
near-duplicates. Everything runs in base R.

## Usage

``` r
item_features(items, stem = "stem", options = NULL, key = "key", id = "id")
```

## Arguments

- items:

  a data frame with one row per item.

- stem:

  name of the column that holds the stem (question text).

- options:

  names of the option columns; `NULL` uses whichever of `A` to `E`
  exist. Use `character(0)` for items without options.

- key:

  name of the column with the keyed option (a letter matching one of
  `options`); ignored when absent.

- id:

  name of the item id column; when absent, items are numbered.

## Value

A tibble with one row per item: `id` and the features above.

## Details

The features are the item covariates of an explanatory IRT model such as
the linear logistic test model (LLTM): Pass them with the items'
difficulties to
[`predict_difficulty()`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md).
They are deliberately simple and transparent. Your own features (an item
writer's rating of the number of solution steps, or text embeddings from
a language model) can be joined by `id` and used in the same way.

The features are:

- `words`, `sentences`: Words (including numbers) and sentences in the
  stem.

- `word_length`: Mean letters per word.

- `grade`: Flesch-Kincaid grade level of the stem, from words per
  sentence and syllables per word.

- `numbers`, `max_digits`: How many numbers the stem contains, and the
  digits in the whole part of the largest one.

- `decimals`: 1 if the stem or the keyed option uses decimals or
  fractions (whole amounts of money such as \$5.00 do not count).

- `negation`: 1 if the stem contains not, never, no, except, least or
  false.

- `option_words`: Mean words per option.

- `key_longest`: 1 if the keyed option is longer than every other
  option, a classic item-writing flaw.

- `distractor_distance`: For numeric options, the median distance of the
  distractors from the key, relative to the key (`NA` when the options
  are not all numbers). Close distractors usually make an item harder.

- `option_overlap`: Mean word overlap (Jaccard) between pairs of
  options.

- `similarity`, `nearest`: The overlap (Jaccard) of the two-word
  sequences in the item's stem and options with those of its most
  similar other item, and that item's id. Values near 1 mark
  near-duplicates; items written from the same template with different
  numbers score lower, because every changed number breaks two
  sequences.

## See also

[`predict_difficulty()`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md)
to predict difficulty from the features; the [AI
Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.html).

## Examples

``` r
f <- item_features(itemtext)
f
#> # A tibble: 192 × 15
#>    id     words sentences word_length grade numbers max_digits decimals negation
#>    <chr>  <int>     <int>       <dbl> <dbl>   <int>      <int>    <int>    <int>
#>  1 N01-01    13         2        3.91   0.9       2          2        0        0
#>  2 N01-02    21         3        4.05   0.8       2          2        0        0
#>  3 N01-03    21         3        3.79   2         2          2        0        0
#>  4 N01-04    13         2        3.91   0.9       2          2        0        0
#>  5 N01-05    13         2        3.91   0.9       2          2        0        0
#>  6 N01-06    21         3        4.05   0.8       2          2        0        0
#>  7 N01-07    13         2        3.91   0.9       2          2        0        0
#>  8 N01-08    13         2        3.91   0.9       2          2        0        0
#>  9 N01-09    20         3        3.78   1.4       2          1        1        0
#> 10 N01-10    13         2        3.91   0.9       2          2        1        0
#> # ℹ 182 more rows
#> # ℹ 6 more variables: option_words <dbl>, key_longest <int>,
#> #   distractor_distance <dbl>, option_overlap <dbl>, similarity <dbl>,
#> #   nearest <chr>
# surface features and difficulty
round(cor(f[, c("words", "max_digits", "decimals")], itemtext$b), 2)
#>             [,1]
#> words       0.00
#> max_digits -0.11
#> decimals    0.14
# the most similar pairs of items
head(f[order(-f$similarity), c("id", "nearest", "similarity")])
#> # A tibble: 6 × 3
#>   id     nearest similarity
#>   <chr>  <chr>        <dbl>
#> 1 N01-02 N01-14       0.92 
#> 2 N01-14 N01-02       0.92 
#> 3 N06-05 N06-12       0.867
#> 4 N06-12 N06-05       0.867
#> 5 N08-01 N08-04       0.613
#> 6 N08-02 N08-11       0.613
```
