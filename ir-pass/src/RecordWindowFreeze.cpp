// RecordWindowFreeze.cpp — see the header for the rule and its argument (bd
// test_C_libtooling-r2j3.3).

#include "RecordWindowFreeze.h"

#include "ChainWalk.h"     // railOf / isInPlaceGateOn / preservesBasisUnderRecord /
                           // recordsIntoKeptCarrier — the gate vocabulary (Rule 14)
#include "DagTraversal.h"  // DataDag
#include "WireWalk.h"      // provablyBefore — the ONE position-aware proof

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"

#include <utility>

using namespace llvm;

namespace cq {

void freezeRecordWindowReaders(DataDag &D, ArrayRef<AncestorEdge> Edges,
                               DominatorTree &DT) {
  // 1. WHEN IS EACH REGISTER'S LABEL RECORDED? A (register, time) pair means "the
  //    label this register held when `time` executed is now held by a kept
  //    carrier". Seeded at every kept-carrier record of a rail of this DAG — the
  //    same seed set as step 3b (`Rails` ∪ `railOf(Calls)`, `recordsIntoKeptCarrier`,
  //    one spelling) — and closed BACKWARD over the ancestor edges: a child read
  //    at time T carries its parent's label as of the gate E that read the parent,
  //    unless E provably runs only AFTER T (then the child the record saw did not
  //    yet hold E's contribution).
  SmallVector<std::pair<Value *, Instruction *>, 16> Work;
  DenseSet<std::pair<Value *, Instruction *>> Seen;
  DenseMap<Value *, SmallVector<Instruction *, 4>> RecordedAt;
  auto push = [&](Value *V, Instruction *T) {
    if (V && T && Seen.insert({V, T}).second) {
      Work.push_back({V, T});
      RecordedAt[V].push_back(T);
    }
  };
  auto seed = [&](Value *R) {
    if (!R)
      return;
    for (User *U : R->users())
      if (auto *S = dyn_cast<CallInst>(U))
        if (recordsIntoKeptCarrier(S, R))
          push(R, S);
  };
  for (Value *R : D.Rails)
    seed(R);
  for (CallInst *G : D.Calls)
    seed(railOf(G));
  if (Work.empty())
    return;  // nothing recorded — the common case, and byte-inert.
  while (!Work.empty()) {
    auto [C, T] = Work.pop_back_val();
    for (const AncestorEdge &E : Edges)
      if (E.Child == C && !provablyBefore(T, E.Gate, DT))
        push(E.Parent, E.Gate);
  }

  // 2. THE WINDOW TEST. For a recorded register P and each NON-basis-preserving
  //    gate N in place on P: if some record of P's label may be taken AFTER N,
  //    then N's adjoint does not restore P, and every gate G that READ P and may
  //    run BEFORE N has its `_unc` recompute from a wrong label — freeze G's rail.
  //    Every adjoint is still emitted (the bd 261j rule: the freeze suppresses
  //    only the free); a frozen rail is LEFT ALLOCATED (Rule 6).
  for (auto &[P, Times] : RecordedAt) {
    for (CallInst *N : D.Calls) {
      if (!isInPlaceGateOn(N, P) || preservesBasisUnderRecord(N))
        continue;
      bool RecordedAfterN = false;
      for (Instruction *T : Times)
        if (!provablyBefore(T, N, DT)) {
          RecordedAfterN = true;
          break;
        }
      if (!RecordedAfterN)
        continue;
      for (CallInst *G : D.Calls) {
        if (G == N || provablyBefore(N, G, DT))
          continue;  // G provably reads P only AFTER N: N's adjoint is not
                     // between G and G's `_unc`.
        Value *R = railOf(G);
        if (R == P)
          continue;  // G's own rail (an in-place gate on P) — step 3b's call.
        bool ReadsP = false;
        for (Value *Op : G->args())
          if (Op == P)
            ReadsP = true;
        if (ReadsP && R)
          D.FrozenRails.insert(R);
      }
    }
  }
}

}  // namespace cq
