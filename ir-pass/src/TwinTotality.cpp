// TwinTotality.cpp — bd dm7f.26/.27/.29/.30: see TwinTotality.h.
//
// Ground truth (R12), read 2026-10-13: Bennett.jl 824458d1 lowers a loop by
// unrolling it a fixed K times under an iteration-active predicate, freezing all
// state after the first exit (src/lowering/cfg.jl:673-700, `lower_loop!`), and
// lowers udiv/sdiv through throw-free kernels that are "LLVM-poison-equivalent
// on b == 0: deterministic but unspecified" (src/divider.jl:8-21,
// src/lowering/aggregate.jl:86-91). BennettVM.jl 23d28e64 evaluates sdiv/srem of
// INT_MIN by -1 "deterministic, not trapping" (src/ir/arithmetic_assignment.jl:
// 248-251) and drives `run!` under a `max_steps` divergence guard
// (src/interpreter/Interpreter.jl:1625-1630). The twin is the classical
// counterpart: a guard where the reference is total by construction, and a
// compiler-derived trip bound (ScalarEvolution) where Bennett.jl takes K from
// the user. Neither reference speculates a call out of a guard; that half is CQ's.
#include "TwinTotality.h"

#include "CallContract.h"       // inertAttrs, returnAttrsHold
#include "CalleeBody.h"         // calleeBodyTrusted
#include "IntrinsicLowering.h"  // isCuratedReversibleIntrinsic
#include "SpeculationTwin.h"    // isVerifiedTwin

#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SCCIterator.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/ScopeExit.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/ValueMapper.h"

#include <algorithm>

using namespace llvm;

namespace cq {
namespace {

bool isDivRem(const Instruction &I) {
  switch (I.getOpcode()) {
  case Instruction::UDiv:
  case Instruction::SDiv:
  case Instruction::URem:
  case Instruction::SRem:
    return true;
  default:
    return false;
  }
}

bool isSignedDivRem(const Instruction &I) {
  return I.getOpcode() == Instruction::SDiv || I.getOpcode() == Instruction::SRem;
}

// `icmp eq F, 0` (or `-1`).
bool eqConst(const Value *V, const Value *F, bool MinusOne) {
  const auto *C = dyn_cast<ICmpInst>(V);
  if (!C || C->getPredicate() != ICmpInst::ICMP_EQ || C->getOperand(0) != F)
    return false;
  const auto *K = dyn_cast<ConstantInt>(C->getOperand(1));
  return K && (MinusOne ? K->isMinusOne() : K->isZero());
}

// The divisor `applyTwinShape` emits: `select(bad, 1, F)` with `F` a `freeze`
// and `bad` = `F == 0` (unsigned) or `(F == 0) | (F == -1)` (signed). `F` is
// defined, so the divisor is never 0 (nor -1 for the signed forms): total for
// every dividend, poison included.
bool guardedDivisor(const Instruction &D) {
  const auto *S = dyn_cast<SelectInst>(D.getOperand(1));
  // Round-1 A-F1: at i1 the constant 1 IS -1, so the signed shape divides by -1.
  if (!S || (isSignedDivRem(D) && D.getType()->isIntegerTy(1)))
    return false;
  const auto *One = dyn_cast<ConstantInt>(S->getTrueValue());
  const auto *F = dyn_cast<FreezeInst>(S->getFalseValue());
  if (!One || !One->isOne() || !F)
    return false;
  if (!isSignedDivRem(D))
    return eqConst(S->getCondition(), F, /*MinusOne=*/false);
  const auto *Or = dyn_cast<BinaryOperator>(S->getCondition());
  return Or && Or->getOpcode() == Instruction::Or &&
         eqConst(Or->getOperand(0), F, false) && eqConst(Or->getOperand(1), F, true);
}

bool hasVector(const Instruction &I) {
  if (I.getType()->isVectorTy())
    return true;
  return any_of(I.operands(), [](const Use &U) { return U->getType()->isVectorTy(); });
}

bool cfgCyclic(const Function &F) {
  for (scc_iterator<const Function *> It = scc_begin(&F); !It.isAtEnd(); ++It)
    if (It.hasCycle())
      return true;
  return false;
}

// Every natural loop's maximum backedge-taken count, or false (irreducible or
// unbounded). ScalarEvolution answers for the ORIGINAL body; see the header for
// why its modulo-UB facts are exactly the ones the counter may rely on.
bool loopBounds(const Function &CF, TwinShape &S) {
  Function &F = const_cast<Function &>(CF);  // the analyses only read the IR
  // Round-1 A-F2: ScalarEvolution reads a call as its `returned` argument
  // (`getReturnedArgOperand`, call site or callee). A false `returned` is no UB,
  // so a bound read through it need not hold on a UB-free execution, and the
  // twin drops the attribute anyway. Strip it from `F`'s call sites and their
  // callees for this analysis only, and restore every list on exit (observably
  // pure: nothing else runs in between). A `range` stays: violated, it is poison.
  SmallVector<std::pair<CallBase *, AttributeList>, 4> Sites;
  SmallVector<std::pair<Function *, AttributeList>, 4> Callees;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *C = dyn_cast<CallBase>(&I)) {
        Sites.emplace_back(C, C->getAttributes());
        Function *G = C->getCalledFunction();
        if (G && !G->isIntrinsic() &&
            none_of(Callees, [&](const auto &E) { return E.first == G; }))
          Callees.emplace_back(G, G->getAttributes());
      }
  auto Restore = make_scope_exit([&] {
    for (auto &[C, A] : Sites)
      C->setAttributes(A);
    for (auto &[G, A] : Callees)
      G->setAttributes(A);
  });
  for (auto &[C, A] : Sites)
    for (unsigned N = 0; N != C->arg_size(); ++N)
      C->removeParamAttr(N, Attribute::Returned);
  for (auto &[G, A] : Callees)
    for (unsigned N = 0; N != G->arg_size(); ++N)
      G->removeParamAttr(N, Attribute::Returned);
  DominatorTree DT(F);
  LoopInfo LI(DT);
  ReversePostOrderTraversal<const Function *> RPOT(&CF);
  if (containsIrreducibleCFG<const BasicBlock *>(RPOT, LI))
    return false;
  AssumptionCache AC(F);
  TargetLibraryInfoImpl TLII(Triple(F.getParent()->getTargetTriple()));
  TargetLibraryInfo TLI(TLII, &F);
  ScalarEvolution SE(F, TLI, AC, DT, LI);
  for (const Loop *L : LI.getLoopsInPreorder()) {
    const auto *K = dyn_cast<SCEVConstant>(SE.getConstantMaxBackedgeTakenCount(L));
    if (!K)
      return false;
    S.Bounds.emplace_back(L->getHeader(), K->getAPInt());
  }
  return true;
}

}  // namespace

