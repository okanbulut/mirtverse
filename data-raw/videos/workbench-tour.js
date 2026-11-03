// Records the silent workbench tour (data-raw/videos). Start the app first:
//   Rscript -e "shiny::runApp(mirtverse::workbench_app(), port = 8765)"
// then run: node workbench-tour.js, and trim the lead-in with ffmpeg -ss <offset from meta.json>.
const { chromium } = require('playwright');
const fs = require('fs');
// Scene start times (s) — must match the narration script.
const S = [0, 10, 20, 30, 48, 60, 70, 80, 95];
const TITLES = ['', '1 · Load your data', '2 · Explore', '3 · Compare models', '4 · Read the results',
  '5 · Graphics', '6 · Item health cards', '7 · Report & reproducible code'];
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 1280, height: 720 },
    recordVideo: { dir: 'raw', size: { width: 1280, height: 720 } } });
  const tCtx = Date.now();
  const p = await ctx.newPage();
  await p.addInitScript(() => {
    window.addEventListener('DOMContentLoaded', () => {
      const st = document.createElement('style');
      st.textContent = `
      #vcur{position:fixed;z-index:99999;width:22px;height:22px;margin:-11px 0 0 -11px;border-radius:50%;
        background:rgba(230,120,30,.35);border:2px solid rgba(230,120,30,.9);pointer-events:none;transition:transform .15s}
      #vcur.down{transform:scale(.6)}
      #vcap{position:fixed;z-index:99998;left:24px;bottom:24px;padding:10px 18px;border-radius:8px;
        background:rgba(22,50,79,.92);color:#fff;font:600 20px/1.2 Inter,system-ui,sans-serif;
        opacity:0;transition:opacity .5s;pointer-events:none}
      #vcode{position:fixed;z-index:99998;right:28px;bottom:28px;padding:14px 20px;border-radius:8px;
        background:#1e1e1e;color:#e6e6e6;font:500 22px/1.3 'DejaVu Sans Mono',monospace;opacity:0;transition:opacity .6s;
        box-shadow:0 6px 24px rgba(0,0,0,.25);pointer-events:none}
      #vend{position:fixed;inset:0;z-index:100000;background:#16324f;color:#fff;display:flex;flex-direction:column;
        align-items:center;justify-content:center;opacity:0;transition:opacity .8s;pointer-events:none;font-family:Inter,system-ui,sans-serif}
      #vend h1{font-size:56px;margin:0 0 12px;font-weight:700}#vend p{font-size:24px;margin:6px;opacity:.9}`;
      document.head.appendChild(st);
      for (const id of ['vcur','vcap','vcode','vend']) { const d = document.createElement('div'); d.id = id; document.body.appendChild(d); }
      document.getElementById('vcode').innerHTML = '<span style="color:#9cdcfe">mirtverse</span>::<span style="color:#dcdcaa">launch_workbench</span>()';
      document.getElementById('vend').innerHTML = '<h1>mirtverse</h1><p>From item responses to defensible decisions,<br>with or without writing R code.</p><p style="margin-top:22px;font-weight:600">okanbulut.com/mirtverse</p>';
      const c = document.getElementById('vcur'); c.style.left = '640px'; c.style.top = '400px';
      addEventListener('mousemove', e => { c.style.left = e.clientX + 'px'; c.style.top = e.clientY + 'px'; });
      addEventListener('mousedown', () => c.classList.add('down')); addEventListener('mouseup', () => c.classList.remove('down'));
    });
  });
  await p.goto('http://127.0.0.1:8765');
  await p.waitForTimeout(3500);
  const t0 = Date.now();                       // video time zero (trim point)
  const off = (t0 - tCtx) / 1000;
  const at = async s => { const w = t0 + s * 1000 - Date.now(); if (w > 0) await p.waitForTimeout(w); else console.log('late', s, -w); };
  const cap = async t => p.evaluate(t => { const e = document.getElementById('vcap'); e.style.opacity = 0;
      setTimeout(() => { e.textContent = t; e.style.opacity = t ? 1 : 0; }, t ? 450 : 0); }, t);
  const show = async (id, on) => p.evaluate(([id, on]) => document.getElementById(id).style.opacity = on ? 1 : 0, [id, on]);
  const moveTo = async (sel, dx = 0.5, dy = 0.5) => { await p.locator(sel).first().scrollIntoViewIfNeeded().catch(()=>{}); await p.waitForTimeout(150); const bb = await p.locator(sel).first().boundingBox(); if (!bb) { console.log("nobox", sel); return; }
    await p.mouse.move(bb.x + bb.width * dx, bb.y + bb.height * dy, { steps: 14 }); await p.waitForTimeout(250); };
  const click = async sel => { await moveTo(sel); await p.mouse.down(); await p.waitForTimeout(90); await p.mouse.up(); };
  const scroll = async (dy, n = 20, ms = 40) => { for (let i = 0; i < n; i++) { await p.mouse.wheel(0, dy / n); await p.waitForTimeout(ms); } };
  const pick = async (id, text) => { await click(`#${id}-selectized`); await p.waitForTimeout(700);
    const opt = `#${id} ~ .selectize-control .selectize-dropdown .option:text-is("${text}")`;
    await moveTo(opt); await p.waitForTimeout(300); await p.locator(opt).first().click(); };

  // Scene 0: intro
  await at(1.5); await show('vcode', true);
  await at(8.5); await show('vcode', false);
  // Scene 1: data
  await at(S[1]); await cap(TITLES[1]);
  await moveTo('label:has-text("Example data")'); await p.waitForTimeout(300);
  await click('.selectize-control.single .selectize-input'); await p.waitForTimeout(900);
  await moveTo('.selectize-dropdown .option:has-text("SAT12")'); await p.waitForTimeout(400);
  await p.locator('.selectize-dropdown .option:has-text("SAT12")').click();
  await p.waitForTimeout(2500); await moveTo('#preview', 0.5, 0.4); await scroll(300, 15, 60);
  // Scene 2: explore
  await at(S[2]); await cap(TITLES[2]);
  await click('a.nav-link:has-text("2. Explore")'); await p.waitForTimeout(2500);
  await moveTo('#itemstats', 0.4, 0.4); await p.waitForTimeout(1500); await scroll(500, 25, 80);
  // Scene 3: model
  await at(S[3]); await cap(TITLES[3]);
  await click('a.nav-link:has-text("3. Model")'); await p.waitForTimeout(1500);
  await moveTo('label:has-text("Compare models")'); await p.waitForTimeout(1200);
  await click('#fit');
  await p.waitForSelector('#sel_plot img', { timeout: 120000 }); await p.waitForTimeout(1200);
  await moveTo('#glance', 0.5, 0.3); await p.waitForTimeout(800);
  await scroll(850, 40, 50); await p.waitForTimeout(500);
  await moveTo('#sel_text', 0.3, 0.3);
  // Scene 4: interpretation
  await at(S[4]); await cap(TITLES[4]);
  await p.evaluate(() => scrollTo({ top: 0, behavior: 'smooth' })); await p.waitForTimeout(700);
  await click('a.nav-link:has-text("4. Results")'); await p.waitForTimeout(2500);
  await moveTo('#interp', 0.3, 0.3); await p.waitForTimeout(2500); await scroll(420, 40, 90);
  // Scene 5: graphics
  await at(S[5]); await cap(TITLES[5]);
  await p.evaluate(() => scrollTo({ top: 0, behavior: 'smooth' })); await p.waitForTimeout(700);
  await click('a.nav-link:has-text("Graphics")'); await p.waitForTimeout(1500);
  await pick('plot_type', 'Wright map'); await p.waitForTimeout(2500);
  await moveTo('#plot', 0.5, 0.5); await scroll(200, 15, 60);
  // Scene 6: item cards
  await at(S[6]); await cap(TITLES[6]);
  await p.evaluate(() => scrollTo({ top: 0, behavior: 'smooth' })); await p.waitForTimeout(700);
  await click('a.nav-link:has-text("Item health cards")'); await p.waitForTimeout(2500);
  await pick('card_item', 'Item.12'); await p.waitForTimeout(2500);
  await moveTo('#card', 0.2, 0.2);
  // Scene 7: report
  await at(S[7]); await cap(TITLES[7]);
  await p.evaluate(() => scrollTo({ top: 0, behavior: 'smooth' })); await p.waitForTimeout(700);
  await click('a.nav-link:has-text("7. Report")'); await p.waitForTimeout(2000);
  await moveTo('#dl_report'); await p.waitForTimeout(1800);
  await moveTo('#dl_code'); await p.waitForTimeout(1000);
  await moveTo('pre', 0.3, 0.3); await scroll(300, 15, 60);
  await at(88.5); await cap(''); await show('vend', true);
  await at(S[8]);
  await p.close(); const v = await p.video().path(); await ctx.close(); await b.close();
  fs.writeFileSync('meta.json', JSON.stringify({ video: v, offset: off }));
  console.log(v, off);
})();
