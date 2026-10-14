// MergeStreamGates.cpp — see header (bd test_C_libtooling-r2j3.32).

#include "MergeStreamGates.h"

#include "ChainWalk.h"         // isInPlaceGateOn / isInteriorConsumer / ...
#include "TaintPropagation.h"  // TaintSet
#include "TemplateName.h"      // isUncHandleSlot

#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

StringRef calleeName(const CallInst *C) {
  const Function *F = C ? C->getCalledFunction() : nullptr;
  return F ? F->getName() : StringRef();
}

// `cqrt_copy_<W>_controlled(ctrl, src, dst)`, int or fp: void, arity 3. The
// one gate allowed to WRITE a merge rail (runtime/cq_runtime.h: a transversal
// CNOT basis copy, an involution with no `_inv` twin).
bool isControlledCopy(const CallInst *C) {
  StringRef N = calleeName(C);
  return N.starts_with("cqrt_copy_") && N.ends_with("_controlled") &&
         C->getType()->isVoidTy() && C->arg_size() == 3;
}

// The merge-stream ALLOWLIST and, per gate, the argument slots it WRITES.
// Every slot not listed is a pure read. Fails closed: anything not named is
// not stream traffic, and a stream containing it is not replayed.
//   cqrt_alloc_<W>(seed)            mints, writes nothing
//   cq_template_* (forward producer) mints, reads every operand
//   cq_template_*_unc(rail, ...)    writes slot 0 (the strip / literal node)
//   cqrt_cnot(c, t)                 writes 1
//   cqrt_toffoli(c1, c2, t)         writes 2
//   cqrt_x(t)                       writes 0
//   cqrt_copy_<W>_controlled(f,s,d) writes 2
//   cqrt_free(r)                    writes 0
bool streamGateWrites(const CallInst *C, SmallVectorImpl<unsigned> &W) {
  W.clear();
  StringRef N = calleeName(C);
  if (N.empty())
    return false;
  bool Void = C->getType()->isVoidTy();
  unsigned A = C->arg_size();
  if (N.starts_with("cqrt_alloc_"))
    return !Void && A == 1;
  if (N == "cqrt_cnot" && Void && A == 2)
    return W.push_back(1), true;
  if (N == "cqrt_toffoli" && Void && A == 3)
    return W.push_back(2), true;
  if (N == "cqrt_x" && Void && A == 1)
    return W.push_back(0), true;
  if (N == "cqrt_free" && Void && A == 1)
    return W.push_back(0), true;
  if (isControlledCopy(C))
    return W.push_back(2), true;
  if (N.starts_with("cq_template_") && !N.contains("_controlled")) {
    if (N.ends_with("_unc"))
      return Void && A >= 1 ? (W.push_back(0), true) : false;
    return !Void && isTemplateProducer(C);
  }
  return false;
}

// The CONTROL slots of the stream's controlled gates.
SmallVector<unsigned, 2> controlSlots(const CallInst *C) {
  StringRef N = calleeName(C);
  if (N == "cqrt_cnot" || isControlledCopy(C))
    return {0};
  if (N == "cqrt_toffoli")
    return {0, 1};
  return {};
}

// Does `C` only READ the register `X` (never write, measure, record or escape
// it)? Asked of every reader of a merge rail and of every gate that touches a
// register the stream reads between the stream and its replay.
bool onlyReads(const CallInst *C, const Value *X, const TaintSet &taint) {
  StringRef N = calleeName(C);
  if (N.empty())
    return false;
  // A forward template producer reading X in a handle slot, a forward QRAM
  // store reading X as its index/value, or an emitter-recorded flag strip:
  // ChainWalk's interior-consumer rows (b)/(b″)/(c), asked, not re-spelled
  // (R12). Its row (a), an in-place gate ON X, is a write and is refused first.
  if (isInPlaceGateOn(C, X))
    return false;
  if (isInteriorConsumer(C, X, taint, /*AdmitCloneCalls=*/false))
    return true;
  // The spine's void out-first adjoint `cq_template_*_unc(rail, operands…)`:
  // slot 0 is the rail it zeroes, every other handle slot a read.
  if (N.starts_with("cq_template_") && N.ends_with("_unc")) {
    bool Any = false;
    for (unsigned I = 0, E = C->arg_size(); I != E; ++I)
      if (C->getArgOperand(I) == X) {
        if (!isUncHandleSlot(N, I))
          return false;
        Any = true;
      }
    return Any;
  }
  // The read-only CONTROL / SOURCE slots of the stream's own permutation gates
  // (`streamGateWrites` names the one written slot of each).
  SmallVector<unsigned, 2> W;
  if (!N.starts_with("cqrt_alloc_") && streamGateWrites(C, W) &&
      !N.starts_with("cq_template_") && N != "cqrt_free") {
    bool Any = false;
    for (unsigned I = 0, E = C->arg_size(); I != E; ++I)
      if (C->getArgOperand(I) == X) {
        if (is_contained(W, I))
          return false;
        Any = true;
      }
    return Any;
  }
  return false;
}

// A value whose state a gate can change: every call result (each runtime
// handle is one, and a classical call result in a literal slot only makes the
// window check refuse more), a tainted Argument, and every Argument of a
// lifted clone body (its handles arrive as plain `i32` parameters). A Constant
// or a classical caller Argument is immutable SSA.
bool isRegister(const Value *V, const TaintSet &taint) {
  if (isa<CallInst>(V))
    return true;
  const auto *A = dyn_cast<Argument>(V);
  return A && (taint.Tainted.count(const_cast<Argument *>(A)) ||
               A->getParent()->getName().starts_with("__cq_q_"));
}

}  // namespace cq
