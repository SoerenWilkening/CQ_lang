// CQ pass plugin — Phase 2/5/7 prototypes.
//
// Validates the no-LLVM-fork architectural claim from docs/llvm-fork-analysis.md
// across three orthogonal slices:
//   - cq-lowering   (Phase 2): cq_init_i32 + tainted add + cq_measure → cqrt_*
//   - cq-uncompute  (Phase 5): last-use-driven cqrt_free emission via
//                              stock PostDominatorTree analysis
//   - cq-specialize (Phase 7): function cloning + call-site retargeting
//                              via stock CloneFunction
//
// Strictly minimal scope per slice (see prototype/README.md for what is
// deferred to real backend implementation).

#include "llvm/ADT/DenseMap.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"

#include <set>
#include <vector>

using namespace llvm;

namespace {

// === Pass implementation ===

struct CQLoweringPass : PassInfoMixin<CQLoweringPass> {

  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    bool Changed = false;
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      Changed |= runOnFunction(F);
    }

    // Module-level cleanup: erase the front-end intrinsic declarations now
    // that all call sites have been lowered. Matches the architecture's
    // promise that no @cq_* remains in the IR after this pass.
    if (Changed) {
      for (const char *Name : {"cq_init_i32", "cq_measure"}) {
        if (Function *FE = M.getFunction(Name)) {
          if (FE->use_empty()) FE->eraseFromParent();
        }
      }
    }

    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }

  static bool runOnFunction(Function &F) {
    Module &M = *F.getParent();
    LLVMContext &Ctx = M.getContext();
    IRBuilder<> Builder(Ctx);

    Type *I32 = Type::getInt32Ty(Ctx);
    Type *I64 = Type::getInt64Ty(Ctx);
    Type *Void = Type::getVoidTy(Ctx);

    // --- Declare the cqrt_* runtime functions in the module. ---

    FunctionCallee AllocClassical = M.getOrInsertFunction(
        "cqrt_alloc_classical_i32",
        FunctionType::get(I32, {I32}, false));
    FunctionCallee AllocFresh = M.getOrInsertFunction(
        "cqrt_alloc_i32",
        FunctionType::get(I32, {}, false));
    FunctionCallee TemplateAdd = M.getOrInsertFunction(
        "cqrt_template_add_i32",
        FunctionType::get(Void, {I32, I32, I32}, false));
    FunctionCallee MeasureRT = M.getOrInsertFunction(
        "cqrt_measure",
        FunctionType::get(I64, {I32}, false));

    // --- Step 1: collect cq_init_i32 and cq_measure call sites. ---

    std::vector<CallInst *> InitCalls;
    std::vector<CallInst *> MeasureCalls;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI) continue;
        Function *Callee = CI->getCalledFunction();
        if (!Callee) continue;
        StringRef N = Callee->getName();
        if (N == "cq_init_i32") InitCalls.push_back(CI);
        else if (N == "cq_measure") MeasureCalls.push_back(CI);
      }
    }

    if (InitCalls.empty() && MeasureCalls.empty())
      return false;

    // --- Step 2: replace each @cq_init_i32(value) with @cqrt_alloc_classical_i32(value). ---
    // The init call returns a %qint_mid_t struct; the alloc call returns an i32 handle.
    // We track the mapping so subsequent extractvalue ops can be rewired.

    DenseMap<Value *, Value *> StructToHandle;
    for (CallInst *Init : InitCalls) {
      Builder.SetInsertPoint(Init);
      Value *Val = Init->getArgOperand(0);
      CallInst *Alloc = Builder.CreateCall(AllocClassical, {Val}, "h");
      if (DebugLoc DL = Init->getDebugLoc()) Alloc->setDebugLoc(DL);
      StructToHandle[Init] = Alloc;
    }

    // --- Step 3: rewrite extractvalue %s, 0 → use handle directly. ---

    std::vector<Instruction *> ToErase;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *EV = dyn_cast<ExtractValueInst>(&I);
        if (!EV) continue;
        Value *Agg = EV->getAggregateOperand();
        auto It = StructToHandle.find(Agg);
        if (It == StructToHandle.end()) continue;
        if (EV->getNumIndices() != 1 || EV->getIndices()[0] != 0) continue;
        EV->replaceAllUsesWith(It->second);
        ToErase.push_back(EV);
      }
    }
    for (Instruction *I : ToErase) I->eraseFromParent();
    ToErase.clear();

    // --- Step 4: forward taint propagation. ---
    // Sources: the i32 handle SSA values produced by step 2.

    std::set<Value *> Tainted;
    std::vector<Value *> Worklist;
    for (auto &P : StructToHandle) {
      Tainted.insert(P.second);
      Worklist.push_back(P.second);
    }

    while (!Worklist.empty()) {
      Value *V = Worklist.back();
      Worklist.pop_back();
      for (User *U : V->users()) {
        auto *I = dyn_cast<Instruction>(U);
        if (!I) continue;
        // Don't propagate through measurement (it's a taint sink).
        if (auto *CI = dyn_cast<CallInst>(I)) {
          Function *Callee = CI->getCalledFunction();
          if (Callee) {
            StringRef N = Callee->getName();
            if (N == "cq_measure" || N == "cqrt_measure") continue;
          }
        }
        if (Tainted.insert(I).second) Worklist.push_back(I);
      }
    }

    // --- Step 5: lower tainted `add i32 %a, %b` to template call. ---
    // Each tainted add becomes:
    //   %h_sum = call i32 @cqrt_alloc_i32()
    //   call void @cqrt_template_add_i32(i32 %a, i32 %b, i32 %h_sum)
    // and `%c`'s users are rewired to `%h_sum`.

    std::vector<BinaryOperator *> TaintedAdds;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *BO = dyn_cast<BinaryOperator>(&I);
        if (!BO) continue;
        if (BO->getOpcode() != Instruction::Add) continue;
        if (BO->getType() != I32) continue;
        if (!Tainted.count(BO)) continue;
        TaintedAdds.push_back(BO);
      }
    }

    for (BinaryOperator *Add : TaintedAdds) {
      Builder.SetInsertPoint(Add);
      Value *A = Add->getOperand(0);
      Value *B = Add->getOperand(1);
      CallInst *Out = Builder.CreateCall(AllocFresh, {}, "h_sum");
      if (DebugLoc DL = Add->getDebugLoc()) Out->setDebugLoc(DL);
      CallInst *T = Builder.CreateCall(TemplateAdd, {A, B, Out});
      if (DebugLoc DL = Add->getDebugLoc()) T->setDebugLoc(DL);
      Add->replaceAllUsesWith(Out);
      Tainted.insert(Out);
      Tainted.erase(Add);
      ToErase.push_back(Add);
    }
    for (Instruction *I : ToErase) I->eraseFromParent();
    ToErase.clear();

    // --- Step 6: lower @cq_measure to @cqrt_measure. ---
    // Pattern recognized:
    //   %s = insertvalue %qint_mid_t poison, i32 %h, 0
    //   %m = call i64 @cq_measure(%qint_mid_t %s)
    // becomes:
    //   %m = call i64 @cqrt_measure(i32 %h)

    for (CallInst *Measure : MeasureCalls) {
      Value *StructArg = Measure->getArgOperand(0);
      auto *IV = dyn_cast<InsertValueInst>(StructArg);
      if (!IV || IV->getNumIndices() != 1 || IV->getIndices()[0] != 0) {
        F.getContext().diagnose(DiagnosticInfoUnsupported(
            F, "cq_measure operand pattern not recognized; expected "
               "insertvalue %struct poison, i32 %h, 0"));
        continue;
      }
      Value *Handle = IV->getInsertedValueOperand();
      Builder.SetInsertPoint(Measure);
      CallInst *NewM = Builder.CreateCall(MeasureRT, {Handle}, "m");
      if (DebugLoc DL = Measure->getDebugLoc()) NewM->setDebugLoc(DL);
      Measure->replaceAllUsesWith(NewM);
      ToErase.push_back(Measure);
      // Erase the insertvalue if it's only used by this measure call.
      if (IV->hasOneUse()) ToErase.push_back(IV);
    }
    for (Instruction *I : ToErase) I->eraseFromParent();
    ToErase.clear();

    // --- Step 7: erase the original cq_init_i32 calls (now use-less). ---

    for (CallInst *Init : InitCalls) {
      if (Init->use_empty()) Init->eraseFromParent();
    }

    return true;
  }
};

