// CQLoweringPass.cpp — thin orchestrator for the cq-lowering pass.
//
// Per-step bodies live in width-resolver / taint / rotation / opcode /
// measure modules. Width parameterization handles `_Bool` / `i8` /
// `i16` / `i64` / `f32` / `f64`.

#include "CQLoweringPass.h"

#include "ArithLowering.h"
#include "ArmAnalysis.h"      // reverifyRailCondReads (bd r9e5 1b-B.1 round 2)
#include "ByRefInline.h"
#include "CondLiteral.h"      // declineQuantumCondLiterals (bd xdu2.13 round 2)
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
#include "RailBankPromote.h"
#include "RotationLowering.h"
#include "SpecializeDetect.h"
#include "SpecializePlan.h"
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
    while (flattenPredMuxRegions(M, taint, /*claimAll=*/false, &railPhiRec))
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
    while (flattenPredMuxRegions(M, taint, /*claimAll=*/false, &railPhiRec))
      taint = propagate(M, wd);
  }
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
  // bd test_C_libtooling-b6ap — THE MULTI-PHI MERGE PEEL (MergePhiPeel.cpp).
  // `clang -O1` fuses two consecutive source `if`s whose conditions it proves
  // equivalent into ONE diamond whose merge holds SEVERAL phi; `soleMergePhi`
  // returns null on >1 phi and `recoverRegion` then declines `control flow` for a
  // BOOKKEEPING reason (`ControlRegion::Merge` is a single `PHINode *`), not a
  // semantic one. This accept-only normalisation turns every merge phi the region
  // does NOT define into a tainted-condition `select` on a CLONE of the region's
  // compare (or on the rail itself), leaving the ONE phi the region needs and
  // handing the mux to the 4.4 `SelectClassify`/`SelectMergeEmit` substrate that
  // has lowered exactly that spelling since Phase 4.4.
  //
  // ⚠ THE SLOT: immediately BEFORE `detectControlRegions`, and AFTER the PredMux
  // fixpoint. Not before it — peeling first would hand PredMux a merge with one
  // phi where it had two, and BOTH of PredMux's own W5 and W7 witnesses require
  // `NumMergePhis == 1`, so an earlier peel could silently MOVE a PredMux accept.
  // Running after the fixpoint means every region PredMux can claim is already
  // gone, so the peel only ever sees shapes that decline today (its own >=2-phi
  // containment gate makes that exact; see the definition). The
  // `lowerControlledIOSinks` / `lowerLoops` precedent is the same "runs BEFORE
  // `detectControlRegions`" slot, for the same reason.
  //
  // ⚠ IT IS CALLED IMMEDIATELY BEFORE **EVERY** `detectControlRegions` CALL IN
  // THE TREE — here, in the second entry point, and inside
  // `TaintPropagation::detectAndLowerOnwardControl`'s round-2 fixpoint. That is
  // CLAUDE.md's standing lesson "a stage that runs ONCE has a round-2-FALSE
  // premise": `repropagateControlMerges` is a SECOND, FULL round of detection over
  // taint re-seeded from the 6.5/4.5 `%out` rails, so it creates regions round 1
  // never saw (MEASURED: probe `p80`, a fused 2-phi diamond whose condition reads
  // a 6.5 `%out`, against its accepting one-phi control `p81`). A fourth
  // `detectControlRegions` that forgets this call re-opens that window with no
  // diagnostic anywhere.
  //
  // NOTES §2's stage-table question — "does this stage compute something a LATER
  // stage consumes, over a premise round 2 falsifies?" — is YES-with-an-argument
  // here: the peel's P3 dominance and P7 clonability proofs are computed before
  // detection and consumed by it, but both are STRUCTURAL (dominance, block
  // shape, `isa<>`) and the peel changes no edge, so round 2 cannot falsify them
  // for a region round 1 already saw. What round 2 changes is WHICH branches are
  // tainted, and that is what the third call site is for.
  //
  // ⚠ AND THE PEEL GROWS TAINT, SO ITS DELTA IS ADJUDICATED — bd b6ap Rule-13
  // ROUND-1 finding F-B6-1, a CONFIRMED plain-C silent miscompile in five consumer
  // classes. The peel turns a CLASSICAL merge phi into a QUANTUM `select`, and
  // `detectSpecializations` (:321), `declineTaintEscapes` (:330) and
  // `declineStaleRecordOps` (:337) are pure-analysis pre-passes that ran ~90 lines
  // ago on the premise that `propagate` had settled — so without this call a
  // `store`, an unknown callee, a visible-body callee or a STALE-MASK Phase-6
  // clone consumes the new rail's runtime HANDLE TAG as a classical integer, at
  // `opt` exit 0, verify-clean and STRICT stage-2b `0 violation(s)`.
  //
  // ⚠ THE SLOT IS THE ANSWER TO A MEASURED QUESTION, not a convenience. The
  // alternative was to MOVE the peel above `detectSpecializations` so the guards
  // see it in their normal single run; that is refused because the peel cannot
  // cross the four stages in between — `unrollConstTripLoops` (:273) and
  // `recognizeCtlzIdiomLoops` (:302) each RE-RUN the PredMux fixpoint internally
  // and PredMux's own W-witness is literally `NumMergePhis >= 2`
  // (`PredMuxFlatten.cpp`), so a peel above them MOVES a PredMux verdict;
  // `lowerControlledIOSinks` (:349) gates on `NumPhis == 0 || ValuePhi`, so a peel
  // above it manufactures NEW 7.6 I/O accepts nothing has measured (and retires
  // the containment-gate argument that its verdict is already final); and
  // `lowerLoops` (:365) is the eight-findings-over-six-rounds neighbourhood the
  // peel's own P9 refuses to widen into. Keeping the slot and re-asking the
  // guards costs one pure-analysis re-scan and removes the premise instead of
  // relocating it. See `FIX_b6ap_R1.md` for the per-stage table.
  {
    SmallPtrSet<Value *, 32> PeelDelta;
    peelIndependentMergePhis(M, taint, &PeelDelta);
    adjudicateTaintDelta(M, wd, taint, plan6, PeelDelta);
  }

  ControlPlan plan = detectControlRegions(M, wd, taint);
  lowerControlRegions(M, wd, taint, plan);

  // Bounded loops, ROUND 2 (Phase 7.3 Increment 3, bd test_C_libtooling-8h7d.5).
  // `lowerLoops` above deliberately leaves a loop with IN-BODY tainted control
  // unclaimed (`tryCaseA` gate L2) — pre-flatten it cannot peel the persistent
  // rail past the region's merge phi and would X1-decline a clean loop. The
  // regions are flattened now, so the same analysis is re-asked on the
  // straight-line body and collapses the loop-carried header phi to its root
  // mint (the rolled-in-place form, PRD 7.3 §2.1 — IR size independent of the
  // trip count). Placed HERE and not later for the SAME three reasons round 1
  // states: BEFORE `declineClassicalMuxes` (else the surviving rail phi
  // false-declines with `kMsgClassicalPhi`, whose "classical-condition" wording
  // mislabels a quantum register), BEFORE `lowerRotations` (pre-RAUW SSA
  // identity — the collapse target is the still-present `@cq_theta` mint), and
  // AFTER the flatten it depends on. A no-op unless an in-loop region was
  // actually emitted (`taint.InLoopFlattenedPreds`), so every pre-existing
  // module is byte-identical.
  collapseFlattenedLoopRails(M, wd, taint);

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

  // bd test_C_libtooling-r9e5 (1b-B.1), Rule-13 ROUND-2 finding F-B1R2-1 — the
  // RAIL-LADDER RE-VERIFICATION, and its slot is the whole soundness argument,
  // exactly as it is for P7 immediately below. `classifySelectRegion`'s §14.3
  // ladder (rung (ii) measured-before, rung (iii) the wire question) and
  // `classifyPhaseKickback`'s step 5b run inside `detectControlRegions`, i.e.
  // with ROUND-1 taint — while `lowerRotations` decides chained-vs-source with
  // FINAL taint (`Chained = taint.Tainted.count(arg0)`). `repropagateControlMerges`
  // re-seeds taint from the 6.5/4.5 `%out` rails, so in that window a
  // `cq_theta_i1` on an `%out`-derived seed is a SOURCE theta to both of the
  // ladder's closures and a CHAINED one to the lowering: its SIBLING then rides
  // the same physical rail and the emitted control read fires on a register the
  // sibling moved (a CONFIRMED silent miscompile, plain C through the two-TU 6.5
  // recipe, `opt` exit 0 / verify-clean / STRICT-stage-2b clean). Every emitter
  // that reads a rail as a control RECORDS `(rail, first read)` at its emission
  // site; this stage re-asks the SAME two rungs here, where the taint is final,
  // and declines LOUDLY. It must run AFTER the round-2 fixpoint (nothing else
  // makes the answer final) and BEFORE `lowerRotations` (which erases the
  // `cq_theta_i1` calls the record names). A no-op for every module that never
  // read a bare `_Bool` register as a control.
  reverifyRailCondReads(M, taint);
  // (Track A.1; bd test_C_libtooling-9pum) THE COMPARE HALF of the same stage,
  // in the same slot for the same reason — `y` in the 6.5 two-TU reproducer is
  // an `%out` derivative, classical at round 1 and tainted after the fixpoint,
  // so the two `cq_theta(y, ·)` siblings are two rails to the classifier and ONE
  // rail to `lowerRotations`. Immediately after its rail twin, not merged with
  // it: the compare record's rung (iii) is asked over the whole `condProvenance`
  // cone AT ONCE (`WireWalk::gateIsHarmless` grows its per-activation barriers
  // from the seed set it is handed), while a rail's is asked per rail.
  reverifyCmpCondReads(M, taint);
  // (bd `test_C_libtooling-xdu2.13`) THE LITERAL HALF, same slot, same reason: a
  // 4.4 condition node's classical `_hl` LITERAL was untainted at the classifier's
  // taint, and one derived from a 6.5/4.5 `%out` is quantum after the fixpoint —
  // a quantum value in a classical slot (Rule 3). Loud. The rule-(B) marks are
  // dropped immediately after: no classifier can ask again past this slot.
  declineQuantumCondLiterals(M, taint);
  // bd `test_C_libtooling-3jru` — THE refusal of a register returned across a
  // function boundary, and its slot is the argument. The call-return closure lives
  // in `propagateWorklist`, through which `propagate`, the round-2 reseed and
  // `propagateFromSeeds` drain — and a DIRECT `Tainted` insert of a fresh rail
  // over an untainted value drains through it only if registered in
  // `UntaintedMergeRails` (the IO-sink mux rail was not until Rule-13 round 5
  // F-R5-1; the complete list is at `propagateWorklist`) — so every stage above
  // sees such a call result as quantum AT THE TAINT OF ITS OWN ROUND; asking HERE, after the
  // round-2 fixpoint, (a) reads FINAL taint — round 2 can taint a callee's `ret`
  // through a 6.5/4.5 `%out` (CLAUDE.md L1; Rule-13 round 4 F-R4-1 measured round
  // 3's `propagate`-only closure missing exactly that) — and (b) leaves the owners
  // ABOVE this slot untouched: the specializer's `detectSpecializations`, the loop
  // layer, and `declineQuantumCondLiterals` just above keep their strings
  // (measured, TRACK_E §6d/§6e). ⚠ Owners BELOW it are PRE-EMPTED in a
  // multi-function module whose callee returns a register: `declineClassicalMuxes`
  // and everything after now see this string instead of theirs (round 4 P3-b —
  // e.g. reviewer probes a08, g03, g05, which the oracle declined as `tainted value
  // muxed by a classical-condition phi`). Both are declines; only the owner moved.
  declineQuantumReturnCalls(M, taint);
  stripPredMuxPredictedMarks(M);
  // (bd `test_C_libtooling-wx8g`) THE THIRD RE-ASK IN THIS SLOT, and it is about
  // a marking rather than a read: `ArmClassify`'s R7-loop clause (c) admitted an
  // ITERATION-LOCAL rotated register inside a rolled loop, and the per-trip
  // TEMPLATE rails that loop's body mints are discharged by the whole-DAG spine
  // ONLY inside `taint.IterationLocalBlocks`. `markIfRailLocal` populates that
  // set after the flatten at FINAL taint and can refuse — or never be asked —
  // for four reasons detection cannot see. Same placement rule as its two
  // neighbours: AFTER the round-2 fixpoint (nothing else makes the marking
  // final), BEFORE `lowerRotations` (which erases the `@cq_theta` the record
  // names). See `TaintPropagation.h`'s `RolledLoopRegionGates` for the measured
  // cost of getting this wrong (two entangled which-path rails leaked per
  // activation, `opt` exit 0 and stage-2b clean).
  declineUnmarkedRolledIterLocal(M, taint);
  // (bd `test_C_libtooling-fn1q` increment 1) THE FOURTH RE-ASK IN THIS SLOT, and
  // it is about a HOIST. `emitValueRegion` moved a value arm's CLASSICAL cone
  // into the pred on a ROUND-1 verdict that every member is untainted; the
  // round-2 re-seed from the 6.5/4.5 `%out` rails can falsify that, which would
  // leave a Q+Q chain link accepted under a Q+C premise — a shape `classifyArms`
  // DEFERS by design. Same placement rule as its three neighbours: AFTER the
  // fixpoint (nothing else makes the taint final), BEFORE `lowerRotations`.
  declineRound2TaintedArmCone(M, taint);

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
  // merge phi (`if (classical_c) q = cq_phi(q, θ); use(q)`) is RAUW'd to its
  // wire base and erased here instead of declined.
  // bd `test_C_libtooling-zujr` — THE TRIP-1 PROMOTION, immediately before the
  // guard whose accept it grants. Contract, slot and retirement trigger in
  // `LoopPlan.h`; it never declines, and an unpromoted carried-handle φ is
  // refused by the very next call.
  promoteLoopCarriedHandleSeeds(M, wd, taint);
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

  lowerRotations(M, wd, taint, &plan);
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
  auto onlyInF = [&F](auto &Calls) {
    Calls.erase(std::remove_if(Calls.begin(), Calls.end(),
                               [&F](CallInst *CI) {
                                 return CI->getFunction() != &F;
                               }),
                Calls.end());
  };
  onlyInF(taint.ThetaCalls);
  onlyInF(taint.PhiCalls);
  onlyInF(taint.PhaseCalls);
  onlyInF(taint.MeasureCalls);
  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty() &&
      taint.PhaseCalls.empty() && taint.MeasureCalls.empty())
    return false;

  // p119: by-ref math canonicalization removed (library functions, source-injected
  // not recognized) — see run(). Twin-pipeline parity preserved by the removal in
  // both entry points.

  // bd `xdu2` / L-1a clause C5 — the rail-bank per-activation promoter, mirrored
  // in this entry point too (twin-pipeline parity is MANDATORY, WI-1.12). See
  // run() for the contract, the completed pipeline, and — the part that must not be
  // separated from the call — the L1 SLOT ARGUMENT: this stage grows the taint
  // set, so it is sound ONLY because it runs above every stage that adjudicates
  // consumers of tainted values, `foldIdentityBitcasts` included.
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

  // bd 3c6m.55 Inc 2 (Lever B) — static-K force-unroll fixpoint, mirrored in
  // this entry point too (twin-pipeline parity is MANDATORY, WI-1.12) — see
  // run() for the post-fixpoints / pre-`detectSpecializations` placement
  // rationale and the nested PredMux re-run.
  while (unrollConstTripLoops(M, taint)) {
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.MeasureCalls);
    while (flattenPredMuxRegions(M, taint, /*claimAll=*/false, &railPhiRec)) {
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
    while (flattenPredMuxRegions(M, taint, /*claimAll=*/false, &railPhiRec)) {
      taint = propagate(M, wd);
      onlyInF(taint.ThetaCalls);
      onlyInF(taint.PhiCalls);
      onlyInF(taint.MeasureCalls);
    }
  }

  // bd `test_C_libtooling-woa0` — the re-ask, mirrored in this entry point too
  // (twin-pipeline parity is MANDATORY, WI-1.12). Same slot by the same
  // argument: after all three top-level PredMux fixpoints and before the first
  // stage that could inherit ownership of the decline. See run().
  if (declineConvertedRailPhiLeaves(railPhiRec))
    return false;
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
  // bd test_C_libtooling-b6ap — the MULTI-PHI MERGE PEEL mirrored in this entry
  // point too (twin-pipeline parity is MANDATORY, WI-1.12). See run() for the
  // slot rationale (after the PredMux fixpoint, immediately before
  // `detectControlRegions`) and for why it is called before EVERY
  // `detectControlRegions` in the tree — AND for why the peel's taint delta must
  // be adjudicated (bd b6ap F-B6-1). Twin-pipeline parity applies to the
  // adjudication exactly as it does to the peel: dropping it here would make this
  // entry point the one that ships the F-B6-1 miscompile.
  {
    SmallPtrSet<Value *, 32> PeelDelta;
    peelIndependentMergePhis(M, taint, &PeelDelta);
    adjudicateTaintDelta(M, wd, taint, plan6, PeelDelta);
  }

  ControlPlan plan = detectControlRegions(M, wd, taint);
  lowerControlRegions(M, wd, taint, plan);
  // Issue dugh (Phase 4×6): the SECOND propagation round mirrored in this entry
  // point too (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for the
  // pre-`lowerIOSinks`/`lowerQramReads`/`declineClassicalMuxes`/`lowerRotations`
  // ordering rationale.
  repropagateControlMerges(M, wd, taint, plan6);
  // bd test_C_libtooling-r9e5 (1b-B.1) mirrored in this entry point too
  // (twin-pipeline parity is MANDATORY, WI-1.12) — see run() for why the ONLY
  // sound slot is AFTER `repropagateControlMerges` (the round-2 fixpoint is what
  // makes the taint final) and BEFORE `lowerRotations` (which erases the
  // `cq_theta_i1` calls the record names).
  reverifyRailCondReads(M, taint);
  // (Track A.1; bd test_C_libtooling-9pum) the compare half, mirrored here too —
  // twin-pipeline parity is MANDATORY (WI-1.12); see run() for the slot argument.
  reverifyCmpCondReads(M, taint);
  // (bd `test_C_libtooling-xdu2.13`) the literal half + the mark drop, mirrored.
  declineQuantumCondLiterals(M, taint);
  // bd `test_C_libtooling-3jru` — THE refusal of a register returned across a
  // function boundary, and its slot is the argument. The call-return closure lives
  // in `propagateWorklist`, through which `propagate`, the round-2 reseed and
  // `propagateFromSeeds` drain — and a DIRECT `Tainted` insert of a fresh rail
  // over an untainted value drains through it only if registered in
  // `UntaintedMergeRails` (the IO-sink mux rail was not until Rule-13 round 5
  // F-R5-1; the complete list is at `propagateWorklist`) — so every stage above
  // sees such a call result as quantum AT THE TAINT OF ITS OWN ROUND; asking HERE, after the
  // round-2 fixpoint, (a) reads FINAL taint — round 2 can taint a callee's `ret`
  // through a 6.5/4.5 `%out` (CLAUDE.md L1; Rule-13 round 4 F-R4-1 measured round
  // 3's `propagate`-only closure missing exactly that) — and (b) leaves the owners
  // ABOVE this slot untouched: the specializer's `detectSpecializations`, the loop
  // layer, and `declineQuantumCondLiterals` just above keep their strings
  // (measured, TRACK_E §6d/§6e). ⚠ Owners BELOW it are PRE-EMPTED in a
  // multi-function module whose callee returns a register: `declineClassicalMuxes`
  // and everything after now see this string instead of theirs (round 4 P3-b —
  // e.g. reviewer probes a08, g03, g05, which the oracle declined as `tainted value
  // muxed by a classical-condition phi`). Both are declines; only the owner moved.
  declineQuantumReturnCalls(M, taint);
  stripPredMuxPredictedMarks(M);
  // (bd `test_C_libtooling-wx8g`) THE THIRD RE-ASK IN THIS SLOT, and it is about
  // a marking rather than a read: `ArmClassify`'s R7-loop clause (c) admitted an
  // ITERATION-LOCAL rotated register inside a rolled loop, and the per-trip
  // TEMPLATE rails that loop's body mints are discharged by the whole-DAG spine
  // ONLY inside `taint.IterationLocalBlocks`. `markIfRailLocal` populates that
  // set after the flatten at FINAL taint and can refuse — or never be asked —
  // for four reasons detection cannot see. Same placement rule as its two
  // neighbours: AFTER the round-2 fixpoint (nothing else makes the marking
  // final), BEFORE `lowerRotations` (which erases the `@cq_theta` the record
  // names). See `TaintPropagation.h`'s `RolledLoopRegionGates` for the measured
  // cost of getting this wrong (two entangled which-path rails leaked per
  // activation, `opt` exit 0 and stage-2b clean).
  declineUnmarkedRolledIterLocal(M, taint);
  // (bd `test_C_libtooling-fn1q` increment 1) THE FOURTH RE-ASK IN THIS SLOT, and
  // it is about a HOIST. `emitValueRegion` moved a value arm's CLASSICAL cone
  // into the pred on a ROUND-1 verdict that every member is untainted; the
  // round-2 re-seed from the 6.5/4.5 `%out` rails can falsify that, which would
  // leave a Q+Q chain link accepted under a Q+C premise — a shape `classifyArms`
  // DEFERS by design. Same placement rule as its three neighbours: AFTER the
  // fixpoint (nothing else makes the taint final), BEFORE `lowerRotations`.
  declineRound2TaintedArmCone(M, taint);
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
  // Post-lift stale-record re-check (test_C_libtooling-2qyz) — see run().
  declineLiftedStaleRecordOps(M, taint);
  // Phase 6 specialization driver (step 14) — mirrored from run() (twin-pipeline
  // parity, WI-1.12).
  specialize(M, wd, taint, plan6);
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

  lowerRotations(M, wd, taint, &plan);
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
  // bd xy9n — mirrored from `run()` (twin-pipeline parity, WI-1.12): miss it and
  // a unit-level caller silently keeps the pairing break. See run() for why this
  // position is the complete one, and for why the bool is consumed.
  if (declineUnpairedUndefLiterals(M))
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
  return true;
}

}  // namespace cq
