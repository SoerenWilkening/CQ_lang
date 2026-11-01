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
#include "QramInternal.h"
#include "../../fatptr/FatPtrInternal.h"

#include <functional>
#include <map>
#include <optional>
#include <string>
#include <utility>

#include "cq/Abi.h"
#include "cq/FatPtr.h"
#include "cq/Predicate.h"
#include "cq/Uncompute.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/MemoryBuiltins.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/ConstantRange.h"
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

// One bus per scalar field column (rule 20: an array of structs is one object per scalar field column,
// all indexed by the same index rail, field-wise as in rule 26, 168). A scalar-element object is one
// column at offset 0.
struct Column {
  uint64_t off = 0;          // byte offset of the field inside one element
  Type *cellTy = nullptr;    // a pointer cell: ptr, its two columns (tag, idx) at the same offset
  RailType w{};
  uint8_t ptrPart = 0;       // 0 a scalar cell; 1 the tag, 2 the idx half of a pointer cell (rule 21, 88)
};

struct QramObj {
  const Value *site = nullptr;     // the alloca, global or heap call
  uint64_t elemBytes = 0;          // E: cell index j addresses bytes [j*E, (j+1)*E) of the object
  SmallVector<Column, 2> cols;     // ascending off
  // The buses (new IR, one per column) each root pointer of the object names: the allocation site (or
  // the global), and each realloc result (CR §1.3: a' replaces a for every access through it).
  std::map<const Value *, SmallVector<Value *, 2>> buses;
  const Column *at(uint64_t fo) const {
    for (const Column &c : cols)
      if (c.off == fo)
        return &c;
    return nullptr;
  }
  unsigned indexOf(const Column *c) const { return unsigned(c - cols.data()); }
};

// Keyed by site, not by ObjectId: taint names one object per field column (rule 20), so a site's
// columns are several ObjectIds of one QramObj.
struct QramState {
  std::map<const Value *, QramObj> objs;
  DenseMap<const Value *, const Value *> siteOf;   // a realloc result -> its block's site
  DenseSet<const Value *> formals;                  // Qram-pointee triple formals of a clone (P1)
};

std::map<const Function *, QramState> &qramStates() {
  static std::map<const Function *, QramState> s;
  return s;
}

int64_t floorDiv(int64_t a, int64_t b) {
  int64_t q = a / b;
  if ((a % b) != 0 && ((a < 0) != (b < 0)))
    --q;
  return q;
}

uint64_t storeBytes(const DataLayout &DL, Type *t) { return DL.getTypeStoreSize(t).getFixedValue(); }

void leaves(Type *t, uint64_t off, const DataLayout &DL, SmallVectorImpl<Column> &out, const Value *at) {
  if (auto *st = dyn_cast<StructType>(t)) {
    const StructLayout *L = DL.getStructLayout(st);
    for (unsigned i = 0; i < st->getNumElements(); ++i)
      leaves(st->getElementType(i), off + L->getElementOffset(i).getFixedValue(), DL, out, at);
    return;
  }
  if (auto *a = dyn_cast<ArrayType>(t)) {
    uint64_t es = DL.getTypeAllocSize(a->getElementType()).getFixedValue();
    for (uint64_t i = 0; i < a->getNumElements(); ++i)
      leaves(a->getElementType(), off + i * es, DL, out, at);
    return;
  }
  if (t->isVectorTy())
    unimplemented("mem-qram: a QRAM object of vector type (aggr, rule 25)", at);
  if (t->isPointerTy()) {
    // A QRAM of pointers holds fat pointers (rule 21, 88): one i32 column for the tag, one for the idx
    // (a cell index), both at the cell's offset and indexed alike.
    for (uint8_t part : {uint8_t(1), uint8_t(2)}) {
      Column c;
      c.off = off;
      c.cellTy = t;
      c.w = RailType{Kind::Int, 32};
      c.ptrPart = part;
      out.push_back(c);
    }
    return;
  }
  if (!t->isIntegerTy() && !t->isFloatingPointTy())
    unimplemented("mem-qram: a QRAM object whose cells are not integers or floating point", at);
  Column c;
  c.off = off;
  c.cellTy = t;
  c.w = railTypeOf(t);
  out.push_back(c);
}

// The layout of a sized object type: arrays stripped to the element, the element's scalar leaves as
// its columns (one for a scalar element).
QramObj layoutOf(Type *t, const DataLayout &DL, const Value *at) {
  while (auto *a = dyn_cast<ArrayType>(t))
    t = a->getElementType();
  QramObj q;
  q.elemBytes = DL.getTypeAllocSize(t).getFixedValue();
  if (!q.elemBytes)
    unimplemented("mem-qram: a QRAM object of zero-sized elements", at);
  leaves(t, 0, DL, q.cols, at);
  if (q.cols.empty())
    unimplemented("mem-qram: a QRAM object with no scalar field", at);
  return q;
}

// A heap block's element: the one type every load and store of the object in F uses.
QramObj heapLayout(LoweringContext &ctx, const Function &F, ObjectId o, const Value *site) {
  Type *t = nullptr;
  for (const Access &a : accessesOf(ctx, F, o)) {
    if (!t)
      t = a.ty;
    else if (t != a.ty)
      unimplemented("mem-qram: a heap QRAM accessed as two types (a bit view, 63)", a.I);
  }
  if (!t)
    unimplemented("mem-qram: a heap QRAM this function never loads or stores (its cell type is known only to "
                  "another function)",
                  site);
  return layoutOf(t, ctx.M.getDataLayout(), site);
}

// The object a QRAM access or allocation site names: exactly one object of class Qram.
ObjectId soleQram(LoweringContext &ctx, const Value *ptr, const Instruction &I) {
  ArrayRef<ObjectId> objs = ctx.T.provenance(ptr, ctx.S);
  if (objs.size() != 1)
    unimplemented("mem-qram: a QRAM access or site whose pointer has " + std::to_string(objs.size()) +
                      " objects (rule 21 fat pointer)",
                  &I);
  if (ctx.T.classOf(objs.front()) != ObjClass::Qram)
    internalError("mem-qram: the object is not a QRAM", &I);
  return objs.front();
}

// The call path of a QRAM pointer passed to a lifted clone (rule 21, §1.4; 191): a direct call of a
// function with a body whose taint specialization takes argument operand u as a T4 triple onto a Qram
// pointee. The clone reaches the bus through the triple (fatptr::bindFormal) and its stores are copied
// out and recorded on the caller's bus (M2, M2b, U3). Anything else (a declared clone, rule 27; an
// indirect call; a call whose site lowers through an argument map, C1) is an escape.
bool crossesAsQramTriple(LoweringContext &ctx, const CallBase &CB, const Use &u) {
  if (!CB.isArgOperand(&u) || CB.isByValArgument(CB.getArgOperandNo(&u)))
    return false;
  const Function *G = CB.getCalledFunction();
  if (!G || G->isDeclaration() || G->isVarArg())
    return false;
  const Specialization *cs = ctx.T.calleeSpecialization(CB, ctx.S);
  if (!cs || cs->isEntry() || cs->F != G)
    return false;
  PtrFormal pf = ctx.T.pointerFormal(*cs, CB.getArgOperandNo(&u));
  return pf.abi != PtrAbi::Raw && pf.pointee == ObjClass::Qram;
}

// A QRAM object's pointer escapes when it reaches anything but loads, stores, address arithmetic, the
// memory and lifetime intrinsics, a compare, free, realloc (whose result is the same object, CR §1.3),
// or a lifted clone's triple formal (crossesAsQramTriple).
bool qramEscapes(LoweringContext &ctx, const Value *root) {
  const DataLayout &DL = ctx.M.getDataLayout();
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
        if (st->getValueOperand() == v && st->getPointerOperand() != v) {
          // Stored as a value into a local QRAM of pointers of this function (rule 21, 88): the
          // pointer goes on through every pointer load from that object.
          Addr d = decompose(st->getPointerOperand(), DL);
          bool qram = d.ok && isa<AllocaInst>(d.root) && !ctx.T.provenance(st->getPointerOperand(), ctx.S).empty();
          for (ObjectId x : qram ? ctx.T.provenance(st->getPointerOperand(), ctx.S) : ArrayRef<ObjectId>())
            qram &= ctx.T.classOf(x) == ObjClass::Qram;
          if (!qram)
            return true;
          for (const Instruction &I : instructions(*st->getFunction()))
            if (auto *ld = dyn_cast<LoadInst>(&I); ld && ld->getType()->isPointerTy()) {
              Addr la = decompose(ld->getPointerOperand(), DL);
              if (la.ok && la.root == d.root && seen.insert(ld).second)
                work.push_back(ld);
            }
          continue;
        }
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
          continue;
        if (getReallocatedOperand(CB) == v) {
          if (seen.insert(CB).second)
            work.push_back(CB);
          continue;
        }
        if (auto *II = dyn_cast<IntrinsicInst>(CB))
          if (II->getIntrinsicID() == Intrinsic::lifetime_start || II->getIntrinsicID() == Intrinsic::lifetime_end)
            continue;
        if (crossesAsQramTriple(ctx, *CB, u))
          continue;
        return true;
      }
      return true;
    }
  }
  return false;
}

// The classical base address of a QRAM object (rule 21): 0x4000_0000_0000_0000 + 0x1000 * n, a
// non-canonical x86-64 address no host pointer takes. The original pointer is bound to it, so any
// classical use of the pointer (a compare, a ptrtoint) sees a unique, exact address.
Constant *qramBase(LoweringContext &ctx, ObjectId o) {
  LLVMContext &C = ctx.M.getContext();
  uint64_t a = 0x4000000000000000ull + 0x1000ull * uint64_t(o);
  return ConstantExpr::getIntToPtr(ConstantInt::get(Type::getInt64Ty(C), a), PointerType::get(C, 0));
}

