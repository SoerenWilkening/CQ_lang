// LoopLowering.cpp — Phase 7.3 bounded-loop recognition + lowering (epic 799w).
// See LoopPlan.h for the contract and the ordering constraints.
//
// Increment 1 (799w.1) — Case A "in-place persistent accumulator". A
// classically-bounded loop whose every tainted value is a persistent rail
// threaded through a loop-carried header phi, mutated only by IN-PLACE gates
// (`cq_phi`=Rz / chained `cq_theta`=Ry on a tainted operand), lowers ROLLED IN
// PLACE: the loop CFG is preserved and the rail phi(s) — the loop-carried header
// phi AND the zero-trip/exit merge phi the `-O1` guard emits — collapse to the
// single persistent rail, so the body lowers to `cqrt_rz(%h, angle_i)` over a
// loop-invariant handle. The trace is byte-identical to the manually-unrolled
// form. No in-body free, no uncompute (the rail is measured/escaped after L).
//
// Also: the Q1 (quantum/measurement-bounded exit) and X1 (cross-iteration dirty
// rail) LOUD declines. Every other off-pattern loop is LEFT for its existing
// owner (`ControlDetect`/`RegionTreeDetect` for tainted control in the body,
// `kMsgQramLoop` for tainted-index memory, `declineClassicalMuxes`/`FreePoint`
// for an unrecognized live range) — `lowerLoops` claims a loop ONLY when it can
// PROVE the §2.2 sound-rolled invariant (Prime Directive: over-declining /
// not-claiming is safe).

#include "LoopPlan.h"

#include "TaintPropagation.h"
#include "ControlPlan.h"  // diagnoseUnderControl (Q1 reuses the control dialect)
#include "OpcodeSupport.h"  // abiWidthFromType (rail width for the capture allocs)
#include "WidthDispatch.h"
#include "FreePoint.h"      // blockCanRepeat (the ONE "can this block run twice")

#include "llvm/IR/IRBuilder.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/TargetParser/Triple.h"

#include <optional>
#include <utility>

using namespace llvm;

