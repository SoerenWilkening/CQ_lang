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
#include "cq/Calls.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"

using namespace llvm;

namespace cq {

namespace {

RailType rt(Type *t, const Value *at) {
  if (t->isPointerTy())
    return RailType{Kind::Int, 64};   // rule 21: a pointer is its address, an i64
  if (!t->isIntegerTy() && !t->isHalfTy() && !t->isBFloatTy() && !t->isFloatTy() && !t->isDoubleTy() && !t->isX86_FP80Ty())
    internalError("spine: a scalar rail type asked of a vector, pointer or fp128 (rules 21, 25: routed elsewhere)", at);
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
  case Intrinsic::bitreverse: return "bitreverse";
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

// Intrinsics with a quantum operand that carry no operation of their own (calls::classify routes them
// here with the templates): a value hint is its operand (rule 3, a representation change: expect,
// ssa.copy, annotation), an optimisation hint is nothing (assume: an input on which it is false has
// undefined behaviour and is outside the domain; prefetch, var.annotation, sideeffect), and a
// compile-time query is the constant LLVM's own lowering gives when it cannot fold it
// (LowerConstantIntrinsics: is.constant false, objectsize -1 or, with min, 0). The three-way compares
// and canonicalize are rule 4 templates composed: scmp(a, b) = zext(a > b) - zext(a < b) at the
// result width; canonicalize(x) = x * 1.0 (IEEE: the same value, a signalling NaN quieted, a
// non-canonical f80 the invalid result, as x86 computes it). True when II was one of them.
bool lowerHintIntrinsic(LoweringContext &ctx, IntrinsicInst &II) {
  Intrinsic::ID id = II.getIntrinsicID();
  switch (id) {
  case Intrinsic::expect:
  case Intrinsic::expect_with_probability:
  case Intrinsic::ssa_copy:
  case Intrinsic::annotation:
    spine::bindOperand(ctx, &II, ctx.operand(II.getArgOperand(0)));
    return true;
  case Intrinsic::assume:
  case Intrinsic::prefetch:
  case Intrinsic::var_annotation:
  case Intrinsic::sideeffect:
  case Intrinsic::donothing:
    return true;
  case Intrinsic::is_constant:
    spine::bindOperand(ctx, &II, Operand{ConstantInt::getFalse(ctx.M.getContext()), false});
    return true;
  case Intrinsic::objectsize: {
    bool min = cast<ConstantInt>(II.getArgOperand(1))->isOne();
    spine::bindOperand(ctx, &II, Operand{ConstantInt::get(II.getType(), min ? 0 : -1, true), false});
    return true;
  }
  case Intrinsic::canonicalize: {
    abi::TemplateSpec spec;
    spec.op = "fmul";
    spec.w = rt(II.getType(), &II);
    if (!binary(ctx, spec, II.getArgOperand(0), ConstantFP::get(II.getType(), 1.0), &II))
      spine::bindOperand(ctx, &II, Operand{spine::copyClassical(ctx, II), false});   // rule 2 collapse
    return true;
  }
  case Intrinsic::scmp:
  case Intrinsic::ucmp: {
    Value *a = II.getArgOperand(0), *b = II.getArgOperand(1);
    if (!ctx.operand(a).handle && !ctx.operand(b).handle) {
      spine::bindOperand(ctx, &II, Operand{spine::copyClassical(ctx, II), false});   // rule 2 collapse
      return true;
    }
    bool s = id == Intrinsic::scmp;
    RailType w = rt(II.getType(), &II);
    auto side = [&](CmpInst::Predicate p) {
      Operand x = ctx.operand(a), y = ctx.operand(b);
      abi::TemplateSpec c;
      c.op = "icmp";
      c.w = rt(a->getType(), &II);
      if (!x.handle) {   // compares never take _lh: flip the predicate (CR §1.2)
        std::swap(x, y);
        p = CmpInst::getSwappedPredicate(p);
      }
      c.pred = CmpInst::getPredicateName(p).str();
      c.shape = y.handle ? "" : "hl";
      Value *f = ctx.emitTemplate(c, {x, y});
      abi::TemplateSpec z;
      z.op = "zext";
      z.w = RailType{Kind::Int, 1};
      z.to = w;
      return Operand{ctx.emitTemplate(z, {Operand{f, true}}), true};
    };
    Operand gt = side(s ? CmpInst::ICMP_SGT : CmpInst::ICMP_UGT);
    Operand lt = side(s ? CmpInst::ICMP_SLT : CmpInst::ICMP_ULT);
    abi::TemplateSpec d;
    d.op = "sub";
    d.w = w;
    ctx.emitTemplate(d, {gt, lt}, &II);
    return true;
  }
  default:
    return false;
  }
}

void lowerIntrinsic(LoweringContext &ctx, IntrinsicInst &II) {
  Intrinsic::ID id = II.getIntrinsicID();
  if (lowerHintIntrinsic(ctx, II))
    return;
  if (id == Intrinsic::ptrmask) {   // rule 21: an integer template over the address
    abi::TemplateSpec spec;
    spec.op = "and";
    spec.w = RailType{Kind::Int, 64};
    if (!binary(ctx, spec, II.getArgOperand(0), II.getArgOperand(1), &II))
      spine::bindOperand(ctx, &II, Operand{spine::copyClassical(ctx, II), false});
    return;
  }
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


} // namespace

void lowerOpcode(LoweringContext &ctx, Instruction &I) {
  if (I.getType()->isVectorTy())
    internalError("spine: lowerOpcode on a vector (aggr::lowerVectorOp)", &I);

  if (auto *bo = dyn_cast<BinaryOperator>(&I)) {
    const char *op = binName(bo->getOpcode());
    if (!op)   // binName names every LLVM 19 binary opcode
      internalError("spine: a binary opcode binName does not name", &I);
    abi::TemplateSpec spec;
    spec.op = op;
    spec.w = rt(I.getType(), &I);
    if (!binary(ctx, spec, bo->getOperand(0), bo->getOperand(1), &I))
      spine::bindOperand(ctx, &I, Operand{spine::copyClassical(ctx, I), false}); // rule 2 collapse
    return;
  }

  if (auto *un = dyn_cast<UnaryOperator>(&I)) {
    if (un->getOpcode() != Instruction::FNeg)   // fneg is LLVM 19's only unary operator
      internalError("spine: a unary opcode other than fneg", &I);
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
    if (!cmp->getOperand(0)->getType()->isIntegerTy() && !cmp->getOperand(0)->getType()->isFloatingPointTy() &&
        !cmp->getOperand(0)->getType()->isPointerTy())   // rule 21: the integer compare of the addresses
      internalError("spine: a compare of non-scalar operands reached lowerOpcode (rule 3::lowerCompare)", &I);
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
    // Rule 21: ptrtoint and inttoptr to or from another width than 64 are the trunc/zext template.
    if (isa<PtrToIntInst>(ci) || isa<IntToPtrInst>(ci))
      op = rt(ci->getSrcTy(), &I).bits > rt(ci->getDestTy(), &I).bits ? "trunc" : "zext";
    if (!op)
      internalError("spine: a pointer cast reached lowerOpcode (rule 3)", &I);
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

  // dispatch hands lowerOpcode only binary, unary, compare, cast, freeze and intrinsic instructions (every
  // other opcode has its own module there).
  internalError("spine: lowerOpcode of an instruction dispatch routes elsewhere", &I);
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
  // Rule 2's fallback: a load copy a rotation acted on is frozen, never un-copied.
  if (auto *lc = dyn_cast<CallInst>(h); lc && lc->getCalledFunction() &&
                                        lc->getCalledFunction()->getName().starts_with("cqrt_qram_load_"))
    ctx.unc().freezeLoadCopy(id);
  else
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
  if (ctx.S.ctl) {
    // Rule 19, Q13: inside a _ctl clone cq_measure measures a controlled copy under the clone's formal: t is the measured
    // rail, h is not collapsed where the predicate is 0, the outcome is tainted, and no classical collapse applies.
    RailType cw = rt(call.getArgOperand(0)->getType(), &call);
    CallInst *t = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, cw}, {Constant::getNullValue(irTypeOf(ctx.M.getContext(), cw))});
    ctx.unc().recordExternal(t, Role::Measured);
    ctx.emitCore(abi::CoreSpec{abi::Core::Copy, cw, /*ctl=*/true}, {ctx.out().getArg(0), x.v, t});
    CallInst *m = ctx.emitCore(abi::CoreSpec{abi::Core::Measure, cw}, {t});
    m->setMetadata("cq.measure", MDNode::get(ctx.M.getContext(), {}));
    spine::shared(ctx).ctlMeasured.insert(t);
    spine::bindOperand(ctx, &call, Operand{t, true});
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
  // CR rule 2 (ruling 2026-11-02, cq-29ej: collapse is static) with §1.3 (a measured rail is never freed):
  // a value measured on some classical paths only is lowered as unmeasured. Its rail keeps its role and is
  // uncomputed as usual (on a measured path it holds the outcome, where its _unc is exact); the measurement
  // reads a basis copy of it (alloc + copy_<W>, rule 18's partial-measurement copy), which is kept.
  Value *target = x.v;
  bool every = spine::measuredOnEveryPath(ctx, call.getArgOperand(0));
  if (!every) {
    CallInst *c = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
    ctx.unc().recordExternal(c, Role::Measured);
    ctx.emitCore(abi::CoreSpec{abi::Core::Copy, w}, {x.v, c});
    target = c;
  }
  CallInst *m = ctx.emitCore(abi::CoreSpec{abi::Core::Measure, w}, {target});
  // V1 (cq-7p6): a measurement the user wrote carries !cq.measure, the uniqued empty tuple.
  m->setMetadata("cq.measure", MDNode::get(ctx.M.getContext(), {}));
  if (m->getType() != call.getType())
    internalError("spine: cqrt_measure result type differs from cq_measure's", &call);
  if (every)
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

// A rail a bus load made (rule 5 sentence 1).
bool busLoadCopy(LoweringContext &ctx, const Value *y) {
  auto bi = spine::shared(ctx).binds.find(y);
  if (bi == spine::shared(ctx).binds.end() || bi->second.size() != 1 || !bi->second[0].handle)
    return false;
  auto *c = dyn_cast<CallInst>(bi->second[0].v);
  const Function *G = c ? c->getCalledFunction() : nullptr;
  return G && G->getName().starts_with("cqrt_qram_load_");
}

// The old value is a rail the rule may clean: a value this function computed into a rail of its
// own (not an argument, a load, a phi or a classical select over handles, which alias other rails).
bool cleanable(LoweringContext &ctx, Value *y) {
  // Rule 5: a load copy is undone by its un-copy, never by rule 6, whatever re-binds it (an extractvalue, a freeze).
  if (busLoadCopy(ctx, y))
    return false;
  auto &binds = spine::shared(ctx).binds;
  auto bi = binds.find(y);
  if (bi == binds.end() || bi->second.size() != 1)
    return false;
  // Rule 19: a controlled copy a _ctl clone measured is never uncomputed.
  if (spine::shared(ctx).ctlMeasured.count(bi->second[0].v))
    return false;
  auto *I = dyn_cast<Instruction>(y);
  if (!I || isa<PHINode>(I))
    return false;
  // Rule 5: a bus load (an atomic's old value included) is undone by its un-copy, never by rule 6.
  if (isa<LoadInst>(I) || isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I))
    return false;
  if (auto *sel = dyn_cast<SelectInst>(I); sel && !spine::isQ(ctx, sel->getCondition()))
    return false;
  // A field of a clone call's composite result (an extractvalue of the lowered call, U2): the call's
  // result rails are undone together by its twin (rule 18, 166), never one of them by rule 6.
  if (isa<ExtractValueInst>(ctx.operand(y).v))
    return false;
  // A handle that is a classical merge of rails in the new IR (a lane or field of a classical select or
  // phi over handles, cq-oa67) aliases its arms, as the select itself does.
  if (isa<SelectInst>(ctx.operand(y).v) || isa<PHINode>(ctx.operand(y).v))
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

// cq-bdf3 (CR rule 6: an escape is "a call argument the callee KEEPS"): a clone call (rule 18) whose callee
// only reads argument argNo into fresh rails keeps nothing of it; the call is a reader (its group item,
// the twin, reads the argument, so Uncompute places the clean-up after it). Narrow class: a direct call
// lifted to a defined, non-variadic callee with no effect at all, transitively (no memory write, no call
// other than a memory-free intrinsic or another such callee: no rotation, phase, measurement, store or
// host call), passing a scalar integer or fp value whose formal reaches no return, store or call through
// casts, freezes, selects, phis or aggregate moves. Anything else stays an escape.
bool effectFree(const Function &F, SmallPtrSetImpl<const Function *> &seen) {
  if (!seen.insert(&F).second)
    return true;
  for (const Instruction &I : instructions(F)) {
    if (auto *CB = dyn_cast<CallBase>(&I)) {
      const Function *G = CB->getCalledFunction();
      if (!G)
        return false;
      if (G->isIntrinsic()) {
        if (CB->doesNotAccessMemory() || G->getIntrinsicID() == Intrinsic::lifetime_start ||
            G->getIntrinsicID() == Intrinsic::lifetime_end)
          continue;
        return false;
      }
      if (G->isDeclaration() || G->isVarArg() || !effectFree(*G, seen))
        return false;
      continue;
    }
    if (I.mayWriteToMemory() || I.mayThrow())
      return false;
  }
  return true;
}

bool pureCloneReader(LoweringContext &ctx, const CallBase &cb, unsigned argNo) {
  const Function *F = cb.getCalledFunction();
  if (!F || F->isDeclaration() || F->isIntrinsic() || F->isVarArg() || !cb.isArgOperand(&cb.getOperandUse(argNo)) ||
      argNo >= F->arg_size() || F->getFunctionType() != cb.getFunctionType())
    return false;
  Type *ty = cb.getArgOperand(argNo)->getType();
  if (!(ty->isIntegerTy() || ty->isFloatingPointTy()) || cb.paramHasAttr(argNo, Attribute::ByVal))
    return false;
  if (calls::classify(cb, ctx.T, ctx.S) != calls::Class::Lift)
    return false;
  SmallPtrSet<const Function *, 8> seen;
  if (!effectFree(*F, seen))
    return false;
  SmallVector<const Value *, 8> work{F->getArg(argNo)};
  SmallPtrSet<const Value *, 8> vis;
  while (!work.empty()) {
    const Value *v = work.pop_back_val();
    if (!vis.insert(v).second)
      continue;
    for (const User *u : v->users()) {
      if (isa<ReturnInst>(u) || isa<StoreInst>(u) || isa<AtomicRMWInst>(u) || isa<AtomicCmpXchgInst>(u))
        return false;
      if (auto *c = dyn_cast<CallBase>(u)) {
        if (isa<IntrinsicInst>(c) && c->doesNotAccessMemory())
          continue;   // a template over it
        return false;
      }
      if (isa<CastInst>(u) || isa<FreezeInst>(u) || isa<SelectInst>(u) || isa<PHINode>(u) ||
          isa<InsertValueInst>(u) || isa<ExtractValueInst>(u) || isa<InsertElementInst>(u) ||
          isa<ExtractElementInst>(u) || isa<ShuffleVectorInst>(u))
        work.push_back(u);
    }
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
                   ArrayRef<const Instruction *> also = {},
                   SmallVectorImpl<const Instruction *> *dynLoads = nullptr) {
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
      if (!sh.binds.count(ui) && !isa<LoadInst>(w) && laterUpdate(ui, w))
        return false;
      // The header phi of the loop whose rule-6 chain ended on this rail reads it on a back edge no path from `at` takes
      // (109: s + t after both walks cleans t).
      if (isa<PHINode>(ui) && sh.carriedFinal.count(h) && !isPotentiallyReachable(ab, ui->getParent()))
        continue;
      if (isa<ReturnInst>(ui) || isa<PHINode>(ui))
        return false;
      if (isa<StoreInst>(ui))
        return false;   // rule 5: a store's value rail is kept
      if (auto *cb = dyn_cast<CallBase>(ui)) {
        if (isa<IntrinsicInst>(cb) && cb->doesNotAccessMemory())
          continue;   // lowered to a template that reads the rail
        if (pureCloneReader(ctx, *cb, U->getOperandNo()))
          continue;   // cq-bdf3: the callee keeps nothing of it
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
// A value met again at no smaller depth was already walked (cq-fbqi: the walk is over a DAG, unmemoized
// it was exponential on remainderl's chained updates; the depth bound keeps its meaning).
bool reads(LoweringContext &ctx, Value *z, Value *y, unsigned depth, DenseMap<Value *, unsigned> &seen) {
  if (z == y)
    return true;
  auto *I = dyn_cast<Instruction>(z);
  if (!I || depth > 64)
    return false;
  if (auto [it, fresh] = seen.try_emplace(z, depth); !fresh) {
    if (it->second <= depth)
      return false;
    it->second = depth;
  }
  spine::Shared &sh = spine::shared(ctx);
  auto bi = sh.binds.find(z);
  // A skipped zext or an unmaterialized view phi (cq-su3p) reads its operands without a binding.
  bool narrow = sh.narrowSkipped.count(z) || sh.views.count(z);
  if (!narrow && (bi == sh.binds.end() || none_of(bi->second, [](const Operand &o) { return o.handle; })))
    return false;
  for (Value *op : I->operands())
    if (reads(ctx, op, y, depth + 1, seen))
      return true;
  return false;
}
bool reads(LoweringContext &ctx, Value *z, Value *y) {
  DenseMap<Value *, unsigned> seen;
  return reads(ctx, z, y, 0, seen);
}

// Does the rail `h` of the new IR hold a function of the rail `y`? Through the histories of the
// spine's emitters (Shared::hist): a template's operands and the in-place writes on a minted rail.
// Too deep to tell counts as reading.
// A rail met again was already found not to read y (a history is a DAG: its shared operands are walked
// once, cq-fbqi: remainderl's chained bijective updates made the unmemoized walk exponential).
bool railReads(spine::Shared &sh, Value *h, Value *y, unsigned depth, SmallPtrSetImpl<Value *> &seen) {
  if (h == y)
    return true;
  if (depth > 64)
    return true;
  if (!seen.insert(h).second)
    return false;
  auto it = sh.hist.find(h);
  if (it == sh.hist.end())
    return false;
  const spine::RailHist &r = it->second;
  if (r.tmpl)
    for (const Operand &o : r.ops)
      if (o.handle && railReads(sh, o.v, y, depth + 1, seen))
        return true;
  for (const spine::RailHist::Write &w : r.writes)
    for (Value *a : w.args)
      if (a != h && (a == y || sh.hist.count(a)) && railReads(sh, a, y, depth + 1, seen))
        return true;
  return false;
}
bool railReads(spine::Shared &sh, Value *h, Value *y) {
  SmallPtrSet<Value *, 32> seen;
  return railReads(sh, h, y, 0, seen);
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

// The inverse of an odd k modulo 2^W. Newton x <- x (2 - k x) from x = 1 (correct to 1 bit) doubles the
// correct low bits per step, so it iterates until they cover W (cq-hxvx: a fixed 7 steps covered only
// 128 bits).
APInt oddInverse(const APInt &k) {
  unsigned W = k.getBitWidth();
  if (!k[0])
    internalError("spine: oddInverse of an even multiplier");
  APInt x(W, 1);
  for (unsigned bits = 1; bits < W; bits *= 2)
    x = x * (APInt(W, 2) - k * x);
  if (!(k * x).isOne())
    internalError("spine: oddInverse did not converge");
  return x;
}

std::optional<Inverse> inverseStepWith(Instruction &U, Value *Y, Operand yp,
                                       function_ref<Operand(Value *)> operandOf,
                                       function_ref<bool(Value *)> readsY) {
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
      if (readsY(Z))
        return std::nullopt;
      Operand z = operandOf(Z);
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
      spec.op = id == Intrinsic::bswap ? "bswap" : "bitreverse";   // §1.2, f684858
      spec.w = rt(U.getType(), &U);
      return normalized(spec, {yp});                 // an involution
    }
    if ((id == Intrinsic::fshl || id == Intrinsic::fshr) && II->getArgOperand(0) == Y &&
        II->getArgOperand(1) == Y && !readsY(II->getArgOperand(2))) {
      spec.op = id == Intrinsic::fshl ? "fshr" : "fshl";   // a rotation's inverse
      spec.w = rt(U.getType(), &U);
      return normalized(spec, {yp, yp, operandOf(II->getArgOperand(2))});
    }
  }
  return std::nullopt;
}

std::optional<Inverse> inverseOf(LoweringContext &ctx, Instruction &U, Value *Y, Operand yp) {
  return inverseStepWith(
      U, Y, yp, [&](Value *Z) { return ctx.operand(Z); }, [&](Value *Z) { return reads(ctx, Z, Y); });
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
bool ruleFiveGarbageRail(spine::Shared &sh, Value *h) {
  auto it = sh.hist.find(h);
  if (it == sh.hist.end() || !it->second.tmpl || it->second.opaque || sh.rotations.count(h) || sh.measured.count(h))
    return false;
  return none_of(it->second.ops, [&](const Operand &o) { return o.handle && sh.ruleSixCleaned.count(o.v); });
}

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
  // A *.with.overflow intrinsic is its value op here (its value field is the update, rule 4).
  Instruction::BinaryOps opc;
  Value *op0, *op1;
  if (auto *bo = dyn_cast<BinaryOperator>(V); bo && bo->getType()->isIntegerTy(W)) {
    opc = bo->getOpcode();
    op0 = bo->getOperand(0);
    op1 = bo->getOperand(1);
  } else if (auto *ii = dyn_cast<IntrinsicInst>(V); ii && overflowValueOp(ii->getIntrinsicID()) &&
                                                     ii->getArgOperand(0)->getType()->isIntegerTy(W)) {
    StringRef vo = overflowValueOp(ii->getIntrinsicID());
    opc = vo == "add" ? Instruction::Add : vo == "sub" ? Instruction::Sub : Instruction::Mul;
    op0 = ii->getArgOperand(0);
    op1 = ii->getArgOperand(1);
  } else {
    return std::nullopt;
  }
  if (depth > 16)
    return std::nullopt;
  if (opc == Instruction::Add || opc == Instruction::Sub) {
    auto l = affineIn(ctx, op0, X, W, depth + 1);
    auto r = affineIn(ctx, op1, X, W, depth + 1);
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
    auto *k = dyn_cast<ConstantInt>(op1);
    Value *T = op0;
    if (!k && opc == Instruction::Mul) {
      k = dyn_cast<ConstantInt>(op0);
      T = op1;
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
  // inverseStepWith's bijections with two cleanable operands are integer binary ops and the
  // *.with.overflow intrinsics, whose y' is the value field (ruleSixAfter): the update's integer type.
  Type *VT = I.getType();
  if (auto *st = dyn_cast<StructType>(VT))
    VT = st->getElementType(0);
  if (!VT->isIntegerTy())
    internalError("spine: rule 6 composite update of a value that is no integer", &I);
  unsigned W = VT->getIntegerBitWidth();
  std::optional<Affine> f = affineIn(ctx, &I, X, W);
  if (!f)
    return;   // rule 6 lists no other bijection: x is kept
  if (!f->a[0])
    return;   // an even multiplier: no inverse, x is kept
  abi::TemplateSpec spec;
  spec.w = rt(VT, &I);
  SmallVector<Inverse, 4> steps;   // each reads the previous step's rail (yp first)
  if (!f->c.isZero())
    steps.push_back(Inverse{spec, {Operand{}, Operand{ConstantInt::get(VT, f->c), false}}});
  for (auto &[neg, v] : f->rest) {
    steps.push_back(Inverse{spec, {Operand{}, ctx.operand(v)}});
    steps.back().spec.op = neg ? "add" : "sub";
  }
  if (!f->c.isZero())
    steps.front().spec.op = "sub";
  if (!f->a.isOne()) {
    steps.push_back(Inverse{spec, {Operand{}, Operand{ConstantInt::get(VT, oddInverse(f->a)), false}}});
    steps.back().spec.op = "mul";
  }
  if (steps.empty()) {   // y' = x (2x - x): t = y' + 0
    steps.push_back(Inverse{spec, {Operand{}, Operand{ConstantInt::get(VT, 0), false}}});
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
// cq-5nj9, cq-mgkr (CR rule 6, dead on one classical path only; ruling cq-mzqo): a CLASSICAL merge M (a
// select on a classical condition, or a phi whose incoming edges are all classical: a classical choice over
// handles, rule 9) of arms one of which is a bijective update U of a dead y. M's value is U's rail on the
// paths that chose U, so y is dead there after M's readers, and rule 6 cleans it there from U's image under
// a classical branch on "M chose U" at the clean-up point; on the other paths y is the live value (or
// garbage undone as usual). Uncompute places it (cleanupBijectiveUnder) and drops it where U's image is
// itself garbage undone through y. Outside cycles only: a loop's carried and exit values are rule 14's.
// The guard: the new select's condition (or its negation), or an i1 phi beside the new phi, true on the
// edges whose incoming handle is U's rail.
Value *choseArm(LoweringContext &ctx, Instruction &M, Value *armRail) {
  Value *m = ctx.operand(&M).v;
  if (auto *sel = dyn_cast<SelectInst>(m)) {
    if (sel->getTrueValue() == armRail && sel->getFalseValue() != armRail)
      return sel->getCondition();
    if (sel->getFalseValue() == armRail && sel->getTrueValue() != armRail) {
      return ctx.B().CreateNot(sel->getCondition(), "cq.r6.chose");   // where the walker is, after M
    }
    return nullptr;
  }
  auto *np = dyn_cast<PHINode>(m);
  if (!np)
    return nullptr;
  BasicBlock *J = np->getParent();
  if (np->getNumIncomingValues() != unsigned(pred_size(J)))
    internalError("spine: a classical merge phi over handles whose incomings are not all filled at its rule 6", &M);
  LLVMContext &C = ctx.M.getContext();
  PHINode *g = PHINode::Create(Type::getInt1Ty(C), np->getNumIncomingValues(), "cq.r6.chose");
  g->insertInto(J, J->begin());
  bool any = false, all = true;
  for (unsigned k = 0; k < np->getNumIncomingValues(); ++k) {
    bool chose = np->getIncomingValue(k) == armRail;
    any |= chose;
    all &= chose;
    g->addIncoming(ConstantInt::getBool(C, chose), np->getIncomingBlock(k));
  }
  if (!any || all) {
    g->eraseFromParent();
    return nullptr;
  }
  return g;
}

void classicalMergeStop(LoweringContext &ctx, Instruction &M, ArrayRef<Value *> arms) {
  auto onCycle = [](const BasicBlock *b) {
    SmallPtrSet<const BasicBlock *, 16> seen;
    SmallVector<const BasicBlock *, 16> work(succ_begin(b), succ_end(b));
    while (!work.empty()) {
      const BasicBlock *x = work.pop_back_val();
      if (x == b)
        return true;
      if (seen.insert(x).second)
        work.append(succ_begin(x), succ_end(x));
    }
    return false;
  };
  if (onCycle(M.getParent()))
    return;
  SmallVector<Instruction *, 4> updates;
  for (Value *a : arms)
    if (auto *U = dyn_cast<Instruction>(a); U && !is_contained(updates, U)) {
      if (onCycle(U->getParent()))
        return;
      updates.push_back(U);
    }
  // Per old value y: the arms that are bijective updates of a dead y, each with its guard.
  struct Alt { Value *guard; Inverse inv; Value *arm; };
  MapVector<Value *, SmallVector<Alt, 2>> perY;
  for (Instruction *U : updates)
    for (Value *Y : U->operands()) {
      if (!cleanable(ctx, Y))
        continue;
      if (onCycle(cast<Instruction>(Y)->getParent()))
        continue;   // a value made in a loop is the loop's (its reverse undoes it, rule 14)
      Operand img = ctx.operand(U);
      if (!img.handle)
        continue;
      std::optional<Inverse> inv = inverseOf(ctx, *U, Y, img);
      if (!inv)
        continue;
      SmallVector<const Instruction *, 4> also;
      for (const Instruction *V : updates)
        if (V != Y)
          also.push_back(V);
      if (!deadAtCleanup(ctx, Y, ctx.operand(Y).v, &M, also))
        continue;
      Value *guard = choseArm(ctx, M, img.v);
      if (!guard)
        continue;   // U's rail is M on every path (an ordinary update, its own rule 6) or on none
      auto &v = perY[Y];
      if (none_of(v, [&](const Alt &a) { return a.arm == U; }))
        v.push_back({guard, *inv, U});
    }
  for (auto &[Y, alts] : perY) {
    // Every arm an update of y: y is dead on every path, and no plain part remains.
    bool every = all_of(arms, [&, &alts = alts](Value *a) {
      return any_of(alts, [&](const Alt &x) { return x.arm == a; });
    });
    Value *h = ctx.operand(Y).v;
    RailId yid = ctx.unc().idOf(h);
    for (const Alt &a : alts) {
      ctx.unc().cleanupBijectiveUnder(yid, a.guard, a.inv.spec, a.inv.ops, every);
      // The clean-up point follows M and the guard (the clean-up reads both).
      if (auto *gi = dyn_cast<Instruction>(a.guard))
        ctx.unc().noteUse(yid, gi);
    }
    if (auto *mi = dyn_cast<Instruction>(ctx.operand(&M).v))
      ctx.unc().noteUse(yid, mi);
    // Where an arm's image is garbage undone through y (Uncompute drops that alternative), y's bijective
    // image may continue through a later update of M's value: rule 6's composite update (127) per path.
    spine::Shared::MergeSix ms{Y, {}, every};
    for (const Alt &a : alts)
      ms.arms.push_back({a.guard, cast<Instruction>(a.arm)});
    spine::shared(ctx).mergeSix[&M] = std::move(ms);
    spine::shared(ctx).ruleSixCleaned.insert(h);   // no second clean-up of y (a deferred retry, cq-2ql9)
  }
}

void mergeCleanup(LoweringContext &ctx, Instruction &M, ArrayRef<Value *> arms, Operand yp) {
  spine::Shared &sh = spine::shared(ctx);
  if (isa<PHINode>(yp.v)) {
    classicalMergeStop(ctx, M, arms);   // a phi over handles: a classical choice
    return;
  }
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
    if (!spine::isQ(ctx, sel->getCondition())) {
      classicalMergeStop(ctx, I, {sel->getTrueValue(), sel->getFalseValue()});
      return;
    }
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
  auto blockersOf = [&](Value *Y) {
    SmallVector<Value *, 2> out;
    for (User *u : Y->users()) {
      auto *U = dyn_cast<Instruction>(u);
      auto bi = U ? spine::shared(ctx).binds.find(U) : spine::shared(ctx).binds.end();
      if (!U || U == &I || U->getType()->isVoidTy() || bi == spine::shared(ctx).binds.end() ||
          bi->second.size() != 1 || !ctx.operand(U).handle || !ruleFiveGarbage(ctx, U))
        continue;
      if (!deadAfter(ctx, U, &I))
        out.push_back(U);
    }
    return out;
  };
  auto neededLater = [&](Value *Y) { return !blockersOf(Y).empty(); };
  // cq-mgkr (CR rule 6, composite through a classical merge): I = f(M, ...) a bijection in M, M a classical
  // merge of bijective updates of a dead y with nothing else reading M: y is cleaned from I's image, on the
  // path that chose arm U by t = U^-1(f^-1(I)), f^-1(I) a fresh garbage rail (compositeCleanup's inner step).
  for (Value *Z : I.operands()) {
    auto ms = spine::shared(ctx).mergeSix.find(Z);
    if (ms == spine::shared(ctx).mergeSix.end() || !deadAfter(ctx, Z, &I))
      continue;
    std::optional<Inverse> inv = inverseOf(ctx, I, Z, yp);
    if (!inv)
      continue;
    spine::Shared::MergeSix m = ms->second;
    spine::shared(ctx).mergeSix.erase(ms);
    SmallVector<std::pair<Value *, Inverse>, 2> steps;
    Value *t1 = nullptr;
    for (auto &a : m.arms) {
      if (!t1)
        t1 = ctx.emitTemplate(inv->spec, inv->ops);
      std::optional<Inverse> iu = inverseOf(ctx, *a.U, m.Y, Operand{t1, true});
      if (!iu) {
        steps.clear();
        break;
      }
      steps.push_back({a.guard, *iu});
    }
    if (steps.empty())
      continue;
    RailId yid = ctx.unc().idOf(ctx.operand(m.Y).v);
    for (auto &[g, iu] : steps)
      ctx.unc().cleanupBijectiveUnder(yid, g, iu.spec, iu.ops, m.every);
    ctx.unc().noteUse(yid, cast<Instruction>(t1));
    // A merge of the same arms may name y's rail where it chose y itself: that path keeps y (plain part).
    (void)Z;
  }
  SmallVector<Value *, 3> dead;
  DenseMap<Value *, SmallVector<const Instruction *, 2>> dynOf;   // cq-8101
  for (Value *Y : I.operands()) {
    SmallVector<const Instruction *, 2> dl;
    // Rule 6, both operands dead: a load copy beside a rule-5-garbage y: both are garbage, no trigger (198).
    if (cleanable(ctx, Y) && ruleFiveGarbage(ctx, Y) &&
        any_of(I.operands(), [&](const Use &u) { return u.get() != Y && busLoadCopy(ctx, u.get()); }))
      continue;
    if (!is_contained(dead, Y) && cleanable(ctx, Y) && deadAtCleanup(ctx, Y, ctx.operand(Y).v, &I, {}, &dl) &&
        !neededLater(Y)) {
      dead.push_back(Y);
      if (!dl.empty())
        dynOf[Y] = dl;
    }
  }
  // CR rule 6, both operands dead (cq-12cr): when exactly one is garbage rule 5 uncomputes anyway, the
  // other is cleaned (its inverse reads the garbage, whose _unc follows in its usual place); when that
  // garbage was computed from the other, it is uncomputed first and rule 6 asks the composite update.
  // Otherwise operand 0 of the IR instruction is cleaned and the other kept.
  // cq-5nj9: when I's value is only an arm of later quantum merges (a select on a quantum condition or a
  // quantum phi, 125), its rail is garbage those merges' rule 5 uncomputes after them, and a clean-up
  // read from it would be dropped (its item reads y). The merge's own rule 6 (mergeCleanup, the
  // composite update) cleans y; the clean-up from I waits for the merges (ruleSixRetry) and is
  // requested only when they cleaned nothing.
  SmallVector<Value *, 2> merges;
  for (User *u : I.users()) {
    auto *sel = dyn_cast<SelectInst>(u);
    bool arm = (sel && sel->getCondition() != &I && spine::isQ(ctx, sel->getCondition())) ||
               (isa<PHINode>(u) && spine::isQ(ctx, u));
    if (!arm) {
      merges.clear();
      break;
    }
    if (!is_contained(merges, u))
      merges.push_back(u);
  }
  auto cleanOrDefer = [&](Value *Y, const Inverse &inv) {
    auto dl = dynOf.find(Y);
    if (merges.empty() && dl == dynOf.end()) {
      clean(ctx, Y, inv);
      return;
    }
    SmallVector<Value *, 2> bl = blockersOf(Y);
    for (Value *m : merges)
      if (!is_contained(bl, m))
        bl.push_back(m);
    spine::Shared::PendingSix e{&ctx, Y, &I, yp, std::move(bl), {}};
    if (dl != dynOf.end())
      e.loads.assign(dl->second.begin(), dl->second.end());
    spine::shared(ctx).ruleSixPending.push_back(std::move(e));
  };
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
        cleanOrDefer(R, *inv);
        return;
      }
    }
  }
  for (Value *Y : dead)
    if (auto inv = inverseOf(ctx, I, Y, yp)) {
      cleanOrDefer(Y, *inv);
      return;
    }
  // cq-2ql9: an old y held back only by such a garbage rail U (an earlier update of y read after I)
  // waits: once every U is kept (a measurement or a non-diagonal gate made it a register) or has no
  // reader left to lower, rule 6 applies to y against I's image (ruleSixRetry). A U still garbage then
  // is uncomputed by rule 5 before the clean-up, which reads y after it (Uncompute's order).
  spine::Shared &sh = spine::shared(ctx);
  for (Value *Y : I.operands()) {
    if (!cleanable(ctx, Y) || !deadAtCleanup(ctx, Y, ctx.operand(Y).v, &I))
      continue;
    SmallVector<Value *, 2> bl = blockersOf(Y);
    if (bl.empty() || !inverseOf(ctx, I, Y, yp))
      continue;
    sh.ruleSixPending.push_back(spine::Shared::PendingSix{&ctx, Y, &I, yp, std::move(bl), {}});
    return;
  }
}

// cq-2ql9 (CR rule 6: the old value is dead at the CLEAN-UP POINT, and a rail still needed to uncompute
// others is uncomputed first): retry each pending old value whose blockers are settled, after every
// original instruction the walker lowers. A blocker is settled when it is no longer rule-5 garbage
// (measured, rotated) or when every reading use of it is lowered. The old value is then cleaned from
// the image recorded at its update when it is still dead there, uncleaned, unreleased, and every rail
// the inverse reads is still live; otherwise the entry is dropped (the old value stays as it was).
void ruleSixRetry(LoweringContext &ctx) {
  Shared &sh = shared(ctx);
  if (sh.ruleSixPending.empty())
    return;
  // Nothing here asks operand(): after a measurement it answers the classical outcome, recomputed at the
  // builder (rule 2's collapse), which would emit code. The bindings are read instead.
  // The rail an original value was bound to (its template's call), whatever a later measurement made
  // operand() answer.
  auto boundRail = [&](const Value *v) -> Value * {
    auto bi = sh.binds.find(v);
    if (bi == sh.binds.end() || bi->second.size() != 1 || !bi->second.front().handle)
      return nullptr;
    return bi->second.front().v;
  };
  auto settled = [&](Value *U) {
    if (!sh.binds.count(U))
      return false;   // a merge not lowered yet
    Value *r = boundRail(U);
    if (!r || !ruleFiveGarbageRail(sh, r))
      return true;
    SmallVector<const Use *, 8> uses;
    readingUses(sh, U, uses);
    return all_of(uses, [&](const Use *u) {
      auto *ui = dyn_cast<Instruction>(u->getUser());
      return ui && !ui->getType()->isVoidTy() && sh.binds.count(ui);
    });
  };
  auto live = [&](Value *h) { return ctx.unc().liveRole(ctx.unc().idOf(h)).has_value(); };
  // cq-8101: a run-time cell load is settled once it and every reader of its value are lowered and each
  // reader is kept or has no reader left to lower.
  auto readsSettled = [&](const Instruction *ld) {
    if (!sh.binds.count(ld))
      return false;
    SmallVector<const Use *, 8> uses;
    readingUses(sh, ld, uses);
    return all_of(uses, [&](const Use *u) {
      auto *ui = dyn_cast<Instruction>(u->getUser());
      return ui && !ui->getType()->isVoidTy() && boundRail(ui) && settled(ui);
    });
  };
  for (size_t k = 0; k < sh.ruleSixPending.size();) {
    Shared::PendingSix &p = sh.ruleSixPending[k];
    if (p.ctx != &ctx) {
      ++k;
      continue;
    }
    if (!all_of(p.blockers, settled) || !all_of(p.loads, readsSettled)) {
      ++k;
      continue;
    }
    Shared::PendingSix e = std::move(p);
    sh.ruleSixPending.erase(sh.ruleSixPending.begin() + k);
    Value *h = boundRail(e.Y);
    SmallVector<const Instruction *, 2> dl;
    // A rail computed from a measured one may be rule 2's collapse (its value classical, its rail
    // uncomputed at the collapse point): not a rule 6 old value here.
    if (!h || any_of(sh.measured, [&](const auto &m) { return railReads(sh, h, const_cast<Value *>(m.first)); }) ||
        sh.ruleSixCleaned.count(h) || !live(h) || !deadAtCleanup(ctx, e.Y, h, e.I, {}, &dl))
      continue;
    if (any_of(dl, [&](const Instruction *ld) { return !is_contained(e.loads, ld); }))
      internalError("spine: rule 6 retry found a run-time cell load of the old value not seen at its update", e.I);
    // The inverse over the other operands' bindings (their rails as I read them; a measured one still holds
    // its outcome).
    bool unbound = false;
    std::optional<Inverse> inv = inverseStepWith(
        *e.I, e.Y, e.yp,
        [&](Value *Z) -> Operand {
          if (isa<Constant>(Z))
            return Operand{Z, false};
          if (!isQ(ctx, Z))
            return ctx.operand(Z);   // a classical value: no collapse to recompute
          auto bi = sh.binds.find(Z);
          if (bi == sh.binds.end() || bi->second.size() != 1) {
            unbound = true;
            return Operand{Z, false};
          }
          return bi->second.front();
        },
        [&](Value *Z) { return reads(ctx, Z, e.Y); });
    if (!inv || unbound || any_of(inv->ops, [&](const Operand &o) { return o.handle && !live(o.v); }))
      continue;
    RailId yid = ctx.unc().idOf(h);
    for (const Instruction *ld : e.loads) {
      Value *lo = boundRail(ld);
      if (lo == h)
        continue;   // forwarded: the load is the rail's own handle
      if (auto *li = dyn_cast_or_null<Instruction>(lo))
        ctx.unc().noteUse(yid, li);
      SmallVector<const Use *, 8> uses;
      readingUses(sh, ld, uses);
      for (const Use *u : uses) {
        auto *ui = cast<Instruction>(u->getUser());
        if (Value *ur = boundRail(ui); ur && ruleFiveGarbageRail(sh, ur))
          unimplemented("spine: rule 6 on a register read back through a slot cell at a run-time index by a "
                        "computation rule 5 uncomputes (its _unc re-reads the cell after the clean-up; cq-8101)",
                        ui);
        if (auto *uh = dyn_cast_or_null<Instruction>(boundRail(ui)))
          ctx.unc().noteUse(yid, uh);
      }
    }
    clean(ctx, e.Y, *inv);
  }
}


std::optional<InverseStep> inverseStep(Instruction &U, Value *Y, Operand yp, function_ref<Operand(Value *)> operandOf,
                                       function_ref<bool(Value *)> readsY) {
  std::optional<Inverse> inv = inverseStepWith(U, Y, yp, operandOf, readsY);
  if (!inv)
    return std::nullopt;
  return InverseStep{inv->spec, inv->ops};
}

} // namespace spine
// CR rule 2 (ruling 2026-11-02, cq-29ej): collapse is static. A value whose rail is measured on some
// classical paths only is lowered as unmeasured: its rail keeps its role (garbage, uncomputed as usual; on a
// measured path it then holds a basis state, where its _unc is exact). True iff every path of the source
// function from the measured value's definition to a return passes a cq_measure of that value (through
// freeze views). A quantum branch is no choice (its arms all run, rule 2: a measurement in a quantum arm
// is executed unconditionally), so a measurement anywhere in its region up to its post-dominator counts on
// the path through it.
bool spine::measuredOnEveryPath(LoweringContext &ctx, const Value *v, const Instruction *also) {
  auto strip = [](const Value *v) {
    while (auto *f = dyn_cast<FreezeInst>(v))
      v = f->getOperand(0);
    return v;
  };
  const Value *root = strip(v);
  if (!isa<Argument>(root) && !isa<Instruction>(root))
    return true;
  const Function &F = *(also ? also->getFunction()
                             : isa<Argument>(root) ? cast<Argument>(root)->getParent()
                                                   : cast<Instruction>(root)->getFunction());
  SmallPtrSet<const BasicBlock *, 8> mblocks;
  for (const Instruction &I : instructions(F))
    if (auto *c = dyn_cast<CallInst>(&I); c && c->getCalledFunction() &&
                                          c->getCalledFunction()->getName().starts_with("cq_measure") &&
                                          c->arg_size() == 1 && strip(c->getArgOperand(0)) == root)
      mblocks.insert(I.getParent());
  if (also)
    mblocks.insert(also->getParent());
  // A value read from memory names a rail stored before it (rules 20, 21): its paths begin at the entry.
  const auto *defI = isa<LoadInst>(root) || isa<AtomicRMWInst>(root) || isa<AtomicCmpXchgInst>(root) ||
                             (isa<ExtractValueInst>(root) && isa<AtomicCmpXchgInst>(cast<ExtractValueInst>(root)->getAggregateOperand()))
                         ? nullptr
                         : dyn_cast<Instruction>(root);
  const BasicBlock *D = defI ? defI->getParent() : &F.getEntryBlock();
  // A measurement after the definition in its own block covers every path.
  if (mblocks.count(D))
    for (const Instruction *I = defI ? defI->getNextNode() : &D->front(); I; I = I->getNextNode())
      if (auto *c = dyn_cast<CallInst>(I); c && c->getCalledFunction() &&
                                           c->getCalledFunction()->getName().starts_with("cq_measure") &&
                                           c->arg_size() == 1 && strip(c->getArgOperand(0)) == root)
        return true;
  if (also && also->getParent() == D && (!defI || defI->comesBefore(also)))
    return true;
  PostDominatorTree PDT(const_cast<Function &>(F));
  auto quantumBranch = [&](const BasicBlock *b) {
    const Instruction *t = b->getTerminator();
    if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional())
      return ctx.T.isQuantum(br->getCondition(), ctx.S);
    if (auto *sw = dyn_cast<SwitchInst>(t))
      return ctx.T.isQuantum(sw->getCondition(), ctx.S);
    if (auto *ib = dyn_cast<IndirectBrInst>(t))
      return ctx.T.isQuantum(ib->getAddress(), ctx.S);   // rule 13: a switch on the address
    return false;
  };
  // Walk the classical choices from the end of D; a block holding a measurement ends the path (measured);
  // reaching D again starts a new instance (its paths are this walk's); a return reached ends it unmeasured.
  SmallPtrSet<const BasicBlock *, 16> seen;
  SmallVector<const BasicBlock *, 16> work;
  auto push = [&](const BasicBlock *b) {
    if (b != D && seen.insert(b).second)
      work.push_back(b);
  };
  auto next = [&](const BasicBlock *b) -> bool {   // false: an unmeasured return
    if (isa<ReturnInst>(b->getTerminator()))
      return false;
    if (!quantumBranch(b)) {
      for (const BasicBlock *s : successors(b))
        push(s);
      return true;
    }
    // The region of a quantum branch, up to its post-dominator: every block of it runs on this path.
    const BasicBlock *J = PDT.getNode(b) && PDT.getNode(b)->getIDom() ? PDT.getNode(b)->getIDom()->getBlock() : nullptr;
    SmallPtrSet<const BasicBlock *, 16> reg;
    SmallVector<const BasicBlock *, 16> w(succ_begin(b), succ_end(b));
    bool measured = false, ret = false;
    while (!w.empty()) {
      const BasicBlock *x = w.pop_back_val();
      if (x == J || x == b || !reg.insert(x).second)
        continue;
      measured = measured || mblocks.count(x);
      ret = ret || isa<ReturnInst>(x->getTerminator());
      for (const BasicBlock *s : successors(x))
        w.push_back(s);
    }
    if (measured)
      return true;
    if (ret)
      return false;
    if (J)
      push(J);
    return true;
  };
  if (!next(D))
    return false;
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    if (mblocks.count(b))
      continue;
    if (!next(b))
      return false;
  }
  return true;
}


} // namespace cq