// === Phase 5: auto-uncomputation pass ===
//
// For each handle SSA value (i32 result of cqrt_alloc_classical_i32 or
// cqrt_alloc_i32), compute the post-dominating last-use point via stock
// PostDominatorTree analysis, and emit cqrt_free(handle) at that point.
// Handles that escape via `ret` are skipped.
//
// This is a placeholder for the full architecture (docs/architecture.md §7.4):
// the real uncomputation emits the *adjoint* of the gate sequence that
// produced the handle, then frees. The placeholder cqrt_free validates the
// analysis + insertion mechanism; adjoint emission is mechanical IR
// construction once the insertion point is known.

struct CQUncomputePass : PassInfoMixin<CQUncomputePass> {

  PreservedAnalyses run(Module &M, ModuleAnalysisManager &AM) {
    LLVMContext &Ctx = M.getContext();
    Type *I32 = Type::getInt32Ty(Ctx);
    Type *Void = Type::getVoidTy(Ctx);

    FunctionCallee FreeFn = M.getOrInsertFunction(
        "cqrt_free",
        FunctionType::get(Void, {I32}, false));

    auto &FAM =
        AM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();

    bool Changed = false;
    for (Function &F : M) {
      if (F.isDeclaration()) continue;
      Changed |= runOnFunction(F, FAM, FreeFn);
    }
    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }

