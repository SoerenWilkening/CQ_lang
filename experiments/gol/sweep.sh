#!/bin/sh
# sweep.sh: Conway's Game of Life (https://github.com/bluekeybo/GameOfLife at 492f5da, one C file) through the
# lowering: every function alone with all arguments quantum, then under every mix of classical and quantum arguments.
# The file's main() is renamed gol_main on the command line so that a driver can supply its own; -D_DARWIN_C_SOURCE
# because the file asks for POSIX 1993 and uses getline, which macOS hides at that level.
set -eu
cd "$(dirname "$0")"
E=$(cd .. && pwd); R=$(cd ../.. && pwd)
L=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
PLUGIN=${PLUGIN:-$R/build/pass/libCQLower.so}
[ -d src ] || { git clone -q https://github.com/bluekeybo/GameOfLife src && git -C src checkout -q 492f5dabfed10201c345619bc5cb13c839741aaa; }
mkdir -p build
# One source change: the display loop `while (1)` has no exit, which the pass cannot lower yet (bead cq-hmxd5); it becomes
# a loop of 1000 generations.
sed -i '' 's/while (1) {/for (i = 0; i < 1000; i++) {/' src/src/gameOfLife.c
"$L/clang" -O1 -w -include "$R/spec/CQ.h" -Dmain=gol_main -D_DARWIN_C_SOURCE -S -emit-llvm src/src/gameOfLife.c -o build/linked.ll
echo "=== 1. all arguments quantum"
"$E/per_function.sh" build/linked.ll build/pf "$PLUGIN"
"$E/mask_sweep.sh" build/linked.ll build/masks build/pf/roots.txt "$PLUGIN"
"$L/llvm-extract" --func=nextGen --func=addPadding -S build/linked.ll -o build/kernel.ll   # for count.sh
