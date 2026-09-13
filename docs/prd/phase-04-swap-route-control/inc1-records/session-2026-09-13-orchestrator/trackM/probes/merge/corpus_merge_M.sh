#!/bin/bash
# corpus_merge_M.sh (Track M, landing 3 merge-and-gate) — ORACLE-vs-MERGED sweep.
# Same row format and same per-file recipe as the 2026-09-11
# review_integration_probes/corpus.sh, the implementer's probes/impl/corpus_m.sh and
# landing 2's trackR/probes/merge/corpus_merge.sh:
#     <rel>|<oracle verdict>|<merged verdict>   verdict = A:<md5-8 of lowered IR> | D:<diagnostic>
# Both binaries are run on the SAME stage-1 file. Corpora = MERGE_BRIEF_TEMPLATE.md step 5
# PLUS MERGE_BRIEF_M.md item C (trackM/probes/impl, trackM/review_M_r{1,2}_probes,
# trackR/*probes*, trackC/*probes*, trackL/probes) — the `find` over each named dir is
# RECURSIVE, so probes/impl, probes/merge, probes/r2 are all included.
# ⚠ md5s are NOT comparable across sweeps (the temp ModuleID changes): compare within a row.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_mphi
S=$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records
SES=$S/session-2026-09-13-orchestrator
OUT=$1
LIST=$(mktemp)
ls $SUBJ/ir-pass/test/*.ll | sort >> $LIST
DIRS="$SES/probes"
for d in $SES/track*/*probes* $SES/track*/probes; do [ -d "$d" ] && DIRS="$DIRS $d"; done
for d in $S/session-9pum/probes $S/session-9pum/review_a1_r1_probes $S/session-9pum/review_a1_r2_probes \
         $S/session-b6ap/probes $S/session-b6ap/review_b6ap_r1_probes $S/session-b6ap/review_b6ap_r2_probes \
         $S/session-f2-i1/probes $S/session-f2-i1/review_f2_r1_probes \
         $S/session-l4x4/probes $S/session-l4x4/review_l4x4b_r1_probes $S/session-l4x4/fix_l4x4b_r1_probes \
         $S/session-boi6/probes $S/session-boi6/review_*_probes \
         $S/session-r903/probes $S/session-r903/review_*_probes \
         $S/session-2026-09-11-orchestrator/probes $S/session-2026-09-11-orchestrator/review_*_probes; do
  [ -d "$d" ] && DIRS="$DIRS $d"
done
for d in $DIRS; do find "$d" \( -name '*.c' -o -name '*.ll' \) ; done | sort -u >> $LIST
sort -u $LIST -o $LIST
N=$(wc -l < $LIST)
row() {
  f=$1
  LLVM=/usr/local/opt/llvm@19/bin
  ORC=/Users/sorenwilkening/Desktop/CQ_lang
  SUBJ=/Users/sorenwilkening/Desktop/CQ_mphi
  T=$(mktemp -d); rel=${f#$SUBJ/}
  if [[ "$f" == *.c ]]; then
    base=$(basename "$f"); dir=$(dirname "$f")
    if [[ "$base" == *_caller.c ]]; then
      stem=${base%_caller.c}
      libf="$dir/${stem}_lib.c"; [ -f "$libf" ] || libf=$(ls "$dir"/lib*.c 2>/dev/null | head -1)
      "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null || { echo "$rel|CLANGERR|CLANGERR"; rm -rf $T; return; }
      if [ -n "$libf" ] && [ -f "$libf" ]; then
        "$LLVM/clang" -I$SUBJ/include -O1 -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null && "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp "$T/a.ll" "$T/s1.ll"
      else cp "$T/a.ll" "$T/s1.ll"; fi
    elif [[ "$base" == *_lib.c || "$base" == lib*.c ]]; then rm -rf $T; return
    else
      "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null || { echo "$rel|CLANGERR|CLANGERR"; rm -rf $T; return; }
    fi
  else cp "$f" "$T/s1.ll"; fi
  v(){ local root=$1 tag=$2
    "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
    if [ $? -eq 0 ]; then echo "A:$(md5 -q "$T/$tag.ll"|cut -c1-8)"; else echo "D:$(grep -oE 'cq [a-z0-9 ]+: [^\"]+' "$T/$tag.err"|head -1|sed 's/ under quantum control//'|cut -c1-80)"; fi; }
  echo "$rel|$(v $ORC o)|$(v $SUBJ s)"
  rm -rf $T
}
export -f row
BODY=$(mktemp)
xargs -P 6 -I{} bash -c 'row "$@"' _ {} < $LIST > $BODY
{ echo "# corpus: $N files | oracle=$(shasum -a 256 $ORC/build/ir-pass/cq-opt|cut -c1-16) merged=$(shasum -a 256 $SUBJ/build/ir-pass/cq-opt|cut -c1-16)"
  sort $BODY
  echo DONE; } > $OUT
rm -f $BODY $LIST
