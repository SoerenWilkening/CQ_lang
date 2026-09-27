#!/bin/bash
# trace_sweep.sh <listfile> <outfile>: run instrumented cq-opt with CQ_R2A_TRACE on each module; keep R2A lines prefixed by module
BIN=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r2A/build/ir-pass/cq-opt
list=$1; out=$2; : > "$out"
n=0
while IFS= read -r f; do
  n=$((n+1))
  CQ_R2A_TRACE=1 "$BIN" -passes=cq-lowering -S "$f" -o /dev/null > /tmp/r2a_$$.err 2>&1
  rc=$?
  grep "^R2A" /tmp/r2a_$$.err | sed "s|^|$(basename "$f") rc=$rc |" >> "$out"
done < "$list"
rm -f /tmp/r2a_$$.err
echo "swept $n modules" >> "$out"
