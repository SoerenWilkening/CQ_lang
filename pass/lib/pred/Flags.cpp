// Module pred (cq-w0-pred): flags (rule 8), value-arm merges (rule 9), phases (rule 12), branches.
//
// Contracts this file relies on (recorded on bead cq-w0-pred; the spine and uncompute implement them):
//   - LoweringContext::emitTemplate emits the forward template AND records it (recordTemplate);
//     emitCore only emits. pred records its own core gates: recordSeed for every alloc it emits,
//     recordCore(gate, spec, controls, idOf(target)) for every XOR-into-target gate of a flag.
//   - Uncompute::noteUse(rail, consumer) takes a consumer instruction of the ORIGINAL function (the
//     same point space as flushBefore). lowerBranch notes, for every quantum atom of the condition,
//     each original instruction that reads it through a predicate.
//   - A flag minted here has no original value; it is due at the first flush after the instruction
//     whose lowering minted it (it is minted at its use and torn down after it, CR §5).
#include "PredInternal.h"

#include "cq/Common.h"
#include "cq/Rotation.h"
#include "llvm/IR/Constants.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq {
namespace pred_detail {

Value *materialize(unsigned node, GateSink &sink, const std::function<bool(unsigned)> &ql) {
  Bdd &m = Bdd::get();
  std::map<unsigned, Value *> memo, atoms;

  auto classical = [&](unsigned n) {
    std::set<unsigned> sup;
    m.support(n, sup);
    for (unsigned v : sup)
      if (ql(v))
        return false;
    return true;
  };
  auto atomRail = [&](unsigned v) {
    auto it = atoms.find(v);
    if (it != atoms.end())
      return it->second;
    return atoms[v] = sink.atomRail(v);
  };

  std::function<Value *(unsigned)> mat;
  std::function<void(Value *, unsigned)> into;

  mat = [&](unsigned n) -> Value * {
    if (m.terminal(n))
      internalError("pred: a flag for a constant predicate");
    auto it = memo.find(n);
    if (it != memo.end())
      return it->second;
    Value *r;
    if (classical(n))
      r = sink.classicalSeed(n);
    else if (m.lo(n) == Bdd::F && m.hi(n) == Bdd::T)
      r = atomRail(m.var(n));
    else {
      r = sink.alloc0();
      into(r, n);
    }
    return memo[n] = r;
  };

  // t ^= n, by XOR-into-t gates only.
  into = [&](Value *t, unsigned n) {
    if (n == Bdd::F)
      return;
    if (n == Bdd::T) {
      sink.gate(abi::Core::NotI1, {}, t);
      return;
    }
    if (classical(n)) {
      sink.gate(abi::Core::XorI1, {mat(n)}, t);
      return;
    }
    // Shannon on the latest quantum-like atom: the innermost condition, so a nested predicate is its
    // parent's flag joined with the inner condition (08, 137).
    std::set<unsigned> sup;
    m.support(n, sup);
    unsigned v = 0;
    bool found = false;
    for (unsigned s : sup)
      if (ql(s)) {
        v = s;
        found = true;
      }
    if (!found)
      internalError("pred: flag synthesis lost its quantum atom");
    unsigned f0 = m.cofactor(n, v, false), f1 = m.cofactor(n, v, true);
    Value *V = atomRail(v);
    if (f0 == Bdd::F) {                       // v & f1
      if (f1 == Bdd::T)
        sink.gate(abi::Core::XorI1, {V}, t);
      else
        sink.gate(abi::Core::AndI1, {V, mat(f1)}, t);
    } else if (f1 == Bdd::F) {                // !v & f0 = f0 ^ (v & f0)
      if (f0 == Bdd::T) {
        sink.gate(abi::Core::NotI1, {}, t);
        sink.gate(abi::Core::XorI1, {V}, t);
      } else {
        Value *G = mat(f0);
        sink.gate(abi::Core::XorI1, {G}, t);
        sink.gate(abi::Core::AndI1, {G, V}, t);
      }
    } else if (f0 == Bdd::T) {                // !v | f1 = 1 ^ (v & !f1)
      sink.gate(abi::Core::NotI1, {}, t);
      unsigned h = m.notOp(f1);
      if (h == Bdd::T)
        sink.gate(abi::Core::XorI1, {V}, t);
      else
        sink.gate(abi::Core::AndI1, {V, mat(h)}, t);
    } else if (f1 == Bdd::T) {                // v | f0
      sink.gate(abi::Core::OrI1, {V, mat(f0)}, t);
    } else {                                  // f0 ^ (v & (f0 ^ f1))
      into(t, f0);
      unsigned d = m.xorOp(f0, f1);
      if (d == Bdd::T)
        sink.gate(abi::Core::XorI1, {V}, t);
      else
        sink.gate(abi::Core::AndI1, {V, mat(d)}, t);
    }
  };

  return mat(node);
}

namespace {

RailType i1Rail() { return RailType{Kind::Int, 1}; }

class CtxSink final : public GateSink {
  LoweringContext &ctx;

