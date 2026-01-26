module("luci.controller.ecoflow_watchdog", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/ecoflow_watchdog") then
		return
	end
	entry({"admin", "services", "ecoflow_watchdog"}, cbi("ecoflow_watchdog"), _("EcoFlow Watchdog"), 60).dependent = true
	entry({"admin", "services", "ecoflow_watchdog", "status"}, template("ecoflow_watchdog/status"), _("Status"), 61).leaf = true
	entry({"admin", "services", "ecoflow_watchdog", "status_json"}, call("action_status")).leaf = true
	entry({"admin", "services", "ecoflow_watchdog", "action"}, call("action_control")).leaf = true
end

local function run(cmd)
	return luci.sys.call(cmd .. " >/dev/null 2>&1")
end

function action_status()
	luci.http.prepare_content("application/json")
	local json = luci.sys.exec("/usr/sbin/ecoflow_watchdogd --status 2>/dev/null")
	if json == "" then
		luci.http.write('{"status":"error","message":"no data"}')
	else
		luci.http.write(json)
	end
end

function action_control()
	local act = luci.http.formvalue("do")
	if act == "start" then
		run("/etc/init.d/ecoflow_watchdog start")
	elseif act == "stop" then
		run("/etc/init.d/ecoflow_watchdog stop")
	elseif act == "restart" then
		run("/etc/init.d/ecoflow_watchdog restart")
	elseif act == "runonce" then
		run("/usr/sbin/ecoflow_watchdogd --once")
	end
	luci.http.status(204, "No Content")
end