namespace cq {

namespace {

// The exact diagnostic string the cross-iteration-dirty-rail decline owns
// (PRD-7.3 §2.7). The negative fixture mirrors it CHARACTER-FOR-CHARACTER
// (Rule 12): lowering_reject_loop_cross_iter.ll → kMsgCrossIter. The
// quantum-bounded-loop (Q1) decline reuses the control dialect via
// `diagnoseUnderControl(_, "loop")` → "cq controlled lowering: loop under
// quantum control" (lowering_reject_loop_quantum_bound.ll).
constexpr char kMsgCrossIter[] =
    "cq loop lowering: loop-carried tainted value crosses iterations";

// The fan-out / linear-lineage decline (Rule 8 no-cloning; the Rule-13 review
// 2026-06-26). A rail value read by >1 in-place consumer (value self-update OR
// rotation gate) cannot be lowered by in-place collapse — both mutations would
// serialize onto the one handle (a verify-clean wrong unitary). Mirrored
// CHARACTER-FOR-CHARACTER by lowering_reject_loop_rail_fanout{,_rot}.ll (Rule 12).
constexpr char kMsgRailFanout[] =
    "cq loop lowering: loop-carried rail has multiple in-place consumers";

// Phase 7.4 (epic y05j) — the `tryBreak` decline partition (PRD-7.4 §2.10). Each
// is source-located (`!dbg`) and mirrored CHARACTER-FOR-CHARACTER by a negative
// fixture (Rule 12). The genuinely-quantum-bounded loop is NOT one of these — it
// is left for `tryCaseA`'s existing L1 `diagnoseUnderControl(_, "loop")` (a fused
// exit with no classical bound is not a `break`, PRD-7.4 §2.5 B1 / Risk 4).
//
//  * (the recognized value-arm break is now EMITTED, Inc 2 — `emitBreakForward`
//    transforms it and records a `LoopBreakRegion`; the `kMsgBreakPending` interim
//    decline is retired. A recognized-but-non-canonical sub-shape declines via
//    `kMsgBreakUnemittable` below.)
//  * kMsgBreakPhase — a phase-class escaping answer (Rule 7: a CNOT copy-out
//    dephases; the data-comparison phase break is degenerate). PERMANENT (§2.6).
//  * kMsgBreakNonReconv — the break edge and the natural exit reach distinct
//    blocks / no single merge phi. DEFER (§2.7).
//  * kMsgBreakMultiSite — >1 tainted exiting block. INTERIM → accept in Inc 3
//    (§2.7; the index latch subsumes any cascade), not a deferral.
//  * kMsgBreakNested — `L` is an inner/outer of another tainted loop; the break
//    crosses loops. DEFER, blocked-on the nested-quantum-loop substrate (§2.7).
// Increment 2 (y05j.2) — the EMITTER sub-shape decline. A loop the recognizer
// accepted as a value-arm break but whose body is NOT the proven, emittable
// canonical rolled shape (single-block `header == latch`; ONE in-place value
// rail with a clean `cq_theta`-rooted self-cycle and linear in-place lineage;
// a UNIT-stride up-counting classical induction with the canonical
// `select(brk, true, bound)` fused `icmp eq i.next, n` exit). Non-canonical
// shapes (multi-block body, non-unit / down stride, phase/dirty rail, fan-out)
// are decline-safe near-term widenings — the index-gated capture + whole-loop
// reverse-play is proven only on the canonical shape in this increment (Prime
// Directive: over-declining is safe). Mirror-exact (Rule 12).
constexpr char kMsgBreakUnemittable[] =
    "cq loop lowering: early break body is not a provable rolled single-rail loop";
constexpr char kMsgBreakPhase[] =
    "cq loop lowering: early break preserves a phase answer";
constexpr char kMsgBreakNonReconv[] =
    "cq loop lowering: early break does not reconverge";
constexpr char kMsgBreakMultiSite[] =
    "cq loop lowering: multiple early-break sites";
constexpr char kMsgBreakNested[] =
    "cq loop lowering: early break across nested loops";

void diagnose(Instruction *Where, StringRef Msg) {
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

}  // namespace

// Issue dtzb — is `BO` a recognized IN-PLACE value rail self-update? An `add` or
// `xor` (a reversible bijection of the rail GIVEN a classical immediate) with
// EXACTLY ONE tainted operand (the rail) and a CLASSICAL other operand (the
// immediate), of an integer width the in-place ABI serves (≤ 64 bits — there is
// no `cqrt_{addc,xorc}_i128`). Returns the tainted rail operand (the base the
// wire peels to), or null. This is the value analogue of an in-place rotation
// gate: `cqrt_{addc,xorc}_<W>` mutates the one rail handle in place, so its
// result belongs to that rail. The exclusions are the over-accept partition
// (Rule 12): `mul`/`and`/`or`/`shl`/`lshr` are information-LOSING (no in-place
// reversible form), and a TWO-quantum `acc + q` (both operands tainted) has no
// classical immediate — both return null and stay the X1 cross-iteration decline
// (the general two-quantum Cuccaro-adder case is a deferred follow-on). An `fadd`
// is opcode `FAdd`, not `Add`, so fp never reaches here.
//
// Exported since bd test_C_libtooling-6uqc Inc 2a — `ArithLowering`'s M-C
// straight-line in-place-reassignment fence asks the SAME question this
// predicate already answers, and Rule 14 says ask it rather than re-spell it.
// (Declared in LoopPlan.h.)
Value *inPlaceValueRailOperand(BinaryOperator *BO, const TaintSet &taint) {
  Instruction::BinaryOps Op = BO->getOpcode();
  if (Op != Instruction::Add && Op != Instruction::Xor)
    return nullptr;  // owner scope (dtzb): the add/xor bijection family only.
  Type *Ty = BO->getType();
  if (!Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return nullptr;  // i128 has no in-place ABI (the copyFn > 64 fence twin).
  Value *L = BO->getOperand(0), *R = BO->getOperand(1);
  bool TL = taint.Tainted.count(L) != 0, TR = taint.Tainted.count(R) != 0;
  if (TL == TR)
    return nullptr;  // need EXACTLY one tainted (rail) + one classical (imm).
  return TL ? L : R;
}

namespace {

// ONE SPELLING of "will this `BinaryOperator` be lowered as an IN-PLACE mutation
// of rail value `V`'s handle?" (bd test_C_libtooling-8h7d.5, Rule-13 round 4,
// finding OD-A). Two independent halves, and conflating them is the defect this
// replaces: the SHAPE (`inPlaceValueRailOperand(BO) == V` — the dtzb `V OP c`
// bijection) says the op COULD be lowered in place; the DISPOSITION says whether
// it WILL be.
//
// In-place value lowering has exactly TWO owners, and this enumerates both:
//   * `taint.InPlaceRailOps` — `lowerLoops`' own proven set (round 1's `railRoot`
//     marking, round 2's step (3)). `Claimed` is the set the CALLER is about to
//     add to it, so a caller that runs BEFORE its own marking (the fan-out guard
//     does — step (2) precedes step (3)) passes its chain and gets the same
//     answer it would after marking. Round 1 passes `railRoot`, where the
//     question is a no-op: its fixpoint has already absorbed every in-place BO
//     consumer of a rail value, by construction.
//   * `ArithLowering`'s M-C in-place reassignment (`classifyInPlaceReassignment`
//     → `inPlaceFenceHolds`), whose **G5** refuses OUTRIGHT any site inside a
//     natural loop or a `blockCanRepeat` block — "the rolled-in-place (799w) and
//     whole-loop reverse-play (y05j/dtzb) machinery owns in-place value gates in
//     loop bodies … straight-line only". So an unmarked, unclaimed BO in a loop
//     body is `OutOfPlace` BY CONSTRUCTION: `lowerOps` mints it a FRESH rail
//     (`cq_template_<op>_<W>_hl`) and the loop-carried register never moves.
//
// `Unproven` is the straight-line remainder — M-C legitimately DOES fire there
// (`for(…){…} int r = q + 9; return cq_measure(r);` emits `cqrt_addc_i32(%h,9)`,
// probe r3h/b4) and nothing here can predict G6/G7's answer. Each caller states
// how it reads that cell, and the two read it OPPOSITE ways on purpose:
//
//   * the FAN-OUT guard counts `Unproven` (Rule 8 linear lineage — an unproven
//     second in-place mutator must decline loudly, Prime Directive);
//   * `collectRailGates`' forward extension follows only `InPlace` (its own
//     header explains why, and that exclusion is sound only because M-C's G6/G7
//     pair refuses a site with a later record read — round 3, bookkeeping 4).
//
// WHAT THIS FIXES. `clang -O1` canonicalizes the two-sided range test
// `if (q > 5 && q < 20)` to `%t = add %q, -6; icmp ult %t, 14`. `%t` has the dtzb
// SHAPE, so the fan-out guard counted it beside the arm's real `cq_phi` and
// declined `kMsgRailFanout` — while the hand-unrolled twin of the same source
// compiled. `%t` is a DERIVED-CONDITION temp inside the loop body: G5 guarantees
// it lowers out of place, so it was never a second mutator of the rail at all.
enum class RailValueUse { NotThisRail, OutOfPlace, Unproven, InPlace };

RailValueUse railValueConsumerDisposition(
    llvm::BinaryOperator *BO, const Value *V, const TaintSet &taint,
    const SmallPtrSetImpl<const Value *> &Claimed) {
  if (inPlaceValueRailOperand(BO, taint) != V)
    return RailValueUse::NotThisRail;
  if (taint.InPlaceRailOps.count(BO) || Claimed.count(BO))
    return RailValueUse::InPlace;
  // G5's own disjunction, asked with the SAME `blockCanRepeat` spelling (which
  // is a strict superset of `LoopInfo::getLoopFor != null`, so one call answers
  // both halves — an irreducible cycle is not a natural loop but still repeats,
  // bd 4p7j / x67f F1).
  if (blockCanRepeat(BO->getParent()))
    return RailValueUse::OutOfPlace;
  return RailValueUse::Unproven;
}

// Peel in-place gates off the front of a value's wire, returning the underlying
// base. Two gate kinds peel (both are in-place mutations of the one rail handle,
// their result RAUWs to the operand at lowering): (1) rotation gates
// (`cq_theta`/`cq_phi` whose arg-0 handle is tainted — the 7.3 vocabulary), and
// (2, issue dtzb) value rail self-updates (`q = q OP c`, add/xor + classical
// immediate — `inPlaceValueRailOperand`). Parallels
// `TaintPropagation::resolveWireBase` but returns only the base. Stops at a
// classical-operand `cq_theta` (the rail MINT), at any non-gate value (a phi /
// template producer / argument), and at a two-quantum / non-bijection op (a dirty
// rail → X1).
// ONE STEP of that peel: the value `V`'s rail parent, or null when `V` IS the
// base. Split out for bd test_C_libtooling-8h7d.5's round-2 collapse, which must
// ENUMERATE the chain (to mark its in-place value ops and to count fan-out) and
// must do so by walking the IDENTICAL edges `peelInPlaceBase` walks — a
// hand-rolled second walk that took `arg 0` off any call would run PAST the base
// and mark ops that are not on the rail at all, which `lowerOps` would then emit
// as in-place mutations of a register they do not belong to (Rule 14: one
// spelling, asked twice).
//
// TWO READINGS OF THE `BinaryOperator` EDGE, AND `AsLowered` PICKS ONE (bd
// 8h7d.5, Rule-13 round 4 — the third head of finding OD-A). By default the edge
// is the dtzb SHAPE alone: that is the CLAIM-time reading, and it is right for
// every caller that is deciding whether it MAY own a chain, because owning it is
// what makes the op in-place (`tryCaseA`'s `railRoot` fixpoint says the same
// thing about itself, in its own Rule-14 note). `AsLowered` asks the DISPOSITION
// instead — `railValueConsumerDisposition(...) == InPlace` — which is the
// FACT-time reading, for a caller that runs AFTER the marking and is asserting
// "this SSA name IS the register".
//
// Conflating the two is a measured defect, not a hypothetical: `clang -O1`
// canonicalizes `if (q > 5 && q < 20)` inside a loop body to
// `%t = add %q, -6; icmp ult %t, 14`, and `%t` peels to the rail root by SHAPE.
// `markIfRailLocal`'s `onRail` therefore classified a DERIVED-CONDITION TEMP as
// "the register", with two consequences: `AnyLocal` stayed false so the body was
// never certified ITERATION-LOCAL and the uncompute spine's §2.9 acyclic
// backstop LEAKED the whole condition chain once per trip (the rolled trace then
// differs from its hand-unrolled twin's — this increment's load-bearing
// witness); and the temp inherited the rail's EXEMPTION from the escape check,
// which `collectRailGates` — the other spelling of "on this rail" — would never
// have granted it. Two spellings that disagree about one value is finding F-1's
// and F-3's shape a third time; this parameter is how they are made to agree.
Value *peelInPlaceStep(Value *V, const SmallPtrSetImpl<CallInst *> &GateCalls,
                       const TaintSet &taint, bool AsLowered = false) {
  if (auto *CI = dyn_cast<CallInst>(V)) {
    if (!GateCalls.count(CI))
      return nullptr;  // not a collected rotation call — V is the base.
    Value *Handle = CI->getArgOperand(0);
    if (!taint.Tainted.count(Handle))
      return nullptr;  // classical-operand theta: the mint point IS the base.
    return Handle;
  }
  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    Value *Base = inPlaceValueRailOperand(BO, taint);  // dtzb self-update, or null.
    if (!AsLowered || !Base)
      return Base;
    // FACT-time: only an op that will really be emitted as `cqrt_{addc,xorc}`
    // keeps the register. `Claimed` is empty — this reading is for callers that
    // run after every claim has been marked, so there is nothing pending.
    SmallPtrSet<const Value *, 1> NoClaim;
    return railValueConsumerDisposition(BO, Base, taint, NoClaim) ==
                   RailValueUse::InPlace
               ? Base
               : nullptr;
  }
  return nullptr;
}

Value *peelInPlaceBase(Value *V, const SmallPtrSetImpl<CallInst *> &GateCalls,
                       const TaintSet &taint, bool AsLowered = false) {
  while (Value *Next = peelInPlaceStep(V, GateCalls, taint, AsLowered))
    V = Next;
  return V;
}

// Is `CI` an IN-PLACE rotation gate on its arg-0 handle `H` (a collected
// `cq_theta`/`cq_phi` whose arg-0 is `H` and tainted)? Such a gate mints no new
// rail; its result RAUWs to `H` at rotation lowering — so its result belongs to
// `H`'s persistent rail.
bool isInPlaceGateOnArg0(const CallInst *CI, const Value *H,
                         const SmallPtrSetImpl<CallInst *> &GateCalls,
                         const TaintSet &taint) {
  if (!GateCalls.count(const_cast<CallInst *>(CI)))
    return false;
  return CI->arg_size() >= 1 && CI->getArgOperand(0) == H &&
         taint.Tainted.count(const_cast<Value *>(H));
}

bool isMeasureCall(const Instruction *I) {
  const auto *CI = dyn_cast<CallInst>(I);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  // Pre-lowering the front-end form is `@cq_measure_<sfx>`; the `cqrt_measure_`
  // prefix is accepted defensively (mirrors `isMeasureSink`) though `lowerLoops`
  // always runs before measure lowering.
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  return N.starts_with("cq_measure_") || N.starts_with("cqrt_measure_");
}

// ── bd test_C_libtooling-8h7d.5, Rule-13 round 1 (finding F1) — THE RAIL-RECORD
//    LIVENESS FENCE. One predicate, asked by BOTH rounds (Rule 14). ──────────
//
// THE INVARIANT IN ONE SENTENCE: an SSA name on a collapsed rail is only a valid
// operand at positions where the physical register still holds the state that
// name denotes.
//
// This is the obligation the two loop rounds share and that round 2 shipped
// without. Collapsing a rail phi RAUWs every member onto ONE handle, so the
// emitted stream reads whatever the wire holds AT THE EMISSION POSITION, while
// the SSA name denotes a fixed prefix of the rail's gate sequence. Inside a loop
// those two disagree the moment ANY rail gate separates them, and the
// disagreement is invisible to every shipped gate:
//
//     for (...) { if (q == 5) q = cq_phi(q, PI); acc = q * 7; q += 3; }
//     return cq_measure(q) + cq_measure(acc);
//
// `clang -O1` sinks the `mul` past the loop (only `acc`'s last value is read), so
// the emitted `cq_template_mul_i32_hl(%h, 7)` runs after every `cqrt_addc_i32`
// and computes `(q0+3k)*7` where the source says `(q0+3(k-1))*7`. `opt` exits 0,
// `opt -verify` is clean, STRICT stage-2b free-pairing is clean — the shape is
// perfect and only the state is wrong. Round 1 declines the same program (its
// CLOSURE refuses any out-of-rail consumer); round 2 stated that it "deliberately
// does not re-prove COVERAGE/CLOSURE" and collapsed anyway.
//
// AND ROUND 1 HAD ITS OWN HALF OF THE HOLE, older than this increment: its
// CLOSURE admits `isMeasureCall` / `ReturnInst` users of a rail value AT ANY
// POSITION, so `for (…) { last = q; q += off; } return cq_measure(last);` emitted
// `measure(h)` after the loop and measured `q0+3k` for a source that says
// `q0+3(k-1)`. Same defect, same fence, both rounds.
//
// WHY IT IS POSITIONAL AND NOT "NOTHING ESCAPES THE LOOP". Two shapes rule the
// cheap answers out. A blanket "no rail member is read outside `L`" refuses
// `slice_control_grover_loop`'s own `cq_measure(q)` — the customer, and the whole
// point of the increment. A blanket "no rail member has a value-op consumer"
// refuses the region's OWN emitted `cq_template_icmp_eq_i32_hl(%h, 5)`, which is
// a value-op consumer of the very same header phi in every shipped slice. What
// separates the accepts from the miscompiles is neither locality nor consumer
// class — it is whether a rail-relabelling gate runs between the record and the
// read.
//
// THE TEST. For a rail member `v` with definition `D` and a non-member consumer
// reading it at position `p`: FAIL iff some execution path runs `D`, then a rail
// GATE, then `p`, WITHOUT re-executing `D` in between. Re-executing `D` refreshes
// the record (this is the same per-activation reading `WireWalk`'s barrier walk
// takes, spelled as an explicit two-state product walk because the barrier here
// is the record's own definition and the question is about a gate strictly
// between two points, not about a pair).
//
// It gets the asymmetries right for free, which is why it is stated this way:
//   * a pre-loop read of the pre-header chain PASSES (no path from the mint to
//     that read runs a body gate) while a POST-loop read of the same member
//     fails;
//   * the LATCH-carried value read after the loop PASSES (every path from it
//     back to itself re-executes it), which is exactly the customer's
//     `cq_measure(q)`;
//   * a read at the TOP of the body passes; the same read moved below an in-place
//     `addc` fails;
//   * in an UNROTATED loop (`while (c) { gates }`) the header phi read in the exit
//     block PASSES — and correctly, because the exit test runs before that
//     iteration's gates, so the phi's value at the exit edge IS the final state.
//     A rule keyed on "which member is it" could not tell that apart from the
//     rotated shape, where the same read is the miscompile above.
//
// WHICH INSTRUCTIONS COUNT AS GATES. Exactly the ones that relabel the
// computational basis ON THIS RAIL: `cq_theta` (Ry) and the dtzb in-place
// `add`/`xor` (a permutation of the register). `cq_phi` (Rz) is DIAGONAL and is
// deliberately NOT a gate — the shipped reading of the whole stale-record family
// (WireWalk.h, bd memory rz-diag-flag-strip-invariant), and the reason
// control_swap_inloop_diamond.ll's post-loop read of a pure-Rz rail keeps lowering.
// A PHINode is a renaming, not a gate. Gates from a DIFFERENT rail are not
// consulted: they mutate another wire and say nothing about this record (bd
// `hcrg`'s lesson in reverse — fence the unitary, not the bookkeeping).
//
// "ON THIS RAIL" AND NOT "ON THIS CHAIN" — that word is finding F-1 of the SECOND
// Rule-13 round, and it was a CONFIRMED silent miscompile until 2026-08-30. The
// gate set was built from the peeled chain's own members, and a rail is bigger
// than its chain: see `collectRailGates` for the forward extension and for the
// three edge kinds it follows.
constexpr char kMsgRailRecordStale[] =
    "cq loop lowering: rail record read past an in-place gate on the same rail";

// Does re-executing `Def` REFRESH the record — i.e. does the value `Def` produces
// on its next activation name the state the register holds right then? The
// `railGateBetween` walk below cuts every path that re-runs `Def` on exactly that
// premise, so this is the premise's proof (bd 8h7d.5 Rule-13 ROUND 2, finding
// F-2: shipped as an unconditional cut, and one rail shape falsifies it).
//
// A def refreshes iff re-executing it RE-READS THE WIRE. Every in-place gate does
// by construction (it applies its gate to whatever the register currently holds,
// so its result IS the post-gate state), and so does an ordinary rail phi, whose
// carry brings back the value the gates just produced. The one shape that does
// NOT is a phi that carries ITSELF around the loop with no gate on the carry:
//
//     %rec = phi i32 [ %q0, %entry ], [ %rec, %latch ]      ; a ZERO-HOP carry
//
// which step (1) accepts as a rail (`peelInPlaceBase(LatV) == &P` holds
// TRIVIALLY). It re-executes every iteration and yields the SAME value every
// time, so it is a FROZEN alias of the mint — while a sibling chain on the same
// root mint moves the wire underneath it. The cut then suppressed exactly the
// path that carried the staleness, and `%acc = mul %rec, 7` read iteration k's
// register through iteration 0's name (probe `pd1_identity_carry.ll`).
//
// STATED GENERALLY, not as a special case for `In == P`. A carry refreshes only
// if it crosses a rail GATE: an incoming that peels back to the phi itself
// through diagonal / renaming steps only (`cq_phi`/Rz, a re-entrant rename) is
// the same frozen record wearing extra phases, and a basis-relabelling `cq_theta`
// or in-place `add`/`xor` on the carry is what makes it a genuine rotating rail
// (the customer's own header phi: its latch incoming peels back through the body
// `cq_theta`s, so it refreshes and the cut stands).
//
// FROZEN-NESS IS DELIBERATELY NOT PROPAGATED FORWARD, and that is a conclusion,
// not an omission. A gate applied to a frozen record (`%z = cq_theta(%rec, a)`)
// is ITSELF a non-member read of `%rec` at a position where a sibling gate has
// already moved the wire — so the fence declines at `%rec` before any read of
// `%z` is ever reached. The only way `%z` is NOT such a read is when it is a
// chain MEMBER, i.e. when `%rec`'s own carry runs through it, and then `%rec`
// refreshes and there was nothing frozen to propagate.
//
// CONSERVATIVE DIRECTION: answering "no" only ever REMOVES a cut, which only ever
// adds declines, so `false` is the safe default and any shape this cannot classify
// belongs on that side. Every non-phi member is classified, not defaulted: a rail
// member is a phi, an in-place rotation, an in-place `add`/`xor`, or the root mint,
// and each of the last three produces the register state as of its own execution.
// The carry walk terminates for the reason `peelInPlaceBase` does — each step
// ascends the arg-0 / rail-operand def chain, acyclic in SSA, and a phi ends it.
bool recordRefreshedByDef(const Instruction *Def,
                          const SmallPtrSetImpl<CallInst *> &GateCalls,
                          const TaintSet &taint,
                          const SmallPtrSetImpl<const Instruction *> &Gates) {
  const auto *P = dyn_cast<PHINode>(Def);
  if (!P)
    return true;  // an in-place gate: its result is the post-gate register.
  for (Value *In : P->incoming_values()) {
    // Walk the carry back through in-place steps. Reaching `P` without crossing
    // a GATE is a frozen self-carry; crossing a gate first (or landing on some
    // other base) is a real refresh for this edge.
    Value *V = In;
    while (true) {
      if (V == P)
        return false;  // gate-free self-carry — the record never moves.
      if (auto *I = dyn_cast<Instruction>(V))
        if (Gates.count(I))
          break;  // the carry relabels the basis — this edge refreshes.
      Value *Next = peelInPlaceStep(V, GateCalls, taint);
      if (!Next)
        break;  // a different base — not a self-carry.
      V = Next;
    }
  }
  return true;
}

// Is there an execution path `Def` → (some `Gates` member) → `Read` that never
// re-executes `Def`? EXACT two-state product walk over the CFG: the state is
// (block entered at the top, "a gate has fired since `Def`"), which is monotone,
// so each block is scanned at most twice and the walk terminates. `Def`'s own
// block is entered MID-WAY (at `Def`) for the seed scan and is NOT pre-marked, so
// a back edge re-entering it from the top is a genuinely different traversal —
// and one that hits `Def` and CUTS, which is the record refresh.
//
// The cut is CONDITIONAL on `DefRefreshes` (`recordRefreshedByDef` above). Cutting
// is exactly equivalent to RESTARTING the walk at `Def` with `sawGate` cleared,
// which the seed scan already explores — which is why cutting is sound whenever
// the premise holds, and unsound the moment it does not.
//
// Deliberately NOT `llvm::isPotentiallyReachable`: that helper's exclusion set is
// per-BLOCK and it bails `true` past a scan limit, and both endpoints here
// routinely live in the SAME block as the barrier (the flattened loop body is one
// block). The same two reasons `WireWalk::reachesWithoutBarrier` and
// `ControlDetect::regionEntryInLoop` hand-roll their walks.
bool railGateBetween(const Instruction *Def, const Instruction *Read,
                     const SmallPtrSetImpl<const Instruction *> &Gates,
                     bool DefRefreshes) {
  SmallPtrSet<const BasicBlock *, 32> Seen[2];
  SmallVector<std::pair<const BasicBlock *, bool>, 32> Work;
  {  // seed: the tail of `Def`'s own block, from just after `Def`.
    const BasicBlock *B = Def->getParent();
    bool Saw = false;
    for (auto I = std::next(Def->getIterator()), E = B->end(); I != E; ++I) {
      if (&*I == Read && Saw)
        return true;
      if (Gates.count(&*I))
        Saw = true;
    }
    for (const BasicBlock *S : successors(B))
      Work.push_back({S, Saw});
  }
  while (!Work.empty()) {
    auto [B, Saw] = Work.pop_back_val();
    if (!Seen[Saw ? 1 : 0].insert(B).second)
      continue;
    bool Cut = false, S2 = Saw;
    for (const Instruction &I : *B) {
      if (&I == Def && DefRefreshes) {
        Cut = true;  // the record is re-established — a different activation.
        break;
      }
      if (&I == Read && S2)
        return true;
      if (Gates.count(&I))
        S2 = true;
    }
    if (Cut)
      continue;
    for (const BasicBlock *S : successors(B))
      Work.push_back({S, S2});
  }
  return false;
}

// Apply the fence to ONE rail. `Members` is that rail's value set (the chain
// endpoints and everything between, in any order — the predicate needs identity,
// never order) and `GateCalls` the collected `cq_theta`/`cq_phi` vocabulary.
// Returns the offending CONSUMER (for the `!dbg`-located diagnostic) or null.
//
// A PHI consumer reads its incoming on the EDGE, not in its own block, so its
// read position is the incoming block's TERMINATOR — without that, the `-O1`
// zero-trip guard's exit phi (`phi [PreV, guard], [LatV, latchexit]`, both
// incomings on the rail and both correct on their own edge) would be refused and
// slice_control_grover_loop_dynamic would stop lowering.
//
// THE GATE SET IS THE RAIL'S, NOT THE CHAIN'S (bd 8h7d.5 Rule-13 ROUND 2, finding
// F-1 — shipped reading the chain only, which was a CONFIRMED silent miscompile).
// `Members` is the peeled root→PreV→phi→LatV chain, and a gate can sit on the
// same PHYSICAL register without being on it. The canonical shape is a rotation
// applied to the loop's EXIT value:
//
//     for (…) { if (q==5) q = cq_phi(q,PI); q = cq_theta(q,-.5); q = cq_theta(q,.5); }
//     int mark = q;  q = cq_theta(q, 0.125);   /* arg-0 IS a member, RESULT is not */
//     return cq_measure(mark) + cq_measure(q);
//
// which emitted `cqrt_ry_i32(%h, 0.125); measure(%h); measure(%h)` — `mark` names
// the pre-Ry record and is measured AFTER it. `opt` exit 0, verify-clean, STRICT
// stage-2b clean. Ry is ALWAYS lowered in place (`lowerRotations` RAUWs the result
// to the handle), so unlike an out-of-place value op there is no escape hatch: the
// wire moves and every earlier name goes stale.
//
// So the rail is extended FORWARD from the chain, through exactly the users that
// keep mutating the SAME handle, and every basis-relabelling one of those is a
// gate. Three edge kinds are followed, and each exclusion is load-bearing:
//
//   * an IN-PLACE ROTATION (`isInPlaceGateOnArg0`) — unconditionally, because
//     `cq_theta`/`cq_phi` are always lowered in place. `cq_theta` is a GATE (Ry
//     relabels the basis); `cq_phi` is followed but is NOT a gate (Rz is diagonal
//     — the shipped reading of the whole stale-record family, bd memory
//     `rz-diag-flag-strip-invariant`). Following the diagonal one matters: it is
//     what catches `mark = q; q = cq_phi(q,a); q = cq_theta(q,b);`, where the Ry's
//     arg-0 is the Rz result and therefore not a chain member (probe g1).
//
//   * an in-place VALUE self-update (dtzb `add`/`xor`) — ONLY when it is a chain
//     member or already in `taint.InPlaceRailOps` — the `InPlace` cell of
//     `railValueConsumerDisposition`, which is the ONE spelling of this question
//     (bd 8h7d.5 Rule-13 round 4, OD-A; the fan-out guards and `markIfRailLocal`
//     ask the same predicate and read its `Unproven` cell the OTHER way, each for
//     its own safe direction). Counting an off-chain one would refuse
//     `mark = q; q = q + 9; measure(mark);`, which is CORRECT today because that
//     add lands on a FRESH rail and this register never moves. The walk STOPS
//     there for the same reason — a `cq_theta` on that add's result rotates the
//     fresh rail, not this one.
//
//     PINNED BY TWO FIXTURES, NOT ONE (round-4 correction; this note said
//     "pinned by control_swap_inloop_postloop_railop.ll" as if that were the
//     whole pin). MEASURED 2026-08-30 by disabling BOTH G6 and G7 in
//     `inPlaceFenceHolds` and running all 1293 fixtures: 49 go red, and
//     control_swap_inloop_postloop_railop.ll (this exclusion's accept — the
//     record read that must survive) and control_swap_inloop_postloop_railop_mc.ll
//     (the in-place / out-of-place pair) are both among them. The round-3 note at
//     the G6 site says the `_mc` fixture only reddens when BOTH clauses are
//     relaxed, and that is confirmed and unchanged; what is corrected here is the
//     COUNT of what stands behind the exclusion.
//
//     THAT EXCLUSION IS SOUND ONLY BECAUSE OF M-C's G6/G7 PAIR, AND IT IS A REAL
//     DEPENDENCY ON ANOTHER FILE — stated here because the earlier wording ("an
//     off-chain one is lowered OUT of place by the M-C decision") asserted
//     something MEASURABLY FALSE as if it were unconditional (bd 8h7d.5 Rule-13
//     ROUND 3, bookkeeping item 4). `lowerOps`' M-C in-place reassignment
//     (`classifyInPlaceReassignment`, ArithLowering.cpp) DOES fire post-loop:
//     `for (…) {…} int r = q + 9; return cq_measure(r);` emits
//     `cqrt_addc_i32(%h, 9)` IN PLACE (probe r3h/b4). What keeps the exclusion
//     safe is M-C's position-aware deadness loop — G6 ("no data use AFTER the op",
//     asked POST-RAUW so every rail alias is already unified onto `%h`) and G7 —
//     which refuses exactly when a later record read of the pre-add register
//     exists, so the two dispositions are mutually exclusive: `mark = q;
//     q = q + 9; q = cq_theta(q,.25); measure(mark)` falls back to the
//     out-of-place `cq_template_add_i32_hl` (probe r3h/b5). Both are pinned by
//     control_swap_inloop_postloop_railop_mc.ll — and pinned WEAKLY, which is part
//     of the record: measured by mutation, G6 and G7 each refuse that use on their
//     own, so the fixture only reddens if BOTH are relaxed. IF YOU RELAX EITHER,
//     this exclusion becomes an over-accept and must be re-derived HERE first; no
//     test will do it for you.
//
//   * a PHI with SOME incoming already on the rail — a merge that names this
//     register on at least one edge, so a rotation applied to it moves this wire
//     on that edge. `railGateBetween` is an ∃-path test, so "some" (not "all") is
//     the sound side; a phi that also merges a foreign value only ever adds
//     declines. Without it `mark = q; if (n) q = cq_phi(q,a); q = cq_theta(q,b);`
//     is missed (probe g3).
//
// NOT TRANSITIVE PAST THE FIRST GATE, and it does not need to be. If `t2 =
// cq_theta(t1, …)` with `t1 = cq_theta(m, …)` and `m` a member, then `Def` (m's
// def) dominates `t1` and `t1` dominates `t2`, so EVERY path from `Def` to `t2`
// crosses `t1`: a `Def`→`t2` path avoiding `t1` could be prefixed by a simple
// entry→`Def` path (which cannot visit `t1`'s block — `Def` dominates it, so the
// path would have to repeat `Def`'s block) to give an entry→`t2` path avoiding
// `t1`, contradicting the dominance. `t1` alone therefore fires the fence at every
// position `t2` would. The forward walk IS still a FIXPOINT, for a different
// reason: the three edge kinds chain (an Rz hop, then a merge phi, then the Ry
// that is the actual gate), and a phi only becomes claimable once one of its
// incomings has joined — which can happen after the phi was first visited.
//
// RULE 14 — WHY THIS IS NOT `tryCaseA`'S `railRoot` FIXPOINT, THOUGH IT LOOKS
// LIKE IT. Round 1 grows a rail forward too (`an in-place gate on a rail value
// joins the SAME rail`, the (a)/(b) fixpoint above `tryCaseA`'s CLOSURE), and the
// question "should these be one spelling?" was asked and answered NO, in this
// round, on the two places they deliberately differ:
//
//   * ROUND 1 follows an off-chain in-place `add`/`xor` UNCONDITIONALLY; this one
//     requires `taint.InPlaceRailOps` (see the second edge kind). Round 1 may:
//     its fixpoint runs BEFORE it marks, and every op it admits it then marks, so
//     "in-place" is a claim it is about to MAKE. Here it is a fact that must
//     already HOLD — a loop reaching round 2 was NOT claimed by round 1, so none
//     of ITS ops carry a mark, and following an unmarked add would refuse the
//     correct `mark = q; q = q + 9; measure(mark)`. (Marks from some OTHER loop's
//     round-1 claim are per-op and simply true, which is why the test is a
//     membership question and not a "has anything been marked yet" one.)
//   * ROUND 1's phi edge needs ALL incomings to peel to one root; this one needs
//     SOME incoming on the rail. Round 1 is building a CLAIM set — a phi merging
//     a foreign value is not a rail it may collapse, so "all" is the sound side
//     there. This is an ∃-PATH staleness witness — one incoming naming the
//     register is one path on which a later gate moves it, so "some" is the sound
//     side here. Each spelling is UNSOUND in the other's job, which is why the
//     union is not available: widening round 1 to "some" would collapse phis it
//     cannot prove, and narrowing this one to "all" silently drops the merge
//     miscompile (lowering_reject_inloop_rail_record_merge_theta.ll).
//
// So two spellings are tolerated, and the pair is PINNED rather than trusted:
// r3g/w1 and r3c/k1 are the SAME C program with and without an in-body tainted
// `if`, i.e. round 1's rail and round 2's, and they ship as
// lowering_reject_loop_rail_record_offchain_theta.ll (round 1, no control) and
// lowering_reject_inloop_rail_record_offchain_theta.ll (round 2). Both must
// decline with the identical message; if the two extensions ever diverge on the
// reach that matters, one of those two fixtures goes red.
//
// `OnRailOut`, when given, receives EVERY value proven to be on this rail — the
// chain members first, in the order they were handed in, then the forward
// extension in discovery order. That out-parameter is finding F-3 of the THIRD
// Rule-13 round, and it is F-1's exact twin one hop out: round 2 widened the GATE
// set to the rail and left the RECORD set at the chain, so a rail value one hop
// off the chain was never asked about (see `staleRailRecordRead`). The order is
// reproducible run-to-run — `Members` arrives in a deterministic order and the
// extension is driven by LLVM use lists, which are construction-ordered, not
// pointer-hashed — which matters because the caller DIAGNOSES from it and a
// wandering `!dbg` location reads as a flaky test later (the same reason
// `tryCaseA` groups its chains in program order).
void collectRailGates(ArrayRef<Value *> Members,
                      const SmallPtrSetImpl<CallInst *> &GateCalls,
                      const TaintSet &taint,
                      SmallPtrSetImpl<const Instruction *> &Gates,
                      SmallVectorImpl<Value *> *OnRailOut = nullptr) {
  // Everything proven to be on this rail — the chain, plus the forward extension.
  SmallPtrSet<const Value *, 32> OnRail;
  SmallVector<Value *, 32> Work;
  for (Value *V : Members)
    if (OnRail.insert(V).second) {
      Work.push_back(V);
      if (OnRailOut)
        OnRailOut->push_back(V);
    }

  auto noteGate = [&](Instruction *I) {
    if (auto *CI = dyn_cast<CallInst>(I)) {
      const Function *Fn = CI->getCalledFunction();
      if (GateCalls.count(CI) && Fn && Fn->getName().starts_with("cq_theta_"))
        Gates.insert(CI);  // Ry — relabels the basis.
    } else if (auto *BO = dyn_cast<BinaryOperator>(I)) {
      if (inPlaceValueRailOperand(BO, taint))
        Gates.insert(BO);  // dtzb `cqrt_{addc,xorc}` — a basis permutation.
    }
  };

  for (Value *V : Members)
    if (auto *I = dyn_cast<Instruction>(V))
      noteGate(I);

  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || OnRail.count(I))
        continue;
      bool OnThisRail = false;
      if (auto *P = dyn_cast<PHINode>(I)) {
        if (!taint.Tainted.count(P))
          continue;  // a classical merge cannot be this register.
        for (Value *In : P->incoming_values())
          if (OnRail.count(In))
            OnThisRail = true;
      } else if (auto *CI = dyn_cast<CallInst>(I)) {
        OnThisRail = isInPlaceGateOnArg0(CI, V, GateCalls, taint);
      } else if (auto *BO = dyn_cast<BinaryOperator>(I)) {
        // `InPlace` ONLY — the `Unproven` straight-line cell is deliberately NOT
        // followed here (see the second edge kind above and OD-A's note on
        // `railValueConsumerDisposition`: this caller and the fan-out guard read
        // that cell OPPOSITE ways, and each direction is the safe one for its own
        // question). `Claimed` is empty: this walk has no marking of its own to
        // anticipate — the chain members it would name are already seeded into
        // `OnRail` before the walk starts.
        SmallPtrSet<const Value *, 1> NoClaim;
        OnThisRail = railValueConsumerDisposition(BO, V, taint, NoClaim) ==
                     RailValueUse::InPlace;
      }
      if (!OnThisRail)
        continue;
      OnRail.insert(I);
      Work.push_back(I);
      if (OnRailOut)
        OnRailOut->push_back(I);
      noteGate(I);
    }
  }
}

