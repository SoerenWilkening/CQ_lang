// Module spine (cq-w0-construct): rule 4 opcode lowering, rule 2 source and sink.
//
//  lowerOpcode   a tainted opcode -> cq_template_<op>[_<pred>]_<W>[_to_<W2>][_<shape>] into a fresh
//                rail (CR §1.2, rule 4). A classical operand is a literal; a commutative op puts the
//                handle first, an fp one unless the literal is a NaN constant (cq-5iy), a compare
//                flips its predicate instead. llvm.fmuladd is unfused (§2): fmul then fadd.
//                An opcode whose operands all map to classical values (rule 2's classical collapse:
//                every quantum source was measured at a dominating point) is the classical opcode.
//  lowerTheta    cq_theta on a classical value mints alloc_<W>(v) and Ry; on a rail, Ry in place.
//  lowerMeasure  measure_<W>(h); the rail stays allocated (Role::Measured); dominated uses of the
//                measured value read the outcome (LoweringContext::operand).
#include "SpineInternal.h"

#include <functional>
#include <optional>

#include "cq/Abi.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"

using namespace llvm;

namespace cq {

namespace {

RailType rt(Type *t, const Value *at) {
  if (!t->isIntegerTy() && !t->isHalfTy() && !t->isBFloatTy() && !t->isFloatTy() && !t->isDoubleTy() && !t->isX86_FP80Ty())
    unimplemented("spine: a rail of IR type that is not iN/half/bfloat/float/double/x86_fp80", at);
  return railTypeOf(t);
}

// CR §1.2 (8b52487, ruling cq-5iy): a commutative fp op puts the handle first unless the literal is
// a compile-time NaN constant, which keeps its position. A run-time classical operand always commutes.
bool provablyNotNaN(const Value *v) {
  if (auto *c = dyn_cast<ConstantFP>(v))
    return !c->isNaN();
  return true;
}

enum class Comm { No, Int, Fp };

Comm commutativity(StringRef op) {
  static const char *ints[] = {"add", "mul", "and", "or", "xor", "smax", "smin", "umax", "umin", "uadd_sat",
                               "uadd_overflow", "sadd_overflow", "umul_overflow", "smul_overflow"};
  for (const char *o : ints)
    if (op == o)
      return Comm::Int;
  if (op == "fadd" || op == "fmul")
    return Comm::Fp;
  return Comm::No;
}

// One binary template over two original operands. Returns the fresh rail, or nullptr after emitting
// the classical form (both operands classical).
Value *binary(LoweringContext &ctx, abi::TemplateSpec spec, const Value *a, const Value *b, const Value *orig) {
  Operand x = ctx.operand(a), y = ctx.operand(b);
  if (!x.handle && !y.handle)
    return nullptr;
  if (x.handle && y.handle) {
    spec.shape = "";
  } else if (x.handle) {
    spec.shape = "hl";
  } else {
    Comm c = commutativity(spec.op);
    if (c == Comm::Int || (c == Comm::Fp && provablyNotNaN(x.v))) {
      std::swap(x, y);
      spec.shape = "hl";
    } else {
      spec.shape = "lh";
    }
  }
  return ctx.emitTemplate(spec, {x, y}, orig);
}

const char *binName(Instruction::BinaryOps op) {
  switch (op) {
  case Instruction::Add: return "add";
  case Instruction::Sub: return "sub";
  case Instruction::Mul: return "mul";
  case Instruction::UDiv: return "udiv";
  case Instruction::SDiv: return "sdiv";
  case Instruction::URem: return "urem";
  case Instruction::SRem: return "srem";
  case Instruction::And: return "and";
  case Instruction::Or: return "or";
  case Instruction::Xor: return "xor";
  case Instruction::Shl: return "shl";
  case Instruction::LShr: return "lshr";
  case Instruction::AShr: return "ashr";
  case Instruction::FAdd: return "fadd";
  case Instruction::FSub: return "fsub";
  case Instruction::FMul: return "fmul";
  case Instruction::FDiv: return "fdiv";
  case Instruction::FRem: return "frem";
  default: return nullptr;
  }
}

const char *castName(Instruction::CastOps op) {
  switch (op) {
  case Instruction::ZExt: return "zext";
  case Instruction::SExt: return "sext";
  case Instruction::Trunc: return "trunc";
  case Instruction::FPExt: return "fpext";
  case Instruction::FPTrunc: return "fptrunc";
  case Instruction::SIToFP: return "sitofp";
  case Instruction::UIToFP: return "uitofp";
  case Instruction::FPToSI: return "fptosi";
  case Instruction::FPToUI: return "fptoui";
  case Instruction::BitCast: return "bitcast";
  default: return nullptr;
  }
}

// Template op of a unary/binary/ternary intrinsic (CR §1.2 names), "" if it has none.
std::string intrinsicOp(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::fabs: return "fabs";
  case Intrinsic::copysign: return "copysign";
  case Intrinsic::sqrt: return "sqrt";
  case Intrinsic::floor: return "floor";
  case Intrinsic::ceil: return "ceil";
  case Intrinsic::trunc: return "trunc";
  case Intrinsic::rint: return "rint";
  case Intrinsic::round: return "round";
  case Intrinsic::maxnum: return "fmax";
  case Intrinsic::minnum: return "fmin";
  case Intrinsic::fma: return "fma";
  case Intrinsic::fshl: return "fshl";
  case Intrinsic::fshr: return "fshr";
  case Intrinsic::abs: return "abs";
  case Intrinsic::ctlz: return "ctlz";
  case Intrinsic::cttz: return "cttz";
  case Intrinsic::ctpop: return "ctpop";
  case Intrinsic::bswap: return "bswap";
  case Intrinsic::smax: return "smax";
  case Intrinsic::smin: return "smin";
  case Intrinsic::umax: return "umax";
  case Intrinsic::umin: return "umin";
  case Intrinsic::uadd_sat: return "uadd_sat";
  case Intrinsic::usub_sat: return "usub_sat";
  case Intrinsic::sadd_sat: return "sadd_sat";
  case Intrinsic::ssub_sat: return "ssub_sat";
  case Intrinsic::uadd_with_overflow: return "uadd_overflow";
  case Intrinsic::sadd_with_overflow: return "sadd_overflow";
  case Intrinsic::umul_with_overflow: return "umul_overflow";
  case Intrinsic::smul_with_overflow: return "smul_overflow";
  case Intrinsic::usub_with_overflow: return "usub_overflow";
  case Intrinsic::ssub_with_overflow: return "ssub_overflow";
  case Intrinsic::is_fpclass: return "is_fpclass";
  case Intrinsic::fmuladd: return "fmuladd";
  default: return "";
  }
}

// The value op of an *.with.overflow intrinsic (rule 4: two templates over the same operands).
const char *overflowValueOp(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::uadd_with_overflow:
  case Intrinsic::sadd_with_overflow: return "add";
  case Intrinsic::usub_with_overflow:
  case Intrinsic::ssub_with_overflow: return "sub";
  case Intrinsic::umul_with_overflow:
  case Intrinsic::smul_with_overflow: return "mul";
  default: return nullptr;
  }
}

