// StaleReadRegion.cpp — see StaleReadRegion.h (bd test_C_libtooling-57ch.1 and the
// returns-normally half of bd 57ch.4).

#include "StaleReadRegion.h"

#include "CalleeBody.h"  // calleeBodyTrusted

#include "llvm/Analysis/CFG.h"  // FindFunctionBackedges
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"  // isGuaranteedToTransferExecutionToSuccessor
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq {

namespace {

constexpr unsigned kMaxSpanBlocks = 64;  // one `uint64_t` reach mask per block

bool closedTerminator(const BasicBlock &BB) {
  const Instruction *T = BB.getTerminator();
  return T && (isa<BranchInst>(T) || isa<SwitchInst>(T));
}

// The span blocks strictly between `D` and `B` (every block on a path from `D`
// that does not pass `B`), in reverse post-order of a DFS from `D`. False when the
// span is cyclic (a DFS edge to a block on the stack, `D` included), leaves the
// span by a terminator other than `br`/`switch` (a path that never reaches `B`),
// or exceeds `kMaxSpanBlocks`.
bool spanBlocks(BasicBlock *D, BasicBlock *B, SmallVectorImpl<BasicBlock *> &Topo) {
  enum Color : unsigned char { White = 0, Grey, Black };
  DenseMap<BasicBlock *, Color> Seen;
  SmallVector<std::pair<BasicBlock *, unsigned>, 16> Stack;
  SmallVector<BasicBlock *, 16> Post;
  if (!closedTerminator(*D))
    return false;
  Seen[D] = Grey;
  Stack.push_back({D, 0});
  while (!Stack.empty()) {
    BasicBlock *X = Stack.back().first;
    const Instruction *TI = X->getTerminator();
    if (Stack.back().second < TI->getNumSuccessors()) {
      BasicBlock *Sx = TI->getSuccessor(Stack.back().second++);
      if (Sx == B)
        continue;
      const Color C = Seen.lookup(Sx);
      if (C == Grey)
        return false;  // a cycle in the span (or back into `D`)
      if (C == Black)
        continue;
      if (!closedTerminator(*Sx) || Seen.size() + 2 > kMaxSpanBlocks)
        return false;  // `D`, the span and `B` must fit one reach mask
      Seen[Sx] = Grey;
      Stack.push_back({Sx, 0});
      continue;
    }
    Seen[X] = Black;
    if (X != D)
      Post.push_back(X);
    Stack.pop_back();
  }
  Topo.assign(Post.rbegin(), Post.rend());
  return true;
}

bool bodyProvablyReturns(const Function &F, ReturnMemo &Memo);

}  // namespace

bool blockReachesAvoiding(ArrayRef<const BasicBlock *> Starts,
                          const BasicBlock *Target, const BasicBlock *Avoid) {
  SmallPtrSet<const BasicBlock *, 32> Seen;
  SmallVector<const BasicBlock *, 32> Work(Starts.begin(), Starts.end());
  while (!Work.empty()) {
    const BasicBlock *X = Work.pop_back_val();
    if (X == Target)
      return true;
    if (X == Avoid || !Seen.insert(X).second)
      continue;
    Work.append(succ_begin(X), succ_end(X));
  }
  return false;
}

bool instructionMayReach(const Instruction *From, const Instruction *To) {
  const BasicBlock *FB = From->getParent(), *TB = To->getParent();
  if (FB == TB && (From == To || From->comesBefore(To)))
    return true;
  SmallVector<const BasicBlock *, 4> Starts(succ_begin(FB), succ_end(FB));
  return blockReachesAvoiding(Starts, TB, /*Avoid=*/nullptr);
}

bool PlacementSpan::sameBlock() const { return Order.size() == 1; }

bool PlacementSpan::inSpan(const Instruction *X) const {
  auto It = Order.find(X->getParent());
  if (It == Order.end() || X == Read)
    return false;
  if (It->second == 0) {  // the slot's block: from the slot on
    if (X != At && !At->comesBefore(X))
      return false;
    return !sameBlock() || X->comesBefore(Read);
  }
  if (X->getParent() == Read->getParent())
    return X->comesBefore(Read);
  return true;
}

bool PlacementSpan::mayRunBefore(const Instruction *J, const Instruction *M) const {
  const BasicBlock *JB = J->getParent(), *MB = M->getParent();
  if (JB == MB)
    return J->comesBefore(M);
  auto JI = Order.find(JB), MI = Order.find(MB);
  if (JI == Order.end() || MI == Order.end())
    return true;  // not asked of anything outside the span; answer conservatively
  return (Reach[JI->second] >> MI->second) & 1;
}

void PlacementSpan::crossed(SmallVectorImpl<Instruction *> &Out) const {
  if (sameBlock()) {
    for (Instruction *J = At; J != Read; J = J->getNextNode())
      Out.push_back(J);
    return;
  }
  for (Instruction *J = At; J; J = J->getNextNode())
    Out.push_back(J);
  for (BasicBlock *X : Blocks)
    for (Instruction &J : *X)
      Out.push_back(&J);
  for (Instruction &J : *Read->getParent()) {
    if (&J == Read)
      break;
    Out.push_back(&J);
  }
}

bool stalePlacementSpan(Instruction &I, ArrayRef<CallInst *> Stalers,
                        const DominatorTree &DT, const PostDominatorTree &PDT,
                        PlacementSpan &S) {
  S = PlacementSpan();
  BasicBlock *B = I.getParent();
  BasicBlock *D = B;
  for (CallInst *T : Stalers) {
    D = DT.findNearestCommonDominator(D, T->getParent());
    if (!D)
      return false;
  }
  Instruction *At = nullptr;
  for (CallInst *T : Stalers)
    if (T->getParent() == D && (!At || T->comesBefore(At)))
      At = T;
  S.Read = &I;
  if (D == B) {
    // One block: every staler in it, before the read (a staler reaching the read
    // around a loop from another block has no slot here).
    for (CallInst *T : Stalers)
      if (T->getParent() != B || !T->comesBefore(&I))
        return false;
    S.At = At;
    S.Order[B] = 0;
    S.Reach.push_back(1);
    return true;
  }
  if (!At)
    At = D->getTerminator();  // every staler lies in a block `D` strictly dominates
  S.At = At;
  if (!PDT.dominates(B, D) || !spanBlocks(D, B, S.Blocks))
    return false;
  // `B` must not run again without `D` running first. Asked EXACTLY (round-1 F1:
  // `isPotentiallyReachableFromMany` with an exclusion set drops the dominator tree
  // and answers "reachable" past 32 explored blocks, which refused a read followed
  // by a long classical tail).
  SmallVector<const BasicBlock *, 4> FromB(succ_begin(B), succ_end(B));
  if (blockReachesAvoiding(FromB, B, D))
    return false;
  // Span order: `D` = 0, the span blocks topologically, `B` last.
  S.Order[D] = 0;
  for (unsigned K = 0; K != S.Blocks.size(); ++K)
    S.Order[S.Blocks[K]] = K + 1;
  const unsigned Last = S.Blocks.size() + 1;
  S.Order[B] = Last;
  S.Reach.assign(Last + 1, 0);
  S.Reach[Last] = uint64_t(1) << Last;
  for (unsigned K = Last; K-- > 0;) {
    BasicBlock *X = K == 0 ? D : S.Blocks[K - 1];
    uint64_t R = uint64_t(1) << K;
    for (BasicBlock *Sx : successors(X))
      if (auto It = S.Order.find(Sx); It != S.Order.end() && It->second > K)
        R |= S.Reach[It->second];
    S.Reach[K] = R;
  }
  // Every staler in the span (the slot, after it in `D`, a span block, or `B`
  // before the read).
  for (CallInst *T : Stalers)
    if (T != At && !S.inSpan(T))
      return false;
  return true;
}

namespace {

bool bodyProvablyReturns(const Function &F, ReturnMemo &Memo) {
  if (auto It = Memo.Bodies.find(&F); It != Memo.Bodies.end())
    return It->second;  // done, or in progress (false: recursion refuses)
  Memo.Bodies[&F] = false;
  SmallVector<std::pair<const BasicBlock *, const BasicBlock *>, 4> BackEdges;
  FindFunctionBackedges(F, BackEdges);
  if (!BackEdges.empty())
    return false;
  for (const BasicBlock &BB : F)
    for (const Instruction &X : BB) {
      if (X.isTerminator()) {
        if (!isa<BranchInst>(X) && !isa<SwitchInst>(X) && !isa<ReturnInst>(X))
          return false;
        continue;
      }
      if (X.isEHPad())
        return false;
      if (const auto *CB = dyn_cast<CallBase>(&X)) {
        if (!callProvablyReturns(*CB, Memo))
          return false;
        continue;
      }
      if (!isGuaranteedToTransferExecutionToSuccessor(&X))
        return false;  // e.g. a volatile store
    }
  Memo.Bodies[&F] = true;
  return true;
}

// Does `M` hold a call that may return twice (`setjmp`, `vfork`, …)? The call-site
// or callee `returns_twice` attribute, as LLVM models it (`CallBase::hasFnAttr`),
// AND the `__builtin_setjmp` intrinsic, which clang -O1 emits as
// `llvm.eh.sjlj.setjmp` carrying only `nounwind`, no `returns_twice` (batch 053
// narrow review): the ruling's "no setjmp" covers it.
bool moduleHasReturnsTwiceCall(const Module &M) {
  for (const Function &F : M)
    for (const Instruction &X : instructions(F))
      if (const auto *CB = dyn_cast<CallBase>(&X);
          CB && (CB->hasFnAttr(Attribute::ReturnsTwice) ||
                 CB->getIntrinsicID() == Intrinsic::eh_sjlj_setjmp))
        return true;
  return false;
}

}  // namespace

bool callTerminationCrossable(const CallBase &CB, ReturnMemo &Memo) {
  if (callProvablyReturns(CB, Memo))
    return true;
  if (!CB.doesNotThrow())
    return false;
  if (Memo.ModuleReturnsTwice < 0)
    Memo.ModuleReturnsTwice = moduleHasReturnsTwiceCall(*CB.getModule());
  return Memo.ModuleReturnsTwice == 0;
}

bool callProvablyReturns(const CallBase &CB, ReturnMemo &Memo) {
  if (isGuaranteedToTransferExecutionToSuccessor(&CB))
    return true;
  if (!isa<CallInst>(CB) || CB.isInlineAsm() || !CB.doesNotThrow() ||
      CB.hasFnAttr(Attribute::NoReturn) || CB.hasFnAttr(Attribute::ReturnsTwice))
    return false;
  const Function *F = CB.getCalledFunction();
  if (!F || F->getIntrinsicID() != Intrinsic::not_intrinsic || F->isVarArg() ||
      F->hasFnAttribute(Attribute::Naked) ||
      !calleeBodyTrusted(F, CalleeBodyUse::AssumeOfLinkedCall))
    return false;
  return bodyProvablyReturns(*F, Memo);
}

}  // namespace cq
