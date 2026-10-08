// IntrinsicLowering.cpp — lower curated reversible llvm.* idiom intrinsics to
// their cq_template_<op>_<W> additive-producer templates. See header for the
// curated set, the mechanism classes, and the curation guard.

#include "IntrinsicLowering.h"

#include "OpcodeSupport.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"

using namespace llvm;

namespace cq {

namespace {

enum class IntrinKind { Unary, Rotate, Binary, Ternary };

// Curated Intrinsic::ID -> symbol stem (matches the intrinsic_table.yaml `op`,
// dots -> underscores for the saturating family). Empty StringRef = NOT curated.
// EXACT id membership — never a name-prefix match (the cq_theta_evil hazard).
StringRef intrinsicStem(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::bswap:      return "bswap";
  case Intrinsic::bitreverse: return "bitreverse";
  case Intrinsic::fshl:       return "fshl";
  case Intrinsic::fshr:       return "fshr";
  case Intrinsic::ctpop:      return "ctpop";
  case Intrinsic::ctlz:       return "ctlz";
  case Intrinsic::cttz:       return "cttz";
  case Intrinsic::abs:        return "abs";
  case Intrinsic::smin:       return "smin";
  case Intrinsic::smax:       return "smax";
  case Intrinsic::umin:       return "umin";
  case Intrinsic::umax:       return "umax";
  case Intrinsic::uadd_sat:   return "uadd_sat";
  case Intrinsic::usub_sat:   return "usub_sat";
  case Intrinsic::sadd_sat:   return "sadd_sat";
  case Intrinsic::ssub_sat:   return "ssub_sat";
  // p119 (Rule 18) hardware-backed fp-math survivors ONLY. A library function is
  // compiled by SOURCE INJECTION (its body inlines to opcodes) — never by
  // recognizing @llvm.<fn> by name. The sole recognized fp intrinsics are those
  // that codegen to a hardware instruction (or an inline opcode sequence) with NO
  // libcall — they have no injectable body. The transcendentals
  // (sin/cos/tan/asin/…/exp/log/log10) and pow TAIL-CALL a libcall on this target
  // (x86-64+SSE4.1) → LIBRARY functions → removed → they decline loudly without
  // injection. NB the keep/cut line is measured on the PROJECT pipeline: native
  // `clang -O1` with `-fno-math-errno` (the darwin default), where a survivor
  // appears as `@llvm.<fn>` and lowers. On a `-fmath-errno` target clang emits a
  // DIRECT `@sqrt`/`@lrint` libcall instead; since bd 3c6m.72 the libm binder
  // rewrites a TAINTED one to its curated intrinsic (`toCuratedIntrinsic`,
  // LibmBinding.cpp), so it reaches the same route.
  // KEPT: sqrt (sqrtsd) · the rounding family floor/ceil/trunc/round/
  // rint/nearbyint (roundsd / inline) · fabs/copysign (bitmask) · fmin/fmax
  // (minnum/maxnum, inline) · fma+fmuladd (the a*b+c contraction → mulsd+addsd,
  // exactly what injected Horner-poly bodies reduce to — removing it would decline
  // every injected polynomial). minnum/maxnum carry the C99 spelling fmin/fmax;
  // fma and fmuladd BOTH carry the `fma` stem (the trace-only backend does not
  // distinguish must-fuse from may-fuse — a Phase-9 concern).
  case Intrinsic::sqrt:       return "sqrt";
  case Intrinsic::floor:      return "floor";
  case Intrinsic::ceil:       return "ceil";
  case Intrinsic::trunc:      return "trunc";
  case Intrinsic::round:      return "round";
  case Intrinsic::rint:       return "rint";
  case Intrinsic::nearbyint:  return "nearbyint";
  case Intrinsic::fabs:       return "fabs";
  case Intrinsic::minnum:     return "fmin";
  case Intrinsic::maxnum:     return "fmax";
  case Intrinsic::copysign:   return "copysign";
  case Intrinsic::fma:        return "fma";
  case Intrinsic::fmuladd:    return "fma";
  // p119 cross-width rounding survivors: lrint/llrint (round-to-nearest-even)
  // codegen to cvtsd2si (hardware) → KEPT. lround/llround (round-half-away) have
  // no HW fp→int form → libcall → LIBRARY functions → removed. clang -O1 lowers
  // lrint/llrint to `@llvm.<fn>.i64.f<W>` intrinsics recognized here by ID but
  // sharing the cross-width TEMPLATE surface (cq_template_<stem>_<from>_to_<to>).
  case Intrinsic::lrint:      return "lrint";
  case Intrinsic::llrint:     return "llrint";
  // bd 3c6m.71 (owner ruling 2026-10-06, CLAUDE R14 Bennett route): f64 trig
  // and inverse trig lower to ONE backend call; the reference circuits are
  // Bennett.jl soft_sin/cos/tan/asin/acos/atan (contracts in
  // tools/intrinsic_table.yaml).
  // `isBennettF64Intrinsic` restricts these to f64: every other width keeps
  // source injection.
  case Intrinsic::sin:        return "sin";
  case Intrinsic::cos:        return "cos";
  case Intrinsic::tan:        return "tan";
  case Intrinsic::asin:       return "asin";
  case Intrinsic::acos:       return "acos";
  case Intrinsic::atan:       return "atan";
  default:                    return {};
  }
}

// bd 3c6m.2: the cross-width libm rounding family — fp arg → INTEGER result of a
// DIFFERENT width (unlike every same-width fp/idiom row). Lowered to the
// `cq_template_<stem>_<from>_to_<to>` cross-width producer (the CAST naming
// grammar reused, a1/ua1 shapes). EXACT id membership.
bool isCrossWidthLibmIntrinsic(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::lrint:
  case Intrinsic::llrint:
    // p119: lround/llround (round-half-away) → libcall on x86-64 → removed.
    return true;
  default:
    return false;
  }
}

