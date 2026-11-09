# Hayatta Kal — revizyon kapsamı ve karar kaydı

Tarih: 2026-11-09

## Önceki durum

Godot 4.7 projesi; oyuncu hareketi, otomatik ateş, düşman dalgaları, XP mücevherleri, yükseltme kartları, ara sahne ve ses akışlarından oluşuyor. Depoda proje başlangıç talimatı, görev listesi veya önceki revizyon kaydı yok. İlk Godot 4.7.2 headless editor/import çalışması exit code 0 ile bitti.

## Araştırma dayanağı

Godot 4.7 resmi genel optimizasyon belgesi, önce profiler/timing ile darboğaz belirleyip her değişiklikten sonra yeniden ölçmeyi; iyileştirmeyi en yavaş yoldan başlatmayı öneriyor: https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html (erişim: 2026-11-09; resmi motor dokümantasyonu). Godot 4.7'nin 3D optimizasyon belgesi şeffaf materyalleri, animasyon/skinning maliyetini ve tekrarlanan geometriyi ayrı ayrı ele alıyor; otomatik instancing'in yalnız Forward+ renderer için geçerli olduğunu ve MultiMesh seçeneğini belirtiyor: https://docs.godotengine.org/en/4.7/tutorials/performance/optimizing_3d_performance.html (erişim: 2026-11-09; resmi motor dokümantasyonu).

İlk kaynak denetiminde oyuncu/autopilot hedef taramaları ile projectile başına tam düşman grubu taraması görüldü. Broadphase değişikliğine karar vermeden önce 150 düşman / 2.500 sorgulu, aynı isabet koşullu Godot mikrobenchmark uygulandı. Mermi çarpışması physics query yoluna taşındı; autopilot dahil GDScript taramaları 0.1 saniyede bir yenileniyor.

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

`scripts/player.gd` oyuncu hedef seçimi ve mücevher pickup taramasını 0.1 saniyelik aralığa alıyor. Hedef geçersiz/ölmekteyse ateşleme ve nişan için kullanılmıyor; debug autopilot'un steer ve closest-gem hesaplamaları da 10 Hz'e düşürüldü. `scripts/projectile.gd` tüm düşman grubunu her fizik adımında taramak yerine 3D sphere broadphase sorgusuyla yakın düşman collider'larını alıyor ve mevcut XZ mesafe testi, hasar, hız ve yaşam süresini koruyor. `scripts/character_visual.gd` parlama callback'lerini sıra numarasıyla koruyor; önceki parlama zamanlayıcısı en son hasarın görselini kapatamıyor. `scripts/wave_director.gd` düşman kümelerini kalan kapasiteye göre sınırlandırıyor.

README'deki eski yaratıcı ve yayıncı atıfları kaldırıldı; depo yolu, indirme bağlantısı ve kod/varlık lisansı ayrımı güncellendi. Animasyonlu 144 karelik `docs/gameplay.webp` dosyasına dokunulmadı; yeni `docs/.gdignore`, Godot'un bu README görselini statik doku gibi import etmeye çalışmasını durdurdu. `tests/regression_smoke.tscn` kayıtlı rekoru, yeni ama henüz kaydedilmemiş rekor adayını, kapasite sınırını, çakışan parlama zamanlayıcılarını, hızlı/ağır düşman projectile isabetlerini ve ana sahne/dalga açılışını test edip 900 fizik karesi çalıştırıyor. `tests/performance_probe.gd` eski GDScript taramasıyla broadphase CPU maliyetini karşılaştırıyor.

Godot 4.7.2.stable.official doğrulaması: `godot --headless --editor --path . --quit` başarılı, WebP/import veya script hatası yok. Güncel `tests/regression_smoke.tscn`, iki projectile tipini test ettikten sonra dalga yöneticisiyle ana sahneyi 900 fizik karesi boyunca çalıştırdı; düşman tavanı ve temiz ses kapatımıyla `PASS: regression smoke tests` verdi. Beş profiler probe koşusunun medyanında 150 düşman başına eski grup taraması 84.782 µs/sorgu; physics broadphase + kesin test 2.086 µs/sorgu; her ikisi de 609 hit verdi (sentetik yükte 40.6× CPU microbenchmark oranı). İkinci read-only audit HUD'da henüz kaydedilmemiş rekor koşusunun "En iyi" diye etiketlenmesini saptadı; save davranışını değiştirmeden etiket "Rekor adayı" olarak ayrıldı ve kayıtlı rekor / yeni aday / eşitlik regresyon testine alındı. `git diff --check` başarılı.

**Sınır:** Bu sandbox, hedef oyuncu cihazı/GPU'su değildir. Sentetik CPU mikrobenchmark gerçek frame time veya FPS yerine geçmez. 3D skinning, gölge, bellek ve uzun koşu CPU/GPU davranışı gerçek cihazda ayrıca ölçülmelidir; dışa aktarma, fiziksel cihaz ve insan oynanış testleri bu ortamda yapılamadı.
