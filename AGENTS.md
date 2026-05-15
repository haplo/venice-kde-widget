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
      config.qml         # Configuration dialog
      ConfigGeneral.qml  # General settings tab
    code/
      api.js             # Venice.ai API client
  metadata.json          # Widget metadata (Plasma 6 format)
```

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
- API key/token is stored via `PlasmaCore.DataSource` or `plasmoid.configuration`, stored securely using KWallet
- All network requests happen in QML JavaScript context via `XMLHttpRequest`
- Use `Kirigami.Icon`, `Kirigami.Heading`, `PlasmaCore.Svg` for consistent theming
- Widget size hints: `compactRepresentation` for panel, `fullRepresentation` for popup
- Never log or expose the API key
