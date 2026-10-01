// QramIndexWidth.cpp — every QRAM index rail has logical width 32. See the
// header for the contract, the two halves, and why a cast rail must not
// outlive its call.

#include "QramIndexWidth.h"

#include "CompareLowering.h"   // logicalOperandWidth
#include "EmitInverse.h"       // emitInverseCall
#include "OpcodeSupport.h"     // castInScope
#include "TaintPropagation.h"  // TaintSet
#include "WidthDispatch.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"

#include <optional>
#include <string>

using namespace llvm;

namespace cq {

namespace {

// The exact diagnostic this file owns. Its negative fixtures
// (lowering_reject_qram_index_width{,_shadow}.ll) mirror it character-for-
// character.
constexpr char kMsgQramIndexWidth[] =
    "cq QRAM access: index has no cast to the i32 index width";

// The tag a QRAM emitter leaves on its call: !{op, fromW, index slot, forward
// arity}. `emitInverseCall` copies it onto the `_unc` it mints from that call
// (`inheritQramIndexTag`), so every reversal carries ITS OWN forward's decision;
// the arity lets the bracket find the index slot of an out-first load `_unc`.
// Read and dropped by `bracketQramIndexCasts`; it never survives the pass.
constexpr char kTagKind[] = "cq.qram.idxcast";

// The strip + width decision. `Ok` is false when no in-scope cast reaches i32.
struct IndexPlan {
  QramIndex R;
  bool Ok = true;
};

IndexPlan planIndex(Value *GepIdx, TaintSet &taint) {
  IndexPlan P;
  P.R.Idx = GepIdx;
  // GEP sign-extends a narrow index, so a bare narrow index re-extends as
  // `sext`; a stripped widening keeps its own kind.
  Instruction::CastOps ExtOp = Instruction::SExt;
  // Strip the mandatory -O1 widening sext/zext. A one-use cast (the gep was its
  // only user) dies with the gep; otherwise `lowerOps` lowers it for its other
  // users and the source value is still the right index.
  if (auto *CI = dyn_cast<CastInst>(P.R.Idx))
    if ((isa<SExtInst>(CI) || isa<ZExtInst>(CI)) &&
        taint.Tainted.count(CI->getOperand(0))) {
      ExtOp = CI->getOpcode();
      P.R.Idx = CI->getOperand(0);
      if (CI->hasOneUse())
        P.R.DeadCast = CI;
    }
  // The LOGICAL width, read while an IR-typed index still carries it in its
  // type; a laundered i32 handle's `HandleWidth` record wins over its SSA type
  // (a nested QRAM load, a retyped loop-carried φ, an emitter rail).
  StringRef W = logicalOperandWidth(P.R.Idx, taint);
  if (W == "i32")
    return P;
  // Pick the one in-scope cast that reaches i32, asking the cast-scope owner.
  P.R.FromW = W;
  if (castInScope("trunc", W, "i32"))
    P.R.CastOp = "trunc";
  else if (castInScope(Instruction::getOpcodeName(ExtOp), W, "i32"))
    P.R.CastOp = Instruction::getOpcodeName(ExtOp);
  else
    P.Ok = false;
  return P;
}

void diagnoseIndexWidth(Instruction *At) {
  At->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *At->getFunction(), kMsgQramIndexWidth, At->getDebugLoc()));
}

struct Tag {
  std::string Op, FromW;
  unsigned Slot, Arity;
};

std::optional<Tag> readTag(const CallInst *C) {
  MDNode *N = C->getMetadata(kTagKind);
  if (!N || N->getNumOperands() != 4)
    return std::nullopt;
  auto *Op = dyn_cast<MDString>(N->getOperand(0));
  auto *W = dyn_cast<MDString>(N->getOperand(1));
  auto *S = mdconst::dyn_extract<ConstantInt>(N->getOperand(2));
  auto *A = mdconst::dyn_extract<ConstantInt>(N->getOperand(3));
  if (!Op || !W || !S || !A)
    return std::nullopt;
  return Tag{Op->getString().str(), W->getString().str(),
             static_cast<unsigned>(S->getZExtValue()),
             static_cast<unsigned>(A->getZExtValue())};
}

