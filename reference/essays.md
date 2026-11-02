# Short science explanations scored by raters, for the AI Hub

1,600 simulated written answers of 400 Grade 8 students (100 of them
English language learners, ELL) to four science prompts, each scored 0
to 4 by trained raters. A response's true score is the number of the
prompt's four key ideas it states correctly. The prompts are E1 (why ice
floats), E2 (why Earth has seasons), E3 (how plants make food) and E4
(why a metal spoon feels colder than a wooden one).

## Usage

``` r
essays
```

## Format

A data frame with 1,600 rows (one per response) and 8 columns: `id`
(response ID), `student` (student ID), `prompt` (`E1` to `E4`), `group`
(factor, `Fluent` or `ELL`), `response` (the text), `words` (number of
words), `human1` (first rater's score, 0 to 4) and `human2` (second
rater's score, `NA` when the response was read once).

## Source

Simulated; the script is `data-raw/essays.R` in the package's GitHub
repository.

## Details

The dataset is for learning automated scoring: training a scorer on the
text, checking machine-human agreement, and checking that the scorer is
fair to ELL students. Some problems were planted on purpose;
`lab_truth("essays")` lists them and the true scores. Every response has
one human score (`human1`); 40% were scored again (`human2`) so that
human-human agreement can be compared with machine-human agreement.

## See also

[itemtext](https://www.okanbulut.com/mirtverse/reference/itemtext.md),
the other AI Hub dataset;
[`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md)
to score responses and check them against human scores.

## Examples

``` r
essays$response[1:3]
#> [1] "Let me explain what I think is going on here. I learned about this in class last year. Frozen water has a lower density than the water around it. In ice the water molecules are locked into a crystal structure with lots of empty space. Objects that are less dense than a fluid float because the buoyant force is greater than their weight. That is why this happens."
#> [2] "Our planet is tilted on its axis. Because the tilt stays pointed the same way, each hemisphere takes turns facing the Sun. Seasons happen because the weather changes."                                                                                                                                                                                                     
#> [3] "This is something that we can see in everyday life. There are a few reasons why this happens. Green plants carry out photosynthesis to make their food. The raw materials are carbon dioxide and water. This shows that science can explain things we see every day."                                                                                                       
table(essays$prompt, essays$human1)
#>     
#>        0   1   2   3   4
#>   E1  51 105 101  77  66
#>   E2  76 108  98  75  43
#>   E3  35  75  88 105  97
#>   E4  93  92  93  87  35
# human-human agreement on the double-scored responses
with(essays, mean(human1 == human2, na.rm = TRUE))
#> [1] 0.7725948
```
