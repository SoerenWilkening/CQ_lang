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
  return ctx.operand(y).handle;
}

// Dead after `at` (CR rule 6): every other use of y is an earlier instruction that neither stores,
// returns, passes (escape), rotates nor measures it. `also` is a second update that may read y
// (the other select of a swap).
bool deadAfter(LoweringContext &ctx, Value *y, Instruction *at, Instruction *also = nullptr) {
  DominatorTree &DT = spine::shared(ctx).dt(*at->getFunction());
  for (User *u : y->users()) {
    if (u == at || u == also)
      continue;
    auto *ui = dyn_cast<Instruction>(u);
    if (!ui || isa<StoreInst>(ui) || isa<ReturnInst>(ui) || isa<CallBase>(ui) || isa<PHINode>(ui))
      return false;
    if (!DT.dominates(ui, at))
      return false;
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
  auto &binds = spine::shared(ctx).binds;
  auto bi = binds.find(z);
  if (bi == binds.end() || none_of(bi->second, [](const Operand &o) { return o.handle; }))
    return false;
  for (Value *op : I->operands())
    if (reads(ctx, op, y, depth + 1))
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

void clean(LoweringContext &ctx, Value *y, abi::TemplateSpec spec, SmallVector<Operand, 3> ops) {
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
  ctx.unc().cleanupBijective(ctx.unc().idOf(ctx.operand(y).v), spec, ops);
}

APInt oddInverse(const APInt &k) {
  APInt x(k.getBitWidth(), 1);
  for (int i = 0; i < 7; ++i)            // Newton: x <- x (2 - k x), doubling the correct bits
    x = x * (APInt(k.getBitWidth(), 2) - k * x);
  return x;
}

} // namespace

namespace spine {

void ruleSixAfter(LoweringContext &ctx, Instruction &I) {
  if (!(isa<BinaryOperator>(I) || isa<UnaryOperator>(I) || isa<IntrinsicInst>(I) || isa<SelectInst>(I)))
    return;
  if (I.getType()->isVoidTy() || I.getType()->isVectorTy() || I.getType()->isStructTy())
    return;
  auto &binds = spine::shared(ctx).binds;
  auto bi = binds.find(&I);
  if (bi == binds.end() || bi->second.size() != 1 || !bi->second[0].handle)
    return;
  Operand yp = ctx.operand(&I);
  abi::TemplateSpec spec;

  if (auto *bo = dyn_cast<BinaryOperator>(&I); bo && bo->getType()->isIntegerTy()) {
    auto opc = bo->getOpcode();
    Value *a0 = bo->getOperand(0), *a1 = bo->getOperand(1);
    if (a0 == a1)
      return;
    spec.w = rt(bo->getType(), bo);
    if (opc == Instruction::Add || opc == Instruction::Sub || opc == Instruction::Xor) {
      // both operands dead: operand 0 is cleaned, the other kept (CR rule 6)
      for (unsigned i = 0; i < 2; ++i) {
        Value *Y = bo->getOperand(i), *Z = bo->getOperand(1 - i);
        if (!cleanable(ctx, Y) || !deadAfter(ctx, Y, &I) || reads(ctx, Z, Y))
          continue;
        Operand z = ctx.operand(Z);
        if (opc == Instruction::Add) {
          spec.op = "sub";
          clean(ctx, Y, spec, {yp, z});              // y = y' - z
        } else if (opc == Instruction::Xor) {
          spec.op = "xor";
          clean(ctx, Y, spec, {yp, z});              // y = y' ^ z
        } else if (i == 0) {
          spec.op = "add";
          clean(ctx, Y, spec, {yp, z});              // y' = y - z: y = y' + z
        } else {
          spec.op = "sub";
          clean(ctx, Y, spec, {z, yp});              // y' = z - y: y = z - y'
        }
        return;
      }
      return;
    }
    if (opc == Instruction::Mul) {
      for (unsigned i = 0; i < 2; ++i) {
        auto *k = dyn_cast<ConstantInt>(bo->getOperand(1 - i));
        Value *Y = bo->getOperand(i);
        if (!k || !k->getValue()[0] || !cleanable(ctx, Y) || !deadAfter(ctx, Y, &I))
          continue;
        spec.op = "mul";                               // y = y' * k^-1 (mod 2^W), k odd
        clean(ctx, Y, spec, {yp, Operand{ConstantInt::get(k->getType(), oddInverse(k->getValue())), false}});
        return;
      }
    }
    return;
  }

  if (auto *un = dyn_cast<UnaryOperator>(&I); un && un->getOpcode() == Instruction::FNeg) {
    Value *Y = un->getOperand(0);
    if (cleanable(ctx, Y) && deadAfter(ctx, Y, &I)) {
      spec.op = "fneg";
      spec.w = rt(I.getType(), &I);
      clean(ctx, Y, spec, {yp});                       // y = -y'
    }
    return;
  }

  if (auto *II = dyn_cast<IntrinsicInst>(&I)) {
    Intrinsic::ID id = II->getIntrinsicID();
    if (id == Intrinsic::bswap || id == Intrinsic::bitreverse) {
      Value *Y = II->getArgOperand(0);
      if (cleanable(ctx, Y) && deadAfter(ctx, Y, &I)) {
        if (id == Intrinsic::bitreverse)
          unimplemented("spine: rule 6 clean-up through bitreverse (no template)", &I);
        spec.op = "bswap";
        spec.w = rt(I.getType(), &I);
        clean(ctx, Y, spec, {yp});                     // an involution
      }
      return;
    }
    if ((id == Intrinsic::fshl || id == Intrinsic::fshr) && II->getArgOperand(0) == II->getArgOperand(1)) {
      Value *Y = II->getArgOperand(0);
      if (cleanable(ctx, Y) && deadAfter(ctx, Y, &I) && !reads(ctx, II->getArgOperand(2), Y)) {
        spec.op = id == Intrinsic::fshl ? "fshr" : "fshl";   // a rotation's inverse
        spec.w = rt(I.getType(), &I);
        clean(ctx, Y, spec, {yp, yp, ctx.operand(II->getArgOperand(2))});
      }
      return;
    }
    return;
  }

  if (auto *sel = dyn_cast<SelectInst>(&I); sel && sel->getType()->isIntegerTy() &&
                                            spine::isQ(ctx, sel->getCondition())) {
    Value *c = sel->getCondition(), *A = sel->getTrueValue(), *B = sel->getFalseValue();
    // A controlled swap (145): this select and an earlier q = select(c, B, A).
    for (User *u : c->users()) {
      auto *q = dyn_cast<SelectInst>(u);
      if (!q || q == sel || q->getCondition() != c || q->getTrueValue() != B || q->getFalseValue() != A ||
          !q->comesBefore(sel) || A == B)
        continue;
      if (!cleanable(ctx, A) || !cleanable(ctx, B) || !deadAfter(ctx, A, &I, q) || !deadAfter(ctx, B, &I, q))
        return;
      spec.op = "select";
      spec.w = rt(I.getType(), &I);
      spec.shape = "";
      Operand cp = ctx.operand(c), qq = ctx.operand(q);
      // q = select(c, B, A), sel = select(c, A, B): B = select(c, q, sel), A = select(c, sel, q)
      clean(ctx, B, spec, {cp, qq, yp});
      clean(ctx, A, spec, {cp, yp, qq});
      return;
    }
    // A select whose arms are updates of y or y itself (125): not built yet.
    for (Value *arm : {A, B}) {
      auto *bo = dyn_cast<BinaryOperator>(arm);
      if (!bo)
        continue;
      for (Value *Y : {bo->getOperand(0), bo->getOperand(1)})
        if ((Y == A || Y == B) && cleanable(ctx, Y) && deadAfter(ctx, Y, &I, bo))
          unimplemented("spine: rule 6 through a select of updates (125)", &I);
    }
  }
}

} // namespace spine
} // namespace cq
