#!/bin/bash
# tr.sh NAME TAG ARG : link $P/NAME.TAG.s2.ll, run with ARG, write NAME.TAG.trace, 2b summary
P=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r2B9/p; W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e; L=/usr/local/opt/llvm@19/bin
n=$1; t=$2; a=${3:-3}
python3 $W/tools/free_pairing_check.py $P/$n.$t.s2.ll > $P/$n.$t.2b 2>&1; r2b=$?
$L/clang $P/$n.$t.s2.ll $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o $P/$n.$t.exe 2>/dev/null || { echo "$n $t LINKFAIL"; exit 1; }
args=""; for i in $(seq 2 $a); do args="$args x"; done
$P/$n.$t.exe $args > $P/$n.$t.trace 2>&1; rr=$?
echo "$n.$t 2b_rc=$r2b $(grep -o '[0-9]* verified, [0-9]* violation(s), [0-9]* unproven' $P/$n.$t.2b) run_rc=$rr lines=$(wc -l < $P/$n.$t.trace)"
