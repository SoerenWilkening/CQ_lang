// Module loops-rolled (cq-9kcq, step S1): the rolled region (Rolled.h). Moved from loops-classical
// (Classical.cpp) without change.
#include "Rolled.h"

#include <optional>
#include <string>
#include <tuple>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Order.h"
#include "../../spine/SpineInternal.h"

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"

using namespace llvm;

namespace cq::loops::rolled {

Value *carryTo(BasicBlock *at, BasicBlock *D, Value *v, Value *dflt, const Twine &name,
              BasicBlock *reset) {
  DenseMap<BasicBlock *, Value *> memo;
  std::vector<PHINode *> made;
  std::function<Value *(BasicBlock *)> end = [&](BasicBlock *b) -> Value * {
    if (b == D)
      return v;
    if (b == reset)
      return dflt;
    if (auto it = memo.find(b); it != memo.end())
      return it->second;
    SmallVector<BasicBlock *, 4> ps(predecessors(b));
    if (ps.empty())
      return memo[b] = dflt;
    if (ps.size() == 1)
      return memo[b] = end(ps[0]);
    PHINode *phi = PHINode::Create(v->getType(), ps.size(), name);
    phi->insertInto(b, b->begin());
    memo[b] = phi;
    made.push_back(phi);
    for (BasicBlock *p : ps)
      phi->addIncoming(end(p), p);
    return phi;
  };
  Value *r = end(at);
  for (bool changed = true; changed;) {
    changed = false;
    for (PHINode *&phi : made) {
      if (!phi)
        continue;
      Value *same = nullptr;
      bool trivial = true;
      for (Value *in : phi->incoming_values()) {
        if (in == phi || in == same)
          continue;
        if (same) {
          trivial = false;
          break;
        }
        same = in;
      }
      if (!trivial || !same)
        continue;
      phi->replaceAllUsesWith(same);
      if (r == phi)
        r = same;
      phi->eraseFromParent();
      phi = nullptr;
      changed = true;
    }
  }
  return r;
}

// The push/pop stack (CR §1.3: i32 words, a wider value low word first). Every first-class type a per-trip
// value can have: a scalar (integer of any width, floating point, pointer) is its bits in words; a vector,
// struct or array is its elements in order (popped in reverse).
unsigned scalarBits(Type *t, const DataLayout &DL) {
  if (t->isIntegerTy())
    return t->getIntegerBitWidth();
  if (t->isPointerTy())
    return DL.getPointerSizeInBits(t->getPointerAddressSpace());
  if (t->isFloatingPointTy())
    return unsigned(t->getPrimitiveSizeInBits());
  internalError("loops-classical: a per-trip SSA value of a type that is no first-class data type");
}

void pushValue(IRBuilder<> &B, FunctionCallee push, Value *v, const DataLayout &DL) {
  LLVMContext &C = v->getContext();
  IntegerType *i32 = Type::getInt32Ty(C);
  Type *t = v->getType();
  if (auto *st = dyn_cast<StructType>(t)) {
    for (unsigned k = 0; k < st->getNumElements(); ++k)
      pushValue(B, push, B.CreateExtractValue(v, k), DL);
    return;
  }
  if (auto *at = dyn_cast<ArrayType>(t)) {
    for (unsigned k = 0; k < at->getNumElements(); ++k)
      pushValue(B, push, B.CreateExtractValue(v, k), DL);
    return;
  }
  if (auto *vt = dyn_cast<FixedVectorType>(t)) {
    for (unsigned k = 0; k < vt->getNumElements(); ++k)
      pushValue(B, push, B.CreateExtractElement(v, B.getInt64(k)), DL);
    return;
  }
  if (t == i32) {
    B.CreateCall(push, {v});
    return;
  }
  unsigned bits = scalarBits(t, DL), w = (bits + 31) / 32;
  Value *x = t->isPointerTy() ? B.CreatePtrToInt(v, B.getIntNTy(bits))
             : t->isIntegerTy() ? v
                                : B.CreateBitCast(v, B.getIntNTy(bits));
  x = B.CreateZExt(x, B.getIntNTy(32 * w));
  for (unsigned j = 0; j < w; ++j)
    B.CreateCall(push, {B.CreateTrunc(j ? B.CreateLShr(x, 32 * j) : x, i32)});
}

Value *popValue(IRBuilder<> &B, FunctionCallee pop, Type *t, const DataLayout &DL) {
  LLVMContext &C = t->getContext();
  IntegerType *i32 = Type::getInt32Ty(C);
  if (isa<StructType>(t) || isa<ArrayType>(t)) {
    unsigned n = isa<StructType>(t) ? cast<StructType>(t)->getNumElements() : cast<ArrayType>(t)->getNumElements();
    Value *agg = PoisonValue::get(t);
    for (unsigned k = n; k-- > 0;) {
      Type *et = isa<StructType>(t) ? cast<StructType>(t)->getElementType(k) : cast<ArrayType>(t)->getElementType();
      agg = B.CreateInsertValue(agg, popValue(B, pop, et, DL), k);
    }
    return agg;
  }
  if (auto *vt = dyn_cast<FixedVectorType>(t)) {
    Value *vec = PoisonValue::get(t);
    for (unsigned k = vt->getNumElements(); k-- > 0;)
      vec = B.CreateInsertElement(vec, popValue(B, pop, vt->getElementType(), DL), B.getInt64(k));
    return vec;
  }
  if (t == i32)
    return B.CreateCall(pop);
  unsigned bits = scalarBits(t, DL), w = (bits + 31) / 32;
  IntegerType *wide = Type::getIntNTy(C, 32 * w);
  Value *x = ConstantInt::get(wide, 0);
  for (unsigned j = w; j-- > 0;) {
    Value *word = B.CreateZExt(B.CreateCall(pop), wide);
    x = B.CreateOr(x, j ? B.CreateShl(word, 32 * j) : word);
  }
  x = B.CreateTrunc(x, Type::getIntNTy(C, bits));
  if (t->isPointerTy())
    return B.CreateIntToPtr(x, t);
  return t->isIntegerTy() ? x : B.CreateBitCast(x, t);
}

// Per trip (rule 5, as early as allowed): a rail made and last read within one segment is uncomputed
// at the end of that segment, in every trip (60: the Toffoli flag of q[j] && q[i]). What is left
// waits for the reverse loop.
// The flush runs with every back edge of the region cut: an item placed in its record's segment is
// reached from a gate of another segment only by a path that re-executes the record (a later trip),
// so only the acyclic trip may count as "between" for Uncompute's barrier check.
void Region::flushTrips() {
  // An edge entering each segment, taken before any item is placed: an item placed inside a segment
  // (a trip-local sub-loop's reverse, 176) splits its block, the head and the incoming edges moving to a
  // fresh block (Uncompute::placeDeferred), so the segment's head is found again through this edge.
  entering.assign(segs.size(), {nullptr, 0});
  for (unsigned i = 0; i < segs.size(); ++i)
    for (BasicBlock *p : predecessors(segs[i].head)) {
      Instruction *t = p->getTerminator();
      for (unsigned k = 0; k < t->getNumSuccessors(); ++k)
        if (t->getSuccessor(k) == segs[i].head && !entering[i].first)
          entering[i] = {t, k};
    }
  BasicBlock *cut = newBlock();
  new UnreachableInst(Mod.getContext(), cut);
  std::vector<std::tuple<Instruction *, unsigned, unsigned>> backEdges;   // (terminator, successor, head index)
  std::vector<std::pair<Instruction *, unsigned>> headEntry(heads.size(), {nullptr, 0});
  for (unsigned h = 0; h < heads.size(); ++h) {
    auto [H, from] = heads[h];
    Instruction *ft = from->getTerminator();
    for (unsigned k = 0; ft && k < ft->getNumSuccessors(); ++k)
      if (ft->getSuccessor(k) == H)
        headEntry[h] = {ft, k};
    for (BasicBlock *p : predecessors(H)) {
      if (p == from)
        continue;
      Instruction *t = p->getTerminator();
      for (unsigned k = 0; k < t->getNumSuccessors(); ++k)
        if (t->getSuccessor(k) == H && !is_contained(backEdges, std::make_tuple(t, k, h)))
          backEdges.push_back({t, k, h});
    }
  }
  for (auto &[t, k, h] : backEdges)
    t->setSuccessor(k, cut);
  auto finishSubs = [&](unsigned upTo) {
    for (Sub &sb : subs)
      if (sb.entrySeg < upTo && sb.unit->finish) {
        sb.unit->hostScopes = hostScopes;
        sb.unit->hostScopes.push_back(ownSeedScope);
        for (const Seg &sg : segs)
          sb.unit->hostScopes.push_back(sg.scope);
        auto f = std::move(sb.unit->finish);
        sb.unit->finish = nullptr;
        f();
      }
  };
  // A rule-6 clean-up whose block is no segment's last (code after it in the segment branched) is placed at that block's
  // end, alone; one whose block is a segment's last goes with that segment's flush.
  DenseMap<const BasicBlock *, unsigned> lastOf;
  for (unsigned i = 0; i < segs.size(); ++i)
    lastOf[segs[i].bb] = i;
  {
    std::vector<std::pair<Instruction *, SmallVector<RailId, 4>>> mid;   // per block end, in lateR6's order
    for (auto &[g, at] : lateR6) {
      if (lastOf.count(at->getParent()))
        continue;
      Instruction *t = at->getParent()->getTerminator();
      auto it = find_if(mid, [&](const auto &m) { return m.first == t; });
      if (it == mid.end())
        mid.push_back({t, {}}), it = std::prev(mid.end());
      it->second.push_back(g);
    }
    for (auto &[t, gs] : mid)
      U.flushRailsBefore(gs, t);
  }
  for (unsigned i = 0; i < segs.size(); ++i) {
    for (auto &[g, at] : lateR6)
      if (at->getParent() == segs[i].bb)
        U.flushIn(g, segs[i].bb);
    U.flushBefore(segs[i].bb->getTerminator());
    finishSubs(i + 1);
  }
  finishSubs(~0u);
  for (unsigned h = 0; h < heads.size(); ++h)
    if (headEntry[h].first)
      heads[h].first = headEntry[h].first->getSuccessor(headEntry[h].second);
  for (auto &[t, k, h] : backEdges)
    t->setSuccessor(k, heads[h].first);
  cut->eraseFromParent();
  // Every trip-local sub-loop's reverse must have been placed in this region's trip (its exit values'
  // readers are the trip's): otherwise it would run once, after the loop, for the last trip only.
  for (Sub &sb : subs)
    if (!sb.unit->reversed)
      unimplemented("loops-classical: a trip-local sub-loop's reverse could not be placed inside its parent's "
                    "trip (rule 14 in a rule-14 trip)",
                    sb.unit->diagAt);
}

void Region::reverse(IRBuilder<> &BX, BasicBlock *X, unsigned seedScope, bool guarded) {
  Module &M = Mod;
  LLVMContext &C = M.getContext();
  FunctionCallee push = abi::declare(M, abi::CoreSpec{abi::Core::Push});
  FunctionCallee pop = abi::declare(M, abi::CoreSpec{abi::Core::Pop});
  IntegerType *i32 = Type::getInt32Ty(C);
  reversed = true;
  revAt = BX.GetInsertBlock();
  const unsigned n = segs.size();
  // A segment is the blocks from its head to its block segs[i].bb, which keeps its terminator: one
  // block, unless an item placed inside it split it (flushTrips' entering edge finds the head).
  std::vector<BasicBlock *> headOf(n);
  DenseMap<const BasicBlock *, unsigned> segOf;
  std::vector<SmallVector<BasicBlock *, 4>> blocksOf(n);
  for (unsigned i = 0; i < n; ++i)
    headOf[i] = i < entering.size() && entering[i].first ? entering[i].first->getSuccessor(entering[i].second)
                                                         : segs[i].head;
  DenseSet<const BasicBlock *> stops;
  for (unsigned i = 0; i < n; ++i) {
    stops.insert(headOf[i]);
    stops.insert(segs[i].bb);
  }
  for (unsigned i = 0; i < n; ++i) {
    SmallVector<BasicBlock *, 8> work{headOf[i]};
    while (!work.empty()) {
      BasicBlock *b = work.pop_back_val();
      if (segOf.count(b))
        continue;
      segOf[b] = i;
      blocksOf[i].push_back(b);
      if (b == segs[i].bb)
        continue;
      for (BasicBlock *x : successors(b))
        if (!stops.count(x) && !subBlocks.count(x))
          work.push_back(x);
        else if (x == segs[i].bb)
          work.push_back(x);
    }
    if (!segOf.count(segs[i].bb) || segOf.lookup(segs[i].bb) != i)
      internalError("loops-classical: a segment's head does not reach its block", segs[i].bb->getTerminator());
  }
  // cq-x00t (CR rules 5, 14; 176): a trip-local sub-loop's reverse pops the frames its forward trips
  // pushed, so nothing of this region may be pushed between the sub-loop's exit and that reverse. This
  // region pushes a segment's path record (below) at the start of the segment's block segs[i].bb, after
  // any item placed in the segment, and its read-back values at that block's terminator. So the reverse
  // must lie in the segment the sub-loop exits into, before segs[i].bb.
  for (const Sub &sb : subs) {
    BasicBlock *at = sb.unit->revAt;
    if (!at)
      continue;
    auto it = segOf.find(at);
    unsigned i = it == segOf.end() ? n : it->second;
    if (i == n || at == segs[i].bb || !is_contained(predecessors(headOf[i]), sb.cont))
      unimplemented("loops-classical: a trip-local sub-loop's reverse placed outside the segment its loop exits "
                    "into (a record of the parent pushed between the sub-loop's exit and its reverse)",
                    sb.unit->diagAt);
  }
  DenseSet<const BasicBlock *> region;
  for (auto &kv : segOf)
    region.insert(kv.first);
  // The forward predecessor of a segment: a sub-unit's continuation stands for the segment entering it.
  auto mapPred = [&](BasicBlock *p) -> BasicBlock * {
    if (auto it = throughSub.find(p); it != throughSub.end())
      return it->second;
    return p;
  };
  auto predsOf = [&](unsigned i) {
    SmallVector<BasicBlock *, 4> ps;
    for (BasicBlock *p : predecessors(headOf[i]))
      ps.push_back(p);
    return ps;
  };

  // Forward dominance over the region (the entry E outside it is the root).
  std::vector<BitVector> dom(n, BitVector(n, true));
  {
    bool changed = true;
    while (changed) {
      changed = false;
      for (unsigned i = 0; i < n; ++i) {
        BitVector d(n, true);
        bool anyPred = false;
        for (BasicBlock *p0 : predsOf(i)) {
          BasicBlock *p = mapPred(p0);
          anyPred = true;
          if (region.count(p))
            d &= dom[segOf.lookup(p)];
          else
            d.reset();
        }
        if (!anyPred)
          d.reset();
        d.set(i);
        if (d != dom[i]) {
          dom[i] = d;
          changed = true;
        }
      }
    }
  }

  const Instruction *crossGate = nullptr;
  {
    DenseSet<const Value *> fresh;
    for (const Seg &s : segs)
      for (const Record &r : U.scopeRecords(s.scope))
        fresh.insert(r.forward);
    for (unsigned si = 0; si < n; ++si)
      for (BasicBlock *sbb : blocksOf[si])
      for (Instruction &I : *sbb) {
        auto *call = dyn_cast<CallInst>(&I);
        Function *callee = call ? call->getCalledFunction() : nullptr;
        if (!callee || crossGate)
          continue;
        std::optional<abi::CoreSpec> cs = abi::parseCore(callee->getName());
        if (!cs || cs->unc || (cs->op != abi::Core::Ry && cs->op != abi::Core::RyQAngle))
          continue;
        for (Value *a : call->args())
          if (a->getType() == i32 && !isa<Constant>(a) && !fresh.count(a))
            crossGate = call;
      }
  }
  auto checkDeferred = [&](BasicBlock *bb, BasicBlock::iterator from) {
    if (!crossGate)
      return;
    for (auto it = from; it != bb->end(); ++it) {
      // The release of a seed never written (rule 7: an edge seed of the trip, 176) reads no other rail
      // and its own is never a gate's target: no later trip's gate can change what it undoes.
      if (auto *fr = dyn_cast<CallInst>(&*it); fr && fr->getCalledFunction() && fr->arg_size() == 1) {
        std::optional<abi::CoreSpec> cs = abi::parseCore(fr->getCalledFunction()->getName());
        auto *src = dyn_cast<CallInst>(fr->getArgOperand(0));
        std::optional<abi::CoreSpec> as =
            src && src->getCalledFunction() ? abi::parseCore(src->getCalledFunction()->getName()) : std::nullopt;
        if (cs && cs->op == abi::Core::Free && as && as->op == abi::Core::Alloc &&
            all_of(src->users(), [&](const User *u) {
              return u == fr || isa<PHINode>(u) || isa<SelectInst>(u) ||
                     (isa<CallInst>(u) && cast<CallInst>(u)->getCalledFunction() &&
                      cast<CallInst>(u)->getCalledFunction()->getName() == "cqrt_push");
            }))
          continue;
      }
      if (isa<CallInst>(*it))
        unimplemented("loops-classical: a non-diagonal gate in a classically bounded loop on a rail that is not "
                      "made in its own trip, while the reverse loop still undoes a record (rule 5's invariant "
                      "across trips: a later trip's gate may touch a rail an earlier trip's record read)",
                      crossGate);
    }
  };

  // Rule 5's invariant within the deferral (cq-vqid): an item the reverse loop undoes reads the rails
  // its records read, and they must still hold the value those records read. A non-diagonal gate
  // in the region on such a rail (a merge read reads every arm it may name) that can run after one
  // of the item's forward records, before the rail is made again, rotates it under the deferred
  // undo: the same trip after the record, or a later trip of an enclosing loop of the region on a
  // rail that the trip does not make again. cq::unimplemented (the undo is never placed before the
  // gate: it waits for the reverse loop).
  struct Gate {
    CallInst *call;
    Value *target;
  };
  std::vector<Gate> gates;
  for (unsigned si = 0; si < n; ++si)
    for (BasicBlock *sbb : blocksOf[si])
    for (Instruction &I : *sbb)
      if (auto *call = dyn_cast<CallInst>(&I))
        if (Function *callee = call->getCalledFunction())
          if (std::optional<abi::CoreSpec> cs = abi::parseCore(callee->getName());
              cs && !cs->unc && (cs->op == abi::Core::Ry || cs->op == abi::Core::RyQAngle))
            gates.push_back({call, call->getArgOperand(cs->ctl ? 1 : 0)});
  std::vector<CallInst *> fwdRecords;
  for (const Seg &s : segs)
    for (const Record &r : U.scopeRecords(s.scope))
      fwdRecords.push_back(r.forward);
  auto leavesOf = [&](Value *v) {
    SmallVector<Value *, 4> out, work{v};
    SmallPtrSet<Value *, 8> seen;
    while (!work.empty()) {
      Value *x = work.pop_back_val();
      if (!seen.insert(x).second)
        continue;
      if (auto *p = dyn_cast<PHINode>(x); p && p->getType() == i32) {
        for (Value *in : p->incoming_values())
          work.push_back(in);
        continue;
      }
      if (auto *sl = dyn_cast<SelectInst>(x); sl && sl->getType() == i32) {
        work.push_back(sl->getTrueValue());
        work.push_back(sl->getFalseValue());
        continue;
      }
      if (!isa<Constant>(x))
        out.push_back(x);
    }
    return out;
  };
  // May G run after f, on a path that does not make `rail` again? f == nullptr: f is before the region.
  auto runsAfter = [&](const Instruction *f, const Instruction *G, const Value *rail) {
    if (!f || !region.count(f->getParent()))
      return true;
    if (f->getParent() == G->getParent() && cq::comesBefore(f, G))
      return true;
    auto *d = dyn_cast<Instruction>(rail);
    const BasicBlock *db = d && region.count(d->getParent()) ? d->getParent() : nullptr;
    SmallVector<const BasicBlock *, 8> work;
    SmallPtrSet<const BasicBlock *, 16> seen;
    for (const BasicBlock *b : successors(f->getParent()))
      work.push_back(b);
    while (!work.empty()) {
      const BasicBlock *b = work.pop_back_val();
      if (!(region.count(b) || subBlocks.count(b)) || !seen.insert(b).second)
        continue;
      if (b == db) {
        if (G->getParent() == b && cq::comesBefore(G, d))
          return true;
        continue;
      }
      if (G->getParent() == b)
        return true;
      for (const BasicBlock *nb : successors(b))
        work.push_back(nb);
    }
    return false;
  };
  // cq-wyu4 (CR rule 5's scheduling invariant, rule 6's kept old value, rule 10: "a flag that read the rotated
  // register stays allocated"; A4): a template record whose item the reverse loop undoes reads a rail that a
  // non-diagonal gate of the region may rotate after the record, on the instance it read (later in the trip, or in
  // a later trip). On a run where such a gate did act after the record, no point lies between the record's last
  // consumer and the gate: the record is a which-path record of the rotated rail and stays allocated (A4); where
  // none did, it is garbage and the reverse loop undoes it. Which one is a run-time fact: each such gate counts its
  // runs in a classical counter (every run, whatever its angle: the gate is non-diagonal by the program's text, as the
  // straight-line spine keeps such a record), the record reads the counters right after it (pushed with its trip), and its item in the reverse loop runs
  // under a classical branch on "no counter moved since". Its consumers' items read it in either case. Another
  // record (an in-place write) so hit is kept (KeptEntangled). Decided before any mirror is emitted.
  struct GuardedItem {
    CallInst *f;
    unsigned seg;
    SmallVector<std::pair<AllocaInst *, Value *>, 2> snaps; // (counter, its value right after f)
  };
  std::vector<GuardedItem> guardedItems;
  SmallVector<std::pair<CallInst *, AllocaInst *>, 2> counters; // gate -> its run counter (program order)
  auto counterOf = [&](CallInst *G) -> AllocaInst * {
    for (auto &kv : counters)
      if (kv.first == G)
        return kv.second;
    BasicBlock &EB = Out.getEntryBlock();
    IRBuilder<> EBld(&EB, EB.getFirstInsertionPt());
    AllocaInst *ctr = EBld.CreateAlloca(i32, nullptr, "cq.gates");
    EBld.CreateStore(ConstantInt::get(i32, 0), ctr);
    IRBuilder<> GB(G->getNextNode());
    GB.CreateStore(GB.CreateAdd(GB.CreateLoad(i32, ctr), ConstantInt::get(i32, 1)), ctr);
    counters.push_back({G, ctr});
    return ctr;
  };
  if (!gates.empty())
    for (unsigned si = 0; si < n; ++si)
      for (const Record &rec : U.scopeRecords(segs[si].scope)) {
        CallInst *f = rec.forward;
        if (!U.liveRole(rec.out) || *U.liveRole(rec.out) != Role::Garbage)
          continue;
        SmallVector<CallInst *, 2> hits;
        for (Value *a : f->args()) {
          if (a->getType() != i32 || isa<Constant>(a) || (U.recorded(a) && U.idOf(a) == rec.out))
            continue;
          for (Value *l : leavesOf(a))
            for (const Gate &g : gates)
              for (Value *t : leavesOf(g.target))
                if (t == l && g.call != f && !is_contained(hits, g.call) && runsAfter(f, g.call, l))
                  hits.push_back(g.call);
        }
        if (hits.empty())
          continue;
        if (!std::holds_alternative<abi::TemplateSpec>(rec.spec) || f->getType() != i32) {
          U.setRole(rec.out, Role::KeptEntangled);
          continue;
        }
        GuardedItem gi{f, si, {}};
        IRBuilder<> SB(f->getNextNode());
        for (CallInst *G : hits) {
          AllocaInst *ctr = counterOf(G);
          gi.snaps.push_back({ctr, SB.CreateLoad(i32, ctr, "cq.gates.at")});
        }
        guardedItems.push_back(std::move(gi));
      }
  std::vector<BasicBlock *> guardBlocks;
  DenseSet<const Instruction *> guardedCalls;
  auto checkUndoneReads = [&](BasicBlock *bb) {
    if (gates.empty())
      return;
    for (Instruction &I : *bb) {
      auto *m = dyn_cast<CallInst>(&I);
      Function *callee = m ? m->getCalledFunction() : nullptr;
      if (!callee)
        continue;
      StringRef name = callee->getName();
      SmallVector<Value *, 4> args(m->args());
      // The forward records this item undoes: the call it was spelled from (the same name, or the
      // name + "_unc"; the forward argument list, after the out handle for a template).
      SmallVector<const Instruction *, 2> anchors;
      for (CallInst *fwd : fwdRecords) {
        StringRef fn = fwd->getCalledFunction() ? fwd->getCalledFunction()->getName() : StringRef();
        if (fn.empty() || !(name == fn || name == (fn + "_unc").str()))
          continue;
        SmallVector<Value *, 4> fa(fwd->args());
        bool same = args == fa;
        bool withOut = !same && args.size() == fa.size() + 1 && args[0] == fwd &&
                       std::equal(fa.begin(), fa.end(), args.begin() + 1);
        if (same || withOut)
          anchors.push_back(fwd);
      }
      if (guardedCalls.count(m))
        continue; // cq-wyu4: it runs only where no gate acted after its record
      if (anchors.empty()) {
        // A free (or an item with no forward call of its own): its rails are read from their
        // definitions on.
        for (Value *a : args)
          if (a->getType() == i32 && !isa<Constant>(a))
            for (Value *l : leavesOf(a))
              anchors.push_back(dyn_cast<Instruction>(l));
      }
      for (Value *a : args) {
        if (a->getType() != i32 || isa<Constant>(a))
          continue;
        for (Value *l : leavesOf(a))
          for (const Gate &g : gates)
            for (Value *t : leavesOf(g.target))
              if (t == l)
                for (const Instruction *f : anchors)
                  if (runsAfter(f, g.call, l))
                    unimplemented("loops-classical: a non-diagonal gate in a classically bounded loop on a rail "
                                  "that a record undone by the reverse loop reads, after that record (rule 5: "
                                  "the reverse loop would undo it against the rotated rail)",
                                  g.call);
      }
    }
  };

  BasicBlock *Z = newBlock();
  std::vector<BasicBlock *> R(n);
  for (unsigned i = 0; i < n; ++i)
    R[i] = newBlock();
  // After a segment's mirror: each guarded item of the segment, `<template>_unc(f, …)` through `cqrt_free(f)`, moves
  // into a block of its own entered only where no counter it reads moved since the record.
  auto guardItems = [&](unsigned si, IRBuilder<> &B) {
    for (const GuardedItem &gi : guardedItems) {
      if (gi.seg != si)
        continue;
      std::string uname = (gi.f->getCalledFunction()->getName() + "_unc").str();
      CallInst *unc = nullptr, *fr = nullptr;
      SmallVector<BasicBlock *, 8> work{R[si]};
      SmallPtrSet<BasicBlock *, 8> seen{R[si]};
      while (!work.empty() && !unc) {
        BasicBlock *mb = work.pop_back_val();
        for (Instruction &I : *mb) {
          auto *c = dyn_cast<CallInst>(&I);
          Function *cf = c ? c->getCalledFunction() : nullptr;
          if (!cf)
            continue;
          if (!unc && cf->getName() == uname && c->arg_size() >= 1 && c->getArgOperand(0) == gi.f)
            unc = c;
          else if (unc && cf->getName() == "cqrt_free" && c->getArgOperand(0) == gi.f) {
            fr = c;
            break;
          }
        }
        if (unc)
          break;
        if (mb->getTerminator())
          for (BasicBlock *sb : successors(mb))
            if (seen.insert(sb).second)
              work.push_back(sb);
      }
      if (!unc || !fr)
        continue; // no item of this spelling here (rule 6 cleaned it, say): checkUndoneReads judges it
      BasicBlock *head = unc->getParent();
      bool atB = head == B.GetInsertBlock();
      BasicBlock *mid = newBlock(), *tail = newBlock();
      std::vector<Instruction *> moveMid, moveTail;
      bool inMid = false, inTail = false;
      for (Instruction &I : *head) {
        if (&I == unc)
          inMid = true;
        if (inTail)
          moveTail.push_back(&I);
        else if (inMid)
          moveMid.push_back(&I);
        if (&I == fr)
          inTail = true;
      }
      for (Instruction *I : moveMid)
        I->moveBefore(*mid, mid->end());
      for (Instruction *I : moveTail)
        I->moveBefore(*tail, tail->end());
      if (tail->getTerminator())
        for (BasicBlock *s : successors(tail))
          s->replacePhiUsesWith(head, tail);
      IRBuilder<> HB(head);
      Value *ok = ConstantInt::getTrue(C);
      for (auto &[ctr, at] : gi.snaps)
        ok = HB.CreateAnd(ok, HB.CreateICmpEQ(HB.CreateLoad(i32, ctr, "cq.gates.now"), at));
      HB.CreateCondBr(ok, mid, tail);
      BranchInst::Create(tail, mid);
      guardBlocks.push_back(mid);
      guardBlocks.push_back(tail);
      guardedCalls.insert(unc);
      guardedCalls.insert(fr);
      if (atB)
        B.SetInsertPoint(tail);
    }
  };
  Instruction *anchor = nullptr;   // a reverse instruction for the uses of the external initial rails

  // cq-h5uj: the copies of the exit values are undone first (they read the last trip's rails, a trip's merge's arms included).
  BasicBlock *copyBlock = nullptr;
  if (copyScope != ~0u) {
    copyBlock = newBlock();
    IRBuilder<> Bc(copyBlock);
    U.emitMirror(copyScope, Bc);
  }

  // cq-v0a5c: likewise each exit edge's copies, before the segment they read.
  SmallVector<BasicBlock *, 2> edgeCopyOf;
  for (unsigned sc : exitEdgeScope) {
    BasicBlock *cb = nullptr;
    if (sc != ~0u) {
      cb = newBlock();
      IRBuilder<> Bc(cb);
      U.emitMirror(sc, Bc);
    }
    edgeCopyOf.push_back(cb);
  }

  for (unsigned i = n; i-- > 0;) {
    IRBuilder<> B(R[i]);
    U.emitMirror(segs[i].scope, B);
    guardItems(i, B);
    checkUndoneReads(R[i]);
    checkDeferred(R[i], R[i]->begin());
    // The mirror, with the reverse of any loop of the segment placed in it (its own blocks, B's block last).
    std::vector<Instruction *> mirror;
    {
      SmallVector<BasicBlock *, 8> work{R[i]};
      SmallPtrSet<BasicBlock *, 8> seen{R[i]};
      while (!work.empty()) {
        BasicBlock *mb = work.pop_back_val();
        for (Instruction &I : *mb)
          mirror.push_back(&I);
        if (mb->getTerminator())
          for (BasicBlock *sb : successors(mb))
            if (seen.insert(sb).second)
              work.push_back(sb);
      }
    }
    // The forward values the mirror reads: popped here, pushed at the end of the segment.
    std::vector<Value *> needs;
    for (Instruction *I : mirror)
      for (Use &u : I->operands())
        if (auto *d = dyn_cast<Instruction>(u.get()); d && region.count(d->getParent()) && segOf.count(d->getParent()) &&
                                                      !is_contained(needs, d)) {
          if (!dom[i].test(segOf.lookup(d->getParent())))
            internalError("loops-classical: a mirror item reads a value defined in a segment that does not dominate "
                          "its own",
                          d);
          needs.push_back(d);
        }
    DenseMap<Value *, Value *> popped;
    {
      IRBuilder<> P(R[i], R[i]->begin());
      for (unsigned k = needs.size(); k-- > 0;)
        popped[needs[k]] = popValue(P, pop, needs[k]->getType(), M.getDataLayout());
    }
    for (Instruction *I : mirror)
      for (Use &u : I->operands())
        if (auto it = popped.find(u.get()); it != popped.end())
          u.set(it->second);
    {
      IRBuilder<> Pu(segs[i].bb->getTerminator());
      for (Value *v : needs)
        pushValue(Pu, push, v, M.getDataLayout());
    }
    // Where the reverse goes next: the reverse of the forward predecessor.
    SmallVector<BasicBlock *, 4> uniq;
    for (BasicBlock *p : predsOf(i))
      if (!is_contained(uniq, mapPred(p)))
        uniq.push_back(mapPred(p));
    auto back = [&](BasicBlock *p) { return region.count(p) ? R[segOf.lookup(p)] : Z; };
    if (uniq.size() == 1) {
      B.CreateBr(back(uniq[0]));
      continue;
    }
    BasicBlock *hd = headOf[i];
    PHINode *cf = PHINode::Create(i32, pred_size(hd), "from");
    cf->insertInto(hd, hd->begin());
    for (BasicBlock *p : predecessors(hd))
      cf->addIncoming(ConstantInt::get(i32, find(uniq, mapPred(p)) - uniq.begin()), p);
    // After any item placed in the segment (a trip-local sub-loop's reverse pops the frames under it).
    BasicBlock *pb = segs[i].bb;
    IRBuilder<>(pb, pb->getFirstInsertionPt()).CreateCall(push, {cf});
    CallInst *k = B.CreateCall(pop);
    if (!anchor && any_of(uniq, [&](BasicBlock *p) { return !region.count(p); }))
      anchor = k;
    SwitchInst *sw = B.CreateSwitch(k, back(uniq[0]), uniq.size() - 1);
    for (unsigned j = 1; j < uniq.size(); ++j)
      sw->addCase(ConstantInt::get(i32, j), back(uniq[j]));
  }

  // The reverse starts at the reverse of the segment that exits; guarded (cq-fx3s), only where the
  // loop ran: the value "the loop's exit block was passed" (false at the function's entry, true at
  // X), read at the start of the item.
  BasicBlock *join = nullptr;
  BasicBlock *guardBlock = BX.GetInsertBlock();
  {
    BasicBlock *start;
    if (exitIndex) {
      // cq-j5mq: the reverse starts at the segment of the exit edge taken.
      start = newBlock();
      Value *ix = guarded ? carryTo(guardBlock, X, exitIndex, PoisonValue::get(exitIndex->getType()), "exit", resetAt)
                          : static_cast<Value *>(exitIndex);
      // Each exit edge's copies are undone first (they read the rails of the segment the edge leaves).
      auto startOf = [&](unsigned k) -> BasicBlock * {
        BasicBlock *r = R[segOf.lookup(exitSegs[k])];
        BasicBlock *cb = k < edgeCopyOf.size() ? edgeCopyOf[k] : nullptr;
        if (!cb)
          return r;
        BranchInst::Create(r, cb);
        return cb;
      };
      SwitchInst *sw = SwitchInst::Create(ix, startOf(0), exitSegs.size() - 1, start);
      for (unsigned k = 1; k < exitSegs.size(); ++k)
        sw->addCase(ConstantInt::get(i32, k), startOf(k));
    } else {
      BasicBlock *exitSeg = nullptr;
      for (BasicBlock *p : predecessors(X)) {
        if (!region.count(p) || (exitSeg && exitSeg != p))
          internalError("loops-classical: the loop's exit block is not reached from exactly one segment",
                        diagAt);
        exitSeg = p;
      }
      start = R[segOf.lookup(exitSeg)];
    }
    if (copyBlock) {
      BranchInst::Create(start, copyBlock);
      start = copyBlock;
    }
    Value *ran = ConstantInt::getTrue(C);
    if (guarded) {
      // a trip-local sub-loop's guard is reset per parent trip (false at the end of resetAt)
      ran = carryTo(guardBlock, X, ConstantInt::getTrue(C), ConstantInt::getFalse(C), "ran", resetAt);
    }
    if (auto *k = dyn_cast<ConstantInt>(ran); k && k->isOne()) {
      BX.CreateBr(start);
    } else {
      join = newBlock();
      BX.CreateCondBr(ran, start, join);
    }
  }
  if (!anchor && !externalInits.empty())
    internalError("loops-classical: no reverse instruction reads the loop's initial rails");
  for (Value *h : externalInits)
    U.noteUse(U.idOf(h), anchor);
  IRBuilder<> BZ(Z);
  U.emitMirror(seedScope, BZ);
  checkUndoneReads(Z);
  checkDeferred(Z, Z->begin());
  if (join) {
    // A value from before the region the reverse reads (a seed of the entry E, a rail made on the
    // loop's path only) need not dominate the guarded start: it is read through a phi that names it on
    // the paths where the loop ran (poison where it did not: the reverse does not run there).
    DenseSet<const BasicBlock *> rev(R.begin(), R.end());
    rev.insert(Z);
    SmallVector<BasicBlock *, 8> revBlocks(R.begin(), R.end());
    if (copyBlock) {
      rev.insert(copyBlock);
      revBlocks.push_back(copyBlock);
    }
    for (BasicBlock *cb : edgeCopyOf)
      if (cb) {
        rev.insert(cb);
        revBlocks.push_back(cb);
      }
    for (BasicBlock *gb : guardBlocks) {
      rev.insert(gb);
      revBlocks.push_back(gb);
    }
    std::vector<Use *> outside;
    for (BasicBlock *b : revBlocks)
      for (Instruction &I : *b)
        for (Use &u : I.operands())
          if (auto *d = dyn_cast<Instruction>(u.get()); d && !rev.count(d->getParent()))
            outside.push_back(&u);
    for (Instruction &I : *Z)
      for (Use &u : I.operands())
        if (auto *d = dyn_cast<Instruction>(u.get()); d && !rev.count(d->getParent()))
          outside.push_back(&u);
    DenseMap<std::pair<Instruction *, BasicBlock *>, Value *> carried;
    for (Use *u : outside) {
      auto *d = cast<Instruction>(u->get());
      if (d->getParent() == &Out.getEntryBlock())
        continue;
      // the value at the use: at the end of the incoming block for a phi, else at the end of the
      // block before the reverse (the guard's block dominates every reverse block)
      auto *ui = cast<Instruction>(u->getUser());
      BasicBlock *at = isa<PHINode>(ui) ? cast<PHINode>(ui)->getIncomingBlock(*u) : guardBlock;
      Value *&c = carried[{d, at}];
      if (!c)
        c = carryTo(at, d->getParent(), d, PoisonValue::get(d->getType()), d->getName());
      u->set(c);
    }
    BZ.CreateBr(join);
    BX.SetInsertPoint(join);
  } else {
    BX.SetInsertPoint(Z);
  }
}

bool readersKeep(LoweringContext &ctx, const Loop &top, const Value *v) {
  SmallVector<const Value *, 4> work{v};
  SmallPtrSet<const Value *, 8> seen{v};
  while (!work.empty()) {
    const Value *x = work.pop_back_val();
    for (const User *u : x->users()) {
      auto *ui = dyn_cast<Instruction>(u);
      if (!ui || top.contains(ui))
        continue;
      if (auto *P = dyn_cast<PHINode>(ui)) {
        if (seen.insert(P).second)
          work.push_back(P);
        continue;
      }
      if (isa<ReturnInst>(ui))
        continue;
      if (auto *st = dyn_cast<StoreInst>(ui); st && st->getValueOperand() == x)
        continue;
      // A measurement keeps the rail it reads only where it measures it in place: on every path (lowerMeasure, CR rule 2);
      // one on some classical paths only reads a kept basis copy, and the rail is uncomputed as usual (cq-2xl5).
      if (auto *CB = dyn_cast<CallBase>(ui); CB && calls::classify(*CB, ctx.T, ctx.S) == calls::Class::Measure &&
                                             !ctx.S.table && !ctx.S.ctl &&
                                             spine::measuredOnEveryPath(ctx, CB->getArgOperand(0)))
        continue;
      return false;
    }
  }
  return true;
}

Region::ExitWiring Region::wireExits(unsigned seedScope, ArrayRef<std::pair<const Value *, Operand>> out,
                                     ArrayRef<RailType> outW, Value *stopCur, const DenseSet<const Value *> &keptFinal,
                                     function_ref<bool(const Value *)> scopedOf,
                                     function_ref<void(const Value *, Operand)> put) {
  std::vector<unsigned> scs{seedScope};
  for (const Seg &sg : segs)
    scs.push_back(sg.scope);
  for (unsigned sc : exitEdgeScope)
    if (sc != ~0u)
      scs.push_back(sc);
  DenseSet<const Value *> ownedH;
  for (unsigned sc : scs)
    for (const Record &r : U.scopeRecords(sc))
      if (!r.forward->getType()->isVoidTy() && !U.leftScope(sc, r.forward)) {
        ownedH.insert(r.forward);
        // A clone with rule-19 extras returns a struct: its rails are the call's extractvalues (cq-f96c8).
        for (const User *u : r.forward->users())
          if (isa<ExtractValueInst>(u))
            ownedH.insert(u);
      }
  std::vector<RailId> exits;
  if (stopCur) {
    exits.push_back(U.idOf(stopCur));   // read in place by the enclosing K-loop's predicate
  }
  std::vector<unsigned> copied;   // the values whose exit rail is no record of the loop: copied out, below
  for (unsigned oi = 0; oi < out.size(); ++oi) {
    const Value *v = out[oi].first;
    Operand op = out[oi].second;
    if (!op.handle)
      internalError("loops-classical: a quantum value read after the loop whose exit value is classical", v);
    if (keptFinal.count(op.v)) {
      // A cleaned chain's final rail is the register itself: the reverse never touches it.
      put(v, op);
      continue;
    }
    // A carried register every trip leaves on its rail (rotated in place, rule 10; 126): the header phi
    // names the entry's seed on every edge, so the seed is the register, kept, read in place.
    if (auto *ph = dyn_cast<PHINode>(op.v)) {
      Value *one = nullptr;
      bool single = true;
      for (Value *in : ph->incoming_values())
        if (in != ph && in != one)
          single = single && !one, one = in;
      auto *seed = dyn_cast_or_null<CallInst>(one);
      if (single && seed && ownedH.count(seed) && seed->getCalledFunction() &&
          seed->getCalledFunction()->getName().starts_with("cqrt_alloc_")) {
        U.setRole(U.idOf(seed), Role::UserRegister);
        put(v, Operand{seed, true});
        continue;
      }
    }
    if (ownedH.count(op.v)) {
      put(v, op);
      RailId x = U.idOf(op.v);
      if (!is_contained(exits, x))
        exits.push_back(x);
      continue;
    }
    copied.push_back(oi);
  }
  for (unsigned sc : scs)
    for (const Record &r : U.scopeRecords(sc)) {
      if (r.forward->getType()->isVoidTy() || !std::holds_alternative<abi::TemplateSpec>(r.spec))
        continue;   // a seed stored into a cell is that cell's register (58, 59), never an exit
      bool stored = any_of(r.forward->users(), [&](const User *u) {
        auto *si = dyn_cast<StoreInst>(u);
        return si && si->getValueOperand() == r.forward;
      });
      if (!stored)
        continue;
      RailId x = U.idOf(r.forward);
      if (!is_contained(exits, x))
        exits.push_back(x);
    }
  for (RailId x : exitEdgeRails)
    if (!is_contained(exits, x))
      exits.push_back(x);
  for (unsigned oi : copied) {
    const Value *v = out[oi].first;
    Operand op = out[oi].second;
    RailType w = outW[oi];
    CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                               {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
    // cq-h5uj, cq-k7zkw (CR rule 14 case 1: "after the result is copied out (alloc + copy) a reverse loop pops"; rule 5:
    // every rail is uncomputed after its last consumer, §6 item 1): a loop whose reverse runs after its readers anyway (one
    // that runs per trip of an enclosing loop, or that has an exit rail read in place) keeps no output of its own: the copy
    // is a record of the loop's own copy scope, an exit rail read in place after the loop, and the deferred reverse
    // un-copies it first (reverse(): the copy scope's mirror before the last trip's). A reader that keeps it (a measurement,
    // an escape) is recordDeferred's kept exit rail.
    // The same for a copy some reader only computes from (cq-ii0vf: a trip's join of handles, read by a template): rule 5
    // uncomputes it after that reader, and nothing can once the reverse has run.
    // cq-jos4q: a copy a reader keeps (measured on every path, returned, stored) is the loop's output even where the reverse is
    // deferred for an exit rail read in place: the deferred reverse must not un-copy and free a measured rail (§1.3).
    // cq-2xl5: with classical exit tests besides the bound (extraExits), T joins each exit edge's res and the exit value
    // after the loop is a select over the copies (CR rule 14 case 3): its readers keep the select, not the copies, which
    // are the copy scope's; readersKeep follows the exit phi as if it were the copy (a kept copy left garbage, and recorded
    // in an open copy scope it was owned by the item it was read by: recordDeferred's internal error).
    bool scoped = scopedOf(v);
    if (scoped && copyScope == ~0u)
      copyScope = U.openScope();   // closed after the last copy (below)
    RailId fid = ctx.unc().recordSeed(f);
    abi::CoreSpec cp{abi::Core::Copy, w};
    CallInst *cc = ctx.emitCore(cp, {op.v, f});
    ctx.unc().recordCore(cc, cp, {op, Operand{f, true}}, fid);
    if (!scoped)
      ctx.unc().setRole(fid, Role::Output);
    else {
      ownedH.insert(f);
      if (!is_contained(exits, fid))
        exits.push_back(fid);
    }
    put(v, Operand{f, true});
  }
  if (copyScope != ~0u) {
    U.closeScope(copyScope);
    scs.push_back(copyScope);
  }
  return {std::move(scs), std::move(ownedH), std::move(exits)};
}

bool Region::finishExits(BasicBlock *T, unsigned seedScope, const ExitWiring &w, bool keptInPlace,
                         const Instruction *latchTerm, std::shared_ptr<Region> self) {
  const std::vector<unsigned> &scs = w.scs;
  const DenseSet<const Value *> &ownedH = w.ownedH;
  const std::vector<RailId> &exits = w.exits;
  if (exits.empty()) {
    flushTrips();
    IRBuilder<> B(T);
    reverse(B, T, seedScope, false);
    ctx.B().SetInsertPoint(B.GetInsertBlock());
    return false;
  }
  // The exit rails are read after the loop: no trip's flush may resolve them in their own trip.
  {
    Instruction *xt = nullptr;
    for (BasicBlock *p : predecessors(T))
      xt = p->getTerminator();
    if (!xt)
      internalError("loops-classical: the loop's exit block has no predecessor", latchTerm);
    for (RailId x : exits)
      U.noteUse(x, xt);
  }
  flushTrips();
  std::vector<RailId> reads;
  for (unsigned sc : scs)
    for (const Record &r : U.scopeRecords(sc))
      for (const Operand &o : r.ops)
        if (o.handle && !ownedH.count(o.v))
          if (RailId x = U.idOf(o.v); !is_contained(reads, x))
            reads.push_back(x);
  // cq-odo1: the initial rails from before the loop the header phis name are read by the reverse (its anchor
  // notes them); one the loop's own seed scope minted is the item's.
  for (Value *h : externalInits)
    if (RailId x = U.idOf(h); !ownedH.count(h) && !is_contained(reads, x))
      reads.push_back(x);
  BasicBlock *Cont = newBlock();
  // cq-gty1h (CR rules 2, 5, 14 case 1): the copy scope's records sit in T, so T belongs to the deferred item's region, and
  // the loop's exit block (the one block outside the region the region branches to, where an exit rail that became kept is
  // copied before its first use after the loop) would be Cont, the block of those uses: the kept copy landed after them.
  // An exit rail read in place by a reader that keeps it gets an empty block J between T and Cont: J is that exit block.
  if (keptInPlace) {
    BasicBlock *J = newBlock();
    BranchInst::Create(J, T);
    BranchInst::Create(Cont, J);
  } else
    BranchInst::Create(Cont, T);
  U.recordDeferred(scs, exits,
                   [self, T, seedScope](IRBuilder<> &B) { self->reverse(B, T, seedScope, !self->U.mirroring()); }, reads, {});
  ctx.B().SetInsertPoint(Cont);
  return true;
}

} // namespace cq::loops::rolled
