// Allocation (CR rule 16 Allocation and Deallocation, rule 20 Allocation, §0 K2; ABI §1.10): every bus-resident alloca
// and every malloc-family call is `ptr @__cq_alloc(i64 size, i64 align)`, classical host code, executed unguarded.
#include "BusInternal.h"

#include "cq/Abi.h"
#include "cq/Loops.h"
#include "../spine/SpineInternal.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Support/KnownBits.h"
#include "llvm/Support/MathExtras.h"

using namespace llvm;

namespace cq::bus {

namespace {

Type *i64Ty(LoweringContext &ctx) { return Type::getInt64Ty(ctx.M.getContext()); }

Value *lit(LoweringContext &ctx, uint64_t v) { return ConstantInt::get(i64Ty(ctx), v); }

// A size or alignment operand brought to i64. A rail narrower than 64 bits goes through the zext template.
Operand asI64(LoweringContext &ctx, const Value *orig) {
  Operand o = ctx.operand(orig);
  unsigned bits = orig->getType()->getIntegerBitWidth();
  if (bits == 64)
    return o;
  if (!o.handle)
    return Operand{ctx.B().CreateZExtOrTrunc(o.v, i64Ty(ctx)), false};
  abi::TemplateSpec z;
  if (bits > 64)
    noteUnbuilt("bus: an allocation size wider than 64 bits (truncated to i64)", orig);
  z.op = bits > 64 ? "trunc" : "zext";
  z.w = RailType{Kind::Int, bits};
  z.to = RailType{Kind::Int, 64};
  return Operand{ctx.emitTemplate(z, {o}), true};
}

std::optional<uint64_t> mulBound(std::optional<uint64_t> a, std::optional<uint64_t> b) {
  if (!a || !b)
    return std::nullopt;
  bool overflow = false;
  uint64_t r = SaturatingMultiply(*a, *b, &overflow);
  if (overflow)
    return std::nullopt;
  return r;
}

// a * b, each a rail or classical; the bound of the product when both have one.
Operand mulSize(LoweringContext &ctx, Operand a, Operand b) {
  if (!a.handle && !b.handle)
    return Operand{ctx.B().CreateMul(a.v, b.v), false};
  if (!a.handle)
    std::swap(a, b);
  if (auto *k = dyn_cast<ConstantInt>(b.v); k && !b.handle && k->isOne())
    return a;
  abi::TemplateSpec m;
  m.op = "mul";
  m.w = RailType{Kind::Int, 64};
  m.shape = b.handle ? "" : "hl";
  return Operand{ctx.emitTemplate(m, {a, b}), true};
}

// The size operand of one __cq_alloc: a classical size is itself; a rail is K2 bytes, and `n > K2` is the kept overflow
// predicate unless range facts bound n by K2 (rule 16), computed immediately before the call.
Value *sizeOperand(LoweringContext &ctx, Operand n, std::optional<uint64_t> bound) {
  if (!n.handle)
    return n.v;
  uint64_t k2 = K2(ctx);
  if (!bound || *bound > k2) {
    abi::TemplateSpec gt;
    gt.op = "icmp";
    gt.pred = "ugt";
    gt.w = RailType{Kind::Int, 64};
    gt.shape = "hl";
    Value *o = ctx.emitTemplate(gt, {n, Operand{lit(ctx, k2), false}});
    ctx.unc().setRole(ctx.unc().idOf(o), Role::KeptOverflow);
  }
  return lit(ctx, k2);
}

CallInst *emitAlloc(LoweringContext &ctx, Value *size, Value *align) {
  CallInst *p = ctx.B().CreateCall(abi::declareHost(ctx.M, abi::Host::Alloc), {size, align});
  ctx.unc().noteVersionChange(p);
  return p;
}

// aligned_alloc(a, n): a rail alignment is K2 rounded up to a power of two (rule 16).
Value *alignOperand(LoweringContext &ctx, const Value *orig) {
  Operand a = asI64(ctx, orig);
  return a.handle ? lit(ctx, PowerOf2Ceil(K2(ctx))) : a.v;
}

// The size in bytes the call names, and the alignment; rule 16 by name, else the declaration's allocsize / allocalign.
struct AllocShape {
  Operand size;
  std::optional<uint64_t> bound;
  Value *align;
};

AllocShape callShape(LoweringContext &ctx, CallBase &CB) {
  const Function *F = CB.getCalledFunction();
  if (!F)
    internalError("bus: lowerAlloc of an indirect call", &CB);
  StringRef n = F->getName();
  auto single = [&](const Value *v) { return AllocShape{asI64(ctx, v), rangeBound(ctx, v), nullptr}; };
  auto product = [&](const Value *a, const Value *b) {
    Operand x = asI64(ctx, a), y = asI64(ctx, b);
    return AllocShape{mulSize(ctx, x, y), mulBound(rangeBound(ctx, a), rangeBound(ctx, b)), nullptr};
  };
  AllocShape s;
  if (n == "malloc") {
    s = single(CB.getArgOperand(0));
  } else if (n == "aligned_alloc") {
    s = single(CB.getArgOperand(1));
    s.align = alignOperand(ctx, CB.getArgOperand(0));
  } else {
    Attribute A = F->getFnAttribute(Attribute::AllocSize);
    if (!A.isValid()) {
      noteUnbuilt((Twine("bus: an allockind callee with no allocsize, size taken as argument 0: ") + n).str(), &CB);
      s = single(CB.getArgOperand(0));
      if (const Value *al = CB.getArgOperandWithAttribute(Attribute::AllocAlign))
        s.align = alignOperand(ctx, al);
      if (!s.align)
        s.align = lit(ctx, 16);
      return s;
    }
    auto [e, c] = A.getAllocSizeArgs();
    s = c ? product(CB.getArgOperand(e), CB.getArgOperand(*c)) : single(CB.getArgOperand(e));
    if (const Value *al = CB.getArgOperandWithAttribute(Attribute::AllocAlign))
      s.align = alignOperand(ctx, al);
  }
  if (!s.align)
    s.align = lit(ctx, 16);   // rule 16: alignment 16 where the call names none
  return s;
}

AllocShape allocaShape(LoweringContext &ctx, AllocaInst &A) {
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t elem = DL.getTypeAllocSize(A.getAllocatedType()).getFixedValue();
  AllocShape s;
  s.align = lit(ctx, A.getAlign().value());
  const Value *count = A.getArraySize();
  if (auto *c = dyn_cast<ConstantInt>(count)) {
    s.size = Operand{lit(ctx, elem * c->getZExtValue()), false};
    return s;
  }
  s.size = mulSize(ctx, asI64(ctx, count), Operand{lit(ctx, elem), false});
  s.bound = mulBound(rangeBound(ctx, count), elem);
  return s;
}

// calloc(n, s) (rule 16; owner 2026-11-12, cq-mrdkr): the size is the EXACT product, never the wrapped one. Classical
// operands: an overflowing product is the null pointer and no __cq_alloc call (a classical test, as C's calloc), folded
// for constants. A rail operand: K2 bytes, the size umul.with.overflow's two templates, and the kept predicate
// or_i1(overflow, n*s > K2) into a fresh rail, the overflow bit and the compare undone at once (omitted when range facts
// bound n*s by K2), computed immediately before the __cq_alloc call.
void lowerCalloc(LoweringContext &ctx, CallBase &CB) {
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  const Value *origN = CB.getArgOperand(0), *origS = CB.getArgOperand(1);
  Operand x = asI64(ctx, origN), y = asI64(ctx, origS);
  Value *align = lit(ctx, 16);
  if (!x.handle && !y.handle) {
    auto *kx = dyn_cast<ConstantInt>(x.v), *ky = dyn_cast<ConstantInt>(y.v);
    if (kx && ky) {
      bool overflow = false;
      (void)kx->getValue().umul_ov(ky->getValue(), overflow);
      Value *r = overflow ? static_cast<Value *>(ConstantPointerNull::get(PointerType::getUnqual(C)))
                          : emitAlloc(ctx, B.CreateMul(x.v, y.v), align);
      spine::bindOperand(ctx, &CB, Operand{r, false});
      return;
    }
    CallInst *mo = B.CreateCall(Intrinsic::getDeclaration(&ctx.M, Intrinsic::umul_with_overflow, {i64Ty(ctx)}), {x.v, y.v});
    ctx.unc().noteVersionChange(mo);   // on both paths: nothing the change orders is placed in an arm
    Value *size = B.CreateExtractValue(mo, {0u}), *ovf = B.CreateExtractValue(mo, {1u});
    BasicBlock *pre = B.GetInsertBlock();
    BasicBlock *Do = BasicBlock::Create(C, "", &ctx.out()), *Join = BasicBlock::Create(C, "", &ctx.out());
    B.CreateCondBr(ovf, Join, Do);
    B.SetInsertPoint(Do);
    CallInst *q = B.CreateCall(abi::declareHost(ctx.M, abi::Host::Alloc), {size, align});
    B.CreateBr(Join);
    B.SetInsertPoint(Join);
    PHINode *r = B.CreatePHI(q->getType(), 2);
    r->addIncoming(ConstantPointerNull::get(cast<PointerType>(q->getType())), pre);
    r->addIncoming(q, Do);
    spine::bindOperand(ctx, &CB, Operand{r, false});
    return;
  }
  Operand m = mulSize(ctx, x, y);
  std::optional<uint64_t> bound = mulBound(rangeBound(ctx, origN), rangeBound(ctx, origS));
  uint64_t k2 = K2(ctx);
  if (!bound || *bound > k2) {
    if (!x.handle)
      std::swap(x, y);
    abi::TemplateSpec ov;
    ov.op = "umul_overflow";
    ov.w = RailType{Kind::Int, 64};
    ov.shape = y.handle ? "" : "hl";
    CallInst *o = rawTemplate(ctx, ov, {x.v, y.v});
    abi::TemplateSpec gt;
    gt.op = "icmp";
    gt.pred = "ugt";
    gt.w = RailType{Kind::Int, 64};
    gt.shape = "hl";
    CallInst *g = rawTemplate(ctx, gt, {m.v, lit(ctx, k2)});
    CallInst *k = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}}, {ConstantInt::getFalse(C)});
    ctx.unc().recordExternal(k, Role::KeptOverflow);
    ctx.emitCore(abi::CoreSpec{abi::Core::OrI1}, {o, g, k});
    undoRaw(ctx, gt, g);
    undoRaw(ctx, ov, o);
  }
  spine::bindOperand(ctx, &CB, Operand{emitAlloc(ctx, lit(ctx, k2), align), false});
}

} // namespace

