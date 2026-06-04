@echo off
setlocal EnableExtensions DisableDelayedExpansion
cls
title Advanced Hypervisor ^& Virtualization Manager v1.2
color 0B

:: =====================================================================
:: Name:        SwitchVirtMode.bat
:: Description: Manage Windows Hypervisor, Core Isolation (Memory
::              Integrity + Firmware Protection), WSL / Virtual Machine
::              Platform / Windows Hypervisor Platform features, GPU
::              Hardware Acceleration, and verify CPU Virtualization.
:: Version:     1.2
:: =====================================================================

:: All generated files (log, state snapshot, BCD backup) live in this
:: subfolder, which is created on first run if it does not exist.
set "DATADIR=%~dp0credential_local"
set "LOGFILE=%DATADIR%\SwitchVirtMode.log"
set "BCDBACKUP=%DATADIR%\bcd_backup.bcd"
set "STATEFILE=%DATADIR%\SwitchVirtMode.state"

:: Always use the OS in-box DISM so its build matches the running image.
:: A mismatched DISM (e.g. an older ADK copy on PATH) is a common cause of
:: feature-servicing failures, so this avoids that and is version-checked below.
set "DISM=%SystemRoot%\System32\Dism.exe"

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

:: --- Ensure the data folder exists for log / state / backup files ---
if not exist "%DATADIR%" mkdir "%DATADIR%" >nul 2>&1

:: --- One-time DISM tool / OS image version compatibility check ---
call :check_versions

:menu
cls
color 0B
call :read_status

echo =================================================================
echo         ADVANCED HYPERVISOR ^& VIRTUALIZATION MANAGER  v1.2
echo =================================================================
echo   Hypervisor (bcdedit) : %HV_LABEL%
echo   Memory Integrity     : %MI_STATUS%
echo   Firmware Protection  : %FW_STATUS%
echo   GPU HAGS             : %HAGS_STATUS%
echo   Saved State Snapshot : %SNAP_STATUS%
echo   DISM (in-box) / OS   : %DISM_VER%  /  %OS_VER%
echo =================================================================
echo   [!] DISM feature changes (4,8,9,10,13) can take several MINUTES.
echo       Do NOT close the window mid-operation - that corrupts servicing.
echo =================================================================
echo.
echo   [1]  System Status Report (CPU, Virtualization, Features)
echo.
echo   --- Quick Switch ---------------------------------------------
echo   [2]  Enable VMware / Proxmox Mode   (Hypervisor OFF)
echo   [3]  Enable WSL2 / Hyper-V Mode      (Hypervisor AUTO)
echo   [4]  One-Click FULL VMware Mode      (Galaxy Book VT-x guide: all OFF)
echo   [5]  One-Click FULL WSL2 Mode        (Hypervisor AUTO + VMP/WSL ON)
echo.
echo   --- Feature Toggles ------------------------------------------
echo   [6]  Toggle Memory Integrity (Core Isolation)
echo   [7]  Toggle Firmware Protection (Core Isolation)
echo   [8]  Toggle WSL Windows Feature
echo   [9]  Toggle Virtual Machine Platform Feature
echo   [10] Toggle Windows Hypervisor Platform Feature
echo   [11] Toggle GPU Hardware Acceleration (HAGS)
echo.
echo   --- State / Safety -------------------------------------------
echo   [12] Save Current State  (snapshot to revert to later)
echo   [13] Restore Saved State (revert to your snapshot)
echo   [14] Create System Restore Point
echo   [15] Backup current Boot Configuration (BCD)
echo   [16] View Log File
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
if "%choice%"=="7"  goto toggle_fw
if "%choice%"=="8"  goto toggle_wsl
if "%choice%"=="9"  goto toggle_vmp
if "%choice%"=="10" goto toggle_hvp
if "%choice%"=="11" goto toggle_hags
if "%choice%"=="12" goto save_state_menu
if "%choice%"=="13" goto restore_state_menu
if "%choice%"=="14" goto restore_point
if "%choice%"=="15" goto backup_bcd
if "%choice%"=="16" goto view_log
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

:: Firmware Protection = Core Isolation "System Guard / Secure Launch"
set "FW_STATUS=Not Configured"
set "FW_RAW="
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled 2^>nul ^| findstr /i "Enabled"') do set "FW_RAW=%%A"
if "%FW_RAW%"=="0x1" set "FW_STATUS=ON  (forces hypervisor to load)"
if "%FW_RAW%"=="0x0" set "FW_STATUS=OFF"