// ONE rail value against a precomputed gate set. Split out so the step-(5) phi
// fixpoint can ask it AFTER step (4) has erased the header phi — the gates
// themselves survive that erase, the members do not.
Instruction *staleReadOfValue(Value *V,
                              const SmallPtrSetImpl<const Value *> &Members,
                              const SmallPtrSetImpl<const Instruction *> &Gates,
                              const SmallPtrSetImpl<CallInst *> &GateCalls,
                              const TaintSet &taint) {
  auto *Def = dyn_cast<Instruction>(V);
  if (!Def)
    return nullptr;
  // Asked ONCE per record: whether re-executing this def re-reads the wire is a
  // property of the def, not of the consumer (bd 8h7d.5 Rule-13 round 2, F-2).
  const bool Refreshes = recordRefreshedByDef(Def, GateCalls, taint, Gates);
  for (User *U : V->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI || Members.count(UI))
      continue;  // the chain itself — its own gates are the rail, not a read.
    if (auto *P = dyn_cast<PHINode>(UI)) {
      for (unsigned i = 0, e = P->getNumIncomingValues(); i != e; ++i)
        if (P->getIncomingValue(i) == V &&
            railGateBetween(Def, P->getIncomingBlock(i)->getTerminator(), Gates,
                            Refreshes))
          return P;
      continue;
    }
    if (railGateBetween(Def, UI, Gates, Refreshes))
      return UI;
  }
  return nullptr;
}

// THE RECORD SET IS THE RAIL'S, THE SKIP SET IS THE CHAIN'S — and they are two
// different sets on purpose (bd 8h7d.5 Rule-13 ROUND 3, finding F-3; another
// CONFIRMED silent miscompile, and F-1's exact twin one hop out).
//
// Round 2 widened `collectRailGates`'s GATE set from the chain to the whole rail
// and left the RECORD loop — the values this fence asks "is any read of you
// stale?" — enumerating chain `Members`. A rail value ONE HOP off the chain was
// therefore never asked about, and this `clang -O1` C program miscompiled:
//
//     for (i<2) { if (q==5) q=cq_phi(q,PI); q=cq_theta(q,-.5); q=cq_theta(q,.5); }
//     int a = cq_theta(q, 0.125);   /* arg-0 IS a member — the RESULT is not */
//     int b = cq_theta(a, 0.25);    /* a rail gate AFTER the record `a` */
//     return cq_measure(a) + cq_measure(b);
//
// emitting `ry(h0,.125); ry(h0,.25); measure(h0); measure(h0)` — `a` names the
// pre-`b` register and is measured after `b`. `opt` exit 0, verify-clean, STRICT
// stage-2b clean. So the loop below runs over `RailValues`, the rail's own closure.
//
// THE TWO SETS MUST NOT BE UNIFIED, and a fixture pins the difference. The SKIP
// set answers "whose own in-place execution IS the wire moving?" — a chain member's
// gate is the rail advancing, not a read of it. The RECORD set answers "which SSA
// names denote a state of this rail?" — every value on it, chain or extension.
// Widening the skip set to the rail too was measured and REGRESSES
// lowering_reject_inloop_rail_frozen_gate_first.ll from a decline to an accept: a
// `cq_theta` applied to a FROZEN identity-carry record joins the rail by the
// extension's first edge kind, and skipping it as a "rail step" deletes exactly
// the read that proves the record frozen (round 2's F-2 argument depends on that
// read being visible — see `recordRefreshedByDef`).
Instruction *staleRailRecordRead(ArrayRef<Value *> Members,
                                 const SmallPtrSetImpl<CallInst *> &GateCalls,
                                 const TaintSet &taint) {
  SmallPtrSet<const Value *, 16> MemberSet(Members.begin(), Members.end());
  SmallPtrSet<const Instruction *, 8> Gates;
  SmallVector<Value *, 32> RailValues;
  collectRailGates(Members, GateCalls, taint, Gates, &RailValues);
  if (Gates.empty())
    return nullptr;
  // NOTE, so the next reader does not mis-read that early-out as "the pure-Rz rail
  // exits here". It does not. An accepted rail's chain contains its ROOT MINT, and
  // taint has exactly one source (Rule 3), so the mint is a `cq_theta` and `Gates`
  // holds at least it. A pure-Rz loop body therefore reaches the walk below and
  // passes it on POSITION: the mint sits outside the loop and is never re-reachable,
  // so no `Def → gate → read` path exists
  // (control_swap_inloop_{diamond,gatefree_body}.ll). The early-out is a defensive
  // guard for a chain that somehow carries no gate at all, not the diagonal case.
  //
  // `RailValues` leads with `Members` in the order the caller handed them in, so
  // the offender named for an already-declining program is the one round 2 named:
  // the extension is only ever reached when no chain member's read is stale.
  for (Value *V : RailValues)
    if (Instruction *Bad = staleReadOfValue(V, MemberSet, Gates, GateCalls, taint))
      return Bad;
  return nullptr;
}

// The loop's exiting condition is a live tainted value (`while(q<k)`,
// amplitude-/measurement-derived bound) ⇒ a runtime branch on a qubit — the
// genuinely quantum-controlled loop, a permanent decline (PRD §2.6, L1). Returns
// the offending terminator (for the diagnostic) or null.
Instruction *taintedExit(Loop *L, const TaintSet &taint) {
  SmallVector<BasicBlock *, 4> Exiting;
  L->getExitingBlocks(Exiting);
  for (BasicBlock *EB : Exiting) {
    Instruction *T = EB->getTerminator();
    if (auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
        return T;
    } else if (auto *SI = dyn_cast<SwitchInst>(T)) {
      if (taint.Tainted.count(SI->getCondition()))
        return T;
    }
  }
  return nullptr;
}

// ── Phase 7.4 (epic y05j) — single value-arm `break` recognition ────────────
//
// All analysis below is PURE SSA/CFG identity on the still-unmutated IR (Rule 9);
// `tryBreak` never mutates in Increment 1 (recognition + decline partition only).

// "Does this value's lineage carry a relative phase (an Rz / `cq_phi`)?" — the
// §2.6 phase fence over the escaping answer (B3). A per-TU mirror of
// `ControlDetect`'s `retLineageCarriesPhase` and the AbortPark/SelectClassify
// twins (the house style sanctions the trivial duplicate — keeping the loop
// partition self-contained, Rule 14). A `cq_theta` (Ry) basis superposition has
// no relative phase and STOPS the walk; a `cq_phi` (Rz) in the lineage is the
// phase carrier. Over-decline-safe (any phi flags it).
bool breakLineageCarriesPhase(Value *Op, const TaintSet &taint) {
  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Visited;
  Work.push_back(Op);
  Visited.insert(Op);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (auto *CI = dyn_cast<CallInst>(V)) {
      const Function *F = CI->getCalledFunction();
      if (F && F->getName().starts_with("cq_phi_"))
        return true;  // an Rz (cq_phi) — a relative-phase carrier.
    }
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;  // an argument / constant root — basis, not a phase.
    for (Value *In : I->operands())
      if (taint.Tainted.count(In) && Visited.insert(In).second)
        Work.push_back(In);
  }
  return false;
}

// Decompose the `-O1` FUSED loop-exit condition (PRD-7.4 §1.1) into its two
// candidate disjunct operands {break flag, classical bound}. `clang -O1` fuses
// the tainted break flag with the classical loop bound into ONE i1 value; this
// recovers the pair so the caller can taint-partition it (B1). Recognized forms
// (and their successor-swapped continue-polarity twins, Rule 9 — verified in the
// IR spike, /tmp/spike):
//   * `select(%a, i1 true,  %b)`   = %a ∨ %b   (exit-polarity, v1_value)
//   * `select(%a, %b, i1 false)`   = %a ∧ %b   (continue-polarity, v6 inner)
//   * `or  i1 %a, %b`              = %a ∨ %b
//   * `and i1 %a, %b`              = %a ∧ %b   (continue-polarity)
// Taint is predicate/polarity-independent (`taint(icmp) == taint(operands)`), so
// the same {tainted=brk, classical=bound} partition holds for both polarities.
// A 3-non-constant `select` (a genuine i1 data-mux) or any other shape returns
// nullopt ⇒ NOT a recognized fused break (the caller rides L1 / declines —
// over-declining is safe, Prime Directive). `IsOr` records the fusion logic
// (OR = `a ∨ b`, AND = `a ∧ b`) — needed to derive which bound value forces a
// standalone loop exit (the §B5 increment-widening termination proof).
struct FusedExit {
  Value *A;
  Value *B;
  bool IsOr;
};
std::optional<FusedExit> decomposeFusedExit(Value *C) {
  if (auto *SI = dyn_cast<SelectInst>(C)) {
    Value *Cnd = SI->getCondition();
    Value *TV = SI->getTrueValue();
    Value *FV = SI->getFalseValue();
    auto *TC = dyn_cast<ConstantInt>(TV);
    auto *FC = dyn_cast<ConstantInt>(FV);
    if (TC && TC->isOne() && !isa<Constant>(FV))
      return FusedExit{Cnd, FV, /*IsOr=*/true};   // select(a, true, b) = a ∨ b
    if (FC && FC->isZero() && !isa<Constant>(TV))
      return FusedExit{Cnd, TV, /*IsOr=*/false};  // select(a, b, false) = a ∧ b
    return std::nullopt;               // 3-operand mux / both-const — not fused.
  }
  if (auto *BO = dyn_cast<BinaryOperator>(C)) {
    bool IsOr = BO->getOpcode() == Instruction::Or;
    if ((IsOr || BO->getOpcode() == Instruction::And) &&
        BO->getType()->isIntegerTy(1)) {
      Value *A = BO->getOperand(0), *B = BO->getOperand(1);
      if (!isa<Constant>(A) && !isa<Constant>(B))
        return FusedExit{A, B, IsOr};
    }
  }
  return std::nullopt;
}

// The exiting block's terminator condition is tainted (a `br`/`switch` on a
// q-derived value). The unit of the multi-site count (B1) and of `taintedExit`.
bool isTaintedExitingTerminator(const Instruction *T, const TaintSet &taint) {
  if (const auto *BI = dyn_cast<BranchInst>(T))
    return BI->isConditional() && taint.Tainted.count(BI->getCondition());
  if (const auto *SI = dyn_cast<SwitchInst>(T))
    return taint.Tainted.count(SI->getCondition());
  return false;
}

// Does any strictly-deeper subloop of `L` contain a tainted value? Such a loop
// is a NESTED quantum loop; a break alongside it crosses loops (B4 — nested-loop
// break is deferred, blocked-on the nested-quantum-loop substrate, §2.7).
bool subloopHasTaintedValue(Loop *L, const TaintSet &taint, LoopInfo &LI) {
  for (BasicBlock *BB : L->blocks()) {
    if (LI.getLoopFor(BB) == L)
      continue;  // a block of L itself — not a subloop block.
    for (Instruction &I : *BB)
      if (taint.Tainted.count(&I))
        return true;
  }
  return false;
}

// (B5, Risk 4) Does `L` have a real, FINITE CLASSICAL TRIP-COUNT bound — i.e. a
// bound that PROVABLY TERMINATES the loop independent of the quantum break?
// ScalarEvolution answers it: `getSymbolicMaxBackedgeTakenCount` is a computable
// SCEV iff SOME exit gives a finite trip count. The quantum break is an opaque
// `SCEVUnknown` (derived from the `cq_*` call results), so SCEV NEVER manufactures
// a finite bound from it — a computable symbolic max therefore means the loop is
// bounded by its CLASSICAL exit (the induction-driven trip count). It correctly
// handles the `-O1` fused `select(brk, true, bound)` / `and`/`or` exit (verified:
// v1_value's select-fused `i != n` bound yields `(-1 + n)`).
//
// This SUBSUMES the earlier UNSOUND structural "the bound *references* the
// induction counter" check (which proved reference, not termination, and so
// mis-recognized a loop-invariant guard `while((q&1)&&(m!=0))` with a dead
// counter, and the clang-realistic wrong-direction `for(i=0;(q&1)&&(i>=start);i++)`
// — the adversarial-review R4 false-accept family 2026-06-25, the seed of an Inc-2
// silent miscompile). SCEV gives those an Unpredictable max ⇒ they ride L1.
//
// HAZARD (the adversarial-review P3 finding 2026-06-26): when the classical bound
// is VACUOUS (always-true), `getSymbolicMaxBackedgeTakenCount` still returns a
// finite max by bounding the loop via the COUNTER'S OWN nsw/nuw OVERFLOW (under
// `llvm.loop.mustprogress`), NOT via any real classical bound — so a genuinely
// quantum-bounded loop is mis-accepted. The single-counter form (`i>=0`) `clang
// -O1` folds away, but a TWO-COUNTER DIVERGING bound (`while((q&1)&&(i<m))` with
// `m` outrunning `i`, so `i<m` is always true) is NOT folded and reaches the pass
// (SCEV max = INT_MAX). This is therefore guarded at the CALL SITE by
// `boundComparesInductionToInvariant` (the bound must compare the counter against a
// loop-INVARIANT limit — a vacuous two-counter / loop-invariant "bound" has none),
// which is the necessary precondition that makes this query sound. Over-declining
// is safe (Prime Directive): if SCEV cannot prove a finite bound, decline.
bool hasFiniteClassicalTripBound(Loop *L, ScalarEvolution &SE) {
  const SCEV *Max = SE.getSymbolicMaxBackedgeTakenCount(L);
  return Max && !isa<SCEVCouldNotCompute>(Max);
}

// (B5, Risk 4) Is the classical bound a REAL counter-vs-fixed-limit comparison —
// exactly ONE operand loop-invariant? This is the necessary precondition that
// closes the `hasFiniteClassicalTripBound` overflow hazard above AND backstops
// `boundProvablyTerminates`. A genuine trip bound compares the induction against a
// loop-INVARIANT limit (`i < n`). A VACUOUS bound that SCEV bounds only by counter
// overflow has either NO loop-invariant operand (a two-counter diverging `i < m`,
// the P3 false-accept) or TWO (a loop-invariant guard `m != 0`, the dead-counter
// family) — both rejected here. Two-counter CONVERGING bounds (rare, e.g.
// `i < j` with `i++`/`j--`) are conservatively declined too (safe — over-declining
// is always safe; distinguishing converging from diverging needs the same
// unreliable two-counter SCEV reasoning the hazard stems from).
bool boundComparesInductionToInvariant(Value *Bound, Loop *L,
                                       ScalarEvolution &SE) {
  auto *Cmp = dyn_cast<ICmpInst>(Bound);
  if (!Cmp)
    return false;
  bool Inv0 = SE.isLoopInvariant(SE.getSCEV(Cmp->getOperand(0)), L);
  bool Inv1 = SE.isLoopInvariant(SE.getSCEV(Cmp->getOperand(1)), L);
  return Inv0 != Inv1;  // exactly one loop-invariant operand (the fixed limit).
}

