# Set up an AI model for mv_ask()

Chooses which AI model
[`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
uses to understand plain-language requests and stores the API key so you
only do this once. Three providers are supported through the ellmer
package:

## Usage

``` r
mv_ask_setup(
  provider = c("claude", "openai", "ollama", "none"),
  model = NULL,
  key = NULL,
  save = c("ask", "renviron", "keyring", "none"),
  test = TRUE
)
```

## Arguments

- provider:

  `"claude"`, `"openai"`, `"ollama"` or `"none"`.

- model:

  model name; defaults to `"claude-opus-5-5"` for Claude, the ellmer
  default for OpenAI and the first installed model for Ollama.

- key:

  the API key. If `NULL` and none is set, you are asked for it with a
  masked prompt.

- save:

  where to keep the key and settings for future sessions: `"ask"`
  (choose interactively), `"renviron"` (your `.Renviron` file),
  `"keyring"` (the system keychain, needs the keyring package) or
  `"none"` (this session only).

- test:

  logical; send one tiny test request to check the setup.

## Value

The provider and model, invisibly.

## Details

- `"claude"`: Anthropic's Claude, with your own key from
  <https://console.anthropic.com> (stored as `ANTHROPIC_API_KEY`).

- `"openai"`: OpenAI's GPT models, with your own key from
  <https://platform.openai.com> (stored as `OPENAI_API_KEY`).

- `"ollama"`: a free model running on your own computer with Ollama
  (<https://ollama.com>). Install Ollama, run `ollama pull qwen2.5` (or
  another model) once, and nothing ever leaves your machine.

Use `provider = "none"` to always use the built-in keyword parser, which
needs no AI model and no internet connection.

Only a summary of your columns (see
[`profile_data()`](https://www.okanbulut.com/mirtverse/reference/profile_data.md))
and your request are sent; never individual responses. Keys are never
written into scripts, reports or `mv_script` objects.

## Examples

``` r
if (FALSE) { # \dontrun{
mv_ask_setup("claude")
mv_ask_setup("ollama", model = "qwen2.5")
} # }
```