// The largest value a quantum size can take (LLVM's known bits and range facts on the original IR):
// rule 20 / §1.3, a quantum size allocates at its upper bound.
uint64_t upperBound(const Value *v, const DataLayout &DL, const Instruction &I) {
  if (!v->getType()->isIntegerTy())
    internalError("mem-qram: a size that is not an integer", &I);
  APInt m = computeKnownBits(v, DL).getMaxValue();
  APInt r = computeConstantRange(v, /*ForSigned=*/false).getUnsignedMax();
  APInt b = APIntOps::umin(m, r);
  if (b.getActiveBits() > 40)
    unimplemented("mem-qram: a quantum size with no usable upper bound (rule 20: allocated at its bound)", &I);
  return b.getZExtValue();
}

// Rule 20: a global QRAM is allocated ONCE by a module constructor (160): cqrt_qram_alloc_<W>(n) per
// column, the handle of column k kept in the global's bytes [4k, 4k + 4) (classical words), and each
// non-zero initializer cell stored by its own _hl store of a seed that is freed at once (the store
// copies it; a global QRAM's stores are never popped).
void ensureGlobalCtor(LoweringContext &ctx, GlobalVariable &gv, const QramObj &q) {
  Module &M = ctx.M;
  LLVMContext &C = M.getContext();
  std::string name = ("__cq_qram_init_" + gv.getName()).str();
  if (M.getFunction(name))
    return;
  const DataLayout &DL = M.getDataLayout();
  uint64_t size = DL.getTypeAllocSize(gv.getValueType()).getFixedValue();
  if (size < 4 * q.cols.size())
    unimplemented("mem-qram: a global QRAM smaller than its bus handles (the global keeps one handle per column)",
                  &gv);
  if (gv.isConstant())
    internalError("mem-qram: a constant global is a QRAM", &gv);
  if (!gv.hasInitializer())
    unimplemented("mem-qram: a global QRAM defined in another translation unit (the constructor is its "
                  "definer's)",
                  &gv);
  uint64_t n = size / q.elemBytes;
  if (n > UINT32_MAX)
    unimplemented("mem-qram: a global QRAM of more than 2^32 cells", &gv);
  Function *F = Function::Create(FunctionType::get(Type::getVoidTy(C), false), GlobalValue::InternalLinkage, name, M);
  IRBuilder<> B(BasicBlock::Create(C, "", F));
  Type *i32 = Type::getInt32Ty(C);
  SmallVector<Value *, 2> a;
  for (const Column &c : q.cols)
    a.push_back(B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::QramAlloc, c.w}), {ConstantInt::get(i32, n)}));
  Constant *init = gv.getInitializer();
  if (!init->isNullValue()) {
    FunctionType *freeTy = FunctionType::get(Type::getVoidTy(C), {i32}, false);
    for (uint64_t j = 0; j < n; ++j)
      for (unsigned k = 0; k < q.cols.size(); ++k) {
        const Column &c = q.cols[k];
        if (c.ptrPart)
          unimplemented("mem-qram: a global QRAM of pointers with an initializer", &gv);
        Constant *v = ConstantFoldLoadFromConst(init, c.cellTy, APInt(64, j * q.elemBytes + c.off), DL);
        if (!v || (!isa<ConstantInt>(v) && !isa<ConstantFP>(v)))
          unimplemented("mem-qram: a global QRAM initializer cell that is not a number", &gv);
        if (v->isNullValue())
          continue;
        Value *h = B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Alloc, c.w}), {v});
        B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::QramStore, c.w, false, true}),
                     {a[k], ConstantInt::get(i32, j), h});
        B.CreateCall(M.getOrInsertFunction("cqrt_free", freeTy), {h});
      }
  }
  for (unsigned k = 0; k < a.size(); ++k)
    B.CreateAlignedStore(a[k], k ? B.CreateConstInBoundsGEP1_64(Type::getInt8Ty(C), &gv, 4 * k) : (Value *)&gv,
                         Align(4));
  B.CreateRetVoid();
  appendToGlobalCtors(M, F, 65535);
}

// The QRAM object reached through root, with its buses in this output function.
QramObj &qramObj(LoweringContext &ctx, const Value *root, const Instruction &I) {
  QramState &st = qramStates()[&ctx.out()];
  const Value *site = st.siteOf.lookup(root);
  if (!site)
    site = root;
  auto it = st.objs.find(site);
  if (it != st.objs.end())
    return it->second;
  auto *gv = const_cast<GlobalVariable *>(dyn_cast<GlobalVariable>(root));
  if (!gv) {
    if (isa<Argument>(root))
      unimplemented("mem-qram: a QRAM access through a parameter (the caller's bus crosses the call as a rule 21 "
                    "triple)",
                    &I);
    unimplemented("mem-qram: a QRAM access to a site that was not allocated as a QRAM (field columns of "
                  "different classes, rule 20, or an allocation not lowered before the access)",
                  &I);
  }
  if (gv->isThreadLocal())
    unimplemented("mem-qram: a thread-local QRAM (rule 24)", &I);
  QramObj q = layoutOf(gv->getValueType(), ctx.M.getDataLayout(), gv);
  q.site = gv;
  ensureGlobalCtor(ctx, *gv, q);
  // The entry loads each bus handle once (classical); the bus is the program's visible state: an
  // output, never popped or freed (rule 20, 160).
  Function &out = ctx.out();
  LLVMContext &C = ctx.M.getContext();
  IRBuilder<> EB(&out.getEntryBlock(), out.getEntryBlock().getFirstInsertionPt());
  SmallVector<Value *, 2> hs;
  for (unsigned k = 0; k < q.cols.size(); ++k) {
    Value *p = k ? EB.CreateConstInBoundsGEP1_64(Type::getInt8Ty(C), gv, 4 * k) : (Value *)gv;
    LoadInst *h = EB.CreateAlignedLoad(Type::getInt32Ty(C), p, Align(4));
    ctx.unc().recordExternal(h, Role::Output);
    hs.push_back(h);
  }
  q.buses[gv] = hs;
  return st.objs.emplace(gv, std::move(q)).first->second;
}

Value *busOf(const QramObj &q, const Value *root, const Column *c, const Instruction &I) {
  auto it = q.buses.find(root);
  if (it == q.buses.end())
    unimplemented("mem-qram: a QRAM access whose root pointer is neither the allocation nor a realloc result "
                  "lowered before it",
                  &I);
  return it->second[q.indexOf(c)];
}

// The cell index of a QRAM access: a quantum index rail (the logical index, rule 20) or a classical i32
// cell index j (the _hl form).
struct QIndex {
  Value *v;
  bool quantum;
};

// The first quantum index term of the address, or nullptr (a classical address).
const std::pair<const Value *, int64_t> *quantumTerm(LoweringContext &ctx, const Addr &a, const Instruction &) {
  for (auto &t : a.terms)
    if (ctx.T.isQuantum(t.first, ctx.S))
      return &t;
  return nullptr;
}

Value *classicalElems(LoweringContext &ctx, const QramObj &q, const Addr &a, const Instruction &I) {
  IRBuilder<> &B = ctx.B();
  Type *i64 = Type::getInt64Ty(ctx.M.getContext());
  int64_t E = int64_t(q.elemBytes);
  Value *j = nullptr;
  for (auto &[v, stride] : a.terms) {
    if (stride % E)
      unimplemented("mem-qram: a QRAM GEP stride that is not a whole number of elements", &I);
    Operand x = ctx.operand(v);
    if (x.handle)
      internalError("mem-qram: a quantum term in a classical QRAM address", &I);
    Value *t = B.CreateSExtOrTrunc(x.v, i64);
    if (stride / E != 1)
      t = B.CreateMul(t, ConstantInt::get(i64, stride / E, true));
    j = j ? B.CreateAdd(j, t) : t;
  }
  return j;
}

// The i32 cell index jb + e.
Value *elemIndex(LoweringContext &ctx, Value *jb, int64_t e) {
  LLVMContext &C = ctx.M.getContext();
  if (!jb)
    return ConstantInt::get(Type::getInt32Ty(C), e, true);
  Value *x = e ? ctx.B().CreateAdd(jb, ConstantInt::get(Type::getInt64Ty(C), e, true)) : jb;
  return ctx.B().CreateTrunc(x, Type::getInt32Ty(C));
}

bool sameCellType(const DataLayout &DL, Type *access, const Column &c) {
  if (c.ptrPart || access->isPointerTy())
    return c.ptrPart == 1 && access->isPointerTy() && DL.getTypeAllocSize(access) == DL.getTypeAllocSize(c.cellTy);
  if (!access->isIntegerTy() && !access->isFloatingPointTy())
    return false;
  RailType r = railTypeOf(access);
  return DL.getTypeAllocSize(access) == DL.getTypeAllocSize(c.cellTy) && r.bits == c.w.bits && r.kind == c.w.kind;
}

// The cells of one element-aligned run of bytes [off, off + len) (from the address's classical base).
struct Hit {
  const Column *col;
  int64_t elem;   // element index relative to the base
  uint64_t rel;   // the cell's first byte relative to off
};

SmallVector<Hit, 8> cellsIn(const DataLayout &DL, const QramObj &q, int64_t off, uint64_t len, const Instruction &I) {
  SmallVector<Hit, 8> out;
  int64_t E = int64_t(q.elemBytes);
  if (len / q.elemBytes > (1u << 16))
    unimplemented("mem-qram: a QRAM write over more than 65536 elements unrolled per cell", &I);
  int64_t end = off + int64_t(len);
  for (int64_t e = floorDiv(off, E); e * E < end; ++e)
    for (const Column &c : q.cols) {
      int64_t s = e * E + int64_t(c.off), sz = int64_t(storeBytes(DL, c.cellTy));
      int64_t lo = std::max(s, off), hi = std::min(s + sz, end);
      if (lo >= hi)
        continue;
      if (lo != s || hi != s + sz)
        unimplemented("mem-qram: a QRAM access or memory intrinsic covering part of a cell (a bit view, 63)", &I);
      if (c.ptrPart)
        unimplemented("mem-qram: a memory intrinsic or wide store over a QRAM of pointers (rule 21)", &I);
      out.push_back({&c, e, uint64_t(s - off)});
    }
  return out;
}

Value *seedOf(LoweringContext &ctx, RailType w, Value *v) {
  CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {v});
  ctx.unc().recordSeed(seed);
  return seed;
}

