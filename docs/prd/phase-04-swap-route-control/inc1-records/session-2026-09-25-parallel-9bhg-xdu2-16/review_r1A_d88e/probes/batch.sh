#!/bin/bash
# batch.sh LIST OUT : for each name, rc + stderr-hash per binary (ora new c9 comp)
A="$(cd "$(dirname "$0")" && pwd)"
LIST="$1"; OUT="$2"; : > "$OUT"; n=0
while read -r m; do
  f="$A/p/$m.s1.ll"; [ -s "$f" ] || { echo "$m MISSING" >> "$OUT"; continue; }
  n=$((n+1)); line="$m"
  for t in ora new c9 comp; do
    "$A/bin/$t" -passes=cq-lowering -S "$f" -o "$A/p/$m.$t.s2.ll" 2> "$A/p/$m.$t.err"; rc=$?
    h=$(shasum -a 256 < "$A/p/$m.$t.err" | cut -c1-8)
    mm=""; [ "$rc" = 0 ] && mm=":m$(grep -c 'call .*@cqrt_measure' "$A/p/$m.$t.s2.ll")"
    line="$line	$t=$rc$mm/$h"
  done
  echo "$line" >> "$OUT"
done < "$LIST"
echo "denominator: $n" >> "$OUT"
