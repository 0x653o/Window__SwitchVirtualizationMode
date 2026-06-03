# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- Runtime files (action log, state snapshot, BCD backup) are now written to a
  `credential_local` subfolder next to the script, created automatically on first
  run, instead of sitting loose in the script directory.

## [1.1] - 2026-06-04

### Added
- **Save Current State** (option 12) — snapshots your full virtualization
  configuration (hypervisor launch type, Memory Integrity, Firmware Protection,
  VBS, GPU HAGS, and the Virtual Machine Platform / WSL / Windows Hypervisor
  Platform feature states) to a plain-text `SwitchVirtMode.state` file next to
  the script.
- **Restore Saved State** (option 13) — re-applies a saved snapshot exactly, so
  you can return to your customized setup in one step (e.g. after Full VMware Mode).
- **Automatic safety net** — Full VMware / Full WSL2 modes auto-snapshot the
  current state the first time (if no snapshot exists yet), so a revert point is
  always available.
- **Dashboard snapshot indicator** — the menu header shows whether a snapshot is
  saved and when it was taken.

### Notes
- Pure batch, **no DLLs or dependencies** — the snapshot is a human-readable text
  file with no registry footprint of its own; deleting the folder leaves nothing behind.
- Feature states are read via a culture-invariant PowerShell enum, so it works
  correctly on non-English Windows.

## [1.0] - 2026-06-03

### Added
- **Live status dashboard** — hypervisor, Memory Integrity, Firmware Protection,
  and GPU HAGS state shown live in the menu header.
- **Hypervisor quick-switch** — toggle `hypervisorlaunchtype` between VMware /
  Proxmox (OFF) and WSL2 / Hyper-V (AUTO).
- **One-Click Full VMware Mode** — applies every step of the Samsung Galaxy Book
  VT-x guide: hypervisor OFF + Memory Integrity OFF + Firmware Protection OFF +
  VBS OFF + Virtual Machine Platform and Windows Hypervisor Platform disabled.
- **One-Click Full WSL2 Mode** — hypervisor AUTO + Virtual Machine Platform + WSL.
- **Feature toggles** — Memory Integrity, Firmware Protection, WSL, Virtual
  Machine Platform, Windows Hypervisor Platform, and GPU HAGS.
- **System Status Report** — CPU architecture (Intel / AMD / ARM64), BIOS
  VT-x/AMD-V firmware status, and a table of relevant Windows optional features.
- **Safety tools** — System Restore Point creation and BCD backup/restore.
- **Action logging** — every change is timestamped to `SwitchVirtMode.log`.
- Project scaffolding: README, MIT `LICENSE`, and `.gitignore`.
