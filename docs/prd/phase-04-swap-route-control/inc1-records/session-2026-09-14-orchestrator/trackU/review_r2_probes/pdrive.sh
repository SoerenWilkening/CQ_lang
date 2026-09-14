#!/bin/bash
# Hand-IR probe driver with a ZERO TWIN control.
#   <n>.ll      the undef spelling      -> ORACLE and SUBJECT
#   <n>.zero.ll the same module with every undef written as the concrete zero
#               -> ORACLE only.  The rule's claim is SUBJECT(<n>.ll) == ORACLE(<n>.zero.ll).
set -u
ORC=/Users/sorenwilkening/Desktop/CQ_lang; SUBJ=/Users/sorenwilkening/Desktop/CQ_undef
D="$(cd "$(dirname "$0")" && pwd)"; cd "$D"; N=$1
r() { local root=$1 f=$2 t=$3
  "$root/build/ir-pass/cq-opt" -passes=cq-lowering -S "$f" -o "$D/$N.$t.ll" 2>"$D/$N.$t.err"; echo $?; }
OE=$(r $ORC  "$N.ll" ou); SE=$(r $SUBJ "$N.ll" su); ZE=$(r $ORC "$N.zero.ll" oz)
echo "### $N   oracle(undef)=$OE   subject(undef)=$SE   oracle(zero-twin)=$ZE"
echo "  O_u: $(head -c 200 $N.ou.err | tr '\n' ' ')"
echo "  S_u: $(head -c 200 $N.su.err | tr '\n' ' ')"
echo "  O_z: $(head -c 200 $N.oz.err | tr '\n' ' ')"
if [ "$SE" = 0 ] && [ "$ZE" = 0 ]; then
  if diff <(grep -v 'ModuleID\|source_filename' $N.su.ll) <(grep -v 'ModuleID\|source_filename' $N.oz.ll) >/dev/null
  then echo "  ==> SUBJECT(undef) == ORACLE(zero twin)  [EQUIVALENT]"
  else echo "  ==> DIVERGES from the zero twin:"; diff <(grep -v 'ModuleID\|source_filename' $N.oz.ll) <(grep -v 'ModuleID\|source_filename' $N.su.ll) | head -30; fi
fi
if [ "$SE" = 0 ]; then echo "  --- SUBJECT emitted stream ---"; grep -oE '(call|tail call).*@(cqrt_|cq_template_)[A-Za-z0-9_]*\([^)]*\)' $N.su.ll | sed 's/^/    /'; fi
