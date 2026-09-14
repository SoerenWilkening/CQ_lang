#!/bin/bash
# The PROBE-CORPORA half of the Track P sweep, run separately because it is the
# half `ctest -R ir-pass-lit` does NOT already cover far more strongly (every
# `ir-pass/test/*.ll` has its own RUN line and CHECKs; a probe has neither).
# Same row format and the same full-stderr hash as corpus_p.sh.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=${SUBJ:-/Users/sorenwilkening/Desktop/CQ_phiphase}
OUT=$1
: > "$OUT"
R=$ORC/docs/prd/phase-04-swap-route-control/inc1-records
DIRS=()
for d in "$R"/session-2026-09-14-orchestrator/track*/probes "$R"/session-2026-09-14-orchestrator/probes \
         "$R"/session-9pum/probes "$R"/session-9pum/review_a1_r1_probes "$R"/session-9pum/review_a1_r2_probes \
         "$R"/session-b6ap/probes "$R"/session-b6ap/review_b6ap_r1_probes "$R"/session-b6ap/review_b6ap_r2_probes \
         "$R"/session-f2-i1/probes "$R"/session-f2-i1/review_f2_r1_probes \
         "$R"/session-l4x4/probes "$R"/session-l4x4/review_l4x4b_r1_probes "$R"/session-l4x4/fix_l4x4b_r1_probes \
         "$R"/session-boi6/probes "$R"/session-r903/probes "$R"/session-r9e5/probes \
         "$R"/session-2026-09-11-orchestrator/probes "$R"/session-2026-09-11-orchestrator/review_integration_probes \
         "$R"/session-2026-09-13-orchestrator/track*/probes "$R"/session-2026-09-13-orchestrator/track*/*_probes \
         "$SUBJ"/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/track*/probes; do
  [ -d "$d" ] && DIRS+=("$d")
done
FILES=$(mktemp)
for d in "${DIRS[@]}"; do find "$d" \( -name '*.c' -o -name '*.ll' \) ! -name '*.s1.ll' ! -name '*.s2.ll' ! -name '*.out.ll' | sort; done > "$FILES"
n=0
while read -r f; do
  T=$(mktemp -d); rel=${f#$R/}; rel=${rel#$SUBJ/}
  if [[ "$f" == *.c ]]; then
    base=$(basename "$f"); dir=$(dirname "$f")
    if [[ "$base" == *_lib.c || "$base" == lib*.c ]]; then rm -rf "$T"; continue; fi
    if [[ "$base" == *_caller.c ]]; then
      stem=${base%_caller.c}; libf="$dir/${stem}_lib.c"; [ -f "$libf" ] || libf=$(ls "$dir"/lib*.c 2>/dev/null | head -1)
      "$LLVM/clang" -I"$ORC/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null || { echo "$rel|CLANGERR|CLANGERR" >> "$OUT"; rm -rf "$T"; continue; }
      if [ -n "$libf" ] && [ -f "$libf" ]; then
        "$LLVM/clang" -I"$ORC/include" -O1 -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null && "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp "$T/a.ll" "$T/s1.ll"
      else cp "$T/a.ll" "$T/s1.ll"; fi
    else
      "$LLVM/clang" -I"$ORC/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null || { echo "$rel|CLANGERR|CLANGERR" >> "$OUT"; rm -rf "$T"; continue; }
    fi
  else cp "$f" "$T/s1.ll"; fi
  v() { local root=$1 tag=$2
    "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
    if [ $? -eq 0 ]; then echo "A:$(md5 -q "$T/$tag.ll" | cut -c1-8)"
    else echo "D:$(shasum "$T/$tag.err" | cut -c1-8):$(grep -oE 'cq [a-z0-9 -]+: [^\"]+' "$T/$tag.err" | head -1 | sed 's/ under quantum control//' | cut -c1-70)"; fi; }
  echo "$rel|$(v "$ORC" o)|$(v "$SUBJ" s)" >> "$OUT"
  rm -rf "$T"; n=$((n+1))
done < "$FILES"
echo "DONE $n rows" >> "$OUT"
rm -f "$FILES"
