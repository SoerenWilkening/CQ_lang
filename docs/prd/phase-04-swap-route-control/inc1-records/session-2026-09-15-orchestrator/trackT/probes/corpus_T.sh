#!/bin/bash
# corpus_T.sh — Track T ORACLE-vs-SUBJECT sweep.
# Row: <rel>|<oracle verdict>|<subject verdict>
#   A:<md5-8 of the lowered IR>       accept (md5s comparable WITHIN a row only)
#   D:<sha1-8 of the FULL stderr>     decline — a HASH, not the tag regex, because
#                                     the shared corpus.sh regex renders the whole
#                                     `cq_measure_<sfx>` family as an empty `D:`
#                                     and hides a D->D string change (PROTOCOL S3).
#   plus the first `cq ...:` string, for readability.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_T
OUT=$1
: > "$OUT"
R=$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records
LIST=$(mktemp)
ls $SUBJ/ir-pass/test/*.ll | sort >> "$LIST"
# ⚠ THE e2e SLICE SOURCES ARE IN THE CORPUS ON PURPOSE. The PROTOCOL reserves the
# `^e2e-` ctest layer for the merge-and-gate agent, but a change to the LOWERING
# that moves a shipped e2e stream must not first be seen at that gate. Lowering
# every `tests/e2e/*.c` through both binaries and comparing the md5 of the lowered
# IR is the same information minus the link and the golden byte-diff, and it is a
# corpus sweep, which IS this track's gate.
ls $SUBJ/tests/e2e/*.c 2>/dev/null | sort >> "$LIST"
find "$R" \( -path '*/probes/*' -o -path '*_probes/*' -o -path '*/c1_reproducers/*' \) \
     \( -name '*.c' -o -name '*.ll' \) 2>/dev/null | grep -v '\.s1\.ll$' | grep -v '\.sora\.' | grep -v '\.ssub\.' | grep -v '\.ora\.' | grep -v '\.sub\.' | sort >> "$LIST"
find "$R" -maxdepth 3 -name '*.c' 2>/dev/null | sort >> "$LIST"
sort -u "$LIST" -o "$LIST"
while read -r f; do
  [ -f "$f" ] || continue
  T=$(mktemp -d); rel=${f#$SUBJ/}
  if [[ "$f" == *.c ]]; then
    "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
      || { echo "$rel|CLANGERR|CLANGERR" >> "$OUT"; rm -rf "$T"; continue; }
  else cp "$f" "$T/s1.ll"; fi
  [ -s "$T/s1.ll" ] || { echo "$rel|EMPTY|EMPTY" >> "$OUT"; rm -rf "$T"; continue; }
  v(){ local root=$1 tag=$2
    "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" \
        -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
    if [ $? -eq 0 ]; then echo "A:$(md5 -q "$T/$tag.ll" | cut -c1-8)"
    else echo "D:$(shasum -a 1 < "$T/$tag.err" | cut -c1-8):$(grep -oE 'cq [a-z0-9- ]+: [^\"]*' "$T/$tag.err" | head -1 | cut -c1-70)"; fi; }
  echo "$rel|$(v $ORC o)|$(v $SUBJ s)" >> "$OUT"
  rm -rf "$T"
done < "$LIST"
rm -f "$LIST"
echo DONE >> "$OUT"
