#!/bin/sh
# The frem loop cutoff (ktest.c). Needs build/libqsoftfloat.a and build/shimtest/toy_backend.o (run_shimtest.sh).
set -eu
T=$(cd "$(dirname "$0")" && pwd)
SF=$(dirname "$T")
LLVM=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
B=$SF/build/shimtest
# softfloat/test/run_ktest.sh [f80]   (f80: build/libqsoftfloat_f80.a, the toy backend of run_shimtest.sh all|f80)
if [ "${1:-}" = f80 ]; then
    "$LLVM/clang" -O1 -DKT_F80 "$T/ktest.c" "$B/toy_backend.o" "$SF/build/native/cqsf_inner.o" "$SF/build/libqsoftfloat_f80.a" -o "$B/ktest_f80"
    "$B/ktest_f80"
else
    "$LLVM/clang" -O1 "$T/ktest.c" "$B/toy_backend.o" "$SF/build/native/cqsf_inner.o" "$SF/build/libqsoftfloat.a" -o "$B/ktest"
    "$B/ktest"
fi