  Value *atomValue(unsigned var) {
    const Atom &a = atomOf(var);
    switch (a.kind) {
    case AtomKind::Cond:
    case AtomKind::Seed: {
      Operand op = ctx.operand(a.v);
      if (op.handle)
        internalError("pred: a classical atom whose operand is a rail", a.v);
      return op.v;
    }
    case AtomKind::Eq: {
      Operand op = ctx.operand(a.v);
      if (op.handle)
        internalError("pred: a classical switch atom whose scrutinee is a rail", a.v);
      return ctx.B().CreateICmpEQ(op.v, ConstantInt::get(op.v->getType(), a.c));
    }
    case AtomKind::Entry:
      internalError("pred: the _ctl entry flag as a classical value", a.v);
    }
    internalError("pred: atom kind");
  }

  Value *classicalValue(unsigned n) {
    Bdd &m = Bdd::get();
    LLVMContext &C = ctx.M.getContext();
    if (n == Bdd::F)
      return ConstantInt::getFalse(C);
    if (n == Bdd::T)
      return ConstantInt::getTrue(C);
    Value *v = atomValue(m.var(n));
    unsigned l = m.lo(n), h = m.hi(n);
    if (l == Bdd::F && h == Bdd::T)
      return v;
    if (l == Bdd::T && h == Bdd::F)
      return ctx.B().CreateNot(v);
    return ctx.B().CreateSelect(v, classicalValue(h), classicalValue(l));
  }

  Value *seed(Value *i1) {
    CallInst *call = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1Rail()}, {i1});
    ctx.unc().recordSeed(call);
    return call;
  }

public:
  explicit CtxSink(LoweringContext &ctx) : ctx(ctx) {}

  Value *atomRail(unsigned var) override {
    const Atom &a = atomOf(var);
    switch (a.kind) {
    case AtomKind::Cond:
      return ctx.rail(a.v);
    case AtomKind::Seed:
      return seed(atomValue(var));
    case AtomKind::Eq: {
      // A3: a case flag is the equality template on the scrutinee with the case value as literal.
      abi::TemplateSpec spec;
      spec.op = "icmp";
      spec.pred = "eq";
      spec.w = railTypeOf(a.v->getType());
      spec.shape = "hl";
      Value *lit = ConstantInt::get(a.v->getType(), a.c);
      return ctx.emitTemplate(spec, {Operand{ctx.rail(a.v), true}, Operand{lit, false}});
    }
    case AtomKind::Entry:
      return const_cast<Value *>(a.v);
    }
    internalError("pred: atom kind");
  }

  Value *classicalSeed(unsigned node) override { return seed(classicalValue(node)); }

  Value *alloc0() override { return seed(ConstantInt::getFalse(ctx.M.getContext())); }

  void gate(abi::Core op, ArrayRef<Value *> controls, Value *target) override {
    SmallVector<Value *, 3> args(controls.begin(), controls.end());
    args.push_back(target);
    abi::CoreSpec spec{op, i1Rail()};
    CallInst *call = ctx.emitCore(spec, args);
    SmallVector<Operand, 3> ops;
    for (Value *c : controls)
      ops.push_back(Operand{c, true});
    ctx.unc().recordCore(call, spec, ops, ctx.unc().idOf(target));
  }
};

std::function<bool(unsigned)> quantumLikeFn(LoweringContext &ctx, std::shared_ptr<Oracle> O) {
  return [O](unsigned v) { return quantumLike(v, *O); };
}

bool scalarRailType(Type *t) { return t->isIntegerTy() || t->isFloatingPointTy(); }

Value *seedOf(LoweringContext &ctx, Value *classical, RailType w) {
  CallInst *call = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {classical});
  ctx.unc().recordSeed(call);
  return call;
}

} // namespace
} // namespace pred_detail

using namespace pred_detail;

