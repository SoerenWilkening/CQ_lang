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
//    zext from i1 or the constant 0 / 1) holds an i1 rail.
//
//    Its i8 load is bound to that i1 rail when every use truncates it to i1; when no use does, to a
//    zext_i1_to_i8 of the rail (a fresh rail); both at once is unimplemented.
//
// Cell contents. A slot cell is homogeneous (rule 20): a classical store materialises its value as a
// seed rail alloc_<W>(v) (rule 7). A classical store into a cell that keeps its seed (dynamic,
// escaping, parameter or extern global object) whose cell the same block overwrites before any
// access of the object or call that may touch it is dead and emits nothing (115: store 0 then the
// cq_theta result). A store under a quantum predicate stores
// select(predicate, value, old) into a fresh rail (rules 9, 20).
//
// One rail per cell (cq-dr4o; CR rule 20 "the rail replaces the cell" read with C value semantics, CR
// §0 basis copies). A store of a handle that another holder may still expose after the store (the
// cell a slot load read it from, a cell an earlier store left it in, or an SSA value that may name it
// and is read after the store) stores a copy: c = alloc_<W>(0), copy_<W>(h, c), recorded like any core
// gate; in a dynamic object c is the cell's register (kept, like a seed), elsewhere it follows the
// computed-rail rules. Otherwise the store is a move (the handle, no gate): each other holder is
// overwritten (in the store's block before it, or on every path after it before any read) or dies.
// A later plain store of the same rail into a slot cell is decided when it is lowered.
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
#include "llvm/Analysis/CFG.h"
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

uint64_t storeBytes(const DataLayout &DL, Type *t) { return DL.getTypeStoreSize(t).getFixedValue(); }

// ---- per-object facts ---------------------------------------------------------------------------

enum class RootKind : uint8_t { Local, Heap, Param, Global };

enum class StoreWhat { Register, Seed, Computed, Copy };

struct ObjInfo {
  RootKind kind;
  const Value *root;
  uint64_t cellBytes = 0;
  bool boolCells = false;
  bool escaping = false;
  bool view = false;  // accessed at more than one width: a value object read and written through bit views (63)
  int dynamic = -1;   // -1 not computed
};

// What a store into a VIEW object left there (63): the value rail h of type ty covering the bytes
// [off, off + store size of ty); tailWritten when a narrower store also wrote bytes past that range
// (they are not in the rail).
struct ViewVal {
  Value *h = nullptr;
  Type *ty = nullptr;
  int64_t off = 0;
  bool tailWritten = false;
};

struct FnState {
  const Function *F = nullptr;
  std::unique_ptr<DominatorTree> DT;
  DenseMap<const Instruction *, Operand> lowered;   // slot load / store -> the handle the cell holds after it
  DenseSet<const Value *> registers;                // new-IR handles known never to be resolved here
  DenseSet<const Instruction *> copies;             // slot stores lowered as a basis copy (cq-dr4o)
  DenseMap<const Instruction *, ViewVal> views;     // stores into a view object -> the value they left (63)
  struct CellRead { const Instruction *I; Addr a; uint64_t size; };
  SmallVector<CellRead, 8> cellReads;               // accesses lowered as a run-time read of a local cell (M3)
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

// The plain loads and stores of the object in F, with their addresses; also its atomicrmw and cmpxchg
// accesses (rule 24: a read and a write of the cell, ty the value type, 94).
struct Access { const Instruction *I; Addr a; Type *ty; };

bool isRMW(const Instruction *I) { return isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I); }

