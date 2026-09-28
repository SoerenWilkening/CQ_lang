#!/bin/bash
# Second family batch: the stale-read/visible-form probes (n21*, n22) on the ORACLE, and the
# zt0b runtime-seed flavour (zt_*) on the ORACLE and on the bd z0re SUBJECT snapshot
# (cq-opt.z0re, sha-256 51b5f78d…), each under the BASE and the NOMERGE header.
P=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/fmt3_probes
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/fmt3
for n in n21 n21b n22; do
  WHO=ORA TAG=base bash "$P/run.sh" "$n" 83 3
  WHO=ORA TAG=nomerge INC="$S/inc_nomerge" bash "$P/run.sh" "$n" 83 3
done
for n in zt_p1 zt_a1 zt_a3 zt_a5; do
  SUB="$S/bin/cq-opt.z0re" WHO="ORA SUB" TAG=base bash "$P/run.sh" "$n" 83 20
  SUB="$S/bin/cq-opt.z0re" WHO="ORA SUB" TAG=nomerge INC="$S/inc_nomerge" bash "$P/run.sh" "$n" 83 20
done
