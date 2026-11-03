#!/bin/sh
# Builds the sample syllabus as an editable Word file and a PDF into
# pkgdown/assets/adopt/. Run from the package root: sh data-raw/syllabus/build.sh
# Needs pandoc and Node with Playwright (for the PDF).
set -e
out=pkgdown/assets/adopt
mkdir -p "$out"
pandoc data-raw/syllabus/sample-syllabus.md -o "$out/mirtverse-sample-syllabus.docx"
pandoc data-raw/syllabus/sample-syllabus.md -s --embed-resources \
  -c data-raw/syllabus/style.css -o data-raw/syllabus/sample-syllabus.html
node -e "
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  await p.goto('file://' + process.cwd() + '/data-raw/syllabus/sample-syllabus.html');
  await p.pdf({ path: '$out/mirtverse-sample-syllabus.pdf', format: 'Letter', printBackground: true,
                margin: { top: '0.7in', bottom: '0.7in', left: '0.75in', right: '0.75in' } });
  await b.close();
})();"
rm data-raw/syllabus/sample-syllabus.html
