#!/bin/sh
# The classical self-test: the patched SoftFloat roots, built natively, against the host's x86 floats.
#   softfloat/test/run_selftest.sh            f16, bf16, f32, f64 (cqsf.roots)
#   softfloat/test/run_selftest.sh f80        the f80 roots (cqsf_f80.roots) against x87 long double
#   softfloat/test/run_selftest.sh int        the INT_X conversions (cq/cqsf_int.h) of both lists
set -eu
T=$(cd "$(dirname "$0")" && pwd)
SF=$(dirname "$T")
LLVM=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
"$SF/build.sh" native
SRC=$T/selftest.c; EXE=$SF/build/native/selftest; HOST=$T/host_bf16.c
[ "${1:-}" = f80 ] && SRC=$T/selftest_f80.c && EXE=$SF/build/native/selftest_f80 && HOST=$T/host_f80.c
[ "${1:-}" = int ] && SRC=$T/selftest_int.c && EXE=$SF/build/native/selftest_int && HOST=$T/host_int.c
"$LLVM/clang" -O1 -msse4.1 -mf16c -mfma -ffp-contract=off -I"$SF/cq" "$SRC" "$HOST" \
    "$SF/build/native/cqsf_roots.o" "$SF/build/native/cqsf_roots_x.o" "$SF/build/native/cqsf_inner.o" -lm -o "$EXE"
"$EXE"
