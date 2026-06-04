# Advanced Hypervisor & Virtualization Manager

A powerful, all-in-one batch script for Windows 11 designed to resolve nested virtualization conflicts, manage Windows Subsystem for Linux (WSL), toggle GPU hardware acceleration, and verify your CPU's hardware virtualization status.

## ❗ The Problem

Windows 11 takes exclusive hardware-level control of virtualization features (Intel VT-x / AMD-V) to run WSL2 and Core Isolation. Because Windows hogs these resources, third-party hypervisors like VMware Workstation are blocked from passing nested virtualization through to guest VMs.

This creates a conflict: **You cannot run WSL2 and a nested VMware VM (like Proxmox) at the exact same time.** This script automates the fix.

## ✨ Features

### Live Status Dashboard
The main menu shows the **current state** of your hypervisor, Memory Integrity, Firmware Protection (both Core Isolation), and GPU HAGS at a glance — read live from `bcdedit` and the registry every time the menu refreshes.

### Hypervisor Quick-Switch
Seamlessly toggle `hypervisorlaunchtype` between:
* **VMware / Proxmox Mode:** Turns the Windows Hypervisor `off`, giving VMware full, exclusive access to VT-x for nested virtualization.
* **WSL2 / Hyper-V Mode:** Turns the Windows Hypervisor to `auto`, restoring WSL2, Docker Desktop, and Windows Sandbox functionality.

### One-Click Combined Modes
* **🟢 Full VMware Mode:** Applies **every step of the Samsung Galaxy Book VT-x guide** in one action — hypervisor `off`, Memory Integrity `off`, Firmware Protection `off`, VBS `off`, and disables both **Virtual Machine Platform** and **Windows Hypervisor Platform**. This fully releases VT-x to VMware (any one of these alone can silently force the hypervisor back on).
* **🔵 Full WSL2 Mode:** Hypervisor `auto` **and** enables Virtual Machine Platform + WSL features required for WSL2 / Docker Desktop.

### Feature Toggles
* **🛡️ Memory Integrity (Core Isolation):** Enable/disable the setting that forces the hypervisor to load for security — the usual culprit behind VMware `VT-x` errors.
* **🔥 Firmware Protection (Core Isolation):** Enable/disable System Guard Secure Launch, which (like Memory Integrity) can force the hypervisor on — Samsung Galaxy Book devices in particular.
* **🐧 WSL Feature:** Install or remove the Windows Subsystem for Linux core feature via DISM.
* **📦 Virtual Machine Platform:** Toggle the feature required by the WSL2 backend.
* **🧩 Windows Hypervisor Platform:** Toggle the third-party hypervisor API feature; the Galaxy Book guide recommends disabling it for VMware.
* **🎮 GPU Hardware Acceleration (HAGS):** Turn Hardware-Accelerated GPU Scheduling on/off — useful when troubleshooting VM graphics latency.

### Save & Revert (Snapshot)
* **💾 Save Current State:** Captures your full virtualization configuration — hypervisor launch type, Memory Integrity, Firmware Protection, VBS, HAGS, and the Virtual Machine Platform / WSL / Windows Hypervisor Platform feature states — to a plain-text `SwitchVirtMode.state` file inside a `credential_local` folder next to the script (created automatically on first run).
* **↩️ Restore Saved State:** Re-applies that snapshot exactly, so after using **Full VMware Mode** you can return to your previous customized setup in one step.
* **🔒 Automatic safety net:** The first time you run a Full VMware/WSL2 mode, the script auto-snapshots your current state (if none exists yet) so a revert point is always available. The dashboard shows whether a snapshot is saved and when.
* **🪶 No dependencies:** Pure batch — the snapshot is a human-readable text file, with **no DLLs, no installers, and no registry footprint of its own**. Delete the folder and nothing is left behind.

### Diagnostics & Safety
* **🧬 DISM / OS version info:** The dashboard shows the in-box DISM (servicing-stack) version and the running OS image version. The script always uses the in-box `System32\Dism.exe` so it matches the running image, avoiding feature-servicing failures from a stray older DISM on `PATH`. *(A 26100-vs-26200 difference is normal on Windows 11 25H2 — shown for information, not an error.)*
* **⏳ DISM caution:** A persistent banner reminds you that feature changes via DISM can take several minutes and must not be interrupted — interrupting them corrupts the servicing stack (e.g. RPC 1726).
* **🔍 System Status Report:** CPU architecture (Intel / AMD / ARM64), BIOS VT-x/AMD-V firmware status, and a live table of relevant Windows optional features (WSL, VMP, Hyper-V, Hypervisor Platform, Sandbox).
* **💾 System Restore Point:** Create a named restore point before making changes.
* **🗂️ BCD Backup:** Export the current Boot Configuration store, with the exact `bcdedit /import` command to roll back.
* **📝 Action Log:** Every change is timestamped to `credential_local\SwitchVirtMode.log` and viewable from the menu.

## 🚀 How to Use

1. Download `SwitchVirtMode.bat`.
2. **Right-click** the file and select **"Run as Administrator"**. *(The script includes a failsafe and will block execution if not run as Admin).*
3. Pick an option from the menu. For most users switching to VMware, **option 4 (Full VMware Mode)** is the one-click answer.
4. Type `Y` when prompted to reboot. **A reboot is mandatory** for hypervisor and registry changes to take effect.

## ⚠️ Important Notes

* **Core Isolation (Memory Integrity + Firmware Protection):** If either of these is ON, Windows security features may force the hypervisor to load in the background, ignoring `bcdedit`. **Option 4 (Full VMware Mode)** turns both off for you. If VMware still throws `VT-x` or `VPMC` errors, also confirm them off under **Windows Security → Device Security → Core Isolation**.
* **Samsung Galaxy Book / custom BIOS:** Some Samsung laptops ship a locked "custom BIOS" where the VT-x option is restricted at the firmware level. If `VirtualizationFirmwareEnabled` shows **FALSE** in the System Status Report (option 1), no software setting can fix it — it must be enabled in BIOS/UEFI, which may not be exposed on these devices.
* **Safety:** This script does not download any external tools; it relies entirely on built-in Microsoft utilities (`bcdedit`, `wmic`, `dism`, and `reg`).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full version history. Current release: **v1.2**.

## License

[MIT License](LICENSE). Feel free to fork, use, and modify!
