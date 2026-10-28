// Module mem-slots (cq-w1-mem-slots): slot arrays of handles, CR rule 20.
//
// A memory object that may hold a handle and is only ever accessed at classical offsets is a SLOT
// array: a classical array of i32 handle cells. This file lowers its allocation, its loads and stores
// at classical offsets and its lifetime end. Everything else about memory (QRAM, QROM, memory
// intrinsics, fat pointers) belongs to the sibling modules.
//
// CONTRACT (the frozen Memory.h states only the signatures; what siblings may rely on is stated here)
//
// Layout. One i32 handle per CELL. A cell is the scalar element of the object (the allocated type with
// arrays stripped; for a parameter or a heap block, the type every access in the function uses).
//  - allocateSlots(alloca) emits `alloca i32, cells` (align >= 4) and binds the original alloca to it
//    as a classical operand: ctx.operand(origAlloca) is the base of the handle cells.
//  - allocateSlots(heap call) keeps the call; with a cell size other than 4 bytes its byte size n
//    becomes n / cell * 4 (75). The original call is bound to the new call.
//  - A parameter or a global keeps its pointer; a global's cells must be at least 4 bytes (the
//    handle is stored in the first 4 bytes of each cell).
//  - The cell index of an access is its byte offset from the object's root divided by the cell size,
//    re-emitted over i32 cells (-O1's byte GEPs over i8 cells are cell indices, 58). An access at
//    another width than the cell (a bit view, 63) is unimplemented.
//  - A _Bool cell (one-byte cells whose loads all carry !range [0, 2) and whose stores all store a
//    zext from i1 or the constant 0 / 1) holds an i1 rail; its i8 load is bound to that i1 rail.
//
// Cell contents. A slot cell is homogeneous (rule 20): a classical store materialises its value as a
// seed rail alloc_<W>(v) (rule 7). A store under a quantum predicate stores
// select(predicate, value, old) into a fresh rail (rules 9, 20).
//
// Rails through memory. Uncompute (rule 5) sees SSA uses only, so a rail read back through a cell must
// be the stored Value itself, or a rail that is never resolved:
//  - FORWARDING: a load whose cell was written (or read) by a dominating access with the same address
//    and no possible write to the object on any path in between (none of these paths re-executes the
//    dominating access) is bound to the handle that access left in the cell. No IR is emitted.
//  - ALIAS: any other load emits `load i32` of the cell; the handle is recorded as an external rail
//    (Role::UserRegister: never resolved here, like a caller's formal, Construct.cpp). That is sound
//    only when every rail that can be in the cell is kept as well, so:
//      * a local object (alloca, heap block of this function) with an ALIAS load is DYNAMIC: a store
//        into it may store only a register (a cq_theta result, an alias) or a classical value, whose
//        seed is then a register (the cells of 58/59: "user registers seeded |0>, they stay
//        allocated"); a computed rail stored into it is unimplemented (its clean-up needs the loops
//        module's reverse loop or a memory-aware uncompute: 52, 67, 75);
//      * a local object whose every load forwards is STATIC: stores change no role;
//      * a parameter's cells are the caller's rails (60); in an entry a stored rail that is not a
//        register is an OUTPUT (71's reasoning: the caller reads it); a store in a clone is
//        unimplemented (rule 18 copy-out, 31);
//      * a global: an external one is an output (71); an alias load of a global is unimplemented
//        (another function or invocation may have left a rail there: 67);
//      * an object whose pointer escapes to a call (or anywhere but loads, stores and the memory and
//        lifetime intrinsics) may have its cells written by the callee: an alias load of it, and any
//        store into it other than of a register, are unimplemented (rule 18 twins: 31, 52, 106).
//
// Lifetime. endSlotLifetime emits the classical free of a heap block and nothing else: forwarded
// rails follow their own roles, alias and dynamic-cell rails are kept.
//
// Rails of memset/memcpy writes (mem-qram, rule 22) follow the same rules: a seed written into a
// DYNAMIC object's cell is a register (58's memset).
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
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq::mem {

namespace {

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

// ---- emission -----------------------------------------------------------------------------------

struct Site { ObjectId o; ObjInfo *info; Addr a; };

Site siteOf(LoweringContext &ctx, FnState &st, const Instruction &I, const Value *ptr, Type *ty) {
  ArrayRef<ObjectId> objs = ctx.T.provenance(ptr, ctx.S);
  if (objs.size() != 1)
    unimplemented("mem-slots: a classical pointer into " + std::to_string(objs.size()) +
                      " objects (a pointer phi/select over slot objects)",
                  &I);
  if (ctx.T.classOf(objs.front()) != ObjClass::Slot)
    unimplemented("mem-slots: a slot access through a pointer whose object is not a slot object", &I);
  Addr a = decompose(ptr, ctx.M.getDataLayout());
  if (!a.ok)
    unimplemented("mem-slots: a slot access whose address is not an object plus GEP offsets (a pointer phi, "
                  "select or load: no static cell index)",
                  &I);
  if (ctx.T.objectOf(a.root) != objs.front())
    internalError("mem-slots: the address root is not the object taint names", &I);
  ObjInfo &info = objInfo(ctx, st, a.root, objs.front());
  uint64_t bytes = ctx.M.getDataLayout().getTypeAllocSize(ty).getFixedValue();
  if (bytes != info.cellBytes)
    unimplemented("mem-slots: a " + std::to_string(bytes) + "-byte access of " + std::to_string(info.cellBytes) +
                      "-byte slot cells (a bit view of a cell, 63)",
                  &I);
  if (info.boolCells && !ty->isIntegerTy(8))
    internalError("mem-slots: a _Bool cell accessed as another type", &I);
  return Site{objs.front(), &info, a};
}

RailType cellRail(const ObjInfo &info, Type *ty, const Instruction &I) {
  if (info.boolCells)
    return RailType{Kind::Int, 1};
  if (!ty->isIntegerTy() && !ty->isFloatingPointTy())
    unimplemented("mem-slots: a slot cell accessed as a non-scalar type", &I);
  return railTypeOf(ty);
}

// The i32 cell pointer of an access, in the new IR.
Value *cellPointer(LoweringContext &ctx, const Site &s, const Instruction &I) {
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  Operand base = ctx.operand(s.a.root);
  if (base.handle)
    internalError("mem-slots: the base of a slot object is a rail", &I);
  int64_t cb = int64_t(s.info->cellBytes);
  if (s.a.off % cb)
    unimplemented("mem-slots: a constant byte offset that is not a whole cell", &I);
  Type *i64 = Type::getInt64Ty(C);
  Value *idx = nullptr;
  for (auto &[v, stride] : s.a.terms) {
    if (stride % cb)
      unimplemented("mem-slots: a GEP stride that is not a whole number of cells", &I);
    Operand x = ctx.operand(v);
    if (x.handle)
      internalError("mem-slots: a quantum index into a slot object (QRAM, rule 20)", &I);
    Value *t = B.CreateSExtOrTrunc(x.v, i64);
    if (stride / cb != 1)
      t = B.CreateMul(t, ConstantInt::get(i64, stride / cb, true));
    idx = idx ? B.CreateAdd(idx, t) : t;
  }
  if (s.a.off) {
    Value *k = ConstantInt::get(i64, s.a.off / cb, true);
    idx = idx ? B.CreateAdd(idx, k) : k;
  }
  Type *i32 = Type::getInt32Ty(C);
  if (s.info->kind == RootKind::Global && cb != 4) {
    if (cb < 4)
      unimplemented("mem-slots: a global slot object with cells narrower than a handle", &I);
    if (!idx)
      return base.v;
    return B.CreateInBoundsGEP(Type::getInt8Ty(C), base.v, B.CreateMul(idx, ConstantInt::get(i64, cb)));
  }
  if (!idx)
    return base.v;
  return B.CreateInBoundsGEP(i32, base.v, idx);
}

// The handle a cell holds at I (a load, or the old value at a guarded store).
Operand readCell(LoweringContext &ctx, FnState &st, const Site &s, const Instruction &I, Type *ty) {
  if (const Instruction *src = sourceOf(ctx, st, *s.info, s.o, &I, s.a, ty)) {
    auto it = st.lowered.find(src);
    if (it == st.lowered.end())
      internalError("mem-slots: the access a slot load forwards from has not been lowered", &I);
    return it->second;
  }
  switch (s.info->kind) {
  case RootKind::Global:
    unimplemented("mem-slots: a load of a global slot cell no dominating access of this function wrote (its "
                  "rail's owner is unknown: 67)",
                  &I);
  case RootKind::Local:
  case RootKind::Heap:
  case RootKind::Param:
    if (s.info->escaping)
      unimplemented("mem-slots: a load of a slot cell a callee may have written (the object's pointer escapes "
                    "to a call: rule 18 twins, 31, 52, 106)",
                    &I);
    break;
  }
  LoadInst *h = ctx.B().CreateAlignedLoad(handleTy(ctx.M.getContext()), cellPointer(ctx, s, I), Align(4));
  ctx.unc().recordExternal(h, Role::UserRegister);
  st.registers.insert(h);
  return Operand{h, true};
}

bool isThetaResult(const Value *v) {
  if (auto *z = dyn_cast<ZExtInst>(v); z && z->getSrcTy()->isIntegerTy(1))
    v = z->getOperand(0);
  if (auto *fr = dyn_cast<FreezeInst>(v))
    v = fr->getOperand(0);
  auto *call = dyn_cast<CallInst>(v);
  const Function *f = call ? call->getCalledFunction() : nullptr;
  return f && f->getName().starts_with("cq_theta_");
}

} // namespace

void allocateSlots(LoweringContext &ctx, Instruction &site) {
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  const DataLayout &DL = ctx.M.getDataLayout();
  FnState &st = stateOf(ctx, site);
  ArrayRef<ObjectId> objs = ctx.T.provenance(&site, ctx.S);
  if (objs.size() != 1)
    unimplemented("mem-slots: an allocation site that is " + std::to_string(objs.size()) +
                      " objects (an array of structs holding handles: one slot array per field column, 168)",
                  &site);
  ObjInfo &info = objInfo(ctx, st, &site, objs.front());
  if (auto *ai = dyn_cast<AllocaInst>(&site)) {
    uint64_t perElem = DL.getTypeAllocSize(ai->getAllocatedType()).getFixedValue() / info.cellBytes;
    Type *i64 = Type::getInt64Ty(C);
    Operand n = ctx.operand(ai->getArraySize());
    if (n.handle)
      internalError("mem-slots: a slot array of quantum length (QRAM, rule 20)", &site);
    Value *count = B.CreateZExtOrTrunc(n.v, i64);
    if (perElem != 1)
      count = B.CreateMul(count, ConstantInt::get(i64, perElem));
    AllocaInst *na = B.CreateAlloca(handleTy(C), count);
    na->setAlignment(std::max(ai->getAlign(), Align(4)));
    ctx.bindFields(&site, {Operand{na, false}});
    return;
  }
  auto *CB = dyn_cast<CallBase>(&site);
  if (!CB)
    internalError("mem-slots: allocateSlots of a site that is neither an alloca nor an allocation call", &site);
  CallBase *nc = cast<CallBase>(CB->clone());
  for (unsigned i = 0; i < CB->arg_size(); ++i) {
    Operand a = ctx.operand(CB->getArgOperand(i));
    if (a.handle)
      unimplemented("mem-slots: a heap slot block of quantum size (QRAM realloc, rule 16, 192)", &site);
    nc->setArgOperand(i, a.v);
  }
  if (info.cellBytes != 4) {
    Attribute as = CB->getFnAttr(Attribute::AllocSize);
    if (!as.isValid())
      as = CB->getCalledFunction() ? CB->getCalledFunction()->getFnAttribute(Attribute::AllocSize) : Attribute();
    if (!as.isValid() || as.getAllocSizeArgs().second)
      unimplemented("mem-slots: a heap slot block with cells of other than 4 bytes from an allocator without a "
                    "single allocsize argument",
                    &site);
    unsigned k = as.getAllocSizeArgs().first;
    Value *n = nc->getArgOperand(k);
    Value *cells = B.CreateUDiv(n, ConstantInt::get(n->getType(), info.cellBytes));
    nc->setArgOperand(k, B.CreateMul(cells, ConstantInt::get(n->getType(), 4)));
  }
  if (!site.getName().empty())
    nc->setName(site.getName());
  B.Insert(nc);
  ctx.bindFields(&site, {Operand{nc, false}});
}

void lowerSlotLoad(LoweringContext &ctx, LoadInst &ld) {
  FnState &st = stateOf(ctx, ld);
  if (!ctx.T.isQuantum(&ld, ctx.S))
    unimplemented("mem-slots: a classical load from a slot object (a classical cell in a handle object: "
                  "records, 163, 164)",
                  &ld);
  Site s = siteOf(ctx, st, ld, ld.getPointerOperand(), ld.getType());
  cellRail(*s.info, ld.getType(), ld);
  Operand h = readCell(ctx, st, s, ld, ld.getType());
  st.lowered[&ld] = h;
  ctx.bindFields(&ld, {h});
}

void lowerSlotStore(LoweringContext &ctx, StoreInst &stI) {
  FnState &st = stateOf(ctx, stI);
  const Value *v = stI.getValueOperand();
  Site s = siteOf(ctx, st, stI, stI.getPointerOperand(), v->getType());
  RailType w = cellRail(*s.info, v->getType(), stI);
  IRBuilder<> &B = ctx.B();

  enum class What { Register, Seed, Computed } what;
  Operand val = ctx.operand(v);
  if (s.info->boolCells && val.handle)
    if (auto *z = dyn_cast<ZExtInst>(v); z && z->getSrcTy()->isIntegerTy(1)) {
      Operand src = ctx.operand(z->getOperand(0));
      if (src.handle && src.v != val.v)
        unimplemented("mem-slots: a _Bool cell stored from a zext template: the cell holds the i1 rail and the "
                      "zext is a representation change (spine, cq-sj2j)",
                      &stI);
    }
  if (Value *flag = ctx.currentFlag()) {
    (void)flag;
    // Rules 9, 20: under a quantum predicate the cell receives select(predicate, value, old).
    Operand old = readCell(ctx, st, s, stI, v->getType());
    if (!val.handle && s.info->boolCells)
      val.v = B.CreateTrunc(val.v, Type::getInt1Ty(ctx.M.getContext()));
    const Pred &p = ctx.currentPredicate();
    Value *sel = selectChain(ctx, {{p, val}, {!p, old}}, w);
    val = Operand{sel, true};
    what = What::Computed;
  } else if (!val.handle) {
    // Rule 20: a slot cell is homogeneous; a classical store materialises a seed rail (rule 7).
    if (v->getType()->isPointerTy())
      unimplemented("mem-slots: a pointer stored into a slot object", &stI);
    Value *x = val.v;
    if (s.info->boolCells)
      x = B.CreateTrunc(x, Type::getInt1Ty(ctx.M.getContext()));
    if (x->getType() != irTypeOf(ctx.M.getContext(), w))
      internalError("mem-slots: a classical stored value of another type than its cell's rail", &stI);
    CallInst *alloc = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {x});
    ctx.unc().recordSeed(alloc);
    val = Operand{alloc, true};
    what = What::Seed;
  } else {
    what = st.registers.count(val.v) || isThetaResult(v) ? What::Register : What::Computed;
  }

  if (what != What::Register) {
    RailId id = ctx.unc().idOf(val.v);
    switch (s.info->kind) {
    case RootKind::Local:
    case RootKind::Heap:
      if (s.info->escaping)
        unimplemented("mem-slots: a seed or computed rail stored into a slot object whose pointer escapes to a "
                      "call (its clean-up is the callee twin's: rule 18, 31, 106)",
                      &stI);
      if (isDynamic(ctx, st, *s.info, s.o)) {
        if (what == What::Computed)
          unimplemented("mem-slots: a computed rail stored into a slot cell that is read back at a run-time "
                        "cell (its clean-up needs a memory-aware uncompute or the loops module's reverse loop: "
                        "52, 67, 75)",
                        &stI);
        // The cells of a dynamic slot array are registers (58, 59: seeded |0>, kept).
        ctx.unc().setRole(id, Role::UserRegister);
        st.registers.insert(val.v);
      }
      break;
    case RootKind::Param:
      if (!ctx.S.isEntry())
        unimplemented("mem-slots: a store into a caller's slot cell from a clone (rule 18 copy-out and twin, 31)",
                      &stI);
      ctx.unc().setRole(id, Role::Output);
      st.registers.insert(val.v);
      break;
    case RootKind::Global:
      if (!cast<GlobalVariable>(s.info->root)->hasLocalLinkage()) {
        ctx.unc().setRole(id, Role::Output);   // an extern global is an output (71)
        st.registers.insert(val.v);
      }
      break;
    }
  }
  StoreInst *ns = B.CreateAlignedStore(val.v, cellPointer(ctx, s, stI), Align(4));
  (void)ns;
  st.lowered[&stI] = val;
}

void endSlotLifetime(LoweringContext &ctx, ObjectId, Instruction *at) {
  if (!at)
    return;
  if (auto *II = dyn_cast<IntrinsicInst>(at)) {
    if (II->getIntrinsicID() == Intrinsic::lifetime_end)
      return;   // the rewritten alloca carries no lifetime markers (they are hints)
    unimplemented("mem-slots: a lifetime end at an intrinsic other than lifetime.end (stackrestore, 192)", at);
  }
  auto *CB = dyn_cast<CallBase>(at);
  if (!CB)
    internalError("mem-slots: endSlotLifetime at a non-call", at);
  // A heap block's free stays the classical call clang wrote (75).
  CallBase *nc = cast<CallBase>(CB->clone());
  for (unsigned i = 0; i < CB->arg_size(); ++i) {
    Operand a = ctx.operand(CB->getArgOperand(i));
    if (a.handle)
      unimplemented("mem-slots: a free with a quantum operand", at);
    nc->setArgOperand(i, a.v);
  }
  ctx.B().Insert(nc);
  if (!CB->getType()->isVoidTy())
    ctx.bindFields(CB, {Operand{nc, false}});
}

} // namespace cq::mem
