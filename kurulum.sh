#!/usr/bin/env bash
# =============================================================================
#  PDF Araçları — tek komutla sunucu kurulumu / one-command server setup
#
#  Kullanım / Usage:   sudo bash kurulum.sh
#
#  Her şeyi kendisi yapar / does everything by itself:
#   • Docker yoksa kurar (Ubuntu, Debian, Oracle Linux, RHEL, Rocky, Alma)
#   • 80/443 boşsa  → Caddy doğrudan yayınlar, SSL'i kendisi alır
#     80/443'te nginx varsa → boş bir yerel port seçer, nginx sitesini yazar,
#                              SELinux iznini verir, certbot (webroot) ile SSL alır
#   • Güvenlik duvarını açar (ufw / firewalld / Oracle iptables)
#   • DNS'i kontrol eder, sonunda https adresini test eder
#  Tekrar çalıştırmak güvenlidir; güncelleme için de aynı komut kullanılır.
#  Safe to re-run; use the same command to update.
# =============================================================================
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; B='\033[1;34m'; N='\033[0m'
ok(){ echo -e "${G}✔${N} $*"; }
warn(){ echo -e "${Y}!${N} $*"; }
step(){ echo -e "\n${B}▶ $*${N}"; }
die(){ echo -e "${R}✘ $*${N}"; exit 1; }

[ "$(id -u)" -eq 0 ] || exec sudo -E bash "$0" "$@"

CONTAINER=pdf-araclari
DEFAULT_DOMAIN=pdf.sporyazilimlari.com.tr

# .env içinde KEY=VALUE yaz/güncelle / set or update KEY=VALUE in .env
setenv(){ if grep -q "^$1=" .env; then sed -i "s|^$1=.*|$1=$2|" .env; else echo "$1=$2" >> .env; fi; }
port_busy(){ ss -ltnH 2>/dev/null | awk '{print $4}' | grep -qE "[:.]$1\$"; }

# --- 1. Ayarlar / settings ---------------------------------------------------
step "Ayarlar / Settings"
[ -f .env ] || { cp .env.example .env; ok ".env oluşturuldu / created"; }
# eski sürümlerden kalan ayarları temizle / migrate older .env files
if grep -qE '^DOMAIN=:' .env; then
  d=$(grep -oP '^#DOMAIN=\K[a-z0-9.-]+' .env | head -1 || true)
  sed -i '/^DOMAIN=:/d; /^#DOMAIN=/d' .env
  setenv DOMAIN "${d:-$DEFAULT_DOMAIN}"
fi
set -a; . ./.env; set +a
DOMAIN="${DOMAIN:-$DEFAULT_DOMAIN}"
ACME_EMAIL="${ACME_EMAIL:-admin@${DOMAIN#*.}}"
setenv DOMAIN "$DOMAIN"; setenv ACME_EMAIL "$ACME_EMAIL"
ok "Alan adı / domain: $DOMAIN   e-posta / e-mail: $ACME_EMAIL"

# --- 2. Docker ---------------------------------------------------------------
step "Docker"
. /etc/os-release
if ! command -v docker >/dev/null 2>&1; then
  warn "Docker kuruluyor / installing Docker…"
  if [[ "${ID:-}" =~ ^(ol|rhel|rocky|almalinux|centos)$ ]]; then
    dnf install -y -q dnf-plugins-core
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    dnf install -y -q --allowerasing docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  else
    command -v curl >/dev/null 2>&1 || { apt-get update -qq && apt-get install -y -qq curl; }
    curl -fsSL https://get.docker.com | sh
  fi
fi
systemctl enable --now docker >/dev/null 2>&1 || true
docker compose version >/dev/null 2>&1 || {
  (apt-get update -qq && apt-get install -y -qq docker-compose-plugin) || dnf install -y -q docker-compose-plugin \
    || die "docker compose kurulamadı / could not install docker compose"
}
ok "Docker $(docker --version | awk '{print $3}' | tr -d ,) + compose"

# --- 3. Yöntem seçimi / choose mode -----------------------------------------
step "80/443 portları / ports"
docker compose down --remove-orphans >/dev/null 2>&1 || true   # kendi eski konteynerimizi bırak
owners=$(ss -ltnpH 2>/dev/null | awk '$4 ~ /[:.](80|443)$/' | grep -oP 'users:\(\("\K[^"]+' | sort -u | tr '\n' ' ' || true)
if [ -z "$owners" ]; then
  MODE=caddy
  ok "Portlar boş → Caddy doğrudan yayınlayacak / ports free → Caddy serves directly"
elif [[ "$owners" == *nginx* ]] && [[ ! "$owners" =~ (httpd|apache2|docker-proxy|caddy|traefik|haproxy) ]]; then
  MODE=nginx
  ok "80/443'te nginx var → nginx arkasında çalışacak / nginx found → running behind nginx"
