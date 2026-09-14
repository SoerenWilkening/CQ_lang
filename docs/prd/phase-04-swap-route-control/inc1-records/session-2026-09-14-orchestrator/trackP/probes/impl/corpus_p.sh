#!/bin/bash
# corpus_p.sh — Track P ORACLE-vs-SUBJECT sweep.
#
# A row is: <rel path>|<oracle verdict>|<subject verdict>, where a verdict is
#   A:<md5 of the lowered IR, 8 chars>     on exit 0
#   D:<sha1 of the FULL stderr, 8 chars>:<first 70 chars of the message>
#
# ⚠ THE FULL-STDERR HASH IS DELIBERATE (PROTOCOL S3). The shared corpus.sh tag
# regex renders the whole `cq_measure_<sfx>` decline family as an EMPTY `D:`, so a
# decline->decline STRING change inside it is INVISIBLE. Hashing the whole stderr
# byte stream closes that hole: any change to any decline's text moves the hash.
# ⚠ Lowered-IR md5s are NOT comparable ACROSS sweeps (the temp `ModuleID`
# changes); they are only ever compared WITHIN a row, which is what this does.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=${SUBJ:-/Users/sorenwilkening/Desktop/CQ_phiphase}
OUT=$1
: > "$OUT"
R=$ORC/docs/prd/phase-04-swap-route-control/inc1-records
SES=$R/session-2026-09-14-orchestrator
DIRS=()
for d in "$SES"/track*/probes "$SES"/probes \
         "$R"/session-9pum/probes "$R"/session-9pum/review_a1_r1_probes "$R"/session-9pum/review_a1_r2_probes \
         "$R"/session-b6ap/probes "$R"/session-b6ap/review_b6ap_r1_probes "$R"/session-b6ap/review_b6ap_r2_probes \
         "$R"/session-f2-i1/probes "$R"/session-f2-i1/review_f2_r1_probes \
         "$R"/session-l4x4/probes "$R"/session-l4x4/review_l4x4b_r1_probes "$R"/session-l4x4/fix_l4x4b_r1_probes \
         "$R"/session-boi6/probes "$R"/session-r903/probes "$R"/session-r9e5/probes \
         "$R"/session-2026-09-11-orchestrator/probes "$R"/session-2026-09-11-orchestrator/review_integration_probes \
         "$R"/session-2026-09-13-orchestrator/track*/probes \
         "$R"/session-2026-09-13-orchestrator/track*/*_probes; do
  [ -d "$d" ] && DIRS+=("$d")
done
# The SUBJECT's own new probes live only in the worktree.
for d in "$SUBJ"/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/track*/probes; do
  [ -d "$d" ] && DIRS+=("$d")
done
FILES=$(mktemp)
{ find "$ORC/ir-pass/test" -name '*.ll' | sort
  for d in "${DIRS[@]}"; do find "$d" \( -name '*.c' -o -name '*.ll' \) ! -name '*.s1.ll' ! -name '*.s2.ll' ! -name '*.out.ll' | sort; done
} > "$FILES"
n=0
while read -r f; do
  T=$(mktemp -d); rel=${f#$R/}; rel=${rel#$ORC/}; rel=${rel#$SUBJ/}
  if [[ "$f" == *.c ]]; then
    base=$(basename "$f"); dir=$(dirname "$f")
    if [[ "$base" == *_lib.c || "$base" == lib*.c ]]; then rm -rf "$T"; continue; fi
    if [[ "$base" == *_caller.c ]]; then
      stem=${base%_caller.c}; libf="$dir/${stem}_lib.c"; [ -f "$libf" ] || libf=$(ls "$dir"/lib*.c 2>/dev/null | head -1)
      "$LLVM/clang" -I"$ORC/include" -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null || { echo "$rel|CLANGERR|CLANGERR" >> "$OUT"; rm -rf "$T"; continue; }
      if [ -n "$libf" ] && [ -f "$libf" ]; then
        "$LLVM/clang" -I"$ORC/include" -O1 -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null && "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp "$T/a.ll" "$T/s1.ll"
      else cp "$T/a.ll" "$T/s1.ll"; fi
    else
      "$LLVM/clang" -I"$ORC/include" -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null || { echo "$rel|CLANGERR|CLANGERR" >> "$OUT"; rm -rf "$T"; continue; }
    fi
  else cp "$f" "$T/s1.ll"; fi
  v() { local root=$1 tag=$2
    "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" \
        -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
    if [ $? -eq 0 ]; then echo "A:$(md5 -q "$T/$tag.ll" | cut -c1-8)"
    else echo "D:$(shasum "$T/$tag.err" | cut -c1-8):$(grep -oE 'cq [a-z0-9 -]+: [^\"]+' "$T/$tag.err" | head -1 | sed 's/ under quantum control//' | cut -c1-70)"; fi; }
  echo "$rel|$(v "$ORC" o)|$(v "$SUBJ" s)" >> "$OUT"
  rm -rf "$T"; n=$((n+1))
done < "$FILES"
echo "DONE $n rows" >> "$OUT"
rm -f "$FILES"
