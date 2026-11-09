# Hayatta Kal

![Hayatta Kal](docs/gameplay.webp)

Yukarıdan bakışlı bir hayatta kalma oyunu. Arbaletin kendi kendine ateş ediyor; sen hareket ediyor, mücevher topluyor, seviye atlıyor ve büyüyen dalgalara karşı güçlendirme seçiyorsun.

**Hayatta Kal, LogondTech tarafından geliştirilen özgün bir projedir. Oyun karakterleri ve proje için hazırlanan içerikler proje sahibine aittir.**

## Oyna

[En son sürümü GitHub Releases sayfasından indir](https://github.com/LogondTech/hayatta-kal/releases/latest); kurulum gerekmiyor.

- **Windows:** `HayattaKal.exe`. Dosya imzalı olmadığı için SmartScreen uyarısı çıkabilir; Windows iletişim kutusundaki yönergeleri izleyin.
- **Linux:** `chmod +x HayattaKal.x86_64 && ./HayattaKal.x86_64`

Vulkan destekleyen bir ekran kartı gerekiyor. Windows'ta Direct3D 12 de kullanılabilir.

## Kontroller

- **WASD** ya da **ok tuşları:** yürü (nişan ve ateş otomatik)
- **1 / 2 / 3:** seviye atlayınca güçlendirme kartı seç
- **Boşluk**, **Enter** ya da **Esc:** girişi geç
- **R:** yeniden başla

## Kaynak koddan çalıştır

`project.godot` dosyasını [Godot 4.7](https://godotengine.org/download) ile aç ve F5'e bas.

## Geliştirici kontrolleri

Proje kökünde aşağıdaki komutlarla içe aktarmayı, regresyon testlerini ve 150 düşmanlı sentetik CPU mikrobenchmark'ını çalıştırabilirsin:

```sh
godot --headless --editor --path . --quit
godot --headless --path . res://tests/regression_smoke.tscn
godot --headless --path . --script res://tests/performance_probe.gd
```

Mikrobenchmark oyun FPS'ini veya GPU performansını değil, GDScript taramasıyla fizik broadphase sorgusunun CPU maliyetini karşılaştırır.

## Lisans

Kod MIT lisanslıdır; ayrıntılar için `LICENSE` dosyasına bakın. `assets/` klasöründeki modeller, dokular, müzik ve videolar MIT lisansının kapsamında değildir.
