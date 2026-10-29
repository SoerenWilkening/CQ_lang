// Module loops-classical (cq-w1-loops-classical): CR rule 14, case 1 (classical bound, quantum body)
// and case 3 (classical bound with a quantum exit, `c || q`).
//
// Reference for the reverse replay: BennettVM.jl src/history/Replay.jl:unrun! (a history tape of the
// forward run, replayed last-in-first-out), and Bennett.jl src/bennett_transform.jl:_bennett_default
// (forward, copy-out, every forward gate replayed in reverse order).
//
// CONSTRUCTION. loops::lowerClassical(ctx, L, case) is called by the spine at L's header with the
// builder in a fresh block E (the loop entry; it runs once per activation of the loop).
//
//  Forward. The loop stays a classical loop over fresh output blocks. A quantum header phi becomes a
//  phi over handles (recordExternal, a kept role: it aliases the seed or the previous trip's rail and
//  is never resolved itself); a classical incoming becomes a seed rail allocated in E. The body is
//  walked in reverse post-order: a classical branch stays a classical branch, a quantum branch is
//  linearized (pred's lowerBranch / sw::lowerSwitch, the arms fall through, a quantum join is
//  pred's lowerMerge), a classical join of handles is a phi over handles (recordMerge, U1). Each
//  original non-phi instruction goes through the spine's lowerInstruction. A sub-loop (case 1 or
//  3) is lowered the same way inside its parent's trip, with no copy-out and no mirror of its own:
//  its reverse runs inside the parent's reverse trip (27, 139).
//  Case 3: the trip predicate a_{-1} is the flag of the header's quantum predicate (the loop sits in
//  an arm; the guard test re-rolled, 26) or a |1> seed; the exit test's quantum disjunct q gives
//  a_j = a_{j-1} & NOT q (as a_{j-1} ^ (a_{j-1} & q), for a positive q); every quantum carried value advances by
//  select(a_{j-1}, next, prev); a quantum value read after the loop that is no carried value's next
//  gets its own capture rail cap_j = select(a_{j-1}, v_j, cap_{j-1}); the loop branches on the
//  classical disjuncts only. Every body instruction is lowered under the trip rail a_{j-1}
//  (lowerInstruction's tripFlag, cq-99f7): a cq_theta / cq_phi in the trip is controlled by it. No predicate is kept: the mirror uncomputes every a_j, the last included.
//
//  Segments. Every forward output block is a segment with its own Uncompute scope (sequential, never
//  nested). After the outermost loop exits, each quantum value read after the loop is copied out
//  (alloc + copy, Role::Output) and rebound to the copy; then the reverse runs: one reverse block
//  R(F) per segment F, holding emitMirror(scope of F), whose operands defined in the forward region
//  are replaced by pops; F pushes exactly those values before its terminator (i32 words, a wider
//  value low word first, §1.3), so every classical per-trip value is pushed rather than recomputed.
//  A segment with several predecessors pushes a come-from index first, and R(F) pops it last and
//  goes to the reverse of that predecessor: the reverse replays the forward path backwards (loop
//  headers included: come-from "entry" ends that loop's reverse). The reverse of the entry edge is
//  the block Z, where the seeds allocated in E are released (emitMirror of E's scope); the builder
//  is left at the end of Z, where the loop's exit block continues.
//
// Shapes that are not built yet stop with cq::unimplemented (the instruction printed): a loop with
// more than one exiting block or latch; a case-3 exit test not at the latch, with more than one
// quantum disjunct, or with a sub-loop or a memory write; a classical
// value read after a case-3 loop; calls other than classical, template intrinsics and the CQ.h
// surface; slot / QRAM memory accesses (187, 188: wave 2); a classical branch inside a quantum arm
// of the body; a quantum-exit loop nested in a classically bounded one.
#include "cq/Loops.h"

#include <map>
#include <vector>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Predicate.h"
#include "cq/Switch.h"

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IntrinsicInst.h"

using namespace llvm;

namespace cq::loops {

namespace {

bool samePred(const Pred &a, const Pred &b) { return (a & !b).isBottom() && (b & !a).isBottom(); }

struct Disj {
  const Value *v;
  bool pos;   // the loop exits when v == pos
};

class Unit {
public:
  Unit(LoweringContext &ctx, Loop &top) : ctx(ctx), top(top), F(*top.getHeader()->getParent()) {
    ReversePostOrderTraversal<Function *> rpot(&F);
    for (BasicBlock *b : rpot)
      rpo.push_back(b);
  }

  void run(Case c);

private:
  LoweringContext &ctx;
  Loop &top;
  Function &F;
  std::vector<BasicBlock *> rpo;

  struct Seg {
    BasicBlock *bb;
    unsigned scope;
  };
  std::vector<Seg> segs;
  DenseMap<const BasicBlock *, unsigned> segIdx;
  bool segOpen = false;
  BasicBlock *cur = nullptr;   // the open output block, null after a real branch
  BasicBlock *E = nullptr;     // the outermost loop's entry block (outside the region)
  DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, BasicBlock *> edgeFrom;
  DenseMap<const BasicBlock *, BasicBlock *> obMap;
  std::vector<Value *> externalInits;   // handles defined outside the region read through header phis

