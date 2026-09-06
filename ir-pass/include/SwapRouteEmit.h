// SwapRouteEmit.h — The RSSA swap-route emitter for tainted-condition control
// regions (swap-route 4.1 IMPLEMENTATION §4/§5 — PHASE arms; 4.2
// IMPLEMENTATION-4.2 §4/§5d/§5e — VALUE arms, method-B). This is the mutating
// step that replaces `ControlStub`'s loud-decline-only behavior for the narrow
// cases `detectControlRegions` (ControlDetect) accepts: a tainted-condition
// diamond (one content arm) or if/else (two arms) whose every arm is a pure
// phase chain (`@cq_phi`/Rz only, §5a/§5b) — or a pure linear value chain
// (supported tainted integer BinaryOperators, §5d/§5e) — over ONE tainted
// quantum handle.
//
// Per accepted region the emitter lowers `if (cond) { rz(q,·)… }` (or
// `… else { rz(q,·)… }`) to the coherent, ZERO-controlled-gate routed stream
// (SCOPING §3a), emitted into the pred block BEFORE the conditional `br`. A
// diamond routes its single content arm; an if/else routes BOTH arms to distinct
// |0> rails — the true arm under flag, the else arm under ¬flag via a
// self-inverse `cqrt_x(flag)` bracket. The exact order (the §5 contract):
//   1. flag mint            cq_template_icmp_<pred>_<W>_hl(q, lit)   (CompareLowering)
//   2. |0> work rail        cqrt_alloc_<W>(0)                        (WidthDispatch)
//   3. route-in             [cqrt_x(flag);] cqrt_cswap(flag,q,rail) [;cqrt_x(flag)]
//   4. arm body VERBATIM    cqrt_rz_<W>(rail, angle)  per arm cq_phi (uncontrolled)
//   5. route-back           the SAME cswap (+bracket) — adjoint of the split
//   6. rail free            cqrt_free(rail)   — the rail is |0> for free (Rz|0>=|0>)
//   7. flag strip           cq_template_icmp_<pred>_<W>_hl_inv(q, lit)  (q==q0)
//   8. flag free            cqrt_free(flag)
//   9. RAUW merge phi → q; erase merge phi / arm cq_phi / dead icmp; SCRUB each
//      erased instruction from taint.Tainted / taint.PhiCalls (§6.1 — else a
//      later `lowerRotations`/`uncompute` dereferences freed memory); then
//      `RegionFlatten` splices the merge into the pred and deletes the now-dead
//      arm/merge blocks.
//
// The route-in/route-back X-bracket fires only for an `ArmNegated` (¬flag /
// FALSE-successor) arm — `clang -O1` makes the gate arm the false successor for
// `if (u != k)`-style conditions (Rule 9); detection resolves the arm by
// merge-phi incoming identity (ControlDetect) and records the polarity in
// `ControlRegion::ArmNegated`.
//
// A VALUE-class region (ClassArm/ClassArmFalse == Value, the ordered chain in
// Shadow/ShadowFalse) takes the CONTROLLED-COPY MERGE (bd
// test_C_libtooling-3qlq Inc 2, retire-swap-route-PRD §7; see emitValueRegion in
// the .cpp). ⚠ IT NO LONGER ROUTES. The pre-3qlq method-B B-keep path — per-arm
// |0> work rails, the chain replayed VERBATIM + UNCONTROLLED on each rail via
// `rewriteBinary`, ONE `cqrt_copy_<W>`-out of the settled register, then per-arm
// reverse-play R† via `emitInverseChain` before the clean rail frees — is
// RETIRED. `emitValueRegion` is now a REWRITE: it HOISTS each arm's proven pure
// linear chain into the pred (where `lowerOps` lowers it and the whole-DAG spine
// reverses it, exactly as for any straight-line tainted arithmetic), builds a
// `select` for the merge, flattens, and hands the result to the 4.4
// `emitSelectRegion` — two `cqrt_copy_<W>_controlled` into a fresh |0> rail, the
// same flag strip, ONE `cqrt_free`. No work rail, no `cqrt_cswap`, no
// reverse-play, and no new runtime symbol. The X-bracket note above therefore
// applies to the PHASE paths and to the merge's second controlled copy; a value
// arm's polarity now rides the `select`'s operand SLOT, not a bracket count.
//
// Runs AFTER `detectControlRegions` and BEFORE `lowerRotations` (§4): it
// references the still-present `@cq_theta` result `%q`; when `lowerRotations`
// later RAUWs `%q` to its `i32` alloc handle every emitter call updates
// automatically (the SSA-identity discipline, Rule 9). The only post-4.1 ABI
// addition is the `cqrt_copy_<W>` family (PRD Part II §8.1) — still emitted, by
// the 4.5 switch-value PRELOAD (SwitchValueEmit) though no longer by the
// retired diamond copy-out.

#ifndef CQ_IRPASS_SWAP_ROUTE_EMIT_H_
#define CQ_IRPASS_SWAP_ROUTE_EMIT_H_

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"

namespace llvm {
class BasicBlock;
class CallInst;
class DebugLoc;
class Module;
class Value;
}  // namespace llvm

namespace cq {

class ControlledSymbols;
class WidthDispatch;
struct TaintSet;
struct ControlPlan;

// Emit the swap-route stream for every region in `plan.Regions` (each a §0
// accepted phase- or value-arm diamond / if-else, populated by
// `detectControlRegions`). Mutates the
// module IR and `taint` (scrubs every erased instruction). A plan with no
// regions is a no-op, so a classical-only / fully-declined module is untouched.
void lowerControlRegions(llvm::Module &M, WidthDispatch &wd, TaintSet &taint,
                         const ControlPlan &plan);

// Reused routing primitives (de-anonymized from the .cpp's anonymous namespace,
// WI-3/MD1-style, so the 4.3 `NestedRouteEmit` TU shares ONE definition per
// Rule 14). `collectArmPhis` returns an arm block's IN-BLOCK `@cq_phi` (Rz) gates
// in FORWARD program order, bounded at the arm-block boundary (a pre-region phi
// is the live derived base, not an arm gate — the load-bearing bound, Rule 10).
// `emitRoute` emits `cqrt_cswap(flag, q, rail)`, X-bracketed for a ¬flag
// (`Negated`/FALSE-successor) arm; the route-in and route-back are the SAME call
// (the RSSA join-is-the-inverse-of-the-split symmetry). It RETURNS that cswap so
// a caller whose route-back is the literal adjoint of its route-in can collect
// the pair into a `TaintSet::RestoringRoute` group (M-B Increment 6 clause (d2)).
// The X brackets are on the FLAG, never on the routed base, so they are not part
// of the group.
llvm::SmallVector<llvm::CallInst *, 4> collectArmPhis(
    llvm::Value *ArmIncoming, const llvm::BasicBlock *ArmBB);
llvm::CallInst *emitRoute(llvm::IRBuilder<> &B, const ControlledSymbols &csyms,
                          llvm::Value *Flag, llvm::Value *Q, llvm::Value *Rail,
                          bool Negated, const llvm::DebugLoc &DL);

}  // namespace cq

#endif  // CQ_IRPASS_SWAP_ROUTE_EMIT_H_
