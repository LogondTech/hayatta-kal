# Hayatta Kal — oynanış dengesi optimizasyon planı

**Durum:** ilk aday denge güncellemesi koda uygulandı ve headless regresyonlardan geçti; oyuncu testiyle henüz kalibre edilmedi.
**Kapsam:** zorluk eğrisi, düşman dalga temposu ve arbalet mermilerinin hızı/tepki hissi.
**İlke:** mevcut değerleri varsayımla değiştirmek yerine oynanış telemetrisi ve tekrarlanabilir testlerle karar ver.

## 1. Mevcut davranışın koddan çıkarılan özeti

Aşağıdaki ilk tablo değişiklik öncesi kaynak kodu baseline'ıdır; hesaplamalar gerçek oyuncu performansı veya denge testi sonucu değildir.

- Oyuncu temel atışı her **0,55 s**'de bir, **10 hasar** ile gönderir: teorik tek hedef DPS'i yaklaşık **18,18**.
- Önceki projectile hızı **26 birim/s** ve hedef aralığı **14 birim** idi; tam menzilde teorik uçuş yaklaşık **0,54 s** sürüyordu.
- Temel düşman: 14 HP, 4,6 hız, 10 temas DPS'i. Brute: 75 HP, 2,1 hız, 28 temas DPS'i. Dalga çarpanları iki türe de uygulanır.
- Spawn bütçesi dalga başına `4 + 4×wave + floor(0,3×wave²)` olarak büyüyor ve bir sonraki dalgaya taşınıyor. Her dalga için zamanlayıcı 20 saniyede ilerleyebiliyor; 150 canlı düşman sınırı veya kalan spawn bütçesi yüzünden üretilmeyen düşmanlar birikiyor.
- Düşman HP çarpanı `1 + 0,16×(wave−1) + 0,01×(wave−1)²`; hız çarpanı dalga başına %2,5 artıp en çok +%45'e ulaşıyor; temas hasarı çarpanı dalga başına %7 artıyor. Brute şansı dalga 10'da %40 tavanına ulaşıyor.
- Koddan hesaplanan örnekler:

| Dalga | Yeni dalga bütçesi* | HP çarpanı | Fast HP | Brute HP | Hız çarpanı | Temas hasarı çarpanı | Brute olasılığı |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 8 | 1,00× | 14 | 75 | 1,00× | 1,00× | 0% |
| 5 | 31 | 1,80× | 25 | 135 | 1,10× | 1,28× | 23,5% |
| 10 | 74 | 3,25× | 45,5 | 243,8 | 1,225× | 1,63× | 40% |
| 20 | 204 | 7,65× | 107,1 | 573,8 | 1,45× (tavan) | 2,33× | 40% |
| 30 | 394 | 14,05× | 196,7 | 1.053,8 | 1,45× (tavan) | 3,03× | 40% |

\* Bu, her yeni dalgada eklenen bütçedir; taşınan düşmanlar eklendiğinden gerçek `_to_spawn` daha yüksek olabilir.

İlk risk adayı, HP ve temas hasarının hız artışı tavana ulaştıktan sonra da büyümeye devam etmesi, 20 saniyede dalga değişirken üretilmemiş bütçenin sonraki dalgaya eklenmesi ve spawn bütçesinin kuadratik yükselmesiydi. Bu değerler tek başına “oyun çok zor” kanıtı değildir; yükseltmeler ve oyuncu hareketi sonucu değiştirir.

## 2. Uygulanan ilk denge adayı (insan testi bekliyor)

Kullanıcının geliştirme talimatıyla tek bir temkinli aday seti uygulandı; ayarlar bilinçli biçimde yardımcı fonksiyonlara ayrıldı ki sonraki denemeler ve regresyon testleri okunabilir olsun.

| Parametre | Değişiklik öncesi | Uygulanan aday | Neden / sınır |
|---|---|---|---|
| Dalga spawn bütçesi | `4 + 4w + floor(0,3w²)` | `4 + 4w + floor(0,15w²)` | Kuadratik ek yükün eğimi yarıya indirildi; wave 10: 59 (önce 74), wave 20: 144 (önce 204), wave 30: 259 (önce 394). |
| Spawn süresi | bütçe yaklaşık 13 s'ye sıkıştırılıyordu | 16 s spawn penceresi, 20 s asgari dalga sınırı | Düşman girişine daha çok yayılım/nefes; canlı cap dolduğunda spawn bekler. |
| Dalga geçişi | 20 s'de spawn bütçesi kalsa bile ilerleyip borcu ekliyordu | Kalan bütçe sıfır olmadan dalga ilerlemez | Borç/ani yoğunluk sıçraması engellenir; cap dolarsa sonraki üretim düşman ölünce devam eder. |
| Düşman HP çarpanı | `1 + 0,16w + 0,01w²` | `1 + 0,12w + 0,004w²` | Wave 10: 2,404× (önce 3,25×); wave 20: 4,724× (önce 7,65×); wave 30: 7,844× (önce 14,05×). |
| Temas hasarı çarpanı | `1 + 0,07w` (sınırsız) | `min(1 + 0,05w, 2)` | Artış yumuşatıldı ve 2× tavan eklendi; wave 30 önce 3,03× idi. |
| Düşman hız çarpanı | wave başına +2,5%, +45% tavan | Değişmedi | Hız profilini aynı anda bozmayıp sadece baskı/HP eksenini değiştirmek için. |
| Projectile hızı | 26 birim/s | 30 birim/s | Yaklaşık %15,4 artış; tam 14 birim uçuş teoride 0,54 s'den 0,47 s'ye iner. Hasar ve ateş aralığı değişmedi. |

