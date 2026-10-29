// Module mem-qram (cq-w1-mem-qram): QRAM objects (rule 20) and the memory intrinsics (rule 22).
//
// Built: QRAM objects (cq-w1-mem-qram) and llvm.memset over a SLOT array (cq-alez). Every other memory
// intrinsic is still an internal error.
//
// QRAM (rule 20, CR §1.3, BACKEND_ABI §1.10). CONTRACT:
//  - Allocation. A local QRAM (alloca, static or runtime element count) is ONE cqrt_qram_alloc_<W>(n)
//    at the alloca, W the scalar cell type (arrays stripped), n its cell count; the bus is recorded with
//    Uncompute (Role::Seed), which pops its stores and emits cqrt_qram_free once nothing reads it. The
//    original alloca is bound to the object's QRAM base address (rule 21: inttoptr of
//    0x4000_0000_0000_0000 + 0x1000 * ObjectId), a classical constant. The bus handle is private to
//    this module. lifetime.end emits nothing. A heap QRAM, a QRAM reached through a parameter, an
//    object whose pointer escapes to a call, and a site allocated twice in one output function are
//    unimplemented.
//  - A global QRAM (any linkage, 160) is allocated once by a module constructor
//    __cq_qram_init_<global> (llvm.global_ctors, priority 65535): cqrt_qram_alloc_<W>(n), each non-zero
//    initializer cell stored by cqrt_qram_store_<W>_hl of a seed freed at once, the handle stored in
//    the global's first 4 bytes (the global keeps its type). Each output function that accesses it
//    loads the handle once at its entry, recorded as Role::Output: its stores are never popped and it
//    is never freed.
//  - Access. ONE call per load or store. The index is the logical quantum index rail (one quantum GEP
//    term of stride one cell, its zext/sext stripped, no other offset) or a classical i32 cell index
//    j (the _hl form). A load is cqrt_qram_load_<W>[_hl](a, idx | j), unguarded, recorded with
//    recordCore (its _unc is Uncompute's); a store is cqrt_qram_store_<W>[_hl][_controlled]([flag,] a,
//    idx | j, v) under the current flag, v a handle (a classical value becomes a recorded seed first),
//    recorded on the bus. The pop order is Uncompute's (cq-w6ie: per-store pops, A2).
//  - An access at another type than the cell (a bit view), a quantum index with an added offset or a
//    scaled stride, two quantum index terms (191), or a pointer/aggregate value is unimplemented.
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

#include <functional>
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
#include "llvm/Transforms/Utils/ModuleUtils.h"

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

// ==== QRAM objects (rule 20) ======================================================================

// The facts of one QRAM object as this output function sees it.
struct QramObj {
  const Value *root = nullptr;
  ObjectId o = 0;
  Type *cellTy = nullptr;
  uint64_t cellBytes = 0;
  RailType w{};
  Value *handle = nullptr;   // the bus a (new IR)
};

struct QramState {
  std::map<const Value *, QramObj> objs;   // original root -> object
};

std::map<const Function *, QramState> &qramStates() {
  static std::map<const Function *, QramState> s;
  return s;
}

// The scalar cell type of a sized object type (arrays stripped).
Type *scalarCell(Type *t, const Value *at) {
  while (auto *a = dyn_cast<ArrayType>(t))
    t = a->getElementType();
  if (t->isStructTy())
    unimplemented("mem-qram: a QRAM object of struct type (one object per field column, rule 26, 168)", at);
  if (t->isVectorTy())
    unimplemented("mem-qram: a QRAM object of vector type (aggr, rule 25)", at);
  if (!t->isIntegerTy() && !t->isFloatingPointTy())
    unimplemented("mem-qram: a QRAM object whose cells are not integers or floating point (a QRAM of pointers, "
                  "rule 21)",
                  at);
  return t;
}

