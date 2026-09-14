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

#include "llvm/ADT/DenseMap.h"  // collapseFlattenedLoopRails (count snapshot)
#include "llvm/ADT/SmallPtrSet.h"  // loopHasInPlaceRailStructure (set param)
#include "llvm/ADT/StringRef.h"  // LoopBreakRegion::RailWidth (by-value member)

namespace llvm {
class Module;
class Loop;
class BasicBlock;
class BinaryOperator;
class Instruction;  // bd wx8g: iterationLocalTaintEscape
class CallInst;
class Value;
class PHINode;
class DominatorTree;
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
// third round finds more. IT DID: see F-3 below, and note that BOTH of round 2's
// findings and round 3's were in premises the fence never stated). The fence is
// stated as "no rail-relabelling gate runs between the record's definition and the
// read", and the shipped code said narrower things:
//
//   F-1, THE GATE SET WAS THE CHAIN'S, NOT THE RAIL'S. `collectRailGates` read only
//   the peeled root→PreV→phi→LatV members, so a `cq_theta` whose arg-0 IS a member
//   but whose RESULT is off the chain — canonically a rotation applied to the
//   loop's EXIT value — was not a gate. `mark = q; q = cq_theta(q, .125);
//   cq_measure(mark)` emitted `cqrt_ry_i32(%h,.125); measure(%h)`, `opt` exit 0 and
//   stage-2b clean. Ry is ALWAYS lowered in place, so unlike a value op there is no
//   escape hatch. Each chain is now extended FORWARD through the users that keep
//   mutating the same handle: a rotation unconditionally, a dtzb `add`/`xor` only
//   when it is a member or already `taint.InPlaceRailOps` (which is what keeps
//   `mark = q; q = q+9; cq_measure(mark)` lowering — CORRECTLY, though NOT for the
//   reason first written here: round 3 measured that M-C does fire IN PLACE on such
//   an add when nothing reads the pre-add register, and it is M-C's own G6/G7 pair
//   refusing whenever a later read exists that makes the two dispositions mutually
//   exclusive; see `collectRailGates` and control_swap_inloop_postloop_railop_mc.ll),
//   and a phi naming the rail on SOME incoming. `clang -O1` C-reachable and
//   CONFIRMED.
//
//   F-2, THE CUT'S PREMISE. `railGateBetween` suppresses every path that
//   re-executes the record's definition, because re-executing it refreshes the
//   record. That holds for every in-place gate and for an ordinary rail phi, and
//   FAILS for a zero-hop identity carry `%rec = phi [%q0, entry], [%rec, latch]`,
//   which step (1) accepts trivially and which re-executes yielding the SAME value
//   while a sibling chain on the same mint moves the wire. A carry now refreshes
//   only if it crosses a rail GATE (`recordRefreshedByDef`).
//
//   F-3, THE RECORD SET WAS THE CHAIN'S TOO (bd 8h7d.5 Rule-13 ROUND 3 — F-1's
//   EXACT TWIN one hop out, and ANOTHER `clang -O1`-reachable CONFIRMED silent
//   miscompile). F-1 widened the GATE set from the chain to the rail and left the
//   RECORD loop — the values the fence asks "is any read of you stale?" —
//   enumerating chain members, so a rail value ONE HOP off the chain was never
//   asked about:
//
//       for (…) { if (q==5) q=cq_phi(q,PI); q=cq_theta(q,-.5); q=cq_theta(q,.5); }
//       int a = cq_theta(q, .125);   int b = cq_theta(a, .25);
//       return cq_measure(a) + cq_measure(b);
//
//   emitted `ry(%h,.125); ry(%h,.25); measure(%h); measure(%h)` — `a` names the
//   pre-`b` register and is measured after `b`. `opt` exit 0, verify-clean, STRICT
//   stage-2b clean. The record loop now runs over `collectRailGates`' `OnRailOut`,
//   the rail's own forward closure. THE SKIP SET STAYS THE CHAIN'S: widening both
//   was measured and turns lowering_reject_inloop_rail_frozen_gate_first.ll from a
//   decline into an accept, because a gate ON a frozen record is the very read that
//   proves it frozen. Two sets, two questions — "whose execution IS the wire
//   moving" (the chain) versus "which names denote a state of this rail" (the rail).
//
// The decline partition is otherwise unchanged and still LOUD: a latch incoming
// that does not peel back to the phi is the X1 cross-iteration dirty rail
// (`kMsgCrossIter`); a rail value with two forward in-place consumers is the
// Rule-8 fan-out (`kMsgRailFanout`); a rail record read past a gate on its own
// rail is `kMsgRailRecordStale`. A phi this round cannot classify either way is
// LEFT STANDING, and `declineClassicalMuxes` — which runs after it — declines it
// loudly. Nothing is silently accepted.
// CALLED TWICE, AND THE SECOND CALL IS NOT A BELT-AND-BRACES RE-RUN — bd 3qlq
// Inc 1, Rule-13 ROUND-2 finding F-R1-1 (a CONFIRMED rolled≠unrolled divergence).
// The stage above is the SECOND round of loop-rail analysis relative to
// `lowerLoops`, and for four increments it was also the LAST — it ran once, at
// `CQLoweringPass.cpp`'s slot right after `lowerControlRegions`. But
// `repropagateControlMerges` runs AFTER it and contains
// `detectAndLowerOnwardControl`, a full SECOND round of
// `detectControlRegions` + `lowerControlRegions` (issue yn71). A region whose
// condition reads a 6.5 classical-call-arm / 4.5 switch-data-mux `%out` rail is
// CLASSICAL at round 1 and tainted only at round 2, so an in-loop one is claimed
// and flattened by a stage that runs after the only caller of
// `invariantRegisterRoots`/`markIfRailLocal`. MEASURED: `for (i<3) if ((y>>i)&1)
// cq_phi(θ)` over an onward `%out` compiled at `opt` exit 0 with THREE
// `cq_template_and_i32_hl` mints and ZERO `_unc` discharges while the
// hand-unrolled twin discharged all three — one entangled which-path record
// leaked per activation, STRICT stage 2b `0 violation(s)` on both (the checker is
// structurally blind to a leaked TEMPLATE-minted rail, as its own header says).
// This is F-L3-1's shape one level up: a stage standing where a one-round
// pipeline put it, whose premise ("the marking stage will run after this
// flatten") is FALSE at round 2.
//
// `AlreadyProcessed` is the caller's snapshot of `taint.InLoopFlattenedPreds`
// taken BEFORE the round-2 fixpoint. Pass it (and only it) on the onward call:
// a loop opened by round 1 was already offered to this stage and is skipped, so
// the onward pass is exactly the DELTA and every pre-round-2 module is
// byte-identical. Pass nullptr (the default) on the round-1 call.
//
// ⚠ THE ONWARD CALL CAN ALSO DECLINE, and that is deliberate rather than a side
// effect: it runs the SAME `collapseRailPhisIn`, whose `Declined` outcomes (the
// X1 cross-iteration dirty rail, the Rule-8 rail fan-out, the stale rail-record
// read) are LOUD. A round-2-opened loop therefore gets exactly the treatment a
// round-1-opened one gets, including its refusals. No fixture in the 1666-file
// corpus changed disposition when this call was added (the red set is the same
// 396 files, file for file), so nothing shipped relies on such a loop having
// been silently unexamined.
//
// ⚠ WHAT THE DELTA DOES NOT DO, stated because it is the honest limit. A loop
// that round 1 processed is NOT re-examined under round-2 taint, so a marking
// GRANTED at round 1 stands even if a value that becomes tainted at round 2
// would have made `markIfRailLocal` refuse. Marking is additive and this stage
// never unmarks. That residual is bounded by construction — round 2 taints only
// `%out` rails and their derivations, an `%out` rail is itself an admitted Root
// (clause (ii-b)), and a DERIVED one is a template rail whose in-loop region
// round 2 would have to claim — see `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §2 for the
// probe and its measured disposition.
//
// TWO ROOT SOURCES PER LOOP, NOT ONE — bd 3qlq Inc 1, the Rule-13 CLEARANCE
// finding **C-1** (the BLOCK verdict). The dispatch used to be exclusive: a loop
// that `collapseRailPhisIn` CLAIMED was marked with the carried roots alone, and
// only a `NotClaimed` loop was offered to `invariantRegisterRoots`. A loop can be
// both — `for (i<K) { if ((q>>i)&1) cq_phi(θ); r = cq_theta(r,.1); }` carries `r`
// and reads the INVARIANT `q` — and that loop was served by neither: the carried
// branch handed `markIfRailLocal` a `Roots` not containing `q`, whose
// "accumulating loop-invariant tainted input" clause then refused, so the body's
// per-bit `and` rails leaked (3 mints / 0 `_unc` at 542d588, against 3/3 both
// hand-unrolled and on the pre-3qlq oracle — a rolled≠unrolled DIFFERENT UNITARY,
// `opt` exit 0 and STRICT stage-2b clean, exactly the F-L7-2 / F-R1-1 signature).
// So the `Collapsed` branch now ALSO asks `invariantRegisterRoots`, handing it the
// carried set as `CarriedRoots` and unioning its result only on success. The
// proof is UNCHANGED: a root mint (and a clause-(ii-b) control-owned out-rail)
// lowers to `cqrt_alloc_<W>` and fails `ChainWalk::isInteriorTerminalHandle`
// clause (I1), so no adjoint `At` can ever be placed for it in the K-times body —
// a property of the ROOT, not of whether some other register crosses the back
// edge, which is why the same argument carries here verbatim.
//
// ⚠ ROUND 2 OF THE SAME REVIEW MOVED BOTH HALVES OF THAT DISPATCH AGAIN (bd 3qlq
// Inc 1, the SECOND C-1 review round; findings F-C1-1 and F-C1-2). Read the two
// paragraphs above as the SHAPE and these as the two preconditions that still
// excluded the customer:
//   * F-C1-2(2a) — "the collapse already owns this candidate" was asked of the
//     LOCAL `Roots` this call had just filled, so it was false whenever the
//     collapse happened in the OTHER call (ROUND-1 `tryCaseA`, which is what
//     claims the carried rail when the in-loop region is an ONWARD one and the
//     loop's control is therefore classical at round 1). The fact now lives in
//     `taint.ClaimedRailRoots`, written at both collapse sites and read in UNION
//     with the local set.
//   * F-C1-2(2b) — `AlreadyProcessed` was a set of BLOCKS, and a round-2 region
//     flattens into the very `Pred` a round-1 region already used, so the loop
//     was never re-offered. It is a COUNT snapshot now, and "round 2 opened
//     something here" is the count having MOVED.
// `wd` is threaded in for F-C1-1: the peel must know whether a PREHEADER dtzb
// `add`/`xor` on the invariant register will be lowered IN PLACE, and that
// decision has exactly one owner — `ArithLowering::classifyInPlaceReassignment`
// (Rule 14, never a second spelling). See `invariantRegisterRoots`.
// bd `test_C_libtooling-s82e`, OWNER RULING **D4** (2026-09-14c) — THE NARROW
// DIVERGENT SUB-CASE OF THE UNMARKED-LOOP LEAK, AS A LOUD DECLINE.
//
// An unmarked loop body leaks its per-trip `cq_template_*` rails (the whole-DAG
// spine's in-loop guard skips them). That is USUALLY Rule 6's accepted leak — the
// leaked rail copies a register that is garbage in both forms. It is NOT a leak
// when the copied register is still LIVE after the loop and a NON-DIAGONAL gate
// lands on it there: the leaked copy dephases it, and rolled and unrolled become
// DIFFERENT UNITARIES (`CLAUDE.md` Rule 8) at `opt` exit 0, verify-clean, and
// STRICT stage 2b clean on both halves. Measured 10-vs-14 and 19-vs-25 trace lines
// against hand-unrolled twins; the rolled-vs-hand-unrolled trace pair is the ONLY
// instrument in the tree that sees the class.
//
// PURE ANALYSIS — declines or does nothing; mutates no IR and no `taint` set.
//
// CALL IT AFTER `declineRecordedStaleQuantumReaders` IN BOTH ENTRY POINTS. The
// slot is load-bearing twice over: it is after the round-2 fixpoint, so
// `taint.IterationLocalBlocks` is FINAL and the stage needs no record to re-ask
// (`CLAUDE.md` L1, answered by ORDER rather than by bookkeeping); and it is after
// the stale-reader backstop, so a module that already declines keeps its existing
// string (`LLVMContext::diagnose` EXITS on the first `DS_Error`, bd `br4a`).
//
// ⚠ THE DECLINE IS THE INTERIM; **bd `tu9q`** (P1) IS THE END STATE — it builds
// the discharge pairing so these programs COMPILE. Rule 17: the refused programs
// receive an INVALID circuit today, so refusing them is the Prime Directive and
// the 2026-09-11 over-decline ruling does not reach them. See the argued comment
// at the definition in `LoopLowering.cpp` for the full measurement, for why the
// stage asks the OUTCOME ("is this body unmarked?") rather than any one refusal
// CLAUSE, and for its retirement triggers.
void declineDephasingUnmarkedLoopRails(llvm::Module &M, TaintSet &taint);

void collapseFlattenedLoopRails(
    llvm::Module &M, WidthDispatch &wd, TaintSet &taint,
    const llvm::DenseMap<const llvm::BasicBlock *, unsigned> *AlreadyProcessed =
        nullptr);

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

// bd test_C_libtooling-drbq Increment 3 — the ROUND-2 RAIL COLLAPSE'S OWN CLAIM
// CONDITION on a header phi's EXTERNAL incoming, asked at DETECTION time.
//
// Returns the root mint (a classical-arg-0 `cq_theta` in `GateCalls` that
// dominates `L`'s header) that `collapseRailPhisIn` step (1) would collapse `P`
// to, or null when `P` is not a claimable rail phi. Defined in LoopLowering.cpp
// so it IS step (1)'s body rather than a second reader of it (Rule 14): the two
// callers are step (1) itself and `ArmClassify`'s R7-loop clause (b'), which
// must refuse — BEFORE the region is emitted and the diamond flattened —
// the shapes the collapse will not claim. See the definition's header for the
// row-DB motivation and for the single seam (each caller finds the external
// incoming itself, provably the same value under the single-latch gate both have
// already passed).
//
// ⚠ TWO CORRECTIONS THE ROUND-1 REVIEW MADE TO THAT SENTENCE, AND BOTH ARE
// PREMISES A WIDENER WOULD OTHERWISE INHERIT AS FACTS (bd drbq Inc 3, lens L5 Q4).
//
// (1) "A DIVERGENCE BETWEEN THE TWO CALLERS' ANSWERS IS IMPOSSIBLE BY
// CONSTRUCTION" IS FALSE AS WRITTEN. This shared body covers the
// EXTERNAL-INCOMING half only. `collapseRailPhisIn` step (1) additionally
// requires, before it calls in here, a `LatV`/`PreV` pair keyed on `IB == Latch`
// AND the CLOSED SELF-CYCLE `peelInPlaceBase(LatV, …) == &P`, whose failure is a
// `continue` or the LOUD `kMsgCrossIter` decline. So clause (b')'s contract —
// "that φ must be one the collapse will actually CLAIM" — is STRONGER than what
// this body proves. The honest claim is the weaker one: THE SHARED HALF CANNOT
// DIVERGE; THE UNSHARED LATCH HALF CAN, and when it does the failure is a loud,
// accurately-labelled, pre-existing loop message after emission rather than a
// mislabelled mux message (measured: lens L5 `q1_loop_joinphi.c` passes detection
// and declines at round 2 with `loop-carried tainted value crosses iterations`).
//
// (2) THE `GateCalls` VOCABULARIES ARE THE SAME RECIPE (θ ∪ φ from `taint`) BUT
// NOT THE SAME SET AT THE TWO CALL TIMES. `AngleSelectEmit` INSERTS the
// unconditional twin rotation it mints into `ThetaCalls`/`PhiCalls`, and it runs
// inside `lowerControlRegions` — AFTER `classifyArms`, BEFORE
// `collapseFlattenedLoopRails`. So round 2's vocabulary is a strict SUPERSET of
// detection's. THE DIRECTION IS SAFE, and here is the argument the code does not
// otherwise carry: `peelInPlaceBase` peels only while a call is IN `GateCalls`,
// so a SMALLER vocabulary stops the peel EARLIER, and an early stop lands on a
// value that then fails this function's `GateCalls.count(Mint)` test ⇒ null ⇒
// clause (b') DECLINES. Detection is conservative w.r.t. round 2 BY
// CONSTRUCTION, not by coincidence.
// RETIREMENT TRIGGER for (2): that argument inverts silently the moment
// detection's vocabulary becomes a superset of round 2's, or the peel's stop
// condition stops being monotone in `GateCalls`. Anyone doing either owes a
// re-derivation here.
llvm::CallInst *railPhiRootMint(
    const llvm::PHINode &P, const llvm::Loop *L,
    const llvm::SmallPtrSetImpl<llvm::CallInst *> &GateCalls,
    const TaintSet &taint, const llvm::DominatorTree &DT);

// bd `test_C_libtooling-wx8g` — `railPhiRootMint`'s CLEAN-RAIL-MINT TAIL, named
// so a second caller can ask it of a value that is NOT a header phi.
//
// Returns the `cq_theta`/`cq_phi` call in `GateCalls` that `V`'s IN-PLACE chain
// bottoms at when that bottom is a CLEAN RAIL MINT (a classical — i.e. untainted
// — arg-0, so its every execution lowers to a FRESH `cqrt_alloc_<W>`), or null
// for a derived out-of-place base (PRD §13.2 row DB). It asks NOTHING about
// position: `railPhiRootMint` adds `DT.dominates(Mint, L->getHeader())` (the
// rail is minted ONCE, before the loop) and `ArmClassify`'s R7-loop clause (c)
// adds `L->contains(Mint->getParent())` (the rail is minted FRESH EVERY TRIP) —
// the two halves of the same dichotomy, over one body.
//
// ONE BODY, THREE READERS (Rule 14 — never a second spelling of "what mints this
// rail?"): `collapseRailPhisIn` step (1) and clause (b') reach it through
// `railPhiRootMint`; clause (c) calls it directly. ⚠ It does NOT test the callee
// FAMILY — a register-free `cq_phi(double)` has an untainted arg-0 (the ANGLE)
// and therefore passes, which is the pre-existing behaviour of `railPhiRootMint`
// and is preserved BYTE-FOR-BYTE here. A caller that needs "this mint ALLOCATES"
// must say so itself; clause (c) does.
llvm::CallInst *railChainRootMint(
    llvm::Value *V,
    const llvm::SmallPtrSetImpl<llvm::CallInst *> &GateCalls,
    const TaintSet &taint);

// bd `test_C_libtooling-wx8g` — THE RE-ASK HALF of R7-loop clause (c). Contract
// and the full L1 argument live on `TaintSet::RolledLoopRegionGates`
// (TaintPropagation.h).
//
// For every region clause (c) let through, its loop's OWN blocks must have been
// marked ITERATION-LOCAL by `markIfRailLocal` — otherwise the whole-DAG spine
// will not place the body's per-trip `_unc`s and the rolled circuit is a
// different unitary from the hand-unrolled twin. That marking happens after the
// flatten, at FINAL taint, in `collapseFlattenedLoopRails`, and it can be
// refused (or never asked) for reasons detection cannot see. This re-asks the
// POSTCONDITION and declines LOUDLY; it never marks, never mutates, and is a
// no-op for a module with no recorded region.
//
// MUST run AFTER `repropagateControlMerges` (nothing else makes the marking
// final) and BEFORE `lowerRotations` (which erases the `@cq_theta` the record
// names), in BOTH entry points — the same slot, and for the same reason, as
// `reverifyRailCondReads`. ⚠ RETIREMENT TRIGGER: moving it above the fixpoint
// makes it read a marking that a round-2-opened loop has not been offered yet,
// which is an OVER-decline today and becomes an under-decline the moment the
// onward pass learns to unmark.
// bd `test_C_libtooling-wx8g` — R7-loop CLAUSE (c3), THE ESCAPE QUESTION, as a
// named body because it is asked TWICE over two different taint sets.
//
// Returns the first TAINTED instruction defined inside `L` that has a user
// outside `L` (or null when there is none). It is `markIfRailLocal`'s own
// "an iteration-local temp escaping the loop" clause asked with the EMPTY
// exemption set — that function skips values on a ROOT rail (`onRail`, keyed on
// a `Roots` that only exists after the flatten), so this is strictly stronger
// and can only OVER-decline. The monotonicity is the safety argument and it is
// one line: a larger `Roots` exempts strictly MORE values, so "nothing defined
// in `L` escapes" implies "no iteration-local temp escapes", for every `Roots`.
//
// TWO CALLERS, ONE BODY (Rule 14): `ArmClassify`'s clause (c3) at DETECTION with
// ROUND-1 taint, and `declineUnmarkedRolledIterLocal` again after the round-2
// fixpoint with FINAL taint — because `repropagateControlMerges` can TAINT a
// value that was classical when the classifier looked (CLAUDE.md's L1 PREDICATE
// species), and `markIfRailLocal`'s marking is ADDITIVE and never withdrawn, so
// a round-1 grant would otherwise stand over a round-2 escape.
//
// ⚠ IT IS A RETURN-FIRST WALKER AND THAT IS SOUND, BUT ONLY BECAUSE IT IS A PURE
// ∀ OVER AN EMPTY EXEMPTION SET (CLAUDE.md L4). L4's failure mode needs an
// EXEMPTION: a first-hit walker is defeated when an already-ACCEPTED item sits in
// front of an unaccepted one. Every tainted instruction defined in `L` owes the
// identical obligation here, there is no per-entry `WireRuled` bit, and both
// consumers read the answer as "∃ a violator" — clause (c3) as
// `… == nullptr`, the re-ask as a diagnostic ANCHOR and never as a set. So one
// witness is a complete answer.
// RETIREMENT TRIGGER, TWO WAYS, and round 1 of the review found the second one
// missing: (1) THE EXEMPTION SET — the moment any value is exempted (the obvious
// candidate is `markIfRailLocal`'s on-rail exemption) this must become a SET and
// a DIFFERENCE; (2) THE CLOSURE (CLAUDE.md L2, the half L4 does not carry) — the
// ∀ ranges over `L->blocks() × taint.Tainted`, so it must be re-derived if either
// moves: the subloop inclusion (`L->blocks()` deliberately includes strictly
// deeper blocks today) or the TAINT ROUND the caller asks it at. Widening a set
// without asking what OTHER set was computed over the same closure is the 8h7d.5
// F-1/F-3 shape verbatim.
llvm::Instruction *iterationLocalTaintEscape(const llvm::Loop *L,
                                             const TaintSet &taint);

void declineUnmarkedRolledIterLocal(llvm::Module &M, TaintSet &taint);

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
