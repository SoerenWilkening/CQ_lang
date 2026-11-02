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
#include "cq/FatPtr.h"
#include <functional>
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
        // A GEP with a vector index yields a vector of pointers, never the scalar address of a load; and
        // x86-64 (CR §0, rule 25) has no scalable types.
        if (isa<VectorType>(idx->getType()))
          internalError("mem-qrom: a vector GEP index on the scalar address of a load", &ld);
        TypeSize ts = gti.getSequentialElementStride(DL);
        if (ts.isScalable())
          internalError("mem-qrom: a scalable GEP stride on x86-64", &ld);
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

// Rule 20's fallback: the index's upper bound from LLVM's range facts, else 2^W. nullptr when that is
// 2^64 or more (the general window, lowerGeneral, takes the load).
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
  (void)ld;
  if (cnt.getActiveBits() > 64)
    return nullptr;
  return ConstantInt::get(i64, cnt.getZExtValue());
}

// The address's quantum terms, each with its logical index (stripped of its widening casts).
struct QTerm {
  const Value *idx;    // the stripped index (a rail)
  int64_t coef;        // its multiple of the cell stride u
  bool sext;           // stripped from a sext of a possibly negative value
  const Value *gidx;   // the GEP's own index operand (LLVM's address arithmetic reads it sign-extended to 64 bits)
  bool general;        // the index may lie outside [0, 2^64) cells from the base read unsigned: lowerGeneral
};

// Strips the GEP index of the zext (any) and of a sext (rule 20, address arithmetic). A sext of a possibly
// negative value is read unsigned (the construction of a static object from its start, where a negative
// index is outside the object) only when it indexes a known object from its start; otherwise, and for an
// uncast index narrower than 64 bits that may be negative (the GEP sign-extends it), or one wider than 64
// bits (the GEP truncates it), the term is `general`: lowerGeneral reads it exactly as the GEP does.
const Value *stripIndex(LoweringContext &ctx, const Value *idx, const Addr &a, const LoadInst &ld, bool &sext,
                        bool &general) {
  const DataLayout &DL = ctx.M.getDataLayout();
  sext = false;
  general = false;
  const Value *top = idx;
  for (;;) {
    if (auto *z = dyn_cast<ZExtInst>(idx); z && isQ(ctx, z->getOperand(0))) {
      idx = z->getOperand(0);
      continue;
    }
    if (auto *s = dyn_cast<SExtInst>(idx); s && isQ(ctx, s->getOperand(0))) {
      bool nonNeg = isKnownNonNegative(s->getOperand(0), SimplifyQuery(DL));
      if (!nonNeg && !(knownObject(a.root) && a.off == 0))
        general = true;
      sext |= !nonNeg;
      idx = s->getOperand(0);
      continue;
    }
    break;
  }
  if (!idx->getType()->isIntegerTy())
    internalError("mem-qrom: a QROM index that is not an integer", &ld);
  unsigned tw = top->getType()->getIntegerBitWidth();
  if (tw > 64)
    general = true;
  if (top == idx && tw < 64 && !isKnownNonNegative(top, SimplifyQuery(DL)) && !(knownObject(a.root) && a.off == 0))
    general = true;
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
  SmallVector<QTerm, 2> terms;     // quantum terms of non-zero stride, descending stride
  SmallVector<Term, 2> cterms;     // classical variable terms (bytes): part of the table's base
  int64_t u = 0, size = 0;
  std::optional<uint64_t> staticN;
  bool general = false;            // the first construction (lowerQromLoad's simple form) does not apply
};

int64_t gcd64(int64_t x, int64_t y) {
  while (y) {
    int64_t t = x % y;
    x = y;
    y = t;
  }
  return x;
}

// The bytes one load of ty reads (a scalar: its alloc size, f80 16, rule 20's element; a composite: its
// store size).
int64_t accessBytes(const DataLayout &DL, Type *ty) {
  if (ty->isStructTy() || ty->isArrayTy() || ty->isVectorTy())
    return int64_t(DL.getTypeStoreSize(ty).getFixedValue());
  return int64_t(DL.getTypeAllocSize(ty).getFixedValue());
}

