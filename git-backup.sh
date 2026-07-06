#!/bin/bash
# Nightly repo backup. The repo is PUBLIC: refuse to push anything that looks
# like a secret, and regenerate the per-tab exports in flows/ first.
cd /opt/node-red || exit 1

python3 split_flows.py > /dev/null

PATTERNS='PVEAPIToken=|\$2[aby]\$[0-9]{2}\$|eyJ[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{10,}|github_pat_|nabu\.casa|AKIA[0-9A-Z]{16}|xox[baprs]-|-----BEGIN .*PRIVATE KEY'
HITS=$(grep -InE "$PATTERNS" data/flows.json data/settings.js docker-compose.yml flows/*.json 2>/dev/null \
       | grep -vE 'env\.get|process\.env|zZWtXTja')
if [ -n "$HITS" ]; then
  echo "$HITS" > /opt/node-red/secret-scan-blocked.txt
  curl -s -m 10 -X POST -H 'Content-Type: application/json' \
    -d '{"message":"Secret-scan HIT - nightly git push BLOCKED. Details in /opt/node-red/secret-scan-blocked.txt - clean the flow, then re-run git-backup.sh."}' \
    http://localhost:1880/nr-backup-alert > /dev/null
  exit 1
fi
rm -f /opt/node-red/secret-scan-blocked.txt

git add -A
git -c user.email=node-red@colfin22.net -c user.name=node-red-lxc commit -q -m "auto backup $(date +%F\ %H:%M)" || exit 0
git push -q
