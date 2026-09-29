#!/bin/bash
# twc.sh BIN TAG base... : C vs T on BIN (composed), trace compare, 2b, warnings.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d
L=/usr/local/opt/llvm@19/bin
RT="$W/build/runtime/libcq_runtime.a"; TPL="$W/build/runtime/libcq_templates.a"
B=$1; TAG=$2; shift 2
cd "$S/r1B_cepm/p" || exit 1
for b in "$@"; do
  c="${b}C"; t="${b}T"
  for x in $c $t; do $B -passes=cq-lowering -S $x.s1.ll -o $x.$TAG.ll 2> $x.$TAG.err; echo $? > $x.$TAG.rc; done
  rc1=$(cat $c.$TAG.rc); rc2=$(cat $t.$TAG.rc)
  e1=$(grep -m1 'error:' $c.$TAG.err | sed 's/^.*error: //;s/<unknown>:0:0: in function [^:]*: //'); e2=$(grep -m1 'error:' $t.$TAG.err | sed 's/^.*error: //;s/<unknown>:0:0: in function [^:]*: //')
  w1=$(grep -c 'warning:' $c.$TAG.err); w2=$(grep -c 'warning:' $t.$TAG.err)
  if [ $rc1 != 0 ] && [ $rc2 != 0 ]; then [ "$e1" = "$e2" ] && v=DECL-SAME || v=DECL-DIFF
  elif [ $rc1 = 0 ] && [ $rc2 = 0 ]; then
    v=ACC-SAME
    for x in $c $t; do python3 $W/tools/free_pairing_check.py $x.$TAG.ll > $x.$TAG.2b 2>&1 || v="ACC-2BFAIL($x)"; $L/clang $x.$TAG.ll $TPL $RT -o $x.$TAG.exe 2>/dev/null || v="LINKFAIL($x)"; done
    if [[ $v == ACC-SAME ]]; then for args in "5 7" "2 9" "9 1"; do ./$c.$TAG.exe $args > $c.$TAG.tr.${args// /_} 2>&1; ./$t.$TAG.exe $args > $t.$TAG.tr.${args// /_} 2>&1; cmp -s $c.$TAG.tr.${args// /_} $t.$TAG.tr.${args// /_} || v=ACC-DIFF; done; fi
  else v="VERDICT-DIFF(C=$rc1,T=$rc2)"; fi
  echo "$b | $TAG $v | C: ${e1:-accept} (warn $w1) | T: ${e2:-accept} (warn $w2)"
done