// ONE cqrt_qram_load_<W>[_hl](a, idx | j): a fresh rail (copy-out, the cells unchanged), undone by its
// _unc against the same cell contents (recordCore).
Value *emitLoad(LoweringContext &ctx, Value *bus, const Column &c, QIndex idx) {
  abi::CoreSpec spec{abi::Core::QramLoad, c.w, false, !idx.quantum};
  CallInst *h = ctx.emitCore(spec, {bus, idx.v});
  ctx.unc().recordCore(h, spec, {Operand{bus, true}, Operand{idx.v, idx.quantum}}, 0);
  return h;
}

// ONE cqrt_qram_store_<W>[_hl][_controlled]([flag,] a, idx | j, v), v a handle, recorded on the bus.
void emitStore(LoweringContext &ctx, Value *bus, const Column &c, QIndex idx, Value *v, Value *flag) {
  abi::CoreSpec spec{abi::Core::QramStore, c.w, flag != nullptr, !idx.quantum};
  SmallVector<Value *, 4> args;
  SmallVector<Operand, 4> ops;
  if (flag) {
    args.push_back(flag);
    ops.push_back(Operand{flag, true});
  }
  args.append({bus, idx.v, v});
  ops.append({Operand{bus, true}, Operand{idx.v, idx.quantum}, Operand{v, true}});
  CallInst *call = ctx.emitCore(spec, args);
  ctx.unc().recordCore(call, spec, ops, ctx.unc().idOf(bus));
}

// The cell of `bits` bits at byte `rel` of the little-endian integer x, as a value of cellTy.
Value *bytesToCell(LoweringContext &ctx, Value *x, uint64_t rel, Type *cellTy) {
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  if (rel)
    x = B.CreateLShr(x, ConstantInt::get(x->getType(), rel * 8));
  unsigned bits = unsigned(cellTy->getPrimitiveSizeInBits().getFixedValue());
  Value *v = B.CreateTrunc(x, IntegerType::get(C, bits));
  if (!cellTy->isIntegerTy())
    v = B.CreateBitCast(v, cellTy);
  return v;
}

// The fill byte b repeated over the cell (rule 22).
Value *splatCell(LoweringContext &ctx, Value *b, Type *cellTy) {
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  unsigned storeBits = unsigned(ctx.M.getDataLayout().getTypeStoreSize(cellTy).getFixedValue()) * 8;
  IntegerType *wide = IntegerType::get(C, storeBits);
  Value *splat = B.CreateMul(B.CreateZExt(b, wide), ConstantInt::get(wide, APInt::getSplat(storeBits, APInt(8, 1))));
  return bytesToCell(ctx, splat, 0, cellTy);
}

struct QAccess {
  QramObj *q;
  Addr a;
};

QAccess qramAccess(LoweringContext &ctx, const Value *ptr, const Instruction &I) {
  soleQram(ctx, ptr, I);
  Addr a = decompose(ptr, ctx.M.getDataLayout());
  if (!a.ok)
    unimplemented("mem-qram: a QRAM access whose address is not an object plus GEP offsets (rule 21)", &I);
  if (isFormalQram(ctx, a.root))
    internalError("mem-qram: a QRAM access through a triple formal outside fatptr's derivation (P1)", &I);
  if (ctx.T.isFatPointer(a.root, ctx.S) || ctx.operand(a.root).handle)
    unimplemented("mem-qram: a QRAM access through a quantum base pointer (rule 21)", &I);
  return {&qramObj(ctx, a.root, I), a};
}

// The single cell a load or store of accessTy names (its column) and its index, or nullptr when the
// access is not exactly one cell.
const Column *exactCell(LoweringContext &ctx, const QramObj &q, const Addr &a, Type *accessTy) {
  int64_t E = int64_t(q.elemBytes);
  int64_t ec = floorDiv(a.off, E);
  const Column *col = q.at(uint64_t(a.off - ec * E));
  if (!col || !sameCellType(ctx.M.getDataLayout(), accessTy, *col))
    return nullptr;
  return col;
}

// The logical index rail of one quantum GEP index term: the index stripped of its widening casts
// (address arithmetic, rule 20), with the extension that widens it (the innermost cast decides: a zext
// makes every later widening a zext; an uncast index narrower than the pointer is sign-extended by the
// GEP itself). A negative sign-extended index points before the object (undefined, outside the domain).
struct LogicalIndex {
  Value *rail;
  unsigned bits;
  bool sext;
  bool zextOverSext;   // a zext of a sext: not one extension
};

LogicalIndex logicalIndex(LoweringContext &ctx, const Value *idx, const Instruction &I) {
  bool sext = false, cast = false, zextOverSext = false;
  for (;;) {
    if (auto *z = dyn_cast<ZExtInst>(idx); z && ctx.T.isQuantum(z->getOperand(0), ctx.S)) {
      idx = z->getOperand(0);
      sext = false;
      cast = true;
      continue;
    }
    if (auto *s = dyn_cast<SExtInst>(idx); s && ctx.T.isQuantum(s->getOperand(0), ctx.S)) {
      if (cast && !sext)
        zextOverSext = true;
      idx = s->getOperand(0);
      sext = true;
      cast = true;
      continue;
    }
    break;
  }
  Operand ix = ctx.operand(idx);
  if (!ix.handle || !idx->getType()->isIntegerTy())
    internalError("mem-qram: the logical QRAM index is not an integer rail", &I);
  unsigned bits = idx->getType()->getIntegerBitWidth();
  if (!cast && bits < 64)
    sext = true;
  return {ix.v, bits, sext, zextOverSext};
}

// The cell index of a QRAM access. A quantum address is its logical index rail alone when it is the
// address's only term at one element's stride with no element offset; otherwise rule 20's index
// arithmetic as templates: each quantum term's logical index widened by its own extension to the C index
// width (at least int, 32, or the widest index), scaled by its stride in elements (mul_hl, the 2-D
// flattening r * cols + c, 191), the scaled terms added in GEP order, then the classical element offset
// (the classical terms and the constant) added (add_hl, 192). A modular sum at that width is the exact
// cell index: every in-domain cell index of a QRAM is below 2^32 (qram_alloc takes an i32 cell count).
QIndex cellIndex(LoweringContext &ctx, const QramObj &q, const Addr &a, const Instruction &I) {
  int64_t E = int64_t(q.elemBytes);
  int64_t ec = floorDiv(a.off, E);
  if (!quantumTerm(ctx, a, I))
    return {elemIndex(ctx, classicalElems(ctx, q, a, I), ec), false};
  SmallVector<std::pair<LogicalIndex, int64_t>, 2> qs;   // logical index, stride in elements
  Addr others = a;
  others.terms.clear();
  for (auto &t : a.terms) {
    if (!ctx.T.isQuantum(t.first, ctx.S)) {
      others.terms.push_back(t);
      continue;
    }
    if (t.second % E)
      unimplemented("mem-qram: a quantum QRAM index whose GEP stride is not a whole number of elements (a bit "
                    "view)",
                    &I);
    qs.push_back({logicalIndex(ctx, t.first, I), t.second / E});
  }
  if (qs.size() == 1 && qs[0].second == 1 && others.terms.empty() && ec == 0)
    return {qs[0].first.rail, true};
  unsigned Ws = 32;
  for (auto &[li, k] : qs) {
    if (li.zextOverSext)
      unimplemented("mem-qram: a quantum QRAM index widened by a zext of a sext, in index arithmetic", &I);
    Ws = std::max(Ws, li.bits);
  }
  LLVMContext &C = ctx.M.getContext();
  RailType rw{Kind::Int, Ws};
  auto tmpl = [&](StringRef op, ArrayRef<Operand> ops, StringRef shape) {
    abi::TemplateSpec spec;
    spec.op = op.str();
    spec.w = rw;
    spec.shape = shape.str();
    return ctx.emitTemplate(spec, ops);
  };
  Value *rail = nullptr;
  for (auto &[li, k] : qs) {
    Value *r = li.rail;
    if (li.bits < Ws) {
      abi::TemplateSpec ext;
      ext.op = li.sext ? "sext" : "zext";
      ext.w = RailType{Kind::Int, li.bits};
      ext.to = rw;
      r = ctx.emitTemplate(ext, {Operand{r, true}});
    }
    if (k != 1)
      r = tmpl("mul", {Operand{r, true}, Operand{ConstantInt::get(IntegerType::get(C, Ws), k, true), false}}, "hl");
    rail = rail ? tmpl("add", {Operand{rail, true}, Operand{r, true}}, "") : r;
  }
  Value *j = classicalElems(ctx, q, others, I);
  if (j || ec) {
    Type *i64 = Type::getInt64Ty(C);
    Value *k = j ? j : ConstantInt::get(i64, 0);
    if (ec)
      k = j ? ctx.B().CreateAdd(k, ConstantInt::get(i64, ec, true)) : ConstantInt::get(i64, ec, true);
    k = ctx.B().CreateSExtOrTrunc(k, IntegerType::get(C, Ws));
    rail = tmpl("add", {Operand{rail, true}, Operand{k, false}}, "hl");
  }
  return {rail, true};
}

// A classical value of type ty stored over the whole cells it covers at a classical address: one _hl
// store per cell of the value's bytes (rule 20: each access is per cell; 84's `store i64` of two i32
// cells), each value a fresh seed (rule 7).
void storeClassicalBytes(LoweringContext &ctx, const QAccess &acc, Value *val, Type *ty, Value *flag,
                         const Instruction &I) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  IRBuilder<> &B = ctx.B();
  if (quantumTerm(ctx, acc.a, I))
    unimplemented("mem-qram: a QRAM store at a quantum index of a value wider or other than its cell (a bit "
                  "view, 63)",
                  &I);
  if (ty->isPointerTy() || ty->isStructTy() || ty->isArrayTy())
    unimplemented("mem-qram: a QRAM store of a pointer or aggregate value (rules 21, 26)", &I);
  uint64_t bytes = storeBytes(DL, ty);
  unsigned prim = unsigned(ty->getPrimitiveSizeInBits().getFixedValue());
  if (prim != bytes * 8 && !ty->isIntegerTy())
    unimplemented("mem-qram: a QRAM store of a padded non-integer value over several cells", &I);
  Value *x = val;
  if (!ty->isIntegerTy())
    x = B.CreateBitCast(x, IntegerType::get(C, prim));
  if (prim != bytes * 8)
    x = B.CreateZExt(x, IntegerType::get(C, unsigned(bytes * 8)));
  const QramObj &q = *acc.q;
  Value *jb = classicalElems(ctx, q, acc.a, I);
  for (const Hit &h : cellsIn(DL, q, acc.a.off, bytes, I)) {
    Value *v = seedOf(ctx, h.col->w, bytesToCell(ctx, x, h.rel, h.col->cellTy));
    emitStore(ctx, busOf(q, acc.a.root, h.col, I), *h.col, {elemIndex(ctx, jb, h.elem), false}, v, flag);
  }
}

