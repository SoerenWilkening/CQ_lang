#!/bin/bash
# usage: build.sh <srcdir> <logprefix>
set -u
SRC="$1"; LOG="$2"
cmake -S "$SRC" -B "$SRC/build" -DLLVM_DIR=/usr/local/opt/llvm@19/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release > "$LOG.cfg.log" 2>&1 || { echo CFG_FAIL; exit 1; }
cmake --build "$SRC/build" -j5 > "$LOG.build.log" 2>&1
echo "build_rc=$?" >> "$LOG.build.log"
