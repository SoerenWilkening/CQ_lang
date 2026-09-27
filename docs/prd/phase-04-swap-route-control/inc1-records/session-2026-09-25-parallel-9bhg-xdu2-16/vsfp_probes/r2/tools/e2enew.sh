#!/bin/bash
# e2enew.sh : copy the new round-2 e2e slices into e2enew/ (harness naming) and
# pair each against the boolsel twin on r2d, round 1 (v5) and the oracle.
cd "$(dirname "$0")" || exit 1
E=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/tests/e2e
mkdir -p e2enew
cp -f "$E/slice_spec_dropped_arg_volatile_char.c" e2enew/vc.c
grep -v '^#ifdef\|^#error\|^#endif' "$E/spec_dropped_arg_volatile_lib.c" > e2enew/vc.lib.c
cp -f "$E/slice_spec_dropped_arg_dead_smax.c" e2enew/sm.c
grep -v '^#ifdef\|^#error\|^#endif' "$E/spec_dropped_arg_lib.c" > e2enew/sm.lib.c
cp -f "$E/slice_spec_dropped_arg_boolsel_twin.c" e2enew/tw.c
for t in r2d v5 main; do
  python3 h.py pair "$t" e2enew vc tw | cut -c1-140
  python3 h.py pair "$t" e2enew sm tw | cut -c1-140
done
