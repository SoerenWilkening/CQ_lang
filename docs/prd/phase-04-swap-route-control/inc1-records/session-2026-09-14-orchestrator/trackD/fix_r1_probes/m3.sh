#!/bin/bash
# Track D FIX-round harness. Three binaries on ONE stage-1 file per probe:
#   ORACLE = /Users/sorenwilkening/Desktop/CQ_lang/build          (frozen session oracle, READ ONLY)
#   PRE    = <worktree>/build/prefix-B8                            (7fe2bcbf…, the reviewed binary, saved)
#   POST   = <worktree>/build                                      (the fix)
# Row: <probe> | O=<v> | P=<v> | S=<v>   where <v> is A[n trace lines] or D[string].
# Every .ll is checked NON-ZERO before it is measured (a 0-byte module ACCEPTS via
# the passthrough early-out — that is a VACUOUS pass, never a result).
set -u
LLVM=/usr/local/opt/llvm@19/bin
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT=/Users/sorenwilkening/Desktop/CQ_3d8q
ORACLE=/Users/sorenwilkening/Desktop/CQ_lang/build
PRE="$ROOT/build/prefix-B8"
POST="$ROOT/build"
mkdir -p "$HERE/s1" "$HERE/O" "$HERE/P" "$HERE/S"
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
  for tag in O P S; do
    case $tag in O) b=$ORACLE;; P) b=$PRE;; S) b=$POST;; esac
    "$b/ir-pass/cq-opt" -passes=cq-lowering -S "$s1" -o "$HERE/$tag/$n.s2.ll" 2> "$HERE/$tag/$n.err"
    e=$?
    if [ $e -ne 0 ]; then
      d=$(grep -o "cq [a-z/ ]*lowering:[^\"]*" "$HERE/$tag/$n.err" | head -1)
      [ -z "$d" ] && d=$(head -1 "$HERE/$tag/$n.err")
      row="$row $tag=D[$d] |"
    else
      rb="$b"; [ "$tag" = P ] && rb="$PRE"
      "$LLVM/clang" "$HERE/$tag/$n.s2.ll" "$rb/runtime/libcq_templates.a" "$rb/runtime/libcq_runtime.a" \
          -o "$HERE/$tag/$n.exe" 2>> "$HERE/$tag/$n.err" && "$HERE/$tag/$n.exe" > "$HERE/$tag/$n.trace" 2>&1
      t=$(grep -c . "$HERE/$tag/$n.trace" 2>/dev/null || echo 0)
      row="$row $tag=A[$t] |"
    fi
  done
  echo "$row"
done
