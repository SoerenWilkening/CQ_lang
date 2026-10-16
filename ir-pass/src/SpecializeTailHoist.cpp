// SpecializeTailHoist.cpp — see the header (bd test_C_libtooling-r2j3.37).

#include "SpecializeTailHoist.h"

#include "ArmAnalysis.h"        // isFrontEndThetaCall
#include "CalleeBody.h"         // calleeBodyTrusted
#include "InPlaceQQ.h"          // isQQStemOpcode / qqDeadRecordBits
#include "SpecializeDetect.h"   // isProvenSpecSite
#include "TaintPropagation.h"   // TaintSet

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/AttributeMask.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Metadata.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/Local.h"

#include <map>
#include <memory>
#include <optional>
#include <vector>

using namespace llvm;

namespace cq {

const char kMsgLiftTailUnhoisted[] =
    "cq specialization: a lifted call overwrites a dead quantum argument the "
    "return-chain hoist did not see";

namespace {

struct Plan;

// One node of a return chain. `Leaf` is a value the chain READS but does not
// pass through: `V` of the planned function's own body, or (`HP`,`HIdx`) a leaf
// of a nested callee's plan, evaluated at `InnerCall`.
struct Node {
  enum Kind { Arg, Const, Leaf, Op } K = Leaf;
  unsigned ArgNo = 0;
  Constant *C = nullptr;
  Value *V = nullptr;
  Plan *HP = nullptr;
  int HIdx = -1;
  CallInst *InnerCall = nullptr;
  Function *Src = nullptr;  // built lazily: the leaf's source function.
  Instruction::BinaryOps Opc = Instruction::Xor;
  int L = -1, R = -1;
  bool HasArg = false;
};

struct Plan {
  Function *F = nullptr;
  std::vector<Node> N;
  int Root = -1;
  bool hoistable() const { return Root >= 0 && N[Root].HasArg; }
};

class Planner {
public:
  Plan *planFor(Function *F) {
    auto It = Plans.find(F);
    if (It != Plans.end())
      return It->second.get();
    if (!OnStack.insert(F).second)
      return nullptr;  // recursion: no chain through it.
    std::unique_ptr<Plan> P = build(F);
    OnStack.erase(F);
    Plan *Raw = P.get();
    Plans[F] = std::move(P);
    return Raw;
  }

  // The leaf's source: a copy of `P.F` returning the leaf's value.
  Function *srcFor(Plan &P, int I) {
    Node &Nd = P.N[I];
    if (Nd.Src)
      return Nd.Src;
    Value *X = nullptr;
    Nd.Src = cloneReturning(*P.F, [&](ValueToValueMapTy &VMap, ReturnInst *Ret) {
      if (Nd.V)
        return X = VMap[Nd.V];
      Function *Inner = srcFor(*Nd.HP, Nd.HIdx);
      auto *IC = cast<CallInst>(VMap[Nd.InnerCall]);
      IRBuilder<> B(Ret);
      CallInst *NC = B.CreateCall(Inner, SmallVector<Value *, 8>(IC->args()));
      NC->setCallingConv(Inner->getCallingConv());
      NC->setDebugLoc(IC->getDebugLoc());
      return X = NC;
    });
    return Nd.Src;
  }

  // A copy of `F` returning zero: keeps a non-trivially-dead call's effects.
  Function *zeroSrc(Function &F) {
    return cloneReturning(F, [&](ValueToValueMapTy &, ReturnInst *) -> Value * {
      return Constant::getNullValue(F.getReturnType());
    });
  }

private:
  std::map<Function *, std::unique_ptr<Plan>> Plans;
  SmallPtrSet<Function *, 8> OnStack;
  unsigned Counter = 0;

  static ReturnInst *singleRet(Function &F) {
    ReturnInst *R = nullptr;
    for (BasicBlock &BB : F)
      if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator())) {
        if (R)
          return nullptr;
        R = RI;
      }
    return R && R->getReturnValue() ? R : nullptr;
  }

