#!/bin/bash
# Track D FIX-round harness, ONE binary. Usage: m1.sh <tag> <build-dir> <probe.c|.ll>...
# Stage 1 is CACHED in s1/ (regenerated only when missing or zero-byte) and every
# .ll is checked NON-ZERO before it is measured — a 0-byte module ACCEPTS via the
# passthrough early-out, which is a VACUOUS pass and never a result.
set -u
LLVM=/usr/local/opt/llvm@19/bin
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT=/Users/sorenwilkening/Desktop/CQ_3d8q
TAG="$1"; B="$2"; shift 2
mkdir -p "$HERE/s1" "$HERE/$TAG"
for f in "$@"; do
  n=$(basename "$f"); n="${n%.*}"
  case "$f" in
    *.c) s1="$HERE/s1/$n.ll"
         if [ ! -s "$s1" ]; then
           "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$s1" \
              2> "$HERE/s1/$n.cc.err" || { echo "$n | STAGE1-FAIL"; continue; }
         fi ;;
    *.ll) s1="$f" ;;
  esac
  if [ ! -s "$s1" ]; then echo "$n | ZERO-BYTE-S1 (VACUOUS, skipped)"; continue; fi
  "$B/ir-pass/cq-opt" -passes=cq-lowering -S "$s1" -o "$HERE/$TAG/$n.s2.ll" 2> "$HERE/$TAG/$n.err"
  if [ $? -ne 0 ]; then
    d=$(grep -o "cq [a-z/ ]*lowering:[^\"]*" "$HERE/$TAG/$n.err" | head -1)
    [ -z "$d" ] && d=$(grep -o "cq [a-z]*:[^\"]*" "$HERE/$TAG/$n.err" | head -1)
    [ -z "$d" ] && d=$(head -1 "$HERE/$TAG/$n.err")
    echo "$n | D[$d]"
  else
    "$LLVM/clang" "$HERE/$TAG/$n.s2.ll" "$B/runtime/libcq_templates.a" "$B/runtime/libcq_runtime.a" \
        -o "$HERE/$TAG/$n.exe" 2>> "$HERE/$TAG/$n.err" && "$HERE/$TAG/$n.exe" > "$HERE/$TAG/$n.trace" 2>&1
    echo "$n | A[$(grep -c . "$HERE/$TAG/$n.trace" 2>/dev/null || echo 0)]"
  fi
done
