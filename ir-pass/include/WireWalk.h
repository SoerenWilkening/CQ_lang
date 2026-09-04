// WireWalk.h — Shared forward in-place-gate wire walk (Rule 14: one walker,
// two guards).
//
// The physical "wire" of a tainted SSA value is the chain of IN-PLACE gates
// that take it (or a value it routes into) as their arg-0 handle: a
// `cq_phi_*` (Rz) user is DIAGONAL — basis-preserving, the walk continues
// through its result on the same wire — while a `cq_theta_*` (Ry) user is
// NON-DIAGONAL: it rotates the wire's computational basis in place, so any
// later basis read of the wire no longer matches an SSA value defined before
// the theta (the stale-record / verify-clean-miscompile family; bd memory
// rz-diag-flag-strip-invariant, MINT_AT_COMPARE.md §4 "position is not
// provenance"). Position of PURE instructions proves nothing (Rule 9 — LLVM
// schedules them freely with the SSA graph unchanged); opaque `cq_*` calls DO
// keep their order, so the wire itself, plus dominance over the opaque calls,
// is the only reliable evidence.
//
// Two consumers, two modes:
//   * POSITION-FREE (`EmitPoint` null) — the detection-time guards
//     (ArmClassify::wireGainsNonDiagonalGate + the value-arm routed-base
//     check, SwitchClassify G10, SwitchArmProve's routed base, SelectClassify
//     GATE 2c): ANY theta user on the guarded wire declines the region (the
//     flag/route mint would read a post-Ry basis; over-decline accepted as
//     safe — Prime Directive).
//   * POSITION-AWARE (`EmitPoint` + `DT` given) —
//     OpcodeLowering::declineStaleRecordOps: a theta is harmless iff it is
//     PROVABLY emitted after every execution of the op's template
//     (`DT->dominates(EmitPoint, T)` — every path to T already executed the
//     template — AND `!isPotentiallyReachable(T, EmitPoint)` — once T fired,
//     the template never re-executes, closing the loop-iteration-2
//     staleness).
//
// `CrossValueRouting` (PHINode / select value-operand edges — they route the
// SAME physical handle, so a theta behind them is still an in-place gate on a
// wire the seed may denote) is TRUE at EVERY caller since bd tayx
// (2026-07-03). The old router-blind detection mode was justified by "a
// PHI-mediated post-region theta is unreachable by design", which covered
// post-region routing only: a chained theta reaching the wire through a
// PRE-compare one-register router phi was probe-proven to evade the
// position-free guards on the phase-diamond, phase-switch, and select paths
// (verify-clean stale flag mints; kjd1 clearance E1/E4 + bd tayx; fixtures
// control_swap_reject_stalecond_router_diamond.ll,
// control_swap_reject_switch_stalecond_router.ll,
// control_swap_reject_select_stalecond_phi_routed.ll). The flag is retained
// in the signature for the walk's semantics, not as a live policy choice.

#ifndef CQ_IRPASS_WIRE_WALK_H_
#define CQ_IRPASS_WIRE_WALK_H_

#include "llvm/ADT/ArrayRef.h"

namespace llvm {
class CallInst;
class DominatorTree;
class Instruction;
class PHINode;
class Value;
}  // namespace llvm