Bu adaylar insan testi yapılmadan “son denge” kabul edilmemeli. Sabit-seed autopilot stres koşusu teknik regresyon ve spawn kapasitesini test edebilir, ancak oyuncu eğlencesini/hayatta kalma hedefini kanıtlamaz. 30 birim/s hızın okunabilirliği ve geç dalga HP eğrisi özellikle gerçek oyuncuyla gözlenmeli.

## 3. Planın hedefleri ve korunacaklar

1. İlk dakikalarda öğrenme ve hareket alanı; orta oyunda baskının kademeli yükselmesi; geç oyunda yoğunluk artarken düşmanın yalnızca mermi süngeri hâline gelmemesi.
2. Dalga numarası ile gerçek tehlike aynı yönde ve okunabilir biçimde ilerlemeli; taşınan spawn borcu veya bir anda artan brute oranı görünmez sıçrama yaratmamalı.
3. Mermi hızı oyuncunun hareket/kaçış ve hedef mesafesine uygun olmalı; atışın otomatik olması hedef seçimini ve isabet hissini anlamsızlaştırmamalı.
4. XP, yükseltme sıklığı ve mevcut kayıt biçimi korunmalı; `MAX_ALIVE` güvenlik tavanı kaldırılmamalı.
5. Denge kararı insan oynanışıyla doğrulanmalı. Autopilot yalnızca tekrarlanabilir teknik stres/uzun koşu karşılaştırmasıdır; eğlence veya gerçek oyuncu becerisinin vekili değildir.

## 4. Aşamalı deney planı

### A — Ölçüm hattını sabitle

- Denge testinde sabit seed ve sabit yapılandırma kaydet; seed, Godot sürümü, fizik tick hızı, renderer, upgrade seçimleri ve koşu süresini sonuçla birlikte sakla.
- Test etapları: dalga 1–3 (öğrenme), 4–10 (orta baskı), 11–20 (ölçeklenme), 21+ (sınırsız modun sürdürülebilirliği).
- Her koşuda en az şu telemetriyi tut: dalga başlama zamanı, dalga başına spawn bütçesi ve taşan bütçe, canlı düşman p95/tepe değeri, düşman tür dağılımı, oyuncunun aldığı temas hasarı, öldürme/atış oranı, isabet/kaçırma oranı, XP/dakika, seviye ve upgrade dağılımı, ölüm zamanı ve ölüm nedeni.
- İnsan testi için her etapta yeni başlayan/ortalama/deneyimli oyuncu segmentleriyle birden fazla koşu yap; her değişiklik için aynı protokolü önce/sonra uygula. Örneklem boyutu ve hedef hayatta kalma süreleri oyun sahibince belirlenmeden sayıları başarı kriteri diye sabitleme.
- Yalnızca karşılaştırma amacıyla autopilot ile seed sabitli stres koşuları çalıştır; bunları insan sonuçlarından ayrı raporla.

### B — Zorluk eğrisini düzeltme adayı olarak test et

Uygulanmış aday setini baseline adayı olarak kaydet. İnsan testi sonuçlarına göre önce tek değişkenli varyantları karşılaştır; daha veri gelmeden ikinci denge revizyonu dayatma:

