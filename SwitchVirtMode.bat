@echo off
setlocal EnableExtensions DisableDelayedExpansion
cls
title Advanced Hypervisor ^& Virtualization Manager v3.0
color 0B

:: =====================================================================
:: Name:        SwitchVirtMode.bat
:: Description: Manage Windows Hypervisor, Core Isolation (Memory
::              Integrity), WSL / Virtual Machine Platform features,
::              GPU Hardware Acceleration, and verify CPU Virtualization.
:: Version:     3.0
:: =====================================================================

set "LOGFILE=%~dp0SwitchVirtMode.log"
set "BCDBACKUP=%~dp0bcd_backup.bcd"

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
call :read_status

echo =================================================================
echo         ADVANCED HYPERVISOR ^& VIRTUALIZATION MANAGER  v3.0
echo =================================================================
echo   Hypervisor (bcdedit) : %HV_LABEL%
echo   Memory Integrity     : %MI_STATUS%
echo   GPU HAGS             : %HAGS_STATUS%
echo =================================================================
echo.
echo   [1]  System Status Report (CPU, Virtualization, Features)
echo.
echo   --- Quick Switch ---------------------------------------------
echo   [2]  Enable VMware / Proxmox Mode   (Hypervisor OFF)
echo   [3]  Enable WSL2 / Hyper-V Mode      (Hypervisor AUTO)
echo   [4]  One-Click FULL VMware Mode      (Hypervisor OFF + Mem Integrity OFF)
echo   [5]  One-Click FULL WSL2 Mode        (Hypervisor AUTO + VMP/WSL ON)
echo.
echo   --- Feature Toggles ------------------------------------------
echo   [6]  Toggle Memory Integrity (Core Isolation)
echo   [7]  Toggle WSL Windows Feature
echo   [8]  Toggle Virtual Machine Platform Feature
echo   [9]  Toggle GPU Hardware Acceleration (HAGS)
echo.
echo   --- Safety / Tools -------------------------------------------
echo   [10] Create System Restore Point
echo   [11] Backup current Boot Configuration (BCD)
echo   [12] View Log File
echo.
echo   [0]  Exit
echo.
set /p "choice=Select an option: "

if "%choice%"=="1"  goto verify_virt
if "%choice%"=="2"  goto vmware
if "%choice%"=="3"  goto wsl_mode
if "%choice%"=="4"  goto full_vmware
if "%choice%"=="5"  goto full_wsl
if "%choice%"=="6"  goto toggle_mi
if "%choice%"=="7"  goto toggle_wsl
if "%choice%"=="8"  goto toggle_vmp
if "%choice%"=="9"  goto toggle_hags
if "%choice%"=="10" goto restore_point
if "%choice%"=="11" goto backup_bcd
if "%choice%"=="12" goto view_log
if "%choice%"=="0"  goto end
goto menu


:: =====================================================================
:: STATUS READER  (fast registry / bcdedit reads for the dashboard)
:: =====================================================================
:read_status
set "HV_STATUS=auto"
for /f "tokens=2*" %%A in ('bcdedit ^| findstr /i "hypervisorlaunchtype"') do set "HV_STATUS=%%A"
if /i "%HV_STATUS%"=="off" (
    set "HV_LABEL=OFF   -^> VMware / Proxmox Mode"
) else (
    set "HV_LABEL=AUTO  -^> WSL2 / Hyper-V Mode"
)

set "MI_STATUS=Not Configured"
set "MI_RAW="
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled 2^>nul ^| findstr /i "Enabled"') do set "MI_RAW=%%A"
if "%MI_RAW%"=="0x1" set "MI_STATUS=ON  (forces hypervisor to load)"
if "%MI_RAW%"=="0x0" set "MI_STATUS=OFF"

set "HAGS_STATUS=Default / Not Set"
set "HAGS_RAW="
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode 2^>nul ^| findstr /i "HwSchMode"') do set "HAGS_RAW=%%A"
if "%HAGS_RAW%"=="0x2" set "HAGS_STATUS=ENABLED"
if "%HAGS_RAW%"=="0x1" set "HAGS_STATUS=DISABLED"
goto :eof