Value *PathPredicates::flag(LoweringContext &ctx, const Pred &p) {
  unsigned n = nodeOf(p);
  if (n == Bdd::T)
    return nullptr;
  if (n == Bdd::F)
    internalError("pred: a flag for the false predicate (code under it never runs)");
  std::shared_ptr<Oracle> O = taintOracle(ctx.T, ctx.S);
  CtxSink sink(ctx);
  return materialize(n, sink, quantumLikeFn(ctx, O));
}

// Rule 9: one select per distinct arm, the complement innermost, into fresh rails.
Value *selectChain(LoweringContext &ctx, ArrayRef<std::pair<Pred, Operand>> arms, RailType w) {
  if (arms.empty())
    internalError("pred: selectChain with no arms");
  std::vector<unsigned> nodes;
  for (auto &a : arms)
    nodes.push_back(nodeOf(a.first));
  auto conds = chainConditions(nodes);
  if (conds.size() == 1) {
    // One arm reaches the merge on every path: the merge is that value (a representation change).
    const Operand &op = arms[conds[0].second].second;
    return op.handle ? op.v : seedOf(ctx, op.v, w);
  }
  std::shared_ptr<Oracle> O = taintOracle(ctx.T, ctx.S);
  auto ql = quantumLikeFn(ctx, O);
  Operand acc = arms[conds.back().second].second;
  for (int j = int(conds.size()) - 2; j >= 0; --j) {
    unsigned c = conds[j].first;
    Operand a = arms[conds[j].second].second;
    Value *cond;
    Operand tv = a, fv = acc;
    if (auto g = negatedAtom(c, ql)) {
      // Selecting on NOT g is selecting on g with the arms swapped.
      CtxSink sink(ctx);
      cond = sink.atomRail(*g);
      std::swap(tv, fv);
    } else {
      cond = ctx.preds().flag(ctx, makePred(c));
    }
    if (!cond)
      internalError("pred: a select arm condition that is constant true before the last arm");
    abi::TemplateSpec spec;
    spec.op = "select";
    spec.w = w;
    std::string shape = std::string(tv.handle ? "h" : "l") + (fv.handle ? "h" : "l");
    spec.shape = shape == "hh" ? "" : shape;
    acc = Operand{ctx.emitTemplate(spec, {Operand{cond, true}, tv, fv}), true};
  }
  return acc.v;
}

Value *lowerMerge(LoweringContext &ctx, PHINode &phi) {
  const PathStorage &I = storage(ctx.preds());
  const BasicBlock *bb = phi.getParent();
  if (I.F != bb->getParent())
    internalError("pred: lowerMerge before PathPredicates::compute of its function", &phi);
  if (I.loopHeaders.count(bb))
    internalError("pred: lowerMerge on a loop-header phi (a carried value: the loop modules)", &phi);
  if (!scalarRailType(phi.getType()))
    unimplemented("pred: lowerMerge of a non-scalar phi (aggregates: aggr, pointers: fatptr)", &phi);

  // One arm per distinct incoming value, ordered by the first incoming block in RPO.
  struct Arm { const Value *v; unsigned node; unsigned order; };
  std::vector<Arm> arms;
  Bdd &m = Bdd::get();
  for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
    const BasicBlock *from = phi.getIncomingBlock(i);
    auto r = I.rpo.find(from);
    if (r == I.rpo.end())
      continue;   // an unreachable predecessor never selects
    unsigned e = nodeOf(ctx.preds().edge(from, bb));
    const Value *v = phi.getIncomingValue(i);
    auto it = std::find_if(arms.begin(), arms.end(), [&](const Arm &a) { return a.v == v; });
    if (it == arms.end())
      arms.push_back({v, e, r->second});
    else {
      it->node = m.orOp(it->node, e);
      it->order = std::min(it->order, r->second);
    }
  }
  std::stable_sort(arms.begin(), arms.end(), [](const Arm &a, const Arm &b) { return a.order < b.order; });
  std::vector<std::pair<Pred, Operand>> chain;
  for (const Arm &a : arms)
    chain.push_back({makePred(a.node), ctx.operand(a.v)});
  return selectChain(ctx, chain, railTypeOf(phi.getType()));
}

Value *lowerSelect(LoweringContext &ctx, SelectInst &sel) {
  Value *c = sel.getCondition();
  if (c->getType()->isVectorTy() || !scalarRailType(sel.getType()))
    unimplemented("pred: lowerSelect of a vector or non-scalar select (aggr, fatptr)", &sel);
  if (!ctx.T.isQuantum(c, ctx.S))
    internalError("pred: lowerSelect on a classical condition", &sel);
  Pred p = Pred::atom(c);
  std::pair<Pred, Operand> arms[] = {{p, ctx.operand(sel.getTrueValue())},
                                     {!p, ctx.operand(sel.getFalseValue())}};
  return selectChain(ctx, arms, railTypeOf(sel.getType()));
}

