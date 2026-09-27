#!/bin/bash
# uafpin.sh : bd 1xp9's u1/u2/u3/u4/u5 under the deterministic test allocator and Guard
# Malloc, on the round-3 debugalloc (ce5fbf89, = the round-3 cq-opt objects) and the
# round-4 one. rc captured on its own line (r3B's L10 note: never `$?` after a
# substitution in the same line).
V=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8
cd "$V" || exit 1
R3=$V/bin/cq-opt-debugalloc.N0_null
R4=$W/build/ir-pass/cq-opt-debugalloc
for f in r4b/u2.ll r4b/u1.ll out/r4b__u5.s1.ll out/r4b__u3.s1.ll out/r4b__u4.s1.ll; do
  for B in "r3:$R3" "r4:$R4"; do
    tag=${B%%:*}; bin=${B#*:}
    for mode in lifo nofree; do
      CQ_OPT_DEBUG_ALLOC=$mode "$bin" -passes=cq-lowering -S "$f" -o /dev/null 2> uafpin.err
      rc=$?
      echo "$(basename "$f") $tag $mode rc=$rc $(grep -m1 -o 'error: .*' uafpin.err | cut -c1-80)"
    done
    DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib "$V/bin/cq-opt.$tag" -passes=cq-lowering -S "$f" -o /dev/null 2> uafpin.err
    rc=$?
    echo "$(basename "$f") $tag gmalloc(cq-opt) rc=$rc"
  done
done
