// TaintPropagation.cpp — Forward taint propagation from quantum init
// returns. Behavior preserved from the pre-M12 monolith's step-4 worker.

#include "TaintPropagation.h"

#include "WidthDispatch.h"

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

#include <vector>

using namespace llvm;

namespace cq {

namespace {

// Per-function pass: collect init/measure call sites in BB order and
// seed the propagation work-list with init RESULT SSA values. Iterating
// per-function (rather than via `F->users()`) preserves Phase 1's
// BB-order semantics — `MidHandleRebind` assigns `BirthOrder` to allocs
// in this same order, which `OpcodeLowering` reads back for stable Q+Q
// operand canonicalization.
void collectAndSeed(Function &F, Function *InitF, Function *MeasureF,
                    TaintSet &out, std::vector<Value *> &Worklist) {
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI)
        continue;
      Function *Callee = CI->getCalledFunction();
      if (!Callee)
        continue;
      if (InitF && Callee == InitF) {
        out.InitCalls.push_back(CI);
        if (out.Tainted.insert(CI).second)
          Worklist.push_back(CI);
      } else if (MeasureF && Callee == MeasureF) {
        out.MeasureCalls.push_back(CI);
      }
    }
  }
}

// Is `I` a taint sink? Both the front-end intrinsic `@cq_measure_si32`
// and the runtime lowering target `@cqrt_measure_i32` stop propagation.
// The latter is defensive: at propagation time only `@cq_measure_si32`
// exists in the IR, but accepting both keeps the rule honest if a
// future re-entrant pass invokes propagation after measure lowering.
bool isMeasureSink(Instruction *I) {
  auto *CI = dyn_cast<CallInst>(I);
  if (!CI)
    return false;
  Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  return N == "cq_measure_si32" || N == "cqrt_measure_i32";
}

}  // namespace

TaintSet propagate(Module &M, WidthDispatch &wd) {
  TaintSet out;
  Function *InitF = wd.initFn();
  Function *MeasureF = wd.measureFn();

  // No front-end intrinsics anywhere in the module → nothing to do.
  // The passthrough_no_quantum LIT fixture pins this early-out path:
  // the pass must leave a purely classical module byte-identical, and
  // crucially must NOT leak `cqrt_*` / `cq_template_*` decls.
  if (!InitF && !MeasureF)
    return out;

  std::vector<Value *> Worklist;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    collectAndSeed(F, InitF, MeasureF, out, Worklist);
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
      if (isMeasureSink(I))
        continue;
      if (out.Tainted.insert(I).second)
        Worklist.push_back(I);
    }
  }

  return out;
}

}  // namespace cq
