#!/bin/bash
# Build qs_visualizer: pengganti cava + cava_feed.sh.
# Baca spektrum audio langsung dari PipeWire, output 64 bar (0-255) per baris ke stdout.
#
# Dependensi build: g++/clang++, libpipewire (dev), fftw3 (dev).
set -e

cd "$(dirname "$0")"

g++ -O2 -std=c++17 \
    -o qs_visualizer \
    qs_visualizer.cpp \
    $(pkg-config --cflags --libs libpipewire-0.3 fftw3) \
    -pthread

echo "OK: $(pwd)/qs_visualizer"