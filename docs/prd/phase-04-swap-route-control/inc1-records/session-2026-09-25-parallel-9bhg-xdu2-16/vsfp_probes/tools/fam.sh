#!/bin/bash
# fam.sh TAG : the F-9C-1 family + hgwx j02 against twins
TAG=$1
cd "$(dirname "$0")" || exit 1
n=0
while read -r d s t; do
  [ -z "$d" ] && continue
  python3 h.py pair "$TAG" "$d" "$s" "$t"
  n=$((n+1))
done <<'LIST'
r2a_src b10 b10T
r2a_src b15 b15T
r2a_src s3d s3dT
r2a_src b10f b10T
r2a_src b15f b15T
r2a_src s3c s3dT
r2a_src b26 b26T
r2a_src b20 b20T
r2a_src b2 b2T
r2a_src b5 b5T
r2a_src b6 b6T
r2a_src b7f b7T
r2a_src b8f b8T
r2a_src b12f b12T
r2a_src b17f b17T
r2a_src b18f b18T
d88e_src j02C j02T
LIST
echo "pairs=$n"
