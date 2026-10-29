// Module spine (cq-xja3): rule 2's classical collapse.
//
// CONTRACT
//
//  CR rule 2: "a value computed only from measured rails and classical values is classical: its rail
//  (a flag too) is uncomputed while its sources still hold the outcome, and the value is recomputed
//  by ordinary classical instructions from the outcomes; a merge under such a flag is a classical
//  select" (155, 140).
//
//  - History. Every rail minted through LoweringContext::emitTemplate (a template forward call) or
//    emitCore (an alloc seed) gets a RailHist; every later in-place XOR-type core gate emitted on it
//    (not_i1, xor_i1, and_i1, or_i1, copy, xorc and their controlled forms) is appended to it. A
//    non-diagonal gate on it (ry, ry_qangle) makes it opaque. Rails the spine's emitters did not mint
//    (clone formals, QRAM loads, tape writes, rails other modules emit directly) have no history and
//    never collapse.
//  - Collapsible at the builder's point. A rail is classical there when it was measured at a point
//    that reaches it (the original measurement dominates the instruction being lowered, or the
//    output measurement call dominates the builder's point), or when its minting call and every
//    write on it dominate the builder's point and every rail they read is classical there. It
//    collapses only when at least one measured rail is among its sources (cq-nvfi: a source read
//    before a non-diagonal gate hit it, at the minting call or a write, makes the rail not classical:
//    it read a value that neither the source's later basis value nor its outcome recomputes): a rail built from seeds
//    alone (a merge of classical arms) is the quantum control flow's own representation and stays.
//  - Recomputation. A measured rail is its outcome. A template rail whose record stands for exactly
//    one original non-phi instruction (its only field) is that instruction copied classically with
//    its operands remapped (which collapses them in turn). A template rail with no such instruction
//    is recomputed from its record: select and icmp; any other op is cq::unimplemented. A seed is its
//    alloc literal. Then its writes are replayed classically in order. Recomputations are cached per
//    rail while they dominate the builder's point.
//  - Uncompute. Nothing is emitted for the rail itself: once every later reader takes the classical
//    value, the rail's last IR use is behind, and uncompute's ordinary flush (reverse dependency
//    order, after the last consumer) uncomputes and frees it. Its measured sources keep their
//    outcomes from the measurement on (CR §1.3: a measured rail is never rotated again), so the _unc
//    reads them while they still hold the outcome.
//  - Where it applies. LoweringContext::operand (every data use). rail() (a flag atom, a control, an
//    in-place target) never collapses a derived rail: a flag stays the quantum control of the arms it
//    guards, which commutes with the measurement of its sources.
#include "SpineInternal.h"

#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IntrinsicInst.h"

using namespace llvm;