void lowerIntrinsic(LoweringContext &ctx, IntrinsicInst &II) {
  Intrinsic::ID id = II.getIntrinsicID();
  std::string op = intrinsicOp(id);
  if (op.empty())
    internalError("spine: lowerOpcode on an intrinsic with no template", &II);

  if (op == "fmuladd") {
    // §2: unfused. fmul(a, b) then fadd(product, c), each its own template or classical opcode.
    RailType w = rt(II.getType(), &II);
    abi::TemplateSpec mul;
    mul.op = "fmul";
    mul.w = w;
    Value *prod = binary(ctx, mul, II.getArgOperand(0), II.getArgOperand(1), nullptr);
    Operand p;
    if (prod) {
      p = Operand{prod, true};
    } else {
      Operand a = ctx.operand(II.getArgOperand(0)), b = ctx.operand(II.getArgOperand(1));
      auto *fm = cast<Instruction>(ctx.B().CreateFMul(a.v, b.v));
      fm->copyFastMathFlags(&II);
      p = Operand{fm, false};
    }
    Operand c = ctx.operand(II.getArgOperand(2));
    abi::TemplateSpec add;
    add.op = "fadd";
    add.w = w;
    if (!p.handle && !c.handle) {
      spine::bindOperand(ctx, &II, Operand{ctx.B().CreateFAdd(p.v, c.v), false});
      return;
    }
    Operand x = p, y = c;
    if (x.handle && y.handle)
      add.shape = "";
    else if (x.handle)
      add.shape = "hl";
    else if (provablyNotNaN(x.v)) {
      std::swap(x, y);
      add.shape = "hl";
    } else
      add.shape = "lh";
    ctx.emitTemplate(add, {x, y}, &II);
    return;
  }

  if (const char *vop = overflowValueOp(id)) {
    // {iN, i1}: the value template and the overflow template over the same operands.
    auto *st = cast<StructType>(II.getType());
    RailType w = rt(st->getElementType(0), &II);
    abi::TemplateSpec val, ovf;
    val.op = vop;
    val.w = w;
    ovf.op = op;
    ovf.w = w;
    Value *v = binary(ctx, val, II.getArgOperand(0), II.getArgOperand(1), nullptr);
    Value *o = binary(ctx, ovf, II.getArgOperand(0), II.getArgOperand(1), nullptr);
    if (!v != !o)
      internalError("spine: overflow intrinsic operands mapped inconsistently", &II);
    if (!v) {   // rule 2 collapse
      spine::bindOperand(ctx, &II, Operand{spine::copyClassical(ctx, II), false});
      return;
    }
    ctx.bindFields(&II, {Operand{v, true}, Operand{o, true}});
    return;
  }

  RailType w = rt(II.getArgOperand(0)->getType(), &II);
  abi::TemplateSpec spec;
  spec.op = op;
  spec.w = w;

  if (op == "is_fpclass") {
    Operand x = ctx.operand(II.getArgOperand(0));
    Operand m = ctx.operand(II.getArgOperand(1));
    if (m.handle)
      internalError("spine: is_fpclass with a quantum class mask", &II);
    if (!x.handle) {
      spine::bindOperand(ctx, &II, Operand{spine::copyClassical(ctx, II), false});   // rule 2 collapse
      return;
    }
    spec.shape = "hl";
    ctx.emitTemplate(spec, {x, m}, &II);
    return;
  }

  unsigned data = 1;
  switch (id) {
  case Intrinsic::copysign:
  case Intrinsic::maxnum:
  case Intrinsic::minnum:
  case Intrinsic::smax:
  case Intrinsic::smin:
  case Intrinsic::umax:
  case Intrinsic::umin:
  case Intrinsic::uadd_sat:
  case Intrinsic::usub_sat:
  case Intrinsic::sadd_sat:
  case Intrinsic::ssub_sat: data = 2; break;
  case Intrinsic::fma:
  case Intrinsic::fshl:
  case Intrinsic::fshr: data = 3; break;
  default: data = 1; break; // abs/ctlz/cttz carry an i1 immarg that totalization (§2) makes moot
  }

  if (data == 2) {
    if (!binary(ctx, spec, II.getArgOperand(0), II.getArgOperand(1), &II))
      spine::bindOperand(ctx, &II, Operand{spine::copyClassical(ctx, II), false});   // rule 2 collapse
    return;
  }
  if (data == 1) {
    Operand x = ctx.operand(II.getArgOperand(0));
    if (!x.handle) {
      spine::bindOperand(ctx, &II, Operand{spine::copyClassical(ctx, II), false});   // rule 2 collapse
      return;
    }
    ctx.emitTemplate(spec, {x}, &II);
    return;
  }
  // Ternary: one letter per operand, q or l; bare for qqq. fma's product operands commute unless
  // the literal is a NaN (CR §1.2 at a46894a): lqq -> qlq, lql -> qll.
  SmallVector<Operand, 3> ops = {ctx.operand(II.getArgOperand(0)), ctx.operand(II.getArgOperand(1)),
                                 ctx.operand(II.getArgOperand(2))};
  if (id == Intrinsic::fma && !ops[0].handle && ops[1].handle && provablyNotNaN(ops[0].v))
    std::swap(ops[0], ops[1]);
  std::string sh;
  bool any = false;
  for (const Operand &o : ops) {
    sh += o.handle ? 'q' : 'l';
    any |= o.handle;
  }
  if (!any) {
    spine::bindOperand(ctx, &II, Operand{spine::copyClassical(ctx, II), false});   // rule 2 collapse
    return;
  }
  spec.shape = sh == "qqq" ? "" : sh;
  ctx.emitTemplate(spec, ops, &II);
}

// Rule 20 with rule 3 (cq-sj2j; 58, 60: "the i8<->i1 zext/trunc are representation changes, no
// gate"): a _Bool slot cell holds an i1 rail behind i8 memory, so the trunc i8 -> i1 of its load
// and the zext i1 -> i8 of a value stored only into such cells name the same rail.
bool boolCellRepresentation(LoweringContext &ctx, const CastInst &ci) {
  LLVMContext &C = ctx.M.getContext();
  if (isa<TruncInst>(ci) && ci.getSrcTy() == Type::getInt8Ty(C) && ci.getDestTy() == Type::getInt1Ty(C)) {
    auto *ld = dyn_cast<LoadInst>(ci.getOperand(0));
    return ld && spine::boolCellAccess(ctx, *ld);
  }
  if (isa<ZExtInst>(ci) && ci.getSrcTy() == Type::getInt1Ty(C) && ci.getDestTy() == Type::getInt8Ty(C)) {
    if (ci.use_empty())
      return false;
    for (const Use &u : ci.uses()) {
      auto *st = dyn_cast<StoreInst>(u.getUser());
      if (!st || u.getOperandNo() != 0 || !spine::boolCellAccess(ctx, *st))
        return false;
    }
    return true;
  }
  return false;
}

} // namespace

