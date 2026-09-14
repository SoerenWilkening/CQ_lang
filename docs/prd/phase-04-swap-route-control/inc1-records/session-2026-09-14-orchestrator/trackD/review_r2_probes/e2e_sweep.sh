#!/bin/bash
# ALL tests/e2e/*.c through BOTH binaries: verdict + sha256(lowered IR, header-stripped)
# + md5(stderr). No link, no run — movement detection only. Zero-byte s1 refused.
set -u
LLVM=/usr/local/opt/llvm@19/bin
ROOT=/Users/sorenwilkening/Desktop/CQ_lang
O=$ROOT/build; S=/Users/sorenwilkening/Desktop/CQ_3d8q/build
T=$(mktemp -d)
for f in "$ROOT"/tests/e2e/*.c; do
  n=$(basename "$f" .c)
  "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/$n.ll" 2>/dev/null \
    || { echo "$n|STAGE1FAIL|STAGE1FAIL"; continue; }
  [ -s "$T/$n.ll" ] || { echo "$n|ZEROBYTE|ZEROBYTE"; continue; }
  out=""
  for b in "$O" "$S"; do
    if "$b/ir-pass/cq-opt" -passes=cq-lowering -S "$T/$n.ll" -o "$T/$n.s2" 2>"$T/$n.err"; then
      h=$(grep -v '^; ModuleID' "$T/$n.s2" | grep -v '^source_filename' | shasum -a 256 | cut -c1-16)
      out="$out|A:$h"
    else
      h=$(md5 -q "$T/$n.err")
      out="$out|D:${h:0:8}"
    fi
  done
  echo "$n$out"
done
rm -rf "$T"