const Value *accessPtr(const Instruction *I) {
  if (auto *r = dyn_cast<AtomicRMWInst>(I))
    return r->getPointerOperand();
  if (auto *c = dyn_cast<AtomicCmpXchgInst>(I))
    return c->getPointerOperand();
  return getLoadStorePointerOperand(I);
}

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
    } else if (auto *r = dyn_cast<AtomicRMWInst>(&I)) {
      if (hasObject(ctx, r->getPointerOperand(), o))
        out.push_back({r, decompose(r->getPointerOperand(), DL), r->getValOperand()->getType()});
    } else if (auto *c = dyn_cast<AtomicCmpXchgInst>(&I)) {
      if (hasObject(ctx, c->getPointerOperand(), o))
        out.push_back({c, decompose(c->getPointerOperand(), DL), c->getNewValOperand()->getType()});
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
      if (auto *r = dyn_cast<AtomicRMWInst>(usr)) {
        if (r->getPointerOperand() == v && r->getValOperand() != v)
          continue;   // rule 24: an access of the cell (94)
        return true;
      }
      if (auto *c = dyn_cast<AtomicCmpXchgInst>(usr)) {
        if (c->getPointerOperand() == v && c->getNewValOperand() != v && c->getCompareOperand() != v)
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
  if (info.kind == RootKind::Local)
    for (const Access &a : accessesOf(ctx, *st.F, o))
      if (DL.getTypeAllocSize(a.ty).getFixedValue() != info.cellBytes)
        info.view = true;
  if (info.cellBytes == 1 && !info.view) {
    bool any = false, all = true;
    for (const Access &a : accessesOf(ctx, *st.F, o)) {
      any = true;
      if (auto *ld = dyn_cast<LoadInst>(a.I))
        all &= boolRange(ld);
      else if (auto *sti = dyn_cast<StoreInst>(a.I))
        all &= boolValueStored(sti->getValueOperand());
      else
        all = false;
    }
    info.boolCells = any && all;
  }
  return st.objs.emplace(root, info).first->second;
}

// ---- may-write and forwarding -------------------------------------------------------------------

// A call may reach code that accesses an internal global whose address never escapes (67) only by
// calling, transitively, a function that accesses it. Calls of a declaration or an indirect call reach
// the module again only through a function whose address is taken (the module is the whole program).
// Computed once per (module, global): the functions from which an access may be reached.
bool callMayTouchInternalGlobal(const CallBase &CB, const GlobalVariable &gv) {
  static std::map<const GlobalVariable *, DenseSet<const Function *>> cache;
  auto it = cache.find(&gv);
  if (it == cache.end()) {
    DenseSet<const Function *> R;
    SmallVector<const Value *, 8> work{&gv};
    SmallPtrSet<const Value *, 16> seen{&gv};
    while (!work.empty()) {
      const Value *v = work.pop_back_val();
      for (const User *u : v->users()) {
        if (auto *I = dyn_cast<Instruction>(u))
          R.insert(I->getFunction());
        else if (seen.insert(u).second)
          work.push_back(u);   // a constant expression over the global
      }
    }
    const Module &M = *gv.getParent();
    bool changed = true;
    while (changed) {
      changed = false;
      bool reentry = false;
      for (const Function *f : R)
        reentry |= f->hasAddressTaken();
      for (const Function &F : M) {
        if (R.count(&F) || F.isDeclaration())
          continue;
        bool reaches = false;
        for (const Instruction &I : instructions(F))
          if (auto *C = dyn_cast<CallBase>(&I)) {
            const Function *g = C->getCalledFunction();
            if (isa<DbgInfoIntrinsic>(C) || (g && g->isIntrinsic()))
              continue;
            if (g ? (R.count(g) || (g->isDeclaration() && reentry)) : reentry)
              reaches = true;
          }
        if (reaches) {
          R.insert(&F);
          changed = true;
        }
      }
    }
    it = cache.emplace(&gv, std::move(R)).first;
  }
  const DenseSet<const Function *> &R = it->second;
  const Function *g = CB.getCalledFunction();
  bool reentry = false;
  for (const Function *f : R)
    reentry |= f->hasAddressTaken();
  if (!g)
    return reentry;
  if (g->isIntrinsic())
    return false;
  if (g->isDeclaration())
    return reentry;
  return R.count(g);
}

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
  if (info.kind == RootKind::Global && !info.escaping && cast<GlobalVariable>(info.root)->hasLocalLinkage())
    return callMayTouchInternalGlobal(*CB, *cast<GlobalVariable>(info.root));
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
    // A volatile or atomic access reaching mem-slots is the plain access (rule 24, cq-r4cz): eff-conc
    // routes only an unobservable volatile access here, and an atomic one is plain single-threaded.
    if (ctx.T.isFatPointer(accessPtr(a.I), ctx.S))
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
    if ((isa<LoadInst>(a.I) || isRMW(a.I)) && !sourceOf(ctx, st, info, o, a.I, a.a, a.ty))
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
  if (info.view) {
    if (info.escaping)
      unimplemented("mem-slots: a bit view of a slot object whose pointer escapes (63's construction needs every "
                    "access in this function)",
                    &I);
    if (!a.terms.empty())
      unimplemented("mem-slots: a bit view access of a slot object at a run-time offset", &I);
    return Site{objs.front(), &info, a};
  }
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

// The rails the lowered stores of this function may have left in the cell I reads at run time (M3): every
// store into the object whose cell may be I's and from which I is reachable, unless a store of exactly that
// cell later in the store's block overwrites it first. Returns false (and sets allRegisters) when there is
// none. A store that may reach I but is not lowered yet (a later store on a back edge), or a memory
// intrinsic writing the object, leaves rails this load cannot name: allowed only when every lowered arm is
// a register (the cells of 58/59/74: registers, kept), otherwise unimplemented.
bool cellArms(LoweringContext &ctx, FnState &st, const Site &s, const Instruction &I, Type *ty,
              SmallVectorImpl<RailId> &arms, bool &allRegisters) {
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t size = DL.getTypeStoreSize(ty).getFixedValue();
  bool unnamed = false;
  for (const Instruction &X : instructions(*st.F))
    if (auto *MI = dyn_cast<MemIntrinsic>(&X); MI && hasObject(ctx, MI->getDest(), s.o) &&
                                               isPotentiallyReachable(MI, &I, nullptr, st.DT.get()))
      unnamed = true;
  for (const Access &a : accessesOf(ctx, *st.F, s.o)) {
    if (isRMW(a.I) && a.I != &I && !differentCell(a.a, s.a, storeBytes(DL, a.ty), size) &&
        isPotentiallyReachable(a.I, &I, nullptr, st.DT.get()))
      unnamed = true;   // an atomic read-modify-write's new rail (94): not named here
    auto *S = dyn_cast<StoreInst>(a.I);
    if (!S || S == &I || differentCell(a.a, s.a, storeBytes(DL, a.ty), size))
      continue;
    if (!isPotentiallyReachable(S, &I, nullptr, st.DT.get()))
      continue;
    bool killed = false;
    for (auto it = std::next(S->getIterator()); it != S->getParent()->end() && !killed; ++it) {
      if (&*it == &I)
        break;
      if (auto *X = dyn_cast<StoreInst>(&*it))
        killed = hasObject(ctx, X->getPointerOperand(), s.o) && !X->isVolatile() && !X->isAtomic() &&
                 !ctx.T.isFatPointer(X->getPointerOperand(), ctx.S) &&
                 storeBytes(DL, X->getValueOperand()->getType()) == storeBytes(DL, a.ty) &&
                 sameCell(decompose(X->getPointerOperand(), DL), a.a);
    }
    if (killed)
      continue;
    auto it = st.lowered.find(S);
    if (it == st.lowered.end()) {
      unnamed = true;
      continue;
    }
    if (!st.registers.count(it->second.v))
      allRegisters = false;
    RailId r = ctx.unc().idOf(it->second.v);
    if (!is_contained(arms, r))
      arms.push_back(r);
  }
  if (unnamed && !allRegisters)
    unimplemented("mem-slots: a run-time read of a slot cell that may hold a computed rail and a rail this load "
                  "cannot name yet (a store on a back edge, or a memory intrinsic: 187)",
                  &I);
  return !arms.empty();
}

// CR rule 2 through memory (M3, 179): a rail stored into a cell is MEASURED when some load of the object
// that may read it measures its value (directly, or through a rule 3 view: trunc to i1 of a _Bool cell,
// freeze). A measured rail is kept (rule 5), so its operands are cleaned as soon as its own computation
// has read them; deciding it at the store, before the loop that reads it is lowered, is what lets a
// classically bounded loop clean them in their own trip (179's y[i] = icmp(...): "a user register, not
// garbage").
bool measuredThroughMemory(LoweringContext &ctx, FnState &st, const Instruction &S, Type *ty, const Site &s) {
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t sz = storeBytes(DL, ty);
  auto measures = [](const Value *v) {
    SmallVector<const Value *, 4> work{v};
    SmallPtrSet<const Value *, 8> seen{v};
    while (!work.empty()) {
      const Value *x = work.pop_back_val();
      for (const User *u : x->users()) {
        if (auto *c = dyn_cast<CallInst>(u); c && c->getCalledFunction() &&
                                             c->getCalledFunction()->getName().starts_with("cq_measure_"))
          return true;
        bool view = isa<FreezeInst>(u) || (isa<TruncInst>(u) && cast<TruncInst>(u)->getDestTy()->isIntegerTy(1));
        if (view && seen.insert(u).second)
          work.push_back(u);
      }
    }
    return false;
  };
  for (const Access &a : accessesOf(ctx, *st.F, s.o)) {
    auto *L = dyn_cast<LoadInst>(a.I);
    if (!L || differentCell(a.a, s.a, storeBytes(DL, a.ty), sz) || !isPotentiallyReachable(&S, L, nullptr, st.DT.get()))
      continue;
    if (measures(L))
      return true;
  }
  return false;
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
  if (s.info->kind == RootKind::Local || s.info->kind == RootKind::Heap) {
    // M3 (CR rules 5, 20): the handle names one of the rails the stores of this function may have left
    // in the cell. When one of them is not a register, the load is a merge over them (recordCellLoad):
    // its readers' clean-ups come before theirs, and a kept role on it keeps them.
    st.cellReads.push_back({&I, s.a, storeBytes(ctx.M.getDataLayout(), ty)});
    SmallVector<RailId, 4> arms;
    bool allRegisters = true;
    if (cellArms(ctx, st, s, I, ty, arms, allRegisters) && !allRegisters) {
      ctx.unc().recordCellLoad(h, arms);
      return Operand{h, true};
    }
  }
  ctx.unc().recordExternal(h, Role::UserRegister);
  st.registers.insert(h);
  return Operand{h, true};
}

// CR rules 7 and 20 (cq-c9il): a classical store whose cell is overwritten in the same block before any
// instruction may read, write or hand out the object stores a seed nothing can read: it is dead and
// emits nothing. -O1 writes `x[i] = 0; cq_theta(&x[i], t)` as store 0, then a store of the cq_theta
// result into the same cell (115, 178: the stored 0 is the cq_theta's classical operand, minted by
// the cq_theta itself). Materialising the seed into a cell that is read back at run-time cells would
// make it a register that the overwrite leaks.
bool deadClassicalStore(LoweringContext &ctx, FnState &st, const ObjInfo &info, ObjectId o, const StoreInst &S,
                        const Addr &cell) {
  if (S.isVolatile() || S.isAtomic())
    return false;
  for (auto it = std::next(S.getIterator()); it != S.getParent()->end(); ++it) {
    const Instruction &I = *it;
    if (auto *O = dyn_cast<StoreInst>(&I)) {
      if (!hasObject(ctx, O->getPointerOperand(), o))
        continue;
      return !O->isVolatile() && !O->isAtomic() && O->getValueOperand()->getType() == S.getValueOperand()->getType() &&
             !ctx.T.isFatPointer(O->getPointerOperand(), ctx.S) &&
             sameCell(decompose(O->getPointerOperand(), ctx.M.getDataLayout()), cell);
    }
    if (auto *ld = dyn_cast<LoadInst>(&I)) {
      if (hasObject(ctx, ld->getPointerOperand(), o))
        return false;
      continue;
    }
    if (isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I) || isa<VAArgInst>(I)) {
      if (hasObject(ctx, I.getOperand(0), o))
        return false;
      continue;
    }
    auto *CB = dyn_cast<CallBase>(&I);
    if (!CB || isa<DbgInfoIntrinsic>(CB) || isCqSurface(*CB))
      continue;
    for (const Use &u : CB->args())
      if (hasObject(ctx, u.get(), o))
        return false;   // a memory intrinsic, a lifetime marker or a call handed the object
    if (CB->mayReadOrWriteMemory() &&
        (info.escaping || info.kind == RootKind::Param || info.kind == RootKind::Global))
      return false;
  }
  return false;
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


// ---- one rail per cell (cq-dr4o) -----------------------------------------------------------------

// A slot cell (object, its facts, its address) that may hold the handle a store writes.
struct Holder { ObjectId o; ObjInfo *info; Addr a; uint64_t size; const Instruction *at; };

const Instruction *defOf(const Value *v) { return dyn_cast<Instruction>(v); }

// No path from S reads the cell before a store overwrites exactly that cell (or the object dies: a
// local or non-escaping heap object at the return). A path that redefines a value of the cell's
// address, or a call that may read the object, keeps it alive.
bool cellDeadAfter(LoweringContext &ctx, const Holder &h, const Instruction *S) {
  const DataLayout &DL = ctx.M.getDataLayout();
  SmallPtrSet<const Instruction *, 4> defs;
  if (auto *I = defOf(h.a.root))
    defs.insert(I);
  for (auto &t : h.a.terms)
    if (auto *I = defOf(t.first))
      defs.insert(I);
  bool localDeath = h.info->kind == RootKind::Local || (h.info->kind == RootKind::Heap && !h.info->escaping);
  // 1 dead on this path, 0 alive, -1 keep walking.
  auto step = [&](const Instruction &I) -> int {
    if (&I == S)
      return -1;
    if (defs.count(&I))
      return 0;
    if (auto *st = dyn_cast<StoreInst>(&I)) {
      if (!hasObject(ctx, st->getPointerOperand(), h.o))
        return -1;
      if (!st->isVolatile() && !st->isAtomic() && !ctx.T.isFatPointer(st->getPointerOperand(), ctx.S) &&
          DL.getTypeStoreSize(st->getValueOperand()->getType()).getFixedValue() == h.size &&
          sameCell(decompose(st->getPointerOperand(), DL), h.a))
        return 1;
      return -1;
    }
    if (auto *ld = dyn_cast<LoadInst>(&I)) {
      if (!hasObject(ctx, ld->getPointerOperand(), h.o))
        return -1;
      Addr a = decompose(ld->getPointerOperand(), DL);
      return differentCell(a, h.a, DL.getTypeStoreSize(ld->getType()).getFixedValue(), h.size) ? -1 : 0;
    }
    if (isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I) || isa<VAArgInst>(I))
      return hasObject(ctx, I.getOperand(0), h.o) ? 0 : -1;
    if (isa<ReturnInst>(I) || isa<ResumeInst>(I))
      return localDeath ? 1 : 0;
    if (isa<UnreachableInst>(I))
      return 1;
    auto *CB = dyn_cast<CallBase>(&I);
    if (!CB || isa<DbgInfoIntrinsic>(CB) || isCqSurface(*CB))
      return -1;
    if (auto *II = dyn_cast<IntrinsicInst>(CB))
      if (II->getIntrinsicID() == Intrinsic::lifetime_end && hasObject(ctx, II->getArgOperand(1), h.o))
        return 1;
    if (isFree(*CB) && CB->arg_size() && hasObject(ctx, CB->getArgOperand(0), h.o))
      return 1;
    for (const Use &u : CB->args())
      if (hasObject(ctx, u.get(), h.o))
        return 0;
    if (CB->mayReadOrWriteMemory() && (h.info->escaping || h.info->kind == RootKind::Param ||
                                       h.info->kind == RootKind::Global))
      return 0;
    return -1;
  };
  auto walk = [&](BasicBlock::const_iterator from, BasicBlock::const_iterator to) -> int {
    for (auto it = from; it != to; ++it)
      if (int r = step(*it); r >= 0)
        return r;
    return -1;
  };
  const BasicBlock *SB = S->getParent();
  int r = walk(std::next(S->getIterator()), SB->end());
  if (r == 0)
    return false;
  if (r == 1)
    return true;
  SmallPtrSet<const BasicBlock *, 16> seen;
  SmallVector<const BasicBlock *, 16> work(succ_begin(SB), succ_end(SB));
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    if (!seen.insert(b).second)
      continue;
    int x = walk(b->begin(), b->end());
    if (x == 0)
      return false;
    if (x == 1)
      continue;
    for (const BasicBlock *s : successors(b))
      work.push_back(s);
  }
  return true;
}

