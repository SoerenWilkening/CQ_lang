// TaintPropagation.cpp — Forward taint propagation from quantum init
// returns. Behavior preserved from the original monolith's step-4 worker;
// the source set spans every `@cq_init_<sfx>` declared in the module
// (14-suffix enumeration via
// `WidthDispatch::allSuffixes()`). Propagation rules are unchanged.

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
// small (≤14 inits, ≤14 measures) makes it a perfect fit.
using FnSet = SmallPtrSet<Function *, 16>;

// Per-function pass: collect init/measure call sites in BB order and
// seed the propagation work-list with init RESULT SSA values. Iterating
// per-function (rather than via `F->users()`) preserves the
// BB-order semantics — `MidHandleRebind` assigns `BirthOrder` to allocs
// in this same order, which `OpcodeLowering` reads back for stable Q+Q
// operand canonicalization.
void collectAndSeed(Function &F, const FnSet &InitFns,
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
      if (InitFns.contains(Callee)) {
        out.InitCalls.push_back(CI);
        if (out.Tainted.insert(CI).second)
          Worklist.push_back(CI);
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

// Resolve every declared `@cq_init_<sfx>` / `@cq_measure_<sfx>` into the
// pair (InitFns, MeasureFns). Suffixes whose intrinsic isn't declared in
// `M` are skipped — that's the early-out cue the per-function walk uses
// to leave a purely-classical module untouched. Order doesn't matter:
// `collectAndSeed` walks call sites in BB order, not symbol order.
void resolveSources(WidthDispatch &wd, FnSet &InitFns, FnSet &MeasureFns) {
  for (StringRef Sfx : wd.allSuffixes()) {
    if (Function *F = wd.initFn(Sfx))
      InitFns.insert(F);
    if (Function *F = wd.measureFn(Sfx))
      MeasureFns.insert(F);
  }
}

}  // namespace

TaintSet propagate(Module &M, WidthDispatch &wd) {
  TaintSet out;
  FnSet InitFns;
  FnSet MeasureFns;
  resolveSources(wd, InitFns, MeasureFns);

  // No front-end intrinsics anywhere in the module → nothing to do.
  // The passthrough_no_quantum LIT fixture pins this early-out path:
  // the pass must leave a purely classical module byte-identical, and
  // crucially must NOT leak `cqrt_*` / `cq_template_*` decls.
  if (InitFns.empty() && MeasureFns.empty())
    return out;

  std::vector<Value *> Worklist;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    collectAndSeed(F, InitFns, MeasureFns, out, Worklist);
  }

  // Forward taint propagation. Each tainted SSA value's user
  // instructions become tainted, except measure sinks. The work-list
  // discipline (insert-then-push) means each value is processed exactly
  // once.
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
