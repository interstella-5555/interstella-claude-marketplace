---
name: screenshot
description: Use when user wants to take a screenshot, capture a webpage, convert HTML to PNG, make an ss, grab a screena, zrzut ekranu, or capture any URL or local HTML file as an image. Also use when generating visual mockups that need to be saved as images.
---

# Screenshot — capture-website-cli

Capture any URL or local HTML file as a PNG/JPEG/WebP image.

**Command:** `npx -y capture-website-cli@latest`

## Quick Reference

| Flag | Description | Default |
|------|-------------|---------|
| `--output` | Output file path (stdout if omitted) | — |
| `--width` | Viewport width in px | 1280 |
| `--height` | Viewport height in px | 800 |
| `--scale-factor` | Retina multiplier | 2 |
| `--full-page` | Capture entire scrollable page | off |
| `--delay` | Wait N seconds after load | 0 |
| `--type` | Format: png, jpeg, webp | png |
| `--quality` | 0-1 for jpeg/webp | 1 |
| `--element` | Capture specific CSS selector only | — |
| `--remove-elements` | Remove elements before capture | — |
| `--hide-elements` | Hide elements (keeps layout) | — |
| `--disable-animations` | Freeze CSS animations | off |
| `--dark-mode` | Emulate prefers-color-scheme: dark | off |
| `--emulate-device` | Device emulation (e.g. "iPhone X") | — |
| `--wait-for-element` | Wait for selector to appear | — |
| `--click-element` | Click element before capture | — |
| `--style` | Inject CSS | — |
| `--no-default-background` | Transparent background | off |
| `--overwrite` | Overwrite existing file | off |

## Examples

**Basic URL screenshot:**
```bash
npx -y capture-website-cli@latest "https://example.com" \
  --output screenshot.png
```

**Local HTML file:**
```bash
npx -y capture-website-cli@latest docs/mockups/my-page.html \
  --output docs/mockups/my-page.png
```

**Retina, full page, no animations:**
```bash
npx -y capture-website-cli@latest "http://localhost:3000" \
  --width 1400 --scale-factor 2 --full-page \
  --disable-animations --delay 2 \
  --output screenshot.png
```

**Capture specific element:**
```bash
npx -y capture-website-cli@latest "http://localhost:3000" \
  --element ".card-container" \
  --output card.png
```

**Remove nav/footer before capture:**
```bash
npx -y capture-website-cli@latest "http://localhost:3000" \
  --remove-elements ".nav" --remove-elements "footer" \
  --full-page --output clean.png
```

**Mobile device emulation:**
```bash
npx -y capture-website-cli@latest "https://example.com" \
  --emulate-device "iPhone X" \
  --output mobile.png
```

**Inject custom CSS before capture:**
```bash
npx -y capture-website-cli@latest "http://localhost:3000" \
  --style "body { background: white; } .debug { display: none; }" \
  --output styled.png
```

## Common Mistakes

- **Missing `--delay`** — SPAs need time to render. Use `--delay 2` or `--wait-for-element ".content"`.
- **Blurry images** — Default `--scale-factor` is 2 (retina). Set to 1 for 1:1 pixel mapping.
- **File not overwritten** — Add `--overwrite` when re-capturing to same path.
- **Animations mid-frame** — Use `--disable-animations` for consistent captures.
