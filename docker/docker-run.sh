#!/usr/bin/env bash
# Build the proxy image from source and run it with host networking.
# Put your existing keypair at ./shredstream-keypair.json first (it is git-ignored).
set -euo pipefail
git clone https://github.com/no-limit-nodes/shredstream-proxy.git
cd shredstream-proxy
docker build -t shredstream-proxy .

docker run -d --name shredstream-proxy --restart unless-stopped --network host \
  -e RUST_LOG=info \
  -v "$(pwd)/../shredstream-keypair.json:/app/shredstream-keypair.json:ro" \
  shredstream-proxy shredstream \
  --block-engine-url https://fra.jito.nolimitnodes.com \
  --auth-keypair /app/shredstream-keypair.json \
  --desired-regions frankfurt \
  --dest-ip-ports 127.0.0.1:8001
