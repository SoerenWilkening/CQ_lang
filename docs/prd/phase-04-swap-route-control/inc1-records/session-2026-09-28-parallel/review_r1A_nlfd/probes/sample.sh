#!/bin/bash
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad; W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295; P=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r1A_nlfd/probes; C=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/nlfd_probes/src/cells; export OUT=$SP/r1A_nlfd/cells; mkdir -p $OUT; cd $P
while read s t; do
  for b in S O A; do r=$(./run.sh $b $C/$s.ll 5 7); rt=$(./run.sh $b $C/$t.ll 5 7); v="-"; if [ -f $OUT/$s.$b.trace ] && [ -f $OUT/$t.$b.trace ]; then cmp -s $OUT/$s.$b.trace $OUT/$t.$b.trace && v=TRACE-IDENT || v=TRACE-DIFF; fi; echo "$s [$b] ${r:0:125} || twin: ${rt:0:45} => $v"; rm -f $OUT/$s.$b.trace; done
done
