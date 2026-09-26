#!/bin/bash
# usage: run.sh name [arg]  (src/name.c or src/name.ll) -> verdict for SUBJ, NOFREE, LIFO, MAIN + 2b + trace
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8
L=/usr/local/opt/llvm@19/bin
SUBJ=$W/build/ir-pass/cq-opt
DBG=$W/build/ir-pass/cq-opt-debugalloc
MAIN=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/frozen/cq-opt.main_aee8
n=$1; arg=${2:-3}
if [ -f src/$n.c ]; then
  $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything ${CFLAGS_EXTRA} src/$n.c -o out/$n.s1.ll || { echo "CLANG FAIL"; exit 9; }
else
  [ -f src/$n.ll ] || { echo "NO SRC $n"; exit 9; }; cp -f src/$n.ll out/$n.s1.ll
fi
sz=$(wc -c < out/$n.s1.ll); if [ "$sz" -lt 200 ]; then echo "TINY s1"; exit 9; fi
for tag in SUBJ NOFREE LIFO MAIN; do
  B=$SUBJ; env=""
  [ $tag = MAIN ] && B=$MAIN
  [ $tag = NOFREE ] && { B=$DBG; export CQ_OPT_DEBUG_ALLOC=nofree; }
  [ $tag = LIFO ] && { B=$DBG; export CQ_OPT_DEBUG_ALLOC=lifo; }
  $B -passes=cq-lowering -S out/$n.s1.ll -o out/$n.$tag.s2.ll 2> out/$n.$tag.err
  rc=$?
  unset CQ_OPT_DEBUG_ALLOC
  err=$(grep -m1 -o 'error: .*' out/$n.$tag.err | cut -c1-140)
  warn=$(grep -c 'warning' out/$n.$tag.err)
  if [ $rc -eq 0 ]; then
    p2b=$(python3 $W/tools/free_pairing_check.py out/$n.$tag.s2.ll 2>&1 | grep -E 'verified|CENSUS|VIOL' | tr '\n' ' ' | cut -c1-220)
    $L/clang -Wno-everything out/$n.$tag.s2.ll $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o out/$n.$tag.exe 2>/dev/null
    out/$n.$tag.exe $arg > out/$n.$tag.trace 2>&1
    echo "$n $tag: ACCEPT warn=$warn lines=$(wc -l < out/$n.$tag.trace) sha=$(shasum out/$n.$tag.trace|cut -c1-10) 2b: $p2b"
    rm -f out/$n.$tag.exe
  else
    rm -f out/$n.$tag.s2.ll
    echo "$n $tag: DECLINE rc=$rc $err"
  fi
done
