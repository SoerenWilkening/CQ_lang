// MergeCarriedFence.cpp — see header (bd test_C_libtooling-r2j3.32).

#include "MergeCarriedFence.h"
#include "MergeStreamGates.h"  // calleeName / isControlledCopy / isMergeWrite /
                               // streamGateWrites / readsState / isRegister /
                               // handleAliases

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

const char kMsgCarriedMergeLeak[] =
    "cq merge discharge: non-diagonal gate on a register a leaked "
    "loop-carried merge rail records";

namespace {

// The loop across whose back edge `Out` is carried: the outermost loop
// containing it whose header has a φ that takes `Out`. Null: not carried.
Loop *carriedLoop(CallInst *Out, LoopInfo &LI) {
  Loop *Hit = nullptr;
  for (Loop *L = LI.getLoopFor(Out->getParent()); L; L = L->getParentLoop())
    for (User *U : Out->users())
      if (auto *P = dyn_cast<PHINode>(U); P && P->getParent() == L->getHeader())
        Hit = L;
  return Hit;
}

// The registers `Out`'s value was computed from: its writers' operands, closed
// backward over producers' state-reading operands, φ / select / cast / freeze
// operands, and the writers of each visited value (a CNOT-copied flag names
// its control). Carried records (`Skip`) are not leaves and are not walked.
void leavesOf(CallInst *Out, const SmallPtrSetImpl<Value *> &Skip,
              const TaintSet &taint, SmallPtrSetImpl<Value *> &Leaves) {
  SmallVector<Value *, 16> Work;
  auto pushOperands = [&](CallInst *C, const Value *Except) {
    for (unsigned S = 0, E = C->arg_size(); S != E; ++S) {
      Value *Op = C->getArgOperand(S);
      if (Op != Except && readsState(C, S) && isRegister(Op, taint))
        Work.push_back(Op);
    }
  };
  for (User *U : Out->users())
    if (auto *C = dyn_cast<CallInst>(U); C && isMergeWrite(C, Out))
      pushOperands(C, Out);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (Skip.count(V) || !isRegister(V, taint) || !Leaves.insert(V).second)
      continue;
    if (auto *C = dyn_cast<CallInst>(V))
      pushOperands(C, V);
    else if (auto *P = dyn_cast<PHINode>(V))
      Work.append(P->value_op_begin(), P->value_op_end());
    else if (auto *S = dyn_cast<SelectInst>(V)) {
      Work.push_back(S->getTrueValue());
      Work.push_back(S->getFalseValue());
    } else if (isa<CastInst>(V) || isa<FreezeInst>(V))
      Work.push_back(cast<Instruction>(V)->getOperand(0));
    // The stream gates that WROTE V: their other register operands (the CNOT
    // control a flag copies, a compare a Toffoli conjoins). A gate outside the
    // stream vocabulary (a rotation, a controlled Ry) computes nothing V is a
    // copy of; if it acts on V after the loop the hazard scan sees it there.
    for (User *U : V->users()) {
      auto *C = dyn_cast<CallInst>(U);
      if (!C || C == V)
        continue;
      SmallVector<unsigned, 2> Wr;
      if (!streamGateWrites(C, Wr))
        continue;
      bool WritesV = false;
      for (unsigned S : Wr)
        if (S < C->arg_size() && C->getArgOperand(S) == V)
          WritesV = true;
      if (WritesV)
        pushOperands(C, V);
    }
  }
}

bool isRuntime(StringRef N) {
  return N.starts_with("cqrt_") || N.starts_with("cq_template_");
}

bool hazardIn(Function &F, Value *Leaf, const TaintSet &taint, unsigned Depth);

// Does `C` act non-diagonally on the register `A` (header list)?
bool isHazard(CallInst *C, const Value *A, const TaintSet &taint,
              unsigned Depth) {
  StringRef N = calleeName(C);
  SmallVector<unsigned, 3> Slots;
  for (unsigned S = 0, E = C->arg_size(); S != E; ++S)
    if (C->getArgOperand(S) == A)
      Slots.push_back(S);
  if (Slots.empty())
    return false;
  if (N.empty())
    return true;  // an indirect call consuming the leaf: fails closed.
  if (!isRuntime(N)) {
    Function *Callee = C->getCalledFunction();
    if (N.starts_with("cq_measure"))
      return false;
    if (!Callee || Callee->isDeclaration() || !N.starts_with("__cq_q_") ||
        Depth > 4)
      return true;
    for (unsigned S : Slots)
      if (S < Callee->arg_size() &&
          hazardIn(*Callee, Callee->getArg(S), taint, Depth + 1))
        return true;
    return false;
  }
  bool Ctl = N.contains("_controlled");
  for (unsigned S : Slots) {
    if (N.starts_with("cqrt_ry"))
      return S == (Ctl ? 1u : 0u);
    if (N == "cqrt_cswap")
      return S == 1 || S == 2;
    if (Ctl && N.starts_with("cqrt_") && S != 0 &&
        !(isControlledCopy(C) && S == 1))
      return true;
  }
  return false;
}

// Is there a non-diagonal gate anywhere in `F` on the alias class of `Leaf`?
// (A lifted body: its parameter is the leaf for the whole body.)
bool hazardIn(Function &F, Value *Leaf, const TaintSet &taint, unsigned Depth) {
  DominatorTree DT(F);
  SmallPtrSet<Value *, 8> Alias;
  if (!handleAliases(Leaf, taint, DT, Alias))
    return true;
  for (Value *A : Alias)
    for (User *U : A->users())
      if (auto *C = dyn_cast<CallInst>(U); C && isHazard(C, A, taint, Depth))
        return true;
  return false;
}

}  // namespace

bool fenceCarriedMergeLeaks(Function &F, const TaintSet &taint,
                            ArrayRef<CallInst *> Left, DominatorTree &DT,
                            LoopInfo &LI) {
  SmallVector<std::pair<CallInst *, Loop *>, 4> Carried;
  SmallPtrSet<Value *, 8> Records;
  for (CallInst *Out : Left)
    if (Loop *L = carriedLoop(Out, LI)) {
      Carried.push_back({Out, L});
      Records.insert(Out);
    }
  for (auto &[Out, L] : Carried) {
    SmallPtrSet<Value *, 16> Leaves;
    leavesOf(Out, Records, taint, Leaves);
    BasicBlock *H = L->getHeader();
    auto after = [&](const Instruction *I) {
      return !L->contains(I->getParent()) &&
             isPotentiallyReachable(H, I->getParent(), nullptr, &DT, &LI);
    };
    auto loud = [&](const Instruction *At) {
      F.getContext().diagnose(DiagnosticInfoUnsupported(
          F, kMsgCarriedMergeLeak, At->getDebugLoc()));
      return true;
    };
    for (Value *Leaf : Leaves) {
      SmallPtrSet<Value *, 8> Alias;
      if (!handleAliases(Leaf, taint, DT, Alias))  // unproven memory: closed.
        return loud(isa<Instruction>(Leaf) ? cast<Instruction>(Leaf) : Out);
      for (Value *A : Alias)
        for (User *U : A->users())
          if (auto *C = dyn_cast<CallInst>(U);
              C && after(C) && isHazard(C, A, taint, 0))
            return loud(C);
    }
  }
  return false;
}

}  // namespace cq