std::optional<uint64_t> rangeBound(LoweringContext &ctx, const Value *V) {
  if (!V->getType()->isIntegerTy())
    return std::nullopt;
  ConstantRange R = computeConstantRange(V, /*ForSigned=*/false, /*UseInstrInfo=*/true);
  // The known bits too: `zext nneg (x & 3)` is a cast computeConstantRange does not look through.
  R = R.intersectWith(ConstantRange::fromKnownBits(computeKnownBits(V, ctx.M.getDataLayout()), /*IsSigned=*/false),
                      ConstantRange::Unsigned);
  if (R.isFullSet() || R.isWrappedSet())
    return std::nullopt;
  APInt hi = R.getUnsignedMax();
  if (hi.isMaxValue() || hi.getActiveBits() > 64)
    return std::nullopt;
  return hi.getZExtValue();
}

unsigned K2(const LoweringContext &cctx) {
  LoweringContext &ctx = const_cast<LoweringContext &>(cctx);
  const Function &F = *ctx.S.F;
  const loops::KOptions &KO = spine::shared(ctx).KO;
  if (auto it = KO.k2PerFunction.find(F.getName().str()); it != KO.k2PerFunction.end() && it->second > 0)
    return it->second;
  if (const GlobalVariable *GV = F.getParent()->getGlobalVariable(("__cq_k2_" + F.getName()).str(), true))
    if (GV->hasInitializer())
      if (auto *CI = dyn_cast<ConstantInt>(GV->getInitializer()); CI && CI->getZExtValue() > 0)
        return unsigned(CI->getZExtValue());
  if (KO.k2Global && *KO.k2Global > 0)
    return *KO.k2Global;
  return 4096;
}

