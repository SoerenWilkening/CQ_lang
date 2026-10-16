// SpecializeTailPlan.h — the RETURN-CHAIN PLAN of a lifted callee and its
// SOURCE functions (bd test_C_libtooling-r2j3.37.1; SpecializeConsume.h holds
// the mechanism and its argument). Header-only: the consuming-clone builder and
// the lift-site tag are its clients.
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

#include "llvm/ADT/DenseMap.h"
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
// of a nested callee's plan, evaluated at `InnerCall`. `Sel` (bd r2j3.37.3) is a
// `select` of two chains: `V` its condition (an `F` value), `L`/`R` its true and
// false arms; the consuming clone branches on it when it is classical.
struct Node {
  enum Kind { Arg, Const, Leaf, Op, Sel } K = Leaf;
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

  // bd r2j3.37.1: a copy of `P.F` returning the value of node `I` (any node with
  // no parameter the caller consumes: a leaf, or an Op over leaves, constants
  // and other parameters), the SOURCE the consuming clone lifts for one
  // in-place op of the chain.
  Function *subtreeSrc(Plan &P, int I) {
    if (P.N[I].K == Node::Leaf)
      return srcFor(P, I);
    return cloneReturning(*P.F, [&](ValueToValueMapTy &VMap, ReturnInst *Ret) {
      IRBuilder<> B(Ret);
      return emitInto(P, I, VMap, B, *Ret->getFunction());
    });
  }

  // bd r2j3.37.3: a copy of `P.F` returning select node `I`'s CONDITION,
  // zero-extended to `F`'s return width (a source returns `F`'s type).
  Function *condSrc(Plan &P, int I) {
    return cloneReturning(*P.F, [&](ValueToValueMapTy &VMap, ReturnInst *Ret) {
      IRBuilder<> B(Ret);
      return B.CreateZExtOrTrunc(VMap[P.N[I].V], Ret->getFunction()->getReturnType());
    });
  }

private:
  std::map<Function *, std::unique_ptr<Plan>> Plans;
  SmallPtrSet<Function *, 8> OnStack;
  unsigned Counter = 0;

  // Node `I` of `P`, materialised in `G`, a copy of `P.F` (`VMap` its map).
  Value *emitInto(Plan &P, int I, ValueToValueMapTy &VMap, IRBuilder<> &B,
                  Function &G) {
    Node &Nd = P.N[I];
    switch (Nd.K) {
    case Node::Arg:
      return G.getArg(Nd.ArgNo);
    case Node::Const:
      return Nd.C;
    case Node::Leaf: {
      if (Nd.V)
        return VMap[Nd.V];
      Function *Inner = srcFor(*Nd.HP, Nd.HIdx);
      auto *IC = cast<CallInst>(VMap[Nd.InnerCall]);
      CallInst *NC = B.CreateCall(Inner, SmallVector<Value *, 8>(IC->args()));
      NC->setCallingConv(Inner->getCallingConv());
      return NC;
    }
    case Node::Op: {
      Value *L = emitInto(P, Nd.L, VMap, B, G);
      Value *R = emitInto(P, Nd.R, VMap, B, G);
      return B.CreateBinOp(Nd.Opc, L, R);
    }
    case Node::Sel: {
      Value *L = emitInto(P, Nd.L, VMap, B, G);
      Value *R = emitInto(P, Nd.R, VMap, B, G);
      return B.CreateSelect(VMap[Nd.V], L, R);
    }
    }
    return nullptr;
  }

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
    // bd r2j3.37.3: a select of chains (a classical branch over two returns,
    // `-O1`'s if/else at the return root). Its condition stays an `F` value.
    if (auto *SI = dyn_cast<SelectInst>(V); SI && chainType(SI->getType())) {
      const int L = expr(P, SI->getTrueValue());
      const int R = expr(P, SI->getFalseValue());
      if (!P.N[L].HasArg && !P.N[R].HasArg)
        return leaf(P, V);
      Node Nd;
      Nd.K = Node::Sel;
      Nd.V = SI->getCondition();
      Nd.L = L;
      Nd.R = R;
      Nd.HasArg = true;
      return add(P, Nd);
    }
    if (auto *CI = dyn_cast<CallInst>(V)) {
      Function *H = CI->getCalledFunction();
      if (H && !H->isIntrinsic() && !H->isDeclaration() && !CI->isMustTailCall() &&
          CI->getFunctionType() == H->getFunctionType())
        if (Plan *HP = planFor(H); HP && HP->hoistable() && !hasSel(*HP))
          return substitute(P, *HP, HP->Root, CI);  // (a nested select: a leaf)
    }
    return leaf(P, V);
  }

  static bool hasSel(const Plan &P) {
    for (const Node &Nd : P.N)
      if (Nd.K == Node::Sel)
        return true;
    return false;
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
    case Node::Sel:
      return -1;  // never: `expr` does not substitute a plan holding a select.
    }
    return -1;
  }
};

