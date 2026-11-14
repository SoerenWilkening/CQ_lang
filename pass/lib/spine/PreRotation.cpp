// Module spine (cq-s32y): a register's pre-rotation value read after its in-place rotation.
//
// CONTRACT
//
//  Rule 2 rotates an existing rail in place: cq_theta(v, θ) on v's rail h is an Ry on h, and the
//  cq_theta's result names h. The C program (the §6 oracle, NORTHSTAR p2/p5) still reads v's own
//  value wherever v is used after the cq_theta. Orchestrator decision on cq-s32y (owner may
//  override): such a use reads a copy taken just before the rotation.
//
//  CR rule 2 (f684858): the pre-rotation value is kept per path and per trip. Wherever one copy taken
//  at T cannot serve every reader, the Ry hits a copy of h instead (rotateCopy) and h keeps v's value
//  on every path and trip: no stop.
//
//  - Classical guards (cq-drcl). A reader after T whose block's classical factor does not imply T's
//    block's is reached by a path on which T did not run: the Ry hits a copy (h is v on every path).
//  - Not after T (cq-drcl). An instruction lowered after the rebinding that T does not reach (a
//    sibling arm, quantum or classical) reads h for v: there the rotation did not happen.
//  - Phi edges. A phi lowered after T whose incoming v arrives only on edges not after T reads h
//    (atPhiEdge). A phi with edges of both kinds for v: the Ry hits a copy.
//  - Loops. v read on a later trip of a cycle around T (v invariant over the cycle): the Ry hits a
//    copy, one per trip.
//  - Memory (cq-xu07). When v is a load, the cell it read holds h too, and so may any value stored
//    into the cell's object: in C the cell keeps its value. When a read of the object may observe
//    the cell after T (a load, memory intrinsic or call reaching it on a path from T before a store
//    to the load's own pointer overwrites it; a return when the object outlives the function) or a
//    quantum value stored into the object is read after T (q[i] = cq_theta(q[i]); s = cq_theta(q[j])
//    with i == j), the rotation hits a copy instead: c = alloc 0, copy_<W>(h, c), v bound to c while
//    T is lowered (T names c) and back to h after it. Otherwise (the corpus's load, cq_theta, store
//    back: 61, 124) h is rotated in place as before.
//  - Register states (cq-6qum). When the cq_theta is uncontrolled (rule 2's classical angle, or rule
//    15's quantum angle: cq-r9j0), v is a rule 10 register state (Shared::statePreps) and v is read
//    after T (or on a later trip), the rotation hits a copy the same way: rot-cry keeps h as the
//    register (a later disjoint prep xors into it), so h must keep v's value.
//  - Switch atoms (cq-0hhk). Rule 13's case atoms are the scrutinee's value at the switch, and pred
//    mints them where a flag or a select reads them (no IR use: the walk above never sees them). When
//    T rotates h in place while a value bound to h is the scrutinee of a quantum switch whose region
//    (the blocks the switch reaches before its immediate post-dominator) holds T, the region's later
//    atoms would read the rotated rail. A copy c of h is taken before the Ry (shared with the copy
//    above when both are needed) and the switch's atoms read it (Shared::switchSnap,
//    LoweringContext::switchRail). T in a cycle where the scrutinee is invariant, or under a classical
//    guard the switch's block does not have: the Ry hits a copy.
#include "SpineInternal.h"

#include "cq/Abi.h"
#include "cq/Order.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Constants.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq::spine {

namespace {

std::string describe(const Value *v) {
  std::string s;
  raw_string_ostream os(s);
  v->printAsOperand(os, false);
  return os.str();
}

const Function *functionOf(const Value *v) {
  if (auto *I = dyn_cast<Instruction>(v))
    return I->getParent() ? I->getFunction() : nullptr;   // a detached key (eff-fenv's probe key) is in none
  if (auto *A = dyn_cast<Argument>(v))
    return A->getParent();
  return nullptr;
}

// The original blocks reachable from the end of P's block without passing def's block (the
// definition of the value whose instance is tracked). cyclic: P's block is among them.
DenseSet<const BasicBlock *> reachFrom(const Instruction *P, const Value *def, bool &cyclic) {
  const BasicBlock *db = nullptr;
  if (auto *D = dyn_cast_or_null<Instruction>(def))
    db = D->getParent();
  DenseSet<const BasicBlock *> reach;
  SmallVector<const BasicBlock *, 16> work(succ_begin(P->getParent()), succ_end(P->getParent()));
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    if (b == db || !reach.insert(b).second)
      continue;
    for (const BasicBlock *s : successors(b))
      work.push_back(s);
  }
  cyclic = reach.count(P->getParent());
  return reach;
}

