// ByRefInline.cpp — inline the producer of a VISIBLE user by-ref out-param (bd
// g7ip). See ByRefInline.h for the contract and `bd memories
// g7ip-inline-producer-design` for the owner design decision (Architecture A).
//
// Runs right after the g387 by-ref fixpoint and before detectSpecializations; the
// caller re-`propagate`s after any change so the inlined producer's downstream is
// re-tainted through the normal mechanism (exactly like lowerByRefMath).

#include "ByRefInline.h"

#include "TaintPropagation.h"  // TaintSet

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Argument.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"

#include <vector>

using namespace llvm;

namespace cq {

namespace {

// A pure, side-effect-free, clonable VALUE op: arithmetic / bitwise / (non-
// pointer) cast / compare / select / fneg. NOT loads, calls, stores, gep, phi,
// alloca, atomics, or pointer/bit-reinterpret casts (the `store`/`memory
// access` / `pointer cast` shapes the specializer's scanBody also declines).
bool isPureValueOp(const Instruction *I) {
  if (const auto *C = dyn_cast<CastInst>(I)) {
    switch (C->getOpcode()) {
    case Instruction::Trunc:
    case Instruction::ZExt:
    case Instruction::SExt:
    case Instruction::FPToUI:
    case Instruction::FPToSI:
    case Instruction::UIToFP:
    case Instruction::SIToFP:
    case Instruction::FPTrunc:
    case Instruction::FPExt:
      return true;
    default:  // BitCast / IntToPtr / PtrToInt / AddrSpaceCast — reinterpret casts
      return false;
    }
  }
  return isa<BinaryOperator>(I) || isa<CmpInst>(I) || isa<SelectInst>(I) ||
         isa<UnaryOperator>(I);
}

// The proven producer: the value stored through the out-param, and the out-param
// index in the callee signature.
struct BodyProof {
  Value *V = nullptr;
  unsigned OutIdx = 0;
};

// Prove `Callee` is a by-ref producer we can inline (TOTAL effect proof — drop
// NOTHING): local-linkage definition; `void` return; a SINGLE basic block ending
// in `ret void`; EXACTLY ONE pointer parameter (the out-param); EXACTLY ONE
// StoreInst, a simple whole-cell write DIRECTLY through that pointer param; the
// out-param's ONLY use is that store; and every OTHER instruction is a pure value
// op (or a lifetime/dbg intrinsic) — so the callee's SOLE observable effect is
// storing the pure value `V` through `out`. On success fills `Out` and returns
// true; any off-pattern shape returns false (skip → existing loud decline).
bool proveInlinableBody(Function *Callee, BodyProof &Out) {
  if (Callee->isDeclaration() || !Callee->hasLocalLinkage() || Callee->isVarArg())
    return false;
  if (!Callee->getReturnType()->isVoidTy())
    return false;
  if (Callee->size() != 1)  // single basic block only (v1)
    return false;

  // Exactly one pointer parameter (the out-param).
  int OutIdx = -1;
  for (unsigned i = 0; i < Callee->arg_size(); ++i) {
    if (Callee->getArg(i)->getType()->isPointerTy()) {
      if (OutIdx >= 0)
        return false;  // >1 pointer param — off-pattern
      OutIdx = static_cast<int>(i);
    }
  }
  if (OutIdx < 0)
    return false;  // no pointer param — not a by-ref producer (leave to specializer)
  Argument *OutParam = Callee->getArg(static_cast<unsigned>(OutIdx));

  BasicBlock &BB = Callee->getEntryBlock();
  auto *Ret = dyn_cast<ReturnInst>(BB.getTerminator());
  if (!Ret || Ret->getReturnValue())  // must be `ret void`
    return false;

  StoreInst *TheStore = nullptr;
  for (Instruction &I : BB) {
    if (&I == Ret)
      continue;
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      if (TheStore)
        return false;  // >1 store — off-pattern
      if (!SI->isSimple() || SI->getPointerOperand() != OutParam)
        return false;  // volatile/atomic, or not a DIRECT whole-cell write to out
      TheStore = SI;
      continue;
    }
    if (auto *II = dyn_cast<IntrinsicInst>(&I)) {
      Intrinsic::ID Id = II->getIntrinsicID();
      if (Id == Intrinsic::lifetime_start || Id == Intrinsic::lifetime_end ||
          Id == Intrinsic::dbg_value || Id == Intrinsic::dbg_declare ||
          Id == Intrinsic::dbg_label)
        continue;
      return false;  // any other intrinsic may carry an effect — decline
    }
    if (isa<CallInst>(&I))
      return false;  // any (non-intrinsic) call — decline (v1; curated-call body deferred)
    if (I.mayReadFromMemory() || I.mayHaveSideEffects())
      return false;  // loads / atomics / anything observable
    if (!isPureValueOp(&I))
      return false;  // gep / phi / alloca / extractvalue / … — unproven shape
  }
  if (!TheStore)
    return false;

