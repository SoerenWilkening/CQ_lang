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
// offending call is left in place to surface at the verifier. The call's
// `!dbg` is attached so the rejection is source-located (same surface as
// `diagnoseUnderControl`).
void diagnoseUnsupported(CallInst *CI, const char *What) {
  std::string Msg = std::string("cq rotation lowering: unsupported ") + What;
  CI->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *CI->getFunction(), Msg, CI->getDebugLoc()));
}

// Straight-line tainted-ANGLE gate (test_C_libtooling-659): quantum-derived
// data in a rotation's arg-1 ANGLE slot has NO fixed unitary — angle =
// f(quantum value), value in superposition — so there is nothing correct to
// emit. The taint discipline keeps the angle operand classical PER-USE (taint
// never propagates THROUGH an arg-1 edge, Rule 3), but the angle VALUE itself
// is tainted when derived from a handle elsewhere (`sitofp(%q)`, `ext(%q)`).
// Two loud-but-wrong outcomes without this guard, both found by the
// test_C_libtooling-9hh §8 adversarial clearance (2026-06-10):
//   (a) cast family — CastLowering cross-type-RAUWs the f64 cast result to an
//       i32 handle inside the already-emitted `cqrt_rz`/`cqrt_ry`, which is
//       FINAL (never erased): Broken module, opt exit 134;
//   (b) opaque-call family — `%ang = call double @ext(i32 %q)` survives
//       well-typed and, after the RAUW-to-handle, reads the i32 RUNTIME
//       HANDLE TAG: a verify-clean silent miscompile.
// The region-level twin is ArmClassify::taintedAngleGate (arms/derived base);
// this is the straight-line root fix: decline loudly BEFORE any emission.
// Returns true (and diagnoses) iff the rotation's angle is tainted.
bool declineTaintedAngle(CallInst *Rot, const TaintSet &taint) {
  if (Rot->arg_size() < 2 || !taint.Tainted.count(Rot->getArgOperand(1)))
    return false;
  diagnoseUnsupported(Rot, "quantum-derived rotation angle");
  return true;
}

// Frozen-quantum-wire guard (test_C_libtooling-4i7r): a tainted `FreezeInst`
// whose result type is NOT `i32` is UN-LAUNDERABLE. The runtime handle is
// ALWAYS i32 (Rule 15); every lowering path RAUWs a tainted quantum value to a
// `cqrt_alloc_*` / `cq_template_*` i32 handle — but a `freeze` is NEVER erased
// by any stage (`declineTaintEscapes` SKIPS an fp freeze so it can ride the
// GATE-3 angle fence; it is never folded). So once the wire under it is
// RAUW'd, `%f = freeze <fp> %handle` is ill-typed AND any `cqrt_*`/`cq_template_*`
// call reading `%f` gets an fp value in an i32 handle slot. With no
// measure/uncompute owner (a dead sibling while the wire is measured/escaped
// elsewhere) NOTHING declines it and `opt` ABORTS on the broken module
// (SIGABRT 134, "Call parameter type does not match function signature")
// instead of the house decline — a crash on VALID input (Rule 1). Scan and
// decline BEFORE the first RAUW so every freeze stays well-typed and `opt`
// exits with the source-located diagnostic, never a crash.
//
// COMPLETENESS: a tainted value derives (transitively) from a `@cq_theta`
// result — the sole taint source — whose lowering yields an i32 handle, so a
// tainted freeze at a non-i32 result type is invariably inconsistent with that
// i32 handle and cannot be lowered. An i32 tainted freeze self-launders
// (`freeze i32 %handle` is well-typed) and is not flagged; a non-i32 INTEGER
// freeze is already declined upstream at `declineTaintEscapes` (kMsgOther, the
// non-foldable `freezeResultWouldEscape` path) so in practice only fp freezes
// reach here — the `!isIntegerTy(32)` test is defensively complete for any
// non-i32 remnant. A CLASSICAL freeze (untainted) is left untouched (its
// operand keeps its own type across every RAUW).
//
// FIXTURE INVARIANT: the SELECT-mediated fp-freeze spellings decline EARLIER at
// `detectControlRegions` (which runs strictly before `lowerRotations`) — the
// kjd1 operand/condition fences (`taintedLineageHasFreeze` + the
// condition-provenance `FreezeInst` scan) and the GATE-3 angle walk
// (`selReachesRotationArg1`) — so this guard NEVER fires on those four fixtures
// (`control_swap_reject_select_fp_freeze_{operand,cond}.ll`,
// `control_swap_reject_select_freeze.ll`,
// `control_swap_reject_freeze_phi_angle.ll`); it owns ONLY the straight-line
// frozen-wire shape the detection fences never see. Walk in BB order for a
// deterministic, source-located first report (the DS_Error diagnose exits).
bool declineFrozenWire(Module &M, const TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *FI = dyn_cast<FreezeInst>(&I))
          if (taint.Tainted.count(FI) && !FI->getType()->isIntegerTy(32)) {
            F.getContext().diagnose(DiagnosticInfoUnsupported(
                F,
                "cq rotation lowering: unsupported frozen quantum wire",
                FI->getDebugLoc()));
            return true;
          }
  }
  return false;
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
  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty())
    return;

  // Frozen-quantum-wire guard (test_C_libtooling-4i7r): decline any tainted
  // non-i32 `freeze` BEFORE the cross-type RAUW-to-handle below breaks it into a
  // verify-clean-invisible SIGABRT. See `declineFrozenWire` for the invariant.
  // The DS_Error diagnose exits `opt` non-zero; return is a belt-and-braces
  // "lower nothing" for any future non-exiting diagnostic handler.
  if (declineFrozenWire(M, taint))
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
    // Quantum-derived angle → loud decline BEFORE any emission (no alloc, no
    // ry); the theta is left standing (test_C_libtooling-659).
    if (declineTaintedAngle(Theta, taint))
      continue;
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
    // `plan->InShadow` names cq_phi gate bodies a control emitter handles
    // itself (so they must NOT be lowered here). For the 4.1 swap-route emitter
    // (`SwapRouteEmit::lowerControlRegions`) this set is EMPTY: that emitter runs
    // BEFORE this pass and ERASES each arm cq_phi (scrubbing it from
    // taint.PhiCalls), so an in-shadow phi never reaches this loop. The guard is
    // retained for forward control work that keeps gate bodies in place (the
    // §6a control-in-place peephole).
    if (plan && plan->InShadow.count(Phi))
      continue;
    Value *Op = Phi->getArgOperand(0);
    Value *Angle = Phi->getArgOperand(1);
    // Quantum-derived angle → loud decline BEFORE any emission, on the
    // classical-operand path too (deleting an Rz whose angle is entangled
    // data would silently drop a quantum-dependent operation; over-declining
    // is safe). The phi is left standing (test_C_libtooling-659).
    if (declineTaintedAngle(Phi, taint))
      continue;
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
