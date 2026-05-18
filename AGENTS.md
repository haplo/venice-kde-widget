# AGENTS.md

## Project Overview

A KDE Plasma 6 widget (plasmoid) that displays Venice.ai API credits and usage information on the desktop or panel.

## Tech Stack

- **QML** (Qt 6) with **Plasma Framework** for the UI
- **JavaScript** (QML-integrated) for HTTP API calls to Venice.ai
- **KDE Frameworks 6**: PlasmaCore, PlasmaExtras, Kirigami

## Project Structure

```
package/
  contents/
    ui/
      main.qml          # Main widget UI
      config/
        ConfigGeneral.qml     # General settings page (token management)
        ConfigAppearance.qml  # Appearance settings page (background, etc.)
        ConfigLinks.qml       # Links settings page (quick link buttons)
    config/
      config.qml            # ConfigModel (declares config categories)
      main.xml              # KConfig schema (appearance prefs)
    code/
      api.js             # Venice.ai API client
      secret.js          # KWallet helper wrapper (drives kwallet.sh)
      kwallet.sh         # secret-tool helper for KWallet load/store/clear
  metadata.json          # Widget metadata (Plasma 6 format)
```

## Runtime dependencies

- `secret-tool` (libsecret). On a KDE Plasma session the freedesktop Secret
  Service is provided by `kwalletd6`, so secrets land in KWallet.

## Commands

```bash
make install    # Install widget locally
make uninstall  # Remove installed widget
make dev        # Test in standalone viewer (plasmoidviewer)
make logs       # View Plasma shell logs (journalctl)
```

## Conventions

- Use Plasma 6 `metadata.json` format (not the older `metadata.desktop`)
- Follow KDE HIG for spacing and sizing
- API token is stored in KWallet via `secret-tool` (the freedesktop Secret Service), driven from QML through a `P5Support.DataSource` executable helper (`code/kwallet.sh`, wrapped by `code/secret.js`). Never persist it in `Plasmoid.configuration` or any other plaintext store.
- All network requests happen in QML JavaScript context via `XMLHttpRequest`
- Use `Kirigami.Icon`, `Kirigami.Heading`, `PlasmaCore.Svg` for consistent theming
- Widget size hints: `compactRepresentation` for panel, `fullRepresentation` for popup
- Never log or expose the API key
