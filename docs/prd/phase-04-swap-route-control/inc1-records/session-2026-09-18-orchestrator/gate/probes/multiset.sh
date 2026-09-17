#!/bin/bash
# multiset.sh <a.c> <b.c> [ORACLE|SUBJECT] -- compare two probes' gate-symbol multisets mechanically.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/Projects/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ac2acfdde3461becc
which="${3:-SUBJECT}"
if [ "$which" = "ORACLE" ]; then B="$ORC"; else B="$SUBJ"; fi
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
run() {
  local f=$1 tag=$2
  "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/$tag.s1.ll" 2>/dev/null || { echo "CLANGFAIL"; return 1; }
  "$B/build/ir-pass/cq-opt" -load-pass-plugin "$B/build/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$T/$tag.s1.ll" -o "$T/$tag.s2.ll" 2>"$T/$tag.err" || { echo "DECLINE"; return 1; }
  "$LLVM/clang" "$T/$tag.s2.ll" "$B/build/runtime/libcq_templates.a" "$B/build/runtime/libcq_runtime.a" -o "$T/$tag.bin" 2>/dev/null || { echo "LINKFAIL"; return 1; }
  "$T/$tag.bin" > "$T/$tag.trace" 2>&1
  sed 's/(.*//' "$T/$tag.trace" | sort | uniq -c | sed 's/^ *//' > "$T/$tag.ms"
  return 0
}
run "$1" a || { echo "A FAILED"; exit 1; }
run "$2" b || { echo "B FAILED"; exit 1; }
echo "A = $(basename "$1")  trace lines: $(wc -l < "$T/a.trace" | tr -d ' ')"
echo "B = $(basename "$2")  trace lines: $(wc -l < "$T/b.trace" | tr -d ' ')"
echo "--- multiset diff (empty == IDENTICAL) ---"
if diff "$T/a.ms" "$T/b.ms"; then echo "MULTISET IDENTICAL"; else echo "*** MULTISET DIFFERS ***"; fi
echo "--- raw trace diff (non-empty == order divergence) ---"
if diff "$T/a.trace" "$T/b.trace" > /dev/null; then echo "TRACES BYTE-IDENTICAL"; else
  echo "traces differ (order); unified diff:"; diff "$T/a.trace" "$T/b.trace"
fi
