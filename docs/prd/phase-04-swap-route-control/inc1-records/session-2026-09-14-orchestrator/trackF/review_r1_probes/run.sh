#!/bin/zsh
# review_r1 runner: stage-1 a .c (or take a .ll), then run BOTH binaries.
# Prints the byte size of every generated .ll (SCOPE_F erratum: a 0-byte module ACCEPTS).
set -u
LLVM=/usr/local/opt/llvm@19/bin
MAIN=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_f2phi
P=$1                    # probe path (.c or .ll)
D=$(dirname "$P"); B=$(basename "$P"); B=${B%.*}
if [[ "$P" == *.c ]]; then
  S1="$D/$B.stage1.ll"
  "$LLVM/clang" -I"$MAIN/include" -include CQ.h -O1 -g -emit-llvm -S "$P" -o "$S1" || { echo "STAGE1 FAIL"; exit 2; }
else
  S1="$P"
fi
SZ=$(stat -f%z "$S1")
echo "== $B  stage1=$S1  bytes=$SZ"
if [[ "$SZ" -eq 0 ]]; then echo "!! ZERO-BYTE MODULE — VACUOUS PROBE, ABORT"; exit 3; fi
for who in ORACLE SUBJECT; do
  if [[ $who == ORACLE ]]; then BD=$MAIN/build; else BD=$SUBJ/build; fi
  OUT="$D/$B.$who.s2.ll"; ERR="$D/$B.$who.err"
  "$BD/ir-pass/cq-opt" -load-pass-plugin "$BD/ir-pass/libCQPass.so" -passes=cq-lowering -S "$S1" -o "$OUT" 2>"$ERR"
  rc=$?
  msg=$(grep -o 'cq [a-z ]*lowering: [^;]*' "$ERR" | head -1)
  osz=$(stat -f%z "$OUT" 2>/dev/null || echo 0)
  echo "   $who exit=$rc  s2bytes=$osz  msg=${msg:-<none>}"
done
