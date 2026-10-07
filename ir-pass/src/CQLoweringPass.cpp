// CQLoweringPass.cpp — thin orchestrator for the cq-lowering pass.
//
// Per-step bodies live in width-resolver / taint / rotation / opcode /
// measure modules. Width parameterization handles `_Bool` / `i8` /
// `i16` / `i64` / `f32` / `f64`.

#include "CQLoweringPass.h"
#include "SpeculationSafety.h"

#include "ArithLowering.h"
#include "ArmAnalysis.h"      // reverifyRailCondReads (bd r9e5 1b-B.1 round 2)
#include "ByRefInline.h"
#include "CondLiteral.h"      // declineQuantumCondLiterals (bd xdu2.13 round 2)
#include "SelectMergeEmit.h"  // declineQuantumCopySources (bd r2j3.14)
#include "ControlPlan.h"
#include "CtlzIdiomPrepass.h"
#include "Fp80Union.h"
#include "IOSinkLowering.h"
#include "LiteralIntegrity.h"
#include "LoopPlan.h"
#include "LoopUnrollPrepass.h"
#include "MeasureLowering.h"
#include "MergePhiPeel.h"
#include "OpcodeLowering.h"
#include "PredMuxFlatten.h"
#include "QramLowering.h"
#include "QramIndexWidth.h"     // bracketQramIndexCasts / stripForeignQramIndexTags (libcqops b6a)
#include "RailBankPromote.h"
#include "ReturnMerge.h"        // unifyTaintedReturns (bd dm7f.5)
#include "RotationLowering.h"
#include "LibmBinding.h"
#include "SpecializeDetect.h"
#include "SpecializePlan.h"
#include "StageList.h"           // runLoopPrepasses / runControlChain (bd p3kd.7.8)
#include "Specialization.h"
#include "SwapRouteEmit.h"
#include "TaintPropagation.h"
#include "Uncomputation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/DiagnosticInfo.h"
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

// THE POSTCONDITION, ASSERTED — bd 3qlq Inc 1 part A, Rule-13 round-1 finding
// F-L6-1 (a CONFIRMED Rule-1 "no third path" violation).
//
// `eraseDeadDecls` above states the architecture's promise — "no
// `@cq_theta_<sfx>` / `@cq_phi_<sfx>` / `@cq_measure_<sfx>` remains in the IR
// after this pass" — and then only ERASES the declarations that happen to be
// unused. It cannot see a SURVIVING CALL, and a surviving call is exactly what
// F-L6-1 found: on a stale header the flagship `if (q == 5) q = cq_phi(q, PI)`
// had its arg 0 const-folded to a classical `i32 5`, so the taint-escape guard
// could not fire; `ArmClassify` still CLAIMED the call by the `cq_phi_` prefix
// and the deleted `PhiCalls` lowering loop never consumed it. `opt` exited 0,
// verify-clean, STRICT stage 2b clean, with the phase gate dropped and
// `@cq_phi_si32` standing in the emitted module. The only thing that noticed was
// `ld`.
//
// The `resolveSources` clause (`TaintPropagation.cpp`) closes that specific
// door. THIS is the backstop that makes the postcondition a CHECKED property
// rather than a comment: whatever else changes upstream, a front-end intrinsic
// CALL that reaches the end of the pipeline is a decline, not an exit-0 module.
// It fires after every lowering stage and before `eraseDeadDecls`, so a stage
// that forgets to consume its own construct is caught by the pass rather than by
// the linker.
//
// LOUD, NOT AN `assert` (Rule 1): a Release build has assertions off, which is
// the build every gate in this tree runs.
bool declineSurvivingIntrinsicCalls(Module &M, WidthDispatch &wd) {
  bool Declined = false;
  for (StringRef Name : wd.frontEndIntrinsicNames()) {
    Function *FE = M.getFunction(Name);
    if (!FE)
      continue;
    for (User *U : FE->users()) {
      auto *CB = dyn_cast<CallBase>(U);
      if (!CB || CB->getCalledFunction() != FE)
        continue;
      Function *At = CB->getFunction();
      At->getContext().diagnose(DiagnosticInfoUnsupported(
          *At,
          ("cq lowering: front-end intrinsic " + Name +
           " survived lowering; the pass lowered nothing for it")
              .str(),
          CB->getDebugLoc()));
      Declined = true;
      break;  // one message per symbol is enough to fail the pass.
    }
  }
  return Declined;
}

}  // namespace

