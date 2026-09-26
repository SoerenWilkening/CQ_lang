#!/bin/bash
f=$1; mode=$2
out=$(env $mode CQ_ALIAS=1 /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r1B/cq-opt.instr -passes=cq-lowering -S "$f" -o /dev/null 2>&1); rc=$?
a=$(printf '%s\n' "$out" | grep '^R1B-ALIAS stage=pre-lowerOps' | grep -v ':: *call \|:: *%[a-z_.0-9]* = call \|:: *ret ' | sed 's/.*fn=\([^ ]*\).*:: */\1: /' | tr '\n' '|')
r=$(printf '%s\n' "$out" | grep '^R1B-ALIAS stage=post-late3jru' | grep -c ':: *ret ')
e=$(printf '%s\n' "$out" | grep -o 'error: .*' | head -1 | cut -c1-90)
printf '%s\t%s\t%s\t%s\t%s\n' "$(basename $f .s1.ll)" "$rc" "$r" "$a" "$e"
