// TaintPropagation.h — Forward taint propagation from quantum rotation
// sources. Originally inline in `CQLoweringPass.cpp` step 4.
//
// Contract: walk the module, collect every `@cq_theta_<sfx>` (rotation
// source), `@cq_phi_<sfx>` (rotation that propagates but does not
// introduce taint), and `@cq_measure_<sfx>` (sink) call site in
// basic-block order, seed the taint set with each theta's RESULT SSA
// value, and forward-propagate through user instructions. Measurement
// stops propagation — it is the canonical point where quantum state
// becomes classical. A `@cq_phi_<sfx>` on a tainted operand is reached by
// propagation as an ordinary user, so its result stays tainted (Rz
// preserves the quantum value); a phi on a classical operand is still
// collected so the lowering can delete it (else an unresolved
// `@cq_phi_*` extern is a Stage-3 link error). The source/sink sets span
// every suffix in `WidthDispatch::allSuffixes()`.
//
// All call sites are collected into `TaintSet` so the rotation / opcode /
// measure lowering passes do not re-walk the module. The pass operates on
// plain scalar SSA — `@cq_theta_<sfx>` returns the suffix's natural ABI
// scalar (no mid-struct wrapper, no extractvalue/insertvalue traffic).

#ifndef CQ_IRPASS_TAINT_PROPAGATION_H_
#define CQ_IRPASS_TAINT_PROPAGATION_H_

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <set>

namespace cq {

class WidthDispatch;

struct TaintSet {
  // Front-end intrinsic call sites collected during the propagation walk,
  // in basic-block order. `ThetaCalls` seeds the taint sources and feeds
  // `RotationLowering`; `PhiCalls` is collected unconditionally (a phi on a
  // classical operand must still be deleted) but does NOT seed taint;
  // `MeasureCalls` is the work list for `MeasureLowering`. Collecting them
  // here avoids re-walking the module from those passes.
  llvm::SmallVector<llvm::CallInst *, 8> ThetaCalls;
  llvm::SmallVector<llvm::CallInst *, 8> PhiCalls;
  llvm::SmallVector<llvm::CallInst *, 8> MeasureCalls;

  // Front-end intrinsic call sites reached via `invoke` instead of a direct
  // `call` (test_C_libtooling-rzs9). `collectAndSeed` declines each one LOUDLY
  // (an `invoke` is a terminator with normal + unwind successors — terminator
  // surgery the call-position lowering has no story for) and records it here so
  // `declineTaintEscapes` SKIPS the same site by EXACT membership, rather than
  // re-flagging a tainted arg-0 as a misleading "unknown callee" (the callee IS
  // known — it is reached via the unsupported form). Normally empty: clang -O1
  // on exception-free C never emits `invoke` for these opaque externs.
  llvm::SmallPtrSet<llvm::CallBase *, 4> IntrinsicInvokes;

  // All SSA values that carry quantum taint at any point in the pipeline.
  // `RotationLowering` mutates this set (inserts alloc handles minted at
  // classical-operand thetas); `OpcodeLowering` mutates it again as tainted
  // adds get rewritten to template-call results.
  std::set<llvm::Value *> Tainted;

  // SSA-value birth order for stable Q+Q operand canonicalization,
  // formerly carried by the now-removed rebind side-table.
  // `RotationLowering` seeds
  // one slot per minted alloc handle (in basic-block order); `OpcodeLowering`
  // extends it for template results and reads it back to order commutative
  // adds so the lowered trace is stable across clang versions. 0 means
  // "not assigned"; only canonicalized values have non-zero entries.
  llvm::DenseMap<llvm::Value *, unsigned> BirthOrder;
  unsigned NextBirth = 1;

  // Phase 4 (PRD §2.8). Logical ABI width of each quantum handle, recorded
  // at its rotation mint point (`RotationLowering`) from the `cq_theta`
  // classical operand. Read when building Q+Q control conditions (PRD §2.4),
  // where both operands are i32-laundered handles and the width is otherwise
  // unrecoverable. Populated and consumed by later WPs; unread this WP.
  llvm::DenseMap<llvm::Value *, llvm::StringRef> HandleWidth;

  // Phase 4 (PRD §2.10). Maps an in-shadow op result to its controlling i32
  // flag handle. Built by the control-flag / flag-conjunction passes and
  // consumed by controlled substitution and `OpcodeLowering`. The region
  // list and in-shadow set are NOT here — they ride the `ControlPlan` struct
  // returned by region detection (epic D4). Populated by later WPs; unread
  // this WP.
  llvm::DenseMap<llvm::Value *, llvm::Value *> ControlFlag;