// Rule 22 over a QRAM destination: a classical length is one _hl store per covered cell (memset: one
// shared basis-state seed per cell type, 30, 55; memcpy/memmove: each cell the source cell's value, a
// seed of a classical source byte run (73, 168) or a _hl load of a QRAM source cell). All source cells
// are read before any store (memmove). Under a quantum predicate the stores are _controlled.
void lowerQramIntrinsic(LoweringContext &ctx, MemIntrinsic &MI, ObjectId o) {
  const DataLayout &DL = ctx.M.getDataLayout();
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  (void)o;
  QAccess acc = qramAccess(ctx, MI.getDest(), MI);
  if (quantumTerm(ctx, acc.a, MI))
    unimplemented("mem-qram: a memory intrinsic at a quantum offset into a QRAM (rule 20, last row)", &MI);
  Operand len = ctx.operand(MI.getLength());
  if (len.handle)
    unimplemented("mem-qram: a memory intrinsic into a QRAM with a quantum length (rule 22's guarded cells, 90)",
                  &MI);
  auto *cl = dyn_cast<ConstantInt>(len.v);
  if (!cl)
    unimplemented("mem-qram: a run-time-length memory intrinsic into a QRAM (its per-cell stores need a loop "
                  "whose pops a reverse loop makes)",
                  &MI);
  const QramObj &q = *acc.q;
  Value *flag = ctx.currentFlag();
  Value *jb = classicalElems(ctx, q, acc.a, MI);
  SmallVector<Hit, 8> hits = cellsIn(DL, q, acc.a.off, cl->getZExtValue(), MI);
  SmallVector<Value *, 8> vals;

  if (auto *MS = dyn_cast<MemSetInst>(&MI)) {
    Operand fill = ctx.operand(MS->getValue());
    if (fill.handle)
      unimplemented("mem-qram: a memset of a QRAM with a quantum fill byte (rule 22)", &MI);
    std::map<std::pair<unsigned, unsigned>, Value *> seeds;   // one shared seed per cell type (rule 22)
    for (const Hit &h : hits) {
      Value *&s = seeds[{unsigned(h.col->w.kind), h.col->w.bits}];
      if (!s)
        s = seedOf(ctx, h.col->w, splatCell(ctx, fill.v, h.col->cellTy));
      vals.push_back(s);
    }
  } else {
    auto *MT = cast<MemTransferInst>(&MI);
    const Value *src = MT->getSource();
    if (ctx.T.isFatPointer(src, ctx.S))
      unimplemented("mem-qram: a memcpy/memmove into a QRAM from a quantum pointer (rule 21)", &MI);
    ArrayRef<ObjectId> so = ctx.T.provenance(src, ctx.S);
    bool host = llvm::all_of(so, [&](ObjectId x) { return ctx.T.classOf(x) == ObjClass::Classical; });
    if (host) {
      Operand sp = ctx.operand(src);
      if (sp.handle)
        internalError("mem-qram: a classical memcpy source bound to a rail", &MI);
      for (const Hit &h : hits) {
        Value *v = nullptr;
        if (auto *k = dyn_cast<Constant>(src))
          v = ConstantFoldLoadFromConstPtr(const_cast<Constant *>(k), h.col->cellTy, APInt(64, h.rel), DL);
        if (!v) {
          Value *p = h.rel ? B.CreateConstInBoundsGEP1_64(Type::getInt8Ty(C), sp.v, h.rel) : sp.v;
          v = B.CreateAlignedLoad(h.col->cellTy, p, commonAlignment(MT->getSourceAlign().valueOrOne(), h.rel));
        }
        vals.push_back(seedOf(ctx, h.col->w, v));
      }
    } else if (so.size() == 1 && ctx.T.classOf(so.front()) == ObjClass::Qram) {
      QAccess sacc = qramAccess(ctx, src, MI);
      if (quantumTerm(ctx, sacc.a, MI))
        unimplemented("mem-qram: a memcpy/memmove from a quantum offset of a QRAM (rule 20, last row)", &MI);
      const QramObj &sq = *sacc.q;
      Value *sjb = classicalElems(ctx, sq, sacc.a, MI);
      int64_t SE = int64_t(sq.elemBytes);
      for (const Hit &h : hits) {
        int64_t p = sacc.a.off + int64_t(h.rel);
        int64_t se = floorDiv(p, SE);
        const Column *sc = sq.at(uint64_t(p - se * SE));
        if (!sc || sc->cellTy != h.col->cellTy)
          unimplemented("mem-qram: a memcpy/memmove between QRAMs whose cells do not line up (a bit view, 63)", &MI);
        vals.push_back(emitLoad(ctx, busOf(sq, sacc.a.root, sc, MI), *sc, {elemIndex(ctx, sjb, se), false}));
      }
    } else {
      unimplemented("mem-qram: a memcpy/memmove into a QRAM from a slot array or several objects (the source "
                    "handles are mem-slots' cell reads, 73)",
                    &MI);
    }
  }
  for (size_t i = 0; i < hits.size(); ++i) {
    const Hit &h = hits[i];
    emitStore(ctx, busOf(q, acc.a.root, h.col, MI), *h.col, {elemIndex(ctx, jb, h.elem), false},
              vals[i], flag);
  }
}

// The column at offset 0 of the object at root whose cell is accessed as ty.
const Column &firstColumn(LoweringContext &ctx, const QramObj &q, llvm::Type *ty, const Instruction &at) {
  const Column *c = q.at(0);
  if (!c || !sameCellType(ctx.M.getDataLayout(), ty, *c))
    unimplemented("mem-qram: a fat-pointer access of a QRAM at another type or field than its first cell (a bit "
                  "view or a field column through a fat pointer)",
                  &at);
  return *c;
}

QIndex fatIndex(LoweringContext &ctx, Operand idx) {
  if (idx.handle)
    return {idx.v, true};
  return {ctx.B().CreateTrunc(idx.v, Type::getInt32Ty(ctx.M.getContext())), false};
}

} // namespace

bool isQramRoot(LoweringContext &ctx, const Value *root) {
  if (isa<GlobalVariable>(root)) {
    for (ObjectId o : ctx.T.provenance(root, ctx.S))
      if (ctx.T.classOf(o) == ObjClass::Qram)
        return true;
    return false;
  }
  QramState &st = qramStates()[&ctx.out()];
  const Value *site = st.siteOf.lookup(root);
  return st.objs.count(site ? site : root) != 0;
}

uint64_t qramElemBytes(LoweringContext &ctx, const Value *root, const Instruction &at) {
  return qramObj(ctx, root, at).elemBytes;
}

Value *qramLoadAt(LoweringContext &ctx, const Value *root, Operand idx, Type *ty, const Instruction &at) {
  QramObj &q = qramObj(ctx, root, at);
  const Column &c = firstColumn(ctx, q, ty, at);
  return emitLoad(ctx, busOf(q, root, &c, at), c, fatIndex(ctx, idx));
}

std::pair<Value *, Value *> qramLoadPtrAt(LoweringContext &ctx, const Value *root, Operand idx,
                                          const Instruction &at) {
  QramObj &q = qramObj(ctx, root, at);
  const Column *c = q.at(0);
  if (!c || c->ptrPart != 1)
    unimplemented("mem-qram: a pointer load through a fat pointer of a QRAM whose first cell is not a pointer", &at);
  QIndex ix = fatIndex(ctx, idx);
  Value *tag = emitLoad(ctx, busOf(q, root, c, at), c[0], ix);
  Value *i = emitLoad(ctx, busOf(q, root, c + 1, at), c[1], ix);
  return {tag, i};
}

void qramStoreAt(LoweringContext &ctx, const Value *root, Operand idx, Type *ty, Value *v, Value *flag,
                 const Instruction &at) {
  QramObj &q = qramObj(ctx, root, at);
  const Column &c = firstColumn(ctx, q, ty, at);
  emitStore(ctx, busOf(q, root, &c, at), c, fatIndex(ctx, idx), v, flag);
}

Value *qramBusOf(LoweringContext &ctx, const Value *root, const Instruction &at) {
  QramObj &q = qramObj(ctx, root, at);
  if (q.cols.size() != 1)
    unimplemented("mem-qram: a QRAM of several field columns crossing a clone boundary (rules 21, 26)", &at);
  return busOf(q, root, &q.cols[0], at);
}

Type *qramCellType(LoweringContext &ctx, const Value *root, const Instruction &at) {
  QramObj &q = qramObj(ctx, root, at);
  if (q.cols.size() != 1)
    unimplemented("mem-qram: a QRAM of several field columns crossing a clone boundary (rules 21, 26)", &at);
  return q.cols[0].cellTy;
}

// Rule 22, per object of a quantum source pointer (90): the length's upper bound in bytes on the paths
// that select root r. A classical length: itself. A quantum length: with one root, its bound; else the
// source and the length must be selects on one condition (the paths that select an arm's root are those
// that select its length), r an arm itself: the largest bound of the arms that are r. Anything else is
// unimplemented (a bound valid for every root would speculate host bytes past an object, rule 22).
uint64_t sourceBound(LoweringContext &ctx, const MemIntrinsic &MI, const Value *lenV, const Value *r) {
  const DataLayout &DL = ctx.M.getDataLayout();
  if (auto *c = dyn_cast<ConstantInt>(lenV))
    return c->getZExtValue();
  const Value *src = cast<MemTransferInst>(MI).getSource()->stripPointerCasts();
  auto *ss = dyn_cast<SelectInst>(src);
  const Value *len = MI.getLength();
  if (auto *z = dyn_cast<ZExtInst>(len))
    len = z->getOperand(0);
  auto *ls = dyn_cast<SelectInst>(len);
  if (!ss || !ls || ss->getCondition() != ls->getCondition())
    unimplemented("mem-qram: a quantum-length memcpy/memmove from a quantum source pointer whose length is not "
                  "selected with it (the length's bound per source object, rule 22)",
                  &MI);
  std::optional<uint64_t> b;
  for (auto [p, l] : {std::pair{ss->getTrueValue(), ls->getTrueValue()}, std::pair{ss->getFalseValue(), ls->getFalseValue()}})
    if (p->stripPointerCasts() == r)
      b = std::max(b.value_or(0), upperBound(l, DL, MI));
  if (!b)
    unimplemented("mem-qram: a memcpy/memmove source object that is not an arm of the source pointer's select (the "
                  "length's bound per source object, rule 22)",
                  &MI);
  return *b;
}

