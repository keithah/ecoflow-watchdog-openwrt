local m = Map("ecoflow_watchdog", translate("EcoFlow Watchdog"))
m.description = translate("Shut down EcoFlow DC (or device) when a client leaves Wi-Fi or input charging stops.")

local s = m:section(NamedSection, "main", "ecoflow_watchdog", translate("Settings"))
s.addremove = false
s.anonymous = true

local region = s:option(ListValue, "region", translate("Region"))
region:value("us", "US")
region:value("eu", "EU")
region.default = "us"

local api_mode = s:option(ListValue, "api_mode", translate("API Mode"))
api_mode:value("bearer_secret", "Bearer + Secret header")
api_mode:value("official", "Official signed (custom)")
api_mode.default = "bearer_secret"

local base_url = s:option(Value, "base_url", translate("Base URL"))
base_url.default = "https://api.ecoflow.com"

local access = s:option(Value, "access_token", translate("Access Token"))
access.password = true

local secret = s:option(Value, "secret_token", translate("Secret Token"))
secret.password = true

local sn = s:option(Value, "device_sn", translate("Device SN"))
sn.datatype = "string"
sn.rmempty = false

local wifi_iface = s:option(Value, "wifi_iface", translate("Wi-Fi Interface"))
wifi_iface.placeholder = "wlan0"

local client_name = s:option(Value, "client_name", translate("Client hostname contains"))
client_name.placeholder = "pHADM"

local client_mac = s:option(Value, "client_mac", translate("Client MAC"))
client_mac.placeholder = "AA:BB:CC:DD:EE:FF"

local grace = s:option(Value, "grace_seconds", translate("Grace seconds"))
grace.datatype = "uinteger"
grace.default = 300

local cooldown = s:option(Value, "cooldown_seconds", translate("Cooldown seconds"))
cooldown.datatype = "uinteger"
cooldown.default = 600

local input_thr = s:option(Value, "input_watts_threshold", translate("Input watts threshold"))
input_thr.datatype = "integer"
input_thr.default = 0

local check_int = s:option(Value, "check_interval", translate("Check interval (daemon)"))
check_int.datatype = "uinteger"
check_int.default = 10

local shutdown_target = s:option(ListValue, "shutdown_target", translate("Action"))
shutdown_target:value("dc", translate("Disable DC (cigarette)"))
shutdown_target:value("device", translate("Device standby/off then DC"))
shutdown_target.default = "dc"

local notify_cmd = s:option(Value, "notify_cmd", translate("Notify command"))
notify_cmd.placeholder = "/usr/lib/ecoflow_watchdog/notify_sample.sh"

local dry = s:option(Flag, "dry_run", translate("Dry run (no API actions)"))
dry.default = 0

local log_level = s:option(ListValue, "log_level", translate("Log level"))
log_level:value("info", "info")
log_level:value("debug", "debug")
log_level.default = "info"

return m
