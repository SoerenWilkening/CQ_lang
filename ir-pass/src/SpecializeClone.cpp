// SpecializeClone.cpp — clone mechanics + the shared DD-5 mask/mangle helpers
// (`mangleSpecName` / `taintArgMask`, declared in `SpecializePlan.h`).

#include "SpecializeClone.h"

#include "OpcodeSupport.h"  // abiWidthFromType, abiWidthHasReversibleFpCopy
#include "SpecializePlan.h"
#include "TaintPropagation.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/ModRef.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include <vector>

using namespace llvm;

namespace cq {

// Strip the function/return attributes the ORIGINAL pure-classical body carried
// but the quantum-lowered body INVALIDATES. The lowered clone calls side-
// effecting trace-runtime primitives (`cqrt_*` print, `cq_template_*` print,
// `cqrt_free` deallocates a rail) and returns a freshly-allocated `i32` handle —
// so `memory(none)`/`willreturn`/`nofree` (purity) and the return-value `range`
// are now LIES the backend would exploit. The load-bearing case: a void
// uncompute-twin call (`@__cq_q_..._unc`, Phase 6.3) whose result is unused would
// be deleted as a dead "pure willreturn" call, leaving the entangled inner rail
// freed DIRTY — a hidden measurement that collapses the borrowed qubit (Rule
// 6/8). Latent since 6.1 (a forward clone's result is always used, so its call
// survived); the void twin is the first unused-result clone call. Applied to
// every clone AND its twin.
void stripStaleClassicalAttrs(Function *F) {
  F->setMemoryEffects(MemoryEffects::unknown());
  F->removeFnAttr(Attribute::WillReturn);
  F->removeFnAttr(Attribute::NoFree);
  // The uncompute twin retypes the return to VOID, on which NO return attribute
  // is valid — a leaked i32-only `noundef`/`signext`/`zeroext`/`range` (which
  // `CloneFunctionInto` copies verbatim from the forward clone) is a malformed
  // module that aborts `opt -verify` (exit 134) on any inner whose clang return
  // carries one (e.g. `a & 255` → `noundef range`). For a non-void clone the
  // return is a freshly-allocated i32 handle: `noundef`/`signext`/`zeroext` stay
  // valid, but the original value `range` is a lie, so drop just that.
  if (F->getReturnType()->isVoidTy())
    F->setAttributes(F->getAttributes().removeAttributesAtIndex(
        F->getContext(), AttributeList::ReturnIndex));
  else
    F->removeRetAttr(Attribute::Range);
  // A clone returns a fresh copy-out (or void), never literally a borrowed
  // param, so a `returned` param attr is stale — at worst a lie the optimizer
  // would use to substitute the borrowed input handle for the basis copy.
  for (Argument &A : F->args())
    F->removeParamAttr(A.getArgNo(), Attribute::Returned);
}

// `__cq_q_<callee>_<binary>` (DD-5). `<binary>` is `Mask` rendered MSB-first,
// zero-padded to `Callee->arg_size()`, param 0 the RIGHTMOST char — so a 1-arg
// arg0-tainted callee → "1" → `__cq_q_helper_1`, a 2-arg arg0-only call → "01"
// → `__cq_q_ipow_01`, a 3-arg arg0-only call → "001` → `__cq_q_f_001`. The
// padding is load-bearing: an unpadded mask would render `0b001` and `0b1` both
// as "1" and alias different-arity clones under `llvm-link` (DD-5).
std::string mangleSpecName(const Function *Callee, SpecMask Mask) {
  unsigned Arity = Callee->arg_size();
  std::string Bits;
  Bits.reserve(Arity);
  // i = Arity-1 (MSB / highest param index) down to 0 (param 0, rightmost).
  for (unsigned i = Arity; i-- > 0;)
    Bits.push_back((Mask >> i) & 1u ? '1' : '0');
  return ("__cq_q_" + Callee->getName() + "_" + Bits).str();
}

// The §2.2 taint signature: bit i set ⇔ `Site->getArgOperand(i)` is in
// `taint.Tainted` (LSB = param 0). A pure membership test — the per-use
// arg-1-angle exclusion (Rule 3) is already reflected in `taint.Tainted`
// upstream (a value used ONLY as a rotation angle never entered the set). The
// `kSpecMaxArity` cap is enforced by the caller BEFORE masking; this helper
// assumes `arg_size() <= 64` (it reads at most bit 63).
SpecMask taintArgMask(const CallInst *Site, const TaintSet &taint) {
  SpecMask Mask = 0;
  unsigned N = Site->arg_size();
  for (unsigned i = 0; i < N && i < kSpecMaxArity; ++i)
    if (taint.Tainted.count(const_cast<Value *>(Site->getArgOperand(i))))
      Mask |= (SpecMask(1) << i);
  return Mask;
}

// bd 3c6m.54 — the fp-ABI RETURN-taint predictor: does the (single-block, per
// `scanBody`) callee's return value derive from a masked-tainted parameter? A
// pure forward transitive-user closure from the masked params — the EXACT closure
// `seedClone` builds on the clone (isomorphic under the verbatim/remap clone), so
// this reproduces the clone's pre-drain return-taint. It is a sound
// OVER-approximation of the final `ReturnTainted`: the intra-clone inner-call
// scrub (`scrubForwardCone`) only REMOVES taint, so `predict==false` ⟹ the return
// is genuinely classical (never rewritten to i32 → stays fp, returned verbatim),
// while a `predict==true`/`actual==false` mispredict (an inner tainted-arg clone
// that returns classical, feeding the whole return — unreachable in the
// always-inlined census cells, which have no inner calls) is caught by the LOUD
// mispredict guard in `buildClone`, never a silent miscompile.
bool predictReturnTainted(Function *Callee, SpecMask Mask) {
  // Collect the return value(s). Pre-5po2-I1 this read ONLY the entry-block
  // terminator (a single-block callee, guaranteed by `scanBody`). I1 accepts a
  // MULTI-BLOCK value diamond whose `ret` lives in the exit/merge block, NOT the
  // entry terminator (a `br`) — reading the entry terminator alone under-predicts
  // "classical", so `cloneFor` would keep an fp return type while `emitBennettWrap`
  // copies out to an i32 handle: a mistyped `ret` (broken module). Scan ALL blocks
  // and OVER-approximate: predict tainted if ANY reachable return value derives
  // from a masked param. Soundness is one-directional — an over-prediction is
  // caught by the loud mispredict guard in `buildClone`; an UNDER-prediction is
  // the broken module. A single-block callee's entry `ret` is found first, so its
  // result is byte-identical to the pre-I1 behavior.
  SmallPtrSet<Value *, 16> Tainted;
  std::vector<Value *> WL;
  for (Argument &A : Callee->args())
    if ((Mask & (SpecMask(1) << A.getArgNo())) && Tainted.insert(&A).second)
      WL.push_back(&A);
  while (!WL.empty()) {
    Value *V = WL.back();
    WL.pop_back();
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || I->getFunction() != Callee)
        continue;
      if (Tainted.insert(I).second)
        WL.push_back(I);
    }
  }
  // (a) 5po2 I2 (Rule-13 CONFIRMED-finding fix): a return that is CONTROL-DEPENDENT
  //     on a tainted branch — e.g. a CONSTANT returned only on `if(q>C) return K`, or
  //     a merge-phi of constants under a tainted diamond — becomes a TAINTED data-mux
  //     out rail in `lowerCloneSelect`, even though the constant itself is not
  //     param-derived (a constant / const-phi is not a param user, so the forward
  //     closure above never reaches it). UNDER-predicting classical made `cloneFor`
  //     keep the fp return type while `lowerCloneSelect` minted an i32 handle → a
  //     mistyped `ret` (a verify-DIRTY / broken module, exit 134). Over-approximate:
  //     if ANY conditional terminator is tainted (a tainted-controlled diamond),
  //     predict the return tainted. SOUND one-directional — an OVER-prediction is
  //     caught by the `buildClone` fp-mispredict guards (a clean decline); an
  //     UNDER-prediction is the broken module. Affects ONLY the fp-return rewrite
  //     (`cloneFor` calls this solely when the return is a reversible-fp width; an
  //     int/void return never consults it, so this is inert there).
  for (BasicBlock &BB : *Callee) {
    const Instruction *T = BB.getTerminator();
    if (const auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() && Tainted.count(BI->getCondition()))
        return true;
    } else if (const auto *SW = dyn_cast<SwitchInst>(T)) {
      if (Tainted.count(SW->getCondition()))
        return true;
    }
  }
  // (b) the param-derived return (the pre-I2 single-block / straight-line case). A
  //     constant RV is never in `Tainted`, so the `!isa<Constant>` filter is
  //     subsumed by the membership test.
  for (BasicBlock &BB : *Callee)
    if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
      if (Value *RV = R->getReturnValue(); RV && Tainted.count(RV))
        return true;
  return false;
}

