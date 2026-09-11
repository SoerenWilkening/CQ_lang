#!/bin/bash
# $1 = fixture path (in CQ_f2). Compare branch vs oracle: rc, stderr, stdout.
F="$1"
NEW=/Users/sorenwilkening/Desktop/CQ_f2/build/ir-pass
OLD=/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass
b=$(basename "$F" .ll)
T=$(mktemp -d)
"$NEW/cq-opt" -load-pass-plugin "$NEW/libCQPass.so" -passes=cq-lowering -S "$F" -o "$T/new.ll" 2>"$T/new.err"; rcn=$?
"$OLD/cq-opt" -load-pass-plugin "$OLD/libCQPass.so" -passes=cq-lowering -S "$F" -o "$T/old.ll" 2>"$T/old.err"; rco=$?
st="SAME"
[ "$rcn" != "$rco" ] && st="RCDIFF"
if [ "$rcn" = 0 ] && [ "$rco" = 0 ]; then
  cmp -s "$T/new.ll" "$T/old.ll" || st="OUTDIFF"
fi
if ! cmp -s "$T/new.err" "$T/old.err"; then
  [ "$st" = "SAME" ] && st="DIAGDIFF"
fi
echo "$st rc_new=$rcn rc_old=$rco $b :: $(head -c 200 $T/new.err | tr '\n' ' ') || $(head -c 200 $T/old.err | tr '\n' ' ')"
rm -rf "$T"
