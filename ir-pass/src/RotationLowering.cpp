// RotationLowering.cpp — Lower tainted `@cq_theta_<sfx>` / `@cq_phi_<sfx>`
// rotations to runtime calls. See header for the contract; backend.md §5.1
// for the operand-dispatch table and IMPLEMENTATION.md §1 for the
// cross-type-RAUW invariant.
//
// Single pass over the already-collected work lists (`taint.ThetaCalls`,
// `taint.PhiCalls` — populated by `propagate`); no module re-walk.

#include "RotationLowering.h"

#include "ControlPlan.h"
#include "ControlledSymbols.h"
#include "OpcodeSupport.h"  // abiWidthFromType
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include <string>
#include <vector>

using namespace llvm;

namespace cq {

namespace {

// Strip a known prefix (`cq_theta_` / `cq_phi_`) from the call's callee
// name → suffix (`si32`). Returns "" on mismatch (callee absent or name
// doesn't start with the prefix).
StringRef suffixFromName(const CallInst *CI, StringRef Prefix) {
  Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return {};
  StringRef N = Callee->getName();
  if (!N.starts_with(Prefix))
    return {};
  return N.substr(Prefix.size());
}

// "Unsupported rotation" diagnostic — mirrors MeasureLowering's surface so
// the pass speaks one diagnostic dialect. Failure is loud, not silent: the
// offending call is left in place to surface at the verifier.
void diagnoseUnsupported(CallInst *CI, const char *What) {
  std::string Msg = std::string("cq rotation lowering: unsupported ") + What;
  CI->getFunction()->getContext().diagnose(
      DiagnosticInfoUnsupported(*CI->getFunction(), Msg));
}

}  // namespace

bool emitRz(CallInst *Phi, Value *Handle, Value *Angle, WidthDispatch &wd,
            bool controlled, Value *Flag) {
  StringRef Sfx = suffixFromName(Phi, "cq_phi_");
  StringRef Abi = wd.abiWidthFor(Sfx);
  IRBuilder<> Builder(Phi);
  if (!controlled) {
    // Uncontrolled gate body: `cqrt_rz_<W>(handle, angle)`.
    FunctionCallee Rz = Abi.empty() ? FunctionCallee() : wd.rzRtFn(Abi);
    if (!Rz) {
      diagnoseUnsupported(Phi, "phi suffix/width");
      return false;  // leave the phi in place for the verifier.
    }
    CallInst *RzCall = Builder.CreateCall(Rz, {Handle, Angle});
    if (DebugLoc DL = Phi->getDebugLoc())
      RzCall->setDebugLoc(DL);
    return true;
  }
  // Controlled gate body: `cqrt_rz_<W>_controlled(flag, handle, angle)`, the
  // i32 control flag prepended as arg 0 (PRD §1.2).
  ControlledSymbols csyms(*Phi->getModule(), wd);
  FunctionCallee Rz =
      Abi.empty() ? FunctionCallee() : csyms.controlledRotationFn(Abi);
  if (!Rz) {
    diagnoseUnsupported(Phi, "controlled phi suffix/width");
    return false;
  }
  CallInst *RzCall = Builder.CreateCall(Rz, {Flag, Handle, Angle});
  if (DebugLoc DL = Phi->getDebugLoc())
    RzCall->setDebugLoc(DL);
  return true;
}

void lowerRotations(Module &M, WidthDispatch &wd, TaintSet &taint,
                    const ControlPlan *plan) {
  (void)M;
  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty())
    return;

  IRBuilder<> Builder(wd.context());
  std::vector<Instruction *> ToErase;

  // --- THETA. Iterate in collection (BB) order. Forward order matters: a
  // chained theta N+1 takes theta N's result as its operand, and lowering
  // theta N RAUWs that result to the handle — so when we re-read theta
  // N+1's operand it is already the handle (tainted), routing it to the
  // ry-only path with no second allocation.
  for (CallInst *Theta : taint.ThetaCalls) {
    StringRef Sfx = suffixFromName(Theta, "cq_theta_");
    StringRef Abi = wd.abiWidthFor(Sfx);
    FunctionCallee Ry = Abi.empty() ? FunctionCallee() : wd.ryRtFn(Abi);
    if (!Ry) {
      diagnoseUnsupported(Theta, "theta suffix/width");
      continue;
    }
    Value *Op = Theta->getArgOperand(0);  // re-read: RAUW may have updated it
    Value *Angle = Theta->getArgOperand(1);
    Builder.SetInsertPoint(Theta);

    Value *Handle;
    if (taint.Tainted.count(Op)) {
      // Tainted operand (chained theta) → ry only on the existing handle.
      Handle = Op;
    } else {
      // Classical operand → mint a fresh handle, then ry on it.
      FunctionCallee Alloc = wd.allocFn(Abi);
      CallInst *H = Builder.CreateCall(Alloc, {Op}, "h");
      if (DebugLoc DL = Theta->getDebugLoc())
        H->setDebugLoc(DL);
      Handle = H;
      taint.Tainted.insert(H);
      taint.BirthOrder[H] = taint.NextBirth++;  // BB-order seed → stable Q+Q
      // §5.6: record the handle's LOGICAL width from the classical `cq_theta`
      // operand, on the freshly minted i32 handle, BEFORE the RAUW below
      // launders the theta result's type away. Read later when building a Q+Q
      // control condition (PRD §2.4), where both operands are i32 handles.
      // `abiWidthFromType` returns a stable StringRef literal (no storage
      // lifetime concern).
      taint.HandleWidth[H] = abiWidthFromType(Op->getType());
    }

    CallInst *RyCall = Builder.CreateCall(Ry, {Handle, Angle});
    if (DebugLoc DL = Theta->getDebugLoc())
      RyCall->setDebugLoc(DL);

    // RAUW to the HANDLE (i32) — never to the void ry call (§1, PRD §2.5).
    // The handle's i32 type may differ from the theta result's type; that
    // mismatch is transient and laundered by erasure of the tainted users.
    Theta->replaceAllUsesWith(Handle);
    ToErase.push_back(Theta);
  }

  // --- PHI. Iterate in collection order (collected regardless of taint).
  for (CallInst *Phi : taint.PhiCalls) {
    // In-shadow gate bodies are lowered CONTROLLED by the orchestrator
    // (`lowerControlledRegions`), not here (§1.4). Skip them entirely — do
    // NOT emit an uncontrolled Rz and do NOT erase: `ControlledSubstitution`
    // owns their emit + erase.
    if (plan && plan->InShadow.count(Phi))
      continue;
    Value *Op = Phi->getArgOperand(0);
    Value *Angle = Phi->getArgOperand(1);
    if (taint.Tainted.count(Op)) {
      // Tainted operand → emit uncontrolled rz on the handle. A failed emit
      // (unsupported width) leaves the phi standing for the verifier — do not
      // erase it.
      if (!emitRz(Phi, Op, Angle, wd, /*controlled=*/false, /*flag=*/nullptr))
        continue;
    }
    // Classical operand → no rz (Rz on a basis state is unobservable,
    // PRD §4.1). RAUW the phi result to its operand either way (the
    // quantum value is unchanged at the handle level), then erase.
    Phi->replaceAllUsesWith(Op);
    ToErase.push_back(Phi);
  }

  for (Instruction *I : ToErase)
    I->eraseFromParent();
}

}  // namespace cq
