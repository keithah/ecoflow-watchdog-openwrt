#!/bin/ash
# Install latest (or specific ref) directly from GitHub without building IPKs.
# Usage: REPO=keithah/ecoflow-watchdog-openwrt REF=main INSTALL_ROOT=/ ./scripts/install_from_repo.sh
# Options:
#   NO_SYSUPGRADE=1       skip adding to /etc/sysupgrade.conf
#   MODE=daemon|cron      choose run mode (default daemon)
#   CRON_SPEC="*/10 * * * *" override cron schedule

set -eu

REPO="${REPO:-keithah/ecoflow-watchdog-openwrt}"
REF="${REF:-main}"
ROOT="${INSTALL_ROOT:-/}"
NO_SYSUPGRADE="${NO_SYSUPGRADE:-0}"
MODE="${MODE:-daemon}"
CRON_SPEC="${CRON_SPEC:-*/10 * * * *}"
CHECK_STATUS="${CHECK_STATUS:-1}"
TMP="$(mktemp -d /tmp/ecoflow_install.XXXXXX)"
BASE="https://raw.githubusercontent.com/${REPO}/${REF}"

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }
need curl

inst() {
  # inst <mode> <src> <dest>
  local mode="$1" src="$2" dest="$3"
  mkdir -p "$(dirname "$dest")"
  if command -v install >/dev/null 2>&1; then
    install -m "$mode" "$src" "$dest"
  elif command -v busybox >/dev/null 2>&1; then
    busybox install -m "$mode" "$src" "$dest"
  else
    cp -f "$src" "$dest"
    chmod "$mode" "$dest"
  fi
}

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
inst 755 "$TMP/ecoflow_watchdogd" "$ROOT/usr/sbin/ecoflow_watchdogd"
inst 755 "$TMP/ecoflow_api.sh" "$ROOT/usr/lib/ecoflow_watchdog/ecoflow_api.sh"
inst 755 "$TMP/notify_sample.sh" "$ROOT/usr/lib/ecoflow_watchdog/notify_sample.sh"

inst 600 "$TMP/ecoflow_watchdog.conf" "$ROOT/etc/config/ecoflow_watchdog"

inst 600 "$TMP/ecoflow_watchdog.env.example" "$ROOT/etc/ecoflow_watchdog.env"

inst 755 "$TMP/init_ecoflow_watchdog" "$ROOT/etc/init.d/ecoflow_watchdog"

# GL.iNet tile (harmless elsewhere)
inst 644 "$TMP/glapp.json" "$ROOT/etc/gl-app/ecoflow-watchdog.json"

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
echo "Edit /etc/ecoflow_watchdog.env and /etc/config/ecoflow_watchdog, then choose run mode (MODE=$MODE)" >&2

CRONTAB="$ROOT/etc/crontabs/root"

if [ "$MODE" = "daemon" ]; then
  # clean old cron line if present
  if [ -f "$CRONTAB" ]; then
    tmpc="$(mktemp)"
    grep -v "ecoflow_watchdogd --once" "$CRONTAB" 2>/dev/null > "$tmpc" || true
    mv "$tmpc" "$CRONTAB"
    chmod 600 "$CRONTAB"
  fi
  if [ -x "$ROOT/etc/init.d/ecoflow_watchdog" ]; then
    chroot "$ROOT" /etc/init.d/ecoflow_watchdog enable >/dev/null 2>&1 || true
    chroot "$ROOT" /etc/init.d/ecoflow_watchdog start >/dev/null 2>&1 || true
    echo "Daemon mode enabled and started" >&2
  else
    echo "Init script missing; cannot start daemon" >&2
  fi
elif [ "$MODE" = "cron" ]; then
  mkdir -p "$(dirname "$CRONTAB")"
  # remove daemon enable if switching from daemon
  if [ -x "$ROOT/etc/init.d/ecoflow_watchdog" ]; then
    chroot "$ROOT" /etc/init.d/ecoflow_watchdog disable >/dev/null 2>&1 || true
    chroot "$ROOT" /etc/init.d/ecoflow_watchdog stop >/dev/null 2>&1 || true
  fi
  if ! grep -F "ecoflow_watchdogd --once" "$CRONTAB" 2>/dev/null; then
    echo "$CRON_SPEC /usr/sbin/ecoflow_watchdogd --once >/tmp/ecoflow_watchdog.log 2>&1" >> "$CRONTAB"
  fi
  chmod 600 "$CRONTAB"
  if chroot "$ROOT" /etc/init.d/cron status >/dev/null 2>&1; then
    chroot "$ROOT" /etc/init.d/cron restart >/dev/null 2>&1 || true
  fi
  echo "Cron mode set at '$CRON_SPEC'" >&2
else
  echo "Unknown MODE: $MODE (use daemon or cron)" >&2
fi

if [ "$CHECK_STATUS" = "1" ]; then
  if [ -x "$ROOT/usr/sbin/ecoflow_watchdogd" ]; then
    echo "Status after install:" >&2
    chroot "$ROOT" /usr/sbin/ecoflow_watchdogd --status 2>/dev/null || true
  fi
fi
