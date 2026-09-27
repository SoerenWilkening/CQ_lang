#!/bin/bash
# r2bat.sh TAG : the round-2 battery. Every r1A/r1B/F-9C-1/hgwx probe against its
# hand-inlined (or fenv-intended) twin under binary TAG; singles against the oracle.
# Prints one line per pair and a class count with the denominator.
cd "$(dirname "$0")" || exit 1
TAG=$1
OUT=r2bat_$TAG.txt
: > "$OUT"
PAIRS="
v15vc b15T
v15vs b15T
v15vl b15T
v15vd b15T
v26vf b15T
v26vb b15T
v02 b15T
v01 b15T
v15vx b15T
v15vn b15T
v26v2s b15T
v29c b15T
v29 b15T
v26vtwo b15T
v20 s3dT
v07 s3dT
v21 b15T
v22 b10T
v23 s3cT
v24 b26T
v25 b20T
v03 v03T
v03b v03bT
v04 v04T
v06 v06T
v11 v11T
v13 v13T
v14 v14T
v16 v16T
v08c v08T
v08d v08T
v10 v10T
v12 v12T
v17 v17T
v18 v18T
v19 v19T
v27 v27T
v30 v30F
v30i v30F
qjoc b15T
qjoc_tpl qjoc_tplT
b10 b10T
b15 b15T
s3d s3dT
b10f b10T
b15f b15T
s3c s3cT
b26 b26T
b20 b20T
b2 b2T
b5 b5T
b6 b6T
b7f b7T
b8f b8T
b12f b12T
b17f b17T
b18f b18T
j02C j02T
e02C e02T
j01C j01T
prov1 prov1_twin
bint1 bint1_twin
bint2 bint2_twin
bint3 bint3_twin
bint4 bint4_twin
bint5 bint5_twin
ctlz1 ctlz1_twin
ctlz2 ctlz2_twin
dcar1 dcar1_twin
dcar5 dcar5_twin
dcar6 dcar6_twin
dloop1 dloop1_twin
dloop2 dloop2_twin
dloop3 dloop3_twin
ediam1 ediam1_twin
ediam2 ediam2_twin
meas1 meas1_twin
av1 av1t
aw9 aw9t
"
n=0
while read -r s t; do
  [ -z "$s" ] && continue
  python3 h.py pair "$TAG" r2src "$s" "$t" 2>&1 | head -1 | cut -c1-260 >> "$OUT"
  n=$((n+1))
done <<< "$PAIRS"
# singles: must equal the ORACLE's verdict/trace (naked1: classical output; naked2: the oracle's decline; resv2: user-defined reserved symbol; v09: weak; v16b)
for s in naked1 naked2 resv2 v09 v16b; do
  a=$(python3 h.py show main r2src "$s" 2>&1)
  b=$(python3 h.py show "$TAG" r2src "$s" 2>&1)
  ah=$(printf '%s' "$a" | tail -n +2 | shasum | cut -c1-12)
  bh=$(printf '%s' "$b" | tail -n +2 | shasum | cut -c1-12)
  av=$(printf '%s' "$a" | head -1 | sed 's/^\[[^]]*\] [^:]*: //' | cut -c1-120)
  bv=$(printf '%s' "$b" | head -1 | sed 's/^\[[^]]*\] [^:]*: //' | cut -c1-120)
  if [ "$ah" = "$bh" ] && [ "${av%% *}" = "${bv%% *}" ]; then c=ORACLE-SAME; else c=ORACLE-DIFF; fi
  echo "[$TAG] single $s: $c | main: $av | $TAG: $bv" >> "$OUT"
  n=$((n+1))
done
echo "denominator=$n" >> "$OUT"
grep -o "TRACE-IDENT\|TRACE-DIFF\|DECL-SAME\|DECL-DIFFSTR\|VERDICT-DIFF\|ORACLE-SAME\|ORACLE-DIFF" "$OUT" | sort | uniq -c >> "$OUT"
cat "$OUT"
