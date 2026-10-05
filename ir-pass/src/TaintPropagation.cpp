// TaintPropagation.cpp — Forward taint propagation from quantum rotation
// returns. The source set spans every `@cq_theta_<sfx>` declared in the
// module (14-suffix enumeration via `WidthDispatch::allSuffixes()`); the
// register-free `@cq_phi` is collected but is not a source (a use of the retired
// `@cq_phi_<sfx>` is a reserved-name decline); `@cq_measure_<sfx>` is the sink.
// Propagation rules are unchanged from the original source-collection version —
// only the source predicate moved to the `@cq_theta_<sfx>` rotation family.

#include "TaintPropagation.h"

#include "ControlPlan.h"      // diagnoseUnderControl (dugh re-classified control)
#include "IntrinsicLowering.h"
#include "OpcodeLowering.h"   // declineStaleRecordOps (dugh second-round re-sweep)
#include "QramLowering.h"
#include "RailBankPromote.h"  // railBankOfPointer / isRailBankAlloca / the W1 second half
#include "RotationLowering.h"  // normalizeUndefRotationSeed (bd z9t1)
#include "SpecializeClone.h"    // specCallResultPredictedClassical (bd cepm / 3zr4)
#include "SpecializeDetect.h"   // detectSpecializations (9paa round-2 re-detection)
#include "SpecializePlan.h"
#include "SpecializeReject.h"  // classifyCandidate / diagnoseReject (0vvq Inc 2 re-plan)
#include "Specialization.h"
#include "LoopPlan.h"          // collapseFlattenedLoopRails (F-R1-1 onward pass)
#include "MergePhiPeel.h"     // peelIndependentMergePhis (bd b6ap, ROUND-2 site)
#include "ReturnMerge.h"      // unifyTaintedReturns (bd dm7f.5, ROUND-2 site)
#include "SwapRouteEmit.h"     // lowerControlRegions (yn71 onward-control re-emit)
#include "WidthDispatch.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/Triple.h"

#include <algorithm>
#include <optional>
#include <string>
#include <vector>

using namespace llvm;

namespace cq {

namespace {

// Set of front-end intrinsic Function*s. `SmallPtrSet` because membership
// lookups happen once per CallInst during the BB walk; pointer-keyed and
// small (≤14 thetas, ≤14 phis, ≤14 measures) makes it a perfect fit.
using FnSet = SmallPtrSet<Function *, 16>;

// Loud decline for a front-end intrinsic reached via `invoke` instead of a
// direct `call` (test_C_libtooling-rzs9). The 42-name surface is opaque
// externs that clang -O1 on exception-free C always reaches with a plain
// `call`; an `invoke` is a TERMINATOR with normal + unwind successors, and
// every lowering stage (RotationLowering / MeasureLowering / Uncomputation)
// inserts plain CallInsts at the call position and RAUWs the result —
// terminator surgery the pipeline has no story for. Declining loudly is the
// move until that story exists (an over-decline to remove, R1, not a safe
// margin): silently dropping it
// (the historical `dyn_cast<CallInst>` gap) treated an invoke'd theta's result
// as CLASSICAL — a verify-clean UNDER-taint — and left the `@cq_*` extern to a
// Stage-3 LINK error. Source-located via the invoke's `!dbg`; the negative
// fixtures mirror the rendered message character-for-character (Rule 12):
//   * lowering_reject_intrinsic_invoke_theta.ll
//   * lowering_reject_intrinsic_invoke_phi.ll
//   * lowering_reject_intrinsic_invoke_measure.ll
void diagnoseIntrinsicInvoke(CallBase *CB, const Function *Callee) {
  std::string Msg =
      (Twine("cq taint propagation: front-end intrinsic ") + Callee->getName() +
       " reached via invoke; only a direct call is supported")
          .str();
  CB->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *CB->getFunction(), Msg, CB->getDebugLoc()));
}

// Per-function pass: collect theta/phi/measure call sites in BB order and
// seed the propagation work-list with theta RESULT SSA values. Iterating
// per-function (rather than via `F->users()`) preserves the BB-order
// semantics — `RotationLowering` assigns `BirthOrder` to alloc handles in
// this same order, which `OpcodeLowering` reads back for stable Q+Q operand
// canonicalization. Phi calls are collected unconditionally but NOT seeded:
// a phi propagates taint through a tainted operand (reached as an ordinary
// user) but never introduces it, and a phi on a classical operand must
// still be collected so the lowering can delete it.
void collectAndSeed(Function &F, const FnSet &ThetaFns, const FnSet &PhiFns,
                    const FnSet &MeasureFns, const Function *PhaseFn,
                    TaintSet &out, std::vector<Value *> &Worklist) {
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      // ── bd `xdu2` / L-1a W1 PIECE 1 — A RAIL-BANK CELL LOAD IS TAINTED.
      //
      // Taint is otherwise SSA-only (`propagateWorklist` has no load/store
      // rule), which is exactly why a bank cell needs a rule of its own: the
      // rail's NAME is parked in memory between the write loop and the read,
      // and a `cq_measure` of an UNTAINTED load takes `MeasureLowering`'s
      // classical split and emits NO GATE, NO SYMBOL AND NO TRACE LINE — a
      // silent miscompile a golden byte-diff structurally cannot see
      // (reproduced with a trace: `trackB/IMPL_B2.md` §1).
      //
      // ⚠ THE PROOF IS THE `!cq.railbank` RECORD AND NOTHING ELSE, and the
      // record is minted ONLY for a `RailBankCarve::Bank` bank
      // (`markRailBankAllocas`). On a `BankRaw` bank the surviving in-loop read
      // is the PARTIALLY AVAILABLE one and tainting it is the hazard clause C7
      // exists to separate (`trackA/SIGNATURE.md` §4 item 2).
      //
      // ⚠ SITTING HERE — inside `collectAndSeed`, i.e. inside `propagate` — is
      // what discharges the L1 round-2 obligation STRUCTURALLY rather than by a
      // record, the same argument bd `z9t1`'s seed clause makes two screens
      // below: `propagate` is the single funnel BOTH entry points and every
      // re-propagation fixpoint come through, so there is no second call site
      // to forget. The record itself is minted by a stage that runs ABOVE every
      // taint-consuming guard and whose caller re-`propagate`s from scratch, so
      // the taint GROWTH it causes owes no `adjudicateTaintDelta` either.
      //
      // ⚠ RETIREMENT TRIGGER: the day taint stops being SSA-only for any other
      // reason, re-derive which of `declineTaintEscapes`' arms a bank load now
      // reaches. Today it reaches NONE — `readsTaintedValue` is false for a load
      // whose POINTER is classical, so a tainted load is not an escape; its
      // CONSUMERS are, and they are adjudicated by the D5 allow-list
      // (`declineUnallowedRailBankReaders`).
      if (auto *LD = dyn_cast<LoadInst>(&I)) {
        if (railBankOfPointer(LD->getPointerOperand()) &&
            out.Tainted.insert(LD).second)
          Worklist.push_back(LD);
        continue;
      }
      // CallBase (not CallInst) so an `invoke` of a front-end intrinsic is
      // SEEN here — the historical seeding gap (test_C_libtooling-rzs9):
      // `dyn_cast<CallInst>` returns null on an InvokeInst, so an invoke'd
      // theta was never seeded as a source and an invoke'd measure never
      // recognized as a sink.
      auto *CB = dyn_cast<CallBase>(&I);
      if (!CB)
        continue;
      Function *Callee = CB->getCalledFunction();
      if (!Callee)
        continue;
      // A conditional runtime-i32 rail-bank preparation needs a real |0> rail
      // on its skipped path. Keep that preallocated handle OUT of ordinary SSA
      // propagation until rotation lowering: detection must classify the theta
      // as a fresh state preparation, not as an in-place rewrite of a register
      // the source supplied. The emitter proved its only role is the theta seed
      // plus the faithful merge incoming; `lowerRotations` adopts the handle
      // into `Tainted` before replacing the theta. Record only the stable width
      // and birth identity here. Exact recognition lives with the emitter.
      if (auto *CI = dyn_cast<CallInst>(CB); isRailBankSeedAlloc(CI)) {
        out.HandleWidth[CI] = "i32";
        out.BirthOrder[CI] = out.NextBirth++;
        continue;
      }
      const bool IsTheta = ThetaFns.contains(Callee);
      const bool IsPhi = PhiFns.contains(Callee);
      const bool IsMeasure = MeasureFns.contains(Callee);
      // bd test_C_libtooling-3qlq Inc 1 — the register-free branch phase,
      // recognized by EXACT Function identity (`wd.phaseFn()`, i.e. the name
      // `cq_phi` with the prototype `void(double)`; a mismatched prototype was
      // already declined and NOT resolved, so `PhaseFn` is null there and the
      // call falls through to the ordinary unknown-callee treatment).
      const bool IsPhase = PhaseFn && Callee == PhaseFn;
      if (!IsTheta && !IsPhi && !IsMeasure && !IsPhase)
        continue;
      // A front-end intrinsic reached via `invoke` (any non-`call` CallBase) is
      // an off-pattern shape the call-position lowering cannot rewrite — decline
      // LOUDLY (diagnoseIntrinsicInvoke) and record the site so the escape guard
      // does not re-flag a tainted arg-0 as an "unknown callee". Lower nothing:
      // the call is NOT collected into any work list.
      auto *CI = dyn_cast<CallInst>(CB);
      if (!CI) {
        diagnoseIntrinsicInvoke(CB, Callee);
        out.IntrinsicInvokes.insert(CB);
        continue;
      }
      if (IsTheta) {
        // bd z9t1 (owner ruling 2026-09-14) — THE UNDEF SEED IS A ZERO AT THE
        // ALLOCATION, and this is the ONE call site.
        //
        // An `undef`/`poison` arg-0 of a SOURCE theta is rewritten to a concrete
        // zero of that type (and so is the same uninitialized object's other
        // read, the `undef` incoming of a phi that merges this theta's result).
        // SILENT by ruling — no diagnostic, no warning, exit 0.
        //
        // *** THE PLACEMENT IS THE RULING'S CLAUSE 2, NOT A CONVENIENCE. *** It
        // must run EARLY, BEFORE classification, so F1/F2 and every downstream
        // fence see a concrete `0`: normalizing at the emission site
        // (`lowerRotations`) is measurably WRONG, because the in-region spelling
        // `bool b; if (c) cq_theta(&b,.5);` dies ~500 lines earlier at F1's
        // `state prep seed does not match the merge incoming`.
        //
        // Sitting HERE — inside `collectAndSeed`, i.e. inside `propagate` — is
        // what discharges the L1 round-2 obligation STRUCTURALLY rather than by
        // a record: `propagate` is the single funnel BOTH entry points and every
        // re-propagate fixpoint round come through, so a theta minted between
        // the rounds (`SpecializeClone` substituting an `undef` actual argument,
        // `LoopUnrollPrepass` duplicating) is re-normalized at that fixpoint's
        // own `taint = propagate(M, wd)`. There is no second call site to
        // forget. The full argument, the refinement ground, the
        // `ConstantExpr` residual and the phi rule's scope are at the definition
        // (`RotationLowering.cpp`).
        //
        // ⚠ THAT DISCHARGE IS THE SEED HALF'S. The PHI half is ONE-SHOT — the
        // callee early-returns once the seed is concrete, so its phi loop is
        // UNREACHABLE at every round after the first (review round 3, F-U3-4).
        // It is safe for three MEASURED reasons, not a structural one, and each
        // carries a retirement trigger at the definition. Do not quote this call
        // site as covering the phi half.
        //
        // ⚠ THE ASYMMETRY WITH `cq_measure` IS PRINCIPLED AND IS RULED (clause
        // 4): `cq_measure` of a never-quantum `undef` KEEPS DECLINING (bd 21mg,
        // `lowering_reject_measure_undef_operand.ll`). There is no allocation,
        // no register and nothing quantum there for the rule to attach to — it
        // is a classical read of an indeterminate object, so a zero would be an
        // invented ANSWER rather than a chosen starting basis state.
        //
        // ⚠ MEASURED CONSEQUENCE, OPEN DISPOSITION (review round 1, F-U1-1):
        // when THIS call's ANGLE also carries an undef, the rewrite removes one
        // of the TWO slots `declineUnpairedUndefLiterals` was counting, so a
        // module the ORACLE declined compiles silently with an `undef` rotation
        // angle. No conjunct is added here — whether that decline was a real
        // pairing break or a uniquing coincidence is an owner ruling. See
        // `RotationLowering.cpp`'s F-U1-1 paragraph.
        normalizeUndefRotationSeed(CI);
        out.ThetaCalls.push_back(CI);
        if (out.Tainted.insert(CI).second)
          Worklist.push_back(CI);
      } else if (IsPhi) {
        // UNREACHABLE since bd test_C_libtooling-3qlq Inc 1: `PhiFns` is
        // always empty (`resolveSources` no longer resolves the retired
        // `@cq_phi_<sfx>` family). Kept so the vacuity is visible here rather
        // than only in the resolver — see TaintPropagation.h on `PhiCalls`.
        out.PhiCalls.push_back(CI);
      } else if (IsPhase) {
        // NOT a source (no taint seeded) and NOT a propagator (no data
        // operand) — it is ordered by its BLOCK, not by taint (D1).
        out.PhaseCalls.push_back(CI);
      } else {  // IsMeasure
        out.MeasureCalls.push_back(CI);
      }
    }
  }
}

// Is `I` a taint sink? Any front-end `@cq_measure_<sfx>` intrinsic in
// `MeasureFns` and the runtime lowering targets `@cqrt_measure_<W>` stop
// propagation. The runtime-name check is defensive: at propagation time
// only `@cq_measure_<sfx>` exists in the IR, but accepting both keeps the
// rule honest if a future re-entrant pass invokes propagation after
// measure lowering. The `cqrt_measure_` prefix match covers all 7 ABI
// widths uniformly (i1, i8, i16, i32, i64, f32, f64).
//
// CallBase (not CallInst) so an `invoke`'d @cq_measure is still recognized as a
// sink (test_C_libtooling-rzs9). Under `opt` an invoke'd intrinsic already
// declined at collection (collectAndSeed), but in any host that continues past
// that DS_Error this keeps the sink predicate honest — otherwise taint would
// over-propagate THROUGH the measure into its result.
bool isMeasureSink(Instruction *I, const FnSet &MeasureFns) {
  auto *CB = dyn_cast<CallBase>(I);
  if (!CB)
    return false;
  Function *Callee = CB->getCalledFunction();
  if (!Callee)
    return false;
  if (MeasureFns.contains(Callee))
    return true;
  return Callee->getName().starts_with("cqrt_measure_");
}

// ── Declared-prototype validation (test_C_libtooling-pn2) ───────────────────
// The 42-name front-end surface is resolved BY NAME ONLY (`M.getFunction`);
// nothing downstream ever re-checks the declared TYPE. A user declaration
// carrying a reserved name with the wrong prototype therefore drives the
// lowering into minting a mistyped replacement — loud (the final verifier
// aborts: Broken module, opt exit 134) but NOT the pass's source-located
// DiagnosticInfoUnsupported dialect, and for a theta/phi MISSING its angle
// parameter the `getArgOperand(1)` read is out of range on a no-assert LLVM
// (the CALLEE OPERAND leaks into the emitted cqrt_ry as its "angle";
// verified 2026-06-10 on all five probe shapes: measure wrong-return, theta
// wrong-arg/missing-angle, phi wrong-angle/wrong-return). So each resolved
// decl is validated HERE, at collection time — both pipeline entry points
// (run / runOnFunction) come through propagate(), so the guard cannot be
// bypassed (twin-pipeline trap, IMPLEMENTATION §6.5).
//
// Canonical prototype per suffix (CQ.h, with T = WidthDispatch::llvmTypeFor):
//   cq_theta_<sfx>: T (T, double)   cq_measure_<sfx>: T (T)   cq_phi: void(double)
// Exact FunctionType match — no varargs, no extra params. Parameter
// ATTRIBUTES (zeroext/noundef/...) are not part of the FunctionType and are
// accepted, so every clang-emitted CQ.h decl passes.
bool declMatchesPrototype(const Function *F, Type *T, bool HasAngle) {
  FunctionType *FT = F->getFunctionType();
  if (!T || FT->isVarArg() || FT->getReturnType() != T)
    return false;
  if (FT->getNumParams() != (HasAngle ? 2u : 1u) || FT->getParamType(0) != T)
    return false;
  return !HasAngle || FT->getParamType(1)->isDoubleTy();
}

// Loud decline for a malformed reserved-name declaration, in the owning
// concern's diagnostic dialect (`Concern` = "cq rotation lowering" for
// theta/phi, "cq measure lowering" for measure). Prefers the first call site
// (use-list order) for the function context and `!dbg` source location; a
// decl-only mismatch diagnoses on the declaration itself. The negative
// fixtures mirror each rendered message CHARACTER-FOR-CHARACTER (Rule 12):
//   * lowering_reject_decl_prototype_theta.ll   → "... for cq_theta_si32"
//   * lowering_reject_decl_prototype_phi.ll     → "... for cq_phi"
//   * lowering_reject_decl_prototype_measure.ll → "... for cq_measure_f64"
//   * lowering_reject_decl_prototype_unused.ll  → decl-only, no call sites
//   * lowering_reject_decl_prototype_invoke.ll  → invoke-only call site (thd7)
void diagnoseMalformedDecl(Function *F, StringRef Concern) {
  std::string Msg = (Twine(Concern) + ": unsupported declared prototype for " +
                     F->getName())
                        .str();
  for (User *U : F->users()) {
    // CallBase (not CallInst) so an `invoke`'d call site still supplies the
    // function context + `!dbg` source location (test_C_libtooling-thd7) —
    // `dyn_cast<CallInst>` returns null on an InvokeInst, so an invoke-only
    // malformed decl fell through to the decl-level diagnostic below (still
    // LOUD, just without source-line precision). Same CallInst→CallBase
    // generalization rzs9 applied to collectAndSeed / isMeasureSink.
    auto *CB = dyn_cast<CallBase>(U);
    if (!CB || CB->getCalledFunction() != F)
      continue;
    CB->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
        *CB->getFunction(), Msg, CB->getDebugLoc()));
    return;
  }
  F->getContext().diagnose(DiagnosticInfoUnsupported(*F, Msg));
}

// Resolve every declared `@cq_theta_<sfx>` / `@cq_measure_<sfx>` and the
// register-free `@cq_phi` (`PhiFns` stays empty). Suffixes whose intrinsic isn't
// declared in `M` are skipped — that's the early-out cue the per-function
// walk uses to leave a purely-classical module untouched. Order doesn't
// matter: `collectAndSeed` walks call sites in BB order, not symbol order.
//
// Every resolved decl is prototype-validated; a mismatch declines loudly and
// is NOT inserted (so no later stage builds a mistyped replacement from it —
// for an in-process host that continues past the DS_Error, its calls become
// opaque externs adjudicated by the taint-escape guard; under `opt` the
// first DS_Error already exited). DELIBERATE passthrough-boundary choice
// (pinned by lowering_reject_decl_prototype_unused.ll): the decline fires
// even for a decl with NO call sites — the 42 names are RESERVED by
// convention (cf. FreePoint's `cq_invert_` prefix escapes), a wrong-typed
// declaration of one is a user error whether or not it is currently called,
// and gating on "has calls" would make the diagnostic depend on DCE
// happenstance (where the declaration is otherwise a valid program, this is a
// loud over-decline to remove under R1, not a safe margin). An
// UNRECOGNIZED suffix (e.g. `cq_measure_xyz999`) is NOT in the 42-name
// surface and stays out of collection — and validation — entirely.
void resolveSources(WidthDispatch &wd, FnSet &ThetaFns, FnSet &PhiFns,
                    FnSet &MeasureFns, Function *&PhaseFn) {
  // bd test_C_libtooling-3qlq Inc 1 (owner decision D1) — the REGISTER-FREE
  // branch phase `void @cq_phi(double)`, resolved by EXACT name.
  //
  // ⚠ THE RETIRED `@cq_phi_<sfx>` FAMILY IS DELIBERATELY *NOT* RESOLVED HERE
  // ANY MORE, and that is the whole surface change on this side (PRD §4.1).
  // `CQ.h` no longer declares it, so an old-spelling call can only come from
  // hand-written IR or a stale header — and it must not keep lowering to the
  // TENSORED `cqrt_rz_<W>` that made every Grover golden the identity on `q`
  // (PRD §1). Left unresolved, `@cq_phi_si32(%q, θ)` is an ordinary unknown
  // external consuming a tainted value and declines LOUDLY through
  // `declineTaintEscapes` with `cq taint escape: tainted value consumed by an
  // unknown callee` (pinned: `lowering_reject_legacy_phi_register_form.ll`).
  // `PhiFns` stays in the signature, permanently empty — see
  // TaintPropagation.h on `PhiCalls` for why the readers are left vacuous
  // rather than deleted.
  //
  // The prototype is validated exactly as the 48 suffixed names are, in the
  // same "cq rotation lowering" dialect and on the same
  // RESERVED-whether-or-not-called rule: a `@cq_phi` with the wrong
  // prototype would otherwise drive a `getArgOperand(0)` read of something
  // that is not the angle (pinned: `lowering_reject_decl_prototype_phi.ll`).
  PhaseFn = nullptr;
  if (Function *F = wd.phaseFn()) {
    FunctionType *FT = F->getFunctionType();
    if (!FT->isVarArg() && FT->getReturnType()->isVoidTy() &&
        FT->getNumParams() == 1 && FT->getParamType(0)->isDoubleTy())
      PhaseFn = F;
    else
      diagnoseMalformedDecl(F, "cq rotation lowering");
  }

  for (StringRef Sfx : wd.allSuffixes()) {
    // ---- THE RETIRED REGISTER FORM `@cq_phi_<sfx>` IS A RESERVED NAME AND ANY
    // USE OF IT DECLINES — bd 3qlq Inc 1 part A, Rule-13 round-1 finding F-L6-1
    // (a CONFIRMED Rule-1 "third path" violation).
    //
    // The comment above says the family "declines LOUDLY through
    // `declineTaintEscapes`". MEASURED, that is true of THREE spellings and
    // FALSE of the fourth — and the fourth is the FLAGSHIP CUSTOMER. On a stale
    // header, `if (q == 5) q = cq_phi(q, PI)` has its arg 0 CONST-FOLDED by
    // `clang -O1` to `i32 5` on the equality edge (the drbq Inc-4 F2 fold
    // class), so the operand is CLASSICAL and the escape guard structurally
    // cannot fire. Meanwhile `ArmClassify::isPhiCall` still recognises the call
    // by the `cq_phi_` PREFIX and CLAIMS it as an arm gate,
    // `emitInPlaceRotationRegion` hoists it and records
    // `taint.ControlledRotations`, and the `PhiCalls` loop in `RotationLowering`
    // that used to lower it is DELETED. Result at HEAD: `opt` exit 0,
    // verify-clean, STRICT stage 2b PASS, the flag minted and stripped and
    // freed, THE PHASE GATE DROPPED (the identity on `q` — PRD §1's own defect
    // class, through a different door), and `@cq_phi_si32` left UNLOWERED in the
    // emitted module. Caught only by `ld`. It is one linkable body away from
    // being silent.
    //
    // MONOTONE — this clause can only ADD declines. It is gated on `!use_empty`
    // rather than on the declaration alone, and that is a DELIBERATE narrowing
    // of the reserved-name rule the other 33 names follow (`resolveSources`'
    // header: "even for a decl with NO call sites"): a declare-only retired
    // symbol is provably inert (measured — with quantum in the module the dead
    // decl is swept; with none the pass is byte-identical passthrough), while
    // the ~490 fixtures still carrying the old family are mid-migration and a
    // decl-only decline would redden every one of them for no correctness gain.
    // A USE is exactly the set that can reach a wrong unitary.
    //
    // NOT a prototype complaint, so it does not reuse `diagnoseMalformedDecl`'s
    // string: the declaration here is perfectly well-formed and the objection is
    // that the SPELLING is retired. It has its own message, mirrored
    // character-for-character by
    // `lowering_reject_legacy_phi_register_form_eqfold.ll`.
    if (Function *F = wd.phiFn(Sfx)) {
      if (!F->use_empty()) {
        std::string Msg =
            ("cq rotation lowering: retired register-form " + F->getName() +
             "; use the register-free void cq_phi(double)")
                .str();
        Function *At = F;
        DebugLoc DL;
        for (User *U : F->users())
          if (auto *CB = dyn_cast<CallBase>(U))
            if (CB->getCalledFunction() == F) {
              At = CB->getFunction();
              DL = CB->getDebugLoc();
              break;
            }
        At->getContext().diagnose(
            DiagnosticInfoUnsupported(*At, Msg, DL));
      }
    }
    if (Function *F = wd.thetaFn(Sfx)) {
      if (declMatchesPrototype(F, wd.llvmTypeFor(Sfx, F->getContext()),
                               /*HasAngle=*/true))
        ThetaFns.insert(F);
      else
        diagnoseMalformedDecl(F, "cq rotation lowering");
    }
    if (Function *F = wd.measureFn(Sfx)) {
      if (declMatchesPrototype(F, wd.llvmTypeFor(Sfx, F->getContext()),
                               /*HasAngle=*/false))
        MeasureFns.insert(F);
      else
        diagnoseMalformedDecl(F, "cq measure lowering");
    }
  }
}