bool isAfter(const Instruction *P, const DenseSet<const BasicBlock *> &reach, const Instruction *point) {
  if (point->getParent() == P->getParent() && point != P && cq::comesBefore(P, point))
    return true;
  return reach.count(point->getParent());
}

// Does I come before P on some path that does not pass def's block after I (I would read another
// instance of def's value otherwise)? I in P's block before P, or P's block reachable from I's.
bool precedes(const Instruction *I, const Instruction *P, const Value *def) {
  if (I->getParent() == P->getParent() && I != P && cq::comesBefore(I, P))
    return true;
  const BasicBlock *db = nullptr;
  if (auto *D = dyn_cast<Instruction>(def))
    db = D->getParent();
  DenseSet<const BasicBlock *> seen;
  SmallVector<const BasicBlock *, 16> work(succ_begin(I->getParent()), succ_end(I->getParent()));
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    if (b == P->getParent())
      return true;
    if (b == db || !seen.insert(b).second)
      continue;
    for (const BasicBlock *s : successors(b))
      work.push_back(s);
  }
  return false;
}

// Does w have a use after P (see the contract)? skip: P itself when it reads w. lazy (optional): the
// unlowered readers found, which are emitted at a later reader of theirs.
const Instruction *useAfter(Shared &sh, const Value *w, const Instruction *P, const DenseSet<const BasicBlock *> &reach,
                            SmallVectorImpl<const Instruction *> *all = nullptr) {
  const Instruction *first = nullptr;
  SmallVector<const Use *, 8> uses;
  readingUses(sh, w, uses);   // a skipped zext's readers read w (cq-su3p)
  for (const Use *Up : uses) {
    const Use &U = *Up;
    auto *I = dyn_cast<Instruction>(U.getUser());
    if (!I || I == P || sh.hoisted.count(I))
      continue;
    bool after;
    if (auto *phi = dyn_cast<PHINode>(I))
      after = isAfter(P, reach, phi->getIncomingBlock(U)->getTerminator());
    else
      // cq-drcl: a user not lowered yet is a lazy reader only when the walk passed it already (it
      // precedes P); one in a block P cannot reach (a sibling arm) is lowered later and reads w's
      // rail where the rotation did not happen (atPhiEdge).
      after = isAfter(P, reach, I) ||
              (!I->getType()->isVoidTy() && !sh.binds.count(I) && precedes(I, P, w));
    if (!after)
      continue;
    if (!first)
      first = I;
    if (!all)
      return first;
    all->push_back(I);
  }
  return first;
}

// Does a phi read w both on an edge after P and on one not after it (atPhiEdge could not tell which rail
// the incoming names)?
bool mixedPhiEdges(Shared &sh, const Value *w, const Instruction *P, const DenseSet<const BasicBlock *> &reach) {
  SmallVector<const Use *, 8> uses;
  readingUses(sh, w, uses);
  for (const Use *U : uses) {
    auto *phi = dyn_cast<PHINode>(U->getUser());
    if (!phi)
      continue;
    bool before = false, after = false;
    for (unsigned i = 0; i < phi->getNumIncomingValues(); ++i)
      if (phi->getIncomingValue(i) == w)
        (isAfter(P, reach, phi->getIncomingBlock(i)->getTerminator()) ? after : before) = true;
    if (before && after)
      return true;
  }
  return false;
}

// The point standing for T in function F: T itself when it is in F (the compiler never inlines, rule 19).
const Instruction *pointIn(Shared &, const Instruction *T, const Function *F) {
  return T->getFunction() == F ? T : nullptr;
}

bool inCycle(const BasicBlock *b) {
  DenseSet<const BasicBlock *> seen;
  SmallVector<const BasicBlock *, 16> work(succ_begin(b), succ_end(b));
  while (!work.empty()) {
    const BasicBlock *x = work.pop_back_val();
    if (x == b)
      return true;
    if (!seen.insert(x).second)
      continue;
    for (const BasicBlock *s : successors(x))
      work.push_back(s);
  }
  return false;
}

