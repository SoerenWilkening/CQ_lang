#!/bin/bash
# tw.sh base... : C vs T on SUBJECT (round 2), with R1B (round 1b) and ORACLE verdicts on C and T.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d
L=/usr/local/opt/llvm@19/bin
RT="$W/build/runtime/libcq_runtime.a"; TPL="$W/build/runtime/libcq_templates.a"
SUBJ=$S/cepm/cq-opt.subj3; R1B=$S/cepm/cq-opt.subj2; ORA=$S/frozen/cq-opt.main_9a230646
cd $S/r2_cepm/p || exit 1
msg(){ grep -m1 'error:' $1 | sed 's/^.*error: //;s/<unknown>:0:0: //;s/^in function [^:]*: //'; }
for b in "$@"; do
  c="${b}C"; t="${b}T"
  for x in $c $t; do
    [ -f $x.s1.ll ] || continue
    $SUBJ -passes=cq-lowering -S $x.s1.ll -o $x.s2.ll 2> $x.err; echo $? > $x.rc
    $R1B -passes=cq-lowering -S $x.s1.ll -o $x.b2.ll 2> $x.berr; echo $? > $x.brc
    $ORA -passes=cq-lowering -S $x.s1.ll -o $x.o2.ll 2> $x.oerr; echo $? > $x.orc
  done
  rc1=$(cat $c.rc); rc2=$(cat $t.rc 2>/dev/null || echo NA)
  e1=$(msg $c.err); e2=$(msg $t.err 2>/dev/null)
  w1=$(grep -c 'warning:' $c.err); w2=$(grep -c 'warning:' $t.err 2>/dev/null)
  if [ $rc2 = NA ]; then [ $rc1 = 0 ] && v=ACC-NOTWIN || v=DECL-NOTWIN
  elif [ $rc1 != 0 ] && [ $rc2 != 0 ]; then [ "$e1" = "$e2" ] && v=DECL-SAME || v=DECL-DIFF
  elif [ $rc1 = 0 ] && [ $rc2 = 0 ]; then
    v=ACC-SAME
    for x in $c $t; do python3 $W/tools/free_pairing_check.py $x.s2.ll > $x.2b 2>&1 || v="ACC-2BFAIL($x)"; $L/clang $x.s2.ll $TPL $RT -o $x.exe 2>/dev/null || v="LINKFAIL($x)"; done
    if [[ $v == ACC-SAME ]]; then for args in "5 7" "2 9" "9 1"; do ./$c.exe $args > $c.tr.${args// /_} 2>&1; ./$t.exe $args > $t.tr.${args// /_} 2>&1; cmp -s $c.tr.${args// /_} $t.tr.${args// /_} || v=ACC-DIFF; done; fi
  else v="VERDICT-DIFF(C=$rc1,T=$rc2)"; fi
  echo "$b | SUBJ $v | C: ${e1:-accept} (w$w1) | T: ${e2:-accept} (w$w2) | R1B C: $(cat $c.brc) $(msg $c.berr) | ORA C: $(cat $c.orc) $(msg $c.oerr) | ORA T: $(cat $t.orc 2>/dev/null) $(msg $t.oerr 2>/dev/null)"
done
