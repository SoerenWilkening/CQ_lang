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
//  - A global QRAM (any linkage, 160, 192) is allocated once by a module constructor
//    __cq_qram_init_<global> (llvm.global_ctors, priority 65535): cqrt_qram_alloc_host_<W>(ptr @g, i64 n),
//    the cells seeded from the global's own storage at program start (n = 0: unknown extent), the handle
//    stored in the compiler-made @<global>.qram (the global keeps its definition; the compiler never reads
//    an initializer; CR rule 20, cq-pf4n). Each output function that accesses it
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
// The object predicates (escaping, dynamic) are mem-slots' and private to Slots.cpp; they are restated
// below verbatim (the "addresses" to "isDynamic" sections) so that both modules classify an object the same
// way. The cells themselves (size, type, _Bool cells, record, view) are never restated: mem::slotLayout is
// mem-slots' objInfo (cq-dd3q).
#include "cq/Effects.h"
#include "cq/Memory.h"
#include "QramInternal.h"
#include "../../loops/cutoff/Exits.h"
#include "cq/Loops.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/TargetParser/Triple.h"
#include "../slots/SlotsInternal.h"
#include "../../fatptr/FatPtrInternal.h"

#include <functional>
#include <map>
#include <numeric>
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

void lowerSlotIntrinsicM6(LoweringContext &ctx, MemIntrinsic &MI, ObjectId o);

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

// With ctx (an access being lowered): a K-loop's walked pointer (cq-9w75, CR rule 14: start + j*step in trip j, the
// phi bound to the trip's constant j) is its start moved by j*step bytes, a classical offset (cq-h8y6).
Addr decompose(const Value *p, const DataLayout &DL, LoweringContext *ctx = nullptr) {
  Addr a;
  for (unsigned guard = 0; guard < 64; ++guard) {
    if (const WalkedPtr *w = ctx ? ctx->walkedPointer(p) : nullptr) {
      SmallVector<Operand, 4> fl = ctx->fields(p);
      auto *j = fl.size() == 1 && !fl.front().handle ? dyn_cast<ConstantInt>(fl.front().v) : nullptr;
      if (!j)
        return a;
      a.off += j->getSExtValue() * w->step;
      p = w->start;
      continue;
    }
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
    if (auto *II = dyn_cast<IntrinsicInst>(p); II && II->getIntrinsicID() == Intrinsic::threadlocal_address) {
      p = II->getArgOperand(0);   // the address of the one thread's instance (rule 24)
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
  Type *cellTy = nullptr;   // mem-slots' cell type (slotLayout); null for a record
  bool record = false;      // mem-slots' slot record: one cell per field of its own type (cellBytes 0)
  bool view = false;        // mem-slots' bit-view object (63)
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

// cq-dd3q (CR rules 20, 22): an object's cells are mem-slots' (slotLayout: its objInfo), never restated here: a
// local struct or union read across its fields is byte cells (63), a local of pointers a record of its pointer
// cells (rule 21), a punned local the narrow cells of 90; mem-qram's rule-22 writes go cell by cell over them.
ObjInfo &objInfo(LoweringContext &ctx, FnState &st, const Value *root, ObjectId o, const Instruction &at) {
  auto it = st.objs.find(root);
  if (it != st.objs.end())
    return it->second;
  ObjInfo info;
  info.root = root;
  if (isa<AllocaInst>(root))
    info.kind = RootKind::Local;
  else if (isa<GlobalVariable>(root))
    info.kind = RootKind::Global;
  else
    info.kind = isa<Argument>(root) ? RootKind::Param : RootKind::Heap;
  SlotLayout L = slotLayout(ctx, root, o, at);
  info.record = L.record;
  info.view = L.view;
  info.cellBytes = L.cellBytes;
  info.cellTy = L.record ? nullptr : L.cellTy;
  info.boolCells = L.boolCells;
  info.escaping = escapes(root);
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

// The scalar type of a cell (mem-slots' cell, slotLayout; a parameter or heap block: the type its accesses in
// this function use, which mem-slots has checked to be one width, else mem-slots' own: the type the functions it
// is handed to access it as, or bytes). Null for a record.
Type *cellType(LoweringContext &ctx, FnState &st, const ObjInfo &info, ObjectId o) {
  if (info.kind == RootKind::Local || info.kind == RootKind::Global || info.record)
    return info.cellTy;   // rules 20, 22, cq-366o
  Type *t = nullptr;
  for (const Access &a : accessesOf(ctx, *st.F, o))
    if (!t || a.ty == t)
      t = a.ty;
    else
      unimplemented("mem-qram: a memset of a parameter or heap slot object accessed as two types of one width",
                    a.I);
  if (!t)
    return info.cellTy;
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
      internalError("mem-qram: the seed form of a memset of a global slot object with cells narrower than a handle "
                    "(lowerSlotMemset routes it to M6)",
                    &I);
    return B.CreateInBoundsGEP(Type::getInt8Ty(C), base.v, B.CreateMul(idx, ConstantInt::get(i64, info.cellBytes)));
  }
  return B.CreateInBoundsGEP(Type::getInt32Ty(C), base.v, idx);
}

// The size in bytes of a slot object of static extent (a local or global).
std::optional<uint64_t> staticObjectBytes(const ObjInfo &info, const DataLayout &DL) {
  uint64_t bytes = 0;
  if (auto *ai = dyn_cast<AllocaInst>(info.root)) {
    auto sz = ai->getAllocationSize(DL);
    if (!sz || sz->isScalable())
      return std::nullopt;
    bytes = sz->getFixedValue();
  } else if (auto *gv = dyn_cast<GlobalVariable>(info.root)) {
    if (!gv->getValueType()->isSized())
      return std::nullopt;
    bytes = DL.getTypeAllocSize(gv->getValueType()).getFixedValue();
  } else {
    return std::nullopt;
  }
  return bytes;
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
  // Every memset this seed form does not take is mem-slots' write path (M6, lowerSlotIntrinsicM6): one
  // update per cell with lowerSlotStore's semantics (a select under a quantum predicate, rule 9; roles as
  // mem-slots gives them), before anything is emitted here.
  if (ctx.currentFlag())
    return lowerSlotIntrinsicM6(ctx, MS, o);
  // The seed form below is the whole-cell update of an object plus classical GEP offsets in mem-slots' handle
  // layout; every other memset (a destination of another form, a run that starts or ends inside a cell, a
  // stride that is not whole cells, a global's cells narrower than a handle) is rule 22's per-cell update on
  // mem-slots' write path (M6), which owns those cells.
  Addr a = decompose(MS.getDest(), DL);
  if (!a.ok)
    return lowerSlotIntrinsicM6(ctx, MS, o);
  if (ctx.T.objectOf(a.root, ctx.S, a.off) != o)
    internalError("mem-qram: the memset destination's root is not the object taint names", &MS);
  ObjInfo &info = objInfo(ctx, st, a.root, o, MS);
  Type *cellTy = cellType(ctx, st, info, o);
  // A record's cells are its fields, each of its own type, and a pointer cell is two handles (rule 21): rule 22's
  // per-cell update on mem-slots' write path (M6) owns them.
  if (info.record || !cellTy || !(cellTy->isIntegerTy() || cellTy->isFloatingPointTy()))
    return lowerSlotIntrinsicM6(ctx, MS, o);
  RailType w = info.boolCells ? RailType{Kind::Int, 1} : railTypeOf(cellTy);
  int64_t cb = int64_t(info.cellBytes);

  Operand fill = ctx.operand(MS.getValue());
  if (fill.handle)
    return lowerSlotIntrinsicM6(ctx, MS, o);
  Operand len = ctx.operand(MS.getLength());
  if (len.handle)
    internalError("mem-qram: a quantum-length memset routed to the seed form (lowerMemIntrinsic sends it to M6)",
                  &MS);
  if (a.off % cb || !wholeCells(MS.getLength(), uint64_t(cb), DL) ||
      (info.kind == RootKind::Global && info.cellBytes < 4) ||
      llvm::any_of(a.terms, [&](const auto &t) { return t.second % cb != 0; }))
    return lowerSlotIntrinsicM6(ctx, MS, o);

  // The role every seed takes (mem-slots' lowerSlotStore of a seed).
  std::optional<Role> role;
  switch (info.kind) {
  case RootKind::Local:
  case RootKind::Heap:
    // A dynamic slot array's seeds are its registers (UserRegister: kept, never cleaned), so a call its
    // pointer escapes to (117's x passed to a _ctl clone) leaves no clean-up to a callee twin.
    // An escaping or static object's cells are mem-slots' (their seeds' clean-up is the callee twin's or
    // the store's, rule 18, 31, 106).
    if (!isDynamic(ctx, st, info, o))
      return lowerSlotIntrinsicM6(ctx, MS, o);
    role = Role::UserRegister;
    break;
  case RootKind::Param:
    if (!ctx.S.isEntry())
      return lowerSlotIntrinsicM6(ctx, MS, o);   // a caller's cells: rule 18's copy-out and twin (31)
    role = Role::Output;
    break;
  case RootKind::Global:
    if (!cast<GlobalVariable>(info.root)->hasLocalLinkage())
      role = Role::Output;   // an extern global is an output (71)
    break;
  }
  if (!role && !isa<ConstantInt>(len.v))
    return lowerSlotIntrinsicM6(ctx, MS, o);   // a run-time length whose seeds are freed: M6's guarded cells

  Type *i64 = Type::getInt64Ty(C);
  // The first cell: the destination's offset in cells.
  Value *first = nullptr;
  for (auto &[v, stride] : a.terms) {
    Operand x = ctx.operand(v);
    if (x.handle)
      internalError("mem-qram: a memset at a quantum offset of an object taint classified a slot array (rule 20: a "
                    "quantum-offset write makes it a QRAM)",
                    &MS);
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
  SmallVector<std::pair<int64_t, Value *>, 8> seeds;   // cq-8101: (byte offset, seed), constant offsets only
  bool constFirst = a.terms.empty();
  auto writeCell = [&](Value *idx) {
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {value});
    RailId id = ctx.unc().recordSeed(seed);
    if (role)
      ctx.unc().setRole(id, *role);
    B.CreateAlignedStore(seed, cellAt(ctx, info, idx, MS), Align(4));
    if (auto *ci = dyn_cast<ConstantInt>(idx); ci && constFirst)
      seeds.push_back({ci->getSExtValue() * cb, seed});
    else
      constFirst = false;
  };

  if (auto *cl = dyn_cast<ConstantInt>(len.v)) {
    uint64_t n = cl->getZExtValue() / uint64_t(cb);
    for (uint64_t j = 0; j < n; ++j)
      writeCell(cellIndex(ConstantInt::get(i64, j)));
    if (info.kind == RootKind::Local && constFirst)
      noteMemsetSeeds(ctx, MS, o, seeds);   // cq-8101: never-written seeds are released (rule 7)
    return;
  }

  if (!role)
    internalError("mem-qram: a run-time-length memset with role-less seeds reached the seed loop", &MS);
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
  std::map<const Value *, uint64_t> bytes;   // per root: the object's size when it is a compile-time constant
  SmallVector<Column, 2> cols;     // ascending off
  // The object may have 2^32 cells or more (CR §1.3, rule 20, cq-k65d): its count is spelled n = 0 (2^64
  // cells) when it does not fit qram_alloc's i32, and a classical cell index that may not fit the _hl form's
  // i32 j is a seed index rail at i64 (the idx form; the index keeps its width, rule 21).
  bool wide = false;
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
  if (auto *vt = dyn_cast<FixedVectorType>(t)) {
    // Rule 25: a vector is its lanes, one column each; lanes that are not whole bytes are packed in
    // memory and are one integer column of their bits (the byte engine splits them).
    uint64_t eb = DL.getTypeSizeInBits(vt->getElementType()).getFixedValue();
    if (eb % 8 == 0) {
      for (unsigned i = 0; i < vt->getNumElements(); ++i)
        leaves(vt->getElementType(), off + i * (eb / 8), DL, out, at);
      return;
    }
    Column c;
    c.off = off;
    c.cellTy = IntegerType::get(t->getContext(), unsigned(eb * vt->getNumElements()));
    c.w = railTypeOf(c.cellTy);
    out.push_back(c);
    return;
  }
  if (t->isVectorTy())
    internalError("mem-qram: a scalable vector on x86-64 (rule 25)", at);
  if (t->isPointerTy() && at && codeAddressCells(at)) {
    // CR rule 13 (b137e75): a cell only code addresses are stored into holds the i64 integer.
    Column c;
    c.off = off;
    c.cellTy = Type::getInt64Ty(t->getContext());
    c.w = RailType{Kind::Int, 64};
    out.push_back(c);
    return;
  }
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
    internalError("mem-qram: a memory object leaf that is no integer, floating point, pointer or vector lane (C has "
                  "none)",
                  at);
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
  // An element of no bytes or no scalar field holds nothing: the object has no cells, every access to it
  // is outside it (§2: a load reads 0, a store does nothing; the byte engine touches no cell).
  if (!q.elemBytes)
    q.elemBytes = 1;
  leaves(t, 0, DL, q.cols, at);
  return q;
}

bool crossesAsQramTriple(LoweringContext &ctx, const CallBase &CB, const Use &u);

// The scalar leaf types of a type (its cells' candidates).
void scalarLeafTypes(Type *t, SmallVectorImpl<Type *> &out) {
  if (auto *st = dyn_cast<StructType>(t)) {
    for (Type *e : st->elements())
      scalarLeafTypes(e, out);
  } else if (auto *at = dyn_cast<ArrayType>(t)) {
    scalarLeafTypes(at->getElementType(), out);
  } else if (auto *vt = dyn_cast<VectorType>(t)) {
    scalarLeafTypes(vt->getElementType(), out);
  } else {
    out.push_back(t);
  }
}

// A heap block's element: the one type every load and store of the object in F uses. A block accessed as
// several types has the cells of the narrowest scalar its quantum-offset accesses use (else its accesses
// use): every access is whole such cells or the byte engine's bytes of them. A block this function only
// hands to clones (rule 21 triples) has the cells their formals access; one nothing accesses holds none.
QramObj heapLayout(LoweringContext &ctx, const Function &F, ObjectId o, const Value *site) {
  const DataLayout &DL = ctx.M.getDataLayout();
  Type *t = nullptr;
  bool several = false;
  SmallVector<Access, 8> as = accessesOf(ctx, F, o);
  for (const Access &a : as) {
    if (!t)
      t = a.ty;
    else if (t != a.ty)
      several = true;
  }
  if (several) {
    Type *best = nullptr;
    for (bool quantumOnly : {true, false}) {
      for (const Access &a : as) {
        if (quantumOnly && ctx.T.offsetKind(a.I, ctx.S) != OffsetKind::Quantum)
          continue;
        SmallVector<Type *, 4> ls;
        scalarLeafTypes(a.ty, ls);
        for (Type *x : ls)
          if (!x->isPointerTy() &&
              (!best || DL.getTypeAllocSize(x).getFixedValue() < DL.getTypeAllocSize(best).getFixedValue()))
            best = x;
      }
      if (best)
        break;
    }
    // Every leaf a pointer (a block of pointers read as a pointer and as an aggregate of pointers): its cells
    // are pointer cells, each a fat (tag, idx) pair (rule 21, 88).
    t = best ? best : PointerType::get(ctx.M.getContext(), 0);
  }
  if (!t) {
    for (const Use &u : site->uses())
      if (auto *CB = dyn_cast<CallBase>(u.getUser()); CB && crossesAsQramTriple(ctx, *CB, u)) {
        t = formalCellType(*CB->getCalledFunction()->getArg(CB->getArgOperandNo(&u)));
        break;
      }
    if (!t)
      t = Type::getInt8Ty(ctx.M.getContext());   // no access anywhere reads or writes a cell
  }
  return layoutOf(t, DL, site);
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
      // cq-py5f (rule 24): an atomic read-modify-write through the pointer is an access, not an escape.
      if (auto *rmw = dyn_cast<AtomicRMWInst>(usr); rmw && rmw->getPointerOperand() == v && rmw->getValOperand() != v)
        continue;
      if (auto *cx = dyn_cast<AtomicCmpXchgInst>(usr); cx && cx->getPointerOperand() == v &&
                                                      cx->getNewValOperand() != v && cx->getCompareOperand() != v)
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
// rule 20 / §1.3, a quantum size allocates at its upper bound. Saturated at 2^62 (every caller's count
// of cells then exceeds what it can allocate or unroll, and says so).
constexpr uint64_t kSatBound = uint64_t(1) << 62;
uint64_t upperBound(const Value *v, const DataLayout &DL, const Instruction &I) {
  if (!v->getType()->isIntegerTy())
    internalError("mem-qram: a size that is not an integer", &I);
  APInt m = computeKnownBits(v, DL).getMaxValue();
  APInt r = computeConstantRange(v, /*ForSigned=*/false).getUnsignedMax();
  APInt b = APIntOps::umin(m, r);
  if (b.getActiveBits() > 62)
    return kSatBound;
  return b.getZExtValue();
}

uint64_t satMul(uint64_t a, uint64_t b) {
  uint64_t r;
  return __builtin_mul_overflow(a, b, &r) || r > kSatBound ? kSatBound : r;
}

// CR §1.3 (cq-k65d, 2026-11-02): qram_alloc / qram_realloc take an i32 cell count, and n = 0 denotes 2^64
// cells. A count of 2^32 or more is spelled 0: the object is then a superset of the C object (an index past
// the C object's end is undefined behaviour, outside the domain), and q.wide.
Value *cellCountArg(LoweringContext &ctx, QramObj &q, uint64_t cells) {
  Type *i32 = Type::getInt32Ty(ctx.M.getContext());
  if (cells > UINT32_MAX) {
    q.wide = true;
    return ConstantInt::get(i32, 0);
  }
  return ConstantInt::get(i32, cells);
}

// A run-time i64 cell count: itself when below 2^32, else 0 (2^64 cells). wideMax: an upper bound of it.
Value *cellCountArg(LoweringContext &ctx, QramObj &q, Value *cells64, uint64_t wideMax) {
  IRBuilder<> &B = ctx.B();
  Type *i32 = Type::getInt32Ty(ctx.M.getContext()), *i64 = Type::getInt64Ty(ctx.M.getContext());
  if (auto *c = dyn_cast<ConstantInt>(cells64))
    return cellCountArg(ctx, q, c->getZExtValue());
  if (wideMax <= UINT32_MAX)
    return B.CreateTrunc(cells64, i32);
  q.wide = true;
  Value *big = B.CreateICmpUGT(cells64, ConstantInt::get(i64, UINT32_MAX));
  return B.CreateSelect(big, ConstantInt::get(i32, 0), B.CreateTrunc(cells64, i32));
}

// Where a global QRAM keeps its bus handles: the compiler-made @<global>.qram (CR rule 20, 160, 192;
// cq-pf4n, 2026-11-02), `internal global i32 0` for one column, [k x i32] for k columns. The global itself
// keeps its definition or declaration as it is: its storage is the host object the bus is seeded from.
Value *busStorage(Module &M, GlobalVariable &gv, const QramObj &q) {
  std::string name = (gv.getName() + ".qram").str();
  if (GlobalVariable *g = M.getNamedGlobal(name))
    return g;
  Type *i32 = Type::getInt32Ty(M.getContext());
  Type *ty = q.cols.size() == 1 ? i32 : static_cast<Type *>(ArrayType::get(i32, q.cols.size()));
  auto *g = new GlobalVariable(M, ty, /*isConstant=*/false, GlobalValue::InternalLinkage, Constant::getNullValue(ty),
                               name);
  g->setAlignment(Align(4));
  return g;
}

// Rule 20 (CR §1.3, BACKEND_ABI §1.10; cq-pf4n, 2026-11-02): a global QRAM is allocated ONCE by a module
// constructor __cq_qram_init_<global> (llvm.global_ctors, priority 65535) as cqrt_qram_alloc_host_<W>(ptr p,
// i64 n): the bus whose cell j starts as the W-bit element at p + j * allocsize(W), read at the call (program
// start), i.e. the global's own storage: its initializer, or for a declaration the definer's contents. The
// compiler never reads an initializer. n is the global's cell count, 0 for an object of unknown extent (a
// declaration of no size, `extern T g[]`: 2^64 cells). The handle of column k is kept in @<global>.qram.
//
// A column whose cells are exactly the object's elements (one scalar column: element stride = the cell
// type's alloc size) is seeded from the global itself. A column of a struct element (stride and offset differ
// from the cell type's) has no single host array of its cells; the constructor first copies the column into a
// contiguous buffer of its own frame and seeds the bus from that (the host object is still read only at
// program start). A column of pointers holds fat (tag, idx) pairs (rule 21), whose start value for a null
// cell is (0, 0): its buffer is zero.
void ensureGlobalCtor(LoweringContext &ctx, GlobalVariable &gv, QramObj &q) {
  Module &M = ctx.M;
  LLVMContext &C = M.getContext();
  std::string name = ("__cq_qram_init_" + gv.getName()).str();
  const DataLayout &DL = M.getDataLayout();
  if (gv.isConstant())
    internalError("mem-qram: a constant global is a QRAM", &gv);
  uint64_t size = DL.getTypeAllocSize(gv.getValueType()).getFixedValue();
  uint64_t n = size / q.elemBytes;
  // An object of unknown extent (a declaration of no size): n = 0, 2^64 cells. Its cells, like those of an
  // object of 2^32 cells or more, are addressed by an i64 index rail (q.wide, cq-k65d).
  bool unknown = !gv.hasInitializer() && size == 0;
  q.wide |= unknown || n > UINT32_MAX;
  if (M.getFunction(name))
    return;
  for (const Column &c : q.cols)
    if (c.ptrPart && (!gv.hasInitializer() || !gv.getInitializer()->isNullValue()))
      unimplemented("mem-qram: a global QRAM of pointers with an initializer", &gv);
  Function *F = Function::Create(FunctionType::get(Type::getVoidTy(C), false), GlobalValue::InternalLinkage, name, M);
  IRBuilder<> B(BasicBlock::Create(C, "", F));
  Type *i8 = Type::getInt8Ty(C), *i64 = Type::getInt64Ty(C);
  Value *nArg = ConstantInt::get(i64, unknown ? 0 : n);
  SmallVector<Value *, 2> a;
  for (const Column &c : q.cols) {
    uint64_t cb = DL.getTypeAllocSize(c.ptrPart ? Type::getInt32Ty(C) : c.cellTy).getFixedValue();
    Value *src = &gv;
    if (c.ptrPart || c.off != 0 || cb != q.elemBytes) {
      if (unknown)
        unimplemented("SPEC_ISSUES: a global QRAM of unknown extent whose element has several columns "
                      "(qram_alloc_host_<W> reads cells at the cell type's stride; no strided form exists)",
                      &gv);
      // The column's cells, contiguous: a buffer of n cells in the constructor's frame.
      IRBuilder<> EB(&F->getEntryBlock(), F->getEntryBlock().begin());
      AllocaInst *buf = EB.CreateAlloca(i8, ConstantInt::get(i64, n * cb));
      buf->setAlignment(Align(16));
      if (c.ptrPart) {
        B.CreateMemSet(buf, ConstantInt::get(i8, 0), ConstantInt::get(i64, n * cb), Align(16));
      } else if (n > 0) {
        BasicBlock *pre = B.GetInsertBlock();
        BasicBlock *body = BasicBlock::Create(C, "", F), *done = BasicBlock::Create(C, "", F);
        B.CreateBr(body);
        B.SetInsertPoint(body);
        PHINode *j = B.CreatePHI(i64, 2);
        j->addIncoming(ConstantInt::get(i64, 0), pre);
        Value *from = B.CreateInBoundsGEP(
            i8, &gv, B.CreateAdd(B.CreateMul(j, ConstantInt::get(i64, q.elemBytes)), ConstantInt::get(i64, c.off)));
        Value *to = B.CreateInBoundsGEP(i8, buf, B.CreateMul(j, ConstantInt::get(i64, cb)));
        B.CreateStore(B.CreateLoad(c.cellTy, from), to);
        Value *j1 = B.CreateAdd(j, ConstantInt::get(i64, 1), "", /*HasNUW=*/true, /*HasNSW=*/true);
        j->addIncoming(j1, B.GetInsertBlock());
        B.CreateCondBr(B.CreateICmpEQ(j1, ConstantInt::get(i64, n)), done, body);
        B.SetInsertPoint(done);
      }
      src = buf;
    }
    a.push_back(B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::QramAllocHost, c.w}), {src, nArg}));
  }
  Value *store = busStorage(M, gv, q);
  for (unsigned k = 0; k < a.size(); ++k)
    B.CreateAlignedStore(a[k], k ? B.CreateConstInBoundsGEP1_64(i8, store, 4 * k) : store, Align(4));
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
    // A parameter pointing into a QRAM is a triple formal of a clone (CR §1.4: a QRAM pointer is a quantum argument,
    // taint lifts its callee), registered as a QRAM over the caller's bus (registerFormalQram): it is found above.
    unimplemented("mem-qram: a QRAM access to a site that was not allocated as a QRAM (field columns of "
                  "different classes, rule 20, or an allocation not lowered before the access)",
                  &I);
  }
  // A thread-local QRAM is one object (rule 24's single-thread collapse): the module constructor runs on the
  // one thread.
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
    Value *store = busStorage(ctx.M, *gv, q);
    Value *p = k ? EB.CreateConstInBoundsGEP1_64(Type::getInt8Ty(C), store, 4 * k) : store;
    LoadInst *h = EB.CreateAlignedLoad(Type::getInt32Ty(C), p, Align(4));
    ctx.unc().recordExternal(h, Role::Output);
    hs.push_back(h);
  }
  q.buses[gv] = hs;
  q.bytes[gv] = ctx.M.getDataLayout().getTypeAllocSize(gv->getValueType()).getFixedValue();
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