  template <typename Fn> Function *cloneReturning(Function &F, Fn &&MakeRet) {
    ValueToValueMapTy VMap;
    Function *G = CloneFunction(&F, VMap);
    G->setName(F.getName() + "__cqsrc" + Twine(Counter++));
    G->setLinkage(GlobalValue::InternalLinkage);
    ReturnInst *Ret = singleRet(*G);
    Value *Old = Ret->getReturnValue();
    Ret->setOperand(0, MakeRet(VMap, Ret));
    RecursivelyDeleteTriviallyDeadInstructions(Old);
    // The source returns a different value: no return-value constraint and no
    // `returned` parameter of `F` holds of it.
    LLVMContext &Ctx = G->getContext();
    G->setAttributes(G->getAttributes().removeRetAttributes(
        Ctx, AttributeMask(G->getAttributes().getRetAttrs())));
    for (Argument &A : G->args())
      G->removeParamAttr(A.getArgNo(), Attribute::Returned);
    return G;
  }

  std::unique_ptr<Plan> build(Function *F) {
    auto P = std::make_unique<Plan>();
    P->F = F;
    ReturnInst *Ret = singleRet(*F);
    if (!Ret || F->isVarArg() || !calleeBodyTrusted(F, CalleeBodyUse::Execute))
      return P;
    P->Root = expr(*P, Ret->getReturnValue());
    return P;
  }

  int add(Plan &P, Node Nd) {
    P.N.push_back(Nd);
    return static_cast<int>(P.N.size()) - 1;
  }

  int leaf(Plan &P, Value *V) {
    Node Nd;
    Nd.K = Node::Leaf;
    Nd.V = V;
    return add(P, Nd);
  }

  static bool chainType(const Type *Ty) {
    return Ty->isIntegerTy() && Ty->getIntegerBitWidth() <= 64;
  }

  int expr(Plan &P, Value *V) {
    if (auto *A = dyn_cast<Argument>(V)) {
      Node Nd;
      Nd.K = Node::Arg;
      Nd.ArgNo = A->getArgNo();
      Nd.HasArg = true;
      return add(P, Nd);
    }
    if (auto *K = dyn_cast<Constant>(V)) {
      Node Nd;
      Nd.K = Node::Const;
      Nd.C = K;
      return add(P, Nd);
    }
    if (auto *BO = dyn_cast<BinaryOperator>(V);
        BO && isQQStemOpcode(BO->getOpcode()) && chainType(BO->getType())) {
      const int L = expr(P, BO->getOperand(0));
      const int R = expr(P, BO->getOperand(1));
      if (!P.N[L].HasArg && !P.N[R].HasArg)
        return leaf(P, V);  // a value the chain reads, not passes through.
      Node Nd;
      Nd.K = Node::Op;
      Nd.Opc = BO->getOpcode();
      Nd.L = L;
      Nd.R = R;
      Nd.HasArg = true;
      return add(P, Nd);
    }
    if (auto *CI = dyn_cast<CallInst>(V)) {
      Function *H = CI->getCalledFunction();
      if (H && !H->isIntrinsic() && !H->isDeclaration() && !CI->isMustTailCall() &&
          CI->getFunctionType() == H->getFunctionType())
        if (Plan *HP = planFor(H); HP && HP->hoistable())
          return substitute(P, *HP, HP->Root, CI);
    }
    return leaf(P, V);
  }

  // `HP`'s node `I`, read at the call `CI` in `P.F`.
  int substitute(Plan &P, Plan &HP, int I, CallInst *CI) {
    const Node HN = HP.N[I];  // copy: `P` may be `HP` only under recursion,
                              // which `planFor` refuses.
    switch (HN.K) {
    case Node::Arg:
      return expr(P, CI->getArgOperand(HN.ArgNo));
    case Node::Const:
      return add(P, HN);
    case Node::Leaf: {
      Node Nd;
      Nd.K = Node::Leaf;
      Nd.HP = &HP;
      Nd.HIdx = I;
      Nd.InnerCall = CI;
      return add(P, Nd);
    }
    case Node::Op: {
      const int L = substitute(P, HP, HN.L, CI);
      const int R = substitute(P, HP, HN.R, CI);
      Node Nd;
      Nd.K = Node::Op;
      Nd.Opc = HN.Opc;
      Nd.L = L;
      Nd.R = R;
      Nd.HasArg = P.N[L].HasArg || P.N[R].HasArg;
      return add(P, Nd);
    }
    }
    return -1;
  }
};