QromShape analyze(LoweringContext &ctx, const LoadInst &ld) {
  const DataLayout &DL = ctx.M.getDataLayout();
  QromShape q;
  q.size = accessBytes(DL, ld.getType());
  q.a = decompose(ld.getPointerOperand(), DL, ld);
  if (isQ(ctx, q.a.root) || ctx.T.isFatPointer(q.a.root, ctx.S))
    internalError("mem-qrom: a QROM whose base pointer is quantum (rule 21: fatptr's)", &ld);
  SmallVector<Term, 2> ts;
  for (const Term &t : q.a.terms) {
    if (t.stride < 0)
      internalError("mem-qrom: a negative GEP stride", &ld);
    if (!isQ(ctx, t.idx)) {
      // A classical variable term (t[c][q]): rule 20's base is the classical address it gives.
      q.cterms.push_back(t);
      q.general = true;
      continue;
    }
    if (t.stride == 0) {   // a zero-sized element: the index moves no byte
      q.general = true;
      continue;
    }
    ts.push_back(t);
  }
  if (q.a.terms.empty())
    internalError("mem-qrom: a quantum-offset load whose address has no quantum index", &ld);
  if (q.a.off < 0)
    q.general = true;
  std::stable_sort(ts.begin(), ts.end(), [](const Term &x, const Term &y) { return x.stride > y.stride; });
  for (const Term &t : ts)
    q.u = gcd64(q.u, t.stride);
  for (const Term &t : ts) {
    bool sx = false, gen = false;
    const Value *idx = stripIndex(ctx, t.idx, q.a, ld, sx, gen);
    q.terms.push_back({idx, t.stride / q.u, sx, t.idx, gen});
    q.general |= gen;
  }
  if (q.general)
    return q;
  if (std::optional<uint64_t> bytes = staticBytes(q.a.root, DL)) {
    uint64_t off = uint64_t(q.a.off), size = uint64_t(q.size), u = uint64_t(q.u);
    q.staticN = *bytes >= off + size ? (*bytes - off - size) / u + 1 : 0;
  }
  return q;
}

// ---- the general window (lowerGeneral) -----------------------------------------------------------

// v's value modulo 2^W as a rail (W <= 64): the GEP index's own address arithmetic, an extension stripped
// above the width (it does not change the low W bits), else applied by its template; an uncast index
// narrower than 64 bits is sign-extended by the GEP itself, a wider one truncated.
Operand railAt(LoweringContext &ctx, const Value *v, unsigned W, bool top, const Instruction &at) {
  auto tmpl = [&](StringRef op, unsigned from, Operand x) {
    abi::TemplateSpec s;
    s.op = op.str();
    s.w = RailType{Kind::Int, from};
    s.to = RailType{Kind::Int, W};
    return Operand{ctx.emitTemplate(s, {x}), true};
  };
  if (isa<ZExtInst>(v) || isa<SExtInst>(v)) {
    const Value *x = cast<CastInst>(v)->getOperand(0);
    if (isQ(ctx, x)) {
      unsigned w = x->getType()->getIntegerBitWidth();
      if (W <= w)
        return railAt(ctx, x, W, false, at);
      Operand r = railAt(ctx, x, w, false, at);
      return tmpl(isa<SExtInst>(v) ? "sext" : "zext", w, r);
    }
  }
  Operand r = ctx.operand(v);
  if (!r.handle || !v->getType()->isIntegerTy())
    internalError("mem-qrom: a quantum QROM index term that is not an integer rail", &at);
  unsigned w = v->getType()->getIntegerBitWidth();
  if (w == W)
    return r;
  if (w > W)
    return tmpl("trunc", w, r);
  if (!top)
    internalError("mem-qrom: an index term narrower than its width below its extension", &at);
  return tmpl("sext", w, r);   // the GEP's own sign extension of a narrow index
}

// The range of an integer value (LLVM's range facts and known bits), seen through extensions.
ConstantRange rangeOf(const Value *v, const DataLayout &DL, bool forSigned) {
  unsigned w = v->getType()->getIntegerBitWidth();
  ConstantRange cr = computeConstantRange(v, forSigned, /*UseInstrInfo=*/true);
  cr = cr.intersectWith(ConstantRange::fromKnownBits(computeKnownBits(v, DL), forSigned),
                        forSigned ? ConstantRange::Signed : ConstantRange::Unsigned);
  if (auto *s = dyn_cast<SExtInst>(v))
    cr = cr.intersectWith(rangeOf(s->getOperand(0), DL, true).signExtend(w),
                          forSigned ? ConstantRange::Signed : ConstantRange::Unsigned);
  else if (auto *z = dyn_cast<ZExtInst>(v))
    cr = cr.intersectWith(rangeOf(z->getOperand(0), DL, false).zeroExtend(w),
                          forSigned ? ConstantRange::Signed : ConstantRange::Unsigned);
  return cr;
}