// The object a QRAM access or allocation site names: exactly one object of class Qram.
ObjectId soleQram(LoweringContext &ctx, const Value *ptr, const Instruction &I) {
  ArrayRef<ObjectId> objs = ctx.T.provenance(ptr, ctx.S);
  if (objs.size() != 1)
    unimplemented("mem-qram: a QRAM access or site whose pointer has " + std::to_string(objs.size()) +
                      " objects (rule 21 fat pointer, or a field-column split)",
                  &I);
  if (ctx.T.classOf(objs.front()) != ObjClass::Qram)
    internalError("mem-qram: the object is not a QRAM", &I);
  return objs.front();
}

// The classical base address of a QRAM object (rule 21): 0x4000_0000_0000_0000 + 0x1000 * n, a
// non-canonical x86-64 address no host pointer takes. The original pointer is bound to it, so any
// classical use of the pointer (a compare, a ptrtoint) sees a unique, exact address.
Constant *qramBase(LoweringContext &ctx, ObjectId o) {
  LLVMContext &C = ctx.M.getContext();
  uint64_t a = 0x4000000000000000ull + 0x1000ull * uint64_t(o);
  return ConstantExpr::getIntToPtr(ConstantInt::get(Type::getInt64Ty(C), a), PointerType::get(C, 0));
}

// Rule 20: a global QRAM is allocated ONCE by a module constructor (160): cqrt_qram_alloc_<W>(n), the
// handle kept in the global's first four bytes (a classical word), and each non-zero element of the
// initializer stored by its own _hl store of a seed that is freed at once (the store copies it; a
// global QRAM's stores are never popped).
void ensureGlobalCtor(LoweringContext &ctx, GlobalVariable &gv, const QramObj &q) {
  Module &M = ctx.M;
  LLVMContext &C = M.getContext();
  std::string name = ("__cq_qram_init_" + gv.getName()).str();
  if (M.getFunction(name))
    return;
  const DataLayout &DL = M.getDataLayout();
  if (DL.getTypeAllocSize(gv.getValueType()).getFixedValue() < 4)
    unimplemented("mem-qram: a global QRAM smaller than a handle (the global keeps the bus handle)", &gv);
  if (gv.isConstant())
    internalError("mem-qram: a constant global is a QRAM", &gv);
  if (!gv.hasInitializer())
    unimplemented("mem-qram: a global QRAM defined in another translation unit (the constructor is its "
                  "definer's)",
                  &gv);
  uint64_t n = DL.getTypeAllocSize(gv.getValueType()).getFixedValue() / q.cellBytes;
  if (n > UINT32_MAX)
    unimplemented("mem-qram: a global QRAM of more than 2^32 cells", &gv);
  Function *F = Function::Create(FunctionType::get(Type::getVoidTy(C), false), GlobalValue::InternalLinkage, name, M);
  IRBuilder<> B(BasicBlock::Create(C, "", F));
  Value *a = B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::QramAlloc, q.w}),
                          {ConstantInt::get(Type::getInt32Ty(C), n)});
  // Non-zero initial cells: alloc_<W>(v); store_hl(a, j, v); free(v).
  Constant *init = gv.getInitializer();
  if (!init->isNullValue()) {
    SmallVector<Constant *, 16> cells;
    std::function<void(Constant *)> flatten = [&](Constant *c) {
      if (c->getType() == q.cellTy) {
        cells.push_back(c);
        return;
      }
      auto *at = dyn_cast<ArrayType>(c->getType());
      if (!at)
        unimplemented("mem-qram: a global QRAM initializer that is not an array of its cells", &gv);
      for (uint64_t i = 0; i < at->getNumElements(); ++i)
        flatten(c->getAggregateElement(unsigned(i)));
    };
    flatten(init);
    FunctionType *freeTy = FunctionType::get(Type::getVoidTy(C), {Type::getInt32Ty(C)}, false);
    for (size_t j = 0; j < cells.size(); ++j) {
      Constant *v = cells[j];
      if (v->isNullValue())
        continue;
      if (!isa<ConstantInt>(v) && !isa<ConstantFP>(v))
        unimplemented("mem-qram: a global QRAM initializer cell that is not a number", &gv);
      Value *h = B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Alloc, q.w}), {v});
      B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::QramStore, q.w, false, true}),
                   {a, ConstantInt::get(Type::getInt32Ty(C), j), h});
      B.CreateCall(M.getOrInsertFunction("cqrt_free", freeTy), {h});
    }
  }
  B.CreateAlignedStore(a, &gv, Align(4));
  B.CreateRetVoid();
  appendToGlobalCtors(M, F, 65535);
}

