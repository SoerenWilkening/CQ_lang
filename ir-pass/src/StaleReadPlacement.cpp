// StaleReadPlacement.cpp — see StaleReadPlacement.h (owner ruling bd 57ch (A);
// first customer bd test_C_libtooling-r2j3.6; the batch-053 slices 57ch.1/.3/.4/.6/.7
// in StaleReadRegion.cpp and here).

#include "StaleReadPlacement.h"

#include "CalleeBody.h"         // calleeBodyTrusted (review round 4 R4-1)
#include "DeadValueLiveness.h"  // isFrontEndIntrinsicSite
#include "StaleReadRegion.h"    // the slot, the span, callProvablyReturns (bd 57ch.1/.4)
#include "TaintPropagation.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/CaptureTracking.h"  // PointerMayBeCaptured (review round 5)
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"  // getUnderlyingObject
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Support/ModRef.h"

#include <utility>

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
std::pair<bool, bool> declaredEffectsOf(const Instruction &X) {
  if (const auto *CB = dyn_cast<CallBase>(&X))
    if (const Function *Callee = CB->getCalledFunction();
        Callee && !Callee->isDeclaration()) {
      const ModRefInfo MR = Callee->getMemoryEffects().getModRef();
      return {isRefSet(MR), isModSet(MR)};
    }
  return {X.mayReadFromMemory(), X.mayWriteToMemory()};
}

// The same, for an instruction of the read's own function that the placement
// MOVES or CROSSES: a front-end site there (`cq_theta` / `cq_measure` / `cq_phi`,
// by membership) touches no memory — it is a gate or a measurement, whatever its
// declaration's attributes say (bd 57ch.6 carries a `cq_theta`, bd 57ch.3 a pure
// op past one). A body walk keeps `declaredEffectsOf` (an unchanged answer there).
std::pair<bool, bool> memoryEffectsOf(const Instruction &X, const TaintSet &taint) {
  if (isFrontEndSite(X, taint))
    return {false, false};
  return declaredEffectsOf(X);
}

// Clause (c): does a MOVED `X` return normally? A front-end site always does; a
// call when `callProvablyReturns` proves it (bd 57ch.4: LLVM's `willreturn`, or an
// acyclic trusted body); anything else by LLVM's own test.
bool returnsNormally(const Instruction &X, const TaintSet &taint, ReturnMemo &RM) {
  if (isFrontEndSite(X, taint))
    return true;
  if (const auto *CB = dyn_cast<CallBase>(&X))
    return callProvablyReturns(*CB, RM);
  return isGuaranteedToTransferExecutionToSuccessor(&X);
}

// Clause (d): may the placement move the read above a CROSSED `X`, as far as
// termination goes? The same test, except that a call is asked
// `callTerminationCrossable` (OWNER RULING 2026-10-13, bd 57ch.4: a `nounwind`
// call in a module with no `returns_twice` call may be crossed even when it may
// not return). A non-call that may not return (a volatile store) is refused.
bool crossableForTermination(const Instruction &X, const TaintSet &taint,
                             ReturnMemo &RM) {
  if (const auto *CB = dyn_cast<CallBase>(&X); CB && !isFrontEndSite(X, taint))
    return callTerminationCrossable(*CB, RM);
  return returnsNormally(X, taint, RM);
}

// ── LOCAL OBJECTS (review round 5; bd 57ch.7, owner ruling 2026-10-13). `Ptr`
// points into an object nothing outside the program's own frame can observe:
//   * a function-local alloca whose address is never captured; or
//   * a parameter of the function being walked whose bit is set in `LocalArgs`:
//     its caller passed a pointer to such a local, and this callee does not
//     capture the parameter (`localPointerArgs` below).
bool isLocalObject(const Value *Ptr, uint64_t LocalArgs) {
  const Value *Obj = getUnderlyingObject(Ptr);
  if (const auto *AI = dyn_cast<AllocaInst>(Obj))
    return !PointerMayBeCaptured(AI, /*ReturnCaptures=*/true,
                                 /*StoreCaptures=*/true);
  if (const auto *A = dyn_cast<Argument>(Obj))
    return A->getArgNo() < 64 && ((LocalArgs >> A->getArgNo()) & 1);
  return false;
}