void lowerAlloc(LoweringContext &ctx, Instruction &site) {
  AllocShape s;
  if (auto *A = dyn_cast<AllocaInst>(&site))
    s = allocaShape(ctx, *A);
  else if (auto *CB = dyn_cast<CallBase>(&site)) {
    if (const Function *F = CB->getCalledFunction(); F && F->getName() == "calloc")
      return lowerCalloc(ctx, *CB);
    s = callShape(ctx, *CB);
  }
  else
    internalError("bus: lowerAlloc of an instruction that allocates nothing", &site);
  spine::bindOperand(ctx, &site, Operand{emitAlloc(ctx, sizeOperand(ctx, s.size, s.bound), s.align), false});
}

// Rule 16: q = __cq_alloc(n, 16); s = the i64 bus load at p - 8; the rail umin(s, n); a rule-22 quantum-length copy p -> q
// whose trip bound is the new block's size, with no overflow predicate of its own; nothing for p.
void lowerRealloc(LoweringContext &ctx, CallBase &CB) {
  const Value *origP = CB.getArgOperand(0), *origN = CB.getArgOperand(1);
  Operand n = asI64(ctx, origN);
  Value *blockSize = sizeOperand(ctx, n, rangeBound(ctx, origN));
  CallInst *q = emitAlloc(ctx, blockSize, lit(ctx, 16));
  spine::bindOperand(ctx, &CB, Operand{q, false});
  Operand p = address(ctx, origP);
  Operand dst{ctx.B().CreatePtrToInt(q, i64Ty(ctx)), false};
  Type *I64 = i64Ty(ctx);
  Operand header = offsetAddress(ctx, p, uint64_t(-8));
  Operand old{emitLoad(ctx, I64, header), true};
  abi::TemplateSpec um;
  um.op = "umin";
  um.w = RailType{Kind::Int, 64};
  um.shape = n.handle ? "" : "hl";
  Value *len = ctx.emitTemplate(um, {old, n});
  CopySpec spec;
  spec.dst = dst;
  spec.src = p;
  spec.length = Operand{len, true};
  spec.trips = blockSize;
  spec.ctl = accessControl(ctx);
  spec.at = &CB;
  emitCopy(ctx, spec);
}

} // namespace cq::bus
