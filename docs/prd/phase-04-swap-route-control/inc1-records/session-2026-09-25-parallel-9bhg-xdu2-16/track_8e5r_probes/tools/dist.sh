#!/bin/bash
# dist.sh <bin> <mode: system|lifo|nofree> <file.ll> <N>
# prints the distribution of (exit code, sha256[0:10] of stdout) over N runs.
b=$1; mode=$2; f=$3; N=$4
for i in $(seq 1 $N); do
  if [ "$mode" = system ]; then
    o=$(env -u CQ_OPT_DEBUG_ALLOC "$b" -passes=cq-lowering -S "$f" -o - 2>/dev/null); rc=$?
  else
    o=$(CQ_OPT_DEBUG_ALLOC=$mode "$b" -passes=cq-lowering -S "$f" -o - 2>/dev/null); rc=$?
  fi
  h=$(printf '%s' "$o" | shasum -a 256 | cut -c1-10)
  echo "$rc $h"
done | sort | uniq -c | awk '{printf "%sx(rc=%s,%s) ", $1, $2, $3}'
echo
