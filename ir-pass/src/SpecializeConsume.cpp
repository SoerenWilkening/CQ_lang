// SpecializeConsume.cpp — see the header (bd test_C_libtooling-r2j3.37.1;
// classical-condition select roots: bd r2j3.37.3).

#include "SpecializeConsume.h"

#include "ArithLowering.h"       // emitInPlaceImmediateGate
#include "DeadValueLiveness.h"   // isRecordedDeadSlot / rewriteRecordedDeadSlotUse
#include "EmitInverse.h"         // emitInverseCall
#include "InPlaceQQ.h"           // kInPlaceQQTag / kConsumeDstAttr
#include "OpcodeSupport.h"       // abiWidthFromType
#include "SpecializeLiftTag.h"   // kLiftTailOwedTag
#include "SpecializeTailPlan.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"

#include <string>
#include <vector>

using namespace llvm;

namespace cq {

using namespace tailhoist;

namespace {

// The consumer's program, inner to outer: an in-place op and its SOURCE operand
// (a parameter, a constant, a lifted source clone), or (r2j3.37.3) a BRANCH on a
// classical condition — computed by a lifted source clone, zero-extended to the
// chain width — between the two arms' programs.
struct Step {
  Instruction::BinaryOps Opc = Instruction::Xor;
  enum Kind { Param, Const, Source, Branch } K = Const;
  unsigned ArgNo = 0;
  Constant *C = nullptr;
  Function *Clone = nullptr;  // the lifted source / condition
  bool Quantum = false;       // a handle (QQ gate) or a classical value (M-C)
  std::vector<Step> Then, Else;
};

// How often the target occurs on every path through node `I` (a select's arms
// must agree; -1 when they do not).
int countArg(const Plan &P, int I, unsigned K) {
  const Node &Nd = P.N[I];
  if (Nd.K == Node::Arg)
    return Nd.ArgNo == K;
  if (Nd.K == Node::Op) {
    const int L = countArg(P, Nd.L, K), R = countArg(P, Nd.R, K);
    return L < 0 || R < 0 ? -1 : L + R;
  }
  if (Nd.K == Node::Sel) {
    const int L = countArg(P, Nd.L, K), R = countArg(P, Nd.R, K);
    return L == R ? L : -1;
  }
  return 0;
}

StringRef stemOf(Instruction::BinaryOps Opc) {
  return Opc == Instruction::Xor ? "xor" : Opc == Instruction::Add ? "add" : "sub";
}

struct Builder {
  CallInst &Site;
  Function *SiteClone;
  uint64_t Handles;
  unsigned K;
  TaintSet &taint;
  ConsumeResolveFn Resolve;
  ConsumeTwinFn EnsureTwin;
  Planner &PL;
  Plan &P;

  // Lift a source (a copy of f returning one value) at the site's arguments.
  ConsumeReason lift(Function *SrcF, Step &S) {
    SrcF->addFnAttr(kConsumeAuxAttr);
    SmallVector<Value *, 8> Args(Site.args());
    CallInst *Tmp = CallInst::Create(SrcF, Args, "", Site.getIterator());
    Tmp->setCallingConv(SrcF->getCallingConv());
    const SpecMask Mask = taintArgMask(Tmp, taint);
    SpecRecord Rec = Resolve(Tmp, SrcF, Mask);
    Tmp->eraseFromParent();
    S.Clone = Rec.Clone;
    S.Quantum = Rec.ReturnTainted;
    if (!S.Clone)
      return ConsumeReason::Unsupported;
    S.Clone->addFnAttr(kConsumeAuxAttr);
    if (S.Quantum)
      EnsureTwin(S.Clone, Mask);
    if (S.Clone->getFunctionType()->params() !=
        SiteClone->getFunctionType()->params())
      return ConsumeReason::Unsupported;
    if (!(taint.SpecDeadArgMask.lookup(S.Clone) >> K & 1))
      return ConsumeReason::SelfDependent;  // the source reads `t`.
    return ConsumeReason::Ok;
  }

  ConsumeReason source(int I, Step &S) {
    const Node &Src = P.N[I];
    if (Src.K == Node::Arg) {
      S.K = Step::Param;
      S.ArgNo = Src.ArgNo;
      S.Quantum = Handles >> Src.ArgNo & 1;
      return ConsumeReason::Ok;
    }
    if (Src.K == Node::Const) {
      S.K = Step::Const;
      S.C = Src.C;
      return ConsumeReason::Ok;
    }
    S.K = Step::Source;
    if (!PL.placeableAtRet(P, I))
      return ConsumeReason::Unsupported;  // a φ arm's own value (r2j3.37.4)
    return lift(PL.subtreeSrc(P, I), S);
  }

