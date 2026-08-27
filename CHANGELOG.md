# Changelog

All notable changes follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow semantic versioning.

## [Unreleased]

## [1.1.0] - 2026-08-26

### Added

- Double-click `SETUP.cmd` entry point for the complete guided Windows setup.
- Reconnect-keeper health in `Status.ps1` output.

### Changed

- Request VMware's minimum practical host audio queue (about 53 ms instead of 200 ms).
- Make the 30/10 ms UltraLow profile the default and run the playback worker at modest real-time priority.
- Preserve all Windows Wi-Fi adapters unchanged during installation and everyday startup.
- Validate and document automatic trusted-PSTV reconnection after console or appliance restarts.
- Clarify that setup automatically detects standard built-in USB-attached Bluetooth radios and external USB dongles without asking for a key, PSTV MAC, or guest IP.

## [1.0.0] - 2026-08-26

### Added

- Reproducible Alpine 3.24 VMware appliance.
- BlueALSA 4.3.1 A2DP sink capped at SBC bitpool 20.
- USB 2.0 passthrough, autosuspend suppression, and no-sniff link policy.
- Keyless-for-users first-boot provisioning with an automatically generated 256-bit credential and pinned SSH host key.
- Low-latency 60/20 ms playback profile plus an optional extra-stable profile.
- Automatic USB Bluetooth radio discovery and VMware configuration.
- PSTV pairing as `PLT Focus` without a hard-coded device MAC or link key.
- Windows logon autostart, status, diagnostics, stop, and uninstall tools.
- VitaBtFix 1.1 binaries and an opt-in, backed-up VitaShell FTP installer.
- Complete setup, operation, build, architecture, and troubleshooting documentation.
