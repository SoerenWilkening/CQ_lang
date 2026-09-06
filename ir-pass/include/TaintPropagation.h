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
#include "llvm/ADT/DenseSet.h"
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
  // `RotationLowering`; `MeasureCalls` is the work list for
  // `MeasureLowering`. Collecting them here avoids re-walking the module
  // from those passes.
  llvm::SmallVector<llvm::CallInst *, 8> ThetaCalls;

  // ⚠ `PhiCalls` IS PERMANENTLY EMPTY SINCE bd test_C_libtooling-3qlq Inc 1
  // (2026-09-05). It used to hold the 15-width `@cq_phi_<sfx>(x, angle)`
  // family; that family is RETIRED (`CQ.h` no longer declares it, and
  // `resolveSources` no longer resolves it), so NOTHING pushes into this
  // vector any more — `grep -rn "PhiCalls.push_back" ir-pass/` finds
  // nothing. It is KEPT rather than deleted because PRD
  // `retire-swap-route-PRD.md` §6.2 row P6 rules that the ~30 "Rz is
  // diagonal and exempt" clauses reading it become VACUOUS, not deleted:
  // every one of them is a `for`/`insert(begin,end)`/`empty()` over this
  // vector and is therefore correct — and inert — on an empty one, whereas
  // deleting the field would mean editing ~30 sites in the Rule-13 lowering
  // core to no behavioural end.
  //
  // The register-free branch phase does NOT reuse this list. It has its own,
  // `PhaseCalls` below, precisely so that no clause written for a call with
  // an arg-0 WIRE and an arg-1 ANGLE can ever be handed a `void(double)`
  // call whose `getArgOperand(0)` is the angle and whose `getArgOperand(1)`
  // is out of range.
  llvm::SmallVector<llvm::CallInst *, 8> PhiCalls;

  llvm::SmallVector<llvm::CallInst *, 8> MeasureCalls;

  // bd test_C_libtooling-3qlq Inc 1 (PRD `retire-swap-route-PRD.md` §4.1,
  // owner decision D1) — the REGISTER-FREE `void @cq_phi(double)` BRANCH
  // PHASE call sites, in basic-block order.
  //
  // It is neither a taint SOURCE nor a taint PROPAGATOR: it has no data
  // operand at all, so there is nothing to propagate through. It is ordered
  // by the BLOCK it sits in, not by taint. Its single operand is the
  // classical ANGLE (Rule 3) — a TAINTED angle declines loudly.
  //
  // Consumers: the control classifiers (which claim a call sitting in a
  // tainted arm and lower it by kickback on the condition flag) and
  // `deleteGlobalPhases` (which deletes every surviving one — an
  // uncontrolled or classically-controlled branch phase is a GLOBAL phase,
  // owner decision D2). Emitters that erase one MUST scrub it from here.
  llvm::SmallVector<llvm::CallInst *, 8> PhaseCalls;

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

  // Control-in-place rotation arms (control-in-place-PRD §6, bd
  // test_C_libtooling-drbq Inc 1). Maps a `@cq_theta_<sfx>` call that
  // `SwapRouteEmit`'s in-place rotation-arm emitter HOISTED out of a tainted
  // arm into the pred, to the i32 control flag it must fire under.
  // `lowerRotations` then mints `cqrt_ry_<W>_controlled(flag, handle, θ)` at the
  // hoisted position instead of the unconditional `cqrt_ry_<W>(handle, θ)`.
  //
  // HOIST-AND-DEFER, and the reason it is not "emit the controlled gate in the
  // emitter" (PRD §6): every PRE-lowering wire walker (`WireWalk`,
  // `LoopLowering::collectRailGates`, `ArmClassify`'s cond-wire scans,
  // `declineStaleRecordOps`) recognizes an in-place Ry by its `@cq_theta_`
  // spelling with the wire at arg 0. Leaving the theta call alive until
  // `lowerRotations` means those walkers keep seeing a theta on `R` where one
  // will fire — over-approximating a CONTROLLED gate as UNCONDITIONAL, which is
  // the safe direction for every staleness fence.
  //
  // ⚠ IT LIVES ON `TaintSet`, NOT ON `ControlPlan`, AND THAT IS DELIBERATE
  // (deviation from the PRD's suggested home, recorded because a reviewer will
  // check). There is not ONE `ControlPlan` per compilation: the yn71 onward-
  // control fixpoint (`TaintPropagation::detectAndLowerOnwardControl`) builds a
  // LOCAL `plan2`, emits its regions, and DISCARDS it, while `lowerRotations`
  // is later handed the FIRST plan. A `ControlPlan`-hosted map would therefore
  // silently lose an onward region's entries and lower its hoisted theta
  // UNCONDITIONALLY — an unconditional Ry where a controlled one was meant, i.e.
  // a verify-clean wrong unitary. `TaintSet` is the one object every emitter and
  // `lowerRotations` share. Empty for a module with no in-place rotation arm.
  llvm::DenseMap<const llvm::CallInst * /*theta*/, llvm::Value * /*flag*/>
      ControlledRotations;

  // ⚠ THERE IS NO `ControlledRotationRails` MEMBER, AND ITS ABSENCE IS THE FIX
  // (bd test_C_libtooling-drbq Inc 1, round-1 review L3 §1 / L5 §1). The
  // "register a controlled rotation fired on is FROZEN" fact used to live here
  // as a `SmallPtrSet<Value *>` populated by `lowerRotations` with the theta's
  // arg-0. That is a PRE-`lowerOps` SSA value: for a DERIVED base (`r = p*5`,
  // `p+5`, `p^5`, `p&5`, `zext p`, `@llvm.sqrt(p)`) it is the raw LLVM
  // instruction, which `lowerOps` — the very NEXT pipeline stage — RAUWs to a
  // `cq_template_*` result and ERASES. The set then held a dangling pointer, the
  // live rail was in no owner set, and the whole-DAG spine emitted a
  // `cqrt_ry_<W>_controlled(f, h, -θ)` naming an already-`cqrt_free`d flag
  // followed by a `cqrt_free` of a still-dirty, condition-entangled register:
  // `opt` exit 0, verify-clean, a hidden measurement (Rules 6/8). MEASURED on 5
  // of 5 out-of-place base opcodes and through two independent `promote()`
  // paths.
  //
  // The freeze is now asked STRUCTURALLY of the emitted gate —
  // `ChainWalk::railCarriesControlledRotation(H)` — which derives the rail from
  // the gate's arg-1 USE at query time and therefore cannot go stale, cannot
  // dangle, and cannot be address-reused. Read that function's header before
  // re-introducing any `Value *`-keyed owner set for this fact.

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

  // ── M-B INCREMENT 6, clause (d2) — the EMITTER-RECORDED FLAG STRIP (bd
  //    test_C_libtooling-160a) ────────────────────────────────────────────────
  //
  // The void OUT-FIRST flag strips a Phase-4 emitter mints for a region whose
  // teardown it OWNS: `cq_template_<cmp>_<W>_hl_unc(flag, operands…)` (bd
  // `8txa`). Slot 0 is the flag rail the strip ZEROES and the emitter frees on
  // the very next line; slots 1.. are the FORWARD compare's operands, READ and
  // left exactly as the forward mint found them.
  //
  // WHY THIS SET EXISTS. A region whose condition is DERIVED
  // (`if (sqrt(a+3.0) <= 5.0)`) computes its compare operand through a chain of
  // template rails, and the LAST of those rails has TWO users: the forward flag
  // mint and this strip. `ChainWalk::isInteriorConsumer` refuses every `_unc`
  // outright — correctly, since discharging a rail at the anchor its FORWARD
  // consumers imply would free it before the strip re-reads it — so the rail
  // leaked and the whole Grover-with-a-nontrivial-oracle shape declined at the
  // M-A guard. Membership here is what lets that one `_unc` count as a READ,
  // which moves the interior partition's `dagInsertPoint` to just after the
  // strip and makes the chain discharge THERE (bd 6uqc's P0).
  //
  // MEMBERSHIP, NEVER A NAME TEST. `_unc` symbols are also what the Phase-5
  // uncompute spine and the 7.4 reverse-play mint, and admitting those by name
  // would let one partition discharge a rail another partition's adjoint still
  // reads (Rule 8's shared-prefix hazard, from the other side). Only a strip a
  // control emitter recorded AT ITS EMISSION SITE is in here, and only emitters
  // whose route provably leaves the compare's operands at their forward basis
  // record one (today: `SwapRouteEmit`'s flat PHASE-arm region — diamond,
  // if/else and the eq-folded diamond that reuses it). Every other strip —
  // value-arm, 4.3 nest, 4.4 select, 4.5 switch, the 6.5 classical-call arm, the
  // 7.6 controlled tape write — deliberately stays OUT and its condition chain
  // keeps leaking, each pinned by a leak fixture.
  llvm::SmallPtrSet<const llvm::CallInst *, 4> DischargedFlagGates;

  // A control region's `cqrt_cswap` ROUTE GROUP on one base register, recorded
  // ONLY where executing the WHOLE group provably restores that register's BASIS
  // LABEL (a phase-arm route-in/route-back pair per arm: the join is the literal
  // adjoint of the split, and at most one arm's swap fires per branch).
  //
  // Consumed by the M-B interior partition's clause-(d) scan as a THIRD disjunct
  // beside LEFT and RIGHT: a route group EVERY member of which lies strictly
  // inside the interval [first recovered gate reading the base, discharge point]
  // is a no-op on the base's label over that interval, so an adjoint placed
  // after it reads the SAME basis the forward gate read. That is precisely what
  // makes an Increment-6 discharge — which by construction sits AFTER the
  // region's route-back, because the flag strip is one of its anchors — legal.
  //
  // THE GROUP IS ATOMIC AND THAT IS THE WHOLE FENCE. One HALF of a route pair
  // inside the interval is NOT restoring (the base holds |0> or |x> depending on
  // the flag), so the scan admits a group only when EVERY member is inside;
  // mixed positions leak. A route whose join is NOT the adjoint of its split —
  // the method-B VALUE arm, whose route-back carries the arm's ANSWER onto the
  // base — is never recorded at all.
  //
  // ⚠ THE BASE IS READ FROM THE GATES, NEVER STORED. A `cqrt_cswap(flag, base,
  // rail)` names its base in ARG 1, which is a USE and therefore follows every
  // later RAUW; a `Value *Base` field captured at emission time does NOT.
  // `lowerControlRegions` runs BEFORE `lowerRotations`, which RAUWs the
  // `@cq_theta` result to the `cqrt_alloc_<W>` handle AND ERASES the theta call —
  // so a stored base would be both stale and dangling by the time `uncompute`
  // asks. (Measured: the first draft of this stored it, and every group silently
  // failed to match, which read exactly like a missing recording.)
  //
  // ⚠ NO WRITER AT HEAD SINCE bd test_C_libtooling-drbq Inc 2a — THIS SET IS
  // PERMANENTLY EMPTY. `SwapRouteEmit::emitRegion`'s phase path was its only
  // writer, and the §6a peephole replaced that path's route with one
  // `cqrt_rz_<W>_controlled`. The exemption the set existed to grant moved to
  // `Uncomputation::preservesBorrowedParent` clause (1b), where it is a POINTWISE
  // property of a diagonal gate rather than a group property of two swaps; read
  // the note above `routeGroupFullyInside` before re-enabling a writer or
  // deleting either end.
  llvm::SmallVector<llvm::SmallVector<const llvm::CallInst *, 4>, 4>
      RestoringRoutes;

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

  // bd 3qlq Inc 1, the THIRD C-1 review round's finding F-C1B-1 — THE SUBSET OF
  // `InPlaceRailOps` THAT `commitOutOfLoopInPlaceOps` PREDICTED, and therefore the
  // exact set `lowerOps` must RE-ASK.
  //
  // The other three writers of `InPlaceRailOps` (round 1's `railRoot` marking,
  // `tryCaseA`'s ACCEPT, `collapseRailPhisIn` step (3)) mark ops on a rail they
  // have just PROVED — a closed self-cycle with its own fan-out and record
  // fences — so their marking is a conclusion. `commitOutOfLoopInPlaceOps` is the
  // one writer whose marking is a PREDICTION of what `ArithLowering`'s M-C fence
  // will answer at `lowerOps`, taken BEFORE `repropagateControlMerges` has grown
  // `taint.Tainted` and before the round-2 flatten has moved a block. Keeping the
  // two apart is what lets the tripwire re-verify exactly the predictions and
  // leave the proofs alone (re-verifying a proof would re-ask a question under a
  // fence — `inPlaceFenceHolds`' G5 loop clause — that the proof's owner
  // deliberately answers differently).
  //
  // Written and rolled back in lockstep with `InPlaceRailOps` by
  // `invariantRegisterRoots`; read ONCE, by `lowerOps` Phase 1. Empty for a module
  // with no committed pre-loop in-place op.
  llvm::SmallPtrSet<llvm::Instruction *, 4> PreLoopCommittedInPlaceOps;

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

  // bd test_C_libtooling-8h7d.5 (Phase 7.3 Increment 3) — the SURVIVING `Pred`
  // block of every tainted-control region that `ControlDetect` admitted INSIDE a
  // loop (`ControlRegion::InLoop`) and `SwapRouteEmit` then emitted + flattened.
  // `flattenRegion` never erases a `Pred`, so these pointers stay valid; they are
  // the ROUND-2 trigger `collapseFlattenedLoopRails` keys on, so a module with no
  // in-loop control pays nothing and is byte-identical. Recording the block (not
  // the loop) is deliberate: the flatten rewrites the CFG, so any `Loop*` captured
  // at emission time would be stale by round 2 — the block survives, and round 2
  // rebuilds `LoopInfo` and asks which loop now contains it (Rule 9: never cache
  // an analysis across a mutation).
  //
  // A COUNT, NOT A MEMBERSHIP — bd 3qlq Inc 1, the SECOND C-1 review round's
  // finding F-C1-2(2b). The round-2 onward pass keys "did round 2 open anything
  // in this loop?" on the DIFFERENCE between this map and the snapshot taken at
  // `repropagateControlMerges` entry. As a SET that difference was structurally
  // blind to the commonest mixed shape: round 1 flattens its region into `Pred`,
  // round 2's onward region flattens into the SAME (now larger) `Pred`, the set
  // does not change, and the loop was NEVER RE-OFFERED — MEASURED on
  // `p/r40_onward_r1open.c` (exactly one `[DBG] loop hdr=` line, `round2=0`),
  // where the round-1 marking had bailed `!AnyLocal` because the round-2 values
  // were not yet tainted, so nothing was ever marked and every per-trip
  // which-path rail leaked. A COUNT moves whenever a region is emitted, which is
  // exactly the event "a round-2 region opened here". Membership (`count(BB)`,
  // `empty()`) reads identically on a `DenseMap`, so the trigger and the
  // per-block test above are unchanged.
  llvm::DenseMap<const llvm::BasicBlock *, unsigned> InLoopFlattenedPreds;

  // bd 3qlq Inc 1, the SECOND C-1 review round's finding F-C1-2(2a) — THE RAIL
  // ROOTS A CASE-A COLLAPSE HAS ALREADY CLAIMED, module-wide.
  //
  // `invariantRegisterRoots`' clause (0) must skip a candidate the collapse
  // already owns, or clause (iii) sees that rail's in-body `cq_theta` and refuses
  // the whole extension — taking the INVARIANT register's discharge down with it
  // (that is finding C-1 itself). Round 1's fix passed the LOCAL `Roots` set
  // `collapseRailPhisIn` had just filled, which is right only when the collapse
  // happened in the SAME call. It does not for the commonest onward shape: when
  // the in-loop region's condition reads a 6.5/4.5 `%out` rail, the loop's
  // control is CLASSICAL at round 1, so ROUND-1 `lowerLoops`/`tryCaseA` collapses
  // the carried rail itself; by the round-2 pass there is no header phi left,
  // `collapseRailPhisIn` returns `NotClaimed`, and the local set is empty.
  // MEASURED (`p/r33_onward_inv_only.c`, `p/r35_onward_diffusion.c`): 3
  // `cq_template_and_i32_hl` mints, ZERO `_unc`, against a hand-unrolled twin
  // that discharges all three.
  //
  // So the fact comes from the TREE, not from a local: filled at BOTH Case-A
  // collapse sites (`tryCaseA`'s ACCEPT and `collapseRailPhisIn` step (4)) and
  // read by clause (0) in UNION with the local carried roots — one fact, two
  // writers, one reader (Rule 14).
  //
  // NOT INFERRED FROM THE ABSENCE OF A HEADER PHI, deliberately: an in-place gate
  // whose result is DEAD in the body (`int t = cq_theta(r,.1);`) mints no phi and
  // carries no claim, and admitting it would grant the marking on a rail nothing
  // proved. Pinned by `p/x3_deadgate_body.c`, which still leaks.
  //
  // ENTRIES CANNOT DANGLE AT ANY READ, and the argument is the call order, not
  // luck: every entry is the still-pre-lowering `cq_theta` root mint (or a
  // clause-(ii-b) `cqrt_alloc` out-rail), both writers run before
  // `lowerRotations` — the only stage that erases a root — and both readers
  // (`collapseFlattenedLoopRails` at round 1 and at round 2) run before it too.
  // ⚠ RETIREMENT TRIGGER: if a stage that erases a `cq_theta` is ever placed
  // between `lowerLoops` and the round-2 collapse, this set needs a
  // `WeakTrackingVH` or a re-validation, because a recycled address matching a
  // live peel root would SKIP a candidate that must be judged — the over-accept
  // direction, not the leak direction.
  //
  // ⭐ KEYED ON `(root, the CLAIMING LOOP's header)`, NOT ON THE ROOT ALONE — bd
  // 3qlq Inc 1, the THIRD C-1 review round's finding **F-C1B-2**. Round 2 shipped
  // this as a module-wide set of ROOT VALUES, while the property clause (0) skips
  // on is PER-LOOP: "*this* loop's collapse already proved *this* rail". A claim
  // made for loop A therefore satisfied clause (0) for loop B, where clause
  // (iii)'s per-loop question — is there an in-loop in-place gate on this root? —
  // was then never asked. MEASURED (`p/z32_claim_across_loops_nomeas.c`: loop A
  // carries `r` and is claimed by `tryCaseA`; loop B has an onward per-bit region
  // and a DEAD `cq_theta(r,0.2)` in its body) — `claimed=1` from LOOP A, `IRR
  // TRUE`, `markIfRailLocal MARKED 1 blocks`, i.e. loop B marked on a rail loop B
  // never proved. That is exactly the grant the "NOT INFERRED FROM THE ABSENCE OF
  // A HEADER PHI" paragraph above says must not happen, and the control that
  // pins it (`p/x3_deadgate_body.c`) structurally cannot see it: a ONE-LOOP
  // module cannot bound a MODULE-WIDE set. No wrong circuit was reachable — every
  // spelling declines at a later loud fence — so the finding is a soundness-
  // argument gap, and the key is narrowed rather than the pin re-argued.
  //
  // THE KEY IS THE HEADER BLOCK, and a mis-key can only ever REFUSE. If a header
  // pointer ever failed to survive to the read (RegionFlatten erases MERGE and
  // ARM blocks; a loop the round-2 collapse re-offers is looked up in a FRESHLY
  // BUILT `LoopInfo`), the claim simply would not match, clause (0) would judge
  // the candidate, clause (iii) would refuse it, and the module would keep
  // today's leak — the Prime-Directive direction, never an over-accept. That
  // asymmetry is why a block pointer is an acceptable key here at all, and it is
  // measured rather than assumed: `r33`/`r35`/`r40`/`z9`/`z10` — every shipped
  // customer whose claim is written in a DIFFERENT call from the read — stay
  // 3/3 rolled-vs-unrolled IDENTICAL after the re-key.
  llvm::DenseSet<std::pair<const llvm::Value *, const llvm::BasicBlock *>>
      ClaimedRailRoots;

  // Issue dugh (Phase 4×6) — the untainted-capable control-merge OUT-rails. The
  // two accept paths that build a DATA-untainted-yet-quantum-by-control merge
  // register — the 6.5 classical-call arm (`emitClassicalCallArmRegion`) and the
  // 4.5 switch data-mux (`emitSwitchDataMuxRegion`) — RAUW their merge phi to a
  // fresh `%out = cqrt_alloc_<W>` handle and record it HERE. The FIRST `propagate`
  // (data-flow taint from `cq_theta`) ran BEFORE `%out` existed and classified its
  // onward consumers as classical; `repropagateControlMerges` (run right after
  // `lowerControlRegions`) re-seeds a forward propagation from this set so an
  // onward QUANTUM flow (arith / phase / local-array Shadow store) is re-tainted
  // and lowers, while an onward CLASSICAL escape (store / opaque call / non-i32
  // ret) declines via the re-run escape net. A rail whose merge WAS already
  // tainted (a `q`-straight-through classical-call arm) is recorded too — the
  // re-propagation is idempotent for it (its onward users were tainted by the
  // first round). Populated by the two emitters; consumed once by
  // `repropagateControlMerges`. Empty for a module with no untainted-merge region.
  llvm::SmallPtrSet<llvm::Value *, 4> UntaintedMergeRails;

  // iw81.7 — guarded Shadow stores. Maps a tainted-index `store` that
  // `emitGuardedStoreArmRegion` proved sits under a depth-1 tainted diamond (the
  // GuardedStoreArm region) to the path-predicate FLAG handle minted from that
  // diamond's condition. The control emitter records the (store→flag) pair and
  // FLATTENS the diamond BEFORE `lowerShadowMemory` runs; `lowerShadowMemory` then
  // consults this map and emits the GUARDED store
  // `cqrt_qram_store_<W>_controlled(flag, arr, idx, val)` (arg-0 flag) instead of
  // the plain `cqrt_qram_store_<W>(arr, idx, val)`. The `StoreInst*` key is stable
  // across the flatten (a splice preserves instruction identity) and is the same
  // pointer `classifyShadowAccess` hands back as `A.MemOp`. The flag is left LIVE
  // (never eagerly stripped) so the whole-DAG LIFO uncompute reverses the guarded
  // store via `..._controlled_unc` (pred arg 0) and then strips the flag (the
  // flag-mint compare is a reversible DAG ancestor, §6.0 compare `_unc`). Empty
  // for a module with no guarded store.
  llvm::DenseMap<llvm::StoreInst *, llvm::Value *> GuardedStores;

  // ── M-A Increment 1 (bd test_C_libtooling-6uqc, owner ruling 2026-08-27) ──
  //
  // EMITTER-RECORDED GATE SETS for the LATE (post-`uncompute`) live-record guard
  // `warnLiveRecordRotations` (RotationLowering.h). The guard runs after every
  // emitting stage, so "which rail is still undischarged when this Ry fires" is a
  // FACT it reads off the settled module — but two questions cannot be answered
  // from the lowered text at all, and these sets answer them:
  //
  //   (1) WHICH `cqrt_ry_<W>` IS A USER ROTATION. A user's chained `cq_theta` and
  //       the spine's compiler-emitted adjoint `cqrt_ry(h, -θ)` are TEXTUALLY
  //       IDENTICAL in lowered IR. The Inc-0 census had to guess (pairing angles
  //       per handle) and measured that guess wrong in BOTH directions — it drops
  //       a user S† whose angle negates an earlier theta on the same handle, and
  //       PROMOTES a spine adjoint to a phantom user site (SPIKE §1.4 blind spot
  //       A8, §1.5). `RotationLowering` knows the answer exactly, because it is
  //       the only stage that lowers `@cq_theta`/`@cq_phi`, so it records it.
  //   (2) WHICH `cqrt_x`/`cqrt_cswap`/`cqrt_toffoli`/`cqrt_cnot`/
  //       `cqrt_copy_*_controlled`/`cqrt_xorc`/`cqrt_addc` IS AN ADJOINT. These
  //       are SELF-INVERSE (or immediate-negating), so `EmitInverse` reverses them
  //       by re-emitting the SAME call — a spine adjoint and a forward Phase-4
  //       route/merge gate are indistinguishable by name. `emitInverseCall`
  //       records every adjoint it mints.
  //
  // A RAW `cqrt_ry`/`cqrt_cswap`/… hand-written in an already-lowered lit fixture
  // is in NEITHER set, which is the intended reading: it is not a user `cq_theta`
  // and it is not the pass's own teardown. That is what makes the two census
  // artefacts (`lowering_uncompute_sink_move_past_unwalked_gate`,
  // `lowering_uncompute_borrowed_operand_free_order` — SPIKE §9.3 / §2R.5)
  // invisible to the guard BY CONSTRUCTION rather than by a special case.

  // `cqrt_ry_<W>` emitted for a user `@cq_theta` whose arg-0 was CLASSICAL (a
  // SOURCE theta: `cqrt_alloc_<W>` then Ry on the fresh handle). NOT a guard site
  // — a source theta mints its wire, so that wire can carry no record yet.
  llvm::SmallPtrSet<const llvm::CallInst *, 4> UserSourceRotations;

  // `cqrt_ry_<W>` emitted for a user `@cq_theta` whose arg-0 was already a
  // TAINTED handle (a CHAINED theta: Ry in place on the existing wire). THESE ARE
  // THE GUARD'S SITES — an in-place non-diagonal gate on a wire that may still
  // carry live basis records of its own value.
  llvm::SmallPtrSet<const llvm::CallInst *, 4> UserChainedRotations;

  // `cqrt_rz_<W>` emitted for a user `@cq_phi` (a DIAGONAL user gate). Recorded
  // for the same reason as the two above: so a user Rz on a record is not
  // mistaken for spine traffic. The Phase-4 arm Rz (`SwapRouteEmit` /
  // `SwitchRouteEmit` / `NestedRouteEmit`) is deliberately NOT recorded — its
  // arg-0 is always a freshly `cqrt_alloc`'d work RAIL, never a template- or
  // qram-load-minted record, so it can never be a use of a record (see
  // `warnLiveRecordRotations`'s record definition).
  llvm::SmallPtrSet<const llvm::CallInst *, 8> UserPhaseRotations;

  // Every adjoint `EmitInverse::emitInverseCall` minted (the whole-DAG spine's
  // `_unc`s and negated-angle rotations, the Phase-4 value-arm reverse-play, the
  // 7.4 break reverse-play). Consumed by `warnLiveRecordRotations` to answer
  // "is this post-gate mention of the rail the compiler undoing ITSELF?" — the
  // spine-aware deadness reading the owner ruled on 2026-08-27 (SPIKE §2R.5a).
  //
  // COMPLETENESS IS NOT ASSUMED. THE FAIL DIRECTION FOR **THIS** CONSUMER IS NOW
  // THE SAFE ONE, AND THAT IS A RECENT CHANGE — READ BOTH PARAGRAPHS BEFORE
  // ADDING AN EMISSION SITE.
  //
  // HISTORY, because this comment has been wrong in both directions. An early
  // draft claimed an unrecorded self-inverse gate "defaults to SPINE traffic, so
  // a missed recording can only over-decline"; that was FALSE (the Inc-1 Rule-13
  // round's F5 finding) and was corrected to the opposite: a `cqrt_x` /
  // `cqrt_cswap` / `cqrt_toffoli` / `cqrt_cnot` / `cqrt_copy_*_controlled` /
  // `cqrt_xorc` / `cqrt_addc` in none of the teardown categories fell through to
  // "USER DATA USE" and EXEMPTED the record, i.e. unrecorded meant PERMISSIVE.
  //
  // THE F1 RULING (owner 2026-08-28) RETIRED THAT DEFAULT. Clause 3 no longer
  // asks "is this use teardown?" but "does this use's LINEAGE REACH AN OBSERVING
  // SINK?" (`reachesObservingSink`, RotationLowering.cpp), whose default for an
  // unmodelled call is NOT A SINK — and the route/bracket gates are named
  // NON-uses outright, because a routed value returns to its own rail and
  // observes nothing. So for the live-record guard a missed `SpineOps` recording
  // can now only over-DECLINE. `isTeardownUse` survives as ONE of that walk's
  // non-use categories (it is the only way to recognize a re-emitted
  // self-inverse adjoint), so the recorder is still worth threading — it just no
  // longer sits on the over-accept edge for this consumer.
  //
  // ⚠ NOTHING HERE LICENSES DROPPING A RECORDING. Measured 2026-08-28: the ONLY
  // reader of this set in the tree is `isTeardownUse` (RotationLowering.cpp) —
  // every other mention is an emitter WRITING to it — so the safe fail direction
  // above is a property of that one consumer, not of the set. Add a second reader
  // and it has to be re-derived for that reader, from scratch.
  //
  // WHY THE CURRENT RESIDUAL IS STILL SAFE, on a structural argument rather than
  // on the fail direction. Exactly one `emitInverseCall` caller does not thread
  // the recorder: `BennettWrap.cpp` (the Phase-6 clone's reverse-program-order
  // adjoint). Two independent reasons, either sufficient: (a) its emissions land
  // only INSIDE a specialized clone body, and SSA users are FUNCTION-LOCAL, so a
  // gate there can never appear in `R->users()` for a caller-side record — the
  // only cross-function user of a caller value is the clone CALL itself, which is
  // classified on its own; (b) a callee containing any `cq_theta`/`cq_phi` is
  // never lifted (`SpecializeReject.cpp`'s `scanBody`, pinned by
  // `spec_clone_theta_free.ll`), so a clone body holds no `UserChainedRotations`
  // member and therefore no guard SITE at all. Both verified against the source,
  // not assumed.
  //
  // ⚠ ADDING A NEW EMISSION THAT CAN TOUCH A RECORD RAIL IS AN **OVER-ACCEPT**
  // HAZARD, NOT AN OVER-DECLINE ONE. If you emit a self-inverse gate from a new
  // site — or from an existing one on a path that can run outside a clone body —
  // thread `&taint.SpineOps` through it. Forgetting to does not make the compiler
  // noisier; it makes it silently accept a dephased program (Prime Directive).
  llvm::SmallPtrSet<const llvm::CallInst *, 16> SpineOps;
};