void lowerOpcode(LoweringContext &ctx, Instruction &I) {
  if (I.getType()->isVectorTy())
    internalError("spine: lowerOpcode on a vector (aggr::lowerVectorOp)", &I);

  if (auto *bo = dyn_cast<BinaryOperator>(&I)) {
    const char *op = binName(bo->getOpcode());
    if (!op)
      unimplemented("spine: binary opcode with no template", &I);
    abi::TemplateSpec spec;
    spec.op = op;
    spec.w = rt(I.getType(), &I);
    if (!binary(ctx, spec, bo->getOperand(0), bo->getOperand(1), &I))
      spine::bindOperand(ctx, &I, Operand{spine::copyClassical(ctx, I), false}); // rule 2 collapse
    return;
  }

  if (auto *un = dyn_cast<UnaryOperator>(&I)) {
    if (un->getOpcode() != Instruction::FNeg)
      unimplemented("spine: unary opcode with no template", &I);
    Operand x = ctx.operand(un->getOperand(0));
    if (!x.handle) {
      spine::bindOperand(ctx, &I, Operand{spine::copyClassical(ctx, I), false});
      return;
    }
    abi::TemplateSpec spec;
    spec.op = "fneg";
    spec.w = rt(I.getType(), &I);
    ctx.emitTemplate(spec, {x}, &I);
    return;
  }

  if (auto *cmp = dyn_cast<CmpInst>(&I)) {
    if (!cmp->getOperand(0)->getType()->isIntegerTy() && !cmp->getOperand(0)->getType()->isFloatingPointTy())
      internalError("spine: a compare of non-scalar operands reached lowerOpcode (fatptr::lowerCompare)", &I);
    Operand x = ctx.operand(cmp->getOperand(0)), y = ctx.operand(cmp->getOperand(1));
    if (!x.handle && !y.handle) {
      spine::bindOperand(ctx, &I, Operand{spine::copyClassical(ctx, I), false});
      return;
    }
    CmpInst::Predicate p = cmp->getPredicate();
    std::string shape;
    if (x.handle && !y.handle) {
      shape = "hl";
    } else if (!x.handle && y.handle) {
      std::swap(x, y);   // compares never take _lh: flip the predicate (CR §1.2)
      p = CmpInst::getSwappedPredicate(p);
      shape = "hl";
    }
    abi::TemplateSpec spec;
    spec.op = isa<ICmpInst>(cmp) ? "icmp" : "fcmp";
    spec.pred = CmpInst::getPredicateName(p).str();
    spec.w = rt(cmp->getOperand(0)->getType(), &I);
    spec.shape = shape;
    ctx.emitTemplate(spec, {x, y}, &I);
    return;
  }

  if (auto *ci = dyn_cast<CastInst>(&I)) {
    const char *op = castName(ci->getOpcode());
    if (!op)
      internalError("spine: a pointer cast reached lowerOpcode (fatptr)", &I);
    Operand x = ctx.operand(ci->getOperand(0));
    if (!x.handle) {
      spine::bindOperand(ctx, &I, Operand{spine::copyClassical(ctx, I), false});
      return;
    }
    Type *from = ci->getSrcTy(), *to = ci->getDestTy();
    if (from == to) {   // a no-op bitcast: a representation change with no gate (rule 3)
      spine::bindOperand(ctx, &I, x);
      return;
    }
    if (boolCellRepresentation(ctx, *ci)) {
      spine::bindOperand(ctx, &I, x);
      return;
    }
    abi::TemplateSpec spec;
    spec.op = op;
    spec.w = rt(from, &I);
    spec.to = rt(to, &I);
    ctx.emitTemplate(spec, {x}, &I);
    return;
  }

  if (auto *fr = dyn_cast<FreezeInst>(&I)) {
    // Rule 3: a representation change, no gate. A rail's basis value is never poison.
    spine::bindOperand(ctx, &I, ctx.operand(fr->getOperand(0)));
    return;
  }

  if (auto *II = dyn_cast<IntrinsicInst>(&I)) {
    lowerIntrinsic(ctx, *II);
    return;
  }

  unimplemented("spine: lowerOpcode: no rule 4 template for this instruction", &I);
}

// Rule 6 (cq-fufh): a rotation in place on y' = f(y, z), with f a bijection in y (add, sub, xor) and
// the old y dead (y' is its only use), cleans the old y rail first: t = f^-1(y', z), copy t into y,
// uncompute t, free y. The non-diagonal gate noted on y' orders the clean-up before it (144).
void lowerTheta(LoweringContext &ctx, CallInst &call) {
  if (call.arg_size() != 2)
    internalError("spine: cq_theta with other than two arguments", &call);
  Value *v = call.getArgOperand(0);
  Operand angle = ctx.operand(call.getArgOperand(1));
  if (angle.handle)
    internalError("spine: lowerTheta with a quantum angle (rot::lowerQuantumAngleTheta)", &call);
  RailType w = rt(v->getType(), &call);
  Operand x = ctx.operand(v);
  Value *h;
  if (x.handle) {
    h = x.v;   // rule 2: a rotation of an existing rail is in place
  } else {
    if (x.v->getType() != irTypeOf(ctx.M.getContext(), w))
      internalError("spine: cq_theta operand type differs from its rail type", &call);
    CallInst *alloc = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {x.v});
    ctx.unc().recordSeed(alloc);
    h = alloc;
  }
  CallInst *ry = ctx.emitCore(abi::CoreSpec{abi::Core::Ry, w}, {h, angle.v});
  RailId id = ctx.unc().idOf(h);
  // Rotated: a register from here on (38). The role comes first: on a classically merged handle it
  // keeps the chosen arm on each path, which the gate then hits (cq-bv91).
  ctx.unc().setRole(id, Role::UserRegister);
  ctx.unc().noteNonDiagonal(id, ry);
  spine::bindOperand(ctx, &call, Operand{h, true});
}

void lowerMeasure(LoweringContext &ctx, CallInst &call) {
  if (call.arg_size() != 1)
    internalError("spine: cq_measure with other than one argument", &call);
  Operand x = ctx.operand(call.getArgOperand(0));
  if (!x.handle) {
    // A classical value (or a rail already measured at a dominating point: rule 2's classical
    // re-read) measures to itself.
    spine::bindOperand(ctx, &call, x);
    return;
  }
  // cq-ihlt: a value whose only quantum sources a callee measured is classical; its sources' rails
  // are re-read in the caller right after the clone call (rule 2) and cq_measure reads it classically.
  Value *c = spine::calleeCollapse(ctx, x.v, call);
  if (!c)
    c = spine::classicalRead(ctx, x.v);   // cq-i962: a value computed after a collapse
  if (c) {
    spine::bindOperand(ctx, &call, Operand{c, false});
    return;
  }
  RailType w = rt(call.getArgOperand(0)->getType(), &call);
  CallInst *m = ctx.emitCore(abi::CoreSpec{abi::Core::Measure, w}, {x.v});
  // V1 (cq-7p6): a measurement the user wrote carries !cq.measure, the uniqued empty tuple.
  m->setMetadata("cq.measure", MDNode::get(ctx.M.getContext(), {}));
  if (m->getType() != call.getType())
    internalError("spine: cqrt_measure result type differs from cq_measure's", &call);
  ctx.unc().setRole(ctx.unc().idOf(x.v), Role::Measured);
  spine::shared(ctx).measured[x.v] = {&call, m};
  spine::bindOperand(ctx, &call, Operand{m, false});
}

// ---------------------------------------------------------------------------------------------
// CR rule 6 (owner ruling cq-qpsb): every bijective update y' = f(y, ...) of a dead old y cleans
// the old rail: t = f^-1(y', ...), copy t into y, uncompute t, free y (Uncompute::cleanupBijective,
// which orders it before the next non-diagonal gate on y' or f's operands). Called after each
// original instruction is lowered (Construct.cpp).

