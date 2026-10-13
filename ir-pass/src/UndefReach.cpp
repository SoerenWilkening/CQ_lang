// UndefReach.cpp — see UndefReach.h (bd p3kd.8).

#include "UndefReach.h"

#include "LiteralIntegrity.h"  // slotCarriesUndef — the one undef-slot predicate

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <utility>

using namespace llvm;

namespace cq {

namespace {

// What the evaluation knows about one value on every execution through the edge.
struct Fact {
  Constant *K = nullptr;  // the exact value (a ConstantInt / ConstantFP), or null
  bool Undef = false;     // derived, as data, from an undef/poison constant
};

using Edge = std::pair<const BasicBlock *, const BasicBlock *>;

// The blocks reachable from `Start` in reverse post-order, or false when a cycle is
// reachable from `Start` (`Start` itself included): B's phis would then be
// re-assigned within one execution and the edge assumption would not hold.
bool acyclicRegionRPO(const BasicBlock *Start,
                      SmallVectorImpl<const BasicBlock *> &RPO) {
  enum Color { Grey, Black };
  DenseMap<const BasicBlock *, Color> Seen;
  SmallVector<std::pair<const BasicBlock *, const_succ_iterator>, 16> Stack;
  SmallVector<const BasicBlock *, 16> Post;
  Seen[Start] = Grey;
  Stack.push_back({Start, succ_begin(Start)});
  while (!Stack.empty()) {
    auto &[BB, It] = Stack.back();
    if (It == succ_end(BB)) {
      Seen[BB] = Black;
      Post.push_back(BB);
      Stack.pop_back();
      continue;
    }
    const BasicBlock *S = *It;
    ++It;
    auto F = Seen.find(S);
    if (F == Seen.end()) {
      Seen[S] = Grey;
      Stack.push_back({S, succ_begin(S)});
    } else if (F->second == Grey) {
      return false;  // a back edge: a cycle reachable from `Start`
    }
  }
  RPO.assign(Post.rbegin(), Post.rend());
  return true;
}

class EdgeEval {
public:
  EdgeEval(const BasicBlock *Start, const BasicBlock *Pred)
      : Start(Start), Pred(Pred),
        DL(Start->getModule()->getDataLayout()) {}

  // True iff an undef-derived value reaches an executable `ret` (or the shape is
  // not modelled).
  bool reachesReturn() {
    SmallVector<const BasicBlock *, 32> RPO;
    if (!acyclicRegionRPO(Start, RPO))
      return true;
    if (!seedPathConditions())
      return true;
    Exec.insert(Start);
    for (const BasicBlock *BB : RPO) {
      if (!Exec.count(BB))
        continue;
      for (const Instruction &I : *BB) {
        if (I.isTerminator()) {
          if (visitTerminator(I))
            return true;
          continue;
        }
        Facts[&I] = evaluate(I);
      }
    }
    return false;
  }

private:
  const BasicBlock *Start;
  const BasicBlock *Pred;
  const DataLayout &DL;
  DenseMap<const Value *, Fact> Facts;
  DenseMap<const Value *, Constant *> Assume;  // branch conditions the edge implies
  SmallPtrSet<const BasicBlock *, 32> Exec;
  DenseSet<Edge> ExecEdges;

  static bool exactConstant(const Constant *C) {
    return isa<ConstantInt>(C) || isa<ConstantFP>(C);
  }

  // `From -> To` is an edge. If `From` ends in a two-way conditional `br`, every
  // execution taking the edge saw its condition at the polarity that selects
  // `To`. False on a contradiction (the same condition needed both ways), which
  // the caller treats conservatively.
  bool assumeBranchTo(const BasicBlock *From, const BasicBlock *To) {
    const auto *BI = dyn_cast<BranchInst>(From->getTerminator());
    if (!BI || !BI->isConditional() || BI->getSuccessor(0) == BI->getSuccessor(1))
      return true;
    const Value *C = BI->getCondition();
    if (isa<Constant>(C))
      return true;
    Constant *V = ConstantInt::getBool(C->getContext(), BI->getSuccessor(0) == To);
    auto [It, New] = Assume.try_emplace(C, V);
    return New || It->second == V;
  }

  // The path condition into the edge `Pred -> Start`: the edge's own branch, then
  // the branch above each block of the single-predecessor chain that ends at
  // `Pred`. Every execution through the edge ran that chain (a block with one
  // predecessor is entered only from it), and each condition is an SSA value
  // defined above its branch, so it keeps that value for the rest of the
  // execution (the region below `Start` is acyclic, so nothing re-enters the
  // chain). exp2 (src/s_exp2.c) needs it: its undef incoming `%61` comes from the
  // `%49`-true arm, and the only reader of `%61` sits behind `br i1 %49` false.
  bool seedPathConditions() {
    if (!assumeBranchTo(Pred, Start))
      return false;
    SmallPtrSet<const BasicBlock *, 16> Seen;
    for (const BasicBlock *X = Pred; Seen.insert(X).second;) {
      const BasicBlock *Y = X->getSinglePredecessor();
      if (!Y)
        break;
      if (!assumeBranchTo(Y, X))
        return false;
      X = Y;
    }
    return true;
  }