// The 13 curated fp-math survivor IDs (p119, Rule 18): sqrt + the rounding family
// (floor/ceil/trunc/round/rint/nearbyint) + fabs + copysign + fmin/fmax
// (minnum/maxnum) + fma/fmuladd. The transcendentals + pow were removed from THIS
// set (library functions — source-injected, not recognized); the six f64 ones
// that have a Bennett.jl circuit are the separate `isBennettF64Intrinsic` set
// below (bd 3c6m.71). Used ONLY by widthInTableSet to
// admit {f16,f32,f64,f80} PER-ID — never a blanket fp open, so every NON-curated
// fp path keeps the full f64 angle/data fence.
bool isCuratedFpIntrinsic(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::sqrt:
  case Intrinsic::floor: case Intrinsic::ceil:   case Intrinsic::trunc:
  case Intrinsic::round: case Intrinsic::rint:   case Intrinsic::nearbyint:
  case Intrinsic::fabs:
  case Intrinsic::minnum: case Intrinsic::maxnum:
  case Intrinsic::copysign:
  case Intrinsic::fma:   case Intrinsic::fmuladd:
    return true;
  default:
    return false;
  }
}

// bd 3c6m.71: the Bennett-backed transcendentals, admitted at f64 ONLY
// (Bennett.jl has no binary32/x87 soft_sin). PER-ID like the survivors above.
bool isBennettF64Intrinsic(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::sin:  case Intrinsic::cos:  case Intrinsic::tan:
  case Intrinsic::asin: case Intrinsic::acos: case Intrinsic::atan:
    return true;
  default:
    return false;
  }
}