Value *seedOf(LoweringContext &ctx, RailType w, Value *v);

// The classical cell index jb + e of an access to q: the _hl form's i32 j, or, for an object that may have
// 2^32 cells or more (q.wide) and an index not provably below 2^32, an i64 seed index rail (rule 7) for the
// idx form (CR §1.3: the idx form addresses any cell; rule 21's i64 idx, cq-k65d).
QIndex classicalIndex(LoweringContext &ctx, const QramObj &q, Value *jb, int64_t e) {
  LLVMContext &C = ctx.M.getContext();
  Type *i64 = Type::getInt64Ty(C);
  if (!q.wide || (!jb && e >= 0 && uint64_t(e) <= UINT32_MAX))
    return {elemIndex(ctx, jb, e), false};
  Value *x = jb ? (e ? ctx.B().CreateAdd(jb, ConstantInt::get(i64, e, true)) : jb) : ConstantInt::get(i64, e, true);
  return {seedOf(ctx, RailType{Kind::Int, 64}, x), true};
}

bool sameCellType(const DataLayout &DL, Type *access, const Column &c) {
  if (access->isPointerTy() && !c.ptrPart && c.cellTy->isIntegerTy(64))
    return true;   // rule 13: a code address in its i64 cell
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

// nullopt when the run covers part of a cell or a pointer cell (the byte engine's: readBytes, writeBytes).
std::optional<SmallVector<Hit, 8>> cellsIn(const DataLayout &DL, const QramObj &q, int64_t off, uint64_t len,
                                           const Instruction &I) {
  (void)I;
  SmallVector<Hit, 8> out;
  int64_t E = int64_t(q.elemBytes);
  int64_t end = off + int64_t(len);
  for (int64_t e = floorDiv(off, E); e * E < end; ++e)
    for (const Column &c : q.cols) {
      int64_t s = e * E + int64_t(c.off), sz = int64_t(storeBytes(DL, c.cellTy));
      int64_t lo = std::max(s, off), hi = std::min(s + sz, end);
      if (lo >= hi)
        continue;
      if (lo != s || hi != s + sz || c.ptrPart)
        return std::nullopt;
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
// cq-8un4 (owner 2026-11-01 on cq-dxii): a QRAM store is recorded once per lowering of its instruction, so
// a store executed on every trip of a loop of its own function is right only when a loop unit (loops::
// lowerClassical / lowerCutoff) lowers each trip; a loop the walker copied as a real loop would run the
// store each trip and pop it once (the store-twice hazard). The LoopInfo is of the store's own function.
void checkStoreOnce(LoweringContext &ctx, const Instruction &orig) {
  const Function &F = *orig.getFunction();
  DominatorTree DT(const_cast<Function &>(F));
  LoopInfo LI(DT);
  const Loop *L = LI.getLoopFor(orig.getParent());
  if (!L)
    return;
  const Loop *U = ctx.loopUnit();
  if (U && U->getHeader()->getParent() == &F && U->contains(L->getHeader()))
    return;
  internalError("mem-qram: a QRAM store executed on every trip of a loop but recorded once (store-twice hazard, "
                "cq-dxii)",
                &orig);
}

void emitStore(LoweringContext &ctx, Value *bus, const Column &c, QIndex idx, Value *v, Value *flag,
               const Instruction &orig) {
  checkStoreOnce(ctx, orig);
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
  if (cellTy->isPointerTy())   // a pointer cell's bytes are its address (rule 21)
    return B.CreateIntToPtr(B.CreateTrunc(x, ctx.M.getDataLayout().getIntPtrType(cellTy)), cellTy);
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
  Addr a = decompose(ptr, ctx.M.getDataLayout(), &ctx);
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

// v's value modulo 2^W as a rail (W <= 64), exactly as the GEP's address arithmetic reads the index: a
// quantum extension above W is stripped (it leaves the low W bits), one below W applied by its template
// (a zext of a sext is two extensions); an uncast top-level index narrower than 64 bits is sign-extended by
// the GEP itself, a wider one truncated.
Value *indexRailAt(LoweringContext &ctx, const Value *v, unsigned W, bool top, const Instruction &I) {
  auto tmpl = [&](StringRef op, unsigned from, Value *x) {
    abi::TemplateSpec s;
    s.op = op.str();
    s.w = RailType{Kind::Int, from};
    s.to = RailType{Kind::Int, W};
    return ctx.emitTemplate(s, {Operand{x, true}});
  };
  if (isa<ZExtInst>(v) || isa<SExtInst>(v)) {
    const Value *x = cast<CastInst>(v)->getOperand(0);
    if (ctx.T.isQuantum(x, ctx.S)) {
      unsigned w = x->getType()->getIntegerBitWidth();
      if (W <= w)
        return indexRailAt(ctx, x, W, false, I);
      return tmpl(isa<SExtInst>(v) ? "sext" : "zext", w, indexRailAt(ctx, x, w, false, I));
    }
  }
  Operand r = ctx.operand(v);
  if (!r.handle || !v->getType()->isIntegerTy())
    internalError("mem-qram: a quantum QRAM index term that is not an integer rail", &I);
  unsigned w = v->getType()->getIntegerBitWidth();
  if (w == W)
    return r.v;
  if (w > W)
    return tmpl("trunc", w, r.v);
  if (!top)
    internalError("mem-qram: an index term narrower than its width below its extension", &I);
  return tmpl("sext", w, r.v);
}

// The cell index of a QRAM access. A quantum address is its logical index rail alone when it is the
// address's only term at one element's stride with no element offset; otherwise rule 20's index
// arithmetic as templates: each quantum term's logical index widened by its own extension to the C index
// width (at least int, 32, or the widest index), scaled by its stride in elements (mul_hl, the 2-D
// flattening r * cols + c, 191), the scaled terms added in GEP order, then the classical element offset
// (the classical terms and the constant) added (add_hl, 192). A modular sum at that width is the exact
// cell index: every in-domain cell index of a QRAM is below 2^32 (qram_alloc takes an i32 cell count).
// extra: a classical i64 element offset added to the address (rule 22's loop over a run's elements), or null.
Value *withExtra(LoweringContext &ctx, Value *j, Value *extra) {
  if (!extra)
    return j;
  return j ? ctx.B().CreateAdd(j, extra) : extra;
}

QIndex cellIndex(LoweringContext &ctx, const QramObj &q, const Addr &a, const Instruction &I,
                 Value *extra = nullptr) {
  int64_t E = int64_t(q.elemBytes);
  int64_t ec = floorDiv(a.off, E);
  if (!quantumTerm(ctx, a, I))
    return classicalIndex(ctx, q, withExtra(ctx, classicalElems(ctx, q, a, I), extra), ec);
  SmallVector<std::tuple<LogicalIndex, int64_t, const Value *>, 2> qs;   // logical index, stride in elements, GEP index
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
    qs.push_back({logicalIndex(ctx, t.first, I), t.second / E, t.first});
  }
  if (qs.size() == 1 && std::get<1>(qs[0]) == 1 && others.terms.empty() && ec == 0 && !extra)
    return {std::get<0>(qs[0]).rail, true};
  unsigned Ws = q.wide ? 64 : 32;
  for (auto &[li, k, g] : qs)
    Ws = std::max(Ws, std::min(64u, li.bits));
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
  for (auto &[li, k, g] : qs) {
    Value *r = li.rail;
    if (li.zextOverSext || li.bits > Ws) {
      r = indexRailAt(ctx, g, Ws, /*top=*/true, I);   // the extensions as the GEP reads them
    } else if (li.bits < Ws) {
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
  Value *j = withExtra(ctx, classicalElems(ctx, q, others, I), extra);
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
// false (nothing emitted) for any other store: the byte engine's (storeThroughBytes).
bool storeClassicalBytes(LoweringContext &ctx, const QAccess &acc, Value *val, Type *ty, Value *flag,
                         const Instruction &I) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  IRBuilder<> &B = ctx.B();
  if (quantumTerm(ctx, acc.a, I))
    return false;
  if (ty->isPointerTy() || ty->isStructTy() || ty->isArrayTy() || ty->isVectorTy())
    return false;
  uint64_t bytes = storeBytes(DL, ty);
  unsigned prim = unsigned(ty->getPrimitiveSizeInBits().getFixedValue());
  if (prim != bytes * 8 && !ty->isIntegerTy())
    return false;
  std::optional<SmallVector<Hit, 8>> hits = cellsIn(DL, *acc.q, acc.a.off, bytes, I);
  if (!hits)
    return false;
  Value *x = val;
  if (!ty->isIntegerTy())
    x = B.CreateBitCast(x, IntegerType::get(C, prim));
  if (prim != bytes * 8)
    x = B.CreateZExt(x, IntegerType::get(C, unsigned(bytes * 8)));
  const QramObj &q = *acc.q;
  Value *jb = classicalElems(ctx, q, acc.a, I);
  for (const Hit &h : *hits) {
    Value *v = seedOf(ctx, h.col->w, bytesToCell(ctx, x, h.rel, h.col->cellTy));
    emitStore(ctx, busOf(q, acc.a.root, h.col, I), *h.col, classicalIndex(ctx, q, jb, h.elem), v, flag, I);
  }
  return true;
}


// ---- the byte engine: runs of bytes over QRAM cells (bit views on a QRAM, rules 20, 22) --------------
//
// An access whose bytes are not exactly whole cells of their own type (63's bit view, a wide store over
// several cells, a memory intrinsic over part of a cell) is ONE QRAM access per touched cell (rule 20):
//  - read: each touched cell's _hl or quantum-index load (the cell unchanged), its touched bytes taken by
//    lshr/trunc and placed by zext/shl/or into an integer rail of the access's bytes (templates, rule 4;
//    bytes no cell holds, padding, read 0);
//  - write: a cell the run covers whole is stored its bytes of the value; a cell it covers in part is
//    read, merged with the new bytes ((old & ~mask) | (new << shift)) and the merge stored. The store
//    swaps the old cell out to its tape slot (§1.3); the pop restores it before the read's _unc.
// The cell of element e (relative to the address's classical base) is at index cellIndex of the address
// with that element offset: the quantum index plus e for a quantum address.
struct Piece {
  const Column *col;
  int64_t elem;               // element index relative to the base
  uint64_t cellLo, cellHi;    // the touched bytes of the cell
  uint64_t valLo;             // the first of them relative to the run's start
};

SmallVector<Piece, 8> piecesIn(const DataLayout &DL, const QramObj &q, int64_t off, uint64_t len,
                               const Instruction &I) {
  SmallVector<Piece, 8> out;
  int64_t E = int64_t(q.elemBytes);
  int64_t end = off + int64_t(len);
  for (int64_t e = floorDiv(off, E); e * E < end; ++e)
    for (const Column &c : q.cols) {
      int64_t s = e * E + int64_t(c.off), sz = int64_t(storeBytes(DL, c.cellTy));
      int64_t lo = std::max(s, off), hi = std::min(s + sz, end);
      if (lo >= hi)
        continue;
      if (c.ptrPart)
        unimplemented("mem-qram: the bytes of a QRAM pointer cell (rule 21: a fat pointer cell holds (tag, idx), not "
                      "an address's bytes)",
                      &I);
      out.push_back({&c, e, uint64_t(lo - s), uint64_t(hi - s), uint64_t(lo - off)});
    }
  return out;
}

QIndex indexAt(LoweringContext &ctx, const QramObj &q, const Addr &a, int64_t e, const Instruction &I,
               Value *extra = nullptr) {
  Addr a2 = a;
  a2.off = e * int64_t(q.elemBytes);
  return cellIndex(ctx, q, a2, I, extra);
}

// Integer arithmetic on an Operand: a rail by its template (rule 4), a classical value by plain IR.
Operand intOp(LoweringContext &ctx, StringRef op, unsigned w, Operand x, const APInt &k) {
  IRBuilder<> &B = ctx.B();
  Constant *kc = ConstantInt::get(ctx.M.getContext(), k.zextOrTrunc(w));
  if (!x.handle) {
    if (op == "lshr")
      return {B.CreateLShr(x.v, kc), false};
    if (op == "shl")
      return {B.CreateShl(x.v, kc), false};
    if (op == "and")
      return {B.CreateAnd(x.v, kc), false};
    if (op == "mul")
      return {B.CreateMul(x.v, kc), false};
    internalError("mem-qram: intOp of an unknown operation");
  }
  abi::TemplateSpec s;
  s.op = op.str();
  s.w = RailType{Kind::Int, w};
  s.shape = "hl";
  return {ctx.emitTemplate(s, {x, Operand{kc, false}}), true};
}

Operand intCast(LoweringContext &ctx, StringRef op, unsigned from, unsigned to, Operand x) {
  if (from == to)
    return x;
  Type *ty = IntegerType::get(ctx.M.getContext(), to);
  if (!x.handle)
    return {op == "trunc" ? ctx.B().CreateTrunc(x.v, ty) : ctx.B().CreateZExt(x.v, ty), false};
  abi::TemplateSpec s;
  s.op = op.str();
  s.w = RailType{Kind::Int, from};
  s.to = RailType{Kind::Int, to};
  return {ctx.emitTemplate(s, {x}), true};
}

Operand intOr(LoweringContext &ctx, unsigned w, Operand a, Operand b) {
  if (!a.handle && !b.handle)
    return {ctx.B().CreateOr(a.v, b.v), false};
  if (!a.handle)
    std::swap(a, b);
  abi::TemplateSpec s;
  s.op = "or";
  s.w = RailType{Kind::Int, w};
  if (!b.handle)
    s.shape = "hl";
  return {ctx.emitTemplate(s, {a, b}), true};
}

unsigned valueBits(Type *t) { return unsigned(t->getPrimitiveSizeInBits().getFixedValue()); }

// A scalar's bits as an integer of its width (a floating-point value by bitcast), and back.
Operand asInt(LoweringContext &ctx, Operand v, Type *t) {
  if (t->isIntegerTy())
    return v;
  Type *it = IntegerType::get(ctx.M.getContext(), valueBits(t));
  if (!v.handle)
    return {ctx.B().CreateBitCast(v.v, it), false};
  abi::TemplateSpec s;
  s.op = "bitcast";
  s.w = railTypeOf(t);
  s.to = RailType{Kind::Int, valueBits(t)};
  return {ctx.emitTemplate(s, {v}), true};
}

Operand fromInt(LoweringContext &ctx, Operand x, Type *t) {
  if (t->isIntegerTy())
    return x;
  if (!x.handle)
    return {ctx.B().CreateBitCast(x.v, t), false};
  abi::TemplateSpec s;
  s.op = "bitcast";
  s.w = RailType{Kind::Int, valueBits(t)};
  s.to = railTypeOf(t);
  return {ctx.emitTemplate(s, {x}), true};
}

// Bits [lo, lo + n) of the w-bit integer x as an n-bit integer.
Operand intOp(LoweringContext &ctx, StringRef op, unsigned w, Operand x, uint64_t k) {
  return intOp(ctx, op, w, x, APInt(std::max(w, 64u), k));
}

Operand bitsOf(LoweringContext &ctx, Operand x, unsigned w, unsigned lo, unsigned n) {
  if (lo)
    x = intOp(ctx, "lshr", w, x, lo);
  return intCast(ctx, "trunc", w, n, x);
}

// The bits of a touched cell piece that the cell's value holds (bytes past them are padding).
unsigned pieceBits(const DataLayout &DL, const Piece &p) {
  unsigned cw = valueBits(p.col->cellTy);
  unsigned lo = unsigned(8 * p.cellLo), hi = std::min(cw, unsigned(8 * p.cellHi));
  (void)DL;
  return hi > lo ? hi - lo : 0;
}

// The integer (len * 8 bits) the bytes [off, off + len) of the access hold.
Operand readBytes(LoweringContext &ctx, const QAccess &acc, int64_t off, uint64_t len, const Instruction &I,
                  Value *extra = nullptr) {
  const DataLayout &DL = ctx.M.getDataLayout();
  unsigned L = unsigned(len * 8);
  Operand out{ConstantInt::get(IntegerType::get(ctx.M.getContext(), L), 0), false};
  bool any = false;
  for (const Piece &p : piecesIn(DL, *acc.q, off, len, I)) {
    unsigned nb = pieceBits(DL, p);
    if (!nb)
      continue;
    unsigned cw = valueBits(p.col->cellTy);
    QIndex idx = indexAt(ctx, *acc.q, acc.a, p.elem, I, extra);
    Value *cell = emitLoad(ctx, busOf(*acc.q, acc.a.root, p.col, I), *p.col, idx);
    Operand x = bitsOf(ctx, asInt(ctx, Operand{cell, true}, p.col->cellTy), cw, unsigned(8 * p.cellLo), nb);
    x = intCast(ctx, "zext", nb, L, x);
    if (p.valLo)
      x = intOp(ctx, "shl", L, x, 8 * p.valLo);
    out = any ? intOr(ctx, L, out, x) : x;
    any = true;
  }
  return out;
}

// Stores the value's bits (val, an integer of len * 8 bits: a rail or classical) into the bytes [off,
// off + len) of the access, under flag (nullptr: unconditional).
void writePiece(LoweringContext &ctx, const QAccess &acc, const Piece &p, Operand bits, unsigned nb, Value *flag,
                const Instruction &I, Value *extra = nullptr) {
  const Column &c = *p.col;
  unsigned cw = valueBits(c.cellTy);
  QIndex idx = indexAt(ctx, *acc.q, acc.a, p.elem, I, extra);
  Value *bus = busOf(*acc.q, acc.a.root, &c, I);
  Operand cellInt;
  if (p.cellLo == 0 && nb == cw) {
    cellInt = bits;
  } else {
    Value *old = emitLoad(ctx, bus, c, idx);
    Operand oi = asInt(ctx, Operand{old, true}, c.cellTy);
    APInt mask = ~(APInt::getLowBitsSet(cw, nb).shl(unsigned(8 * p.cellLo)));
    Operand kept = intOp(ctx, "and", cw, oi, mask);
    Operand nw = intCast(ctx, "zext", nb, cw, bits);
    if (p.cellLo)
      nw = intOp(ctx, "shl", cw, nw, 8 * p.cellLo);
    cellInt = intOr(ctx, cw, kept, nw);
  }
  Operand v = fromInt(ctx, cellInt, c.cellTy);
  Value *h = v.handle ? v.v : seedOf(ctx, c.w, v.v);
  emitStore(ctx, bus, c, idx, h, flag, I);
}

void writeBytes(LoweringContext &ctx, const QAccess &acc, int64_t off, uint64_t len, Operand val, Value *flag,
                const Instruction &I) {
  const DataLayout &DL = ctx.M.getDataLayout();
  unsigned L = unsigned(len * 8);
  for (const Piece &p : piecesIn(DL, *acc.q, off, len, I)) {
    unsigned nb = pieceBits(DL, p);
    if (!nb)
      continue;
    writePiece(ctx, acc, p, bitsOf(ctx, val, L, unsigned(8 * p.valLo), nb), nb, flag, I);
  }
}

// The scalar leaves of a value type with their byte offsets (rules 25, 26: struct and array elements and
// vector lanes, depth first; aggr's field order). A vector of sub-byte lanes is one integer leaf, split
// into lanes by its users here.
struct VLeaf {
  Type *ty;
  uint64_t off;
  unsigned lanes;   // > 0: a packed vector of that many sub-byte lanes of ty's width / lanes bits
};

void vleaves(Type *t, uint64_t off, const DataLayout &DL, SmallVectorImpl<VLeaf> &out) {
  if (auto *st = dyn_cast<StructType>(t)) {
    const StructLayout *SL = DL.getStructLayout(st);
    for (unsigned i = 0; i < st->getNumElements(); ++i)
      vleaves(st->getElementType(i), off + SL->getElementOffset(i).getFixedValue(), DL, out);
    return;
  }
  if (auto *at = dyn_cast<ArrayType>(t)) {
    uint64_t es = DL.getTypeAllocSize(at->getElementType()).getFixedValue();
    for (uint64_t i = 0; i < at->getNumElements(); ++i)
      vleaves(at->getElementType(), off + i * es, DL, out);
    return;
  }
  if (auto *vt = dyn_cast<FixedVectorType>(t)) {
    uint64_t eb = DL.getTypeSizeInBits(vt->getElementType()).getFixedValue();
    if (eb % 8) {
      out.push_back({IntegerType::get(t->getContext(), unsigned(eb * vt->getNumElements())), off,
                     vt->getNumElements()});
      return;
    }
    for (unsigned i = 0; i < vt->getNumElements(); ++i)
      vleaves(vt->getElementType(), off + i * (eb / 8), DL, out);
    return;
  }
  out.push_back({t, off, 0});
}

bool hasPointerLeaf(Type *t) {
  if (auto *st = dyn_cast<StructType>(t))
    return llvm::any_of(st->elements(), hasPointerLeaf);
  if (auto *at = dyn_cast<ArrayType>(t))
    return hasPointerLeaf(at->getElementType());
  if (auto *vt = dyn_cast<VectorType>(t))
    return hasPointerLeaf(vt->getElementType());
  return t->isPointerTy();
}

bool isAggregate(Type *t) { return t->isStructTy() || t->isArrayTy() || t->isVectorTy(); }

// A load of any non-pointer type through the byte engine: per leaf its bytes, as a rail of its type.
void loadThroughBytes(LoweringContext &ctx, const QAccess &acc, LoadInst &ld) {
  const DataLayout &DL = ctx.M.getDataLayout();
  Type *ty = ld.getType();
  if (isa<ScalableVectorType>(ty))
    internalError("mem-qram: a scalable vector on x86-64 (rule 25)", &ld);
  SmallVector<VLeaf, 4> ls;
  vleaves(ty, 0, DL, ls);
  SmallVector<Operand, 4> fields;
  for (const VLeaf &l : ls) {
    uint64_t sb = storeBytes(DL, l.ty);
    unsigned vb = valueBits(l.ty);
    Operand x = readBytes(ctx, acc, acc.a.off + int64_t(l.off), sb, ld);
    x = intCast(ctx, "trunc", unsigned(sb * 8), vb, x);
    x = fromInt(ctx, x, l.ty);
    if (!x.handle)
      x = Operand{seedOf(ctx, railTypeOf(l.ty), x.v), true};
    if (l.lanes) {
      unsigned w = vb / l.lanes;
      for (unsigned i = 0; i < l.lanes; ++i) {
        Operand lane = bitsOf(ctx, x, vb, i * w, w);
        fields.push_back(lane);
      }
    } else {
      fields.push_back(x);
    }
  }
  if (isAggregate(ty))
    ctx.bindFields(&ld, fields);
  else
    ctx.bind(&ld, fields.front().v);
}

// A store of any non-pointer value through the byte engine: per leaf its bits into its bytes.
void storeThroughBytes(LoweringContext &ctx, const QAccess &acc, const Value *val, Value *flag, const Instruction &I) {
  const DataLayout &DL = ctx.M.getDataLayout();
  Type *ty = val->getType();
  SmallVector<VLeaf, 4> ls;
  vleaves(ty, 0, DL, ls);
  SmallVector<Operand, 4> fs;
  if (isAggregate(ty)) {
    fs = ctx.fields(val);
    if (fs.size() == 1 && !fs.front().handle && ls.size() + 0 != 1) {
      // A classical composite bound as one value: its leaves by extraction.
      Value *agg = fs.front().v;
      fs.clear();
      std::function<void(Value *, Type *)> walk = [&](Value *v, Type *t) {
        if (auto *st = dyn_cast<StructType>(t)) {
          for (unsigned i = 0; i < st->getNumElements(); ++i)
            walk(ctx.B().CreateExtractValue(v, {i}), st->getElementType(i));
        } else if (auto *at = dyn_cast<ArrayType>(t)) {
          for (unsigned i = 0; i < at->getNumElements(); ++i)
            walk(ctx.B().CreateExtractValue(v, {i}), at->getElementType());
        } else if (auto *vt = dyn_cast<FixedVectorType>(t)) {
          for (unsigned i = 0; i < vt->getNumElements(); ++i)
            walk(ctx.B().CreateExtractElement(v, uint64_t(i)), vt->getElementType());
        } else {
          fs.push_back(Operand{v, false});
        }
      };
      walk(agg, ty);
    }
  } else {
    fs.push_back(ctx.operand(val));
  }
  size_t k = 0;
  for (const VLeaf &l : ls) {
    uint64_t sb = storeBytes(DL, l.ty);
    unsigned vb = valueBits(l.ty);
    Operand x;
    if (l.lanes) {
      unsigned w = vb / l.lanes;
      for (unsigned i = 0; i < l.lanes; ++i, ++k) {
        if (k >= fs.size())
          internalError("mem-qram: a stored composite with fewer fields than leaves", &I);
        Operand lane = intCast(ctx, "zext", w, vb, fs[k]);
        if (i)
          lane = intOp(ctx, "shl", vb, lane, uint64_t(i) * w);
        x = i ? intOr(ctx, vb, x, lane) : lane;
      }
    } else {
      if (k >= fs.size())
        internalError("mem-qram: a stored composite with fewer fields than leaves", &I);
      x = asInt(ctx, fs[k++], l.ty);
    }
    x = intCast(ctx, "zext", vb, unsigned(sb * 8), x);
    writeBytes(ctx, acc, acc.a.off + int64_t(l.off), sb, x, flag, I);
  }
}

// Rule 22 over a QRAM destination: a classical length is one _hl store per covered cell (memset: one
// shared basis-state seed per cell type, 30, 55; memcpy/memmove: each cell the source cell's value, a
// seed of a classical source byte run (73, 168) or a _hl load of a QRAM source cell). All source cells
// are read before any store (memmove). Under a quantum predicate the stores are _controlled. This is the
// whole-cell form at a classical constant length; false (nothing emitted) when the intrinsic is not of
// that form (lowerQramIntrinsicBytes takes it).
bool lowerQramIntrinsicCells(LoweringContext &ctx, MemIntrinsic &MI, const QAccess &acc, uint64_t length) {
  const DataLayout &DL = ctx.M.getDataLayout();
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  const QramObj &q = *acc.q;
  std::optional<SmallVector<Hit, 8>> hitsOpt = cellsIn(DL, q, acc.a.off, length, MI);
  if (!hitsOpt)
    return false;
  SmallVector<Hit, 8> &hits = *hitsOpt;
  // The source's form, decided before anything is emitted.
  const Value *src = nullptr;
  enum { Fill, Host, Qram, Slot } kind = Fill;
  QAccess sacc{};
  if (auto *MS = dyn_cast<MemSetInst>(&MI)) {
    if (ctx.operand(MS->getValue()).handle)
      for (const Hit &h : hits)
        if (!h.col->cellTy->isIntegerTy(8))
          return false;   // a quantum fill into wider cells: the splat (byte engine)
  } else {
    src = cast<MemTransferInst>(MI).getSource();
    if (ctx.T.isFatPointer(src, ctx.S))
      return false;
    ArrayRef<ObjectId> so = ctx.T.provenance(src, ctx.S);
    if (llvm::all_of(so, [&](ObjectId x) { return ctx.T.classOf(x) == ObjClass::Classical; })) {
      kind = Host;
    } else if (so.size() == 1 && ctx.T.classOf(so.front()) == ObjClass::Qram) {
      kind = Qram;
      sacc = qramAccess(ctx, src, MI);
      if (quantumTerm(ctx, sacc.a, MI))
        return false;
      int64_t SE = int64_t(sacc.q->elemBytes);
      for (const Hit &h : hits) {
        int64_t p = sacc.a.off + int64_t(h.rel);
        int64_t se = floorDiv(p, SE);
        const Column *sc = sacc.q->at(uint64_t(p - se * SE));
        if (!sc || sc->cellTy != h.col->cellTy)
          return false;   // the cells do not line up (a bit view)
      }
    } else if (so.size() == 1 && ctx.T.classOf(so.front()) == ObjClass::Slot) {
      kind = Slot;
      Type *cellTy = hits.empty() ? nullptr : hits.front().col->cellTy;
      uint64_t size = cellTy ? DL.getTypeAllocSize(cellTy).getFixedValue() : 0;
      for (size_t i = 0; i < hits.size(); ++i)
        if (hits[i].col->cellTy != cellTy || hits[i].rel != i * size)
          unimplemented("mem-qram: a memcpy/memmove from a slot array into QRAM cells of several types or not "
                        "consecutive (a struct column layout, 168)",
                        &MI);
    } else {
      return false;
    }
  }
  Value *flag = ctx.currentFlag();
  Value *jb = classicalElems(ctx, q, acc.a, MI);
  SmallVector<Value *, 8> vals;
  if (auto *MS = dyn_cast<MemSetInst>(&MI)) {
    Operand fill = ctx.operand(MS->getValue());
    if (fill.handle) {
      // Rule 22 (72's memset_quantum_byte): a quantum fill byte into byte cells is the fill rail itself,
      // stored into each cell (it stays live until the last of those stores is popped).
      for (size_t i = 0; i < hits.size(); ++i)
        vals.push_back(fill.v);
    }
    std::map<std::pair<unsigned, unsigned>, Value *> seeds;   // one shared seed per cell type (rule 22)
    for (const Hit &h : fill.handle ? ArrayRef<Hit>() : ArrayRef<Hit>(hits)) {
      Value *&s = seeds[{unsigned(h.col->w.kind), h.col->w.bits}];
      if (!s)
        s = seedOf(ctx, h.col->w, splatCell(ctx, fill.v, h.col->cellTy));
      vals.push_back(s);
    }
  } else if (kind == Host) {
    auto *MT = cast<MemTransferInst>(&MI);
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
  } else if (kind == Qram) {
    const QramObj &sq = *sacc.q;
    Value *sjb = classicalElems(ctx, sq, sacc.a, MI);
    int64_t SE = int64_t(sq.elemBytes);
    for (const Hit &h : hits) {
      int64_t p = sacc.a.off + int64_t(h.rel);
      int64_t se = floorDiv(p, SE);
      const Column *sc = sq.at(uint64_t(p - se * SE));
      vals.push_back(emitLoad(ctx, busOf(sq, sacc.a.root, sc, MI), *sc, classicalIndex(ctx, sq, sjb, se)));
    }
  } else {
    // 73: a slot array source. The covered QRAM cells are consecutive cells of one type; their source
    // cells are mem-slots' reads of the slot's cells at the copy (M4 readSlotCells): the handle a cell
    // holds is stored as it is (the slot keeps it), a classical cell is a seed (rule 7).
    if (!hits.empty()) {
      SmallVector<Operand, 8> cells = readSlotCells(ctx, src, hits.front().col->cellTy, hits.size(), MI);
      for (size_t i = 0; i < cells.size(); ++i)
        vals.push_back(cells[i].handle ? cells[i].v : seedOf(ctx, hits[i].col->w, cells[i].v));
    }
  }
  for (size_t i = 0; i < hits.size(); ++i) {
    const Hit &h = hits[i];
    emitStore(ctx, busOf(q, acc.a.root, h.col, MI), *h.col, classicalIndex(ctx, q, jb, h.elem),
              vals[i], flag, MI);
  }
  return true;
}

// ---- rule 22's classical loop over a run's cells (cq-k65d, f684858: no unroll bound) ----------------
//
// A memory intrinsic into a QRAM whose length is a run-time value is one ordinary update per cell emitted
// as a classical loop over the cells (rule 22), and its reverse loop pops the stores (CR §1.3). The trip
// unit is a CHUNK of U = lcm(E, Es) bytes of the destination (E its element size, Es a QRAM source's,
// else E), chunk c covering the destination bytes [cU, cU + U) from the run's first element; its cell
// pieces (piecesIn, static) are each stored their bytes of the new value when the run covers them:
//  - a classical length L: the piece of chunk-relative bytes [lo, hi) is guarded by the classical
//    cU + lo >= r0 && cU + hi <= r0 + L (r0: the run's start inside its first element), a seed flag
//    (rules 7, 8); C = ceil((r0 + L) / U) trips;
//  - a quantum length n (its upper bound leaving more cells than the compiler unrolls): the classical part
//    as a seed, and n >u cU + hi - r0 - 1 as an icmp template (and_i1), over the trips the bound reaches;
//  - a piece the run's end (or start) may cut (the length's known bits do not rule it out) is written byte
//    by byte, each byte under its own guard (rule 22's byte-masked merge);
//  - under a quantum predicate each guard is and_i1 with its flag;
//  - the values, all of a trip's source bytes read before its stores: a memset's fill repeated; a host
//    source's bytes from a zeroed U-byte buffer the host's own memcpy fills with exactly the run's bytes
//    of the chunk (no host byte outside the run is read); a QRAM source's bytes through the byte engine at
//    its element offset c * U / Es. A memmove within one QRAM object copies through a temporary byte QRAM
//    first (every source byte read before any store, whatever the offsets).
// The trip's records are one Uncompute scope. The reverse loop runs the scope's mirror per trip, last
// trip first; every per-trip value the mirror reads (the trip's handles, indices, guards) is saved by the
// forward trip into a host buffer of C slots (malloc'd before the loop, freed after the reverse) and
// reloaded by the reverse trip. The reverse is deferred after the destination's later accesses (F1b) and
// otherwise runs where the loop exits; the trip count and the buffer are kept in entry slots (0 and null
// where the loop did not run, so the reverse is then empty).
struct LoopSrc {
  enum Kind { Fill, Host, Qram } kind = Fill;
  Operand fill;          // Fill: the fill byte
  Value *host = nullptr; // Host: the classical source pointer
  QAccess sacc{};        // Qram: the source
};

struct RunLoop {
  unsigned scope = 0;
  BasicBlock *body = nullptr;      // the forward trip's block
  Instruction *preTerm = nullptr;  // the terminator before the loop
  PHINode *trip = nullptr;
  AllocaInst *cntSlot = nullptr, *bufSlot = nullptr;
};

// Every value of the forward trip the mirror's instructions in [from, to) read: saved by the forward trip into
// its slot of the buffer, reloaded by the reverse trip k.
void remapMirror(LoweringContext &ctx, RunLoop &L, BasicBlock *R, Instruction *firstMirror, PHINode *k,
                 Value *buf) {
  LLVMContext &C = ctx.M.getContext();
  const DataLayout &DL = ctx.M.getDataLayout();
  Type *i64 = Type::getInt64Ty(C), *i8 = Type::getInt8Ty(C);
  SmallVector<Instruction *, 8> saved;
  DenseMap<Instruction *, unsigned> slot;
  for (auto it = firstMirror->getIterator(); it != R->end(); ++it)
    for (Use &u : it->operands())
      if (auto *x = dyn_cast<Instruction>(u.get()); x && x->getParent() == L.body && !slot.count(x)) {
        if (!x->getType()->isIntegerTy() || x->getType()->getIntegerBitWidth() > 64)
          internalError("mem-qram: a rule-22 loop's per-trip value read by its reverse that is no integer", x);
        slot[x] = saved.size();
        saved.push_back(x);
      }
  if (saved.empty())
    return;
  uint64_t K = saved.size();
  // The buffer: C * K i64 slots, allocated before the forward loop.
  {
    IRBuilder<> P(L.preTerm);
    Value *cnt = P.CreateLoad(i64, L.cntSlot);
    FunctionCallee mf = ctx.M.getOrInsertFunction("malloc", PointerType::get(C, 0), i64);
    Value *b = P.CreateCall(mf, {P.CreateMul(cnt, ConstantInt::get(i64, K * 8))});
    P.CreateStore(b, L.bufSlot);
  }
  // The forward trip saves each value.
  {
    IRBuilder<> F(L.body->getTerminator());
    Value *b = F.CreateLoad(PointerType::get(C, 0), L.bufSlot);
    for (unsigned s = 0; s < K; ++s) {
      Value *at = F.CreateAdd(F.CreateMul(L.trip, ConstantInt::get(i64, K)), ConstantInt::get(i64, s));
      // A handle is stored as it is (a slot cell's form), never through a classical instruction.
      F.CreateStore(saved[s], F.CreateInBoundsGEP(i64, b, at));
    }
  }
  // The reverse trip reloads them.
  IRBuilder<> Rb(firstMirror);
  DenseMap<Instruction *, Value *> back;
  for (unsigned s = 0; s < K; ++s) {
    Value *at = Rb.CreateAdd(Rb.CreateMul(k, ConstantInt::get(i64, K)), ConstantInt::get(i64, s));
    back[saved[s]] = Rb.CreateLoad(saved[s]->getType(), Rb.CreateInBoundsGEP(i64, buf, at));
  }
  for (auto it = firstMirror->getIterator(); it != R->end(); ++it)
    for (Use &u : it->operands())
      if (auto *x = dyn_cast<Instruction>(u.get()); x && back.count(x))
        u.set(back[x]);
  (void)DL;
  (void)i8;
}

// The reverse loop at B (see above); B is left at the end of an unterminated block.
void emitRunReverse(LoweringContext &ctx, RunLoop L, IRBuilder<> &B) {
  LLVMContext &C = ctx.M.getContext();
  Type *i64 = Type::getInt64Ty(C), *ptr = PointerType::get(C, 0);
  Function *F = B.GetInsertBlock()->getParent();
  Value *cnt = B.CreateLoad(i64, L.cntSlot);
  Value *buf = B.CreateLoad(ptr, L.bufSlot);
  BasicBlock *X = B.GetInsertBlock();
  BasicBlock *R = BasicBlock::Create(C, "", F), *D = BasicBlock::Create(C, "", F);
  Value *last = B.CreateSub(cnt, ConstantInt::get(i64, 1));
  B.CreateCondBr(B.CreateICmpEQ(cnt, ConstantInt::get(i64, 0)), D, R);
  IRBuilder<> RB(R);
  PHINode *k = RB.CreatePHI(i64, 2);
  k->addIncoming(last, X);
  // A marker the mirror is emitted after (removed below).
  Instruction *mark = cast<Instruction>(RB.CreateAdd(k, ConstantInt::get(i64, 0)));
  ctx.unc().emitMirror(L.scope, RB);
  if (RB.GetInsertBlock() != R)
    internalError("mem-qram: a rule-22 loop's mirror left its block", mark);
  Instruction *first = mark->getNextNode();
  if (first) {
    remapMirror(ctx, L, R, first, k, buf);
  }
  mark->eraseFromParent();
  RB.SetInsertPoint(R);
  Value *k1 = RB.CreateSub(k, ConstantInt::get(i64, 1));
  k->addIncoming(k1, R);
  RB.CreateCondBr(RB.CreateICmpEQ(k, ConstantInt::get(i64, 0)), D, R);
  B.SetInsertPoint(D);
  // The buffer (a host block, or null) and the trip count are released: a second pass reaches nothing.
  FunctionCallee ff = ctx.M.getOrInsertFunction("free", Type::getVoidTy(C), ptr);
  B.CreateCall(ff, {buf});
  B.CreateStore(ConstantInt::get(i64, 0), L.cntSlot);
  B.CreateStore(ConstantPointerNull::get(cast<PointerType>(ptr)), L.bufSlot);
}

// True when some instruction of the original function other than MI that MI may reach accesses one of objs.
bool accessedAfter(LoweringContext &ctx, const Instruction &MI, ArrayRef<ObjectId> objs) {
  const Function &F = *MI.getFunction();
  DominatorTree DT(const_cast<Function &>(F));
  LoopInfo LI(DT);
  for (const Instruction &I : instructions(F)) {
    if (&I == &MI || !(isa<LoadInst>(I) || isa<StoreInst>(I) || isa<CallBase>(I)))
      continue;
    if (auto *II = dyn_cast<IntrinsicInst>(&I); II && II->isLifetimeStartOrEnd())
      continue;
    bool touches = false;
    for (const Use &u : I.operands())
      if (u->getType()->isPointerTy() && !isa<Function>(u.get()))
        for (ObjectId o : ctx.T.provenance(u.get(), ctx.S))
          touches |= is_contained(objs, o);
    if (touches && isPotentiallyReachable(&MI, &I, nullptr, &DT, &LI))
      return true;
  }
  return false;
}

// The forward loop of a run of `trips` chunks (a classical i64) into dst (see above). lenV/len: the length (a
// classical run-time value or a quantum rail); flag: the quantum predicate's or null. Returns the loop.
RunLoop emitRunLoop(LoweringContext &ctx, MemIntrinsic &MI, const QAccess &dst, LoopSrc &src, const Value *lenV,
                    Operand len, uint64_t cover) {
  const DataLayout &DL = ctx.M.getDataLayout();
  LLVMContext &C = ctx.M.getContext();
  IRBuilder<> &B = ctx.B();
  Type *i64 = Type::getInt64Ty(C), *i8 = Type::getInt8Ty(C);
  const QramObj &q = *dst.q;
  uint64_t E = q.elemBytes;
  uint64_t Es = src.kind == LoopSrc::Qram ? src.sacc.q->elemBytes : E;
  uint64_t U = std::lcm(E, Es);
  int64_t e0 = floorDiv(dst.a.off, int64_t(E));
  int64_t r0 = dst.a.off - e0 * int64_t(E);
  // The run's end may cut a piece only at a multiple of 2^g chunk-relative.
  unsigned tzL = computeKnownBits(lenV, DL).countMinTrailingZeros();
  unsigned g = std::min<unsigned>({tzL, unsigned(llvm::countr_zero(U)), r0 ? unsigned(llvm::countr_zero(uint64_t(r0))) : 64u});
  auto mayCut = [&](uint64_t lo, uint64_t hi) {
    if (lo < uint64_t(r0) && uint64_t(r0) < hi)
      return true;
    if (g >= 63)
      return false;
    uint64_t m = ((lo >> g) + 1) << g;
    return m < hi;
  };
  // The (sub-)pieces of one chunk, chunk-relative.
  struct CP { Piece p; uint64_t lo, hi; unsigned nb; };
  SmallVector<CP, 8> cps;
  for (const Piece &p : piecesIn(DL, q, e0 * int64_t(E), U, MI)) {
    unsigned nb = pieceBits(DL, p);
    if (!nb)
      continue;
    uint64_t lo = p.valLo, hi = p.valLo + (p.cellHi - p.cellLo);
    if (!mayCut(lo, hi)) {
      cps.push_back({p, lo, hi, nb});
      continue;
    }
    for (uint64_t kk = 0; kk < p.cellHi - p.cellLo; ++kk) {
      Piece sub = p;
      sub.cellLo = p.cellLo + kk;
      sub.cellHi = sub.cellLo + 1;
      sub.valLo = p.valLo + kk;
      unsigned sb = pieceBits(DL, sub);
      if (sb)
        cps.push_back({sub, sub.valLo, sub.valLo + 1, sb});
    }
  }
  Function &F = ctx.out();
  IRBuilder<> EB(&F.getEntryBlock(), F.getEntryBlock().getFirstInsertionPt());
  RunLoop L;
  L.cntSlot = EB.CreateAlloca(i64);
  L.bufSlot = EB.CreateAlloca(PointerType::get(C, 0));
  EB.CreateStore(ConstantInt::get(i64, 0), L.cntSlot);
  EB.CreateStore(ConstantPointerNull::get(PointerType::get(C, 0)), L.bufSlot);
  AllocaInst *chunkBuf = src.kind == LoopSrc::Host ? EB.CreateAlloca(ArrayType::get(i8, U)) : nullptr;

  // Pre-loop: the trip count and a memset's shared fill per piece width.
  Value *L64 = len.handle ? nullptr : B.CreateZExtOrTrunc(len.v, i64);
  Value *cnt;
  if (L64)
    cnt = B.CreateUDiv(B.CreateAdd(L64, ConstantInt::get(i64, uint64_t(r0) + U - 1)), ConstantInt::get(i64, U));
  else
    cnt = ConstantInt::get(i64, (uint64_t(r0) + cover + U - 1) / U);
  B.CreateStore(cnt, L.cntSlot);
  std::map<unsigned, Operand> fills;
  if (src.kind == LoopSrc::Fill)
    for (const CP &cp : cps) {
      if (fills.count(cp.nb))
        continue;
      unsigned W = unsigned(8 * (cp.hi - cp.lo));
      Operand x = intCast(ctx, "zext", 8, W, src.fill);
      if (W > 8)
        x = intOp(ctx, "mul", W, x, APInt::getSplat(W, APInt(8, 1)));
      x = intCast(ctx, "trunc", W, cp.nb, x);
      if (!x.handle)
        x = Operand{seedOf(ctx, RailType{Kind::Int, cp.nb}, x.v), true};   // one shared basis-state seed (rule 22)
      fills[cp.nb] = x;
    }
  BasicBlock *pre = B.GetInsertBlock();
  BasicBlock *body = BasicBlock::Create(C, "", &F), *done = BasicBlock::Create(C, "", &F);
  L.preTerm = B.CreateCondBr(B.CreateICmpEQ(cnt, ConstantInt::get(i64, 0)), done, body);
  B.SetInsertPoint(body);
  PHINode *c = B.CreatePHI(i64, 2);
  c->addIncoming(ConstantInt::get(i64, 0), pre);
  L.trip = c;
  L.body = body;
  L.scope = ctx.unc().openScope();
  Value *cU = B.CreateMul(c, ConstantInt::get(i64, U));
  Value *extraDst = U == E ? static_cast<Value *>(c) : B.CreateMul(c, ConstantInt::get(i64, U / E));
  // Values, every source byte of the trip read first.
  SmallVector<Operand, 8> vals;
  if (src.kind == LoopSrc::Host) {
    // The run's bytes of this chunk, [max(0, cU - r0), min(Lb, cU + U - r0)) of the source, into the zeroed
    // chunk buffer at their chunk-relative place (Lb: L, or a quantum length's bound).
    Value *Lb = L64 ? L64 : ConstantInt::get(i64, cover);
    Value *start = B.CreateSub(cU, ConstantInt::get(i64, r0));   // run byte of chunk byte 0 (may be < 0)
    Value *k0 = B.CreateSelect(B.CreateICmpSLT(start, ConstantInt::get(i64, 0)), ConstantInt::get(i64, 0), start);
    Value *endc = B.CreateAdd(start, ConstantInt::get(i64, U));
    Value *k1 = B.CreateSelect(B.CreateICmpULT(Lb, endc), Lb, endc);
    B.CreateMemSet(chunkBuf, ConstantInt::get(i8, 0), U, MaybeAlign(1));
    Value *n = B.CreateSelect(B.CreateICmpUGT(k1, k0), B.CreateSub(k1, k0), ConstantInt::get(i64, 0));
    B.CreateMemCpy(B.CreateInBoundsGEP(i8, chunkBuf, B.CreateSub(k0, start)), MaybeAlign(1),
                   B.CreateInBoundsGEP(i8, src.host, k0), MaybeAlign(1), n);
  }
  for (const CP &cp : cps) {
    unsigned W = unsigned(8 * (cp.hi - cp.lo));
    switch (src.kind) {
    case LoopSrc::Fill:
      vals.push_back(fills[cp.nb]);
      break;
    case LoopSrc::Host: {
      Value *at = cp.lo ? B.CreateConstInBoundsGEP1_64(i8, chunkBuf, cp.lo) : static_cast<Value *>(chunkBuf);
      Value *v = B.CreateAlignedLoad(IntegerType::get(C, W), at, Align(1));
      vals.push_back(intCast(ctx, "trunc", W, cp.nb, Operand{v, false}));
      break;
    }
    case LoopSrc::Qram: {
      Value *extraSrc = U == Es ? static_cast<Value *>(c) : B.CreateMul(c, ConstantInt::get(i64, U / Es));
      Operand x = readBytes(ctx, src.sacc, src.sacc.a.off - r0 + int64_t(cp.lo), cp.hi - cp.lo, MI, extraSrc);
      vals.push_back(intCast(ctx, "trunc", W, cp.nb, x));
      break;
    }
    }
  }
  // Guards and stores.
  Value *flag = ctx.currentFlag();
  unsigned lw = lenV->getType()->getIntegerBitWidth();
  for (size_t i = 0; i < cps.size(); ++i) {
    const CP &cp = cps[i];
    Value *lo = B.CreateAdd(cU, ConstantInt::get(i64, cp.lo)), *hi = B.CreateAdd(cU, ConstantInt::get(i64, cp.hi));
    Value *cond = B.CreateICmpUGE(lo, ConstantInt::get(i64, r0));
    if (L64)
      cond = B.CreateAnd(cond, B.CreateICmpULE(hi, B.CreateAdd(L64, ConstantInt::get(i64, r0))));
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}}, {cond});
    ctx.unc().recordSeed(seed);
    Value *gd = seed;
    auto andI1 = [&](Value *x, Value *y) {
      abi::TemplateSpec a;
      a.op = "and";
      a.w = RailType{Kind::Int, 1};
      return ctx.emitTemplate(a, {Operand{x, true}, Operand{y, true}});
    };
    if (len.handle) {
      // n >u (cU + hi - r0 - 1), the right side clamped to the length's width (above it: never).
      Value *rhs = B.CreateSub(hi, ConstantInt::get(i64, r0 + 1));
      if (lw < 64) {
        Value *mx = ConstantInt::get(i64, (uint64_t(1) << lw) - 1);
        rhs = B.CreateTrunc(B.CreateSelect(B.CreateICmpUGT(rhs, mx), mx, rhs), IntegerType::get(C, lw));
      }
      abi::TemplateSpec cmp;
      cmp.op = "icmp";
      cmp.pred = "ugt";
      cmp.w = RailType{Kind::Int, lw};
      cmp.shape = "hl";
      gd = andI1(gd, ctx.emitTemplate(cmp, {len, Operand{rhs, false}}));
    }
    if (flag)
      gd = andI1(flag, gd);
    writePiece(ctx, dst, cp.p, vals[i], cp.nb, gd, MI, extraDst);
  }
  if (B.GetInsertBlock() != body)
    internalError("mem-qram: a rule-22 loop trip that is not one block", &MI);
  ctx.unc().closeScope(L.scope);
  Value *c1 = B.CreateAdd(c, ConstantInt::get(i64, 1), "", /*HasNUW=*/true, /*HasNSW=*/true);
  c->addIncoming(c1, body);
  B.CreateCondBr(B.CreateICmpEQ(c1, cnt), done, body);
  // The loop's exit block continues in one fresh block (Uncompute's immediate placement of a deferred item
  // splits there).
  BasicBlock *cont = BasicBlock::Create(C, "", &F);
  BranchInst::Create(cont, done);
  B.SetInsertPoint(cont);
  (void)i8;
  return L;
}

// The reverse of the loops Ls (last first), then the mirror of `extra` (a scope of records made before them,
// or none): deferred after the destination's later accesses when there are any, else right here. One item for
// all of them: a memmove's second pass writes the cells its first pass read.
void finishRunLoops(LoweringContext &ctx, SmallVector<RunLoop, 2> Ls, std::optional<unsigned> extra, bool later) {
  IRBuilder<> &B = ctx.B();
  LoweringContext *cx = &ctx;
  auto emit = [cx, Ls, extra](IRBuilder<> &RB) {
    for (size_t i = Ls.size(); i-- > 0;)
      emitRunReverse(*cx, Ls[i], RB);
    if (extra)
      cx->unc().emitMirror(*extra, RB);
  };
  if (!later) {
    emit(B);
    return;
  }
  SmallVector<unsigned, 3> scopes;
  if (extra)
    scopes.push_back(*extra);
  for (const RunLoop &L : Ls)
    scopes.push_back(L.scope);
  DenseSet<const Value *> owned;
  for (unsigned sc : scopes)
    for (const Record &r : ctx.unc().scopeRecords(sc))
      if (!r.forward->getType()->isVoidTy())
        owned.insert(r.forward);
  std::vector<RailId> reads;
  for (unsigned sc : scopes)
    for (const Record &r : ctx.unc().scopeRecords(sc))
      for (const Operand &o : r.ops)
        if (o.handle && !owned.count(o.v))
          if (RailId x = ctx.unc().idOf(o.v); !is_contained(reads, x))
            reads.push_back(x);
  ctx.unc().recordDeferred(scopes, {}, emit, reads, {}, /*busUseFollows=*/true);
}

// The source of a memory intrinsic into a QRAM (rule 22): a memset's fill byte, host memory (every object of
// the source classical), or one QRAM at its address.
LoopSrc intrinsicSource(LoweringContext &ctx, MemIntrinsic &MI) {
  LoopSrc src;
  if (auto *MS = dyn_cast<MemSetInst>(&MI)) {
    src.kind = LoopSrc::Fill;
    src.fill = ctx.operand(MS->getValue());
    return src;
  }
  const Value *s = cast<MemTransferInst>(MI).getSource();
  if (ctx.T.isFatPointer(s, ctx.S))
    unimplemented("mem-qram: a memcpy/memmove into a QRAM from a quantum pointer (rule 21)", &MI);
  ArrayRef<ObjectId> so = ctx.T.provenance(s, ctx.S);
  if (llvm::all_of(so, [&](ObjectId x) { return ctx.T.classOf(x) == ObjClass::Classical; })) {
    src.kind = LoopSrc::Host;
    Operand sp = ctx.operand(s);
    if (sp.handle)
      internalError("mem-qram: a classical memcpy source bound to a rail", &MI);
    src.host = sp.v;
    return src;
  }
  if (so.size() == 1 && ctx.T.classOf(so.front()) == ObjClass::Qram) {
    src.kind = LoopSrc::Qram;
    src.sacc = qramAccess(ctx, s, MI);
    return src;
  }
  // Owner 2026-11-03 (no fences): a slot-array source at another layout, or a source over several objects, is
  // read as host memory at the source pointer (rule 22's host form); the sweep judges it.
  src.kind = LoopSrc::Host;
  src.host = ctx.operand(s).v;
  return src;
}

void lowerQramIntrinsicLoop(LoweringContext &ctx, MemIntrinsic &MI, const QAccess &acc, const Value *lenV,
                            Operand len, uint64_t cover) {
  LoopSrc src = intrinsicSource(ctx, MI);
  // A global QRAM's stores are never popped (rule 20, 160): the trip's other records are undone where the loop
  // exits. Any other destination's stores are popped after its later accesses.
  bool later = !isa<GlobalVariable>(acc.q->site) && accessedAfter(ctx, MI, ctx.T.provenance(MI.getDest(), ctx.S));
  if (src.kind == LoopSrc::Qram && isa<MemMoveInst>(&MI) && src.sacc.q == acc.q) {
    // A memmove within one object: through a temporary byte QRAM, every source byte read first.
    LLVMContext &C = ctx.M.getContext();
    QramState &st = qramStates()[&ctx.out()];
    QramObj tq = layoutOf(Type::getInt8Ty(C), ctx.M.getDataLayout(), &MI);
    tq.site = &MI;
    // One byte cell per byte of the run: the length (a quantum one: its bound).
    uint64_t maxRun = len.handle ? cover : upperBound(lenV, ctx.M.getDataLayout(), MI);
    Value *n0 = len.handle ? cellCountArg(ctx, tq, cover)
                           : cellCountArg(ctx, tq, ctx.B().CreateZExtOrTrunc(len.v, Type::getInt64Ty(C)), maxRun);
    abi::CoreSpec spec{abi::Core::QramAlloc, tq.cols[0].w};
    unsigned tscope = ctx.unc().openScope();   // the temporary is the item's own
    CallInst *bus = ctx.emitCore(spec, {n0});
    ctx.unc().recordCore(bus, spec, {Operand{n0, false}}, 0);
    ctx.unc().closeScope(tscope);
    tq.buses[&MI] = {bus};
    QramObj &tmp = st.objs[&MI] = std::move(tq);
    Addr ta;
    ta.root = &MI;
    ta.ok = true;
    QAccess tacc{&tmp, ta};
    // Pass 1: source -> temporary; pass 2: temporary -> destination. One deferred item reverses pass 2, then
    // pass 1, then releases the temporary.
    RunLoop L1 = emitRunLoop(ctx, MI, tacc, src, lenV, len, cover);
    LoopSrc s2;
    s2.kind = LoopSrc::Qram;
    s2.sacc = tacc;   // run byte k is the temporary's byte k
    RunLoop L2 = emitRunLoop(ctx, MI, acc, s2, lenV, len, cover);
    finishRunLoops(ctx, {L1, L2}, tscope, later);
    return;
  }
  RunLoop L = emitRunLoop(ctx, MI, acc, src, lenV, len, cover);
  finishRunLoops(ctx, {L}, std::nullopt, later);
}

// Rule 22 over a QRAM destination, every other form, through the byte engine: the cells the intrinsic
// may touch (a classical constant length: exactly; otherwise up to the length's upper bound, LLVM's range
// facts, and never past the object), each touched cell piece stored its bytes of the new value:
//  - a quantum length n guards the piece of bytes [s, e) of the run by n >= e (icmp ugt n, e - 1); a
//    run-time classical length by the same test as a seed flag (rule 7; a classical term inside a
//    quantum store's control, rule 8). Where the length may end inside a cell piece (its known bits do
//    not rule it out), the piece is written byte by byte, each byte under its own guard: rule 22's
//    byte-masked merge of old and new under n > sj;
//  - under a quantum predicate each guard is and_i1 with the predicate's flag (rule 8, as data);
//  - the new bytes: a memset's fill byte repeated (a quantum fill: zext and mul_hl of the byte rail by
//    0x0101..); a memcpy/memmove's source bytes, every one read before any store: a QRAM source through
//    the engine's reads (at its quantum index too), a host source by host loads (a run-time length: the
//    host's own memcpy into a zeroed buffer of the bound's size first, so no host byte past the length is
//    read);
//  - a quantum destination offset is the engine's index (the quantum cell index plus the element).
void lowerQramIntrinsicBytes(LoweringContext &ctx, MemIntrinsic &MI, const QAccess &acc, const Value *lenV,
                             Operand len) {
  const DataLayout &DL = ctx.M.getDataLayout();
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  Type *i64 = Type::getInt64Ty(C), *i8 = Type::getInt8Ty(C);
  auto *cl = len.handle ? nullptr : dyn_cast<ConstantInt>(len.v);
  uint64_t cover;
  if (cl) {
    cover = cl->getZExtValue();
  } else {
    cover = upperBound(lenV, DL, MI);
    auto it = acc.q->bytes.find(acc.a.root);
    if (it != acc.q->bytes.end()) {
      uint64_t cap = it->second;
      if (acc.a.terms.empty() && acc.a.off >= 0)
        cap = cap > uint64_t(acc.a.off) ? cap - uint64_t(acc.a.off) : 0;
      cover = std::min(cover, cap);
    }
    // A run-time classical length is rule 22's classical loop over the cells; a quantum one whose bound leaves
    // more cells than the compiler unrolls is the same loop over the cells the bound reaches.
    if (!len.handle || cover > (uint64_t(1) << 20))
      return lowerQramIntrinsicLoop(ctx, MI, acc, lenV, len, cover);
  }
  if (cover == 0)
    return;
  SmallVector<Piece, 8> pieces = piecesIn(DL, *acc.q, acc.a.off, cover, MI);
  // The new bits of each piece (pieceBits wide), every source byte read first.
  SmallVector<Operand, 8> vals;
  auto pieceBytes = [](const Piece &p) { return p.cellHi - p.cellLo; };
  if (auto *MS = dyn_cast<MemSetInst>(&MI)) {
    Operand fill = ctx.operand(MS->getValue());
    std::map<unsigned, Operand> shared;   // per piece width: one splat (rule 22's shared seed / the fill rail)
    for (const Piece &p : pieces) {
      unsigned nb = pieceBits(DL, p);
      if (!nb) {
        vals.push_back(Operand{});
        continue;
      }
      auto f = shared.find(nb);
      if (f != shared.end()) {
        vals.push_back(f->second);
        continue;
      }
      unsigned W = unsigned(8 * pieceBytes(p));
      Operand x = intCast(ctx, "zext", 8, W, fill);
      if (W > 8)
        x = intOp(ctx, "mul", W, x, APInt::getSplat(W, APInt(8, 1)));
      x = intCast(ctx, "trunc", W, nb, x);
      if (!x.handle)
        x = Operand{x.v, false};
      shared[nb] = x;
      vals.push_back(x);
    }
  } else {
    LoopSrc ls = intrinsicSource(ctx, MI);
    if (ls.kind == LoopSrc::Host) {
      Value *from = ls.host;
      if (!cl && !len.handle) {
        // The host's own copy of exactly the length's bytes into a zeroed buffer of the bound's size.
        Function &F = ctx.out();
        IRBuilder<> EB(&F.getEntryBlock(), F.getEntryBlock().getFirstInsertionPt());
        AllocaInst *buf = EB.CreateAlloca(ArrayType::get(i8, cover));
        B.CreateMemSet(buf, ConstantInt::get(i8, 0), cover, MaybeAlign(1));
        B.CreateMemCpy(buf, MaybeAlign(1), ls.host, MaybeAlign(1), B.CreateZExtOrTrunc(len.v, i64));
        from = buf;
      }
      for (const Piece &p : pieces) {
        unsigned nb = pieceBits(DL, p);
        if (!nb) {
          vals.push_back(Operand{});
          continue;
        }
        Type *ty = IntegerType::get(C, unsigned(8 * pieceBytes(p)));
        Value *at = p.valLo ? B.CreateConstGEP1_64(i8, from, p.valLo) : from;
        Value *v = B.CreateAlignedLoad(ty, at, Align(1));
        vals.push_back(intCast(ctx, "trunc", unsigned(8 * pieceBytes(p)), nb, Operand{v, false}));
      }
    } else {
      const QAccess &sacc = ls.sacc;
      for (const Piece &p : pieces) {
        unsigned nb = pieceBits(DL, p);
        if (!nb) {
          vals.push_back(Operand{});
          continue;
        }
        Operand x = readBytes(ctx, sacc, sacc.a.off + int64_t(p.valLo), pieceBytes(p), MI);
        vals.push_back(intCast(ctx, "trunc", unsigned(8 * pieceBytes(p)), nb, x));
      }
    }
  }
  // Guards and stores.
  Value *flag = ctx.currentFlag();
  unsigned lw = lenV->getType()->getIntegerBitWidth();
  unsigned tz = cl ? 64 : computeKnownBits(lenV, DL).countMinTrailingZeros();
  auto guardFor = [&](uint64_t end) -> std::optional<Value *> {   // n >= end; nullopt: never
    if (cl)
      return end <= cover ? std::optional<Value *>(flag) : std::nullopt;
    Value *g;
    if (len.handle) {
      if (lw < 64 && (end - 1) >> lw)
        return std::nullopt;
      abi::TemplateSpec cmp;
      cmp.op = "icmp";
      cmp.pred = "ugt";
      cmp.w = RailType{Kind::Int, lw};
      cmp.shape = "hl";
      g = ctx.emitTemplate(cmp, {len, Operand{ConstantInt::get(IntegerType::get(C, lw), end - 1), false}});
    } else {
      Value *c = B.CreateICmpUGE(B.CreateZExtOrTrunc(len.v, i64), ConstantInt::get(i64, end));
      CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}}, {c});
      ctx.unc().recordSeed(seed);
      g = seed;
    }
    if (flag) {
      abi::TemplateSpec a;
      a.op = "and";
      a.w = RailType{Kind::Int, 1};
      g = ctx.emitTemplate(a, {Operand{flag, true}, Operand{g, true}});
    }
    return g;
  };
  for (size_t i = 0; i < pieces.size(); ++i) {
    const Piece &p = pieces[i];
    unsigned nb = pieceBits(DL, p);
    if (!nb)
      continue;
    uint64_t lo = p.valLo, hi = p.valLo + pieceBytes(p);
    // May the length end strictly inside (lo, hi)? Only at a multiple of 2^tz.
    bool cut = !cl && tz < 64 && ((lo >> tz) + 1) << tz < hi;
    if (!cut) {
      if (std::optional<Value *> g = guardFor(hi))
        writePiece(ctx, acc, p, vals[i], nb, *g, MI);
      continue;
    }
    for (uint64_t k = 0; k < pieceBytes(p); ++k) {
      unsigned b0 = unsigned(8 * k);
      if (b0 >= nb)
        break;
      unsigned bn = std::min(8u, nb - b0);
      Piece sub = p;
      sub.cellLo = p.cellLo + k;
      sub.cellHi = sub.cellLo + 1;
      sub.valLo = p.valLo + k;
      if (std::optional<Value *> g = guardFor(sub.valLo + 1))
        writePiece(ctx, acc, sub, bitsOf(ctx, vals[i], nb, b0, bn), bn, *g, MI);
    }
  }
}

