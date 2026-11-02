// Module pred (cq-w0-pred): Pred and PathPredicates (rule 8's path predicates).
//
// A Pred is a reduced ordered BDD over condition atoms (PredInternal.h), so two Preds are the same
// Boolean function iff they are the same node: the join after an if/else is exactly the predicate before
// it, and nested arms nest. Reference for the construction: Bennett.jl src/lowering/phi.jl (path
// predicates as Boolean functions of the branch conditions; merges as selects on them).
//
// PathPredicates::compute assigns every block the disjunction over its incoming forward edges of
// pred(from) & cond(edge), with:
//   - back edges ignored (a loop is lowered as a unit by its loop module);
//   - an edge leaving loop L for L's unique exit block contributes pred(header of L): the loop as a
//     unit always ends there (a quantum-exit loop runs its K trips, rule 14);
//   - an edge leaving a loop with several exit blocks contributes pred(from) & cond, with the
//     condition's value from the trip that exits;
//   - an edge into a dead end (no return reachable from it, taint/DeadEnd.h) does not restrict its
//     siblings (rule 16: after a noreturn arm the program continues uncontrolled; 49: with the
//     unreachable default gone, the last case is the complement). The last live successor of a
//     branch with a dead-end successor takes the complement of its other live successors' conditions;
//     the dead end keeps its own edge's predicate (eff-tape's abort flag). A loop exit into a dead
//     end is not one of the loop's ends: the loop's live exits partition its predicate.
// Control dependence is taint's answer (A1): compute checks that a block taint reports as not
// control-tainted gets no quantum predicate of its own, and fails loudly otherwise.
#include "PredInternal.h"
#include "../taint/DeadEnd.h"

#include <tuple>

