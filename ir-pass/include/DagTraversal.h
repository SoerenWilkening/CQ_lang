// DagTraversal.h — Whole-DAG recovery of a tainted data register (Phase 5 WI-4,
// PRD §2.1/§2.11). Pure analysis — emits no IR.
//
// The conservative WI-3 slice recovered a LINEAR reassignment chain per terminal
// and BAILED on fan-out (reversing a shared prefix twice). WI-4 recovers the whole
// def-use DAG from a SET of terminals via a visited-set worklist (the backward
// hop is every tainted operand, so a QQ node yields BOTH parents), adjointed once
// over a single reverse-topological pass. SSA dominance (def-before-use) makes
// reverse PROGRAM order a valid reverse-topological order, so `Calls` is returned
// in forward program order for the driver to walk in reverse.
//
// Reversal is sound ONLY for a CLOSED DAG: every forward consumer of every rail
// must itself be a recovered gate (so the whole sub-DAG returns to |0⟩ together).
// A rail read by a consumer OUTSIDE the DAG — a Phase-4 controlled copy/cswap that
// entangles it (the §16.5 safe-leak), a measurement sink, a `ret`/`cq_invert`
// escape, or a data gate leading to a measured/escaped terminal — means the rail
// is owned elsewhere and must stay allocated (Rule 6/8: never a dirty free). The
// recovery records that as `NotClosed`/`MeasuredUpstream`/`Escaped` so the driver
// declines (loudly for a measured register; a silent safe-leak otherwise).

#ifndef CQ_IRPASS_DAG_TRAVERSAL_H_
#define CQ_IRPASS_DAG_TRAVERSAL_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Value.h"

namespace cq {

struct TaintSet;

// The recovered forward gate DAG of one or more terminals.
//   * `Calls`  — every in-place rotation and reassigning template producer in the
//                DAG, in FORWARD program order (the driver walks this in reverse,
//                adjointing each gate exactly once).
//   * `Roots`  — the `cqrt_alloc_<W>` / theta mints the DAG bottoms out at.
struct DataDag {
  llvm::SmallVector<llvm::CallInst *, 16> Calls;
  llvm::SmallVector<llvm::Value *, 8> Roots;

  // A NON-rotation rail (a root or a template result) in the DAG is read by a
  // `cqrt_measure_` sink. Reversing the DAG would free a register a user
  // measurement still reads — a hidden projective collapse (Rule 5/6). The
  // driver retries with the measured rails borrowed (bd ptue) and otherwise
  // declines LOUDLY; `UpstreamMeasure` carries the sink for the `!dbg` location.
  bool MeasuredUpstream = false;
  llvm::CallInst *UpstreamMeasure = nullptr;
  // EVERY rail that set `MeasuredUpstream` (bd test_C_libtooling-ptue). Recorded
  // at the one site that decides "measured", so the dead-terminal driver's
  // frontier retry borrows exactly the rails this scan saw measured (Rule 12 —
  // never a second `isMeasureSink` sweep in the driver). Membership only; the
  // set's iteration order is never read into emitted IR.
  llvm::SmallPtrSet<llvm::Value *, 4> MeasuredRails;

  // A DAG rail is consumed by a `ReturnInst` or a `cq_invert_*` call — it escapes
  // the function (the caller / Phase 7 owns its reversal). Silent skip (§2.6).
  bool Escaped = false;

  // A DAG rail has a forward consumer that is NOT a recovered gate: a Phase-4
  // controlled copy/cswap that entangled it (§16.5 safe-leak), a data gate
  // leading to a terminal we are NOT reversing, or any other unprovable user.
  // The sub-DAG is owned elsewhere — leave it allocated (Rule 6/8). Silent skip.
  bool NotClosed = false;
  // The rails that set `NotClosed` through a CONSUMER outside the recovered set
  // (an out-of-DAG gate or a non-call user) — bd test_C_libtooling-01po.8.
  // Recorded at the one site that decides it, so the dead-terminal frontier
  // retry BORROWS exactly these rails (Rule 12) instead of re-scanning users.
  // A rail refused by an OWNERSHIP image (`ControlOwnedRails`, `OutputRails`,
  // `GraveyardRails`, a controlled-rotation register) is NOT in this set: it
  // still sets `NotClosed`, and the retry then keeps its decline.
  llvm::SmallPtrSet<llvm::Value *, 4> OpenRails;

