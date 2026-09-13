#!/bin/bash
# decline_stderr_delta.sh — the CLOSE of a blind spot in the shared corpus recipe.
# corpus.sh renders a decline as `D:` + the first 80 chars matched by
# `grep -oE 'cq [a-z0-9 ]+: [^"]+'`. A diagnostic that does NOT match that regex
# (e.g. `cq_measure_si32 operand not recognized …`, the 21mg family) renders as an
# EMPTY `D:` on BOTH sides, so a row whose diagnostic CHANGED looks unchanged.
# This re-runs both binaries over every row either side declined and byte-compares
# the FULL stderr, with the leading path normalised. A line is printed only when
# the two stderrs differ.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_rb9x
IN=$1        # the corpus_*.txt to take the row list from
OUT=$2
row() {
  rel=$1
  LLVM=/usr/local/opt/llvm@19/bin
  ORC=/Users/sorenwilkening/Desktop/CQ_lang
  SUBJ=/Users/sorenwilkening/Desktop/CQ_rb9x
  f=$SUBJ/$rel
  T=$(mktemp -d)
  if [[ "$f" == *.c ]]; then
    "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null || { rm -rf $T; return; }
  else cp "$f" "$T/s1.ll"; fi
  for tag in o s; do
    root=$ORC; [ $tag = s ] && root=$SUBJ
    "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
    echo "exit=$?" >> "$T/$tag.err"
  done
  if ! diff -q "$T/o.err" "$T/s.err" >/dev/null; then
    echo "### $rel"
    diff "$T/o.err" "$T/s.err" | sed 's/^/    /'
  fi
  rm -rf $T
}
export -f row
grep -v '^#' "$IN" | grep -v '^DONE$' | awk -F'|' '$2 ~ /^D:/ || $3 ~ /^D:/ {print $1}' > /tmp/.dsd.$$
echo "# decline-side full-stderr delta over $(wc -l < /tmp/.dsd.$$) rows | oracle=$(shasum -a 256 $ORC/build/ir-pass/cq-opt|cut -c1-16) merged=$(shasum -a 256 $SUBJ/build/ir-pass/cq-opt|cut -c1-16)" > $OUT
xargs -P 6 -I{} bash -c 'row "$@"' _ {} < /tmp/.dsd.$$ >> $OUT
echo DONE >> $OUT
rm -f /tmp/.dsd.$$
