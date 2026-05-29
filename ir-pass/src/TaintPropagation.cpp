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
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
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
      if (out.Tainted.insert(I).second)
        Worklist.push_back(I);
    }
  }

  return out;
}

}  // namespace cq