// (B5 widening — general CLASSICAL increment) A structural termination proof for
// the value-arm break loops `hasFiniteClassicalTripBound` cannot bound. SCEV's
// `getSymbolicMaxBackedgeTakenCount` is INCOMPLETE on the `-O1` `slt`-with-non-unit
// stride fused exit (e.g. `for(i<n;i+=2)` — verified Unpredictable even standalone,
// no quantum break), so a perfectly classically-bounded non-unit-stride break loop
// over-declines. This proves termination directly for a CLASSICAL CONSTANT step
// (the owner's "purely classical increments" scope, 2026-06-26): the bound
// compares a no-wrap induction AddRec (constant non-zero step) against a
// loop-invariant value, and SCEV's own monotonicity oracle (which requires the
// matching no-wrap flag, so a wrapping counter is rejected) proves the bound moves
// the counter toward the loop-exit value.
//
// SOUNDNESS (the Risk-4 boundary — never accept a genuinely quantum-bounded loop):
//   1. The bound must be a STANDALONE terminator — it forces the loop to exit
//      INDEPENDENT of the quantum break. For the `-O1` OR-fused exit (exit-on-true)
//      a true bound forces exit; for the AND-fused continue (exit-on-false) a false
//      bound forces exit (the §1.1 polarity pairing). Any other pairing means the
//      exit depends on the break ⇒ genuinely quantum-bounded ⇒ reject. This makes
//      `BoundExitValue` (the bound value that forces exit) well-defined.
//   2. The bound must monotonically REACH that exit value: `getMonotonicPredicateType`
//      Increasing ⇒ reaches true, Decreasing ⇒ reaches false; terminates iff the
//      reached value IS the exit value (so an always-true `i>=0` exit-on-false, or a
//      wrong-direction compare, is rejected).
// Used only as an OR-fallback to `hasFiniteClassicalTripBound`, so it can only WIDEN
// acceptance — and both disjuncts are independently sound (each proves a finite
// classical trip bound), so the union never accepts a quantum-bounded loop.
bool boundProvablyTerminates(Value *Bound, bool IsOr, bool ExitTakenOnTrue,
                             Loop *L, ScalarEvolution &SE,
                             const TaintSet &taint) {
  auto *Cmp = dyn_cast<ICmpInst>(Bound);
  if (!Cmp)
    return false;
  // The bound value that STANDALONE forces a loop exit (§soundness 1).
  bool BoundExitValue;
  if (IsOr && ExitTakenOnTrue)
    BoundExitValue = true;
  else if (!IsOr && !ExitTakenOnTrue)
    BoundExitValue = false;
  else
    return false;  // exit depends on the break ⇒ not a standalone classical bound.
  // The induction AddRec (constant non-zero step) vs a loop-invariant limit;
  // normalize so the AddRec is the predicate LHS (as getMonotonicPredicateType wants).
  const SCEV *S0 = SE.getSCEV(Cmp->getOperand(0));
  const SCEV *S1 = SE.getSCEV(Cmp->getOperand(1));
  ICmpInst::Predicate Pred = Cmp->getPredicate();
  const auto *AR = dyn_cast<SCEVAddRecExpr>(S0);
  if (AR && AR->getLoop() == L && SE.isLoopInvariant(S1, L)) {
    // AR is already the LHS.
  } else if ((AR = dyn_cast<SCEVAddRecExpr>(S1)) && AR->getLoop() == L &&
             SE.isLoopInvariant(S0, L)) {
    Pred = ICmpInst::getSwappedPredicate(Pred);
  } else {
    return false;  // not a counter-vs-loop-invariant comparison.
  }
  const SCEV *StepS = AR->getStepRecurrence(SE);
  const auto *Step = dyn_cast<SCEVConstant>(StepS);
  if (!Step || Step->getAPInt().isZero())
    return false;  // non-constant or zero (stuck) step — not a classical counter.
  // SCEV strips no-wrap flags from a SHIFTED induction operand (e.g. `i+2` =
  // {2,+,2}<nuw> loses <nsw>), which defeats the signed-predicate monotonicity
  // check; the canonical header induction phi retains both flags. Recover it (the
  // untainted header phi whose AddRec has the SAME step — monotonic direction is
  // step-determined, so any same-step recurrence gives the same answer), falling
  // back to `AR` itself.
  const SCEVAddRecExpr *MonoAR = AR;
  for (PHINode &P : L->getHeader()->phis()) {
    if (taint.Tainted.count(&P))
      continue;
    if (const auto *PAR = dyn_cast<SCEVAddRecExpr>(SE.getSCEV(&P)))
      if (PAR->getLoop() == L && PAR->getStepRecurrence(SE) == StepS) {
        MonoAR = PAR;
        break;
      }
  }
  // SCEV's monotonicity oracle (internally gated on the matching no-wrap flag).
  auto Mono = SE.getMonotonicPredicateType(MonoAR, Pred);
  if (!Mono)
    return false;
  // Increasing ⇒ bound reaches true; Decreasing ⇒ reaches false. Terminates iff
  // the reached value is the exit value (§soundness 2).
  return *Mono == ScalarEvolution::MonotonicallyIncreasing ? BoundExitValue
                                                           : !BoundExitValue;
}

// ── Increment 2 (y05j.2) — the FORWARD TRANSFORM (pre-lowering) ─────────────
//
// A recognized value-arm break loop, EMITTABLE iff it is the proven canonical
// rolled shape, is rewired here (PRE-lowering — it needs pre-RAUW SSA identity
// and must run before `detectControlRegions`/`declineClassicalMuxes`): the rail
// phi collapses to its in-place handle (dtzb), the loop terminator is stripped to
// the CLASSICAL bound (so the rolled loop runs its FULL trip count — never branch
// the CFG on the quantum `%brk`, PRD §2.9), `R`/`idx`/`out` are minted, and the
// exit merge phi is RAUW'd to `out`. The capture + whole-loop reverse-play is
// EMITTED LATER (post-lowering, `lowerBreakReversePlay`) on the lowered body; this
// records the `LoopBreakRegion` it consumes. Returns true iff the transform ran;
// on a non-canonical sub-shape emits `kMsgBreakUnemittable` and returns false
// (the caller still claims the loop — over-declining is safe, Prime Directive).
bool emitBreakForward(LoopBreakRegion &Rgn, TaintSet &taint, WidthDispatch &wd,
                      const SmallPtrSetImpl<CallInst *> &GateCalls,
                      DominatorTree &DT, bool IsOr) {
  BasicBlock *Header = Rgn.Header;
  BasicBlock *Latch = Rgn.Latch;
  auto *BreakI = cast<Instruction>(Rgn.BreakFlag);  // source-locator anchor.
  auto bail = [&]() {
    diagnose(BreakI, kMsgBreakUnemittable);
    return false;
  };

  // (E1) The proven canonical rolled body is a SINGLE block (the `-O1` rotated
  // loop with `header == latch`). A multi-block body is a near-term widening.
  if (Header != Latch)
    return bail();
  // (E2) The canonical fused exit polarity (`select(brk, true, bound)`, exit on
  // true). The continue-polarity / AND-fused twins are recognizer-accepted but
  // not in this increment's proven emission set.
  if (!IsOr || !Rgn.ExitTakenOnTrue)
    return bail();

  // ── Locate the rail header phi (tainted) + the classical counter phi ──────
  // The canonical body carries EXACTLY one tainted (rail) and one untainted
  // (counter) header phi. Anything else is off-shape.
  PHINode *RailPhi = nullptr, *CounterPhi = nullptr;
  for (PHINode &P : Header->phis()) {
    if (taint.Tainted.count(&P)) {
      if (RailPhi)
        return bail();
      RailPhi = &P;
    } else {
      if (CounterPhi)
        return bail();
      CounterPhi = &P;
    }
  }
  if (!RailPhi || !CounterPhi)
    return bail();

  // ── (E3) The counter is a UNIT up-stride induction: latch-incoming = add(i,1)
  Value *CntLat = CounterPhi->getIncomingValueForBlock(Latch);
  auto *CntAdd = dyn_cast_or_null<BinaryOperator>(CntLat);
  if (!CntAdd || CntAdd->getOpcode() != Instruction::Add)
    return bail();
  Value *StepV = CntAdd->getOperand(0) == CounterPhi   ? CntAdd->getOperand(1)
                 : CntAdd->getOperand(1) == CounterPhi ? CntAdd->getOperand(0)
                                                       : nullptr;
  auto *StepCI = dyn_cast_or_null<ConstantInt>(StepV);
  if (!StepCI || !StepCI->isOne())
    return bail();
  Value *INext = CntAdd;  // `i.next` — the bound compares against this.

  // ── (E4) BoundFlag is the canonical `icmp eq i.next, n` (n loop-invariant) ──
  auto *BoundCmp = dyn_cast<ICmpInst>(Rgn.BoundFlag);
  if (!BoundCmp || BoundCmp->getPredicate() != ICmpInst::ICMP_EQ)
    return bail();
  Value *BoundLimit = BoundCmp->getOperand(0) == INext   ? BoundCmp->getOperand(1)
                      : BoundCmp->getOperand(1) == INext ? BoundCmp->getOperand(0)
                                                         : nullptr;
  if (!BoundLimit)
    return bail();
  // The limit `n` must be loop-invariant (not defined in the single body block).
  if (auto *BLI = dyn_cast<Instruction>(BoundLimit))
    if (BLI->getParent() == Header)
      return bail();

  // ── (E5) The rail is a clean in-place VALUE self-cycle rooted at a mint ────
  if (RailPhi->getNumIncomingValues() != 2)
    return bail();
  Value *RailLat = RailPhi->getIncomingValueForBlock(Latch);
  Value *RailPre = nullptr;
  BasicBlock *PreB = nullptr;
  for (unsigned i = 0; i < 2; ++i)
    if (RailPhi->getIncomingBlock(i) != Latch) {
      RailPre = RailPhi->getIncomingValue(i);
      PreB = RailPhi->getIncomingBlock(i);
    }
  if (!RailPre || !PreB)
    return bail();
  if (peelInPlaceBase(RailLat, GateCalls, taint) != RailPhi)
    return bail();  // latch incoming is not a clean self-cycle (X1 dirty rail).
  Value *Root = peelInPlaceBase(RailPre, GateCalls, taint);
  auto *Mint = dyn_cast<CallInst>(Root);
  if (!Mint || !GateCalls.count(Mint) ||
      taint.Tainted.count(Mint->getArgOperand(0)))
    return bail();  // preheader incoming is not a clean classical-operand mint.
  if (!DT.dominates(Mint, Header))
    return bail();

  // ── (E14) NO pre-loop in-place rail mutation: the rail value ENTERING the loop
  // (`RailPre`, the rail phi's PreB-incoming) must BE the bare mint (`Root`). The dtzb
  // collapse RAUWs the rail phi to `Root = peelInPlaceBase(RailPre)`, which peels
  // THROUGH any pre-loop in-place value/rotation mutation (`q = q ^ 7;` or a pre-loop
  // `cq_phi` between the `cq_theta` mint and the loop), and only the IN-LOOP `RailOps`
  // are marked `InPlaceRailOps`. So a pre-loop mutation orphans to a DEAD out-of-place
  // template handle and is NEVER applied to the in-place rail handle — the post-lowering
  // capture (BreakReversePlay.cpp) then copies a rail handle MISSING that mutation into
  // `out` (a VERIFY-CLEAN WRONG UNITARY, off by the pre-loop mutation; on BOTH edges).
  // E13 does NOT catch it (the escape phi legitimately carries `RailPre`, so escape ==
  // rail by VALUE; the divergence is `Root` ≠ `RailPre` at the HANDLE level). Found by
  // the y05j.2 Rule-13 sign-off 2026-06-28. `Root == RailPre` ⟺ `RailPre` is itself the
  // mint (no peel happened). Decline otherwise (Prime Directive — over-declining is
  // safe; applying the pre-loop mutation in-place to the rail handle is a near-term
  // widening, not this increment's proven shape — the canonical `q = cq_theta(); for(…)`
  // has `RailPre == Root == the mint` and still lowers, lowering_loop_break_*).
  if (Root != RailPre)
    return bail();

  // ── (E13) The escaping/measured answer MUST be the loop RAIL ITSELF on BOTH exit
  // edges — `RailLat` (the rail's post-all-mutations value) on the loop-exit/latch edge
  // AND `RailPre` (the rail's pre-loop value) on the zero-trip bypass edge. The
  // post-lowering capture (BreakReversePlay.cpp captureRailToR + emitExitConsolidation)
  // unconditionally copies the in-place RAIL handle into `R` and then into `out` (the
  // RAUW'd escape phi) — for BOTH the broke branches (capture) and the never-broke /
  // zero-trip branches (the `idx==0` consolidation). Nothing upstream ties the escape
  // phi to the rail: E8 PERMITS `RailLat` to have a non-mutation consumer, and E9/E11
  // ADMIT a break-cond-DERIVED value (`t = f(rail)`, e.g. `t = q*7` — `mul` is
  // information-losing so it is NOT a rail op) as a legitimate body value the escape phi
  // may carry; and the phi's zero-trip incoming is entirely unconstrained. If the
  // program measures/returns a derived `t ≠ RailLat` on the loop edge, or a value
  // `≠ RailPre` on the zero-trip edge (`int ans = 999; for(…){…; ans = q; …} measure(ans)`
  // — n==0 returns 999 but the consolidation yields the rail's initial value), `out` is
  // filled with the RAIL instead of the asked-for answer — a VERIFY-CLEAN WRONG UNITARY
  // (the escape≠rail silent miscompile; BOTH edges idiomatic-C-reachable; found by the
  // y05j.2 Rule-13 re-review 2026-06-27, MISSED originally because every fixture/e2e
  // measures `q` itself so escape == rail held by luck on both edges, never by check).
  // Require the escape phi to be exactly two incomings — `RailLat` from `Latch` and
  // `RailPre` from `PreB`; decline otherwise (Prime Directive — over-declining is safe;
  // capturing a derived answer rather than the rail is a near-term widening, not this
  // increment's proven shape). The canonical `return measure(q)` carries `RailLat`/
  // `RailPre` themselves and still lowers (lowering_loop_break_*).
  {
    int LatchIdx = Rgn.EscapePhi->getBasicBlockIndex(Latch);
    int PreBIdx = Rgn.EscapePhi->getBasicBlockIndex(PreB);
    if (Rgn.EscapePhi->getNumIncomingValues() != 2 || LatchIdx < 0 || PreBIdx < 0 ||
        Rgn.EscapePhi->getIncomingValue(LatchIdx) != RailLat ||
        Rgn.EscapePhi->getIncomingValue(PreBIdx) != RailPre)
      return bail();
  }

  // ── (E15) The rail MINT (`Root`, == `RailPre` after E14) must be read ONLY by the
  // rail phi and the escape phi. After the dtzb collapse RAUWs `RailPhi` → `Root` and
  // lowers the in-loop mutations as in-place gates on `Root`'s handle, `Root` IS the
  // LIVE in-place rail handle at every program point — no longer the frozen initial
  // value. So a break-cond that reads the mint (`int q0 = q; … if (q == q0) break;`)
  // lowers to `icmp_eq(h, h)` (rail vs ITSELF, unconditionally true) — a VERIFY-CLEAN
  // WRONG UNITARY decoupling the break decision from the user predicate (found by the
  // y05j.2 Rule-13 sign-off round 3, 2026-06-28). E8 forbids reading `RailPhi` /
  // intermediate `RailOps` and E9 forbids an UNTAINTED header operand, but the mint is
  // TAINTED and preheader-defined, so both skip it. The ONLY legitimate readers of the
  // mint are `RailPhi` (loop-entry incoming) and `Rgn.EscapePhi` (zero-trip incoming —
  // n==0, the rail is unmutated so reading the mint is correct). Any other user (the
  // break-cond, a separate measure of the snapshot) reads the LIVE rail where it means
  // the frozen mint ⇒ decline (Prime Directive — a frozen-mint snapshot needs a
  // separately allocated copy, a near-term widening, not this increment's proven shape).
  for (User *U : Root->users())
    if (U != RailPhi && U != Rgn.EscapePhi)
      return bail();

  // ── (E6) `PreB` (the rail phi's external/entry predecessor — where R/idx/out are
  // minted) MUST dominate the exit merge. R/idx/out are read in the loop AND in the
  // exit merge (the consolidation/copy-out/reverse-play), so their defs must
  // dominate those uses. This holds for the canonical zero-trip guard block (which
  // dominates the bypassing exit edge) but FAILS for a clang-materialized DEDICATED
  // preheader that the zero-trip guard edge bypasses — minting there yields an
  // ill-dominated module (`opt -verify` aborts on valid C; the Rule-13 review
  // 2026-06-26). Decline (Prime Directive — over-declining is safe).
  if (!DT.dominates(PreB, Rgn.ExitMerge))
    return bail();

  // ── (E12) Capture the forward loop's zero-trip ENTRY guard (PreB's conditional
  // branch into the Header) so the reverse-play companion loop can REUSE it. A
  // re-invented signed `sgt(n, 0)` backward guard would be WRONG for an
  // unsigned-bounded loop (`for (unsigned i=0; i<n; i++)`, whose `-O1` entry guard
  // is `icmp eq n, 0` → enter iff `n != 0`): for `n ≥ 2^31` the forward enters +
  // captures while the signed `sgt(n,0)` skips the whole reverse-play → R/idx freed
  // DIRTY (a Rule-6 hidden measurement; the CRITICAL Rule-13 FINAL finding
  // 2026-06-26). Reusing the forward guard makes the backward loop enter iff the
  // forward did, for ANY signedness. Require PreB to end in a conditional branch
  // with the Header as one successor (the canonical guard shape); decline otherwise.
  auto *GuardBr = dyn_cast<BranchInst>(PreB->getTerminator());
  if (!GuardBr || !GuardBr->isConditional())
    return bail();
  bool LoopOnTrue = GuardBr->getSuccessor(0) == Header;
  if (!LoopOnTrue && GuardBr->getSuccessor(1) != Header)
    return bail();  // PreB does not branch directly to the loop header.
  Rgn.GuardCond = GuardBr->getCondition();
  Rgn.GuardLoopOnTrue = LoopOnTrue;

  // ── (E7) The classical counter must START at the constant 0. The reverse-play
  // companion loop replays the body `BoundLimit` (= `n`) times — which equals the
  // forward trip count ONLY when the rolled loop (now bounded by `icmp eq i.next,
  // n`) runs exactly `n` iterations, i.e. the counter starts at 0. A NON-ZERO start
  // (`for (i = 2; i < n; i++)`) makes the forward run `n - start` iterations while
  // the backward runs `n` — an OVER-REPLAY that leaves `fire`/the rail DIRTY at the
  // `cqrt_free` (a hidden measurement, Rule 6 — the CRITICAL Rule-13 finding
  // 2026-06-26). Tie the two trip counts by requiring start == 0; decline otherwise.
  Value *CntStart = CounterPhi->getIncomingValueForBlock(PreB);
  auto *CntStartC = dyn_cast_or_null<ConstantInt>(CntStart);
  if (!CntStartC || !CntStartC->isZero())
    return bail();

  // Collect the rail self-update VALUE ops (the latch→phi chain). Each must be an
  // in-place value bijection (`inPlaceValueRailOperand`); a rotation gate here is
  // a PHASE rail (B3 should have declined — belt-and-suspenders).
  //
  // (E10) Each rail op's CLASSICAL immediate (the non-rail operand) must be
  // loop-INVARIANT (dominate the exit merge — hence the downstream reverse-play
  // block). `dtzb` (commit 32f63df) accepts ANY untainted immediate — incl. a
  // LOOP-VARIANT one (`q ^= i`, or `q = (i&1) ? q^5 : q^3`). The whole-loop
  // reverse-play re-emits the rail-mut adjoint (`cqrt_{xorc,addc}` /
  // `emitInverseCall`) in the post-loop companion block, reusing the FORWARD
  // immediate — a loop-body value there is undefined (a dominance violation /
  // broken module; the Rule-13 review 2026-06-26). A `ConstantInt` / function-arg
  // immediate is not a body Instruction ⇒ passes; a counter-derived immediate
  // declines (Prime Directive — over-declining is safe).
  SmallVector<BinaryOperator *, 4> RailOps;
  for (Value *V = RailLat; V != RailPhi;) {
    auto *BO = dyn_cast<BinaryOperator>(V);
    if (!BO)
      return bail();
    Value *Base = inPlaceValueRailOperand(BO, taint);
    if (!Base)
      return bail();
    Value *Imm = BO->getOperand(0) == Base ? BO->getOperand(1) : BO->getOperand(0);
    if (auto *ImmI = dyn_cast<Instruction>(Imm))
      if (!DT.dominates(ImmI, Rgn.ExitMerge))
        return bail();  // loop-variant immediate — undefined in the reverse-play.
    RailOps.push_back(BO);
    V = Base;
  }
  // Fan-out / linear-lineage (Rule 8): every rail value has AT MOST ONE in-place
  // consumer (else the collapse serializes two mutators onto the one handle — the
  // verify-clean miscompile `loop-rail-inplace-fanout-miscompile`).
  SmallPtrSet<Value *, 8> RailVals;
  RailVals.insert(Root);
  RailVals.insert(RailPhi);
  for (BinaryOperator *BO : RailOps)
    RailVals.insert(BO);
  for (Value *V : RailVals) {
    unsigned InPlace = 0;
    for (User *U : V->users())
      if (auto *BO = dyn_cast<BinaryOperator>(U))
        if (inPlaceValueRailOperand(BO, taint) == V)
          ++InPlace;
    if (InPlace > 1)
      return bail();
  }

  // ── (E8) The break-cond must read the POST-mutation rail value — NOT the rail
  // HEADER PHI (the pre-mutation value). `clang -O1` strength-reduces a relational
  // ADD-rail break (`q = q + c; if (q > K) break;`) into `icmp sgt(headerphi, K-c)`
  // — the break-cond consumes the PRE-increment rail phi directly, while the answer
  // (escape phi) carries the POST value. The dtzb collapse RAUWs the header phi onto
  // the ONE in-place handle, and the `cqrt_addc` mutation runs BEFORE the break-cond
  // template in program order, so the break-cond would read the POST value — firing
  // one iteration early (a verify-clean WRONG UNITARY, off by the stride; the
  // CRITICAL Rule-13 finding 2026-06-26). The pre/post distinction is unrecoverable
  // after the collapse. GUARD: every NON-FINAL rail value — the header phi AND every
  // intermediate mutation result (all but `RailLat = RailOps.front()`, the
  // post-ALL-mutations latch value) — must be consumed ONLY by the in-place
  // mutation chain (`RailOps`). A non-mutation consumer reads the rail at a
  // PRE-FINAL program point; after the collapse RAUWs every rail value onto the ONE
  // handle and the mutations run in order, that consumer reads the FINAL value —
  // covering BOTH the add-relational strength-reduction (break-cond reads the
  // pre-increment header phi) AND a multi-op-chain intermediate read (break-cond
  // reads `q1` of `q1 = q^9; q2 = q1+3`; the Rule-13 RE-review 2026-06-26). ONLY
  // `RailLat` — the value the escape phi carries — may be read by the break-cond.
  // The canonical single-op xor passes (RailPhi's only user is the one mutation).
  SmallPtrSet<const Value *, 4> RailOpSet(RailOps.begin(), RailOps.end());
  auto consumedOnlyByMutations = [&](Value *RV) {
    for (User *U : RV->users())
      if (!RailOpSet.count(U))
        return false;
    return true;
  };
  if (!consumedOnlyByMutations(RailPhi))
    return bail();
  for (BinaryOperator *BO : RailOps)
    if (BO != RailLat && !consumedOnlyByMutations(BO))
      return bail();

  // ── (E9) The break-cond must read ONLY the (post-mutation) rail + loop-INVARIANTS
  // / constants — never the loop counter or another loop-VARIANT value. The backward
  // reverse-play CLONES the break-cond verbatim; a loop-variant operand (the forward
  // counter `%i`, a loop-variant temp) is undefined in the backward companion loop —
  // a dominance violation / broken module (the Rule-13 review 2026-06-26: a
  // `if ((q & i) == 0) break` clone references `%i`, which `opt -verify` rejects).
  // Walk the break flag's lineage: every Header-defined operand must be a rail value
  // (`RailPhi` / a `RailOp` — incl. the post-mutation `RailLat`) or a tainted
  // break-cond op (recurse); an UNTAINTED Header-defined operand (the counter / a
  // loop-variant classical) declines (Prime Directive — over-declining is safe).
  SmallPtrSet<const Value *, 8> BreakCondOps;  // the tainted break-cond chain (E11).
  {
    SmallVector<Value *, 8> Work;
    SmallPtrSet<Value *, 16> Seen;
    Work.push_back(Rgn.BreakFlag);
    Seen.insert(Rgn.BreakFlag);
    while (!Work.empty()) {
      auto *I = dyn_cast<Instruction>(Work.pop_back_val());
      if (!I || I->getParent() != Header)
        continue;  // constant / argument / loop-invariant (defined outside the body).
                   // A loop-INVARIANT comparand (`q == p`, p defined pre-loop) STOPS
                   // the walk here — its lineage is deliberately NOT inspected, and
                   // that is SOUND even when p carries a RELATIVE PHASE (`p =
                   // cq_phi(p0,θ)`, mvrb) or is a DERIVED tainted handle (`p = p0 + 5`,
                   // 1784). The whole break construct (capture + consolidation +
                   // reverse-play, BreakReversePlay.cpp) emits ONLY basis-PERMUTATION
                   // gates — NO Ry/Rz/H inside it (any phase/derivation on p is built
                   // PRE-LOOP, outside the construct). So the construct is a fixed
                   // permutation π: p's amplitudes (incl. its phase) ride INERT, and p
                   // is consumed EXCLUSIVELY as a QQ-compare control (+matched `_unc`)
                   // — never rotated, copied into `out`, measured, or freed. p is
                   // restored exactly and LEFT ALLOCATED (the Rule-6 safe leak;
                   // `isTerminalHandle(p)` is false, so the whole-DAG spine never
                   // recovers it). Cleared by a 5-lens adversarial Rule-13 sign-off
                   // 2026-06-30 (0 holes). CONTRAST B3 (line ~1027), which DOES fence a
                   // phase ESCAPING ANSWER (the rail itself) — there method-B copies
                   // the rail out, and Rule 7's CNOT-copies-a-label-not-a-phase bites;
                   // a phase on the COMPARAND is never copied out, so it does not.
      if (I == RailPhi || RailOpSet.count(I))
        continue;  // a rail value — the break-cond reads the rail (fine; stop here).
      if (!taint.Tainted.count(I))
        return bail();  // a loop-variant CLASSICAL operand (the counter) — its clone
                        // is undefined in the backward companion loop.
      BreakCondOps.insert(I);  // a tainted break-cond op (recorded for E11 coverage).
      for (Value *Op : I->operands())
        if (Seen.insert(Op).second)
          Work.push_back(Op);
    }
  }

  // ── (E11) BODY COVERAGE — every TAINTED value defined in the body block is a rail
  // value (`RailPhi` / a `RailOp`) or a break-cond op (`BreakCondOps`). A STRAY
  // tainted value (a second compare, an extra tainted producer) is off the proven
  // single-rail-single-break shape AND would break the post-lowering structural
  // re-scan (`discoverLoweredBreak`, BreakReversePlay.cpp), whose single-break-flag
  // invariant a second tainted compare violates — leaving the forward-transformed
  // `out` = |0> (a silent wrong answer; the Rule-13 RE-review 2026-06-26). Declining
  // here, BEFORE any mutation, keeps the forward transform and the post-lowering
  // emission in lock-step (Prime Directive — over-declining is safe). The FUSED EXIT
  // condition (`select(brk, true, bound)` / `or`) is tainted (it uses the break flag)
  // and is the loop terminator the forward transform strips — it is part of the
  // recognized shape, NOT a stray (allowed below). A measure of the rail is not a
  // body value (it lives in the exit block).
  Value *FusedCond = cast<BranchInst>(Header->getTerminator())->getCondition();
  for (Instruction &I : *Header) {
    if (I.isTerminator())
      continue;  // the loop's (tainted-condition) exit branch — loop control the
                 // forward transform rewrites, not a stray data value.
    if (!taint.Tainted.count(&I))
      continue;
    if (&I == RailPhi || RailOpSet.count(&I) || BreakCondOps.count(&I) ||
        &I == FusedCond)
      continue;
    return bail();  // a stray tainted body value — not the proven clean shape.
  }

  // ── Width fences (the in-place / copy ABI serves ≤64-bit integers only) ────
  StringRef RailWidth = abiWidthFromType(RailPhi->getType());
  StringRef IdxWidth = abiWidthFromType(CounterPhi->getType());
  if (!wd.allocFn(RailWidth) || !wd.copyFn(RailWidth) || !wd.allocFn(IdxWidth) ||
      !wd.copyFn(IdxWidth))
    return bail();

  // ── ALL preconditions met — MUTATE (the forward transform) ────────────────
  DebugLoc DL = BreakI->getDebugLoc();
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };

  // (1) Mark the rail self-update ops in-place (dtzb) so `lowerOps` emits the
  //     `cqrt_{addc,xorc}_<W>` in-place gate (one rail handle) rather than the
  //     out-of-place template (the X1 fresh-rail-per-iteration dirty rail).
  for (BinaryOperator *BO : RailOps)
    taint.InPlaceRailOps.insert(BO);

  // (2) Mint R / idx / out = |0> before the loop (in the rail phi's external
  //     predecessor, which dominates both the loop and the exit).
  IRBuilder<> PB(PreB->getTerminator());
  Type *RailTy = RailPhi->getType();
  Type *IdxTy = CounterPhi->getType();
  CallInst *RReg =
      PB.CreateCall(wd.allocFn(RailWidth), {ConstantInt::get(RailTy, 0)}, "cq.brk.R");
  CallInst *IdxReg =
      PB.CreateCall(wd.allocFn(IdxWidth), {ConstantInt::get(IdxTy, 0)}, "cq.brk.idx");
  CallInst *OutReg =
      PB.CreateCall(wd.allocFn(RailWidth), {ConstantInt::get(RailTy, 0)}, "cq.brk.out");
  stamp(RReg);
  stamp(IdxReg);
  stamp(OutReg);
  // R/idx/out are pass-invented control scratch (Phase-7.4 owns reversal/leak):
  // join `Tainted` (so downstream keeps them classified as quantum handles) AND
  // `ControlOwnedRails` (so the whole-DAG `uncompute` spine never selects them as
  // terminals — the reverse-play frees R/idx; out escapes via the measure). The
  // rail Root is likewise break-owned (the reverse-play restores it to its
  // pre-loop state, then LEAVES it allocated — a dirty rail is never freed,
  // Rule 6).
  for (Value *H : {static_cast<Value *>(RReg), static_cast<Value *>(IdxReg),
                   static_cast<Value *>(OutReg)}) {
    taint.Tainted.insert(H);
    taint.ControlOwnedRails.insert(H);
  }
  // NB: the rail Root (`cq_theta`) is RAUW'd to its `cqrt_alloc` handle by
  // `lowerRotations`, so inserting it here would go STALE. The rail handle (and
  // every break-body scratch handle) is excluded from the whole-DAG uncompute
  // spine LATER, in the post-lowering `lowerBreakReversePlay`, where the LOWERED
  // i32 handles are live.

  // (3) RAUW the exit merge phi → out, erase it (BEFORE `declineClassicalMuxes`
  //     would flag a tainted merge phi). `out` is |0> now; the post-lowering
  //     copy-out writes the answer into it before the measure reads it.
  Rgn.EscapePhi->replaceAllUsesWith(OutReg);
  taint.Tainted.erase(Rgn.EscapePhi);
  Rgn.EscapePhi->eraseFromParent();

  // (4) Collapse the rail phi → Root (dtzb Case-A style: RAUW + scrub + erase).
  RailPhi->replaceAllUsesWith(Root);
  taint.Tainted.erase(RailPhi);
  RailPhi->eraseFromParent();

  // (5) Strip the quantum break flag from the loop terminator: branch on the
  //     CLASSICAL bound alone, so the rolled loop runs its full trip count (the
  //     break is realized virtually by `idx`, PRD §2.9). Canonical polarity
  //     (IsOr && ExitTakenOnTrue): exit when bound==true. The successor layout is
  //     unchanged (exit at the true edge). Erase the now-dead fused select; the
  //     break-cond compare stays (use-empty now, but `lowerOps` lowers it by
  //     taint membership and the post-lowering capture consumes its handle).
  auto *Term = cast<BranchInst>(Rgn.ExitingBlock->getTerminator());
  Value *Fused = Term->getCondition();
  Term->setCondition(Rgn.BoundFlag);
  if (auto *FusedI = dyn_cast<Instruction>(Fused))
    if (FusedI != Rgn.BoundFlag && FusedI->use_empty())
      FusedI->eraseFromParent();

  // (6) Record the post-lowering-stable region for `lowerBreakReversePlay`.
  Rgn.CounterPhi = CounterPhi;
  Rgn.BoundLimit = BoundLimit;
  Rgn.RReg = RReg;
  Rgn.IdxReg = IdxReg;
  Rgn.OutReg = OutReg;
  Rgn.RailWidth = RailWidth;
  Rgn.IdxWidth = IdxWidth;
  taint.BreakRegions.push_back(Rgn);
  return true;
}

