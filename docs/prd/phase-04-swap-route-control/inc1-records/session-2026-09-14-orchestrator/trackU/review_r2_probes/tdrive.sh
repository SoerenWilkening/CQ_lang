#!/bin/bash
# Rule-2 end-to-end: lower -> stage 2b -> LINK -> RUN, and byte-diff the TRACE
# of the undef spelling (SUBJECT) against the explicit-zero twin (ORACLE).
set -u
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang; SUBJ=/Users/sorenwilkening/Desktop/CQ_undef
D="$(cd "$(dirname "$0")" && pwd)"; cd "$D"; N=$1
go() { # $1 root  $2 src  $3 tag
  "$LLVM/clang" -I"$ORC/include" -include CQ.h -O1 -g -emit-llvm -S "$2" -o "$N.$3.s1.ll" 2>/dev/null || { echo "clang fail"; return 1; }
  "$1/build/ir-pass/cq-opt" -passes=cq-lowering -S "$N.$3.s1.ll" -o "$N.$3.s2.ll" 2>"$N.$3.err" || { echo "  $3: DECLINE $(head -c 120 $N.$3.err)"; return 1; }
  echo "  $3: 2b: $(python3 $ORC/tools/free_pairing_check.py "$N.$3.s2.ll" 2>&1 | tail -1)"
  "$LLVM/clang" "$N.$3.s2.ll" "$ORC/build/runtime/libcq_templates.a" "$ORC/build/runtime/libcq_runtime.a" -o "$N.$3.exe" 2>/dev/null || { echo "  $3: LINK FAIL"; return 1; }
  ./"$N.$3.exe" > "$N.$3.trace" 2>&1; echo "  $3: $(wc -l < "$N.$3.trace" | tr -d ' ') trace lines"
}
echo "### $N"
go $SUBJ "$N.c"      subj
go $ORC  "$N.zero.c" ozero
if [ -f "$N.subj.trace" ] && [ -f "$N.ozero.trace" ]; then
  if cmp -s "$N.subj.trace" "$N.ozero.trace"; then echo "  ==> TRACE BYTE-IDENTICAL to the explicit-zero twin"
  else echo "  ==> TRACE DIFFERS:"; diff "$N.ozero.trace" "$N.subj.trace" | head -20; fi
  echo "  --- stream ---"; sed 's/^/    /' "$N.subj.trace"
fi
