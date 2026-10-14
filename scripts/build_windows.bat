@echo off
rem ============================================================================
rem Script de compilacion nativa para Windows - Clockmaster
rem ============================================================================
setlocal enabledelayedexpansion

rem Resolver la raiz del repositorio
set "SCRIPT_DIR=%~dp0"
for %%i in ("%SCRIPT_DIR%..") do set "REPO_ROOT=%%~fi"

set "BUILD_TYPE=Release"
set "CLEAN_BUILD=0"
set "PACKAGE_AFTER_BUILD=0"
set "RUN_AFTER_BUILD=0"

rem Parsear argumentos
:parse_args
if "%~1"=="" goto after_args
if /i "%~1"=="--debug" (
    set "BUILD_TYPE=Debug"
) else if /i "%~1"=="debug" (
    set "BUILD_TYPE=Debug"
) else if /i "%~1"=="--release" (
    set "BUILD_TYPE=Release"
) else if /i "%~1"=="release" (
    set "BUILD_TYPE=Release"
) else if /i "%~1"=="--clean" (
    set "CLEAN_BUILD=1"
) else if /i "%~1"=="clean" (
    set "CLEAN_BUILD=1"
) else if /i "%~1"=="--package" (
    set "PACKAGE_AFTER_BUILD=1"
) else if /i "%~1"=="package" (
    set "PACKAGE_AFTER_BUILD=1"
) else if /i "%~1"=="--run" (
    set "RUN_AFTER_BUILD=1"
) else if /i "%~1"=="run" (
    set "RUN_AFTER_BUILD=1"
) else if /i "%~1"=="-h" (
    goto show_help
) else if /i "%~1"=="--help" (
    goto show_help
) else if /i "%~1"=="/?" (
    goto show_help
)
shift
goto parse_args

:show_help
echo Uso: %~nx0 [opciones]
echo.
echo Opciones:
echo   --release    Compila en modo Release (por defecto, ruta: build\windows)
echo   --debug      Compila en modo Debug (ruta: build\debug)
echo   --clean      Elimina la carpeta de build antes de compilar
echo   --package    Genera dist\clockmaster-windows.zip al finalizar
echo   --run        Ejecuta el programa una vez compilado
echo   -h, --help   Muestra esta ayuda
echo.
echo Ejemplos:
echo   %~nx0
echo   %~nx0 --debug
echo   %~nx0 --package
echo   %~nx0 --clean --run
exit /b 0

:after_args
if /i "%BUILD_TYPE%"=="Debug" (
    set "BUILD_DIR=%REPO_ROOT%\build\debug"
) else (
    set "BUILD_DIR=%REPO_ROOT%\build\windows"
)

echo ============================================================
echo  Clockmaster - Compilacion Nativa para Windows (%BUILD_TYPE%)
echo  Carpeta de build: %BUILD_DIR%
echo ============================================================

rem Limpieza si fue solicitada
if "%CLEAN_BUILD%"=="1" (
    if exist "%BUILD_DIR%" (
        echo [1/4] Limpiando carpeta de build...
        rmdir /s /q "%BUILD_DIR%"
    )
)

rem Detectar si Ninja esta disponible
set "GENERATOR="
where ninja >nul 2>nul
if %errorlevel% equ 0 (
    set "GENERATOR=-G Ninja"
)

rem Crear carpeta y configurar con CMake
echo [2/4] Configurando CMake...
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
cmake -B "%BUILD_DIR%" %GENERATOR% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% "%REPO_ROOT%"
if %errorlevel% neq 0 (
    echo ERROR: Fallo la configuracion de CMake.
    exit /b %errorlevel%
)

rem Compilar
echo [3/4] Compilando ejecutable...
cmake --build "%BUILD_DIR%" --config %BUILD_TYPE%
if %errorlevel% neq 0 (
    echo ERROR: Fallo la compilacion.
    exit /b %errorlevel%
)

rem Localizar el ejecutable generado (en caso de generador multi-config de Visual Studio o Ninja)
set "EXE_PATH=%BUILD_DIR%\clockmaster.exe"
set "DLL_PATH=%BUILD_DIR%\slint_cpp.dll"
if not exist "!EXE_PATH!" (
    if exist "%BUILD_DIR%\%BUILD_TYPE%\clockmaster.exe" (
        set "EXE_PATH=%BUILD_DIR%\%BUILD_TYPE%\clockmaster.exe"
        set "DLL_PATH=%BUILD_DIR%\%BUILD_TYPE%\slint_cpp.dll"
    )
)

echo.
echo Compilacion completada con exito: !EXE_PATH!

rem Empaquetado si fue solicitado
if "%PACKAGE_AFTER_BUILD%"=="1" (
    echo [4/4] Empaquetando en dist\clockmaster-windows.zip...
    if not exist "%REPO_ROOT%\dist" mkdir "%REPO_ROOT%\dist"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '!EXE_PATH!', '!DLL_PATH!' -DestinationPath '%REPO_ROOT%\dist\clockmaster-windows.zip' -Force"
    if %errorlevel% equ 0 (
        echo Paquete creado: %REPO_ROOT%\dist\clockmaster-windows.zip
    ) else (
        echo AVISO: No se pudo crear el archivo ZIP mediante PowerShell.
    )
)

rem Ejecucion si fue solicitada
if "%RUN_AFTER_BUILD%"=="1" (
    echo Ejecutando Clockmaster...
    start "" "!EXE_PATH!"
)

exit /b 0
