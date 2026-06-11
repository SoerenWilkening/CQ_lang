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
// Shadow/ShadowFalse) instead takes the method-B B-keep path (see
// emitValueRegion in the .cpp): per-arm |0> rails, the chain replayed VERBATIM
// + UNCONTROLLED on each rail via `rewriteBinary`, ONE `cqrt_copy_<W>`-out of
// the settled register, then per-arm reverse-play R† via `emitInverseChain`
// before the clean rail frees and the same flag strip.
//
// Runs AFTER `detectControlRegions` and BEFORE `lowerRotations` (§4): it
// references the still-present `@cq_theta` result `%q`; when `lowerRotations`
// later RAUWs `%q` to its `i32` alloc handle every emitter call updates
// automatically (the SSA-identity discipline, Rule 9). The only post-4.1 ABI
// addition is the `cqrt_copy_<W>` family (PRD Part II §8.1).

#ifndef CQ_IRPASS_SWAP_ROUTE_EMIT_H_
#define CQ_IRPASS_SWAP_ROUTE_EMIT_H_

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

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

}  // namespace cq

#endif  // CQ_IRPASS_SWAP_ROUTE_EMIT_H_