#include "cq/Common.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq {
namespace pred_detail {

namespace {
struct AtomRegistry {
  std::vector<Atom> atoms;
  std::map<std::tuple<int, const Value *, unsigned, std::string>, unsigned> index;
  static AtomRegistry &get() {
    static AtomRegistry r;
    return r;
  }
};
} // namespace

unsigned atomVar(AtomKind k, const Value *v, const APInt &c) {
  if (!v)
    internalError("pred: an atom of a null value");
  AtomRegistry &R = AtomRegistry::get();
  auto key = std::make_tuple(int(k), v, c.getBitWidth(), c.getBitWidth() ? llvm::toString(c, 16, false) : std::string());
  auto it = R.index.find(key);
  if (it != R.index.end())
    return it->second;
  unsigned var = unsigned(R.atoms.size());
  R.atoms.push_back({k, v, c});
  R.index.emplace(key, var);
  return var;
}

const Atom &atomOf(unsigned var) {
  AtomRegistry &R = AtomRegistry::get();
  if (var >= R.atoms.size())
    internalError("pred: unknown atom variable " + std::to_string(var));
  return R.atoms[var];
}

static std::string atomName(unsigned var) {
  const Atom &a = atomOf(var);
  std::string s;
  raw_string_ostream os(s);
  switch (a.kind) {
  case AtomKind::Cond: break;
  case AtomKind::Eq: os << "eq:"; break;
  case AtomKind::Entry: os << "entry:"; break;
  }
  a.v->printAsOperand(os, false);
  if (a.kind == AtomKind::Eq)
    os << "==" << llvm::toString(a.c, 10, true);
  return os.str();
}

std::string describe(unsigned f) {
  Bdd &m = Bdd::get();
  if (f == Bdd::F)
    return "0";
  if (f == Bdd::T)
    return "1";
  std::string v = atomName(m.var(f));
  unsigned l = m.lo(f), h = m.hi(f);
  if (l == Bdd::F && h == Bdd::T)
    return v;
  if (l == Bdd::T && h == Bdd::F)
    return "!" + v;
  if (l == Bdd::F)
    return "(" + v + " & " + describe(h) + ")";
  if (h == Bdd::F)
    return "(!" + v + " & " + describe(l) + ")";
  if (h == Bdd::T)
    return "(" + v + " | " + describe(l) + ")";
  if (l == Bdd::T)
    return "(!" + v + " | " + describe(h) + ")";
  return "(" + v + " ? " + describe(h) + " : " + describe(l) + ")";
}

namespace {
class TaintOracle final : public Oracle {
  const TaintInfo &T;
  const Specialization &S;

public:
  TaintOracle(const TaintInfo &T, const Specialization &S) : T(T), S(S) {}
  bool isQuantum(const Value *v) override { return T.isQuantum(v, S); }
  bool controlTainted(const BasicBlock *b) override { return T.controlTainted(b, S); }
  bool deadEnd(const BasicBlock *b) override {
    const Function *F = b->getParent();
    if (F != deadOf) {
      dead = taint_detail::DeadEnds(*F);
      deadOf = F;
    }
    return dead.isDeadEnd(b);
  }
  EdgePreds switchEdges(const SwitchInst &si) override { return sw::switchEdges(si, T, S); }

private:
  const Function *deadOf = nullptr;
  taint_detail::DeadEnds dead;
};
} // namespace

std::unique_ptr<Oracle> taintOracle(const TaintInfo &T, const Specialization &S) {
  return std::make_unique<TaintOracle>(T, S);
}

bool quantumLike(unsigned var, Oracle &O) {
  const Atom &a = atomOf(var);
  switch (a.kind) {
  case AtomKind::Cond:
  case AtomKind::Eq:
    return O.isQuantum(a.v);
  case AtomKind::Entry:
    return true;
  }
  internalError("pred: atom kind");
}

static bool isI1(const Value *v) { return v->getType()->isIntegerTy(1); }

static unsigned expandCond(const Value *x, Oracle &O) {
  Bdd &m = Bdd::get();
  if (const auto *ci = dyn_cast<ConstantInt>(x))
    return ci->isOne() ? Bdd::T : Bdd::F;
  if (!O.isQuantum(x))
    return m.ithVar(atomVar(AtomKind::Cond, x));   // a classical leaf: factored out or seeded (rule 8)
  if (const auto *bo = dyn_cast<BinaryOperator>(x); bo && isI1(bo)) {
    switch (bo->getOpcode()) {
    case Instruction::And:
      return m.andOp(expandCond(bo->getOperand(0), O), expandCond(bo->getOperand(1), O));
    case Instruction::Or:
      return m.orOp(expandCond(bo->getOperand(0), O), expandCond(bo->getOperand(1), O));
    case Instruction::Xor:
      // Only a negation (xor with true) is a connective; a data xor is an atom: it never has a
      // classical conjunct, and its own rail is the flag (180's c ^ m1).
      if (const auto *k = dyn_cast<ConstantInt>(bo->getOperand(1)); k && k->isOne())
        return m.notOp(expandCond(bo->getOperand(0), O));
      if (const auto *k = dyn_cast<ConstantInt>(bo->getOperand(0)); k && k->isOne())
        return m.notOp(expandCond(bo->getOperand(1), O));
      break;
    default:
      break;
    }
  }
  if (const auto *si = dyn_cast<SelectInst>(x); si && isI1(si) && isI1(si->getCondition())) {
    unsigned c = expandCond(si->getCondition(), O);
    unsigned t = expandCond(si->getTrueValue(), O);
    unsigned f = expandCond(si->getFalseValue(), O);
    return m.ite(c, t, f);
  }
  return m.ithVar(atomVar(AtomKind::Cond, x));
}

unsigned condNode(const Value *cond, Oracle &O) {
  if (!isI1(cond))
    internalError("pred: a branch condition that is not i1", cond);
  if (const auto *ci = dyn_cast<ConstantInt>(cond))
    return ci->isOne() ? Bdd::T : Bdd::F;
  Bdd &m = Bdd::get();
  unsigned whole = m.ithVar(atomVar(AtomKind::Cond, cond));
  if (!O.isQuantum(cond))
    return whole;
  // The expansion is needed only to factor (rule 8): when neither edge's function has a classical
  // conjunct, the condition is one atom and its own rail (the spine's data template) is the flag.
  unsigned f = expandCond(cond, O);
  if (classicalFactorNode(f, O) == Bdd::T && classicalFactorNode(m.notOp(f), O) == Bdd::T)
    return whole;
  return f;
}

// Rule 8 (CQ_spec a46894a, freeze cq-6yb): P == C & Q on the Boolean function. C is the conjunction of
// every classical literal P implies (a classical conjunct of the whole condition, however -O1 spelled
// it); Q is P cofactored on each of them, the unfactorable rest. A classical atom left in Q (c || q)
// is a seed rail of the one flag.
static std::pair<unsigned, unsigned> factor(unsigned f, Oracle &O) {
  Bdd &m = Bdd::get();
  if (m.terminal(f))
    return {Bdd::T, f};
  if (isClassicalNode(f, O))
    return {f, Bdd::T};   // a classical predicate is its own classical factor: no flag
  std::set<unsigned> sup;
  m.support(f, sup);
  unsigned C = Bdd::T;
  for (unsigned v : sup) {
    if (quantumLike(v, O))
      continue;
    unsigned x = m.ithVar(v);
    if (m.andOp(f, m.notOp(x)) == Bdd::F) {
      C = m.andOp(C, x);
      f = m.cofactor(f, v, true);
    } else if (m.andOp(f, x) == Bdd::F) {
      C = m.andOp(C, m.notOp(x));
      f = m.cofactor(f, v, false);
    }
  }
  return {C, f};
}

unsigned classicalFactorNode(unsigned f, Oracle &O) { return factor(f, O).first; }
unsigned quantumPartNode(unsigned f, Oracle &O) { return factor(f, O).second; }

bool isClassicalNode(unsigned f, Oracle &O) {
  std::set<unsigned> sup;
  Bdd::get().support(f, sup);
  for (unsigned v : sup)
    if (quantumLike(v, O))
      return false;
  return true;
}

} // namespace pred_detail