// The QRAM object behind an access's root, with its bus handle in this output function.
QramObj &qramObj(LoweringContext &ctx, const Value *root, ObjectId o, const Instruction &I) {
  QramState &st = qramStates()[&ctx.out()];
  auto it = st.objs.find(root);
  if (it != st.objs.end())
    return it->second;
  auto *gv = const_cast<GlobalVariable *>(dyn_cast<GlobalVariable>(root));
  if (!gv) {
    if (isa<Argument>(root))
      unimplemented("mem-qram: a QRAM access through a parameter (the caller's bus crosses the call as a rule 21 "
                    "triple)",
                    &I);
    internalError("mem-qram: a QRAM access to a local or heap object whose allocation was not lowered", &I);
  }
  if (gv->isThreadLocal())
    unimplemented("mem-qram: a thread-local QRAM (rule 24)", &I);
  QramObj q;
  q.root = root;
  q.o = o;
  q.cellTy = scalarCell(gv->getValueType(), gv);
  q.cellBytes = ctx.M.getDataLayout().getTypeAllocSize(q.cellTy).getFixedValue();
  q.w = railTypeOf(q.cellTy);
  ensureGlobalCtor(ctx, *gv, q);
  // The entry loads the bus handle once (classical); the bus is the program's visible state: an
  // output, never popped or freed (rule 20, 160).
  Function &out = ctx.out();
  IRBuilder<> EB(&out.getEntryBlock(), out.getEntryBlock().getFirstInsertionPt());
  LoadInst *h = EB.CreateAlignedLoad(Type::getInt32Ty(ctx.M.getContext()), gv, Align(4));
  ctx.unc().recordExternal(h, Role::Output);
  q.handle = h;
  return st.objs.emplace(root, q).first->second;
}

// The cell index of a QRAM access: a quantum index rail (the logical index, rule 20) or a classical i32
// cell index j (the _hl form).
struct QIndex {
  Value *v;
  bool quantum;
};

QIndex qramIndex(LoweringContext &ctx, const QramObj &q, const Addr &a, Type *accessTy, const Instruction &I) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  IRBuilder<> &B = ctx.B();
  if (DL.getTypeAllocSize(accessTy).getFixedValue() != q.cellBytes || railTypeOf(accessTy).bits != q.w.bits ||
      railTypeOf(accessTy).kind != q.w.kind)
    unimplemented("mem-qram: a QRAM access at another type than its cell (a bit view, 63)", &I);
  int64_t cb = int64_t(q.cellBytes);
  if (a.off % cb)
    unimplemented("mem-qram: a QRAM access at a constant byte offset that is not a whole cell", &I);
  const std::pair<const Value *, int64_t> *qt = nullptr;
  for (auto &t : a.terms)
    if (ctx.T.isQuantum(t.first, ctx.S)) {
      if (qt)
        unimplemented("mem-qram: a QRAM address with two quantum index terms (flattened 2-D form, 191)", &I);
      qt = &t;
    }
  if (qt) {
    if (a.terms.size() != 1 || a.off != 0)
      unimplemented("mem-qram: a quantum QRAM index plus a constant or classical offset (the index arithmetic is "
                    "a template)",
                    &I);
    if (qt->second != cb)
      unimplemented("mem-qram: a quantum QRAM index whose GEP stride is not one cell (the scaling is a template)", &I);
    // The logical index: the GEP index stripped of its widening casts (address arithmetic, rule 20). A
    // negative sign-extended index points before the object (undefined, outside the domain).
    const Value *idx = qt->first;
    for (;;) {
      if (auto *z = dyn_cast<ZExtInst>(idx); z && ctx.T.isQuantum(z->getOperand(0), ctx.S)) {
        idx = z->getOperand(0);
        continue;
      }
      if (auto *s = dyn_cast<SExtInst>(idx); s && ctx.T.isQuantum(s->getOperand(0), ctx.S)) {
        idx = s->getOperand(0);
        continue;
      }
      break;
    }
    Operand ix = ctx.operand(idx);
    if (!ix.handle || !idx->getType()->isIntegerTy())
      internalError("mem-qram: the logical QRAM index is not an integer rail", &I);
    return {ix.v, true};
  }
  Type *i64 = Type::getInt64Ty(C);
  Value *j = nullptr;
  for (auto &[v, stride] : a.terms) {
    if (stride % cb)
      unimplemented("mem-qram: a QRAM GEP stride that is not a whole number of cells", &I);
    Value *t = B.CreateSExtOrTrunc(ctx.operand(v).v, i64);
    if (stride / cb != 1)
      t = B.CreateMul(t, ConstantInt::get(i64, stride / cb, true));
    j = j ? B.CreateAdd(j, t) : t;
  }
  Value *k = ConstantInt::get(i64, a.off / cb, true);
  j = j ? (a.off ? B.CreateAdd(j, k) : j) : k;
  return {B.CreateTrunc(j, Type::getInt32Ty(C)), false};
}

