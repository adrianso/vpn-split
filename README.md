# vpn-split

Poor-man's split tunneling for AWS Client VPN. macOS only.

## Install

```
git clone https://github.com/adrianso/vpn-split.git
cd vpn-split
./install.sh
```

You'll be prompted for the hostname to route through the VPN. Re-run `./install.sh` to change it.

## Uninstall

```
./uninstall.sh
```

## Why?

AWS Client VPN with SAML auth forces all traffic through the VPN tunnel (full tunnel). The server-side split tunnel setting is disabled and we can't change it. The AWS VPN Client strips custom OpenVPN directives like `pull-filter`, so there's no client-side config fix either.

This means browsing, streaming, and everything else routes through the VPN while connected.

## How it works

OpenVPN implements full tunnel by pushing two catch-all routes (`0/1` and `128.0/1`) that override the default gateway without replacing it. This script:

1. Detects VPN connection by watching for the `0/1` route
2. Deletes the `0/1` and `128.0/1` catch-all routes
3. Resolves the target hostname (handles multiple IPs behind ELB)
4. Adds specific `/32` routes for each IP through the VPN gateway
5. Monitors for VPN disconnect/reconnect and re-applies as needed

The original default gateway is never touched, so all other traffic flows normally.

## Configuration

The hostname is stored in `~/.config/vpn-split/config`. Override at runtime with the `VPN_SPLIT_HOST` env var.

## Logs

```
tail -f ~/.local/var/log/vpn-split.log
```

## Manual usage

```
vpn-split watch   # watch for VPN and auto-fix routes
vpn-split fix     # one-shot fix (VPN must be connected)
```
