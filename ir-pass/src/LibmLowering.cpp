// LibmLowering.cpp — lower curated DIRECT-libm math.h calls to their
// cq_template_<…> additive-producer templates. See header for the curated set,
// the shape classes, and why recognition is by EXACT function NAME (never a
// prefix — the cq_theta_evil hazard).

#include "LibmLowering.h"

#include "OpcodeSupport.h"
#include "TaintPropagation.h"
#include "TemplateName.h"
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

enum class LibmKind { SameUnary, SameBinary, CrossUnary, MixedBinary };

// One curated libm function. `stem` is the SYMBOL stem (matches the
// libm_table.yaml `op`). `nameF64`/`nameF32` are the EXACT C spellings the
// recognizer matches (the double form and the `…f` float form). For SameBinary,
// `commutative` selects the qq+hl vs qq+hl+lh grid. For CrossUnary/MixedBinary,
// `intW` is the integer width the shape hinges on (CrossUnary: the result `to`
// width; MixedBinary: the arg-1 exponent width `wb`).
struct LibmDesc {
  StringRef nameF64;
  StringRef nameF32;
  StringRef nameLd;  // the `…l` long-double spelling (bd 3c6m.4). f80 on x86-64.
  StringRef stem;
  LibmKind kind;
  bool commutative;
  StringRef intW;  // CrossUnary: to-width; MixedBinary: wb-width; else "".
};

// The curated table. Mirrors tools/libm_table.yaml EXACTLY (minus the
// lrint/llrint/lround/llround cross-width family, which clang intrinsifies and
// IntrinsicLowering owns). EXACT-name membership — the recognizer matches a call
// name against `nameF64` OR `nameF32`, never a prefix.
const LibmDesc kLibmTable[] = {
    // same_unary (fp → fp):
    {"cbrt",   "cbrtf",   "cbrtl",   "cbrt",   LibmKind::SameUnary, false, ""},
    {"erf",    "erff",    "erfl",    "erf",    LibmKind::SameUnary, false, ""},
    {"erfc",   "erfcf",   "erfcl",   "erfc",   LibmKind::SameUnary, false, ""},
    {"tgamma", "tgammaf", "tgammal", "tgamma", LibmKind::SameUnary, false, ""},
    {"lgamma", "lgammaf", "lgammal", "lgamma", LibmKind::SameUnary, false, ""},
    {"expm1",  "expm1f",  "expm1l",  "expm1",  LibmKind::SameUnary, false, ""},
    {"log1p",  "log1pf",  "log1pl",  "log1p",  LibmKind::SameUnary, false, ""},
    {"logb",   "logbf",   "logbl",   "logb",   LibmKind::SameUnary, false, ""},
    {"acosh",  "acoshf",  "acoshl",  "acosh",  LibmKind::SameUnary, false, ""},
    {"asinh",  "asinhf",  "asinhl",  "asinh",  LibmKind::SameUnary, false, ""},
    {"atanh",  "atanhf",  "atanhl",  "atanh",  LibmKind::SameUnary, false, ""},
    // same_binary (fp,fp → fp):
    {"hypot",     "hypotf",     "hypotl",     "hypot",     LibmKind::SameBinary, true,  ""},
    {"atan2",     "atan2f",     "atan2l",     "atan2",     LibmKind::SameBinary, false, ""},
    {"remainder", "remainderf", "remainderl", "remainder", LibmKind::SameBinary, false, ""},
    {"nextafter", "nextafterf", "nextafterl", "nextafter", LibmKind::SameBinary, false, ""},
    {"fdim",      "fdimf",      "fdiml",      "fdim",      LibmKind::SameBinary, false, ""},
    // cross_unary (fp → int):
    {"ilogb", "ilogbf", "ilogbl", "ilogb", LibmKind::CrossUnary, false, "i32"},
    // mixed_binary ((fp, int) → fp):
    {"ldexp",   "ldexpf",   "ldexpl",   "ldexp",   LibmKind::MixedBinary, false, "i32"},
    {"scalbn",  "scalbnf",  "scalbnl",  "scalbn",  LibmKind::MixedBinary, false, "i32"},
    {"scalbln", "scalblnf", "scalblnl", "scalbln", LibmKind::MixedBinary, false, "i64"},
};

// The curated descriptor for `CI`, or nullptr. Requires a DIRECT call to a
// DECLARATION-only libc extern with NO operand bundles (the printf/putchar carve
// precedent — an `invoke`/indirect/in-module-body/operand-bundle form is NOT
// this idiom). EXACT-name match against BOTH spellings — never a prefix.
const LibmDesc *lookupLibm(const CallInst *CI) {
  if (CI->hasOperandBundles())
    return nullptr;
  const Function *Callee = CI->getCalledFunction();
  if (!Callee || !Callee->isDeclaration() || Callee->isIntrinsic())
    return nullptr;
  const StringRef N = Callee->getName();
  for (const LibmDesc &D : kLibmTable)
    if (N == D.nameF64 || N == D.nameF32 || N == D.nameLd)
      return &D;
  return nullptr;
}

