#!/bin/bash
# r2_pipeline.sh : bd rhk5 round 2 measurements, SEQUENTIAL (load discipline).
#   1. corpus A/B: NULL (r2 twice) first, then ORACLE vs r2, then round-1 vs r2
#   2. mutant tree synced to the subject, mutants R0..R9 built
#   3. mutant matrix over the rhk5 subset and over the multi-define complement
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rhk5
R=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/rhk5_probes
OUT=$R/round2
export RHK5_S1=$S/s1cache
echo "[$(date +%T)] A/B null"
python3 "$R/tools/ab.py" "$S/bin/cq-opt.r2" "$S/bin/cq-opt.r2" > "$OUT/ab_null_r2_twice.txt" 2>&1
echo "[$(date +%T)] A/B oracle vs r2"
python3 "$R/tools/ab.py" "$S/bin/cq-opt.oracle" "$S/bin/cq-opt.r2" > "$OUT/ab_oracle_vs_r2.txt" 2>&1
echo "[$(date +%T)] A/B r1 vs r2"
python3 "$R/tools/ab.py" "$S/bin/cq-opt.subject_v2" "$S/bin/cq-opt.r2" > "$OUT/ab_r1_vs_r2.txt" 2>&1
echo "[$(date +%T)] A/B extra (railbank pairs + examples)"
python3 "$R/tools/ab_extra.py" "$S/bin/cq-opt.oracle" "$S/bin/cq-opt.r2" > "$OUT/ab_extra_oracle_vs_r2.txt" 2>&1
echo "[$(date +%T)] mutant tree sync"
bash "$S/mut_setup.sh" > "$OUT/mut_setup_r2.txt" 2>&1
echo "[$(date +%T)] mutants build"
python3 "$R/tools/mutants_r2.py" > "$OUT/mutants_build_r2.txt" 2>&1
echo "[$(date +%T)] mutant matrix (subset)"
bash "$R/tools/mutmatrix.sh" "spec_|uncompute|clone|interior|live_record" r2 oracle R0_null R1_name_trusts_defined \
  R2_interposable_ok R3_cycle_licenses R4_no_depth_cap R5_cap_15 R6_copy_dst_admitted \
  R7_whole_plan_always R8_pieces_always R9_no_function_backstop > "$OUT/mutmatrix_r2_subset.txt" 2>&1
echo "[$(date +%T)] done"
