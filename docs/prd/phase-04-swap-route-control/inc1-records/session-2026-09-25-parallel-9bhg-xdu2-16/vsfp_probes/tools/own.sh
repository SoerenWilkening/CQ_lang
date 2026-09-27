#!/bin/bash
# own.sh TAG : own probes (pairs vs twins, and singles on both binaries)
TAG=$1
cd "$(dirname "$0")" || exit 1
n=0
while read -r d s t; do
  [ -z "$d" ] && continue
  python3 h.py pair "$TAG" "$d" "$s" "$t" | cut -c1-230
  n=$((n+1))
done <<'LIST'
own_src n1 n1T
own_src q1 q1R
own_src f1 f1T
own_src i1 i1T
own_src dq dqT
r2a_src s3c s3cT
LIST
for s in c1 c2 s1 s2 st; do
  for b in main "$TAG"; do
    python3 h.py show "$b" own_src "$s" | head -1 | cut -c1-200
  done
  n=$((n+1))
done
echo "probes=$n"
