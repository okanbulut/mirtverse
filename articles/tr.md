# mirtverse: Türkçe tanıtım

**Madde tepkilerinden savunulabilir kararlara; R kodu yazarak ya da
yazmadan.**

**mirtverse**, R. Philip Chalmers’ın geliştirdiği
[mirt](https://philchalmers.github.io/mirt/) paketi için kullanıcı dostu
bir iş akışı ve raporlama katmanıdır. mirt, madde tepki kuramı (MTK)
modellerini kestirir; mirtverse ise model seçmenize, sonuçları
anlamanıza, yayına hazır grafikler üretmenize ve sonuçları R kullanmayan
kişilerle paylaşmanıza yardım eder.

[Türkçe özet kılavuzu indirin
(PDF)](https://www.okanbulut.com/mirtverse/cheatsheet/mirtverse-cheatsheet-tr.pdf)
[Canlı örnek gösterge panelini
açın](https://www.okanbulut.com/mirtverse/dashboard/sat12-demo.md)

![mirtverse iş akışı dört adımda: Veriyi getirin, modeli kestirip seçin,
sonuçları anlayın, paylaşın ve karar
verin](../reference/figures/home-workflow.svg)

Sitenin geri kalanı, kitap ve laboratuvarlar şimdilik İngilizcedir. Bu
sayfa, Türkçe konuşan kullanıcılar için bir başlangıç noktasıdır.

## Kurulum

mirtverse, R-universe üzerinden derlenmiş paket olarak kurulur:

``` r

install.packages("mirtverse",
  repos = c("https://okanbulut.r-universe.dev", "https://cloud.r-project.org"))

library(mirtverse)   # mirt paketi de yüklenir
```

## İlk analiz

Aşağıdaki kod, mirt ile gelen LSAT7 verisiyle tam bir analiz yapar.
Kendi verinizle çalışmak için `data` satırını değiştirmeniz yeterlidir;
verinin her sütunu bir madde, her satırı bir birey olmalıdır.

``` r

data <- expand.table(LSAT7)

sel <- select_model(data)   # Rasch, 2PL ve 3PL'yi karşılaştırır ve birini önerir
mod <- sel$best             # sıradan bir mirt modeli

interpret(mod)              # sonuçların anlamı, sade bir dille (İngilizce)
item_table(mod)             # madde istatistikleri, uyum ve uyarılar tek tabloda
gg_wright(mod)              # birey-madde haritası (Wright haritası)
item_card(mod, "Item.2")    # tek sayfalık madde durum kartı

mv_report(sel, file = "rapor.html")              # her şey tek bir HTML dosyasında
mv_dashboard(mod, title = "LSAT sonuçları")      # paylaşılabilir etkileşimli panel
```

Kod yazmak yerine tıklamayı mı tercih edersiniz?
[`launch_workbench()`](https://www.okanbulut.com/mirtverse/reference/launch_workbench.md)
komutu, her adımın R kodunu sizin için yazan tıkla-çalıştır bir uygulama
açar.

## Hangi MTK modeli?

Model seçimi, bir MTK analizindeki ilk gerçek karardır. Maddelerin nasıl
puanlandığından (1-0, sıralı kategoriler, sırasız seçenekler) yola çıkan
[tek sayfalık akış
şeması](https://www.okanbulut.com/mirtverse/articles/which-model.md)
(İngilizce), sizi bir modele ve onu kestiren R koduna götürür. Emin
değilseniz `select_model(data)` aday modelleri sizin için karşılaştırır.

## Kimin için?

| Ben… | Buradan başlayın (İngilizce) |
|----|----|
| MTK öğrenen ya da tez verisini çözümleyen bir öğrenciyim | [Öğrenciler](https://www.okanbulut.com/mirtverse/articles/for-students.md) · [Tez kiti](https://www.okanbulut.com/mirtverse/articles/thesis-kit.md) |
| Ölçme ve değerlendirme dersi veriyorum (kitap, on laboratuvar, örnek ders izlencesi) | [Öğretim elemanları](https://www.okanbulut.com/mirtverse/articles/for-instructors.md) · [Dersinizde kullanın](https://www.okanbulut.com/mirtverse/articles/adopt.md) |
| Bir sınav ya da sertifika programında çalışan bir psikometristim | [Sınav programları](https://www.okanbulut.com/mirtverse/articles/for-practitioners.md) · [Örnek olay](https://www.okanbulut.com/mirtverse/articles/case-study.md) |
| mirt, ltm, eRm, TAM veya irtQ kullanan bir araştırmacıyım | [Araştırmacılar](https://www.okanbulut.com/mirtverse/articles/for-researchers.md) · [mirt’e geçiş](https://www.okanbulut.com/mirtverse/articles/mirtify.md) |
| R’ye yeniyim ya da Winsteps, SPSS veya Excel’den geliyorum | [R’ye yeni olanlar](https://www.okanbulut.com/mirtverse/articles/for-new-to-r.md) |
| Ölçmede yapay zekâ ile ilgileniyorum | [Yapay zekâ merkezi](https://www.okanbulut.com/mirtverse/articles/ai-hub.md) |

## Alışılmış MTK araçlarının ötesinde

- **Analizi anlatın, betiği alın.**
  [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md),
  tek cümlelik bir istekten test edilmiş bir R betiği yazar. Claude, bir
  OpenAI modeli, yerel bir model ya da çevrim dışı bir ayrıştırıcıyla
  çalışır. [Nasıl
  çalışır](https://www.okanbulut.com/mirtverse/articles/mv-ask-guide.md)
- **Analizi Claude yapsın.** Claude Code için mirtverse eklentisi,
  Claude’u modelleri kestiren, maddeleri ve DMF’yi kontrol eden,
  bireyleri puanlayan ve sonunda bir rapor ile bir R betiği bırakan bir
  psikometriste dönüştürür. [mirtverse
  ajanı](https://www.okanbulut.com/mirtverse/articles/mirtverse-agent.md)
- **Madde üretin.**
  [`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md),
  bir belirtke tablosundan anahtarlı çoktan seçmeli maddeler ve rubrikli
  açık uçlu maddeler taslağı hazırlar;
  [`generate_isomorphs()`](https://www.okanbulut.com/mirtverse/reference/generate_isomorphs.md)
  bir madde modelinden madde aileleri üretir.
- **Açık uçlu cevapları puanlayın.**
  [`train_scorer()`](https://www.okanbulut.com/mirtverse/reference/train_scorer.md)
  çevrim dışı çalışan, şeffaf bir puanlama motoru eğitir;
  [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md)
  her puan kullanılmadan önce insan puanlayıcılarla uyumu kontrol eder.
- **Bütün bir sınav programını yürütün.**
  [`mv_pipeline()`](https://www.okanbulut.com/mirtverse/reference/mv_pipeline.md),
  bir testi belirtke tablosundan madde bankası izlemeye kadar 13 aşamada
  taşır. [Ölçme
  süreci](https://www.okanbulut.com/mirtverse/articles/assessment-pipeline.md)

## Kısa videolar

Üç kısa tanıtım videosu (her biri yaklaşık 90 saniye, İngilizce
altyazılı): [Workbench turu](https://youtu.be/huSxZzaFNs0) · [Yapay zekâ
merkezi](https://youtu.be/4cFjnpSkcMQ) · [Tez
kiti](https://youtu.be/J3us00sk34g).

## mirt hakkında

R. Philip Chalmers tarafından geliştirilen ve sürdürülen
[mirt](https://philchalmers.github.io/mirt/), madde tepki kuramı için en
kapsamlı açık kaynak paketlerden biridir. 30’dan fazla madde türüyle tek
ve çok boyutlu modelleri, çok gruplu ve karma etkili modelleri, örtük
sınıf ve bilişsel tanı modellerini kestirir.

**mirtverse, mirt’e dayanır ve modellerin kestirilme biçimini asla
değiştirmez.** Her fonksiyon
[`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html)
ile oluşturulmuş bir modeli kabul eder; iki paket arasında istediğiniz
an geçiş yapabilirsiniz.

## Atıf

Lütfen mirtverse’e mirt ile birlikte atıf yapın. R’de
`citation("mirtverse")` komutunu çalıştırın ya da [İngilizce ana
sayfadaki](https://www.okanbulut.com/mirtverse/index.html#citation) atıf
bilgilerini kullanın.
