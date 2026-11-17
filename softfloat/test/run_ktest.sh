#!/bin/sh
# The frem loop cutoff (ktest.c). Needs build/libqsoftfloat.a and build/shimtest/toy_backend.o (run_shimtest.sh).
set -eu
T=$(cd "$(dirname "$0")" && pwd)
SF=$(dirname "$T")
LLVM=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
B=$SF/build/shimtest
"$LLVM/clang" -O1 "$T/ktest.c" "$B/toy_backend.o" "$SF/build/native/cqsf_inner.o" "$SF/build/libqsoftfloat.a" -o "$B/ktest"
"$B/ktest"
