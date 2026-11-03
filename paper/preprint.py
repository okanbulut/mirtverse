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
pre = yaml.safe_load(open("preprint.yml", encoding="utf-8"))
ORCID_ICON = ('<svg viewBox="0 0 256 256" width="13" height="13" style="vertical-align:-1.5px">'
              '<circle cx="128" cy="128" r="128" fill="#A6CE39"/>'
              '<rect x="70" y="80" width="18" height="100" fill="#fff"/><circle cx="79" cy="58" r="11" fill="#fff"/>'
              '<path d="M108 80h46c30 0 52 22 52 50s-22 50-52 50h-46zM126 97v66h27c20 0 34-14 34-33s-14-33-34-33z" fill="#fff"/></svg>')
def who(a):
    out = a["name"]
    if a.get("orcid"):
        out += (f' <a href="https://orcid.org/{a["orcid"]}" title="ORCID {a["orcid"]}" '
                f'aria-label="ORCID {a["orcid"]}">{ORCID_ICON}</a>')
    return f'<p class="author">{out}</p>'
authors = "".join(who(a) for a in meta["authors"])
affils = "".join(f'<p class="affil">{a["name"]}</p>' for a in meta["affiliations"])
header = (f'<h1 class="title">{meta["title"]}</h1>{authors}{affils}<p class="date">{pre["date"]}</p>'
          '<p class="preprint-note">Preprint. Not peer reviewed.</p>')
# The author note sits in the bottom margin of the first page as a footnote
note = pre["author_note"].replace("\\", "\\\\").replace('"', '\\"')
page_css = (f'<style>@page {{ size: Letter; margin: 2cm 2.2cm 2cm 2.2cm; '
            f'@bottom-center {{ content: counter(page); font: 8pt Inter, sans-serif; color: #777; }} }} '
            f'@page :first {{ margin-bottom: 3.4cm; @bottom-center {{ content: none; }} '
            f'@bottom-left {{ content: "{note}"; font: 8pt/1.4 Charter, "Bitstream Charter", Georgia, serif; color: #333; '
            f'vertical-align: top; text-align: left; padding-top: 6pt; border-top: 0.6pt solid #999; width: 100%; }} }}</style>')
header = page_css + header
md = "---\ntitle: \"" + meta["title"].replace('"', '\\"') + "\"\nbibliography: paper.bib\ncsl: apa.csl\nlink-citations: true\n---\n\n```{=html}\n" + header + "\n```\n" + body
open("_preprint.md", "w", encoding="utf-8").write(md)
subprocess.run(["pandoc", "_preprint.md", "-s", "--citeproc", "--mathml", "--css", "preprint.css",
                "--embed-resources", "--metadata", "pagetitle=" + meta["title"],
                "--variable", "title=", "-o", "paper-preprint.html"], check=True)
os.remove("_preprint.md")
js = """const { chromium } = require('playwright');
(async () => { const b = await chromium.launch(); const p = await b.newPage();
  await p.goto('file://' + process.cwd() + '/paper-preprint.html'); await p.waitForTimeout(800);
  await p.pdf({ path: 'paper-preprint.pdf', printBackground: true, preferCSSPageSize: true });
  await b.close(); })();"""
open("_pdf.js", "w").write(js)
subprocess.run(["node", "_pdf.js"], check=True, env=dict(os.environ, NODE_PATH=subprocess.check_output(["npm", "root", "-g"], text=True).strip()))
os.remove("_pdf.js")
