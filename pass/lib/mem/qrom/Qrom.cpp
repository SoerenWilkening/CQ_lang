// Module mem-qrom (cq-w1-mem-qrom): QROM reads of classical memory, CR rule 20.
//
// A load at a quantum offset of an object that never holds a handle (the dispatcher routes it here
// after the fat-pointer, QRAM and slot cases) is ONE call
//   cq_template_qrom_load_<W>(ptr base, i64 n, idx)            element i at base + i * size
//   cq_template_qrom_load_<W>_s(ptr base, i64 n, i64 stride, idx)   element i at base + i * stride
// (CR §1.2, BACKEND_ABI §2.11; size = the loaded type's alloc size, f80: 16). The result is a fresh
// rail bound to the load, recorded with Uncompute like every template: its _unc takes the same
// operands (the backend embeds the contents read at the forward call; rule 20). The circuit is the
// backend's (Bennett.jl src/qrom.jl:emit_qrom!, unary iteration over the n entries).
//
// CONTRACT (what the construction reads off the original IR)
//
//  - Address. The pointer is decomposed through GEPs and bitcasts into
//      root + off + sum_k idx_k * stride_k        (bytes; off a constant, root a classical pointer)
//    whose variable terms are all quantum. A classical variable term next to a quantum one, a quantum
//    root, a negative or non-constant byte offset, a cell stride u = gcd_k(stride_k) below the element
//    size (a bit view) are unimplemented.
//  - Index operand: the logical index rail (rule 20). Each GEP index is stripped of the zext (any)
//    and of a sext whose operand is known non-negative or that indexes a known object from its start
//    (a negative index there is outside the object: undefined, outside the domain). The `zext`,
//    `sext` and GEP scaling are address arithmetic. One term: the rail is the stripped value's rail,
//    at its own width. Several (a 2-D table, 120; a 2-D array of structs): the flattened cell index
//    sum_k (stride_k / u) * idx_k in fresh rails (linearIndex: widen, shl_hl / mul_hl, add, row before
//    column), at the widest index's width raised to hold the largest in-domain cell index. A sext of a
//    possibly negative index into memory of unknown extent (t[i], i < 0, is legal C) is unimplemented:
//    the unsigned QROM index would read 0 there.
//  - Form. u == size: the plain form over base = root + off. Otherwise the strided form (stride u) over
//    base = root + off (the field of a struct-of-arrays column, 78). base is root itself when off is
//    0, else one classical `getelementptr inbounds i8, root, off`.
//  - Length n (rule 20: the cell count when known, else the index's upper bound from range facts,
//    else 2^W of the index):
//      * root a global with a sized value type, or a static alloca: bytes = its alloc size;
//        n = (bytes - off - size) / u + 1 cells (0 when the first cell does not fit);
//      * root a dynamic alloca (VLA, 74) whose allocated type is a whole number E / u of cells and
//        off + size <= u: n = its element count operand, zext to i64, times E / u. Any other dynamic
//        alloca is unimplemented;
//      * anything else (a parameter, a loaded pointer, a heap block, a global of unsized or zero
//        size): an index `urem a, d` with d classical gives n = zext(d) (76); otherwise
//        n = umin(computeConstantRange, computeKnownBits) upper bound + 1 of the stripped index
//        (2^W when neither proves anything); several terms: sum_k (stride_k / u) * umax_k + 1. A bound of
//        2^64 or more is unimplemented.
//  - Result type: an integer or floating-point load (railTypeOf), or a pointer (rule 19, 97): a function
//    pointer read at a quantum index from a constant global with a known initializer is a QROM of
//    callee tags over the derived constant table <global>.cqtag (one i32 per cell: the tag of the cell's
//    function, 1 + its position among the module's address-taken functions in module order, the pass's
//    clones excluded; null is 0), the load bound to the i32 tag rail. qromCallees gives calls the
//    candidates. A data pointer in the table (a fat pointer over the object table, rule 21), a pointer
//    table in memory that is not constant, a vector or an aggregate is unimplemented.
//  - Predicate: none needed. The QROM reads 0 at an index >= n (§2), touches no state, and its
//    result is a value arm like any template under a quantum predicate.
#include "cq/Memory.h"
#include "QromInternal.h"

#include <algorithm>
#include <optional>
#include <string>

