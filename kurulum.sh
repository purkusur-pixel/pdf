#!/usr/bin/env bash
# =============================================================================
#  PDF Araçları — sunucu kurulumu / server setup
#  Kullanım / Usage:   sudo bash kurulum.sh
#  Tekrar çalıştırmak güvenlidir (güncelleme için de kullanılır).
#  Safe to re-run (also used for updates).
# =============================================================================
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; N='\033[0m'
ok(){ echo -e "${G}✔${N} $*"; }
warn(){ echo -e "${Y}!${N} $*"; }
die(){ echo -e "${R}✘ $*${N}"; exit 1; }

[ "$(id -u)" -eq 0 ] || exec sudo -E bash "$0" "$@"

# --- 1. Ayarlar / settings ---------------------------------------------------
[ -f .env ] || { cp .env.example .env; warn ".env oluşturuldu / created from .env.example"; }
set -a; . ./.env; set +a
[ -n "${DOMAIN:-}" ] || die "DOMAIN .env içinde boş / empty in .env"
[ -n "${ACME_EMAIL:-}" ] || die "ACME_EMAIL .env içinde boş / empty in .env"
PROXY=0; [[ "$DOMAIN" == :* ]] && PROXY=1
if [ "$PROXY" = 1 ]; then ok "Proxy modu / proxy mode: HTTP → ${HTTP_PORT:-80}"; else ok "Alan adı / domain: ${DOMAIN}"; fi

# --- 2. Docker ---------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  warn "Docker yok, kuruluyor / Docker not found, installing…"
  command -v curl >/dev/null 2>&1 || { (apt-get update -qq && apt-get install -y -qq curl) || (dnf install -y curl) || (yum install -y curl); }
  curl -fsSL https://get.docker.com | sh
fi
systemctl enable --now docker >/dev/null 2>&1 || true
docker compose version >/dev/null 2>&1 || {
  warn "docker compose eklentisi kuruluyor / installing compose plugin…"
  (apt-get update -qq && apt-get install -y -qq docker-compose-plugin) || (dnf install -y docker-compose-plugin) || (yum install -y docker-compose-plugin) \
    || die "docker compose kurulamadı / could not install docker compose"
}
ok "Docker $(docker --version | awk '{print $3}' | tr -d ,) + compose hazır / ready"

if [ "$PROXY" = 1 ]; then
  docker compose up -d --build --remove-orphans
  for i in $(seq 1 20); do
    if curl -fsS --max-time 3 -o /dev/null "http://${HTTP_PORT:-80}/" 2>/dev/null || curl -fsS --max-time 3 -o /dev/null "http://127.0.0.1:${HTTP_PORT##*:}/" 2>/dev/null; then
      ok "Hazır / Ready → http://${HTTP_PORT} (mevcut proxy'ni buraya yönlendir / point your proxy here)"; exit 0; fi
    sleep 1
  done
  docker compose logs --tail 25 pdf; die "Konteyner yanıt vermiyor / container not responding"
fi

# --- 3. Portlar / ports 80-443 ----------------------------------------------
busy=$(ss -ltnpH 2>/dev/null | awk '$4 ~ /:(80|443)$/' | grep -v -E 'docker-proxy|"caddy"' || true)
if [ -n "$busy" ]; then
  echo "$busy"
  die "80/443 portu başka bir program tarafından kullanılıyor (ör. nginx/apache).
   Port 80/443 is used by another program. See docs/tr/kurulum.md → 'Port çakışması' / docs/en/installation.md → 'Port conflict'."
fi
ok "80/443 portları boş / ports free"

# --- 4. Güvenlik duvarı / firewall -------------------------------------------
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
  ufw allow 80/tcp >/dev/null; ufw allow 443/tcp >/dev/null; ufw allow 443/udp >/dev/null
  ok "ufw: 80/tcp, 443/tcp, 443/udp açıldı / opened"
elif command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
  firewall-cmd -q --permanent --add-service=http --add-service=https --add-port=443/udp && firewall-cmd -q --reload
  ok "firewalld: http, https, 443/udp açıldı / opened"
else
  warn "Yerel güvenlik duvarı bulunamadı; bulut panelinde 80 ve 443 açık olmalı / make sure 80+443 are open in your cloud panel"
fi

# --- 5. DNS kontrolü / DNS check ---------------------------------------------
SERVER_IP=$(curl -fsS4 --max-time 5 https://api.ipify.org 2>/dev/null || curl -fsS4 --max-time 5 https://ifconfig.me 2>/dev/null || true)
DNS_IP=$(getent ahostsv4 "$DOMAIN" 2>/dev/null | awk 'NR==1{print $1}' || true)
if [ -z "$DNS_IP" ]; then
  warn "${DOMAIN} için DNS kaydı bulunamadı. A kaydını ${SERVER_IP:-sunucu IP} adresine ekle; SSL ancak DNS çalışınca alınır."
  warn "No DNS record for ${DOMAIN}. Add an A record → ${SERVER_IP:-server IP}; the certificate is issued once DNS works."
elif [ -n "$SERVER_IP" ] && [ "$DNS_IP" != "$SERVER_IP" ]; then
  warn "DNS ${DNS_IP} gösteriyor ama bu sunucu ${SERVER_IP}. (Cloudflare proxy açıksa 'DNS only' yap.)"
  warn "DNS points to ${DNS_IP}, but this server is ${SERVER_IP}. (If using Cloudflare proxy, set it to 'DNS only'.)"
else
  ok "DNS doğru / correct: ${DOMAIN} → ${DNS_IP}"
fi

# --- 6. Başlat / start --------------------------------------------------------
docker compose up -d --build --remove-orphans
docker image prune -f >/dev/null 2>&1 || true
ok "Konteyner çalışıyor / container running"

# --- 7. Sertifika bekle / wait for certificate ----------------------------------
echo -n "SSL sertifikası bekleniyor / waiting for certificate "
for i in $(seq 1 45); do
  if curl -fsS --max-time 4 -o /dev/null "https://${DOMAIN}/" 2>/dev/null; then
    echo; ok "Hazır / Ready → https://${DOMAIN}"
    docker stats --no-stream --format "   RAM: {{.MemUsage}}  CPU: {{.CPUPerc}}" pdf-araclari || true
    exit 0
  fi
  echo -n "."; sleep 2
done
echo
warn "HTTPS henüz yanıt vermiyor / HTTPS not answering yet. Son loglar / last logs:"
docker compose logs --tail 25 pdf
warn "DNS ve 80. port dışarıdan erişilebilir olunca Caddy otomatik tekrar dener."
warn "Caddy retries automatically once DNS and port 80 are reachable."