else
  die "80/443 portunu kullanan program: ${owners}
   Bu durumda otomatik kurulum yapılamıyor. docs/tr/kurulum.md → 'Port çakışması'
   Cannot auto-configure with this program on 80/443. See docs/en/installation.md → 'Port conflict'."
fi

if [ "$MODE" = caddy ]; then
  setenv SITE_ADDRESS "$DOMAIN"; setenv HTTP_PORT 80; setenv HTTPS_PORT 443
else
  P=$(grep -oP '^HTTP_PORT=127\.0\.0\.1:\K\d+' .env || true)
  if [ -z "$P" ] || port_busy "$P" || port_busy "$((P+1))"; then
    P=18470; while port_busy "$P" || port_busy "$((P+1))"; do P=$((P+2)); done
  fi
  setenv SITE_ADDRESS ":80"; setenv HTTP_PORT "127.0.0.1:$P"; setenv HTTPS_PORT "127.0.0.1:$((P+1))"
  ok "Yerel port / local port: 127.0.0.1:$P"
fi

# --- 4. Güvenlik duvarı / firewall -------------------------------------------
step "Güvenlik duvarı / Firewall"
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
  ufw allow 80/tcp >/dev/null; ufw allow 443/tcp >/dev/null; ufw allow 443/udp >/dev/null
  ok "ufw: 80/tcp 443/tcp 443/udp"
elif command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
  firewall-cmd -q --permanent --add-service=http --add-service=https --add-port=443/udp && firewall-cmd -q --reload
  ok "firewalld: http https 443/udp"
elif command -v iptables >/dev/null 2>&1 && iptables -S INPUT 2>/dev/null | grep -q -- '-j REJECT'; then
  for p in "80 tcp" "443 tcp" "443 udp"; do set -- $p
    if ! iptables -C INPUT -p "$2" --dport "$1" -m state --state NEW -j ACCEPT 2>/dev/null; then
      n=$(iptables -L INPUT --line-numbers -n | awk '/REJECT/{print $1; exit}')
      iptables -I INPUT "${n:-1}" -p "$2" --dport "$1" -m state --state NEW -j ACCEPT
    fi
  done
  if command -v netfilter-persistent >/dev/null 2>&1; then netfilter-persistent save >/dev/null 2>&1 || true
  elif [ -d /etc/iptables ]; then iptables-save > /etc/iptables/rules.v4; fi
  ok "iptables: 80/tcp 443/tcp 443/udp"
else
  ok "Yerel güvenlik duvarı yok / no local firewall"
fi
if curl -fsS --max-time 2 -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ >/dev/null 2>&1; then
  warn "Oracle Cloud: VCN → Security List'te TCP 80, TCP 443 (ve UDP 443) açık olmalı / must be open in the VCN Security List"
fi

