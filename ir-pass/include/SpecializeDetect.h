// SpecializeDetect.h — the pure-analysis specialization pre-pass (C-Plan).
//
// Mirrors `ControlDetect`: pure analysis by SSA/pointer identity, NO IR
// mutation, runs BEFORE `declineTaintEscapes` in both pipeline entry points.
// Walks `M` for tainted-arg DIRECT `CallInst` sites, computes the LSB=param0
// taint mask, and runs the single authoritative `classifyCandidate`:
//   * Accept  → the site enters `SpecPlan.Pending` (membership ⇔ proven
//     specializable — the only thing the `:419` carve-out's `shouldSpecialize`
//     consults).
//   * a CLASSIFIED reject (cq_*, measure, in-body control, recursion, fp/i128,
//     arity) → LOUD `diagnoseReject` HERE (source-located on the offending
//     instruction) + the site is recorded in `SpecPlan.Diagnosed` so the
//     carve-out suppresses its generic `kMsgUnknownCallee` (exactly one message).
//   * a SHAPE reject (invoke/callbr → not a `CallInst`; indirect → null callee;
//     declaration-only → no IR) → SILENT here; the site is neither in `Pending`
//     nor `Diagnosed`, so the carve-out fires `kMsgUnknownCallee` (DD-2 no-IR
//     contract; keeps `_opaque_call`/`_deep_arg`/`_indirect_call` green).
//
// bd 9paa (round-2 spec DETECTION): the SAME walk is RE-RUN from
// `repropagateControlMerges` on the second-propagation taint (the DETECTION twin
// of `replanReseedSpecialization`), so a wholly-new candidate `g(%out)` whose args
// were ALL classical at round 1 (never in the plan) is detected and cloned by the
// step-262 driver. A NON-null `reseed` selects round-2 mode: only a site whose
// newly-tainted arg is a reseed value, and not already Pending/Diagnosed, is
// considered. `reseed == nullptr` (the round-1 call sites) is byte-unchanged.

#ifndef CQ_IRPASS_SPECIALIZE_DETECT_H_
#define CQ_IRPASS_SPECIALIZE_DETECT_H_

#include "llvm/ADT/SmallPtrSet.h"

