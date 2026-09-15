#!/bin/bash
# Track P′ — SOURCE mutation validation (2026-09-15).
#
# ⚠ WHY THIS EXISTS AND WHY THE FIXTURE DECLINES DO NOT REPLACE IT. The three new
# DECLINE fixtures also declined on the BASE binary — through the OLD unconditional
# cross-block bail. So "the fixture is red on the subject" proves only that SOMETHING
# declines, not that the new CFG-bounded scan is what does it. A decline fixture whose
# subject is reached by two different roads is exactly CLAUDE.md Rule 12(c)'s "a
# decline fixture that goes green because its SUBJECT no longer exists pins nothing",
# seen from the other side.
#
# Each mutation below REMOVES one clause of the increment and asserts that a NAMED
# fixture flips. A clause whose removal flips nothing is a clause no gate in the tree
# is testing.
#
#   S-M1  drop the `push(S)` over `successors(Pred)`   -> the BACK-EDGE clause
#         expect: control_phase_kickback_reject_mergephi_inloop_latch_theta.ll  FAILS
#         ⚠ ITS FIRST RUN DID NOT FLIP IT, and that was a real finding rather than a
#         harness bug: the fixture then used an ON-WIRE latch theta, which the wire
#         walk refuses on its own. The fixture was rebuilt around an OFF-WIRE operand
#         (`%b0`) so that exactly one road reaches the decline. A decline fixture
#         reached by two roads measures neither.
#   S-M2  make the cross-block walk `return false` at once -> the SCAN itself
#         expect: ..._cross_block_OFFWIRE_theta.ll FAILS and ..._cross_block_theta.ll
#         does NOT -- the on-wire spelling is doubly covered by the wire walk, which
#         is measured here rather than assumed and is why the two files both exist
#   S-M3  neuter the PhaseKickback precedence edge      -> the ORDER half
#         expect: ..._reject_mergephi_cross_block.ll (now an ACCEPT) FAILS
#
# Usage: source_mutation.sh            (runs all three, restores, rebuilds, hash-checks)
set -uo pipefail
R=/Users/sorenwilkening/Desktop/CQ_P
AC=$R/ir-pass/src/ArmClassify.cpp
SR=$R/ir-pass/src/SwapRouteEmit.cpp
SUBJECT_HASH=7916923f56fb36af90dfd05efe0b8c45317db5dc30d4d90ec56f8ffadba56e72
cp -f "$AC" /tmp/_p_ArmClassify.orig.cpp
cp -f "$SR" /tmp/_p_SwapRouteEmit.orig.cpp
restore() { cp -f /tmp/_p_ArmClassify.orig.cpp "$AC"; cp -f /tmp/_p_SwapRouteEmit.orig.cpp "$SR"; }
trap restore EXIT

rebuild() { (cd "$R" && cmake --build build -j4 > /tmp/_p_mut_build.log 2>&1) || { echo "BUILD FAILED"; tail -20 /tmp/_p_mut_build.log; return 1; }; }
runlit() { (cd "$R/build" && lit ir-pass/test --filter "$1" 2>&1 | grep -E "^ *(Passed|Failed) *:" | tr '\n' ' '); echo; }

echo "########## S-M1: drop the back-edge clause (successors of Pred) ##########"
restore
python3 - "$AC" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
old="""    const BasicBlock *B = Work.pop_back_val();
    if (scanRange(&B->front(), B == Pred ? Term : nullptr))
      return true;
    for (const BasicBlock *S : successors(B))
      push(S);"""
new="""    const BasicBlock *B = Work.pop_back_val();
    if (scanRange(&B->front(), B == Pred ? Term : nullptr))
      return true;
    if (B == Pred)
      continue;  /* S-M1 MUTATION */
    for (const BasicBlock *S : successors(B))
      push(S);"""
assert old in s, "S-M1 anchor not found"
open(p,"w").write(s.replace(old,new,1))
PY
rebuild && { echo -n "  inloop_latch_theta (expect Failed 1): "; runlit 'inloop_latch_theta'; \
             echo -n "  the 3 other new files (expect all Passed): "; runlit 'mergephi_cross_block|mergephi_inloop_outside_prep|two_leaves_cross_block'; }

echo "########## S-M2: the cross-block walk returns false immediately ##########"
restore
python3 - "$AC" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
old="""  const bool Cyclic = isPotentiallyReachable(Pred, DefBB);"""
new="""  return false;  /* S-M2 MUTATION */
  const bool Cyclic = isPotentiallyReachable(Pred, DefBB);"""
assert old in s, "S-M2 anchor not found"
open(p,"w").write(s.replace(old,new,1))
PY
rebuild && { echo -n "  cross_block_OFFWIRE_theta (expect Failed 1 -- single road): "; runlit 'cross_block_offwire_theta'; \
             echo -n "  cross_block_theta on-wire (expect PASSED -- doubly covered by the wire walk): "; runlit 'mergephi_cross_block_theta'; \
             echo -n "  inloop_latch_theta (expect Failed 1): "; runlit 'inloop_latch_theta'; }

echo "########## S-M3: neuter the PhaseKickback precedence edge ##########"
restore
python3 - "$SR" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
old="""    if (Regions[i].Kind != ControlRegion::PhaseKickback)
      continue;"""
new="""    if (Regions[i].Kind != ControlRegion::PhaseKickback)
      continue;
    continue;  /* S-M3 MUTATION */"""
assert old in s, "S-M3 anchor not found"
open(p,"w").write(s.replace(old,new,1))
PY
rebuild && { echo -n "  reject_mergephi_cross_block (expect Failed 1): "; runlit 'mergephi_cross_block$|reject_mergephi_cross_block.ll'; \
             echo -n "  mergephi_inloop_outside_prep (expect Failed 1): "; runlit 'mergephi_inloop_outside_prep'; \
             echo -n "  two_leaves_cross_block (expect PASSED -- the hcrg chain supplies its order): "; runlit 'two_leaves_cross_block'; }

echo "########## RESTORE + verify the subject binary is bit-identical ##########"
restore
rebuild && { H=$(shasum -a 256 "$R/build/ir-pass/cq-opt" | cut -d' ' -f1); \
  if [ "$H" = "$SUBJECT_HASH" ]; then echo "  RESTORED: cq-opt sha256 == the subject hash"; \
  else echo "  ⚠ RESTORED BINARY DIFFERS: $H (expected $SUBJECT_HASH)"; fi; }
