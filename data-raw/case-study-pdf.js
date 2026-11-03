// Prints the case-study technical report to PDF. Run from the package root
// after data-raw/case-study.R: node data-raw/case-study-pdf.js
const { chromium } = require('playwright');
(async () => {
  const dir = process.cwd() + '/pkgdown/assets/case-study/';
  const b = await chromium.launch(); const p = await b.newPage();
  await p.goto('file://' + dir + 'certification-technical-report.html', { waitUntil: 'networkidle' });
  await p.pdf({ path: dir + 'certification-technical-report.pdf', format: 'Letter', printBackground: true,
                margin: { top: '0.6in', bottom: '0.6in', left: '0.6in', right: '0.6in' } });
  await b.close();
})();