struct QAccess {
  QramObj *q;
  QIndex idx;
};

QAccess qramAccess(LoweringContext &ctx, const Value *ptr, Type *accessTy, const Instruction &I) {
  ObjectId o = soleQram(ctx, ptr, I);
  Addr a = decompose(ptr, ctx.M.getDataLayout());
  if (!a.ok)
    unimplemented("mem-qram: a QRAM access whose address is not an object plus GEP offsets (rule 21)", &I);
  if (ctx.T.isFatPointer(a.root, ctx.S) || ctx.operand(a.root).handle)
    unimplemented("mem-qram: a QRAM access through a quantum base pointer (rule 21)", &I);
  QramObj &q = qramObj(ctx, a.root, o, I);
  if (q.o != o)
    internalError("mem-qram: the access's root is another object than its provenance", &I);
  if (!accessTy->isIntegerTy() && !accessTy->isFloatingPointTy())
    unimplemented("mem-qram: a QRAM access of a non-scalar or pointer value (rules 21, 25)", &I);
  return {&q, qramIndex(ctx, q, a, accessTy, I)};
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

// Rule 20, §1.3: ONE cqrt_qram_load_<W>[_hl](a, idx | j) -> a fresh rail (copy-out, the cells
// unchanged), undone by its _unc against the same cell contents. A load is pure, so it is executed
// unguarded under a quantum predicate (rule 21's reading): its result is a value arm like any template.
void lowerQramLoad(LoweringContext &ctx, LoadInst &ld) {
  QAccess acc = qramAccess(ctx, ld.getPointerOperand(), ld.getType(), ld);
  abi::CoreSpec spec{abi::Core::QramLoad, acc.q->w, false, !acc.idx.quantum};
  CallInst *h = ctx.emitCore(spec, {acc.q->handle, acc.idx.v});
  ctx.unc().recordCore(h, spec, {Operand{acc.q->handle, true}, Operand{acc.idx.v, acc.idx.quantum}}, 0);
  ctx.bind(&ld, h);
}

// Rule 20, §1.3: ONE cqrt_qram_store_<W>[_hl][_controlled]([c,] a, idx | j, v), v always a handle (a
// classical value is first a seed, rule 7), under the current quantum predicate's flag when there is
// one. It is recorded on the bus: the bus's item pops its stores last-in-first-out (a global bus is an
// output and is never popped).
void lowerQramStore(LoweringContext &ctx, StoreInst &st) {
  Value *val = st.getValueOperand();
  QAccess acc = qramAccess(ctx, st.getPointerOperand(), val->getType(), st);
  Value *flag = ctx.currentFlag();
  Operand v = ctx.operand(val);
  if (!v.handle) {
    if (railTypeOf(val->getType()).bits != acc.q->w.bits)
      internalError("mem-qram: a stored value of another width than the cell", &st);
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, acc.q->w}, {v.v});
    ctx.unc().recordSeed(seed);
    v = Operand{seed, true};
  }
  abi::CoreSpec spec{abi::Core::QramStore, acc.q->w, flag != nullptr, !acc.idx.quantum};
  SmallVector<Value *, 4> args;
  SmallVector<Operand, 4> ops;
  if (flag) {
    args.push_back(flag);
    ops.push_back(Operand{flag, true});
  }
  args.append({acc.q->handle, acc.idx.v, v.v});
  ops.append({Operand{acc.q->handle, true}, Operand{acc.idx.v, acc.idx.quantum}, v});
  CallInst *call = ctx.emitCore(spec, args);
  RailId bus = ctx.unc().idOf(acc.q->handle);
  ctx.unc().recordCore(call, spec, ops, bus);
}