  static bool runOnFunction(Function &F, FunctionAnalysisManager &FAM,
                            FunctionCallee FreeFn) {
    PostDominatorTree &PDT = FAM.getResult<PostDominatorTreeAnalysis>(F);

    std::vector<CallInst *> Handles;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI) continue;
        Function *Callee = CI->getCalledFunction();
        if (!Callee) continue;
        StringRef N = Callee->getName();
        if (N == "cqrt_alloc_classical_i32" || N == "cqrt_alloc_i32") {
          Handles.push_back(CI);
        }
      }
    }
    if (Handles.empty()) return false;

    IRBuilder<> Builder(F.getContext());
    bool Changed = false;
    for (CallInst *H : Handles) {
      Instruction *InsertBefore = computeFreePoint(H, PDT);
      if (!InsertBefore) continue;
      Builder.SetInsertPoint(InsertBefore);
      CallInst *Free = Builder.CreateCall(FreeFn, {H});
      if (DebugLoc DL = H->getDebugLoc()) Free->setDebugLoc(DL);
      Changed = true;
    }
    return Changed;
  }

  // Returns the instruction *before which* cqrt_free should be inserted,
  // or nullptr if the handle should not be freed (escapes via return,
  // or has no uses).
  static Instruction *computeFreePoint(Value *V, PostDominatorTree &PDT) {
    SmallVector<Instruction *, 8> Users;
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I) continue;
      if (isa<ReturnInst>(I)) return nullptr;
      Users.push_back(I);
    }
    if (Users.empty()) return nullptr;

    BasicBlock *Common = Users[0]->getParent();
    for (size_t i = 1; i < Users.size(); ++i) {
      Common = PDT.findNearestCommonDominator(Common, Users[i]->getParent());
      if (!Common) return nullptr;
    }

    Instruction *Latest = nullptr;
    for (Instruction *U : Users) {
      if (U->getParent() != Common) continue;
      if (!Latest || Latest->comesBefore(U)) Latest = U;
    }

    if (Latest) return Latest->getNextNode();
    return &*Common->getFirstInsertionPt();
  }
};

// === Phase 7: call-graph specialization pass ===
//
// For each call site whose argument list contains any qint_mid_t-typed
// struct value, clone the callee via stock CloneFunction, rename with
// __cq_q_<original>_q1 mangling, and retarget the call site to the clone.
//
// Minimal scope (per docs/llvm-fork-analysis.md §8.2): signature preserved
// (no handle ABI rewriting), no Bennett wrap-around (forward + CNOT-copy +
// reverse), no q-arg-mask discrimination beyond binary. The point is to
// confirm the cloning + call-site retargeting mechanism works on stock
// LLVM. Full specialization is downstream implementation against the same
// extension surface.

struct CQSpecializePass : PassInfoMixin<CQSpecializePass> {

  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    std::vector<CallInst *> ToSpecialize;
    for (Function &F : M) {
      if (F.isDeclaration()) continue;
      for (BasicBlock &BB : F) {
        for (Instruction &I : BB) {
          auto *CI = dyn_cast<CallInst>(&I);
          if (!CI) continue;
          Function *Callee = CI->getCalledFunction();
          if (!Callee || Callee->isDeclaration()) continue;
          // Skip front-end intrinsics, runtime, and already-specialized fns.
          StringRef N = Callee->getName();
          if (N.starts_with("cq_") ||
              N.starts_with("cqrt_") ||
              N.starts_with("__cq_")) continue;
          if (hasQintMidArg(CI)) ToSpecialize.push_back(CI);
        }
      }
    }
    if (ToSpecialize.empty()) return PreservedAnalyses::all();

    DenseMap<Function *, Function *> SpecCache;
    for (CallInst *CI : ToSpecialize) {
      Function *Orig = CI->getCalledFunction();
      Function *&Spec = SpecCache[Orig];
      if (!Spec) Spec = cloneAndMangle(Orig);
      CI->setCalledFunction(Spec);
    }
    return PreservedAnalyses::none();
  }

  static bool hasQintMidArg(CallInst *CI) {
    for (Value *Arg : CI->args()) {
      auto *ST = dyn_cast<StructType>(Arg->getType());
      if (!ST || !ST->hasName()) continue;
      if (ST->getName().starts_with("qint_mid")) return true;
    }
    return false;
  }

  static Function *cloneAndMangle(Function *Orig) {
    ValueToValueMapTy VMap;
    Function *Clone = CloneFunction(Orig, VMap);
    Clone->setName(("__cq_q_" + Orig->getName() + "_q1").str());
    Clone->setLinkage(GlobalValue::InternalLinkage);
    return Clone;
  }
};

}  // namespace

// === Pass plugin registration ===

llvm::PassPluginLibraryInfo getCQPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "cq-lowering", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, ModulePassManager &MPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "cq-lowering") {
                    MPM.addPass(CQLoweringPass());
                    return true;
                  }
                  if (Name == "cq-uncompute") {
                    MPM.addPass(CQUncomputePass());
                    return true;
                  }
                  if (Name == "cq-specialize") {
                    MPM.addPass(CQSpecializePass());
                    return true;
                  }
                  return false;
                });
          }};
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return getCQPluginInfo();
}