// Shared forward-taint work-list loop (extracted for reuse by both the initial
// `propagate` and the dugh second round `repropagateControlMerges`). Each tainted
// SSA value's user instructions become tainted, except measure sinks, the
// arg-1 angle edge of a rotation, and (bd cepm / 3zr4) the RESULT of a would-be
// Phase-6 site whose lifted callee is predicted to return a classical value
// (`specCallResultPredictedClassical`, SpecializeClone.h). The work-list
// discipline (insert-then-push) processes each value exactly once.
//
// `skipRuntimeCalls` is set ONLY by the dugh second round: at that point the IR
// already carries the control emitter's own `cqrt_*` / `cq_template_*`
// scaffolding (the controlled-copy calls whose dst arg IS the seed `%out`), which
// is NOT user data flow — never re-taint it (so `uncompute` treats a re-seeded
// merge out-rail exactly as it treats a tainted-merge one) nor recurse through it.
// At first `propagate` time no such runtime calls exist, so the flag is false and
// this is a pure no-op there.
//
// bd cepm round 1b: the drain itself is `drainWorklist`; `propagateWorklist`
// (below) wraps it with the drain-generation count and the SETTLE step.
void drainWorklist(std::vector<Value *> &Worklist, const FnSet &ThetaFns,
                   const FnSet &PhiFns, const FnSet &MeasureFns,
                   TaintSet &out, bool skipRuntimeCalls) {
  while (!Worklist.empty()) {
    Value *V = Worklist.back();
    Worklist.pop_back();
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        continue;
      if (isMeasureSink(I, MeasureFns))
        continue;
      // WP10/R9 angle taint-discipline: the angle operand (arg 1) of a
      // cq_theta is a classical scalar, never a quantum handle. If `V`
      // reaches a rotation ONLY as its angle (arg 1) and not as the arg-0
      // handle, do NOT propagate taint through that edge — an angle-derived
      // value (e.g. an `if(q){rz(u,a)}else{rz(u,b)}` angle select) must stay
      // classical so it lowers as a rotation-angle choice, not quantum data.
      // Excluding only the arg-1 operand-use (not `V` globally) keeps a value
      // that is ALSO used as a handle elsewhere tainted (risk R9).
      if (auto *CI = dyn_cast<CallInst>(I)) {
        Function *Callee = CI->getCalledFunction();
        if (Callee && (ThetaFns.contains(Callee) || PhiFns.contains(Callee)) &&
            CI->arg_size() >= 2 && CI->getArgOperand(1) == V &&
            CI->getArgOperand(0) != V)
          continue;  // V is used here only as the classical angle; skip edge.
        // dugh: an already-lowered runtime primitive (the control emitter's own
        // cqrt_copy_<W>_controlled / flag scaffolding on the seed rail) is not
        // user data flow — never re-taint / recurse (uncompute parity).
        if (skipRuntimeCalls && Callee) {
          StringRef N = Callee->getName();
          if (N.starts_with("cqrt_") || N.starts_with("cq_template_"))
            continue;
        }
        // bd `test_C_libtooling-cepm` / bd `test_C_libtooling-3zr4` — a
        // would-be Phase-6 site whose lifted callee PROVABLY returns a
        // classical value (`predictReturnTainted` false for the mask this
        // drain sees) does NOT taint its RESULT. Before this, every such
        // result was tainted CONSERVATIVELY and only `specialize()` — after
        // both control rounds — scrubbed it, so a round-1 emitter had already
        // read the integer as a register and bd l3oi's fence declined a
        // program the hand-inlined twin compiles (cepm: `t = h(q, m); if (t >
        // 3)`), and a round-1 site reading a round-2 site's result was cloned
        // from a mask the scrub then falsified (3zr4). The call is NOT marked
        // visited: a later drain that taints another argument reaches it again
        // as that argument's user and re-asks with the grown mask (the
        // predictor is monotone), and the 3jru return crossing below inserts
        // it directly whatever this says. The two backstops (a loud decline in
        // `specialize()` if the clone returns a register after all; the
        // escape guard for a site that never becomes `Pending`) are in
        // SpecializeClone.h.
        //
        // ⚠ ROUND 1b — THE STICKY RULE. "Re-asks with the grown mask" is right
        // only WITHIN one drain. A site an EARLIER-generation drain left
        // classical has since been read as an integer by whatever ran in
        // between (lowerLoops, both control rounds …); tainting it now — in
        // ROUND 2 — was measured to accept programs the oracle declines and
        // whose streams are not the hand-inlined twin's (TRACK_CEPM_3ZR4.md
        // §5.2.1, battery `r2b`/`r2d`). So a later drain NEVER taints it: its
        // result stays classical, `replanReseedSpecialization` grows its
        // Pending mask, and if the clone then returns a register
        // `specialize()` declines loudly (`kMsgPredictedClassicalQuantum`).
        // The SETTLE step (`settleSpecPredictions`) is what keeps the known
        // growth patterns from reaching this: it taints such a site in the
        // drain that recorded it, as the oracle did.
        const bool Recorded = out.SpecPredictedClassical.count(CI) != 0;
        if (Recorded && out.SpecPredictedClassical.lookup(CI) <
                            out.SpecPredictGeneration)
          continue;
        if (specCallResultPredictedClassical(*CI, out)) {
          if (!Recorded)
            out.SpecPredictedClassical[CI] = out.SpecPredictGeneration;
          continue;
        }
        // Tainted below: a record of THIS generation (a smaller mask seen
        // earlier in this drain) is no longer a prediction.
        if (Recorded)
          out.SpecPredictedClassical.erase(CI);
      }
      if (out.Tainted.insert(I).second) {
        Worklist.push_back(I);
        // bd `test_C_libtooling-3jru` — TAINT CROSSES A CALL RETURN, and it does
        // so HERE, in the propagation drain (`propagate`, the round-2 reseed in
        // `repropagateControlMerges` and its onward-control fixpoint,
        // `propagateFromSeeds` for `MergePhiPeel` / `adjudicateTaintDelta`) — Rule
        // 14, one owner. ⚠ A value inserted into `Tainted` DIRECTLY does NOT go
        // through here, and "every grower drains through this" was FALSE until
        // Rule-13 round 5 F-R5-1: the IO-sink mux rail (`IOSinkLowering` 7c')
        // replaced an UNTAINTED φ and was never re-seeded. The complete list of
        // direct inserts of a FRESH value over an UNTAINTED one is: the 6.5
        // `ClassicalCallArmEmit` `%out`, the 4.5 `SwitchDataMuxEmit` `%out`, the
        // IO-sink `MuxOut`, the 7.4 break escape register `cq.brk.esc.out`
        // (`emitBreakForward` E16, bd 8h7d.17; minted in `lowerLoops`, so BEFORE
        // round-1 detection) (all four registered in `UntaintedMergeRails`, which
        // `repropagateControlMerges` drains through here), and `MergePhiPeel`'s
        // clone/select (drained via `propagateFromSeeds`). Every other direct
        // insert replaces an already-tainted value or is scaffold with no reader
        // (TRACK_E_xdu2_13.md §6f). A NEW such site must join one of those two
        // routes, or this closure — and every guard — cannot see it. A tainted `ret` means its DEFINED function returns
        // a quantum register's HANDLE, so every DIRECT call site of that function
        // is quantum in its caller and joins the worklist; chains (g→h) and
        // recursion close by the worklist itself. (Round 3 put this as a separate
        // fixpoint loop in `propagate` only; Rule-13 round 4 F-R4-1 measured the
        // round-2 reseed missing it — a `ret` of a 6.5 merge `%out` left its call
        // site classical at FINAL taint, and a literal carrying the handle id passed
        // `declineQuantumCondLiterals`.) The consumers are refused loudly by
        // `declineQuantumReturnCalls`.
        if (auto *Ret = dyn_cast<ReturnInst>(I)) {
          Function *F = Ret->getFunction();
          for (User *FU : F->users()) {
            auto *CB = dyn_cast<CallBase>(FU);
            // A call whose result is UNUSED carries no value to taint (and stays
            // exactly as the pre-3jru compiler saw it; `declineQuantumReturnCalls`
            // skips it too — round 4 P3-a).
            if (CB && CB->getCalledOperand() == F && !CB->use_empty() &&
                out.Tainted.insert(CB).second)
              Worklist.push_back(CB);
          }
        }
      }
    }
  }
}

// bd `test_C_libtooling-cepm` round 1b (narrowed in round 2) — CAN A LATER DRAIN
// TAINT THIS VALUE?
//
// Every taint-GROWTH event after `propagate()` starts at a φ the round's control
// emission (or `MergePhiPeel`) REPLACES: the 6.5 / 4.5 / IO-sink merge `%out`
// rails (`UntaintedMergeRails`) and the peel's `select` each replace an UNTAINTED
// merge φ whose incoming is SELECTED by a TAINTED condition; their cascades are φs
// selected by a condition derived from such a rail. So `V` can gain taint later
// only if its backward use-def slice (operands; a call's arguments; a φ's
// incomings AND the branches that SELECT which incoming arrives) reaches a
// CONDITION that is tainted now. It OVER-approximates growth, and
// over-approximation is the SAFE direction here: a site it names is tainted in the
// drain that recorded it — what every drain did before bd cepm. An
// UNDER-approximation is what the STICKY rule in `drainWorklist` and
// `specialize()`'s check exist for: such a site stays classical and, if its
// replanned clone then returns a register, the module declines loudly. Neither
// direction is a silent one.
//
// ⚠ ROUND 2 — TWO RULES REMOVED, and why (Rule-13 r1A F-r1A-1 / bd `we38`, r1B
// F-r1B-2):
//   * "a call to a defined callee that holds a `cq_theta` (transitively), or an
//     indirect call" was a SYNTACTIC answer (L5) to "can this call's RESULT be
//     tainted later?". The only channel by which a call RESULT gains taint other
//     than through its operands (which the walk follows) is bd 3jru's return
//     crossing, and a module where it happens is refused by
//     `declineQuantumReturnCalls` at the post-fixpoint slot, before `specialize()`,
//     in both entry points (review probe `r6a`: identical decline with and without
//     the rule). An indirect call is never crossed (the crossing requires the call
//     to name the function directly). The rule's only measured effect was an
//     over-decline (`r6b`: a callee that holds a `cq_theta` but returns a MEASURED
//     classical value). Should the 3jru refusal ever be relaxed, a missed crossing
//     ONTO AN ARGUMENT of a recorded site still ends at the sticky rule +
//     `specialize()`'s check — loud. ⚠ A crossing onto the recorded SITE ITSELF is
//     NOT covered by that mechanism (Rule-13 r2 F-r2-5): `drainWorklist`'s 3jru
//     branch inserts the call into `Tainted` directly, bypassing the sticky rule, and
//     `specialize()`'s check would then see `ResultWasTainted` true. What keeps that
//     path loud TODAY is a DIFFERENT stage: `scanBody` (SpecializeReject.cpp) refuses
//     a callee that transitively holds a `cq_*` primitive (`callee contains a quantum
//     primitive (cq_*); only classical functions are lifted`), so a LIFTED callee's
//     `ret` has no source to grow from. RETIREMENT TRIGGER (L1/L8): the day `scanBody`
//     admits a callee holding a `cq_*` primitive, OR the 3jru refusal is relaxed,
//     re-derive this paragraph and give the site-itself crossing its own check.
//   * "a φ's deciders are EVERY conditional terminator between its block's idom and
//     the block" counted a loop body's own branches as deciding the loop's header φ
//     (review probe `lpp`: `for (i<3) { t = h(q, i+m); if (q > t) cq_phi(.2); }`,
//     whose tainted `br` reconverges before the latch). A branch now counts only if
//     it SELECTS the incoming (`selectsIncoming`).
class LaterTaintOracle {
public:
  explicit LaterTaintOracle(const TaintSet &T) : T(T) {}

  bool mayGain(Value *V) {
    SmallPtrSet<const Value *, 32> Seen;
    return walk(V, Seen);
  }

private:
  const TaintSet &T;
  DenseMap<const Function *, std::unique_ptr<DominatorTree>> DTs;

  DominatorTree &dt(Function &F) {
    auto &Slot = DTs[&F];
    if (!Slot)
      Slot = std::make_unique<DominatorTree>(F);
    return *Slot;
  }

  static Value *terminatorCondition(BasicBlock *B) {
    Instruction *Term = B->getTerminator();
    if (auto *BI = dyn_cast_or_null<BranchInst>(Term))
      return BI->isConditional() ? BI->getCondition() : nullptr;
    if (auto *SI = dyn_cast_or_null<SwitchInst>(Term))
      return SI->getCondition();
    return nullptr;
  }

  // Does `X`'s terminator SELECT which incoming edge of `M` arrives? For each
  // successor S of `X`, E(S) is the set of predecessors P of `M` such that some
  // path from S first reaches `M` through the edge P -> M. `X` selects iff the sets
  // are not all one and the same single block: sets that differ mean the outcome
  // picks the edge; an EMPTY set (an arm that never reaches `M`) or a set of two
  // or more blocks (the choice is left to later branches the outcome may still
  // steer) is conservatively counted as selecting. A loop body's branch whose arms
  // reconverge before the latch yields {latch} on every arm and does not select;
  // a diamond's or triangle's branch yields one arm per edge and does. Budget:
  // visiting more than `kSelectBudget` blocks from one successor answers "selects"
  // (the conservative direction).
  static constexpr unsigned kSelectBudget = 4096;
  static bool selectsIncoming(BasicBlock *X, BasicBlock *M) {
    SmallVector<SmallPtrSet<BasicBlock *, 4>, 4> Sets;
    for (BasicBlock *S : successors(X)) {
      SmallPtrSet<BasicBlock *, 4> E;
      if (S == M) {
        E.insert(X);
      } else {
        SmallPtrSet<BasicBlock *, 32> Vis;
        SmallVector<BasicBlock *, 16> WL{S};
        Vis.insert(S);
        while (!WL.empty()) {
          if (Vis.size() > kSelectBudget)
            return true;
          BasicBlock *B = WL.pop_back_val();
          for (BasicBlock *Succ : successors(B)) {
            if (Succ == M)
              E.insert(B);
            else if (Vis.insert(Succ).second)
              WL.push_back(Succ);
          }
        }
      }
      Sets.push_back(std::move(E));
    }
    if (Sets.empty())
      return false;
    for (const auto &E : Sets)
      if (E.size() != 1)
        return true;
    for (const auto &E : Sets)
      if (*E.begin() != *Sets.front().begin())
        return true;
    return false;
  }

  // A branch at `X` that selects `M`'s incoming, whose condition is tainted now or
  // may gain taint. ⚠ `selectsIncoming` is asked FIRST: a condition's slice walked
  // and then discarded would leave its nodes in `Seen` as if they could not reach
  // a seed, and a later path through them would under-report.
  bool decides(BasicBlock *X, BasicBlock *M, SmallPtrSetImpl<const Value *> &Seen) {
    Value *C = terminatorCondition(X);
    if (!C || !selectsIncoming(X, M))
      return false;
    if (T.Tainted.count(C))
      return true;  // a tainted selector: a later round may replace the φ.
    return walk(C, Seen);
  }

  bool walk(Value *V, SmallPtrSetImpl<const Value *> &Seen) {
    if (!Seen.insert(V).second)
      return false;
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      return false;  // an Argument, a Constant, a global: no drain taints it.
    if (T.Tainted.count(I))
      return false;  // already tainted: counted by the caller's current mask.
    if (auto *CI = dyn_cast<CallInst>(I);
        CI && T.MeasureCalls.contains(CI))
      return false;  // a measurement result is classical forever.
    if (auto *P = dyn_cast<PHINode>(I)) {
      for (Value *In : P->incoming_values())
        if (walk(In, Seen))
          return true;
      BasicBlock *M = P->getParent();
      DominatorTree &DT = dt(*M->getParent());
      DomTreeNode *N = DT.getNode(M);
      if (!N || !N->getIDom())
        return true;  // unreachable / no dominator: do not argue — grow.
      BasicBlock *Top = N->getIDom()->getBlock();
      // The candidate selectors: `M`'s own terminator (a self-loop's exit test)
      // and every conditional terminator on a path from `idom(M)` to `M`. The
      // CLIMB PAST `M`'s DIRECT PREDECESSORS IS REACHABLE AND PINNED — through the
      // `MergePhiPeel` channel: an if/else diamond with two NON-EMPTY phase arms and
      // two pred-available merge φs (the tainted `br` is the entry block's; both of
      // the merge's direct predecessors are ARM blocks, whose terminators are
      // unconditional). `spec_accept_predicted_classical_peel_diamond_climb.ll`
      // (Rule-13 r2 review probe `pkdC.s1.ll`, hand IR) ACCEPTS only because the
      // climb reaches that `br`; without it the site stays sticky, the peel's growth
      // drain replans its mask and `specialize()`'s check declines — a LOUD
      // over-decline, never an accept (measured with the climb removed). ⚠ Round 2
      // wrote here that the climb was "UNPINNED AND, TODAY, UNREACHABLE" because
      // every 6.5 shape with a non-direct tainted predecessor (`gie`, `gsw`,
      // `ir_fwdC.ll`) declines in round 1 — TRUE of the 6.5 channel and FALSE of the
      // peel, which the list did not cover (Rule-13 r2 F-r2-1; L7). No C spelling of
      // the peel diamond is known: `-O1` sinks the arms' common trailing `cq_phi`
      // into the merge and leaves a triangle (review probes `pk1`/`pk2`).
      if (decides(M, M, Seen))
        return true;
      SmallPtrSet<BasicBlock *, 16> Vis;
      SmallVector<BasicBlock *, 16> WL(pred_begin(M), pred_end(M));
      while (!WL.empty()) {
        BasicBlock *X = WL.pop_back_val();
        if (X == M || !Vis.insert(X).second)
          continue;
        if (decides(X, M, Seen))
          return true;
        if (X == Top)
          continue;
        WL.append(pred_begin(X), pred_end(X));
      }
      return false;
    }
    for (Value *Op : I->operands())
      if (walk(Op, Seen))
        return true;
    return false;
  }
};

// The POSSIBLE final mask of a recorded site: its tainted arguments plus every
// argument `LaterTaintOracle` says a later drain can taint. True iff the
// predictor calls the return quantum under it — the site must then be tainted
// NOW, as the oracle (every drain before bd cepm) taints every tainted-argument
// site.
bool specCallResultMayTurnQuantum(CallInst &CI, const TaintSet &taint,
                                  LaterTaintOracle &O) {
  Function *Callee = CI.getCalledFunction();
  if (!Callee)
    return true;  // not a site the predicate would have recorded; defensive.
  SpecMask M = taintArgMask(&CI, taint);
  for (unsigned A = 0, E = CI.arg_size(); A < E && A < kSpecMaxArity; ++A)
    if (!((M >> A) & 1) && O.mayGain(CI.getArgOperand(A)))
      M |= SpecMask(1) << A;
  return predictReturnTainted(Callee, M);
}

// bd `test_C_libtooling-cepm` round 1b — THE SETTLE STEP. After a drain, every
// site THIS generation recorded as predicted-classical is re-asked with its
// POSSIBLE final mask; one that would then be quantum is tainted now and drained
// (which may taint the deciders of further φs, so it repeats to a fixpoint —
// each round taints ≥1 site, so it terminates). Order-independent: it runs on
// the drain's COMPLETE taint, not on the partial taint a drain sees mid-way.
void settleSpecPredictions(const FnSet &ThetaFns, const FnSet &PhiFns,
                           const FnSet &MeasureFns, TaintSet &out,
                           bool skipRuntimeCalls) {
  for (;;) {
    const unsigned Gen = out.SpecPredictGeneration;
    LaterTaintOracle O(out);
    SmallVector<CallInst *, 4> Flip;
    for (const auto &KV : out.SpecPredictedClassical) {
      if (KV.second != Gen)
        continue;
      auto *CI = const_cast<CallInst *>(KV.first);
      if (out.Tainted.count(CI))
        continue;
      if (specCallResultMayTurnQuantum(*CI, out, O))
        Flip.push_back(CI);
    }
    if (Flip.empty())
      return;
    std::vector<Value *> WL;
    for (CallInst *CI : Flip) {
      out.SpecPredictedClassical.erase(CI);
      if (out.Tainted.insert(CI).second)
        WL.push_back(CI);
    }
    drainWorklist(WL, ThetaFns, PhiFns, MeasureFns, out, skipRuntimeCalls);
  }
}

// The drain every caller uses. A GROWTH drain (`skipRuntimeCalls`: the round-2
// reseed and its onward fixpoint, `propagateFromSeeds`) opens a new generation,
// so a site an earlier drain left classical is STICKY in it (see
// `drainWorklist`); `propagate()`'s drains all share generation 0. Then the
// settle step.
void propagateWorklist(std::vector<Value *> &Worklist, const FnSet &ThetaFns,
                       const FnSet &PhiFns, const FnSet &MeasureFns,
                       TaintSet &out, bool skipRuntimeCalls) {
  if (skipRuntimeCalls)
    ++out.SpecPredictGeneration;
  drainWorklist(Worklist, ThetaFns, PhiFns, MeasureFns, out, skipRuntimeCalls);
  settleSpecPredictions(ThetaFns, PhiFns, MeasureFns, out, skipRuntimeCalls);
}

}  // namespace

