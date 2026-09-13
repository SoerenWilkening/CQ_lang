#!/bin/bash
# decline_stderr_delta_M.sh — landing 3's copy of landing 2's F-R1 closure, with the
# parallelism artefact landing 2 reported FIXED.
#
# WHY IT EXISTS (finding F-R1, MERGE_R1_1.md §0): the shared corpus recipe renders a
# decline as `D:` + the first 80 chars matched by `grep -oE 'cq [a-z0-9 ]+: [^"]+'`.
# A diagnostic that does NOT match that regex renders as an EMPTY `D:` on BOTH sides,
# so a DECLINE -> DECLINE string change inside that family is INVISIBLE to the sweep.
# This re-runs both binaries over every row either side declined and byte-compares the
# FULL stderr plus the exit code.
#
# THE FIX vs landing 2's copy: that one wrote the `### <rel>` header and the diff body
# as two separate appends under `-P6`, so two rows' output could interleave (landing 2
# had to re-run three rows SERIALLY before naming them). Here each row writes its own
# file in a temp dir and the files are concatenated in sorted order at the end, so the
# parallel output is already the evidence.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_mphi
IN=$1        # the corpus_*.txt to take the row list from
OUT=$2
D=$(mktemp -d)
export D
row() {
  rel=$1
  LLVM=/usr/local/opt/llvm@19/bin
  ORC=/Users/sorenwilkening/Desktop/CQ_lang
  SUBJ=/Users/sorenwilkening/Desktop/CQ_mphi
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
    { echo "### $rel"; diff "$T/o.err" "$T/s.err" | sed 's/^/    /'; } > "$D/$(echo "$rel" | tr / _)"
  fi
  rm -rf $T
}
export -f row
LIST=$(mktemp)
grep -v '^#' "$IN" | grep -v '^DONE$' | awk -F'|' '$2 ~ /^D:/ || $3 ~ /^D:/ {print $1}' > $LIST
echo "# decline-side full-stderr delta over $(wc -l < $LIST | tr -d ' ') rows | oracle=$(shasum -a 256 $ORC/build/ir-pass/cq-opt|cut -c1-16) merged=$(shasum -a 256 $SUBJ/build/ir-pass/cq-opt|cut -c1-16)" > $OUT
xargs -P 6 -I{} bash -c 'row "$@"' _ {} < $LIST
echo "# rows that DIFFER: $(ls -1 $D | wc -l | tr -d ' ')" >> $OUT
for g in $(ls -1 $D | sort); do cat "$D/$g" >> $OUT; done
echo DONE >> $OUT
rm -rf $D $LIST
