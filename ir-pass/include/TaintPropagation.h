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

#include "LoopPlan.h"  // LoopBreakRegion (by-value in BreakRegions, Phase 7.4 y05j.2)

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <set>

namespace cq {

class WidthDispatch;
struct SpecPlan;

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

  // Phase 5 WI-4 (DD-4). Pass-invented control SCRATCH rails the swap-route /
  // select / switch emitters minted (`cqrt_alloc_<W>` work rails, merge / data-mux
  // OUT-rails) and inserted into `Tainted` so downstream consumers keep
  // classifying them as quantum handles. Phase 4 OWNS their reversal-or-leak
  // (phase arms strip the flag + free a |0> rail; value arms reverse-play; an
  // entangled merge out-rail is LEFT ALLOCATED, Rule 6/8). The whole-DAG uncompute
  // driver subtracts this set BEFORE terminal selection so it never selects a
  // Phase-4 rail as a data terminal — replacing the dead `ControlFlag`/`FlagImage`
  // plumbing (which had zero writers) with a real, explicitly-populated image, and
  // protecting a legitimately-Phase-4-owned dead out-rail from the WI-5 silent→loud
  // flip (a `recoverDataDag` bottoming out at such an alloc would otherwise become a
  // spurious loud decline). Populated by each control emitter at its
  // `Tainted.insert(rail)` site; consumed by `uncompute`. Empty for a module with
  // no tainted control flow.
  llvm::SmallPtrSet<llvm::Value *, 8> ControlOwnedRails;

  // Phase 7.6 (PRD-7.6 §2.5). Kept I/O output rails — the `out_handle` each
  // `cqrt_tape_write_<W>` returns (a Bennett output tape entry). They are a
  // SINK's product, never uncomputed and never freed: routing one through the
  // FreePoint / uncompute spine would collapse the very output the user asked
  // to emit (Rule 6/8). The whole-DAG uncompute driver subtracts this set at
  // BOTH spine sites — terminal selection (`Uncomputation`) and the DAG
  // closure scan (`DagTraversal`) — the SAME discipline as `ControlOwnedRails`
  // (the explicit image is load-bearing; do NOT rely on the closure scan
  // incidentally skipping the rail). A SIBLING of `ControlOwnedRails`, NOT a
  // reuse: the semantics differ (an output sink, not a Phase-4 control rail).
  // The tape HANDLE from `cqrt_tape_alloc` is a classical resource token — not
  // tainted, not a rail — so it is NEVER in this set; only the per-entry
  // `out_handle` is. Populated by `lowerIOSinks`; consumed by `uncompute`.
  // Empty for a module with no tainted I/O output.
  llvm::SmallPtrSet<llvm::Value *, 8> OutputRails;

  // Phase 7.2 Increment 3 (PRD-7.2 §2.8 / §2.11-B, plan §2-A). Parked GRAVEYARD
  // rails — the freshly-`cqrt_alloc`'d rail the abort/exit park `cqrt_cswap`s the
  // pre-abort routed handle into (under the abort flag), plus the abort flag
  // itself. The flag=1 (would-abort) component of the live register is moved aside
  // so the uncontrolled downstream never observes (and so never dephases) it; the
  // graveyard is kept frozen + inspectable forever. A parked rail is ENTANGLED
  // (with the flag / the scrutinee), so reverse-playing or `cqrt_free`-ing it is a
  // hidden projective collapse (Rule 6) — exactly the hazard `OutputRails` /
  // `ControlOwnedRails` guard against, but with a distinct semantics (a parked
  // graveyard, not a control rail or an output-tape entry). The whole-DAG
  // uncompute driver subtracts this set at BOTH spine sites — terminal selection
  // (`Uncomputation`) AND the DAG closure scan (`DagTraversal`) — the SAME
  // load-bearing-explicit-image discipline as `OutputRails` (do NOT rely on the
  // closure scan / `isTerminalHandle` incidentally skipping a parked rail: a
  // graveyard reached as a DAG ancestor must still be left allocated, never
  // reversed/freed). Populated by `AbortParkEmit`; consumed by `uncompute`. Empty
  // for a module with no controlled abort/exit.
  llvm::SmallPtrSet<llvm::Value *, 8> GraveyardRails;

  // Phase 7.3 Inc 2 (799w.2, PRD-7.3 §2.5). Blocks of recognized Case-B
  // "iteration-local" loops — a classically-bounded loop (untainted exit, no
  // tainted control/memory in the body) every one of whose tainted values is
  // BORN AND DIES within a single iteration (no loop-carried/loop-invariant
  // tainted value: no tainted header phi, every tainted value defined in the
  // loop is used ONLY in the loop, and every tainted operand of an in-loop
  // instruction is defined in the loop). The Phase-5 uncompute spine LIFTS its
  // two backedge guards — FreePoint's `kMsgLoopBackedge` per-terminal reject and
  // Uncomputation's §2.9 acyclic backstop — ONLY for a terminal whose whole DAG
  // lies within these blocks, placing the per-iteration recovery + `cqrt_free`
  // IN-BODY (after the temp's last in-iteration use, before the backedge — proven
  // to execute exactly once per iteration) instead of declining or leaking. A
  // block NOT in this set keeps both guards (the residual net). Populated by
  // `lowerLoops`; consumed by `FreePoint` + `Uncomputation`. Empty for a module
  // with no Case-B loop.
  llvm::SmallPtrSet<const llvm::BasicBlock *, 8> IterationLocalBlocks;

