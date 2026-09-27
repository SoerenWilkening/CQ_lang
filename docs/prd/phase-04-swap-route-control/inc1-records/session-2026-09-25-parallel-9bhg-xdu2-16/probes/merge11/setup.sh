#!/bin/bash
# Regenerate r1B_9bhg's alias families into scratchpad/alias9/<family>/ and build
# every <name>.s1.ll (caller -include CQ.h at -O1, llvm-linked with the family's
# lib.c), exactly as r1B's gen.sh / run_slice_multi.sh do.
set -e
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
R=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/review_r1B_9bhg/probes
A=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/alias9
for fam in alias_gen alias_gen2 alias_gen3 alias_gen5 alias_gen6; do
  rm -rf "$A/$fam"; mkdir -p "$A/$fam"
  cp -f "$R/$fam/lib.c" "$A/$fam/"
  cp -f "$R/$fam"/*.c "$A/$fam/" 2>/dev/null || true
  [ -f "$R/$fam/gen.sh" ] && cp -f "$R/$fam/gen.sh" "$A/$fam/"
done
# generators (alias_gen's own xargs build step overflows the command line under
# this worktree's long path; its s1 modules are built by the loop below instead)
set +e
bash "$A/alias_gen/gen.sh" > /dev/null 2>&1
for fam in alias_gen2 alias_gen3 alias_gen6; do bash "$A/$fam/gen.sh" > /dev/null; done
for fam in alias_gen alias_gen2 alias_gen3 alias_gen5 alias_gen6; do
  cd "$A/$fam"
  "$L/clang" -O1 -emit-llvm -S lib.c -o lib.ll
  for c in *.c; do
    [ "$c" = lib.c ] && continue
    b=${c%.c}
    "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$c" -o "$b.caller.ll" 2>/dev/null &&
      "$L/llvm-link" -S "$b.caller.ll" lib.ll -o "$b.s1.ll"
  done
done
for fam in alias_gen alias_gen2 alias_gen3 alias_gen5 alias_gen6; do
  n=$(ls "$A/$fam"/*.s1.ll | wc -l); e=$(find "$A/$fam" -name '*.s1.ll' -size -200c | wc -l)
  echo "$fam: $n s1 modules ($e tiny)"
done