namespace cq {

// Walk the forward in-place-gate wire of every value in `Seeds` and return
// the first `cq_theta_*` user found whose Ry is NOT provably after every
// execution of `EmitPoint` (see header comment for the exact proof
// obligation). With `EmitPoint == nullptr` the walk is position-free: any
// theta on the wire is returned. Returns nullptr when the wire gains no
// (relevant) non-diagonal gate. `DT` must be non-null whenever `EmitPoint`
// is. Pure analysis — mutates nothing (Rule 9).
//
// Each seed is first CLOSED BACKWARD, PER SEED, through diagonal `cq_phi`
// arg-0 hops AND chained-`cq_theta` arg-0 hops to the wire origin
// (test_C_libtooling-6j1 + test_C_libtooling-6vk): a `cq_phi` result, and a
// chained `cq_theta` result (a Ry whose arg-0 is itself a quantum wire),
// denote a record on their parent's physical wire (rotation lowering RAUWs the
// whole chain to one handle), so a theta consuming a SIBLING SSA name of the
// chain is an in-place Ry on the seed's wire that user-edge walking alone can
// never reach. The ON-ANCESTRY gates on that backward chain (the gates that
// PRODUCE the seed's record) are EXEMPT from the forward staling-gate frontier
// — they precede the record and can never stale it; flagging the producing
// theta would over-decline every chained-rotation consumer (the boundary the
// previous never-cross-theta stop protected). Only an OFF-ancestry sibling
// theta (a user of a shared parent handle, NOT on the seed's own arg-0 chain)
// is stale evidence. A SOURCE theta's arg-0 is the classical init, so the
// closure stops there.
llvm::CallInst *findNonDiagonalWireGate(llvm::ArrayRef<llvm::Value *> Seeds,
                                        bool CrossValueRouting,
                                        const llvm::Instruction *EmitPoint =
                                            nullptr,
                                        const llvm::DominatorTree *DT =
                                            nullptr);

// "IF `B` executes, `A` has already executed, and `A` never runs again after
// it." THE ONE SPELLING of this project's position-aware proof obligation, and
// it is now shared rather than re-derived (Rule 14). Three callers: this file's
// own position-aware mode (above), `RotationLowering`'s M-A live-record clauses,
// and `ArithLowering`'s M-C in-place-reassignment deadness fence. It had TWO
// independent spellings before bd test_C_libtooling-6uqc Inc 2a, and this
// project's history says two spellings of one relation eventually disagree (bd
// uow0 `railOf`, bd 1fim `isAbiQramStore`) — so a third was consolidated into a
// first instead of added.
//
// Dominance ALONE is not enough inside a loop: the back edge replays `A` after
// `B`, so a template/gate emitted at `A` runs again against a wire `B` already
// relabelled. The reachability half closes exactly that. Unproven ⇒ false ⇒ the
// caller takes its conservative branch (Prime Directive).
//
// READ THE MODALITY — it proves a CONDITIONAL-on-`B` property, never a
// post-dominance one. `provablyBefore(A, B)` says "if `B` runs, `A` already
// did"; it does NOT say "`A` runs whenever the program reaches here". Callers
// asking the second question (will a user READ this value later?) get a
// deliberately permissive answer on a classical branch that may not execute —
// see the clause-3 note in RotationLowering.cpp, which measured both edges.
bool provablyBefore(const llvm::Instruction *A, const llvm::Instruction *B,
                    const llvm::DominatorTree &DT);

// "Does PHINode `P` faithfully DENOTE the wire at the moment it executes?" —
// i.e. does RE-EXECUTING it RE-READ the register, so that its value is a live
// record rather than a frozen one? The full argument (and the two shapes that
// separate them) is at the definition in WireWalk.cpp.
//
// EXPORTED for bd test_C_libtooling-drbq Increment 3. `ArmClassify`'s R6
// per-activation clause needs exactly this question about the DEFINITION of a
// rail record before it may grant that re-executing the def refreshes the
// record, and `LoopLowering::recordRefreshedByDef` asks the same thing over a
// POST-FLATTEN gate set that detection does not have. Two spellings of one
// relation eventually disagree in this codebase (bd
// [[identity-carry-phi-does-not-refresh]] is that disagreement, found as a
// silent miscompile), so the detection-time caller reuses this one rather than
// writing a third (Rule 14).
//
// ⚠ "`false` IS THE CONSERVATIVE ANSWER" IS A PROPERTY OF THE CALLERS, NOT OF
// THIS PREDICATE, AND THE POLARITY IS INVERTED BETWEEN THE TWO THAT EXIST (bd
// drbq Inc 3, round-1 lens L5 Q3). In `gateIsHarmless` it is a BARRIER: `false`
// refuses, so refusing only ever adds declines. In
// `ArmClassify::recordLivePerActivation` it is a PRECONDITION: `false` declines,
// so `true` GRANTS — and there an over-permissive answer would be an
// OVER-ACCEPT. Any third caller must state which direction it uses before
// relying on the sentence above.
//
// THE VOCABULARY THAT MAKES THAT MATTER: this predicate is spelled over
// `thetaOnPathTo`, which counts a `cq_theta` as a staler and does NOT count the
// dtzb in-place `add`/`xor` that `LoopLowering::collectRailGates` DOES count as
// a rail-relabelling gate. So in the GRANTING direction a φ whose wire moved
// only by a dtzb `add` between its incoming and its edge would be granted a
// refresh it did not earn.
//
// MEASURED 2026-09-04 (5 probes, HEAD): NOT EXPLOITABLE, and the fixture
// `ir-pass/test/control_inplace_ry_reject_inloop_frozen_dtzb_carry.ll` carries
// the whole discrimination. A frozen carry is its own user, so R6's PHI-EDGE
// READ POSITION rule refuses the mirrored pair before this predicate is
// consulted; and any NON-frozen φ on the same wire has an incoming whose
// `collectWireValues` closure reaches the region's own arm `cq_theta`, so this
// predicate answers `false` anyway.
// RETIREMENT TRIGGER, THREE WAYS: that argument dies if the phi-edge
// read-position rule is relaxed, if `recordLivePerActivation` admits a non-φ `D`
// that can be frozen, or if `LoopLowering::collapseRailPhisIn` step (1)'s
// LOOP-CARRIED guard (`kMsgCrossIter`, "cq loop lowering: loop-carried tainted
// value crosses iterations") is relaxed. Any of the three makes this predicate
// the only wall, and the dtzb gap becomes live — WIDEN THE VOCABULARY (or fence
// the caller) IN THE SAME CHANGE.
//
// THE THIRD ONE IS THE ROUND-2 ADDITION, and it is here because a round-2
// reviewer built the construction the two legs above do NOT cover: a NON-frozen
// carry seeded from the region's MERGE value (M-β's hoisted `T`), the dtzb `add`
// placed AFTER the region on the sibling chain, and the carry READ IN THE BODY
// so that R6's path conjunct is satisfiable — i.e. exactly the shape leg (1)
// relies on failing. It DECLINES (no defect), but on the loop-carried guard, and
// neither of the two legs is what refused it. An argument that names only the
// fences it happens to have met is the failure mode this comment block exists to
// avoid. The same trigger is written at the call site
// (`ArmClassify::recordLivePerActivation`) and in that fixture; all three move
// together.
bool phiTracksWire(const llvm::PHINode *P);

// The PER-ACTIVATION reading of `provablyBefore`, for code inside a loop whose
// every iteration re-establishes the thing being reasoned about (bd
// test_C_libtooling-8h7d.5, Phase 7.3 Increment 3).
//
// `provablyBefore` asks "`A` never runs again after `B`", which a back edge
// always falsifies — correctly, when the object under discussion PERSISTS across
// iterations, and uselessly when it does not. A per-iteration ancilla rail, and a
// loop-header phi that re-reads the wire, are re-created every trip: a `B` that
// reaches `A` only by re-executing `Barrier` first belongs to the NEXT
// activation, and says nothing about this one.
//
// So: `DT.dominates(A, B)` as before, AND either the original reachability proof
// OR "every path from `B` back to `A` re-executes `Barrier`". The second
// disjunct is what makes a rolled loop lower the same circuit its hand-unrolled
// twin does.
//
// STRICTLY ADDITIVE — the first disjunct is `provablyBefore` verbatim, so no
// shape this returned false for now returns true unless the barrier walk proves
// it. `Barrier` must be the instruction whose EXECUTION re-establishes the
// premise (the rail's mint, the interval's opening gate, the record's
// definition); passing anything else is unsound, so every caller states which
// one it means and why.
//
// `Barrier == A` IS REFUSED OUTRIGHT (bd test_C_libtooling-8h7d.5 Rule-13 round
// 1, finding P1). It is not merely unsound in principle — it was VACUOUS in
// practice, and silently so: the walk tests barrier membership BEFORE the
// endpoint, so with `To == A == Barrier` it cut at the instruction it was trying
// to reach and could never succeed, collapsing the whole call to
// `DT.dominates(A, B)` and DELETING the reachability half of `provablyBefore`
// with no diagnostic and no test. Fixing the endpoint order would not rescue it
// either: every path from `B` to `A` ends AT `A`, so "re-executes `A` on the way"
// proves nothing about this activation. `A` is the premise's subject; the barrier
// is what CLOSES the activation, which for an interval [`First`, `At`] is the
// OTHER endpoint (`Uncomputation::routeGroupFullyInside` states both legs).
// `Barrier == B` is a DIFFERENT, sound configuration and stays allowed — see the
// LEFT disjunct at Uncomputation.cpp.
bool provablyBeforePerActivation(const llvm::Instruction *A,
                                 const llvm::Instruction *B,
                                 const llvm::Instruction *Barrier,
                                 const llvm::DominatorTree &DT);

// "Does EVERY CFG path from `From` to `To` execute `Barrier` before it arrives?"
// The RAW barrier walk `provablyBeforePerActivation` is built on, exported since
// bd test_C_libtooling-8h7d.5 Rule-13 round 4 so a caller reasoning about a
// per-activation WINDOW can ask for the barrier certificate ALONE, without the
// dominance conjunct that helper bundles with it (`Uncomputation.cpp`'s window
// lemma states why the window obligation does not need one, and shows the
// dominance-bundled spellings are a strict subset).
//
// `false` is the useful answer for a proof — "no such path exists" — so read it
// as a certificate, and read `true` as "unproven, take the conservative branch".
//
// TWO WAYS TO GET A VACUOUS `false`, both of which have already cost this project
// a round: (1) `Barrier == To` — the walk tests barrier membership BEFORE the
// endpoint, so it cuts at the very instruction it is trying to reach and can
// never succeed (finding P1); (2) `From`'s own block is entered mid-way, so a
// `Barrier` textually BEFORE `From` in that block does not cut the tail scan but
// DOES cut a back-edge re-entry from the top — which is the intended semantics,
// but only if the caller means "re-executes". Every caller must state which
// instruction it is claiming re-establishes its premise, and must not pass one
// that trivially coincides with an endpoint.
bool everyPathReExecutes(const llvm::Instruction *From,
                         const llvm::Instruction *To,
                         const llvm::Instruction *Barrier);

// THE PREMISE THE `Close`-BARRIERED LEGS REST ON (bd test_C_libtooling-8h7d.5,
// Rule-13 round 4, finding F-4). "Do the two endpoints of the interval
// [`Open`, `Close`] ALTERNATE?" — i.e. is every execution of `Close` separated
// from the previous one by an execution of `Open`?
//
// `Open` DOMINATING `Close` (which every caller proves separately) gives only
// "some `Open` precedes every `Close`". It does NOT rule out a CFG cycle through
// `Close` that misses `Open` — `entry → Open → H → Close → H` satisfies both
// dominance and post-dominance and repeats `Close` freely — so the missing half
// is exactly this walk: `Close` cannot get back to `Close` without re-executing
// `Open`. In an acyclic region `Close` cannot reach itself at all and this is
// trivially true, so it is byte-inert outside a loop.
//
// WHY IT IS NOT NEEDED BY EVERY LEG, WHICH IS THE POINT OF STATING IT SEPARATELY.
// Fix an execution of `Close` at `T_Close` and let `T_Open` be the LAST `Open`
// before it; the window under discussion is `W = (T_Open, T_Close)`. A leg whose
// BARRIER is `Open` refutes a hypothetical event in `W` by producing an `Open`
// inside `W`, contradicting the maximality of `T_Open` — self-contained. A leg
// whose barrier is `Close` produces a second `Close` inside `W` instead, and that
// is a contradiction ONLY under alternation (two `Close`s force an `Open`
// between them, again inside `W`). So barriers are NOT interchangeable, and only
// the `Close`-barriered legs must be gated on this predicate.
bool intervalAlternates(const llvm::Instruction *Open,
                        const llvm::Instruction *Close);

}  // namespace cq

#endif  // CQ_IRPASS_WIRE_WALK_H_
