// InPlaceQQRecord.cpp — the two analysis halves of the in-place quantum-source
// round that bracket it in the pipeline (bd test_C_libtooling-r2j3.33, dm7f.51
// step 1; see InPlaceQQ.h): the pre-emission DEAD-OPERAND record it keys its
// eligibility on, and the post-`uncompute` POSTCONDITION that re-asks its
// prediction. Split out of InPlaceQQ.cpp for the 400-line file budget.

#include "InPlaceQQ.h"

#include "ChainWalk.h"         // isInPlaceGateOn
#include "EmitInverse.h"       // inPlaceQQAdjointName
#include "FreePoint.h"         // blockCanRepeat
#include "MergeStreamGates.h"  // streamGateWrites / handleAliases
#include "TaintPropagation.h"  // TaintSet
#include "WireWalk.h"          // provablyBefore

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"

#include <cstring>
#include <optional>

using namespace llvm;

namespace cq {

namespace {

bool isQQStem(Instruction::BinaryOps Op) {
  return Op == Instruction::Xor || Op == Instruction::Add ||
         Op == Instruction::Sub;
}

unsigned maskOf(const Instruction *I) {
  MDNode *MD = I->getMetadata(kDeadOperandTag);
  if (!MD || MD->getNumOperands() != 1)
    return 0;
  auto *C = mdconst::dyn_extract<ConstantInt>(MD->getOperand(0));
  return C ? static_cast<unsigned>(C->getZExtValue()) & 3u : 0u;
}

void setDeadMask(Instruction *I, unsigned Mask) {
  LLVMContext &Ctx = I->getContext();
  I->setMetadata(kDeadOperandTag,
                 MDNode::get(Ctx, ConstantAsMetadata::get(ConstantInt::get(
                                      Type::getInt32Ty(Ctx), Mask))));
}

// Is `V` DEAD after `BO` in the IR the user wrote: is `BO` its last reader?
// Bennett's exclusive reader (one operand occurrence) is the order-free special
// case; CQ asks the POSITIONAL question — every other user provably BEFORE `BO`
// (`provablyBefore`, the shared spelling) — because a completed earlier reader
// (a region compare, a measured record) does not keep the old value alive
// (owner ruling Q1: "the OLD x is dead at the op"). Whether that earlier reader
// is SETTLED is the fence's question (G7), asked later; here it only decides
// eligibility, i.e. in-place-or-loud versus out-of-place. A `BO` that can run
// again reads `V` again unless `V` is re-defined in the same cycle, so a `V`
// from outside `BO`'s loop is live (and an irreducible repeat is not proven).
// A φ is never a target (Bennett: it can alias another live name).
bool deadAfter(Value *V, BinaryOperator *BO, const DominatorTree &DT,
               const LoopInfo &LI) {
  if (isa<Constant>(V) || isa<PHINode>(V) ||
      BO->getOperand(0) == BO->getOperand(1))
    return false;
  if (Loop *L = LI.getLoopFor(BO->getParent())) {
    auto *VI = dyn_cast<Instruction>(V);
    if (!VI || !L->contains(VI))
      return false;
  } else if (blockCanRepeat(BO->getParent())) {
    return false;
  }
  for (User *U : V->users()) {
    if (U == BO)
      continue;
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI || !provablyBefore(UI, BO, DT))
      return false;
  }
  return true;
}

}  // namespace

void recordDeadQQOperands(Module &M, const TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    std::optional<DominatorTree> DT;
    std::optional<LoopInfo> LI;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *BO = dyn_cast<BinaryOperator>(&I);
        if (!BO || !isQQStem(BO->getOpcode()) || !BO->getType()->isIntegerTy() ||
            BO->getType()->getIntegerBitWidth() > 64)
          continue;
        if (!taint.Tainted.count(BO->getOperand(0)) &&
            !taint.Tainted.count(BO->getOperand(1)))
          continue;
        if (!DT) {
          DT.emplace(F);
          LI.emplace(*DT);
        }
        unsigned Mask = 0;
        for (unsigned Idx = 0; Idx < 2; ++Idx)
          if (deadAfter(BO->getOperand(Idx), BO, *DT, *LI))
            Mask |= 1u << Idx;
        if (Mask)
          setDeadMask(BO, Mask);
      }
  }
}

