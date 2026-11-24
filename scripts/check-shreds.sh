#!/usr/bin/env bash
# Are shred packets reaching the machine at all? Captures 20 packets on the proxy's listen port.
set -euo pipefail
sudo tcpdump -n -i any 'udp and dst port 20000' -c 20
