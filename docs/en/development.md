# Developer guide

[Türkçe](../tr/gelistirme.md) · **English** · [← README](../../README.md)

## Architecture

The app is **a single HTML file** (`src/index.html`) containing the CSS, the UI and the JavaScript for every tool.
There is no server-side code; Caddy only serves the `html/` folder as static files.

| Layer | Technology |
|---|---|
| UI | Plain HTML + CSS + JavaScript (no framework) |
| PDF reading / rendering / text | PDF.js |
| PDF creation / editing | pdf-lib |
| Word / PowerPoint / Excel | docx, mammoth, PptxGenJS, SheetJS, html2pdf.js |
| Encryption | jsPDF |
| Read aloud | Web Speech API (`speechSynthesis`) |
| Offline / install | Service Worker + Web App Manifest (PWA) |
| Server | Caddy 2 (Docker), automatic Let's Encrypt |

Libraries are loaded **on demand**: if a user only opens Merge, only pdf-lib is downloaded.

### Code layout (`src/index.html`)

- `CDN` — library URLs. `tools/build.py` rewrites them to local `libs/` paths.
- `need('pdflib', 'jszip')` — loads libraries in order.
- `TOOLS` — the list of all tools. Each tool is an object:
  ```js
  { id: 'merge', group: 'Düzenle', icon: '⧉', color: '#d6453d',
    title: 'PDF Birleştir', desc: '…',
    accept: PDF_ACCEPT, multiple: true, min: 2, sortable: true,
    libs: ['pdflib'],
    options: () => [ opt.sel(…), opt.text(…) ],   // optional settings
    note: '…',                                      // optional warning
    async onFiles(box){ … },                        // optional: custom UI after a file is chosen
    async run(){ return [{ name: 'x.pdf', blob }]; } }
  ```
- `setupReader`, `setupSign` — custom UIs of the Read Aloud and Sign tools.
- A URL hash such as `#merge` opens that tool directly.

### Adding a tool

1. Add an object like the one above to `TOOLS`.
2. Write every user-visible string as `__('Turkish text')` or `` __t`Turkish ${x} text` ``.
3. Add the English translation to the `EN` dictionary (`{0}`, `{1}`… mark the variables):
   ```js
   'Türkçe {0} metin': 'English {0} text',
   ```
4. Rebuild `html/` with `python3 tools/build.py`.

## Internationalisation (i18n)

- The source language is Turkish; translations live in the `EN` object inside `src/index.html`.
- `__('text')` returns the translation; `` __t`Sayfa ${n}` `` templates are looked up with the key `'Sayfa {0}'`.
- Static HTML elements are translated via the `data-i18n` (plain text) or `data-i18n-html` (HTML) attribute.
- The chosen language is stored in `localStorage` as `pdfaraclari.lang`; on first visit the browser language decides.
- To add a language: add its code to `LANGS`, create a dictionary like `EN`, extend `__` accordingly and add a button to `#langSw` in the header.

## Building (`src` → `html`)

```bash
npm ci                              # libraries at the versions pinned in package.json
pip install -r requirements.txt     # Pillow (icons) and brotli (compression)
python3 tools/build.py
```

`tools/build.py`:

1. Copies the libraries from `node_modules` to `html/libs/` and replaces CDN URLs with local ones.
2. Bundles the Inter and Dancing Script fonts locally (no requests to Google).
3. Generates the PWA icons, `manifest.webmanifest` and `sw.js` (offline cache).
4. Adds the install button, the iOS hint, the offline note and the **Share** button on phones.
5. Pre-generates `.br` and `.gz` files for `libs/*.js`.

The service worker version is a hash of the files, so users get new versions automatically.

### Trying it locally

```bash
cd html && python3 -m http.server 8000      # http://localhost:8000
```

or with Docker:

```bash
DOMAIN=:80 ACME_EMAIL=test@example.com HTTP_PORT=8080 HTTPS_PORT=8443 docker compose up --build   # http://localhost:8080
```

`src/index.html` also works on its own without building (it loads the libraries from CDNs); just open it in a browser.

## Pushing to GitHub (the "send button")

`github-gonder.sh` ("send to GitHub") in the repository root pushes everything with one command:

```bash
bash github-gonder.sh                     # first push or update
bash github-gonder.sh "Added a new tool"  # with your own commit message
FORCE=1 bash github-gonder.sh             # overwrite whatever is on GitHub
```

The script creates a git repository if needed → asks for your name/e-mail if not configured → sets `origin`
to `https://github.com/purkusur-pixel/pdf.git` → commits all changes → pushes to `main`.
If GitHub has commits that aren't here (e.g. a README created on the website) it offers to merge them.

**Authentication:** GitHub no longer accepts passwords. Use one of these:

- **Easiest:** install the [GitHub CLI](https://cli.github.com) and run `gh auth login` once.
- **Token:** GitHub → Settings → Developer settings → Personal access tokens → create a *fine-grained token*
  (only the `purkusur-pixel/pdf` repository, *Contents: Read and write*). Paste it when git asks for a password.
- **SSH:** `REPO_URL=git@github.com:purkusur-pixel/pdf.git bash github-gonder.sh`

On Windows, run the script in **Git Bash**.

### Repository description and topics

On GitHub, click the ⚙ (About) icon at the top right of the repository and enter:

- **Description:** `Tarayıcıda çalışan, gizlilik dostu PDF araçları (PWA) — birleştir, böl, dönüştür, imzala, sesli oku · Privacy-friendly in-browser PDF toolkit (PWA)`
- **Website:** `https://pdf.sporyazilimlari.com.tr`
- **Topics:** `pdf` `pwa` `pdf-tools` `pdf-merge` `pdf-split` `text-to-speech` `docker` `caddy` `turkish` `privacy`

or with the GitHub CLI:

```bash
gh repo edit purkusur-pixel/pdf \
  --description "Tarayıcıda çalışan, gizlilik dostu PDF araçları (PWA) · Privacy-friendly in-browser PDF toolkit" \
  --homepage https://pdf.sporyazilimlari.com.tr \
  --add-topic pdf,pwa,pdf-tools,pdf-merge,pdf-split,text-to-speech,docker,caddy,turkish,privacy
```

## Security notes

- The `Caddyfile` sends a strict Content-Security-Policy: the page can only load resources from its own origin.
  (`'unsafe-inline'` and `'unsafe-eval'` are required by the single-file design and some libraries.)
- The container runs with a read-only filesystem, `no-new-privileges` and resource limits.
- User files never reach the server, so there is no personal data stored there (access logs are off too).

## Contributing

Open an *Issue* on GitHub for bugs and ideas; send a *Pull Request* for changes.
Please remember to add English translations for new strings to the `EN` dictionary.
