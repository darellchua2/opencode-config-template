#!/usr/bin/env bash
#
# restart-opencode-pm2.sh
# Purpose: Pull the latest 'main' branch of opencode-config-template and restart
#          the pm2-hosted OpenCode web service (`opencode serve`).
#
# Branch:  Deploys the 'main' branch — changes MUST be merged to main first.
#
# Health checks performed after restart:
#   1. Local service:   GET http://localhost:4096  -> expects HTTP 200
#   2. Public endpoint: GET https://opencode-ha.civiltekk.com -> expects 200/101
# On local failure, recent pm2 logs are printed; on public failure, a warning is shown.
#
set -euo pipefail

cd /home/silentx/VSCODE/opencode-config-template
git checkout main
git stash
git pull
git stash pop 2>/dev/null || true

pm2 delete opencode 2>/dev/null || true
pm2 start "opencode serve --hostname 0.0.0.0 --port 4096" --name opencode
pm2 save

echo "Waiting for opencode to start..."
sleep 3

if curl -s -o /dev/null -w "%{http_code}" http://localhost:4096 | grep -q "200"; then
  echo "OpenCode is running on http://0.0.0.0:4096"
else
  echo "Warning: OpenCode did not respond with 200"
  pm2 logs opencode --lines 10 --nostream
fi

echo "Checking opencode-ha.civiltekk.com..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://opencode-ha.civiltekk.com)
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 101 ]; then
  echo "opencode-ha.civiltekk.com is reachable (HTTP $HTTP_CODE)"
else
  echo "Warning: opencode-ha.civiltekk.com returned HTTP $HTTP_CODE"
fi
