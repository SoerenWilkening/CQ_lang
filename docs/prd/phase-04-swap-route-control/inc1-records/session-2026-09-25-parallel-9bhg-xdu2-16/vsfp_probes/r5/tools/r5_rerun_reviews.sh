#!/bin/bash
# r5_rerun_reviews.sh : re-run the two round-4 reviewers' own verdict scripts on the current
# build (round 5) — r4A's results.sh (reads the reviewer's scratch probe dir; writes to a
# mktemp dir) and r4B's all.sh on a SCRATCH COPY of its probes (its run.sh writes out/ next to
# itself, so it is never run inside the committed record). Both under /bin/bash, as recorded.
V=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp
R=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16
cd "$V" || exit 1
rm -rf r4Bcopy
mkdir -p r4Bcopy/out
cp -Rf "$R/review_r4B_vsfp/probes/all.sh" "$R/review_r4B_vsfp/probes/pair.sh" "$R/review_r4B_vsfp/probes/run.sh" \
       "$R/review_r4B_vsfp/probes/src" "$R/review_r4B_vsfp/probes/aux" r4Bcopy/
echo "subject cq-opt: $(shasum -a 256 /Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/build/ir-pass/cq-opt | cut -c1-16)"
/bin/bash "$R/review_r4A_vsfp/probes/tools/results.sh" > "$V/r5_r4A_results.txt" 2>&1
echo "r4A rows: $(wc -l < "$V/r5_r4A_results.txt")"
/bin/bash r4Bcopy/all.sh > "$V/r5_r4B_verdicts.txt" 2>&1
echo "r4B rows: $(wc -l < "$V/r5_r4B_verdicts.txt")"
