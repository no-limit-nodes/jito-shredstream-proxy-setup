#!/usr/bin/env bash
# Install the prebuilt jito-shredstream-proxy (Linux x86-64, glibc 2.31+) and verify its SHA-256 checksum.
set -euo pipefail
BASE=https://github.com/no-limit-nodes/shredstream-proxy/releases/latest/download
BIN=jito-shredstream-proxy-x86_64-unknown-linux-gnu

curl -LO "$BASE/$BIN"
curl -LO "$BASE/$BIN.sha256"
sha256sum -c "$BIN.sha256"
chmod +x "$BIN"
sudo mv "$BIN" /usr/local/bin/jito-shredstream-proxy
echo "Installed /usr/local/bin/jito-shredstream-proxy"