// CR rule 13 (ruling 2026-11-02): a computed goto is a switch over its destination list whose scrutinee is the
// integer the target address was derived from. The address is followed back to that integer: a `blockaddress`
// constant is its destination; a select chooses by its condition (rule 9); a load of a constant `blockaddress`
// table at an index (a QROM of the table, rule 20) is the case `index == k` for each entry k naming the
// destination.
std::optional<GotoTableRead> gotoTableRead(const Value *a) {
  auto *ld = dyn_cast<LoadInst>(a->stripPointerCasts());
  if (!ld || !ld->isSimple())
    return std::nullopt;
  auto *g = dyn_cast<GEPOperator>(ld->getPointerOperand());
  if (!g)
    return std::nullopt;
  auto *gv = dyn_cast<GlobalVariable>(g->getPointerOperand()->stripPointerCasts());
  if (!gv || !gv->isConstant() || !gv->hasDefinitiveInitializer())
    return std::nullopt;
  auto *arr = dyn_cast<ConstantArray>(gv->getInitializer());
  if (!arr || !arr->getType()->getElementType()->isPointerTy())
    return std::nullopt;
  // The one variable index, scaled by the entry size, with every other offset 0.
  const DataLayout &DL = ld->getModule()->getDataLayout();
  const Value *idx = nullptr;
  uint64_t esz = DL.getTypeAllocSize(arr->getType()->getElementType());
  for (gep_type_iterator it = gep_type_begin(g), e = gep_type_end(g); it != e; ++it) {
    const Value *o = it.getOperand();
    if (auto *ci = dyn_cast<ConstantInt>(o)) {
      if (!ci->isZero())
        return std::nullopt;
      continue;
    }
    if (idx || it.isStruct() || DL.getTypeAllocSize(it.getIndexedType()) != esz)
      return std::nullopt;
    idx = o;
  }
  if (!idx || !idx->getType()->isIntegerTy())
    return std::nullopt;
  // The integer beneath a widening of the index (rule 20: the widening is address arithmetic, never
  // emitted): entry k is read where that integer is k, for the k it can hold.
  uint64_t n = arr->getNumOperands();
  while (auto *ext = dyn_cast<CastInst>(idx)) {
    if (!isa<ZExtInst>(ext) && !isa<SExtInst>(ext))
      break;
    unsigned w = ext->getSrcTy()->getIntegerBitWidth() - (isa<SExtInst>(ext) ? 1 : 0);
    if (w < 64)
      n = std::min<uint64_t>(n, uint64_t(1) << w);
    idx = ext->getOperand(0);
  }
  GotoTableRead t{idx, {}};
  for (unsigned k = 0; k < n; ++k) {
    auto *ba = dyn_cast<BlockAddress>(arr->getOperand(k)->stripPointerCasts());
    t.entries.push_back(ba ? ba->getBasicBlock() : nullptr);
  }
  return t;
}

// A `blockaddress` names a block of the function it was taken in; a specialization of that function (a
// clone, §1.4) has the same blocks in the same order, so the destination is the block at the same position.
static const BasicBlock *destIn(const BasicBlock *d, const Function &F) {
  if (!d || d->getParent() == &F)
    return d;
  auto it = F.begin();
  for (const BasicBlock &b : *d->getParent()) {
    if (it == F.end())
      internalError("pred: a computed goto destination with no block of the specialization", &*F.begin()->begin());
    if (&b == d)
      return &*it;
    ++it;
  }
  internalError("pred: a computed goto destination outside its own function", &*F.begin()->begin());
}

