#!/bin/bash
# pair.sh NAME [ARG] — r2A harness pair3: subject S, oracle O, composed C (rhk5 r2+z0re r2+nlfd), z0re Z, nlfd N. NAME.c (+ NAME.lib.c, llvm-linked like
# run_slice_multi.sh) and, if present, NAME_T.c (the hand-inlined twin).
# For BOTH binaries (S = subject, O = oracle): opt rc, warnings/errors, stage 2b
# STRICT census, link (templates BEFORE runtime), run with ARG, trace; then
# trace_twin_equiv on S-subject vs S-twin.  Outputs under out/.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9
L=/usr/local/opt/llvm@19/bin
S=$W/build/ir-pass/cq-opt
O=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
WT=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees
BINS=${BINS:-"S=$S O=$O C=$SP/rev_r2A_rhk5/build/ir-pass/cq-opt Z=$WT/agent-a284a60d747f2ed82/build/ir-pass/cq-opt N=$WT/agent-a333a1777db2f2295/build/ir-pass/cq-opt"}
HERE=$(cd "$(dirname "$0")" && pwd)
n=$1; ARG=${2:-5}
cd $HERE/src
build() { # $1 name -> $1.s1.ll
  local m=$1
  if [ -f $m.ll ]; then cp -f $m.ll $m.s1.ll; return; fi
  local CQ="$L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything"
  if [ -f $m.lib.c ]; then
    $CQ $m.c -o $HERE/out/$m.caller.ll && $L/clang -O1 -emit-llvm -S -Wno-everything $m.lib.c -o $HERE/out/$m.lib.ll \
      && $L/llvm-link -S $HERE/out/$m.caller.ll $HERE/out/$m.lib.ll -o $m.s1.ll
  else
    $CQ $m.c -o $m.s1.ll
  fi
  [ -s $m.s1.ll ] || { echo "EMPTY s1 for $m"; exit 2; }
}
side() { # $1 bin-tag $2 bin $3 name
  local tag=$1 B=$2 m=$3 o=$HERE/out/$3.$1
  $B -passes=cq-lowering -S $m.s1.ll -o $o.s2.ll 2> $o.err; local rc=$?
  local w=$(grep -c 'warning:' $o.err); local e=$(grep -m1 'error:' $o.err | sed 's/.*error: //' | cut -c1-110)
  if [ $rc -ne 0 ]; then echo "  [$tag] $m: DECLINE rc=$rc  $e"; return; fi
  local fp=$(python3 $W/tools/free_pairing_check.py $o.s2.ll 2>&1 | grep -E 'census|verified' | tr '\n' ' ' | sed -E 's/.*rail mint\(s\) of which ([0-9]+) left allocated, ([0-9]+) template rail mint\(s\) of which ([0-9]+) left dirty.*([0-9]+) verified, ([0-9]+) violation\(s\), ([0-9]+) unproven.*/left=\1 dirty=\3 viol=\5 unpr=\6/')
  $L/clang -Wno-everything -c $o.s2.ll -o $o.o 2>/dev/null && $W/build/tests/e2e/cq_link.sh -o $o.exe $o.o $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a 2>/dev/null || { echo "  [$tag] $m: LINKFAIL"; return; }; rm -f $o.o
  $o.exe $ARG > $o.trace; rm -f $o.exe
  echo "  [$tag] $m: ACCEPT warn=$w 2b[$fp] lines=$(wc -l < $o.trace)"
}
build $n; [ -f ${n}_T.c ] && build ${n}_T
echo "== $n (arg $ARG)"
for tb in $BINS; do tag=${tb%%=*}; b=${tb#*=}; [ -x $b ] && side $tag $b $n; done
if [ -f ${n}_T.c ]; then for tb in $BINS; do tag=${tb%%=*}; b=${tb#*=}; [ -x $b ] && side $tag $b ${n}_T; done; fi
for tb in $BINS; do tag=${tb%%=*}; if [ -f $HERE/out/$n.$tag.trace ] && [ -f $HERE/out/${n}_T.$tag.trace ]; then echo "  equiv $tag-subject vs $tag-twin: $(python3 $W/tools/trace_twin_equiv.py --quiet-controls $HERE/out/$n.$tag.trace $HERE/out/${n}_T.$tag.trace | tail -1 | sed "s/.*: //")"; fi; done
if [ -f $HERE/out/$n.S.trace ] && [ -f $HERE/out/${n}_T.S.trace ]; then
  echo "  equiv S-subject vs S-twin: $(python3 $W/tools/trace_twin_equiv.py --quiet-controls $HERE/out/$n.S.trace $HERE/out/${n}_T.S.trace | tail -1 | sed 's/.*: //')"
fi
if [ -f $HERE/out/$n.S.trace ] && [ -f $HERE/out/$n.O.trace ]; then
  cmp -s $HERE/out/$n.S.trace $HERE/out/$n.O.trace && echo "  S==O trace (unchanged)" || echo "  S!=O trace (moved)"
fi
