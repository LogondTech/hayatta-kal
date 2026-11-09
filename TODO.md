# Revizyon görev listesi

- [x] HUD, kayıtlı rekoru korumalı; koşu yeni rekoru aşmış fakat ölüm ekranında kaydedilmemişse süreyi "Rekor adayı" olarak ayırmalı.
- [x] Karakter hasar parlaması, daha önce başlatılmış bir zamanlayıcıdan etkilenmemeli; son hasarın parlama süresi tamamlanana kadar görünür kalmalı.
- [x] Dalga yöneticisi, rastgele küme büyüklüğünü kalan kapasiteye göre sınırlamalı; canlı düşman sayısı `MAX_ALIVE` değerini aşmamalı.
- [x] Oyuncu hedef ve mücevher seçim taramalarını her fizik karesinde değil, kısa ve sabit aralıklarla yenilemeli; geçersiz/ölmekte olan hedef ateşleme hedefi olarak kalmamalı.
- [x] README oyun/proje tanıtımını korumalı, güncel depo sahibine atıfsız üçüncü taraf yaratıcı/yayın bilgisi vermemeli; indirme adresi bu depoya yönelmeli ve kod lisansı ile varlık kapsamını ayırmalı.
- [x] Godot 4.7 headless import, 900 fizik karelik ana sahne regresyonu ve yeni mantık testleri geçmeli; mevcut kayıt politikası korunmalı.
- [x] 150 hedef / 2.500 sorgu CPU mikrobenchmark'ı beş kez çalıştırılmalı; broadphase ile eski GDScript taraması aynı isabet sayısıyla karşılaştırılmalı.
- [ ] Hedef cihazın CPU/GPU, frame time ve FPS profili gerçek cihaz üzerinde alınmalı. Cloud sandbox bu cihazı veya GPU'yu temsil etmiyor; cihaz ölçümü olmadan FPS kazanımı ileri sürülmemeli.
