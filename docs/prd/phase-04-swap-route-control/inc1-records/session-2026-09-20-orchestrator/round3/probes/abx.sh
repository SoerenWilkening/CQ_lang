#!/bin/bash
# abx.sh — 4-way verdict table, ERROR line only (a warning is not a verdict).
LLVM=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a8a02006bc710dbc0
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e25cef7b-131a-4e4d-a7b8-d6bf76310076/scratchpad
printf '%-30s |  %-46s|  %-46s|  %-46s|  %-46s\n' PROBE BASE MAIN TU9QONLY COMPOSED
for C in "$@"; do
  n=$(basename "$C" .c)
  printf '%-30s' "$n"
  for TAG in BASE MAIN TU9QONLY COMPOSED; do
    d=$S/out/$TAG; mkdir -p "$d"
    "$LLVM/clang" -I$W/include -include CQ.h -O1 -emit-llvm -S "$C" -o "$d/$n.s1.ll" 2>/dev/null
    "$S/bins/cq-opt.$TAG" -load-pass-plugin "$S/bins/libCQPass.$TAG.so" -passes=cq-lowering -S "$d/$n.s1.ll" -o "$d/$n.s2.ll" 2>"$d/$n.opt.err"
    rc=$?
    if [ $rc -eq 0 ]; then m="ACCEPT($(grep -c . $d/$n.s2.ll) lines)"; else m=$(grep '^error:' "$d/$n.opt.err" | sed -n 's/.*: cq \(.*\)$/\1/p' | head -1 | cut -c1-46); fi
    printf ' | %-46s' "$m"
  done
  echo
done
