# Kullanım kılavuzu

**Türkçe** · [English](../en/usage.md) · [← README](../../README.tr.md)

## Genel kullanım

1. Ana ekranda bir araç seç.
2. **Dosya seç**'e dokun veya dosyayı kutuya sürükle.
3. Varsa seçenekleri ayarla.
4. Alttaki büyük düğmeye bas (ör. **PDF Birleştir →**).
5. **İndir** ile sonucu kaydet. Telefonda **Paylaş** ile Dosyalar'a, WhatsApp'a veya e-postaya gönderebilirsin.

Birden çok dosya üreten araçlar (Böl, PDF → JPG) ayrıca hepsini içeren bir **.zip** verir.

- **Dil:** Sağ üstteki **TR / EN** düğmesi. Seçimin hatırlanır.
- **Gizlilik:** Dosyalar hiçbir yere yüklenmez. İşlem bittiğinde sayfayı kapatman yeterli.
- **Sayfa aralıkları:** Virgülle ayır, tire ile aralık ver. Örnekler: `1-3, 5, 8-` (8'den sona kadar), `2`, `-4` (baştan 4'e kadar).

---

## 🔊 PDF Sesli Oku

PDF'teki metni cihazının sesiyle okur.

- **Cümleye dokun:** Okuma o cümleden başlar.
- **Buradan oku ▶:** O sayfanın başından başlar.
- **Alt çubuk:** ⏮ önceki cümle · ▶/❚❚ oynat/duraklat · ⏭ sonraki cümle · ■ durdur.
- **Ses / Hız / Ton:** ⭐ ile işaretli sesler daha doğaldır. Seçimin hatırlanır.
- **Klavye:** Boşluk oynat/duraklat, ← → cümleler arasında gezinir.

**En doğal sesler:**

| Cihaz | Yapılacak |
|---|---|
| Bilgisayar | **Microsoft Edge** ile aç → "Microsoft Emel/Ahmet Online (Natural)" (internet gerekir) |
| iPhone/iPad | Ayarlar → Erişilebilirlik → Seslendirilen İçerik → Sesler → Türkçe → "Geliştirilmiş/Premium" sesi indir |
| Android | Google Konuşma Hizmetleri → Ayarlar → Ses verilerini yükle → Türkçe |

Taranmış (resim) PDF'lerde metin olmadığı için okunacak bir şey bulunmaz.

---

## Düzenle

### PDF Birleştir
Birden çok PDF'i sırayla tek dosyada toplar. ↑ ↓ ile sırayı değiştir, ✕ ile çıkar. Aynı dosyayı birden çok kez ekleyebilirsin.

### PDF Böl
- **Her sayfa ayrı dosya:** 10 sayfalık PDF'ten 10 dosya çıkar.
- **Belirttiğim aralıklar:** `1-3, 4-6, 7-` → 3 dosya.
- **Her N sayfada bir:** N=2 → 1-2, 3-4, 5-6…

### Sayfa Çıkar
Yalnızca yazdığın sayfalardan yeni bir PDF yapar. Örnek: `1, 3-5` → 4 sayfalık PDF.

### Sayfa Sil
Yazdığın sayfaları kaldırır. Örnek: `2, 5-7`.

### Sayfaları Düzenle
Her sayfanın küçük önizlemesi görünür. Sayfanın altındaki düğmeler:
◀ ▶ taşı · ⟲ ⟳ döndür · ✕ sil (↺ geri al). Sonra **Sayfaları Düzenle →** düğmesine bas.

### PDF Döndür
Seçtiğin sayfaları (boş bırakırsan hepsini) 90° sağa, 90° sola veya 180° çevirir. İçerik bozulmaz.

### PDF Sıkıştır
Sayfaları JPEG görüntüye çevirerek küçültür.
- **Güçlü:** En küçük dosya, düşük kalite.
- **Önerilen:** Dengeli.
- **Hafif:** En iyi kalite.

Taranmış veya fotoğraflı PDF'lerde çok etkilidir. Metin ağırlıklı PDF'lerde dosya büyüyebilir; uygulama bu durumda uyarır ve orijinali kullanmanı önerir.
⚠ Sonuçta metin seçilemez ve aranamaz.

### PDF Kırp
Her sayfanın üst/alt/sol/sağ kenarından milimetre cinsinden keser (görünür alanı daraltır).

---

## PDF'den dönüştür

### PDF → JPG / PNG
Her sayfayı resim yapar.
- **Çözünürlük:** 72 DPI (ekran), 150 DPI (normal), 300 DPI (baskı).
- **Biçim:** JPG daha küçük, PNG kayıpsız.

