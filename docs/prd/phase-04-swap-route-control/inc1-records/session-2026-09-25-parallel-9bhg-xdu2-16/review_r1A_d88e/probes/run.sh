#!/bin/bash
# run.sh "tags" name... ; tags in bin/ ; prints rc, #measure, #ry, first error
A="$(cd "$(dirname "$0")" && pwd)"
TAGS="$1"; shift
for m in "$@"; do
  m="${m%.c}"; f="$A/p/$m.s1.ll"
  [ -s "$f" ] || { echo "$m MISSING/EMPTY"; continue; }
  for t in $TAGS; do
    "$A/bin/$t" -passes=cq-lowering -S "$f" -o "$A/p/$m.$t.s2.ll" 2> "$A/p/$m.$t.err"
    rc=$?
    err=$(grep -o 'error: .*' "$A/p/$m.$t.err" | head -1 | sed 's/^error: [^ ]* //' | cut -c1-110)
    [ -z "$err" ] && [ "$rc" != 0 ] && err=$(head -1 "$A/p/$m.$t.err" | cut -c1-110)
    w=$(grep -c 'warning:' "$A/p/$m.$t.err")
    meas=""; [ "$rc" = 0 ] && meas="meas=$(grep -c 'call .*@cqrt_measure' "$A/p/$m.$t.s2.ll") ry=$(grep -c 'call .*@cqrt_ry' "$A/p/$m.$t.s2.ll")"
    printf '%-14s %-5s rc=%-3s %-14s w=%s %s\n' "$m" "$t" "$rc" "$meas" "$w" "$err"
  done
done
exit 0