  // bd 261j(a) — rails that are RECORDED into a kept carrier (an output tape,
  // never uncomputed and never freed) AND whose forward chain is not a basis
  // permutation of still-live conditions. Such a rail is ENTANGLED with the
  // carrier at the free point, so re-emitting its adjoint does NOT return it to
  // |0⟩ and `cqrt_free` on it would be a hidden projective measurement (Rules
  // 5/6/8). A frozen rail gets NO FREE — it is LEFT ALLOCATED, the Rule-6
  // fallback. This is a PER-RAIL subtraction, not a DAG-global bail: every
  // non-frozen rail in the same DAG still frees.
  //
  // A frozen rail IS still fully reverse-played. The freeze suppresses the FREE and
  // never an adjoint — dropping the adjoint breaks invariant (d) for every
  // surviving rail that READS the frozen one, which the bd 261j(a) Rule-13 round
  // measured as four separate hidden measurements. See the long note at the
  // suppression site in `Uncomputation::emitDagReversal`.
  //
  // bd r2j3.3 adds a SECOND writer, `RecordWindowFreeze` (step 3c): a rail whose
  // own chain IS a basis permutation but whose gate READ a register that a later
  // non-basis gate moved and a kept carrier then recorded — its `_unc` would
  // recompute from a label the inverse gate no longer restores. Same effect: no
  // free, every adjoint kept.
  //
  // bd 5c5b (libcqops vmz9) adds a THIRD writer, `BirthFreeze` (step 3d): clause
  // (a), "R starts at |0⟩". Reverse-play returns a rail to its BIRTH state, and a
  // `cqrt_alloc_<W>(seed)` root is born |seed⟩, so only a template producer or a
  // null-constant-seeded alloc can be freed. Same effect: no free, every adjoint
  // kept.
  //
  // Consumed by `Uncomputation::emitDagReversal` (the suppression) and by its
  // planner's `addDischargedRails` (which counts only rails it will free),
  // deliberately: `D.Calls`
  // stays intact so the driver's invertibility / InLoop / dominance scans still
  // see every recovered gate and still decline loudly. Pruning `Calls` instead
  // would blind all three (bd 261j(a) risks 1-2, MEASURED rc=1 → rc=0).
  llvm::SmallPtrSet<llvm::Value *, 4> FrozenRails;

  // bd 8gi5(3) + bd e4zs — every SOURCE-PRESERVING SINK that reads a rail of this
  // DAG: a `cqrt_tape_write_<W>[_controlled]` (`isOutputSink`) or an uncontrolled
  // `cqrt_copy_<W>(src, dst)` (`isCopyOutSink`). These READ a rail without
  // consuming it, which is why the closure scan above lets them pass — but they
  // are still USES, and the reversal's `cqrt_free` must land AFTER them.
  //
  // `FreePoint::computeFreePoint` cannot supply that ordering on its own: it is
  // called per TERMINAL and scans `Terminal->users()`, so a preserving sink that
  // reads a NON-TERMINAL upstream rail never joins the post-dominator user set and
  // the insertion point can precede it. MEASURED on both surfaces (rc=0, `opt
  // -passes=verify` clean, and stage 2b naming it `F2-use-after-free`):
  //     %a = add %q, 1 ; %b = add %a, 2 (dead terminal) ; tape_write(tape, %a)
  //     %a = add %q, 1 ; %b = add %a, 2 (dead terminal) ; copy(%a, %dst)
  // The driver folds these into the `dagInsertPoint` anchor set so the whole
  // reversal is placed after every preserving read of every rail it frees.
  llvm::SmallVector<llvm::CallInst *, 4> PreservingSinks;