PreservedAnalyses CQLoweringPass::run(Module &M, ModuleAnalysisManager &) {
  WidthDispatch wd(M);
  TaintSet taint = propagate(M, wd);

  // No quantum work anywhere in the module: leave the IR byte-identical
  // and (crucially) emit no runtime/template decls. The
  // passthrough_no_quantum LIT fixture pins this path. `PhaseCalls` is in the
  // predicate so a module whose ONLY quantum surface is an uncontrolled
  // `void @cq_phi(double)` still runs (and DELETES it, D2) — else the
  // unresolved `@cq_phi` extern is a Stage-3 link error. (`PhiCalls` is
  // permanently empty since 3qlq Inc 1 and is kept in the predicate as the
  // vacuous term it now is; see TaintPropagation.h.)
  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty() &&
      taint.PhaseCalls.empty() && taint.MeasureCalls.empty())
    return eraseUnusedLibmBodies(M, /*KeepBindable=*/false) ? PreservedAnalyses::none()
                                    : PreservedAnalyses::all();

  // bd `test_C_libtooling-3c6m.72` — a quantum math.h call reaches the body
  // `tools/cqc` injected (`__cq_libm_<name>`); a classical one keeps the system
  // libm. FIRST, so every pre-pass below sees an ordinary call to a visible
  // callee. Re-asked before `detectSpecializations` (L1). See LibmBinding.h.
  bindLibmCalls(M, taint, wd);
  eraseUnusedLibmBodies(M, /*KeepBindable=*/true);

  // bd `test_C_libtooling-dm7f.5` — MULTI-EXIT `ret` NORMALIZATION, SLOT (a) of
  // two (`ReturnMerge.h`). A function whose tainted-condition `br`/`switch`
  // reaches two or more `ret`s (a `musttail` arm keeps its own `ret` at -O1;
  // hand IR) has the `ret`s that branch reaches merged into one block,
  // `musttail` demoted to `tail` where that is sound and refused loudly where it
  // is not — the plain-return twin's CFG when no classical exit stays outside
  // the merge (`ReturnMerge.h` states the exact contract). FIRST, before every
  // stage that reads the CFG (PredMux, the I/O-sink / guarded-store / loop
  // pre-peels, the specialization detector and the escape guards), so each of
  // them sees the merged IR. No guard has run yet, so a plain re-`propagate` is
  // the whole taint obligation (the dead-argument drop's argument below). Slot
  // (b) is beside every `peelIndependentMergePhis` call, for branches tainted
  // only later.
  if (unifyTaintedReturns(M, taint, /*Delta=*/nullptr))
    taint = propagate(M, wd);

  // bd `test_C_libtooling-vsfp` (P1) / bd `hgwx` — THE DEAD CALL-ARGUMENT DROP
  // (`SpecializeDetect.h`), SLOT A of two. An integer/fp argument whose callee
  // parameter is DEAD under the pass's ONE liveness predicate
  // (`DeadValueLiveness.h` — mark-from-roots, not `use_empty()`) becomes a null
  // constant, and the operand's dead cone is deleted by the same predicate. That
  // is LLVM's dead-argument elimination, with DAE's own preconditions mirrored
  // (exact definition, not `naked`, not variadic, …; a `musttail` site IS rewritten
  // since bd ev3m — only an operand changes, no signature), applied across the TU
  // boundary `clang -O1` cannot see. Without it a Phase-6 clone that never reads
  // a slot was still PASSED the operand, and that phantom read kept a which-path
  // rail (a 4.4 bool-select `%out`, a 6.5 `%out`, a template rail) alive and
  // entangled across a later non-diagonal gate on the register it copies — a
  // dephased circuit at exit 0, stage 2b clean.
  //
  // ⚠ THE SLOT IS THE ARGUMENT. The operand has to be gone before any stage
  // READS it: before `detectSpecializations` computes a mask over it, before
  // round-1 control emission mints a merge rail for it, and before round 2's
  // re-detection (bd 9paa) makes a `g(%out)` site out of it — after emission a
  // dropped operand would leave its rail minted, orphaned and entangled. Slot A
  // is FIRST so the by-ref inliner, the rail bank and the bitcast/volatile folds
  // see IR with the dead cone already gone. SLOT B (after the fenv volatile
  // stages, below) asks again, because the volatile STORE erasure is what makes
  // `h(a,k){ volatile char z = a; … }`'s parameter dead (bd a8q5) — slot A cannot
  // see that, the store being a root until it is erased.
  //
  // ⚠ WHAT "THE TWIN'S IR" MEANS HERE, PRECISELY (L7 — round 1 said the
  // pre-passes "see the TWIN's IR" and r1A F-VA-2/3/4 measured three ways it was
  // false). After both slots, every argument whose callee parameter the liveness
  // predicate proves dead is a constant and its dead cone is gone — dead LLVM
  // intrinsics, dead side-effect-free calls and dead φ cycles included — and an
  // arm the deletion emptied is folded into its merge (the SimplifyCFG shape
  // `-O1` gives the twin). What is NOT the twin's: a dead BRANCH `-O1` would
  // have removed is kept when its arm is not empty or its merge has a φ (the
  // predicate has no control dependence; conservative — the parameter it reads
  // stays live), and CFG simplification beyond that one fold is not run.
  //
  // It needs taint only for the intrinsic-site membership (roots; the call-site
  // skip). The full re-`propagate` after it is exactly the restart every fixpoint
  // below performs, and it is what the drop OWES: ⚠ the round-2 sentence here —
  // "it SHRINKS the taint set and grows nothing" — was false (bd vsfp Rule-13 r2A
  // F-WA-2): `deleteDeadCones`' two-entry-φ fold can mint a TAINTED `select`
  // (a φ of classical incomings under a quantum condition). The conclusion
  // survives on the right ground: the drop re-`propagate`s whenever it changed
  // anything and no guard has run yet, so a plain `propagate` is the whole
  // obligation (no `adjudicateTaintDelta`). The observing half is
  // `resolvePhantomCloneArgReads` after `specialize()`, asked with the SAME
  // predicate's record of the built clones.
  if (dropDeadCallArguments(M, taint))
    taint = propagate(M, wd);

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

  // bd `xdu2` / L-1a clause C5 — THE RAIL-BANK PER-ACTIVATION PROMOTER
  // (RailBankPromote.cpp): a bounded `bool b[N]` / `int b[N]` whose cells hold
  // one fresh rail per trip is forwarded to SSA WITHIN ONE ACTIVATION — the seed
  // load becomes the proven initializer constant, every intra-activation load
  // becomes the dominating store's value (an SSA merge phi where the store is
  // conditional), and EXACTLY ONE store per activation survives, at the
  // activation's end. That is the shape `clang -O1` emits for the equivalent
  // scalar source (`trackL/probes/L1_promoted_store.c`), so everything after it
  // is SSA and the existing control chain applies unchanged.
  //
  // The rest of L-1a now ships downstream of this call: the taint rule (a load
  // from a `!cq.railbank` alloca is tainted), the fixed `[N x i1]` -> `[N x i32]`
  // type rewrite and the D5 allow-list — so a promoted bank LOWERS. bd xdu2.4
  // adds the runtime `alloca i32, %n` bank (already handle-typed), a real |0>
  // seed for its conditional in-arm preparation, and the emptied-arm `select`
  // fold (PASS H). Off-pattern banks are left untouched and still decline at
  // their existing owner. See RailBankPromote.h.
  //
  // ⚠ The seed marker is compiler-owned: `declineForeignRailBankSeeds` below
  // refuses an input that already carries it, BEFORE the promoter can mint one.
  //
  // ⚠ THE SLOT IS THE L1 ARGUMENT, AND IT IS WHY THIS IS *FIRST*. This stage
  // GROWS THE TAINT SET — a bank `load` is untainted today (taint is SSA-only;
  // `propagateWorklist` has no load/store rule), and forwarding the STORED VALUE
  // to it makes every downstream user quantum. That is `MergePhiPeel`'s F-B6-1
  // species verbatim (five plain-C escapes of a rail HANDLE at `opt` exit 0),
  // and the cure there was `adjudicateTaintDelta`. Here the cure is ORDER: the
  // loop below re-runs `propagate` FROM SCRATCH after every change, which is
  // strictly stronger than a delta, and EVERY stage that adjudicates consumers
  // of tainted values runs after it —
  //   `foldIdentityBitcasts` (:169, the SOLE handler for a same-width int<->int
  //   bitcast, and `adjudicateTaintDelta`'s CALL 1 for exactly that reason),
  //   `foldVolatileConstGlobalLoads`, `foldVolatileConstAllocaLoads`,
  //   `eraseDeadVolatileScalarStores`, `promoteVolatileScalarLocals`,
  //   `promoteFp80Union`, `flattenPredMuxRegions`, `unrollConstTripLoops`,
  //   `recognizeCtlzIdiomLoops`, `detectSpecializations`, `declineTaintEscapes`,
  //   `declineStaleRecordOps`, `recordStaleQuantumReaders`, the peel and both
  //   detection rounds.
  // Nothing above it computes anything a later stage consumes: `lowerByRefInline`
  // is itself a re-propagating fixpoint. RETIREMENT TRIGGER: move this call below
  // ANY of the stages named above — or add a taint-consuming stage above it — and
  // it owes `adjudicateTaintDelta` exactly as the peel does, with NO DIAGNOSTIC
  // ANYWHERE if the obligation is missed.
  //
  // ACCEPT-ONLY: an off-pattern bank is left byte-untouched for its existing loud
  // owner. ONE bank per call + a full re-propagate (the `flattenPredMuxRegions` /
  // `promoteVolatileScalarLocals` precedent) so each claim sees fresh taint and
  // fresh dominance and no cached block identity crosses an erasure (Rule 9).
  // libcqops b6a — the QRAM index tag is compiler-owned: drop any the input
  // carries before an emitter can mint one (round-3 review H1). Dropping, not
  // declining: the tag means nothing to the program, so the IR is unchanged.
  stripForeignQramIndexTags(M);
  if (declineForeignRailBankSeeds(M))
    return PreservedAnalyses::none();
  while (promoteRailBankCells(M, wd, taint))
    taint = propagate(M, wd);

  // Debug lever (bd `xdu2`; env-gated, no behaviour change): dump the module
  // after the promotion fixpoint settles — the CQ_FP80_DBG / CQ_SPEC_DBG
  // precedent. It exists because a promoted module that later DECLINES writes 0
  // bytes to stdout (`DS_Error`), so for that population the promotion is not
  // observable on the lowered IR and an IR-text CHECK there would be vacuous
  // (Rule 12 hygiene defect (b)). Accepted banks are observable directly.
  if (::getenv("CQ_RAILBANK_DBG")) {
    llvm::errs()
        << "=== CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===\n";
    M.print(llvm::errs(), nullptr);
  }
  // ── bd `xdu2` / L-1a W1 PIECE 1's PRECONDITION — MINT THE `!cq.railbank`
  //    RECORD, then re-`propagate` so the bank's LOADS become tainted.
  //
  // The mint is the ONE proof the whole second half is keyed on (the taint rule,
  // the type rewrite, the D5 allow-list and the accept at `declineTaintEscapes`
  // all ask `isRailBankAlloca`), and it is minted for a `RailBankCarve::Bank`
  // bank and nothing else — `BankRaw` is the promoter's INPUT and must keep
  // declining forever (`trackA/SIGNATURE.md` §3).
  //
  // ⚠ THE SLOT IS THE WHOLE L1 ARGUMENT, exactly as it is for the promoter
  // immediately above. This stage GROWS THE TAINT SET — it is what makes a
  // memory-resident rail name quantum — and it is sound only because it runs
  // ABOVE every stage that adjudicates consumers of tainted values
  // (`foldIdentityBitcasts`, `flattenPredMuxRegions`, `unrollConstTripLoops`,
  // `recognizeCtlzIdiomLoops`, `detectSpecializations`, `declineTaintEscapes`,
  // `declineStaleRecordOps`, `recordStaleQuantumReaders`, the peel and both
  // detection rounds), and because the growth is published by a FULL
  // `propagate` rather than by a delta. RETIREMENT TRIGGER: move this call below
  // any of those — or add a taint-consuming stage above it — and it owes
  // `adjudicateTaintDelta` exactly as `MergePhiPeel` does, with NO DIAGNOSTIC
  // ANYWHERE if the obligation is missed.
  //
  // ⚠ AND IT IS *AFTER* THE PROMOTER'S FIXPOINT, NOT INSIDE IT. Clause B8 is
  // what terminates that fixpoint (`applyBank` replaces every in-`L` load, so
  // the next turn finds none); a membership record consulted by the promoter
  // would MASK a B8 regression rather than back it up, which is precisely why
  // the retired clause B9 was retired (merge filing F-9). The mint arrives after
  // the promoter has already stopped, so the promoter never sees it.
  //
  // ⚠ AND IT IS BELOW THE `CQ_RAILBANK_DBG` MODULE DUMP, DELIBERATELY. That
  // dump is the PROMOTER'S OUTPUT, and seven shipped `railbank_promote_*`
  // fixtures pin `NOMD-NOT: !cq.railbank` on it — the check that keeps the
  // RETIRED clause B9 retired (*the promoter mints nothing*, merge filing F-9).
  // Minting above the dump would make all seven vacuously unable to see a
  // promoter that started minting again. The mint is a SEPARATE stage and the
  // dump must keep showing the module without it.
  //
  // ⚠ ONE-SHOT BY CONSTRUCTION, NOT BY LUCK: `markRailBankAllocas` skips an
  // alloca that already carries the record, so a second call returns false. It
  // is written as an `if` rather than a `while` for that reason — a `while` here
  // would read as a fixpoint whose termination depends on that skip.
  if (markRailBankAllocas(M, taint)) {
    taint = propagate(M, wd);
  }

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
  //
  // ⚠ IT IS ALSO CALL 1 OF `adjudicateTaintDelta` (bd b6ap F-B6R2-1): this run
  // sees only the taint that has settled BY HERE, and it is the SOLE handler for
  // the opcode, so a bitcast a LATER stage makes tainted would be left standing
  // and die at `no template for opcode 'bitcast i32'`. `Scrub=nullptr` here
  // because this slot holds no taint DELTA to keep consistent — it runs over the
  // whole settled set, and the only `Value *` table a fold could stale is `taint`
  // itself, which the fold scrubs.
  foldIdentityBitcasts(M, taint, /*Scrub=*/nullptr);

  // bd 3c6m.14 Inc 3 — volatile-const global-load fold (QramLowering.cpp): the
  // openlibm anti-const-fold idiom (`static volatile double twom1000`,
  // `*(volatile double *)&atanlo[3]`) folds to the initializer constant when
  // the global is internal, definitively initialized, never stored, and never
  // address-escaped. Runs HERE — after the passthrough early-out (a cq-free
  // module stays byte-identical) and BEFORE the PredMux fixpoint, whose E4
  // admits no volatile access (unfolded, these block the tainted arm). Folded
  // loads are classical. ⚠ But since bd vsfp round 3 (bd stl3) the stage also
  // folds an arm it EMPTIES (`deleteDeadCones`), which can turn a two-entry φ
  // under a quantum condition into a NEW tainted `select` — so it re-propagates
  // when it changed anything, like every other pre-pass in this window (bd otam;
  // the old "no re-propagate needed" was the bug, see QramLowering.h).
  if (foldVolatileConstGlobalLoads(M, taint))
    taint = propagate(M, wd);

  // bd etiq — volatile-const LOCAL fold (QramLowering.cpp): the alloca sibling
  // of the global fold, for the openlibm rounding idiom kept in a LOCAL
  // (`volatile double vd2 = 0x1.0p32;` in s_cbrtl.c — mem2reg never promotes a
  // volatile access, so the store/load pair survives -O1 and would block the
  // tainted arm at PredMux E4). Single-Constant-store + dominated exact-type
  // loads only; the fold erases the loads, store, lifetime markers, and
  // alloca. Folded values are classical, but the arm fold behind it is not taint-
  // neutral (bd otam, r2A `stale4`: a `(void)k` arm emptied under a quantum
  // condition became a tainted `select` nobody re-propagated, and a user
  // `cq_measure` vanished) — so: re-propagate when it changed anything.
  if (foldVolatileConstAllocaLoads(M, taint))
    taint = propagate(M, wd);

  // bd k710 — DEAD volatile SCALAR STORE elimination (QramLowering.cpp): the
  // WRITE-ONLY sibling of the two folds above, for openlibm's underflow idiom
  // (`volatile float u = x*x; /* underflow */`, ld80/s_nexttowardf.c:63, `u`
  // never read). Zero loads means neither fold above nor zco4's promotion can
  // claim it, so the volatile store survives to `declineTaintEscapes` and the
  // cell dies on kMsgStore. Grounded in the fenv ruling (owner 2026-08-10): CQ
  // models no FP exception flags and a volatile access to a non-escaping local
  // is not observable. Erases the stores/markers/alloca AND the stored value's
  // dead cone (bd qjoc / bd vsfp round 2, the pass's ONE liveness predicate) —
  // the computation disappears, which IS what the ruling licenses (measured: zero
  // `fmul_f32` in slice_libm_ld80_nexttowardf). ⚠ The sentence that stood here —
  // "outside a region it is instead lowered, uncomputed and freed" — was false
  // for a dead 4.4 select (a silent which-path rail) and a dead template product
  // whose source is later rotated (a dirty rail); see QramLowering.h. The same
  // cone deletion can fold an emptied arm into a tainted `select` (bd otam, r2A
  // `stale3a/b/c`, `loop2`), so: re-propagate when it changed anything.
  if (eraseDeadVolatileScalarStores(M, taint))
    taint = propagate(M, wd);

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

  // bd `test_C_libtooling-vsfp` round 2 — THE DEAD CALL-ARGUMENT DROP, SLOT B.
  // The two fenv stages just above are what make a parameter dead in callees
  // like `h(a,k){ volatile char z = a; return k+1; }` (the store erasure, with
  // its dead cone) and `volatile char z = a; char w = z; … (w - w)` (the
  // promotion, with its residue) — bd a8q5, r1B F-VB-1. Slot A ran before them
  // and saw the volatile store as a root. Asked here, still before
  // `promoteFp80Union`, PredMux, `detectSpecializations` and every emission, so
  // the premise of slot A (no stage has read the argument yet) holds verbatim.
  // What ran between the slots and could have READ a now-dead operand: the
  // by-ref inliner, the rail-bank promoter and mint, the bitcast and volatile
  // folds. None records an SSA value this drop then deletes (the rail-bank
  // record is metadata on an ALLOCA, never on a load), and each is an
  // accept-only normaliser. Idempotent with slot A: every argument slot A
  // dropped is a constant, and constants are never revisited.
  if (dropDeadCallArguments(M, taint))
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
  // existing loud declines; regions with cq_* calls / stores / loads are never
  // claimed, so every shipped accept shape reaches its owner byte-identically.
  // ⚠ "/ loops" WAS IN THAT LIST AND IS NOW FALSE (bd fn1q increment 3): E2
  // admits a region lying STRICTLY INSIDE one loop body. The conclusion is
  // unchanged — corpus A/B over all ir-pass fixtures, 0 A->D and 0 stream moves
  // — and the reason it is unchanged is the **claim witness**: measured, 100 of
  // the accepting `*loop*` fixtures leave PredMux at `W-witness`, which claims
  // only shapes today's detection declines. ⚠ Round 1's correction of this
  // sentence said the reason was E4; round 2 measured 0 leaves at E4 and that
  // claim is withdrawn. See the W7 block in `PredMuxFlatten.cpp` for the
  // counterfactual fences and the retirement trigger. One region per iteration + a full re-propagate (the
  // lowerByRefInline fixpoint precedent) so each claim sees fresh
  // dominance/taint state and sequential siblings compose without any cached
  // block identity crossing an erasure (Rule 9).
  //
  // bd `test_C_libtooling-woa0` — `railPhiRec` is the CROSS-CLAIM record, and it
  // is declared out here rather than inside the loop for the only reason that
  // matters: the property it polices is violated BETWEEN claims, so a record
  // scoped to one call would be structurally incapable of seeing it. It is
  // threaded through all THREE fixpoints below (this one, the unroll pre-pass's
  // and the ctlz pre-pass's) and re-asked once, after the last of them. See
  // `PredMuxFlatten.h`.
  PredMuxRailPhiRecord railPhiRec;
  while (flattenPredMuxRegions(M, taint, /*claimAll=*/false, &railPhiRec))
    taint = propagate(M, wd);

  // The static-K unroll and ctlz-idiom pre-passes (StageList.cpp: placement
  // rationale, the nested PredMux re-run, and why the ctlz pass competes with
  // Q1). One stage list for main and lifted clones (bd p3kd.7.8).
  auto Reprop = [&] { taint = propagate(M, wd); };
  runLoopPrepasses(M, taint, railPhiRec, StageScope{Reprop});
  // bd `test_C_libtooling-woa0` — THE RE-ASK, and its slot is the argument.
  //
  // CLAUDE.md L1's standing cure names "after the fixpoint, in BOTH entry
  // points, declining loudly". HERE is after ALL THREE top-level PredMux
  // fixpoints (:374, the unroll pre-pass's, and the ctlz pre-pass's) and BEFORE
  // the first stage that could consume — or accidentally decline — what a later
  // claim converted. That ORDER is what makes the diagnostic name the real cause
  // instead of inheriting a downstream owner: before this fence the composition
  // landed on `SelectClassify`'s data-select grammar refusing a `select i1`
  // condition — Rule-13 round 2's "a downstream accident, not a fence". (⚠ this
  // sentence said "`collectCondTree`'s refusal of an `xor`-of-`select`" and round
  // B measured that there is no `xor` in the post-flatten module — `F-RB-3`.)
  // `LLVMContext::diagnose`
  // EXITS on the first `DS_Error` (bd `br4a`), so being early is precisely what
  // buys the ownership.
  //
  // ⚠ IT DOES NOT COVER `Specialization.cpp`'s `claimAll=true` fixpoint, which
  // runs inside `specialize()` — i.e. AFTER `detectControlRegions` and
  // `repropagateControlMerges`, so no slot here can. That driver carries its own
  // record and its own re-ask; see `lowerCloneControl`.
  if (declineConvertedRailPhiLeaves(railPhiRec))
    return PreservedAnalyses::none();
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
  // bd `test_C_libtooling-otam` (bd vsfp round 3) — THE PRE-PASS WINDOW'S
  // TAINT-FRESHNESS POSTCONDITION. Every stage above that changes the IR
  // re-propagates itself; this re-derives the set once more and declines LOUDLY
  // if it differs, so the NEXT stage that grows taint and forgets (the three
  // volatile folds did, round 2) is a decline, not a silent miscompile. See
  // TaintPropagation.h for what it can and cannot see.
  if (declineStaleTaintSet(M, wd, taint))
    return PreservedAnalyses::none();
  // bd 3c6m.72 — re-ask the early `bindLibmCalls` after the pre-passes above,
  // which can taint a math.h call the first round saw as classical. AFTER the
  // stale-taint postcondition, so its own re-propagation hides nothing. NOT an
  // L1 round-2 re-ask: taint grown later (`adjudicateTaintDelta`,
  // `repropagateControlMerges`) binds nothing, and the call then fails loudly
  // as an unknown callee (an over-decline, bd 3c6m.75).
  bindLibmCalls(M, taint, wd);
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

  // (bd test_C_libtooling-3d8q, P1) THE STALE-READER ANALYSIS — pure analysis,
  // no diagnostic, paired with `declineRecordedStaleQuantumReaders` far below.
  // It asks the linear rule (`docs/frontend.md` §3.2) of the reader families the
  // sweep above does not cover: a `@cq_theta_<sfx>` (arg-0) or `@cq_measure_<sfx>`
  // call reading a name the wire has already moved past. Until this, a rotation
  // or a measurement reading a stale name was asked NOTHING while an `add` on
  // the same name declined — a CONFIRMED verify-clean silent miscompile, exit 0
  // and stage-2b clean, emitting a stream byte-identical to a DIFFERENT
  // well-formed program.
  //
  // ⚠ IT MUST RUN HERE, BEFORE `lowerLoops` / the peel / control detection, and
  // that is the over-decline half of the argument: its premise is that an SSA
  // name denotes a basis RECORD, which is true only of the names the USER wrote.
  // The rail-φ collapse, the peel and the one-register lift each REWRITE a
  // wire-TRACKING name into a wire-BASE name, and the fence asked after any of
  // them declines well-formed programs for a fact about the rewrite (measured: 9
  // shipped in-loop ACCEPT fixtures). The diagnostic half is deferred to the late
  // slot for the opposite reason — see `TaintSet::StaleQuantumReaders`.
  recordStaleQuantumReaders(M, taint);

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

  // `lowerLoops` through the round-2 re-asks (StageList.cpp holds the stage
  // comments: bounded loops, the merge-phi peel, control detection and
  // emission, loop round 2, the round-2 propagation and its L1 re-asks).
  std::unique_ptr<ControlPlan> plan =
      runControlChain(M, wd, taint, plan6, StageScope{Reprop});

  // bd test_C_libtooling-3qlq Inc 1 (PRD §6.2 row P7, owner decision D2) —
  // DELETE every SURVIVING register-free `cq_phi`: an uncontrolled or
  // classically-controlled branch phase is a GLOBAL phase, unobservable, and
  // deleting it is a documented semantic rather than a diagnostic.
  //
  // POSITION IS THE WHOLE SOUNDNESS ARGUMENT, AND IT IS **AFTER**
  // `repropagateControlMerges`, NOT immediately after `lowerControlRegions`.
  // The premise is "every tainted `br`/`switch` has been CLAIMED or DECLINED
  // loudly — Rule 1's no-third-path — so a survivor sits under CLASSICAL control
  // only". At the OLD position that premise was FALSE, and the Rule-13 round-1
  // lens L3 measured the consequence as a CONFIRMED SILENT MISCOMPILE (F-L3-1):
  //
  //   `repropagateControlMerges` (the dugh/yn71 round) is not a taint touch-up —
  //   its `detectAndLowerOnwardControl` is a SECOND, FULL round of
  //   `detectControlRegions` + `lowerControlRegions`. A `cq_phi` under an ONWARD
  //   tainted branch — one whose condition reads a 6.5 classical-call-arm or 4.5
  //   switch-data-mux `%out` rail, and is therefore CLASSICAL at round 1 — was
  //   deleted as a "global phase" BEFORE its region had ever been looked at.
  //   `int y=5; if (q>5) y=ext_f(7); if (y>50) cq_phi(0.9); else cq_phi(0.3);`
  //   then compiled at exit 0 with the phase gone AND — its only consumer having
  //   been deleted — with the ANGLE `select` re-classified at round 2 as plain
  //   fp DATA and lowered through the 4.4/kjd1 `cqrt_copy_f64_controlled` merge:
  //   a rotation angle materialised on a quantum f64 rail, the Rule-3
  //   wire-crossing `CLAUDE.md` names outright. A second reproducer (a phase
  //   BESIDE a value op in an onward arm) became an over-accept of a shape the
  //   pre-3qlq oracle declines `mixed phase/value arm under quantum control`.
  //
  // NEITHER of the two fences could see it, and both failures are STRUCTURAL
  // rather than accidental: (i) at the old position the onward branch's condition
  // is not yet in `taint.Tainted`, so the Rule-1 assert's
  // `reachedThroughTaintedBranch` walk had nothing to find; and (ii) the ROUND-1
  // tainted `br` that the same walk would otherwise have found on the predecessor
  // path had ALREADY BEEN ERASED by its own region's flatten.
  //
  // AT THIS POSITION the premise is true rather than aspirational: round 2 has
  // run to a fixpoint, so its `detectControlRegions` — including the new
  // `classifyPhaseKickback` pre-peel — has claimed or declined every onward
  // tainted `br` too, and `reachedThroughTaintedBranch` is asked with ROUND-2
  // taint on the ROUND-2 CFG, which is its correct position. A survivor
  // reachable through a tainted branch condition declines `unclaimed branch
  // phase under quantum control` instead of vanishing (PRD §10.3 lens 4), and a
  // survivor with a TAINTED ANGLE declines with the retired family's own
  // `quantum-derived rotation angle` string.
  //
  // WHAT IS DOWNSTREAM OF THE NEW SLOT AND WAS RE-CHECKED (the 8h7d.5 F-1/F-3
  // discipline — a stage that MOVES must be re-asked against every stage it
  // crossed):
  //   * `repropagateControlMerges` itself re-runs `declineTaintEscapes`, which
  //     already CARVES OUT `taint.PhaseCalls` (`TaintPropagation.cpp`), so a
  //     surviving `cq_phi` crossing that stage adds no new escape decline —
  //     MEASURED, no fixture changes disposition.
  //   * `detectSpecializations` runs at BOTH rounds and reads
  //     `taint.PhaseCalls` since F-L3-3 below, so a survivor inside a
  //     specialization candidate declines as a `quantum primitive (cq_*)` at
  //     round 2 as well as at round 1.
  //   * `collapseFlattenedLoopRails` (round-2 rail collapse) sees the same
  //     survivors it saw before; it keys on `taint.InLoopFlattenedPreds` and on
  //     rotation/`addc` rail gates, and a register-free phase call is neither.
  deleteGlobalPhases(M, wd, taint);

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
  // merge phi (`if (classical_c) cq_theta(&q, θ); use(q)`) is RAUW'd to its
  // wire base and erased here instead of declined. ⚠ That proof reads PRE-
  // `specialize()` taint, so it is RECORDED and re-asked right after
  // `specialize()` (`declineFalsifiedMergePhiLifts`, bd `test_C_libtooling-d88e`):
  // a base the scrub proves classical turns the accept back into this guard's
  // decline.
  // bd `test_C_libtooling-zujr` — THE TRIP-1 PROMOTION, immediately before the
  // guard whose accept it grants. Contract, slot and retirement trigger in
  // `LoopPlan.h`; it never declines, and an unpromoted carried-handle φ is
  // refused by the very next call.
  promoteLoopCarriedHandleSeeds(M, wd, taint);
  declineClassicalMuxes(M, taint);
  // (The bd 2qyz post-lift stale-record re-sweep, `declineLiftedStaleRecordOps`,
  // used to run HERE. It runs below, after `specialize()` and the bd d88e re-ask
  // of the lift itself — see there for why.)

  // Phase 6 specialization DRIVER (step 14, DD-1): drains `plan6.Pending`,
  // cloning each visible pure-classical callee, lowering it under a disjoint
  // `cloneTaint`, and Bennett-wrapping it — strictly BEFORE `lowerRotations`
  // (the clone must be theta-free before the RAUW-to-handle at :110). The clone
  // bodies are invisible to the single module-wide `uncompute` below because
  // `cloneTaint` is never unioned into `taint` (C-Taint); `specialize` re-marks
  // each retargeted call result into `taint` per its post-lowering return-taint.
  specialize(M, wd, taint, plan6);
  // bd `test_C_libtooling-d88e` (P1) — the scrub-direction L1 re-ask of a
  // REWRITE. `declineClassicalMuxes` above lifted every one-register merge phi
  // on PRE-scrub taint, RAUW'ing it onto its wire base; a base that `specialize()`
  // just proved classical was never a register, and every consumer of the erased
  // phi reads it as a classical value: a `cq_measure` vanishes, and a consumer
  // that is itself a gate lands the arm's rotation on an orphan rail while the
  // measurement count stays right (Rule-13 r1B `zlC`, r1A `r16`) — exit 0,
  // stage-2b clean either way. The lift RECORDED its premise; this re-asks it at
  // FINAL taint and declines with the classical-mux guard's own string — the
  // hand-inlined twin's verdict (and its string when this phi is the module's
  // first classical-mux offender, r1A F-DA-3). FIRST after `specialize()`, ahead
  // of the 2qyz re-sweep,
  // the l3oi fence and the stale-reader backstop, so the owner whose premise was
  // falsified speaks (`..._spec_scrubbed_base_owner.ll` pins the slot against the
  // backstop, `..._spec_scrubbed_base_pure_consumer.ll` against the re-sweep,
  // `..._spec_scrubbed_base_l3oi_owner.ll` against the l3oi fence).
  // Nothing between here and `lowerRotations` changes `taint.Tainted` (the
  // re-sweep below writes only `StaleDeclined`), so the taint it reads is the
  // taint `lowerRotations` decides `Chained` on.
  if (declineFalsifiedMergePhiLifts(M, taint))
    return PreservedAnalyses::none();

  // Post-lift stale-record re-sweep (test_C_libtooling-2qyz): the lift RAUWs a
  // merge phi to its wire base AFTER declineStaleRecordOps already ran, so a
  // consumer over a re-Ry'd wire would lower silently. When a lift occurred
  // (witnessed by taint.LiftedMergePhis, the lift EVENT — bd ec7r) this re-runs the FULL stale-record
  // sweep on the post-lift IR — a stale op can be a TRANSITIVE consumer any
  // number of in-place-gate hops below the lifted phi, so a scoped re-check is
  // incomplete (Rule-13 finding). Idempotent + still pre-RAUW SSA identity;
  // no-op when nothing was lifted.
  //
  // ⚠ MOVED HERE from right after `declineClassicalMuxes` by bd d88e, and the
  // slot is the argument. This sweep adjudicates CONSEQUENCES of a lift, so it
  // must run only once the lift itself is confirmed: before `specialize()` it
  // judged the post-lift IR on PRE-scrub taint, and for a lift the re-ask above
  // now refuses it declined FIRST, with a stale-record string for a staleness the
  // false RAUW manufactured (probe `g01C`, `r = t; if (c) { r = t; cq_theta(&r, a); }
  // cq_measure(r + 1)` over a spec-classical `t`, where the hand-inlined twin
  // declines at the classical-mux guard). Here it reads POST-scrub taint (the
  // same `taint.Tainted` `lowerRotations` starts from), and every lift still
  // standing is a proven one. It still runs BEFORE the l3oi fence, the relative
  // order it always had. RETIREMENT TRIGGER: a stage that REMOVES taint after
  // this slot re-opens the same window for this sweep.
  declineLiftedStaleRecordOps(M, taint);

  // bd `test_C_libtooling-l3oi` — the scrub-direction L1 re-ask of an EMISSION:
  // `specialize()` can REMOVE taint (a clone proved classical), after every
  // control emitter already read the value as a handle. Loud, and ahead of
  // everything after it except the d88e re-ask and the 2qyz re-sweep just above.
  if (declineScrubbedHandleReads(M, taint))
    return PreservedAnalyses::none();

  // bd `test_C_libtooling-z0re` — the GROWTH-direction twin of the l3oi re-ask
  // just above, for the RUNTIME state-prep seed the owner admitted 2026-09-28. F1
  // (and S3 for the angle select) accepted the seed as CLASSICAL at the taint of
  // its detection round; a 6.5/4.5 `%out` derivative is quantum after the
  // round-2 fixpoint, and `lowerRotations` below decides `Chained` on EXACTLY
  // this taint (nothing between `specialize()` and it writes `taint.Tainted`) —
  // so a seed that turned quantum would lower as an in-place controlled Ry that
  // R4/R6/S8/S9 never vetted. Re-asked on the record the two emitters took.
  // After the l3oi fence and before the stale-reader backstop, so it speaks
  // only where the premise it re-asks is the one that failed. A no-op for every
  // module whose preps have literal seeds — every module before this increment.
  if (declineRound2QuantumPrepSeeds(M, taint))
    return PreservedAnalyses::none();

  // The lowered calls are erased inside each step, so nothing dangles and
  // there is no separate dead-init sweep.
  // (bd test_C_libtooling-3d8q, P1) THE STALE-READER BACKSTOP — drains the record
  // `recordStaleQuantumReaders` took at the EARLY slot (the linear rule,
  // `docs/frontend.md` §3.2, for a `@cq_theta_<sfx>` / `@cq_measure_<sfx>` reader
  // of a name the wire has moved past).
  //
  // ⚠ AS LATE AS IT CAN POSSIBLY BE, and that is the point. This fence is a
  // BACKSTOP for the shapes no specialised owner claims, never a preemptor of
  // one: the condition-wire dispositions, `ArmClassify` R6,
  // `LoopLowering::staleRailRecordRead`, `declineClassicalMuxes` and
  // `declineLiftedStaleRecordOps` all own shapes of their own and all give a more
  // precise message. `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd
  // `br4a`), so "last" is literally "every other owner goes first" — measured:
  // emitted at the early slot this takes the message away from 68 shipped
  // negative fixtures, leaving 68 fences pinned by nothing (Rule 12
  // fixture-hygiene defect (c)).
  //
  // ⚠ IT CANNOT GO ANY LATER. `lowerRotations` below RAUWs every `@cq_theta_*`
  // result to an `i32` handle and erases the call; `lowerMeasures` does the same
  // for the measures. A recorded reader is a `WeakTrackingVH`, so moving this
  // call below either of them NULLS the whole record and the fence becomes a
  // silent no-op — with no diagnostic anywhere. RETIREMENT TRIGGER: that, and
  // moving the ANALYSIS half (`recordStaleQuantumReaders`) below `lowerLoops` /
  // the peel / control detection, which reopens the over-decline the split
  // exists to avoid.
  declineRecordedStaleQuantumReaders(M, taint);
  // bd `test_C_libtooling-s82e` / owner ruling D4 (2026-09-14c) — the narrow
  // divergent sub-case of the unmarked-loop rail leak. AFTER the stale-reader
  // backstop on purpose (it keeps its documented "last owner to speak" role for
  // every module that already declines; this one only ever speaks where nothing
  // else did — measured as ZERO string moves over the corpus sweep), and after
  // the round-2 fixpoint so `taint.IterationLocalBlocks` is FINAL. Contract and
  // retirement triggers in `LoopPlan.h`; the argued comment is at the definition.
  declineDephasingUnmarkedLoopRails(M, taint);
  // bd `test_C_libtooling-tu9q` — the L1 RE-ASK of `lowerLoops`' round-1
  // root-mint marking grant, under FINAL taint. Below the round-2 fixpoint (the
  // whole point) and above `lowerRotations` (which RAUWs the recorded roots to
  // `i32` handles). Placed LAST in the decline chain so it only ever speaks where
  // nothing else did; a no-op when `taint.Round1RailGrants` is empty, which is
  // every module with no bounded quantum loop reading a loop-invariant register.
  declineRound2FalsifiedRailGrants(M, taint, wd);
  // bd `test_C_libtooling-vsfp` (P1) / bd `tzfa` (P1) — THE PHANTOM READ,
  // RESOLVED: the observing half of `dropDeadCallArguments` (its slots A and B
  // above), with the specializer's record of the SAME liveness predicate
  // (`taint.SpecDeadArgMask`). It NEUTRALISES every recorded-dead slot of every
  // module-level clone call that the drop's eligibility admits (a null constant —
  // bd `91k9`: never a pointer or `byval` slot; a quantum operand in such an
  // ineligible slot declines instead), so the
  // uncompute spine, M-C, M-A and stage 2b all see the hand-inlined twin's
  // consumer set; then it declines a neutralised QUANTUM operand the user program
  // no longer reads (a rail minted only for the phantom — the twin has none).
  // ⚠ Round 2's version declined unless the operand was "kept alive elsewhere"
  // and then ACCEPTED with the phantom read still in place: the spine saw an extra
  // consumer and left a template rail dirty (bd tzfa, r2B `k19`: `q` dephased).
  // ⚠ Round 1 called this "TOTAL"; it acts only on phantom reads THROUGH A CLONE
  // CALL (r1A F-VA-2). Other dead keepers are the drop's `deleteDeadCones`.
  //
  // ⚠ THE SLOT: after `specialize()`, the first point at which the clone bodies
  // are FINAL (a read the clone's own flatten removed is visible only here), and at
  // the END of the post-`specialize()` decline chain — after the bd d88e lift
  // re-ask, the bd 2qyz re-sweep, the bd l3oi fence, the bd 3d8q stale-reader
  // backstop and the two loop re-asks above — so it only ever speaks where nothing
  // else did (`LLVMContext::diagnose` exits on the first `DS_Error`, bd br4a).
  // ⚠ WHY LAST IS NOT "TWIN PARITY" (L7; Rule-13 r1B F-VB-5). Round 1 wrote "the
  // twin never computes the phantom operand, so any OTHER owner that fires here
  // fires on the twin too". False in one direction: an earlier owner can fire ON
  // THE PHANTOM OPERAND'S OWN CONE, which the twin does not have (r1B `v27`: l3oi
  // refused a 4.4 select reading a scrubbed call result, while the twin accepted).
  // The correct statement: an earlier owner fires either on something the twin also
  // has (same verdict) or on the phantom operand's cone (the twin has none — a
  // decline where the twin accepts, the safe direction). Since round 2 the drop
  // removes such a cone before emission whenever the callee's parameter is dead in
  // the ORIGINAL body (`v27` now accepts, twin-identical). Before `lowerRotations`,
  // which RAUWs every `cq_theta` result to its handle, and before `lowerOps` and
  // `uncompute`, which build the consumer sets the neutralisation corrects.
  // Nothing between `specialize()` and here writes `taint.Tainted`, so the taint
  // it reads is FINAL.
  if (resolvePhantomCloneArgReads(M, taint))
    return PreservedAnalyses::none();

  lowerRotations(M, wd, taint, plan.get());
  // ── bd `xdu2` / L-1a W1 PIECE 2 — the rail-bank cell TYPE REWRITE,
  //    `[N x cell]` → `[N x i32]` of runtime handles (Rule 15).
  //
  // ⚠ BETWEEN `lowerRotations` AND `lowerOps`, AND BOTH BOUNDS ARE THE
  // CONTRACT. Above `lowerRotations` the stored value is still the `@cq_theta`
  // call and there is no handle to store. Below `lowerOps` the storage cast has
  // already become `cq_template_zext_i1_to_i8` — A SECOND, ENTANGLED RAIL PER
  // CELL, with the original left allocated (measured, `probes/b09`). This is
  // NOT `SCOPE_L1a.md` §3(a)'s proposed slot ("after `lowerOps`"), and the move
  // is deliberate and recorded there.
  //
  // The L1 answer is unchanged by the move and still sufficient: this slot is
  // strictly after `repropagateControlMerges`, so the taint it reads is FINAL.
  rewriteRailBankCellTypes(M, taint);
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
  for (Function &F : M)
    if (!F.isDeclaration())
      stabilizeSpeculatedValues(F, taint);
  // libcqops b6a — every QRAM call (forward and `_unc`) whose index is not a
  // 32-bit rail gets its own `cast; call; cast_unc; free` bracket. AFTER
  // `uncompute` so no cast rail is ever a live record in the DAG it planned, and
  // BEFORE the literal-integrity guard so that guard still sees every emitted call.
  bracketQramIndexCasts(M, wd, taint);
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
  // bd dm7f.4 — the kept-flag postcondition, the one LOUD question in M-A's slot
  // and asked with M-A's predicates: a kept condition flag is the only record
  // the owner ruled into the circuit, so any other condition-chain rail of the
  // rotated register still standing unobserved at its controlled Ry declines
  // (RotationLowering.h). Before the warning, so a refused module prints none.
  if (declineUndischargedKeptFlagChains(M, taint))
    return PreservedAnalyses::none();
  // bd test_C_libtooling-6uqc (M-A) — the LIVE-RECORD WARNING, at the
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
  // `DS_Error` long before here, so this one re-owns no shipped message
  // (census 0.4's 9 at-risk fixtures all decline at or before run-line 404).
  //
  // IT IS A WARNING SINCE INCREMENT 7b (owner ruling 2026-08-29, bd lyyf): the
  // dephasing-by-leftover-record class is the USER's circuit, so it is reported
  // and LOWERED — `opt` exits zero and hands back the module, and the named
  // record is left allocated (never freed dirty; Rule 6 is untouched). The
  // returned bool is therefore NOT branched on: there is nothing to abandon.
  // Every WRONG-VALUE and DIRTY-FREE owner above stays loud; the ruling reverses
  // this guard's decline half and nothing else.
  warnLiveRecordRotations(M, taint);
  // bd test_C_libtooling-bbu0, owner ruling E6 (2026-09-15) = option (D) — drain
  // the verdict `declineDephasingUnmarkedLoopRails` (:772) DEFERRED under
  // `CQ_BBU0_DEFER_DEPHASE_FENCE`. A NO-OP with the variable unset; contract in
  // LoopPlan.h. IMMEDIATELY AFTER the warn stage in BOTH directions: earlier and
  // the instrument's marker stops proving the warn stage ran (the measurement's
  // only vacuity guard); omitted here and a gated module would exit ZERO, the one
  // outcome the instrument must never produce.
  emitDeferredDephasingDecline(M);
  // bd `test_C_libtooling-6n1s` F-1 — THE MARKED BODY'S POSTCONDITION. Contract in
  // `LoopPlan.h`. `declineDephasingUnmarkedLoopRails` (above) no longer SUPPRESSES
  // its fence on a marked body; it RECORDS the promise that the body's interior
  // rails will be discharged in-body, and this is where that promise is checked
  // against the emitted module. It is the first point at which "was this rail
  // discharged?" is a FACT rather than a forecast — `uncompute` has run.
  //
  // ⚠ IN BOTH ENTRY POINTS, and that is a contract rather than a convenience: a
  // fence added to one of two entry points is a hole with no diagnostic anywhere
  // (`CLAUDE.md` L1's cure names "in BOTH entry points" for exactly this reason).
  // ⚠ AFTER `emitDeferredDephasingDecline`, so bd `bbu0`'s deferred verdict still
  // speaks first when its env gate is on — `LLVMContext::diagnose` EXITS on the
  // first `DS_Error` (bd `br4a`), so ORDER is what keeps one module from having
  // two owners for one diagnostic. It re-uses that fence's own message string.
  if (declineUndischargedMarkedBodyRails(M))
    return PreservedAnalyses::none();
  // THE POSTCONDITION BACKSTOP (bd 3qlq Inc 1 part A, round-1 F-L6-1) — see the
  // function's own header. Runs BEFORE `eraseDeadDecls`, which only erases the
  // declarations that are already unused and is therefore blind to a surviving
  // CALL.
  if (declineSurvivingIntrinsicCalls(M, wd))
    return PreservedAnalyses::none();
  // Rail-bank cell postcondition (bd xdu2.4 review A F-1): no bank cell may park
  // a literal. Asked once every folder has run, because the literal arrives by
  // COMPOSITION (a constant-condition select stored to a cell, then a PredMux
  // residue fold), not from one stage. The first exhibit's select was the
  // promoter's own PASS H output; bd xdu2.9 made PASS H resolve a constant
  // condition itself, so this backstop's lit pin is now
  // `railbank_deadcell_reject_backstop_literal.ll`.
  if (declineNonHandleBankStores(M))
    return PreservedAnalyses::none();
  eraseDeadDecls(M, wd);
  eraseUnusedLibmBodies(M, /*KeepBindable=*/false);  // bd 3c6m.72, LibmBinding.h

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
      taint.PhaseCalls.empty() && taint.MeasureCalls.empty())
    return eraseUnusedLibmBodies(M, /*KeepBindable=*/false);
  bindLibmCalls(M, taint, wd);  // bd 3c6m.72 — see run().
  eraseUnusedLibmBodies(M, /*KeepBindable=*/true);

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
  //
  // ⚠ `deleteGlobalPhases` (bd 3qlq Inc 1, P7) IS A FOURTH MODULE-WIDE STAGE and
  // belongs in that list — Rule-13 round-1 finding F-L3-6. `onlyInF` scopes the
  // WORK LISTS, but `deleteGlobalPhases` deliberately derives its survivors from
  // `wd.phaseFn()->users()` rather than from `taint.PhaseCalls` (so a missed
  // emitter scrub is a no-op instead of a dangling read), and that use list is
  // module-wide. So this shim would DELETE `cq_phi` calls in functions other than
  // `F`, and — since F-L3-4 — would DECLINE on an address-take anywhere in `M`.
  // Same disposition as the three above: harmless while this entry point has zero
  // callers, and a reviver must scope it to `F` or accept it as module-wide.
  //
  // ⚠ A FIFTH AND SIXTH (bd vsfp, Rule-13 r2A F-WA-4): `dropDeadCallArguments`
  // (both slots) and `resolvePhantomCloneArgReads` rewrite call arguments in EVERY
  // function of M, and the drop's LOAD-BEARING front-end-site skip reads the
  // membership lists AFTER `onlyInF` has filtered them to F — so a reviver would
  // no longer protect another function's `cq_theta` angle in a module that DEFINES
  // the reserved symbol (`spec_accept_dropped_arg_reserved_symbol_angle.ll`'s
  // shape; the liveness ROOT side is still covered by the reserved-name root). The
  // `declineStaleTaintSet` postcondition compares only `Tainted`, which `onlyInF`
  // never filters. Same disposition: a reviver must scope all of these to `F`.
  auto onlyInF = [&F](auto &Calls) {
    Calls.remove_if([&F](CallInst *CI) { return CI->getFunction() != &F; });
  };
  onlyInF(taint.ThetaCalls);
  onlyInF(taint.PhiCalls);
  onlyInF(taint.PhaseCalls);
  onlyInF(taint.MeasureCalls);
  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty() &&
      taint.PhaseCalls.empty() && taint.MeasureCalls.empty())
    return false;

  // bd `test_C_libtooling-dm7f.5` — the multi-exit `ret` normalization's SLOT (a),
  // mirrored (twin-pipeline parity is MANDATORY, WI-1.12); see run(). Module-wide,
  // like the dead-argument drop below (AXIS-F).
  if (unifyTaintedReturns(M, taint, /*Delta=*/nullptr)) {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.PhaseCalls);
    onlyInF(taint.MeasureCalls);
  }

  // bd `test_C_libtooling-vsfp` — the dead call-argument drop's SLOT A, mirrored
  // in this entry point too (twin-pipeline parity is MANDATORY, WI-1.12). FIRST,
  // before any stage reads an argument; see run() for the slot argument and for
  // slot B. Module-wide, like `detectSpecializations` below (AXIS-F).
  if (dropDeadCallArguments(M, taint)) {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.PhaseCalls);
    onlyInF(taint.MeasureCalls);
  }

  // p119: by-ref math canonicalization removed (library functions, source-injected
  // not recognized) — see run(). Twin-pipeline parity preserved by the removal in
  // both entry points.

  // bd `xdu2` / L-1a clause C5 — the rail-bank per-activation promoter, mirrored
  // in this entry point too (twin-pipeline parity is MANDATORY, WI-1.12). See
  // run() for the contract, the completed pipeline, and — the part that must not be
  // separated from the call — the L1 SLOT ARGUMENT: this stage grows the taint
  // set, so it is sound ONLY because it runs above every stage that adjudicates
  // consumers of tainted values, `foldIdentityBitcasts` included.
  stripForeignQramIndexTags(M);  // libcqops b6a — mirrored from run().
  if (declineForeignRailBankSeeds(M))
    return false;
  while (promoteRailBankCells(M, wd, taint)) {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.MeasureCalls);
  }
  if (::getenv("CQ_RAILBANK_DBG")) {
    llvm::errs()
        << "=== CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===\n";
    M.print(llvm::errs(), nullptr);
  }
  // bd `xdu2` / L-1a W1 — the `!cq.railbank` mint + re-propagate, mirrored in
  // this entry point too (twin-pipeline parity is MANDATORY, WI-1.12). See
  // run() for the slot argument, which must not be separated from the call.
  if (markRailBankAllocas(M, taint)) {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.MeasureCalls);
  }

  // bd iw81.1: fold same-width int<->int bitcast identity, mirrored in this entry
  // point too (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the
  // fold-before-any-analysis rationale (and see it for why `Scrub` is null here).
  foldIdentityBitcasts(M, taint, /*Scrub=*/nullptr);

  // bd 3c6m.14 Inc 3 — volatile-const global-load fold, mirrored in this entry
  // point too (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the
  // post-passthrough / pre-PredMux placement rationale.
  if (foldVolatileConstGlobalLoads(M, taint)) {  // bd otam/stl3 — see run().
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.PhaseCalls);
    onlyInF(taint.MeasureCalls);
  }

  // bd etiq — volatile-const LOCAL fold, mirrored in this entry point too
  // (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the
  // post-global-fold / pre-PredMux placement rationale.
  if (foldVolatileConstAllocaLoads(M, taint)) {  // bd otam — see run().
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.PhaseCalls);
    onlyInF(taint.MeasureCalls);
  }

  // bd k710 — DEAD volatile SCALAR STORE elimination (QramLowering.cpp): the
  // WRITE-ONLY sibling of the two folds above, for openlibm's underflow idiom
  // (`volatile float u = x*x; /* underflow */`, ld80/s_nexttowardf.c:63, `u`
  // never read). Zero loads means neither fold above nor zco4's promotion can
  // claim it, so the volatile store survives to `declineTaintEscapes` and the
  // cell dies on kMsgStore. Grounded in the fenv ruling (owner 2026-08-10): CQ
  // models no FP exception flags and a volatile access to a non-escaping local
  // is not observable. Erases the stores/markers/alloca AND the stored value's
  // dead cone (bd qjoc / bd vsfp round 2, the pass's ONE liveness predicate) —
  // the computation disappears, which IS what the ruling licenses (measured: zero
  // `fmul_f32` in slice_libm_ld80_nexttowardf). ⚠ The sentence that stood here —
  // "outside a region it is instead lowered, uncomputed and freed" — was false
  // for a dead 4.4 select (a silent which-path rail) and a dead template product
  // whose source is later rotated (a dirty rail); see QramLowering.h.
  if (eraseDeadVolatileScalarStores(M, taint)) {  // bd otam — see run().
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.PhaseCalls);
    onlyInF(taint.MeasureCalls);
  }

  // bd zco4 — volatile scalar-local SSA promotion, mirrored in this entry point
  // too (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the
  // same-slot-as-etiq placement + fixpoint-re-propagate rationale.
  while (promoteVolatileScalarLocals(M, taint)) {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.MeasureCalls);
  }

  // bd `test_C_libtooling-vsfp` round 2 — the drop's SLOT B, mirrored in this
  // entry point (twin-pipeline parity, WI-1.12). See run() for why two slots.
  if (dropDeadCallArguments(M, taint)) {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.PhaseCalls);
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
  //
  // bd `test_C_libtooling-woa0` — the cross-claim record, mirrored here because
  // "in BOTH entry points" is the cure's own wording and a fence added to one of
  // two entry points is a hole with no diagnostic anywhere. See run().
  PredMuxRailPhiRecord railPhiRec;
  while (flattenPredMuxRegions(M, taint, /*claimAll=*/false, &railPhiRec)) {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.MeasureCalls);
  }

  // The loop pre-passes, mirrored in this entry point too (twin-pipeline parity
  // is MANDATORY, WI-1.12): the same driver as run(), with this shim's
  // filtered re-propagation.
  auto Reprop = [&] {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.MeasureCalls);
  };
  runLoopPrepasses(M, taint, railPhiRec, StageScope{Reprop});

  // bd `test_C_libtooling-woa0` — the re-ask, mirrored in this entry point too
  // (twin-pipeline parity is MANDATORY, WI-1.12). Same slot by the same
  // argument: after all three top-level PredMux fixpoints and before the first
  // stage that could inherit ownership of the decline. See run().
  if (declineConvertedRailPhiLeaves(railPhiRec))
    return false;
  // Phase 6 specialization pre-pass + carve-out, mirrored in this entry point
  // too (twin-pipeline parity is MANDATORY — a pre-pass wired in `run()` but not
  // here would silently diverge, WI-1.12). See run() for the rationale.
  if (declineStaleTaintSet(M, wd, taint))  // bd otam — see run().
    return false;
  bindLibmCalls(M, taint, wd);  // bd 3c6m.72 — see run().
  SpecPlan plan6;
  detectSpecializations(M, taint, wd, plan6);

  // Taint-escape + stale-record guards run FIRST here too (twin-pipeline
  // trap, IMPLEMENTATION §6.5) — see run(). Both are module-scoped like
  // `lowerOps`, which also walks all of `M` (only the rotation/measure work
  // lists above are F-restricted).
  declineTaintEscapes(M, taint, plan6);
  declineStaleRecordOps(M, taint);

  // (bd test_C_libtooling-3d8q, P1) THE STALE-READER ANALYSIS — pure analysis,
  // no diagnostic, paired with `declineRecordedStaleQuantumReaders` far below.
  // It asks the linear rule (`docs/frontend.md` §3.2) of the reader families the
  // sweep above does not cover: a `@cq_theta_<sfx>` (arg-0) or `@cq_measure_<sfx>`
  // call reading a name the wire has already moved past. Until this, a rotation
  // or a measurement reading a stale name was asked NOTHING while an `add` on
  // the same name declined — a CONFIRMED verify-clean silent miscompile, exit 0
  // and stage-2b clean, emitting a stream byte-identical to a DIFFERENT
  // well-formed program.
  //
  // ⚠ IT MUST RUN HERE, BEFORE `lowerLoops` / the peel / control detection, and
  // that is the over-decline half of the argument: its premise is that an SSA
  // name denotes a basis RECORD, which is true only of the names the USER wrote.
  // The rail-φ collapse, the peel and the one-register lift each REWRITE a
  // wire-TRACKING name into a wire-BASE name, and the fence asked after any of
  // them declines well-formed programs for a fact about the rewrite (measured: 9
  // shipped in-loop ACCEPT fixtures). The diagnostic half is deferred to the late
  // slot for the opposite reason — see `TaintSet::StaleQuantumReaders`.
  recordStaleQuantumReaders(M, taint);

  // Controlled Tier-0 conditional output (Phase 7.6 Increment 2) mirrored in
  // this entry point too (twin-pipeline parity is MANDATORY, WI-1.12) — see
  // run() for the pre-`detectControlRegions` ordering rationale.
  lowerControlledIOSinks(M, wd, taint);

  // `lowerLoops` through the round-2 re-asks, mirrored (twin-pipeline parity is
  // MANDATORY, WI-1.12): the same driver as run(). This shim has never run
  // `collapseFlattenedLoopRails`; that difference is kept, not introduced.
  StageScope ChainScope{Reprop};
  ChainScope.CollapseLoopRails = false;
  std::unique_ptr<ControlPlan> plan =
      runControlChain(M, wd, taint, plan6, ChainScope);
  // bd test_C_libtooling-3qlq Inc 1 (P7) mirrored in this entry point too
  // (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for why the ONLY
  // sound slot is AFTER `repropagateControlMerges` and not immediately after
  // `lowerControlRegions` (Rule-13 round-1 finding F-L3-1: round 2 is a full
  // second round of control detection, so at the earlier slot P7 deleted branch
  // phases whose regions had never been looked at).
  deleteGlobalPhases(M, wd, taint);
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
  // bd `test_C_libtooling-zujr` — THE TRIP-1 PROMOTION, immediately before the
  // guard whose accept it grants. Contract, slot and retirement trigger in
  // `LoopPlan.h`; it never declines, and an unpromoted carried-handle φ is
  // refused by the very next call.
  promoteLoopCarriedHandleSeeds(M, wd, taint);
  declineClassicalMuxes(M, taint);
  // (The bd 2qyz post-lift stale-record re-check runs below `specialize()` and
  // the d88e re-ask — see run().)
  // Phase 6 specialization driver (step 14) — mirrored from run() (twin-pipeline
  // parity, WI-1.12).
  specialize(M, wd, taint, plan6);
  // bd `test_C_libtooling-d88e` — the lift re-ask, same slot as run() and for
  // the same reason (twin-pipeline parity).
  if (declineFalsifiedMergePhiLifts(M, taint))
    return false;
  // Post-lift stale-record re-check (test_C_libtooling-2qyz) — moved below the
  // d88e re-ask by bd d88e; see run() for why.
  declineLiftedStaleRecordOps(M, taint);
  // bd `test_C_libtooling-l3oi` — the scrub-direction L1 re-ask of an EMISSION:
  // `specialize()` can REMOVE taint (a clone proved classical), after every
  // control emitter already read the value as a handle. Loud, and ahead of
  // everything after it except the d88e re-ask and the 2qyz re-sweep above.
  if (declineScrubbedHandleReads(M, taint))
    return false;
  // bd `test_C_libtooling-z0re` — the runtime state-prep seed's L1 re-ask, same
  // slot as run() and for the same reason (twin-pipeline parity is MANDATORY,
  // WI-1.12).
  if (declineRound2QuantumPrepSeeds(M, taint))
    return false;
  // (bd test_C_libtooling-3d8q, P1) THE STALE-READER BACKSTOP — drains the record
  // `recordStaleQuantumReaders` took at the EARLY slot (the linear rule,
  // `docs/frontend.md` §3.2, for a `@cq_theta_<sfx>` / `@cq_measure_<sfx>` reader
  // of a name the wire has moved past).
  //
  // ⚠ AS LATE AS IT CAN POSSIBLY BE, and that is the point. This fence is a
  // BACKSTOP for the shapes no specialised owner claims, never a preemptor of
  // one: the condition-wire dispositions, `ArmClassify` R6,
  // `LoopLowering::staleRailRecordRead`, `declineClassicalMuxes` and
  // `declineLiftedStaleRecordOps` all own shapes of their own and all give a more
  // precise message. `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd
  // `br4a`), so "last" is literally "every other owner goes first" — measured:
  // emitted at the early slot this takes the message away from 68 shipped
  // negative fixtures, leaving 68 fences pinned by nothing (Rule 12
  // fixture-hygiene defect (c)).
  //
  // ⚠ IT CANNOT GO ANY LATER. `lowerRotations` below RAUWs every `@cq_theta_*`
  // result to an `i32` handle and erases the call; `lowerMeasures` does the same
  // for the measures. A recorded reader is a `WeakTrackingVH`, so moving this
  // call below either of them NULLS the whole record and the fence becomes a
  // silent no-op — with no diagnostic anywhere. RETIREMENT TRIGGER: that, and
  // moving the ANALYSIS half (`recordStaleQuantumReaders`) below `lowerLoops` /
  // the peel / control detection, which reopens the over-decline the split
  // exists to avoid.
  declineRecordedStaleQuantumReaders(M, taint);
  // bd `test_C_libtooling-s82e` / owner ruling D4 (2026-09-14c) — the narrow
  // divergent sub-case of the unmarked-loop rail leak. AFTER the stale-reader
  // backstop on purpose (it keeps its documented "last owner to speak" role for
  // every module that already declines; this one only ever speaks where nothing
  // else did — measured as ZERO string moves over the corpus sweep), and after
  // the round-2 fixpoint so `taint.IterationLocalBlocks` is FINAL. Contract and
  // retirement triggers in `LoopPlan.h`; the argued comment is at the definition.
  declineDephasingUnmarkedLoopRails(M, taint);
  // bd `test_C_libtooling-tu9q` — the L1 RE-ASK of `lowerLoops`' round-1
  // root-mint marking grant, under FINAL taint. Below the round-2 fixpoint (the
  // whole point) and above `lowerRotations` (which RAUWs the recorded roots to
  // `i32` handles). Placed LAST in the decline chain so it only ever speaks where
  // nothing else did; a no-op when `taint.Round1RailGrants` is empty, which is
  // every module with no bounded quantum loop reading a loop-invariant register.
  declineRound2FalsifiedRailGrants(M, taint, wd);
  // bd `test_C_libtooling-vsfp` / bd `tzfa` — the phantom-read resolution
  // (neutralise, then decline what the twin does not compute), mirrored in this
  // entry point too (twin-pipeline parity is MANDATORY, WI-1.12). Same slot, last
  // in the post-`specialize()` decline chain; see run().
  if (resolvePhantomCloneArgReads(M, taint))
    return false;

  lowerRotations(M, wd, taint, plan.get());
  // ── bd `xdu2` / L-1a W1 PIECE 2 — the rail-bank cell TYPE REWRITE,
  //    `[N x cell]` → `[N x i32]` of runtime handles (Rule 15).
  //
  // ⚠ BETWEEN `lowerRotations` AND `lowerOps`, AND BOTH BOUNDS ARE THE
  // CONTRACT. Above `lowerRotations` the stored value is still the `@cq_theta`
  // call and there is no handle to store. Below `lowerOps` the storage cast has
  // already become `cq_template_zext_i1_to_i8` — A SECOND, ENTANGLED RAIL PER
  // CELL, with the original left allocated (measured, `probes/b09`). This is
  // NOT `SCOPE_L1a.md` §3(a)'s proposed slot ("after `lowerOps`"), and the move
  // is deliberate and recorded there.
  //
  // The L1 answer is unchanged by the move and still sufficient: this slot is
  // strictly after `repropagateControlMerges`, so the taint it reads is FINAL.
  rewriteRailBankCellTypes(M, taint);
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
  for (Function &F : M)
    if (!F.isDeclaration())
      stabilizeSpeculatedValues(F, taint);
  // libcqops b6a — mirrored from `run()` (twin-pipeline parity, WI-1.12).
  bracketQramIndexCasts(M, wd, taint);
  // bd xy9n — mirrored from `run()` (twin-pipeline parity, WI-1.12): miss it and
  // a unit-level caller silently keeps the pairing break. See run() for why this
  // position is the complete one, and for why the bool is consumed.
  if (declineUnpairedUndefLiterals(M))
    return true;
  // bd dm7f.4 — mirrored from `run()` (twin-pipeline parity, WI-1.12): miss it
  // and this entry point lowers a kept-flag region whose condition chain is
  // still live at the gate.
  if (declineUndischargedKeptFlagChains(M, taint))
    return true;
  // bd test_C_libtooling-6uqc (M-A) — mirrored from `run()` (twin-pipeline
  // parity, WI-1.12): miss it and a unit-level caller loses the live-record
  // report. See run() for the late-slot + emitter-keyed rationale and for why
  // the bool is not branched on (owner ruling 2026-08-29, bd lyyf).
  warnLiveRecordRotations(M, taint);
  // bd test_C_libtooling-bbu0 (D), mirrored in this entry point too — the
  // deferred-verdict drain. Twin-pipeline parity is MANDATORY (WI-1.12) and here
  // it is load-bearing rather than tidy: an entry point that records a deferral
  // and never drains it hands back a module with `opt` exit 0 on a program this
  // fence refused. See run() for the full rationale.
  emitDeferredDephasingDecline(M);
  // bd `test_C_libtooling-6n1s` F-1 — THE MARKED BODY'S POSTCONDITION. Contract in
  // `LoopPlan.h`. `declineDephasingUnmarkedLoopRails` (above) no longer SUPPRESSES
  // its fence on a marked body; it RECORDS the promise that the body's interior
  // rails will be discharged in-body, and this is where that promise is checked
  // against the emitted module. It is the first point at which "was this rail
  // discharged?" is a FACT rather than a forecast — `uncompute` has run.
  //
  // ⚠ IN BOTH ENTRY POINTS, and that is a contract rather than a convenience: a
  // fence added to one of two entry points is a hole with no diagnostic anywhere
  // (`CLAUDE.md` L1's cure names "in BOTH entry points" for exactly this reason).
  // ⚠ AFTER `emitDeferredDephasingDecline`, so bd `bbu0`'s deferred verdict still
  // speaks first when its env gate is on — `LLVMContext::diagnose` EXITS on the
  // first `DS_Error` (bd `br4a`), so ORDER is what keeps one module from having
  // two owners for one diagnostic. It re-uses that fence's own message string.
  if (declineUndischargedMarkedBodyRails(M))
    return true;
  // The postcondition backstop, mirrored in this entry point too (twin-pipeline
  // parity is MANDATORY, WI-1.12) — see run() for the F-L6-1 rationale.
  if (declineSurvivingIntrinsicCalls(M, wd))
    return true;
  if (declineNonHandleBankStores(M))
    return true;
  eraseDeadDecls(M, wd);
  eraseUnusedLibmBodies(M, /*KeepBindable=*/false);  // bd 3c6m.72 — see run().
  return true;
}

}  // namespace cq