// cq-su3p: can the reader I (and the operands it needs that are not lowered yet) be lowered at T,
// before the rotation? Pure scalar opcodes only, outside every cycle, in T's function, on paths where
// T's classical guard held. `order` receives them operands first.
bool hoistable(LoweringContext &ctx, const Instruction &T, const Instruction *I, const Pred &tf,
               SmallVectorImpl<Instruction *> &order, SmallPtrSetImpl<const Instruction *> &seen, unsigned depth) {
  Shared &sh = shared(ctx);
  if (sh.binds.count(I) || sh.hoisted.count(I) || sh.narrowSkipped.count(I) || sh.views.count(I))
    return true;
  if (I == &T || depth > 16 || I->getFunction() != T.getFunction())
    return false;
  if (!seen.insert(I).second)
    return true;
  if (!(isa<BinaryOperator>(I) || isa<CmpInst>(I) || isa<CastInst>(I) || isa<FreezeInst>(I)))
    return false;
  if (!I->getType()->isIntOrIntVectorTy() && !I->getType()->isFloatingPointTy())
    return false;
  if (I->getType()->isVectorTy())
    return false;
  for (const Use &u : I->operands())
    if (!u->getType()->isIntegerTy() && !u->getType()->isFloatingPointTy())
      return false;
  if (inCycle(I->getParent()))
    return false;
  const Pred &p = ctx.preds().block(I->getParent());
  if (!p.isBottom() && !(p.classicalFactor(ctx.T, ctx.S) & !tf).isBottom())
    return false;
  for (const Use &u : I->operands()) {
    const Value *o = u.get();
    if (isa<Constant>(o) || isa<Argument>(o))
      continue;
    auto *oi = dyn_cast<Instruction>(o);
    if (!oi || !hoistable(ctx, T, oi, tf, order, seen, depth + 1))
      return false;
  }
  order.push_back(const_cast<Instruction *>(I));
  return true;
}

// cq-su3p (113's %32): a reader of the register's pre-rotation value through another value bound to h
// or a view of h, which -O1 sank after T, is lowered here, before the rotation (the reference's
// shape), when it is hoistable. The walker skips it when it gets there. No rule 6 for it: the uses
// between T and its original place are not lowered yet.
void hoistReaders(LoweringContext &ctx, CallInst &T, const Value *v, Value *h) {
  Shared &sh = shared(ctx);
  if (T.getFunction() != sh.orig || sh.tripFlag || inCycle(T.getParent()))
    return;
  SmallVector<const Value *, 4> aliases;
  for (auto &[w, ops] : sh.binds)
    if (w != v && w != &T && ops.size() == 1 && ops.front().handle && ops.front().v == h)
      aliases.push_back(w);
  for (auto &[w, vw] : sh.views)
    if (vw.rail == h)
      aliases.push_back(w);
  const BasicBlock *tb = T.getParent();
  const Pred &tp = ctx.preds().block(tb);
  Pred tf = tp.isBottom() ? Pred::bottom() : tp.classicalFactor(ctx.T, ctx.S);
  for (const Value *w : aliases) {
    if (functionOf(w) != T.getFunction())
      continue;
    bool cyc = false;
    DenseSet<const BasicBlock *> r = reachFrom(&T, w, cyc);
    if (cyc)
      continue;
    SmallVector<const Instruction *, 4> readers;
    useAfter(sh, w, &T, r, &readers);
    for (const Instruction *rd : readers) {
      if (isa<PHINode>(rd) || sh.hoisted.count(rd))
        continue;
      SmallVector<Instruction *, 4> order;
      SmallPtrSet<const Instruction *, 8> seen;
      if (!hoistable(ctx, T, rd, tf, order, seen, 0))
        continue;
      for (Instruction *J : order) {
        dispatch(ctx, *J);
        sh.hoisted.insert(J);
        auto bi = sh.binds.find(J);
        if (bi != sh.binds.end() && any_of(bi->second, [](const Operand &o) { return o.handle; }))
          sh.hoistedDefs.push_back(J);
      }
    }
  }
}

