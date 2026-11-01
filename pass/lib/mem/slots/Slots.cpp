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

#include <map>
#include <optional>
#include <set>
#include <tuple>
#include <string>
#include <utility>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Loops.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ScalarEvolution.h"
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
  struct Field { int64_t off; Type *ty; int handle = -1; };   // handle: -1 not decided
  SmallVector<Field, 4> fields;
  StructType *recTy = nullptr;
  // A BYTE-CELL object (90): a local scalar object that a memory intrinsic writes and that is read at a
  // narrower width than its type: its cells are the narrowest access width (90's `unsigned char d[4]` that
  // -O1 made an alloca i32); a wider classical store is split into one write per cell (little-endian).
  bool split = false;
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
  std::unique_ptr<LoopInfo> LI;
  DenseMap<const Instruction *, Operand> lowered;   // slot load / store -> the handle the cell holds after it
  DenseSet<const Value *> registers;                // new-IR handles known never to be resolved here
  DenseSet<const Instruction *> copies;             // slot stores lowered as a basis copy (cq-dr4o)
  DenseMap<const Instruction *, ViewVal> views;     // stores into a view object -> the value they left (63)
  struct CellRead { const Instruction *I; Addr a; uint64_t size; };
  SmallVector<CellRead, 8> cellReads;               // accesses lowered as a run-time read of a local cell (M3)
  std::map<const Value *, ObjInfo> objs;
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

// The callee's formals of a clone call and the site operand each one takes (M1b: a lifted thread call's
// formal 0 is operand 3).
unsigned numFormals(const CallBase &CB) { return threadStart(CB) ? 1 : CB.arg_size(); }
const Value *formalActual(const CallBase &CB, unsigned k) { return CB.getArgOperand(threadStart(CB) ? 3 : k); }