// bd r2j3.37.1 R11 r1 (rL1C-F2 / rL1A-F2): may a consuming clone stand for `F`?
// Its body applies ONLY the return chain, and each source clone re-runs `F`; so
// `F` must have no effect but its return value: no cycle (termination), no
// instruction that may have a side effect, and every call either side-effect
// free itself or to a defined callee that satisfies this too (the hand IR
// `-O1`'s attribute inference never saw). Asked at candidate build; a body that
// fails is not consumed (loud when owed).
inline bool consumableBody(const Function &F,
                           SmallPtrSetImpl<const Function *> &Stack) {
  if (F.isDeclaration() || !Stack.insert(&F).second)
    return false;
  SmallVector<std::pair<const BasicBlock *, const BasicBlock *>, 2> Back;
  FindFunctionBackedges(F, Back);
  bool OK = Back.empty();
  for (const Instruction &I : instructions(F)) {
    if (!OK || !I.mayHaveSideEffects())
      continue;
    const auto *CI = dyn_cast<CallInst>(&I);
    const Function *G = CI ? CI->getCalledFunction() : nullptr;
    OK = G && !G->isIntrinsic() && consumableBody(*G, Stack);
  }
  Stack.erase(&F);
  return OK;
}

// bd r2j3.37.1 R11 r1 (rL1B-F1): the parameters `F`'s returned value reaches
// through xor/add/sub (the opcodes the in-place rounds convert) and through
// EVERY arm of the muxes a classical branch makes of them (select, φ), across nested
// calls whose own return reaches the parameter they bind (bit i = parameter i).
// A PROPERTY OF THE SITE, independent of whether a plan exists: such a slot,
// filled by a dead user register beside a kept result, is OWED in place — built
// when the plan covers it, LOUD otherwise. Not through a cast: `(int)t ^ a`
// reads `t` through a widening, which no in-place gate overwrites (as for the
// inlined op, whose QQ round never sees `t` as an operand).
inline uint64_t chainReachSlots(const Function &F,
                                SmallPtrSetImpl<const Function *> &Stack);
// Memoised per value (`Memo`; a value on the current walk reads 0, so a φ cycle
// contributes nothing): the slots `V` passes through on every path.
inline uint64_t chainReachValue(const Value *V,
                                DenseMap<const Value *, uint64_t> &Memo,
                                SmallPtrSetImpl<const Function *> &Stack) {
  if (auto It = Memo.find(V); It != Memo.end())
    return It->second;
  Memo[V] = 0;  // in progress
  uint64_t M = 0;
  if (const auto *A = dyn_cast<Argument>(V)) {
    M = A->getArgNo() < 64 ? uint64_t(1) << A->getArgNo() : 0;
  } else if (const auto *BO = dyn_cast<BinaryOperator>(V);
             BO && isQQStemOpcode(BO->getOpcode()) &&
             BO->getType()->isIntegerTy() &&
             BO->getType()->getIntegerBitWidth() <= 64) {
    M = chainReachValue(BO->getOperand(0), Memo, Stack) |
        chainReachValue(BO->getOperand(1), Memo, Stack);
  } else if (const auto *SI = dyn_cast<SelectInst>(V)) {
    // bd r2j3.37.3: a mux of chains: the parameter must pass through EVERY arm
    // (an arm returning something else is no permutation of it).
    M = chainReachValue(SI->getTrueValue(), Memo, Stack) &
        chainReachValue(SI->getFalseValue(), Memo, Stack);
  } else if (const auto *PN = dyn_cast<PHINode>(V)) {
    M = PN->getNumIncomingValues() ? ~uint64_t(0) : 0;
    for (const Value *In : PN->incoming_values())
      M &= chainReachValue(In, Memo, Stack);
  } else if (const auto *CI = dyn_cast<CallInst>(V)) {
    const Function *H = CI->getCalledFunction();
    if (H && !H->isIntrinsic() && !H->isDeclaration() &&
        CI->getFunctionType() == H->getFunctionType()) {
      const uint64_t Inner = chainReachSlots(*H, Stack);
      for (unsigned J = 0; J < CI->arg_size() && J < 64; ++J)
        if (Inner >> J & 1)
          M |= chainReachValue(CI->getArgOperand(J), Memo, Stack);
    }
  }
  Memo[V] = M;
  return M;
}
inline uint64_t chainReachSlots(const Function &F,
                                SmallPtrSetImpl<const Function *> &Stack) {
  if (F.isDeclaration() || !Stack.insert(&F).second)
    return 0;
  // EVERY return must pass the parameter through: a path returning something
  // else (`return 10;`) makes the result no permutation of it, so no in-place
  // form exists and keeping the old register is the program (as inlined).
  uint64_t M = ~uint64_t(0);
  bool Any = false;
  DenseMap<const Value *, uint64_t> Memo;
  for (const BasicBlock &BB : F)
    if (const auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
      if (const Value *V = R->getReturnValue()) {
        M &= chainReachValue(V, Memo, Stack);
        Any = true;
      }
  Stack.erase(&F);
  return Any ? M : 0;
}


}  // namespace tailhoist
}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_TAIL_PLAN_H_