// cq-xu07: may p point into obj (an identified object, else anything)?
bool mayPointInto(const Value *p, const Value *obj) {
  const Value *o = getUnderlyingObject(p);
  return o == obj || !isIdentifiedObject(o) || !isIdentifiedObject(obj);
}

// cq-xu07: may the cell the load L read (or a value stored into its object) be read after T?
bool cellReadAfter(Shared &sh, const Instruction &T, const LoadInst &L) {
  const Value *ptr = L.getPointerOperand(), *obj = getUnderlyingObject(ptr);
  const Function *F = T.getFunction();
  bool local = isa<AllocaInst>(obj);
  auto reads = [&](const Instruction &I) {
    if (auto *ld = dyn_cast<LoadInst>(&I))
      return mayPointInto(ld->getPointerOperand(), obj);
    if (isa<ReturnInst>(I))
      return !local;
    if (auto *CB = dyn_cast<CallBase>(&I)) {
      if (CB->isLifetimeStartOrEnd() || isa<DbgInfoIntrinsic>(CB))
        return false;
      if (auto *MI = dyn_cast<MemIntrinsic>(CB))
        return isa<MemTransferInst>(MI) && mayPointInto(cast<MemTransferInst>(MI)->getSource(), obj);
      for (const Value *a : CB->args())
        if (a->getType()->isPointerTy() && mayPointInto(a, obj))
          return true;
      return !local && CB->mayReadFromMemory();
    }
    return false;
  };
  // Paths from T, each ending at a store to the load's own pointer (the cell overwritten).
  SmallPtrSet<const BasicBlock *, 16> seen;
  SmallVector<BasicBlock::const_iterator, 16> work{std::next(T.getIterator())};
  while (!work.empty()) {
    BasicBlock::const_iterator it = work.pop_back_val();
    const BasicBlock *b = it->getParent();
    bool killed = false;
    for (; it != b->end(); ++it) {
      if (auto *st = dyn_cast<StoreInst>(&*it); st && st->getPointerOperand() == ptr) {
        killed = true;
        break;
      }
      if (reads(*it))
        return true;
    }
    if (killed)
      continue;
    for (const BasicBlock *s : successors(b))
      if (seen.insert(s).second)
        work.push_back(s->begin());
  }
  // A quantum value stored into the object, read after T: it may be the cell's rail.
  bool cyc = false;
  DenseSet<const BasicBlock *> reach = reachFrom(&T, nullptr, cyc);
  for (const BasicBlock &b : *F)
    for (const Instruction &I : b) {
      auto *st = dyn_cast<StoreInst>(&I);
      if (!st || st->getValueOperand() == &T || !mayPointInto(st->getPointerOperand(), obj))
        continue;
      const Value *w = st->getValueOperand();
      auto bi = sh.binds.find(w);
      if (bi == sh.binds.end() || none_of(bi->second, [](const Operand &o) { return o.handle; }))
        continue;
      for (const User *u : w->users())
        if (auto *ui = dyn_cast<Instruction>(u); ui && ui != st && ui != &T && isAfter(&T, reach, ui))
          return true;
    }
  return false;
}

// cq-0hhk: is P inside the region of the switch S (reachable from S's block before its immediate
// post-dominator, through which every path leaves the region)?
bool inSwitchRegion(const SwitchInst &S, const Instruction *P) {
  const BasicBlock *sb = S.getParent();
  PostDominatorTree PDT(const_cast<Function &>(*sb->getParent()));
  const BasicBlock *ip = PDT.getNode(sb) && PDT.getNode(sb)->getIDom() ? PDT.getNode(sb)->getIDom()->getBlock() : nullptr;
  DenseSet<const BasicBlock *> seen;
  SmallVector<const BasicBlock *, 16> work(succ_begin(sb), succ_end(sb));
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    if (b == ip || !seen.insert(b).second)
      continue;
    if (b == P->getParent())
      return true;
    for (const BasicBlock *x : successors(b))
      work.push_back(x);
  }
  return false;
}