// Walks every non-declaration function in `M`, collects theta/phi/measure
// intrinsic call sites in basic-block order, and runs the forward taint
// propagation. The work-list is seeded with each theta's RESULT (the
// suffix's natural ABI scalar — plain SSA, no struct wrapper).
TaintSet propagate(llvm::Module &M, WidthDispatch &wd);

// Is `CI` a REGISTER-FREE branch-phase call (`void @cq_phi(double)`, bd
// test_C_libtooling-3qlq Inc 1)?
//
// EXACT MEMBERSHIP in `taint.PhaseCalls` — deliberately NOT a name test, and
// this is the project's standing accept-side discipline, not a style choice
// (`declineTaintEscapes`' "never name-prefix matching on the ACCEPT side (a user
// function named `cq_theta_evil` must not slip through)"). `PhaseCalls` holds
// exactly the calls whose callee resolved through `WidthDispatch::phaseFn()`
// AND passed the `void(double)` prototype validation, so a user's own
// `void cq_phi(double, double)` or an `i32 cq_phi(double)` is not in it — it was
// already declined loudly at collection and must not be re-read here as if the
// operand at index 0 were an angle.
//
// ONE SPELLING, shared by every consumer (Rule 14): the P1 kickback classifier,
// the P2 angle-select classifier and `deleteGlobalPhases`. Linear over a
// SmallVector that holds one entry per phase call in the module.
bool isRegisterFreePhaseCall(const llvm::CallInst *CI, const TaintSet &taint);

