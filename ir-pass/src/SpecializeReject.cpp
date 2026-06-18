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

// The Callee-only body-shape verdict (arity cap, straight-line value shape, no
// `cq_*`/measure/non-reversibilizable construct, integer-i32 return), recursing
// through nested calls (Phase 6.3 transitive). `OnStack` is the DFS recursion
// stack of callees currently being scanned; a nested call whose target is on the
// stack (self OR mutual) is a call-graph cycle → `Recursion` (the convergence
// argument requires the accepted subset to be acyclic, §2.8). A nested call to a
// VISIBLE classical body recurses (it will be transitively specialized); a nested
// call with no static body (indirect / declaration-only / inline-asm) is an
// unproven shape → reject. The per-Site argument-ABI (tainted args are i32) is
// NOT checked here — it needs the call's real taint mask and is verified by
// `classifyCandidate` for every concrete `(Site, mask)` (the top at detection,
// each inner at specialize-time).
SpecReject scanBody(Function *Callee, const IntrinsicSets &Sets,
                    WidthDispatch &wd, SmallPtrSetImpl<const Function *> &OnStack,
                    Instruction *&WhereOut, std::string &KindOut) {
  // (0a) Varargs: `taintArgMask` reads the call site's `arg_size()` (incl. the
  //      vararg tail) while seeding iterates the callee's FIXED params only — a
  //      tainted vararg-tail arg would set a mask bit that is never seeded
  //      (silent under-taint). Unreachable in 6.1/6.2 (a vararg site never became
  //      a candidate), but the transitive worklist broadens the set, so decline
  //      loudly now ([[6-3-drain-ordering-varargs-recheck]]).
  if (Callee->isVarArg()) {
    WhereOut = Callee->getEntryBlock().getTerminator();
    KindOut = "varargs";
    return SpecReject::NonReversibilizable;
  }

  // (0) Arity cap (DD-5): a 65th parameter truncates the 64-bit mask and silently
  //     aliases two distinct signatures. Applies to every specialized body — a
  //     nested callee included.
  if (Callee->arg_size() > kSpecMaxArity) {
    WhereOut = &*Callee->getEntryBlock().begin();
    return SpecReject::ArityOverflow;
  }

  // (1) Straight-line value bodies only (the open Rule-13 item, §8). A body with
  //     >1 basic block has a branch/switch — in-body control flow this plan does
  //     not prove.
  if (Callee->size() != 1) {
    WhereOut = Callee->getEntryBlock().getTerminator();
    return SpecReject::InBodyControl;
  }

  // (2) ABI return: a (possibly-tainted) return must have an integer i32
  //     reversible copy. fp → null `copyFn` (the f64-angle trap, C10);
  //     i128/vector/half → empty `abiWidthFromType`; non-i32 int → no i32-handle
  //     representation. `void` is a classical no-output — exempt.
  Type *RetTy = Callee->getReturnType();
  if (!RetTy->isVoidTy()) {
    StringRef RetW = abiWidthFromType(RetTy);
    if (RetW.empty() || !wd.copyFn(RetW) || RetW != "i32") {
      WhereOut = Callee->getEntryBlock().getTerminator();
      return SpecReject::FpAbi;
    }
  }

  // (3) WHITELIST body scan over the single basic block (guaranteed by (1)). The
  //     `OnStack` insert/erase brackets this callee's frame so a deeper recursion
  //     sees it (cycle detection); `Inserted` guards the (impossible here, but
  //     defensive) re-entry of an already-stacked callee.
  bool Inserted = OnStack.insert(Callee).second;
  auto pop = [&]() {
    if (Inserted)
      OnStack.erase(Callee);
  };
  BasicBlock &BB = Callee->getEntryBlock();
  for (Instruction &I : BB) {
    // The terminator must be a plain `ret` (no branch/switch — in-body control).
    if (I.isTerminator()) {
      if (!isa<ReturnInst>(I)) {
        WhereOut = &I;
        pop();
        return SpecReject::InBodyControl;
      }
      continue;
    }
    // Calls: a quantum primitive (rejects), a recursion/cycle, inline asm, or a
    // nested classical call (Phase 6.3 — recurse into its body).
    if (auto *CB = dyn_cast<CallBase>(&I)) {
      if (CB->isInlineAsm()) {
        WhereOut = &I;
        KindOut = "inline assembly";
        pop();
        return SpecReject::NonReversibilizable;
      }
      if (auto *CI = dyn_cast<CallInst>(CB)) {
        if (Sets.Rotations.count(CI)) {
          WhereOut = &I;
          pop();
          return SpecReject::QuantumPrimitive;
        }
        if (Sets.Measures.count(CI)) {
          WhereOut = &I;
          pop();
          return SpecReject::Measurement;
        }
        Function *Inner = CI->getCalledFunction();
        // Call-graph cycle (self OR mutual): the convergence argument needs the
        // accepted subset acyclic, so a recursive callee has no static depth
        // bound and is declined loudly (§2.8, §2.11).
        if (Inner && OnStack.count(Inner)) {
          WhereOut = &I;
          pop();
          return SpecReject::Recursion;
        }
        // A nested call to a VISIBLE classical body recurses — it is the
        // transitive-specialization candidate (6.3). Its argument-ABI is checked
        // at specialize-time with the inner's real mask.
        if (Inner && !Inner->isDeclaration()) {
          SpecReject R = scanBody(Inner, Sets, wd, OnStack, WhereOut, KindOut);
          if (R != SpecReject::Accept) {
            pop();
            return R;
          }
          continue;  // nested specializable call — OK.
        }
        // Indirect (null callee) or declaration-only (no IR) nested call — an
        // unproven shape with no body to reversibilize (DD-2).
        WhereOut = &I;
        KindOut = "nested call";
        pop();
        return SpecReject::NonReversibilizable;
      }
      // A non-`CallInst` CallBase reached as a non-terminator (defensive — an
      // invoke/callbr is a terminator caught above): an unproven shape.
      WhereOut = &I;
      KindOut = "nested call";
      pop();
      return SpecReject::NonReversibilizable;
    }
    // Memory / synchronization — never pure, no reversible copy.
    if (isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I) || isa<FenceInst>(I)) {
      WhereOut = &I;
      KindOut = "atomic";
      pop();
      return SpecReject::NonReversibilizable;
    }
    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      WhereOut = &I;
      KindOut = LI->isVolatile() ? "volatile" : "memory access";
      pop();
      return SpecReject::NonReversibilizable;
    }
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      WhereOut = &I;
      KindOut = SI->isVolatile() ? "volatile" : "memory access";
      pop();
      return SpecReject::NonReversibilizable;
    }
    // Control muxes — InBodyControl (a select/phi on a tainted value).
    if (isa<SelectInst>(I) || isa<PHINode>(I)) {
      WhereOut = &I;
      pop();
      return SpecReject::InBodyControl;
    }
    // The reversibilizable data-op whitelist. A vector lane has no scalar copy.
    if (isa<BinaryOperator>(I) || isa<UnaryOperator>(I) || isa<CmpInst>(I) ||
        isa<CastInst>(I)) {
      if (touchesVector(I)) {
        WhereOut = &I;
        KindOut = "vector SIMD";
        pop();
        return SpecReject::NonReversibilizable;
      }
      continue;  // accepted data op.
    }
    // Anything else (getelementptr, freeze, va_arg, extract/insert, …) is an
    // unproven shape — decline (Prime Directive).
    WhereOut = &I;
    KindOut = "unsupported instruction";
    pop();
    return SpecReject::NonReversibilizable;
  }

  pop();
  return SpecReject::Accept;
}

}  // namespace