TaintSet propagate(Module &M, WidthDispatch &wd) {
  TaintSet out;
  FnSet ThetaFns;
  FnSet PhiFns;
  FnSet MeasureFns;
  Function *PhaseFn = nullptr;
  resolveSources(wd, ThetaFns, PhiFns, MeasureFns, PhaseFn);

  // No front-end intrinsics anywhere in the module → nothing to do.
  // The passthrough_no_quantum LIT fixture pins this early-out path:
  // the pass must leave a purely classical module byte-identical, and
  // crucially must NOT leak `cqrt_*` / `cq_template_*` decls.
  //
  // `PhaseFn` joins the predicate (bd test_C_libtooling-3qlq Inc 1): a module
  // whose ONLY quantum surface is an uncontrolled `void @cq_phi(double)` must
  // still run, so that D2's deletion happens — otherwise the unresolved
  // `@cq_phi` extern is a Stage-3 link error, exactly the reason the retired
  // family was in this predicate before it.
  if (ThetaFns.empty() && PhiFns.empty() && MeasureFns.empty() && !PhaseFn)
    return out;

  std::vector<Value *> Worklist;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    collectAndSeed(F, ThetaFns, PhiFns, MeasureFns, PhaseFn, out, Worklist);
  }

  // Forward taint propagation. Each tainted SSA value's user instructions
  // become tainted, except measure sinks. The work-list discipline
  // (insert-then-push) means each value is processed exactly once. A
  // tainted-operand phi is reached here as a normal user, so its result
  // taints and propagates onward — correct (Rz preserves the value).
  // `skipRuntimeCalls=false`: no `cqrt_*`/`cq_template_*` calls exist pre-lowering.
  propagateWorklist(Worklist, ThetaFns, PhiFns, MeasureFns, out,
                    /*skipRuntimeCalls=*/false);

  // bd `test_C_libtooling-3jru`: call-return taint is closed INSIDE
  // `propagateWorklist` (see there), so this rebuild is closed under it too.
  return out;
}


bool declineStaleTaintSet(Module &M, WidthDispatch &wd, const TaintSet &taint) {
  // See TaintPropagation.h. Asked in both directions: a value the fresh set has
  // and the carried one lacks is the bd otam shape (a pre-pass minted a tainted
  // value and nobody re-propagated); the converse (a carried value the fresh set
  // lacks) would mean a stage made a value classical without a re-propagate —
  // equally stale, equally loud.
  TaintSet Fresh = propagate(M, wd);
  const Value *Diff = nullptr;
  for (Value *V : Fresh.Tainted)
    if (!taint.Tainted.count(V)) {
      Diff = V;
      break;
    }
  if (!Diff)
    for (Value *V : taint.Tainted)
      if (!Fresh.Tainted.count(V)) {
        Diff = V;
        break;
      }
  if (!Diff)
    return false;
  const auto *I = dyn_cast<Instruction>(Diff);
  const Function *F = I ? I->getFunction() : nullptr;
  if (!F)
    if (const auto *A = dyn_cast<Argument>(Diff))
      F = A->getParent();
  if (!F)
    for (const Function &G : M)
      if (!G.isDeclaration()) {
        F = &G;
        break;
      }
  if (!F)
    return false;  // no body anywhere: nothing downstream can read the set.
  F->getContext().diagnose(DiagnosticInfoUnsupported(
      *F,
      "cq lowering: taint set is stale after a pre-pass (a stage grew or shrank "
      "the tainted set without re-propagating)",
      I ? I->getDebugLoc() : DebugLoc()));
  return true;
}

void foldIdentityBitcasts(Module &M, TaintSet &taint,
                          SmallPtrSetImpl<Value *> *Scrub) {
  // See TaintPropagation.h for the full rationale. A same-width int<->int
  // `bitcast` is a zero-gate reversible IDENTITY that `rewriteCast` would fold to
  // `result === operand`; folding it HERE — before ANY analysis — means the whole
  // pass sees the operand's true wire directly and never an opaque identity node.
  // Every downstream provenance/lineage/stale walk (the pass has several bespoke
  // ones that do NOT share a single walker) is thereby automatically correct: the
  // module is reduced to the exact DIRECT-operand form the base pass adjudicates,
  // so a downstream DATA op over a re-rotated wire declines and a MEASURE reads the
  // wire in place — with no per-consumer crossing logic (the Rule-13 finding).
  //
  // Collect first, then RAUW+erase (no in-flight iterator invalidation). A CHAIN
  // (`%b2 = bitcast %b1`) folds correctly regardless of order: RAUW propagates the
  // operand through, and each collected bitcast is erased exactly once. Only a
  // TAINTED, BOTH-sides-scalar-integer bitcast is folded — the fold-eligibility
  // test mirrors `castInScope`'s `bitcast` accept (same-width int, `intBits` equal)
  // exactly, so nothing folds here that `rewriteCast` would not have. fp<->int /
  // vector / pointer bitcasts fail the scalar-integer test, are LEFT STANDING, and
  // decline loudly at `castInScope` downstream (unchanged). An UNTAINTED bitcast is
  // classical scaffolding — never folded, never lowered.
  SmallVector<BitCastInst *, 8> Fold;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *BC = dyn_cast<BitCastInst>(&I))
          if (taint.Tainted.count(BC) && BC->getType()->isIntegerTy() &&
              BC->getOperand(0)->getType()->isIntegerTy())
            Fold.push_back(BC);
  }
  for (BitCastInst *BC : Fold) {
    Value *Src = BC->getOperand(0);
    BC->replaceAllUsesWith(Src);
    // Scrub the freed Instruction* from the taint side-tables (SwapRouteEmit::
    // scrubTaint / freeze-fold precedent — a later allocation could alias the
    // address; belt-and-braces since bd 8e5r: every TaintSet table drops a deleted key by itself, `ScrubOnDelete.h`). The operand keeps its own BirthOrder/HandleWidth; a fold mints no
    // new handle. BirthOrder is not populated for a raw pre-lowering bitcast.
    taint.Tainted.erase(BC);
    taint.HandleWidth.erase(BC);
    // `Scrub` is the CALLER'S OWN `Value *` set (bd b6ap F-B6R2-1): the delta
    // `adjudicateTaintDelta` hands to `replanReseedSpecialization` /
    // `detectSpecializations` as a DIRECT-ARGUMENT membership test. A freed
    // pointer left live in it is the bd `drbq` Inc-1 stale-set defect, so the
    // erase happens HERE, at the one place that knows the instruction is dying,
    // rather than at a call site that would have to predict which bitcasts fold.
    if (Scrub)
      Scrub->erase(BC);
    BC->eraseFromParent();
  }
}

// Does `I` read at least one tainted SSA value? Operand-level test (not
// result-taint): the escape is the EDGE from a quantum value into a consumer
// the lowering cannot rewrite. For a CallBase, `operands()` includes the
// called operand, so an indirect call THROUGH a tainted pointer also trips.
// Exported (bd cepm) — see TaintPropagation.h.
bool readsTaintedValue(const Instruction &I, const TaintSet &taint) {
  for (const Value *Op : I.operands())
    if (taint.Tainted.count(const_cast<Value *>(Op)))
      return true;
  return false;
}

namespace {

// The exact diagnostic strings the taint-escape guard owns
// (test_C_libtooling-bxv; the non-i32 return string is test_C_libtooling-udw).
// The negative fixtures mirror each one CHARACTER-FOR-CHARACTER (Rule 12):
//   * lowering_reject_taint_escape_opaque_call.ll    → kMsgUnknownCallee
//   * lowering_reject_taint_escape_deep_arg.ll       → kMsgUnknownCallee
//   * lowering_reject_taint_escape_inmodule_body.ll  → kMsgUnknownCallee
//   * lowering_reject_taint_escape_indirect_call.ll  → kMsgUnknownCallee
//   * lowering_reject_taint_escape_store_global.ll   → kMsgStore
//   * lowering_reject_taint_escape_gep.ll            → kMsgOther
//   * lowering_reject_taint_escape_return_straightline.ll   → kMsgNonI32Return
//   * lowering_reject_taint_escape_return_phase_diamond.ll  → kMsgNonI32Return
//   * lowering_reject_taint_escape_return_value_diamond.ll  → kMsgNonI32Return
constexpr char kMsgUnknownCallee[] =
    "cq taint escape: tainted value consumed by an unknown callee";
constexpr char kMsgStore[] = "cq taint escape: tainted value stored to memory";
constexpr char kMsgOther[] =
    "cq taint escape: tainted value reaches an unsupported instruction";
constexpr char kMsgNonI32Return[] =
    "cq taint escape: tainted value returned at non-i32 width";

// Loud `DiagnosticInfoUnsupported(DS_Error)` with the offending instruction's
// `!dbg` — the one diagnostic surface the whole pass speaks (same idiom as
// FreePoint::diagnose and RotationLowering::diagnoseUnsupported); `opt` exits
// non-zero, which the negative LIT fixtures invert with `RUN: not`.
void diagnoseEscape(Instruction *I, StringRef Msg) {
  I->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *I->getFunction(), Msg, I->getDebugLoc()));
}


// ── Phase-7.1 Increment B: the freeze-passthrough R-B narrowing ─────────────
// A tainted `freeze` is, semantically, a basis-level identity (freeze of an
// already-defined value is the value itself). But a BLANKET `isa<FreezeInst>`
// skip would re-launder an Escaped/Measured value: `freeze i32 %h; ret i32 %f`
// would slip `%h` into the ACCEPTED i32-ret Escaped case (`:482-487`), and
// `freeze` of a fanned-out / independently-measured handle would mis-route the
// whole-DAG uncompute's free (Rule 8 linear-lineage). So the accept is NARROW
// (Prime Directive: any unproven ownership ⇒ decline).
//
// `isLocalIntegerIdentityFreeze` returns true ONLY for the pure local case we
// fold away: an INTEGER freeze whose
//   (a) tainted operand has no INDEPENDENT escape/sink user — no `ret`/`store`/
//       `cq_invert_*`/measure user OTHER than through this freeze (linear
//       lineage on the operand: the operand's only forward consumers are the
//       freeze plus benign in-place/template/measure users in THIS lineage), and
//   (b) freeze RESULT has no user that would become an escape after the fold —
//       no `ret`/`store`/`cq_invert_*`/unknown-or-opaque call (those must stay
//       declined: the R-B blocker). A `cq_measure`/`cqrt_*`/`cq_template_*`
//       consumer, or another value-preserving carrier, is fine.
// An FP freeze is NOT folded here — it rides the GATE-3 carrier fence
// (SelectClassify::selReachesRotationArg1 now crosses `freeze`), so an FP-angle
// route is declined `rotation angle` at detection rather than laundered. The
// caller therefore handles FP and integer separately.
bool freezeOperandIndependentlyEscapes(const Value *Op, const FreezeInst *Self) {
  for (const User *U : Op->users()) {
    if (U == Self)
      continue;  // the freeze itself is the in-lineage consumer.
    const auto *I = dyn_cast<Instruction>(U);
    if (!I)
      continue;
    if (isa<ReturnInst>(I) || isa<StoreInst>(I))
      return true;  // operand independently leaves the SSA/return domain.
    if (const auto *CI = dyn_cast<CallInst>(I)) {
      const Function *Callee = CI->getCalledFunction();
      StringRef N = Callee ? Callee->getName() : StringRef();
      // A measure of the operand (a SECOND sink — fan-out) or a manual-inversion
      // handoff makes the operand's record path-dependent. Recognized in-place /
      // template consumers are in-lineage and benign.
      if (N.starts_with("cq_measure_") || N.starts_with("cqrt_measure_") ||
          N.starts_with("cq_invert_"))
        return true;
    }
  }
  return false;
}

bool freezeResultWouldEscape(const FreezeInst *FI) {
  for (const User *U : FI->users()) {
    const auto *I = dyn_cast<Instruction>(U);
    if (!I)
      continue;
    if (isa<ReturnInst>(I) || isa<StoreInst>(I))
      return true;  // the R-B blocker: folding would create a tainted escape.
    if (const auto *CI = dyn_cast<CallInst>(I)) {
      const Function *Callee = CI->getCalledFunction();
      StringRef N = Callee ? Callee->getName() : StringRef();
      // Only EXPLICITLY recognized consumers are benign post-fold; an unknown /
      // opaque / indirect callee would read the laundered handle verify-clean.
      if (N.starts_with("cq_measure_") || N.starts_with("cqrt_") ||
          N.starts_with("cq_template_"))
        continue;
      return true;  // unknown callee — decline-by-default.
    }
    // A non-call, non-ret/store user (another carrier, a downstream op) is left
    // for its own guard; it is not an escape created by this fold.
  }
  return false;
}

bool isLocalIntegerIdentityFreeze(const FreezeInst *FI, const TaintSet &taint) {
  if (!FI->getType()->isIntegerTy())
    return false;  // FP/vector/aggregate freeze is not the folded case.
  Value *Op = FI->getOperand(0);
  if (!taint.Tainted.count(Op))
    return false;  // only a tainted-handle identity is in scope.
  if (freezeOperandIndependentlyEscapes(Op, FI))
    return false;  // operand independently escaped/measured ⇒ decline (R-B).
  if (freezeResultWouldEscape(FI))
    return false;  // folding would launder into an escape ⇒ decline (R-B).
  return true;
}

}  // namespace