static bool addressCases(const Value *a, const Pred &under, const Function &F,
                         SmallVectorImpl<std::pair<Pred, const BasicBlock *>> &cases) {
  a = a->stripPointerCasts();
  if (auto *ba = dyn_cast<BlockAddress>(a)) {
    cases.push_back({under, destIn(ba->getBasicBlock(), F)});
    return true;
  }
  if (auto *sel = dyn_cast<SelectInst>(a)) {
    Pred c = Pred::atom(sel->getCondition());
    return addressCases(sel->getTrueValue(), under & c, F, cases) &&
           addressCases(sel->getFalseValue(), under & !c, F, cases);
  }
  if (std::optional<GotoTableRead> t = gotoTableRead(a)) {
    for (unsigned k = 0; k < t->entries.size(); ++k)
      if (t->entries[k])
        cases.push_back({under & Pred::eqAtom(t->index, APInt(t->index->getType()->getIntegerBitWidth(), k)),
                         destIn(t->entries[k], F)});
    return true;
  }
  return false;
}

std::optional<SmallVector<std::pair<Pred, const BasicBlock *>, 4>> computedGotoCases(const IndirectBrInst &ib) {
  SmallVector<std::pair<Pred, const BasicBlock *>, 4> cases;
  if (!addressCases(ib.getAddress(), Pred::top(), *ib.getFunction(), cases))
    return std::nullopt;
  return cases;
}

