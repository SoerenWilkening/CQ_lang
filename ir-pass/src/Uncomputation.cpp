// Uncomputation.cpp — see header. The Step-1 conservative slice: emit the
// rotation adjoint + `cqrt_free` for rotation-only single-register terminals.

#include "Uncomputation.h"

#include "ControlledSymbols.h"
#include "EmitInverse.h"
#include "FreePoint.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include <utility>

using namespace llvm;

namespace cq {

namespace {

// An uncontrolled rotation gate `cqrt_ry/rz_<W>(handle, θ)` taking `Handle` as
// arg 0? These are the only gates the Step-1 conservative slice reverses.
bool isRotationGateOn(const CallInst *G, const Value *Handle) {
  const Function *Callee = G->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  return (N.starts_with("cqrt_ry_") || N.starts_with("cqrt_rz_")) &&
         !N.contains("_controlled") && G->arg_size() == 2 &&
         G->getArgOperand(0) == Handle;
}

}  // namespace

void uncompute(Module &M, WidthDispatch &wd, TaintSet &taint) {
  ControlledSymbols csyms(M, wd);

  // Module-scoped: walks every function. In the `runOnFunction` shim only the
  // requested F's rotations were lowered to `cqrt_alloc_<W>`, so only F yields
  // candidates below (other functions keep their unlowered `cq_theta_*` calls)
  // — the per-function side-effect contract holds without explicit scoping.
  // (Phase-5 IMPLEMENTATION §8 Q4: the target set reads the module-wide taint.)
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;

    // Collect candidate terminals FIRST (a full walk), then emit — so the
    // freshly-inserted adjoint / free calls are never re-scanned. A candidate
    // is a tainted `cqrt_alloc_<W>` handle whose EVERY user is an uncontrolled
    // rotation gate on it (rotation-only). Any other user — a template op, a
    // measure sink, a controlled gate (handle as arg 1), a `ret`, a classical
    // read — disqualifies it (conservative; ChainWalk generalizes in Step 2).
    SmallVector<std::pair<CallInst *, SmallVector<CallInst *, 4>>, 8> Targets;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *H = dyn_cast<CallInst>(&I);
        if (!H)
          continue;
        Function *Callee = H->getCalledFunction();
        if (!Callee || !Callee->getName().starts_with("cqrt_alloc_"))
          continue;
        if (!taint.Tainted.count(H))
          continue;

        SmallVector<CallInst *, 4> Gates;
        bool RotationOnly = true;
        for (User *U : H->users()) {
          auto *G = dyn_cast<CallInst>(U);
          if (G && isRotationGateOn(G, H)) {
            Gates.push_back(G);
          } else {
            RotationOnly = false;
            break;
          }
        }
        if (!RotationOnly || Gates.empty())
          continue;

        // Conservative: only same-block gate sets (a single-register prep
        // chain). Cross-block rotation chains land in Step 2 (ChainWalk).
        BasicBlock *GB = Gates.front()->getParent();
        if (!llvm::all_of(Gates,
                          [&](CallInst *G) { return G->getParent() == GB; }))
          continue;

        Targets.push_back({H, std::move(Gates)});
      }
    }
    if (Targets.empty())
      continue;

    PostDominatorTree PDT(F);
    IRBuilder<> B(F.getContext());
    for (auto &T : Targets) {
      CallInst *H = T.first;
      SmallVectorImpl<CallInst *> &Gates = T.second;

      FreePoint FP = computeFreePoint(H, F, PDT, taint);
      if (FP.Kind != FreePointKind::Insert)
        continue;

      // Forward program order, then emit the adjoint in reverse (EmitInverse
      // reverses internally), then `cqrt_free` at the same point (PRD §2.10).
      llvm::sort(Gates, [](const CallInst *A, const CallInst *Bc) {
        return A->comesBefore(Bc);
      });
      B.SetInsertPoint(FP.At);
      emitInverseChain(B, Gates, wd, csyms);
      CallInst *Free = B.CreateCall(wd.freeFn(), {H});
      if (DebugLoc DL = H->getDebugLoc())
        Free->setDebugLoc(DL);
    }
  }
}

}  // namespace cq
