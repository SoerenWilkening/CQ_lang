// StaleReadPlacement.h — OWNER RULING bd test_C_libtooling-57ch (A), 2026-10-01:
// "a stale read that can be moved before its rotating gate MUST compile: place the
// read just before the gate (entangling copy of a basis label, no cloning, no
// measurement)". This is the LEGALITY half of that placement, for ANY reader
// instruction; the mover and the verdict are `checkStaleReads`' (OpcodeLowering.cpp).
// Customers (each opts in at its own call site at the EARLY stale slot only): the
// lifted call (bd r2j3.6), and since bd 57ch.3 the pure op (curated intrinsics,
// direct sin/cos included) and the QRAM access. NOT customers, and why (bd 57ch.3):
// the `cq_measure` reader, because its staler is a gate on the register it
// measures, so the placed program gates a MEASURED handle — bd yiid's open
// re-prep lowering, see OpcodeLowering.cpp; and the `cq_theta` reader, because its
// staler always consumes the record it reads (a fan-out of one record into two
// in-place gates), so the move would stale the staler — that shape is 57ch (B).
//
// WHY THE MOVE IS THE PROGRAM. A stale read `I` denotes, by SSA, the record its
// operand names, which the register held just before the earliest staling gate. The
// circuit for "read there" is the one for the same program written with the read
// first, which the pass already lowers. Moving `I` is sound when (all checked):
//   (a) a SLOT exists (StaleReadRegion.h, bd 57ch.1): the earliest staler in the
//       nearest common dominator `D` of the read and every staler, or `D`'s
//       terminator; the read's block post-dominates `D`; the span between is
//       acyclic and closed and `I` runs exactly once per execution of `D`;
//   (b) every operand of `I` is available at the slot, or is CARRIED to it with
//       `I`, recursively, from the span:
//         - a CLASSICAL value (untainted, reading nothing tainted, no front-end
//           site, no observable ordered event, a call only if crossable; bd r2j3.6
//           review round 1 F2: -O1 schedules the `mul` of `f(q, argc * 3)` after
//           the gate);
//         - a TAINTED pure read (bd 57ch.3: a cast, arithmetic, compare, `gep`, a
//           simple load, a pure intrinsic) of records available at the slot or
//           carried: it is itself a read of pre-slot records, so it moves with
//           `I` (the QRAM index `gep` of `v = tbl[q]` sits after the gate). The
//           caller re-asks each carried tainted read at its new slot;
//         - an INDEPENDENT register's `cq_theta` gates (bd 57ch.6): a mint whose
//           arg 0 is classical, or a gate whose arg 0 is itself carried, never a
//           staler; no reader of a carried gate's input record stays in the span.
//           Gates on a register minted in the span touch no wire outside it, so
//           they commute with every staler.
//       Anything else defined after the slot refuses: a value that depends on a
//       staler (the read needs the old label AND a post-gate value — 57ch (B), the
//       kept snapshot, not built), a phi, a measurement;
//   (c) everything moved returns normally (`isGuaranteedToTransferExecutionTo-
//       Successor`, or a call `callProvablyReturns` proves by its acyclic body —
//       bd 57ch.4: the MOVED-call proof; a CROSSED call is asked (d)'s rule; a
//       front-end gate or measurement always returns), so the instructions it moves
//       above still run whenever they ran;
//   (d) every instruction it crosses that is not a front-end gate (`cq_theta_*`,
//       `cq_measure_*`, `cq_phi` call, by membership) returns normally by the same
//       test (a call: `callTerminationCrossable`, below) and is no OBSERVABLE
//       ordered event: OWNER RULING 2026-10-08, clarified
//       in review round 5 (bd memory owner-ruling-gates-ordered-vs-volatile-atomic-
//       2026-10-08): gate emission is ordered, in both directions, against any
//       volatile access, any fence, and any atomic access (any ordering) whose
//       object may be visible outside its function; an atomic on a never-captured
//       function-local alloca is not observable, and (OWNER RULING 2026-10-13, bd
//       57ch.7) neither is an atomic in a callee on a pointer argument the callee
//       does not capture that points at such a local of a caller. ONE predicate
//       (`isObservableOrderedEvent`) is asked of a crossed instruction, of every
//       instruction in a crossed call's body (with that call's local-argument
//       mask), and of a carried operand; a call is crossable (`callCrossable`, the
//       same test at every depth) when LLVM proves it touches no memory, or it is a
//       real intrinsic (by intrinsic ID, never the `llvm.` name prefix) that is a
//       non-volatile memory intrinsic or `nosync`, or its visible body holds,
//       transitively, no observable ordered event and no uncrossable call (review
//       rounds 4-5). Termination of a CROSSED call is `callTerminationCrossable`
//       (OWNER RULING 2026-10-13, bd 57ch.4): proved to return, or `nounwind` in a
//       module with no `returns_twice` call; `puts` is still refused, by
//       `callCrossable`. Such a read stays loud until 57ch (B); and
//   (e) does not conflict in memory with a moved instruction that crosses it: a
//       reading one crosses no write, a writing one crosses no access (57ch (A)'s
//       array-order rule, over all memory), asked only where the crossed
//       instruction may run before the moved one on some path. A moved CALL TO A
//       DEFINITION is asked of the definition's own effect summary, never of the
//       call site (review round 1 F4: `bindLibmCalls` keeps the libc declaration's
//       call-site `memory(none)` on an injected body that has no such attribute). A
//       front-end site touches no memory.
// A front-end gate commutes with the moved read: one on a wire `I` reads is a
// staling gate the move puts after `I` (and the caller's verdict proves it), a
// measurement is diagonal in the basis `I` copies from, and one on another wire
// touches nothing `I` reads or writes. Uses LLVM's own effect summaries (L4).
//
// ⚠ NOT CHECKED HERE, AND WHY: freshness at the new slot. A gate's previous
// instance can reach the slot around a loop; the caller takes its one stale
// verdict at the new slot (and re-asks every carried tainted read), so such a read
// still declines (it is then refused where it was moved to, which `opt` never
// emits: the `DS_Error` ends the pass).

#ifndef CQ_IRPASS_STALE_READ_PLACEMENT_H_
#define CQ_IRPASS_STALE_READ_PLACEMENT_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
class CallInst;
class DominatorTree;
class Instruction;
class PostDominatorTree;
}  // namespace llvm

namespace cq {

struct TaintSet;

// The slot (an instruction to move `I` before) at which the stale read `I`, staled by
// `Stalers` (non-empty), may be placed per (a)-(e) above; nullptr when it may not.
// `Carried` receives the operand chain to move before the slot first, in an order
// in which every definition precedes its uses (empty when every operand already
// dominates the slot).
llvm::Instruction *staleReadInsertPoint(
    llvm::Instruction &I, llvm::ArrayRef<llvm::CallInst *> Stalers,
    const TaintSet &taint, const llvm::DominatorTree &DT,
    const llvm::PostDominatorTree &PDT,
    llvm::SmallVectorImpl<llvm::Instruction *> &Carried);

}  // namespace cq

#endif  // CQ_IRPASS_STALE_READ_PLACEMENT_H_
