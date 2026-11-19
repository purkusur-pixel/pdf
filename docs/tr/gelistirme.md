# Geliştirici kılavuzu

**Türkçe** · [English](../en/development.md) · [← README](../../README.tr.md)

## Mimari

Uygulama **tek bir HTML dosyasıdır** (`src/index.html`): CSS, arayüz ve tüm araçların JavaScript kodu içindedir.
Sunucu tarafında kod yoktur; Caddy yalnızca `html/` klasörünü statik olarak sunar.

| Katman | Teknoloji |
|---|---|
| Arayüz | Saf HTML + CSS + JavaScript (çerçeve yok) |
| PDF okuma / görüntüleme / metin | PDF.js |
| PDF oluşturma / düzenleme | pdf-lib |
| Word / PowerPoint / Excel | docx, mammoth, PptxGenJS, SheetJS, html2pdf.js |
| Şifreleme | jsPDF |
| Sesli okuma | Web Speech API (`speechSynthesis`) |
| Çevrimdışı / kurulum | Service Worker + Web App Manifest (PWA) |
| Sunucu | Caddy 2 (Docker), otomatik Let's Encrypt |

Kütüphaneler **gerektiğinde** yüklenir: kullanıcı yalnızca Birleştir'i açarsa yalnızca pdf-lib indirilir.

### Kod yapısı (`src/index.html`)

- `CDN` — kütüphane adresleri. `tools/build.py` bunları yerel `libs/` adresleriyle değiştirir.
- `need('pdflib', 'jszip')` — kütüphaneleri sırayla yükler.
- `TOOLS` — tüm araçların listesi. Her araç bir nesnedir:
  ```js
  { id: 'merge', group: 'Düzenle', icon: '⧉', color: '#d6453d',
    title: 'PDF Birleştir', desc: '…',
    accept: PDF_ACCEPT, multiple: true, min: 2, sortable: true,
    libs: ['pdflib'],
    options: () => [ opt.sel(…), opt.text(…) ],   // isteğe bağlı ayarlar
    note: '…',                                      // isteğe bağlı uyarı
    async onFiles(box){ … },                        // isteğe bağlı: dosya seçilince özel arayüz
    async run(){ return [{ name: 'x.pdf', blob }]; } }
  ```
- `setupReader`, `setupSign` — Sesli Oku ve İmzala araçlarının özel arayüzleri.
- Adres çubuğundaki `#merge` gibi kısımlar doğrudan ilgili aracı açar.

### Yeni araç ekleme

1. `TOOLS` dizisine yukarıdaki biçimde bir nesne ekle.
2. Kullanıcıya görünen her metni `__('Türkçe metin')` veya `` __t`Türkçe ${x} metin` `` ile yaz.
3. Aynı metni İngilizcesiyle `EN` sözlüğüne ekle (`{0}`, `{1}`… değişkenlerin yeridir):
   ```js
   'Türkçe {0} metin': 'English {0} text',
   ```
4. `python3 tools/build.py` ile `html/` klasörünü yeniden üret.

## Çoklu dil (i18n)

- Kaynak dil Türkçedir; çeviriler `src/index.html` içindeki `EN` nesnesindedir.
- `__('metin')` çeviriyi döndürür; `` __t`Sayfa ${n}` `` şablonları `'Sayfa {0}'` anahtarıyla çevirir.
- Statik HTML öğeleri `data-i18n` (düz metin) veya `data-i18n-html` (HTML) özniteliğiyle çevrilir.
- Dil seçimi `localStorage` içinde `pdfaraclari.lang` olarak saklanır; ilk açılışta tarayıcı diline bakılır.
- Yeni bir dil eklemek için: `LANGS` dizisine kodu ekle, `EN` gibi bir sözlük oluştur, `__` fonksiyonunu ona göre genişlet ve üst bardaki `#langSw` içine bir düğme koy.

## Derleme (`src` → `html`)

```bash
npm ci                              # kütüphaneleri package.json'daki sürümlerle indir
pip install -r requirements.txt     # Pillow (simgeler) ve brotli (sıkıştırma)
python3 tools/build.py
```

`tools/build.py` şunları yapar:

1. Kütüphaneleri `node_modules`'tan `html/libs/`'e kopyalar ve CDN adreslerini yerel adreslerle değiştirir.
2. Inter ve Dancing Script yazı tiplerini yerel olarak ekler (Google'a istek gitmez).
3. PWA simgelerini, `manifest.webmanifest`'i ve `sw.js`'yi (çevrimdışı önbellek) üretir.
4. Kurulum düğmesi, iOS ipucu, çevrimdışı notu ve telefonda **Paylaş** düğmesini ekler.
5. `libs/*.js` için `.br` ve `.gz` dosyalarını önceden üretir.

Service worker sürümü dosyaların özetinden üretilir; dosyalar değişince kullanıcılar yeni sürümü otomatik alır.

### Yerelde deneme

```bash
cd html && python3 -m http.server 8000      # http://localhost:8000
```

ya da Docker ile:

```bash
DOMAIN=:80 ACME_EMAIL=test@example.com HTTP_PORT=8080 HTTPS_PORT=8443 docker compose up --build   # http://localhost:8080
```

`src/index.html` derlenmeden de tek başına çalışır (kütüphaneleri CDN'den yükler); dosyayı tarayıcıda açman yeterli.

## GitHub'a gönderme ("gönder tuşu")

Depo kökündeki `github-gonder.sh` her şeyi tek komutla gönderir:

```bash
bash github-gonder.sh                    # ilk gönderim veya güncelleme
bash github-gonder.sh "Yeni araç eklendi" # kendi commit mesajınla
FORCE=1 bash github-gonder.sh            # GitHub'daki her şeyin üzerine yaz
```

Betik: git deposu yoksa oluşturur → adın/e-postan ayarlı değilse sorar → `origin`'i
`https://github.com/purkusur-pixel/pdf.git` olarak ayarlar → tüm değişiklikleri commit'ler → `main` dalına gönderir.
GitHub'daki depoda burada olmayan bir commit (ör. web'den oluşturulan README) varsa birleştirmeyi önerir.

**Giriş:** GitHub artık şifre kabul etmiyor. Şu yollardan biriyle giriş yap:

- **En kolayı:** [GitHub CLI](https://cli.github.com) kur ve bir kez `gh auth login` çalıştır.
- **Token:** GitHub → Settings → Developer settings → Personal access tokens → *Fine-grained token* oluştur
  (yalnızca `purkusur-pixel/pdf` deposu, *Contents: Read and write*). Git şifre sorduğunda bu token'ı yapıştır.
- **SSH:** `REPO_URL=git@github.com:purkusur-pixel/pdf.git bash github-gonder.sh`

Windows'ta betiği **Git Bash** içinde çalıştır.

### Depo açıklaması ve konular

GitHub'da deponun sağ üstündeki ⚙ (About) simgesine tıkla ve şunları gir:

- **Description:** `Tarayıcıda çalışan, gizlilik dostu PDF araçları (PWA) — birleştir, böl, dönüştür, imzala, sesli oku · Privacy-friendly in-browser PDF toolkit (PWA)`
- **Website:** `https://pdf.sporyazilimlari.com.tr`
- **Topics:** `pdf` `pwa` `pdf-tools` `pdf-merge` `pdf-split` `text-to-speech` `docker` `caddy` `turkish` `privacy`

ya da GitHub CLI ile:

```bash
gh repo edit purkusur-pixel/pdf \
  --description "Tarayıcıda çalışan, gizlilik dostu PDF araçları (PWA) · Privacy-friendly in-browser PDF toolkit" \
  --homepage https://pdf.sporyazilimlari.com.tr \
  --add-topic pdf,pwa,pdf-tools,pdf-merge,pdf-split,text-to-speech,docker,caddy,turkish,privacy
```

## Güvenlik notları

- `Caddyfile` sıkı bir Content-Security-Policy gönderir: sayfa yalnızca kendi alan adından kaynak yükleyebilir.
  (`'unsafe-inline'` ve `'unsafe-eval'` tek dosya mimarisi ve bazı kütüphaneler için gereklidir.)
- Konteyner salt okunur dosya sistemiyle, `no-new-privileges` ve kaynak sınırlarıyla çalışır.
- Kullanıcı dosyaları sunucuya hiç gelmediği için sunucuda saklanacak kişisel veri yoktur (erişim logları da kapalı).

## Katkı

Hata bildirimi ve öneriler için GitHub'da *Issue* aç; değişiklik için *Pull Request* gönder.
Lütfen yeni metinlerin İngilizcesini `EN` sözlüğüne eklemeyi unutma.
