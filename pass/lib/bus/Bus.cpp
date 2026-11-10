// The one bus (CR rules 5, 20, 21; ABI §1.10): the handle, addresses, loads, kept stores, atomics.
#include "BusInternal.h"

#include "cq/Abi.h"
#include "cq/Order.h"
#include "cq/Aggregates.h"
#include "cq/Predicate.h"
#include "../spine/SpineInternal.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/Operator.h"

using namespace llvm;

namespace cq::bus {

namespace {

RailType accessType(LLVMContext &C, Type *T) {
  return railTypeOf(T->isPointerTy() ? Type::getInt64Ty(C) : T);
}

// A classical pointer's address, spelled as rule 20 says: the constant expression for a global, the ptrtoint
// instruction otherwise (one per block is enough; the position is not compared).
Value *classicalAddress(LoweringContext &ctx, Value *p) {
  Type *I64 = Type::getInt64Ty(ctx.M.getContext());
  if (!p->getType()->isPointerTy()) {
    if (!p->getType()->isIntegerTy(64))
      internalError("bus: a classical address that is neither a pointer nor an i64", p);
    return p;
  }
  if (auto *c = dyn_cast<Constant>(p))
    return ConstantExpr::getPtrToInt(c, I64);
  IRBuilder<> &B = ctx.B();
  BasicBlock *bb = B.GetInsertBlock();
  for (User *u : p->users())
    if (auto *pi = dyn_cast<PtrToIntInst>(u);
        pi && pi->getParent() == bb && pi->getType() == I64 &&
        (B.GetInsertPoint() == bb->end() || cq::comesBefore(pi, &*B.GetInsertPoint())))
      return pi;
  return B.CreatePtrToInt(p, I64);
}

// Rule 20 Address arithmetic: the tainted indices brought to i64, scaled, added per getelementptr; everything
// untainted is one classical i64, the _hl literal.
Operand gepAddress(LoweringContext &ctx, const GEPOperator &G) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  Type *I64 = Type::getInt64Ty(C);
  RailType w64{Kind::Int, 64};
  IRBuilder<> &B = ctx.B();
  Operand base = address(ctx, G.getPointerOperand());
  uint64_t constant = 0;
  Value *classical = base.handle ? nullptr : base.v;
  Value *rail = nullptr;
  auto addRail = [&](Value *r) {
    if (!rail) {
      rail = r;
      return;
    }
    abi::TemplateSpec add;
    add.op = "add";
    add.w = w64;
    rail = ctx.emitTemplate(add, {Operand{rail, true}, Operand{r, true}});
  };
  auto addClassical = [&](Value *v) { classical = classical ? B.CreateAdd(classical, v) : v; };
  for (gep_type_iterator I = gep_type_begin(G), E = gep_type_end(G); I != E; ++I) {
    const Value *idx = I.getOperand();
    if (StructType *st = I.getStructTypeOrNull()) {
      constant += DL.getStructLayout(st)->getElementOffset(cast<ConstantInt>(idx)->getZExtValue());
      continue;
    }
    uint64_t size = I.getSequentialElementStride(DL).getFixedValue();
    if (auto *ci = dyn_cast<ConstantInt>(idx)) {
      constant += size * ci->getValue().sextOrTrunc(64).getZExtValue();
      continue;
    }
    Operand ix = ctx.operand(idx);
    if (!ix.handle) {
      Value *v = B.CreateSExtOrTrunc(ix.v, I64);
      addClassical(size == 1 ? v : B.CreateMul(v, ConstantInt::get(I64, size)));
      continue;
    }
    Value *r = ix.v;
    RailType w = railTypeOf(idx->getType());
    if (w.bits != 64) {
      abi::TemplateSpec cast;
      cast.op = w.bits < 64 ? "sext" : "trunc";
      cast.w = w;
      cast.to = w64;
      r = ctx.emitTemplate(cast, {Operand{r, true}});
    }
    if (size != 1) {
      abi::TemplateSpec mul;
      mul.op = "mul";
      mul.w = w64;
      mul.shape = "hl";
      r = ctx.emitTemplate(mul, {Operand{r, true}, Operand{ConstantInt::get(I64, size), false}});
    }
    addRail(r);
  }
  if (constant)
    addClassical(ConstantInt::get(I64, constant));
  if (base.handle) {
    if (rail) {
      abi::TemplateSpec add;
      add.op = "add";
      add.w = w64;
      rail = ctx.emitTemplate(add, {base, Operand{rail, true}});
    } else {
      rail = base.v;
    }
  }
  if (!rail)
    return Operand{classical ? classical : ConstantInt::get(I64, 0), false};
  if (!classical)
    return Operand{rail, true};
  if (auto *k = dyn_cast<ConstantInt>(classical); k && k->isZero())
    return Operand{rail, true};
  abi::TemplateSpec add;
  add.op = "add";
  add.w = w64;
  add.shape = "hl";
  return Operand{ctx.emitTemplate(add, {Operand{rail, true}, Operand{classical, false}}), true};
}

} // namespace

