// SpeculationSafety.cpp — dm7f.16.1 / p3kd.7.7.
// BennettVM's taken edges establish SSA semantics, not speculative totality.
// The fixed CQ script must be total on untaken arms, and every literal must
// have one SSA identity shared by the forward gates and their adjoints.
#include "SpeculationSafety.h"

#include "ArmClassify.h"
#include "LiteralIntegrity.h"
#include "PoisonFacts.h"
#include "PredMuxFlatten.h"
#include "TaintPropagation.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/KnownBits.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
namespace cq {
namespace {
constexpr char Mark[] = "cq.speculated";

bool scalar(Type *T) {
  return T->isIntegerTy() || T->isFloatingPointTy();
}

bool inertAttrs(AttributeSet AS) {
  for (Attribute A : AS) {
    if (!A.isEnumAttribute())
      return false;
    switch (A.getKindAsEnum()) {
    case Attribute::NoUndef:
    case Attribute::ZExt:
    case Attribute::SExt:
    case Attribute::InReg:
      break;
    default:
      return false;
    }
  }
  return true;
}

bool argAttrsAreInert(const CallBase *C, unsigned N) {
  const Function *F = C->getCalledFunction();
  return F && inertAttrs(C->getAttributes().getParamAttrs(N)) &&
         (N >= F->arg_size() || inertAttrs(F->getAttributes().getParamAttrs(N)));
}

bool returnAttrsHold(AttributeSet AS, const Function &F) {
  for (Attribute A : AS) {
    if (A.hasAttribute(Attribute::Range)) {
      for (const BasicBlock &BB : F)
        if (const auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
          if (!R->getReturnValue()->getType()->isIntegerTy() ||
              !A.getRange().contains(ConstantRange::fromKnownBits(
                  computeKnownBits(R->getReturnValue(),
                                   F.getParent()->getDataLayout(), 0, nullptr,
                                   nullptr, nullptr, /*UseInstrInfo=*/false),
                  /*IsSigned=*/false))) {
            if (::getenv("CQ_PREDMUX_DBG"))
              errs() << "CQ_PREDMUX_DBG: classical call return range unproven @"
                     << F.getName() << "\n";
            return false;
          }
    } else if (!inertAttrs(AttributeSet::get(F.getContext(), {A}))) {
      return false;
    }
  }
  return true;
}

bool basicCallContractHolds(const CallInst *C) {
  const Function *F = C ? C->getCalledFunction() : nullptr;
  if (!F || !scalar(C->getType()) || C->hasOperandBundles() ||
      C->hasPoisonGeneratingFlags() || C->hasPoisonGeneratingMetadata() ||
      C->getCallingConv() != F->getCallingConv() ||
      C->doesNotReturn() || C->isConvergent() || C->cannotDuplicate() ||
      C->isMustTailCall() || C->hasFnAttr(Attribute::ReturnsTwice))
    return false;
  return true;
}

bool callContractIsInert(const CallInst *C) {
  if (!basicCallContractHolds(C))
    return false;
  const Function *F = C->getCalledFunction();
  for (unsigned N = 0; N != C->arg_size(); ++N)
    if (!scalar(C->getArgOperand(N)->getType()) || !argAttrsAreInert(C, N))
      return false;
  return returnAttrsHold(C->getAttributes().getRetAttrs(), *F);
}

bool intrinsicContractHolds(const CallInst *C) {
  const Function *F = C->getCalledFunction();
  // A declaration has no return dataflow with which to prove a range. Keep
  // intrinsic semantics separate from exact-body proofs; no vacuous proof.
  if (C->hasPoisonGeneratingReturnAttributes() ||
      !inertAttrs(C->getAttributes().getRetAttrs()) ||
      !inertAttrs(F->getAttributes().getRetAttrs()))
    return false;
  for (unsigned N = 0; N != C->arg_size(); ++N) {
    if (!scalar(C->getArgOperand(N)->getType()))
      return false;
    for (AttributeSet AS : {C->getAttributes().getParamAttrs(N),
                            F->getAttributes().getParamAttrs(N)})
      for (Attribute A : AS)
        if (A.hasAttribute(Attribute::ImmArg)) {
          if (!isa<Constant>(C->getArgOperand(N)))
            return false;
        } else if (!inertAttrs(AttributeSet::get(F->getContext(), {A}))) {
          return false;
        }
  }
  return true;
}

bool totalCall(const CallInst *Root) {
  if (!callContractIsInert(Root) ||
      !isSpeculatableTotalCallee(Root->getCalledFunction()))
    return false;
  // The owning strict query already establishes an acyclic pure call graph.
  // Walk that graph once: repeated call edges must not multiply the work.
  SmallPtrSet<const Function *, 16> Seen;
  SmallVector<const Function *, 16> Work{Root->getCalledFunction()};
  while (!Work.empty()) {
    const Function *F = Work.pop_back_val();
    if (!Seen.insert(F).second)
      continue;
    if (!returnAttrsHold(F->getAttributes().getRetAttrs(), *F))
      return false;
    for (const Instruction &I : instructions(F)) {
      for (const Value *V : I.operands())
        if (const auto *K = dyn_cast<Constant>(V))
          if (!isa<Function>(K) && !isGuaranteedNotToBeUndefOrPoison(K))
            return false;
      if (I.isTerminator())
        continue;
      if (const auto *C = dyn_cast<CallInst>(&I)) {
        if (!basicCallContractHolds(C))
          return false;
        if (C->getCalledFunction()->isIntrinsic()) {
          if (!intrinsicContractHolds(C) || curatedIntrinsicCanBePoison(C) ||
              canCreateUndefOrPoison(cast<Operator>(C)))
            return false;
        } else {
          if (!callContractIsInert(C))
            return false;
          Work.push_back(C->getCalledFunction());
        }
      } else if (canCreateUndefOrPoison(cast<Operator>(&I))) {
        return false;
      }
    }
  }
  return true;
}

// No use/path assumptions: a hoisted noundef call must not certify its own
// formerly guarded poison argument. Visit each SSA dependency once.
bool definedWithoutContext(const Value *Root) {
  SmallPtrSet<const Value *, 16> Seen;
  SmallVector<const Value *, 16> Work{Root};
  while (!Work.empty()) {
    const Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    if (const auto *K = dyn_cast<Constant>(V)) {
      if (!isGuaranteedNotToBeUndefOrPoison(K))
        return false;
      continue;
    }
    if (const auto *A = dyn_cast<Argument>(V)) {
      if (!A->hasAttribute(Attribute::NoUndef))
        return false;
      continue;
    }
    if (isa<FreezeInst>(V))
      continue;
    const auto *I = dyn_cast<Instruction>(V);
    if (!I || isa<PHINode>(I) || isa<LoadInst>(I))
      return false;
    if (const auto *C = dyn_cast<CallInst>(I)) {
      if (!classicalCallCanBeSpeculated(C))
        return false;
    } else if (canCreateUndefOrPoison(cast<Operator>(I))) {
      return false;
    }
    for (const Value *Op : I->operands())
      if (!isa<Function>(Op))
        Work.push_back(Op);
  }
  return true;
}

bool needsStableUse(const Instruction &I) {
  for (const User *U : I.users())
    if (const auto *C = dyn_cast<CallInst>(U)) {
      if (isEmittedRuntimeCallee(C))
        return true;
      for (unsigned N = 0; N != C->arg_size(); ++N)
        if (C->getArgOperand(N) == &I &&
            C->paramHasAttr(N, Attribute::NoUndef))
          return true;
    }
  return false;
}

Value *stabilize(Value *V, const TaintSet &Taint, Function &F) {
  if (!scalar(V->getType()) || Taint.Tainted.count(V) ||
      definedWithoutContext(V))
    return V;
  Instruction *At = &*F.getEntryBlock().getFirstInsertionPt();
  if (auto *I = dyn_cast<Instruction>(V))
    At = isa<PHINode>(I) ? &*I->getParent()->getFirstInsertionPt()
                         : I->getNextNode();
  auto *Frozen = new FreezeInst(V, V->getName() + ".stable", At);
  if (const auto *I = dyn_cast<Instruction>(V))
    Frozen->setDebugLoc(I->getDebugLoc());
  // Constants are module-uniqued. Never replace another function's operand
  // with this function's SSA result (nor rewrite global/constant-expression
  // users). Local SSA definitions also use this narrow replacement.
  V->replaceUsesWithIf(Frozen, [&](Use &U) {
    const auto *I = dyn_cast<Instruction>(U.getUser());
    return I && I != Frozen && I->getFunction() == &F;
  });
  return Frozen;
}
} // namespace

// Same effective call-site/callee union as the original 9hea predicate.
// Total classical speculation additionally stabilizes parameters without
// noundef: their bodies may pass them onward to a constrained inner call.
bool freezeDischargesHoistedArg(const CallBase *C, unsigned N) {
  return C->paramHasAttr(N, Attribute::NoUndef) && argAttrsAreInert(C, N);
}

bool classicalCallCanBeSpeculated(const CallInst *Call) {
  return totalCall(Call);
}

void markSpeculatedValue(Instruction &Root) {
  // Include pre-existing entry/dominator producers: they can become new gate
  // literals even though only their quantum consumer moved. Arguments are
  // handled by the function-level mark after final taint is known.
  Root.getFunction()->setMetadata(Mark, MDNode::get(Root.getContext(), {}));
  SmallVector<Instruction *, 16> Work{&Root};
  while (!Work.empty()) {
    Instruction *I = Work.pop_back_val();
    if (!scalar(I->getType()) || I->getMetadata(Mark))
      continue;
    I->setMetadata(Mark, MDNode::get(I->getContext(), {}));
    for (Value *V : I->operands())
      if (auto *Op = dyn_cast<Instruction>(V))
        Work.push_back(Op);
  }
}

void stabilizeSpeculatedValues(Function &F, const TaintSet &Taint) {
  if (!F.getMetadata(Mark))
    return;
  F.setMetadata(Mark, nullptr);
  for (Argument &A : F.args())
    if (scalar(A.getType()))
      for (const User *U : A.users())
        if (const auto *C = dyn_cast<CallInst>(U); C && isEmittedRuntimeCallee(C)) {
          stabilize(&A, Taint, F);
          break;
        }
  SmallVector<Instruction *, 16> Sources;
  for (Instruction &I : instructions(F))
    if (I.getMetadata(Mark)) {
      I.setMetadata(Mark, nullptr);
      Sources.push_back(&I);
    }
  for (Instruction *I : Sources) {
    if (auto *C = dyn_cast<CallInst>(I))
      for (unsigned N = 0; N != C->arg_size(); ++N)
        if (classicalCallCanBeSpeculated(C) || freezeDischargesHoistedArg(C, N))
          C->setArgOperand(N, stabilize(C->getArgOperand(N), Taint, F));
    if (needsStableUse(*I))
      stabilize(I, Taint, F);
  }
}
} // namespace cq