  // A value defined outside the evaluated region (or not yet evaluated) is
  // unknown and not undef-derived: its own undef, if any, is a separate incoming
  // or operand that the bd 3p2a walk adjudicates on its own.
  Fact factOf(const Value *V) const {
    if (const auto *C = dyn_cast<Constant>(V)) {
      if (slotCarriesUndef(C))
        return Fact{nullptr, true};
      if (exactConstant(C))
        return Fact{const_cast<Constant *>(C), false};
      return Fact{};
    }
    if (auto A = Assume.find(V); A != Assume.end())
      return Fact{A->second, false};
    auto It = Facts.find(V);
    return It == Facts.end() ? Fact{} : It->second;
  }

  Fact evaluate(const Instruction &I) const {
    if (const auto *PN = dyn_cast<PHINode>(&I)) {
      if (PN->getParent() == Start)  // the edge assumption
        return factOf(PN->getIncomingValueForBlock(Pred));
      Fact Out;
      bool First = true;
      for (unsigned N = 0, E = PN->getNumIncomingValues(); N != E; ++N) {
        if (!ExecEdges.count({PN->getIncomingBlock(N), PN->getParent()}))
          continue;
        const Fact In = factOf(PN->getIncomingValue(N));
        Out.Undef |= In.Undef;
        if (First)
          Out.K = In.K;
        else if (Out.K != In.K)
          Out.K = nullptr;
        First = false;
      }
      if (Out.Undef)
        Out.K = nullptr;
      return Out;
    }
    if (const auto *SI = dyn_cast<SelectInst>(&I)) {
      const Fact C = factOf(SI->getCondition());
      if (C.Undef)
        return Fact{nullptr, true};
      if (auto *CK = dyn_cast_or_null<ConstantInt>(C.K))
        return factOf(CK->isOne() ? SI->getTrueValue() : SI->getFalseValue());
      const Fact T = factOf(SI->getTrueValue());
      const Fact F = factOf(SI->getFalseValue());
      if (T.Undef || F.Undef)
        return Fact{nullptr, true};
      return Fact{T.K && T.K == F.K ? T.K : nullptr, false};
    }
    SmallVector<Constant *, 4> Ops;
    bool AllKnown = true;
    for (const Value *Op : I.operands()) {
      const Fact OF = factOf(Op);
      if (OF.Undef)
        return Fact{nullptr, true};
      if (OF.K)
        Ops.push_back(OF.K);
      else
        AllKnown = false;
    }
    if (!AllKnown || isa<CallBase>(I) || I.mayReadOrWriteMemory())
      return Fact{};
    Constant *K = ConstantFoldInstOperands(const_cast<Instruction *>(&I), Ops,
                                           DL, /*TLI=*/nullptr,
                                           /*AllowNonDeterministic=*/false);
    if (K && exactConstant(K) && !slotCarriesUndef(K))
      return Fact{K, false};
    return Fact{};
  }

  void markEdge(const BasicBlock *From, const BasicBlock *To) {
    ExecEdges.insert({From, To});
    Exec.insert(To);
  }

  // True iff this terminator returns an undef-derived value or is not modelled.
  bool visitTerminator(const Instruction &T) {
    const BasicBlock *BB = T.getParent();
    if (const auto *R = dyn_cast<ReturnInst>(&T)) {
      const Value *RV = R->getReturnValue();
      return RV && factOf(RV).Undef;
    }
    if (isa<UnreachableInst>(T))
      return false;
    if (const auto *BI = dyn_cast<BranchInst>(&T)) {
      if (BI->isConditional())
        if (auto *CK = dyn_cast_or_null<ConstantInt>(
                factOf(BI->getCondition()).K)) {
          markEdge(BB, BI->getSuccessor(CK->isOne() ? 0 : 1));
          return false;
        }
      // Unconditional, unknown, or undef-derived (UB on every defined execution,
      // LangRef `br`): every successor.
      for (const BasicBlock *S : successors(BB))
        markEdge(BB, S);
      return false;
    }
    if (const auto *SW = dyn_cast<SwitchInst>(&T)) {
      if (auto *CK = dyn_cast_or_null<ConstantInt>(factOf(SW->getCondition()).K)) {
        markEdge(BB, SW->findCaseValue(CK)->getCaseSuccessor());
        return false;
      }
      for (const BasicBlock *S : successors(BB))
        markEdge(BB, S);
      return false;
    }
    return true;  // indirectbr / callbr / invoke / EH: not modelled.
  }
};

}  // namespace

bool undefIncomingReachesReturn(const PHINode &PN, unsigned K) {
  return EdgeEval(PN.getParent(), PN.getIncomingBlock(K)).reachesReturn();
}

}  // namespace cq
