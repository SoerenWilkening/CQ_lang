// RailWindowFence.cpp — bd `test_C_libtooling-01po.19` S4: the exact barrier
// walk the window model reasons with, and THE STALE-CELL FENCE (contract in
// RailWindow.h).
//
// WHY A FENCE OF ITS OWN. A handle array keeps one physical rail per cell, and
// between windows that rail is spelled by a different SSA value in every window
// (a fresh load) or by the value a rebind stored. Every stale-reader fence in
// the tree keys on SSA identity, so each is BLIND to a gate through another
// spelling: `bool a = q[0]; <walk rotating q[i]>; cq_measure(a)` measured the
// ROTATED rail where C says `a` holds the value from before the walk (measured
// on the first S4 build: `cqrt_measure_i1(h0)` after `cqrt_ry_i1(h0, .5)`,
// exit 0, verify-clean). Its scalar twin declines (`rail record read past an
// in-place gate on the same rail`), so this is that refusal across the memory
// hop, and it is loud for the same reason: until the copy-on-read lowering
// exists (a stale name read as a reversible copy taken at the load), the pass
// must not guess (bd 01po.19.2).
//
// ⚠ WHAT THE FENCE RELIES ON (S4 review round 1). Its GATE set is the in-place
// `cq_theta` calls whose wire peels (casts, phis, theta chains) to a family
// member, and its USE set is the DIRECT users of a member. Both are complete
// only because (1) `declineClassicalMuxes` refuses a classical-condition
// select/phi over two different rails (so no mux of handles carries a cell
// rail to a gate or a use the peel cannot see), and (2) every cast of a
// tainted value is a template COPY (a new rail, read at its own position), not
// an alias. If either is relaxed — a handle mux admitted, or a cast lowered as
// an identity on the handle — this fence must widen with it.

#include "RailWindow.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/ValueTracking.h"  // getUnderlyingObject
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

bool railWindowReachesAvoiding(
    const Instruction *From, const Instruction *To,
    const SmallPtrSetImpl<const Instruction *> &Barriers) {
  const BasicBlock *FB = From->getParent();
  for (auto I = std::next(From->getIterator()); I != FB->end(); ++I) {
    if (&*I == To)
      return true;
    if (Barriers.count(&*I))
      return false;
  }
  SmallVector<const BasicBlock *, 16> Work(succ_begin(FB), succ_end(FB));
  SmallPtrSet<const BasicBlock *, 32> Seen;
  while (!Work.empty()) {
    const BasicBlock *B = Work.pop_back_val();
    if (!Seen.insert(B).second)
      continue;
    bool Cut = false;
    for (const Instruction &I : *B) {
      if (&I == To)
        return true;
      if (Barriers.count(&I)) {
        Cut = true;
        break;
      }
    }
    if (!Cut)
      Work.append(succ_begin(B), succ_end(B));
  }
  return false;
}

