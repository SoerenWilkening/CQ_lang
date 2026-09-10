#!/bin/bash
# corpusdiff.sh — run every ir-pass/test/*.ll on BOTH binaries and classify.
# Prints RCDIFF / DIAGDIFF / OUTDIFF lines and a summary.
set -u
ROOT=/Users/sorenwilkening/Desktop/CQ_lang
PRE=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/05a94f34-2e8d-4c24-b48c-aaecd3961c97/scratchpad/impl_b1/pre
OUT=$(dirname "$0")/corpus; mkdir -p "$OUT"
one() {
  f="$1"; b=$(basename "$f" .ll); T=$(mktemp -d)
  "$PRE/cq-opt" -load-pass-plugin "$PRE/libCQPass.so" -passes=cq-lowering -S "$f" -o "$T/pre.ll" 2>"$T/pre.err"; rp=$?
  "$ROOT/build/ir-pass/cq-opt" -load-pass-plugin "$ROOT/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$f" -o "$T/post.ll" 2>"$T/post.err"; rq=$?
  s=""
  [ "$rp" != "$rq" ] && s="$s RCDIFF($rp->$rq)"
  cmp -s "$T/pre.err" "$T/post.err" || s="$s DIAGDIFF"
  if [ $rp -eq 0 ] && [ $rq -eq 0 ]; then tail -n +4 "$T/pre.ll" > "$T/p"; tail -n +4 "$T/post.ll" > "$T/q"; cmp -s "$T/p" "$T/q" || s="$s OUTDIFF"; fi
  [ -n "$s" ] && echo "$b$s"
  rm -rf "$T"
}
export -f one
export PRE ROOT
ls "$ROOT"/ir-pass/test/*.ll | xargs -P 6 -I{} bash -c 'one "$@"' _ {} > "$OUT/movers.txt" 2>/dev/null
echo "SCANNED=$(ls $ROOT/ir-pass/test/*.ll | wc -l | tr -d ' ') MOVERS=$(wc -l < $OUT/movers.txt | tr -d ' ')"
sort "$OUT/movers.txt"
