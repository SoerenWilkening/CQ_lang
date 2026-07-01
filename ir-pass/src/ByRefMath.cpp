// ByRefMath.cpp — canonicalize tainted by-ref libm math calls (bd g387).
// See ByRefMath.h for the contract and PRD for the design. Runs right after the
// first `propagate` (before `detectSpecializations`); the caller re-propagates
// after any change so the markers' downstream is re-tainted.

#include "ByRefMath.h"

#include "OpcodeSupport.h"     // abiWidthFromType
#include "TaintPropagation.h"  // TaintSet
#include "WidthDispatch.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/DiagnosticInfo.h"

#include <string>
#include <vector>

using namespace llvm;

namespace cq {

namespace {

// Loud, source-located decline. `Reason` names the off-pattern cause; a fixture
// mirrors `kMsgByRefMath (Reason)` character-for-character (Rule 12).
constexpr char kMsgByRefMath[] = "cq by-ref math out-param under quantum lift";

void diagnoseByRef(Instruction *I, StringRef Reason) {
  std::string Msg = (Twine(kMsgByRefMath) + " (" + Reason + ")").str();
  I->getFunction()->getContext().diagnose(
      DiagnosticInfoUnsupported(*I->getFunction(), Msg, I->getDebugLoc()));
}

// One by-ref math family. `numFp` leading fp value args, then ONE ptr out-param.
// `prim`/`sec` are the synthetic marker name bases (a `_<W>` width suffix is
// appended). `secIsInt` ⇒ the out-cell is `i32` (frexp exponent, remquo
// quotient); else the out-cell is the SAME fp width as the input (modf int part).
struct ByRefDesc {
  StringRef name;    // double spelling
  StringRef nameF;   // float spelling
  StringRef nameLd;  // long double spelling
  unsigned numFp;    // # leading fp value args (frexp/modf 1, remquo 2)
  StringRef prim;    // primary marker base
  StringRef sec;     // secondary marker base
  bool secIsInt;     // out-cell is i32 vs same-fp
};

const ByRefDesc kByRef[] = {
    {"frexp", "frexpf", "frexpl", 1, "cq_byref_frexp", "cq_byref_frexpexp", true},
    {"modf", "modff", "modfl", 1, "cq_byref_modf", "cq_byref_modfint", false},
    {"remquo", "remquof", "remquol", 2, "cq_byref_remquo", "cq_byref_remquoquo",
     true},
};

const ByRefDesc *lookupByRef(const CallInst *CI) {
  if (CI->hasOperandBundles())
    return nullptr;
  const Function *Callee = CI->getCalledFunction();
  if (!Callee || !Callee->isDeclaration() || Callee->isIntrinsic())
    return nullptr;
  const StringRef N = Callee->getName();
  for (const ByRefDesc &D : kByRef)
    if (N == D.name || N == D.nameF || N == D.nameLd)
      return &D;
  return nullptr;
}

// The by-ref call's SIGNATURE must be exactly (fp × numFp, ptr) → fp, all fp
// the SAME width ∈ {f32,f64,f80}. Returns the fp type on success, else nullptr.
Type *validSignature(const CallInst *CI, const ByRefDesc &D) {
  const FunctionType *FT = CI->getFunctionType();
  if (FT->isVarArg() || FT->getNumParams() != D.numFp + 1)
    return nullptr;
  Type *FpTy = FT->getReturnType();
  if (abiWidthFromType(FpTy).empty() || !FpTy->isFloatingPointTy())
    return nullptr;
  for (unsigned i = 0; i < D.numFp; ++i)
    if (FT->getParamType(i) != FpTy)
      return nullptr;
  if (!FT->getParamType(D.numFp)->isPointerTy())
    return nullptr;
  return FpTy;
}

// Mirror of QramLowering::instUnderTaintedControl (file-local there): a tainted
// br/switch on any dominator ⇒ the instruction runs under quantum control.
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

// Analyze the out-param cell. On accept, fills `Loads` + `Lifetimes` (to erase)
// and returns nullptr; on reject, diagnoses loudly and returns a non-empty
// reason (so the caller stops). `CellTy` is the required scalar cell type.
StringRef analyzeCell(CallInst *CI, const ByRefDesc &D, Type *FpTy,
                      const TaintSet &taint, DominatorTree &DT, LoopInfo &LI,
                      AllocaInst *&CellOut,
                      SmallVectorImpl<LoadInst *> &Loads,
                      SmallVectorImpl<StoreInst *> &Stores,
                      SmallVectorImpl<Instruction *> &Lifetimes) {
  Value *PtrArg = CI->getArgOperand(D.numFp);
  auto *Cell = dyn_cast<AllocaInst>(PtrArg->stripPointerCasts());
  if (!Cell || Cell != PtrArg)  // must be a DIRECT alloca (no bitcast/gep)
    return "out-param not a direct scalar alloca";
  if (!Cell->isStaticAlloca() || Cell->isArrayAllocation())
    return "out-param cell not a static single-element alloca";
  Type *CellTy = Cell->getAllocatedType();
  Type *WantTy = D.secIsInt ? Type::getInt32Ty(CI->getContext()) : FpTy;
  if (CellTy != WantTy)
    return "out-param cell type mismatch";

  // The cell address must escape NOWHERE except this one by-ref call (the ptr
  // out-param), loads, and lifetime markers. Miss-safety is STRUCTURAL: an
  // unaccounted read stays classical → silent miscompile (Prime Directive).
  unsigned ByRefUses = 0;
  for (User *U : Cell->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI)
      return "out-param cell has a non-instruction user";
    if (UI == CI) {
      // The call must take the cell only ONCE (as the out-param slot, which
      // PtrArg == arg numFp already fixes) — never aliased into another arg.
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
      // A store to the cell is allowed ONLY as a DEAD pre-call whole-cell write
      // the by-ref call overwrites (e.g. clang's `int e = 0;` zero-init before
      // frexp). It must dominate the call — a store the call does NOT dominate
      // (a POST-call write) could be observed by a later load, which would then
      // read a value OTHER than the by-ref result: RAUW-ing that load to the
      // secondary producer would be a silent miscompile. Decline that.
      if (!ST->isSimple() || ST->getPointerOperand() != Cell ||
          ST->getValueOperand()->getType() != CellTy)
        return "out-param cell store is not a simple whole-cell write";
      if (!DT.dominates(ST, CI))
        return "out-param cell written after the by-ref call";
      Stores.push_back(ST);
      continue;
    }
    if (auto *II = dyn_cast<IntrinsicInst>(UI)) {
      Intrinsic::ID id = II->getIntrinsicID();
      if (id == Intrinsic::lifetime_start || id == Intrinsic::lifetime_end) {
        Lifetimes.push_back(II);
        continue;
      }
    }
    return "out-param cell escapes to an unsupported use";
  }
  if (ByRefUses != 1)
    return "out-param cell not written by exactly one by-ref call";

