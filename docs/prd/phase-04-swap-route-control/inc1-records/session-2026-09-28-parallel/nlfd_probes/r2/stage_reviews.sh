#!/bin/bash
# stage_reviews.sh — copy both reviewers' probe batteries to the scratchpad (the committed
# review dirs are never written: tools/build.sh drops .s1.ll files next to the sources) and
# keep a copy of the current build as the named binary.   usage: stage_reviews.sh [TAG]
set -u
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/nlfd
R=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel
rm -rf "$SP/rev"; mkdir -p "$SP/rev/r1A" "$SP/rev/r1B" "$SP/bin"
cp -f "$R"/review_r1A_nlfd/probes/*.ll "$SP/rev/r1A/"
cp -Rf "$R/review_r1B_nlfd/probes/q1" "$R/review_r1B_nlfd/probes/q2" "$R/review_r1B_nlfd/probes/q4" "$SP/rev/r1B/"
rm -f "$SP"/rev/r1B/q*/*.s1.ll   # rebuilt by pairs.py with the SAME recipe
if [ -n "${1:-}" ]; then cp -f "$W/build/ir-pass/cq-opt" "$SP/bin/cq-opt.$1"; fi
echo "r1A: $(ls "$SP/rev/r1A" | wc -l) files; r1B: $(find "$SP/rev/r1B" -type f | wc -l) files"
