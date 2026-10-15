// InPlaceQQ.cpp — see the header (bd test_C_libtooling-r2j3.33, dm7f.51 step 1).

#include "InPlaceQQ.h"

#include "ArithLowering.h"     // inPlacePositionHolds (the ONE positional fence)
#include "ChainWalk.h"         // isNonPermutationMove
#include "MergeStreamGates.h"  // streamGateWrites
#include "WireWalk.h"          // provablyBefore
#include "TaintPropagation.h"  // TaintSet
#include "TemplateName.h"      // dataName — the ONE builder of the QQ symbol
#include "Uncomputation.h"     // planInteriorDischarges
#include "WidthDispatch.h"     // qqInPlaceFn

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq {

const char kMsgInPlaceQQRefused[] =
    "cq in-place lowering: quantum reassignment of a dead register is not "
    "provable in place";

bool isInPlaceQQSymbol(StringRef N) {
  for (StringRef Stem : {"cqrt_xor_", "cqrt_add_", "cqrt_sub_"})
    if (N.consume_front(Stem))
      return N == "i8" || N == "i16" || N == "i32" || N == "i64";
  return false;
}

bool isInPlaceQQGate(const CallInst *G) {
  if (!G || !G->getMetadata(kInPlaceQQTag))
    return false;
  const Function *Callee = G->getCalledFunction();
  if (!Callee || !G->getType()->isVoidTy() || G->arg_size() != 2)
    return false;
  StringRef N = Callee->getName();
  if (N != "cqrt_cnot" && !isInPlaceQQSymbol(N))
    return false;
  for (const Use &A : G->args())
    if (!A.get()->getType()->isIntegerTy(32))
      return false;
  return G->getArgOperand(0) != G->getArgOperand(1);
}

namespace {

// A QQ site: an out-of-place `cq_template_{xor,add,sub}_<W>(a, b)` THIS pass
// minted in `rewriteBinary` (it has a `HandleWidth` record — a clone body's
// templates live in their own TaintSet and are skipped), both operands quantum.
struct Site {
  CallInst *C = nullptr;
  StringRef Stem, W;
  unsigned Mask = 0;
};

bool qqShape(CallInst *C, const TaintSet &taint, Site &S) {
  const Function *Callee = C->getCalledFunction();
  if (!Callee || C->arg_size() != 2 || C->getType()->isVoidTy())
    return false;
  StringRef N = Callee->getName();
  if (!N.starts_with("cq_template_"))
    return false;
  StringRef W = taint.HandleWidth.lookup(C);
  if (W.empty())
    return false;
  for (StringRef Stem : {"xor", "add", "sub"}) {
    if (N != StringRef(dataName(Stem, W, Shape::QQ)))
      continue;
    if (!taint.Tainted.count(C->getArgOperand(0)) ||
        !taint.Tainted.count(C->getArgOperand(1)))
      return false;
    S.C = C;
    S.Stem = Stem;
    S.W = W;
    S.Mask = deadOperandMask(C);
    return true;
  }
  return false;
}

// Is `P`'s rail user data the spine never discharges? It carries a
// non-permutation move (Ry or controlled Ry) — `isNonPermutationMove`, asked.
bool railIsUserData(const Value *P) {
  for (const User *U : P->users())
    if (const auto *G = dyn_cast<CallInst>(U); G && isNonPermutationMove(G, P))
      return true;
  return false;
}

// Does gate `W` WRITE rail `V`? Asked of the owners, never re-spelt (R12): an
// in-place gate on `V` (`isInPlaceGateOn`, which includes a converted target),
// or a merge-stream permutation gate with `V` in a slot it writes
// (`streamGateWrites`: cnot/toffoli targets, `cqrt_x`, copy destinations).
bool writesRail(const CallInst *W, const Value *V) {
  if (isInPlaceGateOn(W, V))
    return true;
  SmallVector<unsigned, 2> Slots;
  if (!streamGateWrites(W, Slots))
    return false;
  for (unsigned S : Slots)
    if (W->getArgOperand(S) == V)
      return true;
  return false;
}

bool dependsOnTarget(Value *S, const Value *P, const Instruction *Site,
                     const DominatorTree &DT) {
  SmallVector<Value *, 16> Work{S};
  SmallPtrSet<Value *, 32> Seen;
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (V == P)
      return true;
    if (!Seen.insert(V).second || isa<Constant>(V))
      continue;
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;
    for (Value *Op : I->operands())
      if (!isa<BasicBlock>(Op) && !isa<Function>(Op))
        Work.push_back(Op);
    for (User *U : V->users()) {
      auto *W = dyn_cast<CallInst>(U);
      if (!W || W == Site || !provablyBefore(W, Site, DT) ||
          !writesRail(W, V))
        continue;  // only a gate WRITING this rail, before the site, feeds it.
      for (Value *Op : W->args())
        if (Op != V)
          Work.push_back(Op);
    }
  }
  return false;
}

// Does the out-of-place RESULT `R` SURVIVE — is its value kept by the program
// rather than a temporary the compiler returns to |0⟩ after its last reader?
// It survives when it is observed (measured, taped), moved by a non-permutation
// gate (an Ry on it: user data from then on), routed or escaped by a non-call
// user, or continued as the DEAD operand of a later QQ template whose result
// survives (a chain `t ^= a; t ^= b`: the first result lives on in the second).
// A result only READ by forward producers is a temporary: out of place is then
// exactly in-place followed by its own adjoint at the result's death, which is
// what the dead-record ruling asks of a dead value, and converting it would
// leave the dead value on the user's rail where nothing undoes it (measured:
// `_BitInt(40) a + b` lowered as an i64 add + mask, slice_bitint).
bool survives(const CallInst *R, const TaintSet &taint, unsigned Depth = 0) {
  if (Depth > 16)
    return true;  // a pathological chain: say "kept" (in place or loud).
  for (const User *U : R->users()) {
    const auto *C = dyn_cast<CallInst>(U);
    if (!C)
      return true;  // ret / store / φ / select: the value escapes or is routed.
    if (isMeasureSink(C) || isOutputSink(C) || isNonPermutationMove(C, R))
      return true;
    Site T;
    if (qqShape(const_cast<CallInst *>(C), taint, T)) {
      for (unsigned Idx = 0; Idx < 2; ++Idx)
        if (C->getArgOperand(Idx) == R && (T.Mask >> Idx & 1u) &&
            survives(C, taint, Depth + 1))
          return true;
    }
  }
  return false;
}

// Is the out-of-place result `C` already discharged in the IR: an out-first
// `_unc` zeroing it (slot 0) AND a `cqrt_free` of it? Both are required, as in
// `priorUseIsSettled` arm (d): the `_unc` witnesses |0⟩, the free the release.
bool resultDischargedInline(const CallInst *C) {
  bool Zeroed = false, Released = false;
  for (const User *U : C->users()) {
    const auto *D = dyn_cast<CallInst>(U);
    const Function *DF = D ? D->getCalledFunction() : nullptr;
    if (!DF || D->arg_size() < 1 || D->getArgOperand(0) != C)
      continue;
    StringRef N = DF->getName();
    if (N == "cqrt_free")
      Released = true;
    else if (N.ends_with("_unc") && N.starts_with("cq_template_"))
      Zeroed = true;
  }
  return Zeroed && Released;
}

void convert(const Site &S, unsigned TargetIdx, FunctionCallee Fn,
             TaintSet &taint) {
  CallInst *C = S.C;
  Value *P = C->getArgOperand(TargetIdx);
  Value *Src = C->getArgOperand(1 - TargetIdx);
  IRBuilder<> B(C);
  CallInst *G = B.CreateCall(Fn, {Src, P});
  if (DebugLoc DL = C->getDebugLoc())
    G->setDebugLoc(DL);
  G->setMetadata(kInPlaceQQTag, MDNode::get(C->getContext(), {}));
  // V = x OP y IS x's register now: every reader of V reads x's rail.
  C->replaceAllUsesWith(P);
  taint.Tainted.erase(C);
  taint.HandleWidth.erase(C);
  taint.BirthOrder.erase(C);
  Function *Sym = C->getCalledFunction();
  C->eraseFromParent();
  if (Sym && Sym->isDeclaration() && Sym->use_empty())
    Sym->eraseFromParent();
}

enum class Outcome { None, Converted, Loud };

// Decide the FIRST undecided site of `F` in program order on the current IR.
Outcome decideNext(Function &F, WidthDispatch &wd, TaintSet &taint,
                   SmallPtrSetImpl<CallInst *> &Done) {
  SmallVector<Site, 4> Sites;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB) {
      auto *C = dyn_cast<CallInst>(&I);
      Site S;
      if (!C || Done.count(C) || !qqShape(C, taint, S))
        continue;
      // A rail another emitter owns is never re-lowered (the same explicit
      // image the classical-immediate late round applies).
      if (taint.ControlOwnedRails.count(C) || taint.OutputRails.count(C) ||
          taint.GraveyardRails.count(C) || taint.UntaintedMergeRails.count(C))
        continue;
      Sites.push_back(S);
    }
  if (Sites.empty())
    return Outcome::None;

  DominatorTree DT(F);
  LoopInfo LI(DT);
  InteriorDischargePlan Plan = planInteriorDischarges(F, taint);
  for (const Site &S : Sites) {
    Done.insert(S.C);
    // (E) eligibility, per operand: dead after the op in the user's IR (the
    // `!cq.qq.dead` record), a user-data rail, and a source that does not depend
    // on its old value (which also covers every alias of it: `x ^= x`, a φ or
    // select of it — those stay out of place, the `0` a fresh rail). `sub` is
    // directional — only the minuend (slot 0) can be overwritten; an eligible
    // SUBTRAHEND (`t = a - t`) has no in-place form, so it is refused like any
    // other fence refusal, i.e. loud unless the minuend converts.
    SmallVector<unsigned, 2> Cands;
    bool Eligible = false;
    for (unsigned Idx = 0; Idx < 2; ++Idx) {
      if (!(S.Mask >> Idx & 1u) || !railIsUserData(S.C->getArgOperand(Idx)) ||
          dependsOnTarget(S.C->getArgOperand(1 - Idx), S.C->getArgOperand(Idx),
                          S.C, DT))
        continue;
      Eligible = true;
      if (!(S.Stem == "sub" && Idx == 1))
        Cands.push_back(Idx);
    }
    if (!Eligible)
      continue;  // live old value (or a derived rail): out of place, D5.
    // A RESULT THAT IS DISCHARGED stays out of place, fence or no fence. An
    // emitter already returned it to |0⟩ inline (a control region's chain strip),
    // or the M-B plan discharges it after its last reader (`uncompute` re-runs
    // the same planner; a moved plan degrades to a leak, never to a misplaced
    // adjoint). Then the old rail standing beside it records nothing the program
    // does not: out of place IS in-place followed by its own adjoint at the
    // result's death, which is what the dead-record ruling asks of a dead value
    // (uncompute, never leak). Converting would instead leave the dead result on
    // the user's rail, where nothing undoes it (measured: `_BitInt(40) a + b`
    // lowered as an i64 add + mask, slice_bitint).
    if (resultDischargedInline(S.C) || Plan.GateAt.count(S.C) ||
        !survives(S.C, taint))
      continue;
    if (Cands.size() == 2) {
      unsigned B0 = taint.BirthOrder.lookup(S.C->getArgOperand(0));
      unsigned B1 = taint.BirthOrder.lookup(S.C->getArgOperand(1));
      if (B0 && B1 && B1 < B0)
        std::swap(Cands[0], Cands[1]);
    }
    // (F) the fence, per candidate.
    for (unsigned Idx : Cands) {
      Value *P = S.C->getArgOperand(Idx);
      if (!inPlacePositionHolds(S.C, P, taint, DT, LI, &Plan))
        continue;
      // Asked LAST: `getOrInsertFunction` declares as a side effect (G3).
      FunctionCallee Fn = wd.qqInPlaceFn(S.Stem, S.W);
      if (!Fn)
        continue;
      Done.erase(S.C);  // erased below; never leave a dangling key.
      convert(S, Idx, Fn, taint);
      return Outcome::Converted;
    }
    // Q1: a dead user register the fence refuses, beside a SURVIVING result —
    // never out of place.
    F.getContext().diagnose(DiagnosticInfoUnsupported(
        F, kMsgInPlaceQQRefused, S.C->getDebugLoc()));
    return Outcome::Loud;
  }
  return Outcome::None;
}

}  // namespace

bool lowerInPlaceQQ(Module &M, WidthDispatch &wd, TaintSet &taint) {
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    SmallPtrSet<CallInst *, 8> Done;
    for (;;) {
      Outcome O = decideNext(F, wd, taint, Done);
      if (O == Outcome::Converted) {
        Changed = true;
        continue;
      }
      if (O == Outcome::Loud)
        return Changed;
      break;
    }
  }
  for (Function &F : M)
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (I.getMetadata(kDeadOperandTag))
          I.setMetadata(kDeadOperandTag, nullptr);
  return Changed;
}

}  // namespace cq
