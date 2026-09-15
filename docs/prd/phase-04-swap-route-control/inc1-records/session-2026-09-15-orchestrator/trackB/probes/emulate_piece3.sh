#!/bin/sh
# Emulate PIECE 3 ALONE (the bank store exempted from declineTaintEscapes) by
# deleting the one surviving bank store and its storage-extension cast from the
# promoter's own output, then running the frozen ORACLE on the result.
# ⚠ THIS IS NOT THE SECOND HALF.  With no TAINT RULE the bank loads stay
# classical, so `cq_measure` takes MeasureLowering's classical split and emits
# NOTHING.  That is the point: the emitted trace is the SILENT MISCOMPILE the
# brief names, reproduced.  Used here only to (a) exhibit it and (b) take the
# D1/R2 twin comparison on the gate stream, which the cast/store deletion does
# not touch.
set -u
LLVM=/usr/local/opt/llvm@19/bin; BUILD=${BUILD:-build}; W=${W:-/tmp/cqtrackB}; mkdir -p "$W"
P="$1"; B=$(basename "$P" .c)
"$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S "$P" -o "$W/$B.s1.ll" || exit 9
CQ_RAILBANK_DBG=1 "$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" \
    -passes=cq-lowering -S "$W/$B.s1.ll" -o /dev/null 2> "$W/$B.rb.txt"
awk '/^=== CQ_RAILBANK_DBG: module after/{f=1;next} f' "$W/$B.rb.txt" \
  | grep -v '^error: \|^\^$' > "$W/$B.promoted.ll"
python3 - "$W/$B.promoted.ll" "$W/$B.emu.ll" <<'PY'
import re,sys
s=open(sys.argv[1]).read()
m=re.search(r"\n  store [^\n]*, ptr %cq\.bank\.addr[^\n]*\n", s)
val=re.match(r"\n  store \S+ (%\S+),", m.group(0)).group(1)
s=s.replace(m.group(0),"\n")
c=re.search(r"\n  %s = (zext|trunc)[^\n]*\n"%re.escape(val), s)
if c: s=s.replace(c.group(0),"\n")
open(sys.argv[2],"w").write(s)
PY
"$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering \
    -S "$W/$B.emu.ll" -o "$W/$B.emu.s2.ll" || { echo "$B: emu DECLINE"; exit 0; }
"$LLVM/clang" "$W/$B.emu.s2.ll" "$BUILD/runtime/libcq_templates.a" "$BUILD/runtime/libcq_runtime.a" \
    -o "$W/$B.emu.exe" 2>/dev/null && "$W/$B.emu.exe" > "$W/$B.emu.trace" 2>&1
echo "$B: emu ACCEPT, $(wc -l < "$W/$B.emu.trace" | tr -d ' ') trace lines"
