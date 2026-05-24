// CQLoweringPass.cpp — Phase 1 production port of the cq-lowering pass.
//
// Ported from prototype/cq_pass.cpp. Deltas vs. prototype (per
// phases/phase1/PLAN.md §4.5):
//
//   * `cq_measure`               -> `cq_measure_i32`
//   * `cqrt_measure`             -> `cqrt_measure_i32`  (and now returns i32)
//   * fresh-ancilla `cqrt_alloc_i32` dropped from add lowering;
//     the template returns its own handle.
//   * `cqrt_template_add_i32`    -> `cq_template_add_i32`
//     (returns i32 handle; takes two i32 operands).
//
// Other prototype passes (cq-uncompute, cq-specialize, cq-control) stay in
// the prototype directory — Phase 1 productionizes only cq-lowering.

#include "CQLoweringPass.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <set>
#include <vector>

using namespace llvm;

namespace cq {

PreservedAnalyses CQLoweringPass::run(Module &M, ModuleAnalysisManager &) {
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    Changed |= runOnFunction(F);
  }

  // Module-level cleanup: erase the front-end intrinsic declarations now
  // that all call sites have been lowered. Matches the architecture's
  // promise that no @cq_* (init/measure) remains in the IR after this pass.
  if (Changed) {
    for (const char *Name : {"cq_init_i32", "cq_measure_i32"}) {
      if (Function *FE = M.getFunction(Name)) {
        if (FE->use_empty())
          FE->eraseFromParent();
      }
    }
  }

  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

bool CQLoweringPass::runOnFunction(Function &F) {
  Module &M = *F.getParent();
  LLVMContext &Ctx = M.getContext();
  IRBuilder<> Builder(Ctx);

  Type *I32 = Type::getInt32Ty(Ctx);

  // --- Step 1: collect cq_init_i32 and cq_measure_i32 call sites. ---
  //
  // This precedes the runtime decl insertion so a function with zero
  // front-end intrinsics doesn't leak `cqrt_*` / `cq_template_*` declarations
  // into the module. (The LIT fixture passthrough_no_quantum.ll pins this.)

  std::vector<CallInst *> InitCalls;
  std::vector<CallInst *> MeasureCalls;
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI)
        continue;
      Function *Callee = CI->getCalledFunction();
      if (!Callee)
        continue;
      StringRef N = Callee->getName();
      if (N == "cq_init_i32")
        InitCalls.push_back(CI);
      else if (N == "cq_measure_i32")
        MeasureCalls.push_back(CI);
    }
  }

  if (InitCalls.empty() && MeasureCalls.empty())
    return false;

  // --- Declare the runtime functions lazily, on first use. ---
  //
  // Declarations are inserted only when the function actually has work that
  // calls into them. This keeps cq_template_add_i32 out of modules that
  // contain only measure-without-add, and similarly avoids leaking
  // cqrt_alloc_classical_i32 / cqrt_measure_i32 into measure-only or
  // init-only functions. The LIT fixtures measure_only.ll and
  // passthrough_no_quantum.ll pin this behavior.
  //
  // cq_template_add_i32 returns a fresh handle and takes the two operand
  // handles — no out-handle parameter (the template owns its allocation,
  // resolving PRD open item §6.3).
  auto getAllocClassical = [&]() {
    return M.getOrInsertFunction("cqrt_alloc_classical_i32",
                                 FunctionType::get(I32, {I32}, false));
  };
  auto getTemplateAdd = [&]() {
    return M.getOrInsertFunction("cq_template_add_i32",
                                 FunctionType::get(I32, {I32, I32}, false));
  };
  auto getMeasureRT = [&]() {
    return M.getOrInsertFunction("cqrt_measure_i32",
                                 FunctionType::get(I32, {I32}, false));
  };

  // --- Step 2: replace each @cq_init_i32(value) with
  // @cqrt_alloc_classical_i32(value). The init call canonically returns a
  // %qint_mid_t struct, but clang -O1 SROAs the single-field struct down
  // to a bare i32 (visible in the post-Clang IR for the e2e fixtures).
  // Track the mapping so the extractvalue cleanup in step 3 can rewire
  // users to the handle. In the i32-flattened shape there is no
  // extractvalue to rewire, so we additionally RAUW the init to the alloc
  // directly (types match, so this is sound) — that gives step 4's taint
  // worklist real users to walk through. ---

  DenseMap<Value *, Value *> StructToHandle;
  if (!InitCalls.empty()) {
    FunctionCallee AllocClassical = getAllocClassical();
    for (CallInst *Init : InitCalls) {
      Builder.SetInsertPoint(Init);
      Value *Val = Init->getArgOperand(0);
      CallInst *Alloc = Builder.CreateCall(AllocClassical, {Val}, "h");
      if (DebugLoc DL = Init->getDebugLoc())
        Alloc->setDebugLoc(DL);
      StructToHandle[Init] = Alloc;
      // Flattened-struct shape (post clang -O1): Init returns i32 and
      // its direct users (e.g. `add i32 %2, %1` and
      // `cq_measure_i32(i32 %1)`) point straight at the Init result. We
      // rewire those uses to the Alloc so taint propagation in step 4 has
      // edges to follow and the measure operand-match in step 6 sees the
      // tainted handle. The non-flattened (struct) shape is handled by
      // the extractvalue cleanup in step 3 instead.
      if (Init->getType() == I32)
        Init->replaceAllUsesWith(Alloc);
    }
  }

  // --- Step 3: rewrite extractvalue %s, 0 → use handle directly. ---

  std::vector<Instruction *> ToErase;
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      auto *EV = dyn_cast<ExtractValueInst>(&I);
      if (!EV)
        continue;
      Value *Agg = EV->getAggregateOperand();
      auto It = StructToHandle.find(Agg);
      if (It == StructToHandle.end())
        continue;
      if (EV->getNumIndices() != 1 || EV->getIndices()[0] != 0)
        continue;
      EV->replaceAllUsesWith(It->second);
      ToErase.push_back(EV);
    }
  }
  for (Instruction *I : ToErase)
    I->eraseFromParent();
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
      if (!I)
        continue;
      // Don't propagate through measurement (it's a taint sink).
      if (auto *CI = dyn_cast<CallInst>(I)) {
        Function *Callee = CI->getCalledFunction();
        if (Callee) {
          StringRef N = Callee->getName();
          if (N == "cq_measure_i32" || N == "cqrt_measure_i32")
            continue;
        }
      }
      if (Tainted.insert(I).second)
        Worklist.push_back(I);
    }
  }

  // --- Step 5: lower tainted `add i32 %a, %b` to template call. ---
  //
  // Each tainted add becomes:
  //   %h_sum = call i32 @cq_template_add_i32(i32 %a, i32 %b)
  // and `%c`'s users are rewired to `%h_sum`. The template owns its own
  // allocation; the prototype's fresh-ancilla preamble (cqrt_alloc_i32)
  // is dropped (PLAN.md §4.5, §6.3).

  std::vector<BinaryOperator *> TaintedAdds;
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      auto *BO = dyn_cast<BinaryOperator>(&I);
      if (!BO)
        continue;
      if (BO->getOpcode() != Instruction::Add)
        continue;
      if (BO->getType() != I32)
        continue;
      if (!Tainted.count(BO))
        continue;
      TaintedAdds.push_back(BO);
    }
  }

  if (!TaintedAdds.empty()) {
    FunctionCallee TemplateAdd = getTemplateAdd();
    for (BinaryOperator *Add : TaintedAdds) {
      Builder.SetInsertPoint(Add);
      Value *A = Add->getOperand(0);
      Value *B = Add->getOperand(1);
      CallInst *T = Builder.CreateCall(TemplateAdd, {A, B}, "h_sum");
      if (DebugLoc DL = Add->getDebugLoc())
        T->setDebugLoc(DL);
      Add->replaceAllUsesWith(T);
      Tainted.insert(T);
      Tainted.erase(Add);
      ToErase.push_back(Add);
    }
  }
  for (Instruction *I : ToErase)
    I->eraseFromParent();
  ToErase.clear();

  // --- Step 6: lower @cq_measure_i32 to @cqrt_measure_i32. ---
  //
  // Three operand patterns are recognized:
  //
  //  (a) The struct arg is a direct @cq_init_i32 call that step 2 already
  //      mapped to a handle (the canonical -O0-shaped measure_only
  //      fixture: %s = call @cq_init_i32(..); %m = call @cq_measure_i32(%s)).
  //      Use the mapped handle directly.
  //
  //  (b) The struct arg is `insertvalue %qint_mid_t poison, i32 %h, 0`
  //      (the post-O1, post-add-lowering shape from lowering_basic). Pull
  //      the handle out of the insertvalue and erase the insertvalue if
  //      it's only used by this measure.
  //
  //  (c) The struct arg is already an i32 SSA value carrying a tainted
  //      handle. This is the post-clang-O1 shape, where SROA/IPSCCP
  //      flattens the single-field `qint_mid_t` struct so both
  //      `cq_init_i32` and `cq_measure_i32` operate on `i32` directly,
  //      and the measure's argument is e.g. the result of a now-lowered
  //      `cq_template_add_i32` call (or, in the cast-rewriter path, a
  //      handle SSA value that has flowed through plain i32 IR). The
  //      taint set computed in step 4 (+ updates from step 5) tells us
  //      which i32 SSA values carry quantum handles. The CastRewrite
  //      module (transpiler/src/CastRewrite.cpp) pins this case via the
  //      worked_example / mixed_operand / full_example e2e fixtures.

  if (!MeasureCalls.empty()) {
    FunctionCallee MeasureRT = getMeasureRT();
    for (CallInst *Measure : MeasureCalls) {
      Value *StructArg = Measure->getArgOperand(0);
      Value *Handle = nullptr;
      InsertValueInst *IVToErase = nullptr;

      if (auto It = StructToHandle.find(StructArg);
          It != StructToHandle.end()) {
        // Pattern (a): init→handle mapping already gave us the SSA value.
        Handle = It->second;
      } else if (auto *IV = dyn_cast<InsertValueInst>(StructArg)) {
        if (IV->getNumIndices() == 1 && IV->getIndices()[0] == 0) {
          // Pattern (b): pull from insertvalue.
          Handle = IV->getInsertedValueOperand();
          if (IV->hasOneUse())
            IVToErase = IV;
        }
      } else if (StructArg->getType() == I32 && Tainted.count(StructArg)) {
        // Pattern (c): flattened-struct shape — the arg is already an
        // i32 SSA value carrying a tainted handle (init result, or
        // cq_template_add_i32 result from step 5). Use it as-is.
        Handle = StructArg;
      }

      if (!Handle) {
        F.getContext().diagnose(DiagnosticInfoUnsupported(
            F, "cq_measure_i32 operand pattern not recognized; expected "
               "direct cq_init_i32 result, insertvalue %struct poison, "
               "i32 %h, 0, or tainted i32 handle"));
        continue;
      }

      Builder.SetInsertPoint(Measure);
      CallInst *NewM = Builder.CreateCall(MeasureRT, {Handle}, "m");
      if (DebugLoc DL = Measure->getDebugLoc())
        NewM->setDebugLoc(DL);
      Measure->replaceAllUsesWith(NewM);
      ToErase.push_back(Measure);
      if (IVToErase)
        ToErase.push_back(IVToErase);
    }
  }
  for (Instruction *I : ToErase)
    I->eraseFromParent();
  ToErase.clear();

  // --- Step 7: erase the original cq_init_i32 calls (now use-less). ---

  for (CallInst *Init : InitCalls) {
    if (Init->use_empty())
      Init->eraseFromParent();
  }

  return true;
}

}  // namespace cq