// CR rule 20 slot store, C value semantics (cq-dr4o): the rail replaces the cell, and C copies the
// value. When the handle S stores may still be read after S through another holder (a cell other
// than S's, or an SSA value naming the rail), the two C objects would share one rail and an in-place
// gate on one (rule 2) would change the other: S then stores a basis copy (CR §0). It is a move (the
// handle itself, no gate) when no other holder can be read after S.
bool needsCopy(LoweringContext &ctx, FnState &st, const StoreInst &S, const Site &dest) {
  const DataLayout &DL = ctx.M.getDataLayout();
  const Value *v = S.getValueOperand();
  SmallPtrSet<const Value *, 8> names;
  SmallVector<Holder, 4> holders;
  auto slotSite = [&](const Instruction &I, const Value *ptr, Type *ty, std::optional<Holder> &out) {
    ArrayRef<ObjectId> objs = ctx.T.provenance(ptr, ctx.S);
    if (objs.size() != 1 || ctx.T.classOf(objs.front()) != ObjClass::Slot || ctx.T.isFatPointer(ptr, ctx.S))
      return;
    Addr a = decompose(ptr, DL);
    if (!a.ok)
      return;
    ObjInfo &info = objInfo(ctx, st, a.root, objs.front());
    out = Holder{objs.front(), &info, a, DL.getTypeStoreSize(ty).getFixedValue(), &I};
  };
  // Rule 2 and rule 3 views of a value are the same rail: cq_theta (in place), freeze, bitcast.
  auto sameRail = [](const User *u, const Value *x) {
    if (isa<FreezeInst>(u) || isa<BitCastInst>(u))
      return true;
    auto *c = dyn_cast<CallInst>(u);
    return c && c->getCalledFunction() && c->getCalledFunction()->getName().starts_with("cq_theta_") &&
           c->arg_size() && c->getArgOperand(0) == x;
  };
  auto close = [&](SmallPtrSet<const Value *, 8> &set) {
    SmallVector<const Value *, 8> work(set.begin(), set.end());
    while (!work.empty()) {
      const Value *x = work.pop_back_val();
      for (const User *u : x->users())
        if (sameRail(u, x) && set.insert(u).second)
          work.push_back(u);
    }
  };
  // The rail's origin and the values naming it by construction.
  const Value *origin = v;
  for (unsigned guard = 0; guard < 64; ++guard) {
    const auto *U = dyn_cast<User>(origin);
    if (!U || !U->getNumOperands())
      break;
    const Value *x = U->getOperand(0);
    if (!sameRail(U, x))
      break;
    origin = x;
  }
  SmallPtrSet<const Value *, 8> own{origin};
  close(own);
  names.insert(own.begin(), own.end());
  // Under one rail per cell, the cell a slot load read is the rail's only cell; every handle an access
  // lowered before S may have left in (or read from) that cell may be the same rail.
  if (auto *L = dyn_cast<LoadInst>(origin)) {
    std::optional<Holder> h;
    slotSite(*L, L->getPointerOperand(), L->getType(), h);
    if (h) {
      for (const Access &x : accessesOf(ctx, *st.F, h->o)) {
        uint64_t sz = DL.getTypeStoreSize(x.ty).getFixedValue();
        if (!st.lowered.count(x.I) || differentCell(x.a, h->a, sz, h->size))
          continue;
        if (auto *xs = dyn_cast<StoreInst>(x.I)) {
          // A store lowered as a copy left its own rail in the cell, not its value's (cq-7hpb).
          if (!st.copies.count(xs))
            names.insert(xs->getValueOperand());
        }
        else
          names.insert(x.I);
      }
      close(names);
      if (!(h->o == dest.o && sameCell(h->a, dest.a)))
        holders.push_back(*h);
    }
  }
  // Cells an earlier store left the rail in.
  for (const Value *n : own)
    for (const User *u : n->users()) {
      auto *X = dyn_cast<StoreInst>(u);
      if (!X || X == &S || X->getValueOperand() != n || !st.lowered.count(X) || st.copies.count(X))
        continue;
      std::optional<Holder> h;
      slotSite(*X, X->getPointerOperand(), n->getType(), h);
      if (h && !(h->o == dest.o && sameCell(h->a, dest.a)))
        holders.push_back(*h);
    }
  // A name read after S, with or without another memory holder (cq-7hpb: b[j] = x; ... x). A later plain store of a name into a slot cell is not a read: that store is
  // decided the same way when it is lowered, with S's cell among its holders.
  auto slotStoreOf = [&](const Instruction *U, const Value *n) {
    auto *X = dyn_cast<StoreInst>(U);
    if (!X || X->getValueOperand() != n || X->isVolatile() || X->isAtomic())
      return false;
    std::optional<Holder> h;
    slotSite(*X, X->getPointerOperand(), n->getType(), h);
    return h.has_value();
  };
  const BasicBlock *SB = S.getParent();
  SmallPtrSet<const BasicBlock *, 16> reach;
  SmallVector<const BasicBlock *, 16> bw(succ_begin(SB), succ_end(SB));
  while (!bw.empty()) {
    const BasicBlock *b = bw.pop_back_val();
    if (reach.insert(b).second)
      for (const BasicBlock *s : successors(b))
        bw.push_back(s);
  }
  for (const Value *n : names)
    for (const User *u : n->users()) {
      auto *U = dyn_cast<Instruction>(u);
      if (!U || U == &S || slotStoreOf(U, n))
        continue;
      const BasicBlock *ub = U->getParent();
      if (auto *phi = dyn_cast<PHINode>(U)) {
        for (unsigned i = 0; i < phi->getNumIncomingValues(); ++i)
          if (phi->getIncomingValue(i) == n &&
              (phi->getIncomingBlock(i) == SB || reach.count(phi->getIncomingBlock(i))))
            return true;
        continue;
      }
      if (reach.count(ub) || (ub == SB && S.comesBefore(U)))
        return true;
    }
  if (holders.empty())
    return false;
  // An overwrite of a holder with a value that may be the rail puts it back, unless that value is a
  // load of S's own cell: it is the rail only when its cell held it, i.e. when S's cell is the holder.
  auto rePuts = [&](const Value *o) {
    if (!names.count(o) || own.count(o))
      return names.count(o) > 0;
    auto *ol = dyn_cast<LoadInst>(o);
    return !(ol && hasObject(ctx, ol->getPointerOperand(), dest.o) &&
             sameCell(decompose(ol->getPointerOperand(), DL), dest.a));
  };
  // A holder overwritten in S's block before S (after the access that left the rail there) no longer
  // holds it (the second store of a swap); every other holder must be dead after S.
  for (const Holder &h : holders) {
    bool gone = false;
    for (auto it = S.getIterator(); it != SB->begin();) {
      --it;
      if (&*it == h.at)
        break;
      auto *o = dyn_cast<StoreInst>(&*it);
      if (o && !rePuts(o->getValueOperand()) && hasObject(ctx, o->getPointerOperand(), h.o) &&
          !o->isVolatile() && !o->isAtomic() && !ctx.T.isFatPointer(o->getPointerOperand(), ctx.S) &&
          DL.getTypeStoreSize(o->getValueOperand()->getType()).getFixedValue() == h.size &&
          sameCell(decompose(o->getPointerOperand(), DL), h.a)) {
        gone = true;
        break;
      }
    }
    if (!gone && !cellDeadAfter(ctx, h, &S))
      return true;
  }
  return false;
}

