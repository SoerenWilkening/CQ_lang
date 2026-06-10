// TaintPropagation.cpp — Forward taint propagation from quantum rotation
// returns. The source set spans every `@cq_theta_<sfx>` declared in the
// module (14-suffix enumeration via `WidthDispatch::allSuffixes()`);
// `@cq_phi_<sfx>` is collected for lowering but is not a source;
// `@cq_measure_<sfx>` is the sink. Propagation rules are unchanged from the
// original source-collection version — only the source predicate moved to
// the `@cq_theta_<sfx>` rotation family.

#include "TaintPropagation.h"

#include "WidthDispatch.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

#include <vector>

using namespace llvm;

namespace cq {

namespace {

// Set of front-end intrinsic Function*s. `SmallPtrSet` because membership
// lookups happen once per CallInst during the BB walk; pointer-keyed and
// small (≤14 thetas, ≤14 phis, ≤14 measures) makes it a perfect fit.
using FnSet = SmallPtrSet<Function *, 16>;

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
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI)
        continue;
      Function *Callee = CI->getCalledFunction();
      if (!Callee)
        continue;
      if (ThetaFns.contains(Callee)) {
        out.ThetaCalls.push_back(CI);
        if (out.Tainted.insert(CI).second)
          Worklist.push_back(CI);
      } else if (PhiFns.contains(Callee)) {
        out.PhiCalls.push_back(CI);
      } else if (MeasureFns.contains(Callee)) {
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
bool isMeasureSink(Instruction *I, const FnSet &MeasureFns) {
  auto *CI = dyn_cast<CallInst>(I);
  if (!CI)
    return false;
  Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return false;
  if (MeasureFns.contains(Callee))
    return true;
  return Callee->getName().starts_with("cqrt_measure_");
}

// Resolve every declared `@cq_theta_<sfx>` / `@cq_phi_<sfx>` /
// `@cq_measure_<sfx>` into the three FnSets. Suffixes whose intrinsic isn't
// declared in `M` are skipped — that's the early-out cue the per-function
// walk uses to leave a purely-classical module untouched. Order doesn't
// matter: `collectAndSeed` walks call sites in BB order, not symbol order.
void resolveSources(WidthDispatch &wd, FnSet &ThetaFns, FnSet &PhiFns,
                    FnSet &MeasureFns) {
  for (StringRef Sfx : wd.allSuffixes()) {
    if (Function *F = wd.thetaFn(Sfx))
      ThetaFns.insert(F);
    if (Function *F = wd.phiFn(Sfx))
      PhiFns.insert(F);
    if (Function *F = wd.measureFn(Sfx))
      MeasureFns.insert(F);
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
// (test_C_libtooling-bxv). The negative fixtures mirror each one
// CHARACTER-FOR-CHARACTER (Rule 12):
//   * lowering_reject_taint_escape_opaque_call.ll    → kMsgUnknownCallee
//   * lowering_reject_taint_escape_deep_arg.ll       → kMsgUnknownCallee
//   * lowering_reject_taint_escape_inmodule_body.ll  → kMsgUnknownCallee
//   * lowering_reject_taint_escape_indirect_call.ll  → kMsgUnknownCallee
//   * lowering_reject_taint_escape_store_global.ll   → kMsgStore
//   * lowering_reject_taint_escape_gep.ll            → kMsgOther
constexpr char kMsgUnknownCallee[] =
    "cq taint escape: tainted value consumed by an unknown callee";
constexpr char kMsgStore[] = "cq taint escape: tainted value stored to memory";
constexpr char kMsgOther[] =
    "cq taint escape: tainted value reaches an unsupported instruction";

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

}  // namespace

void declineTaintEscapes(Module &M, const TaintSet &taint) {
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
          // 1d. Everything else — opaque extern, in-module body (Phase 6
          //     clone-on-taint is NOT implemented; a visible body is exactly
          //     as un-lowered as a declaration), llvm.* intrinsic (e.g. the
          //     -O1 `llvm.smin` min/max idiom), or indirect (null callee) —
          //     is an UNKNOWN callee: after RAUW it would read the i32
          //     runtime handle tag, verify-clean.
          if (readsTaintedValue(I, taint))
            diagnoseEscape(&I, kMsgUnknownCallee);
          continue;
        }
        // 2. The four lowerOps instruction classes — owned by Arith/Compare/
        //    CastLowering, whose drivers diagnose their own unsupported
        //    members loudly ("no template for opcode ... in tainted context",
        //    e.g. the inttoptr probe; fixture lowering_icmp_qq_negative.ll).
        if (isa<BinaryOperator>(I) || isa<UnaryOperator>(I) ||
            isa<CmpInst>(I) || isa<CastInst>(I))
          continue;
        // 3. Control-flow value merges/muxes — owned by ControlDetect (a
        //    tainted-condition select/switch/branch accepts as a swap-route
        //    region or declines "... under quantum control") and by the
        //    Phase-5 FreePoint net (a classical-condition phi/select over
        //    tainted data reaches its "unrecognized user" reject). Declining
        //    them here would re-own shapes whose fixtures pin those
        //    diagnostics character-for-character.
        if (isa<PHINode>(I) || isa<SelectInst>(I))
          continue;
        // 4. Terminators: a tainted `br`/`switch` condition is ControlDetect's;
        //    `ret` of a tainted handle is FreePoint's RECOGNIZED Escaped case —
        //    the caller owns the handle (pinned ACCEPT fixtures
        //    lowering_uncompute_escape_return.ll, control_swap_ifelse_escape.ll).
        if (I.isTerminator())
          continue;
        if (!readsTaintedValue(I, taint))
          continue;
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
}

}  // namespace cq
