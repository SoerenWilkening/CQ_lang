// LoopPlan.h — Phase 7.3 bounded-loop recognition + lowering (epic 799w).
//
// A classically-bounded loop (`for`/`while` with an UNTAINTED trip/exit
// condition) over a tainted body is NOT a tainted-control problem —
// `ControlDetect` keys strictly on condition taint, so the loop CFG (backedge,
// header phi) is invisible to it. 7.3 lowers such a loop ROLLED IN PLACE: the
// loop CFG is preserved and the body's tainted ops lower to the same
// `cqrt_*` / `cq_template_*` stream the straight-line form produces (owner
// decision 2026-06-24 — dynamic/runtime-classical bounds are in scope; NO
// compile-time trip count, NO unroll). See `docs/prd/phase-07-expressiveness/
// PRD-7.3.md`.
//
// `lowerLoops` interposes BESIDE `detectControlRegions` in `CQLoweringPass::run`,
// with three hard ordering constraints (PRD §2.3):
//   * BEFORE `detectControlRegions` — so a quantum/measurement-bounded loop (Q1)
//     is partitioned out with the dedicated `loop under quantum control`
//     diagnostic before `ControlDetect` declines it with the generic
//     `nested control flow…` message;
//   * BEFORE `declineClassicalMuxes` — so the recognized loop-carried header phi
//     is consumed by the Case-A collapse and never reaches `kMsgClassicalPhi`;
//   * BEFORE `lowerRotations` — like every control/QRAM/IO stage, it reads the
//     still-present `@cq_theta`/`@cq_phi` SSA values before the RAUW-to-handle.
//
// Recognition is PURE ANALYSIS by SSA/CFG identity, before any mutation (Rule 9):
// a freshly-built `DominatorTree DT(F); LoopInfo LI(DT)` reads header/latch/
// preheader/exit/header-phis, the same direct-construction idiom the FreePoint /
// Uncomputation backedge guards already use. The ONLY mutation is the Case-A
// header-phi collapse (RAUW phi→root + erase). Every off-pattern loop declines
// LOUDLY (Prime Directive: over-declining is safe; a silently-wrong loop unitary
// is the only unforgivable bug).

#ifndef CQ_IRPASS_LOOP_PLAN_H_
#define CQ_IRPASS_LOOP_PLAN_H_

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// Recognize + lower classically-bounded loops over tainted state (Phase 7.3,
// epic 799w). For each natural loop containing tainted values:
//   * (L1) a tainted EXITING condition ⇒ quantum/measurement-bounded loop —
//     LOUD decline `cq controlled lowering: loop under quantum control` (§2.6);
//   * (Case A, Inc 1 — 799w.1) every tainted value is an IN-PLACE persistent
//     rail (a loop-carried header phi whose latch-incoming peels through
//     in-place gates back to the phi itself, rooted at a `cq_theta` mint, and
//     measured/escaped after the loop) ⇒ collapse each rail phi (header +
//     zero-trip/exit) to its single persistent rail, so the body lowers to
//     `cqrt_rz(%h, angle_i)` over a loop-invariant handle (§2.4); the trace is
//     byte-identical to the manually-unrolled form;
//   * (X1) a tainted value carried across iterations on a DIRTY (non-in-place)
//     rail ⇒ LOUD decline `cq loop lowering: loop-carried tainted value crosses
//     iterations` (§2.7; the static-K unroll fallback is a deferred follow-on);
//   * (Case B, Inc 2 — 799w.2) an iteration-local born-and-dies temporary is
//     registered for the per-iteration in-body uncompute the Phase-5 spine then
//     places (§2.5).
// A loop with tainted control / tainted-index memory in its body is NOT claimed
// here — it keeps declining via the existing `ControlDetect`/`RegionTreeDetect`
// (L2) / `kMsgQramLoop` (L3) owners (§2.8). A purely-classical loop (no tainted
// values) is left byte-identical. Wired in BOTH pipeline entry points
// (twin-pipeline parity is mandatory, WI-1.12).
void lowerLoops(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_LOOP_PLAN_H_