// The logical ABI widths come from the CALLEE's declared FunctionType (the libc
// prototype), NEVER from the operand VALUES. This is the crux of the phase-
// safety: RotationLowering RAUWs a tainted operand to an i32 handle (theta alloc
// / arith template result), but that rewrites the operand VALUE, not the
// callee's FunctionType — so a param/return width read here is IDENTICAL at BOTH
// phases `isLibmCall` runs (the escape carve PRE-lowering, and the OpcodeLowering
// enqueue/rewrite POST-RotationLowering). No HandleWidth recovery, no phase
// dependence, no carve/emitter drift. (Casts must use HandleWidth because a cast
// has no callee to read a stable source width from — the operand type IS the
// source; a call does not.) The TEMPLATE operand types (i32 handle for a tainted
// operand, the real type for a classical one) are read separately from the
// actual call operands at emit — these widths only NAME the symbol.
StringRef paramW(const CallInst *CI, unsigned i) {
  return abiWidthFromType(CI->getFunctionType()->getParamType(i));
}
StringRef retW(const CallInst *CI) {
  return abiWidthFromType(CI->getFunctionType()->getReturnType());
}

// bd 3c6m.4 admits the long-double width f80 (the `…l` spellings). A
// same/cross/mixed libm call at long-double width lowers exactly like its
// f32/f64 sibling — the width only NAMES the template symbol. f128 (AArch64
// long double) is deferred; a tainted fp128 libm call declines upstream
// (abiWidthFromType returns "" for fp128, so retW/paramW here are "").
bool isFpWidth(StringRef W) {
  return W == "f32" || W == "f64" || W == "f80";
}

// Promote `repl` as the lowered replacement for `orig`. Mirrors
// IntrinsicLowering::promote / ArithLowering::promote EXACTLY (the duplicated
// Phase-2 bookkeeping: taint move, BirthOrder seed, HandleWidth record + erase-
// scrub). `W` is the RESULT handle's logical width.
void promote(Value *repl, Instruction *orig, TaintSet &taint, StringRef W) {
  taint.Tainted.insert(repl);
  taint.Tainted.erase(orig);
  taint.BirthOrder[repl] = taint.NextBirth++;
  taint.HandleWidth.erase(orig);
  if (!W.empty())
    taint.HandleWidth[repl] = W;
}

}  // namespace

bool isLibmCall(const CallInst *CI) {
  const LibmDesc *D = lookupLibm(CI);
  if (!D)
    return false;
  const FunctionType *FT = CI->getFunctionType();
  if (FT->isVarArg())
    return false;  // a vararg prototype is not the fixed-arity libm signature.
  const StringRef RW = retW(CI);

  switch (D->kind) {
  case LibmKind::SameUnary:
    // fp → fp of the SAME width ∈ {f32,f64}. `<op>f`=f32, `<op>`=f64.
    return FT->getNumParams() == 1 && isFpWidth(RW) && paramW(CI, 0) == RW;
  case LibmKind::SameBinary:
    // (fp,fp) → fp, all the SAME fp width.
    return FT->getNumParams() == 2 && isFpWidth(RW) && paramW(CI, 0) == RW &&
           paramW(CI, 1) == RW;
  case LibmKind::CrossUnary:
    // fp → integer `to` width. Names `cq_template_<op>_<from>_to_<to>`.
    return FT->getNumParams() == 1 && RW == D->intW &&
           isFpWidth(paramW(CI, 0));
  case LibmKind::MixedBinary:
    // (fp, int) → fp: arg0 the fp (result width `wa`), arg1 the integer `wb`.
    return FT->getNumParams() == 2 && isFpWidth(RW) && paramW(CI, 0) == RW &&
           paramW(CI, 1) == D->intW;
  }
  return false;
}

