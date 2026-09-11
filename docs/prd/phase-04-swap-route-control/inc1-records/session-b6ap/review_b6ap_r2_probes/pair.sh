#!/usr/bin/env bash
# pair.sh <dir> <fused> <handpeeled> — SUBJECT's lowering of <fused> vs ORACLE's of <handpeeled>.
ORACLE=/Users/sorenwilkening/Desktop/CQ_lang; SUBJ=/Users/sorenwilkening/Desktop/CQ_b6ap
LLVM=/usr/local/opt/llvm@19/bin; D=$1; A=$2; B=$3; T=$(mktemp -d)
run(){ local root=$1 nm=$2 out=$3 ll="$T/$nm.ll"
  if [ -e "$D/$nm.c" ]; then "$LLVM/clang" -I$ORACLE/include -include CQ.h -O1 -emit-llvm -S "$D/$nm.c" -o "$ll" 2>/dev/null; else cp "$D/$nm.s1.ll" "$ll"; fi
  "$root/build/ir-pass/cq-opt" -passes=cq-lowering -S "$ll" -o "$T/$nm.lo.ll" 2>"$T/$nm.err" || { echo "DECLINE: $(grep -oE 'error: .*' $T/$nm.err|head -1)" > "$out"; return; }
  "$LLVM/clang" "$T/$nm.lo.ll" "$ORACLE/build/runtime/libcq_templates.a" "$ORACLE/build/runtime/libcq_runtime.a" -o "$T/$nm.exe" 2>/dev/null && "$T/$nm.exe" > "$out" 2>&1 || echo LINKFAIL > "$out"; }
run "$SUBJ" "$A" "$T/a.tr"; run "$ORACLE" "$B" "$T/b.tr"
if diff -q "$T/a.tr" "$T/b.tr" >/dev/null; then echo "$A(subj,fused) == $B(oracle,handpeel): BYTE-IDENTICAL ($(wc -l < $T/a.tr | tr -d ' ') lines)";
else echo "$A vs $B : DIFF"; diff "$T/a.tr" "$T/b.tr" | head -20; fi
rm -rf "$T"
