# User guide

[Türkçe](../tr/kullanim.md) · **English** · [← README](../../README.md)

## Basics

1. Pick a tool on the home screen.
2. Tap **Choose file** or drag the file onto the box.
3. Adjust the options, if any.
4. Press the big button at the bottom (e.g. **Merge PDF →**).
5. Save the result with **Download**. On phones, **Share** sends it to Files, WhatsApp, e-mail, etc.

Tools that produce several files (Split, PDF → JPG) also give you a **.zip** containing all of them.

- **Language:** the **TR / EN** switch at the top right. Your choice is remembered.
- **Privacy:** files are never uploaded anywhere. Close the page when you're done.
- **Page ranges:** separate with commas, use a dash for ranges. Examples: `1-3, 5, 8-` (8 to the end), `2`, `-4` (start to 4).

---

## 🔊 Read PDF Aloud

Reads the PDF's text with your device's voice.

- **Tap a sentence:** reading starts from that sentence.
- **Read from here ▶:** starts at the top of that page.
- **Bottom bar:** ⏮ previous sentence · ▶/❚❚ play/pause · ⏭ next sentence · ■ stop.
- **Voice / Speed / Pitch:** voices marked ⭐ sound more natural. Your choice is remembered.
- **Keyboard:** Space plays/pauses, ← → move between sentences.

**Most natural voices:**

| Device | What to do |
|---|---|
| Computer | Open in **Microsoft Edge** → pick an "Online (Natural)" voice (needs internet) |
| iPhone/iPad | Settings → Accessibility → Spoken Content → Voices → your language → download an "Enhanced/Premium" voice |
| Android | Speech Services by Google → Settings → Install voice data → your language |

Scanned (image-only) PDFs contain no text, so there's nothing to read.

---

## Edit

### Merge PDF
Combines several PDFs into one, in order. Use ↑ ↓ to reorder and ✕ to remove. You can add the same file more than once.

### Split PDF
- **Every page as a separate file:** a 10-page PDF becomes 10 files.
- **Ranges I specify:** `1-3, 4-6, 7-` → 3 files.
- **Every N pages:** N=2 → 1-2, 3-4, 5-6…

### Extract Pages
Creates a new PDF from only the pages you list. Example: `1, 3-5` → a 4-page PDF.

### Delete Pages
Removes the pages you list. Example: `2, 5-7`.

### Organize Pages
Shows a thumbnail for every page. Buttons under each page:
◀ ▶ move · ⟲ ⟳ rotate · ✕ delete (↺ undo). Then press **Organize Pages →**.

### Rotate PDF
Turns the chosen pages (or all pages if left empty) 90° right, 90° left or 180°. Content is not altered.

### Compress PDF
Shrinks the file by turning pages into JPEG images.
- **Strong:** smallest file, lower quality.
- **Recommended:** balanced.
- **Light:** best quality.

Very effective for scanned or photo-heavy PDFs. Text-heavy PDFs may get bigger; the app warns you so you can keep the original.
⚠ Text in the result can't be selected or searched.

### Crop PDF
Trims the top/bottom/left/right of every page by the given millimetres (shrinks the visible area).

---

## Convert from PDF

### PDF → JPG / PNG
Turns each page into an image.
- **Resolution:** 72 DPI (screen), 150 DPI (normal), 300 DPI (print).
- **Format:** JPG is smaller, PNG is lossless.

### PDF → Word
Moves the text and paragraphs into an editable `.docx` file. Each PDF page starts on a new Word page.
Complex layouts, tables and images are not transferred.

### PDF → PowerPoint
Each page becomes a slide containing an exact image of the page. Slide size follows the first page.

### PDF → Text
Gives you all the text as a `.txt` file with page headers.

---

## Convert to PDF

### JPG / PNG → PDF
Turns several images (JPG, PNG, WEBP, GIF…) into one PDF, in order.
- **Page size:** A4, Letter, or same as the image.
- **Orientation:** automatic (landscape image → landscape page), portrait or landscape.
- **Margin:** none, small or large.

### Word → PDF
Converts a `.docx` document to PDF: headings, lists, tables and images are kept.
Fonts and page breaks may differ slightly from Word. Save legacy `.doc` files as `.docx` in Word first.

### Excel → PDF
Turns every sheet of an `.xlsx`, `.xls`, `.ods` or `.csv` file into a table in the PDF. Choose **Landscape** for wide sheets.
Colors, charts and cell formatting are not transferred.

---

## Sign & stamp

### Sign PDF
1. Choose the PDF.
2. Draw your signature with a finger or mouse on the **Draw** tab (color selectable), or type your name on the **Type** tab (shown in a handwriting style).
3. Choose the **Page** (default: the last page).
4. **Tap** the preview where the signature should go. Use **Signature width** to resize it.
5. Optionally tick **Add to all pages**.
6. Press **Sign PDF →**.

> This is a visual signature (an image of a handwritten signature), not a qualified electronic/digital signature.

### Add Watermark
Stamps text on every page (e.g. CONFIDENTIAL, DRAFT, SAMPLE).
Color, opacity, size and angle (diagonal/horizontal) are adjustable. **Tile across the page** repeats it. Any characters are supported.

### Page Numbers
- **Position:** top or bottom, left, center or right.
- **Format:** `1`, `1 / 10`, `Page 1`, `Page 1 / 10`.
- **First number** and **start numbering on page** (e.g. 2 to skip a cover) are adjustable.

---

## Security

### Protect PDF
Adds an opening password; anyone opening the file must enter it.
⚠ Pages are converted to high-resolution images, so text can't be selected. A forgotten password can't be recovered.

### Unlock
Creates a password-free copy of a PDF whose password you **know**. Pages are converted to images.

### Repair PDF
Rewrites damaged or badly saved PDFs. If the structure can't be repaired, pages are redrawn to recover them.

---

## FAQ

**Are my files sent to the server?**
No. Everything runs in your browser with JavaScript. Try it: disconnect from the internet and the tools keep working.

**Is there a file size limit?**
Not on the server side. The limit is your device's memory. On phones, some operations (compress, PDF → image) can be slow on PDFs with hundreds of pages.

**Which browsers are supported?**
Recent Chrome, Edge, Firefox and Safari. For read-aloud, Edge (desktop) and Safari (iPhone) give the best voices.

**Does it work offline?**
Yes, once you've opened the site or app with an internet connection at least once.
