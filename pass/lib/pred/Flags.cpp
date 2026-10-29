// Module pred (cq-w0-pred): flags (rule 8), value-arm merges (rule 9), phases (rule 12), branches.
//
// Contracts this file relies on (recorded on bead cq-w0-pred; the spine and uncompute implement them):
//   - LoweringContext::emitTemplate emits the forward template AND records it (recordTemplate);
//     emitCore only emits. pred records its own core gates: recordSeed for every alloc it emits,
//     recordCore(gate, spec, controls, idOf(target)) for every XOR-into-target gate of a flag.
//   - Uncompute (pass/lib/uncompute/Uncompute.cpp CONTRACT): recordCore's ops are the gate's whole
//     argument list, out its target; IR users of a handle are its uses; a rail is resolved only at a
//     flushBefore/flushAtExit the spine places. A flag minted here is used right where it is minted
//     (a gate or a select), so the first flush after that lowering tears it down (CR §5).
//   - One exception (cq-rdux): a phase whose compound flag has a negated atom (rule 8's X bracket)
//     computes the flag on an unrecorded scratch rail, applies the phase and uncomputes and frees the
//     flag itself, with the bracket around all three (bracketedFlag). The scratch rail is never an
//     operand of a record; its sub-flags and atoms are ordinary recorded rails read by IR users.
#include "PredInternal.h"

#include "cq/Common.h"
#include "cq/Rotation.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq {
namespace pred_detail {

namespace {

// Flag synthesis state shared by materialize and bracketedPhase: one memo of atom rails and minted
// sub-flags per lowering, so an atom (a switch case flag, a classical seed) is read through one rail.
class Materializer {
  Bdd &m = Bdd::get();
  GateSink &sink;
  const std::function<bool(unsigned)> &ql;
  std::map<unsigned, Value *> memo, atoms;

public:
  Materializer(GateSink &sink, const std::function<bool(unsigned)> &ql) : sink(sink), ql(ql) {}

  bool classical(unsigned n) {
    std::set<unsigned> sup;
    m.support(n, sup);
    for (unsigned v : sup)
      if (ql(v))
        return false;
    return true;
  }

  Value *atomRail(unsigned v) {
    auto it = atoms.find(v);
    if (it != atoms.end())
      return it->second;
    return atoms[v] = sink.atomRail(v);
  }

  // The latest quantum-like atom of n: the innermost condition, so a nested predicate is its parent's
  // flag joined with the inner condition (08, 137).
  unsigned shannonVar(unsigned n) {
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
    return v;
  }

  Value *mat(unsigned n) {
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
  }

  // t ^= n, by XOR-into-t gates only.
  void into(Value *t, unsigned n) {
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
    unsigned v = shannonVar(n);
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
  }

  // ---- Rule 8's X bracket inside a compound flag (cq-rdux) ----
  // A control of a planned gate: a literal (a quantum-like atom, possibly negated) or a sub-flag
  // node, minted by mat (recorded, torn down by the uncompute spine).
  struct Ctl { bool lit; unsigned var; bool neg; unsigned node; };
  struct PGate { abi::Core op; SmallVector<Ctl, 2> ctl; unsigned negs() const {
    unsigned k = 0;
    for (const Ctl &c : ctl)
      k += c.lit && c.neg;
    return k;
  } };

  Ctl ctlOf(unsigned n) {
    if (!m.terminal(n) && ql(m.var(n))) {
      if (m.lo(n) == Bdd::F && m.hi(n) == Bdd::T)
        return Ctl{true, m.var(n), false, 0};
      if (m.lo(n) == Bdd::T && m.hi(n) == Bdd::F)
        return Ctl{true, m.var(n), true, 0};
    }
    return Ctl{false, 0, false, n};
  }
  static Ctl lit(unsigned v, bool neg) { return Ctl{true, v, neg, 0}; }

