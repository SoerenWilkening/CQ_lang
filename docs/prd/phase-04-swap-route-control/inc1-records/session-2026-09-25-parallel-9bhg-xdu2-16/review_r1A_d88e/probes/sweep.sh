#!/bin/bash
# sweep.sh BIN LISTFILE OUT  (parallel 4)
A="$(cd "$(dirname "$0")" && pwd)"
BIN="$1"; LIST="$2"; OUT="$3"
xargs -P 4 -n 1 "$A/one.sh" "$BIN" < "$LIST" | sort > "$OUT"
echo "denominator: $(wc -l < "$LIST") listed, $(wc -l < "$OUT") measured"