void transferDeadOperandMask(const BinaryOperator *BO, CallInst *T,
                             bool Swapped) {
  unsigned Mask = maskOf(BO);
  if (!Mask)
    return;
  if (Swapped)
    Mask = ((Mask & 1u) << 1) | ((Mask >> 1) & 1u);
  setDeadMask(T, Mask);
}

const char kMsgInPlaceQQStaleAdjoint[] =
    "cq in-place lowering: an adjoint reads a register after its in-place "
    "quantum reassignment";

namespace {

// Is `I` an adjoint of `G` on the same operands? The symbol is EmitInverse's
// (`inPlaceQQAdjointName`, the one spelling), never re-derived here.
bool isAdjointOf(const CallInst *I, const CallInst *G) {
  return I != G && isInPlaceQQGate(I) &&
         I->getArgOperand(0) == G->getArgOperand(0) &&
         I->getArgOperand(1) == G->getArgOperand(1) &&
         I->getCalledFunction()->getName() ==
             inPlaceQQAdjointName(G->getCalledFunction()->getName());
}

// The rails `X` WRITES, asked of the owners: a converted QQ gate writes its
// destination; a merge-stream permutation gate / an out-first `_unc` its
// `streamGateWrites` slots. Anything else (a forward producer minting a FRESH
// rail, a measurement, a controlled rotation of a user register) writes no
// compiler record of an older value.
void writtenRails(const CallInst *X, SmallVectorImpl<const Value *> &Out) {
  if (isInPlaceQQGate(X)) {
    Out.push_back(X->getArgOperand(1));
    return;
  }
  SmallVector<unsigned, 2> Slots;
  if (streamGateWrites(X, Slots))
    for (unsigned S : Slots)
      Out.push_back(X->getArgOperand(S));
}

}  // namespace

// THE POSTCONDITION AS A GATE SET (R11 round 1, finding A-F3/B-F1/C-F1, L3).
// Invariant: no gate after the in-place gate `G` reads `G`'s target `P` (or any
// alias of it — `handleAliases`, φ/select/cast routes and rail-bank cells) to
// write a COMPILER RECORD minted BEFORE `G` — the shape of every adjoint, strip
// and merge replay of a computation that read `P`'s OLD value — unless `G`'s own
// adjoint ran in between (the spine reversing a dead target's DAG). A record
// that is user data (a rotated register) is the program's entanglement and is not
// asked. Every reader kind is asked, not only the `_unc` suffix.
bool declineStaleInPlaceQQReads(Module &M, const TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    SmallVector<CallInst *, 4> Gates;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *G = dyn_cast<CallInst>(&I); G && isInPlaceQQGate(G))
          Gates.push_back(G);
    if (Gates.empty())
      continue;
    DominatorTree DT(F);
    for (CallInst *G : Gates) {
      Value *P = G->getArgOperand(1);
      SmallPtrSet<Value *, 8> Names;
      Names.insert(P);
      SmallPtrSet<Value *, 8> Alias;
      if (handleAliases(P, taint, DT, Alias))
        Names.insert(Alias.begin(), Alias.end());
      SmallVector<CallInst *, 4> Undo;
      for (User *U : P->users())
        if (auto *I = dyn_cast<CallInst>(U); I && isAdjointOf(I, G))
          Undo.push_back(I);
      for (Value *V : Names)
        for (User *U : V->users()) {
          auto *X = dyn_cast<CallInst>(U);
          if (!X || X == G || !provablyBefore(G, X, DT) ||
              isInPlaceGateOn(X, V))
            continue;  // not after G, or a gate ON the new value, not a reader.
          SmallVector<const Value *, 2> W;
          writtenRails(X, W);
          bool Stale = false;
          for (const Value *Rec : W) {
            const auto *RI = dyn_cast<Instruction>(Rec);
            if (Rec == V || !RI || !provablyBefore(RI, G, DT) ||
                railIsUserData(Rec))
              continue;
            Stale = true;
          }
          if (!Stale)
            continue;
          if (llvm::any_of(Undo, [&](CallInst *Inv) {
                return provablyBefore(G, Inv, DT) && provablyBefore(Inv, X, DT);
              }))
            continue;
          F.getContext().diagnose(DiagnosticInfoUnsupported(
              F, kMsgInPlaceQQStaleAdjoint, X->getDebugLoc()));
          return true;
        }
    }
  }
  return false;
}

unsigned deadOperandMask(const CallInst *T) { return maskOf(T); }

}  // namespace cq