  // The gates of t ^= n with a negated atom as a literal control (no rail of its own): Shannon on the
  // same atom as `into`, so a predicate with no negated literal plans what `into` emits.
  void plan(unsigned n, std::vector<PGate> &out) {
    if (n == Bdd::F)
      return;
    if (n == Bdd::T) {
      out.push_back({abi::Core::NotI1, {}});
      return;
    }
    if (classical(n)) {
      out.push_back({abi::Core::XorI1, {ctlOf(n)}});
      return;
    }
    unsigned v = shannonVar(n);
    unsigned f0 = m.cofactor(n, v, false), f1 = m.cofactor(n, v, true);
    if (f0 == Bdd::F) {                       // v & f1
      if (f1 == Bdd::T)
        out.push_back({abi::Core::XorI1, {lit(v, false)}});
      else
        out.push_back({abi::Core::AndI1, {lit(v, false), ctlOf(f1)}});
    } else if (f1 == Bdd::F) {                // !v & f0
      if (f0 == Bdd::T)
        out.push_back({abi::Core::XorI1, {lit(v, true)}});
      else
        out.push_back({abi::Core::AndI1, {ctlOf(f0), lit(v, true)}});
    } else if (f0 == Bdd::T) {                // !v | f1
      out.push_back({abi::Core::OrI1, {lit(v, true), ctlOf(f1)}});
    } else if (f1 == Bdd::T) {                // v | f0
      out.push_back({abi::Core::OrI1, {lit(v, false), ctlOf(f0)}});
    } else {                                  // f0 ^ (v & (f0 ^ f1))
      plan(f0, out);
      unsigned d = m.xorOp(f0, f1);
      if (d == Bdd::T)
        out.push_back({abi::Core::XorI1, {lit(v, false)}});
      else
        out.push_back({abi::Core::AndI1, {lit(v, false), ctlOf(d)}});
    }
  }

  bool bracketed(unsigned node, const std::function<void(Value *)> &use) {
    if (m.terminal(node) || classical(node))
      internalError("pred: a bracketed flag for a constant or classical predicate");
    std::vector<PGate> gates;
    plan(node, gates);
    if (std::none_of(gates.begin(), gates.end(), [](const PGate &g) { return g.negs() > 0; }))
      return false;   // nothing to bracket: the ordinary flag
    // Gates with fewer negated controls first, so a bracket opens once and spans the inner gates, the
    // use and their replay (137).
    std::stable_sort(gates.begin(), gates.end(), [](const PGate &a, const PGate &b) { return a.negs() < b.negs(); });
    Value *t = sink.scratch0();
    // Every control rail is minted before any bracket opens: a sub-flag's recorded gates read its
    // atoms un-negated, as their replay will.
    std::vector<SmallVector<Value *, 2>> rails;
    for (const PGate &g : gates) {
      SmallVector<Value *, 2> r;
      for (const Ctl &c : g.ctl)
        r.push_back(c.lit ? atomRail(c.var) : mat(c.node));
      rails.push_back(r);
    }
    std::vector<Value *> open;   // rails currently negated, in opening order
    auto setNeg = [&](Value *r, bool want) {
      auto it = std::find(open.begin(), open.end(), r);
      if ((it != open.end()) == want)
        return;
      sink.rawGate(abi::Core::NotI1, {}, r);
      if (want)
        open.push_back(r);
      else
        open.erase(it);
    };
    // Before each gate exactly the brackets it needs are open. The uncompute spine places a recorded
    // control's item right after its last use, which is a gate of the replay: the sub-flags of a gate
    // never read its own literals (Shannon), so the item then reads its atoms un-negated.
    auto emit = [&](size_t i) {
      SmallVector<Value *, 2> need;
      for (size_t j = 0; j < gates[i].ctl.size(); ++j)
        if (gates[i].ctl[j].lit && gates[i].ctl[j].neg)
          need.push_back(rails[i][j]);
      for (size_t k = open.size(); k-- > 0;)
        if (!is_contained(need, open[k]))
          setNeg(open[k], false);
      for (Value *r : need)
        setNeg(r, true);
      // An atom rail computed directly from a bracketed one may have its item placed after this gate.
      for (Value *r : rails[i])
        if (auto *c = dyn_cast<CallInst>(r))
          for (Value *a : c->args())
            if (is_contained(need, a))
              unimplemented("pred: an X bracket on a rail another control of the same flag gate reads", c);
      for (Value *r : rails[i])
        if (r == t)
          internalError("pred: a bracketed flag gate controlled by its own target");
      sink.rawGate(gates[i].op, rails[i], t);
    };
    for (size_t i = 0; i < gates.size(); ++i)
      emit(i);
    use(t);
    for (size_t i = gates.size(); i-- > 0;)
      emit(i);
    while (!open.empty())
      setNeg(open.back(), false);
    sink.freeScratch(t);
    return true;
  }
};

} // namespace

Value *materialize(unsigned node, GateSink &sink, const std::function<bool(unsigned)> &ql) {
  return Materializer(sink, ql).mat(node);
}

bool bracketedFlag(unsigned node, GateSink &sink, const std::function<bool(unsigned)> &ql,
                   const std::function<void(Value *)> &use) {
  return Materializer(sink, ql).bracketed(node, use);
}

// ---- Rule 9 at a58c3a4: merges chosen classically (owner ruling on cq-mtt) ----

Value *classicalSelect(SelectInst &sel, IRBuilder<> &B, MergeSink &sink) {
  Operand c = sink.operand(sel.getCondition());
  if (c.handle)
    internalError("pred: a classically chosen select whose condition is a rail", &sel);
  RailType w = railTypeOf(sel.getType());
  if (auto *k = dyn_cast<ConstantInt>(c.v)) {
    Operand a = sink.operand(k->isOne() ? sel.getTrueValue() : sel.getFalseValue());
    return a.handle ? a.v : sink.seed(a.v, w);
  }
  Operand t = sink.operand(sel.getTrueValue()), f = sink.operand(sel.getFalseValue());
  if (!t.handle && !f.handle)   // every arm read classically (a collapsed rail): one value, one rail
    return sink.seed(B.CreateSelect(c.v, t.v, f.v), w);
  if (t.v == f.v)
    return t.v;
  Value *ht = t.handle ? t.v : sink.seed(t.v, w);
  Value *hf = f.handle ? f.v : sink.seed(f.v, w);
  Instruction *m = B.Insert(SelectInst::Create(c.v, ht, hf), sel.getName());
  sink.merged(m);
  return m;
}

Value *classicalPhi(PHINode &phi, BasicBlock *join, IRBuilder<> &B,
                    const std::function<BasicBlock *(const BasicBlock *)> &outOf, MergeSink &sink) {
  RailType w = railTypeOf(phi.getType());
  struct In { const BasicBlock *u; BasicBlock *out; const Value *v; Operand op; };
  std::vector<In> ins;
  for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
    const BasicBlock *u = phi.getIncomingBlock(i);
    if (std::any_of(ins.begin(), ins.end(), [&](const In &x) { return x.u == u; }))
      continue;   // a repeated edge carries the same value
    BasicBlock *ob = outOf(u);
    if (!ob)
      continue;   // an unreachable predecessor never selects
    ins.push_back({u, ob, phi.getIncomingValue(i), Operand{nullptr, false}});
  }
  if (ins.empty())
    internalError("pred: a phi with no reachable incoming edge", &phi);
  {
    // Each incoming value is read where its edge leaves.
    IRBuilderBase::InsertPointGuard g(B);
    for (In &in : ins) {
      Instruction *t = in.out->getTerminator();
      if (!t)
        internalError("pred: the output block of an incoming edge has no terminator yet", &phi);
      B.SetInsertPoint(t);
      in.op = sink.operand(in.v);
    }
  }
  if (std::all_of(ins.begin(), ins.end(), [&](const In &x) { return x.op.v == ins[0].op.v; }))
    return ins[0].op.handle ? ins[0].op.v : sink.seed(ins[0].op.v, w);   // one value on every edge

