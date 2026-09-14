#!/bin/zsh
# FIX-round measurement (d): is the circuit emitted for r14 REPRODUCIBLE?
# The angle stays `undef` in the emitted IR, so the printed value is whatever
# the -O0 stage-3 link materialises for an f64 IMPLICIT_DEF. Link it TWICE, into
# two different temp dirs, and run each binary three times.
set -u
LLVM=/usr/local/opt/llvm@19/bin
cd /Users/sorenwilkening/Desktop/CQ_undef
S2="$1"
for L in 1 2; do
  T=$(mktemp -d)
  "$LLVM/clang" "$S2" build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o "$T/a" 2>/dev/null || { echo "LINK $L FAILED"; continue; }
  echo "link $L  exe-sha=$(shasum -a 256 "$T/a" | cut -c1-16)"
  for R in 1 2 3; do
    echo "  run $L.$R: $("$T/a" | tr '\n' '|')"
  done
  rm -rf "$T"
done