// ---- bit views of a value object (63) ---------------------------------------------------------
//
// A non-escaping local object accessed at more than one width (a union, an f80 next to i32 words) is a
// VALUE, not memory (CR rule 20, 63): every load is computed from the rails that the stores of this
// function left in it, through rule 3/4 views, and no handle is stored into the cells. Each store leaves
// a value rail covering its bytes (ViewVal):
//  - a store whose bytes cover the bytes of the value it overwrites (or that overlaps no value) leaves
//    the stored rail (a classical value: its seed, rule 7; a handle another holder may still read: a
//    basis copy, cq-dr4o);
//  - a narrower store at byte offset r of a value V of N bits leaves the new value
//    (V & ~mask) | (zext(word) << 8r), mask the word's bits within N (the word's bits past N fall off and
//    the value records that bytes past it were written), bitcast back when V is floating point;
//  - a load at byte offset r of V reads lshr(V, 8r), truncated to its width, or, when it reaches past
//    V's bits, truncated to the bits V has and zero-extended (bytes past a stored value are padding the
//    program never wrote: LLVM reads them as undef, 0 is one of its values). A load reaching bytes a
//    narrower store wrote past V is unimplemented, as is a load or store starting before the value it
//    reads, a load no dominating store reaches unchanged, a run-time offset, and a store under a
//    quantum predicate.

