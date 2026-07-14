// CQLoweringPass.cpp — thin orchestrator for the cq-lowering pass.
//
// Per-step bodies live in width-resolver / taint / rotation / opcode /
// measure modules. Width parameterization handles `_Bool` / `i8` /
// `i16` / `i64` / `f32` / `f64`.

#include "CQLoweringPass.h"

#include "ByRefInline.h"
#include "ControlPlan.h"
#include "IOSinkLowering.h"
#include "LoopPlan.h"
#include "MeasureLowering.h"
#include "OpcodeLowering.h"
#include "PredMuxFlatten.h"
#include "QramLowering.h"
#include "RotationLowering.h"
#include "SpecializeDetect.h"
#include "SpecializePlan.h"
#include "Specialization.h"
#include "SwapRouteEmit.h"
#include "TaintPropagation.h"
#include "Uncomputation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <algorithm>

using namespace llvm;

namespace cq {

namespace {

// Module-level cleanup: erase the front-end intrinsic declarations now
// that all call sites have been lowered. Matches the architecture's
// promise that no @cq_theta_<sfx> / @cq_phi_<sfx> / @cq_measure_<sfx>
// remains in the IR after this pass. Gated on Changed so a passthrough-
// classical module stays byte-identical.
void eraseDeadDecls(Module &M, WidthDispatch &wd) {
  for (StringRef Name : wd.frontEndIntrinsicNames()) {
    if (Function *FE = M.getFunction(Name)) {
      if (FE->use_empty())
        FE->eraseFromParent();
    }
  }
}

}  // namespace

PreservedAnalyses CQLoweringPass::run(Module &M, ModuleAnalysisManager &) {
  WidthDispatch wd(M);
  TaintSet taint = propagate(M, wd);

  // No quantum work anywhere in the module: leave the IR byte-identical
  // and (crucially) emit no runtime/template decls. The
  // passthrough_no_quantum LIT fixture pins this path. PhiCalls is in the
  // predicate so a classical-only-phi module still runs (and deletes the
  // phi) — else an unresolved @cq_phi_* extern is a Stage-3 link error.
  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty() &&
      taint.MeasureCalls.empty())
    return PreservedAnalyses::all();

  // p119: tainted by-ref MATH (frexp/modf/remquo) recognition is REMOVED — those
  // are library functions, now source-injected, not name-recognized. A tainted
  // un-injected by-ref libm call declines via `declineTaintEscapes`. The g7ip
  // by-ref out-param INLINER below (a VISIBLE user body) is unrelated and stays.
  //
  // bd g7ip: by-ref out-param on a VISIBLE user function. This INLINES the pure
  // store-value producer of a
  // visible user body `void f(v…, T* out){ *out = g(v…); }` into the caller and
  // RAUWs the read-back load — Architecture A (owner decision 2026-07-01), sound
  // because the out-cell is a single-write/single-read fresh scalar with a
  // CLASSICAL address, so the reversible store→load round-trip collapses (== the
  // IR clang -O1 emits when the helper inlines; see `bd memories
  // g7ip-inline-producer-design`). Runs after the g387 fixpoint and BEFORE
  // detectSpecializations so a provable shape is canonicalized to plain SSA before
  // the specializer/escape guard see it; an off-pattern shape is left untouched
  // and falls through to the existing loud declines (ACCEPT-ONLY). Re-`propagate`
  // to taint the inlined producer's downstream; FIXPOINT for nested producers.
  while (lowerByRefInline(M, taint))
    taint = propagate(M, wd);

  // bd iw81.1: fold same-width int<->int `bitcast` identity FIRST, right after
  // taint settles and BEFORE any analysis. A folded bitcast is `result===operand`
  // (ONE physical wire); folding it away up front means every downstream bespoke
  // provenance/lineage/stale/control walk sees the operand's true wire directly —
  // never an opaque identity node it would have to special-case (the Rule-13
  // finding: three distinct consumers — the stale-record chained-theta hop,
  // SelectClassify's coherent-use gate, the I/O tape lineage check — each blind to
  // a re-rotation hidden behind a standing fold). The module reduces to the exact
  // DIRECT-operand form the pass already adjudicates correctly. A pure taint-
  // preserving RAUW+erase (the freeze-fold precedent), so NO re-propagate is
  // needed. fp<->int / vector bitcasts are left standing to decline at castInScope.
  foldIdentityBitcasts(M, taint);

