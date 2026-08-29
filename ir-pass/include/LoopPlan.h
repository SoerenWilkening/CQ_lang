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

#include "llvm/ADT/SmallPtrSet.h"  // loopHasInPlaceRailStructure (set param)
#include "llvm/ADT/StringRef.h"  // LoopBreakRegion::RailWidth (by-value member)

namespace llvm {
class Module;
class Loop;
class BasicBlock;
class BinaryOperator;
class CallInst;
class Value;
class PHINode;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// Phase 7.4 (epic y05j) — the recognized single value-arm `break` loop, the
// fruit of the `tryBreak` recognizer (LoopLowering.cpp). Pure-analysis output:
// Increment 1 (y05j.1) only POPULATES this from the `-O1` fused-exit
// decomposition and uses it to drive the interim "emission not yet implemented"
// decline (proving the value-arm-vs-quantum-bounded partition); Increment 2
// (y05j.2) consumes it to emit the index-gated copy-not-move capture +
// whole-loop reverse-play (PRD-7.4 §2.2/§2.3). NO emission, NO ABI in Inc 1.
//
// All fields are SSA/CFG identities captured BEFORE any mutation (Rule 9). The
// `-O1` break fuses the tainted break flag and the classical loop bound into one
// `select(%brk, true, %bound)` / `or %brk, %bound` (and the successor-swapped
// continue-polarity `select(¬%brk, ¬%bound, false)` / `and`); `BreakFlag` is the
// single TAINTED disjunct, `BoundFlag` the CLASSICAL one — the load-bearing
// partition (a fused exit with BOTH operands tainted is a genuinely
// quantum-bounded loop and is NOT a LoopBreakRegion, PRD-7.4 §2.5 B1 / Risk 4).
struct LoopBreakRegion {
  llvm::Loop *L = nullptr;
  llvm::BasicBlock *Header = nullptr;
  llvm::BasicBlock *Latch = nullptr;
  llvm::BasicBlock *ExitMerge = nullptr;     // the single loop-exit block (B2)
  llvm::BasicBlock *ExitingBlock = nullptr;  // block whose tainted br fuses brk+bound
  llvm::Value *BreakFlag = nullptr;          // the tainted disjunct (%brk, an icmp/fcmp)
  llvm::Value *BoundFlag = nullptr;          // the classical disjunct (%bound)
  llvm::PHINode *EscapePhi = nullptr;        // value-class exit merge phi (the answer)
  bool ExitTakenOnTrue = false;              // polarity: exit successor is the br's true edge

