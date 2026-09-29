#!/bin/bash
# usage: pipe.sh <src.c> <tag> <incdir> [args...]  -> writes $S/out/<tag>.{s1.ll,s2.ll,err,2b,trace}
set -u
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/r1B_fmt3
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b
L=/usr/local/opt/llvm@19/bin
OPT=${OPT:-$W/build/ir-pass/cq-opt}
src=$1; tag=$2; inc=$3; shift 3
o=$S/out/$tag
"$L/clang" -I"$inc" -include CQ.h -O1 -emit-llvm -S "$src" -o $o.s1.ll 2>$o.cc.err || { echo "$tag: CLANG FAIL"; cat $o.cc.err; exit 1; }
"$OPT" -load-pass-plugin x -passes=cq-lowering -S $o.s1.ll -o $o.s2.ll 2>$o.err; rc=$?
if [ $rc -ne 0 ]; then echo "$tag: DECLINE rc=$rc :: $(grep -o 'cq [^:]*: .*' $o.err | head -1 | cut -c1-160)"; exit 0; fi
python3 $W/tools/free_pairing_check.py $o.s2.ll > $o.2b 2>&1; r2=$?
"$L/clang" $o.s2.ll $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o $o.exe 2>/dev/null || { echo "$tag: LINK FAIL"; exit 1; }
$o.exe "$@" > $o.trace 2>/dev/null
echo "$tag: ACCEPT lines=$(wc -l < $o.trace | tr -d ' ') 2b_rc=$r2 [$(tail -1 $o.2b | cut -c1-90)] warn=$(grep -c warning $o.err)"