void declineTaintEscapes(Module &M, TaintSet &taint, const SpecPlan &plan6) {
  // Phase-7.1 Increment B: basis-level identity freezes proven foldable during
  // the walk below; folded (RAUW + erase + taint-scrub) AFTER the walk so no
  // erasure invalidates the in-flight BB iterator (the diagnostics still see
  // pre-RAUW SSA identity — the fold removes only no-ops).
  SmallVector<FreezeInst *, 4> FoldFreezes;
  // Exact membership for the collected front-end intrinsic call sites —
  // never name-prefix matching on the ACCEPT side (a user function named
  // `cq_theta_evil` must not slip through). `propagate` collected precisely
  // the calls whose callee resolved through WidthDispatch's 42-name surface.
  SmallPtrSet<const CallInst *, 32> IntrinsicCalls;
  IntrinsicCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  IntrinsicCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());
  IntrinsicCalls.insert(taint.MeasureCalls.begin(), taint.MeasureCalls.end());
  // bd test_C_libtooling-3qlq Inc 1 — the register-free `void @cq_phi(double)`.
  // Its ONE operand is the classical ANGLE, and a TAINTED angle there is the
  // ACCEPTED angle-select shape (`cq_phi(c ? A : B)`, PRD §6.2 P2) as often as
  // it is an error, so it cannot be adjudicated here: like the suffixed
  // family's arg-1 slot above, it is OWNED by a later stage — the angle-select
  // classifier claims it, and every surviving one is declined by
  // `deleteGlobalPhases` with the SAME `quantum-derived rotation angle` string
  // the suffixed family used. Omitting this line makes P2 unreachable (measured
  // on the oracle: `cq taint escape: tainted value consumed by an unknown
  // callee`, fired before `detectControlRegions` ever runs).
  IntrinsicCalls.insert(taint.PhaseCalls.begin(), taint.PhaseCalls.end());

  // BB-order walk (deterministic diagnostic order, like
  // OpcodeLowering::declineStaleRecordOps). One diagnostic per offending
  // instruction. The KNOWN-CONSUMER list below is everything a later stage
  // provably owns — each entry cites its owner; ANYTHING else that reads a
  // tainted value is an unproven shape and declines loudly: never silent, but
  // each valid program it refuses is a gap to close (R1), while over-accepting
  // is a silent miscompile.
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Phase-7.5 QRAM: built lazily, only when a tainted gep/load candidate is
    // seen in `F` (same idiom as declineClassicalMuxes' DT). Needed by the
    // straight-line (not-under-tainted-control) + not-in-loop carve predicate.
    std::optional<DominatorTree> DT;
    std::optional<LoopInfo> LInfo;
    // bd `xdu2` / L-1a W1 — ScalarEvolution for the rail-bank C2′ injectivity
    // clause, built lazily and at most once per function, only when a store has
    // already passed the (cheap) rail-bank entry gate. The direct-construction
    // idiom is COPIED FROM `LoopLowering.cpp`'s `lowerLoops` (`AssumptionCache
    // AC(F); TargetLibraryInfoImpl TLII(Triple(M.getTargetTriple()));
    // TargetLibraryInfo TLI(TLII); ScalarEvolution SE(F, TLI, AC, DT, LI);`) —
    // the LIVE one of the tree's two spellings (the other is
    // `LoopUnrollPrepass.cpp`, byte-identical); a default `TargetLibraryInfoImpl`
    // is a conservative TLI, sufficient for SCEV's trip-count reasoning.
    //
    // ⚠ `TaintPropagation.cpp`'s own warning that *"a `LoopInfo` built
    // mid-fixpoint would describe a loop the next iteration reshapes"* is
    // DISCHARGED HERE rather than inherited: `declineTaintEscapes` runs
    // PRE-DETECTION and PRE-FLATTEN, so this SE describes the SOURCE loop — which
    // is exactly the loop whose trip count C2′ is asking about. It is rebuilt from
    // scratch on every re-entry (including `adjudicateTaintDelta`'s), so it can
    // never be a stale cache either.
    //
    // DECLARATION ORDER IS LOAD-BEARING: `SE` holds references to `TLI`, `AC`,
    // `*DT` and `*LInfo`, and members are destroyed in reverse declaration order,
    // so `SE` must be declared LAST of the five.
    std::optional<AssumptionCache> AC;
    std::optional<TargetLibraryInfoImpl> TLII;
    std::optional<TargetLibraryInfo> TLI;
    std::optional<ScalarEvolution> SE;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // 1. Calls/invokes FIRST (an InvokeInst is also a terminator — it must
        //    not fall through to the terminator skip below).
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          // 1a. Front-end intrinsic call sites: arg-0 handle slot is lowered
          //     (RotationLowering / MeasureLowering); the arg-1 ANGLE slot is
          //     OWNED by RotationLowering::declineTaintedAngle and
          //     ArmClassify::taintedAngleGate (test_C_libtooling-659) — both
          //     run later and still fire, so this guard skips the whole call.
          if (auto *CI = dyn_cast<CallInst>(CB))
            if (IntrinsicCalls.count(CI))
              continue;
          // An `invoke` of a front-end intrinsic was already declined loudly at
          // collection (collectAndSeed → diagnoseIntrinsicInvoke,
          // test_C_libtooling-rzs9). Skip it here by EXACT membership — NEVER by
          // name prefix, so a user function named `cq_theta_evil` reached via
          // invoke still escapes (the accept-side hazard guarded at line ~302) —
          // so this guard does not re-flag a tainted arg-0 as a misleading
          // "unknown callee" (the callee IS known; the invoke form is not).
          if (taint.IntrinsicInvokes.count(CB))
            continue;
          const Function *Callee = CB->getCalledFunction();
          StringRef N = Callee ? Callee->getName() : StringRef();
          // 1b. The pass's own runtime symbols. At guard time (pre-lowering)
          //     none should exist; accepting them anyway keeps the rule honest
          //     for a re-entrant caller (same defensive stance as
          //     `isMeasureSink`'s `cqrt_measure_` prefix above) and for the
          //     `runOnFunction` unit shim run after a sibling was lowered.
          // 1c. `cq_invert_*`: the Phase-7 manual-inversion handoff — a
          //     RECOGNIZED escape, the same set FreePoint silently skips
          //     (isRecognizedEscapeUser; pinned ACCEPT fixture
          //     lowering_uncompute_escape_invert.ll).
          if (N.starts_with("cqrt_") || N.starts_with("cq_template_") ||
              N.starts_with("cq_invert_"))
            continue;
          // 1d-Phase6. Carve-out (C-Plan, decline-by-default). A direct
          //     `CallInst` to a visible body that `detectSpecializations`
          //     proved liftable (in `plan6.Pending`) is OWNED by clone-on-taint
          //     (step 14) — suppress its escape decline. A site detection
          //     already loud-declined with a SPECIALIZATION message
          //     (`plan6.Diagnosed`: a `cq_*` body, a measurement, in-body
          //     control, recursion, an fp/i128 ABI, an over-wide arity) is
          //     suppressed too, so it renders exactly one message, not also the
          //     generic `kMsgUnknownCallee`. This is a pure membership test — no
          //     re-classification, no `wd` (none in scope, C6). Every other
          //     candidate-shaped site (invoke/callbr → not a `CallInst`;
          //     indirect → null callee; declaration-only → no IR) is in NEITHER
          //     set and falls through to the decline below (DD-2 no-IR contract).
          if (auto *CI = dyn_cast<CallInst>(CB)) {
            if (shouldSpecialize(CI, plan6) || plan6.Diagnosed.count(CI))
              continue;
            // 1d-Phase7.1-E. Curated reversible llvm.* idiom intrinsics
            //     (bswap/bitreverse/fshl-fshr rotation/ctpop/ctlz/cttz/abs/
            //     smin/smax/umin/umax/*.sat at a table width) are OWNED by
            //     IntrinsicLowering (enqueued in OpcodeLowering, lowered to a
            //     cq_template_<op>_<W> additive producer the whole-DAG uncompute
            //     spine reverses). EXACT Intrinsic::ID membership — NEVER a
            //     `starts_with("llvm.")` accept (the cq_theta_evil hazard) — and
            //     fshl/fshr require a CONSTANT amount in EITHER the rotation form
            //     (arg0==arg1) OR the general two-runtime-operand funnel form
            //     (arg0!=arg1, both non-ConstantInt — the (ix<<16)|(i0>>16) idiom).
            //     A non-curated id, an unsupported width, a dynamic amount, or a
            //     funnel with a ConstantInt data operand fails the predicate and
            //     falls through to the loud kMsgUnknownCallee decline below
            //     (`*.with.overflow`, transcendentals stay declined).
            if (isCuratedReversibleIntrinsic(CI))
              continue;
            // p119 (Rule 18): a DIRECT-libm math.h call (cbrt/erf/atan2/hypot/
            //     ilogb/ldexp/…) and a by-ref math call (frexp/modf/remquo) are
            //     LIBRARY functions — their name-recognition is REMOVED. A library
            //     function must be compiled by SOURCE INJECTION (its body inlines
            //     to opcodes before this pass), never carved by name. So a tainted
            //     un-injected libm call is NOT carved here: it falls through to the
            //     loud kMsgUnknownCallee decline below (the correct, safe outcome —
            //     you did not inject the source). Only the hardware-backed
            //     intrinsics carved above (isCuratedReversibleIntrinsic) survive.
          }
          // 1d-Phase7.6. Recognized I/O output sinks (`printf` / `putchar`)
          //     consuming a tainted INTEGER-SCALAR arg are OWNED by
          //     `lowerIOSinks` (the reversible output tape — `cqrt_tape_alloc`
          //     + `cqrt_tape_write_<W>`, PRD-7.6). EXACT-name membership —
          //     NEVER a `starts_with("printf")` accept (a user `printf_helper`
          //     must still escape; the cq_theta_evil hazard, line ~448-451).
          //     Restricted to a DIRECT `CallInst`: an `invoke @printf` (a
          //     CallBase that is not a CallInst) and an indirect call (null
          //     callee, empty `N`) both fall through to the loud
          //     kMsgUnknownCallee decline below. `lowerIOSinks` runs later
          //     (after control lowering, BEFORE `lowerRotations`) and STILL
          //     fires its OWN loud decline for any arg shape it cannot prove
          //     (fp `%f`, i128, non-scalar, a used sink result, a non-constant
          //     classical co-arg) — so this carve suppresses ONLY the generic
          //     unknown-callee decline, it NEVER accepts an unlowerable sink.
          //     The callee must be a DECLARATION (the libc extern) — a user's
          //     own in-module printf/putchar body is owned by the specializer /
          //     escape path, NOT taped (Rule-13 R5) — and the call must carry no
          //     OPERAND BUNDLES (a tainted bundle operand is read by
          //     readsTaintedValue but not by lowerIOSinks's CI->args() scan, so
          //     carving without lowering it is the opaque-call miscompile,
          //     Rule-13 R3). These two predicates match isRecognizedIOSink
          //     EXACTLY so the carve and the emitter can never diverge.
          if (auto *CIio = dyn_cast<CallInst>(CB))
            if (Callee && Callee->isDeclaration() &&
                !CIio->hasOperandBundles() &&
                (N == "printf" || N == "putchar"))
              continue;
          // 1e. Everything else — opaque extern, an in-module body the
          //     specializer declined, a NON-curated llvm.* intrinsic, or
          //     indirect (null callee) — is an UNKNOWN callee: after RAUW it
          //     would read the i32 runtime handle tag, verify-clean.
          if (readsTaintedValue(I, taint))
            diagnoseEscape(&I, kMsgUnknownCallee);
          continue;
        }
        // 2. The four lowerOps instruction classes — owned by Arith/Compare/
        //    CastLowering, whose drivers diagnose their own unsupported
        //    members loudly ("no template for opcode ... in tainted context",
        //    e.g. the inttoptr probe; fixture
        //    lowering_icmp_qq_no_width_reject.ll, an unsupported Q+Q compare).
        if (isa<BinaryOperator>(I) || isa<UnaryOperator>(I) ||
            isa<CmpInst>(I) || isa<CastInst>(I))
          continue;
        // 3. Control-flow value merges/muxes — owned by ControlDetect (a
        //    tainted-condition select/switch/branch accepts as a control
        //    region or declines "... under quantum control") and, for the
        //    CLASSICAL-condition leftovers, by `declineClassicalMuxes`, which
        //    runs after `lowerControlRegions` (test_C_libtooling-wi5 — the
        //    Phase-5 FreePoint net is NOT an owner: its "unrecognized user"
        //    reject is bypassed when the base handle is Measured / Escaped /
        //    `main`-resident or non-terminal). Declining them here would
        //    re-own the tainted-condition shapes whose fixtures pin the
        //    "... under quantum control" diagnostics character-for-character.
        if (isa<PHINode>(I) || isa<SelectInst>(I))
          continue;
        // 4. Terminators. A tainted `br`/`switch` CONDITION is ControlDetect's.
        //    A `ret` of a tainted value is FreePoint's RECOGNIZED Escaped case —
        //    the caller owns the handle — but ONLY at i32 width (pinned ACCEPT
        //    fixtures lowering_uncompute_escape_return.ll,
        //    control_swap_ifelse_escape.ll). The runtime handle is ALWAYS i32:
        //    every lowering path RAUWs a tainted SSA value to a `cqrt_alloc_*`
        //    i32 result (RotationLowering §1) — straight-line theta, the phase-
        //    diamond merge, and the value-diamond `cqrt_copy` merge alike — and
        //    that cross-type RAUW is laundered ONLY by ERASURE of the tainted
        //    user. A `ret` is NEVER erased, so returning a tainted value at a
        //    width other than i32 leaves `ret <iN!=32> <i32 handle>` in the
        //    final IR: the verifier aborts with report_fatal_error("Broken
        //    module found") — loud and unconsumable, but NOT the Rule-1 source-
        //    located decline, and for the value-diamond (which PRD Part II §8.5
        //    sanctions as ACCEPT-class: ret is a legitimate consumer of `out`)
        //    it crashes accepted input. Declining HERE, pre-RAUW, converts that
        //    abort into a clean decline — the same move as
        //    ArmClassify::taintedAngleGate. i32-width tainted rets stay
        //    accepted; a non-tainted ret (e.g. of a `cq_measure` result, a
        //    classical value past the taint sink) is untouched
        //    (test_C_libtooling-udw; pinned boundary
        //    lowering_taint_escape_return_measure_i64.ll).
        if (auto *Ret = dyn_cast<ReturnInst>(&I)) {
          Value *RV = Ret->getReturnValue();
          // Gate on the FUNCTION return type, NOT `RV->getType()` (dugh). Pre-RAUW
          // (the first-pass tainted straight-line/diamond returns) the two are
          // identical — well-formed IR requires `ret <T> <v>` with v: T == the
          // function return type — so this is equivalent for every pinned
          // straight-line/value/phase-diamond non-i32-return fixture. But in the
          // SECOND round (`repropagateControlMerges`) an untainted-merge emitter has
          // already RAUW'd its iN merge phi to the i32 `%out` handle, so
          // `ret i64 %out` has an i32 RV yet an i64 function return type — the exact
          // 8mld broken-module the verifier aborts on. Reading `RV->getType()` here
          // would see i32 and MISS it (verifier SIGABRT on valid input); the function
          // return type is the stable ABI width and catches the post-RAUW mismatch.
          if (RV && taint.Tainted.count(RV) &&
              !Ret->getFunction()->getReturnType()->isIntegerTy(32))
            diagnoseEscape(&I, kMsgNonI32Return);
          continue;
        }
        if (I.isTerminator())
          continue;
        if (!readsTaintedValue(I, taint))
          continue;
        // 4a-Phase7.5. QRAM tainted-index memory. A tainted-pointer
        //    `getelementptr`/`load`/`store` is QRAM's domain, adjudicated by the
        //    SINGLE shared verdict `qramCarveVerdict` (QramLowering) — the same
        //    `matchQramAccess` the emitters (`lowerQramReads`/`lowerShadowMemory`)
        //    consult, so the carve and the emit can never diverge (Inc 1
        //    discipline). The verdict is one of:
        //      * Accept  — a QRAM-shaped access the emitter lowers (const-global
        //        QROM read OR alloca-backed Shadow store/load). The emitter STILL
        //        loud-declines an accepted-shape access whose element width has no
        //        reversible copy (fp/i128) and the alloca-WIDE failures (mixed /
        //        escape / mid-sequence observation), so the carve suppresses ONLY
        //        the generic decline — it NEVER accepts an unlowerable access (§6.9).
        //      * Decline — a QRAM-shaped access that fails a PER-ACCESS precondition
        //        (Inc 3 §2.8(iv) decline matrix: multi-origin, inttoptr/ptrtoint,
        //        addrspacecast, dynamic-N, heap, aliasing fan-out, in-loop). Fire
        //        the pattern-naming, source-located diagnostic the verdict owns
        //        (`Msg`, a QramLowering string the negative fixtures mirror).
        //      * NotQram — a classical-address / value-tainted store, or a read
        //        UNDER tainted control (a clang-folded jump-table gep/load,
        //        control_swap_reject_switch_jumptable.ll) — fall through to the
        //        GENERIC decline below (kMsgStore / kMsgOther). Over-declining a
        //        clean-origin-but-unclean-offset access is safe (never silent).
        if (isa<GetElementPtrInst>(I) || isa<LoadInst>(I) || isa<StoreInst>(I)) {
          if (!DT) {
            DT.emplace(F);
            LInfo.emplace(*DT);
          }
          const char *QMsg = nullptr;
          switch (qramCarveVerdict(&I, taint, *DT, *LInfo, QMsg)) {
          case QramCarve::Accept:
            continue;  // emitter owns it (accept or alloca-wide/width decline).
          case QramCarve::Decline:
            diagnoseEscape(&I, QMsg);  // Inc 3 pattern-naming decline; opt non-zero.
            continue;
          case QramCarve::DeferControl:
            continue;  // iw81.7 — a GuardedStoreArm store/gep: `detectControlRegions`
                       // owns it (flatten + guarded emit) or declines it loudly.
          case QramCarve::NotQram:
            break;  // fall through to the rail-bank carve, then to the generic
                    // kMsgStore / kMsgOther decline.
          }
        }
        // 4a-bis-xdu2. THE RAIL-BANK CARVE (bd `xdu2` / L-1a Increment W1), a
        //    SECOND switch beside the QRAM one and reached ONLY after
        //    `QramCarve::NotQram` — because a classical-address / value-tainted
        //    store is precisely `NotQram`'s documented population
        //    (`QramLowering.h`; implemented at the `!taint.Tainted.count(PtrOp)`
        //    line of `classifyQramCarve`). The two axes are orthogonal by
        //    construction: 7.5 owns a TAINTED index over classical memory, L-1a a
        //    CLASSICAL index over quantum cells, and `railBankCarveVerdict` carries
        //    the negation as an explicit conjunct so neither can claim the other's
        //    input if either caller moves (L3's mirror).
        //
        //    *** THE `Bank` VERDICT STILL DECLINES THIS SESSION, AND THAT IS A
        //    CORRECTNESS REQUIREMENT, NOT A SCOPE PREFERENCE. *** The taint rule (a
        //    `load` from a bank cell is tainted), the `[N x i1]` → `[N x i32]` type
        //    rewrite and the D5 consumer allow-list are the second half of L-1a.
        //    Until they land, an ACCEPTED bank is a SILENT MISCOMPILE by a named
        //    mechanism (`SCOPE_L1a.md` §4.4(D)): `cq_measure(b[i])` on an UNTAINTED
        //    load takes `MeasureLowering`'s classical split and emits no gate, no
        //    symbol and NO TRACE LINE — and the golden byte-diff cannot see a
        //    measurement that was never emitted. So `Bank` `break`s to the generic
        //    `kMsgStore` below, exactly as `QramCarve::NotQram` does.
        //
        //    ⚠ L8 RETIREMENT TRIGGER: when that second half lands, the `Bank` arm
        //    stops breaking and becomes a `continue` (the bank's owner emits it),
        //    and every `lowering_reject_railbank_*` fixture whose header says so
        //    becomes an ACCEPT. Re-derive them then; do NOT delete them.
        //
        //    ⚠⚠ THE TRIGGER REACHES `Bank` AND NOT `BankRaw`, AND THAT DISTINCTION
        //    IS THE WHOLE OF bd `test_C_libtooling-de8n` (P1, closed 2026-09-15).
        //    Until clause C7 existed there was ONE accept-shaped verdict and this
        //    trigger turned it into the accept — while that verdict did NOT imply
        //    the shape the type rewrite can serve. A bank the per-activation
        //    promoter did not normalise still carries the PARTIALLY AVAILABLE
        //    per-trip read of `SCOPE_L1a.md` §0 H3, and after the `[N x cell]` →
        //    `[N x i32]` rewrite that read takes the initializer `0` AS A HANDLE —
        //    `h0` being a LIVE RAIL (`cqrt_alloc_i1(0) -> h0`). Reachable from
        //    plain `-O1` C, three families, measured. So: `Bank` may one day
        //    `continue`; `BankRaw` MUST KEEP BREAKING TO `kMsgStore`, FOREVER, and
        //    a widening that wants a `BankRaw` shape to compile must move it into
        //    `Bank` at the carve (or teach the promoter to normalise it) rather
        //    than add an arm here.
        //
        //    The `Reject*` arms DO fire now: they replace the generic `kMsgStore`
        //    with a per-clause, pattern-naming, source-located diagnostic for
        //    exactly the population this classifier claims — a decline→decline
        //    string change and nothing else.
        if (auto *BankSI = dyn_cast<StoreInst>(&I)) {
          if (!DT) {
            DT.emplace(F);
            LInfo.emplace(*DT);
          }
          // ⚠ `LInfo->empty()` BEFORE constructing SE — the SAME guard both existing
          // standalone-SE sites use (`LoopLowering.cpp` and `LoopUnrollPrepass.cpp`
          // each open with `if (LI.empty()) continue;`), copied rather than
          // re-derived. A rail bank's store is ALWAYS in a loop, so a loop-free
          // function can never produce a `Bank` and need not pay for a
          // ScalarEvolution. It duplicates no rail-bank predicate: the verdict's own
          // `LI.getLoopFor(SI->getParent())` conjunct is unchanged and is what
          // actually decides. MEASURED, the cost it avoids is below this pass's
          // per-spawn noise floor (IMPL_A.md §10 R-5) — it is here because a
          // pathological function is the case a measurement on the corpus cannot see.
          //
          // ⚠ IT IS AN `if`-GUARD AROUND THE REST OF THE BLOCK, NOT AN EARLY `break`,
          // AND THE FIRST SPELLING OF IT WAS THE OTHER ONE. Inside `for (Instruction
          // &I : BB)` a bare `break` exits the INSTRUCTION LOOP, so a loop-free
          // function would have SKIPPED this store's generic `kMsgStore` decline AND
          // every later instruction of its block — a SILENT SKIP of a decline, i.e.
          // exactly the Prime-Directive violation Rule 1 calls "no third path". It
          // compiled clean. Kept as a comment because the shape recurs: a guard
          // added for PERFORMANCE inside a loop whose body ends in a mandatory
          // diagnostic is one keyword away from deleting the diagnostic.
        if (!LInfo->empty()) {
          if (!SE) {
            AC.emplace(F);
            TLII.emplace(Triple(M.getTargetTriple()));
            TLI.emplace(*TLII);
            SE.emplace(F, *TLI, *AC, *DT, *LInfo);
          }
          const char *BMsg = nullptr;
          cq::RailBankShape BShape;
          switch (railBankCarveVerdict(BankSI, taint, *DT, *LInfo, *SE, BMsg,
                                       &BShape)) {
          case RailBankCarve::Bank:
            // The Rule-12 hygiene defect (c) hazard in its purest form: TODAY this
            // verdict's observable behaviour is identical to doing nothing at all,
            // so it MUST be pinned by something other than the unchanged
            // `kMsgStore`. The anchor rides the existing env-gated `CQ_CTRL_DBG`
            // lever (bd adia; `ControlPlan.h`'s `diagnoseUnderControl` uses the same
            // variable) — byte-neutral when unset, and byte-ABSENT on the ORACLE,
            // which is what makes the `env CQ_CTRL_DBG=1` fixtures non-vacuous.
            if (::getenv("CQ_CTRL_DBG")) {
              llvm::errs() << "CQ_CTRL_DBG: railbank [Bank] cells=";
              if (BShape.RuntimeSized)
                llvm::errs() << "runtime(" << *BShape.Extent << ")";
              else
                llvm::errs() << BShape.Count;
              llvm::errs() << " abi=" << BShape.ElemAbi << " trips=";
              if (BShape.RuntimeSized)
                llvm::errs() << "runtime";
              else
                llvm::errs() << BShape.Trips;
              llvm::errs() << " at: " << *BankSI << "\n";
            }
            // ⚠ THE L8 RETIREMENT TRIGGER ABOVE HAS FIRED (bd `xdu2` W1 second
            // half, 2026-09-15): the `Bank` arm no longer falls through to
            // `kMsgStore` — the bank OWNS this store, and the rail it parks is
            // read back by the type rewrite + the taint rule + the D5
            // allow-list. Every `lowering_reject_railbank_*` fixture whose
            // header says so is re-derived as part of that landing.
            //
            // ⚠⚠ BUT ONLY WITH THE RECORD PRESENT, AND THE CONJUNCT IS THE
            // WHOLE SAFETY COUPLING, NOT A BELT-AND-BRACES. The accept, the
            // taint rule and the type rewrite are all keyed on
            // `!cq.railbank`; a `Bank` verdict WITHOUT the record means this
            // store's loads were never tainted and the type rewrite will never
            // see the object, which is EXACTLY the silent miscompile the second
            // half exists to close (three written `cq_measure` calls emitting
            // nothing). The record is minted at the normaliser slot, so the two
            // can only disagree if a stage BETWEEN that slot and here changed
            // the shape — and then the loud answer is the generic decline.
            // MEASURED direction of each disagreement: shape destroyed after
            // the mint ⇒ the carve no longer says `Bank` and some `Reject*` or
            // the generic `kMsgStore` fires (a loud over-decline); a NEW bank
            // manufactured after the mint ⇒ `Bank` with no record ⇒ the `break`
            // below (a loud over-decline). Loud, never silent, but each is still
            // a gap to remove (R1), not a free margin.
            //
            // ⚠ AND THAT DIRECTION ARGUMENT IS THE WHOLE JUSTIFICATION — the
            // injection matrix's mutant M2 (drop this conjunct) is reported
            // MISSED, and it must NOT additionally be justified by claiming no
            // stage between the mint and here can manufacture a bank shape
            // (Rule-13 review item I-6, 2026-09-15). That claim was an
            // ENUMERATION OF STAGES, which is L5's losing move — a syntactic
            // answer to a semantic question — and the window contains
            // `foldIdentityBitcasts`, `promoteFp80Union`, the
            // `flattenPredMuxRegions` fixpoint, `unrollConstTripLoops`,
            // `recognizeCtlzIdiomLoops` and `detectSpecializations`, at least
            // one of which (PredMux) exists to turn conditional control flow
            // into straight-line code — the very transformation that would turn
            // a `BankRaw`/`Reject*` shape into a `Bank` one. NOBODY HAS
            // CONSTRUCTED SUCH A MODULE and this comment does not claim one
            // exists. What it claims is enough and is checkable: dropping the
            // conjunct fails SILENTLY (a `Bank` with no record accepts a store
            // whose loads were never tainted), and keeping it fails LOUDLY in
            // the over-decline direction. That asymmetry, not unreachability,
            // is why the conjunct stays and why M2 is a deliberate MISSED.
            if (isRailBankAlloca(BShape.Alloca))
              continue;
            break;  // `Bank` but UNMARKED — keep the generic kMsgStore.
          case RailBankCarve::BankRaw:
            // The promoter's INPUT shape (C7 failed). It is NOT a decline of its
            // own — every clause C1–C6 held and `BMsg` is null — so it takes the
            // same generic `kMsgStore` it would have taken anyway, and the corpus
            // sees a byte-identical diagnostic. What changes is only the anchor,
            // and the anchor is the point: it is the observable that says *"this
            // bank is NOT the one the type rewrite may have"*.
            if (::getenv("CQ_CTRL_DBG")) {
              llvm::errs() << "CQ_CTRL_DBG: railbank [BankRaw] cells=";
              if (BShape.RuntimeSized)
                llvm::errs() << "runtime(" << *BShape.Extent << ")";
              else
                llvm::errs() << BShape.Count;
              llvm::errs() << " abi=" << BShape.ElemAbi << " trips=";
              if (BShape.RuntimeSized)
                llvm::errs() << "runtime";
              else
                llvm::errs() << BShape.Trips;
              llvm::errs() << " at: " << *BankSI << "\n";
            }
            break;  // ⚠ MUST STAY A BREAK FOREVER — see the L8 note above.
          case RailBankCarve::RejectShape:
          case RailBankCarve::RejectIndex:
          case RailBankCarve::RejectWidth:
          case RailBankCarve::RejectAlias:
          case RailBankCarve::RejectTotality:
            diagnoseEscape(&I, BMsg);  // per-clause decline; opt non-zero.
            continue;
          case RailBankCarve::NotBank:
            break;  // not a rail-bank cell write — generic decline, unmoved.
          }
          }  // if (!LInfo->empty())
        }
        // 4b. `freeze` (Phase-7.1 Increment B) — a basis-level identity. The
        //     accept is NARROW (R-B): an FP freeze is SKIPPED so the GATE-3
        //     carrier fence (SelectClassify, runs at detection) catches an angle
        //     routed through it (`control_swap_reject_select_freeze.ll`); a pure
        //     LOCAL INTEGER identity freeze is FOLDED away below (no standing
        //     freeze ⇒ no FreePoint `unrecognized-user` reject, no whole-DAG
        //     uncompute interaction). ANY OTHER freeze — an integer freeze whose
        //     operand is independently Escaped/Measured or whose result would
        //     escape after the fold (the laundering hazard), or a vector/
        //     aggregate freeze — falls through to the kMsgOther decline
        //     (`lowering_reject_freeze_escaped_return.ll`,
        //     `lowering_reject_freeze_measured_fanout.ll`). Default-to-decline
        //     (Prime Directive) on every unproven shape.
        if (auto *FI = dyn_cast<FreezeInst>(&I)) {
          if (FI->getType()->isFPOrFPVectorTy())
            continue;  // rides the GATE-3 carrier fence (no escape, no fold).
          if (isLocalIntegerIdentityFreeze(FI, taint)) {
            FoldFreezes.push_back(FI);
            continue;
          }
          // integer-but-escaping / vector / aggregate ⇒ fall through to decline.
        }
        // 5. Unowned readers of a tainted value. A store exits the SSA-only
        //    taint domain into memory (a later load reads the handle tag,
        //    untainted); everything else (getelementptr, atomicrmw, freeze,
        //    va_arg, ...) has no reversible-lowering story at all. Both are
        //    bypassed by the Phase-5 net when the handle is ALSO measured
        //    (FreePoint returns Measured before its FirstUnrecognized check),
        //    so the decline must happen HERE, pre-lowering.
        diagnoseEscape(&I, isa<StoreInst>(I) ? kMsgStore : kMsgOther);
      }
    }
  }

  // Phase-7.1 Increment B: fold the proven basis-level identity freezes. RAUW
  // each `%f = freeze iN %h` to its `%h` (the freeze of a defined runtime i32
  // handle is the handle), scrub it from the taint set (`SwapRouteEmit::scrubTaint`
  // precedent — a freed Instruction* must not linger in `Tainted` where a later
  // allocation could alias it; belt-and-braces since bd 8e5r: every TaintSet table drops a deleted key by itself, `ScrubOnDelete.h`), and erase. The downstream measure/return/uncompute
  // analyses then see the TRUE handle lineage (the standing freeze would otherwise
  // read as an unrecognized FreePoint user). Done AFTER the walk so no erasure
  // invalidates the BB iterator above.
  for (FreezeInst *FI : FoldFreezes) {
    Value *H = FI->getOperand(0);
    FI->replaceAllUsesWith(H);
    taint.Tainted.erase(FI);
    FI->eraseFromParent();
  }

  // ── bd `xdu2` / L-1a W1 PIECE 3 — THE D5 CONSUMER ALLOW-LIST.
  //
  // LAST inside this guard, deliberately, and for the reason bd `br4a` makes a
  // rule of: `LLVMContext::diagnose` EXITS on the first `DS_Error`, so "last"
  // means "every owner with a more precise message goes first" — a bank whose
  // STORE is still refused (a `Bank` the record was never minted on, or a
  // `Reject*` clause) keeps its own per-clause string, unmoved.
  //
  // It is a POSITIVE allow-list and never a deny-list, because a rail parked in
  // memory is invisible to every SSA-shaped fence in the tree: `railWireClosure`
  // has no memory hop and MUST NOT BE TAUGHT ONE (that trips
  // `f2SeedPinnedByLiveRegister`'s retirement trigger and forces a from-scratch
  // re-derivation of the F2 narrowing), and the rail/wire/uncompute machinery is
  // MEMORY-BLIND by construction (`SCOPE_L1a.md` §4.1). So the refusal lives
  // here, on an enumerated list of consumers, and every other consumer declines.
  //
  // ⚠ LIVING INSIDE `declineTaintEscapes` BUYS THE ROUND-2 RE-ASK FOR FREE
  // (L1's PREDICATE species): `adjudicateTaintDelta` and
  // `repropagateControlMerges` both call this guard, so a bank load that only
  // becomes reachable after the control fixpoint is asked the same question
  // again, with nothing new to remember.
  declineUnallowedRailBankReaders(M, taint);
}

