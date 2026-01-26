#!/bin/ash
# Sample notification hook.
# Receives args: $1=event, $2=reason, $3=extra
# Environment: EVENT, REASON, EXTRA, TIMESTAMP

# Example: try GL.iNet SMS ubus if available.
PHONE="${NOTIFY_PHONE:-}"
if ubus list 2>/dev/null | grep -q '^sms$' && [ -n "$PHONE" ]; then
	ubus call sms send_sms "{\"number\":\"$PHONE\",\"text\":\"[EcoFlow] ${EVENT}: ${REASON} ${EXTRA} @ ${TIMESTAMP}\"}" >/dev/null 2>&1
	exit 0
fi

# Otherwise, just log to syslog
logger -t ecoflow_watchdog "[notify] ${EVENT} ${REASON} ${EXTRA} @ ${TIMESTAMP}"
