// Module mem-qram (cq-w1-mem-qram): QRAM objects (rule 20) and the memory intrinsics (rule 22).
//
// Built so far (cq-alez): llvm.memset over a SLOT array (rule 22, slot side). Every other entry of
// this module is still the wave 0 stub: an internal error naming the function.
//
// memset over a slot array. rule 22: memset works per CELL of the destination; with a classical length
// it is one ordinary update per cell, and for a slot array the update of a cell with a classical value
// is a seed rail (rule 7, rule 20 homogeneity), exactly what mem-slots' classical store emits. The cell
// layout is mem-slots' (pass/lib/mem/slots/Slots.cpp, CONTRACT): one i32 handle per cell, the cell is
// the scalar element of the object, ctx.operand(root) is the base of the handle cells, a _Bool object
// holds i1 rails. So:
//  - the destination is the object's root plus classical GEP offsets; its first cell is byte offset /
//    cell bytes, and the length covers length / cell bytes cells. A destination or length that is not
//    a whole number of cells is a bit view (63): unimplemented.
//  - the cell value is the fill byte repeated over the cell's bytes (an iN cell: the splat truncated to
//    N bits; a floating-point cell: the splat's bits), and for a _Bool cell trunc(byte) to i1.
//  - each cell gets its OWN seed cqrt_alloc_<W>(value) (58, 59, 116: the cells are registers that are
//    later rotated in place, so cells never share a rail), stored into its handle cell.
//  - a constant length is unrolled into one update per cell (116); a run-time length is a classical
//    loop over the cells (58, 59), guarded by "no cells" since nothing tells the pass the length is
//    non-zero. The builder is left in the loop's exit block, where the spine continues the block.
//  - roles follow mem-slots' store of a seed: into a local or heap object read back at a run-time cell
//    (DYNAMIC) the seed is a register, Role::UserRegister (58: "the n cells are user registers and stay
//    allocated"); into a parameter's cells in an entry, or an extern global, an output; into an escaping
//    object, a clone's parameter, or a STATIC local object, unimplemented. (A static object's loads all
//    forward from plain stores, so nothing reads the seed through SSA; a guarded store would read it
//    through the cell after uncompute freed it at its last SSA use, the store. A memset blocks
//    forwarding, so a load reading a memset cell always makes the object dynamic.)
//  - a memset under a quantum predicate (select(predicate, value, old) per cell), a quantum fill byte
//    or a quantum length (rule 22's guarded cells) are not built: unimplemented.
//
// The object predicates (_Bool cells, escaping, dynamic) are mem-slots' and private to Slots.cpp; they
// are restated below verbatim (the "addresses" to "isDynamic" sections) so that both modules classify
// an object the same way.
#include "cq/Memory.h"

#include <map>
#include <optional>
#include <string>
#include <utility>

#include "cq/Abi.h"
#include "cq/Predicate.h"
#include "cq/Uncompute.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/KnownBits.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq::mem {

