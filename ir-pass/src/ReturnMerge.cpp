// ReturnMerge.cpp — multi-exit `ret` normalization. See ReturnMerge.h for the
// contract, the slots and the taint obligation (bd test_C_libtooling-dm7f.5).

#include "ReturnMerge.h"

#include "ControlPlan.h"        // diagnoseUnderControl
#include "ControlShape.h"       // hasTaintedCondBranch, regionEntryInLoop
#include "TaintPropagation.h"   // TaintSet, propagateFromSeeds

#include "llvm/ADT/DepthFirstIterator.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CallGraph.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/Local.h"  // TryToSimplifyUncondBranchFromEmptyBlock

#include <memory>
#include <optional>

using namespace llvm;

namespace cq {

MergedReturn mergeReturnBlocks(Function &F, ArrayRef<ReturnInst *> Rets,
                               StringRef BlockName, StringRef PhiName,
                               bool CarryDebugLoc) {
  // The statement order below is `normalizeReturnMerge`'s, verbatim (block, φ,
  // `ret`, then per old `ret`: incoming, `br`, erase), so the clone caller's
  // output is byte-identical to the pre-extraction binary's.
  LLVMContext &Ctx = F.getContext();
  MergedReturn Out;
  Out.Merge = BasicBlock::Create(Ctx, BlockName, &F);
  Type *RetTy = F.getReturnType();
  if (!RetTy->isVoidTy())
    Out.Phi = PHINode::Create(RetTy, Rets.size(), PhiName, Out.Merge);
  ReturnInst *NewRet = ReturnInst::Create(Ctx, Out.Phi, Out.Merge);
  SmallVector<DILocation *, 4> Locs;
  for (ReturnInst *R : Rets) {
    if (Out.Phi)
      Out.Phi->addIncoming(R->getReturnValue(), R->getParent());  // (value, block)
    BranchInst *Br = BranchInst::Create(Out.Merge, R);  // `br merge` before the `ret`…
    if (CarryDebugLoc) {
      Br->setDebugLoc(R->getDebugLoc());
      if (DILocation *L = R->getDebugLoc().get())
        Locs.push_back(L);
    }
    R->eraseFromParent();  // …then drop the `ret`.
  }
  // Only when EVERY `ret` had a location: a merged location over a partial set
  // would claim a line the missing `ret`s never had.
  if (CarryDebugLoc && !Locs.empty() && Locs.size() == Rets.size())
    NewRet->setDebugLoc(DILocation::getMergedLocations(Locs));
  return Out;
}

namespace {

// Is `Term` a tainted-control terminator — the two `detectControlRegions`
// dispatches (`br i1` via the shared `hasTaintedCondBranch`, and `switch` on a
// tainted scrutinee)? A `select` is not control flow and ends no block.
bool isTaintedControlTerminator(Instruction *Term, TaintSet &taint) {
  if (hasTaintedCondBranch(Term->getParent(), taint))
    return true;
  if (auto *SI = dyn_cast<SwitchInst>(Term))
    return taint.Tainted.count(SI->getCondition());
  return false;
}

// Are two or more distinct `ret` blocks reachable from `Term`'s block? An exact
// walk (LLVM's `depth_first`, each block once) — not `isPotentiallyReachable`,
// whose 32-block scan limit answers `true` in a large function (the reason
// `blockOnCycle` is exact too).
bool reachesTwoReturns(Instruction *Term) {
  unsigned N = 0;
  for (BasicBlock *BB : depth_first(Term->getParent()))
    if (isa<ReturnInst>(BB->getTerminator()) && ++N >= 2)
      return true;
  return false;
}

// Is a `ret` block reachable from `From`'s successors along a path that never
// enters `Avoid`? (Exact; each block once.)
bool retReachableAvoiding(BasicBlock *From, BasicBlock *Avoid) {
  SmallPtrSet<BasicBlock *, 32> Seen;
  Seen.insert(Avoid);
  SmallVector<BasicBlock *, 16> Work;
  for (BasicBlock *S : successors(From))
    if (Seen.insert(S).second)
      Work.push_back(S);
  while (!Work.empty()) {
    BasicBlock *BB = Work.pop_back_val();
    if (isa<ReturnInst>(BB->getTerminator()))
      return true;
    for (BasicBlock *S : successors(BB))
      if (Seen.insert(S).second)
        Work.push_back(S);
  }
  return false;
}

// Do the `ret`s reachable from `TB` RECONVERGE first — is there a block every path
// from `TB` to a `ret` passes through? LLVM's `PostDominatorTree` answers the
// common case: a real immediate post-dominator is such a block. Its "virtual exit"
// answer is NOT a no, because the tree's roots are every exit, `unreachable` and
// infinite loops included: a tainted `br` beside an abort arm (`br %c, %die,
// %cont`, `%cont` later splitting CLASSICALLY into two `ret`s) has only the virtual
// post-dominator, yet both `ret`s are reached through `%cont`. So a virtual answer
// is re-asked exactly over the `ret` exits: `P` qualifies iff no `ret` is reachable
// from `TB` while avoiding `P` (one walk per candidate; only for a terminator that
// already reaches two `ret`s with no real post-dominator).
bool returnsReconverge(BasicBlock *TB, PostDominatorTree &PDT) {
  if (DomTreeNode *N = PDT.getNode(TB))
    if (DomTreeNode *IPD = N->getIDom(); IPD && IPD->getBlock())
      return true;
  for (BasicBlock *P : depth_first(TB))
    if (P != TB && !retReachableAvoiding(TB, P))
      return true;
  return false;
}

enum class ExitDisp { None, Normalize, LeaveForLoopOwner };

// Does `F` need the normalization? A tainted-control terminator NEEDS it iff its
// region does not reconverge before the function exits: two or more `ret`s are
// reachable from it and no block lies on every path from it to a `ret`
// (`returnsReconverge`). A region that reconverges at a real block before a later
// CLASSICAL branch splits into two `ret`s does not need it, and neither does an
// abort park whose continuation splits classically; their functions are left
// byte-untouched. `Normalize` iff some terminator needs it and NONE that needs it
// sits on a CFG cycle: a cyclic one is a multi-exit LOOP under quantum control
// (bd 8h7d's row), and the whole function is then left untouched so that row's
// loud declines fire on exactly the IR they fire on today
// (`lowering_reject_break_nonreconverging.ll`). `regionEntryInLoop` is the d8jl
// cycle predicate the detector itself asks.
ExitDisp classifyExits(Function &F, TaintSet &taint) {
  std::optional<PostDominatorTree> PDT;  // built on the first candidate only
  bool Flat = false;
  for (BasicBlock &BB : F) {
    Instruction *T = BB.getTerminator();
    if (!T || !isTaintedControlTerminator(T, taint) || !reachesTwoReturns(T))
      continue;
    if (!PDT)
      PDT.emplace(F);
    if (returnsReconverge(&BB, *PDT))
      continue;  // nothing to merge for this terminator
    if (regionEntryInLoop(T))
      return ExitDisp::LeaveForLoopOwner;
    Flat = true;
  }
  return Flat ? ExitDisp::Normalize : ExitDisp::None;
}

// The decline `What` if demoting the `musttail` call `CI` to `tail` would change
// the program, else empty. `musttail` promises two things: that the call is the
// last action before `ret` (which the merge necessarily breaks) and that it is
// LOWERED as a tail call (stack reuse). Its operands, its callee, its result and
// the callee's view of the caller's stack are unchanged by `tail` — LangRef: both
// markers imply the callee does not access the caller's allocas — so the
// demotion changes only stack depth, EXCEPT in the four cases refused here:
//   * a `preallocated` operand is legal only on a `musttail` call (or with the
//     "preallocated" bundle a forwarded argument has no token for): the demoted
//     call is invalid IR. The clone path refuses the same forward in `scanBody`
//     (SpecializeReject.cpp); IR-only, the 32-bit Windows C++ ABI. (`inalloca`
//     is NOT refused: a forwarded `inalloca` is legal on a plain call — the
//     clone path's measured precedent, `stripStaleClassicalAttrs`.)
//   * a variadic or "thunk" caller: `musttail` forwards the caller's
//     unprototyped variadic arguments (and, in a thunk, returns the callee's
//     result to the caller's caller); a plain call forwards nothing.
//   * an indirect callee: there is no body to ask the next question of.
//   * a callee that can reach the caller again (LLVM's `CallGraph`): `musttail`
//     is what keeps that recursion in constant stack, and a quantum-controlled
//     recursion needs a finite bound (NORTHSTAR goal 1) that nothing here can
//     supply. RESIDUAL, stated: a cycle closed through an INDIRECT call or an
//     opaque external callback is not an edge of the `CallGraph` and is not seen.
StringRef mustTailDemotionRefusal(CallInst *CI, Module &M,
                                  std::unique_ptr<CallGraph> &CG) {
  for (unsigned A = 0, E = CI->arg_size(); A < E; ++A)
    if (CI->paramHasAttr(A, Attribute::Preallocated))
      return "musttail forward of a preallocated argument";
  Function *Caller = CI->getFunction();
  if (Caller->isVarArg() || Caller->hasFnAttribute("thunk"))
    return "variadic musttail forward";
  Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return "indirect musttail call";
  if (Callee == Caller)
    return "recursive musttail call";
  if (!CG)
    CG = std::make_unique<CallGraph>(M);
  CallGraphNode *Target = (*CG)[Caller];
  for (CallGraphNode *N : depth_first((*CG)[Callee]))
    if (N == Target)
      return "recursive musttail call";
  return StringRef();
}

// Fold a former `ret` block that the merge left EMPTY (its only instruction is
// the new `br` to `Merge`) into its predecessors with SimplifyCFG's own
// empty-block removal. Refused — the forwarder is kept, which is semantically
// identical — when any predecessor already reaches `Merge` directly: folding then
// would give that predecessor's terminator two edges into `Merge`, and a tainted
// `br` with two identical successors is a shape no emitter is built for.
void foldEmptyForwarder(BasicBlock *BB, BasicBlock *Merge) {
  if (BB == &BB->getParent()->getEntryBlock() || pred_empty(BB))
    return;
  auto *Br = dyn_cast<BranchInst>(&BB->front());
  if (!Br || Br->isConditional() || Br->getSuccessor(0) != Merge)
    return;
  for (BasicBlock *P : predecessors(BB))
    if (is_contained(predecessors(Merge), P))
      return;
  TryToSimplifyUncondBranchFromEmptyBlock(BB, /*DTU=*/nullptr);
}

}  // namespace

bool unifyTaintedReturns(Module &M, TaintSet &taint,
                         SmallPtrSetImpl<Value *> *Delta) {
  bool Changed = false;
  SmallVector<Value *, 4> Seeds;
  std::unique_ptr<CallGraph> CG;  // built on the first direct `musttail` asked
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Identities captured BEFORE the first mutation (Rule 9 / CLAUDE.md R8).
    SmallVector<ReturnInst *, 4> Rets;
    for (BasicBlock &BB : F)
      if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
        Rets.push_back(R);
    if (Rets.size() < 2 || classifyExits(F, taint) != ExitDisp::Normalize)
      continue;

    // (1) Every `musttail` before one of these `ret`s is asked FIRST, and a
    // single refusal leaves the whole function untouched (detect before mutate).
    SmallVector<CallInst *, 4> MustTail;
    bool Refused = false;
    for (ReturnInst *R : Rets)
      if (CallInst *CI = R->getParent()->getTerminatingMustTailCall()) {
        StringRef Why = mustTailDemotionRefusal(CI, M, CG);
        if (!Why.empty()) {
          diagnoseUnderControl(CI, Why);
          Refused = true;
        }
        MustTail.push_back(CI);
      }
    if (Refused)
      continue;
    for (CallInst *CI : MustTail)
      CI->setTailCallKind(CallInst::TCK_Tail);  // the twin's own marker

    // (2) The merge.
    SmallVector<BasicBlock *, 4> RetBlocks;
    for (ReturnInst *R : Rets)
      RetBlocks.push_back(R->getParent());
    MergedReturn MR = mergeReturnBlocks(F, Rets, "cq.retmerge", "cq.ret",
                                        /*CarryDebugLoc=*/true);

    // (3) A φ of one value is that value.
    if (MR.Phi)
      if (Value *V = MR.Phi->hasConstantValue()) {
        MR.Phi->replaceAllUsesWith(V);
        MR.Phi->eraseFromParent();
        MR.Phi = nullptr;
      }

    // (4) Empty forwarders, in layout order.
    for (BasicBlock *BB : RetBlocks)
      foldEmptyForwarder(BB, MR.Merge);

    if (MR.Phi && any_of(MR.Phi->incoming_values(),
                         [&](Value *V) { return taint.Tainted.count(V) > 0; })) {
      taint.Tainted.insert(MR.Phi);
      Seeds.push_back(MR.Phi);
    }
    Changed = true;
  }
  propagateFromSeeds(taint, Seeds, Delta);
  return Changed;
}

}  // namespace cq
