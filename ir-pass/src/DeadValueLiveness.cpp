// DeadValueLiveness.cpp — see DeadValueLiveness.h (bd test_C_libtooling-vsfp r2).

#include "DeadValueLiveness.h"

#include "CalleeBody.h"  // calleeBodyTrusted (bd p3kd.2)

#include "SpecializeDetect.h"  // nullSafeSlot (bd 91k9 / w7nm: the ONE null-soundness rule)
#include "TaintPropagation.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/InstructionSimplify.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Local.h"

#include <algorithm>
#include <cstdlib>
#include <string>

using namespace llvm;

namespace cq {

namespace {

bool isFrontEndIntrinsicSite(const CallBase &CB, const TaintSet &taint) {
  const auto *CI = dyn_cast<CallInst>(&CB);
  if (!CI)
    return false;  // an invoke is a terminator — a root on that ground already.
  return taint.ThetaCalls.contains(CI) || taint.PhiCalls.contains(CI) ||
         taint.PhaseCalls.contains(CI) || taint.MeasureCalls.contains(CI);
}

// An "empty arm": nothing but its unconditional branch (debug intrinsics aside).
bool isEmptyUncondArm(const BasicBlock &B) {
  const auto *BI = dyn_cast<BranchInst>(B.getTerminator());
  if (!BI || BI->isConditional())
    return false;
  for (const Instruction &I : B)
    if (&I != BI && !isa<DbgInfoIntrinsic>(I))
      return false;
  return true;
}

// Is `F`'s BODY side-effect-free and terminating, asked of the body itself
// rather than of `F`'s attributes? Deliberately narrow: an exact, non-`naked`,
// non-variadic definition whose CFG is ACYCLIC (so every execution terminates),
// with no call of any kind (a debug intrinsic aside), no instruction that may
// write memory, throw or not return, and only `br`/`switch`/`ret` terminators.
// It exists because the attributes `clang -O1` inferred can be STALE here: the
// fenv stages erase a callee's volatile store after `-O1` inferred
// `memory(inaccessiblemem: readwrite)` without `willreturn` from it (bd vsfp
// round 2, r1B probe `v16`), and hand-written IR carries no attributes at all.
bool bodyIsSideEffectFree(const Function &F) {
  // `AssumeOfLinkedCall` (bd p3kd.2, CalleeBody.h; unchanged behaviour). A
  // "not a root" verdict licenses more than deleting the call: the drop reads it
  // as "this caller's parameter is dead" and rewrites the OUTER call's operand,
  // and a clone's recorded dead slots are built on it. Deleting a call to a
  // derefinable ODR body would be sound (inline the visible body, then DCE it),
  // but until every such consumer is shown to delete the call it reasons about,
  // a derefined variant that still reads the operand must not be possible.
  if (!calleeBodyTrusted(&F, CalleeBodyUse::AssumeOfLinkedCall) || F.isVarArg() ||
      F.hasFnAttribute(Attribute::Naked))
    return false;
  SmallVector<std::pair<const BasicBlock *, const BasicBlock *>, 4> BackEdges;
  FindFunctionBackedges(F, BackEdges);
  if (!BackEdges.empty())
    return false;
  for (const BasicBlock &BB : F)
    for (const Instruction &I : BB) {
      if (isa<DbgInfoIntrinsic>(I))
        continue;
      if (I.isTerminator()) {
        if (!isa<BranchInst>(I) && !isa<SwitchInst>(I) && !isa<ReturnInst>(I))
          return false;
        continue;
      }
      if (isa<CallBase>(I) || I.mayHaveSideEffects() || I.isEHPad())
        return false;
    }
  return true;
}

}  // namespace

bool isLivenessRoot(const Instruction &I, const TaintSet &taint) {
  if (I.isTerminator() || I.isEHPad())
    return true;
  if (const auto *CB = dyn_cast<CallBase>(&I)) {
    // ROOTS BY IDENTITY, asked FIRST so no later rule can override them:
    //   * a front-end intrinsic SITE (`cq_theta`/`cq_phi`/`cq_measure`), by
    //     MEMBERSHIP of the taint lists — never by name or attribute;
    //   * a call to a function the SPECIALIZER built (a `__cq_q_*` clone or its
    //     `_unc` twin), by its own record `SpecHandleArgMask` — never by name;
    //   * a call into the project's RESERVED namespaces (`cq_*` front end and
    //     markers, `__cq_*` clones and markers, `cqrt_*`/`cq_template_*`
    //     runtime). Every such function the front end and the pass produce is a
    //     DECLARATION without attributes (a root on the side-effect ground
    //     anyway); this covers a module that DEFINES one with a pure body — the
    //     reserved-name case r1A F-VA-5 measured for `cq_theta_si32`. ⚠ The NAME
    //     is used here only to ADD a root, the conservative direction: it can
    //     refuse a deletion, never allow one. (The first spelling of this rule sat
    //     AFTER the side-effect branch below and was therefore never reached for a
    //     defined attribute-less callee — measured on
    //     spec_accept_dropped_arg_reserved_marker_kept.ll before it was moved.)
    if (isFrontEndIntrinsicSite(*CB, taint))
      return true;
    if (const Function *Callee = CB->getCalledFunction()) {
      if (taint.SpecHandleArgMask.count(Callee))
        return true;
      StringRef N = Callee->getName();
      if (N.starts_with("cq_") || N.starts_with("__cq_") || N.starts_with("cqrt_"))
        return true;
    }
  }
  if (I.mayHaveSideEffects()) {
    // A call LLVM cannot prove side-effect-free from ATTRIBUTES is still not a
    // root when it is a direct `call` whose callee's BODY is side-effect-free and
    // terminating (see `bodyIsSideEffectFree`). Everything else that may have a
    // side effect — a store, a volatile or atomic access, a fence, an invoke, an
    // indirect call, a call to a declaration — is a root.
    const auto *CB = dyn_cast<CallBase>(&I);
    const Function *Callee = CB ? CB->getCalledFunction() : nullptr;
    return !Callee || !isa<CallInst>(CB) || !bodyIsSideEffectFree(*Callee);
  }
  return false;
}

bool isRecordedDeadSlot(const CallBase &CB, unsigned ArgNo,
                        const TaintSet &taint) {
  const Function *Callee = CB.getCalledFunction();
  if (!Callee || ArgNo >= 64 || ArgNo >= Callee->arg_size())
    return false;
  auto It = taint.SpecDeadArgMask.find(Callee);
  if (It == taint.SpecDeadArgMask.end())
    return false;
  return (It->second >> ArgNo) & 1;
}

bool isRewritableDeadSlot(const CallBase &CB, unsigned ArgNo,
                          const TaintSet &taint) {
  return isRecordedDeadSlot(CB, ArgNo, taint) && nullSafeSlot(CB, ArgNo);
}

bool isUnreadScalarSlot(const CallBase &CB, unsigned ArgNo,
                        const TaintSet &taint) {
  if (!isRecordedDeadSlot(CB, ArgNo, taint))
    return false;
  FunctionType *FT = CB.getFunctionType();
  if (ArgNo >= FT->getNumParams())
    return false;
  Type *T = FT->getParamType(ArgNo);
  return T->isIntegerTy() || T->isFloatingPointTy();
}

void stripParamValueConstraints(Function &F, unsigned ArgNo) {
  if (ArgNo < F.arg_size())
    for (Attribute::AttrKind K : {Attribute::Range, Attribute::NoFPClass})
      F.removeParamAttr(ArgNo, K);
}

void stripUnreadSlotValueConstraints(CallBase &CB, unsigned ArgNo) {
  if (Function *Callee = CB.getCalledFunction(); Callee && ArgNo < Callee->arg_size()) {
    stripParamValueConstraints(*Callee, ArgNo);
    for (Attribute::AttrKind K : {Attribute::Range, Attribute::NoFPClass})
      CB.removeParamAttr(ArgNo, K);
  }
}

bool rewriteRecordedDeadSlotUse(Use &U, const TaintSet &taint) {
  auto *CB = dyn_cast<CallBase>(U.getUser());
  if (!CB || !CB->isArgOperand(&U) || isa<Constant>(U.get()))
    return false;
  unsigned A = CB->getArgOperandNo(&U);
  if (!isRewritableDeadSlot(*CB, A, taint))
    return false;
  FunctionType *FT = CB->getFunctionType();
  Type *SlotTy = A < FT->getNumParams() ? FT->getParamType(A) : U.get()->getType();
  stripUnreadSlotValueConstraints(*CB, A);
  U.set(Constant::getNullValue(SlotTy));
  return true;
}

FunctionLiveness::FunctionLiveness(const Function &F, const TaintSet &taint,
                                   SlotReads Mode) {
  SmallVector<const Instruction *, 64> Worklist;
  auto markLive = [&](const Value *V) {
    if (!isa<Instruction>(V) && !isa<Argument>(V))
      return;
    if (!Live.insert(V).second)
      return;
    if (const auto *I = dyn_cast<Instruction>(V))
      Worklist.push_back(I);
  };
  for (const BasicBlock &BB : F)
    for (const Instruction &I : BB)
      if (isLivenessRoot(I, taint))
        markLive(&I);
  while (!Worklist.empty()) {
    const Instruction *I = Worklist.pop_back_val();
    if (const auto *CB = dyn_cast<CallBase>(I)) {
      // Operands of a call: an argument slot the callee is RECORDED never to read
      // does not propagate when nothing in THIS function has to keep its operand
      // alive; the called operand, bundle operands and every other slot do.
      //   * a REWRITABLE slot (`isRewritableDeadSlot`: recorded dead AND
      //     null-safe) — the one rewrite nulls it, so its operand is not a use;
      //   * an UNREAD SCALAR slot (`isUnreadScalarSlot`: recorded dead, int/fp)
      //     whose operand is an ARGUMENT — bd `nlfd` (vsfp Rule-13 r6 F-R6-1). An
      //     argument is never deleted, so "the operand must survive" asks nothing
      //     of it, and its VALUE is never observed there (the callee never reads
      //     the slot; a scalar slot is not dereferenced by the call). Counting it
      //     was NOT the conservative direction: through `deadParamMask` it made
      //     the ENCLOSING clone's parameter LIVE one level up, the outer
      //     (null-safe) phantom slot was never neutralised, and bd `tzfa`'s wrong
      //     unitary came back (r6 `sa1.ll`: a string attribute on the inner slot)
      //     — on `main` 9a230646; since bd rhk5 the phantom read is not a wrong
      //     unitary any more (bd `test_C_libtooling-ur72`), and this clause is kept
      //     as a strict improvement (no phantom operand, no over-warn).
      //   * in `SlotReads::Value` mode, EVERY unread scalar slot — the question
      //     "is the VALUE observed?", asked only by `buildClone`'s bd `nlfd` fence.
      // ⚠ bd `91k9` (round 5): a recorded-dead slot that is NOT null-safe keeps an
      // INSTRUCTION operand live in the default (existence) mode — it is never
      // rewritten, so that value is still a use of the call and `deleteDeadCones`
      // step 3 must not delete it. A pointer slot (`byval` copies its pointee at
      // the CALL) is never an unread scalar slot. ⚠ bd `w7nm` (round 6): the
      // rewrite question is NULL-SOUNDNESS only, never the drop's policy.
      for (const Use &U : CB->operands()) {
        if (CB->isArgOperand(&U)) {
          const unsigned A = CB->getArgOperandNo(&U);
          if (isRewritableDeadSlot(*CB, A, taint))
            continue;
          if ((Mode == SlotReads::Value || isa<Argument>(U.get())) &&
              isUnreadScalarSlot(*CB, A, taint))
            continue;
        }
        markLive(U.get());
      }
      continue;
    }
    for (const Use &U : I->operands())
      markLive(U.get());
  }
}

bool FunctionLiveness::isLive(const Value *V) const { return Live.count(V); }

uint64_t deadParamMask(const Function &F, const TaintSet &taint, SlotReads Mode) {
  return deadParamMask(F, FunctionLiveness(F, taint, Mode));
}

uint64_t deadParamMask(const Function &F, const FunctionLiveness &L) {
  uint64_t Mask = 0;
  for (const Argument &A : F.args())
    if (A.getArgNo() < 64 && !L.isLive(&A))
      Mask |= uint64_t(1) << A.getArgNo();
  return Mask;
}

unsigned deleteDeadCones(Function &F, ArrayRef<Value *> Seeds,
                         const TaintSet &taint, StringRef Stage,
                         ArrayRef<BasicBlock *> CallerTouched) {
  FunctionLiveness L(F, taint);

  // 1. The dead backward cone: from each dead seed through the operands of dead
  //    instructions. A live operand stops the walk (and every operand of a live
  //    instruction is live, so nothing dead lies behind it on this path).
  SmallPtrSet<Instruction *, 32> Del;
  SmallVector<Instruction *, 32> Worklist;
  auto visit = [&](Value *V) {
    auto *I = dyn_cast<Instruction>(V);
    // A debug intrinsic is never a liveness ROOT (it is side-effect-free) and is
    // never deleted here: it carries metadata, not a value, and a deleted
    // operand is salvaged or dropped from it by `salvageDebugInfo`.
    if (!I || isa<DbgInfoIntrinsic>(I) || I->getFunction() != &F ||
        L.isLive(I) || !Del.insert(I).second)
      return;
    Worklist.push_back(I);
  };
  for (Value *S : Seeds)
    visit(S);
  while (!Worklist.empty()) {
    Instruction *I = Worklist.pop_back_val();
    for (Use &U : I->operands())
      visit(U.get());
  }
  // 2. Forward-close over users. Every user of a dead instruction is dead (a live
  //    user would have made it live), so this never reaches a live instruction —
  //    it only makes the set closed, so nothing left behind references a deleted
  //    value.
  for (Instruction *I : SmallVector<Instruction *, 32>(Del.begin(), Del.end()))
    Worklist.push_back(I);
  while (!Worklist.empty()) {
    Instruction *I = Worklist.pop_back_val();
    for (User *U : I->users())
      if (auto *UI = dyn_cast<Instruction>(U))
        if (!isa<DbgInfoIntrinsic>(UI) && !L.isLive(UI) && Del.insert(UI).second)
          Worklist.push_back(UI);
  }
  // 3. Delete: salvage debug info, drop every reference, then erase — so the
  //    erase order inside the (possibly cyclic) set does not matter.
  // Blocks the CALLER emptied count as touched (bd vsfp round 2: the fenv store
  // erasure empties `if (a > 3) { volatile int z = 1; }` itself — measured, the
  // empty diamond then kept `a` live in the callee and a C program reached the
  // phantom-read backstop instead of lowering to its fenv-intended twin).
  SmallPtrSet<BasicBlock *, 8> Touched(CallerTouched.begin(), CallerTouched.end());
  for (Instruction *I : Del) {
    Touched.insert(I->getParent());
    salvageDebugInfo(*I);
  }
  // A dead value may still be an operand of a LIVE call — exactly when that call's
  // slot is one the specializer RECORDED dead AND the rewrite may null
  // (`isRewritableDeadSlot`; the call-slot rule is the one place liveness does not
  // follow an operand, and for an INSTRUCTION operand of a recorded-dead slot that
  // is NOT null-safe it does follow it — bd 91k9 — so that operand is never in
  // `Del`). Such a slot gets the null constant of the
  // CALLEE PARAMETER's type (bd `f061`'s lesson: after retargeting, an fp slot is an
  // `i32` handle), with `range`/`nofpclass` stripped — the drop's own rewrite. Only
  // reachable after `specialize()` has written a record, i.e. inside a clone body
  // (bd `sqjq`: a nested clone call INHERITS the dead slot, r3A `n5_nested.ll`); the
  // pre-`specialize()` callers see an empty record and never take this branch.
  for (Instruction *I : Del)
    for (Use &U : make_early_inc_range(I->uses()))
      if (auto *CB = dyn_cast<CallBase>(U.getUser()); CB && !Del.count(CB))
        rewriteRecordedDeadSlotUse(U, taint);  // a live reader of a dead `I` can
                                                // only be such a slot.
  for (Instruction *I : Del)
    I->dropAllReferences();
  unsigned N = Del.size();
  for (Instruction *I : Del)
    I->eraseFromParent();

  // 4. The empty-arm fold — SimplifyCFG's two shapes for a conditional branch
  //    whose arms are EMPTY (`-O1` applies both to the hand-inlined twin; r1A
  //    F-VA-4: without them an arm this deletion emptied left an empty diamond
  //    on a quantum condition, `control flow under quantum control` where the
  //    twin accepts). Only a branch one of whose arms — or whose common
  //    successor — this call TOUCHED (a deletion there, or a block the CALLER
  //    reports it emptied) is considered; an empty-arm shape `-O1` left in place
  //    elsewhere (it folds most of them; its φ fold has a cost limit) is not
  //    rewritten here.
  //    Both successors must reach one block `S` either directly or through an
  //    arm that is nothing but `br S` with this branch as its only predecessor
  //    (never the entry block, never an address-taken block). Then:
  //      * `S` has no φ — the branch has no effect: it becomes `br S`;
  //      * `S` has φs and exactly the two paths as predecessors — the
  //        two-entry-φ fold (`FoldTwoEntryPHINode`): each φ becomes
  //        `select Cond, v_true, v_false` before the branch, and the branch
  //        becomes `br S`. The incoming values are available at the branch: an
  //        empty arm defines nothing, so a value flowing out of it dominates it,
  //        and its only predecessor is the branch's block.
  //    Anything else (a merge with a third predecessor and a φ) is left alone.
  // ⚠ The condition seeds are TRACKING handles (bd `test_C_libtooling-1xp9`, bd
  // vsfp Rule-13 r3B F-XB-1 — a use-after-free reachable from plain C): a seed
  // that is an `i1` φ in an EARLIER fold's merge block is erased by that block's
  // `MergeBlockIntoPredecessor` below (`FoldSingleEntryPHINodes` RAUWs the now
  // single-entry φ to its value and deletes it), and round 2/3 held it as a raw
  // `Value *`, so the recursive call read freed memory (SIGSEGV on r3B `u5.c`,
  // whose conditions are classical; silent UB on `u2.ll`). A `WeakTrackingVH`
  // FOLLOWS that RAUW, so the seed becomes the φ's replacement — typically the
  // earlier fold's `select` — and the recursion deletes that select if it is
  // now dead. Skipping a nulled seed instead (a `WeakVH`) would leave such a
  // dead select behind, and a dead select on a TAINTED condition is a which-path
  // rail nobody discharges (bd qjoc's class). Recursing BEFORE the merge loop
  // would also avoid the dangling read, but on a CFG `-O1` would not leave
  // (single-entry φs still standing); the tracking handle keeps the order the
  // twin gets — CFG simplification first, then dead-code elimination.
  SmallVector<WeakTrackingVH, 4> CondSeeds;
  SmallVector<WeakVH, 4> Merge;
  unsigned Folded = 0;
  SmallPtrSet<BasicBlock *, 8> Erased;
  // Candidate arms: every block the deletion touched, and every predecessor of
  // one (a merge that lost its only φ leaves arms that were already empty).
  SmallVector<BasicBlock *, 8> Cands(Touched.begin(), Touched.end());
  for (BasicBlock *T : SmallVector<BasicBlock *, 8>(Touched.begin(), Touched.end()))
    for (BasicBlock *PB : predecessors(T))
      Cands.push_back(PB);
  for (BasicBlock *Arm : Cands) {
    if (Erased.count(Arm) || !isEmptyUncondArm(*Arm) || Arm->hasAddressTaken() ||
        Arm == &F.getEntryBlock())
      continue;
    BasicBlock *P = Arm->getSinglePredecessor();
    if (!P || P == Arm || Erased.count(P))
      continue;
    auto *BI = dyn_cast<BranchInst>(P->getTerminator());
    if (!BI || !BI->isConditional())
      continue;
    auto isArm = [&](BasicBlock *B) {
      return B != &F.getEntryBlock() && !B->hasAddressTaken() &&
             isEmptyUncondArm(*B) && B->getSinglePredecessor() == P;
    };
    BasicBlock *B0 = BI->getSuccessor(0), *B1 = BI->getSuccessor(1);
    BasicBlock *S0 = isArm(B0) ? B0->getSingleSuccessor() : B0;
    BasicBlock *S1 = isArm(B1) ? B1->getSingleSuccessor() : B1;
    if (!S0 || S0 != S1 || S0 == P)
      continue;
    BasicBlock *S = S0;
    BasicBlock *E0 = isArm(B0) ? B0 : P, *E1 = isArm(B1) ? B1 : P;
    const bool HasPhi = isa<PHINode>(S->begin());
    if (HasPhi) {
      // S's predecessors are exactly the two paths (FoldTwoEntryPHINode's
      // precondition); a third predecessor keeps its own φ entry and the fold
      // would have to split it — left alone.
      bool OnlyOurs = true;
      for (BasicBlock *SP : predecessors(S))
        OnlyOurs &= SP == E0 || SP == E1;
      if (!OnlyOurs)
        continue;
    }
    Value *Cond = BI->getCondition();
    SmallVector<std::pair<PHINode *, Value *>, 4> NewIn;
    for (PHINode &Phi : S->phis()) {
      Value *VT = Phi.getIncomingValueForBlock(E0);
      Value *VF = Phi.getIncomingValueForBlock(E1);
      // `select %c, i1 true, i1 false` IS `%c`, so ask the folder first (bd vsfp
      // round 4: r3B `u1.ll`'s cascaded fold otherwise left a logical `select i1`
      // as a 4.4 data select's condition, which the data-select grammar refuses —
      // an over-decline against the twin). ⚠ Round 4's comment said this is what
      // SimplifyCFG's `FoldTwoEntryPHINode` builds — FALSE (bd `w9xe`, r4B F-YB-2,
      // measured): stock SimplifyCFG builds through `IRBuilder<NoFolder>` and emits
      // `select i1 %c, i1 true, i1 false`; the `-O1` twin loses it only in the LATER
      // InstCombine. The parity bar is SimplifyCFG + InstCombine, of which this is
      // one fold. `simplifySelectInst` returns only an EXISTING value (a constant,
      // `Cond`, `VT`, `VF` or an operand of `Cond`'s compare — all available at the
      // branch), never a new instruction.
      Value *NV = VT == VF ? VT
                           : simplifySelectInst(Cond, VT, VF,
                                                SimplifyQuery(F.getParent()->getDataLayout()));
      if (!NV)
        NV = SelectInst::Create(Cond, VT, VF, Phi.getName() + ".cq.dce.sel", BI);
      NewIn.push_back({&Phi, NV});
    }
    BranchInst::Create(S, BI);
    BI->eraseFromParent();
    for (auto &[Phi, NV] : NewIn) {
      for (BasicBlock *E : {E0, E1})
        if (E != P && Phi->getBasicBlockIndex(E) >= 0)
          Phi->removeIncomingValue(E, /*DeletePHIIfEmpty=*/false);
      if (Phi->getBasicBlockIndex(P) >= 0)
        Phi->setIncomingValueForBlock(P, NV);
      else
        Phi->addIncoming(NV, P);
    }
    for (BasicBlock *A : {B0, B1})
      if (A != S && !Erased.count(A)) {
        // Now unreachable: its only predecessor no longer branches to it, and
        // its own incoming entries in S were removed above.
        A->eraseFromParent();
        Erased.insert(A);
      }
    // The condition is a seed whenever the fold leaves it dead: no φ, or every φ
    // had EQUAL incomings (`int r = (q > 3) ? K : 0;` with `K == 0` once the
    // volatile global fold read `K`). For a CLASSICAL condition that is cleanup
    // only (a dead compare keeps no parameter live under liveness); for a TAINTED
    // one it is load-bearing: the dead compare would be lowered as a forward
    // template never uncomputed — a dirty flag (bd vsfp round 3, mutant S2,
    // `lowering_volatile_globalfold_equal_phi.ll`). A condition a new `select`
    // reads is live and the recursive call deletes nothing.
    CondSeeds.push_back(Cond);
    Merge.push_back(WeakVH(S));
    ++Folded;
  }
  // SimplifyCFG's last step on the same shape: S now has the one predecessor P,
  // whose only successor it is, so the two blocks are one (and a single-entry φ
  // left by the fold is folded to its value). Without it the φ survives as a
  // one-register "mux" the classical-mux guard refuses (measured, r1A `ediam2`).
  for (WeakVH &H : Merge)
    if (auto *S = dyn_cast_or_null<BasicBlock>(H.operator Value *()))
      if (!S->hasAddressTaken())
        MergeBlockIntoPredecessor(S);
  if (::getenv("CQ_DEADCONE_DBG") && (N || Folded))
    errs() << "CQ_DEADCONE_DBG: " << Stage << " deleted " << N << " in @"
           << F.getName() << (Folded ? " (folded " + std::to_string(Folded) + " empty arm(s))" : std::string())
           << "\n";
  SmallVector<Value *, 4> Live;
  for (WeakTrackingVH &H : CondSeeds)
    if (Value *V = H)
      Live.push_back(V);  // a seed ERASED (not RAUW'd) has nothing left to delete.
  if (!Live.empty())
    N += deleteDeadCones(F, Live, taint, Stage);
  return N;
}

}  // namespace cq