namespace {

// ==== restated from pass/lib/mem/slots/Slots.cpp (mem-slots), keep in step ========================

// ---- addresses ----------------------------------------------------------------------------------

// root + off + sum(term * stride), all in bytes. ok = false when the root is not an object site
// (a phi, select or load of a pointer: no static cell index).
struct Addr {
  const Value *root = nullptr;
  int64_t off = 0;
  SmallVector<std::pair<const Value *, int64_t>, 2> terms;
  bool ok = false;
};

bool sameCell(const Addr &a, const Addr &b) {
  if (!a.ok || !b.ok || a.root != b.root || a.off != b.off || a.terms.size() != b.terms.size())
    return false;
  for (size_t i = 0; i < a.terms.size(); ++i)
    if (a.terms[i] != b.terms[i])
      return false;
  return true;
}

// Provably different cells of the same object: same variable part, different constant part.
bool differentCell(const Addr &a, const Addr &b, uint64_t sizeA, uint64_t sizeB) {
  if (!a.ok || !b.ok || a.root != b.root || a.terms.size() != b.terms.size())
    return false;
  for (size_t i = 0; i < a.terms.size(); ++i)
    if (a.terms[i] != b.terms[i])
      return false;
  return a.off + int64_t(sizeA) <= b.off || b.off + int64_t(sizeB) <= a.off;
}

Addr decompose(const Value *p, const DataLayout &DL) {
  Addr a;
  for (unsigned guard = 0; guard < 64; ++guard) {
    if (auto *g = dyn_cast<GEPOperator>(p)) {
      for (gep_type_iterator gti = gep_type_begin(g), e = gep_type_end(g); gti != e; ++gti) {
        const Value *idx = gti.getOperand();
        if (StructType *st = gti.getStructTypeOrNull()) {
          a.off += int64_t(DL.getStructLayout(st)->getElementOffset(cast<ConstantInt>(idx)->getZExtValue()));
          continue;
        }
        int64_t stride = int64_t(gti.getSequentialElementStride(DL).getFixedValue());
        if (auto *c = dyn_cast<ConstantInt>(idx)) {
          a.off += c->getSExtValue() * stride;
          continue;
        }
        if (isa<VectorType>(idx->getType()))
          return a;
        bool merged = false;
        for (auto &t : a.terms)
          if (t.first == idx) {
            t.second += stride;
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
    if (isa<AllocaInst>(p) || isa<Argument>(p) || isa<GlobalVariable>(p) || isa<CallBase>(p)) {
      a.root = p;
      a.ok = true;
      llvm::sort(a.terms, [](const auto &x, const auto &y) { return x.first < y.first; });
      return a;
    }
    return a;
  }
  return a;
}

// ---- per-object facts ---------------------------------------------------------------------------

enum class RootKind : uint8_t { Local, Heap, Param, Global };

struct ObjInfo {
  RootKind kind;
  const Value *root;
  uint64_t cellBytes = 0;
  bool boolCells = false;
  bool escaping = false;
  int dynamic = -1;   // -1 not computed
};

struct FnState {
  const Function *F = nullptr;
  std::unique_ptr<DominatorTree> DT;
  DenseMap<const Instruction *, Operand> lowered;   // slot load / store -> the handle the cell holds after it
  DenseSet<const Value *> registers;                // new-IR handles known never to be resolved here
  std::map<const Value *, ObjInfo> objs;
};

// One state per (output function, original function): rule 19 inlining lowers a callee's body into
// its caller's output function.
std::map<std::pair<const Function *, const Function *>, std::unique_ptr<FnState>> &states() {
  static std::map<std::pair<const Function *, const Function *>, std::unique_ptr<FnState>> s;
  return s;
}

FnState &stateOf(LoweringContext &ctx, const Instruction &I) {
  const Function *F = I.getFunction();
  auto &p = states()[{&ctx.out(), F}];
  if (!p) {
    p = std::make_unique<FnState>();
    p->F = F;
    p->DT = std::make_unique<DominatorTree>(const_cast<Function &>(*F));
  }
  return *p;
}

bool hasObject(LoweringContext &ctx, const Value *ptr, ObjectId o) {
  if (!ptr->getType()->isPointerTy())
    return false;
  for (ObjectId x : ctx.T.provenance(ptr, ctx.S))
    if (x == o)
      return true;
  return false;
}

bool isCqSurface(const CallBase &CB) {
  const Function *f = CB.getCalledFunction();
  return f && f->getName().starts_with("cq_");
}

// The plain loads and stores of the object in F, with their addresses.
struct Access { const Instruction *I; Addr a; Type *ty; };

SmallVector<Access, 8> accessesOf(LoweringContext &ctx, const Function &F, ObjectId o) {
  const DataLayout &DL = ctx.M.getDataLayout();
  SmallVector<Access, 8> out;
  for (const Instruction &I : instructions(F)) {
    if (auto *ld = dyn_cast<LoadInst>(&I)) {
      if (hasObject(ctx, ld->getPointerOperand(), o))
        out.push_back({ld, decompose(ld->getPointerOperand(), DL), ld->getType()});
    } else if (auto *st = dyn_cast<StoreInst>(&I)) {
      if (hasObject(ctx, st->getPointerOperand(), o))
        out.push_back({st, decompose(st->getPointerOperand(), DL), st->getValueOperand()->getType()});
    }
  }
  return out;
}

bool isFree(const CallBase &CB) {
  const Function *f = CB.getCalledFunction();
  AllocFnKind k = f ? f->getAttributes().getFnAttrs().getAllocKind() : AllocFnKind::Unknown;
  return (k & AllocFnKind::Free) != AllocFnKind::Unknown;
}

bool escapes(const Value *root) {
  SmallVector<const Value *, 8> work{root};
  SmallPtrSet<const Value *, 16> seen{root};
  while (!work.empty()) {
    const Value *v = work.pop_back_val();
    for (const Use &u : v->uses()) {
      const User *usr = u.getUser();
      if (auto *ld = dyn_cast<LoadInst>(usr)) {
        if (ld->getPointerOperand() == v)
          continue;
        return true;
      }
      if (auto *st = dyn_cast<StoreInst>(usr)) {
        if (st->getPointerOperand() == v && st->getValueOperand() != v)
          continue;
        return true;
      }
      if (isa<GetElementPtrInst>(usr) || isa<BitCastInst>(usr) || isa<AddrSpaceCastInst>(usr) ||
          isa<PHINode>(usr) || isa<SelectInst>(usr) || isa<GEPOperator>(usr)) {
        if (seen.insert(usr).second)
          work.push_back(usr);
        continue;
      }
      if (isa<ICmpInst>(usr))
        continue;
      if (auto *CB = dyn_cast<CallBase>(usr)) {
        if (isa<DbgInfoIntrinsic>(CB) || isa<MemIntrinsic>(CB) || isCqSurface(*CB))
          continue;
        if (isFree(*CB) && CB->arg_size() && CB->getArgOperand(0) == v)
          continue;   // the end of a heap block's lifetime, not an escape
        if (auto *II = dyn_cast<IntrinsicInst>(CB))
          if (II->getIntrinsicID() == Intrinsic::lifetime_start || II->getIntrinsicID() == Intrinsic::lifetime_end)
            continue;
        return true;
      }
      return true;
    }
  }
  return false;
}

bool boolValueStored(const Value *v) {
  if (auto *z = dyn_cast<ZExtInst>(v))
    return z->getSrcTy()->isIntegerTy(1);
  if (auto *c = dyn_cast<ConstantInt>(v))
    return c->getBitWidth() == 8 && c->getZExtValue() <= 1;
  return false;
}

bool boolRange(const LoadInst *ld) {
  MDNode *r = ld->getMetadata(LLVMContext::MD_range);
  if (!r || r->getNumOperands() != 2)
    return false;
  auto *lo = mdconst::dyn_extract<ConstantInt>(r->getOperand(0));
  auto *hi = mdconst::dyn_extract<ConstantInt>(r->getOperand(1));
  return lo && hi && lo->isZero() && hi->getZExtValue() == 2;
}

uint64_t scalarCellBytes(Type *t, const DataLayout &DL, const Value *at) {
  while (auto *at2 = dyn_cast<ArrayType>(t))
    t = at2->getElementType();
  if (t->isStructTy())
    unimplemented("mem-slots: a slot record (a struct object holding handles: sret/byval, rule 20, 163, 164)", at);
  if (t->isVectorTy())
    unimplemented("mem-slots: a slot object of vector type (aggr, rule 25)", at);
  if (!t->isIntegerTy() && !t->isFloatingPointTy())
    unimplemented("mem-slots: a slot object whose cells are not integers or floating point (pointers in a "
                  "handle object)",
                  at);
  return DL.getTypeAllocSize(t).getFixedValue();
}

ObjInfo &objInfo(LoweringContext &ctx, FnState &st, const Value *root, ObjectId o) {
  auto it = st.objs.find(root);
  if (it != st.objs.end())
    return it->second;
  const DataLayout &DL = ctx.M.getDataLayout();
  ObjInfo info;
  info.root = root;
  if (auto *ai = dyn_cast<AllocaInst>(root)) {
    info.kind = RootKind::Local;
    info.cellBytes = scalarCellBytes(ai->getAllocatedType(), DL, ai);
  } else if (auto *gv = dyn_cast<GlobalVariable>(root)) {
    info.kind = RootKind::Global;
    info.cellBytes = scalarCellBytes(gv->getValueType(), DL, gv);
  } else {
    info.kind = isa<Argument>(root) ? RootKind::Param : RootKind::Heap;
    for (const Access &a : accessesOf(ctx, *st.F, o)) {
      uint64_t b = DL.getTypeAllocSize(a.ty).getFixedValue();
      if (info.cellBytes && info.cellBytes != b)
        unimplemented("mem-slots: a parameter or heap slot object accessed at two widths (a bit view, 63)", a.I);
      info.cellBytes = b;
    }
    if (!info.cellBytes)
      unimplemented("mem-slots: a parameter or heap slot object this function never loads or stores (its cell "
                    "size is known only to another function)",
                    root);
  }
  info.escaping = escapes(root);
  if (info.cellBytes == 1) {
    bool any = false, all = true;
    for (const Access &a : accessesOf(ctx, *st.F, o)) {
      any = true;
      if (auto *ld = dyn_cast<LoadInst>(a.I))
        all &= boolRange(ld);
      else
        all &= boolValueStored(cast<StoreInst>(a.I)->getValueOperand());
    }
    info.boolCells = any && all;
  }
  return st.objs.emplace(root, info).first->second;
}

// ---- may-write and forwarding -------------------------------------------------------------------

bool mayWrite(LoweringContext &ctx, const ObjInfo &info, ObjectId o, const Instruction &I, const Addr &cell,
              uint64_t size) {
  const DataLayout &DL = ctx.M.getDataLayout();
  if (auto *st = dyn_cast<StoreInst>(&I)) {
    if (!hasObject(ctx, st->getPointerOperand(), o))
      return false;
    Addr a = decompose(st->getPointerOperand(), DL);
    return !differentCell(a, cell, DL.getTypeStoreSize(st->getValueOperand()->getType()).getFixedValue(), size);
  }
  if (isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I))
    return hasObject(ctx, I.getOperand(0), o);
  auto *CB = dyn_cast<CallBase>(&I);
  if (!CB || isa<DbgInfoIntrinsic>(CB) || isCqSurface(*CB))
    return false;
  if (auto *II = dyn_cast<IntrinsicInst>(CB)) {
    if (II->getIntrinsicID() == Intrinsic::lifetime_start || II->getIntrinsicID() == Intrinsic::lifetime_end)
      return hasObject(ctx, II->getArgOperand(1), o);
  }
  if (auto *MI = dyn_cast<MemIntrinsic>(CB))
    return hasObject(ctx, MI->getDest(), o);
  if (CB->onlyReadsMemory())
    return false;
  if (info.escaping || info.kind == RootKind::Param || info.kind == RootKind::Global)
    return true;
  for (const Use &u : CB->args())
    if (hasObject(ctx, u.get(), o))
      return true;
  return false;
}

// Blocks on a path from S's block to L's block that does not re-enter S's block (a path that re-enters
// it re-executes S, whose write is then the one that reaches L). L's block is included.
SmallPtrSet<const BasicBlock *, 16> between(const BasicBlock *BS, const BasicBlock *BL) {
  SmallPtrSet<const BasicBlock *, 16> fwd, back;
  SmallVector<const BasicBlock *, 16> work;
  for (const BasicBlock *s : successors(BS))
    if (s != BS && fwd.insert(s).second)
      work.push_back(s);
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    for (const BasicBlock *s : successors(b))
      if (s != BS && fwd.insert(s).second)
        work.push_back(s);
  }
  back.insert(BL);
  work.push_back(BL);
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    for (const BasicBlock *p : predecessors(b))
      if (p != BS && back.insert(p).second)
        work.push_back(p);
  }
  SmallPtrSet<const BasicBlock *, 16> mid;
  for (const BasicBlock *b : fwd)
    if (back.count(b))
      mid.insert(b);
  return mid;
}

bool onCycleWithin(const BasicBlock *b, const SmallPtrSet<const BasicBlock *, 16> &mid) {
  SmallPtrSet<const BasicBlock *, 16> seen;
  SmallVector<const BasicBlock *, 16> work;
  for (const BasicBlock *s : successors(b))
    if (mid.count(s) && seen.insert(s).second)
      work.push_back(s);
  while (!work.empty()) {
    const BasicBlock *x = work.pop_back_val();
    if (x == b)
      return true;
    for (const BasicBlock *s : successors(x))
      if (mid.count(s) && seen.insert(s).second)
        work.push_back(s);
  }
  return false;
}

// No write to the cell between S and L (S dominates L), and the cell's address names the same cell at
// both. In one block only the segment between them counts: leaving the block re-enters it at its top
// and re-executes S.
bool clearBetween(LoweringContext &ctx, const ObjInfo &info, ObjectId o, const Instruction *S,
                  const Instruction *L, const Addr &cell, uint64_t size) {
  const BasicBlock *BS = S->getParent(), *BL = L->getParent();
  auto writes = [&](BasicBlock::const_iterator from, BasicBlock::const_iterator to) {
    for (auto it = from; it != to; ++it)
      if (&*it != S && &*it != L && mayWrite(ctx, info, o, *it, cell, size))
        return true;
    return false;
  };
  if (BS == BL)
    return !writes(std::next(S->getIterator()), L->getIterator());
  SmallPtrSet<const BasicBlock *, 16> mid = between(BS, BL);
  // The cell is the same one at S and at L only if no value of its address is redefined in between
  // (a loop header's phi that a path from S to L passes again).
  auto redefined = [&](const Value *v) {
    auto *I = dyn_cast<Instruction>(v);
    return I && mid.count(I->getParent());
  };
  if (redefined(cell.root))
    return false;
  for (auto &t : cell.terms)
    if (redefined(t.first))
      return false;
  if (writes(std::next(S->getIterator()), BS->end()))
    return false;
  for (const BasicBlock *b : mid) {
    if (b == BL && !onCycleWithin(BL, mid)) {
      if (writes(BL->begin(), L->getIterator()))
        return false;
      continue;
    }
    if (writes(b->begin(), b->end()))
      return false;
  }
  return true;
}

// The dominating plain access of the same cell whose handle L reads, if any (structural: it does not
// look at what has been lowered yet).
const Instruction *sourceOf(LoweringContext &ctx, FnState &st, const ObjInfo &info, ObjectId o,
                            const Instruction *L, const Addr &cell, Type *ty) {
  if (!cell.ok)
    return nullptr;
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t size = DL.getTypeStoreSize(ty).getFixedValue();
  const Instruction *best = nullptr;
  for (const Access &a : accessesOf(ctx, *st.F, o)) {
    if (a.I == L || a.ty != ty || !sameCell(a.a, cell))
      continue;
    if (auto *ld = dyn_cast<LoadInst>(a.I); ld && (ld->isVolatile() || ld->isAtomic()))
      continue;
    if (auto *s = dyn_cast<StoreInst>(a.I); s && (s->isVolatile() || s->isAtomic()))
      continue;
    if (ctx.T.isFatPointer(getLoadStorePointerOperand(a.I), ctx.S))
      continue;
    if (!st.DT->dominates(a.I, L))
      continue;
    if (!clearBetween(ctx, info, o, a.I, L, cell, size))
      continue;
    if (!best || st.DT->dominates(best, a.I))
      best = a.I;
  }
  return best;
}

bool isDynamic(LoweringContext &ctx, FnState &st, ObjInfo &info, ObjectId o) {
  if (info.dynamic >= 0)
    return info.dynamic;
  info.dynamic = 0;
  for (const Access &a : accessesOf(ctx, *st.F, o))
    if (isa<LoadInst>(a.I) && !sourceOf(ctx, st, info, o, a.I, a.a, a.ty))
      info.dynamic = 1;
  return info.dynamic;
}


// ==== end of the restatement ======================================================================

// The scalar type of a cell (mem-slots' cell: arrays stripped; a parameter or heap block: the type its
// accesses use, which objInfo has checked to be one width).
Type *cellType(LoweringContext &ctx, FnState &st, const ObjInfo &info, ObjectId o) {
  Type *t = nullptr;
  if (auto *ai = dyn_cast<AllocaInst>(info.root))
    t = ai->getAllocatedType();
  else if (auto *gv = dyn_cast<GlobalVariable>(info.root))
    t = gv->getValueType();
  else
    for (const Access &a : accessesOf(ctx, *st.F, o))
      if (!t || a.ty == t)
        t = a.ty;
      else
        unimplemented("mem-qram: a memset of a parameter or heap slot object accessed as two types of one width",
                      a.I);
  while (auto *at = dyn_cast<ArrayType>(t))
    t = at->getElementType();
  return t;
}

// The cell value the fill byte b gives (classical): b repeated over the cell's bytes.
Value *fillValue(LoweringContext &ctx, Value *b, Type *cellTy, const ObjInfo &info, RailType w) {
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  if (info.boolCells)
    return B.CreateTrunc(b, Type::getInt1Ty(C));
  unsigned storeBits = unsigned(ctx.M.getDataLayout().getTypeStoreSize(cellTy).getFixedValue()) * 8;
  IntegerType *wide = IntegerType::get(C, storeBits);
  Value *splat = B.CreateMul(B.CreateZExt(b, wide), ConstantInt::get(wide, APInt::getSplat(storeBits, APInt(8, 1))));
  unsigned bits = unsigned(cellTy->getPrimitiveSizeInBits().getFixedValue());
  Value *v = B.CreateTrunc(splat, IntegerType::get(C, bits));
  if (!cellTy->isIntegerTy())
    v = B.CreateBitCast(v, cellTy);
  if (v->getType() != irTypeOf(C, w))
    internalError("mem-qram: a memset fill value of another type than its cell's rail");
  return v;
}

// The new-IR i32 cell pointer of cell `idx` (i64) of the object (mem-slots' cellPointer, at a run-time
// cell index).
Value *cellAt(LoweringContext &ctx, const ObjInfo &info, Value *idx, const Instruction &I) {
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  Operand base = ctx.operand(info.root);
  if (base.handle)
    internalError("mem-qram: the base of a slot object is a rail", &I);
  Type *i64 = Type::getInt64Ty(C);
  if (info.kind == RootKind::Global && info.cellBytes != 4) {
    if (info.cellBytes < 4)
      unimplemented("mem-qram: a memset of a global slot object with cells narrower than a handle", &I);
    return B.CreateInBoundsGEP(Type::getInt8Ty(C), base.v, B.CreateMul(idx, ConstantInt::get(i64, info.cellBytes)));
  }
  return B.CreateInBoundsGEP(Type::getInt32Ty(C), base.v, idx);
}

// A byte count that is provably a whole number of cells.
bool wholeCells(const Value *len, uint64_t cb, const DataLayout &DL) {
  if (cb == 1)
    return true;
  if (auto *c = dyn_cast<ConstantInt>(len))
    return c->getZExtValue() % cb == 0;
  if (!isPowerOf2_64(cb))
    return false;
  return computeKnownBits(len, DL).countMinTrailingZeros() >= Log2_64(cb);
}

// Rule 22 over a slot array: one seed per cell (see the file header).
void lowerSlotMemset(LoweringContext &ctx, MemSetInst &MS, ObjectId o) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  IRBuilder<> &B = ctx.B();
  FnState &st = stateOf(ctx, MS);
  if (ctx.currentFlag())
    unimplemented("mem-qram: a memset of a slot object under a quantum predicate (rules 9, 20, 22: each cell "
                  "becomes select(predicate, value, old))",
                  &MS);
  Addr a = decompose(MS.getDest(), DL);
  if (!a.ok)
    unimplemented("mem-qram: a memset of a slot object whose destination is not an object plus GEP offsets", &MS);
  if (ctx.T.objectOf(a.root) != o)
    internalError("mem-qram: the memset destination's root is not the object taint names", &MS);
  ObjInfo &info = objInfo(ctx, st, a.root, o);
  Type *cellTy = cellType(ctx, st, info, o);
  RailType w = info.boolCells ? RailType{Kind::Int, 1} : railTypeOf(cellTy);
  int64_t cb = int64_t(info.cellBytes);