Value *mem(LoweringContext &ctx) {
  BasicBlock &E = ctx.out().getEntryBlock();
  for (Instruction &I : E)
    if (auto *c = dyn_cast<CallInst>(&I); c && c->getCalledFunction() && c->getCalledFunction()->getName() == "__cq_mem")
      return c;
  IRBuilder<> B(&E, E.getFirstInsertionPt());
  return B.CreateCall(abi::declareHost(ctx.M, abi::Host::Mem));
}

Operand address(LoweringContext &ctx, const Value *p) {
  if (ctx.bound(p)) {
    Operand o = ctx.operand(p);
    return o.handle ? o : Operand{classicalAddress(ctx, o.v), false};
  }
  if (auto *G = dyn_cast<GEPOperator>(p))
    return gepAddress(ctx, *G);
  if (auto *AC = dyn_cast<AddrSpaceCastOperator>(p))
    return address(ctx, AC->getPointerOperand());
  internalError("bus: the address of a pointer with no value in the new IR", p);
}

Value *accessControl(LoweringContext &ctx) {
  Value *f = ctx.currentFlag();
  return !f && ctx.S.ctl ? ctx.out().getArg(0) : f;
}

void scalarLeaves(const DataLayout &DL, Type *T, uint64_t offset, SmallVectorImpl<Leaf> &out) {
  if (auto *st = dyn_cast<StructType>(T)) {
    const StructLayout *SL = DL.getStructLayout(st);
    for (unsigned i = 0; i < st->getNumElements(); ++i)
      scalarLeaves(DL, st->getElementType(i), offset + SL->getElementOffset(i), out);
    return;
  }
  if (auto *at = dyn_cast<ArrayType>(T)) {
    uint64_t size = DL.getTypeAllocSize(at->getElementType());
    for (uint64_t i = 0; i < at->getNumElements(); ++i)
      scalarLeaves(DL, at->getElementType(), offset + i * size, out);
    return;
  }
  if (auto *vt = dyn_cast<FixedVectorType>(T)) {
    uint64_t size = DL.getTypeStoreSize(vt->getElementType());
    for (unsigned i = 0; i < vt->getNumElements(); ++i)
      out.push_back({vt->getElementType(), offset + i * size});
    return;
  }
  out.push_back({T, offset});
}

Operand offsetAddress(LoweringContext &ctx, Operand addr, uint64_t off) {
  if (!off)
    return addr;
  Value *k = ConstantInt::get(Type::getInt64Ty(ctx.M.getContext()), off);
  if (!addr.handle)
    return Operand{ctx.B().CreateAdd(addr.v, k), false};
  abi::TemplateSpec add;
  add.op = "add";
  add.w = RailType{Kind::Int, 64};
  add.shape = "hl";
  return Operand{ctx.emitTemplate(add, {addr, Operand{k, false}}), true};
}

CallInst *emitLoad(LoweringContext &ctx, Type *T, Operand addr, bool unguarded) {
  Value *m = mem(ctx);
  Value *c = unguarded ? nullptr : accessControl(ctx);
  abi::CoreSpec spec{abi::Core::QramLoad, accessType(ctx.M.getContext(), T), /*ctl=*/c != nullptr, /*hl=*/!addr.handle};
  SmallVector<Value *, 3> args;
  SmallVector<Operand, 3> ops;
  if (c) {
    args.push_back(c);
    ops.push_back(Operand{c, true});
  }
  args.append({m, addr.v});
  ops.append({Operand{m, false}, addr});
  CallInst *call = ctx.emitCore(spec, args);
  ctx.unc().recordBusLoad(call, ops);
  return call;
}

