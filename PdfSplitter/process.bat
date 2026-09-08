@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

REM Get current date in YYYYMMDD format
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd'"`) do set "TODAY=%%a"

REM Production environment (D: / E:)
set "BASE_FOLDER=D:\UTBatch\DSB\eAdvice\%TODAY%"
set "EXTRA_OUTPUT_FOLDER=E:\User_Output\WMO\e-Documents"

REM Test environment (C: desktop)
REM set "BASE_FOLDER=%~dp0..\UTBatch\DSB\eAdvice\%TODAY%"
REM set "EXTRA_OUTPUT_FOLDER=%~dp0..\User_Output\WMO\e-Documents"

set "BULK_FOLDER=%BASE_FOLDER%\BulkUpload"
set "OUT_FOLDER=%BASE_FOLDER%"
set "ATTACHMENT_FOLDER=%BASE_FOLDER%\Attachment"

REM Create directories if they don't exist
if not exist "%BULK_FOLDER%" mkdir "%BULK_FOLDER%"
if not exist "%OUT_FOLDER%" mkdir "%OUT_FOLDER%"
if not exist "%ATTACHMENT_FOLDER%" mkdir "%ATTACHMENT_FOLDER%"
if not exist "%EXTRA_OUTPUT_FOLDER%" mkdir "%EXTRA_OUTPUT_FOLDER%"

echo ============================================
echo PdfSplitter PROCESS
echo ============================================
echo BulkUpload :  %BULK_FOLDER%
echo Output     :  %OUT_FOLDER%
echo Attachment :  %ATTACHMENT_FOLDER%
echo ExtraOutput:  %EXTRA_OUTPUT_FOLDER%\%TODAY%
echo.

REM Run PdfSplitter
echo [INFO] Starting PdfSplitter...
echo.
"%~dp0PdfSplitter.exe" "%BULK_FOLDER%" "%OUT_FOLDER%" "%ATTACHMENT_FOLDER%" "%EXTRA_OUTPUT_FOLDER%"
set EXIT_CODE=%ERRORLEVEL%

REM Show latest log file (logback writes to log\yyyyMMdd\app.log under the working directory)
set "LOG_FILE=%~dp0log\%TODAY%\app.log"

echo.
echo ============================================
if %EXIT_CODE% EQU 0 (
    echo [SUCCESS] All instructions processed successfully!
    echo ============================================
    exit /b 0
) else (
    echo [FAILED] Some instructions failed. Exit code: %EXIT_CODE%
    echo ============================================
    if exist "%LOG_FILE%" (
        echo Log: %LOG_FILE%
    )
    echo.
    pause
    exit /b %EXIT_CODE%
)
