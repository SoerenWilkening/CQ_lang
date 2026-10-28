// Module spine (cq-w0-construct): construct(), the general construction for one specialization
// (cq-arch "construct()"). Contract of LoweringContext and of the walk: SpineInternal.h.
//
// Output function. An entry function keeps its C signature and is rewritten in place (rule 1: its
// formals stay classical, a quantum value it returns is the handle, §1.1 / 162). Its new body is
// built in a temporary function and moved into it once every specialization of the module is
// constructed, so that every construct() of the run reads original bodies only (a later clone, or
// a rule 19 inline of the entry, reads the original). A clone is made by calls::materialize.
//
// Walk. The original blocks are visited in one reverse post-order L. A loop that is not purely
// classical is dispatched as a unit at its header (rule 14). Every other block is lowered
// instruction by instruction under its block predicate. A br or switch on a quantum condition emits
// no control flow: both arms run, linearized along L, each under its predicate (rules 8, 9, 13).
// A classical terminator stays a classical branch; its edge to s is redirected to next(x, s): the
// first block y after x in L with y == s, or y not reachable from x whose nearest common dominator
// with x ends in a quantum terminator (y heads a quantum arm still to run). A quantum terminator
// falls through to the first such y that is a successor or an arm head.
//
// Classical guards (rule 8 at CQ_spec a46894a, P1). A block's predicate is classicalFactor &
// quantumPart. The factor stays a classical branch: the walker tracks, per block, the classical facts
// every output path into it establishes (the classical factors of the real classical edges taken),
// and where the factor is not yet established it emits `br <missing literals>, block, skip` at the
// block's start, skip being the first later block that may run when the guard is false. The literals
// are branch-condition terms of the function (a classical condition, a classical term of a quantum
// condition, a classical switch case), chosen by implication on pred's predicates; the factoring
// itself is pred's.
#include "SpineInternal.h"

#include "cq/Effects.h"
#include "cq/Switch.h"

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/TargetParser/Triple.h"

using namespace llvm;

namespace cq {

namespace {

struct PendingEntry {
  Function *F, *NF;
};
thread_local std::map<const Module *, std::vector<PendingEntry>> pendingEntries;

// Move each lowered entry body into its function. The original bodies are dropped here, after the
// last construct() of the module, when nothing reads them any more.
void finishEntries(Module &M) {
  auto it = pendingEntries.find(&M);
  if (it == pendingEntries.end())
    return;
  for (PendingEntry &p : it->second) {
    Function &F = *p.F, &NF = *p.NF;
    for (BasicBlock &BB : F)
      BB.dropAllReferences();
    while (!F.empty())
      F.begin()->eraseFromParent();
    F.splice(F.end(), &NF);
    for (unsigned i = 0; i < F.arg_size(); ++i) {
      NF.getArg(i)->replaceAllUsesWith(F.getArg(i));
      if (F.getArg(i)->getName().empty())
        F.getArg(i)->takeName(NF.getArg(i));
    }
    NF.replaceAllUsesWith(&F);
    NF.eraseFromParent();
  }
  pendingEntries.erase(it);
}

// The CQ.h surface is consumed by the lowering; its declarations with no use left are dropped.
void dropDeadSurface(Module &M) {
  SmallVector<Function *, 8> dead;
  for (Function &F : M) {
    StringRef n = F.getName();
    bool surface = n.starts_with("cq_theta_") || n.starts_with("cq_measure_") || n == "cq_phi" ||
                   n == "__cq_invert_begin" || n == "__cq_invert_end";
    if (surface && F.isDeclaration() && F.use_empty())
      dead.push_back(&F);
  }
  for (Function *F : dead)
    F->eraseFromParent();
}

bool isQuantumTerm(LoweringContext &ctx, const Instruction *t) {
  if (auto *br = dyn_cast<BranchInst>(t))
    return br->isConditional() && spine::isQ(ctx, br->getCondition());
  if (auto *sw = dyn_cast<SwitchInst>(t))
    return spine::isQ(ctx, sw->getCondition());
  return false;
}

class Walker {
public:
  Walker(LoweringContext &ctx, Function &F, DominatorTree &DT, LoopInfo &LI)
      : ctx(ctx), sh(spine::shared(ctx)), F(F), DT(DT), LI(LI), PDT(F) {}

