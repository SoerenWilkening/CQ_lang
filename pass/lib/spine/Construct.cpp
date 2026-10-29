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
#include "cq/Rotation.h"
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
  const Instruction *regionEnd = nullptr;               // a cq_invert region spanning blocks in progress
  // cq-lx8f: quantum phis of a unit's exit blocks that the loop module bound (rule 14 case 2: an exit
  // phi identified with a carried value's final state). The walker does not merge them again.
  DenseSet<const PHINode *> unitBoundPhis;
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
  // cq-174f: the classical facts each planned output edge establishes (planGuards), and per original
  // block the output edges actually emitted into its output block, with their facts (and the loop
  // when the edge is a unit's exit). A quantum phi of a block reached by several output edges is
  // factored by them first (factoredMerge).
  DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, Pred> edgeFacts;
  DenseMap<const BasicBlock *, Pred> guardFacts;
  struct InEdge {
    BasicBlock *out;
    std::optional<Pred> facts;
    Loop *unit;
  };
  DenseMap<const BasicBlock *, SmallVector<InEdge, 2>> inEdges;
  void noteIn(const BasicBlock *from, const BasicBlock *to, Loop *unit = nullptr);
  Value *factoredMerge(PHINode &phi);
  bool eligible(const BasicBlock *y, const BasicBlock *from) const;
  BasicBlock *out(const BasicBlock *b);
  void emitBlock(BasicBlock *b);
  void emitGuard(BasicBlock *b);
  void emitBody(BasicBlock *b, const Instruction *resume);
  void emitTerminator(BasicBlock *b);
  void emitCloneReturn(ReturnInst *ret);
  Value *returnCopyOut(PHINode &phi);
  DenseSet<const Value *> copiedOut;                    // return phis copied out per edge (cq-mjwb)
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
  // Reverse post-order with successors visited last to first, so a branch's first successor (the
  // then arm) comes first in L and its arm is linearized before the else arm (cq-746v).
  {
    std::vector<BasicBlock *> post;
    DenseSet<BasicBlock *> seen;
    std::vector<std::pair<BasicBlock *, unsigned>> stack;   // block, successors still to visit
    seen.insert(&F.getEntryBlock());
    stack.push_back({&F.getEntryBlock(), F.getEntryBlock().getTerminator()->getNumSuccessors()});
    while (!stack.empty()) {
      auto &[b, k] = stack.back();
      if (k == 0) {
        post.push_back(b);
        stack.pop_back();
        continue;
      }
      BasicBlock *s = b->getTerminator()->getSuccessor(--k);
      if (seen.insert(s).second)
        stack.push_back({s, s->getTerminator()->getNumSuccessors()});
    }
    for (auto it = post.rbegin(); it != post.rend(); ++it) {
      idx[*it] = L.size();
      L.push_back(*it);
    }
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
      // The loop as a unit ends at its exit block; like any edge leaving b, it continues at the next
      // block of the walk that may run (an arm still to run comes first).
      outEdges[b].push_back(next(b, exit));
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
      // A unit's exit continues where the loop module leaves the builder when the unit is its only
      // way in and it comes next; otherwise (a zero-trip guard's skip edge also reaches it, 41, 177)
      // the unit ends in a jump to it (emitBlock).
      if (unitOf.count(prev) && pe != outEdges.end() && pe->second.front() == b && outPreds.lookup(b) == 1)
        merged.insert(b);
    }
    prev = b;
  }
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
  auto fact = [&](const BasicBlock *from, const BasicBlock *to, const Pred &f) {
    auto it = edgeFacts.find({from, to});
    if (it == edgeFacts.end())
      edgeFacts.insert({{from, to}, f});
    else
      it->second = it->second | f;
  };
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
      guardFacts.insert({b, inB & !conj});
    }
    Pred outB = inB & cf;

    if (unitOf.count(b)) {
      add(outEdges[b].front(), outB);
      fact(b, outEdges[b].front(), outB);
      continue;
    }
    Instruction *t = b->getTerminator();
    auto oe = outEdges.find(b);
    if (oe == outEdges.end())
      continue;
    if (isQuantumTerm(ctx, t) || isa<UnreachableInst>(t)) {
      for (BasicBlock *n : oe->second) {
        add(n, outB);
        fact(b, n, outB);
      }
      continue;
    }
    for (unsigned k = 0; k < t->getNumSuccessors(); ++k) {
      BasicBlock *s = t->getSuccessor(k), *tg = oe->second[k];
      if (idx.lookup(s) <= idx.lookup(b))
        continue;   // a back edge of a purely classical loop
      Pred f = tg == s ? outB & ctx.preds().edge(b, s).classicalFactor(ctx.T, ctx.S) : outB;
      add(tg, f);
      fact(b, tg, f);
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
  noteIn(from, to);
  maybeFlush(br);
}

