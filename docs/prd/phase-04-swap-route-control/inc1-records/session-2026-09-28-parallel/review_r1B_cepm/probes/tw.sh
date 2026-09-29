#!/bin/bash
# tw.sh base... : subject vs twin (C vs T) + oracle verdict on C and T; prints warnings.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d
L=/usr/local/opt/llvm@19/bin
RT="$W/build/runtime/libcq_runtime.a"; TPL="$W/build/runtime/libcq_templates.a"
SUBJ=$W/build/ir-pass/cq-opt; ORA=$S/frozen/cq-opt.main_9a230646
cd "$S/r1B_cepm/p" || exit 1
for b in "$@"; do
  c="${b}C"; t="${b}T"
  for x in $c $t; do
    $SUBJ -passes=cq-lowering -S $x.s1.ll -o $x.s2.ll 2> $x.err; echo $? > $x.rc
    $ORA -passes=cq-lowering -S $x.s1.ll -o $x.o2.ll 2> $x.oerr; echo $? > $x.orc
  done
  rc1=$(cat $c.rc); rc2=$(cat $t.rc)
  e1=$(grep -m1 'error:' $c.err | sed 's/^.*error: //;s/<unknown>:0:0: //'); e2=$(grep -m1 'error:' $t.err | sed 's/^.*error: //;s/<unknown>:0:0: //')
  oe1=$(grep -m1 'error:' $c.oerr | sed 's/^.*error: //;s/<unknown>:0:0: //'); oe2=$(grep -m1 'error:' $t.oerr | sed 's/^.*error: //;s/<unknown>:0:0: //')
  w1=$(grep -c 'warning:' $c.err); w2=$(grep -c 'warning:' $t.err)
  if [ $rc1 != 0 ] && [ $rc2 != 0 ]; then [ "$e1" = "$e2" ] && v=DECL-SAME || v=DECL-DIFF
  elif [ $rc1 = 0 ] && [ $rc2 = 0 ]; then
    v=ACC-SAME
    for x in $c $t; do python3 $W/tools/free_pairing_check.py $x.s2.ll > $x.2b 2>&1 || v="ACC-2BFAIL($x)"; $L/clang $x.s2.ll $TPL $RT -o $x.exe 2>/dev/null || v="LINKFAIL($x)"; done
    if [[ $v == ACC-SAME ]]; then for args in "5 7" "2 9" "9 1"; do ./$c.exe $args > $c.tr.${args// /_} 2>&1; ./$t.exe $args > $t.tr.${args// /_} 2>&1; cmp -s $c.tr.${args// /_} $t.tr.${args// /_} || v=ACC-DIFF; done; fi
  else v="VERDICT-DIFF(C=$rc1,T=$rc2)"; fi
  echo "$b | SUBJ $v | C: ${e1:-accept} (warn $w1) | T: ${e2:-accept} (warn $w2) | ORA C: $(cat $c.orc) ${oe1:-accept} | ORA T: $(cat $t.orc) ${oe2:-accept}"
done
