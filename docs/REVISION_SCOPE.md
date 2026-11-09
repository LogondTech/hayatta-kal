# Hayatta Kal — revizyon kapsamı ve karar kaydı

Tarih: 2026-11-09

## Önceki durum

Godot 4.7 projesi; oyuncu hareketi, otomatik ateş, düşman dalgaları, XP mücevherleri, yükseltme kartları, ara sahne ve ses akışlarından oluşuyor. Depoda proje başlangıç talimatı, görev listesi veya önceki revizyon kaydı yok. İlk Godot 4.7.2 headless editor/import çalışması exit code 0 ile bitti.

## Araştırma dayanağı

Godot 4.7 resmi genel optimizasyon belgesi, önce profiler/timing ile darboğaz belirleyip her değişiklikten sonra yeniden ölçmeyi; iyileştirmeyi en yavaş yoldan başlatmayı öneriyor: https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html (erişim: 2026-11-09; resmi motor dokümantasyonu). Godot 4.7'nin 3D optimizasyon belgesi şeffaf materyalleri, animasyon/skinning maliyetini ve tekrarlanan geometriyi ayrı ayrı ele alıyor; otomatik instancing'in yalnız Forward+ renderer için geçerli olduğunu ve MultiMesh seçeneğini belirtiyor: https://docs.godotengine.org/en/4.7/tutorials/performance/optimizing_3d_performance.html (erişim: 2026-11-09; resmi motor dokümantasyonu).

Kaynakları okuma/inceleme bulguları: oyuncu ve autopilot düşman/mücevher gruplarını her fizik karesinde tarıyor; her mermi de düşman grubunu baştan tarıyor. Düşmanlar per-frame hareket ve animasyon güncelliyor; dalga yöneticisi 150 canlı düşmana izin veriyor. Bunlar ölçülmesi ve/veya algoritmik olarak sınırlandırılması gereken güçlü ölçeklenme adaylarıdır; henüz runtime profiler ölçümü değildir.

## Yetki, koruma ve sınırlar

Kullanıcı depo, karakterler ve proje üzerinde yetkisi olduğunu teyit etti; README atıflarını kendisiyle uyumlu güncelleme talimatı verdi. Oyun kimliği, karakter/modeller, ses/video ve mevcut kayıt biçimi korunacak. Varlık dosyaları silinmeyecek veya yeniden üretilmeyecek. Tasarım/oynanış yeniden tasarımı, ücretli servis, dağıtım/yayınlama veya mağaza/release işlemi bu aşamanın kapsamında değil. Kullanıcının sahiplik beyanı doğrulanmış dış kanıt olarak değil, çalışma yetkisi olarak kayda alınmıştır.

## Bu aşamanın kapsamı

Kodun tamamını incele; kanıtlı çalışma zamanı hatalarını ve yüksek maliyetli ölçeklenme sorunlarını dar ve anlaşılır değişikliklerle düzelt. README’deki yazar, kanal, release ve varlık atıflarını kullanıcıyla uyumlu hale getir; gerçek kullanıcı adına dair bilgi verilmediği için isim/URL uydurma, nötr ve doğrulanabilir proje sahipliği dili kullan. Çalıştırma/dağıtım talimatlarını koru. Yeniden üretilebilir headless import/runtime kontrolleri ekle veya mevcut olanı kullan. Her sonuç için kaynak kontrolü ve mümkünse Godot headless çalıştırması yap.

## Kabul ölçütleri ve sınırlar

1. Godot 4.7.x ile proje headless import/parse aşamasından hatasız geçmeli.
2. Oyun ana sahnesi headless çalıştırmada başlangıçta script/resource hatası vermemeli.
3. İyileştirmeler var olan saldırı, düşman, XP, yükseltme ve kayıt akışını bozmamalı.
4. Temel doğrusal tarama maliyetleri mümkünse paylaşılan/verimli aday seçimi veya uzamsal sorguyla azaltılmalı; gereksiz mimari yeniden yazım yapılmamalı.
5. README, eski yapımcı/yayıncı ve üçüncü taraf varlık atıflarını kullanıcıyla uyumlu, uydurma bilgi içermeyen dille değiştirmeli; MIT kod lisansı ile varlıkların farklı koşullarda olabileceği ayrımını kaynağa dayalı olarak korumalı.
6. Değişiklikler gerçek kod diff'i, Godot doğrulama çıktısı ve kısıtlarıyla teslim edilmeli. Donanım üzerinde FPS garantisi verilmemeli.

## Yapılanlar ve doğrulama

`scripts/player.gd` oyuncu hedef seçimi ve mücevher pickup taramasını 0.1 saniyelik yenileme aralığına aldı. Hedef geçersiz/ölmekteyse ateşleme ve nişan için kullanılmıyor. Standart 60 Hz fizik güncellemesi varsayımında bu iki tarama yolunun sıklığı yaklaşık 60/s'den 10/s'ye düşer; bu çağrı sıklığı hesabıdır, FPS ölçümü değildir. `scripts/character_visual.gd` parlama callback'lerini sıra numarasıyla koruyor; önceki parlama zamanlayıcısı en son hasarın görselini kapatamıyor. `scripts/wave_director.gd` düşman kümelerini kalan kapasiteye göre sınırlandırıyor ve 150 canlı düşman tavanı için saf doğrulanabilir yardımcı kullanıyor.

README'deki eski yaratıcı ve yayıncı atıfları kaldırıldı; depo yolu, indirme bağlantısı ve kod/varlık lisansı ayrımı güncellendi. Animasyonlu 144 karelik `docs/gameplay.webp` dosyasına dokunulmadı; yeni `docs/.gdignore`, Godot'un bu README görselini statik doku gibi import etmeye çalışmasını durdurdu. `tests/regression_smoke.tscn` kaydedilmiş/yeni en iyi süre davranışını, kapasite sınırını, çakışan parlama zamanlayıcılarını ve ana sahne/dalga açılışını test ediyor.

Godot 4.7.2.stable.official doğrulaması: `godot --headless --editor --path . --quit` başarılı, WebP/import veya script hatası yok. `godot --headless --path . res://tests/regression_smoke.tscn` başarılı ve temiz kapanıyor (`PASS: regression smoke tests`). Regresyon sahnesi, ana sahneyi başlatıp düşman dalgası başlangıcını da doğruluyor. `git diff --check` başarılı. README görselinin geçerli animasyonlu WebP olduğu Pillow ile kontrol edildi. HUD için ilk denetim raporundaki hata iddiası test ve kaynak semantiğiyle yanlış bulundu; `maxf(best, t)` korunup iki durum test edildi.

**Açık kalan:** Profiler ile gerçek CPU/GPU süresi, FPS, bellek ve uzun koşudaki düşman yoğunluğu ölçümü kullanıcı hedef donanımında yapılmadı. Bu nedenle mermi taraması, 3D skinning, gölge ve 150 düşman sınırının cihaz başına maliyeti hakkında performans garantisi yok. Windows/Linux export, fiziksel cihaz, insan oynanış ve yayın testleri de yapılmadı.