// The latest store into the view object whose bytes overlap [at.off, at.off + n) and reach I unchanged.
const StoreInst *viewSource(LoweringContext &ctx, FnState &st, const ObjInfo &info, ObjectId o, const Instruction *I,
                            const Addr &at, uint64_t n) {
  const DataLayout &DL = ctx.M.getDataLayout();
  const StoreInst *best = nullptr;
  for (const Access &a : accessesOf(ctx, *st.F, o)) {
    auto *S = dyn_cast<StoreInst>(a.I);
    if (!S || S == I)
      continue;
    if (!a.a.ok || !a.a.terms.empty() || a.a.root != at.root || ctx.T.isFatPointer(S->getPointerOperand(), ctx.S))
      unimplemented("mem-slots: a store into a bit-view slot object at a run-time offset or through a fat pointer",
                    S);
    int64_t m = int64_t(storeBytes(DL, a.ty));
    if (!(a.a.off < at.off + int64_t(n) && at.off < a.a.off + m))
      continue;
    if (!st.DT->dominates(S, I) || !clearBetween(ctx, info, o, S, I, at, n))
      continue;
    if (!best || st.DT->dominates(best, S))
      best = S;
  }
  return best;
}

Value *viewTemplate(LoweringContext &ctx, StringRef op, RailType w, std::optional<RailType> to, ArrayRef<Operand> ops,
                    StringRef shape = "") {
  abi::TemplateSpec sp;
  sp.op = op.str();
  sp.w = w;
  sp.to = to;
  sp.shape = shape.str();
  return ctx.emitTemplate(sp, ops);
}

