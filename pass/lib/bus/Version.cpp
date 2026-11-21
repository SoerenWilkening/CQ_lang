// Rule 5 "memory version change": per original instruction, and the static writes-memory property (the least fixpoint
// over calls by name).
#include "BusInternal.h"

#include "cq/Calls.h"
#include "cq/Common.h"
#include "cq/Effects.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq::bus {

namespace {

const Function *calleeOf(const CallBase &CB) {
  return CB.isInlineAsm() ? nullptr : dyn_cast<Function>(CB.getCalledOperand()->stripPointerCasts());
}

bool isSurface(const Function &G) {
  StringRef n = G.getName();
  return G.isDeclaration() && (n.starts_with("cq_theta_") || n.starts_with("cq_measure_") || n == "cq_phi" ||
                               n.starts_with("__cq_invert_"));
}

// Rule 26, §1.4: a call by name of a variadic function or of one with a byval formal makes bus stores (the block, the
// copy) whatever the callee does.
bool plainForm(const Function &G) {
  return !hostCallee(G) && (G.isVarArg() || any_of(G.args(), [](const Argument &A) { return A.hasByValAttr(); }));
}

// Rule 5: a format entry is no change. Rule 16 makes printf one always.
bool formatEntry(const Function &G) {
  LibFunc lf;
  return libFuncOf(G, lf) && lf == LibFunc_printf;
}

// Rule 16: an allocation is a change; `free` is nothing.
bool allocates(const Function &G) {
  AllocFnKind k = hostAllocKind(G);
  return k != AllocFnKind::Unknown && (k & AllocFnKind::Free) == AllocFnKind::Unknown;
}
bool frees(const Function &G) {
  return (hostAllocKind(G) & AllocFnKind::Free) != AllocFnKind::Unknown;
}

// Rulings Q14: a host call is no change iff LLVM says it does not write memory.
bool hostCallWrites(const CallBase &CB) { return !CB.onlyReadsMemory(); }

// Rule 16: a noreturn host call is an abort event or the end of the program, no memory version change and no reason for rule 18's
// "no twin" (its list names memory writes, tainted measurements and effect results, never an abort). longjmp comes back at its
// setjmp and a thread's exit leaves the others running: those stay what LLVM says of them.
bool endsProgram(const CallBase &CB, const Function &G) {
  if (!CB.doesNotReturn() && !G.doesNotReturn())
    return false;
  StringRef n = G.getName();
  return n != "longjmp" && n != "_longjmp" && n != "siglongjmp" && n != "__longjmp_chk" && n != "pthread_exit" && n != "thrd_exit";
}

bool intrinsicWrites(const IntrinsicInst &II) {
  switch (II.getIntrinsicID()) {
  case Intrinsic::memcpy:
  case Intrinsic::memmove:
  case Intrinsic::memset:
  case Intrinsic::memcpy_inline:
  case Intrinsic::memset_inline:
  case Intrinsic::vastart:
  case Intrinsic::vacopy:
    return true;
  default:
    return false;
  }
}

// The body of F contains a change, calls by name aside (they go to `callees`).
bool bodyWrites(const TaintInfo &T, const Function &F, SmallVectorImpl<const Function *> &callees) {
  bool w = false;
  for (const Instruction &I : instructions(F)) {
    if (isa<StoreInst>(I) || isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I)) {
      w |= !T.deadVolatileStore(I);
    } else if (auto *A = dyn_cast<AllocaInst>(&I)) {
      // A bus-resident alloca is an allocation (rule 16): the object is host-resident in every clone or it is not.
      for (const Specialization &S : T.specializations())
        if (S.F == &F && !T.hostResident(A, S))
          w = true;
    } else if (auto *CB = dyn_cast<CallBase>(&I)) {
      if (isa<DbgInfoIntrinsic>(CB))
        continue;
      if (auto *II = dyn_cast<IntrinsicInst>(CB)) {
        w |= intrinsicWrites(*II);
        continue;
      }
      if (invert::isMarkerFence(*CB))
        continue;   // rule 17: consumed beside its marker (cq-h0cmk)
      const Function *G = calleeOf(*CB);
      if (!G) {
        w |= !CB->isInlineAsm() || hostCallWrites(*CB);   // a table clone's call (rule 19), or an asm
        continue;
      }
      if (isSurface(*G) || frees(*G))
        continue;
      if (allocates(*G)) {
        w = true;
        continue;
      }
      if (plainForm(*G))
        w = true;
      if (hostCallee(*G)) {   // cq-pt57w: a stream call by name is rule 16's, its body never lifted
        if (formatEntry(*G))
          continue;
        bool declared = false;   // rule 27: a declared clone's call in some specialization (an all-classical one is a host call)
        for (const Specialization &S : T.specializations())
          declared = declared || (S.F == &F && T.declaredCall(*CB, S));
        if (endsProgram(*CB, *G) && !declared)
          continue;
        w |= hostCallWrites(*CB) || declared;
        for (const Specialization &S : T.specializations())
          if (S.F == &F && T.isEffectEntry(*CB, S))
            w = true;
      } else {
        callees.push_back(G);
      }
    }
  }
  return w;
}

