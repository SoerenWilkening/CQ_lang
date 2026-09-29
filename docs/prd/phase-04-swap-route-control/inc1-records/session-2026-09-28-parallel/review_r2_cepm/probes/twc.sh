#!/bin/bash
# twc.sh base... : C vs T on the COMPOSED binary (cepm round 2 + main ba4fdad4 = rhk5 + z0re).
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d
L=/usr/local/opt/llvm@19/bin
RT="$W/build/runtime/libcq_runtime.a"; TPL="$W/build/runtime/libcq_templates.a"
B=$S/r2_cepm/cq-opt.composed
cd $S/r2_cepm/p || exit 1
msg(){ grep -m1 'error:' $1 | sed 's/^.*error: //;s/<unknown>:0:0: //;s/^in function [^:]*: //'; }
for b in "$@"; do
  c="${b}C"; t="${b}T"
  for x in $c $t; do [ -f $x.s1.ll ] || continue; $B -passes=cq-lowering -S $x.s1.ll -o $x.k2.ll 2> $x.kerr; echo $? > $x.krc; done
  rc1=$(cat $c.krc); rc2=$(cat $t.krc 2>/dev/null || echo NA)
  e1=$(msg $c.kerr); e2=$(msg $t.kerr 2>/dev/null); w1=$(grep -c 'warning:' $c.kerr); w2=$(grep -c 'warning:' $t.kerr 2>/dev/null)
  if [ $rc2 = NA ]; then [ $rc1 = 0 ] && v=ACC-NOTWIN || v=DECL-NOTWIN
  elif [ $rc1 != 0 ] && [ $rc2 != 0 ]; then [ "$e1" = "$e2" ] && v=DECL-SAME || v=DECL-DIFF
  elif [ $rc1 = 0 ] && [ $rc2 = 0 ]; then
    v=ACC-SAME
    for x in $c $t; do python3 $W/tools/free_pairing_check.py $x.k2.ll > $x.k2b 2>&1 || v="ACC-2BFAIL($x)"; $L/clang $x.k2.ll $TPL $RT -o $x.kexe 2>/dev/null || v="LINKFAIL($x)"; done
    if [[ $v == ACC-SAME ]]; then for args in "5 7" "2 9" "9 1"; do ./$c.kexe $args > $c.ktr.${args// /_} 2>&1; ./$t.kexe $args > $t.ktr.${args// /_} 2>&1; cmp -s $c.ktr.${args// /_} $t.ktr.${args// /_} || v=ACC-DIFF; done; fi
  else v="VERDICT-DIFF(C=$rc1,T=$rc2)"; fi
  # stream identity vs the un-composed subject
  sid=""; if [ $rc1 = 0 ] && [ "$(cat $c.rc 2>/dev/null)" = 0 ]; then cmp -s $c.tr.5_7 $c.ktr.5_7 && sid="stream=subject" || sid="stream-MOVED-vs-subject"; fi
  echo "$b | COMPOSED $v | C: ${e1:-accept} (w$w1) | T: ${e2:-accept} (w$w2) $sid"
done
