⚠️ _*In heavy development. No support provided. May not work, may crash your computer, may singe your jaffles.*_ ⚠️

# Getting started

![CI](https://github.com/xmm7360/xmm7360-pci/workflows/CI/badge.svg)

## What

Driver for Fibocom L850-GL / Intel XMM7360 (PCI ID 8086:7360).

Please see [DEVICES.md](DEVICES.md) a list of devices this has been tested on.

## How

Please see [INSTALLING.md](INSTALLING.md) for details on how to setup this driver on your system.

### Dependencies

- build-essential
- python3-pyroute2
- python3-configargparse
- dkms (optional, for automatic rebuilds on kernel updates)

### DKMS

Use the repo helper to register the current checkout with DKMS:

- `make dkms-install`
- `make dkms-status`
- `make dkms-remove`

The DKMS package version is derived from the current git revision and gets a
`-dirty` suffix when the working tree has uncommitted changes.

## Status

This release supports native IP.

To test:

- `sudo pip install --user pyroute2 ConfigArgParse`
- `make && make load`
- If your sim has pin enabled, run `echo "AT+CPIN=\"0000\"" | sudo tee -a /dev/ttyXMM1`. Replace `0000` with your pin code.
- `sudo python3 rpc/open_xdatachannel.py --apn your.apn.here` (or you can create the xmm7360.ini from the sample and edit the apn)
- pray (if applicable)

> If your sim has pin enabled, run `echo "AT+CPIN=\"0000\"" | sudo tee -a /dev/ttyXMM1`. Replace `0000` with your pin code.

You should receive a `wwan0` interface, with an IP, and a default route.

## Next

Involvement from someone involved in modem control projects like ModemManager
would be welcome to shape the kernel interfaces so it's not too horrible to
bring up.

Power management support is absent. The modem, as configured, turns off during
suspend, and needs to be reconfigured on resume.