// The signed range of a GEP index as the GEP reads it (sign-extended to, or truncated at, 64 bits).
std::pair<APInt, APInt> gepIndexRange(const Value *gidx, const DataLayout &DL) {
  constexpr unsigned BW = 256;
  unsigned w = gidx->getType()->getIntegerBitWidth();
  if (w > 64)
    return {APInt::getSignedMinValue(64).sext(BW), APInt::getSignedMaxValue(64).sext(BW)};
  ConstantRange cr = rangeOf(gidx, DL, /*forSigned=*/true);
  if (cr.isEmptySet())   // the index is poison on every path
    cr = ConstantRange::getFull(w);
  return {cr.getSignedMin().sext(BW), cr.getSignedMax().sext(BW)};
}

// The extent in bytes of root's object when the IR states it: static (a global or a static alloca) or
// a dynamic alloca's element count times its element size (computed at the builder); nullptr otherwise.
Value *extentBytes(LoweringContext &ctx, const Value *root) {
  const DataLayout &DL = ctx.M.getDataLayout();
  Type *i64 = Type::getInt64Ty(ctx.M.getContext());
  if (std::optional<uint64_t> b = staticBytes(root, DL))
    return ConstantInt::get(i64, *b);
  if (auto *ai = dyn_cast<AllocaInst>(root)) {
    Operand c = ctx.operand(ai->getArraySize());
    if (c.handle)
      internalError("mem-qrom: a VLA element count bound to a rail", ai);
    uint64_t E = DL.getTypeAllocSize(ai->getAllocatedType()).getFixedValue();
    return ctx.B().CreateMul(toI64(ctx, c.v), ConstantInt::get(i64, E));
  }
  return nullptr;
}

// floor(a / u) for an i64 a and a positive constant u.
Value *floorDivRT(IRBuilder<> &B, Value *a, int64_t u) {
  Type *i64 = a->getType();
  Value *uc = ConstantInt::get(i64, u);
  Value *q = B.CreateSDiv(a, uc);
  Value *neg = B.CreateICmpSLT(B.CreateSRem(a, uc), ConstantInt::get(i64, 0));
  return B.CreateSelect(neg, B.CreateSub(q, ConstantInt::get(i64, 1)), q);
}

Value *smaxRT(IRBuilder<> &B, Value *a, Value *b) { return B.CreateSelect(B.CreateICmpSGT(a, b), a, b); }

// The QROM table of a load in its general form: base (host address of element 0), n, the cell stride u
// and the index rail: rule 20's QROM over the cells at root + B0 + L * u, where B0 is the constant offset
// plus the classical terms (bytes, LLVM's wrapping GEP arithmetic) and L = sum_k coef_k * idx_k the
// quantum cell index as the GEP reads it (each index sign-extended or truncated to 64 bits). Element i of
// the table is the cell at L = lo + i, read at index L - lo (modulo 2^W, exact on [0, n)):
//  - an object of known extent `bytes`: the cells of the object, lo = ceil(-B0 / u) (at least 0 when L
//    cannot be negative), up to floor((bytes - size - B0) / u); an access outside them is outside the
//    object (undefined, outside the domain);
//  - memory of unknown extent: rule 20's range facts on L (lo = its signed minimum when it may be negative,
//    else 0; up to its maximum); when they leave 2^64 or more cells and u is a power of two 2^p (p >= 1),
//    the address depends only on L modulo 2^(64 - p): n = 2^(64 - p) at the index truncated to 64 - p bits.
//    A byte or odd stride over 2^64 cells has no i64 length (awaiting owner ruling).
struct Table {
  Value *base;
  Value *n;
  Operand idx;
};