void lowerQramIntrinsic(LoweringContext &ctx, MemIntrinsic &MI, ObjectId o) {
  (void)o;
  QAccess acc = qramAccess(ctx, MI.getDest(), MI);
  const Value *lenV = MI.getLength();
  if (auto *z = dyn_cast<ZExtInst>(lenV); z && ctx.T.isQuantum(z->getOperand(0), ctx.S))
    lenV = z->getOperand(0);
  Operand len = ctx.operand(lenV);
  if (auto *cl = len.handle ? nullptr : dyn_cast<ConstantInt>(len.v);
      cl && !quantumTerm(ctx, acc.a, MI) && lowerQramIntrinsicCells(ctx, MI, acc, cl->getZExtValue()))
    return;
  lowerQramIntrinsicBytes(ctx, MI, acc, lenV, len);
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

QIndex fatIndex(LoweringContext &ctx, const QramObj &q, Operand idx) {
  if (idx.handle)
    return {idx.v, true};
  if (q.wide)
    return classicalIndex(ctx, q, ctx.B().CreateSExtOrTrunc(idx.v, Type::getInt64Ty(ctx.M.getContext())), 0);
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

Value *forwardDeferredStores(LoweringContext &ctx, const Value *root, Operand idx, unsigned idxBits, Value *loaded,
                             const Instruction &at);

Value *qramLoadAt(LoweringContext &ctx, const Value *root, Operand idx, Type *ty, const Instruction &at,
                  unsigned idxBits) {
  QramObj &q = qramObj(ctx, root, at);
  const Column &c = firstColumn(ctx, q, ty, at);
  Value *h = emitLoad(ctx, busOf(q, root, &c, at), c, fatIndex(ctx, q, idx));
  if (isFormalQram(ctx, root))
    h = forwardDeferredStores(ctx, root, idx, idxBits, h, at);
  return h;
}

std::pair<Value *, Value *> qramLoadPtrAt(LoweringContext &ctx, const Value *root, Operand idx,
                                          const Instruction &at) {
  QramObj &q = qramObj(ctx, root, at);
  const Column *c = q.at(0);
  if (!c || c->ptrPart != 1)
    unimplemented("mem-qram: a pointer load through a fat pointer of a QRAM whose first cell is not a pointer", &at);
  QIndex ix = fatIndex(ctx, q, idx);
  Value *tag = emitLoad(ctx, busOf(q, root, c, at), c[0], ix);
  Value *i = emitLoad(ctx, busOf(q, root, c + 1, at), c[1], ix);
  return {tag, i};
}

void qramStoreAt(LoweringContext &ctx, const Value *root, Operand idx, Type *ty, Value *v, Value *flag,
                 const Instruction &at) {
  QramObj &q = qramObj(ctx, root, at);
  const Column &c = firstColumn(ctx, q, ty, at);
  emitStore(ctx, busOf(q, root, &c, at), c, fatIndex(ctx, q, idx), v, flag, at);
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

// Rule 22, per object of a quantum source pointer (90): the length's upper bound in bytes on the paths that
// select root r. A classical length: itself. A quantum length: when the source and the length are selects on
// one condition (the paths that select an arm's root are those that select its length) and r is an arm, the
// largest bound of the arms that are r; otherwise the length's bound at the intrinsic, which bounds it on every
// path, those that select r included. fatptr caps it by r's object extent (rule 20: an in-domain copy never
// reads past its object; an object of no static extent has the indices' range as its extent).
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
  if (ss && ls && ss->getCondition() == ls->getCondition()) {
    std::optional<uint64_t> b;
    for (auto [p, l] : {std::pair{ss->getTrueValue(), ls->getTrueValue()},
                        std::pair{ss->getFalseValue(), ls->getFalseValue()}})
      if (p->stripPointerCasts() == r)
        b = std::max(b.value_or(0), upperBound(l, DL, MI));
    if (b)
      return *b;
  }
  return upperBound(lenV, DL, MI);
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
  if (!a.ok || ctx.T.objectOf(a.root, ctx.S, a.off) != o)
    unimplemented("mem-qram: a memory intrinsic into a slot object whose destination is not its object plus GEP "
                  "offsets",
                  &MI);
  ObjInfo &info = objInfo(ctx, st, a.root, o, MI);
  Type *cellTy = cellType(ctx, st, info, o);
  uint64_t cb = info.cellBytes;
  // mem-slots' cells (slotLayout, cq-dd3q): a local a memory intrinsic writes whose narrowest access is narrower
  // than its integer element already has byte cells of that width there (-O1's punned alloca i32 of 90's
  // unsigned char d[4]; mem-slots splits each wider classical store per cell). A bit view (63) or a record
  // (one cell per field of its own type) is not one run of cells of one type.
  if (info.view || info.record || !cellTy)
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
  bool rtLen = false;   // a run-time classical length: rule 22's cells up to its bound, each under a seed guard
  if (!len.handle && !isa<ConstantInt>(len.v)) {
    rtLen = true;
    if (!wholeCells(lenV, cb, DL))
      unimplemented("mem-qram: a run-time-length memory intrinsic into a slot array over a part of a cell (a bit "
                    "view, 63)",
                    &MI);
    n = (upperBound(lenV, DL, MI) + cb - 1) / cb;
    if (std::optional<uint64_t> ob = staticObjectBytes(info, DL); ob && a.terms.empty() && a.off >= 0)
      n = std::min<uint64_t>(n, *ob > uint64_t(a.off) ? (*ob - uint64_t(a.off)) / cb : 0);
    if (n > (uint64_t(1) << 20))
      unimplemented("awaiting owner ruling: SPEC_ISSUES rule 22 unrolled over a length whose upper bound leaves "
                    "more than 2^20 bytes (no range fact bounds it and the destination's extent is not static)",
                    &MI);
  } else if (!len.handle) {
    auto *cl = cast<ConstantInt>(len.v);
    if (cl->getZExtValue() % cb)
      unimplemented("mem-qram: a memory intrinsic into a slot array over a part of a cell (a bit view, 63)", &MI);
    n = cl->getZExtValue() / cb;
  } else {
    if (!wholeCells(lenV, cb, DL))
      unimplemented("mem-qram: a quantum-length memory intrinsic into a slot array over a part of a cell (a bit "
                    "view, 63)",
                    &MI);
    n = (upperBound(lenV, DL, MI) + cb - 1) / cb;
    // Rule 22: only cells some execution can touch, none past the destination object.
    if (std::optional<uint64_t> ob = staticObjectBytes(info, DL); ob && a.terms.empty() && a.off >= 0)
      n = std::min<uint64_t>(n, *ob > uint64_t(a.off) ? (*ob - uint64_t(a.off)) / cb : 0);
    if (n > (uint64_t(1) << 20))
      unimplemented("awaiting owner ruling: SPEC_ISSUES rule 22 unrolled over a quantum length whose upper bound "
                    "leaves more than 2^20 cells (no range fact bounds it and the destination's extent is not "
                    "static)",
                    &MI);
  }
  if (n == 0)
    return;
  // The values, every source cell read first.
  SmallVector<Operand, 8> vals;
  if (auto *MS = dyn_cast<MemSetInst>(&MI)) {
    Operand fill = ctx.operand(MS->getValue());
    if (fill.handle) {
      // Rule 22: the quantum fill byte repeated over the cell (zext and mul_hl by 0x0101..), one rail every
      // cell takes as a basis copy; a _Bool cell is the byte's low bit.
      unsigned W = unsigned(DL.getTypeStoreSize(cellTy).getFixedValue() * 8);
      Operand x = intCast(ctx, "zext", 8, W, fill);
      if (W > 8)
        x = intOp(ctx, "mul", W, x, APInt::getSplat(W, APInt(8, 1)));
      x = fromInt(ctx, intCast(ctx, "trunc", W, info.boolCells ? 1 : valueBits(cellTy), x),
                  info.boolCells ? Type::getInt1Ty(C) : cellTy);
      vals.assign(n, x);
    } else {
      Value *v = splatCell(ctx, fill.v, cellTy);
      vals.assign(n, Operand{v, false});
    }
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
      Value *from = sp.v;
      if (rtLen) {
        // The host's own copy of exactly the length's bytes into a zeroed buffer of the bound's size: no
        // host byte past the length is read (rule 22).
        Function &F = ctx.out();
        IRBuilder<> EB(&F.getEntryBlock(), F.getEntryBlock().getFirstInsertionPt());
        AllocaInst *buf = EB.CreateAlloca(ArrayType::get(Type::getInt8Ty(C), n * cb));
        B.CreateMemSet(buf, ConstantInt::get(Type::getInt8Ty(C), 0), n * cb, MaybeAlign(1));
        B.CreateMemCpy(buf, MaybeAlign(1), sp.v, MaybeAlign(1), B.CreateZExtOrTrunc(len.v, Type::getInt64Ty(C)));
        from = buf;
      }
      for (uint64_t j = 0; j < n; ++j) {
        Value *p = j ? B.CreateInBoundsGEP(Type::getInt8Ty(C), from, ConstantInt::get(Type::getInt64Ty(C), j * cb))
                     : from;
        vals.push_back(Operand{rtLen ? B.CreateAlignedLoad(cellTy, p, Align(1)) : B.CreateLoad(cellTy, p), false});
      }
    } else if (so.size() == 1 && ctx.T.classOf(so.front()) == ObjClass::Qram) {
      // A QRAM source: each cell's bytes by the byte engine's reads (rule 20, one access per touched cell).
      QAccess sacc = qramAccess(ctx, src, MI);
      for (uint64_t j = 0; j < n; ++j) {
        Operand x = readBytes(ctx, sacc, sacc.a.off + int64_t(j * cb), cb, MI);
        x = intCast(ctx, "trunc", unsigned(cb * 8), valueBits(cellTy), x);
        vals.push_back(fromInt(ctx, x, cellTy));
      }
    } else {
      unimplemented("mem-qram: a memcpy/memmove into a slot array from several objects (rule 21's per-object "
                    "source cells)",
                    &MI);
    }
    }
  }
  // The guards of a quantum length, or of a run-time classical one (a seed flag, rules 7, 8).
  SmallVector<Value *, 8> guards;
  if (rtLen) {
    Type *i64 = Type::getInt64Ty(C);
    for (uint64_t j = 0; j < n; ++j) {
      Value *c = B.CreateICmpUGE(B.CreateZExtOrTrunc(len.v, i64), ConstantInt::get(i64, (j + 1) * cb));
      CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}}, {c});
      ctx.unc().recordSeed(seed);
      guards.push_back(seed);
    }
  }
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
  // Under a quantum predicate every cell's guard includes the predicate's flag (M6: the guards are the
  // caller's; rules 8, 9: a conjunction used as data is and_i1).
  if (Value *flag = ctx.currentFlag()) {
    guards.resize(n, nullptr);
    for (Value *&g : guards) {
      if (!g) {
        g = flag;
        continue;
      }
      abi::TemplateSpec a;
      a.op = "and";
      a.w = RailType{Kind::Int, 1};
      g = ctx.emitTemplate(a, {Operand{flag, true}, Operand{g, true}});
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
    return lowerSlotMemset(ctx, cast<MemSetInst>(MI), objs.front());
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
  if (Addr r = decompose(ld.getPointerOperand(), ctx.M.getDataLayout(), &ctx); r.ok && isFormalQram(ctx, r.root))
    return fatptr::lowerLoad(ctx, ld);   // through a triple formal: its idx plus the offset (P1)
  if (lowerFormalWalkLoad(ctx, ld))
    return;   // through a classical walk of a triple formal's object (P1, rule 21)
  if (formalFatWalk(ctx, ld.getPointerOperand()))
    return fatptr::lowerLoad(ctx, ld);   // through a fat pointer over a triple formal's object (rule 21)
  QAccess acc = qramAccess(ctx, ld.getPointerOperand(), ld);
  if (ld.getType()->isPointerTy() && !isCodeAddress(&ld)) {
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
  if (hasPointerLeaf(ld.getType()) && !isCodeAddress(&ld))
    unimplemented("mem-qram: a QRAM load of an aggregate holding a pointer (rules 21, 26: its fat fields)", &ld);
  const Column *col = isAggregate(ld.getType()) ? nullptr : exactCell(ctx, *acc.q, acc.a, ld.getType());
  if (!col)
    return loadThroughBytes(ctx, acc, ld);   // a bit view or a composite: one access per touched cell
  QIndex idx = cellIndex(ctx, *acc.q, acc.a, ld);
  ctx.bind(&ld, emitLoad(ctx, busOf(*acc.q, acc.a.root, col, ld), *col, idx));
}

// Rule 20, §1.3: ONE cqrt_qram_store_<W>[_hl][_controlled]([c,] a, idx | j, v), v always a handle (a
// classical value is first a seed, rule 7), under the current quantum predicate's flag when there is
// one. It is recorded on the bus: the bus's item pops its stores last-in-first-out (a global bus is an
// output and is never popped). A classical value over several whole cells is one store per cell.
void lowerQramStore(LoweringContext &ctx, StoreInst &st) {
  if (Addr r = decompose(st.getPointerOperand(), ctx.M.getDataLayout(), &ctx); r.ok && isFormalQram(ctx, r.root))
    return fatptr::lowerStore(ctx, st);   // through a triple formal: the deferred copy-out (P1, M2b)
  if (lowerFormalWalkStore(ctx, st))
    return;   // through a classical walk of a triple formal's object: the deferred copy-out (P1, M2b)
  if (formalFatWalk(ctx, st.getPointerOperand()))
    return fatptr::lowerStore(ctx, st);   // through a fat pointer over a triple formal's object (rule 21)
  Value *val = st.getValueOperand();
  QAccess acc = qramAccess(ctx, st.getPointerOperand(), st);
  Value *flag = ctx.currentFlag();
  if (val->getType()->isPointerTy() && !isCodeAddress(val)) {
    // A pointer stored into a QRAM of pointers (rule 21, 88): its fat (tag, idx) into the two halves,
    // classical fields as seeds (rule 7).
    const Column *col = exactCell(ctx, *acc.q, acc.a, val->getType());
    if (!col)
      unimplemented("mem-qram: a pointer stored into a QRAM cell that is not a pointer (a bit view, 63)", &st);
    QIndex idx = cellIndex(ctx, *acc.q, acc.a, st);
    auto [tag, ix] = fatptr::storedFields(ctx, val);
    Value *tv = tag.handle ? tag.v : seedOf(ctx, col[0].w, tag.v);
    Value *iv = ix.handle ? ix.v : seedOf(ctx, col[1].w, ix.v);
    emitStore(ctx, busOf(*acc.q, acc.a.root, col, st), col[0], idx, tv, flag, st);
    emitStore(ctx, busOf(*acc.q, acc.a.root, col + 1, st), col[1], idx, iv, flag, st);
    return;
  }
  if (hasPointerLeaf(val->getType()) && !isCodeAddress(val))
    unimplemented("mem-qram: a QRAM store of an aggregate holding a pointer (rules 21, 26: its fat fields)", &st);
  if (isAggregate(val->getType()))
    return storeThroughBytes(ctx, acc, val, flag, st);
  Operand v = ctx.operand(val);
  const Column *col = exactCell(ctx, *acc.q, acc.a, val->getType());
  if (!col) {
    if (v.handle || !storeClassicalBytes(ctx, acc, v.v, val->getType(), flag, st))
      storeThroughBytes(ctx, acc, val, flag, st);   // a bit view: one access per touched cell
    return;
  }
  QIndex idx = cellIndex(ctx, *acc.q, acc.a, st);
  if (!v.handle)
    v = Operand{seedOf(ctx, col->w, v.v), true};
  emitStore(ctx, busOf(*acc.q, acc.a.root, col, st), *col, idx, v.v, flag, st);
}

// cq-py5f (CR rule 24, 94): an atomicrmw / cmpxchg on a QRAM cell is the plain read-modify-write: the cell
// read as lowerQramLoad reads it, combine, the result stored as lowerQramStore stores it (the load's un-copy
// follows the store's pop, as for any load and later store of one cell).
Value *rmwQramCell(LoweringContext &ctx, Instruction &I, const Value *ptr, Type *ty,
                   function_ref<Value *(Value *)> combine) {
  if (Addr r = decompose(ptr, ctx.M.getDataLayout()); r.ok && isFormalQram(ctx, r.root))
    unimplemented("mem-qram: a read-modify-write through a QRAM triple formal (fatptr's derivation, P1)", &I);
  QAccess acc = qramAccess(ctx, ptr, I);
  if (!ty->isIntegerTy() && !ty->isFloatingPointTy())
    unimplemented("mem-qram: a QRAM access of a non-scalar or pointer value (rules 21, 25)", &I);
  const Column *col = exactCell(ctx, *acc.q, acc.a, ty);
  if (!col) {
    // A bit view (63): the bytes read through the byte engine (one access per touched cell), combined, and
    // the new value's bytes stored over the same cells (the old cells swapped out to their tape slots, §1.3).
    const DataLayout &DL = ctx.M.getDataLayout();
    uint64_t sb = storeBytes(DL, ty);
    unsigned vb = valueBits(ty);
    Operand x = intCast(ctx, "trunc", unsigned(sb * 8), vb, readBytes(ctx, acc, acc.a.off, sb, I));
    x = fromInt(ctx, x, ty);
    if (!x.handle)
      x = Operand{seedOf(ctx, railTypeOf(ty), x.v), true};
    Value *next = combine(x.v);
    Operand nx = intCast(ctx, "zext", vb, unsigned(sb * 8), asInt(ctx, Operand{next, true}, ty));
    writeBytes(ctx, acc, acc.a.off, sb, nx, ctx.currentFlag(), I);
    return x.v;
  }
  QIndex idx = cellIndex(ctx, *acc.q, acc.a, I);
  Value *bus = busOf(*acc.q, acc.a.root, col, I);
  Value *old = emitLoad(ctx, bus, *col, idx);
  Value *next = combine(old);
  emitStore(ctx, bus, *col, idx, next, ctx.currentFlag(), I);
  return old;
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
  auto constCells = [&](uint64_t cells) { return cellCountArg(ctx, q, cells); };
  if (auto *ai = dyn_cast<AllocaInst>(&site)) {
    q = layoutOf(ai->getAllocatedType(), DL, ai);
    uint64_t per = DL.getTypeAllocSize(ai->getAllocatedType()).getFixedValue() / q.elemBytes;
    if (auto *c = dyn_cast<ConstantInt>(ai->getArraySize())) {
      n = constCells(per * c->getZExtValue());
      q.bytes[&site] = per * c->getZExtValue() * q.elemBytes;
    } else {
      Operand cnt = ctx.operand(ai->getArraySize());
      if (cnt.handle) {
        uint64_t cells = satMul(per, upperBound(ai->getArraySize(), DL, site));
        n = constCells(cells);
        q.bytes[&site] = cells * q.elemBytes;
      } else {
        Value *x = B.CreateZExtOrTrunc(cnt.v, i64);
        if (per != 1)
          x = B.CreateMul(x, ConstantInt::get(i64, per));
        n = cellCountArg(ctx, q, x, satMul(per, upperBound(ai->getArraySize(), DL, site)));
      }
    }
  } else if (auto *CB = dyn_cast<CallBase>(&site)) {
    q = heapLayout(ctx, *site.getFunction(), soleQram(ctx, &site, site), &site);
    Attribute A = CB->getFnAttr(Attribute::AllocSize);
    // An allocator whose size the IR does not state: an object of unknown extent (rule 20, cq-k65d), spelled
    // n = 0 (2^64 cells, CR §1.3); every in-domain access is inside the real block.
    SmallVector<unsigned, 2> args;
    if (A.isValid()) {
      auto [ai0, ai1] = A.getAllocSizeArgs();
      args.push_back(ai0);
      if (ai1)
        args.push_back(*ai1);
    }
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
        cbytes = satMul(cbytes, c->getZExtValue());
      else
        allConst = false;
      bytes = bytes ? B.CreateMul(bytes, x) : x;
    }
    if (args.empty()) {
      q.wide = true;
      n = ConstantInt::get(i32, 0);
    } else if (allConst) {
      n = constCells(cbytes / q.elemBytes);
      q.bytes[&site] = cbytes;   // a quantum size: its upper bound, the cells allocated
    } else {
      Value *cells = B.CreateUDiv(bytes, ConstantInt::get(i64, q.elemBytes));
      uint64_t wideMax = 1;
      for (unsigned k : args)
        wideMax = satMul(wideMax, upperBound(CB->getArgOperand(k), DL, site));
      n = cellCountArg(ctx, q, cells, wideMax / q.elemBytes);
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
  // A site lowered again in one output function (a loop unit lowering each trip, rule 14) allocates a new
  // object each time: every later access of the site is to the newest one; the earlier one's stores stay
  // recorded on its own bus, popped and freed by Uncompute like any bus.
  QramState &st = qramStates()[&ctx.out()];
  st.objs[&site] = std::move(q);
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
    return;   // a VLA's scope end (llvm.stackrestore, 192) or the return: the same, nothing here
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
  // realloc of any other pointer than the block's own is undefined (C17 7.22.3.5): in the domain the
  // operand is the root, whatever offset its address arithmetic names.
  Addr a = decompose(old, DL);
  if (!a.ok)
    unimplemented("mem-qram: a realloc of a pointer whose root is not an object site (a merge of blocks, rule 21)",
                  &CB);
  QramObj &q = qramObj(ctx, a.root, CB);
  auto it = q.buses.find(a.root);
  if (it == q.buses.end())
    internalError("mem-qram: a realloc of a QRAM root with no bus in this function (its operand's root dominates "
                  "the realloc, so its allocation or realloc was lowered first)",
                  &CB);
  SmallVector<Value *, 2> olds = it->second;
  Attribute A = CB.getFnAttr(Attribute::AllocSize);
  // The new size in bytes: the allocsize argument, or the product of the two (a quantum one at its bound). A
  // reallocator whose size the IR does not state gives an object of unknown extent (rule 20): n = 0.
  SmallVector<unsigned, 2> sargs;
  if (A.isValid()) {
    sargs.push_back(A.getAllocSizeArgs().first);
    if (A.getAllocSizeArgs().second)
      sargs.push_back(*A.getAllocSizeArgs().second);
  }
  uint64_t cbytes = 1;
  bool allConst = true;
  Value *bytes = nullptr;
  for (unsigned k : sargs) {
    const Value *size = CB.getArgOperand(k);
    Operand sz = ctx.operand(size);
    Value *x = sz.handle ? ConstantInt::get(i64, upperBound(size, DL, CB)) : B.CreateZExtOrTrunc(sz.v, i64);
    if (auto *c = dyn_cast<ConstantInt>(x))
      cbytes = satMul(cbytes, c->getZExtValue());
    else
      allConst = false;
    bytes = bytes ? B.CreateMul(bytes, x) : x;
  }
  Value *n;
  if (sargs.empty()) {
    q.wide = true;
    n = ConstantInt::get(i32, 0);
  } else if (allConst) {
    n = cellCountArg(ctx, q, cbytes / q.elemBytes);
    q.bytes[&CB] = cbytes;
  } else {
    uint64_t wideMax = 1;
    for (unsigned k : sargs)
      wideMax = satMul(wideMax, upperBound(CB.getArgOperand(k), DL, CB));
    n = cellCountArg(ctx, q, B.CreateUDiv(bytes, ConstantInt::get(i64, q.elemBytes)), wideMax / q.elemBytes);
  }
  // Under a quantum predicate (rules 8, 20) the new logical size is the merge select(p, n, n_old), a quantum
  // size: CR §1.3 sizes it at its upper bound, max(n, n_old) (0, 2^64 cells, is the largest). A path where C
  // shrinks reaches no cell past n (undefined, outside the domain); one where it does not realloc keeps
  // n_old's cells. The old size is the old bus's own count (its qram_alloc or qram_realloc operand).
  if (ctx.currentFlag()) {
    auto *ob = dyn_cast<CallInst>(olds.front());
    Function *of = ob ? ob->getCalledFunction() : nullptr;
    Value *nOld = nullptr;
    if (of && of->getName().starts_with("cqrt_qram_alloc_"))
      nOld = ob->getArgOperand(0);
    else if (of && of->getName().starts_with("cqrt_qram_realloc_"))
      nOld = ob->getArgOperand(1);
    if (!nOld)
      internalError("mem-qram: a QRAM bus this function lowered that is no qram_alloc or qram_realloc result", &CB);
    if (auto *a1 = dyn_cast<ConstantInt>(n), *a2 = dyn_cast<ConstantInt>(nOld); a1 && a2) {
      uint64_t x = a1->getZExtValue(), y = a2->getZExtValue();
      n = ConstantInt::get(i32, x == 0 || y == 0 ? 0 : std::max(x, y));
    } else {
      Value *zero = ConstantInt::get(i32, 0);
      Value *anyAll = B.CreateOr(B.CreateICmpEQ(n, zero), B.CreateICmpEQ(nOld, zero));
      n = B.CreateSelect(anyAll, zero, B.CreateSelect(B.CreateICmpUGT(n, nOld), n, nOld));
    }
    if (auto it2 = q.bytes.find(a.root); it2 != q.bytes.end()) {
      auto it3 = q.bytes.find(&CB);
      if (it3 != q.bytes.end())
        it3->second = std::max(it3->second, it2->second);
    } else {
      q.bytes.erase(&CB);
    }
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

// One deferred store: its bus and column, its index (a classical j, or the copied-out index rail), the
// copied-out value, and the copied-out control flag (null: unconditional).
struct DeferredStore {
  Value *bus;
  Column col;
  QIndex idx;
  Value *v;
  Value *flag;
  bool idxOut = false;   // the index rail is one of the clone's results (FormalStore::idxRail)
  // The store as the clone's body made it (M2b's forwarding to later loads): its formal, index (a classical
  // i64 or a rail of idxBits bits), value rail and predicate flag (or null).
  const Value *root = nullptr;
  Operand idxOrig;
  unsigned idxBits = 64;
  Value *vOrig = nullptr, *flagOrig = nullptr;
};

// Per output function: how many times each store instruction (or a call's callee store `inner`) has been deferred.
std::map<const Function *, std::map<std::pair<const Instruction *, unsigned>, unsigned>> &deferCounts() {
  static std::map<const Function *, std::map<std::pair<const Instruction *, unsigned>, unsigned>> d;
  return d;
}

std::map<const Function *, SmallVector<DeferredStore, 2>> &deferredStores() {
  static std::map<const Function *, SmallVector<DeferredStore, 2>> d;
  return d;
}

// The loads and stores through pointers derived from formal A by GEPs and bitcasts (and, unless
// strict, phis and selects). Any other use is unimplemented.
struct FormalUses {
  SmallVector<const LoadInst *, 4> loads;
  SmallVector<const StoreInst *, 4> stores;
  // M2 through a call (rules 18, 21): a pointer derived from the formal handed to a direct call of a function with
  // a body that never calls back into this one (the call's argument operand number).
  SmallVector<std::pair<const CallBase *, unsigned>, 2> calls;
};

void tripleUseStop(const Value *usr) {
  unimplemented("mem-qram: a use of a pointer derived from a rule 21 triple formal other than a load, a store "
                "or address arithmetic (a call, a memory intrinsic, free, realloc, a compare, a merge or an "
                "escape of the triple: P1, M2)",
                usr);
}

// Whether G reaches F through direct calls of functions with bodies (G == F included).
bool reachesByCalls(const Function *G, const Function *F) {
  SmallVector<const Function *, 8> work{G};
  SmallPtrSet<const Function *, 16> seen{G};
  while (!work.empty()) {
    const Function *h = work.pop_back_val();
    if (h == F)
      return true;
    for (const Instruction &I : instructions(*h))
      if (auto *cb = dyn_cast<CallBase>(&I))
        if (const Function *c = cb->getCalledFunction(); c && !c->isDeclaration() && seen.insert(c).second)
          work.push_back(c);
  }
  return false;
}

FormalUses formalUses(const Argument &A, bool strict, bool throughCalls = false) {
  FormalUses out;
  SmallVector<const Value *, 8> work{&A};
  SmallPtrSet<const Value *, 16> seen{&A};
  while (!work.empty()) {
    const Value *v = work.pop_back_val();
    for (const Use &u : v->uses()) {
      const User *usr = u.getUser();
      // throughCalls (the cells' type, rule 18): a pointer handed on to a function with a body is accessed by
      // that function's formal (musl frexp hands its int *e to its own recursive call, cq-sd95).
      if (auto *cb = dyn_cast<CallBase>(usr); throughCalls && cb && cb->isArgOperand(&u) &&
                                               cb->getCalledFunction() && !cb->getCalledFunction()->isDeclaration() &&
                                               !isa<IntrinsicInst>(cb) &&
                                               cb->getArgOperandNo(&u) < cb->getCalledFunction()->arg_size()) {
        const Argument *fa = cb->getCalledFunction()->getArg(cb->getArgOperandNo(&u));
        if (seen.insert(fa).second)
          work.push_back(fa);
        continue;
      }
      if (auto *ld = dyn_cast<LoadInst>(usr)) {
        out.loads.push_back(ld);   // a volatile or atomic access is a plain one (rule 24)
        continue;
      }
      if (auto *st = dyn_cast<StoreInst>(usr); st && st->getPointerOperand() == v && st->getValueOperand() != v) {
        out.stores.push_back(st);   // rule 24: plain
        continue;
      }
      // A merge (phi, select) of pointers that all derive from the formals this walk follows is address
      // arithmetic on one object: a walk through the caller's QRAM (strict or not). A merge with any other object
      // is not (M2 could not tell the formal's stores from the other object's).
      bool merge = isa<PHINode>(usr) || (isa<SelectInst>(usr) && cast<SelectInst>(usr)->getCondition() != v);
      if (merge && strict) {
        SmallVector<const Value *, 4> us;
        getUnderlyingObjects(usr, us);
        merge = !us.empty() && llvm::all_of(us, [&](const Value *x) { return isa<Argument>(x) && seen.count(x); });
      }
      bool walk = isa<GEPOperator>(usr) || isa<BitCastOperator>(usr) || isa<AddrSpaceCastOperator>(usr) || merge;
      if (walk) {
        if (seen.insert(usr).second)
          work.push_back(usr);
        continue;
      }
      // Rule 21: a return (the clone's fat-pointer result, its fields the triple's tag and idx), a compare and a
      // ptrtoint (over the address) read no cell through the pointer.
      if (isa<ReturnInst>(usr) || isa<ICmpInst>(usr) || isa<PtrToIntInst>(usr))
        continue;
      // Rules 18, 21 (M2 through a call): the triple handed on to a lifted callee, whose stores through it are
      // this clone's (formalQramStores).
      if (auto *cb = dyn_cast<CallBase>(usr); cb && cb->isArgOperand(&u) && !isa<IntrinsicInst>(cb) &&
                                               cb->getCalledFunction() && !cb->getCalledFunction()->isDeclaration() &&
                                               !cb->getCalledFunction()->isVarArg() &&
                                               cb->getArgOperandNo(&u) < cb->getCalledFunction()->arg_size() &&
                                               !reachesByCalls(cb->getCalledFunction(), A.getParent())) {
        out.calls.push_back({cb, cb->getArgOperandNo(&u)});
        continue;
      }
      tripleUseStop(usr);
    }
  }
  return out;
}

Type *cellTypeOfUses(const Argument &A, bool strict) {
  FormalUses u = formalUses(A, strict, /*throughCalls=*/true);
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
  // A formal its clone never loads or stores through touches no cell: its one column is never accessed, and a
  // heap block only handed to such clones holds bytes (heapLayout's default, rule 22: untyped memory's cell).
  if (!t)
    t = Type::getInt8Ty(A.getContext());
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
  int64_t cell;   // cell offset from the formal's idx (when !idxRail)
  Type *ty;
  const StoreInst *st;   // null for a store a callee makes (call)
  // M2 through a call (rules 18, 21): the callee's store number `inner` (its own M2 order) through a pointer
  // this clone handed it at `call`, which lands in this formal's object.
  const CallBase *call = nullptr;
  unsigned inner = 0;
  // Rule 14 case 2: the instance number of a store in an unrolled K-loop trip (the k-th lowering of the store
  // instruction, trip-major), 0 outside K-loops.
  unsigned trip = 0;
  const Instruction *at() const { return st ? static_cast<const Instruction *>(st) : call; }
  // The store's index is not the caller's actual idx plus a constant (a run-time offset, or a constant offset
  // from a quantum idx): the clone copies its index out as a rail of its own (the caller's pop reads it).
  bool idxRail = false;
  // The store runs under a quantum predicate or the clone's control flag: a _controlled store whose flag the
  // clone copies out.
  bool flagged = false;
  unsigned rails() const { return 1 + unsigned(idxRail) + unsigned(flagged); }
};

// Whether the idx of pointer formal argNo crosses as a rail (its mask digit, CR §1.4).
bool formalIdxQuantum(const TaintInfo &T, const Specialization &S, unsigned argNo) {
  size_t d = 0;
  for (Argument &A : S.F->args()) {
    if (!A.getType()->isPointerTy()) {
      d += T.fieldMask(&A, S).size();
      continue;
    }
    PtrFormal pf = T.pointerFormal(S, A.getArgNo());
    if (A.getArgNo() == argNo)
      return pf.abi != PtrAbi::Raw && d + 1 < S.mask.size() && S.mask[d + 1] == '1';
    d += pf.digits;
  }
  internalError("mem-qram: formalIdxQuantum of no pointer formal", S.F);
}

// The blocks of an acyclic F every execution of its lowering runs, whatever its classical branches decide: a
// quantum branch runs all its arms under their predicates (rules 8, 9), a classical one only the arm it takes.
DenseSet<const BasicBlock *> alwaysRun(const TaintInfo &T, const Specialization &S) {
  std::map<const BasicBlock *, DenseSet<const BasicBlock *>> forced;
  std::function<DenseSet<const BasicBlock *>(const BasicBlock *)> F = [&](const BasicBlock *b) {
    auto it = forced.find(b);
    if (it != forced.end())
      return it->second;
    forced[b] = {b};   // a cycle (none reaches here: loops stop first) contributes nothing more
    DenseSet<const BasicBlock *> out{b};
    const Instruction *t = b->getTerminator();
    SmallVector<const BasicBlock *, 4> succ;
    for (const BasicBlock *x : successors(b))
      if (!is_contained(succ, x))
        succ.push_back(x);
    bool classical = succ.size() > 1;
    if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional())
      classical = !T.isQuantum(br->getCondition(), S);
    else if (auto *sw = dyn_cast<SwitchInst>(t))
      classical = !T.isQuantum(sw->getCondition(), S);
    if (classical && succ.size() > 1) {
      DenseSet<const BasicBlock *> meet = F(succ[0]);
      for (size_t k = 1; k < succ.size(); ++k) {
        DenseSet<const BasicBlock *> o = F(succ[k]), keep;
        for (const BasicBlock *x : meet)
          if (o.count(x))
            keep.insert(x);
        meet = std::move(keep);
      }
      for (const BasicBlock *x : meet)
        out.insert(x);
    } else {
      for (const BasicBlock *x : succ)
        for (const BasicBlock *y : F(x))
          out.insert(y);
    }
    forced[b] = out;
    return out;
  };
  return F(&S.F->getEntryBlock());
}

// M2's analysis: the clone's stores through Qram-pointee triple formals in program order, every shape
// outside the contract unimplemented.
SmallVector<FormalStore, 2> formalQramStores(const TaintInfo &T, const Specialization &S) {
  Function &F = *S.F;
  const DataLayout &DL = F.getParent()->getDataLayout();
  SmallVector<FormalStore, 2> out;
  SmallVector<std::pair<const LoadInst *, unsigned>, 8> loads;
  SmallVector<std::pair<const CallBase *, unsigned>, 4> calls;   // the triple handed on, every formal's
  for (Argument &A : F.args()) {
    if (!isQramTriple(T, S, A))
      continue;
    Type *cellTy = cellTypeOfUses(A, /*strict=*/true);
    int64_t E = int64_t(DL.getTypeAllocSize(cellTy).getFixedValue());
    FormalUses u = formalUses(A, /*strict=*/true);
    for (const LoadInst *ld : u.loads)
      loads.push_back({ld, A.getArgNo()});
    for (auto c : u.calls)
      if (!is_contained(calls, c))
        calls.push_back(c);
    bool idxQ = formalIdxQuantum(T, S, A.getArgNo());
    for (const StoreInst *st : u.stores) {
      Addr a = decompose(st->getPointerOperand(), DL);
      if (!a.ok) {
        // Through a merge of pointers into the formal's object (formalUses): its cell is the run-time index fatptr
        // derives, copied out with the store (M2's index rail).
        SmallVector<const Value *, 4> us;
        getUnderlyingObjects(st->getPointerOperand(), us);
        if (llvm::all_of(us, [&](const Value *x) { return x == &A; })) {
          FormalStore fs{A.getArgNo(), 0, cellTy, st};
          fs.idxRail = true;
          fs.flagged = S.ctl;
          out.push_back(fs);
          continue;
        }
      }
      if (!a.ok || a.root != &A)
        internalError("mem-qram: a store through a QRAM triple formal that is not the formal plus GEP offsets", st);
      if (a.off % E)
        unimplemented("mem-qram: a store through a QRAM triple formal inside a cell (a bit view, 63)", st);
      FormalStore fs{A.getArgNo(), a.off / E, cellTy, st};
      fs.idxRail = !a.terms.empty() || (idxQ && fs.cell != 0);
      fs.flagged = S.ctl;
      out.push_back(fs);
    }
  }
  // M2 through a call (rules 18, 21; 191): a callee handed a pointer into a QRAM formal's object stores into the
  // caller's bus. It applies its stores at its end; this clone pops them right after the call (they are its own
  // stores now) and defers them like its own (noteCalleeQramStores), one entry per callee store that lands in one
  // of its QRAM formals' objects: at the actual's cell plus the callee's offset, a classical one when the actual is
  // the formal plus a constant, else the index copied out as a rail. A callee store with an index rail of its own
  // (whose width only the callee knows), an actual that merges a formal's object with another, and a callee that
  // reads the object after a store this clone defers (it would not see it) stop with the triple's use.
  SmallPtrSet<const CallBase *, 4> done;
  for (auto [cb, j] : calls) {
    if (!done.insert(cb).second)
      continue;
    const Specialization *C = T.calleeSpecialization(*cb, S);
    if (!C || C->isEntry() || C->F != cb->getCalledFunction()) {
      tripleUseStop(cb);
      continue;   // no clone: no store of its own reaches the bus
    }
    SmallVector<FormalStore, 2> in = formalQramStores(T, *C);
    for (unsigned k = 0; k < in.size(); ++k) {
      const Value *act = cb->getArgOperand(in[k].argNo);
      SmallVector<const Value *, 4> us;
      getUnderlyingObjects(act, us);
      const Argument *B = us.empty() ? nullptr : dyn_cast<Argument>(us.front());
      bool own = B && B->getParent() == &F && isQramTriple(T, S, *B) &&
                 llvm::all_of(us, [&](const Value *x) { return x == B; });
      if (!own) {
        // The actual names no QRAM formal of this clone: the callee stores into an object of this clone's own (U3).
        if (llvm::any_of(us, [&](const Value *x) {
              auto *X = dyn_cast<Argument>(x);
              return X && X->getParent() == &F && isQramTriple(T, S, *X);
            }))
          tripleUseStop(cb);
        continue;
      }
      Type *cellTy = cellTypeOfUses(*B, /*strict=*/true);
      int64_t E = int64_t(DL.getTypeAllocSize(cellTy).getFixedValue());
      Addr a = decompose(act, DL);
      FormalStore fs{B->getArgNo(), 0, in[k].ty, nullptr};
      fs.call = cb;
      fs.inner = k;
      fs.flagged = in[k].flagged;   // the callee's flag (a _ctl callee's include its caller's predicate)
      if (in[k].idxRail) {
        fs.idxRail = true;   // the callee's own index rail, copied out again at its width (deferCallStore)
      } else if (a.ok && a.root == B && a.terms.empty() && a.off % E == 0) {
        fs.cell = a.off / E + in[k].cell;
        fs.idxRail = formalIdxQuantum(T, S, B->getArgNo()) && fs.cell != 0;
      } else {
        fs.idxRail = true;
      }
      out.push_back(fs);
    }
  }
  if (out.empty())
    return out;
  DominatorTree DT(F);
  PostDominatorTree PDT(F);
  LoopInfo LI(DT);
  // Rule 14 case 2 (loops-cutoff): a quantum-exit loop runs c = min(K, B) trips UNROLLED, its body lowered once per
  // trip under the trip predicate; a store in it is c store instances, each its own copied-out rails (the per-trip
  // rails rule 14 mints for every value of a trip), a _controlled store under the trip's flag. Nested K-loops
  // multiply. The trip counts are the cutoff module's: K resolved per function, B its cutoffBound.
  TargetLibraryInfoImpl tlii(Triple(F.getParent()->getTargetTriple()));
  TargetLibraryInfo tli(tlii, &F);
  AssumptionCache ac(F);
  ScalarEvolution SE(F, tli, ac, DT, LI);
  auto kLoop = [&](const Loop *L) { return loops::classify(*L, T, S) == loops::Case::QuantumExit; };
  auto tripsOf = [&](const Loop *L) -> unsigned {
    unsigned K = m2KOptions() ? loops::resolveK(F, *m2KOptions()) : 4;
    std::optional<uint64_t> B = loops::exits::cutoffBound(*L, SE, T, S);
    return unsigned(B ? std::min<uint64_t>(K, *B) : K);
  };
  // A store whose every enclosing loop is a K-loop is unrolled with them: it runs on every trip's path.
  auto unrolled = [&](const FormalStore &fs) {
    const Loop *L = LI.getLoopFor(fs.at()->getParent());
    if (!L)
      return false;
    for (; L; L = L->getParentLoop())
      if (!kLoop(L))
        return false;
    return true;
  };
  DenseSet<const BasicBlock *> always;
  bool alwaysDone = false;
  for (FormalStore &fs : out) {
    const BasicBlock *b = fs.at()->getParent();
    if (unrolled(fs)) {
      fs.flagged = true;   // the trip predicate (and the callee's flag, a _ctl callee's under it)
      fs.idxRail = true;   // each trip's own cell
      continue;
    }
    bool everyPath = PDT.dominates(b, &F.getEntryBlock());
    for (const BasicBlock &r : F)
      if (isa<ReturnInst>(r.getTerminator()))
        everyPath &= DT.dominates(b, &r);
    if (!everyPath && !LI.getLoopFor(b)) {
      // Under a branch: built when only quantum branches avoid it (its lowering runs it under its predicate,
      // a _controlled store).
      if (!alwaysDone) {
        always = alwaysRun(T, S);
        alwaysDone = true;
      }
      everyPath = always.count(b) != 0;
      if (!fs.call)
        fs.flagged = true;
    }
    if (!everyPath || LI.getLoopFor(b))
      unimplemented("mem-qram: a store through a QRAM triple formal under a classical branch or in a loop of the "
                    "clone (M2: the clone's stores are deferred, one copied-out rail each, in program order)",
                    fs.at());
  }
  llvm::stable_sort(out, [&](const FormalStore &x, const FormalStore &y) {
    return x.at() != y.at() && DT.dominates(x.at(), y.at());
  });
  // The trip instances in lowering order: a K-loop's stores trip-major (trip 0's in program order, then trip 1's,
  // ...), nested K-loops expanded inside each trip; the instance number of each store instruction counts its
  // lowerings (deferFormalStore, deferCallStore).
  {
    SmallVector<FormalStore, 2> ordered;
    std::map<std::pair<const Instruction *, unsigned>, unsigned> instance;
    std::function<void(ArrayRef<FormalStore>, const Loop *)> expand = [&](ArrayRef<FormalStore> xs, const Loop *L) {
      for (size_t i = 0; i < xs.size();) {
        // The child loop of L (a K-loop) holding xs[i], if any.
        const Loop *C = LI.getLoopFor(xs[i].at()->getParent());
        while (C && C->getParentLoop() != L)
          C = C->getParentLoop();
        if (!C || !unrolled(xs[i])) {
          FormalStore fs = xs[i++];
          fs.trip = instance[{fs.at(), fs.inner}]++;
          ordered.push_back(fs);
          continue;
        }
        size_t j = i;
        while (j < xs.size() && C->contains(xs[j].at()->getParent()))
          ++j;
        for (unsigned t = 0, n = tripsOf(C); t < n; ++t)
          expand(xs.slice(i, j - i), C);
        i = j;
      }
    };
    expand(out, nullptr);
    out = std::move(ordered);
  }
  // A callee that reads the object through the triple after a store this clone defers would read the cell
  // without it.
  for (auto [cb, j] : calls)
    for (const FormalStore &fs : out)
      if (fs.at() != cb && isPotentiallyReachable(fs.at(), cb, nullptr, &DT, &LI) &&
          !formalUses(*cb->getCalledFunction()->getArg(j), /*strict=*/false, /*throughCalls=*/true).loads.empty())
        tripleUseStop(cb);
  // A load after stores through its own formal reads them forwarded (forwardDeferredStores). Two formals may
  // name one caller object, and the clone cannot compare their buses (handles): a load after a store through
  // another formal is a stop.
  for (auto [ld, argNo] : loads)
    for (const FormalStore &fs : out)
      if (fs.argNo != argNo && isPotentiallyReachable(fs.at(), ld, nullptr, &DT, &LI))
        unimplemented("mem-qram: a load through a QRAM triple formal after a store through another triple formal "
                      "(M2b defers the store; the clone cannot tell whether the two name one object)",
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

// The entry of M2's analysis (formalQramStores) a deferred store is.
std::optional<FormalStore> listedStore(LoweringContext &ctx, function_ref<bool(const FormalStore &)> match,
                                       const Instruction &at) {
  std::optional<FormalStore> fs;
  for (const FormalStore &x : formalQramStores(ctx.T, ctx.S))
    if (match(x))
      fs = x;
  if (!fs)
    internalError("mem-qram: a deferred store that M2's analysis does not list", &at);
  return fs;
}

// The triple formal of this clone whose caller's bus `bus` is (registerFormalQram), or null.
const Value *formalOfBus(LoweringContext &ctx, Value *bus) {
  QramState &st = qramStates()[&ctx.out()];
  for (auto &[site, q] : st.objs)
    for (auto &[root, hs] : q.buses)
      if (is_contained(hs, bus) && st.formals.count(site))
        return site;
  return nullptr;
}

// The rule 18 copy-out of a rail x: f = alloc 0, copy(x, f), a result of the clone.
Value *copyOutRail(LoweringContext &ctx, Value *x, RailType w) {
  LLVMContext &C = ctx.M.getContext();
  CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(C, w))});
  RailId fid = ctx.unc().recordSeed(f);
  abi::CoreSpec cp{abi::Core::Copy, w};
  CallInst *cpy = ctx.emitCore(cp, {x, f});
  ctx.unc().recordCore(cpy, cp, {Operand{x, true}, Operand{f, true}}, fid);
  ctx.unc().setRole(fid, Role::Result);
  return f;
}

// The width of an index rail a call to a clone returns (its M2 copy-out: the field of the clone's built body is
// the result of cqrt_alloc_<W>, a seed or a copy-out's fresh rail); the i32 triple idx otherwise (rule 21: the
// index crosses a clone boundary as an i32). constructionOrder builds such a clone before its caller.
RailType indexRailType(Value *idx) {
  auto *ev = dyn_cast<ExtractValueInst>(idx);
  auto *call = ev ? dyn_cast<CallInst>(ev->getAggregateOperand()) : nullptr;
  Function *G = call ? call->getCalledFunction() : nullptr;
  if (G && !G->isDeclaration() && ev->getNumIndices() == 1)
    for (BasicBlock &BB : *G)
      if (auto *ret = dyn_cast<ReturnInst>(BB.getTerminator()); ret && ret->getReturnValue()) {
        // The insertvalue that writes the field.
        for (Value *v = ret->getReturnValue(); auto *iv = dyn_cast<InsertValueInst>(v); v = iv->getAggregateOperand())
          if (iv->getNumIndices() == 1 && iv->getIndices()[0] == ev->getIndices()[0]) {
            auto *a = dyn_cast<CallInst>(iv->getInsertedValueOperand());
            std::optional<abi::CoreSpec> cs = a && a->getCalledFunction()
                                                  ? abi::parseCore(a->getCalledFunction()->getName())
                                                  : std::nullopt;
            if (cs && cs->op == abi::Core::Alloc)
              return cs->w;
            break;
          }
      }
  return RailType{Kind::Int, 32};
}

// M2 through a call (formalQramStores): the callee's store number `inner` at `call`, of value v at idx (this
// clone's bus coordinates: the i32 triple idx it handed on plus the callee's offset, or a classical index) under
// flag, on the bus of this clone's triple formal `formal`: deferred like the clone's own stores (its value, index
// and flag copied out; M2b forwards it to later loads).
void deferCallStore(LoweringContext &ctx, const CallBase &call, unsigned inner, const Value *formal, const Column &col,
                    Operand idx, Value *v, Value *flag) {
  unsigned k = deferCounts()[&ctx.out()][{&call, inner}]++;   // the k-th lowering of the call (a K-loop trip)
  std::optional<FormalStore> fs = listedStore(
      ctx, [&](const FormalStore &x) { return x.call == &call && x.inner == inner && x.trip == k; }, call);
  QramObj &q = qramObj(ctx, formal, call);
  LLVMContext &C = ctx.M.getContext();
  DeferredStore d{nullptr, col, QIndex{}, copyOutRail(ctx, v, col.w), nullptr};
  d.bus = busOf(q, formal, &col, call);
  d.idxOut = fs->idxRail;
  d.root = formal;
  d.idxOrig = idx;
  d.idxBits = idx.handle ? 32 : 64;
  d.vOrig = v;
  d.flagOrig = flag;
  if (fs->idxRail) {
    if (idx.handle) {
      d.idx = {copyOutRail(ctx, idx.v, indexRailType(idx.v)), true};
    } else {
      Type *i32 = Type::getInt32Ty(C);
      CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 32}},
                                    {ctx.B().CreateSExtOrTrunc(idx.v, i32)});
      RailId sid = ctx.unc().recordSeed(seed);
      ctx.unc().setRole(sid, Role::Result);
      d.idx = {seed, true};
    }
  } else {
    d.idx = fatIndex(ctx, q, idx);
  }
  if (flag)
    d.flag = copyOutRail(ctx, flag, RailType{Kind::Int, 1});
  deferredStores()[&ctx.out()].push_back(d);
}

} // namespace

