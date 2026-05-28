// MidHandleRebind.cpp — Mid-struct → i32-handle SSA rebinding. Behavior
// preserved from the original monolith's steps 2 and 3, generalized
// from `qint_mid_t`-only recognition to the full 14-entry
// mid-struct table via `WidthDispatch::midStructToSuffix`. The
// rebinding logic (replace struct-typed SSA value with i32 handle) is
// unchanged — handles are i32 across every ABI width per PRD §"Width
// unification" — but the per-init alloc symbol now switches per width:
// `qfloat_mid_t` → `cqrt_alloc_f32`, `qbool_mid_t` → `cqrt_alloc_i1`,
// and so on.

#include "MidHandleRebind.h"

#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include <optional>
#include <vector>

using namespace llvm;

namespace cq {

namespace {

// Recognize an init's mid-struct return type → its 14-suffix. Returns
// std::nullopt if the init's return type is not one of the known
// identified-struct shapes (e.g., a future SROA-flattened init whose
// signature already lost the struct wrapper). Callers fall back to
// extracting the suffix from the function name in that case.
std::optional<StringRef> suffixFromInitStructReturn(const CallInst *Init,
                                                    const WidthDispatch &wd) {
  auto *ST = dyn_cast<StructType>(Init->getType());
  if (!ST)
    return std::nullopt;
  return wd.midStructToSuffix(ST);
}

// Extract the suffix from the init function name (`cq_init_<sfx>`).
// Used as a fallback when the init's return type has already been
// flattened past the mid-struct wrapper. Returns "" if the name doesn't
// match the expected prefix.
StringRef suffixFromInitName(const CallInst *Init) {
  Function *Callee = Init->getCalledFunction();
  if (!Callee)
    return {};
  StringRef N = Callee->getName();
  constexpr StringRef kPrefix = "cq_init_";
  if (!N.starts_with(kPrefix))
    return {};
  return N.substr(kPrefix.size());
}

}  // namespace

RebindMap rebindMids(Module &M, WidthDispatch &wd, TaintSet &taint) {
  RebindMap rebind;
  if (taint.InitCalls.empty())
    return rebind;

  IRBuilder<> Builder(wd.context());

  // --- Step 2 (legacy, width-widened): emit cqrt_alloc_<W>(value) per
  // init, build the struct→handle map, and (flattened-shape only) RAUW
  // the init result.
  //
  // The RAUW for the flattened shape is critical: it gives downstream
  // passes (taint-set-driven OpcodeLowering, MeasureLowering pattern c)
  // real i32 SSA edges to follow, because in the flattened shape there
  // is no extractvalue intermediary. The struct shape keeps the init's
  // struct uses alive until step 7 (eraseDeadInits) reclaims them.
  //
  // The per-init alloc symbol is selected per width. We resolve
  // the suffix from the init's struct return type first (the 14-entry
  // mid-struct table); if that fails (flattened shape) we fall back to
  // the function name (`cq_init_<sfx>`). Either way we then compute the
  // ABI width and ask WidthDispatch for the matching alloc decl.
  for (CallInst *Init : taint.InitCalls) {
    StringRef Sfx;
    if (auto FromStruct = suffixFromInitStructReturn(Init, wd))
      Sfx = *FromStruct;
    else
      Sfx = suffixFromInitName(Init);
    if (Sfx.empty())
      continue;
    StringRef AbiWidth = wd.abiWidthFor(Sfx);
    if (AbiWidth.empty())
      continue;
    FunctionCallee AllocFn = wd.allocFn(AbiWidth);
    if (!AllocFn)
      continue;

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

    // Flattened (`-O1` SROA) shape: the init's return type equals the
    // ABI scalar type (i1/i8/.../f64) for this width, so we can rewire
    // init users straight to the alloc. The struct shape leaves
    // `Init->getType()` as a StructType and falls through to step 3's
    // extractvalue rewriting. Originally this branch was i32-only; now
    // every supported width can take the flattened path.
    Type *AbiTy = wd.llvmTypeFor(Sfx, wd.context());
    if (AbiTy && Init->getType() == AbiTy) {
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
