#!/bin/bash
# r3gen.sh : round-3 probe set — regenerate sources, build fp1/fp3/l3, stage the Rule-13 r2
# reviewer's hand-IR pkd pair (copied verbatim into ir/), then run tri.sh on all four.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
D="$(cd "$(dirname "$0")" && pwd)"
cd "$D" || exit 1
python3 "$D/mkprobes.py" > /dev/null
bash "$D/gen.sh" fp1C fp1T fp3C fp3T l3C l3T
mkdir -p "$D/ir"
cp -f "$D/../review_r2_cepm/probes/ir/pkdC.s1.ll" "$D/ir/pkdC.s1.ll"
cp -f "$D/../review_r2_cepm/probes/ir/pkdT.s1.ll" "$D/ir/pkdT.s1.ll"
cp -f "$D/ir/pkdC.s1.ll" "$S/cepm/p/pkdC.s1.ll"
cp -f "$D/ir/pkdT.s1.ll" "$S/cepm/p/pkdT.s1.ll"
bash "$D/tri.sh" fp1 fp3 l3 pkd
