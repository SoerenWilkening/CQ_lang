#!/bin/bash
# One pass: stage 1 once (4-way), subject twice (NULL CONTROL, must move 0), oracle once.
# usage: run_ab.sh <subject cq-opt> <tag>
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
P=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/z0re_probes
python3 "$P/ab.py" "$S/frozen/cq-opt.main_9a230646" "$1" lit e2e multi probes > "$P/results/ab_$2.txt" 2>&1
echo done