void Walker::noteIn(const BasicBlock *from, const BasicBlock *to, Loop *unit) {
  auto f = edgeFacts.find({from, to});
  inEdges[to].push_back(
      {ctx.B().GetInsertBlock(), f == edgeFacts.end() ? std::nullopt : std::optional<Pred>(f->second), unit});
}

// cq-174f: a quantum phi whose output block is reached by several output edges (a classical guard's
// skip edge, a unit's exit, a classical branch) is factored by the classical facts of those edges
// first (rule 8 / P1: the classical factor stays a classical branch). On each output edge e with facts
// F the incomings whose edge predicate meets F are the candidates; a candidate edge u -> b from
// outside a rule-14 case-3 unit whose exit e is, is absorbed by the unit when, under F, u -> b is
// taken only when the header's predicate is false and its value is the initial value of the carried
// value whose next the unit's own incoming is: the unit's trip predicate starts at the flag of the
// header's quantum predicate (loops-classical's contract), so no trip runs and the carried value
// leaves the unit as that initial value (26 break_with_body: the pre-header test n < 1 || x == k is
// trip -1 of the latch test). An edge keeping one candidate takes its value; an edge keeping several
// takes rule 9's select chain over them, emitted where the edge leaves, each arm under the quantum
// part of its predicate restricted to F (only when that restriction is exact: the arm's classical
// factor is F; g6 of review cq-hqk5, a case-1 loop in an arm `q && c`). The phi is then chosen
// classically: a phi over handles on the output edges, each value read where its edge leaves (a
// classical one seeded there), recorded as a merge (rule 9 at a58c3a4, then cq-bv91's kept arms).
// Otherwise (an output edge with no facts, a non-scalar phi, an inexact restriction) nullptr: the
// merge stays pred's lowerMerge.
Value *Walker::factoredMerge(PHINode &phi) {
  const BasicBlock *b = phi.getParent();
  auto ie = inEdges.find(b);
  if (ie == inEdges.end() || ie->second.size() < 2)
    return nullptr;
  BasicBlock *join = out(b);
  {
    SmallPtrSet<BasicBlock *, 4> outs, preds;
    for (const InEdge &e : ie->second) {
      if (!e.facts || !outs.insert(e.out).second)
        return nullptr;
    }
    for (BasicBlock *p : predecessors(join))
      preds.insert(p);
    if (preds != outs)
      return nullptr;
  }
  RailType w = railTypeOf(phi.getType());
  if (!(phi.getType()->isIntegerTy() || phi.getType()->isFloatingPointTy()))
    return nullptr;
  // Per output edge: one incoming value, or a select chain over several, each arm under the quantum
  // part of its edge predicate restricted to the edge's facts.
  struct Choice {
    BasicBlock *out;
    SmallVector<std::pair<Pred, const Value *>, 2> arms;
  };
  std::vector<Choice> chosen;
  for (const InEdge &e : ie->second) {
    const Pred &F = *e.facts;
    SmallVector<unsigned, 2> cands;
    for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
      const BasicBlock *u = phi.getIncomingBlock(i);
      if (!idx.count(u))
        continue;   // an unreachable predecessor never selects
      if ((ctx.preds().edge(u, b) & F).isBottom())
        continue;
      if (none_of(cands, [&](unsigned k) { return phi.getIncomingValue(k) == phi.getIncomingValue(i); }))
        cands.push_back(i);
    }
    if (e.unit && cands.size() > 1 && loops::classify(*e.unit, ctx.T, ctx.S) == loops::Case::ClassicalBoundQuantumExit) {
      Loop &lp = *e.unit;
      const BasicBlock *header = lp.getHeader(), *pre = lp.getLoopPredecessor(), *latch = lp.getLoopLatch();
      const Value *inLoop = nullptr;
      unsigned nIn = 0;
      for (unsigned k : cands)
        if (lp.contains(phi.getIncomingBlock(k))) {
          inLoop = phi.getIncomingValue(k);
          ++nIn;
        }
      const Value *init = nullptr;
      if (nIn == 1 && pre && latch)
        for (const PHINode &h : header->phis())
          if (h.getIncomingValueForBlock(latch) == inLoop && spine::isQ(ctx, &h))
            init = h.getIncomingValueForBlock(pre);
      if (init) {
        const Pred &hp = ctx.preds().block(header);
        SmallVector<unsigned, 2> kept;
        for (unsigned k : cands) {
          const BasicBlock *u = phi.getIncomingBlock(k);
          bool absorbed = !lp.contains(u) && phi.getIncomingValue(k) == init;
          if (absorbed)
            for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i)
              if (phi.getIncomingValue(i) == init && !lp.contains(phi.getIncomingBlock(i)) &&
                  !(ctx.preds().edge(phi.getIncomingBlock(i), b) & F & hp).isBottom())
                absorbed = false;
          if (!absorbed)
            kept.push_back(k);
        }
        cands = kept;
      }
    }
    if (cands.empty())
      return nullptr;
    Choice ch{e.out, {}};
    for (unsigned k : cands) {
      // The arm's predicate under F: every incoming edge carrying the same value.
      Pred p = Pred::bottom();
      for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i)
        if (phi.getIncomingValue(i) == phi.getIncomingValue(k) && idx.count(phi.getIncomingBlock(i)))
          p = p | ctx.preds().edge(phi.getIncomingBlock(i), b);
      p = p & F;
      // Its quantum part stands for it under F only when its classical factor is F itself.
      if (cands.size() > 1 && !(F & !p.classicalFactor(ctx.T, ctx.S)).isBottom())
        return nullptr;
      ch.arms.push_back({p.quantumPart(ctx.T, ctx.S), phi.getIncomingValue(k)});
    }
    chosen.push_back(std::move(ch));
  }

  // Each value is read where its edge leaves.
  IRBuilder<> &B = ctx.B();
  std::vector<Operand> ops;
  {
    IRBuilderBase::InsertPointGuard g(B);
    for (Choice &ch : chosen) {
      Instruction *t = ch.out->getTerminator();
      if (!t)
        internalError("spine: the output block of an incoming edge has no terminator yet", &phi);
      B.SetInsertPoint(t);
      if (ch.arms.size() == 1) {
        ops.push_back(ctx.operand(ch.arms.front().second));
        continue;
      }
      // Rule 9 on this edge alone: the merge's quantum rest, a select chain where the edge leaves.
      std::vector<std::pair<Pred, Operand>> arms;
      for (auto &[p, v] : ch.arms)
        arms.push_back({p, ctx.operand(v)});
      ops.push_back(Operand{selectChain(ctx, arms, w), true});
    }
    bool anyHandle = any_of(ops, [](const Operand &o) { return o.handle; });
    bool same = all_of(ops, [&](const Operand &o) { return o.v == ops.front().v; });
    if (anyHandle && !same)
      for (unsigned k = 0; k < ops.size(); ++k)
        if (!ops[k].handle) {
          B.SetInsertPoint(chosen[k].out->getTerminator());
          CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {ops[k].v});
          ctx.unc().recordSeed(a);
          ops[k] = Operand{a, true};
        }
  }
  auto seedHere = [&](Value *c) {
    CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {c});
    ctx.unc().recordSeed(a);
    return a;
  };
  if (all_of(ops, [&](const Operand &o) { return o.v == ops.front().v; }))
    return ops.front().handle ? ops.front().v : seedHere(ops.front().v);
  Type *ty = ops.front().v->getType();
  PHINode *np = PHINode::Create(ty, unsigned(ops.size()), phi.getName());
  np->insertInto(join, join->getFirstNonPHIIt());
  for (unsigned k = 0; k < ops.size(); ++k)
    np->addIncoming(ops[k].v, chosen[k].out);
  if (!ops.front().handle)
    return seedHere(np);   // every arm read classically: one value, one rail
  ctx.unc().recordMerge(np);
  return np;
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