// cq-0hhk (contract: Switch atoms): the quantum switches whose atoms read h after T get a copy of h
// taken here. Returns the copy (nullptr: none needed). rotateCopy: set, with nothing emitted, when one copy
// at T cannot serve every atom (T inside a cycle where the scrutinee is invariant, or under a classical
// guard the switch's block does not have): the Ry then hits a copy and h keeps the scrutinee's value on
// every path and trip (CR rule 2, f684858: pre-rotation copies per path and trip).
Value *snapshotSwitchAtoms(LoweringContext &ctx, CallInst &T, Value *h, bool &rotateCopy) {
  Shared &sh = shared(ctx);
  SmallVector<const Value *, 4> scrutinees;
  for (auto &[w, ops] : sh.binds)
    if (ops.size() == 1 && ops.front().handle && ops.front().v == h)
      scrutinees.push_back(w);
  for (auto &[w, vw] : sh.views)
    if (vw.rail == h)
      scrutinees.push_back(w);
  auto cf = [&](const BasicBlock *b) {
    const Pred &p = ctx.preds().block(b);
    return p.isBottom() ? Pred::bottom() : p.classicalFactor(ctx.T, ctx.S);
  };
  // The switches whose atoms read h after T (the compiler never inlines, rule 19: T is in the switch's
  // function or no point of it).
  SmallVector<std::pair<const Value *, const SwitchInst *>, 2> hits;
  for (const Value *w : scrutinees)
    for (const User *u : w->users()) {
      auto *S = dyn_cast<SwitchInst>(u);
      if (!S || S->getCondition() != w || !ctx.T.isQuantum(w, ctx.S))
        continue;
      const Instruction *P = pointIn(sh, &T, S->getFunction());
      if (!P || !inSwitchRegion(*S, P))
        continue;
      bool cyc = false;
      reachFrom(&T, w, cyc);
      if (cyc || !(cf(S->getParent()) & !cf(T.getParent())).isBottom()) {
        rotateCopy = true;
        return nullptr;
      }
      hits.push_back({w, S});
    }
  Value *c = nullptr;
  for (auto &[w, S] : hits) {
    {
      if (!c) {
        // A view scrutinee (cq-su3p) names the register's narrow rail h: the copy is of h's width.
        auto vw = sh.views.find(w);
        RailType rw = vw != sh.views.end() ? RailType{Kind::Int, vw->second.bits} : railTypeOf(w->getType());
        c = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, rw}, {Constant::getNullValue(irTypeOf(ctx.M.getContext(), rw))});
        RailId cid = ctx.unc().recordSeed(cast<CallInst>(c));
        abi::CoreSpec cp{abi::Core::Copy, rw};
        CallInst *cc = ctx.emitCore(cp, {h, c});
        ctx.unc().recordCore(cc, cp, {Operand{h, true}, Operand{c, true}}, cid);
      }
      sh.switchSnap[w] = c;
    }
  }
  return c;
}

} // namespace