namespace {

// The old value is a rail the rule may clean: a value this function computed into a rail of its
// own (not an argument, a load, a phi or a classical select over handles, which alias other rails).
bool cleanable(LoweringContext &ctx, Value *y) {
  auto &binds = spine::shared(ctx).binds;
  auto bi = binds.find(y);
  if (bi == binds.end() || bi->second.size() != 1)
    return false;
  auto *I = dyn_cast<Instruction>(y);
  if (!I || isa<LoadInst>(I) || isa<PHINode>(I))
    return false;
  if (auto *sel = dyn_cast<SelectInst>(I); sel && !spine::isQ(ctx, sel->getCondition()))
    return false;
  // A field of a clone call's composite result (an extractvalue of the lowered call, U2): the call's
  // result rails are undone together by its twin (rule 18, 166), never one of them by rule 6.
  if (isa<ExtractValueInst>(ctx.operand(y).v))
    return false;
  return ctx.operand(y).handle;
}

// Dead after `at` (CR rule 6): every other use of y is an earlier instruction that neither stores,
// returns, passes (escape), rotates nor measures it. `also` are further updates that may read y (the
// other select of a swap; the arms of a merge of updates, 125). Earlier: it dominates `at`, or (cq-tmvo)
// it is in a block no path from `at` reaches, from which a path reaches `at`, while `at` lies outside
// every cycle (a read in a sibling arm of a branch that joined before `at`). cq-oqih: a read in a
// sibling arm of `at`'s own branch (neither block reaches the other) is not earlier: a quantum branch
// emits every arm, the sibling after `at`'s (49, 158), and the rail is one rail on every path.
bool deadAfter(LoweringContext &ctx, Value *y, Instruction *at, ArrayRef<const Instruction *> also = {}) {
  DominatorTree &DT = spine::shared(ctx).dt(*at->getFunction());
  SmallVector<const Use *, 8> uses;
  spine::readingUses(spine::shared(ctx), y, uses);   // through skipped zexts (cq-su3p)
  std::optional<DenseSet<const BasicBlock *>> reach;
  auto reachesAt = [&](const BasicBlock *from) {
    DenseSet<const BasicBlock *> seen;
    SmallVector<const BasicBlock *, 16> work(succ_begin(from), succ_end(from));
    while (!work.empty()) {
      const BasicBlock *b = work.pop_back_val();
      if (b == at->getParent())
        return true;
      if (seen.insert(b).second)
        work.append(succ_begin(b), succ_end(b));
    }
    return false;
  };
  auto unreachedFromAt = [&](const Instruction *ui) {
    if (!reach) {
      reach.emplace();
      SmallVector<const BasicBlock *, 16> work(succ_begin(at->getParent()), succ_end(at->getParent()));
      while (!work.empty()) {
        const BasicBlock *b = work.pop_back_val();
        if (reach->insert(b).second)
          work.append(succ_begin(b), succ_end(b));
      }
    }
    return !reach->count(at->getParent()) && !reach->count(ui->getParent()) && ui->getParent() != at->getParent() &&
           reachesAt(ui->getParent());
  };
  for (const Use *U : uses) {
    User *u = U->getUser();
    if (u == at || is_contained(also, u))
      continue;
    auto *ui = dyn_cast<Instruction>(u);
    if (!ui || isa<StoreInst>(ui) || isa<ReturnInst>(ui) || isa<CallBase>(ui) || isa<PHINode>(ui))
      return false;
    if (ui->getFunction() != at->getFunction() || (!DT.dominates(ui, at) && !unreachedFromAt(ui)))
      return false;
  }
  return true;
}

// CR rule 6 Dead (CQ_spec cbda16a, owner ruling 2026-11-01 on cq-k7f8): asked at the CLEAN-UP POINT,
// one placement rule for every opcode. Uncompute places the clean-up after the old value's last reader
// (every IR use of a value naming the rail, every load of a cell holding it, every _unc re-reading it)
// and before the first non-diagonal gate on the rails its inverse reads; a reader after such a gate
// leaves no point and keeps the rail (Role::KeptEntangled). So a later reader never keeps the old
// value here; it is kept only when it escapes or is measured: a use by a return, a call (cq_measure,
// cq_theta, a clone or host call: rules 2, 18), a phi, or a store (its cell may be read after the
// function returns) -- except a store into the very cell an atomic update `at` then overwrites in
// place (94: the rmw reads the cell's x and leaves x + c there). The aliases are the values bound to
// the rail alone and its view phis (cq-su3p). An update in a cycle keeps the strict test (every other
// use dominates it): a reader after it comes round again before it. `also` as for deadAfter.
bool deadAtCleanup(LoweringContext &ctx, Value *Y, Value *h, Instruction *at,
                   ArrayRef<const Instruction *> also = {}) {
  spine::Shared &sh = spine::shared(ctx);
  if (sh.measured.count(h) || sh.measured.count(Y))
    return false;
  if (sh.ruleSixCleaned.count(h))
    return false;   // an earlier update's clean-up already covers this rail (it is placed after this reader)
  const BasicBlock *ab = at->getParent();
  {
    DenseSet<const BasicBlock *> reach;
    SmallVector<const BasicBlock *, 16> work(succ_begin(ab), succ_end(ab));
    while (!work.empty()) {
      const BasicBlock *b = work.pop_back_val();
      if (reach.insert(b).second)
        work.append(succ_begin(b), succ_end(b));
    }
    if (reach.count(ab)) {
      auto bi = sh.binds.find(Y);
      bool own = bi != sh.binds.end() && bi->second.size() == 1 && bi->second.front().v == h;
      return own && deadAfter(ctx, Y, at, also);
    }
  }
  SmallPtrSet<const Value *, 8> A;
  A.insert(Y);
  for (auto &[w, ops] : sh.binds)
    if (ops.size() == 1 && ops.front().handle && ops.front().v == h)
      A.insert(w);
  for (auto &[w, v] : sh.views)
    if (v.rail == h)
      A.insert(w);
  const Value *cellPtr = nullptr;
  if (auto *rmw = dyn_cast<AtomicRMWInst>(at))
    cellPtr = rmw->getPointerOperand();
  DominatorTree &DT = sh.dt(*at->getFunction());
  // A user not lowered yet that may name the rail itself (a freeze, a cast the spine may skip, a
  // classical select or an aggregate or vector carrying it) is followed as an alias.
  auto mayAlias = [&](const Instruction *ui) {
    if (sh.binds.count(ui))
      return false;
    if (auto *sel = dyn_cast<SelectInst>(ui))
      return !spine::isQ(ctx, sel->getCondition());
    return isa<FreezeInst>(ui) || isa<CastInst>(ui) || isa<InsertValueInst>(ui) || isa<ExtractValueInst>(ui) ||
           isa<InsertElementInst>(ui) || isa<ExtractElementInst>(ui) || isa<ShuffleVectorInst>(ui);
  };
  auto laterUpdate = [&](const Instruction *ui, const Value *w) {
    if (auto *bo = dyn_cast<BinaryOperator>(ui)) {
      if (bo->getOperand(0) == bo->getOperand(1))
        return false;
      auto opc = bo->getOpcode();
      if (opc == Instruction::Add || opc == Instruction::Sub || opc == Instruction::Xor)
        return true;
      if (opc == Instruction::Mul) {
        auto *k = dyn_cast<ConstantInt>(bo->getOperand(bo->getOperand(0) == w ? 1 : 0));
        return k && k->getValue()[0];
      }
      return false;
    }
    if (auto *un = dyn_cast<UnaryOperator>(ui))
      return un->getOpcode() == Instruction::FNeg;
    if (auto *II = dyn_cast<IntrinsicInst>(ui)) {
      Intrinsic::ID id = II->getIntrinsicID();
      if (id == Intrinsic::bswap || id == Intrinsic::bitreverse)
        return true;
      if (id == Intrinsic::fshl || id == Intrinsic::fshr)
        return II->getArgOperand(0) == w && II->getArgOperand(1) == w;
      if (const char *v = overflowValueOp(id))
        return std::string(v) != "mul" && II->getArgOperand(0) != II->getArgOperand(1);
    }
    // A quantum select with the rail as an arm: a merge of updates of it (125, mergeCleanup).
    if (auto *sel = dyn_cast<SelectInst>(ui))
      return sel->getCondition() != w && spine::isQ(ctx, sel->getCondition());
    return false;   // an atomic's value operand is no update of it (the rmw updates the cell's old value)
  };
  // A store's cell: an alloca of this function that taint classifies as slot cells (every object the
  // pointer may name), at a classical offset.
  auto localSlotCell = [&](const StoreInst *st) -> const AllocaInst * {
    auto *AI = dyn_cast<AllocaInst>(getUnderlyingObject(st->getPointerOperand()));
    if (!AI || AI->getFunction() != at->getFunction())
      return nullptr;
    ArrayRef<ObjectId> prov = ctx.T.provenance(st->getPointerOperand(), ctx.S);
    if (prov.empty() || any_of(prov, [&](ObjectId o) { return ctx.T.classOf(o) != ObjClass::Slot; }) ||
        ctx.T.offsetKind(st, ctx.S) != OffsetKind::Classical)
      return nullptr;
    return AI;
  };
  // Every load of the object (through constant GEPs); false when the address has any other use (a
  // call argument, a stored or returned pointer, a memory intrinsic: the cell may be read elsewhere).
  auto cellLoads = [&](const AllocaInst *AI, const std::function<void(const Instruction *)> &each) {
    SmallVector<const Value *, 8> ptrs{AI};
    SmallPtrSet<const Value *, 8> seenP;
    while (!ptrs.empty()) {
      const Value *p = ptrs.pop_back_val();
      if (!seenP.insert(p).second)
        continue;
      for (const User *u : p->users()) {
        if (auto *ld = dyn_cast<LoadInst>(u)) {
          each(ld);
          continue;
        }
        if (auto *s2 = dyn_cast<StoreInst>(u); s2 && s2->getPointerOperand() == p && s2->getValueOperand() != p)
          continue;
        if (auto *g = dyn_cast<GetElementPtrInst>(u); g && g->hasAllConstantIndices()) {
          ptrs.push_back(g);
          continue;
        }
        if (auto *II = dyn_cast<IntrinsicInst>(u); II && II->isLifetimeStartOrEnd())
          continue;
        return false;
      }
    }
    return true;
  };
  SmallVector<const Value *, 8> work(A.begin(), A.end());
  while (!work.empty()) {
    const Value *w = work.pop_back_val();
    SmallVector<const Use *, 8> uses;
    spine::readingUses(sh, w, uses);
    for (const Use *U : uses) {
      auto *ui = dyn_cast<Instruction>(U->getUser());
      if (!ui || ui->getFunction() != at->getFunction())
        return false;
      if (ui == at || is_contained(also, ui) || A.count(ui))
        continue;
      if (mayAlias(ui)) {
        A.insert(ui);
        work.push_back(ui);
        continue;
      }
      // A later bijective update of the rail (not lowered yet) cleans it instead: the clean-up point is
      // after that reader, and the image live there is its result (180: b' = a ^ b, then a is rotated,
      // then c' = b ^ m1 is the image b is cleaned from).
      if (!sh.binds.count(ui) && laterUpdate(ui, w))
        return false;
      if (isa<ReturnInst>(ui) || isa<PHINode>(ui))
        return false;
      if (auto *st = dyn_cast<StoreInst>(ui)) {
        if (cellPtr && st->getValueOperand() == w && st->getPointerOperand() == cellPtr && DT.dominates(st, at))
          continue;
        // cq-1jxg (owner 2026-11-01): a store into a local slot cell extends the reader set, it is no
        // escape: the cell's loads read the rail (their values are its aliases, followed for escapes),
        // and Uncompute places the clean-up after them (the new-IR store holds it to the scope exit
        // when they come later). Only memory read after the function returns or a QRAM store keeps it.
        const AllocaInst *cell = st->getValueOperand() == w ? localSlotCell(st) : nullptr;
        if (!cell)
          return false;
        if (!cellLoads(cell, [&](const Instruction *ld) {
              if (A.insert(ld).second)
                work.push_back(ld);
            }))
          return false;
        continue;
      }
      if (auto *cb = dyn_cast<CallBase>(ui)) {
        if (isa<IntrinsicInst>(cb) && cb->doesNotAccessMemory())
          continue;   // lowered to a template that reads the rail
        return false;
      }
      // Any other instruction reads the rail into a fresh one (a template, a compare, an atomic's operand).
    }
  }
  return true;
}

// Does `z` read `y`, through the original instructions computing it? Then y' = y + z(y) is a
// composite update (127), not a bijection in y for fixed z: no rule 6 through z.
// Only quantum values carry the dependency: a measured or classical value is a constant for the
// inverse (rule 2; 180: c' = c ^ m1 with m1 a measurement of a value computed from c).
bool reads(LoweringContext &ctx, Value *z, Value *y, unsigned depth = 0) {
  if (z == y)
    return true;
  auto *I = dyn_cast<Instruction>(z);
  if (!I || depth > 64)
    return false;
  spine::Shared &sh = spine::shared(ctx);
  auto bi = sh.binds.find(z);
  // A skipped zext or an unmaterialized view phi (cq-su3p) reads its operands without a binding.
  bool narrow = sh.narrowSkipped.count(z) || sh.views.count(z);
  if (!narrow && (bi == sh.binds.end() || none_of(bi->second, [](const Operand &o) { return o.handle; })))
    return false;
  for (Value *op : I->operands())
    if (reads(ctx, op, y, depth + 1))
      return true;
  return false;
}

// Does the rail `h` of the new IR hold a function of the rail `y`? Through the histories of the
// spine's emitters (Shared::hist): a template's operands and the in-place writes on a minted rail.
// Too deep to tell counts as reading.
bool railReads(spine::Shared &sh, Value *h, Value *y, unsigned depth = 0) {
  if (h == y)
    return true;
  if (depth > 64)
    return true;
  auto it = sh.hist.find(h);
  if (it == sh.hist.end())
    return false;
  const spine::RailHist &r = it->second;
  if (r.tmpl)
    for (const Operand &o : r.ops)
      if (o.handle && railReads(sh, o.v, y, depth + 1))
        return true;
  for (const spine::RailHist::Write &w : r.writes)
    for (Value *a : w.args)
      if (a != h && (a == y || sh.hist.count(a)) && railReads(sh, a, y, depth + 1))
        return true;
  return false;
}

std::string shapeOf(ArrayRef<Operand> ops) {
  std::string sh;
  bool all = true;
  for (const Operand &o : ops) {
    sh += o.handle ? 'q' : 'l';
    all &= o.handle;
  }
  return all ? "" : sh;
}

// The inverse of a bijective update in y: the template and its forward operands computing the old y.
struct Inverse {
  abi::TemplateSpec spec;
  SmallVector<Operand, 3> ops;
};

Inverse normalized(abi::TemplateSpec spec, SmallVector<Operand, 3> ops) {
  if (ops.size() == 2) {
    // binary templates: "" (both rails), "hl", or "lh" (literal first, a non-commutative op)
    if (ops[0].handle && ops[1].handle) {
      spec.shape = "";
    } else if (ops[0].handle) {
      spec.shape = "hl";
    } else if (spec.op == "add" || spec.op == "xor" || spec.op == "mul") {
      std::swap(ops[0], ops[1]);
      spec.shape = "hl";
    } else {
      spec.shape = "lh";
    }
  } else if (ops.size() == 3 && spec.op != "select") {
    spec.shape = shapeOf(ops);
  }
  return Inverse{std::move(spec), std::move(ops)};
}

APInt oddInverse(const APInt &k) {
  APInt x(k.getBitWidth(), 1);
  for (int i = 0; i < 7; ++i)            // Newton: x <- x (2 - k x), doubling the correct bits
    x = x * (APInt(k.getBitWidth(), 2) - k * x);
  return x;
}

// CR rule 6's bijections: when U = f(y, ...) is a bijection in y for every value of its other
// operands (which do not read y), the inverse computing y from yp (the rail holding f's value).
// Nothing is emitted. The caller has established that y is cleanable and dead.
std::optional<Inverse> inverseOf(LoweringContext &ctx, Instruction &U, Value *Y, Operand yp) {
  abi::TemplateSpec spec;
  // The value field of {u,s}{add,sub}.with.overflow is the add or sub itself (cq-6r4r, 112).
  auto *ovf = dyn_cast<IntrinsicInst>(&U);
  const char *vop = ovf ? overflowValueOp(ovf->getIntrinsicID()) : nullptr;
  auto *bo = dyn_cast<BinaryOperator>(&U);
  if ((bo && bo->getType()->isIntegerTy()) || vop) {
    std::string v = vop ? vop : "";
    auto opc = bo ? bo->getOpcode() : v == "add" ? Instruction::Add : v == "sub" ? Instruction::Sub : Instruction::Mul;
    Value *a0 = U.getOperand(0), *a1 = U.getOperand(1);
    if (a0 == a1 || (Y != a0 && Y != a1))
      return std::nullopt;
    unsigned i = Y == a0 ? 0 : 1;
    Value *Z = U.getOperand(1 - i);
    spec.w = rt(a0->getType(), &U);
    if (opc == Instruction::Add || opc == Instruction::Sub || opc == Instruction::Xor) {
      if (reads(ctx, Z, Y))
        return std::nullopt;
      Operand z = ctx.operand(Z);
      if (opc == Instruction::Add) {
        spec.op = "sub";
        return normalized(spec, {yp, z});            // y = y' - z
      }
      if (opc == Instruction::Xor) {
        spec.op = "xor";
        return normalized(spec, {yp, z});            // y = y' ^ z
      }
      if (i == 0) {
        spec.op = "add";
        return normalized(spec, {yp, z});            // y' = y - z: y = y' + z
      }
      spec.op = "sub";
      return normalized(spec, {z, yp});              // y' = z - y: y = z - y'
    }
    if (opc == Instruction::Mul) {
      auto *k = dyn_cast<ConstantInt>(Z);
      if (!k || !k->getValue()[0])
        return std::nullopt;
      spec.op = "mul";                               // y = y' * k^-1 (mod 2^W), k odd
      return normalized(spec, {yp, Operand{ConstantInt::get(k->getType(), oddInverse(k->getValue())), false}});
    }
    return std::nullopt;
  }
  if (auto *un = dyn_cast<UnaryOperator>(&U); un && un->getOpcode() == Instruction::FNeg) {
    if (un->getOperand(0) != Y)
      return std::nullopt;
    spec.op = "fneg";
    spec.w = rt(U.getType(), &U);
    return normalized(spec, {yp});                   // y = -y'
  }
  if (auto *II = dyn_cast<IntrinsicInst>(&U)) {
    Intrinsic::ID id = II->getIntrinsicID();
    if (id == Intrinsic::bswap || id == Intrinsic::bitreverse) {
      if (II->getArgOperand(0) != Y)
        return std::nullopt;
      if (id == Intrinsic::bitreverse)
        unimplemented("spine: rule 6 clean-up through bitreverse (no template)", &U);
      spec.op = "bswap";
      spec.w = rt(U.getType(), &U);
      return normalized(spec, {yp});                 // an involution
    }
    if ((id == Intrinsic::fshl || id == Intrinsic::fshr) && II->getArgOperand(0) == Y &&
        II->getArgOperand(1) == Y && !reads(ctx, II->getArgOperand(2), Y)) {
      spec.op = id == Intrinsic::fshl ? "fshr" : "fshl";   // a rotation's inverse
      spec.w = rt(U.getType(), &U);
      return normalized(spec, {yp, yp, ctx.operand(II->getArgOperand(2))});
    }
  }
  return std::nullopt;
}

void clean(LoweringContext &ctx, Value *y, const Inverse &inv) {
  Value *h = ctx.operand(y).v;
  ctx.unc().cleanupBijective(ctx.unc().idOf(h), inv.spec, inv.ops);
  spine::shared(ctx).ruleSixCleaned.insert(h);
}

// Garbage rule 5 uncomputes anyway (CR rule 6, both operands dead; cq-12cr): a template result the
// spine minted that no non-diagonal gate or measurement turned into a register, and whose _unc can
// still run: no operand of it was cleaned by rule 6 (cq-tmvo: r = z + x + w with z cleaned at z + x
// leaves z + x a rail rule 5 cannot uncompute; rule 6 then cleans it at its own update).
bool ruleFiveGarbage(LoweringContext &ctx, Value *y) {
  spine::Shared &sh = spine::shared(ctx);
  Value *h = ctx.operand(y).v;
  auto it = sh.hist.find(h);
  if (it == sh.hist.end() || !it->second.tmpl || it->second.opaque || sh.rotations.count(h) || sh.measured.count(h))
    return false;
  return none_of(it->second.ops, [&](const Operand &o) { return o.handle && sh.ruleSixCleaned.count(o.v); });
}

// y = a*x + c + sum(+-rest) over the original instructions computing V (CR rule 6's composite update,
// 127): add, sub, and mul or shl by a literal of a term free of other addends. nullopt: V is no such
// affine function of x.
struct Affine {
  APInt a, c;
  SmallVector<std::pair<bool, Value *>, 4> rest;   // (negated, a value that does not read x)
};

std::optional<Affine> affineIn(LoweringContext &ctx, Value *V, Value *X, unsigned W, unsigned depth = 0) {
  if (V == X)
    return Affine{APInt(W, 1), APInt(W, 0), {}};
  if (auto *k = dyn_cast<ConstantInt>(V))
    return Affine{APInt(W, 0), k->getValue(), {}};
  if (!reads(ctx, V, X))
    return Affine{APInt(W, 0), APInt(W, 0), {{false, V}}};
  auto *bo = dyn_cast<BinaryOperator>(V);
  if (!bo || depth > 16 || !bo->getType()->isIntegerTy(W))
    return std::nullopt;
  auto opc = bo->getOpcode();
  if (opc == Instruction::Add || opc == Instruction::Sub) {
    auto l = affineIn(ctx, bo->getOperand(0), X, W, depth + 1);
    auto r = affineIn(ctx, bo->getOperand(1), X, W, depth + 1);
    if (!l || !r)
      return std::nullopt;
    bool neg = opc == Instruction::Sub;
    l->a = neg ? l->a - r->a : l->a + r->a;
    l->c = neg ? l->c - r->c : l->c + r->c;
    for (auto &[n, v] : r->rest)
      l->rest.push_back({n != neg, v});
    return l;
  }
  if (opc == Instruction::Mul || opc == Instruction::Shl) {
    auto *k = dyn_cast<ConstantInt>(bo->getOperand(1));
    Value *T = bo->getOperand(0);
    if (!k && opc == Instruction::Mul) {
      k = dyn_cast<ConstantInt>(bo->getOperand(0));
      T = bo->getOperand(1);
    }
    if (!k || (opc == Instruction::Shl && k->getValue().uge(W)))
      return std::nullopt;
    APInt f = opc == Instruction::Mul ? k->getValue() : APInt::getOneBitSet(W, k->getZExtValue());
    auto t = affineIn(ctx, T, X, W, depth + 1);
    if (!t || !t->rest.empty())
      return std::nullopt;
    return Affine{t->a * f, t->c * f, {}};
  }
  return std::nullopt;
}

// CR rule 6 on x against the composite update y' = f(g(x), x) (cq-12cr owner ruling, 127): the
// garbage g, computed from x, is uncomputed by rule 5 first (its _unc reads x, so Uncompute orders it
// before x's clean-up). y' = a*x + c + sum(+-rest) is a bijection in x iff a is odd; then
// x = (y' - c - sum(+-rest)) * a^-1, its inner steps fresh garbage rails. An even a: x is kept.
void compositeCleanup(LoweringContext &ctx, Instruction &I, Value *X, Operand yp) {
  if (!I.getType()->isIntegerTy())
    unimplemented("spine: rule 6 composite update (127) of a non-integer value", &I);
  unsigned W = I.getType()->getIntegerBitWidth();
  std::optional<Affine> f = affineIn(ctx, &I, X, W);
  if (!f)
    unimplemented("spine: rule 6 composite update (127) that is not an affine function of the register", &I);
  if (!f->a[0])
    return;   // an even multiplier: no inverse, x is kept
  abi::TemplateSpec spec;
  spec.w = rt(I.getType(), &I);
  SmallVector<Inverse, 4> steps;   // each reads the previous step's rail (yp first)
  if (!f->c.isZero())
    steps.push_back(Inverse{spec, {Operand{}, Operand{ConstantInt::get(I.getType(), f->c), false}}});
  for (auto &[neg, v] : f->rest) {
    steps.push_back(Inverse{spec, {Operand{}, ctx.operand(v)}});
    steps.back().spec.op = neg ? "add" : "sub";
  }
  if (!f->c.isZero())
    steps.front().spec.op = "sub";
  if (!f->a.isOne()) {
    steps.push_back(Inverse{spec, {Operand{}, Operand{ConstantInt::get(I.getType(), oddInverse(f->a)), false}}});
    steps.back().spec.op = "mul";
  }
  if (steps.empty()) {   // y' = x (2x - x): t = y' + 0
    steps.push_back(Inverse{spec, {Operand{}, Operand{ConstantInt::get(I.getType(), 0), false}}});
    steps.back().spec.op = "add";
  }
  RailId xid = ctx.unc().idOf(ctx.operand(X).v);
  Operand cur = yp;
  for (size_t k = 0; k < steps.size(); ++k) {
    steps[k].ops[0] = cur;
    Inverse inv = normalized(steps[k].spec, steps[k].ops);
    if (k + 1 == steps.size()) {
      clean(ctx, X, inv);
      return;
    }
    Value *h = ctx.emitTemplate(inv.spec, inv.ops);
    ctx.unc().noteUse(xid, cast<Instruction>(h));
    cur = Operand{h, true};
  }
}

// CR rule 6, a select whose arms are bijective updates of y or y itself (125): a quantum select or a
// quantum-join phi M, lowered (rule 9) to a chain of select templates over the rails of its arms. Its
// inverse is the same chain over the inverses of the arms, read from M's rail: t = c ? f^-1(y') : y'
// for y' = c ? f(y) : y, where no condition of the chain reads y (else M is no bijection in y). The
// arms' inverses and the inner selects are fresh garbage rails (rule 5 undoes them after the clean-up
// that reads them); the outermost select is the clean-up's inverse (Uncompute::cleanupBijective).
void mergeCleanup(LoweringContext &ctx, Instruction &M, ArrayRef<Value *> arms, Operand yp) {
  spine::Shared &sh = spine::shared(ctx);
  DenseMap<Value *, Value *> leafOf;   // an arm's rail -> the arm
  for (Value *a : arms) {
    Operand o = ctx.operand(a);
    if (!o.handle)
      return;   // a classical arm: M is no bijection in any rail
    leafOf.try_emplace(o.v, a);
  }
  if (leafOf.count(yp.v))
    return;     // M is one of its arms (one arm reaches it on every path): no select to invert
  SmallVector<Value *, 4> cands;
  SmallVector<const Instruction *, 4> updates;
  for (Value *a : arms) {
    if (!is_contained(cands, a))
      cands.push_back(a);
    if (auto *U = dyn_cast<Instruction>(a)) {
      updates.push_back(U);
      for (Value *op : U->operands())
        if (!is_contained(cands, op))
          cands.push_back(op);
    }
  }
  for (Value *Y : cands) {
    if (!cleanable(ctx, Y))
      continue;
    SmallVector<const Instruction *, 4> also;
    for (const Instruction *U : updates)
      if (U != Y)
        also.push_back(U);
    if (!deadAtCleanup(ctx, Y, ctx.operand(Y).v, &M, also))
      continue;
    Value *yr = ctx.operand(Y).v;
    // The chain is a bijection in y: every node a select on a condition rail that does not read y,
    // every leaf y itself or a bijective update of it, at least one an update.
    bool updated = false;
    std::function<bool(Value *)> ok = [&](Value *h) -> bool {
      if (auto l = leafOf.find(h); l != leafOf.end()) {
        if (l->second == Y)
          return true;
        auto *U = dyn_cast<Instruction>(l->second);
        if (!U || !inverseOf(ctx, *U, Y, yp))
          return false;
        updated = true;
        return true;
      }
      auto it = sh.hist.find(h);
      if (it == sh.hist.end() || !it->second.tmpl || it->second.spec.op != "select" || it->second.ops.size() != 3)
        return false;
      const auto &ops = it->second.ops;
      return ops[0].handle && ops[1].handle && ops[2].handle && !railReads(sh, ops[0].v, yr) && ok(ops[1].v) &&
             ok(ops[2].v);
    };
    if (!ok(yp.v) || !updated)
      continue;
    // An inner rail of t, emitted here. The clean-up is placed after the last use of y (Uncompute):
    // each inner rail is noted as a use of y so that the clean-up reading it comes after it.
    RailId yid = ctx.unc().idOf(yr);
    auto inner = [&](const Inverse &inv) {
      Value *h = ctx.emitTemplate(inv.spec, inv.ops);
      ctx.unc().noteUse(yid, cast<Instruction>(h));
      return h;
    };
    std::function<Operand(Value *, bool)> emit = [&](Value *h, bool top) -> Operand {
      if (auto l = leafOf.find(h); l != leafOf.end()) {
        if (l->second == Y)
          return yp;
        Inverse inv = *inverseOf(ctx, *cast<Instruction>(l->second), Y, yp);
        return Operand{inner(inv), true};
      }
      const spine::RailHist &r = sh.hist.find(h)->second;
      abi::TemplateSpec spec = r.spec;
      Operand c = r.ops[0], tv = r.ops[1], fv = r.ops[2];
      Operand a = emit(tv.v, false), b = emit(fv.v, false);
      Inverse inv{spec, {c, a, b}};
      inv.spec.shape = "";
      if (top) {
        clean(ctx, Y, inv);
        return Operand{};
      }
      return Operand{inner(inv), true};
    };
    emit(yp.v, true);
    return;
  }
}

} // namespace

