// EmitInverse.cpp — see header. The per-call adjoint dispatch (PRD §2.3).
//
// Step 1 implemented the two uncontrolled cases that need no symbol lookup: the
// rotation-negate case (re-emit the forward `cqrt_ry/rz_<W>` with a negated
// angle) and the self-adjoint involutions (`cqrt_x` / `cqrt_cswap`, emitted
// as-is). Step 2 adds the uncontrolled DATA TEMPLATE case (`cq_template_*` →
// its `_inv` twin), which mints a FRESH handle that must be threaded onward
// (R-template-inv-fresh-handle). The controlled `_controlled_inv` path lands in
// Step 4 (InShadowAdjoint).

#include "EmitInverse.h"

#include "ControlledSymbols.h"
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Function.h"

using namespace llvm;

namespace cq {

namespace {

// Operand index of the threaded data handle in a forward UNCONTROLLED data
// template `cq_template_<op>_<W>[_hl|_lh]`. The `_lh` form is `(classical,
// handle)` — handle at 1; every other shape (`_hl`, QQ, unary/cast) keeps the
// handle (or the primary handle) at arg 0. Decoded from the name suffix, the
// canonical source of the operand layout (TemplateName.cpp). Single-register
// chains (the Step-2 scope) carry exactly one threaded handle per link.
unsigned templateHandleIndex(StringRef Name) {
  return Name.ends_with("_lh") ? 1 : 0;
}

}  // namespace

Value *emitInverseCall(IRBuilder<> &B, CallInst *Forward, WidthDispatch &wd,
                       ControlledSymbols &csyms, Value *Flag, Value *CurHandle) {
  (void)wd;     // template `_inv` mints from the forward type; no `wd` lookup.
  (void)csyms;  // Step 4 (controlled `_controlled_inv`) mints via `csyms`.
  (void)Flag;   // Step 4 supplies the control flag; unused for uncontrolled cases.

  Function *Callee = Forward ? Forward->getCalledFunction() : nullptr;
  if (!Callee)
    return nullptr;
  StringRef Name = Callee->getName();

  // Uncontrolled rotation: `cqrt_ry_<W>(h, θ)` / `cqrt_rz_<W>(h, θ)`. The
  // inverse is the SAME forward symbol with a negated angle — there is no
  // `cqrt_ry/rz_<W>_inv` symbol. Void / in-place: the "current handle" the next
  // reversed link consumes is this gate's handle (the threaded `CurHandle` when
  // a non-in-place link upstream produced a fresh one, else the forward arg 0).
  if ((Name.starts_with("cqrt_ry_") || Name.starts_with("cqrt_rz_")) &&
      !Name.contains("_controlled") && Forward->arg_size() == 2) {
    Value *Handle = CurHandle ? CurHandle : Forward->getArgOperand(0);
    Value *NegAngle = B.CreateFNeg(Forward->getArgOperand(1));
    CallInst *Inv = B.CreateCall(Callee, {Handle, NegAngle});
    if (DebugLoc DL = Forward->getDebugLoc())
      Inv->setDebugLoc(DL);
    return Handle;
  }

  // Self-adjoint involutions: `cqrt_x` / `cqrt_cswap` are their own inverse, so
  // emit AS-IS (no `_inv` lookup). Void; return the (threaded) handle operand.
  if (Name == "cqrt_x" || Name == "cqrt_cswap") {
    SmallVector<Value *, 3> Args(Forward->args());
    if (CurHandle && !Args.empty())
      Args[0] = CurHandle;
    CallInst *Inv = B.CreateCall(Callee, Args);
    if (DebugLoc DL = Forward->getDebugLoc())
      Inv->setDebugLoc(DL);
    return CurHandle ? CurHandle : Forward->getArgOperand(0);
  }

  // Uncontrolled data template: `cq_template_<op>_<W>[_hl|_lh]` → its declared
  // `_inv` twin. The twin's FunctionType is BYTE-IDENTICAL to the forward (PRD
  // §2.3); only the symbol flips, so mint it from the forward callee's name +
  // type. Clone the forward operands, substitute the threaded handle for the
  // data operand, and return the FRESH result handle (R-template-inv-fresh-handle)
  // so the next reversed link threads it.
  if (Name.starts_with("cq_template_") && !Name.contains("_controlled") &&
      !Name.ends_with("_inv")) {
    SmallVector<Value *, 3> Args(Forward->args());
    unsigned HIdx = templateHandleIndex(Name);
    if (CurHandle && HIdx < Args.size())
      Args[HIdx] = CurHandle;
    FunctionCallee Inv = Forward->getModule()->getOrInsertFunction(
        (Name + "_inv").str(), Forward->getFunctionType());
    CallInst *InvCall = B.CreateCall(Inv, Args, "h_inv");
    if (DebugLoc DL = Forward->getDebugLoc())
      InvCall->setDebugLoc(DL);
    return InvCall;
  }

  // Controlled `_controlled_inv` (Step 4) is not yet handled; returning nullptr
  // keeps an un-invertible link loud rather than emitting a half-reversed chain.
  return nullptr;
}

Value *emitInverseChain(IRBuilder<> &B, ArrayRef<CallInst *> ForwardChain,
                        WidthDispatch &wd, ControlledSymbols &csyms,
                        Value *Flag, Value *Terminal) {
  // Walk the chain in reverse program order: the adjoint of (g0 ∘ g1 ∘ … ∘ gN)
  // is (gN⁻¹ ∘ … ∘ g1⁻¹ ∘ g0⁻¹). Thread the live handle through each link — the
  // first inverse consumes the terminal handle; a template `_inv` mints a fresh
  // result that feeds the next inverse, while in-place rotations pass it through.
  // Returns the FINAL threaded handle (the one to free), or nullptr if a link
  // was not invertible. Callers PRE-VALIDATE invertibility (Uncomputation only
  // feeds uncontrolled single-register chains), so the nullptr path is a
  // defensive backstop — the caller skips the `cqrt_free` when it fires.
  Value *Cur = Terminal;
  for (int i = (int)ForwardChain.size() - 1; i >= 0; --i) {
    Value *Next = emitInverseCall(B, ForwardChain[i], wd, csyms, Flag, Cur);
    if (!Next)
      return nullptr;
    Cur = Next;
  }
  return Cur;
}

}  // namespace cq