// Rule 22 into a slot array through mem-slots' write path (M6 writeSlotCells, cq-arch 2026-11-01): the
// cells the intrinsic may touch, j below the length's bound (a classical constant length: exactly; a
// quantum length: its upper bound, LLVM's known bits and range facts), take their new values, guarded by
// len >u (j + 1) * cb - 1 for a quantum length (an i1 rail per cell; mem-slots makes the cell
// select(guard, new, old) and restores the slot on uncompute). Every source cell is read before any write
// (memmove's overlap): a slot source through readSlotCells (M4), a classical source by host loads; a
// memset's fill is its splatted literal. A QRAM or fat-pointer source, a quantum fill and a run-time
// classical length are unimplemented.
void lowerSlotIntrinsicM6(LoweringContext &ctx, MemIntrinsic &MI, ObjectId o) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  IRBuilder<> &B = ctx.B();
  FnState &st = stateOf(ctx, MI);
  Addr a = decompose(MI.getDest(), DL);
  if (!a.ok || ctx.T.objectOf(a.root) != o)
    unimplemented("mem-qram: a memory intrinsic into a slot object whose destination is not its object plus GEP "
                  "offsets",
                  &MI);
  ObjInfo &info = objInfo(ctx, st, a.root, o);
  Type *cellTy = cellType(ctx, st, info, o);
  uint64_t cb = info.cellBytes;
  // mem-slots' cells (Slots.cpp objInfo, restated): a local a memory intrinsic writes whose narrowest
  // access is narrower than its integer element has byte cells of that width (-O1's punned alloca i32 of
  // 90's unsigned char d[4]; mem-slots splits each wider classical store per cell). Any other local
  // accessed at another width than its cell is a bit view (63).
  bool view = false;
  if (info.kind == RootKind::Local) {
    uint64_t narrow = cb;
    for (const Access &x : accessesOf(ctx, *st.F, o))
      narrow = std::min(narrow, uint64_t(DL.getTypeAllocSize(x.ty).getFixedValue()));
    if (narrow < cb && cellTy->isIntegerTy()) {
      cb = narrow;
      cellTy = IntegerType::get(C, unsigned(8 * narrow));
    } else {
      for (const Access &x : accessesOf(ctx, *st.F, o))
        view |= DL.getTypeAllocSize(x.ty).getFixedValue() != cb;
    }
  }
  if (view || isa<StructType>(cellTy))
    unimplemented("mem-qram: a memory intrinsic into a slot object accessed at another width than its cell or a "
                  "record (mem-slots' cells: a bit view 63, -O1's punned alloca of 90)",
                  &MI);
  if (a.off % int64_t(cb))
    unimplemented("mem-qram: a memory intrinsic into a slot object starting inside a cell (a bit view, 63)", &MI);
  // The length: a classical constant, or a quantum rail (its logical value beneath one zext).
  const Value *lenV = MI.getLength();
  if (auto *z = dyn_cast<ZExtInst>(lenV); z && ctx.T.isQuantum(z->getOperand(0), ctx.S))
    lenV = z->getOperand(0);
  Operand len = ctx.operand(lenV);
  uint64_t n = 0;
  if (!len.handle) {
    auto *cl = dyn_cast<ConstantInt>(len.v);
    if (!cl)
      unimplemented("mem-qram: a memcpy/memmove into a slot array with a run-time classical length (a loop)", &MI);
    if (cl->getZExtValue() % cb)
      unimplemented("mem-qram: a memory intrinsic into a slot array over a part of a cell (a bit view, 63)", &MI);
    n = cl->getZExtValue() / cb;
  } else {
    if (!wholeCells(lenV, cb, DL))
      unimplemented("mem-qram: a quantum-length memory intrinsic into a slot array over a part of a cell (a bit "
                    "view, 63)",
                    &MI);
    n = (upperBound(lenV, DL, MI) + cb - 1) / cb;
  }
  if (n == 0)
    return;
  // The values, every source cell read first.
  SmallVector<Operand, 8> vals;
  if (auto *MS = dyn_cast<MemSetInst>(&MI)) {
    Operand fill = ctx.operand(MS->getValue());
    if (fill.handle)
      unimplemented("mem-qram: a memset of a slot object with a quantum fill byte (rule 22)", &MI);
    Value *v = splatCell(ctx, fill.v, cellTy);
    vals.assign(n, Operand{v, false});
  } else {
    const Value *src = cast<MemTransferInst>(MI).getSource();
    if (ctx.T.isFatPointer(src, ctx.S)) {
      vals = fatptr::loadHostCells(ctx, src, cellTy, n, [&](const Value *r) { return sourceBound(ctx, MI, lenV, r); },
                                   MI);
    } else {
    ArrayRef<ObjectId> so = ctx.T.provenance(src, ctx.S);
    bool classical = true;
    for (ObjectId x : so)
      classical &= ctx.T.classOf(x) == ObjClass::Classical;
    if (so.size() == 1 && ctx.T.classOf(so.front()) == ObjClass::Slot) {
      vals = readSlotCells(ctx, src, cellTy, n, MI);
    } else if (classical) {
      Operand sp = ctx.operand(src);
      if (sp.handle)
        internalError("mem-qram: a classical memcpy source bound to a rail", &MI);
      for (uint64_t j = 0; j < n; ++j) {
        Value *p = j ? B.CreateInBoundsGEP(Type::getInt8Ty(C), sp.v, ConstantInt::get(Type::getInt64Ty(C), j * cb))
                     : sp.v;
        vals.push_back(Operand{B.CreateLoad(cellTy, p), false});
      }
    } else {
      unimplemented("mem-qram: a memcpy/memmove into a slot array from a QRAM or a mixed-class source", &MI);
    }
    }
  }
  // The guards of a quantum length.
  SmallVector<Value *, 8> guards;
  if (len.handle) {
    unsigned lw = lenV->getType()->getIntegerBitWidth();
    for (uint64_t j = 0; j < n; ++j) {
      abi::TemplateSpec cmp;
      cmp.op = "icmp";
      cmp.pred = "ugt";
      cmp.w = RailType{Kind::Int, lw};
      cmp.shape = "hl";
      guards.push_back(ctx.emitTemplate(cmp, {len, Operand{ConstantInt::get(IntegerType::get(C, lw), (j + 1) * cb - 1), false}}));
    }
  }
  writeSlotCells(ctx, MI.getDest(), cellTy, vals, guards, MI);
}

void lowerMemIntrinsic(LoweringContext &ctx, MemIntrinsic &MI) {
  ArrayRef<ObjectId> objs = ctx.T.provenance(MI.getDest(), ctx.S);
  if (ctx.T.isFatPointer(MI.getDest(), ctx.S))
    unimplemented("mem-qram: a memory intrinsic through a quantum destination pointer (rules 21, 22)", &MI);
  if (objs.size() == 1 && ctx.T.classOf(objs.front()) == ObjClass::Slot) {
    // M6: a quantum-length memset and every memcpy/memmove go through mem-slots' write path.
    if (!isa<MemSetInst>(&MI) || ctx.operand(MI.getLength()).handle)
      return lowerSlotIntrinsicM6(ctx, MI, objs.front());
    if (auto *MS = dyn_cast<MemSetInst>(&MI))
      return lowerSlotMemset(ctx, *MS, objs.front());
    unimplemented("mem-qram: a memcpy/memmove into a slot array (rule 22: each cell takes the source handle or a "
                  "seed)",
                  &MI);
  }
  if (objs.size() == 1 && ctx.T.classOf(objs.front()) == ObjClass::Qram)
    return lowerQramIntrinsic(ctx, MI, objs.front());
  unimplemented("mem-qram: a memory intrinsic whose destination has " + std::to_string(objs.size()) +
                    " objects or is classical memory with a quantum operand",
                &MI);
}

// Rule 20, §1.3: ONE cqrt_qram_load_<W>[_hl](a, idx | j) -> a fresh rail. A load is pure, so it is
// executed unguarded under a quantum predicate (rule 21's reading): its result is a value arm like any
// template.
void lowerQramLoad(LoweringContext &ctx, LoadInst &ld) {
  if (Addr r = decompose(ld.getPointerOperand(), ctx.M.getDataLayout()); r.ok && isFormalQram(ctx, r.root))
    return fatptr::lowerLoad(ctx, ld);   // through a triple formal: its idx plus the offset (P1)
  QAccess acc = qramAccess(ctx, ld.getPointerOperand(), ld);
  if (ld.getType()->isPointerTy()) {
    // A pointer cell (rule 21, 88): its tag and idx halves, the loaded fat pointer's two fields.
    const Column *col = exactCell(ctx, *acc.q, acc.a, ld.getType());
    if (!col)
      unimplemented("mem-qram: a pointer load from a QRAM cell that is not a pointer (a bit view, 63)", &ld);
    QIndex idx = cellIndex(ctx, *acc.q, acc.a, ld);
    Value *tag = emitLoad(ctx, busOf(*acc.q, acc.a.root, col, ld), col[0], idx);
    Value *ix = emitLoad(ctx, busOf(*acc.q, acc.a.root, col + 1, ld), col[1], idx);
    ctx.bindFields(&ld, {Operand{tag, true}, Operand{ix, true}});
    return;
  }
  if (!ld.getType()->isIntegerTy() && !ld.getType()->isFloatingPointTy())
    unimplemented("mem-qram: a QRAM access of a non-scalar or pointer value (rules 21, 25)", &ld);
  const Column *col = exactCell(ctx, *acc.q, acc.a, ld.getType());
  if (!col)
    unimplemented("mem-qram: a QRAM access at another type than its cell (a bit view, 63)", &ld);
  QIndex idx = cellIndex(ctx, *acc.q, acc.a, ld);
  ctx.bind(&ld, emitLoad(ctx, busOf(*acc.q, acc.a.root, col, ld), *col, idx));
}

