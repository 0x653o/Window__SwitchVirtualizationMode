@echo off
setlocal EnableDelayedExpansion
cls
title Advanced Hypervisor & Virtualization Manager v2.0
color 0B

:: =====================================================================
:: Name:        SwitchVirtMode.bat
:: Description: Manage Windows Hypervisor, WSL features, Hardware 
::              Acceleration, and verify CPU Virtualization support.
:: Version:     2.0
:: =====================================================================

:: --- Administrator Check ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    color 0C
    echo =====================================================
    echo    ERROR: ADMINISTRATOR PRIVILEGES REQUIRED
    echo =====================================================
    echo This script modifies Boot Data and Windows Features.
    echo Please right-click this script and select:
    echo "Run as Administrator".
    echo =====================================================
    echo.
    pause
    exit /b
)

:menu
cls
color 0B
echo =================================================================
echo         ADVANCED HYPERVISOR ^& VIRTUALIZATION MANAGER
echo =================================================================

:: --- Check Current Hypervisor Status ---
for /f "tokens=2*" %%A in ('bcdedit ^| findstr "hypervisorlaunchtype"') do set STATUS=%%A
if /i "%STATUS%"=="off" (
    echo  [!] Current Mode: VMware / Proxmox (Hypervisor OFF)
) else if /i "%STATUS%"=="Auto" (
    echo  [!] Current Mode: WSL2 / Hyper-V (Hypervisor AUTO)
) else (
    echo  [!] Current Mode: Status Unknown (Defaulting to Auto)
)
echo =================================================================
echo.
echo  [1] Verify CPU Architecture ^& Virtualization (ARM/AMD/Intel)
echo  [2] Enable VMware / Proxmox Mode (Turns OFF Hypervisor)  [ORIGINAL]
echo  [3] Enable WSL2 / Hyper-V Mode (Turns ON Hypervisor)     [ORIGINAL]
echo  [4] Toggle WSL Windows Feature (On/Off)
echo  [5] Toggle GPU Hardware Acceleration (HAGS)
echo  [6] Exit
echo.
set /p choice="Select an option (1-6): "

if "%choice%"=="1" goto verify_virt
if "%choice%"=="2" goto vmware
if "%choice%"=="3" goto wsl
if "%choice%"=="4" goto toggle_wsl
if "%choice%"=="5" goto toggle_hags
if "%choice%"=="6" goto end
goto menu


:: ---------------------------------------------------------
:: OPTION 1: Verify Architecture & Virtualization
:: ---------------------------------------------------------
:verify_virt
cls
color 0E
echo =====================================================
echo    HARDWARE VIRTUALIZATION ^& CPU VERIFICATION
echo =====================================================
echo.
echo [CPU Architecture]
echo Identifier: %PROCESSOR_IDENTIFIER%
echo Arch Type:  %PROCESSOR_ARCHITECTURE%
echo.

:: Check for ARM vs x64/x86
echo %PROCESSOR_ARCHITECTURE% | findstr /i "ARM" >nul
if %errorlevel% equ 0 (
    echo System detected as: ARM Architecture (Snapdragon/Apple Silicon)
) else (
    echo System detected as: x86/x64 Architecture (Intel/AMD)
)
echo.
echo [Virtualization Firmware Status]
wmic cpu get VirtualizationFirmwareEnabled
echo.
echo If 'VirtualizationFirmwareEnabled' is TRUE, VT-x/AMD-V is enabled in BIOS.
echo If it is FALSE, you must restart and enable it in your BIOS/UEFI settings.
echo.
pause
goto menu


:: ---------------------------------------------------------
:: OPTION 2: Original VMware / Proxmox Mode
:: ---------------------------------------------------------
:vmware
cls
color 0A
echo =====================================================
echo APPLYING VMWARE / PROXMOX MODE...
echo =====================================================
bcdedit /set hypervisorlaunchtype off
echo.
echo [SUCCESS] Hypervisor is disabled. 
echo Nested virtualization (VT-x) will now pass through to VMware.
echo WSL2 will NOT work until you switch back.
goto restart_prompt


:: ---------------------------------------------------------
:: OPTION 3: Original WSL2 / Hyper-V Mode
:: ---------------------------------------------------------
:wsl
cls
color 0A
echo =====================================================
echo APPLYING WSL2 / HYPER-V MODE...
echo =====================================================
bcdedit /set hypervisorlaunchtype auto
echo.
echo [SUCCESS] Hypervisor is set to Auto. 
echo WSL2, Docker Desktop, and Windows Sandbox will now work.
echo VMware nested VT-x will be blocked.
goto restart_prompt


:: ---------------------------------------------------------
:: OPTION 4: Toggle WSL Windows Feature
:: ---------------------------------------------------------
:toggle_wsl
cls
color 0E
echo =====================================================
echo           WSL WINDOWS FEATURE MANAGER
echo =====================================================
echo [A] Install / Enable WSL Feature
echo [B] Uninstall / Disable WSL Feature
echo [C] Go Back
echo.
set /p wsl_choice="Select A, B, or C: "

if /i "%wsl_choice%"=="A" (
    echo.
    echo Enabling Windows Subsystem for Linux...
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    echo Done.
    goto restart_prompt
)
if /i "%wsl_choice%"=="B" (
    echo.
    echo Disabling Windows Subsystem for Linux...
    dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
    echo Done.
    goto restart_prompt
)
goto menu


:: ---------------------------------------------------------
:: OPTION 5: Toggle GPU Hardware Acceleration (HAGS)
:: ---------------------------------------------------------
:toggle_hags
cls
color 0D
echo =====================================================
echo      GPU HARDWARE ACCELERATION SCHEDULING (HAGS)
echo =====================================================
echo Hardware-Accelerated GPU Scheduling reduces latency 
echo and improves performance, but can sometimes conflict 
echo with heavy VM graphics emulation.
echo.
echo [A] Enable Hardware Acceleration (HAGS)
echo [B] Disable Hardware Acceleration (HAGS)
echo [C] Go Back
echo.
set /p hags_choice="Select A, B, or C: "

if /i "%hags_choice%"=="A" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f
    echo.
    echo Hardware Acceleration ENABLED.
    goto restart_prompt
)
if /i "%hags_choice%"=="B" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 1 /f
    echo.
    echo Hardware Acceleration DISABLED.
    goto restart_prompt
)
goto menu


:: ---------------------------------------------------------
:: RESTART PROMPT
:: ---------------------------------------------------------
:restart_prompt
echo =====================================================
echo.
color 0C
set /p reboot="A system restart is required. Restart now? (Y/N): "
if /i "%reboot%"=="Y" (
    echo Restarting in 5 seconds...
    shutdown /r /t 5
) else (
    echo.
    echo Please restart your computer manually to apply the changes.
    pause
    goto menu
)
exit

:end
exit