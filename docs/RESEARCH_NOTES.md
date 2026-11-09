# Teknik araştırma notları

Erişim tarihi: 2026-11-09. Proje `project.godot` içinde Godot 4.7 hedefliyor; doğrulama ortamı Godot 4.7.2.stable.official.

- [Godot 4.7 General optimization tips](https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html), resmi motor dokümantasyonu. Tavsiye: optimize etmeden önce Profiler/timing ile darboğazı belirle, en pahalı fonksiyonla başla, her optimizasyondan sonra yeniden ölç. Bu nedenle projectile grup taraması mikrobenchmark edildi, fizik broadphase yolu seçildi; oyuncu hedef, mücevher ve autopilot taramaları 0.1 saniyeye sabitlendi.
- [Godot 4.7 The Profiler](https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/the_profiler.html), resmi motor dokümantasyonu. Çerçeve, fizik ve boşta kalma sürelerini ayrı ölçmeyi; frame time'ın render maliyetini de içerdiğini açıklar. Aşağıdaki ölçüm CPU-only sentetik mikrobenchmark'tır; hedef cihazda GPU/render veya gerçek oyun FPS ölçümü değildir.
- [Godot 4.7 Optimizing 3D performance](https://docs.godotengine.org/en/4.7/tutorials/performance/optimizing_3d_performance.html), resmi motor dokümantasyonu. Şeffaf nesneler, animasyon/skinning ve tekrarlanan geometri için öneriler içerir. Projedeki karakterlerde hangi maliyetin baskın olduğunu kanıtlayan GPU/CPU ölçümü olmadığından model/renderer ayarları değiştirilmedi.

## Depo inceleme bulguları

Oyuncunun hedef ve mücevher seçimi ile debug autopilot steer hesabı 0.1 saniyelik aralığa alındı. Mermi hit-test'i her projectile için tüm `enemies` grubunu GDScript'te taramak yerine aynı sphere shape ile collision layer 8'in broadphase adaylarını sorguluyor ve eski XZ mesafe testini uyguluyor. Projectile hızı, hasarı, yaşam süresi ve hedefleme davranışı korunuyor. Mermi vuruşu hızlı ve ağır düşmanlara karşı gerçek test sahnesinde doğrulandı.

## CPU mikrobenchmark

`tests/performance_probe.gd`; 150 sentetik StaticBody düşmanı, aynı 2.500 belirli pozisyon ve aynı XZ isabet koşuluyla eski `get_nodes_in_group()` + doğrusal GDScript taramasını yeni `PhysicsDirectSpaceState3D.intersect_shape()` broadphase + kesin mesafe testiyle karşılaştırır. Godot 4.7.2.stable.official headless cloud sandbox'ta beş çalıştırma yapıldı. Medyan: eski yol 84.782 µs/sorgu, broadphase yolu 2.086 µs/sorgu; bu mikrobenchmark'ta yaklaşık **40.6× daha düşük CPU süresi**. Her iki yolda da 2.500 sorgu toplamında 609 isabet bulundu. Bu sonuç yalnızca test edilen host ve sentetik CPU iş yüküne aittir; frame-time/FPS/GPU kazanımı veya hedef cihaz garantisi değildir. Yeniden çalıştırma: `godot --headless --path . --script res://tests/performance_probe.gd`.

Her düşmanın kendi `CharacterBody3D` fizik ve model animasyonunu çalıştırması, şeffaf materyaller/gölgeler ve uzun koşudaki gerçek entity yoğunluğu profiling ile ayrıca incelenebilir; bunlar için bu mikrobenchmark'tan çıkarım yapılamaz.

İlk bağımsız denetim, HUD'ın `maxf(best, t)` ifadesini yanlış yorumlayıp rekor göstergesinin hatalı olduğunu bildirdi. GDScript `maxf` iki değerin büyüğünü döndürdüğü için bu bulgu kaynak koduyla çelişiyordu. Kod bu nedenle korunuyor; test hem kayıtlı rekoru hem de geçilen yeni rekoru doğruluyor.

## Görsel import bulgusu

`docs/gameplay.webp` geçerli 640×360 animasyonlu WebP'dir (144 kare). Godot 4.7.2'nin import aşaması bu README görselini statik doku olarak çözemedi. Görsel, oyun runtime'ında kullanılmıyor. İçeriğe dokunmadan `docs/.gdignore` eklenerek dokümantasyon görselinin oyun varlığı olarak import edilmesi engellendi; sonraki headless import'ta WebP hatası tekrarlanmadı.