Type *formalCellType(const Argument &A) { return cellTypeOfUses(A, /*strict=*/false); }

HostTriple hostTriple(LoweringContext &ctx, const Value *ptr, const Instruction &at) {
  const DataLayout &DL = ctx.M.getDataLayout();
  Addr a = decompose(ptr, DL);
  // Rule 21 (P1): a pointer derived from this clone's own host or slot triple formal points into the caller's
  // object the formal came with; it crosses on as that triple (object, tag and cell count the formal's, idx its
  // idx plus the offset in the formal's cells).
  fatptr::FormalTriple ft;
  bool formal = a.ok && isa<Argument>(a.root) && fatptr::boundTriple(ctx, a.root, ft);
  bool local = a.ok && (isa<AllocaInst>(a.root) || isa<GlobalVariable>(a.root)) &&
               ctx.T.provenance(ptr, ctx.S).size() == 1;
  if (!local && !formal) {
    // Rules 20, 21 (cq-k65d, cq-5xm0): any other object (a parameter of a function that is no clone of its caller,
    // a heap block, a call's result, a loaded pointer, a merge, an integer cast to a pointer): the object that
    // starts at the pointer, its count the extent from the pointer on (0: unknown extent).
    fatptr::ownPlaceTriple(ctx, ptr, ft);
    HostTriple h{ptr, ft.idx, ft.cellCount, ft.cell};
    h.object = ft.object;
    h.tag = ft.tag;
    return h;
  }
  Type *objTy = nullptr;
  uint64_t bytes = 0, cb = ft.cell;
  Value *rtBytes = nullptr;   // a VLA's size, computed at the call (rule 21: the count follows the triple)
  if (formal) {
    // The formal's cells: its clone's accesses (and its callees', hostFormalCellBytes / formalCellType).
  } else if (auto *ai = dyn_cast<AllocaInst>(a.root)) {
    auto sz = ai->getAllocationSize(DL);
    objTy = ai->getAllocatedType();
    if (sz && !sz->isScalable()) {
      bytes = sz->getFixedValue();
    } else {
      Operand c = ctx.operand(ai->getArraySize());
      if (c.handle)
        internalError("mem-qram: a VLA element count bound to a rail", ai);
      Type *i64 = Type::getInt64Ty(ctx.M.getContext());
      rtBytes = ctx.B().CreateMul(ctx.B().CreateZExtOrTrunc(c.v, i64),
                                  ConstantInt::get(i64, DL.getTypeAllocSize(objTy).getFixedValue()));
    }
  } else {
    auto *gv = cast<GlobalVariable>(a.root);
    objTy = gv->getValueType();
    bytes = DL.getTypeAllocSize(objTy).getFixedValue();
  }
  if (!formal) {
    ArrayRef<ObjectId> objs = ctx.T.provenance(ptr, ctx.S);
    if (objs.size() != 1)
      internalError("mem-qram: hostTriple of a pointer with other than one object", &at);
    // cq-dd3q (CR rules 20, 21): a slot object's cells are mem-slots' (slotLayout), a host object's its C type's.
    std::optional<SlotLayout> L;
    if (ctx.T.classOf(objs.front()) == ObjClass::Slot)
      L = slotLayout(ctx, a.root, objs.front(), at, /*fields=*/true);
    std::function<bool(Type *)> hasPtr = [&](Type *t) {
      if (auto *s2 = dyn_cast<StructType>(t))
        return llvm::any_of(s2->elements(), hasPtr);
      if (auto *a2 = dyn_cast<ArrayType>(t))
        return hasPtr(a2->getElementType());
      return t->isPointerTy();
    };
    bool ptrRecord = L ? L->record && L->pointerField : isa<StructType>(objTy) && hasPtr(objTy);
    if (ptrRecord && isa<AllocaInst>(a.root) && !rtBytes) {
      // cq-oocu (CR rules 20, 21; 107): a local slot record with a pointer-kind field crosses as ONE cell (the
      // record), at its start: (object, tag, idx 0, count 1).
      if (a.off != 0 || !a.terms.empty())
        unimplemented("mem-qram: a pointer into a slot record with a pointer-kind field crossing a clone boundary "
                      "other than at the record's start (rule 21 triple)",
                      &at);
      LLVMContext &C = ctx.M.getContext();
      return {a.root, ConstantInt::get(Type::getInt32Ty(C), 0), ConstantInt::get(Type::getInt32Ty(C), 1), bytes};
    }
    // Rules 20, 22 (cq-366o): a local's cells are the type the program accesses it as. A slot object's are
    // mem-slots' (byte cells of a struct read across its fields, 63; the narrow cells of 90), a slot record's its
    // fields when they are all handle cells of one size (the lowered record is then the slot array the triple's
    // idx indexes); a slot record of classical fields or of several sizes has no one cell a triple's idx counts
    // (its lowered layout is not the C one). A host object's cells are its C type's scalar (arrays stripped, a
    // vector's lanes, rule 25), a struct of one leaf type that leaf (an array by another name), a struct of
    // several leaf types ONE cell, the record (host memory is C's own layout; the callee's accesses are checked,
    // checkCalleeCells).
    if (L && L->record && !L->handleCellBytes) {
      unimplemented("mem-qram: an object crossing a clone boundary as a rule 21 triple that is accessed at another "
                    "width than its cell (a bit view, 63)",
                    &at);
    } else if (L && L->record) {
      cb = L->handleCellBytes;
    } else if (L) {
      cb = L->cellBytes;
    } else {
      Type *t = isa<AllocaInst>(a.root) ? localCellType(*cast<AllocaInst>(a.root)) : objTy;
      SmallVector<Type *, 8> leaves;
      scalarLeafTypes(t, leaves);
      bool one = all_of(leaves, [&](Type *x) { return x == leaves.front(); });
      while (isa<ArrayType>(t))
        t = t->getArrayElementType();
      cb = DL.getTypeAllocSize(one && !leaves.empty() ? leaves.front() : t).getFixedValue();
    }
    // mem-slots' cells are the scalar element; an object accessed at another width has other cells
    // (a bit view, or -O1's punned local, 90).
    for (const Access &x : accessesOf(ctx, *at.getFunction(), objs.front()))
      if (DL.getTypeAllocSize(x.ty).getFixedValue() != cb)
        unimplemented("mem-qram: an object crossing a clone boundary as a rule 21 triple that is accessed at another "
                      "width than its cell (a bit view, 63)",
                      x.I);
  }
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
  if (formal) {
    HostTriple h{a.root, B.CreateTrunc(B.CreateAdd(B.CreateSExt(ft.idx, i64), j), i32), ft.cellCount, cb};
    h.object = ft.object;
    h.tag = ft.tag;
    return h;
  }
  if (rtBytes)
    return {a.root, B.CreateTrunc(j, i32), B.CreateTrunc(B.CreateUDiv(rtBytes, ConstantInt::get(i64, cb)), i32), cb};
  if (bytes / cb > UINT32_MAX)
    unimplemented("awaiting owner ruling: SPEC_ISSUES a rule 21 triple onto an object of 2^32 or more cells (the "
                  "compiler-added i32 cell count)",
                  &at);
  return {a.root, B.CreateTrunc(j, i32), ConstantInt::get(i32, bytes / cb), cb};
}

