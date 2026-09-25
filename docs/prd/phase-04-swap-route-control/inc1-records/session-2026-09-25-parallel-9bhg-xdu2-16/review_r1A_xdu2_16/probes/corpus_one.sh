#!/bin/bash
# corpus_one.sh A B FILE — one record line: rc/stdout-sha/first-error for both binaries.
# rc is captured DIRECTLY from the tool (no pipe), then the output file is hashed.
A=$1; B=$2; f=$3
d=$(mktemp -d)
"$A" -passes=cq-lowering -S "$f" -o "$d/a.ll" 2>"$d/ea"; ca=$?
"$B" -passes=cq-lowering -S "$f" -o "$d/b.ll" 2>"$d/eb"; cb=$?
sa=$( [ -s "$d/a.ll" ] && shasum -a 256 < "$d/a.ll" | cut -c1-16 || echo none)
sb=$( [ -s "$d/b.ll" ] && shasum -a 256 < "$d/b.ll" | cut -c1-16 || echo none)
xa=$(grep -m1 'error:' "$d/ea" | sed 's/.*error: //'); xb=$(grep -m1 'error:' "$d/eb" | sed 's/.*error: //')
rm -rf "$d"
k=SAME; if [ "$ca" != "$cb" ] || [ "$sa" != "$sb" ] || [ "$xa" != "$xb" ]; then k=MOVER; fi
echo "$k $(basename "$f") A:rc=$ca,$sa,[$xa] B:rc=$cb,$sb,[$xb]"
