@echo off
REM ============================================================
REM 建立 PdfChecker Template31 測試目錄（日期資料夾用當天日期）
REM 在 Win11 測試機上執行，執行前請確認 D: 槽存在
REM ============================================================
cd /d "%~dp0"

for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd'"`) do set "TODAY=%%a"

set "TARGET=%USERPROFILE%\Desktop\UTBatch\DSB\eAdvice\%TODAY%\CorporateActionGeneric\Template31_CA20260730001"

if not exist "%TARGET%" mkdir "%TARGET%"
copy /Y "%~dp020260807_33_NA00945001_000923.pdf" "%TARGET%\" >nul

echo.
echo Test folder ready:
echo %TARGET%
echo.
dir /b "%TARGET%"
