#!/bin/bash
# Track U R3 — three verdicts per fixture on the phi-injection mutants.
#   O_u = ORACLE on the undef mutant ; S_u = SUBJECT on the undef mutant
#   O_z = ORACLE on the hand-normalized ZERO twin
# Claim under test:  S_u == O_z  (IR bytes for an accept, stderr for a decline).
ORACLE=/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt
SUBJECT=/Users/sorenwilkening/Desktop/CQ_undef/build/ir-pass/cq-opt
U=/tmp/cqu_r3_u ; Z=/tmp/cqu_r3_z ; OUT=/tmp/cqu_r3_out
mkdir -p "$OUT"
run() { # $1=binary $2=input $3=tag
  local b=$(basename "$2" .ll)
  "$1" -passes=cq-lowering -S "$2" -o "$OUT/$b.$3.ll" 2>"$OUT/$b.$3.err"
  echo $? > "$OUT/$b.$3.rc"
}
export -f run ; export OUT
one() {
  f="$1" ; b=$(basename "$f" .ll)
  run /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt  "/tmp/cqu_r3_u/$b.ll" Ou
  run /Users/sorenwilkening/Desktop/CQ_undef/build/ir-pass/cq-opt "/tmp/cqu_r3_u/$b.ll" Su
  run /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt  "/tmp/cqu_r3_z/$b.ll" Oz
}
export -f one
ls /tmp/cqu_r3_u/*.ll | xargs -P 4 -I{} bash -c 'one "$@"' _ {}
echo "sweep done: $(ls /tmp/cqu_r3_out/*.rc 2>/dev/null | wc -l) verdict files"
