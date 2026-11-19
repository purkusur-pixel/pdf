#!/usr/bin/env python3
"""
src/index.html  ->  html/  (Docker/Caddy ile yayınlanan, PWA'lı site)

Kullanım / Usage:
    npm ci
    pip install -r requirements.txt
    python3 tools/build.py

- CDN adreslerini yerel libs/ dosyalarıyla değiştirir (dış bağlantı yok).
- Google Fonts yerine yerel yazı tiplerini kullanır (KVKK/GDPR dostu).
- PWA: manifest, service worker (çevrimdışı), simgeler, kurulum düğmesi.
- libs/*.js için .br/.gz dosyalarını önceden üretir (sunucu CPU'su harcamaz).
"""
import os, re, shutil, json, hashlib, gzip, glob
import brotli
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'src', 'index.html')
NM = os.path.join(ROOT, 'node_modules') + '/'
H = os.path.join(ROOT, 'html')

shutil.rmtree(H, ignore_errors=True)
for d in ('libs', 'fonts', 'icons'):
    os.makedirs(f'{H}/{d}')

# ---------- kütüphaneler / libraries ----------
LIBS = {
    'pdfjs-dist/build/pdf.min.js': 'pdf.min.js',
    'pdfjs-dist/build/pdf.worker.min.js': 'pdf.worker.min.js',
    'pdf-lib/dist/pdf-lib.min.js': 'pdf-lib.min.js',
    'jszip/dist/jszip.min.js': 'jszip.min.js',
    'docx/build/index.umd.js': 'docx.umd.js',
    'mammoth/mammoth.browser.min.js': 'mammoth.browser.min.js',
    'html2pdf.js/dist/html2pdf.bundle.min.js': 'html2pdf.bundle.min.js',
    'pptxgenjs/dist/pptxgen.bundle.js': 'pptxgen.bundle.js',
    'xlsx/dist/xlsx.full.min.js': 'xlsx.full.min.js',
    'jspdf/dist/jspdf.umd.min.js': 'jspdf.umd.min.js',
}
for s, d in LIBS.items():
    shutil.copy(NM + s, f'{H}/libs/{d}')

# ---------- yazı tipleri / fonts ----------
css = []
for fam, pkg, weights in (('Inter', 'inter', (400, 500, 600, 700)), ('Dancing Script', 'dancing-script', (600,))):
    for w in weights:
        src = open(f'{NM}@fontsource/{pkg}/{w}.css').read()
        for subset, face in re.findall(r'/\*\s*([\w-]+)\s*\*/\s*(@font-face\s*{[^}]*})', src):
            if subset not in ('latin', 'latin-ext'):
                continue
            fn = f'{pkg}-{subset}-{w}-normal.woff2'
            shutil.copy(f'{NM}@fontsource/{pkg}/files/{fn}', f'{H}/fonts/{fn}')
            rng = re.search(r'unicode-range:\s*([^;]+);', face).group(1)
            css.append(f"@font-face{{font-family:'{fam}';font-style:normal;font-display:swap;font-weight:{w};"
                       f"src:url(./{fn}) format('woff2');unicode-range:{rng};}}")
open(f'{H}/fonts/fonts.css', 'w').write('\n'.join(css) + '\n')