  Operand fill = ctx.operand(MS.getValue());
  if (fill.handle)
    unimplemented("mem-qram: a memset of a slot object with a quantum fill byte (rule 22)", &MS);
  Operand len = ctx.operand(MS.getLength());
  if (len.handle)
    unimplemented("mem-qram: a memset of a slot object with a quantum length (rule 22's guarded cells)", &MS);
  if (a.off % cb)
    unimplemented("mem-qram: a memset of a slot object starting inside a cell (a bit view, 63)", &MS);
  if (!wholeCells(MS.getLength(), uint64_t(cb), DL))
    unimplemented("mem-qram: a memset of a slot object over a length that is not a whole number of cells (a bit "
                  "view, 63)",
                  &MS);

  // The role every seed takes (mem-slots' lowerSlotStore of a seed).
  std::optional<Role> role;
  switch (info.kind) {
  case RootKind::Local:
  case RootKind::Heap:
    if (info.escaping)
      unimplemented("mem-qram: a memset of a slot object whose pointer escapes to a call (its seeds' clean-up is "
                    "the callee twin's: rule 18, 31, 106)",
                    &MS);
    if (!isDynamic(ctx, st, info, o))
      unimplemented("mem-qram: a memset of a slot object no load reads back at a run-time cell (its seeds are "
                    "freed at their store while a guarded store may still read them from the cell)",
                    &MS);
    role = Role::UserRegister;
    break;
  case RootKind::Param:
    if (!ctx.S.isEntry())
      unimplemented("mem-qram: a memset of a caller's slot cells from a clone (rule 18 copy-out and twin, 31)", &MS);
    role = Role::Output;
    break;
  case RootKind::Global:
    if (!cast<GlobalVariable>(info.root)->hasLocalLinkage())
      role = Role::Output;   // an extern global is an output (71)
    break;
  }