  void run();

private:
  LoweringContext &ctx;
  spine::Shared &sh;
  Function &F;
  DominatorTree &DT;
  LoopInfo &LI;
  PostDominatorTree PDT;

  std::vector<BasicBlock *> L;
  DenseMap<const BasicBlock *, unsigned> idx;
  std::vector<BitVector> reach;                         // reach[i][j]: L[j] reachable from L[i], forward edges
  DenseMap<const BasicBlock *, Loop *> unitOf;          // blocks of loops dispatched as units
  DenseSet<const BasicBlock *> pureHeaders;             // headers of purely classical loops walked inline
  DenseMap<const BasicBlock *, SmallVector<BasicBlock *, 2>> outEdges;
  DenseMap<const BasicBlock *, unsigned> outPreds;
  DenseSet<const BasicBlock *> merged;
  DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, BasicBlock *> edgeOut;
  std::vector<std::pair<PHINode *, PHINode *>> classicalPhis;
  DenseSet<const Instruction *> visited;
  std::vector<const Instruction *> blockDefs;           // original quantum defs in the current output block
  SmallVector<const BasicBlock *, 4> openRegions;       // ipdoms of quantum terminators not yet reached
  std::unique_ptr<TargetLibraryInfoImpl> tlii;
  std::unique_ptr<TargetLibraryInfo> tli;
  std::unique_ptr<AssumptionCache> ac;
  std::unique_ptr<ScalarEvolution> se;

  bool pureClassical(const Loop &lp);
  BasicBlock *next(const BasicBlock *x, const BasicBlock *s);
  void plan();
  void planGuards();