  bool isQ(const Value *v) {
    if (isa<Constant>(v) || isa<BasicBlock>(v) || isa<MetadataAsValue>(v))
      return false;
    return ctx.T.isQuantum(v, ctx.S);
  }
  Pred qp(const BasicBlock *b) { return ctx.preds().block(b).quantumPart(ctx.T, ctx.S); }

  BasicBlock *newBlock() { return BasicBlock::Create(ctx.M.getContext(), "", &ctx.out()); }
  BasicBlock *ob(const BasicBlock *b) {
    auto it = obMap.find(b);
    if (it != obMap.end())
      return it->second;
    return obMap[b] = newBlock();
  }

  void closeSeg() {
    if (segOpen)
      ctx.unc().closeScope(segs.back().scope);
    segOpen = false;
  }
  void startSeg(BasicBlock *bb) {
    closeSeg();
    segIdx[bb] = segs.size();
    segs.push_back({bb, ctx.unc().openScope()});
    segOpen = true;
    cur = bb;
    ctx.B().SetInsertPoint(bb);
  }

  Value *seed(Value *classical, RailType w) {
    CallInst *call = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {classical});
    ctx.unc().recordSeed(call);
    return call;
  }
  Value *asHandle(Operand o, Type *ty) {
    if (o.handle)
      return o.v;
    return seed(o.v, railTypeOf(ty));
  }
  Value *select(Value *cond, Operand t, Operand f, RailType w) {
    abi::TemplateSpec spec;
    spec.op = "select";
    spec.w = w;
    std::string shape = std::string(t.handle ? "h" : "l") + (f.handle ? "h" : "l");
    spec.shape = shape == "hh" ? "" : shape;
    return ctx.emitTemplate(spec, {Operand{cond, true}, t, f});
  }
  void gate(abi::Core op, ArrayRef<Value *> args) {
    abi::CoreSpec spec{op, RailType{Kind::Int, 1}};
    CallInst *call = ctx.emitCore(spec, args);
    SmallVector<Operand, 3> ops;
    for (Value *a : args)
      ops.push_back(Operand{a, true});
    ctx.unc().recordCore(call, spec, ops, ctx.unc().idOf(args.back()));
  }

