#!/bin/bash
# pp.sh TAG DIR subj:twin ... : pair each subject with its twin under binary TAG
cd "$(dirname "$0")" || exit 1
TAG=$1; D=$2; shift 2
n=0
for p in "$@"; do
  s=${p%%:*}; t=${p##*:}
  python3 h.py pair "$TAG" "$D" "$s" "$t" 2>&1 | head -1 | cut -c1-${W:-200}
  n=$((n+1))
done
echo "pairs=$n"
