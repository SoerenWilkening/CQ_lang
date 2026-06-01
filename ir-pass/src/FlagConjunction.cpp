// FlagConjunction.cpp — see header. Combine two i32 control flags into one
// fresh flag (`&&`/`||`/nesting share this path, PRD §2.5/§2.7), and emit the
// exact mirror-image uncompute. The operand order on every `cqrt_toffoli` /
// `cqrt_x` is correctness-critical and matches the table in the header.

#include "FlagConjunction.h"

#include "ControlledSymbols.h"
#include "WidthDispatch.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

// Mint the fresh combined-flag ancilla `f = cqrt_alloc_i1(0)` (an i32 handle,
// logically |0⟩) at `B`'s insertion point. Returns nullptr if the runtime
// `cqrt_alloc_i1` symbol is unavailable.
Value *allocFreshFlag(WidthDispatch &wd, IRBuilder<> &B) {
  FunctionCallee Alloc = wd.allocFn("i1");
  if (!Alloc)
    return nullptr;
  // `cqrt_alloc_i1(bool value)` → the arg is i1; seed it to false (|0⟩).
  Value *Zero = ConstantInt::getFalse(B.getContext());
  return B.CreateCall(Alloc, {Zero}, "f_conj");
}

}  // namespace

Value *combineFlags(Value *fa, Value *fb, ControlRegion::ConjKind kind,
                    ControlledSymbols &csyms, WidthDispatch &wd,
                    Instruction *before) {
  if (kind == ControlRegion::ConjNone || !fa || !fb || !before)
    return nullptr;

  FunctionCallee Toffoli = csyms.toffoliFn(/*inverse=*/false);
  if (!Toffoli)
    return nullptr;

  IRBuilder<> B(before);
  Value *F = allocFreshFlag(wd, B);
  if (!F)
    return nullptr;

  if (kind == ControlRegion::ConjAnd) {
    // AND: f ← fa ∧ fb directly.
    B.CreateCall(Toffoli, {fa, fb, F});
    return F;
  }

  // OR via De Morgan, a||b = ¬(¬a ∧ ¬b). The X-bracket on fa/fb restores them
  // (so the sub-flags stay clean for their own uncompute); the single X on f
  // turns the AND into the OR.
  FunctionCallee X = csyms.xFn();
  if (!X)
    return nullptr;
  B.CreateCall(X, {fa});
  B.CreateCall(X, {fb});
  B.CreateCall(Toffoli, {fa, fb, F});
  B.CreateCall(X, {F});
  B.CreateCall(X, {fa});
  B.CreateCall(X, {fb});
  return F;
}

void uncombineFlags(Value *fa, Value *fb, Value *f, ControlRegion::ConjKind kind,
                    ControlledSymbols &csyms, Instruction *at) {
  if (kind == ControlRegion::ConjNone || !fa || !fb || !f || !at)
    return;

  FunctionCallee ToffoliInv = csyms.toffoliFn(/*inverse=*/true);
  if (!ToffoliInv)
    return;

  IRBuilder<> B(at);

  if (kind == ControlRegion::ConjAnd) {
    // Exact inverse of the AND compute.
    B.CreateCall(ToffoliInv, {fa, fb, f});
    return;
  }

  // OR uncompute — the mirror image of the De Morgan compute, in reverse:
  //   compute : X(fa); X(fb); toffoli(fa,fb,f); X(f); X(fa); X(fb)
  //   reverse : X(fb); X(fa); X(f); toffoli_inv(fa,fb,f); X(fb); X(fa)
  FunctionCallee X = csyms.xFn();
  if (!X)
    return;
  B.CreateCall(X, {fb});
  B.CreateCall(X, {fa});
  B.CreateCall(X, {f});
  B.CreateCall(ToffoliInv, {fa, fb, f});
  B.CreateCall(X, {fb});
  B.CreateCall(X, {fa});
}

}  // namespace cq
