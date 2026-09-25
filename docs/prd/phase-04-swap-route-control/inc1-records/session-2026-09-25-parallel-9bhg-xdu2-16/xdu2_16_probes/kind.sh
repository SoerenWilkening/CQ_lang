#!/bin/bash
# kind.sh OUTDIR [OPT] — K-independence of tests/e2e/slice_loop_condtree_select_hoisted.c
# (F-A1-6). Builds the COMMITTED source at K=3 (as committed) and K=1000 (the one
# `i < 3` edited), lowers both, and prints `wc -l`, non-blank lines, and the diff.
set -euo pipefail
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df
L=/usr/local/opt/llvm@19/bin
OUT=$1; OPT=${2:-$W/build/ir-pass/cq-opt}
mkdir -p "$OUT"
SRC=$W/tests/e2e/slice_loop_condtree_select_hoisted.c
cp -f "$SRC" "$OUT/k3.c"
sed '/for (int i = 0; i < 3; ++i)/s/i < 3; ++i/i < 1000; ++i/' "$SRC" > "$OUT/k1000.c"
test "$(grep -c 'for (int i = 0; i < 1000; ++i)' "$OUT/k1000.c")" = 1   # the CODE loop, exactly once (a header comment also spells `i < 3; ++i`)
for k in k3 k1000; do
  "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$OUT/$k.c" -o "$OUT/$k.s1.ll"
  "$OPT" -passes=cq-lowering -S "$OUT/$k.s1.ll" -o "$OUT/$k.s2.ll"
  echo "$k: wc -l = $(wc -l < "$OUT/$k.s2.ll"), non-blank = $(grep -c . "$OUT/$k.s2.ll")"
done
echo "--- diff (ModuleID/source_filename lines carry the file name and are expected to differ):"
diff "$OUT/k3.s2.ll" "$OUT/k1000.s2.ll" || true
