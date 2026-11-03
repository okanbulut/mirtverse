# Demo videos

Silent screen recordings for the narrated demo clips. Narration is recorded
separately (ElevenLabs) and combined with ffmpeg.

- `workbench-tour.js`: Drives the Shiny workbench with Playwright.
- Code clips (AI Hub, thesis kit): `Rscript assets.R` writes the real R output
  and plots, `python3 build.py ai` (or `th`) fills `player.html` with a
  timeline, and `node rec.js ai 92` records it. Copy `man/figures/home-ai.svg`
  next to the files first. Render `methods.docx` to PNG with LibreOffice and
  pdftoppm for the thesis clip.
