#!/bin/sh
# build.sh: TinyCC (https://github.com/TinyCC/tinycc at 5cef7f3f, 0.9.28rc) to one LLVM module, build/linked.ll: the
# compiler as its Makefile's ONE_SOURCE build (tcc.c including libtcc.c and every compiler unit) for the native target
# (x86-64, Mach-O), configured by its own ./configure. Its runtime library lib/ (assembly) is not part of it. The
# sources are unchanged.
set -eu
cd "$(dirname "$0")"
R=$(cd ../.. && pwd)
L=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
[ -d src ] || { git clone -q https://github.com/TinyCC/tinycc src && git -C src checkout -q 5cef7f3f85b0fbbd4663fd3518ba097d7fe3d738; }
[ -f src/config.h ] || (cd src && ./configure --cc="$L/clang" >/dev/null)
[ -f src/tccdefs_.h ] || make -C src tccdefs_.h >/dev/null
mkdir -p build
"$L/clang" -O1 -w -include "$R/spec/CQ.h" -Isrc -DONE_SOURCE=1 -S -emit-llvm src/tcc.c -o build/linked.ll
echo "functions: $(grep -c '^define ' build/linked.ll)"
