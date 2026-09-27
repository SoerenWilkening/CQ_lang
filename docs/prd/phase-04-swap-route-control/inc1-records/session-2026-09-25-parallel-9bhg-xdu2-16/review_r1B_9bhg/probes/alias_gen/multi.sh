#!/bin/bash
# multi.sh <bin> <file> <N>: distribution of (rc, output-hash) over N runs
b=$1; f=$2; N=$3
for i in $(seq 1 $N); do
  o=$("$b" -passes=cq-lowering -S "$f" -o - 2>/dev/null); rc=$?
  echo "$rc $(printf '%s' "$o" | shasum -a 256 | cut -c1-10)"
done | sort | uniq -c | tr '\n' ';'