// Rule 20: a local (alloca) or heap QRAM is ONE cqrt_qram_alloc_<W>(n) at its allocation site, all
// cells |0> (C's indeterminate initial contents read 0, §6). The bus is a Seed rail: Uncompute pops its
// stores last-in-first-out and releases it with cqrt_qram_free once nothing reads it. The original
// pointer is bound to the object's QRAM base address (rule 21).
void allocateQram(LoweringContext &ctx, Instruction &site) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  ObjectId o = soleQram(ctx, &site, site);
  if (escapes(&site))
    unimplemented("mem-qram: a QRAM object whose pointer escapes to a call (the callee reaches the bus through a "
                  "rule 21 triple and its stores are the twin's: rule 18)",
                  &site);
  QramObj q;
  q.root = &site;
  q.o = o;
  Value *n = nullptr;
  if (auto *ai = dyn_cast<AllocaInst>(&site)) {
    q.cellTy = scalarCell(ai->getAllocatedType(), ai);
    q.cellBytes = DL.getTypeAllocSize(q.cellTy).getFixedValue();
    uint64_t per = DL.getTypeAllocSize(ai->getAllocatedType()).getFixedValue() / q.cellBytes;
    if (auto *c = dyn_cast<ConstantInt>(ai->getArraySize())) {
      uint64_t cells = per * c->getZExtValue();
      if (cells > UINT32_MAX)
        unimplemented("mem-qram: a QRAM of more than 2^32 cells", ai);
      n = ConstantInt::get(Type::getInt32Ty(C), cells);
    } else {
      Operand cnt = ctx.operand(ai->getArraySize());
      if (cnt.handle)
        unimplemented("mem-qram: a QRAM of quantum size (allocated at its upper bound, rule 20)", ai);
      Value *x = ctx.B().CreateZExtOrTrunc(cnt.v, Type::getInt32Ty(C));
      n = per == 1 ? x : ctx.B().CreateMul(x, ConstantInt::get(Type::getInt32Ty(C), per));
    }
  } else {
    unimplemented("mem-qram: a heap QRAM block (rule 20; realloc and free under a predicate, 91, 186)", &site);
  }
  q.w = railTypeOf(q.cellTy);
  abi::CoreSpec spec{abi::Core::QramAlloc, q.w};
  CallInst *a = ctx.emitCore(spec, {n});
  ctx.unc().recordCore(a, spec, {Operand{n, false}}, 0);
  q.handle = a;
  QramState &st = qramStates()[&ctx.out()];
  if (!st.objs.emplace(&site, q).second)
    unimplemented("mem-qram: a QRAM allocation site executed twice in one output function (a loop or an "
                  "inlined call re-allocating the object)",
                  &site);
  ctx.bind(&site, qramBase(ctx, o));
}

// The end of a local QRAM's scope (llvm.lifetime.end): nothing is emitted here. The bus's item (every
// store popped, then cqrt_qram_free) is Uncompute's, placed once nothing reads the bus; no access
// follows the lifetime end, so the release is at or before the end of the object's life.
void endQramLifetime(LoweringContext &ctx, ObjectId o, Instruction *at) {
  if (!at || !isa<IntrinsicInst>(at))
    unimplemented("mem-qram: free of a heap QRAM block (rule 20)", at);
  QramState &st = qramStates()[&ctx.out()];
  for (auto &[root, q] : st.objs)
    if (q.o == o)
      return;
  internalError("mem-qram: the lifetime end of a QRAM this function did not allocate", at);
}
} // namespace cq::mem
