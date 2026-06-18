// SpecializeReject.cpp — the single authoritative accept predicate for Phase 6
// specialization (Rule 14), plus the loud-diagnostic renderer. WHITELIST body
// scan: only `BinaryOperator` / `UnaryOperator` / `CmpInst` / `CastInst` data
// ops, the `ret` terminator, and quantum-primitive calls (which themselves
// reject) are recognized; EVERYTHING else is an unproven shape and rejects
// (Prime Directive — over-declining is always safe).

#include "SpecializeReject.h"

#include "OpcodeSupport.h"
#include "SpecializePlan.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"

#include <string>

using namespace llvm;

namespace cq {

namespace {

// Exact-pointer membership of the front-end intrinsic call sites
// `propagate` already collected module-wide (NEVER name-prefix — C7). A clone
// candidate's body is the ORIGINAL callee body, whose theta/phi/measure calls
// were collected by `propagate`, so a body `CallInst` is a quantum primitive iff
// it is one of those exact pointers.
struct IntrinsicSets {
  SmallPtrSet<const CallInst *, 8> Rotations;  // theta + phi
  SmallPtrSet<const CallInst *, 8> Measures;
};

IntrinsicSets buildIntrinsicSets(const TaintSet &taint) {
  IntrinsicSets S;
  S.Rotations.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  S.Rotations.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());
  S.Measures.insert(taint.MeasureCalls.begin(), taint.MeasureCalls.end());
  return S;
}

// Does any operand or the result of `I` carry a vector type? A SIMD value has no
// per-lane reversible-copy story (`cqrt_copy` is scalar), so it is a
// non-reversibilizable construct.
bool touchesVector(const Instruction &I) {
  if (I.getType()->isVectorTy())
    return true;
  for (const Value *Op : I.operands())
    if (Op->getType()->isVectorTy())
      return true;
  return false;
}

}  // namespace

