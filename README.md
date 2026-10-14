# Clockmaster - Sistema de seguimiento de tiempo para tareas simultáneas

Clockmaster es un programa ligero y de código abierto diseñado para llevar distintos cronómetros persistentes y registrar el tiempo total invertido en diversas tareas simultáneas.

---

## Principios de la aplicación

* **Multiplataforma:** Compatible con Linux, Windows y macOS.
* **Portable:** Se distribuye como un ejecutable único y autocontenido. No requiere instaladores ni runtimes externos pesados.
* **Archivos a la mano y legibles:** El estado de los cronómetros se guarda en archivos locales legibles (por ejemplo, JSON o texto plano), permitiendo al usuario inspeccionar o rectificar tiempos manualmente.
* **Bajo consumo de recursos:** Interfaz gráfica nativa reactiva, con consumo mínimo de RAM y uso nulo de CPU en reposo.

---

## Stack Tecnológico

* **Lenguaje del backend / lógica:** C++ (estándar C++20).
* **Framework de interfaz gráfica (GUI):** [Slint](https://slint.dev/) (usando su API oficial de C++).
* **Sistema de construcción:** CMake (versión 3.21 o superior) con integración mediante `FetchContent`.
* **Compilación cruzada a Windows:** MinGW-w64 + toolchain de Rust para Windows (`x86_64-pc-windows-gnu`).

---

## Estructura del Proyecto

```text
Clockmaster/
├── CMakeLists.txt              # Configuración principal de CMake y FetchContent de Slint
├── cmake/
│   └── toolchain-mingw64.cmake # Archivo de toolchain para compilación cruzada hacia Windows
├── ui/
│   └── app_window.slint        # Definición declarativa de la interfaz gráfica
├── src/
│   ├── main.cpp                # Punto de entrada de la aplicación
│   ├── app_window.hpp          # Declaración de la clase C++ de la ventana (capa de vista)
│   ├── app_window.cpp          # Conexión de métodos Slint con la lógica de negocio
│   ├── timer_manager.hpp       # Declaración de la interfaz de gestión de cronómetros
│   └── timer_manager.cpp       # Implementación de lógica de tiempo y reloj de pared
├── build/                      # Salidas de compilación intermedias (ignorado en Git)
│   ├── linux/                  # Compilación nativa Release para Linux
│   ├── windows/                # Compilación cruzada Release para Windows (.exe)
│   └── debug/                  # Compilación para depuración interactiva (GDB/LLDB)
├── dist/                       # Paquetes finales para distribución (.zip, .tar) (ignorado en Git)
├── icons/                      # Iconos vectoriales (SVG) embebidos en el binario
├── .gitignore
└── README.md
```

---

## Configuración del Entorno de Desarrollo

### 1. En Arch Linux

Instala los compiladores C++, herramientas de construcción, librerías de sistema y el toolchain para Windows:

```bash
# Compiladores y herramientas base
sudo pacman -S base-devel cmake ninja gcc clang

# Librerías del sistema para la GUI en Linux
sudo pacman -S fontconfig libxkbcommon wayland libx11 mesa

# MinGW-w64 para compilación cruzada hacia Windows y Wine para pruebas locales
sudo pacman -S mingw-w64-gcc wine

# Administrador de toolchains de Rust
sudo pacman -S rustup

# Configurar Rust estable y añadir targets para Linux y Windows
rustup default stable
rustup target add x86_64-unknown-linux-gnu
rustup target add x86_64-pc-windows-gnu
```

### 2. En Ubuntu / Debian (Referencia)

```bash
sudo apt update
sudo apt install build-essential cmake ninja-build gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 \
    libfontconfig1-dev libxkbcommon-dev libwayland-dev libx11-dev libgl1-mesa-dev wine64 curl

# Instalar Rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add x86_64-unknown-linux-gnu
rustup target add x86_64-pc-windows-gnu
```

### 3. Editor recomendado (VS Code)

Se recomienda abrir el proyecto en VS Code con las siguientes extensiones recomendadas:
* **Slint** (`slint.slint`): Resaltado de sintaxis, autocompletado y **Live Preview** interactivo de la UI en tiempo real.
* **C/C++** (`ms-vscode.cpptools`) o **CodeLLDB** (`vadimcn.vscode-lldb`): Para depuración con puntos de interrupción (*breakpoints*).
* **CMake Tools** (`ms-vscode.cmake-tools`): Para integración con el flujo de trabajo de CMake.

#### Depuración con un solo clic (F5):
El proyecto ya incluye configuraciones en `.vscode/`:
1. Abre el panel de **Ejecutar y depurar** (`Ctrl+Shift+D` / `F5`).
2. Selecciona **`Clockmaster (Debug - GDB)`** o **`Clockmaster (Debug - CodeLLDB)`**.
3. Presiona **`F5`**: VS Code compilará automáticamente en `build/debug/` con símbolos y lanzará el debugger enganchado al proceso.

---

## Compilación y Ejecución

### Opción A: Compilar para Linux (Nativo)

1. **Configurar el proyecto con CMake y Ninja:**
   ```bash
   cmake -B build/linux -G Ninja -DCMAKE_BUILD_TYPE=Release
   ```
   *(En la primera configuración, CMake descargará y compilará la librería de Slint automáticamente).*

2. **Compilar:**
   ```bash
   cmake --build build/linux
   ```

3. **Ejecutar:**
   ```bash
   ./build/linux/clockmaster
   ```

---

### Opción B: Compilación Cruzada para Windows (.exe) desde Linux

1. **Configurar usando el toolchain de MinGW:**
   ```bash
   cmake -B build/windows -G Ninja \
     -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-mingw64.cmake \
     -DCMAKE_BUILD_TYPE=Release
   ```

2. **Compilar el ejecutable `.exe`:**
   ```bash
   cmake --build build/windows
   ```

3. **Probar el ejecutable en Linux con Wine:**
   ```bash
   wine ./build/windows/clockmaster.exe
   ```

---

## Empaquetado para Distribución (`dist/`)

Para empaquetar ejecutables autónomos listos para compartir o publicar:

* **Windows (`dist/clockmaster-windows.zip`):**
  ```bash
  mkdir -p dist && zip -j dist/clockmaster-windows.zip build/windows/clockmaster.exe build/windows/slint_cpp.dll
  ```
* **Linux (`dist/clockmaster-linux.tar.gz`):**
  ```bash
  mkdir -p dist build/linux/stage
  cp build/linux/clockmaster build/linux/_deps/slint-build/libslint_cpp.so build/linux/stage/
  patchelf --set-rpath '$ORIGIN' build/linux/stage/clockmaster
  tar -C build/linux/stage -czf dist/clockmaster-linux.tar.gz clockmaster libslint_cpp.so
  rm -rf build/linux/stage
  ```

*(También disponible desde VS Code ejecutando las tareas `package: Windows (.zip)`, `package: Linux (.tar.gz)` o `package: all`).*

---

## Scripts Automatizados (`scripts/`)

El repositorio incluye scripts listos para usar tanto en Linux (Bash) como en Windows (CMD / PowerShell):

### En Linux:
* **Compilar nativo Linux:**
  ```bash
  ./scripts/build_linux.sh          # Release en build/linux
  ./scripts/build_linux.sh --debug  # Debug en build/debug
  ./scripts/build_linux.sh --package # Compila y empaqueta en dist/
  ```
* **Compilación cruzada hacia Windows:**
  ```bash
  ./scripts/build_windows.sh        # Genera build/windows/clockmaster.exe
  ./scripts/build_windows.sh --package # Compila y genera dist/clockmaster-windows.zip
  ./scripts/build_windows.sh --run     # Compila y ejecuta con Wine
  ```
* **Empaquetar versiones ya construidas:**
  ```bash
  ./scripts/package.sh all          # Empaqueta Linux y Windows en dist/
  ./scripts/package.sh linux        # Solo Linux
  ./scripts/package.sh windows      # Solo Windows
  ```

### En Windows:
* **Compilar nativo en Windows:**
  ```cmd
  scripts\build_windows.bat         rem Compila en build\windows
  scripts\build_windows.bat --debug rem Compila en build\debug
  scripts\build_windows.bat --package rem Compila y empaqueta en dist\
  ```
* **Empaquetar versión de Windows:**
  ```cmd
  scripts\package_windows.bat       rem Genera dist\clockmaster-windows.zip
  ```

---
