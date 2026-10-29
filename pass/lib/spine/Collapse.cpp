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
//    is recomputed from its record (fromRecord: select, icmp and the integer templates, §2's totalization
//    explicit); an fp, _rm/_rmq, _exc, qrom or overflow record is cq::unimplemented. A seed is its
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

// A template record recomputed by classical instructions whose value equals the template's total
// function (CR §1.2, §2) on every input. Integer arithmetic, bitwise ops, compares, integer casts,
// bitcasts and the integer intrinsics are recomputed, with §2's totalization made explicit where
// LLVM's own result is poison or UB (division by 0, INT_MIN / -1, a shift amount at or above W). A
// record whose value depends on the floating-point environment or on vendor semantics (fp
// arithmetic, fp conversions, fp compares, _rm/_rmq, _exc), or that reads memory or returns a pair
// (qrom_load, *_overflow), is cq::unimplemented, named by its template.
Value *fromRecord(LoweringContext &ctx, const RailHist &r) {
  IRBuilder<> &B = ctx.B();
  const abi::TemplateSpec &s = r.spec;
  auto fail = [&]() -> Value * {
    unimplemented("spine: classical collapse (rule 2) of " + abi::name(s, false) +
                      " with no original instruction to recompute it from",
                  r.def);
  };
  if (s.rm != abi::TemplateSpec::NoRm || s.exc || s.strided)
    return fail();
  size_t n = r.ops.size();
  SmallVector<Value *, 3> a;
  auto args = [&](size_t k) {
    if (n != k)
      return false;
    for (const Operand &o : r.ops)
      a.push_back(classicalOf(ctx, o));
    return true;
  };
  const std::string &op = s.op;
  if (op == "select" && args(3))
    return B.CreateSelect(a[0], a[1], a[2]);
  if (op == "icmp" && args(2)) {
    static const std::pair<const char *, CmpInst::Predicate> preds[] = {
        {"eq", CmpInst::ICMP_EQ},   {"ne", CmpInst::ICMP_NE},   {"ugt", CmpInst::ICMP_UGT},
        {"uge", CmpInst::ICMP_UGE}, {"ult", CmpInst::ICMP_ULT}, {"ule", CmpInst::ICMP_ULE},
        {"sgt", CmpInst::ICMP_SGT}, {"sge", CmpInst::ICMP_SGE}, {"slt", CmpInst::ICMP_SLT},
        {"sle", CmpInst::ICMP_SLE}};
    for (auto &[pn, p] : preds)
      if (s.pred == pn)
        return B.CreateICmp(p, a[0], a[1]);
    return fail();
  }
  if (s.w.kind != Kind::Int)
    return fail();   // fp templates: the value depends on the fp environment or §2's NaN rows
  if (s.to) {
    if (n != 1 || !args(1))
      return fail();
    Type *to = irTypeOf(B.getContext(), *s.to);
    if (op == "zext" && s.to->kind == Kind::Int)
      return B.CreateZExt(a[0], to);
    if (op == "sext" && s.to->kind == Kind::Int)
      return B.CreateSExt(a[0], to);
    if (op == "trunc" && s.to->kind == Kind::Int)
      return B.CreateTrunc(a[0], to);
    if (op == "bitcast" && s.to->bits == s.w.bits)
      return B.CreateBitCast(a[0], to);
    return fail();
  }
  if (n == 2 && args(2)) {
    Value *x = a[0], *y = a[1];
    Type *T = x->getType();
    unsigned W = s.w.bits;
    if (op == "add") return B.CreateAdd(x, y);
    if (op == "sub") return B.CreateSub(x, y);
    if (op == "mul") return B.CreateMul(x, y);
    if (op == "and") return B.CreateAnd(x, y);
    if (op == "or") return B.CreateOr(x, y);
    if (op == "xor") return B.CreateXor(x, y);
    if (op == "shl" || op == "lshr" || op == "ashr") {
      Value *k = B.CreateURem(y, ConstantInt::get(T, W));   // §2: the amount mod W
      return op == "shl" ? B.CreateShl(x, k) : op == "lshr" ? B.CreateLShr(x, k) : B.CreateAShr(x, k);
    }
    if (op == "udiv" || op == "urem" || op == "sdiv" || op == "srem") {
      Value *one = ConstantInt::get(T, 1), *z = B.CreateICmpEQ(y, Constant::getNullValue(T));
      Value *bad = z;
      bool sgn = op == "sdiv" || op == "srem";
      if (sgn)   // INT_MIN / -1: §2 gives INT_MIN and 0, which dividing by 1 yields
        bad = B.CreateOr(z, B.CreateAnd(B.CreateICmpEQ(x, ConstantInt::get(T, APInt::getSignedMinValue(W))),
                                        B.CreateICmpEQ(y, Constant::getAllOnesValue(T))));
      Value *d = B.CreateSelect(bad, one, y);
      if (op == "udiv")   // udiv(a, 0) = 2^W - 1
        return B.CreateSelect(z, Constant::getAllOnesValue(T), B.CreateUDiv(x, d));
      if (op == "urem")   // urem(a, 0) = a
        return B.CreateSelect(z, x, B.CreateURem(x, d));
      if (op == "sdiv")   // sdiv(a, 0) = -1 if a >= 0, else +1
        return B.CreateSelect(z,
                              B.CreateSelect(B.CreateICmpSGE(x, Constant::getNullValue(T)),
                                             Constant::getAllOnesValue(T), one),
                              B.CreateSDiv(x, d));
      return B.CreateSelect(z, x, B.CreateSRem(x, d));   // srem(a, 0) = a
    }
    static const std::pair<const char *, Intrinsic::ID> bin[] = {
        {"smax", Intrinsic::smax}, {"smin", Intrinsic::smin}, {"umax", Intrinsic::umax},
        {"umin", Intrinsic::umin}, {"uadd_sat", Intrinsic::uadd_sat}, {"usub_sat", Intrinsic::usub_sat}};
    for (auto &[bn, id] : bin)
      if (op == bn)
        return B.CreateBinaryIntrinsic(id, x, y);
    return fail();
  }
  if (n == 1 && args(1)) {
    Value *x = a[0];
    if (op == "ctpop") return B.CreateUnaryIntrinsic(Intrinsic::ctpop, x);
    if (op == "bswap") return B.CreateUnaryIntrinsic(Intrinsic::bswap, x);
    if (op == "ctlz" || op == "cttz")   // §2: ctlz(0) = cttz(0) = W, LLVM's value without the poison flag
      return B.CreateBinaryIntrinsic(op == "ctlz" ? Intrinsic::ctlz : Intrinsic::cttz, x, B.getFalse());
    if (op == "abs")   // §2: abs(INT_MIN) = INT_MIN, LLVM's value without the poison flag
      return B.CreateBinaryIntrinsic(Intrinsic::abs, x, B.getFalse());
    return fail();
  }
  if (n == 3 && (op == "fshl" || op == "fshr") && args(3))   // the amount is taken mod W by LLVM too
    return B.CreateIntrinsic(op == "fshl" ? Intrinsic::fshl : Intrinsic::fshr, {a[0]->getType()},
                             {a[0], a[1], a[2]});
  return fail();
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
