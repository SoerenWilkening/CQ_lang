#!/bin/bash
# Does cq_measure need `nomerge` too? m1/m2/m3 (+ n2f) under THREE headers on the oracle:
#   base    = the pre-fmt3 header (orig_inc)
#   nomerge = the committed header (nomerge on cq_theta_* only)
#   measnm  = committed header + nomerge on cq_measure_* as well (a MEASUREMENT variant, not shipped)
P=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/fmt3_probes
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/fmt3
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b
for n in ${LIST:-m1 m2 m3 n2f}; do
  WHO=ORA TAG=base INC="$S/orig_inc" bash "$P/run.sh" "$n" 83 3
  WHO=ORA TAG=nomerge INC="$W/include" bash "$P/run.sh" "$n" 83 3
  WHO=ORA TAG=measnm INC="$S/inc_measnm" bash "$P/run.sh" "$n" 83 3
done