// Rule 18 copy-out at a clone's return (cq-b0w, orchestrator decision: the spine owns it). A
// quantum result r is copied into a fresh rail f = cqrt_alloc_<W>(0); cqrt_copy_<W>(r, f), f is kept
// (Role::Result: the caller frees it after the twin) and returned; flushAtExit then uncomputes the
// body, which the copy reads, after it (06, 07, 33, 34). The copy is made even for a one-template
// body (CR allows returning that rail directly; the corpus always copies). A classical result (a
// callee that measures, or a mask under which the result does not depend on a quantum value) is
// returned as is.
void Walker::emitCloneReturn(ReturnInst *ret) {
  IRBuilder<> &B = ctx.B();
  Function *C = ctx.B().GetInsertBlock()->getParent();
  ReturnInst *nr;
  if (Value *rv = ret->getReturnValue()) {
    if (rv->getType()->isAggregateType())
      unimplemented("spine: a clone returning an aggregate (rule 18 copy-out per field: aggr/calls)", ret);
    Operand op = ctx.operand(rv);
    Value *v = op.v;
    if (copiedOut.count(rv)) {
      // Copied out on each incoming edge already (returnCopyOut): v is the phi of the result rails.
      if (!op.handle || C->getReturnType() != handleTy(ctx.M.getContext()))
        internalError("spine: a return phi copied out per edge that is not a handle of the clone's type", ret);
    } else if (op.handle) {
      if (C->getReturnType() != handleTy(ctx.M.getContext()))
        internalError("spine: a clone with a quantum result whose return type is not the handle type", ret);
      RailType w = railTypeOf(rv->getType());
      CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                 {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
      RailId fid = ctx.unc().recordSeed(f);
      abi::CoreSpec cp{abi::Core::Copy, w};
      CallInst *c = ctx.emitCore(cp, {op.v, f});
      ctx.unc().recordCore(c, cp, {op, Operand{f, true}}, fid);
      ctx.unc().setRole(fid, Role::Result);
      v = f;
    } else if (v->getType() != C->getReturnType()) {
      internalError("spine: a clone's classical result does not have the clone's return type", ret);
    }
    nr = B.CreateRet(v);
  } else {
    nr = B.CreateRetVoid();
  }
  ctx.unc().flushAtExit(nr);
}

// Rule 18 copy-out of a return phi chosen classically (cq-mjwb, 119). A clone's return value that
// is a phi of the return's own block, read by the return alone, whose every incoming edge is chosen
// classically, names on each path the arm of the edge taken. Copying out of the merged handle at the
// return would read an arm (garbage of its own branch) at a return its definition does not dominate.
// So the copy-out is made on each incoming edge, where the edge leaves: f_e = cqrt_alloc_<W>(0),
// cqrt_copy_<W>(arm_e, f_e) (an arm that is classical on that edge: f_e = cqrt_alloc_<W>(arm_e)), f_e
// kept as Role::Result; the return returns the phi of the f_e, recorded as a merge whose arms are all
// kept (U1, cq-bv91: nothing changes). The arm's garbage is then resolved in its own arm: the edge
// block flushes (flushBefore its terminator) once nothing lowered later reads a rail defined there,
// as maybeFlush does at a jump (119: the reference's per-arm alloc + copy, the base case copying the
// formal, and the arm's uncompute inside the arm). An edge leaving a block that branches elsewhere
// too gets a block of its own on that edge (as a classical guard's skip edge does), so the copy runs
// on that edge only. nullptr when the shape is not this one (an entry, other users, a merged or
// guarded join, an output edge the walk did not record, a quantum phi of the block after this one):
// the merge is lowered as any other phi.
Value *Walker::returnCopyOut(PHINode &phi) {
  BasicBlock *b = phi.getParent();
  auto *ret = dyn_cast<ReturnInst>(b->getTerminator());
  if (ctx.S.isEntry() || !ret || ret->getReturnValue() != &phi || !phi.hasOneUse() || merged.count(b) ||
      guards.count(b) || unitOf.count(b))
    return nullptr;
  if (!phi.getType()->isIntegerTy() && !phi.getType()->isFloatingPointTy())
    return nullptr;
  for (const PHINode &o : b->phis())
    if (&o != &phi && !visited.count(&o) && spine::isQ(ctx, &o))
      return nullptr;
  Function *C = ctx.B().GetInsertBlock()->getParent();
  if (C->getReturnType() != handleTy(ctx.M.getContext()))
    return nullptr;
  BasicBlock *ob = out(b);
  // One value per output edge block; every output edge into ob is one of them.
  SmallVector<std::pair<BasicBlock *, const Value *>, 4> edges;
  for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
    BasicBlock *u = phi.getIncomingBlock(i);
    if (!idx.count(u))
      continue;   // an unreachable predecessor never chooses
    if (!ctx.preds().edge(u, b).isClassical(ctx.T, ctx.S))
      return nullptr;
    auto e = edgeOut.find({u, b});
    if (e == edgeOut.end())
      return nullptr;
    const Value *v = phi.getIncomingValue(i);
    auto it = find_if(edges, [&](const auto &x) { return x.first == e->second; });
    if (it == edges.end())
      edges.push_back({e->second, v});
    else if (it->second != v)
      return nullptr;
  }
  if (edges.empty())
    return nullptr;
  for (BasicBlock *p : predecessors(ob))
    if (none_of(edges, [&](const auto &x) { return x.first == p; }))
      return nullptr;
  for (auto &[E, v] : edges) {
    Instruction *t = E->getTerminator();
    if (!t || count(successors(E), ob) != 1)
      return nullptr;
  }

  IRBuilder<> &B = ctx.B();
  RailType w = railTypeOf(phi.getType());
  PHINode *np;
  {
    IRBuilderBase::InsertPointGuard g(B);
    SmallVector<std::pair<BasicBlock *, Value *>, 4> fs;
    for (auto &[E, v] : edges) {
      BasicBlock *at = E;
      if (E->getTerminator()->getNumSuccessors() > 1) {
        // The edge's own block: the copy runs on this edge only.
        BasicBlock *n = BasicBlock::Create(ctx.M.getContext(), "", &ctx.out(), ob);
        E->getTerminator()->replaceSuccessorWith(ob, n);
        BranchInst::Create(ob, n);
        ob->replacePhiUsesWith(E, n);
        for (auto &[k, o] : edgeOut)
          if (k.second == b && o == E)
            o = n;
        for (InEdge &ie : inEdges[b])
          if (ie.out == E)
            ie.out = n;
        at = n;
      }
      Instruction *t = at->getTerminator();
      B.SetInsertPoint(t);
      sh.cur = &phi;
      Operand op = ctx.operand(v);
      CallInst *f;
      if (op.handle) {
        f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
        RailId fid = ctx.unc().recordSeed(f);
        abi::CoreSpec cp{abi::Core::Copy, w};
        CallInst *c = ctx.emitCore(cp, {op.v, f});
        ctx.unc().recordCore(c, cp, {op, Operand{f, true}}, fid);
        ctx.unc().setRole(fid, Role::Result);
      } else {
        f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {op.v});
        ctx.unc().setRole(ctx.unc().recordSeed(f), Role::Result);
      }
      fs.push_back({at, f});
      // The arm's garbage is resolved in its own arm once nothing lowered later reads it.
      if (at == E && openRegions.empty()) {
        bool later = false;
        for (auto &[orig, ops] : sh.binds) {
          auto *oi = dyn_cast<Instruction>(orig);
          if (!oi || none_of(ops, [&](const Operand &o) {
                return o.handle && isa<Instruction>(o.v) && cast<Instruction>(o.v)->getParent() == E;
              }))
            continue;
          for (const User *us : oi->users())
            if (auto *ui = dyn_cast<Instruction>(us); ui && ui != &phi && !visited.count(ui))
              later = true;
        }
        if (!later)
          ctx.unc().flushBefore(t);
      }
    }
    np = PHINode::Create(handleTy(ctx.M.getContext()), unsigned(fs.size()), phi.getName());
    np->insertInto(ob, ob->getFirstNonPHIIt());
    for (auto &[at, f] : fs)
      np->addIncoming(f, at);
  }
  ctx.unc().recordMerge(np);
  copiedOut.insert(&phi);
  sh.cur = &phi;
  return np;
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
      return emitCloneReturn(ret);
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
    if (!merged.count(n)) {
      B.CreateBr(out(n));
      noteIn(b, n);
    }
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
    noteIn(b, targets[0]);
    if (targets[1] != targets[0])
      noteIn(b, targets[1]);
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
  {
    SmallVector<const BasicBlock *, 4> done;
    for (BasicBlock *t : targets)
      if (!is_contained(done, t)) {
        done.push_back(t);
        noteIn(b, t);
      }
  }
  for (unsigned s = 0; s < sw->getNumSuccessors(); ++s)
    if (targets[s] == sw->getSuccessor(s))
      edgeOut[{b, sw->getSuccessor(s)}] = ns->getParent();
  maybeFlush(ns);
}

