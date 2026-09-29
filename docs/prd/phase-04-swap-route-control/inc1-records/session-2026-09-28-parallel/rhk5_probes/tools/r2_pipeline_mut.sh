#!/bin/bash
# r2_pipeline_mut.sh : the MUTANT half of r2_pipeline.sh, re-run after the 21:52 stop
# killed it at the tree sync (the A/B half had completed; its outputs were checked for
# a TOTAL line and a full denominator before being kept).
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rhk5
R=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/rhk5_probes
OUT=$R/round2
echo "[$(date +%T)] mutant tree sync"
bash "$S/mut_setup.sh" > "$OUT/mut_setup_r2.txt" 2>&1
echo "[$(date +%T)] mutants build"
python3 "$R/tools/mutants_r2.py" > "$OUT/mutants_build_r2.txt" 2>&1
echo "[$(date +%T)] mutant matrix (subset)"
bash "$R/tools/mutmatrix.sh" "spec_|uncompute|clone|interior|live_record" r2 oracle N0_null R1_name_trusts_defined \
  R2_interposable_ok R3_cycle_licenses R4_no_depth_cap R5_cap_15 R6_copy_dst_admitted \
  R7_whole_plan_always R8_pieces_always R9_no_function_backstop > "$OUT/mutmatrix_r2_subset.txt" 2>&1
echo "[$(date +%T)] done"
