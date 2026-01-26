# EcoFlow Power-Off Watchdog (OpenWrt, cron-friendly)

Goal: on a GL.iNet/OpenWrt router, stop the EcoFlow DC (cigarette) output—or whole device, if desired—after the paired client disappears and/or input charging power goes away for a grace period. Designed to run from cron every 10 minutes (daemon mode optional).

## Files
- `usr/sbin/ecoflow_watchdogd` – one-shot/daemon script (POSIX `ash`)
- `usr/lib/ecoflow_watchdog/ecoflow_api.sh` – EcoFlow API helper (Bearer+Secret headers by default)
- `usr/lib/ecoflow_watchdog/notify_sample.sh` – optional notification hook template (tries `ubus sms` if present)
- `etc/config/ecoflow_watchdog` – UCI config template

## Install (OpenWrt/Spitz)
```sh
opkg install curl jq ca-bundle iwinfo  # iwinfo optional but useful
mkdir -p /usr/lib/ecoflow_watchdog
cp usr/sbin/ecoflow_watchdogd /usr/sbin/
cp usr/lib/ecoflow_watchdog/ecoflow_api.sh /usr/lib/ecoflow_watchdog/
cp usr/lib/ecoflow_watchdog/notify_sample.sh /usr/lib/ecoflow_watchdog/
cp etc/config/ecoflow_watchdog /etc/config/
cp ecoflow_watchdog.env.example /etc/ecoflow_watchdog.env
chmod 755 /usr/sbin/ecoflow_watchdogd /usr/lib/ecoflow_watchdog/*.sh
chmod 600 /etc/config/ecoflow_watchdog
chmod 600 /etc/ecoflow_watchdog.env
```

## Configure (`/etc/config/ecoflow_watchdog`)
- Required: `device_sn`, `access_token`, `secret_token`
- Presence detection: set `client_name` (hostname substring, case-insensitive) and/or `client_mac` and optional `wifi_iface` (otherwise all hostapd.* objects are scanned).
- Behavior: `grace_seconds` (default 300), `cooldown_seconds` (default 600), `shutdown_target` (`dc` or `device`), `input_watts_threshold` (default 0).
- Notifications: set `notify_cmd` to an executable script. Example: `/usr/lib/ecoflow_watchdog/notify_sample.sh`.
- Optional env file: `/etc/ecoflow_watchdog.env` overrides UCI for tokens/base URL without storing them in UCI backups (see `ecoflow_watchdog.env.example`).
  - You can also set `NOTIFY_PHONE` here for the sample SMS hook.

## Cron usage (recommended)
```
*/10 * * * * /usr/sbin/ecoflow_watchdogd --once >/tmp/ecoflow_watchdog.log 2>&1
```
State is stored in `/tmp/ecoflow_watchdog.state` so the grace window survives across cron runs.

## Daemon mode (optional)
```
/usr/sbin/ecoflow_watchdogd --daemon
```
Uses `check_interval` from config (default 10 s).
`/etc/init.d/ecoflow_watchdog` is provided if you prefer `service ecoflow_watchdog start` and `enable`.

## GL.iNet persistence notes
- GL.iNet keeps `/etc`, `/usr/sbin`, `/usr/lib` when “Keep settings” is enabled during firmware upgrade (default). To be extra safe, add these paths to `/etc/sysupgrade.conf`:
  ```
  /usr/sbin/ecoflow_watchdogd
  /usr/lib/ecoflow_watchdog/
  /etc/config/ecoflow_watchdog
  /etc/ecoflow_watchdog.env
  /etc/init.d/ecoflow_watchdog
  ```
- Secrets belong in `/etc/ecoflow_watchdog.env` (chmod 600) to keep them out of UCI backups.

## Installation on GL.iNet (copy/paste)
```
opkg update
opkg install curl jq ca-bundle iwinfo
mkdir -p /usr/lib/ecoflow_watchdog
cp /tmp/ecoflow_watchdogd /usr/sbin/                     # adjust source path if copied differently
cp /tmp/ecoflow_api.sh /tmp/notify_sample.sh /usr/lib/ecoflow_watchdog/
cp /tmp/ecoflow_watchdog /etc/config/
cp /tmp/ecoflow_watchdog.env.example /etc/ecoflow_watchdog.env
chmod 755 /usr/sbin/ecoflow_watchdogd /usr/lib/ecoflow_watchdog/*.sh
chmod 600 /etc/config/ecoflow_watchdog /etc/ecoflow_watchdog.env
cat >> /etc/sysupgrade.conf <<'EOF'
/usr/sbin/ecoflow_watchdogd
/usr/lib/ecoflow_watchdog/
/etc/config/ecoflow_watchdog
/etc/ecoflow_watchdog.env
/etc/init.d/ecoflow_watchdog
EOF
```

