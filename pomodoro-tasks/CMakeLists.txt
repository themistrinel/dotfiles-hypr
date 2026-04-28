cmake_minimum_required(VERSION 3.20)
project(pomodoro-tasks CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(PkgConfig REQUIRED)
pkg_check_modules(WEBKIT REQUIRED webkit2gtk-4.1)
pkg_check_modules(PULSE  REQUIRED libpulse-simple)
pkg_check_modules(TRAY   REQUIRED appindicator3-0.1)
pkg_check_modules(EVDEV  REQUIRED libevdev)

# Embed ui/index.html into a C++ header at build time
file(READ "${CMAKE_SOURCE_DIR}/ui/index.html" UI_HTML_CONTENT)
# Escape backslashes and quotes, then wrap in raw string
file(WRITE "${CMAKE_BINARY_DIR}/ui_html.h"
    "static const char* UI_HTML = R\"HTMLEOF(\n${UI_HTML_CONTENT}\n)HTMLEOF\";\n")

add_executable(pomodoro-tasks
    src/main.cpp
    src/app.cpp
    src/task_store.cpp
    src/timer.cpp
    src/waybar.cpp
    src/wal_theme.cpp
    src/ipc.cpp
    src/audio.cpp
)

target_include_directories(pomodoro-tasks PRIVATE src ${CMAKE_BINARY_DIR}
    ${WEBKIT_INCLUDE_DIRS} ${PULSE_INCLUDE_DIRS} ${TRAY_INCLUDE_DIRS})
target_link_libraries(pomodoro-tasks PRIVATE
    ${WEBKIT_LIBRARIES} ${PULSE_LIBRARIES} ${TRAY_LIBRARIES})
target_compile_options(pomodoro-tasks PRIVATE
    ${WEBKIT_CFLAGS_OTHER} ${PULSE_CFLAGS_OTHER} ${TRAY_CFLAGS_OTHER})

# ── Typing sounds daemon ──────────────────────────────────────────────────────
add_executable(typing-sounds src/typing_sounds_daemon.cpp)
target_include_directories(typing-sounds PRIVATE ${PULSE_INCLUDE_DIRS} ${EVDEV_INCLUDE_DIRS})
target_link_libraries(typing-sounds PRIVATE ${PULSE_LIBRARIES} ${EVDEV_LIBRARIES})
target_compile_options(typing-sounds PRIVATE ${PULSE_CFLAGS_OTHER} ${EVDEV_CFLAGS_OTHER})
