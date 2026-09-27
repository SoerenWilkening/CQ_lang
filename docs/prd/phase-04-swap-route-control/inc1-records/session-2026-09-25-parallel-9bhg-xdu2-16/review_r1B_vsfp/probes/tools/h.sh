#!/usr/bin/env bash
# r1B_vsfp harness. usage: h.sh <tag> <name> [args...]
# builds src/<name>.c (+ src/<name>.lib.c, llvm-linked like run_slice_multi.sh) -> out/<name>.s1.ll
# runs bin/cq-opt.<tag>; on accept: 2b strict + census, link (templates BEFORE runtime), run.
set -u
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r1Bv
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8
L=/usr/local/opt/llvm@19/bin
tag=$1; n=$2; shift 2
args=("$@"); [ ${#args[@]} -eq 0 ] && args=(5 7)
src=$S/src/$n.c; lib=$S/src/$n.lib.c; s1=$S/out/$n.s1.ll
if [ ! -f "$s1" ] || [ "$src" -nt "$s1" ] || { [ -f "$lib" ] && [ "$lib" -nt "$s1" ]; }; then
  if [ -f "$lib" ]; then
    $L/clang -O1 -emit-llvm -S -Wno-everything "$lib" -o $S/out/$n.lib.ll || exit 90
    $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything "$src" -o $S/out/$n.caller.ll || exit 90
    $L/llvm-link -S $S/out/$n.caller.ll $S/out/$n.lib.ll -o "$s1" || exit 90
  else
    $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything "$src" -o "$s1" || exit 90
  fi
fi
sz=$(wc -c < "$s1"); if [ "$sz" -lt 200 ]; then echo "[$tag] $n: TINY s1 ($sz bytes)"; exit 91; fi
s2=$S/out/$n.$tag.s2.ll; rm -f "$s2"
$S/bin/cq-opt.$tag -passes=cq-lowering -S "$s1" -o "$s2" 2> $S/out/$n.$tag.err
rc=$?
nw=$(grep -c 'warning:' $S/out/$n.$tag.err)
if [ $rc -ne 0 ]; then
  echo "[$tag] $n: DECL rc=$rc :: $(grep -m1 'error:' $S/out/$n.$tag.err | sed 's/.*error: //')"
  exit 0
fi
twob=$(python3 $W/tools/free_pairing_check.py "$s2" 2>&1); tbrc=$?
exe=$S/out/$n.$tag.exe
$L/clang -Wno-everything "$s2" $S/bin/libcq_templates.a $S/bin/libcq_runtime.a -o "$exe" 2>$S/out/$n.$tag.linkerr || { echo "[$tag] $n: LINKFAIL"; exit 92; }
"$exe" "${args[@]}" > $S/out/$n.$tag.trace 2>&1; xrc=$?
rm -f "$exe"
echo "[$tag] $n: ACC warn=$nw 2b_rc=$tbrc run_rc=$xrc trace_sha=$(shasum -a 256 $S/out/$n.$tag.trace | cut -c1-12) lines=$(wc -l < $S/out/$n.$tag.trace)"
echo "$twob" | grep -E 'verified|census|template rail|VIOLATION' | sed 's/^/    2b: /'
grep 'warning:' $S/out/$n.$tag.err | sed 's/.*warning: /    warn: /' | sort | uniq -c
