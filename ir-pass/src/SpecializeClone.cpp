// SpecializeClone.cpp — clone mechanics + the shared DD-5 mask/mangle helpers
// (`mangleSpecName` / `taintArgMask`, declared in `SpecializePlan.h`). The
// return-taint predictor (SpecializeClone.h) lives in SpecializePredict.cpp.

#include "SpecializeClone.h"

#include "CalleeBody.h"     // calleeBodyTrusted (bd p3kd.2)
#include "OpcodeSupport.h"  // abiWidthFromType, widthHasReversibleCopy, abiWidthHasReversibleFpCopy
#include "SpecializePlan.h"
#include "TaintPropagation.h"

#include "llvm/ADT/DenseMap.h"
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

bool liftHandleWidth(StringRef W) {
  return widthHasReversibleCopy(W) || abiWidthHasReversibleFpCopy(W);
}

bool liftRetypedWidth(StringRef W) { return W != "i32" && liftHandleWidth(W); }

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
  // A `musttail` marker in the body is a promise about the CLASSICAL body too
  // (bd `test_C_libtooling-m5pn`; the nlfd/ev3m track, 2026-09-28, found by the
  // (null-safe × musttail × recorded-dead × operand) cell table): that the call is
  // the function's last action before `ret`. The lowered clone breaks it — the
  // Bennett wrap puts the copy-out and the reverse of the forward stream BETWEEN an
  // inner clone call and the `ret` — and the verifier then ABORTS the whole run
  // (exit 134, PRE-EXISTING on `main` 9a230646 from plain C: `int h(int a,int k){
  // __attribute__((musttail)) return h2(a,k); }` with `h2` reading `a`). ⚠ Round 1
  // also named "`cloneFor`'s fp→i32 rewrite changes prototypes" as a cause — FALSE
  // on the reachable surface (Rule-13 r1B F-r1B-4, probe `f1`): a retarget to a clone
  // whose return type differs REPLACES the call with a fresh `CreateCall` (no tail
  // kind, `retargetSite`), and an unchanged return type keeps matching prototypes;
  // the fp spelling compiles on the ORACLE byte-identically to its plain-tail one.
  // Code emitted after the call is the one cause. `musttail` guarantees only the
  // tail-call LOWERING (stack reuse) for every argument kind the pass can reach from
  // C: the call, its operands and its result are unchanged by dropping it, and a
  // clone is acyclic (recursion is declined), so no stack guarantee is
  // load-bearing. ⚠ NOT for a `preallocated` argument (legal only on a `musttail`
  // call or with the `"preallocated"` bundle — the demotion would leave the verifier
  // aborting): `scanBody` DECLINES a lifted body that `musttail`-forwards one (r1B
  // F-r1B-2, IR-only — the 32-bit Windows C++ ABI), so none reaches this loop. NOR
  // for an `inalloca` argument (owner ruling 2026-10-05, bd dm7f.5 review round 2,
  // superseding the 2026-09-29 invariant this comment used to state — "an
  // `inalloca` forward IS demoted and is then byte-identical to its plain-`tail`
  // spelling"): that plain spelling is itself invalid (LangRef: off `musttail`, an
  // `inalloca` operand must be the `alloca` set up for the call), merely
  // verifier-clean, so `scanBody` declines it through the same shared predicate,
  // `mustTailForwardBlocksDemotion`. The demotion goes to NO tail kind at all: a
  // clone promises nothing it cannot prove.
  for (BasicBlock &BB : *F)
    for (Instruction &I : BB)
      if (auto *CI = dyn_cast<CallInst>(&I); CI && CI->isMustTailCall())
        CI->setTailCallKind(CallInst::TCK_None);
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

// Clone + mangle + internal linkage, VERBATIM: `CloneFunction` copies the
// callee's signature as-is. The `_q1` suffix is the DD-5 `__cq_q_<callee>_<mask>`
// mangle; `InternalLinkage` keeps it file-local so `llvm-link` of the
// multi-file program does not export it.
//
// bd p3kd.7.8 (owner ruling owner-ruling-clone-pipeline-q1q2-2026-10-07): a
// tainted fp param or return is NOT retyped here any more. The clone keeps its
// fp signature while main's stage list runs on it (`lowerCloneControl`), so every
// stage reads well-typed IR; `retypeCloneSignature` installs the i32-handle
// signature afterwards. Retyping first left `fadd i32`, `fcmp oeq i32` and
// `bitcast i32 to i64` in the body, which PredMux's condition grammar refused
// (measured, docs/design/clone-one-pipeline.md).
Function *cloneFor(const SpecCandidate &Cand) {
  ValueToValueMapTy VMap;
  Function *Clone = CloneFunction(Cand.Callee, VMap);
  Clone->setName(mangleSpecName(Cand.Callee, Cand.Mask));
  Clone->setLinkage(GlobalValue::InternalLinkage);
  stripStaleClassicalAttrs(Clone);
  return Clone;
}