namespace {

// The exact diagnostic strings the classical-mux guard owns
// (test_C_libtooling-wi5). The negative fixtures mirror each one
// CHARACTER-FOR-CHARACTER (Rule 12):
//   * lowering_reject_classical_mux_select_measured.ll     → kMsgClassicalSelect
//   * lowering_reject_classical_mux_select_escape.ll       → kMsgClassicalSelect
//   * lowering_reject_classical_mux_select_alltainted_main.ll
//                                                          → kMsgClassicalSelect
//   * lowering_reject_classical_mux_phi_measured.ll        → kMsgClassicalPhi
constexpr char kMsgClassicalSelect[] =
    "cq taint escape: tainted value muxed by a classical-condition select";
constexpr char kMsgClassicalPhi[] =
    "cq taint escape: tainted value muxed by a classical-condition phi";

// ───────────────────────────────────────────────────────────────────────────
// One-register merge-phi lift (test_C_libtooling-5j5; N-ary generalized in
// test_C_libtooling-sbt1.3, Phase 7.1 Increment C).
//
// The natural "classical if around a quantum gate" program
//     if (classical_c) cq_theta(&q, theta);  ...use(q)...
// survives `clang -O1` as a merge phi whose two incomings are DISTINCT SSA
// values denoting the SAME physical register:
//     merge: %p = phi i32 [ %q2, %arm ], [ %q, %entry ]   ; %q2 = cq_theta(%q,θ)
// (verified 2026-06-10 on the `if` and ternary forms of the pre-3qlq register
// form `q = cq_phi(q, θ)` — clang cannot speculate the opaque call, so BOTH
// compile to this branch+phi shape, never to a select). The N-ary classical
// `switch` around an in-place gate on the SAME register is the same shape at
// higher arity — N>2 incomings, each a distinct SSA name of the one register's
// per-path record, reconverging at one merge phi; Increment C lifts it by the
// IDENTICAL per-edge argument, with the (7a) reachability proof carried against
// EVERY other edge (not just the single 2-way complement). Rotation lowering is
// IN PLACE: `RotationLowering` emits the gate at the call's position ON THE
// OPERAND HANDLE and RAUWs the result to that same operand (ry-only on the
// existing handle for a tainted-operand chained cq_theta). So after lowering,
// EVERY incoming of such a phi is the same i32 handle — the phi is a pure SSA
// renaming that never touches the register. RAUW'ing it to the wire's base SSA
// value and erasing it reduces the module to the phi-less form the pipeline
// ALREADY accepts (verified pre-3qlq with an rz: gate-in-classical-arm +
// use-of-base lowers to gate-inside-the-arm + measure-on-handle, main and not).
//
// Rule-13 trace/statevector clearance (the accept argument): the condition is
// CLASSICAL — each shot executes exactly one path; no superposed control, no
// flag, no routing, no cloning. The lift adds, moves, and removes NO gate;
// only an SSA name disappears. Per-shot the emitted trace is exactly the gate
// stream of the executed source path (gate fires iff its arm runs), which is
// what the user wrote. The only hazard is a RECORD mismatch — an edge whose
// incoming SSA value denotes a register history that some path entering the
// merge through that edge does not physically have. The predicate below
// makes that impossible:
//   (3) every incoming resolves through the in-place gate wire (arg-0 of
//       COLLECTED cq_theta call sites — exact CallInst membership,
//       never name matching, this is an ACCEPT predicate) to ONE common base;
//       a classical-operand theta MINTS a fresh register, so the walk stops
//       there; template results (add/mul/...) mint fresh rails
//       (`ArithLowering` RAUWs to the template CALL result) and never resolve
//       — a derived-value arm stays declined;
//   (6) every chain gate sits in ITS edge's incoming block, so entering via
//       that edge implies the chain ran, this traversal, in order;
//   (7a) no chain gate can reach ANY OTHER edge's terminator — kills every
//       path that fires the gate and then enters the merge through a different
//       edge claiming a record without it (the loop-iteration-2 stale-base
//       path, fixture lowering_reject_classical_mux_phi_loop.ll; at N>2 the
//       check spans ALL j != i, closing the third-edge hole a naive `1-i`-only
//       extension would leave — lowering_reject_classical_mux_phi_onereg_nway_loop.ll);
//   (7b) the gate's own edge, once taken, can never lead back to the gate —
//       every cycle through the gate exits its block through the checked
//       terminator, so no path applies the chain twice while the incoming
//       claims one application.
// A SELECT is categorically NOT liftable: SSA forces a select's operands to
// dominate it, so a gate-call incoming has ALREADY FIRED unconditionally when
// the select executes — the "untaken" incoming names a pre-gate record the
// physical register no longer holds (undoing an applied rotation on the one
// register is non-unitary; it would need cloning). Accepting it would compile
// "rotate iff c" IR semantics to "always rotate": the exact verify-clean
// silent-miscompile class. Pinned: lowering_reject_classical_mux_select_onereg.ll.
//
// ⚠ THE PROOF IS ONLY AS FINAL AS THE TAINT IT READS — bd test_C_libtooling-d88e
// (P1, found by bd 9bhg's Rule-13 round r1A, F-9A-1). Conjuncts (2) and (3) ask
// `taint.Tainted`, and this lift runs BEFORE `specialize()`. A Phase-6 call
// result `t = h(q, m)` is tainted CONSERVATIVELY by `propagate` (it reads a
// tainted argument — ⚠ since bd cepm only when `predictReturnTainted` says the
// clone MAY return a register: a result predicted classical is never tainted and
// no lift is ever proved over it); if the clone proves `h` returns a classical value,
// `scrubForwardCone` UNTAINTS `t` after this lift has already RAUW'd
// `phi(t, @cq_theta_*(t, θ))` onto it. "One register" was then never true: the arm's
// `@cq_theta_*(t, θ)` lowers as a SOURCE on a fresh rail (`Chained` is decided at
// FINAL taint, RotationLowering.cpp), and the user's `cq_measure` of the erased
// phi reads the classical `t` down the bd 21mg classical-measure path — the
// measurement VANISHED, exit 0, stage-2b clean, on every binary up to `def1b088`.
// The "only hazard is a RECORD mismatch" sentence above is therefore true of a
// FINAL-taint proof and was false of this one. The cure is CLAUDE.md L1's
// standing one: the accept RECORDS its premise (`taint.LiftedMergePhis`) and
// `declineFalsifiedMergePhiLifts` RE-ASKS (2)/(3) at final taint right after
// `specialize()`, declining with THIS guard's `kMsgClassicalPhi` — the hand-
// inlined twin (`int t = m + 1;`) declines at this guard too, since its phi muxes
// a classical value and a register. The VERDICT is the twin's; the STRING and
// site are the twin's when this phi is the module's first classical-mux offender
// on both sides (not otherwise: r1A F-DA-3). Pinned by the
// `lowering_reject_classical_mux_phi_spec_scrubbed_base*.ll` family and its
// accept controls `lowering_classical_mux_phi_onereg_spec_*.ll`.
// ───────────────────────────────────────────────────────────────────────────

// The backward in-place-gate wire resolution: peel collected cq_theta
// call sites through their arg-0 handle while that handle is tainted (a
// tainted-operand rotation is in-place — its result RAUWs to its operand).
// Stops at a classical-operand theta (the register's mint point — the call
// itself is the base), at an ALREADY-ADJUDICATED controlled rotation (see the
// `ControlledRotations` stop below), at any non-gate value
// (phi/select/template/argument), and never steps through another mux (nested
// diamonds resolve to distinct phi bases and decline — conservative,
// documented).
//
// TWO CALLERS (bd test_C_libtooling-d88e; this said "SOLE CALLER" until the
// Rule-13 round r1A F-DA-2 caught it): `liftOneRegisterMergePhi`, and its re-ask
// `declineFalsifiedMergePhiLifts`, which runs after `specialize()` and must
// resolve every recorded incoming EXACTLY as the lift did — that is why both
// take their gate set from `collectLiftGateCalls`. `WireChain::Gates` still has
// exactly ONE reader, the lift's (6)/(7) loop; the re-ask reads only `.Base`.
// ⚠ THE L3-MIRROR QUESTION, asked for the second caller: the three reasons for
// the `ControlledRotations` STOP below are about the lift's RECORD semantics, and
// they hold for the re-ask unchanged because `taint.ControlledRotations` is not
// written between the lift and the re-ask (`specialize()` never touches it; the
// control emitters that write it all ran before `declineClassicalMuxes`), so the
// two calls see the same stop set. RETIREMENT TRIGGER: a stage in that window
// that writes `ControlledRotations`, or a third caller, re-opens this paragraph.
// `LoopLowering::peelInPlaceBase` is the SIBLING spelling of the same walk and
// is deliberately NOT changed by the stop below — see the note at the stop.
struct WireChain {
  Value *Base = nullptr;
  // Gate calls peeled, incoming-value-first. Empty when the incoming IS the
  // base (the pre-gate straight edge, or the degenerate same-value merge).
  SmallVector<CallInst *, 4> Gates;
};

WireChain resolveWireBase(Value *V, const SmallPtrSetImpl<CallInst *> &GateCalls,
                          const TaintSet &taint) {
  WireChain Chain;
  while (auto *CI = dyn_cast<CallInst>(V)) {
    if (!GateCalls.count(CI))
      break;  // not a collected rotation call site — V is the base.
    // An ALREADY-ADJUDICATED CONTROLLED rotation is a STOP, not a peel step:
    // its result IS the base (bd test_C_libtooling-drbq Increment 3, round-1
    // Rule-13 review finding F-L5-1; fixture
    // control_inplace_ry_lifted_phi_after_region.ll).
    //
    // Three independent reasons, and the FIRST is the one that makes this an
    // ACCEPT predicate rather than a convenience:
    //  (i) A recorded rotation is UNCONDITIONAL IN THE CFG. `SwapRouteEmit`
    //      HOISTS the arm gate into the region's pred and `AngleSelectEmit`
    //      leaves the consuming rotation where it stood; the conditionality is
    //      QUANTUM, carried by the `taint.ControlledRotations` flag operand,
    //      never by a branch. So it executes on every path into any join below
    //      it — which is exactly the obligation clauses (6)/(7a) discharge for
    //      an edge-local gate, discharged here by domination instead. Peeling
    //      it as if it were an edge gate then FAILS (6) (it is never in the
    //      join's incoming block) and FAILS (7a) (it reaches every other edge),
    //      so a shape whose per-path records are provably consistent declined.
    // (ii) Its OPERAND names a record the register no longer holds — that is
    //      the whole Inc-1 freeze / R6 staleness class. Peeling past it would
    //      make the lift RAUW every consumer onto a STALE name, which
    //      `declineLiftedStaleRecordOps` then has to catch. Stopping hands the
    //      consumers the post-region name, which is what they physically read.
    // (iii) It is a gate ANOTHER OWNER already proved (`ControlDetect` +
    //      `ArmClassify` R1–R7 / `classifyAngleSelect` S1–S10, then the region
    //      emitter). Re-opening its record question here is the sibling-spelling
    //      hazard bd [[sibling-predicate-spelling-is-the-hole]] warns about.
    //
    // ⚠ THE SIBLING WALK IS DELIBERATELY DIFFERENT AND MUST STAY SO.
    // `LoopLowering::peelInPlaceBase` peels THROUGH a hoisted controlled Ry on
    // purpose — under M-β that is precisely how `collapseRailPhisIn` sees the
    // gate as a rail chain member (notes §3). The two walks ask different
    // questions: `peelInPlaceBase` asks "which physical RAIL is this?", and the
    // answer is unchanged by a gate; `resolveWireBase` asks "which RECORD does
    // this name denote?", and a gate changes that. Do not "unify" them.
    if (taint.ControlledRotations.count(CI))
      break;
    Value *Handle = CI->getArgOperand(0);
    if (!taint.Tainted.count(Handle))
      break;  // classical-operand theta: the mint point IS the base.
    Chain.Gates.push_back(CI);
    V = Handle;
  }
  Chain.Base = V;
  return Chain;
}

// Defensive ownership check on a terminator: the lift only fires under
// CLASSICAL control. Every tainted-condition br/switch/select was adjudicated
// by ControlDetect before this guard runs (accept → SwapRouteEmit erased the
// merge phi; decline → opt already exited at that DS_Error), so under `opt`
// this never sees a tainted condition — but an in-process host that continues
// past a ControlDetect decline must NOT have this lift mutate a shape another
// owner declined (same defensive stance as the tainted-condition `continue`
// on the select branch below). Exotic terminators (invoke/indirectbr/...)
// are unproven shapes — not acceptable.
bool terminatorIsClassical(const Instruction *T, const TaintSet &taint) {
  if (const auto *BI = dyn_cast<BranchInst>(T))
    return !BI->isConditional() || !taint.Tainted.count(BI->getCondition());
  if (const auto *SI = dyn_cast<SwitchInst>(T))
    return !taint.Tainted.count(SI->getCondition());
  return false;
}

// Try the one-register lift on a LIVE tainted-reading phi. Returns true iff
// the phi was PROVEN a pure renaming of one register's per-path current
// record, RAUW'd to the wire base, scrubbed from the taint set, and erased —
// the caller then has nothing to diagnose. Any unproven branch returns false
// and the caller declines loudly, exactly as before the lift (never silent;
// a valid program declined there is a gap to close, R1).
bool liftOneRegisterMergePhi(PHINode *Phi, TaintSet &taint,
                             const SmallPtrSetImpl<CallInst *> &GateCalls,
                             std::optional<DominatorTree> &DT) {
  // (1) At least the canonical 2-incoming diamond/if-else join (the -O1 shape;
  //     ControlDetect's `soleMergePhi` carries the same discipline). Phase-7.1
  //     Increment C generalizes to N>2: the natural classical N-way `switch`
  //     around an in-place gate on ONE register reconverges at a single merge
  //     phi whose every incoming is the same register's per-path current
  //     record. Each edge is per-edge provable by the SAME argument as the
  //     2-way case — the only delta is that (7a) must hold against ALL other
  //     edges, not just the single complement (see the per-edge loop below).
  //     N==2 reduces EXACTLY to the prior `1-i` logic. A degenerate <2 phi is
  //     not a mux — decline (nothing to lift).
  unsigned N = Phi->getNumIncomingValues();
  if (N < 2)
    return false;
  // (2) Every incoming tainted. A mixed tainted/untainted mux
  //     ("handle-or-literal-5") is a real data mux on the handle domain and
  //     stays declined (pinned: lowering_reject_classical_mux_phi_measured.ll).
  for (Value *V : Phi->incoming_values())
    if (!taint.Tainted.count(V))
      return false;
  // (3) Every incoming resolves to ONE common base. Build all N WireChains up
  //     front (pure analysis — no mutation), then require every
  //     `Chains[k].Base == Chains[0].Base`; a SINGLE off-base edge among N
  //     (distinct register, derived fresh rail) sinks the whole accept — it is
  //     a real data mux, not a renaming. Taint only ever holds Instructions, so
  //     a matching base is an Instruction; the Phi-as-its-own-base degenerate
  //     (self-incoming cycle) is rejected explicitly.
  SmallVector<WireChain, 4> Chains;
  Chains.reserve(N);
  for (Value *V : Phi->incoming_values())
    Chains.push_back(resolveWireBase(V, GateCalls, taint));
  for (unsigned k = 1; k < N; ++k)
    if (Chains[k].Base != Chains[0].Base)
      return false;  // a distinct register or derived fresh rail — real mux.
  if (Chains[0].Base == Phi)
    return false;     // self-incoming cycle — no base register to rename to.
  auto *BaseI = dyn_cast<Instruction>(Chains[0].Base);
  if (!BaseI)
    return false;
  // (4) Dominator tree — built lazily, once per function (same idiom as
  //     `declineStaleRecordOps`).
  Function &F = *Phi->getFunction();
  if (!DT)
    DT.emplace(F);
  // (5) Defensive ownership: the join's deciding branch (the merge's
  //     immediate dominator) and EVERY incoming pred's terminator must be
  //     classical (see terminatorIsClassical — already accepts a classical
  //     `switch`). Unreachable merge → decline.
  DomTreeNode *Node = DT->getNode(Phi->getParent());
  if (!Node || !Node->getIDom())
    return false;
  if (!terminatorIsClassical(Node->getIDom()->getBlock()->getTerminator(),
                             taint))
    return false;
  for (unsigned i = 0; i < N; ++i)
    if (!terminatorIsClassical(Phi->getIncomingBlock(i)->getTerminator(),
                               taint))
      return false;
  // RAUW validity: base must dominate every current phi user. SSA already
  // implies it (base dominates each incoming edge's use point, hence every
  // path into the merge), but the explicit check is cheap insurance.
  if (!DT->dominates(BaseI, Phi))
    return false;
  // (6)+(7) Per-edge conditional-execution proof — see the block comment. All
  // chains were built above; this loop is still pure analysis (no mutation).
  for (unsigned i = 0; i < N; ++i) {
    BasicBlock *Self = Phi->getIncomingBlock(i);
    for (CallInst *G : Chains[i].Gates) {
      // (6) Single-block arm: the whole chain lives in this edge's pred, so
      //     taking the edge implies the chain ran (block-local SSA order).
      //     A chain call OUTSIDE the pred (a pre-branch gate on the wire)
      //     makes the other edges' base records stale — decline (pinned:
      //     lowering_reject_classical_mux_phi_crossblock_chain.ll and its
      //     N-ary sibling _onereg_nway_crossblock_chain.ll).
      if (G->getParent() != Self)
        return false;
      // (7a) GENERALIZED to ALL other edges (Increment C): no path may fire
      //      this gate and then enter the merge through ANY OTHER edge `j`,
      //      whose phi-incoming record omits G. With N>2 there is more than one
      //      "other" edge, so checking only the single `1-i` complement (the
      //      naive 2-way extension) leaves a hole — a gate fired in arm-i could
      //      reach the merge through a THIRD edge j (j!=i, j!=1-i) whose record
      //      lacks it, double-applying / mis-recording after the lift. This is
      //      the primary silent-miscompile guard (pinned:
      //      _onereg_nway_loop.ll — a classical back edge routes arm-i's gate to
      //      the default edge). N==2 reduces this to exactly the prior `1-i`
      //      check (the single j != i IS the complement).
      for (unsigned j = 0; j < N; ++j) {
        if (j == i)
          continue;
        if (isPotentiallyReachable(G, Phi->getIncomingBlock(j)->getTerminator(),
                                   nullptr, &*DT))
          return false;
      }
      // (7b) Once this edge is taken the gate must never re-fire: every cycle
      //      through G leaves its block via this terminator, so this check
      //      closes the applied-twice/recorded-once path.
      if (isPotentiallyReachable(Self->getTerminator(), G, nullptr, &*DT))
        return false;
    }
  }
  // ACCEPT. The phi is a no-op on the handle domain: RAUW to the base (after
  // rotation lowering every incoming IS this base's i32 handle), scrub the
  // erased value from the taint set (`SwapRouteEmit::scrubTaint` precedent —
  // a freed Instruction* must not linger in `Tainted` where a later
  // allocation could alias it; belt-and-braces since bd 8e5r: every TaintSet table drops a deleted key by itself, `ScrubOnDelete.h`), and erase.
  //
  // Witness that a lift OCCURRED (test_C_libtooling-2qyz). The RAUW re-points
  // every consumer onto the wire base, so a sibling Ry re-rotating that base's
  // wire now stales any in-scope op downstream of the (erased) phi — but the
  // stale-record guard (`declineStaleRecordOps`) already ran BEFORE this lift
  // and saw only the opaque PHINode operand (its backward closure stops at a
  // PHINode, and its forward walk from the phi never reaches the base's sibling
  // theta), so it could not adjudicate the now-exposed shape. NOT "every later
  // guard still adjudicates it" — the stale-record guard is an EARLIER guard.
  // The record pushed below flags the lift to the orchestrator, which re-runs
  // the FULL stale-record sweep (`declineLiftedStaleRecordOps`) — since bd d88e
  // AFTER `specialize()` and the re-ask of this lift's own premise, so it only
  // ever adjudicates a lift that survived that re-ask. The sweep is complete,
  // not scoped to the phi's consumers: the genuine stale op may be a TRANSITIVE
  // consumer separated from the phi by in-place-gate hops (chained Ry) — a
  // Rule-13 adversarial finding — so only re-walking every consumer's full wire
  // is sound. (bd ec7r: the witness is the RECORD, i.e. the lift event; the
  // self-cleaning direct-consumer set that used to be the witness is removed.)
  // bd test_C_libtooling-d88e — RECORD the premise (2)/(3) just proved, at the
  // taint it was proved under, so `declineFalsifiedMergePhiLifts` can re-ask it
  // after `specialize()` (see the block comment above). The incomings are not
  // touched by the RAUW below (only the phi's USES are), and every handle is a
  // `WeakTrackingVH`, so the record follows any later RAUW of them.
  {
    TaintSet::LiftedMergePhi Rec;
    Rec.F = Phi->getFunction();
    Rec.DL = Phi->getDebugLoc();
    Rec.Base = Chains[0].Base;
    for (Value *V : Phi->incoming_values())
      Rec.Incomings.emplace_back(V);
    // bd r2j3.11 / dm7f.1 — the PER-USE record (`TaintSet::LiftedMergePhi`), taken
    // BEFORE the RAUW makes a phi read and a base read the same operand.
    for (Use &U : Phi->uses())
      Rec.Uses.push_back({WeakTrackingVH(U.getUser()), U.getOperandNo()});
    // The gates on the phi's per-path record. Each incoming's own chain is exact:
    // (6)/(7) above prove a chain gate fires iff its edge is taken. An EARLIER
    // lift's record is inherited only when EVERY incoming derives from that lift's
    // phi — the incoming WAS the phi (a recorded `(Phi, k)` use), or the chain's
    // bottom gate read it (a recorded `(gate, 0)` use). One edge without the
    // inheritance can enter the merge after the earlier gate fired, on a record
    // that omits it (`int q0 = q; if (c) Ry; if (d) Ry; else q = q0;`).
    SmallPtrSet<Value *, 8> Gates;
    std::optional<SmallPtrSet<Value *, 8>> Inherited;
    for (unsigned K = 0; K < N; ++K) {
      for (CallInst *G : Chains[K].Gates)
        Gates.insert(G);
      SmallPtrSet<Value *, 8> Mine;
      const User *Reader = Chains[K].Gates.empty()
                               ? static_cast<const User *>(Phi)
                               : Chains[K].Gates.back();
      const unsigned Slot = Chains[K].Gates.empty() ? K : 0;
      for (const TaintSet::LiftedMergePhi &E : taint.LiftedMergePhis) {
        if (static_cast<Value *>(E.Base) != Chains[0].Base)
          continue;
        for (const TaintSet::LiftedUse &EU : E.Uses)
          if (static_cast<Value *>(EU.User) == Reader && EU.OpNo == Slot)
            for (const WeakVH &EG : E.RecordGates)
              if (Value *GV = EG)
                Mine.insert(GV);
      }
      if (!Inherited) {
        Inherited.emplace(Mine);
      } else {
        SmallVector<Value *, 8> Drop;
        for (Value *GV : *Inherited)
          if (!Mine.count(GV))
            Drop.push_back(GV);
        for (Value *GV : Drop)
          Inherited->erase(GV);
      }
    }
    if (Inherited)
      Gates.insert(Inherited->begin(), Inherited->end());
    for (Value *G : Gates)
      Rec.RecordGates.emplace_back(G);
    taint.LiftedMergePhis.push_back(std::move(Rec));
  }
  Phi->replaceAllUsesWith(Chains[0].Base);
  taint.Tainted.erase(Phi);
  Phi->eraseFromParent();
  return true;
}

// The ONE spelling of `resolveWireBase`'s gate set: exact `CallInst` membership
// of the collected rotation call sites (an ACCEPT predicate — never a name test).
// Shared by the lift (`declineClassicalMuxes`) and its re-ask
// (`declineFalsifiedMergePhiLifts`), so the two cannot resolve a wire differently.
void collectLiftGateCalls(const TaintSet &taint,
                          SmallPtrSetImpl<CallInst *> &GateCalls) {
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());
}

}  // namespace

