.PHONY: install uninstall dev logs restart

PLUGIN_ID := net.fidelramos.kde.veniceai

ICON_NAME := venice-applet
ICON_SRC  := package/contents/images/$(ICON_NAME).png
ICON_DIR  := $(HOME)/.local/share/icons/hicolor/256x256/apps
ICON_DEST := $(ICON_DIR)/$(ICON_NAME).png

install:
	kpackagetool6 --type Plasma/Applet --upgrade package/ || \
	kpackagetool6 --type Plasma/Applet --install package/
	mkdir -p $(ICON_DIR)
	cp $(ICON_SRC) $(ICON_DEST)

uninstall:
	kpackagetool6 --type Plasma/Applet --remove $(PLUGIN_ID)
	rm -f $(ICON_DEST)

dev:
	plasmoidviewer --applet package/

logs:
	journalctl -f -o cat /usr/bin/plasmashell

restart:
	kquitapp6 plasmashell ; kstart plasmashell