  // Straight-line only: not under tainted control, and neither the call nor any
  // load in a loop (out of Phase-7.5 scope — decline, do not miscompile).
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

}  // namespace

bool isByRefMathCall(const CallInst *CI) { return lookupByRef(CI) != nullptr; }

bool lowerByRefMath(Module &M, WidthDispatch &wd, TaintSet &taint,
                    SmallPtrSetImpl<const CallInst *> &Declined) {
  (void)wd;
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;

    // Collect candidate by-ref calls first (canonicalization erases them).
    std::vector<CallInst *> Sites;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (lookupByRef(CI))
            Sites.push_back(CI);
    if (Sites.empty())
      continue;

    DominatorTree DT(F);
    LoopInfo LI(DT);

    for (CallInst *CI : Sites) {
      if (Declined.count(CI))
        continue;  // already loud-declined in a prior fixpoint pass.
      const ByRefDesc *D = lookupByRef(CI);

      // Does this by-ref-NAMED call consume ANY tainted value in the CURRENT
      // (re-derived) taint set? A fully-classical by-ref call is an ordinary
      // libc call — leave it untouched (passthrough; declineTaintEscapes won't
      // flag it either). Iterate ALL operands: a chained call becomes tainted
      // across fixpoint passes once the inner producer's downstream is
      // re-propagated (DEFECT C — handled by the fixpoint, not by seeding).
      bool ReadsTainted = false;
      for (Use &Op : CI->args())
        if (taint.Tainted.count(Op.get())) {
          ReadsTainted = true;
          break;
        }
      if (!ReadsTainted)
        continue;

      // From here the call is QUANTUM. The `isByRefMathCall` escape carve
      // (name-only) suppresses the generic kMsgUnknownCallee, so lowerByRefMath
      // MUST now either lower it or LOUD-DECLINE it (recording it in `Declined`)
      // — a silent skip would strand the call (verify-clean SILENT MISCOMPILE on
      // an i32 operand, or a broken module on an fp operand — g387 Rule-13
      // DEFECT A/B/C). Rule 1 / Prime Directive: off-pattern declines loudly,
      // never crashes the backend.
      Type *FpTy = validSignature(CI, *D);
      if (!FpTy) {
        diagnoseByRef(CI, "unsupported by-ref math signature");
        Declined.insert(CI);
        continue;
      }
      bool AnyFpTainted = false;
      for (unsigned i = 0; i < D->numFp; ++i)
        if (taint.Tainted.count(CI->getArgOperand(i)))
          AnyFpTainted = true;
      if (!AnyFpTainted) {
        // Reads a tainted value but no fp value arg is tainted → the tainted
        // operand is the out-POINTER (a quantum address/index), off the
        // straight-line scalar-cell model. Decline (never route a quantum
        // pointer through the scalar-promotion path).
        diagnoseByRef(CI, "tainted by-ref out-pointer");
        Declined.insert(CI);
        continue;
      }

      AllocaInst *Cell = nullptr;
      SmallVector<LoadInst *, 4> Loads;
      SmallVector<StoreInst *, 4> Stores;
      SmallVector<Instruction *, 4> Lifetimes;
      StringRef Reason = analyzeCell(CI, *D, FpTy, taint, DT, LI, Cell, Loads,
                                     Stores, Lifetimes);
      if (!Reason.empty()) {  // off-pattern — loud decline, lower nothing.
        diagnoseByRef(CI, Reason);
        Declined.insert(CI);
        continue;
      }

      // ---- Accept: emit the two producer markers over the live fp source(s). --
      const StringRef W = abiWidthFromType(FpTy);
      IRBuilder<> B(CI);
      SmallVector<Value *, 2> FpArgs;
      SmallVector<Type *, 2> FpParamTys;
      for (unsigned i = 0; i < D->numFp; ++i) {
        FpArgs.push_back(CI->getArgOperand(i));
        FpParamTys.push_back(FpTy);
      }

      // Primary marker: (fp…) -> fp. Replaces the by-ref call's return value.
      std::string PrimName = (D->prim + "_" + W).str();
      FunctionCallee Prim = M.getOrInsertFunction(
          PrimName, FunctionType::get(FpTy, FpParamTys, /*isVarArg=*/false));
      CallInst *PrimCall = B.CreateCall(Prim, FpArgs, "h_byref");
      if (DebugLoc DL = CI->getDebugLoc())
        PrimCall->setDebugLoc(DL);
      CI->replaceAllUsesWith(PrimCall);

      // Secondary marker: (fp…) -> cell type. Replaces every out-cell load.
      // (No taint seeding here — the caller's fixpoint re-`propagate` re-derives
      // taint over the markers and their whole downstream, which is what lowers
      // CHAINED by-ref math regardless of how the linkage is expressed.)
      if (!Loads.empty()) {
        Type *CellTy = Cell->getAllocatedType();
        std::string SecName = (D->sec + "_" + W).str();
        FunctionCallee Sec = M.getOrInsertFunction(
            SecName, FunctionType::get(CellTy, FpParamTys, /*isVarArg=*/false));
        CallInst *SecCall = B.CreateCall(Sec, FpArgs, "h_byref_out");
        if (DebugLoc DL = CI->getDebugLoc())
          SecCall->setDebugLoc(DL);
        for (LoadInst *LD : Loads)
          LD->replaceAllUsesWith(SecCall);
      }

      // ---- Tear down the memory cell (loads, dead pre-call stores, call,
      //      lifetimes, alloca). -------------------------------------------
      for (LoadInst *LD : Loads)
        LD->eraseFromParent();
      for (StoreInst *ST : Stores)
        ST->eraseFromParent();
      CI->eraseFromParent();
      for (Instruction *LT : Lifetimes)
        LT->eraseFromParent();
      if (Cell->use_empty())
        Cell->eraseFromParent();
      Changed = true;
    }
  }

  return Changed;
}

}  // namespace cq
