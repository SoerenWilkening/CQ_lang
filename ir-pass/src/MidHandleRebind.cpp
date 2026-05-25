// MidHandleRebind.cpp — Mid-struct → i32-handle SSA rebinding. Behavior
// preserved from the pre-M12 monolith's steps 2 and 3.

#include "MidHandleRebind.h"

#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include <vector>

using namespace llvm;

namespace cq {

RebindMap rebindMids(Module &M, WidthDispatch &wd, TaintSet &taint) {
  RebindMap rebind;
  if (taint.InitCalls.empty())
    return rebind;

  IRBuilder<> Builder(wd.context());
  FunctionCallee AllocFn = wd.allocFn();
  Type *I32 = wd.i32Ty();

  // --- Step 2 (legacy): emit cqrt_alloc_<W>(value) per init, build the
  // struct→handle map, and (flattened-shape only) RAUW the init result.
  //
  // The RAUW for the flattened shape is critical: it gives downstream
  // passes (taint-set-driven OpcodeLowering, MeasureLowering pattern c)
  // real i32 SSA edges to follow, because in the flattened shape there
  // is no extractvalue intermediary. The struct shape keeps the init's
  // struct uses alive until step 7 (eraseDeadInits) reclaims them.
  for (CallInst *Init : taint.InitCalls) {
    Builder.SetInsertPoint(Init);
    Value *Val = Init->getArgOperand(0);
    CallInst *Alloc = Builder.CreateCall(AllocFn, {Val}, "h");
    if (DebugLoc DL = Init->getDebugLoc())
      Alloc->setDebugLoc(DL);

    rebind.StructToHandle[Init] = Alloc;
    rebind.BirthOrder[Alloc] = rebind.NextBirth++;

    // Alloc IS the post-rebind quantum-carrying SSA value; downstream
    // dispatch will need to see it as tainted. Add unconditionally.
    taint.Tainted.insert(Alloc);

    if (Init->getType() == I32) {
      // Flattened (`-O1` SROA) shape: types match; rewire init's i32
      // users to the alloc directly. The init itself becomes use-less
      // and is reclaimed by eraseDeadInits.
      Init->replaceAllUsesWith(Alloc);
    }
  }

  // --- Step 3 (legacy): rewrite extractvalue %s, 0 → handle.
  //
  // Only extractvalues whose aggregate is a tracked init result are
  // rewired (otherwise we'd be eating someone else's struct traffic).
  // We also drop the erased extractvalue from `taint.Tainted` so a
  // future same-address allocation can't accidentally match.
  std::vector<Instruction *> ToErase;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *EV = dyn_cast<ExtractValueInst>(&I);
        if (!EV)
          continue;
        Value *Agg = EV->getAggregateOperand();
        auto It = rebind.StructToHandle.find(Agg);
        if (It == rebind.StructToHandle.end())
          continue;
        if (EV->getNumIndices() != 1 || EV->getIndices()[0] != 0)
          continue;
        EV->replaceAllUsesWith(It->second);
        ToErase.push_back(EV);
      }
    }
  }
  for (Instruction *I : ToErase) {
    taint.Tainted.erase(I);
    I->eraseFromParent();
  }

  return rebind;
}

}  // namespace cq
