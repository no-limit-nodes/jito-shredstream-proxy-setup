#!/usr/bin/env bash
# Run the proxy in the foreground. Set KEYPAIR to your existing auth keypair file.
set -euo pipefail
KEYPAIR=${KEYPAIR:-/path/to/shredstream-keypair.json}

RUST_LOG=info jito-shredstream-proxy shredstream \
  --block-engine-url https://fra.jito.nolimitnodes.com \
  --auth-keypair "$KEYPAIR" \
  --desired-regions frankfurt \
  --dest-ip-ports 127.0.0.1:8001
