#!/bin/bash
# modes.sh <file.ll> [N] [bins...] — distribution per (binary, allocator mode).
T=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r
f=$1; N=${2:-10}; shift 2
BINS=${@:-ora_alloc subj2}
cd "$T"
for b in $BINS; do
  for m in lifo nofree system; do
    echo "$b $m: $(./dist.sh ./cq-opt.$b $m "$f" "$N")"
  done
done
