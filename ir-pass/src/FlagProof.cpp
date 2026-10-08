// FlagProof.cpp — bd dm7f.21: see FlagProof.h. Every proof below asks about an
// OPERAND of the flagged instruction, never about the instruction itself.
#include "FlagProof.h"

#include "PoisonFacts.h"  // curatedIntrinsicCanBePoison

#include "llvm/Analysis/SimplifyQuery.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/KnownBits.h"

#include <optional>

using namespace llvm;

namespace cq {
namespace {

// No context instruction, dominator tree or assumption cache: a fact that holds
// only under the source's guard must not prove a flag on a speculated path.
SimplifyQuery flagFreeQuery(const Instruction &I) {
  return SimplifyQuery(I.getModule()->getDataLayout(),
                       static_cast<const DominatorTree *>(nullptr),
                       /*AC=*/nullptr, /*CxtI=*/nullptr,
                       /*UseInstrInfo=*/false);
}

KnownBits operandBits(const Value *V, const SimplifyQuery &SQ) {
  return computeKnownBits(V, /*Depth=*/0, SQ);
}

unsigned signBits(const Value *V, const SimplifyQuery &SQ) {
  return ComputeNumSignBits(V, SQ.DL, /*Depth=*/0, /*AC=*/nullptr,
                            /*CxtI=*/nullptr, /*DT=*/nullptr,
                            /*UseInstrInfo=*/false);
}

// The largest shift amount `Amt` can take, when it is below the width (a larger
// one is inherent poison, `canCreateUndefOrPoison`'s question).
std::optional<unsigned> maxShift(const Value *Amt, unsigned BW,
                                 const SimplifyQuery &SQ) {
  const APInt Max = operandBits(Amt, SQ).getMaxValue();
  if (Max.uge(BW))
    return std::nullopt;
  return unsigned(Max.getZExtValue());
}

bool neverOverflows(OverflowResult R) {
  return R == OverflowResult::NeverOverflows;
}

// Is the unsigned (`Signed=false`) or signed wrap flag of `I` implied by its
// operands? Shifts and truncations count the bits that leave the value.
bool wrapProven(const Instruction &I, bool Signed, const SimplifyQuery &SQ) {
  const Value *A = I.getOperand(0);
  if (const auto *T = dyn_cast<TruncInst>(&I)) {
    const unsigned Lost = T->getSrcTy()->getScalarSizeInBits() -
                          T->getDestTy()->getScalarSizeInBits();
    return Signed ? signBits(A, SQ) > Lost
                  : operandBits(A, SQ).countMinLeadingZeros() >= Lost;
  }
  const Value *B = I.getOperand(1);
  switch (I.getOpcode()) {
  case Instruction::Add:
    return neverOverflows(Signed ? computeOverflowForSignedAdd(A, B, SQ)
                                 : computeOverflowForUnsignedAdd(A, B, SQ));
  case Instruction::Sub:
    return neverOverflows(Signed ? computeOverflowForSignedSub(A, B, SQ)
                                 : computeOverflowForUnsignedSub(A, B, SQ));
  case Instruction::Mul:
    // `IsNSW=false`: the instruction's own `nsw` is exactly what is unproven.
    return neverOverflows(Signed ? computeOverflowForSignedMul(A, B, SQ)
                                 : computeOverflowForUnsignedMul(
                                       A, B, SQ, /*IsNSW=*/false));
  case Instruction::Shl: {
    const std::optional<unsigned> S =
        maxShift(B, I.getType()->getScalarSizeInBits(), SQ);
    if (!S)
      return false;
    return Signed ? signBits(A, SQ) > *S
                  : operandBits(A, SQ).countMinLeadingZeros() >= *S;
  }
  default:
    return false;
  }
}

// `exact` on a right shift: no set bit is shifted out.
bool exactProven(const Instruction &I, const SimplifyQuery &SQ) {
  if (I.getOpcode() != Instruction::LShr && I.getOpcode() != Instruction::AShr)
    return false;
  const std::optional<unsigned> S =
      maxShift(I.getOperand(1), I.getType()->getScalarSizeInBits(), SQ);
  return S && operandBits(I.getOperand(0), SQ).countMinTrailingZeros() >= *S;
}

// LLVM answers "no poison" for a NOUNDEF call to an intrinsic it does not list
// (it counts that as UB). Ask it about the call site without that `noundef`.
bool intrinsicSemanticsCanPoison(const CallInst &C) {
  if (C.getCalledFunction()->hasRetAttribute(Attribute::NoUndef))
    return true;  // a declaration's contract the call cannot shed
  if (!C.getAttributes().hasRetAttr(Attribute::NoUndef))
    return canCreateUndefOrPoison(cast<Operator>(&C),
                                  /*ConsiderFlagsAndMetadata=*/false);
  auto *Probe = cast<CallInst>(C.clone());
  Probe->removeRetAttr(Attribute::NoUndef);
  const bool R = canCreateUndefOrPoison(cast<Operator>(Probe),
                                        /*ConsiderFlagsAndMetadata=*/false);
  Probe->deleteValue();
  return R;
}
}  // namespace

bool poisonFlagsProven(const Instruction &I) {
  if (!I.hasPoisonGeneratingFlags())
    return true;
  if (isa<CallBase>(I))
    return false;  // fast-math flags on a call
  const SimplifyQuery SQ = flagFreeQuery(I);
  // Clear each flag proven from the operands on a detached clone, then let
  // LLVM say whether any poison-generating flag remains: a flag this file does
  // not know (fast-math, gep, `udiv exact`) stays and refuses.
  Instruction *Probe = I.clone();
  if (isa<OverflowingBinaryOperator>(I) || isa<TruncInst>(I)) {
    if (I.hasNoUnsignedWrap() && wrapProven(I, /*Signed=*/false, SQ))
      Probe->setHasNoUnsignedWrap(false);
    if (I.hasNoSignedWrap() && wrapProven(I, /*Signed=*/true, SQ))
      Probe->setHasNoSignedWrap(false);
  }
  if (isa<PossiblyExactOperator>(I) && I.isExact() && exactProven(I, SQ))
    Probe->setIsExact(false);
  if (isa<PossiblyNonNegInst>(I) && I.hasNonNeg() &&
      isKnownNonNegative(I.getOperand(0), SQ))
    Probe->setNonNeg(false);
  if (const auto *D = dyn_cast<PossiblyDisjointInst>(&I);
      D && D->isDisjoint() &&
      haveNoCommonBitsSet(I.getOperand(0), I.getOperand(1), SQ))
    cast<PossiblyDisjointInst>(Probe)->setIsDisjoint(false);
  const bool Remaining = Probe->hasPoisonGeneratingFlags();
  Probe->deleteValue();
  return !Remaining;
}

bool createsPoison(const Instruction &I, bool AllowProofs) {
  if (const auto *C = dyn_cast<CallInst>(&I)) {
    const Function *F = C->getCalledFunction();
    if (!F || !F->isIntrinsic())
      return true;  // a body's poison is the dataflow's question, not this one
    if (C->hasPoisonGeneratingFlags() || C->hasPoisonGeneratingMetadata())
      return true;
    const Intrinsic::ID Id = F->getIntrinsicID();
    if (Id != Intrinsic::ctlz && Id != Intrinsic::cttz && Id != Intrinsic::abs)
      return intrinsicSemanticsCanPoison(*C);
    if (!curatedIntrinsicCanBePoison(C))
      return false;  // the poison immarg is `false`: total
    if (!AllowProofs)
      return true;
    const Value *X = C->getArgOperand(0);
    const SimplifyQuery SQ = flagFreeQuery(I);
    if (Id != Intrinsic::abs)
      return !isKnownNonZero(X, SQ);
    const unsigned BW = X->getType()->getScalarSizeInBits();
    return computeConstantRangeIncludingKnownBits(X, /*ForSigned=*/true, SQ)
        .contains(APInt::getSignedMinValue(BW));
  }
  if (canCreateUndefOrPoison(cast<Operator>(&I),
                             /*ConsiderFlagsAndMetadata=*/false) ||
      I.hasPoisonGeneratingMetadata())
    return true;
  return I.hasPoisonGeneratingFlags() && !(AllowProofs && poisonFlagsProven(I));
}

}  // namespace cq
