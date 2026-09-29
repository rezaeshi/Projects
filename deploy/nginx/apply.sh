#!/usr/bin/env bash
# Runs on the server (piped over ssh by the deploy workflow): installs the uploaded
# nginx config and restores the previous one if nginx rejects it.
set -euo pipefail

target=/etc/nginx/conf.d/hamkar-learntalk.conf
new=/tmp/hamkar-learntalk.conf.new
backup="/root/hamkar-learntalk.conf.$(date +%Y%m%d-%H%M%S).bak"

cp "$target" "$backup"
echo "backup: $backup"
install -m 644 "$new" "$target"

if ! nginx -t; then
    cp "$backup" "$target"
    echo "nginx -t failed; restored $backup" >&2
    exit 1
fi
systemctl reload nginx
rm -f "$new"

curl -sS -o /dev/null -w 'http  /hamkar/ -> %{http_code}\n' http://127.0.0.1/hamkar/
curl -sS -o /dev/null -w 'http  /        -> %{http_code}\n' -H 'Host: app.prodima.ir' http://127.0.0.1/
curl -sS -o /dev/null -w 'https /        -> %{http_code}\n' --resolve app.prodima.ir:443:127.0.0.1 https://app.prodima.ir/