namespace {

// CR rule 6 on a compare narrowed to xor_i1 (cq-su3p, 113's q2 ^= q1 over i1-valued bytes): the
// first narrow operand whose rail the spine minted and is dead after it is cleaned by t = y' ^ z.
void narrowRuleSix(LoweringContext &ctx, Instruction &I, ArrayRef<const Value *> nv, Operand yp) {
  spine::Shared &sh = spine::shared(ctx);
  auto railOf = [&](const Value *w) -> Value * {
    if (auto it = sh.views.find(w); it != sh.views.end())
      return it->second.rail;
    auto bi = sh.binds.find(w);
    if (bi == sh.binds.end() || bi->second.size() != 1 || !bi->second.front().handle)
      return nullptr;
    return bi->second.front().v;
  };
  for (unsigned k = 0; k < 2; ++k) {
    const Value *Y = nv[k], *Z = nv[1 - k];
    if (isa<Constant>(Y))
      continue;
    Value *h = railOf(Y);
    if (!h || !sh.hist.count(h) || sh.measured.count(h))
      continue;
    Operand z;
    if (auto *c = dyn_cast<Constant>(Z)) {
      z = Operand{const_cast<Constant *>(c), false};
    } else {
      Value *zr = railOf(Z);
      if (!zr || zr == h || reads(ctx, const_cast<Value *>(Z), const_cast<Value *>(Y)))
        continue;
      z = sh.views.count(Z) ? Operand{zr, true} : ctx.operand(Z);
    }
    if (!deadAtCleanup(ctx, const_cast<Value *>(Y), h, &I))
      continue;
    abi::TemplateSpec spec;
    spec.op = "xor";
    spec.w = RailType{Kind::Int, 1};
    Inverse inv = normalized(spec, {yp, z});                 // y = y' ^ z
    ctx.unc().cleanupBijective(ctx.unc().idOf(h), inv.spec, inv.ops);
    sh.ruleSixCleaned.insert(h);
    return;
  }
}

} // namespace