  // The rails the step-3 closure scan actually WALKED: `Roots` ∪ the template
  // producers. Everything this DAG knows about a rail — `MeasuredUpstream`,
  // `NotClosed`, `Escaped`, `PreservingSinks` — is set by iterating exactly this
  // set, so a value OUTSIDE it carries none of those verdicts.
  //
  // Exported because `emitDagReversal` frees by `railOf(G)` over `Calls`, and those
  // two sets are NOT equal. Freeing a member of the difference would reset a
  // register that was never measure-, closure- or sink-scanned (Rule 6), so the
  // driver intersects. The gap has exactly one emitter-mintable member today, a
  // `@__cq_q_<callee>_<mask>` clone call, and it is unreachable — but this used to
  // be justified in prose as "a DOWNSTREAM guard, `isInverseEmittable`, removes it",
  // which is FALSE (that predicate accepts `__cq_q_`). Structure, not prose.
  llvm::SmallPtrSet<llvm::Value *, 16> Rails;
};

// ── M-B INTERIOR PARTITION (bd test_C_libtooling-6uqc Inc 5a) ────────────────
//
// The plan the interior driver hands to the recovery. Empty (`nullptr`) for the
// two existing partitions, whose behaviour is then BYTE-IDENTICAL to before.
//
//   * `Owned`    — the interior rails this recovery may adjoint and free. Each
//                  passed `ChainWalk::isInteriorTerminalHandle` AND the driver's
//                  positional proof (every consumer provably executed before the
//                  discharge point, never re-read after).
//   * `Borrowed` — the FRONTIER. A parent rail that is read-only for this DAG:
//                  the `cqrt_alloc`-minted source wire, or any rail the interior
//                  test declined to own. The backward walk STOPS at it — it is
//                  never added to `Roots`, its in-place gates are never
//                  collected, and it is therefore never adjointed and never
//                  freed.
//
// WITHOUT THE FRONTIER THE SPINE WOULD DO ONE OF TWO WRONG THINGS, both
// measured on bd 6uqc's P1/P4 before it existed: hop from the first template
// rail to the `cqrt_alloc` source, collect its `cqrt_ry` as an in-place gate and
// emit `cqrt_ry(%h, -θ); cqrt_free(%h)` on a register the program still uses
// (P4's chained theta) — or, where the chain ends at a measured rail, recover
// that rail and fire `kMsgLineageMeasured`. The frontier is what makes the
// interior partition a subtraction from the live program rather than a claim
// over it.
struct InteriorPlan {
  llvm::SmallPtrSet<llvm::Value *, 16> Owned;
  llvm::SmallPtrSet<llvm::Value *, 8> Borrowed;
  // bd rhk5 round 2 (bd `kyy1`): whether the closure scan below may admit a
  // Phase-6 clone call as an OWNED rail's consumer (`isInteriorConsumer` (b′)).
  // Set by the planner from the mode it is planning in; the two must agree, or a
  // rail planned WITHOUT (b′) could be closed WITH it.
  bool AdmitCloneCalls = false;
};

// Recover the whole forward DAG of the registers whose live terminal handles are
// `Terminals` (a union — fan-out terminals sharing a prefix yield one DAG so the
// shared gates are recovered once). `DT` supplies the cross-block program order.
// The closure / measure / escape analysis (the fields above) runs over every
// recovered rail.
//
// `IP`, when non-null, switches on the M-B interior mode: the backward walk stops
// at `IP->Borrowed`, and a forward consumer of an `IP->Owned` rail that
// `ChainWalk::isInteriorConsumer` admits is a BENIGN closure user rather than an
// out-of-DAG one. Both are strict extensions — with `IP == nullptr` not one line
// of the existing behaviour changes.
DataDag recoverDataDag(llvm::ArrayRef<llvm::Value *> Terminals,
                       const TaintSet &taint, llvm::DominatorTree &DT,
                       const InteriorPlan *IP = nullptr);

}  // namespace cq

#endif  // CQ_IRPASS_DAG_TRAVERSAL_H_
