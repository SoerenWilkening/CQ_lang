// Module spine (cq-xja3): rule 2's classical collapse.
//
// CONTRACT
//
//  CR rule 2: "a value computed only from measured rails and classical values is classical: its rail
//  (a flag too) is uncomputed while its sources still hold the outcome, and the value is recomputed
//  by ordinary classical instructions from the outcomes; a merge under such a flag is a classical
//  select" (155, 140).
//
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
//    explicit, the fp ones per §2, _rm/_rmq and _exc in a host fenv bracket). A seed is its
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
//  - cq_measure (cq-i962). classicalRead: a cq_measure of a rail classical at its point (seeds alone
//    included: a value computed after a collapse) reads the recomputation and emits no gate (rule 2).
//    A constrained FP op (rule 23) is recomputed in the mode it was lowered with and with the host
//    environment restored after it (fromConstrained).
#include "SpineInternal.h"
#include "cq/Order.h"

#include "llvm/ADT/SetVector.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IntrinsicInst.h"

using namespace llvm;

namespace cq::spine {

namespace {

// The visited set of one backward walk over the output CFG, reused across walks (a fresh set per walk was most of their
// cost): a block is visited in this walk iff its stamp is the walk's generation. Never an answer kept across walks.
struct WalkSet {
  DenseMap<const BasicBlock *, unsigned> stamp;
  unsigned gen = 0;
  void start() {
    if (++gen == 0 || stamp.size() > (1u << 16)) {   // wrapped, or grown over blocks long gone
      stamp.clear();
      gen = 1;
    }
  }
  bool insert(const BasicBlock *b) {
    unsigned &s = stamp[b];
    if (s == gen)
      return false;
    s = gen;
    return true;
  }
};
thread_local WalkSet walkSet;
thread_local SmallVector<const BasicBlock *, 16> walkWork;

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
    return ip == cur->end() || cq::comesBefore(def, &*ip);
  }
  walkSet.start();
  for (BasicBlock *b = cur->getSinglePredecessor(); b && walkSet.insert(b); b = b->getSinglePredecessor())
    if (b == def->getParent())
      return true;
  // cq-8nj3o: past a join (a classical branch's, whose arms both reach it) the predecessors are walked backwards as in
  // outBefore: def's block dominates the insertion block when no walk avoiding it reaches a block with no predecessor.
  const BasicBlock *ab = def->getParent();
  walkSet.start();
  SmallVector<const BasicBlock *, 16> &work = walkWork;
  work.assign(1, cur);
  walkSet.insert(cur);
  while (!work.empty()) {
    const BasicBlock *x = work.pop_back_val();
    if (pred_empty(x))
      return false;
    for (const BasicBlock *p : predecessors(x))
      if (p != ab && walkSet.insert(p))
        work.push_back(p);
  }
  return true;
}

