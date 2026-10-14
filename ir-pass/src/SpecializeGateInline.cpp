// SpecializeGateInline.cpp — bd p3kd.21; contract and triggers in the header.

#include "SpecializeGateInline.h"

#include "llvm/ADT/SCCIterator.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/CallGraph.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
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

// The questions on one taint snapshot; `MayGain` is empty in the final re-ask.
struct Asker {
  const GateSets &S;
  const TaintSet &taint;
  std::function<bool(Value *)> MayGain;
  bool CrossCallResults;

  bool quantum(Value *V) const {
    return taint.Tainted.count(V) || (MayGain && MayGain(V));
  }

  // (d): is `CB`'s block control-dependent on a conditional terminator whose
  // condition is (or can become) quantum? `T` in block `B` governs `CB` iff
  // `CB`'s block is reachable from a successor of `B` and does not post-dominate
  // `B`.
  bool underQuantumControl(const CallBase &CB,
                           const PostDominatorTree &PDT) const {
    const BasicBlock *Site = CB.getParent();
    for (const BasicBlock &B : *CB.getFunction()) {
      const Instruction *T = B.getTerminator();
      Value *Cond = nullptr;
      if (const auto *BI = dyn_cast_or_null<BranchInst>(T))
        Cond = BI->isConditional() ? BI->getCondition() : nullptr;
      else if (const auto *SI = dyn_cast_or_null<SwitchInst>(T))
        Cond = SI->getCondition();
      if (!Cond || !quantum(Cond) || PDT.dominates(Site, &B))
        continue;
      for (const BasicBlock *Succ : successors(&B))
        if (isPotentiallyReachable(Succ, Site))
          return true;
    }
    return false;
  }

  // (b), caller half: does the object `P` points into receive a store of a
  // value that is (or can become) quantum in the caller?
  bool receivesQuantumStore(const Value *P, const Function &Caller) const {
    const Value *Obj = getUnderlyingObject(P);
    for (const Instruction &I : instructions(Caller))
      if (const auto *SI = dyn_cast<StoreInst>(&I))
        if (quantum(const_cast<Value *>(SI->getValueOperand())) &&
            getUnderlyingObject(SI->getPointerOperand()) == Obj)
          return true;
    return false;
  }

  // (c): does a `ret` of `F` return a register `F` itself rotates? The
  // backward tainted slice of a returned value reaches a `cq_theta` result of
  // `F`. A call result is crossed when the call is to a gate callee that itself
  // returns its own register (recursion guarded; a call-cycle member answers
  // no), and, in the `CrossCallResults` phase only, through any other direct
  // call's tainted operands (a register returned through a lifted classical
  // call, `return h(x)` after `cq_theta(&x, …)`; R11 r1 item 7). Before slot B
  // such a result's taint is the conservative lift-site prediction (see the
  // header), so it is not crossed there.
  bool returnsOwnRegister(const Function &F,
                          SmallPtrSetImpl<const Function *> &Visiting) const {
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
      if (!Seen.insert(V).second ||
          !taint.Tainted.count(const_cast<Value *>(V)))
        continue;
      if (const auto *CI = dyn_cast<CallInst>(V)) {
        if (taint.ThetaCalls.contains(const_cast<CallInst *>(CI)))
          return true;
        const Function *G = CI->getCalledFunction();
        if (G && !G->isDeclaration() && S.Gate.count(G) &&
            returnsOwnRegister(*G, Visiting))
          return true;
        if (CrossCallResults && G && !G->isDeclaration())
          for (const Value *A : CI->args())
            Work.push_back(A);
        continue;
      }
      if (const auto *I = dyn_cast<Instruction>(V))
        for (const Value *Op : I->operands())
          Work.push_back(Op);
    }
    return false;
  }

  bool shouldInline(CallInst &CI, const Function &Callee,
                    std::unique_ptr<PostDominatorTree> &PDT) const {
    bool HasPtrArg = false;
    for (const Use &U : CI.args()) {
      if (quantum(U.get()))
        return true;  // (a)
      if (U->getType()->isPointerTy()) {
        HasPtrArg = true;
        if (receivesQuantumStore(U.get(), *CI.getFunction()))
          return true;  // (b), caller half
      }
    }
    if (HasPtrArg && S.StoresTainted.count(&Callee))
      return true;  // (b), callee half
    SmallPtrSet<const Function *, 8> Visiting;
    if (returnsOwnRegister(Callee, Visiting) &&
        (!CI.use_empty() || !Callee.getReturnType()->isIntegerTy(32)))
      return true;  // (c)
    if (!PDT)
      PDT = std::make_unique<PostDominatorTree>(*CI.getFunction());
    return underQuantumControl(CI, *PDT);  // (d)
  }
};

// The callee of `CI` if it is a candidate at all: a direct, non-interposable,
// non-recursive gate subroutine other than the caller, not excluded by the
// inline history (a site produced by inlining this same callee).
Function *candidateCallee(CallInst &CI, const GateSets &S,
                          const GateInlineState &St) {
  Function *Callee = CI.getCalledFunction();
  if (!Callee || Callee->isDeclaration() || !S.Gate.count(Callee) ||
      S.Recursive.count(Callee) || Callee == CI.getFunction() ||
      Callee->isInterposable())
    return nullptr;
  auto It = St.History.find(&CI);
  if (It != St.History.end() && llvm::is_contained(It->second, Callee))
    return nullptr;
  return Callee;
}