  void check(Loop &L, Case c);
  void disjuncts(const Value *v, bool pos, SmallVectorImpl<Disj> &out, SmallPtrSetImpl<const Value *> &inner);
  // Lowers L with the builder at `cur`; its exit edge goes to T. Returns the exit operand of every
  // value of L read after it (quantum ones only).
  std::vector<std::pair<const Value *, Operand>> lowerLoop(Loop &L, Case c, BasicBlock *T, bool outermost);
  void reverse(BasicBlock *X, unsigned seedScope);
};

void Unit::disjuncts(const Value *c, bool positive, SmallVectorImpl<Disj> &out,
                     SmallPtrSetImpl<const Value *> &inner) {
  const Value *a = nullptr, *b = nullptr;
  bool isOr = false, isAnd = false;
  if (auto *bo = dyn_cast<BinaryOperator>(c); bo && bo->getType()->isIntegerTy(1)) {
    if (bo->getOpcode() == Instruction::Or) { isOr = true; a = bo->getOperand(0); b = bo->getOperand(1); }
    if (bo->getOpcode() == Instruction::And) { isAnd = true; a = bo->getOperand(0); b = bo->getOperand(1); }
  } else if (auto *sel = dyn_cast<SelectInst>(c); sel && sel->getType()->isIntegerTy(1)) {
    if (auto *k = dyn_cast<ConstantInt>(sel->getTrueValue()); k && k->isOne()) {
      isOr = true; a = sel->getCondition(); b = sel->getFalseValue();
    } else if (auto *k2 = dyn_cast<ConstantInt>(sel->getFalseValue()); k2 && k2->isZero()) {
      isAnd = true; a = sel->getCondition(); b = sel->getTrueValue();
    }
  }
  if ((isOr && positive) || (isAnd && !positive)) {
    inner.insert(c);
    disjuncts(a, positive, out, inner);
    disjuncts(b, positive, out, inner);
    return;
  }
  out.push_back({c, positive});
}

void Unit::check(Loop &L, Case c) {
  if (!L.getLoopPredecessor())
    unimplemented("loops-classical: a rule-14 loop whose header has more than one predecessor outside the loop",
                  L.getHeader()->getTerminator());
  if (!L.getLoopLatch())
    unimplemented("loops-classical: a rule-14 loop with more than one latch", L.getHeader()->getTerminator());
  if (!L.getExitingBlock() || !L.getExitBlock())
    unimplemented("loops-classical: a rule-14 loop with more than one exiting block or exit block",
                  L.getHeader()->getTerminator());
  for (PHINode &p : L.getHeader()->phis())
    if (isQ(&p) && !(p.getType()->isIntegerTy() || p.getType()->isFloatingPointTy()))
      unimplemented("loops-classical: a quantum carried value of non-scalar type (aggr, fatptr)", &p);
  if (c == Case::ClassicalBoundQuantumExit) {
    if (L.getExitingBlock() != L.getLoopLatch())
      unimplemented("loops-classical: a quantum exit test that is not the latch's (rule 14 case 3)",
                    L.getExitingBlock()->getTerminator());
    if (!L.getSubLoops().empty())
      unimplemented("loops-classical: a loop nested in a case-3 loop (the inner chain seeded by the outer trip "
                    "predicate)",
                    L.getHeader()->getTerminator());
  }
  for (BasicBlock *b : L.blocks())
    for (Instruction &I : *b) {
      if (isa<DbgInfoIntrinsic>(I))
        continue;
      if (c == Case::ClassicalBoundQuantumExit && I.mayWriteToMemory() && !isa<CallBase>(I))
        unimplemented("loops-classical: a memory write in a case-3 loop (under the trip rail: loops-mem)", &I);
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        calls::Class k = calls::classify(*CB, ctx.T, ctx.S);
        switch (k) {
        case calls::Class::Classical:
        case calls::Class::TemplateIntrinsic:
          break;
        case calls::Class::Theta:
        case calls::Class::Measure:
        case calls::Class::Phi:
          break;   // case 3: under the trip rail (lowerInstruction's tripFlag, cq-99f7)
        default:
          unimplemented("loops-classical: a call of this class inside a rule-14 loop (calls-loops / loops-mem "
                        "integration)",
                        &I);
        }
        continue;
      }
      if (auto *st = dyn_cast<StoreInst>(&I)) {
        bool q = isQ(st->getValueOperand()) || isQ(st->getPointerOperand()) ||
                 ctx.T.isFatPointer(st->getPointerOperand(), ctx.S);
        for (ObjectId o : ctx.T.provenance(st->getPointerOperand(), ctx.S))
          q |= ctx.T.classOf(o) != ObjClass::Classical;
        if (q)
          unimplemented("loops-classical: a store into slot / QRAM memory in a classically bounded loop (rule 14, "
                        "187, 188: loops-mem)",
                        &I);
        continue;
      }
      if (auto *ld = dyn_cast<LoadInst>(&I)) {
        bool q = ctx.T.isFatPointer(ld->getPointerOperand(), ctx.S);
        for (ObjectId o : ctx.T.provenance(ld->getPointerOperand(), ctx.S))
          q |= ctx.T.classOf(o) != ObjClass::Classical;
        if (q)
          unimplemented("loops-classical: a load of slot / QRAM memory in a classically bounded loop (loops-mem)",
                        &I);
        continue;
      }
      if (I.mayWriteToMemory() && (isQ(&I) || any_of(I.operands(), [&](const Use &u) { return isQ(u.get()); })))
        unimplemented("loops-classical: a quantum memory effect in a classically bounded loop", &I);
      if (isa<ReturnInst>(I) || isa<UnreachableInst>(I) || isa<IndirectBrInst>(I) || isa<CallBrInst>(I) ||
          isa<InvokeInst>(I))
        unimplemented("loops-classical: a loop body terminator of this kind", &I);
    }
}

