#!/bin/bash
# Track D ROUND-2 FIX harness. Usage: m.sh <TAG> <probe.c|probe.ll> ...
#   TAG = the output dir under this directory (BEFORE / AFTER / ORACLE).
# Stage 1 is generated ONCE per probe and REUSED; every .ll is checked NON-ZERO
# before it is measured (the passthrough trap). The binary is chosen by TAG.
set -u
LLVM=/usr/local/opt/llvm@19/bin
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT=/Users/sorenwilkening/Desktop/CQ_3d8q
TAG="$1"; shift
case "$TAG" in
  ORACLE) B=/Users/sorenwilkening/Desktop/CQ_lang/build ;;
  *)      B=/Users/sorenwilkening/Desktop/CQ_3d8q/build ;;
esac
mkdir -p "$HERE/$TAG" "$HERE/s1"
for f in "$@"; do
  n=$(basename "$f"); n="${n%.*}"
  case "$f" in
    *.c)  s1="$HERE/s1/$n.ll"
          if [ ! -s "$s1" ]; then
            "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$s1" \
               2> "$HERE/s1/$n.cc.err" || { echo "$n | STAGE1-FAIL"; continue; }
          fi ;;
    *.ll) s1="$f" ;;
  esac
  if [ ! -s "$s1" ]; then echo "$n | ZERO-BYTE-S1 (VACUOUS, skipped)"; continue; fi
  "$B/ir-pass/cq-opt" -passes=cq-lowering -S "$s1" -o "$HERE/$TAG/$n.s2.ll" 2> "$HERE/$TAG/$n.err"
  e=$?
  if [ $e -ne 0 ]; then
    d=$(grep -o "cq [a-z/ -]*lowering:[^\"]*" "$HERE/$TAG/$n.err" | head -1)
    [ -z "$d" ] && d=$(grep -o "cq [a-z]*:[^\"]*" "$HERE/$TAG/$n.err" | head -1)
    [ -z "$d" ] && d=$(head -1 "$HERE/$TAG/$n.err")
    echo "$n | D[$d]"
  else
    if [ ! -s "$HERE/$TAG/$n.s2.ll" ]; then echo "$n | ZERO-BYTE-S2 (VACUOUS)"; continue; fi
    "$LLVM/clang" "$HERE/$TAG/$n.s2.ll" "$B/runtime/libcq_templates.a" "$B/runtime/libcq_runtime.a" \
        -o "$HERE/$TAG/$n.exe" 2>> "$HERE/$TAG/$n.err" && "$HERE/$TAG/$n.exe" > "$HERE/$TAG/$n.trace" 2>&1
    t=$(grep -c . "$HERE/$TAG/$n.trace" 2>/dev/null || echo 0)
    echo "$n | A[trace=$t]"
  fi
done
