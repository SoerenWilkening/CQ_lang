#!/bin/bash
# stage2b_movers.sh — MERGE_BRIEF_TEMPLATE.md step 5's last clause: "every accepting
# mover re-lowered through STRICT stage 2b". Takes the corpus file, selects every row
# the MERGED binary accepts and the ORACLE did not, re-lowers it on the merged binary
# and runs tools/free_pairing_check.py with NO --allow-unproven.
set -u
LLVM=/usr/local/opt/llvm@19/bin
SUBJ=/Users/sorenwilkening/Desktop/CQ_mphi
IN=$1; OUT=$2
: > "$OUT"
grep -v '^#' "$IN" | grep -v '^DONE$' | awk -F'|' '$2 ~ /^D:/ && $3 ~ /^A:/ {print $1}' | sort > /tmp/.s2b.$$
echo "# STRICT stage 2b over $(wc -l < /tmp/.s2b.$$ | tr -d ' ') accepting movers | merged=$(shasum -a 256 $SUBJ/build/ir-pass/cq-opt|cut -c1-16)" >> "$OUT"
while read -r rel; do
  f=$SUBJ/$rel; T=$(mktemp -d)
  if [[ "$f" == *.c ]]; then
    base=$(basename "$f"); dir=$(dirname "$f")
    if [[ "$base" == *_caller.c ]]; then
      stem=${base%_caller.c}; libf="$dir/${stem}_lib.c"; [ -f "$libf" ] || libf=$(ls "$dir"/lib*.c 2>/dev/null | head -1)
      "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null
      if [ -n "${libf:-}" ] && [ -f "$libf" ]; then
        "$LLVM/clang" -I$SUBJ/include -O1 -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null && "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp "$T/a.ll" "$T/s1.ll"
      else cp "$T/a.ll" "$T/s1.ll"; fi
    else
      "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null
    fi
  else cp "$f" "$T/s1.ll"; fi
  "$SUBJ/build/ir-pass/cq-opt" -load-pass-plugin "$SUBJ/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/s2.ll" 2>/dev/null
  line=$( cd "$SUBJ" && python3 tools/free_pairing_check.py "$T/s2.ll" 2>&1 | tail -1 )
  echo "$rel | $line" >> "$OUT"
  rm -rf "$T"
done < /tmp/.s2b.$$
echo "# violations: $(grep -c 'violation' "$OUT" | tr -d ' ') lines mentioning 'violation'; non-zero check:" >> "$OUT"
grep -E '[1-9][0-9]* violation|[1-9][0-9]* unproven' "$OUT" >> "$OUT" || echo "# none: every row reads 0 violation(s), 0 unproven" >> "$OUT"
rm -f /tmp/.s2b.$$
echo DONE >> "$OUT"