bool divisionIsTotal(const Instruction &I) {
  return !isDivRem(I) || isSafeToSpeculativelyExecute(&I) || guardedDivisor(I);
}

bool declarationWrapperExists(const Function &F) {
  if (!F.isSpeculatable() || F.isIntrinsic() || F.isVarArg())
    return false;
  bool ArgPois = false;
  for (const Argument &A : F.args()) {
    if (!inertAttrs(F.getAttributes().getParamAttrs(A.getArgNo())))
      return false;
    ArgPois |= !A.hasAttribute(Attribute::NoUndef);
  }
  const bool Pois = ArgPois || !returnAttrsHold(F.getAttributes().getRetAttrs(), F);
  return !(Pois && F.hasRetAttribute(Attribute::NoUndef));
}

const TwinTotality::Entry &TwinTotality::get(const Function &Root) {
  if (auto It = Memo.find(&Root); It != Memo.end())
    return It->second;
  // bd ziuw's lesson: a call chain may be 60000 deep, so the walk is an explicit
  // stack. `Local` holds each body's own verdict and its direct callees.
  struct Local {
    Entry E;
    SmallVector<const Function *, 4> Callees;
  };
  DenseMap<const Function *, Local> Locals;
  auto localOf = [&](const Function &F) {
    Local L;
    L.E.Admitted = L.E.Total = true;
    auto refuse = [&] { L.E.Admitted = L.E.Total = false; };
    if (F.isDeclaration()) {
      // Only a ROOT reaches here (an inner declaration is refused below): its
      // twin is the wrapper, trusted on the `speculatable` promise exactly as
      // the Direct route trusts it. The wrapper terminates only if `F` does, so
      // `willreturn` is the declaration's to state (nothing here can prove it).
      L.E.Admitted = F.isSpeculatable() && F.willReturn() && !F.isIntrinsic() &&
                     !F.isVarArg() && F.doesNotAccessMemory();
      L.E.Total = false;
      return L;
    }
    if (!calleeBodyTrusted(&F, CalleeBodyUse::AssumeOfLinkedCall) || F.isVarArg()) {
      refuse();
      return L;
    }
    for (const BasicBlock &BB : F) {
      const Instruction *T = BB.getTerminator();
      // A-F3: the twin returns zero there. LOAD-BEARING (round-2 review): a body
      // whose every path ends in `unreachable` keeps a cloned `noreturn`, so a
      // twin returning 0 from it would be UB; callExecutionIsDefined refuses
      // `noreturn` at the root (HoistRoute) and at every inner call (walkBody).
      if (isa<UnreachableInst>(T)) {
        L.E.Shape.Unreachables.push_back(T);
        L.E.Total = false;
      } else if (!isa<BranchInst>(T) && !isa<ReturnInst>(T) && !isa<SwitchInst>(T)) {
        return refuse(), L;
      }
      for (const Instruction &I : BB) {
        if (I.isTerminator() || isa<PHINode>(I))
          continue;
        if (hasVector(I))
          return refuse(), L;
        if (const auto *C = dyn_cast<CallInst>(&I)) {
          const Function *G = C->getCalledFunction();
          if (G && G->isIntrinsic() && isCuratedReversibleIntrinsic(C) &&
              C->doesNotAccessMemory())
            continue;
          if (!G || G->isIntrinsic() || G->isDeclaration())
            return refuse(), L;
          L.Callees.push_back(G);
          continue;
        }
        if (isDivRem(I)) {
          if (!divisionIsTotal(I)) {
            L.E.Shape.Guards.push_back(cast<BinaryOperator>(&I));
            L.E.Total = false;
          }
          continue;
        }
        if (I.mayReadOrWriteMemory() || !isSafeToSpeculativelyExecute(&I))
          return refuse(), L;
      }
    }
    if (cfgCyclic(F)) {
      if (!loopBounds(F, L.E.Shape))
        return refuse(), L;
      L.E.Total = false;
    }
    return L;
  };
  SmallVector<const Function *, 16> Stack{&Root};
  SmallPtrSet<const Function *, 16> OnStack{&Root};
  auto settle = [&](const Function *F, Entry E) {
    Memo[F] = std::move(E);
    OnStack.erase(F);
    Stack.pop_back();
  };
  while (!Stack.empty()) {
    const Function *F = Stack.back();
    if (Memo.count(F)) {
      OnStack.erase(F);
      Stack.pop_back();
      continue;
    }
    if (isVerifiedTwin(*F)) {  // total by construction (SpeculationTwin.cpp)
      settle(F, Entry{true, true, {}});
      continue;
    }
    if (!Locals.count(F))
      Locals[F] = localOf(*F);
    Local &L = Locals[F];
    if (!L.E.Admitted) {
      settle(F, std::move(L.E));
      continue;
    }
    const Function *Next = nullptr;
    bool Cycle = false;
    for (const Function *G : L.Callees)
      if (!Memo.count(G)) {
        Cycle = OnStack.count(G);  // recursion: no termination bound
        Next = G;
        break;
      }
    if (Cycle) {
      settle(F, Entry{});
      continue;
    }
    if (Next) {
      Stack.push_back(Next);
      OnStack.insert(Next);
      continue;
    }
    Entry E = std::move(L.E);
    for (const Function *G : L.Callees) {
      const Entry &C = Memo[G];
      E.Admitted &= C.Admitted;
      E.Total &= C.Total;
    }
    if (!E.Admitted)
      E.Total = false;
    settle(F, std::move(E));
  }
  return Memo[&Root];
}