std::optional<PendingCopy> beginPreRotation(LoweringContext &ctx, CallInst &T, bool uncontrolled) {
  if (T.arg_size() != 2)
    internalError("spine: cq_theta with other than two arguments", &T);
  const Value *v = T.getArgOperand(0);
  if (!isQ(ctx, v))
    return std::nullopt;
  Operand x = ctx.operand(v);
  if (!x.handle)
    return std::nullopt;   // a classical value or a measured rail: the rotation mints its own rail
  Shared &sh = shared(ctx);
  Value *h = x.v;
  // A rotation of a copy: the cell (cq-xu07) or the register (cq-6qum) and every holder of h keep
  // the unrotated rail.
  auto rotateCopy = [&]() {
    RailType w = railTypeOf(v->getType());
    CallInst *c = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                               {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
    RailId cid = ctx.unc().recordSeed(c);
    abi::CoreSpec cp{abi::Core::Copy, w};
    CallInst *cc = ctx.emitCore(cp, {h, c});
    ctx.unc().recordCore(cc, cp, {Operand{h, true}, Operand{c, true}}, cid);
    auto it = sh.binds.find(v);
    if (it == sh.binds.end() || it->second.size() != 1 || it->second.front().v != h)
      internalError("spine: the operand of a cq_theta on a copy is not bound to one rail", &T);
    it->second.assign({Operand{c, true}});
    PendingCopy pc;
    pc.v = v;
    pc.rec.T = &T;
    pc.rec.h = h;
    pc.rec.c = c;
    pc.rotCopy = true;
    return pc;
  };
  // cq-c09h (owner 2026-11-02, C semantics): a by-value formal is a copy. h, the rail a formal of T's
  // function is bound to, is the caller's (a clone's actual): the Ry hits a copy
  // of it, the caller's rail is untouched. A merge that may name a formal's rail at run time would need
  // the copy on some paths only: not built.
  {
    const Function *TF = T.getFunction();
    for (const Argument &A : TF->args()) {
      auto ai = sh.binds.find(&A);
      if (ai == sh.binds.end() || ai->second.size() != 1 || !ai->second.front().handle)
        continue;
      Value *r = ai->second.front().v;
      if (r == h)
        return rotateCopy();
      SmallVector<const Value *, 8> work{h};
      SmallPtrSet<const Value *, 8> seen{h};
      while (!work.empty()) {
        const Value *a = work.pop_back_val();
        SmallVector<const Value *, 2> ins;
        if (auto *p = dyn_cast<PHINode>(a))
          ins.append(p->incoming_values().begin(), p->incoming_values().end());
        else if (auto *sl = dyn_cast<SelectInst>(a))
          ins.append({sl->getTrueValue(), sl->getFalseValue()});
        for (const Value *in : ins) {
          if (in == r)   // the caller's rail on some paths: a copy on every path (C: v keeps its value)
            return rotateCopy();
          if (seen.insert(in).second)
            work.push_back(in);
        }
      }
    }
  }
  if (auto *L = dyn_cast<LoadInst>(v); L && cellReadAfter(sh, T, *L))
    return rotateCopy();   // cq-xu07
  // cq-6qum. v is a rule 10 register state (a prep, a controlled rotation or a merge of them; rot-cry
  // keeps preparing the register's rail h for the C variable v was read from) and rule 2 (or rule 15
  // with a quantum angle, cq-r9j0) rotates it
  // uncontrolled while v is still read after the rotation: in C, v (and the register) keep their
  // value and only the cq_theta's result is rotated. The Ry hits a copy; h stays the register, so a
  // later disjoint prep of it never lands on the rotated rail (w3: r and y would share one rail).
  if (uncontrolled && sh.statePreps.count(v)) {
    bool cyc = false;
    DenseSet<const BasicBlock *> r = reachFrom(&T, v, cyc);
    (void)cyc;   // read after T, or on a later trip of a cycle: either way the copy is rotated
    if (useAfter(sh, v, &T, r))
      return rotateCopy();
  }
  hoistReaders(ctx, T, v, h);

  // A view of h (cq-su3p) read narrow after the rotation reads the pre-rotation copy as its rail (a
  // materialized view's wide readers read its copy taken at the merge).
  SmallVector<const Value *, 2> viewNeeds;
  SmallVector<const Instruction *, 4> readers;   // every reader after T that gets the copy
  for (auto &[w, vw] : sh.views) {
    if (vw.rail != h || functionOf(w) != T.getFunction())
      continue;
    bool cyc = false;
    DenseSet<const BasicBlock *> r = reachFrom(&T, w, cyc);
    SmallVector<const Use *, 8> uses;
    readingUses(sh, w, uses);
    for (const Use *U : uses) {
      auto *I = dyn_cast<Instruction>(U->getUser());
      if (!I || I == &T || sh.hoisted.count(I))
        continue;
      bool after = isa<PHINode>(I) ? isAfter(&T, r, cast<PHINode>(I)->getIncomingBlock(*U)->getTerminator())
                                   : (isAfter(&T, r, I) || (!sh.binds.count(I) && precedes(I, &T, w)));
      if (!after && !cyc)
        continue;
      if (U->getUser() != w && sh.binds.count(w) && !narrowUse(ctx, *U, vw.bits) && U->get() == w)
        continue;   // reads the wide copy
      if (cyc)
        return rotateCopy();   // the view is read on a later trip: h keeps its value, the copy is rotated
      if (!is_contained(viewNeeds, w))
        viewNeeds.push_back(w);
      readers.push_back(I);
    }
  }

  bool switchNeedsCopy = false;
  Value *snap = snapshotSwitchAtoms(ctx, T, h, switchNeedsCopy);   // cq-0hhk
  if (switchNeedsCopy)
    return rotateCopy();

  // Any other value bound to h and read after the rotation reads the pre-rotation copy too (bound to
  // it after the Ry, like the operand). cq-igqp: a value bound to a rail h may name at run time (h a phi
  // or select over handles: a classically bounded loop's header phi names its initial rail on trip 0)
  // would need the copy on the paths where h names it only: the Ry hits a copy of h instead (the C
  // program's own reading: v and every alias keep their value).
  SmallPtrSet<const Value *, 8> aliases;
  {
    SmallVector<const Value *, 8> work{h};
    while (!work.empty()) {
      const Value *a = work.pop_back_val();
      if (auto *p = dyn_cast<PHINode>(a)) {
        for (const Value *in : p->incoming_values())
          if (aliases.insert(in).second)
            work.push_back(in);
      } else if (auto *sl = dyn_cast<SelectInst>(a)) {
        for (const Value *in : {sl->getTrueValue(), sl->getFalseValue()})
          if (aliases.insert(in).second)
            work.push_back(in);
      }
    }
    aliases.erase(h);
  }
  SmallVector<std::pair<const Value *, DenseSet<const BasicBlock *>>, 2> aliasNeeds;
  for (auto &[w, ops] : sh.binds) {
    if (w == v || w == &T || ops.size() != 1 || !ops.front().handle ||
        (ops.front().v != h && !aliases.count(ops.front().v)))
      continue;
    // cq-181j (CR rule 23): eff-fenv binds the MODE or FLAGS rail to a detached probe key (no block, no reader in the
    // IR). The environment holds that rail to the end of the function, so it is read after T: the copy is rotated, the
    // environment keeps its rail (C: `int m = fegetround(); cq_theta(&m, t);` rotates m, never the FPU mode).
    if (auto *wi = dyn_cast<Instruction>(w); wi && !wi->getParent())
      return rotateCopy();
    const Function *F = functionOf(w);
    const Instruction *P = F ? pointIn(sh, &T, F) : nullptr;
    if (!P)
      continue;
    bool cyc = false;
    DenseSet<const BasicBlock *> r = reachFrom(P, w, cyc);
    SmallVector<const Instruction *, 4> rs;
    if (!useAfter(sh, w, P, r, &rs))
      continue;
    if (ops.front().v != h || P != &T)
      return rotateCopy();
    if (cyc || mixedPhiEdges(sh, w, &T, r))
      return rotateCopy();   // read on a later trip, or merged with its unrotated self: copies per trip and path
    readers.append(rs.begin(), rs.end());
    aliasNeeds.push_back({w, std::move(r)});
  }

  bool cyclic = false;
  DenseSet<const BasicBlock *> reach = reachFrom(&T, v, cyclic);
  SmallVector<const Instruction *, 4> vReaders;
  const Instruction *u = useAfter(sh, v, &T, reach, &vReaders);
  if (!u && viewNeeds.empty() && aliasNeeds.empty())
    return std::nullopt;
  // CR rule 2 (f684858, pre-rotation copies per path and trip): v read on a later trip of a cycle around T,
  // or merged by a phi with its unrotated self, keeps h; the Ry hits a copy.
  if (u && (cyclic || mixedPhiEdges(sh, v, &T, reach)))
    return rotateCopy();
  readers.append(vReaders.begin(), vReaders.end());
  // cq-drcl: the copy is emitted at T, so it is available to a reader after T only when every output
  // path to the reader passes T's output block: quantum arms are linearized, a classical branch is
  // not. A reader whose block's classical factor does not imply T's is reached by a path on which T's
  // classical guard failed, where v's value is h unrotated: that needs a merge of c and h at the
  // classical join, which is not built.
  if (T.getFunction() == sh.orig) {
    auto cf = [&](const BasicBlock *b) {
      const Pred &p = ctx.preds().block(b);
      return p.isBottom() ? Pred::bottom() : p.classicalFactor(ctx.T, ctx.S);
    };
    Pred tf = cf(T.getParent());
    // A reader reached by a path on which T's classical guard failed reads h unrotated there: h keeps v's
    // value on every path and the Ry hits a copy (no merge of c and h at the classical join).
    for (const Instruction *r : readers)
      if (!(cf(r->getParent()) & !tf).isBottom())
        return rotateCopy();
  }

  RailType w = railTypeOf(v->getType());
  Value *c = snap && snap->getType() == irTypeOf(ctx.M.getContext(), w) ? snap : nullptr;   // cq-0hhk: one copy
  if (!c) {
    c = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
    RailId cid = ctx.unc().recordSeed(cast<CallInst>(c));
    abi::CoreSpec cp{abi::Core::Copy, w};
    CallInst *cc = ctx.emitCore(cp, {h, c});
    ctx.unc().recordCore(cc, cp, {Operand{h, true}, Operand{c, true}}, cid);
  }

  PendingCopy pc;
  pc.v = u ? v : nullptr;
  pc.rec.T = &T;
  pc.rec.h = h;
  pc.rec.c = c;
  pc.rec.reach = std::move(reach);
  pc.views.assign(viewNeeds.begin(), viewNeeds.end());
  for (auto &[a, r] : aliasNeeds) {
    Shared::PreRot ar = pc.rec;
    ar.reach = std::move(r);
    pc.aliases.push_back({a, std::move(ar)});
  }
  return pc;
}

void finishPreRotation(LoweringContext &ctx, std::optional<PendingCopy> &pc) {
  if (!pc)
    return;
  Shared &sh = shared(ctx);
  auto it = pc->v ? sh.binds.find(pc->v) : sh.binds.end();
  if (pc->rotCopy) {
    if (it == sh.binds.end() || it->second.size() != 1 || it->second.front().v != pc->rec.c)
      internalError("spine: the operand of a cq_theta on a copy changed its binding during the rotation",
                    pc->rec.T);
    it->second.assign({Operand{pc->rec.h, true}});
    pc.reset();
    return;
  }
  // The views and the other values bound to h read the copy after the rotation (each with its own
  // reach for atPhiEdge: a reader the rotation does not reach still reads h).
  for (const Value *w : pc->views)
    sh.views[w].rail = pc->rec.c;
  for (auto &[a, r] : pc->aliases) {
    auto ai = sh.binds.find(a);
    if (ai == sh.binds.end() || ai->second.size() != 1 || ai->second.front().v != pc->rec.h)
      internalError("spine: a value bound to an in-place cq_theta's rail changed its binding during the rotation",
                    pc->rec.T);
    ai->second.assign({Operand{pc->rec.c, true}});
    sh.preRot[a] = std::move(r);
  }
  if (pc->v) {
    if (it == sh.binds.end() || it->second.size() != 1 || it->second.front().v != pc->rec.h)
      internalError("spine: the operand of an in-place cq_theta changed its binding during the rotation", pc->rec.T);
    it->second.assign({Operand{pc->rec.c, true}});
    sh.preRot[pc->v] = std::move(pc->rec);
  }
  pc.reset();
}

Operand atPhiEdge(Shared &sh, const Value *orig, Operand bound) {
  if (!bound.handle)
    return bound;
  auto it = sh.preRot.find(orig);
  if (it == sh.preRot.end() || bound.v != it->second.c)
    return bound;
  const Shared::PreRot &r = it->second;
  if (!sh.cur || sh.cur->getFunction() != r.T->getFunction())
    return bound;
  auto *phi = dyn_cast<PHINode>(sh.cur);
  if (!phi) {
    // cq-drcl: an instruction the rotation does not reach (a sibling arm of the cq_theta, quantum or
    // classical) reads h: on its paths h was not rotated (rule 10's controlled Ry is the identity
    // where its flag is false).
    if (sh.cur != r.T && !isAfter(r.T, r.reach, sh.cur))
      return Operand{r.h, true};
    return bound;
  }
  bool before = false, after = false;
  for (unsigned i = 0; i < phi->getNumIncomingValues(); ++i)
    if (phi->getIncomingValue(i) == orig)
      (isAfter(r.T, r.reach, phi->getIncomingBlock(i)->getTerminator()) ? after : before) = true;
  if (!before)
    return bound;
  if (after)
    internalError("spine: a phi takes " + describe(orig) + " both on edges after an in-place rotation of its rail "
                      "and on edges before it (beginPreRotation rotates a copy then, cq-s32y)",
                  phi);
  return Operand{r.h, true};
}

} // namespace cq::spine
