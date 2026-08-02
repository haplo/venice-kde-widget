.PHONY: install uninstall package dev logs restart

PLUGIN_ID := net.fidelramos.kde.veniceai
VERSION   := $(shell sed -n 's/.*"Version": *"\([^"]*\)".*/\1/p' package/metadata.json)
PLASMOID  := $(PLUGIN_ID)-$(VERSION).plasmoid

install:
	kpackagetool6 --type Plasma/Applet --upgrade package/ || \
	kpackagetool6 --type Plasma/Applet --install package/

package:
	rm -f $(PLASMOID)
	cd package && zip -r ../$(PLASMOID) .
	@echo "Created $(PLASMOID)"

uninstall:
	kpackagetool6 --type Plasma/Applet --remove $(PLUGIN_ID)

dev:
	plasmoidviewer --applet package/

logs:
	journalctl -f -o cat /usr/bin/plasmashell

restart:
	kquitapp6 plasmashell ; kstart plasmashell