  struct Lit {
    const Value *v;
    bool neg;
    bool eq;
    APInt val;
    Pred p;
  };
  std::vector<Lit> cands;
  DenseMap<const BasicBlock *, std::pair<std::vector<unsigned>, BasicBlock *>> guards;
  bool eligible(const BasicBlock *y, const BasicBlock *from) const;
  BasicBlock *out(const BasicBlock *b);
  void emitBlock(BasicBlock *b);
  void emitTerminator(BasicBlock *b);
  void lowerUnit(Loop &lp);
  void maybeFlush(Instruction *term);
  void jump(const BasicBlock *from, const BasicBlock *to);
};

bool Walker::pureClassical(const Loop &lp) {
  for (const BasicBlock *b : lp.blocks())
    for (const Instruction &I : *b) {
      if ((!I.getType()->isVoidTy() && spine::isQ(ctx, &I)) || spine::anyQuantumOperand(ctx, I))
        return false;
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (!isa<DbgInfoIntrinsic>(CB) && calls::classify(*CB, ctx.T, ctx.S) != calls::Class::Classical)
          return false;
      if (auto *ld = dyn_cast<LoadInst>(&I))
        if (ctx.T.offsetKind(ld, ctx.S) == OffsetKind::Quantum)
          return false;
    }
  return true;
}

BasicBlock *Walker::next(const BasicBlock *x, const BasicBlock *s) {
  unsigned i = idx.lookup(x);
  const Loop *xl = LI.getLoopFor(x);
  for (unsigned j = i + 1; j < L.size(); ++j) {
    BasicBlock *y = L[j];
    if (s ? y == s : is_contained(successors(x), y))
      return y;
    // Arm heads only: a block inside a loop the edge does not enter is reached through its header.
    const Loop *yl = LI.getLoopFor(y);
    if (yl && yl->getHeader() != y && !(xl && yl->contains(xl)))
      continue;
    if (unitOf.count(y) && unitOf.lookup(y)->getHeader() != y)
      continue;
    if (reach[i].test(j))
      continue;
    BasicBlock *d = DT.findNearestCommonDominator(const_cast<BasicBlock *>(x), y);
    if (d && isQuantumTerm(ctx, d->getTerminator()))
      return y;
  }
  return const_cast<BasicBlock *>(s);
}

void Walker::plan() {
  ReversePostOrderTraversal<Function *> rpo(&F);
  for (BasicBlock *b : rpo) {
    idx[b] = L.size();
    L.push_back(b);
  }
  for (Loop *lp : LI.getTopLevelLoops()) {
    if (pureClassical(*lp)) {
      for (Loop *sub : lp->getLoopsInPreorder())
        pureHeaders.insert(sub->getHeader());
      continue;
    }
    for (BasicBlock *b : lp->blocks())
      unitOf[b] = lp;
  }
  // Forward reachability (edges to a later block of L; back edges excluded).
  reach.assign(L.size(), BitVector(L.size()));
  for (unsigned i = L.size(); i-- > 0;) {
    reach[i].set(i);
    for (BasicBlock *s : successors(L[i])) {
      unsigned j = idx.lookup(s);
      if (j > i)
        reach[i] |= reach[j];
    }
  }

  for (BasicBlock *b : L) {
    if (unitOf.count(b)) {
      Loop *lp = unitOf.lookup(b);
      if (lp->getHeader() != b)
        continue;
      BasicBlock *exit = lp->getUniqueExitBlock();
      if (!exit)
        unimplemented("spine: a non-classical loop with more than one exit block", b->getTerminator());
      outEdges[b].push_back(exit);
      continue;
    }
    Instruction *t = b->getTerminator();
    if (isa<ReturnInst>(t))
      continue;
    if (isa<UnreachableInst>(t)) {
      if (ctx.T.controlTainted(b, ctx.S))
        if (BasicBlock *n = next(b, nullptr))
          outEdges[b].push_back(n);
      continue;
    }
    if (isQuantumTerm(ctx, t)) {
      BasicBlock *n = next(b, nullptr);
      if (!n)
        internalError("spine: a quantum branch with nothing to fall through to", t);
      outEdges[b].push_back(n);
      continue;
    }
    if (!isa<BranchInst>(t) && !isa<SwitchInst>(t))
      unimplemented("spine: terminator kind", t);
    for (BasicBlock *s : successors(b)) {
      bool back = idx.lookup(s) <= idx.lookup(b);
      outEdges[b].push_back(back ? s : next(b, s));
    }
  }
  planGuards();
  for (auto &e : outEdges)
    for (BasicBlock *t : e.second)
      ++outPreds[t];
  for (auto &g : guards)
    ++outPreds[g.second.second];

  // A block reached only by an unconditional jump from the block emitted just before it continues
  // in that output block (no classical phi, not a loop header).
  const BasicBlock *prev = nullptr;
  for (BasicBlock *b : L) {
    if (unitOf.count(b) && unitOf.lookup(b)->getHeader() != b)
      continue;
    if (prev) {
      auto pe = outEdges.find(prev);
      bool uncond = pe != outEdges.end() && pe->second.size() == 1 && pe->second.front() == b;
      bool classicalPhi = false;
      for (PHINode &phi : b->phis())
        classicalPhi |= !spine::isQ(ctx, &phi);
      if (uncond && outPreds.lookup(b) == 1 && !classicalPhi && !pureHeaders.count(b) && !unitOf.count(b))
        merged.insert(b);
      // A unit's exit continues where the loop module leaves the builder.
      if (unitOf.count(prev) && pe != outEdges.end() && pe->second.front() == b) {
        if (outPreds.lookup(b) != 1)
          unimplemented("spine: the exit block of a dispatched loop has other predecessors", b->getTerminator());
        merged.insert(b);
      }
    }
    prev = b;
  }
  for (auto &[b, lp] : unitOf)
    if (lp->getHeader() == b && !merged.count(outEdges.lookup(b).front()))
      unimplemented("spine: the exit block of a dispatched loop does not follow it in the walk order",
                    b->getTerminator());
}

// Can the walk continue at y after leaving `from`? Blocks inside a loop are entered by its header.
bool Walker::eligible(const BasicBlock *y, const BasicBlock *from) const {
  const Loop *yl = LI.getLoopFor(y);
  const Loop *fl = LI.getLoopFor(from);
  if (yl && yl->getHeader() != y && !(fl && yl->contains(fl)))
    return false;
  if (unitOf.count(y) && unitOf.lookup(y)->getHeader() != y)
    return false;
  return true;
}

void Walker::planGuards() {
  // Candidate literals: classical branch conditions, classical terms of quantum conditions, cases of
  // classical switches.
  DenseSet<const Value *> seen;
  std::function<void(const Value *)> terms = [&](const Value *c) {
    if (!c->getType()->isIntegerTy(1) || isa<Constant>(c) || !seen.insert(c).second)
      return;
    if (!spine::isQ(ctx, c))
      cands.push_back(Lit{c, false, false, APInt(), Pred::atom(c)});
    if (auto *bo = dyn_cast<BinaryOperator>(c)) {
      if (bo->getOpcode() == Instruction::And || bo->getOpcode() == Instruction::Or ||
          bo->getOpcode() == Instruction::Xor) {
        terms(bo->getOperand(0));
        terms(bo->getOperand(1));
      }
    } else if (auto *sel = dyn_cast<SelectInst>(c)) {
      terms(sel->getCondition());
      terms(sel->getTrueValue());
      terms(sel->getFalseValue());
    }
  };
  for (BasicBlock *b : L) {
    Instruction *t = b->getTerminator();
    if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional())
      terms(br->getCondition());
    if (auto *sw = dyn_cast<SwitchInst>(t); sw && !spine::isQ(ctx, sw->getCondition()))
      for (auto &cs : sw->cases())
        cands.push_back(Lit{sw->getCondition(), false, true, cs.getCaseValue()->getValue(),
                            Pred::eqAtom(sw->getCondition(), cs.getCaseValue()->getValue())});
  }
  {
    size_t n = cands.size();
    for (size_t i = 0; i < n; ++i) {
      Lit l = cands[i];
      l.neg = true;
      l.p = !l.p;
      cands.push_back(l);
    }
  }

