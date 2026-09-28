#!/bin/bash
# The z0re mutation matrix: every mutant binary through minilit over the z0re fixture
# set; a mutant is KILLED iff at least one fixture FAILS. The subject is run FIRST as
# the boundary control (must be all-PASS) and M0_null must also be all-PASS.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82
P=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/z0re_probes
LIST=$P/results/z0re_fixtures.txt
cd "$W" || exit 1
for m in subj_v2 M0_null M1_f1_literal_only M2_rel_int_noexcl M3_rel_fp_noexcl M4_no_record_prep M5_no_record_angle M6_no_reask M7_s3_literal_base M8_no_s789_skip; do
  out=$(python3 "$P/minilit.py" "$S/z0re_bins/cq-opt.$m" $(cat "$LIST"))
  fails=$(echo "$out" | grep '^FAIL' | cut -f2 | tr '\n' ' ')
  summary=$(echo "$out" | tail -1 | sed 's/ bin=.*//')
  if echo "$out" | grep -q '^FAIL'; then v=KILLED; else v=SURVIVED; fi
  echo "$m	$v	$summary	FAILS: $fails"
done