IntrinKind intrinsicKind(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::bswap:
  case Intrinsic::bitreverse:
  case Intrinsic::ctpop:
  case Intrinsic::ctlz:
  case Intrinsic::cttz:
  case Intrinsic::abs:
  // p119 unary fp-math survivors (one fp data handle, no immarg flag): sqrt + the
  // rounding family + fabs; and since bd 3c6m.71 the Bennett-backed f64
  // transcendentals (`isBennettF64Intrinsic`). Every other transcendental is a
  // library function, lifted from injected source.
  case Intrinsic::sqrt:
  case Intrinsic::floor: case Intrinsic::ceil:   case Intrinsic::trunc:
  case Intrinsic::round: case Intrinsic::rint:   case Intrinsic::nearbyint:
  case Intrinsic::fabs:
  case Intrinsic::sin: case Intrinsic::cos:  case Intrinsic::tan:
  case Intrinsic::asin: case Intrinsic::acos: case Intrinsic::atan:
    return IntrinKind::Unary;
  case Intrinsic::fshl:
  case Intrinsic::fshr:
    return IntrinKind::Rotate;
  case Intrinsic::fma:
  case Intrinsic::fmuladd:
    // wd2p: a*b + c. The product pair (arg0,arg1) is commutative; the addend
    // (arg2) is positional. Three data operands, no immarg flag.
    return IntrinKind::Ternary;
  default:
    // smin/smax/umin/umax + *.sat + iw81.4.b binary fp (pow/minnum/maxnum/
    // copysign).
    return IntrinKind::Binary;
  }
}

// min/max and uadd/sadd.sat are commutative (carry qq+hl); usub/ssub.sat are not
// (carry qq+hl+lh). Mirrors the intrinsic_table.yaml `commutative` column.
bool intrinsicCommutative(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::smin:
  case Intrinsic::smax:
  case Intrinsic::umin:
  case Intrinsic::umax:
  case Intrinsic::uadd_sat:
  case Intrinsic::sadd_sat:
  // iw81.4.b: fmin/fmax (llvm.minnum/maxnum) commute (carry qq+hl). pow and
  // copysign are order-sensitive (fall to the default → carry qq+hl+lh).
  case Intrinsic::minnum:
  case Intrinsic::maxnum:
    return true;
  default:
    return false;  // usub_sat / ssub_sat / pow / copysign (order-sensitive)
  }
}

// The intrinsic's result width must be in its table set. The integer idiom rows
// use {i8,i16,i32,i64} (bswap additionally excludes i8 — llvm.bswap needs a
// 16-bit multiple); the iw81.4.b fp-math rows use {f16,f32,f64}. Admission is
// PER-ID: an fp ID admits ONLY fp widths and an integer ID ONLY integer widths —
// NEVER a blanket fp open (that would reopen the f64 angle/data miscompile family
// on every soft-float path). i1, the deferred i128, vector widths, and any
// fp ID outside the curated set are out (a non-curated width => the predicate is
// false => the call rides the loud kMsgUnknownCallee escape decline, never an
// unresolved cq_template_<op>_<W>).
bool widthInTableSet(Intrinsic::ID id, StringRef W) {
  if (isBennettF64Intrinsic(id))
    return W == "f64";
  if (isCuratedFpIntrinsic(id))
    // bd 3c6m.4 admits the long-double width f80 (the survivor `…l` math.h
    // variants: sqrtl/floorl/copysignl/fmal/… lower to `@llvm.<fn>.f80` on
    // x86-64). f128 (the AArch64 `.f128` form) is deferred — not shipped. Still
    // PER-ID and fp-only.
    return W == "f16" || W == "f32" || W == "f64" || W == "f80";
  const bool base = (W == "i8" || W == "i16" || W == "i32" || W == "i64");
  if (id == Intrinsic::bswap)
    return base && W != "i8";
  return base;
}

// Promote `repl` as the lowered replacement for `orig` (the additive producer's
// fresh result handle). Mirrors ArithLowering::promote EXACTLY (the duplicated
// Phase-2 bookkeeping, Increment-A HandleWidth record + R-A erase-scrub).
void promote(Value *repl, Instruction *orig, TaintSet &taint, StringRef W) {
  taint.Tainted.insert(repl);
  taint.Tainted.erase(orig);
  taint.BirthOrder[repl] = taint.NextBirth++;
  taint.HandleWidth.erase(orig);
  if (!W.empty())
    taint.HandleWidth[repl] = W;
}

}  // namespace

