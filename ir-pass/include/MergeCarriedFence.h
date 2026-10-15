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
// reachable from it is scanned, and the leaf's use is checked against an
// ALLOWLIST (R11 round 2: a second wall must fail closed). A leaf is safe only
//   * in a gate diagonal or a computational-basis permutation on it:
//     `cqrt_rz*` (controlled or not), `cqrt_x`, `cqrt_cnot`, `cqrt_toffoli`,
//     `cqrt_cswap`, `cqrt_addc_*` / `cqrt_xorc_*`, `cqrt_copy_*` (a controlled
//     copy INTO it is an XOR), an uncontrolled `cq_template_*` (forward or
//     `_unc`), `cqrt_free`, `cqrt_measure_*`;
//   * as the control (slot 0) of any controlled gate;
//   * as the argument of a lifted `__cq_q_*` body that passes the same test on
//     its parameter (recursively), or of `cq_measure*`.
// Every other use — `cqrt_ry*`, `cqrt_h`, a controlled template's data slot,
// any runtime gate added later, an opaque call — fails loudly at that call
// (`DiagnosticInfoUnsupported`, its `!dbg`). None of the allowed uses
// interferes the branches a basis record separates; every other use might.
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
