// SpecializeClone.cpp — clone mechanics + the shared DD-5 mask/mangle helpers
// (`mangleSpecName` / `taintArgMask`, declared in `SpecializePlan.h`).

#include "SpecializeClone.h"

#include "SpecializePlan.h"
#include "TaintPropagation.h"

#include "llvm/IR/Attributes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/ModRef.h"
#include "llvm/Transforms/Utils/Cloning.h"

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

// Clone + mangle + internal linkage. Lifted from the archived `cloneAndMangle`
// (`CloneFunction(Orig, VMap)` with an empty `ValueToValueMapTy`), with the
// `_q1` suffix replaced by the DD-5 `__cq_q_<callee>_<mask>` mangle. The clone
// is added to `Callee`'s module by `CloneFunction`; `InternalLinkage` keeps it
// file-local so `llvm-link` of the multi-file program does not export it.
Function *cloneFor(const SpecCandidate &Cand) {
  ValueToValueMapTy VMap;
  Function *Clone = CloneFunction(Cand.Callee, VMap);
  Clone->setName(mangleSpecName(Cand.Callee, Cand.Mask));
  Clone->setLinkage(GlobalValue::InternalLinkage);
  stripStaleClassicalAttrs(Clone);
  return Clone;
}

}  // namespace cq
