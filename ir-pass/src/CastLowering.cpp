// CastLowering.cpp — per-instruction lowering for tainted `CastInst` over the
// in-scope cast pairs. See header for the cast-width-capture-before-RAUW
// invariant (the single most error-prone point of the phase), the unary
// `(i32)→i32` template shape, and the cross-type RAUW for non-i32 cast
// results. Models its collect-emit-RAUW-bookkeep structure on `ArithLowering`
// / `CompareLowering`; the driver (`OpcodeLowering`) owns collection, the
// up-front width capture, program order, and erase.

#include "CastLowering.h"

#include "OpcodeSupport.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

// Promote `repl` (the i32 handle) into the taint set as the lowered
// replacement for `orig` (the cast), drop `orig`, and give `repl` the next
// BirthOrder slot. Exact Phase-2/ArithLowering/CompareLowering bookkeeping.
// Casts are unary, so there is no operand-ordering concern. The driver erases
// `orig` afterward (we only RAUW + bookkeep here).
void promote(Value *repl, Instruction *orig, TaintSet &taint) {
  taint.Tainted.insert(repl);
  taint.Tainted.erase(orig);
  taint.BirthOrder[repl] = taint.NextBirth++;
}

}  // namespace

bool rewriteCast(CastInst *cast, CastWidths cw, WidthDispatch &wd,
                 TaintSet &taint) {
  // The cast opcode name is the lowercase LLVM mnemonic
  // ("sext"/"zext"/"trunc"/"fpext"/"fptrunc"/"sitofp"/"uitofp"/"fptosi"/
  // "fptoui") — exactly what `castName`/`castInScope` expect.
  StringRef Op = cast->getOpcodeName();

  // Widths come from the driver's COLLECTION-TIME capture (IMPLEMENTATION
  // §1.3 / risk R1), NEVER from `cast->getSrcTy()` at rewrite time: a prior
  // rewrite may have RAUW'd the cast's operand to an i32 handle, which would
  // make `getSrcTy()` read i32 and emit a garbage symbol (e.g.
  // `cq_template_zext_i32_to_i32` for the measured-compare bridge instead of
  // the correct `cq_template_zext_i1_to_i32`). An empty captured width means
  // an unsupported source/dest type (`half`, `i128`, vector) — diagnose and
  // leave un-lowered, same as every other unsupported path.
  if (cw.From.empty() || cw.To.empty()) {
    diagnoseNoTemplate(cast);
    return false;
  }

  // Scope gate: only the in-scope cast pairs (the 68 yaml pairs) have a
  // template. An out-of-scope pair (wrong direction, i1 signed-int domain
  // cross, …) hits the loud diagnostic and is left un-lowered.
  if (!castInScope(Op, cw.From, cw.To)) {
    diagnoseNoTemplate(cast);
    return false;
  }

  FunctionCallee Callee = wd.castTemplateFn(Op, cw.From, cw.To);
  if (!Callee) {
    diagnoseNoTemplate(cast);
    return false;
  }

  IRBuilder<> Builder(cast);
  // The operand is the tainted handle (taint reached this cast through it);
  // the (i32)→i32 template consumes it directly. By rewrite time a prior
  // rewrite may have RAUW'd that operand to an i32 handle even though the
  // cast still nominally reads a narrower/float source — which is exactly why
  // the symbol uses the CAPTURED widths, not the live operand type.
  CallInst *T = Builder.CreateCall(Callee, {cast->getOperand(0)}, "h_cast");
  if (DebugLoc DL = cast->getDebugLoc())
    T->setDebugLoc(DL);
  // The template returns an i32 handle. The original cast's result may be
  // non-i32 (`sitofp i32→f64` → f64, `fptrunc f64→f32` → f32, or i32 for
  // int width casts); RAUW then replaces that SSA value with the i32 handle —
  // a cross-type RAUW laundered by erasure (IMPLEMENTATION §1.2 / risk R2),
  // identical to CompareLowering's i1-flag RAUW. Every user is itself tainted
  // (a measured cast carries a `cqrt_measure_<W>` sink), hence lowered to a
  // call consuming the i32 handle and erased, so the transient mistyped
  // instruction never reaches the verifier (guarded by the per-fixture
  // `verify` RUN line).
  cast->replaceAllUsesWith(T);
  promote(T, cast, taint);
  return true;
}

}  // namespace cq