  DenseMap<const BasicBlock *, Pred> in;
  auto add = [&](const BasicBlock *to, const Pred &f) {
    auto it = in.find(to);
    if (it == in.end())
      in.insert({to, f});
    else
      it->second = it->second | f;
  };
  in.insert({L.front(), Pred::top()});
  for (BasicBlock *b : L) {
    if (unitOf.count(b) && unitOf.lookup(b)->getHeader() != b)
      continue;
    const Loop *bl = LI.getLoopFor(b);
    bool inPure = bl && !unitOf.count(b);
    auto ii = in.find(b);
    Pred inB = ii == in.end() ? Pred::top() : ii->second;
    const Pred &p = ctx.preds().block(b);
    Pred cf = p.isBottom() ? Pred::top() : p.classicalFactor(ctx.T, ctx.S);

    // A purely classical loop keeps its CFG exactly: its classical facts are the CFG's.
    if (!inPure && !(inB & !cf).isBottom()) {
      std::vector<unsigned> sel;
      Pred conj = Pred::top();
      for (unsigned k = 0; k < cands.size(); ++k) {
        const Lit &l = cands[k];
        if (!(cf & !l.p).isBottom() || (inB & conj & !l.p).isBottom())
          continue;
        if (auto *def = dyn_cast<Instruction>(l.v); def && !DT.dominates(def, b))
          continue;
        sel.push_back(k);
        conj = conj & l.p;
      }
      if (!(inB & conj & !cf).isBottom())
        unimplemented("spine: the classical factor of a block predicate is not a conjunction of branch-condition "
                      "literals that dominate the block (rule 8)",
                      b->getTerminator());
      BasicBlock *skip = nullptr;
      for (unsigned j = idx.lookup(b) + 1; j < L.size() && !skip; ++j) {
        BasicBlock *y = L[j];
        if (!eligible(y, b))
          continue;
        const Pred &py = ctx.preds().block(y);
        Pred cfy = py.isBottom() ? Pred::bottom() : py.classicalFactor(ctx.T, ctx.S);
        if (!(cfy & !conj).isBottom())
          skip = y;
      }
      if (!skip)
        internalError("spine: a classical guard with nothing to skip to", b->getTerminator());
      for (PHINode &phi : skip->phis())
        if (!spine::isQ(ctx, &phi))
          unimplemented("spine: a classical guard skipping to a block with a classical phi", &phi);
      guards[b] = {sel, skip};
      add(skip, inB & !conj);
    }
    Pred outB = inB & cf;

    if (unitOf.count(b)) {
      add(outEdges[b].front(), outB);
      continue;
    }
    Instruction *t = b->getTerminator();
    auto oe = outEdges.find(b);
    if (oe == outEdges.end())
      continue;
    if (isQuantumTerm(ctx, t) || isa<UnreachableInst>(t)) {
      for (BasicBlock *n : oe->second)
        add(n, outB);
      continue;
    }
    for (unsigned k = 0; k < t->getNumSuccessors(); ++k) {
      BasicBlock *s = t->getSuccessor(k), *tg = oe->second[k];
      if (idx.lookup(s) <= idx.lookup(b))
        continue;   // a back edge of a purely classical loop
      if (tg == s)
        add(s, outB & ctx.preds().edge(b, s).classicalFactor(ctx.T, ctx.S));
      else
        add(tg, outB);
    }
  }
}

BasicBlock *Walker::out(const BasicBlock *b) {
  auto it = sh.blocks.find(b);
  if (it != sh.blocks.end())
    return it->second;
  if (merged.count(b))
    internalError("spine: a branch to a block merged into its predecessor");
  BasicBlock *nb = BasicBlock::Create(ctx.M.getContext(), "", &ctx.out());
  sh.blocks[b] = nb;
  return nb;
}

void Walker::maybeFlush(Instruction *term) {
  if (!openRegions.empty())
    return;
  for (const Instruction *d : blockDefs)
    for (const User *u : d->users())
      if (auto *ui = dyn_cast<Instruction>(u); ui && !visited.count(ui))
        return;
  ctx.unc().flushBefore(term);
}

void Walker::jump(const BasicBlock *from, const BasicBlock *to) {
  if (merged.count(to))
    return;
  BranchInst *br = ctx.B().CreateBr(out(to));
  edgeOut[{from, to}] = br->getParent();
  maybeFlush(br);
}

void Walker::lowerUnit(Loop &lp) {
  loops::Case c = loops::classify(lp, ctx.T, ctx.S);
  if (c == loops::Case::QuantumExit) {
    if (!se) {
      tlii = std::make_unique<TargetLibraryInfoImpl>(Triple(F.getParent()->getTargetTriple()));
      tli = std::make_unique<TargetLibraryInfo>(*tlii, &F);
      ac = std::make_unique<AssumptionCache>(F);
      se = std::make_unique<ScalarEvolution>(F, *tli, *ac, DT, LI);
    }
    loops::lowerCutoff(ctx, lp, ctx.K(&lp), loops::tripBound(lp, *se));
  } else {
    loops::lowerClassical(ctx, lp, c);
  }
  for (BasicBlock *b : lp.blocks())
    for (Instruction &I : *b)
      visited.insert(&I);
}

void Walker::emitTerminator(BasicBlock *b) {
  Instruction *t = b->getTerminator();
  sh.cur = t;
  visited.insert(t);
  IRBuilder<> &B = ctx.B();

  if (auto *ret = dyn_cast<ReturnInst>(t)) {
    if (ctx.T.controlTainted(b, ctx.S))
      unimplemented("spine: a return under a quantum predicate", t);
    if (!ctx.S.isEntry())
      unimplemented("spine: return from a clone: rule 18 copy-out has no owner in the frozen interface (cq-b0w)", t);
    ReturnInst *nr;
    if (Value *rv = ret->getReturnValue()) {
      Operand op = ctx.operand(rv);
      Value *v = op.v;
      if (op.handle) {
        // §1.1: an entry returns an unmeasured quantum value as its handle; the rail escapes.
        ctx.unc().setRole(ctx.unc().idOf(op.v), Role::Escaped);
        Type *rt = F.getReturnType();
        if (!rt->isIntegerTy())
          unimplemented("spine: an entry returning a quantum value of non-integer C type (§1.1 names no "
                        "encoding of a handle in it)",
                        t);
        v = B.CreateZExtOrTrunc(op.v, rt);
      }
      nr = B.CreateRet(v);
    } else {
      nr = B.CreateRetVoid();
    }
    ctx.unc().flushAtExit(nr);
    return;
  }

  if (isa<UnreachableInst>(t)) {
    auto it = outEdges.find(b);
    if (it != outEdges.end() && !it->second.empty())
      return jump(b, it->second.front());
    B.CreateUnreachable();
    return;
  }

  if (isQuantumTerm(ctx, t)) {
    if (auto *br = dyn_cast<BranchInst>(t))
      lowerBranch(ctx, *br);
    else
      sw::lowerSwitch(ctx, *cast<SwitchInst>(t));
    BasicBlock *ip = PDT.getNode(b) && PDT.getNode(b)->getIDom() ? PDT.getNode(b)->getIDom()->getBlock() : nullptr;
    if (ip)
      openRegions.push_back(ip);
    BasicBlock *n = outEdges.lookup(b).front();
    if (!merged.count(n))
      B.CreateBr(out(n));
    return;
  }

  ArrayRef<BasicBlock *> targets = outEdges[b];
  if (auto *br = dyn_cast<BranchInst>(t)) {
    if (!br->isConditional())
      return jump(b, targets[0]);
    Operand c = ctx.operand(br->getCondition());
    if (c.handle)
      internalError("spine: a classical branch on a rail", t);
    BranchInst *nb = B.CreateCondBr(c.v, out(targets[0]), out(targets[1]));
    for (unsigned k = 0; k < 2; ++k)
      if (targets[k] == br->getSuccessor(k))
        edgeOut[{b, br->getSuccessor(k)}] = nb->getParent();
    maybeFlush(nb);
    return;
  }
  auto *sw = cast<SwitchInst>(t);
  Operand c = ctx.operand(sw->getCondition());
  if (c.handle)
    internalError("spine: a classical switch on a rail", t);
  // successors(b) order: default first, then the cases (SwitchInst successor order).
  SwitchInst *ns = B.CreateSwitch(c.v, out(targets[0]), sw->getNumCases());
  unsigned k = 1;
  for (auto &cs : sw->cases())
    ns->addCase(cs.getCaseValue(), out(targets[k++]));
  for (unsigned s = 0; s < sw->getNumSuccessors(); ++s)
    if (targets[s] == sw->getSuccessor(s))
      edgeOut[{b, sw->getSuccessor(s)}] = ns->getParent();
  maybeFlush(ns);
}

void Walker::emitBlock(BasicBlock *b) {
  if (merged.count(b)) {
    sh.blocks[b] = ctx.B().GetInsertBlock();
  } else {
    BasicBlock *ob = out(b);
    ctx.B().SetInsertPoint(ob);
    blockDefs.clear();
  }
  while (!openRegions.empty() && openRegions.back() == b)
    openRegions.pop_back();
  sh.curPred = ctx.preds().block(b).quantumPart(ctx.T, ctx.S);

  if (unitOf.count(b)) {
    lowerUnit(*unitOf.lookup(b));
    return;
  }

  for (PHINode &phi : b->phis()) {
    sh.cur = &phi;
    visited.insert(&phi);
    if (spine::isQ(ctx, &phi)) {
      spine::bindOperand(ctx, &phi, Operand{lowerMerge(ctx, phi), true});
      blockDefs.push_back(&phi);
      continue;
    }
    PHINode *np = ctx.B().CreatePHI(phi.getType(), phi.getNumIncomingValues(), phi.getName());
    classicalPhis.push_back({&phi, np});
    spine::bindOperand(ctx, &phi, Operand{np, false});
  }

  if (auto g = guards.find(b); g != guards.end()) {
    // Rule 8 / P1: the classical factor not yet established on every path here is a classical branch.
    IRBuilder<> &B = ctx.B();
    sh.cur = &*b->getFirstNonPHIIt();
    Value *cond = nullptr;
    for (unsigned k : g->second.first) {
      const Lit &l = cands[k];
      Operand op = ctx.operand(l.v);
      if (op.handle)
        internalError("spine: a classical guard literal that is a rail", l.v);
      Value *v = l.eq ? B.CreateICmpEQ(op.v, ConstantInt::get(op.v->getType(), l.val)) : op.v;
      if (l.neg)
        v = B.CreateNot(v);
      cond = cond ? B.CreateAnd(cond, v) : v;
    }
    BasicBlock *cont = BasicBlock::Create(ctx.M.getContext(), "", &ctx.out());
    B.CreateCondBr(cond, cont, out(g->second.second));
    B.SetInsertPoint(cont);
    blockDefs.clear();
  }

  for (auto it = b->getFirstNonPHIIt(), end = b->getTerminator()->getIterator(); it != end; ++it) {
    Instruction &I = *it;
    sh.cur = &I;
    visited.insert(&I);
    if (auto *CB = dyn_cast<CallInst>(&I);
        CB && calls::classify(*CB, ctx.T, ctx.S) == calls::Class::InvertBegin) {
      // Rule 17: eff-invert owns the bracketed region, up to and including its end marker.
      auto e = std::next(it);
      for (; e != end; ++e)
        if (auto *E = dyn_cast<CallInst>(&*e);
            E && calls::classify(*E, ctx.T, ctx.S) == calls::Class::InvertEnd)
          break;
      if (e == end)
        unimplemented("spine: a cq_invert region spanning blocks", CB);
      invert::lowerRegion(ctx, *CB, *cast<CallInst>(&*e));
      for (auto r = it; r != std::next(e); ++r)
        visited.insert(&*r);
      it = e;
      continue;
    }
    spine::dispatch(ctx, I);
    if (!I.getType()->isVoidTy()) {
      auto bi = sh.binds.find(&I);
      if (bi != sh.binds.end())
        for (const Operand &o : bi->second)
          if (o.handle) {
            blockDefs.push_back(&I);
            break;
          }
    }
  }
  emitTerminator(b);
}

void Walker::run() {
  plan();
  // The first block of L is the entry; its output block must be the output function's first.
  for (BasicBlock *b : L) {
    if (unitOf.count(b) && unitOf.lookup(b)->getHeader() != b)
      continue;
    emitBlock(b);
  }
  for (auto &[op, np] : classicalPhis) {
    for (unsigned i = 0; i < op->getNumIncomingValues(); ++i) {
      BasicBlock *u = op->getIncomingBlock(i);
      auto e = edgeOut.find({u, op->getParent()});
      if (e == edgeOut.end())
        unimplemented("spine: a classical phi over an edge the linearization redirected: a classical branch "
                      "joining with a quantum arm (cq-mtt, cq-bq0)",
                      op);
      sh.cur = u->getTerminator();
      Operand v = ctx.operand(op->getIncomingValue(i));
      if (v.handle)
        internalError("spine: a classical phi with a rail incoming", op);
      np->addIncoming(v.v, e->second);
    }
  }
  sh.cur = nullptr;
}

} // namespace

