// Render the "Which IRT model?" flowchart to PDF and PNG.
// Run from the package root: node data-raw/which-model/build.js
// The QR code (qr.svg) points to articles/which-model.html and was made with
// the Python package segno: segno.make(url, error = "m").save("qr.svg", border = 0, scale = 4).
const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const src = path.resolve(__dirname, 'poster.html');
  const out = path.resolve(__dirname, '../../pkgdown/assets/which-model');
  require('fs').mkdirSync(out, { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1056, height: 816 }, deviceScaleFactor: 2 });
  await page.goto('file://' + src);
  await page.evaluate(() => document.fonts.ready);
  await page.pdf({ path: path.join(out, 'which-irt-model.pdf'), width: '11in', height: '8.5in',
                   printBackground: true, preferCSSPageSize: true });
  await (await page.$('.page')).screenshot({ path: path.join(out, 'which-irt-model.png') });
  await browser.close();
})();
