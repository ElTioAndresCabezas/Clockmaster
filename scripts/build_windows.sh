#!/usr/bin/env bash
# ==============================================================================
# Script de compilación cruzada hacia Windows (.exe) desde Linux - Clockmaster
# ==============================================================================
set -euo pipefail

# Directorio raíz del repositorio
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build/windows"
TOOLCHAIN_FILE="$REPO_ROOT/cmake/toolchain-mingw64.cmake"

CLEAN_BUILD=false
PACKAGE_AFTER_BUILD=false
RUN_WITH_WINE=false
EXTRA_CMAKE_ARGS=()

mostrar_ayuda() {
    cat <<EOF
Uso: $(basename "$0") [OPCIONES]

Opciones:
  --clean         Elimina la carpeta build/windows antes de compilar
  --package       Genera el paquete .zip en dist/ tras compilar
  --run           Ejecuta el archivo .exe usando Wine (si está instalado)
  -h, --help      Muestra este mensaje de ayuda

Requisitos:
  - MinGW-w64 (x86_64-w64-mingw32-gcc y x86_64-w64-mingw32-g++)
  - Rust target: x86_64-pc-windows-gnu (rustup target add x86_64-pc-windows-gnu)

Ejemplos:
  $(basename "$0")                 # Compila clockmaster.exe en build/windows
  $(basename "$0") --package       # Compila y crea dist/clockmaster-windows.zip
  $(basename "$0") --run           # Compila y ejecuta con Wine
EOF
}

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --package)
            PACKAGE_AFTER_BUILD=true
            shift
            ;;
        --run)
            RUN_WITH_WINE=true
            shift
            ;;
        -h|--help)
            mostrar_ayuda
            exit 0
            ;;
        *)
            EXTRA_CMAKE_ARGS+=("$1")
            shift
            ;;
    esac
done

echo "============================================================"
echo " Clockmaster - Compilación Cruzada para Windows (MinGW-w64)"
echo " Carpeta de build: $BUILD_DIR"
echo "============================================================"

# Verificar dependencias básicas de compilación cruzada
if ! command -v x86_64-w64-mingw32-g++ >/dev/null 2>&1; then
    echo "ERROR: No se encontró 'x86_64-w64-mingw32-g++'." >&2
    echo "Por favor, instala mingw-w64-gcc (Arch: sudo pacman -S mingw-w64-gcc, Debian/Ubuntu: sudo apt install g++-mingw-w64-x86-64)." >&2
    exit 1
fi

if [[ ! -f "$TOOLCHAIN_FILE" ]]; then
    echo "ERROR: No se encontró el archivo de toolchain: $TOOLCHAIN_FILE" >&2
    exit 1
fi

# Limpieza si fue solicitada
if [[ "$CLEAN_BUILD" == true && -d "$BUILD_DIR" ]]; then
    echo "[1/4] Limpiando carpeta de build ($BUILD_DIR)..."
    rm -rf "$BUILD_DIR"
fi

# Detectar generador (Ninja recomendado si está instalado)
GENERATOR=""
if command -v ninja >/dev/null 2>&1; then
    GENERATOR="-G Ninja"
fi

# Configuración con CMake
echo "[2/4] Configurando CMake con toolchain de MinGW..."
mkdir -p "$BUILD_DIR"
cmake -B "$BUILD_DIR" \
    $GENERATOR \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
    -DCMAKE_BUILD_TYPE="Release" \
    "${EXTRA_CMAKE_ARGS[@]}" \
    "$REPO_ROOT"

# Compilación
echo "[3/4] Compilando ejecutable .exe..."
cmake --build "$BUILD_DIR"

echo "✓ Compilación completada con éxito: $BUILD_DIR/clockmaster.exe"

# Empaquetado en dist/ si fue solicitado
if [[ "$PACKAGE_AFTER_BUILD" == true ]]; then
    echo "[4/4] Empaquetando en dist/..."
    DIST_DIR="$REPO_ROOT/dist"
    mkdir -p "$DIST_DIR"

    if command -v zip >/dev/null 2>&1; then
        zip -j "$DIST_DIR/clockmaster-windows.zip" "$BUILD_DIR/clockmaster.exe" "$BUILD_DIR/slint_cpp.dll"
        echo "✓ Paquete creado en: $DIST_DIR/clockmaster-windows.zip"
    else
        echo "AVISO: 'zip' no está instalado. No se pudo crear el archivo .zip." >&2
    fi
fi

# Ejecución con Wine si fue solicitada
if [[ "$RUN_WITH_WINE" == true ]]; then
    if command -v wine >/dev/null 2>&1; then
        echo "Ejecutando con Wine..."
        wine "$BUILD_DIR/clockmaster.exe"
    else
        echo "ERROR: 'wine' no está instalado para ejecutar archivos .exe en Linux." >&2
        exit 1
    fi
fi
