# Jito Shredstream Proxy Setup

Ready-to-use setup files for running `jito-shredstream-proxy` on Linux after Jito's ShredStream shutdown: install script, systemd unit, Docker run command, environment file, and a packet health check.

The proxy receives Solana shreds from a block engine and forwards them to your validator, RPC node or bot. These files point it at [NoLimitNodes Jito Shreds](https://nolimitnodes.com/products/jito-shreds): you keep your keypair and everything downstream, change `--block-engine-url`, and shreds arrive on UDP 20000.

Full walkthrough: **[Jito shredstream proxy setup guide](https://nolimitnodes.com/blog/jito-shredstream-proxy-setup)**

## Requirements

- A Linux server with a public IPv4 address. The prebuilt binary needs x86-64 and glibc 2.31 or newer (Ubuntu 20.04+, Debian 11+).
- Your existing auth keypair file. Register only its **public key** in the NoLimitNodes dashboard:

  ```bash
  solana-keygen pubkey shredstream-keypair.json
  ```

  Never share or commit the keypair file itself. This repo's `.gitignore` excludes `*.json`.

- UDP port 20000 open on the proxy machine.

## Quick start

```bash
# 1. Install the proxy (prebuilt binary with checksum check)
./scripts/install-binary.sh
#    or build it: ./scripts/build-from-source.sh

# 2. Allow shreds in on the listen port, from the source IP the dashboard shows
sudo ufw allow from <SOURCE_IP> to any port 20000 proto udp

# 3. Run it
KEYPAIR=/path/to/shredstream-keypair.json ./scripts/run.sh
```

The proxy forwards shreds to `127.0.0.1:8001`. Change `--dest-ip-ports` to wherever your consumer listens.

## Run as a systemd service

```bash
sudo cp systemd/shredstream-proxy.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now shredstream-proxy
journalctl -u shredstream-proxy -f
```

## Run with Docker

```bash
./docker/docker-run.sh
```

Every flag can also be set as an environment variable. See [`.env.example`](.env.example).

## Health check

```bash
./scripts/check-shreds.sh
```

- **No packets:** the firewall or network is blocking UDP 20000, or the public key isn't registered yet.
- **Packets in tcpdump, nothing in the proxy:** they're being dropped on the machine. tcpdump sees packets before the host firewall does, so check ufw or iptables.

Proxy stopped with `Error: Shutdown`? See [Jito shredstream proxy stopped working](https://nolimitnodes.com/blog/jito-shredstream-proxy-stopped-working).

## Files

| File | What it does |
|---|---|
| `scripts/install-binary.sh` | Downloads the prebuilt proxy and verifies its SHA-256 |
| `scripts/build-from-source.sh` | Builds the proxy with cargo |
| `scripts/run.sh` | Runs the proxy in the foreground |
| `scripts/check-shreds.sh` | tcpdump check for shreds on UDP 20000 |
| `systemd/shredstream-proxy.service` | systemd unit |
| `docker/docker-run.sh` | Builds and runs the proxy in Docker |
| `.env.example` | The flags as environment variables |

## Related

- [What are Jito shreds?](https://nolimitnodes.com/blog/what-are-jito-shreds)
- [How to decode Jito shreds](https://nolimitnodes.com/blog/decode-jito-shreds)
- [Jito shreds pricing](https://nolimitnodes.com/blog/jito-shreds-pricing)
- Proxy source: [no-limit-nodes/shredstream-proxy](https://github.com/no-limit-nodes/shredstream-proxy)
