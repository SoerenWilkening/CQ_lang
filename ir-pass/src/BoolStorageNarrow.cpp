// BoolStorageNarrow.cpp — bd `test_C_libtooling-dm7f.53`. Read
// `BoolStorageNarrow.h` first: it carries the web conditions (W1)-(W4), the
// exactness argument and the taint discipline. This file is the predicate and
// the rewrite.

#include "BoolStorageNarrow.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

#include "ControlShape.h"  // blockOnCycle (W4) — the one spelling
#include "TaintPropagation.h"

using namespace llvm;

namespace cq {

namespace {

bool isBoolZext(const Value *V) {
  const auto *Z = dyn_cast<ZExtInst>(V);
  return Z && Z->getSrcTy()->isIntegerTy(1);
}

// `icmp ne %p, 0` / `icmp eq %p, 1` (either operand order): under (W1) it IS the
// low bit, so it is replaced by the narrowed φ itself (`if (t)` on a stored
// `_Bool`). Any other compare reads more than "is it 1" and blocks the web.
bool isLowBitTest(const Value *U, const Value *P) {
  const auto *C = dyn_cast<ICmpInst>(U);
  if (!C)
    return false;
  const Value *O = C->getOperand(0) == P ? C->getOperand(1) : C->getOperand(0);
  const auto *K = dyn_cast<ConstantInt>(O);
  if (!K || (C->getOperand(0) != P && C->getOperand(1) != P) || O == P)
    return false;
  return (C->getPredicate() == ICmpInst::ICMP_NE && K->isZero()) ||
         (C->getPredicate() == ICmpInst::ICMP_EQ && K->isOne());
}

// The web containing `Seed`: every same-typed φ reachable through φ→φ incoming
// and user edges. Deterministic (insertion-ordered).
void collectWeb(PHINode *Seed, SetVector<PHINode *> &Web) {
  SmallVector<PHINode *, 8> Work{Seed};
  Web.insert(Seed);
  while (!Work.empty()) {
    PHINode *P = Work.pop_back_val();
    auto Visit = [&](Value *V) {
      auto *Q = dyn_cast<PHINode>(V);
      if (Q && Q->getType() == Seed->getType() && Web.insert(Q))
        Work.push_back(Q);
    };
    for (Value *In : P->incoming_values())
      Visit(In);
    for (User *U : P->users())
      Visit(U);
  }
}

// (W1)-(W4). Pure analysis — nothing is mutated before every member passes.
bool webNarrowable(const SetVector<PHINode *> &Web, TaintSet &taint) {
  bool AnyTainted = false;
  for (PHINode *P : Web) {
    if (blockOnCycle(P->getParent()))
      return false;  // (W4)
    if (taint.Tainted.count(P))
      AnyTainted = true;
    for (Value *In : P->incoming_values()) {
      if (auto *Q = dyn_cast<PHINode>(In); Q && Web.count(Q))
        continue;
      if (isBoolZext(In))
        continue;
      if (auto *CI = dyn_cast<ConstantInt>(In); CI && CI->getValue().ule(1))
        continue;
      return false;  // (W1) — a value that may be outside {0,1}.
    }
    for (User *U : P->users()) {
      if (auto *Q = dyn_cast<PHINode>(U); Q && Web.count(Q))
        continue;
      if (auto *T = dyn_cast<TruncInst>(U); T && T->getDestTy()->isIntegerTy(1))
        continue;
      if (isa<ZExtInst>(U))
        continue;
      if (isLowBitTest(U, P))
        continue;
      return false;  // (W2) — a reader of more than bit 0.
    }
  }
  return AnyTainted;  // (W3)
}

void narrowWeb(const SetVector<PHINode *> &Web, TaintSet &taint,
               SmallVectorImpl<Value *> &Seeds) {
  LLVMContext &Ctx = Web.front()->getContext();
  Type *I1 = Type::getInt1Ty(Ctx);
  DenseMap<PHINode *, PHINode *> New;
  for (PHINode *P : Web) {
    PHINode *NP = PHINode::Create(I1, P->getNumIncomingValues(),
                                  P->getName() + ".b", P);
    NP->setDebugLoc(P->getDebugLoc());
    New[P] = NP;
    if (taint.Tainted.count(P)) {
      taint.Tainted.insert(NP);
      Seeds.push_back(NP);
    }
  }
  SmallSetVector<Instruction *, 8> Zexts;
  for (PHINode *P : Web) {
    PHINode *NP = New[P];
    for (unsigned i = 0, e = P->getNumIncomingValues(); i != e; ++i) {
      Value *In = P->getIncomingValue(i);
      Value *NV;
      if (auto *Q = dyn_cast<PHINode>(In); Q && Web.count(Q)) {
        NV = New[Q];
      } else if (isBoolZext(In)) {
        NV = cast<ZExtInst>(In)->getOperand(0);
        Zexts.insert(cast<Instruction>(In));
      } else {
        NV = ConstantInt::get(I1, cast<ConstantInt>(In)->getZExtValue());
      }
      NP->addIncoming(NV, P->getIncomingBlock(i));
    }
  }
  for (PHINode *P : Web) {
    PHINode *NP = New[P];
    for (User *U : make_early_inc_range(P->users())) {
      auto *UI = cast<Instruction>(U);
      if (isa<PHINode>(UI))
        continue;  // a member — erased below.
      Value *Repl = NP;
      if (auto *Z = dyn_cast<ZExtInst>(UI)) {
        auto *NZ = CastInst::Create(Instruction::ZExt, NP, Z->getDestTy(),
                                    Z->getName(), UI);
        NZ->setDebugLoc(Z->getDebugLoc());
        if (taint.Tainted.count(NP)) {
          taint.Tainted.insert(NZ);
          Seeds.push_back(NZ);
        }
        Repl = NZ;
      }
      UI->replaceAllUsesWith(Repl);
      taint.Tainted.erase(UI);
      UI->eraseFromParent();
    }
  }
  for (PHINode *P : Web)
    P->replaceAllUsesWith(PoisonValue::get(P->getType()));
  for (PHINode *P : Web) {
    taint.Tainted.erase(P);
    P->eraseFromParent();
  }
  for (Instruction *Z : Zexts)
    if (Z->use_empty()) {
      taint.Tainted.erase(Z);
      Z->eraseFromParent();
    }
}

}  // namespace

bool narrowBoolStoragePhis(Function &F, TaintSet &taint,
                           SmallVectorImpl<Value *> &Seeds) {
  SmallVector<SetVector<PHINode *>, 4> Webs;
  SmallPtrSet<PHINode *, 16> Seen;
  for (BasicBlock &BB : F)
    for (PHINode &P : BB.phis()) {
      auto *Ty = dyn_cast<IntegerType>(P.getType());
      if (!Ty || Ty->getBitWidth() < 2 || Seen.count(&P))
        continue;
      SetVector<PHINode *> Web;
      collectWeb(&P, Web);
      Seen.insert(Web.begin(), Web.end());
      if (webNarrowable(Web, taint))
        Webs.push_back(std::move(Web));
    }
  // Detect every web before rewriting any (Rule 9): webs are disjoint by
  // construction, so one rewrite cannot invalidate another's proof.
  for (const SetVector<PHINode *> &Web : Webs)
    narrowWeb(Web, taint, Seeds);
  return !Webs.empty();
}

}  // namespace cq
