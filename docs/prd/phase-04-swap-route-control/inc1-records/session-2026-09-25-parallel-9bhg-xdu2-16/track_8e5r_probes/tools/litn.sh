#!/bin/bash
# litn.sh TAG FILTER N — run lit (private site TAG) on FILTER N times; print the
# per-run PASS/FAIL tally (the denominator is N).
T=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r
tag=$1; filt=$2; N=${3:-10}
p=0; f=0
for i in $(seq 1 "$N"); do
  out=$(lit "$T/lit_$tag" --filter "$filt" 2>&1)
  np=$(printf '%s\n' "$out" | grep -c '^PASS:')
  nf=$(printf '%s\n' "$out" | grep -c '^FAIL:')
  p=$((p + np)); f=$((f + nf))
done
echo "lit[$tag] filter='$filt' runs=$N  PASS-results=$p  FAIL-results=$f"
