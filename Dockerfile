# Statik site + otomatik HTTPS / static site + automatic HTTPS
FROM caddy:2.8-alpine
COPY Caddyfile /etc/caddy/Caddyfile
COPY html /srv
