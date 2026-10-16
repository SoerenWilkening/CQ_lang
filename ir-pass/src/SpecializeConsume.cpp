// SpecializeConsume.cpp — see the header (bd test_C_libtooling-r2j3.37.1).

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

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"

#include <string>

using namespace llvm;

namespace cq {

using namespace tailhoist;

namespace {

// One in-place op of the chain, inner to outer: the op and its SOURCE operand.
struct Step {
  Instruction::BinaryOps Opc = Instruction::Xor;
  enum Kind { Param, Const, Source } K = Const;
  unsigned ArgNo = 0;
  Constant *C = nullptr;
  Function *Clone = nullptr;  // the lifted source (Kind == Source)
  bool Quantum = false;       // a handle (QQ gate) or a classical value (M-C)
};

unsigned countArg(const Plan &P, int I, unsigned K) {
  const Node &Nd = P.N[I];
  if (Nd.K == Node::Arg)
    return Nd.ArgNo == K;
  if (Nd.K == Node::Op)
    return countArg(P, Nd.L, K) + countArg(P, Nd.R, K);
  return 0;
}

// The path root -> Arg(K) as (op node, the target's side is R?), root first.
bool pathTo(const Plan &P, int I, unsigned K,
            SmallVectorImpl<std::pair<int, bool>> &Path) {
  const Node &Nd = P.N[I];
  if (Nd.K == Node::Arg)
    return Nd.ArgNo == K;
  if (Nd.K != Node::Op)
    return false;
  for (bool Right : {false, true}) {
    Path.push_back({I, Right});
    if (pathTo(P, Right ? Nd.R : Nd.L, K, Path))
      return true;
    Path.pop_back();
  }
  return false;
}

StringRef stemOf(Instruction::BinaryOps Opc) {
  return Opc == Instruction::Xor ? "xor" : Opc == Instruction::Add ? "add" : "sub";
}

// The consumer's body. False: a gate has no symbol.
bool emitBody(Function &C, unsigned K, ArrayRef<Step> Steps, StringRef W,
              const TaintSet &taint, WidthDispatch &wd) {
  LLVMContext &Ctx = C.getContext();
  BasicBlock *BB = BasicBlock::Create(Ctx, "", &C);
  ReturnInst *Ret = ReturnInst::Create(Ctx, BB);
  IRBuilder<> B(Ret);
  Value *Dst = C.getArg(K);
  SmallVector<Value *, 8> Args;
  for (Argument &A : C.args())
    Args.push_back(&A);
  SmallVector<CallInst *, 4> Minted;
  for (const Step &S : Steps) {
    Value *Src = nullptr;
    if (S.K == Step::Param) {
      Src = C.getArg(S.ArgNo);
    } else if (S.K == Step::Const) {
      Src = S.C;
    } else {
      CallInst *SC = B.CreateCall(S.Clone, Args);
      SC->setCallingConv(S.Clone->getCallingConv());
      for (unsigned A = 0; A < SC->arg_size(); ++A)
        if (isRecordedDeadSlot(*SC, A, taint))
          rewriteRecordedDeadSlotUse(SC->getArgOperandUse(A), taint);
      if (S.Quantum)
        Minted.push_back(SC);
      Src = SC;
    }
    if (S.Quantum) {
      FunctionCallee Fn = wd.qqInPlaceFn(stemOf(S.Opc), W);
      if (!Fn)
        return false;
      B.CreateCall(Fn, {Src, Dst})
          ->setMetadata(kInPlaceQQTag, MDNode::get(Ctx, {}));
    } else if (!emitInPlaceImmediateGate(Ret, S.Opc, Dst, Src, W, wd)) {
      return false;
    }
  }
  for (auto It = Minted.rbegin(); It != Minted.rend(); ++It) {
    if (!emitInverseCall(B, *It, wd, nullptr, nullptr))
      return false;
    B.CreateCall(wd.freeFn(), {*It});
  }
  return true;
}

constexpr const char kStepsTag[] = "cq.consume.steps";

// `!{!"W", !{opc, kind, argno, const-or-clone-or-0, quantum}...}`.
MDNode *encodeSteps(LLVMContext &Ctx, ArrayRef<Step> Steps, StringRef W) {
  auto I32 = [&](uint64_t X) -> Metadata * {
    return ConstantAsMetadata::get(ConstantInt::get(Type::getInt32Ty(Ctx), X));
  };
  SmallVector<Metadata *, 8> Ops{MDString::get(Ctx, W)};
  for (const Step &S : Steps) {
    Metadata *V = S.K == Step::Const    ? ConstantAsMetadata::get(S.C)
                  : S.K == Step::Source ? ValueAsMetadata::get(S.Clone)
                                        : I32(0);
    Ops.push_back(MDNode::get(Ctx, {I32(S.Opc), I32(S.K), I32(S.ArgNo), V,
                                    I32(S.Quantum)}));
  }
  return MDNode::get(Ctx, Ops);
}

bool decodeSteps(const MDNode *MD, SmallVectorImpl<Step> &Steps, StringRef &W) {
  auto *WS = MD && MD->getNumOperands() ? dyn_cast<MDString>(MD->getOperand(0))
                                        : nullptr;
  if (!WS)
    return false;
  W = WS->getString();
  for (unsigned I = 1; I < MD->getNumOperands(); ++I) {
    auto *E = dyn_cast<MDNode>(MD->getOperand(I));
    if (!E || E->getNumOperands() != 5)
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
    if (S.K == Step::Source)
      S.Clone = VM ? dyn_cast<Function>(VM->getValue()) : nullptr;
    if ((S.K == Step::Const && !S.C) || (S.K == Step::Source && !S.Clone))
      return false;
    Steps.push_back(S);
  }
  return true;
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
  auto I32 = [&](uint64_t X) {
    return ConstantAsMetadata::get(ConstantInt::get(Type::getInt32Ty(Ctx), X));
  };
  SmallVector<Metadata *, 8> Ops(Tag->op_begin(), Tag->op_end());
  SmallVector<Value *, 8> SiteArgs(Site.args());
  for (unsigned K = 0; K < 64 && K < Site.arg_size(); ++K) {
    if (!(Chain >> K & 1) || !(Handles >> K & 1) ||
        consumeSlotReadsTwice(Site, K, Handles))
      continue;  // a value in two handle slots is read twice: never a target.
    ConsumeReason Why = ConsumeReason::Ok;
    SmallVector<std::pair<int, bool>, 4> Path;
    const StringRef W = abiWidthFromType(OrigCallee->getArg(K)->getType());
    if (!Pure || !P || !P->hoistable() || W.empty())
      Why = ConsumeReason::Unsupported;
    else if (const unsigned N = countArg(*P, P->Root, K); N >= 2)
      Why = ConsumeReason::SelfDependent;  // `t` read twice by the chain.
    else if (N == 0 || !pathTo(*P, P->Root, K, Path))
      Why = ConsumeReason::Unsupported;    // reached, but not through a plan.
    SmallVector<Step, 4> Steps;
    for (auto It = Path.rbegin(); Why == ConsumeReason::Ok && It != Path.rend();
         ++It) {
      const Node &Op = P->N[It->first];
      Step S;
      S.Opc = Op.Opc;
      if (Op.Opc == Instruction::Sub && It->second) {
        Why = ConsumeReason::NotInPlace;  // `a - t`: no in-place form.
        break;
      }
      const int SrcIdx = It->second ? Op.L : Op.R;
      const Node &Src = P->N[SrcIdx];
      if (Src.K == Node::Arg) {
        S.K = Step::Param;
        S.ArgNo = Src.ArgNo;
        S.Quantum = Handles >> Src.ArgNo & 1;
      } else if (Src.K == Node::Const) {
        S.K = Step::Const;
        S.C = Src.C;
      } else {
        Function *SrcF = PL.subtreeSrc(*P, SrcIdx);
        SrcF->addFnAttr(kConsumeAuxAttr);
        CallInst *Tmp = CallInst::Create(SrcF, SiteArgs, "", Site.getIterator());
        Tmp->setCallingConv(SrcF->getCallingConv());
        const SpecMask Mask = taintArgMask(Tmp, taint);
        SpecRecord Rec = Resolve(Tmp, SrcF, Mask);
        Tmp->eraseFromParent();
        S.K = Step::Source;
        S.Clone = Rec.Clone;
        S.Quantum = Rec.ReturnTainted;
        if (!S.Clone) {
          Why = ConsumeReason::Unsupported;
          break;
        }
        S.Clone->addFnAttr(kConsumeAuxAttr);
        if (S.Quantum)
          EnsureTwin(S.Clone, Mask);
        if (S.Clone->getFunctionType()->params() !=
            SiteClone->getFunctionType()->params())
          Why = ConsumeReason::Unsupported;
        else if (!(taint.SpecDeadArgMask.lookup(S.Clone) >> K & 1))
          Why = ConsumeReason::SelfDependent;  // the source reads `t`.
      }
      Steps.push_back(S);
    }
    // The consumer is a SHELL here (a `ret void` body carrying the steps as
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
        C = makeShell(*SiteClone, Name, K, encodeSteps(Ctx, Steps, W));
        taint.SpecHandleArgMask[C] = Handles;
      }
    }
    Ops.push_back(MDNode::get(
        Ctx, {I32(K), I32(static_cast<unsigned>(Why)),
              C ? static_cast<Metadata *>(ValueAsMetadata::get(C)) : I32(0)}));
  }
  Site.setMetadata(kLiftTailOwedTag, MDNode::get(Ctx, Ops));
}

bool materializeConsumer(Function &C, const TaintSet &taint, WidthDispatch &wd) {
  const int K = consumingCloneDestSlot(&C);
  MDNode *Enc = C.getMetadata(kStepsTag);
  if (!Enc)
    return K >= 0;  // already materialized (another site shares it).
  SmallVector<Step, 4> Steps;
  StringRef W;
  if (K < 0 || !decodeSteps(Enc, Steps, W))
    return false;
  C.getEntryBlock().eraseFromParent();
  C.setMetadata(kStepsTag, nullptr);
  return emitBody(C, K, Steps, W, taint, wd);
}

}  // namespace cq