// Clone + mangle + internal linkage. Two paths (bd 3c6m.54):
//
//   * VERBATIM (the historical path, byte-identical): when no tainted argument or
//     return needs an fp→i32-handle rewrite (every INTEGER clone), `CloneFunction`
//     copies the callee's signature as-is. The `_q1` suffix is the DD-5
//     `__cq_q_<callee>_<mask>` mangle; `InternalLinkage` keeps it file-local so
//     `llvm-link` of the multi-file program does not export it. Existing integer
//     spec fixtures pin this output.
//
//   * fp-ABI REWRITE: when a tainted argument (or the return) is a reversible-fp
//     width {f16,f32,f64,f80}, the runtime handle is still i32 (Rule 15), so the
//     clone SIGNATURE must carry i32 in those slots. A fresh `Function::Create` +
//     `CloneFunctionInto` remaps each old arg → new arg; a rewritten fp→i32 slot
//     is a CROSS-type operand substitution (untyped, no RAUW assert), laundered
//     when `lowerOps` rewrites the transiently-mistyped fp body ops to i32-handle
//     `cq_template_*` — the SAME transient-mismatch discipline the theta
//     RAUW-to-handle relies on (RotationLowering §1). The return is rewritten to
//     i32 only when `predictReturnTainted` (a classical fp return stays fp and is
//     returned verbatim; the copy width is recovered from the ORIGINAL callee
//     return type in `buildClone`).
Function *cloneFor(const SpecCandidate &Cand) {
  Function *Callee = Cand.Callee;
  LLVMContext &Ctx = Callee->getContext();
  Type *I32 = Type::getInt32Ty(Ctx);

  SmallVector<Type *, 8> ParamTys;
  bool NeedsRewrite = false;
  for (Argument &A : Callee->args()) {
    Type *T = A.getType();
    const bool Tainted = (Cand.Mask & (SpecMask(1) << A.getArgNo())) != 0;
    if (Tainted && abiWidthHasReversibleFpCopy(abiWidthFromType(T))) {
      ParamTys.push_back(I32);  // fp handle → i32 (Rule 15).
      NeedsRewrite = true;
    } else {
      ParamTys.push_back(T);  // classical pass-through / i32 handle — kept.
    }
  }
  Type *RetTy = Callee->getReturnType();
  Type *NewRetTy = RetTy;
  if (abiWidthHasReversibleFpCopy(abiWidthFromType(RetTy)) &&
      predictReturnTainted(Callee, Cand.Mask)) {
    NewRetTy = I32;  // tainted fp return → i32 copy-out handle.
    NeedsRewrite = true;
  }

  if (!NeedsRewrite) {
    ValueToValueMapTy VMap;
    Function *Clone = CloneFunction(Callee, VMap);
    Clone->setName(mangleSpecName(Callee, Cand.Mask));
    Clone->setLinkage(GlobalValue::InternalLinkage);
    stripStaleClassicalAttrs(Clone);
    return Clone;
  }

  FunctionType *FT = FunctionType::get(NewRetTy, ParamTys, /*isVarArg=*/false);
  Function *Clone =
      Function::Create(FT, GlobalValue::InternalLinkage,
                       mangleSpecName(Callee, Cand.Mask), Callee->getParent());
  ValueToValueMapTy VMap;
  auto NewArg = Clone->arg_begin();
  for (Argument &A : Callee->args()) {
    NewArg->setName(A.getName());
    VMap[&A] = &*NewArg;
    ++NewArg;
  }
  SmallVector<ReturnInst *, 1> Returns;
  CloneFunctionInto(Clone, Callee, VMap,
                    CloneFunctionChangeType::LocalChangesOnly, Returns);
  stripStaleClassicalAttrs(Clone);
  // A rewritten (fp→i32) param/return may carry a source type-specific attribute
  // `CloneFunctionInto` copied verbatim; drop the whole attr set on any slot whose
  // type CHANGED so no fp-typed attr rides onto the i32 handle (a malformed-module
  // abort otherwise). Slots left at their original type keep their attrs.
  for (unsigned i = 0, n = Callee->arg_size(); i < n; ++i)
    if (Callee->getArg(i)->getType() != Clone->getArg(i)->getType())
      Clone->setAttributes(Clone->getAttributes().removeParamAttributes(Ctx, i));
  if (NewRetTy != RetTy)
    Clone->setAttributes(Clone->getAttributes().removeAttributesAtIndex(
        Ctx, AttributeList::ReturnIndex));
  // InternalLinkage requires dso_local — set LAST (CloneFunctionInto copies the
  // source function's flags, which for an externally-visible callee are not
  // dso_local). The verbatim CloneFunction path inherits this from the callee.
  Clone->setDSOLocal(true);
  return Clone;
}

}  // namespace cq
