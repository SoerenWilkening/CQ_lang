// RegCondLeaf.cpp — see RegCondLeaf.h (bd test_C_libtooling-dm7f.77).

#include "RegCondLeaf.h"

#include "ArmAnalysis.h"       // condProvenance
#include "InPlaceQQ.h"         // qqOperandDeadAfter
#include "TaintPropagation.h"  // TaintSet

#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"

#include <optional>

using namespace llvm;

namespace cq {

namespace {

bool isCallTo(const Value *V, StringRef Prefix) {
  const auto *CI = dyn_cast<CallInst>(V);
  const Function *F = CI ? CI->getCalledFunction() : nullptr;
  return F && F->getName().starts_with(Prefix);
}

// Does `X` name a register that carries a rotation — the SSA-level reading of
// step 1's E2 (`railIsUserData`, asked after lowering)? A `cq_theta` result, or
// a φ / select / freeze routing one (the routers `railWireClosure` crosses).
// A compiler temporary (a template result: xor, compare, cast) is not.
bool rotatedRegister(Value *X, const TaintSet &Taint, unsigned Depth = 0) {
  if (Depth > 8 || !Taint.Tainted.count(X))
    return false;
  if (isCallTo(X, "cq_theta_"))
    return true;
  if (auto *P = dyn_cast<PHINode>(X)) {
    for (Value *In : P->incoming_values())
      if (rotatedRegister(In, Taint, Depth + 1))
        return true;
    return false;
  }
  if (auto *S = dyn_cast<SelectInst>(X))
    return rotatedRegister(S->getTrueValue(), Taint, Depth + 1) ||
           rotatedRegister(S->getFalseValue(), Taint, Depth + 1);
  if (auto *F = dyn_cast<FreezeInst>(X))
    return rotatedRegister(F->getOperand(0), Taint, Depth + 1);
  return false;
}

// Is `B` a QQ xor whose result-carrying operand `Idx` is dead after it?
bool deadQQOperand(BinaryOperator *B, unsigned Idx, const TaintSet &Taint,
                   const DominatorTree &DT, const LoopInfo &LI) {
  return B->getOpcode() == Instruction::Xor &&
         Taint.Tainted.count(B->getOperand(0)) &&
         Taint.Tainted.count(B->getOperand(1)) &&
         qqOperandDeadAfter(B->getOperand(Idx), B, DT, LI);
}

// Does `V` survive past its own reads as a control — step 1's E3 (`survives`,
// asked after lowering) on the IR detection sees? A reader that keeps the value:
// a measurement, a rotation of it, a return / store / φ / select data use, an
// opaque call, or the DEAD operand of a later QQ xor whose result survives.
// Conservative toward "yes": a wrong yes only reads the register (sound either
// way, see the header); a wrong no keeps today's decomposition and its loud fence.
bool survivesPastControl(Value *V, const TaintSet &Taint, const DominatorTree &DT,
                         const LoopInfo &LI, unsigned Depth = 0) {
  if (Depth > 16)
    return true;
  for (User *U : V->users()) {
    if (isa<BranchInst>(U))
      continue;  // the control read itself.
    if (auto *S = dyn_cast<SelectInst>(U); S && S->getCondition() == V &&
                                           S->getTrueValue() != V &&
                                           S->getFalseValue() != V)
      continue;  // a 4.4 select CONDITION read: a control read too.
    if (auto *B = dyn_cast<BinaryOperator>(U)) {
      for (unsigned Idx = 0; Idx < 2; ++Idx)
        if (B->getOperand(Idx) == V && deadQQOperand(B, Idx, Taint, DT, LI) &&
            survivesPastControl(B, Taint, DT, LI, Depth + 1))
          return true;
      continue;  // another pure reader: a temporary the spine discharges.
    }
    if (isa<CmpInst>(U) || isa<CastInst>(U))
      continue;  // pure readers minting their own rails.
    return true;  // measure, theta, ret, store, φ, data select, opaque call.
  }
  return false;
}

void setTag(Instruction *I, unsigned Idx) {
  LLVMContext &Ctx = I->getContext();
  I->setMetadata(kRegCondTag,
                 MDNode::get(Ctx, ConstantAsMetadata::get(ConstantInt::get(
                                      Type::getInt32Ty(Ctx), Idx))));
}

// Is `V` (or a tainted i1 and/or/xor below it) a logical NOT `xor X, true` of
// a tainted `X`? No condition network decomposes one (`collectCondTree`: "the
// logical NOT stays declined"), and `-O1` makes them from plain C
// (`b ^= a; if (a & b)` is `a & !b`; `q3 = !q2` from a classical `1 ^ q2`).
bool treeHasNot(Value *V, const TaintSet &Taint, unsigned Depth = 0) {
  auto *B = dyn_cast<BinaryOperator>(V);
  if (!B || Depth > 16 || !B->getType()->isIntegerTy(1) ||
      !Taint.Tainted.count(B))
    return false;
  const auto Op = B->getOpcode();
  if (Op != Instruction::And && Op != Instruction::Or && Op != Instruction::Xor)
    return false;
  for (unsigned Idx = 0; Idx < 2; ++Idx)
    if (auto *K = dyn_cast<ConstantInt>(B->getOperand(Idx));
        K && K->isOne() && Op == Instruction::Xor)
      return true;
  return treeHasNot(B->getOperand(0), Taint, Depth + 1) ||
         treeHasNot(B->getOperand(1), Taint, Depth + 1);
}

// The commit predicate for one condition value (see the header).
void considerCondition(Value *C, const TaintSet &Taint, const DominatorTree &DT,
                       const LoopInfo &LI) {
  auto *B = dyn_cast<BinaryOperator>(C);
  if (!B || !B->getType()->isIntegerTy(1) || !Taint.Tainted.count(B))
    return;
  SmallVector<unsigned, 2> Targets;
  for (unsigned Idx = 0; Idx < 2; ++Idx)
    if (deadQQOperand(B, Idx, Taint, DT, LI) &&
        rotatedRegister(B->getOperand(Idx), Taint))
      Targets.push_back(Idx);
  // Both operands dead registers: the late round fails loudly (both-dead ruling);
  // leave the decomposition, which that fence refuses on its own.
  if (Targets.size() > 1)
    return;
  // A condition that dies at its control read and decomposes is left to the
  // network (every shipped tree accept, byte-unchanged) — unless its tree holds
  // a logical NOT, which no network decomposes: then its own out-of-place
  // register is the condition (Bennett.jl @824458d src/lowering/driver.jl:
  // 408-420, a branch condition is ONE resolved wire; arith.jl:348-384 lowers
  // and/or/xor i1 onto a fresh wire), and the spine owns that rail afterwards.
  if (!survivesPastControl(B, Taint, DT, LI) && !treeHasNot(B, Taint))
    return;
  // No dead target (design D5): the xor stays OUT OF PLACE, its fresh rail is
  // the entangling copy the program keeps, and that rail is the condition.
  setTag(B, Targets.empty() ? kRegCondFresh : Targets.front());
}

// A committed in-place condition `V` (a target tag) is SUNK to just before its
// branch when nothing else in its block reads it. Legal: `V` is pure, reads only
// values defined before its old position, and its target is dead after it (the
// commit's own predicate), so nothing between the two positions reads either.
// Why: the in-place gate then runs at the control read, AFTER every independent
// pure reader `-O1` (or the 57ch placement, which puts a stale read "just before
// the gate") scheduled between them — measured on dicke.c, where `q3 ^= q1`
// placed after `q2 ^= q1` left q3's record of the OLD q2 to be discharged after
// q2 was overwritten, and the late round's G7 then refused the conversion.
void sinkCommittedCondition(BranchInst *Br) {
  auto *V = dyn_cast<Instruction>(Br->getCondition());
  if (!V || !regCondTarget(V) || V->getParent() != Br->getParent())
    return;
  for (User *U : V->users())
    if (auto *UI = dyn_cast<Instruction>(U);
        UI && UI != Br && UI->getParent() == V->getParent())
      return;
  // Cross only non-call instructions: a gate (`cq_theta`), a measurement or any
  // call between the two positions may move or collapse an operand's register,
  // and `V` would then read it after that event instead of before.
  for (Instruction *I = V->getNextNode(); I && I != Br; I = I->getNextNode())
    if (isa<CallBase>(I) || I->mayHaveSideEffects())
      return;
  V->moveBefore(Br);
}

// Does an arm of `Br` (a successor whose only predecessor is `Br`'s block)
// rotate the register `C` names — a `cq_theta_*` with arg 0 == `C`?
bool armRotates(BranchInst *Br, Value *C) {
  for (BasicBlock *S : successors(Br)) {
    if (S->getSinglePredecessor() != Br->getParent())
      continue;
    for (Instruction &I : *S)
      if (auto *CI = dyn_cast<CallInst>(&I);
          CI && isCallTo(CI, "cq_theta_") && CI->arg_size() >= 1 &&
          CI->getArgOperand(0) == C)
        return true;
  }
  return false;
}

// DESIGN D4 CASE 2 (owner-approved dm7f.51 design; delegated Q7 ruling for the
// kept-copy class). `br i1 %c` whose arm rotates `%c` itself — dicke.c's
// `q3 ^= q2; if (q3) cq_theta(&q2, θ)` with `q3 = 1 ^ q2` folds to exactly this,
// the guard being `!q2` — cannot read `%c` as its own control (the control would
// sit on the gate's target). When the program ALREADY computes the negation
// `%g = xor i1 %c, true` at a point dominating the branch, `%g` is that guard on
// a rail of its own (the out-of-place `_hl` xor: `%c` is read again by the arm,
// so no in-place form applies), so the branch is rewritten to `br i1 %g` with the
// successors swapped — the identity on values — and `%g` is tagged a register
// condition with no target. Nothing is minted; `%g` is the program's register.
// A program with no such value keeps today's loud decline (design D4 case 1, the
// kept copy flag, is not built here).
void substituteNegatedGuard(BranchInst *Br, const TaintSet &Taint,
                            const DominatorTree &DT) {
  Value *C = Br->getCondition();
  if (!Taint.Tainted.count(C) || !C->getType()->isIntegerTy(1) ||
      !armRotates(Br, C))
    return;
  for (User *U : C->users()) {
    auto *G = dyn_cast<BinaryOperator>(U);
    if (!G || G->getOpcode() != Instruction::Xor || !Taint.Tainted.count(G))
      continue;
    Value *Other = G->getOperand(0) == C ? G->getOperand(1) : G->getOperand(0);
    auto *K = dyn_cast<ConstantInt>(Other);
    if (!K || !K->isOne() || !DT.dominates(G, Br))
      continue;
    Br->setCondition(G);
    Br->swapSuccessors();
    setTag(G, kRegCondFresh);
    return;
  }
}

}  // namespace

bool isRegCondLeaf(const Value *V) {
  const auto *I = dyn_cast_or_null<Instruction>(V);
  return I && I->getType()->isIntegerTy(1) && I->getMetadata(kRegCondTag);
}

Value *regCondTarget(const Value *V) {
  if (!isRegCondLeaf(V))
    return nullptr;
  const auto *I = cast<Instruction>(V);
  MDNode *MD = I->getMetadata(kRegCondTag);
  if (MD->getNumOperands() != 1)
    return nullptr;
  auto *K = mdconst::dyn_extract<ConstantInt>(MD->getOperand(0));
  if (!K || K->getZExtValue() == kRegCondFresh ||
      K->getZExtValue() >= I->getNumOperands())
    return nullptr;
  return I->getOperand(K->getZExtValue());
}

void transferRegCondTag(const Instruction *From, Instruction *To, bool Swapped) {
  MDNode *MD = From->getMetadata(kRegCondTag);
  if (!MD)
    return;
  auto *K = MD->getNumOperands() == 1
                ? mdconst::dyn_extract<ConstantInt>(MD->getOperand(0))
                : nullptr;
  if (!K)
    return;
  unsigned Idx = K->getZExtValue();
  if (Swapped && Idx < 2)
    Idx = 1 - Idx;
  setTag(To, Idx);
}

int regCondTagIndex(const Instruction *I) {
  MDNode *MD = I ? I->getMetadata(kRegCondTag) : nullptr;
  auto *K = MD && MD->getNumOperands() == 1
                ? mdconst::dyn_extract<ConstantInt>(MD->getOperand(0))
                : nullptr;
  return K ? static_cast<int>(K->getZExtValue()) : -1;
}

void regCondProvenance(Value *V, TaintSet &Taint, SmallPtrSetImpl<Value *> &Out) {
  if (Taint.Tainted.count(V))
    Out.insert(V);
  if (Value *T = regCondTarget(V))
    condProvenance(T, Taint, Out);
}

void commitRegisterConditions(Module &M, TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Tags are only ADDED: a round-1 tag must survive round 2's call, because the
    // flattened region's value is no longer a branch condition there, and the
    // post-fixpoint re-ask (`reverifyRailCondReads`) reads the tag (L1).
    std::optional<DominatorTree> DT;
    std::optional<LoopInfo> LI;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        Value *C = nullptr;
        if (auto *Br = dyn_cast<BranchInst>(&I); Br && Br->isConditional())
          C = Br->getCondition();
        else if (auto *S = dyn_cast<SelectInst>(&I))
          C = S->getCondition();
        if (!C || !taint.Tainted.count(C))
          continue;
        if (!DT) {
          DT.emplace(F);
          LI.emplace(*DT);
        }
        if (auto *Br = dyn_cast<BranchInst>(&I)) {
          substituteNegatedGuard(Br, taint, *DT);  // edits no edge: DT stays valid.
          C = Br->getCondition();
          if (isRegCondLeaf(C))
            continue;
        }
        considerCondition(C, taint, *DT, *LI);
        if (auto *Br = dyn_cast<BranchInst>(&I))
          sinkCommittedCondition(Br);
      }
  }
}

}  // namespace cq