std::vector<std::pair<const Value *, Operand>> Unit::lowerLoop(Loop &L, Case c, BasicBlock *T, bool outermost) {
  check(L, c);
  const bool c3 = c == Case::ClassicalBoundQuantumExit;
  BasicBlock *header = L.getHeader(), *pre = L.getLoopPredecessor(), *latch = L.getLoopLatch();
  BasicBlock *exitB = L.getExitBlock();

  // Values of L read after it.
  std::vector<const Instruction *> liveOut;
  for (BasicBlock *b : L.blocks())
    for (Instruction &I : *b)
      for (const User *u : I.users())
        if (auto *ui = dyn_cast<Instruction>(u); ui && !L.contains(ui)) {
          liveOut.push_back(&I);
          break;
        }

  // Case 3: the exit test.
  SmallVector<Disj, 4> ds;
  SmallPtrSet<const Value *, 8> skip;
  const Value *qLeaf = nullptr;
  bool qPos = false;
  if (c3) {
    auto *br = dyn_cast<BranchInst>(latch->getTerminator());
    if (!br || !br->isConditional() || !isQ(br->getCondition()))
      internalError("loops-classical: a case-3 loop whose latch is no quantum conditional branch",
                    latch->getTerminator());
    bool exitOnTrue = !L.contains(br->getSuccessor(0));
    disjuncts(br->getCondition(), exitOnTrue, ds, skip);
    bool anyClassical = false;
    for (const Disj &d : ds) {
      if (!isQ(d.v)) {
        anyClassical = true;
        continue;
      }
      if (qLeaf)
        unimplemented("loops-classical: a case-3 exit test with more than one quantum disjunct", br);
      qLeaf = d.v;
      qPos = d.pos;
    }
    if (!anyClassical || !qLeaf)
      internalError("loops-classical: a case-3 exit test without a classical and a quantum disjunct", br);
    // An inner node of the test is not lowered when nothing but the test reads it.
    for (bool changed = true; changed;) {
      changed = false;
      for (const Value *n : SmallVector<const Value *, 8>(skip.begin(), skip.end()))
        for (const User *u : n->users())
          if (u != br && !skip.count(u)) {
            skip.erase(n);
            changed = true;
            break;
          }
    }
    for (const Instruction *v : liveOut)
      if (!isQ(v))
        unimplemented("loops-classical: a classical value read after a case-3 loop (its exit value depends on the "
                      "quantum exit)",
                      v);
  }

  // Entry: the trip predicate, the seeds.
  unsigned seedScope = 0;
  Value *aInit = nullptr;
  if (outermost)
    seedScope = ctx.unc().openScope();
  // a_{-1} is minted inside the outermost loop's seed scope, so Z tears it down after the reverse (cq-t71u): under
  // a classical guard its definition does not dominate the return and no exit flush could free it. An atom rail
  // flag() returns has no record in the scope and is untouched.
  if (c3) {
    Pred hp = qp(header);
    if (!hp.isTop())
      aInit = ctx.preds().flag(ctx, hp);
  }
  if (c3 && !aInit)
    aInit = seed(ConstantInt::getTrue(ctx.M.getContext()), RailType{Kind::Int, 1});
  else if (aInit && outermost)
    externalInits.push_back(aInit);
  BasicBlock *entryFrom = cur;
  struct Carried {
    PHINode *orig;
    PHINode *np;
    bool q;
  };
  std::vector<Carried> carried;
  std::vector<std::pair<Value *, bool>> inits;
  for (PHINode &p : header->phis()) {
    Operand o = ctx.operand(p.getIncomingValueForBlock(pre));
    bool q = isQ(&p);
    if (q) {
      Value *h = asHandle(o, p.getType());
      if (o.handle && outermost)
        externalInits.push_back(h);
      inits.push_back({h, true});
    } else {
      if (o.handle)
        internalError("loops-classical: a classical carried value with a rail as its initial value", &p);
      inits.push_back({o.v, false});
    }
  }
  // Case 3: capture rails for values read after the loop that are no carried value's next.
  std::vector<std::pair<const Instruction *, PHINode *>> caps;
  std::vector<Value *> capInits;
  DenseMap<const Value *, PHINode *> nextOf;   // a carried value's next -> its header phi (orig)
  if (c3) {
    for (PHINode &p : header->phis())
      if (isQ(&p))
        nextOf[p.getIncomingValueForBlock(latch)] = &p;
    for (const Instruction *v : liveOut)
      if (!nextOf.count(v)) {
        if (!(v->getType()->isIntegerTy() || v->getType()->isFloatingPointTy()))
          unimplemented("loops-classical: a non-scalar value read after a case-3 loop", v);
        RailType w = railTypeOf(v->getType());
        capInits.push_back(seed(Constant::getNullValue(irTypeOf(ctx.M.getContext(), w)), w));
      }
  }
  BasicBlock *H = newBlock();
  ctx.B().CreateBr(H);
  if (outermost) {
    ctx.unc().closeScope(seedScope);
    segOpen = false;
  }
  startSeg(H);
  {
    unsigned k = 0;
    for (PHINode &p : header->phis()) {
      auto [v, q] = inits[k++];
      PHINode *np = ctx.B().CreatePHI(q ? handleTy(ctx.M.getContext()) : p.getType(), 2, p.getName());
      np->addIncoming(v, entryFrom);
      if (q)
        ctx.unc().recordExternal(np, Role::UserRegister);
      ctx.bind(&p, np);
      carried.push_back({&p, np, q});
    }
  }
  PHINode *aPhi = nullptr;
  if (c3) {
    aPhi = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), 2, "trip");
    aPhi->addIncoming(aInit, entryFrom);
    ctx.unc().recordExternal(aPhi, Role::UserRegister);
    unsigned k = 0;
    for (const Instruction *v : liveOut)
      if (!nextOf.count(v)) {
        PHINode *cp = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), 2, "cap");
        cp->addIncoming(capInits[k++], entryFrom);
        ctx.unc().recordExternal(cp, Role::UserRegister);
        caps.push_back({v, cp});
      }
  }

  // The body walk.
  const Pred hq = qp(header);
  auto armed = [&](const BasicBlock *u) { return !samePred(qp(u), hq); };
  auto subOf = [&](const BasicBlock *b) -> Loop * {
    for (Loop *s : L.getSubLoops())
      if (s->contains(b))
        return s;
    return nullptr;
  };
  auto fwdPreds = [&](const BasicBlock *s) {
    SmallVector<const BasicBlock *, 4> ps;
    Loop *sl = subOf(s);
    for (const BasicBlock *p : predecessors(s))
      if (!(sl && sl->contains(p)) && !is_contained(ps, p))
        ps.push_back(p);
    return ps;
  };
  enum class EK { Linear, Merge, Real };
  auto termQ = [&](const Instruction *t) {
    if (auto *br = dyn_cast<BranchInst>(t))
      return br->isConditional() && isQ(br->getCondition());
    if (auto *sw = dyn_cast<SwitchInst>(t))
      return isQ(sw->getCondition());
    return false;
  };
  auto edgeKind = [&](const BasicBlock *u, const BasicBlock *s) {
    if (subOf(u))
      return EK::Real;   // a sub-loop always ends in a real branch
    const Instruction *t = u->getTerminator();
    if (termQ(t))
      return EK::Linear;
    if (auto *br = dyn_cast<BranchInst>(t); br && !br->isConditional()) {
      if (armed(u))
        return EK::Linear;
      return fwdPreds(s).size() == 1 ? EK::Merge : EK::Real;
    }
    return EK::Real;
  };
  auto target = [&](const BasicBlock *s) -> BasicBlock * {
    if (s == header)
      return H;
    if (!L.contains(s))
      return T;
    return ob(s);
  };

  // Next values of the carried phis, computed at the latch before its terminator.
  std::vector<Value *> nexts;
  auto latchNexts = [&]() {
    for (Carried &cv : carried) {
      Operand o = ctx.operand(cv.orig->getIncomingValueForBlock(latch));
      if (!cv.q) {
        if (o.handle)
          internalError("loops-classical: a classical carried value whose next is a rail", cv.orig);
        nexts.push_back(o.v);
      } else if (c3) {
        nexts.push_back(select(aPhi, o, Operand{cv.np, true}, railTypeOf(cv.orig->getType())));
      } else {
        nexts.push_back(asHandle(o, cv.orig->getType()));
      }
    }
    for (auto &[v, cp] : caps)
      cp->addIncoming(select(aPhi, ctx.operand(v), Operand{cp, true}, railTypeOf(v->getType())), cur);
  };

  auto emitPhis = [&](BasicBlock *b, bool real) {
    for (PHINode &p : b->phis()) {
      bool q = isQ(&p);
      if (p.getNumIncomingValues() == 1 || all_of(p.incoming_values(), [&](const Value *v) {
            return v == p.getIncomingValue(0);
          })) {
        Operand o = ctx.operand(p.getIncomingValue(0));
        ctx.bind(&p, q ? asHandle(o, p.getType()) : o.v);
        continue;
      }
      if (!real) {
        if (!q)
          internalError("loops-classical: a classical phi at a linearized join", &p);
        ctx.bind(&p, lowerMerge(ctx, p));
        continue;
      }
      if (q && !(p.getType()->isIntegerTy() || p.getType()->isFloatingPointTy()))
        unimplemented("loops-classical: a non-scalar phi of handles", &p);
      PHINode *np = PHINode::Create(q ? handleTy(ctx.M.getContext()) : p.getType(), p.getNumIncomingValues(),
                                    p.getName());
      np->insertInto(ob(b), ob(b)->getFirstNonPHIIt());
      SmallPtrSet<BasicBlock *, 4> from;
      for (unsigned i = 0; i < p.getNumIncomingValues(); ++i) {
        BasicBlock *u = p.getIncomingBlock(i);
        auto it = edgeFrom.find({u, b});
        if (it == edgeFrom.end())
          internalError("loops-classical: a join edge with no output block", &p);
        if (!from.insert(it->second).second)
          unimplemented("loops-classical: two edges of a classical join leave one output block", &p);
        Operand o = ctx.operand(p.getIncomingValue(i));
        if (q && !o.handle)
          unimplemented("loops-classical: a classical incoming of a phi of handles inside the loop body", &p);
        if (!q && o.handle)
          internalError("loops-classical: a classical phi with a rail incoming", &p);
        np->addIncoming(o.v, it->second);
      }
      if (q)
        ctx.unc().recordMerge(np);
      ctx.bind(&p, np);
    }
  };

  auto emitTerminator = [&](BasicBlock *u) {
    Instruction *t = u->getTerminator();
    if (u == latch)
      latchNexts();
    if (c3 && u == latch) {
      IRBuilder<> &B = ctx.B();
      Value *cExit = nullptr;
      for (const Disj &d : ds) {
        if (isQ(d.v))
          continue;
        Operand o = ctx.operand(d.v);
        if (o.handle)
          internalError("loops-classical: a classical exit disjunct that is a rail", d.v);
        Value *x = d.pos ? o.v : B.CreateNot(o.v);
        cExit = cExit ? B.CreateOr(cExit, x) : x;
      }
      Value *q = ctx.rail(qLeaf);
      Value *a = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
      // a = a_prev & q, or a_prev & NOT q = a_prev ^ (a_prev & q): gates on a alone, so the mirror's
      // undo of a reads q in the state the forward read it (no bracket on q).
      if (qPos)
        gate(abi::Core::XorI1, {aPhi, a});
      gate(abi::Core::AndI1, {aPhi, q, a});
      aPhi->addIncoming(a, cur);
      B.CreateCondBr(cExit, T, H);
      edgeFrom[{u, exitB}] = cur;
      edgeFrom[{u, header}] = cur;
      cur = nullptr;
      return;
    }
    if (auto *br = dyn_cast<BranchInst>(t)) {
      if (!br->isConditional()) {
        BasicBlock *s = br->getSuccessor(0);
        EK k = (s == header || !L.contains(s)) ? EK::Real : edgeKind(u, s);
        edgeFrom[{u, s}] = cur;
        if (k != EK::Real)
          return;
        ctx.B().CreateBr(target(s));
        cur = nullptr;
        return;
      }
      if (termQ(t)) {
        for (BasicBlock *s : successors(u))
          if (s == header || !L.contains(s))
            unimplemented("loops-classical: a quantum branch leaving the trip that is not a case-3 latch test", t);
        lowerBranch(ctx, *br);
        for (BasicBlock *s : successors(u))
          edgeFrom[{u, s}] = cur;
        return;
      }
      if (armed(u))
        unimplemented("loops-classical: a classical branch inside a quantum arm of a loop body", t);
      Operand cnd = ctx.operand(br->getCondition());
      if (cnd.handle)
        internalError("loops-classical: a classical branch on a rail", t);
      ctx.B().CreateCondBr(cnd.v, target(br->getSuccessor(0)), target(br->getSuccessor(1)));
      for (BasicBlock *s : successors(u))
        edgeFrom[{u, s}] = cur;
      cur = nullptr;
      return;
    }
    if (auto *sw = dyn_cast<SwitchInst>(t)) {
      if (termQ(t)) {
        for (BasicBlock *s : successors(u))
          if (s == header || !L.contains(s))
            unimplemented("loops-classical: a quantum switch leaving the trip", t);
        sw::lowerSwitch(ctx, *sw);
        for (BasicBlock *s : successors(u))
          edgeFrom[{u, s}] = cur;
        return;
      }
      if (armed(u))
        unimplemented("loops-classical: a classical switch inside a quantum arm of a loop body", t);
      Operand cnd = ctx.operand(sw->getCondition());
      if (cnd.handle)
        internalError("loops-classical: a classical switch on a rail", t);
      SwitchInst *ns = ctx.B().CreateSwitch(cnd.v, target(sw->getDefaultDest()), sw->getNumCases());
      for (auto &cs : sw->cases())
        ns->addCase(cs.getCaseValue(), target(cs.getCaseSuccessor()));
      for (BasicBlock *s : successors(u))
        edgeFrom[{u, s}] = cur;
      cur = nullptr;
      return;
    }
    unimplemented("loops-classical: a loop body terminator of this kind", t);
  };

  auto emitInstructions = [&](BasicBlock *b) {
    for (Instruction &I : *b) {
      if (isa<PHINode>(I) || I.isTerminator() || skip.count(&I))
        continue;
      lowerInstruction(ctx, I, aPhi);   // case 3: the body runs under a_{j-1}; case 1: no trip rail
    }
  };

  // The header (its phis are the carried values above).
  emitInstructions(header);
  emitTerminator(header);
  for (BasicBlock *b : rpo) {
    if (b == header || !L.contains(b))
      continue;
    Loop *sl = subOf(b);
    if (sl && sl->getHeader() != b)
      continue;
    SmallVector<const BasicBlock *, 4> ps = fwdPreds(b);
    bool anyReal = false, anyLin = false;
    for (const BasicBlock *p : ps)
      (edgeKind(p, b) == EK::Real ? anyReal : anyLin) = true;
    if (anyReal && anyLin)
      unimplemented("loops-classical: a block reached both by a classical branch and by a linearized arm",
                    &*b->begin());
    if (anyReal) {
      if (cur)
        unimplemented("loops-classical: a classical join reached while a quantum arm of the body is open",
                      &*b->begin());
      startSeg(ob(b));
    } else if (!cur) {
      unimplemented("loops-classical: a linearized block after the walk left its arm (body block order)",
                    &*b->begin());
    }
    if (sl) {
      Case sc = classify(*sl, ctx.T, ctx.S);
      if (sc == Case::QuantumExit)
        unimplemented("loops-classical: a quantum-exit loop nested in a classically bounded loop (loops-cutoff)",
                      sl->getHeader()->getTerminator());
      BasicBlock *sx = sl->getExitBlock();
      if (!sx || !L.contains(sx))
        unimplemented("loops-classical: a sub-loop that leaves its parent loop", sl->getHeader()->getTerminator());
      for (auto &[v, op] : lowerLoop(*sl, sc, ob(sx), false))
        ctx.rebind(v, {op});
      continue;
    }
    emitPhis(b, anyReal);
    emitInstructions(b);
    emitTerminator(b);
  }
  if (cur)
    internalError("loops-classical: the trip walk ended with an open block", latch->getTerminator());

  // Back edges.
  {
    auto it = edgeFrom.find({latch, header});
    if (it == edgeFrom.end())
      internalError("loops-classical: no back edge out of the latch", latch->getTerminator());
    for (unsigned k = 0; k < carried.size(); ++k)
      carried[k].np->addIncoming(nexts[k], it->second);
  }
  closeSeg();

  // Exit values of the values read after the loop.
  std::vector<std::pair<const Value *, Operand>> out;
  for (const Instruction *v : liveOut) {
    if (!isQ(v))
      continue;
    if (c3) {
      if (auto n = nextOf.find(v); n != nextOf.end()) {
        unsigned k = 0;
        while (carried[k].orig != n->second)
          ++k;
        out.push_back({v, Operand{nexts[k], true}});
      } else {
        for (auto &[cv, cp] : caps)
          if (cv == v)
            out.push_back({v, Operand{cp->getIncomingValueForBlock(edgeFrom[{latch, header}]), true}});
      }
    } else {
      out.push_back({v, ctx.operand(v)});
    }
  }
  if (outermost) {
    ctx.B().SetInsertPoint(T);
    for (auto &[v, op] : out) {
      RailType w = railTypeOf(v->getType());
      if (!op.handle)
        internalError("loops-classical: a quantum value read after the loop whose exit value is classical", v);
      CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                 {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
      RailId fid = ctx.unc().recordSeed(f);
      abi::CoreSpec cp{abi::Core::Copy, w};
      CallInst *cc = ctx.emitCore(cp, {op.v, f});
      ctx.unc().recordCore(cc, cp, {op, Operand{f, true}}, fid);
      ctx.unc().setRole(fid, Role::Output);
      ctx.rebind(v, {Operand{f, true}});
    }
    reverse(T, seedScope);
    return {};
  }
  return out;
}

