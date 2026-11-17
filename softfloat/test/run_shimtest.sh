#!/bin/sh
# Every float template of the lowered library, through its shim, the lowered library and an integer-only
# toy backend, against the same root built natively (gen_shimtest.py).
#   softfloat/test/run_shimtest.sh [SAMPLES [GROUP]]   GROUP: default (build/libqsoftfloat.a),
#                                                      f80 (build/libqsoftfloat_f80.a) or all (both; the default)
set -eu
T=$(cd "$(dirname "$0")" && pwd)
SF=$(dirname "$T")
LLVM=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
G=${2:-all}
B=$SF/build/shimtest; mkdir -p "$B"
"$SF/build.sh" native
LL="" LIBS=""
if [ "$G" != f80 ]; then LL="$LL $SF/build/cqsf.groups/g.*.lowered.ll"; LIBS="$LIBS $SF/build/libqsoftfloat.a"; fi
if [ "$G" != default ]; then LL="$LL $SF/build/cqsf_f80.groups/g.*.lowered.ll"; LIBS="$LIBS $SF/build/libqsoftfloat_f80.a"; fi
python3 "$T/gen_toy_backend.py" "$B/toy_backend.c" $LL --library-manifest "$SF/build/manifest.json"
python3 "$T/gen_shimtest.py" "$B/shimtest.c" --samples "${1:-12}" --group "$G"
"$LLVM/clang" -O1 -c "$B/toy_backend.c" -o "$B/toy_backend.o"
"$LLVM/clang" -O1 -c "$B/shimtest.c" -o "$B/shimtest.o"
"$LLVM/clang" "$B/shimtest.o" "$B/toy_backend.o" "$SF/build/native/cqsf_inner.o" "$SF/build/native/cqsf_roots_x.o" $LIBS -o "$B/shimtest"
"$B/shimtest"