// Try to recognize one natural loop `L` as a single value-arm `break` loop
// (Phase 7.4, epic y05j). Returns true iff `tryBreak` CLAIMS `L` — either the
// recognized value-arm break (interim decline in Inc 1) or one of the off-pattern
// break declines (phase / non-reconverging / multiple-site / nested, §2.10).
// Returns false ⇒ `L` is NOT a recognized break (genuinely quantum-bounded, a
// bare tainted exit, a both-tainted fused exit, or an unproven body) and is left
// for `tryCaseA` — whose L1 `taintedExit` then gives it the existing
// `loop under quantum control` decline (Prime Directive: not-claiming is safe).
//
// Tried BEFORE `tryCaseA` (PRD-7.4 §2.4): a break loop's value-mutating rail is
// NOT a pure in-place persistent accumulator, so `tryCaseA` would otherwise
// X1/L1-decline it before the partition runs. NO mutation, NO emission (Inc 1).
bool tryBreak(Loop *L, Function &F, TaintSet &taint, WidthDispatch &wd,
              const SmallPtrSetImpl<CallInst *> &GateCalls, DominatorTree &DT,
              LoopInfo &LI, ScalarEvolution &SE) {
  (void)F;
  // Only a loop with a tainted EXIT is a break/quantum-bounded candidate; a
  // classical-exit loop is `tryCaseA`/Case-B territory (leave it).
  if (!taintedExit(L, taint))
    return false;

  // (Multi-site, B1) Count tainted exiting blocks. >1 ⇒ multiple early-break
  // sites (v3_multi) — INTERIM decline, accepted in Inc 3 (§2.7). Checked first:
  // the index-latch generalization is orthogonal to the single-break mechanism.
  SmallVector<BasicBlock *, 4> Exiting;
  L->getExitingBlocks(Exiting);
  unsigned TaintedExiting = 0;
  Instruction *TheExitT = nullptr;
  BasicBlock *TheExitB = nullptr;
  for (BasicBlock *EB : Exiting)
    if (isTaintedExitingTerminator(EB->getTerminator(), taint)) {
      ++TaintedExiting;
      TheExitT = EB->getTerminator();
      TheExitB = EB;
    }
  if (TaintedExiting > 1) {
    diagnose(TheExitT, kMsgBreakMultiSite);
    return true;
  }

  // Exactly one tainted exiting block. Inc-1 lowers only the FUSED conditional
  // branch (a tainted `switch` break is not in the proven set — ride L1).
  auto *BI = dyn_cast<BranchInst>(TheExitT);
  if (!BI || !BI->isConditional())
    return false;
  BasicBlock *S0 = BI->getSuccessor(0), *S1 = BI->getSuccessor(1);
  bool In0 = L->contains(S0), In1 = L->contains(S1);
  if (In0 == In1)
    return false;  // not exactly one in-loop / one exit successor — unproven.
  bool ExitTakenOnTrue = !In0;  // the exit successor is the false edge iff In0.

  // (Non-reconverging, B2) The break and the natural exit must converge to ONE
  // loop-exit block. `getUniqueExitBlock()` is null when the loop has multiple
  // DISTINCT exit blocks (v4_nonreconv: the break edge and the bound edge reach
  // different blocks) ⇒ DEFER decline (§2.7). NB: `getUniqueExitBlock` (not
  // `getExitBlock`) — the latter returns null even for repeat exit EDGES to one
  // shared block, over-declining genuinely-reconverging two-edge loops (the
  // adversarial-review getExitBlock-vs-getUniqueExitBlock note 2026-06-25).
  BasicBlock *ExitBlk = L->getUniqueExitBlock();
  if (!ExitBlk) {
    diagnose(TheExitT, kMsgBreakNonReconv);
    return true;
  }

  // (B1) Decompose the `-O1` fused exit into {break flag, classical bound}. A
  // bare tainted icmp (no fused classical bound — v5_qbound) or a 3-operand mux
  // returns nullopt ⇒ NOT a break: leave it for L1 (genuinely quantum-bounded).
  auto Pair = decomposeFusedExit(BI->getCondition());
  if (!Pair)
    return false;
  Value *A = Pair->A, *B = Pair->B;
  bool TA = taint.Tainted.count(A), TB = taint.Tainted.count(B);
  // The load-bearing partition (Risk 4): EXACTLY one disjunct tainted (the break
  // flag) and the other CLASSICAL (the loop bound). Both tainted ⇒ no classical
  // fall-through ⇒ genuinely quantum-bounded; neither ⇒ not a tainted exit. Both
  // ride L1 (return false).
  if (TA == TB)
    return false;
  Value *BreakFlag = TA ? A : B;
  Value *BoundFlag = TA ? B : A;
  // The break flag must be a stock comparison on a tainted value (a clean
  // single-condition break); a compound tainted disjunct (a nested select/or)
  // is not in the Inc-1 proven set — ride L1.
  if (!isa<ICmpInst>(BreakFlag) && !isa<FCmpInst>(BreakFlag))
    return false;
  Instruction *BreakI = cast<Instruction>(BreakFlag);  // source-locator anchor.

  // (B4, nested) `L` inside another loop, or wrapping a tainted subloop ⇒ the
  // break crosses loops (v6_nested) — DEFER, blocked-on the nested-quantum-loop
  // substrate (§2.7). Checked once the break shape is confirmed (a quantum-
  // bounded nested loop must stay L1, not be relabeled "nested break").
  if (L->getParentLoop() || subloopHasTaintedValue(L, taint, LI)) {
    diagnose(BreakI, kMsgBreakNested);
    return true;
  }

  // (B2) The single exit block must carry exactly one TAINTED merge phi — the
  // escaping answer. Zero / multiple tainted phis is not the clean single-answer
  // reconvergence (ride L1).
  PHINode *EscapePhi = nullptr;
  for (PHINode &P : ExitBlk->phis())
    if (taint.Tainted.count(&P)) {
      if (EscapePhi)
        return false;  // >1 tainted exit phi — unproven.
      EscapePhi = &P;
    }
  if (!EscapePhi)
    return false;

  // (B3) Value-class answer. A phase-class escaping answer (an Rz/`cq_phi` in any
  // incoming lineage — v2_phase) cannot be CNOT-copied out (Rule 7 dephases) and
  // the data-comparison phase break is degenerate ⇒ PERMANENT decline (§2.6).
  for (Value *In : EscapePhi->incoming_values())
    if (taint.Tainted.count(In) && breakLineageCarriesPhase(In, taint)) {
      diagnose(BreakI, kMsgBreakPhase);
      return true;
    }

  // (B5, Risk 4) A proven 7.3 rolled loop with a REAL, PROVABLY-FINITE CLASSICAL
  // TRIP-COUNT bound: single latch, and ScalarEvolution must prove the loop
  // terminates classically (a computable symbolic max backedge-taken count). A
  // loop whose only real termination is the quantum break — whether via a
  // loop-invariant guard (`while((q&1)&&(m!=0))`, dead counter) or a non-bounding
  // counter comparison (always-true `i>=0`, wrong-direction `i>k`, unreachable
  // `i==-1`, identity `i+=0`) — has an UNPREDICTABLE max and must ride L1, NOT be
  // recognized as a value-arm break (the adversarial-review R4 false-accept family
  // 2026-06-25 — the seed of an Inc-2 silent miscompile; the proof lands here in
  // Inc-1 recognition, not Inc 2). SCEV's termination reasoning is the sound proof
  // a structural "bound references the counter" check cannot give.
  BasicBlock *Latch = L->getLoopLatch();
  if (!Latch)
    return false;
  BasicBlock *Header = L->getHeader();
  // The classical bound must compare the induction against a loop-INVARIANT limit
  // (Risk 4 — the necessary precondition that makes the SCEV symbolic-max proof
  // sound against the P3 two-counter-diverging / vacuous-bound overflow hazard).
  if (!boundComparesInductionToInvariant(BoundFlag, L, SE))
    return false;
  // Then EITHER the SCEV symbolic-max proof (fast path; handles eq/unit-stride/
  // downward, incl. the select-fused exit) OR the structural classical-constant-step
  // termination proof (the increment widening — covers the `slt`-non-unit-stride
  // shapes SCEV's symbolic-max leaves Unpredictable). Both prove a finite classical
  // trip bound; with the loop-invariant-limit guard the union never accepts a
  // genuinely quantum-bounded loop (Risk 4).
  if (!hasFiniteClassicalTripBound(L, SE) &&
      !boundProvablyTerminates(BoundFlag, Pair->IsOr, ExitTakenOnTrue, L, SE,
                               taint))
    return false;

  // (B4, body) No OTHER tainted control (a nested diamond/switch beyond the break
  // exit) and no tainted-index memory in the body — those are the existing 7.3
  // L2/L3 owners' (ControlDetect / kMsgQramLoop). Their presence means the body
  // is not the proven invertible single-break shape (ride L1).
  for (BasicBlock *BB : L->blocks()) {
    Instruction *T = BB->getTerminator();
    if (T != TheExitT && isTaintedExitingTerminator(T, taint))
      return false;  // a second tainted br/switch (non-exiting control) in body.
    if (auto *BrI = dyn_cast<BranchInst>(T))
      if (T != TheExitT && BrI->isConditional() &&
          taint.Tainted.count(BrI->getCondition()))
        return false;
    if (auto *SwI = dyn_cast<SwitchInst>(T))
      if (T != TheExitT && taint.Tainted.count(SwI->getCondition()))
        return false;
    for (Instruction &I : *BB) {
      if (isa<GetElementPtrInst>(I) || isa<LoadInst>(I) || isa<StoreInst>(I))
        for (Value *Op : I.operands())
          if (taint.Tainted.count(Op))
            return false;  // tainted-index memory — the kMsgQramLoop owner's.
      // An OBSERVABLE / IRREVERSIBLE body op — a `cq_measure` (Rule 5: the
      // compiler must NEVER emit a measurement the user did not write — and the
      // rolled break runs the body its FULL trip count AND the reverse-play
      // replays it, so an in-body measure would fire ~2n times at the wrong
      // place), or any side-effecting call / volatile-atomic store (a global /
      // I/O effect the full-trip + reverse-play replay would multiply). The
      // break virtualization (PRD §2.9) is sound ONLY for a pure-coherent body;
      // such an op rides L1 (`loop under quantum control`). The canonical
      // value-arm break body is pure arithmetic + phis (the rail mint lives in
      // the preheader), so this never over-declines it (the Rule-13 FINAL review
      // 2026-06-26).
      if (!I.isTerminator() && I.mayHaveSideEffects())
        return false;
    }
  }

  // KNOWN Inc-1 coverage limitation (DECLINE-SAFE — rides L1, not a miscompile;
  // for Inc 2 to widen, NOT a bug to mistake for a quantum-bound classification
  // error): a CONSTANT-bound break (`for(i<8)…break`). `clang -O1` drops the
  // zero-trip guard for a provably-≥1-trip constant bound, so the exit block has a
  // SINGLE predecessor and NO merge phi — the escaping value is consumed directly,
  // and the (B2) `EscapePhi==null` check declines. (A runtime bound keeps the guard
  // ⇒ the merge phi ⇒ recognized — the v1 canonical case.) Inc 2 may fall back to
  // the directly-escaping value when the exit block has one predecessor.
  // (The earlier non-unit-stride gap is CLOSED by the §B5 increment widening above.)
  //
  // RECOGNIZED single value-arm break. Run the FORWARD TRANSFORM (Inc 2, y05j.2):
  // collapse the rail, strip the terminator to the classical bound, mint
  // `R`/`idx`/`out`, RAUW the exit phi → `out`, and record the `LoopBreakRegion`
  // the post-lowering `lowerBreakReversePlay` consumes to emit the index-gated
  // capture + whole-loop reverse-play. `emitBreakForward` declines LOUDLY
  // (`kMsgBreakUnemittable`) for a recognized-but-non-canonical sub-shape; either
  // way the loop is CLAIMED here (NOT mis-declined as the L1 quantum-bounded loop,
  // Risk 4). `kMsgBreakPending` is retired (emission now lands).
  LoopBreakRegion R;
  R.L = L;
  R.Header = Header;
  R.Latch = Latch;
  R.ExitMerge = ExitBlk;
  R.ExitingBlock = TheExitB;
  R.BreakFlag = BreakFlag;
  R.BoundFlag = BoundFlag;
  R.EscapePhi = EscapePhi;
  R.ExitTakenOnTrue = ExitTakenOnTrue;
  emitBreakForward(R, taint, wd, GateCalls, DT, Pair->IsOr);
  return true;
}

