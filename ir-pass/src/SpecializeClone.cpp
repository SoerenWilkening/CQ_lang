// SpecializeClone.cpp — clone mechanics + the shared DD-5 mask/mangle helpers
// (`mangleSpecName` / `taintArgMask`, declared in `SpecializePlan.h`).

#include "SpecializeClone.h"

#include "SpecializePlan.h"
#include "TaintPropagation.h"

#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Transforms/Utils/Cloning.h"

using namespace llvm;

namespace cq {

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
  return Clone;
}

}  // namespace cq