  // bd 3c6m.14 Inc 3 — volatile-const global-load fold (QramLowering.cpp): the
  // openlibm anti-const-fold idiom (`static volatile double twom1000`,
  // `*(volatile double *)&atanlo[3]`) folds to the initializer constant when
  // the global is internal, definitively initialized, never stored, and never
  // address-escaped. Runs HERE — after the passthrough early-out (a cq-free
  // module stays byte-identical) and BEFORE the PredMux fixpoint, whose E4
  // admits no volatile access (unfolded, these block the tainted arm). Folded
  // loads are classical, so taint is unaffected (the bitcast-fold precedent —
  // no re-propagate needed).
  foldVolatileConstGlobalLoads(M);

  // bd 3c6m.14 (L6) — PredMux: general acyclic tainted control flattened to
  // block-predicate select chains (PredMuxFlatten.cpp; PRD
  // docs/prd/phase-07-expressiveness/3c6m.14-L6-control-predication/). Runs
  // HERE — after taint settles + the bitcast fold, BEFORE every analysis
  // guard — so the escape/stale guards, loop lowering, control detection,
  // select classification, and uncompute all see the post-flatten IR through
  // their normal entry points (the 2qyz full-re-run lesson holds by
  // construction: the guards below simply run after the fixpoint). ACCEPT-
  // ONLY: an ineligible shape is left byte-untouched and falls through to the
  // existing loud declines; regions with cq_* calls / stores / loads / loops
  // are never claimed, so every shipped accept shape reaches its owner
  // byte-identically. One region per iteration + a full re-propagate (the
  // lowerByRefInline fixpoint precedent) so each claim sees fresh
  // dominance/taint state and sequential siblings compose without any cached
  // block identity crossing an erasure (Rule 9).
  while (flattenPredMuxRegions(M, taint))
    taint = propagate(M, wd);

  // Phase 6 specialization PRE-PASS (C-Plan, DD-1): pure analysis by SSA
  // identity, BEFORE `declineTaintEscapes`, so the carve-out's membership test
  // (`shouldSpecialize` / `plan6.Diagnosed`) is populated when the escape guard
  // runs. It enters ONLY proven-Accept sites into `plan6.Pending` and loud-
  // declines classified rejects (recording them in `plan6.Diagnosed`); every
  // candidate-shaped-but-unproven site is left for the carve-out to decline.
  SpecPlan plan6;
  detectSpecializations(M, taint, wd, plan6);

  // Taint-escape guard (test_C_libtooling-bxv): pure analysis, FIRST — before
  // any mutation — because the escape is only diagnosable on pre-RAUW SSA
  // identity (after rotation lowering every tainted value IS the i32 handle
  // and an unknown call reading it is verify-clean). Declines loudly any
  // consumer of a tainted value the lowering does not own (unknown callee /
  // store / unsupported instruction), EXCEPT a site the Phase 6 pre-pass owns
  // (clone-on-taint) or already loud-declined (carve-out, C-Plan).
  declineTaintEscapes(M, taint, plan6);

  // Straight-line stale-record guard (test_C_libtooling-uzb): pure analysis,
  // FIRST — before any mutation — because it needs SSA-record identity
  // (rotation lowering's RAUW collapses the pre-/post-Ry values onto one i32
  // handle) and the original schedule (= the emitted opaque-call stream). It
  // diagnoses loudly and marks `taint.StaleDeclined` for `lowerOps` to skip.
  declineStaleRecordOps(M, taint);

