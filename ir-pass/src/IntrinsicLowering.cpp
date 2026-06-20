// IntrinsicLowering.cpp — lower curated reversible llvm.* idiom intrinsics to
// their cq_template_<op>_<W> additive-producer templates. See header for the
// curated set, the mechanism classes, and the curation guard.

#include "IntrinsicLowering.h"

#include "OpcodeSupport.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
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

enum class IntrinKind { Unary, Rotate, Binary };

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
  default:                    return {};
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
    return IntrinKind::Unary;
  case Intrinsic::fshl:
  case Intrinsic::fshr:
    return IntrinKind::Rotate;
  default:
    return IntrinKind::Binary;  // smin/smax/umin/umax + *.sat
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
    return true;
  default:
    return false;  // usub_sat / ssub_sat (order-sensitive)
  }
}

// The intrinsic's result width must be in its table set. All curated rows use
// {i8,i16,i32,i64}; bswap additionally excludes i8 (llvm.bswap needs a 16-bit
// multiple). i1, the deferred i128, and every fp/vector width are out (a
// non-curated width => the predicate is false => the call rides the loud
// kMsgUnknownCallee escape decline, never an unresolved cq_template_<op>_<W>).
bool widthInTableSet(Intrinsic::ID id, StringRef W) {
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
    return false;  // not a curated id (e.g. *.with.overflow, sqrt, memcpy).
  // Width from the RESULT type (a real iN, never i1-flag) — so E is independent
  // of Increment A's HandleWidth (a compare result is the only i1).
  if (!widthInTableSet(id, abiWidthFromType(CI->getType())))
    return false;
  // fshl/fshr: ONLY the rotation form (arg0==arg1) with a CONSTANT amount is
  // curated. The general (x!=y) funnel shift, and a dynamic rotation amount, are
  // NOT this idiom — fall through to the loud decline.
  if (id == Intrinsic::fshl || id == Intrinsic::fshr) {
    if (CI->arg_size() != 3 ||
        CI->getArgOperand(0) != CI->getArgOperand(1) ||
        !isa<ConstantInt>(CI->getArgOperand(2)))
      return false;
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
  const IntrinKind K = intrinsicKind(id);

  if (K == IntrinKind::Unary) {
    // bswap/bitreverse/ctpop/ctlz/cttz/abs — one data handle (arg 0). The
    // trailing i1 immarg flag of abs/ctlz/cttz (arg 1) is a CONSTANT dropped
    // here: the lowered op is the TOTAL reversible function; both fwd and `_unc`
    // use the same total f, so the rail zeroes correctly.
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
    // fshl/fshr rotation: arg0 (==arg1) is the data handle, arg2 the CONSTANT
    // amount n. Lower to the _hl shape (handle, iN n) — exactly the handle+
    // literal form. Adjoint (Class-1 rotate_back) is the `_inv` twin; whole-DAG
    // reversal is the `_unc` twin (recompute-and-XOR), both in the sibling table.
    FunctionCallee Callee = wd.dataTemplateFn(Stem, W, Shape::HL);
    if (!Callee) {
      diagnoseNoTemplate(CI);
      return false;
    }
    CallInst *T = Builder.CreateCall(
        Callee, {CI->getArgOperand(0), CI->getArgOperand(2)}, "h_intr");
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