void Walker::emitBlock(BasicBlock *b) {
  if (regionEnd) {
    // Inside a cq_invert region spanning blocks (eff-invert lowered it): b emits nothing of its own and
    // continues in the current output block; the end's block resumes after the end marker.
    if (sh.blocks.count(b))
      internalError("spine: a block of a cq_invert region with an output block of its own", b->getTerminator());
    if (unitOf.count(b) || guards.count(b))
      internalError("spine: a loop or classical guard inside a cq_invert region", b->getTerminator());
    sh.blocks[b] = ctx.B().GetInsertBlock();
    for (Instruction &I : *b) {
      visited.insert(&I);
      if (&I == regionEnd)
        break;
    }
    if (regionEnd->getParent() != b)
      return;
    const Instruction *resume = regionEnd;
    regionEnd = nullptr;
    while (!openRegions.empty() && openRegions.back() == b)
      openRegions.pop_back();
    sh.curPred = ctx.preds().block(b).quantumPart(ctx.T, ctx.S);
    emitBody(b, resume);
    return;
  }
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
    // The header's guard comes first: the unit runs only under it (cq-uevr).
    emitGuard(b);
    Loop &lp = *unitOf.lookup(b);
    SmallVector<std::pair<BasicBlock *, BasicBlock *>, 4> exits;
    lp.getExitEdges(exits);
    // The exit blocks' quantum phis not yet bound: those bound once the unit returns, the loop module
    // bound (cq-lx8f). A phi bound before the unit is not the loop module's and stays an error below.
    SmallVector<const PHINode *, 4> exitPhis;
    for (auto &x : exits)
      for (PHINode &phi : x.second->phis())
        if (spine::isQ(ctx, &phi) && !sh.binds.count(&phi) && !is_contained(exitPhis, &phi))
          exitPhis.push_back(&phi);
    lowerUnit(lp);
    for (const PHINode *phi : exitPhis)
      if (sh.binds.count(phi))
        unitBoundPhis.insert(phi);
    BasicBlock *n = outEdges.lookup(b).front();
    // All of the unit's exit edges leave from one output block, so a phi of an exit block cannot
    // tell them apart: it would get one incoming per exit edge from the same block (cq-qjm9). It
    // stays unimplemented until the loop contract says which exit edge was taken. The count is over
    // the loop's own exit blocks, not n: a unit in a quantum arm continues at next(b, exit), which
    // need not be the block its exit edges target, and n may be merged (cq-9us4).
    for (auto &x : exits) {
      BasicBlock *to = x.second;
      if (count_if(exits, [&](const auto &e) { return e.second == to; }) > 1 && !to->phis().empty())
        unimplemented("spine: a loop unit with more than one exit edge into an exit block with a phi (the "
                      "loop contract does not say which exit edge was taken; cq-qjm9)",
                      &*to->phis().begin());
    }
    // Every exiting block's output block is where the loop module left the builder, the block the
    // exit edges leave from (cq-qctz): a phi of an exit block the loop module did not bind (a
    // classically chosen merge of the zero-trip edge and the loop edge) finds its loop incoming
    // there through ctx.block(exiting). Set before the merged return, which also continues there.
    for (auto &x : exits)
      sh.blocks[x.first] = ctx.B().GetInsertBlock();
    if (merged.count(n))
      return;
    // The unit's exit edges all leave from where the loop module left the builder (a classical phi
    // of the exit block takes its incoming values there). The jump flushes only once no rail the loop
    // bound to an original value is still read after it.
    BasicBlock *at = ctx.B().GetInsertBlock();
    for (auto &[from, to] : exits)
      if (to == n)
        edgeOut[{from, to}] = at;
    blockDefs.clear();
    for (BasicBlock *lb : lp.blocks())
      for (Instruction &I : *lb) {
        auto bi = sh.binds.find(&I);
        if (bi != sh.binds.end() && any_of(bi->second, [](const Operand &o) { return o.handle; }))
          blockDefs.push_back(&I);
      }
    BranchInst *br = ctx.B().CreateBr(out(n));
    noteIn(b, n, &lp);
    maybeFlush(br);
    return;
  }

  for (PHINode &phi : b->phis()) {
    sh.cur = &phi;
    visited.insert(&phi);
    if (unitBoundPhis.count(&phi)) {
      blockDefs.push_back(&phi);
      continue;
    }
    if (spine::isQ(ctx, &phi)) {
      // A phi whose every incoming edge predicate is classical chooses its incoming value
      // classically: pred's lowerMerge emits a classical phi over handles (rule 9 at a58c3a4).
      // Rule 10: a phi with a state prep (or a merge of one) among its incomings merges the
      // register's states; it is the register, never a select of the rotated rail (no label copy).
      if (any_of(phi.incoming_values(), [&](const Value *u) { return sh.statePreps.count(u); })) {
        sh.statePreps.insert(&phi);
        rot::lowerStatePrepMerge(ctx, phi);
        blockDefs.push_back(&phi);
        continue;
      }
      // Rule 21 (cq-xb7r): a quantum pointer phi is a fat-pointer merge (tag, idx), the phi
      // counterpart of the select fatptr::lower takes; fatptr has no phi entry yet, and pred's merge
      // is scalar only.
      if (phi.getType()->isPointerTy())
        unimplemented("spine: a quantum pointer phi (rule 21 fat-pointer merge; fatptr has no phi entry)", &phi);
      if (Value *r = returnCopyOut(phi)) {
        spine::bindOperand(ctx, &phi, Operand{r, true});
        blockDefs.push_back(&phi);
        continue;
      }
      Value *m = merged.count(b) ? nullptr : factoredMerge(phi);
      spine::bindOperand(ctx, &phi, Operand{m ? m : lowerMerge(ctx, phi), true});
      // CR rule 6: a merge of bijective updates of a dead y and y itself cleans the old y (125).
      spine::ruleSixAfter(ctx, phi);
      blockDefs.push_back(&phi);
      continue;
    }
    PHINode *np = ctx.B().CreatePHI(phi.getType(), phi.getNumIncomingValues(), phi.getName());
    classicalPhis.push_back({&phi, np});
    spine::bindOperand(ctx, &phi, Operand{np, false});
  }

  emitGuard(b);
  emitBody(b, nullptr);
}

