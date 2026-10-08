// StaleReadPlacement.cpp — see StaleReadPlacement.h (owner ruling bd 57ch (A);
// first customer bd test_C_libtooling-r2j3.6).

#include "StaleReadPlacement.h"

#include "CalleeBody.h"         // calleeBodyTrusted (review round 4 R4-1)
#include "DeadValueLiveness.h"  // isFrontEndIntrinsicSite
#include "TaintPropagation.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/CaptureTracking.h"  // PointerMayBeCaptured (review round 5)
#include "llvm/Analysis/ValueTracking.h"  // isGuaranteedToTransferExecutionToSuccessor
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Support/ModRef.h"

using namespace llvm;

namespace cq {

namespace {

bool isFrontEndSite(const Instruction &J, const TaintSet &taint) {
  const auto *CB = dyn_cast<CallBase>(&J);
  return CB && isFrontEndIntrinsicSite(*CB, taint);  // membership, never a name
}

bool isMustTail(const Instruction &J) {
  const auto *CB = dyn_cast<CallBase>(&J);
  return CB && CB->isMustTailCall();
}

// Clause (e): the memory an instruction may touch, as {reads, writes}, asked the
// same way of a MOVED and of a CROSSED one (review round 2 R2-5). A call to a
// DEFINITION is asked of the definition's own summary (what -O1 inferred from the
// body), never of the call site: `bindLibmCalls` keeps the libc declaration's
// call-site attributes on a call it binds to an injected body (review round 1 F4;
// `lgamma` writes `signgam`). The witness that a lifted call writes nothing and
// reads only constant tables is `scanBody`'s acceptance (SpecializeReject.cpp: a
// store, a non-QROM load, an atomic are rejects); asking the body's own summary
// keeps this clause sound if `scanBody` is ever widened (a by-ref out-parameter,
// R16's volatile reads) without anyone re-reading it. An ordered (volatile or
// atomic) load counts as a write, as `Instruction::mayWriteToMemory` says.
std::pair<bool, bool> memoryEffectsOf(const Instruction &X) {
  if (const auto *CB = dyn_cast<CallBase>(&X))
    if (const Function *Callee = CB->getCalledFunction();
        Callee && !Callee->isDeclaration()) {
      const ModRefInfo MR = Callee->getMemoryEffects().getModRef();
      return {isRefSet(MR), isModSet(MR)};
    }
  return {X.mayReadFromMemory(), X.mayWriteToMemory()};
}

// ── THE ORDERED EVENTS (OWNER RULING 2026-10-08, clarified in review round 5; bd
// memory owner-ruling-gates-ordered-vs-volatile-atomic-2026-10-08): gate emission is
// ordered against OBSERVABLE volatile, atomic and fence events, so no code motion of
// this placement (the moved call, a carried operand) may cross one in either
// direction. ONE predicate, asked of a crossed instruction, of every instruction of
// a crossed call's body, and of a carried operand (review round 5 R5-1, R12):
//   * any volatile access, and any fence;
//   * any atomic access (load, store, rmw, cmpxchg; ANY ordering) unless its object
//     is provably a function-local alloca whose address is never captured
//     (`getUnderlyingObject` + `PointerMayBeCaptured`): such an atomic is not
//     observable, by the reasoning R16 applies to an unreachable volatile.
bool isObservableOrderedEvent(const Instruction &X) {
  if (X.isVolatile() || isa<FenceInst>(X))
    return true;
  if (!X.isAtomic())
    return false;
  const Value *Ptr = getLoadStorePointerOperand(&X);
  if (const auto *RMW = dyn_cast<AtomicRMWInst>(&X))
    Ptr = RMW->getPointerOperand();
  else if (const auto *CX = dyn_cast<AtomicCmpXchgInst>(&X))
    Ptr = CX->getPointerOperand();
  const auto *AI = Ptr ? dyn_cast<AllocaInst>(getUnderlyingObject(Ptr)) : nullptr;
  return !AI || PointerMayBeCaptured(AI, /*ReturnCaptures=*/true,
                                     /*StoreCaptures=*/true);
}

// ── MAY THE MOVED GATES CROSS (or a carried operand be) CALL `CB`? (review rounds
// 4-5, R4-1/R5-1/R5-2/R5-3.) A call is an ordered event iff it may perform one, so
// it is crossable when LLVM's facts prove it cannot, and refused otherwise — asked
// the SAME way at every depth (a crossed call, a call inside a crossed body, a
// carried call):
//   * LLVM proves it touches no memory (`memoryEffectsOf` empty): no volatile access
//     (LLVM 19 models one as `inaccessiblemem`), no fence, and no atomic on an
//     escaping object — NOT because the inference inspects atomics (it ignores an
//     atomic on ANY alloca, captured or not) but because publishing an alloca's
//     address is itself a modeled effect (a store to visible memory, an escaping
//     call argument), which a `memory(none)` function cannot have. So crossable.
//     (It can disagree with the body walk on a local whose address is stored only
//     into another never-captured local: the walk refuses, the summary admits; both
//     are safe, the summary's answer being the exact one.)
//   * a REAL intrinsic (`getIntrinsicID() != not_intrinsic`, never the `llvm.` name
//     prefix — a user declaration can carry it, R5-2): a memory intrinsic that is not
//     volatile, or a `nosync` one that is no other memory intrinsic;
//   * a call to a VISIBLE definition whose body the linked call runs
//     (`calleeBodyTrusted`, AssumeOfLinkedCall) holding, transitively (memoized; a
//     cycle refuses), no observable ordered event and no call that is not itself
//     crossable (`nosync` is not asked of a body: it admits a monotonic atomic);
//   * anything else (an opaque declaration that may touch memory, an indirect call,
//     inline asm): refused.
// Clause (e)'s memory conflict with the moved set still applies on top.
using CrossMemo = DenseMap<const Function *, bool>;

bool callCrossable(const CallBase &CB, CrossMemo &Memo);

bool bodyHoldsNoOrderedEvent(const Function &F, CrossMemo &Memo) {
  if (auto It = Memo.find(&F); It != Memo.end())
    return It->second;  // done, or in progress (false: a cycle refuses)
  Memo[&F] = false;
  for (const Instruction &X : instructions(F)) {
    if (isObservableOrderedEvent(X))
      return false;
    if (const auto *CB = dyn_cast<CallBase>(&X); CB && !callCrossable(*CB, Memo))
      return false;
  }
  Memo[&F] = true;
  return true;
}

bool callCrossable(const CallBase &CB, CrossMemo &Memo) {
  if (CB.isInlineAsm())
    return false;
  if (const auto [Reads, Writes] = memoryEffectsOf(CB); !Reads && !Writes)
    return true;
  const Function *Callee = CB.getCalledFunction();
  if (!Callee)
    return false;  // indirect: no body to ask
  if (Callee->getIntrinsicID() != Intrinsic::not_intrinsic) {
    if (const auto *MI = dyn_cast<MemIntrinsic>(&CB))
      return !MI->isVolatile();
    return !isa<AnyMemIntrinsic>(CB) && CB.hasFnAttr(Attribute::NoSync);
  }
  if (!calleeBodyTrusted(Callee, CalleeBodyUse::AssumeOfLinkedCall))
    return false;  // an opaque declaration, or a body the linker may replace
  return bodyHoldsNoOrderedEvent(*Callee, Memo);
}

// A CARRIED classical operand (review round 2 R2-1, round 5 R5-1): no observable
// ordered event, and a call only if crossable by the same test as above (which also
// refuses inline asm). Its memory conflicts with what it crosses are clause (e)'s.
bool carriableEffects(const Instruction &X, CrossMemo &Memo) {
  if (const auto *CB = dyn_cast<CallBase>(&X))
    return !isObservableOrderedEvent(X) && callCrossable(*CB, Memo);
  return !isObservableOrderedEvent(X);
}

}  // namespace

Instruction *staleReadInsertPoint(Instruction &I, ArrayRef<CallInst *> Stalers,
                                  const TaintSet &taint, const DominatorTree &DT,
                                  SmallVectorImpl<Instruction *> &Carried) {
  Carried.clear();
  if (Stalers.empty() || isa<PHINode>(I) || I.isTerminator() || I.isEHPad() ||
      isMustTail(I))
    return nullptr;  // a `musttail` call must stay immediately before its `ret`.
  // (a) one block, every staler before `I`; the slot is the earliest staler.
  BasicBlock *BB = I.getParent();
  Instruction *At = nullptr;
  for (CallInst *T : Stalers) {
    if (T->getParent() != BB || !T->comesBefore(&I))
      return nullptr;
    if (!At || T->comesBefore(At))
      At = T;
  }
  // (b) every operand available at the slot, or a CLASSICAL instruction between
  // the slot and `I` that is carried along (review round 1 F2: `f(q, argc * 3)`
  // with the `mul` scheduled after the gate). A carried value is untainted, no
  // front-end site, reads nothing tainted (moving it would move a read of a wire)
  // and has only modeled effects (`carriableEffects`, R2-1), so it does not depend
  // on the gate. A TAINTED operand defined after the gate refuses: either it
  // depends on the gate (57ch (B): the old label and a post-gate value at once) or
  // it is an INDEPENDENT register whose own front-end gates would have to move
  // above the slot (`f(q, p)` with `p` minted after it: a commuting reorder on
  // disjoint wires, not built — r2j3.6 follow-up F8). An operand not dominating
  // the slot dominates its user, so it lies in [slot, user) of this block.
  CrossMemo Memo;  // one memo for every crossing question of this placement
  SmallPtrSet<Instruction *, 8> Move;
  SmallVector<Instruction *, 8> Work;
  Move.insert(&I);
  Work.push_back(&I);
  while (!Work.empty()) {
    Instruction *X = Work.pop_back_val();
    for (Value *Op : X->operands()) {
      auto *OpI = dyn_cast<Instruction>(Op);
      if (!OpI || Move.count(OpI) || DT.dominates(OpI, At))
        continue;
      if (OpI->getParent() != BB || taint.Tainted.count(OpI) ||
          isa<PHINode>(OpI) || OpI->isEHPad() || isFrontEndSite(*OpI, taint) ||
          isMustTail(*OpI) || readsTaintedValue(*OpI, taint) ||
          !carriableEffects(*OpI, Memo))
        return nullptr;
      Move.insert(OpI);
      Work.push_back(OpI);
    }
  }
  // (c) everything moved returns normally, so what it is moved above still runs
  // whenever it ran. (`I` itself is not asked `carriableEffects`: a lifted body
  // holds no volatile or atomic access, `scanBody`'s rejects. RETIREMENT TRIGGER:
  // the day it admits one (R16), ask `I` `isObservableOrderedEvent` / `callCrossable`
  // too.)
  for (Instruction *M : Move)
    if (!isGuaranteedToTransferExecutionToSuccessor(M))
      return nullptr;
  // (d) everything crossed returns normally and is no OBSERVABLE ordered event, nor a
  // call that may perform one (`isObservableOrderedEvent`, `callCrossable` above;
  // owner ruling 2026-10-08 as clarified in review round 5), and (e) none of it
  // conflicts in memory with a moved instruction that crosses it.
  for (Instruction *J = At; J != &I; J = J->getNextNode()) {
    if (Move.count(J))
      continue;
    if (isFrontEndSite(*J, taint))
      continue;
    if (!isGuaranteedToTransferExecutionToSuccessor(J) ||
        isObservableOrderedEvent(*J))
      return nullptr;
    if (const auto *CB = dyn_cast<CallBase>(J); CB && !callCrossable(*CB, Memo))
      return nullptr;
    const auto [JReads, JWrites] = memoryEffectsOf(*J);
    for (Instruction *M : Move) {
      if (!J->comesBefore(M))
        continue;
      const auto [Reads, Writes] = memoryEffectsOf(*M);
      if ((Writes && (JReads || JWrites)) || (Reads && JWrites))
        return nullptr;
    }
  }
  for (Instruction *J = At; J != &I; J = J->getNextNode())
    if (Move.count(J))
      Carried.push_back(J);
  return At;
}

}  // namespace cq