void construct(Module &M, const TaintInfo &T, const Specialization &S, const loops::KOptions &KO) {
  if (!S.F || S.F->isDeclaration())
    internalError("spine: construct of a specialization with no body");
  if (S.adj)
    unimplemented("spine: an _adj clone (rule 17)", S.F);
  Function &F = *S.F;

  LoweringContext ctx(M, T, S, KO);
  spine::Shared &sh = spine::shared(ctx);
  sh.orig = &F;

  Value *entryFlag = nullptr;
  if (S.isEntry()) {
    Function *NF = Function::Create(F.getFunctionType(), GlobalValue::InternalLinkage, F.getName() + ".cq.entry", &M);
    sh.out = NF;
    for (unsigned i = 0; i < F.arg_size(); ++i) {
      if (spine::isQ(ctx, F.getArg(i)))
        unimplemented("spine: an entry function with a quantum formal (rule 1)", F.getArg(i));
      spine::bindOperand(ctx, F.getArg(i), Operand{NF->getArg(i), false});
    }
    pendingEntries[&M].push_back({&F, NF});
  } else {
    Function *C = calls::materialize(M, S);
    sh.out = C;
    unsigned off = S.ctl ? 1 : 0;
    if (C->arg_size() != F.arg_size() + off)
      unimplemented("spine: a clone whose formals are not one per original formal (aggregate or pointer "
                    "fields: calls/aggr/fatptr)",
                    C);
    if (S.ctl)
      entryFlag = C->getArg(0);
    for (unsigned i = 0; i < F.arg_size(); ++i) {
      Argument *p = C->getArg(i + off);
      bool q = spine::isQ(ctx, F.getArg(i));
      if (q)
        ctx.unc().recordExternal(p, Role::UserRegister);   // the caller's rail: never freed here
      spine::bindOperand(ctx, F.getArg(i), Operand{p, q});
    }
  }

  DominatorTree &DT = sh.dt(F);
  LoopInfo LI(DT);
  ctx.preds().compute(F, LI, T, S, entryFlag);
  ctx.B().SetInsertPoint(BasicBlock::Create(M.getContext(), "", sh.out));
  // The walker creates blocks on demand; the entry block made here is L[0]'s.
  {
    BasicBlock *entry = &sh.out->getEntryBlock();
    sh.blocks[&F.getEntryBlock()] = entry;
  }
  Walker(ctx, F, DT, LI).run();

  ArrayRef<Specialization> all = T.specializations();
  bool inList = !all.empty() && &S >= all.begin() && &S < all.end();
  if (!inList || &S == &all.back()) {
    finishEntries(M);
    dropDeadSurface(M);
  }
}

} // namespace cq
