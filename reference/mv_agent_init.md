# Set up a folder for the mirtverse agent in Claude Code

Writes the files that turn a folder into a mirtverse analysis project
for Claude Code, for people who do not install the mirtverse plugin: A
`CLAUDE.md` that tells Claude how to work (which tools to use, which
checks to run, how to explain results) and a `.mcp.json` that starts
[`mv_agent_server()`](https://www.okanbulut.com/mirtverse/reference/mv_agent_server.md)
in the folder. Open the folder in Claude Code afterwards and approve the
`mirtverse` server when Claude asks.

## Usage

``` r
mv_agent_init(path = ".", title = NULL, overwrite = FALSE)
```

## Arguments

- path:

  the project folder. It is created if needed.

- title:

  optional project title, written at the top of `CLAUDE.md`.

- overwrite:

  logical; replace existing files. Without it, existing files are left
  alone and reported.

## Value

The paths of the files written, invisibly.

## Details

The `CLAUDE.md` is plain text, so edit it to add what Claude should know
about your project, such as what the test measures, who took it, and how
results should be reported.

## See also

[`mv_agent_server()`](https://www.okanbulut.com/mirtverse/reference/mv_agent_server.md)

## Examples

``` r
dir <- file.path(tempdir(), "math-test")
mv_agent_init(dir, title = "Grade 8 math test, spring 2026")
#> Wrote CLAUDE.md and .mcp.json in /tmp/RtmpyaT2l9/math-test.
#> Put your data files in the folder, open it in Claude Code (`claude` in a terminal),
#> approve the mirtverse server, and ask, for example: "Analyze exam.csv".
list.files(dir, all.files = TRUE, no.. = TRUE)
#> [1] ".mcp.json"        "CLAUDE.md"        "mirtverse-output"
```
