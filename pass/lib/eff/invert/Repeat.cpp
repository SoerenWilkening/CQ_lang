// Module eff-invert (cq-oyirf; CR rule 17 "A value made in the region and read after its end", owner ruling 2026-11-16):
// a loop inside a cq_invert region whose value is read after the region's end through a computation runs again after the
// end. Contract at repeatAfterEnd in Split.h.
//
// CR rule 17: a rail made inside the region crosses the end only where a rule keeps it (a measured rail, a rotated
// register, a kept store's rail, a kept a_K). Every other one is uncomputed inside the region, and a reader after the end
// gets the value recomputed after the end from the values live before the begin. The spine recomputes a straight-line
// pure value so (cq-5n3n, Dispatch closeRegionRails). A loop is no pure instruction the spine can lower again at the end
// marker: its value is "recomputed" by running the loop again after the end, forward, its values read in place, then its
// reverse loop (as anywhere else, deferred after the readers). The repeat keeps no a_K: the in-region loop's is the kept
// rail (loops-cutoff reads the `cq.repeat` mark this step leaves on a repeated loop's header).
//
// CONSTRUCTION, on the original IR before the walk (the walker then lowers the in-region loop and the repeat as it lowers
// any loop). The region of a begin B and an end E of one function with no other marker between them, single entry and
// single exit (B dominates E, E post-dominates B, every block between is entered and left only within it). A use after E
// of a value V made in the region is RE-READ when V's pure cone in the region reaches a loop and V does not cross the end
// as a rail: V not lowered again by the spine (a loop's value or a phi) with a reader after the end that keeps or names
// the rail (a call: a measurement, a rotation, a clone's actual; a return; a stored value; a phi after the end). Such a
// V crosses as before, and every reader after the end reads it (cq-037u2: the loop's kept copy; owner 2026-11-16: a
// loop value measured right after the end is a measured rail). With at least one re-read, the region's blocks are
// copied once onto the edge that leaves E (E's block is split after E, B's after its CQ.h fence), every re-read use
// reads the copy's V, and in the copy only
// what the re-read values and the copy's branches depend on remains (the markers, CQ.h's fences and everything else
// go). That remainder must be pure (no call but a memory-free intrinsic, no memory access): a loop whose body holds a
// rotation, a measurement, a bus store or an effect is repeated only by the slice its read values and exit tests depend
// on (CR: "where those read nothing such an instruction produces"); such an instruction is never repeated. A remainder
// that reads one is left as it was (the kept copy, a §6 leak: the construction is owed, CR §8).
//
// A load in the remainder (owner ruling 2026-11-16, cq-oyirf follow-up, rule 17 with rule 5) is repeated when no memory
// version change lies between the region's begin and the repeat (the region: the repeat sits right after its end), for
// any specialization of the function: rule 5's own classification (bus::versionChange: a bus store, an in-place form's
// store on a cell, an allocation, a call that is one), and an effect entry, which notes its change at its tape_effect
// call. CQ.h's fences beside the markers are none (the walker consumes them, emitting nothing). Wherever one lies there, the load counts as reading what a store produced: the owed case above. A volatile load
// is an observable access, never repeated. The repeated load is lowered like any other (rule 5: its un-copy after its
// last reader, its rail freed when no version change overtook it).
//
// Taint: only where every specialization of the function holds each re-read value quantum (classical code is never
// rewritten). The scaffold re-taints the module when anything changed.
#include "Split.h"

#include "cq/Bus.h"
#include "cq/Effects.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Metadata.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"

using namespace llvm;

namespace cq::invert {

namespace {

bool callsNamed(const Instruction &I, StringRef name) {
  auto *C = dyn_cast<CallBase>(&I);
  const Function *F = C ? C->getCalledFunction() : nullptr;
  return F && F->getName() == name;
}

bool isMarkerCall(const Instruction &I) {
  return callsNamed(I, "__cq_invert_begin") || callsNamed(I, "__cq_invert_end");
}

// The spine's recomputable instructions (Dispatch.cpp recomputable): lowered again after an end from their operands.
bool spineRecomputes(const Instruction *I) {
  return isa<BinaryOperator>(I) || isa<CmpInst>(I) || isa<CastInst>(I) || isa<SelectInst>(I) || isa<FreezeInst>(I) ||
         isa<UnaryOperator>(I);
}

// An instruction a repeat may run again: no memory access, no side effect, no call but a memory-free intrinsic.
bool pureForRepeat(const Instruction &I) {
  if (I.isTerminator())
    return true;
  if (auto *II = dyn_cast<IntrinsicInst>(&I))
    return II->doesNotAccessMemory() && !II->mayHaveSideEffects() && !isa<DbgInfoIntrinsic>(II);
  if (isa<CallBase>(&I) || isa<AllocaInst>(&I) || I.isEHPad())
    return false;
  return !I.mayReadOrWriteMemory() && !I.mayHaveSideEffects();
}

struct RegionCut {
  CallInst *begin = nullptr, *end = nullptr;
  SmallVector<BasicBlock *, 16> blocks;   // function order; begin's block first in the set, end's block included
};

class Repeater {
public:
  Repeater(Function &F, const TaintInfo &T) : F(F), T(T), DT(F), PDT(F), LI(DT) {}