  // The out-param's ONLY use in the body is the store (no load-from-out, no gep,
  // no escape into another call/arg) — so inlining the store value is the WHOLE
  // effect of `out`.
  for (User *U : OutParam->users())
    if (U != TheStore)
      return false;

  Out.V = TheStore->getValueOperand();
  Out.OutIdx = static_cast<unsigned>(OutIdx);
  return true;
}

// Mirror of ByRefMath.cpp's file-local guard: an instruction runs "under quantum
// control" iff a tainted br/switch dominates it.
bool underTaintedControl(const Instruction *I, const TaintSet &taint,
                         DominatorTree &DT) {
  DomTreeNode *Node = DT.getNode(const_cast<BasicBlock *>(I->getParent()));
  if (!Node)
    return true;  // unreachable / no node — decline conservatively.
  for (DomTreeNode *N = Node->getIDom(); N; N = N->getIDom()) {
    const Instruction *T = N->getBlock()->getTerminator();
    if (const auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() &&
          taint.Tainted.count(const_cast<Value *>(BI->getCondition())))
        return true;
    } else if (const auto *SI = dyn_cast<SwitchInst>(T)) {
      if (taint.Tainted.count(const_cast<Value *>(SI->getCondition())))
        return true;
    }
  }
  return false;
}

// Prove the caller-side out-cell (the actual pointer arg) is a direct scalar
// alloca whose ONLY users are this call (once, not aliased into another arg),
// read-back loads (each dominated by the call, of the cell type), dead pre-call
// whole-cell stores, and lifetime/dbg intrinsics; the call is not under tainted
// control and not in a loop; no load is in a loop. This is the g387 `analyzeCell`
// discipline (miss-safety is STRUCTURAL: an unaccounted read stays classical =
// silent miscompile). On accept fills the out-vectors and returns empty; on
// reject returns a (non-empty) reason so the caller SKIPS (falls through to the
// existing loud declines — no diagnostic here).
StringRef proveCallerCell(CallInst *CI, unsigned OutIdx, Type *CellTy,
                          const TaintSet &taint, DominatorTree &DT, LoopInfo &LI,
                          AllocaInst *&CellOut,
                          SmallVectorImpl<LoadInst *> &Loads,
                          SmallVectorImpl<StoreInst *> &DeadStores,
                          SmallVectorImpl<Instruction *> &Lifetimes) {
  Value *PtrArg = CI->getArgOperand(OutIdx);
  auto *Cell = dyn_cast<AllocaInst>(PtrArg);
  if (!Cell || Cell != PtrArg->stripPointerCasts())
    return "out-param not a direct scalar alloca";
  if (!Cell->isStaticAlloca() || Cell->isArrayAllocation())
    return "out-param cell not a static single-element alloca";
  if (Cell->getAllocatedType() != CellTy)
    return "out-param cell type mismatch";

  unsigned ByRefUses = 0;
  for (User *U : Cell->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI)
      return "out-param cell has a non-instruction user";
    if (UI == CI) {
      unsigned Occ = 0;
      for (const Use &Op : CI->args())
        if (Op.get() == Cell)
          ++Occ;
      if (Occ != 1)
        return "out-param cell aliased into another argument";
      ++ByRefUses;
      continue;
    }
    if (auto *LD = dyn_cast<LoadInst>(UI)) {
      if (!LD->isSimple() || LD->getType() != CellTy)
        return "out-param cell load is not a simple scalar read";
      if (!DT.dominates(CI, LD))
        return "out-param cell load not dominated by the call";
      Loads.push_back(LD);
      continue;
    }
    if (auto *ST = dyn_cast<StoreInst>(UI)) {
      // A dead pre-call whole-cell write the call overwrites (clang's `int e=0;`);
      // a POST-call store could be read by a later load, so require it to DOMINATE
      // the call (else decline — a later load would read a non-producer value).
      if (!ST->isSimple() || ST->getPointerOperand() != Cell ||
          ST->getValueOperand()->getType() != CellTy)
        return "out-param cell store is not a simple whole-cell write";
      if (!DT.dominates(ST, CI))
        return "out-param cell written after the by-ref call";
      DeadStores.push_back(ST);
      continue;
    }
    if (auto *II = dyn_cast<IntrinsicInst>(UI)) {
      Intrinsic::ID Id = II->getIntrinsicID();
      if (Id == Intrinsic::lifetime_start || Id == Intrinsic::lifetime_end ||
          Id == Intrinsic::dbg_value || Id == Intrinsic::dbg_declare) {
        Lifetimes.push_back(II);
        continue;
      }
    }
    return "out-param cell escapes to an unsupported use";
  }
  if (ByRefUses != 1)
    return "out-param cell not written by exactly one by-ref call";

  if (underTaintedControl(CI, taint, DT))
    return "under quantum control";
  if (LI.getLoopFor(CI->getParent()))
    return "by-ref call in a loop";
  for (LoadInst *LD : Loads)
    if (LI.getLoopFor(LD->getParent()))
      return "out-param cell load in a loop";

  CellOut = Cell;
  return StringRef();  // accept
}

