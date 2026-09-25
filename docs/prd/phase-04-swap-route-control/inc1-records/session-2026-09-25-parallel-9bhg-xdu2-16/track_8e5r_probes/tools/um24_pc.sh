#!/bin/bash
# um24_pc.sh [bin] [N] — the four bd um24 fixtures (+ the intermittent putchar
# one) under the three allocator modes, N runs each.
T=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2
BIN=${1:-$T/cq-opt.ora_alloc}; N=${2:-10}
cd $T
for f in iosink_reject_mux_literal_callee lowering_reject_break_uncollected_clone lowering_reject_inplace_rail_stale_w1_xor_bareout lowering_reject_inplace_rail_stale_w1_xor_derived lowering_io_controlled_putchar; do
  for m in system lifo nofree; do echo "$f $m: $(./dist.sh $BIN $m $W/ir-pass/test/$f.ll $N)"; done
done
