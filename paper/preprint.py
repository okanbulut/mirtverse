"""Build a preprint PDF from the JOSS-style paper.md.

Run from this folder: python3 preprint.py. Needs pandoc (3.x) with citeproc
and Node with Playwright. Writes paper-preprint.html and paper-preprint.pdf.
"""
import re, subprocess, os, yaml
src = open("paper.md", encoding="utf-8").read()
_, front, body = src.split("---", 2)
meta = yaml.safe_load(front)
# JOSS's \autoref{fig:x} becomes "Figure N", numbered by order of the figures
labels = re.findall(r"\\label\{(fig:[^}]+)\}", body)
for i, lab in enumerate(labels, 1):
    body = body.replace(f"\\autoref{{{lab}}}", f"Figure {i}")
    body = re.sub(r"!\[(.*?)\\label\{" + re.escape(lab) + r"\}\]", lambda m: f"![Figure {i}. {m.group(1)}]", body)
authors = "".join(f'<p class="author">{a["name"]}</p>' for a in meta["authors"])
affils = "".join(f'<p class="affil">{a["index"]}. {a["name"]}</p>' for a in meta["affiliations"])
header = (f'<h1 class="title">{meta["title"]}</h1>{authors}{affils}<p class="date">{meta["date"]}</p>'
          '<p class="preprint-note">Preprint. Not peer reviewed.</p>')
md = "---\ntitle: \"" + meta["title"].replace('"', '\\"') + "\"\nbibliography: paper.bib\ncsl: apa.csl\nlink-citations: true\n---\n\n```{=html}\n" + header + "\n```\n" + body
open("_preprint.md", "w", encoding="utf-8").write(md)
subprocess.run(["pandoc", "_preprint.md", "-s", "--citeproc", "--mathml", "--css", "preprint.css",
                "--embed-resources", "--metadata", "pagetitle=" + meta["title"],
                "--variable", "title=", "-o", "paper-preprint.html"], check=True)
os.remove("_preprint.md")
js = """const { chromium } = require('playwright');
(async () => { const b = await chromium.launch(); const p = await b.newPage();
  await p.goto('file://' + process.cwd() + '/paper-preprint.html'); await p.waitForTimeout(800);
  await p.pdf({ path: 'paper-preprint.pdf', format: 'Letter', printBackground: true,
    displayHeaderFooter: true, headerTemplate: '<span></span>',
    footerTemplate: '<div style="font-size:8px;width:100%;text-align:center;color:#777"><span class="pageNumber"></span></div>',
    margin: { top: '2cm', bottom: '2cm', left: '2.2cm', right: '2.2cm' } });
  await b.close(); })();"""
open("_pdf.js", "w").write(js)
subprocess.run(["node", "_pdf.js"], check=True, env=dict(os.environ, NODE_PATH=subprocess.check_output(["npm", "root", "-g"], text=True).strip()))
os.remove("_pdf.js")
