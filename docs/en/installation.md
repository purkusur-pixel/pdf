# Installation guide

[Türkçe](../tr/kurulum.md) · **English** · [← README](../../README.md)

This guide explains how to publish PDF Tools on your own server at `https://pdf.sporyazilimlari.com.tr`
(or any other domain) with automatic HTTPS.

## Contents

1. [Requirements](#1-requirements)
2. [DNS](#2-dns)
3. [Copying the files to the server (scp)](#3-copying-the-files-to-the-server-scp)
4. [Running the setup script](#4-running-the-setup-script)
5. [Installing on phones and computers (PWA)](#5-installing-on-phones-and-computers-pwa)
6. [Updating](#6-updating)
7. [Resource usage](#7-resource-usage)
8. [Port conflict (Nginx/Apache already running)](#8-port-conflict)
9. [Troubleshooting](#9-troubleshooting)
10. [Useful commands](#10-useful-commands)

## 1. Requirements

| | Minimum |
|---|---|
| OS | Ubuntu 20.04+, Debian 11+, AlmaLinux/Rocky 8+, or any Linux that runs Docker |
| RAM | 256 MB (the app uses ~20–40 MB) |
| Disk | ~150 MB (Docker image + site) |
| Network | Public IP address, ports 80 and 443 reachable from the internet |
| Privileges | `root` or `sudo` |

If Docker isn't installed, `kurulum.sh` installs it with the official `get.docker.com` script.

## 2. DNS

In your DNS provider's (or Cloudflare's) panel:

| Type | Name | Value |
|---|---|---|
| A | `pdf` | the server's IPv4 address |
| AAAA (optional) | `pdf` | the server's IPv6 address |

To check, on your own computer: `ping pdf.sporyazilimlari.com.tr` → it should show the server's IP.

> **Using Cloudflare?** For the first setup set the record to **"DNS only" (grey cloud)**. After the certificate
> is issued you may turn the proxy on; then set Cloudflare's SSL mode to **Full (strict)**.

## 3. Copying the files to the server (scp)

`pdf-sunucu.zip` ("server zip") contains everything, preconfigured (domain and e-mail are set in `.env`).

```bash
# On your own computer (also works in Windows PowerShell):
scp pdf-sunucu.zip root@SERVER_IP:/opt/
```

With an SSH key: `scp -i ~/.ssh/mykey pdf-sunucu.zip user@SERVER_IP:/opt/`

## 4. Running the setup script

```bash
ssh root@SERVER_IP
cd /opt
unzip -o pdf-sunucu.zip        # if unzip is missing: apt install -y unzip
cd pdf-sunucu
sudo bash kurulum.sh
```

The script, step by step:

1. Reads `.env` (`DOMAIN`, `ACME_EMAIL`).
2. Installs Docker and Docker Compose if missing and starts the service.
3. Checks that no other program uses ports 80/443.
4. Opens 80/tcp, 443/tcp and 443/udp if `ufw` or `firewalld` is active.
5. Checks that the DNS record points to this server.
6. Starts the container with `docker compose up -d --build`.
7. Waits until the Let's Encrypt certificate is issued and `https://` answers (usually 10–60 s).

At the end you'll see: `✔ Hazır / Ready → https://pdf.sporyazilimlari.com.tr`

Certificates are **renewed automatically** every 60–90 days; nothing to do on your side.
They are stored in the `caddy_data` Docker volume and survive container rebuilds.

### Changing the domain or e-mail

Edit `.env` and run the script again:

```bash
nano .env
sudo bash kurulum.sh
```

## 5. Installing on phones and computers (PWA)

| Device | How |
|---|---|
| **Android (Chrome, Edge, Samsung Internet)** | The **⬇ Install app** button on the page, or ⋮ menu → *Install app / Add to Home screen* |
| **iPhone / iPad (Safari)** | **Share** → **Add to Home Screen** (the page reminds you on first visit) |
| **Windows / macOS / Linux (Chrome, Edge)** | The install icon at the right of the address bar, or the button on the page |

Once installed:

- The app opens in its own window without browser bars.
- After the first visit it **works offline** (all libraries are cached).
- On a computer you can right-click a PDF → **Open with → PDF Tools** (one PDF → Read Aloud, several → Merge).
- Long-press / right-click the icon for shortcuts: Read Aloud, Merge, Split, Compress.
- On phones a **Share** button appears next to the result: save to Files, WhatsApp, e-mail, etc.

## 6. Updating

When you get a new `pdf-sunucu.zip`:

```bash
scp pdf-sunucu.zip root@SERVER_IP:/opt/
ssh root@SERVER_IP "cd /opt && unzip -o pdf-sunucu.zip && cd pdf-sunucu && bash kurulum.sh"
```

If you installed from GitHub:

```bash
cd pdf && git pull && sudo bash kurulum.sh
```

Installed apps pick up the new version automatically the next time they are opened.
A `.env` inside the zip overwrites yours; back it up first if you changed it.

## 7. Resource usage

Limits in `docker-compose.yml`:

| Setting | Value | Meaning |
|---|---|---|
| `mem_limit` | 96 MB | Hard cap; normal use is ~20–40 MB |
| `GOMEMLIMIT` | 40 MiB | Makes Caddy return memory early |
| `cpus` | 0.5 | At most half a core |
| `GOMAXPROCS` | 1 | Single scheduler thread |
| `pids_limit` | 50 | Process limit |
| `read_only` | yes | Read-only filesystem |
| Logs | off / 2×1 MB | Almost no disk writes |

Why so little? PDF processing happens on the user's device; the server only sends static files.
Libraries are pre-compressed with Brotli/Gzip, so the server never compresses them per request.
Thanks to the PWA cache, returning users barely touch the server at all.

Live usage: `docker stats pdf-araclari`

## 8. Port conflict

If a web server already uses 80/443 (Nginx, Apache, Plesk, cPanel, another proxy container),
`kurulum.sh` stops and tells you. Two options:

**A) Run behind the existing server (recommended)**

1. Remove the `#` from the last three lines of `.env`:
   ```ini
   DOMAIN=:80
   HTTP_PORT=127.0.0.1:8080
   HTTPS_PORT=127.0.0.1:8443
   ```
   (Caddy then doesn't fetch certificates; it only serves HTTP on `127.0.0.1:8080` inside the server.)
2. Run `sudo bash kurulum.sh`.
3. Add a site to your existing Nginx and get TLS with certbot:
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
   With Apache, Plesk or cPanel, create a reverse proxy for `pdf.sporyazilimlari.com.tr` to `http://127.0.0.1:8080` the same way.

**B) Remove the existing server** and move all your sites to Caddy (fewer resources, but affects other sites).

## 9. Troubleshooting

| Symptom | Fix |
|---|---|
| `✘ 80/443 portu başka bir program tarafından kullanılıyor` (port in use) | See [Port conflict](#8-port-conflict). `sudo ss -ltnp \| grep -E ':80\|:443'` shows which program uses it. |
| Certificate not issued, logs show `timeout` / `connection refused` | Check the DNS A record and that 80/443 are open in your cloud provider's firewall (Hetzner, AWS, Azure, Oracle…). |
| Logs show `too many certificates` / `rate limit` | Let's Encrypt rate limit; wait an hour. Don't delete the `caddy_data` volume repeatedly. |
| Site opens with a "not secure" warning | The certificate isn't issued yet. Watch `docker compose logs -f pdf`. |
| "Install app" doesn't appear on the phone | The site must be opened over **https**. iPhone has no button; use Share → Add to Home Screen. |
| Old version still shows after an update | Fully close and reopen the app; refresh once in the browser. |
| No voice for my language in Read Aloud | Voices come from the device. Android: *Speech Services by Google* → voice data. iPhone: Settings → Accessibility → Spoken Content → Voices. Windows: Settings → Time & language → Speech → Add voices. |
| Error `ACME_EMAIL .env dosyasinda olmali` | Run `cp .env.example .env` and set the e-mail. |

## 10. Useful commands

```bash
cd /opt/pdf-sunucu
docker compose ps                 # status
docker compose logs -f pdf        # live logs (Ctrl+C to quit)
docker compose restart            # restart
docker compose down               # stop (certificates are kept)
docker compose down -v            # stop AND delete certificates (careful!)
docker stats pdf-araclari         # RAM/CPU usage
```
