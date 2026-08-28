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

}  // namespace cq

#endif  // CQ_IRPASS_WIRE_WALK_H_