// Rule 20, §1.3: ONE cqrt_qram_store_<W>[_hl][_controlled]([c,] a, idx | j, v), v always a handle (a
// classical value is first a seed, rule 7), under the current quantum predicate's flag when there is
// one. It is recorded on the bus: the bus's item pops its stores last-in-first-out (a global bus is an
// output and is never popped). A classical value over several whole cells is one store per cell.
void lowerQramStore(LoweringContext &ctx, StoreInst &st) {
  if (Addr r = decompose(st.getPointerOperand(), ctx.M.getDataLayout()); r.ok && isFormalQram(ctx, r.root))
    return fatptr::lowerStore(ctx, st);   // through a triple formal: the deferred copy-out (P1, M2b)
  Value *val = st.getValueOperand();
  QAccess acc = qramAccess(ctx, st.getPointerOperand(), st);
  Value *flag = ctx.currentFlag();
  if (val->getType()->isPointerTy()) {
    // A pointer stored into a QRAM of pointers (rule 21, 88): its fat (tag, idx) into the two halves,
    // classical fields as seeds (rule 7).
    const Column *col = exactCell(ctx, *acc.q, acc.a, val->getType());
    if (!col)
      unimplemented("mem-qram: a pointer stored into a QRAM cell that is not a pointer (a bit view, 63)", &st);
    QIndex idx = cellIndex(ctx, *acc.q, acc.a, st);
    auto [tag, ix] = fatptr::storedFields(ctx, val);
    Value *tv = tag.handle ? tag.v : seedOf(ctx, col[0].w, tag.v);
    Value *iv = ix.handle ? ix.v : seedOf(ctx, col[1].w, ix.v);
    emitStore(ctx, busOf(*acc.q, acc.a.root, col, st), col[0], idx, tv, flag);
    emitStore(ctx, busOf(*acc.q, acc.a.root, col + 1, st), col[1], idx, iv, flag);
    return;
  }
  Operand v = ctx.operand(val);
  const Column *col = exactCell(ctx, *acc.q, acc.a, val->getType());
  if (!col) {
    if (v.handle)
      unimplemented("mem-qram: a QRAM access at another type than its cell (a bit view, 63)", &st);
    return storeClassicalBytes(ctx, acc, v.v, val->getType(), flag, st);
  }
  QIndex idx = cellIndex(ctx, *acc.q, acc.a, st);
  if (!v.handle)
    v = Operand{seedOf(ctx, col->w, v.v), true};
  emitStore(ctx, busOf(*acc.q, acc.a.root, col, st), *col, idx, v.v, flag);
}

// Rule 20: a local (alloca) or heap QRAM is ONE cqrt_qram_alloc_<W>(n) per column at its allocation
// site, all cells |0> (C's indeterminate initial contents read 0, §6); a quantum size allocates at its
// upper bound (§1.3). Each bus is a Seed rail: Uncompute pops its stores last-in-first-out and releases
// it with cqrt_qram_free once nothing reads it. The original pointer is bound to the object's QRAM base
// address (rule 21). A heap block has no host block: the allocator call is not emitted.
void allocateQram(LoweringContext &ctx, Instruction &site) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  IRBuilder<> &B = ctx.B();
  Type *i32 = Type::getInt32Ty(C), *i64 = Type::getInt64Ty(C);
  if (qramEscapes(ctx, &site))
    unimplemented("mem-qram: a QRAM object whose pointer escapes to a call (the callee reaches the bus through a "
                  "rule 21 triple and its stores are the twin's: rule 18)",
                  &site);
  QramObj q;
  Value *n = nullptr;
  auto constCells = [&](uint64_t cells) {
    if (cells > UINT32_MAX)
      unimplemented("mem-qram: a QRAM of more than 2^32 cells", &site);
    return ConstantInt::get(i32, cells);
  };
  if (auto *ai = dyn_cast<AllocaInst>(&site)) {
    q = layoutOf(ai->getAllocatedType(), DL, ai);
    uint64_t per = DL.getTypeAllocSize(ai->getAllocatedType()).getFixedValue() / q.elemBytes;
    if (auto *c = dyn_cast<ConstantInt>(ai->getArraySize())) {
      n = constCells(per * c->getZExtValue());
    } else {
      Operand cnt = ctx.operand(ai->getArraySize());
      if (cnt.handle) {
        n = constCells(per * upperBound(ai->getArraySize(), DL, site));
      } else {
        Value *x = B.CreateZExtOrTrunc(cnt.v, i32);
        n = per == 1 ? x : B.CreateMul(x, ConstantInt::get(i32, per));
      }
    }
  } else if (auto *CB = dyn_cast<CallBase>(&site)) {
    q = heapLayout(ctx, *site.getFunction(), soleQram(ctx, &site, site), &site);
    Attribute A = CB->getFnAttr(Attribute::AllocSize);
    if (!A.isValid())
      unimplemented("mem-qram: a heap QRAM from an allocator without an allocsize attribute", &site);
    auto [ai0, ai1] = A.getAllocSizeArgs();
    SmallVector<unsigned, 2> args{ai0};
    if (ai1)
      args.push_back(*ai1);
    bool allConst = true;
    uint64_t cbytes = 1;
    Value *bytes = nullptr;
    for (unsigned k : args) {
      const Value *orig = CB->getArgOperand(k);
      Operand op = ctx.operand(orig);
      Value *x;
      if (op.handle) {
        x = ConstantInt::get(i64, upperBound(orig, DL, site));
      } else {
        x = B.CreateZExtOrTrunc(op.v, i64);
      }
      if (auto *c = dyn_cast<ConstantInt>(x))
        cbytes *= c->getZExtValue();
      else
        allConst = false;
      bytes = bytes ? B.CreateMul(bytes, x) : x;
    }
    if (allConst) {
      n = constCells(cbytes / q.elemBytes);
    } else {
      Value *cells = B.CreateUDiv(bytes, ConstantInt::get(i64, q.elemBytes));
      n = B.CreateTrunc(cells, i32);
    }
  } else {
    internalError("mem-qram: a QRAM allocation site that is neither an alloca nor a call", &site);
  }
  q.site = &site;
  // Taint classifies each field column on its own (rule 20). The site has no host block once it is a
  // QRAM, so every access of every column must be a QRAM access.
  for (const Instruction &I : instructions(*site.getFunction())) {
    const Value *p = nullptr;
    if (auto *ld = dyn_cast<LoadInst>(&I))
      p = ld->getPointerOperand();
    else if (auto *s = dyn_cast<StoreInst>(&I))
      p = s->getPointerOperand();
    else if (auto *mi = dyn_cast<MemIntrinsic>(&I))
      p = mi->getDest();
    if (!p)
      continue;
    Addr pa = decompose(p, DL);
    if (!pa.ok || pa.root != &site)
      continue;
    for (ObjectId x : ctx.T.provenance(p, ctx.S))
      if (ctx.T.classOf(x) != ObjClass::Qram)
        unimplemented("mem-qram: an array of structs whose field columns are of different classes (a QRAM "
                      "column beside a slot or classical column, rule 20)",
                      &I);
  }
  SmallVector<Value *, 2> hs;
  for (const Column &c : q.cols) {
    abi::CoreSpec spec{abi::Core::QramAlloc, c.w};
    CallInst *a = ctx.emitCore(spec, {n});
    ctx.unc().recordCore(a, spec, {Operand{n, false}}, 0);
    hs.push_back(a);
  }
  q.buses[&site] = hs;
  QramState &st = qramStates()[&ctx.out()];
  if (!st.objs.emplace(&site, std::move(q)).second)
    unimplemented("mem-qram: a QRAM allocation site executed twice in one output function (a loop or an "
                  "inlined call re-allocating the object)",
                  &site);
  ctx.bind(&site, qramBase(ctx, soleQram(ctx, &site, site)));
}

// The end of a local QRAM's scope (llvm.lifetime.end) or of a heap QRAM (free, rule 16, 186): nothing is
// emitted here (a heap QRAM has no host block to free). The bus's item (every store popped, then
// cqrt_qram_free) is Uncompute's, placed once nothing reads the bus; no access follows the lifetime end
// (an access after free is undefined, outside the domain), so the release is at or before the end of the
// object's life, on every path, whether the free is conditional or not.
void endQramLifetime(LoweringContext &ctx, ObjectId o, Instruction *at) {
  auto *CB = dyn_cast_or_null<CallBase>(at);
  bool lifetimeEnd = CB && isa<IntrinsicInst>(CB) &&
                     cast<IntrinsicInst>(CB)->getIntrinsicID() == Intrinsic::lifetime_end;
  if (!lifetimeEnd && !(CB && isFree(*CB)))
    unimplemented("mem-qram: a QRAM lifetime end at other than lifetime.end or free (stackrestore, 192)", at);
  (void)o;
  Addr a = decompose(CB->getArgOperand(lifetimeEnd ? 1 : 0), ctx.M.getDataLayout());
  QramState &st = qramStates()[&ctx.out()];
  const Value *site = a.ok ? st.siteOf.lookup(a.root) : nullptr;
  if (a.ok && st.objs.count(site ? site : a.root))
    return;
  internalError("mem-qram: the lifetime end of a QRAM this function did not allocate", at);
}