#include "cq/Abi.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/KnownBits.h"

using namespace llvm;

namespace cq::mem {

namespace {

struct Term {
  const Value *idx;
  int64_t stride;
};

// root + off + sum(term), bytes. Stops at the first pointer that is not a GEP or bitcast.
struct Addr {
  const Value *root = nullptr;
  int64_t off = 0;
  SmallVector<Term, 2> terms;
};

Addr decompose(const Value *p, const DataLayout &DL, const LoadInst &ld) {
  Addr a;
  for (;;) {
    if (auto *g = dyn_cast<GEPOperator>(p)) {
      for (gep_type_iterator gti = gep_type_begin(g), e = gep_type_end(g); gti != e; ++gti) {
        const Value *idx = gti.getOperand();
        if (StructType *st = gti.getStructTypeOrNull()) {
          a.off += int64_t(DL.getStructLayout(st)->getElementOffset(cast<ConstantInt>(idx)->getZExtValue()));
          continue;
        }
        if (isa<VectorType>(idx->getType()))
          unimplemented("mem-qrom: a vector GEP index on a QROM address", &ld);
        TypeSize ts = gti.getSequentialElementStride(DL);
        if (ts.isScalable())
          unimplemented("mem-qrom: a scalable GEP stride on a QROM address", &ld);
        int64_t stride = int64_t(ts.getFixedValue());
        if (auto *c = dyn_cast<ConstantInt>(idx)) {
          a.off += c->getSExtValue() * stride;
          continue;
        }
        bool merged = false;
        for (Term &t : a.terms)
          if (t.idx == idx) {
            t.stride += stride;
            merged = true;
          }
        if (!merged)
          a.terms.push_back({idx, stride});
      }
      p = g->getPointerOperand();
      continue;
    }
    if (auto *bc = dyn_cast<BitCastOperator>(p)) {
      p = bc->getOperand(0);
      continue;
    }
    a.root = p;
    return a;
  }
}

bool isQ(LoweringContext &ctx, const Value *v) { return ctx.T.isQuantum(v, ctx.S); }

// The allocation size in bytes of a root whose extent the IR states statically.
std::optional<uint64_t> staticBytes(const Value *root, const DataLayout &DL) {
  if (auto *gv = dyn_cast<GlobalVariable>(root)) {
    Type *t = gv->getValueType();
    if (!t->isSized())
      return std::nullopt;
    uint64_t b = DL.getTypeAllocSize(t).getFixedValue();
    if (b == 0)   // `extern T t[];` is [0 x T]: no extent
      return std::nullopt;
    return b;
  }
  if (auto *ai = dyn_cast<AllocaInst>(root)) {
    auto *cnt = dyn_cast<ConstantInt>(ai->getArraySize());
    if (!cnt)
      return std::nullopt;
    return DL.getTypeAllocSize(ai->getAllocatedType()).getFixedValue() * cnt->getZExtValue();
  }
  return std::nullopt;
}

bool knownObject(const Value *root) { return isa<GlobalVariable>(root) || isa<AllocaInst>(root); }

Value *toI64(LoweringContext &ctx, Value *v) {
  Type *i64 = Type::getInt64Ty(ctx.M.getContext());
  if (v->getType() == i64)
    return v;
  if (!v->getType()->isIntegerTy() || v->getType()->getIntegerBitWidth() > 64)
    internalError("mem-qrom: a QROM length that is not an integer of at most 64 bits", v);
  return ctx.B().CreateZExt(v, i64);
}

// Rule 20's fallback: the index's upper bound from LLVM's range facts, else 2^W.
Value *lengthFromRange(LoweringContext &ctx, const Value *idx, const LoadInst &ld) {
  Type *i64 = Type::getInt64Ty(ctx.M.getContext());
  // x urem d < d for a classical d (76's param_bounded): the run-time divisor is the bound.
  if (auto *bo = dyn_cast<BinaryOperator>(idx); bo && bo->getOpcode() == Instruction::URem &&
                                               !isQ(ctx, bo->getOperand(1))) {
    Operand d = ctx.operand(bo->getOperand(1));
    if (d.handle)
      internalError("mem-qrom: a classical urem divisor bound to a rail", bo);
    if (!isa<Constant>(d.v))
      return toI64(ctx, d.v);
  }
  unsigned W = idx->getType()->getIntegerBitWidth();
  const DataLayout &DL = ctx.M.getDataLayout();
  ConstantRange cr = computeConstantRange(idx, /*ForSigned=*/false, /*UseInstrInfo=*/true);
  KnownBits kb = computeKnownBits(idx, DL);
  APInt umax = APIntOps::umin(cr.getUnsignedMax(), kb.getMaxValue());
  // n = umax + 1 entries, at most 2^W (umax = 2^W - 1 when nothing is known).
  APInt cnt = umax.zext(std::max(W, 64u) + 1) + 1;
  if (cnt.getActiveBits() > 64)
    unimplemented("mem-qrom: a QROM of 2^64 or more entries (no range fact bounds the " + std::to_string(W) +
                      "-bit index)",
                  &ld);
  return ConstantInt::get(i64, cnt.getZExtValue());
}

// The address's quantum terms, each with its logical index (stripped of its widening casts).
struct QTerm {
  const Value *idx;   // the stripped index (a rail)
  int64_t coef;       // its multiple of the cell stride u
  bool sext;          // stripped from a sext of a possibly negative value
};

// Strips the GEP index of the zext (any) and of a sext whose operand is known non-negative or that
// indexes a known object from its start (rule 20, address arithmetic).
const Value *stripIndex(LoweringContext &ctx, const Value *idx, const Addr &a, const LoadInst &ld, bool &sext) {
  const DataLayout &DL = ctx.M.getDataLayout();
  sext = false;
  for (;;) {
    if (auto *z = dyn_cast<ZExtInst>(idx); z && isQ(ctx, z->getOperand(0))) {
      idx = z->getOperand(0);
      continue;
    }
    if (auto *s = dyn_cast<SExtInst>(idx); s && isQ(ctx, s->getOperand(0))) {
      bool nonNeg = isKnownNonNegative(s->getOperand(0), SimplifyQuery(DL));
      if (!nonNeg && !(knownObject(a.root) && a.off == 0))
        unimplemented("mem-qrom: a sign-extended quantum index into memory of unknown extent (a negative "
                      "index would read 0)",
                      &ld);
      sext |= !nonNeg;
      idx = s->getOperand(0);
      continue;
    }
    break;
  }
  if (!idx->getType()->isIntegerTy())
    internalError("mem-qrom: a QROM index that is not an integer", &ld);
  return idx;
}

// The unsigned upper bound of an index from LLVM's range facts (2^W - 1 when nothing is known).
APInt indexUMax(const Value *idx, const DataLayout &DL) {
  ConstantRange cr = computeConstantRange(idx, /*ForSigned=*/false, /*UseInstrInfo=*/true);
  KnownBits kb = computeKnownBits(idx, DL);
  return APIntOps::umin(cr.getUnsignedMax(), kb.getMaxValue());
}

// The logical (flattened) cell index sum_k coef_k * idx_k of a QROM address with several quantum terms,
// or one term at a coefficient above 1 (rule 20: "strided and flattened forms for struct arrays and 2-D
// arrays", 120): computed into fresh rails at width Wl, uncomputed by the spine like every template.
//  - Wl = the widest stripped index, widened to hold the largest in-domain linear index: n - 1 for a
//    static n (a larger index is past the object: undefined, outside the domain), else
//    sum_k coef_k * umax_k when every term is non-negative, else 64 (the byte offset's own width).
//    Modulo 2^Wl the sum is exact for every in-domain input (0 <= linear < 2^Wl).
//  - A narrower index is widened by a zext template (a sext one for a possibly negative index into a known
//    object, whose in-domain sum is still non-negative); coef 1: the rail itself, a power of two: shl_hl,
//    else mul_hl; the terms are summed left to right by add, in descending stride order (row before
//    column).
Operand linearIndex(LoweringContext &ctx, ArrayRef<QTerm> terms, std::optional<uint64_t> staticN, const LoadInst &ld) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  unsigned W = 1;
  for (const QTerm &t : terms)
    W = std::max(W, t.idx->getType()->getIntegerBitWidth());
  constexpr unsigned BW = 256;
  APInt bound(BW, 0);
  bool nonNeg = true;
  for (const QTerm &t : terms)
    nonNeg &= !t.sext;
  if (staticN) {
    bound = APInt(BW, *staticN ? *staticN - 1 : 0);
  } else if (nonNeg) {
    for (const QTerm &t : terms)
      bound += indexUMax(t.idx, DL).zext(BW) * APInt(BW, uint64_t(t.coef));
  } else {
    bound = APInt::getSignedMaxValue(64).zext(BW);
  }
  unsigned Wl = std::max(W, bound.getActiveBits());
  Type *ty = IntegerType::get(C, Wl);
  RailType rt = railTypeOf(ty);
  Operand acc{nullptr, true};
  for (const QTerm &t : terms) {
    Operand x = ctx.operand(t.idx);
    if (!x.handle)
      internalError("mem-qrom: the logical QROM index is not a rail", t.idx);
    unsigned w = t.idx->getType()->getIntegerBitWidth();
    if (w != Wl) {
      abi::TemplateSpec cast;
      cast.op = t.sext ? "sext" : "zext";
      cast.w = railTypeOf(t.idx->getType());
      cast.to = rt;
      x = Operand{ctx.emitTemplate(cast, {x}), true};
    }
    if (t.coef != 1) {
      abi::TemplateSpec sc;
      sc.w = rt;
      sc.shape = "hl";
      uint64_t c = uint64_t(t.coef);
      if ((c & (c - 1)) == 0) {
        sc.op = "shl";
        x = Operand{ctx.emitTemplate(sc, {x, Operand{ConstantInt::get(ty, Log2_64(c)), false}}), true};
      } else {
        sc.op = "mul";
        x = Operand{ctx.emitTemplate(sc, {x, Operand{ConstantInt::get(ty, c), false}}), true};
      }
    }
    if (!acc.v) {
      acc = x;
      continue;
    }
    abi::TemplateSpec add;
    add.op = "add";
    add.w = rt;
    acc = Operand{ctx.emitTemplate(add, {acc, x}), true};
  }
  (void)ld;
  return acc;
}

// Rules 19 and 21 (97): the tag of a function as a fat pointer's object: 1 + its position among the
// module's address-taken functions in module order (the pass's own clones excluded); 0 is null.
unsigned tagOf(const Module &M, const Function &F) {
  unsigned n = 0;
  for (const Function &G : M) {
    if (!G.hasAddressTaken() || G.getName().starts_with("__cq_"))
      continue;
    ++n;
    if (&G == &F)
      return n;
  }
  internalError("mem-qrom: a callee-table entry that is not an address-taken function", &F);
}

// The QROM cells of a pointer table: cell i holds the pointer at byte root + off + i * u of a constant
// global's initializer: a function (its tag), null (0), anything else unimplemented (a data pointer is a
// fat pointer over the per-function object table, rule 21: its derived (tag, idx) tables are not built).
SmallVector<const Function *, 8> pointerCells(const GlobalVariable &gv, int64_t off, int64_t u, uint64_t n,
                                              const Instruction &at) {
  const DataLayout &DL = gv.getParent()->getDataLayout();
  Type *pty = PointerType::get(gv.getContext(), 0);
  SmallVector<const Function *, 8> cells;
  for (uint64_t i = 0; i < n; ++i) {
    APInt o(64, uint64_t(off) + i * uint64_t(u));
    Constant *c = ConstantFoldLoadFromConst(const_cast<Constant *>(gv.getInitializer()), pty, o, DL);
    if (!c)
      unimplemented("mem-qrom: a pointer-table cell whose contents do not fold to a constant", &at);
    c = c->stripPointerCasts();
    if (c->isNullValue()) {
      cells.push_back(nullptr);
      continue;
    }
    auto *F = dyn_cast<Function>(c);
    if (!F)
      unimplemented("mem-qrom: a QROM load of a data pointer (rule 21: a fat pointer whose (tag, idx) tables "
                    "over the object table are not built)",
                    &at);
    cells.push_back(F);
  }
  return cells;
}

// The derived constant table of callee tags of a function-pointer table (97: @fps.cqtag), one i32 per
// QROM cell; reused when an identical one exists.
GlobalVariable *tagTable(Module &M, const GlobalVariable &gv, ArrayRef<const Function *> cells, int64_t off,
                         int64_t u) {
  LLVMContext &C = M.getContext();
  Type *i32 = Type::getInt32Ty(C);
  SmallVector<Constant *, 8> tags;
  for (const Function *F : cells)
    tags.push_back(ConstantInt::get(i32, F ? tagOf(M, *F) : 0));
  ArrayType *aty = ArrayType::get(i32, tags.size());
  Constant *init = ConstantArray::get(aty, tags);
  std::string name = gv.getName().str() + ".cqtag";
  if (off != 0 || u != int64_t(M.getDataLayout().getPointerSize()))
    name += "." + std::to_string(off) + "." + std::to_string(u);
  if (GlobalVariable *g = M.getNamedGlobal(name)) {
    if (g->getValueType() != aty || g->getInitializer() != init)
      internalError("mem-qrom: a derived tag table name taken by a different table", g);
    return g;
  }
  auto *g = new GlobalVariable(M, aty, /*isConstant=*/true, GlobalValue::PrivateLinkage, init, name);
  g->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
  g->setAlignment(gv.getAlign().valueOrOne());
  return g;
}

// The shared analysis of a QROM load: address, terms, cell stride u and static cell count.
struct QromShape {
  Addr a;
  SmallVector<QTerm, 2> terms;
  int64_t u = 0, size = 0;
  std::optional<uint64_t> staticN;
};

int64_t gcd64(int64_t x, int64_t y) {
  while (y) {
    int64_t t = x % y;
    x = y;
    y = t;
  }
  return x;
}

QromShape analyze(LoweringContext &ctx, const LoadInst &ld) {
  const DataLayout &DL = ctx.M.getDataLayout();
  QromShape q;
  Type *ty = ld.getType();
  q.size = int64_t(DL.getTypeAllocSize(ty).getFixedValue());
  q.a = decompose(ld.getPointerOperand(), DL, ld);
  if (isQ(ctx, q.a.root) || ctx.T.isFatPointer(q.a.root, ctx.S))
    unimplemented("mem-qrom: a QROM whose base pointer is quantum (rule 21)", &ld);
  for (const Term &t : q.a.terms)
    if (!isQ(ctx, t.idx))
      unimplemented("mem-qrom: a classical variable index next to the quantum one in a QROM address", &ld);
  if (q.a.terms.empty())
    internalError("mem-qrom: a quantum-offset load whose address has no quantum index", &ld);
  if (q.a.off < 0)
    unimplemented("mem-qrom: a QROM address with a negative constant byte offset", &ld);
  SmallVector<Term, 2> ts(q.a.terms.begin(), q.a.terms.end());
  std::stable_sort(ts.begin(), ts.end(), [](const Term &x, const Term &y) { return x.stride > y.stride; });
  for (const Term &t : ts)
    if (t.stride <= 0)
      unimplemented("mem-qrom: a QROM stride below the element size (a bit view, or a negative stride)", &ld);
  for (const Term &t : ts)
    q.u = gcd64(q.u, t.stride);
  if (q.u < q.size)
    unimplemented("mem-qrom: a QROM stride below the element size (a bit view, or a negative stride)", &ld);
  for (const Term &t : ts) {
    bool sx = false;
    const Value *idx = stripIndex(ctx, t.idx, q.a, ld, sx);
    q.terms.push_back({idx, t.stride / q.u, sx});
  }
  if (std::optional<uint64_t> bytes = staticBytes(q.a.root, DL)) {
    uint64_t off = uint64_t(q.a.off), size = uint64_t(q.size), u = uint64_t(q.u);
    q.staticN = *bytes >= off + size ? (*bytes - off - size) / u + 1 : 0;
  }
  return q;
}

} // namespace

