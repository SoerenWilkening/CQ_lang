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
//      root + off + idx * stride        (bytes; off a constant, root a classical pointer)
//    with exactly ONE variable term, whose index is quantum. A second quantum term (a flattened 2-D
//    index, 120), a classical variable term next to the quantum one, a quantum root, a negative or
//    non-constant byte offset, a stride below the element size (a bit view) are unimplemented.
//  - Index operand: the logical index rail (rule 20). The GEP's index is stripped of the zext (any)
//    and of a sext whose operand is known non-negative or that indexes a known object from its start
//    (a negative index there is outside the object: undefined, outside the domain). The `zext`,
//    `sext` and GEP scaling are address arithmetic: the rail is the stripped value's rail, at its
//    own width. A sext of a possibly negative index into memory of unknown extent (t[i], i < 0, is
//    legal C) is unimplemented: the unsigned QROM index would read 0 there.
//  - Form. stride == size: the plain form over base = root + off. Otherwise the strided form over
//    base = root + off (the field of a struct-of-arrays column, 78). base is root itself when off is
//    0, else one classical `getelementptr inbounds i8, root, off`.
//  - Length n (rule 20: the cell count when known, else the index's upper bound from range facts,
//    else 2^W of the index):
//      * root a global with a sized value type, or a static alloca: bytes = its alloc size;
//        n = (bytes - off - size) / stride + 1 elements (0 when the first element does not fit);
//      * root a dynamic alloca (VLA, 74) whose allocated type is one element (its alloc size is the
//        stride) and off < stride: n = its element count operand, zext to i64. Any other dynamic
//        alloca is unimplemented;
//      * anything else (a parameter, a loaded pointer, a heap block, a global of unsized or zero
//        size): an index `urem a, d` with d classical gives n = zext(d) (76); otherwise
//        n = umin(computeConstantRange, computeKnownBits) upper bound + 1 of the stripped index
//        (2^W when neither proves anything); a bound of 2^64 or more is unimplemented.
//  - Result type: an integer or floating-point load (railTypeOf). A pointer load (a table of
//    pointers or callee tags, rules 18 and 21), a vector or an aggregate is unimplemented.
//  - Predicate: none needed. The QROM reads 0 at an index >= n (§2), touches no state, and its
//    result is a value arm like any template under a quantum predicate.
#include "cq/Memory.h"

#include <algorithm>
#include <optional>
#include <string>

#include "cq/Abi.h"
#include "llvm/ADT/SmallVector.h"
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

} // namespace

void lowerQromLoad(LoweringContext &ctx, LoadInst &ld) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  Type *i64 = Type::getInt64Ty(C);
  Type *ty = ld.getType();
  if (!(ty->isIntegerTy() || ty->isFloatingPointTy()))
    unimplemented("mem-qrom: a QROM load of a non-scalar or pointer value (rules 18, 21)", &ld);
  RailType w = railTypeOf(ty);
  int64_t size = int64_t(DL.getTypeAllocSize(ty).getFixedValue());

  Addr a = decompose(ld.getPointerOperand(), DL, ld);
  if (isQ(ctx, a.root) || ctx.T.isFatPointer(a.root, ctx.S))
    unimplemented("mem-qrom: a QROM whose base pointer is quantum (rule 21)", &ld);
  const Term *q = nullptr;
  for (const Term &t : a.terms) {
    if (!isQ(ctx, t.idx))
      unimplemented("mem-qrom: a classical variable index next to the quantum one in a QROM address", &ld);
    if (q)
      unimplemented("mem-qrom: a QROM address with two quantum indices (flattened 2-D form, 120)", &ld);
    q = &t;
  }
  if (!q)
    internalError("mem-qrom: a quantum-offset load whose address has no quantum index", &ld);
  int64_t stride = q->stride, off = a.off;
  if (off < 0)
    unimplemented("mem-qrom: a QROM address with a negative constant byte offset", &ld);
  if (stride < size)
    unimplemented("mem-qrom: a QROM stride below the element size (a bit view, or a negative stride)", &ld);

  // The logical index: the GEP index stripped of its widening casts (address arithmetic, rule 20).
  const Value *idx = q->idx;
  for (;;) {
    if (auto *z = dyn_cast<ZExtInst>(idx); z && isQ(ctx, z->getOperand(0))) {
      idx = z->getOperand(0);
      continue;
    }
    if (auto *s = dyn_cast<SExtInst>(idx); s && isQ(ctx, s->getOperand(0))) {
      bool nonNeg = isKnownNonNegative(s->getOperand(0), SimplifyQuery(DL));
      if (!nonNeg && !(knownObject(a.root) && off == 0))
        unimplemented("mem-qrom: a sign-extended quantum index into memory of unknown extent (a negative "
                      "index would read 0)",
                      &ld);
      idx = s->getOperand(0);
      continue;
    }
    break;
  }
  if (!idx->getType()->isIntegerTy())
    internalError("mem-qrom: a QROM index that is not an integer", &ld);
  Operand ix = ctx.operand(idx);
  if (!ix.handle)
    internalError("mem-qrom: the logical QROM index is not a rail", idx);

  // Base.
  Operand root = ctx.operand(a.root);
  if (root.handle)
    internalError("mem-qrom: a QROM base pointer bound to a rail", a.root);
  Value *base = root.v;
  if (off != 0)
    base = ctx.B().CreateInBoundsGEP(Type::getInt8Ty(C), base, ConstantInt::get(i64, off));

  // Length.
  Value *n = nullptr;
  if (std::optional<uint64_t> bytes = staticBytes(a.root, DL)) {
    uint64_t cnt = *bytes >= uint64_t(off + size) ? (*bytes - uint64_t(off) - uint64_t(size)) / uint64_t(stride) + 1 : 0;
    n = ConstantInt::get(i64, cnt);
  } else if (auto *ai = dyn_cast<AllocaInst>(a.root)) {
    if (int64_t(DL.getTypeAllocSize(ai->getAllocatedType()).getFixedValue()) != stride || off >= stride)
      unimplemented("mem-qrom: a QROM over a dynamic alloca whose element is not the indexed stride", &ld);
    Operand c = ctx.operand(ai->getArraySize());
    if (c.handle)
      internalError("mem-qrom: a VLA element count bound to a rail", ai);
    n = toI64(ctx, c.v);
  } else {
    n = lengthFromRange(ctx, idx, ld);
  }

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

} // namespace cq::mem