bool TwinTotality::admits(const Function &F) { return get(F).Admitted; }
const TwinShape &TwinTotality::shape(const Function &F) { return get(F).Shape; }
bool TwinTotality::originalTotal(const Function &F) {
  const Entry &E = get(F);
  return E.Admitted && E.Total;
}

namespace {
// `n / d` -> `n / select(bad, 1, freeze d)`; for sdiv/srem the `d == -1` value
// is rebuilt (`0 - n`, `0`: what the source computes for every n but INT_MIN,
// where the source is UB). Only the divisor is frozen: it is a sink.
void guardDivision(BinaryOperator &D) {
  Type *Ty = D.getType();
  if (isSignedDivRem(D) && Ty->isIntegerTy(1)) {
    // Round-1 A-F1: an i1 divisor is 0 (UB) or -1, and -1 overflows for the
    // dividend -1 (INT_MIN), so 0 / -1 = 0 is the only UB-free value of i1
    // sdiv and srem alike: the twin computes exactly that, dividing by nothing.
    D.replaceAllUsesWith(ConstantInt::get(Ty, 0));
    D.eraseFromParent();
    return;
  }
  IRBuilder<> B(&D);
  B.SetCurrentDebugLocation(D.getDebugLoc());
  Value *F = B.CreateFreeze(D.getOperand(1), "cq.div.fr");
  Value *Bad = B.CreateICmpEQ(F, ConstantInt::get(Ty, 0), "cq.div.zero");
  Value *M1 = nullptr;
  if (isSignedDivRem(D)) {
    M1 = B.CreateICmpEQ(F, ConstantInt::getAllOnesValue(Ty), "cq.div.m1");
    Bad = B.CreateOr(Bad, M1, "cq.div.bad");
  }
  D.setOperand(1, B.CreateSelect(Bad, ConstantInt::get(Ty, 1), F, "cq.div.safe"));
  if (!M1)
    return;
  B.SetInsertPoint(D.getNextNode());
  Value *Fix = D.getOpcode() == Instruction::SDiv
                   ? B.CreateSub(ConstantInt::get(Ty, 0), D.getOperand(0), "cq.div.neg")
                   : ConstantInt::get(Ty, 0);
  Value *R = B.CreateSelect(M1, Fix, &D, "cq.div.res");
  D.replaceUsesWithIf(R, [&](Use &U) { return U.getUser() != R; });
}

// `ret <zero>` at the end of `BB` (the counter's exit, a rewritten `unreachable`).
void retZero(Function &T, BasicBlock *BB) {
  Type *RT = T.getReturnType();
  if (RT->isVoidTy())
    ReturnInst::Create(T.getContext(), BB);
  else
    ReturnInst::Create(T.getContext(), Constant::getNullValue(RT), BB);
}

// A counter in header `H`: `cq.trip` is 0 on entry and +1 per backedge; once it
// exceeds `Bound` the loop leaves to `ret <zero>`. On a UB-free execution of the
// source the header runs at most Bound+1 times per entry, so that exit is never
// taken there; elsewhere it bounds the loop, within ScalarEvolution's constant
// max trip count (which may be long: owner ruling
// owner-ruling-twin-divergence-bounded-2026-10-13).
void boundLoop(Function &T, BasicBlock *H, const APInt &Bound) {
  BasicBlock *Body = SplitBlock(H, H->getFirstNonPHI());
  Body->setName("cq.trip.body");
  LLVMContext &Ctx = T.getContext();
  auto *CT = IntegerType::get(Ctx, std::max(64u, Bound.getBitWidth() + 1));
  DominatorTree DT(T);  // after the split: a self-loop's latch is now `Body`
  auto *Cnt = PHINode::Create(CT, 2, "cq.trip");
  Cnt->insertBefore(H->begin());
  Instruction *Old = H->getTerminator();
  IRBuilder<> B(Old);
  Value *Next = B.CreateAdd(Cnt, ConstantInt::get(CT, 1), "cq.trip.next");
  Value *Over = B.CreateICmpUGT(Cnt, ConstantInt::get(CT, Bound.zext(CT->getBitWidth())),
                                "cq.trip.over");
  BasicBlock *Exit = BasicBlock::Create(Ctx, "cq.trip.exit", &T);
  retZero(T, Exit);
  B.CreateCondBr(Over, Exit, Body);
  Old->eraseFromParent();
  for (bool Latch : {false, true})  // entering edges first, then the backedges
    for (BasicBlock *P : predecessors(H))
      if (DT.dominates(H, P) == Latch)
        Cnt->addIncoming(Latch ? Next : ConstantInt::get(CT, 0), P);
}
}  // namespace

void applyTwinShape(Function &T, const TwinShape &S, ValueToValueMapTy &VMap) {
  for (const Instruction *U : S.Unreachables) {  // reaching it is UB in the source
    auto *Old = cast<Instruction>(VMap.lookup(U));
    BasicBlock *BB = Old->getParent();
    Old->eraseFromParent();
    retZero(T, BB);
  }
  for (const BinaryOperator *D : S.Guards)
    guardDivision(*cast<BinaryOperator>(VMap.lookup(D)));
  for (const auto &[H, Bound] : S.Bounds)
    boundLoop(T, cast<BasicBlock>(VMap.lookup(H)), Bound);
}

}  // namespace cq
