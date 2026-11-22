@echo off
rem Golden Axe: The Revenge of Death Adder - Dreamcast Edition : disc builder
rem Double-click, or drag your ga2.zip onto this file. Options: see README.md
setlocal
if "%~1"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-Disc.ps1"
) else (
  if exist "%~1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-Disc.ps1" -Roms "%~1" %2 %3 %4 %5 %6
  ) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-Disc.ps1" %*
  )
)
echo.
pause