unsigned bitsOf(const DataLayout &DL, Type *t) { return unsigned(DL.getTypeSizeInBits(t).getFixedValue()); }

// The rail of v (type t) as an integer of t's bits.
Value *intView(LoweringContext &ctx, Value *h, Type *t) {
  if (t->isIntegerTy())
    return h;
  unsigned n = bitsOf(ctx.M.getDataLayout(), t);
  return viewTemplate(ctx, "bitcast", railTypeOf(t), RailType{Kind::Int, n}, {Operand{h, true}});
}

Operand lit(LoweringContext &ctx, unsigned bits, const APInt &v) {
  return Operand{ConstantInt::get(IntegerType::get(ctx.M.getContext(), bits), v), false};
}

Value *readView(LoweringContext &ctx, FnState &st, const Site &s, const Instruction &I, Type *ty) {
  const DataLayout &DL = ctx.M.getDataLayout();
  if (!ty->isIntegerTy() && !ty->isFloatingPointTy())
    unimplemented("mem-slots: a bit view load of a non-scalar type", &I);
  const StoreInst *src = viewSource(ctx, st, *s.info, s.o, &I, s.a, storeBytes(DL, ty));
  if (!src)
    unimplemented("mem-slots: a load of a bit-view slot object that no dominating store of this function reaches "
                  "unchanged (63)",
                  &I);
  auto it = st.views.find(src);
  if (it == st.views.end())
    internalError("mem-slots: the store a bit view reads has not been lowered", &I);
  const ViewVal V = it->second;
  int64_t rel = s.a.off - V.off;
  if (rel < 0)
    unimplemented("mem-slots: a bit view load starting before the value it reads", &I);
  if (rel == 0 && ty == V.ty)
    return V.h;
  unsigned N = bitsOf(DL, V.ty), M = bitsOf(DL, ty);
  if (8 * rel >= int64_t(N))
    unimplemented("mem-slots: a bit view load of padding bytes only (past the stored value)", &I);
  unsigned avail = N - unsigned(8 * rel);
  if (M > avail && V.tailWritten)
    unimplemented("mem-slots: a bit view load of bytes a narrower store wrote past the value it wrote into", &I);
  RailType iN{Kind::Int, N};
  Value *x = intView(ctx, V.h, V.ty);
  if (rel)
    x = viewTemplate(ctx, "lshr", iN, std::nullopt, {Operand{x, true}, lit(ctx, N, APInt(N, uint64_t(8 * rel)))},
                     "hl");
  unsigned keep = std::min(M, avail);
  if (keep < N)
    x = viewTemplate(ctx, "trunc", iN, RailType{Kind::Int, keep}, {Operand{x, true}});
  if (keep < M)
    x = viewTemplate(ctx, "zext", RailType{Kind::Int, keep}, RailType{Kind::Int, M}, {Operand{x, true}});
  if (!ty->isIntegerTy())
    x = viewTemplate(ctx, "bitcast", RailType{Kind::Int, M}, railTypeOf(ty), {Operand{x, true}});
  return x;
}

void lowerViewStore(LoweringContext &ctx, FnState &st, StoreInst &stI, const Site &s) {
  const DataLayout &DL = ctx.M.getDataLayout();
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  if (ctx.currentFlag())
    unimplemented("mem-slots: a store into a bit-view slot object under a quantum predicate", &stI);
  Value *v = stI.getValueOperand();
  Type *ty = v->getType();
  if (!ty->isIntegerTy() && !ty->isFloatingPointTy())
    unimplemented("mem-slots: a bit view store of a non-scalar type", &stI);
  uint64_t n = storeBytes(DL, ty);
  Operand val = ctx.operand(v);
  const StoreInst *src = viewSource(ctx, st, *s.info, s.o, &stI, s.a, n);
  ViewVal V;
  if (src) {
    auto it = st.views.find(src);
    if (it == st.views.end())
      internalError("mem-slots: the store a bit view store writes into has not been lowered", &stI);
    V = it->second;
  }
  if (!src || (s.a.off <= V.off && s.a.off + int64_t(n) >= V.off + int64_t(storeBytes(DL, V.ty)))) {
    // The stored value is the object's value over its bytes.
    Value *h = val.v;
    RailType w = railTypeOf(ty);
    if (!val.handle) {
      CallInst *alloc = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {val.v});
      ctx.unc().recordSeed(alloc);
      h = alloc;
    } else if (needsCopy(ctx, st, stI, s)) {
      CallInst *c = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(C, w))});
      RailId cid = ctx.unc().recordSeed(c);
      abi::CoreSpec cp{abi::Core::Copy, w};
      CallInst *cc = ctx.emitCore(cp, {val.v, c});
      ctx.unc().recordCore(cc, cp, {Operand{val.v, true}, Operand{c, true}}, cid);
      st.copies.insert(&stI);
      h = c;
    }
    st.views[&stI] = ViewVal{h, ty, s.a.off, src && V.tailWritten};
    st.lowered[&stI] = Operand{h, true};
    return;
  }
  int64_t rel = s.a.off - V.off;
  unsigned N = bitsOf(DL, V.ty), S = bitsOf(DL, ty);
  if (rel < 0 || 8 * rel >= int64_t(N))
    unimplemented("mem-slots: a bit view store starting before the value it writes into", &stI);
  unsigned r = unsigned(8 * rel), k = std::min(S, N - r);
  RailType iN{Kind::Int, N};
  Value *vi = intView(ctx, V.h, V.ty);
  Value *low = viewTemplate(ctx, "and", iN, std::nullopt, {Operand{vi, true}, lit(ctx, N, ~APInt::getBitsSet(N, r, r + k))},
                            "hl");
  Value *res;
  if (val.handle) {
    Value *w = val.v;
    if (!ty->isIntegerTy())
      w = viewTemplate(ctx, "bitcast", railTypeOf(ty), RailType{Kind::Int, S}, {Operand{w, true}});
    if (S < N)
      w = viewTemplate(ctx, "zext", RailType{Kind::Int, S}, iN, {Operand{w, true}});
    else if (S > N)
      w = viewTemplate(ctx, "trunc", RailType{Kind::Int, S}, iN, {Operand{w, true}});
    if (r)
      w = viewTemplate(ctx, "shl", iN, std::nullopt, {Operand{w, true}, lit(ctx, N, APInt(N, r))}, "hl");
    res = viewTemplate(ctx, "or", iN, std::nullopt, {Operand{low, true}, Operand{w, true}});
  } else {
    Value *w = val.v;
    if (!ty->isIntegerTy())
      w = B.CreateBitCast(w, IntegerType::get(C, S));
    w = B.CreateZExtOrTrunc(w, IntegerType::get(C, N));
    if (r)
      w = B.CreateShl(w, ConstantInt::get(w->getType(), r));
    res = viewTemplate(ctx, "or", iN, std::nullopt, {Operand{low, true}, Operand{w, false}}, "hl");
  }
  if (!V.ty->isIntegerTy())
    res = viewTemplate(ctx, "bitcast", iN, railTypeOf(V.ty), {Operand{res, true}});
  st.views[&stI] = ViewVal{res, V.ty, V.off, V.tailWritten || r + S > N};
  st.lowered[&stI] = Operand{res, true};
}

