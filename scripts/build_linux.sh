#!/usr/bin/env bash
# ==============================================================================
# Script de compilación para Linux (Nativo) - Clockmaster
# ==============================================================================
set -euo pipefail

# Directorio raíz del repositorio
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Valores por defecto
BUILD_TYPE="Release"
CLEAN_BUILD=false
PACKAGE_AFTER_BUILD=false
RUN_AFTER_BUILD=false
EXTRA_CMAKE_ARGS=()

mostrar_ayuda() {
    cat <<EOF
Uso: $(basename "$0") [OPCIONES]

Opciones:
  --release       Compila en modo Release optimizado (por defecto, ruta: build/linux)
  --debug         Compila en modo Debug con símbolos (ruta: build/debug)
  --clean         Elimina la carpeta de build antes de compilar
  --package       Genera los paquetes .tar y .tar.gz en dist/ tras compilar
  --run           Ejecuta la aplicación una vez compilada
  -h, --help      Muestra este mensaje de ayuda

Ejemplos:
  $(basename "$0")                 # Compila Release en build/linux
  $(basename "$0") --debug         # Compila Debug en build/debug
  $(basename "$0") --package       # Compila Release y empaqueta en dist/
  $(basename "$0") --clean --run   # Compila desde cero y ejecuta
EOF
}

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --release)
            BUILD_TYPE="Release"
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --package)
            PACKAGE_AFTER_BUILD=true
            shift
            ;;
        --run)
            RUN_AFTER_BUILD=true
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

# Seleccionar carpeta de build según el tipo
if [[ "$BUILD_TYPE" == "Debug" ]]; then
    BUILD_DIR="$REPO_ROOT/build/debug"
else
    BUILD_DIR="$REPO_ROOT/build/linux"
fi

echo "============================================================"
echo " Clockmaster - Compilación Nativa para Linux ($BUILD_TYPE)"
echo " Carpeta de build: $BUILD_DIR"
echo "============================================================"

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
echo "[2/4] Configurando CMake..."
mkdir -p "$BUILD_DIR"
cmake -B "$BUILD_DIR" \
    $GENERATOR \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    "${EXTRA_CMAKE_ARGS[@]}" \
    "$REPO_ROOT"

# Compilación
echo "[3/4] Compilando proyecto..."
cmake --build "$BUILD_DIR"

echo "✓ Compilación completada con éxito: $BUILD_DIR/clockmaster"

# Empaquetado en dist/ si fue solicitado
if [[ "$PACKAGE_AFTER_BUILD" == true ]]; then
    echo "[4/4] Empaquetando en dist/..."
    DIST_DIR="$REPO_ROOT/dist"
    STAGE_DIR="$BUILD_DIR/stage"

    mkdir -p "$DIST_DIR" "$STAGE_DIR"
    cp "$BUILD_DIR/clockmaster" "$STAGE_DIR/"
    cp "$BUILD_DIR/_deps/slint-build/libslint_cpp.so" "$STAGE_DIR/"

    if command -v patchelf >/dev/null 2>&1; then
        patchelf --set-rpath '$ORIGIN' "$STAGE_DIR/clockmaster"
    fi

    tar -C "$STAGE_DIR" -cf "$DIST_DIR/clockmaster-linux.tar" clockmaster libslint_cpp.so
    tar -C "$STAGE_DIR" -czf "$DIST_DIR/clockmaster-linux.tar.gz" clockmaster libslint_cpp.so
    rm -rf "$STAGE_DIR"

    echo "✓ Paquetes creados en $DIST_DIR:"
    echo "  - $DIST_DIR/clockmaster-linux.tar"
    echo "  - $DIST_DIR/clockmaster-linux.tar.gz"
fi

# Ejecución si fue solicitada
if [[ "$RUN_AFTER_BUILD" == true ]]; then
    echo "Ejecutando $BUILD_DIR/clockmaster..."
    "$BUILD_DIR/clockmaster"
fi