namespace {

// CR rules 6 and 24 on an atomic read-modify-write of a slot cell (94): mem-slots lowers
// `old = atomicrmw add|sub|xor p, v` to y' = old op v stored into the cell, binding the instruction to
// old's rail. y' is a bijection in old when v does not read it, so a dead old rail is cleaned from y':
// old = y' - v, y' + v, y' ^ v. The old rail must be one this function minted (a register's or a
// template's rail, not a formal or a merge of cell contents).
void atomicRuleSix(LoweringContext &ctx, AtomicRMWInst &I) {
  spine::Shared &sh = spine::shared(ctx);
  const char *inverse = nullptr, *fwdOp = nullptr;
  switch (I.getOperation()) {
  case AtomicRMWInst::Add: fwdOp = "add"; inverse = "sub"; break;
  case AtomicRMWInst::Sub: fwdOp = "sub"; inverse = "add"; break;
  case AtomicRMWInst::Xor: fwdOp = "xor"; inverse = "xor"; break;
  default: return;
  }
  auto bi = sh.binds.find(&I);
  if (bi == sh.binds.end() || bi->second.size() != 1 || !bi->second.front().handle)
    return;
  Value *h = bi->second.front().v;
  auto *minted = dyn_cast<CallInst>(h);
  Function *mf = minted ? minted->getCalledFunction() : nullptr;
  bool unc = false;
  std::optional<abi::CoreSpec> core = mf ? abi::parseCore(mf->getName()) : std::nullopt;
  if (!mf || !((core && core->op == abi::Core::Alloc) || abi::parseTemplate(mf->getName(), &unc)))
    return;
  Operand v = ctx.operand(I.getValOperand());
  if (v.handle && railReads(sh, v.v, h))
    return;
  // y': the template mem-slots just emitted over (old, v) in the current block.
  CallInst *yp = nullptr;
  for (User *u : h->users()) {
    auto *c = dyn_cast<CallInst>(u);
    Function *cf = c ? c->getCalledFunction() : nullptr;
    std::optional<abi::TemplateSpec> t = cf ? abi::parseTemplate(cf->getName(), &unc) : std::nullopt;
    if (!t || unc || t->op != fwdOp || c->getParent() != ctx.B().GetInsertBlock() || c->getArgOperand(0) != h ||
        c->arg_size() != 2 || c->getArgOperand(1) != v.v)
      continue;
    if (!yp || yp->comesBefore(c))
      yp = c;
  }
  if (!yp)
    internalError("spine: rule 6 on an atomicrmw: no template over the old cell value found", &I);
  if (!deadAtCleanup(ctx, &I, h, &I))
    return;
  abi::TemplateSpec spec;
  spec.op = inverse;
  spec.w = rt(I.getType(), &I);
  Inverse inv = normalized(spec, {Operand{yp, true}, v});   // y = y' -/+/^ v
  ctx.unc().cleanupBijective(ctx.unc().idOf(h), inv.spec, inv.ops);
  sh.ruleSixCleaned.insert(h);
}

} // namespace