SmallVector<unsigned, 4> cellsWrittenBy(LoweringContext &ctx, const Specialization &S, unsigned argNo) {
  if (detail::cellsWrittenOverride())
    return detail::cellsWrittenOverride()(S, argNo);
  return ctx.T.cellsWritten(S, argNo);
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
  if (!t->isIntegerTy() && !t->isFloatingPointTy())
    unimplemented("mem-slots: a slot record with a field that is not an integer or floating point (a pointer or "
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
  if (!info.record)
    return int64_t(c * info.cellBytes);
  if (c >= info.fields.size())
    internalError("mem-slots: a cell index past the record's fields");
  return info.fields[c].off;
}

ObjInfo &objInfo(LoweringContext &ctx, FnState &st, const Value *root, ObjectId o) {
  auto it = st.objs.find(root);
  if (it != st.objs.end())
    return it->second;
  const DataLayout &DL = ctx.M.getDataLayout();
  ObjInfo info;
  info.root = root;
  if (StructType *rt = recordType(root)) {
    info.kind = isa<AllocaInst>(root) ? RootKind::Local : RootKind::Param;
    info.record = true;
    flattenRecord(rt, 0, DL, info.fields, root);
    info.escaping = escapes(ctx, root);
    return st.objs.emplace(root, info).first->second;
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
      if (&X != L && (cloneWritesCell(ctx, info, o, X, cell, size) || namedWrite(ctx, X, cell, size, info)) &&
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
    f.handle = h;
  }
  SmallVector<Type *, 4> cells;
  for (const ObjInfo::Field &f : info.fields)
    cells.push_back(f.handle ? handleTy(ctx.M.getContext()) : f.ty);
  info.recTy = StructType::get(ctx.M.getContext(), cells);
}

// ---- emission -----------------------------------------------------------------------------------

struct Site { ObjectId o; ObjInfo *info; Addr a; bool beyond = false; };

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
  // A pointer formal's provenance is the caller's object (taint has no site for an argument).
  if (!isa<Argument>(a.root) && ctx.T.objectOf(a.root) != objs.front())
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
    return k == 0 ? base.v : B.CreateStructGEP(s.info->recTy, base.v, unsigned(k));
  }
  int64_t cb = int64_t(s.info->cellBytes);
  if (s.a.off % cb)
    unimplemented("mem-slots: a constant byte offset that is not a whole cell", &I);
  Type *i64 = Type::getInt64Ty(C);
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

// CR rule 20 slot store, C value semantics (cq-dr4o): the rail replaces the cell, and C copies the
// value. When the handle S stores may still be read after S through another holder (a cell other
// than S's, or an SSA value naming the rail), the two C objects would share one rail and an in-place
// gate on one (rule 2) would change the other: S then stores a basis copy (CR §0). It is a move (the
// handle itself, no gate) when no other holder can be read after S.
bool needsCopy(LoweringContext &ctx, FnState &st, const StoreInst &S, const Site &dest) {
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
                isPotentiallyReachable(&I, R.I, nullptr, st.DT.get()) && !sameClassicalLoop(ctx, st, &I, R.I))
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
      if (!ctx.S.isEntry()) {
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
  if (info.record) {
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

void lowerSlotLoad(LoweringContext &ctx, LoadInst &ld) {
  if (calls::lowerVaAreaLoad(ctx, ld))
    return;   // CR §1.4 (95): a read of a variadic clone's save area
  FnState &st = stateOf(ctx, ld);
  if (!ctx.T.isQuantum(&ld, ctx.S)) {
    Site s = siteOf(ctx, st, ld, ld.getPointerOperand(), ld.getType());
    if (s.beyond)
      unimplemented("mem-slots: a walked access beyond its slot object other than a load (rule 21)", &ld);
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
    if (auto *CB = dyn_cast<CallBase>(src); CB && !isa<MemIntrinsic>(CB)) {
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

void lowerSlotStore(LoweringContext &ctx, StoreInst &stI) {
  FnState &st = stateOf(ctx, stI);
  const Value *v = stI.getValueOperand();
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
    what = st.registers.count(val.v) || isThetaResult(ctx, v, val) ? What::Register : What::Computed;
    if (what == What::Register)
      st.registers.insert(val.v);   // a cq_theta result is a user register (rule 2)
  }

  finishStore(ctx, st, s, stI, v->getType(), val, what);
}

// Rule 16 (99): the cells a host effect's tape entry reads.
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
    c.a.off += firstByte + int64_t(i * s.info->cellBytes);
    if (!sourceOf(ctx, st, *c.info, c.o, &at, c.a, cellTy)) {
      // 73: a memory intrinsic reading a cell that only run-time stores wrote (a loop fill) reads the handle
      // in the cell at run time, as a quantum slot load does (M3: readCell names it as a cell read).
      if (!isa<MemIntrinsic>(at))
        unimplemented("mem-slots: a host effect reading a slot cell that no dominating access of this function "
                      "wrote (a run-time read at a host effect)",
                      &at);
      if (classicalCell(ctx, st, c))
        unimplemented("mem-slots: a memory intrinsic reading at run time a slot cell no handle store reaches", &at);
      cellRail(*c.info, cellTy, at);
    }
    out.push_back(readCell(ctx, st, c, at, cellTy));
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
  for (size_t i = 0; i < vals.size(); ++i) {
    Site c = s;
    c.a.off += int64_t(i * s.info->cellBytes);
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
      if (v.v->getType() != irTypeOf(C, w))
        internalError("mem-slots: a writeSlotCells value of another type than the cell's rail", &at);
      CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {v.v});
      ctx.unc().recordSeed(a);
      val = Operand{a, true};
      what = StoreWhat::Seed;
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

} // namespace

SmallVector<Value *, 4> slotCellsBeforeCall(LoweringContext &ctx, const CallBase &orig, unsigned argNo,
                                            ArrayRef<unsigned> argMap) {
  FnState &st = stateOf(ctx, orig);
  CloneArg ca = cloneArg(ctx, st, orig, argNo, argMap);
  SmallVector<Value *, 4> out;
  Type *i32 = handleTy(ctx.M.getContext());
  for (unsigned c : ca.cells) {
    Site cs = cellSite(ca, c);
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
  bool twin = false;
  if (argMap.empty()) {
    if (!orig.getType()->isVoidTy())
      twin |= is_contained(ctx.T.fieldMask(&orig, ctx.S), true);
  } else if (Type *rt = ca.S->F->getReturnType(); !rt->isVoidTy()) {
    // A lifted call's own result is not the clone's (pthread_create's 0): the clone's result record is.
    unsigned n = isa<StructType>(rt) ? cast<StructType>(rt)->getNumElements() : 1;
    for (unsigned f = 0; f < n; ++f)
      twin |= ctx.T.resultQuantum(*ca.S, f);
  }
  unsigned formals = argMap.empty() ? orig.arg_size() : argMap.size();
  for (unsigned i = 0; i < formals; ++i)
    if (orig.getArgOperand(siteOperand(orig, i, argMap))->getType()->isPointerTy() &&
        !cellsWrittenBy(ctx, *ca.S, i).empty())
      twin = true;
  SmallVector<Value *, 4> old;
  for (unsigned c : ca.cells) {
    Site cs = cellSite(ca, c);
    Type *cty = cs.info->record ? cs.info->fields[c].ty : cs.info->cellTy;
    if (const Instruction *src = sourceOf(ctx, st, *cs.info, cs.o, &orig, cs.a, cty)) {
      if (auto it = st.lowered.find(src); it != st.lowered.end() && it->second.handle)
        old.push_back(it->second.v);
    } else {
      old.push_back(nullptr);   // a run-time content: every rail it may be is passed as the twin's operand
    }
  }
  SmallVector<RailId, 8> reads;
  for (Value *h : railsInObjectAt(ctx, st, ca.s, orig)) {
    RailId id = ctx.unc().idOf(h);
    ctx.unc().noteUse(id, lowered);
    // U4: a rail the clone may read through the pointer outlives the twin, which recompute-reads it (52's
    // tx cells); a cell's old content is already the twin's operand.
    if (twin && !st.registers.count(h) && !is_contained(old, h) && !is_contained(reads, id))
      reads.push_back(id);
  }
  if (!reads.empty())
    ctx.unc().noteCallReads(lowered, reads);
  SmallVector<Value *, 4> out;
  IRBuilder<> &B = ctx.B();
  for (unsigned c : ca.cells) {
    Site cs = cellSite(ca, c);
    LoadInst *h = B.CreateAlignedLoad(handleTy(ctx.M.getContext()), cellPointer(ctx, cs, orig), Align(4));
    st.callOut[&orig][cs.a.off] = Operand{h, true};
    out.push_back(h);
  }
  return out;
}

} // namespace cq::mem