// The callee parameters of call `CB` that point at a local object of the caller
// (`isLocalObject` with the caller's own mask) and that the callee's body does not
// capture (`PointerMayBeCaptured` asked of the callee's argument — the body's own
// answer, never a call-site attribute; review round 1 F4).
uint64_t localPointerArgs(const CallBase &CB, const Function &Callee,
                          uint64_t CallerLocalArgs) {
  uint64_t Mask = 0;
  const unsigned E = std::min<unsigned>(
      {static_cast<unsigned>(CB.arg_size()),
       static_cast<unsigned>(Callee.arg_size()), 64u});
  for (unsigned A = 0; A != E; ++A) {
    const Value *Op = CB.getArgOperand(A);
    if (!Op->getType()->isPointerTy() ||
        PointerMayBeCaptured(Callee.getArg(A), /*ReturnCaptures=*/true,
                             /*StoreCaptures=*/true))
      continue;
    if (isLocalObject(Op, CallerLocalArgs))
      Mask |= uint64_t(1) << A;
  }
  return Mask;
}

// ── THE ORDERED EVENTS (OWNER RULING 2026-10-08, clarified in review round 5; bd
// memory owner-ruling-gates-ordered-vs-volatile-atomic-2026-10-08; extended to a
// caller's local by OWNER RULING 2026-10-13, bd 57ch.7): gate emission is ordered
// against OBSERVABLE volatile, atomic and fence events, so no code motion of this
// placement (the moved read, a carried operand) may cross one in either
// direction. ONE predicate, asked of a crossed instruction, of every instruction of
// a crossed call's body, and of a carried operand (review round 5 R5-1, R12):
//   * any volatile access, and any fence;
//   * any atomic access (load, store, rmw, cmpxchg; ANY ordering) unless its object
//     is a LOCAL OBJECT (`isLocalObject`): a never-captured function-local alloca,
//     or a non-captured parameter pointing at a caller's such local. Neither is
//     observable, by the reasoning R16 applies to an unreachable volatile.
bool isObservableOrderedEvent(const Instruction &X, uint64_t LocalArgs) {
  if (X.isVolatile() || isa<FenceInst>(X))
    return true;
  if (!X.isAtomic())
    return false;
  const Value *Ptr = getLoadStorePointerOperand(&X);
  if (const auto *RMW = dyn_cast<AtomicRMWInst>(&X))
    Ptr = RMW->getPointerOperand();
  else if (const auto *CX = dyn_cast<AtomicCmpXchgInst>(&X))
    Ptr = CX->getPointerOperand();
  return !Ptr || !isLocalObject(Ptr, LocalArgs);
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
//     (`calleeBodyTrusted`, AssumeOfLinkedCall) holding, transitively (memoized per
//     body AND local-argument mask; a cycle refuses), no observable ordered event
//     and no call that is not itself crossable (`nosync` is not asked of a body: it
//     admits a monotonic atomic). The body is asked with THIS call's mask
//     (`localPointerArgs`, bd 57ch.7);
//   * anything else (an opaque declaration that may touch memory, an indirect call,
//     inline asm): refused.
// Clause (e)'s memory conflict with the moved set still applies on top.
using CrossMemo = DenseMap<std::pair<const Function *, uint64_t>, bool>;

bool callCrossable(const CallBase &CB, CrossMemo &Memo, uint64_t CallerLocalArgs);

bool bodyHoldsNoOrderedEvent(const Function &F, uint64_t LocalArgs,
                             CrossMemo &Memo) {
  const auto Key = std::make_pair(&F, LocalArgs);
  if (auto It = Memo.find(Key); It != Memo.end())
    return It->second;  // done, or in progress (false: a cycle refuses)
  Memo[Key] = false;
  for (const Instruction &X : instructions(F)) {
    if (isObservableOrderedEvent(X, LocalArgs))
      return false;
    if (const auto *CB = dyn_cast<CallBase>(&X);
        CB && !callCrossable(*CB, Memo, LocalArgs))
      return false;
  }
  Memo[Key] = true;
  return true;
}

bool callCrossable(const CallBase &CB, CrossMemo &Memo, uint64_t CallerLocalArgs) {
  if (CB.isInlineAsm())
    return false;
  if (const auto [Reads, Writes] = declaredEffectsOf(CB); !Reads && !Writes)
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
  return bodyHoldsNoOrderedEvent(
      *Callee, localPointerArgs(CB, *Callee, CallerLocalArgs), Memo);
}

// A CARRIED classical operand (review round 2 R2-1, round 5 R5-1): no observable
// ordered event, and a call only if crossable by the same test as above (which also
// refuses inline asm). Its memory conflicts with what it crosses are clause (e)'s.
bool carriableEffects(const Instruction &X, CrossMemo &Memo) {
  if (isObservableOrderedEvent(X, /*LocalArgs=*/0))
    return false;
  const auto *CB = dyn_cast<CallBase>(&X);
  return !CB || callCrossable(*CB, Memo, /*CallerLocalArgs=*/0);
}

// (b) A TAINTED instruction the placement may carry (bd 57ch.3): a pure read of
// its operands — it mints a fresh rail (or, a `gep`, computes an address), so moving
// it earlier with its consumer moves a read, never a gate. A simple load is a QRAM
// read; its memory order is clause (e)'s.
bool carriableTaintedRead(const Instruction &X) {
  if (isa<BinaryOperator>(X) || isa<UnaryOperator>(X) || isa<CastInst>(X) ||
      isa<CmpInst>(X) || isa<GetElementPtrInst>(X) || isa<FreezeInst>(X))
    return true;
  if (const auto *LI = dyn_cast<LoadInst>(&X))
    return LI->isSimple();
  if (const auto *CI = dyn_cast<CallInst>(&X)) {
    const Function *F = CI->getCalledFunction();
    return F && F->getIntrinsicID() != Intrinsic::not_intrinsic &&
           CI->doesNotAccessMemory() &&
           isGuaranteedToTransferExecutionToSuccessor(CI);
  }
  return false;
}

// (b) May operand `X` (defined after the slot, in the span) be carried?
bool carriable(const Instruction &X, const TaintSet &taint,
               const SmallPtrSetImpl<const CallInst *> &Stalers, CrossMemo &Memo) {
  if (isa<PHINode>(X) || X.isEHPad() || isMustTail(X))
    return false;
  if (isFrontEndSite(X, taint)) {  // bd 57ch.6: an independent register's gate
    const auto *CI = cast<CallInst>(&X);
    return taint.ThetaCalls.contains(CI) && !Stalers.count(CI);
  }
  if (taint.Tainted.count(const_cast<Instruction *>(&X)))
    return carriableTaintedRead(X);
  return !readsTaintedValue(X, taint) && carriableEffects(X, Memo);
}

}  // namespace