// A br on a quantum condition is absorbed: the arms are linearized by the spine's walk and run under
// their block predicates, so nothing is emitted for it. What remains is lifetime: the rails of the
// condition's quantum atoms must outlive every original instruction that reads them through a
// predicate (every instruction lowered under a block predicate that mentions the atom, and every
// merge whose edge predicates mention it).
void lowerBranch(LoweringContext &ctx, BranchInst &br) {
  if (!br.isConditional())
    internalError("pred: lowerBranch on an unconditional br", &br);
  if (!ctx.T.isQuantum(br.getCondition(), ctx.S))
    internalError("pred: lowerBranch on a classical condition (it stays a classical branch)", &br);
  const PathStorage &I = storage(ctx.preds());
  if (I.F != br.getFunction())
    internalError("pred: lowerBranch before PathPredicates::compute of its function", &br);
  std::shared_ptr<Oracle> O = taintOracle(ctx.T, ctx.S);
  Bdd &m = Bdd::get();

  std::set<unsigned> sup, atoms;
  m.support(condNode(br.getCondition(), *O), sup);
  for (unsigned v : sup) {
    const Atom &a = atomOf(v);
    if (a.kind == AtomKind::Cond && O->isQuantum(a.v))
      atoms.insert(v);   // Seed atoms are re-minted from classical values at each use
  }
  if (atoms.empty())
    return;
  std::map<unsigned, RailId> ids;
  for (unsigned v : atoms)
    ids[v] = ctx.unc().idOf(ctx.rail(atomOf(v).v));

  auto mentions = [&](const Pred &p, auto &&fn) {
    std::set<unsigned> s;
    m.support(nodeOf(p), s);
    for (unsigned v : atoms)
      if (s.count(v))
        fn(v);
  };
  for (auto &entry : I.rpo) {
    const BasicBlock *b = entry.first;

    mentions(I.blocks.find(b)->second, [&](unsigned v) {
      for (const Instruction &inst : *b)
        ctx.unc().noteUse(ids[v], const_cast<Instruction *>(&inst));
    });
    for (const PHINode &phi : b->phis())
      for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
        auto e = I.edges.find({phi.getIncomingBlock(i), b});
        if (e != I.edges.end())
          mentions(e->second, [&](unsigned v) { ctx.unc().noteUse(ids[v], const_cast<PHINode *>(&phi)); });
      }
  }
}

// Rule 12: a phase is rz_i1 on the flag of the quantum predicate in scope (a _ctl clone's predicate
// included), and is deleted when there is none: a phase under a classical predicate is global.
void lowerPhase(LoweringContext &ctx, CallInst &cqPhi) {
  if (cqPhi.arg_size() != 1)
    internalError("pred: cq_phi with other than one argument", &cqPhi);
  Value *theta = cqPhi.getArgOperand(0);
  if (ctx.T.isQuantum(theta, ctx.S)) {
    rot::lowerQuantumAnglePhase(ctx, cqPhi, ctx.currentFlag());   // rules 11, 15
    return;
  }
  if (ctx.S.pure)
    return;   // a _pure clone is the clone without its phase effects (CR §1.4)
  const Pred &q = ctx.currentPredicate();
  unsigned n = nodeOf(q);
  if (n == Bdd::T || n == Bdd::F)
    return;   // global phase (rule 12), or code that never runs
  Operand angle = ctx.operand(theta);
  if (angle.handle)
    internalError("pred: a classical cq_phi angle whose operand is a rail", &cqPhi);
  abi::CoreSpec rz{abi::Core::RzI1, i1Rail()};
  std::shared_ptr<Oracle> O = taintOracle(ctx.T, ctx.S);
  if (auto g = negatedAtom(n, quantumLikeFn(ctx, O))) {
    // Rule 8: the false edge is an X bracket on the flag (21).
    CtxSink sink(ctx);
    Value *G = sink.atomRail(*g);
    abi::CoreSpec x{abi::Core::NotI1, i1Rail()};
    ctx.emitCore(x, {G});
    ctx.emitCore(rz, {G, angle.v});
    ctx.emitCore(x, {G});
    return;
  }
  Value *f = ctx.preds().flag(ctx, q);
  ctx.emitCore(rz, {f, angle.v});
}

} // namespace cq