// The handle-ABI signature (bd 3c6m.54 for fp, bd p3kd.9 for the non-i32 integer
// widths): a tainted argument (or the return) at a retyped lift-boundary width
// (`liftRetypedWidth`: i1/i8/i16/i64 and f16/f32/f64/f80) is an i32 runtime handle
// (Rule 15), so the clone's SIGNATURE carries i32 in those slots. The return is
// rewritten only when `predictReturnTainted` (a classical return stays at its
// width and is returned verbatim; the copy width is recovered from the ORIGINAL
// callee return type in `buildClone`).
//
// The new function takes the old one's place in the module's function list (so
// the printed module order is unchanged), its name, attributes and metadata,
// and the old body by `splice` (every instruction keeps its identity, so taint
// keyed on body values stays valid). A rewritten fp->i32 or iN->i32 slot is a
// CROSS-type operand substitution (`Use::set`, untyped, no RAUW assert), laundered
// when `lowerOps` rewrites the transiently-mistyped body ops to i32-handle
// `cq_template_*`: the SAME transient-mismatch discipline the theta
// RAUW-to-handle relies on (RotationLowering §1, where an `i64` theta result is
// replaced by its i32 handle the same way), and the state `cloneFor` produced
// before bd p3kd.7.8. Returns `Clone` itself when no slot changes.
Function *retypeCloneSignature(Function *Clone, const SpecCandidate &Cand) {
  Function *Callee = Cand.Callee;
  LLVMContext &Ctx = Callee->getContext();
  Type *I32 = Type::getInt32Ty(Ctx);

  SmallVector<Type *, 8> ParamTys;
  bool NeedsRewrite = false;
  for (Argument &A : Clone->args()) {
    Type *T = A.getType();
    const bool Tainted = (Cand.Mask & (SpecMask(1) << A.getArgNo())) != 0;
    if (Tainted && liftRetypedWidth(abiWidthFromType(T))) {
      ParamTys.push_back(I32);  // fp / iN handle → i32 (Rule 15).
      NeedsRewrite = true;
    } else {
      ParamTys.push_back(T);  // classical pass-through / i32 handle — kept.
    }
  }
  Type *RetTy = Clone->getReturnType();
  Type *NewRetTy = RetTy;
  if (liftRetypedWidth(abiWidthFromType(RetTy)) &&
      predictReturnTainted(Callee, Cand.Mask)) {
    NewRetTy = I32;  // tainted fp / iN return → i32 copy-out handle.
    NeedsRewrite = true;
  }
  if (!NeedsRewrite)
    return Clone;

  FunctionType *FT = FunctionType::get(NewRetTy, ParamTys, /*isVarArg=*/false);
  Function *New = Function::Create(FT, Clone->getLinkage(),
                                   Clone->getAddressSpace());
  Clone->getParent()->getFunctionList().insert(Clone->getIterator(), New);
  New->takeName(Clone);
  New->copyAttributesFrom(Clone);
  New->copyMetadata(Clone, 0);
  New->splice(New->begin(), Clone);
  for (unsigned i = 0, n = Clone->arg_size(); i < n; ++i) {
    Argument *OldA = Clone->getArg(i);
    Argument *NewA = New->getArg(i);
    NewA->takeName(OldA);
    if (OldA->getType() == NewA->getType()) {
      OldA->replaceAllUsesWith(NewA);
      continue;
    }
    SmallVector<Use *, 8> Uses;
    for (Use &U : OldA->uses())
      Uses.push_back(&U);
    for (Use *U : Uses)
      U->set(NewA);  // cross-type: see the header comment.
  }
  // A rewritten (fp→i32 / iN→i32) param/return may carry a source type-specific
  // attribute (`nofpclass`, a `range(i64 …)`, `signext`/`zeroext` on an i8/i16, …)
  // `copyAttributesFrom` copied verbatim; drop the whole attr set on any slot whose
  // type CHANGED so no source-typed attr rides onto the i32 handle (a
  // malformed-module abort otherwise). Slots left at their original type keep
  // their attrs.
  for (unsigned i = 0, n = Clone->arg_size(); i < n; ++i)
    if (Clone->getArg(i)->getType() != New->getArg(i)->getType())
      New->setAttributes(New->getAttributes().removeParamAttributes(Ctx, i));
  if (NewRetTy != RetTy)
    New->setAttributes(New->getAttributes().removeAttributesAtIndex(
        Ctx, AttributeList::ReturnIndex));
  New->setDSOLocal(true);
  Clone->eraseFromParent();
  return New;
}

}  // namespace cq