Constant *qramObjectBase(LoweringContext &ctx, ObjectId o) { return qramBase(ctx, o); }

const loops::KOptions *&m2KOptions() {
  static const loops::KOptions *k = nullptr;
  return k;
}

namespace {
// Rule 21: the QRAM root a classical pointer into one QRAM object names in this function, when the pointer is not
// that root plus GEP offsets (a classical merge walking the object, a clone's pointer result, a pointer loaded or
// computed): a QRAM triple formal of this clone every object of the pointer derives from (through GEPs, casts,
// phis and selects), else the allocation site or global of the pointer's one QRAM object. Its cell index is the
// root's own (the formal's classical idx, 0 for a site) plus the distance of the pointer's address from the root's
// in cells: the pointer's classical value is an address in the QRAM address space (qramBase, boundQramAddress).
struct Addressed {
  const Value *root = nullptr;
  Value *rootIdx = nullptr;   // i64
};
Addressed addressedRoot(LoweringContext &ctx, const Value *ptr) {
  Addressed out;
  Addr r = decompose(ptr, ctx.M.getDataLayout(), &ctx);
  if (r.ok && (isFormalQram(ctx, r.root) || isQramRoot(ctx, r.root)))
    return out;   // the root plus GEP offsets: the usual access
  if (ctx.T.isFatPointer(ptr, ctx.S) || ctx.T.isQuantum(ptr, ctx.S) || !ctx.bound(ptr) || ctx.operand(ptr).handle)
    return out;
  IRBuilder<> &B = ctx.B();
  SmallVector<const Value *, 4> us;
  getUnderlyingObjects(ptr, us);
  auto *A = us.empty() ? nullptr : dyn_cast<Argument>(us.front());
  if (A && isFormalQram(ctx, A) && llvm::all_of(us, [&](const Value *x) { return x == A; })) {
    if (!ctx.bound(A) || ctx.operand(A).handle || !fatptr::boundFormalIdx(ctx, *A))
      return out;
    out.root = A;
    out.rootIdx = B.CreateSExtOrTrunc(fatptr::boundFormalIdx(ctx, *A), B.getInt64Ty());
    return out;
  }
  ArrayRef<ObjectId> objs = ctx.T.provenance(ptr, ctx.S);
  if (objs.size() != 1 || ctx.T.classOf(objs.front()) != ObjClass::Qram)
    return out;
  for (auto &[site, q] : qramStates()[&ctx.out()].objs) {
    if (isa<Argument>(site) || isa<GlobalVariable>(site) || !ctx.bound(site) || ctx.operand(site).handle)
      continue;
    if (ctx.T.objectOf(site, ctx.S) != objs.front())
      continue;
    out.root = site;
    out.rootIdx = B.getInt64(0);
    return out;
  }
  // A global QRAM keeps its host storage: a pointer to it holds the global's own address.
  for (GlobalVariable &G : ctx.M.globals())
    if (isQramRoot(ctx, &G) && ctx.T.objectOf(&G, ctx.S) == objs.front()) {
      out.root = &G;
      out.rootIdx = B.getInt64(0);
      return out;
    }
  return out;
}

// The cell ptr names: the root's idx plus (address(ptr) - address(root)) / E, E the object's element size.
Operand addressedCell(LoweringContext &ctx, const Addressed &a, const Value *ptr, uint64_t E) {
  IRBuilder<> &B = ctx.B();
  Type *i64 = B.getInt64Ty();
  Value *d = B.CreateSub(B.CreatePtrToInt(ctx.operand(ptr).v, i64), B.CreatePtrToInt(ctx.operand(a.root).v, i64));
  Value *cells = isPowerOf2_64(E) ? B.CreateAShr(d, Log2_64(E)) : B.CreateSDiv(d, ConstantInt::get(i64, E));
  return Operand{B.CreateAdd(a.rootIdx, cells), false};
}
} // namespace