void declineClassicalMuxes(Module &M, TaintSet &taint) {
  // BB-order walk, one diagnostic per offending mux (deterministic order,
  // same discipline as declineTaintEscapes). Runs AFTER `lowerControlRegions`:
  // every tainted-condition construct has already been adjudicated by
  // ControlDetect (declined → opt exited at that first DS_Error; accepted →
  // SwapRouteEmit RAUW'd + erased + taint-scrubbed the merge phi), so a
  // surviving select/phi over tainted data is CLASSICALLY conditioned, and no
  // later stage owns it — decline loudly (Prime Directive). Confirmed silent
  // pre-guard for all five bypass shapes: base-also-measured, base-escaped
  // (`ret`), `main`-resident, non-terminal base, and the all-tainted
  // distinct-handle mux (which rules out the "mixed-incomings-only" variant
  // of this guard — see the wi5 trail).
  //
  // ONE deliberate accept (test_C_libtooling-5j5): the live merge PHI that is
  // a proven pure renaming of ONE register's per-path current record — the
  // natural `if (classical_c) cq_theta(&q, θ); use(q)` shape — is RAUW'd to
  // its wire base and erased (see liftOneRegisterMergePhi above for the full
  // predicate and the Rule-13 clearance). ⚠ That accept is proved at PRE-
  // `specialize()` taint and is PROVISIONAL until `declineFalsifiedMergePhiLifts`
  // re-asks it after the scrub (bd test_C_libtooling-d88e) — a base that turns
  // out classical makes the accept this guard's decline after all, with this
  // guard's string. Selects are NEVER lifted: a select's
  // gate-call incoming dominates it, so the gate has already fired
  // unconditionally and the untaken incoming names a record the register no
  // longer holds.
  SmallPtrSet<CallInst *, 32> GateCalls;
  collectLiftGateCalls(taint, GateCalls);
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Built lazily, only when a lift candidate exists in `F` (same idiom as
    // declineStaleRecordOps).
    std::optional<DominatorTree> DT;
    for (BasicBlock &BB : F) {
      // early-inc: an accepted phi is erased mid-walk.
      for (Instruction &I : llvm::make_early_inc_range(BB)) {
        if (auto *Sel = dyn_cast<SelectInst>(&I)) {
          // Tainted condition → ControlDetect's, never ours (defensive: under
          // opt the earlier "select under quantum control" decline already
          // exited; an in-process host that continues past it must still not
          // see a second owner claim the same shape).
          if (taint.Tainted.count(Sel->getCondition()))
            continue;
          if (taint.Tainted.count(Sel->getTrueValue()) ||
              taint.Tainted.count(Sel->getFalseValue()))
            diagnoseEscape(Sel, kMsgClassicalSelect);
          continue;
        }
        if (auto *Phi = dyn_cast<PHINode>(&I)) {
          // A DEAD phi is a pure live-range extender (no reader → no mux →
          // nothing downstream can read the wrong value): FreePoint's pinned
          // benign-merge domain (isBenignLiveRangePhi; ACCEPT fixture
          // lowering_uncompute_branch_botharms.ll).
          if (Phi->use_empty())
            continue;
          if (!readsTaintedValue(*Phi, taint))
            continue;
          // The one-register renaming lifts (RAUW + erase); every other live
          // tainted-reading phi — mixed handle/literal, distinct registers,
          // derived fresh-rail incomings, cross-block chains, loop-reachable
          // merges — is declined: its record/uncompute story is
          // path-dependent and unproven.
          if (liftOneRegisterMergePhi(Phi, taint, GateCalls, DT))
            continue;
          // ── bd `test_C_libtooling-zujr` — THE LOOP-CARRIED HANDLE VARIABLE ──
          //
          // A header φ that `promoteLoopCarriedHandleSeeds` ACTUALLY PROMOTED
          // muxes two `i32` HANDLES — a preheader `cqrt_alloc_<W>(seed)` and the
          // merge `%out` of the previous activation — under the loop's own
          // CLASSICAL exit test. Exactly one incoming is live per trip and WHICH
          // one is a classical fact the hardware already has, so this is a handle
          // VARIABLE, not the no-cloning data mux this guard exists to refuse. The
          // owner's ruling of 2026-09-17: *"the runtime needs nothing — a handle
          // is an `i32` and a loop-carried `i32` is ordinary classical data"*.
          //
          // ⚠ THE SET IS THE PROMOTION'S OWN RECORD OF A MUTATION IT MADE, never a
          // prediction and never re-derived here (Rule 14). That is the whole
          // safety argument for every earlier site in this increment: the
          // structural predicate at the two X1 sites and at clause (c3) only
          // DEFERS, and a φ the promotion refused arrives here UNPROMOTED and
          // declines — loudly, with this same string, as it always did.
          if (taint.PromotedCarriedHandlePhis.count(Phi))
            continue;
          diagnoseEscape(Phi, kMsgClassicalPhi);
          continue;
        }
      }
    }
  }
}

// bd test_C_libtooling-d88e — the RE-ASK of every one-register lift, at FINAL
// taint. Contract in TaintPropagation.h; the defect it closes is in the lift's
// block comment above (`liftOneRegisterMergePhi`).
//
// WHAT IS RE-ASKED, AND WHY ONLY THAT. The lift's conjuncts split by what they
// read. (1) arity, (4) the dominator tree, (6) block membership and (7a)/(7b)
// reachability are STRUCTURAL: nothing between the lift and this slot changes
// the caller's CFG (the only stage between them is `specialize()`, which clones
// callees, retargets call sites in place and scrubs taint; the bd 2qyz re-sweep
// used to sit in between and now runs AFTER this slot). (5) asks that
// every deciding terminator be CLASSICAL, and between the lift and this slot
// taint only SHRINKS on anything a terminator can read: `specialize()`'s one
// `Tainted.insert` re-marks a spec-site result the clone proves QUANTUM, and
// that result was already tainted at propagation (or is the rebuilt call that
// replaced one which was), so a terminator reading it was already refused by
// (5). ⚠ Since bd cepm propagation can leave a result CLASSICAL on the
// predictor's word; a clone that then proves it quantum is refused loudly inside
// `specialize()` (`kMsgPredictedClassicalQuantum`) before this slot, so the
// "already tainted" premise is CHECKED there, not assumed. What CAN move is (2)/(3): the scrub removes taint, and a removed base
// ends the wire walk at the arm's gate (a SOURCE theta) instead of at the base.
// So exactly (2)/(3) are re-run, by CALLING `resolveWireBase` with the same gate
// set (`collectLiftGateCalls`, Rule 14) — never a second spelling of the walk.
//
// THE ENTRY TEST MIRRORS `declineClassicalMuxes`, not the lift. When no recorded
// incoming is tainted any more, the phi (had it survived) is a CLASSICAL phi:
// `readsTaintedValue` is false and the guard skips it, so the twin accepts. The
// only lift that can land there is the DEGENERATE `phi(t, t, …)` (every chain
// empty — any recorded gate is a `cq_theta` result, a never-scrub keep root), and
// RAUW'ing it to `t` is exact at any taint. Pinned by
// `lowering_classical_mux_phi_onereg_spec_scrubbed_base_degenerate.ll`.
//
// A NULLED HANDLE DECLINES. An incoming or the base erased without a RAUW has no
// question left to re-ask; nothing in the window erases a lifted phi's base or
// its incomings (the gates are `cq_theta` calls, alive until `lowerRotations`),
// so this is the Prime-Directive default for an argued-unreachable state, not a
// shape any fixture can reach (Rule 12 can supply none).
bool declineFalsifiedMergePhiLifts(Module &M, const TaintSet &taint) {
  if (taint.LiftedMergePhis.empty())
    return false;
  SmallPtrSet<CallInst *, 32> GateCalls;
  collectLiftGateCalls(taint, GateCalls);
  for (const TaintSet::LiftedMergePhi &L : taint.LiftedMergePhis) {
    // `L.F` is a `WeakVH` (bd 8e5r x d88e, r1B F-EB-1): the accept records
    // `Phi->getFunction()`, and nothing in the window erases a Function, so it is
    // non-null on every path this pass has. A NULL one means the recorded function
    // was deleted: the premise has no question left to re-ask, so it DECLINES
    // like a nulled Base/Incoming, anchored on the first defined function (a
    // diagnostic needs one). ⚠ Argued unreachable; Rule 12 can supply no fixture.
    auto *Fn = cast_or_null<Function>(static_cast<Value *>(L.F));
    if (!Fn) {
      for (Function &G : M)
        if (!G.isDeclaration()) {
          Fn = &G;
          break;
        }
      if (!Fn)
        return false;  // no defined function left: nothing can be lowered
      Fn->getContext().diagnose(
          DiagnosticInfoUnsupported(*Fn, kMsgClassicalPhi, L.DL));
      return true;
    }
    Value *Base = L.Base;
    bool Falsified = !Base;
    SmallVector<Value *, 4> Ins;
    for (const WeakTrackingVH &H : L.Incomings) {
      Value *V = H;
      if (!V)
        Falsified = true;
      else
        Ins.push_back(V);
    }
    if (!Falsified) {
      // `declineClassicalMuxes`' entry test: a phi that reads no tainted value
      // is a classical phi the guard never asks about.
      bool AnyTainted = llvm::any_of(
          Ins, [&](Value *V) { return taint.Tainted.count(V) != 0; });
      if (!AnyTainted)
        continue;
      for (Value *V : Ins) {
        // (2) every incoming still tainted; (3) still ONE base, the recorded one.
        if (!taint.Tainted.count(V) ||
            resolveWireBase(V, GateCalls, taint).Base != Base) {
          Falsified = true;
          break;
        }
      }
    }
    if (!Falsified)
      continue;
    // The erased phi's own diagnostic: `diagnoseEscape(Phi, kMsgClassicalPhi)`
    // spelled from the recorded function and `!dbg`.
    Fn->getContext().diagnose(
        DiagnosticInfoUnsupported(*Fn, kMsgClassicalPhi, L.DL));
    return true;
  }
  return false;
}

namespace {

// yn71 (Phase 4×6, the CONTROL case) — RE-DETECT + emit onward tainted control on
// a re-seeded control-merge `%out`. REPLACES dugh's blanket
// `declineReClassifiedControl`: a downstream `br`/`switch`/`select` whose
// condition is a `%out` derivation was CLASSICAL-conditioned at round-1 detection
// (the merge was data-untainted then), so `detectControlRegions` (step 183)
// skipped it and it survived round-1 flattening. The second propagation just
// tainted its condition, making it a genuinely NEW tainted-control region —
// indistinguishable from the tainted-condition diamond/if-else/switch/select the
// SAME machinery already lowers (a re-seeded `%out` handle is a tainted quantum
// handle exactly like a fresh `cq_theta` one). This is the physics-valid "quantum
// data used as further quantum control" case dugh over-declined (over-decline is
// safe, so shipping it as this bead's real lowering; Rule 17 build-the-intent).
//
// SAFE TO RE-RUN. Round-1's accepted regions are already flattened (their tainted
// `br`/`switch` erased) or RAUW'd+erased (the emitted `select`); round-1's
// declines already exited `opt`. So the ONLY tainted-condition construct visible
// here is a new downstream one on `%out`. `detectControlRegions` is pure analysis
// by SSA identity (fresh `ControlPlan`+`Claimed` per call, no cached block
// pointers across erasures — Rule 9) and is the DECLINE AUTHORITY: any tainted
// control it cannot prove fires its precise per-shape diagnostic (`opt` exits
// non-zero), so the "accept the known phase/value/select/switch shapes, decline
// the rest loudly" contract holds with ZERO new decline logic (Rule 14 reuse).
//
// FIXPOINT (mirrors the g387 by-ref / 0vvq spec fixpoints in this same function).
// Two accepted region kinds — the 6.5 classical-call arm and the 4.5 switch
// data-mux — build a NEW `%out2` rail that may itself feed a further onward
// control. Re-seed `propagateWorklist` from the WHOLE live `taint.Tainted`
// (`skipRuntimeCalls=true` — never re-taint the emitter's own `cqrt_*`/
// `cq_template_*` scaffolding, so uncompute parity with a round-1 rail is kept)
// after each `lowerControlRegions`, so the next iteration adjudicates the
// cascaded region. Seeding from the whole set (not just the new rails) is
// required: the rail is already tainted, so a rails-only re-seed would not
// re-visit its downstream (the g387 by-ref re-seed uses the full set for the same
// reason). TERMINATES: each non-empty plan emits ≥1 region and every emit REMOVES
// exactly one tainted-condition construct (`RegionFlatten` erases the
// `br`/`switch`; `emitSelectRegion` erases the `select`) while creating none, so
// the finite construct count strictly decreases; a single-level onward control
// runs two iterations (emit, then confirm empty).
//
// THE CASCADE IS NATURALLY SEQUENCED. When an upstream region is adjudicated, the
// downstream (cascaded) region's condition is still CLASSICAL (its rail does not
// exist until the upstream emits + the next re-propagation runs), so
// `recoverRegion`'s `hasTaintedCondBranch(merge)` sequential/nested guard does not
// fire on it and it lowers on the following iteration. Two SAME-source siblings
// `if(%out>k1)…; if(%out>k2)…` are BOTH tainted in one iteration, so the first's
// merge hosts the second's tainted `br` and `recoverRegion` declines them as
// sequential/nested (the block-lifetime SIGSEGV-family guard, unchanged) — a safe
// over-decline (filed follow-on).
//
// THE RE-FLATTEN HAZARD (Rule 13). The CFG is ALREADY flattened by round-1
// `lowerControlRegions` (step 184). When the downstream diamond's pred is the
// round-1 spliced merge tail (`int y=5; if(q>3) y=f(a); if(y>7) y=cq_phi(y,θ)`,
// pre-3qlq register form; the round-1 merge block ends in `br i1 %c2`), round-1
// `flattenRegion` already re-pointed the downstream merge phi's incoming block
// `Merge → Pred` before erasing `Merge` (the dugh D1 fix
// `replaceSuccessorsPhiUsesWith`, load-bearing for the CLASSICAL 5j5
// `accept_onward_phase_downstream_if` case AND equally for this TAINTED case),
// leaving a clean standalone downstream diamond whose pred is the flattened block;
// round-2 `flattenRegion` handles it with the same discipline (its own D1 fix
// re-points any THIRD region's merge phi). Stress-tested under guard-malloc in the
// Rule-13 sweep.
// p119: the by-ref re-run (frexp/modf/remquo on a round-2 rail) is REMOVED — by-ref
// math is a library-function family, now source-injected, not name-recognized. Only
// the onward tainted-CONTROL re-detect (yn71) remains: a round-2 br/switch/select on
// a merge rail is lowered as a fixpoint (a control emit can expose a further onward
// control). The SPEC case (a round-2 rail feeding a Phase-6 candidate) declines
// cleanly via `declineTaintEscapes` `kMsgUnknownCallee` (round-2 spec detection,
// bead 9paa).
void detectAndLowerOnwardControl(Module &M, WidthDispatch &wd, TaintSet &taint,
                                 const FnSet &ThetaFns, const FnSet &PhiFns,
                                 const FnSet &MeasureFns) {
  while (true) {
    // bd test_C_libtooling-b6ap — THE MULTI-PHI MERGE PEEL, THE ROUND-2 CALL
    // SITE (`MergePhiPeel.cpp`). CLAUDE.md's standing lesson "a stage that runs
    // ONCE has a round-2-FALSE premise" (F-L3-1, F-R1-1, F-B1R2-1) applies to the
    // peel directly: this loop is a SECOND, FULL round of `detectControlRegions`
    // over taint re-seeded from the 6.5/4.5 `%out` rails, so it sees tainted
    // branches round 1 did not. MEASURED customer: probe `p80` — a 6.5
    // classical-call region followed by a FUSED 2-phi diamond whose condition
    // `icmp eq i32 %out, 13` is CLASSICAL at round 1 and tainted here; its
    // one-phi control `p81` already accepts, so the 2-phi wall is the only thing
    // stopping it, and a round-1-only peel would leave it declining with nothing
    // in the suite able to notice.
    //
    // INSIDE the loop, not before it: the loop is a FIXPOINT (a control emit can
    // expose a further onward control), so a call placed before it would cover
    // only the first iteration. The rule is uniform and grep-checkable — the peel
    // is called immediately before EVERY `detectControlRegions` call in the tree
    // (here, `CQLoweringPass::run`, and the second entry point).
    //
    // Idempotent on an unchanged module: after a successful peel the merge holds
    // at most one phi, so the >=2-phi containment gate refuses the same site on
    // the next iteration. It is NOT a no-op to re-call, because each iteration's
    // lowering can create a fresh fused region.
    //
    // ⚠ `Delta = nullptr` HERE, AND IT IS AN INCLUSION ARGUMENT, NOT AN OMISSION
    // (bd b6ap Rule-13 ROUND-1 finding F-B6-1). The peel GROWS TAINT, and its
    // growth must be adjudicated by `adjudicateTaintDelta` — the two ROUND-1 call
    // sites in `CQLoweringPass.cpp` do that themselves. This one does not need to,
    // because its ONLY caller is `repropagateControlMerges` (measured: `grep -rn
    // 'detectAndLowerOnwardControl' ir-pass/src ir-pass/include` = the definition,
    // the forward decl and ONE call site), which snapshots `beforeTaint` at ENTRY
    // — BEFORE this loop — and computes `reseed = UntaintedMergeRails ∪ (Tainted −
    // beforeTaint)` AFTER it. Every value this peel taints is therefore inside
    // that reseed set and is adjudicated by the same `adjudicateTaintDelta` call.
    // If this loop ever gains a second caller, that caller owes the delta.
    //
    // bd `test_C_libtooling-dm7f.5` — the multi-exit `ret` normalization
    // (`ReturnMerge.h`), slot (b), ROUND 2, for the same reason as the peel: a
    // `br` reading a 6.5/4.5 `%out` is classical at slot (a) and tainted only
    // here, and if it reaches two `ret`s, detection would see no merge. Same
    // `nullptr` disposition and the same inclusion argument: the `cq.ret` φ it
    // taints is inserted into `Tainted` inside this loop, so it is part of the
    // `Tainted − beforeTaint` reseed the sole caller adjudicates.
    unifyTaintedReturns(M, taint, /*Delta=*/nullptr);
    peelIndependentMergePhis(M, taint, /*Delta=*/nullptr);
    ControlPlan plan2 = detectControlRegions(M, wd, taint);
    if (plan2.Regions.empty())
      break;  // fixpoint: no new onward control region emitted.
    lowerControlRegions(M, wd, taint, plan2);
    std::vector<Value *> WL(taint.Tainted.begin(), taint.Tainted.end());
    propagateWorklist(WL, ThetaFns, PhiFns, MeasureFns, taint,
                      /*skipRuntimeCalls=*/true);
  }
}

// bd 0vvq (Increment 2) — RE-PLAN a Phase-6 specialization candidate whose FROZEN
// per-arg mask no longer matches the round-2 taint, so its clone lowers the
// round-2-quantum `%out` argument as a QUANTUM operand (a Q+Q / Q+C clone body)
// instead of reading the `%out` qubit-handle tag as a classical `_hl` literal (the
// D2 verify-clean silent miscompile — the handle tag, not the superposed value —
// that dugh's now-deleted `declineReseedIntoFrozenPlan` over-declined).
//
// THE FROZEN PLAN IS THE `Pending` MASK, NOT A BUILT CLONE. `detectSpecializations`
// (step 5) froze each candidate's per-arg mask from round-1 taint and pushed a
// `SpecCandidate{Site, Callee, Mask}` onto `plan6.Pending`; but the DRIVER
// (`specialize`, step 14) that actually clones runs DOWNSTREAM of this second
// propagation. So at re-plan time NO clone exists yet — unfreezing is simply
// UPDATING the Pending candidate's `Mask` before the driver consumes it. There is
// no premature clone to drop and no retarget to redo: the driver clones the
// corrected Q+Q body, and its existing depth-first transitive machinery (6.3)
// specializes any inner call whose argument the wider mask newly taints. `Site` is
// a stable pointer here — `RegionFlatten` `splice`s the merge tail into the pred
// (it MOVES the call, never erases it), the same invariant `shouldSpecialize`
// already relies on.
//
// SOUNDNESS OF THE WIDER MASK. `scanBody` (the body verdict inside
// `classifyCandidate`) is MASK-INDEPENDENT: it proved the WHOLE transitive body is
// straight-line, pure, and built only from in-scope data ops at DETECTION, and
// every such op carries a complete QQ + `unc_qq` grid (opcode_table.yaml), so an
// operand flipped C→Q switches a `cq_template_<op>_<W>_hl` producer to its bare-QQ
// twin `cq_template_<op>_<W>` (both with an `_unc` twin `emitInverseChain`
// reverses) and nothing else changes. The ONE mask-dependent gate is
// `classifyCandidate` step (A): every TAINTED argument must arrive as an i32 handle
// (Rule 15). Round-1-tainted args were already proven i32 (else the candidate is
// not in `Pending`), so the re-plan can only newly FAIL on a NON-i32 reseed arg
// (`f(q, (short)%out)` / `f(q, sitofp %out)`) → loud `kMsgFpAbi`.
//
// SCOPE (Prime Directive). This RE-PLANS an EXISTING `plan6.Pending` candidate
// (proven-Accept at round 1, ≥1 round-1 tainted arg) whose C-masked arg is now a
// reseed value. A call that was NOT a candidate at round 1 (ALL args classical
// then, now reading `%out`) is a round-2 spec DETECTION, out of this increment's
// scope — it stays declined by the re-run `declineTaintEscapes` (`kMsgUnknownCallee`,
// a visible-body callee reading tainted, not carved; tracked follow-on). An
// in-clone construct the clone cannot emit was already declined at DETECTION by the
// mask-independent `scanBody`, so it never entered `Pending`.
void replanReseedSpecialization(TaintSet &taint, WidthDispatch &wd,
                                SpecPlan &plan6,
                                const SmallPtrSetImpl<Value *> &reseed) {
  // Indices of candidates that could NOT be re-planned (loud-declined) — compacted
  // out of `Pending` after the walk so the driver never clones a stale-mask body.
  SmallVector<unsigned, 4> Rejected;
  for (unsigned i = 0, n = plan6.Pending.size(); i < n; ++i) {
    SpecCandidate &Cand = plan6.Pending[i];
    CallInst *Site = Cand.Site;

    // Does the site read a reseed value (`%out` or a `%out`-derivation) as an arg?
    bool ReadsReseed = false;
    for (const Use &Op : Site->args())
      if (reseed.count(Op.get())) {
        ReadsReseed = true;
        break;
      }
    if (!ReadsReseed)
      continue;  // a round-1-only candidate — its frozen mask is still correct.

    // Recompute the mask against the round-2 taint (monotonically ⊇ the frozen
    // `Cand.Mask`: propagation only ADDS taint, so a reseed arg's bit grows).
    SpecMask NewMask = taintArgMask(Site, taint);
    if (NewMask == Cand.Mask)
      continue;  // defensive: a reseed arg was already masked Q (cannot happen — a
                 // reseed value was untainted at round 1, so its bit must grow).

    // Re-classify with the grown mask. `scanBody` is unchanged (the body verdict is
    // mask-independent); the only new gate is step (A)'s per-arg i32 ABI on the
    // newly-tainted reseed args.
    SpecCandidate ReCand{Site, Cand.Callee, NewMask};
    Instruction *Where = nullptr;
    std::string Kind;
    SpecReject Why = classifyCandidate(ReCand, taint, wd, Where, Kind);
    if (Why == SpecReject::Accept) {
      Cand.Mask = NewMask;  // RE-PLAN — the driver clones the Q+Q body transitively.
      continue;
    }
    // Cannot re-plan (a non-i32 reseed arg): decline LOUDLY at the offending
    // instruction (the precise `kMsgFpAbi`, not dugh's generic "under quantum
    // control"), mark it `Diagnosed` so the re-run `declineTaintEscapes` carve
    // renders no second `kMsgUnknownCallee`, and drop it from `Pending` so the
    // driver never clones a stale-mask body (`opt` exits non-zero regardless; the
    // drop keeps the transient IR clean).
    diagnoseReject(Where, Why, Kind);
    plan6.Diagnosed.insert(Site);
    Rejected.push_back(i);
  }
  // Compact `Pending`, dropping the rejected indices highest-first (so the lower
  // indices stay valid across each erase).
  for (unsigned j = Rejected.size(); j-- > 0;)
    plan6.Pending.erase(plan6.Pending.begin() + Rejected[j]);
}

}  // namespace

