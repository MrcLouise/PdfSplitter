@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

REM Get current date in YYYYMMDD format
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd'"`) do set "TODAY=%%a"

REM Test environment (desktop): C:\Users\<user>\Desktop\UTBatch\DSB\eAdvice\<today>
set "BASE_FOLDER=%USERPROFILE%\Desktop\UTBatch\DSB\eAdvice\%TODAY%"
set "LOG_FOLDER=%~dp0"

REM Production environment (D: / E:)
REM set "BASE_FOLDER=D:\UTBatch\DSB\eAdvice\%TODAY%"
REM set "LOG_FOLDER=%~dp0"

echo ============================================
echo PdfChecker
echo ============================================
echo Base Folder : %BASE_FOLDER%
echo Log         : %LOG_FOLDER%\log\logfile.txt
echo.

REM Run pdfchecker
echo [INFO] Starting pdfchecker...
echo.
"%~dp0pdfchecker.exe" "%BASE_FOLDER%" "%LOG_FOLDER%"
set EXIT_CODE=%ERRORLEVEL%

echo.
echo ============================================
if %EXIT_CODE% EQU 0 (
    echo [SUCCESS] All PDF checks passed!
    echo ============================================
    exit /b 0
) else (
    echo [FAILED] Some PDF checks failed. Exit code: %EXIT_CODE%
    echo ============================================
    exit /b %EXIT_CODE%
)
