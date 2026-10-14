// SpecializeGateInline.cpp — gate subroutines compiled at their call site (bd
// test_C_libtooling-p3kd.21). The contract and the trigger list are in
// SpecializeGateInline.h.

#include "SpecializeGateInline.h"

#include "llvm/ADT/SCCIterator.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/CallGraph.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/AttributeMask.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include <cstdlib>
#include <memory>

using namespace llvm;

namespace cq {

namespace {

// The gate-subroutine closure: a defined function holding a front-end primitive
// (exact call-site membership), or directly calling a member. `StoresTainted` is
// the closure of "stores a tainted value" over the same call edges (trigger b).
struct GateSets {
  SmallPtrSet<const Function *, 16> Gate;
  SmallPtrSet<const Function *, 16> StoresTainted;
  SmallPtrSet<const Function *, 16> Recursive;
};

GateSets collectGateSets(Module &M, const TaintSet &taint) {
  GateSets S;
  auto mark = [&](const CallInst *CI) {
    if (CI && CI->getParent())
      S.Gate.insert(CI->getFunction());
  };
  for (const CallInst *CI : taint.ThetaCalls)
    mark(CI);
  for (const CallInst *CI : taint.PhaseCalls)
    mark(CI);
  for (const CallInst *CI : taint.MeasureCalls)
    mark(CI);
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : instructions(F))
      if (auto *SI = dyn_cast<StoreInst>(&I))
        if (taint.Tainted.count(SI->getValueOperand())) {
          S.StoresTainted.insert(&F);
          break;
        }
  }
  // Close both sets over direct call edges.
  bool Changed = true;
  while (Changed) {
    Changed = false;
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      for (Instruction &I : instructions(F)) {
        auto *CB = dyn_cast<CallBase>(&I);
        const Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (!Callee || Callee->isDeclaration())
          continue;
        if (S.Gate.count(Callee) && S.Gate.insert(&F).second)
          Changed = true;
        if (S.StoresTainted.count(Callee) && S.StoresTainted.insert(&F).second)
          Changed = true;
      }
    }
  }
  CallGraph CG(M);
  for (scc_iterator<CallGraph *> I = scc_begin(&CG); !I.isAtEnd(); ++I)
    if (I.hasCycle())
      for (CallGraphNode *N : *I)
        if (const Function *F = N->getFunction())
          S.Recursive.insert(F);
  return S;
}

// (d): is `CB`'s block control-dependent on a tainted conditional terminator of
// its function? A terminator `T` in block `B` governs `CB` iff `CB`'s block is
// reachable from a successor of `B` and does not post-dominate `B`.
bool underTaintedControl(const CallBase &CB, const PostDominatorTree &PDT,
                         const TaintSet &taint) {
  const BasicBlock *Site = CB.getParent();
  for (const BasicBlock &B : *CB.getFunction()) {
    const Instruction *T = B.getTerminator();
    const Value *Cond = nullptr;
    if (const auto *BI = dyn_cast_or_null<BranchInst>(T))
      Cond = BI->isConditional() ? BI->getCondition() : nullptr;
    else if (const auto *SI = dyn_cast_or_null<SwitchInst>(T))
      Cond = SI->getCondition();
    if (!Cond || !taint.Tainted.count(const_cast<Value *>(Cond)))
      continue;
    if (PDT.dominates(Site, &B))
      continue;
    for (const BasicBlock *Succ : successors(&B))
      if (isPotentiallyReachable(Succ, Site))
        return true;
  }
  return false;
}

// (b), caller half: does the object `P` points into receive a tainted store in
// the caller?
bool receivesTaintedStore(const Value *P, const Function &Caller,
                          const TaintSet &taint) {
  const Value *Obj = getUnderlyingObject(P);
  for (const Instruction &I : instructions(Caller))
    if (const auto *SI = dyn_cast<StoreInst>(&I))
      if (taint.Tainted.count(SI->getValueOperand()) &&
          getUnderlyingObject(SI->getPointerOperand()) == Obj)
        return true;
  return false;
}

