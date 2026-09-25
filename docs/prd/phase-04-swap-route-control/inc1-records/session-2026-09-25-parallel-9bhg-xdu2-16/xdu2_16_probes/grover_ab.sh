#!/bin/bash
# grover_ab.sh — each example/grover/*.c through stage 1, then ORACLE vs NEW: exit code,
# stderr bytes, lowered-IR sha, stage 2b, and (on accept) trace sha.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df
L=/usr/local/opt/llvm@19/bin
D=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/x16/grover
F=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/frozen
cd "$D" || exit 9
for c in *.c; do
  b=${c%.c}
  "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$c" -o "$b.s1.ll" 2>/dev/null || { echo "$c: stage1 failed (skipped)"; continue; }
  for tag in main983 x16a; do
    "$F/cq-opt.$tag" -passes=cq-lowering -S "$b.s1.ll" -o "$b.$tag.s2.ll" 2> "$b.$tag.err"; rc=$?
    tr=""
    if [ "$rc" = 0 ]; then
      "$L/clang" "$b.$tag.s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$b.$tag.exe" 2>/dev/null && tr=$("./$b.$tag.exe" | shasum -a 256 | cut -c1-12)
    fi
    echo "$c [$tag] rc=$rc stderr=$(wc -c < "$b.$tag.err")B s2=$(shasum -a 256 "$b.$tag.s2.ll" 2>/dev/null | cut -c1-12) trace=$tr"
  done
  cmp -s "$b.main983.s2.ll" "$b.x16a.s2.ll" && echo "  -> lowered IR byte-identical" || echo "  -> lowered IR DIFFERS"
done
