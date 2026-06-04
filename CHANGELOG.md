# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.2] - 2026-06-04

### Added
- **Dashboard version info** — the main menu now shows the in-box DISM
  (servicing-stack) version and the running OS image version, so you can see
  what is servicing what at a glance.
- **DISM caution banner** — a persistent reminder that DISM feature changes
  (options 4, 8, 9, 10, 13) can take several minutes and must not be
  interrupted (interrupting them corrupts the servicing stack — e.g. RPC 1726).

### Changed
- The script now always invokes the **in-box DISM** (`%SystemRoot%\System32\Dism.exe`)
  instead of whatever `dism` resolves to on `PATH`. This prevents a stray older
  DISM (e.g. a Windows ADK copy) from servicing a newer OS image and failing.

### Notes
- A version difference such as DISM `10.0.26100.x` vs OS `10.0.26200.x` is
  **expected and healthy** on Windows 11 25H2, which ships as an enablement
  package on the 24H2 (26100) servicing base — it is shown for information only,
  not as an error.

## [1.1] - 2026-06-04

### Added
- **Save Current State** (option 12) — snapshots your full virtualization
  configuration (hypervisor launch type, Memory Integrity, Firmware Protection,
  VBS, GPU HAGS, and the Virtual Machine Platform / WSL / Windows Hypervisor
  Platform feature states) to a plain-text `SwitchVirtMode.state` file inside a
  `credential_local` folder next to the script.
- **Restore Saved State** (option 13) — re-applies a saved snapshot exactly, so
  you can return to your customized setup in one step (e.g. after Full VMware Mode).
- **Automatic safety net** — Full VMware / Full WSL2 modes auto-snapshot the
  current state the first time (if no snapshot exists yet), so a revert point is
  always available.
- **Dashboard snapshot indicator** — the menu header shows whether a snapshot is
  saved and when it was taken.

### Changed
- Runtime files (action log, state snapshot, BCD backup) are written to a
  `credential_local` subfolder next to the script, created automatically on first
  run, instead of sitting loose in the script directory.

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