// (c): does a `ret` of `F` return a register `F` itself rotates? The backward
// tainted slice of a returned value reaches a `cq_theta` result of the callee
// without crossing a CALL RESULT. A call result is crossed by nobody: its taint
// is propagation's conservative prediction for a lift site (bd cepm), settled by
// the specializer after the dead-argument drop's slot B, and a ret tainted only
// through one is not yet a quantum return (measured: `w` in
// slice_spec_dropped_arg_musttail_return returns `h2(p, k + z)`, classical once
// the drop nulls the dead `musttail` slot, and must stay a standalone body).
// A call to a GATE callee that itself returns its own register is crossed (the
// question recurses into it; a call-cycle member answers no and keeps its loud
// owner).
bool returnsOwnRegister(const Function &F, const GateSets &S,
                        const TaintSet &taint,
                        SmallPtrSetImpl<const Function *> &Visiting) {
  if (S.Recursive.count(&F) || !Visiting.insert(&F).second)
    return false;
  SmallVector<const Value *, 16> Work;
  SmallPtrSet<const Value *, 32> Seen;
  for (const BasicBlock &BB : F)
    if (const auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
      if (const Value *RV = R->getReturnValue())
        Work.push_back(RV);
  while (!Work.empty()) {
    const Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second || !taint.Tainted.count(const_cast<Value *>(V)))
      continue;
    if (const auto *CI = dyn_cast<CallInst>(V)) {
      if (taint.ThetaCalls.contains(const_cast<CallInst *>(CI)))
        return true;
      const Function *G = CI->getCalledFunction();
      if (G && !G->isDeclaration() && S.Gate.count(G) &&
          returnsOwnRegister(*G, S, taint, Visiting))
        return true;
      continue;  // any other call result: never crossed.
    }
    if (const auto *I = dyn_cast<Instruction>(V))
      for (const Value *Op : I->operands())
        Work.push_back(Op);
  }
  return false;
}

bool shouldInline(CallInst &CI, const Function &Callee, const GateSets &S,
                  const TaintSet &taint,
                  std::unique_ptr<PostDominatorTree> &PDT) {
  bool HasPtrArg = false;
  for (const Use &U : CI.args()) {
    if (taint.Tainted.count(U.get()))
      return true;  // (a)
    if (U->getType()->isPointerTy()) {
      HasPtrArg = true;
      if (receivesTaintedStore(U.get(), *CI.getFunction(), taint))
        return true;  // (b), caller half
    }
  }
  if (HasPtrArg && S.StoresTainted.count(&Callee))
    return true;  // (b), callee half
  // (c): a used tainted result is the 3jru crossing; an UNUSED one at a non-i32
  // width is still a call to a function whose `ret` the non-i32 escape guard
  // refuses (the callee has a use, so it is no export).
  SmallPtrSet<const Function *, 8> Visiting;
  if (returnsOwnRegister(Callee, S, taint, Visiting) &&
      (!CI.use_empty() || !Callee.getReturnType()->isIntegerTy(32)))
    return true;
  if (!PDT)
    PDT = std::make_unique<PostDominatorTree>(*CI.getFunction());
  return underTaintedControl(CI, *PDT, taint);  // (d)
}

// clang's `-O1` per-function simplification (the step the CGSCC inliner runs on
// a caller after inlining into it), over exactly the callers that changed.
void simplifyCallers(ArrayRef<Function *> Callers) {
  LoopAnalysisManager LAM;
  FunctionAnalysisManager FAM;
  CGSCCAnalysisManager CGAM;
  ModuleAnalysisManager MAM;
  PassBuilder PB;
  PB.registerModuleAnalyses(MAM);
  PB.registerCGSCCAnalyses(CGAM);
  PB.registerFunctionAnalyses(FAM);
  PB.registerLoopAnalyses(LAM);
  PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);
  FunctionPassManager FPM = PB.buildFunctionSimplificationPipeline(
      OptimizationLevel::O1, ThinOrFullLTOPhase::None);
  for (Function *F : Callers)
    FPM.run(*F, FAM);
}

}  // namespace