# --- 5. DNS ------------------------------------------------------------------
step "DNS"
SERVER_IP=$(curl -fsS4 --max-time 5 https://api.ipify.org 2>/dev/null || true)
DNS_IP=$(getent ahostsv4 "$DOMAIN" 2>/dev/null | awk 'NR==1{print $1}' || true)
if [ -z "$DNS_IP" ]; then
  die "${DOMAIN} için DNS kaydı yok. A kaydını ${SERVER_IP:-sunucu IP} adresine ekle, sonra tekrar çalıştır.
   No DNS record for ${DOMAIN}. Add an A record → ${SERVER_IP:-server IP} and run again."
elif [ -n "$SERVER_IP" ] && [ "$DNS_IP" != "$SERVER_IP" ]; then
  warn "DNS ${DNS_IP} gösteriyor, sunucu ${SERVER_IP} (Cloudflare proxy ise sorun değil) / DNS → ${DNS_IP}, server is ${SERVER_IP}"
else
  ok "$DOMAIN → $DNS_IP"
fi

# --- 6. Uygulamayı başlat / start the app ------------------------------------
step "Uygulama / App"
docker compose up -d --build --remove-orphans
docker image prune -f >/dev/null 2>&1 || true
ok "Konteyner çalışıyor / container running"

# --- 7a. nginx + certbot (webroot) --------------------------------------------
if [ "$MODE" = nginx ]; then
  step "nginx + SSL"
  for i in $(seq 1 20); do curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$P/" && break; sleep 1; done
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$P/" || { docker compose logs --tail 20 pdf; die "Konteyner yanıt vermiyor / container not responding"; }

  CONF_DIR=/etc/nginx/conf.d; mkdir -p "$CONF_DIR"
  CONF="$CONF_DIR/$DOMAIN.conf"
  WEBROOT=/var/www/letsencrypt; mkdir -p "$WEBROOT"
  CERT=/etc/letsencrypt/live/$DOMAIN/fullchain.pem
  KEY=/etc/letsencrypt/live/$DOMAIN/privkey.pem
  [ -f "$CONF" ] && cp "$CONF" "/tmp/$DOMAIN.conf.bak"

  write_conf(){  # $1 = http | https
    {
      echo "# PDF Araçları — kurulum.sh tarafından oluşturuldu / generated by kurulum.sh"
      echo "server {"
      echo "    listen 80;"
      echo "    listen [::]:80;"
      echo "    server_name $DOMAIN;"
      echo "    location /.well-known/acme-challenge/ { root $WEBROOT; }"
      if [ "$1" = https ]; then
        echo "    location / { return 301 https://\$host\$request_uri; }"
        echo "}"
        echo "server {"
        echo "    listen 443 ssl;"
        echo "    listen [::]:443 ssl;"
        echo "    server_name $DOMAIN;"
        echo "    ssl_certificate     $CERT;"
        echo "    ssl_certificate_key $KEY;"
        echo "    ssl_protocols TLSv1.2 TLSv1.3;"
        echo "    ssl_session_cache shared:pdfssl:1m;"
      fi
      echo "    client_max_body_size 1m;"
      echo "    location / {"
      echo "        proxy_pass http://127.0.0.1:$P;"
      echo "        proxy_http_version 1.1;"
      echo "        proxy_set_header Host \$host;"
      echo "        proxy_set_header X-Forwarded-Proto \$scheme;"
      echo "    }"
      echo "}"
    } > "$CONF"
  }
  reload_nginx(){
    if nginx -t >/dev/null 2>&1; then systemctl reload nginx
    else
      nginx -t || true
      [ -f "/tmp/$DOMAIN.conf.bak" ] && cp "/tmp/$DOMAIN.conf.bak" "$CONF" || rm -f "$CONF"
      systemctl reload nginx || true
      die "nginx ayarı hatalı, eski hâline döndürüldü / nginx config invalid, restored"
    fi
  }

  if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" != "Disabled" ]; then
    setsebool -P httpd_can_network_connect 1 && ok "SELinux: nginx → 127.0.0.1:$P izni / allowed"
    command -v restorecon >/dev/null 2>&1 && restorecon -R "$WEBROOT" || true
  fi

  if [ ! -f "$CERT" ]; then
    write_conf http; reload_nginx
    ok "nginx (HTTP) hazır, sertifika alınıyor / getting certificate…"
    if ! command -v certbot >/dev/null 2>&1; then
      if command -v dnf >/dev/null 2>&1; then
        dnf install -y -q certbot 2>/dev/null || { dnf install -y -q "oracle-epel-release-el${VERSION_ID%%.*}" 2>/dev/null || dnf install -y -q epel-release; dnf install -y -q certbot; }
      else apt-get update -qq && apt-get install -y -qq certbot; fi
    fi
    certbot certonly --webroot -w "$WEBROOT" -d "$DOMAIN" --non-interactive --agree-tos \
      -m "$ACME_EMAIL" --no-eff-email --deploy-hook "systemctl reload nginx" \
      || die "Sertifika alınamadı. DNS ve 80. port dışarıdan erişilebilir mi? / Certificate failed. Is port 80 reachable?"
  fi
  write_conf https; reload_nginx
  ok "nginx (HTTPS) hazır: $CONF"
  systemctl enable --now certbot-renew.timer >/dev/null 2>&1 || systemctl enable --now certbot.timer >/dev/null 2>&1 || true
  ok "Sertifika otomatik yenilenir / auto-renews ($(openssl x509 -enddate -noout -in "$CERT" 2>/dev/null | cut -d= -f2))"
fi

# --- 7b/8. Son kontrol / final check -------------------------------------------
step "Kontrol / Check"
for i in $(seq 1 45); do
  if curl -fsS --max-time 4 -o /dev/null "https://${DOMAIN}/" 2>/dev/null; then
    echo
    ok "Hazır / Ready →  https://${DOMAIN}"
    docker stats --no-stream --format "   RAM: {{.MemUsage}}   CPU: {{.CPUPerc}}" "$CONTAINER" 2>/dev/null || true
    exit 0
  fi
  sleep 2
done
warn "https://${DOMAIN} henüz yanıt vermiyor / not answering yet."
[ "$MODE" = caddy ] && docker compose logs --tail 25 pdf
warn "Oracle Cloud / bulut panelinde 80 ve 443'ün açık olduğunu kontrol et, sonra tekrar çalıştır."
warn "Check that 80 and 443 are open in your cloud panel, then run again."
exit 1
