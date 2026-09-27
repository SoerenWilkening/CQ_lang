#!/bin/bash
# r6_rerun_reviews.sh : re-run the r5 reviewer's results.sh and r4A's results.sh unmodified on the
# current build (round 6), under /bin/bash; each writes only to scratch. Output next to this file.
V=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp
R=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16
echo "subject cq-opt: $(shasum -a 256 /Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/build/ir-pass/cq-opt | cut -c1-16)"
/bin/bash "$R/review_r5_vsfp/probes/tools/results.sh" > "$V/r6_r5rev_results.txt" 2>&1
echo "r5 rows: $(wc -l < "$V/r6_r5rev_results.txt")"
/bin/bash "$R/review_r4A_vsfp/probes/tools/results.sh" > "$V/r6_r4A_results.txt" 2>&1
echo "r4A rows: $(wc -l < "$V/r6_r4A_results.txt")"
