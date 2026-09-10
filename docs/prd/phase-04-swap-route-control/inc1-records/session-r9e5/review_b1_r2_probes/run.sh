#!/bin/bash
# run.sh [PRE|POST] [filter] — run the round-2 probe corpus on one binary.
# Prints: <name> rc=<n> <diagnostic> | <name> rc=0 accepted trace=<N lines> 2b=<...>
set -u
LLVM=/usr/local/opt/llvm@19/bin
ROOT=${CQ_ROOT:-/Users/sorenwilkening/Desktop/CQ_lang}
HERE=$(cd "$(dirname "$0")" && pwd)
PRE=${CQ_PRE:-/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/05a94f34-2e8d-4c24-b48c-aaecd3961c97/scratchpad/impl_b1/pre}
which=${1:-POST}; filt=${2:-}
if [ "$which" = "PRE" ]; then OPT="$PRE/cq-opt"; PLUG="$PRE/libCQPass.so"; else OPT="$ROOT/build/ir-pass/cq-opt"; PLUG="$ROOT/build/ir-pass/libCQPass.so"; fi
OUT="$HERE/out/$which"; mkdir -p "$OUT"
for f in "$HERE"/c/*.c "$HERE"/ll/*.ll; do
  [ -e "$f" ] || continue
  b=$(basename "$f"); b="${b%.*}"
  if [ -n "$filt" ]; then case "$b" in $filt) ;; *) continue;; esac; fi
  case "$f" in
    *.c) "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -emit-llvm -S "$f" -o "$OUT/$b.s1.ll" 2>"$OUT/$b.clang" || { echo "$b CLANGFAIL"; continue; } ;;
    *.ll) cp -f "$f" "$OUT/$b.s1.ll" ;;
  esac
  "$OPT" -load-pass-plugin "$PLUG" -passes=cq-lowering -S "$OUT/$b.s1.ll" -o "$OUT/$b.s2.ll" 2>"$OUT/$b.err"; rc=$?
  if [ $rc -ne 0 ]; then
    echo "$b rc=$rc DECLINE: $(grep -o "cq [a-z0-9 -]*: [^;]*" "$OUT/$b.err" | head -1)"
  else
    python3 "$ROOT/tools/free_pairing_check.py" "$OUT/$b.s2.ll" > "$OUT/$b.2b" 2>&1; p2=$?
    "$LLVM/clang" "$OUT/$b.s2.ll" "$ROOT/build/runtime/libcq_templates.a" "$ROOT/build/runtime/libcq_runtime.a" -o "$OUT/$b.bin" 2>"$OUT/$b.link" && "$OUT/$b.bin" > "$OUT/$b.trace" 2>&1
    lr=$?
    n=$(wc -l < "$OUT/$b.trace" 2>/dev/null | tr -d ' ')
    echo "$b rc=0 ACCEPT trace=$n link/run=$lr 2b=$(sed -n 's/.*: \([0-9]* verified.*\)/\1/p' "$OUT/$b.2b" | head -1)${p2:+ 2brc=$p2}"
  fi
done
