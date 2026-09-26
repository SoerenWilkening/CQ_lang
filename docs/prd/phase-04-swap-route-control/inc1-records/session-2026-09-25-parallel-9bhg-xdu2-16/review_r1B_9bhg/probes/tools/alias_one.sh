#!/bin/bash
f=$1; mode=$2
out=$(env $mode CQ_ALIAS=1 /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r1B/cq-opt.instr -passes=cq-lowering -S "$f" -o /dev/null 2>&1); rc=$?
a=$(printf '%s\n' "$out" | grep -c '^R1B-ALIAS')
printf '%s\t%s\t%s\n' "$(basename $f .ll)" "$rc" "$a"
