// CallContract.cpp — bd bwfp: see CallContract.h. Split out of
// SpeculationSafety.cpp in review round 3 (2026-10-08), carrying that round's
// fixes: return attributes as poison sources, the constant-range proof, the
// fixpoint, a branch on poison as UB, and a verified `returned` (round 4).
#include "CallContract.h"

#include "ArmClassify.h"  // freezeDischargesHoistedArg (declared there, bd 9hea)
#include "PoisonFacts.h"  // curatedIntrinsicCanBePoison
#include "SpeculationSafety.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/KnownBits.h"
#include "llvm/Support/raw_ostream.h"

#include <cstdlib>
#include <optional>
#include <utility>

using namespace llvm;
namespace cq {
bool speculationScalar(Type *T) {
  return T->isIntegerTy() || T->isFloatingPointTy();
}

namespace {
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

// `returned` on parameter `N` holds when every `ret` of `F` returns that
// parameter itself. It is NOT inert: `computeKnownBits` (so `rangeProven`) and
// the caller's optimizer read the call as that argument, so a false one proves
// a false range (review round 4 F1).
bool returnsParam(const Function &F, unsigned N) {
  if (F.isDeclaration() || N >= F.arg_size())
    return false;
  for (const BasicBlock &BB : F)
    if (const auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
      if (R->getReturnValue() != F.getArg(N))
        return false;
  return true;
}

// The one per-argument contract question: does every attribute on argument `N`
// (call site and callee) hold for any defined value? `AllowImmArg` admits an
// intrinsic's `immarg` on a constant (a frozen value can never feed one).
bool paramAttrsHold(const CallBase *C, unsigned N, bool AllowImmArg) {
  const Function *F = C->getCalledFunction();
  if (!F)
    return false;
  for (AttributeSet AS : {C->getAttributes().getParamAttrs(N),
                          N < F->arg_size() ? F->getAttributes().getParamAttrs(N)
                                            : AttributeSet()})
    for (Attribute A : AS) {
      if (A.hasAttribute(Attribute::ImmArg)) {
        if (!AllowImmArg || !isa<Constant>(C->getArgOperand(N)))
          return false;
      } else if (A.hasAttribute(Attribute::Returned)) {
        if (!returnsParam(*F, N))
          return false;
      } else if (!inertAttrs(AttributeSet::get(F->getContext(), {A}))) {
        return false;
      }
    }
  return true;
}

bool argAttrsAreInert(const CallBase *C, unsigned N) {
  return paramAttrsHold(C, N, /*AllowImmArg=*/false);
}

// Does the returned value `V` lie in `R` whenever it is not poison? Poison is the
// dataflow's question (`poisonFlow`). LLVM's own range and known-bits facts, in
// both signednesses, without the instruction flags a violation would make poison
// (review round 3: clang -O1 stamps `range(i32 1, 3)` on `x > 0 ? 1 : 2`).
bool rangeProven(const ConstantRange &R, const Value *V, const DataLayout &DL) {
  if (!V || !V->getType()->isIntegerTy())
    return false;
  const KnownBits KB = computeKnownBits(V, DL, 0, nullptr, nullptr, nullptr,
                                        /*UseInstrInfo=*/false);
  for (bool Signed : {false, true})
    if (R.contains(computeConstantRange(V, Signed, /*UseInstrInfo=*/false)
                       .intersectWith(ConstantRange::fromKnownBits(KB, Signed),
                                      Signed ? ConstantRange::Signed
                                             : ConstantRange::Unsigned)))
      return true;
  return false;
}
} // namespace

// Every value-constraining return attribute in `AS` holds for `F`'s body: a
// `range` is proven from each `ret`, anything else beyond the inert set refuses.
// A declaration proves no range (it has no `ret` to read; no vacuous proof).
bool returnAttrsHold(AttributeSet AS, const Function &F) {
  for (Attribute A : AS) {
    if (A.hasAttribute(Attribute::Range)) {
      if (F.isDeclaration())
        return false;
      for (const BasicBlock &BB : F)
        if (const auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
          if (!rangeProven(A.getRange(), R->getReturnValue(),
                           F.getParent()->getDataLayout())) {
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
  return callExecutionIsDefined(C) && speculationScalar(C->getType()) &&
         !C->hasPoisonGeneratingFlags() && !C->hasPoisonGeneratingMetadata();
}

namespace {
// A call's parameter contract a defined value cannot violate: the inert
// attributes, a verified `returned`, plus an intrinsic's `immarg` on a constant
// (as `intrinsicContractHolds` admits it).
bool paramContractIsInert(const CallInst *C, unsigned N) {
  return paramAttrsHold(C, N, /*AllowImmArg=*/true);
}

// The result range an intrinsic's semantics give from its operand's known bits,
// for the ids LLVM 19's InstCombine stamps a call-site `range` on (`ctpop`,
// `ctlz`, `cttz`; review round 4). A zero-is-poison flag is the dataflow's
// poison (`canCreateUndefOrPoison`), never a range fact.
std::optional<ConstantRange> intrinsicResultRange(const CallInst &C) {
  const Function *F = C.getCalledFunction();
  if (!F || !C.getType()->isIntegerTy() || C.arg_size() == 0)
    return std::nullopt;
  const KnownBits K = computeKnownBits(
      C.getArgOperand(0), C.getModule()->getDataLayout(), 0, nullptr, nullptr,
      nullptr, /*UseInstrInfo=*/false);
  unsigned Lo, Hi;
  switch (F->getIntrinsicID()) {
  case Intrinsic::ctpop:
    Lo = K.countMinPopulation();
    Hi = K.countMaxPopulation();
    break;
  case Intrinsic::ctlz:
    Lo = K.countMinLeadingZeros();
    Hi = K.countMaxLeadingZeros();
    break;
  case Intrinsic::cttz:
    Lo = K.countMinTrailingZeros();
    Hi = K.countMaxTrailingZeros();
    break;
  default:
    return std::nullopt;
  }
  const unsigned BW = C.getType()->getIntegerBitWidth();
  return ConstantRange::getNonEmpty(APInt(BW, Lo), APInt(BW, Hi + 1));
}

// The call site's own return contract: a `range` proven from the callee's body,
// or for an intrinsic from its semantics (`intrinsicResultRange`); otherwise
// only the inert set. An intrinsic DECLARATION's own attributes are LLVM's
// semantics (the IR parser replaces user-written ones), so they are not asked.
bool callSiteReturnHolds(const CallInst &C) {
  const Function *F = C.getCalledFunction();
  if (!F)
    return false;
  const AttributeSet AS = C.getAttributes().getRetAttrs();
  if (!F->isIntrinsic())
    return returnAttrsHold(AS, *F);
  for (Attribute A : AS)
    if (A.hasAttribute(Attribute::Range)) {
      const std::optional<ConstantRange> R = intrinsicResultRange(C);
      if (!R || !A.getRange().contains(*R))
        return false;
    } else if (!inertAttrs(AttributeSet::get(F->getContext(), {A}))) {
      return false;
    }
  return true;
}

// bd bwfp — does POISON reach a `noundef` SINK when `F` runs with the
// parameters in `PoisonParams` possibly poison? A sink is a `noundef` return
// (the function's or a call site's) or an inner call's `noundef` parameter:
// poison there is immediate UB. Every other poison is tolerated, which is the
// 6.5 owner's own argument (a poison RESULT is never merged on a shielded state;
// control_classical_call_arm_accept_poisonselect_callee.ll). Also refused, as
// UB at the call: an inner call whose calling convention differs from its
// callee's, and a value-constraining parameter attribute (`range`, `nonnull`,
// ...) that a defined value may violate. Poison SOURCES include an unproven
// value-constraining return attribute (`range`, `nofpclass`, ...) on any callee
// or call site in the tree (review round 3 F1). The strict body walk owns
// memory, control and division; a `speculatable` body (the caller's other
// admission) may branch and loop, so the scan runs to a fixpoint and a branch on
// poison is UB. Union propagation is monotone, so a set of poison parameters
// causes UB iff one of them does.
struct PoisonFlow {
  bool UB = false;
  bool RetMayPoison = false;
};
using PoisonMemo = DenseMap<std::pair<const Function *, uint64_t>, PoisonFlow>;

PoisonFlow poisonFlow(const Function &F, uint64_t PoisonParams, PoisonMemo &Memo,
                      SmallPtrSetImpl<const Function *> &OnStack) {
  if (auto It = Memo.find({&F, PoisonParams}); It != Memo.end())
    return It->second;
  PoisonFlow V;
  if (F.isDeclaration()) {
    // A bodyless callee the caller admitted as speculatable: its result is
    // poison whenever an argument is; its own `noundef` return is a sink.
    V.RetMayPoison = true;
    V.UB = PoisonParams && F.hasRetAttribute(Attribute::NoUndef);
    return V;
  }
  if (!OnStack.insert(&F).second) {
    V.UB = true;  // a cycle: the strict walk refuses it; never prove through one
    return V;
  }
  SmallPtrSet<const Value *, 32> May;
  for (const Argument &A : F.args())
    if (A.getArgNo() < 64 && ((PoisonParams >> A.getArgNo()) & 1))
      May.insert(&A);
  auto may = [&](const Value *Op) {
    if (const auto *K = dyn_cast<Constant>(Op))
      return !isa<Function>(K) && !isGuaranteedNotToBeUndefOrPoison(K);
    return May.count(Op) != 0;
  };
  bool Grew = true;
  while (Grew) {
    Grew = false;
    for (const BasicBlock *BB : ReversePostOrderTraversal<const Function *>(&F))
      for (const Instruction &I : *BB) {
        if (const auto *R = dyn_cast<ReturnInst>(&I)) {
          if (const Value *RV = R->getReturnValue(); RV && may(RV)) {
            V.RetMayPoison = true;
            if (F.hasRetAttribute(Attribute::NoUndef))
              V.UB = true;
          }
          continue;
        }
        if (const auto *Br = dyn_cast<BranchInst>(&I)) {
          if (Br->isConditional() && may(Br->getCondition()))
            V.UB = true;
          continue;
        }
        if (const auto *Sw = dyn_cast<SwitchInst>(&I)) {
          if (may(Sw->getCondition()))
            V.UB = true;
          continue;
        }
        if (I.isTerminator() || isa<FreezeInst>(I))
          continue;
        bool P;
        if (const auto *C = dyn_cast<CallInst>(&I)) {
          if (!callExecutionIsDefined(C))
            V.UB = true;
          uint64_t Mask = 0;
          for (unsigned N = 0; N != C->arg_size(); ++N) {
            if (!paramContractIsInert(C, N))
              V.UB = true;
            if (!may(C->getArgOperand(N)))
              continue;
            if (N >= 64 || C->paramHasAttr(N, Attribute::NoUndef))
              V.UB = true;  // past the mask: never analysed as defined
            else
              Mask |= uint64_t(1) << N;
          }
          const Function *Callee = C->getCalledFunction();
          if (Callee && !Callee->isIntrinsic()) {
            const PoisonFlow S = poisonFlow(*Callee, Mask, Memo, OnStack);
            V.UB |= S.UB;
            P = S.RetMayPoison;
          } else {
            // The intrinsic's own semantics only: its flags, metadata and
            // call-site return attributes are asked just below, where a
            // `range` LLVM's semantics imply is proven (`callSiteReturnHolds`).
            // LLVM answers "no poison" for a `noundef` ctlz/cttz/abs whatever
            // its poison flag (it counts that as UB instead), so the flag is
            // asked of its owner too, as `totalCall` does (review round 5 F1).
            P = Mask != 0 ||
                canCreateUndefOrPoison(cast<Operator>(C),
                                       /*ConsiderFlagsAndMetadata=*/false) ||
                curatedIntrinsicCanBePoison(C);
          }
          // The call site's own return contract (a callee body's own
          // attributes are that body's question, above).
          P = P || C->hasPoisonGeneratingFlags() ||
              C->hasPoisonGeneratingMetadata() || !callSiteReturnHolds(*C);
          if (P && C->hasRetAttr(Attribute::NoUndef))
            V.UB = true;
        } else {
          P = canCreateUndefOrPoison(cast<Operator>(&I)) ||
              any_of(I.operands(), may);
        }
        if (P && May.insert(&I).second)
          Grew = true;
      }
  }
  // An unproven value constraint on `F`'s own return (`range`, `nofpclass`) makes
  // the result poison where it fails, and UB under `noundef`.
  if (!returnAttrsHold(F.getAttributes().getRetAttrs(), F)) {
    V.RetMayPoison = true;
    if (F.hasRetAttribute(Attribute::NoUndef))
      V.UB = true;
  }
  OnStack.erase(&F);
  Memo[{&F, PoisonParams}] = V;
  return V;
}

bool hoistUBWithPoisonArgs(const CallInst *Call, uint64_t PoisonArgs) {
  const Function *F = Call->getCalledFunction();
  if (!F)
    return true;
  PoisonMemo Memo;
  SmallPtrSet<const Function *, 8> OnStack;
  const PoisonFlow V = poisonFlow(*F, PoisonArgs, Memo, OnStack);
  // The hoisted call's own `noundef` return (call site or callee) is a sink too,
  // and an unproven value constraint on the call site's return is a source.
  const bool RetPoison = V.RetMayPoison || !callSiteReturnHolds(*Call);
  return V.UB || (RetPoison && Call->hasRetAttr(Attribute::NoUndef));
}
} // namespace

bool callContractIsInert(const CallInst *C) {
  if (!basicCallContractHolds(C))
    return false;
  const Function *F = C->getCalledFunction();
  for (unsigned N = 0; N != C->arg_size(); ++N)
    if (!speculationScalar(C->getArgOperand(N)->getType()) || !argAttrsAreInert(C, N))
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
    if (!speculationScalar(C->getArgOperand(N)->getType()))
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

bool callExecutionIsDefined(const CallInst *C) {
  const Function *F = C ? C->getCalledFunction() : nullptr;
  return F && !C->hasOperandBundles() &&
         C->getCallingConv() == F->getCallingConv() && !C->doesNotReturn() &&
         !C->isConvergent() && !C->cannotDuplicate() && !C->isMustTailCall() &&
         !C->hasFnAttr(Attribute::ReturnsTwice);
}

bool hoistedArgPoisonIsUB(const CallBase *C, unsigned N) {
  if (C->paramHasAttr(N, Attribute::NoUndef))
    return true;
  const auto *CI = dyn_cast<CallInst>(C);
  return !CI || N >= 64 || hoistUBWithPoisonArgs(CI, uint64_t(1) << N);
}

// Same effective call-site/callee union as the original 9hea predicate.
// Total classical speculation additionally stabilizes parameters without
// noundef: their bodies may pass them onward to a constrained inner call.
bool freezeDischargesHoistedArg(const CallBase *C, unsigned N) {
  return hoistedArgPoisonIsUB(C, N) && argAttrsAreInert(C, N);
}

bool hoistedCallTreeIsUBFree(const CallInst *Call) {
  if (!callExecutionIsDefined(Call))
    return false;
  // A value-constraining attribute on the hoisted call's own parameter (`range`,
  // `nonnull`, ... with `noundef`) is UB for a DEFINED argument the source's
  // guard kept out of its domain (review round 2 F2), so only inert ones pass:
  // the same contract an inner call must meet (review round 3 F3).
  for (unsigned N = 0; N != Call->arg_size(); ++N)
    if (!paramContractIsInert(Call, N))
      return false;
  // Every argument whose poison would be UB is frozen (`hoistedArgPoisonIsUB`);
  // the rest may stay poison without UB by construction, so the body must be
  // UB-free with all arguments defined.
  return !hoistUBWithPoisonArgs(Call, 0);
}
} // namespace cq