namespace spine {

void ruleSixAfter(LoweringContext &ctx, Instruction &I) {
  if (auto *rmw = dyn_cast<AtomicRMWInst>(&I)) {
    atomicRuleSix(ctx, *rmw);
    return;
  }
  if (auto nx = shared(ctx).narrowXor.find(&I); nx != shared(ctx).narrowXor.end()) {
    SmallVector<const Value *, 2> nv(nx->second.begin(), nx->second.end());
    Operand yp = ctx.operand(&I);
    if (yp.handle)
      narrowRuleSix(ctx, I, nv, yp);
    return;
  }
  if (!(isa<BinaryOperator>(I) || isa<UnaryOperator>(I) || isa<IntrinsicInst>(I) || isa<SelectInst>(I) ||
        isa<PHINode>(I)))
    return;
  auto &binds = spine::shared(ctx).binds;
  auto bi = binds.find(&I);
  Operand yp;
  auto *ovf = dyn_cast<IntrinsicInst>(&I);
  if (ovf && overflowValueOp(ovf->getIntrinsicID())) {
    // {value, overflow}: y' is the value field's rail (cq-6r4r); the overflow field's template reads y
    // too, a reader that only moves the clean-up.
    if (bi == binds.end() || bi->second.size() != 2 || !bi->second[0].handle)
      return;
    yp = bi->second[0];
  } else {
    if (I.getType()->isVoidTy() || I.getType()->isVectorTy() || I.getType()->isStructTy())
      return;
    if (bi == binds.end() || bi->second.size() != 1 || !bi->second[0].handle)
      return;
    yp = ctx.operand(&I);
  }

  if (auto *phi = dyn_cast<PHINode>(&I)) {
    SmallVector<Value *, 4> arms(phi->incoming_values().begin(), phi->incoming_values().end());
    mergeCleanup(ctx, I, arms, yp);
    return;
  }

  if (auto *sel = dyn_cast<SelectInst>(&I)) {
    if (!spine::isQ(ctx, sel->getCondition()))
      return;
    Value *c = sel->getCondition(), *A = sel->getTrueValue(), *B = sel->getFalseValue();
    // A controlled swap (145): this select and an earlier q = select(c, B, A).
    for (User *u : c->users()) {
      auto *q = dyn_cast<SelectInst>(u);
      if (!q || q == sel || q->getCondition() != c || q->getTrueValue() != B || q->getFalseValue() != A ||
          !q->comesBefore(sel) || A == B)
        continue;
      if (!sel->getType()->isIntegerTy() || !cleanable(ctx, A) || !cleanable(ctx, B) ||
          !deadAtCleanup(ctx, A, ctx.operand(A).v, &I, {q}) || !deadAtCleanup(ctx, B, ctx.operand(B).v, &I, {q}))
        return;
      abi::TemplateSpec spec;
      spec.op = "select";
      spec.w = rt(I.getType(), &I);
      spec.shape = "";
      Operand cp = ctx.operand(c), qq = ctx.operand(q);
      // q = select(c, B, A), sel = select(c, A, B): B = select(c, q, sel), A = select(c, sel, q)
      clean(ctx, B, Inverse{spec, {cp, qq, yp}});
      clean(ctx, A, Inverse{spec, {cp, yp, qq}});
      return;
    }
    // A select whose arms are updates of y or y itself (125).
    mergeCleanup(ctx, I, {A, B}, yp);
    return;
  }

  // y' = f(y, ...): the first operand that is a cleanable dead rail f is a bijection in. An old y that
  // another live garbage rail still needs for its uncompute (a sibling arm 3y of y ^ 7 that a later
  // select reads, 920_pu) is not cleaned here: CR rule 6 applies after that rail is uncomputed, to the
  // composite update, which is the later consumer's (the select's merge clean-up, cq-hge5).
  auto neededLater = [&](Value *Y) {
    for (User *u : Y->users()) {
      auto *U = dyn_cast<Instruction>(u);
      if (!U || U == &I || U->getType()->isVoidTy() || !spine::shared(ctx).binds.count(U) ||
          !ctx.operand(U).handle || !ruleFiveGarbage(ctx, U))
        continue;
      if (!deadAfter(ctx, U, &I))
        return true;
    }
    return false;
  };
  SmallVector<Value *, 3> dead;
  for (Value *Y : I.operands())
    if (!is_contained(dead, Y) && cleanable(ctx, Y) && deadAtCleanup(ctx, Y, ctx.operand(Y).v, &I) && !neededLater(Y))
      dead.push_back(Y);
  // CR rule 6, both operands dead (cq-12cr): when exactly one is garbage rule 5 uncomputes anyway, the
  // other is cleaned (its inverse reads the garbage, whose _unc follows in its usual place); when that
  // garbage was computed from the other, it is uncomputed first and rule 6 asks the composite update.
  // Otherwise operand 0 of the IR instruction is cleaned and the other kept.
  if (dead.size() == 2) {
    bool g0 = ruleFiveGarbage(ctx, dead[0]), g1 = ruleFiveGarbage(ctx, dead[1]);
    if (g0 != g1) {
      Value *G = g0 ? dead[0] : dead[1], *R = g0 ? dead[1] : dead[0];
      if (reads(ctx, G, R)) {
        if (inverseOf(ctx, I, G, yp)) {
          compositeCleanup(ctx, I, R, yp);
          return;
        }
      } else if (auto inv = inverseOf(ctx, I, R, yp)) {
        clean(ctx, R, *inv);
        return;
      }
    }
  }
  for (Value *Y : dead)
    if (auto inv = inverseOf(ctx, I, Y, yp)) {
      clean(ctx, Y, *inv);
      return;
    }
}

} // namespace spine
} // namespace cq
