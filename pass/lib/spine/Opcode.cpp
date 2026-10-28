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

#include "cq/Abi.h"
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
  case Intrinsic::usub_sat: data = 2; break;
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
// y is dead after `at`: every other use of y is an instruction in at's block that comes before it
// (180: c's first CNOT reads it before c ^ m1).
static bool deadAfter(Value *y, Instruction *at) {
  for (User *u : y->users()) {
    if (u == at)
      continue;
    auto *ui = dyn_cast<Instruction>(u);
    if (!ui || ui->getParent() != at->getParent() || !ui->comesBefore(at))
      return false;
  }
  return true;
}

static void ruleSixBeforeRotation(LoweringContext &ctx, Value *v, Value *yPrime) {
  auto *bo = dyn_cast<BinaryOperator>(v);
  if (!bo || !bo->getType()->isIntegerTy())
    return;
  auto opc = bo->getOpcode();
  if (opc != Instruction::Add && opc != Instruction::Sub && opc != Instruction::Xor)
    return;
  for (unsigned i = 0; i < 2; ++i) {
    Value *Y = bo->getOperand(i), *Z = bo->getOperand(1 - i);
    Operand y = ctx.operand(Y);
    if (!y.handle || !deadAfter(Y, bo))
      continue;
    Operand z = ctx.operand(Z), yp{yPrime, true};
    // CR rule 6 applies whether z is a rail (144) or classical (180: c ^ m1 with m1 measured). The
    // 38 rotate_derived reference keeps the dead x of y = x + c; CR wins (SPEC_ISSUES.md, cq-tvfm).
    abi::TemplateSpec spec;
    spec.w = rt(bo->getType(), bo);
    Operand a = yp, b = z;
    if (opc == Instruction::Add) {
      spec.op = "sub";                    // y = y' - z
    } else if (opc == Instruction::Xor) {
      spec.op = "xor";                    // y = y' ^ z
    } else if (i == 0) {
      spec.op = "add";                    // y' = y - z: y = y' + z
    } else {
      spec.op = "sub";                    // y' = z - y: y = z - y'
      a = z;
      b = yp;
    }
    if (a.handle && b.handle) {
      spec.shape = "";
    } else if (a.handle) {
      spec.shape = "hl";
    } else if (spec.op != "sub") {
      std::swap(a, b);
      spec.shape = "hl";
    } else {
      spec.shape = "lh";
    }
    ctx.unc().cleanupBijective(ctx.unc().idOf(y.v), spec, {a, b});
    return;
  }
}

// Rule 6, a controlled swap (145): p = select(c, A, B) and q = select(c, B, A) with A, B rails whose
// only uses are these two selects. A rotation in place on c cleans the old A and B first, through
// the swap's inverse: A = select(c, p, q), B = select(c, q, p).
static void ruleSixSwapBeforeRotation(LoweringContext &ctx, Value *c) {
  SmallVector<SelectInst *, 4> sels;
  for (User *u : c->users())
    if (auto *s = dyn_cast<SelectInst>(u); s && s->getCondition() == c && s->getType()->isIntegerTy())
      sels.push_back(s);
  for (SelectInst *p : sels)
    for (SelectInst *q : sels) {
      if (p == q || p->getTrueValue() != q->getFalseValue() || p->getFalseValue() != q->getTrueValue())
        continue;
      Value *A = p->getTrueValue(), *B = p->getFalseValue();
      if (A == B || A->getNumUses() != 2 || B->getNumUses() != 2)
        continue;
      Operand a = ctx.operand(A), b = ctx.operand(B), cp = ctx.operand(c), pp = ctx.operand(p), qq = ctx.operand(q);
      if (!a.handle || !b.handle || !cp.handle || !pp.handle || !qq.handle)
        continue;
      abi::TemplateSpec spec;
      spec.op = "select";
      spec.w = rt(p->getType(), p);
      spec.shape = "";
      // p (A when c) appears first among the swap's two selects: clean A and B once, from that pair
      if (p->comesBefore(q) || p->getParent() != q->getParent()) {
        ctx.unc().cleanupBijective(ctx.unc().idOf(a.v), spec, {cp, pp, qq});
        ctx.unc().cleanupBijective(ctx.unc().idOf(b.v), spec, {cp, qq, pp});
        return;
      }
    }
}

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
    ruleSixBeforeRotation(ctx, v, h);
    ruleSixSwapBeforeRotation(ctx, v);
  } else {
    if (x.v->getType() != irTypeOf(ctx.M.getContext(), w))
      internalError("spine: cq_theta operand type differs from its rail type", &call);
    CallInst *alloc = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {x.v});
    ctx.unc().recordSeed(alloc);
    h = alloc;
  }
  CallInst *ry = ctx.emitCore(abi::CoreSpec{abi::Core::Ry, w}, {h, angle.v});
  RailId id = ctx.unc().idOf(h);
  ctx.unc().noteNonDiagonal(id, ry);
  ctx.unc().setRole(id, Role::UserRegister);   // rotated: a register from here on (38)
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

} // namespace cq