# ---------- simgeler / icons ----------
FONT = (glob.glob('/usr/share/fonts/**/DejaVuSans-Bold.ttf', recursive=True) or [None])[0]
RED = (214, 69, 61)
def icon(size, maskable=False, radius=True):
    im = Image.new('RGBA', (size, size), RED + (255,) if maskable else (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    if not maskable:
        dr.rounded_rectangle([0, 0, size - 1, size - 1], radius=size * 0.22 if radius else 0, fill=RED)
    scale = 0.62 if maskable else 0.8
    pw, ph = size * 0.42 * scale, size * 0.52 * scale
    cx, cy = size / 2, size * 0.47
    x0, y0 = cx - pw / 2, cy - ph / 2
    fold = pw * 0.3
    dr.polygon([(x0, y0), (x0 + pw - fold, y0), (x0 + pw, y0 + fold), (x0 + pw, y0 + ph), (x0, y0 + ph)], fill='white')
    dr.polygon([(x0 + pw - fold, y0), (x0 + pw - fold, y0 + fold), (x0 + pw, y0 + fold)], fill=(240, 180, 175))
    for i in range(3):
        ly = y0 + ph * (0.42 + i * 0.17)
        dr.rounded_rectangle([x0 + pw * 0.16, ly, x0 + pw * (0.84 if i < 2 else 0.6), ly + ph * 0.07], radius=ph * 0.035, fill=RED)
    f = ImageFont.truetype(FONT, int(size * 0.15 * scale / 0.8)) if FONT else ImageFont.load_default()
    tw = dr.textlength('PDF', font=f)
    dr.text((cx - tw / 2, y0 + ph + size * 0.035 * scale / 0.8), 'PDF', font=f, fill='white')
    return im

icon(192).save(f'{H}/icons/icon-192.png')
icon(512).save(f'{H}/icons/icon-512.png')
icon(512, maskable=True).save(f'{H}/icons/icon-maskable-512.png')
icon(180, radius=False).convert('RGB').save(f'{H}/icons/apple-touch-icon.png')
icon(32).save(f'{H}/icons/favicon-32.png')
icon(48).save(f'{H}/favicon.ico', sizes=[(16, 16), (32, 32), (48, 48)])

# ---------- manifest ----------
manifest = {
    'name': 'PDF Araçları · PDF Tools',
    'short_name': 'PDF Araçları',
    'description': 'PDF birleştir, böl, dönüştür, imzala ve sesli dinle. Merge, split, convert, sign and read PDFs aloud. Dosyalar cihazdan çıkmaz / files never leave your device.',
    'lang': 'tr', 'dir': 'ltr',
    'id': '/', 'start_url': '/', 'scope': '/',
    'display': 'standalone', 'display_override': ['standalone', 'minimal-ui'],
    'orientation': 'any',
    'background_color': '#f5f5f2', 'theme_color': '#d6453d',
    'categories': ['productivity', 'utilities'],
    'icons': [
        {'src': '/icons/icon-192.png', 'sizes': '192x192', 'type': 'image/png', 'purpose': 'any'},
        {'src': '/icons/icon-512.png', 'sizes': '512x512', 'type': 'image/png', 'purpose': 'any'},
        {'src': '/icons/icon-maskable-512.png', 'sizes': '512x512', 'type': 'image/png', 'purpose': 'maskable'},
    ],
    'shortcuts': [
        {'name': 'Sesli Oku / Read Aloud', 'url': '/#read', 'icons': [{'src': '/icons/icon-192.png', 'sizes': '192x192'}]},
        {'name': 'Birleştir / Merge', 'url': '/#merge', 'icons': [{'src': '/icons/icon-192.png', 'sizes': '192x192'}]},
        {'name': 'Böl / Split', 'url': '/#split', 'icons': [{'src': '/icons/icon-192.png', 'sizes': '192x192'}]},
        {'name': 'Sıkıştır / Compress', 'url': '/#compress', 'icons': [{'src': '/icons/icon-192.png', 'sizes': '192x192'}]},
    ],
    'file_handlers': [{'action': '/', 'accept': {'application/pdf': ['.pdf']}}],
    'launch_handler': {'client_mode': 'focus-existing'},
}
open(f'{H}/manifest.webmanifest', 'w').write(json.dumps(manifest, ensure_ascii=False, indent=2))

# ---------- index.html ----------
s = open(SRC).read()
s = re.sub(r"'https://cdn[^']*/docx@[\d.]+/build/index\.umd\.js'", "'libs/docx.umd.js'", s)
s = re.sub(r"'https://(?:cdnjs\.cloudflare\.com|cdn\.jsdelivr\.net)/[^']*/([^'/]+\.js)'", r"'libs/\1'", s)
s = re.sub(r'<link rel="preconnect"[^>]*>\s*<link href="https://fonts\.googleapis\.com[^>]*>',
           '<link rel="stylesheet" href="fonts/fonts.css">', s)
assert 'googleapis' not in s and 'https://cdn' not in s, 'dış bağlantı kaldı / external URL left'

def sub(a, b):
    global s
    assert a in s, 'bulunamadı / not found: ' + a[:80]
    s = s.replace(a, b, 1)

sub('<title>PDF Araçları</title>', '''<title>PDF Araçları</title>
<meta name="description" content="PDF birleştir, böl, dönüştür, imzala ve sesli dinle. Dosyalar cihazdan çıkmaz.">
<meta name="theme-color" content="#d6453d">
<link rel="manifest" href="/manifest.webmanifest">
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" type="image/png" sizes="32x32" href="/icons/favicon-32.png">
<link rel="apple-touch-icon" href="/icons/apple-touch-icon.png">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="PDF Araçları">
<meta name="apple-mobile-web-app-status-bar-style" content="default">''')
# Kurulum düğmesi, iOS ipucu, çevrimdışı notu
sub('<span id="hdrRight">', '<span id="hdrRight"><button id="installBtn" class="btn hidden" style="padding:6px 10px;font-size:12px" data-i18n>⬇ Uygulamayı yükle</button>')
sub('</header>', '''</header>
    <div id="iosHint" class="warn hidden" style="margin:0 0 14px;display:flex;gap:8px;align-items:flex-start"><span style="flex:1" data-i18n-html>iPhone/iPad'e kurmak için: Safari'de <b>Paylaş</b> düğmesine, ardından <b>Ana Ekrana Ekle</b>'ye dokun.</span><button class="mini" onclick="this.parentNode.remove();try{localStorage.setItem('iosHintSeen',1)}catch(e){}">✕</button></div>
    <div id="offlineNote" class="hint hidden" style="margin:-8px 0 12px" data-i18n>📴 Çevrimdışısın — daha önce açılmış araçlar çalışmaya devam eder.</div>''')
# Telefonda Paylaş düğmesi (Web Share API)
sub("    box.append(el('div', { class: 'dl' }, el('span', { class: 'n' }, o.name), el('span', { class: 'sz' }, fmtSize(o.blob.size)), b));",
"""    let sh = null;
    try {
      const f = new File([o.blob], o.name, { type: o.blob.type || 'application/octet-stream' });
      if (d === null && navigator.canShare && navigator.canShare({ files: [f] }))
        sh = el('button', { class: 'btn', title: __('Paylaş veya Dosyalar\\'a kaydet'), onclick: () => navigator.share({ files: [f], title: o.name }).catch(() => {}) }, __('Paylaş'));
    } catch(e){}
    box.append(el('div', { class: 'dl' }, el('span', { class: 'n' }, o.name), el('span', { class: 'sz' }, fmtSize(o.blob.size)), sh, b));""")
# Bilgisayarda "Birlikte aç → PDF Araçları"
sub('route();\n})();', """route();
if ('launchQueue' in window) launchQueue.setConsumer(async params => {
  if (!params.files || !params.files.length) return;
  const fs = await Promise.all(params.files.map(h => h.getFile()));
  openTool(fs.length > 1 ? 'merge' : 'read'); addFiles(fs);
});
})();""")
sub('</body>', '''<script>
(() => {
  if ('serviceWorker' in navigator) window.addEventListener('load', () => navigator.serviceWorker.register('/sw.js').catch(() => {}));
  let deferred = null; const btn = document.getElementById('installBtn');
  window.addEventListener('beforeinstallprompt', e => { e.preventDefault(); deferred = e; btn.classList.remove('hidden'); });
  btn.addEventListener('click', async () => { if (!deferred) return; deferred.prompt(); await deferred.userChoice.catch(() => {}); deferred = null; btn.classList.add('hidden'); });
  window.addEventListener('appinstalled', () => btn.classList.add('hidden'));
  const standalone = matchMedia('(display-mode: standalone)').matches || navigator.standalone;
  const ios = /iphone|ipad|ipod/i.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  let seen = false; try { seen = !!localStorage.getItem('iosHintSeen'); } catch(e){}
  if (ios && !standalone && !seen) document.getElementById('iosHint').classList.remove('hidden');
  const net = () => document.getElementById('offlineNote').classList.toggle('hidden', navigator.onLine);
  addEventListener('online', net); addEventListener('offline', net); net();
})();
</script>
</body>''')
open(f'{H}/index.html', 'w').write(s)

# ---------- service worker ----------
assets = ['/', '/index.html', '/manifest.webmanifest', '/favicon.ico']
for d in ('libs', 'fonts', 'icons'):
    assets += ['/' + d + '/' + f for f in sorted(os.listdir(f'{H}/{d}'))]
hsh = hashlib.sha256()
for a in assets[1:]:
    hsh.update(open(H + a, 'rb').read())
ver = hsh.hexdigest()[:10]
open(f'{H}/sw.js', 'w').write(f"""// PDF Araçları service worker — {ver} (tools/build.py)
const CACHE = 'pdf-araclari-{ver}';
const ASSETS = {json.dumps(assets, indent=2)};

self.addEventListener('install', e => {{
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting()));
}});
self.addEventListener('activate', e => {{
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k.startsWith('pdf-araclari-') && k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
}});
self.addEventListener('fetch', e => {{
  const req = e.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== location.origin) return;
  if (req.mode === 'navigate') {{
    // sayfa: önce ağ, çevrimdışıysa önbellek / page: network first, cache when offline
    e.respondWith(fetch(req).then(r => {{
      if (r.ok) {{ const copy = r.clone(); caches.open(CACHE).then(c => c.put('/index.html', copy)); }}
      return r;
    }}).catch(() => caches.match('/index.html')));
    return;
  }}
  // kütüphane, yazı tipi, simge: önce önbellek / assets: cache first
  e.respondWith(caches.match(req, {{ ignoreSearch: true }}).then(hit => hit || fetch(req)));
}});
""")

# ---------- önceden sıkıştırma / precompression ----------
for f in glob.glob(f'{H}/libs/*.js'):
    data = open(f, 'rb').read()
    open(f + '.br', 'wb').write(brotli.compress(data, quality=11))
    open(f + '.gz', 'wb').write(gzip.compress(data, 9, mtime=0))

print('html/ hazır / ready — service worker', ver, '—', len(assets), 'dosya / files')
