@echo off
rem ============================================================================
rem Script para empaquetar Clockmaster en dist\clockmaster-windows.zip (Windows)
rem ============================================================================
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
for %%i in ("%SCRIPT_DIR%..") do set "REPO_ROOT=%%~fi"

set "BUILD_DIR=%REPO_ROOT%\build\windows"
set "DIST_DIR=%REPO_ROOT%\dist"

set "EXE_PATH=%BUILD_DIR%\clockmaster.exe"
set "DLL_PATH=%BUILD_DIR%\slint_cpp.dll"

if not exist "!EXE_PATH!" (
    if exist "%BUILD_DIR%\Release\clockmaster.exe" (
        set "EXE_PATH=%BUILD_DIR%\Release\clockmaster.exe"
        set "DLL_PATH=%BUILD_DIR%\Release\slint_cpp.dll"
    )
)

if not exist "!EXE_PATH!" (
    echo ERROR: No se encontro el ejecutable en %BUILD_DIR%.
    echo Por favor ejecuta primero: scripts\build_windows.bat
    exit /b 1
)

if not exist "!DLL_PATH!" (
    echo ERROR: No se encontro slint_cpp.dll en %BUILD_DIR%.
    exit /b 1
)

echo Empaquetando en dist\clockmaster-windows.zip...
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '!EXE_PATH!', '!DLL_PATH!' -DestinationPath '%DIST_DIR%\clockmaster-windows.zip' -Force"

if %errorlevel% equ 0 (
    echo.
    echo Paquete creado con exito: %DIST_DIR%\clockmaster-windows.zip
) else (
    echo ERROR: Fallo la creacion del archivo ZIP.
    exit /b %errorlevel%
)

exit /b 0
