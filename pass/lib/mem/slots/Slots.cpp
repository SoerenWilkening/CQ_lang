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
//    Its i8 load is bound to that i1 rail when every use truncates it to i1 or compares it (eq/ne) with
//    another _Bool cell load or a constant 0 / 1 (the spine's cell view, cq-nd2i); when no use does, to a
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
#include "SlotsTest.h"
#include "SlotsInternal.h"
#include "../../fatptr/FatPtrInternal.h"

#include <functional>
#include <map>
#include <optional>
#include <set>
#include <tuple>
#include <string>
#include <utility>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Loops.h"
#include "../../fatptr/FatPtrInternal.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/Support/KnownBits.h"
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
#include "llvm/Transforms/Utils/ModuleUtils.h"
#include "../../spine/SpineInternal.h"

using namespace llvm;

namespace cq::mem {

detail::CellsWrittenFn &detail::cellsWrittenOverride() {
  static CellsWrittenFn f;
  return f;
}

namespace {

// ---- addresses ----------------------------------------------------------------------------------

// root + off + sum(term * stride), all in bytes. ok = false when the root is not an object site
// (a phi, select or load of a pointer: no static cell index).
struct Addr {
  const Value *root = nullptr;
  int64_t off = 0;
  SmallVector<std::pair<const Value *, int64_t>, 2> terms;
  bool ok = false;
  const Value *ptr = nullptr;   // the pointer decompose read; it addresses root + off0 + terms
  int64_t off0 = 0;
};

// Scalar evolution of an original function (cq-nd2i), built once per function on first use.
struct SEBundle {
  TargetLibraryInfoImpl TLII;
  TargetLibraryInfo TLI;
  AssumptionCache AC;
  DominatorTree DT;
  LoopInfo LI;
  ScalarEvolution SE;
  explicit SEBundle(Function &F)
      : TLII(Triple(F.getParent()->getTargetTriple())), TLI(TLII, &F), AC(F), DT(F), LI(DT),
        SE(F, TLI, AC, DT, LI) {}
};
ScalarEvolution *seOf(const Value *v) {
  const Function *F = nullptr;
  if (auto *I = dyn_cast<Instruction>(v))
    F = I->getFunction();
  else if (auto *A = dyn_cast<Argument>(v))
    F = A->getParent();
  if (!F || F->isDeclaration())
    return nullptr;
  static std::map<const Function *, std::unique_ptr<SEBundle>> m;
  auto &b = m[F];
  if (!b)
    b = std::make_unique<SEBundle>(const_cast<Function &>(*F));
  return &b->SE;
}

// cq-nd2i (114): two addresses with different variable parts are different cells when scalar evolution
// bounds their byte distance (at the same values of the SSA values they are computed from, the reading
// differentCell has) outside the overlap range: q[m-1-l] against q[m-1] with l >= 2.
bool distantBySCEV(const Addr &a, const Addr &b, uint64_t sizeA, uint64_t sizeB) {
  if (!a.ptr || !b.ptr || !a.ptr->getType()->isPointerTy() || !b.ptr->getType()->isPointerTy())
    return false;
  ScalarEvolution *SE = seOf(isa<Instruction>(a.ptr) || isa<Argument>(a.ptr) ? a.ptr : b.ptr);
  if (!SE || SE != seOf(isa<Instruction>(b.ptr) || isa<Argument>(b.ptr) ? b.ptr : a.ptr))
    return false;
  const SCEV *d = SE->getMinusSCEV(SE->getSCEV(const_cast<Value *>(a.ptr)), SE->getSCEV(const_cast<Value *>(b.ptr)));
  if (isa<SCEVCouldNotCompute>(d) || !d->getType()->isIntegerTy())
    return false;
  ConstantRange r = SE->getSignedRange(d);
  if (r.isFullSet() || r.getBitWidth() > 64)
    return false;
  // a's bytes start at d + (a.off - a.off0) - (b.off - b.off0) from b's.
  int64_t adj = (a.off - a.off0) - (b.off - b.off0);
  APInt lo = r.getSignedMin().sextOrTrunc(64), hi = r.getSignedMax().sextOrTrunc(64);
  bool ov1 = false, ov2 = false;
  APInt A(64, uint64_t(adj), true);
  APInt mn = lo.sadd_ov(A, ov1), mx = hi.sadd_ov(A, ov2);
  if (ov1 || ov2)
    return false;
  return mn.sge(APInt(64, sizeB)) || mx.sle(-APInt(64, sizeA));
}

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
  if (!a.ok || !b.ok || a.root != b.root)
    return false;
  if (a.terms.size() != b.terms.size())
    return distantBySCEV(a, b, sizeA, sizeB);
  for (size_t i = 0; i < a.terms.size(); ++i)
    if (a.terms[i] != b.terms[i])
      return distantBySCEV(a, b, sizeA, sizeB);
  return a.off + int64_t(sizeA) <= b.off || b.off + int64_t(sizeB) <= a.off;
}

Addr decompose(const Value *p, const DataLayout &DL) {
  Addr a;
  a.ptr = p;
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
        // cq-nd2i (114): an index `add X, C` (sub, or disjoint) at the pointer index width is X plus C cells:
        // the GEP's offset arithmetic wraps at that width, so the split is exact. q[m-1] = q + (m - 1) and
        // q[m-2] = (q - 2) + m are then the same variable part and provably different cells.
        while (auto *bo = dyn_cast<BinaryOperator>(idx)) {
          auto *c = dyn_cast<ConstantInt>(bo->getOperand(1));
          if (!c || idx->getType()->getIntegerBitWidth() != DL.getIndexTypeSizeInBits(g->getType()))
            break;
          int64_t k;
          if (bo->getOpcode() == Instruction::Add)
            k = c->getSExtValue();
          else if (bo->getOpcode() == Instruction::Sub)
            k = -c->getSExtValue();
          else if (bo->getOpcode() == Instruction::Or && cast<PossiblyDisjointInst>(bo)->isDisjoint())
            k = c->getSExtValue();
          else
            break;
          a.off += k * stride;
          idx = bo->getOperand(0);
        }
        if (auto *c = dyn_cast<ConstantInt>(idx)) {
          a.off += c->getSExtValue() * stride;
          continue;
        }
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
    // cq-9w75 (CR rule 14 f981c89): a pointer walked by a constant step, phi [start, gep(phi, step)], is
    // start + j*step: a term (phi, step) whose operand is the trip index j a K-loop binds per trip
    // (LoweringContext::walkedPointer). Elsewhere the term is an unknown classical index.
    if (auto *phi = dyn_cast<PHINode>(p); phi && phi->getNumIncomingValues() == 2) {
      const Value *start = nullptr;
      int64_t step = 0;
      for (unsigned k = 0; k < 2 && !start; ++k) {
        auto *g = dyn_cast<GEPOperator>(phi->getIncomingValue(k));
        APInt c(DL.getIndexTypeSizeInBits(phi->getType()), 0);
        const Value *other = phi->getIncomingValue(1 - k);
        if (g && g->getPointerOperand() == phi && g->accumulateConstantOffset(DL, c) && other != phi) {
          start = other;
          step = c.getSExtValue();
        }
      }
      if (start && step != 0) {
        bool merged = false;
        for (auto &t : a.terms)
          if (t.first == phi) {
            t.second += step;
            merged = true;
          }
        if (!merged)
          a.terms.push_back({phi, step});
        p = start;
        continue;
      }
    }
    if (isa<AllocaInst>(p) || isa<Argument>(p) || isa<GlobalVariable>(p) || isa<CallBase>(p)) {
      a.root = p;
      a.ok = true;
      a.off0 = a.off;
      llvm::sort(a.terms, [](const auto &x, const auto &y) { return x.first < y.first; });
      return a;
    }
    return a;
  }
  return a;
}

uint64_t storeBytes(const DataLayout &DL, Type *t) { return DL.getTypeStoreSize(t).getFixedValue(); }

struct ObjInfo;
uint64_t cellSizeAt(const ObjInfo &info, int64_t off, const DataLayout &DL);
int64_t cellOffset(const ObjInfo &info, unsigned c);

// ---- per-object facts ---------------------------------------------------------------------------

enum class RootKind : uint8_t { Local, Heap, Param, Global };

enum class StoreWhat { Register, Seed, Computed, Copy };

struct ObjInfo {
  RootKind kind;
  const Value *root;
  uint64_t cellBytes = 0;
  Type *cellTy = nullptr;   // the cell's C type (the scalar element; for a parameter or heap block, its accesses')
  bool boolCells = false;
  bool escaping = false;
  bool view = false;  // accessed at more than one width: a value object read and written through bit views (63)
  int dynamic = -1;   // -1 not computed
  // A slot RECORD (rules 20, 26: an sret/byval struct, 163 164 70, or a local struct object): one cell per
  // scalar field at its own offset; a handle field is an i32 cell, a classical field keeps its C type and
  // its value in memory. recTy is the new layout (a literal struct of the cells). cellBytes is 0.
  bool record = false;
  // cq-oocu (CR rules 20, 21; 107): a field of POINTER KIND (its type a pointer) holds a fat pointer as two
  // i32 handles, tag then idx, at recTy elements rec and rec + 1; every other cell is recTy element rec.
  struct Field { int64_t off; Type *ty; int handle = -1; unsigned rec = 0; };   // handle: -1 not decided
  SmallVector<Field, 4> fields;
  StructType *recTy = nullptr;
  // A BYTE-CELL object (90): a local scalar object that a memory intrinsic writes and that is read at a
  // narrower width than its type: its cells are the narrowest access width (90's `unsigned char d[4]` that
  // -O1 made an alloca i32); a wider classical store is split into one write per cell (little-endian).
  bool split = false;
  // A FIELD COLUMN (rule 20, 129's guarded_field_store): taint names one object per scalar field column of a
  // local array of structs; a column holding handles keeps the array's own layout (the classical columns keep
  // their C values in memory), the handle in the first 4 bytes of each of its fields (colBytes >= 4). Cell c
  // is at byte colOff + c * colStride. colStride 0: not a column.
  uint64_t colStride = 0;
  int64_t colOff = 0;
};

// The byte distance of consecutive cells.
uint64_t cellStride(const ObjInfo &info) { return info.colStride ? info.colStride : info.cellBytes; }

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
  std::unique_ptr<LoopInfo> LI;
  DenseMap<const Instruction *, Operand> lowered;   // slot load / store -> the handle the cell holds after it
  // cq-oocu (107): an access of a pointer-kind cell -> the idx handle the cell holds after it (lowered: the tag).
  DenseMap<const Instruction *, Operand> loweredIdx;
  DenseSet<const Value *> registers;                // new-IR handles known never to be resolved here
  DenseSet<const Instruction *> copies;             // slot stores lowered as a basis copy (cq-dr4o)
  DenseSet<const Value *> seeds;                    // cq-bfz4: seeds of dynamic cells kept as Role::Seed
  DenseMap<const Instruction *, ViewVal> views;     // stores into a view object -> the value they left (63)
  struct CellRead { const Instruction *I; Addr a; uint64_t size; LoadInst *h = nullptr; };
  SmallVector<CellRead, 8> cellReads;               // accesses lowered as a run-time read of a local cell (M3)
  std::map<std::pair<const Value *, int>, ObjInfo> objs;   // (root, field column or -1)
  // M1: a clone call handed a pointer into a slot object -> (byte offset of a cell it writes -> the handle
  // the caller loaded from that cell right after the call: slotCellsAfterCall).
  DenseMap<const Instruction *, std::map<int64_t, Operand>> callOut;
  // A clone's stores into a caller cell under quantum predicates (51): (block predicate, value) per store
  // lowered so far, keyed by the cell's byte offset; merged into one slot result at the last of them.
  std::map<int64_t, std::vector<std::pair<Pred, Operand>>> cloneArms;
  // cq-vxgm (rule 20 guarded store): a caller cell a clone writes on some returning paths only, keyed by
  // (formal, byte offset): the caller's handle loaded at the clone's entry and the fresh slot result f the
  // clone stores into the cell there (f = old; each arm store makes it the stored value).
  std::map<std::pair<const Value *, int64_t>, std::pair<Value *, Value *>> guardedCells;
  // Register updates (CR rules 6, 20; 114): per object, whether its every store has a register-update
  // shape (1) or not (0); the new-IR base of each object that has one; the cqrt_free of each old rail they
  // cleaned (finishSlots checks the items of the rails' other readers against them).
  std::map<ObjectId, int> ruShape;
  std::map<ObjectId, Value *> ruBase;
  SmallVector<CallInst *, 8> ruFrees;
  // Rule 7 (129): seeds in a dynamic object's cells that no user register enters, per root: released at the
  // object's lifetime end.
  std::map<const Value *, SmallVector<Value *, 4>> releasable;
  // M7 (129): a store through a fat pointer over local slot objects, or a clone call handed one, -> (root,
  // byte offset of a cell it wrote -> the handle it left there).
  DenseMap<const Instruction *, std::map<std::pair<const Value *, int64_t>, Operand>> fatOut;
  // 102 (program slots, see programSlot): the content of each program slot along an entry. SEEDED: a seed
  // of the classical value v (the constructor's initializer at the entry's start). WRITTEN: one guarded store
  // of a _ctl clone call left R = flag ? s : vold in the slot; old is the handle the slot held before it.
  struct ProgSlot {
    Value *v = nullptr;
    bool written = false;
    Value *flag = nullptr, *s = nullptr, *old = nullptr;
  };
  std::map<const GlobalVariable *, ProgSlot> progSlots;
  DenseSet<const Instruction *> progSlotCalls;   // original calls noteProgramSlotCall recorded
  // cq-r8-d (CR rule 27 Pointers; 190): a declared clone call handed a pointer into a local slot object ->
  // its twin's pseudo rail (Uncompute U7) and the handles the object's cells held at the call, by byte
  // offset (a later read of a cell names the clone's new handle or the old one).
  struct Declared { RailId pseudo; std::map<int64_t, Operand> atCall; };
  DenseMap<const Instruction *, Declared> declared;
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

// A host effect (rule 16) never runs in the lowered program: its tape entry reads the cells it is handed
// (readSlotCells, 99) and writes none.
bool isHostEffect(LoweringContext &ctx, const CallBase &CB) {
  return calls::classify(CB, ctx.T, ctx.S) == calls::Class::HostEffect;
}

// M1 (CR rules 18, 20): a call of a quantum clone (rule 18). A slot object handed to one through a pointer
// that the call does not capture is not an escape: the clone accesses the caller's cells while it runs and
// writes exactly the cells TaintInfo::cellsWritten names (the caller loads their new handles right after
// the call, slotCellsAfterCall).
// Rule 24 (106): pthread_create(t, attr, f, p) with a defined start routine f is lowered as the direct call
// f(p) (calls::lowerLiftedVia, argMap {3}); its start routine, else null.
const Function *threadStart(const CallBase &CB) {
  const Function *g = CB.getCalledFunction();
  if (!g || g->getName() != "pthread_create" || CB.arg_size() != 4)
    return nullptr;
  auto *f = dyn_cast<Function>(CB.getArgOperand(2)->stripPointerCasts());
  return f && !f->isDeclaration() && f->arg_size() == 1 ? f : nullptr;
}

const Specialization *cloneCallee(LoweringContext &ctx, const CallBase &CB) {
  const Function *f = CB.getCalledFunction();
  if (threadStart(CB)) {
    const Specialization *S = ctx.T.calleeSpecialization(CB, ctx.S);
    return S && !S->isEntry() ? S : nullptr;
  }
  if (!f || f->isDeclaration() || isa<IntrinsicInst>(CB))
    return nullptr;
  return ctx.T.calleeSpecialization(CB, ctx.S);
}

// cq-r8-d: X is a declared clone call (rule 27) that st's lowering registered (declaredCells) or will:
// a call handed a pointer into object o through declaredArgUse.
bool declaredArgUse(LoweringContext &ctx, const CallBase &CB, const Use &u);
bool hasObjectArg(LoweringContext &ctx, const Instruction &X, ObjectId o) {
  if (auto *CB = dyn_cast<CallBase>(&X))
    for (const Use &u : CB->args())
      if (hasObject(ctx, u.get(), o))
        return true;
  return false;
}
bool declaredCallOn(LoweringContext &ctx, const Instruction &X, ObjectId o) {
  auto *CB = dyn_cast<CallBase>(&X);
  if (!CB)
    return false;
  for (const Use &u : CB->args())
    if (hasObject(ctx, u.get(), o) && declaredArgUse(ctx, *CB, u))
      return true;
  return false;
}

// The callee's formals of a clone call and the site operand each one takes (M1b: a lifted thread call's
// formal 0 is operand 3).
unsigned numFormals(const CallBase &CB) { return threadStart(CB) ? 1 : CB.arg_size(); }
const Value *formalActual(const CallBase &CB, unsigned k) { return CB.getArgOperand(threadStart(CB) ? 3 : k); }

SmallVector<unsigned, 4> cellsWrittenBy(LoweringContext &ctx, const Specialization &S, unsigned argNo) {
  if (detail::cellsWrittenOverride())
    return detail::cellsWrittenOverride()(S, argNo);
  return ctx.T.cellsWritten(S, argNo);
}

// T5 (109): cell c of formal argNo is filled by the clone with formal j's handle unchanged (cellForward):
// j, else -1.
int forwardedFrom(LoweringContext &ctx, const Specialization &S, unsigned argNo, unsigned c) {
  if (detail::cellsWrittenOverride())
    return -1;
  return ctx.T.cellForward(S, argNo, c);
}

// The cells of formal argNo the clone fills with a rail it mints (its slot results, undone by the twin).
SmallVector<unsigned, 4> cellsMintedBy(LoweringContext &ctx, const Specialization &S, unsigned argNo) {
  SmallVector<unsigned, 4> out;
  for (unsigned c : cellsWrittenBy(ctx, S, argNo))
    if (forwardedFrom(ctx, S, argNo, c) < 0)
      out.push_back(c);
  return out;
}

// The callee's formal A is never captured: its value reaches only addresses of loads, stores, atomics and
// memory intrinsics (through GEPs, casts, phis and selects), compares, and formals of callees that capture
// nothing either (-O1 leaves `nocapture` off some internal callees: 51's split).
bool formalNotCaptured(const Argument &A, unsigned depth = 0) {
  if (depth > 8)
    return false;
  SmallVector<const Value *, 8> work{&A};
  SmallPtrSet<const Value *, 16> seen{&A};
  while (!work.empty()) {
    const Value *v = work.pop_back_val();
    for (const Use &u : v->uses()) {
      const User *usr = u.getUser();
      if (auto *ld = dyn_cast<LoadInst>(usr); ld && ld->getPointerOperand() == v)
        continue;
      if (auto *st = dyn_cast<StoreInst>(usr); st && st->getPointerOperand() == v && st->getValueOperand() != v)
        continue;
      if (isa<ICmpInst>(usr))
        continue;
      if (isa<GetElementPtrInst>(usr) || isa<CastInst>(usr) || isa<PHINode>(usr) || isa<SelectInst>(usr)) {
        if (seen.insert(usr).second)
          work.push_back(usr);
        continue;
      }
      if (auto *CB = dyn_cast<CallBase>(usr)) {
        if (isa<DbgInfoIntrinsic>(CB) || isa<MemIntrinsic>(CB))
          continue;
        if (auto *II = dyn_cast<IntrinsicInst>(CB); II && II->isLifetimeStartOrEnd())
          continue;
        if (!CB->isArgOperand(&u))
          return false;
        unsigned i = CB->getArgOperandNo(&u);
        if (CB->doesNotCapture(i))
          continue;
        const Function *g = CB->getCalledFunction();
        if (g && !g->isDeclaration() && i < g->arg_size() && formalNotCaptured(*g->getArg(i), depth + 1))
          continue;
        return false;
      }
      return false;
    }
  }
  return true;
}

bool cloneArgUse(LoweringContext &ctx, const CallBase &CB, const Use &u) {
  if (!CB.isArgOperand(&u))
    return false;
  unsigned i = CB.getArgOperandNo(&u);
  if (const Function *f = threadStart(CB))
    return i == 3 && formalNotCaptured(*f->getArg(0)) && cloneCallee(ctx, CB);
  const Function *g = CB.getCalledFunction();
  bool noCapture = CB.doesNotCapture(i) || CB.isByValArgument(i) ||
                   (g && !g->isDeclaration() && i < g->arg_size() && formalNotCaptured(*g->getArg(i)));
  return noCapture && cloneCallee(ctx, CB);
}

// cq-z6q1 (CR rules 20, 21; 189): a pointer stored as a value into a block of this function (an alloca or a
// noalias allocation call, at a classical address naming it alone) stays inside the function as long as the
// block does and every pointer loaded back from the block does: the block's site and those loads (through
// any pointer whose provenance names the block, a fat pointer's among them) join the walk.
bool storedLocally(LoweringContext &ctx, const StoreInst &st, SmallVectorImpl<const Value *> &work,
                   SmallPtrSetImpl<const Value *> &seen) {
  if (st.isVolatile() || st.isAtomic() || ctx.T.isFatPointer(st.getPointerOperand(), ctx.S))
    return false;
  const Value *dst = getUnderlyingObject(st.getPointerOperand());
  auto *DI = dyn_cast<Instruction>(dst);
  auto *CB = dyn_cast_or_null<CallBase>(DI);
  if (!DI || DI->getFunction() != st.getFunction() ||
      !(isa<AllocaInst>(DI) || (CB && CB->hasRetAttr(Attribute::NoAlias) && CB->getFnAttr(Attribute::AllocKind).isValid())))
    return false;
  ArrayRef<ObjectId> dobj = ctx.T.provenance(st.getPointerOperand(), ctx.S);
  if (dobj.size() != 1)
    return false;
  for (const Instruction &I : instructions(*st.getFunction()))
    if (auto *MI = dyn_cast<MemTransferInst>(&I);
        MI && llvm::is_contained(ctx.T.provenance(MI->getSource(), ctx.S), dobj.front()))
      return false;   // the block's pointers copied elsewhere
  if (seen.insert(dst).second)
    work.push_back(dst);
  for (const Instruction &I : instructions(*st.getFunction()))
    if (auto *ld = dyn_cast<LoadInst>(&I); ld && ld->getType()->isPointerTy() &&
                                            llvm::is_contained(ctx.T.provenance(ld->getPointerOperand(), ctx.S),
                                                               dobj.front()))
      if (seen.insert(ld).second)
        work.push_back(ld);
  return true;
}

// cq-r8-d (CR rule 27 Pointers; 190): a pointer argument of a void call of a function with no body that
// rule 27 lowers (calls::lowerDeclared): the caller snapshots the object's cells before the call, the
// clone may overwrite them with handles it minted, and its twin, after the last read of a cell, restores
// every cell. The object stays the caller's: not an escape.
bool declaredArgUse(LoweringContext &ctx, const CallBase &CB, const Use &u) {
  const Function *f = CB.getCalledFunction();
  if (!CB.isArgOperand(&u) || !f || !f->isDeclaration() || isa<IntrinsicInst>(CB) || !CB.getType()->isVoidTy())
    return false;
  return calls::classify(CB, ctx.T, ctx.S) == calls::Class::Declared;
}