:: =====================================================================
:: OPTION 1: System Status Report
:: =====================================================================
:verify_virt
cls
color 0E
echo =====================================================
echo    SYSTEM STATUS REPORT
echo =====================================================
echo.
echo [CPU Architecture]
echo Identifier: %PROCESSOR_IDENTIFIER%
echo Arch Type:  %PROCESSOR_ARCHITECTURE%
echo %PROCESSOR_ARCHITECTURE% | findstr /i "ARM" >nul
if %errorlevel% equ 0 (
    echo Detected:   ARM Architecture (Snapdragon / Apple Silicon)
) else (
    echo Detected:   x86/x64 Architecture (Intel / AMD)
)
echo.
echo [Hardware Virtualization Firmware]
for /f "skip=1 tokens=*" %%V in ('wmic cpu get VirtualizationFirmwareEnabled 2^>nul') do (
    if not "%%V"=="" echo VT-x / AMD-V enabled in BIOS: %%V
)
echo If TRUE, virtualization is enabled in BIOS/UEFI. If FALSE, enable it in firmware.
echo.
echo [Boot / Hypervisor]
call :read_status
echo Hypervisor launch type: %HV_STATUS%
echo Memory Integrity:       %MI_STATUS%
echo GPU HAGS:               %HAGS_STATUS%
echo.
echo [Windows Optional Features]  (querying, please wait...)
powershell -NoProfile -Command "Get-WindowsOptionalFeature -Online | Where-Object FeatureName -in 'Microsoft-Windows-Subsystem-Linux','VirtualMachinePlatform','Microsoft-Hyper-V-All','HypervisorPlatform','Containers-DisposableClientVM' | Sort-Object FeatureName | Format-Table FeatureName, State -AutoSize" 2>nul
echo.
pause
goto menu


:: =====================================================================
:: OPTION 2: VMware / Proxmox Mode
:: =====================================================================
:vmware
cls
color 0A
echo =====================================================
echo APPLYING VMWARE / PROXMOX MODE...
echo =====================================================
bcdedit /set hypervisorlaunchtype off
call :log "Set hypervisorlaunchtype OFF (VMware/Proxmox mode)"
echo.
echo [SUCCESS] Hypervisor disabled. Nested VT-x will pass through to VMware.
echo WSL2 will NOT work until you switch back.
if "%MI_RAW%"=="0x1" (
    echo.
    echo [WARNING] Memory Integrity is ON. Windows may still force the
    echo hypervisor to load. Use option [4] for a full VMware switch.
)
goto restart_prompt


:: =====================================================================
:: OPTION 3: WSL2 / Hyper-V Mode
:: =====================================================================
:wsl_mode
cls
color 0A
echo =====================================================
echo APPLYING WSL2 / HYPER-V MODE...
echo =====================================================
bcdedit /set hypervisorlaunchtype auto
call :log "Set hypervisorlaunchtype AUTO (WSL2/Hyper-V mode)"
echo.
echo [SUCCESS] Hypervisor set to Auto. WSL2, Docker Desktop, and
echo Windows Sandbox will now work. VMware nested VT-x will be blocked.
goto restart_prompt


:: =====================================================================
:: OPTION 4: One-Click FULL VMware Mode
:: =====================================================================
:full_vmware
cls
color 0A
echo =====================================================
echo APPLYING FULL VMWARE / PROXMOX MODE...
echo =====================================================
echo This turns the hypervisor OFF and disables Memory Integrity so
echo Windows fully releases VT-x to VMware for nested virtualization.
echo.
set /p "ok=Proceed? (Y/N): "
if /i not "%ok%"=="Y" goto menu
bcdedit /set hypervisorlaunchtype off
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f
call :log "FULL VMware mode: hypervisor OFF + Memory Integrity OFF"
echo.
echo [SUCCESS] Hypervisor OFF and Memory Integrity OFF.
echo VMware nested virtualization is now fully unblocked.
goto restart_prompt


:: =====================================================================
:: OPTION 5: One-Click FULL WSL2 Mode
:: =====================================================================
:full_wsl
cls
color 0A
echo =====================================================
echo APPLYING FULL WSL2 / HYPER-V MODE...
echo =====================================================
echo This turns the hypervisor AUTO and enables the Virtual Machine
echo Platform + WSL features required for WSL2 and Docker Desktop.
echo.
set /p "ok=Proceed? (Y/N): "
if /i not "%ok%"=="Y" goto menu
bcdedit /set hypervisorlaunchtype auto
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
call :log "FULL WSL2 mode: hypervisor AUTO + VMP + WSL enabled"
echo.
echo [SUCCESS] Hypervisor AUTO, Virtual Machine Platform and WSL enabled.
goto restart_prompt


:: =====================================================================
:: OPTION 6: Toggle Memory Integrity (Core Isolation)
:: =====================================================================
:toggle_mi
cls
color 0E
echo =====================================================
echo        MEMORY INTEGRITY (CORE ISOLATION)
echo =====================================================
echo Current state: %MI_STATUS%
echo.
echo When ON, Windows loads the hypervisor for security even if
echo bcdedit is set to OFF, which blocks VMware nested VT-x.
echo.
echo [A] Enable Memory Integrity
echo [B] Disable Memory Integrity
echo [C] Go Back
echo.
set /p "mi_choice=Select A, B, or C: "
if /i "%mi_choice%"=="A" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f
    call :log "Memory Integrity ENABLED"
    echo Memory Integrity ENABLED.
    goto restart_prompt
)
if /i "%mi_choice%"=="B" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f
    call :log "Memory Integrity DISABLED"
    echo Memory Integrity DISABLED.
    goto restart_prompt
)
goto menu


