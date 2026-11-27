<h1 align="center">Jito Shredstream Proxy Setup: Install, systemd, Docker and Health Check Files for Linux</h1>

<p align="center">
  <b>Keep running jito-shredstream-proxy after Jito's ShredStream shutdown. Change one URL and shreds keep arriving on UDP 20000.</b><br>
  <sub>Ready-to-use install script, systemd unit, Docker run command, environment file and a packet health check, pointed at <a href="https://nolimitnodes.com/products/jito-shreds">NoLimitNodes Jito Shreds</a>. Maintained by <a href="https://nolimitnodes.com">NoLimitNodes</a>.</sub>
</p>

<p align="center">
  <a href="#repo-layout"><img alt="Bash" src="https://img.shields.io/badge/scripts-bash-blue?style=flat-square"></a>
  <a href="#run-as-a-systemd-service"><img alt="systemd" src="https://img.shields.io/badge/systemd-unit-lightgrey?style=flat-square"></a>
  <a href="#run-with-docker"><img alt="Docker" src="https://img.shields.io/badge/docker-host%20network-2496ED?style=flat-square"></a>
  <a href="https://nolimitnodes.com"><img alt="Powered by NoLimitNodes" src="https://img.shields.io/badge/powered%20by-NoLimitNodes-FBDE00?style=flat-square&labelColor=000000"></a>
  <a href="#how-it-works"><img alt="UDP 20000" src="https://img.shields.io/badge/transport-UDP%2020000-brightgreen?style=flat-square"></a>
  <a href="https://solana.com"><img alt="Solana Mainnet" src="https://img.shields.io/badge/solana-mainnet-9945FF?style=flat-square"></a>
</p>

<p align="center">
  <a href="#quickstart-run-the-proxy-in-3-steps">Quickstart</a> ·
  <a href="#run-as-a-systemd-service">systemd</a> ·
  <a href="#run-with-docker">Docker</a> ·
  <a href="#configuration">Configuration</a> ·
  <a href="#health-check-and-troubleshooting">Health check</a> ·
  <a href="#proxy-vs-push-feed-when-to-pick-which">Proxy vs push</a> ·
  <a href="#faq">FAQ</a>
</p>

---

## What this is

This repo holds the files for a **Jito shredstream proxy setup** on Linux after Jito's ShredStream shutdown: an install script, a systemd unit, a Docker run command, an environment file and a packet health check. The proxy receives Solana shreds from a block engine and forwards them to your validator, RPC node or bot. These files point it at [NoLimitNodes Jito Shreds](https://nolimitnodes.com/products/jito-shreds). You keep your keypair and everything downstream, change `--block-engine-url`, and shreds arrive on UDP 20000.