// THE PHASE-CARRIER QUESTION, RE-ASKED FOR THE REGISTER-FREE SURFACE — bd 3qlq
// Inc 1 part A, Rule-13 round-1 finding F-L5-6 (a latent WIDENING the
// increment's own vacuity audit missed).
//
// Three fences ask "does this escaping value's lineage carry a RELATIVE PHASE?"
// and decline if it does: `LoopLowering::breakLineageCarriesPhase` (the §2.6 B3
// fence — a 7.4 `break` whose escaping answer carries a phase),
// `ControlDetect::retLineageCarriesPhase` (controlled `return`) and
// `AbortParkEmit::lineageCarriesPhase` (the 7.2 abort park). All three answered
// it by looking for a `cq_phi_`-prefixed CALL in the value's own SSA lineage.
//
// AFTER D1/D2 THAT PROPERTY IS NOT REPRESENTABLE IN THE LINEAGE AT ALL. A
// register whose branches carry a KICKBACK phase has NO `cq_phi` anywhere in its
// operand graph — the phase is attached to a BRANCH on `c(x)`, and the gate
// lands on a flag ancilla that is not an operand of anything the register
// derives from. So all three silently began answering "no phase" for a value
// that genuinely carries one. That is a WIDENING, not a narrowing, and it is the
// one direction a vacuity audit exists to catch. (Two of the three DID get a
// "⚠ VACUOUS" note, and its stated reason — "a `void(double)` call has no arg-0
// WIRE and no arg-1 ANGLE, so every clause below would be reading the wrong
// operand" — is right for the WIRE-walking predicates and a non-sequitur for a
// CARRIER predicate, which reads no operand at all.)
//
// THIS IS THE REPLACEMENT PROPERTY, and it is deliberately COARSE. It asks: does
// `F` contain a branch phase that is CONTROL-DEPENDENT on a tainted branch? An
// UNCONTROLLED `cq_phi` is a global phase and carries nothing (D2 deletes it),
// so only a branch phase counts; but which REGISTER it attaches to is a
// control-dependence question the three carriers' backward operand walks cannot
// answer, and inventing a precise version inside a Rule-13 fence is not a
// round-1 change. Over-declining is safe here by construction — every one of the
// three consumers turns `true` into a LOUD DECLINE.
//
// ⚠ TIMING IS WHY THE ANSWER CANNOT BE A RECORD WRITTEN BY THE EMITTER. All
// three carriers run BEFORE `lowerControlRegions` (`lowerLoops` → `tryBreak`,
// then `detectControlRegions`), so a `taint.BranchPhasedRegisters` filled in
// `emitPhaseKickbackRegion` would always be empty when they read it. The
// question has to be asked of the SOURCE construct, which is what this does.
//
// ⚠⚠ AND THAT TIMING IS ALSO WHY THE FIRST SPELLING OF IT WAS WRONG — Rule-13
// ROUND-2 finding F-R1-2, a MEASURED plain-C OVER-DECLINE. The clause above
// says "CONTROL-DEPENDENT ON a tainted branch" and the first implementation
// asked `reachedThroughTaintedBranch`, which is `deleteGlobalPhases`' assert and
// answers something strictly weaker: "is a tainted branch anywhere on any path
// reaching this block". That crudeness is SOUND at P7's slot — every tainted
// `br` has by then been claimed-and-erased or declined, so the honest answer is
// always "no" and a "yes" means the Rule-1 invariant broke — and it is UNSOUND
// here, where every tainted `br` is still standing. Measured:
//
//     void abort(void);
//     int slice(int u){ int q = cq_theta(u,0.5);
//       if (q == 5) abort();          /* the 7.2 park                        */
//       cq_phi(0.75);                 /* UNCONDITIONAL — a GLOBAL phase (D2) */
//       return cq_measure(q); }
//
// declined `phase-class value escaping under quantum control` while the SAME
// statement one line earlier compiled, and the round-1 binary compiled both to
// the identical 8-line trace — i.e. a statement the compiler is REQUIRED to
// delete made a compiling program stop compiling. It is now the real predicate:
// `BB` post-dominates some CONTINUING successor of the tainted branch and does
// not post-dominate the branch itself, with post-dominance read over
// RETURNING paths so a `noreturn` arm (the park's own) decides nothing —
// which matches the physics: the park is coherent routing, the remainder runs
// on every branch, and a phase after it really is global. See
// `controlDependentOnTaintedBranch` in `TaintPropagation.cpp`.
//
// The fence stays a DISCRIMINATOR, not a blanket: `if (q>7) cq_phi(0.75); if
// (q==5) abort();` — a genuine BRANCH phase reaching the same park — still
// declines, from plain `clang -O1` C (`control_phase_kickback_abort_*.ll`).
bool functionCarriesBranchPhase(const llvm::Function *F, const TaintSet &taint);