// M5 (cq-arch 2026-11-01), CR §1.3: realloc of a heap QRAM is cqrt_qram_realloc_<W>(a, n) -> a' per
// column, n the new size in cells (a quantum size: its upper bound), recorded with Uncompute (its _unc
// after every store through a' was popped). a' replaces a for every access through the realloc result;
// the result is bound to the same QRAM base (the same object, no cell moves).
void reallocQram(LoweringContext &ctx, CallBase &CB) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  IRBuilder<> &B = ctx.B();
  Type *i32 = Type::getInt32Ty(C), *i64 = Type::getInt64Ty(C);
  ObjectId o = soleQram(ctx, &CB, CB);
  const Value *old = getReallocatedOperand(&CB);
  if (!old)
    internalError("mem-qram: reallocQram of a call that is not a realloc", &CB);
  if (soleQram(ctx, old, CB) != o)
    internalError("mem-qram: a realloc whose result is another object than its operand", &CB);
  if (ctx.currentFlag())
    unimplemented("mem-qram: a realloc of a QRAM under a quantum predicate (the logical size would be a merge)", &CB);
  Addr a = decompose(old, DL);
  if (!a.ok || a.off || !a.terms.empty())
    unimplemented("mem-qram: a realloc of a pointer that is not the block's root", &CB);
  QramObj &q = qramObj(ctx, a.root, CB);
  auto it = q.buses.find(a.root);
  if (it == q.buses.end())
    unimplemented("mem-qram: a realloc of a QRAM pointer root lowered after it", &CB);
  SmallVector<Value *, 2> olds = it->second;
  Attribute A = CB.getFnAttr(Attribute::AllocSize);
  if (!A.isValid() || A.getAllocSizeArgs().second)
    unimplemented("mem-qram: a realloc without a one-argument allocsize attribute", &CB);
  const Value *size = CB.getArgOperand(A.getAllocSizeArgs().first);
  Operand sz = ctx.operand(size);
  Value *n;
  if (sz.handle) {
    uint64_t cells = upperBound(size, DL, CB) / q.elemBytes;
    if (cells > UINT32_MAX)
      unimplemented("mem-qram: a QRAM of more than 2^32 cells", &CB);
    n = ConstantInt::get(i32, cells);
  } else if (auto *c = dyn_cast<ConstantInt>(sz.v)) {
    n = ConstantInt::get(i32, c->getZExtValue() / q.elemBytes);
  } else {
    n = B.CreateTrunc(B.CreateUDiv(B.CreateZExtOrTrunc(sz.v, i64), ConstantInt::get(i64, q.elemBytes)), i32);
  }
  SmallVector<Value *, 2> hs;
  for (unsigned k = 0; k < q.cols.size(); ++k) {
    abi::CoreSpec spec{abi::Core::QramRealloc, q.cols[k].w};
    CallInst *a2 = ctx.emitCore(spec, {olds[k], n});
    ctx.unc().recordCore(a2, spec, {Operand{olds[k], true}, Operand{n, false}}, 0);
    hs.push_back(a2);
  }
  q.buses[&CB] = hs;
  qramStates()[&ctx.out()].siteOf[&CB] = q.site;
  ctx.bind(&CB, qramBase(ctx, o));
}
} // namespace cq::mem

namespace cq::mem {
// ==== triple formals (P1, M2, M2b, U3; CR rules 18, 21, §1.4; 190, 191) ==========================
//
// CONTRACT
//  - A pointer formal taint passes as a rule 21 triple (T4 Triple/TripleCount) onto a QRAM object is,
//    in its clone, a one-column QRAM over the caller's bus (registerFormalQram, from fatptr::bindFormal):
//    loads are ordinary QRAM loads at the formal's idx plus the GEP offset (fatptr derives the cell).
//  - M2. The clone's stores through such formals are the rule 18 copy-out (deferFormalStore): v is copied
//    into a fresh rail (alloc 0, copy; Role::Result) where the store stands, and the store itself is
//    emitted after the body's uncompute (emitCalleeQramStores), in program order, recording nothing; its
//    rails are returned after the result. Each store must be straight-line in the clone (its block runs
//    on every path: it post-dominates the entry, dominates every return, lies on no cycle), at a
//    constant cell offset from the formal (the caller's record is the actual's idx plus that constant),
//    with no load through any such formal after it (the store is deferred: a later load would not see
//    it), and the clone has no control flag. Any other use of a pointer derived from the formal (a call,
//    a memory intrinsic, free, realloc, a compare, a merge, the pointer stored as a value) is
//    unimplemented.
//  - U3. In the caller, after recordCall: Uncompute::noteCallBusRead(fwd, bus) once per bus of a
//    Qram-pointee triple formal, then per stored rail in order recordCore(fwd, QramStore[_hl], {bus,
//    idx + offset, v}, bus): the caller pops the clone's stores (LIFO with its own), then the twin
//    recomputes from the cells as the clone's loads saw them (191). A global QRAM's bus is never popped,
//    so a clone storing into one is unimplemented.

namespace {

std::map<const Function *, SmallVector<std::tuple<Value *, Column, QIndex, Value *>, 2>> &deferredStores() {
  static std::map<const Function *, SmallVector<std::tuple<Value *, Column, QIndex, Value *>, 2>> d;
  return d;
}

// The loads and stores through pointers derived from formal A by GEPs and bitcasts (and, unless
// strict, phis and selects). Any other use is unimplemented.
struct FormalUses {
  SmallVector<const LoadInst *, 4> loads;
  SmallVector<const StoreInst *, 4> stores;
};

FormalUses formalUses(const Argument &A, bool strict) {
  FormalUses out;
  SmallVector<const Value *, 8> work{&A};
  SmallPtrSet<const Value *, 16> seen{&A};
  while (!work.empty()) {
    const Value *v = work.pop_back_val();
    for (const Use &u : v->uses()) {
      const User *usr = u.getUser();
      if (auto *ld = dyn_cast<LoadInst>(usr)) {
        if (!ld->isSimple())
          unimplemented("mem-qram: a volatile or atomic access through a rule 21 triple formal", ld);
        out.loads.push_back(ld);
        continue;
      }
      if (auto *st = dyn_cast<StoreInst>(usr); st && st->getPointerOperand() == v && st->getValueOperand() != v) {
        if (!st->isSimple())
          unimplemented("mem-qram: a volatile or atomic access through a rule 21 triple formal", st);
        out.stores.push_back(st);
        continue;
      }
      bool walk = isa<GEPOperator>(usr) || isa<BitCastOperator>(usr) ||
                  (!strict && (isa<PHINode>(usr) || isa<SelectInst>(usr)));
      if (walk) {
        if (seen.insert(usr).second)
          work.push_back(usr);
        continue;
      }
      unimplemented("mem-qram: a use of a pointer derived from a rule 21 triple formal other than a load, a store "
                    "or address arithmetic (a call, a memory intrinsic, free, realloc, a compare, a merge or an "
                    "escape of the triple: P1, M2)",
                    usr);
    }
  }
  return out;
}

Type *cellTypeOfUses(const Argument &A, bool strict) {
  FormalUses u = formalUses(A, strict);
  Type *t = nullptr;
  auto see = [&](Type *x, const Instruction *I) {
    if (!x->isIntegerTy() && !x->isFloatingPointTy())
      unimplemented("mem-qram: a pointer, vector or aggregate access through a rule 21 triple formal (rules 21, 25, "
                    "26)",
                    I);
    if (t && t != x)
      unimplemented("mem-qram: a rule 21 triple formal accessed as two types (a bit view, 63)", I);
    t = x;
  };
  for (const LoadInst *ld : u.loads)
    see(ld->getType(), ld);
  for (const StoreInst *st : u.stores)
    see(st->getValueOperand()->getType(), st);
  if (!t)
    unimplemented("mem-qram: a rule 21 triple formal its clone never loads or stores through (its cell type is "
                  "the caller's)",
                  &A);
  return t;
}

bool isQramTriple(const TaintInfo &T, const Specialization &S, const Argument &A) {
  if (!A.getType()->isPointerTy())
    return false;
  PtrFormal pf = T.pointerFormal(S, A.getArgNo());
  return pf.abi != PtrAbi::Raw && pf.pointee == ObjClass::Qram;
}

struct FormalStore {
  unsigned argNo;
  int64_t cell;   // cell offset from the formal's idx
  Type *ty;
  const StoreInst *st;
};

// M2's analysis: the clone's stores through Qram-pointee triple formals in program order, every shape
// outside the contract unimplemented.
SmallVector<FormalStore, 2> formalQramStores(const TaintInfo &T, const Specialization &S) {
  Function &F = *S.F;
  const DataLayout &DL = F.getParent()->getDataLayout();
  SmallVector<FormalStore, 2> out;
  SmallVector<const LoadInst *, 8> loads;
  for (Argument &A : F.args()) {
    if (!isQramTriple(T, S, A))
      continue;
    Type *cellTy = cellTypeOfUses(A, /*strict=*/true);
    int64_t E = int64_t(DL.getTypeAllocSize(cellTy).getFixedValue());
    FormalUses u = formalUses(A, /*strict=*/true);
    loads.append(u.loads.begin(), u.loads.end());
    for (const StoreInst *st : u.stores) {
      Addr a = decompose(st->getPointerOperand(), DL);
      if (!a.ok || a.root != &A || !a.terms.empty())
        unimplemented("mem-qram: a store through a QRAM triple formal at a run-time offset (M2, U3: the caller "
                      "records it at the actual's idx plus a constant)",
                      st);
      if (a.off % E)
        unimplemented("mem-qram: a store through a QRAM triple formal inside a cell (a bit view, 63)", st);
      out.push_back({A.getArgNo(), a.off / E, cellTy, st});
    }
  }
  if (out.empty())
    return out;
  if (S.ctl)
    unimplemented("mem-qram: a store through a QRAM triple formal in a clone with a control flag (a _controlled "
                  "deferred store: M2)",
                  out.front().st);
  DominatorTree DT(F);
  PostDominatorTree PDT(F);
  LoopInfo LI(DT);
  for (const FormalStore &fs : out) {
    const BasicBlock *b = fs.st->getParent();
    bool straight = PDT.dominates(b, &F.getEntryBlock()) && !LI.getLoopFor(b);
    for (const BasicBlock &r : F)
      if (isa<ReturnInst>(r.getTerminator()))
        straight &= DT.dominates(b, &r);
    if (!straight)
      unimplemented("mem-qram: a store through a QRAM triple formal under a branch or in a loop of the clone (M2: "
                    "the clone's stores are deferred in program order)",
                    fs.st);
  }
  llvm::sort(out, [&](const FormalStore &x, const FormalStore &y) {
    return x.st != y.st && DT.dominates(x.st, y.st);
  });
  for (const LoadInst *ld : loads)
    for (const FormalStore &fs : out)
      if (isPotentiallyReachable(fs.st, ld, nullptr, &DT, &LI))
        unimplemented("mem-qram: a load through a QRAM triple formal after a store through one (M2b defers the "
                      "store to the clone's end)",
                      ld);
  return out;
}

// The column a caller's bus belongs to (nullptr when the bus is no QRAM of this output function), and
// whether its object is a global QRAM.
const Column *columnOfBus(LoweringContext &ctx, Value *bus, bool &global) {
  for (auto &[site, q] : qramStates()[&ctx.out()].objs)
    for (auto &[root, hs] : q.buses)
      for (unsigned k = 0; k < hs.size(); ++k)
        if (hs[k] == bus) {
          global = isa<GlobalVariable>(site);
          return &q.cols[k];
        }
  return nullptr;
}

} // namespace

Type *formalCellType(const Argument &A) { return cellTypeOfUses(A, /*strict=*/false); }

HostTriple hostTriple(LoweringContext &ctx, const Value *ptr, const Instruction &at) {
  const DataLayout &DL = ctx.M.getDataLayout();
  Addr a = decompose(ptr, DL);
  if (!a.ok || !(isa<AllocaInst>(a.root) || isa<GlobalVariable>(a.root)))
    unimplemented("mem-qram: a slot or host pointer crossing a clone boundary whose object is not a local or "
                  "global (rule 21 triple: its cell count)",
                  &at);
  Type *objTy;
  uint64_t bytes;
  if (auto *ai = dyn_cast<AllocaInst>(a.root)) {
    auto sz = ai->getAllocationSize(DL);
    if (!sz || sz->isScalable())
      unimplemented("mem-qram: a variable-size local crossing a clone boundary as a rule 21 triple (its cell "
                    "count)",
                    &at);
    objTy = ai->getAllocatedType();
    bytes = sz->getFixedValue();
  } else {
    auto *gv = cast<GlobalVariable>(a.root);
    objTy = gv->getValueType();
    bytes = DL.getTypeAllocSize(objTy).getFixedValue();
  }
  uint64_t cb = scalarCellBytes(objTy, DL, &at);
  // mem-slots' cells are the scalar element; an object accessed at another width has other cells
  // (a bit view, or -O1's punned local, 90).
  ArrayRef<ObjectId> objs = ctx.T.provenance(ptr, ctx.S);
  if (objs.size() != 1)
    internalError("mem-qram: hostTriple of a pointer with other than one object", &at);
  for (const Access &x : accessesOf(ctx, *at.getFunction(), objs.front()))
    if (DL.getTypeAllocSize(x.ty).getFixedValue() != cb)
      unimplemented("mem-qram: an object crossing a clone boundary as a rule 21 triple that is accessed at another "
                    "width than its cell (a bit view, 63)",
                    x.I);
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  Type *i64 = Type::getInt64Ty(C), *i32 = Type::getInt32Ty(C);
  if (a.off % int64_t(cb))
    unimplemented("mem-qram: a rule 21 triple pointing inside a cell (a bit view, 63)", &at);
  Value *j = ConstantInt::get(i64, a.off / int64_t(cb), true);
  for (auto &[v, stride] : a.terms) {
    if (stride % int64_t(cb))
      unimplemented("mem-qram: a rule 21 triple whose GEP stride is not a whole number of cells", &at);
    Operand x = ctx.operand(v);
    if (x.handle)
      internalError("mem-qram: a quantum term in a classical triple's address", &at);
    Value *t = B.CreateSExtOrTrunc(x.v, i64);
    if (stride / int64_t(cb) != 1)
      t = B.CreateMul(t, ConstantInt::get(i64, stride / int64_t(cb), true));
    j = B.CreateAdd(j, t);
  }
  if (bytes / cb > UINT32_MAX)
    unimplemented("mem-qram: a rule 21 triple onto an object of more than 2^32 cells", &at);
  return {a.root, B.CreateTrunc(j, i32), ConstantInt::get(i32, bytes / cb), cb};
}

void registerFormalQram(LoweringContext &ctx, const Argument &A, Value *bus) {
  QramState &st = qramStates()[&ctx.out()];
  QramObj q = layoutOf(cellTypeOfUses(A, /*strict=*/true), ctx.M.getDataLayout(), &A);
  if (q.cols.size() != 1)
    internalError("mem-qram: a triple formal's QRAM with other than one column", &A);
  q.site = &A;
  q.buses[&A] = {bus};
  if (!st.objs.emplace(&A, std::move(q)).second)
    internalError("mem-qram: a triple formal registered twice", &A);
  st.formals.insert(&A);
}

bool isFormalQram(LoweringContext &ctx, const Value *root) {
  return qramStates()[&ctx.out()].formals.count(root) != 0;
}

void deferFormalStore(LoweringContext &ctx, const Value *root, Operand idx, Type *ty, Value *v, Value *flag,
                      const Instruction &at) {
  if (flag)
    unimplemented("mem-qram: a store through a QRAM triple formal under a quantum predicate (M2)", &at);
  QramObj &q = qramObj(ctx, root, at);
  const Column &c = firstColumn(ctx, q, ty, at);
  CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, c.w}, {Constant::getNullValue(c.cellTy)});
  RailId fid = ctx.unc().recordSeed(f);
  abi::CoreSpec cp{abi::Core::Copy, c.w};
  CallInst *cpy = ctx.emitCore(cp, {v, f});
  ctx.unc().recordCore(cpy, cp, {Operand{v, true}, Operand{f, true}}, fid);
  ctx.unc().setRole(fid, Role::Result);
  deferredStores()[&ctx.out()].push_back({busOf(q, root, &c, at), c, fatIndex(ctx, idx), f});
}

