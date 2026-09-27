#!/bin/bash
# The coordinator's targeted ctest subset on the merged tree.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
O=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/merge12/ctest_targeted.txt
RE='spec|twin-identical|multi|scrub|taintset|volatile'
{
  shasum -a 256 "$W/build/ir-pass/cq-opt" "$W/build/ir-pass/cq-opt-debugalloc" | cut -c1-24
  uptime
  ctest --test-dir "$W/build" -N -R "$RE" | tail -1
  start=$(date +%s)
  ctest --test-dir "$W/build" -j6 -R "$RE" --output-on-failure
  echo "wall_seconds=$(( $(date +%s) - start ))"
  uptime
} > "$O" 2>&1
grep -E "Total Tests|tests passed|tests failed|Total Test time|wall_seconds|load averages|\*\*\*|^[0-9a-f]{24}" "$O"
