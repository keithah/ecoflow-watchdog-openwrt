include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for EcoFlow Watchdog
LUCI_DEPENDS:=+luci-compat +ecoflow-watchdog
LUCI_PKGARCH:=all
PKG_LICENSE:=MIT

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-app-ecoflow-watchdog/postinst
#!/bin/sh
[ -x /etc/init.d/ucitrack ] && /etc/init.d/ucitrack restart >/dev/null 2>&1 || true
exit 0
endef

$(eval $(call BuildPackage,luci-app-ecoflow-watchdog))