bool escapes(LoweringContext &ctx, const Value *root) {
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
        if (st->getPointerOperand() != v && storedLocally(ctx, *st, work, seen))
          continue;   // cq-z6q1 (189): a classical pointer field of a local or heap block of this function
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
        if (isHostEffect(ctx, *CB))
          continue;   // a tape entry reads the cells (99)
        if (cloneArgUse(ctx, *CB, u))
          continue;   // M1: the clone's accesses are the call's (slotCellsBeforeCall / After)
        if (declaredArgUse(ctx, *CB, u))
          continue;   // rule 27: a snapshot before the call, the twin restores the cells (declaredCells)
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

// A wide classical store split over one-byte cells (cq-muau) whose every byte is 0 or 1.
bool splitBoolBytes(const Value *v) {
  auto *c = dyn_cast<ConstantInt>(v);
  if (!c || c->getBitWidth() % 8)
    return false;
  for (unsigned k = 0; k < c->getBitWidth() / 8; ++k)
    if (c->getValue().extractBitsAsZExtValue(8, 8 * k) > 1)
      return false;
  return true;
}

bool boolRange(const LoadInst *ld) {
  MDNode *r = ld->getMetadata(LLVMContext::MD_range);
  if (!r || r->getNumOperands() != 2)
    return false;
  auto *lo = mdconst::dyn_extract<ConstantInt>(r->getOperand(0));
  auto *hi = mdconst::dyn_extract<ConstantInt>(r->getOperand(1));
  return lo && hi && lo->isZero() && hi->getZExtValue() == 2;
}

Type *scalarCellType(Type *t) {
  while (auto *at2 = dyn_cast<ArrayType>(t))
    t = at2->getElementType();
  return t;
}

uint64_t scalarCellBytes(Type *t, const DataLayout &DL, const Value *at) {
  t = scalarCellType(t);
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

void flattenRecord(Type *t, int64_t off, const DataLayout &DL, SmallVectorImpl<ObjInfo::Field> &out,
                   const Value *at) {
  if (auto *st = dyn_cast<StructType>(t)) {
    const StructLayout *SL = DL.getStructLayout(st);
    for (unsigned k = 0; k < st->getNumElements(); ++k)
      flattenRecord(st->getElementType(k), off + int64_t(SL->getElementOffset(k)), DL, out, at);
    return;
  }
  if (auto *a = dyn_cast<ArrayType>(t)) {
    int64_t es = int64_t(DL.getTypeAllocSize(a->getElementType()).getFixedValue());
    for (uint64_t k = 0; k < a->getNumElements(); ++k)
      flattenRecord(a->getElementType(), off + int64_t(k) * es, DL, out, at);
    return;
  }
  if (!t->isIntegerTy() && !t->isFloatingPointTy() && !t->isPointerTy())
    unimplemented("mem-slots: a slot record with a field that is not an integer, floating point or pointer (a "
                  "vector field)",
                  at);
  out.push_back(ObjInfo::Field{off, t});
}

// The struct type of a record root: a local struct object, or an sret/byval parameter (rule 26).
StructType *recordType(const Value *root) {
  if (auto *ai = dyn_cast<AllocaInst>(root)) {
    Type *t = ai->getAllocatedType();
    if (isa<ArrayType>(t) && scalarCellType(t)->isStructTy())
      unimplemented("mem-slots: an array of structs holding handles (one slot array per field column, 168)", ai);
    return dyn_cast<StructType>(t);
  }
  if (auto *A = dyn_cast<Argument>(root)) {
    Type *t = A->getParamByValType();
    if (!t)
      t = A->getParamStructRetType();
    return t ? dyn_cast<StructType>(t) : nullptr;
  }
  return nullptr;
}

int fieldAt(const ObjInfo &info, int64_t off) {
  for (unsigned k = 0; k < info.fields.size(); ++k)
    if (info.fields[k].off == off)
      return int(k);
  return -1;
}

// The store size of the cell at byte offset off (a record's field there; 0 when no field starts there).
uint64_t cellSizeAt(const ObjInfo &info, int64_t off, const DataLayout &DL) {
  if (!info.record)
    return info.cellBytes;
  int k = fieldAt(info, off);
  return k < 0 ? 0 : storeBytes(DL, info.fields[unsigned(k)].ty);
}

// The byte offset of cell c from the object's start (a record's field c).
int64_t cellOffset(const ObjInfo &info, unsigned c) {
  if (info.colStride)
    return info.colOff + int64_t(c * info.colStride);
  if (!info.record)
    return int64_t(c * info.cellBytes);
  if (c >= info.fields.size())
    internalError("mem-slots: a cell index past the record's fields");
  return info.fields[c].off;
}

// cq-z6q1 (CR rules 20, 21; 189): a HEAP RECORD. A heap block of constant size whose accesses are at
// classical constant byte offsets of more than one type (189's `struct node { int v; struct node *next; }`)
// is a record: one cell per accessed field, at its own offset and of its own type (rule 20 per cell: a handle
// field is an i32 cell, a classical field keeps its type and its value in host memory; a pointer field must
// be classical). Accesses through a fat pointer naming the block (rule 21) are fatptr's: they are checked
// there against the fields. The block stays the host allocation: the new layout (the cells' literal struct)
// must keep every field's offset and fit the block. Fields overlapping, a run-time offset, or a memory
// intrinsic: unimplemented.
bool heapRecord(LoweringContext &ctx, FnState &st, ObjInfo &info, ObjectId o) {
  const DataLayout &DL = ctx.M.getDataLayout();
  SmallVector<Access, 8> acc = accessesOf(ctx, *st.F, o);
  auto fat = [&](const Access &a) { return !a.a.ok && ctx.T.isFatPointer(accessPtr(a.I), ctx.S); };
  std::optional<uint64_t> width;
  bool widths = false;
  for (const Access &a : acc) {
    if (fat(a))
      continue;
    uint64_t b = DL.getTypeAllocSize(a.ty).getFixedValue();
    widths |= width && *width != b;
    width = b;
  }
  if (!widths)
    return false;   // one cell width: a slot array (a pointer cell type stays unimplemented there)
  std::optional<uint64_t> size;
  if (auto *CB = dyn_cast<CallBase>(info.root)) {
    Attribute as = CB->getFnAttr(Attribute::AllocSize);
    if (as.isValid() && !as.getAllocSizeArgs().second)
      if (auto *n = dyn_cast<ConstantInt>(CB->getArgOperand(as.getAllocSizeArgs().first)))
        size = n->getZExtValue();
  }
  if (!size)
    unimplemented("mem-slots: a heap block accessed at several types that is not of one constant allocsize (a "
                  "heap record's extent)",
                  info.root);
  for (const Instruction &X : instructions(*st.F))
    if (auto *MI = dyn_cast<MemIntrinsic>(&X); MI && hasObject(ctx, MI->getDest(), o))
      unimplemented("mem-slots: a memory intrinsic on a heap record", &X);
  std::map<int64_t, Type *> fields;
  for (const Access &a : acc) {
    if (fat(a))
      continue;
    if (!a.a.ok)
      unimplemented("mem-slots: a heap record accessed through a pointer of no static offset", a.I);
    if (!a.a.terms.empty() || a.a.root != info.root)
      unimplemented("mem-slots: a heap record accessed at a run-time offset", a.I);
    if (!a.ty->isIntegerTy() && !a.ty->isFloatingPointTy() && !a.ty->isPointerTy())
      unimplemented("mem-slots: a heap record field that is not a scalar or a pointer", a.I);
    auto [it, fresh] = fields.insert({a.a.off, a.ty});
    if (!fresh && it->second != a.ty)
      unimplemented("mem-slots: a heap record field accessed at two types (a bit view, 63)", a.I);
  }
  int64_t end = 0;
  for (auto &[off, ty] : fields) {
    if (off < end)
      unimplemented("mem-slots: overlapping fields of a heap record (a bit view, 63)", info.root);
    end = off + int64_t(storeBytes(DL, ty));
    info.fields.push_back(ObjInfo::Field{off, ty});
  }
  if (end > int64_t(*size))
    unimplemented("mem-slots: a heap record field past its block", info.root);
  info.record = true;
  return true;
}

// The struct element of a local array of structs that taint splits into one object per scalar field column
// (rule 20; taint's splitSite: two or more fields, none an aggregate or vector), else null.
StructType *columnStruct(const Value *root) {
  auto *ai = dyn_cast<AllocaInst>(root);
  auto *at = ai ? dyn_cast<ArrayType>(ai->getAllocatedType()) : nullptr;
  auto *stt = at ? dyn_cast<StructType>(at->getElementType()) : nullptr;
  if (!stt || stt->getNumElements() < 2)
    return nullptr;
  for (Type *e : stt->elements())
    if (e->isAggregateType() || e->isVectorTy())
      return nullptr;
  return stt;
}

// The field column object o is of such an array (its accesses' offsets modulo the element size, the field
// at or below it, as taint assigns them), or -1 when root is no such array. Every access of o agrees.
int columnOf(LoweringContext &ctx, FnState &st, const Value *root, ObjectId o) {
  StructType *stt = columnStruct(root);
  if (!stt)
    return -1;
  const DataLayout &DL = ctx.M.getDataLayout();
  const StructLayout *SL = DL.getStructLayout(stt);
  int64_t E = int64_t(DL.getTypeAllocSize(stt).getFixedValue());
  int col = -1;
  for (const Access &a : accessesOf(ctx, *st.F, o)) {
    if (!a.a.ok || a.a.root != root)
      unimplemented("mem-slots: a field column accessed through a pointer that is not the array plus GEP offsets",
                    a.I);
    for (auto &t : a.a.terms)
      if (t.second % E)
        unimplemented("mem-slots: a field column accessed at a run-time offset that is not a whole number of "
                      "elements",
                      a.I);
    int64_t m = ((a.a.off % E) + E) % E;
    int c = -1;
    for (unsigned k = 0; k < stt->getNumElements(); ++k)
      if (int64_t(SL->getElementOffset(k)) <= m)
        c = int(k);
    if (c < 0 || int64_t(SL->getElementOffset(unsigned(c))) != m)
      unimplemented("mem-slots: a field column accessed inside a field (a bit view, 63)", a.I);
    if (col >= 0 && col != c)
      internalError("mem-slots: an object whose accesses lie in two field columns", a.I);
    col = c;
  }
  if (col < 0)
    unimplemented("mem-slots: a field column this function never accesses", root);
  return col;
}

ObjInfo &objInfo(LoweringContext &ctx, FnState &st, const Value *root, ObjectId o) {
  int col = columnOf(ctx, st, root, o);
  auto it = st.objs.find({root, col});
  if (it != st.objs.end())
    return it->second;
  const DataLayout &DL = ctx.M.getDataLayout();
  ObjInfo info;
  info.root = root;
  if (col >= 0) {
    // Rule 20 (129): one field column of a local array of structs, at its own offset in each element.
    auto *ai = cast<AllocaInst>(root);
    auto *stt = cast<StructType>(cast<ArrayType>(ai->getAllocatedType())->getElementType());
    info.kind = RootKind::Local;
    info.cellTy = stt->getElementType(unsigned(col));
    info.cellBytes = scalarCellBytes(info.cellTy, DL, ai);
    if (info.cellBytes < 4)
      unimplemented("mem-slots: a field column holding handles whose fields are narrower than a handle (an array "
                    "of structs keeps its layout, rule 20)",
                    ai);
    info.colStride = DL.getTypeAllocSize(stt).getFixedValue();
    info.colOff = int64_t(DL.getStructLayout(stt)->getElementOffset(unsigned(col)));
    info.escaping = escapes(ctx, root);
    for (const Access &a : accessesOf(ctx, *st.F, o))
      if (DL.getTypeAllocSize(a.ty).getFixedValue() != info.cellBytes)
        unimplemented("mem-slots: a field column accessed at another width than its field (a bit view, 63)", a.I);
    for (const Instruction &X : instructions(*st.F))
      if (auto *MI = dyn_cast<MemIntrinsic>(&X); MI && hasObject(ctx, MI->getDest(), o))
        unimplemented("mem-slots: a memory intrinsic writing a field column holding handles (rule 22)", &X);
    if (info.cellBytes == 1)
      internalError("mem-slots: a one-byte field column");
    return st.objs.emplace(std::make_pair(root, col), info).first->second;
  }
  if (StructType *rt = recordType(root)) {
    info.kind = isa<AllocaInst>(root) ? RootKind::Local : RootKind::Param;
    info.record = true;
    flattenRecord(rt, 0, DL, info.fields, root);
    info.escaping = escapes(ctx, root);
    return st.objs.emplace(std::make_pair(root, col), info).first->second;
  }
  if (auto *ai = dyn_cast<AllocaInst>(root)) {
    info.kind = RootKind::Local;
    info.cellBytes = scalarCellBytes(ai->getAllocatedType(), DL, ai);
    info.cellTy = scalarCellType(ai->getAllocatedType());
  } else if (auto *gv = dyn_cast<GlobalVariable>(root)) {
    info.kind = RootKind::Global;
    info.cellBytes = scalarCellBytes(gv->getValueType(), DL, gv);
    info.cellTy = scalarCellType(gv->getValueType());
  } else {
    info.kind = isa<Argument>(root) ? RootKind::Param : RootKind::Heap;
    if (info.kind == RootKind::Heap && heapRecord(ctx, st, info, o)) {
      info.escaping = escapes(ctx, root);
      return st.objs.emplace(std::make_pair(root, col), info).first->second;
    }
    for (const Access &a : accessesOf(ctx, *st.F, o)) {
      uint64_t b = DL.getTypeAllocSize(a.ty).getFixedValue();
      if (info.cellBytes && info.cellBytes != b)
        unimplemented("mem-slots: a parameter or heap slot object accessed at two widths (a bit view, 63)", a.I);
      info.cellBytes = b;
      info.cellTy = a.ty;
    }
    if (!info.cellBytes)
      unimplemented("mem-slots: a parameter or heap slot object this function never loads or stores (its cell "
                    "size is known only to another function)",
                    root);
  }
  info.escaping = escapes(ctx, root);
  if (info.kind == RootKind::Local) {
    uint64_t narrow = info.cellBytes;
    for (const Access &a : accessesOf(ctx, *st.F, o))
      narrow = std::min(narrow, uint64_t(DL.getTypeAllocSize(a.ty).getFixedValue()));
    bool intrinsic = false;
    for (const Instruction &X : instructions(*st.F))
      if (auto *MI = dyn_cast<MemIntrinsic>(&X); MI && hasObject(ctx, MI->getDest(), o))
        intrinsic = true;
    if (intrinsic && narrow < info.cellBytes && info.cellTy->isIntegerTy()) {
      // 90: byte cells. Every wider access must be a classical store (split per cell).
      for (const Access &a : accessesOf(ctx, *st.F, o)) {
        if (DL.getTypeAllocSize(a.ty).getFixedValue() == narrow)
          continue;
        auto *S = dyn_cast<StoreInst>(a.I);
        if (!S || !S->getValueOperand()->getType()->isIntegerTy() || ctx.T.isQuantum(S->getValueOperand(), ctx.S))
          unimplemented("mem-slots: a byte-cell slot object (a memory intrinsic writes it) accessed wider than its "
                        "cells by other than a classical integer store",
                        a.I);
      }
      info.split = true;
      info.cellBytes = narrow;
      info.cellTy = IntegerType::get(ctx.M.getContext(), unsigned(8 * narrow));
    } else {
      // cq-muau (120): an object of integer cells whose only accesses at another width are classical integer
      // stores at constant offsets covering whole cells (-O1's `bool q[2][2] = {0}` as one i32 store) keeps
      // its cells; each such store is split into one write per cell (as 90's), so the cells may still be
      // accessed at run-time offsets. Any other access at another width makes it a view object (63).
      bool other = false, wideStore = false;
      for (const Access &a : accessesOf(ctx, *st.F, o)) {
        uint64_t b = DL.getTypeAllocSize(a.ty).getFixedValue();
        if (b == info.cellBytes)
          continue;
        auto *S = dyn_cast<StoreInst>(a.I);
        if (S && info.cellTy->isIntegerTy() && S->getValueOperand()->getType()->isIntegerTy() &&
            !ctx.T.isQuantum(S->getValueOperand(), ctx.S) && a.a.ok && a.a.terms.empty() &&
            storeBytes(DL, a.ty) % info.cellBytes == 0 && a.a.off % int64_t(info.cellBytes) == 0)
          wideStore = true;
        else
          other = true;
      }
      if (other)
        info.view = true;
      else if (wideStore)
        info.split = true;
    }
  }
  if (info.cellBytes == 1 && !info.view) {
    bool any = false, all = true;
    for (const Access &a : accessesOf(ctx, *st.F, o)) {
      any = true;
      if (auto *ld = dyn_cast<LoadInst>(a.I))
        all &= boolRange(ld);
      else if (auto *sti = dyn_cast<StoreInst>(a.I))
        all &= boolValueStored(sti->getValueOperand()) ||
               (info.split && splitBoolBytes(sti->getValueOperand()));
      else
        all = false;
    }
    info.boolCells = any && all;
  }
  return st.objs.emplace(std::make_pair(root, col), info).first->second;
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
  if (auto *MI = dyn_cast<MemIntrinsic>(CB)) {
    if (!hasObject(ctx, MI->getDest(), o))
      return false;
    // cq-597j: the intrinsic writes bytes [dest, dest + len) only, len at most its upper bound (LLVM's known
    // bits and range facts, as mem-qram's rule-22 cells: 90's memcpy of x & 3 bytes never reaches d[3]).
    Addr d = decompose(MI->getDest(), DL);
    if (!d.ok || !d.terms.empty() || !cell.ok || !cell.terms.empty() || d.root != cell.root)
      return true;
    const Value *len = MI->getLength();
    APInt b = APIntOps::umin(computeKnownBits(len, DL).getMaxValue(),
                             computeConstantRange(len, /*ForSigned=*/false).getUnsignedMax());
    if (b.getActiveBits() > 40)
      return true;
    int64_t n = int64_t(b.getZExtValue());
    return cell.off + int64_t(size) > d.off && cell.off < d.off + n;
  }
  if (CB->onlyReadsMemory() || isHostEffect(ctx, *CB))
    return false;
  if (info.kind == RootKind::Global && !info.escaping && cast<GlobalVariable>(info.root)->hasLocalLinkage())
    return callMayTouchInternalGlobal(*CB, *cast<GlobalVariable>(info.root));
  if ((info.kind == RootKind::Local || info.kind == RootKind::Heap) && !info.escaping)
    if (const Specialization *S = cloneCallee(ctx, *CB)) {
      // M1: the clone writes the cells cellsWritten names, at their offsets from the pointer it is handed.
      for (unsigned i = 0; i < numFormals(*CB); ++i) {
        if (!hasObject(ctx, formalActual(*CB, i), o))
          continue;
        Addr pa = decompose(formalActual(*CB, i), DL);
        if (!pa.ok || !pa.terms.empty())
          return true;
        if (info.record) {
          // The clone may write any classical field (a classical store, not a handle: T2 names handles).
          int k = cell.terms.empty() ? fieldAt(info, cell.off) : -1;
          if (k < 0 || info.fields[unsigned(k)].handle != 1)
            return true;
        }
        for (unsigned c : cellsWrittenBy(ctx, *S, i)) {
          Addr w = pa;
          w.off += cellOffset(info, c);
          if (!differentCell(w, cell, cellSizeAt(info, w.off, DL), size))
            return true;
        }
        // cq-nyto (1): a clone rotating the cell in place (T3 cellsRotated) changes its rail's state though
        // not its handle: a later read does not forward the handle stored before the call (rule 2's
        // classical re-read would see a seed's or a measured rail's old value). The read is a run-time read
        // of the cell (the object is dynamic: its cells are registers, 124's r).
        for (unsigned c : ctx.T.cellsRotated(*S, i)) {
          if (c == TaintInfo::kAnyCell)
            return true;   // cq-budv: a rotation at a variable offset may hit any cell
          Addr w = pa;
          w.off += cellOffset(info, c);
          if (!differentCell(w, cell, cellSizeAt(info, w.off, DL), size))
            return true;
        }
      }
      return false;
    }
  if (info.escaping || info.kind == RootKind::Param || info.kind == RootKind::Global)
    return true;
  for (const Use &u : CB->args())
    if (hasObject(ctx, u.get(), o))
      return true;
  return false;
}

// M1: the clone call X writes exactly the cell at `cell` (size bytes) of object o.
bool cloneWritesCell(LoweringContext &ctx, const ObjInfo &info, ObjectId o, const Instruction &X, const Addr &cell,
                     uint64_t size) {
  auto *CB = dyn_cast<CallBase>(&X);
  const Specialization *S = CB ? cloneCallee(ctx, *CB) : nullptr;
  if (!S)
    return false;
  for (unsigned i = 0; i < numFormals(*CB); ++i) {
    if (!hasObject(ctx, formalActual(*CB, i), o))
      continue;
    Addr pa = decompose(formalActual(*CB, i), ctx.M.getDataLayout());
    if (!pa.ok || !pa.terms.empty())
      continue;
    for (unsigned c : cellsWrittenBy(ctx, *S, i)) {
      Addr w = pa;
      w.off += cellOffset(info, c);
      if (sameCell(w, cell) && size == cellSizeAt(info, w.off, ctx.M.getDataLayout()))
        return true;
    }
  }
  return false;
}

// M6: X writes exactly this cell per cell: a memory intrinsic lowered through writeSlotCells (the cells
// below its length's upper bound, mem-qram's rule-22 cells) or a classical store wider than its byte cells
// (90's punned initializer, one seed per cell). Structural (cq-597j b): it does not depend on whether X
// has been lowered yet (isDynamic asks before), so readCell finds the cell's handle in callOut once it has.
bool namedWrite(LoweringContext &ctx, const Instruction &X, const Addr &cell, uint64_t size, const ObjInfo &info) {
  const DataLayout &DL = ctx.M.getDataLayout();
  if (!cell.ok || !cell.terms.empty() || cell.root != info.root || size != info.cellBytes || !info.cellBytes)
    return false;
  int64_t from = 0, n = 0;
  if (auto *MI = dyn_cast<MemIntrinsic>(&X)) {
    Addr d = decompose(MI->getDest(), DL);
    if (!d.ok || !d.terms.empty() || d.root != info.root)
      return false;
    const Value *len = MI->getLength();
    APInt b = APIntOps::umin(computeKnownBits(len, DL).getMaxValue(),
                             computeConstantRange(len, /*ForSigned=*/false).getUnsignedMax());
    if (b.getActiveBits() > 40)
      return false;
    from = d.off;
    n = int64_t((b.getZExtValue() + info.cellBytes - 1) / info.cellBytes * info.cellBytes);
  } else if (auto *S = dyn_cast<StoreInst>(&X); S && info.split) {
    uint64_t w = storeBytes(DL, S->getValueOperand()->getType());
    Addr d = decompose(S->getPointerOperand(), DL);
    if (w == info.cellBytes || !d.ok || !d.terms.empty() || d.root != info.root)
      return false;
    from = d.off;
    n = int64_t(w);
  } else {
    return false;
  }
  return cell.off >= from && cell.off < from + n && (cell.off - from) % int64_t(info.cellBytes) == 0;
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
  // M1: a clone call that writes the cell leaves there the handle the caller loads right after it.
  if ((info.kind == RootKind::Local || info.kind == RootKind::Heap) && !info.escaping)
    for (const Instruction &X : instructions(*st.F))
      if (&X != L &&
          (cloneWritesCell(ctx, info, o, X, cell, size) || namedWrite(ctx, X, cell, size, info) ||
           declaredCallOn(ctx, X, o) ||
           (cell.ok && cell.terms.empty() && cell.root == info.root &&
            fatptr::writesSlotCell(ctx, X, info.root, cell.off, size))) &&
          st.DT->dominates(&X, L) && clearBetween(ctx, info, o, &X, L, cell, size) &&
          (!best || st.DT->dominates(best, &X)))
        best = &X;
  return best;
}

bool isDynamic(LoweringContext &ctx, FnState &st, ObjInfo &info, ObjectId o) {
  if (info.dynamic >= 0)
    return info.dynamic;
  info.dynamic = 0;
  for (const Access &a : accessesOf(ctx, *st.F, o)) {
    if (info.record) {
      int k = a.a.terms.empty() ? fieldAt(info, a.a.off) : -1;
      if (k >= 0 && info.fields[unsigned(k)].handle == 0)
        continue;   // a classical field is memory, never a handle read
    }
    if (ctx.T.isFatPointer(accessPtr(a.I), ctx.S))
      continue;   // M7: fatptr reads such a cell only where a dominating access wrote it (readFatCell)
    if ((isa<LoadInst>(a.I) || isRMW(a.I)) && !sourceOf(ctx, st, info, o, a.I, a.a, a.ty))
      info.dynamic = 1;
  }
  return info.dynamic;
}

// Rules 20, 26 (163, 164, 70): which fields of a record hold handles. In an entry's local record, a field
// holds a handle when some write puts one there: a store of a quantum value or under a quantum predicate,
// an atomic read-modify-write, or a clone call that stores a handle into it (cellsWritten); otherwise it is
// a classical cell. In a clone, a record parameter's field holds a handle when its mask digit says so (CR
// §1.4: one digit per field, 1 iff it holds a handle at the call) or the clone itself stores one into it.
void decideFields(LoweringContext &ctx, FnState &st, ObjInfo &info, ObjectId o) {
  if (!info.record || info.recTy)
    return;
  const DataLayout &DL = ctx.M.getDataLayout();
  std::string digits;
  if (info.kind == RootKind::Param) {
    if (ctx.S.isEntry())
      unimplemented("mem-slots: an sret/byval record parameter of an entry (the host's object)", info.root);
    size_t other = 0;
    unsigned nPtr = 0;
    for (const Argument &A : st.F->args()) {
      if (A.getType()->isPointerTy())
        ++nPtr;
      else
        other += ctx.T.fieldMask(&A, ctx.S).size();
    }
    if (nPtr != 1 || ctx.S.mask.size() < other)
      unimplemented("mem-slots: a record parameter of a clone with several pointer formals (the per-formal mask "
                    "layout)",
                    info.root);
    // The pointer formal's digits: the mask's digits past the scalar formals before it.
    size_t before = 0;
    for (const Argument &A : st.F->args()) {
      if (&A == info.root)
        break;
      before += ctx.T.fieldMask(&A, ctx.S).size();
    }
    digits = ctx.S.mask.substr(before, ctx.S.mask.size() - other);
    if (digits.size() != info.fields.size())
      unimplemented("mem-slots: a record parameter whose mask digits do not count its fields", info.root);
  }
  for (const Instruction &X : instructions(*st.F))
    if (auto *MI = dyn_cast<MemIntrinsic>(&X); MI && hasObject(ctx, MI->getDest(), o))
      unimplemented("mem-slots: a memory intrinsic writing a slot record", &X);
  for (unsigned k = 0; k < info.fields.size(); ++k) {
    ObjInfo::Field &f = info.fields[k];
    uint64_t sz = storeBytes(DL, f.ty);
    Addr cell;
    cell.root = info.root;
    cell.off = f.off;
    cell.ok = true;
    bool h = !digits.empty() && digits[k] == '1';
    for (const Access &a : accessesOf(ctx, *st.F, o)) {
      if (isa<LoadInst>(a.I) || differentCell(a.a, cell, storeBytes(DL, a.ty), sz))
        continue;
      auto *S = dyn_cast<StoreInst>(a.I);
      if (!S || ctx.T.isQuantum(S->getValueOperand(), ctx.S) ||
          !ctx.preds().block(S->getParent()).quantumPart(ctx.T, ctx.S).isTop())
        h = true;
    }
    for (const Instruction &X : instructions(*st.F))
      if (cloneWritesCell(ctx, info, o, X, cell, sz))
        h = true;
    if (f.ty->isPointerTy() && !h && info.kind != RootKind::Heap)
      unimplemented("mem-slots: a pointer field of a slot record that no write fills with a fat pointer (a "
                    "classical pointer beside handle fields: rules 20, 21)",
                    info.root);
    f.handle = h;
  }
  SmallVector<Type *, 4> cells;
  for (ObjInfo::Field &f : info.fields) {
    f.rec = cells.size();
    if (f.ty->isPointerTy() && f.handle) {
      // cq-oocu (107): a pointer-kind cell is two handles (tag, idx), rule 21's fat pointer.
      if (info.kind != RootKind::Local)
        unimplemented("mem-slots: a pointer-kind field of an sret/byval record parameter or of a heap record "
                      "(rules 20, 21, 26)",
                      info.root);
      cells.push_back(handleTy(ctx.M.getContext()));
    }
    cells.push_back(f.handle ? handleTy(ctx.M.getContext()) : f.ty);
  }
  info.recTy = StructType::get(ctx.M.getContext(), cells);
  if (info.kind == RootKind::Heap) {
    // cq-z6q1: a heap record keeps its host block: every cell at its field's offset.
    const StructLayout *SL = DL.getStructLayout(info.recTy);
    for (unsigned k = 0; k < info.fields.size(); ++k)
      if (int64_t(SL->getElementOffset(info.fields[k].rec)) != info.fields[k].off)
        unimplemented("mem-slots: a heap record whose handle cells do not keep its fields' offsets", info.root);
  }
}

// ---- emission -----------------------------------------------------------------------------------

struct Site { ObjectId o; ObjInfo *info; Addr a; bool beyond = false; };

Site siteOf(LoweringContext &ctx, FnState &st, const Instruction &I, const Value *ptr, Type *ty,
            int64_t extra = 0) {
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
  a.off += extra;   // M7: a cell past the pointer (a fat-pointer load's byte offset)
  // A pointer formal's provenance is the caller's object (taint has no site for an argument).
  // A field column (129) is one of several objects of its site (objInfo's columnOf checks it).
  if (!isa<Argument>(a.root) && !columnStruct(a.root) && ctx.T.objectOf(a.root) != objs.front())
    internalError("mem-slots: the address root is not the object taint names", &I);
  ObjInfo &info = objInfo(ctx, st, a.root, objs.front());
  uint64_t bytes = ctx.M.getDataLayout().getTypeAllocSize(ty).getFixedValue();
  // cq-9w75 (CR rule 14 f981c89): in a K-loop trip a walked pointer's term is the constant trip index, so
  // the access is at a classical cell, folded here. A cell beyond the object (a trip the C program does
  // not run) reads |0> (rule 21).
  bool beyond = false;
  if (any_of(a.terms, [&](const auto &t) { return ctx.walkedPointer(t.first) != nullptr; })) {
    for (auto it = a.terms.begin(); it != a.terms.end();) {
      if (!ctx.walkedPointer(it->first)) {
        ++it;
        continue;
      }
      auto *j = dyn_cast<ConstantInt>(ctx.operand(it->first).v);
      if (!j)
        internalError("mem-slots: a walked pointer not bound to its trip index", &I);
      a.off += j->getSExtValue() * it->second;
      it = a.terms.erase(it);
    }
    if (!a.terms.empty())
      unimplemented("mem-slots: a walked slot access with a run-time index besides the trip (its rule 21 bound check)",
                    &I);
    auto *al = dyn_cast<AllocaInst>(a.root);
    std::optional<TypeSize> total = al ? al->getAllocationSize(ctx.M.getDataLayout()) : std::nullopt;
    if (!total || total->isScalable())
      unimplemented("mem-slots: a walked slot access into an object of no static size (its rule 21 bound check)", &I);
    beyond = a.off < 0 || uint64_t(a.off) + bytes > total->getFixedValue();
  }
  if (beyond && (info.record || info.view))
    unimplemented("mem-slots: a walked access beyond a slot record or view object", &I);
  if (info.record) {
    decideFields(ctx, st, info, objs.front());
    if (!a.terms.empty())
      unimplemented("mem-slots: a slot record accessed at a run-time offset", &I);
    int k = fieldAt(info, a.off);
    if (k < 0 || storeBytes(ctx.M.getDataLayout(), ty) != storeBytes(ctx.M.getDataLayout(), info.fields[unsigned(k)].ty))
      unimplemented("mem-slots: a slot record access that is not exactly one field (a bit view of a record, 122)", &I);
    return Site{objs.front(), &info, a};
  }
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
  return Site{objs.front(), &info, a, beyond};
}

RailType cellRail(const ObjInfo &info, Type *ty, const Instruction &I) {
  if (info.boolCells)
    return RailType{Kind::Int, 1};
  if (!ty->isIntegerTy() && !ty->isFloatingPointTy())
    unimplemented("mem-slots: a slot cell accessed as a non-scalar type", &I);
  return railTypeOf(ty);
}

// cq-bfz4: the i64 cell index of an access of a scalar-cell slot array at a run-time or nonzero offset, in
// the new IR (null for cell 0 of a constant offset), as cellPointer computes it.
Value *cellIndex(LoweringContext &ctx, const Site &s, const Instruction &I) {
  IRBuilder<> &B = ctx.B();
  int64_t cb = int64_t(s.info->cellBytes);
  if (s.info->record || s.info->colStride || s.a.off % cb)
    internalError("mem-slots: cellIndex of a record, a field column or an offset inside a cell", &I);
  Type *i64 = Type::getInt64Ty(ctx.M.getContext());
  Value *idx = nullptr;
  for (auto &[v, stride] : s.a.terms) {
    if (stride % cb || v->getType()->isPointerTy())
      internalError("mem-slots: cellIndex of a stride inside a cell or a walked pointer", &I);
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
  return idx;
}

// The i32 cell pointer of an access, in the new IR.
Value *cellPointer(LoweringContext &ctx, const Site &s, const Instruction &I) {
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  Operand base = ctx.operand(s.a.root);
  if (base.handle)
    internalError("mem-slots: the base of a slot object is a rail", &I);
  if (s.info->record) {
    int k = fieldAt(*s.info, s.a.off);
    if (k < 0 || !s.a.terms.empty() || !s.info->recTy)
      internalError("mem-slots: a record cell pointer that is not one field", &I);
    unsigned r = s.info->fields[unsigned(k)].rec;
    return r == 0 ? base.v : B.CreateStructGEP(s.info->recTy, base.v, r);
  }
  int64_t cb = int64_t(s.info->cellBytes);
  Type *i64 = Type::getInt64Ty(C);
  if (s.info->colStride) {
    // A field column (129): the array's own layout, the handle at the start of the field: a byte address.
    int64_t cs = int64_t(s.info->colStride);
    if ((((s.a.off - s.info->colOff) % cs) + cs) % cs)
      internalError("mem-slots: a field-column access off its column", &I);
    Value *bytes = nullptr;
    for (auto &[v, stride] : s.a.terms) {
      if (stride % cs)
        unimplemented("mem-slots: a GEP stride into a field column that is not a whole number of elements", &I);
      if (v->getType()->isPointerTy())
        unimplemented("mem-slots: a walked pointer into a field column", &I);
      Operand x = ctx.operand(v);
      if (x.handle)
        internalError("mem-slots: a quantum index into a slot object (QRAM, rule 20)", &I);
      Value *t = B.CreateMul(B.CreateSExtOrTrunc(x.v, i64), ConstantInt::get(i64, stride, true));
      bytes = bytes ? B.CreateAdd(bytes, t) : t;
    }
    if (s.a.off) {
      Value *k = ConstantInt::get(i64, s.a.off, true);
      bytes = bytes ? B.CreateAdd(bytes, k) : k;
    }
    return bytes ? B.CreateInBoundsGEP(Type::getInt8Ty(C), base.v, bytes) : base.v;
  }
  if (s.a.off % cb)
    unimplemented("mem-slots: a constant byte offset that is not a whole cell", &I);
  Value *idx = nullptr;
  for (auto &[v, stride] : s.a.terms) {
    if (stride % cb)
      unimplemented("mem-slots: a GEP stride that is not a whole number of cells", &I);
    if (v->getType()->isPointerTy() && !ctx.walkedPointer(v))
      unimplemented("mem-slots: a slot access through a walked pointer outside a K-loop trip (its index is not "
                    "bound: rule 14 case 1 pointer inductions)",
                    &I);
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

// A and B lie in one classically bounded loop (rule 14 case 1) and every loop holding either is one:
// the loop is lowered once as a classical loop whose reverse undoes its trips last-in-first-out, so a
// rail one trip stores into a cell and a later trip reads back (187) is undone after that later trip's
// records that read it.
bool sameClassicalLoop(LoweringContext &ctx, FnState &st, const Instruction *A, const Instruction *B) {
  if (!st.LI)
    st.LI = std::make_unique<LoopInfo>(*st.DT);
  const Loop *LA = st.LI->getLoopFor(A->getParent()), *LB = st.LI->getLoopFor(B->getParent());
  if (!LA || !LB)
    return false;
  bool common = false;
  for (const Loop *l = LA; l; l = l->getParentLoop())
    common |= l->contains(B->getParent());
  if (!common)
    return false;
  for (const Loop *L0 : {LA, LB})
    for (const Loop *l = L0; l; l = l->getParentLoop())
      if (loops::classify(*l, ctx.T, ctx.S) != loops::Case::ClassicalBound)
        return false;
  return true;
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
  for (auto &[X, d] : st.declared)
    if (hasObjectArg(ctx, *X, s.o) && isPotentiallyReachable(X, &I, nullptr, st.DT.get()))
      unimplemented("mem-slots: a run-time read of a slot cell a declared clone call may have written on some "
                    "paths only (rule 27)",
                    &I);
  for (const Instruction &X : instructions(*st.F))
    if (auto *MI = dyn_cast<MemIntrinsic>(&X); MI && hasObject(ctx, MI->getDest(), s.o) &&
                                               isPotentiallyReachable(MI, &I, nullptr, st.DT.get())) {
      auto c = st.callOut.find(MI);
      if (c == st.callOut.end()) {
        unnamed = true;   // not lowered through writeSlotCells (yet)
        continue;
      }
      for (auto &[off, h] : c->second) {   // M6: the cells it wrote are named
        Addr w = s.a;
        w.off = off;
        w.terms.clear();
        if (differentCell(w, s.a, s.info->cellBytes, size) || !h.handle)
          continue;
        if (!st.registers.count(h.v))
          allRegisters = false;
        RailId r = ctx.unc().idOf(h.v);
        if (!is_contained(arms, r))
          arms.push_back(r);
      }
    }
  for (const Instruction &X : instructions(*st.F)) {
    auto *CB = dyn_cast<CallBase>(&X);
    if (!CB || !cloneCallee(ctx, *CB) || !mayWrite(ctx, *s.info, s.o, X, s.a, size) ||
        !isPotentiallyReachable(&X, &I, nullptr, st.DT.get()))
      continue;
    // M1: a clone call that may write the cell: its new handles are the caller's loads after it.
    auto c = st.callOut.find(&X);
    if (c == st.callOut.end()) {
      unnamed = true;
      continue;
    }
    for (auto &[off, h] : c->second) {
      Addr w = s.a;
      w.off = off;
      w.terms.clear();
      if (differentCell(w, s.a, cellSizeAt(*s.info, off, DL), size))
        continue;
      allRegisters = false;
      RailId r = ctx.unc().idOf(h.v);
      if (!is_contained(arms, r))
        arms.push_back(r);
    }
  }
  for (const Access &a : accessesOf(ctx, *st.F, s.o)) {
    if (isRMW(a.I) && a.I != &I && !differentCell(a.a, s.a, storeBytes(DL, a.ty), size) &&
        isPotentiallyReachable(a.I, &I, nullptr, st.DT.get()))
      unnamed = true;   // an atomic read-modify-write's new rail (94): not named here
    auto *S = dyn_cast<StoreInst>(a.I);
    if (!S || S == &I || differentCell(a.a, s.a, storeBytes(DL, a.ty), size))
      continue;
    if (auto c = st.callOut.find(S); c != st.callOut.end()) {
      // A wide store split per cell (90): the cells it wrote are named.
      if (!isPotentiallyReachable(S, &I, nullptr, st.DT.get()))
        continue;
      for (auto &[off, h] : c->second) {
        Addr w = s.a;
        w.off = off;
        w.terms.clear();
        if (differentCell(w, s.a, s.info->cellBytes, size) || !h.handle)
          continue;
        if (!st.registers.count(h.v))
          allRegisters = false;
        RailId r = ctx.unc().idOf(h.v);
        if (!is_contained(arms, r))
          arms.push_back(r);
      }
      continue;
    }
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
      if (!sameClassicalLoop(ctx, st, S, &I))
        unnamed = true;   // a trip-carried rail of the same classical loop is ordered by its reverse (187)
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

// Some instruction `hit` accepts is reached from S (not through S again) on a path on which no instruction
// `kill` accepts comes first; kill applies only while the path has not re-executed an instruction of defs,
// and hit is told whether it has (fresh: S's address values are still the ones S used).
bool reachesUnkilled(const Instruction &S, const SmallPtrSetImpl<const Instruction *> &defs,
                     function_ref<bool(const Instruction &)> kill,
                     function_ref<bool(const Instruction &, bool fresh)> hit) {
  SmallVector<std::tuple<const BasicBlock *, BasicBlock::const_iterator, bool>, 16> work;
  std::set<std::pair<const BasicBlock *, bool>> seen;
  work.push_back({S.getParent(), std::next(S.getIterator()), true});
  while (!work.empty()) {
    auto [b, it, fresh] = work.pop_back_val();
    bool stop = false;
    for (; it != b->end(); ++it) {
      const Instruction &X = *it;
      if (&X == &S) {
        stop = true;
        break;
      }
      if (defs.count(&X))
        fresh = false;
      if (hit(X, fresh))
        return true;
      if (fresh && kill(X)) {
        stop = true;
        break;
      }
    }
    if (stop)
      continue;
    for (const BasicBlock *n : successors(b))
      if (seen.insert({n, fresh}).second)
        work.push_back({n, n->begin(), fresh});
  }
  return false;
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
        // A cmpxchg's old value is its field 0 (rule 24, 94).
        if (auto *ev = dyn_cast<ExtractValueInst>(u); ev && isa<AtomicCmpXchgInst>(x) && ev->getIndices()[0] == 0)
          view = true;
        if (view && seen.insert(u).second)
          work.push_back(u);
      }
    }
    return false;
  };
  // cq-lvx8: only a load S's rail may still be in the cell at: a path from S to it on which no store of
  // exactly S's cell (or atomic read-modify-write of it) comes first. Such an overwrite counts only while
  // the path has not re-executed a definition of the cell's address.
  SmallPtrSet<const Instruction *, 4> defs;
  if (auto *R = dyn_cast<Instruction>(s.a.root))
    defs.insert(R);
  for (auto &t : s.a.terms)
    if (auto *T = dyn_cast<Instruction>(t.first))
      defs.insert(T);
  auto mine = [&](const Instruction &X, Addr &a, uint64_t &n) {
    const Value *p = isa<LoadInst>(X) || isa<StoreInst>(X) || isRMW(&X) ? accessPtr(&X) : nullptr;
    if (!p || !hasObject(ctx, p, s.o))
      return false;
    a = decompose(p, DL);
    if (auto *ld = dyn_cast<LoadInst>(&X))
      n = storeBytes(DL, ld->getType());
    else if (auto *so = dyn_cast<StoreInst>(&X))
      n = storeBytes(DL, so->getValueOperand()->getType());
    else
      n = storeBytes(DL, isa<AtomicRMWInst>(X) ? cast<AtomicRMWInst>(X).getValOperand()->getType()
                                               : cast<AtomicCmpXchgInst>(X).getNewValOperand()->getType());
    return true;
  };
  auto hit = [&](const Instruction &X, bool fresh) {
    Addr a;
    uint64_t n = 0;
    // cq-3gdk: once the path re-executed an index of S's address, "provably another cell" no longer holds
    // (a[i - 1] in the next trip is this trip's a[i]).
    if (!(isa<LoadInst>(X) || isRMW(&X)) || !mine(X, a, n) || (fresh && differentCell(a, s.a, n, sz)))
      return false;
    return measures(&X);
  };
  auto kill = [&](const Instruction &X) {
    Addr a;
    uint64_t n = 0;
    if (isa<LoadInst>(X) || !mine(X, a, n) || n != sz || !sameCell(a, s.a) ||
        ctx.T.isFatPointer(accessPtr(&X), ctx.S))
      return false;
    auto *so = dyn_cast<StoreInst>(&X);
    return !so || (!so->isVolatile() && !so->isAtomic());
  };
  return reachesUnkilled(S, defs, kill, hit);
}

// Rule 20 is per cell (orchestrator decision 2026-11-01 under rule 20, owner may override): a cell of a
// static object (local or heap, not escaping, every read forwarded) is CLASSICAL when no write that may
// reach it puts a handle there: every store that may write it stores a classical value outside any
// quantum predicate, and no atomic read-modify-write or memory intrinsic writes the object.
bool classicalCell(LoweringContext &ctx, FnState &st, const Site &s) {
  const DataLayout &DL = ctx.M.getDataLayout();
  if (s.info->boolCells || s.info->view)
    return false;
  for (const Instruction &X : instructions(*st.F))
    if (auto *MI = dyn_cast<MemIntrinsic>(&X); MI && hasObject(ctx, MI->getDest(), s.o))
      return false;
  if (s.info->record) {
    int k = fieldAt(*s.info, s.a.off);
    return k >= 0 && s.info->fields[unsigned(k)].handle == 0;
  }
  uint64_t size = s.info->cellBytes;
  for (const Instruction &X : instructions(*st.F))
    if (auto *CB = dyn_cast<CallBase>(&X); CB && cloneCallee(ctx, *CB))
      for (const Use &u : CB->args())
        if (hasObject(ctx, u.get(), s.o))
          return false;   // M1: a clone may read the cell as a handle or store one into it
  for (const Access &a : accessesOf(ctx, *st.F, s.o)) {
    if (isa<LoadInst>(a.I) || differentCell(a.a, s.a, storeBytes(DL, a.ty), size))
      continue;
    auto *S = dyn_cast<StoreInst>(a.I);
    if (!S || ctx.T.isQuantum(S->getValueOperand(), ctx.S) || ctx.T.isFatPointer(S->getPointerOperand(), ctx.S) ||
        !ctx.preds().block(S->getParent()).quantumPart(ctx.T, ctx.S).isTop())
      return false;
  }
  return true;
}

// M3b (CR rules 5, 20; 114): an earlier run-time read R of a cell of the same object that is provably another
// cell than I's in the same activation of every enclosing loop (R dominates I, no value of either address is
// redefined between them, no write into the object between them) names another rail at run time (one rail per
// cell): Uncompute::noteCellsDistinct, so a gate on one is no alias hit on a record reading the other.
void noteDistinctReads(LoweringContext &ctx, FnState &st, const Site &s, const Instruction &I, uint64_t size,
                       LoadInst *h) {
  const DataLayout &DL = ctx.M.getDataLayout();
  for (const FnState::CellRead &R : st.cellReads) {
    if (!R.h || R.a.root != s.a.root || !differentCell(R.a, s.a, R.size, size) || !st.DT->dominates(R.I, &I))
      continue;
    const BasicBlock *BR = R.I->getParent(), *BI = I.getParent();
    SmallPtrSet<const BasicBlock *, 16> mid;
    if (BR != BI)
      mid = between(BR, BI);
    auto redefined = [&](const Value *v) {
      auto *d = dyn_cast<Instruction>(v);
      return d && mid.count(d->getParent());
    };
    bool ok = !redefined(R.a.root) && !redefined(s.a.root);
    for (auto &t : R.a.terms)
      ok &= !redefined(t.first);
    for (auto &t : s.a.terms)
      ok &= !redefined(t.first);
    if (BR != BI && (onCycleWithin(BI, mid) || mid.count(BR)))
      ok = false;
    auto writes = [&](BasicBlock::const_iterator from, BasicBlock::const_iterator to) {
      for (auto it = from; it != to; ++it)
        if (it->mayWriteToMemory() && !isa<DbgInfoIntrinsic>(&*it)) {
          if (auto *si = dyn_cast<StoreInst>(&*it)) {
            if (!hasObject(ctx, si->getPointerOperand(), s.o))
              continue;
            // A store of a rail made after R's load (a fresh computation, 114's q[m-1] ^= ...) is no
            // pre-existing handle: neither cell can come to hold R's rail through it.
            auto lw = st.lowered.find(si);
            auto *vi = lw == st.lowered.end() || !lw->second.handle ? nullptr : dyn_cast<Instruction>(lw->second.v);
            if (vi && vi != R.h && vi->getParent() == R.h->getParent() && R.h->comesBefore(vi) &&
                !isa<LoadInst>(vi))
              continue;
          }
          if (auto *II = dyn_cast<IntrinsicInst>(&*it); II && II->isLifetimeStartOrEnd())
            continue;
          if (auto *CB = dyn_cast<CallBase>(&*it); CB && isCqSurface(*CB))
            continue;
          return true;
        }
      return false;
    };
    if (ok && BR == BI)
      ok = !writes(std::next(R.I->getIterator()), I.getIterator());
    if (ok && BR != BI) {
      ok = !writes(std::next(R.I->getIterator()), BR->end()) && !writes(BI->begin(), I.getIterator());
      for (const BasicBlock *b : mid)
        if (b != BI)
          ok &= !writes(b->begin(), b->end());
    }
    (void)DL;
    if (ok)
      ctx.unc().noteCellsDistinct(R.h, h);
  }
}

// M3b (114): a fresh computed rail v stored at S into a cell of a dynamic object that provably differs
// from the cell an earlier run-time read R of the same activation read (R dominates S, v made after R's
// load) is never the rail R names: not in this activation (v did not exist at R), and not in a later one
// when no store of the function moves a handle loaded from the object into another of its cells.
void noteDistinctStore(LoweringContext &ctx, FnState &st, const Site &s, const Instruction &S, uint64_t size,
                       Value *v) {
  auto *vi = dyn_cast<Instruction>(v);
  if (!vi || isa<LoadInst>(vi) || st.cellReads.empty())
    return;
  const DataLayout &DL = ctx.M.getDataLayout();
  // No move: every store into the object whose value is (a view or in-place rotation of) a load of the
  // object stores it back into that load's own cell.
  for (const Access &a : accessesOf(ctx, *st.F, s.o)) {
    auto *X = dyn_cast<StoreInst>(a.I);
    if (!X)
      continue;
    const Value *x = X->getValueOperand();
    for (unsigned g = 0; g < 16; ++g) {
      if (auto *c = dyn_cast<CastInst>(x)) {
        x = c->getOperand(0);
        continue;
      }
      if (auto *fz = dyn_cast<FreezeInst>(x)) {
        x = fz->getOperand(0);
        continue;
      }
      auto *c = dyn_cast<CallInst>(x);
      if (c && c->getCalledFunction() && c->getCalledFunction()->getName().starts_with("cq_theta_")) {
        x = c->getArgOperand(0);
        continue;
      }
      break;
    }
    if (auto *ld = dyn_cast<LoadInst>(x); ld && hasObject(ctx, ld->getPointerOperand(), s.o) &&
                                          !sameCell(decompose(ld->getPointerOperand(), DL), a.a))
      return;
    if (isa<PHINode>(x) || isa<SelectInst>(x))
      return;   // a handle chosen among others may be a moved one
  }
  for (const FnState::CellRead &R : st.cellReads)
    if (R.h && R.a.root == s.a.root && differentCell(R.a, s.a, R.size, size) && st.DT->dominates(R.I, &S) &&
        vi->getParent() == R.h->getParent() && R.h->comesBefore(vi))
      ctx.unc().noteCellsDistinct(R.h, vi);
}

// cq-2t04 (CR rules 7, 20; 121): a classical store S into a cell of a dynamic local object, outside any
// quantum predicate, whose old content is a seed nothing has read: the old rail is in a known basis state and
// no other holder reads it, so it is released right there (the cell's handle loaded and freed), before the new
// seed takes the cell. Built only when every write that may reach S's cell is a classical store (one of them
// dominating S and covering the cell: the same cell, or the whole object), or the same address stored after S
// in S's block of an outermost loop whose address advances every trip (a later trip's S writes another cell),
// and no read of the object can reach S.
void freeOverwrittenSeed(LoweringContext &ctx, FnState &st, const Site &s, const StoreInst &S) {
  if (!(s.info->kind == RootKind::Local || s.info->kind == RootKind::Heap) || s.info->escaping ||
      s.info->record || s.info->view || !isDynamic(ctx, st, *s.info, s.o) || ctx.currentFlag() ||
      !ctx.currentPredicate().isTop())
    return;
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t size = storeBytes(DL, S.getValueOperand()->getType());
  auto classicalStore = [&](const Instruction &X) {
    auto *x = dyn_cast<StoreInst>(&X);
    return x && !x->isVolatile() && !x->isAtomic() && !ctx.T.isQuantum(x->getValueOperand(), ctx.S) &&
           !ctx.T.isFatPointer(x->getPointerOperand(), ctx.S) &&
           ctx.preds().block(x->getParent()).quantumPart(ctx.T, ctx.S).isTop();
  };
  auto *root = dyn_cast<AllocaInst>(s.info->root);
  auto covers = [&](const StoreInst &x) {
    Addr a = decompose(x.getPointerOperand(), DL);
    if (sameCell(a, s.a) && storeBytes(DL, x.getValueOperand()->getType()) == size)
      return true;
    if (!root || root->isArrayAllocation() || !a.ok || !a.terms.empty() || a.root != root || a.off != 0)
      return false;
    return storeBytes(DL, x.getValueOperand()->getType()) >= DL.getTypeAllocSize(root->getAllocatedType());
  };
  auto advancesLater = [&](const Instruction &X) {
    auto *x = dyn_cast<StoreInst>(&X);
    if (!x || x->getPointerOperand() != S.getPointerOperand() || x->getParent() != S.getParent() ||
        !S.comesBefore(x))
      return false;
    if (!st.LI)
      st.LI = std::make_unique<LoopInfo>(*st.DT);
    Loop *L = st.LI->getLoopFor(S.getParent());
    ScalarEvolution *SE = seOf(S.getPointerOperand());
    if (!L || L->getParentLoop() || !SE)
      return false;
    auto *ar = dyn_cast<SCEVAddRecExpr>(SE->getSCEV(const_cast<Value *>(S.getPointerOperand())));
    if (!ar || ar->getLoop()->getHeader() != L->getHeader() || !ar->isAffine() || !ar->hasNoSelfWrap())
      return false;
    auto *step = dyn_cast<SCEVConstant>(ar->getStepRecurrence(*SE));
    return step && !step->getValue()->isZero() &&
           step->getAPInt().abs().uge(APInt(step->getAPInt().getBitWidth(), size));
  };
  bool dominated = false;
  for (const Instruction &X : instructions(*st.F)) {
    if (&X == &S)
      continue;
    if (auto *II = dyn_cast<IntrinsicInst>(&X); II && II->isLifetimeStartOrEnd())
      continue;
    bool reads = false;
    if (auto *ld = dyn_cast<LoadInst>(&X))
      reads = hasObject(ctx, ld->getPointerOperand(), s.o);
    else if (auto *CB = dyn_cast<CallBase>(&X); CB && !isCqSurface(*CB))
      reads = any_of(CB->args(), [&](const Use &u) { return hasObject(ctx, u.get(), s.o); });
    else if (isRMW(&X))
      reads = hasObject(ctx, X.getOperand(0), s.o);
    if (reads) {
      if (isPotentiallyReachable(&X, &S, nullptr, st.DT.get())) 
        return;
      continue;
    }
    if (!(isa<StoreInst>(X) || isa<CallBase>(X)) || !mayWrite(ctx, *s.info, s.o, X, s.a, size) ||
        !isPotentiallyReachable(&X, &S, nullptr, st.DT.get()))
      continue;
    if (classicalStore(X)) {
      dominated |= st.DT->dominates(&X, &S) && covers(cast<StoreInst>(X));
      continue;
    }
    if (advancesLater(X))
      continue;
    return;
  }
  if (!dominated)
    return;
  IRBuilder<> &B = ctx.B();
  LoadInst *h = B.CreateAlignedLoad(handleTy(ctx.M.getContext()), cellPointer(ctx, s, S), Align(4));
  ctx.emitCore(abi::CoreSpec{abi::Core::Free, {}}, {h});
}

// ---- program slots (102) ------------------------------------------------------------------------
//
// CR rules 16, 19, 20, 2, 7 (102's @hit). A PROGRAM SLOT is an internal integer global G (32 to 64 bits,
// an integer initializer, not externally initialized, not constant, not thread-local) whose every use is a
// non-atomic load or store of G's value type through G itself, and that some function loads with no store
// of G in that function dominating the load: the cell's content comes from outside the function (102: a
// signal handler's store, read after raise). G is program-lifetime storage holding a handle on every path
// (rule 20), so:
//  - a module constructor __cq_slot_init_<G> (llvm.global_ctors, priority 65535) stores a seed
//    alloc_<W>(initializer) into G (rule 7; 160's global);
//  - a classical store in a function that does not load G (102's classical original h) stores a seed
//    rail, Role::Output (the slot keeps it);
//  - the GUARDED STORE: in a _ctl clone whose callee's only access of G is one store in its entry block of
//    a constant or a classical formal (guardedStoreOf), old = load G (the caller's rail, kept here) and
//    select(ctl, v, old) into a fresh rail stored into G, Role::Output (the caller decides its fate);
//  - in an entry E the slot's content is tracked along E (FnState::ProgSlot). Each shot runs one entry after
//    the constructors, so at E's start G holds the constructor's seed of its initializer (SEEDED, a seed of
//    a classical value v). A call of such a _ctl clone (noteProgramSlotCall, the call executing on every path
//    of E, outside loops) loads the old handle before the call; the slot is then WRITTEN with
//    R = flag ? s : vold. With no load of G reachable after the call the old seed is freed after it (nothing
//    holds it) and R stays the slot's (kept). A load in the SEEDED state after a collapse is v (a classical
//    read, rule 2). A load in the WRITTEN state needs the call's predicate classical there (rule 2: a function of measured
//    rails, spine::collapse): R is uncomputed against a seed of the predicate's classical value c
//    (select_<W>_lh_unc), freed, a fresh seed of v = c ? s : vold is stored into G (rule 7: the slot keeps it),
//    the old seed is freed, and the load is v.
// The initializer as the old seed's value at the collapse is 102's reading (its reference: "the seed's
// value is 0"): the entry is the shot's only reader of the slot (orchestrator decision under CR rule 2 and
// 102, owner may override). Unimplemented: a load before any guarded write in the entry (the slot's content
// at the entry's start), a load in a function the module calls or whose address is taken, any other access
// of a program slot (a store in an entry that loads it or in another clone, a store of a rail, a second guarded write before a collapse, a load in the WRITTEN state whose
// predicate is not classical yet, a load or the call under a classical branch or in a loop, a load reached
// by a call that may run code accessing G other than the recorded clone calls and signal()).

bool programSlot(const GlobalVariable *gv) {
  static std::map<const GlobalVariable *, bool> cache;
  if (auto it = cache.find(gv); it != cache.end())
    return it->second;
  auto decide = [&]() {
    auto *IT = dyn_cast<IntegerType>(gv->getValueType());
    if (!gv->hasLocalLinkage() || gv->isExternallyInitialized() || gv->isConstant() || gv->isThreadLocal() ||
        !gv->hasInitializer() || !IT || IT->getBitWidth() < 32 || IT->getBitWidth() > 64 ||
        IT->getBitWidth() % 8 || !isa<ConstantInt>(gv->getInitializer()))
      return false;
    SmallVector<const LoadInst *, 4> loads;
    std::map<const Function *, SmallVector<const StoreInst *, 2>> stores;
    for (const User *u : gv->users()) {
      if (auto *L = dyn_cast<LoadInst>(u); L && L->getPointerOperand() == gv && L->getType() == IT && !L->isAtomic()) {
        loads.push_back(L);
        continue;
      }
      if (auto *S = dyn_cast<StoreInst>(u); S && S->getPointerOperand() == gv && S->getValueOperand() != gv &&
                                            S->getValueOperand()->getType() == IT && !S->isAtomic()) {
        stores[S->getFunction()].push_back(S);
        continue;
      }
      return false;
    }
    for (const LoadInst *L : loads) {
      DominatorTree DT(const_cast<Function &>(*L->getFunction()));
      if (none_of(stores[L->getFunction()], [&](const StoreInst *S) { return DT.dominates(S, L); }))
        return true;
    }
    return false;
  };
  return cache[gv] = decide();
}

const GlobalVariable *programSlotOf(const Site &s) {
  if (s.info->kind != RootKind::Global || !s.a.ok || s.a.off || !s.a.terms.empty())
    return nullptr;
  auto *gv = dyn_cast<GlobalVariable>(s.info->root);
  return gv && programSlot(gv) ? gv : nullptr;
}

RailType slotRail(const GlobalVariable &gv) {
  return RailType{Kind::Int, cast<IntegerType>(gv.getValueType())->getBitWidth()};
}

void ensureSlotCtor(Module &M, const GlobalVariable &cgv) {
  auto &gv = const_cast<GlobalVariable &>(cgv);
  std::string name = ("__cq_slot_init_" + gv.getName()).str();
  if (M.getFunction(name))
    return;
  LLVMContext &C = M.getContext();
  Function *F = Function::Create(FunctionType::get(Type::getVoidTy(C), false), GlobalValue::InternalLinkage, name, M);
  IRBuilder<> B(BasicBlock::Create(C, "", F));
  Value *h = B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Alloc, slotRail(gv)}), {gv.getInitializer()});
  B.CreateAlignedStore(h, &gv, Align(4));
  B.CreateRetVoid();
  appendToGlobalCtors(M, F, 65535);
}

// The guarded store of a program slot gv in F (a handler, 102's h): F's only access of gv, a store in F's
// entry block of a constant or a formal of F, and no call in F that may reach code accessing gv. Else null.
const StoreInst *guardedStoreOf(const Function &F, const GlobalVariable &gv) {
  const StoreInst *S = nullptr;
  for (const User *u : gv.users()) {
    auto *I = dyn_cast<Instruction>(u);
    if (!I || I->getFunction() != &F)
      continue;
    auto *st = dyn_cast<StoreInst>(I);
    if (S || !st || st->getParent() != &F.getEntryBlock() ||
        !(isa<ConstantInt>(st->getValueOperand()) || isa<Argument>(st->getValueOperand())))
      return nullptr;
    S = st;
  }
  if (!S)
    return nullptr;
  for (const Instruction &X : instructions(F))
    if (auto *CB = dyn_cast<CallBase>(&X); CB && !isa<DbgInfoIntrinsic>(CB) && !isCqSurface(*CB) &&
                                         callMayTouchInternalGlobal(*CB, gv))
      return nullptr;
  return S;
}

bool loadsGlobal(const Function &F, const GlobalVariable &gv) {
  return any_of(gv.users(), [&](const User *u) {
    auto *L = dyn_cast<LoadInst>(u);
    return L && L->getFunction() == &F;
  });
}

FnState::ProgSlot &progSlotState(FnState &st, const GlobalVariable &gv) {
  auto it = st.progSlots.find(&gv);
  if (it == st.progSlots.end()) {
    FnState::ProgSlot p;
    p.v = const_cast<Constant *>(gv.getInitializer());   // the constructor's seed: this shot's only entry starts here
    it = st.progSlots.emplace(&gv, p).first;
  }
  return it->second;
}

// The guarded store's old read in a _ctl clone (see above): the handle the slot holds at the call.
bool cloneReadsProgramSlot(LoweringContext &ctx, const GlobalVariable &gv, const Instruction &I) {
  return ctx.S.ctl && !ctx.S.pure && !ctx.S.adj && !ctx.S.isEntry() && I.getFunction() == ctx.S.F &&
         guardedStoreOf(*ctx.S.F, gv) == &I;
}

// A load of a program slot in an entry (see above).
Operand readProgramSlot(LoweringContext &ctx, FnState &st, const GlobalVariable &gv, const LoadInst &L) {
  std::string pre = "mem-slots: a load of a program slot (102) ";
  if (!ctx.S.isEntry() || L.getFunction() != ctx.S.F)
    unimplemented(pre + "outside an entry (its content there depends on the caller)", &L);
  if (ctx.loopUnit() || !ctx.preds().block(L.getParent()).isTop())
    unimplemented(pre + "in a loop or under a branch", &L);
  for (const Instruction &X : instructions(*st.F)) {
    if (&X == &L || !isPotentiallyReachable(&X, &L, nullptr, st.DT.get()))
      continue;
    if (auto *S = dyn_cast<StoreInst>(&X); S && S->getPointerOperand() == &gv)
      unimplemented(pre + "after a store of it in the same entry", &L);
    auto *CB = dyn_cast<CallBase>(&X);
    if (!CB || isa<DbgInfoIntrinsic>(CB) || isCqSurface(*CB) || !callMayTouchInternalGlobal(*CB, gv) ||
        st.progSlotCalls.count(CB))
      continue;
    const Function *f = CB->getCalledFunction();
    if (f && f->isDeclaration() && f->getName() == "signal")
      continue;   // installs a handler; never runs it (the signal table, rule 16)
    unimplemented(pre + "after a call that may run code accessing it (other than a guarded _ctl clone call)", &L);
  }
  if (any_of(ctx.S.F->users(), [](const User *u) { return isa<CallBase>(u); }) || ctx.S.F->hasAddressTaken())
    unimplemented(pre + "in a function the program may call (its content there is the caller's)", &L);
  FnState::ProgSlot &p = progSlotState(st, gv);
  if (!p.written && p.v == gv.getInitializer())
    unimplemented(pre + "that no guarded clone call of this entry wrote (its content at the entry's start)", &L);
  if (!p.written)
    return Operand{p.v, false};
  Value *c = spine::collapse(ctx, p.flag);
  if (!c)
    unimplemented(pre + "a guarded clone store wrote while its predicate is not classical at the load (rule 2's "
                        "collapse needs its quantum sources measured first)",
                  &L);
  if (!c->getType()->isIntegerTy(1))
    internalError("mem-slots: a collapsed predicate that is not an i1", &L);
  IRBuilder<> &B = ctx.B();
  ensureSlotCtor(ctx.M, gv);
  RailType w = slotRail(gv);
  LoadInst *R = B.CreateAlignedLoad(handleTy(ctx.M.getContext()), const_cast<GlobalVariable *>(&gv), Align(4));
  CallInst *pc = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}}, {c});
  abi::TemplateSpec sel;
  sel.op = "select";
  sel.w = w;
  sel.shape = "lh";
  B.CreateCall(abi::declare(ctx.M, sel, true), {R, pc, p.s, p.old});
  ctx.emitCore(abi::CoreSpec{abi::Core::Free, {}}, {pc});
  ctx.emitCore(abi::CoreSpec{abi::Core::Free, {}}, {R});
  Value *v = B.CreateSelect(c, p.s, p.v);
  CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {v});
  B.CreateAlignedStore(f, const_cast<GlobalVariable *>(&gv), Align(4));
  ctx.emitCore(abi::CoreSpec{abi::Core::Free, {}}, {p.old});
  p = FnState::ProgSlot{};
  p.v = v;
  return Operand{v, false};
}

