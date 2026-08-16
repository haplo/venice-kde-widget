# KDE Store Listing — Venice.ai Balance

Paste-ready content for submitting the widget to the KDE Store.
Submission is manual via the web UI (there is no publish API):
<https://www.opendesktop.org/add> (requires an opendesktop.org account).

## Product fields

- **Title:** Venice.ai Balance
- **Category:** Linux/Unix Desktops → Desktop Extensions → KDE Plasma Extensions → Plasma 6 Extensions → Plasma 6 Applets
- **License:** MIT
- **Source code:** <https://github.com/haplo/venice-kde-widget>
- **Tags:** `plasma##majorversion=6, plasma, kde, widget, venice.ai, ai, api, balance, monitor`

> The `plasma##majorversion=6` tag is what makes the product visible in
> Plasma 6's "Get New Widgets" dialog — don't skip it.

## Description

Paste this into the description field:

```markdown
Displays your [Venice.ai](https://venice.ai/) API balance on your desktop or panel.

**Features**

- Compact panel display with configurable text: percentage, available amount, both, or icon only
- Color-coded status at a glance
- Shows DIEM when your account has a DIEM allocation, USD otherwise
- Popup with configurable quick-link buttons (Chat, Studio, Feed, API settings, Pricing, Token)
- Transparent background option for use as a desktop widget over your wallpaper
- API token stored securely in KWallet via the freedesktop Secret Service — never in plaintext config
- Balance refreshed automatically every 30 seconds

**Requirements**

- KDE Plasma 6
- `secret-tool` (provided by `libsecret` or `libsecret-tools` on most distributions) — used to store the API token in KWallet

**Setup**

1. Create an API key at <https://venice.ai/settings/api>
2. Add the widget to your panel or desktop
3. Open the widget's settings and paste your API key

Source code: <https://github.com/haplo/venice-kde-widget>

Unofficial community widget — not affiliated with Venice.ai.
```

## File

- Upload `net.fidelramos.kde.veniceai-1.0.plasmoid` (build with `make package`)
- Version: `1.0`

## Screenshots

Upload in this order (the first image becomes the listing thumbnail):

1. `screenshot_2.webp` — full widget popup with quick-link buttons (best hero shot)
2. `screenshot_1.webp` — compact panel display
3. `screenshot_3.webp` — transparent background on desktop

## Changelog

```
1.0 — Initial release
```

## After publishing

- The product goes live immediately. Its URL will be
  `https://store.kde.org/p/<PRODUCT_ID>` — paste it into `README.md`
  (search for `PRODUCT_ID`).
- "Get New Widgets" visibility can lag behind publication (store → Plasma
  sync delay). If the widget doesn't appear there after ~24 h, post on
  <https://forum.opendesktop.org> — staff can bump it.
- The store runs automated keyword moderation; if the page shows
  "reported … will be validated by our moderators", no action is needed.
- **Updates:** bump `KPlugin.Version` in `package/metadata.json`, run
  `make package`, then edit the product and upload the new `.plasmoid`
  file with the new version number plus a changelog entry.