// Does output instruction a come before b on every path to b (a dominates b in the output CFG built
// so far)? cq-drcl: the predecessors of b's block are walked backwards without passing a's block; a
// block with no predecessor reached that way (the entry, or a block not linked yet) is a path that
// avoids a. Conservative: false when unknown. Edges the walk adds later are forward edges into blocks
// not emitted yet or back edges to a loop header, neither of which opens a path into b avoiding a.
bool outBefore(const Instruction *a, const Instruction *b) {
  const BasicBlock *ab = a->getParent(), *bb = b->getParent();
  if (ab == bb)
    return a != b && cq::comesBefore(a, b);
  walkSet.start();
  SmallVector<const BasicBlock *, 16> &work = walkWork;
  work.assign(1, bb);
  walkSet.insert(bb);
  while (!work.empty()) {
    const BasicBlock *x = work.pop_back_val();
    if (pred_empty(x))
      return false;
    for (const BasicBlock *p : predecessors(x))
      if (p != ab && walkSet.insert(p))
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

// Owner 2026-11-15, cq-amtcn (CR rule 14): a loop-carried rail its trip measured denotes the outcome where the instruction
// being lowered is inside that loop (taint's measuredRead reads it so: the trip's own measurement reaches the read); after
// the loop it stays the rail (cq-2z29a). Only a direct read of the measured phi (LoweringContext::operand checks the
// original value): a rail derived from it before the measurement stays a rail (classify's No), as taint keeps it quantum.
bool carriedOutcome(Shared &sh, Value *h) {
  auto m = sh.measured.find(h);
  if (m == sh.measured.end() || !sh.cur)
    return false;
  auto *P = dyn_cast<PHINode>(m->second.v);
  if (!P || sh.cur->getFunction() != P->getFunction())
    return false;
  LoopInfo &LI = sh.li(*P->getFunction());
  const Loop *L = LI.getLoopFor(P->getParent());
  return L && L->getHeader() == P->getParent() && L->contains(sh.cur);
}

// cq-ihlt: `assumed` (when given) collects the rails a clone call measured that the classification
// treats as measured: a rail noted in Shared::calleeMeasured whose clone call is before the builder's
// point.
Cls classify(Shared &sh, Value *h, DenseMap<Value *, Cls> &memo, SetVector<Value *> *assumed = nullptr, bool forRead = false) {
  if (measuredHere(sh, h) || (forRead && measuredEarlier(sh, h)))
    return forRead || !sh.carriedMeasured.count(h) ? Measured : No;
  if (assumed) {
    auto cm = sh.calleeMeasured.find(h);
    if (cm != sh.calleeMeasured.end() && sh.dominatesCurrent(cm->second.call) &&
        (!cm->second.out || outAvailable(sh, cm->second.out))) {
      assumed->insert(h);
      return Measured;
    }
  }
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
  // cq-g3h1i: No is final (nothing below raises it), and without `assumed` the walk has no other effect: it
  // stops at the first No instead of classifying the rest of the rail's history.
  const bool stopAtNo = !assumed;
  auto join = [&](Value *v, const Instruction *at) {
    Cls k = staleRead(sh, v, at) ? No : classify(sh, v, memo, assumed, forRead);
    c = k == No || c == No ? No : std::max(c, k);
  };
  if (r.tmpl) {
    for (const Operand &o : r.ops)
      if (o.handle) {
        join(o.v, r.def);
        if (stopAtNo && c == No)
          return No;
      }
  } else if (!r.seed || !availableValue(sh, r.seed)) {
    return No;
  }
  for (const RailHist::Write &w : r.writes) {
    if (!outAvailable(sh, w.call))
      return memo[h] = No;
    for (Value *a : writeReads(w)) {
      join(a, w.call);
      if (stopAtNo && c == No)
        return No;
    }
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

Value *fromRecordIn(LoweringContext &ctx, const RailHist &r, size_t n);

// The host fenv calls the recomputation of a _rm or _exc record brackets its operation with (fenv_t of
// the pinned triple is 16 bytes; 32 leave room).
Value *fenvSave(LoweringContext &ctx) {
  IRBuilder<> &B = ctx.B();
  Function &F = *B.GetInsertBlock()->getParent();
  IRBuilder<> EB(&F.getEntryBlock(), F.getEntryBlock().getFirstInsertionPt());
  AllocaInst *env = EB.CreateAlloca(ArrayType::get(B.getInt8Ty(), 32), nullptr, "cq.fenv.save");
  env->setAlignment(Align(16));
  Type *i32 = B.getInt32Ty(), *ptr = PointerType::getUnqual(B.getContext());
  B.CreateCall(ctx.M.getOrInsertFunction("fegetenv", FunctionType::get(i32, {ptr}, false)), {env});
  return env;
}
Value *fenvCall(LoweringContext &ctx, StringRef fn, Value *arg) {
  Type *i32 = ctx.B().getInt32Ty();
  return ctx.B().CreateCall(ctx.M.getOrInsertFunction(fn, FunctionType::get(i32, {arg->getType()}, false)), {arg});
}

// A template record recomputed by classical instructions whose value equals the template's total
// function (CR §1.2, §2) on every input. A _rm/_rmq record runs its operation in its mode and an _exc
// record reads the x86 exception bits the operation raises (the §1.2 bits are the host's FE_* values,
// DENORMAL excluded), both between fegetenv and fesetenv of a host fenv_t (the program's environment
// untouched), the operation a constrained intrinsic so that nothing moves it across the calls.
Value *fromRecord(LoweringContext &ctx, const RailHist &r) {
  IRBuilder<> &B = ctx.B();
  const abi::TemplateSpec &s = r.spec;
  if (s.rm == abi::TemplateSpec::NoRm && !s.exc)
    return fromRecordIn(ctx, r, r.ops.size());
  size_t n = r.ops.size() - (s.rm != abi::TemplateSpec::NoRm ? 1 : 0);
  Value *mode = s.rm != abi::TemplateSpec::NoRm ? classicalOf(ctx, r.ops.back()) : nullptr;
  for (size_t k = 0; k < n; ++k)   // operands first, each recomputed in its own bracket
    (void)classicalOf(ctx, r.ops[k]);
  Value *env = fenvSave(ctx);
  if (mode)
    fenvCall(ctx, "fesetround", B.CreateAnd(mode, B.getInt32(0xC00)));
  if (s.exc)
    fenvCall(ctx, "feclearexcept", B.getInt32(0x3F));
  bool wasConstrained = B.getIsFPConstrained();
  B.setIsFPConstrained(true);
  B.setDefaultConstrainedRounding(mode ? RoundingMode::Dynamic : RoundingMode::NearestTiesToEven);
  B.setDefaultConstrainedExcept(fp::ebStrict);
  Value *v = fromRecordIn(ctx, r, n);
  B.setIsFPConstrained(wasConstrained);
  if (s.exc)
    v = B.CreateAnd(fenvCall(ctx, "fetestexcept", B.getInt32(0x3F)), B.getInt32(0x3D));
  Type *ptr = PointerType::getUnqual(B.getContext());
  B.CreateCall(ctx.M.getOrInsertFunction("fesetenv", FunctionType::get(B.getInt32Ty(), {ptr}, false)), {env});
  return v;
}

// fromRecord's operation over the first n operands of the record (the data operands).
Value *fromRecordIn(LoweringContext &ctx, const RailHist &r, size_t n) {
  IRBuilder<> &B = ctx.B();
  const abi::TemplateSpec &s = r.spec;
  // Every template op of CR §1.2 is recomputed below; a record of another op is not a template.
  auto fail = [&]() -> Value * {
    internalError("spine: classical collapse (rule 2) of " + abi::name(s, false) + ": no such template", r.def);
  };
  SmallVector<Value *, 3> a;
  auto args = [&](size_t k) {
    if (n != k)
      return false;
    for (size_t i = 0; i < k; ++i)
      a.push_back(classicalOf(ctx, r.ops[i]));
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
  if (s.w.kind != Kind::Int || (s.to && s.to->kind != Kind::Int)) {
    // Floating point (CR §2): IEEE at the operation's width in the record's mode (the default mode
    // outside a strict region: a non-default mode there has undefined behaviour, C17 §7.6.1); a NaN
    // result of arithmetic is the first NaN operand in IR operand order, quieted, else the default NaN
    // the x86 operation itself produces (the SSE rule); fmax/fmin by §2's formula.
    Type *ft = s.w.kind != Kind::Int ? irTypeOf(B.getContext(), s.w) : nullptr;
    auto quiet = [&](Value *x) {
      Type *t = x->getType();
      unsigned bits = t->getPrimitiveSizeInBits();
      Type *it = IntegerType::get(B.getContext(), bits);
      unsigned qb = t->isX86_FP80Ty() ? 62 : APFloat::semanticsPrecision(t->getFltSemantics()) - 2;
      return B.CreateBitCast(B.CreateOr(B.CreateBitCast(x, it), ConstantInt::get(it, APInt::getOneBitSet(bits, qb))), t);
    };
    // An fp intrinsic at the record's type, its constrained form when the builder is constrained (a _rm
    // or _exc record: the mode it runs in, nothing moved across the fenv calls).
    auto fpCall = [&](Intrinsic::ID id, ArrayRef<Value *> xs) -> Value * {
      if (!B.getIsFPConstrained())
        return B.CreateIntrinsic(id, {ft}, xs);
      Intrinsic::ID cid = Intrinsic::not_intrinsic;
      switch (id) {
      case Intrinsic::sqrt: cid = Intrinsic::experimental_constrained_sqrt; break;
      case Intrinsic::floor: cid = Intrinsic::experimental_constrained_floor; break;
      case Intrinsic::ceil: cid = Intrinsic::experimental_constrained_ceil; break;
      case Intrinsic::trunc: cid = Intrinsic::experimental_constrained_trunc; break;
      case Intrinsic::rint: cid = Intrinsic::experimental_constrained_rint; break;
      case Intrinsic::round: cid = Intrinsic::experimental_constrained_round; break;
      case Intrinsic::fma: cid = Intrinsic::experimental_constrained_fma; break;
      default: internalError("spine: classical collapse: an fp intrinsic with no constrained form", r.def);
      }
      return B.CreateConstrainedFPCall(Intrinsic::getDeclaration(&ctx.M, cid, {ft}), xs);
    };
    auto nanRule = [&](ArrayRef<Value *> xs, Value *res) {
      for (size_t k = xs.size(); k-- > 0;)
        res = B.CreateSelect(B.CreateFCmpUNO(xs[k], xs[k]), quiet(xs[k]), res);
      return res;
    };
    const std::string &op = s.op;
    if (s.to) {
      if (n != 1 || !args(1))
        return fail();
      Type *to = irTypeOf(B.getContext(), *s.to);
      if (op == "fpext") return B.CreateFPExt(a[0], to);
      if (op == "fptrunc") return B.CreateFPTrunc(a[0], to);
      if (op == "fptosi") return B.CreateFPToSI(a[0], to);
      if (op == "fptoui") return B.CreateFPToUI(a[0], to);
      if (op == "sitofp") return B.CreateSIToFP(a[0], to);
      if (op == "uitofp") return B.CreateUIToFP(a[0], to);
      if (op == "bitcast" && s.to->bits == s.w.bits) return B.CreateBitCast(a[0], to);
      return fail();
    }
    if ((op == "fcmp" || op == "fcmps") && args(2)) {
      for (unsigned p = CmpInst::FIRST_FCMP_PREDICATE; p <= CmpInst::LAST_FCMP_PREDICATE; ++p)
        if (s.pred == CmpInst::getPredicateName(CmpInst::Predicate(p)))
          return op == "fcmps" ? B.CreateFCmpS(CmpInst::Predicate(p), a[0], a[1])
                               : B.CreateFCmp(CmpInst::Predicate(p), a[0], a[1]);
      return fail();
    }
    if (op == "is_fpclass" && args(2))
      return B.createIsFPClass(a[0], cast<ConstantInt>(a[1])->getZExtValue());
    if (n == 1 && args(1)) {
      Value *x = a[0];
      if (op == "fneg") return B.CreateFNeg(x);
      if (op == "fabs") return B.CreateUnaryIntrinsic(Intrinsic::fabs, x);
      static const std::pair<const char *, Intrinsic::ID> un[] = {
          {"sqrt", Intrinsic::sqrt},   {"floor", Intrinsic::floor}, {"ceil", Intrinsic::ceil},
          {"trunc", Intrinsic::trunc}, {"rint", Intrinsic::rint},   {"round", Intrinsic::round}};
      for (auto &[un_, id] : un)
        if (op == un_)
          return nanRule({x}, fpCall(id, {x}));
      return fail();
    }
    if (n == 2 && args(2)) {
      Value *x = a[0], *y = a[1];
      if (op == "fadd") return nanRule({x, y}, B.CreateFAdd(x, y));
      if (op == "fsub") return nanRule({x, y}, B.CreateFSub(x, y));
      if (op == "fmul") return nanRule({x, y}, B.CreateFMul(x, y));
      if (op == "fdiv") return nanRule({x, y}, B.CreateFDiv(x, y));
      if (op == "frem") return nanRule({x, y}, B.CreateFRem(x, y));
      if (op == "copysign") return B.CreateBinaryIntrinsic(Intrinsic::copysign, x, y);
      if (op == "fmax" || op == "fmin") {   // §2: isnan(a) ? b : isnan(b) ? a : (b > a ? b : a), min with <
        Value *pick = op == "fmax" ? B.CreateFCmpOGT(y, x) : B.CreateFCmpOLT(y, x);
        return B.CreateSelect(B.CreateFCmpUNO(x, x), y,
                              B.CreateSelect(B.CreateFCmpUNO(y, y), x, B.CreateSelect(pick, y, x)));
      }
      return fail();
    }
    if (n == 3 && op == "fma" && args(3))
      return nanRule({a[0], a[1], a[2]}, fpCall(Intrinsic::fma, {a[0], a[1], a[2]}));
    return fail();
  }
  if (n == 2 && op.size() > 9 && StringRef(op).ends_with("_overflow") && args(2)) {
    static const std::pair<const char *, Intrinsic::ID> ov[] = {
        {"uadd_overflow", Intrinsic::uadd_with_overflow}, {"sadd_overflow", Intrinsic::sadd_with_overflow},
        {"usub_overflow", Intrinsic::usub_with_overflow}, {"ssub_overflow", Intrinsic::ssub_with_overflow},
        {"umul_overflow", Intrinsic::umul_with_overflow}, {"smul_overflow", Intrinsic::smul_with_overflow}};
    for (auto &[on, id] : ov)
      if (op == on)
        return B.CreateExtractValue(B.CreateBinaryIntrinsic(id, a[0], a[1]), {1u});
    return fail();
  }
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
        {"umin", Intrinsic::umin}, {"uadd_sat", Intrinsic::uadd_sat}, {"usub_sat", Intrinsic::usub_sat},
        {"sadd_sat", Intrinsic::sadd_sat}, {"ssub_sat", Intrinsic::ssub_sat}};
    for (auto &[bn, id] : bin)
      if (op == bn)
        return B.CreateBinaryIntrinsic(id, x, y);
    return fail();
  }
  if (n == 1 && args(1)) {
    Value *x = a[0];
    if (op == "ctpop") return B.CreateUnaryIntrinsic(Intrinsic::ctpop, x);
    if (op == "bswap") return B.CreateUnaryIntrinsic(Intrinsic::bswap, x);
    if (op == "bitreverse") return B.CreateUnaryIntrinsic(Intrinsic::bitreverse, x);
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

// cq-i962: a constrained FP op (rule 23) recomputed at the use point must round in the mode it was
// lowered with (the record's last operand: the _rm literal, or the _rmq MODE rail, itself collapsed)
// and must not raise into the host flags (its bits were the quantum FLAGS' at its own point). The
// copy runs between fegetenv and fesetenv of a host fenv_t (both the mode and the flags restored),
// under fesetround(mode). fmuladd is recomputed unfused (CR §2), as it was lowered.
Value *fromConstrained(LoweringContext &ctx, const RailHist &r, ConstrainedFPIntrinsic &ci) {
  IRBuilder<> &B = ctx.B();
  unsigned n = ci.getNonMetadataArgCount();
  bool rm = r.spec.rm != abi::TemplateSpec::NoRm;
  if (r.ops.size() != n + (rm ? 1 : 0))
    internalError("spine: classical collapse: a constrained op's record has an unexpected operand count", &ci);
  Value *mode = nullptr;
  if (rm) {
    mode = classicalOf(ctx, r.ops.back());
  } else if (std::optional<RoundingMode> m = ci.getRoundingMode()) {
    // A static mode: its x86 FE_* value (bits 10-11, CR §1.2).
    switch (*m) {
    case RoundingMode::NearestTiesToEven: mode = B.getInt32(0); break;
    case RoundingMode::TowardNegative: mode = B.getInt32(0x400); break;
    case RoundingMode::TowardPositive: mode = B.getInt32(0x800); break;
    case RoundingMode::TowardZero: mode = B.getInt32(0xC00); break;
    default: internalError("spine: classical collapse: a constrained op with a static mode x86 has no FE_ value for", &ci);
    }
  }
  if (mode && !mode->getType()->isIntegerTy(32))
    internalError("spine: classical collapse: a rounding mode that is not an i32", &ci);
  for (unsigned i = 0; i < n; ++i)   // operands first, each in its own mode
    (void)ctx.operand(ci.getArgOperand(i));
  Function &F = *B.GetInsertBlock()->getParent();
  // fenv_t of the pinned triple (x86_64-apple-macosx) is 16 bytes; 32 leaves room.
  IRBuilder<> EB(&F.getEntryBlock(), F.getEntryBlock().getFirstInsertionPt());
  AllocaInst *env = EB.CreateAlloca(ArrayType::get(B.getInt8Ty(), 32), nullptr, "cq.fenv.save");
  env->setAlignment(Align(16));
  LLVMContext &C = B.getContext();
  Type *i32 = B.getInt32Ty(), *ptr = PointerType::getUnqual(C);
  B.CreateCall(ctx.M.getOrInsertFunction("fegetenv", FunctionType::get(i32, {ptr}, false)), {env});
  if (mode)
    B.CreateCall(ctx.M.getOrInsertFunction("fesetround", FunctionType::get(i32, {i32}, false)), {mode});
  Value *v;
  if (ci.getIntrinsicID() == Intrinsic::experimental_constrained_fmuladd) {
    // CR §2: fmuladd is unfused, fmul then fadd, each rounded in the mode.
    bool was = B.getIsFPConstrained();
    B.setIsFPConstrained(true);
    B.setDefaultConstrainedRounding(RoundingMode::Dynamic);
    B.setDefaultConstrainedExcept(fp::ebStrict);
    Value *x = ctx.operand(ci.getArgOperand(0)).v, *y = ctx.operand(ci.getArgOperand(1)).v,
          *z = ctx.operand(ci.getArgOperand(2)).v;
    v = B.CreateFAdd(B.CreateFMul(x, y), z);
    B.setIsFPConstrained(was);
  } else {
    v = copyClassical(ctx, ci);
  }
  B.CreateCall(ctx.M.getOrInsertFunction("fesetenv", FunctionType::get(i32, {ptr}, false)), {env});
  return v;
}

Value *recompute(LoweringContext &ctx, Value *h) {
  Shared &sh = shared(ctx);
  // classify said the rail is classical here: measured here (static), or, for a cq_measure's read, measured earlier.
  if (Value *m = outcomeAt(ctx, h, /*reread=*/true))
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
      // An operand still a rail where it is read (a loop-carried measured value's, ctx.operand gives the rail): the record reads it
      // through recompute instead.
      if (viaOrig)
        for (const Use &u : oi->operands())
          if (!isa<BasicBlock, MetadataAsValue>(u.get()) && ctx.operand(u.get()).handle)
            viaOrig = false;
    }
    if (viaOrig && isa<ConstrainedFPIntrinsic>(oi))
      v = fromConstrained(ctx, r, *cast<ConstrainedFPIntrinsic>(const_cast<Instruction *>(oi)));
    else
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

static void noteGateAt(Shared &sh, CallInst *call) {
  SmallVector<const Instruction *, 2> &at = sh.gateAt[call];
  if (sh.cur)
    at.push_back(sh.cur);
}

// A gate on a rail through a phi of the output (a loop-carried or merged handle, the same rail as its incoming values): the
// incoming rails' records no longer give its basis value (invert_seed p_seedin: rotated through the loop header's phi), so
// they are opaque.
static void opaqueThroughPhi(Shared &sh, Value *t) {
  SmallVector<Value *, 4> work{t};
  SmallPtrSet<Value *, 8> seen{t};
  while (!work.empty()) {
    auto *phi = dyn_cast<PHINode>(work.pop_back_val());
    if (!phi)
      continue;
    for (Value *in : phi->incoming_values()) {
      if (!seen.insert(in).second)
        continue;
      if (auto it = sh.hist.find(in); it != sh.hist.end())
        it->second.opaque = true;
      work.push_back(in);
    }
  }
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
      noteGateAt(sh, call);
      if (auto it = sh.hist.find(args[t]); it != sh.hist.end())
        it->second.opaque = true;
      opaqueThroughPhi(sh, args[t]);
    }
    return;
  }
  if (spec.op == abi::Core::Add || spec.op == abi::Core::Sub || spec.op == abi::Core::Addc) {
    // Rule 6's in-place update (cq-2h7xa): no XOR, so the rail's records no longer give its basis value.
    Value *d = args[spec.op == abi::Core::Addc ? 0 : 1];
    if (auto it = sh.hist.find(d); it != sh.hist.end())
      it->second.opaque = true;
    opaqueThroughPhi(sh, d);
    return;
  }
  int t = xorTarget(spec, args.size());
  if (t < 0 || t >= int(args.size()))
    return;
  if (auto it = sh.hist.find(args[t]); it != sh.hist.end()) {
    it->second.writes.push_back(RailHist::Write{spec, SmallVector<Value *, 3>(args.begin(), args.end()), call});
    noteGateAt(sh, call);
  } else {
    opaqueThroughPhi(sh, args[t]);
  }
}

// CR rule 2, "a re-measurement of the same rail is a classical re-read": a measurement of the rail already emitted before the
// builder's point (a K-loop's earlier trip included). It decides only what a cq_measure reads (classicalRead), never whether a
// value is classical: that is static (measuredHere).
bool measuredEarlier(Shared &sh, Value *h) {
  auto m = sh.measured.find(h);
  if (m == sh.measured.end())
    return false;
  auto *mc = dyn_cast<Instruction>(m->second.outcome);
  return sh.dominatesCurrent(m->second.at) || (mc && outAvailable(sh, mc));
}

bool measuredHere(Shared &sh, Value *h) {
  auto m = sh.measured.find(h);
  if (m == sh.measured.end() || !sh.cur || !sh.isQ)
    return false;
  // The outcome must reach the builder's point too: a value measured on every path by several measurements, none of
  // which reaches here alone (one in each classical arm), stays a rail here (no re-read is made up).
  if (!measuredEarlier(sh, h))
    return false;
  // The instruction being lowered is the measurement itself, its outcome reaching here: the builder is past it (the
  // write-backs and settles that run after a measurement, rule 2's "right after the measurement", 65), not the same
  // site's measurement of an earlier K-loop trip (me_cbr: behind a classical branch, its outcome does not reach).
  if (m->second.at == sh.cur)
    return true;
  return cq::measuredBefore(sh.isQ, m->second.v, sh.cur->getParent(), sh.cur, m->second.at);
}

Value *outcomeAt(LoweringContext &ctx, Value *h, bool reread) {
  Shared &sh = shared(ctx);
  if (!measuredHere(sh, h) && !(reread && measuredEarlier(sh, h)))
    return nullptr;
  return sh.measured.find(h)->second.outcome;
}

Value *classicalRead(LoweringContext &ctx, Value *handle) {
  Shared &sh = shared(ctx);
  if (Value *m = outcomeAt(ctx, handle, /*reread=*/true))
    return m;
  DenseMap<Value *, Cls> memo;
  if (classify(sh, handle, memo, nullptr, /*forRead=*/true) == No)
    return nullptr;
  return recompute(ctx, handle);
}

Value *collapse(LoweringContext &ctx, Value *handle) {
  Shared &sh = shared(ctx);
  if (sh.carriedMeasured.count(handle) && !(measuredHere(sh, handle) && carriedOutcome(sh, handle)))
    return nullptr;
  if (Value *m = outcomeAt(ctx, handle, /*reread=*/false))
    return m;
  DenseMap<Value *, Cls> memo;
  if (classify(sh, handle, memo) != Measured)
    return nullptr;
  return recompute(ctx, handle);
}

namespace {

// Does F (an original function with a body) measure its formal `idx` (a cq_measure_* of the formal,
// or a call passing it to an in-module function that does)? Always: on every path to a return (the
// measuring call dominates every return). Some: on some path only.
enum class Meas : uint8_t { None, Some, Always };

Meas formalMeasured(const TaintInfo &T, Shared &sh, const Function &F, unsigned idx,
                    SmallPtrSet<const Function *, 8> &onStack) {
  if (hostCallee(F) || idx >= F.arg_size() || !T.formalMayReachMeasure(F, idx) || !onStack.insert(&F).second)
    return Meas::None;
  const Argument *A = F.getArg(idx);
  SmallVector<const ReturnInst *, 4> rets;
  for (const BasicBlock &BB : F)
    if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
      rets.push_back(R);
  Meas r = Meas::None;
  for (const Use &U : A->uses()) {
    auto *CB = dyn_cast<CallBase>(U.getUser());
    if (!CB || !CB->isArgOperand(&U))
      continue;
    const Function *G = CB->getCalledFunction();
    if (!G)
      continue;
    Meas m = Meas::None;
    if (G->isDeclaration()) {
      if (G->getName().starts_with("cq_measure_"))
        m = Meas::Always;
    } else {
      m = formalMeasured(T, sh, *G, CB->getArgOperandNo(&U), onStack);
    }
    if (m == Meas::None)
      continue;
    if (m == Meas::Always)
      for (const ReturnInst *R : rets)
        if (!sh.dt(F).dominates(CB, R))
          m = Meas::Some;
    r = std::max(r, m);
  }
  onStack.erase(&F);
  return r;
}

} // namespace

void noteCalleeMeasures(LoweringContext &ctx, const CallBase &orig, BasicBlock *, Instruction *) {
  Shared &sh = shared(ctx);
  const Function *F = orig.getCalledFunction();
  if (!F || hostCallee(*F))
    return;
  // Rule 19: a _ctl clone measures a controlled copy: the actual is not collapsed. A table clone hands its callee a copy
  // (cq-t2jj2, calls::measuredActual): neither is its actual.
  if (ctx.S.table)
    return;
  if (const Specialization *cs = ctx.T.calleeSpecialization(orig, ctx.S); cs && cs->ctl)
    return;
  for (unsigned i = 0; i < orig.arg_size(); ++i) {
    const Value *a = orig.getArgOperand(i);
    auto b = sh.binds.find(a);
    if (b == sh.binds.end() || b->second.size() != 1 || !b->second.front().handle)
      continue;
    Value *h = b->second.front().v;
    if (measuredHere(sh, h) || measuredEarlier(sh, h))
      continue;
    SmallPtrSet<const Function *, 8> onStack;
    Meas m = formalMeasured(ctx.T, sh, *F, i, onStack);
    // CR rule 2, collapse is static (f684858): a rail the callee measures on some of its classical
    // paths only is lowered as unmeasured after the call. Templates, twins and gates act on the basis
    // state it then holds, and a later cq_measure of it (or of a value read from it) is an ordinary
    // measurement: nothing is re-read.
    if (m != Meas::Always)
      continue;
    // Rule 2: measured on some classical paths of this function only, the rail is lowered as unmeasured: the clone measured
    // a kept basis copy of it (calls::emitCloneCall), so there is nothing to re-read.
    if (!measuredOnEveryPath(ctx, a, &orig))
      continue;
    Shared::CalleeMeasure cm;
    cm.call = &orig;
    cm.arg = a;
    cm.always = m == Meas::Always;
    // The end of the call's lowering (the builder's point now): after the clone call (or calls, a
    // dispatch over callees) wherever its lowering left the walk, so a re-read placed there follows the
    // callee's measurement and dominates every later reader (a _ctl clone measures unconditionally too,
    // rule 2).
    IRBuilder<> &B = ctx.B();
    cm.endBlock = B.GetInsertBlock();
    cm.out = B.GetInsertPoint() == cm.endBlock->begin() ? nullptr : &*std::prev(B.GetInsertPoint());
    sh.calleeMeasured[h] = cm;
  }
}

Value *calleeCollapse(LoweringContext &ctx, Value *handle, const Instruction &at) {
  Shared &sh = shared(ctx);
  if (sh.calleeMeasured.empty())
    return nullptr;
  DenseMap<Value *, Cls> memo;
  SetVector<Value *> assumed;
  if (classify(sh, handle, memo, &assumed) != Measured || assumed.empty())
    return nullptr;
  for (Value *src : assumed) {
    Shared::CalleeMeasure cm = sh.calleeMeasured.lookup(src);
    if (!cm.always)
      internalError("spine: a callee-measured record of a rail the callee measures on some paths only (rule 2: "
                    "collapse is static, noteCalleeMeasures records none)",
                    &at);
    IRBuilder<> &B = ctx.B();
    IRBuilderBase::InsertPointGuard guard(B);
    if (cm.out)
      B.SetInsertPoint(cm.out->getParent(), std::next(cm.out->getIterator()));
    else
      B.SetInsertPoint(cm.endBlock, cm.endBlock->getFirstInsertionPt());
    Type *t = cm.arg->getType();
    if (!t->isIntegerTy() && !t->isFloatingPointTy())   // one handle: a scalar actual (rule 1)
      internalError("spine: a callee-measured actual bound to one handle that is no scalar", &at);
    // A classical re-read (CR §1.3, rule 2): no gate, so no open cq_invert gate log records it.
    std::vector<bool> logs = sh.gateLogOpen;
    sh.gateLogOpen.assign(logs.size(), false);
    CallInst *m = ctx.emitCore(abi::CoreSpec{abi::Core::Measure, railTypeOf(t)}, {src});
    sh.gateLogOpen = logs;
    // The lowering of the user's cq_measure: it carries the V1 provenance marker.
    m->setMetadata("cq.measure", MDNode::get(ctx.M.getContext(), {}));
    if (m->getType() != t)
      internalError("spine: re-read cqrt_measure result type differs from the actual's", &at);
    // CR rule 2 (cq-29ej): a source the call measures on some classical paths only is lowered as unmeasured.
    if (measuredOnEveryPath(ctx, cm.arg, cm.call))
      ctx.unc().setRole(ctx.unc().idOf(src), Role::Measured);
    sh.measured[src] = {cm.call, m, cm.arg};
    sh.calleeMeasured.erase(src);
  }
  Value *v = collapse(ctx, handle);
  if (!v)
    internalError("spine: a callee-measured source did not collapse its reader (cq-ihlt)", &at);
  return v;
}

} // namespace cq::spine