  // Controlled Tier-0 conditional output (Phase 7.6 Increment 2): a tainted
  // `if (q > k) printf("%d", x)` lowers to ONE `cqrt_tape_write_<W>_controlled`
  // under the minted flag. Runs BEFORE `detectControlRegions` — the void-arm
  // `if(q)printf` diamond has NO merge phi, so `recoverRegion` would otherwise
  // loud-decline it as OffPattern ("control flow under quantum control"). This
  // step recognizes that I/O-sink shape, emits the controlled write, and flattens
  // the diamond, so detection only ever sees real phase/value control regions; an
  // off-pattern I/O-under-control shape declines loudly here. Also pre-
  // `lowerRotations` (the still-present `@cq_theta` src; the RAUW-to-handle
  // rewrites every emitted operand later).
  lowerControlledIOSinks(M, wd, taint);

  // Bounded loops (Phase 7.3, epic 799w): a classically-bounded loop over a
  // tainted body lowers ROLLED IN PLACE. `lowerLoops` (LoopLowering.cpp)
  // recognizes the §2.2 sound-rolled invariant by pure LoopInfo/SSA analysis
  // (Rule 9) and collapses each Case-A in-place persistent-rail phi (the
  // loop-carried header phi + the zero-trip/exit merge phi) to its single rail,
  // so the body lowers to `cqrt_rz(%h, angle_i)` over a loop-invariant handle.
  // Runs BEFORE `detectControlRegions` so a quantum/measurement-bounded loop
  // (Q1) is partitioned out with the dedicated `loop under quantum control`
  // message before ControlDetect declines it generically; BEFORE
  // `declineClassicalMuxes` so the collapsed header phi never reaches
  // `kMsgClassicalPhi`; and BEFORE `lowerRotations` (the still-present
  // `@cq_theta`/`@cq_phi` SSA values). A cross-iteration dirty rail (X1) and a
  // tainted-exit loop (Q1) decline LOUDLY here; every other loop is left for its
  // existing owner. A purely-classical loop is untouched.
  lowerLoops(M, wd, taint);

  // Tainted control flow: `detectControlRegions` (ControlDetect.cpp) recognizes
  // the swap-route phase-arm diamond/if-else shape by SSA identity (Rule 9, no
  // mutation), pushes each accepted phase-arm DIAMOND onto `plan.Regions`, and
  // declines everything else loudly ("… under quantum control", opt exits
  // non-zero). `lowerControlRegions` (SwapRouteEmit) then emits the coherent
  // routed stream per region — flag mint → |0> rail → cswap route-in → verbatim
  // Rz on rail → cswap route-back → rail free → icmp_inv flag-strip → flag free —
  // and flattens the CFG. It runs BEFORE `lowerRotations` so it can reference the
  // still-present `@cq_theta` result; the later RAUW-to-handle updates every
  // emitted call (Rule 9). A classical-condition branch stays byte-untouched.
  ControlPlan plan = detectControlRegions(M, taint);
  lowerControlRegions(M, wd, taint, plan);

  // Issue dugh (Phase 4×6): the SECOND propagation round for control-merge
  // out-rails. The two untainted-merge emitters (6.5 classical-call arm, 4.5
  // switch data-mux) built a fresh `%out` quantum handle and RAUW'd their
  // (data-untainted) merge phi to it — but the first `propagate` ran before `%out`
  // existed, so its onward consumers were classified CLASSICAL. Re-seed a forward
  // propagation from `taint.UntaintedMergeRails` so an onward QUANTUM flow (arith /
  // phase / local-array Shadow store) is re-tainted and lowers via the stages
  // below, while an onward CLASSICAL escape / a new tainted-condition control on
  // `%out` declines via the re-run escape + control nets. Runs BEFORE
  // `lowerIOSinks`/`lowerQramReads`/`lowerShadowMemory` (they must see the newly-
  // tainted onward IO/QRAM/Shadow access), BEFORE `declineClassicalMuxes` (a
  // classical mux over a derived `%out` value), and BEFORE `lowerRotations` (the
  // tainted-angle guard + the newly-tainted onward `cq_phi`). A no-op when no
  // untainted-merge region was emitted.
  repropagateControlMerges(M, wd, taint, plan6);