// The handle a cell holds at I (a load, or the old value at a guarded store).
Operand readCell(LoweringContext &ctx, FnState &st, const Site &s, const Instruction &I, Type *ty) {
  if (s.beyond) {
    // Rule 21 (cq-9w75): a cell beyond the object reads |0>, a seed of its own.
    RailType w = cellRail(*s.info, ty, I);
    CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                               {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
    ctx.unc().recordSeed(z);
    return Operand{z, true};
  }
  if (const Instruction *src = sourceOf(ctx, st, *s.info, s.o, &I, s.a, ty)) {
    if (auto f = st.fatOut.find(src); f != st.fatOut.end()) {
      auto k = f->second.find({s.a.root, s.a.off});
      if (k == f->second.end())
        internalError("mem-slots: a load forwards from a fat-pointer write that did not write its cell", &I);
      if (ty != s.info->cellTy)
        unimplemented("mem-slots: a read at another type of a cell a fat-pointer write left a rail in (M7)", &I);
      return k->second;
    }
    if (auto d = st.declared.find(src); d != st.declared.end()) {
      // cq-r8-d (rule 27): the cell holds the clone's new handle or the one it held at the call. A
      // run-time read, a cell load over the twin's pseudo rail (its readers come before the twin) and the
      // old handle.
      if (s.info->record || s.info->view || s.info->boolCells || !s.a.terms.empty())
        unimplemented("mem-slots: a read after a declared clone call of a slot record, bit view, _Bool cell or "
                      "run-time offset (rule 27)",
                      &I);
      LoadInst *h = ctx.B().CreateAlignedLoad(handleTy(ctx.M.getContext()), cellPointer(ctx, s, I), Align(4));
      SmallVector<RailId, 2> arms{d->second.pseudo};
      if (auto k = d->second.atCall.find(s.a.off); k != d->second.atCall.end() && k->second.handle)
        arms.push_back(ctx.unc().idOf(k->second.v));
      ctx.unc().recordCellLoad(h, arms);
      return Operand{h, true};
    }
    if (isa<CallBase>(src)) {
      auto c = st.callOut.find(src);
      auto k = c == st.callOut.end() ? std::map<int64_t, Operand>::iterator() : c->second.find(s.a.off);
      if (c == st.callOut.end() || k == c->second.end())
        unimplemented("mem-slots: a load of a cell a clone call wrote whose new handle the caller did not load "
                      "(mem::slotCellsAfterCall, M1)",
                      &I);
      return k->second;
    }
    // cq-597j (a): a split classical store (90) or a memory intrinsic lowered through writeSlotCells (M6)
    // names its cells' handles in callOut, per cell offset.
    if (auto c = st.callOut.find(src); c != st.callOut.end()) {
      auto k = c->second.find(s.a.off);
      if (k == c->second.end())
        internalError("mem-slots: a load forwards from a per-cell write that did not write its cell", &I);
      return k->second;
    }
    auto it = st.lowered.find(src);
    if (it == st.lowered.end())
      internalError("mem-slots: the access a slot load forwards from has not been lowered", &I);
    return it->second;
  }
  if (const GlobalVariable *gv = programSlotOf(s)) {
    if (auto *L = dyn_cast<LoadInst>(&I))
      return readProgramSlot(ctx, st, *gv, *L);
    if (!cloneReadsProgramSlot(ctx, *gv, I))
      unimplemented("mem-slots: a read of a program slot (102) other than a load in an entry or the guarded "
                    "store of a _ctl clone",
                    &I);
    ensureSlotCtor(ctx.M, *gv);
    LoadInst *h = ctx.B().CreateAlignedLoad(handleTy(ctx.M.getContext()), const_cast<GlobalVariable *>(gv), Align(4));
    ctx.unc().recordExternal(h, Role::UserRegister);   // the caller's rail: never the clone's
    st.registers.insert(h);
    return Operand{h, true};
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
    uint64_t size = storeBytes(ctx.M.getDataLayout(), ty);
    SmallVector<RailId, 4> arms;
    bool allRegisters = true;
    if (cellArms(ctx, st, s, I, ty, arms, allRegisters) && !allRegisters) {
      ctx.unc().recordCellLoad(h, arms);
    } else {
      ctx.unc().recordExternal(h, Role::UserRegister);
      st.registers.insert(h);
    }
    noteDistinctReads(ctx, st, s, I, size, h);
    st.cellReads.push_back({&I, s.a, size, h});
    return Operand{h, true};
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

// The stored handle is the rail of a cq_theta result itself (a user register, rule 2), seen through the
// views that name the same rail (a zext of an i1 into a _Bool cell, freeze). A zext the spine lowered
// as a template into a fresh rail is not the register (cq-eq5x finding 1).
bool isThetaResult(LoweringContext &ctx, const Value *v, const Operand &val) {
  if (auto *z = dyn_cast<ZExtInst>(v); z && z->getSrcTy()->isIntegerTy(1))
    v = z->getOperand(0);
  if (auto *fr = dyn_cast<FreezeInst>(v))
    v = fr->getOperand(0);
  auto *call = dyn_cast<CallInst>(v);
  const Function *f = call ? call->getCalledFunction() : nullptr;
  if (!f || !f->getName().starts_with("cq_theta_"))
    return false;
  Operand t = ctx.operand(call);
  return t.handle && t.v == val.v;
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

// cq-bfz4: the original values that name handle h: the value of a lowered store that left h in its cell,
// a lowered load that read h, and their views and in-place rotations (freeze, bitcast, cq_theta).
void railNames(FnState &st, const Value *h, SmallPtrSetImpl<const Value *> &out) {
  SmallVector<const Value *, 8> work;
  for (auto &[I, op] : st.lowered) {
    if (!op.handle || op.v != h)
      continue;
    const Value *n = I;
    if (auto *X = dyn_cast<StoreInst>(I))
      n = X->getValueOperand();
    else if (!isa<LoadInst>(I))
      continue;
    if (!isa<Constant>(n) && out.insert(n).second)
      work.push_back(n);
  }
  while (!work.empty()) {
    const Value *x = work.pop_back_val();
    for (const User *u : x->users()) {
      auto *c = dyn_cast<CallInst>(u);
      bool same = isa<FreezeInst>(u) || isa<BitCastInst>(u) ||
                  (c && c->getCalledFunction() && c->getCalledFunction()->getName().starts_with("cq_theta_") &&
                   c->arg_size() && c->getArgOperand(0) == x);
      if (same && out.insert(u).second)
        work.push_back(u);
    }
  }
}

// cq-bfz4 (orchestrator decision 2026-11-01, revising cq-dr4o; CR rules 2, 20, 190 memmove_overlap and
// escape): one rail may sit in several cells (and SSA names) as long as nothing writes it in place: C's
// copies then hold equal values, and a read never writes a rail (rule 4). True when a non-diagonal in-place
// write on a rail named by `names` or held by a cell of `objs` may follow `at` (reachable from it): a
// cq_theta (rule 2) whose operand is such a name, a load of such an object, or a value chosen among
// handles (a phi or a classical select), or a call of a function with a body (a clone, rule 18; an
// indirect call) handed a pointer into such an object or such a name. A callee with no body (rule 27, a
// declared clone: its twin restores the cells) and the cq_ surface otherwise are no in-place write.
bool inPlaceMayFollow(LoweringContext &ctx, FnState &st, const Instruction &at, ArrayRef<ObjectId> objs,
                      const SmallPtrSetImpl<const Value *> *names) {
  auto inObjs = [&](const Value *p) {
    if (!p->getType()->isPointerTy())
      return false;
    for (ObjectId x : ctx.T.provenance(p, ctx.S))
      if (is_contained(objs, x))
        return true;
    return false;
  };
  auto mayBeRail = [&](const Value *x) {
    for (unsigned g = 0; g < 64; ++g) {
      if (names && names->count(x))
        return true;
      if (isa<FreezeInst>(x) || isa<CastInst>(x)) {
        x = cast<Instruction>(x)->getOperand(0);
        continue;
      }
      if (auto *c = dyn_cast<CallInst>(x); c && c->getCalledFunction() &&
                                          c->getCalledFunction()->getName().starts_with("cq_theta_") &&
                                          c->arg_size()) {
        x = c->getArgOperand(0);
        continue;
      }
      if (auto *ld = dyn_cast<LoadInst>(x))
        return inObjs(ld->getPointerOperand());
      return isa<PHINode>(x) || isa<SelectInst>(x);
    }
    return true;
  };
  auto hit = [&](const Instruction &I) {
    auto *CB = dyn_cast<CallBase>(&I);
    if (!CB || isa<DbgInfoIntrinsic>(CB))
      return false;
    const Function *f = CB->getCalledFunction();
    if (f && f->getName().starts_with("cq_theta_"))
      return CB->arg_size() && ctx.T.isQuantum(CB->getArgOperand(0), ctx.S) && mayBeRail(CB->getArgOperand(0));
    if (isCqSurface(*CB) || isa<IntrinsicInst>(CB) || (f && f->isDeclaration()))
      return false;
    for (const Use &u : CB->args())
      if (inObjs(u.get()) || (ctx.T.isQuantum(u.get(), ctx.S) && mayBeRail(u.get())))
        return true;
    return false;
  };
  const BasicBlock *AB = at.getParent();
  for (auto it = std::next(at.getIterator()); it != AB->end(); ++it)
    if (hit(*it))
      return true;
  SmallPtrSet<const BasicBlock *, 16> seen;
  SmallVector<const BasicBlock *, 16> work(succ_begin(AB), succ_end(AB));
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    if (!seen.insert(b).second)
      continue;
    for (const Instruction &I : *b)
      if (hit(I))
        return true;
    work.append(succ_begin(b), succ_end(b));
  }
  return false;
}

// CR rule 20 slot store, C value semantics (cq-dr4o): the rail replaces the cell, and C copies the
// value. When the handle S stores may still be read after S through another holder (a cell other
// than S's, or an SSA value naming the rail), the two C objects would share one rail and an in-place
// gate on one (rule 2) would change the other: S then stores a basis copy (CR §0). It is a move (the
// handle itself, no gate) when no other holder can be read after S, and (cq-bfz4) the cells share the
// rail when no in-place write on any holder may follow S (inPlaceMayFollow).
// holderMayBeRead: the read half of that test; it leaves the rail's names and its holders' objects in
// namesOut and objsOut for inPlaceMayFollow (needsCopy below).
bool holderMayBeRead(LoweringContext &ctx, FnState &st, const StoreInst &S, const Site &dest,
                     SmallPtrSetImpl<const Value *> &namesOut, SmallVectorImpl<ObjectId> &objsOut) {
  const DataLayout &DL = ctx.M.getDataLayout();
  const Value *v = S.getValueOperand();
  // A constant names no rail (its store is a seed, rule 7), and its users span the module (121: the 'a'
  // stored by two functions).
  if (isa<Constant>(v))
    return false;
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
    if (!sameRail(U, x) || isa<Constant>(x))
      break;   // a constant (cq_theta's classical initial value) names no rail: its users span the module
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
  namesOut.insert(names.begin(), names.end());
  for (const Holder &h : holders)
    if (!is_contained(objsOut, h.o))
      objsOut.push_back(h.o);
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
  // cq-kwmu (CR rules 2, 20): an in-place cq_theta of a name whose result (through further in-place
  // cq_theta) is only stored back into S's own cell rotates the cell's rail, not another holder's (61's
  // prep: *x = cq_theta(*x); if (y > k) *x = cq_theta(*x), which -O1 writes as cq_theta of the first
  // result). Any other use of such a result is a read and is checked as a name.
  std::function<bool(const Value *, unsigned)> inPlaceOnDest = [&](const Value *x, unsigned depth) {
    if (depth > 16 || x->use_empty())
      return false;
    for (const User *w : x->users()) {
      if (auto *X = dyn_cast<StoreInst>(w)) {
        if (X->getValueOperand() != x || X->isVolatile() || X->isAtomic() ||
            ctx.T.isFatPointer(X->getPointerOperand(), ctx.S) || !hasObject(ctx, X->getPointerOperand(), dest.o) ||
            !sameCell(decompose(X->getPointerOperand(), DL), dest.a) ||
            DL.getTypeStoreSize(x->getType()) != DL.getTypeStoreSize(v->getType()))
          return false;
        continue;
      }
      auto *c = dyn_cast<CallInst>(w);
      if (!c || !c->getCalledFunction() || !c->getCalledFunction()->getName().starts_with("cq_theta_") ||
          c->getArgOperand(0) != x || !inPlaceOnDest(c, depth + 1))
        return false;
    }
    return true;
  };
  for (const Value *n : names)
    for (const User *u : n->users()) {
      auto *U = dyn_cast<Instruction>(u);
      if (!U || U == &S || slotStoreOf(U, n))
        continue;
      if (auto *c = dyn_cast<CallInst>(U); c && sameRail(c, n) && inPlaceOnDest(c, 0))
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

bool needsCopy(LoweringContext &ctx, FnState &st, const StoreInst &S, const Site &dest) {
  SmallPtrSet<const Value *, 8> names;
  SmallVector<ObjectId, 4> objs{dest.o};
  if (!holderMayBeRead(ctx, st, S, dest, names, objs))
    return false;
  return inPlaceMayFollow(ctx, st, S, objs, &names);
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
//  - a load reads each of its bytes from the value of the last store that wrote it (cq-i0fv): the bits of
//    the latest overlapping value V (lshr(V, 8r), truncated), and the bytes before and past V from the
//    values before it, each piece zero-extended and shifted to its place and or-ed together; bytes no
//    store wrote are padding (LLVM reads them as undef, 0 is one of its values). A load reaching bytes a
//    narrower store wrote past V is unimplemented, as is a store starting before the value it writes
//    into, a load no dominating store reaches unchanged, bytes a store wrote on some path only, a
//    run-time offset, and a store under a quantum predicate.

unsigned bitsOf(const DataLayout &DL, Type *t);

// The latest store into the view object whose bytes, or the value it left, overlap [at.off, at.off + n)
// and reach I unchanged.
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
    // cq-0kji: a store overlaps the bytes when its own bytes do, or the value it left covers them (a narrower
    // store merged into a value leaves the whole merged value, 63).
    bool over = a.a.off < at.off + int64_t(n) && at.off < a.a.off + m;
    if (auto vit = st.views.find(S); vit != st.views.end()) {
      int64_t vo = vit->second.off, vb = int64_t((bitsOf(DL, vit->second.ty) + 7) / 8);
      over |= vo < at.off + int64_t(n) && at.off < vo + vb;
    }
    if (!over)
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

// One piece of a bit view load: bits [8 * (byte - load offset), + bits) of the loaded value come from the
// rail h (an integer of exactly `bits` bits); bytes no piece covers are padding the program never wrote
// (LLVM reads them as undef, 0 is one of its values).
struct ViewPiece { int64_t byte; unsigned bits; Value *h; };

// The pieces of the bytes [a, b) as of I (cq-i0fv): the latest store overlapping them that reaches I
// unchanged gives the bytes its value covers; the bytes before and past that value come from the stores
// before it (each found the same way over its own range: a store the latest one does not overlap there
// is not overwritten by it).
void viewPieces(LoweringContext &ctx, FnState &st, const Site &s, const Instruction &I, int64_t a, int64_t b,
                bool top, SmallVectorImpl<ViewPiece> &out) {
  const DataLayout &DL = ctx.M.getDataLayout();
  Addr at = s.a;
  at.off = a;
  const StoreInst *src = viewSource(ctx, st, *s.info, s.o, &I, at, uint64_t(b - a));
  if (!src) {
    if (top)
      unimplemented("mem-slots: a load of a bit-view slot object that no dominating store of this function reaches "
                    "unchanged (63)",
                    &I);
    // Padding only when no store of these bytes may reach I at all (one on some path only, a store in a
    // classical branch, leaves bytes this load cannot name).
    for (const Access &x : accessesOf(ctx, *st.F, s.o))
      if (isa<StoreInst>(x.I) && x.a.off < b && a < x.a.off + int64_t(storeBytes(DL, x.ty)) &&
          isPotentiallyReachable(x.I, &I, nullptr, st.DT.get()))
        unimplemented("mem-slots: a bit view load of bytes a store of this function wrote on some path only", &I);
    return;   // padding
  }
  auto it = st.views.find(src);
  if (it == st.views.end())
    internalError("mem-slots: the store a bit view reads has not been lowered", &I);
  const ViewVal V = it->second;
  unsigned N = bitsOf(DL, V.ty);
  int64_t ve = V.off + int64_t((N + 7) / 8);   // the bytes V's value covers: [V.off, ve)
  if (a >= ve)
    unimplemented(V.tailWritten ? "mem-slots: a bit view load of bytes a narrower store wrote past the value it "
                                  "wrote into"
                                : "mem-slots: a bit view load of padding bytes only (past the stored value)",
                  &I);
  if (a < V.off)
    viewPieces(ctx, st, s, I, a, V.off, false, out);
  int64_t lo = std::max(a, V.off), hi = std::min(b, ve);
  unsigned r = unsigned(8 * (lo - V.off)), len = std::min(unsigned(8 * (hi - V.off)), N) - r;
  Value *x = intView(ctx, V.h, V.ty);
  RailType iN{Kind::Int, N};
  if (r)
    x = viewTemplate(ctx, "lshr", iN, std::nullopt, {Operand{x, true}, lit(ctx, N, APInt(N, uint64_t(r)))}, "hl");
  if (len < N)
    x = viewTemplate(ctx, "trunc", iN, RailType{Kind::Int, len}, {Operand{x, true}});
  out.push_back(ViewPiece{lo, len, x});
  if (b > ve) {
    if (V.tailWritten)
      unimplemented("mem-slots: a bit view load of bytes a narrower store wrote past the value it wrote into", &I);
    viewPieces(ctx, st, s, I, ve, b, false, out);
  }
}

Value *readView(LoweringContext &ctx, FnState &st, const Site &s, const Instruction &I, Type *ty) {
  const DataLayout &DL = ctx.M.getDataLayout();
  if (!ty->isIntegerTy() && !ty->isFloatingPointTy())
    unimplemented("mem-slots: a bit view load of a non-scalar type", &I);
  int64_t n = int64_t(storeBytes(DL, ty));
  if (const StoreInst *src = viewSource(ctx, st, *s.info, s.o, &I, s.a, uint64_t(n))) {
    auto it = st.views.find(src);
    if (it != st.views.end() && it->second.off == s.a.off && it->second.ty == ty)
      return it->second.h;   // the stored value itself
  }
  SmallVector<ViewPiece, 4> pieces;
  viewPieces(ctx, st, s, I, s.a.off, s.a.off + n, true, pieces);
  unsigned M = bitsOf(DL, ty);
  RailType iM{Kind::Int, M};
  Value *x = nullptr;
  for (const ViewPiece &p : pieces) {
    unsigned pos = unsigned(8 * (p.byte - s.a.off));
    if (pos >= M)
      continue;   // bits past the loaded type (a padding byte of an f80 load)
    Value *y = p.h;
    unsigned bits = p.bits;
    if (pos + bits > M) {
      y = viewTemplate(ctx, "trunc", RailType{Kind::Int, bits}, RailType{Kind::Int, M - pos}, {Operand{y, true}});
      bits = M - pos;
    }
    if (bits < M)
      y = viewTemplate(ctx, "zext", RailType{Kind::Int, bits}, iM, {Operand{y, true}});
    if (pos)
      y = viewTemplate(ctx, "shl", iM, std::nullopt, {Operand{y, true}, lit(ctx, M, APInt(M, pos))}, "hl");
    x = x ? viewTemplate(ctx, "or", iM, std::nullopt, {Operand{x, true}, Operand{y, true}}) : y;
  }
  if (!x)
    internalError("mem-slots: a bit view load with no piece inside its bits", &I);
  if (!ty->isIntegerTy())
    x = viewTemplate(ctx, "bitcast", iM, railTypeOf(ty), {Operand{x, true}});
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

// CR rules 9, 18, 20 (51): a clone's stores into one caller cell, each in its own arm under a quantum
// predicate, are one value at the join: the select tree over the arms (rule 9, selectChain), copied out
// once (rule 18: alloc 0, copy, store the copy, Role::Result) at the last of them. No store emits anything
// before. The cell's rail is the floating-point view when some access of it is floating point (51's
// punned i64 stores of a double: a bitcast). Arms that do not cover every path select the caller's old
// content there (cq-vxgm). Unimplemented: an arm store some other store may reach, and a load of the cell in
// the clone.
bool mergedCloneStore(LoweringContext &ctx, FnState &st, const Site &s, StoreInst &stI, Operand val) {
  if (s.info->kind != RootKind::Param || ctx.S.isEntry() || !ctx.currentFlag() || s.info->view ||
      s.info->boolCells || !s.a.terms.empty())
    return false;
  const DataLayout &DL = ctx.M.getDataLayout();
  Type *vty = stI.getValueOperand()->getType();
  uint64_t sz = storeBytes(DL, vty);
  SmallVector<const StoreInst *, 4> stores;
  Type *cellTy = vty;
  for (const Access &a : accessesOf(ctx, *st.F, s.o)) {
    if (differentCell(a.a, s.a, storeBytes(DL, a.ty), sz))
      continue;
    if (!sameCell(a.a, s.a) || storeBytes(DL, a.ty) != sz)
      unimplemented("mem-slots: a clone's arm stores into a caller cell overlapping another access of it", &stI);
    if (isa<LoadInst>(a.I))
      unimplemented("mem-slots: a clone reading a caller cell it stores into under a quantum predicate", a.I);
    auto *S = dyn_cast<StoreInst>(a.I);
    if (!S)
      unimplemented("mem-slots: an atomic access of a caller cell a clone stores into under a quantum predicate",
                    a.I);
    if (ctx.preds().block(S->getParent()).quantumPart(ctx.T, ctx.S).isTop())
      unimplemented("mem-slots: a clone storing into a caller cell both unconditionally and under a quantum "
                    "predicate",
                    S);
    stores.push_back(S);
    if (a.ty->isFloatingPointTy())
      cellTy = a.ty;
  }
  for (const StoreInst *x : stores)
    for (const StoreInst *y : stores)
      if (x != y && isPotentiallyReachable(x, y, nullptr, st.DT.get()))
        unimplemented("mem-slots: a clone storing into a caller cell that an earlier store of the clone may have "
                      "filled (two slot results for one cell)",
                      y);
  RailType w = railTypeOf(cellTy);
  if (vty != cellTy) {
    if (val.handle)
      val = Operand{viewTemplate(ctx, "bitcast", railTypeOf(vty), w, {val}), true};
    else
      val = Operand{ctx.B().CreateBitCast(val.v, cellTy), false};
  }
  auto &arms = st.cloneArms[s.a.off];
  arms.push_back({ctx.preds().block(stI.getParent()), val});
  st.lowered[&stI] = val;
  if (arms.size() < stores.size())
    return true;
  Pred any = arms.front().first;
  for (auto &a : arms)
    any = any | a.first;
  SmallVector<std::pair<Pred, Operand>, 4> chain(arms.begin(), arms.end());
  if (!any.isTop()) {
    // cq-vxgm (owner 2026-11-01, rule 20 guarded store): the clone always writes the cell; where no arm
    // stores, the select's arm is the cell's old content, the caller's handle loaded here (calls'
    // finalize gives the twin old_k for this load, which precedes the copy-out).
    for (const StoreInst *x : stores)
      if (x->getValueOperand()->getType() != cellTy)
        unimplemented("mem-slots: a clone's arm stores of several types into a caller cell that leave it "
                      "unwritten on some path (the old content's type is the caller's)",
                      x);
    for (auto &a : arms)
      if (!a.first.classicalFactor(ctx.T, ctx.S).isTop())
        unimplemented("mem-slots: a clone's arm stores into a caller cell under quantum predicates inside "
                      "classical arms that leave it unwritten on some path",
                      &stI);
    LoadInst *old = ctx.B().CreateAlignedLoad(handleTy(ctx.M.getContext()), cellPointer(ctx, s, stI), Align(4));
    ctx.unc().recordExternal(old, Role::UserRegister);   // the caller's rail: never the clone's
    st.registers.insert(old);
    chain.push_back({!any, Operand{old, true}});
  }
  Value *sel = selectChain(ctx, chain, w);
  CallInst *c = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
  RailId cid = ctx.unc().recordSeed(c);
  abi::CoreSpec cp{abi::Core::Copy, w};
  CallInst *cc = ctx.emitCore(cp, {sel, c});
  ctx.unc().recordCore(cc, cp, {Operand{sel, true}, Operand{c, true}}, cid);
  ctx.unc().setRole(cid, Role::Result);
  st.registers.insert(c);
  ctx.B().CreateAlignedStore(c, cellPointer(ctx, s, stI), Align(4));
  st.lowered[&stI] = Operand{c, true};
  return true;
}

// The role of a rail stored into a slot cell (rule 20), the handle store and the cell's new content.
// The cells of object o may hold user registers (rule 2): a cq_theta result is stored into it, a cq_theta
// reads a value loaded from it (through casts), or a clone or unknown function is handed a pointer into it.
bool cellsHoldRegisters(LoweringContext &ctx, FnState &st, ObjectId o) {
  auto theta = [](const Value *v) {
    while (auto *c = dyn_cast<CastInst>(v))
      v = c->getOperand(0);
    auto *CB = dyn_cast<CallBase>(v);
    const Function *f = CB ? CB->getCalledFunction() : nullptr;
    return f && f->getName().starts_with("cq_theta");
  };
  for (const Access &a : accessesOf(ctx, *st.F, o))
    if (auto *S = dyn_cast<StoreInst>(a.I); S && theta(S->getValueOperand()))
      return true;
  for (const Instruction &X : instructions(*st.F)) {
    auto *CB = dyn_cast<CallBase>(&X);
    if (!CB || isa<DbgInfoIntrinsic>(CB) || isa<MemIntrinsic>(CB))
      continue;
    if (auto *II = dyn_cast<IntrinsicInst>(CB); II && II->isLifetimeStartOrEnd())
      continue;
    const Function *f = CB->getCalledFunction();
    bool theta = f && f->getName().starts_with("cq_theta");
    for (const Use &u : CB->args()) {
      const Value *v = u.get();
      if (v->getType()->isPointerTy()) {
        if (!theta && hasObject(ctx, v, o))
          return true;
        continue;
      }
      if (!theta)
        continue;
      while (auto *c = dyn_cast<CastInst>(v))
        v = c->getOperand(0);
      if (auto *ld = dyn_cast<LoadInst>(v); ld && hasObject(ctx, ld->getPointerOperand(), o))
        return true;
    }
  }
  return false;
}

// cq-bfz4: every store into the object writes its own cell once: a classical constant offset, outside any
// cycle, no two stores of one cell.
bool storesOnce(LoweringContext &ctx, FnState &st, ObjectId o) {
  if (!st.LI)
    st.LI = std::make_unique<LoopInfo>(*st.DT);
  const DataLayout &DL = ctx.M.getDataLayout();
  SmallVector<Access, 8> stores;
  for (const Access &a : accessesOf(ctx, *st.F, o)) {
    if (!isa<StoreInst>(a.I))
      continue;
    if (!a.a.ok || !a.a.terms.empty() || st.LI->getLoopFor(a.I->getParent()))
      return false;
    for (const Access &b : stores)
      if (!differentCell(a.a, b.a, storeBytes(DL, a.ty), storeBytes(DL, b.ty)))
        return false;
    stores.push_back(a);
  }
  return true;
}

void finishStore(LoweringContext &ctx, FnState &st, const Site &s, Instruction &I, Type *ty, Operand val,
                 StoreWhat what) {
  using What = StoreWhat;
  IRBuilder<> &B = ctx.B();
  if (const GlobalVariable *gv = programSlotOf(s)) {
    // 102: a program slot keeps what it is given (see programSlot): a classical store's seed in a function
    // that does not load it, or the guarded store's select in a _ctl clone.
    bool seed = what == What::Seed && !ctx.currentFlag() && ctx.currentPredicate().isTop() &&
                !loadsGlobal(*st.F, *gv) && !ctx.loopUnit();
    bool guarded = what == What::Computed && cloneReadsProgramSlot(ctx, *gv, I);
    if (!seed && !guarded)
      unimplemented("mem-slots: a store into a program slot (102) other than a classical store in a function "
                    "that does not load it or a _ctl clone's guarded store",
                    &I);
    ensureSlotCtor(ctx.M, *gv);
    ctx.unc().setRole(ctx.unc().idOf(val.v), Role::Output);
    st.registers.insert(val.v);
    B.CreateAlignedStore(val.v, const_cast<GlobalVariable *>(gv), Align(4));
    st.lowered[&I] = val;
    return;
  }
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
            // The store's own read of the old cell (a guarded store) precedes it: only a cycle through the
            // store's block brings the store round to it.
            bool reaches = R.I == &I ? any_of(successors(I.getParent()),
                                              [&](const BasicBlock *b) {
                                                return isPotentiallyReachable(b, I.getParent(), nullptr,
                                                                              st.DT.get());
                                              })
                                     : isPotentiallyReachable(&I, R.I, nullptr, st.DT.get());
            if (R.a.root == s.a.root && !differentCell(R.a, s.a, R.size, sz) && reaches &&
                !sameClassicalLoop(ctx, st, &I, R.I))
              unimplemented("mem-slots: a computed rail stored into a slot cell that an earlier-lowered run-time "
                            "read may see on a back edge (the cell's rail is loop-carried through memory: 187)",
                            &I);
          }
          noteDistinctStore(ctx, st, s, I, sz, val.v);
          if (measuredThroughMemory(ctx, st, I, ty, s)) {
            ctx.unc().setRole(id, Role::Measured);
            st.registers.insert(val.v);
          }
          break;
        }
        // The cells of a dynamic slot array are registers (58, 59: seeded |0>, kept).
        ctx.unc().setRole(id, Role::UserRegister);
        if (what == What::Seed && (!cellsHoldRegisters(ctx, st, s.o) ||
                                   (storesOnce(ctx, st, s.o) && !inPlaceMayFollow(ctx, st, I, {s.o}, nullptr)))) {
          // Rule 7 (129's f seeds): no user register ever enters the object's cells (no cq_theta result
          // stored there or applied to a load of it, no clone handed a pointer into it), so a seed keeps its
          // classical value: released at the object's lifetime end (endSlotLifetime). It is no register for
          // the run-time reads (each names it, M3), so its release follows them. cq-bfz4 (190): registers
          // may enter the cells, but no in-place write on a cell may follow the seed's store
          // (inPlaceMayFollow) and no store overwrites a cell (storesOnce: freeOverwrittenSeed frees an
          // overwritten seed itself, 121): the seed is never written either.
          st.releasable[s.a.root].push_back(val.v);
          st.seeds.insert(val.v);
          break;
        }
        st.registers.insert(val.v);
      }
      break;
    case RootKind::Param:
      if (!ctx.S.isEntry()) {
        // T5 (109's put): the clone stores a formal's handle unchanged into the caller's cell (taint's
        // cellForward): the cell holds the caller's own rail after the call; no copy-out, no twin for it.
        if (auto *PA = dyn_cast<Argument>(s.a.root); PA && s.a.terms.empty() && s.a.off >= 0) {
          uint64_t sz = storeBytes(ctx.M.getDataLayout(), ty);
          int j = ctx.T.cellForward(ctx.S, PA->getArgNo(), unsigned(uint64_t(s.a.off) / sz));
          auto *SI = dyn_cast<StoreInst>(&I);
          if (j >= 0 && SI && SI->getValueOperand() == ctx.S.F->getArg(unsigned(j)))
            break;
        }
        // M1 clone side (CR rule 18, cq-arch T2 + M1): a handle stored into a caller's cell is a slot
        // result: the rule-18 copy-out (alloc 0, copy, the copy's handle into the cell, Role::Result). The
        // caller loads it after the call and frees it after the twin, which finalize aims at it and which
        // restores the cell's old content.
        const DataLayout &DL = ctx.M.getDataLayout();
        if (ctx.currentFlag())
          unimplemented("mem-slots: a clone storing into a caller's cell under a quantum predicate (the select's "
                        "old arm is the caller's content: 51)",
                        &I);
        for (const Access &a : accessesOf(ctx, *st.F, s.o))
          if (a.I != &I && (isa<StoreInst>(a.I) || isRMW(a.I)) &&
              !differentCell(a.a, s.a, storeBytes(DL, a.ty), storeBytes(DL, ty)) &&
              isPotentiallyReachable(a.I, &I, nullptr, st.DT.get()))
            unimplemented("mem-slots: a clone storing into a caller's cell that an earlier store of the clone may "
                          "have filled (two slot results for one cell)",
                          &I);
        RailType w = cellRail(*s.info, ty, I);
        // cq-vxgm (owner 2026-11-01, rule 20 guarded store): the caller reloads the cell after the call and
        // cleans its old content (rule 6), so the clone always writes it. When a returning path leaves the
        // cell unwritten (a store under a classical condition), the cell's content at return is
        // select(arm predicate, value, old) in a fresh rail f, copied out: at the clone's entry
        // old = load cell, f = alloc_<W>(0), copy(old, f), store f into the cell; at each arm store
        // copy(old, f), copy(v, f) (copy is an XOR: f = v on the arm, old elsewhere). The twin (calls'
        // finalize) replays the copies into the cell's handle, zeroing it, and stores old_k back.
        {
          Pred written = ctx.preds().block(I.getParent());
          for (const Access &a : accessesOf(ctx, *st.F, s.o))
            if ((isa<StoreInst>(a.I) || isRMW(a.I)) && !differentCell(a.a, s.a, storeBytes(DL, a.ty), storeBytes(DL, ty)))
              written = written | ctx.preds().block(a.I->getParent());
          bool partial = false;
          for (const BasicBlock &bb : *st.F)
            if (isa<ReturnInst>(bb.getTerminator()) && !(ctx.preds().block(&bb) & !written).isBottom())
              partial = true;
          if (partial) {
            if (!s.a.terms.empty() || s.info->view || s.info->boolCells)
              unimplemented("mem-slots: a clone storing on some paths only into a caller cell at a run-time offset "
                            "or of a bit-view or _Bool object",
                            &I);
            for (const Access &a : accessesOf(ctx, *st.F, s.o)) {
              if (differentCell(a.a, s.a, storeBytes(DL, a.ty), storeBytes(DL, ty)))
                continue;
              if (!isa<StoreInst>(a.I))
                unimplemented("mem-slots: a clone reading or atomically updating a caller cell it writes on some "
                              "paths only (the cell holds the slot result from the clone's entry)",
                              a.I);
              if (!sameCell(a.a, s.a) || a.ty != ty)
                unimplemented("mem-slots: a clone writing a caller cell on some paths only through another view "
                              "of it",
                              a.I);
            }
            auto key = std::make_pair(s.a.root, s.a.off);
            auto g = st.guardedCells.find(key);
            if (g == st.guardedCells.end()) {
              IRBuilderBase::InsertPointGuard guard(B);
              BasicBlock &E = ctx.out().getEntryBlock();
              B.SetInsertPoint(&E, E.getFirstInsertionPt());
              LoadInst *old = B.CreateAlignedLoad(handleTy(ctx.M.getContext()), cellPointer(ctx, s, I), Align(4));
              ctx.unc().recordExternal(old, Role::UserRegister);   // the caller's rail: never the clone's
              st.registers.insert(old);
              CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                         {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
              RailId fid = ctx.unc().recordSeed(f);
              abi::CoreSpec cp{abi::Core::Copy, w};
              CallInst *cc = ctx.emitCore(cp, {old, f});
              ctx.unc().recordCore(cc, cp, {Operand{old, true}, Operand{f, true}}, fid);
              ctx.unc().setRole(fid, Role::Result);
              st.registers.insert(f);
              B.CreateAlignedStore(f, cellPointer(ctx, s, I), Align(4));
              g = st.guardedCells.emplace(key, std::pair<Value *, Value *>(old, f)).first;
            }
            Value *old = g->second.first, *f = g->second.second;
            RailId fid = ctx.unc().idOf(f);
            abi::CoreSpec cp{abi::Core::Copy, w};
            CallInst *c1 = ctx.emitCore(cp, {old, f});
            ctx.unc().recordCore(c1, cp, {Operand{old, true}, Operand{f, true}}, fid);
            CallInst *c2 = ctx.emitCore(cp, {val.v, f});
            ctx.unc().recordCore(c2, cp, {val, Operand{f, true}}, fid);
            st.lowered[&I] = Operand{f, true};
            return;
          }
        }
        // Literally alloc_<W>(0), copy(v, c), store c (calls' finalize rewrites this sequence in the twin),
        // a seed included (it stays the clone's, freed directly).
        CallInst *c = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                   {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
        RailId cid = ctx.unc().recordSeed(c);
        abi::CoreSpec cp{abi::Core::Copy, w};
        CallInst *cc = ctx.emitCore(cp, {val.v, c});
        ctx.unc().recordCore(cc, cp, {val, Operand{c, true}}, cid);
        ctx.unc().setRole(cid, Role::Result);
        val = Operand{c, true};
        st.registers.insert(val.v);
        break;
      }
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

// cq-r7-91 (CR rules 9, 20; whatever LLVM does, we do): the cells of a fresh uninitialized allocation (an
// alloca, or a call whose allockind is alloc + uninitialized: malloc, not calloc) are undef until written. A
// store under a quantum predicate into a plain cell that no write reached since its allocation is select(p,
// v, undef), which LLVM folds to v: the store is unguarded (91's trip objects: "it runs unguarded under the
// trip predicate because the object is fresh in its trip"). The allocation dominates the store, and a path
// back to the store that does not re-execute the allocation (the store on a cycle of its own) is excluded.
bool freshCell(LoweringContext &ctx, FnState &st, const Site &s, const StoreInst &S) {
  if (!s.a.ok || s.beyond || s.info->view || s.info->boolCells || s.info->record || s.info->split ||
      s.info->escaping || S.isVolatile() || S.isAtomic())
    return false;
  if (s.info->kind != RootKind::Heap && s.info->kind != RootKind::Local)
    return false;
  auto *R = dyn_cast<Instruction>(s.a.root);
  if (!R || R->getFunction() != S.getFunction() || !st.DT->dominates(R, &S))
    return false;
  if (auto *CB = dyn_cast<CallBase>(R)) {
    Attribute k = CB->getFnAttr(Attribute::AllocKind);
    if (!k.isValid())
      return false;
    auto kind = AllocFnKind(k.getValueAsInt());
    if ((kind & AllocFnKind::Alloc) == AllocFnKind::Unknown ||
        (kind & AllocFnKind::Uninitialized) == AllocFnKind::Unknown)
      return false;
  } else if (!isa<AllocaInst>(R)) {
    return false;
  }
  if (R->getParent() != S.getParent() && onCycleWithin(S.getParent(), between(R->getParent(), S.getParent())))
    return false;
  for (const Instruction &X : instructions(*st.F))
    if (auto *MI = dyn_cast<MemIntrinsic>(&X); MI && hasObject(ctx, MI->getDest(), s.o))
      return false;
  uint64_t size = storeBytes(ctx.M.getDataLayout(), S.getValueOperand()->getType());
  return clearBetween(ctx, *s.info, s.o, R, &S, s.a, size);
}

} // namespace

// M7 (cq-z6q1, CR rules 20, 21; 189).
bool hostRecord(LoweringContext &ctx, const Value *root) {
  auto *I = dyn_cast<CallBase>(root);
  if (!I || !I->getFnAttr(Attribute::AllocKind).isValid() || ctx.T.isQuantum(root, ctx.S))
    return false;
  ArrayRef<ObjectId> objs = ctx.T.provenance(root, ctx.S);
  if (objs.size() != 1 || ctx.T.objectOf(root) != objs.front())
    return false;
  ObjectId o = objs.front();
  if (ctx.T.classOf(o) != ObjClass::Slot)
    return false;
  FnState &st = stateOf(ctx, *I);
  ObjInfo &info = objInfo(ctx, st, root, o);
  return info.kind == RootKind::Heap && info.record;
}

Operand loadSlotCellAt(LoweringContext &ctx, const Value *root, int64_t byte, Type *ty, Instruction &at) {
  if (!hostRecord(ctx, root))
    unimplemented("mem-slots: a fat-pointer load from a slot object that is not a heap record (rule 21 guarded "
                  "slot select)",
                  &at);
  FnState &st = stateOf(ctx, at);
  Site s = siteOf(ctx, st, at, root, ty, byte);
  if (classicalCell(ctx, st, s)) {
    // A classical field (a pointer field among them) is host memory: the host load of it.
    LoadInst *nl = ctx.B().CreateAlignedLoad(ty, cellPointer(ctx, s, at), ctx.M.getDataLayout().getABITypeAlign(ty));
    return Operand{nl, false};
  }
  cellRail(*s.info, ty, at);
  return readCell(ctx, st, s, at, ty);
}

void allocateSlots(LoweringContext &ctx, Instruction &site) {
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  const DataLayout &DL = ctx.M.getDataLayout();
  FnState &st = stateOf(ctx, site);
  ArrayRef<ObjectId> objs = ctx.T.provenance(&site, ctx.S);
  if (columnStruct(&site)) {
    // Rule 20 (129): an array of structs, one object per field column. The array keeps its layout: the
    // handle columns hold handles in their fields (objInfo checks each), the classical ones their C values.
    auto *ai = cast<AllocaInst>(&site);
    Operand n = ctx.operand(ai->getArraySize());
    if (n.handle)
      internalError("mem-slots: a slot array of quantum length (QRAM, rule 20)", &site);
    AllocaInst *na = B.CreateAlloca(ai->getAllocatedType(), n.v);
    na->setAlignment(std::max(ai->getAlign(), Align(4)));
    ctx.bindFields(&site, {Operand{na, false}});
    return;
  }
  if (objs.size() != 1)
    unimplemented("mem-slots: an allocation site that is " + std::to_string(objs.size()) +
                      " objects (an array of structs holding handles: one slot array per field column, 168)",
                  &site);
  ObjInfo &info = objInfo(ctx, st, &site, objs.front());
  if (info.record && info.kind == RootKind::Heap) {
    // cq-z6q1: a heap record is the host block itself (heapRecord: its cells fit at the fields' offsets).
    decideFields(ctx, st, info, objs.front());
  } else if (info.record) {
    auto *ai = dyn_cast<AllocaInst>(&site);
    if (!ai || !isa<ConstantInt>(ai->getArraySize()) || !cast<ConstantInt>(ai->getArraySize())->isOne())
      unimplemented("mem-slots: a slot record that is not one local struct object", &site);
    decideFields(ctx, st, info, objs.front());
    AllocaInst *na = B.CreateAlloca(info.recTy);
    na->setAlignment(std::max(ai->getAlign(), Align(4)));
    ctx.bindFields(&site, {Operand{na, false}});
    return;
  }
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
  if (!info.record && info.cellBytes != 4) {
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

// cq-qd05: the type of the rail the clone S leaves in the cell at byte offset off (size bytes) of the
// object its formal argNo points to: its stores through the formal at that cell (finishStore: the stored
// type; mergedCloneStore, 51: the floating-point type when some store is floating point), or, through a
// clone it hands the pointer to, that clone's. Null when no such store is found.
Type *cloneCellType(LoweringContext &ctx, const Specialization &S, unsigned argNo, int64_t off, uint64_t size,
                    const Instruction &at, unsigned depth = 0) {
  if (depth > 16)
    unimplemented("mem-slots: the rail type a clone leaves in a caller cell through a deep chain of clone calls",
                  &at);
  const DataLayout &DL = ctx.M.getDataLayout();
  const Argument *A = S.F->getArg(argNo);
  Type *fp = nullptr, *any = nullptr;
  SmallVector<const Instruction *, 4> writers;
  bool mixed = false;
  auto note = [&](Type *t, const Instruction &w) {
    if (any && t != any)
      mixed = true;
    if (t->isFloatingPointTy())
      fp = t;
    if (!any)
      any = t;
    writers.push_back(&w);
  };
  for (const Instruction &I : instructions(*S.F)) {
    if (auto *CB = dyn_cast<CallBase>(&I)) {
      if (isa<MemIntrinsic>(CB) || isa<DbgInfoIntrinsic>(CB) || isCqSurface(*CB))
        continue;
      const Function *f = CB->getCalledFunction();
      const Specialization *C =
          f && !f->isDeclaration() && !isa<IntrinsicInst>(CB) ? ctx.T.calleeSpecialization(*CB, S) : nullptr;
      if (!C)
        continue;
      for (unsigned i = 0; i < CB->arg_size(); ++i) {
        Addr pa = decompose(CB->getArgOperand(i), DL);
        if (pa.ok && pa.root == A && pa.terms.empty() && !ctx.T.cellsWritten(*C, i).empty())
          if (Type *t = cloneCellType(ctx, *C, i, off - pa.off, size, at, depth + 1))
            note(t, I);
      }
      continue;
    }
    const Value *ptr = nullptr;
    Type *ty = nullptr;
    if (auto *st = dyn_cast<StoreInst>(&I)) {
      ptr = st->getPointerOperand();
      ty = st->getValueOperand()->getType();
    } else if (auto *r = dyn_cast<AtomicRMWInst>(&I)) {
      ptr = r->getPointerOperand();
      ty = r->getValOperand()->getType();
    } else if (auto *c = dyn_cast<AtomicCmpXchgInst>(&I)) {
      ptr = c->getPointerOperand();
      ty = c->getNewValOperand()->getType();
    } else {
      continue;
    }
    Addr a = decompose(ptr, DL);
    if (a.ok && a.root == A && a.terms.empty() && a.off == off && storeBytes(DL, ty) == size)
      note(ty, I);
  }
  if (mixed) {
    // cq-nyto (3): writes of different types leave one rail type only when they are the arms of one
    // quantum-predicated merge (mergedCloneStore, 51: the floating-point view). A write that a classical
    // branch decides (it is control dependent on a conditional terminator with a classical condition)
    // leaves a rail whose type depends on the path (c1): unimplemented.
    Function &F = const_cast<Function &>(*S.F);
    DominatorTree DT(F);
    PostDominatorTree PDT(F);
    for (const Instruction *w : writers)
      for (const BasicBlock &X : F) {
        const Instruction *T = X.getTerminator();
        if (!T || T->getNumSuccessors() < 2 || !DT.dominates(&X, w->getParent()) ||
            PDT.dominates(w->getParent(), &X))
          continue;
        const Value *cond = nullptr;
        if (auto *br = dyn_cast<BranchInst>(T); br && br->isConditional())
          cond = br->getCondition();
        else if (auto *sw = dyn_cast<SwitchInst>(T))
          cond = sw->getCondition();
        if (!cond || !ctx.T.isQuantum(cond, S))
          unimplemented("mem-slots: a clone writes a caller cell at different types on paths a classical condition "
                        "chooses (the rail type the caller reads depends on the path: cq-nyto)",
                        w);
      }
  }
  return fp ? fp : any;
}

namespace {

// ---- pointer-kind cells (cq-oocu; CR rules 20, 21; 107) ------------------------------------------
//
// A slot record's pointer field is a cell of POINTER KIND: it holds a fat pointer as two handles (tag,
// idx; recTy elements rec and rec + 1). Its idx counts cells of the UNIT, the scalar element size of every
// object the pointers stored into the cell may point to (rule 21: idx is always a cell index).
//  - Caller (a local record, not dynamic, not escaping): a store of a pointer is unguarded; its tag is a
//    classical tag (a seed) or the fresh rail of a quantum-condition select whose only use is the store
//    (moved into the cell); its idx is classical (a seed). A load of a pointer is bound to the handles the
//    dominating store or clone call left; every access through the loaded pointer is at the unit. An integer
//    access of the cell in the caller (ptrtoint / inttoptr at the access) is unimplemented.
//  - Clone (a T4 Triple formal onto a slot object whose accessed cells are of pointer kind: two mask digits
//    per cell, §1.4): the object is one record (hostTriple: cell count 1), so its cells are at the object
//    itself (an idx other than 0 accesses past it: outside the domain). An i64 load is ptrtoint AT THE
//    LOAD: the integer is carried as its provenance T (the tag handle, which stays in the cell) plus the
//    byte offset unit * I (zext, shl), base[T] never materialised; the integer may only flow through add /
//    sub of classical constants into an i64 store into the same cell, which is inttoptr AT
//    THE STORE keeping T: the new idx (lshr, trunc) is the rule-18 copy-out into the idx half (the caller
//    reloads it, the twin zeroes it and restores the old idx). Anything else is unimplemented.

bool ptrField(const ObjInfo &info, int64_t off) {
  if (!info.record)
    return false;
  int k = fieldAt(info, off);
  return k >= 0 && info.fields[unsigned(k)].ty->isPointerTy() && info.fields[unsigned(k)].handle != 0;   // cq-z6q1
}

// The i32 pointer of half h (0 tag, 1 idx) of the pointer-kind cell of a caller's record.
Value *halfPointer(LoweringContext &ctx, const Site &s, const Instruction &I, unsigned h) {
  Operand base = ctx.operand(s.a.root);
  int k = fieldAt(*s.info, s.a.off);
  if (base.handle || k < 0 || !s.a.terms.empty() || !s.info->recTy)
    internalError("mem-slots: a pointer-kind cell half that is not one field of a record", &I);
  unsigned r = s.info->fields[unsigned(k)].rec + h;
  return r == 0 ? base.v : ctx.B().CreateStructGEP(s.info->recTy, base.v, r);
}

// The unit of the pointer-kind cell at (root, off) of F: the scalar element size of every object the
// pointers F stores there may point to.
uint64_t storedPtrUnit(LoweringContext &ctx, const Function &F, const Value *root, int64_t off,
                       const Instruction &at) {
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t unit = 0;
  for (const Instruction &X : instructions(F)) {
    auto *S = dyn_cast<StoreInst>(&X);
    if (!S)
      continue;
    Addr a = decompose(S->getPointerOperand(), DL);
    if (!a.ok || a.root != root || !a.terms.empty() || a.off != off)
      continue;
    if (!S->getValueOperand()->getType()->isPointerTy())
      unimplemented("mem-slots: an integer stored into a pointer-kind slot cell by its owner (inttoptr at the store "
                    "in the caller: rule 21)",
                    S);
    SmallVector<const Value *, 4> objs;
    getUnderlyingObjects(S->getValueOperand(), objs);
    for (const Value *o : objs) {
      Type *t = nullptr;
      if (auto *ai = dyn_cast<AllocaInst>(o))
        t = ai->getAllocatedType();
      else if (auto *gv = dyn_cast<GlobalVariable>(o))
        t = gv->getValueType();
      if (!t || scalarCellType(t)->isStructTy() || scalarCellType(t)->isVectorTy())
        unimplemented("mem-slots: a pointer-kind slot cell holding a pointer into an object that is not a local or "
                      "global array of scalars (its cell unit, rule 21)",
                      S);
      uint64_t u = DL.getTypeAllocSize(scalarCellType(t)).getFixedValue();
      if (unit && u != unit)
        unimplemented("mem-slots: a pointer-kind slot cell holding pointers into objects of two cell sizes (rule 21)",
                      S);
      unit = u;
    }
  }
  if (!unit)
    unimplemented("mem-slots: a pointer-kind slot cell into which its owner stores no pointer (its cell unit)", &at);
  return unit;
}

// In a clone: formal A is a T4 Triple onto a caller's slot object whose cells the clone accesses are all of
// pointer kind (two mask digits per accessed cell).
} // namespace

bool isPointerKindFormal(LoweringContext &ctx, const Argument &A) {
  if (ctx.S.isEntry() || !A.getType()->isPointerTy())
    return false;
  PtrFormal pf = ctx.T.pointerFormal(ctx.S, A.getArgNo());
  if (pf.abi == PtrAbi::Raw || pf.pointee != ObjClass::Slot)
    return false;
  // A quantum tag digit: an object table of slot objects (M7, 129: one digit per object's cell), never one record.
  size_t d = 0;
  for (const Argument &B : A.getParent()->args()) {
    if (&B == &A)
      break;
    d += B.getType()->isPointerTy() ? ctx.T.pointerFormal(ctx.S, B.getArgNo()).digits : ctx.T.fieldMask(&B, ctx.S).size();
  }
  if (d < ctx.S.mask.size() && ctx.S.mask[d] == '1')
    return false;
  const DataLayout &DL = ctx.M.getDataLayout();
  std::set<std::pair<int64_t, uint64_t>> cells;
  for (const Instruction &X : instructions(*A.getParent())) {
    const Value *p = isa<LoadInst>(X) || isa<StoreInst>(X) ? accessPtr(&X) : nullptr;
    if (!p)
      continue;
    Addr a = decompose(p, DL);
    if (!a.ok || a.root != &A)
      continue;
    Type *t = isa<LoadInst>(X) ? X.getType() : cast<StoreInst>(X).getValueOperand()->getType();
    cells.insert({a.terms.empty() ? a.off : INT64_MIN, storeBytes(DL, t)});
  }
  // TripleCount (CR rule 21: the callee loads through it) carries the record's cell count 1; the clone's cells
  // are at idx 0 of the object, an idx beyond it would access past the record (outside the domain).
  if (cells.empty() || pf.digits != 2 + 2 * cells.size())
    return false;
  for (auto &[off, sz] : cells)
    if (off == INT64_MIN || sz != 8)
      unimplemented("mem-slots: a clone accessing a caller's pointer-kind cell at a run-time offset or at another "
                    "width than the pointer (rule 21)",
                    &A);
  return true;
}

namespace {

bool sameSpec(const Specialization &a, const Specialization &b) {
  return a.F == b.F && a.mask == b.mask && a.ctl == b.ctl && a.pure == b.pure && a.adj == b.adj && a.depth == b.depth;
}

// In a clone: the unit of the pointer-kind cell at byte off of pointer-kind formal A, over every call site
// of this clone (each passes a local record of its caller).
uint64_t formalPtrUnit(LoweringContext &ctx, const Argument &A, int64_t off, const Instruction &at) {
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t unit = 0;
  for (const Specialization &C : ctx.T.specializations()) {
    if (!C.F || C.F->isDeclaration())
      continue;
    for (const Instruction &X : instructions(*C.F)) {
      auto *CB = dyn_cast<CallBase>(&X);
      const Specialization *cs = CB && CB->getCalledFunction() == ctx.S.F ? ctx.T.calleeSpecialization(*CB, C) : nullptr;
      if (!cs || !sameSpec(*cs, ctx.S))
        continue;
      if (A.getArgNo() >= CB->arg_size())
        internalError("mem-slots: a call of a clone with fewer operands than its formals", CB);
      Addr a = decompose(CB->getArgOperand(A.getArgNo()), DL);
      if (!a.ok || !a.terms.empty() || !isa<AllocaInst>(a.root))
        unimplemented("mem-slots: a pointer-kind slot cell handed to a clone other than as a local record of its "
                      "caller (its cell unit, rule 21)",
                      CB);
      uint64_t u = storedPtrUnit(ctx, *C.F, a.root, a.off + off, *CB);
      if (unit && u != unit)
        unimplemented("mem-slots: a clone handed pointer-kind cells of two cell units by its callers (rule 21)", &at);
      unit = u;
    }
  }
  if (!unit)
    unimplemented("mem-slots: a clone with a pointer-kind formal and no call site (its cell unit)", &at);
  return unit;
}

// The (tag, idx) handles the caller's pointer-kind cell s holds at I.
std::pair<Operand, Operand> readPtrCell(LoweringContext &ctx, FnState &st, const Site &s, const Instruction &I) {
  Type *pty = s.info->fields[unsigned(fieldAt(*s.info, s.a.off))].ty;
  const Instruction *src = sourceOf(ctx, st, *s.info, s.o, &I, s.a, pty);
  if (!src)
    unimplemented("mem-slots: a read of a pointer-kind slot cell that no dominating store or clone call of this "
                  "function wrote (a run-time read of a fat pointer's handles: rule 21)",
                  &I);
  if (auto c = st.callOut.find(src); c != st.callOut.end()) {
    auto t = c->second.find(s.a.off), i = c->second.find(s.a.off + 4);
    if (t == c->second.end() || i == c->second.end())
      internalError("mem-slots: a clone call's pointer-kind cell without both handles", &I);
    return {t->second, i->second};
  }
  auto t = st.lowered.find(src), i = st.loweredIdx.find(src);
  if (t == st.lowered.end() || i == st.loweredIdx.end())
    internalError("mem-slots: the access a pointer-kind cell read forwards from has not been lowered", &I);
  return {t->second, i->second};
}

// The clone writes only the idx half of the pointer-kind cell at byte off of formal argNo: each of its stores
// there is inttoptr at the store of an integer derived from its own load of that cell (the tag stays).
const LoadInst *cellLoadOrigin(const Value *v, const Value *root, int64_t off, const DataLayout &DL);

void checkCloneKeepsTag(LoweringContext &ctx, const Specialization &S, unsigned argNo, int64_t off,
                        const Instruction &at) {
  const DataLayout &DL = ctx.M.getDataLayout();
  const Argument *A = S.F->getArg(argNo);
  for (const Instruction &X : instructions(*S.F)) {
    if (auto *CB = dyn_cast<CallBase>(&X)) {
      for (const Use &u : CB->args())
        if (getUnderlyingObject(u.get()) == A && !isa<IntrinsicInst>(CB))
          unimplemented("mem-slots: a clone handing a caller's pointer-kind cell on to a call (rules 18, 21)", &at);
      continue;
    }
    auto *St = dyn_cast<StoreInst>(&X);
    if (!St)
      continue;
    Addr a = decompose(St->getPointerOperand(), DL);
    if (!a.ok || a.root != A)
      continue;
    if (!a.terms.empty() || a.off != off || !St->getValueOperand()->getType()->isIntegerTy(64) ||
        !cellLoadOrigin(St->getValueOperand(), A, off, DL))
      unimplemented("mem-slots: a clone writing a caller's pointer-kind cell other than by an integer derived from "
                    "its own load of the cell (the tag it stores is unknown: rule 21)",
                    St);
  }
}

// The i64 load of cell (root, off) the integer v derives from through add / sub of classical constants, else
// nullptr.
const LoadInst *cellLoadOrigin(const Value *v, const Value *root, int64_t off, const DataLayout &DL) {
  for (unsigned d = 0; d < 64; ++d) {
    if (auto *L = dyn_cast<LoadInst>(v)) {
      Addr a = decompose(L->getPointerOperand(), DL);
      return a.ok && a.root == root && a.terms.empty() && a.off == off && L->getType()->isIntegerTy(64) ? L : nullptr;
    }
    auto *BO = dyn_cast<BinaryOperator>(v);
    if (!BO || !isa<ConstantInt>(BO->getOperand(1)))
      return nullptr;
    // Not a disjoint or: its disjointness is a fact about base[T] + offset, not about the offset alone.
    bool ok = BO->getOpcode() == Instruction::Add || BO->getOpcode() == Instruction::Sub;
    if (!ok)
      return nullptr;
    v = BO->getOperand(0);
  }
  return nullptr;
}

// Every value derived from the clone's i64 load L of a pointer-kind cell is only offset arithmetic (add, sub of a
// classical constant) ending in
// an i64 store into that cell (the integer is never observed as a number, so base[T] is never needed).
void checkOffsetOnly(const LoadInst &L, const Value *root, int64_t off, const DataLayout &DL) {
  SmallVector<const Value *, 8> work{&L};
  SmallPtrSet<const Value *, 8> seen{&L};
  while (!work.empty()) {
    const Value *v = work.pop_back_val();
    for (const Use &u : v->uses()) {
      const User *U = u.getUser();
      if (auto *St = dyn_cast<StoreInst>(U); St && St->getValueOperand() == v) {
        Addr a = decompose(St->getPointerOperand(), DL);
        if (a.ok && a.root == root && a.terms.empty() && a.off == off)
          continue;
      }
      if (auto *BO = dyn_cast<BinaryOperator>(U); BO && BO->getOperand(0) == v && isa<ConstantInt>(BO->getOperand(1)) &&
                                                  (BO->getOpcode() == Instruction::Add ||
                                                   BO->getOpcode() == Instruction::Sub)) {
        if (seen.insert(BO).second)
          work.push_back(BO);
        continue;
      }
      unimplemented("mem-slots: a clone's integer read from a caller's pointer-kind cell observed as a number "
                    "(base[tag] is not passed: rule 21 object table)",
                    U);
    }
  }
}

Value *i64Tmpl(LoweringContext &ctx, StringRef op, Value *h, uint64_t k) {
  abi::TemplateSpec spec;
  spec.op = op.str();
  spec.w = RailType{Kind::Int, 64};
  spec.shape = "hl";
  return ctx.emitTemplate(spec, {Operand{h, true}, Operand{ConstantInt::get(Type::getInt64Ty(ctx.M.getContext()), k), false}});
}

Value *castTmpl(LoweringContext &ctx, StringRef op, unsigned from, unsigned to, Value *h) {
  abi::TemplateSpec spec;
  spec.op = op.str();
  spec.w = RailType{Kind::Int, from};
  spec.to = RailType{Kind::Int, to};
  return ctx.emitTemplate(spec, {Operand{h, true}});
}

void lowerPtrCellCloneAccess(LoweringContext &ctx, FnState &st, Instruction &I, const Argument &A, const Addr &a) {
  const DataLayout &DL = ctx.M.getDataLayout();
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  Type *i8 = Type::getInt8Ty(C), *i32 = handleTy(C);
  Value *obj = fatptr::boundSlotObject(ctx, A);
  if (!obj)
    internalError("mem-slots: a pointer-kind triple formal that fatptr did not bind", &A);
  auto half = [&](unsigned h) {
    int64_t o = a.off + 4 * int64_t(h);
    return o == 0 ? obj : B.CreateConstInBoundsGEP1_64(i8, obj, uint64_t(o));
  };
  uint64_t unit = formalPtrUnit(ctx, A, a.off, I);
  if (ctx.currentFlag() || !ctx.currentPredicate().isTop())
    unimplemented("mem-slots: a clone accessing a caller's pointer-kind cell under a quantum predicate", &I);
  if (auto *L = dyn_cast<LoadInst>(&I)) {
    if (!L->getType()->isIntegerTy(64))
      unimplemented("mem-slots: a clone loading a caller's pointer-kind cell other than as an i64 (rule 21)", L);
    checkOffsetOnly(*L, &A, a.off, DL);
    LoadInst *T = B.CreateAlignedLoad(i32, half(0), Align(4));
    LoadInst *X = B.CreateAlignedLoad(i32, half(1), Align(4));
    for (Value *h : {(Value *)T, (Value *)X}) {
      ctx.unc().recordExternal(h, Role::UserRegister);   // the caller's rails in its cell
      st.registers.insert(h);
    }
    // ptrtoint at the load: base[T] + unit * I, carried as the byte offset unit * I.
    Value *o = castTmpl(ctx, "zext", 32, 64, X);
    if (unit != 1)
      o = isPowerOf2_64(unit) ? i64Tmpl(ctx, "shl", o, Log2_64(unit)) : i64Tmpl(ctx, "mul", o, unit);
    st.lowered[L] = Operand{T, true};
    st.loweredIdx[L] = Operand{X, true};
    ctx.bindFields(L, {Operand{o, true}});
    return;
  }
  auto *St = cast<StoreInst>(&I);
  const LoadInst *L = cellLoadOrigin(St->getValueOperand(), &A, a.off, DL);
  if (!L || !St->getValueOperand()->getType()->isIntegerTy(64))
    unimplemented("mem-slots: a clone writing a caller's pointer-kind cell other than by an integer derived from "
                  "its own load of the cell (the tag it stores is unknown: rule 21)",
                  St);
  auto lt = st.lowered.find(L);
  if (lt == st.lowered.end())
    internalError("mem-slots: a pointer-kind cell's store before the load its integer derives from", St);
  for (const Instruction &X : instructions(*A.getParent()))
    if (auto *O = dyn_cast<StoreInst>(&X); O && O != St && decompose(O->getPointerOperand(), DL).root == &A)
      unimplemented("mem-slots: a clone storing into a caller's pointer-kind cells more than once (one slot result "
                    "per cell)",
                    O);
  Operand o = ctx.operand(St->getValueOperand());
  if (!o.handle)
    internalError("mem-slots: a pointer-kind cell's derived integer is classical", St);
  // inttoptr at the store keeps the provenance T: idx = (u - base[T]) / unit.
  Value *x = o.v;
  if (unit != 1)
    x = isPowerOf2_64(unit) ? i64Tmpl(ctx, "lshr", x, Log2_64(unit)) : i64Tmpl(ctx, "udiv", x, unit);
  x = castTmpl(ctx, "trunc", 64, 32, x);
  // The rule-18 copy-out (alloc 0, copy, store; calls' finalize builds the twin from it).
  RailType w{Kind::Int, 32};
  CallInst *c = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {ConstantInt::get(i32, 0)});
  RailId cid = ctx.unc().recordSeed(c);
  abi::CoreSpec cp{abi::Core::Copy, w};
  CallInst *cc = ctx.emitCore(cp, {x, c});
  ctx.unc().recordCore(cc, cp, {Operand{x, true}, Operand{c, true}}, cid);
  ctx.unc().setRole(cid, Role::Result);
  st.registers.insert(c);
  B.CreateAlignedStore(c, half(1), Align(4));
  st.lowered[St] = lt->second;
  st.loweredIdx[St] = Operand{c, true};
}

void lowerPtrCellStore(LoweringContext &ctx, FnState &st, StoreInst &stI, const Site &s) {
  const Value *v = stI.getValueOperand();
  if (!v->getType()->isPointerTy())
    unimplemented("mem-slots: an integer stored into a pointer-kind slot cell by its owner (inttoptr at the store "
                  "in the caller: rule 21)",
                  &stI);
  if (ctx.currentFlag() || !ctx.currentPredicate().isTop())
    unimplemented("mem-slots: a fat pointer stored into a pointer-kind slot cell under a quantum predicate (rules 9, "
                  "20, 21)",
                  &stI);
  if (s.info->kind != RootKind::Local || s.info->escaping || isDynamic(ctx, st, *s.info, s.o))
    unimplemented("mem-slots: a pointer-kind slot cell of a record that is not a static local", &stI);
  // The pointer's roots must be the objects themselves (fatptr's idx is relative to its root: a classical GEP
  // root inside an object would put the clone's moved idx relative to that interior point).
  {
    SmallVector<const Value *, 4> work{v};
    while (!work.empty()) {
      const Value *x = work.pop_back_val();
      if (auto *sel = dyn_cast<SelectInst>(x)) {
        work.push_back(sel->getTrueValue());
        work.push_back(sel->getFalseValue());
        continue;
      }
      if (!isa<AllocaInst>(x) && !isa<GlobalVariable>(x))
        unimplemented("mem-slots: a pointer stored into a pointer-kind slot cell that is not a select over objects' "
                      "starts (an interior root: rule 21's idx is relative to the object)",
                      &stI);
    }
  }
  uint64_t unit = storedPtrUnit(ctx, *st.F, s.a.root, s.a.off, stI);
  uint64_t cell = fatptr::storedCell(ctx, v);
  if (cell && cell != unit)
    unimplemented("mem-slots: a fat pointer stored into a pointer-kind cell whose cell size is not its objects' "
                  "element size (rule 21)",
                  &stI);
  auto [tag, idx] = fatptr::storedFields(ctx, v);
  auto seed = [&](Operand &f) {
    CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 32}}, {f.v});
    ctx.unc().recordSeed(a);
    f = Operand{a, true};
  };
  if (tag.handle) {
    auto *sel = dyn_cast<SelectInst>(v);
    if (!sel || !v->hasOneUse() || !ctx.T.isQuantum(sel->getCondition(), ctx.S))
      unimplemented("mem-slots: a fat pointer whose tag rail may have another holder stored into a pointer-kind "
                    "slot cell (cq-dr4o: only a quantum select's own tag is moved into the cell)",
                    &stI);
  } else {
    seed(tag);
  }
  if (idx.handle)
    unimplemented("mem-slots: a fat pointer with a quantum cell index stored into a pointer-kind slot cell (its idx "
                  "rail may have another holder: cq-dr4o)",
                  &stI);
  seed(idx);
  ctx.B().CreateAlignedStore(tag.v, halfPointer(ctx, s, stI, 0), Align(4));
  ctx.B().CreateAlignedStore(idx.v, halfPointer(ctx, s, stI, 1), Align(4));
  st.lowered[&stI] = tag;
  st.loweredIdx[&stI] = idx;
}

void lowerPtrCellLoad(LoweringContext &ctx, FnState &st, LoadInst &ld, const Site &s) {
  if (!ld.getType()->isPointerTy())
    unimplemented("mem-slots: an integer load of a pointer-kind slot cell by its owner (ptrtoint at the load in the "
                  "caller: rule 21)",
                  &ld);
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t unit = storedPtrUnit(ctx, *st.F, s.a.root, s.a.off, ld);
  for (const Use &u : ld.uses()) {
    Type *t = nullptr;
    if (auto *l = dyn_cast<LoadInst>(u.getUser()); l && l->getPointerOperand() == &ld)
      t = l->getType();
    else if (auto *w = dyn_cast<StoreInst>(u.getUser()); w && w->getPointerOperand() == &ld)
      t = w->getValueOperand()->getType();
    if (!t || DL.getTypeAllocSize(t).getFixedValue() != unit)
      unimplemented("mem-slots: a pointer loaded from a pointer-kind slot cell used other than by an access at its "
                    "cell unit (rule 21)",
                    u.getUser());
  }
  auto [tag, idx] = readPtrCell(ctx, st, s, ld);
  if (!tag.handle || !idx.handle)
    internalError("mem-slots: a pointer-kind cell holding a classical value", &ld);
  st.lowered[&ld] = tag;
  st.loweredIdx[&ld] = idx;
  ctx.bindFields(&ld, {tag, idx});
}

// Routes an access of a pointer-kind cell (caller or clone side); false when I is no such access.
bool lowerPtrCell(LoweringContext &ctx, FnState &st, Instruction &I) {
  const Value *ptr = accessPtr(&I);
  ArrayRef<ObjectId> objs = ctx.T.provenance(ptr, ctx.S);
  if (objs.size() != 1 || ctx.T.classOf(objs.front()) != ObjClass::Slot)
    return false;
  Addr a = decompose(ptr, ctx.M.getDataLayout());
  if (!a.ok)
    return false;
  if (auto *A = dyn_cast<Argument>(a.root)) {
    if (!isPointerKindFormal(ctx, *A))
      return false;
    lowerPtrCellCloneAccess(ctx, st, I, *A, a);
    return true;
  }
  if (columnStruct(a.root) || ctx.T.objectOf(a.root) != objs.front())
    return false;   // a field column (129) is one of several objects of its site: never a record
  ObjInfo &info = objInfo(ctx, st, a.root, objs.front());
  if (!info.record)
    return false;
  decideFields(ctx, st, info, objs.front());
  if (!a.terms.empty() || !ptrField(info, a.off))
    return false;
  Site s{objs.front(), &info, a};
  if (auto *ld = dyn_cast<LoadInst>(&I))
    lowerPtrCellLoad(ctx, st, *ld, s);
  else
    lowerPtrCellStore(ctx, st, cast<StoreInst>(I), s);
  return true;
}

} // namespace

// cq-hfah (CR rule 20 per cell, as classicalCell; orchestrator decision 2026-11-01, owner may override): a cell of
// a global slot object that taint proves never holds a handle anywhere in the program (TaintInfo::
// globalHostCell, the answer the loads' taint uses) is HOST memory: its classical stores write the C value
// there and its loads read it, so a classical reader elsewhere (an untainted function) reads the C value.
// A clone's pointer formal naming only such globals (the caller's raw pointer: the global's own layout) reads and
// writes them the same way.
bool hostGlobalCell(LoweringContext &ctx, const Site &s, const Value *ptr, Type *ty, const Instruction &I) {
  if ((s.info->kind != RootKind::Global && s.info->kind != RootKind::Param) || s.info->record)
    return false;
  if (!ctx.T.globalHostCell(ptr, 0, storeBytes(ctx.M.getDataLayout(), ty), ctx.S))
    return false;
  if (s.info->view || s.info->boolCells || s.info->colStride)
    unimplemented("mem-slots: a host cell of a global slot object with bit-view, _Bool or field-column cells "
                  "(cq-hfah)",
                  &I);
  if (s.info->kind == RootKind::Param && s.info->cellBytes != 4)
    unimplemented("mem-slots: a host cell of a global slot object reached through a pointer formal, cells other "
                  "than 4 bytes (cq-hfah)",
                  &I);
  return true;
}

void lowerSlotLoad(LoweringContext &ctx, LoadInst &ld) {
  if (calls::lowerVaAreaLoad(ctx, ld))
    return;   // CR §1.4 (95): a read of a variadic clone's save area
  FnState &st = stateOf(ctx, ld);
  if (!ld.isVolatile() && !ld.isAtomic() && lowerPtrCell(ctx, st, ld))
    return;   // cq-oocu (107): a pointer-kind cell
  if (!ctx.T.isQuantum(&ld, ctx.S)) {
    Site s = siteOf(ctx, st, ld, ld.getPointerOperand(), ld.getType());
    if (s.beyond)
      unimplemented("mem-slots: a walked access beyond its slot object other than a load (rule 21)", &ld);
    if (hostGlobalCell(ctx, s, ld.getPointerOperand(), ld.getType(), ld)) {
      LoadInst *nl = ctx.B().CreateAlignedLoad(ld.getType(), cellPointer(ctx, s, ld), ld.getAlign());
      st.lowered[&ld] = Operand{nl, false};
      ctx.bindFields(&ld, {Operand{nl, false}});
      return;
    }
    if (!s.info->record || !classicalCell(ctx, st, s))
      unimplemented("mem-slots: a classical load from a slot cell that holds a handle", &ld);
    // Rules 20, 26: a classical field of a record is ordinary memory (the clone reads and writes it there).
    if (const Instruction *src = sourceOf(ctx, st, *s.info, s.o, &ld, s.a, ld.getType()))
      if (auto it = st.lowered.find(src); it != st.lowered.end() && !it->second.handle) {
        st.lowered[&ld] = it->second;
        ctx.bindFields(&ld, {it->second});
        return;
      }
    LoadInst *nl = ctx.B().CreateAlignedLoad(ld.getType(), cellPointer(ctx, s, ld), ld.getAlign());
    st.lowered[&ld] = Operand{nl, false};
    ctx.bindFields(&ld, {Operand{nl, false}});
    return;
  }
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
  if (const Instruction *src = h.handle ? sourceOf(ctx, st, *s.info, s.o, &ld, s.a, ld.getType()) : nullptr)
    if (auto *CB = dyn_cast<CallBase>(src); CB && st.declared.count(CB)) {
      // cq-r8-d (rule 27): the declared clone's handles are of the cell's C type.
      if (ld.getType() != s.info->cellTy)
        unimplemented("mem-slots: a load of a cell a declared clone call may have written at another type than "
                      "the cell's (rule 27)",
                      &ld);
    } else if (CB && !isa<MemIntrinsic>(CB) && !st.fatOut.count(CB)) {
      // cq-qd05: the cell holds the rail the clone left there, of the clone's type (cloneCellType); a load
      // at another type of the same width reads it through a bitcast (a view, rule 3: 51's punned i64 and
      // double accesses of one cell, the caller reading the other one).
      const DataLayout &DL = ctx.M.getDataLayout();
      uint64_t size = storeBytes(DL, ld.getType());
      Type *cty = nullptr;
      if (const Specialization *S = cloneCallee(ctx, *CB))
        for (unsigned i = 0; i < numFormals(*CB) && !cty; ++i) {
          Addr pa = decompose(formalActual(*CB, i), DL);
          if (pa.ok && pa.terms.empty() && hasObject(ctx, formalActual(*CB, i), s.o) && pa.root == s.a.root &&
              !cellsWrittenBy(ctx, *S, i).empty())
            cty = cloneCellType(ctx, *S, i, s.a.off - pa.off, size, ld);
        }
      if (!cty)
        unimplemented("mem-slots: a load of a caller cell a clone call wrote whose rail type the clone's stores do "
                      "not show (cq-qd05)",
                      &ld);
      if (cty != ld.getType()) {
        if (storeBytes(DL, cty) != size || !(cty->isIntegerTy() || cty->isFloatingPointTy()) ||
            !(ld.getType()->isIntegerTy() || ld.getType()->isFloatingPointTy()) || s.info->boolCells)
          unimplemented("mem-slots: a load of a caller cell a clone call wrote at a type the clone's rail is not a "
                        "same-width scalar view of (cq-qd05)",
                        &ld);
        // The view is a fresh rail with its own role. cq-nyto (2): when the view is kept (the load measured
        // or returned: rule 2, 19), the clone's rail is kept with it and with the call's kept results (U2:
        // the twin undoes all of them or none); otherwise the clone's rail stays garbage, read by the
        // view's clean-up, and the twin uncomputes it after that (c8, c7). A mixed call (a kept result, a
        // garbage cell rail, or the reverse) is U2's unimplemented. Orchestrator decision under CR rule 5
        // and U2, owner may override.
        bool kept = false;
        for (const User *u : ld.users()) {
          if (isa<ReturnInst>(u))
            kept = true;
          if (auto *m = dyn_cast<CallBase>(u); m && m->getCalledFunction() &&
                                              m->getCalledFunction()->getName().starts_with("cq_measure_"))
            kept = true;
        }
        if (kept)
          ctx.unc().setRole(ctx.unc().idOf(h.v), Role::KeptEntangled);
        Value *v = viewTemplate(ctx, "bitcast", railTypeOf(cty), railTypeOf(ld.getType()), {h});
        st.lowered[&ld] = Operand{v, true};
        ctx.bindFields(&ld, {Operand{v, true}});
        return;
      }
    }
  if (!h.handle) {
    ctx.bindFields(&ld, {h});   // a classical cell (rule 20 per cell)
    return;
  }
  if (s.info->boolCells) {
    // A _Bool cell holds an i1 rail behind i8 memory. The trunc i8 -> i1 of the load names that rail
    // (spine, cq-sj2j: rule 3, no gate); any other use reads the i8 value, which is the rail widened
    // (cq-c9il): a zext_i1_to_i8 into a fresh rail, so every reader gets a rail of its operand's width.
    // cq-nd2i: an icmp eq/ne against another _Bool cell load or a constant 0 / 1 also reads the i1 rail (the
    // spine's cell view narrows it to an i1 compare, Views.cpp), so it needs no widened copy.
    auto boolCellLoad = [&](const Value *w) {
      auto *l2 = dyn_cast<LoadInst>(w);
      if (!l2 || !l2->getType()->isIntegerTy(8) || !boolRange(l2) || l2->isVolatile() || l2->isAtomic())
        return false;
      ArrayRef<ObjectId> objs = ctx.T.provenance(l2->getPointerOperand(), ctx.S);
      Addr a2 = decompose(l2->getPointerOperand(), ctx.M.getDataLayout());
      if (objs.size() != 1 || !a2.ok || ctx.T.classOf(objs.front()) != ObjClass::Slot)
        return false;
      return objInfo(ctx, st, a2.root, objs.front()).boolCells;
    };
    bool narrow = false, wide = false;
    for (const Use &u : ld.uses()) {
      auto *t = dyn_cast<TruncInst>(u.getUser());
      auto *c = dyn_cast<ICmpInst>(u.getUser());
      if (t && t->getDestTy()->isIntegerTy(1)) {
        narrow = true;
      } else if (c && c->isEquality()) {
        const Value *other = c->getOperand(1 - u.getOperandNo());
        auto *k = dyn_cast<ConstantInt>(other);
        if ((k && k->getZExtValue() <= 1) || boolCellLoad(other))
          narrow = true;
        else
          wide = true;
      } else {
        wide = true;
      }
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

namespace {

// ---- register updates (CR rules 6, 20; 114) ----------------------------------------------------
//
// CONTRACT. A REGISTER-UPDATE store S writes into a cell c of a slot object O the value y' = y ^ z (an xor
// of two loads, or -O1's `icmp ne` of two loads of _Bool cells stored through its zext) where y is a load L of
// exactly c in S's block before S with nothing between them that may write memory, and z a load of O at a
// provably different cell. O is a REGISTER ARRAY when it is a dynamic local or heap object (not escaping,
// no view, record or byte split, no atomic and no memory intrinsic on it) whose every store is a classical
// store (a seed, rule 7) or a register-update store, both outside any quantum predicate, or a cq_theta
// result stored back into the cell its operand was loaded from (rule 2, under a predicate too) or of a
// classical value (a fresh register), with at
// least one register update. Every rail ever in a cell of a register array is then a register (kept, never resolved by Uncompute; its loads are aliases): y'
// takes Role::UserRegister, and the rail y that S supersedes (the cell was its only holder) is cleaned by
// rule 6 right after the store, while y' and z are unchanged: t = y' ^ z, copy(t, y), uncompute t, free t,
// free y (114: "the slot's old handle (no other reference) is cleaned by rule 6 right there, while the
// control is still unchanged").
//  - Dead (rule 6): no value that may name y is read after S: every load of O (but one that, as of S, read a
//    provably different cell: it dominates S and no address value is redefined between), every value stored
//    into O and every cq_theta result of either (through casts and freeze) has no use that a path from S
//    reaches without redefining that value first; a handle merged by a phi or select is not followed
//    (unimplemented).
//  - Other readers: a garbage template whose operand is a rail of O must be undone before that rail is
//    freed. finishSlots checks it once the body is lowered: each such template's _unc lies in its forward's
//    block with no register-update clean-up between them (or it has none: kept). Any other call reading a
//    rail of O (a clone call), or a phi or select over one, is unimplemented.
//  - In a register array a register-update store whose operands are not the two loads' rails, whose y is not
//    a register or is read after S, is unimplemented: the cells never mix registers with computed rails.

const Value *stripViews(const Value *v) {
  for (unsigned g = 0; g < 16; ++g) {
    if (auto *c = dyn_cast<CastInst>(v); c && c->getSrcTy()->isIntegerTy() && c->getDestTy()->isIntegerTy()) {
      v = c->getOperand(0);
      continue;
    }
    if (auto *f = dyn_cast<FreezeInst>(v)) {
      v = f->getOperand(0);
      continue;
    }
    break;
  }
  return v;
}

bool isThetaCall(const Value *v) {
  auto *c = dyn_cast<CallInst>(v);
  return c && c->getCalledFunction() && c->getCalledFunction()->getName().starts_with("cq_theta_");
}

// S's register-update shape: L reads exactly S's cell (S's block, before S, no write between), Z another
// cell of O.
bool ruShapeOf(LoweringContext &ctx, const StoreInst &S, ObjectId o, bool boolCells, const LoadInst *&L,
               const LoadInst *&Z) {
  if (S.isVolatile() || S.isAtomic())
    return false;
  const DataLayout &DL = ctx.M.getDataLayout();
  const Value *v = S.getValueOperand();
  if (auto *z = dyn_cast<ZExtInst>(v); z && z->getSrcTy()->isIntegerTy(1))
    v = z->getOperand(0);
  const Value *a = nullptr, *b = nullptr;
  if (auto *ic = dyn_cast<ICmpInst>(v);
      ic && boolCells && ic->getPredicate() == ICmpInst::ICMP_NE && v != S.getValueOperand()) {   // 0/1 cells
    a = ic->getOperand(0);
    b = ic->getOperand(1);
  } else if (auto *bo = dyn_cast<BinaryOperator>(v); bo && bo->getOpcode() == Instruction::Xor &&
                                                      v == S.getValueOperand()) {
    a = bo->getOperand(0);
    b = bo->getOperand(1);
  } else {
    return false;
  }
  auto *la = dyn_cast<LoadInst>(a), *lb = dyn_cast<LoadInst>(b);
  if (!la || !lb || la == lb || la->isVolatile() || lb->isVolatile() || la->isAtomic() || lb->isAtomic())
    return false;
  Addr sa = decompose(S.getPointerOperand(), DL);
  uint64_t size = storeBytes(DL, S.getValueOperand()->getType());
  if (!sa.ok)
    return false;
  for (int k = 0; k < 2; ++k) {
    const LoadInst *l = k ? lb : la, *z = k ? la : lb;
    if (!hasObject(ctx, l->getPointerOperand(), o) || !hasObject(ctx, z->getPointerOperand(), o))
      continue;
    if (l->getParent() != S.getParent() || !l->comesBefore(&S) || l->getType() != S.getValueOperand()->getType())
      continue;
    if (!sameCell(decompose(l->getPointerOperand(), DL), sa) ||
        !differentCell(decompose(z->getPointerOperand(), DL), sa, storeBytes(DL, z->getType()), size))
      continue;
    bool writes = false;
    for (auto it = std::next(l->getIterator()); &*it != &S; ++it)
      writes |= it->mayWriteToMemory();
    if (writes)
      continue;
    L = l;
    Z = z;
    return true;
  }
  return false;
}

bool registerArray(LoweringContext &ctx, FnState &st, ObjInfo &info, ObjectId o) {
  if (auto it = st.ruShape.find(o); it != st.ruShape.end())
    return it->second;
  st.ruShape[o] = 0;
  if (!(info.kind == RootKind::Local || info.kind == RootKind::Heap) || info.escaping || info.view ||
      info.record || info.split || !isDynamic(ctx, st, info, o))
    return false;
  const DataLayout &DL = ctx.M.getDataLayout();
  for (const Instruction &X : instructions(*st.F))
    if (auto *MI = dyn_cast<MemIntrinsic>(&X); MI && hasObject(ctx, MI->getDest(), o))
      return false;
  bool any = false;
  for (const Access &a : accessesOf(ctx, *st.F, o)) {
    if (isRMW(a.I))
      return false;
    auto *S = dyn_cast<StoreInst>(a.I);
    if (!S)
      continue;
    if (S->isVolatile() || S->isAtomic())
      return false;
    bool top = ctx.preds().block(S->getParent()).quantumPart(ctx.T, ctx.S).isTop();
    const Value *v = S->getValueOperand();
    if (!ctx.T.isQuantum(v, ctx.S)) {
      if (!top)
        return false;   // select(p, seed, old): a computed rail
      continue;         // a seed
    }
    const LoadInst *L, *Z;
    if (ruShapeOf(ctx, *S, o, info.boolCells, L, Z)) {
      if (!top)
        return false;
      any = true;
      continue;
    }
    const Value *x = stripViews(v);
    if (isThetaCall(x)) {
      const Value *arg = stripViews(cast<CallInst>(x)->getArgOperand(0));
      if (!ctx.T.isQuantum(arg, ctx.S))
        continue;   // a cq_theta of a classical value: a fresh register (115's `q[i] = 0; cq_theta(&q[i], t)`)
      if (auto *ld = dyn_cast<LoadInst>(arg); ld && hasObject(ctx, ld->getPointerOperand(), o) &&
                                              sameCell(decompose(ld->getPointerOperand(), DL), a.a))
        continue;   // a cq_theta in place
    }
    return false;
  }
  st.ruShape[o] = any;
  return any;
}

// The load X, as of S, read a provably different cell than S writes: X dominates S, the cells differ, and no
// value of either address is redefined on a path from X to S (X's latest execution is in S's activation).
bool readOtherCell(FnState &st, const Instruction &X, const Addr &ax, uint64_t sx, const StoreInst &S,
                   const Addr &as, uint64_t ss) {
  if (!ax.ok || !as.ok || ax.root != as.root || !differentCell(ax, as, sx, ss) || !st.DT->dominates(&X, &S))
    return false;
  const BasicBlock *BX = X.getParent(), *BS = S.getParent();
  if (BX == BS)
    return X.comesBefore(&S);
  SmallPtrSet<const BasicBlock *, 16> mid = between(BX, BS);
  if (mid.count(BX) || onCycleWithin(BS, mid))
    return false;
  auto redefined = [&](const Value *v) {
    auto *d = dyn_cast<Instruction>(v);
    return d && mid.count(d->getParent());
  };
  if (redefined(ax.root) || redefined(as.root))
    return false;
  for (const Addr *a : {&ax, &as})
    for (auto &t : a->terms)
      if (redefined(t.first))
        return false;
  return true;
}

// Rule 6 Dead for the rail S supersedes: some value that may name it is read after S.
bool oldReadAfter(LoweringContext &ctx, FnState &st, const Site &s, const StoreInst &S) {
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t size = storeBytes(DL, S.getValueOperand()->getType());
  for (const Access &a : accessesOf(ctx, *st.F, s.o)) {
    const Instruction *X = nullptr;
    if (isa<LoadInst>(a.I)) {
      if (readOtherCell(st, *a.I, a.a, storeBytes(DL, a.ty), S, s.a, size))
        continue;   // names the rail of another cell (one rail per cell)
      X = a.I;
    }
    else if (auto *T = dyn_cast<StoreInst>(a.I); T && T != &S)
      X = dyn_cast<Instruction>(stripViews(T->getValueOperand()));
    if (!X || !ctx.T.isQuantum(X, ctx.S))
      continue;
    SmallVector<const Instruction *, 8> work{X}, uses;
    SmallPtrSet<const Instruction *, 8> seen{X};
    while (!work.empty()) {
      const Instruction *w = work.pop_back_val();
      for (const User *u : w->users()) {
        auto *ui = dyn_cast<Instruction>(u);
        if (!ui)
          return true;
        if (isa<PHINode>(ui) || (isa<SelectInst>(ui) && cast<SelectInst>(ui)->getCondition() != w))
          return true;   // a merged handle: not followed
        uses.push_back(ui);
        bool same = isa<CastInst>(ui) || isa<FreezeInst>(ui) ||
                    (isThetaCall(ui) && cast<CallInst>(ui)->getArgOperand(0) == w);
        if (same && seen.insert(ui).second)
          work.push_back(ui);
      }
    }
    SmallPtrSet<const Instruction *, 1> none;
    for (const Instruction *U : uses)
      if (reachesUnkilled(S, none, [&](const Instruction &I) { return &I == X; },
                          [&](const Instruction &I, bool) { return &I == U; }))
        return true;
  }
  return false;
}

struct RegUpdate { Value *old, *z; abi::TemplateSpec spec; };

// S as a register update of a register array (nullopt: not one, lowered as before).
std::optional<RegUpdate> registerUpdate(LoweringContext &ctx, FnState &st, const Site &s, const StoreInst &S,
                                        const Operand &val) {
  if (!registerArray(ctx, st, *s.info, s.o))
    return std::nullopt;
  const LoadInst *L = nullptr, *Z = nullptr;
  if (!ruShapeOf(ctx, S, s.o, s.info->boolCells, L, Z))
    return std::nullopt;
  if (ctx.currentFlag() || !ctx.currentPredicate().isTop())
    unimplemented("mem-slots: a register update of a register array under a quantum predicate or trip flag", &S);
  Operand y = ctx.operand(L), z = ctx.operand(Z);
  auto *fwd = dyn_cast<CallInst>(val.v);
  bool unc = false;
  std::optional<abi::TemplateSpec> spec;
  if (fwd && fwd->getCalledFunction())
    spec = abi::parseTemplate(fwd->getCalledFunction()->getName(), &unc);
  if (!y.handle || !z.handle || y.v == z.v || !val.handle || !spec || unc || spec->op != "xor" ||
      !spec->shape.empty() || fwd->arg_size() != 2 ||
      !((fwd->getArgOperand(0) == y.v && fwd->getArgOperand(1) == z.v) ||
        (fwd->getArgOperand(0) == z.v && fwd->getArgOperand(1) == y.v)))
    unimplemented("mem-slots: a register update of a register array whose stored rail is not the xor template "
                  "of the two cells' rails (rule 6 through the cell)",
                  &S);
  if (!st.registers.count(y.v))
    unimplemented("mem-slots: a register update of a register array whose old rail is not a register", &S);
  if (oldReadAfter(ctx, st, s, S))
    unimplemented("mem-slots: a register update of a register array whose old rail may still be read after the "
                  "store (rule 6 Dead)",
                  &S);
  return RegUpdate{y.v, z.v, *spec};
}

// Rule 6 on the superseded rail, right after the store: t = y' ^ z; copy(t, y); t's _unc; free t; free y.
void cleanSuperseded(LoweringContext &ctx, FnState &st, const Site &s, const RegUpdate &ru, Value *newRail) {
  IRBuilder<> &B = ctx.B();
  CallInst *t = B.CreateCall(abi::declare(ctx.M, ru.spec, false), {newRail, ru.z});
  ctx.emitCore(abi::CoreSpec{abi::Core::Copy, ru.spec.w}, {t, ru.old});
  B.CreateCall(abi::declare(ctx.M, ru.spec, true), {t, newRail, ru.z});
  ctx.emitCore(abi::CoreSpec{abi::Core::Free, {}}, {t});
  st.ruFrees.push_back(ctx.emitCore(abi::CoreSpec{abi::Core::Free, {}}, {ru.old}));
  Operand base = ctx.operand(s.info->root);
  st.ruBase[s.o] = base.v;
}

// cq-m3mu (CR rule 10): the rule 10 prep a stored value is, through in-place cq_theta rotations of it:
// a cq_theta of a classical value under a quantum predicate (rot-cry's register, an Ry superposition
// that exists only where its arm runs), else nullptr.
const CallInst *statePrepOf(LoweringContext &ctx, const Value *v) {
  for (unsigned depth = 0; depth < 64; ++depth) {
    auto *CI = dyn_cast<CallInst>(v);
    const Function *F = CI ? CI->getCalledFunction() : nullptr;
    if (!F || !F->getName().starts_with("cq_theta_") || CI->arg_size() != 2)
      return nullptr;
    const Value *x = CI->getArgOperand(0);
    if (ctx.T.isQuantum(x, ctx.S)) {
      v = x;   // in place on an existing rail: the prep, if any, is below it
      continue;
    }
    return ctx.preds().block(CI->getParent()).quantumPart(ctx.T, ctx.S).isTop() ? nullptr : CI;
  }
  return nullptr;
}

} // namespace

void lowerSlotStore(LoweringContext &ctx, StoreInst &stI) {
  FnState &st = stateOf(ctx, stI);
  const Value *v = stI.getValueOperand();
  if (!stI.isVolatile() && !stI.isAtomic() && lowerPtrCell(ctx, st, stI))
    return;   // cq-oocu (107): a pointer-kind cell
  {
    // 90: a classical store wider than its byte cells writes one seed per cell (little-endian bytes).
    ArrayRef<ObjectId> objs = ctx.T.provenance(stI.getPointerOperand(), ctx.S);
    Addr a = decompose(stI.getPointerOperand(), ctx.M.getDataLayout());
    if (objs.size() == 1 && a.ok && !isa<Argument>(a.root)) {
      ObjInfo &info = objInfo(ctx, st, a.root, objs.front());
      uint64_t n = storeBytes(ctx.M.getDataLayout(), v->getType());
      if (info.split && n != info.cellBytes) {
        Operand val = ctx.operand(v);
        if (val.handle || !a.terms.empty() || n % info.cellBytes)
          internalError("mem-slots: a split store that is not a classical store at a constant offset", &stI);
        if (ctx.currentFlag() || !ctx.currentPredicate().isTop())
          unimplemented("mem-slots: a classical store split per cell under a quantum predicate", &stI);
        Site s = siteOf(ctx, st, stI, stI.getPointerOperand(), info.cellTy);
        if (s.beyond)
          unimplemented("mem-slots: a walked access beyond its slot object other than a load (rule 21)", &stI);
        RailType w = cellRail(info, info.cellTy, stI);
        IRBuilder<> &B = ctx.B();
        for (uint64_t k = 0; k < n / info.cellBytes; ++k) {
          Site c = s;
          c.a.off += int64_t(k * info.cellBytes);
          Value *part = B.CreateTrunc(B.CreateLShr(val.v, ConstantInt::get(val.v->getType(), 8 * k * info.cellBytes)),
                                      info.cellTy);
          if (info.boolCells)
            part = B.CreateTrunc(part, Type::getInt1Ty(ctx.M.getContext()));   // a _Bool cell holds an i1 rail
          CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {part});
          ctx.unc().recordSeed(seed);
          finishStore(ctx, st, c, stI, info.cellTy, Operand{seed, true}, StoreWhat::Seed);
          st.callOut[&stI][c.a.off] = st.lowered[&stI];
          st.lowered.erase(&stI);
        }
        return;
      }
    }
  }
  Site s = siteOf(ctx, st, stI, stI.getPointerOperand(), v->getType());
  if (s.beyond)
    unimplemented("mem-slots: a walked access beyond its slot object other than a load (rule 21)", &stI);
  if (hostGlobalCell(ctx, s, stI.getPointerOperand(), v->getType(), stI)) {
    // cq-hfah: a host cell keeps the C value (no seed): its readers, tainted or not, read it as host memory.
    Operand hv = ctx.operand(v);
    if (hv.handle || ctx.currentFlag() || !ctx.currentPredicate().isTop())
      internalError("mem-slots: a handle, or a store under a quantum predicate, into a cell taint calls host", &stI);
    ctx.B().CreateAlignedStore(hv.v, cellPointer(ctx, s, stI), stI.getAlign());
    st.lowered[&stI] = hv;
    return;
  }
  if (s.info->view)
    return lowerViewStore(ctx, st, stI, s);
  if (s.info->record && v->getType()->isPointerTy()) {
    // cq-z6q1 (189): a heap record's pointer field is a classical cell (decideFields): the host pointer is
    // stored as written.
    Operand pv = ctx.operand(v);
    if (pv.handle || !classicalCell(ctx, st, s) || ctx.currentFlag())
      internalError("mem-slots: a record's pointer field written with other than a classical pointer", &stI);
    ctx.B().CreateAlignedStore(pv.v, cellPointer(ctx, s, stI), stI.getAlign());
    st.lowered[&stI] = pv;
    return;
  }
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
  if (val.handle && ctx.currentPredicate().isTop() && !ctx.currentFlag())
    if (const Instruction *src = sourceOf(ctx, st, *s.info, s.o, &stI, s.a, v->getType()))
      if (auto it = st.lowered.find(src);
          it != st.lowered.end() && it->second.handle && it->second.v == val.v && !needsCopy(ctx, st, stI, s)) {
        // The cell already holds the stored rail (a cq_theta in place, rule 2, of the rail a load of this
        // cell read: 58, 60, 124's step through `int *r`) and no other holder of it is read after the store
        // (else C's two objects get two rails, cq-7hpb): the rail replaces the cell with itself; nothing is
        // emitted.
        st.lowered[&stI] = val;
        return;
      }
  if (val.handle && !ctx.currentPredicate().isTop())
    if (const Instruction *src = sourceOf(ctx, st, *s.info, s.o, &stI, s.a, v->getType()))
      if (auto it = st.lowered.find(src); it != st.lowered.end() && it->second.handle && it->second.v == val.v) {
        // The cell already holds the stored rail: a cq_theta in place under the predicate (rule 10) of the
        // rail a load of this cell read, select(p, h, h) = h (59 below; 124's step through `int *r`, the
        // clone's rotation of a caller cell, T3 cellsRotated: it writes no handle there). Nothing is
        // emitted, before mergedCloneStore would take it for an arm store.
        st.lowered[&stI] = val;
        return;
      }
  if (mergedCloneStore(ctx, st, s, stI, val))
    return;
  if (Value *flag = ctx.currentFlag(); flag && !freshCell(ctx, st, s, stI)) {
    (void)flag;
    if (const LoadInst *L = nullptr, *Z = nullptr;
        registerArray(ctx, st, *s.info, s.o) && ruShapeOf(ctx, stI, s.o, s.info->boolCells, L, Z))
      unimplemented("mem-slots: a register update of a register array under a quantum predicate or trip flag",
                    &stI);
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
    // cq-m3mu: a rule 10 prep stored into the cell under its predicate. In C the cell IS the prepared
    // register (Ry superposition where the arm ran, the old value elsewhere); rule 10 builds that as
    // one rail (xorc then controlled Ry onto the register), never a select copy of the rotated rail,
    // which would copy a label of the superposition and leave the prep's rail entangled (125). The
    // cell as rule 10's register is not built.
    if (const CallInst *prep = val.handle ? statePrepOf(ctx, v) : nullptr) {
      std::string d;
      raw_string_ostream os(d);
      prep->printAsOperand(os, false);
      unimplemented("mem-slots: a rule 10 state prep (" + os.str() +
                        ") stored into a slot cell under a quantum predicate: the cell as rule 10's register "
                        "is not built (a select merge would copy the rotated rail, cq-m3mu)",
                    &stI);
    }
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
    if (!staticCell && !localGlobal && deadClassicalStore(ctx, st, *s.info, s.o, stI, s.a)) {
      freeOverwrittenSeed(ctx, st, s, stI);   // cq-2t04: the cell's old seed, before the cq_theta's own seed
      return;
    }
    if (s.info->record && classicalCell(ctx, st, s)) {
      // Rules 20, 26: a classical field of a record keeps its C value in memory (163's c, 164's b and c).
      B.CreateAlignedStore(val.v, cellPointer(ctx, s, stI), stI.getAlign());
      st.lowered[&stI] = val;
      return;
    }
    if (staticCell && classicalCell(ctx, st, s)) {
      // Rule 20 per cell (99's 'z'): a cell of a static object that no store fills with a handle is a
      // classical cell; every read of it forwards (static), so it holds the classical value and nothing
      // is emitted.
      st.lowered[&stI] = val;
      return;
    }
    Value *x = val.v;
    if (s.info->boolCells)
      x = B.CreateTrunc(x, Type::getInt1Ty(ctx.M.getContext()));
    if (x->getType() != irTypeOf(ctx.M.getContext(), w))
      internalError("mem-slots: a classical stored value of another type than its cell's rail", &stI);
    freeOverwrittenSeed(ctx, st, s, stI);
    CallInst *alloc = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {x});
    ctx.unc().recordSeed(alloc);
    val = Operand{alloc, true};
    what = What::Seed;
  } else if (needsCopy(ctx, st, stI, s)) {
    // C copies the value (cq-dr4o): the cell gets its own rail, a basis copy of the stored one (CR §0).
    if (const LoadInst *L = nullptr, *Z = nullptr;
        registerArray(ctx, st, *s.info, s.o) && ruShapeOf(ctx, stI, s.o, s.info->boolCells, L, Z))
      unimplemented("mem-slots: a register update of a register array whose new rail has another holder", &stI);
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
  } else if (std::optional<RegUpdate> ru = registerUpdate(ctx, st, s, stI, val)) {
    // A register update (CR rules 6, 20; 114): y' is the cell's register, the superseded rail is cleaned.
    ctx.unc().setRole(ctx.unc().idOf(val.v), Role::UserRegister);
    st.registers.insert(val.v);
    noteDistinctStore(ctx, st, s, stI, storeBytes(ctx.M.getDataLayout(), v->getType()), val.v);   // M3c
    finishStore(ctx, st, s, stI, v->getType(), val, What::Register);
    cleanSuperseded(ctx, st, s, *ru, val.v);
    return;
  } else {
    what = st.registers.count(val.v) || isThetaResult(ctx, v, val) ? What::Register : What::Computed;
    if (what == What::Register)
      st.registers.insert(val.v);   // a cq_theta result is a user register (rule 2)
  }

  finishStore(ctx, st, s, stI, v->getType(), val, what);
}

namespace {
bool anyWriteReaches(LoweringContext &ctx, FnState &st, const Site &s, const Instruction &I);
} // namespace

// Rule 16 (99): the cells a host effect's tape entry reads. Also calls::noteRotatedCells' T3 consumer: the
// cells a clone rotates in place.
SmallVector<Operand, 8> readSlotCells(LoweringContext &ctx, const Value *ptr, Type *cellTy, uint64_t n,
                                      Instruction &at, int64_t firstByte) {
  FnState &st = stateOf(ctx, at);
  Site s = siteOf(ctx, st, at, ptr, cellTy);
  if (s.beyond)
    unimplemented("mem-slots: a walked access beyond its slot object other than a load (rule 21)", &at);
  if (s.info->view || s.info->boolCells)
    unimplemented("mem-slots: a host effect reading a bit-view or _Bool slot object", &at);
  if (s.info->escaping)
    unimplemented("mem-slots: a host effect reading a slot object whose pointer escapes to a call", &at);
  SmallVector<Operand, 8> out;
  for (uint64_t i = 0; i < n; ++i) {
    Site c = s;
    if (s.info->record)
      unimplemented("mem-slots: a host effect reading a slot record", &at);
    c.a.off += firstByte + int64_t(i * cellStride(*s.info));
    if (!sourceOf(ctx, st, *c.info, c.o, &at, c.a, cellTy)) {
      if (isa<MemIntrinsic>(at)) {
        // 73: a memory intrinsic reading a cell that only run-time stores wrote (a loop fill) reads the handle
        // in the cell at run time, as a quantum slot load does (M3: readCell names it as a cell read).
        if (classicalCell(ctx, st, c))
          unimplemented("mem-slots: a memory intrinsic reading at run time a slot cell no handle store reaches", &at);
        cellRail(*c.info, cellTy, at);
      } else {
        // cq-peeh (CR rule 20): with no dominating source the cell's handle is read at run time (readCell: a
        // run-time read names every rail a write may have left there, M3), as a load after an in-place
        // rotating clone call is (cq-nyto). That needs the cell to hold a handle: some write of this function
        // reaches it (a never-written cell holds nothing), and it is not a classical cell of a static object
        // (whose C value stays in memory, rule 20 per cell).
        bool staticCell = (c.info->kind == RootKind::Local || c.info->kind == RootKind::Heap) &&
                          !c.info->escaping && !isDynamic(ctx, st, *c.info, c.o);
        if (!anyWriteReaches(ctx, st, c, at) || (staticCell && classicalCell(ctx, st, c)))
          unimplemented("mem-slots: a host effect reading a slot cell that no dominating access of this function "
                        "wrote (a run-time read at a host effect)",
                        &at);
      }
    }
    out.push_back(readCell(ctx, st, c, at, cellTy));
  }
  return out;
}

// T3 consumer (cq-budv, CR rules 5, 18, 20; 117): the rails the cells of the slot object ptr points to may
// hold at `at`, a clone call rotating any of its cells in place (TaintInfo::kAnyCell). Restricted to a
// DYNAMIC local or heap object: every rail in its cells is a register (a seed, a cq_theta result in place,
// an alias load's handle), each the handle some lowered access or memory intrinsic of this function left
// or read in a cell (st.lowered, st.callOut). Any other object is unimplemented (a static object's cells
// are named one by one by T3's cell list).
SmallVector<Value *, 8> slotRailsMayHold(LoweringContext &ctx, const Value *ptr, Instruction &at) {
  FnState &st = stateOf(ctx, at);
  const DataLayout &DL = ctx.M.getDataLayout();
  ArrayRef<ObjectId> objs = ctx.T.provenance(ptr, ctx.S);
  Addr a = decompose(ptr, DL);
  if (objs.size() != 1 || !a.ok)
    unimplemented("mem-slots: the rails a clone may rotate in place through a pointer into other than one slot "
                  "object (T3 any cell)",
                  &at);
  ObjectId o = objs.front();
  ObjInfo &info = objInfo(ctx, st, a.root, o);
  if ((info.kind != RootKind::Local && info.kind != RootKind::Heap) || info.record || info.view ||
      !isDynamic(ctx, st, info, o))
    unimplemented("mem-slots: a clone rotating any cell (T3, a variable offset) of a slot object that is not a "
                  "dynamic local or heap array",
                  &at);
  SmallVector<Value *, 8> out;
  auto add = [&](const Operand &h) {
    if (h.handle && h.v && !is_contained(out, h.v))
      out.push_back(h.v);
  };
  for (auto &[I, h] : st.lowered)
    if (const Value *p = accessPtr(I); p && hasObject(ctx, p, o))
      add(h);
  for (auto &[I, cells] : st.callOut) {
    const Value *p = nullptr;
    if (auto *MI = dyn_cast<MemIntrinsic>(I))
      p = MI->getRawDest();
    bool mine = p ? hasObject(ctx, p, o) : false;
    if (auto *CB = dyn_cast<CallBase>(I); CB && !p)
      for (const Use &u : CB->args())
        mine |= hasObject(ctx, u.get(), o);
    if (mine)
      for (auto &[off, h] : cells)
        add(h);
  }
  return out;
}

// M6 (CR rules 7, 20, 22): a memory intrinsic's per-cell writes (mem-qram lowers the intrinsic).
void writeSlotCells(LoweringContext &ctx, const Value *ptr, Type *cellTy, ArrayRef<Operand> vals,
                    ArrayRef<Value *> guards, Instruction &at) {
  FnState &st = stateOf(ctx, at);
  if (!isa<MemIntrinsic>(at))
    internalError("mem-slots: writeSlotCells at an instruction that is not a memory intrinsic", &at);
  if (!guards.empty() && guards.size() != vals.size())
    internalError("mem-slots: writeSlotCells with a guard list of another length than its values", &at);
  if (ctx.T.isFatPointer(ptr, ctx.S))
    unimplemented("mem-slots: writeSlotCells through a fat pointer (rule 21)", &at);
  Site s = siteOf(ctx, st, at, ptr, cellTy);
  if (s.beyond)
    unimplemented("mem-slots: a walked access beyond its slot object other than a load (rule 21)", &at);
  if (s.info->view || s.info->boolCells || s.info->record)
    unimplemented("mem-slots: a memory intrinsic writing a bit-view, _Bool or record slot object", &at);
  if (!s.a.terms.empty())
    unimplemented("mem-slots: a memory intrinsic writing slot cells at a run-time offset", &at);
  if (ctx.currentFlag())
    unimplemented("mem-slots: a memory intrinsic writing slot cells under a quantum predicate (the guards are "
                  "the caller's)",
                  &at);
  RailType w = cellRail(*s.info, cellTy, at);
  LLVMContext &C = ctx.M.getContext();
  // cq-bfz4: the objects and SSA names that may hold a source rail besides the written cell.
  SmallVector<ObjectId, 4> objs{s.o};
  if (auto *MT = dyn_cast<MemTransferInst>(&at))
    for (ObjectId x : ctx.T.provenance(MT->getSource(), ctx.S))
      if (!is_contained(objs, x))
        objs.push_back(x);
  SmallPtrSet<const Value *, 8> names;
  for (const Operand &v : vals)
    if (v.handle)
      railNames(st, v.v, names);
  for (size_t i = 0; i < vals.size(); ++i) {
    Site c = s;
    c.a.off += int64_t(i * cellStride(*s.info));
    Operand v = vals[i];
    Value *g = guards.empty() ? nullptr : guards[i];
    Operand val;
    StoreWhat what;
    if (g) {
      if (g->getType() != handleTy(C))
        internalError("mem-slots: a writeSlotCells guard that is not an i1 rail handle", &at);
      Operand old = readCell(ctx, st, c, at, cellTy);
      if (!old.handle)
        internalError("mem-slots: a guarded cell write over a classical cell", &at);
      abi::TemplateSpec sel;
      sel.op = "select";
      sel.w = w;
      sel.shape = v.handle ? "" : "lh";
      val = Operand{ctx.emitTemplate(sel, {Operand{g, true}, v, old}), true};
      what = StoreWhat::Computed;
    } else if (!v.handle) {
      if (ctx.T.globalHostCell(ptr, int64_t(i * cellStride(*s.info)), storeBytes(ctx.M.getDataLayout(), cellTy),
                               ctx.S))
        unimplemented("mem-slots: a memory intrinsic writing a classical value into a host cell of a global slot "
                      "object (rule 20 per cell, cq-hfah)",
                      &at);
      if (v.v->getType() != irTypeOf(C, w))
        internalError("mem-slots: a writeSlotCells value of another type than the cell's rail", &at);
      CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {v.v});
      ctx.unc().recordSeed(a);
      val = Operand{a, true};
      what = StoreWhat::Seed;
    } else if (!inPlaceMayFollow(ctx, st, at, objs, &names)) {
      // cq-bfz4: no in-place write on a holder may follow: the cell takes the handle itself, as a slot
      // store does (190's memmove: cells 0 and 1 both x).
      val = v;
      what = st.registers.count(v.v) ? StoreWhat::Register : StoreWhat::Computed;
    } else {
      // C copies the value (cq-dr4o): the cell gets its own rail, a basis copy (the source still holds it).
      CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(C, w))});
      RailId aid = ctx.unc().recordSeed(a);
      abi::CoreSpec cp{abi::Core::Copy, w};
      CallInst *cc = ctx.emitCore(cp, {v.v, a});
      ctx.unc().recordCore(cc, cp, {v, Operand{a, true}}, aid);
      val = Operand{a, true};
      what = StoreWhat::Copy;
    }
    finishStore(ctx, st, c, at, cellTy, val, what);
    st.callOut[&at][c.a.off] = st.lowered[&at];
    st.lowered.erase(&at);
  }
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
  if (s.beyond)
    unimplemented("mem-slots: a walked access beyond its slot object other than a load (rule 21)", &I);
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

// 102 (program slots, see programSlot): a clone call `lowered` (just emitted for orig, callee `callee`) whose
// callee accesses a program slot.
void noteProgramSlotCall(LoweringContext &ctx, const CallBase &orig, const Specialization &callee,
                         CallInst *lowered) {
  if (!callee.F || callee.F->isDeclaration())
    return;
  for (const GlobalVariable &gv : ctx.M.globals()) {
    if (!programSlot(&gv))
      continue;
    bool touches = any_of(gv.users(), [&](const User *u) {
      auto *I = dyn_cast<Instruction>(u);
      return I && I->getFunction() == callee.F;
    });
    const StoreInst *S = touches ? guardedStoreOf(*callee.F, gv) : nullptr;
    if (!touches) {
      for (const Instruction &X : instructions(*callee.F))
        if (auto *CB = dyn_cast<CallBase>(&X); CB && !isa<DbgInfoIntrinsic>(CB) && !isCqSurface(*CB) &&
                                             callMayTouchInternalGlobal(*CB, gv))
          unimplemented("mem-slots: a clone call whose callee calls code that may access a program slot (102)",
                        &orig);
      continue;
    }
    std::string pre = "mem-slots: a clone call writing a program slot (102) ";
    if (!S)
      unimplemented(pre + "other than by one store in its entry block of a constant or a formal", &orig);
    if (!callee.ctl || callee.pure || callee.adj)
      unimplemented(pre + "that is not a _ctl clone (the guarded store)", &orig);
    if (!ctx.S.isEntry() || orig.getFunction() != ctx.S.F)
      unimplemented(pre + "from a clone or an inlined callee", &orig);
    if (ctx.loopUnit() || !ctx.preds().block(orig.getParent()).classicalFactor(ctx.T, ctx.S).isTop())
      unimplemented(pre + "in a loop or under a classical branch", &orig);
    FnState &st = stateOf(ctx, orig);
    FnState::ProgSlot &p = progSlotState(st, gv);
    if (p.written)
      unimplemented(pre + "twice before a load collapses it", &orig);
    if (lowered->arg_size() != 1 + callee.F->arg_size() || !lowered->getArgOperand(0)->getType()->isIntegerTy(32))
      unimplemented(pre + "whose formals are not one argument each", &orig);
    Value *sv = const_cast<Value *>(S->getValueOperand());
    if (auto *A = dyn_cast<Argument>(sv)) {
      if (A->getArgNo() >= callee.mask.size() || callee.mask[A->getArgNo()] != '0')
        unimplemented(pre + "of a quantum formal (the stored rail would be the caller's)", &orig);
      sv = lowered->getArgOperand(1 + A->getArgNo());
    }
    if (sv->getType() != gv.getValueType())
      internalError("mem-slots: a program slot's guarded store of another type than the slot", &orig);
    ensureSlotCtor(ctx.M, gv);
    IRBuilderBase::InsertPointGuard guard(ctx.B());
    ctx.B().SetInsertPoint(lowered);
    p.old = ctx.B().CreateAlignedLoad(handleTy(ctx.M.getContext()), const_cast<GlobalVariable *>(&gv), Align(4));
    p.flag = lowered->getArgOperand(0);
    p.s = sv;
    p.written = true;
    st.progSlotCalls.insert(&orig);
    bool readLater = any_of(gv.users(), [&](const User *u) {
      auto *L = dyn_cast<LoadInst>(u);
      return L && L->getFunction() == ctx.S.F && isPotentiallyReachable(&orig, L, nullptr, st.DT.get());
    });
    if (!readLater) {
      // Nothing reads the slot after the call: the old seed is held by nothing (R stays the slot's, kept).
      if (Instruction *n = lowered->getNextNode())
        ctx.B().SetInsertPoint(n);
      else
        ctx.B().SetInsertPoint(lowered->getParent());
      ctx.emitCore(abi::CoreSpec{abi::Core::Free, {}}, {p.old});
    }
  }
}

void endSlotLifetime(LoweringContext &ctx, ObjectId, Instruction *at) {
  if (!at)
    return;
  if (auto *II = dyn_cast<IntrinsicInst>(at)) {
    if (II->getIntrinsicID() == Intrinsic::lifetime_end) {
      // The rewritten alloca carries no lifetime markers (they are hints). Rule 7 (129): the object's
      // releasable seeds still registers here are released (freed after the reads naming them), when this is
      // the object's only lifetime end and its block returns: every access of the object lies before it.
      FnState &st = stateOf(ctx, *at);
      const Value *root = getUnderlyingObject(II->getArgOperand(1));
      auto rel = st.releasable.find(root);
      if (rel == st.releasable.end())
        return;
      unsigned ends = 0;
      for (const User *u : root->users())
        if (auto *E = dyn_cast<IntrinsicInst>(u); E && E->getIntrinsicID() == Intrinsic::lifetime_end)
          ++ends;
      if (ends != 1 || !isa<ReturnInst>(at->getParent()->getTerminator()))
        return;
      for (const Instruction *X = at->getNextNode(); X; X = X->getNextNode())
        if (const Value *p = accessPtr(X); p && getUnderlyingObject(p) == root)
          return;
      for (Value *h : rel->second) {
        RailId id = ctx.unc().idOf(h);
        if (ctx.unc().liveRole(id) == Role::UserRegister)
          ctx.unc().setRole(id, Role::Seed);
      }
      st.releasable.erase(rel);
      return;
    }
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

// ---- M1: a slot object handed to a quantum clone ------------------------------------------------
//
// CONTRACT (cq-arch M1 + T2, 2026-11-01; CR rules 18, 20, §1.4). calls lowers a call of a quantum clone; for
// each argument that points into a caller's slot object it calls slotCellsBeforeCall before emitting the
// forward call and slotCellsAfterCall with the builder right after it, and passes their results to
// Uncompute::recordCall as `extra` and `slotOuts`.
//  - The cells: TaintInfo::cellsWritten(callee, argNo), cell indices counted from the pointer handed over
//    (the formal's cell 0), in the caller object's cells.
//  - Before: each cell's content as of the call: the handle (or the classical value of a classical cell)
//    a dominating access left there, a run-time load of the cell (Uncompute::recordCellLoad over the rails
//    the function's writes may have left there) when only some path wrote it, poison i32 when no write of
//    this function may reach the call.
//  - After: one `load i32` per cell, right after the call; a later load of the cell that the call reaches
//    with no write in between forwards to it (no IR), a run-time read names it (M3).
//  - Every rail that may be in a cell of the object at the call is used by the forward call (noteUse). When
//    the call has a twin (a quantum result, or a cell the clone writes), a garbage or seed rail in a cell the
//    clone may read is also read by the call's item (Uncompute::noteCallReads, U4): it outlives the twin.
//  - A slot object whose pointer goes only to such calls (not captured: `nocapture`) and to loads and
//    stores is not escaping; a call writes only the cells cellsWritten names.
//  - M1b: argNo is the callee's formal index; with argMap (a call lowered as a call of another function,
//    calls::lowerLiftedVia) the site operand of formal k is argMap[k], else k.
// Not built: a parameter or global slot object handed to a clone that writes it, a pointer at a run-time
// offset, a bit-view or _Bool object; rule 6 clean-up of an old rail the clone overwrote when the twin never
// runs (every result kept): the twin restores the old content, so the old rail is read by it and cleaned
// after it by its own role.

namespace {

struct CloneArg { const Specialization *S; Site s; SmallVector<unsigned, 4> cells; };

std::string describeValue(const Value *v) {
  std::string t;
  raw_string_ostream os(t);
  v->printAsOperand(os, false);
  return os.str();
}

// M1b: argNo is the callee's formal index; the site operand is argMap[argNo] when the call is lowered as a
// call of another function (rule 24: pthread_create(t, attr, f, p) -> f(p), argMap {3}), else argNo.
unsigned siteOperand(const CallBase &orig, unsigned argNo, ArrayRef<unsigned> argMap) {
  unsigned k = argMap.empty() ? argNo : (argNo < argMap.size() ? argMap[argNo] : ~0u);
  if (k >= orig.arg_size())
    internalError("mem-slots: slotCellsBeforeCall/After: a formal index with no site operand under argMap", &orig);
  return k;
}

const Specialization *calleeOf(LoweringContext &ctx, const CallBase &orig, ArrayRef<unsigned> argMap) {
  // A lifted call (argMap given) names a declaration (pthread_create); taint's calleeSpecialization of
  // the site is the clone the site is lowered as a call of.
  if (argMap.empty() || threadStart(orig))
    return cloneCallee(ctx, orig);
  return ctx.T.calleeSpecialization(orig, ctx.S);
}

CloneArg cloneArg(LoweringContext &ctx, FnState &st, const CallBase &orig, unsigned argNo,
                  ArrayRef<unsigned> argMap) {
  const Specialization *S = calleeOf(ctx, orig, argMap);
  if (!S)
    internalError("mem-slots: slotCellsBeforeCall/After of a call that is not a quantum clone call", &orig);
  const Value *ptr = orig.getArgOperand(siteOperand(orig, argNo, argMap));
  ArrayRef<ObjectId> objs = ctx.T.provenance(ptr, ctx.S);
  if (objs.size() != 1 || ctx.T.classOf(objs.front()) != ObjClass::Slot)
    internalError("mem-slots: slotCellsBeforeCall/After of an argument that does not point into one slot object",
                  &orig);
  Addr a = decompose(ptr, ctx.M.getDataLayout());
  if (!a.ok)
    unimplemented("mem-slots: a pointer handed to a clone whose address is not an object plus GEP offsets", &orig);
  if (!a.terms.empty())
    unimplemented("mem-slots: a pointer into a slot object at a run-time offset handed to a clone", &orig);
  ObjInfo &info = objInfo(ctx, st, a.root, objs.front());
  decideFields(ctx, st, info, objs.front());
  CloneArg r{S, Site{objs.front(), &info, a}, cellsWrittenBy(ctx, *S, argNo)};
  if (r.cells.empty())
    return r;
  if (info.view || info.boolCells)
    unimplemented("mem-slots: a bit-view or _Bool slot object handed to a clone that writes it", &orig);
  if (info.kind != RootKind::Local && info.kind != RootKind::Heap)
    unimplemented("mem-slots: a parameter or global slot object handed to a clone that writes it", &orig);
  if (info.escaping)
    unimplemented("mem-slots: a slot object whose pointer escapes handed to a clone that writes it", &orig);
  if (info.record ? a.off != 0 : a.off % int64_t(info.cellBytes))
    unimplemented("mem-slots: a pointer handed to a clone that is not at a whole cell (or not at a record's "
                  "start)",
                  &orig);
  return r;
}

Site cellSite(const CloneArg &ca, unsigned c) {
  Site s = ca.s;
  s.a.off += cellOffset(*ca.s.info, c);
  return s;
}

// Some write of this function into a cell that may be s's may reach I.
bool anyWriteReaches(LoweringContext &ctx, FnState &st, const Site &s, const Instruction &I) {
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t size = cellSizeAt(*s.info, s.a.off, DL);
  for (const Instruction &X : instructions(*st.F)) {
    if (&X == &I || !(isa<StoreInst>(X) || isRMW(&X) || isa<CallBase>(X)))
      continue;
    if (auto *II = dyn_cast<IntrinsicInst>(&X); II && II->isLifetimeStartOrEnd())
      continue;   // a lifetime marker writes no content
    if (!mayWrite(ctx, *s.info, s.o, X, s.a, size))
      continue;
    (void)DL;
    if (isPotentiallyReachable(&X, &I, nullptr, st.DT.get()))
      return true;
  }
  return false;
}

// The rails a lowered write of this function may still have left in some cell of object o at I.
SmallVector<Value *, 8> railsInObjectAt(LoweringContext &ctx, FnState &st, const Site &s, const Instruction &I) {
  const DataLayout &DL = ctx.M.getDataLayout();
  SmallVector<Value *, 8> out;
  auto add = [&](Value *h) {
    if (!is_contained(out, h))
      out.push_back(h);
  };
  for (const Access &a : accessesOf(ctx, *st.F, s.o)) {
    if (!(isa<StoreInst>(a.I) || isRMW(a.I)))
      continue;
    auto it = st.lowered.find(a.I);
    if (it == st.lowered.end() || !it->second.handle)
      continue;
    SmallPtrSet<const Instruction *, 4> defs;
    if (auto *R = dyn_cast<Instruction>(a.a.root))
      defs.insert(R);
    for (auto &t : a.a.terms)
      if (auto *T = dyn_cast<Instruction>(t.first))
        defs.insert(T);
    uint64_t sz = storeBytes(DL, a.ty);
    auto kill = [&](const Instruction &X) {
      auto *so = dyn_cast<StoreInst>(&X);
      return so && !so->isVolatile() && !so->isAtomic() && hasObject(ctx, so->getPointerOperand(), s.o) &&
             !ctx.T.isFatPointer(so->getPointerOperand(), ctx.S) &&
             storeBytes(DL, so->getValueOperand()->getType()) == sz &&
             sameCell(decompose(so->getPointerOperand(), DL), a.a);
    };
    if (reachesUnkilled(*a.I, defs, kill, [&](const Instruction &X, bool) { return &X == &I; }))
      add(it->second.v);
  }
  for (auto &[X, cells] : st.callOut)
    if (X != &I && isPotentiallyReachable(X, &I, nullptr, st.DT.get()))
      for (auto &[off, h] : cells)
        add(h.v);
  return out;
}

// The call has a twin (a quantum result, or a cell the clone mints): the twin recompute-reads what the
// clone read through its pointers.
bool callHasTwin(LoweringContext &ctx, const CallBase &orig, const Specialization &S, ArrayRef<unsigned> argMap) {
  bool twin = false;
  if (argMap.empty()) {
    if (!orig.getType()->isVoidTy())
      twin |= is_contained(ctx.T.fieldMask(&orig, ctx.S), true);
  } else if (Type *rt = S.F->getReturnType(); !rt->isVoidTy()) {
    // A lifted call's own result is not the clone's (pthread_create's 0): the clone's result record is.
    unsigned n = isa<StructType>(rt) ? cast<StructType>(rt)->getNumElements() : 1;
    for (unsigned f = 0; f < n; ++f)
      twin |= ctx.T.resultQuantum(S, f);
  }
  unsigned formals = argMap.empty() ? orig.arg_size() : argMap.size();
  for (unsigned i = 0; i < formals; ++i)
    if (orig.getArgOperand(siteOperand(orig, i, argMap))->getType()->isPointerTy() &&
        !cellsMintedBy(ctx, S, i).empty())
      twin = true;
  return twin;
}

// Every rail that may be in a cell of s's object at the call is used by the forward call (noteUse); with a
// twin, one the clone only reads is read by the call's item as well (U4: it outlives the twin, which
// recompute-reads it, 52's tx cells). A cell's old content (`old`) is already the twin's operand.
void noteObjectReadByCall(LoweringContext &ctx, FnState &st, const Site &s, const CallBase &orig, CallInst *lowered,
                          bool twin, ArrayRef<Value *> old) {
  SmallVector<RailId, 8> reads;
  for (Value *h : railsInObjectAt(ctx, st, s, orig)) {
    RailId id = ctx.unc().idOf(h);
    ctx.unc().noteUse(id, lowered);
    if (twin && !st.registers.count(h) && !is_contained(old, h) && !is_contained(reads, id))
      reads.push_back(id);
  }
  if (!reads.empty())
    ctx.unc().noteCallReads(lowered, reads);
}

} // namespace

// D1 (cq-r8-d, CR rule 27 Pointers; 190): see Memory.h.
DeclaredCells declaredCellsAtCall(LoweringContext &ctx, const CallBase &orig, unsigned argNo) {
  FnState &st = stateOf(ctx, orig);
  const Value *actual = orig.getArgOperand(argNo);
  if (!declaredArgUse(ctx, orig, orig.getArgOperandUse(argNo)))
    internalError("mem-slots: declaredCellsAtCall of an argument that is not a declared clone's pointer", &orig);
  ArrayRef<ObjectId> objs = ctx.T.provenance(actual, ctx.S);
  if (objs.size() != 1 || ctx.T.classOf(objs.front()) != ObjClass::Slot)
    unimplemented("mem-slots: a declared clone's pointer argument into other than one slot object (rule 27)", &orig);
  Addr a = decompose(actual, ctx.M.getDataLayout());
  if (!a.ok || !isa<AllocaInst>(a.root))
    unimplemented("mem-slots: a declared clone's pointer argument into a slot object that is not a local (rule 27: "
                  "a heap block, parameter or global)",
                  &orig);
  ObjInfo &info = objInfo(ctx, st, a.root, objs.front());
  if (info.kind != RootKind::Local || info.record || info.view || info.boolCells || info.split || !info.cellTy ||
      info.escaping)
    unimplemented("mem-slots: a declared clone's pointer argument into a slot record, bit view, _Bool or byte-cell "
                  "object (rule 27)",
                  &orig);
  auto *ai = cast<AllocaInst>(a.root);
  auto sz = ai->getAllocationSize(ctx.M.getDataLayout());
  if (!sz || sz->isScalable() || sz->getFixedValue() % info.cellBytes)
    unimplemented("mem-slots: a declared clone's pointer argument into a variable-size local (rule 27)", &orig);
  // A store into the object the call reaches would be undone by the twin's restore from the snapshot.
  for (const Access &x : accessesOf(ctx, *st.F, objs.front()))
    if (!isa<LoadInst>(x.I) && x.I != &orig && isPotentiallyReachable(&orig, x.I, nullptr, st.DT.get()))
      unimplemented("mem-slots: a write into a slot object after a declared clone call handed it (the twin "
                    "restores the cells from its snapshot: rule 27)",
                    x.I);
  for (const Instruction &X : instructions(*st.F))
    if (&X != &orig && declaredCallOn(ctx, X, objs.front()) &&
        (isPotentiallyReachable(&orig, &X, nullptr, st.DT.get()) ||
         isPotentiallyReachable(&X, &orig, nullptr, st.DT.get())))
      unimplemented("mem-slots: a slot object handed to two declared clone calls that may run one after the other "
                    "(rule 27: the second snapshot holds the first clone's handles)",
                    &X);
  uint64_t n = sz->getFixedValue() / info.cellBytes;
  DeclaredCells out{info.cellTy, readSlotCells(ctx, a.root, info.cellTy, n, const_cast<CallBase &>(orig))};
  return out;
}

void noteDeclaredWrites(LoweringContext &ctx, const CallBase &orig, unsigned argNo, unsigned pseudoRail,
                        ArrayRef<Operand> atCall) {
  FnState &st = stateOf(ctx, orig);
  const Value *actual = orig.getArgOperand(argNo);
  Addr a = decompose(actual, ctx.M.getDataLayout());
  ObjectId o = ctx.T.provenance(actual, ctx.S).front();
  ObjInfo &info = objInfo(ctx, st, a.root, o);
  if (st.declared.count(&orig))
    unimplemented("mem-slots: a declared clone call handed two pointers into slot objects (rule 27)", &orig);
  FnState::Declared d{pseudoRail, {}};
  for (unsigned i = 0; i < atCall.size(); ++i)
    d.atCall[int64_t(i * info.cellBytes)] = atCall[i];
  st.declared[&orig] = std::move(d);
}

SmallVector<Value *, 4> slotCellsBeforeCall(LoweringContext &ctx, const CallBase &orig, unsigned argNo,
                                            ArrayRef<unsigned> argMap) {
  FnState &st = stateOf(ctx, orig);
  CloneArg ca = cloneArg(ctx, st, orig, argNo, argMap);
  SmallVector<Value *, 4> out;
  Type *i32 = handleTy(ctx.M.getContext());
  for (unsigned c : ca.cells) {
    if (forwardedFrom(ctx, *ca.S, argNo, c) >= 0)
      continue;   // T5: no slot result, so no old content for a twin
    Site cs = cellSite(ca, c);
    if (ptrField(*cs.info, cs.a.off)) {
      // cq-oocu (107): the clone writes only the cell's idx half (the tag stays): its old idx.
      checkCloneKeepsTag(ctx, *ca.S, argNo, cellOffset(*cs.info, c), orig);
      Operand i = readPtrCell(ctx, st, cs, orig).second;
      if (!i.handle)
        internalError("mem-slots: a pointer-kind cell holding a classical idx", &orig);
      out.push_back(i.v);
      continue;
    }
    Type *ty = cs.info->record ? cs.info->fields[c].ty : cs.info->cellTy;
    if (!sourceOf(ctx, st, *cs.info, cs.o, &orig, cs.a, ty) && !anyWriteReaches(ctx, st, cs, orig)) {
      out.push_back(PoisonValue::get(i32));   // never written: the twin restores nothing defined (31, 52, 163)
      continue;
    }
    Operand v = readCell(ctx, st, cs, orig, ty);
    if (!v.handle)
      internalError("mem-slots: a cell a clone writes holds a classical value before the call", &orig);
    out.push_back(v.v);
  }
  return out;
}

SmallVector<Value *, 4> slotCellsAfterCall(LoweringContext &ctx, const CallBase &orig, unsigned argNo,
                                           CallInst *lowered, ArrayRef<unsigned> argMap) {
  FnState &st = stateOf(ctx, orig);
  CloneArg ca = cloneArg(ctx, st, orig, argNo, argMap);
  if (!lowered)
    internalError("mem-slots: slotCellsAfterCall without the lowered call", &orig);
  // The rails the clone may read through the pointer are read by the call; one it only reads must also
  // outlive a twin (see the contract above).
  bool twin = callHasTwin(ctx, orig, *ca.S, argMap);
  SmallVector<Value *, 4> old;
  for (unsigned c : ca.cells) {
    if (forwardedFrom(ctx, *ca.S, argNo, c) >= 0)
      continue;
    Site cs = cellSite(ca, c);
    if (ptrField(*cs.info, cs.a.off)) {
      old.push_back(readPtrCell(ctx, st, cs, orig).second.v);   // cq-oocu: the idx half's old handle
      continue;
    }
    Type *cty = cs.info->record ? cs.info->fields[c].ty : cs.info->cellTy;
    if (const Instruction *src = sourceOf(ctx, st, *cs.info, cs.o, &orig, cs.a, cty)) {
      if (auto it = st.lowered.find(src); it != st.lowered.end() && it->second.handle)
        old.push_back(it->second.v);
    } else {
      old.push_back(nullptr);   // a run-time content: every rail it may be is passed as the twin's operand
    }
  }
  noteObjectReadByCall(ctx, st, ca.s, orig, lowered, twin, old);
  SmallVector<Value *, 4> out;
  IRBuilder<> &B = ctx.B();
  for (unsigned c : ca.cells) {
    Site cs = cellSite(ca, c);
    if (int j = forwardedFrom(ctx, *ca.S, argNo, c); j >= 0) {
      // T5 (109): the cell now holds the caller's rail the call passed as formal j.
      const Value *act = orig.getArgOperand(siteOperand(orig, unsigned(j), argMap));
      Operand h = ctx.operand(act);
      if (!h.handle)
        internalError("mem-slots: a forwarded cell's formal passed a classical value", &orig);
      if (!act->hasOneUse())
        unimplemented("mem-slots: a rail a clone forwards into a caller cell that the caller also reads after the "
                      "call (two holders of one rail: cq-dr4o)",
                      &orig);
      st.callOut[&orig][cs.a.off] = h;
      continue;
    }
    if (ptrField(*cs.info, cs.a.off)) {
      // cq-oocu (107): the tag handle stays in the cell; the clone stored a new idx handle.
      Operand t = readPtrCell(ctx, st, cs, orig).first;
      LoadInst *h = B.CreateAlignedLoad(handleTy(ctx.M.getContext()), halfPointer(ctx, cs, orig, 1), Align(4));
      st.callOut[&orig][cs.a.off] = t;
      st.callOut[&orig][cs.a.off + 4] = Operand{h, true};
      out.push_back(h);
      continue;
    }
    LoadInst *h = B.CreateAlignedLoad(handleTy(ctx.M.getContext()), cellPointer(ctx, cs, orig), Align(4));
    st.callOut[&orig][cs.a.off] = Operand{h, true};
    out.push_back(h);
  }
  return out;
}


// cq-567j (CR rules 5, 18, 20): a pointer into caller slot objects that a quantum clone only reads. Every
// rail the objects' cells may hold at the call is used by the forward call, and read by its item when the
// call has a twin (see noteObjectReadByCall). Conservative: the whole of each slot object the pointer may
// name (taint does not narrow a read to cells).
void slotRailsReadByCall(LoweringContext &ctx, const CallBase &orig, unsigned argNo, CallInst *lowered,
                         ArrayRef<unsigned> argMap) {
  FnState &st = stateOf(ctx, orig);
  const Specialization *S = calleeOf(ctx, orig, argMap);
  if (!S)
    internalError("mem-slots: slotRailsReadByCall of a call that is not a quantum clone call", &orig);
  if (!lowered)
    internalError("mem-slots: slotRailsReadByCall without the lowered call", &orig);
  const Value *ptr = orig.getArgOperand(siteOperand(orig, argNo, argMap));
  bool twin = callHasTwin(ctx, orig, *S, argMap);
  for (ObjectId o : ctx.T.provenance(ptr, ctx.S))
    if (ctx.T.classOf(o) == ObjClass::Slot)
      noteObjectReadByCall(ctx, st, Site{o, nullptr, Addr{}}, orig, lowered, twin, {});
}

// Register updates (CR rules 5, 6, 20; 114): the readers of a register array's rails, checked once the body
// is lowered and every item placed. A rail a cell of the array held may be freed by a later register update's
// rule-6 clean-up, which Uncompute does not see, so every item that reads such a rail runs before any such
// clean-up can: a template reading one is a register itself, kept (no _unc), or undone in its own block with
// no clean-up between its forward and its _unc (a block runs whole, so no other block's clean-up can come
// between them either). A template whose result is pushed (undone by a reverse loop) or merged, a pushed rail
// of the array, and any other reader of such a rail are unimplemented.
void finishSlots(LoweringContext &ctx) {
  for (auto &[key, stp] : states()) {
    if (key.first != &ctx.out() || !stp || stp->ruFrees.empty())
      continue;
    FnState &st = *stp;
    DenseSet<const CallInst *> frees(st.ruFrees.begin(), st.ruFrees.end());
    SmallPtrSet<const Value *, 4> bases;
    for (auto &[o, b] : st.ruBase)
      bases.insert(b);
    SmallVector<Value *, 32> handles;
    for (Instruction &I : instructions(ctx.out())) {
      if (auto *ld = dyn_cast<LoadInst>(&I); ld && bases.count(getUnderlyingObject(ld->getPointerOperand())))
        handles.push_back(ld);
      if (auto *si = dyn_cast<StoreInst>(&I); si && bases.count(getUnderlyingObject(si->getPointerOperand())))
        handles.push_back(si->getValueOperand());
    }
    auto ruBetween = [&](const Instruction *a, const Instruction *b) {
      for (const Instruction *x = a->getNextNode(); x && x != b; x = x->getNextNode())
        if (auto *c = dyn_cast<CallInst>(x); c && frees.count(c))
          return true;
      return false;
    };
    SmallPtrSet<const Value *, 32> seen;
    for (Value *h : handles) {
      if (!seen.insert(h).second)
        continue;
      unsigned nFree = 0;
      for (User *u : h->users()) {
        if (isa<StoreInst>(u))
          continue;
        auto *c = dyn_cast<CallInst>(u);
        Function *cf = c ? c->getCalledFunction() : nullptr;
        if (!cf)
          unimplemented("mem-slots: a rail of a register-updated slot array read by a phi, select or indirect "
                        "call",
                        dyn_cast<Instruction>(u));
        if (frees.count(c))
          ++nFree;
        if (std::optional<abi::CoreSpec> core = abi::parseCore(cf->getName())) {
          if (core->op == abi::Core::Push)
            unimplemented("mem-slots: a rail of a register-updated slot array pushed for a reverse (read after a "
                          "register update may have freed it)",
                          c);
          continue;   // a core gate: control, rotation, measurement, the clean-up's copy and free
        }
        bool unc = false;
        if (!abi::parseTemplate(cf->getName(), &unc))
          unimplemented("mem-slots: a rail of a register-updated slot array read by a call that is not a template "
                        "or a core gate",
                        c);
        if (unc || st.registers.count(c))
          continue;   // an _unc is checked from its forward; a register is never undone
        for (User *ru : c->users()) {
          auto *uc = dyn_cast<CallInst>(ru);
          Function *uf = uc ? uc->getCalledFunction() : nullptr;
          std::optional<abi::CoreSpec> core = uf ? abi::parseCore(uf->getName()) : std::nullopt;
          if (!uf || (core && core->op == abi::Core::Push))
            unimplemented("mem-slots: a template reading a rail of a register-updated slot array whose result is "
                          "merged or pushed (undone elsewhere, after a register update may have freed that rail)",
                          c);
          bool u2 = false;
          if (!abi::parseTemplate(uf->getName(), &u2) || !u2 || uc->getArgOperand(0) != c)
            continue;
          if (uc->getParent() != c->getParent() || !c->comesBefore(uc) || ruBetween(c, uc))
            unimplemented("mem-slots: a template reading a rail of a register-updated slot array is undone outside "
                          "its own block or after a register update may have freed that rail (rule 5)",
                          c);
        }
      }
      if (nFree > 1)
        internalError("mem-slots: a register-updated slot array's rail freed twice", h);
    }
  }
}

bool isSlotRegister(LoweringContext &ctx, const Value *handle) {
  for (auto &[key, stp] : states())
    if (key.first == &ctx.out() && stp && stp->registers.count(handle))
      return true;
  return false;
}

// ---- M7: cells of local slot objects accessed through a fat pointer (cq-g1ty, CR rules 20, 21; 129) ----

namespace {
Site fatSite(LoweringContext &ctx, FnState &st, const Value *root, Type *ty, int64_t byte, const Instruction &at) {
  ArrayRef<ObjectId> objs = ctx.T.provenance(root, ctx.S);
  if (objs.size() != 1 || ctx.T.classOf(objs.front()) != ObjClass::Slot || !isa<AllocaInst>(root))
    internalError("mem-slots: a fat-pointer cell access of a root that is not one local slot object", &at);
  ObjInfo &info = objInfo(ctx, st, root, objs.front());
  if (info.record || info.view || info.boolCells || info.split || info.colStride || info.escaping)
    unimplemented("mem-slots: a fat-pointer access of a slot record, bit-view, _Bool, split, field-column or "
                  "escaping object (M7)",
                  &at);
  // Every plain load of the object forwards (static): a run-time read would name rails rule 6 cleaned.
  if (isDynamic(ctx, st, info, objs.front()))
    unimplemented("mem-slots: a fat-pointer access of a slot object with a run-time read (a dynamic object, M7)",
                  &at);
  const DataLayout &DL = ctx.M.getDataLayout();
  std::optional<TypeSize> total = cast<AllocaInst>(root)->getAllocationSize(DL);
  if (!total || total->isScalable())
    unimplemented("mem-slots: a fat-pointer access of a slot object of no static size (M7)", &at);
  if (ty != info.cellTy || byte < 0 || byte % int64_t(info.cellBytes) ||
      uint64_t(byte) + info.cellBytes > total->getFixedValue())
    unimplemented("mem-slots: a fat-pointer access that is not one whole cell of its slot object (M7)", &at);
  cellRail(info, ty, at);
  Addr a;
  a.root = root;
  a.off = byte;
  a.ok = true;
  return Site{objs.front(), &info, a};
}
} // namespace

Operand readFatCell(LoweringContext &ctx, const Value *root, Type *ty, int64_t byte, Instruction &at) {
  FnState &st = stateOf(ctx, at);
  Site s = fatSite(ctx, st, root, ty, byte, at);
  if (!sourceOf(ctx, st, *s.info, s.o, &at, s.a, ty))
    unimplemented("mem-slots: a fat-pointer read of a slot cell that no dominating access of this function wrote "
                  "(M7)",
                  &at);
  return readCell(ctx, st, s, at, ty);
}

void writeFatCell(LoweringContext &ctx, const Value *root, Type *ty, int64_t byte, Operand val, Instruction &at) {
  FnState &st = stateOf(ctx, at);
  Site s = fatSite(ctx, st, root, ty, byte, at);
  if (!val.handle)
    internalError("mem-slots: writeFatCell of a classical value", &at);
  finishStore(ctx, st, s, at, ty, val, StoreWhat::Computed);
  st.fatOut[&at][{root, byte}] = st.lowered[&at];
  st.lowered.erase(&at);
}

Value *reloadFatCell(LoweringContext &ctx, const Value *root, Type *ty, int64_t byte, const CallBase &orig,
                     CallInst *lowered) {
  FnState &st = stateOf(ctx, orig);
  Site s = fatSite(ctx, st, root, ty, byte, orig);
  Operand old = readFatCell(ctx, root, ty, byte, const_cast<CallBase &>(orig));
  if (!old.handle)
    internalError("mem-slots: a cell a clone writes holds a classical value before the call", &orig);
  // The clone reads the old rail through the pointer (U4: its twin would recompute-read it).
  ctx.unc().noteUse(ctx.unc().idOf(old.v), lowered);
  ctx.unc().noteCallReads(lowered, {ctx.unc().idOf(old.v)});
  LoadInst *h = ctx.B().CreateAlignedLoad(handleTy(ctx.M.getContext()), cellPointer(ctx, s, orig), Align(4));
  st.fatOut[&orig][{root, byte}] = Operand{h, true};
  return h;
}

// R6 (cq-bfz4, CR rule 6 'a cell chosen by a classical index'; 190's memmove_overlap). The cells' rails as
// of ld when ld is that shape (see Memory.h), each with true for a seed; nullopt otherwise.
namespace {
struct IndexedCells {
  Site s;
  SmallVector<std::pair<Value *, bool>, 8> cells;
};
std::optional<IndexedCells> indexedCells(LoweringContext &ctx, const LoadInst &ld, const Instruction &U) {
  if (ld.isVolatile() || ld.isAtomic() || !ctx.T.isQuantum(&ld, ctx.S) || ctx.T.isFatPointer(ld.getPointerOperand(), ctx.S))
    return std::nullopt;
  ArrayRef<ObjectId> objs = ctx.T.provenance(ld.getPointerOperand(), ctx.S);
  if (objs.size() != 1 || ctx.T.classOf(objs.front()) != ObjClass::Slot)
    return std::nullopt;
  if (!ld.hasOneUse() || ld.user_back() != &U || U.getParent() != ld.getParent() || !ctx.currentPredicate().isTop() ||
      ctx.currentFlag())
    return std::nullopt;
  FnState &st = stateOf(ctx, ld);
  auto lw = st.lowered.find(&ld);
  if (lw == st.lowered.end() || !lw->second.handle || lw->second.v != ctx.operand(&ld).v)
    return std::nullopt;
  Addr a0 = decompose(ld.getPointerOperand(), ctx.M.getDataLayout());
  if (!a0.ok || a0.terms.empty())
    return std::nullopt;
  Site s = siteOf(ctx, st, ld, ld.getPointerOperand(), ld.getType());
  ObjectId o = s.o;
  auto *AI = dyn_cast<AllocaInst>(s.a.root);
  if (s.beyond || !AI || s.info->kind != RootKind::Local || s.info->escaping || s.info->record || s.info->view ||
      s.info->boolCells || s.info->colStride || !isDynamic(ctx, st, *s.info, o) || !s.info->cellBytes)
    return std::nullopt;
  if (!st.LI)
    st.LI = std::make_unique<LoopInfo>(*st.DT);
  if (st.LI->getLoopFor(ld.getParent()))
    return std::nullopt;
  // Nothing reads the object but ld: its other accesses are plain stores, memory intrinsics into it read
  // only it (or classical memory), and no call is handed it.
  for (const Access &x : accessesOf(ctx, *st.F, o))
    if (x.I != &ld && !isa<StoreInst>(x.I))
      return std::nullopt;
  for (const Instruction &X : instructions(*st.F)) {
    if (auto *MT = dyn_cast<MemTransferInst>(&X)) {
      if (hasObject(ctx, MT->getSource(), o) && !hasObject(ctx, MT->getDest(), o))
        return std::nullopt;
      continue;
    }
    if (auto *CB = dyn_cast<CallBase>(&X); CB && !isa<MemIntrinsic>(CB) && !isa<DbgInfoIntrinsic>(CB) &&
                                         !(isa<IntrinsicInst>(CB) && cast<IntrinsicInst>(CB)->isLifetimeStartOrEnd()))
      for (const Use &u : CB->args())
        if (hasObject(ctx, u.get(), o))
          return std::nullopt;
  }
  std::optional<TypeSize> total = AI->getAllocationSize(ctx.M.getDataLayout());
  if (!total || total->isScalable())
    return std::nullopt;
  uint64_t cb = s.info->cellBytes, n = total->getFixedValue() / cb;
  IndexedCells out{s, {}};
  for (uint64_t c = 0; c < n; ++c) {
    Addr ac = s.a;
    ac.terms.clear();
    ac.off = int64_t(c * cb);
    const Instruction *src = sourceOf(ctx, st, *s.info, o, &ld, ac, ld.getType());
    if (!src)
      return std::nullopt;
    Operand h;
    if (auto co = st.callOut.find(src); co != st.callOut.end()) {
      auto k = co->second.find(ac.off);
      if (k == co->second.end())
        return std::nullopt;
      h = k->second;
    } else if (auto lo = st.lowered.find(src); lo != st.lowered.end() && isa<StoreInst>(src)) {
      h = lo->second;
    } else {
      return std::nullopt;
    }
    if (!h.handle)
      return std::nullopt;
    if (st.seeds.count(h.v)) {
      out.cells.push_back({h.v, true});
      continue;
    }
    // A register: a cq_theta result (rule 2) whose every IR name is only stored into this object.
    if (!st.registers.count(h.v))
      return std::nullopt;
    bool theta = false;
    for (auto &[X, op] : st.lowered) {
      if (!op.handle || op.v != h.v)
        continue;
      auto *XS = dyn_cast<StoreInst>(X);
      if (!XS)
        return std::nullopt;
      const Value *V = XS->getValueOperand();
      if (!isThetaResult(ctx, V, h))
        return std::nullopt;
      theta = true;
      for (const User *u : V->users()) {
        auto *us = dyn_cast<StoreInst>(u);
        if (!us || us->getValueOperand() != V || !hasObject(ctx, us->getPointerOperand(), o))
          return std::nullopt;
      }
    }
    if (!theta)
      return std::nullopt;
    out.cells.push_back({h.v, false});
  }
  return out;
}
} // namespace

bool indexedCellLoadDead(LoweringContext &ctx, const LoadInst &ld, const Instruction &update) {
  return indexedCells(ctx, ld, update).has_value();
}

void cleanIndexedCellLoad(LoweringContext &ctx, const LoadInst &ld, Instruction &update,
                          const abi::TemplateSpec &inverse, ArrayRef<Operand> ops) {
  std::optional<IndexedCells> ic = indexedCells(ctx, ld, update);
  if (!ic)
    internalError("mem-slots: cleanIndexedCellLoad of a load that is not a dead indexed cell load", &ld);
  // The update's result is kept by its measurement (rule 2): its record is never undone, so nothing
  // re-reads the old value after the clean-up.
  for (const User *u : update.users()) {
    auto *m = dyn_cast<CallBase>(u);
    if (!m || !m->getCalledFunction() || !m->getCalledFunction()->getName().starts_with("cq_measure_"))
      unimplemented("mem-slots: rule 6 on a slot cell chosen by a classical index whose bijective update is used "
                    "other than by a measurement (its _unc would re-read the cleaned register)",
                    &update);
  }
  bool anyRegister = false, anySeed = false;
  for (auto &[h, seed] : ic->cells)
    (seed ? anySeed : anyRegister) = true;
  if (!anyRegister)
    return;   // a seed is freed directly (rule 7)
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  Module &M = ctx.M;
  Value *h = ctx.operand(&ld).v;
  Value *idx = cellIndex(ctx, ic->s, ld);
  if (!idx)
    internalError("mem-slots: an indexed cell load with no run-time cell index", &ld);
  // Split the current block at the builder: its head (and its predecessors' edges) move to a fresh block
  // H, the clean-up runs from H on the branch, and the walk continues in the original block (which keeps
  // the program's later code and every reference to it as an edge's source).
  BasicBlock *P = B.GetInsertBlock();
  Function *F = P->getParent();
  BasicBlock::iterator ip = B.GetInsertPoint();
  BasicBlock *H = BasicBlock::Create(C, "", F, P);
  H->splice(H->end(), P, P->begin(), ip);
  for (BasicBlock *pr : SmallVector<BasicBlock *, 4>(predecessors(P)))
    if (pr != H)
      pr->getTerminator()->replaceSuccessorWith(P, H);
  BasicBlock *Cl = BasicBlock::Create(C, "", F, P);
  B.SetInsertPoint(H);
  if (anySeed) {
    // A classical branch on the index (CR rule 6, 190): the seed cells are skipped.
    Value *isSeed = nullptr;
    for (size_t c = 0; c < ic->cells.size(); ++c)
      if (ic->cells[c].second) {
        Value *e = B.CreateICmpEQ(idx, ConstantInt::get(idx->getType(), c));
        isSeed = isSeed ? B.CreateOr(isSeed, e) : e;
      }
    B.CreateCondBr(isSeed, P, Cl);
  } else {
    B.CreateBr(Cl);
  }
  B.SetInsertPoint(Cl);
  // Rule 6: t = f^-1(y', ...); copy(t, old); f^-1_unc(t, ...); free t; free old.
  SmallVector<Value *, 4> args;
  for (const Operand &o : ops)
    args.push_back(o.v);
  CallInst *t = B.CreateCall(abi::declare(M, inverse, false), args);
  RailType w = railTypeOf(ld.getType());
  ctx.emitCore(abi::CoreSpec{abi::Core::Copy, w}, {t, h});
  SmallVector<Value *, 5> uargs{t};
  uargs.append(args.begin(), args.end());
  B.CreateCall(abi::declare(M, inverse, true), uargs);
  ctx.emitCore(abi::CoreSpec{abi::Core::Free, {}}, {t});
  ctx.emitCore(abi::CoreSpec{abi::Core::Free, {}}, {h});
  B.CreateBr(P);
  B.SetInsertPoint(P, P->begin());
}

} // namespace cq::mem
