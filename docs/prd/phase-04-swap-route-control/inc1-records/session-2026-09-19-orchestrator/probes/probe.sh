#!/bin/bash
# probe.sh <file.c|file.ll> [WT]  -- run stage1+stage2 in the worktree, print hash + verdict
set -uo pipefail
WT=${WT:-/Users/sorenwilkening/Desktop/Projects/cq-wt-zujr}
L=/usr/local/opt/llvm@19/bin
SC=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/f7470aeb-8222-4499-94df-fe0b1a412365/scratchpad/zujr
IN="$1"; B=$(basename "$IN"); B=${B%.*}
H=$(shasum -a 256 "$WT/build/ir-pass/cq-opt" | cut -c1-8)
if [[ "$IN" == *.c ]]; then
  "$L/clang" -I"$WT/include" -include CQ.h -O1 -emit-llvm -S "$IN" -o "$SC/$B.s1.ll" 2>"$SC/$B.s1.err" || { echo "[$H] $B STAGE1-FAIL"; cat "$SC/$B.s1.err"; exit 2; }
else
  cp -f "$IN" "$SC/$B.s1.ll"
fi
ERR=$("$L/opt" -load-pass-plugin "$WT/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$SC/$B.s1.ll" -o "$SC/$B.s2.ll" 2>&1)
EX=$?
if [[ $EX -eq 0 ]]; then
  echo "[$H] $B ACCEPT (exit 0)${ERR:+  stderr: $ERR}"
else
  echo "[$H] $B DECLINE (exit $EX): $ERR"
fi
