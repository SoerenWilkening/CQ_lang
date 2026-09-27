#!/bin/bash
# usage: run.sh name   (name.c in cwd [+ name.lib.c]) -> prints verdict for SUBJ and MAIN, trace diff
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8
L=/usr/local/opt/llvm@19/bin
SUBJ=$W/build/ir-pass/cq-opt
MAIN=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/frozen/cq-opt.main_aee8
n=$1
mkdir -p out
if [ -f $n.lib.c ]; then
  $L/clang -O1 -emit-llvm -S -Wno-everything $n.lib.c -o out/$n.lib.ll || exit 9
  $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything $n.c -o out/$n.caller.ll || exit 9
  $L/llvm-link -S out/$n.caller.ll out/$n.lib.ll -o out/$n.s1.ll || exit 9
elif [ -f $n.c ]; then
  $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything $n.c -o out/$n.s1.ll || exit 9
else
  cp -f $n.ll out/$n.s1.ll
fi
sz=$(wc -c < out/$n.s1.ll); if [ "$sz" -lt 200 ]; then echo "TINY s1"; exit 9; fi
for tag in SUBJ MAIN; do
  B=$SUBJ; [ $tag = MAIN ] && B=$MAIN
  $B -passes=cq-lowering -S out/$n.s1.ll -o out/$n.$tag.s2.ll 2> out/$n.$tag.err
  rc=$?
  err=$(grep -m1 -o 'error: .*' out/$n.$tag.err | cut -c1-150)
  warn=$(grep -c 'warning' out/$n.$tag.err)
  if [ $rc -eq 0 ]; then
    p2b=$(python3 $W/tools/free_pairing_check.py out/$n.$tag.s2.ll 2>&1 | grep -E 'verified|CENSUS|VIOL' | tr '\n' ' ' | cut -c1-200)
    $L/clang -Wno-everything out/$n.$tag.s2.ll $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o out/$n.$tag.exe 2>/dev/null
    out/$n.$tag.exe 3 > out/$n.$tag.trace 2>&1
    echo "$tag: ACCEPT warn=$warn lines=$(wc -l < out/$n.$tag.trace) 2b: $p2b"
    rm -f out/$n.$tag.exe
  else
    rm -f out/$n.$tag.s2.ll
    echo "$tag: DECLINE rc=$rc $err"
  fi
done