namespace llvm {
class Module;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;
struct SpecPlan;

// `reseed` (bd 9paa): non-null ⇒ round-2 re-detection restricted to sites reading
// a reseed value (the control-merge `%out` or a `%out` derivation) and not already
// Pending/Diagnosed. Null (default) ⇒ round-1 detection over every tainted-arg
// candidate, unchanged.
void detectSpecializations(llvm::Module &M, const TaintSet &taint,
                           WidthDispatch &wd, SpecPlan &out,
                           const llvm::SmallPtrSetImpl<llvm::Value *> *reseed =
                               nullptr);

// bd `test_C_libtooling-vsfp` (P1) / bd `test_C_libtooling-hgwx` — THE DEAD
// CALL-ARGUMENT DROP, a normaliser asked at TWO slots in both entry points, both
// before any stage reads an argument (slot A first; slot B right after the fenv
// volatile stages — the slot arguments are at the call sites in
// `CQLoweringPass.cpp`).
//
// For every DIRECT `CallInst` (never a front-end intrinsic site, by membership)
// to an eligible callee, every eligible argument whose callee PARAMETER IS DEAD
// under the pass's ONE liveness predicate (`DeadValueLiveness.h`,
// `deadParamMask`: mark-from-roots, NOT `use_empty()`) is replaced by
// `Constant::getNullValue`, and the operands' dead cones are deleted with the
// SAME predicate (`deleteDeadCones`). Iterated to a fixpoint, so a parameter that
// is only FORWARDED to a dead parameter of an inner callee dies too. Returns true
// iff anything changed; the caller must then re-`propagate`.
//
// WHY: a Phase-6 clone is built from its callee's body, so a parameter dead
// there is a parameter the clone never reads — yet the call kept READING the
// operand (bd hgwx's root cause), which kept a which-path rail the hand-inlined
// twin never computes alive and entangled across a later non-diagonal gate (bd
// vsfp: exit 0, no warning, stage 2b clean). Doing it before
// `detectSpecializations` computes a mask and before any control emitter mints a
// rail for the operand is the timing argument: after emission a dropped operand
// would leave an orphaned, entangled rail.
//
// ⚠ ROUND 1 ASKED `use_empty()` AND LOST THE WAY CLAUDE.md L5 PREDICTS (Rule-13
// r1A/r1B on 5e56060b, both NOT-CLEAR): a dead `trunc` left by the fenv store
// erasure is a use (bd a8q5), a dead `llvm.smax`/`abs`/`ctpop` is a call the
// round-1 cone walk refused to delete (bd m1gi), a dead loop-carried φ cycle has
// no `use_empty()` member (r1A F-VA-3), and an emptied arm left an empty diamond
// on a quantum condition (r1A F-VA-4). The liveness predicate answers all four;
// `deleteDeadCones` folds the emptied arm.
//
// IT IS LLVM's DEAD-ARGUMENT ELIMINATION, WITH DAE's PRECONDITIONS, APPLIED
// ACROSS TUs. `clang -O1` does this WITHIN one TU; the caller TU of a 2-TU
// program sees only `int h(int a, int k);`, and the pass is the first to see
// both. ⚠ Round 1 said "LLVM's own transform" while copying ONE of DAE's
// preconditions: a `naked` callee (its asm reads the argument REGISTERS) had its
// argument rewritten, a classical miscompile at exit 0 (bd ctz4, r1A F-VA-1).
// The preconditions now mirrored, each at its definition in SpecializeDetect.cpp:
// exact definition, not `naked`, not variadic and not a `musttail` site (both
// STRICTER than DAE's call-site rewrite — conservatism, pinned), the call's
// function type equal to the callee's (DAE's own rule), and a
// parameter carrying none of `returned`/`swifterror`/`byval`/`inalloca`/
// `preallocated`, with every attribute in the whitelist
// `noundef`/`signext`/`zeroext`/`inreg`/`range`/`nofpclass` (the last two
// STRIPPED, as DAE strips its UB-implying set). The replacement is a NULL
// CONSTANT, not DAE's `poison`: a `noundef` parameter makes poison immediate UB
// unless the callee's attribute is stripped too, and a clone call inside a clone
// is duplicated verbatim into its `_unc` twin, where an `undef`/`poison` literal is
// bd xy9n's two-reads-two-values hazard — `0` is one value in every slot. Scope,
// not soundness: pointer/vector/aggregate arguments are never rewritten.
//
// ⚠ PURELY STRUCTURAL AND TAINT-AGNOSTIC, deliberately: the operand of a
// ROUND-2 candidate (`g(%out)`, bd 9paa) is CLASSICAL at every slot before
// emission, so a taint-keyed drop would miss exactly the 6.5 `%out` member
// (r2A `s3d`). It never deletes a ROOT — so never a user's `cq_theta`/`cq_measure`
// (membership, and the reserved-name rule) and never a call that may have side
// effects. A dead call that is side-effect-free — by LLVM's attributes (a pure
// intrinsic, a `memory(none)` `willreturn` `nounwind` definition) or by its BODY
// (`DeadValueLiveness.h`'s body rule: acyclic, call-free, write-free) — IS
// deleted, as `-O1` deletes it once it can see the body.
//
// The observing half is `resolvePhantomCloneArgReads` (Specialization.h): after
// `specialize()` it reads the SAME predicate's record of the BUILT clones
// (`taint.SpecDeadArgMask`), neutralises every slot the clone never reads, and
// declines a quantum operand the user program then no longer reads.
bool dropDeadCallArguments(llvm::Module &M, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_DETECT_H_
