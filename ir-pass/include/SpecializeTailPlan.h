// SpecializeTailPlan.h — the RETURN-CHAIN PLAN of a lifted callee and its
// SOURCE functions (bd test_C_libtooling-r2j3.37; SpecializeTailHoist.h holds the
// mechanism and its argument). Header-only: one client, the hoist.
//
// A plan is the callee's returned value read as an expression tree: `Op` nodes
// are xor/add/sub (`isQQStemOpcode`) at an integer width <= 64 with at least one
// parameter below them, `Arg` a parameter, `Const` a constant, and `Leaf` any
// other value the chain reads (computed by a SOURCE: a copy of the callee
// returning it). A nested call whose own plan reaches its parameters is
// SUBSTITUTED at the call (its leaves become sources evaluated at that call), so
// `g(t,a,b) = f(t,a) ^ b` plans as `(t ^ a) ^ b`. Planned only for a single-`ret`,
// non-variadic body the specializer may execute (`calleeBodyTrusted(Execute)`);
// recursion plans nothing through the cycle.
#ifndef CQ_IRPASS_SPECIALIZE_TAIL_PLAN_H_
#define CQ_IRPASS_SPECIALIZE_TAIL_PLAN_H_

#include "CalleeBody.h"  // calleeBodyTrusted
#include "InPlaceQQ.h"   // isQQStemOpcode

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/AttributeMask.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/Local.h"

#include <map>
#include <memory>
#include <vector>

namespace cq {
namespace tailhoist {

using namespace llvm;

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

inline void argNos(const Plan &P, int I, SmallVectorImpl<unsigned> &Out) {
  const Node &Nd = P.N[I];
  if (Nd.K == Node::Arg)
    Out.push_back(Nd.ArgNo);
  else if (Nd.K == Node::Op) {
    argNos(P, Nd.L, Out);
    argNos(P, Nd.R, Out);
  }
}

// A body with no side-effecting instruction and no cycle has no effect but its
// return (the attributes `-O1` would infer, asked of hand IR that lacks them).
inline bool effectFree(Function &F) {
  SmallVector<std::pair<const BasicBlock *, const BasicBlock *>, 2> Back;
  FindFunctionBackedges(F, Back);
  if (!Back.empty())
    return false;
  for (Instruction &I : instructions(F))
    if (I.mayHaveSideEffects())
      return false;
  return true;
}


}  // namespace tailhoist
}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_TAIL_PLAN_H_