// Rule 8 / P1: the classical factor of b's predicate not yet established on every path here is a
// classical branch at b's start, to b's own code or to the planned skip block (cq-uevr: a loop unit's
// header too, before the unit is lowered).
void Walker::emitGuard(BasicBlock *b) {
  auto g = guards.find(b);
  if (g == guards.end())
    return;
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
  const BasicBlock *skip = g->second.second;
  // cq-174f: when the skip block has a quantum phi, the skip edge gets a block of its own, where the
  // phi's value on that edge is read (and seeded) on the skip path only.
  BasicBlock *from = B.GetInsertBlock();
  bool split = any_of(skip->phis(), [&](const PHINode &p) { return spine::isQ(ctx, &p); });
  if (split) {
    BasicBlock *e = BasicBlock::Create(ctx.M.getContext(), "", &ctx.out());
    B.CreateCondBr(cond, cont, e);
    BranchInst::Create(out(skip), e);
    from = e;
  } else {
    B.CreateCondBr(cond, cont, out(skip));
  }
  {
    auto gf = guardFacts.find(b);
    inEdges[skip].push_back({from, gf == guardFacts.end() ? std::nullopt : std::optional<Pred>(gf->second), nullptr});
  }
  B.SetInsertPoint(cont);
  blockDefs.clear();
}

