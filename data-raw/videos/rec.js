const { chromium } = require('playwright'); const fs=require('fs');
const name = process.argv[2], total = +process.argv[3];
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport:{width:1280,height:720}, recordVideo:{dir:'raw-'+name,size:{width:1280,height:720}} });
  const t0=Date.now(); const p = await ctx.newPage();
  await p.goto('file://'+process.cwd()+'/'+name+'.html'); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(1500);
  const off=(Date.now()-t0)/1000; await p.evaluate(()=>start());
  if (process.argv[4]) { for (const s of process.argv[4].split(',')) { await p.waitForTimeout(+s*1000 - (Date.now()-t0-off*1000)); await p.screenshot({path:`${name}-${s}.png`}); } }
  await p.waitForTimeout(total*1000-(Date.now()-t0-off*1000));
  await p.close(); const v=await p.video().path(); await ctx.close(); await b.close();
  fs.writeFileSync(name+'.meta.json', JSON.stringify({video:v, offset:off})); console.log(v, off);
})();
