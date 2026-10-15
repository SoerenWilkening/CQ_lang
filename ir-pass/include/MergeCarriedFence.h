// MergeCarriedFence.h — the loud fence on a LEAKED loop-carried merge rail
// (bd test_C_libtooling-r2j3.32, routing decision (b) of 2026-10-15; the
// reverse loop that would reverse these rails is bd 8h7d.20).
//
// THE HAZARD. A Phase-4 merge rail `%out` inside a loop whose value is also the
// loop-carried register (a φ in the loop's header takes it on the back edge) is
// read by the NEXT trip's merge as a copy source. `MergeRailDischarge` cannot
// reverse it per trip: its reversal needs the previous trip's rail still live,
// so it is LIFO across trips — a post-loop reverse loop, not emitted yet. Each
// trip's rail therefore stays allocated holding a CNOT record of that trip's
// condition and sources. That leak is accepted for now (owner-delegated
// decision (b)); its COMPOSITION with a later non-diagonal gate on a register
// the record copies is not: the gate interferes branches the record still
// tells apart, so the program dephases — the r2j3.32 miscompile, one loop out.
//
// THE FENCE (R11 round 2: the invariant itself, not a per-path closure; three
// rounds of path closures each left a hole). For every merge rail the
// discharge LEFT and that is loop-carried:
//   * THE PROTECTED SET is its ENTANGLEMENT CLOSURE. Start from the rail; any
//     call ANYWHERE in the function (before, inside or after the loop) that
//     touches two or more handles — operands in state slots plus a fresh
//     handle result: cnot, toffoli, cswap, controlled copy, any controlled
//     gate's control and target, a multi-handle template or `_unc`, a lifted
//     `__cq_q_*` call (not descended: all its handles join) — protects all of
//     them as soon as one is protected, each with its whole alias class
//     (`handleAliases`: φ, select, cast, freeze, the proven rail-bank hop).
//     To a fixpoint. A protected handle that leaves through any other memory
//     fails loudly. A CNOT into a recorded register protects its CONTROL too:
//     it kicks phase back (revU6 p1).
//   * THE HAZARD is any use of a protected register, in a call after the loop
//     exit (outside the carried loop and reachable from it), in a slot not on
//     the ALLOWLIST: a gate diagonal or a computational-basis permutation on it
//     — `cqrt_rz*` (controlled or not), `cqrt_x`, `cqrt_cnot`, `cqrt_toffoli`,
//     `cqrt_cswap`, `cqrt_addc_*` / `cqrt_xorc_*`, `cqrt_copy_*`, an
//     uncontrolled `cq_template_*`, `cqrt_free`, `cqrt_measure_*`,
//     `cq_measure*` — or the control (slot 0) of a runtime controlled gate.
//     Everything else — `cqrt_ry*`, `cqrt_h`, a controlled gate's target, a
//     lifted call, any runtime gate added later — fails loudly at that call
//     (`DiagnosticInfoUnsupported`, its `!dbg`).
// WHERE: after the loop exit, not after the first merge write. Inside the loop
// each trip's gates are the body the control-lowering fences adjudicate per
// trip (every in-loop source shape we probed is declined there); the bank
// aliasing that makes every `bool b0[N]` cell one class would otherwise flag
// the shipped trip-k state prep of b0[k] itself (predicted from the alias rule,
// not measured). RESIDUAL, stated: an
// in-loop non-diagonal gate on a protected register that upstream accepts is
// not seen here.
// OVER-APPROXIMATES by design (position-independent closure, every controlled
// target joins): a register entangled with the record only AFTER a gate, or
// only as a controlled-rotation target, is still protected. Acceptable while
// the leak is the rare carried shape; the real fix is the reverse loop
// (bd 8h7d.20).
//
// L1: the question is asked where its answer is final — inside
// `dischargeMergeRails`, which `uncompute` runs LAST in both pass entry points,
// after the round-2 control fixpoint, over the settled module.

#ifndef CQ_IRPASS_MERGE_CARRIED_FENCE_H_
#define CQ_IRPASS_MERGE_CARRIED_FENCE_H_

#include "llvm/ADT/ArrayRef.h"

namespace llvm {
class CallInst;
class DominatorTree;
class Function;
class LoopInfo;
}  // namespace llvm

namespace cq {

struct TaintSet;

// The diagnostic, mirrored character-for-character by the decline fixtures.
extern const char kMsgCarriedMergeLeak[];

// Fail loudly at the first non-diagonal gate on a leaf of a leaked loop-carried
// merge rail among `Left` (the merge rails the discharge left allocated).
// Returns true when it diagnosed.
bool fenceCarriedMergeLeaks(llvm::Function &F, const TaintSet &taint,
                            llvm::ArrayRef<llvm::CallInst *> Left,
                            llvm::DominatorTree &DT, llvm::LoopInfo &LI);

}  // namespace cq

#endif  // CQ_IRPASS_MERGE_CARRIED_FENCE_H_