  ConsumeReason build(int I, std::vector<Step> &Out) {
    const Node &Nd = P.N[I];
    if (Nd.K == Node::Arg)
      return Nd.ArgNo == K ? ConsumeReason::Ok : ConsumeReason::Unsupported;
    if (Nd.K == Node::Op) {
      const int L = countArg(P, Nd.L, K), R = countArg(P, Nd.R, K);
      if (L < 0 || R < 0 || L + R == 0)
        return ConsumeReason::Unsupported;
      if (L + R >= 2)
        return ConsumeReason::SelfDependent;  // `t` read twice by the chain.
      const bool Right = R == 1;
      if (Nd.Opc == Instruction::Sub && Right)
        return ConsumeReason::NotInPlace;  // `a - t`: no in-place form.
      if (ConsumeReason Why = build(Right ? Nd.R : Nd.L, Out);
          Why != ConsumeReason::Ok)
        return Why;
      Step S;
      S.Opc = Nd.Opc;
      ConsumeReason Why = source(Right ? Nd.L : Nd.R, S);
      Out.push_back(std::move(S));
      return Why;
    }
    if (Nd.K == Node::Sel) {
      // r2j3.37.3: each arm in place under the CLASSICAL condition; a quantum
      // condition is a control region, not built here (loud when owed).
      Step S;
      S.K = Step::Branch;
      if (auto *CondI = dyn_cast<Instruction>(Nd.V);
          CondI && !P.DT->dominates(CondI, P.Ret))
        return ConsumeReason::Unsupported;
      ConsumeReason Why = lift(PL.condSrc(P, I), S);
      if (Why != ConsumeReason::Ok)
        return Why;
      if (S.Quantum)
        return ConsumeReason::Unsupported;
      if ((Why = build(Nd.L, S.Then)) != ConsumeReason::Ok ||
          (Why = build(Nd.R, S.Else)) != ConsumeReason::Ok)
        return Why;
      Out.push_back(std::move(S));
      return ConsumeReason::Ok;
    }
    return ConsumeReason::Unsupported;
  }
};

// The consumer's program before `At` (which it leaves in the block that holds
// the rest of the body). False: a gate has no symbol at the width.
bool emitSteps(ArrayRef<Step> Steps, Instruction *At, Function &C, unsigned K,
               StringRef W, const TaintSet &taint, WidthDispatch &wd) {
  LLVMContext &Ctx = C.getContext();
  Value *Dst = C.getArg(K);
  SmallVector<Value *, 8> Args;
  for (Argument &A : C.args())
    Args.push_back(&A);
  auto call = [&](IRBuilder<> &B, Function *F) {
    CallInst *SC = B.CreateCall(F, Args);
    SC->setCallingConv(F->getCallingConv());
    for (unsigned A = 0; A < SC->arg_size(); ++A)
      if (isRecordedDeadSlot(*SC, A, taint))
        rewriteRecordedDeadSlotUse(SC->getArgOperandUse(A), taint);
    return SC;
  };
  SmallVector<CallInst *, 4> Minted;
  for (const Step &S : Steps) {
    IRBuilder<> B(At);
    if (S.K == Step::Branch) {
      Value *Cond = B.CreateICmpNE(call(B, S.Clone), Constant::getNullValue(
                                                         S.Clone->getReturnType()));
      BasicBlock *Cur = At->getParent();
      Cur->splitBasicBlock(At->getIterator());  // `At` now heads the merge
      BasicBlock *Merge = At->getParent();
      auto *Then = BasicBlock::Create(Ctx, "", &C, Merge);
      auto *Else = BasicBlock::Create(Ctx, "", &C, Merge);
      Instruction *TT = BranchInst::Create(Merge, Then);
      Instruction *ET = BranchInst::Create(Merge, Else);
      Cur->getTerminator()->eraseFromParent();
      BranchInst::Create(Then, Else, Cond, Cur);
      if (!emitSteps(S.Then, TT, C, K, W, taint, wd) ||
          !emitSteps(S.Else, ET, C, K, W, taint, wd))
        return false;
      continue;
    }
    Value *Src = S.K == Step::Param ? static_cast<Value *>(C.getArg(S.ArgNo))
                 : S.K == Step::Const ? static_cast<Value *>(S.C)
                                      : call(B, S.Clone);
    if (S.K == Step::Source && S.Quantum)
      Minted.push_back(cast<CallInst>(Src));
    if (S.Quantum) {
      FunctionCallee Fn = wd.qqInPlaceFn(stemOf(S.Opc), W);
      if (!Fn)
        return false;
      B.CreateCall(Fn, {Src, Dst})->setMetadata(kInPlaceQQTag, MDNode::get(Ctx, {}));
    } else if (!emitInPlaceImmediateGate(At, S.Opc, Dst, Src, W, wd)) {
      return false;
    }
  }
  IRBuilder<> B(At);
  for (auto It = Minted.rbegin(); It != Minted.rend(); ++It) {
    if (!emitInverseCall(B, *It, wd, nullptr, nullptr))
      return false;
    B.CreateCall(wd.freeFn(), {*It});
  }
  return true;
}

constexpr const char kStepsTag[] = "cq.consume.steps";

Metadata *I32MD(LLVMContext &Ctx, uint64_t X) {
  return ConstantAsMetadata::get(ConstantInt::get(Type::getInt32Ty(Ctx), X));
}

// `!{opc, kind, argno, const-or-clone-or-0, quantum, !{then...}, !{else...}}`.
MDNode *encodeList(LLVMContext &Ctx, ArrayRef<Step> Steps) {
  SmallVector<Metadata *, 8> Ops;
  for (const Step &S : Steps) {
    Metadata *V = S.K == Step::Const ? ConstantAsMetadata::get(S.C)
                  : S.Clone          ? ValueAsMetadata::get(S.Clone)
                                     : I32MD(Ctx, 0);
    Ops.push_back(MDNode::get(Ctx, {I32MD(Ctx, S.Opc), I32MD(Ctx, S.K),
                                    I32MD(Ctx, S.ArgNo), V, I32MD(Ctx, S.Quantum),
                                    encodeList(Ctx, S.Then),
                                    encodeList(Ctx, S.Else)}));
  }
  return MDNode::get(Ctx, Ops);
}

bool decodeList(const MDNode *MD, std::vector<Step> &Steps) {
  for (unsigned I = 0; MD && I < MD->getNumOperands(); ++I) {
    auto *E = dyn_cast<MDNode>(MD->getOperand(I));
    if (!E || E->getNumOperands() != 7)
      return false;
    auto word = [&](unsigned J) {
      auto *C = mdconst::dyn_extract<ConstantInt>(E->getOperand(J));
      return C ? C->getZExtValue() : ~0ull;
    };
    Step S;
    S.Opc = static_cast<Instruction::BinaryOps>(word(0));
    S.K = static_cast<Step::Kind>(word(1));
    S.ArgNo = static_cast<unsigned>(word(2));
    S.Quantum = word(4) == 1;
    auto *VM = dyn_cast<ValueAsMetadata>(E->getOperand(3));
    if (S.K == Step::Const)
      S.C = VM ? dyn_cast<Constant>(VM->getValue()) : nullptr;
    if (S.K == Step::Source || S.K == Step::Branch)
      S.Clone = VM ? dyn_cast<Function>(VM->getValue()) : nullptr;
    if ((S.K == Step::Const && !S.C) || (S.K >= Step::Source && !S.Clone) ||
        !decodeList(dyn_cast<MDNode>(E->getOperand(5)), S.Then) ||
        !decodeList(dyn_cast<MDNode>(E->getOperand(6)), S.Else))
      return false;
    Steps.push_back(std::move(S));
  }
  return MD != nullptr;
}

Function *makeShell(Function &Like, const Twine &Name, unsigned K, MDNode *Enc) {
  FunctionType *FT = FunctionType::get(Type::getVoidTy(Like.getContext()),
                                       Like.getFunctionType()->params(), false);
  Function *F = Function::Create(FT, GlobalValue::InternalLinkage, Name,
                                 Like.getParent());
  F->setCallingConv(Like.getCallingConv());
  F->addFnAttr(kConsumeDstAttr, std::to_string(K));
  F->addFnAttr(kConsumeAuxAttr);
  F->addFnAttr(Attribute::NoInline);
  ReturnInst::Create(F->getContext(),
                     BasicBlock::Create(F->getContext(), "entry", F));
  F->setMetadata(kStepsTag, Enc);
  return F;
}

}  // namespace

void buildConsumingCandidates(CallInst &Site, Function *OrigCallee,
                              TaintSet &taint, WidthDispatch &wd,
                              ConsumeResolveFn Resolve, ConsumeTwinFn EnsureTwin) {
  MDNode *Tag = Site.getMetadata(kLiftTailOwedTag);
  Function *SiteClone = Site.getCalledFunction();
  if (!Tag || Tag->getNumOperands() != 1 || !SiteClone || !OrigCallee)
    return;
  auto *KC = mdconst::dyn_extract<ConstantInt>(Tag->getOperand(0));
  const uint64_t Chain = KC ? KC->getZExtValue() : 0;
  const uint64_t Handles = taint.SpecHandleArgMask.lookup(SiteClone);
  Planner PL;
  Plan *P = PL.planFor(OrigCallee);
  SmallPtrSet<const Function *, 8> Stack;
  // R11 r1 (rL1C-F2 / rL1A-F2): the body must have no effect but its return.
  const bool Pure = consumableBody(*OrigCallee, Stack);
  LLVMContext &Ctx = Site.getContext();
  SmallVector<Metadata *, 8> Ops(Tag->op_begin(), Tag->op_end());
  for (unsigned K = 0; K < 64 && K < Site.arg_size(); ++K) {
    if (!(Chain >> K & 1) || !(Handles >> K & 1) ||
        consumeSlotReadsTwice(Site, K, Handles))
      continue;  // a value in two handle slots is read twice: never a target.
    ConsumeReason Why = ConsumeReason::Ok;
    const StringRef W = abiWidthFromType(OrigCallee->getArg(K)->getType());
    std::vector<Step> Steps;
    if (!Pure || !P || !P->hoistable() || W.empty()) {
      Why = ConsumeReason::Unsupported;
    } else {
      Builder Bld{Site, SiteClone, Handles, K, taint, Resolve, EnsureTwin, PL, *P};
      Why = Bld.build(P->Root, Steps);
    }
    // The consumer is a SHELL here (a `ret void` body carrying the program as
    // `!cq.consume.steps`): its gates are minted only if the late round
    // consumes the site (`materializeConsumer`), so an unused candidate leaves
    // no declaration behind. It has NO adjoint twin, deliberately: a consumed
    // target is user data (it carries an Ry), which the spine never reverses,
    // and a lifted clone body never consumes (only top-level sites are tagged),
    // so no adjoint is ever asked for — and `isInverseEmittable` answers false
    // for a consumer without a defined twin, i.e. fails CLOSED (R11 r1 rL1B-F2).
    Function *C = nullptr;
    if (Why == ConsumeReason::Ok) {
      const std::string Name = (SiteClone->getName() + "_c" + Twine(K)).str();
      C = Site.getModule()->getFunction(Name);
      if (!C) {
        MDNode *Enc = MDNode::get(Ctx, {MDString::get(Ctx, W), encodeList(Ctx, Steps)});
        C = makeShell(*SiteClone, Name, K, Enc);
        taint.SpecHandleArgMask[C] = Handles;
      }
    }
    Ops.push_back(MDNode::get(
        Ctx, {I32MD(Ctx, K), I32MD(Ctx, static_cast<unsigned>(Why)),
              C ? static_cast<Metadata *>(ValueAsMetadata::get(C)) : I32MD(Ctx, 0)}));
  }
  Site.setMetadata(kLiftTailOwedTag, MDNode::get(Ctx, Ops));
}

bool materializeConsumer(Function &C, const TaintSet &taint, WidthDispatch &wd) {
  const int K = consumingCloneDestSlot(&C);
  MDNode *Enc = C.getMetadata(kStepsTag);
  if (!Enc)
    return K >= 0;  // already materialized (another site shares it).
  std::vector<Step> Steps;
  auto *WS = Enc->getNumOperands() == 2 ? dyn_cast<MDString>(Enc->getOperand(0))
                                        : nullptr;
  if (K < 0 || !WS || !decodeList(dyn_cast<MDNode>(Enc->getOperand(1)), Steps))
    return false;
  const StringRef W = WS->getString();
  C.getEntryBlock().eraseFromParent();
  C.setMetadata(kStepsTag, nullptr);
  ReturnInst *Ret =
      ReturnInst::Create(C.getContext(), BasicBlock::Create(C.getContext(), "", &C));
  return emitSteps(Steps, Ret, C, K, W, taint, wd);
}

}  // namespace cq