set "HAGS_STATUS=Default / Not Set"
set "HAGS_RAW="
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode 2^>nul ^| findstr /i "HwSchMode"') do set "HAGS_RAW=%%A"
if "%HAGS_RAW%"=="0x2" set "HAGS_STATUS=ENABLED"
if "%HAGS_RAW%"=="0x1" set "HAGS_STATUS=DISABLED"

set "SNAP_STATUS=None saved yet"
if exist "%STATEFILE%" (
    set "SNAP_STATUS=Saved (option 13 reverts to it)"
    for /f "usebackq tokens=2 delims=|" %%T in ("%STATEFILE%") do set "SNAP_STATUS=Saved %%T"
)
goto :eof


:: =====================================================================
:: VERSION INFO  (run once at startup)
:: Reports the in-box DISM (servicing-stack) version and the running OS
:: image version for transparency. We deliberately do NOT flag a build
:: difference as an error: on Windows 11 25H2 (build 26200) the servicing
:: stack legitimately reports the 24H2 base (26100) because 25H2 ships as
:: an enablement package. Pinning to the in-box DISM above is what prevents
:: a real tool/image mismatch (e.g. a stray older DISM on PATH).
:: =====================================================================
:check_versions
set "OS_VER=unknown"
for /f "tokens=2 delims=[]" %%a in ('ver') do set "OS_RAW=%%a"
for /f "tokens=2" %%b in ("%OS_RAW%") do set "OS_VER=%%b"

set "DISM_VER=unknown"
for /f "delims=" %%v in ('powershell -NoProfile -Command "(Get-Item '%DISM%').VersionInfo.ProductVersion" 2^>nul') do set "DISM_VER=%%v"
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
echo Firmware Protection:    %FW_STATUS%
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
echo This applies every step of the Samsung Galaxy Book VT-x guide
echo so Windows fully releases VT-x / AMD-V to VMware:
echo   - Hypervisor launch type   -^> OFF   (bcdedit)
echo   - Memory Integrity         -^> OFF   (Core Isolation)
echo   - Firmware Protection      -^> OFF   (Core Isolation)
echo   - Virtual Machine Platform -^> DISABLED
echo   - Windows Hypervisor Plat. -^> DISABLED
echo.
echo NOTE: This disables WSL2/Docker prerequisites. Use option [5]
echo (Full WSL2 Mode) to restore them later.
echo.
set /p "ok=Proceed? (Y/N): "
if /i not "%ok%"=="Y" goto menu
if not exist "%STATEFILE%" (
    echo Saving a snapshot of your current state first ^(revert with option 13^)...
    call :save_state
)
bcdedit /set hypervisorlaunchtype off
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f
"%DISM%" /online /disable-feature /featurename:VirtualMachinePlatform /norestart
"%DISM%" /online /disable-feature /featurename:HypervisorPlatform /norestart
call :log "FULL VMware mode: HV off + MemIntegrity off + Firmware off + VBS off + VMP/HVP disabled"
echo.
echo [SUCCESS] Hypervisor, Memory Integrity, Firmware Protection, and
echo VBS are OFF; Virtual Machine Platform and Windows Hypervisor
echo Platform are disabled. VMware nested virtualization is fully unblocked.
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
if not exist "%STATEFILE%" (
    echo Saving a snapshot of your current state first ^(revert with option 13^)...
    call :save_state
)
bcdedit /set hypervisorlaunchtype auto
"%DISM%" /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
"%DISM%" /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
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
:: OPTION 7: Toggle Firmware Protection (Core Isolation / System Guard)
:: =====================================================================
:toggle_fw
cls
color 0E
echo =====================================================
echo      FIRMWARE PROTECTION (CORE ISOLATION)
echo =====================================================
echo Current state: %FW_STATUS%
echo.
echo Like Memory Integrity, Firmware Protection (System Guard
echo Secure Launch) can force the hypervisor to load and block
echo VMware nested VT-x. The Galaxy Book guide turns this OFF.
echo.
echo [A] Enable Firmware Protection
echo [B] Disable Firmware Protection
echo [C] Go Back
echo.
set /p "fw_choice=Select A, B, or C: "
if /i "%fw_choice%"=="A" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 1 /f
    call :log "Firmware Protection ENABLED"
    echo Firmware Protection ENABLED.
    goto restart_prompt
)
if /i "%fw_choice%"=="B" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 0 /f
    call :log "Firmware Protection DISABLED"
    echo Firmware Protection DISABLED.
    goto restart_prompt
)
goto menu


