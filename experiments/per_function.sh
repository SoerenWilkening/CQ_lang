#!/bin/sh
# per_function.sh <linked.ll> <outdir> [plugin]: lowers every function of a module on its own, as a library root: its table clones under every argument
# arrangement (rule 27), and lists the pass errors by site. Every other function of the module and libc are named as
# lowered-library roots, so a call stays a call and one function's error does not hide another's.
# 6 at a time, 120 s each.
set -eu
IN=$1; OUT=$2; PLUGIN=${3:-$(cd "$(dirname "$0")/.." && pwd)/build-fast/pass/libCQLower.so}
L=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
E=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$OUT/f"
grep '^define ' "$IN" | sed -E 's/^define [^@]*@"?([A-Za-z0-9_.$]+)"?\(.*/\1/' | sort -u > "$OUT/functions.txt"
cat "$E/lib/libc.roots" "$OUT/functions.txt" | sort -u > "$OUT/roots.txt"
export IN OUT PLUGIN L
set +e
xargs -P6 -n1 sh -c '
f=$1; k=$(printf %s "$f" | cksum | cut -d" " -f1)   # file key: names differing only in case share a file on macOS
$L/llvm-extract --func="$f" -S "$IN" -o "$OUT/f/$k.ll" 2>/dev/null || { echo "$f|EXTRACT||"; exit 0; }
perl -e "alarm 120; exec @ARGV" $L/opt -load-pass-plugin="$PLUGIN" -passes=cq-lower -cq-roots="$OUT/roots.txt" -S -o /dev/null < "$OUT/f/$k.ll" > "$OUT/f/$k.err" 2>&1
rc=$?
if [ $rc = 0 ]; then echo "$f|ok||"; rm -f "$OUT/f/$k.ll" "$OUT/f/$k.err"
elif [ $rc = 142 ]; then echo "$f|TIMEOUT||"
else site=$(grep -m1 "^  site:" "$OUT/f/$k.err" | awk "{print \$2}"); msg=$(grep -m1 "LLVM ERROR" "$OUT/f/$k.err" | sed "s/.*internal error: //" | cut -c1-90); if [ -n "$site" ]; then echo "$f|ERROR|$site|$msg"; else echo "$f|CRASH||"; fi
fi' _ < "$OUT/functions.txt" > "$OUT/results.txt"
echo "functions: $(wc -l < "$OUT/functions.txt")"
cut -d'|' -f2 "$OUT/results.txt" | sort | uniq -c
echo "--- errors by site"
awk -F'|' '$2 == "ERROR" { print $3 " | " $4 }' "$OUT/results.txt" | sort | uniq -c | sort -rn
