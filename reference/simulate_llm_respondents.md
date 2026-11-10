# Simulate respondents with a language model (experimental)

**Experimental.** `simulate_llm_respondents()` asks a language model to
answer multiple-choice items as each of a list of described respondents
("personas") would, and scores the answers. Some researchers use such
"synthetic respondents" or "silicon samples" to try out items before a
field test. Whether their answers behave like real test takers' answers
is an open question, and the evidence so far is mixed: Language models
tend to find items too easy, to answer more consistently than people,
and to act out stereotypes of the groups they are asked to play. Treat
the results as a hypothesis about the items, never as a replacement for
responses from real people, and always check them against real data with
[`compare_synthetic()`](https://www.okanbulut.com/mirtverse/reference/compare_synthetic.md).

## Usage

``` r
simulate_llm_respondents(
  items,
  personas,
  stem = "stem",
  options = NULL,
  key = "key",
  id = "id",
  provider = NULL,
  model = NULL
)
```

## Arguments

- items:

  a data frame with one row per multiple-choice item, such as
  [itemtext](https://www.okanbulut.com/mirtverse/reference/itemtext.md).

- personas:

  the respondents to simulate: A character vector of descriptions ("A
  Grade 7 student who struggles with fractions"), or a data frame with a
  `persona` column and any other columns that describe them (kept in the
  output).

- stem, key, id:

  names of the columns with the stem, the letter of the keyed option and
  the item id.

- options:

  names of the option columns; by default the columns `A` to `E` that
  exist.

- provider, model:

  the language model, as in
  [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md).
  By default the one chosen with
  [`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md),
  or the recordings when
  [`mv_llm_replay()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md)
  is on.

## Value

An object of class `mv_synthetic`: A list with `responses` (a data frame
of scored responses, 1 correct, 0 wrong and `NA` when the model gave no
usable answer, one row per persona and one column per item), `answers`
(the option letters chosen), `personas` (a tibble with an `id` and the
persona columns), `items` (item ids and keys), `provider` and `model`.
It has [`print()`](https://rdrr.io/r/base/print.html) and
[`compare_synthetic()`](https://www.okanbulut.com/mirtverse/reference/compare_synthetic.md)
methods; pass `$responses` to
[`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html)
like any response data.

## Details

Each persona is one request, which lists every item. The model is asked
to answer as the persona would, mistakes included, and to give one
option letter per item.

The function and its output may change in later versions of mirtverse.

## References

Argyle, L. P., Busby, E. C., Fulda, N., Gubler, J. R., Rytting, C., &
Wingate, D. (2023). Out of one, many: Using language models to simulate
human samples. *Political Analysis, 31*(3), 337-351.

## See also

[`compare_synthetic()`](https://www.okanbulut.com/mirtverse/reference/compare_synthetic.md);
the book's chapter on large language models; the [AI
Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.html).

## Examples

``` r
# \donttest{
if (requireNamespace("ellmer", quietly = TRUE)) {
  old <- mv_llm_replay()        # answer from the recordings that come with mirtverse
  items <- itemtext[endsWith(itemtext$id, "-01"), ]
  personas <- c(
    "A Grade 7 student who struggles with mathematics.",
    "A Grade 7 student who struggles with mathematics and is still learning English.",
    "A Grade 7 student who finds fractions and decimals hard but tries every question.",
    "A Grade 7 student who often rushes and makes careless mistakes.",
    "A Grade 7 student who is about average in mathematics.",
    "A Grade 7 student who is about average in mathematics and is still learning English.",
    "A Grade 7 student with average marks who is anxious on tests.",
    "A Grade 7 student who is about average in mathematics and likes word problems.",
    "A Grade 7 student who is strong in mathematics.",
    "A Grade 7 student who is strong in mathematics and is still learning English.",
    "A Grade 7 student in an enriched mathematics program.",
    "A Grade 7 student who is strong in mathematics but reads slowly.")
  syn <- simulate_llm_respondents(items, personas)
  syn
  compare_synthetic(syn, stats::setNames(items$p_field, items$id))
  options(old)
}
#> Language model calls now answer from examples.json (26 recorded requests).
# }
```
