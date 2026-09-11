#!/usr/bin/env bash
# twin.sh <name> — compares SUBJECT's lowering of the FUSED module against the
# ORACLE's lowering of the HAND-PEELED twin (<name>t_handpeel.s1.ll).
ORACLE=/Users/sorenwilkening/Desktop/CQ_lang; SUBJ=/Users/sorenwilkening/Desktop/CQ_b6ap
LLVM=/usr/local/opt/llvm@19/bin; N=$1; cd "$(dirname "$0")"
"$SUBJ/build/ir-pass/cq-opt" -passes=cq-lowering -S "$N.s1.ll" -o "$N.s.ll" 2> "$N.s.err"; RS=$?
"$ORACLE/build/ir-pass/cq-opt" -passes=cq-lowering -S "${N}t_handpeel.s1.ll" -o "${N}t.o.ll" 2> "${N}t.o.err"; RO=$?
echo "SUBJECT(fused) exit=$RS   ORACLE(hand-peeled twin) exit=$RO"
[ $RS -ne 0 ] && sed -n '1,3p' "$N.s.err"
[ $RO -ne 0 ] && sed -n '1,3p' "${N}t.o.err"
if [ $RS -eq 0 ] && [ $RO -eq 0 ]; then
  for T in "$N.s" "${N}t.o"; do
    "$LLVM/clang" "$T.ll" "$ORACLE/build/runtime/libcq_templates.a" "$ORACLE/build/runtime/libcq_runtime.a" -o "$T.exe" 2>/dev/null && ./"$T.exe" > "$T.trace" 2>&1
  done
  if diff -q "$N.s.trace" "${N}t.o.trace" >/dev/null 2>&1; then echo "TRACE: BYTE-IDENTICAL ($(wc -l < "$N.s.trace") lines)";
  else echo "TRACE DIFF ($(wc -l < "$N.s.trace") vs $(wc -l < "${N}t.o.trace")):"; diff "$N.s.trace" "${N}t.o.trace" | head -30; fi
fi
