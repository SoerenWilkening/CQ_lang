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
//   * ArmClassify::wireGainsNonDiagonalGate — POSITION-FREE (`EmitPoint`
//     null): ANY theta user on the condition's provenance wire declines the
//     region (the flag mint at the branch would read a post-Ry basis;
//     over-decline accepted as safe — Prime Directive). Does NOT cross
//     PHINodes/selects, preserving the documented ArmClassify boundary (a
//     PHI-mediated post-region theta is unreachable by design there).
//   * OpcodeLowering::declineStaleRecordOps — POSITION-AWARE (`EmitPoint` +
//     `DT` given): a theta is harmless iff it is PROVABLY emitted after every
//     execution of the op's template (`DT->dominates(EmitPoint, T)` — every
//     path to T already executed the template — AND
//     `!isPotentiallyReachable(T, EmitPoint)` — once T fired, the template
//     never re-executes, closing the loop-iteration-2 staleness). This mode
//     DOES cross PHINodes and select value-operands (`CrossValueRouting`):
//     they route the same physical handle, so a theta behind them is still an
//     in-place gate on a wire the operand may denote.

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
// Each seed is first CLOSED BACKWARD through diagonal `cq_phi` arg-0 hops
// (test_C_libtooling-6j1): a `cq_phi` result denotes its parent's basis
// record on its parent's physical wire (Rz is diagonal; rotation lowering
// RAUWs the whole chain to one handle), so a theta consuming a SIBLING SSA
// name of the chain is an in-place Ry on the seed's wire that user-edge
// walking alone can never reach. The closure stops at the seed's nearest
// non-`cq_phi` ancestor — its RECORD BOUNDARY, not necessarily the wire
// origin: it never crosses a theta hop (a theta result is a fresh record,
// and seeding at its parent would flag the producing gate itself — see
// WireWalk.cpp), so a sibling Ry behind a CHAINED theta remains a known-open
// over-accept family, tracked in test_C_libtooling-6vk.
llvm::CallInst *findNonDiagonalWireGate(llvm::ArrayRef<llvm::Value *> Seeds,
                                        bool CrossValueRouting,
                                        const llvm::Instruction *EmitPoint =
                                            nullptr,
                                        const llvm::DominatorTree *DT =
                                            nullptr);

}  // namespace cq

#endif  // CQ_IRPASS_WIRE_WALK_H_
