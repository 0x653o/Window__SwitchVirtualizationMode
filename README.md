# Advanced Hypervisor & Virtualization Manager

A powerful, all-in-one batch script for Windows 11 designed to resolve nested virtualization conflicts, manage Windows Subsystem for Linux (WSL), toggle GPU hardware acceleration, and verify your CPU's hardware virtualization status.

## ❗ The Problem

Windows 11 takes exclusive hardware-level control of virtualization features (Intel VT-x / AMD-V) to run WSL2 and Core Isolation. Because Windows hogs these resources, third-party hypervisors like VMware Workstation are blocked from passing nested virtualization through to guest VMs.

This creates a conflict: **You cannot run WSL2 and a nested VMware VM (like Proxmox) at the exact same time.** This script automates the fix.

## ✨ Features

* **🔍 Architecture & Virtualization Check:** Automatically detects your CPU architecture (Intel / AMD / ARM64) and reads your system's firmware flags to verify if Hardware Virtualization (VT-x/AMD-V) is actively enabled in your BIOS/UEFI.
* **🔁 Hypervisor Quick-Switch (Original):** Seamlessly toggle `hypervisorlaunchtype` between:
  * **VMware / Proxmox Mode:** Turns the Windows Hypervisor `off`, giving VMware full, exclusive access to VT-x for nested virtualization.
  * **WSL2 / Hyper-V Mode:** Turns the Windows Hypervisor to `auto`, restoring WSL2, Docker Desktop, and Windows Sandbox functionality.
* **🐧 WSL Feature Manager:** Install or fully remove the Windows Subsystem for Linux core features directly via Windows DISM commands.
* **🎮 Hardware Acceleration (HAGS) Toggle:** Turn Windows Hardware-Accelerated GPU Scheduling on or off via the registry. Useful for troubleshooting graphics rendering issues or latency inside virtual environments.

## 🚀 How to Use

1. Download `SwitchVirtMode.bat` to your desktop.
2. **Right-click** the file and select **"Run as Administrator"**. *(The script includes a failsafe and will block execution if not run as Admin).*
3. Select an option from the main menu (1-6).
4. Type `Y` when prompted to reboot your system. **A reboot is absolutely mandatory** for hypervisor and registry changes to take effect.

## ⚠️ Important Notes

* **Core Isolation / Memory Integrity:** If Windows "Memory Integrity" is turned ON, Windows security features may force the hypervisor to load in the background, ignoring this script. If VMware still throws `VT-x` or `VPMC` errors after switching to VMware Mode, go to **Windows Security → Device Security → Core Isolation** and turn **Memory Integrity OFF**.
* **Safety:** This script is perfectly safe. It does not download any external tools; it relies entirely on built-in Microsoft utilities (`bcdedit`, `wmic`, `dism`, and `reg`).

## License

[MIT License](LICENSE). Feel free to fork, use, and modify!