// The instructions of b after its phis (after resume when set: the end marker of a cq_invert region
// begun in an earlier block), then its terminator.
void Walker::emitBody(BasicBlock *b, const Instruction *resume) {
  for (BasicBlock::iterator it = resume ? std::next(const_cast<Instruction *>(resume)->getIterator())
                                        : b->getFirstNonPHIIt(),
                            end = b->getTerminator()->getIterator();
       it != end; ++it) {
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
      if (e == end) {
        // The region spans blocks: its end is the first __cq_invert_end of a later block of L. The
        // blocks between are the region's interior; they emit nothing of their own (eff-invert lowers
        // them) and continue in the current output block; the end's block resumes after the end.
        CallInst *E = nullptr;
        for (unsigned j = idx.lookup(b) + 1; j < L.size() && !E; ++j)
          for (Instruction &J : *L[j])
            if (auto *C = dyn_cast<CallInst>(&J);
                C && calls::classify(*C, ctx.T, ctx.S) == calls::Class::InvertEnd) {
              E = C;
              break;
            }
        if (!E)
          internalError("spine: a __cq_invert_begin with no __cq_invert_end after it", CB);
        invert::lowerRegion(ctx, *CB, *E);
        for (auto r = it; r != b->end(); ++r)
          visited.insert(&*r);
        regionEnd = E;
        return;
      }
      invert::lowerRegion(ctx, *CB, *cast<CallInst>(&*e));
      for (auto r = it; r != std::next(e); ++r)
        visited.insert(&*r);
      it = e;
      continue;
    }
    spine::dispatch(ctx, I);
    spine::ruleSixAfter(ctx, I);
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
  if (!S.F)
    internalError("spine: construct of a specialization with no function");
  ArrayRef<Specialization> all = T.specializations();
  bool inList = !all.empty() && &S >= all.begin() && &S < all.end();
  bool last = !inList || &S == &all.back();
  // Rule 27 (161): a declared specialization has no body to construct. The compiler only emits
  // declarations, and calls emits the declared clone (and its _ctl and twin declarations) at each
  // call site. The module-wide epilogue still runs when it is the last specialization.
  if (S.F->isDeclaration()) {
    if (last) {
      finishEntries(M);
      dropDeadSurface(M);
    }
    return;
  }
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

  if (last) {
    finishEntries(M);
    dropDeadSurface(M);
  }
}

} // namespace cq
