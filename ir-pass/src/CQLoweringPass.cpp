// CQLoweringPass.cpp — thin orchestrator for the cq-lowering pass.
//
// Per-step bodies live in width-resolver / taint / rotation / opcode /
// measure modules. Width parameterization handles `_Bool` / `i8` /
// `i16` / `i64` / `f32` / `f64`.

#include "CQLoweringPass.h"

#include "ArithLowering.h"
#include "ByRefInline.h"
#include "ControlPlan.h"
#include "CtlzIdiomPrepass.h"
#include "Fp80Union.h"
#include "IOSinkLowering.h"
#include "LiteralIntegrity.h"
#include "LoopPlan.h"
#include "LoopUnrollPrepass.h"
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

  // bd etiq — volatile-const LOCAL fold (QramLowering.cpp): the alloca sibling
  // of the global fold, for the openlibm rounding idiom kept in a LOCAL
  // (`volatile double vd2 = 0x1.0p32;` in s_cbrtl.c — mem2reg never promotes a
  // volatile access, so the store/load pair survives -O1 and would block the
  // tainted arm at PredMux E4). Single-Constant-store + dominated exact-type
  // loads only; the fold erases the loads, store, lifetime markers, and
  // alloca. Folded values are classical — same no-re-propagate rationale.
  foldVolatileConstAllocaLoads(M, taint);

  // bd k710 — DEAD volatile SCALAR STORE elimination (QramLowering.cpp): the
  // WRITE-ONLY sibling of the two folds above, for openlibm's underflow idiom
  // (`volatile float u = x*x; /* underflow */`, ld80/s_nexttowardf.c:63, `u`
  // never read). Zero loads means neither fold above nor zco4's promotion can
  // claim it, so the volatile store survives to `declineTaintEscapes` and the
  // cell dies on kMsgStore. Grounded in the fenv ruling (owner 2026-08-10): CQ
  // models no FP exception flags and a volatile access to a non-escaping local
  // is not observable. Erases the stores/markers/alloca; the stored VALUE is then
  // trivially dead and, inside a PredMux region, is removed by the pre-existing
  // cleanup at PredMuxFlatten.cpp:2618 — so the emitted circuit generally loses
  // the multiply too, which IS what the ruling licenses (measured: zero
  // `fmul_f32` in slice_libm_ld80_nexttowardf). Outside a region it is instead
  // lowered, uncomputed and freed. See QramLowering.h for the asymmetry.
  eraseDeadVolatileScalarStores(M, taint);

  // bd zco4 — volatile scalar-local SSA promotion (QramLowering.cpp): the mem2reg
  // sibling of the etiq fold above, for the OpenBSD/Moshier "***CAUTION***" idiom
  // where the anti-reassociation `volatile` is on a MULTI-STORE COMPUTED
  // accumulator (`volatile long double z` in e_log10l.c), not a single constant.
  // clang's mem2reg never promotes a volatile access, so the tainted store
  // survives -O1 and declines at kMsgStore. This clears isVolatile + runs
  // PromoteMemToReg on a proven non-escaping single scalar (see QramLowering.h for
  // the gate list). Runs HERE — same slot as the etiq fold, BEFORE the
  // promoteFp80Union / PredMux fixpoints and BEFORE declineTaintEscapes. UNLIKE
  // the const fold, promotion mints TAINTED SSA (the accumulator's stored value
  // reaches its loads), so this is a FIXPOINT with a full re-propagate (the
  // promoteFp80Union precedent) — the promoted phis/values are re-tainted and a
  // scalar exposed by an outer promotion is claimed on the next turn.
  while (promoteVolatileScalarLocals(M, taint))
    taint = propagate(M, wd);

  // bd 3c6m.51 — x86_fp80 union-promotion peephole (Fp80Union.cpp): the ld80 libm
  // cells extract sign/exponent/mantissa through a `union IEEEl2bits` bit-pattern
  // type-pun (`store x86_fp80` then `load iN` at const byte offsets) that LLVM
  // cannot promote (the offset-8 word straddles the undefined padding bytes
  // [10,16)) — so the union stays in MEMORY at CQ's -O1 floor and the tainted seed
  // store would decline at kMsgStore. This rewrites each provable union to
  // `bitcast x86_fp80 -> i80` + lshr/trunc/zext register form, modelling the
  // padding as 0 (sound only under the §4.1 mask fence — an unmasked padding
  // observation loud-declines here). Runs HERE — after the volatile-const fold and
  // BEFORE flattenPredMuxRegions — so the union is register-resident before PredMux
  // (which never claims a region containing loads/stores). A FIXPOINT + full
  // re-propagate (the bitcast-fold / PredMux precedent): promotion mints new
  // `bitcast x86_fp80` on the theta seed, so re-`propagate` re-taints the extracted
  // words + the isnan/exponent branch, and a nested union exposed by an outer
  // promotion is claimed on the next turn. An off-pattern union is byte-untouched.
  while (promoteFp80Union(M, taint))
    taint = propagate(M, wd);
  // Debug lever (bd 3c6m.55; env-gated, no behavior change): dump the module
  // state after the fp80-union promotion fixpoint settles.
  if (::getenv("CQ_FP80_DBG")) {
    llvm::errs() << "=== CQ_FP80_DBG: module after promoteFp80Union fixpoint ===\n";
    M.print(llvm::errs(), nullptr);
  }

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

  // bd 3c6m.55 Inc 2 (Lever B, ticket lf8s) — static-K force-unroll pre-pass
  // (LoopUnrollPrepass.cpp): a PROVEN-constant-trip loop with no cq-family
  // call, no tainted control, and no 799w/dtzb in-place rail structure (the
  // openlibm `__polevll` Horner loops, kept rolled at -O1 by
  // `!llvm.loop.unroll.disable`) is fully unrolled to the straight-line form
  // the substrate already lowers. Runs HERE — after the fp80-union + PredMux
  // fixpoints (the relevance fence must read the SAME settled taint
  // `detectSpecializations` reads: the taint reaching a polevll accumulator
  // flows through Lever-A-promoted unions) and BEFORE `detectSpecializations`
  // (the spec-scan and the later clone must see the unrolled body) and
  // `lowerLoops` (a claimed loop is gone before `tryCaseA` would X1-decline
  // it; the fence is structurally disjoint from every rolled-in-place claim —
  // see the U1–U8 gate proof in LoopUnrollPrepass.h). ACCEPT-ONLY: an
  // off-fence loop is byte-untouched for its existing loud owner. One loop per
  // iteration + a full re-propagate (the PredMux precedent — the unroll erases
  // loop phis and clones body instructions, so `taint` is stale until
  // re-propagated); each unroll re-runs the PredMux fixpoint, since a region
  // that contained the loop (cyclic — PredMux never claims it) is acyclic and
  // claimable once the loop is gone.
  while (unrollConstTripLoops(M, taint)) {
    taint = propagate(M, wd);
    while (flattenPredMuxRegions(M, taint))
      taint = propagate(M, wd);
  }

  // bd ww4c Inc 1 — the shift-count loop -> `llvm.ctlz` idiom recognizer
  // (CtlzIdiomPrepass.cpp): a rotated do-while `do { c--; x <<= 1; } while
  // ((signed)x > 0)` over a TAINTED entry value is replaced by its closed form
  // (C0-1) - (ctlz(v<<1) & (N-1)) — four already-linked template ops, no new
  // frozen symbol. Runs HERE, on the same reasoning as the unroll pre-pass
  // above and for one reason of its own: AFTER the fp80-union + PredMux
  // fixpoints (Z8 must read taint that has SETTLED through them — for the ld80
  // cells that taint arrives through the union promotion; NOT "the same taint
  // the rest of the pipeline reads", which bd ww4c.4 measured false: argument
  // taint is minted later by `detectSpecializations`, so a callee-hosted idiom
  // is never claimed — see CtlzIdiomPrepass.cpp), BEFORE `detectSpecializations`
  // (the spec-scan and any later
  // clone must see the rewritten body), and BEFORE `lowerLoops` (a claimed
  // loop is gone before Q1 would decline it). Same one-claim-per-call +
  // full-re-propagate + nested-PredMux-fixpoint shape: the claim mints tainted
  // SSA and erases the loop's, and the enclosing region was CYCLIC (PredMux
  // never claims a region containing a loop) so it becomes claimable the
  // moment the loop is gone. ACCEPT-ONLY, and note the ONE way this differs
  // from the unroll pre-pass: that fence is DISJOINT from the rolled-in-place
  // owners, while THIS ONE COMPETES WITH Q1 FOR THE SAME LOOPS (Q1 fires on a
  // tainted exiting condition, which every loop here has). So its failure mode
  // is a wrong CLAIM, not a wrong decline — see the Z1-Z9 contract in
  // CtlzIdiomPrepass.h.
  while (recognizeCtlzIdiomLoops(M, taint)) {
    taint = propagate(M, wd);
    while (flattenPredMuxRegions(M, taint))
      taint = propagate(M, wd);
  }
  // Debug lever (bd adia; env-gated, no behavior change): dump the module state
  // the Phase-6 spec-scan reads (post fp80/PredMux/unroll fixpoints).
  if (::getenv("CQ_SPEC_DBG")) {
    llvm::errs() << "=== CQ_SPEC_DBG: module before detectSpecializations ===\n";
    M.print(llvm::errs(), nullptr);
  }

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
  // bd test_C_libtooling-x67f (M-C Increment 7a) — the LATE in-place
  // reassignment round, at the LAST slot before `uncompute`. `lowerOps`' own
  // Phase-1 M-C fence sees an IR in which the M-B interior spine has neither
  // planned nor emitted anything, so a `q -= off` whose parent is read by a
  // DERIVED-condition oracle chain looked like it had an undischarged prior
  // reader and stayed out of place — minting a fresh rail and leaving the
  // original register a dead ancestor record at the next `cq_theta`. This round
  // re-asks the SAME fence on the now fully-lowered module with the M-B
  // discharge PLAN in hand (`planInteriorDischarges`). Purely ADDITIVE: a site
  // Phase 1 already converted never reaches it, and a site it does not accept
  // keeps today's out-of-place lowering byte for byte.
  //
  // WHY HERE AND NOT EARLIER: this is the first point at which every emitter
  // except `uncompute` has run, so the prior readers the fence adjudicates are
  // lowered `cq_template_*` calls (not still-unlowered opcodes, which arm (e)
  // refuses on sight) and the Phase-4 / 7.4 teardown traffic is already inline.
  // WHY NOT LATER: `uncompute` must SEE the conversion, because the in-place
  // gate is a mutation of a borrowed parent that its clause-(d) scan has to
  // adjudicate — that scan is what makes a stale plan a LEAK instead of a
  // misplaced adjoint.
  lowerLateReassignments(M, wd, taint);
  // Phase 5 (PRD §2.8): per-op uncomputation runs LAST, after every other
  // mutation has settled `taint` into its final post-lowering state.
  uncompute(M, wd, taint);
  // bd xy9n — the literal-integrity guard, AFTER `uncompute` and so after the
  // last emitting stage: an `undef`/`poison` literal reaching TWO emitted gate
  // operands is read as two DIFFERENT values at the shipped `-O0` stage 3
  // (`IMPLICIT_DEF` materialises per use), so a forward gate and its adjoint
  // compute inverses of different functions — dirty entangled rail, and the
  // `cqrt_free` that follows is a hidden measurement (Rules 6, 8). This is the
  // ONLY position that provably sees every emitted call, forward AND adjoint,
  // and it is complete there for a PLACEMENT reason, not a provenance one: nothing
  // after this point emits a call or mints a constant, so whatever sits in an emitted
  // slot here is exactly what stage 3 reads. (Do NOT re-derive it from "the pass never
  // synthesizes an undef/poison" — LiteralIntegrity.h explicitly DISOWNS that claim,
  // and an earlier version of this very comment cited the header for it.)
  // the mutation costs nothing observable — a `DS_Error` exits `opt` with zero
  // stdout bytes (measured).
  // The bool IS consumed — the Rule-13 round caught this discarded at first, which
  // made the guard's correctness rest entirely on `diagnose` calling `exit(1)`,
  // the exact dependency LiteralIntegrity.h says it was written to avoid. On a
  // host that swallows `DS_Error` the pass now at least stops here instead of
  // running on and reporting success. It still hands back a MUTATED module on such
  // a host — that is a pass-wide property of every post-mutation decline
  // (`Uncomputation`'s `kMsgLineageMeasured` / `kMsgUninvertible` are the
  // precedent, not an exception this guard invents), and it is filed as its own
  // follow-up rather than papered over here.
  if (declineUnpairedUndefLiterals(M))
    return PreservedAnalyses::none();
  // bd test_C_libtooling-6uqc (M-A Increment 1) — the LIVE-RECORD guard, at the
  // SAME late slot and for the SAME reason as the literal-integrity guard above:
  // this is the only position where "is rail R still undischarged when this
  // chained `cqrt_ry` fires, and does any USER read it afterwards" are FACTS
  // about the emitted stream rather than PREDICTIONS about what Phase 4's flag
  // strip and Phase 5's free placement are going to do (owner ruling 2026-08-27,
  // point 2 — the early `declineStaleRecordOps` slot was rejected on three
  // measured failure modes, including that it would decline a currently-green
  // `cq_theta; if(c) cq_phi; cq_theta` merge-phi-lift program).
  //
  // It keys on EMITTER-RECORDED gate sets (`taint.UserChainedRotations` /
  // `UserSourceRotations` / `UserPhaseRotations` / `SpineOps`), never on a
  // textual shape test: in lowered IR a user's chained theta and the spine's
  // adjoint `cqrt_ry(h, -θ)` are the same call, and the Inc-0 census measured its
  // angle-pairing guess wrong in BOTH directions (SPIKE §1.4 A8). A raw
  // hand-written `cqrt_ry` in an already-lowered lit fixture is in NEITHER set
  // and is therefore not a site — which is what makes the two census artefacts
  // invisible here by construction.
  //
  // ORDER WITHIN THE SLOT: after `declineUnpairedUndefLiterals`, which returns
  // early on its own decline. Every EARLIER-stage owner (`declineStaleRecordOps`,
  // `ArmClassify`, `declineFrozenWire`, …) already exited `opt` at its own
  // `DS_Error` long before here, so this guard re-owns no shipped message
  // (census 0.4's 9 at-risk fixtures all decline at or before run-line 404).
  if (declineLiveRecordRotations(M, taint))
    return PreservedAnalyses::none();
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

  // bd etiq — volatile-const LOCAL fold, mirrored in this entry point too
  // (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the
  // post-global-fold / pre-PredMux placement rationale.
  foldVolatileConstAllocaLoads(M, taint);

  // bd k710 — DEAD volatile SCALAR STORE elimination (QramLowering.cpp): the
  // WRITE-ONLY sibling of the two folds above, for openlibm's underflow idiom
  // (`volatile float u = x*x; /* underflow */`, ld80/s_nexttowardf.c:63, `u`
  // never read). Zero loads means neither fold above nor zco4's promotion can
  // claim it, so the volatile store survives to `declineTaintEscapes` and the
  // cell dies on kMsgStore. Grounded in the fenv ruling (owner 2026-08-10): CQ
  // models no FP exception flags and a volatile access to a non-escaping local
  // is not observable. Erases the stores/markers/alloca; the stored VALUE is then
  // trivially dead and, inside a PredMux region, is removed by the pre-existing
  // cleanup at PredMuxFlatten.cpp:2618 — so the emitted circuit generally loses
  // the multiply too, which IS what the ruling licenses (measured: zero
  // `fmul_f32` in slice_libm_ld80_nexttowardf). Outside a region it is instead
  // lowered, uncomputed and freed. See QramLowering.h for the asymmetry.
  eraseDeadVolatileScalarStores(M, taint);

  // bd zco4 — volatile scalar-local SSA promotion, mirrored in this entry point
  // too (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the
  // same-slot-as-etiq placement + fixpoint-re-propagate rationale.
  while (promoteVolatileScalarLocals(M, taint)) {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.MeasureCalls);
  }

  // bd 3c6m.51 — x86_fp80 union-promotion peephole, mirrored in this entry point
  // too (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the
  // post-volatile-fold / pre-PredMux placement + fixpoint-re-propagate rationale.
  while (promoteFp80Union(M, taint)) {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.MeasureCalls);
  }

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

  // bd 3c6m.55 Inc 2 (Lever B) — static-K force-unroll fixpoint, mirrored in
  // this entry point too (twin-pipeline parity is MANDATORY, WI-1.12) — see
  // run() for the post-fixpoints / pre-`detectSpecializations` placement
  // rationale and the nested PredMux re-run.
  while (unrollConstTripLoops(M, taint)) {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.MeasureCalls);
    while (flattenPredMuxRegions(M, taint)) {
      taint = propagate(M, wd);
      onlyInF(taint.ThetaCalls);
      onlyInF(taint.PhiCalls);
      onlyInF(taint.MeasureCalls);
    }
  }

  // bd ww4c Inc 1 — the shift-count -> ctlz idiom fixpoint, mirrored in this
  // entry point too (twin-pipeline parity is MANDATORY, WI-1.12) — see run()
  // for the post-fixpoints / pre-`detectSpecializations` placement rationale,
  // the nested PredMux re-run, and why this pre-pass (unlike the unroll one)
  // competes with Q1 for the same loops.
  while (recognizeCtlzIdiomLoops(M, taint)) {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.MeasureCalls);
    while (flattenPredMuxRegions(M, taint)) {
      taint = propagate(M, wd);
      onlyInF(taint.ThetaCalls);
      onlyInF(taint.PhiCalls);
      onlyInF(taint.MeasureCalls);
    }
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
  // bd test_C_libtooling-x67f (M-C Increment 7a) — mirrored from `run()`
  // (twin-pipeline parity, WI-1.12): miss it and a unit-level caller diverges.
  // See run() for the full rationale and for why this slot is the only one.
  lowerLateReassignments(M, wd, taint);
  // Phase 5 (PRD §2.8): uncomputation runs LAST in this entry point too — miss
  // one and unit-level callers diverge from `run()`.
  uncompute(M, wd, taint);
  // bd xy9n — mirrored from `run()` (twin-pipeline parity, WI-1.12): miss it and
  // a unit-level caller silently keeps the pairing break. See run() for why this
  // position is the complete one, and for why the bool is consumed.
  if (declineUnpairedUndefLiterals(M))
    return true;
  // bd test_C_libtooling-6uqc (M-A Inc 1) — mirrored from `run()` (twin-pipeline
  // parity, WI-1.12): miss it and a unit-level caller silently keeps the
  // live-record accept. See run() for the late-slot + emitter-keyed rationale.
  if (declineLiveRecordRotations(M, taint))
    return true;
  eraseDeadDecls(M, wd);
  return true;
}

}  // namespace cq
