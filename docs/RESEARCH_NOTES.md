# Teknik araştırma notları

Erişim tarihi: 2026-11-09. Proje `project.godot` içinde Godot 4.7 hedefliyor; doğrulama ortamı Godot 4.7.2.stable.official.

- [Godot 4.7 General optimization tips](https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html), resmi motor dokümantasyonu. Tavsiye: optimize etmeden önce Profiler/timing ile darboğazı belirle, en pahalı fonksiyonla başla, her optimizasyondan sonra yeniden ölç. Bu nedenle oyuncunun per-frame düşman ve mücevher grup taramalarının çağrı sıklığı azaltıldı; ancak FPS artışı veya hedef donanım sonucu iddia edilmiyor.
- [Godot 4.7 The Profiler](https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/the_profiler.html), resmi motor dokümantasyonu. Çerçeve, fizik ve boşta kalma sürelerini ayrı ölçmeyi; frame time'ın render maliyetini de içerdiğini açıklar. Kullanıcıya ait fiziksel cihaz veya Godot Profiler ölçümü bu revizyonda mevcut değil.
- [Godot 4.7 Optimizing 3D performance](https://docs.godotengine.org/en/4.7/tutorials/performance/optimizing_3d_performance.html), resmi motor dokümantasyonu. Şeffaf nesneler, animasyon/skinning ve tekrarlanan geometri için öneriler içerir. Projedeki karakterlerde hangi maliyetin baskın olduğunu kanıtlayan GPU/CPU ölçümü olmadığından model/renderer ayarları değiştirilmedi.

## Depo inceleme bulguları

Oyuncunun düşman hedefi ve mücevher taraması fizik güncellemesinde yineleniyordu. Yeniden hedef seçimi ve pickup taraması 0.1 saniyelik sabit aralığa alındı. Bu bir algoritma/çağrı sıklığı iyileştirmesidir; donanımda ölçülmüş FPS kazanımı değildir. Her merminin her fizik karesinde düşmanları kontrol etmesi, düşmanların `CharacterBody3D` fizik güncellemesi ve animasyon skinning maliyeti hâlâ ayrı incelenmeye açık.

İlk bağımsız denetim, HUD'ın `maxf(best, t)` ifadesini yanlış yorumlayıp rekor göstergesinin hatalı olduğunu bildirdi. GDScript `maxf` iki değerin büyüğünü döndürdüğü için bu bulgu kaynak koduyla çelişiyordu. Kod bu nedenle korunuyor; test hem kayıtlı rekoru hem de geçilen yeni rekoru doğruluyor.

## Görsel import bulgusu

`docs/gameplay.webp` geçerli 640×360 animasyonlu WebP'dir (144 kare). Godot 4.7.2'nin import aşaması bu README görselini statik doku olarak çözemedi. Görsel, oyun runtime'ında kullanılmıyor. İçeriğe dokunmadan `docs/.gdignore` eklenerek dokümantasyon görselinin oyun varlığı olarak import edilmesi engellendi; sonraki headless import'ta WebP hatası tekrarlanmadı.