  // The output CFG must reach the join through exactly the incoming edges' blocks.
  SmallPtrSet<BasicBlock *, 8> outs, preds;
  for (const In &in : ins)
    if (!outs.insert(in.out).second)
      unimplemented("pred: two incoming edges of a classically chosen phi leave one output block", &phi);
  for (BasicBlock *p : predecessors(join))
    preds.insert(p);
  bool routed = outs.size() == preds.size();
  for (BasicBlock *p : preds)
    routed &= outs.count(p) > 0;
  if (!routed)
    unimplemented("pred: a classically chosen phi whose output join is not reached exactly through the output "
                  "blocks of its incoming edges",
                  &phi);

  bool anyHandle = std::any_of(ins.begin(), ins.end(), [](const In &x) { return x.op.handle; });
  if (anyHandle) {
    // A classical arm meets the quantum ones on a rail, seeded on its own edge (128).
    IRBuilderBase::InsertPointGuard g(B);
    for (In &in : ins)
      if (!in.op.handle) {
        B.SetInsertPoint(in.out->getTerminator());
        in.op = Operand{sink.seed(in.op.v, w), true};
      }
  }
  Type *ty = anyHandle ? ins[0].op.v->getType() : phi.getType();
  for (const In &in : ins)
    if (in.op.v->getType() != ty)
      internalError("pred: the arms of a classically chosen phi have different types", &phi);
  PHINode *np = PHINode::Create(ty, unsigned(pred_size(join)), phi.getName());
  np->insertInto(join, join->getFirstNonPHIIt());
  for (BasicBlock *p : predecessors(join))
    for (const In &in : ins)
      if (in.out == p)
        np->addIncoming(in.op.v, p);
  if (!anyHandle)
    return sink.seed(np, w);   // every arm read classically: one value, one rail
  sink.merged(np);
  return np;
}

namespace {

RailType i1Rail() { return RailType{Kind::Int, 1}; }

class CtxSink final : public GateSink {
  LoweringContext &ctx;

