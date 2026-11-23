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
//     operand of a record; its sub-flags and atoms are ordinary recorded rails read by IR users, and
//     the scratch free, after the last bracket closes, is a noted use of each (cq-nogu).
#include "PredInternal.h"

#include "cq/Aggregates.h"
#include "cq/Order.h"
#include "cq/Common.h"
#include "cq/Rotation.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/CycleInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/Support/raw_ostream.h"

#include <unordered_map>

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

  // Memoized per node over this lowering (not a support set per call): classical(n) says no quantum-like atom
  // is in n's support; latestQl(n) is n's quantum-like atom latest in the variable order, Bdd::NoVar for none.
  std::unordered_map<unsigned, bool> classicalMemo;
  std::unordered_map<unsigned, unsigned> latestMemo;

  bool classical(unsigned n) {
    if (m.terminal(n))
      return true;
    if (auto it = classicalMemo.find(n); it != classicalMemo.end())
      return it->second;
    bool r = !ql(m.var(n)) && classical(m.lo(n)) && classical(m.hi(n));
    return classicalMemo[n] = r;
  }

  unsigned latestQl(unsigned n) {
    if (m.terminal(n))
      return Bdd::NoVar;
    if (auto it = latestMemo.find(n); it != latestMemo.end())
      return it->second;
    unsigned v = ql(m.var(n)) ? m.var(n) : Bdd::NoVar;
    for (unsigned s : {latestQl(m.lo(n)), latestQl(m.hi(n))})
      if (s != Bdd::NoVar && (v == Bdd::NoVar || m.level(s) > m.level(v)))
        v = s;
    return latestMemo[n] = v;
  }

  Value *atomRail(unsigned v) {
    auto it = atoms.find(v);
    if (it != atoms.end())
      return it->second;
    AtomKind k = atomOf(v).kind;
    if (k != AtomKind::Eq && k != AtomKind::Addr)
      return atoms[v] = sink.atomRail(v);   // the IR value's own rail
    if (Value *x = sink.reusable(m.ithVar(v)))
      return atoms[v] = x;
    Value *r = sink.atomRail(v);   // a case's equality, minted here
    sink.minted(m.ithVar(v), r);
    return atoms[v] = r;
  }

  // The latest quantum-like atom of n: the innermost condition, so a nested predicate is its parent's
  // flag joined with the inner condition (08, 137). Latest in the variable order (cq-ewzri: creation
  // order but for an atom placed into a switch case's group).
  unsigned shannonVar(unsigned n) {
    unsigned v = latestQl(n);
    if (v == Bdd::NoVar)
      internalError("pred: flag synthesis lost its quantum atom");
    return v;
  }

  // cq-ct59d: n where at most one case atom of each switch (computed goto) holds, the only assignments its
  // atoms' rails take. When n implies case atom e, the other cases of e's scrutinee are false wherever n
  // holds: n is e & n[e = 1, its siblings = 0]. Without it a sub-flag under case k reads every other case
  // (the derivative of a switch's join on a condition inside case k is case k & no earlier case's path),
  // so a switch's flags grow with the square of its cases, or exponentially in creation order.
  unsigned exclusive(unsigned n) {
    if (m.terminal(n))
      return n;
    std::set<unsigned> sup;
    m.support(n, sup);
    for (unsigned e : sup) {
      const Atom &a = atomOf(e);
      if ((a.kind != AtomKind::Eq && a.kind != AtomKind::Addr) || m.sides(n, e).first)
        continue;
      unsigned r = m.cofactor(n, e, true);
      for (unsigned o : sup)
        if (exclusiveAtoms(a, atomOf(o)))
          r = m.cofactor(r, o, false);
      return m.andOp(m.ithVar(e), r);
    }
    return n;
  }

  Value *mat(unsigned n) {
    if (m.terminal(n))
      internalError("pred: a flag for a constant predicate");
    auto it = memo.find(n);
    if (it != memo.end())
      return it->second;
    if (Value *x = sink.reusable(n))
      return memo[n] = x;
    Value *r;
    // A node that needs two cases of one scrutinee at once rewrites to false: no rail state reaches it, its flag is n's.
    if (unsigned x = exclusive(n); x != n && !m.terminal(x))
      r = mat(x);
    else if (classical(n)) {
      r = sink.classicalSeed(n);
      sink.minted(n, r);
    }
    else if (m.lo(n) == Bdd::F && m.hi(n) == Bdd::T)
      r = atomRail(m.var(n));
    else if (Value *x = m.lo(n) == Bdd::T && m.hi(n) == Bdd::F && ql(m.var(n)) ? sink.liveNegation(m.var(n)) : nullptr)
      r = x;   // NOT v is already a live rail (cq-su3p, 113)
    else {
      r = sink.alloc0();
      into(r, n);
      sink.minted(n, r);
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
    // control's item right after its last use; freeScratch, after every bracket closed, is noted as
    // a use of every control rail, so no item reading a bracketed atom, directly or through the
    // chain of a rail it uncomputes (p5: an atom rail computed from zext of the negated atom), lands
    // inside a bracket (cq-nogu).
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
    SmallVector<Value *, 8> held;
    for (const auto &r : rails)
      for (Value *c : r)
        if (!is_contained(held, c))
          held.push_back(c);
    sink.freeScratch(t, held);
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

// ---- Decision (1) on cq-su3p: NOT v as an existing live rail ----

namespace {

bool isI1(const RailType &w) { return w.kind == Kind::Int && w.bits == 1; }

// Is c a forward template computing NOT atom (xor with true, icmp eq false, icmp ne true on i1)?
bool negates(const CallInst &c, const Value *atom) {
  const Function *f = c.getCalledFunction();
  if (!f || c.arg_size() != 2)
    return false;
  bool unc = false;
  std::optional<abi::TemplateSpec> spec = abi::parseTemplate(f->getName(), &unc);
  if (!spec || unc || spec->to || !isI1(spec->w) || spec->rm != abi::TemplateSpec::NoRm || spec->exc)
    return false;
  const Value *a0 = c.getArgOperand(0), *a1 = c.getArgOperand(1);
  const ConstantInt *k = nullptr;
  if (a0 == atom && spec->shape == "hl")
    k = dyn_cast<ConstantInt>(a1);
  else if (a1 == atom && spec->shape == "lh")
    k = dyn_cast<ConstantInt>(a0);
  if (!k || k->getBitWidth() != 1)
    return false;
  if (spec->op == "xor")
    return k->isOne();
  if (spec->op == "icmp")
    return (spec->pred == "eq" && k->isZero()) || (spec->pred == "ne" && k->isOne());
  return false;
}

// What call c does to the rails `a` (the atom) and `x` (the candidate): false when it may change
// either's basis value or resolve it. A not_i1 on the atom flips `atomFlips`.
bool keeps(const CallInst &c, const Value *a, const Value *x, unsigned &atomFlips) {
  bool readsA = false, readsX = false;
  for (const Use &u : c.args()) {
    readsA |= u.get() == a;
    readsX |= u.get() == x;
  }
  if (!readsA && !readsX)
    return true;
  const Function *f = c.getCalledFunction();
  if (!f)
    return false;
  bool unc = false;
  if (abi::parseTemplate(f->getName(), &unc))
    return !unc || (c.getArgOperand(0) != a && c.getArgOperand(0) != x);   // an _unc's first operand is its result
  std::optional<abi::CoreSpec> core = abi::parseCore(f->getName());
  if (!core || core->unc)
    return false;
  auto target = [&](unsigned i) -> const Value * { return i < c.arg_size() ? c.getArgOperand(i) : nullptr; };
  const Value *t = nullptr;
  switch (core->op) {
  case abi::Core::RzI1:
  case abi::Core::RzQAngle:
    return true;   // diagonal
  case abi::Core::Ry:
  case abi::Core::RyQAngle:
  case abi::Core::Xorc:
    t = target(core->ctl ? 1 : 0);
    break;
  case abi::Core::Copy:
    t = target(core->ctl ? 2 : 1);
    break;
  case abi::Core::NotI1:
    t = target(0);
    if (t == a && !core->ctl && c.arg_size() == 1) {
      ++atomFlips;
      return true;
    }
    break;
  case abi::Core::AndI1:
  case abi::Core::OrI1:
    t = target(2);
    break;
  case abi::Core::XorI1:
    t = target(1);
    break;
  default:
    return false;
  }
  return t && t != a && t != x;
}

} // namespace

// cq-i61ms: does some call negate atom (negates)? Such a call calls one of the three symbols below (parseTemplate takes
// only the canonical spelling, and xor and the compares never take _lh); a check of their calls spares the scan of the
// atom's users (thousands of gates on a path condition: sqlite3VdbeExec) where none does.
static bool anyNegation(const Value *atom, const Module &M) {
  for (const char *pred : {"", "eq", "ne"}) {
    abi::TemplateSpec s;
    s.op = *pred ? "icmp" : "xor";
    s.pred = pred;
    s.w = RailType{Kind::Int, 1};
    s.shape = "hl";
    if (const Function *f = M.getFunction(abi::name(s, false)))
      for (const User *u : f->users())
        if (auto *c = dyn_cast<CallInst>(u); c && negates(*c, atom))
          return true;
  }
  return false;
}

Value *liveNegationAt(Value *atom, BasicBlock *bb, BasicBlock::iterator pt) {
  if (!atom || !bb)
    return nullptr;
  if (!anyNegation(atom, *bb->getModule()))
    return nullptr;
  // The blocks that run, once and in this order, before bb on every path into it.
  SmallVector<BasicBlock *, 8> chain{bb};
  SmallPtrSet<BasicBlock *, 8> seen{bb};
  for (BasicBlock *b = bb; BasicBlock *p = b->getSinglePredecessor(); b = p) {
    if (!seen.insert(p).second || p->getTerminator() == nullptr || p->getTerminator()->getNumSuccessors() != 1)
      break;
    chain.push_back(p);
  }
  for (User *u : atom->users()) {
    auto *c = dyn_cast<CallInst>(u);
    if (!c)
      continue;
    auto at = std::find(chain.begin(), chain.end(), c->getParent());   // the cheap test first
    if (at == chain.end() || !negates(*c, atom))
      continue;
    // before pt (cq-i61ms: by the order labels, not a scan of bb per user)
    if (c->getParent() == bb && pt != bb->end() && !cq::comesBefore(c, &*pt))
      continue;
    bool resolved = false;
    for (User *xu : c->users())
      if (auto *xc = dyn_cast<CallInst>(xu); xc && xc->getCalledFunction()) {
        bool unc = false;
        StringRef fn = xc->getCalledFunction()->getName();
        if (abi::parseTemplate(fn, &unc) ? unc && xc->getArgOperand(0) == c : false)
          resolved = true;
        if (auto core = abi::parseCore(fn); core && (core->op == abi::Core::Free || core->unc))
          resolved = true;
      }
    if (resolved)
      continue;
    // The window from c to pt, in program order.
    unsigned flips = 0;
    bool ok = true;
    for (auto b = std::make_reverse_iterator(at + 1); ok && b != chain.rend(); ++b) {
      BasicBlock *blk = *b;
      auto it = blk == c->getParent() ? std::next(c->getIterator()) : blk->begin();
      auto end = blk == bb ? pt : blk->end();
      for (; ok && it != end; ++it)
        if (auto *ci = dyn_cast<CallInst>(&*it))
          ok = keeps(*ci, atom, c, flips);
    }
    if (ok && flips % 2 == 0)
      return c;
  }
  return nullptr;
}

// ---- Rule 9 at a58c3a4: merges chosen classically (owner ruling on cq-mtt) ----

// CR rule 13 (b137e75): a code address merges as the i64 integer it is.
static RailType mergeRail(Type *t) { return t->isPointerTy() ? RailType{Kind::Int, 64} : railTypeOf(t); }

Value *classicalSelect(SelectInst &sel, IRBuilder<> &B, MergeSink &sink) {
  Operand c = sink.operand(sel.getCondition());
  if (c.handle)
    internalError("pred: a classically chosen select whose condition is a rail", &sel);
  RailType w = mergeRail(sel.getType());
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
  RailType w = mergeRail(phi.getType());
  return classicalPhiOf(phi, join, B, outOf, sink, w, irTypeOf(phi.getContext(), w),
                        [&](const Value *v) { return sink.operand(v); }, /*seedClassical=*/true)
      .v;
}

// classicalPhi over one field of phi (cq-oa67, rule 26): `read` gives the field of an incoming value at
// the builder, w its rail type and ty its classical type.
Operand classicalPhiOf(PHINode &phi, BasicBlock *join, IRBuilder<> &B,
                       const std::function<BasicBlock *(const BasicBlock *)> &outOf, MergeSink &sink, RailType w,
                       Type *fieldTy, const std::function<Operand(const Value *)> &read, bool seedClassical) {
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
  // When the output CFG reaches the join through exactly the incoming edges' blocks, each output edge
  // carries its own incoming. Otherwise (the walk ran two incoming blocks on one output path, or reached
  // the join by a guard's skip edge or a redirected edge; cq-pfpy) each output edge into the join takes
  // the incoming its classical facts choose (rule 9: the choice is classical): one admitted value as it
  // is, several a classical select on their (classical) edge predicates, read where the edge leaves.
  SmallPtrSet<BasicBlock *, 8> outs, preds;
  bool routed = true;
  for (const In &in : ins)
    routed &= outs.insert(in.out).second;
  for (BasicBlock *p : predecessors(join))
    preds.insert(p);
  routed &= outs.size() == preds.size();
  for (BasicBlock *p : preds)
    routed &= outs.count(p) > 0;
  if (routed) {
    // Each incoming value is read where its edge leaves. outOf(u) is u's first output block, and only when
    // the output edges into the join are the incoming ones is its terminator that point: a guard continues
    // u's code in a block of its own, whose values do not reach the guard's branch (cq-iaz30).
    IRBuilderBase::InsertPointGuard g(B);
    for (In &in : ins) {
      Instruction *t = in.out->getTerminator();
      if (!t)
        internalError("pred: the output block of an incoming edge has no terminator yet", &phi);
      B.SetInsertPoint(t);
      in.op = sink.reaching(read(in.v), w, phi, in.u);
    }
    if (std::all_of(ins.begin(), ins.end(), [&](const In &x) { return x.op.v == ins[0].op.v; })) {
      if (ins[0].op.handle || !seedClassical)
        return ins[0].op;
      return Operand{sink.seed(ins[0].op.v, w), true};   // one value on every edge
    }
  } else {
    std::vector<In> per;
    IRBuilderBase::InsertPointGuard g(B);
    for (BasicBlock *p : predecessors(join)) {
      if (std::any_of(per.begin(), per.end(), [&](const In &x) { return x.out == p; }))
        continue;
      if (!p->getTerminator())
        internalError("pred: a predecessor of a classically chosen join has no terminator yet", &phi);
      B.SetInsertPoint(p->getTerminator());
      per.push_back({nullptr, p, nullptr, sink.edgeChoice(phi, p, join, w, fieldTy, read)});
    }
    ins = std::move(per);
    if (std::all_of(ins.begin(), ins.end(), [&](const In &x) { return x.op.v == ins[0].op.v; })) {
      if (ins[0].op.handle || !seedClassical)
        return ins[0].op;
      return Operand{sink.seed(ins[0].op.v, w), true};
    }
  }

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
  if (anyHandle) {
    // cq-88vg (52): an arm whose rail reaches the join along another edge too (defined before the
    // classical choice: a register, a cell's handle loaded before the branch, a clone call's out) is
    // copied into a fresh rail on its own edge, as 52's reference does. The phi then names rails local
    // to their arms: a kept phi (measured, returned) keeps the copy chosen on each path, and the arm
    // itself is resolved where it would be without the phi.
    auto reachesOther = [&](const In &in) {
      auto *d = dyn_cast<Instruction>(in.op.v);
      if (!d)
        return true;   // a formal or a constant handle: available on every edge
      const BasicBlock *D = d->getParent();
      SmallPtrSet<const BasicBlock *, 16> seen{D};
      SmallVector<const BasicBlock *, 16> work{D};
      while (!work.empty()) {
        const BasicBlock *b = work.pop_back_val();
        for (const In &o : ins)
          if (o.out == b && o.out != in.out)
            return true;
        const Instruction *t = b->getTerminator();
        if (!t || b == in.out)
          continue;
        for (const BasicBlock *s : successors(t))
          if (s != join && seen.insert(s).second)
            work.push_back(s);
      }
      return false;
    };
    IRBuilderBase::InsertPointGuard g(B);
    std::vector<bool> copyIt(ins.size());
    for (size_t k = 0; k < ins.size(); ++k)
      copyIt[k] = ins[k].op.handle && reachesOther(ins[k]);
    for (size_t k = 0; k < ins.size(); ++k)
      if (copyIt[k]) {
        B.SetInsertPoint(ins[k].out->getTerminator());
        ins[k].op = Operand{sink.copy(ins[k].op.v, w), true};
      }
  }
  Type *ty = anyHandle ? ins[0].op.v->getType() : fieldTy;
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
    return seedClassical ? Operand{sink.seed(np, w), true}   // every arm read classically: one value, one rail
                         : Operand{np, false};
  sink.merged(np);
  return Operand{np, true};
}

namespace {

RailType i1Rail() { return RailType{Kind::Int, 1}; }

class CtxSink final : public GateSink {
  LoweringContext &ctx;
  // cq-2p1p: the output value an atom's IR value is read through where it is carried to a classical
  // join by a phi (JoinRepair carry mode); otherwise the spine's binding.
  const std::map<unsigned, Value *> *over = nullptr;
  Value *overridden(unsigned var) const {
    if (!over)
      return nullptr;
    auto it = over->find(var);
    return it == over->end() ? nullptr : it->second;
  }
  Operand orig(unsigned var) {
    if (Value *x = overridden(var))
      return Operand{x, ctx.T.isQuantum(atomOf(var).v, ctx.S)};
    return ctx.operand(atomOf(var).v);
  }

  Value *atomValue(unsigned var) {
    const Atom &a = atomOf(var);
    switch (a.kind) {
    case AtomKind::Cond: {
      Operand op = orig(var);
      if (op.handle)
        internalError("pred: a classical atom whose operand is a rail", a.v);
      return op.v;
    }
    case AtomKind::Eq: {
      Operand op = orig(var);
      if (op.handle)
        internalError("pred: a classical switch atom whose scrutinee is a rail", a.v);
      return ctx.B().CreateICmpEQ(op.v, ConstantInt::get(op.v->getType(), a.c));
    }
    case AtomKind::Addr: {
      // Rule 13: a classical computed goto's case, the address against the destination's blockaddress.
      Operand op = orig(var);
      if (op.handle)
        internalError("pred: a classical computed goto atom whose address is a rail", a.v);
      Value *x = op.v->getType()->isPointerTy() ? ctx.B().CreatePtrToInt(op.v, ctx.B().getInt64Ty()) : op.v;
      return ctx.B().CreateICmpEQ(x, caseAddress(a.bb));
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
  explicit CtxSink(LoweringContext &ctx, const std::map<unsigned, Value *> *over = nullptr) : ctx(ctx), over(over) {}

  // A classical node's i1 value at the builder (its atoms read through `over` where given).
  Value *classical(unsigned n) { return classicalValue(n); }

  Value *atomRail(unsigned var) override {
    const Atom &a = atomOf(var);
    switch (a.kind) {
    case AtomKind::Cond:
      if (!ctx.T.isQuantum(a.v, ctx.S))
        return seed(atomValue(var));   // a classical term of a mixed flag (rule 8, c || q)
      if (Value *x = overridden(var))
        return x;
      return ctx.rail(a.v);
    case AtomKind::Eq: {
      // A3: a case flag is the equality template on the scrutinee with the case value as literal.
      abi::TemplateSpec spec;
      spec.op = "icmp";
      spec.pred = "eq";
      spec.w = railTypeOf(a.v->getType());
      spec.shape = "hl";
      Value *lit = ConstantInt::get(a.v->getType(), a.c);
      // cq-0hhk: the scrutinee's value at the switch (switchRail), never a rail rotated since.
      return ctx.emitTemplate(spec, {Operand{overridden(var) ? overridden(var) : ctx.switchRail(a.v), true}, Operand{lit, false}});
    }
    case AtomKind::Addr: {
      // Rule 13 (b137e75): a quantum computed goto's case flag is icmp_eq_i64_hl(address rail,
      // ptrtoint(blockaddress(destination))).
      abi::TemplateSpec spec;
      spec.op = "icmp";
      spec.pred = "eq";
      spec.w = RailType{Kind::Int, 64};
      spec.shape = "hl";
      return ctx.emitTemplate(spec, {Operand{overridden(var) ? overridden(var) : ctx.switchRail(a.v), true},
                                     Operand{caseAddress(a.bb), false}});
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

  void freeScratch(Value *t, ArrayRef<Value *> held) override {
    CallInst *free = ctx.emitCore(abi::CoreSpec{abi::Core::Free}, {t});
    for (Value *r : held)
      ctx.unc().noteUse(ctx.unc().idOf(r), free);
  }

  // A rail minted for node earlier in this block, not yet uncomputed: it holds node's function of the atoms' SSA
  // values, which is what a fresh flag would hold. Not where atoms are carried (`over`: other values).
  Value *reusable(unsigned node) override {
    if (over)
      return nullptr;
    auto &minted = storage(ctx.preds()).minted;
    auto it = minted.find(node);
    if (it == minted.end())
      return nullptr;
    auto *I = dyn_cast_or_null<Instruction>(static_cast<Value *>(it->second));
    BasicBlock *U = ctx.B().GetInsertBlock();
    BasicBlock::iterator pt = ctx.B().GetInsertPoint();
    if (!I || I->getParent() != U || (pt != U->end() && (&*pt == I || !cq::comesBefore(I, &*pt))))
      return nullptr;
    if (!ctx.unc().recorded(I) || !ctx.unc().liveRole(ctx.unc().idOf(I)))
      return nullptr;
    return I;
  }

  void minted(unsigned node, Value *rail) override {
    if (!over)
      storage(ctx.preds()).minted[node] = rail;
  }

  Value *liveNegation(unsigned var) override {
    if (overridden(var))
      return nullptr;
    const Atom &a = atomOf(var);
    Value *h;
    if (a.kind == AtomKind::Cond && ctx.T.isQuantum(a.v, ctx.S))
      h = ctx.rail(a.v);
    else if (a.kind == AtomKind::Entry)
      h = const_cast<Value *>(a.v);
    else
      return nullptr;   // a switch case flag is minted where it is read; a classical atom is a seed
    return liveNegationAt(h, ctx.B().GetInsertBlock(), ctx.B().GetInsertPoint());
  }

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

// Rule 13 (b137e75): a code address is an integer; a classical one is read as its i64 value.
Operand addressAsInt(LoweringContext &ctx, Operand op) {
  if (op.handle || !op.v->getType()->isPointerTy())
    return op;
  Type *i64 = Type::getInt64Ty(ctx.M.getContext());
  if (auto *c = dyn_cast<Constant>(op.v))
    return Operand{ConstantExpr::getPtrToInt(c, i64), false};
  return Operand{ctx.B().CreatePtrToInt(op.v, i64), false};
}

class CtxMergeSink final : public MergeSink {
  LoweringContext &ctx;

public:
  explicit CtxMergeSink(LoweringContext &ctx) : ctx(ctx) {}
  Operand operand(const Value *orig) override {
    Operand op = ctx.operand(orig);
    return orig->getType()->isPointerTy() ? addressAsInt(ctx, op) : op;
  }
  Value *seed(Value *classical, RailType w) override {
    CallInst *call = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {classical});
    ctx.unc().recordSeed(call);
    return call;
  }
  void merged(Instruction *m) override { ctx.unc().recordMerge(m); }
  Operand reaching(const Operand &op, RailType w, const PHINode &phi, const BasicBlock *u) override;
  Operand edgeChoice(PHINode &phi, BasicBlock *P, BasicBlock *join, RailType w, Type *fieldTy,
                     const std::function<Operand(const Value *)> &read) override;
  Value *copy(Value *h, RailType w) override {
    CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                               {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
    RailId fid = ctx.unc().recordSeed(f);
    abi::CoreSpec cp{abi::Core::Copy, w};
    CallInst *c = ctx.emitCore(cp, {h, f});
    ctx.unc().recordCore(c, cp, {Operand{h, true}, Operand{f, true}}, fid);
    return f;
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

// ---- cq-2p1p: a predicate or a merge read at a classical join (rules 8, 9) ----
// -O1 tail-merges a block reached from several classically chosen arms: its predicate, and the arms
// of a merge in it, read rails (and classical values) minted inside those arms, none of which
// dominates the join in the output. Rule 8 keeps the classical condition a classical branch; rule 9
// makes a choice of incoming edge that is purely classical a classical phi over the handles. So:
//   - the flag of predicate n at the join is a classical phi of per-edge flags: on each output edge
//     p -> J, n restricted by the classical facts of that edge (and the caller's don't-care set),
//     computed where the edge leaves (before p's terminator), recursively when p itself is such a
//     join; an edge on which the restriction is constant gets a seed of that constant (rule 7);
//   - a merge operand minted in an arm reaches the join as a classical phi of it and, on an edge on
//     which its arm's predicate restricted by the edge's facts is false (the select never picks it
//     there), a fresh |0> seed (a classical operand: the null value).
// Each phi over handles is recorded as a merge (Uncompute::recordMerge, U1). Used only where some
// rail or value a construction reads does not reach the point; elsewhere nothing changes.
// The classical facts of an output edge are decoded from the output CFG: the conditions of its
// classical branches and switches, over the output values of the classical atoms involved (a
// condition the decoder does not know contributes no fact, which is sound: a weaker fact restricts
// less, and a predicate that still reads a rail that does not reach is a loud unimplemented).
// cq-i61ms: the dominator tree of the output function, shared by the JoinRepairs made while its CFG stands (every
// flag lowering made one, and built a tree of the whole function: sqlite3VdbeExec). Kept with the CFG it was built from,
// the blocks in order with their successors: a tree of the same graph is the same tree.
std::shared_ptr<DominatorTree> sharedDominatorTree(Function &F) {
  struct Cache {
    const Function *F = nullptr;
    std::vector<const void *> sig;
    std::shared_ptr<DominatorTree> dt;
  };
  static Cache *c = new Cache;   // never destroyed: the tree must not outlive the LLVMContext at exit
  std::vector<const void *> sig;
  for (BasicBlock &b : F) {
    sig.push_back(&b);
    if (const Instruction *t = b.getTerminator())
      for (const BasicBlock *s : successors(t))
        sig.push_back(s);
    sig.push_back(nullptr);
  }
  if (c->dt && c->F == &F && c->sig == sig)
    return c->dt;
  c->F = &F;
  c->sig = std::move(sig);
  c->dt = std::make_shared<DominatorTree>(F);
  return c->dt;
}

class JoinRepair {
  LoweringContext &ctx;
  Bdd &m = Bdd::get();
  std::shared_ptr<Oracle> O;
  std::function<bool(unsigned)> ql;
  std::shared_ptr<DominatorTree> dt;
  std::unique_ptr<LoopInfo> li;
  std::unique_ptr<CycleInfo> ci;
  std::map<std::tuple<unsigned, unsigned, BasicBlock *>, Value *> flagMemo;
  std::map<std::tuple<Value *, unsigned, unsigned, BasicBlock *>, Value *> valueMemo;
  std::map<std::tuple<Value *, unsigned, unsigned, BasicBlock *, int, bool>, Value *> constMemo;
  std::map<std::vector<Value *>, Value *> phiMemo;

  DominatorTree &DT() {
    if (!dt)
      dt = sharedDominatorTree(ctx.out());
    return *dt;
  }
  LoopInfo &LI() {
    if (!li)
      li = std::make_unique<LoopInfo>(DT());
    return *li;
  }
  CycleInfo &CI() {
    if (!ci) {
      ci = std::make_unique<CycleInfo>();
      ci->compute(ctx.out());
    }
    return *ci;
  }

  // cq-03rdt (CR rules 5, 9, 14): a value read at `at` through a block b inside output loops that do not hold `at` (a
  // rolled loop's trip, one of its arms, read past the loop) is the same on every trip when everything it reads is
  // defined before the loop: it is read at the loop's entry instead, the one block outside the outermost such loop that
  // enters it. Per-edge values built at a join inside the loop would mint one rail per trip, after the loop's records
  // were closed: nothing undoes or frees them. Null: b lies in no such loop, the loop has several entries, or a value
  // read is defined where the loop's header reaches without passing its entry (in the loop or after it).
  // cq-vbep9: an irreducible output cycle (no loop of LoopInfo: a classical loop's reverse, entered where each exit of the
  // forward loop left it) is such a loop too when every edge into it comes from one block.
  BasicBlock *loopEntry(BasicBlock *b, BasicBlock *at, ArrayRef<Value *> reads) {
    Loop *out = nullptr;
    for (Loop *L = LI().getLoopFor(b); L && !L->contains(at); L = L->getParentLoop())
      out = L;
    BasicBlock *E = out ? out->getLoopPredecessor() : nullptr;
    const void *key = out;
    SmallVector<BasicBlock *, 2> heads;
    if (out) {
      heads.push_back(out->getHeader());
    } else {
      const CycleInfo::CycleT *cy = nullptr;
      for (const CycleInfo::CycleT *C = CI().getCycle(b); C && !C->contains(at); C = C->getParentCycle())
        cy = C;
      if (cy) {
        key = cy;
        for (BasicBlock *h : cy->getEntries()) {
          heads.push_back(h);
          for (BasicBlock *p : predecessors(h))
            if (!cy->contains(p)) {
              if (E && E != p)
                return nullptr;
              E = p;
            }
        }
      }
    }
    if (!E)
      return nullptr;
    auto [it, fresh] = pastEntry.try_emplace(key);
    if (fresh) {
      SmallVector<BasicBlock *, 16> work(heads.begin(), heads.end());
      it->second.insert(heads.begin(), heads.end());
      while (!work.empty())
        for (BasicBlock *s : successors(work.pop_back_val()))
          if (s != E && it->second.insert(s).second)
            work.push_back(s);
    }
    for (Value *x : reads)
      if (auto *i = dyn_cast_or_null<Instruction>(x); i && it->second.count(i->getParent()))
        return nullptr;
    return E;
  }
  DenseMap<const void *, SmallPtrSet<BasicBlock *, 32>> pastEntry;   // loopEntry: the blocks a header reaches avoiding its entry

  // cq-03rdt (CR rules 5, 14): an edge p -> J leaving output loops that do not hold J (one that loopEntry does not move:
  // the value depends on the trip). A flag or carried value built at p's end would be minted on every trip, after the
  // loop's records were closed, and only the last trip's is read: nothing undoes or frees the others. It is built once,
  // in a block of its own on the edge, outside the loop. Returns the block to build in (p itself when p is in no such loop).
  BasicBlock *onEdge(BasicBlock *p, BasicBlock *J) {
    Loop *L = LI().getLoopFor(p);
    if (!L || L->contains(J))
      return p;
    BasicBlock *B = BasicBlock::Create(ctx.M.getContext(), "", &ctx.out(), J);
    BranchInst::Create(J, B);
    Instruction *t = p->getTerminator();
    for (unsigned i = 0; i < t->getNumSuccessors(); ++i)
      if (t->getSuccessor(i) == J)
        t->setSuccessor(i, B);
    for (PHINode &ph : J->phis()) {   // one entry for B, however many edges p had into J
      bool kept = false;
      for (unsigned i = ph.getNumIncomingValues(); i-- > 0;)
        if (ph.getIncomingBlock(i) == p) {
          if (kept)
            ph.removeIncomingValue(i, false);
          else
            ph.setIncomingBlock(i, B), kept = true;
        }
    }
    li.reset();
    ci.reset();
    dt.reset();
    pastEntry.clear();
    return B;
  }
  SmallVector<Value *, 4> atomValues(unsigned n) {
    std::set<unsigned> sup;
    m.support(n, sup);
    SmallVector<Value *, 4> xs;
    for (unsigned v : sup)
      xs.push_back(atomValue(v));
    return xs;
  }

  // Does the output value v reach the point (U, pt): a constant or formal, an instruction before pt in
  // U, or one whose block dominates U.
  bool reaches(Value *v, BasicBlock *U, BasicBlock::iterator pt) {
    auto *I = dyn_cast<Instruction>(v);
    if (!I)
      return true;
    BasicBlock *D = I->getParent();
    if (D == U)
      return pt == U->end() || (&*pt != I && cq::comesBefore(I, &*pt));
    // The chain of unique predecessors needs no tree.
    SmallPtrSet<BasicBlock *, 16> seen{U};
    for (BasicBlock *b = U->getUniquePredecessor(); b && seen.insert(b).second; b = b->getUniquePredecessor())
      if (b == D)
        return true;
    return DT().dominates(D, U);
  }

  // The output value an atom is read through (nullptr: the _ctl entry flag, a formal): as CtxSink reads
  // it, a quantum atom through rail() (operand() would emit a rule 2 recomputation at the builder).
  Value *atomValue(unsigned var) {
    const Atom &a = atomOf(var);
    if (a.kind == AtomKind::Entry)
      return nullptr;
    if (ql(var))
      return a.kind == AtomKind::Eq || a.kind == AtomKind::Addr ? ctx.switchRail(a.v) : ctx.rail(a.v);   // cq-0hhk
    return ctx.operand(a.v).v;
  }

  // The rail type of the value atomValue reads (cq-7jd1z): a condition is an i1, a case atom its scrutinee's
  // own type (rule 13: the equality is taken on the scrutinee), a computed goto atom its 64-bit address.
  RailType atomRailType(unsigned var) {
    const Atom &a = atomOf(var);
    if (a.kind == AtomKind::Eq || a.kind == AtomKind::Addr)
      return railTypeOf(a.v->getType());
    return RailType{Kind::Int, 1};
  }

  bool nodeReaches(unsigned n, BasicBlock *U, BasicBlock::iterator pt) {
    std::set<unsigned> sup;
    m.support(n, sup);
    for (unsigned v : sup)
      if (Value *x = atomValue(v); x && !reaches(x, U, pt))
        return false;
    return true;
  }

  void classicalVars(unsigned n, std::set<unsigned> &out) {
    std::set<unsigned> sup;
    m.support(n, sup);
    for (unsigned v : sup)
      if (!ql(v))
        out.insert(v);
  }

  // ---- classical facts of output edges ----
  struct Decoder {
    JoinRepair &R;
    DenseMap<const Value *, unsigned> condVar;
    std::vector<std::tuple<const Value *, APInt, unsigned>> eqVar;
    std::map<std::pair<const Value *, bool>, unsigned> memo;
    explicit Decoder(JoinRepair &R) : R(R) {}

    unsigned eqOf(const Value *x, const APInt &c) {
      for (auto &[s, k, v] : eqVar)
        if (s == x && k.getBitWidth() == c.getBitWidth() && k == c)
          return R.m.ithVar(v);
      return Bdd::T;   // marker: unknown (callers test with known())
    }
    bool hasEq(const Value *x, const APInt &c) {
      for (auto &[s, k, v] : eqVar)
        if (s == x && k.getBitWidth() == c.getBitWidth() && k == c)
          return true;
      return false;
    }

    // What "x == k" implies: the case atom of k, and no other known case of x (distinct constants).
    unsigned caseIs(const Value *x, const APInt &k) {
      Bdd &m = R.m;
      unsigned r = hasEq(x, k) ? eqOf(x, k) : Bdd::T;
      for (auto &[s, j, v] : eqVar)
        if (s == x && j.getBitWidth() == k.getBitWidth() && j != k)
          r = m.andOp(r, m.notOp(m.ithVar(v)));
      return r;
    }

    // A function over the known atoms implied by "v == pol".
    unsigned implied(const Value *v, bool pol) {
      Bdd &m = R.m;
      if (const auto *k = dyn_cast<ConstantInt>(v))
        return k->isOne() == pol ? Bdd::T : Bdd::F;
      auto key = std::make_pair(v, pol);
      if (auto it = memo.find(key); it != memo.end())
        return it->second;
      unsigned r = Bdd::T;
      if (auto it = condVar.find(v); it != condVar.end()) {
        unsigned x = m.ithVar(it->second);
        r = pol ? x : m.notOp(x);
      } else if (const auto *bo = dyn_cast<BinaryOperator>(v); bo && bo->getType()->isIntegerTy(1)) {
        const Value *a = bo->getOperand(0), *b = bo->getOperand(1);
        switch (bo->getOpcode()) {
        case Instruction::Xor:
          if (const auto *k = dyn_cast<ConstantInt>(b); k && k->isOne())
            r = implied(a, !pol);
          else if (const auto *k = dyn_cast<ConstantInt>(a); k && k->isOne())
            r = implied(b, !pol);
          break;
        case Instruction::And:
          r = pol ? m.andOp(implied(a, true), implied(b, true)) : m.orOp(implied(a, false), implied(b, false));
          break;
        case Instruction::Or:
          r = pol ? m.orOp(implied(a, true), implied(b, true)) : m.andOp(implied(a, false), implied(b, false));
          break;
        default:
          break;
        }
      } else if (const auto *si = dyn_cast<SelectInst>(v); si && si->getType()->isIntegerTy(1)) {
        r = m.orOp(m.andOp(implied(si->getCondition(), true), implied(si->getTrueValue(), pol)),
                   m.andOp(implied(si->getCondition(), false), implied(si->getFalseValue(), pol)));
      } else if (const auto *ic = dyn_cast<ICmpInst>(v); ic && ic->isEquality()) {
        const Value *x = ic->getOperand(0);
        const auto *k = dyn_cast<ConstantInt>(ic->getOperand(1));
        if (!k) {
          x = ic->getOperand(1);
          k = dyn_cast<ConstantInt>(ic->getOperand(0));
        }
        if (k) {
          bool isEq = ic->getPredicate() == ICmpInst::ICMP_EQ;
          if (isEq == pol)
            r = caseIs(x, k->getValue());
          else if (hasEq(x, k->getValue()))
            r = m.notOp(eqOf(x, k->getValue()));
        }
      }
      // cq-rb96s: a compare fixes, besides what it says itself, every atom whose output value is an identical compare
      // (the same predicate over the same operands): two atoms `icmp ne %3, 0` of the C program, or a guard's literal
      // recomputed at the guard (spine guardRecomputes; SQLite flattenSubquery). In addition to the decoding above, never
      // instead of it: `icmp eq %1, 2` is also switch case 2, and not case 1 (SQLite windowCodeOp).
      if (const auto *cv = dyn_cast<CmpInst>(v)) {
        SmallVector<unsigned, 2> same;   // by variable, not by the map's pointer order: one BDD whatever the addresses
        for (auto &[x, var] : condVar)
          if (x != v && isa<CmpInst>(x) && cast<CmpInst>(x)->isIdenticalTo(cv))
            same.push_back(var);
        llvm::sort(same);
        for (unsigned var : same)
          r = m.andOp(r, pol ? m.ithVar(var) : m.notOp(m.ithVar(var)));
      }
      memo[key] = r;
      return r;
    }

    // What the edge from -> to establishes by itself.
    unsigned edge(const BasicBlock *from, const BasicBlock *to) {
      Bdd &m = R.m;
      const Instruction *t = from->getTerminator();
      if (const auto *br = dyn_cast_or_null<BranchInst>(t)) {
        if (br->isUnconditional())
          return Bdd::T;
        unsigned r = Bdd::F;
        if (br->getSuccessor(0) == to)
          r = m.orOp(r, implied(br->getCondition(), true));
        if (br->getSuccessor(1) == to)
          r = m.orOp(r, implied(br->getCondition(), false));
        return r;
      }
      if (const auto *sw = dyn_cast_or_null<SwitchInst>(t)) {
        const Value *x = sw->getCondition();
        unsigned r = Bdd::F, noCase = Bdd::T;
        for (const auto &c : sw->cases()) {
          const APInt &k = c.getCaseValue()->getValue();
          if (c.getCaseSuccessor() == to)
            r = m.orOp(r, caseIs(x, k));
          if (hasEq(x, k))
            noCase = m.andOp(noCase, m.notOp(eqOf(x, k)));
        }
        if (sw->getDefaultDest() == to)
          r = m.orOp(r, noCase);
        return r;
      }
      return Bdd::T;
    }
  };

  // The classical facts over `vars` every output path establishes on the edge p -> J (forward edges of
  // the output CFG from its entry; a back edge of a classical loop contributes nothing).
  unsigned edgeFacts(BasicBlock *p, BasicBlock *J, const std::set<unsigned> &vars) {
    Decoder D(*this);
    unsigned fp = inFacts(D, p, vars);
    return m.andOp(fp, D.edge(p, J));
  }

  // The classical facts over `vars` every forward output path from the entry establishes on reaching U. Leaving an
  // output loop, a fact about a value the loop defines is one trip's (cq-b9w7) and is dropped (a weaker fact, sound):
  // kept, the exits of n loops in a row each add their own atom beside the skip edge's, and the facts past them are a
  // BDD of 2^n nodes in the atoms' order (cq-iaz30, GSL ode-initval rk8pd_apply).
  unsigned inFacts(Decoder &D, BasicBlock *U, const std::set<unsigned> &vars) {
    DenseMap<unsigned, const Instruction *> defOf;
    for (unsigned v : vars) {
      const Atom &a = atomOf(v);
      if (a.kind == AtomKind::Cond)
        D.condVar[ctx.operand(a.v).v] = v;
      else if (a.kind == AtomKind::Eq)
        D.eqVar.emplace_back(ctx.operand(a.v).v, a.c, v);
      else
        continue;
      if (auto *x = dyn_cast<Instruction>(ctx.operand(a.v).v))
        defOf[v] = x;
    }
    Function &OF = ctx.out();
    DenseMap<const BasicBlock *, unsigned> idx, in;
    ReversePostOrderTraversal<Function *> rpot(&OF);
    unsigned i = 0;
    for (BasicBlock *b : rpot)
      idx[b] = i++;
    for (BasicBlock *b : rpot) {
      if (b == &OF.getEntryBlock()) {
        in[b] = Bdd::T;
        continue;
      }
      unsigned f = Bdd::F;
      SmallPtrSet<BasicBlock *, 4> seen;
      for (BasicBlock *q : predecessors(b)) {
        auto qi = idx.find(q);
        if (qi == idx.end() || qi->second >= idx[b] || !seen.insert(q).second)
          continue;
        unsigned e = m.andOp(in[q], D.edge(q, b));
        Loop *out = nullptr;
        for (Loop *L = LI().getLoopFor(q); L && !L->contains(b); L = L->getParentLoop())
          out = L;
        if (out && !m.terminal(e))
          e = m.exists(e, [&](unsigned v) {
            auto it = defOf.find(v);
            return it != defOf.end() && out->contains(it->second->getParent());
          });
        f = m.orOp(f, e);
      }
      in[b] = f;
    }
    auto pi = in.find(U);
    return pi == in.end() ? Bdd::T : pi->second;
  }

  // The classical facts that hold wherever the output reaches the point U: the conditions of the
  // classical branches and switches on every path to it, over every classical atom of the function's
  // path predicates that has its value in the output by now. A rail read at U is needed only where
  // they hold (a path they exclude never reaches U), so they join the caller's don't-care set: an
  // output edge into a join above U that they exclude carries a don't-care (rule 9's arm on its own
  // edge). The point's predicate is the quantum part of its block's (rule 8: C stays a classical
  // branch), so its classical facts are known only from the output CFG.
  unsigned factsAt(BasicBlock *U) {
    if (!pointVars) {
      pointVars.emplace();
      const PathStorage &I = storage(ctx.preds());
      std::set<unsigned> sup;
      for (const auto &e : I.edges)
        m.support(nodeOf(e.second), sup);
      for (const auto &b : I.blocks)
        m.support(nodeOf(b.second), sup);
      for (unsigned v : sup) {
        const Atom &a = atomOf(v);
        if (a.kind != AtomKind::Entry && !ql(v) && ctx.bound(a.v))
          pointVars->insert(v);
      }
    }
    Decoder D(*this);
    return inFacts(D, U, *pointVars);
  }
  std::optional<std::set<unsigned>> pointVars;

  bool noJoinAbove(BasicBlock *U) {
    SmallPtrSet<BasicBlock *, 16> seen;
    while (BasicBlock *s = U->getUniquePredecessor()) {
      if (!seen.insert(U).second)
        return false;
      U = s;
    }
    return pred_empty(U);
  }

  // The nearest block at or above U (through unique predecessors) with several predecessors.
  // cq-a24ig: `read` names the read for the internal error only; built only there (printing a value numbers the whole
  // function).
  BasicBlock *joinAbove(BasicBlock *U, const Value *what, function_ref<std::string()> read) {
    BasicBlock *J = U;
    SmallPtrSet<BasicBlock *, 16> seen;
    while (BasicBlock *s = J->getUniquePredecessor()) {
      if (!seen.insert(J).second)
        break;
      J = s;
    }
    // Rule 9 (cq-pfpy): the walk runs a block on every output path whose classical facts its predicate
    // meets (Walker::next), so a value is read on a path that never minted it only where its arm's
    // predicate, restricted by that path's facts, is false, and the join where that path meets the one
    // that minted it carries it with a don't-care. A point with no join above it and a value that does
    // not reach it is a walk that skipped a block it had to run.
    if (pred_empty(J))
      internalError("pred: a predicate or merge arm reads a value minted where it does not reach the point, on a "
                    "path the walk took without running its block (Walker::next, cq-pfpy): " + read(),
                    isa_and_nonnull<Instruction>(what) && cast<Instruction>(what)->getParent() ? what : U);
    return J;
  }

  SmallVector<BasicBlock *, 4> uniquePreds(BasicBlock *J) {
    SmallVector<BasicBlock *, 4> ps;
    for (BasicBlock *p : predecessors(J))
      if (llvm::find(ps, p) == ps.end())
        ps.push_back(p);
    return ps;
  }

  Value *phiOf(BasicBlock *J, ArrayRef<std::pair<BasicBlock *, Value *>> per, bool handle) {
    bool same = std::all_of(per.begin(), per.end(), [&](const auto &x) { return x.second == per[0].second; });
    if (same)
      return per[0].second;
    std::vector<Value *> key{J};
    for (const auto &x : per)
      key.push_back(x.second);
    if (auto it = phiMemo.find(key); it != phiMemo.end())
      return it->second;   // the same per-edge values met at the same join: one phi
    Type *ty = per[0].second->getType();
    PHINode *phi = PHINode::Create(ty, unsigned(pred_size(J)), "");
    phiMemo[key] = phi;
    phi->insertInto(J, J->begin());
    for (BasicBlock *p : predecessors(J))
      for (const auto &x : per)
        if (x.first == p) {
          if (x.second->getType() != ty)
            internalError("pred: the per-edge values of a join have different types", x.second);
          phi->addIncoming(x.second, p);
          break;
        }
    if (handle)
      ctx.unc().recordMerge(phi);
    return phi;
  }

  // cq-b9w7: phiOf over the entry edges `per` of a classical loop header J, J's own value on each back edge
  // (backEdge): one value on every entry (a loop has one) is J's value as it is; otherwise a phi over the
  // entries naming itself on each back edge (as a merge it names what it named on entry, U1).
  Value *loopPhiOf(BasicBlock *J, ArrayRef<std::pair<BasicBlock *, Value *>> per,
                   const std::function<bool(BasicBlock *)> &backEdge, bool handle) {
    if (none_of(uniquePreds(J), backEdge) ||
        all_of(per, [&](const auto &e) { return e.second == per[0].second; }))
      return phiOf(J, per, handle);
    Type *ty = per[0].second->getType();
    PHINode *phi = PHINode::Create(ty, unsigned(pred_size(J)), "");
    phi->insertInto(J, J->begin());
    for (BasicBlock *p : predecessors(J)) {
      if (backEdge(p)) {
        phi->addIncoming(phi, p);
        continue;
      }
      for (const auto &x : per)
        if (x.first == p) {
          phi->addIncoming(x.second, p);   // one type: the carried value's (or its handle's), as phiOf checks
          break;
        }
    }
    if (handle)
      ctx.unc().recordMerge(phi);
    return phi;
  }

  // cq-pfpy: a join whose per-edge values are being built. Reached again through a back edge, it is a
  // placeholder phi standing for the value the join will carry, replaced by it once built.
  using JoinKey = std::tuple<Value *, unsigned, unsigned, int, BasicBlock *>;
  std::map<JoinKey, PHINode *> building;
  Value *reentered(const JoinKey &key, Type *ty) {
    auto it = building.find(key);
    if (it == building.end()) {
      building[key] = nullptr;
      return nullptr;
    }
    if (!it->second) {
      BasicBlock *J = std::get<4>(key);
      it->second = PHINode::Create(ty, 0, "");
      it->second->insertInto(J, J->begin());
    }
    return it->second;
  }
  Value *settle(const JoinKey &key, Value *v) {
    auto it = building.find(key);
    PHINode *ph = it == building.end() ? nullptr : it->second;
    building.erase(key);
    if (ph) {
      if (v == ph)
        internalError("pred: a value carried around a classical loop that no edge mints");
      ph->replaceAllUsesWith(v);
      for (auto &e : flagMemo)
        if (e.second == ph)
          e.second = v;
      for (auto &e : valueMemo)
        if (e.second == ph)
          e.second = v;
      for (auto &e : constMemo)
        if (e.second == ph)
          e.second = v;
      for (auto it2 = phiMemo.begin(); it2 != phiMemo.end();)
        it2 = is_contained(it2->first, ph) ? phiMemo.erase(it2) : std::next(it2);
      ph->eraseFromParent();
    }
    return v;
  }

public:
  explicit JoinRepair(LoweringContext &ctx)
      : ctx(ctx), O(taintOracle(ctx.T, ctx.S)), ql([this](unsigned v) { return quantumLike(v, *O); }) {}

  bool nodeBound(unsigned n) {
    std::set<unsigned> sup;
    m.support(n, sup);
    return all_of(sup, [&](unsigned v) {
      const Atom &a = atomOf(v);
      return a.kind == AtomKind::Entry || ctx.bound(a.v);
    });
  }

  bool nodeReachesHere(unsigned n) { return nodeReaches(n, ctx.B().GetInsertBlock(), ctx.B().GetInsertPoint()); }

  // cq-pfpy: the incoming of a classically chosen phi the output edge P -> join stands for, read at the
  // builder (P's end): the incomings whose edge predicates meet the edge's classical facts; one value as
  // it is (carried when it does not reach), several a classical select chain on their edge predicates
  // restricted by the facts (their atoms carried likewise). No incoming meets the facts: the edge is
  // never taken, a null value.
  Operand edgeChoice(PHINode &phi, BasicBlock *P, BasicBlock *join, RailType w, Type *fieldTy,
                     const std::function<Operand(const Value *)> &read) {
    const PathStorage &I = storage(ctx.preds());
    const BasicBlock *bb = phi.getParent();
    struct Arm { const Value *v; unsigned node; };
    std::vector<Arm> arms;
    for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
      const BasicBlock *u = phi.getIncomingBlock(i);
      if (!I.rpo.count(u))
        continue;
      unsigned e = nodeOf(ctx.preds().edge(u, bb));
      const Value *v = phi.getIncomingValue(i);
      auto it = std::find_if(arms.begin(), arms.end(), [&](const Arm &a) { return a.v == v; });
      if (it == arms.end())
        arms.push_back({v, e});
      else
        it->node = m.orOp(it->node, e);
    }
    std::set<unsigned> vars;
    for (const Arm &a : arms)
      classicalVars(a.node, vars);
    unsigned c = edgeFacts(P, join, vars);
    std::vector<std::pair<Arm, unsigned>> live;   // arm, its predicate restricted by the facts
    for (const Arm &a : arms) {
      unsigned r = c == Bdd::F ? Bdd::F : m.andOp(a.node, c);
      if (r != Bdd::F && predsMeet(makePred(a.node), makePred(c)))
        live.push_back({a, m.restrict(a.node, c)});
    }
    BasicBlock *U = ctx.B().GetInsertBlock();
    BasicBlock::iterator pt = ctx.B().GetInsertPoint();
    auto value = [&](const Arm &a) {
      Operand op = read(a.v);
      return Operand{carry(op.v, op.handle, w, Carry{a.node, c, -1}, U, pt, &phi), op.handle};
    };
    if (live.empty())
      return Operand{Constant::getNullValue(fieldTy), false};
    Operand acc = value(live.back().first);
    for (size_t k = live.size() - 1; k-- > 0;) {
      Operand x = value(live[k].first);
      if (x.v == acc.v)
        continue;
      // The arm's restricted predicate as a classical i1 at the point, its atoms carried there.
      std::set<unsigned> sup;
      m.support(live[k].second, sup);
      std::map<unsigned, Value *> over;
      for (unsigned v : sup)
        if (Value *a = atomValue(v); a && !reaches(a, U, pt))
          over[v] = carry(a, false, atomRailType(v), Carry{live[k].second, c, int(v)}, U, pt, &phi);
      IRBuilderBase::InsertPointGuard g(ctx.B());
      ctx.B().SetInsertPoint(U, pt);
      CtxSink sink(ctx, &over);
      Value *cond = sink.classical(live[k].second);
      if (x.handle != acc.handle) {
        if (!x.handle)
          x = Operand{seedOf(ctx, x.v, w), true};
        else
          acc = Operand{seedOf(ctx, acc.v, w), true};
      }
      Value *sel = ctx.B().CreateSelect(cond, x.v, acc.v);
      if (x.handle)
        if (auto *si = dyn_cast<Instruction>(sel))
          ctx.unc().recordMerge(si);
      acc = Operand{sel, x.handle};
    }
    return acc;
  }
  bool reachesHere(Value *v) { return reaches(v, ctx.B().GetInsertBlock(), ctx.B().GetInsertPoint()); }

  // A rail holding n at (U, pt) wherever `care` holds (n is a don't-care outside it).
  Value *flagAt(unsigned n, unsigned care, BasicBlock *U, BasicBlock::iterator pt, const Value *what) {
    IRBuilderBase::InsertPointGuard g(ctx.B());
    ctx.B().SetInsertPoint(U, pt);
    if (m.terminal(n) || nodeReaches(n, U, pt)) {
      CtxSink sink(ctx);
      if (m.terminal(n))
        return sink.classicalSeed(n);   // rule 7: a rail holding the constant
      return materialize(n, sink, ql);
    }
    // cq-us8cz (rule 9): with no join above to carry n's atoms over, n is a constant wherever the point's facts hold
    // when they exclude n or its complement, also only by the exclusive cases of one switch (predsMeet; TinyEMU
    // csr_read: a later case's quantum edge read on the path of an earlier case, whose block the walk did not run).
    // A point whose facts contradict the care set is reached on no path the flag is needed on (either constant serves).
    if (noJoinAbove(U)) {
      unsigned c = m.andOp(care, factsAt(U));
      for (unsigned k : {Bdd::F, Bdd::T})
        if (!predsMeet(makePred(k == Bdd::F ? n : m.notOp(n)), makePred(c)))
          return CtxSink(ctx).classicalSeed(k);
      // Each atom those facts fix (a case of a switch whose other case they hold, TinyEMU csr_read) has its value in n:
      // the rest of n agrees with n wherever they hold, and may read only atoms that reach the point.
      std::set<unsigned> sup;
      m.support(n, sup);
      unsigned r = n;
      for (unsigned v : sup) {
        if (!predsMeet(makePred(m.ithVar(v)), makePred(c)))
          r = m.cofactor(r, v, false);
        else if (!predsMeet(makePred(m.notOp(m.ithVar(v))), makePred(c)))
          r = m.cofactor(r, v, true);
      }
      if (r != n)
        return flagAt(r, care, U, pt, what);
    }
    BasicBlock *J = joinAbove(U, what, [&] { return "the predicate " + describe(n); });
    if (BasicBlock *E = loopEntry(J, U, atomValues(n)))
      return flagAt(n, care, E, E->getTerminator()->getIterator(), what);   // cq-03rdt
    {
      // Per-edge flags need every atom the point reads to exist where J's edges leave. When one is
      // minted between J and the point (a later arm's own condition), the atoms that do not reach are
      // carried to the point instead, each by a phi over the joins above it with a |0> seed (false)
      // on an edge where the predicate, restricted by that edge's facts, does not read it; the flag is
      // then computed at the point as usual (its classical seeds make it exact on every path).
      std::set<unsigned> sup;
      m.support(n, sup);
      bool perEdge = true;
      for (unsigned v : sup)
        if (Value *x = atomValue(v); x && reaches(x, U, pt) && !reaches(x, J, J->begin()))
          perEdge = false;
      if (!perEdge) {
        std::map<unsigned, Value *> over;
        for (unsigned v : sup)
          if (Value *x = atomValue(v); x && !reaches(x, U, pt))
            over[v] = carry(x, ql(v), atomRailType(v), Carry{n, care, int(v)}, U, pt, what);
        IRBuilderBase::InsertPointGuard g2(ctx.B());
        ctx.B().SetInsertPoint(U, pt);
        CtxSink sink(ctx, &over);
        return materialize(n, sink, ql);
      }
    }
    std::set<unsigned> vars;
    classicalVars(n, vars);
    classicalVars(care, vars);
    // A join reached again while its flag is being built (a classical loop's back edge): the flag it
    // will be (cq-pfpy; no depth bound).
    JoinKey jkey{nullptr, n, care, -2, J};
    if (Value *x = reentered(jkey, Type::getInt32Ty(ctx.M.getContext())))
      return x;
    // cq-b9w7 (CR rules 8, 14): J heads a classical loop and every atom n reads is defined outside it: n is
    // the same on every trip, so on a back edge the flag is J's own (not a seed per trip; the facts of an edge
    // inside the loop are one trip's, not those of the point after the loop the care set speaks of).
    std::set<unsigned> nsup;
    m.support(n, nsup);
    bool invariant = all_of(nsup, [&](unsigned v) {
      auto *x = dyn_cast_or_null<Instruction>(atomValue(v));
      return !x || !DT().dominates(J, x->getParent());
    });
    auto backEdge = [&](BasicBlock *p) { return invariant && DT().dominates(J, p); };
    std::vector<std::pair<BasicBlock *, Value *>> per;
    for (BasicBlock *p : uniquePreds(J)) {
      if (backEdge(p))
        continue;
      // cq-03rdt: an edge leaving a loop J is not in is read at the loop's entry, without one trip's facts.
      BasicBlock *q = loopEntry(p, J, atomValues(n));
      unsigned c = q ? care : m.andOp(care, edgeFacts(p, J, vars));
      if (!q)
        q = p = onEdge(p, J);
      unsigned np = c == Bdd::F ? Bdd::F : m.restrict(n, c);
      auto key = std::make_tuple(np, c, q);
      Value *v;
      if (auto it = flagMemo.find(key); it != flagMemo.end())
        v = it->second;
      else
        v = flagMemo[key] = flagAt(np, c, q, q->getTerminator()->getIterator(), what);
      per.push_back({p, v});
    }
    return settle(jkey, loopPhiOf(J, per, backEdge, true));
  }

  Value *flagHere(unsigned n, unsigned care, const Value *what) {
    BasicBlock *U = ctx.B().GetInsertBlock();
    return flagAt(n, pointCare(care, U), U, ctx.B().GetInsertPoint(), what);
  }

  // The caller's don't-care set narrowed by the classical facts at U (factsAt).
  unsigned pointCare(unsigned care, BasicBlock *U) {
    unsigned c = m.andOp(care, factsAt(U));
    return c == Bdd::F ? care : c;
  }

  // What a carried value is needed for: a merge arm (var < 0), unneeded on an edge where `node` (its
  // predicate) restricted by the edge's facts is false; or atom `var` of the predicate `node` under
  // `care`, unneeded where the restricted predicate does not read it.
  struct Carry { unsigned node, care; int var; };

  // The value v at (U, pt), carried by phis over the classical joins above the point.
  Value *carry(Value *v, bool handle, RailType w, Carry k, BasicBlock *U, BasicBlock::iterator pt,
               const Value *what) {
    if (reaches(v, U, pt))
      return v;
    // Rule 9: a merge arm the point's classical facts exclude, at a point with no join above it to carry it
    // over (the entry's own classical arm, a unit there reading a binding an earlier unit made in the other
    // arm: wcsrtombs' loops into one join). Its don't-care: a |0> seed here, or the null value (rule 7).
    // cq-us8cz: the facts at the point narrow the care set, and they may exclude the arm only by the exclusive cases of
    // one switch (predsMeet; TinyEMU csr_read: an earlier case's path reaching the join of a later case's arm). When they
    // contradict the care set, no path the value is needed on reaches the point (a classically infeasible edge: a case of
    // a switch on the value an enclosing switch already fixed to another case).
    if (k.var < 0 && noJoinAbove(U) && !predsMeet(makePred(k.node), makePred(m.andOp(k.care, factsAt(U))))) {
      Type *ty = handle ? irTypeOf(ctx.M.getContext(), w) : v->getType();
      if (!handle)
        return Constant::getNullValue(ty);
      IRBuilderBase::InsertPointGuard g(ctx.B());
      ctx.B().SetInsertPoint(U, pt);
      return seedOf(ctx, Constant::getNullValue(ty), w);
    }
    BasicBlock *J = joinAbove(U, what, [&] {
      std::string vs;
      raw_string_ostream(vs) << *v;
      return (k.var < 0 ? "the merge arm " : "the atom ") + vs + " under " + describe(k.node);
    });
    if (BasicBlock *E = loopEntry(J, U, {v}))
      return carry(v, handle, w, k, E, E->getTerminator()->getIterator(), what);   // cq-03rdt
    auto jkey = std::make_tuple(v, k.node, k.care, k.var, J);
    if (Value *x = reentered(jkey, handle ? irTypeOf(ctx.M.getContext(), w) : v->getType()))
      return x;
    std::set<unsigned> vars;
    classicalVars(k.node, vars);
    classicalVars(k.care, vars);
    // cq-b9w7 (CR rules 9, 14): J heads a classical loop that v is defined outside of. Around the loop's
    // back edges v is what it was at J (no block of the loop defines it): the carried value is J's own phi
    // there, on every back edge, needed or not. A don't-care seed on a back edge would mint a rail per trip
    // (and the classical facts of an edge inside the loop are those of one trip, not of the point after the
    // loop the care set speaks of).
    auto *vi = dyn_cast<Instruction>(v);
    bool outside = !vi || !DT().dominates(J, vi->getParent());
    auto backEdge = [&](BasicBlock *p) { return outside && DT().dominates(J, p); };
    std::vector<std::pair<BasicBlock *, Value *>> per;
    for (BasicBlock *p : uniquePreds(J)) {
      if (backEdge(p))
        continue;
      if (BasicBlock *E = loopEntry(p, J, {v})) {
        // cq-03rdt: an edge leaving a loop J is not in carries v as it is at the loop's entry.
        per.push_back({p, carry(v, handle, w, k, E, E->getTerminator()->getIterator(), what)});
        continue;
      }
      unsigned c = m.andOp(k.care, edgeFacts(p, J, vars));
      p = onEdge(p, J);
      unsigned a = c == Bdd::F ? Bdd::F : m.restrict(k.node, c);
      bool unneeded, one = false;
      if (k.var < 0) {
        unneeded = a == Bdd::F;
      } else {
        // cq-1b92: the flag at the point is computed from the UNRESTRICTED predicate over the carried
        // values, so a constant stands in for the atom on this edge only if it leaves that predicate's
        // value unchanged wherever c holds. The restriction dropping the atom is not enough (c may fix
        // it: carrying false for an atom c fixes true fires the gate under the wrong control):
        //   - c fixes the atom to b: carry b (it is the atom's value on every such path);
        //   - the predicate agrees with its cofactor at b on c with the atom quantified out: carry b
        //     (substitutions made on nested edges compose: each such set is closed under its atom's change).
        //     cq-7prhl: c may read the atom without fixing it (an identical compare of another arm ties it
        //     to that one's literal, SoftFloat f16_div with b classical); quantified out, it is still a
        //     constant wherever the predicate does not depend on it;
        //   - otherwise the atom is needed here: carried by its real value (or further joins).
        unsigned var = unsigned(k.var), lit = m.ithVar(var);
        std::set<unsigned> asup;
        m.support(a, asup);
        unsigned free = m.exists(c, [&](unsigned v) { return v == var; });
        auto agrees = [&](bool b) {
          return m.andOp(free, m.xorOp(k.node, m.cofactor(k.node, var, b))) == Bdd::F;
        };
        if (c == Bdd::F) {
          unneeded = true;   // no path: never read
        } else if (asup.count(var)) {
          unneeded = false;
        } else if (m.andOp(c, m.notOp(lit)) == Bdd::F) {
          unneeded = one = true;
        } else if (m.andOp(c, lit) == Bdd::F) {
          unneeded = true;
        } else if (agrees(false)) {
          unneeded = true;
        } else if (agrees(true)) {
          unneeded = one = true;
        } else {
          unneeded = false;
        }
      }
      auto key = std::make_tuple(v, a, c, p);
      auto ckey = std::make_tuple(v, a, c, p, k.var, one);   // a switch atom's constant depends on its case
      Value *x;
      if (auto it = unneeded ? constMemo.find(ckey) : constMemo.end(); it != constMemo.end()) {
        x = it->second;
      } else if (auto it = unneeded ? valueMemo.end() : valueMemo.find(key); it != valueMemo.end()) {
        x = it->second;
      } else if (unneeded) {
        // Not read on this edge beyond a constant: a fresh rail seeded with it (rule 7), or the constant
        // (|0> / null for a merge arm).
        Type *ty = handle ? irTypeOf(ctx.M.getContext(), w) : v->getType();
        Constant *k0 = one ? ConstantInt::get(ty, 1) : Constant::getNullValue(ty);
        if (k.var >= 0 && atomOf(unsigned(k.var)).kind == AtomKind::Eq) {
          // A switch atom is carried by its scrutinee: a value equal to its case constant, or not.
          const APInt &kc = atomOf(unsigned(k.var)).c;
          if (ty != IntegerType::get(ctx.M.getContext(), kc.getBitWidth()))
            internalError("pred: a carried switch atom whose scrutinee type is not its case constant's", v);
          k0 = ConstantInt::get(ty, one ? kc : kc + 1);
        } else if (k.var >= 0 && atomOf(unsigned(k.var)).kind == AtomKind::Addr) {
          // A computed goto atom is carried by its address: the destination's address, or another value.
          Constant *ka = caseAddress(atomOf(unsigned(k.var)).bb);
          if (!one)
            ka = ConstantExpr::getAdd(ka, ConstantInt::get(ka->getType(), 1));
          if (ty->isPointerTy())
            k0 = ConstantExpr::getIntToPtr(ka, ty);
          else if (ty == ka->getType())
            k0 = ka;
          else
            internalError("pred: a carried computed goto atom whose address is no pointer or i64", v);
        }
        if (handle) {
          IRBuilderBase::InsertPointGuard g(ctx.B());
          ctx.B().SetInsertPoint(p->getTerminator());
          x = seedOf(ctx, k0, w);
        } else {
          x = k0;
        }
        constMemo[ckey] = x;
      } else {
        x = valueMemo[key] =
            carry(v, handle, w, Carry{a, c, k.var}, p, p->getTerminator()->getIterator(), what);
      }
      per.push_back({p, x});
    }
    return settle(jkey, loopPhiOf(J, per, backEdge, handle));
  }

  // The arm is read only where `care` holds: outside it, it is a don't-care.
  Operand operandHere(const Operand &op, RailType w, unsigned armNode, unsigned care, const Value *what) {
    BasicBlock *U = ctx.B().GetInsertBlock();
    return Operand{carry(op.v, op.handle, w, Carry{armNode, pointCare(care, U), -1}, U, ctx.B().GetInsertPoint(),
                         what),
                   op.handle};
  }
};

Operand CtxMergeSink::edgeChoice(PHINode &phi, BasicBlock *P, BasicBlock *join, RailType w, Type *fieldTy,
                                 const std::function<Operand(const Value *)> &read) {
  JoinRepair R(ctx);
  return R.edgeChoice(phi, P, join, w, fieldTy, read);
}

// cq-pfpy: an incoming value of a classically chosen phi read where its output edge leaves; one minted
// in a block that does not dominate that point is carried there by the classical joins above it, a
// don't-care (|0>, or the null value) on a join edge whose facts exclude the phi's incoming edge.
Operand CtxMergeSink::reaching(const Operand &op, RailType w, const PHINode &phi, const BasicBlock *u) {
  JoinRepair R(ctx);
  if (R.reachesHere(op.v))
    return op;
  return R.operandHere(op, w, nodeOf(ctx.preds().edge(u, phi.getParent())), Bdd::T, &phi);
}

} // namespace
} // namespace pred_detail

using namespace pred_detail;

bool predReadable(LoweringContext &ctx, const Pred &p) {
  JoinRepair R(ctx);
  return R.nodeBound(nodeOf(p));
}

Operand reachingOperand(LoweringContext &ctx, const Operand &op, RailType w, const Pred &arm, const Pred &care) {
  JoinRepair R(ctx);
  if (R.reachesHere(op.v))
    return op;
  return R.operandHere(op, w, nodeOf(arm), nodeOf(care), nullptr);
}

Value *PathPredicates::flag(LoweringContext &ctx, const Pred &p) { return flag(ctx, p, Pred::top()); }

Value *PathPredicates::flag(LoweringContext &ctx, const Pred &p, const Pred &care) {
  unsigned n = nodeOf(p);
  if (n == Bdd::T)
    return nullptr;
  if (n == Bdd::F) {
    // cq-rb96s (rule 7): -O1 can keep a block no path reaches, its predicate false (GLPK lux_decomp branches twice on one
    // `n < 1` around loops; mpl_constraint_statement's switch default where an earlier switch on the value admits only
    // its cases). The C program never runs it: its controlled code runs under a |0> seed and does nothing.
    CtxSink sink(ctx);
    return sink.classicalSeed(n);
  }
  {
    JoinRepair R(ctx);   // cq-2p1p: an atom minted in a classical arm that does not reach the point
    if (!R.nodeReachesHere(n))
      return R.flagHere(n, nodeOf(care), nullptr);
  }
  std::shared_ptr<Oracle> O = taintOracle(ctx.T, ctx.S);
  CtxSink sink(ctx);
  return materialize(n, sink, quantumLikeFn(ctx, O));
}

Value *classicalValue(LoweringContext &ctx, const Pred &p) {
  CtxSink sink(ctx);
  return sink.classical(nodeOf(p));
}

namespace {
Value *selectChainAt(LoweringContext &ctx, ArrayRef<std::pair<Pred, Operand>> arms, RailType w, unsigned care,
                     const Value *what);
}

// Rule 9: one select per distinct arm, the complement innermost, into fresh rails.
Value *selectChain(LoweringContext &ctx, ArrayRef<std::pair<Pred, Operand>> arms, RailType w) {
  return selectChainAt(ctx, arms, w, Bdd::T, nullptr);
}

Value *selectChain(LoweringContext &ctx, ArrayRef<std::pair<Pred, Operand>> arms, RailType w, const Pred &care) {
  return selectChainAt(ctx, arms, w, nodeOf(care), nullptr);
}

namespace {
// selectChain under a don't-care set: the merge is read only where `care` holds (the merge block's
// predicate), which a per-edge select condition at a classical join may use (cq-2p1p).
Value *selectChainAt(LoweringContext &ctx, ArrayRef<std::pair<Pred, Operand>> arms, RailType w, unsigned care,
                     const Value *what) {
  if (arms.empty())
    internalError("pred: selectChain with no arms");
  std::vector<unsigned> nodes;
  for (auto &a : arms)
    nodes.push_back(nodeOf(a.first));
  std::vector<SelectNode> tree = selectTree(nodes);
  if (tree[0].arm >= 0) {
    // One arm reaches the merge on every path: the merge is that value (a representation change).
    Operand op = arms[tree[0].arm].second;
    // cq-iaz30 (rule 9; SQLite allocateBtreePage): the only arm (the others poison or undef) may be minted on a classical
    // path that joins others above the point; there its value is carried, a don't-care where the path excludes its arm.
    if (JoinRepair R(ctx); !R.reachesHere(op.v))
      op = R.operandHere(op, w, nodes[tree[0].arm], care, what);
    return op.handle ? op.v : seedOf(ctx, op.v, w);
  }
  std::shared_ptr<Oracle> O = taintOracle(ctx.T, ctx.S);
  auto ql = quantumLikeFn(ctx, O);
  Bdd &m = Bdd::get();
  JoinRepair R(ctx);
  // Inner selects first (the true side's, then the false side's), each node's select after both.
  // ctxt: the arms' union and the tree conditions above node k (where its select is read). cq-m16f6: made only where
  // read; the union of a loop's many latch edges can be far larger than any arm.
  std::vector<unsigned> above;
  std::optional<unsigned> all;
  auto ctxtHere = [&] {
    if (!all) {
      all = Bdd::F;
      for (unsigned n : nodes)
        all = m.orOp(*all, n);
    }
    unsigned ctxt = *all;
    for (unsigned c : above)
      ctxt = m.andOp(ctxt, c);
    return ctxt;
  };
  std::function<Operand(int)> emit = [&](int k) -> Operand {
    const SelectNode &nd = tree[k];
    if (nd.arm >= 0) {
      const Operand &op = arms[nd.arm].second;
      if (R.reachesHere(op.v))
        return op;
      return R.operandHere(op, w, nodes[nd.arm], care, what);   // cq-2p1p: an arm minted in a classical arm
    }
    unsigned c = nd.cond;
    above.push_back(c);
    Operand tv = emit(nd.thenIdx);
    above.back() = m.notOp(c);
    Operand fv = emit(nd.elseIdx);
    above.pop_back();
    Value *cond;
    if (!R.nodeReachesHere(c)) {
      // cq-2p1p: per-edge flags of the condition, a don't-care outside this select's context.
      cond = R.flagHere(c, m.andOp(care, ctxtHere()), what);
    } else if (auto g = negatedAtom(c, ql)) {
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
    return Operand{ctx.emitTemplate(spec, {Operand{cond, true}, tv, fv}), true};
  };
  // cq-03rdt: selectTree restricts each condition to the arms' union (buildSelect's context), so outside it a
  // condition says nothing and no arm is chosen there: the select is read only inside it, and a flag of a condition
  // is a don't-care outside (a caller's arms on one classical side only, read where the other side also passes).
  return emit(0).v;
}
} // namespace

Value *lowerMerge(LoweringContext &ctx, PHINode &phi) {
  const PathStorage &I = storage(ctx.preds());
  const BasicBlock *bb = phi.getParent();
  if (I.F != bb->getParent())
    internalError("pred: lowerMerge before PathPredicates::compute of its function", &phi);
  if (I.loopHeaders.count(bb))
    internalError("pred: lowerMerge on a loop-header phi (a carried value: the loop modules)", &phi);
  bool code = phi.getType()->isPointerTy();   // rule 3: an i64 integer
  if (!scalarRailType(phi.getType()) && !code)
    internalError("pred: lowerMerge of a vector, aggregate or pointer phi (every caller routes a composite to "
                  "lowerMergeFields and a data pointer to rule 3, rules 21, 26)",
                  &phi);

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
  // LLVM's refinement of poison/undef (cq-lyzw, rule 24's escape returns): an incoming poison or undef
  // value is no arm of its own unless every incoming value is one.
  bool allUndef = all_of(phi.incoming_values(), [](const Value *v) { return isa<UndefValue>(v); });
  Bdd &m = Bdd::get();
  for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
    const BasicBlock *from = phi.getIncomingBlock(i);
    auto r = I.rpo.find(from);
    if (r == I.rpo.end())
      continue;   // an unreachable predecessor never selects
    unsigned e = nodeOf(ctx.preds().edge(from, bb));
    const Value *v = phi.getIncomingValue(i);
    if (isa<UndefValue>(v) && !allUndef)
      continue;   // poison or undef on that edge: any value refines it, the other arms' merge among them
    auto it = std::find_if(arms.begin(), arms.end(), [&](const Arm &a) { return a.v == v; });
    if (it == arms.end())
      arms.push_back({v, e, i});
    else
      it->node = m.orOp(it->node, e);
  }
  std::stable_sort(arms.begin(), arms.end(), [](const Arm &a, const Arm &b) { return a.order < b.order; });
  std::vector<std::pair<Pred, Operand>> chain;
  for (const Arm &a : arms)
    chain.push_back({makePred(a.node), code ? addressAsInt(ctx, ctx.operand(a.v)) : ctx.operand(a.v)});
  return selectChainAt(ctx, chain, mergeRail(phi.getType()), nodeOf(I.blocks.lookup(bb)), &phi);
}

namespace {
void scalarLeafTypes(Type *t, SmallVectorImpl<Type *> &out) {
  if (auto *st = dyn_cast<StructType>(t)) {
    for (Type *e : st->elements())
      scalarLeafTypes(e, out);
  } else if (auto *at = dyn_cast<ArrayType>(t)) {
    for (uint64_t i = 0; i < at->getNumElements(); ++i)
      scalarLeafTypes(at->getElementType(), out);
  } else if (auto *vt = dyn_cast<FixedVectorType>(t)) {
    for (unsigned i = 0; i < vt->getNumElements(); ++i)
      out.push_back(vt->getElementType());
  } else {
    out.push_back(t);
  }
}
} // namespace

// Rules 9, 25, 26 (cq-oa67): a phi of a vector, struct or array is one merge per field, each exactly as
// lowerMerge merges a scalar: a classical phi over the field's handles where every incoming edge is
// chosen classically, else the rule 9 select chain of the field's distinct incoming values. A field
// that is the same classical value on every arm stays classical. Binds the phi's fields (aggr).
SmallVector<Operand, 4> mergeFieldsOf(LoweringContext &ctx, PHINode &phi, ArrayRef<RailType> rails,
                                      ArrayRef<Type *> tys,
                                      const std::function<SmallVector<Operand, 4>(const Value *)> &read) {
  const PathStorage &I = storage(ctx.preds());
  const BasicBlock *bb = phi.getParent();
  if (I.F != bb->getParent())
    internalError("pred: mergeFieldsOf before PathPredicates::compute of its function", &phi);
  if (I.loopHeaders.count(bb))
    internalError("pred: mergeFieldsOf on a loop-header phi (a carried value: the loop modules)", &phi);
  if (rails.size() != tys.size())
    internalError("pred: mergeFieldsOf with a rail type per field that does not match its types", &phi);
  SmallVector<Operand, 4> out;
  if (classicalChoice(ctx, phi)) {
    CtxMergeSink sink(ctx);
    auto outOf = [&](const BasicBlock *u) -> BasicBlock * { return I.rpo.count(u) ? ctx.block(u) : nullptr; };
    for (unsigned k = 0; k < tys.size(); ++k)
      out.push_back(classicalPhiOf(phi, ctx.B().GetInsertBlock(), ctx.B(), outOf, sink, rails[k], tys[k],
                                   [&](const Value *v) { return read(v)[k]; }, /*seedClassical=*/false));
    return out;
  }

  struct Arm { const Value *v; unsigned node; unsigned order; };
  std::vector<Arm> arms;
  // LLVM's refinement of poison/undef (cq-lyzw, rule 24's escape returns): an incoming poison or undef
  // value is no arm of its own unless every incoming value is one.
  bool allUndef = all_of(phi.incoming_values(), [](const Value *v) { return isa<UndefValue>(v); });
  Bdd &m = Bdd::get();
  for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
    const BasicBlock *from = phi.getIncomingBlock(i);
    if (!I.rpo.count(from))
      continue;   // an unreachable predecessor never selects
    unsigned e = nodeOf(ctx.preds().edge(from, bb));
    const Value *v = phi.getIncomingValue(i);
    if (isa<UndefValue>(v) && !allUndef)
      continue;   // poison or undef on that edge: any value refines it, the other arms' merge among them
    auto it = std::find_if(arms.begin(), arms.end(), [&](const Arm &a) { return a.v == v; });
    if (it == arms.end())
      arms.push_back({v, e, i});
    else
      it->node = m.orOp(it->node, e);
  }
  std::stable_sort(arms.begin(), arms.end(), [](const Arm &a, const Arm &b) { return a.order < b.order; });
  std::vector<SmallVector<Operand, 4>> armFields;
  for (const Arm &a : arms) {
    armFields.push_back(read(a.v));
    if (armFields.back().size() != tys.size())
      internalError("pred: mergeFieldsOf read an incoming with another field count", &phi);
  }
  for (unsigned k = 0; k < tys.size(); ++k) {
    bool same = all_of(armFields, [&](const SmallVector<Operand, 4> &f) { return f[k].v == armFields[0][k].v; });
    if (same) {
      out.push_back(armFields[0][k]);   // one value on every arm (a classical field stays classical)
      continue;
    }
    if (tys[k]->isPointerTy())
      unimplemented("pred: a pointer field of a composite merged under a quantum predicate (rule 21's pointer "
                    "merge of a field)",
                    &phi);
    std::vector<std::pair<Pred, Operand>> chain;
    for (unsigned a = 0; a < arms.size(); ++a)
      chain.push_back({makePred(arms[a].node), armFields[a][k]});
    out.push_back(Operand{selectChainAt(ctx, chain, rails[k], nodeOf(I.blocks.lookup(bb)), &phi), true});
  }
  return out;
}

bool classicalChoice(LoweringContext &ctx, const PHINode &phi) {
  const PathStorage &I = storage(ctx.preds());
  const BasicBlock *bb = phi.getParent();
  std::shared_ptr<Oracle> CO = taintOracle(ctx.T, ctx.S);
  for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i)
    if (I.rpo.count(phi.getIncomingBlock(i)) &&
        !isClassicalNode(nodeOf(ctx.preds().edge(phi.getIncomingBlock(i), bb)), *CO))
      return false;
  return true;
}

void lowerMergeFields(LoweringContext &ctx, PHINode &phi, bool rebind) {
  SmallVector<Type *, 8> tys;
  scalarLeafTypes(phi.getType(), tys);
  auto fieldsOf = [&](const Value *v) {
    SmallVector<Operand, 4> f = aggr::flattenResult(ctx, v);
    if (f.size() != tys.size())
      unimplemented("pred: a merge of a composite with a packed integer leaf (cq-0umd: its field widths are not "
                    "recorded)",
                    &phi);
    return f;
  };
  SmallVector<RailType, 8> rails;
  for (Type *t : tys)
    rails.push_back(t->isPointerTy() ? RailType{Kind::Int, 64} : railTypeOf(t));
  SmallVector<Operand, 4> out = mergeFieldsOf(ctx, phi, rails, tys, fieldsOf);
  if (rebind)
    ctx.rebind(&phi, out);
  else
    aggr::bindLeafFields(ctx, &phi, out, SmallVector<unsigned, 8>(tys.size(), 1));
}

Value *lowerSelect(LoweringContext &ctx, SelectInst &sel) {
  Value *c = sel.getCondition();
  bool code = sel.getType()->isPointerTy();   // rule 3: an i64 integer
  if (c->getType()->isVectorTy() || (!scalarRailType(sel.getType()) && !code))
    internalError("pred: lowerSelect of a vector, aggregate or data pointer select (the spine routes them to aggr "
                  "and rule 3)",
                  &sel);
  // cq-iaz30 (rules 9, 14; SQLite sqlite3AddColumn): a condition taint calls quantum that this evaluation bound classically
  // (a classically bounded K-loop's induction read in one trip's exit arm) is a classical choice here, as a classical one.
  auto cf = ctx.bound(c) ? ctx.fields(c) : SmallVector<Operand, 4>();
  bool boundClassical = cf.size() == 1 && !cf.front().handle;
  if (!ctx.T.isQuantum(c, ctx.S) || boundClassical) {
    CtxMergeSink sink(ctx);   // rule 9 at a58c3a4: a classical select over the handles, no gate
    // Rule 14: a classical per-trip value read after a quantum-exit loop is its exit value, a rail (exit capture; the
    // induction's test in musl-shaped `i != 0` after the loop): no atom of any predicate, one select on that rail.
    if (Operand cr = ctx.operand(c); cr.handle) {
      RailType w = mergeRail(sel.getType());
      auto handle = [&](const Value *v) {
        Operand o = code ? addressAsInt(ctx, ctx.operand(v)) : ctx.operand(v);
        return o.handle ? o : Operand{sink.seed(o.v, w), true};
      };
      abi::TemplateSpec spec;
      spec.op = "select";
      spec.w = w;
      Operand t = handle(sel.getTrueValue()), f = handle(sel.getFalseValue());
      return ctx.emitTemplate(spec, {cr, t, f});
    }
    return classicalSelect(sel, ctx.B(), sink);
  }
  Pred p = Pred::atom(c);
  auto read = [&](const Value *v) { return code ? addressAsInt(ctx, ctx.operand(v)) : ctx.operand(v); };
  std::pair<Pred, Operand> arms[] = {{p, read(sel.getTrueValue())}, {!p, read(sel.getFalseValue())}};
  // cq-7prhl (rule 9): the select is read only where its block runs, as a merge (lowerMerge): an operand minted in a
  // classical arm is a don't-care on a classical path the block's predicate excludes (SoftFloat f64_mulAdd's exponent
  // select after the c == 0 return, c classical).
  return selectChainAt(ctx, arms, mergeRail(sel.getType()), nodeOf(storage(ctx.preds()).blocks.lookup(sel.getParent())),
                       &sel);
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

Value *PathPredicates::negatedAtomRail(LoweringContext &ctx, const Pred &q) {
  std::shared_ptr<Oracle> O = taintOracle(ctx.T, ctx.S);
  if (auto g = negatedAtom(nodeOf(q), quantumLikeFn(ctx, O))) {
    CtxSink sink(ctx);
    return sink.atomRail(*g);
  }
  return nullptr;
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
  {
    // cq-2p1p: a phase in a block reached from several classically chosen arms whose predicate reads
    // rails minted in them: rz_i1 on the classical phi of the per-edge flags.
    JoinRepair R(ctx);
    if (!R.nodeReachesHere(n)) {
      ctx.emitCore(rz, {R.flagHere(n, Bdd::T, &cqPhi), angle.v});
      return;
    }
  }
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