// Clone the pure operand cone of `V` (defined in the callee) into the caller,
// inserting each clone immediately before `InsertPt`, remapping callee params to
// the call's actual args via `VMap` (seeded param→actual by the caller). Post-
// order (operands first) so dominance holds; memoized so shared subexpressions
// clone once. `V`'s cone is proven pure (no loads/calls/phi/cycles), so this
// terminates and reproduces the callee's computation exactly (flags preserved by
// `clone()`).
Value *cloneExpr(Value *V, DenseMap<Value *, Value *> &VMap,
                 Instruction *InsertPt) {
  auto It = VMap.find(V);
  if (It != VMap.end())
    return It->second;
  if (isa<Constant>(V))
    return V;  // constants / globals are module-level — identical in the caller
  auto *I = cast<Instruction>(V);
  Instruction *Clone = I->clone();
  for (unsigned k = 0; k < Clone->getNumOperands(); ++k)
    Clone->setOperand(k, cloneExpr(I->getOperand(k), VMap, InsertPt));
  Clone->insertBefore(InsertPt);
  Clone->setName(I->getName());
  // The callee's !dbg points at the callee's DISubprogram; re-anchor to the call
  // site's scope so the verifier stays happy (drops it if the call has no !dbg).
  Clone->setDebugLoc(InsertPt->getDebugLoc());
  VMap[V] = Clone;
  return Clone;
}

}  // namespace

