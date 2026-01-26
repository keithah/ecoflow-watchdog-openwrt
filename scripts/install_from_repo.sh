#!/bin/ash
# Install latest (or specific ref) directly from GitHub without building IPKs.
# Usage: REPO=keithah/ecoflow-watchdog-openwrt REF=main INSTALL_ROOT=/ ./scripts/install_from_repo.sh
# Optional: NO_SYSUPGRADE=1 to skip adding entries.

set -eu

REPO="${REPO:-keithah/ecoflow-watchdog-openwrt}"
REF="${REF:-main}"
ROOT="${INSTALL_ROOT:-/}"
NO_SYSUPGRADE="${NO_SYSUPGRADE:-0}"
TMP="$(mktemp -d /tmp/ecoflow_install.XXXXXX)"
BASE="https://raw.githubusercontent.com/${REPO}/${REF}"

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }
need curl

fetch() {
  local path="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  curl -L "${BASE}/${path}" -o "$dest"
}

# Files to fetch
fetch usr/sbin/ecoflow_watchdogd "$TMP/ecoflow_watchdogd"
fetch usr/lib/ecoflow_watchdog/ecoflow_api.sh "$TMP/ecoflow_api.sh"
fetch usr/lib/ecoflow_watchdog/notify_sample.sh "$TMP/notify_sample.sh"
fetch etc/config/ecoflow_watchdog "$TMP/ecoflow_watchdog.conf"
fetch etc/init.d/ecoflow_watchdog "$TMP/init_ecoflow_watchdog"
fetch ecoflow_watchdog.env.example "$TMP/ecoflow_watchdog.env.example"
fetch package/ecoflow-watchdog/files/etc/gl-app/ecoflow-watchdog.json "$TMP/glapp.json"

# Install
install -m 755 "$TMP/ecoflow_watchdogd" "$ROOT/usr/sbin/ecoflow_watchdogd"
mkdir -p "$ROOT/usr/lib/ecoflow_watchdog"
install -m 755 "$TMP/ecoflow_api.sh" "$ROOT/usr/lib/ecoflow_watchdog/ecoflow_api.sh"
install -m 755 "$TMP/notify_sample.sh" "$ROOT/usr/lib/ecoflow_watchdog/notify_sample.sh"

mkdir -p "$ROOT/etc/config"
install -m 600 "$TMP/ecoflow_watchdog.conf" "$ROOT/etc/config/ecoflow_watchdog"

mkdir -p "$ROOT/etc"
install -m 600 "$TMP/ecoflow_watchdog.env.example" "$ROOT/etc/ecoflow_watchdog.env"

mkdir -p "$ROOT/etc/init.d"
install -m 755 "$TMP/init_ecoflow_watchdog" "$ROOT/etc/init.d/ecoflow_watchdog"

# GL.iNet tile (harmless elsewhere)
mkdir -p "$ROOT/etc/gl-app"
install -m 644 "$TMP/glapp.json" "$ROOT/etc/gl-app/ecoflow-watchdog.json"

# sysupgrade persistence
if [ "$NO_SYSUPGRADE" != "1" ]; then
  SYSC="$ROOT/etc/sysupgrade.conf"
  mkdir -p "$(dirname "$SYSC")"
  for p in \
    /usr/sbin/ecoflow_watchdogd \
    /usr/lib/ecoflow_watchdog/ \
    /etc/config/ecoflow_watchdog \
    /etc/ecoflow_watchdog.env \
    /etc/init.d/ecoflow_watchdog \
    /etc/gl-app/ecoflow-watchdog.json; do
    grep -qxF "$p" "$SYSC" 2>/dev/null || echo "$p" >> "$SYSC"
  done
fi

echo "Installed from ${REPO}@${REF} into ${ROOT}" >&2
echo "Edit /etc/ecoflow_watchdog.env and /etc/config/ecoflow_watchdog, then either cron or service ecoflow_watchdog start" >&2