// The role of a rail stored into a slot cell (rule 20), the handle store and the cell's new content.
void finishStore(LoweringContext &ctx, FnState &st, const Site &s, Instruction &I, Type *ty, Operand val,
                 StoreWhat what) {
  using What = StoreWhat;
  IRBuilder<> &B = ctx.B();
  if (what != What::Register) {
    RailId id = ctx.unc().idOf(val.v);
    switch (s.info->kind) {
    case RootKind::Local:
    case RootKind::Heap:
      if (s.info->escaping)
        unimplemented("mem-slots: a seed or computed rail stored into a slot object whose pointer escapes to a "
                      "call (its clean-up is the callee twin's: rule 18, 31, 106)",
                      &I);
      if (isDynamic(ctx, st, *s.info, s.o)) {
        // A copy into a dynamic cell is that cell's register, like its seed (58, 59; cq-dr4o).
        if (what == What::Computed) {
          // M3: a computed rail stays garbage; each run-time read of the cell after it names it
          // (recordCellLoad), so its clean-up follows them. A read lowered before this store that this
          // store may reach (a back edge) named the cell's rails without it.
          const DataLayout &DL = ctx.M.getDataLayout();
          uint64_t sz = storeBytes(DL, ty);
          for (const FnState::CellRead &R : st.cellReads) {
            if (R.a.root == s.a.root && !differentCell(R.a, s.a, R.size, sz) &&
                isPotentiallyReachable(&I, R.I, nullptr, st.DT.get()))
              unimplemented("mem-slots: a computed rail stored into a slot cell that an earlier-lowered run-time "
                            "read may see on a back edge (the cell's rail is loop-carried through memory: 187)",
                            &I);
          }
          if (measuredThroughMemory(ctx, st, I, ty, s)) {
            ctx.unc().setRole(id, Role::Measured);
            st.registers.insert(val.v);
          }
          break;
        }
        // The cells of a dynamic slot array are registers (58, 59: seeded |0>, kept).
        ctx.unc().setRole(id, Role::UserRegister);
        st.registers.insert(val.v);
      }
      break;
    case RootKind::Param:
      if (!ctx.S.isEntry())
        unimplemented("mem-slots: a store into a caller's slot cell from a clone (rule 18 copy-out and twin, 31)",
                      &I);
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
  StoreInst *ns = B.CreateAlignedStore(val.v, cellPointer(ctx, s, I), Align(4));
  (void)ns;
  st.lowered[&I] = val;
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
  if (s.info->view) {
    Value *h = readView(ctx, st, s, ld, ld.getType());
    st.lowered[&ld] = Operand{h, true};
    ctx.bindFields(&ld, {Operand{h, true}});
    return;
  }
  cellRail(*s.info, ld.getType(), ld);
  Operand h = readCell(ctx, st, s, ld, ld.getType());
  st.lowered[&ld] = h;
  if (s.info->boolCells) {
    // A _Bool cell holds an i1 rail behind i8 memory. The trunc i8 -> i1 of the load names that rail
    // (spine, cq-sj2j: rule 3, no gate); any other use reads the i8 value, which is the rail widened
    // (cq-c9il): a zext_i1_to_i8 into a fresh rail, so every reader gets a rail of its operand's width.
    bool narrow = false, wide = false;
    for (const Use &u : ld.uses()) {
      auto *t = dyn_cast<TruncInst>(u.getUser());
      if (t && t->getDestTy()->isIntegerTy(1))
        narrow = true;
      else
        wide = true;
    }
    if (narrow && wide)
      unimplemented("mem-slots: a _Bool cell load read both as its i1 rail (trunc) and at i8 (the trunc names "
                    "the rail, the i8 reader needs a widened copy: rule 3 views, cq-c9il)",
                    &ld);
    if (wide) {
      abi::TemplateSpec spec;
      spec.op = "zext";
      spec.w = RailType{Kind::Int, 1};
      spec.to = RailType{Kind::Int, 8};
      ctx.emitTemplate(spec, {h}, &ld);
      return;
    }
  }
  ctx.bindFields(&ld, {h});
}

void lowerSlotStore(LoweringContext &ctx, StoreInst &stI) {
  FnState &st = stateOf(ctx, stI);
  const Value *v = stI.getValueOperand();
  Site s = siteOf(ctx, st, stI, stI.getPointerOperand(), v->getType());
  if (s.info->view)
    return lowerViewStore(ctx, st, stI, s);
  RailType w = cellRail(*s.info, v->getType(), stI);
  IRBuilder<> &B = ctx.B();

  using What = StoreWhat;
  What what;
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
    if (val.handle && old.handle && val.v == old.v) {
      // The cell already holds the stored rail (a cq_theta in place under the predicate, rule 10, of the
      // rail the cell holds: 59's `if (q[i]) cq_theta(&q[i + 1], c)`): select(p, h, h) is h, the cell
      // and the rail's role are unchanged and nothing is emitted.
      st.lowered[&stI] = val;
      return;
    }
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
    // A seed that a cell keeps (a dynamic, escaping, parameter or extern global object) but that is
    // overwritten before anything can read it is never materialised (rules 7, 20; cq-c9il).
    bool staticCell = (s.info->kind == RootKind::Local || s.info->kind == RootKind::Heap) && !s.info->escaping &&
                      !isDynamic(ctx, st, *s.info, s.o);
    bool localGlobal =
        s.info->kind == RootKind::Global && cast<GlobalVariable>(s.info->root)->hasLocalLinkage();
    if (!staticCell && !localGlobal && deadClassicalStore(ctx, st, *s.info, s.o, stI, s.a))
      return;
    Value *x = val.v;
    if (s.info->boolCells)
      x = B.CreateTrunc(x, Type::getInt1Ty(ctx.M.getContext()));
    if (x->getType() != irTypeOf(ctx.M.getContext(), w))
      internalError("mem-slots: a classical stored value of another type than its cell's rail", &stI);
    CallInst *alloc = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {x});
    ctx.unc().recordSeed(alloc);
    val = Operand{alloc, true};
    what = What::Seed;
  } else if (needsCopy(ctx, st, stI, s)) {
    // C copies the value (cq-dr4o): the cell gets its own rail, a basis copy of the stored one (CR §0).
    Value *h = val.v;
    CallInst *c = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                               {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
    RailId cid = ctx.unc().recordSeed(c);
    abi::CoreSpec cp{abi::Core::Copy, w};
    CallInst *cc = ctx.emitCore(cp, {h, c});
    ctx.unc().recordCore(cc, cp, {Operand{h, true}, Operand{c, true}}, cid);
    val = Operand{c, true};
    what = What::Copy;
    st.copies.insert(&stI);
  } else {
    what = st.registers.count(val.v) || isThetaResult(v) ? What::Register : What::Computed;
    if (what == What::Register)
      st.registers.insert(val.v);   // a cq_theta result is a user register (rule 2)
  }

  finishStore(ctx, st, s, stI, v->getType(), val, what);
}

// Rule 24 (94): the single-thread meaning of an atomic read-modify-write of a slot cell.
void lowerSlotAtomic(LoweringContext &ctx, Instruction &I) {
  FnState &st = stateOf(ctx, I);
  auto *rmw = dyn_cast<AtomicRMWInst>(&I);
  auto *cx = dyn_cast<AtomicCmpXchgInst>(&I);
  if (!rmw && !cx)
    internalError("mem-slots: lowerSlotAtomic of an instruction that is neither atomicrmw nor cmpxchg", &I);
  if ((rmw && rmw->isVolatile()) || (cx && cx->isVolatile()))
    unimplemented("mem-slots: a volatile atomic read-modify-write of a slot cell", &I);
  const Value *ptr = accessPtr(&I);
  if (ctx.T.isFatPointer(ptr, ctx.S))
    unimplemented("mem-slots: an atomic read-modify-write through a fat pointer (rule 21)", &I);
  Type *ty = rmw ? rmw->getValOperand()->getType() : cx->getNewValOperand()->getType();
  Site s = siteOf(ctx, st, I, ptr, ty);
  if (s.info->view || s.info->boolCells)
    unimplemented("mem-slots: an atomic read-modify-write of a bit-view or _Bool slot cell", &I);
  if (ctx.currentFlag())
    unimplemented("mem-slots: an atomic read-modify-write of a slot cell under a quantum predicate", &I);
  if (!ty->isIntegerTy())
    unimplemented("mem-slots: an atomic read-modify-write of a non-integer slot cell", &I);
  RailType w = cellRail(*s.info, ty, I);
  Operand old = readCell(ctx, st, s, I, ty);
  if (!old.handle)
    internalError("mem-slots: a slot cell read as a classical value", &I);
  auto shape2 = [](const Operand &a, const Operand &b) {
    return a.handle && b.handle ? "" : a.handle ? "hl" : "lh";
  };
  Operand nv;
  if (rmw) {
    Operand v = ctx.operand(rmw->getValOperand());
    const char *op = nullptr;
    switch (rmw->getOperation()) {
    case AtomicRMWInst::Add: op = "add"; break;
    case AtomicRMWInst::Sub: op = "sub"; break;
    case AtomicRMWInst::And: op = "and"; break;
    case AtomicRMWInst::Or: op = "or"; break;
    case AtomicRMWInst::Xor: op = "xor"; break;
    default:
      unimplemented("mem-slots: an atomicrmw operation other than add, sub, and, or, xor on a slot cell", &I);
    }
    abi::TemplateSpec sp;
    sp.op = op;
    sp.w = w;
    sp.shape = shape2(old, v);
    nv = Operand{ctx.emitTemplate(sp, {old, v}), true};
    ctx.bindFields(&I, {old});
  } else {
    Operand cmp = ctx.operand(cx->getCompareOperand());
    Operand v = ctx.operand(cx->getNewValOperand());
    abi::TemplateSpec eq;
    eq.op = "icmp";
    eq.pred = "eq";
    eq.w = w;
    eq.shape = shape2(old, cmp);
    Value *f = ctx.emitTemplate(eq, {old, cmp});
    abi::TemplateSpec sel;
    sel.op = "select";
    sel.w = w;
    sel.shape = v.handle ? "" : "lh";
    nv = Operand{ctx.emitTemplate(sel, {Operand{f, true}, v, old}), true};
    ctx.bindFields(&I, {old, Operand{f, true}});
  }
  finishStore(ctx, st, s, I, ty, nv, StoreWhat::Computed);
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