// bd `test_C_libtooling-b6ap` — see the header for what this is and, more
// importantly, for the MEASURED reason the MULTI-PHI MERGE PEEL needs it.
//
// The FnSet rebuild is `repropagateControlMerges`' idiom verbatim and for its
// stated reason: rebuilding from the collected call sites rather than re-running
// `resolveSources` avoids re-firing the malformed-decl prototype guard (which has
// already fired, and exited, in the first `propagate` if it was going to). Both
// callers run before `lowerRotations`/`lowerMeasures`, so the collected calls are
// intact.
void propagateFromSeeds(TaintSet &taint, ArrayRef<Value *> Seeds,
                        SmallPtrSetImpl<Value *> *Delta) {
  if (Seeds.empty())
    return;
  // The seeds are ALREADY in `Tainted` (the caller decided that), so a pure
  // before/after diff would miss them. Union them in explicitly — the same
  // two-part computation `repropagateControlMerges` performs for its own reseed
  // set (`UntaintedMergeRails` ∪ `Tainted − beforeTaint`).
  // bd 8e5r: a SELF-CLEANING snapshot, not a raw `std::set` copy. A raw copy
  // keeps a member's address after its Value is deleted, and a value tainted
  // LATER at that reused address would then read as "already tainted before" and
  // silently drop out of the delta the caller adjudicates (the L1 obligation).
  TaintedValueSet beforeTaint;
  if (Delta)
    beforeTaint = taint.Tainted;
  FnSet ThetaFns, PhiFns, MeasureFns;
  for (CallInst *CI : taint.ThetaCalls)
    if (Function *Fn = CI->getCalledFunction())
      ThetaFns.insert(Fn);
  for (CallInst *CI : taint.PhiCalls)
    if (Function *Fn = CI->getCalledFunction())
      PhiFns.insert(Fn);
  for (CallInst *CI : taint.MeasureCalls)
    if (Function *Fn = CI->getCalledFunction())
      MeasureFns.insert(Fn);
  std::vector<Value *> Worklist(Seeds.begin(), Seeds.end());
  propagateWorklist(Worklist, ThetaFns, PhiFns, MeasureFns, taint,
                    /*skipRuntimeCalls=*/true);
  if (Delta) {
    Delta->insert(Seeds.begin(), Seeds.end());
    for (Value *V : taint.Tainted)
      if (!beforeTaint.count(V))
        Delta->insert(V);
  }
}

// bd `test_C_libtooling-b6ap`, F-B6-1 — see the header. This is the round-2
// sequence `repropagateControlMerges` below has always run for its own taint
// delta, lifted out VERBATIM (same functions, same order, same arguments) so a
// second taint-growth customer cannot grow a second spelling of it (Rule 14).
//
// ⚠ FIVE CALLS, NOT FOUR — bd b6ap Rule-13 ROUND-2 finding F-B6R2-1. The
// enumeration this function shipped with was "the stages that adjudicate
// CONSUMERS of tainted values", and `foldIdentityBitcasts` is one it missed: it
// is the SOLE handler for a same-width int<->int `bitcast` and it folds ONLY a
// bitcast that is ALREADY `taint.Tainted` at its pipeline slot (wired first in
// BOTH entry points, `CQLoweringPass.cpp`), so one made tainted by a LATER
// taint-growth stage is left STANDING and dies at `no template for opcode
// 'bitcast i32' in tainted context` — while the hand-peeled twin of the same
// module lowers at exit 0 on BOTH binaries (probe `BC1`). An OVER-decline, never
// a wrong unitary, and hand-IR-only (`clang -O1` folds an i32->i32 bitcast long
// before the pass sees it) — but it falsifies this increment's stated contract,
// "produce the module the hand peel already is".
//
// It is CALL 1 — it runs FIRST, for the SAME reason it is wired first in both
// entry points: a standing identity node blinds the bespoke provenance/lineage
// walks the four stages below run, and one of those walks is the stale-record
// guard's own chained-theta hop (call 5). Folding after them would leave each of
// those walks looking at exactly the opaque node bd `iw81.1` exists to remove.
//
// MONOTONE AND IDEMPOTENT, which is what makes a fifth call free. The fold only
// ever RAUWs `result === operand` and erases a no-op, so it adds no taint, emits
// no gate, and can move no accept/decline of its own; over a LARGER `Tainted` it
// folds a SUPERSET of what the pipeline-slot run folded; and a second run over an
// unchanged delta finds nothing left to fold. The `delta.empty()` early return
// above still contains it entirely — a module that peeled nothing never reaches
// this line, which is what keeps the pre-existing corpus byte-identical.
void adjudicateTaintDelta(Module &M, WidthDispatch &wd, TaintSet &taint,
                          SpecPlan &plan6,
                          const SmallPtrSetImpl<Value *> &delta) {
  if (delta.empty())
    return;
  // ⚠ The fold ERASES instructions, and `delta` is a `Value *` set the two
  // specialization calls below read as a DIRECT-ARGUMENT membership test. A
  // folded bitcast that is itself IN the delta (the `BC1` shape exactly: `%bc`
  // is tainted only BY the peel, so the walk put it there) would leave a freed
  // pointer as a live key — the bd `drbq` Inc-1 defect verbatim, and the one
  // dangling-key instance this increment actually creates. So the fold is handed
  // a LOCAL COPY to scrub, and the copy is what the spec calls consume. No
  // coverage is lost by the scrub: a tainted bitcast's OPERAND is tainted too
  // (`propagateWorklist` taints users, so the operand precedes it in the very
  // same walk) and the RAUW makes every consumer read the operand, which is
  // still in the delta.
  //
  // ⚠ AND THE SAME QUESTION ONE LEVEL OUT, because this call makes a sequence that
  // was PURE ANALYSIS (bar the `freeze` fold) into one that ERASES INSTRUCTIONS at
  // a NEW program point: what else could still be naming the bitcast it deletes?
  // The answer is "nothing", and the reason is ONE property — the fold only ever
  // erases a value that is TAINTED. Every structure live here either (i) is
  // scrubbed by the fold itself (`taint.Tainted`, `taint.HandleWidth`, and now the
  // caller's delta); or (ii) holds only EMITTER-CREATED `cqrt_*` / `cq_template_*`
  // calls (`ControlOwnedRails`, `OutputRails`, `GraveyardRails`,
  // `UntaintedMergeRails`, `SharedCondFlags`, `ControlledRotations`); or (iii)
  // holds only CLASSICAL values (`BreakRegions`' `BoundLimit`/`CounterPhi` — a
  // tainted bound is Q1-declined before this point); or (iv) is typed so a
  // `BitCastInst` cannot enter it (`CallInst *` / `StoreInst *` / `BasicBlock *`
  // containers, `InPlaceRailOps`' `add`/`xor`); or (v) is empty here
  // (`LiftedConsumers`, removed since bd ec7r — `declineClassicalMuxes` runs after BOTH peel sites;
  // `StaleDeclined` — reaching this line at all means no stale decline fired, and
  // a `DS_Error` is final). The full row-by-row version of this table, measured
  // over 194 φ erasures, is `IMPL_b6ap.md` §2d.
  SmallPtrSet<Value *, 32> live(delta.begin(), delta.end());
  foldIdentityBitcasts(M, taint, &live);
  replanReseedSpecialization(taint, wd, plan6, live);
  detectSpecializations(M, taint, wd, plan6, &live);
  declineTaintEscapes(M, taint, plan6);
  declineStaleRecordOps(M, taint);
  // (bd test_C_libtooling-3d8q) THE STALE-READER ANALYSIS, DELTA-SCOPED. Every
  // taint-GROWTH event owes the L1 question, and for the reader fence the answer
  // is: ask it only of the values that just BECAME tainted. A reader seeded on a
  // peel's mux out-rail or a 6.5/4.5 merge `%out` is invisible at round 1 (its
  // operand is classical there) and is a genuine member of the P1 class; a
  // FULL re-sweep here would instead decline 9 shipped in-loop ACCEPTS, because
  // `lowerLoops` has already collapsed the rail φ these fixtures' freshness
  // proof rests on. The diagnostic stays deferred to the late slot either way.
  recordStaleQuantumReaders(M, taint, &live);
}

void repropagateControlMerges(Module &M, WidthDispatch &wd, TaintSet &taint,
                              SpecPlan &plan6) {
  // ⚠ `empty()` counts LIVE rails only (bd 8e5r, r1A F-EA-8): it is empty here
  // only if every recorded `%out` is gone — and then there is nothing left to
  // re-propagate FROM, so the early return is still right.
  if (taint.UntaintedMergeRails.empty())
    return;  // no 6.5 classical-call arm / 4.5 switch data-mux region emitted.

  // bd 3qlq Inc 1, Rule-13 ROUND-2 finding F-R1-1 — the SNAPSHOT the onward
  // loop-rail pass at the end of this function needs. Taken HERE, before
  // `detectAndLowerOnwardControl` grows the set, so the difference is exactly
  // "the loops round 2 opened".
  //
  // ⚠ SELF-CLEANING, LIKE THE TABLE IT SNAPSHOTS (bd test_C_libtooling-jct8,
  // Rule-13 r1A F-EA-1 — the L2 question the `beforeTaint` snapshots below
  // already answered). A round-2 flatten can erase a recorded `Pred`. The live
  // `taint.InLoopFlattenedPreds` drops a deleted block and RESETS the count of a
  // fresh block recycled at its address; a RAW snapshot kept the dead block's
  // round-1 count, so a new Pred at that address compared `1 <= 1` and the
  // onward pass SKIPPED the loop. This comment used to call that skip "the leak,
  // i.e. the safe direction" — FALSE (L7): F-R1-1 below measured exactly that
  // skip as a rolled-vs-unrolled divergence whose per-trip which-path rails
  // leaked. With a `ScrubMap` snapshot the dead block is absent on both sides
  // (live 1 against snapshot 0), so the loop is re-offered. Argued unreachable
  // today (no stage creates a BasicBlock between here and the onward pass —
  // `LoopLowering.cpp`'s creator census); reproduced deterministically in a unit
  // probe (`review_r1A_8e5r/probes/round1_snapshot_asym.cpp`).
  //
  // A COUNT SNAPSHOT since bd 3qlq Inc 1's SECOND C-1 review round (F-C1-2(2b)):
  // the delta the onward pass wants is "did round 2 emit a region into this
  // block?", and as a SET of blocks it could not see the commonest mixed shape —
  // round 2's onward region flattens into the SAME `Pred` a round-1 region
  // already used, so membership does not move and the loop is never re-offered
  // (MEASURED on `p/r40_onward_r1open.c`: one `[DBG] loop hdr=` line, `round2=0`,
  // while every per-trip which-path rail leaked).
  ScrubMap<const BasicBlock *, unsigned> Round1FlattenedPreds =
      taint.InLoopFlattenedPreds;

  // Rebuild the theta/phi/measure FnSets from the collected intrinsic call sites
  // (needed by the shared work-list loop's angle / measure-sink rules). NOT a
  // re-`resolveSources`: that would re-run the malformed-decl prototype guard —
  // already fired (and exited) in the first `propagate` if it was going to. The
  // collected calls are intact here (this runs before `lowerRotations`/
  // `lowerMeasures`; the two emitters scrub only the erased merge PHINode, never a
  // theta/phi/measure call).
  FnSet ThetaFns, PhiFns, MeasureFns;
  for (CallInst *CI : taint.ThetaCalls)
    if (Function *Fn = CI->getCalledFunction())
      ThetaFns.insert(Fn);
  for (CallInst *CI : taint.PhiCalls)
    if (Function *Fn = CI->getCalledFunction())
      PhiFns.insert(Fn);
  for (CallInst *CI : taint.MeasureCalls)
    if (Function *Fn = CI->getCalledFunction())
      MeasureFns.insert(Fn);

  // 1. Incremental forward propagation from the merge out-rails (already in
  //    `Tainted`). `skipRuntimeCalls=true`: never re-taint the emitter's own
  //    cqrt_copy scaffolding (uncompute parity). Idempotent for a rail whose
  //    merge was already tainted (its onward users are already in `Tainted`).
  //    Snapshot the round-1 taint FIRST so the round-2 reseed set (the merge
  //    rails + everything the propagation newly taints) is recoverable — the
  //    Phase-6 spec guard below needs it. `%out` itself is pre-tainted by the
  //    emitter (so it is in the snapshot, not the diff), so union in the rails.
  // bd 8e5r: self-cleaning, for the reason given at `propagateFromSeeds` — the
  // reseed delta below is `Tainted − beforeTaint`, and a raw copy would exclude
  // a value newly tainted at a reused address from it.
  TaintedValueSet beforeTaint = taint.Tainted;
  std::vector<Value *> Worklist(taint.UntaintedMergeRails.begin(),
                                taint.UntaintedMergeRails.end());
  propagateWorklist(Worklist, ThetaFns, PhiFns, MeasureFns, taint,
                    /*skipRuntimeCalls=*/true);

  // p119: the bd-0vvq by-ref-math UNFREEZE on a round-2 `%out` is REMOVED — by-ref
  // math (frexp/modf/remquo) is a library-function family, now source-injected, not
  // name-recognized. A merge-fed un-injected by-ref call declines cleanly via
  // `declineTaintEscapes` `kMsgUnknownCallee`. `declineReseedIntoFrozenPlan` below is
  // spec-only.

  // yn71 (Phase 4×6, CONTROL case): RE-DETECT + emit a NEW tainted-condition
  // br/switch/select on the merge as a FIXPOINT, instead of dugh's blanket decline.
  // `detectControlRegions`/`lowerControlRegions` (the same machinery step 183/184
  // run) lowers the known phase/value/select/switch shapes and declines the rest
  // loudly itself (it is the decline authority — see `detectAndLowerOnwardControl`).
  //
  // Runs BEFORE the reseed computation + spec re-plan/re-detect below — the bd afmv
  // ORDERING FIX. yn71's `detectAndLowerOnwardControl` builds NEW `%out2` control
  // rails (a downstream `if(%out>k)` classical-call arm / switch data-mux) that are
  // genuine i32 quantum handles and taints them + their downstream. A Phase-6 spec
  // candidate reading a `%out2` rail must be in the round-2 reseed domain so the
  // re-plan/re-detect below either re-widen its mask to bare-QQ or loud-decline it —
  // otherwise a ROUND-1 `Pending` candidate whose arg is a `%out2` rail keeps its
  // stale (frozen) mask and the step-262 driver clones it reading the superposed rail
  // as an `_hl` classical literal (`cq_template_mul_i32_hl(q, %out2)` = q × the rail's
  // handle-TAG, a verify-clean wrong unitary, bd afmv). Computing `reseed` AFTER this
  // (so it captures the `%out2` rails) is exactly what closes that hole.
  detectAndLowerOnwardControl(M, wd, taint, ThetaFns, PhiFns, MeasureFns);

  // Round-2 reseed set — computed AFTER the by-ref re-run AND the yn71 control
  // fixpoint, so it captures the WHOLE round-2 taint delta: the merge out-rails, the
  // by-ref markers, AND the yn71-produced `%out2` control rails + everything they
  // taint. `UntaintedMergeRails` has grown to include the yn71 rails (the 6.5/4.5
  // emitters record every `%out` they build); `Tainted − beforeTaint` captures their
  // derivations. This POST-fixpoint computation is the bd afmv fix (see above).
  SmallPtrSet<Value *, 32> reseed(taint.UntaintedMergeRails.begin(),
                                  taint.UntaintedMergeRails.end());
  for (Value *V : taint.Tainted)
    if (!beforeTaint.count(V))
      reseed.insert(V);

  // 2. RE-PLAN a FROZEN-PLAN Phase-6 spec candidate (the SOLE remaining frozen-plan
  //    owner after 0vvq Inc 1 re-ran by-ref math above) whose per-arg mask was fixed
  //    pre-emit and no longer matches a round-2-quantum argument: recompute the mask
  //    (Q+Q) so the step-262 driver clones a body that reads the reseed arg as a
  //    QUANTUM operand, not as an `_hl` classical literal (the D2 silent miscompile).
  //    A non-i32 reseed arg cannot be re-planned and declines LOUDLY here (0vvq Inc
  //    2). With the afmv ordering the reseed set now includes yn71 `%out2` rails, so a
  //    round-1 `Pending` candidate reading a `%out2` rail is re-widened here (bd afmv)
  //    exactly as a `%out`-reading one. Must precede `declineTaintEscapes`, whose
  //    `shouldSpecialize` carve would otherwise wave a stale-mask candidate through.
  // 2b. bd 9paa (round-2 spec DETECTION — the detection twin of the re-plan): a
  //    wholly-new candidate `g(%out)`/`g(%out2)` that was ALL-classical at round 1
  //    (never in the plan) now reads a tainted merge/control rail. RE-RUN
  //    `detectSpecializations` on the reseed set, feeding the SAME `plan6`, so the
  //    driver clones it. Runs AFTER the re-plan (so its (a)/(b) Pending/Diagnosed
  //    dedup sees the re-plan's result — a reseed-reading round-1 candidate is already
  //    resolved and 9paa skips it) and AFTER `detectAndLowerOnwardControl` (so the CFG
  //    is fully settled: no un-lowered pre-lowering merge phi can enter `Pending`,
  //    closing the broken-module hazard). Both must precede `declineTaintEscapes` so
  //    the `shouldSpecialize` carve suppresses the new site's `kMsgUnknownCallee`.
  // 3. Then re-run the escape net (onward classical escapes decline via the precise
  //    messages; onward arith/phase/QRAM-store are carved for their owners) and 4. the
  //    stale-record sweep (mirrors the `declineLiftedStaleRecordOps` re-sweep
  //    precedent). Each decline is a `DiagnosticInfoUnsupported(DS_Error)` → non-zero
  //    exit, so an escape decline exits before the transiently-mistyped IR is verified.
  // bd b6ap F-B6-1 — these four calls ARE `adjudicateTaintDelta`, which is this
  // sequence lifted into a named function so the MULTI-PHI MERGE PEEL's own taint
  // growth is adjudicated by the SAME code rather than by a second spelling of it
  // (Rule 14). Behaviour here is byte-unchanged: same functions, same order, same
  // arguments. ⚠ `reseed` also covers the ROUND-2 PEEL: `peelIndependentMergePhis`
  // runs inside `detectAndLowerOnwardControl` above, and `beforeTaint` was
  // snapshotted at this function's ENTRY, so every value that peel tainted is in
  // `Tainted − beforeTaint` and therefore in `reseed`. That is why the round-2
  // peel call site needs no adjudication of its own — MEASURED, not assumed: the
  // only caller of `detectAndLowerOnwardControl` is this function, below the
  // `UntaintedMergeRails.empty()` early return.
  adjudicateTaintDelta(M, wd, taint, plan6, reseed);

  // 5. THE ONWARD LOOP-RAIL PASS — bd 3qlq Inc 1, Rule-13 ROUND-2 finding F-R1-1
  //    (a CONFIRMED rolled≠unrolled divergence, plain C through the shipped 2-TU
  //    onward harness). `collapseFlattenedLoopRails` is the round-2 loop-rail
  //    analysis, and until this call it ran EXACTLY ONCE, at
  //    `CQLoweringPass.cpp`'s slot BEFORE this function. Its premise —
  //    "`markIfRailLocal` runs after every in-loop region flatten" — is FALSE
  //    here: `detectAndLowerOnwardControl` above is a full second round of
  //    `detectControlRegions`/`lowerControlRegions`, so an in-loop region whose
  //    condition reads an `%out` rail is claimed and flattened AFTER the only
  //    caller of that marking has already run. MEASURED at HEAD before this
  //    call: `for (i<3) if ((y>>i)&1) cq_phi(θ)` over a 6.5 classical-call-arm
  //    `%out` emitted 3 `cq_template_and_i32_hl` mints and **0** `_unc`
  //    discharges — three entangled which-path records leaked per activation,
  //    while the hand-unrolled spelling of the same source discharged all three.
  //    `opt` exit 0, verify-clean, STRICT stage 2b `0 violation(s)` on both.
  //
  //    IT IS THE SAME STAGE, NOT A SECOND SPELLING (Rule 14): the identical
  //    function, given the snapshot of `taint.InLoopFlattenedPreds` taken at
  //    entry so it processes ONLY the loops the round-2 flatten opened. Every
  //    module with no round-2 in-loop region is therefore byte-identical.
  //
  //    POSITION. After the whole round-2 fixpoint (the CFG must be settled — a
  //    `LoopInfo` built mid-fixpoint would describe a loop the next iteration
  //    reshapes) and after the re-run escape/stale nets (both are pure analysis
  //    and either has already exited non-zero if it declined). It is BEFORE
  //    `deleteGlobalPhases` in both entry points for the same reason the round-1
  //    call is: P7 is the last stage that reads the pre-lowering `cq_phi` calls,
  //    and this marking is computed over the same work lists.
  //
  //    It lives HERE and not at the two `CQLoweringPass` call sites so that the
  //    `runOnFunction` shim gets it too. ⚠ That shim does NOT call the ROUND-1
  //    `collapseFlattenedLoopRails` at all — a PRE-EXISTING twin-pipeline
  //    divergence inherited from bd 8h7d.5, recorded in the AXIS-F note there
  //    and not repaired by this increment (the shim has zero callers).
  collapseFlattenedLoopRails(M, wd, taint, &Round1FlattenedPreds);
}