// bd test_C_libtooling-3qlq Inc 1, PRD §6.2 row P7 (owner decision D2) — DELETE
// every SURVIVING register-free `cq_phi`, and ASSERT the Rule-1 invariant that
// makes the deletion sound.
//
// An uncontrolled or classically-controlled branch phase multiplies the WHOLE
// state by `e^{iθ}`: a global phase, unobservable, and therefore deleted. It is
// a documented semantic, not a diagnostic (D2, owner question Q2 assumed answer:
// no remark).
//
// SOUNDNESS RESTS ENTIRELY ON THE POSITION OF THIS STAGE. It runs after
// `repropagateControlMerges` — NOT "immediately after `lowerControlRegions`",
// which is what this sentence said until Rule-13 round-1 finding F-L3-1 measured
// that slot as a CONFIRMED silent miscompile and moved the call in both entry
// points; see the 50-line argument at the call site in `CQLoweringPass.cpp`. By
// then `detectControlRegions` has, at BOTH rounds, either
// CLAIMED every tainted `br`/`switch` (and its emitter erased the phase call it
// claimed) or DECLINED it loudly — Rule 1's "there is no third path". So a
// SURVIVING phase call sits under CLASSICAL control only. That is asserted, not
// assumed: a survivor whose block is reachable through a TAINTED branch
// condition is a violation of the invariant, and it declines LOUDLY
// (`unclaimed branch phase under quantum control`) instead of being deleted —
// deleting it would silently drop a quantum-conditional phase (PRD §10.3 lens
// 4).
//
// A survivor whose ANGLE is TAINTED also declines, with the same
// `quantum-derived rotation angle` string the retired suffixed family used: an
// accepted angle select (P2) has already been erased by its emitter, so a
// tainted angle reaching here is one no classifier claimed.
void deleteGlobalPhases(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

// Issue dugh (Phase 4×6) — the SECOND propagation round for control-merge
// out-rails. Wired right AFTER `lowerControlRegions` in BOTH pipeline entry
// points (the twin-pipeline trap). A no-op when `taint.UntaintedMergeRails` is
// empty (no 6.5 classical-call arm / 4.5 switch data-mux region emitted).
//
// The two untainted-merge emitters build a fresh `%out` quantum handle and RAUW
// their (data-untainted) merge phi to it, but the first `propagate` ran before
// `%out` existed, so `%out`'s onward consumers were classified CLASSICAL. This
// re-seeds a forward taint propagation from those rails (skipping the emitted
// `cqrt_*`/`cq_template_*` scaffolding so uncompute parity with the tainted-merge
// case is preserved), then re-runs the taint-gated guards on the newly-tainted
// onward flow: `detectAndLowerOnwardControl` (yn71 — a new tainted-condition
// br/switch/select on `%out` is RE-DETECTED + emitted as a fixpoint via the
// step-183/184 machinery, the known shapes lowered and the rest declined loudly;
// replaces dugh's blanket `declineReClassifiedControl`), `declineTaintEscapes`
// (onward classical escapes — store / opaque call / non-i32 ret still decline via
// the precise net), and `declineStaleRecordOps` (an onward stale-record hazard).
// The remaining downstream stages (QRAM/Shadow/IO, rotations + the tainted-angle
// guard, ops, measures, uncompute) then lower the onward QUANTUM flow. `plan6` is
// forwarded to the re-run `declineTaintEscapes` (its Phase-6 carve-out).
//
// bd 0vvq (Increment 2): `plan6` is taken by MUTABLE reference because the round-2
// spec-clone RE-PLAN (`replanReseedSpecialization`) UPDATES a `plan6.Pending`
// candidate's per-arg mask (or drops it to `plan6.Diagnosed` on a loud decline)
// when a round-2-tainted `%out` argument no longer matches its frozen round-1 mask
// — the fix that unfreezes the spec-clone half of dugh's `declineReseedIntoFrozenPlan`.
void repropagateControlMerges(llvm::Module &M, WidthDispatch &wd,
                              TaintSet &taint, SpecPlan &plan6);

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
