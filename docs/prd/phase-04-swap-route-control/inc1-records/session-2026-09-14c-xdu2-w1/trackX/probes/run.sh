#!/bin/zsh
# Track X probe runner. ORACLE == HEAD pass source (measured: ir-pass/ byte-identical).
# usage: run.sh <probe.c|probe.ll> [-DCQ_K=n ...]
set -u
LLVM=/usr/local/opt/llvm@19/bin
ROOT=/Users/sorenwilkening/Desktop/CQ_x5
BUILD=${CQ_BUILD:-/Users/sorenwilkening/Desktop/CQ_lang/build}
P="$1"; shift 2>/dev/null
T=$(mktemp -d)
B=$(basename "$P")
case "$P" in
  *.c)  "$LLVM/clang" -I$ROOT/include -include CQ.h -O1 -g -emit-llvm -S "$@" "$P" -o "$T/s1.ll" 2>"$T/cc.err" || { echo "$B | CLANGERR"; sed -n 1,3p "$T/cc.err"; rm -rf $T; exit 0; } ;;
  *.ll) cp "$P" "$T/s1.ll" ;;
esac
"$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/s2.ll" 2>"$T/e"
RC=$?
if [ $RC -ne 0 ]; then
  echo "$B | DECLINE exit=$RC | $(grep -o 'cq [a-z ]*lowering: .*\|error: .*' $T/e | head -1)"
  [ -n "${CQ_FULL:-}" ] && cat "$T/e"
  [ -n "${CQ_DBG:-}" ] && CQ_CTRL_DBG=1 "$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o /dev/null 2>&1 | grep -i 'decline\|classif\|f2\|prep' | head -20
else
  FP=$(python3 $ROOT/tools/free_pairing_check.py "$T/s2.ll" 2>&1 | tail -1)
  echo "$B | ACCEPT | 2b: $FP"
  if [ -n "${CQ_TRACE:-}" ]; then
    "$LLVM/clang" "$T/s2.ll" "$BUILD/runtime/libcq_templates.a" "$BUILD/runtime/libcq_runtime.a" -o "$T/a" 2>/dev/null && "$T/a"
  fi
  [ -n "${CQ_IR:-}" ] && cp "$T/s2.ll" "${CQ_IR}"
fi
[ -n "${CQ_S1:-}" ] && cp "$T/s1.ll" "${CQ_S1}"
rm -rf $T
