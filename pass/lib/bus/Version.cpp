// Rule 5 "memory version change": per original instruction, and the static writes-memory property (the least fixpoint
// over calls by name).
#include "BusInternal.h"

#include "cq/Calls.h"
#include "cq/Common.h"
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
  return !G.isDeclaration() && (G.isVarArg() || any_of(G.args(), [](const Argument &A) { return A.hasByValAttr(); }));
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
      w = true;
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
      if (G->isDeclaration()) {
        if (formatEntry(*G))
          continue;
        w |= hostCallWrites(*CB) || T.listedRoot(*G);
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

bool versionChange(const LoweringContext &ctx, const Instruction &I) {
  if (isa<StoreInst>(I) || isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I))
    return true;
  if (auto *A = dyn_cast<AllocaInst>(&I))
    return !ctx.T.hostResident(A, ctx.S);
  auto *CB = dyn_cast<CallBase>(&I);
  if (!CB || isa<DbgInfoIntrinsic>(CB))
    return false;
  if (auto *II = dyn_cast<IntrinsicInst>(CB))
    return intrinsicWrites(*II);
  const Function *G = calleeOf(*CB);
  if (!G)
    return !CB->isInlineAsm() || hostCallWrites(*CB);
  if (isSurface(*G) || frees(*G))
    return false;
  if (allocates(*G))
    return true;
  if (plainForm(*G))
    return true;
  if (G->isDeclaration()) {
    // An effect entry notes its change at the tape_effect call itself (Tape.cpp): the readers of its fields and of what
    // precedes are un-copied before it (99). A format entry is none.
    if (ctx.T.isEffectEntry(*CB, ctx.S) || formatEntry(*G))
      return false;
    return hostCallWrites(*CB) || ctx.T.listedRoot(*G);
  }
  return writesMemory(ctx.T, *G);
}

} // namespace cq::bus
