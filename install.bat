@echo off
REM install.bat — Windows wrapper for install.sh
REM
REM Usage:
REM   install.bat C:\path\to\target\project
REM   install.bat  (installs to current directory)
REM
REM Requires Git for Windows (provides bash).

setlocal

REM ─── Detect Git Bash ──────────────────────────────────────────────────────
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Git is not installed or not in PATH.
    echo.
    echo This framework requires Git for Windows, which provides bash.
    echo Download from: https://gitforwindows.org/
    exit /b 1
)

REM Get Git install directory and derive bash path
for /f "delims=" %%i in ('git --exec-path') do set "GIT_EXEC=%%i"
set "GIT_BASH=%GIT_EXEC%\..\..\..\bin\bash.exe"

if not exist "%GIT_BASH%" (
    REM Fallback: check if bash is in PATH and is Git Bash (not WSL)
    where bash >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: bash not found.
        echo.
        echo Install Git for Windows from: https://gitforwindows.org/
        exit /b 1
    )

    REM Verify it's Git Bash, not WSL
    for /f "delims=" %%v in ('bash --version 2^>nul') do set "BASH_VER=%%v"
    echo %BASH_VER% | findstr /i "msys mingw" >nul 2>&1
    if %errorlevel% neq 0 (
        echo WARNING: Found bash but it appears to be WSL, not Git Bash.
        echo WSL bash uses a different filesystem and may cause path issues.
        echo.
        echo Install Git for Windows from: https://gitforwindows.org/
        exit /b 1
    )
    set "GIT_BASH=bash"
)

REM ─── Run install.sh ───────────────────────────────────────────────────────
set "SCRIPT_DIR=%~dp0"
"%GIT_BASH%" "%SCRIPT_DIR%install.sh" %*