:: =====================================================================
:: OPTION 8: Toggle WSL Windows Feature
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
    "%DISM%" /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    call :log "WSL feature ENABLED"
    goto restart_prompt
)
if /i "%wsl_choice%"=="B" (
    echo Disabling Windows Subsystem for Linux...
    "%DISM%" /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
    call :log "WSL feature DISABLED"
    goto restart_prompt
)
goto menu


:: =====================================================================
:: OPTION 9: Toggle Virtual Machine Platform Feature
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
    "%DISM%" /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    call :log "Virtual Machine Platform ENABLED"
    goto restart_prompt
)
if /i "%vmp_choice%"=="B" (
    echo Disabling Virtual Machine Platform...
    "%DISM%" /online /disable-feature /featurename:VirtualMachinePlatform /norestart
    call :log "Virtual Machine Platform DISABLED"
    goto restart_prompt
)
goto menu


:: =====================================================================
:: OPTION 10: Toggle Windows Hypervisor Platform Feature
:: =====================================================================
:toggle_hvp
cls
color 0E
echo =====================================================
echo      WINDOWS HYPERVISOR PLATFORM FEATURE
echo =====================================================
echo This Windows feature exposes a hypervisor API that some
echo third-party tools use. The Galaxy Book VT-x guide turns it
echo OFF for VMware nested virtualization.
echo.
echo [A] Enable Windows Hypervisor Platform
echo [B] Disable Windows Hypervisor Platform
echo [C] Go Back
echo.
set /p "hvp_choice=Select A, B, or C: "
if /i "%hvp_choice%"=="A" (
    echo Enabling Windows Hypervisor Platform...
    "%DISM%" /online /enable-feature /featurename:HypervisorPlatform /all /norestart
    call :log "Windows Hypervisor Platform ENABLED"
    goto restart_prompt
)
if /i "%hvp_choice%"=="B" (
    echo Disabling Windows Hypervisor Platform...
    "%DISM%" /online /disable-feature /featurename:HypervisorPlatform /norestart
    call :log "Windows Hypervisor Platform DISABLED"
    goto restart_prompt
)
goto menu


:: =====================================================================
:: OPTION 11: Toggle GPU Hardware Acceleration (HAGS)
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
:: OPTION 12: Save Current State (snapshot)
:: =====================================================================
:save_state_menu
cls
color 0D
echo =====================================================
echo            SAVE CURRENT STATE (SNAPSHOT)
echo =====================================================
echo Recording your current virtualization configuration to:
echo   %STATEFILE%
echo so you can revert to it later with option [13].
echo (Reading Windows feature states, please wait...)
echo.
call :save_state
echo [SUCCESS] Snapshot saved:
echo -----------------------------------------------------
type "%STATEFILE%"
echo -----------------------------------------------------
echo.
pause
goto menu


:: =====================================================================
:: OPTION 13: Restore Saved State
:: =====================================================================
:restore_state_menu
cls
color 0D
echo =====================================================
echo            RESTORE SAVED STATE
echo =====================================================
if not exist "%STATEFILE%" (
    echo No saved state found.
    echo Use option [12] to save a snapshot first.
    echo.
    pause
    goto menu
)
echo The following saved snapshot will be re-applied:
echo -----------------------------------------------------
type "%STATEFILE%"
echo -----------------------------------------------------
echo.
set /p "ok=Revert to this saved state? (Y/N): "
if /i not "%ok%"=="Y" goto menu
echo.
echo Re-applying saved state...
echo [!] Enabling Windows features via DISM can take SEVERAL MINUTES and
echo     shows no progress here. Please WAIT - do NOT close this window.
call :restore_state
call :log "Restored saved state from snapshot"
echo.
echo [SUCCESS] Saved state re-applied.
goto restart_prompt


