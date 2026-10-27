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
//     condition's value from the trip that exits.
// Control dependence is taint's answer (A1): compute checks that a block taint reports as not
// control-tainted gets no quantum predicate of its own, and fails loudly otherwise.
#include "PredInternal.h"

#include <tuple>

#include "cq/Common.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/Analysis/LoopInfo.h"
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
  case AtomKind::Seed: os << "seed:"; break;
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
  EdgePreds switchEdges(const SwitchInst &si) override { return sw::switchEdges(si, T, S); }
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
  case AtomKind::Seed:
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
    return m.ithVar(atomVar(AtomKind::Seed, x));
  if (const auto *bo = dyn_cast<BinaryOperator>(x); bo && isI1(bo)) {
    switch (bo->getOpcode()) {
    case Instruction::And:
      return m.andOp(expandCond(bo->getOperand(0), O), expandCond(bo->getOperand(1), O));
    case Instruction::Or:
      return m.orOp(expandCond(bo->getOperand(0), O), expandCond(bo->getOperand(1), O));
    case Instruction::Xor:
      return m.xorOp(expandCond(bo->getOperand(0), O), expandCond(bo->getOperand(1), O));
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
  if (!O.isQuantum(cond))
    return Bdd::get().ithVar(atomVar(AtomKind::Cond, cond));
  return expandCond(cond, O);
}

unsigned quantumPartNode(unsigned f, Oracle &O) {
  Bdd &m = Bdd::get();
  unsigned C = m.exists(f, [&](unsigned v) { return quantumLike(v, O); });
  if (C == Bdd::T || C == Bdd::F)
    return f;
  return m.restrict(f, C);
}

bool isClassicalNode(unsigned f, Oracle &O) {
  std::set<unsigned> sup;
  Bdd::get().support(f, sup);
  for (unsigned v : sup)
    if (quantumLike(v, O))
      return false;
  return true;
}

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
  unimplemented("pred: path predicate across this terminator", term);
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
  for (BasicBlock *bb : rpot) {
    I.rpo[bb] = idx++;
    if (bb == &F.getEntryBlock()) {
      unsigned e = entryFlag ? m.ithVar(atomVar(AtomKind::Entry, entryFlag)) : Bdd::T;
      I.blocks[bb] = makePred(e);
      continue;
    }
    const Loop *own = LI.getLoopFor(bb);
    bool isHeader = own && own->getHeader() == bb;
    unsigned acc = Bdd::F;
    SmallPtrSet<const BasicBlock *, 8> seen;
    for (const BasicBlock *p : predecessors(bb)) {
      if (!seen.insert(p).second || !reachable.count(p))
        continue;
      if (isHeader && own->contains(p))
        continue;   // back edge: the loop module chains trips
      if (!I.rpo.count(p))
        internalError("pred: a forward predecessor not yet visited (irreducible control flow reached pred)",
                      p->getTerminator());
      const Loop *out = nullptr;
      for (const Loop *L = LI.getLoopFor(p); L && !L->contains(bb); L = L->getParentLoop())
        out = L;
      unsigned contrib;
      if (out && out->getUniqueExitBlock() == bb)
        contrib = predOf(out->getHeader());
      else
        contrib = m.andOp(predOf(p), edgeCond(p, bb, O));
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
      I.edges[{bb, s}] = makePred(m.andOp(predOf(bb), edgeCond(bb, s, O)));
    }
  }
  // A1: control dependence is taint's. A block taint calls free of tainted control must not carry a
  // quantum predicate of its own (only the _ctl entry flag, which every block of a _ctl clone has).
  unsigned allowed = entryFlag ? m.ithVar(atomVar(AtomKind::Entry, entryFlag)) : Bdd::T;
  for (BasicBlock *bb : rpot) {
    unsigned q = quantumPartNode(predOf(bb), O);
    if (q != Bdd::T && q != allowed && !O.controlTainted(bb))
      internalError("pred: block has the quantum predicate " + describe(q) +
                        " but taint reports no tainted control dependence (A1)",
                    bb);
  }
}

std::vector<std::pair<unsigned, unsigned>> chainConditions(ArrayRef<unsigned> arms) {
  Bdd &m = Bdd::get();
  std::vector<std::pair<unsigned, unsigned>> out;
  unsigned ctxt = Bdd::F;
  for (unsigned a : arms)
    ctxt = m.orOp(ctxt, a);
  if (ctxt == Bdd::F)
    internalError("pred: a merge none of whose arms can be taken");
  for (unsigned i = 0; i < arms.size() && ctxt != Bdd::F; ++i) {
    unsigned c = m.restrict(arms[i], ctxt);
    unsigned rest = m.andOp(ctxt, m.notOp(arms[i]));
    if (m.andOp(ctxt, arms[i]) == Bdd::F)
      continue;   // unreachable in its context
    out.push_back({rest == Bdd::F ? unsigned(Bdd::T) : c, i});
    ctxt = rest;
  }
  if (ctxt != Bdd::F)
    internalError("pred: merge arms do not cover the merge's predicate");
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

Pred Pred::operator&(const Pred &o) const { return makePred(Bdd::get().andOp(nodeOf(*this), nodeOf(o))); }
Pred Pred::operator|(const Pred &o) const { return makePred(Bdd::get().orOp(nodeOf(*this), nodeOf(o))); }
Pred Pred::operator!() const { return makePred(Bdd::get().notOp(nodeOf(*this))); }
bool Pred::isTop() const { return nodeOf(*this) == Bdd::T; }
bool Pred::isBottom() const { return nodeOf(*this) == Bdd::F; }

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
