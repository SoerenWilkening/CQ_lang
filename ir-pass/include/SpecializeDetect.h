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
// CALL-ARGUMENT DROP, a normaliser that runs ONCE, before any stage reads the
// argument, in both entry points (the slot argument is at the call site in
// `CQLoweringPass.cpp`).
//
// For every DIRECT `CallInst` to an EXACT, non-vararg definition, every
// integer/floating-point argument whose callee PARAMETER HAS NO USES is replaced
// by `Constant::getNullValue`, and the operand's now-unused cone is deleted
// (non-call, trivially-dead instructions only). Iterated to a fixpoint, so a
// parameter that is only FORWARDED to a dead parameter of an inner callee dies
// too. Returns true iff anything changed; the caller must then re-`propagate`
// (the call result's conservative taint came from the dropped operand).
//
// WHY: a Phase-6 clone is built from its callee's body, so a parameter with no
// uses there is a parameter the clone never reads — yet the call kept READING
// the operand (bd hgwx's root cause), which kept a which-path rail the
// hand-inlined twin never computes alive and entangled across a later
// non-diagonal gate (bd vsfp: exit 0, no warning, stage 2b clean). The twin is
// the definition of the right circuit, and this is what `clang -O1` does to the
// twin: the dead operand is never computed. Doing it HERE — before
// `detectSpecializations` computes a mask and before any control emitter mints a
// rail for the operand — is the timing argument: after emission a dropped
// operand would leave an orphaned, entangled rail.
//
// IT IS LLVM'S OWN TRANSFORM, APPLIED ACROSS TUs. `clang -O1`'s dead-argument
// elimination already does this WITHIN one TU (`RemoveDeadArgumentsFromCallers`,
// for an exact definition). What it cannot do is look through the TU boundary:
// the caller TU of a 2-TU program sees only `int h(int a, int k);`, and the pass
// is the first to see both. The replacement is a NULL CONSTANT, not DAE's
// `poison`, for two reasons of this pass's own: a `noundef` parameter (clang puts
// one on every scalar parameter) makes a poison argument immediate UB unless the
// attribute is also stripped from the callee, which this stage never touches; and
// a clone call inside a clone is duplicated verbatim into its `_unc` twin, where an
// `undef`/`poison` literal is the bd xy9n two-reads-two-values hazard — `0` is one
// value in every slot. The cone deletion is `RecursivelyDeleteTriviallyDeadInstructions`'
// walk minus calls.
//
// ⚠ PURELY STRUCTURAL AND TAINT-AGNOSTIC, deliberately: the operand of a
// ROUND-2 candidate (`g(%out)`, bd 9paa) is CLASSICAL at every slot before
// emission, so a taint-keyed drop would miss exactly the 6.5 `%out` member
// (r2A `s3d`). What it will NOT do: touch a pointer/vector/aggregate argument,
// a constant operand, a callee that may be interposed (`!hasExactDefinition()`),
// a parameter or call-site argument carrying any attribute other than
// `noundef`/`signext`/`zeroext`/`inreg` (a null constant could violate
// `range`/`nofpclass`), or DELETE A CALL (a dead `cq_theta` is the user's gate,
// never this stage's to erase — CLAUDE.md §4i).
//
// The TOTAL half is `declinePhantomCloneArgReads` (Specialization.h): it OBSERVES,
// after `specialize()`, any clone call that still passes a quantum operand to a
// parameter the clone never reads — i.e. whatever this predictor missed.
bool dropDeadCallArguments(llvm::Module &M, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_DETECT_H_