Table generalTable(LoweringContext &ctx, const QromShape &q, const LoadInst &ld) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  IRBuilder<> &B = ctx.B();
  Type *i64 = Type::getInt64Ty(C);
  constexpr unsigned BW = 256;
  int64_t u = q.u, size = q.size;
  // B0.
  Value *b0 = ConstantInt::get(i64, q.a.off, true);
  for (const Term &t : q.cterms) {
    Operand x = ctx.operand(t.idx);
    if (x.handle)
      internalError("mem-qrom: a classical QROM address term bound to a rail", t.idx);
    Value *v = B.CreateSExtOrTrunc(x.v, i64);
    b0 = B.CreateAdd(b0, B.CreateMul(v, ConstantInt::get(i64, t.stride, true)));
  }
  // L's range.
  APInt Lmin(BW, 0), Lmax(BW, 0);
  unsigned Wt = 1;
  for (const QTerm &t : q.terms) {
    auto [lo, hi] = gepIndexRange(t.gidx, DL);
    APInt c(BW, uint64_t(t.coef));
    Lmin += lo * c;
    Lmax += hi * c;
    Wt = std::max(Wt, std::min(64u, t.idx->getType()->getIntegerBitWidth()));
  }
  bool nonNeg = !Lmin.isNegative();
  Value *lo = nullptr, *n = nullptr;
  unsigned W = 64;
  if (Value *bytes = extentBytes(ctx, q.a.root)) {
    lo = B.CreateNeg(floorDivRT(B, b0, u));
    if (nonNeg)
      lo = smaxRT(B, lo, ConstantInt::get(i64, 0));
    Value *hi = floorDivRT(B, B.CreateSub(B.CreateSub(bytes, ConstantInt::get(i64, size)), b0), u);
    n = smaxRT(B, B.CreateAdd(B.CreateSub(hi, lo), ConstantInt::get(i64, 1)), ConstantInt::get(i64, 0));
    if (auto *cb = dyn_cast<ConstantInt>(bytes)) {
      // hi - lo + 1 <= floor((bytes - size) / u) + 1 (floor(a) + floor(b) <= floor(a + b)).
      int64_t nmax = cb->getSExtValue() >= size ? (cb->getSExtValue() - size) / u + 1 : 1;
      W = std::max(Wt, nmax > 1 ? Log2_64_Ceil(uint64_t(nmax)) : 1u);
    }
  } else {
    APInt l = nonNeg ? APInt(BW, 0) : Lmin;
    APInt cnt = Lmax - l + 1;
    if (cnt.getActiveBits() <= 64 && !cnt.isZero()) {
      lo = ConstantInt::get(C, l.trunc(64));
      n = ConstantInt::get(i64, cnt.getZExtValue());
      W = std::max(Wt, cnt.ugt(1) ? unsigned(Log2_64_Ceil(cnt.getZExtValue())) : 1u);
      if (cnt.getActiveBits() == 64 && cnt.isPowerOf2())
        W = 64;
    } else if (u > 1 && isPowerOf2_64(uint64_t(u))) {
      W = 64 - Log2_64(uint64_t(u));
      lo = ConstantInt::get(i64, 0);
      n = ConstantInt::get(i64, uint64_t(1) << W);
    } else {
      unimplemented("awaiting owner ruling: SPEC_ISSUES QROM of 2^64 cells (a byte or odd stride at an unbounded "
                    "64-bit index into memory of unknown extent has no i64 length)",
                    &ld);
    }
  }
  // The index (L - lo) modulo 2^W.
  Type *ty = IntegerType::get(C, W);
  RailType rt{Kind::Int, W};
  Operand acc{nullptr, true};
  for (const QTerm &t : q.terms) {
    Operand x = railAt(ctx, t.gidx, W, /*top=*/true, ld);
    APInt c = APInt(64, uint64_t(t.coef)).trunc(W);
    if (c.isZero())
      internalError("mem-qrom: a QROM index coefficient that vanishes at its width", &ld);
    if (!c.isOne()) {
      abi::TemplateSpec sc;
      sc.w = rt;
      sc.shape = "hl";
      if (c.isPowerOf2()) {
        sc.op = "shl";
        x = Operand{ctx.emitTemplate(sc, {x, Operand{ConstantInt::get(ty, c.logBase2()), false}}), true};
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
  auto *loc = dyn_cast<ConstantInt>(lo);
  if (!loc || !loc->isZero()) {
    abi::TemplateSpec add;
    add.op = "add";
    add.w = rt;
    add.shape = "hl";
    acc = Operand{ctx.emitTemplate(add, {acc, Operand{B.CreateTrunc(B.CreateNeg(lo), ty), false}}), true};
  }
  // base = root + B0 + lo * u (an address arithmetic GEP, not inbounds: the table may start before the
  // object only where rule 20's range facts reach).
  Operand root = ctx.operand(q.a.root);
  if (root.handle)
    internalError("mem-qrom: a QROM base pointer bound to a rail", q.a.root);
  Value *off = B.CreateAdd(b0, B.CreateMul(lo, ConstantInt::get(i64, u)));
  Value *base = root.v;
  if (!isa<ConstantInt>(off) || !cast<ConstantInt>(off)->isZero())
    base = B.CreateGEP(Type::getInt8Ty(C), base, off);
  return {base, n, acc};
}

// The scalar leaves of a loaded value (rules 25, 26: struct and array elements, vector lanes, depth
// first, left to right; the field order aggr binds) with their byte offsets in the value. A vector of
// lanes that are not whole bytes is one leaf of its integer bits (split by unpackLanes).
struct Leaf {
  Type *ty;
  uint64_t off;
};

void leavesOf(Type *t, uint64_t off, const DataLayout &DL, SmallVectorImpl<Leaf> &out) {
  if (auto *st = dyn_cast<StructType>(t)) {
    const StructLayout *L = DL.getStructLayout(st);
    for (unsigned i = 0; i < st->getNumElements(); ++i)
      leavesOf(st->getElementType(i), off + L->getElementOffset(i).getFixedValue(), DL, out);
    return;
  }
  if (auto *at = dyn_cast<ArrayType>(t)) {
    uint64_t es = DL.getTypeAllocSize(at->getElementType()).getFixedValue();
    for (uint64_t i = 0; i < at->getNumElements(); ++i)
      leavesOf(at->getElementType(), off + i * es, DL, out);
    return;
  }
  if (auto *vt = dyn_cast<FixedVectorType>(t)) {
    uint64_t eb = DL.getTypeSizeInBits(vt->getElementType()).getFixedValue();
    if (eb % 8) {
      out.push_back({IntegerType::get(t->getContext(), unsigned(eb * vt->getNumElements())), off});
      return;
    }
    for (unsigned i = 0; i < vt->getNumElements(); ++i)
      leavesOf(vt->getElementType(), off + i * (eb / 8), DL, out);
    return;
  }
  out.push_back({t, off});
}

bool pointerLeaf(Type *t) {
  if (auto *st = dyn_cast<StructType>(t))
    return llvm::any_of(st->elements(), pointerLeaf);
  if (auto *at = dyn_cast<ArrayType>(t))
    return pointerLeaf(at->getElementType());
  if (auto *vt = dyn_cast<VectorType>(t))
    return pointerLeaf(vt->getElementType());
  return t->isPointerTy();
}

// The lanes of a vector of sub-byte integer lanes, read as one integer rail x: lane i is
// trunc(lshr(x, i * w)) (rule 25: lanes; rule 4 templates).
void unpackLanes(LoweringContext &ctx, FixedVectorType *vt, Operand x, SmallVectorImpl<Operand> &out) {
  unsigned w = vt->getElementType()->getIntegerBitWidth(), N = w * vt->getNumElements();
  Type *ty = IntegerType::get(ctx.M.getContext(), N);
  for (unsigned i = 0; i < vt->getNumElements(); ++i) {
    Operand s = x;
    if (i) {
      abi::TemplateSpec sh;
      sh.op = "lshr";
      sh.w = RailType{Kind::Int, N};
      sh.shape = "hl";
      s = Operand{ctx.emitTemplate(sh, {x, Operand{ConstantInt::get(ty, uint64_t(i) * w), false}}), true};
    }
    abi::TemplateSpec tr;
    tr.op = "trunc";
    tr.w = RailType{Kind::Int, N};
    tr.to = RailType{Kind::Int, w};
    out.push_back(Operand{ctx.emitTemplate(tr, {s}), true});
  }
}

// The rails of a loaded value's fields (aggr's order): one rail per leaf from leafRail, a packed sub-byte
// vector split into its lanes.
SmallVector<Operand, 4> fieldRails(LoweringContext &ctx, Type *ty, function_ref<Operand(const Leaf &)> leafRail) {
  const DataLayout &DL = ctx.M.getDataLayout();
  SmallVector<Leaf, 4> leaves;
  leavesOf(ty, 0, DL, leaves);
  SmallVector<Operand, 4> raw;
  for (const Leaf &l : leaves)
    raw.push_back(leafRail(l));
  SmallVector<Operand, 4> out;
  size_t k = 0;
  std::function<void(Type *)> walk = [&](Type *t2) {
    if (auto *st = dyn_cast<StructType>(t2)) {
      for (Type *e : st->elements())
        walk(e);
    } else if (auto *at = dyn_cast<ArrayType>(t2)) {
      for (uint64_t i = 0; i < at->getNumElements(); ++i)
        walk(at->getElementType());
    } else if (auto *vt = dyn_cast<FixedVectorType>(t2)) {
      if (DL.getTypeSizeInBits(vt->getElementType()).getFixedValue() % 8) {
        unpackLanes(ctx, vt, raw[k++], out);
      } else {
        for (unsigned i = 0; i < vt->getNumElements(); ++i)
          walk(vt->getElementType());
      }
    } else {
      out.push_back(raw[k++]);
    }
  };
  walk(ty);
  return out;
}

// One QROM template per leaf of the loaded value over the table, each at base + its offset with stride u.
SmallVector<Operand, 4> loadLeaves(LoweringContext &ctx, Type *ty, const Table &t, int64_t u) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  Type *i64 = Type::getInt64Ty(C);
  return fieldRails(ctx, ty, [&](const Leaf &l) {
    abi::TemplateSpec spec;
    spec.op = "qrom_load";
    spec.w = railTypeOf(l.ty);
    spec.strided = u != int64_t(DL.getTypeAllocSize(l.ty).getFixedValue());
    Value *base = l.off ? ctx.B().CreateGEP(Type::getInt8Ty(C), t.base, ConstantInt::get(i64, l.off)) : t.base;
    SmallVector<Operand, 4> ops{Operand{base, false}, Operand{t.n, false}};
    if (spec.strided)
      ops.push_back(Operand{ConstantInt::get(i64, u), false});
    ops.push_back(t.idx);
    return Operand{ctx.emitTemplate(spec, ops), true};
  });
}

bool isComposite(Type *t) { return t->isStructTy() || t->isArrayTy() || t->isVectorTy(); }

// Rule 20 over the general window (see generalTable).
void lowerGeneral(LoweringContext &ctx, LoadInst &ld, const QromShape &q) {
  Table t = generalTable(ctx, q, ld);
  SmallVector<Operand, 4> leaves = loadLeaves(ctx, ld.getType(), t, q.u);
  if (isComposite(ld.getType()))
    ctx.bindFields(&ld, leaves);
  else
    ctx.bind(&ld, leaves.front().v);
}

} // namespace