void argNos(const Plan &P, int I, SmallVectorImpl<unsigned> &Out) {
  const Node &Nd = P.N[I];
  if (Nd.K == Node::Arg)
    Out.push_back(Nd.ArgNo);
  else if (Nd.K == Node::Op) {
    argNos(P, Nd.L, Out);
    argNos(P, Nd.R, Out);
  }
}

// THE GATE (header): the chain parameters receiving a tainted operand the
// in-place record would call dead at the call (bit i = argument i; 0 = none).
// `Hoist`: the pre-lowering slot also asks E2 the only way stock IR can answer
// it — a USER register is a front-end `cq_theta` result, or a φ the record
// proved one wire of such a chain (bit 1 on a φ: `singleWirePhiDeadAfter`). A
// derived operand stays a lifted read: hoisting it would trade the clone
// consumer the spine plans around (M-B) for a template reader with no in-place
// gain (measured: spec_accept_clone_two_components_both_discharged.ll leaked).
// Anything else the late tag adjudicates with the exact E2.
uint64_t owes(CallInst &CI, const Plan &P, const TaintSet &taint,
              const DominatorTree &DT, const LoopInfo &LI, bool Hoist) {
  if (!P.hoistable() || CI.isMustTailCall())
    return 0;
  SmallVector<unsigned, 4> Args;
  argNos(P, P.Root, Args);
  uint64_t Mask = 0;
  for (unsigned A : Args) {
    Value *V = CI.getArgOperand(A);
    if (A >= 64 || !taint.Tainted.count(V))
      continue;
    const unsigned Bits = qqDeadRecordBits(V, &CI, DT, LI);
    if (Hoist ? (Bits & 1u) && (isFrontEndThetaCall(V) || isa<PHINode>(V))
              : Bits != 0)
      Mask |= uint64_t(1) << A;
  }
  return Mask;
}

Value *emit(Planner &PL, Plan &P, int I, CallInst &Site, IRBuilder<> &B,
            unsigned &Leaves) {
  Node &Nd = P.N[I];
  switch (Nd.K) {
  case Node::Arg:
    return Site.getArgOperand(Nd.ArgNo);
  case Node::Const:
    return Nd.C;
  case Node::Leaf: {
    ++Leaves;
    Function *S = PL.srcFor(P, I);
    CallInst *NC = B.CreateCall(S, SmallVector<Value *, 8>(Site.args()));
    NC->setCallingConv(S->getCallingConv());
    return NC;
  }
  case Node::Op: {
    Value *L = emit(PL, P, Nd.L, Site, B, Leaves);
    Value *R = emit(PL, P, Nd.R, Site, B, Leaves);
    return B.CreateBinOp(Nd.Opc, L, R);
  }
  }
  return nullptr;
}

// A body with no side-effecting instruction and no cycle has no effect but its
// return (the attributes `-O1` would infer, asked of hand IR that lacks them).
bool effectFree(Function &F) {
  SmallVector<std::pair<const BasicBlock *, const BasicBlock *>, 2> Back;
  FindFunctionBackedges(F, Back);
  if (!Back.empty())
    return false;
  for (Instruction &I : instructions(F))
    if (I.mayHaveSideEffects())
      return false;
  return true;
}

}  // namespace