// A pointer that is not an object plus GEP offsets and that derives only from triple formals of this clone (a
// merge of fat pointers over them, a K-loop's carried walk): fatptr derives its (tag, idx).
bool formalFatWalk(LoweringContext &ctx, const Value *ptr) {
  if (decompose(ptr, ctx.M.getDataLayout(), &ctx).ok)
    return false;
  SmallVector<const Value *, 4> us;
  getUnderlyingObjects(ptr, us);
  return !us.empty() && llvm::all_of(us, [&](const Value *x) { return isa<Argument>(x) && isFormalQram(ctx, x); });
}

bool qramAddressed(LoweringContext &ctx, const Value *ptr, const Value *&root, Value *&idx) {
  Addressed a = addressedRoot(ctx, ptr);
  if (!a.root)
    return false;
  root = a.root;
  idx = addressedCell(ctx, a, ptr, qramObj(ctx, a.root, *cast<Instruction>(ptr)).elemBytes).v;
  return true;
}

bool lowerFormalWalkLoad(LoweringContext &ctx, LoadInst &ld) {
  Addressed a = addressedRoot(ctx, ld.getPointerOperand());
  if (!a.root || ld.getType()->isPointerTy())
    return false;
  QramObj &q = qramObj(ctx, a.root, ld);
  const Column &c = firstColumn(ctx, q, ld.getType(), ld);
  Operand j = addressedCell(ctx, a, ld.getPointerOperand(), q.elemBytes);
  ctx.bind(&ld, qramLoadAt(ctx, a.root, j, ld.getType(), ld, 64));
  return true;
}

