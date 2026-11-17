#!/bin/sh
# Every float template of libqsoftfloat.a, through its shim, the lowered library and an integer-only toy
# backend, against the same root built natively (gen_shimtest.py).
#   softfloat/test/run_shimtest.sh [SAMPLES]        (needs build/libqsoftfloat.a)
set -eu
T=$(cd "$(dirname "$0")" && pwd)
SF=$(dirname "$T")
LLVM=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
B=$SF/build/shimtest; mkdir -p "$B"
"$SF/build.sh" native
python3 "$T/gen_toy_backend.py" "$B/toy_backend.c" "$SF"/build/cqsf.groups/g.*.lowered.ll --library-manifest "$SF/build/manifest.json"
python3 "$T/gen_shimtest.py" "$B/shimtest.c" --samples "${1:-12}"
"$LLVM/clang" -O1 -c "$B/toy_backend.c" -o "$B/toy_backend.o"
"$LLVM/clang" -O1 -c "$B/shimtest.c" -o "$B/shimtest.o"
"$LLVM/clang" "$B/shimtest.o" "$B/toy_backend.o" "$SF/build/native/cqsf_inner.o" "$SF/build/libqsoftfloat.a" -o "$B/shimtest"
"$B/shimtest"
