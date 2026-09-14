#!/bin/zsh
# Track F FIX-round runner. Runs a probe (.c staged through clang -O1, or a .ll
# taken as-is) through THREE binaries: the frozen session ORACLE, the PRE-FIX
# subject (147cb3d6, snapshotted before the fix build) and the POST-FIX subject.
# Prints the byte size of every module BEFORE measuring it and aborts on 0 —
# IMPL_F §7's erratum: a 0-byte .ll parses as an empty module and ACCEPTS.
set -u
LLVM=/usr/local/opt/llvm@19/bin
MAIN=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_f2phi
P=$1
D=$(dirname "$P"); B=$(basename "$P"); B=${B%.*}
if [[ "$P" == *.c ]]; then
  S1="$D/$B.stage1.ll"
  "$LLVM/clang" -I"$MAIN/include" -include CQ.h -O1 -g -emit-llvm -S "$P" -o "$S1" || { echo "STAGE1 FAIL"; exit 2; }
else
  S1="$P"
fi
SZ=$(stat -f%z "$S1")
echo "== $B  stage1=$S1  bytes=$SZ"
if [[ "$SZ" -eq 0 ]]; then echo "!! ZERO-BYTE MODULE - VACUOUS PROBE, ABORT"; exit 3; fi
for who in ORACLE PREFIX POSTFIX; do
  case $who in
    ORACLE)  OPT=$MAIN/build/ir-pass/cq-opt;            SO=$MAIN/build/ir-pass/libCQPass.so ;;
    PREFIX)  OPT=$SUBJ/build/prefix_147cb3d6/cq-opt;    SO=$SUBJ/build/prefix_147cb3d6/libCQPass.so ;;
    POSTFIX) OPT=$SUBJ/build/ir-pass/cq-opt;            SO=$SUBJ/build/ir-pass/libCQPass.so ;;
  esac
  [[ -x "$OPT" ]] || { echo "   $who  <binary absent>"; continue; }
  OUT="$D/$B.$who.s2.ll"; ERR="$D/$B.$who.err"
  "$OPT" -load-pass-plugin "$SO" -passes=cq-lowering -S "$S1" -o "$OUT" 2>"$ERR"
  rc=$?
  msg=$(grep -o 'cq [a-z ]*lowering: [^;]*' "$ERR" | head -1)
  osz=$(stat -f%z "$OUT" 2>/dev/null || echo 0)
  md5=$(md5 -q "$OUT" 2>/dev/null || echo -)
  echo "   $who exit=$rc  s2bytes=$osz  md5=$md5  msg=${msg:-<none>}"
done
