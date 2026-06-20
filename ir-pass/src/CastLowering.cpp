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
//
// Phase 7.1 Increment A: `handleWidth` records the lowered handle's LOGICAL
// ABI width on `repl`. For a cast this is the DEST width (`cw.To`) — the
// produced handle logically holds the cast's result, never `cw.From`/i32. R-A
// scrub: `HandleWidth.erase(orig)` mirrors the `Tainted.erase` (stale-on-erase
// guard; verify-clean if a reused address kept the old width). See
// ArithLowering::promote for the rationale.
void promote(Value *repl, Instruction *orig, TaintSet &taint,
             StringRef handleWidth = {}) {
  taint.Tainted.insert(repl);
  taint.Tainted.erase(orig);
  taint.BirthOrder[repl] = taint.NextBirth++;
  taint.HandleWidth.erase(orig);
  if (!handleWidth.empty())
    taint.HandleWidth[repl] = handleWidth;
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
  //
  // Erase-all-users audit vs EMITTER-MINTED FINAL calls (never erased; the
  // test_C_libtooling-659 violation family). A final call can only hold a
  // pending (not-yet-RAUW'd) cast result if it was minted BEFORE this RAUW:
  //   * `cq_template_*` from `lowerOps` itself — safe by program order: the
  //     driver rewrites producers before consumers (SSA dominance + the
  //     single program-order work list), so by emission time every tainted
  //     operand is already the i32 handle.
  //   * `cqrt_measure_<W>` (`lowerMeasures`) and the uncompute adjoints —
  //     minted AFTER `lowerOps`, when every RAUW has settled.
  //   * `cqrt_ry_<W>` / `cqrt_rz_<W>` (`lowerRotations`, runs BEFORE
  //     `lowerOps`) and SwapRouteEmit's replayed rail Rz — the ONLY final
  //     calls minted before this point. Their arg-0 handle slot is
  //     INTENTIONALLY laundered by later RAUWs (it converges to i32); their
  //     arg-1 ANGLE slot must stay floating-point and is exactly what a
  //     cross-type RAUW breaks (Broken module, exit 134). Both emitters now
  //     refuse to mint a call holding a tainted angle:
  //     `RotationLowering::declineTaintedAngle` (straight-line) and
  //     `ArmClassify::taintedAngleGate` (control regions) decline loudly
  //     before any emission — closing the family at the source.
  // A NON-emitter-minted final user (an opaque user call consuming the f64
  // cast result) still violates the invariant, but fails LOUDLY at the
  // verifier (mistyped surviving call), never silently.
  cast->replaceAllUsesWith(T);
  // Record the result handle's LOGICAL width = the cast DEST width (`cw.To`,
  // captured up-front at OpcodeLowering, validated non-empty at :54), NEVER
  // `cw.From` and NEVER the laundered i32 — a downstream Q+Q data compare
  // recovers it (Increment A). E.g. `zext i8->i32` records "i32"; the produced
  // handle logically holds the i32 result.
  promote(T, cast, taint, cw.To);
  return true;
}

}  // namespace cq