void lowerQromLoad(LoweringContext &ctx, LoadInst &ld) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  Type *i64 = Type::getInt64Ty(C);
  Type *ty = ld.getType();
  bool fnTable = ty->isPointerTy();
  if (!(ty->isIntegerTy() || ty->isFloatingPointTy() || fnTable))
    unimplemented("mem-qrom: a QROM load of a vector or aggregate value", &ld);

  QromShape q = analyze(ctx, ld);
  const Addr &a = q.a;
  int64_t stride = q.u, size = q.size, off = a.off;

  // The logical index (rule 20): one term at coefficient 1 is its stripped index's rail at its own width;
  // otherwise the flattened linear index.
  Operand ix{nullptr, false};
  if (q.terms.size() == 1 && q.terms[0].coef == 1) {
    ix = ctx.operand(q.terms[0].idx);
    if (!ix.handle)
      internalError("mem-qrom: the logical QROM index is not a rail", q.terms[0].idx);
  }

  if (fnTable) {
    // Rule 19 (97): a function pointer loaded at a quantum index is a QROM of callee tags over the
    // derived constant table; the load is bound to the tag rail (calls dispatches on it).
    auto *gv = dyn_cast<GlobalVariable>(a.root);
    if (!gv || !gv->isConstant() || !gv->hasDefinitiveInitializer() || !q.staticN)
      unimplemented("mem-qrom: a QROM of pointers over memory that is not a constant global with a known "
                    "initializer (the tag table would be derived at run time)",
                    &ld);
    SmallVector<const Function *, 8> cells = pointerCells(*gv, off, stride, *q.staticN, ld);
    GlobalVariable *tags = tagTable(ctx.M, *gv, cells, off, stride);
    if (!ix.v)
      ix = linearIndex(ctx, q.terms, q.staticN, ld);
    abi::TemplateSpec spec;
    spec.op = "qrom_load";
    spec.w = RailType{Kind::Int, 32};
    ctx.emitTemplate(spec, {Operand{tags, false}, Operand{ConstantInt::get(i64, *q.staticN), false}, ix}, &ld);
    return;
  }
  RailType w = railTypeOf(ty);

  // Base.
  Operand root = ctx.operand(a.root);
  if (root.handle)
    internalError("mem-qrom: a QROM base pointer bound to a rail", a.root);
  Value *base = root.v;
  if (off != 0)
    base = ctx.B().CreateInBoundsGEP(Type::getInt8Ty(C), base, ConstantInt::get(i64, off));

  // Length.
  Value *n = nullptr;
  if (q.staticN) {
    n = ConstantInt::get(i64, *q.staticN);
  } else if (auto *ai = dyn_cast<AllocaInst>(a.root)) {
    int64_t E = int64_t(DL.getTypeAllocSize(ai->getAllocatedType()).getFixedValue());
    if (E % stride != 0 || off + size > stride)
      unimplemented("mem-qrom: a QROM over a dynamic alloca whose element is not a whole number of indexed "
                    "cells",
                    &ld);
    Operand c = ctx.operand(ai->getArraySize());
    if (c.handle)
      internalError("mem-qrom: a VLA element count bound to a rail", ai);
    n = toI64(ctx, c.v);
    if (E != stride)
      n = ctx.B().CreateMul(n, ConstantInt::get(i64, E / stride));
  } else if (q.terms.size() == 1) {
    n = lengthFromRange(ctx, q.terms[0].idx, ld);
  } else {
    // Several non-negative terms (a sext of a possibly negative one into unknown extent was refused):
    // sum_k coef_k * umax_k + 1 cells.
    APInt cnt(256, 1);
    for (const QTerm &t : q.terms)
      cnt += indexUMax(t.idx, DL).zext(256) * APInt(256, uint64_t(t.coef));
    if (cnt.getActiveBits() > 64)
      unimplemented("mem-qrom: a QROM of 2^64 or more entries (no range fact bounds the flattened index)", &ld);
    n = ConstantInt::get(i64, cnt.getZExtValue());
  }
  if (!ix.v)
    ix = linearIndex(ctx, q.terms, q.staticN, ld);

  abi::TemplateSpec spec;
  spec.op = "qrom_load";
  spec.w = w;
  spec.strided = stride != size;
  SmallVector<Operand, 4> ops{Operand{base, false}, Operand{n, false}};
  if (spec.strided)
    ops.push_back(Operand{ConstantInt::get(i64, stride), false});
  ops.push_back(ix);
  ctx.emitTemplate(spec, ops, &ld);
}