namespace {

bool isTheta(const Value *V) {
  const auto *CI = dyn_cast<CallInst>(V);
  const Function *F = CI ? CI->getCalledFunction() : nullptr;
  return F && F->getName().starts_with("cq_theta_") && CI->arg_size() >= 1;
}

// The family members `V` is an in-place spelling of: back through storage
// casts, phis and in-place `cq_theta` gates (the value-domain spelling of "the
// same rail") to the members it reaches.
void rootsOf(Value *V, const SmallPtrSetImpl<Value *> &Members,
             SmallPtrSetImpl<Value *> &Out,
             const DenseMap<Value *, Value *> &Targets = DenseMap<Value *, Value *>()) {
  SmallVector<Value *, 8> W{V};
  SmallPtrSet<Value *, 16> Seen;
  while (!W.empty()) {
    Value *X = W.pop_back_val();
    if (!Seen.insert(X).second)
      continue;
    if (Members.count(X)) {
      Out.insert(X);
      continue;
    }
    if (auto *C = dyn_cast<CastInst>(X))
      W.push_back(C->getOperand(0));
    else if (auto *P = dyn_cast<PHINode>(X))
      W.append(P->value_op_begin(), P->value_op_end());
    else if (isTheta(X))
      W.push_back(cast<CallInst>(X)->getArgOperand(0));
    else if (Value *T = Targets.lookup(X))
      W.push_back(T);  // S5: an in-place update is its target's rail.
  }
}

// S5 — the in-place cell updates (`railWindowInPlaceUpdate`) and the operand
// each overwrites, asked of THE lowering's own predicate (review S5 B-F3: one
// spelling of "target"): the operand rooted at a cell read `M` for which
// `railWindowWritesBack(update, M)` holds. Two candidates: neither (the
// quantum-source round refuses both-dead loudly).
void collectUpdates(Function &F, const SmallPtrSetImpl<Value *> &Members,
                    DenseMap<Value *, Value *> &Targets) {
  // To a fixpoint: a chained update `x2 = x1 ^ b` roots at the cell read only
  // through `x1`'s own entry.
  for (bool Grew = true; Grew;) {
    Grew = false;
    for (Instruction &I : instructions(F)) {
      Value *X, *Y;
      bool Sub;
      if (Targets.count(&I) || !railWindowInPlaceUpdate(&I, X, Y, Sub))
        continue;
      Value *Target = nullptr;
      bool Two = false;
      for (Value *O : {X, Y}) {
        if (Sub && O == Y)
          break;
        SmallPtrSet<Value *, 4> R;
        rootsOf(O, Members, R, Targets);
        for (Value *M : R)
          if (isa<LoadInst>(M) &&
              railWindowWritesBack(&I, cast<LoadInst>(M)->getPointerOperand())) {
            Two |= Target && Target != O;
            Target = O;
          }
      }
      if (Target && !Two) {
        Targets[&I] = Target;
        Grew = true;
      }
    }
  }
}

// The program points that read `X` through user `U` (a phi reads at the end of
// each incoming block that carries `X`).
void usePoints(Value *X, Instruction *U, SmallVectorImpl<Instruction *> &Out) {
  if (auto *P = dyn_cast<PHINode>(U)) {
    for (unsigned i = 0, e = P->getNumIncomingValues(); i != e; ++i)
      if (P->getIncomingValue(i) == X)
        Out.push_back(P->getIncomingBlock(i)->getTerminator());
    return;
  }
  Out.push_back(U);
}

}  // namespace

