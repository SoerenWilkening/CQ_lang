#!/bin/bash
# Track A 2026-09-15 — the INJECTION (mutation) MATRIX over the accept surface this
# track changed: the carve's clause C7 (`Bank` vs `BankRaw`, bd `de8n`) and the
# promoter's B4' (bd `n74d`), B6 and B9 (merge filing F-2).
#
# For each mutant: apply, rebuild BOTH targets, run the railbank fixture set, record
# CAUGHT (>=1 fixture red) or MISSED (all green), revert.
#
# ⚠ INSTRUMENT DISCIPLINE — each of these closes a measured failure of some earlier
# harness in this project:
#   * a mutation that does not apply is a HOLE, not a pass -> the edit asserts the
#     pattern occurs EXACTLY ONCE and the row is `MUTATION-HOLE` otherwise;
#   * a harness that runs a WEAKER command than lit measures itself, not the
#     fixtures -> this runs `lit`, the same command the suite runs;
#   * a matrix with no mutants reports `MISSED 0` -> the count is printed;
#   * a BUILD FAILURE IS NOT A CAUGHT -> reported separately as BUILDFAIL.
set -uo pipefail
cd /Users/sorenwilkening/Desktop/CQ_A
Q=ir-pass/src/QramLowering.cpp
P=ir-pass/src/RailBankPromote.cpp
FILTER=${FILTER:-railbank}
mkdir -p /tmp/ta; cp $Q /tmp/ta/Q.orig; cp $P /tmp/ta/P.orig
revert() { cp /tmp/ta/Q.orig $Q; cp /tmp/ta/P.orig $P; }
trap revert EXIT

apply() {
python3 - "$1" "$2" "$3" <<'PY'
import sys
p,o,n=sys.argv[1],sys.argv[2],sys.argv[3]
s=open(p).read()
if s.count(o)!=1: sys.exit(3)
open(p,"w").write(s.replace(o,n))
PY
}

run_one() { # name file old new
  local name=$1 file=$2 old=$3 new=$4
  revert
  if ! apply "$file" "$old" "$new"; then echo "$name|MUTATION-HOLE(pattern not unique)"; return; fi
  if ! cmake --build build -j2 > /tmp/ta/mut.build 2>&1; then
    echo "$name|BUILDFAIL|$(grep -m1 error: /tmp/ta/mut.build | cut -c1-90)"; return; fi
  local out fails names
  out=$(cd build && lit ir-pass/test --filter "$FILTER" 2>&1)
  fails=$(printf '%s\n' "$out" | grep -c '^FAIL:')
  names=$(printf '%s\n' "$out" | grep '^FAIL:' | sed 's/^FAIL: CQ IR-pass :: //;s/ (.*//' | tr '\n' ' ')
  if [ "$fails" -gt 0 ]; then echo "$name|CAUGHT($fails)|$names"; else echo "$name|**MISSED**"; fi
}

echo "=== injection matrix, filter='$FILTER' ==="
run_one "M1  C7(a) deleted (in-loop read no longer downgrades)" "$Q" \
  'if (AnyReadInsideL || !WriteIsTotalPerTrip)' 'if (!WriteIsTotalPerTrip)'
run_one "M2  C7(b) deleted (conditional store no longer downgrades)" "$Q" \
  'if (AnyReadInsideL || !WriteIsTotalPerTrip)' 'if (AnyReadInsideL)'
run_one "M3  C7(b) weakened: drop the single-exiting-block conjunct" "$Q" \
  'Latch && L->getExitingBlock() == Latch &&' 'Latch &&'
run_one "M4  C7(b) weakened: drop the dominates-the-latch conjunct" "$Q" \
  'DT.dominates(SI->getParent(), Latch);' 'true;'
run_one "M5  C7 deleted entirely (the pre-fix binary: one accept verdict)" "$Q" \
  'if (AnyReadInsideL || !WriteIsTotalPerTrip)
    return RailBankCarve::BankRaw;' ''
run_one "M6  C7(a) flag never set (equivalent spelling of M1)" "$Q" \
  'AnyReadInsideL = true;  // C7(a)' 'AnyReadInsideL = false;  // C7(a)'
run_one "M7  B6 requires Bank instead of BankRaw" "$P" \
  'RailBankCarve::BankRaw)' 'RailBankCarve::Bank)'
run_one "M8  B6 accepts BOTH Bank and BankRaw" "$P" \
  '    if (railBankCarveVerdict(SI, taint, DT, LI, SE, Msg, &Shape) !=
        RailBankCarve::BankRaw)
      return false;' '    RailBankCarve BV = railBankCarveVerdict(SI, taint, DT, LI, SE, Msg, &Shape);
    if (BV != RailBankCarve::BankRaw && BV != RailBankCarve::Bank)
      return false;'
run_one "M9  B9 weakened to >=1 store per activation" "$P" \
  'if (Plan.Stores.size() != 1)' 'if (Plan.Stores.empty())'
run_one "M10 B4-prime reverted: the Read gep's LOADS are not observed (bd n74d)" "$P" \
  '      if (auto *RG = dyn_cast<GetElementPtrInst>(UI))
        for (User *RU : RG->users())
          if (auto *RI = dyn_cast<Instruction>(RU))
            NonRewritable.push_back(RI);' ''
run_one "M11 CONTROL: carve C6 in-loop-read-of-another-cell deleted (pre-existing clause)" "$Q" \
  '          SE.getSCEV(LIdx) != IdxS) {' '          false) {'
revert
cmake --build build -j2 > /tmp/ta/mut.build 2>&1 && echo "reverted + rebuilt: $(shasum -a 256 build/ir-pass/cq-opt | cut -c1-16)"