bool isCuratedReversibleIntrinsic(const CallInst *CI) {
  const auto *II = dyn_cast<IntrinsicInst>(CI);
  if (!II)
    return false;
  const Intrinsic::ID id = II->getIntrinsicID();
  if (intrinsicStem(id).empty())
    return false;  // not a curated id (e.g. *.with.overflow, exp, memcpy).
                   // NB `sqrt` IS curated (see intrinsicStem above) — it was
                   // added by the iw81.4.b fp-math family AFTER this comment
                   // was first written, and named the wrong example until
                   // bd tkju's prose-vs-code audit caught it.
  // bd 3c6m.2 cross-width libm rounding (lrint/llrint ONLY): fp → int.
  // NOT lround/llround — p119 (Rule 18) removed them as LIBRARY functions
  // (round-half-away has no HW fp→int form → libcall), and
  // isCrossWidthLibmIntrinsic returns true for lrint/llrint alone. The stale
  // `/lround/llround` spelling here was corrected by bd tkju.
  // Accept ONLY the generated cross-width surface — result width i64 (the LP64
  // to-width) AND arg width f32/f64 (the generated `from`s). The arg width is
  // read from the CALLEE'S declared param type (the intrinsic's fixed
  // FunctionType), NEVER the operand value — RotationLowering RAUWs the operand
  // to an i32 handle, but the FunctionType is untouched, so this is laundering-
  // proof and identical at both phases (escape carve + enqueue). A 32-bit-`long`
  // i32 result, or an f16/f128 arg, has no generated template → declines
  // (a phantom-mint fence, Prime Directive).
  if (isCrossWidthLibmIntrinsic(id)) {
    // bd 3c6m.4: lrintl/llrintl/lroundl/llroundl add the long-double source
    // (`@llvm.lrint.i64.f80` on x86-64) alongside f32/f64. f128 deferred.
    const StringRef FromW =
        abiWidthFromType(CI->getFunctionType()->getParamType(0));
    return abiWidthFromType(CI->getType()) == "i64" &&
           (FromW == "f32" || FromW == "f64" || FromW == "f80");
  }
  // Width from the RESULT type (a real iN, never i1-flag) — so E is independent
  // of Increment A's HandleWidth (a compare result is the only i1).
  if (!widthInTableSet(id, abiWidthFromType(CI->getType())))
    return false;
  // fshl/fshr: TWO curated forms, both with a CONSTANT amount (the inverse /
  // uncompute needs the amount statically). A DYNAMIC amount is neither and rides
  // the loud escape decline.
  //   (a) ROTATION (arg0==arg1): the Class-1 bijection, lowered `_hl`.
  //   (b) GENERAL funnel (arg0!=arg1, BOTH data operands runtime values): the
  //       Class-2 `(ix<<16)|(i0>>16)` word-extract idiom, lowered to the ternary
  //       qql producer. A ConstantInt DATA operand is NOT this idiom — instcombine
  //       folds `(C<<n)|(y>>(W-n))` to a plain shl/or, so a funnel with a literal
  //       high/low word never survives to the pass; reject it (→ escape decline).
  //       The remaining tainted-vs-classical-runtime distinction is taint-based and
  //       completed in the rewriter (this predicate is taint-invariant by design —
  //       it is consulted at the escape carve and the enqueue, where no TaintSet is
  //       in scope; the rewriter declines a tainted+classical mix via diagnoseNoTemplate).
  if (id == Intrinsic::fshl || id == Intrinsic::fshr) {
    if (CI->arg_size() != 3 || !isa<ConstantInt>(CI->getArgOperand(2)))
      return false;  // dynamic amount → not curated.
    if (CI->getArgOperand(0) == CI->getArgOperand(1))
      return true;   // (a) rotation form.
    // (b) general funnel: both DATA operands must be runtime (non-ConstantInt).
    if (isa<ConstantInt>(CI->getArgOperand(0)) ||
        isa<ConstantInt>(CI->getArgOperand(1)))
      return false;  // literal high/low word → folded by instcombine → escape.
    return true;
  }
  return true;
}