bool lowerFormalWalkStore(LoweringContext &ctx, StoreInst &st) {
  Addressed a = addressedRoot(ctx, st.getPointerOperand());
  Type *ty = st.getValueOperand()->getType();
  if (!a.root || ty->isPointerTy())
    return false;
  QramObj &q = qramObj(ctx, a.root, st);
  const Column &c = firstColumn(ctx, q, ty, st);
  Operand j = addressedCell(ctx, a, st.getPointerOperand(), q.elemBytes);
  Operand v = ctx.operand(st.getValueOperand());
  if (!v.handle)
    v = Operand{seedOf(ctx, c.w, v.v), true};
  if (isFormalQram(ctx, a.root))
    deferFormalStore(ctx, a.root, j, 64, ty, v.v, ctx.currentFlag(), st);
  else
    qramStoreAt(ctx, a.root, j, ty, v.v, ctx.currentFlag(), st);
  return true;
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

void deferFormalStore(LoweringContext &ctx, const Value *root, Operand idx, unsigned idxBits, Type *ty, Value *v,
                      Value *flag, const Instruction &at) {
  unsigned k = deferCounts()[&ctx.out()][{&at, 0u}]++;   // the k-th lowering of this store (a K-loop trip)
  std::optional<FormalStore> fs =
      listedStore(ctx, [&](const FormalStore &x) { return x.st == &at && x.trip == k; }, at);
  if ((flag != nullptr) != fs->flagged)
    internalError("mem-qram: a deferred store's predicate disagrees with M2's analysis", &at);
  QramObj &q = qramObj(ctx, root, at);
  const Column &c = firstColumn(ctx, q, ty, at);
  LLVMContext &C = ctx.M.getContext();
  // The rule 18 copy-out of a rail x: f = alloc 0, copy(x, f), a result of the clone.
  auto copyOut = [&](Value *x, RailType w) {
    CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(C, w))});
    RailId fid = ctx.unc().recordSeed(f);
    abi::CoreSpec cp{abi::Core::Copy, w};
    CallInst *cpy = ctx.emitCore(cp, {x, f});
    ctx.unc().recordCore(cpy, cp, {Operand{x, true}, Operand{f, true}}, fid);
    ctx.unc().setRole(fid, Role::Result);
    return f;
  };
  DeferredStore d{busOf(q, root, &c, at), c, QIndex{}, copyOut(v, c.w), nullptr};
  d.idxOut = fs->idxRail;
  d.root = root;
  d.idxOrig = idx;
  d.idxBits = idx.handle ? idxBits : 64;
  d.vOrig = v;
  d.flagOrig = flag;
  if (fs->idxRail) {
    // The index as a rail of the clone's results, which the caller's pop reads: a quantum one copied out, a
    // classical one a seed of its value (the twin XORs the value out where the clone minted it, rule 18).
    if (idx.handle) {
      d.idx = {copyOut(idx.v, RailType{Kind::Int, idxBits}), true};
    } else {
      Type *i32 = Type::getInt32Ty(C);
      CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 32}},
                                    {ctx.B().CreateSExtOrTrunc(idx.v, i32)});
      RailId sid = ctx.unc().recordSeed(seed);
      ctx.unc().setRole(sid, Role::Result);
      d.idx = {seed, true};
    }
  } else {
    d.idx = fatIndex(ctx, q, idx);
  }
  if (flag)
    d.flag = copyOut(flag, RailType{Kind::Int, 1});
  deferredStores()[&ctx.out()].push_back(d);
}

