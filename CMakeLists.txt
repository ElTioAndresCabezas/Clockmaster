cmake_minimum_required(VERSION 3.21)
project(Clockmaster LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Enlazar compile_commands.json en la raíz del proyecto para clangd / LSP
if(UNIX)
    file(CREATE_LINK
        "${CMAKE_BINARY_DIR}/compile_commands.json"
        "${CMAKE_SOURCE_DIR}/compile_commands.json"
        SYMBOLIC
    )
endif()

# Enlace estático para MinGW en Windows (hace el binario .exe 100% portable sin DLLs faltantes)
if(WIN32 AND MINGW)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static -static-libgcc -static-libstdc++")
endif()

include(FetchContent)
set(FETCHCONTENT_UPDATES_DISCONNECTED ON CACHE BOOL "Desactivar actualizaciones remotas si las dependencias ya están descargadas")
FetchContent_Declare(
    Slint
    GIT_REPOSITORY https://github.com/slint-ui/slint.git
    GIT_TAG release/1
    SOURCE_SUBDIR api/cpp
)
FetchContent_MakeAvailable(Slint)

add_executable(clockmaster
    src/main.cpp
    src/app_window.cpp
    src/app_window.hpp
    src/timer_manager.cpp
    src/timer_manager.hpp
)

set_property(TARGET clockmaster PROPERTY SLINT_EMBED_RESOURCES embed-files)

slint_target_sources(clockmaster
    ui/app_window.slint
)

target_link_libraries(clockmaster PRIVATE Slint::Slint)

# Ocultar la consola de comandos en Windows y copiar DLL requerida
if(WIN32)
    set_target_properties(clockmaster PROPERTIES WIN32_EXECUTABLE TRUE)
    add_custom_command(TARGET clockmaster POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_BINARY_DIR}/_deps/slint-build/slint_cpp.dll"
            $<TARGET_FILE_DIR:clockmaster>
    )
endif()

# Pruebas unitarias
enable_testing()
add_executable(clockmaster_tests
    tests/test_timer_manager.cpp
    src/timer_manager.cpp
    src/timer_manager.hpp
)
target_include_directories(clockmaster_tests PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_BINARY_DIR}"
)
target_link_libraries(clockmaster_tests PRIVATE Slint::Slint)
add_test(NAME TimerManagerTests COMMAND clockmaster_tests)