// ── bd test_C_libtooling-3qlq Inc 1 — the register-free branch phase ─────────

bool isRegisterFreePhaseCall(const CallInst *CI, const TaintSet &taint) {
  // See the header for why this is EXACT MEMBERSHIP and not a name test.
  return CI && llvm::is_contained(taint.PhaseCalls, CI);
}

namespace {

// The condition a block's terminator branches on: a conditional `br`'s i1 or a
// `switch` scrutinee; null for every other terminator. The ONE spelling the
// walks below share (bd 3by9 hoisted it out of the two inline copies).
const Value *branchCondition(const Instruction *T) {
  if (const auto *BI = dyn_cast<BranchInst>(T))
    return BI->isConditional() ? BI->getCondition() : nullptr;
  if (const auto *SI = dyn_cast<SwitchInst>(T))
    return SI->getCondition();
  return nullptr;
}

// Is `BB` reachable from the function entry along a path that passes through a
// block whose TERMINATOR branches on a TAINTED condition? Pure backward CFG
// walk from `BB`'s predecessors; `Taint` decides tainted-ness by SSA identity.
//
// This is `deleteGlobalPhases`' assertion, and it is deliberately CRUDE in the
// safe direction: it asks whether ANY tainted branch sits anywhere on ANY path
// reaching `BB`, not whether `BB` is on a specific arm of one. An accepted
// region has already been FLATTENED by its emitter (the tainted `br` is gone
// with the diamond) and a declined one exited non-zero, so on every reachable
// program state the answer is "no" — a "yes" means the Rule-1 invariant
// ("`detectControlRegions` either claims or declines every tainted `br`; there
// is no third path") has been broken, which is the one thing that must never be
// answered by a silent delete.
bool reachedThroughTaintedBranch(const BasicBlock *BB, const TaintSet &taint) {
  SmallPtrSet<const BasicBlock *, 16> Seen;
  SmallVector<const BasicBlock *, 16> Work(pred_begin(BB), pred_end(BB));
  while (!Work.empty()) {
    const BasicBlock *P = Work.pop_back_val();
    if (!Seen.insert(P).second)
      continue;
    const Value *C = branchCondition(P->getTerminator());
    if (C && taint.Tainted.count(const_cast<Value *>(C)))
      return true;
    Work.append(pred_begin(P), pred_end(P));
  }
  return false;
}

// ── CONTROL DEPENDENCE, for the phase carriers only ─────────────────────────
//
// bd 3qlq Inc 1, Rule-13 ROUND-2 finding F-R1-2. `reachedThroughTaintedBranch`
// above answers "is there a tainted branch ANYWHERE on ANY path to `BB`", which
// is the right question at `deleteGlobalPhases`' slot (a "yes" there means the
// Rule-1 no-third-path invariant broke) and the WRONG one for the three phase
// carriers, which run BEFORE `lowerControlRegions` while every tainted `br` is
// still standing. Asked there it answers "reached from" where
// `TaintPropagation.h` promises "CONTROL-DEPENDENT ON", and the difference is a
// MEASURED plain-C over-decline: `if (q==5) abort(); cq_phi(0.75); return
// cq_measure(q);` declined `phase-class value escaping under quantum control`
// although its `cq_phi` is UNCONDITIONAL — a GLOBAL phase owner decision D2
// requires the compiler to DELETE. The same program with the phase one line
// EARLIER compiled, and the round-1 binary compiled both to the identical
// 8-line trace.
//
// TWO SPELLINGS, ON PURPOSE, BECAUSE THEY ARE TWO QUESTIONS (Rule 14 is about
// one spelling per QUESTION, not one predicate per file). The assert wants the
// crude reachability; the carriers want control dependence. Naming them apart is
// what stops the next reader "unifying" them.

// Can `From` reach a block that RETURNS from the function? An `unreachable`
// terminator (a `noreturn` sink — the 7.2 abort park's own arm) has no
// successors and is a dead end, which is exactly the property the two walks
// below need: the classical CFG says the abort arm does not continue, while the
// EMITTED circuit runs the remainder coherently on every branch, so a phase
// after a park is global.
bool canReachReturn(const BasicBlock *From) {
  SmallPtrSet<const BasicBlock *, 16> Seen;
  SmallVector<const BasicBlock *, 16> Work{From};
  while (!Work.empty()) {
    const BasicBlock *B = Work.pop_back_val();
    if (!Seen.insert(B).second)
      continue;
    if (isa<ReturnInst>(B->getTerminator()))
      return true;
    Work.append(succ_begin(B), succ_end(B));
  }
  return false;
}

// Does EVERY path from `From` that reaches a `ret` pass through `Through`?
// (i.e. `Through` post-dominates `From` in the RETURNING-paths sense.) `From ==
// Through` is trivially true; a `From` that reaches no `ret` at all is
// vacuously true and the callers below never rely on that case (each guards it
// with `canReachReturn`).
bool everyReturningPathThrough(const BasicBlock *From,
                               const BasicBlock *Through) {
  SmallPtrSet<const BasicBlock *, 16> Seen;
  SmallVector<const BasicBlock *, 16> Work{From};
  while (!Work.empty()) {
    const BasicBlock *B = Work.pop_back_val();
    if (B == Through)
      continue;  // the cut — every path through here is accounted for.
    if (!Seen.insert(B).second)
      continue;
    if (isa<ReturnInst>(B->getTerminator()))
      return false;  // a returning path that avoids `Through`.
    Work.append(succ_begin(B), succ_end(B));
  }
  return true;
}

// Is `BB` CONTROL-DEPENDENT on the conditional terminator of `P`? The textbook
// definition, with post-dominance read in the returning-paths sense above:
//   `BB` is control-dependent on `P` iff (i) some successor `S` of `P` that can
//   still reach a `ret` is post-dominated by `BB`, and (ii) `P` itself is not.
// Clause (i)'s `canReachReturn` filter is the load-bearing half for the abort
// park: without it the `unreachable` arm is VACUOUSLY post-dominated by every
// block and (i) is true for anything. The ONE per-pair spelling, asked by
// `controlDependentOnTaintedBranch` and `transitiveControllers` (bd 3by9 hoisted
// it out of the former, unchanged).
//
// Clause (ii) is read NON-STRICTLY (`P == BB` counts as "post-dominated"), so a
// block is never control-dependent on its OWN terminator — not even the
// single-block loop whose back edge decides whether it runs again. The textbook
// definition says strict. Recorded rather than changed (bd 3by9): the one place
// it is observable, a phase inside a quantum-exit loop, is refused before any
// emitter by tryBreak's B4 side-effect clause and then the L1 loop decline.
bool controlDependsOn(const BasicBlock *BB, const BasicBlock *P) {
  if (everyReturningPathThrough(P, BB))
    return false;  // (ii) fails — `BB` post-dominates `P`: a GLOBAL phase.
  for (const BasicBlock *S : successors(P)) {
    if (!canReachReturn(S))
      continue;  // a `noreturn` arm — it decides nothing about `BB`.
    if (everyReturningPathThrough(S, BB))
      return true;  // (i) holds: `BB` runs on this arm and not on all of them.
  }
  return false;
}

bool functionHasReturn(const Function *F) {
  for (const BasicBlock &B : *F)
    if (isa<ReturnInst>(B.getTerminator()))
      return true;
  return false;
}

// Is `BB` CONTROL-DEPENDENT on some TAINTED branch of its function?
//
// Conservative fallback: a function with no `ReturnInst` at all has no
// returning-path structure to reason over, so this answers TRUE (the pre-fix
// disposition, which is the loud-decline direction).
bool controlDependentOnTaintedBranch(const BasicBlock *BB,
                                     const TaintSet &taint) {
  const Function *F = BB->getParent();
  if (!functionHasReturn(F))
    return true;

  for (const BasicBlock &P : *F) {
    const Value *C = branchCondition(P.getTerminator());
    if (!C || !taint.Tainted.count(const_cast<Value *>(C)))
      continue;
    if (controlDependsOn(BB, &P))
      return true;
  }
  return false;
}

// Is `CI` (a member of `taint.PhaseCalls`) a BRANCH phase — control-dependent
// on a tainted branch — rather than a global one? The per-call clause of
// `functionCarriesBranchPhase`, shared with `lineageCarriesBranchPhase` so the
// precise predicate considers EXACTLY the calls the coarse one counts.
bool isTaintControlledBranchPhase(const CallInst *CI, const TaintSet &taint) {
  // The crude reachability walk stays as the CHEAP PRE-FILTER (it is implied
  // by control dependence — `BB` post-dominating a successor of `P` requires
  // `BB` reachable from `P` — so it can only skip work, never change an
  // answer), and the control-dependence test decides.
  return reachedThroughTaintedBranch(CI->getParent(), taint) &&
         controlDependentOnTaintedBranch(CI->getParent(), taint);
}

// Every block whose conditional terminator `BB` is control-dependent on,
// DIRECTLY OR THROUGH A CHAIN — the closure of `controlDependsOn`, classical
// and tainted controllers alike (a classical `if` nested in a quantum arm, or a
// loop-invariant `if` inside a loop whose exit is quantum, both hand the
// question on to the branch that decides whether THEY run).
void transitiveControllers(const BasicBlock *BB,
                           SmallVectorImpl<const BasicBlock *> &Out) {
  const Function *F = BB->getParent();
  SmallPtrSet<const BasicBlock *, 16> Seen;
  SmallVector<const BasicBlock *, 8> Work{BB};
  while (!Work.empty()) {
    const BasicBlock *X = Work.pop_back_val();
    for (const BasicBlock &P : *F) {
      if (Seen.count(&P) || !branchCondition(P.getTerminator()))
        continue;
      if (!controlDependsOn(X, &P))
        continue;
      Seen.insert(&P);
      Out.push_back(&P);
      Work.push_back(&P);
    }
  }
}

// The TAINTED backward OPERAND closure of `V`, `V` itself included — the walk
// the three carriers' `cq_phi_` rows already take (an argument / constant root
// stops it; untainted operands are not followed).
void taintedOperandLineage(const Value *V, const TaintSet &taint,
                           SmallPtrSetImpl<const Value *> &Out) {
  SmallVector<const Value *, 16> Work{V};
  Out.insert(V);
  while (!Work.empty()) {
    const auto *I = dyn_cast<Instruction>(Work.pop_back_val());
    if (!I)
      continue;
    for (const Value *Op : I->operands())
      if (taint.Tainted.count(const_cast<Value *>(Op)) && Out.insert(Op).second)
        Work.push_back(Op);
  }
}

}  // namespace

// See the header for the whole argument (bd 3qlq Inc 1 part A, F-L5-6; narrowed
// to genuine control dependence by Rule-13 round-2 finding F-R1-2).
bool functionCarriesBranchPhase(const Function *F, const TaintSet &taint) {
  for (CallInst *CI : taint.PhaseCalls)
    if (CI->getFunction() == F && isTaintControlledBranchPhase(CI, taint))
      return true;
  return false;
}

// See the header (bd 3by9, tinh). Strictly NARROWER than
// `functionCarriesBranchPhase` by construction: it visits exactly the calls that
// predicate counts, skips the ones that cannot reach `Construct`, and adds a
// condition before answering true.
bool lineageCarriesBranchPhase(const Value *V, const TaintSet &taint,
                               const BasicBlock *Construct) {
  const auto *VI = dyn_cast<Instruction>(V);
  if (!VI)
    return false;  // the coarse clause's own scope: it never asked of a non-instruction.
  const Function *F = VI->getFunction();
  SmallPtrSet<const Value *, 32> Answer;
  for (CallInst *CI : taint.PhaseCalls) {
    if (CI->getFunction() != F || !isTaintControlledBranchPhase(CI, taint))
      continue;
    // bd tinh: a phase whose block cannot reach the construct runs only after
    // it (or on a path that never enters it), so it is a later gate. Asked
    // BEFORE the no-`ret` fallback below, because the question is purely
    // structural and reads no post-dominance. `isPotentiallyReachable` answers
    // TRUE when its block budget runs out, which counts the phase (the loud
    // direction).
    if (Construct && Construct->getParent() == F &&
        !isPotentiallyReachable(CI->getParent(), Construct))
      continue;
    // No returning path: `controlDependentOnTaintedBranch` answered by its
    // fallback, not by structure, and so would `transitiveControllers` (every
    // block vacuously post-dominates everything). Keep the coarse answer.
    if (!functionHasReturn(F))
      return true;
    if (Answer.empty())
      taintedOperandLineage(V, taint, Answer);
    // The values the phase is a function of: every TAINTED controlling
    // condition, plus a tainted angle (a folded `cq_phi(c ? a : b)` nested under
    // a tainted branch; a top-level fold never passes the per-call clause above).
    SmallVector<const Value *, 8> Keys;
    SmallVector<const BasicBlock *, 8> Ctl;
    transitiveControllers(CI->getParent(), Ctl);
    for (const BasicBlock *P : Ctl) {
      const Value *C = branchCondition(P->getTerminator());
      if (taint.Tainted.count(const_cast<Value *>(C)))
        Keys.push_back(C);
    }
    if (taint.Tainted.count(CI->getArgOperand(0)))
      Keys.push_back(CI->getArgOperand(0));
    for (const Value *K : Keys) {
      SmallPtrSet<const Value *, 32> KeyLineage;
      taintedOperandLineage(K, taint, KeyLineage);
      for (const Value *X : KeyLineage)
        if (Answer.count(X))
          return true;
    }
  }
  return false;
}

void deleteGlobalPhases(Module &M, WidthDispatch &wd, TaintSet &taint) {
  Function *PhaseFn = wd.phaseFn();
  if (!PhaseFn)
    return;

  // Walk the FUNCTION's own use list rather than `taint.PhaseCalls`: an emitter
  // that claimed a region has already ERASED its phase call, and while every
  // such emitter also scrubs the work list, deriving the survivors from the IR
  // itself makes a missed scrub a no-op here instead of a dangling read.
  SmallVector<CallInst *, 8> Survivors;
  bool Declined = false;
  for (User *U : PhaseFn->users()) {
    auto *CI = dyn_cast<CallInst>(U);
    if (CI && CI->getCalledFunction() == PhaseFn) {
      Survivors.push_back(CI);
      continue;
    }
    // (0) ANY OTHER USER OF `@cq_phi` IS A LOUD DECLINE — Rule-13 round-1
    // finding F-L3-4. The earlier spelling of this loop was a `dyn_cast` FILTER,
    // so a non-call user simply fell out of the walk: the pass lowered nothing
    // for it, the extern SURVIVED into the lowered module, and `opt` exited 0 on
    // a module it had not lowered. MEASURED from plain `clang -O1` C —
    //
    //     void (*volatile pf)(double) = cq_phi;
    //     int slice(void){ int q = cq_theta_si32(0,0.3); pf(0.5); return cq_measure_si32(q); }
    //
    // — stage 2 exit 0, stage 2b exit 0, and stage 3 fails with
    // `Undefined symbols … "_cq_phi", referenced from: _pf`. Loud at the LINKER
    // is not loud at the compiler: Rule 1 says there is no third path, and an
    // `opt` that exits 0 on an unlowered quantum construct IS one. It also
    // matters that the survivor set is derived from `PhaseFn->users()` precisely
    // so a missed scrub is a no-op — that same choice is what makes a NON-call
    // user visible here, which is the right place to refuse it.
    //
    // The two other spellings already decline elsewhere and keep their own
    // strings: an `invoke` is caught at collection (`front-end intrinsic cq_phi
    // reached via invoke; only a direct call is supported`) and a
    // `pf(...)` UNDER a tainted branch declines `control flow under quantum
    // control` before this stage. This clause is the remaining one.
    //
    // A `CallInst` that uses `PhaseFn` as a non-callee OPERAND (an argument, say)
    // lands here too, and correctly: passing the intrinsic's address to anything
    // is the same escape.
    Function *At = nullptr;
    const Instruction *I = dyn_cast<Instruction>(U);
    if (I)
      At = const_cast<Function *>(I->getFunction());
    if (!At)
      At = PhaseFn;  // a constant expression / global initializer user.
    At->getContext().diagnose(DiagnosticInfoUnsupported(
        *At,
        "cq taint propagation: front-end intrinsic cq_phi has its address taken; "
        "only a direct call is supported",
        I ? I->getDebugLoc() : DebugLoc()));
    Declined = true;
  }

  for (CallInst *CI : Survivors) {
    // (1) THE RULE-1 ASSERT FIRST, so a broken invariant is never masked by the
    //     angle message below.
    if (reachedThroughTaintedBranch(CI->getParent(), taint)) {
      diagnoseUnderControl(CI, "unclaimed branch phase");
      Declined = true;
      continue;
    }
    // (2) A tainted ANGLE (Rule 3). Same dialect and same string as the retired
    //     suffixed family's `RotationLowering::declineTaintedAngle`.
    if (CI->arg_size() == 1 && taint.Tainted.count(CI->getArgOperand(0))) {
      CI->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
          *CI->getFunction(),
          "cq rotation lowering: unsupported quantum-derived rotation angle",
          CI->getDebugLoc()));
      Declined = true;
      continue;
    }
    // (3) GLOBAL PHASE → delete (D2). No diagnostic, by owner decision.
    auto &PC = taint.PhaseCalls;
    PC.erase_value(CI);
    taint.Tainted.erase(CI);
    taint.BirthOrder.erase(CI);
    CI->eraseFromParent();
  }
  (void)Declined;
}

// bd `test_C_libtooling-3jru` — character-for-character in
// `condtree_classical_leaf_reject_callee_quantum_return*.ll` and
// `taint_reject_quantum_return_*.ll`.
static constexpr char kMsgQuantumReturn[] =
    "cq taint escape: quantum value returned across a function boundary";

bool functionReturnsTainted(const Function &F, const TaintSet &taint) {
  for (const BasicBlock &BB : F)
    if (const auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
      if (Value *RV = R->getReturnValue())
        if (taint.Tainted.count(RV))
          return true;
  return false;
}

// bd `test_C_libtooling-3jru` — the LOUD refusal. See TaintPropagation.h.
bool declineQuantumReturnCalls(Module &M, const TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration() || !functionReturnsTainted(F, taint))
      continue;
    // Two kinds of use are refused:
    //  * a DIRECT call whose RESULT HAS A USE — the caller would read the handle
    //    as a value. A direct call whose result is UNUSED (`g(m);`) is NOT
    //    refused (Rule-13 round 4 P3-a): nothing in the caller reads the handle,
    //    the callee's `ret` of it is the ordinary Escaped contract, and the rail is
    //    left allocated (Rule 6) — which is what the pre-3jru compiler emitted.
    //  * ANY other use — the address taken (a function pointer, a store, an
    //    argument, a constant expression): it may reach an INDIRECT call whose
    //    result is read, and nothing here can tell which. This is kept loud even
    //    when no indirect call exists in the module (a function that is only
    //    address-taken and never called still declines): proving the absence of
    //    every indirect read is a points-to question this stage does not ask, and
    //    an over-decline is the loud side of it (never silent, but a gap to
    //    remove under R1, not a safe margin).
    // A function with no use in this module (an entry point, or a cross-TU
    // export) is untouched: its `ret` of a handle is the existing Escaped contract.
    for (User *U : F.users()) {
      if (auto *CB = dyn_cast<CallBase>(U);
          CB && CB->getCalledOperand() == &F && CB->use_empty())
        continue;
      // Rule-13 round 5 F-R5-2: `@llvm.used` / `@llvm.compiler.used` list F to
      // keep it alive; they are not callers and read no result.
      if (auto *C = dyn_cast<Constant>(U); C && !isa<GlobalValue>(C)) {
        bool OnlyUsedLists = !C->use_empty();
        for (User *CU : C->users()) {
          auto *GV = dyn_cast<GlobalVariable>(CU);
          if (!GV || (GV->getName() != "llvm.used" &&
                      GV->getName() != "llvm.compiler.used"))
            OnlyUsedLists = false;
        }
        if (OnlyUsedLists)
          continue;
      }
      auto *I = dyn_cast<Instruction>(U);
      if (!I) {
        // A constant user (a global initializer, a constant expression): no
        // instruction to anchor on — anchor on the function itself.
        F.getContext().diagnose(
            DiagnosticInfoUnsupported(F, kMsgQuantumReturn));
        return true;
      }
      I->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
          *I->getFunction(), kMsgQuantumReturn, I->getDebugLoc()));
      return true;
    }
  }
  return false;
}

// bd `test_C_libtooling-l3oi` — see TaintPropagation.h. Mirrored
// character-for-character by `taint_reject_scrubbed_handle_*.ll`.
static constexpr char kMsgScrubbedHandle[] =
    "cq taint escape: classical call result used as a quantum register";

bool declineScrubbedHandleReads(Module &M, const TaintSet &taint) {
  (void)M;
  for (const WeakVH &H : taint.ScrubbedByReturnTaint) {
    Value *V = H;
    if (!V || taint.Tainted.count(V))
      continue;  // erased, or re-tainted by an independent source since.
    for (User *U : V->users()) {
      auto *CB = dyn_cast<CallBase>(U);
      if (!CB)
        continue;
      const Function *Callee = CB->getCalledFunction();
      if (!Callee)
        continue;
      StringRef N = Callee->getName();
      bool Reads = N.starts_with("cqrt_") || N.starts_with("cq_template_");
      // Rule-13 round 7 F-R7-1: a call to a SPECIALIZED CLONE (or its `_unc`
      // twin) built pre-scrub from a detection-time mask reads the value as a
      // handle in every MASKED argument slot. Identified by the specializer's
      // own record (`SpecHandleArgMask`), never by the `__cq_q_` name prefix.
      if (!Reads) {
        auto It = taint.SpecHandleArgMask.find(Callee);
        if (It != taint.SpecHandleArgMask.end())
          for (unsigned A = 0, E = CB->arg_size(); A < E && A < 64; ++A)
            if (CB->getArgOperand(A) == V && ((It->second >> A) & 1))
              Reads = true;
      }
      if (!Reads)
        continue;
      CB->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
          *CB->getFunction(), kMsgScrubbedHandle, CB->getDebugLoc()));
      return true;
    }
  }
  return false;
}

}  // namespace cq
