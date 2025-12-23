@echo off
setlocal enabledelayedexpansion
title Advanced Security Suite (Antivirus + VPN + Firewall)
color 0A

:: ===========================
:: CONFIG
:: ===========================
set "LOG=%~dp0security_log.txt"
set "HASH_CSV=%~dp0hash_results.csv"
set "QUAR=%~dp0Quarantine"
set "KNOWN_BAD=%~dp0known_bad_hashes.txt"
set "VPN_NAME=MySecureVPN"
set "VPN_USER="
set "VPN_PASS="
set "FIREWALL_EXPORT=%~dp0firewall_policy.wfw"

if not exist "%KNOWN_BAD%" (
    echo ; Put one SHA256 per line (uppercase hex) > "%KNOWN_BAD%"
)

:: Suspicious / Exclude lists
set suspicious_exts=.exe .dll .scr .vbs .ps1 .js .cmd .bat
set suspicious_keywords=trojan worm hack crack keylogger stealer miner ransom xmrig minerd
set exclude_exts=.txt .log .png .jpg .bat
set whitelist_paths="%ProgramFiles%" "%ProgramFiles(x86)%" "%SystemRoot%\System32"

:: ===========================
:: MAIN MENU
:: ===========================
:menu
cls
echo ============================================
echo        Advanced Security Suite
echo ============================================
echo Antivirus
echo   1. Quick Scan (Downloads + AppData)
echo   2. Full Scan (C:\)  [long]
echo   3. Custom Folder Scan
echo   4. Persistence Scan (Startup/Registry/Tasks)
echo   5. View Logs
echo   6. Restore Quarantine
echo VPN
echo   7. Connect VPN
echo   8. Disconnect VPN
echo Firewall
echo   9. Enable Firewall (Domain/Private/Public)
echo  10. Disable Firewall (all profiles) [not recommended]
echo  11. Block outbound for suspicious apps (from last scan)
echo  12. List top rules
echo  13. Add allow rule for app
echo  14. Reset firewall to defaults
echo  15. Export firewall policy
echo  16. Import firewall policy
echo  17. Exit
echo ============================================
set /p choice=Choose option: 

if "%choice%"=="1" call :scan_root "%USERPROFILE%\Downloads" "%APPDATA%"
if "%choice%"=="2" call :scan_root "C:\"
if "%choice%"=="3" call :custom_scan
if "%choice%"=="4" call :persistence_scan
if "%choice%"=="5" call :view_logs
if "%choice%"=="6" call :restore_quarantine

if "%choice%"=="7" call :vpn_connect
if "%choice%"=="8" call :vpn_disconnect

if "%choice%"=="9"  call :fw_enable_all
if "%choice%"=="10" call :fw_disable_all
if "%choice%"=="11" call :fw_block_suspicious
if "%choice%"=="12" call :fw_list_rules
if "%choice%"=="13" call :fw_allow_app
if "%choice%"=="14" call :fw_reset
if "%choice%"=="15" call :fw_export
if "%choice%"=="16" call :fw_import

if "%choice%"=="17" exit /b
goto menu

:: ===========================
:: ANTIVIRUS — Scan roots
:: ===========================
:scan_root
echo [%date% %time%] Scan roots: %* >> "%LOG%"
for %%R in (%*) do (
    if exist "%%~R" (
        call :scan_folder "%%~R"
    )
)
echo Scan complete. Press any key.
pause
goto menu

:custom_scan
set /p "DIR=Enter full folder path: "
if exist "%DIR%" (
    call :scan_folder "%DIR%"
) else (
    echo Folder not found.
    pause
)
goto menu

:scan_folder
set "folder=%~1"
echo Scanning: %folder%
echo [%date% %time%] Scanning: %folder% >> "%LOG%"

for /R "%folder%" %%F in (*) do (
    set "file=%%~nxF"
    set "ext=%%~xF"
    set "path=%%~fF"
    call :tolower ext

    :: Whitelist paths (skip system/program folders)
    set "WLHIT="
    for %%W in (%whitelist_paths%) do (
        echo "!path!" | findstr /I /C:"%%~W" >nul && set "WLHIT=1"
    )
    if defined WLHIT goto :skip

    :: Skip excluded extensions
    set "skip_ext="
    for %%X in (%exclude_exts%) do if /I "!ext!"=="%%X" set "skip_ext=1"
    if defined skip_ext goto :skip

    :: Suspicious ext
    for %%E in (%suspicious_exts%) do (
        if /I "!ext!"=="%%E" (
            echo [EXT] !path! >> "%LOG%"
            call :hash_and_check "%%~fF"
            call :prompt_quarantine "%%~fF" "EXT"
        )
    )

    :: Suspicious keywords in filename
    for %%K in (%suspicious_keywords%) do (
        echo !file! | findstr /I "%%K" >nul && (
            echo [KEY] !path! >> "%LOG%"
            call :hash_and_check "%%~fF"
            call :prompt_quarantine "%%~fF" "KEY"
        )
    )
    :skip
)
exit /b