bool rewriteIntrinsic(CallInst *CI, WidthDispatch &wd, TaintSet &taint) {
  const auto *II = cast<IntrinsicInst>(CI);
  const Intrinsic::ID id = II->getIntrinsicID();
  const StringRef Stem = intrinsicStem(id);
  const StringRef W = abiWidthFromType(CI->getType());
  // Defensive: the driver only enqueues when isCuratedReversibleIntrinsic held,
  // so Stem/W are valid here; bail loudly rather than mint a garbage symbol.
  if (Stem.empty() || W.empty()) {
    diagnoseNoTemplate(CI);
    return false;
  }

  IRBuilder<> Builder(CI);

  if (isCrossWidthLibmIntrinsic(id)) {
    // bd 3c6m.2 cross-width libm rounding (lrint/llrint ONLY, never
    // lround/llround — see isCrossWidthLibmIntrinsic): fp → i64.
    // Reuse the CAST naming grammar cq_template_<stem>_<from>_to_<to> (a1/ua1
    // shapes — the handle is i32 on both sides). `from` is the intrinsic's
    // declared fp param width (laundering-proof — the operand VALUE is a
    // post-RAUW i32 handle, but the FunctionType is not); `to` is the i64 result
    // width `W`. The `_unc` twin (EmitInverse string-append) recomputes
    // round(live fp source) and XORs the i64 out rail to |0> — the Class-2
    // source-liveness model, cross-width and all (bd [libm-namematcher-3c6m2]).
    const StringRef FromW =
        abiWidthFromType(CI->getFunctionType()->getParamType(0));
    if (!(FromW == "f32" || FromW == "f64" || FromW == "f80") || W != "i64") {
      diagnoseNoTemplate(CI);
      return false;
    }
    FunctionCallee Callee = wd.castTemplateFn(Stem, FromW, W);
    CallInst *T = Builder.CreateCall(Callee, {CI->getArgOperand(0)}, "h_intr");
    if (DebugLoc DL = CI->getDebugLoc())
      T->setDebugLoc(DL);
    CI->replaceAllUsesWith(T);
    promote(T, CI, taint, W);
    return true;
  }

  const IntrinKind K = intrinsicKind(id);

  if (K == IntrinKind::Unary) {
    // bswap/bitreverse/ctpop/ctlz/cttz/abs + the iw81.4.b unary fp-math family
    // (sin/cos/.../sqrt/floor/.../fabs) — one data handle (arg 0). The trailing
    // i1 immarg flag of abs/ctlz/cttz (arg 1) is a CONSTANT dropped here (the fp
    // unary intrinsics have no immarg); the lowered op is the TOTAL reversible
    // function, so both fwd and `_unc` use the same total f and the rail zeroes
    // correctly. The angle fence (a tainted fp result reaching a rotation arg-1)
    // is positional and already enforced upstream by declineTaintedAngle, which
    // runs BEFORE lowerOps — see bd [fp-angle-fence-ordering-invariant].
    FunctionCallee Callee = wd.dataTemplateFn(Stem, W, Shape::Unary);
    if (!Callee) {
      diagnoseNoTemplate(CI);
      return false;
    }
    CallInst *T = Builder.CreateCall(Callee, {CI->getArgOperand(0)}, "h_intr");
    if (DebugLoc DL = CI->getDebugLoc())
      T->setDebugLoc(DL);
    CI->replaceAllUsesWith(T);
    promote(T, CI, taint, W);
    return true;
  }

  if (K == IntrinKind::Rotate) {
    Value *P0 = CI->getArgOperand(0);
    Value *P1 = CI->getArgOperand(1);
    Value *Amt = CI->getArgOperand(2);  // ConstantInt (predicate-guaranteed).
    if (P0 == P1) {
      // fshl/fshr ROTATION (arg0==arg1): the single data handle + CONSTANT amount
      // n. Lower to the _hl shape (handle, iN n) — the handle+literal form.
      // Adjoint (Class-1 rotate_back) is the `_inv` twin; whole-DAG reversal is
      // the `_unc` twin (recompute-and-XOR), both in the sibling table.
      FunctionCallee Callee = wd.dataTemplateFn(Stem, W, Shape::HL);
      if (!Callee) {
        diagnoseNoTemplate(CI);
        return false;
      }
      CallInst *T = Builder.CreateCall(Callee, {P0, Amt}, "h_intr");
      if (DebugLoc DL = CI->getDebugLoc())
        T->setDebugLoc(DL);
      CI->replaceAllUsesWith(T);
      promote(T, CI, taint, W);
      return true;
    }
    // fshl/fshr GENERAL funnel (arg0!=arg1): fshl(a,b,n) = (a<<n)|(b>>(W-n)), the
    // `(ix<<16)|(i0>>16)` word-extract idiom. Class-2 additive producer over the
    // ternary qql shape (Rule 14): |a>|b>|0> -> |a>|b>|fshl(a,b,n)>; the void
    // `_unc(out,a,b,n)` recomputes fshl from the still-LIVE a,b,n (source-liveness,
    // Rule 8). ONLY the QQ case (BOTH data operands quantum handles) has a template
    // — a tainted+classical-runtime mix has NO qql shape (the amount is the literal
    // slot; a second literal data operand would be a different, ungenerated shape),
    // so decline it loudly rather than mint a phantom symbol (the SAME pattern as
    // the binary all-classical guard below). The amount
    // n rides the qql literal slot at its own iN width (matching the generated sig).
    const bool P0T = taint.Tainted.count(P0) != 0;
    const bool P1T = taint.Tainted.count(P1) != 0;
    if (!P0T || !P1T) {
      diagnoseNoTemplate(
          CI, (Twine(Stem) + "." + W + " general funnel (non-quantum operand)")
                  .str());
      return false;
    }
    // Operand order is SEMANTIC (a = high word, b = low word) — NEVER canonicalize.
    FunctionCallee Callee = wd.dataTemplateFn(Stem, W, Shape::TernaryQQL);
    if (!Callee) {
      diagnoseNoTemplate(CI);
      return false;
    }
    CallInst *T = Builder.CreateCall(Callee, {P0, P1, Amt}, "h_intr");
    if (DebugLoc DL = CI->getDebugLoc())
      T->setDebugLoc(DL);
    CI->replaceAllUsesWith(T);
    promote(T, CI, taint, W);
    return true;
  }

  if (K == IntrinKind::Ternary) {
    // fma(a,b,c) = a*b + c (and fmuladd — the default -O1 contraction of
    // `a*b+c`). The product pair (arg0,arg1) is COMMUTATIVE; the addend (arg2) is
    // POSITIONAL. Same additive-producer / source-liveness discipline as the
    // binary arm: a fresh out rail is minted; a,b,c stay live so the void
    // `_unc(out,a,b,c)` recomputes a*b+c and XORs the rail to |0⟩ (Rule 8). The
    // angle fence — a tainted fma result reaching a rotation arg-1 — is positional
    // and already declined upstream by declineTaintedAngle (lowerRotations runs
    // before lowerOps), so it never reaches here.
    Value *P0 = CI->getArgOperand(0);
    Value *P1 = CI->getArgOperand(1);
    Value *Add = CI->getArgOperand(2);
    const bool P0T = taint.Tainted.count(P0) != 0;
    const bool P1T = taint.Tainted.count(P1) != 0;
    const bool AddT = taint.Tainted.count(Add) != 0;
    // An all-classical product (taint reaching ONLY via the addend) is the `llq`
    // shape (bd 3c6m.73): `fma(x0, x1, q)` and the -O1 contraction of `x*y + q`
    // with runtime x, y. Both factors pass as literals in source order, never
    // pre-multiplied (fma rounds a*b+c once). With no tainted operand at all there
    // is no handle to read, so decline loudly (defensive: the driver only enqueues
    // a tainted call, and taint reaches it through an operand).
    if (!P0T && !P1T) {
      if (!AddT) {
        diagnoseNoTemplate(CI);
        return false;
      }
      FunctionCallee Callee = wd.dataTemplateFn(Stem, W, Shape::TernaryLLQ);
      if (!Callee) {
        diagnoseNoTemplate(CI);
        return false;
      }
      CallInst *T = Builder.CreateCall(Callee, {P0, P1, Add}, "h_intr");
      if (DebugLoc DL = CI->getDebugLoc())
        T->setDebugLoc(DL);
      CI->replaceAllUsesWith(T);
      promote(T, CI, taint, W);
      return true;
    }
    // Canonicalize the commutative product pair so slot A is ALWAYS a handle: a
    // literal factor moves to slot B; two handles order by BirthOrder (lower → A)
    // for a FileCheck-stable trace (mirrors the binary QQ commutative case). The
    // addend is NEVER folded into the product — it is positional (operand order is
    // semantic for the `+ c` term, exactly like a non-commutative binary).
    Value *A = P0;
    Value *B = P1;
    if (!P0T) {
      A = P1;  // product = (literal, handle) → put the handle first.
      B = P0;
    } else if (P1T) {
      const unsigned BA = taint.BirthOrder.lookup(P0);
      const unsigned BB = taint.BirthOrder.lookup(P1);
      if (BA != 0 && BB != 0 && BB < BA) {
        A = P1;
        B = P0;
      }
    }
    const bool BTainted = taint.Tainted.count(B) != 0;  // B is handle | literal.
    // Shape by (B) × (addend): A is a handle; B/Add are each handle (q) or lit (l).
    Shape ShapeSel;
    if (BTainted && AddT)
      ShapeSel = Shape::TernaryQQQ;
    else if (BTainted && !AddT)
      ShapeSel = Shape::TernaryQQL;
    else if (!BTainted && AddT)
      ShapeSel = Shape::TernaryQLQ;
    else
      ShapeSel = Shape::TernaryQLL;

    FunctionCallee Callee = wd.dataTemplateFn(Stem, W, ShapeSel);
    if (!Callee) {
      diagnoseNoTemplate(CI);
      return false;
    }
    CallInst *T = Builder.CreateCall(Callee, {A, B, Add}, "h_intr");
    if (DebugLoc DL = CI->getDebugLoc())
      T->setDebugLoc(DL);
    CI->replaceAllUsesWith(T);
    promote(T, CI, taint, W);
    return true;
  }

  // Binary (smin/smax/umin/umax + *.sat) — operand classification by taint
  // membership, mirroring ArithLowering::rewriteBinary EXACTLY (additive
  // producer, sources kept live for the recompute `_unc`).
  Value *A = CI->getArgOperand(0);
  Value *B = CI->getArgOperand(1);
  const bool ATainted = taint.Tainted.count(A) != 0;
  const bool BTainted = taint.Tainted.count(B) != 0;
  // Defensive (local safety, not relied-on): the driver only enqueues a TAINTED
  // intrinsic, and a tainted binary intrinsic has >=1 tainted operand (taint
  // reaches it through one). If neither operand is tainted the classification
  // below would mis-pick a handle from a classical operand — bail loudly rather
  // than depend on the distant outer taint gate (OpcodeLowering.cpp:200).
  if (!ATainted && !BTainted) {
    diagnoseNoTemplate(CI);
    return false;
  }
  const bool Commutative = intrinsicCommutative(id);

  Value *Lhs = A;
  Value *Rhs = B;
  Shape ShapeSel;
  if (ATainted && BTainted) {
    // QQ. Commutative: order by BirthOrder (lower -> LHS) for stable traces;
    // non-commutative: preserve source order (operand order is semantic).
    if (Commutative) {
      const unsigned BA = taint.BirthOrder.lookup(A);
      const unsigned BB = taint.BirthOrder.lookup(B);
      if (BA != 0 && BB != 0 && BB < BA) {
        Lhs = B;
        Rhs = A;
      }
    }
    ShapeSel = Shape::QQ;
  } else if (Commutative) {
    // One tainted, commutative -> handle-on-left _hl regardless of source side.
    Lhs = ATainted ? A : B;
    Rhs = ATainted ? B : A;
    ShapeSel = Shape::HL;
  } else if (ATainted) {
    ShapeSel = Shape::HL;  // non-commutative, handle on left, order preserved.
  } else {
    ShapeSel = Shape::LH;  // non-commutative, literal on left, order preserved.
  }

  FunctionCallee Callee = wd.dataTemplateFn(Stem, W, ShapeSel);
  if (!Callee) {
    diagnoseNoTemplate(CI);
    return false;
  }
  CallInst *T = Builder.CreateCall(Callee, {Lhs, Rhs}, "h_intr");
  if (DebugLoc DL = CI->getDebugLoc())
    T->setDebugLoc(DL);
  CI->replaceAllUsesWith(T);
  promote(T, CI, taint, W);
  return true;
}

}  // namespace cq