  // ziov WI-1 (owner 2026-06-15). Maps a tainted condition compare that
  // `SwapRouteEmit::emitRegion` minted a SHARED control flag for — because the
  // compare is ALSO read as data (`int f = (q>5)`; clang -O1 CSEs the control and
  // data uses to one `icmp`) — to that flag handle. The emitter mints the flag
  // ONCE at the compare's position (so it dominates every data use) and records
  // it here INSTEAD of RAUWing the compare; `lowerOps`'s `rewriteCompare` then
  // REUSES the recorded flag for the surviving data-position compare rather than
  // minting a SECOND flag (the ziov duplicate-mint). Recording (not RAUWing)
  // defers the cross-type i1→i32 launder to lowerOps Phase 2, AFTER Phase 1 has
  // captured the data casts' true i1 source width (a pre-RAUW capture the early
  // emitter cannot do — RAUWing first turns `zext i1→i32` into a templateless
  // `zext i32→i32`). Populated by `emitRegion`; consumed in `rewriteCompare` (the
  // entry then goes stale as the compare is erased). Empty for every region
  // without a shared condition flag.
  llvm::DenseMap<llvm::Value * /*compare*/, llvm::Value * /*flag*/>
      SharedCondFlags;

  // Phase 5 Step 0 (Phase-5 IMPLEMENTATION §2.4 / §4.0). Maps a control flag to
  // the FIRST instruction of its Phase-4 teardown — the `_inv` compare (plain)
  // or `cqrt_toffoli_inv`/`cqrt_x` bracket head (conjunction) minted by
  // `emitUncompute` (`ControlledLowering.cpp`). That teardown is NOT discoverable
  // by SSA dataflow: it runs over the condition's DATA handles, not the flag, and
  // the merge block that anchored it is erased post-linearization. Phase 5's
  // in-shadow keep-alive (PRD §2.7) reads `FlagTeardown[ControlFlag[handle]]` and
  // anchors the controlled data-adjoint immediately before this instruction so
  // the adjoint nests OUTSIDE the entire (LIFO) flag teardown. Populated by
  // `emitUncompute`; unread until Phase 5 Step 4.
  llvm::DenseMap<llvm::Value * /*flag*/, llvm::CallInst * /*firstTeardown*/>
      FlagTeardown;

  // Straight-line stale-record guard (test_C_libtooling-uzb). Tainted PURE
  // producers (add/sub/mul/casts/data-position icmp) whose template, emitted
  // at the instruction's SCHEDULED position, would read a wire basis a
  // tainted-operand `cq_theta` (in-place, non-diagonal Ry) has already
  // rotated — while the SSA operand denotes the PRE-Ry record (a verify-clean
  // wrong unitary). Populated by `declineStaleRecordOps` (pure analysis on
  // the still-unmutated IR, where the pre-/post-Ry SSA values are still
  // distinct — after rotation lowering's RAUW both are the same i32 handle
  // and the distinction is unrecoverable). `lowerOps` skips members (the
  // diagnostic has already fired; lower nothing — Prime Directive). Members
  // are never erased before `lowerOps` reads this set, so the pointers stay
  // valid.
  llvm::SmallPtrSet<llvm::Instruction *, 4> StaleDeclined;

