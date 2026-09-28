#!/bin/bash
# run_family.sh — the whole probe family on the ORACLE under the BASE header and under the
# option-(B) NOMERGE header variant.   Output: one line per (probe, header).
P=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/fmt3_probes
NM=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/fmt3/inc_nomerge
LIST=${LIST:-"a6 a6f a4 n9 n10 n1 n2 n3 n4a n4b n5 n6 n6b n7 n8 n11 n12 n13 n13f n14 n15 n16 n17 n17f n17d n18 n19 d13a1"}
for n in $LIST; do
  WHO=ORA TAG=base bash "$P/run.sh" "$n" 83 3
  WHO=ORA TAG=nomerge INC="$NM" bash "$P/run.sh" "$n" 83 3
done
