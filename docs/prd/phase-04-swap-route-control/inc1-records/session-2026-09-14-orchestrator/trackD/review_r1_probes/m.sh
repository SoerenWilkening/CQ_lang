#!/bin/bash
# Reviewer harness, Track D r1. Usage: m.sh <probe.c|probe.ll> ...
# Stage 1 generated ONCE per probe (.c only); BOTH binaries run on the SAME .ll.
# Every .ll is checked NON-ZERO before it is measured (the passthrough trap).
set -u
LLVM=/usr/local/opt/llvm@19/bin
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT=/Users/sorenwilkening/Desktop/CQ_lang
O=/Users/sorenwilkening/Desktop/CQ_lang/build
S=/Users/sorenwilkening/Desktop/CQ_3d8q/build
for f in "$@"; do
  n=$(basename "$f"); n="${n%.*}"
  case "$f" in
    *.c) s1="$HERE/s1/$n.ll"
         "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$s1" \
            2> "$HERE/s1/$n.cc.err" || { echo "$n | STAGE1-FAIL"; continue; } ;;
    *.ll) s1="$f" ;;
  esac
  if [ ! -s "$s1" ]; then echo "$n | ZERO-BYTE-S1 (VACUOUS, skipped)"; continue; fi
  row="$n |"
  for tag in ORACLE SUBJECT; do
    b=$O; [ "$tag" = SUBJECT ] && b=$S
    "$b/ir-pass/cq-opt" -passes=cq-lowering -S "$s1" -o "$HERE/$tag/$n.s2.ll" 2> "$HERE/$tag/$n.err"
    e=$?
    if [ $e -ne 0 ]; then
      d=$(grep -o "cq [a-z/ ]*lowering:[^\"]*" "$HERE/$tag/$n.err" | head -1)
      [ -z "$d" ] && d=$(head -1 "$HERE/$tag/$n.err")
      row="$row ${tag:0:1}=D[$d] |"
    else
      "$LLVM/clang" "$HERE/$tag/$n.s2.ll" "$b/runtime/libcq_templates.a" "$b/runtime/libcq_runtime.a" \
          -o "$HERE/$tag/$n.exe" 2>> "$HERE/$tag/$n.err" && "$HERE/$tag/$n.exe" > "$HERE/$tag/$n.trace" 2>&1
      t=$(grep -c . "$HERE/$tag/$n.trace" 2>/dev/null || echo 0)
      row="$row ${tag:0:1}=A[trace=$t] |"
    fi
  done
  echo "$row"
done
