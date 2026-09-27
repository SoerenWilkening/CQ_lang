#!/usr/bin/env bash
# usage: pipe.sh <name> [runargs...]   -- src/<name>.c [+ src/<name>.lib.c [+ src/<name>.lib2.c]]
set -u
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
R=$SP/rA_vsfp
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8
L=/usr/local/opt/llvm@19/bin
ORA=$SP/frozen/cq-opt.main_aee8
SUB=$W/build/ir-pass/cq-opt
n=$1; shift
S=$R/src; O=$R/out; rm -f $O/$n.*
CFLAGS="-O1 -emit-llvm -S -Wno-everything"
$L/clang -I$W/include -include CQ.h $CFLAGS $S/$n.c -o $O/$n.caller.ll || { echo GENFAIL; exit 3; }
files=($O/$n.caller.ll)
for lib in $S/$n.lib.c $S/$n.lib2.c; do
  if [ -f $lib ]; then b=$(basename $lib .c); $L/clang -I$W/include -include CQ.h $CFLAGS $lib -o $O/$n.$b.ll || { echo GENFAIL; exit 3; }; files+=($O/$n.$b.ll); fi
done
if [ ${#files[@]} -gt 1 ]; then $L/llvm-link -S "${files[@]}" -o $O/$n.s1.ll || { echo LINKFAIL; exit 3; }; else cp -f $O/$n.caller.ll $O/$n.s1.ll; fi
sz=$(wc -c < $O/$n.s1.ll); echo "s1 bytes=$sz"
for tag in ORA SUB; do
  bin=${!tag}
  CQ_DEADARG_DBG=1 $bin -passes=cq-lowering -S $O/$n.s1.ll -o $O/$n.$tag.s2.ll 2> $O/$n.$tag.err
  rc=$?
  echo "== $tag rc=$rc"
  sed -e 's/^/   stderr: /' $O/$n.$tag.err | head -8
  if [ $rc -eq 0 ]; then
    python3 $W/tools/free_pairing_check.py $O/$n.$tag.s2.ll > $O/$n.$tag.2b 2>&1; echo "   2b rc=$? $(tail -2 $O/$n.$tag.2b | tr '\n' ' ')"
    $L/clang -Wno-everything $O/$n.$tag.s2.ll $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o $O/$n.$tag.exe 2>/dev/null || echo "   LINKFAIL"
    $O/$n.$tag.exe "$@" > $O/$n.$tag.trace 2>&1; echo "   exit=$? lines=$(wc -l < $O/$n.$tag.trace)"
    rm -f $O/$n.$tag.exe
  fi
done
if [ -f $O/$n.ORA.trace ] && [ -f $O/$n.SUB.trace ]; then cmp -s $O/$n.ORA.trace $O/$n.SUB.trace && echo "TRACE ORA==SUB" || echo "TRACE ORA!=SUB"; fi
