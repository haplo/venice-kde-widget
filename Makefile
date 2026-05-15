.PHONY: install uninstall dev logs restart

PLUGIN_ID := com.venice.widget.credits

install:
	kpackagetool6 --type Plasma/Applet --upgrade package/ || \
	kpackagetool6 --type Plasma/Applet --install package/

uninstall:
	kpackagetool6 --type Plasma/Applet --remove $(PLUGIN_ID)

dev:
	plasmoidviewer --applet package/

logs:
	journalctl -f -o cat /usr/bin/plasmashell

restart:
	kquitapp6 plasmashell ; kstart plasmashell