## Roadmap
- Optional LuCI/GL.iNet UI tile under “Applications” for configuring tokens/targets.
- “Official” SMS sending method once GL.iNet clarifies stable ubus/HTTP endpoints (see issue #1).

## LuCI / package builds
- Packages included for OpenWrt build systems:
  - `package/ecoflow-watchdog/Makefile`
  - `package/luci-app-ecoflow-watchdog/Makefile`
- The LuCI app adds:
  - Config form for all UCI options
  - Status page with last activity/action, watts, cooldown/grace timers
  - Buttons: Run once, Start, Restart, Stop
- GL.iNet tile: `/etc/gl-app/ecoflow-watchdog.json` points to the LuCI path; harmless on other builds.
- To build with an OpenWrt SDK: place this repo under the SDK tree and run `make package/ecoflow-watchdog/compile package/luci-app-ecoflow-watchdog/compile V=sc`.

## Download prebuilt IPKs (ath79/mips_24kc)
- GitHub Actions builds on every PR/push/release (workflow `build.yml`). The artifact is named `openwrt-packages-<sha>` and contains:
  - `ecoflow-watchdog_0.1.0-1_mips_24kc.ipk`
  - `luci-app-ecoflow-watchdog_*_all.ipk`
- To fetch from a successful run: Actions → Build OpenWrt packages → run → Artifacts.
- On releases, the same IPKs are attached automatically.
- CLI pull for testing (requires `gh` + `jq`):
  ```
  REPO=keithah/ecoflow-watchdog-openwrt ./scripts/fetch_latest_artifacts.sh
  ls output/
  ```
  This downloads the latest main-branch build artifact into `output/`.

## Quick manual install from repo (no IPK, good for PR testing)
```
# defaults: REPO=keithah/ecoflow-watchdog-openwrt, REF=main, MODE=daemon
REPO=keithah/ecoflow-watchdog-openwrt REF=main MODE=cron CRON_SPEC="*/10 * * * *" \
  sh -c 'curl -L https://raw.githubusercontent.com/keithah/ecoflow-watchdog-openwrt/main/scripts/install_from_repo.sh | sh'
```
- MODE=daemon (default) enables and starts the procd service.
- MODE=cron adds a cron entry (default */10) and restarts cron.
- Keeps settings across upgrades by appending paths to `/etc/sysupgrade.conf` (disable with `NO_SYSUPGRADE=1`).
- After install, the script prints a status snapshot (set `CHECK_STATUS=0` to skip).

One-liner to install from current main, start daemon, and show status:
```
sh -c 'curl -L https://raw.githubusercontent.com/keithah/ecoflow-watchdog-openwrt/main/scripts/install_from_repo.sh | sh'
```

## Installing IPKs (GL.iNet/OpenWrt)
```
# copy the two ipks to the router, e.g. via scp to /tmp/
opkg update
opkg install /tmp/ecoflow-watchdog_0.1.0-1_mips_24kc.ipk /tmp/luci-app-ecoflow-watchdog_*_all.ipk

# enable daemon mode (optional; cron is still fine)
service ecoflow_watchdog enable
service ecoflow_watchdog start
```
Then open LuCI → Services → EcoFlow Watchdog (or GL.iNet “Applications” tile) to configure tokens/device/client and view status.

## Decision logic
1) If the client is present (hostapd → DHCP leases → iwinfo), liveness resets.
2) If input watts exceed `input_watts_threshold`, liveness resets.
3) If neither is true for `grace_seconds` and outside `cooldown_seconds`, it:
   - attempts device standby/off when `shutdown_target=device` (best effort), else
   - disables DC output (`/out/dc`), falling back to car output.

## Notifications (example for GL.iNet SMS)
- If your firmware exposes an `sms` ubus object (`ubus list | grep '^sms$'`), set:
  - `uci set ecoflow_watchdog.main.notify_cmd='/usr/lib/ecoflow_watchdog/notify_sample.sh'`
  - set `NOTIFY_PHONE="+1XXXXXXXXXX"` in `/etc/ecoflow_watchdog.env`.
- Otherwise, point `notify_cmd` to any custom script (e.g., sends email, hits a webhook, etc.). The script receives: `$1=event`, `$2=reason`, `$3=extra`, with env vars `EVENT`, `REASON`, `EXTRA`, `TIMESTAMP`.

## Notes
- Default API mode: Bearer + `X-Secret-Token`, base URL `https://api.ecoflow.com`. Swap `api_mode` / `base_url` if using a proxy or official signed flow.
- Secrets are never logged. If tokens are missing, the script logs and skips API calls.
- Logging goes to syslog (`logread`) and stdout/stderr when run manually.