struct WriteSet {
  const TaintInfo *T = nullptr;
  const void *impl = nullptr;
  DenseSet<const Function *> writes;
};

} // namespace

bool writesMemory(const TaintInfo &T, const Function &F) {
  // One computation per module per taint: the specializations' array identifies the taint run.
  static thread_local WriteSet cache;
  const void *id = T.specializations().data();
  if (cache.impl != id) {
    cache.impl = id;
    cache.writes.clear();
    DenseMap<const Function *, SmallVector<const Function *, 2>> callers;
    SmallVector<const Function *, 16> work;
    for (const Function &G : *F.getParent()) {
      if (G.isDeclaration())
        continue;
      SmallVector<const Function *, 4> callees;
      if (bodyWrites(T, G, callees) && cache.writes.insert(&G).second)
        work.push_back(&G);
      for (const Function *c : callees)
        callers[c].push_back(&G);
    }
    while (!work.empty())
      for (const Function *c : callers.lookup(work.pop_back_val()))
        if (cache.writes.insert(c).second)
          work.push_back(c);
  }
  return cache.writes.count(&F) != 0;
}

bool isSurfaceCall(const CallBase &CB) {
  const Function *G = calleeOf(CB);
  return G && isSurface(*G);
}

bool notesOwnChange(const LoweringContext &ctx, const Instruction &I) {
  if (auto *A = dyn_cast<AllocaInst>(&I))
    return !ctx.T.hostResident(A, ctx.S);
  auto *CB = dyn_cast<CallBase>(&I);
  if (!CB || isa<DbgInfoIntrinsic>(CB))
    return false;
  if (const Function *G = calleeOf(*CB); G && allocates(*G))
    return true;
  if (!isa<MemIntrinsic>(CB))
    return false;
  // Rule 22: a host-resident destination keeps the intrinsic, a plain change; a copy's change is its first store.
  return calls::classify(*CB, ctx.T, ctx.S) == calls::Class::MemIntrinsic;
}

bool versionChange(const LoweringContext &ctx, const Instruction &I) { return versionChange(ctx.T, ctx.S, I); }

bool versionChange(const TaintInfo &T, const Specialization &S, const Instruction &I) {
  if (isa<StoreInst>(I) || isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I))
    return !T.deadVolatileStore(I);
  if (auto *A = dyn_cast<AllocaInst>(&I))
    return !T.hostResident(A, S);
  auto *CB = dyn_cast<CallBase>(&I);
  if (!CB || isa<DbgInfoIntrinsic>(CB))
    return false;
  if (auto *II = dyn_cast<IntrinsicInst>(CB))
    return intrinsicWrites(*II);
  // Rule 17 (cq-h0cmk): CQ.h's asm fence beside a cq_invert marker is consumed (Dispatch emits nothing for it), so it is
  // no memory version change; a region is lowered exactly as anywhere else.
  if (invert::isMarkerFence(*CB))
    return false;
  const Function *G = calleeOf(*CB);
  if (!G)
    return !CB->isInlineAsm() || hostCallWrites(*CB);
  if (isSurface(*G) || frees(*G))
    return false;
  if (allocates(*G))
    return true;
  if (plainForm(*G))
    return true;
  if (hostCallee(*G)) {
    // An effect entry notes its change at the tape_effect call itself (Tape.cpp): the readers of its fields and of what
    // precedes are un-copied before it (99). A format entry is none.
    if (T.isEffectEntry(*CB, S) || formatEntry(*G))
      return false;
    if (endsProgram(*CB, *G) && !T.declaredCall(*CB, S))
      return false;
    return hostCallWrites(*CB) || T.declaredCall(*CB, S);
  }
  return writesMemory(T, *G);
}

} // namespace cq::bus
