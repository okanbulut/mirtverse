# Score mv_ask() request parsing on the benchmark requests.
# Each AI run sends 100 short requests (column summaries only) to the provider.
library(mirtverse)

rules <- mirtverse:::ask_benchmark("none")
# claude <- mirtverse:::ask_benchmark("claude")
# gpt    <- mirtverse:::ask_benchmark("openai")
# local  <- mirtverse:::ask_benchmark("ollama", model = "qwen2.5")

# requests the parser got wrong
subset(rules, !correct, c(id, request, model, group, missing, items, steps, error))