  // Issue dtzb — the in-place reversible arithmetic strategy. A recognized
  // loop-carried VALUE rail self-update (`q = q OP c`, OP ∈ {add, xor}, one
  // tainted operand + a CLASSICAL immediate — a reversible bijection of the
  // rail) whose rail phi `lowerLoops` collapsed Case-A style. `lowerLoops`
  // RECOGNIZES + collapses + marks the op here; `lowerOps` then emits the
  // IN-PLACE `cqrt_{addc,xorc}_<W>(handle, imm)` (the rail is one handle by
  // then, the cross-type theta→i32-handle RAUW already done) instead of the
  // out-of-place `cq_template_<op>_<W>_hl` data template (which would mint a
  // fresh rail per iteration — the X1 cross-iteration dirty rail). The set
  // carries ONLY ops `lowerLoops` proved are clean in-place rail self-updates;
  // any unproven value rail stays the X1 decline. Empty for a module with no
  // recognized value-accumulator loop.
  llvm::SmallPtrSet<llvm::Instruction *, 4> InPlaceRailOps;

  // Phase 7.6 (PRD-7.6 §2.4). One lazy `cqrt_tape_alloc()` per function — the
  // stream→tape registry (v1 has a single stdout stream). SHARED across the two
  // I/O-lowering steps so a function with BOTH a controlled `if(q)printf`
  // (lowered before control detection) AND an uncontrolled `printf` (lowered
  // after control lowering) appends to ONE tape, never two separate tapes (a
  // split transcript is a verify-clean lost-output bug, PRD-7.6 risk #2). The
  // tape handle is a CLASSICAL resource token — NOT tainted, NOT an output rail.
  // Keyed by Function so each function owns its own stdout tape. Populated lazily
  // by `lowerControlledIOSinks` / `lowerIOSinks`; empty for a module with no
  // tainted I/O output.
  llvm::DenseMap<llvm::Function *, llvm::Value *> IOTapeForFn;

  // Phase 7.4 Increment 2 (epic y05j) — value-arm `break` loops the FORWARD
  // transform (`tryBreak`/`emitBreakForward`, pre-lowering) recognized and rewired
  // (rail collapsed, terminator stripped to the classical bound, `R`/`idx`/`out`
  // minted, exit-phi RAUW'd to `out`). Each carries the post-lowering-stable
  // record (`LoopBreakRegion`, LoopPlan.h) the POST-LOWERING `lowerBreakReversePlay`
  // stage consumes to emit the capture + whole-loop reverse-play on the lowered
  // body. Empty for a module with no recognized value-arm break.
  llvm::SmallVector<LoopBreakRegion, 2> BreakRegions;
};

// Walks every non-declaration function in `M`, collects theta/phi/measure
// intrinsic call sites in basic-block order, and runs the forward taint
// propagation. The work-list is seeded with each theta's RESULT (the
// suffix's natural ABI scalar — plain SSA, no struct wrapper).
TaintSet propagate(llvm::Module &M, WidthDispatch &wd);

// bd iw81.1 — fold same-width int<->int `bitcast` identity EARLY (before ANY
// wire / lineage / control / stale-record analysis runs), so the whole pass sees
// the operand's true wire directly and never an opaque identity node it must
// special-case. A same-width int bitcast is a zero-gate reversible IDENTITY
// (`result === operand`, ONE physical wire); leaving it STANDING would blind each
// of the pass's many BESPOKE provenance walks (stale-record, SelectClassify
// coherent-use, IOSink lineage, ArmClassify/SwitchArmProve condition, …) to an
// in-place re-rotation hidden behind it — a whack-a-mole class of verify-clean
// silent miscompile (the Rule-13 review confirmed three distinct such consumers).
// Folding it away up front (the FREEZE-fold precedent, `declineTaintEscapes`)
// reduces the program to the DIRECT-operand form the base pass already adjudicates
// correctly — a downstream DATA op reading a re-rotated wire declines, a MEASURE
// reads the wire in place (accepted) — with ZERO new per-consumer analysis. Only
// TAINTED same-width int<->int bitcasts are folded (RAUW result->operand, scrub
// `Tainted`/`HandleWidth`, erase); fp<->int reinterprets, vectors, and pointer
// bitcasts are NOT identities and are LEFT STANDING to decline loudly at
// `castInScope` ("no template for opcode 'bitcast …'") — unchanged. Wired FIRST,
// right after taint settles, in BOTH pipeline entry points (twin-pipeline trap).
void foldIdentityBitcasts(llvm::Module &M, TaintSet &taint);

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
//
// Phase 6 carve-out (C-Plan): `plan6` is the proven-Accept plan
// `detectSpecializations` populated as a pre-pass BEFORE this guard. The
// `:419` in-module-body decline is SUPPRESSED for a site in `plan6.Pending`
// (`shouldSpecialize`) — clone-on-taint owns it — and for a site in
// `plan6.Diagnosed` (detection already loud-declined it with a specialization
// message, so the generic `kMsgUnknownCallee` would be a confusing second
// message). Every other tainted-arg call (declaration-only / indirect / invoke /
// opaque extern) is absent from both and STILL fires `kMsgUnknownCallee`
// (decline-by-default). `plan6` is otherwise read-only here.
//
// `taint` is taken by mutable reference because the ONE Phase-7.1 Increment-B
// accept (a basis-level identity `freeze iN %handle`) is FOLDED away here
// (RAUW + erase + scrub from `taint.Tainted`); every other path is pure analysis
// (the decline diagnostics still key on pre-RAUW SSA identity).
void declineTaintEscapes(llvm::Module &M, TaintSet &taint,
                         const SpecPlan &plan6);

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
