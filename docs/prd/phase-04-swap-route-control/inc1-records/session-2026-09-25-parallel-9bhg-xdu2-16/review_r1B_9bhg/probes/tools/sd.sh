#!/bin/bash
f=$1
out=$(CQ_DANGLE=1 CQ_NOFREE=1 /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r1B/cq-opt.instr -passes=cq-lowering -S "$f" -o /dev/null 2>&1)
a=$(printf '%s\n' "$out" | grep -c "R1B-DANGLE stage=pre-specialize ")
b=$(printf '%s\n' "$out" | grep -c "R1B-DANGLE stage=post-specialize ")
c=$(printf '%s\n' "$out" | grep -c "R1B-DANGLE stage=clone-")
echo "$(basename $f) $a $b $c"
