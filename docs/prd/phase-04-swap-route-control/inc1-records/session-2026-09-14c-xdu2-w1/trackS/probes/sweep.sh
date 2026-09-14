#!/bin/bash
# Track S ORACLE-vs-SUBJECT corpus sweep.
# ⚠ S3 defect closed: the shared corpus.sh renders a decline as a TRUNCATED TAG via a regex that
#   collapses the whole `cq_measure_<sfx>` family to an empty `D:`, so a decline->decline STRING
#   change is INVISIBLE. This sweep records, for a decline, the sha256 of the FULL stderr plus the
#   exit code, and compares those. Accepts are compared by md5 of the lowered IR produced from the
#   SAME stage-1 file by both binaries (md5s are only comparable WITHIN a row, never across sweeps).
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_s82e
OUT=$1
: > "$OUT"
run() { # $1 root  $2 stage1  $3 tmp tag
  "$1/build/ir-pass/cq-opt" -load-pass-plugin "$1/build/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$2" -o "$3.ll" 2>"$3.err"
  local e=$?
  if [ $e -eq 0 ]; then echo "A:$(md5 -q "$3.ll" | cut -c1-12)"
  else echo "D$e:$(shasum -a 256 "$3.err" | cut -c1-12):$(grep -oE 'cq [a-z0-9 -]+lowering: .*|cq taint escape: .*' "$3.err" | head -1 | cut -c1-90)"; fi
}
for f in "$SUBJ"/ir-pass/test/*.ll; do
  T=$(mktemp -d); rel="ir-pass/test/$(basename "$f")"
  echo "$rel|$(run "$ORC" "$f" "$T/o")|$(run "$SUBJ" "$f" "$T/s")" >> "$OUT"
  rm -rf "$T"
done
for f in "$SUBJ"/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/*.c; do
  T=$(mktemp -d); rel="trackS/probes/$(basename "$f")"
  if ! "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null; then
    echo "$rel|CLANGERR|CLANGERR" >> "$OUT"; rm -rf "$T"; continue; fi
  echo "$rel|$(run "$ORC" "$T/s1.ll" "$T/o")|$(run "$SUBJ" "$T/s1.ll" "$T/s")" >> "$OUT"
  rm -rf "$T"
done
echo DONE >> "$OUT"