namespace pred_detail {

// The condition under which the terminator of `from` transfers control to `to`.
static unsigned edgeCond(const BasicBlock *from, const BasicBlock *to, Oracle &O) {
  Bdd &m = Bdd::get();
  const Instruction *term = from->getTerminator();
  if (const auto *br = dyn_cast<BranchInst>(term)) {
    if (br->isUnconditional())
      return Bdd::T;
    unsigned c = condNode(br->getCondition(), O);
    unsigned r = Bdd::F;
    if (br->getSuccessor(0) == to)
      r = m.orOp(r, c);
    if (br->getSuccessor(1) == to)
      r = m.orOp(r, m.notOp(c));
    return r;
  }
  if (const auto *si = dyn_cast<SwitchInst>(term)) {
    unsigned r = Bdd::F;
    if (O.isQuantum(si->getCondition())) {
      // Rule 13 is the switch module's (A3: eqAtom flags, the default as the complement).
      EdgePreds ep = O.switchEdges(*si);
      bool seen = false;
      for (auto &[bb, p] : ep.succ)
        if (bb == to) {
          r = m.orOp(r, nodeOf(p));
          seen = true;
        }
      if (!seen)
        internalError("pred: sw::switchEdges gave no predicate for a successor", term);
      return r;
    }
    // A classical switch stays a classical switch: its edges are classical guards.
    unsigned noCase = Bdd::T;
    for (const auto &c : si->cases()) {
      unsigned eq = m.ithVar(atomVar(AtomKind::Eq, si->getCondition(), c.getCaseValue()->getValue()));
      if (c.getCaseSuccessor() == to)
        r = m.orOp(r, eq);
      noCase = m.andOp(noCase, m.notOp(eq));
    }
    if (si->getDefaultDest() == to)
      r = m.orOp(r, noCase);
    return r;
  }
  if (const auto *ib = dyn_cast<IndirectBrInst>(term)) {
    std::optional<SmallVector<std::pair<Pred, const BasicBlock *>, 4>> cases = computedGotoCases(*ib);
    if (!cases)
      unimplemented("pred: a computed goto whose address is not derived from an integer through blockaddress "
                    "constants, selects and constant blockaddress tables (SPEC_ISSUES: the integer a computed "
                    "goto's address is derived from)",
                    term);
    unsigned r = Bdd::F;
    for (auto &[p, d] : *cases)
      if (d == to)
        r = m.orOp(r, nodeOf(p));
    return r;
  }
  unimplemented("pred: path predicate across this terminator", term);
}

// edgeCond with dead ends (cq-820w): an edge between two live blocks out of a branch that also has a
// dead-end successor; the last live successor in successor order takes the complement of the other
// live successors' conditions, so the dead ends' share falls to it.
static unsigned liveEdgeCond(const BasicBlock *from, const BasicBlock *to, Oracle &O) {
  if (O.deadEnd(from) || O.deadEnd(to))
    return edgeCond(from, to, O);
  SmallVector<const BasicBlock *, 4> live;
  bool anyDead = false;
  for (const BasicBlock *s : successors(from)) {
    if (O.deadEnd(s))
      anyDead = true;
    else if (llvm::find(live, s) == live.end())
      live.push_back(s);
  }
  if (!anyDead || live.back() != to)
    return edgeCond(from, to, O);
  Bdd &m = Bdd::get();
  unsigned others = Bdd::F;
  for (const BasicBlock *s : live)
    if (s != to)
      others = m.orOp(others, edgeCond(from, s, O));
  return m.notOp(others);
}

void computePaths(PathStorage &I, Function &F, const LoopInfo &LI, Oracle &O, Value *entryFlag) {
  Bdd &m = Bdd::get();
  I = PathStorage();
  I.F = &F;
  I.entryFlag = entryFlag;
  for (const BasicBlock &bb : F)
    I.blocks[&bb] = makePred(Bdd::F);
  for (const Loop *L : LI.getLoopsInPreorder())
    I.loopHeaders.insert(L->getHeader());

  ReversePostOrderTraversal<Function *> rpot(&F);
  SmallPtrSet<const BasicBlock *, 32> reachable;
  for (BasicBlock *bb : rpot)
    reachable.insert(bb);

  auto predOf = [&](const BasicBlock *b) { return nodeOf(I.blocks[b]); };
  unsigned idx = 0;
  for (BasicBlock *bb : rpot)
    I.rpo[bb] = idx++;

  // The outermost loop an edge p -> bb leaves (null when it leaves none).
  auto leftLoop = [&](const BasicBlock *p, const BasicBlock *bb) {
    const Loop *out = nullptr;
    for (const Loop *L = LI.getLoopFor(p); L && !L->contains(bb); L = L->getParentLoop())
      out = L;
    return out;
  };
  auto isBackEdge = [&](const BasicBlock *p, const BasicBlock *bb) {
    const Loop *own = LI.getLoopFor(bb);
    return own && own->getHeader() == bb && own->contains(p);
  };

  // Evaluation order: a topological order of the forward edges, in which an exit block of a loop with
  // several exit blocks also waits for every block of that loop (its exit edges are evaluated
  // together, below). RPO is not enough: a reducible CFG's RPO may place an exit block before a loop
  // body block.
  DenseMap<const BasicBlock *, SmallVector<const BasicBlock *, 8>> deps;
  for (BasicBlock *bb : rpot) {
    SmallPtrSet<const BasicBlock *, 8> seen;
    for (const BasicBlock *p : predecessors(bb)) {
      if (!reachable.count(p) || isBackEdge(p, bb) || !seen.insert(p).second)
        continue;
      deps[bb].push_back(p);
      if (const Loop *out = leftLoop(p, bb); out && !out->getUniqueExitBlock())
        for (const BasicBlock *lb : out->blocks())
          if (seen.insert(lb).second)
            deps[bb].push_back(lb);
    }
  }
  std::vector<BasicBlock *> order;
  {
    SmallPtrSet<const BasicBlock *, 32> done;
    std::vector<BasicBlock *> todo(rpot.begin(), rpot.end());
    while (!todo.empty()) {
      bool progress = false;
      for (auto it = todo.begin(); it != todo.end();) {
        bool ready = true;
        for (const BasicBlock *d : deps[*it])
          ready &= done.count(d) > 0;
        if (ready) {
          done.insert(*it);
          order.push_back(*it);
          it = todo.erase(it);
          progress = true;
        } else {
          ++it;
        }
      }
      if (!progress)
        internalError("pred: no topological order of the forward edges (irreducible control flow reached pred)",
                      todo.front());
    }
  }

  // A loop with several exit blocks ends through exactly one exit edge, and it does end (a quantum
  // exit runs its K trips, rule 14), so its exit edges partition the loop's predicate: exit edge e
  // contributes pred(header) & X_e, where X_e is e's condition within the exiting trip, relative to
  // the header, minus the earlier exit edges', and the last exit edge takes the rest. A join every
  // exit reaches then gets the loop's predicate back (121's block %29; control dependence is
  // post-dominance, A1).
  // The loop's unique exit block once exits into dead ends are set aside (null when several remain).
  auto liveUniqueExit = [&](const Loop *L) -> const BasicBlock * {
    SmallVector<BasicBlock *, 4> exitBlocks;
    L->getUniqueExitBlocks(exitBlocks);
    const BasicBlock *one = nullptr;
    for (const BasicBlock *e : exitBlocks) {
      if (O.deadEnd(e) && !O.deadEnd(L->getHeader()))
        continue;
      if (one)
        return nullptr;
      one = e;
    }
    return one;
  };
  std::map<const Loop *, std::map<std::pair<const BasicBlock *, const BasicBlock *>, unsigned>> exitShare;
  auto exitContribution = [&](const Loop *L, const BasicBlock *p, const BasicBlock *bb) {
    auto &shares = exitShare[L];
    if (shares.empty()) {
      SmallVector<std::pair<BasicBlock *, BasicBlock *>, 8> exits;
      L->getExitEdges(exits);
      std::vector<std::pair<const BasicBlock *, const BasicBlock *>> edgesInOrder;
      for (auto &e : exits)
        if (reachable.count(e.first) && (O.deadEnd(L->getHeader()) || !O.deadEnd(e.second)) &&
            std::find(edgesInOrder.begin(), edgesInOrder.end(), std::make_pair((const BasicBlock *)e.first, (const BasicBlock *)e.second)) == edgesInOrder.end())
          edgesInOrder.push_back({e.first, e.second});
      std::stable_sort(edgesInOrder.begin(), edgesInOrder.end(), [&](auto &x, auto &y) {
        return std::make_pair(I.rpo[x.first], I.rpo[x.second]) < std::make_pair(I.rpo[y.first], I.rpo[y.second]);
      });
      unsigned h = predOf(L->getHeader()), covered = Bdd::F;
      for (size_t i = 0; i < edgesInOrder.size(); ++i) {
        auto [ep, eb] = edgesInOrder[i];
        unsigned x;
        if (i + 1 == edgesInOrder.size()) {
          x = m.notOp(covered);
        } else {
          unsigned d = m.restrict(m.andOp(predOf(ep), liveEdgeCond(ep, eb, O)), h);
          x = m.andOp(d, m.notOp(covered));
        }
        covered = m.orOp(covered, x);
        shares[{ep, eb}] = m.andOp(h, x);
      }
    }
    auto it = shares.find({p, bb});
    if (it == shares.end())
      internalError("pred: an exit edge missing from its loop's exit edges", p->getTerminator());
    return it->second;
  };

  for (BasicBlock *bb : order) {
    if (bb == &F.getEntryBlock()) {
      unsigned e = entryFlag ? m.ithVar(atomVar(AtomKind::Entry, entryFlag)) : Bdd::T;
      I.blocks[bb] = makePred(e);
      continue;
    }
    unsigned acc = Bdd::F;
    SmallPtrSet<const BasicBlock *, 8> seen;
    for (const BasicBlock *p : predecessors(bb)) {
      if (!seen.insert(p).second || !reachable.count(p) || isBackEdge(p, bb))
        continue;   // a back edge: the loop module chains trips
      unsigned contrib;
      const Loop *out = leftLoop(p, bb);
      if (out && O.deadEnd(bb) && !O.deadEnd(p))
        contrib = m.andOp(predOf(p), edgeCond(p, bb, O));   // a loop exit into a dead end
      else if (out && liveUniqueExit(out) == bb)
        contrib = predOf(out->getHeader());
      else if (out)
        contrib = exitContribution(out, p, bb);
      else
        contrib = m.andOp(predOf(p), liveEdgeCond(p, bb, O));
      I.edges[{p, bb}] = makePred(contrib);
      acc = m.orOp(acc, contrib);
    }
    I.blocks[bb] = makePred(acc);
  }
  // Every remaining edge out of a reachable block (back edges included).
  for (BasicBlock *bb : rpot) {
    SmallPtrSet<const BasicBlock *, 8> seen;
    for (const BasicBlock *s : successors(bb)) {
      if (!seen.insert(s).second || I.edges.count({bb, s}))
        continue;
      I.edges[{bb, s}] = makePred(m.andOp(predOf(bb), liveEdgeCond(bb, s, O)));
    }
  }
  // A1: control dependence is taint's. A block taint calls free of tainted control must not carry a
  // quantum predicate of its own (only the _ctl entry flag, which every block of a _ctl clone has).
  for (BasicBlock *bb : rpot) {
    unsigned q = quantumPartNode(predOf(bb), O);
    std::set<unsigned> sup;
    m.support(q, sup);
    bool quantumOwn = false;   // a quantum atom other than the _ctl entry flag
    for (unsigned v : sup)
      quantumOwn |= atomOf(v).kind != AtomKind::Entry && quantumLike(v, O);
    if (quantumOwn && !O.controlTainted(bb))
      internalError("pred: block has the quantum predicate " + describe(q) +
                        " but taint reports no tainted control dependence (A1)",
                    bb);
  }
}

namespace {
// One level of selectTree over the arms live in ctxt; returns the node's index in out.
int buildSelect(std::vector<SelectNode> &out, ArrayRef<unsigned> arms, unsigned ctxt) {
  Bdd &m = Bdd::get();
  auto literal = [&](unsigned n) { return !m.terminal(n) && m.terminal(m.lo(n)) && m.terminal(m.hi(n)); };
  auto leaf = [&](unsigned i) {
    out.push_back(SelectNode{Bdd::T, int(i), -1, -1});
    return int(out.size() - 1);
  };
  auto node = [&](unsigned cond) {
    out.push_back(SelectNode{cond, -1, -1, -1});
    return int(out.size() - 1);
  };
  std::vector<unsigned> live;
  for (unsigned i = 0; i < arms.size(); ++i)
    if (m.andOp(ctxt, arms[i]) != Bdd::F)
      live.push_back(i);
  if (live.empty())
    internalError("pred: merge arms do not cover the merge's predicate");
  // An arm taken on every path of the context is the complement arm (innermost); the others are
  // unreachable here and dropped.
  for (unsigned i : live)
    if (m.andOp(ctxt, m.notOp(arms[i])) == Bdd::F)
      return leaf(i);
  // A chain step: the first arm (in the caller's order) one literal separates from the rest in the
  // context, so an if/else chain is single compares (104) and nested arms nest (158).
  for (unsigned i : live) {
    unsigned c = m.restrict(arms[i], ctxt);
    if (literal(c)) {
      int n = node(c);
      int t = leaf(i);
      int e = buildSelect(out, arms, m.andOp(ctxt, m.notOp(arms[i])));
      out[n].thenIdx = t;
      out[n].elseIdx = e;
      return n;
    }
  }
  // A split: a literal every live arm lies on one side of, with arms on both sides (two-sided nested
  // value arms, cq-95k8). The select on it nests a select tree per side; rule 9: nested arms nest,
  // never a conjunction flag for a pure select. The side of the first live arm is the true side.
  std::set<unsigned> sup;
  for (unsigned i : live)
    m.support(m.restrict(arms[i], ctxt), sup);
  for (unsigned v : sup) {
    unsigned lit = m.ithVar(v);
    bool pos = false, neg = false, splits = true;
    for (unsigned i : live) {
      unsigned a = m.andOp(ctxt, arms[i]);
      bool p = m.andOp(a, lit) != Bdd::F, q = m.andOp(a, m.notOp(lit)) != Bdd::F;
      if (p && q) {
        splits = false;
        break;
      }
      pos |= p;
      neg |= q;
    }
    if (!splits || !pos || !neg)
      continue;
    unsigned cond = m.andOp(m.andOp(ctxt, arms[live[0]]), lit) != Bdd::F ? lit : m.notOp(lit);
    int n = node(cond);
    int t = buildSelect(out, arms, m.andOp(ctxt, cond));
    int e = buildSelect(out, arms, m.andOp(ctxt, m.notOp(cond)));
    out[n].thenIdx = t;
    out[n].elseIdx = e;
    return n;
  }
  // No literal separates the arms (an arm whose predicate is a compound condition of one branch, as
  // for a && b): the first live arm's condition in the context.
  unsigned i = live[0];
  int n = node(m.restrict(arms[i], ctxt));
  int t = leaf(i);
  int e = buildSelect(out, arms, m.andOp(ctxt, m.notOp(arms[i])));
  out[n].thenIdx = t;
  out[n].elseIdx = e;
  return n;
}
} // namespace

std::vector<SelectNode> selectTree(ArrayRef<unsigned> arms) {
  Bdd &m = Bdd::get();
  unsigned ctxt = Bdd::F;
  for (unsigned a : arms)
    ctxt = m.orOp(ctxt, a);
  if (ctxt == Bdd::F)
    internalError("pred: a merge none of whose arms can be taken");
  std::vector<SelectNode> out;
  if (buildSelect(out, arms, ctxt) != 0)
    internalError("pred: selectTree's root is not its first node");
  return out;
}

std::optional<unsigned> negatedAtom(unsigned f, const std::function<bool(unsigned)> &ql) {
  Bdd &m = Bdd::get();
  if (!m.terminal(f) && m.lo(f) == Bdd::T && m.hi(f) == Bdd::F && ql(m.var(f)))
    return m.var(f);
  return std::nullopt;
}

} // namespace pred_detail