namespace cq::spine {

namespace {

// Does `def` (an instruction of the output function) dominate the builder's insertion point? The
// output function is under construction, so dominance is read along the chain of single
// predecessors from the insertion block: the walk emits forward edges into a block before it, and a
// back edge never changes which block dominates a loop header from outside.
bool outAvailable(Shared &sh, const Instruction *def) {
  BasicBlock *cur = sh.B.GetInsertBlock();
  if (!cur || !def)
    return false;
  if (def->getParent() == cur) {
    BasicBlock::iterator ip = sh.B.GetInsertPoint();
    return ip == cur->end() || def->comesBefore(&*ip);
  }
  SmallPtrSet<BasicBlock *, 8> seen;
  for (BasicBlock *b = cur->getSinglePredecessor(); b && seen.insert(b).second; b = b->getSinglePredecessor())
    if (b == def->getParent())
      return true;
  return false;
}

// Does output instruction a come before b on every path to b (a dominates b in the output CFG built
// so far)? cq-drcl: the predecessors of b's block are walked backwards without passing a's block; a
// block with no predecessor reached that way (the entry, or a block not linked yet) is a path that
// avoids a. Conservative: false when unknown. Edges the walk adds later are forward edges into blocks
// not emitted yet or back edges to a loop header, neither of which opens a path into b avoiding a.
bool outBefore(const Instruction *a, const Instruction *b) {
  const BasicBlock *ab = a->getParent(), *bb = b->getParent();
  if (ab == bb)
    return a != b && a->comesBefore(b);
  SmallPtrSet<const BasicBlock *, 16> seen;
  SmallVector<const BasicBlock *, 16> work{bb};
  seen.insert(bb);
  while (!work.empty()) {
    const BasicBlock *x = work.pop_back_val();
    if (pred_empty(x))
      return false;
    for (const BasicBlock *p : predecessors(x))
      if (p != ab && seen.insert(p).second)
        work.push_back(p);
  }
  return true;
}

// cq-nvfi: a read of rail v at `at` is stale when a non-diagonal gate hit v that does not come
// before the read: what the reader read is no function of v's later basis value or outcome.
bool staleRead(Shared &sh, Value *v, const Instruction *at) {
  auto it = sh.rotations.find(v);
  if (it == sh.rotations.end())
    return false;
  return any_of(it->second, [&](const CallInst *r) { return !outBefore(r, at); });
}

bool availableValue(Shared &sh, Value *v) {
  auto *I = dyn_cast<Instruction>(v);
  return !I || outAvailable(sh, I);
}

// The target argument index of an in-place XOR-type core gate, or -1 when the gate writes no rail's
// basis value.
int xorTarget(const abi::CoreSpec &s, size_t nargs) {
  switch (s.op) {
  case abi::Core::NotI1:
    return s.ctl ? 1 : 0;
  case abi::Core::XorI1:
  case abi::Core::AndI1:
  case abi::Core::OrI1:
  case abi::Core::Copy:
    return int(nargs) - 1;
  case abi::Core::Xorc:
    return s.ctl ? 1 : 0;
  default:
    return -1;
  }
}

// The rail arguments a write reads (every argument but the target and xorc's literal).
SmallVector<Value *, 3> writeReads(const RailHist::Write &w) {
  SmallVector<Value *, 3> r;
  int t = xorTarget(w.spec, w.args.size());
  for (int i = 0; i < int(w.args.size()); ++i) {
    if (i == t)
      continue;
    if (w.spec.op == abi::Core::Xorc && i == int(w.args.size()) - 1)
      continue;
    r.push_back(w.args[i]);
  }
  return r;
}

enum Cls : uint8_t { No = 0, Classical = 1, Measured = 2 };

Cls classify(Shared &sh, Value *h, DenseMap<Value *, Cls> &memo) {
  if (outcomeAt(sh, h))
    return Measured;
  auto mi = memo.find(h);
  if (mi != memo.end())
    return mi->second;
  memo[h] = No;   // SSA order: a rail never reads itself; this only guards malformed records
  auto it = sh.hist.find(h);
  if (it == sh.hist.end())
    return No;
  const RailHist &r = it->second;
  if (r.opaque || !outAvailable(sh, r.def))
    return No;
  Cls c = Classical;
  auto join = [&](Value *v, const Instruction *at) {
    Cls k = staleRead(sh, v, at) ? No : classify(sh, v, memo);
    c = k == No || c == No ? No : std::max(c, k);
  };
  if (r.tmpl) {
    for (const Operand &o : r.ops)
      if (o.handle)
        join(o.v, r.def);
  } else if (!r.seed || !availableValue(sh, r.seed)) {
    return No;
  }
  for (const RailHist::Write &w : r.writes) {
    if (!outAvailable(sh, w.call))
      return memo[h] = No;
    for (Value *a : writeReads(w))
      join(a, w.call);
  }
  return memo[h] = c;
}

Value *xorBits(IRBuilder<> &B, Value *v, Value *x) {
  if (x->getType() != v->getType())
    internalError("spine: classical collapse: a write whose operand type differs from its target's", x);
  if (v->getType()->isIntegerTy())
    return B.CreateXor(v, x);
  Type *it = IntegerType::get(v->getContext(), v->getType()->getPrimitiveSizeInBits());
  return B.CreateBitCast(B.CreateXor(B.CreateBitCast(v, it), B.CreateBitCast(x, it)), v->getType());
}

Value *recompute(LoweringContext &ctx, Value *h);

Value *classicalOf(LoweringContext &ctx, const Operand &o) { return o.handle ? recompute(ctx, o.v) : o.v; }

Value *fromRecord(LoweringContext &ctx, const RailHist &r) {
  IRBuilder<> &B = ctx.B();
  const abi::TemplateSpec &s = r.spec;
  if (s.op == "select" && r.ops.size() == 3)
    return B.CreateSelect(classicalOf(ctx, r.ops[0]), classicalOf(ctx, r.ops[1]), classicalOf(ctx, r.ops[2]));
  if (s.op == "icmp" && r.ops.size() == 2) {
    static const std::pair<const char *, CmpInst::Predicate> preds[] = {
        {"eq", CmpInst::ICMP_EQ},   {"ne", CmpInst::ICMP_NE},   {"ugt", CmpInst::ICMP_UGT},
        {"uge", CmpInst::ICMP_UGE}, {"ult", CmpInst::ICMP_ULT}, {"ule", CmpInst::ICMP_ULE},
        {"sgt", CmpInst::ICMP_SGT}, {"sge", CmpInst::ICMP_SGE}, {"slt", CmpInst::ICMP_SLT},
        {"sle", CmpInst::ICMP_SLE}};
    for (auto &[n, p] : preds)
      if (s.pred == n)
        return B.CreateICmp(p, classicalOf(ctx, r.ops[0]), classicalOf(ctx, r.ops[1]));
  }
  unimplemented("spine: classical collapse (rule 2) of " + abi::name(s, false) +
                    " with no original instruction to recompute it from",
                r.def);
}

Value *recompute(LoweringContext &ctx, Value *h) {
  Shared &sh = shared(ctx);
  if (Value *m = outcomeAt(sh, h))
    return m;
  if (auto c = sh.collapsed.find(h); c != sh.collapsed.end() && availableValue(sh, c->second))
    return c->second;
  auto it = sh.hist.find(h);
  if (it == sh.hist.end())
    internalError("spine: classical collapse of a rail with no history", h);
  RailHist r = it->second;   // a copy: recomputation may grow the maps
  IRBuilder<> &B = ctx.B();
  Value *v;
  if (!r.tmpl) {
    v = r.seed;
  } else {
    const auto *oi = dyn_cast_or_null<Instruction>(r.orig);
    bool viaOrig = false;
    if (oi && !isa<PHINode>(oi) && !oi->isTerminator()) {
      auto b = sh.binds.find(oi);
      viaOrig = b != sh.binds.end() && b->second.size() == 1 && b->second.front().handle &&
                b->second.front().v == h;
      if (auto *cb = dyn_cast<CallBase>(oi))
        viaOrig &= cb->getCalledFunction() && cb->getCalledFunction()->isIntrinsic();
    }
    v = viaOrig ? copyClassical(ctx, *const_cast<Instruction *>(oi)) : fromRecord(ctx, r);
  }
  for (const RailHist::Write &w : r.writes) {
    int t = xorTarget(w.spec, w.args.size());
    Value *ctl = nullptr;
    unsigned first = 0;
    if (w.spec.ctl && w.spec.op != abi::Core::XorI1 && w.spec.op != abi::Core::AndI1 &&
        w.spec.op != abi::Core::OrI1) {
      ctl = recompute(ctx, w.args[0]);
      first = 1;
    }
    Value *x;
    switch (w.spec.op) {
    case abi::Core::NotI1: x = ConstantInt::getTrue(v->getContext()); break;
    case abi::Core::XorI1: x = recompute(ctx, w.args[0]); break;
    case abi::Core::AndI1: x = B.CreateAnd(recompute(ctx, w.args[0]), recompute(ctx, w.args[1])); break;
    case abi::Core::OrI1: x = B.CreateOr(recompute(ctx, w.args[0]), recompute(ctx, w.args[1])); break;
    case abi::Core::Copy: x = recompute(ctx, w.args[first]); break;
    case abi::Core::Xorc: x = w.args[t + 1]; break;
    default: internalError("spine: classical collapse: an unmodelled write", w.call);
    }
    if (ctl)
      x = B.CreateSelect(ctl, x, Constant::getNullValue(x->getType()));
    v = xorBits(B, v, x);
  }
  sh.collapsed[h] = v;
  return v;
}

} // namespace

void noteTemplate(Shared &sh, CallInst *fwd, const abi::TemplateSpec &spec, ArrayRef<Operand> ops,
                  const Value *orig) {
  RailHist &r = sh.hist[fwd];
  r.def = fwd;
  r.tmpl = true;
  r.spec = spec;
  r.ops.assign(ops.begin(), ops.end());
  r.orig = orig;
}

void noteCore(Shared &sh, CallInst *call, const abi::CoreSpec &spec, ArrayRef<Value *> args) {
  if (spec.op == abi::Core::Alloc) {
    if (args.size() != 1)
      internalError("spine: cqrt_alloc with other than one argument", call);
    RailHist &r = sh.hist[call];
    r.def = call;
    r.seed = args[0];
    return;
  }
  if (spec.op == abi::Core::Ry || spec.op == abi::Core::RyQAngle) {
    unsigned t = spec.ctl ? 1 : 0;
    if (t < args.size()) {
      sh.rotations[args[t]].push_back(call);
      if (auto it = sh.hist.find(args[t]); it != sh.hist.end())
        it->second.opaque = true;
    }
    return;
  }
  int t = xorTarget(spec, args.size());
  if (t < 0 || t >= int(args.size()))
    return;
  if (auto it = sh.hist.find(args[t]); it != sh.hist.end())
    it->second.writes.push_back(RailHist::Write{spec, SmallVector<Value *, 3>(args.begin(), args.end()), call});
}

Value *outcomeAt(Shared &sh, Value *h) {
  auto m = sh.measured.find(h);
  if (m == sh.measured.end())
    return nullptr;
  auto *mc = dyn_cast<Instruction>(m->second.second);
  if (sh.dominatesCurrent(m->second.first) || (mc && outAvailable(sh, mc)))
    return m->second.second;
  return nullptr;
}

Value *collapse(LoweringContext &ctx, Value *handle) {
  Shared &sh = shared(ctx);
  if (Value *m = outcomeAt(sh, handle))
    return m;
  DenseMap<Value *, Cls> memo;
  if (classify(sh, handle, memo) != Measured)
    return nullptr;
  return recompute(ctx, handle);
}

} // namespace cq::spine