// M2b: a load through a triple formal after stores through it that the clone defers to its end reads what C
// reads: the cell's content, replaced by the value of each earlier store (program order) whose index equals the
// load's and whose predicate holds, select(idx == idx_j && flag_j, v_j, ...) over the rails the store read (the
// body's own: its twin replays them after the caller popped the stores, against the same cells).
Value *forwardDeferredStores(LoweringContext &ctx, const Value *root, Operand idx, unsigned idxBits, Value *loaded,
                             const Instruction &at) {
  auto it = deferredStores().find(&ctx.out());
  if (it == deferredStores().end() || it->second.empty())
    return loaded;
  LLVMContext &C = ctx.M.getContext();
  IRBuilder<> &B = ctx.B();
  auto tmpl = [&](StringRef op, RailType w, ArrayRef<Operand> ops, StringRef shape, std::optional<RailType> to = {},
                  StringRef pred = "") {
    abi::TemplateSpec sp;
    sp.op = op.str();
    sp.w = w;
    sp.shape = shape.str();
    if (to)
      sp.to = *to;
    sp.pred = pred.str();
    return ctx.emitTemplate(sp, ops);
  };
  // Two indices as operands of one width (a classical one at the rail's width; two rails zero-extended to the
  // wider: a triple formal is at its object's start, its indices are non-negative).
  auto eqOf = [&](Operand a, unsigned aw, Operand b, unsigned bw) -> Value * {
    if (!a.handle && !b.handle) {
      Type *i64 = Type::getInt64Ty(C);
      Value *c = B.CreateICmpEQ(B.CreateSExtOrTrunc(a.v, i64), B.CreateSExtOrTrunc(b.v, i64));
      return seedOf(ctx, RailType{Kind::Int, 1}, c);
    }
    if (!a.handle) {
      std::swap(a, b);
      std::swap(aw, bw);
    }
    if (!b.handle)
      return tmpl("icmp", RailType{Kind::Int, aw},
                  {a, Operand{B.CreateSExtOrTrunc(b.v, IntegerType::get(C, aw)), false}}, "hl", {}, "eq");
    unsigned w = std::max(aw, bw);
    if (aw < w)
      a = Operand{tmpl("zext", RailType{Kind::Int, aw}, {a}, "", RailType{Kind::Int, w}), true};
    if (bw < w)
      b = Operand{tmpl("zext", RailType{Kind::Int, bw}, {b}, "", RailType{Kind::Int, w}), true};
    return tmpl("icmp", RailType{Kind::Int, w}, {a, b}, "", {}, "eq");
  };
  Value *val = loaded;
  for (const DeferredStore &d : it->second) {
    if (d.root != root)
      internalError("mem-qram: a load through a triple formal after a deferred store through another formal (M2's "
                    "analysis stops on it)",
                    &at);
    Value *p = eqOf(idx, idx.handle ? idxBits : 64, d.idxOrig, d.idxBits);
    if (d.flagOrig)
      p = tmpl("and", RailType{Kind::Int, 1}, {Operand{d.flagOrig, true}, Operand{p, true}}, "");
    val = tmpl("select", d.col.w, {Operand{p, true}, Operand{d.vOrig, true}, Operand{val, true}}, "");
  }
  return val;
}

unsigned calleeQramStoreCount(const TaintInfo &T, const Specialization &callee) {
  unsigned n = 0;
  for (const FormalStore &fs : formalQramStores(T, callee))
    n += fs.rails();
  return n;
}

SmallVector<Value *, 2> emitCalleeQramStores(LoweringContext &ctx) {
  SmallVector<Value *, 2> out;
  auto it = deferredStores().find(&ctx.out());
  if (it == deferredStores().end())
    return out;
  // Per store, its rails in M2's order: the value, the index rail (idxRail), the flag (flagged).
  for (DeferredStore &d : it->second) {
    SmallVector<Value *, 4> args;
    if (d.flag)
      args.push_back(d.flag);
    args.append({d.bus, d.idx.v, d.v});
    ctx.emitCore(abi::CoreSpec{abi::Core::QramStore, d.col.w, d.flag != nullptr, !d.idx.quantum}, args);
    out.push_back(d.v);
    if (d.idxOut)
      out.push_back(d.idx.v);
    if (d.flag)
      out.push_back(d.flag);
  }
  deferredStores().erase(it);
  return out;
}

void noteCalleeQramStores(LoweringContext &ctx, const CallBase &orig, const Specialization &callee, CallInst *fwd,
                          ArrayRef<Value *> storedRails) {
  const TaintInfo &T = ctx.T;
  SmallVector<FormalStore, 2> stores = formalQramStores(T, callee);
  unsigned railCount = 0;
  for (const FormalStore &fs : stores)
    railCount += fs.rails();
  if (railCount != storedRails.size())
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
  if (fenv::cloneCarriesEnv(T, callee))
    p += 2;   // E1 (82): the caller's mode and flags trail the formals (calls::materialize)
  if (p != fwd->arg_size())
    internalError("mem-qram: a clone call whose arguments do not match its formals' layout", fwd);
  // A global QRAM's stores are never popped (rule 20, 160): the caller records none of them. Its twin then
  // recomputes the clone's loads against cells the stores changed: built when the clone loads through no
  // QRAM triple formal on that bus.
  DenseSet<Value *> globalBuses;
  for (Value *bus : buses) {
    bool global = false;
    if (!columnOfBus(ctx, bus, global))
      internalError("mem-qram: a clone call's QRAM triple whose bus is no QRAM of this function", fwd);
    if (global)
      globalBuses.insert(bus);
    // A bus this clone was handed (its triple formal's) is the caller's rail: no store lands on it in this clone's
    // body (its own are deferred, a callee's popped right after the call), so the call reads it as it is. A global
    // QRAM's bus is an output whose stores are never popped (rule 20, 160): it has no versions to order the call
    // after.
    if (!formalOfBus(ctx, bus) && !global)
      ctx.unc().noteCallBusRead(fwd, ctx.unc().idOf(bus));
  }
  for (Argument &A : callee.F->args())
    if (isQramTriple(T, callee, A) && triple.count(A.getArgNo()) && globalBuses.count(triple[A.getArgNo()].first) &&
        !stores.empty() && !formalUses(A, /*strict=*/true).loads.empty())
      unimplemented("mem-qram: a clone loading through a QRAM triple formal onto a global QRAM it also stores into "
                    "(a global bus is never popped: the twin would recompute against the stored cells)",
                    &orig);
  IRBuilder<> &B = ctx.B();
  unsigned r = 0;
  SmallVector<std::pair<abi::CoreSpec, SmallVector<Operand, 4>>, 2> pops;   // the call's stores on formals' buses
  for (size_t k = 0; k < stores.size(); ++k) {
    const FormalStore &fs = stores[k];
    auto [bus, idx] = triple.at(fs.argNo);
    Value *v = storedRails[r++];
    if (fs.idxRail) {
      idx = Operand{storedRails[r++], true};
    } else if (fs.cell) {
      if (idx.handle)
        internalError("mem-qram: a store at a constant offset from a quantum idx that M2 does not copy out", fs.at());
      idx = Operand{B.CreateAdd(idx.v, ConstantInt::get(idx.v->getType(), fs.cell, true)), false};
    }
    Value *flag = fs.flagged ? storedRails[r++] : nullptr;
    if (globalBuses.count(bus))
      continue;
    bool global = false;
    const Column *col = columnOfBus(ctx, bus, global);
    RailType w = railTypeOf(fs.ty);
    if (!sameCellType(ctx.M.getDataLayout(), fs.ty, *col))
      unimplemented("mem-qram: a clone storing through a QRAM triple formal at another type than the caller's "
                    "cells (a bit view, 63)",
                    fs.at());
    abi::CoreSpec spec{abi::Core::QramStore, w, flag != nullptr, !idx.handle};
    SmallVector<Operand, 4> ops;
    if (flag)
      ops.push_back(Operand{flag, true});
    ops.append({Operand{bus, true}, idx, Operand{v, true}});
    if (const Value *formal = formalOfBus(ctx, bus)) {
      // M2 through a call: the bus is this clone's own triple formal's, its caller's object. The store is this
      // clone's: popped right after the call (below, last first), deferred like its own stores.
      deferCallStore(ctx, orig, k, formal, *col, idx, v, flag);
      pops.push_back({spec, ops});
      continue;
    }
    ctx.unc().recordCore(fwd, spec, ops, ctx.unc().idOf(bus));
  }
  for (auto it = pops.rbegin(); it != pops.rend(); ++it) {
    abi::CoreSpec spec = it->first;
    spec.unc = true;
    SmallVector<Value *, 4> args;
    for (const Operand &o : it->second)
      args.push_back(o.v);
    CallInst *pop = B.CreateCall(abi::declare(ctx.M, spec), args);
    for (const Operand &o : it->second)
      if (o.handle)
        ctx.unc().noteUse(ctx.unc().idOf(o.v), pop);
  }
}
} // namespace cq::mem