Value *keptControl(LoweringContext &ctx, Value *c, Value *value) {
  if (!c)
    return nullptr;
  if (c == spine::shared(ctx).tripZeroRail)
    return c;   // rule 14: a_0 of a re-rolled loop's chain, not an arm's false edge (91)
  Value *g = ctx.unc().negatedAtomOf(c);
  if (!g)
    return c;
  if (g == value) {
    noteUnbuilt("bus: a kept store of the i1 flag under its own false edge: no X bracket can read it as the value");
    return c;
  }
  return g;
}

void emitKeptStore(LoweringContext &ctx, Type *T, Operand addr, Operand value) {
  LLVMContext &C = ctx.M.getContext();
  RailType w = accessType(C, T);
  Value *v = value.v;
  if (!value.handle) {
    Value *lit = spine::codeAddressAsInt(ctx.B(), v, irTypeOf(C, w));
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {lit});
    ctx.unc().recordSeed(seed);
    v = seed;
  }
  Value *m = mem(ctx);
  // Rule 8: the false edge is an X bracket on the flag, which rule 5 keeps with the store (95). The flag is the atom's
  // rail itself; under a trip, the rail the trip rail negates (cq-5aus, 55).
  Value *neg = nullptr;
  const Pred &q = ctx.currentPredicate();
  if (!spine::shared(ctx).tripFlag && !q.isTop())
    neg = ctx.preds().negatedAtomRail(ctx, q);
  if (neg == v)
    neg = nullptr;   // keptControl says so: no bracket can read the flag as the store's value
  Value *c = neg;
  if (!c) {
    Value *flag = accessControl(ctx);
    c = keptControl(ctx, flag, v);
    if (c != flag)
      neg = c;
  }
  abi::CoreSpec spec{abi::Core::QramStore, w, /*ctl=*/c != nullptr, /*hl=*/!addr.handle};
  SmallVector<Value *, 4> args;
  if (c)
    args.push_back(c);
  args.append({m, addr.v, v});
  abi::CoreSpec x{abi::Core::NotI1, RailType{Kind::Int, 1}};
  if (neg)
    ctx.emitCore(x, {neg});
  CallInst *call = ctx.emitCore(spec, args);
  if (neg) {
    CallInst *close = ctx.emitCore(x, {neg});
    if (addr.handle)
      ctx.unc().noteUse(ctx.unc().idOf(addr.v), close);   // the address's item may read the flag: never inside the bracket
  }
  ctx.unc().noteKeptStore(call, v, c);
  ctx.unc().noteVersionChange(call);
}

void lowerLoad(LoweringContext &ctx, LoadInst &L, bool unguarded) {
  if (isBoolCellLoad(ctx, L))
    return lowerBoolCellLoad(ctx, L);
  const DataLayout &DL = ctx.M.getDataLayout();
  Type *T = L.getType();
  Operand addr = address(ctx, L.getPointerOperand());
  if (!T->isAggregateType() && !T->isVectorTy()) {
    spine::bindOperand(ctx, &L, Operand{emitLoad(ctx, T, addr, unguarded), true});
    return;
  }
  SmallVector<Leaf, 4> leaves;
  scalarLeaves(DL, T, 0, leaves);
  SmallVector<Operand, 4> fields;
  for (const Leaf &f : leaves)
    fields.push_back(Operand{emitLoad(ctx, f.type, offsetAddress(ctx, addr, f.offset), unguarded), true});
  ctx.bindFields(&L, fields);
}

void lowerStore(LoweringContext &ctx, StoreInst &S) {
  if (isInPlaceForm(ctx, S))
    return lowerInPlace(ctx, S);
  const DataLayout &DL = ctx.M.getDataLayout();
  Value *V = S.getValueOperand();
  Type *T = V->getType();
  Operand addr = address(ctx, S.getPointerOperand());
  if (!T->isAggregateType() && !T->isVectorTy())
    return emitKeptStore(ctx, T, addr, ctx.operand(V));
  SmallVector<Leaf, 4> leaves;
  scalarLeaves(DL, T, 0, leaves);
  SmallVector<Operand, 4> fields = aggr::flattenResult(ctx, V);
  if (fields.size() != leaves.size())
    noteUnbuilt("bus: a store of an aggregate whose fields are not its scalar leaves (stores the common prefix)", &S);
  for (unsigned i = 0, e = std::min(leaves.size(), fields.size()); i < e; ++i)
    emitKeptStore(ctx, leaves[i].type, offsetAddress(ctx, addr, leaves[i].offset), fields[i]);
}