SmallVector<std::pair<Function *, unsigned>, 4> qromCallees(LoweringContext &ctx, const Value *fp) {
  SmallVector<std::pair<Function *, unsigned>, 4> out;
  auto *ld = dyn_cast<LoadInst>(fp);
  if (!ld || !ld->getType()->isPointerTy() || ld->isVolatile() || ld->isAtomic() ||
      ctx.T.offsetKind(ld, ctx.S) != OffsetKind::Quantum)
    return out;
  QromShape q = analyze(ctx, *ld);
  auto *gv = dyn_cast<GlobalVariable>(q.a.root);
  if (!gv || !gv->isConstant() || !gv->hasDefinitiveInitializer() || !q.staticN)
    return out;
  for (const Function *F : pointerCells(*gv, q.a.off, q.u, *q.staticN, *ld)) {
    if (!F)
      continue;
    unsigned t = tagOf(ctx.M, *F);
    if (std::none_of(out.begin(), out.end(), [&](auto &p) { return p.second == t; }))
      out.push_back({const_cast<Function *>(F), t});
  }
  std::sort(out.begin(), out.end(), [](auto &x, auto &y) { return x.second < y.second; });
  return out;
}

unsigned calleeTag(const Module &M, const Function &F) { return tagOf(M, F); }

// Rule 21 over classical memory: the QROM of a fat pointer's root (a classical pointer into a static
// object: a constant byte offset from an alloca or global) at a rail cell index.
Value *qromLoadAt(LoweringContext &ctx, const Value *root, Operand idx, unsigned idxBits, bool idxSext, Type *ty,
                  const Instruction &at) {
  const DataLayout &DL = ctx.M.getDataLayout();
  Type *i64 = Type::getInt64Ty(ctx.M.getContext());
  if (!idx.handle)
    internalError("mem-qrom: qromLoadAt at a classical index", &at);
  if (!(ty->isIntegerTy() || ty->isFloatingPointTy()))
    unimplemented("mem-qrom: a QROM load of a non-scalar or pointer value through a fat pointer (rule 21)", &at);
  APInt off(64, 0);
  const Value *obj = root->stripAndAccumulateConstantOffsets(DL, off, /*AllowNonInbounds=*/true);
  std::optional<uint64_t> bytes = staticBytes(obj, DL);
  if (!bytes || off.isNegative())
    unimplemented("mem-qrom: a fat-pointer QROM over a root whose extent is not static", &at);
  uint64_t size = DL.getTypeAllocSize(ty).getFixedValue();
  uint64_t o = off.getZExtValue();
  // cq-b244: the k whole cells of the object before root are in-bounds at idx -k .. -1 (a signed idx; an
  // unsigned one never reaches them); the table starts at the first of them and the index moves up by k
  // (exact in the low W bits: every in-domain idx + k is below n <= 2^W).
  uint64_t k = idxSext ? o / size : 0;
  uint64_t first = o - k * size;
  uint64_t n = *bytes >= first + size ? (*bytes - first - size) / size + 1 : 0;
  Operand base = ctx.operand(root);
  if (base.handle)
    internalError("mem-qrom: a QROM base pointer bound to a rail", root);
  Value *table = base.v;
  if (k != 0) {
    if (idxBits == 0 || idxBits > 64)
      internalError("mem-qrom: a fat-pointer QROM index of no width", &at);
    unsigned W = std::max(idxBits, n > 1 ? Log2_64_Ceil(n) : 1u);
    if (W > 64)
      unimplemented("mem-qrom: a fat-pointer QROM of 2^64 or more cells", &at);
    auto tmpl = [&](StringRef op, unsigned w, ArrayRef<Operand> ops, StringRef shape, std::optional<unsigned> to) {
      abi::TemplateSpec s;
      s.op = op.str();
      s.w = RailType{Kind::Int, w};
      if (to)
        s.to = RailType{Kind::Int, *to};
      s.shape = shape.str();
      return Operand{ctx.emitTemplate(s, ops), true};
    };
    if (W > idxBits)
      idx = tmpl(idxSext ? "sext" : "zext", idxBits, {idx}, "", W);
    idx = tmpl("add", W, {idx, Operand{ConstantInt::get(ctx.M.getContext(), APInt(W, k)), false}}, "hl", std::nullopt);
    table = ctx.B().CreateInBoundsGEP(Type::getInt8Ty(ctx.M.getContext()), table,
                                      ConstantInt::get(i64, -int64_t(k * size)));
  }
  abi::TemplateSpec spec;
  spec.op = "qrom_load";
  spec.w = railTypeOf(ty);
  return ctx.emitTemplate(spec, {Operand{table, false}, Operand{ConstantInt::get(i64, n), false}, idx});
}

} // namespace cq::mem
