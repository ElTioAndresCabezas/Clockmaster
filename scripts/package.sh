#!/usr/bin/env bash
# ==============================================================================
# Script de empaquetado para distribución (dist/) - Clockmaster
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$REPO_ROOT/dist"
LINUX_BUILD="$REPO_ROOT/build/linux"
WINDOWS_BUILD="$REPO_ROOT/build/windows"

TARGET="${1:-all}"

empaquetar_linux() {
    if [[ ! -f "$LINUX_BUILD/clockmaster" || ! -f "$LINUX_BUILD/_deps/slint-build/libslint_cpp.so" ]]; then
        echo "ERROR: No se encontró el binario de Linux en $LINUX_BUILD." >&2
        echo "Ejecuta primero: ./scripts/build_linux.sh" >&2
        return 1
    fi

    echo "Empaquetando versión Linux..."
    STAGE_DIR="$LINUX_BUILD/stage"
    mkdir -p "$DIST_DIR" "$STAGE_DIR"
    cp "$LINUX_BUILD/clockmaster" "$STAGE_DIR/"
    cp "$LINUX_BUILD/_deps/slint-build/libslint_cpp.so" "$STAGE_DIR/"

    if command -v patchelf >/dev/null 2>&1; then
        patchelf --set-rpath '$ORIGIN' "$STAGE_DIR/clockmaster"
    fi

    tar -C "$STAGE_DIR" -cf "$DIST_DIR/clockmaster-linux.tar" clockmaster libslint_cpp.so
    tar -C "$STAGE_DIR" -czf "$DIST_DIR/clockmaster-linux.tar.gz" clockmaster libslint_cpp.so
    rm -rf "$STAGE_DIR"

    echo "✓ Creado: $DIST_DIR/clockmaster-linux.tar"
    echo "✓ Creado: $DIST_DIR/clockmaster-linux.tar.gz"
}

empaquetar_windows() {
    if [[ ! -f "$WINDOWS_BUILD/clockmaster.exe" || ! -f "$WINDOWS_BUILD/slint_cpp.dll" ]]; then
        echo "ERROR: No se encontró el binario de Windows en $WINDOWS_BUILD." >&2
        echo "Ejecuta primero: ./scripts/build_windows.sh" >&2
        return 1
    fi

    echo "Empaquetando versión Windows..."
    mkdir -p "$DIST_DIR"
    if command -v zip >/dev/null 2>&1; then
        zip -j "$DIST_DIR/clockmaster-windows.zip" "$WINDOWS_BUILD/clockmaster.exe" "$WINDOWS_BUILD/slint_cpp.dll"
        echo "✓ Creado: $DIST_DIR/clockmaster-windows.zip"
    else
        echo "ERROR: 'zip' no está instalado en el sistema." >&2
        return 1
    fi
}

case "$TARGET" in
    linux)
        empaquetar_linux
        ;;
    windows)
        empaquetar_windows
        ;;
    all)
        echo "Empaquetando todas las plataformas disponibles en dist/..."
        if [[ -f "$LINUX_BUILD/clockmaster" ]]; then
            empaquetar_linux
        else
            echo "Aviso: Saltando Linux (no compilado en $LINUX_BUILD)."
        fi

        if [[ -f "$WINDOWS_BUILD/clockmaster.exe" ]]; then
            empaquetar_windows
        else
            echo "Aviso: Saltando Windows (no compilado en $WINDOWS_BUILD)."
        fi
        ;;
    -h|--help)
        echo "Uso: $(basename "$0") [all|linux|windows]"
        exit 0
        ;;
    *)
        echo "Uso: $(basename "$0") [all|linux|windows]"
        exit 1
        ;;
esac
