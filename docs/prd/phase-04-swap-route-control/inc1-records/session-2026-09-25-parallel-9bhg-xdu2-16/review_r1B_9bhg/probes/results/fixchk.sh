#!/bin/bash
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
f=$1
ref=$(CQ_NOFREE=1 $S/r1B/gen/multi.sh $S/r1B/cq-opt.instr $f 1 | awk '{print $2" "$3}')
fx=$($S/r1B/gen/multi.sh $S/r1B/cq-opt.fix8e5r $f 12)
fxr=$(CQ_REUSE=1 $S/r1B/gen/multi.sh $S/r1B/cq-opt.fix8e5r $f 3)
echo "$(basename $f) REF[$ref] FIX: $fx REUSE: $fxr"