:: =====================================================================
:: STATE SAVE WORKER   ( writes %STATEFILE% )
:: =====================================================================
:save_state
call :read_status
set "S_MI=none"
if "%MI_RAW%"=="0x1" set "S_MI=1"
if "%MI_RAW%"=="0x0" set "S_MI=0"
set "S_FW=none"
if "%FW_RAW%"=="0x1" set "S_FW=1"
if "%FW_RAW%"=="0x0" set "S_FW=0"
set "S_HAGS=none"
if "%HAGS_RAW%"=="0x2" set "S_HAGS=2"
if "%HAGS_RAW%"=="0x1" set "S_HAGS=1"
set "S_VBS=none"
set "S_VBS_RAW="
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity 2^>nul ^| findstr /i "EnableVirtualizationBasedSecurity"') do set "S_VBS_RAW=%%A"
if "%S_VBS_RAW%"=="0x1" set "S_VBS=1"
if "%S_VBS_RAW%"=="0x0" set "S_VBS=0"
call :feat_state VirtualMachinePlatform S_VMP
call :feat_state Microsoft-Windows-Subsystem-Linux S_WSL
call :feat_state HypervisorPlatform S_HVP
> "%STATEFILE%" echo # saved ^| %date% %time%
>> "%STATEFILE%" echo HV=%HV_STATUS%
>> "%STATEFILE%" echo MI=%S_MI%
>> "%STATEFILE%" echo FW=%S_FW%
>> "%STATEFILE%" echo VBS=%S_VBS%
>> "%STATEFILE%" echo HAGS=%S_HAGS%
>> "%STATEFILE%" echo VMP=%S_VMP%
>> "%STATEFILE%" echo WSL=%S_WSL%
>> "%STATEFILE%" echo HVP=%S_HVP%
call :log "State snapshot saved to %STATEFILE%"
goto :eof


:: =====================================================================
:: STATE RESTORE WORKER   ( re-applies %STATEFILE% )
:: =====================================================================
:restore_state
set "R_HV=auto"
set "R_MI=none"
set "R_FW=none"
set "R_VBS=none"
set "R_HAGS=none"
set "R_VMP=off"
set "R_WSL=off"
set "R_HVP=off"
for /f "usebackq eol=# tokens=1,2 delims==" %%K in ("%STATEFILE%") do (
    if /i "%%K"=="HV"   set "R_HV=%%L"
    if /i "%%K"=="MI"   set "R_MI=%%L"
    if /i "%%K"=="FW"   set "R_FW=%%L"
    if /i "%%K"=="VBS"  set "R_VBS=%%L"
    if /i "%%K"=="HAGS" set "R_HAGS=%%L"
    if /i "%%K"=="VMP"  set "R_VMP=%%L"
    if /i "%%K"=="WSL"  set "R_WSL=%%L"
    if /i "%%K"=="HVP"  set "R_HVP=%%L"
)
bcdedit /set hypervisorlaunchtype %R_HV%
call :apply_dword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" Enabled %R_MI%
call :apply_dword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" Enabled %R_FW%
call :apply_dword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" EnableVirtualizationBasedSecurity %R_VBS%
call :apply_dword "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" HwSchMode %R_HAGS%
call :apply_feature VirtualMachinePlatform %R_VMP%
call :apply_feature Microsoft-Windows-Subsystem-Linux %R_WSL%
call :apply_feature HypervisorPlatform %R_HVP%
goto :eof


:: =====================================================================
:: HELPER: read a Windows optional-feature state into a variable
::         ( call :feat_state <FeatureName> <OutVarName> )
::         Uses PowerShell so the Enabled/Disabled value is the
::         culture-invariant enum (works on non-English Windows).
:: =====================================================================
:feat_state
set "%~2=off"
set "FEAT_RAW="
for /f %%S in ('powershell -NoProfile -Command "(Get-WindowsOptionalFeature -Online -FeatureName %~1).State" 2^>nul') do set "FEAT_RAW=%%S"
echo %FEAT_RAW% | findstr /i "Enabled" >nul && set "%~2=on"
goto :eof


:: =====================================================================
:: HELPER: apply a REG_DWORD, or delete it when value is "none"
::         ( call :apply_dword "<KeyPath>" <ValueName> <none^|number> )
:: =====================================================================
:apply_dword
if /i "%~3"=="none" (
    reg delete "%~1" /v %~2 /f >nul 2>&1
) else (
    reg add "%~1" /v %~2 /t REG_DWORD /d %~3 /f >nul
)
goto :eof


:: =====================================================================
:: HELPER: enable/disable a Windows optional feature
::         ( call :apply_feature <FeatureName> <on^|off> )
:: =====================================================================
:apply_feature
if /i "%~2"=="on" (
    "%DISM%" /online /enable-feature /featurename:%~1 /all /norestart >nul
) else (
    "%DISM%" /online /disable-feature /featurename:%~1 /norestart >nul
)
goto :eof


:: =====================================================================
:: OPTION 14: Create System Restore Point
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
:: OPTION 15: Backup current Boot Configuration (BCD)
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
:: OPTION 16: View Log File
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