SpecReject classifyCandidate(const SpecCandidate &Cand, const TaintSet &taint,
                             WidthDispatch &wd, Instruction *&WhereOut,
                             std::string &KindOut) {
  Function *Callee = Cand.Callee;
  WhereOut = nullptr;
  KindOut.clear();

  // (0) Arity cap (DD-5): a 65th parameter would truncate the 64-bit mask and
  //     silently alias two distinct signatures (the over-accept class).
  if (Callee->arg_size() > kSpecMaxArity) {
    WhereOut = &*Callee->getEntryBlock().begin();
    return SpecReject::ArityOverflow;
  }

  // (1) Straight-line value bodies only (the open Rule-13 item, §8). A body with
  //     >1 basic block has a branch/switch — in-body control flow whose Bennett
  //     composition this plan does not prove. Declined until that lands as its
  //     own red→green→clear WI.
  if (Callee->size() != 1) {
    WhereOut = Callee->getEntryBlock().getTerminator();
    return SpecReject::InBodyControl;
  }

  // (2) ABI: the runtime handle is ALWAYS i32 (Rule 15). A tainted argument must
  //     therefore arrive as an i32 handle, and a (possibly-tainted) return must
  //     have an integer i32 reversible copy. fp → null `copyFn` (the f64-angle
  //     trap, C10); i128/vector/half → empty `abiWidthFromType`; non-i32 int →
  //     no i32-handle representation at the call boundary. `void` is a classical
  //     no-output (its tainted arg is dead) — exempt from the return check.
  for (unsigned i = 0, n = Cand.Site->arg_size(); i < n; ++i) {
    if (!(Cand.Mask & (SpecMask(1) << i)))
      continue;  // classical pass-through arg — any width is fine.
    if (!Cand.Site->getArgOperand(i)->getType()->isIntegerTy(32)) {
      WhereOut = Cand.Site;
      return SpecReject::FpAbi;
    }
  }
  Type *RetTy = Callee->getReturnType();
  if (!RetTy->isVoidTy()) {
    StringRef RetW = abiWidthFromType(RetTy);
    if (RetW.empty() || !wd.copyFn(RetW) || RetW != "i32") {
      WhereOut = Callee->getEntryBlock().getTerminator();
      return SpecReject::FpAbi;
    }
  }

  // (3) WHITELIST body scan. The single basic block (guaranteed by (1)).
  IntrinsicSets Sets = buildIntrinsicSets(taint);
  BasicBlock &BB = Callee->getEntryBlock();
  for (Instruction &I : BB) {
    // The terminator must be a plain `ret` (no branch/switch — in-body control).
    if (I.isTerminator()) {
      if (!isa<ReturnInst>(I)) {
        WhereOut = &I;
        return SpecReject::InBodyControl;
      }
      continue;
    }
    // Calls: a quantum primitive (rejects), a self-call (recursion), inline asm,
    // or a foreign/nested call (out of 6.1's straight-line scope).
    if (auto *CB = dyn_cast<CallBase>(&I)) {
      if (CB->isInlineAsm()) {
        WhereOut = &I;
        KindOut = "inline assembly";
        return SpecReject::NonReversibilizable;
      }
      if (auto *CI = dyn_cast<CallInst>(CB)) {
        if (Sets.Rotations.count(CI)) {
          WhereOut = &I;
          return SpecReject::QuantumPrimitive;
        }
        if (Sets.Measures.count(CI)) {
          WhereOut = &I;
          return SpecReject::Measurement;
        }
        if (CI->getCalledFunction() == Callee) {
          WhereOut = &I;
          return SpecReject::Recursion;
        }
      }
      // Any other call (in-module foreign def, opaque extern, indirect, invoke,
      // or non-self CallInst) — a nested call the 6.1 straight-line lifter does
      // not handle (the transitive worklist is 6.3); decline loudly.
      WhereOut = &I;
      KindOut = "nested call";
      return SpecReject::NonReversibilizable;
    }
    // Memory / synchronization — never pure, no reversible copy.
    if (isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I) || isa<FenceInst>(I)) {
      WhereOut = &I;
      KindOut = "atomic";
      return SpecReject::NonReversibilizable;
    }
    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      WhereOut = &I;
      KindOut = LI->isVolatile() ? "volatile" : "memory access";
      return SpecReject::NonReversibilizable;
    }
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      WhereOut = &I;
      KindOut = SI->isVolatile() ? "volatile" : "memory access";
      return SpecReject::NonReversibilizable;
    }
    // Control muxes — InBodyControl (a select/phi on a tainted value).
    if (isa<SelectInst>(I) || isa<PHINode>(I)) {
      WhereOut = &I;
      return SpecReject::InBodyControl;
    }
    // The reversibilizable data-op whitelist. A vector lane has no scalar copy.
    if (isa<BinaryOperator>(I) || isa<UnaryOperator>(I) || isa<CmpInst>(I) ||
        isa<CastInst>(I)) {
      if (touchesVector(I)) {
        WhereOut = &I;
        KindOut = "vector SIMD";
        return SpecReject::NonReversibilizable;
      }
      continue;  // accepted data op.
    }
    // Anything else (getelementptr, freeze, va_arg, extract/insert, …) is an
    // unproven shape — decline (Prime Directive).
    WhereOut = &I;
    KindOut = "unsupported instruction";
    return SpecReject::NonReversibilizable;
  }

  return SpecReject::Accept;
}

void diagnoseReject(Instruction *Where, SpecReject Why, StringRef Kind) {
  std::string Msg;
  switch (Why) {
  case SpecReject::Recursion:
    Msg = kMsgRecursion;
    break;
  case SpecReject::FpAbi:
    Msg = kMsgFpAbi;
    break;
  case SpecReject::QuantumPrimitive:
    Msg = kMsgQuantumPrimitive;
    break;
  case SpecReject::Measurement:
    Msg = kMsgMeasurement;
    break;
  case SpecReject::InBodyControl:
    Msg = kMsgInBodyControl;
    break;
  case SpecReject::ArityOverflow:
    Msg = kMsgArityOverflow;
    break;
  case SpecReject::NonReversibilizable:
    Msg = (Twine(kMsgNonRevizPrefix) + " (" + Kind + ")").str();
    break;
  case SpecReject::Accept:
    return;  // never diagnosed.
  }
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

}  // namespace cq
