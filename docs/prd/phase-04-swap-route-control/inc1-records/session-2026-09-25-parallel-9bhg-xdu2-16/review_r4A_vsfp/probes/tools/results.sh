#!/bin/bash
# Re-runs every row of review_r4A_vsfp and prints the verdicts (bash, not zsh).
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8
L=/usr/local/opt/llvm@19/bin
TPL=$W/build/runtime/libcq_templates.a; RT=$W/build/runtime/libcq_runtime.a
bin() { case $1 in S) echo $W/build/ir-pass/cq-opt;; M) echo $SP/frozen/cq-opt.main_aee8;; *) echo $SP/vsfp/bin/cq-opt.$1;; esac; }
T=$(mktemp -d)
one() { # one <tag> <s1.ll> -> prints "rc=<opt> 2b=<...> run=<rc> lines=<n>" ; leaves $T/<base>.<tag>.trace
  local tag=$1 in=$2 b; b=$(basename ${in%.ll}); local o=$T/$b.$tag.s2.ll
  $(bin $tag) -passes=cq-lowering -S "$in" -o "$o" 2>$o.err; local rc=$?
  if [ $rc -ne 0 ]; then echo "opt=$rc $(grep -o 'error: .*' $o.err | head -1 | cut -c1-110)"; return; fi
  local pb; pb=$(python3 $W/tools/free_pairing_check.py "$o" | grep -o '[0-9]* verified, [0-9]* violation(s), [0-9]* unproven')
  $L/clang -Wno-everything "$o" $TPL $RT -o $o.exe 2>/dev/null || { echo "opt=0 LINKFAIL"; return; }
  $o.exe 5 > $T/$b.$tag.trace 2>/dev/null; local r=$?
  echo "opt=0 2b[$pb] run=$r lines=$(wc -l < $T/$b.$tag.trace | tr -d ' ')"
}
cmpt() { cmp -s $T/$1.trace $T/$2.trace && echo TRACE-IDENT || echo TRACE-DIFF; }
echo "binaries: S=$(shasum -a 256 $(bin S) | cut -c1-16) M=$(shasum -a 256 $(bin M) | cut -c1-16) r2=$(shasum -a 256 $(bin r2) | cut -c1-16) r3=$(shasum -a 256 $(bin r3) | cut -c1-16)"
echo "== F-YA-1: a recorded-dead BYVAL / nonnull pointer slot is neutralised to null"
for p in bv bvn2 pn; do for t in r2 r3 S M; do echo "$p [$t]: $(one $t $SP/r4A/c/$p.s1.ll)"; done
  grep -o 'call i32 @__cq_q_[a-z]*_[0-9]*([^)]*)' $T/$p.s1.S.s2.ll | sed "s/^/   S call: /"; done
echo "== nested-clone spellings vs DAE twins (subject)"
for p in "N1 N1T" "N3 N3T" "N4 N4T" "N5 N5T" "N7 N7T" "N8 N7T" "N2 N2T"; do set -- $p
  a=$(one S $SP/r4A/src/$1.ll); b=$(one S $SP/r4A/src/$2.ll); echo "$1 vs $2: $(cmpt $1.S $2.S) | $a | T: $b"; done
echo "N2 on ORACLE: $(one M $SP/r4A/src/N2.ll) ; S==M trace: $(cmpt N2.S N2.M)"
echo "== C-level nested (volatile-fold empty arm), with and without -g, vs DAE twin cnD"
for p in cn cng cnD; do echo "$p [S]: $(one S $SP/r4A/c/$p.s1.ll)"; done
echo "cn vs cnD: $(cmpt cn.s1.S cnD.s1.S); cng vs cnD: $(cmpt cng.s1.S cnD.s1.S)"
echo "== r3A re-derivation (probe vs LLVM inliner twin INL), subject"
R=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/review_r3A_vsfp/probes/src
for p in a1_add a1_deadop a1_icmp a1_sext a1_xorself a2_chain a3_width g1c n5_nested e2b f1b f2b fpfloatb fplongdb; do
  $L/opt -S -passes='cgscc(inline),function(instcombine<no-verify-fixpoint>,simplifycfg,adce),globaldce' $R/$p.ll -o $T/${p}_INL.ll 2>/dev/null
  cp -f $R/$p.ll $T/$p.ll; a=$(one S $T/$p.ll); b=$(one S $T/${p}_INL.ll); echo "$p: $(cmpt $p.S ${p}_INL.S) | $a | INL: $b"; done
rm -rf $T
