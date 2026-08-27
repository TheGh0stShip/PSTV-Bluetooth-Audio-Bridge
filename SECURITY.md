# Security Policy

## Supported versions

Security fixes are provided for the latest release.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting feature for issues involving credential exposure, unsafe installer behavior, command injection, or appliance remote access. Do not publish secrets or exploit details in a public issue.

## Sensitive files

Never share:

- `config/admin-password.txt`
- `config/hostkey.txt`
- `/var/lib/bluetooth` from an installed appliance
- VMware memory/suspend files (`*.vmem`, `*.vmss`)
- Raw Bluetooth captures unless device addresses have been reviewed

The official release image intentionally contains none of these.
