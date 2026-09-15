#!/bin/zsh
# ARM group gate — SOURCE MUTATION over `availableAtAnF2Slot` (2026-09-15).
#
# WHY IT EXISTS. Rule-13 round item R-3: Track F' shipped NO source-mutation
# gate, while Track P' ran three and one of them found a real defect ("a decline
# fixture reached by two roads measures neither"). F''s decline tripwires are
# pinned by ORACLE-vs-SUBJECT isolation and by an injection matrix over the
# ACCEPT fixture only — which is real evidence, and which does not answer
# *"would this fixture flip if the clause it exists for were deleted?"*, the
# OVER-ACCEPT direction the two back-edge files are for.
#
# WHAT IT MUTATES. `availableAtAnF2Slot` has exactly two clauses:
#     if (PredSlot && DT.dominates(I, PredSlot))            return true;   // PRED slot
#     for (ArmBB : ArmSlots) if (ArmBB && DT.dominates(...)) return true;  // ARM slot
# and the caller `continue`s (truncates) on `true`. So:
#     MA  body -> `return false;`   nothing ever truncates; the exclusion set
#                 becomes the FULL user closure of M; MORE exclusions, FEWER
#                 witnesses, MORE accepts  -> the DECLINE fixtures must go RED.
#     MB  body -> `return true;`    everything truncates; the set collapses to
#                 {M}; FEWER exclusions, MORE witnesses, MORE declines
#                 -> the ACCEPT fixture must go RED.
#     MC  PRED clause deleted (ARM clause kept).
#     MD  ARM clause deleted (PRED clause kept).
# MA and MB are the two DIRECTIONS; MC and MD isolate the two CLAUSES.
#
# ⚠ A MUTANT THAT FLIPS NOTHING IS REPORTED AS SUCH AND NOT AS A PASS
# (PROTOCOL S3: "a mutation harness that reports n/a is a HOLE, not a pass").
# MD is expected to flip nothing — the source header gives three independent
# reasons the ARM clause is unreachable today — and that expectation is a CLAIM
# THIS RUN TESTS, not a licence to skip it.
#
# Usage: source_mutation.sh <MA|MB|MC|MD|RESTORE>
set -eu
ROOT=/Users/sorenwilkening/Desktop/CQ_ARM
SRC=$ROOT/ir-pass/src/ArmClassify.cpp
BAK=${CQ_ARMGATE_SCRATCH:-/tmp}/armgate_ArmClassify.cpp.orig
FILTER='(backedge|acyclic_nondominated|sideways|range_forward|step_cap_over|merge_edge|offwire|mergephi_cross_block|mergephi_two_leaves|mergephi_inloop|cross_block_theta|offwire_theta|inloop_latch_theta)'
# 27 fixtures at HEAD: the two back-edge tripwires, the four acyclic-nondominated
# files (converted decline + its control, new accept + its control), the >=11
# shipped merge-block colliders the REFUSED dominance conjunct would flip, and
# Track P''s own family. A mutant that moves a COLLIDER has drifted onto the
# refused conjunct and that is a FINDING, not a flip.

[ -f "$BAK" ] || cp -f "$SRC" "$BAK"

case "${1:-}" in
  MA) python3 - "$SRC" <<'PY'
import sys,re
p=sys.argv[1]; s=open(p).read()
old="""  if (PredSlot && DT.dominates(I, PredSlot))
    return true;
  for (const BasicBlock *ArmBB : ArmSlots)
    if (ArmBB && DT.dominates(I->getParent(), ArmBB))
      return true;
  return false;"""
assert s.count(old)==1, s.count(old)
open(p,"w").write(s.replace(old,"  (void)PredSlot; (void)ArmSlots; (void)DT; (void)I;\n  return false;  // MUTANT MA"))
PY
   ;;
  MB) python3 - "$SRC" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
old="""  if (PredSlot && DT.dominates(I, PredSlot))
    return true;
  for (const BasicBlock *ArmBB : ArmSlots)
    if (ArmBB && DT.dominates(I->getParent(), ArmBB))
      return true;
  return false;"""
assert s.count(old)==1, s.count(old)
open(p,"w").write(s.replace(old,"  (void)PredSlot; (void)ArmSlots; (void)DT; (void)I;\n  return true;  // MUTANT MB"))
PY
   ;;
  MC) python3 - "$SRC" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
old="""  if (PredSlot && DT.dominates(I, PredSlot))
    return true;
"""
assert s.count(old)==1, s.count(old)
open(p,"w").write(s.replace(old,"  (void)PredSlot;  // MUTANT MC: PRED clause deleted\n"))
PY
   ;;
  MD) python3 - "$SRC" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
old="""  for (const BasicBlock *ArmBB : ArmSlots)
    if (ArmBB && DT.dominates(I->getParent(), ArmBB))
      return true;
"""
assert s.count(old)==1, s.count(old)
open(p,"w").write(s.replace(old,"  (void)ArmSlots;  // MUTANT MD: ARM clause deleted\n"))
PY
   ;;
  RESTORE) cp -f "$BAK" "$SRC" ;;
  *) echo "usage: $0 <MA|MB|MC|MD|RESTORE>"; exit 2 ;;
esac

echo "=== mutant ${1} applied; rebuilding BOTH targets (never --target CQPass alone) ==="
cmake --build "$ROOT/build" -j6 > /tmp/_armgate_mut_build.log 2>&1 || { tail -25 /tmp/_armgate_mut_build.log; exit 1; }
echo "cq-opt sha256: $(shasum -a 256 $ROOT/build/ir-pass/cq-opt | cut -c1-16)"
echo "libCQPass sha256: $(shasum -a 256 $ROOT/build/ir-pass/libCQPass.so | cut -c1-16)"
cd "$ROOT/build" && lit ir-pass/test --filter "$FILTER" 2>&1 | tail -30
