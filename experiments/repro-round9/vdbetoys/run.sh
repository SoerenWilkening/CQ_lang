#!/bin/bash
# run.sh PLUGIN FAMILY "Ns" OUTDIR: lowers gen.py's toys and counts calls over the whole lowered module
P=$1; F=$2; O=$4; D=$(cd "$(dirname "$0")" && pwd); mkdir -p "$O"
for n in $3; do
  python3 "$D/gen.py" "$F" "$n" > "$O/$F$n.c"
  /usr/local/opt/llvm@19/bin/clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 "$O/$F$n.c" -o "$O/$F$n.ll"
  /usr/bin/time -l /usr/local/opt/llvm@19/bin/opt -load-pass-plugin="$P" -passes=cq-lower -cq-roots="$D/roots.txt" \
    -S -o "$O/$F$n.out.ll" < "$O/$F$n.ll" 2> "$O/$F$n.err"
  rss=$(grep "maximum resident" "$O/$F$n.err" | awk '{print int($1/1048576)}')
  sec=$(grep " real " "$O/$F$n.err" | awk '{print $1}')
  c() { grep -c "$1" "$O/$F$n.out.ll"; }
  printf "%-6s N=%-3s push=%-7s and=%-7s xor=%-7s tmpl=%-6s lines=%-8s %ss %sMB %s\n" "$F" "$n" \
    "$(c 'call void @cqrt_push')" "$(c 'call void @cqrt_and_i1')" "$(c 'call void @cqrt_xor_i1')" \
    "$(c '@cq_template')" "$(wc -l < "$O/$F$n.out.ll")" "$sec" "$rss" "$(grep -m1 -i 'error' "$O/$F$n.err")"
done