bool hoistLiftedTailChains(Module &M, const TaintSet &taint, WidthDispatch &wd) {
  Planner PL;
  SmallVector<std::pair<CallInst *, Plan *>, 4> Sites;
  SmallPtrSet<Function *, 32> Before;  // `isProvenSpecSite` may declare.
  for (Function &F : M)
    Before.insert(&F);
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    std::optional<DominatorTree> DT;
    std::optional<LoopInfo> LI;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        Function *Callee = CI ? CI->getCalledFunction() : nullptr;
        if (!Callee || Callee->isDeclaration() || Callee->isIntrinsic() ||
            CI->getFunctionType() != Callee->getFunctionType())
          continue;
        Plan *P = PL.planFor(Callee);
        if (!P || !P->hoistable())
          continue;
        if (!DT) {
          DT.emplace(F);
          LI.emplace(*DT);
        }
        if (owes(*CI, *P, taint, *DT, *LI, /*Hoist=*/true) &&
            isProvenSpecSite(*CI, taint, wd))
          Sites.push_back({CI, P});
      }
  }
  for (Function &F : make_early_inc_range(M))
    if (!Before.count(&F) && F.isDeclaration() && F.use_empty())
      F.eraseFromParent();  // never leave a phantom declaration (n0ui).
  for (auto &[CI, P] : Sites) {
    IRBuilder<> B(CI);
    B.SetCurrentDebugLocation(CI->getDebugLoc());
    unsigned Leaves = 0;
    Value *V = emit(PL, *P, P->Root, *CI, B, Leaves);
    if (!Leaves && !wouldInstructionBeTriviallyDead(CI) && !effectFree(*P->F)) {
      Function *Z = PL.zeroSrc(*P->F);
      B.CreateCall(Z, SmallVector<Value *, 8>(CI->args()))
          ->setCallingConv(Z->getCallingConv());
    }
    CI->replaceAllUsesWith(V);
    if (P->N[P->Root].K == Node::Op)
      V->takeName(CI);  // never rename an argument the identity chain returns.
    CI->eraseFromParent();
  }
  return !Sites.empty();
}

void tagUnhoistedLiftTail(CallInst &CI, const TaintSet &taint) {
  Function *Callee = CI.getCalledFunction();
  if (!Callee || Callee->isDeclaration() || Callee->isIntrinsic() ||
      CI.getFunctionType() != Callee->getFunctionType())
    return;
  Planner PL;
  Plan *P = PL.planFor(Callee);
  if (!P || !P->hoistable())
    return;
  DominatorTree DT(*CI.getFunction());
  LoopInfo LI(DT);
  if (const uint64_t Mask = owes(CI, *P, taint, DT, LI, /*Hoist=*/false)) {
    LLVMContext &Ctx = CI.getContext();
    CI.setMetadata(kLiftTailOwedTag,
                   MDNode::get(Ctx, ConstantAsMetadata::get(ConstantInt::get(
                                        Type::getInt64Ty(Ctx), Mask))));
  }
}

bool declineUnhoistedLiftTails(Module &M, const TaintSet &taint) {
  bool Loud = false;
  for (Function &F : M) {
    std::optional<PostDominatorTree> PDT;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        MDNode *MD = I.getMetadata(kLiftTailOwedTag);
        if (!MD)
          continue;
        I.setMetadata(kLiftTailOwedTag, nullptr);
        auto *CI = dyn_cast<CallInst>(&I);
        auto *K = MD->getNumOperands() == 1
                      ? mdconst::dyn_extract<ConstantInt>(MD->getOperand(0))
                      : nullptr;
        if (Loud || !CI || !K)
          continue;
        const uint64_t Mask = K->getZExtValue();
        bool UserData = false;
        for (unsigned A = 0; A < CI->arg_size() && A < 64; ++A)
          if ((Mask >> A & 1) && qqTargetIsUserData(CI, CI->getArgOperand(A)))
            UserData = true;
        if (!UserData)
          continue;
        if (!PDT)
          PDT.emplace(F);
        if (!qqResultSurvives(CI, taint, F, *PDT))
          continue;
        F.getContext().diagnose(
            DiagnosticInfoUnsupported(F, kMsgLiftTailUnhoisted, CI->getDebugLoc()));
        Loud = true;
      }
  }
  return Loud;
}

}  // namespace cq
