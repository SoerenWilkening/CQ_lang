#!/bin/bash
W=/Users/sorenwilkening/Desktop/Projects/cq-wt-11qv
cd "$W" || exit 1
TAG="$1"; MOV=0; CRASH=0; TOT=0; T=$(mktemp -d)
for f in ir-pass/test/*.ll; do
  TOT=$((TOT+1))
  build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S "$f" -o /dev/null 2>"$T/a.err"; RA=$?
  CQ_ZUJR_PEEL="$TAG" build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S "$f" -o /dev/null 2>"$T/b.raw"; RB=$?
  grep -v '^CQ_ZUJR_PEEL:' "$T/b.raw" > "$T/b.err"
  if [ "$RA" != "$RB" ] || ! diff -q "$T/a.err" "$T/b.err" >/dev/null; then
    MOV=$((MOV+1)); echo "MOVER $(basename $f)  rc:$RA->$RB"
    echo "  base: $(head -1 "$T/a.err")"; echo "  peel: $(head -1 "$T/b.err")"
  fi
  [ "$RB" = "134" ] && { CRASH=$((CRASH+1)); echo "CRASH134 $(basename $f)"; }
done
echo "PEEL[$TAG]: $TOT fixtures, $MOV movers, $CRASH crashes"