// The `-O1` per-function simplification with clang's `-O1`
// PipelineTuningOptions (clang's CodeGenOptions: `UnrollLoops`, `VectorizeLoop`
// and `VectorizeSLP` default off below -O2, `LoopInterleaving` follows
// `UnrollLoops`), so `LoopFullUnrollPass` runs only when forced, as in clang.
// No TargetMachine (see the header).
void simplifyCallers(ArrayRef<Function *> Callers) {
  PipelineTuningOptions PTO;
  PTO.LoopUnrolling = false;
  PTO.LoopInterleaving = false;
  PTO.LoopVectorization = false;
  PTO.SLPVectorization = false;
  LoopAnalysisManager LAM;
  FunctionAnalysisManager FAM;
  CGSCCAnalysisManager CGAM;
  ModuleAnalysisManager MAM;
  PassBuilder PB(/*TM=*/nullptr, PTO);
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

constexpr unsigned kMaxRounds = 64;  // backstop: a site -O1 clones loses its history

}  // namespace

bool inlineGateSubroutines(Module &M, const TaintSet &taint,
                           GateInlineState &St, bool CrossCallResults) {
  if (++St.Rounds > kMaxRounds)
    return false;  // what is left keeps its loud owner.
  const GateSets S = collectGateSets(M, taint);
  if (S.Gate.empty())
    return false;
  const Asker Ask{S, taint, makeLaterTaintQuery(taint), CrossCallResults};

  // Decide every site on one consistent taint snapshot, then mutate.
  SmallVector<CallInst *, 8> Sites;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    std::unique_ptr<PostDominatorTree> PDT;
    for (Instruction &I : instructions(F))
      if (auto *CI = dyn_cast<CallInst>(&I))
        if (Function *Callee = candidateCallee(*CI, S, St))
          if (Ask.shouldInline(*CI, *Callee, PDT))
            Sites.push_back(CI);
  }
  if (Sites.empty())
    return false;

  SetVector<Function *> Callers;
  SmallPtrSet<Function *, 8> Inlined;
  for (CallInst *CI : Sites) {
    Function *Caller = CI->getFunction();
    Function *Callee = CI->getCalledFunction();
    // The site's history plus this callee, for every site the inline produces.
    SmallVector<Function *, 2> Hist;
    if (auto It = St.History.find(CI); It != St.History.end())
      Hist = It->second;
    Hist.push_back(Callee);
    InlineFunctionInfo IFI;
    if (!InlineFunction(*CI, IFI).isSuccess())
      continue;
    for (CallBase *New : IFI.InlinedCallSites)
      St.History[New] = Hist;
    Callers.insert(Caller);
    Inlined.insert(Callee);
  }
  if (Callers.empty())
    return false;
  simplifyCallers(Callers.getArrayRef());
  // Debug lever (env-gated; the CQ_RAILBANK_DBG precedent).
  if (::getenv("CQ_GATEINLINE_DBG"))
    for (Function *F : Callers)
      F->print(llvm::errs());

  // A gate subroutine with no use left would be lowered standalone with
  // classical parameters: erase it when nothing outside the module can call it
  // (local linkage, or a whole program: the module defines `main`).
  const Function *Main = M.getFunction("main");
  const bool WholeProgram = Main && !Main->isDeclaration();
  for (Function *F : Inlined)
    if ((F->hasLocalLinkage() || WholeProgram) && F->use_empty() && F != Main)
      F->eraseFromParent();
  return true;
}

bool declineMissedGateSubroutines(Module &M, const TaintSet &taint,
                                  const GateInlineState &St) {
  const GateSets S = collectGateSets(M, taint);
  if (S.Gate.empty())
    return false;
  const Asker Ask{S, taint, nullptr, /*CrossCallResults=*/true};
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    std::unique_ptr<PostDominatorTree> PDT;
    for (Instruction &I : instructions(F))
      if (auto *CI = dyn_cast<CallInst>(&I))
        if (Function *Callee = candidateCallee(*CI, S, St))
          if (Ask.shouldInline(*CI, *Callee, PDT)) {
            F.getContext().diagnose(DiagnosticInfoUnsupported(
                F,
                "cq specialization: gate subroutine call became quantum after "
                "call-site compilation",
                CI->getDebugLoc()));
            return true;
          }
  }
  return false;
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

bool isProgramEntryPoint(const Function &F) {
  return F.getName() == "main" && !F.isDeclaration() && !F.hasLocalLinkage();
}

bool isQuantumReturnExport(const Function &F) {
  const auto *RT = dyn_cast<IntegerType>(F.getReturnType());
  if (F.isDeclaration() || !RT || RT->getBitWidth() <= 32 ||
      isProgramEntryPoint(F))
    return false;
  return onlyUsedListUsers(F);
}

bool widenQuantumExportReturns(Module &M) {
  for (Function &F : M) {
    if (!isQuantumReturnExport(F))
      continue;
    SmallVector<ReturnInst *, 2> Handles;
    const ReturnInst *Other = nullptr;
    for (BasicBlock &BB : F)
      if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator())) {
        Value *RV = R->getReturnValue();
        if (RV && RV->getType() != F.getReturnType() &&
            RV->getType()->isIntegerTy(32))
          Handles.push_back(R);
        else
          Other = R;
      }
    if (Handles.empty())
      continue;  // nothing returned a register: a classical function.
    if (Other) {
      F.getContext().diagnose(DiagnosticInfoUnsupported(
          F, nonI32ReturnMessage(), Other->getDebugLoc()));
      return true;
    }
    for (ReturnInst *R : Handles) {
      IRBuilder<> B(R);
      R->setOperand(0, B.CreateZExt(R->getReturnValue(), F.getReturnType(),
                                    "cq.handle.ret"));
    }
  }
  return false;
}

}  // namespace cq
