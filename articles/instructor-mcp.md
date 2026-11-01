# An AI assistant for your course materials

mirtverse comes with an **MCP server** for instructors. MCP, the [Model
Context Protocol](https://modelcontextprotocol.io), is the standard way
AI assistants connect to tools. Once you connect your assistant to the
mirtverse server, it can open, edit and test the teaching materials in
your course folder. You describe what you want in plain words, for
example:

> *Add a question on local dependence to Lab 1, after the Q3 heatmap.*
>
> *Use my midterm data (`data/midterm.csv`) in the fairness lab instead
> of the numeracy test. The group variable is `campus`.*
>
> *Here are my old lecture notes on the Rasch model, written with ltm.
> Turn them into a mirtverse chapter, but keep my examples.*

The assistant reads your files, makes the change with the mirtverse
instructor tools, runs the material to check that it still works, and
tells you what it changed. It works with Claude (Desktop and Claude
Code) and with OpenAI (Codex, the Agents SDK, and ChatGPT).

## What the assistant can do

The server gives the assistant these tools. You never call them
yourself; the assistant picks them.

| Task | Tools |
|----|----|
| See what is in your course | `course_overview`, `list_materials`, `read_material` |
| Change files | `edit_material` (part of a file), `write_material` (new or whole file), `undo_last_change` |
| Build and change labs | `copy_lab`, `new_lab`, `lab_outline`, `add_lab_section`, `add_lab_exercise`, `add_lab_question`, `remove_lab_section`, `swap_lab_data` |
| Chapters and notes | `copy_chapter`, `new_chapter`, `swap_chapter_data` |
| Use your own data | `describe_dataset` |
| Bring in existing materials | `scan_material`, `translate_code` (uses [`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md)) |
| Get it right | `mirtverse_help` (real function names and arguments), `guide` (lab and chapter style), `check_material` (runs the material) |

The lab and chapter tools use the functions of the [instructor
toolkit](https://www.okanbulut.com/mirtverse/articles/instructor-toolkit.md),
so anything the assistant builds is the same as what you would build by
hand.

It also offers three ready-made requests (MCP “prompts”), which appear
in clients that show them, such as the `+` menu in Claude Desktop or `/`
in Claude Code:

- **Revise a teaching material**: give a file and say what to change.
- **Adapt my materials to mirtverse**: give an existing lab, notes file
  or script.
- **Build a lab on my data**: give a data file and a topic.

## Safety

- **Only your course folder.** The assistant can read and write files
  only inside the folder you choose. It cannot see the rest of your
  computer.
- **Every change can be undone.** Before each change the server backs up
  the files it touches (in a hidden `.mirtverse-mcp` folder inside your
  course). Ask the assistant to “undo the last change”, or to undo the
  last change to a particular file.
- **Your originals are kept.** When adapting existing materials, the
  assistant writes the new version to a new file unless you ask it to
  replace the original.
- **Running code.** `check_material` runs your materials’ R code in a
  separate R session on your computer, as you would when knitting them.
  It is on by default for desktop clients and off for ChatGPT (see
  below).
- **Your data.** The assistant’s AI provider sees what the tools return:
  file contents, and summaries of datasets (column names, value ranges
  and counts, not the full data). Do not put identifiable student data
  in the course folder, or check your institution’s rules on AI tools
  first.

## Set up

You need R with mirtverse installed (and learnr, for labs). Pick a
folder for your course, such as `~/courses/edpy507`. If you already used
the instructor toolkit, use that course folder; otherwise the assistant
can set one up for you.

[`mv_mcp_config()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_config.md)
prints the exact settings for your computer, with the full path to R
filled in:

``` r

library(mirtverse)
mv_mcp_config("~/courses/edpy507", client = "claude-desktop")
```

### Claude Desktop

1.  Run `mv_mcp_config("~/courses/edpy507", client = "claude-desktop")`.
2.  In Claude Desktop, open **Settings \> Developer \> Edit Config**.
    This opens `claude_desktop_config.json`.
3.  Paste the `"mirtverse"` entry inside `"mcpServers"` (create
    `"mcpServers"` if the file is empty), save, and restart Claude
    Desktop.
4.  Start a new chat. The mirtverse tools appear under the tools icon.
    Try *“What is in my course?”*

The result looks like this (your paths will differ):

``` json
{
  "mcpServers": {
    "mirtverse": {
      "command": "/Library/Frameworks/R.framework/Resources/bin/Rscript",
      "args": ["-e", "mirtverse::mv_mcp_server('/Users/you/courses/edpy507')"]
    }
  }
}
```

### Claude Code

Run the command that `mv_mcp_config(client = "claude-code")` prints,
once, in a terminal:

``` bash
claude mcp add mirtverse -- "/usr/local/bin/Rscript" -e "mirtverse::mv_mcp_server('/Users/you/courses/edpy507')"
```

### OpenAI Codex

Codex (the command-line tool and the IDE extension) reads
`~/.codex/config.toml`. Add the block that
`mv_mcp_config(client = "codex")` prints:

``` toml
[mcp_servers.mirtverse]
command = "/usr/local/bin/Rscript"
args = ["-e", "mirtverse::mv_mcp_server('/Users/you/courses/edpy507')"]
startup_timeout_sec = 30
tool_timeout_sec = 900
```

### OpenAI Agents SDK

If you script with the OpenAI Agents SDK for Python,
`mv_mcp_config(client = "openai-agents")` prints a starting point that
connects an agent to the server with `MCPServerStdio`.

### ChatGPT

ChatGPT connects to servers by URL rather than starting them itself, so
the server has to run over HTTP and be reachable from the internet. At
the time of writing this needs ChatGPT’s **developer mode** (Settings \>
Apps & Connectors \> Advanced), which is available on some plans only.

1.  In R, start the server over HTTP:

    ``` r

    mv_mcp_server("~/courses/edpy507", transport = "http", port = 8765)
    ```

    It prints a URL such as `http://127.0.0.1:8765/mcp/k3v9...`. The
    random last part is a secret: only people who know it can reach the
    server.

2.  Make the port reachable with a tunnel, for example `ngrok http 8765`
    or `cloudflared tunnel --url http://localhost:8765`.

3.  In ChatGPT, create a connector with the tunnel address followed by
    `/mcp/<secret>` and no authentication.

Over HTTP, `check_material` is off unless you start the server with
`allow_run = TRUE`, because anyone with the URL could otherwise run R
code on your computer. Stop the server (Esc or Ctrl+C in R) when you are
done.

## Tips

- **Start each conversation with the big picture**: which course, which
  students, what they already know. The assistant keeps your voice
  better when it knows your audience.
- **Ask for a plan first** for large changes (“tell me what you would
  change before you do it”).
- **Check its work.** The assistant runs `check_material` after every
  change, but you know your course: preview a changed lab with
  [`learnr::run_tutorial()`](https://pkgs.rstudio.com/learnr/reference/run_tutorial.html)
  or the Run Document button before your students see it.
- **Let it look things up.** If the assistant seems unsure about a
  function, ask it to check `mirtverse_help`.

## For developers

The server is written in R with no extra dependencies and speaks MCP
(protocol versions 2024-11-05 to 2025-11-25) over stdio or Streamable
HTTP (JSON responses, no server-sent events). Tools that need the
instructor toolkit appear only when the installed mirtverse has it. See
[`?mv_mcp_server`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_server.md)
for all options.