  Value *atomValue(unsigned var) {
    const Atom &a = atomOf(var);
    switch (a.kind) {
    case AtomKind::Cond: {
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
      if (!ctx.T.isQuantum(a.v, ctx.S))
        return seed(atomValue(var));   // a classical term of a mixed flag (rule 8, c || q)
      return ctx.rail(a.v);
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

  Value *scratch0() override {
    return ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1Rail()}, {ConstantInt::getFalse(ctx.M.getContext())});
  }

  void rawGate(abi::Core op, ArrayRef<Value *> controls, Value *target) override {
    SmallVector<Value *, 3> args(controls.begin(), controls.end());
    args.push_back(target);
    ctx.emitCore(abi::CoreSpec{op, i1Rail()}, args);
  }

  void freeScratch(Value *t) override { ctx.emitCore(abi::CoreSpec{abi::Core::Free}, {t}); }

  void gate(abi::Core op, ArrayRef<Value *> controls, Value *target) override {
    SmallVector<Value *, 3> args(controls.begin(), controls.end());
    args.push_back(target);
    abi::CoreSpec spec{op, i1Rail()};
    CallInst *call = ctx.emitCore(spec, args);
    SmallVector<Operand, 3> ops;   // uncompute's contract: the gate's whole argument list
    for (Value *a : args)
      ops.push_back(Operand{a, true});
    ctx.unc().recordCore(call, spec, ops, ctx.unc().idOf(target));
  }
};

class CtxMergeSink final : public MergeSink {
  LoweringContext &ctx;

public:
  explicit CtxMergeSink(LoweringContext &ctx) : ctx(ctx) {}
  Operand operand(const Value *orig) override { return ctx.operand(orig); }
  Value *seed(Value *classical, RailType w) override {
    CallInst *call = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {classical});
    ctx.unc().recordSeed(call);
    return call;
  }
  void merged(Instruction *m) override { ctx.unc().recordMerge(m); }
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

  // Rule 9 at a58c3a4: every incoming edge chosen classically makes a classical phi over the handles.
  std::shared_ptr<Oracle> CO = taintOracle(ctx.T, ctx.S);
  bool classicalChoice = true;
  for (unsigned i = 0; i < phi.getNumIncomingValues() && classicalChoice; ++i)
    if (I.rpo.count(phi.getIncomingBlock(i)))
      classicalChoice = isClassicalNode(nodeOf(ctx.preds().edge(phi.getIncomingBlock(i), bb)), *CO);
  if (classicalChoice) {
    CtxMergeSink sink(ctx);
    auto outOf = [&](const BasicBlock *u) -> BasicBlock * { return I.rpo.count(u) ? ctx.block(u) : nullptr; };
    return classicalPhi(phi, ctx.B().GetInsertBlock(), ctx.B(), outOf, sink);
  }

  // One arm per distinct incoming value, in the phi's incoming order (its first occurrence).
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
      arms.push_back({v, e, i});
    else
      it->node = m.orOp(it->node, e);
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
  if (!ctx.T.isQuantum(c, ctx.S)) {
    CtxMergeSink sink(ctx);   // rule 9 at a58c3a4: a classical select over the handles, no gate
    return classicalSelect(sel, ctx.B(), sink);
  }
  Pred p = Pred::atom(c);
  std::pair<Pred, Operand> arms[] = {{p, ctx.operand(sel.getTrueValue())},
                                     {!p, ctx.operand(sel.getFalseValue())}};
  return selectChain(ctx, arms, railTypeOf(sel.getType()));
}

// A br on a quantum condition is absorbed: the arms are linearized by the spine's walk and run under
// their block predicates (the classical factor of a block predicate as a classical branch, its
// quantum part as a flag, rule 8 / P1), so nothing is emitted for it. The rails of the condition's
// atoms are read again by the arms' flags and by the merges: uncompute counts IR users of a handle as
// uses and resolves a rail only at a flushBefore the spine places, so the spine keeps a condition rail
// pending (no flush that could resolve it) until the last block and merge under it are lowered.
void lowerBranch(LoweringContext &ctx, BranchInst &br) {
  if (!br.isConditional())
    internalError("pred: lowerBranch on an unconditional br", &br);
  if (!ctx.T.isQuantum(br.getCondition(), ctx.S))
    internalError("pred: lowerBranch on a classical condition (it stays a classical branch)", &br);
  const PathStorage &I = storage(ctx.preds());
  if (I.F != br.getFunction())
    internalError("pred: lowerBranch before PathPredicates::compute of its function", &br);
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
  {
    // Rule 8: a negated atom inside a compound flag is an X bracket on its rail, not a rail of its
    // own (137). The bracket spans the flag's gates, the phase and their replay, so the flag is
    // computed and uncomputed here, around the phase, and is no uncompute record (cq-rdux).
    CtxSink sink(ctx);
    if (bracketedFlag(n, sink, quantumLikeFn(ctx, O), [&](Value *t) { ctx.emitCore(rz, {t, angle.v}); }))
      return;
  }
  Value *f = ctx.preds().flag(ctx, q);
  ctx.emitCore(rz, {f, angle.v});
}

} // namespace cq