unsigned calleeQramStoreCount(const TaintInfo &T, const Specialization &callee) {
  return unsigned(formalQramStores(T, callee).size());
}

SmallVector<Value *, 2> emitCalleeQramStores(LoweringContext &ctx) {
  SmallVector<Value *, 2> out;
  auto it = deferredStores().find(&ctx.out());
  if (it == deferredStores().end())
    return out;
  for (auto &[bus, col, idx, copy] : it->second) {
    ctx.emitCore(abi::CoreSpec{abi::Core::QramStore, col.w, false, !idx.quantum}, {bus, idx.v, copy});
    out.push_back(copy);
  }
  deferredStores().erase(it);
  return out;
}

void noteCalleeQramStores(LoweringContext &ctx, const CallBase &orig, const Specialization &callee, CallInst *fwd,
                          ArrayRef<Value *> storedRails) {
  const TaintInfo &T = ctx.T;
  SmallVector<FormalStore, 2> stores = formalQramStores(T, callee);
  if (stores.size() != storedRails.size())
    internalError("mem-qram: noteCalleeQramStores with another rail count than the clone's stores", &orig);
  // The forward's arguments (calls::formalLayout): [ctl flag], per formal its scalar leaves, a raw
  // pointer as one, a triple as (object, tag, idx[, cell count]).
  std::map<unsigned, std::pair<Value *, Operand>> triple;   // argNo -> (bus, idx)
  SmallVector<Value *, 2> buses;
  unsigned p = callee.ctl ? 1 : 0;
  size_t d = 0;
  for (Argument &A : callee.F->args()) {
    if (!A.getType()->isPointerTy()) {
      size_t n = T.fieldMask(&A, callee).size();
      p += unsigned(n);
      d += n;
      continue;
    }
    PtrFormal pf = T.pointerFormal(callee, A.getArgNo());
    unsigned n = pf.abi == PtrAbi::Raw ? 1 : pf.abi == PtrAbi::Triple ? 3 : 4;
    if (pf.abi != PtrAbi::Raw && pf.pointee == ObjClass::Qram) {
      if (p + 3 > fwd->arg_size() || d + 2 > callee.mask.size())
        internalError("mem-qram: a clone call with fewer arguments than its triple formals", fwd);
      Value *bus = fwd->getArgOperand(p);
      triple[A.getArgNo()] = {bus, Operand{fwd->getArgOperand(p + 2), callee.mask[d + 1] == '1'}};
      if (!llvm::is_contained(buses, bus))
        buses.push_back(bus);
    }
    p += n;
    d += pf.digits;
  }
  if (p != fwd->arg_size())
    internalError("mem-qram: a clone call whose arguments do not match its formals' layout", fwd);
  for (Value *bus : buses) {
    bool global = false;
    if (!columnOfBus(ctx, bus, global))
      internalError("mem-qram: a clone call's QRAM triple whose bus is no QRAM of this function", fwd);
    if (global && !stores.empty())
      unimplemented("mem-qram: a clone storing into a global QRAM through a triple formal (a global bus is never "
                    "popped: the twin would read the stored cells)",
                    &orig);
    ctx.unc().noteCallBusRead(fwd, ctx.unc().idOf(bus));
  }
  IRBuilder<> &B = ctx.B();
  for (size_t k = 0; k < stores.size(); ++k) {
    auto [bus, idx] = triple.at(stores[k].argNo);
    if (stores[k].cell) {
      if (idx.handle)
        unimplemented("mem-qram: a clone's store through a QRAM triple formal with a quantum idx at a cell offset "
                      "(U3: the caller's index would be a template)",
                      stores[k].st);
      idx = Operand{B.CreateAdd(idx.v, ConstantInt::get(idx.v->getType(), stores[k].cell, true)), false};
    }
    bool global = false;
    const Column *col = columnOfBus(ctx, bus, global);
    RailType w = railTypeOf(stores[k].ty);
    if (!sameCellType(ctx.M.getDataLayout(), stores[k].ty, *col))
      unimplemented("mem-qram: a clone storing through a QRAM triple formal at another type than the caller's "
                    "cells (a bit view, 63)",
                    stores[k].st);
    abi::CoreSpec spec{abi::Core::QramStore, w, false, !idx.handle};
    ctx.unc().recordCore(fwd, spec, {Operand{bus, true}, idx, Operand{storedRails[k], true}}, ctx.unc().idOf(bus));
  }
}
} // namespace cq::mem