// Try to recognize + collapse one natural loop `L` as Case A (in-place
// persistent accumulator). Returns true iff a Case-A collapse (or a LOUD
// X1/Q1 decline) was performed; false ⇒ `L` is left untouched for its existing
// owner (Prime Directive — claim only what is proven).
bool tryCaseA(Loop *L, Function &F, TaintSet &taint,
              const SmallPtrSetImpl<CallInst *> &GateCalls, DominatorTree &DT,
              LoopInfo &LI) {
  // (L1) Quantum/measurement-bounded exit ⇒ permanent decline (§2.6). Checked
  //      FIRST and BEFORE `detectControlRegions`, so Q1 gets the dedicated
  //      `loop under quantum control` message rather than the generic
  //      `nested control flow…` ControlDetect would otherwise emit.
  if (Instruction *TE = taintedExit(L, taint)) {
    diagnoseUnderControl(TE, "loop");
    return true;
  }

  // (L2) Tainted control INSIDE the body (a non-exiting tainted `br`/`switch` —
  // a loop-resident diamond/if-else/switch). 7.3 does NOT lower control-in-loop
  // (§2.8): leave the loop unclaimed so the existing `ControlDetect` /
  // `RegionTreeDetect` owner declines it (`nested control flow under quantum
  // control`, the backedge guard `RegionTreeDetect.cpp`). Crucially this runs
  // BEFORE the X1 header-phi analysis below, so a control-merge latch phi (a
  // tainted nested-diamond merge feeding the backedge) is left for that owner
  // rather than mis-declined as a cross-iteration dirty value rail.
  for (BasicBlock *BB : L->blocks()) {
    Instruction *T = BB->getTerminator();
    if (auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
        return false;
    } else if (auto *SI = dyn_cast<SwitchInst>(T)) {
      if (taint.Tainted.count(SI->getCondition()))
        return false;
    }
  }

  BasicBlock *Header = L->getHeader();
  BasicBlock *Latch = L->getLoopLatch();
  // Require a single latch — the `-O1` shape (verified). NOTE: a rotated `-O1`
  // loop has a GUARD branch (`if (n>0) goto loop`) as its entry predecessor,
  // which is NOT a dedicated preheader (it has two successors), so
  // `getLoopPreheader()` returns null here — the header phi's external
  // (non-latch) incoming is identified directly from its incoming blocks below.
  // A multi-latch loop is an unproven shape; leave it (conservative).
  if (!Latch)
    return false;

  // railRoot maps every value on a recognized persistent rail to its single
  // root mint (a classical-operand `cq_theta`). Seeded from the clean
  // self-cycle header phis; expanded to a fixpoint over in-place gates and
  // single-root phis below.
  DenseMap<Value *, Value *> railRoot;
  for (PHINode &P : Header->phis()) {
    if (!taint.Tainted.count(&P))
      continue;  // classical induction phi — not a rail.
    // The header phi must have exactly two incomings: one from the latch (the
    // back edge) and one EXTERNAL (the entry/guard edge from outside L). A phi
    // with extra edges (an irreducible / multi-entry shape) is unproven.
    if (P.getNumIncomingValues() != 2)
      return false;  // unproven multi-edge header phi — leave it.
    Value *LatV = nullptr;
    Value *PreV = nullptr;
    for (unsigned i = 0; i < 2; ++i) {
      BasicBlock *IB = P.getIncomingBlock(i);
      if (IB == Latch)
        LatV = P.getIncomingValue(i);
      else if (!L->contains(IB))
        PreV = P.getIncomingValue(i);  // the external (entry) edge.
    }
    if (!PreV || !LatV)
      return false;  // not the clean latch + external-entry pair.
    // (Risk 2) The latch incoming must peel — through IN-PLACE gates ONLY —
    // back to the header phi itself (a closed self-cycle ⇒ a single persistent
    // rail). A latch that peels to a fresh value-op rail (a `cq_template_*`
    // accumulator, X1) is a cross-iteration dirty rail: LOUD decline, never a
    // silent collapse of a loop-variant handle.
    if (peelInPlaceBase(LatV, GateCalls, taint) != &P) {
      // X1 only when the latch carries a genuine tainted dirty rail across the
      // backedge (an `acc=acc+q` fresh-rail accumulator). A header phi we cannot
      // classify either way is left for downstream (conservative).
      Value *LatBase = peelInPlaceBase(LatV, GateCalls, taint);
      if (taint.Tainted.count(LatBase)) {
        diagnose(&P, kMsgCrossIter);
        return true;
      }
      return false;
    }
    // The preheader incoming must peel to a classical-operand `cq_theta` MINT
    // that dominates the loop (the rail origin).
    Value *Root = peelInPlaceBase(PreV, GateCalls, taint);
    auto *Mint = dyn_cast<CallInst>(Root);
    if (!Mint || !GateCalls.count(Mint) ||
        taint.Tainted.count(Mint->getArgOperand(0)))
      return false;  // preheader incoming is not a clean rail mint.
    if (!DT.dominates(Mint, Header))
      return false;
    railRoot[Root] = Root;
    railRoot[&P] = Root;
  }
  if (railRoot.empty())
    return false;  // no persistent rail — Case B / other, not Inc 1.

  // Fixpoint expansion: an in-place gate on a rail value joins the SAME rail; a
  // tainted phi ALL of whose incomings peel to one common root joins that root
  // (the zero-trip/exit merge phi and any inner renaming). A phi whose incomings
  // peel to TWO distinct roots is a cross-rail merge — not clean; bail.
  SmallVector<Value *, 16> Work;
  for (auto &KV : railRoot)
    Work.push_back(KV.first);
  bool PhiAdded = true;
  while (PhiAdded) {
    // (a) drain the in-place-gate worklist. An in-place gate on a rail value V
    // joins V's rail: a rotation gate (`isInPlaceGateOnArg0`, the 7.3 vocabulary)
    // OR a value self-update (`inPlaceValueRailOperand(BO) == V`, issue dtzb —
    // `cqrt_{addc,xorc}` mutates the one rail handle in place, so its result is
    // the same rail).
    while (!Work.empty()) {
      Value *V = Work.pop_back_val();
      Value *R = railRoot[V];
      for (User *U : V->users()) {
        bool InPlace = false;
        if (auto *CI = dyn_cast<CallInst>(U))
          InPlace = isInPlaceGateOnArg0(CI, V, GateCalls, taint);
        else if (auto *BO = dyn_cast<BinaryOperator>(U))
          InPlace = inPlaceValueRailOperand(BO, taint) == V;
        if (!InPlace)
          continue;
        auto *I = cast<Instruction>(U);
        auto It = railRoot.find(I);
        if (It == railRoot.end()) {
          railRoot[I] = R;
          Work.push_back(I);
        } else if (It->second != R) {
          return false;  // a gate result claimed by two rails — not clean.
        }
      }
    }
    // (b) one phi-scan pass: add any tainted phi now fully resolved to one root.
    PhiAdded = false;
    for (BasicBlock &BB : F)
      for (PHINode &P : BB.phis()) {
        if (railRoot.count(&P) || !taint.Tainted.count(&P))
          continue;
        Value *Common = nullptr;
        bool Ok = true, Touches = false;
        for (Value *V : P.incoming_values()) {
          Value *Base = peelInPlaceBase(V, GateCalls, taint);
          auto It = railRoot.find(Base);
          if (It == railRoot.end()) {
            Ok = false;
            break;
          }
          Touches = true;
          if (!Common)
            Common = It->second;
          else if (Common != It->second) {
            Ok = false;  // merges two distinct rails — not a clean renaming.
            break;
          }
        }
        if (Ok && Touches && Common) {
          railRoot[&P] = Common;
          Work.push_back(&P);
          PhiAdded = true;
        }
      }
  }

  // FAN-OUT / linear-lineage guard (Rule 8 no-cloning; the Rule-13 adversarial
  // review 2026-06-26 found this verify-clean over-accept). A rail value may have
  // AT MOST ONE forward IN-PLACE consumer (a single linear chain). MORE than one
  // is FAN-OUT: the rail value is read by two in-place mutators that the collapse
  // would both serialize onto the ONE rail handle — corrupting both (e.g. `%qn =
  // q^9` carried + `%qm = q^3` escaping ⇒ `xorc(h,9); xorc(h,3)` ⇒ measures
  // `q^9^3`, not the source's `q^3`; the rotation twin `rz(h,1); rz(h,2)` = Rz(3)
  // ≠ the source's Rz(2)). In-place mutation needs LINEAR lineage; a fan-out of a
  // superposed source needs an ancilla/`cqrt_cswap`, not in-place collapse. The
  // count covers BOTH gate kinds — value self-updates (dtzb add/xor) AND rotations
  // (cq_phi/rz, the SHARED pre-dtzb gap) — so the same guard closes both. Loud
  // decline (claimed), never a silent serialized collapse (Prime Directive).
  //
  // COUNTED VIA `railValueConsumerDisposition` (bd 8h7d.5 Rule-13 round 4, OD-A)
  // — the ONE spelling of "will this BO be lowered in place", shared with round 2
  // and with `collectRailGates`. `Claimed` is `railRoot`, and HERE the question
  // is a NO-OP by construction: the (a)/(b) fixpoint above has already absorbed
  // every in-place BO consumer of a rail value into `railRoot`, so every op this
  // guard could count is `InPlace`. It is threaded through anyway so the two
  // rounds cannot drift apart on the predicate again (Rule 14) — and pinned by
  // `control_swap_inloop_range_cond.ll`'s round-1 twin `@range_cond_no_control`,
  // which must keep declining.
  SmallPtrSet<const Value *, 32> Round1Claimed;
  for (auto &KV : railRoot)
    Round1Claimed.insert(KV.first);
  for (auto &KV : railRoot) {
    SmallVector<Instruction *, 2> InPlaceUsers;
    for (User *U : KV.first->users()) {
      if (auto *CI = dyn_cast<CallInst>(U)) {
        if (isInPlaceGateOnArg0(CI, KV.first, GateCalls, taint))
          InPlaceUsers.push_back(CI);
      } else if (auto *BO = dyn_cast<BinaryOperator>(U)) {
        if (railValueConsumerDisposition(BO, KV.first, taint, Round1Claimed) >
            RailValueUse::OutOfPlace)
          InPlaceUsers.push_back(BO);  // `Unproven` counts — see the enum's note.
      }
    }
    if (InPlaceUsers.size() > 1) {
      diagnose(InPlaceUsers.front(), kMsgRailFanout);
      return true;  // recognized but unlowerable fan-out — loud decline.
    }
  }

  // COVERAGE: every tainted value whose innermost loop is exactly `L` must be on
  // a rail (else there is a value op / control / memory in the body — not pure
  // Case A; leave it for Inc 2 / the existing owners). A tainted instruction in
  // a strictly-deeper subloop is NOT this loop's to classify.
  for (BasicBlock *BB : L->blocks()) {
    if (LI.getLoopFor(BB) != L)
      continue;  // a subloop block — owned by the inner loop's pass.
    for (Instruction &I : *BB) {
      if (!taint.Tainted.count(&I))
        continue;
      if (isMeasureCall(&I))
        continue;  // a sink reading the rail — fine.
      if (!railRoot.count(&I))
        return false;  // an uncovered tainted body value — not pure Case A.
    }
  }

  // CLOSURE: every user of a rail value is an in-place gate / phi on the rail, a
  // measure sink, or an escape (`ret`). ANY other consumer — a value-op
  // template producer, a tainted control compare, a store, an unknown call, or
  // the rail used as a classical ANGLE (arg-1) — means the rail is not isolated;
  // leave it (the consumer's own guard declines loudly downstream).
  for (auto &KV : railRoot) {
    Value *V = KV.first;
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        continue;
      if (railRoot.count(I) || isMeasureCall(I) || isa<ReturnInst>(I))
        continue;
      // An in-place gate on the rail whose result is itself a rail is in
      // railRoot (handled above). Anything else is an out-of-rail consumer.
      return false;
    }
  }

  // RECORD LIVENESS (bd 8h7d.5 Rule-13 round 1, finding F1). CLOSURE above
  // admits a `cq_measure` / `ret` user of a rail value at ANY position, and that
  // admission was itself a silent miscompile: `for (…) { last = q; q += off; }
  // return cq_measure(last);` emitted `measure(h)` AFTER the loop and measured
  // `q0+3k` where the source says `q0+3(k-1)`. The one out-of-loop rail read that
  // is sound is the state the register actually holds at the exit; the fence
  // decides that POSITIONALLY (see `staleRailRecordRead`) rather than by naming a
  // member, because in an unrotated loop the header phi IS that state.
  //
  // Asked PER RAIL — a gate on a sibling rail mutates another wire and says
  // nothing about this record — and LOUDLY: no other owner catches it (measured;
  // the round-1 shape above compiled clean at ba35c1f), so falling through to
  // `declineClassicalMuxes` is not available here.
  {
    // Grouped in PROGRAM ORDER, from the function rather than from `railRoot`.
    // This loop DIAGNOSES, and `railRoot` is a `DenseMap` whose pointer-hashed
    // iteration order would make WHICH offending consumer gets named (and which
    // `!dbg` location the error carries) vary between runs on the same module.
    // The DECISION was deterministic either way — any offender declines — but a
    // wandering source location is exactly the kind of thing that reads as a
    // flaky test later. `MapVector` keeps the root order stable too; round 2's
    // chains are already built in a deterministic order.
    MapVector<Value *, SmallVector<Value *, 8>> ByRoot;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto It = railRoot.find(&I);
        if (It != railRoot.end())
          ByRoot[It->second].push_back(&I);
      }
    for (auto &KV : ByRoot)
      if (Instruction *Bad = staleRailRecordRead(KV.second, GateCalls, taint)) {
        diagnose(Bad, kMsgRailRecordStale);
        return true;  // recognized but unlowerable record escape — loud decline.
      }
  }

  // ACCEPT. Issue dtzb — mark each IN-PLACE VALUE rail self-update so `lowerOps`
  // emits the in-place `cqrt_{addc,xorc}_<W>(handle, imm)` (not the out-of-place
  // `cq_template_<op>_<W>_hl` that mints a fresh per-iteration rail). Rotation
  // gates need NO marking: `lowerRotations` already lowers them in place. Only
  // BinaryOperator rail members exist via `inPlaceValueRailOperand`, so every one
  // is a proven value self-update; mark before the phi collapse erases nothing it
  // depends on (marking only records the op, never mutates it). The op's result
  // goes use-empty after the collapse, but `lowerOps` collects it by taint
  // membership (not use-count) and emits the side-effecting in-place gate.
  for (auto &KV : railRoot)
    if (auto *BO = dyn_cast<BinaryOperator>(KV.first))
      taint.InPlaceRailOps.insert(BO);

  // Collapse every rail PHINode to its root. RAUW to the root mint (the
  // still-pre-lowering `cq_theta` SSA value, SAME type as the phi — no ill-typed
  // `phi double` survives, Risk 5; rotation lowering later maps root→%h). Scrub
  // each erased phi from `Tainted` (the `scrubTaint` precedent) and erase after
  // ALL RAUWs so inter-phi references resolve cleanly.
  SmallVector<PHINode *, 4> Collapse;
  for (auto &KV : railRoot)
    if (auto *P = dyn_cast<PHINode>(KV.first))
      Collapse.push_back(P);
  for (PHINode *P : Collapse)
    P->replaceAllUsesWith(railRoot[P]);
  for (PHINode *P : Collapse) {
    taint.Tainted.erase(P);
    P->eraseFromParent();
  }
  return true;
}