:hash_and_check
set "target=%~1"
set "SHA="
for /f "tokens=1,* delims=:" %%A in ('certutil -hashfile "%target%" SHA256 ^| findstr /R /I "^[0-9A-F]"') do set "SHA=%%A"
if not defined SHA set "SHA=ERROR"
if not exist "%HASH_CSV%" echo path,sha256,%date% %time% > "%HASH_CSV%"
echo "%target%",%SHA%,%date% %time%>> "%HASH_CSV%"

:: Compare with known-bad list
set "badhit="
for /f "usebackq delims=" %%H in ("%KNOWN_BAD%") do (
    if /I "%SHA%"=="%%H" set "badhit=1"
)
if defined badhit (
    echo [HASH] KNOWN BAD: %target% (%SHA%) >> "%LOG%"
    call :prompt_quarantine "%target%" "HASH"
)
exit /b

:prompt_quarantine
set "target=%~1"
set "reason=%~2"
echo Suspicious [%reason%]: %target%
set /p "ans=Quarantine this file? (y/n): "
if /I "%ans%"=="y" (
    if not exist "%QUAR%" mkdir "%QUAR%"
    set "ts=%date%_%time%"
    set "ts=!ts::=-!"
    move /Y "%target%" "%QUAR%" >nul
    echo [QUAR] %target% (%reason%) at !ts! >> "%LOG%"
)
exit /b

:restore_quarantine
if not exist "%QUAR%" (
    echo No quarantine folder.
    pause
    goto :eof
)
echo Quarantine contents:
dir /b "%QUAR%"
set /p "fname=Enter exact filename to restore (from list): "
if exist "%QUAR%\%fname%" (
    set /p "dest=Restore to folder (full path): "
    if not exist "%dest%" mkdir "%dest%"
    move /Y "%QUAR%\%fname%" "%dest%"
    echo [RESTORE] %fname% -> %dest% >> "%LOG%"
) else (
    echo File not found in quarantine.
)
pause
goto :eof

:view_logs
echo Opening logs...
start "" "%LOG%"
if exist "%HASH_CSV%" start "" "%HASH_CSV%"
pause
goto menu

:: ===========================
:: ANTIVIRUS — Persistence scan
:: ===========================
:persistence_scan
echo [%date% %time%] Persistence Scan >> "%LOG%"

echo Startup folders:
set "start1=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "start2=%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup"
for %%S in ("%start1%" "%start2%") do (
    if exist "%%~S" (
        echo - %%~S
        for %%F in ("%%~S\*") do echo [STARTUP] %%~fF >> "%LOG%"
    )
)

echo Registry Run / RunOnce:
for %%K in (
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    "HKLM\Software\Microsoft\Windows\CurrentVersion\Run"
    "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce"
) do (
    reg query %%~K >nul 2>&1 && (
        reg query %%~K
        reg query %%~K >> "%LOG%"
    )
)

echo Scheduled tasks (summary):
schtasks /query /fo LIST /v | findstr /I /C:"TaskName" /C:"Task To Run" /C:"Run As User"
schtasks /query /fo LIST /v >> "%LOG%"

echo Persistence scan complete. Press any key.
pause
goto menu

:: ===========================
:: VPN control (requires profile)
:: ===========================
:vpn_connect
echo Connecting VPN: %VPN_NAME%
if defined VPN_USER (
    rasdial "%VPN_NAME%" "%VPN_USER%" "%VPN_PASS%"
) else (
    rasdial "%VPN_NAME%"
)
if errorlevel 1 (
    echo VPN connection failed.
    echo [%date% %time%] VPN connect FAILED >> "%LOG%"
) else (
    echo VPN connected.
    echo [%date% %time%] VPN connected >> "%LOG%"
)
pause
goto menu

