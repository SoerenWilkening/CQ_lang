#!/bin/bash
W=/Users/sorenwilkening/Desktop/Projects/cq-wt-11qv
O=/Users/sorenwilkening/Desktop/Projects/CQ_lang/build
cd "$W" || exit 1
T=$(mktemp -d); AD=0; DA=0; DD=0; AA=0; TOT=0
for f in ir-pass/test/*.ll; do
  TOT=$((TOT+1))
  "$O/ir-pass/cq-opt" -load-pass-plugin "$O/ir-pass/libCQPass.so" -passes=cq-lowering -S "$f" -o "$T/a.ll" 2>"$T/a.err"; RA=$?
  build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S "$f" -o "$T/b.ll" 2>"$T/b.err"; RB=$?
  if [ $RA -eq 0 ] && [ $RB -ne 0 ]; then AD=$((AD+1)); echo "A->D $(basename $f) :: $(head -1 "$T/b.err")"
  elif [ $RA -ne 0 ] && [ $RB -eq 0 ]; then DA=$((DA+1)); echo "D->A $(basename $f) :: was $(head -1 "$T/a.err" | sed 's/.*: cq /cq /')"
  elif [ $RA -ne 0 ] && [ $RB -ne 0 ]; then
    if ! diff -q "$T/a.err" "$T/b.err" >/dev/null; then DD=$((DD+1)); echo "D->D(string) $(basename $f)"; echo "   was: $(head -1 "$T/a.err"|sed 's/.*: cq /cq /')"; echo "   now: $(head -1 "$T/b.err"|sed 's/.*: cq /cq /')"; fi
  else
    if ! diff -q <(grep -v '^; ModuleID' "$T/a.ll") <(grep -v '^; ModuleID' "$T/b.ll") >/dev/null; then AA=$((AA+1)); echo "A->A(stream) $(basename $f)"; fi
  fi
done
echo "CORPUS A/B: $TOT fixtures | A->D $AD | D->A $DA | D->D(string) $DD | A->A(stream moved) $AA"