  // Reversible I/O output tape (Phase 7.6): a tainted `printf`/`putchar` lowers
  // to `cqrt_tape_alloc` + `cqrt_tape_write_<W>` append sequences instead of
  // declining at the escape guard above (Rule 5 — NO measurement). Runs BEFORE
  // `lowerRotations` so the sink operand is still the pre-RAUW `@cq_theta`-
  // derived value (the later RAUW-to-handle rewrites every emitted `src` arg);
  // capturing the i32 handle instead would be the opaque-call silent
  // miscompile. A classical-only `printf` stays byte-untouched.
  lowerIOSinks(M, wd, taint);

  // QRAM tainted-index memory (Phase 7.5 Inc 1): a STRAIGHT-LINE tainted-index
  // READ of a const-global table (`return tbl[q]`) lowers to `cqrt_qram_alloc_<W>`
  // + `cqrt_qram_load_<W>` instead of loud-declining at the escape guard above
  // (the matching carve in `declineTaintEscapes`). Runs BEFORE `lowerRotations`
  // so the index operand is still the pre-RAUW `@cq_theta`-derived value (the
  // later RAUW-to-handle rewrites the emitted `idx`); the loaded value joins
  // `Tainted` as an ordinary reversible producer the Phase-5 spine uncomputes.
  // An accepted-shape read with an fp/i128 cell declines LOUDLY here.
  lowerQramReads(M, wd, taint);

  // QRAM tainted-index memory (Phase 7.5 Inc 2): a STRAIGHT-LINE tainted-index
  // STORE/LOAD through an `alloca [N x iW]` (`arr[q]=v; … arr[p] …`, Shadow-shaped)
  // lowers to `cqrt_qram_alloc_<W>` (a TAINTED in-place-mutated register) +
  // `cqrt_qram_store_<W>` + `cqrt_qram_load_<W>`. Runs right after `lowerQramReads`
  // and (like it) BEFORE `lowerRotations` (pre-RAUW SSA identity — the emitted
  // index/value operands are the still-tainted source values the later
  // RAUW-to-handle rewrites). A dead scratch array's stores reverse in LIFO via the
  // Phase-5 spine; an escaped/measured array reverses nothing. An aliasing/escaping,
  // dynamic-N, mixed-access, fp/i128-cell, or mid-sequence-observed alloca declines
  // LOUDLY here (the matching carve in `declineTaintEscapes`).
  lowerShadowMemory(M, wd, taint);

  // Classical-condition mux guard (test_C_libtooling-wi5): a LIVE select/phi
  // reading tainted data that SURVIVES control lowering is classically
  // conditioned (ControlDetect adjudicated every tainted condition above —
  // declined regions already exited opt; accepted regions' merge phis are
  // erased) and no later stage owns it — the Phase-5 FreePoint net is bypassed
  // whenever the base handle is measured/escaped/`main`-resident or
  // non-terminal. Must run BEFORE `lowerRotations` (pre-RAUW SSA identity).
  // One deliberate accept (test_C_libtooling-5j5): the proven ONE-REGISTER
  // merge phi (`if (classical_c) q = cq_phi(q, θ); use(q)`) is RAUW'd to its
  // wire base and erased here instead of declined.
  declineClassicalMuxes(M, taint);

  // Post-lift stale-record re-sweep (test_C_libtooling-2qyz): the lift above
  // RAUWs a merge phi to its wire base AFTER declineStaleRecordOps already ran,
  // so a consumer over a re-Ry'd wire would lower silently. When a lift occurred
  // (witnessed by taint.LiftedConsumers) this re-runs the FULL stale-record
  // sweep on the post-lift IR — a stale op can be a TRANSITIVE consumer any
  // number of in-place-gate hops below the lifted phi, so a scoped re-check is
  // incomplete (Rule-13 finding). Idempotent + still pre-RAUW SSA identity;
  // no-op when nothing was lifted.
  declineLiftedStaleRecordOps(M, taint);

