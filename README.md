# Advanced Hypervisor & Virtualization Manager

A powerful, all-in-one batch script for Windows 11 designed to resolve nested virtualization conflicts, manage Windows Subsystem for Linux (WSL), toggle GPU hardware acceleration, and verify your CPU's hardware virtualization status.

## ❗ The Problem

Windows 11 takes exclusive hardware-level control of virtualization features (Intel VT-x / AMD-V) to run WSL2 and Core Isolation. Because Windows hogs these resources, third-party hypervisors like VMware Workstation are blocked from passing nested virtualization through to guest VMs.

This creates a conflict: **You cannot run WSL2 and a nested VMware VM (like Proxmox) at the exact same time.** This script automates the fix.

## ✨ Features

### Live Status Dashboard
The main menu shows the **current state** of your hypervisor, Memory Integrity (Core Isolation), and GPU HAGS at a glance — read live from `bcdedit` and the registry every time the menu refreshes.

### Hypervisor Quick-Switch
Seamlessly toggle `hypervisorlaunchtype` between:
* **VMware / Proxmox Mode:** Turns the Windows Hypervisor `off`, giving VMware full, exclusive access to VT-x for nested virtualization.
* **WSL2 / Hyper-V Mode:** Turns the Windows Hypervisor to `auto`, restoring WSL2, Docker Desktop, and Windows Sandbox functionality.

### One-Click Combined Modes
* **🟢 Full VMware Mode:** Hypervisor `off` **and** Memory Integrity `off` in a single action — fully releases VT-x to VMware (Memory Integrity alone can silently force the hypervisor back on).
* **🔵 Full WSL2 Mode:** Hypervisor `auto` **and** enables Virtual Machine Platform + WSL features required for WSL2 / Docker Desktop.

### Feature Toggles
* **🛡️ Memory Integrity (Core Isolation):** Enable/disable the setting that forces the hypervisor to load for security — the usual culprit behind VMware `VT-x` errors.
* **🐧 WSL Feature:** Install or remove the Windows Subsystem for Linux core feature via DISM.
* **📦 Virtual Machine Platform:** Toggle the feature required by the WSL2 backend.
* **🎮 GPU Hardware Acceleration (HAGS):** Turn Hardware-Accelerated GPU Scheduling on/off — useful when troubleshooting VM graphics latency.

### Diagnostics & Safety
* **🔍 System Status Report:** CPU architecture (Intel / AMD / ARM64), BIOS VT-x/AMD-V firmware status, and a live table of relevant Windows optional features (WSL, VMP, Hyper-V, Hypervisor Platform, Sandbox).
* **💾 System Restore Point:** Create a named restore point before making changes.
* **🗂️ BCD Backup:** Export the current Boot Configuration store, with the exact `bcdedit /import` command to roll back.
* **📝 Action Log:** Every change is timestamped to `SwitchVirtMode.log` and viewable from the menu.

## 🚀 How to Use

1. Download `SwitchVirtMode.bat`.
2. **Right-click** the file and select **"Run as Administrator"**. *(The script includes a failsafe and will block execution if not run as Admin).*
3. Pick an option from the menu. For most users switching to VMware, **option 4 (Full VMware Mode)** is the one-click answer.
4. Type `Y` when prompted to reboot. **A reboot is mandatory** for hypervisor and registry changes to take effect.

## ⚠️ Important Notes

* **Core Isolation / Memory Integrity:** If Windows "Memory Integrity" is turned ON, Windows security features may force the hypervisor to load in the background, ignoring this script. If VMware still throws `VT-x` or `VPMC` errors after switching to VMware Mode, go to **Windows Security → Device Security → Core Isolation** and turn **Memory Integrity OFF**.
* **Safety:** This script is perfectly safe. It does not download any external tools; it relies entirely on built-in Microsoft utilities (`bcdedit`, `wmic`, `dism`, and `reg`).

## License

[MIT License](LICENSE). Feel free to fork, use, and modify!
