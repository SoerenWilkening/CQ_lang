#!/bin/bash
# fmt3 round 2 — the header A/B on the MERGED tree (main ba4fdad4 + fmt3), run through the
# merged tree's own cq-opt (bit-identical to main's). NULL CONTROL FIRST (committed header vs
# itself), then REAL (pre-fmt3 header == git show 9a230646:include/CQ.h, which main did not
# change, vs the committed header). Single-TU (ab_hdr.py) and multi-TU (ab_hdr_multi.py).
# Usage: ab_round2.sh <tag>      (tag names the output files, e.g. premerge / final)
P=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/fmt3_probes
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b
OI=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/fmt3/orig_inc
OPT=$W/build/ir-pass/cq-opt
T=${1:-r2}
python3 "$P/ab_hdr.py" "$W/include" "$W/include" "$OPT" -j 4 > "$P/ab_hdr.$T.NULL.txt" 2>&1
python3 "$P/ab_hdr_multi.py" "$W/include" "$W/include" "$OPT" > "$P/ab_hdr_multi.$T.NULL.txt" 2>&1
python3 "$P/ab_hdr.py" "$OI" "$W/include" "$OPT" -j 4 > "$P/ab_hdr.$T.REAL.txt" 2>&1
python3 "$P/ab_hdr_multi.py" "$OI" "$W/include" "$OPT" > "$P/ab_hdr_multi.$T.REAL.txt" 2>&1
echo "done $T"