  // Phase 6 specialization DRIVER (step 14, DD-1): drains `plan6.Pending`,
  // cloning each visible pure-classical callee, lowering it under a disjoint
  // `cloneTaint`, and Bennett-wrapping it — strictly BEFORE `lowerRotations`
  // (the clone must be theta-free before the RAUW-to-handle at :110). The clone
  // bodies are invisible to the single module-wide `uncompute` below because
  // `cloneTaint` is never unioned into `taint` (C-Taint); `specialize` re-marks
  // each retargeted call result into `taint` per its post-lowering return-taint.
  specialize(M, wd, taint, plan6);

  // The lowered calls are erased inside each step, so nothing dangles and
  // there is no separate dead-init sweep.
  lowerRotations(M, wd, taint, &plan);
  lowerOps(M, wd, taint);
  lowerMeasures(M, wd, taint);
  // Phase 7.4 Inc 2 (y05j.2): the value-arm `break` capture + whole-loop
  // reverse-play, on the now-LOWERED body (i32 handles). Runs AFTER `lowerOps`
  // (it reuses `emitInverseChain`, which consumes lowered `cqrt_*` calls) and
  // BEFORE `uncompute` (it excludes the break construct from the whole-DAG spine).
  // No-op when no value-arm break was recognized (`taint.BreakRegions` empty).
  lowerBreakReversePlay(M, wd, taint);
  // Phase 5 (PRD §2.8): per-op uncomputation runs LAST, after every other
  // mutation has settled `taint` into its final post-lowering state.
  uncompute(M, wd, taint);
  eraseDeadDecls(M, wd);

  return PreservedAnalyses::none();
}