void lowerQromLoad(LoweringContext &ctx, LoadInst &ld) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  Type *i64 = Type::getInt64Ty(C);
  Type *ty = ld.getType();
  bool fnTable = ty->isPointerTy();
  if (isa<ScalableVectorType>(ty))
    internalError("mem-qrom: a scalable vector on x86-64 (rule 25)", &ld);
  {
    Addr a0 = decompose(ld.getPointerOperand(), DL, ld);
    if (isQ(ctx, a0.root) || ctx.T.isFatPointer(a0.root, ctx.S))
      return fatptr::lowerLoad(ctx, ld);   // rule 21: a quantum base is a fat pointer, its objects' QROMs
  }
  if (!fnTable && pointerLeaf(ty))
    unimplemented("mem-qrom: a QROM load of an aggregate holding a pointer (rule 21: a fat pointer whose (tag, idx) "
                  "tables over the object table are not built)",
                  &ld);

  QromShape q = analyze(ctx, ld);
  const Addr &a = q.a;

  if (q.terms.empty()) {
    // Every quantum term moves no byte (a zero-sized element): the address is classical, the load a host
    // read whose value is a seed rail (rule 7) per leaf.
    if (fnTable)
      unimplemented("mem-qrom: a function pointer read through a zero-sized quantum index (rule 19's tag table)", &ld);
    IRBuilder<> &B = ctx.B();
    Operand root = ctx.operand(a.root);
    Value *off = ConstantInt::get(i64, a.off, true);
    for (const Term &t : q.cterms)
      off = B.CreateAdd(off, B.CreateMul(B.CreateSExtOrTrunc(ctx.operand(t.idx).v, i64),
                                         ConstantInt::get(i64, t.stride, true)));
    Value *p = B.CreateGEP(Type::getInt8Ty(C), root.v, off);
    SmallVector<Operand, 4> ops = fieldRails(ctx, ty, [&](const Leaf &l) {
      Value *v = B.CreateLoad(l.ty, l.off ? B.CreateGEP(Type::getInt8Ty(C), p, ConstantInt::get(i64, l.off)) : p);
      CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(l.ty)}, {v});
      ctx.unc().recordSeed(seed);
      return Operand{seed, true};
    });
    if (isComposite(ty))
      ctx.bindFields(&ld, ops);
    else
      ctx.bind(&ld, ops.front().v);
    return;
  }

  if (!fnTable && (q.general || isComposite(ty)))
    return lowerGeneral(ctx, ld, q);

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
    if (q.general || !gv || !gv->isConstant() || !gv->hasDefinitiveInitializer() || !q.staticN)
      unimplemented("mem-qrom: a QROM of pointers over memory that is not a constant global with a known "
                    "initializer at a constant offset (the tag table would be derived at run time)",
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

  // Length.
  Value *n = nullptr;
  if (q.staticN) {
    n = ConstantInt::get(i64, *q.staticN);
  } else if (auto *ai = dyn_cast<AllocaInst>(a.root)) {
    int64_t E = int64_t(DL.getTypeAllocSize(ai->getAllocatedType()).getFixedValue());
    if (E % stride != 0 || off + size > stride)
      return lowerGeneral(ctx, ld, q);   // an element that is not a whole number of indexed cells
    Operand c = ctx.operand(ai->getArraySize());
    if (c.handle)
      internalError("mem-qrom: a VLA element count bound to a rail", ai);
    n = toI64(ctx, c.v);
    if (E != stride)
      n = ctx.B().CreateMul(n, ConstantInt::get(i64, E / stride));
  } else if (q.terms.size() == 1) {
    n = lengthFromRange(ctx, q.terms[0].idx, ld);
    if (!n)
      return lowerGeneral(ctx, ld, q);   // 2^64 or more cells
  } else {
    // Several non-negative terms: sum_k coef_k * umax_k + 1 cells.
    APInt cnt(256, 1);
    for (const QTerm &t : q.terms)
      cnt += indexUMax(t.idx, DL).zext(256) * APInt(256, uint64_t(t.coef));
    if (cnt.getActiveBits() > 64)
      return lowerGeneral(ctx, ld, q);   // 2^64 or more cells
    n = ConstantInt::get(i64, cnt.getZExtValue());
  }

  // Base.
  Operand root = ctx.operand(a.root);
  if (root.handle)
    internalError("mem-qrom: a QROM base pointer bound to a rail", a.root);
  Value *base = root.v;
  if (off != 0)
    base = ctx.B().CreateInBoundsGEP(Type::getInt8Ty(C), base, ConstantInt::get(i64, off));
  if (!ix.v)
    ix = linearIndex(ctx, q.terms, q.staticN, ld);

  abi::TemplateSpec spec;
  spec.op = "qrom_load";
  spec.w = w;
  spec.strided = stride != size;   // a struct-of-arrays column (78), or a stride below the element (a view)
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
  {
    Addr a0 = decompose(ld->getPointerOperand(), ctx.M.getDataLayout(), *ld);
    if (isQ(ctx, a0.root) || ctx.T.isFatPointer(a0.root, ctx.S))
      return out;
  }
  QromShape q = analyze(ctx, *ld);
  auto *gv = dyn_cast<GlobalVariable>(q.a.root);
  if (q.general || q.terms.empty() || !gv || !gv->isConstant() || !gv->hasDefinitiveInitializer() || !q.staticN)
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

// Rule 21 over classical memory: the QROM of a fat pointer's root (a classical pointer, a constant byte
// offset o from its object) at a rail cell index idx (idxBits wide, read signed when idxSext). The table is
// the window of cells idx can reach in-domain:
//  - an object of static extent: the object's cells, idx from lo = ceil(-o / size) (at least 0 for an
//    unsigned idx) to floor((bytes - size - o) / size) (cq-b244: a signed idx reaches the cells before
//    root); element i is cell lo + i, read at idx - lo, widened to cover n;
//  - memory of unknown extent: every value idx can take (rule 20's 2^W fallback), from -2^(W-1) for a
//    signed idx; a 64-bit idx over a power-of-two cell size 2^p (p >= 1) is read modulo 2^(64 - p) (the
//    address depends on nothing more); a byte or odd cell size there is awaiting owner ruling.
// fatptr splits a composite per leaf (leafOff: the leaf's byte offset in the element; the cell size is the
// element's, `cellBytes`, 0 = ty's own alloc size).
Value *qromLoadAt(LoweringContext &ctx, const Value *root, Operand idx, unsigned idxBits, bool idxSext, Type *ty,
                  const Instruction &at, uint64_t leafOff, uint64_t cellBytes) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  Type *i64 = Type::getInt64Ty(C);
  if (!idx.handle)
    internalError("mem-qrom: qromLoadAt at a classical index", &at);
  if (!(ty->isIntegerTy() || ty->isFloatingPointTy()))
    internalError("mem-qrom: qromLoadAt of a non-scalar (fatptr loads a pointer's fields and splits a composite "
                  "per leaf)",
                  &at);
  if (idxBits == 0 || idxBits > 64)
    internalError("mem-qrom: a fat-pointer QROM index of no width", &at);
  uint64_t esz = DL.getTypeAllocSize(ty).getFixedValue();
  uint64_t size = cellBytes ? cellBytes : esz;
  auto tmpl = [&](StringRef op, unsigned w, ArrayRef<Operand> ops, StringRef shape, std::optional<unsigned> to) {
    abi::TemplateSpec s;
    s.op = op.str();
    s.w = RailType{Kind::Int, w};
    if (to)
      s.to = RailType{Kind::Int, *to};
    s.shape = shape.str();
    return Operand{ctx.emitTemplate(s, ops), true};
  };
  Operand base = ctx.operand(root);
  if (base.handle)
    internalError("mem-qrom: a QROM base pointer bound to a rail", root);
  Value *table = base.v;
  APInt offA(64, 0);
  const Value *obj = root->stripAndAccumulateConstantOffsets(DL, offA, /*AllowNonInbounds=*/true);
  std::optional<uint64_t> bytes = staticBytes(obj, DL);
  uint64_t n;
  int64_t lo;   // the first cell of the table, relative to root
  unsigned W = idxBits;
  if (bytes) {
    int64_t o = offA.getSExtValue(), sz = int64_t(size), B = int64_t(*bytes);
    int64_t fl = o >= 0 ? o / sz : -((-o + sz - 1) / sz);   // floor(o / size)
    lo = -fl;
    if (!idxSext)
      lo = std::max<int64_t>(lo, 0);
    int64_t num = B - int64_t(esz) - int64_t(leafOff) - o;
    int64_t hi = num >= 0 ? num / sz : -((-num + sz - 1) / sz);
    n = hi - lo + 1 > 0 ? uint64_t(hi - lo + 1) : 0;
    W = std::max(idxBits, n > 1 ? Log2_64_Ceil(n) : 1u);
    if (W > 64)
      internalError("mem-qrom: a static object of more than 2^64 cells", &at);
  } else if (idxBits < 64) {
    lo = idxSext ? -(int64_t(1) << (idxBits - 1)) : 0;
    n = uint64_t(1) << idxBits;
  } else if (size > 1 && isPowerOf2_64(size)) {
    W = 64 - Log2_64(size);
    idx = tmpl("trunc", 64, {idx}, "", W);
    lo = 0;
    n = uint64_t(1) << W;
  } else {
    unimplemented("awaiting owner ruling: SPEC_ISSUES QROM of 2^64 cells (a byte or odd stride at an unbounded "
                  "64-bit index into memory of unknown extent has no i64 length)",
                  &at);
  }
  if (lo != 0 && W > idxBits)   // lo == 0: idx at its own width reads every in-domain cell
    idx = tmpl(idxSext ? "sext" : "zext", idxBits, {idx}, "", W);
  if (lo != 0)
    idx = tmpl("add", W, {idx, Operand{ConstantInt::get(C, APInt(W, uint64_t(-lo), /*isSigned=*/false)), false}},
               "hl", std::nullopt);
  int64_t first = lo * int64_t(size) + int64_t(leafOff);
  if (first != 0)
    table = bytes ? ctx.B().CreateInBoundsGEP(Type::getInt8Ty(C), table, ConstantInt::get(i64, first, true))
                  : ctx.B().CreateGEP(Type::getInt8Ty(C), table, ConstantInt::get(i64, first, true));
  abi::TemplateSpec spec;
  spec.op = "qrom_load";
  spec.w = railTypeOf(ty);
  spec.strided = size != esz;
  SmallVector<Operand, 4> ops{Operand{table, false}, Operand{ConstantInt::get(i64, n), false}};
  if (spec.strided)
    ops.push_back(Operand{ConstantInt::get(i64, size), false});
  ops.push_back(idx);
  return ctx.emitTemplate(spec, ops);
}

} // namespace cq::mem
