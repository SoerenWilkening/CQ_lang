// CallContract.cpp — bd bwfp: see CallContract.h. Split out of
// SpeculationSafety.cpp in review round 3 (2026-10-08), carrying that round's
// fixes: return attributes as poison sources, the constant-range proof, the
// fixpoint, a branch on poison as UB, and a verified `returned` (round 4).
// bd dm7f.21 moved the poison dataflow on to PoisonFlow.cpp.
#include "CallContract.h"

#include "FlagProof.h"          // poisonFlagsProven (bd dm7f.20)
#include "SpeculationSafety.h"  // callExecutionIsDefined

#include "llvm/ADT/SCCIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
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

using namespace llvm;
namespace cq {
bool speculationScalar(Type *T) {
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

namespace {
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

// bd dm7f.20 — may the range proof read the flags in `V`'s cone? Only when the
// body is acyclic and every flag in the cone is proven from flag-free facts
// about its own OPERANDS (`poisonFlagsProven`): a fact a flag adds then holds
// whenever its instruction is not poison, exactly as an operand fact does, and
// no flag ever proves itself. Measured need: clang -O1 stamps
// `range(i32 1, 257)` on `(x & 255) + 1u`, which rests on the `nuw`.
bool coneFlagsProven(const Value *V) {
  const auto *Root = dyn_cast<Instruction>(V);
  if (!Root)
    return false;
  for (scc_iterator<const Function *> It = scc_begin(Root->getFunction());
       !It.isAtEnd(); ++It)
    if (It.hasCycle())
      return false;
  SmallPtrSet<const Instruction *, 16> Seen;
  SmallVector<const Instruction *, 16> Work{Root};
  while (!Work.empty()) {
    const Instruction *I = Work.pop_back_val();
    if (!Seen.insert(I).second)
      continue;
    if (I->hasPoisonGeneratingMetadata() || !poisonFlagsProven(*I))
      return false;
    for (const Value *Op : I->operands())
      if (const auto *OI = dyn_cast<Instruction>(Op))
        Work.push_back(OI);
  }
  return true;
}

// LLVM's per-opcode range transfer functions (`ConstantRange::binaryOp`,
// `overflowingBinaryOp` under PROVEN flags, `castOp`) over the operands' ranges,
// `Depth` levels down, as LazyValueInfo composes them: `computeConstantRange`
// does no arithmetic for add/sub/mul (bd dm7f.20, `(x & 255) + 1u`).
ConstantRange composedRange(const Value *V, bool Signed, bool UseFlags,
                            const DataLayout &DL, unsigned Depth) {
  const KnownBits KB = computeKnownBits(V, DL, 0, nullptr, nullptr, nullptr,
                                        /*UseInstrInfo=*/UseFlags);
  const auto Pref = Signed ? ConstantRange::Signed : ConstantRange::Unsigned;
  ConstantRange CR = computeConstantRange(V, Signed, /*UseInstrInfo=*/UseFlags)
                         .intersectWith(ConstantRange::fromKnownBits(KB, Signed),
                                        Pref);
  if (Depth == 0)
    return CR;
  if (const auto *BO = dyn_cast<BinaryOperator>(V)) {
    const ConstantRange A =
        composedRange(BO->getOperand(0), Signed, UseFlags, DL, Depth - 1);
    const ConstantRange B =
        composedRange(BO->getOperand(1), Signed, UseFlags, DL, Depth - 1);
    unsigned NoWrap = 0;
    if (UseFlags && isa<OverflowingBinaryOperator>(BO)) {
      if (BO->hasNoUnsignedWrap())
        NoWrap |= OverflowingBinaryOperator::NoUnsignedWrap;
      if (BO->hasNoSignedWrap())
        NoWrap |= OverflowingBinaryOperator::NoSignedWrap;
    }
    const Instruction::BinaryOps Op = BO->getOpcode();
    const bool Wrapping = Op == Instruction::Add || Op == Instruction::Sub ||
                          Op == Instruction::Mul || Op == Instruction::Shl;
    CR = CR.intersectWith(NoWrap && Wrapping
                              ? A.overflowingBinaryOp(Op, B, NoWrap)
                              : A.binaryOp(Op, B),
                          Pref);
  } else if (const auto *CI = dyn_cast<CastInst>(V);
             CI && CI->getSrcTy()->isIntegerTy() &&
             (isa<ZExtInst>(CI) || isa<SExtInst>(CI) || isa<TruncInst>(CI))) {
    CR = CR.intersectWith(
        composedRange(CI->getOperand(0), Signed, UseFlags, DL, Depth - 1)
            .castOp(CI->getOpcode(), V->getType()->getIntegerBitWidth()),
        Pref);
  }
  return CR;
}

// Does the returned value `V` lie in `R` whenever it is not poison? Poison is the
// dataflow's question (`poisonFlow`). LLVM's own range and known-bits facts, in
// both signednesses, without the instruction flags a violation would make poison
// (review round 3: clang -O1 stamps `range(i32 1, 3)` on `x > 0 ? 1 : 2`), unless
// every such flag is proven (`coneFlagsProven`). Every fact here holds whenever
// the value it describes is not poison, which is the `range` attribute's own
// condition.
bool rangeProven(const ConstantRange &R, const Value *V, const DataLayout &DL) {
  if (!V || !V->getType()->isIntegerTy())
    return false;
  const bool UseFlags = coneFlagsProven(V);
  for (bool Signed : {false, true})
    if (R.contains(composedRange(V, Signed, UseFlags, DL, /*Depth=*/4)))
      return true;
  return false;
}
} // namespace

bool argAttrsAreInert(const CallBase *C, unsigned N) {
  return paramAttrsHold(C, N, /*AllowImmArg=*/false);
}

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

bool paramContractIsInert(const CallInst *C, unsigned N) {
  return paramAttrsHold(C, N, /*AllowImmArg=*/true);
}

namespace {
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
} // namespace

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

bool callContractIsInert(const CallInst *C) {
  if (!basicCallContractHolds(C))
    return false;
  const Function *F = C->getCalledFunction();
  for (unsigned N = 0; N != C->arg_size(); ++N)
    if (!speculationScalar(C->getArgOperand(N)->getType()) || !argAttrsAreInert(C, N))
      return false;
  return returnAttrsHold(C->getAttributes().getRetAttrs(), *F);
}

// bd dm7f.20: the owners the 6.5 dataflow asks (R12). The return contract is
// `callSiteReturnHolds` (a call-site `range` LLVM 19 stamps on ctpop/ctlz/cttz is
// proven from the intrinsic's semantics, never refused wholesale); the parameters
// are `paramContractIsInert` (inert attributes, an `immarg` only on a constant).
bool intrinsicContractHolds(const CallInst *C) {
  if (!callSiteReturnHolds(*C))
    return false;
  for (unsigned N = 0; N != C->arg_size(); ++N)
    if (!speculationScalar(C->getArgOperand(N)->getType()) ||
        !paramContractIsInert(C, N))
      return false;
  return true;
}

bool callExecutionIsDefined(const CallInst *C) {
  const Function *F = C ? C->getCalledFunction() : nullptr;
  return F && !C->hasOperandBundles() &&
         C->getCallingConv() == F->getCallingConv() && !C->doesNotReturn() &&
         !C->isConvergent() && !C->cannotDuplicate() && !C->isMustTailCall() &&
         !C->hasFnAttr(Attribute::ReturnsTwice);
}

} // namespace cq