SpecReject classifyCandidate(const SpecCandidate &Cand, const TaintSet &taint,
                             WidthDispatch &wd, Instruction *&WhereOut,
                             std::string &KindOut) {
  WhereOut = nullptr;
  KindOut.clear();

  // (A) Per-Site argument ABI (Rule 15): the runtime handle is ALWAYS i32, so
  //     every TAINTED argument (mask bit set) must arrive as an i32 handle. A
  //     classical pass-through arg may be any width. This is the one check that
  //     needs the call's concrete taint mask — it is verified for the top
  //     candidate at detection and for every inner candidate at specialize-time
  //     (each with its own real `(Site, mask)`).
  for (unsigned i = 0, n = Cand.Site->arg_size(); i < n; ++i) {
    if (!(Cand.Mask & (SpecMask(1) << i)))
      continue;  // classical pass-through arg — any width is fine.
    if (!Cand.Site->getArgOperand(i)->getType()->isIntegerTy(32)) {
      WhereOut = Cand.Site;
      return SpecReject::FpAbi;
    }
  }

  // (B) Callee body shape + transitive closure (arity, straight-line value body,
  //     no `cq_*`/measure/non-reversibilizable construct, i32 return, no
  //     call-graph cycle), recursing through nested calls (6.3). The single
  //     authoritative body verdict (Rule 14).
  IntrinsicSets Sets = buildIntrinsicSets(taint);
  SmallPtrSet<const Function *, 8> OnStack;
  return scanBody(Cand.Callee, Sets, wd, OnStack, WhereOut, KindOut);
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
