# Kurulum kılavuzu

**Türkçe** · [English](../en/installation.md) · [← README](../../README.tr.md)

Bu kılavuz, PDF Araçları'nı kendi sunucunda `https://pdf.sporyazilimlari.com.tr` (veya başka bir alan adı)
üzerinden, otomatik SSL ile yayınlamayı anlatır.

## İçindekiler

1. [Gereksinimler](#1-gereksinimler)
2. [DNS ayarı](#2-dns-ayarı)
3. [Dosyaları sunucuya gönderme (scp)](#3-dosyaları-sunucuya-gönderme-scp)
4. [Kurulum betiğini çalıştırma](#4-kurulum-betiğini-çalıştırma)
5. [Telefona ve bilgisayara kurma (PWA)](#5-telefona-ve-bilgisayara-kurma-pwa)
6. [Güncelleme](#6-güncelleme)
7. [Kaynak kullanımı](#7-kaynak-kullanımı)
8. [Port çakışması (sunucuda zaten Nginx/Apache varsa)](#8-port-çakışması)
9. [Sorun giderme](#9-sorun-giderme)
10. [Faydalı komutlar](#10-faydalı-komutlar)

## 1. Gereksinimler

| | En az |
|---|---|
| İşletim sistemi | Ubuntu 20.04+, Debian 11+, AlmaLinux/Rocky 8+ veya Docker çalıştırabilen herhangi bir Linux |
| RAM | 256 MB (uygulama ~20–40 MB kullanır) |
| Disk | ~150 MB (Docker imajı + site) |
| Ağ | Genel IP adresi, 80 ve 443 portları dışarıya açık |
| Yetki | `root` veya `sudo` |

Docker kurulu değilse `kurulum.sh` onu resmi `get.docker.com` betiğiyle kurar.

## 2. DNS ayarı

Alan adı sağlayıcının (veya Cloudflare'in) DNS panelinde:

| Tür | Ad | Değer |
|---|---|---|
| A | `pdf` | sunucunun IPv4 adresi |
| AAAA (isteğe bağlı) | `pdf` | sunucunun IPv6 adresi |

Kontrol etmek için kendi bilgisayarında: `ping pdf.sporyazilimlari.com.tr` → sunucunun IP'sini göstermeli.

> **Cloudflare kullanıyorsan:** ilk kurulumda kaydı **"DNS only" (gri bulut)** yap. Sertifika alındıktan sonra
> isteğe bağlı olarak proxy'yi açabilirsin; bu durumda Cloudflare SSL modunu **Full (strict)** yap.

## 3. Dosyaları sunucuya gönderme (scp)

`pdf-sunucu.zip` dosyası her şeyi hazır içerir (alan adı ve e-posta `.env` içinde ayarlı).

```bash
# Kendi bilgisayarında (Windows'ta PowerShell'de de çalışır):
scp pdf-sunucu.zip root@SUNUCU_IP:/opt/
```

SSH anahtarı kullanıyorsan: `scp -i ~/.ssh/anahtarim pdf-sunucu.zip kullanici@SUNUCU_IP:/opt/`

## 4. Kurulum betiğini çalıştırma

```bash
ssh root@SUNUCU_IP
cd /opt
unzip -o pdf-sunucu.zip        # unzip yoksa: apt install -y unzip
cd pdf-sunucu
sudo bash kurulum.sh
```

Betik sırasıyla şunları yapar:

1. `.env` dosyasını okur (`DOMAIN`, `ACME_EMAIL`).
2. Docker ve Docker Compose yoksa kurar, servisi başlatır.
3. 80/443 portlarını başka bir programın kullanıp kullanmadığını kontrol eder.
4. `ufw` veya `firewalld` açıksa 80/tcp, 443/tcp ve 443/udp portlarını açar.
5. DNS kaydının bu sunucuyu gösterip göstermediğini kontrol eder.
6. `docker compose up -d --build` ile konteyneri başlatır.
7. Let's Encrypt sertifikası alınıp `https://` adresi yanıt verene kadar bekler (genelde 10–60 sn).

Sonunda şunu görürsün: `✔ Hazır / Ready → https://pdf.sporyazilimlari.com.tr`

Sertifika her 60–90 günde bir **otomatik yenilenir**; senin bir şey yapmana gerek yok.
Sertifikalar `caddy_data` Docker biriminde saklanır, konteyner silinse bile kaybolmaz.

### Alan adını veya e-postayı değiştirmek

`.env` dosyasını düzenle ve betiği tekrar çalıştır:

```bash
nano .env
sudo bash kurulum.sh
```

## 5. Telefona ve bilgisayara kurma (PWA)

| Cihaz | Nasıl |
|---|---|
| **Android (Chrome, Edge, Samsung Internet)** | Sayfadaki **⬇ Uygulamayı yükle** düğmesi veya ⋮ menü → *Uygulamayı yükle / Ana ekrana ekle* |
| **iPhone / iPad (Safari)** | **Paylaş** düğmesi → **Ana Ekrana Ekle** (sayfa ilk açılışta bunu hatırlatır) |
| **Windows / macOS / Linux (Chrome, Edge)** | Adres çubuğunun sağındaki yükle simgesi veya sayfadaki düğme |

Kurulduktan sonra:

- Uygulama kendi penceresinde, tarayıcı çubukları olmadan açılır.
- Bir kez açıldıktan sonra **internet olmadan da çalışır** (tüm kütüphaneler önbelleğe alınır).
- Bilgisayarda bir PDF'e sağ tıklayıp **Birlikte aç → PDF Araçları** diyebilirsin (tek PDF → Sesli Oku, birden çok → Birleştir).
- Uzun basınca/sağ tıklayınca kısayollar: Sesli Oku, Birleştir, Böl, Sıkıştır.
- Telefonda sonuç dosyası için **Paylaş** düğmesi çıkar: Dosyalar'a kaydet, WhatsApp, e-posta vb.

## 6. Güncelleme

Yeni bir `pdf-sunucu.zip` geldiğinde:

```bash
scp pdf-sunucu.zip root@SUNUCU_IP:/opt/
ssh root@SUNUCU_IP "cd /opt && unzip -o pdf-sunucu.zip && cd pdf-sunucu && bash kurulum.sh"
```

GitHub'dan kurduysan:

```bash
cd pdf && git pull && sudo bash kurulum.sh
```

Kullanıcıların kurulu uygulamaları bir sonraki açılışta yeni sürümü otomatik alır.
`.env` dosyan zip'te varsa üzerine yazılır; farklı ayar kullanıyorsan önce yedekle.

## 7. Kaynak kullanımı

`docker-compose.yml` içindeki sınırlar:

| Ayar | Değer | Açıklama |
|---|---|---|
| `mem_limit` | 96 MB | Üst sınır; normal kullanım ~20–40 MB |
| `GOMEMLIMIT` | 40 MiB | Caddy'nin belleği erken boşaltmasını sağlar |
| `cpus` | 0.5 | En fazla yarım çekirdek |
| `GOMAXPROCS` | 1 | Tek iş parçacığı havuzu |
| `pids_limit` | 50 | Süreç sınırı |
| `read_only` | evet | Dosya sistemi salt okunur |
| Loglar | kapalı / 2×1 MB | Diske neredeyse hiç yazılmaz |

Neden bu kadar az? PDF işlemleri kullanıcının cihazında yapılır; sunucu yalnızca statik dosya gönderir.
Kütüphaneler önceden Brotli/Gzip ile sıkıştırılmıştır, sunucu her istekte yeniden sıkıştırmaz.
PWA önbelleği sayesinde tekrar gelen kullanıcılar sunucuya neredeyse hiç istek atmaz.

Anlık kullanım: `docker stats pdf-araclari`

## 8. Port çakışması

Sunucunda zaten 80/443'ü kullanan bir web sunucusu (Nginx, Apache, Plesk, cPanel, başka bir proxy konteyneri) varsa
`kurulum.sh` durur ve bunu söyler. İki seçenek var:

**A) Mevcut sunucunun arkasında çalıştır (önerilen)**

1. `.env` dosyasının sonundaki üç satırın başındaki `#` işaretini kaldır:
   ```ini
   DOMAIN=:80
   HTTP_PORT=127.0.0.1:8080
   HTTPS_PORT=127.0.0.1:8443
   ```
   (Caddy bu durumda SSL almaz, yalnızca sunucunun içinde `127.0.0.1:8080` adresinde HTTP sunar.)
2. `sudo bash kurulum.sh` çalıştır.
3. Mevcut Nginx'e bir site ekle ve SSL'i certbot ile al:
   ```nginx
   server {
       server_name pdf.sporyazilimlari.com.tr;
       location / {
           proxy_pass http://127.0.0.1:8080;
           proxy_set_header Host $host;
       }
   }
   ```
   ```bash
   sudo nginx -t && sudo systemctl reload nginx
   sudo certbot --nginx -d pdf.sporyazilimlari.com.tr
   ```
   Apache, Plesk veya cPanel kullanıyorsan aynı şekilde `pdf.sporyazilimlari.com.tr` için `http://127.0.0.1:8080` adresine ters proxy tanımla.

**B) Mevcut sunucuyu kaldır** ve tüm sitelerini Caddy'ye taşı (daha az kaynak, ama diğer siteleri etkiler).

## 9. Sorun giderme

| Belirti | Çözüm |
|---|---|
| `✘ 80/443 portu başka bir program tarafından kullanılıyor` | [Port çakışması](#8-port-çakışması) bölümüne bak. `sudo ss -ltnp \| grep -E ':80\|:443'` hangi programın kullandığını gösterir. |
| Sertifika alınamıyor, loglarda `timeout` / `connection refused` | DNS A kaydını ve bulut sağlayıcının (Hetzner, AWS, Azure, Oracle…) güvenlik duvarında 80/443'ün açık olduğunu kontrol et. |
| Loglarda `too many certificates` / `rate limit` | Let's Encrypt sınırına takıldın; 1 saat bekle. Konteyneri sık sık silip `caddy_data` birimini silme. |
| Site açılıyor ama "güvenli değil" uyarısı | Sertifika henüz alınmamış. `docker compose logs -f pdf` ile izle. |
| Telefonda "Uygulamayı yükle" görünmüyor | Site **https** ile açılmalı. iPhone'da düğme yoktur, Paylaş → Ana Ekrana Ekle kullanılır. |
| Güncelleme sonrası eski sürüm görünüyor | Uygulamayı tamamen kapatıp yeniden aç; tarayıcıda bir kez yenile. |
| Sesli okumada Türkçe ses yok | Sesler cihazdan gelir. Android: *Google Konuşma Hizmetleri* → Türkçe ses verisi. iPhone: Ayarlar → Erişilebilirlik → Seslendirilen İçerik → Sesler → Türkçe. Windows: Ayarlar → Saat ve dil → Konuşma → Türkçe ses ekle. |
| `ACME_EMAIL .env dosyasinda olmali` hatası | `cp .env.example .env` yap ve e-postayı yaz. |

## 10. Faydalı komutlar

```bash
cd /opt/pdf-sunucu
docker compose ps                 # durum
docker compose logs -f pdf        # canlı loglar (Ctrl+C ile çık)
docker compose restart            # yeniden başlat
docker compose down               # durdur (sertifikalar korunur)
docker compose down -v            # durdur VE sertifikaları sil (dikkat!)
docker stats pdf-araclari         # RAM/CPU kullanımı
```
