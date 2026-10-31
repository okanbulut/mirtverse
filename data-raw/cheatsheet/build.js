// Render the mirtverse cheat sheet to PDF and a PNG preview of each page.
// Run from the package root: node data-raw/cheatsheet/build.js
const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const src = path.resolve(__dirname, 'cheatsheet.html');
  const out = path.resolve(__dirname, '../../pkgdown/assets/cheatsheet');
  require('fs').mkdirSync(out, { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1056, height: 816 }, deviceScaleFactor: 2 });
  await page.goto('file://' + src);
  await page.evaluate(() => document.fonts.ready);
  await page.pdf({ path: path.join(out, 'mirtverse-cheatsheet.pdf'), width: '11in', height: '8.5in',
                   printBackground: true, preferCSSPageSize: true });
  const pages = await page.$$('.page');
  for (let i = 0; i < pages.length; i++) {
    await pages[i].screenshot({ path: path.join(out, `mirtverse-cheatsheet-${i + 1}.png`) });
  }
  await browser.close();
})();
