#!/bin/bash
set -e
cd "$(dirname "$0")"

mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON > /dev/null
make -j$(nproc)

echo "✓ build/pomodoro-tasks"
