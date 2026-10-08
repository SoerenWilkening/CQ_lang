// StaleReadPlacement.h — OWNER RULING bd test_C_libtooling-57ch (A), 2026-10-01:
// "a stale read that can be moved before its rotating gate MUST compile: place the
// read just before the gate (entangling copy of a basis label, no cloning, no
// measurement)". This is the LEGALITY half of that placement, for ANY reader
// instruction; the mover and the verdict are `checkStaleReads`' (OpcodeLowering.cpp).
// First customer: the lifted call (bd r2j3.6). Pure ops, QRAM accesses and the
// `cq_theta` / `cq_measure` readers are 57ch's remaining slices; each opts in at its
// own call site, flipping its own decline fixtures in its own reviewed change.
//
// WHY THE MOVE IS THE PROGRAM. A stale read `I` denotes, by SSA, the record its
// operand names, which the register held just before the earliest staling gate. The
// circuit for "read there" is the one for the same program written with the read
// first, which the pass already lowers. Moving `I` is sound when (all checked):
//   (a) every staling gate is in `I`'s block, before `I`; the slot is the earliest;
//   (b) every operand of `I` is available at that slot, or is a CLASSICAL value
//       computed between the slot and `I` (untainted, reading nothing tainted, no
//       front-end site, no observable ordered event, a call only if crossable) that is
//       CARRIED to the slot with it, recursively (bd r2j3.6 review round 1 F2:
//       -O1 schedules the `mul` of `f(q, argc * 3)` after the gate; it does not
//       depend on the gate). A TAINTED operand defined after the gate refuses:
//       either it depends on the gate (the read needs the old label AND a
//       post-gate value at once — 57ch (B), the kept snapshot, not built) or it is
//       an INDEPENDENT register whose own front-end gates would have to move above
//       the slot (a commuting reorder on disjoint wires, not built: follow-up F8);
//   (c) everything moved returns normally (`isGuaranteedToTransferExecutionTo-
//       Successor`), so the instructions it moves above still run whenever they ran;
//   (d) every instruction it crosses that is not a front-end gate (`cq_theta_*`,
//       `cq_measure_*`, `cq_phi` call, by membership) returns normally and is no
//       OBSERVABLE ordered event: OWNER RULING 2026-10-08, clarified in review
//       round 5 (bd memory owner-ruling-gates-ordered-vs-volatile-atomic-2026-10-08):
//       gate emission is ordered, in both directions, against any volatile access,
//       any fence, and any atomic access (any ordering) whose object may be visible
//       outside its function; an atomic on a never-captured function-local alloca is
//       not observable. ONE predicate (`isObservableOrderedEvent`) is asked of a
//       crossed instruction, of every instruction in a crossed call's body, and of a
//       carried operand; a call is crossable (`callCrossable`, the same test at
//       every depth) when LLVM proves it touches no memory, or it is a real
//       intrinsic (by intrinsic ID, never the `llvm.` name prefix) that is a
//       non-volatile memory intrinsic or `nosync`, or its visible body holds,
//       transitively, no observable ordered event and no uncrossable call (review
//       rounds 4-5). Such a read stays loud until 57ch (B); and
//   (e) does not conflict in memory with a moved instruction that crosses it: a
//       reading one crosses no write, a writing one crosses no access (57ch (A)'s
//       array-order rule, over all memory). A moved CALL TO A DEFINITION is asked
//       of the definition's own effect summary, never of the call site (review
//       round 1 F4: `bindLibmCalls` keeps the libc declaration's call-site
//       `memory(none)` on an injected body that has no such attribute).
// A front-end gate commutes with the moved read: one on a wire `I` reads is a
// staling gate the move puts after `I` (and the caller's verdict proves it), a
// measurement is diagonal in the basis `I` copies from, and one on another wire
// touches nothing `I` reads or writes. Uses LLVM's own effect summaries (L4).
//
// ⚠ NOT CHECKED HERE, AND WHY: freshness at the new slot. A gate's previous
// instance can reach the slot around a loop; the caller takes its one stale
// verdict at the new slot, so such a read still declines (it is then refused
// where it was moved to, which `opt` never emits: the `DS_Error` ends the pass).

#ifndef CQ_IRPASS_STALE_READ_PLACEMENT_H_
#define CQ_IRPASS_STALE_READ_PLACEMENT_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
class CallInst;
class DominatorTree;
class Instruction;
}  // namespace llvm

namespace cq {

struct TaintSet;

// The slot (an instruction to move `I` before) at which the stale read `I`, staled by
// `Stalers` (non-empty), may be placed per (a)-(e) above; nullptr when it may not.
// `Carried` receives the classical operand chain to move before the slot first, in
// program order (empty when every operand already dominates the slot).
llvm::Instruction *staleReadInsertPoint(
    llvm::Instruction &I, llvm::ArrayRef<llvm::CallInst *> Stalers,
    const TaintSet &taint, const llvm::DominatorTree &DT,
    llvm::SmallVectorImpl<llvm::Instruction *> &Carried);

}  // namespace cq

#endif  // CQ_IRPASS_STALE_READ_PLACEMENT_H_