  // One-register merge-phi lift WITNESS (test_C_libtooling-2qyz). The lift
  // (`liftOneRegisterMergePhi`) RAUWs a proven pure-renaming merge phi to its
  // wire BASE and erases it — AFTER `declineStaleRecordOps` already ran — so a
  // consumer that read the phi now resolves to the base, and a sibling Ry
  // re-rotating the base's wire (invisible behind the PHINode at the earlier
  // guard) would make the consumer's template stale. The lift inserts its
  // direct Instruction consumers here so the orchestrator knows a lift OCCURRED
  // and re-runs the FULL stale-record sweep (`declineLiftedStaleRecordOps`,
  // right after `declineClassicalMuxes`, before any rotation lowering). The
  // re-sweep is NOT scoped to these entries — a stale op can sit any number of
  // in-place-gate hops downstream of the lifted phi (a Rule-13 adversarial
  // finding), so the complete sweep is required for soundness; this set is the
  // lift-occurred gate (non-empty ⇒ re-sweep, so non-lift modules incur no
  // diagnostic churn). Pointers stay valid — consumers are not erased before
  // the re-sweep.
  llvm::SmallPtrSet<llvm::Instruction *, 4> LiftedConsumers;
};

// Walks every non-declaration function in `M`, collects theta/phi/measure
// intrinsic call sites in basic-block order, and runs the forward taint
// propagation. The work-list is seeded with each theta's RESULT (the
// suffix's natural ABI scalar — plain SSA, no struct wrapper).
TaintSet propagate(llvm::Module &M, WidthDispatch &wd);

// Pre-lowering taint-escape guard (test_C_libtooling-bxv). Pure analysis on
// the still-unmutated IR, wired FIRST in BOTH pipeline entry points (the
// twin-pipeline trap, IMPLEMENTATION §6.5) — it needs pre-RAUW SSA identity,
// before rotation lowering launders every tainted value onto an i32 handle.
//
// The taint discipline only knows how to lower stock opcodes and cq
// intrinsics. Any OTHER consumer of a tainted SSA value exits the discipline's
// visibility while staying verify-clean (a same-typed opaque call reads the
// runtime handle tag after RAUW; a store leaks it into memory, where taint —
// being SSA-only — never follows): the silent-miscompile class. This guard
// walks every instruction in BB order and LOUDLY DECLINES
// (`DiagnosticInfoUnsupported`, DS_Error, `!dbg`) every user of a tainted
// value that is not on the known-consumer list (see the implementation for
// the list and the per-owner diagnostic split). Lowering still proceeds —
// the diagnostic makes `opt` exit non-zero, so nothing consumes the output
// (same surface as RotationLowering::declineTaintedAngle).
void declineTaintEscapes(llvm::Module &M, const TaintSet &taint);

// Classical-condition value-mux guard (test_C_libtooling-wi5) + the
// one-register merge-phi lift (test_C_libtooling-5j5). Wired in BOTH pipeline
// entry points AFTER `lowerControlRegions` and BEFORE `lowerRotations`
// (pre-RAUW SSA identity). Ordering is load-bearing twice over (bd memory
// opt-exits-at-first-ds-error-freepoint-net):
//   * AFTER control: ControlDetect owns every TAINTED-condition br/switch/
//     select (accept → SwapRouteEmit consumes/erases the merge phi; decline →
//     opt already exited at that first DS_Error), so whatever select/phi
//     survives to this guard is classically conditioned — no re-owning of the
//     pinned "… under quantum control" fixtures.
//   * BEFORE rotation lowering: after RAUW the mux reads the i32 handle tag
//     and is verify-clean.
//
// A LIVE select/phi that reads a tainted SSA value under a CLASSICAL condition
// is a runtime-chosen alias of quantum state ("handle-or-literal", or
// "handle-or-other-handle"): measuring or gating its result is the
// verify-clean silent-miscompile class, and NO later stage owns it — the
// Phase-5 FreePoint "unrecognized user" net is bypassed whenever the base
// handle is Measured/Escaped/`main`-resident or non-terminal. DECLINED loudly
// here. Two accepted residues:
//   * a DEAD (use_empty) phi is a pure live-range extender with no reader —
//     FreePoint's pinned benign-merge domain
//     (lowering_uncompute_branch_botharms.ll) — and cannot miscompile;
//   * the ONE-REGISTER live merge phi (test_C_libtooling-5j5): every incoming
//     tainted and resolved through the in-place cq_theta/cq_phi arg-0 wire to
//     one common base, each gate chain confined to its edge's incoming block,
//     and no path able to fire a chain gate then enter the merge through an
//     edge whose record omits it — the natural -O1 shape of
//     `if (classical_c) q = cq_phi(q, θ); use(q)`. That phi is a PROVEN pure
//     SSA renaming of one physical register: it is RAUW'd to the wire base
//     and ERASED (hence non-const `taint` — the erased phi is scrubbed from
//     `Tainted`), reducing the module to the already-accepted phi-less form.
//     SELECTS are never lifted: a select's gate-call incoming dominates it,
//     so the gate has already fired unconditionally and the untaken incoming
//     names a record the one register no longer holds (undoing it is
//     non-unitary). See liftOneRegisterMergePhi in the .cpp for the full
//     predicate and the Rule-13 trace clearance.
void declineClassicalMuxes(llvm::Module &M, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_TAINT_PROPAGATION_H_