using namespace pred_detail;

// ---- Pred ----

namespace pred_detail {
unsigned nodeOf(const Pred &p) {
  const auto &impl = p.*member(PredTag{});
  if (!impl)
    internalError("pred: use of an uninitialised Pred");
  return impl->n;
}

Pred makePred(unsigned node) {
  Pred p;
  p.*member(PredTag{}) = std::make_shared<const PredStorage>(PredStorage{node});
  return p;
}

PathStorage &storage(PathPredicates &pp) {
  auto &impl = pp.*member(PathTag{});
  if (!impl)
    internalError("pred: PathPredicates without storage");
  return *impl;
}
} // namespace pred_detail

Pred Pred::top() { return makePred(Bdd::T); }
Pred Pred::bottom() { return makePred(Bdd::F); }

Pred Pred::atom(const Value *cond) {
  if (!cond || !isI1(cond))
    internalError("pred: Pred::atom of a value that is not i1", cond);
  if (const auto *ci = dyn_cast<ConstantInt>(cond))
    return ci->isOne() ? top() : bottom();
  return makePred(Bdd::get().ithVar(atomVar(AtomKind::Cond, cond)));
}

Pred Pred::eqAtom(const Value *scrutinee, const APInt &v) {
  if (!scrutinee || !scrutinee->getType()->isIntegerTy() ||
      scrutinee->getType()->getIntegerBitWidth() != v.getBitWidth())
    internalError("pred: Pred::eqAtom width mismatch", scrutinee);
  if (const auto *ci = dyn_cast<ConstantInt>(scrutinee))
    return ci->getValue() == v ? top() : bottom();
  return makePred(Bdd::get().ithVar(atomVar(AtomKind::Eq, scrutinee, v)));
}

