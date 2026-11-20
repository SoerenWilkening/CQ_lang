#!/bin/sh
# sweep.sh: ABC (https://github.com/maksimKorzh/abc, a small chess engine) through the lowering.
#  1. every function on its own with all arguments quantum (../per_function.sh);
#  2. every function under every mix of classical and quantum arguments except all-classical: one generated driver per
#     (function, mask) calls it from a program, classical arguments from argc, quantum ones from cq_theta, so the pass
#     makes that mask's clone. The other ABC functions and libc are declared roots, so a call stays a call.
# Functions with no argument take their quantum data from the globals (the board): step 1 covers them.
set -eu
cd "$(dirname "$0")"
E=$(cd .. && pwd); R=$(cd ../.. && pwd)
L=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
PLUGIN=${PLUGIN:-$R/build/pass/libCQLower.so}
[ -d src ] || git clone -q --depth 1 https://github.com/maksimKorzh/abc src
mkdir -p build/ir build/masks
# ABC declares its argument-less functions as `f()`: unprototyped in C17, so every call is typed `(...)` and is not a
# direct call of the definition (pass gap, bead cq-3fzuf). One source change: give them `(void)`.
sed -i '' 's/();/(void);/' src/src/abc.h
for c in src/src/*.c; do
    n=$(basename "$c" .c); [ "$n" = main ] && continue      # main() is the UCI loop: host code
    "$L/clang" -O1 -w -include "$R/spec/CQ.h" -include prelude.h -S -emit-llvm "$c" -o "build/ir/$n.ll"
done
"$L/llvm-link" -S build/ir/*.ll -o build/linked.ll

echo "=== 1. all arguments quantum"
"$E/per_function.sh" build/linked.ll build/pf "$PLUGIN"

"$E/mask_sweep.sh" build/linked.ll build/masks build/pf/roots.txt "$PLUGIN"