  // The begin/end pairs whose region is single-entry single-exit with no other marker inside.
  SmallVector<RegionCut, 2> regions() {
    SmallVector<CallInst *, 4> begins, ends;
    for (BasicBlock &b : F)
      for (Instruction &I : b)
        if (callsNamed(I, "__cq_invert_begin"))
          begins.push_back(cast<CallInst>(&I));
        else if (callsNamed(I, "__cq_invert_end"))
          ends.push_back(cast<CallInst>(&I));
    SmallVector<RegionCut, 2> out;
    for (CallInst *E : ends) {
      CallInst *B = nullptr;
      for (CallInst *b : begins)
        if (DT.dominates(b, E) && PDT.dominates(E->getParent(), b->getParent()) && (!B || DT.dominates(B, b)))
          B = b;
      if (!B || B->getParent() == E->getParent())
        continue;   // no control flow between them: no loop
      BasicBlock *Bb = B->getParent(), *Be = E->getParent();
      RegionCut r{B, E, {}};
      DenseSet<const BasicBlock *> in;
      for (BasicBlock &b : F)
        if (&b == Bb || &b == Be || (DT.dominates(Bb, &b) && PDT.dominates(Be, &b))) {
          r.blocks.push_back(&b);
          in.insert(&b);
        }
      bool sese = true, otherMarker = false;
      for (BasicBlock *b : r.blocks) {
        if (b != Bb)
          for (BasicBlock *p : predecessors(b))
            sese = sese && in.count(p);
        if (b != Be)
          for (BasicBlock *s : successors(b))
            sese = sese && in.count(s);
        for (Instruction &I : *b)
          if (isMarkerCall(I) && &I != B && &I != E && inRegion(r, in, &I))
            otherMarker = true;
      }
      // Be's own successors leave the region; a loop around Be (Be inside a loop of the region) is no single exit.
      if (!sese || otherMarker || LI.getLoopFor(Bb) != LI.getLoopFor(Be))
        continue;
      out.push_back(std::move(r));
    }
    return out;
  }

  bool inRegion(const RegionCut &r, const DenseSet<const BasicBlock *> &in, const Instruction *I) const {
    const BasicBlock *b = I->getParent();
    if (!in.count(b))
      return false;
    if (b == r.begin->getParent() && !r.begin->comesBefore(I))
      return false;
    if (b == r.end->getParent() && !I->comesBefore(r.end))
      return false;
    return true;
  }

  // A loop of the function whose blocks lie in the region (its outermost one there).
  // (A loop headed by the begin's or the end's block holds the whole region: it is no loop of the region.)
  Loop *regionLoop(const DenseSet<const BasicBlock *> &in, const BasicBlock *b) const {
    auto inside = [&](const Loop *L) {
      const BasicBlock *h = L->getHeader();
      return in.count(h) && h != cur->begin->getParent() && h != cur->end->getParent();
    };
    Loop *L = LI.getLoopFor(b);
    if (!L || !inside(L))
      return nullptr;
    while (L->getParentLoop() && inside(L->getParentLoop()))
      L = L->getParentLoop();
    return L;
  }

  bool run();

private:
  Function &F;
  const TaintInfo &T;
  DominatorTree DT;
  PostDominatorTree PDT;
  LoopInfo LI;

