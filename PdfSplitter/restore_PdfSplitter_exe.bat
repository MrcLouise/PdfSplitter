@echo off
setlocal
cd /d "%~dp0"

if not exist PdfSplitter.exe.part1 goto :missing
if not exist PdfSplitter.exe.part2 goto :missing
if not exist PdfSplitter.exe.part3 goto :missing

echo Merging PdfSplitter.exe.part1 + part2 + part3 ...
copy /b PdfSplitter.exe.part1+PdfSplitter.exe.part2+PdfSplitter.exe.part3 PdfSplitter.exe >nul
if errorlevel 1 goto :fail

for %%A in (PdfSplitter.exe) do set "size=%%~zA"
if not "%size%"=="6900917" goto :sizefail

echo.
echo OK: PdfSplitter.exe restored, size = %size% bytes
echo SHA256 should be: d53adec6d00b447c9594656801a094ce476c0d3bd377904c8fa639faf36cca56
certutil -hashfile PdfSplitter.exe SHA256 | find /v ":" | find /v "CertUtil"
pause
exit /b 0

:missing
echo ERROR: part file missing. Need PdfSplitter.exe.part1 / part2 / part3 in the same folder as this bat.
pause
exit /b 1

:fail
echo ERROR: copy failed.
pause
exit /b 1

:sizefail
echo ERROR: restored size %size% bytes, expected 6900917. Parts may be corrupted.
pause
exit /b 1