bool rewriteLibmCall(CallInst *CI, WidthDispatch &wd, TaintSet &taint) {
  const LibmDesc *D = lookupLibm(CI);
  if (!D) {  // defensive — driver only enqueues when isLibmCall held.
    diagnoseNoTemplate(CI);
    return false;
  }
  const StringRef ResultW = retW(CI);  // == CI->getType(); not laundered at emit.
  IRBuilder<> Builder(CI);

  if (D->kind == LibmKind::SameUnary) {
    // One fp data handle (arg 0). The angle fence (a tainted result reaching a
    // rotation arg-1) is positional and enforced upstream by declineTaintedAngle.
    FunctionCallee Callee = wd.dataTemplateFn(D->stem, ResultW, Shape::Unary);
    if (!Callee) {
      diagnoseNoTemplate(CI);
      return false;
    }
    CallInst *T = Builder.CreateCall(Callee, {CI->getArgOperand(0)}, "h_libm");
    if (DebugLoc DL = CI->getDebugLoc())
      T->setDebugLoc(DL);
    CI->replaceAllUsesWith(T);
    promote(T, CI, taint, ResultW);
    return true;
  }

  if (D->kind == LibmKind::CrossUnary) {
    // fp → int. Reuse the CAST naming grammar cq_template_<stem>_<from>_to_<to>
    // (a1/ua1 shapes — the handle is i32 on both sides). `from` is the operand's
    // logical fp width; `to` is the integer result width. The `_unc` twin
    // (EmitInverse string-append) recomputes f(live fp source) and XORs the int
    // out rail to |0> — the Class-2 source-liveness model, cross-width and all.
    const StringRef FromW = paramW(CI, 0);  // callee param — never laundered.
    if (!isFpWidth(FromW) || ResultW != D->intW) {
      diagnoseNoTemplate(CI);
      return false;
    }
    FunctionCallee Callee = wd.castTemplateFn(D->stem, FromW, ResultW);
    CallInst *T = Builder.CreateCall(Callee, {CI->getArgOperand(0)}, "h_libm");
    if (DebugLoc DL = CI->getDebugLoc())
      T->setDebugLoc(DL);
    CI->replaceAllUsesWith(T);
    promote(T, CI, taint, ResultW);
    return true;
  }

  if (D->kind == LibmKind::MixedBinary) {
    // (fp, int) → fp. arg0 is the fp (width wa = ResultW), arg1 the integer
    // exponent (fixed width wb). NON-commutative — operand ORDER preserved. Shape
    // by which operand is tainted; the classical operand's C type is per-shape
    // (hl carries the int wb, lh carries the fp wa), which the FunctionType built
    // from the ACTUAL operand LLVM types reproduces exactly (matching the
    // generated cq_template_<stem>_<wa>_<wb>[_hl|_lh] signature).
    Value *A = CI->getArgOperand(0);  // fp.
    Value *B = CI->getArgOperand(1);  // int exponent.
    const bool AT = taint.Tainted.count(A) != 0;
    const bool BT = taint.Tainted.count(B) != 0;
    StringRef Suffix;
    if (AT && BT)
      Suffix = "";  // QQ (bare base symbol).
    else if (AT)
      Suffix = "_hl";  // fp handle, int literal.
    else if (BT)
      Suffix = "_lh";  // fp literal, int handle.
    else {  // neither tainted — not a lowerable shape (defensive; not enqueued).
      diagnoseNoTemplate(CI);
      return false;
    }
    std::string Name =
        ("cq_template_" + D->stem + "_" + ResultW + "_" + D->intW + Suffix)
            .str();
    // FunctionType from the actual operand types → i32 handle result. HL:
    // (i32 handle, <wb> lit); LH: (<wa> lit, i32 handle); QQ: (i32, i32).
    FunctionType *FT = FunctionType::get(
        Type::getInt32Ty(CI->getContext()), {A->getType(), B->getType()},
        /*isVarArg=*/false);
    FunctionCallee Callee = CI->getModule()->getOrInsertFunction(Name, FT);
    CallInst *T = Builder.CreateCall(Callee, {A, B}, "h_libm");
    if (DebugLoc DL = CI->getDebugLoc())
      T->setDebugLoc(DL);
    CI->replaceAllUsesWith(T);
    promote(T, CI, taint, ResultW);
    return true;
  }

  // SameBinary (fp,fp) → fp — operand classification by taint membership,
  // mirroring IntrinsicLowering::rewriteBinary / ArithLowering EXACTLY (additive
  // producer, both sources kept live for the recompute `_unc`).
  Value *A = CI->getArgOperand(0);
  Value *B = CI->getArgOperand(1);
  const bool AT = taint.Tainted.count(A) != 0;
  const bool BT = taint.Tainted.count(B) != 0;
  if (!AT && !BT) {  // defensive — a tainted binary has ≥1 tainted operand.
    diagnoseNoTemplate(CI);
    return false;
  }
  Value *Lhs = A;
  Value *Rhs = B;
  Shape ShapeSel;
  if (AT && BT) {
    // QQ. Commutative: order by BirthOrder (lower → LHS) for a stable trace;
    // non-commutative: preserve source order (operand order is semantic).
    if (D->commutative) {
      const unsigned BA = taint.BirthOrder.lookup(A);
      const unsigned BB = taint.BirthOrder.lookup(B);
      if (BA != 0 && BB != 0 && BB < BA) {
        Lhs = B;
        Rhs = A;
      }
    }
    ShapeSel = Shape::QQ;
  } else if (D->commutative) {
    // One tainted, commutative → handle-on-left `_hl` regardless of source side.
    Lhs = AT ? A : B;
    Rhs = AT ? B : A;
    ShapeSel = Shape::HL;
  } else if (AT) {
    ShapeSel = Shape::HL;  // non-commutative, handle on left, order preserved.
  } else {
    ShapeSel = Shape::LH;  // non-commutative, literal on left, order preserved.
  }
  FunctionCallee Callee = wd.dataTemplateFn(D->stem, ResultW, ShapeSel);
  if (!Callee) {
    diagnoseNoTemplate(CI);
    return false;
  }
  CallInst *T = Builder.CreateCall(Callee, {Lhs, Rhs}, "h_libm");
  if (DebugLoc DL = CI->getDebugLoc())
    T->setDebugLoc(DL);
  CI->replaceAllUsesWith(T);
  promote(T, CI, taint, ResultW);
  return true;
}

}  // namespace cq