Instruction *railWindowStaleUse(Function &F, const RailWindowAccesses &AccW,
                                const SmallPtrSetImpl<Value *> &Quantum,
                                ScalarEvolution &SE,
                                const DenseMap<BasicBlock *, BasicBlock *> &R) {
  // The family: every cell read, and every rail stored into a cell. A member's
  // DEFINITION POINT is where it becomes the cell's rail: the load itself, or
  // the store that parks it. Its address is the cell it names.
  SmallPtrSet<Value *, 16> Members;
  DenseMap<Value *, Instruction *> Def;
  DenseMap<Value *, const SCEV *> Addr;
  for (LoadInst *L : AccW.Loads) {
    Members.insert(L);
    Def[L] = L;
    Addr[L] = SE.getSCEV(L->getPointerOperand());
  }
  for (StoreInst *S : AccW.Stores) {
    Value *V = S->getValueOperand();
    if (!Quantum.count(V) || Members.count(V))
      continue;
    Members.insert(V);
    Def[V] = S;
    Addr[V] = SE.getSCEV(S->getPointerOperand());
  }
  // The gates on the array: every in-place `cq_theta` whose wire is a member,
  // and (S5) every in-place cell update, a gate on its target's rail.
  DenseMap<Value *, Value *> Targets;
  collectUpdates(F, Members, Targets);
  SmallVector<std::pair<Instruction *, SmallPtrSet<Value *, 4>>, 8> Gates;
  for (Instruction &I : instructions(F)) {
    Value *Wire = isTheta(&I) ? cast<CallInst>(&I)->getArgOperand(0)
                              : Targets.lookup(&I);
    if (!Wire)
      continue;
    SmallPtrSet<Value *, 4> Roots;
    rootsOf(Wire, Members, Roots, Targets);
    if (!Roots.empty())
      Gates.push_back({&I, Roots});
  }
  for (Value *X : Members) {
    Instruction *D = Def[X];
    // A path that re-executes X's own SSA definition reads a NEW instance of
    // X (a stored member's definition precedes its parking store).
    SmallPtrSet<const Instruction *, 2> Again{D};
    if (auto *XI = dyn_cast<Instruction>(X))
      Again.insert(XI);
    for (auto &[G, Roots] : Gates) {
      if (G == X)
        continue;  // an update's own result is born by the gate, not moved.
      // A gate through X's OWN spelling is SSA-visible (the scalar fences own
      // it); only a gate through ANOTHER spelling is the memory hop.
      bool Other = false;
      for (Value *Y : Roots) {
        if (Y == X)
          continue;
        // Inside one window the promoted classes are provably distinct cells
        // (S3's alias proof): a gate there on another class is another rail.
        if (R.lookup(G->getParent()) == R.lookup(D->getParent()) &&
            railWindowDistinct(SE, Addr[X], Addr[Y]))
          continue;
        Other = true;
      }
      if (!Other || !railWindowReachesAvoiding(D, G, Again))
        continue;
      for (User *U : X->users()) {
        auto *UI = dyn_cast<Instruction>(U);
        if (!UI || UI == D)
          continue;
        SmallVector<Instruction *, 2> Pts;
        usePoints(X, UI, Pts);
        for (Instruction *P : Pts)
          if (P == G || railWindowReachesAvoiding(G, P, Again))
            return UI;
      }
    }
    // A PARKED rail moved through its OWN name: `q[i] = x; cq_theta(&x, θ)`
    // rotates the cell's rail too, where C leaves the cell holding the old
    // `x`. Stale iff a cell read can follow the gate before any store that
    // parks the moved rail again (that store makes the cell what C says).
    if (!isa<StoreInst>(D))
      continue;
    SmallPtrSet<const Instruction *, 4> Repark{D};
    if (auto *XI = dyn_cast<Instruction>(X))
      Repark.insert(XI);
    for (StoreInst *S : AccW.Stores) {
      SmallPtrSet<Value *, 4> Roots;
      rootsOf(S->getValueOperand(), Members, Roots, Targets);
      if (S != D && Roots.count(X))
        Repark.insert(S);
    }
    for (auto &[G, Roots] : Gates) {
      if (!Roots.count(X) || !railWindowReachesAvoiding(D, G, Again))
        continue;
      for (LoadInst *L : AccW.Loads)
        if (railWindowReachesAvoiding(G, L, Repark))
          return G;
    }
  }
  return nullptr;
}

// bd 01po.19 S4 review C-F1 (ruling `ruling-01po19-s4-r1-qs-2026-10-15` Q2):
// a cell rail stored into memory OTHER than its own handle array (`r[i] =
// q[i]`, `r[i] = q[(i+1)&3]`) would park the SAME rail in a second object,
// where C has two independent copies; the second array's own lowering then met
// a handle it cannot type (the internal `kMsgBankRewrite`, or "array mixes a
// rail cell access with an unrecognized one"). It is refused here, at the
// window slot, before any bank stage runs, until the copy-on-read lowering
// (bd 01po.19.2) exists. Returns the first such store, or null.
StoreInst *railWindowCellCopy(Function &F, const RailWindowAccesses &AccW) {
  SmallPtrSet<Value *, 16> Members(AccW.Loads.begin(), AccW.Loads.end());
  for (Instruction &I : instructions(F)) {
    auto *S = dyn_cast<StoreInst>(&I);
    if (!S || getUnderlyingObject(S->getPointerOperand()) == AccW.AI)
      continue;
    SmallPtrSet<Value *, 4> Roots;
    rootsOf(S->getValueOperand(), Members, Roots);
    if (!Roots.empty())
      return S;
  }
  return nullptr;
}

}  // namespace cq
