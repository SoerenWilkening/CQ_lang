#!/bin/bash
# corpus sweep: one binary over every ir-pass/test/*.ll, verdict + diagnostic string.
# ⚠ BOUNDARY CONTROLS, and they exist because THE FIRST SPELLING OF THIS SCRIPT
# REPORTED "0 MOVERS" WHILE EVERY ROW WAS EXIT 127 (`cq-opt` not at the path it
# was handed) — a checker nobody has tried to fool is a checker nobody should
# trust (CLAUDE.md L10). It now refuses to produce a file at all unless the
# binary exists, no row is 127, and BOTH verdicts actually occur.
set -u
BD="$1"; OUT="$2"
CQ="$BD/ir-pass/cq-opt"; PL="$BD/ir-pass/libCQPass.so"
[ -x "$CQ" ] || { echo "REFUSE: no executable at $CQ" >&2; exit 2; }
[ -f "$PL" ] || { echo "REFUSE: no plugin at $PL" >&2; exit 2; }
TMP="$OUT.part"; : > "$TMP"
for f in /Users/sorenwilkening/Desktop/CQ_LOOPFIX/ir-pass/test/*.ll; do
  err=$("$CQ" -load-pass-plugin "$PL" -passes=cq-lowering -S "$f" -o /dev/null 2>&1); e=$?
  b=$(basename "$f")
  if [ $e -eq 0 ]; then echo "$b|A|" >> "$TMP"
  else
    s=$(echo "$err" | grep -o 'cq [a-z0-9 -]*\(lowering\|escape\|propagation\)[^|]*' | head -1)
    [ -z "$s" ] && s="<NO-DIAGNOSTIC-TEXT>"
    echo "$b|D$e|$s" >> "$TMP"
  fi
done
n127=$(grep -c '|D127|' "$TMP" || true)
nA=$(grep -c '|A|'   "$TMP" || true)
nD=$(grep -c '|D1|'  "$TMP" || true)
if [ "$n127" -ne 0 ] || [ "$nA" -lt 100 ] || [ "$nD" -lt 100 ]; then
  echo "REFUSE: sweep is not measuring the compiler (127=$n127 accepts=$nA declines=$nD)" >&2
  exit 2
fi
mv -f "$TMP" "$OUT"
echo "sweep OK: $(wc -l < "$OUT") rows, accepts=$nA declines=$nD"