1. **Spawn borcu ve dalga sınırı:** her 20 saniyede yeni dalga açılırken önceki `_to_spawn` bütçesinin taşınmasının görünür yoğunluğa etkisini ölç. Dalga bütçesi, canlı düşman sınırı ve dalga süresi arasında bir uyum hedefi seç. Borç birikiyorsa seçenekleri (a) borçla dalga geçişi, (b) sabit/artan spawn tavanı, (c) canlı sayıya göre dinamik aralık olarak ayrı test et; oyuncuya haber vermeden spawn'ı kaybetme.
2. **HP eğrisi:** wave 1–30 için mevcut fast/brute HP ile oyuncunun atış başına öldürme süresi ve öldürme oranını çiz. HP'nin kuadratik artışı özellikle hız artışı 19. dalgada tavan yaptıktan sonra ayrı varyantlarla sınansın. Sabit HP yerine sınırlı/azalan marjinal artış ancak ölçüm mermi süngeri sorunu gösterirse denenmeli.
3. **Temas hasarı:** brute/fast türü, wave ve yakın mesafe kalış süresine göre beklenen can kaybını çıkar. Temas hasarı %7/wave ölçeği, oyuncu upgrade ve hareket hızından bağımsız olarak baskıyı katlıyor olabilir; hasar artışını HP/spawn değişikliklerinden ayrı A/B test et.
4. **Brute kompozisyonu:** dalga 2'den itibaren brute payı artıyor, wave 10'da %40 tavan yapıyor. Ortalama dalga brute sayısı ve brute kaynaklı ölüm oranını ölç; oran eğrisini, brute HP'sini ve spawn zamanını aynı deneyde değiştirme.
5. **Upgrade ekonomisi:** seçimlerin gerçek dağılımını ve seviye atlama/dakika değerini kaydet. Hasar, atış hızı ve multishot alımlarının efektif DPS'e bileşik etkisini ölçmeden enemy HP eğrisini tek başına dengeleme.

Her varyant baseline'a göre dalga başına medyan/p10 hayatta kalma, temas hasarı/dakika, kills/dakika, XP/dakika ve upgrade dağılımı ile raporlansın. Hedef aralıkları, sahibiyle/oyuncu testleriyle belirlenmeli; bu planda uydurma hedef oranı yoktur.

### C — Projectile hızı ve isabet hissi

- Mevcut aday 30 birim/s değerini kaydet; önceki commit'teki 26 birim/s ile A/B karşılaştır. Kodda hız, menzil ve atış aralığı ayrı parametreler olarak test edilsin; önce sadece projectile hızı değişsin.
- Önerilen deney kademeleri: **18, 22, 26, 30, 34 birim/s**. Bunlar test noktalarıdır, 30 birim/s henüz nihai/oyuncu onaylı değer değildir.
- Aynı seed, hedef türü, düşman hızı/mesafesi ve oyuncu upgrade durumu ile projectile travel time, atış başına isabet, öldürme süresi, mermi hedefi geçmeden düşmanın hareket edip etmediği ve ekrandaki okunabilirlik ölçülsün.
- 26 birim/s baseline'da 14 birim menzil teorik olarak 0,54 s; 30 birim/s adayında 0,47 s. Gerçek menzil testi, düşmanların da oyuncuya yaklaşmasını ve atışın hedef konumuna yönelmesini hesaba katmalı.
- Yalnız hız artırımı isabet/öldürme süresini iyileştiriyor fakat vuruş hissini bozuyorsa görsel iz/etki/kontrast ayrı bir sanat testi olsun; fiziksel hızı ve görsel geri bildirimi aynı anda değiştirme.
- Oyuncu ateş aralığı 0,55 s ve yükseltme başına /1,2 olduğundan, atış hızı yükseltmeleri ile mermi hızını bir arada optimize etme; önce tek değişkenli ölçüm, ardından küçük faktöriyel kombinasyon testi.

### D — Kabul, geri alma ve sürümleme

Bir denge ayarı ancak aşağıdakilerden sonra kabul edilsin:

- Önceden seçilmiş hedef oyuncu segmentinde hayatta kalma/ilerleme dağılımı istenen yöne değişmiş olmalı; sadece autopilot sonucu yeterli değil.
- Başlangıç dalgaları yeni oyuncu için haksız ani ölüm üretmemeli; geç dalga baskısı artarken öldürme süresi ve isabet okunabilir kalmalı.
- XP/upgrade temposu ve kayıt akışı regress olmamalı.
- Eski ve yeni değerler, sabit seed ve test protokolü ile aynı raporda bulunmalı; sonuç tekrar koşulabilmeli.
- Her aday değişiklik ayrı commit/feature flag ile tutulmalı, rollback mümkün olmalı. Bu plan onaylanmadan gameplay değerleri değiştirilmemeli.

## 5. Rapor şablonu

Her koşu için: `build/commit`, Godot sürümü, seed, dalga, upgrade listesi, oyuncu segmenti, koşu süresi, ölüm nedeni, canlı düşman p95/tepe, spawn backlog, fast/brute oranı, hasar/dakika, XP/dakika, kills/dakika, atış/isabet oranı, mermi travel time ve notlar.

## 6. Açık kararlar

- Hedef ortalama koşu süresi veya “normal” hedef dalga belirtilmedi; ürün hedefi varsayılmamalı.
- Hangi oyuncu/cihaz gruplarının temsil edileceği ve test katılımcısı sayısı belirlenmeli.
- Mevcut `tests/regression_smoke.tscn` ve sentetik CPU benchmark'ı oyun denge ölçümü değildir; gerçek input/oyuncu telemetrisi eklenmeden denge eğrisi başarıyla kalibre edilmiş sayılamaz.
- Kodda aday değişiklikler var; gerçek oyuncu/cihaz profili ve insan oynanışı kalibrasyonu hâlâ beklemede.