bool CQLoweringPass::runOnFunction(Function &F) {
  // Compatibility shim for any unit-level caller of the per-function
  // entry point. The canonical lowering loop runs at module scope
  // (so the WidthDispatch / TaintSet objects can amortize across
  // functions); this wrapper preserves the historical Function&
  // signature by routing through a single-function "module view."
  Module &M = *F.getParent();
  WidthDispatch wd(M);
  TaintSet taint = propagate(M, wd);
  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty() &&
      taint.MeasureCalls.empty())
    return false;

  // Restrict the work lists to the requested function. Callers of
  // runOnFunction expect side-effects only on F.
  //
  // AXIS-F HAZARD (WI-4.6): runOnFunction is a DEAD SHIM — Plugin.cpp registers
  // only run() (a ModulePassManager pass), so this entry point has ZERO callers.
  // The restriction below scopes ONLY the rotation/measure work lists to F; the
  // Phase-6 specialization pre-pass (`detectSpecializations`), the carve-out
  // (`declineTaintEscapes`), and the driver (`specialize`) below all walk the
  // WHOLE module M. On a genuine multi-function module that would specialize
  // calls in functions OTHER than F — DIVERGING from the per-F intent. Harmless
  // while unreachable; a future reviver MUST either restrict `plan6` to sites in
  // F or accept (and document) module-wide specialization here.
  auto onlyInF = [&F](auto &Calls) {
    Calls.erase(std::remove_if(Calls.begin(), Calls.end(),
                               [&F](CallInst *CI) {
                                 return CI->getFunction() != &F;
                               }),
                Calls.end());
  };
  onlyInF(taint.ThetaCalls);
  onlyInF(taint.PhiCalls);
  onlyInF(taint.MeasureCalls);
  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty() &&
      taint.MeasureCalls.empty())
    return false;

  // p119: by-ref math canonicalization removed (library functions, source-injected
  // not recognized) — see run(). Twin-pipeline parity preserved by the removal in
  // both entry points.

  // bd iw81.1: fold same-width int<->int bitcast identity, mirrored in this entry
  // point too (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the
  // fold-before-any-analysis rationale.
  foldIdentityBitcasts(M, taint);

  // bd 3c6m.14 Inc 3 — volatile-const global-load fold, mirrored in this entry
  // point too (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the
  // post-passthrough / pre-PredMux placement rationale.
  foldVolatileConstGlobalLoads(M);

  // bd 3c6m.14 (L6) — PredMux flatten fixpoint, mirrored in this entry point
  // too (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the
  // before-every-analysis-guard placement rationale. Note the re-propagate
  // rebuilds module-wide work lists; the F-restriction below this point in
  // the original shim applies only to the rotation/measure lists, and this
  // shim is a documented DEAD entry point (AXIS-F) — parity is kept anyway.
  while (flattenPredMuxRegions(M, taint)) {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.MeasureCalls);
  }

  // Phase 6 specialization pre-pass + carve-out, mirrored in this entry point
  // too (twin-pipeline parity is MANDATORY — a pre-pass wired in `run()` but not
  // here would silently diverge, WI-1.12). See run() for the rationale.
  SpecPlan plan6;
  detectSpecializations(M, taint, wd, plan6);

  // Taint-escape + stale-record guards run FIRST here too (twin-pipeline
  // trap, IMPLEMENTATION §6.5) — see run(). Both are module-scoped like
  // `lowerOps`, which also walks all of `M` (only the rotation/measure work
  // lists above are F-restricted).
  declineTaintEscapes(M, taint, plan6);
  declineStaleRecordOps(M, taint);

  // Controlled Tier-0 conditional output (Phase 7.6 Increment 2) mirrored in
  // this entry point too (twin-pipeline parity is MANDATORY, WI-1.12) — see
  // run() for the pre-`detectControlRegions` ordering rationale.
  lowerControlledIOSinks(M, wd, taint);

  // Bounded loops (Phase 7.3, epic 799w) mirrored in this entry point too
  // (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the pre-
  // `detectControlRegions` / pre-`declineClassicalMuxes` / pre-`lowerRotations`
  // ordering rationale.
  lowerLoops(M, wd, taint);

  // See run() — `detectControlRegions` pushes accepted phase-arm diamonds and
  // declines the rest; `lowerControlRegions` emits the routed stream. BOTH must
  // run in this entry point too, between detection and `lowerRotations`, or
  // unit-level callers silently diverge from `run()` (the twin-pipeline trap,
  // IMPLEMENTATION §6.5).
  ControlPlan plan = detectControlRegions(M, taint);
  lowerControlRegions(M, wd, taint, plan);
  // Issue dugh (Phase 4×6): the SECOND propagation round mirrored in this entry
  // point too (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the
  // pre-`lowerIOSinks`/`lowerQramReads`/`declineClassicalMuxes`/`lowerRotations`
  // ordering rationale.
  repropagateControlMerges(M, wd, taint, plan6);
  // Reversible I/O output tape (Phase 7.6) mirrored in this entry point too
  // (twin-pipeline parity is MANDATORY — a stage wired in run() but not here
  // silently diverges, WI-1.12). See run() for the pre-`lowerRotations`
  // ordering rationale.
  lowerIOSinks(M, wd, taint);
  // QRAM tainted-index memory (Phase 7.5 Inc 1) mirrored in this entry point too
  // (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the pre-
  // `lowerRotations` ordering rationale.
  lowerQramReads(M, wd, taint);
  // QRAM alloca-backed Shadow store/load (Phase 7.5 Inc 2) mirrored here too
  // (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the ordering.
  lowerShadowMemory(M, wd, taint);
  // Classical-condition mux guard in this entry point too (twin-pipeline
  // trap, IMPLEMENTATION §6.5) — see run() for the ordering rationale.
  declineClassicalMuxes(M, taint);
  // Post-lift stale-record re-check (test_C_libtooling-2qyz) — see run().
  declineLiftedStaleRecordOps(M, taint);
  // Phase 6 specialization driver (step 14) — mirrored from run() (twin-pipeline
  // parity, WI-1.12).
  specialize(M, wd, taint, plan6);
  lowerRotations(M, wd, taint, &plan);
  lowerOps(M, wd, taint);
  lowerMeasures(M, wd, taint);
  // Phase 7.4 Inc 2 (y05j.2) — twin-pipeline parity (WI-1.12): miss this and
  // unit-level callers diverge from `run()`. See run() for the staging rationale.
  lowerBreakReversePlay(M, wd, taint);
  // Phase 5 (PRD §2.8): uncomputation runs LAST in this entry point too — miss
  // one and unit-level callers diverge from `run()`.
  uncompute(M, wd, taint);
  eraseDeadDecls(M, wd);
  return true;
}

}  // namespace cq
