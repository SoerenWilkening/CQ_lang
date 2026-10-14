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
// THE FENCE (a gate SET, L3). For every merge rail the discharge LEFT and that
// is loop-carried, the LEAVES are the registers its stream read — the condition
// wire (each copy's control flag and, transitively, everything that flag was
// computed or CNOT-copied from) and the copied source operands (transitively,
// what they were computed from) — closed over their handle aliases (φ, select,
// cast, freeze, the rail-bank hop; `handleAliases`). The carried rails
// themselves are the records, not leaves. Every call outside that loop and
// reachable from it is scanned; one that acts NON-DIAGONALLY on a leaf fails
// loudly at that call (`DiagnosticInfoUnsupported`, its `!dbg`):
//   * `cqrt_ry_*` on the leaf (slot 0; slot 1 of the `_controlled` form);
//   * `cqrt_cswap` with the leaf in a swapped slot;
//   * any other `cqrt_*_controlled` with the leaf as its target (a controlled
//     copy INTO it — the X-bracketed copy; not its control or copy source);
//   * a call to a non-runtime function consuming it (a lifted `__cq_q_*` body
//     is asked the same question of its parameter; anything else fails closed).
// Measurement, frees, diagonal phases (`cqrt_rz_*`) and basis permutations
// (`cqrt_x`, `cqrt_cnot`, `cqrt_toffoli`, `addc`/`xorc`, templates) are not
// hazards: none of them interferes the branches a basis record separates.
// A leaf whose alias class reaches unproven memory fails closed the same way.
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