  // ── Increment 2 (y05j.2) persisted record — the FORWARD-transform output the
  // post-lowering `lowerBreakReversePlay` stage consumes (PRD-7.4 §2.4 staging:
  // the reverse-play needs ALREADY-LOWERED `cqrt_*`/`cq_template_*` calls, so it
  // runs AFTER `lowerOps`; `tryBreak`/`emitBreakForward` runs PRE-lowering). All
  // fields below are pointers that SURVIVE rotation/opcode lowering (the rail
  // mint + break-cond are RE-DERIVED post-lowering by a structural scan of the
  // proven single-block body — `Loop *L`, `BreakFlag`, `EscapePhi` are STALE
  // post-lowering and must NOT be read by the reverse-play stage):
  llvm::PHINode *CounterPhi = nullptr;       // the classical induction phi (untainted — survives)
  llvm::Value *BoundLimit = nullptr;         // the loop-invariant trip limit `n` (bound's invariant operand)
  llvm::Value *RReg = nullptr;               // the |0> capture register `R` (cqrt_alloc result)
  llvm::Value *IdxReg = nullptr;             // the |0> first-break index `idx` (cqrt_alloc result)
  llvm::Value *OutReg = nullptr;             // the |0> escaping answer `out` (cqrt_alloc result; RAUW'd into the measure)
  llvm::StringRef RailWidth;                 // the rail's ABI width (`i8`/`i16`/`i32`/`i64`) for copy/alloc symbol selection
  llvm::StringRef IdxWidth;                   // the counter's ABI width — the `idx` register width (PRD §2.8)
  // The forward loop's zero-trip ENTRY guard (the rail phi's external predecessor's
  // conditional branch). The reverse-play companion loop reuses it VERBATIM so the
  // backward loop enters iff the forward did — for ANY bound signedness (a re-
  // invented signed `sgt(n,0)` guard would skip the reverse-play for an unsigned
  // `n ≥ 2^31`, leaving R/idx dirty at `cqrt_free`; the Rule-13 FINAL review).
  llvm::Value *GuardCond = nullptr;          // the guard condition (loop-invariant, dominates the exit)
  bool GuardLoopOnTrue = false;              // the loop (Header) is the guard branch's TRUE successor
};

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

// bd test_C_libtooling-8h7d.5 (Phase 7.3 Increment 3) — ROUND 2 of the bounded-
// loop pass, run AFTER `lowerControlRegions` has emitted and FLATTENED the
// tainted-control regions that `ControlDetect::flatRegionRollableInLoop`
// admitted inside a loop body.
//
// WHY A SECOND ROUND EXISTS AT ALL. `lowerLoops` (round 1) deliberately leaves a
// loop with in-body tainted control UNCLAIMED (`tryCaseA` gate L2) — it cannot
// see past the diamond: the header phi's latch incoming peels only as far as the
// region's MERGE phi, which `peelInPlaceBase` does not cross, so the persistent
// rail reads as a cross-iteration dirty rail (X1) and the whole loop would
// loud-decline a shape that is in fact clean. After the flatten the merge phis
// are GONE (RAUW'd to the routed base) and the body is straight-line, so the
// very same peel now resolves — which is why the analysis is re-asked here and
// not made cleverer up front (Rule 9: analyse the IR in front of you).
//
// SCOPE, and why it is NOT a second `tryCaseA`. This round makes ONE claim: the
// loop-carried tainted header phi denotes ONE PERSISTENT QUBIT RAIL, so it
// collapses to its root mint. It does not re-prove `tryCaseA`'s COVERAGE ("every
// tainted body value is on the rail") — that is a CLAIM condition, about whether
// round 1 may own a loop, and the post-flatten body legitimately contains values
// on no rail at all: the region's own emitted stream (flag mint, `cqrt_cswap`
// route, `_unc` strip) and a derived condition's iteration-local template rails.
// Their disposition belongs to the owners that already have it — the Phase-5
// uncompute spine and `FreePoint`, whose back-edge live-range reject is untouched.
//
// IT DOES RE-PROVE THE OTHER HALF, AND THE FIRST VERSION OF THIS ROUND DID NOT.
// `tryCaseA`'s CLOSURE was carrying TWO obligations under one name. The second
// one is a UNITARY condition, not a claim condition: a rail record may only be
// READ at a position where the register still holds it. The collapse RAUWs every
// member onto one handle, so a consumer reads whatever the wire holds at ITS
// position while the SSA name denotes a fixed prefix of the rail's gates —
// and inside a loop those diverge the moment any gate separates them.
//
//     for (…) { if (q == 5) q = cq_phi(q, PI); acc = q * 7; q += 3; }
//     return cq_measure(q) + cq_measure(acc);
//
// `clang -O1` sinks the `mul` past the loop, so the emitted template runs against
// the POST-loop register and computes `(q0+3k)*7` where the source says
// `(q0+3(k-1))*7`. `opt` exit 0, `opt -verify` clean, STRICT stage-2b clean; the
// shape is perfect and only the state is wrong (bd 8h7d.5 Rule-13 round 1,
// finding F1). Round 1 declines that program; round 2 collapsed it. The fence is
// `staleRailRecordRead` (LoopLowering.cpp), asked by BOTH rounds — which also
// closed round 1's own older half of the hole, where CLOSURE admitted a
// `cq_measure`/`ret` of a rail value at ANY position.
//
// TWO PREMISES OF THAT FENCE WERE THEMSELVES WRONG (bd 8h7d.5 Rule-13 ROUND 2,
// findings F-1 and F-2 — six findings over two rounds on one increment; assume a
// third round finds more). The fence is stated as "no rail-relabelling gate runs
// between the record's definition and the read", and the shipped code said two
// narrower things:
//
//   F-1, THE GATE SET WAS THE CHAIN'S, NOT THE RAIL'S. `collectRailGates` read only
//   the peeled root→PreV→phi→LatV members, so a `cq_theta` whose arg-0 IS a member
//   but whose RESULT is off the chain — canonically a rotation applied to the
//   loop's EXIT value — was not a gate. `mark = q; q = cq_theta(q, .125);
//   cq_measure(mark)` emitted `cqrt_ry_i32(%h,.125); measure(%h)`, `opt` exit 0 and
//   stage-2b clean. Ry is ALWAYS lowered in place, so unlike a value op there is no
//   escape hatch. Each chain is now extended FORWARD through the users that keep
//   mutating the same handle: a rotation unconditionally, a dtzb `add`/`xor` only
//   when it is a member or already `taint.InPlaceRailOps` (an off-chain one lowers
//   OUT of place into a FRESH rail — which is why `mark = q; q = q+9;
//   cq_measure(mark)` is CORRECT and keeps lowering), and a phi naming the rail on
//   SOME incoming. `clang -O1` C-reachable and CONFIRMED.
//
//   F-2, THE CUT'S PREMISE. `railGateBetween` suppresses every path that
//   re-executes the record's definition, because re-executing it refreshes the
//   record. That holds for every in-place gate and for an ordinary rail phi, and
//   FAILS for a zero-hop identity carry `%rec = phi [%q0, entry], [%rec, latch]`,
//   which step (1) accepts trivially and which re-executes yielding the SAME value
//   while a sibling chain on the same mint moves the wire. A carry now refreshes
//   only if it crosses a rail GATE (`recordRefreshedByDef`).
//
// The decline partition is otherwise unchanged and still LOUD: a latch incoming
// that does not peel back to the phi is the X1 cross-iteration dirty rail
// (`kMsgCrossIter`); a rail value with two forward in-place consumers is the
// Rule-8 fan-out (`kMsgRailFanout`); a rail record read past a gate on its own
// rail is `kMsgRailRecordStale`. A phi this round cannot classify either way is
// LEFT STANDING, and `declineClassicalMuxes` — which runs after it — declines it
// loudly. Nothing is silently accepted.
void collapseFlattenedLoopRails(llvm::Module &M, TaintSet &taint);

// Issue dtzb — is `BO` a recognized IN-PLACE value rail self-update (`q = q OP
// c`, OP in {add, xor}, EXACTLY ONE tainted operand, integer width <= 64, the
// widths the frozen `cqrt_{addc,xorc}_<W>` grid serves)? Returns the tainted
// rail operand, or null. Defined in LoopLowering.cpp beside the loop claim it
// was written for; exported since bd test_C_libtooling-6uqc Inc 2a so
// `ArithLowering`'s M-C straight-line fence asks the SAME predicate rather than
// re-spelling its exclusion partition (Rule 14 — `mul`/`and`/`or`/shifts are
// information-losing, a two-quantum `acc + q` has no classical immediate, and
// `fadd` is a different opcode; a second spelling of that list is a second thing
// to keep in sync). See the .cpp for the full over-accept partition.
llvm::Value *inPlaceValueRailOperand(llvm::BinaryOperator *BO,
                                     const TaintSet &taint);

// Shared 799w/dtzb rail-structure predicate for the Lever-B force-unroll
// pre-pass (LoopUnrollPrepass.cpp, ticket lf8s — fence U4). True iff `L`
// carries IN-PLACE rail structure the rolled-in-place owner's vocabulary
// recognizes: (a) a tainted in-place-shaped `add`/`xor` self-update
// (`inPlaceValueRailOperand` — the dtzb bijection family) anywhere in `L`'s
// blocks, or (b) a tainted header phi whose latch incoming peels through
// in-place gates back to the phi itself (`peelInPlaceBase` — the Case-A claim
// seed, including the zero-hop identity carry). Defined in LoopLowering.cpp so
// it CALLS the same predicates `tryCaseA` claims with — the disjointness gate
// is the shared code path, not a re-implementation that could drift (Rule 14).
// Conservative: an unproven shape (no single latch) reports true (the caller
// skips; over-skipping is the safe direction). `GateCalls` is the collected
// theta+phi vocabulary, the same seed `lowerLoops` builds.
bool loopHasInPlaceRailStructure(
    llvm::Loop *L, const TaintSet &taint,
    const llvm::SmallPtrSetImpl<llvm::CallInst *> &GateCalls);

// Phase 7.4 Increment 2 (epic y05j) — the POST-LOWERING reverse-play stage.
// Wired AFTER `lowerOps`/`lowerRotations` in BOTH pipeline entry points (PRD-7.4
// §2.4): for each `LoopBreakRegion` the forward transform (`tryBreak`) recorded
// in `taint.BreakRegions`, emit — on the now-LOWERED `cqrt_*`/`cq_template_*`
// body (i32 handles throughout) — (a) the index-gated copy-not-move capture +
// in-iteration scratch uncompute INTO the forward body, (b) the loop-exit
// consolidation + the `cqrt_copy_<W>` copy-out into `out`, and (c) the
// backward-counted reverse-play companion loop (the whole-loop adjoint that
// returns `R`/`idx`/rail to their pre-capture state), then the `cqrt_free` of
// `R`/`idx`. The break-owned handles are inserted into `taint.ControlOwnedRails`
// so the whole-DAG `uncompute` spine never double-reverses them. No-op when
// `taint.BreakRegions` is empty (every module with no recognized value-arm break).
void lowerBreakReversePlay(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_LOOP_PLAN_H_