  const RegionCut *cur = nullptr;
  bool repeatRegion(RegionCut &r);
};

bool Repeater::run() {
  SmallVector<RegionCut, 2> rs = regions();
  // One region per call: the cut changes the CFG, and a second region is found again on the new one.
  for (RegionCut &r : rs)
    if (repeatRegion(r))
      return true;
  return false;
}

bool Repeater::repeatRegion(RegionCut &r) {
  cur = &r;
  DenseSet<const BasicBlock *> in(r.blocks.begin(), r.blocks.end());
  auto made = [&](const Value *v) {
    auto *I = dyn_cast<Instruction>(v);
    return I && inRegion(r, in, I);
  };
  // Does v's pure cone in the region reach a loop of the region?
  DenseMap<const Value *, bool> memo;
  std::function<bool(const Value *)> reachesLoop = [&](const Value *v) -> bool {
    if (!made(v))
      return false;
    if (auto it = memo.find(v); it != memo.end())
      return it->second;
    memo[v] = false;   // a cycle through a phi outside a loop cannot be: the cut is reducible, and a cycle is a loop
    auto *I = cast<Instruction>(v);
    bool res = false;
    if (regionLoop(in, I->getParent()))
      res = true;
    else if (auto *P = dyn_cast<PHINode>(I))
      res = any_of(P->incoming_values(), [&](const Value *x) { return reachesLoop(x); });
    else if (spineRecomputes(I))
      res = any_of(I->operands(), [&](const Value *x) { return reachesLoop(x); });
    memo[v] = res;
    return res;
  };
  auto quantumEverywhere = [&](const Value *v) {
    bool any = false;
    for (const Specialization &S : T.specializations())
      if (S.F == &F) {
        if (!T.isQuantum(v, S))
          return false;
        any = true;
      }
    return any;
  };
  // The re-read uses (user, operand index).
  SmallVector<std::pair<Instruction *, unsigned>, 4> reread;
  SetVector<Instruction *> seeds;
  for (BasicBlock *b : r.blocks)
    for (Instruction &I : *b) {
      if (!made(&I) || I.getType()->isVoidTy())
        continue;
      bool crossesAsRail = !spineRecomputes(&I) || regionLoop(in, I.getParent());
      auto after = [&](const Use &u) {
        auto *U = dyn_cast<Instruction>(u.getUser());
        return U && !made(U) && U->getFunction() == &F;
      };
      auto keeps = [&](const Use &u) {
        const User *U = u.getUser();
        return isa<CallBase>(U) || isa<ReturnInst>(U) || isa<PHINode>(U) || (isa<StoreInst>(U) && u.getOperandNo() == 0);
      };
      // A value that crosses the end as a rail (a reader after the end keeps it: the measured rail of 62ff999e) is read
      // there by every reader after the end, a computation too: no repeat.
      if (crossesAsRail && any_of(I.uses(), [&](const Use &u) { return after(u) && keeps(u); }))
        continue;
      for (Use &u : I.uses()) {
        if (!after(u) || !reachesLoop(&I) || !quantumEverywhere(&I))
          continue;
        reread.push_back({cast<Instruction>(u.getUser()), u.getOperandNo()});
        seeds.insert(&I);
      }
    }
  if (reread.empty())
    return false;
  // What the copy keeps: the re-read values and every branch of the region, with what they read in the region. The
  // remainder is pure (CR: the instructions the read values and exit tests depend on, "where those read nothing such an
  // instruction produces"); a loop it enters may hold a rotation, a measurement, a bus store, an effect or a call besides:
  // the copy drops them (never repeated). A re-read value whose remainder reads one of them (or a load where the
  // region holds a memory version change: what a store produced) is left as it was, and so is the region when a branch's does: the construction is owed (CR §8), the
  // kept copy stays a §6 leak. A region with a path that ends (an abort's unreachable) is left as well: the copy would keep
  // the dead end without the call that ends the path. A load is repeated only when the region holds no memory version
  // change (rule 5; owner ruling 2026-11-16, see the head of this file).
  bool versionChangeInRegion = false;
  for (BasicBlock *b : r.blocks)
    for (Instruction &I : *b) {
      // CQ.h's fence beside a marker is the marker's: the walker consumes it and emits nothing (Dispatch: no change noted).
      if (versionChangeInRegion || !made(&I) || isMarkerFence(I))
        continue;
      auto *CB = dyn_cast<CallBase>(&I);
      for (const Specialization &S : T.specializations())
        if (S.F == &F && (bus::versionChange(T, S, I) || (CB && T.isEffectEntry(*CB, S))))
          versionChangeInRegion = true;
    }
  auto repeatable = [&](const Instruction &I) {
    if (auto *L = dyn_cast<LoadInst>(&I))
      return !versionChangeInRegion && !L->isVolatile();
    return pureForRepeat(I);
  };
  SetVector<Instruction *> need;
  auto close = [&](ArrayRef<Instruction *> from, SetVector<Instruction *> &into) {
    SmallVector<Instruction *, 16> work(from.begin(), from.end());
    while (!work.empty()) {
      Instruction *I = work.pop_back_val();
      if (!made(I) && !I->isTerminator())
        continue;
      if (!into.insert(I))
        continue;
      if (!repeatable(*I) || isMarkerCall(*I))
        return false;
      for (Value *o : I->operands())
        if (auto *oi = dyn_cast<Instruction>(o); oi && made(oi))
          work.push_back(oi);
    }
    return true;
  };
  SmallVector<Instruction *, 16> terms;
  for (BasicBlock *b : r.blocks)
    if (b != r.end->getParent())
      terms.push_back(b->getTerminator());
  if (!close(terms, need))
    return false;
  for (Instruction *V : seeds) {
    SetVector<Instruction *> own = need;
    if (close({V}, own))
      need = std::move(own);
    else
      erase_if(reread, [&](const std::pair<Instruction *, unsigned> &u) { return u.first->getOperand(u.second) == V; });
  }
  if (reread.empty())
    return false;
  for (BasicBlock *b : r.blocks)
    if (isa<UnreachableInst>(b->getTerminator()))
      return false;

  // The cut. E's block ends at E; B's block's part after B is a block of its own.
  BasicBlock *Be = r.end->getParent();
  BasicBlock *After = Be->splitBasicBlock(std::next(r.end->getIterator()));
  BasicBlock *Bb = r.begin->getParent();
  // (CQ.h's fence right after the begin stays beside it: the walker consumes it there, isMarkerFence.)
  BasicBlock::iterator cut = std::next(r.begin->getIterator());
  if (!cut->isTerminator() && isMarkerFence(*cut))
    ++cut;
  BasicBlock *R0 = Bb->splitBasicBlock(cut);
  SmallVector<BasicBlock *, 16> blocks;
  for (BasicBlock *b : r.blocks)
    blocks.push_back(b == Bb ? R0 : b);
  SmallPtrSet<const BasicBlock *, 4> headers;
  for (BasicBlock *b : r.blocks)
    if (LI.isLoopHeader(b) && b != Bb && b != Be)
      headers.insert(b);
  ValueToValueMapTy VM;
  SmallVector<BasicBlock *, 16> copies;
  for (BasicBlock *b : blocks) {
    BasicBlock *c = CloneBasicBlock(b, VM, "", &F);
    c->moveBefore(After);
    VM[b] = c;
    copies.push_back(c);
  }
  remapInstructionsInBlocks(copies, VM);
  Be->getTerminator()->setSuccessor(0, cast<BasicBlock>(VM[R0]));
  for (auto &[U, idx] : reread)
    U->setOperand(idx, VM[U->getOperand(idx)]);
  // In the copy only the remainder stays (its branches included).
  DenseSet<const Value *> keep;
  for (Instruction *I : need)
    if (Value *c = VM.lookup(I))
      keep.insert(c);
  SmallVector<Instruction *, 32> drop;
  for (BasicBlock *c : copies)
    for (Instruction &I : *c)
      if (!I.isTerminator() && !keep.count(&I))
        drop.push_back(&I);
  for (Instruction *I : drop)
    I->replaceAllUsesWith(PoisonValue::get(I->getType()));
  for (Instruction *I : drop)
    I->eraseFromParent();
  // The repeated loops keep no a_K (loops-cutoff reads the mark).
  for (BasicBlock *b : r.blocks)
    if (headers.count(b))
      cast<BasicBlock>(VM[b])
          ->getTerminator()
          ->setMetadata("cq.repeat", MDNode::get(F.getContext(), {}));
  return true;
}

} // namespace

SmallVector<Function *, 4> repeatAfterEnd(Module &M, const TaintInfo &T) {
  SmallVector<Function *, 4> out;
  for (Function &F : M) {
    if (F.isDeclaration() || (!T.isTainted(F) && !T.hasClone(F)))
      continue;
    bool any = false;
    // Each cut changes the CFG: the analyses are made afresh for the next region (a bounded number: one per end).
    for (unsigned n = 0; n < 16 && Repeater(F, T).run(); ++n)
      any = true;
    if (any)
      out.push_back(&F);
  }
  return out;
}

bool repeatedLoop(const llvm::Loop &L) {
  const Instruction *t = L.getHeader()->getTerminator();
  return t && t->getMetadata("cq.repeat");
}

} // namespace cq::invert