Instruction *staleReadInsertPoint(Instruction &I, ArrayRef<CallInst *> Stalers,
                                  const TaintSet &taint, const DominatorTree &DT,
                                  const PostDominatorTree &PDT,
                                  SmallVectorImpl<Instruction *> &Carried) {
  Carried.clear();
  if (Stalers.empty() || isa<PHINode>(I) || I.isTerminator() || I.isEHPad() ||
      isMustTail(I))
    return nullptr;  // a `musttail` call must stay immediately before its `ret`.
  // (a) the slot and the span (StaleReadRegion.h).
  PlacementSpan S;
  if (!stalePlacementSpan(I, Stalers, DT, PDT, S))
    return nullptr;
  Instruction *At = S.At;
  const SmallPtrSet<const CallInst *, 8> StalerSet(Stalers.begin(), Stalers.end());
  // (b) every operand available at the slot, or carried from the span.
  CrossMemo Memo;  // one memo for every crossing question of this placement
  ReturnMemo RM;
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
      if (!S.inSpan(OpI) || !carriable(*OpI, taint, StalerSet, Memo))
        return nullptr;
      Move.insert(OpI);
      Work.push_back(OpI);
    }
  }
  // (b, bd 57ch.6) a carried gate acts on a register minted in the span: its arg 0
  // is classical (the mint) or itself carried, and no reader of its input record
  // stays behind in the span (it would then read a record the moved gate consumed).
  for (Instruction *M : Move) {
    const auto *CI = dyn_cast<CallInst>(M);
    if (!CI || !taint.ThetaCalls.contains(CI))
      continue;
    Value *A0 = CI->getArgOperand(0);
    if (!taint.Tainted.count(A0))
      continue;
    auto *A0I = dyn_cast<Instruction>(A0);
    if (!A0I || !Move.count(A0I))
      return nullptr;  // a gate on a register that predates the slot
    for (User *U : A0->users())
      if (auto *UI = dyn_cast<Instruction>(U); UI && !Move.count(UI) && S.inSpan(UI))
        return nullptr;
  }
  // (b') NO MINTED RAIL OUTLIVES THE SLOT UNLESS ITS CONSUMERS MOVE (batch 053
  // composition probe, HIGH: a placed `sitofp` whose lifted-call consumer stayed
  // below the gate left `(double)q_pre` dirty and entangled across the Ry, its
  // `_unc` having no valid position — a silent dephasing the read-first twin does
  // not have). Asked as a SET (L3): every rail the placement mints (a moved tainted
  // value that is no front-end site and no address `gep`) has all its users in the
  // moved set, or is consumed by a MEASUREMENT (a terminal sink: the twin keeps it
  // across the gate too, and nothing reverses it). Otherwise refuse: the stale fence
  // declines loudly. RETIREMENT TRIGGER (L7): carrying the read's forward tainted
  // cone with it (each member re-checked by (b)-(e)) makes these shapes place.
  for (Instruction *M : Move) {
    if (!taint.Tainted.count(M) || isFrontEndSite(*M, taint) ||
        isa<GetElementPtrInst>(M))
      continue;
    for (User *U : M->users()) {
      auto *UI = dyn_cast<Instruction>(U);
      if (UI && Move.count(UI))
        continue;
      const auto *UC = dyn_cast_or_null<CallInst>(UI);
      if (UC && taint.MeasureCalls.contains(const_cast<CallInst *>(UC)))
        continue;
      return nullptr;
    }
  }
  // (c) everything moved returns normally, so what it is moved above still runs
  // whenever it ran. `I` that is not a call is also no observable event itself (a
  // volatile QRAM access). (A lifted call `I` is not asked `isObservableOrderedEvent`
  // / `callCrossable`: its body holds no volatile or atomic access, `scanBody`'s
  // rejects. RETIREMENT TRIGGER: the day it admits one (R16), ask it too.)
  for (Instruction *M : Move)
    if (!returnsNormally(*M, taint, RM))
      return nullptr;
  if (!isa<CallBase>(I) && isObservableOrderedEvent(I, /*LocalArgs=*/0))
    return nullptr;
  // (d) everything crossed returns normally and is no OBSERVABLE ordered event, nor a
  // call that may perform one, and (e) none of it conflicts in memory with a moved
  // instruction that it may run before.
  SmallVector<Instruction *, 32> Crossed;
  S.crossed(Crossed);
  for (Instruction *J : Crossed) {
    if (Move.count(J) || isFrontEndSite(*J, taint))
      continue;
    if (!crossableForTermination(*J, taint, RM) ||
        isObservableOrderedEvent(*J, /*LocalArgs=*/0))
      return nullptr;
    if (const auto *CB = dyn_cast<CallBase>(J);
        CB && !callCrossable(*CB, Memo, /*CallerLocalArgs=*/0))
      return nullptr;
    const auto [JReads, JWrites] = memoryEffectsOf(*J, taint);
    if (!JReads && !JWrites)
      continue;
    for (Instruction *M : Move) {
      if (!S.mayRunBefore(J, M))
        continue;
      const auto [Reads, Writes] = memoryEffectsOf(*M, taint);
      if ((Writes && (JReads || JWrites)) || (Reads && JWrites))
        return nullptr;
    }
  }
  for (Instruction *J : Crossed)  // span order: every definition before its uses
    if (Move.count(J))
      Carried.push_back(J);
  return At;
}

}  // namespace cq
