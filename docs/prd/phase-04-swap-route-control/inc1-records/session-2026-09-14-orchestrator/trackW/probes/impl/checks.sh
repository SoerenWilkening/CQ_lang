#!/bin/bash
# checks.sh <file.ll> [function] — print the emitted cqrt_*/cq_template_* call
# sequence of one function of the LOWERED module, as ready-made CHECK lines.
SUBJ=/Users/sorenwilkening/Desktop/CQ_wx8g
F=$1; FN=${2:-example}
T=$(mktemp -d)
"$SUBJ/build/ir-pass/cq-opt" -load-pass-plugin "$SUBJ/build/ir-pass/libCQPass.so" \
  -passes=cq-lowering -S "$F" -o "$T/s2.ll" 2>"$T/err" || { echo "DECLINE:"; head -2 "$T/err"; rm -rf $T; exit 1; }
echo "--- full lowered @$FN ---"
sed -n "/define .*@$FN(/,/^}/p" "$T/s2.ll"
echo "--- gate sequence ---"
sed -n "/define .*@$FN(/,/^}/p" "$T/s2.ll" | grep -oE '@(cqrt|cq_template)[A-Za-z0-9_]*\([^)]*\)' | sed 's/^/; CHECK: /'
rm -rf $T
