{ title: "AI Hub demo", edMax: 6, total: 92, txt: __TXT__, timeline: [
 [0, () => slide(`<div style="display:flex;flex-direction:column;align-items:center;gap:6px">
   <div style="background:#fff;border-radius:14px;padding:10px 18px;box-shadow:0 10px 40px #0004"><img src="home-ai.svg" style="width:760px;display:block"></div>
   <div style="font:700 50px Inter;margin-top:26px">The mirtverse AI Hub</div>
   <div style="font:400 23px Inter;opacity:.85">AI for psychometricians, with a psychometric check behind every feature</div></div>`)],
 [12, () => slide(`<div style="width:1060px">
   <div style="font:700 36px Inter;margin-bottom:18px">A learning path from jobs you already do</div>
   ${[["Vocabulary","Machine learning words in measurement terms"],["ML through an IRT lens","Prediction models vs. measurement models"],["LLMs in your workflow","Scripts from plain language, replay mode"],["Automated scoring","train_scorer(), agreement_report() · Lab 7"],["Item text and difficulty","item_features(), predict_difficulty() · Lab 8"],["Automatic item generation","item_model(), generate_isomorphs() · Lab 9"],["Validity and fairness","ai_audit(), validity_argument() · Lab 10"]].map((r,i)=>
     `<div style="display:flex;align-items:center;gap:16px;margin:9px 0;opacity:0;animation:fi .5s ${0.3+i*0.35}s forwards"><span style="width:38px;height:38px;border-radius:50%;background:#e6781e;display:inline-flex;align-items:center;justify-content:center;font:700 18px Inter">${i+1}</span><span style="font:600 22px Inter;width:340px">${r[0]}</span><span style="font:400 19px Inter;opacity:.8">${r[1]}</span></div>`).join('')}
   <div style="margin-top:22px;font:500 19px Inter;opacity:0;animation:fi .5s 3.2s forwards;color:#ffd7b0">6 book chapters · 4 hands-on labs · replay mode: No API key needed</div>
   <style>@keyframes fi{to{opacity:1}}</style></div>`)],
 [23.3, () => slide(null)],
 [24, () => cap("Automated scoring")],
 [24.6, () => type(["library(mirtverse)", "e1 <- essays[essays$prompt == \"E1\", ]   # 400 essays, two human raters", "s <- train_scorer(e1)", "s"])],
 [31.5, () => run(["s <- train_scorer(e1)", "s"], "ai-scorer")],
 [34, () => mark("QWK = 0.89")],
 [42, () => cap("Check it like a psychometrician")],
 [42.5, () => type(["a <- agreement_report(s$cv$machine, e1$human1, e1$human2, group = e1$group)", "a"])],
 [47.4, () => run(["a <- agreement_report(s$cv$machine, e1$human1, e1$human2, group = e1$group)", "a"], "ai-agree")],
 [49.5, () => mark("meets")],
 [51.5, () => mark("machine too low")],
 [54, () => view("ai-agree.png", "Plots · autoplot(a)", 820)],
 [60, () => { view(null); cap("Item text and difficulty"); }],
 [60.6, () => type(["feats <- item_features(itemtext)", "head(feats[order(-feats$similarity), c(\"id\", \"similarity\", \"nearest\")], 4)"], 40)],
 [64.2, () => run(["feats <- item_features(itemtext)", "head(feats[order(-feats$similarity), c(\"id\", \"similarity\", \"nearest\")], 4)"], "ai-feats", true)],
 [65.2, () => mark("N01-14")],
 [66.5, () => type(["m <- predict_difficulty(merge(itemtext, feats), c(\"family\", \"sentences\", \"decimals\", \"max_digits\"), se = \"b_se\")", "m"], 55)],
 [69.6, () => run(["m <- predict_difficulty(merge(itemtext, feats), c(\"family\", \"sentences\", \"decimals\", \"max_digits\"), se = \"b_se\")", "m"], "ai-diff")],
 [71, () => mark("No model can predict b more closely than that.")],
 [72.6, () => view("ai-diff.png", "Plots · autoplot(m)", 860)],
 [76, () => { cap(""); slide(`<div style="text-align:center"><div style="font:700 44px Inter;line-height:1.25">Every AI feature in mirtverse<br>sits behind a psychometric check.</div>
   <div style="font:500 24px Inter;margin-top:30px;opacity:.9">Start with the AI Hub</div><div style="font:600 26px Inter;margin-top:8px;color:#ffd7b0">okanbulut.com/mirtverse</div></div>`); }],
]}