bool predsMeet(const Pred &a, const Pred &b) {
  Bdd &m = Bdd::get();
  unsigned f = m.andOp(nodeOf(a), nodeOf(b));
  if (f == Bdd::F)
    return false;
  std::set<unsigned> sup;
  m.support(f, sup);
  std::vector<unsigned> eqs(sup.begin(), sup.end());
  for (size_t i = 0; i < eqs.size() && f != Bdd::F; ++i)
    for (size_t j = i + 1; j < eqs.size() && f != Bdd::F; ++j) {
      const Atom &x = atomOf(eqs[i]), &y = atomOf(eqs[j]);
      if (x.kind == AtomKind::Eq && y.kind == AtomKind::Eq && x.v == y.v && x.c != y.c)
        f = m.andOp(f, m.notOp(m.andOp(m.ithVar(eqs[i]), m.ithVar(eqs[j]))));
    }
  return f != Bdd::F;
}

Pred Pred::operator&(const Pred &o) const { return makePred(Bdd::get().andOp(nodeOf(*this), nodeOf(o))); }
Pred Pred::operator|(const Pred &o) const { return makePred(Bdd::get().orOp(nodeOf(*this), nodeOf(o))); }
Pred Pred::operator!() const { return makePred(Bdd::get().notOp(nodeOf(*this))); }
bool Pred::isTop() const { return nodeOf(*this) == Bdd::T; }
bool Pred::isBottom() const { return nodeOf(*this) == Bdd::F; }

