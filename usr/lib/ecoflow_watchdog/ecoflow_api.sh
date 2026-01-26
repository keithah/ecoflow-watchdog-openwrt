#!/bin/ash
# Minimal EcoFlow API helper (Bearer + Secret header mode by default).

ecoflow_api_request() {
	# $1 method, $2 path, $3 body-json (optional), outputs body to stdout, returns 0 on 2xx
	local method="$1"; shift
	local path="$1"; shift
	local body="${1:-}"

	local url="${BASE_URL%/}${path}"
	local tmpbody
	tmpbody="$(mktemp /tmp/ecoflow_api.XXXXXX)" || return 1
	local code attempt=0 delay=1

	while [ "$attempt" -lt 3 ]; do
		if [ -n "$body" ]; then
			curl -skS --max-time 15 -X "$method" "$url" \
				-H "Authorization: Bearer ${ACCESS_TOKEN}" \
				-H "X-Secret-Token: ${SECRET_TOKEN}" \
				-H "Content-Type: application/json" \
				-o "$tmpbody" -w "%{http_code}" -d "$body" >"$tmpbody.code"
		else
			curl -skS --max-time 15 -X "$method" "$url" \
				-H "Authorization: Bearer ${ACCESS_TOKEN}" \
				-H "X-Secret-Token: ${SECRET_TOKEN}" \
				-o "$tmpbody" -w "%{http_code}" >"$tmpbody.code"
		fi
		code=$(cat "$tmpbody.code" 2>/dev/null)
		if [ -n "$code" ] && [ "$code" -ge 200 ] && [ "$code" -lt 300 ]; then
			cat "$tmpbody"
			rm -f "$tmpbody" "$tmpbody.code"
			return 0
		fi
		# retry on failure
		: $((attempt++))
		sleep "$delay"
		: $((delay<<=1))
	done
	rm -f "$tmpbody" "$tmpbody.code"
	return 1
}

ecoflow_get_parameters() {
	# $1 device_sn
	local sn="$1"
	ecoflow_api_request "GET" "/api/devices/${sn}/parameters"
}

ecoflow_set_dc_output() {
	# $1 device_sn, $2 on|off
	local sn="$1" state="$2"
	ecoflow_api_request "PUT" "/api/power_station/${sn}/out/dc" "{\"state\":\"${state}\"}"
}

ecoflow_set_car_output() {
	# optional: disable car / cigar if API differentiates
	local sn="$1" state="$2"
	ecoflow_api_request "PUT" "/api/power_station/${sn}/out/car" "{\"state\":\"${state}\"}"
}

ecoflow_set_standby() {
	# $1 device_sn, $2 type (device|ac|dc|lcd), $3 seconds
	local sn="$1" stype="$2" secs="$3"
	ecoflow_api_request "POST" "/api/power_station/${sn}/standby" "{\"type\":\"${stype}\",\"stand_by\":${secs}}"
}
