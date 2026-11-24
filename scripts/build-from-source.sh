#!/usr/bin/env bash
# Build jito-shredstream-proxy from source (Ubuntu).
set -euo pipefail
sudo apt-get install -y build-essential clang libclang-dev cmake protobuf-compiler

git clone https://github.com/no-limit-nodes/shredstream-proxy.git
cd shredstream-proxy
RUST_REED_SOLOMON_ERASURE_ARCH=x86-64 cargo build --release --bin jito-shredstream-proxy
echo "Binary: $(pwd)/target/release/jito-shredstream-proxy"
