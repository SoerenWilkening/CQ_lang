#!/bin/bash
# guard_validate.sh — record the semantic taintset_scrub_guard's validation:
# clean header, its own --selftest, and ALL THREE Rule-13 fool corpora run
# UNMODIFIED against it (they call the guard's `check()` API, which it keeps):
# r1A guard_bypass.py, r1B guard_fool.py, r2-delta guard_fool_r2.py.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2
D=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16
O=$D/track_8e5r_probes/results
cd "$W"
python3 tools/taintset_scrub_guard.py > "$O/guard_v3_clean.txt" 2>&1; echo "rc=$?" >> "$O/guard_v3_clean.txt"
python3 tools/taintset_scrub_guard.py --selftest > "$O/guard_v3_selftest.txt" 2>&1; echo "rc=$?" >> "$O/guard_v3_selftest.txt"
python3 "$D/review_r1A_8e5r/probes/guard_bypass.py" "$W" > "$O/guard_v3_vs_r1A_corpus.txt" 2>&1
python3 "$D/review_r1B_8e5r/probes/guard_fool.py" "$W" > "$O/guard_v3_vs_r1B_corpus.txt" 2>&1
python3 "$D/review_r2_delta_8e5r/probes/guard_fool_r2.py" "$W" > "$O/guard_v3_vs_r2_corpus.txt" 2>&1
tail -n 2 "$O"/guard_v3_*.txt