// Increment 2 (799w.2) — Case B: mark a loop whose every tainted value is an
// ITERATION-LOCAL born-and-dies temporary, so the Phase-5 uncompute spine
// recovers each temp's DAG IN-BODY (once per iteration) instead of declining
// (FreePoint kMsgLoopBackedge) or leaking. Pure analysis; the ONLY effect is
// inserting `L`'s blocks into `taint.IterationLocalBlocks` (no mutation). Called
// only when `tryCaseA` left the loop unclaimed.
//
// A loop qualifies iff: classical exit (L1 — a tainted exit was already declined
// Q1 by `tryCaseA`); no tainted control (L2) / tainted-index memory (L3) in the
// body; and every tainted value is iteration-local — NO tainted header phi (no
// loop-carried persistent rail; that is Case A or X1), every tainted value
// DEFINED in L is USED only in L (nothing escapes the loop), and every tainted
// OPERAND of an in-L instruction is DEFINED in L (no loop-invariant tainted input
// minted outside, whose register would accumulate across iterations — the
// `lowering_uncompute_loop_backedge` residual). The spine then PROVES per-DAG
// closure/measure/escape; this predicate only certifies the loop is a sound place
// to lift the backedge guard (Prime Directive: not-marking is always safe).
void markIfIterationLocal(Loop *L, TaintSet &taint, LoopInfo &LI) {
  if (taintedExit(L, taint))
    return;  // Q1 quantum-bounded — never Case B.
  BasicBlock *Header = L->getHeader();
  bool AnyTainted = false;
  for (BasicBlock *BB : L->blocks()) {
    // (L2) tainted control in the body ⇒ the existing ControlDetect owner's.
    Instruction *T = BB->getTerminator();
    if (auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
        return;
    } else if (auto *SI = dyn_cast<SwitchInst>(T)) {
      if (taint.Tainted.count(SI->getCondition()))
        return;
    }
    if (LI.getLoopFor(BB) != L) {
      // A strictly-deeper SUBLOOP with quantum content is a NESTED quantum loop,
      // not a single-level iteration-local loop: a value rotated by the subloop
      // runs the subloop-trip-count times PER outer iteration, but the spine
      // would reverse it ONCE (a dirty free of an under-reversed rail — a SILENT
      // miscompile, confirmed on a do-while inner loop whose body dominates the
      // outer recovery point, so the divergent-arm backstop does not catch it).
      // Decline to mark (Prime Directive: over-declining is safe — the value's
      // terminal then keeps FreePoint's `kMsgLoopBackedge` reject). 7.3 does not
      // lower nested quantum loops; the subloop is handled (or declined) on its
      // own, never folded into the outer iteration-local set.
      for (Instruction &I : *BB)
        if (taint.Tainted.count(&I))
          return;
      continue;
    }
    for (Instruction &I : *BB) {
      // (L3) tainted-index memory in the body ⇒ the existing kMsgQramLoop owner's.
      if (isa<GetElementPtrInst>(I) || isa<LoadInst>(I) || isa<StoreInst>(I))
        for (Value *Op : I.operands())
          if (taint.Tainted.count(Op))
            return;
      const bool TI = taint.Tainted.count(&I);
      // A tainted HEADER phi is a loop-carried persistent rail (Case A / X1),
      // not an iteration-local temp.
      if (TI && isa<PHINode>(I) && BB == Header)
        return;
      if (TI) {
        AnyTainted = true;
        // Every tainted value defined in L must be used ONLY in L (nothing
        // escapes the loop — the last iteration's value never reads downstream).
        for (User *U : I.users())
          if (auto *UI = dyn_cast<Instruction>(U))
            if (!L->contains(UI->getParent()))
              return;
      }
      // Every tainted OPERAND must be defined in L — a tainted value minted
      // OUTSIDE L and read inside (loop-invariant) is a persistent register that
      // accumulates across iterations, NOT iteration-local.
      for (Value *Op : I.operands())
        if (taint.Tainted.count(Op)) {
          auto *OpI = dyn_cast<Instruction>(Op);
          if (!OpI || !L->contains(OpI->getParent()))
            return;
        }
    }
  }
  if (!AnyTainted)
    return;  // a purely-classical loop — leave it byte-identical.
  for (BasicBlock *BB : L->blocks())
    taint.IterationLocalBlocks.insert(BB);
}

}  // namespace

// Shared with the Lever-B force-unroll pre-pass (LoopUnrollPrepass.cpp, ticket
// lf8s — fence U4; contract in LoopPlan.h). Lives HERE so the disjointness gate
// calls the very predicates `tryCaseA` claims with (`inPlaceValueRailOperand`,
// `peelInPlaceBase`) instead of a re-implementation that could drift (Rule 14).
bool loopHasInPlaceRailStructure(
    Loop *L, const TaintSet &taint,
    const SmallPtrSetImpl<CallInst *> &GateCalls) {
  // (a) A tainted in-place-shaped `add`/`xor` self-update ANYWHERE in the loop
  // (dtzb). Even one whose rail lives OUTSIDE `L` matters: unrolling would
  // duplicate it, flipping the sibling rail's linear-lineage fan-out count
  // (the kMsgRailFanout guard) — over-skipping here is the safe direction.
  for (BasicBlock *BB : L->blocks())
    for (Instruction &I : *BB)
      if (auto *BO = dyn_cast<BinaryOperator>(&I))
        if (inPlaceValueRailOperand(BO, taint))
          return true;
  // (b) A tainted header phi whose latch incoming peels in-place back to the
  // phi itself — the Case-A claim seed (`tryCaseA` Risk 2), including the
  // zero-hop identity carry `phi [x, pre], [%self, latch]` that (a) misses.
  BasicBlock *Latch = L->getLoopLatch();
  if (!Latch)
    return true;  // multi-latch: unproven shape — report rail-structured.
  for (PHINode &P : L->getHeader()->phis()) {
    if (!taint.Tainted.count(&P))
      continue;
    for (unsigned i = 0, e = P.getNumIncomingValues(); i != e; ++i)
      if (P.getIncomingBlock(i) == Latch &&
          peelInPlaceBase(P.getIncomingValue(i), GateCalls, taint) == &P)
        return true;
  }
  return false;
}

