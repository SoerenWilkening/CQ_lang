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
// discharge LEFT and that is loop-carried — a member of its alias class is a
// containing loop's header φ, or a rail-bank cell load inside it (R11 round 1,
// F2: carried through MEMORY, S3's Q6(a) shape); an unprovable class inside a
// loop counts as carried and then fails loudly:
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
//   * THE HAZARD SET (bd r2j3.36: the whole function, inside the loop too) is
//     every (call C, slot S) where
//       (i)   the operand is in the protected set,
//       (ii)  the slot is not on the ALLOWLIST: a gate diagonal or a
//             computational-basis permutation on it — `cqrt_rz*` (controlled
//             or not), `cqrt_x`, `cqrt_cnot`, `cqrt_toffoli`, `cqrt_cswap`,
//             `cqrt_addc_*` / `cqrt_xorc_*`, the r2j3.33 in-place tag,
//             `cqrt_copy_*`, an uncontrolled `cq_template_*`, `cqrt_free`,
//             `cqrt_measure_*`, `cq_measure*` — or the control (slot 0) of a
//             runtime controlled gate. Everything else — `cqrt_ry*`, `cqrt_h`,
//             a controlled gate's target, a lifted call, any runtime gate
//             added later — FAILS CLOSED;
//       (iii) a record can exist at C: C is reachable from the rail's
//             allocation (`isPotentiallyReachable` with DT and LoopInfo, so
//             every call in the loop counts, across the back edge — trip k+1
//             sees trip k's leaked rail);
//       (iv)  the register is not FRESH at C (MergeCarriedFenceFresh.h): a
//             `cqrt_alloc_*` result on which no coupling use of its alias
//             class runs between that allocation and C on some CFG path, or
//             (R11 round 1, F1) a per-trip CELL LOAD of a bank whose cells
//             are parked fresh mints, at a no-wrap AddRec address of the
//             carried loop, that no same-cell coupling can precede in the
//             trip and no other-cell coupling can precede at all. A fresh
//             register is in a product state, so no gate on it interferes
//             branches a record tells apart. A template result, a φ, a
//             select are never fresh.
//     The first element fails loudly at C (`DiagnosticInfoUnsupported`, its
//     `!dbg`).
// WHY THIS SHAPE (R11 round 2, revU7, then r2j3.36): before r2j3.36 the check
// ran only after the loop exit, and an in-loop non-diagonal gate on a register
// entangled with this trip's or an earlier trip's leaked rail passed (reviewer
// probes pA–pE; every C spelling is declined upstream today by the rail-bank
// multi-store / re-executed-walk declines 01po.19 S4–S7 remove). A plain
// in-loop check over the position-insensitive closure would flag the shipped
// slice's per-trip state prep: its fresh `b0[i]` rail joins the closure (via
// the carried φ → `icmp` → `cqrt_ry_i1_controlled` target) though it is
// entangled with nothing when rotated. Clause (iv) is the flow-sensitive
// "entangled before" answer for exactly that population, asked as a CFG path
// question rather than a per-path closure (memory
// merge-carried-fence-closure-lesson-2026-10-15).
// OVER-APPROXIMATES by design: the closure is position-independent and only an
// allocation is ever fresh, so a template result, φ or bank load entangled
// with the record only after a gate is still protected. Acceptable while the
// leak is the rare carried shape; the real fix is the reverse loop
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

// Fail loudly at the first element of the hazard set (above) of a leaked
// loop-carried merge rail among `Left` (the merge rails the discharge left
// allocated).
// Returns true when it diagnosed.
bool fenceCarriedMergeLeaks(llvm::Function &F, const TaintSet &taint,
                            llvm::ArrayRef<llvm::CallInst *> Left,
                            llvm::DominatorTree &DT, llvm::LoopInfo &LI);

}  // namespace cq

#endif  // CQ_IRPASS_MERGE_CARRIED_FENCE_H_
