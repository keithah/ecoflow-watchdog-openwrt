include $(TOPDIR)/rules.mk

PKG_NAME:=ecoflow-watchdog
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Keith <keith@example.com>

include $(INCLUDE_DIR)/package.mk

FEEDSRC:=$(TOPDIR)/feeds/ecoflow

define Package/ecoflow-watchdog
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=EcoFlow power-off watchdog
  DEPENDS:=+curl +jq +ca-bundle
endef

define Package/ecoflow-watchdog/description
Cron/daemon watchdog that disables EcoFlow DC (or device standby) when a target Wi-Fi client disappears or input power stops.
endef

define Build/Compile
endef

define Package/ecoflow-watchdog/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(FEEDSRC)/usr/sbin/ecoflow_watchdogd $(1)/usr/sbin/

	$(INSTALL_DIR) $(1)/usr/lib/ecoflow_watchdog
	$(INSTALL_BIN) $(FEEDSRC)/usr/lib/ecoflow_watchdog/ecoflow_api.sh $(1)/usr/lib/ecoflow_watchdog/
	$(INSTALL_BIN) $(FEEDSRC)/usr/lib/ecoflow_watchdog/notify_sample.sh $(1)/usr/lib/ecoflow_watchdog/

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(FEEDSRC)/etc/config/ecoflow_watchdog $(1)/etc/config/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(FEEDSRC)/etc/init.d/ecoflow_watchdog $(1)/etc/init.d/

	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_CONF) $(FEEDSRC)/ecoflow_watchdog.env.example $(1)/etc/ecoflow_watchdog.env.example

	# GL.iNet app tile (harmless elsewhere)
	$(INSTALL_DIR) $(1)/etc/gl-app
	$(INSTALL_CONF) $(FEEDSRC)/package/ecoflow-watchdog/files/etc/gl-app/ecoflow-watchdog.json $(1)/etc/gl-app/
endef

$(eval $(call BuildPackage,ecoflow-watchdog))
