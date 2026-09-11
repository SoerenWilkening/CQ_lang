#!/usr/bin/env bash
ORACLE=/Users/sorenwilkening/Desktop/CQ_lang; SUBJ=/Users/sorenwilkening/Desktop/CQ_b6ap; LLVM=/usr/local/opt/llvm@19/bin
N=$1
"$SUBJ/build/ir-pass/cq-opt" -passes=cq-lowering -S "$N.s1.ll" -o "$N.s.ll" 2>"$N.s.err"; RS=$?
"$ORACLE/build/ir-pass/cq-opt" -passes=cq-lowering -S "${N}t_handpeel.s1.ll" -o "${N}t.o.ll" 2>"${N}t.o.err"; RO=$?
if [ $RS -ne 0 ] || [ $RO -ne 0 ]; then
  echo "$N | subj=$RS $(grep -oE 'error: .*' $N.s.err|head -1|sed 's/.*cq /cq /') | twin-on-oracle=$RO $(grep -oE 'error: .*' ${N}t.o.err|head -1|sed 's/.*cq /cq /')"; exit; fi
for T in "$N.s" "${N}t.o"; do "$LLVM/clang" "$T.ll" "$ORACLE/build/runtime/libcq_templates.a" "$ORACLE/build/runtime/libcq_runtime.a" -o "$T.exe" 2>/dev/null && ./"$T.exe" > "$T.trace" 2>&1 || echo LINKFAIL > "$T.trace"; done
if diff -q "$N.s.trace" "${N}t.o.trace" >/dev/null; then echo "$N | BOTH ACCEPT | TRACE BYTE-IDENTICAL ($(wc -l < $N.s.trace|tr -d ' ') lines)";
else echo "$N | BOTH ACCEPT | TRACE DIFF"; diff "$N.s.trace" "${N}t.o.trace" | head -14; fi
