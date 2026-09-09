#!/bin/bash
# Set the admin password and open the health endpoint, then hand off to upstream's entrypoint.
#
# HertzBeat reads its login accounts from config/sureness.yml, not from the database, so the
# shipped default (admin / hertzbeat) would otherwise be the password on a public URL. The file
# is patched in place at every start rather than replaced, so a version bump keeps upstream's
# own file and only the credential line changes.
set -euo pipefail

CONFIG="/opt/hertzbeat/config/sureness.yml"

[ -n "${HERTZBEAT_ADMIN_PASSWORD:-}" ] || {
  echo "HERTZBEAT_ADMIN_PASSWORD is empty; refusing to start with the well-known default password" >&2
  exit 1
}
[ "${#HERTZBEAT_ADMIN_PASSWORD}" -ge 12 ] || {
  echo "HERTZBEAT_ADMIN_PASSWORD must be at least 12 characters" >&2
  exit 1
}
# The credential is written into a YAML scalar; keep it to characters that need no quoting.
case "$HERTZBEAT_ADMIN_PASSWORD" in
  *[!A-Za-z0-9_-]*)
    echo "HERTZBEAT_ADMIN_PASSWORD may only contain A-Z a-z 0-9 _ -" >&2
    exit 1 ;;
esac
[ -n "${SPRING_DATASOURCE_URL:-}" ] || {
  echo "SPRING_DATASOURCE_URL is empty; HertzBeat needs its PostgreSQL service" >&2
  exit 1
}
[ -n "${WAREHOUSE_STORE_VICTORIA_METRICS_URL:-}" ] || {
  echo "WAREHOUSE_STORE_VICTORIA_METRICS_URL is empty; HertzBeat needs its VictoriaMetrics service" >&2
  exit 1
}
[ -f "$CONFIG" ] || { echo "$CONFIG is missing; the upstream image layout changed" >&2; exit 1; }

# Replace the credential belonging to the admin account only, leaving any other account and
# every comment untouched.
awk -v pw="$HERTZBEAT_ADMIN_PASSWORD" '
  /^[[:space:]]*-[[:space:]]*appId:[[:space:]]*admin[[:space:]]*$/ { print; in_admin = 1; next }
  in_admin && /^[[:space:]]*credential:/ {
    match($0, /^[[:space:]]*/)
    print substr($0, 1, RLENGTH) "credential: " pw
    in_admin = 0
    next
  }
  { print }
' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"

grep -q "credential: $HERTZBEAT_ADMIN_PASSWORD" "$CONFIG" || {
  echo "failed to set the admin password in $CONFIG" >&2
  exit 1
}
echo "admin password applied to sureness.yml"

# Railway's healthcheck is an unauthenticated HTTP GET, but sureness protects /actuator/**.
# Allow only the health endpoint; /actuator/metrics and /actuator/prometheus stay behind auth.
# Spring's health details default to hidden, so this exposes a status and nothing more.
if ! grep -q '/actuator/health===get' "$CONFIG"; then
  awk '
    /^excludedResource:/ { print; print "  - /actuator/health===get"; next }
    { print }
  ' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"
  echo "opened /actuator/health for the platform healthcheck"
fi

exec ./bin/entrypoint.sh "$@"
