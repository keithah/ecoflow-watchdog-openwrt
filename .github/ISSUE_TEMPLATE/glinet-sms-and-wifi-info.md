---
name: "Question: GL.iNet SMS + Wi-Fi client API details"
about: Gather upstream details needed for EcoFlow watchdog automation
title: "[question] GL.iNet SMS API + hostapd ubus details"
labels: question
assignees: ""
---

### Summary
We’re building an OpenWrt/GL.iNet watchdog that runs on Spitz (CAT4/5) to shut down an EcoFlow pack when a specific client leaves Wi‑Fi or charge input stops. We’d like to rely on supported APIs rather than model-specific hacks.

### Questions for GL.iNet
1. **SMS send API (CLI/ubus):** What is the supported, stable way to send an SMS from shell?  
   - Is `ubus call sms send_sms '{"number":"...","text":"..."}'` guaranteed across Spitz firmware 4.x?  
   - If not, what ubus object/method should we call, and is there an HTTP RPC we should prefer?  
   - Any rate limits or message length constraints?
2. **Hostapd ubus object names:** Is there a documented way to enumerate AP interfaces (e.g., `ubus list hostapd.*`)? Are object names guaranteed to follow `hostapd.<iface>` in 4.x?  
3. **Client hostname availability:** In `ubus call hostapd.$IF get_clients`, can we rely on a `hostname` field? If not, is there a preferred source for hostname (DHCP leases vs. ubus) that’s stable in GL.iNet builds?  
4. **Cellular-only units:** Any differences in SMS/ubus availability between CAT4 (EP06-E) and CAT20 (EM12/EM20) Spitz SKUs we should account for?  
5. **Future compatibility:** Are there planned changes in the 4.x → 5.x line that would deprecate these calls? Any recommended capability probe we should implement?

### Context
- Router: GL.iNet Spitz (GL-X750) running firmware 4.x (OpenWrt base).
- Use case: cron/daemon script; dependencies: `curl`, `jq`, optional `iwinfo`.
- Public repo: https://github.com/keithah/ecoflow-watchdog-openwrt

Thanks for any guidance or documentation pointers!