### PDF → Word
Metni ve paragrafları düzenlenebilir bir `.docx` dosyasına aktarır. Her PDF sayfası yeni bir Word sayfasında başlar.
Karmaşık düzen, tablo ve resimler aktarılmaz.

### PDF → PowerPoint
Her sayfa, görünümü birebir korunarak bir slayta resim olarak yerleştirilir. Slayt boyutu ilk sayfaya göre ayarlanır.

### PDF → Metin
Tüm metni sayfa başlıklarıyla birlikte `.txt` olarak verir.

---

## PDF'ye dönüştür

### JPG / PNG → PDF
Birden çok resmi (JPG, PNG, WEBP, GIF…) sırayla PDF yapar.
- **Sayfa boyutu:** A4, Letter veya resim boyutunda.
- **Yön:** Otomatik (yatay resim → yatay sayfa), dikey veya yatay.
- **Kenar boşluğu:** Yok, küçük veya büyük.

### Word → PDF
`.docx` belgesini PDF yapar: başlıklar, listeler, tablolar ve resimler aktarılır.
Yazı tipleri ve sayfa sonları Word'dekinden biraz farklı olabilir. Eski `.doc` dosyalarını önce Word'de `.docx` olarak kaydet.

### Excel → PDF
`.xlsx`, `.xls`, `.ods` veya `.csv` dosyasının her sayfasını tablo olarak PDF'e aktarır. Geniş tablolar için **Yatay** seç.
Renkler, grafikler ve hücre biçimleri aktarılmaz.

---

## İmza & işaret

### PDF İmzala
1. PDF'i seç.
2. **Çiz** sekmesinde parmağınla veya fareyle imzanı at (renk seçilebilir), ya da **Yaz** sekmesinde adını yaz (el yazısı stilinde görünür).
3. **Sayfa**'yı seç (varsayılan: son sayfa).
4. Önizlemede imzanın gideceği yere **dokun**. **İmza genişliği** ile boyutunu ayarla.
5. İstersen **Tüm sayfalara ekle**'yi işaretle.
6. **PDF İmzala →** düğmesine bas.

> Bu, görsel bir imzadır (ıslak imza görüntüsü). E-imza / nitelikli elektronik sertifika değildir.

### Filigran Ekle
Her sayfaya yazı damgası basar (ör. GİZLİDİR, TASLAK, ÖRNEK).
Renk, saydamlık, büyüklük ve açı (çapraz/yatay) ayarlanabilir. **Sayfayı döşe** ile sayfa boyunca tekrarlanır. Türkçe karakterler desteklenir.

### Sayfa Numarası
- **Konum:** Altta veya üstte, solda, ortada ya da sağda.
- **Biçim:** `1`, `1 / 10`, `Sayfa 1`, `Sayfa 1 / 10`.
- **İlk numara** ve **numaralamaya başlanacak sayfa** (ör. kapağı atlamak için 2) ayarlanabilir.

---

## Güvenlik

### PDF Şifrele
PDF'e açılış şifresi koyar; dosyayı açan herkes şifre girmek zorunda kalır.
⚠ Sayfalar yüksek çözünürlüklü görüntüye çevrilir, metin seçilemez. Şifreyi unutursan kurtarılamaz.

### Kilit Aç
Şifresini **bildiğin** bir PDF'in şifresiz kopyasını oluşturur. Sayfalar görüntüye çevrilir.

### PDF Onar
Bozuk veya hatalı kaydedilmiş PDF'leri yeniden yazar. Yapı onarılamazsa sayfalar yeniden çizilerek kurtarılmaya çalışılır.

---

## Sık sorulan sorular

**Dosyalarım sunucuya gidiyor mu?**
Hayır. Tüm işlemler tarayıcında JavaScript ile yapılır. İstersen internet bağlantısını kesip deneyebilirsin: araçlar çalışmaya devam eder.

**Dosya boyutu sınırı var mı?**
Sunucu tarafında yok. Sınır, cihazının belleğidir. Telefonda yüzlerce sayfalık PDF'lerde bazı işlemler (sıkıştırma, PDF → resim) yavaşlayabilir.

**Hangi tarayıcılar destekleniyor?**
Chrome, Edge, Firefox ve Safari'nin son sürümleri. Sesli okumada en iyi sonucu Edge (bilgisayar) ve Safari (iPhone) verir.

**İnternet olmadan çalışır mı?**
Evet, siteyi veya uygulamayı en az bir kez internetle açtıysan çalışır.
