#!/bin/bash
# Copy the probe sources, scripts and raw measurement outputs into the record.
set -e
P=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/p9
D=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/probes
mkdir -p "$D/hdr" "$D/results"
cd "$P"
cp -f ./*.c "$D/"
cp -f gen.sh run.sh cmp.sh mk.sh mk2.sh mkyo.py mkrm2.py yo_main.ll ab_sweep.py \
      build_e2e_mods.py mutate.py assemble.sh assemble_all.sh e2e_trace.sh \
      final_sweeps.sh final_sweeps3.sh copy_probes.sh "$D/"
cp -f hdr/*.hdr "$D/hdr/"
cp -f ab_corpus.txt ab_corpus_final.txt mutate_out.txt mutate_out2.txt mutate_out3.txt \
      final_sweeps.txt final_sweeps3.txt "$D/results/"
[ -f ctest_full.txt ] && cp -f ctest_full.txt "$D/results/" || true
ls "$D" | wc -l