// Rule 4: a bus load, the compare and select (or the operation's) templates, a bus store, by rule 5 as if written.
// The operation is the plain opcode: the template is built through the same operand conventions as lowerOpcode's.
void lowerAtomic(LoweringContext &ctx, Instruction &I) {
  LLVMContext &C = ctx.M.getContext();
  auto hl = [&](const char *op, RailType w, Operand a, Operand b) -> Value * {
    abi::TemplateSpec s;
    s.op = op;
    s.w = w;
    if (!a.handle && b.handle)
      std::swap(a, b);
    s.shape = b.handle ? "" : "hl";
    return ctx.emitTemplate(s, {a, b});
  };
  if (auto *X = dyn_cast<AtomicCmpXchgInst>(&I)) {
    Type *T = X->getCompareOperand()->getType();
    RailType w = accessType(C, T);
    Operand addr = address(ctx, X->getPointerOperand());
    CallInst *old = emitLoad(ctx, T, addr);
    Operand cmp = ctx.operand(X->getCompareOperand()), nv = ctx.operand(X->getNewValOperand());
    abi::TemplateSpec eq;
    eq.op = "icmp";
    eq.pred = "eq";
    eq.w = w;
    eq.shape = cmp.handle ? "" : "hl";
    Value *ok = ctx.emitTemplate(eq, {Operand{old, true}, cmp});
    abi::TemplateSpec sel;
    sel.op = "select";
    sel.w = w;
    sel.shape = nv.handle ? "" : "lh";
    Value *res = ctx.emitTemplate(sel, {Operand{ok, true}, nv, Operand{old, true}});
    emitKeptStore(ctx, T, addr, Operand{res, true});
    ctx.bindFields(X, {Operand{old, true}, Operand{ok, true}});
    return;
  }
  auto *R = dyn_cast<AtomicRMWInst>(&I);
  if (!R)
    internalError("bus: lowerAtomic of an instruction that is neither cmpxchg nor atomicrmw", &I);
  using Op = AtomicRMWInst::BinOp;
  Op op = R->getOperation();
  if (op == Op::Add || op == Op::Sub || op == Op::Xor)
    return lowerInPlaceRMW(ctx, *R);
  Type *T = R->getValOperand()->getType();
  RailType w = accessType(C, T);
  Operand addr = address(ctx, R->getPointerOperand());
  CallInst *old = emitLoad(ctx, T, addr);
  Operand val = ctx.operand(R->getValOperand());
  Operand oldOp{old, true};
  Value *res;
  switch (op) {
  case Op::Xchg:
    emitKeptStore(ctx, T, addr, val);
    spine::bindOperand(ctx, R, oldOp);
    return;
  case Op::And: res = hl("and", w, oldOp, val); break;
  case Op::Or: res = hl("or", w, oldOp, val); break;
  case Op::Nand: {
    Value *a = hl("and", w, oldOp, val);
    res = hl("xor", w, Operand{a, true}, Operand{Constant::getAllOnesValue(T), false});
    break;
  }
  case Op::Max: res = hl("smax", w, oldOp, val); break;
  case Op::Min: res = hl("smin", w, oldOp, val); break;
  case Op::UMax: res = hl("umax", w, oldOp, val); break;
  case Op::UMin: res = hl("umin", w, oldOp, val); break;
  case Op::FAdd: res = hl("fadd", w, oldOp, val); break;
  case Op::FSub: {
    abi::TemplateSpec s;
    s.op = "fsub";
    s.w = w;
    s.shape = val.handle ? "" : "hl";
    res = ctx.emitTemplate(s, {oldOp, val});
    break;
  }
  case Op::FMax: res = hl("fmax", w, oldOp, val); break;
  case Op::FMin: res = hl("fmin", w, oldOp, val); break;
  default:
    report_fatal_error("cq: unimplemented: bus: an atomicrmw operation clang 19 does not emit for C",
                       /*gen_crash_diag=*/false);
  }
  emitKeptStore(ctx, T, addr, Operand{res, true});
  spine::bindOperand(ctx, R, oldOp);
}

} // namespace cq::bus
