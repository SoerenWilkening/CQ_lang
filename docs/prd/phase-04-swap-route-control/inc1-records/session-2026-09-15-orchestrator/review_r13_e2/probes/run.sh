#!/bin/bash
# usage: run.sh <binary-tag: oracle|subject> <file.c|file.ll>
LLVM=/usr/local/opt/llvm@19/bin
ORACLE=/Users/sorenwilkening/Desktop/CQ_lang/build
SUBJECT=/Users/sorenwilkening/Desktop/CQ_E2/build
case "$1" in
  oracle) B=$ORACLE;; subject) B=$SUBJECT;;
  *) echo "bad tag"; exit 9;;
esac
F="$2"; BN=$(basename "$F"); BN="${BN%.*}"
D=$(mktemp -d)
if [[ "$F" == *.c ]]; then
  "$LLVM/clang" -I/Users/sorenwilkening/Desktop/CQ_lang/include -include CQ.h -O1 -emit-llvm -S "$F" -o "$D/s1.ll" 2>"$D/cc.err" || { echo "CLANGERR"; cat "$D/cc.err"; exit 8; }
else
  cp -f "$F" "$D/s1.ll"
fi
# non-empty check (CLAUDE.md: a 0-byte .ll ACCEPTS through the passthrough early-out)
SZ=$(wc -c < "$D/s1.ll"); NCQ=$(grep -c '@cq_theta_\|@cq_measure_\|@cq_phi' "$D/s1.ll" || true)
"$B/ir-pass/cq-opt" -load-pass-plugin "$B/ir-pass/libCQPass.so" -passes=cq-lowering -S "$D/s1.ll" -o "$D/s2.ll" 2>"$D/s2.err"
RC=$?
echo "== $1 $BN : exit=$RC  stage1bytes=$SZ  cqcalls=$NCQ"
if [ $RC -ne 0 ]; then echo "STDERR: $(head -c 400 "$D/s2.err")"; else
  echo "STDERR-BYTES: $(wc -c < "$D/s2.err")"
fi
echo "$D"