bool lowerByRefInline(Module &M, TaintSet &taint) {
  bool Changed = false;
  SmallPtrSet<Function *, 8> MaybeDead;

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;

    // Collect candidate call sites first (rewriting erases them). A candidate is
    // a direct call to a local-linkage DEFINED callee (not F itself).
    std::vector<CallInst *> Sites;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (Function *Callee = CI->getCalledFunction())
            if (!Callee->isDeclaration() && Callee->hasLocalLinkage() &&
                Callee != &F)
              Sites.push_back(CI);
    if (Sites.empty())
      continue;

    // DT/LI built once. This stage makes NO CFG edits (only intra-block
    // instruction add/erase), so block-level dominance/loop membership is stable
    // across sites; DT's per-block instruction-order cache self-heals on query
    // (the g387 lowerByRefMath invariant).
    DominatorTree DT(F);
    LoopInfo LI(DT);

    for (CallInst *CI : Sites) {
      Function *Callee = CI->getCalledFunction();

      BodyProof BP;
      if (!proveInlinableBody(Callee, BP))
        continue;
      if (CI->arg_size() != Callee->arg_size())
        continue;  // signature/arity mismatch — leave it

      // Taint gate: the out-POINTER must be CLASSICAL (a tainted out-pointer is a
      // quantum address — leave it to decline), and V must USE ≥1 tainted value
      // arg (else the result is classical / the tainted arg would be orphaned).
      if (taint.Tainted.count(CI->getArgOperand(BP.OutIdx)))
        continue;
      SmallPtrSet<const Argument *, 4> UsedParams;
      {
        SmallVector<Value *, 8> WL{BP.V};
        SmallPtrSet<Value *, 16> Seen;
        while (!WL.empty()) {
          Value *V = WL.pop_back_val();
          if (!Seen.insert(V).second)
            continue;
          if (auto *A = dyn_cast<Argument>(V))
            UsedParams.insert(A);
          else if (auto *I = dyn_cast<Instruction>(V))
            for (Value *Op : I->operands())
              WL.push_back(Op);
        }
      }
      bool AnyTaintedUsed = false;
      for (const Argument *A : UsedParams)
        if (A->getArgNo() != BP.OutIdx &&
            taint.Tainted.count(CI->getArgOperand(A->getArgNo()))) {
          AnyTaintedUsed = true;
          break;
        }
      if (!AnyTaintedUsed)
        continue;

      // Caller-side out-cell proof (g387 discipline).
      Type *CellTy = BP.V->getType();
      AllocaInst *Cell = nullptr;
      SmallVector<LoadInst *, 4> Loads;
      SmallVector<StoreInst *, 4> DeadStores;
      SmallVector<Instruction *, 4> Lifetimes;
      StringRef Reason = proveCallerCell(CI, BP.OutIdx, CellTy, taint, DT, LI,
                                         Cell, Loads, DeadStores, Lifetimes);
      if (!Reason.empty())
        continue;  // ADDITIVE: skip → falls through to the existing loud decline.

      // ---- Accept: materialize V into the caller, RAUW the read-back loads. ----
      DenseMap<Value *, Value *> VMap;
      for (unsigned i = 0; i < Callee->arg_size(); ++i)
        VMap[Callee->getArg(i)] = CI->getArgOperand(i);
      Value *NewV = cloneExpr(BP.V, VMap, CI);

      for (LoadInst *LD : Loads)
        LD->replaceAllUsesWith(NewV);
      for (LoadInst *LD : Loads)
        LD->eraseFromParent();
      for (StoreInst *ST : DeadStores)
        ST->eraseFromParent();
      CI->eraseFromParent();
      for (Instruction *LT : Lifetimes)
        LT->eraseFromParent();
      if (Cell->use_empty())
        Cell->eraseFromParent();

      MaybeDead.insert(Callee);
      Changed = true;
    }
  }

  // Erase now-dead inlined callees (internal, no remaining uses) — keeps the
  // output tidy, mirroring the g387 dead-marker cleanup.
  for (Function *Callee : MaybeDead)
    if (Callee->hasLocalLinkage() && Callee->use_empty())
      Callee->eraseFromParent();

  return Changed;
}

}  // namespace cq