namespace {

// ── bd test_C_libtooling-8h7d.5 (7.3 Inc 3) — ROUND 2: the post-flatten rail ──
//
// Contract + rationale in LoopPlan.h. This is the analysis for ONE loop; it
// reuses `peelInPlaceBase` / `isInPlaceGateOnArg0` / `inPlaceValueRailOperand`
// and the two shipped diagnostics rather than re-spelling any of them (Rule 14),
// so the round-1 and round-2 readings of "a persistent in-place rail" cannot
// drift.
//
// TRI-STATE, not a bool (bd 8h7d.5 Rule-13 round 1). The caller must be able to
// tell a DECLINE from a COLLAPSE: `markIfRailLocal` grants the spine a permission
// to discharge inside the body, and granting it on top of a loud decline is
// bookkeeping on a module that will never be emitted. The pre-round-1 spelling
// returned `true` for both and the caller marked either way.
enum class RailRound2 { NotClaimed, Declined, Collapsed };

RailRound2 collapseRailPhisIn(Loop *L, Function &F, TaintSet &taint,
                              const SmallPtrSetImpl<CallInst *> &GateCalls,
                              DominatorTree &DT,
                              SmallPtrSetImpl<Value *> &RootsOut) {
  BasicBlock *Header = L->getHeader();
  BasicBlock *Latch = L->getLoopLatch();
  if (!Latch)
    return RailRound2::NotClaimed;  // multi-latch — unproven, as round 1 (Risk 2).

  // (1) Recognise every collapsible rail phi. PURE ANALYSIS — no mutation until
  //     the whole header has been classified, so an inter-phi reference cannot
  //     read an already-erased phi (the round-1 `Collapse` precedent).
  DenseMap<PHINode *, Value *> Collapse;    // phi → root mint
  SmallVector<Value *, 8> RailMembers;      // every value on an accepted chain
  // The SAME members, grouped PER PHYSICAL WIRE — i.e. keyed on the ROOT MINT,
  // which is exactly one `cqrt_alloc` (rotation lowering RAUWs every member of a
  // root's chain to that one handle). The fan-out guard below is per value and
  // does not care; the F1 record-liveness fence does, in BOTH directions:
  //   * two chains rooted at DIFFERENT mints are two registers, and one's gates
  //     must never stale the other's record — that is what makes two independent
  //     registers with their own tainted `if`s in one loop lowerable;
  //   * two chains rooted at the SAME mint are ONE register wearing two SSA names
  //     (`int a = q, b = q;` — an alias, never a copy; Rule 8), so each one's
  //     gates DO stale the other's records and the two must be merged.
  // Keying on the root is the only spelling that gets both, and it is the same
  // grouping round 1 uses (`ByRoot` over `railRoot`) — Rule 14, ONE predicate
  // asked twice, not two that agree today.
  MapVector<Value *, SmallVector<Value *, 8>> ChainsByRoot;
  for (PHINode &P : Header->phis()) {
    if (!taint.Tainted.count(&P))
      continue;  // classical induction phi — not a rail.
    if (P.getNumIncomingValues() != 2)
      continue;  // multi-entry header phi — leave it (declineClassicalMuxes).
    Value *LatV = nullptr, *PreV = nullptr;
    for (unsigned i = 0; i < 2; ++i) {
      BasicBlock *IB = P.getIncomingBlock(i);
      if (IB == Latch)
        LatV = P.getIncomingValue(i);
      else if (!L->contains(IB))
        PreV = P.getIncomingValue(i);  // the external (entry/guard) edge.
    }
    if (!PreV || !LatV)
      continue;  // not the clean latch + external-entry pair.

    // (Risk 2, verbatim from round 1) The latch incoming must peel — through
    // IN-PLACE gates ONLY — back to the phi itself: a CLOSED self-cycle, i.e.
    // one persistent rail whose handle is the same qubit every iteration. A
    // latch that peels to a fresh value-op rail is X1, the cross-iteration
    // dirty rail, and it declines LOUDLY here rather than silently collapsing a
    // loop-variant handle.
    if (peelInPlaceBase(LatV, GateCalls, taint) != &P) {
      Value *LatBase = peelInPlaceBase(LatV, GateCalls, taint);
      if (taint.Tainted.count(LatBase)) {
        diagnose(&P, kMsgCrossIter);
        return RailRound2::Declined;
      }
      continue;  // unclassifiable either way — leave it for the mux guard.
    }
    // The external incoming must peel to a classical-operand `cq_theta` MINT
    // that dominates the loop (the rail origin) — the value every rail member
    // RAUWs onto at rotation lowering, and therefore the only sound collapse
    // target.
    Value *Root = peelInPlaceBase(PreV, GateCalls, taint);
    auto *Mint = dyn_cast<CallInst>(Root);
    if (!Mint || !GateCalls.count(Mint) ||
        taint.Tainted.count(Mint->getArgOperand(0)))
      continue;  // not a clean rail mint — leave it.
    if (!DT.dominates(Mint, Header))
      continue;

    // Collect the chain members (root → … → PreV → phi → … → LatV) so the
    // fan-out guard and the in-place marking below see every one of them.
    // Walked with `peelInPlaceStep` — the SAME edges `peelInPlaceBase` walked to
    // prove the two endpoints above, so the enumeration cannot run past the base
    // and cannot disagree with the proof it is enumerating (Rule 14). Both walks
    // TERMINATE: each step ascends the arg-0 / rail-operand def chain, which is
    // acyclic in SSA outside phis, and a phi ends the walk (`peelInPlaceStep`
    // returns null for it).
    SmallVector<Value *, 8> Chain;
    Chain.push_back(&P);
    for (Value *V = LatV; V != &P;) {
      Chain.push_back(V);
      Value *Next = peelInPlaceStep(V, GateCalls, taint);
      if (!Next)
        break;  // cannot happen (the peel above reached `&P`); defensive.
      V = Next;
    }
    for (Value *V = PreV; V != Root;) {
      Chain.push_back(V);
      Value *Next = peelInPlaceStep(V, GateCalls, taint);
      if (!Next)
        break;  // cannot happen (the peel above reached `Root`); defensive.
      V = Next;
    }
    Chain.push_back(Root);
    RailMembers.append(Chain.begin(), Chain.end());
    auto &Merged = ChainsByRoot[Root];
    Merged.append(Chain.begin(), Chain.end());
    Collapse[&P] = Root;
    RootsOut.insert(Root);
  }
  if (Collapse.empty())
    return RailRound2::NotClaimed;

  // (2) FAN-OUT / linear-lineage guard (Rule 8 no-cloning) — the SAME guard
  //     round 1 applies, for the same reason: a rail value read by TWO in-place
  //     mutators would have both serialised onto the one handle, corrupting
  //     both (`rz(h,1); rz(h,2)` = Rz(3), not the source's Rz(2)). The emitted
  //     region stream is NOT counted here and must not be: `cqrt_cswap` /
  //     `cq_template_*` are not in `GateCalls` (which holds only the collected
  //     front-end `@cq_theta`/`@cq_phi` sites) and are not `BinaryOperator`s, so
  //     `isInPlaceGateOnArg0` / `inPlaceValueRailOperand` reject them by
  //     construction — a route puts the value on a work rail and brings it back,
  //     it does not mutate the lineage.
  //
  //     A `BinaryOperator` CONSUMER IS COUNTED ONLY IF IT WILL ACTUALLY BE
  //     LOWERED IN PLACE (bd 8h7d.5 Rule-13 ROUND 4, finding OD-A) — the
  //     `railValueConsumerDisposition` question, shared with round 1 and with
  //     `collectRailGates` (Rule 14). Asking the dtzb SHAPE alone counted a
  //     DERIVED-CONDITION temp: `clang -O1` canonicalizes the owner's own
  //     `if (q > 5 && q < 20)` to `%t = add %q, -6; icmp ult %t, 14`, and `%t`
  //     was tallied beside the arm's real `cq_phi` — a loud `kMsgRailFanout` on a
  //     program whose hand-unrolled twin compiles. `%t` is inside the loop body
  //     and is neither a chain member nor marked, so M-C's G5 refuses it OUTRIGHT
  //     and `lowerOps` mints it a fresh rail; it never touches the loop-carried
  //     register and was never a second mutator.
  //
  //     THE ORDERING IS WHY `Claimed` EXISTS. This guard runs BEFORE step (3)
  //     marks, so `taint.InPlaceRailOps` is still empty for this loop; passing
  //     `RailMembers` (exactly what step (3) will mark) makes the answer
  //     order-independent. A member is `InPlace`; an off-chain in-loop BO is
  //     `OutOfPlace`; an off-chain STRAIGHT-LINE BO stays `Unproven` and is still
  //     counted, because M-C genuinely does fire post-loop (probe r3h/b4) and
  //     no one here can predict G6/G7. Prime Directive: only the case with a
  //     PROOF is dropped.
  SmallPtrSet<const Value *, 32> Claimed(RailMembers.begin(), RailMembers.end());
  for (Value *V : RailMembers) {
    SmallVector<Instruction *, 2> InPlaceUsers;
    for (User *U : V->users()) {
      if (auto *CI = dyn_cast<CallInst>(U)) {
        if (isInPlaceGateOnArg0(CI, V, GateCalls, taint))
          InPlaceUsers.push_back(CI);
      } else if (auto *BO = dyn_cast<BinaryOperator>(U)) {
        if (railValueConsumerDisposition(BO, V, taint, Claimed) >
            RailValueUse::OutOfPlace)
          InPlaceUsers.push_back(BO);  // `Unproven` counts — see the enum's note.
      }
    }
    if (InPlaceUsers.size() > 1) {
      diagnose(InPlaceUsers.front(), kMsgRailFanout);
      return RailRound2::Declined;  // unlowerable fan-out — loud decline.
    }
  }

  // (2b) RECORD LIVENESS (bd 8h7d.5 Rule-13 round 1, finding F1) — THE HALF THIS
  //      ROUND SHIPPED WITHOUT. Round 1's COVERAGE/CLOSURE is deliberately not
  //      re-proved here (see LoopPlan.h: the post-flatten body legitimately
  //      contains the region's own emitted stream and a derived condition's
  //      iteration-local rails, which CLOSURE would refuse). But CLOSURE was
  //      carrying TWO obligations, not one, and only the first is inapplicable:
  //        (i) "every tainted body value is on the rail" — a CLAIM condition,
  //            about whether round 1 may own the loop. Not ours; dropped, rightly.
  //       (ii) "a rail record is only read where the register still holds it" —
  //            a UNITARY condition, and it is exactly as binding after the
  //            flatten as before it. Dropping it made
  //            `for (…) { if (q==5) q=cq_phi(q,PI); acc = q*7; q += 3; }` emit
  //            the `mul` in the EXIT block against the post-loop register: a
  //            different unitary, `opt` exit 0, verify-clean, stage-2b clean.
  //      Asked PER ROOT MINT (`ChainsByRoot`) — one root is one `cqrt_alloc`, one
  //      physical wire — and that grouping is load-bearing in BOTH directions: a
  //      gate on a DIFFERENT root's rail relabels another register and must not
  //      stale this record (else two independent registers in one loop are
  //      permanently unlowerable, control_swap_inloop_two_registers.ll), while two
  //      chains sharing ONE root are one register wearing two SSA names and MUST
  //      interfere (lowering_reject_inloop_rail_alias_shared_mint.ll — which the
  //      fan-out guard cannot catch, because it counts in-place users PER VALUE
  //      and the shared mint's users there are the phis).
  //      RUNS AFTER the fan-out guard so the Rule-8 message keeps its programs.
  for (auto &KV : ChainsByRoot)
    if (Instruction *Bad = staleRailRecordRead(KV.second, GateCalls, taint)) {
      diagnose(Bad, kMsgRailRecordStale);
      return RailRound2::Declined;
    }

  // (3) Issue dtzb — MARK EVERY IN-PLACE VALUE RAIL SELF-UPDATE, exactly as
  //     round 1 does, and this line is NOT optional bookkeeping: it is what makes
  //     the collapse SOUND for a rail carrying `q += c`.
  //
  //     MEASURED SILENT MISCOMPILE WHEN IT IS MISSING (found 2026-08-29 while
  //     re-measuring `example/grover/grover_loop_frontier.c` with only the
  //     in-loop offsets removed — `opt` exit 0, verify-clean, strict
  //     free-pairing CLEAN, and the only outward sign was one M-A WARNING).
  //     `a = cq_theta(a,.5); a += cq_off;` before a loop puts the `add` on the
  //     rail's PRE-header chain, so the header phi's external incoming peels
  //     THROUGH it to the mint — and collapsing the phi to that mint RAUW's every
  //     in-loop use to the PRE-OFFSET handle. `lowerOps` then emits the add
  //     out-of-place into a fresh rail nothing reads, and the whole loop computes
  //     on `a`, not on `a + off`. The wrong unitary, with the right shape.
  //
  //     Marking records the op only (no mutation). The op's result goes use-empty
  //     after the collapse; `lowerOps` collects it by TAINT MEMBERSHIP, not use
  //     count, and emits the side-effecting in-place `cqrt_{addc,xorc}_<W>`.
  //     Rotation gates need no marking (`lowerRotations` already lowers in place).
  for (Value *V : RailMembers)
    if (auto *BO = dyn_cast<BinaryOperator>(V))
      taint.InPlaceRailOps.insert(BO);

  // Snapshot each rail's GATES and SURVIVING members before step (4) erases the
  // header phis — step (5) needs both and the phis will be gone. Gates are
  // `cq_theta` calls and in-place `add`/`xor`, none of which the collapse erases.
  DenseMap<Value *, SmallPtrSet<const Instruction *, 8>> GatesByRoot;
  DenseMap<Value *, SmallPtrSet<const Value *, 16>> LiveByRoot;
  for (auto &KV : ChainsByRoot) {
    collectRailGates(KV.second, GateCalls, taint, GatesByRoot[KV.first]);
    for (Value *V : KV.second)
      if (!isa<PHINode>(V))
        LiveByRoot[KV.first].insert(V);
  }

  // (4) Collapse. RAUW each rail phi to its root mint (the still-pre-lowering
  //     `cq_theta` SSA value, SAME type — no ill-typed phi survives) and erase
  //     after ALL RAUWs so inter-phi references resolve cleanly. This is exactly
  //     what rotation lowering would produce anyway (every in-place gate RAUWs
  //     its result to its arg-0 handle, so the phi would degenerate to
  //     `phi [%h, pre], [%h, latch]`); doing it HERE is what keeps the emitted
  //     stream identical to the hand-unrolled twin's and the loop ROLLED.
  for (auto &KV : Collapse)
    KV.first->replaceAllUsesWith(KV.second);
  for (auto &KV : Collapse) {
    taint.Tainted.erase(KV.first);
    taint.BirthOrder.erase(KV.first);
    KV.first->eraseFromParent();
  }

  // (5) A tainted phi ELSEWHERE whose every incoming now peels to the SAME root
  //     is a pure renaming of that rail (the rotated-loop exit/LCSSA merge, and
  //     any inner router the flatten left behind). Collapse it too — round 1's
  //     fixpoint (b) makes the identical claim. A phi mixing two roots, or one
  //     with an incoming off every rail, is LEFT for `declineClassicalMuxes`.
  for (bool Grew = true; Grew;) {
    Grew = false;
    SmallVector<std::pair<PHINode *, Value *>, 4> More;  // phi → its one root
    for (BasicBlock &BB : F)
      for (PHINode &P : BB.phis()) {
        if (!taint.Tainted.count(&P))
          continue;
        Value *Common = nullptr;
        bool Ok = true;
        for (Value *V : P.incoming_values()) {
          Value *Base = peelInPlaceBase(V, GateCalls, taint);
          bool OnRail = false;
          for (auto &KV : Collapse)
            if (Base == KV.second)
              OnRail = true;
          if (!OnRail) {
            Ok = false;
            break;
          }
          if (!Common)
            Common = Base;
          else if (Common != Base) {
            Ok = false;  // merges two distinct rails — not a clean renaming.
            break;
          }
        }
        if (Ok && Common)
          More.push_back({&P, Common});
      }
    // The SAME record-liveness fence, on the phis this fixpoint is about to
    // claim (bd 8h7d.5 Rule-13 round 1, finding F1 — completing its own edit).
    // A step-(5) phi is a pure RENAMING of the rail, so its consumers are rail
    // reads exactly like a chain member's, and they get the identical treatment:
    // the phi's own value is a faithful name for the register only where no rail
    // gate separates the two. Reached as a USER of the chain, each of these phis
    // was already cleared by (2b); this clears its CONSUMERS.
    //
    // It costs the shipped set nothing and is the reason: the `-O1` zero-trip
    // guard's exit phi (`phi [PreV, guard], [LatV, latchexit]`, the shape
    // slice_control_grover_loop_dynamic hands the pass) sits after the loop with
    // no rail gate below it, so `railGateBetween` is false and it collapses as
    // before.
    for (auto &KV : More) {
      auto GIt = GatesByRoot.find(KV.second);
      auto LIt = LiveByRoot.find(KV.second);
      if (GIt == GatesByRoot.end() || LIt == LiveByRoot.end())
        continue;  // not one of this round's roots — nothing snapshotted.
      SmallPtrSet<const Value *, 16> Skip(LIt->second);
      Skip.insert(KV.first);
      if (Instruction *Bad =
              staleReadOfValue(KV.first, Skip, GIt->second, GateCalls, taint)) {
        diagnose(Bad, kMsgRailRecordStale);
        return RailRound2::Declined;
      }
    }
    // `Common` DOMINATES every use of `P`: each incoming peels to it, so it
    // dominates every incoming definition, hence every predecessor of `P`'s
    // block, hence that block — so the RAUW is well-formed without a re-check.
    for (auto &KV : More) {
      KV.first->replaceAllUsesWith(KV.second);
      taint.Tainted.erase(KV.first);
      taint.BirthOrder.erase(KV.first);
      KV.first->eraseFromParent();
      Grew = true;
    }
  }
  return RailRound2::Collapsed;
}

// ── bd test_C_libtooling-8h7d.5 — the Case-B twin for a loop WITH a rail ─────
//
// `markIfIterationLocal` (Increment 2, 799w.2) certifies a loop in which EVERY
// tainted value is born and dies inside one iteration, and it refuses — by
// design — a loop that reads a tainted value minted OUTSIDE it. That refusal is
// exactly right for the shape it was written for and exactly wrong here: after
// the round-2 collapse the loop reads ONE loop-invariant tainted value, the
// PERSISTENT QUBIT RAIL, and its whole point is to persist. Without a marking
// the spine takes its §2.9 acyclic backstop (`InLoop && !IterLocal → return`,
// Uncomputation.cpp) and LEAKS the condition chain's rails once per iteration —
// measured on the customer program: three `cq_template_*` rails allocated and
// never uncomputed, never freed, where the hand-unrolled twin reverses and frees
// all three. A leak is not a miscompile, but it is a DIFFERENT CIRCUIT from the
// cleared unrolled one, and "the rolled trace equals the unrolled trace" is this
// increment's load-bearing witness.
//
// So: the same certificate, with the rail carved out and NOTHING else.
//   * a value ON the rail (it peels to a collapsed root) is exempt from the
//     escape check — it is the register, owned by the user's `cq_measure`, and it
//     is never a recovered DAG terminal (its def is OUTSIDE the loop, so
//     `FreePoint`'s `TermIterLocal` is false for it and the ordinary
//     Measured/Escaped path still decides it);
//
//     READ THAT EXEMPTION WITH ITS PROOF, NOT AS A PREMISE. This header used to
//     say a rail value "may be read from ANYWHERE and used ANYWHERE — it is the
//     register", and that sentence was FALSE and load-bearing (bd 8h7d.5 Rule-13
//     round 1, finding F1). A rail SSA name denotes one prefix of the rail's gate
//     sequence; it is a faithful name for the register only at positions where
//     the register still holds that prefix. `for (…) { if (q==5) q=cq_phi(q,PI);
//     acc = q*7; q += 3; }` reads it one `addc` too late and computes a different
//     unitary, `opt` exit 0 and stage-2b clean. The exemption is sound HERE only
//     because `collapseRailPhisIn` step (2b) has already PROVEN, for every rail
//     VALUE and every consumer, that no rail-relabelling gate separates the
//     record from its read (`staleRailRecordRead`) — and it declines loudly
//     otherwise, before this function is ever called. It is a conclusion, not an
//     axiom, and it must not outlive that call order. "Every rail VALUE" is the
//     word this sentence needed and did not have until bd 8h7d.5 Rule-13 ROUND 3
//     (finding F-3): it said "every rail MEMBER", and the fence really did only
//     enumerate chain members, so a record one hop off the chain was exempted
//     from a proof this exemption claims to rest on. Both halves are fixed —
//     `staleRailRecordRead` now enumerates the rail's closure, so the premise
//     stated here is the premise actually discharged;
//   * every OTHER tainted value must be defined in `L` and used only in `L` —
//     the unchanged iteration-local obligation;
//   * a tainted OPERAND that is neither on the rail nor defined in `L` is the
//     accumulating loop-invariant register the original guard was protecting
//     against, and still refuses the marking.
// The L2 (tainted control), L3 (tainted-index memory), subloop and
// tainted-header-phi refusals are copied VERBATIM — a surviving tainted header
// phi in particular means the collapse did NOT claim this rail, so nothing here
// may assume one.
//
// Marking is a PERMISSION, not a proof, and both consumers re-verify it:
// `Uncomputation` re-confirms every recovered gate sits in a marked block and
// `FreePoint` re-confirms the insertion point is in-body. Not marking is always
// safe (the leak); this predicate only ever grants.
void markIfRailLocal(Loop *L, TaintSet &taint, LoopInfo &LI,
                     const SmallPtrSetImpl<CallInst *> &GateCalls,
                     const SmallPtrSetImpl<Value *> &Roots) {
  if (Roots.empty())
    return;
  if (taintedExit(L, taint))
    return;  // Q1 quantum-bounded — never markable.
  BasicBlock *Header = L->getHeader();
  // `AsLowered` — the FACT-time peel (see `peelInPlaceStep`). Everything this
  // lambda is asked is asked AFTER `collapseRailPhisIn` step (3) has marked every
  // chain member `InPlaceRailOps`, and BOTH of its jobs need the fact rather than
  // the shape: it decides which values are iteration-local TEMPS (whose escape
  // must be checked) and which are THE REGISTER (exempt, because `cq_measure`
  // owns it). A `%t = add %q, -6` derived-condition temp is a temp; peeling it by
  // shape called it the register, silently exempting it AND leaving `AnyLocal`
  // false so the body was never marked at all.
  auto onRail = [&](Value *V) {
    return Roots.count(peelInPlaceBase(V, GateCalls, taint,
                                       /*AsLowered=*/true)) != 0;
  };
  bool AnyLocal = false;
  for (BasicBlock *BB : L->blocks()) {
    Instruction *T = BB->getTerminator();
    if (auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
        return;  // (L2) tainted control still standing — not ours.
    } else if (auto *SI = dyn_cast<SwitchInst>(T)) {
      if (taint.Tainted.count(SI->getCondition()))
        return;
    }
    if (LI.getLoopFor(BB) != L) {
      // A strictly-deeper SUBLOOP with quantum content runs its gates N times
      // per outer iteration while the spine would reverse them ONCE — the
      // under-reversed dirty free. Verbatim from `markIfIterationLocal`.
      for (Instruction &I : *BB)
        if (taint.Tainted.count(&I))
          return;
      continue;
    }
    for (Instruction &I : *BB) {
      if (isa<GetElementPtrInst>(I) || isa<LoadInst>(I) || isa<StoreInst>(I))
        for (Value *Op : I.operands())
          if (taint.Tainted.count(Op))
            return;  // (L3) tainted-index memory — the kMsgQramLoop owner's.
      const bool TI = taint.Tainted.count(&I) != 0;
      if (TI && isa<PHINode>(I) && BB == Header)
        return;  // an unclaimed loop-carried rail — the collapse did not run.
      if (TI && !onRail(&I)) {
        AnyLocal = true;
        for (User *U : I.users())
          if (auto *UI = dyn_cast<Instruction>(U))
            if (!L->contains(UI->getParent()))
              return;  // an iteration-local temp escaping the loop.
      }
      for (Value *Op : I.operands())
        if (taint.Tainted.count(Op)) {
          auto *OpI = dyn_cast<Instruction>(Op);
          if (!OpI)
            return;
          if (!L->contains(OpI->getParent()) && !onRail(Op))
            return;  // an accumulating loop-invariant tainted input.
        }
    }
  }
  if (!AnyLocal)
    return;  // a pure-rail loop (no temps) — nothing for the spine to place.
  // ONLY `L`'s OWN blocks (bd 8h7d.5 Rule-13 round 1, finding P2). `L->blocks()`
  // includes every strictly-deeper SUBLOOP block, and the subloop refusal above
  // only inspects `taint.Tainted` membership — which the region emitters' own
  // output (`cqrt_cswap`, `cqrt_x`, the `_unc` strips) is never in, because they
  // are void calls minted after propagation. So a subloop carrying an EMITTED
  // stream would be certified iteration-local while running its gates N times per
  // outer iteration, and the spine would reverse them ONCE: the under-reversed
  // dirty free (Rule 6). Unreachable today — every nested-loop probe declines
  // earlier, at `ControlDetect::flatRegionRollableInLoop` gate (B) (one depth) or
  // at the subloop refusal above — which is exactly why it is closed structurally
  // rather than left to the guard that cannot see it. `markIfIterationLocal`
  // (Increment 2) has the identical `L->blocks()` shape but is NOT changed here:
  // its own refusal covers every tainted value, and it has no post-flatten
  // emitted stream to miss.
  for (BasicBlock *BB : L->blocks())
    if (LI.getLoopFor(BB) == L)
      taint.IterationLocalBlocks.insert(BB);
}

}  // namespace

void collapseFlattenedLoopRails(Module &M, TaintSet &taint) {
  // Round-2 TRIGGER: only a module in which an in-loop tainted-control region
  // was actually emitted + flattened. Everything else is byte-identical, which
  // is what keeps the 250-odd shipped e2e goldens untouched by this increment.
  if (taint.InLoopFlattenedPreds.empty())
    return;

  SmallPtrSet<CallInst *, 32> GateCalls;
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Rebuild DT/LI on the POST-FLATTEN CFG (Rule 11/9 — the round-1 trees are
    // long invalid; the flatten spliced and erased blocks).
    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;
    for (Loop *L : LI.getLoopsInPreorder()) {
      bool Touched = false;
      for (BasicBlock *BB : L->blocks())
        if (taint.InLoopFlattenedPreds.count(BB))
          Touched = true;
      if (!Touched)
        continue;  // a loop this increment did not open — leave it untouched.
      SmallPtrSet<Value *, 4> Roots;
      // Mark ONLY after a real collapse. A DECLINE means `opt` will exit
      // non-zero, and handing the spine an in-body discharge permission for a
      // module that is never emitted is bookkeeping on a corpse (bd 8h7d.5
      // Rule-13 round 1); a NotClaimed loop keeps its pre-existing owner.
      if (collapseRailPhisIn(L, F, taint, GateCalls, DT, Roots) ==
          RailRound2::Collapsed)
        markIfRailLocal(L, taint, LI, GateCalls, Roots);
    }
  }
}

void lowerLoops(Module &M, WidthDispatch &wd, TaintSet &taint) {
  // The collected rotation call sites — the in-place-gate wire vocabulary the
  // peel + closure consult (same seed as `declineClassicalMuxes`).
  SmallPtrSet<CallInst *, 32> GateCalls;
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Cheap skip: a function with no tainted value has no quantum loop.
    bool AnyTainted = false;
    for (Value *V : taint.Tainted)
      if (auto *I = dyn_cast<Instruction>(V))
        if (I->getFunction() == &F) {
          AnyTainted = true;
          break;
        }
    if (!AnyTainted)
      continue;

    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;
    // ScalarEvolution (built standalone from DT/LI, the same direct-construction
    // idiom as DT/LI) proves the §2.5 B5 finite classical trip bound for the
    // `tryBreak` recognizer (Risk 4). A default `TargetLibraryInfoImpl` is a
    // conservative TLI — sufficient for SCEV's trip-count reasoning.
    AssumptionCache AC(F);
    TargetLibraryInfoImpl TLII(Triple(M.getTargetTriple()));
    TargetLibraryInfo TLI(TLII);
    ScalarEvolution SE(F, TLI, AC, DT, LI);
    // Recognition is pure analysis on the still-unmutated IR; the only mutation
    // is the Case-A phi collapse inside `tryCaseA`, which erases phis (the CFG —
    // blocks + edges — is untouched, so `LI`/`DT` stay valid across loops). A
    // loop `tryCaseA` does not claim (Case A collapse / Q1 / X1) is offered to
    // the Case-B iteration-local recognizer (Increment 2), which only marks
    // blocks for the spine — never mutates.
    //
    // `tryBreak` (Phase 7.4, epic y05j) is tried FIRST (§2.4): a single value-arm
    // break loop's value-mutating rail is not a pure in-place accumulator, so
    // `tryCaseA` would X1/L1-decline it before the value-arm-vs-quantum-bounded
    // partition runs. Inc-1 `tryBreak` is pure analysis (recognition + decline),
    // no mutation — so `LI`/`DT` stay valid for the `tryCaseA` fallthrough.
    for (Loop *L : LI.getLoopsInPreorder()) {
      if (tryBreak(L, F, taint, wd, GateCalls, DT, LI, SE))
        continue;
      if (!tryCaseA(L, F, taint, GateCalls, DT, LI))
        markIfIterationLocal(L, taint, LI);
    }
  }
}

}  // namespace cq
