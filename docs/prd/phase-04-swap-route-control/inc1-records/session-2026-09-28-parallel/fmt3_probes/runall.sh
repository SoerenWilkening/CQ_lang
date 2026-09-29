#!/bin/bash
# runall.sh — runs every probe in the family through run.sh (env passes through: WHO, INC, TAG, SUB).
P=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/fmt3_probes
LIST=${LIST:-"a6 a6f a4 n9 n10 n1 n2 n3 n4a n4b n5 n6 n7 n8 n11 n12 n13 n13f n14 n15"}
for n in $LIST; do bash "$P/run.sh" "$n" 83 3; done