The proxy binary comes from [no-limit-nodes/shredstream-proxy](https://github.com/no-limit-nodes/shredstream-proxy), a minimal fork of `jito-labs/shredstream-proxy` with the same CLI and wire protocol. Full walkthrough: **[Jito shredstream proxy setup guide](https://nolimitnodes.com/blog/jito-shredstream-proxy-setup)**.

**If you've been looking for any of these, you're in the right place:**

- A **jito-shredstream-proxy setup guide** that still works after the shutdown
- A **jito-shredstream-proxy systemd service** file
- A **jito-shredstream-proxy Docker run** command with host networking
- A **prebuilt jito-shredstream-proxy binary** install with a SHA-256 checksum check
- How to **build jito-shredstream-proxy from source** on Ubuntu
- A replacement **block engine URL for jito-shredstream-proxy**
- A fix for **jito-shredstream-proxy stopped working** or `Error: Shutdown`
- A quick **tcpdump check that shreds are arriving** on UDP 20000

## Who this is for

- **Validator and RPC operators** who forward shreds to their TVU port with `jito-shredstream-proxy`
- **Trading bot teams** whose consumers read shreds from the proxy's `--dest-ip-ports`
- **DevOps engineers** who want the proxy under systemd or Docker with restart on failure
- **Anyone hit by the ShredStream shutdown** who wants to change one URL rather than rewrite a pipeline

## Requirements

- A Linux server with a public IPv4 address. The prebuilt binary needs x86-64 and glibc 2.31 or newer (Ubuntu 20.04+, Debian 11+).
- Your existing auth keypair file. Register only its **public key** in the NoLimitNodes dashboard:

  ```bash
  solana-keygen pubkey shredstream-keypair.json
  ```

  Never share or commit the keypair file itself. This repo's `.gitignore` excludes `*keypair*.json`, `*.json` and `.env`.

- UDP port 20000 open on the proxy machine.

## Quickstart: run the proxy in 3 steps

Before you start, create a NoLimitNodes account at **[app.nolimitnodes.com/register](https://app.nolimitnodes.com/register)**, get [Jito Shreds](https://nolimitnodes.com/products/jito-shreds) access and register your keypair's public key in the dashboard.

```bash
git clone https://github.com/no-limit-nodes/jito-shredstream-proxy-setup
cd jito-shredstream-proxy-setup

# 1. Install the proxy (prebuilt binary with checksum check)
./scripts/install-binary.sh
#    or build it: ./scripts/build-from-source.sh

# 2. Allow shreds in on the listen port, from the source IP the dashboard shows
sudo ufw allow from <SOURCE_IP> to any port 20000 proto udp

# 3. Run it
KEYPAIR=/path/to/shredstream-keypair.json ./scripts/run.sh
```

The proxy forwards shreds to `127.0.0.1:8001`. Change `--dest-ip-ports` to wherever your consumer listens.

### What the scripts do

- `scripts/install-binary.sh` downloads `jito-shredstream-proxy-x86_64-unknown-linux-gnu` and its `.sha256` from the latest [shredstream-proxy release](https://github.com/no-limit-nodes/shredstream-proxy/releases), runs `sha256sum -c`, and installs it to `/usr/local/bin/jito-shredstream-proxy`.
- `scripts/build-from-source.sh` installs `build-essential clang libclang-dev cmake protobuf-compiler` with apt, clones `no-limit-nodes/shredstream-proxy`, and runs `RUST_REED_SOLOMON_ERASURE_ARCH=x86-64 cargo build --release --bin jito-shredstream-proxy`. The binary lands in `shredstream-proxy/target/release/jito-shredstream-proxy`. It needs a Rust toolchain installed.
- `scripts/run.sh` runs the proxy in the foreground with `RUST_LOG=info`, reading the keypair path from `KEYPAIR` (default `/path/to/shredstream-keypair.json`).

## Run as a systemd service

```bash
sudo cp systemd/shredstream-proxy.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now shredstream-proxy
journalctl -u shredstream-proxy -f
```

The unit runs `/usr/local/bin/jito-shredstream-proxy` as user `shredstream`, reads the keypair from `/etc/shredstream/keypair.json`, starts after `network-online.target`, and restarts always with a 5 second delay. Create that user and put the keypair at that path (readable by the user), or edit the unit to match your host.

## Run with Docker

```bash
./docker/docker-run.sh
```

Put your existing keypair at `./shredstream-keypair.json` first (it is git-ignored) and run the script from the repo root. It clones `no-limit-nodes/shredstream-proxy` into `./shredstream-proxy` (or pulls the latest if it is already there), builds the image from source as `shredstream-proxy`, and starts a container named `shredstream-proxy` with `--network host`, `--restart unless-stopped`, `RUST_LOG=info` and the keypair mounted read-only at `/app/shredstream-keypair.json`. It is safe to run again: it updates the source, rebuilds, and replaces the old container.

## Configuration

Every flag can also be set as an environment variable: upper case, underscores. See [`.env.example`](.env.example).

| Flag | Environment variable | Value in these files | Notes |
|---|---|---|---|
| `--block-engine-url` | `BLOCK_ENGINE_URL` | `https://fra.jito.nolimitnodes.com` | The only change from a Jito setup |
| `--auth-keypair` | `AUTH_KEYPAIR` | `/app/shredstream-keypair.json` (Docker), `/etc/shredstream/keypair.json` (systemd) | Your existing keypair. Register its public key only |
| `--desired-regions` | `DESIRED_REGIONS` | `frankfurt` | Required by the CLI. The gateway serves Frankfurt only |
| `--dest-ip-ports` | `DEST_IP_PORTS` | `127.0.0.1:8001` | Comma-separated `IP:PORT` list of consumers |
| `--src-bind-port` | `SRC_BIND_PORT` | `20000` | UDP port the proxy listens on for shreds |

The full flag list (multicast, dynamic endpoint discovery, the gRPC entry service and more) is in the [shredstream-proxy README](https://github.com/no-limit-nodes/shredstream-proxy#cli-reference).

## Health check and troubleshooting

```bash
./scripts/check-shreds.sh
```

This runs `sudo tcpdump -n -i any 'udp and dst port 20000' -c 20` and captures 20 packets on the proxy's listen port.

- **No packets:** the firewall or network is blocking UDP 20000, or the public key isn't registered yet.
- **Packets in tcpdump, nothing in the proxy:** they're being dropped on the machine. tcpdump sees packets before the host firewall does, so check ufw or iptables.
- **Proxy stopped with `Error: Shutdown`?** See [Jito shredstream proxy stopped working](https://nolimitnodes.com/blog/jito-shredstream-proxy-stopped-working).

## Use cases

- **Keep a validator's shred feed running** by forwarding to its TVU port after the ShredStream shutdown
- **Feed a trading bot** that already reads shreds from a local UDP port, with no code change
- **Run the proxy as a managed service** under systemd or Docker with automatic restarts
- **Verify a new setup** with a tcpdump packet check before you debug the proxy itself

## How it works

`jito-shredstream-proxy shredstream` authenticates to the block engine URL with your keypair, then listens for shreds on UDP `--src-bind-port` (20000) and forwards every shred it receives to each `--dest-ip-ports` destination. NoLimitNodes whitelists your keypair's public key and sends shreds from the source IP shown in the dashboard, so the only firewall rule you need is UDP 20000 from that IP. Everything downstream of the proxy stays the same as with Jito.

## Proxy vs push feed: when to pick which

- **Use this proxy setup ([NoLimitNodes Jito Shreds](https://nolimitnodes.com/products/jito-shreds))** when you want to keep `jito-shredstream-proxy`, your keypair and your `--dest-ip-ports` exactly as they are, or when you use the proxy's gRPC entry service.
- **Use a push feed ([NoLimitNodes Shredstream](https://nolimitnodes.com/products/shredstream))** when you would rather not run a proxy at all. Shreds go straight to verified `IPv4:port` destinations. The [jito-shredstream-alternative](https://github.com/no-limit-nodes/jito-shredstream-alternative) kit has the migration checklist and tools to compare two feeds.

## Repo layout

```text
jito-shredstream-proxy-setup/
├── .env.example                      # the flags as environment variables
├── .gitignore                        # keeps keypairs and .env out of git
├── README.md
├── docker/
│   └── docker-run.sh                 # builds and runs the proxy in Docker
├── scripts/
│   ├── build-from-source.sh          # builds the proxy with cargo
│   ├── check-shreds.sh               # tcpdump check for shreds on UDP 20000
│   ├── install-binary.sh             # downloads the prebuilt proxy and verifies its SHA-256
│   └── run.sh                        # runs the proxy in the foreground
└── systemd/
    └── shredstream-proxy.service     # systemd unit
```

## FAQ

<details>
<summary><b>Does jito-shredstream-proxy still work after the shutdown?</b></summary>

The binary still works, but Jito's block engine no longer serves ShredStream. Point `--block-engine-url` at `https://fra.jito.nolimitnodes.com`, keep your auth keypair, and register its public key with NoLimitNodes. Use the prebuilt binary from `no-limit-nodes/shredstream-proxy`, which removes Jito's end-of-life kill switch that stops the upstream proxy.
</details>

<details>
<summary><b>Why did my proxy stop with Error: Shutdown?</b></summary>

The [proxy stopped working](https://nolimitnodes.com/blog/jito-shredstream-proxy-stopped-working) post walks through this error and the fix. In short, the upstream Jito proxy shipped an end-of-life kill switch for the ShredStream shutdown, and the NoLimitNodes fork removes it. Install the fork with `./scripts/install-binary.sh` and point it at the NoLimitNodes gateway.
</details>

<details>
<summary><b>What block engine URL should I use?</b></summary>

Use `https://fra.jito.nolimitnodes.com`. It is the NoLimitNodes Jito Shreds gateway in Frankfurt, and it is the only value you need to change in an existing Jito setup. Pass it as `--block-engine-url` or the `BLOCK_ENGINE_URL` environment variable. Set `--desired-regions frankfurt`, because the CLI requires at least one region.
</details>

<details>
<summary><b>Do I need a new keypair?</b></summary>

No. Keep the auth keypair you used with Jito, or create one with `solana-keygen new`. Register only its public key in the NoLimitNodes dashboard, using `solana-keygen pubkey shredstream-keypair.json` to print it. The keypair is only used to log in, does not need funds, and should never be shared or committed.
</details>

<details>
<summary><b>Which port do shreds arrive on?</b></summary>

UDP 20000, the proxy's default `--src-bind-port`. Allow it from the source IP shown in the dashboard, for example with `sudo ufw allow from <SOURCE_IP> to any port 20000 proto udp`. The proxy then forwards shreds to your `--dest-ip-ports`, which is `127.0.0.1:8001` in these files. Change it to your consumer's address.
</details>

<details>
<summary><b>How do I check that shreds are reaching my server?</b></summary>

Run `./scripts/check-shreds.sh`, which captures 20 UDP packets on port 20000 with tcpdump. No packets means the network or firewall is blocking the port, or your public key is not registered. Packets in tcpdump but none in the proxy means the host firewall is dropping them, because tcpdump sees packets first.
</details>

<details>
<summary><b>How much does Jito Shreds cost?</b></summary>

According to the [shredstream-proxy README](https://github.com/no-limit-nodes/shredstream-proxy#access), Jito Shreds is $100/month with a 2-hour trial per account, managed in the NoLimitNodes dashboard. The trial is enough to confirm shreds reach your server with `./scripts/check-shreds.sh`. Check the [Jito shreds pricing](https://nolimitnodes.com/blog/jito-shreds-pricing) post and the [pricing page](https://nolimitnodes.com/pricing) for current terms before you subscribe.
</details>

## Learn more on NoLimitNodes Academy

- [Ways to get real-time Solana data, compared](https://nolimitnodes.com/academy/ways-to-get-real-time-solana-data-compared): how raw shreds compare with gRPC, WebSocket and decoded streams.
- [What is a Solana RPC node?](https://nolimitnodes.com/academy/what-is-a-solana-rpc-node): background for operators forwarding shreds to an RPC node or validator.
- [Solana slots, blocks and commitment explained](https://nolimitnodes.com/academy/solana-slots-blocks-commitment-explained): what the slots in each shred mean.
- [NoLimitNodes Academy](https://nolimitnodes.com/academy): all guides, workbooks and walkthroughs.

## Contributing

Issues and pull requests are welcome, for example units or scripts for other distros. Never include a keypair file in a pull request.

## License

This repo does not include a license file. The proxy it installs, [no-limit-nodes/shredstream-proxy](https://github.com/no-limit-nodes/shredstream-proxy), is based on `jito-labs/shredstream-proxy` and licensed under the Apache License 2.0.

## Related resources

**NoLimitNodes**

- [NoLimitNodes Jito Shreds](https://nolimitnodes.com/products/jito-shreds): the gateway these files point at
- [NoLimitNodes Shredstream](https://nolimitnodes.com/products/shredstream): push feed with no proxy to run
- [Shredstream docs](https://nolimitnodes.com/docs/api-reference/shredstream/overview), [Jito client](https://nolimitnodes.com/docs/api-reference/shredstream/jito-client), [firewall](https://nolimitnodes.com/docs/api-reference/shredstream/firewall) and [troubleshooting](https://nolimitnodes.com/docs/api-reference/shredstream/troubleshooting)
- [Jito ShredStream vs NoLimitNodes](https://nolimitnodes.com/compare/jito-shredstream-vs-nolimitnodes)

**Blog**

- [Jito shredstream proxy setup guide](https://nolimitnodes.com/blog/jito-shredstream-proxy-setup)
- [Jito shredstream proxy stopped working](https://nolimitnodes.com/blog/jito-shredstream-proxy-stopped-working)
- [Jito ShredStream alternative](https://nolimitnodes.com/blog/jito-shredstream-alternative)
- [Solana Shredstream guide](https://nolimitnodes.com/blog/solana-shredstream-guide)
- [What are Jito shreds?](https://nolimitnodes.com/blog/what-are-jito-shreds)
- [How to decode Jito shreds](https://nolimitnodes.com/blog/decode-jito-shreds)
- [Jito shreds pricing](https://nolimitnodes.com/blog/jito-shreds-pricing)

**Companion repos**

- Proxy source: [no-limit-nodes/shredstream-proxy](https://github.com/no-limit-nodes/shredstream-proxy)
- Migration kit and feed comparison tools: [no-limit-nodes/jito-shredstream-alternative](https://github.com/no-limit-nodes/jito-shredstream-alternative)

**External**

- [Jito low-latency transaction feed docs](https://docs.jito.wtf/lowlatencytxnfeed/)
- [jito-labs/shredstream-proxy](https://github.com/jito-labs/shredstream-proxy)
- [systemd.service manual](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html)

---

<p align="center">
  <b>Ready to get your proxy receiving shreds again?</b><br>
  Create a NoLimitNodes account at <a href="https://app.nolimitnodes.com/register"><b>app.nolimitnodes.com/register</b></a>, add Jito Shreds and register your public key.
</p>
