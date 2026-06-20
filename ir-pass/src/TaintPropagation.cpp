// TaintPropagation.cpp — Forward taint propagation from quantum rotation
// returns. The source set spans every `@cq_theta_<sfx>` declared in the
// module (14-suffix enumeration via `WidthDispatch::allSuffixes()`);
// `@cq_phi_<sfx>` is collected for lowering but is not a source;
// `@cq_measure_<sfx>` is the sink. Propagation rules are unchanged from the
// original source-collection version — only the source predicate moved to
// the `@cq_theta_<sfx>` rotation family.

#include "TaintPropagation.h"

#include "IntrinsicLowering.h"
#include "SpecializePlan.h"
#include "Specialization.h"
#include "WidthDispatch.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"

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
// terminator surgery the pipeline has no story for. Declining is the correct
// move (Prime Directive: over-declining is always safe): silently dropping it
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
                    const FnSet &MeasureFns, TaintSet &out,
                    std::vector<Value *> &Worklist) {
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
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
      const bool IsTheta = ThetaFns.contains(Callee);
      const bool IsPhi = PhiFns.contains(Callee);
      const bool IsMeasure = MeasureFns.contains(Callee);
      if (!IsTheta && !IsPhi && !IsMeasure)
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
        out.ThetaCalls.push_back(CI);
        if (out.Tainted.insert(CI).second)
          Worklist.push_back(CI);
      } else if (IsPhi) {
        out.PhiCalls.push_back(CI);
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
//   cq_theta_<sfx> / cq_phi_<sfx>: T (T, double)    cq_measure_<sfx>: T (T)
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
//   * lowering_reject_decl_prototype_phi.ll     → "... for cq_phi_si32"
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

// Resolve every declared `@cq_theta_<sfx>` / `@cq_phi_<sfx>` /
// `@cq_measure_<sfx>` into the three FnSets. Suffixes whose intrinsic isn't
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
// happenstance (over-declining is always safe, Prime Directive). An
// UNRECOGNIZED suffix (e.g. `cq_measure_xyz999`) is NOT in the 42-name
// surface and stays out of collection — and validation — entirely.
void resolveSources(WidthDispatch &wd, FnSet &ThetaFns, FnSet &PhiFns,
                    FnSet &MeasureFns) {
  for (StringRef Sfx : wd.allSuffixes()) {
    if (Function *F = wd.thetaFn(Sfx)) {
      if (declMatchesPrototype(F, wd.llvmTypeFor(Sfx, F->getContext()),
                               /*HasAngle=*/true))
        ThetaFns.insert(F);
      else
        diagnoseMalformedDecl(F, "cq rotation lowering");
    }
    if (Function *F = wd.phiFn(Sfx)) {
      if (declMatchesPrototype(F, wd.llvmTypeFor(Sfx, F->getContext()),
                               /*HasAngle=*/true))
        PhiFns.insert(F);
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

}  // namespace

TaintSet propagate(Module &M, WidthDispatch &wd) {
  TaintSet out;
  FnSet ThetaFns;
  FnSet PhiFns;
  FnSet MeasureFns;
  resolveSources(wd, ThetaFns, PhiFns, MeasureFns);

  // No front-end intrinsics anywhere in the module → nothing to do.
  // The passthrough_no_quantum LIT fixture pins this early-out path:
  // the pass must leave a purely classical module byte-identical, and
  // crucially must NOT leak `cqrt_*` / `cq_template_*` decls.
  if (ThetaFns.empty() && PhiFns.empty() && MeasureFns.empty())
    return out;

  std::vector<Value *> Worklist;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    collectAndSeed(F, ThetaFns, PhiFns, MeasureFns, out, Worklist);
  }

  // Forward taint propagation. Each tainted SSA value's user instructions
  // become tainted, except measure sinks. The work-list discipline
  // (insert-then-push) means each value is processed exactly once. A
  // tainted-operand phi is reached here as a normal user, so its result
  // taints and propagates onward — correct (Rz preserves the value).
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
      // cq_theta/cq_phi is a classical scalar, never a quantum handle. If `V`
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
      }
      if (out.Tainted.insert(I).second)
        Worklist.push_back(I);
    }
  }

  return out;
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

