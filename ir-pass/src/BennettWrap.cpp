// BennettWrap.cpp — the thin Bennett compute-copy-uncompute synthesizer (DD-3).

#include "BennettWrap.h"

#include "EmitInverse.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"

using namespace llvm;

namespace cq {

namespace {

// Loud declines (Rule 12; not fixture-pinned in 6.1 — the pre-scan is
// unreachable-by-construction over a pure-classical clone whose data templates
// and compares are all invertible post-WI-0, but defends a future widening of
// the accepted body set).
constexpr char kMsgCloneUninvertible[] =
    "cq specialization: clone body contains an un-invertible primitive under "
    "quantum lift";
constexpr char kMsgCloneNoCopy[] =
    "cq specialization: clone return width has no reversible copy under quantum "
    "lift";

void diagnose(Instruction *Where, StringRef Msg) {
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

}  // namespace

bool emitBennettWrap(Function &Clone, ArrayRef<CallInst *> ForwardStream,
                     Value *ResultRail, ArrayRef<Value *> ScratchRails,
                     StringRef RetAbiWidth, WidthDispatch &wd,
                     TaintSet &cloneTaint) {
  // The accepted body is a single straight-line BB terminated by `ret`.
  auto *Ret = dyn_cast<ReturnInst>(Clone.getEntryBlock().getTerminator());
  if (!Ret)
    return false;  // not the proven straight-line shape (defensive).

  // (a) Pre-scan the WHOLE forward stream BEFORE any mutation. A single
  //     un-invertible primitive declines loudly with NO emission — never a
  //     half-reversed chain (C11). Post-WI-0 compares pass this scan.
  for (CallInst *Fwd : ForwardStream)
    if (!isInverseEmittable(Fwd)) {
      diagnose(Fwd, kMsgCloneUninvertible);
      return false;
    }

  IRBuilder<> B(Ret);

  // (b)+(c) Copy the result rail out, BEFORE the reverse (the reverse zeroes the
  //     result rail in place; copy-after-reverse would copy |0>). Only when the
  //     return carries taint — a classical / no-output return has no handle to
  //     copy (`ResultRail` is null then).
  Value *Out = nullptr;
  if (ResultRail) {
    FunctionCallee Alloc = wd.allocFn(RetAbiWidth);
    FunctionCallee Copy = wd.copyFn(RetAbiWidth);
    Type *WTy = wd.llvmWidthType(RetAbiWidth);
    if (!Alloc || !Copy || !WTy) {
      diagnose(Ret, kMsgCloneNoCopy);  // fp/i128 return — gated earlier, defensive.
      return false;
    }
    Out = B.CreateCall(Alloc, {Constant::getNullValue(WTy)}, "cqq.out");
    B.CreateCall(Copy, {ResultRail, Out});
  }

  // (d) Reverse-program-order adjoint (void `_unc`). Check the bool and return
  //     BEFORE any free — defends against a half-reversed chain (unreachable
  //     after the step-(a) pre-scan over the SAME predicate, C11).
  if (!emitInverseChain(B, ForwardStream, wd)) {
    diagnose(Ret, kMsgCloneUninvertible);
    return false;
  }

  // (e) Free each scratch rail — exactly the set whose `_unc` ran (every forward
  //     result, incl. the result rail (d) zeroed in place) — ONLY after the
  //     COMPLETE reverse returned true, never interleaved (Rule 6). `Out`
  //     escapes via `ret` (not in `ScratchRails`); borrowed params are read-only
  //     (never produced by the forward stream, so never here).
  FunctionCallee Free = wd.freeFn();
  for (Value *Rail : ScratchRails) {
    B.CreateCall(Free, {Rail});
    cloneTaint.ControlOwnedRails.insert(Rail);  // defense-in-depth (DD-2).
  }

  // Return the basis-valued copy instead of the (now-zeroed-and-freed) result
  // rail. `Out` dominates `ret` (it is the alloc above).
  if (Out) {
    cloneTaint.ControlOwnedRails.insert(Out);
    Ret->setOperand(0, Out);
  }
  return true;
}

}  // namespace cq