  Type *i64 = Type::getInt64Ty(C);
  // The first cell: the destination's offset in cells.
  Value *first = nullptr;
  for (auto &[v, stride] : a.terms) {
    if (stride % cb)
      unimplemented("mem-qram: a memset destination GEP stride that is not a whole number of cells", &MS);
    Operand x = ctx.operand(v);
    if (x.handle)
      unimplemented("mem-qram: a memset of a slot object at a quantum offset (QRAM, rule 20)", &MS);
    Value *t = B.CreateSExtOrTrunc(x.v, i64);
    if (stride / cb != 1)
      t = B.CreateMul(t, ConstantInt::get(i64, stride / cb, true));
    first = first ? B.CreateAdd(first, t) : t;
  }
  if (a.off || !first) {
    Value *k = ConstantInt::get(i64, a.off / cb, true);
    first = first ? B.CreateAdd(first, k) : k;
  }

  Value *value = fillValue(ctx, fill.v, cellTy, info, w);
  auto cellIndex = [&](Value *j) {   // first + j, without a no-op add
    if (auto *c = dyn_cast<ConstantInt>(first); c && c->isZero())
      return j;
    return B.CreateAdd(first, j);
  };
  auto writeCell = [&](Value *idx) {
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {value});
    RailId id = ctx.unc().recordSeed(seed);
    if (role)
      ctx.unc().setRole(id, *role);
    B.CreateAlignedStore(seed, cellAt(ctx, info, idx, MS), Align(4));
  };

  if (auto *cl = dyn_cast<ConstantInt>(len.v)) {
    uint64_t n = cl->getZExtValue() / uint64_t(cb);
    for (uint64_t j = 0; j < n; ++j)
      writeCell(cellIndex(ConstantInt::get(i64, j)));
    return;
  }

  if (!role)
    unimplemented("mem-qram: a run-time-length memset of a slot object whose seeds are freed (an internal-linkage "
                  "global): the loop's seeds would need a reverse loop",
                  &MS);
  Value *n = B.CreateZExtOrTrunc(len.v, i64);
  if (cb != 1)
    n = B.CreateLShr(n, ConstantInt::get(i64, Log2_64(uint64_t(cb))), "", /*isExact=*/true);
  Function *F = &ctx.out();
  BasicBlock *pre = B.GetInsertBlock();
  BasicBlock *body = BasicBlock::Create(C, "", F);
  BasicBlock *done = BasicBlock::Create(C, "", F);
  B.CreateCondBr(B.CreateICmpEQ(n, ConstantInt::get(i64, 0)), done, body);
  B.SetInsertPoint(body);
  PHINode *j = B.CreatePHI(i64, 2);
  j->addIncoming(ConstantInt::get(i64, 0), pre);
  writeCell(cellIndex(j));
  Value *j1 = B.CreateAdd(j, ConstantInt::get(i64, 1), "", /*HasNUW=*/true, /*HasNSW=*/true);
  j->addIncoming(j1, body);
  B.CreateCondBr(B.CreateICmpEQ(j1, n), done, body);
  B.SetInsertPoint(done);
}

} // namespace

void lowerMemIntrinsic(LoweringContext &ctx, MemIntrinsic &MI) {
  if (auto *MS = dyn_cast<MemSetInst>(&MI)) {
    ArrayRef<ObjectId> objs = ctx.T.provenance(MS->getDest(), ctx.S);
    if (objs.size() == 1 && ctx.T.classOf(objs.front()) == ObjClass::Slot)
      return lowerSlotMemset(ctx, *MS, objs.front());
  }
  unimplemented("mem-qram: mem::lowerMemIntrinsic", &MI);
}

void lowerQramLoad(LoweringContext &, LoadInst &) { unimplemented("mem-qram: mem::lowerQramLoad"); }
void lowerQramStore(LoweringContext &, StoreInst &) { unimplemented("mem-qram: mem::lowerQramStore"); }
void allocateQram(LoweringContext &, Instruction &) { unimplemented("mem-qram: mem::allocateQram"); }
void endQramLifetime(LoweringContext &, ObjectId, Instruction *) { unimplemented("mem-qram: mem::endQramLifetime"); }
} // namespace cq::mem
