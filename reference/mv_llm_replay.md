# Replay or record language model responses

`mv_llm_replay()` makes every mirtverse function that calls a language
model
([`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md),
[`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md),
[`verify_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md),
[`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md),
[`review_packet()`](https://www.okanbulut.com/mirtverse/reference/review_packet.md)
with `ai_screen = TRUE`,
[`simulate_llm_respondents()`](https://www.okanbulut.com/mirtverse/reference/simulate_llm_respondents.md)
and
[`mv_kg_extract()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_extract.md))
answer from a file of recorded responses instead of a live model.
Nothing is sent anywhere, no API key is needed, and the same request
always gets the same answer, so examples, labs and lessons run offline
and give the same results for every student.

## Usage

``` r
mv_llm_replay(file = NULL)

mv_llm_record(file, append = TRUE)

mv_llm_recordings(file = NULL)
```

## Arguments

- file:

  path to a recording (a `.json` file). For `mv_llm_replay()` the
  default is the example file that comes with mirtverse; `FALSE` turns
  replay off. For `mv_llm_record()`, `NULL` stops recording.

- append:

  logical; add to an existing recording rather than start a new one.

## Value

`mv_llm_replay()` returns the previous settings invisibly, so you can
restore them with [`options()`](https://rdrr.io/r/base/options.html).
`mv_llm_record()` returns the file path invisibly. `mv_llm_recordings()`
returns a data frame with one row per recorded request.

## Details

`mv_llm_record()` does the opposite: While it is on, every request sent
to a live model and the model's answer are saved to a file, which
`mv_llm_replay()` can play back later. Use it to capture a session once
and teach from it many times.

A recording answers only the exact requests it was made from: The same
instructions to the model and the same prompt, which follow from the
same function call on the same data. A request that is not in the file
stops with an error that says so; run it with a live model, or record
it.

mirtverse comes with a small example file used in the AI Hub articles
and the online book. Its responses were written by the package authors
to show what a model returns, including a few deliberate mistakes for
the checks to catch; they were not produced by a live model. The calls
they answer are in
`system.file("replay", "examples.R", package = "mirtverse")`.

## See also

[`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md)
to use a live model.

## Examples

``` r
# answer from the example recordings that come with mirtverse
old <- mv_llm_replay()
#> Language model calls now answer from examples.json (26 recorded requests).
head(mv_llm_recordings()[, c("function_name", "prompt_start")])
#> # A tibble: 6 × 2
#>   function_name  prompt_start                                                  
#>   <chr>          <chr>                                                         
#> 1 mv_ask         "Request: Fit a graded response model to these attitude items"
#> 2 generate_items "Construct: Grade 7 numeracy Test takers: Grade 7 students Sc"
#> 3 generate_items "Construct: Grade 7 numeracy Test takers: Grade 7 students Sc"
#> 4 verify_items   "A recipe uses 3 cups of flour for every 2 cups of milk. How "
#> 5 verify_items   "A cyclist rides 45 km in 3 hours at a steady speed. How far "
#> 6 verify_items   "A garden is 12 m long and 7 m wide. How many metres of fenci"
options(old)

if (FALSE) { # \dontrun{
# record a live session, then replay it offline
mv_ask_setup("claude")
mv_llm_record("my-session.json")
p <- generate_items(p, n = 10)
mv_llm_record(NULL)
mv_llm_replay("my-session.json")
p2 <- generate_items(p0, n = 10)   # same items, no model called
} # }
```
