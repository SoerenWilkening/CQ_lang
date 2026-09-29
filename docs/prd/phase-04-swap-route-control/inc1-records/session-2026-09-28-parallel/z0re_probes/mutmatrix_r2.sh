#!/bin/bash
# Round-2 mutation matrix: the round-2 subject first (boundary control, must be all-PASS),
# then R0_null (must be all-PASS), then each mutant of a round-2-changed conjunct, over
# results/r2_mut_fixtures.txt (248 fixtures: every angle-select, every state-prep and every
# runtime-seed fixture). KILLED iff >= 1 fixture FAILs.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82
P=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/z0re_probes
LIST=$P/results/r2_mut_fixtures.txt
cd "$W" || exit 1
for m in subj_r2 R0_null R1_step0_rederive R2_step0_never R3_step0_always R4_step0_flag_only R5_readd_constant R6_no_scope_line; do
  out=$(python3 "$P/minilit.py" "$S/z0re_bins/cq-opt.$m" $(cat "$LIST"))
  fails=$(echo "$out" | grep '^FAIL' | cut -f2 | tr '\n' ' ')
  summary=$(echo "$out" | tail -1 | sed 's/ bin=.*//')
  if echo "$out" | grep -q '^FAIL'; then v=KILLED; else v=SURVIVED; fi
  echo "$m	$v	$summary	FAILS: $fails"
done
