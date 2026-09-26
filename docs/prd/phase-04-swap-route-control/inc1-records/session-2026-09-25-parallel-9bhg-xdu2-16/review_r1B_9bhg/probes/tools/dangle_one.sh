#!/bin/bash
# usage: dangle_one.sh <file.ll> ; prints "<file>\t<rc>\t<dangle lines>"
f=$1
b=$(basename "$f" .ll)
out=$(CQ_DANGLE=1 CQ_NOFREE=1 /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r1B/cq-opt.instr -passes=cq-lowering -S "$f" -o /dev/null 2>&1)
rc=$?
d=$(printf '%s\n' "$out" | grep '^R1B-DANGLE' | sed 's/ ptr=.*//' | sort | uniq -c | tr '\n' ';')
printf '%s\t%s\t%s\n' "$b" "$rc" "$d"