Pred Pred::classicalFactor(const TaintInfo &T, const Specialization &S) const {
  auto O = taintOracle(T, S);
  return makePred(classicalFactorNode(nodeOf(*this), *O));
}

Pred Pred::quantumPart(const TaintInfo &T, const Specialization &S) const {
  auto O = taintOracle(T, S);
  return makePred(quantumPartNode(nodeOf(*this), *O));
}

bool Pred::isClassical(const TaintInfo &T, const Specialization &S) const {
  auto O = taintOracle(T, S);
  return isClassicalNode(nodeOf(*this), *O);
}

// ---- PathPredicates ----


PathPredicates::PathPredicates() : impl(std::make_shared<Impl>()) {}

void PathPredicates::compute(Function &F, const LoopInfo &LI, const TaintInfo &T, const Specialization &S,
                             Value *entryFlag) {
  auto O = taintOracle(T, S);
  computePaths(*impl, F, LI, *O, entryFlag);
}

const Pred &PathPredicates::block(const BasicBlock *b) const {
  if (!impl->F)
    internalError("pred: PathPredicates::block before compute");
  auto it = impl->blocks.find(b);
  if (it == impl->blocks.end())
    internalError("pred: PathPredicates::block of a block outside the computed function", b);
  return it->second;
}

const Pred &PathPredicates::edge(const BasicBlock *from, const BasicBlock *to) const {
  if (!impl->F)
    internalError("pred: PathPredicates::edge before compute");
  auto it = impl->edges.find({from, to});
  if (it == impl->edges.end())
    internalError("pred: PathPredicates::edge of a pair that is no reachable CFG edge", from);
  return it->second;
}

} // namespace cq
