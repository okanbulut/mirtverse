// Render the mirtverse cheat sheets (English and Turkish) to PDF and a PNG preview of each page.
// Run from the package root: node data-raw/cheatsheet/build.js
const { chromium } = require('playwright');
const path = require('path');

const sheets = [
  { src: 'cheatsheet.html', out: 'mirtverse-cheatsheet' },
  { src: 'cheatsheet-tr.html', out: 'mirtverse-cheatsheet-tr' },
];

(async () => {
  const out = path.resolve(__dirname, '../../pkgdown/assets/cheatsheet');
  require('fs').mkdirSync(out, { recursive: true });
  const browser = await chromium.launch();
  for (const s of sheets) {
    const page = await browser.newPage({ viewport: { width: 1056, height: 816 }, deviceScaleFactor: 2 });
    await page.goto('file://' + path.resolve(__dirname, s.src));
    await page.evaluate(() => document.fonts.ready);
    await page.pdf({ path: path.join(out, s.out + '.pdf'), width: '11in', height: '8.5in',
                     printBackground: true, preferCSSPageSize: true });
    const pages = await page.$$('.page');
    for (let i = 0; i < pages.length; i++) {
      await pages[i].screenshot({ path: path.join(out, `${s.out}-${i + 1}.png`) });
    }
    await page.close();
  }
  await browser.close();
})();
