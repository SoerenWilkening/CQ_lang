#!/bin/bash
# bd `n74d` — THE M12-STYLE MUTANT the bead asks a fix agent to take.
#
# The shipped B4' clause is DEFENCE IN DEPTH: on the shipped binary the carve's C6
# refuses an in-loop read of another cell first, so no module isolates the clause
# and no fixture can be red-green for it. This script removes that upstream refusal
# (mutant M11) and measures the promoter WITH and WITHOUT the bd `n74d` fix (M10)
# on the `-O1` hoisted-address module.
#   $1 = "fixed" | "unfixed"
set -uo pipefail
cd /Users/sorenwilkening/Desktop/CQ_A
Q=ir-pass/src/QramLowering.cpp; P=ir-pass/src/RailBankPromote.cpp
cp $Q /tmp/ta/nQ.keep; cp $P /tmp/ta/nP.keep
revert() { cp /tmp/ta/nQ.keep $Q; cp /tmp/ta/nP.keep $P; }
trap revert EXIT INT TERM HUP
python3 - "$1" <<'PY'
import sys
mode=sys.argv[1]
q="ir-pass/src/QramLowering.cpp"; p="ir-pass/src/RailBankPromote.cpp"
s=open(q).read()
o="""      if (!LG || !railBankCellAddress(LG, taint, Origin, CellTy, LIdx) ||
          SE.getSCEV(LIdx) != IdxS) {"""
n="""      if (!LG || !railBankCellAddress(LG, taint, Origin, CellTy, LIdx) ||
          false) {"""
assert s.count(o)==1, "M11 pattern not unique"
open(q,"w").write(s.replace(o,n))
if mode=="unfixed":
    t=open(p).read()
    o2="""      if (auto *RG = dyn_cast<GetElementPtrInst>(UI))
        for (User *RU : RG->users())
          if (auto *RI = dyn_cast<Instruction>(RU))
            NonRewritable.push_back(RI);
"""
    assert t.count(o2)==1, "M10 pattern not unique"
    open(p,"w").write(t.replace(o2,""))
print("applied: M11" + (" + M10" if mode=="unfixed" else " only"))
PY
cmake --build build -j2 > /tmp/ta/n74d.build 2>&1 || { echo BUILDFAIL; grep -m1 error: /tmp/ta/n74d.build; exit 1; }
echo "binary $(shasum -a 256 build/ir-pass/cq-opt | cut -c1-16)"
F=ir-pass/test/railbank_promote_reject_inloop_hoisted_read.ll
OUT=$(CQ_RAILBANK_DBG=1 build/ir-pass/cq-opt -passes=cq-lowering -S $F -o /dev/null 2>&1)
echo "promo=$(printf '%s\n' "$OUT" | grep -c 'CQ_RAILBANK_DBG: promote bank')"
printf '%s\n' "$OUT" | sed -n '/^6:/,/^}/p' | sed -n '1,22p'