// Does `I` read at least one tainted SSA value? Operand-level test (not
// result-taint): the escape is the EDGE from a quantum value into a consumer
// the lowering cannot rewrite. For a CallBase, `operands()` includes the
// called operand, so an indirect call THROUGH a tainted pointer also trips.
bool readsTaintedValue(const Instruction &I, const TaintSet &taint) {
  for (const Value *Op : I.operands())
    if (taint.Tainted.count(const_cast<Value *>(Op)))
      return true;
  return false;
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

  // BB-order walk (deterministic diagnostic order, like
  // OpcodeLowering::declineStaleRecordOps). One diagnostic per offending
  // instruction. The KNOWN-CONSUMER list below is everything a later stage
  // provably owns — each entry cites its owner; ANYTHING else that reads a
  // tainted value is an unproven shape and declines loudly (Prime Directive:
  // over-declining is always safe, over-accepting is a silent miscompile).
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
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
            //     fshl/fshr require the rotation form (arg0==arg1, constant
            //     amount). A non-curated id, an unsupported width, or the general
            //     funnel shift fails the predicate and falls through to the loud
            //     kMsgUnknownCallee decline below (`*.with.overflow`,
            //     transcendentals, general funnel shift stay declined).
            if (isCuratedReversibleIntrinsic(CI))
              continue;
          }
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
        //    tainted-condition select/switch/branch accepts as a swap-route
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
          if (RV && taint.Tainted.count(RV) && !RV->getType()->isIntegerTy(32))
            diagnoseEscape(&I, kMsgNonI32Return);
          continue;
        }
        if (I.isTerminator())
          continue;
        if (!readsTaintedValue(I, taint))
          continue;
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
  // allocation could alias it), and erase. The downstream measure/return/uncompute
  // analyses then see the TRUE handle lineage (the standing freeze would otherwise
  // read as an unrecognized FreePoint user). Done AFTER the walk so no erasure
  // invalidates the BB iterator above.
  for (FreezeInst *FI : FoldFreezes) {
    Value *H = FI->getOperand(0);
    FI->replaceAllUsesWith(H);
    taint.Tainted.erase(FI);
    FI->eraseFromParent();
  }
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
//     if (classical_c) q = cq_phi(q, theta);  ...use(q)...
// survives `clang -O1` as a merge phi whose two incomings are DISTINCT SSA
// values denoting the SAME physical register:
//     merge: %p = phi i32 [ %q2, %arm ], [ %q, %entry ]   ; %q2 = cq_phi(%q,θ)
// (verified 2026-06-10 on both the `if` and the ternary form — clang cannot
// speculate the opaque cq_phi call, so BOTH compile to this branch+phi shape,
// never to a select). The N-ary classical `switch` around an in-place gate on
// the SAME register is the same shape at higher arity — N>2 incomings, each a
// distinct SSA name of the one register's per-path record, reconverging at one
// merge phi; Increment C lifts it by the IDENTICAL per-edge argument, with the
// (7a) reachability proof carried against EVERY other edge (not just the single
// 2-way complement). Rotation lowering is IN PLACE: `RotationLowering` emits
// the gate at the call's position ON THE OPERAND HANDLE and RAUWs the result
// to that same operand (cqrt_rz for cq_phi; ry-only on the existing handle for
// a tainted-operand chained cq_theta). So after lowering, EVERY incoming of
// such a phi is the same i32 handle — the phi is a pure SSA renaming that
// never touches the register. RAUW'ing it to the wire's base SSA value and
// erasing it reduces the module to the phi-less form the pipeline ALREADY
// accepts (verified: gate-in-classical-arm + use-of-base lowers to
// rz-inside-the-arm + measure-on-handle, in both main and non-main).
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
//       COLLECTED cq_theta/cq_phi call sites — exact CallInst membership,
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
// ───────────────────────────────────────────────────────────────────────────

// The backward in-place-gate wire resolution: peel collected cq_theta/cq_phi
// call sites through their arg-0 handle while that handle is tainted (a
// tainted-operand rotation is in-place — its result RAUWs to its operand).
// Stops at a classical-operand theta (the register's mint point — the call
// itself is the base), at any non-gate value (phi/select/template/argument),
// and never steps through another mux (nested diamonds resolve to distinct
// phi bases and decline — conservative, documented).
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
// and the caller declines loudly, exactly as before the lift (Prime
// Directive: over-declining is always safe).
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
  // allocation could alias it), and erase.
  //
  // Witness that a lift OCCURRED (test_C_libtooling-2qyz). The RAUW re-points
  // every consumer onto the wire base, so a sibling Ry re-rotating that base's
  // wire now stales any in-scope op downstream of the (erased) phi — but the
  // stale-record guard (`declineStaleRecordOps`) already ran BEFORE this lift
  // and saw only the opaque PHINode operand (its backward closure stops at a
  // PHINode, and its forward walk from the phi never reaches the base's sibling
  // theta), so it could not adjudicate the now-exposed shape. NOT "every later
  // guard still adjudicates it" — the stale-record guard is an EARLIER guard.
  // Recording the direct consumers flags the lift to the orchestrator, which
  // re-runs the FULL stale-record sweep right after `declineClassicalMuxes`
  // (`declineLiftedStaleRecordOps`). The sweep is complete, not scoped to these
  // entries: the genuine stale op may be a TRANSITIVE consumer separated from
  // the phi by in-place-gate hops (Rz / chained Ry) — a Rule-13 adversarial
  // finding — so only re-walking every consumer's full wire is sound.
  for (User *U : Phi->users())
    if (auto *I = dyn_cast<Instruction>(U))
      taint.LiftedConsumers.insert(I);
  Phi->replaceAllUsesWith(Chains[0].Base);
  taint.Tainted.erase(Phi);
  Phi->eraseFromParent();
  return true;
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
  // natural `if (classical_c) q = cq_phi(q, θ); use(q)` shape — is RAUW'd to
  // its wire base and erased (see liftOneRegisterMergePhi above for the full
  // predicate and the Rule-13 clearance). Selects are NEVER lifted: a select's
  // gate-call incoming dominates it, so the gate has already fired
  // unconditionally and the untaken incoming names a record the register no
  // longer holds.
  SmallPtrSet<CallInst *, 32> GateCalls;
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());
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
          diagnoseEscape(Phi, kMsgClassicalPhi);
          continue;
        }
      }
    }
  }
}

}  // namespace cq