// `t = cast(idx); C(.., t, ..); cast_unc(t, idx); cqrt_free(t)` around `C`'s
// index slot. Only `C` runs between the cast and its `_unc`, and a QRAM call
// only reads its index, so `t` is |0⟩ at the free (Rule 5: provably-|0⟩ only)
// and is never live across any other gate.
bool bracket(CallInst *C, unsigned Slot, const Tag &T, WidthDispatch &wd,
             TaintSet &taint) {
  Value *Idx = C->getArgOperand(Slot);
  if (!Idx->getType()->isIntegerTy(32))
    return false;  // an un-lowered operand: the module already failed loudly.
  IRBuilder<> B(C);
  B.SetCurrentDebugLocation(C->getDebugLoc());
  CallInst *Cast =
      B.CreateCall(wd.castTemplateFn(T.Op, T.FromW, "i32"), {Idx}, "qidx");
  C->setArgOperand(Slot, Cast);
  taint.Tainted.insert(Cast);
  taint.HandleWidth[Cast] = "i32";
  taint.BirthOrder[Cast] = taint.NextBirth++;
  IRBuilder<> A(C->getNextNode());
  A.SetCurrentDebugLocation(C->getDebugLoc());
  if (!emitInverseCall(A, Cast, wd, nullptr, &taint.SpineOps))
    return false;  // unreachable: an uncontrolled cast template always inverts.
  A.CreateCall(wd.freeFn(), {Cast});
  return true;
}

}  // namespace

bool checkQramIndexWidth(Value *GepIdx, Instruction *At, TaintSet &taint) {
  if (planIndex(GepIdx, taint).Ok)
    return true;
  diagnoseIndexWidth(At);
  return false;
}

QramIndex resolveQramIndex(Value *GepIdx, Instruction *At, TaintSet &taint) {
  IndexPlan P = planIndex(GepIdx, taint);
  if (!P.Ok) {
    diagnoseIndexWidth(At);
    return QramIndex{};
  }
  return P.R;
}

void tagQramIndexCast(CallInst *Q, unsigned Slot, const QramIndex &R) {
  if (R.CastOp.empty())
    return;
  LLVMContext &Ctx = Q->getContext();
  Type *I32 = Type::getInt32Ty(Ctx);
  Metadata *Ops[] = {
      MDString::get(Ctx, R.CastOp), MDString::get(Ctx, R.FromW),
      ConstantAsMetadata::get(ConstantInt::get(I32, Slot)),
      ConstantAsMetadata::get(ConstantInt::get(I32, Q->arg_size()))};
  Q->setMetadata(kTagKind, MDNode::get(Ctx, Ops));
}

void inheritQramIndexTag(const CallInst *Forward, CallInst *Inv) {
  if (MDNode *N = Forward->getMetadata(kTagKind))
    Inv->setMetadata(kTagKind, N);
}

void stripForeignQramIndexTags(Module &M) {
  for (Function &F : M)
    for (Instruction &I : instructions(F))
      if (I.getMetadata(kTagKind))
        I.setMetadata(kTagKind, nullptr);
}

bool bracketQramIndexCasts(Module &M, WidthDispatch &wd, TaintSet &taint) {
  // Every tagged call: a forward QRAM call its emitter tagged, or a `_unc`
  // `emitInverseCall` minted from one (same tag). A `_unc` takes its forward's
  // operands, OUT-FIRST for a rail-minting load and SAME-ARGS for a void store,
  // so its index slot is the forward slot shifted by the extra leading operand.
  SmallVector<std::pair<CallInst *, Tag>, 16> Work;
  for (Function &F : M)
    for (Instruction &I : instructions(F))
      if (auto *C = dyn_cast<CallInst>(&I))
        if (auto T = readTag(C)) {
          C->setMetadata(kTagKind, nullptr);
          if (C->arg_size() < T->Arity)
            continue;  // not a QRAM call shape this tag can name.
          T->Slot += C->arg_size() - T->Arity;
          if (T->Slot < C->arg_size())
            Work.push_back({C, *T});
        }
  bool Changed = false;
  for (auto &[C, T] : Work)
    Changed |= bracket(C, T.Slot, T, wd, taint);
  return Changed;
}

}  // namespace cq