:vpn_disconnect
echo Disconnecting VPN: %VPN_NAME%
rasdial "%VPN_NAME%" /disconnect
if errorlevel 1 (
    echo VPN disconnect failed or not connected.
    echo [%date% %time%] VPN disconnect FAILED >> "%LOG%"
) else (
    echo VPN disconnected.
    echo [%date% %time%] VPN disconnected >> "%LOG%"
)
pause
goto menu

:: ===========================
:: Firewall management
:: ===========================
:fw_enable_all
echo Enabling Windows Firewall (all profiles)...
netsh advfirewall set allprofiles state on
echo [%date% %time%] Firewall enabled >> "%LOG%"
pause
goto menu

:fw_disable_all
echo Disabling Windows Firewall (all profiles) [NOT RECOMMENDED]...
netsh advfirewall set allprofiles state off
echo [%date% %time%] Firewall disabled >> "%LOG%"
pause
goto menu

:fw_list_rules
echo Listing top rules (name, direction, action)...
powershell -NoProfile -Command ^
"Get-NetFirewallRule | Select-Object -First 20 -Property DisplayName, Direction, Action | Format-Table -AutoSize"
pause
goto menu

:fw_allow_app
set /p "APP=Enter full path to app to allow (inbound+outbound): "
if not exist "%APP%" (
    echo App not found.
    pause
    goto menu
)
for %%I in ("%APP%") do set "NAME=AllowApp_%%~nI"
echo Creating allow rules for %APP%...
netsh advfirewall firewall add rule name="%NAME%_In" dir=in action=allow program="%APP%" enable=yes
netsh advfirewall firewall add rule name="%NAME%_Out" dir=out action=allow program="%APP%" enable=yes
echo [%date% %time%] FW allow for %APP% >> "%LOG%"
pause
goto menu

:fw_block_suspicious
if not exist "%LOG%" (
    echo No log found. Run a scan first.
    pause
    goto menu
)
echo Blocking outbound for suspicious apps found in last scan...
for /f "tokens=1,* delims=[]" %%A in ('findstr /I /C:"[EXT]" /C:"[KEY]" /C:"[HASH]" "%LOG%"') do (
    for /f "tokens=2 delims=] " %%X in ("%%A %%B") do (
        set "SUS=%%X"
        if exist "!SUS!" (
            for %%I in ("!SUS!") do set "RULE=BlockSus_%%~nI"
            netsh advfirewall firewall add rule name="!RULE!" dir=out action=block program="!SUS!" enable=yes
            echo [FW BLOCK] !SUS! >> "%LOG%"
        )
    )
)
echo Done. Review rules in Windows Defender Firewall with Advanced Security.
pause
goto menu

:fw_reset
echo Resetting firewall to factory defaults...
netsh advfirewall reset
echo [%date% %time%] Firewall reset >> "%LOG%"
pause
goto menu

:fw_export
echo Exporting current firewall policy to %FIREWALL_EXPORT% ...
netsh advfirewall export "%FIREWALL_EXPORT%"
echo [%date% %time%] Firewall exported >> "%LOG%"
pause
goto menu

:fw_import
if not exist "%FIREWALL_EXPORT%" (
    echo No exported policy found at %FIREWALL_EXPORT%.
    pause
    goto menu
)
echo Importing firewall policy from %FIREWALL_EXPORT% ...
netsh advfirewall import "%FIREWALL_EXPORT%"
echo [%date% %time%] Firewall imported >> "%LOG%"
pause
goto menu

:: ===========================
:: Helpers
:: ===========================
:tolower
set "%1=!%1:A=a!"
set "%1=!%1:B=b!"
set "%1=!%1:C=c!"
set "%1=!%1:D=d!"
set "%1=!%1:E=e!"
set "%1=!%1:F=f!"
set "%1=!%1:G=g!"
set "%1=!%1:H=h!"
set "%1=!%1:I=i!"
set "%1=!%1:J=j!"
set "%1=!%1:K=k!"
set "%1=!%1:L=l!"
set "%1=!%1:M=m!"
set "%1=!%1:N=n!"
set "%1=!%1:O=o!"
set "%1=!%1:P=p!"
set "%1=!%1:Q=q!"
set "%1=!%1:R=r!"
set "%1=!%1:S=s!"
set "%1=!%1:T=t!"
set "%1=!%1:U=u!"
set "%1=!%1:V=v!"
set "%1=!%1:W=w!"
set "%1=!%1:X=x!"
set "%1=!%1:Y=y!"
set "%1=!%1:Z=z!"
exit /b