:: =====================================================================
:: OPTION 7: Toggle WSL Windows Feature
:: =====================================================================
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
set /p "wsl_choice=Select A, B, or C: "
if /i "%wsl_choice%"=="A" (
    echo Enabling Windows Subsystem for Linux...
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    call :log "WSL feature ENABLED"
    goto restart_prompt
)
if /i "%wsl_choice%"=="B" (
    echo Disabling Windows Subsystem for Linux...
    dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
    call :log "WSL feature DISABLED"
    goto restart_prompt
)
goto menu


:: =====================================================================
:: OPTION 8: Toggle Virtual Machine Platform Feature
:: =====================================================================
:toggle_vmp
cls
color 0E
echo =====================================================
echo        VIRTUAL MACHINE PLATFORM FEATURE
echo =====================================================
echo Required by WSL2 and Docker Desktop's WSL2 backend.
echo.
echo [A] Enable Virtual Machine Platform
echo [B] Disable Virtual Machine Platform
echo [C] Go Back
echo.
set /p "vmp_choice=Select A, B, or C: "
if /i "%vmp_choice%"=="A" (
    echo Enabling Virtual Machine Platform...
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    call :log "Virtual Machine Platform ENABLED"
    goto restart_prompt
)
if /i "%vmp_choice%"=="B" (
    echo Disabling Virtual Machine Platform...
    dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
    call :log "Virtual Machine Platform DISABLED"
    goto restart_prompt
)
goto menu


:: =====================================================================
:: OPTION 9: Toggle GPU Hardware Acceleration (HAGS)
:: =====================================================================
:toggle_hags
cls
color 0D
echo =====================================================
echo      GPU HARDWARE ACCELERATION SCHEDULING (HAGS)
echo =====================================================
echo Current state: %HAGS_STATUS%
echo.
echo HAGS reduces latency and improves performance, but can
echo conflict with heavy VM graphics emulation.
echo.
echo [A] Enable Hardware Acceleration (HAGS)
echo [B] Disable Hardware Acceleration (HAGS)
echo [C] Go Back
echo.
set /p "hags_choice=Select A, B, or C: "
if /i "%hags_choice%"=="A" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f
    call :log "HAGS ENABLED"
    echo Hardware Acceleration ENABLED.
    goto restart_prompt
)
if /i "%hags_choice%"=="B" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 1 /f
    call :log "HAGS DISABLED"
    echo Hardware Acceleration DISABLED.
    goto restart_prompt
)
goto menu


:: =====================================================================
:: OPTION 10: Create System Restore Point
:: =====================================================================
:restore_point
cls
color 0D
echo =====================================================
echo            CREATE SYSTEM RESTORE POINT
echo =====================================================
echo Creating a restore point named "SwitchVirtMode"...
echo (System Protection must be enabled on the system drive.)
echo.
powershell -NoProfile -Command "try { Enable-ComputerRestore -Drive $env:SystemDrive -ErrorAction SilentlyContinue; Checkpoint-Computer -Description 'SwitchVirtMode' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; Write-Host '[SUCCESS] Restore point created.' } catch { Write-Host '[FAILED] ' $_.Exception.Message }"
call :log "Attempted System Restore Point creation"
echo.
pause
goto menu


:: =====================================================================
:: OPTION 11: Backup current Boot Configuration (BCD)
:: =====================================================================
:backup_bcd
cls
color 0D
echo =====================================================
echo          BACKUP BOOT CONFIGURATION (BCD)
echo =====================================================
echo Exporting current BCD store to:
echo   %BCDBACKUP%
echo.
bcdedit /export "%BCDBACKUP%"
if %errorlevel% equ 0 (
    echo [SUCCESS] Backup saved.
    echo To restore later, run:  bcdedit /import "%BCDBACKUP%"
    call :log "BCD exported to %BCDBACKUP%"
) else (
    echo [FAILED] Could not export BCD store.
)
echo.
pause
goto menu


:: =====================================================================
:: OPTION 12: View Log File
:: =====================================================================
:view_log
cls
color 0F
echo =====================================================
echo                 ACTION LOG
echo =====================================================
if exist "%LOGFILE%" (
    type "%LOGFILE%"
) else (
    echo No actions have been logged yet.
)
echo.
pause
goto menu


:: =====================================================================
:: LOG HELPER   ( call :log "message" )
:: =====================================================================
:log
echo [%date% %time%] %~1>> "%LOGFILE%"
goto :eof


:: =====================================================================
:: RESTART PROMPT
:: =====================================================================
:restart_prompt
echo.
echo =====================================================
color 0C
set /p "reboot=A system restart is required. Restart now? (Y/N): "
if /i "%reboot%"=="Y" (
    call :log "User initiated reboot"
    echo Restarting in 5 seconds...
    shutdown /r /t 5
    exit
)
echo.
echo Please restart your computer manually to apply the changes.
pause
goto menu


:end
exit