bool inlineGateSubroutines(Module &M, const TaintSet &taint) {
  const GateSets S = collectGateSets(M, taint);
  if (S.Gate.empty())
    return false;

  // Decide every site on one consistent taint snapshot, then mutate.
  SmallVector<CallInst *, 8> Sites;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    std::unique_ptr<PostDominatorTree> PDT;
    for (Instruction &I : instructions(F)) {
      auto *CI = dyn_cast<CallInst>(&I);
      Function *Callee = CI ? CI->getCalledFunction() : nullptr;
      if (!Callee || Callee->isDeclaration() || !S.Gate.count(Callee) ||
          S.Recursive.count(Callee) || Callee == &F)
        continue;
      if (shouldInline(*CI, *Callee, S, taint, PDT))
        Sites.push_back(CI);
    }
  }
  if (Sites.empty())
    return false;

  SetVector<Function *> Callers;
  SmallPtrSet<Function *, 8> Inlined;
  for (CallInst *CI : Sites) {
    Function *Caller = CI->getFunction();
    Function *Callee = CI->getCalledFunction();
    InlineFunctionInfo IFI;
    if (InlineFunction(*CI, IFI).isSuccess()) {
      Callers.insert(Caller);
      Inlined.insert(Callee);
    }
  }
  if (Callers.empty())
    return false;
  simplifyCallers(Callers.getArrayRef());
  // Debug lever (env-gated, no behaviour change; the CQ_RAILBANK_DBG precedent):
  // a module that later declines prints nothing on stdout.
  if (::getenv("CQ_GATEINLINE_DBG"))
    for (Function *F : Callers)
      F->print(llvm::errs());

  // A local gate subroutine with no use left would be lowered standalone with
  // classical parameters: erase it (its every call site is now caller code).
  for (Function *F : Inlined)
    if (F->hasLocalLinkage() && F->use_empty())
      F->eraseFromParent();
  return true;
}

// The no-use test of `declineQuantumReturnCalls` (TaintPropagation.cpp): a
// `@llvm.used` / `@llvm.compiler.used` entry keeps `F` alive and reads nothing.
static bool onlyUsedListUsers(const Function &F) {
  for (const User *U : F.users()) {
    const auto *C = dyn_cast<Constant>(U);
    if (!C || isa<GlobalValue>(C) || C->use_empty())
      return false;
    for (const User *CU : C->users()) {
      const auto *GV = dyn_cast<GlobalVariable>(CU);
      if (!GV || (GV->getName() != "llvm.used" &&
                  GV->getName() != "llvm.compiler.used"))
        return false;
    }
  }
  return true;
}

bool isQuantumReturnExport(const Function &F) {
  Type *RT = F.getReturnType();
  if (F.isDeclaration() || RT->isIntegerTy(32) ||
      !(RT->isIntegerTy() || RT->isFloatingPointTy()))
    return false;
  return onlyUsedListUsers(F);
}

static constexpr char kMsgNonI32ReturnExport[] =
    "cq taint escape: tainted value returned at non-i32 width";

bool retypeQuantumExportReturns(Module &M) {
  SmallVector<Function *, 2> Work;
  for (Function &F : M) {
    if (!isQuantumReturnExport(F))
      continue;
    bool AnyHandle = false, AnyOther = false;
    const ReturnInst *Other = nullptr;
    for (BasicBlock &BB : F)
      if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator())) {
        Value *RV = R->getReturnValue();
        if (RV && RV->getType() != F.getReturnType() &&
            RV->getType()->isIntegerTy(32))
          AnyHandle = true;
        else {
          AnyOther = true;
          Other = R;
        }
      }
    if (!AnyHandle)
      continue;  // nothing returned a register: a classical function.
    if (AnyOther) {
      F.getContext().diagnose(DiagnosticInfoUnsupported(
          F, kMsgNonI32ReturnExport, Other->getDebugLoc()));
      return true;
    }
    Work.push_back(&F);
  }
  for (Function *F : Work) {
    LLVMContext &Ctx = F->getContext();
    SmallVector<Type *, 8> Params(F->getFunctionType()->params());
    FunctionType *FT = FunctionType::get(Type::getInt32Ty(Ctx), Params,
                                         F->isVarArg());
    Function *NF = Function::Create(FT, F->getLinkage(), F->getAddressSpace(),
                                    "", F->getParent());
    NF->copyAttributesFrom(F);
    // The return attributes (`zeroext`, `noundef`, `nofpclass`, …) described the
    // `iN`; the handle carries none of them.
    NF->setAttributes(NF->getAttributes().removeRetAttributes(Ctx, AttributeMask(NF->getAttributes().getRetAttrs())));
    NF->setSubprogram(F->getSubprogram());
    NF->splice(NF->end(), F);
    for (auto [A, NA] : zip(F->args(), NF->args())) {
      NA.takeName(&A);
      A.replaceAllUsesWith(&NA);
    }
    NF->takeName(F);
    F->replaceAllUsesWith(NF);  // only `@llvm.used`-list entries remain.
    F->eraseFromParent();
  }
  return false;
}

}  // namespace cq