// ---- the reverse --------------------------------------------------------------------------------

unsigned wordsOf(Type *t, const Value *at) {
  if (auto *it = dyn_cast<IntegerType>(t))
    return (it->getBitWidth() + 31) / 32;
  if (t->isHalfTy() || t->isBFloatTy() || t->isFloatTy())
    return 1;
  if (t->isDoubleTy() || t->isPointerTy())
    return 2;
  if (t->isX86_FP80Ty())
    return 3;
  if (t->isFP128Ty())
    return 4;
  unimplemented("loops-classical: a per-trip value of this type on the push/pop stack", at);
}

Value *toInt(IRBuilder<> &B, Value *v) {
  Type *t = v->getType();
  if (t->isIntegerTy())
    return v;
  if (t->isPointerTy())
    return B.CreatePtrToInt(v, B.getInt64Ty());
  return B.CreateBitCast(v, B.getIntNTy(t->getPrimitiveSizeInBits()));
}

Value *fromInt(IRBuilder<> &B, Value *x, Type *t) {
  if (t->isIntegerTy())
    return x;
  if (t->isPointerTy())
    return B.CreateIntToPtr(x, t);
  return B.CreateBitCast(x, t);
}

void Unit::reverse(BasicBlock *X, unsigned seedScope) {
  Module &M = ctx.M;
  LLVMContext &C = M.getContext();
  FunctionCallee push = abi::declare(M, abi::CoreSpec{abi::Core::Push});
  FunctionCallee pop = abi::declare(M, abi::CoreSpec{abi::Core::Pop});
  IntegerType *i32 = Type::getInt32Ty(C);
  const unsigned n = segs.size();
  DenseSet<const BasicBlock *> region;
  for (const Seg &s : segs)
    region.insert(s.bb);

  // Forward dominance over the region (the entry E outside it is the root).
  std::vector<BitVector> dom(n, BitVector(n, true));
  {
    bool changed = true;
    while (changed) {
      changed = false;
      for (unsigned i = 0; i < n; ++i) {
        BitVector d(n, true);
        bool anyPred = false;
        for (BasicBlock *p : predecessors(segs[i].bb)) {
          anyPred = true;
          if (region.count(p))
            d &= dom[segIdx.lookup(p)];
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

  BasicBlock *Z = newBlock();
  std::vector<BasicBlock *> R(n);
  for (unsigned i = 0; i < n; ++i)
    R[i] = newBlock();
  Instruction *anchor = nullptr;   // a reverse instruction for the uses of the external initial rails

  for (unsigned i = n; i-- > 0;) {
    IRBuilder<> B(R[i]);
    ctx.unc().emitMirror(segs[i].scope, B);
    std::vector<Instruction *> mirror;
    for (Instruction &I : *R[i])
      mirror.push_back(&I);
    // The forward values the mirror reads: popped here, pushed at the end of the segment.
    std::vector<Value *> needs;
    for (Instruction *I : mirror)
      for (Use &u : I->operands())
        if (auto *d = dyn_cast<Instruction>(u.get()); d && region.count(d->getParent()) && !is_contained(needs, d)) {
          if (!dom[i].test(segIdx.lookup(d->getParent())))
            internalError("loops-classical: a mirror item reads a value defined in a segment that does not dominate "
                          "its own",
                          d);
          needs.push_back(d);
        }
    DenseMap<Value *, Value *> popped;
    {
      IRBuilder<> P(R[i], R[i]->begin());
      for (unsigned k = needs.size(); k-- > 0;) {
        Value *v = needs[k];
        unsigned w = wordsOf(v->getType(), v);
        if (v->getType() == i32) {
          popped[v] = P.CreateCall(pop);
          continue;
        }
        IntegerType *wide = Type::getIntNTy(C, 32 * w);
        Value *x = ConstantInt::get(wide, 0);
        for (unsigned j = w; j-- > 0;) {
          Value *word = P.CreateZExt(P.CreateCall(pop), wide);
          x = P.CreateOr(x, j ? P.CreateShl(word, 32 * j) : word);
        }
        Type *t = v->getType();
        unsigned bits = t->isIntegerTy() ? t->getIntegerBitWidth()
                        : t->isPointerTy() ? 64
                                           : unsigned(t->getPrimitiveSizeInBits());
        popped[v] = fromInt(P, P.CreateTrunc(x, Type::getIntNTy(C, bits)), t);
      }
    }
    for (Instruction *I : mirror)
      for (Use &u : I->operands())
        if (auto it = popped.find(u.get()); it != popped.end())
          u.set(it->second);
    {
      IRBuilder<> Pu(segs[i].bb->getTerminator());
      for (Value *v : needs) {
        if (v->getType() == i32) {
          Pu.CreateCall(push, {v});
          continue;
        }
        unsigned w = wordsOf(v->getType(), v);
        Value *x = Pu.CreateZExt(toInt(Pu, v), Type::getIntNTy(C, 32 * w));
        for (unsigned j = 0; j < w; ++j)
          Pu.CreateCall(push, {Pu.CreateTrunc(j ? Pu.CreateLShr(x, 32 * j) : x, i32)});
      }
    }
    // Where the reverse goes next: the reverse of the forward predecessor.
    SmallVector<BasicBlock *, 4> uniq;
    for (BasicBlock *p : predecessors(segs[i].bb))
      if (!is_contained(uniq, p))
        uniq.push_back(p);
    auto back = [&](BasicBlock *p) { return region.count(p) ? R[segIdx.lookup(p)] : Z; };
    if (uniq.size() == 1) {
      B.CreateBr(back(uniq[0]));
      continue;
    }
    PHINode *cf = PHINode::Create(i32, pred_size(segs[i].bb), "from");
    cf->insertInto(segs[i].bb, segs[i].bb->begin());
    for (BasicBlock *p : predecessors(segs[i].bb))
      cf->addIncoming(ConstantInt::get(i32, find(uniq, p) - uniq.begin()), p);
    IRBuilder<>(segs[i].bb, segs[i].bb->getFirstInsertionPt()).CreateCall(push, {cf});
    CallInst *k = B.CreateCall(pop);
    if (!anchor && any_of(uniq, [&](BasicBlock *p) { return !region.count(p); }))
      anchor = k;
    SwitchInst *sw = B.CreateSwitch(k, back(uniq[0]), uniq.size() - 1);
    for (unsigned j = 1; j < uniq.size(); ++j)
      sw->addCase(ConstantInt::get(i32, j), back(uniq[j]));
  }

  // The reverse starts at the reverse of the segment that exits.
  {
    BasicBlock *exitSeg = nullptr;
    for (BasicBlock *p : predecessors(X)) {
      if (!region.count(p) || (exitSeg && exitSeg != p))
        internalError("loops-classical: the loop's exit block is not reached from exactly one segment");
      exitSeg = p;
    }
    IRBuilder<>(X).CreateBr(R[segIdx.lookup(exitSeg)]);
  }
  if (!anchor && !externalInits.empty())
    internalError("loops-classical: no reverse instruction reads the loop's initial rails");
  for (Value *h : externalInits)
    ctx.unc().noteUse(ctx.unc().idOf(h), anchor);
  IRBuilder<> BZ(Z);
  ctx.unc().emitMirror(seedScope, BZ);
  ctx.B().SetInsertPoint(Z);
}

void Unit::run(Case c) {
  E = ctx.B().GetInsertBlock();
  cur = E;
  BasicBlock *X = newBlock();
  lowerLoop(top, c, X, true);
}

} // namespace

void lowerClassical(LoweringContext &ctx, Loop &L, Case c) {
  if (c == Case::QuantumExit)
    internalError("loops-classical: lowerClassical of a quantum-exit loop (loops-cutoff)", L.getHeader()->getTerminator());
  Unit(ctx, L).run(c);
}

} // namespace cq::loops
