// Module fatptr (cq-w1-fatptr): quantum pointers, CR rule 21.
//
// A pointer depending on quantum data is a fat pointer (tag, idx) over a per-function object table.
//
// CONTRACT
//
//  - Object table. Every pointer-typed argument and instruction of the original function, and every
//    pointer constant it uses, in program order (arguments first), is one ROOT numbered 1, 2, ...
//    (a deterministic function of the IR). A root is a classical pointer the new IR already holds:
//    its tag is its number, its idx the classical cell index 0, its base its own address. The tag
//    table is therefore over roots; two roots may reach the same object (a classical GEP into it),
//    which only the address form below can see, so the tag-only reduction is restricted to roots
//    that are distinct allocas.
//  - Derivation (derive). From the pointer down through its definitions:
//      * a classical pointer whose objects are all classical memory, or a constant: a root;
//      * a bitcast / addrspacecast: its operand;
//      * a GEP: base + its byte offset const + sum(scale_i * v_i) (GEPOperator::collectOffset). The
//        CELL size is the scale of the variable terms (one size per fat pointer, merged arms agree);
//        the constant and the classical terms are added to a classical idx in cells. One quantum term
//        per GEP is allowed. Alone, onto a base whose idx is the classical 0: idx is then the
//        logical index rail (the GEP index stripped of one zext/sext of a quantum value: the widening
//        and the scaling are address arithmetic, never emitted, rule 20, cq-eog3), remembered with its
//        width and extension. A sum on a rail idx (a second rail term, a classical term or a constant
//        cell offset, or a rail term onto a non-zero classical idx) is computed at sumWidth (32, or
//        the widest rail; 64 for a classical object of 2^32 cells or more or of unknown extent): each
//        rail widened by its own extension, then add templates; idx is then a rail read unsigned, or
//        signed when a root lies inside its object (&t[4]: in-bounds indices down to -4, cq-b244).
//      * a select: the spine calls lower(sel) once, at the select (patch spine-dispatch-ptrselect);
//        lower computes tag and idx there and binds them as the select's two fields. A quantum
//        condition gives tag = select_i32(cond, tag_t, tag_f) (a classical tag when both arms have
//        the same one), idx = the select of the arms' idx (the same classical value stays classical);
//        a classical condition is a classical select of classical fields. Later derivations reaching
//        the select read its fields (its shape is re-derived from the IR without emitting).
//      * an inttoptr (89, 107): bound by lowerIntToPtr as its two fields (tag, idx); its shape is the
//        provenance of the ptrtoint its integer derives from, in cells of the accesses through it.
//      * anything else quantum (a phi, a loaded pointer (189), a clone parameter (the clone-boundary
//        triple), a call result) is unimplemented.
//  - Compare (lowerCompare). eq/ne where every root of both pointers is a distinct alloca of this
//    function: tags, then indices (tag == tag' and idx == idx', a data conjunction: and_i1 / or_i1 for
//    ne). Every other compare is over addresses base[tag] + size * idx as i64 (rule 21): base[tag] is
//    the root's ptrtoint when the tag is a classical constant, else a select chain over the pointer's
//    roots on the flags tag == k, the first root innermost (the complement); the idx is widened by its
//    own extension and scaled by shl (power-of-two cell size) or mul. The result is always a rail (a
//    classical outcome becomes an i1 seed rail).
//  - ptrtoint (lowerPtrToInt) is the address base[tag] + size * idx, as a compare builds it; it keeps the
//    base[tag] it built. inttoptr (lowerIntToPtr) of an integer derived from ptrtoint(p) (taint's walk: add,
//    disjoint or, sub of a constant, zext/sext) is p's tag and idx = trunc_i32((u - base[tag]) >> log2 size),
//    size the access cell; an integer of unknown origin (range decoding) is unimplemented.
//  - Loads, stores and the clone boundary: see lowerLoad, lowerStore and passAcrossCall.
#include "cq/FatPtr.h"

#include <functional>
#include <numeric>
#include <map>
#include <set>
#include <optional>
#include <string>
#include <tuple>

#include "cq/Abi.h"
#include "cq/Memory.h"
#include "cq/Predicate.h"
#include "../mem/qram/QramInternal.h"
#include "../mem/qrom/QromInternal.h"
#include "FatPtrInternal.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/ValueTracking.h"
#include "../spine/SpineInternal.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Support/MathExtras.h"

using namespace llvm;

namespace cq::fatptr {

namespace {

bool isQ(LoweringContext &ctx, const Value *v) { return ctx.T.isQuantum(v, ctx.S); }

IntegerType *i32(LoweringContext &ctx) { return Type::getInt32Ty(ctx.M.getContext()); }
IntegerType *i64(LoweringContext &ctx) { return Type::getInt64Ty(ctx.M.getContext()); }

// The fat pointer of one original pointer value: its fields in the new IR (when emitted) and its
// shape, a pure function of the original IR.
struct Fat {
  Operand tag{nullptr, false};          // i32: a rail or a classical value
  Operand idx{nullptr, false};          // a rail of idxBits (idxSext: sign-extended), or classical i64
  unsigned idxBits = 64;
  bool idxSext = false;
  uint64_t cell = 0;                    // cell size in bytes, 0 = not fixed yet (idx is the constant 0)
  SmallVector<const Value *, 4> roots;  // in tag order
  const struct TripPtr *trips = nullptr;   // R1: the trip objects of a K-loop's exit phi (91)
  // NULL (a root, tag 0) may carry a non-zero idx: a GEP with an offset applied to a pointer that may be
  // NULL (85: false, so a compare with NULL is the tag compare alone).
  bool nullMoved = false;
  bool tagRail() const { return tag.handle; }
  bool idxRail() const { return idx.handle; }
};

// ---- object table ----------------------------------------------------------------------------

unsigned rootNumber(LoweringContext &ctx, const Value *root) {
  // NULL is tag 0 in every function's table (85): a clone's result crosses into its caller's table, where
  // the clone's NULL must still be NULL; its base is the address 0.
  if (isa<ConstantPointerNull>(root))
    return 0;
  const Function *F = ctx.S.F;
  unsigned n = 0;
  SmallPtrSet<const Value *, 32> seen;
  auto visit = [&](const Value *v) -> bool {
    if (!v->getType()->isPointerTy() || !seen.insert(v).second)
      return false;
    ++n;
    return v == root;
  };
  for (const Argument &a : F->args())
    if (visit(&a))
      return n;
  for (const BasicBlock &bb : *F)
    for (const Instruction &I : bb) {
      for (const Use &u : I.operands())
        if (isa<Constant>(u.get()) && !isa<BasicBlock>(u.get()) && visit(u.get()))
          return n;
      if (visit(&I))
        return n;
    }
  internalError("fatptr: a root pointer that is not in its function's object table", root);
}

bool classicalMemoryOnly(LoweringContext &ctx, const Value *p) {
  if (ctx.T.isFatPointer(p, ctx.S))
    return false;
  for (ObjectId o : ctx.T.provenance(p, ctx.S))
    if (ctx.T.classOf(o) != ObjClass::Classical)
      return false;
  return true;
}

// A root is a classical pointer into classical memory, or the site itself of a QRAM object (its
// classical base, rule 21; a classical GEP into a QRAM is derived onto that root's idx).
// M7 (cq-g1ty, CR rules 20, 21; 129): the address of a whole local slot object (an alloca whose one object
// is a slot array) is a root; the fat pointers over such roots this module lowers are select trees of them
// (slotSelectRoots).
bool isSlotRoot(LoweringContext &ctx, const Value *p) {
  auto *ai = dyn_cast<AllocaInst>(p);
  if (!ai || isQ(ctx, p) || ctx.T.isFatPointer(p, ctx.S))
    return false;
  ArrayRef<ObjectId> objs = ctx.T.provenance(p, ctx.S);
  return objs.size() == 1 && ctx.T.classOf(objs.front()) == ObjClass::Slot;
}

// The roots of a select tree over whole local slot objects (each at cell 0), false for any other pointer.
bool slotSelectRoots(LoweringContext &ctx, const Value *p, SmallVectorImpl<const Value *> &out, unsigned depth = 0) {
  if (depth > 16)
    return false;
  if (auto *sel = dyn_cast<SelectInst>(p))
    return slotSelectRoots(ctx, sel->getTrueValue(), out, depth + 1) &&
           slotSelectRoots(ctx, sel->getFalseValue(), out, depth + 1);
  if (!isSlotRoot(ctx, p))
    return false;
  if (!is_contained(out, p))
    out.push_back(p);
  return true;
}

bool isRoot(LoweringContext &ctx, const Value *p) {
  if (isQ(ctx, p) || ctx.T.isFatPointer(p, ctx.S))
    return false;
  if (classicalMemoryOnly(ctx, p))
    return true;
  if (isSlotRoot(ctx, p))
    return true;
  if (isa<GEPOperator>(p) || isa<BitCastOperator>(p) || isa<AddrSpaceCastOperator>(p))
    return false;
  if (mem::hostRecord(ctx, p))
    return true;   // cq-z6q1: a heap slot record keeps its host block (its base is its host address, 189)
  return mem::isQramRoot(ctx, p);
}

// P1: a clone's triple pointer formal (rule 21, §1.4), bound at the clone's entry. Its fat pointer is
// (tag, idx) of the caller; the formal is its single root (the clone sees one object).
struct Bound {
  Value *object = nullptr;      // the caller's bus (Qram) or handle cells (Slot)
  Operand tag{nullptr, false};  // classical i32
  Operand idx{nullptr, false};  // an i32 rail, or the classical i32 parameter
  Value *idx64 = nullptr;       // a classical idx widened to i64 at the clone's entry (made on first need)
  Value *cellCount = nullptr;   // i32, TripleCount only
  ObjClass pointee = ObjClass::Classical;
  uint64_t cell = 0;            // the clone's cell size in bytes
  Type *cellTy = nullptr;
  Value *zeroSeed = nullptr;    // Slot: the |0> rail a load beyond the cell count reads (190)
  // M7 (129): a quantum tag over an OBJECT TABLE of `table` slot objects (object k at table[k - 1] has tag k);
  // bases: their handle-cell bases, loaded at the clone's entry on first need. 0: no table.
  unsigned table = 0;
  SmallVector<Value *, 4> bases;
};

std::map<const Function *, DenseMap<const Value *, Bound>> &boundFormals() {
  static std::map<const Function *, DenseMap<const Value *, Bound>> b;
  return b;
}

Bound *boundOf(LoweringContext &ctx, const Value *p) {
  if (!isa<Argument>(p))
    return nullptr;
  auto it = boundFormals().find(&ctx.out());
  if (it == boundFormals().end())
    return nullptr;
  auto jt = it->second.find(p);
  return jt == it->second.end() ? nullptr : &jt->second;
}

// R1 (cq-r7-91): a K-loop's exit phi over the trip objects of one allocation site, and null.
struct TripPtr {
  Operand tag{nullptr, true};
  SmallVector<TripObject, 4> objs;
};
struct TripState {
  DenseMap<const Value *, TripPtr> phis;
  unsigned next = 0;   // the next free trip tag (0: none reserved yet)
};
std::map<const Function *, TripState> &tripStates() {
  static std::map<const Function *, TripState> t;
  return t;
}
const TripPtr *tripOf(LoweringContext &ctx, const Value *p) {
  auto it = tripStates().find(&ctx.out());
  if (it == tripStates().end())
    return nullptr;
  auto jt = it->second.phis.find(p);
  return jt == it->second.phis.end() ? nullptr : &jt->second;
}

// R2 (cq-z6q1, CR rules 14, 21; 189): a K-loop's quantum pointer header phi, carried by the loop as its tag
// rail (the loop's binding of the phi), at the classical idx 0 of each of its roots.
std::map<const Function *, DenseSet<const Value *>> &carriedPhis() {
  static std::map<const Function *, DenseSet<const Value *>> c;
  return c;
}
bool isCarried(LoweringContext &ctx, const Value *p) {
  auto it = carriedPhis().find(&ctx.out());
  return it != carriedPhis().end() && it->second.count(p);
}

// The byte size of a root's object: an alloca's, or an allocation call's constant allocsize.
std::optional<uint64_t> objectBytes(LoweringContext &ctx, const Value *root) {
  const DataLayout &DL = ctx.M.getDataLayout();
  if (auto *ai = dyn_cast<AllocaInst>(root)) {
    std::optional<TypeSize> t = ai->getAllocationSize(DL);
    if (t && !t->isScalable())
      return t->getFixedValue();
    return std::nullopt;
  }
  if (auto *CB = dyn_cast<CallBase>(root)) {
    Attribute as = CB->getFnAttr(Attribute::AllocSize);
    if (as.isValid() && !as.getAllocSizeArgs().second)
      if (auto *n = dyn_cast<ConstantInt>(CB->getArgOperand(as.getAllocSizeArgs().first)))
        return n->getZExtValue();
  }
  return std::nullopt;
}

// A distinct allocation of this function: an alloca, or a noalias allocation call on no cycle (one object
// per execution of the function, so its tag names one object).
bool distinctAllocation(LoweringContext &ctx, const Value *r) {
  auto *I = dyn_cast<Instruction>(r);
  if (!I || I->getFunction() != ctx.S.F)
    return false;
  if (isa<AllocaInst>(I))
    return true;
  auto *CB = dyn_cast<CallBase>(I);
  if (!CB || !CB->hasRetAttr(Attribute::NoAlias) || !CB->getFnAttr(Attribute::AllocKind).isValid())
    return false;
  for (const BasicBlock *s : successors(I->getParent()))
    if (isPotentiallyReachable(s, I->getParent()))
      return false;
  return true;
}

// A null pointer that is undefined to dereference (address space 0, the function does not define null).
bool undefinedNull(LoweringContext &ctx, const Value *r) {
  auto *n = dyn_cast<ConstantPointerNull>(r);
  return n && !NullPointerIsDefined(ctx.S.F, n->getType()->getAddressSpace());
}

// A builder at the top of the clone's entry block (bindFormal runs before the walker makes it): a value
// made there dominates every use in the clone.
IRBuilder<> atEntry(LoweringContext &ctx) {
  BasicBlock &E = ctx.out().getEntryBlock();
  return IRBuilder<>(&E, E.getFirstInsertionPt());
}

Value *idx64Of(LoweringContext &ctx, Bound &b) {
  if (!b.idx64)
    b.idx64 = atEntry(ctx).CreateZExt(b.idx.v, Type::getInt64Ty(ctx.M.getContext()));
  return b.idx64;
}

void addRoots(Fat &dst, ArrayRef<const Value *> src) {
  for (const Value *r : src)
    if (llvm::find(dst.roots, r) == dst.roots.end())
      dst.roots.push_back(r);
}

// ---- emission helpers ------------------------------------------------------------------------

Value *tmpl(LoweringContext &ctx, StringRef op, RailType w, ArrayRef<Operand> ops, StringRef shape,
            StringRef pred = "", std::optional<RailType> to = std::nullopt) {
  abi::TemplateSpec spec;
  spec.op = op.str();
  spec.pred = pred.str();
  spec.w = w;
  spec.to = to;
  spec.shape = shape.str();
  return ctx.emitTemplate(spec, ops);
}

RailType intRail(unsigned bits) { return RailType{Kind::Int, bits}; }

// A classical i1 outcome as a rail: an i1 seed (rule 7).
Value *seedI1(LoweringContext &ctx, Value *v) {
  CallInst *alloc = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, intRail(1)}, {v});
  ctx.unc().recordSeed(alloc);
  return alloc;
}

// icmp <p> over two operands of width w (a handle first; never _lh: the predicate is swapped).
Operand icmp(LoweringContext &ctx, CmpInst::Predicate p, unsigned w, Operand x, Operand y) {
  if (!x.handle && !y.handle)
    return Operand{ctx.B().CreateICmp(p, x.v, y.v), false};
  std::string shape;
  if (!x.handle) {
    std::swap(x, y);
    p = CmpInst::getSwappedPredicate(p);
  }
  if (!y.handle)
    shape = "hl";
  return Operand{tmpl(ctx, "icmp", intRail(w), {x, y}, shape, CmpInst::getPredicateName(p)), true};
}

// A commutative i1 / integer binop (and, or, add) of width w, a handle first.
Operand commutative(LoweringContext &ctx, StringRef op, unsigned w, Operand x, Operand y) {
  if (!x.handle && !y.handle) {
    Instruction::BinaryOps o = op == "and" ? Instruction::And : op == "or" ? Instruction::Or : Instruction::Add;
    return Operand{ctx.B().CreateBinOp(o, x.v, y.v), false};
  }
  if (!x.handle)
    std::swap(x, y);
  return Operand{tmpl(ctx, op, intRail(w), {x, y}, y.handle ? "" : "hl"), true};
}

Operand select(LoweringContext &ctx, unsigned w, Operand c, Operand t, Operand f) {
  if (!c.handle) {
    if (t.handle || f.handle)
      internalError("fatptr: a classical select over rails");
    return Operand{ctx.B().CreateSelect(c.v, t.v, f.v), false};
  }
  std::string shape = std::string(t.handle ? "h" : "l") + (f.handle ? "h" : "l");
  return Operand{tmpl(ctx, "select", intRail(w), {c, t, f}, shape == "hh" ? "" : shape), true};
}

bool sameClassical(const Operand &a, const Operand &b) { return !a.handle && !b.handle && a.v && a.v == b.v; }

// ---- derivation ------------------------------------------------------------------------------

Fat derive(LoweringContext &ctx, const Value *p, bool emit, bool eager = false);
Fat derivePtrMask(LoweringContext &ctx, const IntrinsicInst &pm, bool emit, bool eager);

Fat deriveRoot(LoweringContext &ctx, const Value *p, bool emit) {
  Fat f;
  f.roots.push_back(p);
  f.tag = Operand{ConstantInt::get(i32(ctx), rootNumber(ctx, p)), false};
  f.idx = Operand{ConstantInt::get(i64(ctx), 0), false};
  (void)emit;
  return f;
}

// The logical index rail beneath one zext/sext of a quantum value (rule 20, cq-eog3).
const Value *stripIndexCast(LoweringContext &ctx, const Value *v, bool &sext) {
  if (auto *z = dyn_cast<ZExtInst>(v); z && isQ(ctx, z->getOperand(0))) {
    sext = false;
    return z->getOperand(0);
  }
  if (auto *s = dyn_cast<SExtInst>(v); s && isQ(ctx, s->getOperand(0))) {
    sext = true;
    return s->getOperand(0);
  }
  sext = true;   // an index narrower than the pointer is sign-extended by the GEP itself
  return v;
}

// cq-b244: the in-domain cell indices relative to a fat pointer's roots, [lo, hi] over all of them. A root
// at a constant offset inside a static object (&t[4]) reaches the cells before it at negative indices
// ((&t[4])[-1] is t[3]): lo = -(offset / cell), hi = (bytes - offset) / cell (one past the end included).
// A QRAM root, a triple formal (its idx crosses as an i32, mem::hostTriple) and NULL are at their object's
// start with fewer than 2^32 cells. nullopt: a root whose object extent or offset is not static.
struct IdxRange {
  int64_t lo = 0;
  uint64_t hi = 0;
};
std::optional<IdxRange> relRange(LoweringContext &ctx, ArrayRef<const Value *> roots, uint64_t cell) {
  if (cell == 0)
    return std::nullopt;
  const DataLayout &DL = ctx.M.getDataLayout();
  IdxRange R;
  for (const Value *r : roots) {
    if (mem::isQramRoot(ctx, r) || boundOf(ctx, r) || isa<ConstantPointerNull>(r)) {
      R.hi = std::max(R.hi, (uint64_t(1) << 32) - 1);
      continue;
    }
    APInt off(64, 0);
    const Value *obj = r->stripAndAccumulateConstantOffsets(DL, off, /*AllowNonInbounds=*/true);
    std::optional<uint64_t> bytes;
    if (auto *gv = dyn_cast<GlobalVariable>(obj))
      bytes = DL.getTypeAllocSize(gv->getValueType()).getFixedValue();
    else if (auto *ai = dyn_cast<AllocaInst>(obj))
      if (auto sz = ai->getAllocationSize(DL); sz && !sz->isScalable())
        bytes = sz->getFixedValue();
    if (!bytes || off.isNegative() || off.getZExtValue() > *bytes)
      return std::nullopt;
    uint64_t o = off.getZExtValue();
    if (o / cell > uint64_t(INT64_MAX))
      return std::nullopt;
    R.lo = std::min(R.lo, -int64_t(o / cell));
    R.hi = std::max(R.hi, (*bytes - o) / cell);
  }
  return R;
}

// A root at a constant offset of at least one cell inside its object, or one whose place in its object is
// unknown (a pointer argument, a loaded pointer): its fat pointers may carry a negative in-bounds cell
// index (cq-b244). A global, an alloca, an allocation call's result and a heap record start their objects.
bool mayPrecede(LoweringContext &ctx, ArrayRef<const Value *> roots, uint64_t cell) {
  const DataLayout &DL = ctx.M.getDataLayout();
  for (const Value *r : roots) {
    if (mem::isQramRoot(ctx, r) || boundOf(ctx, r) || isa<ConstantPointerNull>(r) || isSlotRoot(ctx, r) ||
        mem::hostRecord(ctx, r))
      continue;
    APInt off(64, 0);
    const Value *obj = r->stripAndAccumulateConstantOffsets(DL, off, /*AllowNonInbounds=*/true);
    auto *CB = dyn_cast<CallBase>(obj);
    bool allocation = CB && CB->hasRetAttr(Attribute::NoAlias) && CB->getFnAttr(Attribute::AllocKind).isValid();
    if (!isa<GlobalVariable>(obj) && !isa<AllocaInst>(obj) && !allocation)
      return true;
    if (off.isNegative() || (cell ? off.getZExtValue() >= cell : !off.isZero()))
      return true;
  }
  return false;
}

// The extension that reads every in-domain index of R exactly from its low W bits: zext when none is
// negative and all are below 2^W, sext when all lie in the signed W-bit range; nullopt otherwise.
std::optional<bool> readsAt(const IdxRange &R, unsigned W) {
  if (W >= 64)
    return R.lo < 0;
  if (R.lo >= 0 && R.hi < (uint64_t(1) << W))
    return false;
  if (R.lo >= -(int64_t(1) << (W - 1)) && R.hi < (uint64_t(1) << (W - 1)))
    return true;
  return std::nullopt;
}

// A rail idx of W bits holding a cell index relative to roots, from an i64 or W-bit computation that is
// exact in its low W bits (a ptrtoint difference, a QRAM-stored i32 field): its extension, or
// unimplemented when its in-domain indices are not all readable at W (cq-b244). Roots that all start
// their objects keep the unsigned reading (their indices are non-negative).
std::optional<bool> idxSextMaybe(LoweringContext &ctx, ArrayRef<const Value *> roots, uint64_t cell, unsigned W) {
  // No cell size: every pointer the idx comes from has the constant idx 0 (Fat::cell), read either way.
  if (cell == 0 || !mayPrecede(ctx, roots, cell) || W >= 64)
    return W >= 64 && cell && mayPrecede(ctx, roots, cell);
  std::optional<IdxRange> R = relRange(ctx, roots, cell);
  return R ? readsAt(*R, W) : std::nullopt;
}

bool idxSextAt(LoweringContext &ctx, ArrayRef<const Value *> roots, uint64_t cell, unsigned W, const Value *at) {
  std::optional<bool> sx = idxSextMaybe(ctx, roots, cell, W);
  if (!sx)
    unimplemented("awaiting owner ruling: SPEC_ISSUES rule 21 i32 idx field of a pointer whose root's place in its "
                  "object is unknown (a " +
                      std::to_string(W) +
                      "-bit cell index relative to a pointer argument or a loaded pointer, stored in a QRAM of "
                      "pointers or returned by a clone)",
                  at);
  return *sx;
}

// The width of a summed rail cell index (cq-qf4c): the C index width (at least int, 32), or the
// widest summand. LLVM sums at i64; the sum's low W bits are exact, and so is its unsigned reading at W
// whenever every in-domain cell index is below 2^W: always for a QRAM (qram_alloc takes an i32 cell
// count, BACKEND_ABI), and for a classical object whose static cell count is below 2^W. Otherwise 64.
// cq-b244: read signed instead when a root lies inside its object (relRange) and every in-domain index
// fits the signed range at W. Returns {W, sext}.
std::pair<unsigned, bool> sumWidth(LoweringContext &ctx, const Fat &f, unsigned widest) {
  unsigned W = std::max(32u, widest);
  if (W >= 64)
    return {64, false};
  std::optional<IdxRange> R = relRange(ctx, f.roots, f.cell);
  std::optional<bool> sx = R ? readsAt(*R, W) : std::nullopt;
  if (!sx)
    return {64, false};
  return {W, *sx};
}

// The rail idx r (W bits, extension sx) at width to (to >= W), by its own extension.
Operand widenRail(LoweringContext &ctx, Operand r, unsigned W, bool sx, unsigned to) {
  if (!r.handle || W >= to)
    return r;
  return Operand{tmpl(ctx, sx ? "sext" : "zext", intRail(W), {r}, "", "", intRail(to)), true};
}

// r * m at width W (r a rail): shl for a power of two, mul otherwise, then a negation for m < 0 (0 - r'). The
// product is exact in its low W bits (modular arithmetic: the final in-domain sum is read at W).
Operand scaleRail(LoweringContext &ctx, Operand r, int64_t m, unsigned W) {
  if (m == 1)
    return r;
  uint64_t a = m < 0 ? uint64_t(0) - uint64_t(m) : uint64_t(m);
  LLVMContext &C = ctx.M.getContext();
  IntegerType *ty = IntegerType::get(C, W);
  if (a != 1)
    r = isPowerOf2_64(a) ? Operand{tmpl(ctx, "shl", intRail(W), {r, Operand{ConstantInt::get(ty, Log2_64(a)), false}}, "hl"), true}
                         : Operand{tmpl(ctx, "mul", intRail(W), {r, Operand{ConstantInt::get(ty, a), false}}, "hl"), true};
  if (m < 0)
    r = Operand{tmpl(ctx, "sub", intRail(W), {Operand{ConstantInt::get(ty, 0), false}, r}, "lh"), true};
  return r;
}

// CR rules 20, 21 (a cell index of the object; strided and flattened forms, 30, 50, 191): the fat pointer's idx
// re-expressed in cells of `cell` bytes, a divisor of f.cell (idx' = idx * f.cell / cell). A classical idx is
// multiplied; a rail idx is widened to the sum width of the new cells and scaled.
void rescale(LoweringContext &ctx, Fat &f, uint64_t cell, bool emit) {
  if (f.cell == 0 || f.cell == cell) {
    f.cell = cell;
    return;
  }
  if (f.cell % cell != 0)
    internalError("fatptr: a rescale to a cell size that does not divide the pointer's");
  int64_t m = int64_t(f.cell / cell);
  unsigned oldBits = f.idxBits;
  bool oldSext = f.idxSext;
  f.cell = cell;
  if (!f.idxRail()) {
    if (emit && f.idx.v)
      if (auto *ci = dyn_cast<ConstantInt>(f.idx.v); !ci || !ci->isZero())
        f.idx = Operand{ctx.B().CreateMul(f.idx.v, ConstantInt::get(i64(ctx), m)), false};
    if (!emit)
      if (auto *ci = dyn_cast_or_null<ConstantInt>(f.idx.v))
        f.idx = Operand{ConstantInt::get(i64(ctx), ci->getSExtValue() * m), false};
    return;
  }
  auto [W, sx] = sumWidth(ctx, f, oldBits);
  f.idxBits = W;
  f.idxSext = sx;
  if (!emit)
    return;
  f.idx = scaleRail(ctx, widenRail(ctx, f.idx, oldBits, oldSext, W), m, W);
}

// Rule 21 ("byte arithmetic converts at the access by the element size"): f's idx re-expressed in cells of the
// access size `size`. A cell that is a multiple of it: rescaled (exact). A cell that divides it: the idx divided by
// size / cell (a cell dividing neither: first rescaled to their common divisor), exact in the domain when the access is aligned to its size (LLVM: an access below its stated
// alignment is undefined) and every root's base is aligned to it, so an in-domain idx is a whole number of access
// cells. Otherwise false (nothing emitted).
bool fitCells(LoweringContext &ctx, Fat &f, uint64_t size, Align align) {
  if (f.cell == 0 || f.cell == size) {
    f.cell = size;
    return true;
  }
  if (f.cell % size == 0) {
    rescale(ctx, f, size, /*emit=*/true);
    return true;
  }
  if (align.value() < size)
    return false;
  const DataLayout &DL = ctx.M.getDataLayout();
  for (const Value *r : f.roots)
    if (!isa<ConstantPointerNull>(r) && (boundOf(ctx, r) || r->getPointerAlignment(DL).value() < size))
      return false;
  if (size % f.cell != 0)
    rescale(ctx, f, std::gcd(f.cell, size), /*emit=*/true);   // cells dividing both, then whole access cells
  uint64_t k = size / f.cell;
  f.cell = size;
  if (!f.idxRail()) {
    f.idx = Operand{ctx.B().CreateExactSDiv(f.idx.v, ConstantInt::get(i64(ctx), k)), false};
    return true;
  }
  IntegerType *ty = IntegerType::get(ctx.M.getContext(), f.idxBits);
  bool p2 = isPowerOf2_64(k);
  StringRef op = p2 ? (f.idxSext ? "ashr" : "lshr") : (f.idxSext ? "sdiv" : "udiv");
  f.idx = Operand{tmpl(ctx, op, intRail(f.idxBits), {f.idx, Operand{ConstantInt::get(ty, p2 ? Log2_64(k) : k), false}},
                       "hl"),
                  true};
  return true;
}

Fat deriveGEP(LoweringContext &ctx, const GEPOperator &g, bool emit) {
  const DataLayout &DL = ctx.M.getDataLayout();
  Fat f = derive(ctx, g.getPointerOperand(), emit);
  MapVector<Value *, APInt> vars;
  APInt cst(64, 0);
  // collectOffset fails only on a scalable vector type, which no x86-64 type is (rule 25: the target's widths).
  if (!g.collectOffset(DL, 64, vars, cst))
    internalError("fatptr: a GEP over a scalable vector type on x86-64", &g);
  // A term of scale 0 adds no byte (the scales of one value cancelled): it is dropped.
  SmallVector<std::pair<Value *, int64_t>, 4> terms;
  for (auto &[v, scale] : vars)
    if (!scale.isZero())
      terms.push_back({v, scale.getSExtValue()});
  int64_t c = cst.getSExtValue();
  if (f.trips && !terms.empty())
    unimplemented("fatptr: a GEP with a variable index onto a pointer to K-loop trip objects (R1)", &g);
  // The cell size (rule 21: idx is a cell index of the object; rule 20's strided and flattened forms). The
  // pointer's own cell, else the first term's scale, else the GEP's result element; when a term's scale or the
  // constant is not a multiple of it (a 2-D index a[i][j], a field offset, a byte offset), the greatest common
  // divisor of all of them: every term is then a whole multiple of the cell, idx = sum(scale / cell * v) +
  // const / cell, exact (the pointer's earlier idx rescaled to the smaller cell).
  uint64_t cand = f.cell;
  if (!cand && !terms.empty())
    cand = uint64_t(terms.front().second < 0 ? -terms.front().second : terms.front().second);
  if (!cand && c != 0)
    cand = DL.getTypeAllocSize(g.getResultElementType()).getFixedValue();
  if (terms.empty() && c == 0 && !cand)
    return f;
  auto absu = [](int64_t x) { return x < 0 ? uint64_t(0) - uint64_t(x) : uint64_t(x); };
  uint64_t cell = cand ? cand : absu(c);
  for (auto &t : terms)
    cell = std::gcd(cell, absu(t.second));
  if (c != 0)
    cell = std::gcd(cell, absu(c));
  if (cell == 0)
    internalError("fatptr: a GEP with no cell size", &g);
  if (!terms.empty() || c != 0)
    for (const Value *r : f.roots)
      if (isa<ConstantPointerNull>(r))
        f.nullMoved = true;
  rescale(ctx, f, cell, emit);
  SmallVector<std::pair<const Value *, int64_t>, 2> qTerms;   // quantum terms, multiplier in cells
  SmallVector<std::pair<Value *, int64_t>, 2> cTerms;         // classical terms, multiplier in cells
  for (auto &[v, s] : terms) {
    int64_t m = s / int64_t(cell);
    if (isQ(ctx, v))
      qTerms.push_back({v, m});
    else
      cTerms.push_back({v, m});
  }
  int64_t cc = c / int64_t(cell);
  IRBuilder<> &B = ctx.B();
  auto classicalSum = [&](Value *acc) {
    for (auto &[v, m] : cTerms) {
      Operand o = ctx.operand(v);
      if (o.handle)
        internalError("fatptr: a classical GEP index bound to a rail", v);
      Value *x = B.CreateSExtOrTrunc(o.v, i64(ctx));
      if (m != 1)
        x = B.CreateMul(x, ConstantInt::get(i64(ctx), m));
      acc = B.CreateAdd(acc, x);
    }
    if (cc != 0)
      acc = B.CreateAdd(acc, ConstantInt::get(i64(ctx), cc));
    return acc;
  };
  if (qTerms.empty() && !f.idxRail()) {
    if (cTerms.empty() && cc == 0)
      return f;
    if (!emit) {
      // shape only: a constant when the base idx is one and no classical term is variable
      auto *b0 = dyn_cast_or_null<ConstantInt>(f.idx.v);
      f.idx = Operand{b0 && cTerms.empty() ? ConstantInt::get(i64(ctx), b0->getSExtValue() + cc) : nullptr, false};
      return f;
    }
    f.idx = Operand{classicalSum(f.idx.v), false};
    return f;
  }
  // A rail cell index (rule 21): the base's rail idx and/or the quantum terms' logical indices, plus the
  // classical part (the base's classical idx, the classical terms, the constant). A lone rail of multiplier 1
  // stays at its own width (the widening is address arithmetic, never emitted, rule 20); a sum is computed at
  // sumWidth: each rail widened by its own extension (zext, or sext for a signed index), scaled by its
  // multiplier, then added (an index past the object is undefined, outside the domain). An index wider than
  // the 64-bit address is truncated to it first, as the GEP does.
  struct QT {
    const Value *ix;
    unsigned w;
    bool sext;
    bool wide;
    int64_t m;
  };
  SmallVector<QT, 2> qs;
  unsigned widest = f.idxRail() ? f.idxBits : 0u;
  for (auto &[v, m] : qTerms) {
    bool qsext = false;
    const Value *ix = stripIndexCast(ctx, v, qsext);
    if (!ix->getType()->isIntegerTy())
      internalError("fatptr: a quantum GEP index that is not an integer", &g);
    unsigned w = ix->getType()->getIntegerBitWidth();
    bool wide = w > 64;
    if (wide)
      w = 64;
    qs.push_back({ix, w, qsext && w < 64, wide, m});
    widest = std::max(widest, w);
  }
  bool classicalPart = !cTerms.empty() || cc != 0 ||
                       (!f.idxRail() && !(isa<ConstantInt>(f.idx.v) && cast<ConstantInt>(f.idx.v)->isZero()));
  bool sum = classicalPart || qs.size() + (f.idxRail() ? 1 : 0) > 1 || any_of(qs, [](const QT &q) { return q.m != 1; });
  unsigned W = f.idxRail() ? f.idxBits : qs.front().w;
  bool sext = f.idxRail() ? f.idxSext : qs.front().sext;
  if (sum)
    std::tie(W, sext) = sumWidth(ctx, f, widest);
  if (!emit) {
    f.idxBits = W;
    f.idxSext = sext;
    f.idx = Operand{nullptr, true};
    return f;
  }
  auto widen = [&](Operand r, unsigned w, bool sx) -> Operand { return sum ? widenRail(ctx, r, w, sx, W) : r; };
  Operand rail{nullptr, true};
  if (f.idxRail())
    rail = widen(f.idx, f.idxBits, f.idxSext);
  for (const QT &q : qs) {
    Operand r = ctx.operand(q.ix);
    if (!r.handle)
      internalError("fatptr: the logical index of a quantum GEP index is not a rail", q.ix);
    if (q.wide)
      r = Operand{tmpl(ctx, "trunc", intRail(q.ix->getType()->getIntegerBitWidth()), {r}, "", "", intRail(64)), true};
    r = widen(r, q.w, q.sext);
    if (W < q.w)
      r = Operand{tmpl(ctx, "trunc", intRail(q.w), {r}, "", "", intRail(W)), true};
    r = scaleRail(ctx, r, q.m, W);
    rail = rail.v ? Operand{tmpl(ctx, "add", intRail(W), {rail, r}, ""), true} : r;
  }
  if (classicalPart) {
    Value *cs = classicalSum(f.idxRail() ? ConstantInt::get(i64(ctx), 0) : f.idx.v);
    if (W < 64)
      cs = B.CreateTrunc(cs, IntegerType::get(ctx.M.getContext(), W));
    rail = Operand{tmpl(ctx, "add", intRail(W), {rail, Operand{cs, false}}, "hl"), true};
  }
  f.idxBits = W;
  f.idxSext = sext;
  f.idx = rail;
  return f;
}

Fat deriveSelect(LoweringContext &ctx, const SelectInst &sel, bool emit, bool eager) {
  if (emit && !eager) {
    // The spine lowered the select at its position (lower): read its bound fields.
    Fat f = deriveSelect(ctx, sel, /*emit=*/false, false);
    SmallVector<Operand, 4> fl = ctx.fields(&sel);
    if (fl.size() != 2 || fl[0].handle != f.tag.handle || fl[1].handle != f.idx.handle)
      internalError("fatptr: a pointer select bound to other than its (tag, idx)", &sel);
    f.tag = fl[0];
    f.idx = fl[1];
    return f;
  }
  Fat t = derive(ctx, sel.getTrueValue(), emit);
  Fat e = derive(ctx, sel.getFalseValue(), emit);
  if (t.trips || e.trips)
    unimplemented("fatptr: a select of a pointer to K-loop trip objects (R1)", &sel);
  Fat f;
  addRoots(f, t.roots);
  addRoots(f, e.roots);
  f.nullMoved = t.nullMoved || e.nullMoved;
  llvm::sort(f.roots, [&](const Value *x, const Value *y) { return rootNumber(ctx, x) < rootNumber(ctx, y); });
  // Arms of two cell sizes merge in cells of their greatest common divisor (each arm's idx rescaled, exact).
  if (t.cell && e.cell && t.cell != e.cell) {
    uint64_t g = std::gcd(t.cell, e.cell);
    rescale(ctx, t, g, emit);
    rescale(ctx, e, g, emit);
  }
  f.cell = t.cell ? t.cell : e.cell;
  // Two rail idx of different widths or extensions merge at a width that reads both exactly: the wider one's
  // with a common extension; a zext arm read signed needs one more bit than its own.
  if (t.idxRail() && e.idxRail() && (t.idxBits != e.idxBits || t.idxSext != e.idxSext)) {
    unsigned W;
    bool sx;
    if (t.idxSext == e.idxSext) {
      W = std::max(t.idxBits, e.idxBits);
      sx = t.idxSext;
    } else {
      const Fat &z = t.idxSext ? e : t, &s2 = t.idxSext ? t : e;
      W = std::min(64u, std::max(z.idxBits + 1, s2.idxBits));
      sx = W < 64;
    }
    for (Fat *x : {&t, &e}) {
      if (emit)
        x->idx = widenRail(ctx, x->idx, x->idxBits, x->idxSext, W);
      x->idxBits = W;
      x->idxSext = sx;
    }
  }
  // One rail arm and one classical arm whose value is no constant readable at the rail's width: the rail is
  // widened to 64 bits by its extension and the classical arm taken as its i64. Decided on the arms' shapes
  // (derive without emitting), so the emitting and the shape-only derivations agree.
  if (t.idxRail() != e.idxRail()) {
    bool railT = t.idxRail();
    Fat &r = railT ? t : e;
    Fat os = derive(ctx, railT ? sel.getFalseValue() : sel.getTrueValue(), /*emit=*/false);
    auto *ci = dyn_cast_or_null<ConstantInt>(os.idx.v);
    bool fits = ci && (r.idxSext ? ci->getValue().isSignedIntN(r.idxBits) : ci->getValue().isIntN(r.idxBits));
    if (r.idxBits < 64 && !fits) {
      if (emit)
        r.idx = widenRail(ctx, r.idx, r.idxBits, r.idxSext, 64);
      r.idxBits = 64;
      r.idxSext = false;
    }
  }
  if (t.idxRail() || e.idxRail()) {
    const Fat &r = t.idxRail() ? t : e;
    f.idxBits = r.idxBits;
    f.idxSext = r.idxSext;
  }
  Operand c = emit ? ctx.operand(sel.getCondition()) : Operand{nullptr, isQ(ctx, sel.getCondition())};
  auto choose = [&](unsigned w, Operand x, Operand y) -> Operand {
    if (!c.handle && (x.handle || y.handle)) {
      // A classical condition over rail fields chooses the rail classically (rule 9 at a classical predicate):
      // a classical select of handles, a classical arm minted as its seed rail (rule 7) first.
      if (!emit)
        return Operand{nullptr, true};
      auto rail = [&](Operand o) -> Value * {
        if (o.handle)
          return o.v;
        CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, intRail(w)}, {o.v});
        ctx.unc().recordSeed(seed);
        return seed;
      };
      Value *xv = rail(x), *yv = rail(y);
      auto *m = cast<Instruction>(ctx.B().CreateSelect(c.v, xv, yv));
      ctx.unc().recordMerge(m);
      return Operand{m, true};
    }
    if (!emit)
      return Operand{nullptr, c.handle};
    return select(ctx, w, c, x, y);
  };
  f.tag = sameClassical(t.tag, e.tag) ? t.tag : choose(32, t.tag, e.tag);
  if (sameClassical(t.idx, e.idx)) {
    f.idx = t.idx;
  } else if (!t.idxRail() && !e.idxRail()) {
    f.idx = choose(64, t.idx, e.idx);
    f.idxBits = 64;
    f.idxSext = false;
  } else {
    // One rail arm and one classical arm: the classical one as a literal at the rail's width (an i64 at 64).
    auto lit = [&](Operand o) -> Operand {
      if (o.handle || !emit)
        return o;
      if (f.idxBits == 64)
        return o;   // a classical idx is an i64
      auto *ci = dyn_cast<ConstantInt>(o.v);
      if (!ci)
        internalError("fatptr: a non-constant classical idx merged with a rail narrower than 64 bits", &sel);
      return Operand{ConstantInt::get(ctx.M.getContext(), ci->getValue().trunc(f.idxBits)), false};
    };
    f.idx = choose(f.idxBits, lit(t.idx), lit(e.idx));
  }
  return f;
}

// The incoming values of a pointer phi that carry a value: each distinct one once, poison and undef dropped
// (any value refines them) unless every incoming is one.
SmallVector<const Value *, 4> phiArms(const PHINode &P) {
  bool allUndef = all_of(P.incoming_values(), [](const Value *v) { return isa<UndefValue>(v); });
  SmallVector<const Value *, 4> arms;
  for (const Value *v : P.incoming_values())
    if ((allUndef || !isa<UndefValue>(v)) && !is_contained(arms, v))
      arms.push_back(v);
  return arms;
}

// Rule 21 (merge over edge predicates; rule 9): a quantum pointer phi is the fat pointer whose tag and idx are
// the merges of its incomings' tags and idx, in the cells of their greatest common divisor, the idx rails at a
// width that reads every arm exactly (deriveSelect's widths, over n arms). The spine calls lower() at the phi,
// which merges the fields there (cq::mergeFieldsOf: a select chain on the edge predicates, or a classical
// phi when the choice is classical) and binds them; later derivations read the bound fields. A field equal on
// every arm stays as it is; a tag that is not one constant is a rail (a classically chosen one is seeded).
Fat derivePhi(LoweringContext &ctx, const PHINode &P, bool emit, bool eager) {
  if (emit && !eager) {
    Fat f = derivePhi(ctx, P, /*emit=*/false, false);
    SmallVector<Operand, 4> fl = ctx.fields(&P);
    if (fl.size() != 2 || fl[0].handle != f.tag.handle || fl[1].handle != f.idx.handle)
      internalError("fatptr: a pointer phi bound to other than its (tag, idx)", &P);
    f.tag = fl[0];
    f.idx = fl[1];
    return f;
  }
  SmallVector<const Value *, 4> arms = phiArms(P);
  SmallVector<Fat, 4> sh;
  for (const Value *v : arms) {
    sh.push_back(derive(ctx, v, /*emit=*/false));
    if (sh.back().trips)
      unimplemented("fatptr: a phi of a pointer to K-loop trip objects (R1)", &P);
  }
  Fat f;
  for (const Fat &a : sh) {
    addRoots(f, a.roots);
    f.nullMoved = f.nullMoved || a.nullMoved;
  }
  llvm::sort(f.roots, [&](const Value *x, const Value *y) { return rootNumber(ctx, x) < rootNumber(ctx, y); });
  uint64_t g = 0;
  for (const Fat &a : sh)
    if (a.cell)
      g = g ? std::gcd(g, a.cell) : a.cell;
  for (Fat &a : sh)
    if (g)
      rescale(ctx, a, g, /*emit=*/false);
  f.cell = g;
  // The rail width: deriveSelect's rule over every rail arm; a classical arm that is no constant readable there
  // takes the merge to 64 bits.
  bool anyRail = false, allSx = true, anySx = false;
  unsigned maxZ = 0, maxS = 0;
  for (const Fat &a : sh)
    if (a.idxRail()) {
      anyRail = true;
      allSx = allSx && a.idxSext;
      anySx = anySx || a.idxSext;
      (a.idxSext ? maxS : maxZ) = std::max(a.idxSext ? maxS : maxZ, a.idxBits);
    }
  unsigned W = 64;
  bool sx = false;
  if (anyRail) {
    if (allSx || !anySx) {
      W = std::max(maxZ, maxS);
      sx = allSx;
    } else {
      W = std::min(64u, std::max(maxZ + 1, maxS));
      sx = W < 64;
    }
    for (const Fat &a : sh)
      if (!a.idxRail()) {
        auto *ci = dyn_cast_or_null<ConstantInt>(a.idx.v);
        bool fits = ci && (sx ? ci->getValue().isSignedIntN(W) : ci->getValue().isIntN(W));
        if (W < 64 && !fits) {
          W = 64;
          sx = false;
        }
      }
  }
  bool classical = cq::classicalChoice(ctx, P);
  auto *t0 = dyn_cast_or_null<ConstantInt>(sh.front().tag.v);
  bool tagConst = all_of(sh, [&](const Fat &a) { return !a.tag.handle && a.tag.v == t0 && t0; });
  auto *i0 = dyn_cast_or_null<ConstantInt>(sh.front().idx.v);
  bool idxSame = all_of(sh, [&](const Fat &a) { return !a.idx.handle && i0 && a.idx.v == i0; });
  bool idxClassical = !anyRail && (classical || idxSame);
  f.tag = tagConst ? Operand{t0, false} : Operand{nullptr, true};
  if (idxClassical) {
    f.idx = Operand{idxSame ? i0 : nullptr, false};
    f.idxBits = 64;
    f.idxSext = false;
  } else {
    f.idx = Operand{nullptr, true};
    f.idxBits = W;
    f.idxSext = sx;
  }
  if (!emit)
    return f;
  // The merge, at the phi (eager: lower()).
  LLVMContext &C = ctx.M.getContext();
  std::map<std::pair<const Value *, BasicBlock *>, SmallVector<Operand, 4>> cache;
  auto read = [&](const Value *v) -> SmallVector<Operand, 4> {
    auto key = std::make_pair(v, ctx.B().GetInsertBlock());
    if (auto it = cache.find(key); it != cache.end())
      return it->second;
    Fat a = derive(ctx, v, /*emit=*/true);
    if (g)
      rescale(ctx, a, g, /*emit=*/true);
    Operand idx = a.idx;
    if (!idxClassical) {
      if (a.idxRail()) {
        idx = widenRail(ctx, a.idx, a.idxBits, a.idxSext, W);
      } else if (W < 64) {
        auto *ci = dyn_cast<ConstantInt>(a.idx.v);
        if (!ci)
          internalError("fatptr: a non-constant classical idx merged with a rail narrower than 64 bits", &P);
        idx = Operand{ConstantInt::get(C, ci->getValue().trunc(W)), false};
      }
    }
    return cache[key] = SmallVector<Operand, 4>{a.tag, idx};
  };
  RailType rails[2] = {intRail(32), intRail(idxClassical ? 64 : W)};
  Type *tys[2] = {i32(ctx), idxClassical ? (Type *)i64(ctx) : (Type *)IntegerType::get(C, W)};
  SmallVector<Operand, 4> m = cq::mergeFieldsOf(ctx, const_cast<PHINode &>(P), rails, tys, read);
  auto railed = [&](Operand o, unsigned w) -> Operand {
    if (o.handle)
      return o;
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, intRail(w)}, {o.v});
    ctx.unc().recordSeed(seed);
    return Operand{seed, true};
  };
  f.tag = tagConst ? m[0] : railed(m[0], 32);
  if (idxClassical) {
    if (m[1].handle)
      internalError("fatptr: a classically merged idx of classical arms that is a rail", &P);
    f.idx = m[1];
  } else {
    f.idx = railed(m[1], W);
  }
  if (tagConst && f.tag.v != t0)
    internalError("fatptr: a pointer phi's constant tag merged to another value", &P);
  return f;
}

// cq-z6q1 (CR rule 21; 189): a pointer loaded from host memory (a slot record's classical pointer field or a
// classical object) through a fat pointer. Its value is a host address decoded at run time by lowerLoad
// (exact start tests over its roots, decodeTag); its roots are the pointers this function stores into the
// objects the load reads, each a root at its start (idx 0: a node pointer), and NULL. Every object of the load's provenance
// must be one of them (a pointer of unknown origin, or one stored by another function or a memory
// intrinsic, is unimplemented). Its idx is the classical 0; its tag the rail lowerLoad bound.
Fat deriveHostLoaded(LoweringContext &ctx, const LoadInst &ld, ArrayRef<ObjectId> src, bool emit) {
  auto intersects = [](ArrayRef<ObjectId> a, ArrayRef<ObjectId> b) {
    for (ObjectId x : a)
      if (llvm::is_contained(b, x))
        return true;
    return false;
  };
  Fat f;
  bool interior = false;
  uint64_t cell = 0;
  for (const Instruction &I : instructions(*ctx.S.F)) {
    if (auto *MI = dyn_cast<MemIntrinsic>(&I); MI && intersects(ctx.T.provenance(MI->getDest(), ctx.S), src))
      unimplemented("fatptr: a memory intrinsic writing memory a pointer is loaded from (rule 21)", &I);
    auto *st = dyn_cast<StoreInst>(&I);
    if (!st || !intersects(ctx.T.provenance(st->getPointerOperand(), ctx.S), src))
      continue;
    if (!st->getValueOperand()->getType()->isPointerTy())
      continue;
    const Value *v = st->getValueOperand();
    if (isa<ConstantPointerNull>(v) || (isRoot(ctx, v) && !isa<GEPOperator>(v) && distinctAllocation(ctx, v))) {
      addRoots(f, {v});
      continue;
    }
    // An interior pointer, or the start of an object that is not a distinct allocation (a global): the loaded
    // address is decoded by range tests over the stored pointers' roots (rule 21), its idx decoded with it.
    Fat sv = derive(ctx, v, /*emit=*/false);
    if (sv.tag.handle || sv.idx.handle)
      internalError("fatptr: a quantum pointer stored into classical host memory", st);
    interior = true;
    for (const Value *r : sv.roots)
      if (!isa<ConstantPointerNull>(r) && !isRoot(ctx, r))
        internalError("fatptr: a stored pointer whose root is not a root", st);
    addRoots(f, sv.roots);
    if (sv.cell)
      cell = cell ? std::gcd(cell, sv.cell) : sv.cell;
  }
  for (ObjectId o : ctx.T.provenance(&ld, ctx.S)) {
    bool covered = false;
    for (const Value *r : f.roots)
      if (!isa<ConstantPointerNull>(r) && llvm::is_contained(ctx.T.provenance(r, ctx.S), o))
        covered = true;
    if (!covered)
      unimplemented("fatptr: a pointer loaded from host memory that may hold a pointer this function does not "
                    "store (unknown origin, rule 21)",
                    &ld);
  }
  if (f.roots.empty())
    unimplemented("fatptr: a pointer loaded from host memory into which this function stores no pointer", &ld);
  llvm::sort(f.roots, [&](const Value *x, const Value *y) { return rootNumber(ctx, x) < rootNumber(ctx, y); });
  if (interior) {
    // The decoded idx: an i64 rail in cells of the stored pointers' common cell (the byte when none has one).
    if (!is_contained(f.roots, (const Value *)ConstantPointerNull::get(cast<PointerType>(ld.getType()))))
      f.roots.insert(f.roots.begin(), ConstantPointerNull::get(cast<PointerType>(ld.getType())));
    f.nullMoved = true;
    f.cell = cell ? cell : 1;
    f.idxBits = 64;
    f.idxSext = false;
    f.tag = Operand{nullptr, true};
    f.idx = Operand{nullptr, true};
    if (!emit)
      return f;
    SmallVector<Operand, 4> fl = ctx.fields(&ld);
    if (fl.size() != 2 || !fl[1].handle)
      internalError("fatptr: a decoded interior pointer bound to other than its (tag, idx) rails", &ld);
    f.tag = fl[0];
    f.idx = fl[1];
    return f;
  }
  f.idx = Operand{ConstantInt::get(i64(ctx), 0), false};
  if (!emit) {
    f.tag = Operand{nullptr, true};
    return f;
  }
  SmallVector<Operand, 4> fl = ctx.fields(&ld);
  if (fl.size() != 2)
    internalError("fatptr: a pointer loaded from host memory bound to other than its (tag, idx)", &ld);
  f.tag = fl[0];
  return f;
}

// A pointer loaded from a QRAM of pointers (rule 21, 88): its (tag, idx) are the two i32 rails its
// loader bound. Its roots are the roots of the pointers this function stores into the objects the load
// reads, restricted to the load's provenance; its cell size their common one.
Fat deriveLoaded(LoweringContext &ctx, const LoadInst &ld, bool emit) {
  // The roots of a pointer loaded from memory are the least fixed point over the pointers stored there: a stored
  // pointer that is itself (through this load again) loaded from the same memory adds no root of its own, so the
  // shape derivation re-entering this load contributes nothing (a cycle: a list node's next loaded and stored).
  static SmallPtrSet<const LoadInst *, 8> active;
  if (!emit && active.count(&ld)) {
    Fat cyc;
    cyc.tag = Operand{nullptr, true};
    cyc.idx = Operand{nullptr, true};
    cyc.idxBits = 32;
    return cyc;
  }
  struct Guard {
    const LoadInst *l;
    bool mine;
    Guard(const LoadInst *l) : l(l), mine(active.insert(l).second) {}
    ~Guard() {
      if (mine)
        active.erase(l);
    }
  } guard(&ld);
  ArrayRef<ObjectId> src = ctx.T.provenance(ld.getPointerOperand(), ctx.S);
  if (src.empty())
    unimplemented("fatptr: a pointer loaded through a pointer with no known object (rule 21)", &ld);
  // cq-oocu (107): a pointer loaded at a classical offset from a slot record's pointer-kind cell; mem-slots
  // binds its (tag, idx) handles. Its roots are those of the pointers this function stores into that object
  // (a clone call writing the cell keeps their provenance: mem-slots checkCloneKeepsTag).
  bool slotCell = src.size() == 1 && ctx.T.classOf(src.front()) == ObjClass::Slot &&
                  !ctx.T.isFatPointer(ld.getPointerOperand(), ctx.S) && !isQ(ctx, ld.getPointerOperand());
  // cq-z6q1 (189): through a fat pointer from slot records' classical pointer fields or classical memory.
  if (!slotCell && llvm::none_of(src, [&](ObjectId o) { return ctx.T.classOf(o) == ObjClass::Qram; }))
    return deriveHostLoaded(ctx, ld, src, emit);
  for (ObjectId o : src)
    if (ctx.T.classOf(o) != ObjClass::Qram && !slotCell)
      unimplemented("fatptr: a pointer loaded through a fat pointer from QRAM and other memory (rule 21)", &ld);
  SmallVector<ObjectId, 4> mine(ctx.T.provenance(&ld, ctx.S).begin(), ctx.T.provenance(&ld, ctx.S).end());
  auto intersects = [](ArrayRef<ObjectId> a, ArrayRef<ObjectId> b) {
    for (ObjectId x : a)
      if (llvm::is_contained(b, x))
        return true;
    return false;
  };
  Fat f;
  bool negative = false;   // a stored pointer's idx may be negative (cq-b244)
  for (const Instruction &I : instructions(*ctx.S.F)) {
    auto *st = dyn_cast<StoreInst>(&I);
    if (!st || !st->getValueOperand()->getType()->isPointerTy() ||
        !intersects(ctx.T.provenance(st->getPointerOperand(), ctx.S), src))
      continue;
    Fat s = derive(ctx, st->getValueOperand(), /*emit=*/false);
    if (s.idx.handle) {
      negative |= s.idxSext;
    } else {
      auto *ci = dyn_cast_or_null<ConstantInt>(s.idx.v);
      negative |= !ci || ci->isNegative();
    }
    if (s.trips)
      unimplemented("fatptr: a pointer to K-loop trip objects stored into a QRAM of pointers (R1)", st);
    f.nullMoved |= s.nullMoved;
    for (const Value *r : s.roots)
      if (intersects(ctx.T.provenance(r, ctx.S), mine))
        addRoots(f, {r});
    if (s.cell) {
      if (f.cell && f.cell != s.cell)
        unimplemented("fatptr: a QRAM or slot cell of pointers holding pointers of two cell sizes", &ld);
      f.cell = s.cell;
    }
  }
  if (f.roots.empty())
    unimplemented("fatptr: a pointer loaded from a QRAM into which this function stores no pointer of its "
                  "provenance",
                  &ld);
  llvm::sort(f.roots, [&](const Value *x, const Value *y) { return rootNumber(ctx, x) < rootNumber(ctx, y); });
  f.idxBits = 32;
  f.idxSext = negative && idxSextAt(ctx, f.roots, f.cell, 32, &ld);   // the stored i32 field (cq-b244)
  if (!emit) {
    f.tag = Operand{nullptr, true};
    f.idx = Operand{nullptr, true};
    return f;
  }
  SmallVector<Operand, 4> fl = ctx.fields(&ld);
  if (fl.size() != 2 || !fl[0].handle || !fl[1].handle)
    internalError("fatptr: a pointer loaded from a QRAM bound to other than its (tag, idx) rails", &ld);
  f.tag = fl[0];
  f.idx = fl[1];
  return f;
}

Fat deriveIntToPtr(LoweringContext &ctx, const IntToPtrInst &I, bool emit);

// The roots a clone's pointer result is derived from (85): its formals and NULL, through selects, phis,
// GEPs and casts. Any other origin (a local, a global, a loaded or computed pointer) is unimplemented.
// nullMoved: NULL is reached through a GEP with an offset (Fat::nullMoved).
void calleeResultRoots(const Function &G, SmallVectorImpl<const Value *> &out, bool &nullMoved, const Value *at) {
  std::set<std::pair<const Value *, bool>> seen;
  SmallVector<std::pair<const Value *, bool>, 8> work;   // (value, a GEP with an offset lies above it)
  for (const BasicBlock &BB : G)
    if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator()))
      work.push_back({RI->getReturnValue(), false});
  while (!work.empty()) {
    auto [v, moved] = work.pop_back_val();
    if (!seen.insert({v, moved}).second)
      continue;
    if (isa<Argument>(v) || isa<ConstantPointerNull>(v)) {
      if (llvm::find(out, v) == out.end())
        out.push_back(v);
      if (isa<ConstantPointerNull>(v) && moved)
        nullMoved = true;
    } else if (auto *sel = dyn_cast<SelectInst>(v)) {
      work.push_back({sel->getTrueValue(), moved});
      work.push_back({sel->getFalseValue(), moved});
    } else if (auto *phi = dyn_cast<PHINode>(v)) {
      for (const Value *in : phi->incoming_values())
        work.push_back({in, moved});
    } else if (auto *g = dyn_cast<GEPOperator>(v)) {
      work.push_back({g->getPointerOperand(), moved || !g->hasAllZeroIndices()});
    } else if (auto *bc = dyn_cast<BitCastOperator>(v)) {
      work.push_back({bc->getOperand(0), moved});
    } else {
      unimplemented("fatptr: a clone's fat-pointer result not derived from its triple formals or NULL (rule 21 "
                    "object table across the call)",
                    at);
    }
  }
}

// The host or slot root (and its cells) each actual crossed a clone boundary as, in this output function
// (passAcrossCall): the roots of a clone's fat-pointer result in the caller's table.
struct Crossed {
  const Value *root;
  uint64_t cell;
};
std::map<const Function *, DenseMap<const Value *, Crossed>> &crossings() {
  static std::map<const Function *, DenseMap<const Value *, Crossed>> m;
  return m;
}

// Rule 21 (85): a clone's fat-pointer result, bound by calls as its two i32 rails (tag, idx) in this
// function's table. Its roots are the roots its triple actuals crossed as (the clone's tag is the actual's
// tag), and NULL (tag 0) when the clone may return NULL; its cell size the actuals' common one.
Fat deriveCallResult(LoweringContext &ctx, const CallBase &CB, bool emit) {
  const Specialization *cs = ctx.T.calleeSpecialization(CB, ctx.S);
  const Function *G = CB.getCalledFunction();
  if (!cs || cs->isEntry() || !G || cs->F != G || G->isDeclaration())
    unimplemented("fatptr: a fat pointer returned by a call that is not a lifted clone (rule 21)", &CB);
  SmallVector<const Value *, 4> cr;
  Fat f;
  calleeResultRoots(*G, cr, f.nullMoved, &CB);
  for (const Value *r : cr) {
    if (isa<ConstantPointerNull>(r)) {
      addRoots(f, {r});
      continue;
    }
    unsigned argNo = cast<Argument>(r)->getArgNo();
    if (ctx.T.pointerFormal(*cs, argNo).abi == PtrAbi::Raw)
      unimplemented("fatptr: a clone's fat-pointer result derived from a raw pointer formal (rule 21)", &CB);
    auto &m = crossings()[&ctx.out()];
    auto it = m.find(CB.getArgOperand(argNo));
    if (it == m.end())
      internalError("fatptr: a clone's fat-pointer result whose triple actual has not crossed", &CB);
    addRoots(f, {it->second.root});
    if (f.cell && f.cell != it->second.cell)
      unimplemented("fatptr: a clone's fat-pointer result over triple actuals of two cell sizes", &CB);
    f.cell = it->second.cell;
  }
  llvm::sort(f.roots, [&](const Value *x, const Value *y) { return rootNumber(ctx, x) < rootNumber(ctx, y); });
  f.idxBits = 32;
  f.idxSext = idxSextAt(ctx, f.roots, f.cell, 32, &CB);   // the returned i32 field (cq-b244)
  if (!emit) {
    f.tag = Operand{nullptr, true};
    f.idx = Operand{nullptr, true};
    return f;
  }
  SmallVector<Operand, 4> fl = ctx.fields(&CB);
  if (fl.size() != 2 || !fl[0].handle || !fl[1].handle)
    internalError("fatptr: a clone's fat-pointer result bound to other than its (tag, idx) rails", &CB);
  f.tag = fl[0];
  f.idx = fl[1];
  return f;
}

Fat derive(LoweringContext &ctx, const Value *p, bool emit, bool eager) {
  if (!p->getType()->isPointerTy())
    internalError("fatptr: derive of a non-pointer", p);
  if (auto *bc = dyn_cast<BitCastOperator>(p))
    return derive(ctx, bc->getOperand(0), emit);
  if (auto *ac = dyn_cast<AddrSpaceCastOperator>(p))
    return derive(ctx, ac->getPointerOperand(), emit);
  if (Bound *b = boundOf(ctx, p)) {
    // P1: the caller's (tag, idx), in cells of the clone's access type (a classical idx as an i64; a
    // shape-only derivation keeps the i32 parameter, never emitted).
    Fat f;
    f.roots.push_back(p);
    f.tag = b->tag;
    f.idx = b->idx;
    f.cell = b->cell;
    if (b->idx.handle) {
      f.idxBits = 32;
      f.idxSext = false;
    } else if (emit) {
      f.idx = Operand{idx64Of(ctx, *b), false};
    }
    return f;
  }
  if (const TripPtr *t = tripOf(ctx, p)) {
    // R1: the bound tag rail at the classical idx 0, over null and the trip objects.
    Fat f;
    for (const Value *in : cast<PHINode>(p)->incoming_values())
      if (isa<ConstantPointerNull>(in) && llvm::find(f.roots, in) == f.roots.end())
        f.roots.push_back(in);
    f.trips = t;
    f.tag = emit ? t->tag : Operand{nullptr, true};
    f.idx = Operand{ConstantInt::get(i64(ctx), 0), false};
    return f;
  }
  if (isRoot(ctx, p))
    return deriveRoot(ctx, p, emit);
  if (auto *g = dyn_cast<GEPOperator>(p))
    return deriveGEP(ctx, *g, emit);
  if (auto *sel = dyn_cast<SelectInst>(p))
    return deriveSelect(ctx, *sel, emit, eager);
  if (const WalkedPtr *w = ctx.walkedPointer(p)) {
    // cq-9w75 (CR rule 14 f981c89): a K-loop's walked pointer is start + j*step bytes in trip j, the
    // phi bound to the constant j: the start's fat pointer moved by j*step / cell cells (classical).
    Fat f = derive(ctx, w->start, emit);
    f.nullMoved |= llvm::any_of(f.roots, [](const Value *r) { return isa<ConstantPointerNull>(r); });
    // The cell: the start's, or the step's when the step is not a whole number of it (their greatest common
    // divisor, the start's idx rescaled): a function of the step alone, so every trip agrees.
    if (w->step != 0) {
      uint64_t st = w->step < 0 ? uint64_t(0) - uint64_t(w->step) : uint64_t(w->step);
      rescale(ctx, f, f.cell ? std::gcd(f.cell, st) : st, emit);
    }
    // A rail start idx moves by an add at the sum width (rule 21, as a GEP's sum).
    unsigned railBits = f.idxBits;
    bool railSext = f.idxSext;
    if (f.idxRail())
      std::tie(railBits, railSext) = sumWidth(ctx, f, f.idxBits);
    if (!emit) {
      if (!f.idxRail())
        f.idx = Operand{nullptr, false};
      else {
        f.idxBits = railBits;
        f.idxSext = railSext;
      }
      return f;
    }
    auto *j = dyn_cast<ConstantInt>(ctx.operand(p).v);
    if (!j)
      internalError("fatptr: a walked pointer not bound to its trip index", p);
    int64_t bytes = j->getSExtValue() * w->step;
    if (f.idxRail()) {
      Operand r = widenRail(ctx, f.idx, f.idxBits, f.idxSext, railBits);
      if (bytes != 0)
        r = Operand{tmpl(ctx, "add", intRail(railBits),
                         {r, Operand{ConstantInt::get(IntegerType::get(ctx.M.getContext(), railBits),
                                                      bytes / int64_t(f.cell), /*signed=*/true),
                                     false}},
                         "hl"),
                    true};
      f.idx = r;
      f.idxBits = railBits;
      f.idxSext = railSext;
      return f;
    }
    if (bytes == 0)
      return f;
    f.idx = Operand{ctx.B().CreateAdd(f.idx.v, ConstantInt::get(i64(ctx), bytes / int64_t(f.cell))), false};
    return f;
  }
  if (auto *pm = dyn_cast<IntrinsicInst>(p); pm && pm->getIntrinsicID() == Intrinsic::ptrmask)
    return derivePtrMask(ctx, *pm, emit, eager);
  if (isCarried(ctx, p)) {
    // R2 (cq-z6q1): the loop's tag rail at the classical idx 0, over the roots of its incomings.
    Fat f;
    for (const Value *in : cast<PHINode>(p)->incoming_values()) {
      if (in == p)
        continue;
      Fat s = derive(ctx, in, /*emit=*/false);
      auto *ci = s.idx.handle ? nullptr : dyn_cast_or_null<ConstantInt>(s.idx.v);
      if (s.trips || s.nullMoved || !ci || !ci->isZero())
        unimplemented("fatptr: a K-loop's carried pointer whose incoming is not at the start of its objects (a "
                      "carried idx, rule 21)",
                      p);
      addRoots(f, s.roots);
    }
    llvm::sort(f.roots, [&](const Value *x, const Value *y) { return rootNumber(ctx, x) < rootNumber(ctx, y); });
    f.tag = emit ? ctx.operand(p) : Operand{nullptr, true};
    f.idx = Operand{ConstantInt::get(i64(ctx), 0), false};
    return f;
  }
  if (auto *phi = dyn_cast<PHINode>(p))
    return derivePhi(ctx, *phi, emit, eager);
  if (auto *ld = dyn_cast<LoadInst>(p))
    return deriveLoaded(ctx, *ld, emit);
  if (isa<Argument>(p))
    unimplemented("fatptr: a fat pointer parameter (rule 21 clone-boundary triple)", p);
  if (auto *ip = dyn_cast<IntToPtrInst>(p))
    return deriveIntToPtr(ctx, *ip, emit);
  if (auto *cb = dyn_cast<CallBase>(p))
    return deriveCallResult(ctx, *cb, emit);
  if (classicalMemoryOnly(ctx, p) == false && !isQ(ctx, p))
    unimplemented("fatptr: a root pointer into slot or QRAM memory", p);
  unimplemented("fatptr: a quantum pointer of this kind", p);
}

// ---- addresses -------------------------------------------------------------------------------

// The root's classical base address (rule 21: a host object's base is its real host address).
using Bases = DenseMap<const Value *, Value *>;   // root -> its ptrtoint, one per compare

// The C address of a classical pointer into a slot object (rule 21, f684858): the object's lowered allocation's
// address plus the pointer's C byte offset into it (its GEPs' terms over classical indices, never the handle-cell
// offsets the lowered GEPs carry). A pointer that does not decompose further (the object itself, a parameter,
// a loaded pointer) is its lowered address.
Value *slotRootAddress(LoweringContext &ctx, const Value *p) {
  const DataLayout &DL = ctx.M.getDataLayout();
  IRBuilder<> &B = ctx.B();
  if (auto *bc = dyn_cast<BitCastOperator>(p))
    return slotRootAddress(ctx, bc->getOperand(0));
  if (auto *g = dyn_cast<GEPOperator>(p)) {
    unsigned bw = DL.getIndexTypeSizeInBits(g->getType());
    MapVector<Value *, APInt> vars;
    APInt off(bw, 0);
    if (!g->collectOffset(DL, bw, vars, off))
      internalError("fatptr: a GEP into a slot object whose offset does not decompose", p);
    Value *a = slotRootAddress(ctx, g->getPointerOperand());
    if (!off.isZero())
      a = B.CreateAdd(a, ConstantInt::get(i64(ctx), off.sextOrTrunc(64)));
    for (auto &[v, scale] : vars) {
      Operand o = ctx.operand(v);
      if (o.handle)
        internalError("fatptr: a classical root's GEP over a quantum index", p);
      Value *t = B.CreateSExtOrTrunc(o.v, i64(ctx));
      a = B.CreateAdd(a, B.CreateMul(t, ConstantInt::get(i64(ctx), scale.sextOrTrunc(64))));
    }
    return a;
  }
  Operand r = ctx.operand(p);
  if (r.handle)
    internalError("fatptr: a root pointer bound to a rail", p);
  return B.CreatePtrToInt(r.v, i64(ctx));
}

Value *rootBase(LoweringContext &ctx, const Value *root, Bases &bases) {
  if (Value *b = bases.lookup(root))
    return b;
  // A QRAM object has no host block: its base is its address in the QRAM address space, the non-canonical
  // 0x4000_0000_0000_0000 + 0x1000·n for object n (rule 21), n its object number.
  if (mem::isQramRoot(ctx, root) && !boundOf(ctx, root)) {
    ArrayRef<ObjectId> objs = ctx.T.provenance(root, ctx.S);
    if (objs.size() != 1)
      internalError("fatptr: a QRAM root of other than one object", root);
    return bases[root] = ConstantInt::get(i64(ctx), (uint64_t(1) << 62) + uint64_t(0x1000) * uint64_t(objs.front()));
  }
  // A slot object's base is its lowered alloca's address, its size the C element size (rule 21, f684858): a root
  // inside a slot object (a classical GEP into it) lies at the object's lowered address plus its C byte offset,
  // so address arithmetic inside the object agrees with C whatever the handle-cell layout.
  bool slot = false;
  for (ObjectId o : ctx.T.provenance(root, ctx.S))
    slot = slot || ctx.T.classOf(o) == ObjClass::Slot;
  if (slot && !boundOf(ctx, root) && !isa<ConstantPointerNull>(root))
    return bases[root] = slotRootAddress(ctx, root);
  Operand r = ctx.operand(root);
  if (r.handle)
    internalError("fatptr: a root pointer bound to a rail", root);
  return bases[root] = ctx.B().CreatePtrToInt(r.v, i64(ctx));
}

// base[tag]: the root's base for a constant tag, else a select chain on tag == k over the pointer's
// roots, the first root innermost (the complement).
Operand baseOf(LoweringContext &ctx, const Fat &f, Bases &cache) {
  if (auto *k = dyn_cast<ConstantInt>(f.tag.v)) {
    for (const Value *r : f.roots)
      if (rootNumber(ctx, r) == k->getZExtValue())
        return Operand{rootBase(ctx, r, cache), false};
    internalError("fatptr: a constant tag naming no root of its pointer");
  }
  if (f.roots.empty())
    internalError("fatptr: a fat pointer with no roots");
  SmallVector<Value *, 4> bases;
  for (const Value *r : f.roots)
    bases.push_back(rootBase(ctx, r, cache));
  Operand acc{bases[0], false};
  for (unsigned i = 1; i < f.roots.size(); ++i) {
    Operand flag = icmp(ctx, CmpInst::ICMP_EQ, 32, f.tag,
                        Operand{ConstantInt::get(i32(ctx), rootNumber(ctx, f.roots[i])), false});
    acc = select(ctx, 64, flag, Operand{bases[i], false}, acc);
  }
  return acc;
}

// The idx as an i64 (its own extension).
Operand idx64(LoweringContext &ctx, const Fat &f) {
  if (!f.idxRail())
    return f.idx;
  if (f.idxBits == 64)
    return f.idx;
  return Operand{tmpl(ctx, f.idxSext ? "sext" : "zext", intRail(f.idxBits), {f.idx}, "", "", intRail(64)), true};
}

// base[tag] + size * idx (base: baseOf(f), when the caller already made it).
Operand address(LoweringContext &ctx, const Fat &f, Bases &cache, std::optional<Operand> made = std::nullopt) {
  Operand base = made ? *made : baseOf(ctx, f, cache);
  Operand off = idx64(ctx, f);
  if (auto *ci = dyn_cast<ConstantInt>(off.v); !off.handle && ci && ci->isZero())
    return base;
  if (f.cell == 0)
    internalError("fatptr: a non-zero cell index with no cell size");
  if (f.cell != 1) {
    if (!off.handle) {
      off = Operand{ctx.B().CreateMul(off.v, ConstantInt::get(i64(ctx), f.cell)), false};
    } else if (isPowerOf2_64(f.cell)) {
      off = Operand{tmpl(ctx, "shl", intRail(64), {off, Operand{ConstantInt::get(i64(ctx), Log2_64(f.cell)), false}},
                         "hl"),
                    true};
    } else {
      off = Operand{tmpl(ctx, "mul", intRail(64), {off, Operand{ConstantInt::get(i64(ctx), f.cell), false}}, "hl"),
                    true};
    }
  }
  return commutative(ctx, "add", 64, base, off);
}

// ---- ptrtoint / inttoptr (rule 21: the two crossings between the fat form and the flat address) ----

// A ptrtoint fatptr lowered: the fat pointer it read and the base[tag] it built, which an inttoptr of an
// integer derived from it reuses (idx = (addr - base[tag]) / size, the base cancelling exactly).
struct Flat {
  Fat f;
  Operand base{nullptr, false};
};
std::map<const Function *, DenseMap<const Value *, Flat>> &flats() {
  static std::map<const Function *, DenseMap<const Value *, Flat>> m;
  return m;
}

// The pointer whose ptrtoint the integer v derives from, by the walk taint's provenance makes (add, disjoint
// or, sub of a constant, zext/sext into the ptrtoint at scale 1; shl, mul and every other term are offsets):
// nullptr when there is none, or when the ptrtoint appears twice or at a scale other than 1.
const PtrToIntInst *derivedFrom(const Value *v) {
  using namespace PatternMatch;
  const PtrToIntInst *found = nullptr;
  bool bad = false;
  std::function<void(const Value *, bool)> go = [&](const Value *V, bool unit) {
    const APInt *K;
    const Value *X, *Y;
    if (auto *PI = dyn_cast<PtrToIntInst>(V)) {
      if (found || !unit)
        bad = true;
      found = PI;
      return;
    }
    if (match(V, m_APInt(K)))
      return;
    if (match(V, m_Add(m_Value(X), m_Value(Y))) || match(V, m_DisjointOr(m_Value(X), m_Value(Y)))) {
      go(X, unit);
      go(Y, unit);
      return;
    }
    if (match(V, m_Sub(m_Value(X), m_APInt(K))) || match(V, m_ZExtOrSExt(m_Value(X)))) {
      go(X, unit);
      return;
    }
  };
  go(v, true);
  return bad ? nullptr : found;
}

// The cell size of the inttoptr's pointer: the size of every load and store directly through it (rule 21:
// idx is a cell index of the access type; the byte offset converts at the access).
// When the pointer is used other than by loads and stores of one size (a GEP on it, a compare, two access sizes,
// no access), the cell is the byte: idx = addr - base[tag] is exact, and each access converts it to its own cells
// (fitCells, rule 21: "byte arithmetic converts at the access by the element size").
uint64_t accessCell(LoweringContext &ctx, const IntToPtrInst &I) {
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t cell = 0;
  for (const User *u : I.users()) {
    Type *t = nullptr;
    if (auto *ld = dyn_cast<LoadInst>(u); ld && ld->getPointerOperand() == &I)
      t = ld->getType();
    else if (auto *st = dyn_cast<StoreInst>(u); st && st->getPointerOperand() == &I)
      t = st->getValueOperand()->getType();
    else
      return 1;
    uint64_t s = DL.getTypeAllocSize(t).getFixedValue();
    if (cell && s != cell)
      return 1;
    cell = s;
  }
  return cell ? cell : 1;
}

// Rule 21, an integer of unknown origin: the candidate objects are the inttoptr's provenance; each is named by
// the root of this function that is its start (an alloca, a global, an allocation call), and NULL (tag 0: an
// address in no candidate decodes as NULL plus the address, so its flat address is kept exactly).
SmallVector<const Value *, 4> candidateRoots(LoweringContext &ctx, const IntToPtrInst &I) {
  SmallVector<const Value *, 4> out;
  out.push_back(ConstantPointerNull::get(cast<PointerType>(I.getType())));
  const Function *F = ctx.S.F;
  SmallPtrSet<const Value *, 32> seen;
  SmallVector<const Value *, 32> table;
  auto visit = [&](const Value *v) {
    if (v->getType()->isPointerTy() && seen.insert(v).second)
      table.push_back(v);
  };
  for (const Argument &a : F->args())
    visit(&a);
  for (const BasicBlock &bb : *F)
    for (const Instruction &J : bb) {
      for (const Use &u : J.operands())
        if (isa<Constant>(u.get()) && !isa<BasicBlock>(u.get()))
          visit(u.get());
      visit(&J);
    }
  // The integer's own data flow: when every leaf of its integer computation is a constant, a ptrtoint or a value
  // narrower than an address, the
  // candidates are those ptrtoints' roots (an address computed here lies in one of them, or in none: NULL).
  {
    SmallPtrSet<const Value *, 16> seenV;
    SmallVector<const Value *, 8> work{I.getOperand(0)};
    SmallVector<const Value *, 4> found;
    bool closed = true;
    while (!work.empty() && closed) {
      const Value *v = work.pop_back_val();
      if (!seenV.insert(v).second || isa<Constant>(v))
        continue;
      if (auto *pi = dyn_cast<PtrToIntInst>(v)) {
        for (const Value *r : derive(ctx, pi->getPointerOperand(), /*emit=*/false).roots)
          if (!is_contained(found, r))
            found.push_back(r);
        continue;
      }
      if (isa<BinaryOperator>(v) || isa<SelectInst>(v) || isa<PHINode>(v) || isa<CastInst>(v)) {
        auto *U = cast<User>(v);
        for (unsigned k = isa<SelectInst>(v) ? 1 : 0; k < U->getNumOperands(); ++k)
          work.push_back(U->getOperand(k));
        continue;
      }
      // Another leaf (a call, an argument, a load) narrower than an address is an offset: it cannot hold an x86-64
      // address. An address-wide one may hold any exposed address: the candidates are then the provenance's.
      if (!v->getType()->isIntegerTy() || v->getType()->getIntegerBitWidth() >= 64)
        closed = false;
    }
    if (closed) {
      for (const Value *r : found)
        if (!is_contained(out, r))
          out.push_back(r);
      llvm::sort(out, [&](const Value *x, const Value *y) { return rootNumber(ctx, x) < rootNumber(ctx, y); });
      return out;
    }
  }
  for (ObjectId o : ctx.T.provenance(&I, ctx.S)) {
    const Value *found = nullptr;
    for (const Value *v : table) {
      if (isa<ConstantPointerNull>(v) || !isRoot(ctx, v))
        continue;
      auto *CB = dyn_cast<CallBase>(v);
      bool start = isa<AllocaInst>(v) || isa<GlobalVariable>(v) ||
                   (CB && CB->getFnAttr(Attribute::AllocSize).isValid());
      ArrayRef<ObjectId> po = ctx.T.provenance(v, ctx.S);
      if (start && po.size() == 1 && po.front() == o) {
        found = v;
        break;
      }
    }
    if (!found)
      unimplemented("fatptr: inttoptr of an integer of unknown origin whose candidate object has no start root in "
                    "this function (rule 21 range decoding)",
                    &I);
    if (!is_contained(out, found))
      out.push_back(found);
  }
  llvm::sort(out, [&](const Value *x, const Value *y) { return rootNumber(ctx, x) < rootNumber(ctx, y); });
  return out;
}

Fat deriveIntToPtr(LoweringContext &ctx, const IntToPtrInst &I, bool emit) {
  const PtrToIntInst *pi = derivedFrom(I.getOperand(0));
  if (!pi) {
    // Range decoding: tag the candidate the address lies in, idx = (addr - base[tag]) / size as an i64 rail.
    Fat f;
    f.roots = candidateRoots(ctx, I);
    f.nullMoved = true;
    f.cell = accessCell(ctx, I);
    f.idxBits = 64;
    f.idxSext = false;
    f.tag = Operand{nullptr, true};
    f.idx = Operand{nullptr, true};
    if (!emit)
      return f;
    SmallVector<Operand, 4> fl = ctx.fields(&I);
    if (fl.size() != 2 || !fl[0].handle || !fl[1].handle)
      internalError("fatptr: a range-decoded inttoptr bound to other than its (tag, idx) rails", &I);
    f.tag = fl[0];
    f.idx = fl[1];
    return f;
  }
  Fat src = derive(ctx, pi->getPointerOperand(), /*emit=*/false);
  Fat f;
  f.roots = src.roots;
  f.nullMoved = llvm::any_of(src.roots, [](const Value *r) { return isa<ConstantPointerNull>(r); });
  f.cell = accessCell(ctx, I);
  f.idxBits = 32;
  f.idxSext = false;
  if (!emit) {
    // idx is a rail when the integer is one or base[tag] is (a rail tag over several roots).
    bool baseRail = src.tag.handle && src.roots.size() > 1;
    f.tag = Operand{nullptr, src.tag.handle};
    f.idx = Operand{nullptr, isQ(ctx, I.getOperand(0)) || baseRail};
    if (!f.idx.handle)
      f.idxBits = 64;
    // A root inside its object (cq-b244): a negative difference, read signed (a classical i64 is exact).
    if (f.idx.handle) {
      // The logical i32 idx when every in-domain index reads exactly at 32 bits, else the exact i64 difference
      // (signed: a root of unknown place may lie inside its object).
      std::optional<bool> sx = idxSextMaybe(ctx, f.roots, f.cell, 32);
      f.idxBits = sx ? 32 : 64;
      f.idxSext = sx ? *sx : true;
    } else {
      f.idxSext = mayPrecede(ctx, f.roots, f.cell);
    }
    return f;
  }
  Fat sh = deriveIntToPtr(ctx, I, /*emit=*/false);
  f.tag = sh.tag;
  f.idx = sh.idx;
  f.idxBits = sh.idxBits;
  f.idxSext = sh.idxSext;
  SmallVector<Operand, 4> fl = ctx.fields(&I);
  if (fl.size() != 2)
    internalError("fatptr: an inttoptr bound to other than its (tag, idx)", &I);
  if (fl[0].handle != f.tag.handle || fl[1].handle != f.idx.handle)
    internalError("fatptr: an inttoptr's bound fields differ in kind from its shape", &I);
  f.tag = fl[0];
  f.idx = fl[1];
  return f;
}

// Every root of both pointers a distinct alloca of this function (rule 21's tag reduction).
bool distinctLocalAllocas(LoweringContext &ctx, const Fat &a, const Fat &b) {
  for (const Fat *f : {&a, &b})
    for (const Value *r : f->roots) {
      if (isa<ConstantPointerNull>(r))
        continue;   // NULL (tag 0) is no allocation's address (85)
      auto *ai = dyn_cast<AllocaInst>(r);
      if ((!ai || ai->getFunction() != ctx.S.F) && !distinctAllocation(ctx, r))
        return false;   // cq-z6q1: a noalias allocation call on no cycle is one object too (189's nodes)
    }
  return true;
}

// idx == idx' at a common width.
Operand idxEqual(LoweringContext &ctx, CmpInst::Predicate p, const Fat &a, const Fat &b) {
  if (a.idxRail() && b.idxRail() && a.idxBits == b.idxBits && a.idxSext == b.idxSext)
    return icmp(ctx, p, a.idxBits, a.idx, b.idx);
  auto narrow = [&](const Fat &r, const Fat &o) -> std::optional<Operand> {
    // A rail idx against a classical constant that fits its width: compare at the rail's width.
    if (!r.idxRail() || o.idxRail())
      return std::nullopt;
    auto *ci = dyn_cast<ConstantInt>(o.idx.v);
    if (!ci)
      return std::nullopt;
    bool fits = r.idxSext ? ci->getValue().isSignedIntN(r.idxBits) : ci->getValue().isIntN(r.idxBits);
    if (!fits)
      return std::nullopt;
    return icmp(ctx, p, r.idxBits, r.idx, Operand{ConstantInt::get(ctx.M.getContext(), ci->getValue().trunc(r.idxBits)), false});
  };
  if (auto o = narrow(a, b))
    return *o;
  if (auto o = narrow(b, a))
    return *o;
  return icmp(ctx, p, 64, idx64(ctx, a), idx64(ctx, b));
}

Operand tagEqual(LoweringContext &ctx, CmpInst::Predicate p, const Fat &a, const Fat &b) {
  return icmp(ctx, p, 32, a.tag, b.tag);
}

Value *asRail(LoweringContext &ctx, Operand o) { return o.handle ? o.v : seedI1(ctx, o.v); }

} // namespace

namespace {
// llvm.ptrmask(p, m) (105; clang's __builtin_align_down / _up) masks p's FLAT ADDRESS: 89's round trip
// (rule 21). u = base[tag] + size * idx, u' = u & m, and the result keeps p's provenance (ptrmask is
// provenance-preserving): the same tag, idx = (u' - base[tag]) / size as an unsigned rail of p's idx
// width (32 at the narrowest: the logical index rail). The spine lowers it once, at the call (lower);
// later derivations read its bound fields. m is a classical constant that keeps cell alignment.
Fat derivePtrMask(LoweringContext &ctx, const IntrinsicInst &pm, bool emit, bool eager) {
  Fat a = derive(ctx, pm.getArgOperand(0), emit && eager);
  // The result's cell (rule 21: idx = (u' - base[tag]) / size, exact): the largest power of two dividing the
  // pointer's cell, the mask's alignment (2^ctz of a constant mask; 1 for a run-time or quantum mask) and every
  // root's known base alignment. In those cells the masked address minus the base is a whole number of cells.
  // A mask narrower than the address (no such type on x86-64: the index width is 64) is zero-extended by LLVM's
  // semantics; ptrmask's mask has the index width, so it is always 64 bits here.
  if (pm.getArgOperand(1)->getType()->getIntegerBitWidth() != 64)
    internalError("fatptr: llvm.ptrmask with a mask that is not the 64-bit index width", &pm);
  auto *m = dyn_cast<ConstantInt>(pm.getArgOperand(1));
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t cell = a.cell ? (a.cell & (~a.cell + 1)) : 1;
  if (m && !m->isZero())
    cell = std::min<uint64_t>(cell, uint64_t(1) << m->getValue().countr_zero());
  else if (!m)
    cell = 1;
  for (const Value *r : a.roots)
    if (!isa<ConstantPointerNull>(r))
      cell = std::min<uint64_t>(cell, r->getPointerAlignment(DL).value());
  if (a.cell && a.cell != cell)
    rescale(ctx, a, cell, emit && eager);
  else if (!a.cell)
    a.cell = cell;
  Fat f;
  f.roots = a.roots;
  f.cell = a.cell;
  f.tag = a.tag;
  bool railIdx = a.idxRail() || a.tagRail() || isQ(ctx, pm.getArgOperand(1));
  f.idxBits = a.idxRail() ? std::max(32u, a.idxBits) : 64;
  // A root inside its object (cq-b244): the masked address may precede it, a negative idx read signed.
  if (railIdx) {
    std::optional<bool> sx = idxSextMaybe(ctx, f.roots, f.cell, f.idxBits);
    if (!sx)
      f.idxBits = 64;   // the exact i64 difference, read signed
    f.idxSext = sx ? *sx : true;
  } else {
    f.idxSext = mayPrecede(ctx, f.roots, f.cell);
  }
  if (!emit) {
    f.idx = Operand{nullptr, railIdx};
    return f;
  }
  if (!eager) {
    SmallVector<Operand, 4> fl = ctx.fields(&pm);
    if (fl.size() != 2)
      internalError("fatptr: a llvm.ptrmask pointer bound to other than its (tag, idx)", &pm);
    f.tag = fl[0];
    f.idx = fl[1];
    return f;
  }
  Bases cache;
  Operand u = address(ctx, a, cache);
  Operand mk = ctx.operand(pm.getArgOperand(1));
  Operand masked = commutative(ctx, "and", 64, u, mk);
  Operand base = baseOf(ctx, a, cache);
  Operand d;
  if (!masked.handle && !base.handle)
    d = Operand{ctx.B().CreateSub(masked.v, base.v), false};
  else if (!base.handle)
    d = Operand{tmpl(ctx, "sub", intRail(64), {masked, base}, "hl"), true};
  else
    d = Operand{tmpl(ctx, "sub", intRail(64), {masked, base}, masked.handle ? "" : "lh"), true};
  if (a.cell != 1) {
    Constant *sh = ConstantInt::get(i64(ctx), Log2_64(a.cell));
    d = d.handle ? Operand{tmpl(ctx, f.idxSext ? "ashr" : "lshr", intRail(64), {d, Operand{sh, false}}, "hl"), true}
                 : Operand{f.idxSext ? ctx.B().CreateAShr(d.v, sh) : ctx.B().CreateLShr(d.v, sh), false};
  }
  if (d.handle && f.idxBits < 64)
    d = Operand{tmpl(ctx, "trunc", intRail(64), {d}, "", "", intRail(f.idxBits)), true};
  if (!d.handle)
    f.idxBits = 64;
  f.idx = d;
  return f;
}
} // namespace

FatPtr lower(LoweringContext &ctx, const Value *ptr) {
  Fat f;
  if (auto *pm = dyn_cast<IntrinsicInst>(ptr); pm && pm->getIntrinsicID() == Intrinsic::ptrmask) {
    f = derive(ctx, ptr, /*emit=*/true, /*eager=*/true);
    ctx.bindFields(pm, {f.tag, f.idx});
  } else if (auto *sel = dyn_cast<SelectInst>(ptr)) {
    // The spine's call at the select (patch spine-dispatch-ptrselect): compute and bind its fields.
    f = derive(ctx, ptr, /*emit=*/true, /*eager=*/true);
    ctx.bindFields(sel, {f.tag, f.idx});
  } else if (auto *phi = dyn_cast<PHINode>(ptr); phi && !isCarried(ctx, phi) && !tripOf(ctx, phi) &&
                                                  !ctx.bound(phi)) {
    // The spine's call at a quantum pointer phi (rule 21, merge over edge predicates): merge and bind its fields.
    f = derive(ctx, ptr, /*emit=*/true, /*eager=*/true);
    ctx.bindFields(phi, {f.tag, f.idx});
  } else {
    f = derive(ctx, ptr, /*emit=*/true);
  }
  if (f.trips)
    unimplemented("fatptr: lower() of a pointer to K-loop trip objects (R1: its objects are per trip)", ptr);
  FatPtr out{f.tag.v, f.tag.handle, f.idx.v, f.idx.handle, {}};
  for (const Value *r : f.roots)
    for (ObjectId o : ctx.T.provenance(r, ctx.S))
      if (llvm::find(out.objects, o) == out.objects.end())
        out.objects.push_back(o);
  return out;
}

namespace {
// Whether the fat pointer may name root (a classical tag names one root only).
bool mayName(LoweringContext &ctx, const Fat &f, const Value *r) {
  if (f.tag.handle || boundOf(ctx, r))
    return true;   // a bound formal's tag is the caller's numbering: the formal is the only root
  auto *k = dyn_cast<ConstantInt>(f.tag.v);
  if (!k)
    internalError("fatptr: a classical tag that is not a constant");
  return k->getZExtValue() == rootNumber(ctx, r);
}

// The guard of root r: tag == r's number, conjoined with the current flag (a fresh i1 rail,
// alloc_i1(false) + and_i1(flag, eq, g), 84). nullptr = unguarded.
Value *guardTag(LoweringContext &ctx, const Fat &f, unsigned k, Value *flag) {
  if (!f.tag.handle)
    return flag;
  Operand eq = icmp(ctx, CmpInst::ICMP_EQ, 32, f.tag, Operand{ConstantInt::get(i32(ctx), k), false});
  if (!eq.handle)
    internalError("fatptr: a tag compare of a rail tag that is classical");
  if (!flag)
    return eq.v;
  CallInst *g = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, intRail(1)}, {ConstantInt::getFalse(ctx.M.getContext())});
  RailId gid = ctx.unc().recordSeed(g);
  abi::CoreSpec andSpec{abi::Core::AndI1, intRail(1)};
  CallInst *c = ctx.emitCore(andSpec, {flag, eq.v, g});
  ctx.unc().recordCore(c, andSpec, {Operand{flag, true}, eq, Operand{g, true}}, gid);
  return g;
}

Value *guardOf(LoweringContext &ctx, const Fat &f, const Value *r, Value *flag) {
  return guardTag(ctx, f, rootNumber(ctx, r), flag);
}
} // namespace


namespace {
// ---- M7: fat pointers over local slot objects (cq-g1ty, CR rules 6, 18, 20, 21; 129) -------------------

// A read-modify-write of one cell: the stored value is U(L, Z), L the load of the cell through the same
// pointer, U add, sub or xor, Z not reading L (zBySub: U = Z - L).
struct CellUpdate {
  Instruction::BinaryOps op = Instruction::Add;
  bool zBySub = false;
  const Value *z = nullptr;
  const LoadInst *load = nullptr;
  Type *ty = nullptr;
};

// L ... S in one block, nothing between them that may write memory, S storing U(L, Z) through L's pointer.
std::optional<CellUpdate> rmwOf(const LoadInst &L, const StoreInst &S) {
  if (L.getParent() != S.getParent() || !L.comesBefore(&S) || !L.isSimple() || !S.isSimple() ||
      L.getPointerOperand() != S.getPointerOperand() || !L.getType()->isIntegerTy() ||
      S.getValueOperand()->getType() != L.getType())
    return std::nullopt;
  for (auto it = std::next(L.getIterator()); &*it != &S; ++it)
    if (it->mayWriteToMemory())
      return std::nullopt;
  auto *bo = dyn_cast<BinaryOperator>(S.getValueOperand());
  if (!bo || bo->getOperand(0) == bo->getOperand(1))
    return std::nullopt;
  CellUpdate c;
  c.op = bo->getOpcode();
  if (c.op != Instruction::Add && c.op != Instruction::Sub && c.op != Instruction::Xor)
    return std::nullopt;
  c.load = &L;
  c.ty = L.getType();
  if (bo->getOperand(0) == &L) {
    c.z = bo->getOperand(1);
  } else if (bo->getOperand(1) == &L) {
    c.z = bo->getOperand(0);
    c.zBySub = c.op == Instruction::Sub;
  } else {
    return std::nullopt;
  }
  return c;
}

// The clone's accesses through pointer formal argNo of G (129's bump: *p += c): one load and, after it, at
// most one store, both through the formal itself in the entry block. With a store: the update U(L, Z), Z a
// constant. Loads only: an update with op Add and no z. Anything else: nullopt.
std::optional<CellUpdate> calleeCellUpdate(const Function &G, unsigned argNo) {
  if (G.isDeclaration() || argNo >= G.arg_size())
    return std::nullopt;
  const Argument *A = G.getArg(argNo);
  const BasicBlock *E = &G.getEntryBlock();
  const LoadInst *L = nullptr;
  const StoreInst *S = nullptr;
  for (const Use &u : A->uses()) {
    const User *usr = u.getUser();
    if (auto *ld = dyn_cast<LoadInst>(usr); ld && !L && ld->getParent() == E && ld->isSimple()) {
      L = ld;
      continue;
    }
    if (auto *st = dyn_cast<StoreInst>(usr);
        st && !S && st->getPointerOperand() == A && st->getParent() == E && st->isSimple()) {
      S = st;
      continue;
    }
    return std::nullopt;
  }
  if (!L || !L->getType()->isIntegerTy())
    return std::nullopt;
  if (!S) {
    CellUpdate c;
    c.load = L;
    c.ty = L->getType();
    return c;
  }
  std::optional<CellUpdate> c = rmwOf(*L, *S);
  if (!c || !isa<ConstantInt>(c->z))
    return std::nullopt;
  return c;
}

// The update a store through a fat pointer over slot objects applies (a read-modify-write through the same
// pointer, Z classical), else nullopt.
std::optional<CellUpdate> fatStoreUpdate(LoweringContext &ctx, const StoreInst &st) {
  auto *bo = dyn_cast<BinaryOperator>(st.getValueOperand());
  if (!bo)
    return std::nullopt;
  for (const Value *op : bo->operands())
    if (auto *L = dyn_cast<LoadInst>(op))
      if (std::optional<CellUpdate> c = rmwOf(*L, st); c && !isQ(ctx, c->z))
        return c;
  return std::nullopt;
}

// U^-1(yp, z): the old cell value from the updated one.
Value *inverseUpdate(LoweringContext &ctx, const CellUpdate &u, Operand yp, Operand z) {
  if (!yp.handle || z.handle)
    internalError("fatptr: a cell update's inverse over a classical image or a quantum operand");
  RailType w = railTypeOf(u.ty);
  switch (u.op) {
  case Instruction::Add:
    if (auto *k = dyn_cast<ConstantInt>(z.v))
      return tmpl(ctx, "add", w, {yp, Operand{ConstantInt::get(k->getType(), -k->getValue()), false}}, "hl");
    return tmpl(ctx, "sub", w, {yp, z}, "hl");
  case Instruction::Sub:
    if (u.zBySub)
      return tmpl(ctx, "sub", w, {z, yp}, "lh");   // y' = z - y: y = z - y'
    return tmpl(ctx, "add", w, {yp, z}, "hl");
  case Instruction::Xor:
    return tmpl(ctx, "xor", w, {yp, z}, "hl");
  default:
    internalError("fatptr: a cell update that is not add, sub or xor");
  }
}

// CR rule 6 (129): the cell of `root` held h and now holds yp = select(eq, U(h, Z), h) (on tag == k the
// update read h). When h is dead (no original value bound to it is used other than by its store into this
// cell or by an earlier pure reader; not measured), it is cleaned from yp: h = select(eq, U^-1(yp, Z), yp),
// the inner U^-1 a fresh garbage rail. A rail this function did not mint (a caller's, a call's result) is
// left alone.
void cleanOldCell(LoweringContext &ctx, Value *h, Value *eq, Value *yp, const CellUpdate &u, Operand z,
                  const Value *root, const Instruction &at) {
  spine::Shared &sh = spine::shared(ctx);
  if (!sh.hist.count(h) || sh.measured.count(h) || sh.ruleSixCleaned.count(h))
    return;
  // A seed (rule 7) is in a known basis state: the uncompute spine releases it; rule 6 is for computed rails.
  if (ctx.unc().liveRole(ctx.unc().idOf(h)) == Role::Seed)
    return;
  DominatorTree &DT = sh.dt(*at.getFunction());
  for (auto &[Y, ops] : sh.binds) {
    if (none_of(ops, [&](const Operand &o) { return o.handle && o.v == h; }))
      continue;
    for (const Use &use : Y->uses()) {
      auto *ui = dyn_cast<Instruction>(use.getUser());
      if (!ui || ui->getFunction() != at.getFunction())
        return;
      if (auto *s2 = dyn_cast<StoreInst>(ui);
          s2 && s2->getValueOperand() == Y && s2->getPointerOperand() == root && DT.dominates(s2, &at))
        continue;
      if (isa<StoreInst>(ui) || isa<CallBase>(ui) || isa<ReturnInst>(ui) || isa<PHINode>(ui) ||
          !DT.dominates(ui, &at))
        return;
    }
  }
  RailId hid = ctx.unc().idOf(h);
  Value *inner = inverseUpdate(ctx, u, Operand{yp, true}, z);
  ctx.unc().noteUse(hid, cast<Instruction>(inner));
  abi::TemplateSpec sel;
  sel.op = "select";
  sel.w = railTypeOf(u.ty);
  ctx.unc().cleanupBijective(hid, sel, {Operand{eq, true}, Operand{inner, true}, Operand{yp, true}});
  sh.ruleSixCleaned.insert(h);
}

// The handle each slot root's cell held at a load through a fat pointer (rule 6 checks its store's old).
std::map<const Function *, std::map<std::pair<const Instruction *, const Value *>, Value *>> &slotArms() {
  static std::map<const Function *, std::map<std::pair<const Instruction *, const Value *>, Value *>> m;
  return m;
}

// The fat pointer's roots as whole local slot objects tagged 1..n (an object table across a call indexes
// them by tag), its idx the classical cell 0.
SmallVector<const Value *, 4> slotRootsOf(LoweringContext &ctx, const Fat &f, const Value *ptr, const Instruction &I) {
  SmallVector<const Value *, 4> rs;
  if (!slotSelectRoots(ctx, ptr, rs) || !f.tag.handle)
    unimplemented("fatptr: an access through a fat pointer over slot objects that is not a quantum select of whole "
                  "local slot objects (M7)",
                  &I);
  auto *ci = dyn_cast_or_null<ConstantInt>(f.idx.v);
  if (f.idx.handle || !ci || !ci->isZero())
    internalError("fatptr: a select of whole slot objects with a cell index other than 0", &I);
  return SmallVector<const Value *, 4>(f.roots.begin(), f.roots.end());
}

Value *tableBase(LoweringContext &ctx, Bound &b, unsigned k) {
  if (b.bases.empty()) {
    IRBuilder<> EB = atEntry(ctx);
    for (unsigned j = 0; j < b.table; ++j) {
      Value *slot = j ? EB.CreateConstInBoundsGEP1_64(PointerType::getUnqual(ctx.M.getContext()), b.object, j)
                      : b.object;
      b.bases.push_back(EB.CreateAlignedLoad(PointerType::getUnqual(ctx.M.getContext()), slot, Align(8)));
    }
  }
  return b.bases[k];
}

// In a clone, the handle cell idx of table object k (a caller's rail: recorded external, never freed here).
Value *tableCell(LoweringContext &ctx, Bound &b, const Fat &f, unsigned k, Value *&ptr) {
  IRBuilder<> &B = ctx.B();
  ptr = B.CreateInBoundsGEP(handleTy(ctx.M.getContext()), tableBase(ctx, b, k), idx64Of(ctx, b));
  LoadInst *h = B.CreateAlignedLoad(handleTy(ctx.M.getContext()), ptr, Align(4));
  ctx.unc().recordExternal(h, Role::UserRegister);
  (void)f;
  return h;
}

void checkTableAccess(LoweringContext &ctx, Bound &b, const Fat &f, Type *ty, const Instruction &I) {
  if (f.idx.handle)
    internalError("fatptr: an access through a slot object table formal at a quantum cell", &I);
  if (ty != b.cellTy)
    internalError("fatptr: an access through a slot object table formal at another type than its update", &I);
}
} // namespace

// P1, rule 21 (190): a load through a slot triple formal at the classical cell j = idx + offset is the
// handle of cell j when j < cellCount, else the clone's shared |0> seed: the cell index is checked against
// the cell count and redirected to cell 0 beyond it (no host memory past the object is read, whatever trip
// a cutoff runs), the handle merged with the seed by a classical select (U1).
Value *boundSlotLoad(LoweringContext &ctx, Bound &b, const Fat &f, Type *ty, const LoadInst &ld) {
  if (f.idx.handle)
    internalError("fatptr: a load through a slot triple formal at a quantum cell index (rule 20: such an object is "
                  "a QRAM)",
                  &ld);
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  const DataLayout &DL = ctx.M.getDataLayout();
  // The cell index in the formal's cells (rule 21: idx converts at the access by the element size): a constant
  // byte or sub-cell index that lands on a whole cell divides exactly; a rail never reaches here (rule 20: QRAM).
  Value *j = f.idx.v;
  if (f.cell != b.cell && f.cell != 0) {
    auto *ci = dyn_cast<ConstantInt>(j);
    int64_t bytes = ci ? ci->getSExtValue() * int64_t(f.cell) : 0;
    if (ci && bytes % int64_t(b.cell) == 0)
      j = ConstantInt::get(i64(ctx), bytes / int64_t(b.cell));
    else if (f.cell % b.cell == 0)
      j = B.CreateMul(j, ConstantInt::get(i64(ctx), f.cell / b.cell));
    else
      unimplemented("fatptr: a load through a slot triple formal at a run-time index in cells smaller than its cells "
                    "(a sub-cell view, rules 20, 21)",
                    &ld);
  }
  // A cell is one scalar (rule 20); a load of another type of the same size is its bit view (rule 4 bitcast).
  if (ty != b.cellTy && DL.getTypeStoreSize(ty) != DL.getTypeStoreSize(b.cellTy))
    unimplemented("fatptr: a load through a slot triple formal of part of a cell (a sub-cell view, rules 20, 21)", &ld);
  Value *ok = B.CreateICmpULT(j, B.CreateZExt(b.cellCount, i64(ctx)));
  Value *safe = B.CreateSelect(ok, j, ConstantInt::get(i64(ctx), 0));
  Value *p = B.CreateInBoundsGEP(handleTy(C), b.object, safe);
  LoadInst *h = B.CreateAlignedLoad(handleTy(C), p, Align(4));
  ctx.unc().recordExternal(h, Role::UserRegister);   // the caller's rail in its cell
  if (!b.zeroSeed) {
    // The clone's shared |0> rail of the cell type, minted once at its entry (190).
    IRBuilder<> EB = atEntry(ctx);
    abi::CoreSpec spec{abi::Core::Alloc, railTypeOf(b.cellTy)};
    CallInst *z = EB.CreateCall(abi::declare(ctx.M, spec), {Constant::getNullValue(b.cellTy)});
    ctx.unc().recordSeed(z);
    b.zeroSeed = z;
  }
  auto *v = cast<Instruction>(B.CreateSelect(ok, h, b.zeroSeed));
  ctx.unc().recordMerge(v);
  if (ty != b.cellTy)
    return tmpl(ctx, "bitcast", railTypeOf(b.cellTy), {Operand{v, true}}, "", "", railTypeOf(ty));
  return v;
}

// The extent of a host root's object from the root on (rule 21's cell count in the object table): the object's
// byte size (a global, an alloca, an allocation call of a constant or run-time allocsize) minus the root's
// constant offset into it, as a classical i64 (a constant when static). nullptr: no extent is known (a pointer
// parameter, a loaded pointer).
Value *hostExtent(LoweringContext &ctx, const Value *root) {
  const DataLayout &DL = ctx.M.getDataLayout();
  APInt off(64, 0);
  const Value *obj = root->stripAndAccumulateConstantOffsets(DL, off, /*AllowNonInbounds=*/true);
  if (isa<GEPOperator>(obj)) {
    // A run-time offset into its object (a classical GEP): the object's extent less the root's distance from it.
    const Value *u = getUnderlyingObject(obj);
    if (u == obj || isa<GEPOperator>(u))
      return nullptr;
    Value *whole = hostExtent(ctx, u);
    Operand r = ctx.operand(root), o = ctx.operand(u);
    if (!whole || r.handle || o.handle)
      return nullptr;
    IRBuilder<> &B = ctx.B();
    return B.CreateSub(whole, B.CreateSub(B.CreatePtrToInt(r.v, i64(ctx)), B.CreatePtrToInt(o.v, i64(ctx))));
  }
  int64_t o = off.getSExtValue();
  if (auto *gv = dyn_cast<GlobalVariable>(obj))
    return ConstantInt::get(i64(ctx), int64_t(DL.getTypeAllocSize(gv->getValueType()).getFixedValue()) - o);
  if (auto *ai = dyn_cast<AllocaInst>(obj)) {
    if (std::optional<TypeSize> t = ai->getAllocationSize(DL); t && !t->isScalable())
      return ConstantInt::get(i64(ctx), int64_t(t->getFixedValue()) - o);
    return nullptr;
  }
  if (auto *CB = dyn_cast<CallBase>(obj)) {
    Attribute as = CB->getFnAttr(Attribute::AllocSize);
    if (!as.isValid())
      return nullptr;
    auto [a, b] = as.getAllocSizeArgs();
    IRBuilder<> &B = ctx.B();
    auto arg = [&](unsigned k) -> Value * {
      Operand n = ctx.operand(CB->getArgOperand(k));
      return n.handle ? nullptr : B.CreateZExtOrTrunc(n.v, i64(ctx));
    };
    Value *n = arg(a);
    if (!n)
      return nullptr;
    if (b) {
      Value *m = arg(*b);
      if (!m)
        return nullptr;
      n = B.CreateMul(n, m);
    }
    return o ? B.CreateSub(n, ConstantInt::get(i64(ctx), o)) : n;
  }
  return nullptr;
}

// CR rule 21: one host object's access of a load through a fat pointer at a classical idx, executed unguarded
// (the merge by tag == k selects it). `check`: the index may lie outside the object on a branch the circuit
// executes (a rail tag: the access runs for every object of the provenance; or a quantum predicate the C program
// would not have reached), so the index is checked against the object's extent and the access reads 0 beyond it,
// never host memory past the object (190). A constant in-range access is a plain load, a constant out-of-range
// one the constant 0; a run-time index loads at a select(ok, p, base) address and selects 0 when not ok.
Operand hostArm(LoweringContext &ctx, const Value *r, const Fat &f, Type *ty, Instruction &at, bool check,
                Align align) {
  const DataLayout &DL = ctx.M.getDataLayout();
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  if (f.idx.handle)
    internalError("fatptr: a host access at a rail idx", &at);
  Value *idx = f.idx.v;
  auto *ci = dyn_cast<ConstantInt>(idx);
  if (!(ci && ci->isZero()) && f.cell == 0)
    internalError("fatptr: a non-zero cell index with no cell size", &at);
  if (mem::hostRecord(ctx, r)) {
    if (!ci)
      unimplemented("fatptr: a load through a fat pointer into a heap slot record at a run-time cell index "
                    "(mem-slots: a record's fields lie at constant offsets)",
                    &at);
    return mem::loadSlotCellAt(ctx, r, ci->getSExtValue() * int64_t(f.cell), ty, at);
  }
  Operand base = ctx.operand(r);
  if (base.handle)
    internalError("fatptr: a root pointer bound to a rail", r);
  int64_t size = int64_t(DL.getTypeStoreSize(ty).getFixedValue());
  Value *byte = ci ? ConstantInt::get(i64(ctx), ci->getSExtValue() * int64_t(f.cell ? f.cell : 1))
                   : B.CreateMul(idx, ConstantInt::get(i64(ctx), f.cell));
  Value *ext = check ? hostExtent(ctx, r) : nullptr;
  // An object with no extent in the module (a pointer parameter, a loaded pointer) has as extent the range of
  // the indices that reach it (rule 20, n = 0, f684858): every index reaching it is in range, so no check.
  if (check && !ext)
    check = false;
  auto *bc = dyn_cast<ConstantInt>(byte);
  auto *ec = dyn_cast_or_null<ConstantInt>(ext);
  if (!check || (bc && ec && bc->getSExtValue() >= 0 && bc->getSExtValue() + size <= ec->getSExtValue())) {
    Value *p = B.CreateInBoundsGEP(Type::getInt8Ty(C), base.v, byte);
    return Operand{B.CreateAlignedLoad(ty, p, align), false};
  }
  if (bc && ec)
    return Operand{Constant::getNullValue(ty), false};
  // ok = 0 <= byte && byte + size <= extent, as one unsigned compare: byte <=u extent - size.
  Value *lim = B.CreateSub(ext, ConstantInt::get(i64(ctx), size));
  Value *ok = B.CreateAnd(B.CreateICmpSGE(lim, ConstantInt::get(i64(ctx), 0)), B.CreateICmpULE(byte, lim));
  Value *safe = B.CreateSelect(ok, byte, ConstantInt::get(i64(ctx), 0));
  Value *p = B.CreateGEP(Type::getInt8Ty(C), base.v, safe);
  Value *v = B.CreateAlignedLoad(ty, p, Align(1));
  return Operand{B.CreateSelect(ok, v, Constant::getNullValue(ty)), false};
}

// Rule 21 (85, 107, 190): a load through a host triple formal at the classical cell j = idx + offset: the host
// load of cell j of the caller's object. With `check` (a quantum predicate is in scope, so the circuit may run the
// access where C would not) j is checked against the cell count the triple carries and cell 0 is read beyond it,
// the value then 0; otherwise it is a plain load (107: the count is passed, the body ignores it).
Operand boundHostLoad(LoweringContext &ctx, Bound &b, const Fat &f, Type *ty, LoadInst &ld, bool check) {
  const DataLayout &DL = ctx.M.getDataLayout();
  if (DL.getTypeAllocSize(ty).getFixedValue() != b.cell || f.cell != b.cell)
    internalError("fatptr: a load through a host triple formal at another cell size than the formal's", &ld);
  IRBuilder<> &B = ctx.B();
  if (f.idx.handle) {
    // Rules 20, 21: classical memory read at a quantum offset is a QROM over the caller's object: its host
    // pointer, the triple's cell count as n (a run-time i64; an index at or past it reads 0, §2), the idx rail.
    if (!b.cellCount)
      internalError("fatptr: a host triple formal loaded through with no cell count (rule 21 TripleCount)", &ld);
    abi::TemplateSpec spec;
    spec.op = "qrom_load";
    spec.w = railTypeOf(ty);
    Value *n = B.CreateZExt(b.cellCount, i64(ctx));
    return Operand{ctx.emitTemplate(spec, {Operand{b.object, false}, Operand{n, false}, f.idx}), true};
  }
  Value *j = f.idx.v;
  if (!check) {
    Value *p = B.CreateInBoundsGEP(ty, b.object, j);
    return Operand{B.CreateAlignedLoad(ty, p, ld.getAlign()), false};
  }
  if (!b.cellCount)
    internalError("fatptr: a host triple formal loaded through with no cell count (rule 21 TripleCount)", &ld);
  Value *ok = B.CreateICmpULT(j, B.CreateZExt(b.cellCount, i64(ctx)));
  Value *safe = B.CreateSelect(ok, j, ConstantInt::get(i64(ctx), 0));
  Value *v = B.CreateAlignedLoad(ty, B.CreateInBoundsGEP(ty, b.object, safe), ld.getAlign());
  return Operand{B.CreateSelect(ok, v, Constant::getNullValue(ty)), false};
}

// cq-z6q1 (CR rule 21; 189): a fat pointer with a quantum tag at a classical idx whose roots are heap slot
// records and classical host objects, and NULL.
bool hostOrRecordRoots(LoweringContext &ctx, const Fat &f) {
  if (!f.tag.handle || f.idx.handle || f.trips)
    return false;
  bool any = false;
  for (const Value *r : f.roots) {
    if (isa<ConstantPointerNull>(r))
      continue;
    if (boundOf(ctx, r) || mem::isQramRoot(ctx, r))
      return false;
    if (!mem::hostRecord(ctx, r) && !classicalMemoryOnly(ctx, r))
      return false;
    any = true;
  }
  return any;
}

// A host address decoded at run time to its tag over the roots (rule 21, unknown origin). Its only producer is
// deriveHostLoaded, which requires every stored pointer to be an object start (idx 0), so the test is exact:
// addr == base[o] (owner ruling 2026-11-02, cq-0w0g). The one-past-included range test would let a pointer to
// the start of an object adjacent to the end of another decode as the other (real malloc places blocks
// adjacently); it belongs only to a decode of a possibly interior pointer, which then must let an object
// starting at the address win over the one it is one past, and is not built. A matching root's tag (roots are
// distinct allocations, so at most one matches); an address that is no root's start (NULL) is tag 0. A
// classical select chain, the last root innermost.
Value *decodeTag(LoweringContext &ctx, Value *addrPtr, ArrayRef<const Value *> roots) {
  IRBuilder<> &B = ctx.B();
  Value *addr = B.CreatePtrToInt(addrPtr, i64(ctx));
  Value *acc = ConstantInt::get(i32(ctx), 0);
  for (size_t i = roots.size(); i-- > 0;) {
    const Value *r = roots[i];
    if (isa<ConstantPointerNull>(r))
      continue;
    Operand base = ctx.operand(r);
    if (base.handle)
      internalError("fatptr: a root pointer bound to a rail", r);
    Value *in = B.CreateICmpEQ(addr, B.CreatePtrToInt(base.v, i64(ctx)));
    acc = B.CreateSelect(in, ConstantInt::get(i32(ctx), rootNumber(ctx, r)), acc);
  }
  return acc;
}

// Rule 21, a host address loaded at run time that may point inside its object: decoded by range tests over the
// roots (base <= addr <= base + size·n, one past the end included; an object starting at the address wins over
// the one it is one past, ruling 2026-11-02 cq-0w0g: the one-past tests first, the interior tests after), its
// idx = (addr - base[tag]) / cell. No match (NULL) is tag 0 with idx addr / cell. Classical selects.
std::pair<Value *, Value *> decodeRange(LoweringContext &ctx, Value *addrPtr, ArrayRef<const Value *> roots,
                                        uint64_t cell, const Instruction &at) {
  IRBuilder<> &B = ctx.B();
  Value *addr = B.CreatePtrToInt(addrPtr, i64(ctx));
  struct Cand {
    const Value *r;
    Value *base, *end;
  };
  SmallVector<Cand, 4> cs;
  for (const Value *r : roots) {
    if (isa<ConstantPointerNull>(r))
      continue;
    Operand b = ctx.operand(r);
    if (b.handle)
      internalError("fatptr: a root pointer bound to a rail", r);
    Value *ext = hostExtent(ctx, r);
    Value *base = B.CreatePtrToInt(b.v, i64(ctx));
    cs.push_back({r, base, ext ? B.CreateAdd(base, ext) : nullptr});
  }
  Value *tag = ConstantInt::get(i32(ctx), 0), *base = ConstantInt::get(i64(ctx), 0);
  auto pick = [&](Value *c, const Cand &k) {
    tag = B.CreateSelect(c, ConstantInt::get(i32(ctx), rootNumber(ctx, k.r)), tag);
    base = B.CreateSelect(c, k.base, base);
  };
  // A candidate with no extent in the module (rule 20, n = 0: its extent is every index that reaches it) holds
  // every address from its base on; among several such, the nearest base at or below the address. The known
  // extents' tests come after (they are exact and win).
  for (const Cand &k : cs)
    if (!k.end)
      pick(B.CreateAnd(B.CreateICmpUGE(addr, k.base), B.CreateICmpUGE(k.base, base)), k);
  for (const Cand &k : cs)
    if (k.end)
      pick(B.CreateICmpEQ(addr, k.end), k);
  for (const Cand &k : cs)
    if (k.end)
      pick(B.CreateAnd(B.CreateICmpUGE(addr, k.base), B.CreateICmpULT(addr, k.end)), k);
  Value *off = B.CreateSub(addr, base);
  if (cell != 1)
    off = isPowerOf2_64(cell) ? B.CreateLShr(off, Log2_64(cell)) : B.CreateUDiv(off, ConstantInt::get(i64(ctx), cell));
  return {tag, off};
}

// The load through such a fat pointer: one unguarded access per root at the classical byte offset (a heap
// record's field: its handle, or the host load of a classical field; a classical object: a host load, which
// must lie inside the object), merged by select on tag == k, the first root innermost (the complement; NULL
// is dropped: a load through it is undefined). A loaded pointer is decoded per root at run time (decodeTag
// over the roots of the loaded pointer, deriveHostLoaded) and the tags merged alike; its idx is 0.
void lowerHostLoad(LoweringContext &ctx, LoadInst &ld, const Fat &f) {
  Type *ty = ld.getType();
  bool ptr = ty->isPointerTy();
  SmallVector<const Value *, 4> loadedRoots;
  if (ptr) {
    Fat lf = derive(ctx, &ld, /*emit=*/false);
    loadedRoots.assign(lf.roots.begin(), lf.roots.end());
  }
  bool interior = false;
  uint64_t loadedCell = 0;
  if (ptr) {
    Fat lf = derive(ctx, &ld, /*emit=*/false);
    interior = lf.idx.handle;
    loadedCell = lf.cell;
  }
  SmallVector<std::pair<const Value *, Operand>, 4> arms;
  SmallVector<Operand, 4> idxArms;
  for (const Value *r : f.roots) {
    if (isa<ConstantPointerNull>(r))
      continue;
    Operand v = hostArm(ctx, r, f, ty, ld, /*check=*/true, ld.getAlign());
    if (ptr) {
      if (v.handle)
        internalError("fatptr: a pointer field holding a handle", &ld);
      if (interior) {
        auto [t, i] = decodeRange(ctx, v.v, loadedRoots, loadedCell, ld);
        v = Operand{t, false};
        idxArms.push_back(Operand{i, false});
      } else {
        v = Operand{decodeTag(ctx, v.v, loadedRoots), false};
      }
    }
    arms.push_back({r, v});
  }
  if (interior) {
    Operand tacc = arms[0].second, iacc = idxArms[0];
    for (size_t i = 1; i < arms.size(); ++i) {
      Operand eq = icmp(ctx, CmpInst::ICMP_EQ, 32, f.tag,
                        Operand{ConstantInt::get(i32(ctx), rootNumber(ctx, arms[i].first)), false});
      auto sel = [&](RailType w, Operand x, Operand acc) {
        std::string shape = std::string(x.handle ? "h" : "l") + (acc.handle ? "h" : "l");
        return Operand{tmpl(ctx, "select", w, {eq, x, acc}, shape == "hh" ? "" : shape), true};
      };
      tacc = sel(intRail(32), arms[i].second, tacc);
      iacc = sel(intRail(64), idxArms[i], iacc);
    }
    auto rail = [&](Operand o, RailType w) {
      if (o.handle)
        return o;
      CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {o.v});
      ctx.unc().recordSeed(seed);
      return Operand{seed, true};
    };
    ctx.bindFields(&ld, {tacc, rail(iacc, intRail(64))});
    return;
  }
  if (arms.empty())
    internalError("fatptr: a fat pointer naming none of its roots", &ld);
  RailType w = ptr ? intRail(32) : railTypeOf(ty);
  Operand acc = arms[0].second;
  for (size_t i = 1; i < arms.size(); ++i) {
    Operand eq = icmp(ctx, CmpInst::ICMP_EQ, 32, f.tag,
                      Operand{ConstantInt::get(i32(ctx), rootNumber(ctx, arms[i].first)), false});
    std::string shape = std::string(arms[i].second.handle ? "h" : "l") + (acc.handle ? "h" : "l");
    acc = Operand{tmpl(ctx, "select", w, {eq, arms[i].second, acc}, shape == "hh" ? "" : shape), true};
  }
  if (ptr) {
    ctx.bindFields(&ld, {acc, Operand{ConstantInt::get(i32(ctx), 0), false}});
    return;
  }
  ctx.bindFields(&ld, {acc});
}

// Rule 21: a load through a fat pointer is one pure access per object of its provenance, executed
// unguarded at idx (a QRAM load; a QROM of a classical object at a rail idx), merged by a select chain
// on the flags tag == k (the first root innermost, the complement), like any multi-way merge (rule 9).
// A pointer load (a QRAM of pointers, 88) merges its tag and idx halves alike and binds them as the
// load's two fields.
void lowerLoad(LoweringContext &ctx, LoadInst &ld) {
  Fat f = derive(ctx, ld.getPointerOperand(), /*emit=*/true);
  Type *ty = ld.getType();
  bool ptr = ty->isPointerTy();
  if (f.trips) {
    // R1 (91, rules 20, 21): one slot load per trip object (its captured handle, no gate), merged by select
    // on tag == k, the last trip innermost (the complement). The null root is dropped: a load through null
    // is undefined, so the tag never names it on an in-domain path.
    if (ptr || (!ty->isIntegerTy() && !ty->isFloatingPointTy()))
      unimplemented("fatptr: a load of a pointer, aggregate or vector through a pointer to K-loop trip objects (R1)",
                    &ld);
    for (const Value *r : f.roots)
      if (!undefinedNull(ctx, r))
        unimplemented("fatptr: a load through a pointer to K-loop trip objects that may name another root (R1)", &ld);
    auto *ci = f.idx.handle ? nullptr : dyn_cast<ConstantInt>(f.idx.v);
    if (!ci)
      unimplemented("fatptr: a load through a pointer to K-loop trip objects at a run-time or quantum cell (R1)", &ld);
    int64_t byte = ci->isZero() ? 0 : ci->getSExtValue() * int64_t(f.cell);
    SmallVector<std::pair<unsigned, Operand>, 4> arms;
    for (const TripObject &o : f.trips->objs) {
      const TripCell *c = nullptr;
      for (const TripCell &x : o.cells)
        if (x.byte == byte && x.ty == ty)
          c = &x;
      if (!c)
        internalError("fatptr: a load through a pointer to K-loop trip objects at a cell the loop did not capture", &ld);
      arms.push_back({o.tag, c->h});
    }
    if (arms.empty())
      internalError("fatptr: a pointer to K-loop trip objects with no trip", &ld);
    RailType w = railTypeOf(ty);
    Operand acc = arms.back().second;
    for (size_t i = arms.size() - 1; i-- > 0;) {
      Operand eq = icmp(ctx, CmpInst::ICMP_EQ, 32, f.tag, Operand{ConstantInt::get(i32(ctx), arms[i].first), false});
      if (!arms[i].second.handle && !acc.handle)
        unimplemented("fatptr: a load through a pointer to K-loop trip objects whose cells are classical (R1)", &ld);
      std::string shape = std::string(arms[i].second.handle ? "h" : "l") + (acc.handle ? "h" : "l");
      acc = Operand{tmpl(ctx, "select", w, {eq, arms[i].second, acc}, shape == "hh" ? "" : shape), true};
    }
    if (!acc.handle)
      unimplemented("fatptr: a load through a pointer to K-loop trip objects whose cell is classical (R1)", &ld);
    ctx.bind(&ld, acc.v);
    return;
  }
  if (!ptr && !ty->isIntegerTy() && !ty->isFloatingPointTy())
    unimplemented("fatptr: a load of an aggregate or vector through a fat pointer (rules 21, 25, 26)", &ld);
  if (f.roots.size() == 1)
    if (Bound *b = boundOf(ctx, f.roots[0]); b && b->table) {
      // M7 (129): the handle in cell idx of each table object, merged by select on tag == k (the last innermost).
      checkTableAccess(ctx, *b, f, ty, ld);
      Value *ign = nullptr;
      SmallVector<Value *, 4> hk;
      for (unsigned k = 0; k < b->table; ++k)
        hk.push_back(tableCell(ctx, *b, f, k, ign));
      Operand acc{hk.back(), true};
      for (unsigned k = b->table - 1; k-- > 0;) {
        Operand eq = icmp(ctx, CmpInst::ICMP_EQ, 32, f.tag, Operand{ConstantInt::get(i32(ctx), k + 1), false});
        acc = Operand{tmpl(ctx, "select", railTypeOf(ty), {eq, Operand{hk[k], true}, acc}, ""), true};
      }
      ctx.bind(&ld, acc.v);
      return;
    }
  if (hostOrRecordRoots(ctx, f)) {
    lowerHostLoad(ctx, ld, f);
    return;
  }
  SmallVector<const Value *, 4> roots;
  // NULL (tag 0, 85) contributes 0: a load through it is undefined, so the complement of the other
  // objects' guards reads the constant 0 (the select chain starts from it).
  bool null = false;
  for (const Value *r : f.roots)
    if (mayName(ctx, f, r)) {
      if (isa<ConstantPointerNull>(r))
        null = true;
      else
        roots.push_back(r);
    }
  if (roots.empty())
    internalError("fatptr: a fat pointer naming none of its roots", &ld);
  // Rule 21: the index may lie outside an object on a branch the circuit executes when a rail tag runs every
  // object's access, or a quantum predicate is in scope.
  bool check = f.tag.handle || ctx.currentFlag();
  SmallVector<std::pair<Operand, Operand>, 4> hs;   // per root: the value (ptr: tag, idx)
  Operand none{nullptr, false};
  for (const Value *r : roots) {
    if (Bound *b = boundOf(ctx, r); b && b->pointee == ObjClass::Slot) {
      if (ptr)
        unimplemented("fatptr: a pointer loaded through a slot triple formal (rule 21)", &ld);
      hs.push_back({Operand{boundSlotLoad(ctx, *b, f, ty, ld), true}, none});
      continue;
    }
    if (Bound *b = boundOf(ctx, r); b && b->pointee == ObjClass::Classical) {
      if (ptr)
        unimplemented("fatptr: a pointer loaded through a host triple formal (rule 21 decoded address)", &ld);
      hs.push_back({boundHostLoad(ctx, *b, f, ty, ld, check), none});
      continue;
    }
    if (isSlotRoot(ctx, r)) {
      // M7 (129; rules 20, 21): the handle (or the classical value) in the slot object's cell at the classical
      // constant idx (no gate), merged below; a cell outside the object reads 0.
      if (ptr)
        unimplemented("fatptr: a pointer loaded through a fat pointer over slot objects (rule 21)", &ld);
      auto *ci = f.idx.handle ? nullptr : dyn_cast<ConstantInt>(f.idx.v);
      if (!ci)
        unimplemented("fatptr: a load through a fat pointer over slot objects at a run-time or quantum cell index "
                      "(mem-slots: a per-object dynamic slot load)",
                      &ld);
      int64_t byte = ci->isZero() ? 0 : ci->getSExtValue() * int64_t(f.cell);
      uint64_t size = ctx.M.getDataLayout().getTypeStoreSize(ty).getFixedValue();
      std::optional<uint64_t> n = objectBytes(ctx, r);
      if (!n)
        internalError("fatptr: a local slot object with no static size", r);
      if (byte < 0 || uint64_t(byte) + size > *n) {
        hs.push_back({Operand{Constant::getNullValue(ty), false}, none});
        continue;
      }
      Operand h = mem::readFatCell(ctx, r, ty, byte, ld);
      if (h.handle)
        slotArms()[&ctx.out()][{&ld, r}] = h.v;
      hs.push_back({h, none});
      continue;
    }
    if (mem::isQramRoot(ctx, r)) {
      // In cells of the QRAM's element (the idx converted, rule 21).
      Fat g = f;
      if (g.cell && g.cell != mem::qramElemBytes(ctx, r, ld) && !fitCells(ctx, g, mem::qramElemBytes(ctx, r, ld), ld.getAlign()))
        unimplemented("fatptr: a fat pointer whose cells do not convert to its QRAM object's element (rule 21)", &ld);
      if (ptr) {
        auto [t, i] = mem::qramLoadPtrAt(ctx, r, g.idx, ld);
        hs.push_back({Operand{t, true}, Operand{i, true}});
      } else {
        hs.push_back({Operand{mem::qramLoadAt(ctx, r, g.idx, ty, ld, g.idxBits), true}, none});
      }
      continue;
    }
    if (!ptr && classicalMemoryOnly(ctx, r) && f.idxRail()) {
      // A QROM over the object in cells of the loaded type (its idx converted at the access, rule 21).
      uint64_t size = ctx.M.getDataLayout().getTypeAllocSize(ty).getFixedValue();
      Fat g = f;
      if (!fitCells(ctx, g, size, ld.getAlign()))
        unimplemented("fatptr: a fat-pointer QROM read at a type that does not cover whole cells of the pointer "
                      "(a misaligned bit view, rule 21)",
                      &ld);
      hs.push_back({Operand{mem::qromLoadAt(ctx, r, g.idx, g.idxBits, g.idxSext, ty, ld), true}, none});
      continue;
    }
    if (!ptr && classicalMemoryOnly(ctx, r)) {
      // Rule 21: a classical load of classical memory at the classical idx, checked against the object's extent.
      hs.push_back({hostArm(ctx, r, f, ty, ld, check, ld.getAlign()), none});
      continue;
    }
    unimplemented("fatptr: a pointer loaded through a fat pointer from classical memory among other objects "
                  "(rule 21, 189)",
                  &ld);
  }
  // The merge (rule 21, rule 9): a classical tag names its one root; a rail tag selects on tag == k, the first
  // root innermost (the complement), or NULL's classical 0 innermost.
  auto merge = [&](RailType w, Type *cty, auto pick) -> Operand {
    if (!f.tag.handle) {
      if (roots.size() != 1)
        internalError("fatptr: a classical tag naming several roots", &ld);
      return pick(hs[0]);
    }
    Operand acc = null ? Operand{Constant::getNullValue(cty), false} : pick(hs[0]);
    for (unsigned i = null ? 0 : 1; i < roots.size(); ++i) {
      Operand eq = icmp(ctx, CmpInst::ICMP_EQ, 32, f.tag,
                        Operand{ConstantInt::get(i32(ctx), rootNumber(ctx, roots[i])), false});
      Operand v = pick(hs[i]);
      std::string shape = std::string(v.handle ? "h" : "l") + (acc.handle ? "h" : "l");
      acc = Operand{tmpl(ctx, "select", w, {eq, v, acc}, shape == "hh" ? "" : shape), true};
    }
    return acc;
  };
  // The load's value is quantum (rule 3): a classical outcome (a classical tag over a classical cell) is its
  // seed rail (rule 7).
  auto rail = [&](Operand o, RailType w) -> Value * {
    if (o.handle)
      return o.v;
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {o.v});
    ctx.unc().recordSeed(seed);
    return seed;
  };
  if (ptr) {
    Operand tag = merge(intRail(32), i32(ctx), [](auto &p) { return p.first; });
    Operand idx = merge(intRail(32), i32(ctx), [](auto &p) { return p.second; });
    ctx.bindFields(&ld, {tag, idx});
    return;
  }
  ctx.bind(&ld, rail(merge(railTypeOf(ty), ty, [](auto &p) { return p.first; }), railTypeOf(ty)));
}

SmallVector<Operand, 8> loadHostCells(LoweringContext &ctx, const Value *src, Type *cellTy, uint64_t n,
                                      function_ref<uint64_t(const Value *root)> bound, const Instruction &at) {
  Fat f = derive(ctx, src, /*emit=*/true);
  if (f.trips)
    unimplemented("fatptr: a memory intrinsic through a pointer to K-loop trip objects (R1)", &at);
  if (!cellTy->isIntegerTy() && !cellTy->isFloatingPointTy())
    unimplemented("fatptr: a memory intrinsic copying cells that are not integers or floating point through a fat "
                  "source pointer",
                  &at);
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t size = DL.getTypeAllocSize(cellTy).getFixedValue();
  Align srcAlign(1);
  if (auto *MT = dyn_cast<MemTransferInst>(&at))
    srcAlign = MT->getSourceAlign().valueOrOne();
  auto *ci = f.idx.handle ? nullptr : dyn_cast<ConstantInt>(f.idx.v);
  int64_t base = ci ? ci->getSExtValue() * int64_t(f.cell) : 0;
  // A rail idx (rules 20, 22): one quantum-offset load per cell, at idx + j in cells of the copied type.
  Fat g = f;
  if (f.idxRail() && !fitCells(ctx, g, size, srcAlign))
    unimplemented("fatptr: a memory intrinsic's fat source pointer at a quantum cell index whose cells do not "
                  "convert to the copied cells (a misaligned bit view, rule 21)",
                  &at);
  SmallVector<const Value *, 4> roots;
  SmallVector<uint64_t, 4> bounds;
  for (const Value *r : f.roots) {
    if (!mayName(ctx, f, r) || isa<ConstantPointerNull>(r))
      continue;
    roots.push_back(r);
    // Rule 22: never past r's object (an in-domain copy from a constant cell of it ends inside it).
    uint64_t b = bound(r);
    std::optional<uint64_t> ob = objectBytes(ctx, r);
    if (auto *gv = dyn_cast<GlobalVariable>(r); gv && gv->getValueType()->isSized())
      ob = DL.getTypeAllocSize(gv->getValueType()).getFixedValue();
    if (ob && ci && base >= 0)
      b = std::min<uint64_t>(b, *ob > uint64_t(base) ? *ob - uint64_t(base) : 0);
    bounds.push_back(b);
  }
  if (roots.empty())
    internalError("fatptr: a fat pointer naming none of its roots", &at);
  RailType w = railTypeOf(cellTy);
  DenseMap<const Value *, Operand> flags;   // tag == k, once per root
  auto flagOf = [&](const Value *r) {
    auto it = flags.find(r);
    if (it != flags.end())
      return it->second;
    Operand eq = icmp(ctx, CmpInst::ICMP_EQ, 32, f.tag, Operand{ConstantInt::get(i32(ctx), rootNumber(ctx, r)), false});
    return flags[r] = eq;
  };
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  // Cell j of root r: a classical memory object is a host load (a constant idx: at its byte, as -O1 addresses it;
  // a run-time idx: checked against the object's extent, 0 beyond it, rule 21) or a QROM at a rail idx; a QRAM a
  // QRAM load; a local slot object the handle (or classical value) in its cell at a constant idx.
  auto cellOf = [&](const Value *r, uint64_t j) -> Operand {
    Operand rv = ctx.operand(r);
    if (rv.handle)
      internalError("fatptr: a root pointer bound to a rail", r);
    if (g.idxRail()) {
      Operand ij = g.idx;
      if (j)
        ij = Operand{tmpl(ctx, "add", intRail(g.idxBits),
                          {ij, Operand{ConstantInt::get(IntegerType::get(C, g.idxBits), j), false}}, "hl"),
                     true};
      if (mem::isQramRoot(ctx, r)) {
        if (mem::qramElemBytes(ctx, r, at) != size)
          unimplemented("fatptr: a memory intrinsic's quantum-index source into a QRAM of another element size", &at);
        return Operand{mem::qramLoadAt(ctx, r, ij, cellTy, at, g.idxBits), true};
      }
      if (classicalMemoryOnly(ctx, r))
        return Operand{mem::qromLoadAt(ctx, r, ij, g.idxBits, g.idxSext, cellTy, at), true};
      unimplemented("fatptr: a memory intrinsic's quantum-index source into a slot object (mem-slots: a QRAM)", &at);
    }
    if (mem::isQramRoot(ctx, r)) {
      if (mem::qramElemBytes(ctx, r, at) != size || (f.cell && f.cell != size))
        unimplemented("fatptr: a memory intrinsic's source into a QRAM at cells of another size", &at);
      Value *ij = B.CreateAdd(f.idx.v, ConstantInt::get(i64(ctx), j));
      return Operand{mem::qramLoadAt(ctx, r, Operand{ij, false}, cellTy, at), true};
    }
    if (isSlotRoot(ctx, r)) {
      if (!ci)
        unimplemented("fatptr: a memory intrinsic's source into a slot object at a run-time cell index (mem-slots: "
                      "a per-object dynamic slot load)",
                      &at);
      return mem::readFatCell(ctx, r, cellTy, base + int64_t(j * size), const_cast<Instruction &>(at));
    }
    if (!classicalMemoryOnly(ctx, r))
      unimplemented("fatptr: a memory intrinsic's fat source pointer into a heap slot record (rules 21, 22)", &at);
    if (ci) {
      int64_t off = base + int64_t(j * size);
      Value *p = off ? B.CreateInBoundsGEP(Type::getInt8Ty(C), rv.v, ConstantInt::get(i64(ctx), off)) : rv.v;
      return Operand{B.CreateLoad(cellTy, p), false};
    }
    Fat h = f;
    h.cell = 1;
    h.idx = Operand{B.CreateAdd(B.CreateMul(f.idx.v, ConstantInt::get(i64(ctx), f.cell)),
                                ConstantInt::get(i64(ctx), j * size)),
                    false};
    return hostArm(ctx, r, h, cellTy, const_cast<Instruction &>(at), /*check=*/true, Align(1));
  };
  SmallVector<Operand, 8> out;
  for (uint64_t j = 0; j < n; ++j) {
    std::optional<Operand> acc;
    for (unsigned i = 0; i < roots.size(); ++i) {
      if (j * size >= bounds[i])
        continue;
      Operand v = cellOf(roots[i], j);
      if (!acc) {
        acc = v;
        continue;
      }
      Operand c = flagOf(roots[i]);
      if (!c.handle)
        internalError("fatptr: a tag compare of a rail tag that is classical", &at);
      std::string shape = std::string(v.handle ? "h" : "l") + (acc->handle ? "h" : "l");
      acc = Operand{tmpl(ctx, "select", w, {c, v, *acc}, shape == "hh" ? "" : shape), true};
    }
    if (!acc)
      internalError("fatptr: a source cell below the length's bound that no root reaches", &at);
    out.push_back(*acc);
  }
  return out;
}

std::pair<Operand, Operand> resultFields(LoweringContext &ctx, const ReturnInst &ret) {
  const Value *rv = ret.getReturnValue();
  Fat f = derive(ctx, rv, /*emit=*/false);
  for (const Value *r : f.roots) {
    if (isa<ConstantPointerNull>(r))
      continue;
    const Bound *b = boundOf(ctx, r);
    if (!b)
      unimplemented("fatptr: a clone's fat-pointer result into an object of its own (a local, a global: rule 21 "
                    "object table across the call)",
                    &ret);
    if (f.cell && f.cell != b->cell)
      unimplemented("fatptr: a clone's fat-pointer result at another cell size than its triple formal's", &ret);
  }
  return storedFields(ctx, rv);
}

uint64_t storedCell(LoweringContext &ctx, const Value *ptr) { return derive(ctx, ptr, /*emit=*/false).cell; }

Operand addressOf(LoweringContext &ctx, const Value *ptr) {
  Fat f = derive(ctx, ptr, /*emit=*/true);
  if (f.trips)
    unimplemented("fatptr: the address of a pointer to K-loop trip objects (R1)", ptr);
  Bases cache;
  Operand base = baseOf(ctx, f, cache);
  return address(ctx, f, cache, base);
}

SmallVector<const Value *, 4> rootsOf(LoweringContext &ctx, const Value *ptr) {
  Fat f = derive(ctx, ptr, /*emit=*/false);
  SmallVector<const Value *, 4> out;
  for (const Value *r : f.roots)
    if (mayName(ctx, f, r) && !isa<ConstantPointerNull>(r))
      out.push_back(r);
  return out;
}

std::optional<int64_t> constantByteOffset(LoweringContext &ctx, const Value *ptr) {
  Fat f = derive(ctx, ptr, /*emit=*/false);
  auto *ci = f.idx.handle ? nullptr : dyn_cast<ConstantInt>(f.idx.v);
  if (!ci)
    return std::nullopt;
  return ci->isZero() ? 0 : ci->getSExtValue() * int64_t(f.cell);
}

Value *boundSlotObject(LoweringContext &ctx, const Argument &A) {
  Bound *b = boundOf(ctx, &A);
  return b && b->pointee == ObjClass::Slot ? b->object : nullptr;
}

std::pair<Operand, Operand> storedFields(LoweringContext &ctx, const Value *ptr) {
  Fat f = derive(ctx, ptr, /*emit=*/true);
  if (f.trips)
    unimplemented("fatptr: a pointer to K-loop trip objects stored into memory (R1)", ptr);
  Operand idx = f.idx;
  if (!idx.handle) {
    idx = Operand{ctx.B().CreateTrunc(idx.v, i32(ctx)), false};
  } else if (f.idxBits < 32) {
    idx = Operand{tmpl(ctx, f.idxSext ? "sext" : "zext", intRail(f.idxBits), {idx}, "", "", intRail(32)), true};
  } else if (f.idxBits > 32) {
    idx = Operand{tmpl(ctx, "trunc", intRail(f.idxBits), {idx}, "", "", intRail(32)), true};
  }
  return {f.tag, idx};
}

// Rule 21: a store through a fat pointer over QRAM objects is the _controlled store into each object
// under its guard (tag == k, and the current flag), the value one handle shared by every object (a
// classical value is one seed, rule 7; 84).
void lowerStore(LoweringContext &ctx, StoreInst &st) {
  Fat f = derive(ctx, st.getPointerOperand(), /*emit=*/true);
  if (f.trips)
    unimplemented("fatptr: a store through a pointer to K-loop trip objects after the loop (R1)", &st);
  if (f.roots.size() == 1)
    if (Bound *b = boundOf(ctx, f.roots[0]); b && b->table) {
      // M7 (129): each table object's cell takes w_k = (tag == k) ? v : old_k, a fresh rail left there for the
      // caller (Role::Result: the clone does not clean the old cells, its caller does by rule 6, rule 18).
      Type *ty = st.getValueOperand()->getType();
      checkTableAccess(ctx, *b, f, ty, st);
      Operand v = ctx.operand(st.getValueOperand());
      for (unsigned k = 0; k < b->table; ++k) {
        Value *cell = nullptr;
        Value *old = tableCell(ctx, *b, f, k, cell);
        // Under a quantum predicate the guard is tag == k and the flag (rule 9, 84).
        Operand eq{guardTag(ctx, f, k + 1, ctx.currentFlag()), true};
        Value *w = tmpl(ctx, "select", railTypeOf(ty), {eq, v, Operand{old, true}}, v.handle ? "" : "lh");
        ctx.unc().setRole(ctx.unc().idOf(w), Role::Result);
        ctx.B().CreateAlignedStore(w, cell, Align(4));
      }
      return;
    }
  if (f.roots.size() == 1)
    if (Bound *b = boundOf(ctx, f.roots[0]); b && b->pointee == ObjClass::Slot && !b->tag.handle && !f.idx.handle) {
      // Rules 18, 20, 21 (cq-1c5j): a classical (tag, idx) into the caller's slot object names one handle cell; the
      // spine bound the formal to that cell's address, and a store through it is the slot store of a raw slot
      // formal (31): the rail replaces the cell, under a quantum predicate a select into a fresh rail, the
      // caller cleaning the old cell after the call (rule 18).
      mem::lowerSlotStore(ctx, st);
      return;
    }
  Value *val = st.getValueOperand();
  Type *ty = val->getType();
  if (!ty->isIntegerTy() && !ty->isFloatingPointTy())
    unimplemented("fatptr: a store of a pointer or aggregate through a fat pointer (rule 21)", &st);
  Value *flag = ctx.currentFlag();
  // CR rule 6 (129): a read-modify-write through the same pointer cleans each slot object's old cell.
  std::optional<CellUpdate> u = ty->isIntegerTy() ? fatStoreUpdate(ctx, st) : std::nullopt;
  Operand v = ctx.operand(val);
  bool anySlot = any_of(f.roots, [&](const Value *r) { return mayName(ctx, f, r) && isSlotRoot(ctx, r); });
  if (anySlot) {
    // Rules 9, 20, 21 (129): a store through a fat pointer into local slot objects at a classical constant cell:
    // each object's cell takes w_k = guard_k ? v : old_k into a fresh rail (guard_k: tag == k and the current
    // flag), the cell holding a classical value first materialised as its seed (rule 20, rule 7). A cell outside
    // an object is never written in the domain (the guard is false there) and is skipped.
    auto *ci = f.idx.handle ? nullptr : dyn_cast<ConstantInt>(f.idx.v);
    if (!ci)
      unimplemented("fatptr: a store through a fat pointer over slot objects at a run-time or quantum cell index "
                    "(mem-slots: a per-object dynamic slot store)",
                    &st);
    int64_t byte = ci->isZero() ? 0 : ci->getSExtValue() * int64_t(f.cell);
    uint64_t size = ctx.M.getDataLayout().getTypeStoreSize(ty).getFixedValue();
    for (const Value *r : f.roots) {
      if (!mayName(ctx, f, r) || !isSlotRoot(ctx, r))
        continue;
      std::optional<uint64_t> n = objectBytes(ctx, r);
      if (!n)
        internalError("fatptr: a local slot object with no static size", r);
      if (byte < 0 || uint64_t(byte) + size > *n)
        continue;
      Value *g = guardOf(ctx, f, r, flag);
      Operand old = mem::readFatCell(ctx, r, ty, byte, st);
      if (!g) {
        // A classical tag naming this object outside any quantum predicate: the cell takes v itself.
        Value *w = v.handle ? v.v : nullptr;
        if (!w) {
          CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(ty)}, {v.v});
          ctx.unc().recordSeed(seed);
          w = seed;
        }
        mem::writeFatCell(ctx, r, ty, byte, Operand{w, true}, st);
        continue;
      }
      if (!old.handle) {
        CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(ty)}, {old.v});
        ctx.unc().recordSeed(seed);
        old = Operand{seed, true};
      }
      bool rmw = u && byte == 0 && !flag && f.tag.handle;
      if (rmw) {
        auto arm = slotArms()[&ctx.out()].find({u->load, r});
        if (arm == slotArms()[&ctx.out()].end() || arm->second != old.v)
          rmw = false;   // the update's load read another rail: no rule 6 clean-up of this cell
      }
      Value *w = tmpl(ctx, "select", railTypeOf(ty), {Operand{g, true}, v, old}, v.handle ? "" : "lh");
      mem::writeFatCell(ctx, r, ty, byte, Operand{w, true}, st);
      if (rmw)
        cleanOldCell(ctx, old.v, g, w, *u, ctx.operand(u->z), r, st);
    }
  }
  if (!v.handle && any_of(f.roots, [&](const Value *r) {
        return mayName(ctx, f, r) && !isa<ConstantPointerNull>(r) && !isSlotRoot(ctx, r);
      })) {
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(ty)}, {v.v});
    ctx.unc().recordSeed(seed);
    v = Operand{seed, true};
  }
  for (const Value *r : f.roots) {
    if (!mayName(ctx, f, r) || isa<ConstantPointerNull>(r) || isSlotRoot(ctx, r))
      continue;
    if (const Bound *b = boundOf(ctx, r)) {
      if (b->pointee != ObjClass::Qram)
        unimplemented("fatptr: a store through a slot or host triple formal (rule 21)", &st);
      // M2b: the store is the clone's copy-out, emitted after its body's uncompute. Its cell must still
      // be addressable there: the formal's own idx rail, a classical index, or a computed index rail mem-qram
      // copies out with the store (M2's index rail).
      mem::deferFormalStore(ctx, r, f.idx, f.idxBits, ty, v.v, flag, st);
      continue;
    }
    if (!mem::isQramRoot(ctx, r))
      unimplemented("fatptr: a store through a fat pointer into classical host memory (taint classifies memory a "
                    "quantum store may reach as a slot or QRAM)",
                    &st);
    Fat g = f;
    if (g.cell && g.cell != mem::qramElemBytes(ctx, r, st) && !fitCells(ctx, g, mem::qramElemBytes(ctx, r, st), st.getAlign()))
      unimplemented("fatptr: a fat pointer whose cells do not convert to its QRAM object's element (rule 21)", &st);
    mem::qramStoreAt(ctx, r, g.idx, ty, v.v, guardOf(ctx, f, r, flag), st);
  }
}

Value *lowerCompare(LoweringContext &ctx, ICmpInst &cmp) {
  Fat a = derive(ctx, cmp.getOperand(0), /*emit=*/true);
  Fat b = derive(ctx, cmp.getOperand(1), /*emit=*/true);
  CmpInst::Predicate p = cmp.getPredicate();
  bool eq = p == CmpInst::ICMP_EQ, ne = p == CmpInst::ICMP_NE;
  bool sameCell = a.cell == 0 || b.cell == 0 || a.cell == b.cell;
  if (a.trips || b.trips) {
    // R1: trip objects are distinct allocations, non-null in the domain; the roots must be null.
    if (!(eq || ne) || (a.trips && b.trips))
      unimplemented("fatptr: a compare through a pointer to K-loop trip objects other than eq/ne with null (R1)", &cmp);
    for (const Fat *x : {&a, &b})
      for (const Value *r : x->roots)
        if (!undefinedNull(ctx, r))
          unimplemented("fatptr: a compare through a pointer to K-loop trip objects with a root other than null (R1)",
                        &cmp);
  }
  // p == NULL (85): over NULL and distinct allocations of this function, a pointer of tag 0 is NULL itself
  // unless an offset moved it (nullMoved), and no allocation's address is NULL: the tag compare decides.
  auto isNull = [](const Value *v) { return isa<ConstantPointerNull>(v->stripPointerCasts()); };
  if ((eq || ne) && (isNull(cmp.getOperand(0)) || isNull(cmp.getOperand(1))) && !a.nullMoved && !b.nullMoved &&
      distinctLocalAllocas(ctx, a, b))
    return asRail(ctx, tagEqual(ctx, p, a, b));
  if ((eq || ne) && sameCell && (a.trips || b.trips || distinctLocalAllocas(ctx, a, b))) {
    // Distinct allocations of this function: same object (tag), then same cell (idx); ne is
    // tag != tag' or idx != idx'. A classical term that decides alone is folded.
    bool decides = ne;   // the term value that decides the result alone: false for eq, true for ne
    auto decisive = [&](const Operand &o) {
      auto *ci = o.handle ? nullptr : dyn_cast<ConstantInt>(o.v);
      return ci && ci->isOne() == decides;
    };
    auto neutral = [&](const Operand &o) {
      auto *ci = o.handle ? nullptr : dyn_cast<ConstantInt>(o.v);
      return ci && ci->isOne() != decides;
    };
    Operand t = tagEqual(ctx, p, a, b);
    if (decisive(t))
      return seedI1(ctx, t.v);
    Operand i = idxEqual(ctx, p, a, b);
    if (decisive(i))
      return seedI1(ctx, i.v);
    if (neutral(t))
      return asRail(ctx, i);
    if (neutral(i))
      return asRail(ctx, t);
    return asRail(ctx, commutative(ctx, eq ? "and" : "or", 1, t, i));
  }
  Bases cache;
  Operand x = address(ctx, a, cache), y = address(ctx, b, cache);
  return asRail(ctx, icmp(ctx, p, 64, x, y));
}

// Rule 21 (89, 107): ptrtoint of a fat pointer is its flat address base[tag] + size * idx (base[tag] the
// select chain over the roots' host addresses, as a compare builds it), at the integer's width (a narrower
// integer is the address truncated, as LLVM does).
void lowerPtrToInt(LoweringContext &ctx, Instruction &I) {
  auto *pi = dyn_cast<PtrToIntInst>(&I);
  if (!pi)
    internalError("fatptr: lowerPtrToInt of a non-ptrtoint", &I);
  unsigned w = I.getType()->getIntegerBitWidth();
  Flat fl;
  fl.f = derive(ctx, pi->getPointerOperand(), /*emit=*/true);
  Bases cache;
  fl.base = baseOf(ctx, fl.f, cache);
  Operand a = address(ctx, fl.f, cache, fl.base);
  // At the integer's width, as LLVM does: a narrower integer is the address truncated, a wider one zero-extended.
  if (w < 64)
    a = a.handle ? Operand{tmpl(ctx, "trunc", intRail(64), {a}, "", "", intRail(w)), true}
                 : Operand{ctx.B().CreateTrunc(a.v, I.getType()), false};
  else if (w > 64)
    a = a.handle ? Operand{tmpl(ctx, "zext", intRail(64), {a}, "", "", intRail(w)), true}
                 : Operand{ctx.B().CreateZExt(a.v, I.getType()), false};
  if (!flats()[&ctx.out()].try_emplace(&I, fl).second)
    internalError("fatptr: a ptrtoint lowered twice", &I);
  ctx.bindFields(&I, {a});
}

// Rule 21: inttoptr of an integer of unknown origin, decoded by range tests over the candidate objects
// (candidateRoots): base <= addr <= base + size·n, one past the end included. An address that is one object's
// end and another's start names the object starting there (ruling 2026-11-02, cq-0w0g): the one-past tests are
// applied first, the interior tests (base <= addr < end) after them, so an interior match wins. No match is NULL
// (tag 0, base 0). idx = (addr - base[tag]) / size, an i64 rail (exact for an in-domain address, which lies on a
// cell of its object; the cell is the byte unless every access through the pointer has one size).
void lowerRangeDecode(LoweringContext &ctx, const IntToPtrInst &I) {
  Fat f = deriveIntToPtr(ctx, I, /*emit=*/false);
  Operand u = ctx.operand(I.getOperand(0));
  if (unsigned uw = I.getOperand(0)->getType()->getIntegerBitWidth(); uw != 64) {
    StringRef op = uw < 64 ? "zext" : "trunc";
    u = u.handle ? Operand{tmpl(ctx, op, intRail(uw), {u}, "", "", intRail(64)), true}
                 : Operand{ctx.B().CreateZExtOrTrunc(u.v, i64(ctx)), false};
  }
  if (!u.handle) {
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, intRail(64)}, {u.v});
    ctx.unc().recordSeed(seed);
    u = Operand{seed, true};
  }
  IRBuilder<> &B = ctx.B();
  Bases cache;
  struct Cand {
    const Value *r;
    Value *base, *end;
  };
  SmallVector<Cand, 4> cs;
  for (const Value *r : f.roots) {
    if (isa<ConstantPointerNull>(r))
      continue;
    Value *ext = hostExtent(ctx, r);
    Value *base = rootBase(ctx, r, cache);
    cs.push_back({r, base, ext ? B.CreateAdd(base, ext) : nullptr});
  }
  Operand tag{ConstantInt::get(i32(ctx), 0), false};
  auto pick = [&](Operand cond, const Value *r) {
    tag = select(ctx, 32, cond, Operand{ConstantInt::get(i32(ctx), rootNumber(ctx, r)), false}, tag);
  };
  // A candidate with no extent in the module (rule 20, n = 0) holds every address from its base on; among
  // several such, the nearest base at or below the address: candidate i is picked when addr >= base_i and addr
  // lies below every other unbounded base above base_i (a classical bound per pair: base_j when base_j > base_i,
  // else no bound). Known extents are tested after them and win.
  SmallVector<const Cand *, 4> open;
  for (const Cand &c : cs)
    if (!c.end)
      open.push_back(&c);
  for (size_t i = 0; i < open.size(); ++i) {
    Operand cond = icmp(ctx, CmpInst::ICMP_UGE, 64, u, Operand{open[i]->base, false});
    for (size_t j = 0; j < open.size(); ++j)
      if (j != i) {
        Value *bound = B.CreateSelect(B.CreateICmpUGT(open[j]->base, open[i]->base), open[j]->base,
                                      ConstantInt::getAllOnesValue(i64(ctx)));
        cond = commutative(ctx, "and", 1, cond, icmp(ctx, CmpInst::ICMP_ULT, 64, u, Operand{bound, false}));
      }
    pick(cond, open[i]->r);
  }
  for (const Cand &c : cs)
    if (c.end)
      pick(icmp(ctx, CmpInst::ICMP_EQ, 64, u, Operand{c.end, false}), c.r);
  for (const Cand &c : cs) {
    if (!c.end)
      continue;
    Operand ge = icmp(ctx, CmpInst::ICMP_UGE, 64, u, Operand{c.base, false});
    Operand lt = icmp(ctx, CmpInst::ICMP_ULT, 64, u, Operand{c.end, false});
    pick(commutative(ctx, "and", 1, ge, lt), c.r);
  }
  Fat g = f;
  g.tag = tag;
  Operand base = baseOf(ctx, g, cache);
  Operand off = Operand{tmpl(ctx, "sub", intRail(64), {u, base}, base.handle ? "" : "hl"), true};
  if (f.cell != 1) {
    bool p2 = isPowerOf2_64(f.cell);
    off = Operand{tmpl(ctx, p2 ? "lshr" : "udiv", intRail(64),
                       {off, Operand{ConstantInt::get(i64(ctx), p2 ? Log2_64(f.cell) : f.cell), false}}, "hl"),
                  true};
  }
  ctx.bindFields(&I, {tag, off});
}

// Rule 21 (89, 107): inttoptr of an integer derived from ptrtoint(p) keeps p's provenance: tag = p's tag (the
// same rail), idx = (addr - base[tag]) / size in cells of the access through the result (sub, lshr by log2
// size, trunc to the logical i32 index rail; one past the end included). base[tag] is the one that ptrtoint
// built (or, for a classical ptrtoint, the root's host address): no range test, so nothing depends on where
// the host placed the objects. Only an integer of unknown origin would be decoded by range tests
// (unimplemented). The result is bound as its two fields (tag, idx).
void lowerIntToPtr(LoweringContext &ctx, Instruction &I) {
  auto *ip = dyn_cast<IntToPtrInst>(&I);
  if (!ip)
    internalError("fatptr: lowerIntToPtr of a non-inttoptr", &I);
  const PtrToIntInst *pi = derivedFrom(I.getOperand(0));
  if (!pi) {
    lowerRangeDecode(ctx, *ip);
    return;
  }
  Fat shape = deriveIntToPtr(ctx, *ip, /*emit=*/false);
  Operand tag{nullptr, false}, base{nullptr, false};
  auto &fm = flats()[&ctx.out()];
  if (auto it = fm.find(pi); it != fm.end()) {
    tag = it->second.f.tag;
    base = it->second.base;
  } else {
    // A classical ptrtoint (the spine copied it): p is one root, its tag a constant.
    Fat f = derive(ctx, pi->getPointerOperand(), /*emit=*/true);
    if (f.tag.handle)
      internalError("fatptr: a ptrtoint of a quantum-tag pointer that fatptr did not lower", pi);
    Bases cache;
    tag = f.tag;
    base = baseOf(ctx, f, cache);
  }
  if (tag.handle != shape.tag.handle)
    internalError("fatptr: an inttoptr whose tag differs in kind from its ptrtoint's", &I);
  Operand u = ctx.operand(I.getOperand(0));
  // The integer at the address width, as LLVM's inttoptr: a narrower one zero-extended, a wider one truncated.
  if (unsigned uw = I.getOperand(0)->getType()->getIntegerBitWidth(); uw != 64) {
    StringRef op = uw < 64 ? "zext" : "trunc";
    u = u.handle ? Operand{tmpl(ctx, op, intRail(uw), {u}, "", "", intRail(64)), true}
                 : Operand{ctx.B().CreateZExtOrTrunc(u.v, i64(ctx)), false};
  }
  Operand off;
  if (!u.handle && !base.handle)
    off = Operand{ctx.B().CreateSub(u.v, base.v), false};
  else
    off = Operand{tmpl(ctx, "sub", intRail(64), {u, base}, u.handle && base.handle ? "" : u.handle ? "hl" : "lh"),
                  true};
  uint64_t cell = shape.cell;
  Operand idx = off;
  if (cell != 1) {
    // A root inside its object (cq-b244): the difference may be negative, a signed division (exact: an
    // in-domain address lies on a cell of the root).
    bool sx = shape.idxSext;
    Constant *k = ConstantInt::get(i64(ctx), isPowerOf2_64(cell) ? Log2_64(cell) : cell);
    StringRef op = isPowerOf2_64(cell) ? (sx ? "ashr" : "lshr") : (sx ? "sdiv" : "udiv");
    idx = idx.handle ? Operand{tmpl(ctx, op, intRail(64), {idx, Operand{k, false}}, "hl"), true}
                     : Operand{isPowerOf2_64(cell) ? (sx ? ctx.B().CreateAShr(idx.v, k) : ctx.B().CreateLShr(idx.v, k))
                                                   : (sx ? ctx.B().CreateSDiv(idx.v, k) : ctx.B().CreateUDiv(idx.v, k)),
                               false};
  }
  if (idx.handle && shape.idxBits < 64)
    idx = Operand{tmpl(ctx, "trunc", intRail(64), {idx}, "", "", intRail(shape.idxBits)), true};
  ctx.bindFields(&I, {tag, idx});
}

// The cell size every lifted clone a pointer is passed to as a T4 triple accesses through its formal
// must be the caller's cell size cellBytes (and, onto a QRAM, its cell type): the triple's idx and cell
// count are in the caller's cells.
// The cell size of a host-pointee triple formal (85): the scale of its GEPs' variable terms and the size of
// its accesses, through GEPs, casts, selects and phis; a compare or return of a derived pointer is no
// access. Two sizes, an escape (a store of the pointer, a call) or none at all are unimplemented.
uint64_t hostFormalCellBytes(const Argument &A) {
  const DataLayout &DL = A.getParent()->getParent()->getDataLayout();
  uint64_t cell = 0;
  auto see = [&](uint64_t c, const Value *at) {
    if (c == 0 || (cell && cell != c))
      unimplemented("fatptr: a host triple formal used at two cell sizes (a bit view, 63)", at);
    cell = c;
  };
  SmallPtrSet<const Value *, 16> seen;
  SmallVector<const Value *, 8> work{&A};
  while (!work.empty()) {
    const Value *v = work.pop_back_val();
    if (!seen.insert(v).second)
      continue;
    for (const Use &u : v->uses()) {
      const User *U = u.getUser();
      if (auto *g = dyn_cast<GEPOperator>(U); g && g->getPointerOperand() == v) {
        MapVector<Value *, APInt> vars;
        APInt cst(64, 0);
        if (!g->collectOffset(DL, 64, vars, cst))
          internalError("fatptr: a GEP over a scalable vector type on x86-64", g);
        for (auto &[x, scale] : vars)
          see(scale.getZExtValue(), g);
        work.push_back(g);
      } else if (isa<BitCastOperator>(U) || isa<SelectInst>(U) || isa<PHINode>(U)) {
        work.push_back(U);
      } else if (auto *ld = dyn_cast<LoadInst>(U)) {
        see(DL.getTypeAllocSize(ld->getType()).getFixedValue(), ld);
      } else if (auto *st = dyn_cast<StoreInst>(U); st && st->getPointerOperand() == v) {
        see(DL.getTypeAllocSize(st->getValueOperand()->getType()).getFixedValue(), st);
      } else if (isa<ReturnInst>(U) || isa<ICmpInst>(U)) {
        continue;
      } else {
        unimplemented("fatptr: a host triple formal whose pointer escapes (rule 21)", U);
      }
    }
  }
  if (!cell)
    unimplemented("fatptr: a host triple formal its clone never indexes or accesses (its cells are the caller's)", &A);
  return cell;
}

void checkCalleeCells(LoweringContext &ctx, const Value *ptr, uint64_t cellBytes, Type *qramCellTy) {
  const DataLayout &DL = ctx.M.getDataLayout();
  for (const Use &u : ptr->uses()) {
    auto *CB = dyn_cast<CallBase>(u.getUser());
    if (!CB || !CB->isArgOperand(&u) || CB->getFunction() != ctx.S.F)
      continue;
    const Specialization *cs = ctx.T.calleeSpecialization(*CB, ctx.S);
    const Function *G = CB->getCalledFunction();
    if (!cs || cs->isEntry() || !G || cs->F != G || G->isDeclaration())
      continue;
    unsigned argNo = CB->getArgOperandNo(&u);
    if (argNo >= G->arg_size() || ctx.T.pointerFormal(*cs, argNo).abi == PtrAbi::Raw)
      continue;
    PtrFormal pf = ctx.T.pointerFormal(*cs, argNo);
    if (pf.pointee == ObjClass::Classical) {
      if (hostFormalCellBytes(*G->getArg(argNo)) != cellBytes)
        unimplemented("fatptr: a clone indexing a rule 21 triple formal at another cell size than the caller's "
                      "object (a bit view, 63)",
                      CB);
      continue;
    }
    Type *t = mem::formalCellType(*G->getArg(argNo));
    if (DL.getTypeAllocSize(t).getFixedValue() != cellBytes || (qramCellTy && t != qramCellTy))
      unimplemented("fatptr: a clone accessing a rule 21 triple formal at another cell type than the caller's "
                    "object (a bit view, 63)",
                    CB);
  }
}

// Rule 21 at a clone boundary (CR §1.4; 190, 191). A pointer into ONE QRAM object crosses as (bus, tag,
// idx): the object's bus handle, its i32 tag (the root number; classical for a single object) and its i32
// cell index (a rail or a classical value, as storedFields); cellCount is null (a QRAM's extent is its
// bus). A classical-tag, classical-idx pointer into ONE slot or host object (a local or global plus
// classical GEPs) crosses as (base, tag, idx, cell count): the object's new-IR base (a slot's handle
// cells, a host object's own address), its root number, its cell index and its cell count (mem-slots'
// cells). Several objects (an object table), a quantum tag or idx into a slot or host object, and a
// constant pointer into a QRAM are unimplemented.
namespace {
std::map<const CallInst *, std::vector<std::function<void()>>> &pendingTableCleanups() {
  static std::map<const CallInst *, std::vector<std::function<void()>>> m;
  return m;
}
} // namespace

bool slotTableActual(LoweringContext &ctx, const Value *ptr) {
  SmallVector<const Value *, 4> rs;
  return ctx.T.isFatPointer(ptr, ctx.S) && slotSelectRoots(ctx, ptr, rs);
}

bool writesSlotCell(LoweringContext &ctx, const Instruction &X, const Value *root, int64_t byte, uint64_t size) {
  const DataLayout &DL = ctx.M.getDataLayout();
  SmallVector<const Value *, 4> rs;
  if (auto *S = dyn_cast<StoreInst>(&X)) {
    if (!ctx.T.isFatPointer(S->getPointerOperand(), ctx.S) || !slotSelectRoots(ctx, S->getPointerOperand(), rs) ||
        !is_contained(rs, root))
      return false;
    return byte == 0 && size == DL.getTypeStoreSize(S->getValueOperand()->getType()).getFixedValue();
  }
  auto *CB = dyn_cast<CallBase>(&X);
  const Function *G = CB ? CB->getCalledFunction() : nullptr;
  if (!G || G->isDeclaration() || isa<IntrinsicInst>(CB))
    return false;
  for (unsigned i = 0; i < CB->arg_size(); ++i) {
    const Value *a = CB->getArgOperand(i);
    rs.clear();
    if (!a->getType()->isPointerTy() || !ctx.T.isFatPointer(a, ctx.S) || !slotSelectRoots(ctx, a, rs) ||
        !is_contained(rs, root))
      continue;
    const Specialization *cs = ctx.T.calleeSpecialization(*CB, ctx.S);
    std::optional<CellUpdate> u = calleeCellUpdate(*G, i);
    if (cs && !cs->isEntry() && u && u->z && byte == 0 && size == DL.getTypeStoreSize(u->ty).getFixedValue())
      return true;
  }
  return false;
}

SmallVector<Value *, 4> afterSlotTableCall(LoweringContext &ctx, const CallBase &orig, unsigned argNo,
                                           const Specialization &callee, CallInst *fwd) {
  const Value *ptr = orig.getArgOperand(argNo);
  Fat f = derive(ctx, ptr, /*emit=*/true);
  SmallVector<const Value *, 4> rs = slotRootsOf(ctx, f, ptr, orig);
  std::optional<CellUpdate> u = calleeCellUpdate(*callee.F, argNo);
  if (!u)
    unimplemented("fatptr: a slot object table passed to a clone that accesses it other than by one load and at "
                  "most one read-modify-write store (M7)",
                  &orig);
  if (ctx.T.pointerFormal(callee, argNo).digits != 2 + rs.size())
    internalError("fatptr: a slot object table formal whose digits do not count its objects", &orig);
  SmallVector<Value *, 4> out;
  if (!u->z) {
    // Loads only: the clone reads the cells (U4), it writes none.
    for (const Value *r : rs) {
      Operand old = mem::readFatCell(ctx, r, u->ty, 0, const_cast<CallBase &>(orig));
      if (!old.handle)
        internalError("fatptr: a slot object table cell holding a classical value at the call", &orig);
      ctx.unc().noteUse(ctx.unc().idOf(old.v), fwd);
      ctx.unc().noteCallReads(fwd, {ctx.unc().idOf(old.v)});
    }
    return out;
  }
  // Rule 6 on the old cells consumes them, so the reloaded cells must never be undone by the call's twin: every
  // load of each object the call reaches is measured (rule 2: kept). Otherwise the twin (unbuilt) would need them.
  {
    for (const Value *r : rs) {
      bool any = false;
      for (const User *us : r->users()) {
        auto *L = dyn_cast<LoadInst>(us);
        if (!L || !isPotentiallyReachable(&orig, L))
          continue;
        any = true;
        bool measured = all_of(L->users(), [](const User *m) {
          auto *CB = dyn_cast<CallBase>(m);
          return CB && CB->getCalledFunction() && CB->getCalledFunction()->getName().starts_with("cq_measure");
        });
        if (!measured)
          unimplemented("fatptr: a slot object table call whose objects' cells are read after it other than by "
                        "cq_measure (the call's twin, M7)",
                        L);
      }
      if (!any)
        unimplemented("fatptr: a slot object table call whose objects' cells are never measured after it (the "
                      "call's twin, M7)",
                      &orig);
    }
  }
  // The clone left n_k = (tag == k) ? U(old_k, z) : old_k in each cell (its stores, Role::Result there): the
  // caller reloads them (the call's slot results, undone together by a twin, U2) and cleans each dead old_k by
  // rule 6, as after its own read-modify-write (rule 18: only the caller knows the old cells are dead).
  SmallVector<Value *, 4> olds;
  for (const Value *r : rs) {
    Operand old = mem::readFatCell(ctx, r, u->ty, 0, const_cast<CallBase &>(orig));
    olds.push_back(old.v);
    out.push_back(mem::reloadFatCell(ctx, r, u->ty, 0, orig, fwd));
  }
  // The clean-ups read the reloaded cells, which recordCall registers: finishSlotTableCall emits them.
  // Under a quantum predicate the clone (its _ctl form, rule 18) wrote under tag == k and the predicate: the
  // clean-up's guard is the same conjunction.
  Value *callFlag = ctx.currentFlag();
  pendingTableCleanups()[fwd].push_back([&ctx, &orig, f, rs, olds, out, u = *u, callFlag]() {
    for (unsigned k = 0; k < rs.size(); ++k) {
      Value *g = guardTag(ctx, f, rootNumber(ctx, rs[k]), callFlag);
      cleanOldCell(ctx, olds[k], g, out[k], u, Operand{const_cast<Value *>(u.z), false}, rs[k], orig);
    }
  });
  return out;
}

void finishSlotTableCall(LoweringContext &ctx, CallInst *fwd) {
  auto it = pendingTableCleanups().find(fwd);
  if (it == pendingTableCleanups().end())
    return;
  auto fns = std::move(it->second);
  pendingTableCleanups().erase(it);
  for (auto &fn : fns)
    fn();
  (void)ctx;
}

Triple passAcrossCall(LoweringContext &ctx, const Value *ptr) {
  if (slotTableActual(ctx, ptr)) {
    // M7 (129): the OBJECT TABLE of the pointer's slot objects, object k (tag k) at table[k - 1], each its
    // handle cells' base; the tag rail; idx the classical cell 0; the common cell count.
    const Instruction *at = dyn_cast<Instruction>(ptr);
    Fat f = derive(ctx, ptr, /*emit=*/true);
    SmallVector<const Value *, 4> rs = slotRootsOf(ctx, f, ptr, *at);
    const DataLayout &DL = ctx.M.getDataLayout();
    LLVMContext &C = ctx.M.getContext();
    uint64_t bytes = 0;
    for (unsigned k = 0; k < rs.size(); ++k) {
      if (rootNumber(ctx, rs[k]) != k + 1)
        unimplemented("fatptr: an object table across a call over slot objects whose tags are not 1..n (M7)", at);
      std::optional<TypeSize> sz = cast<AllocaInst>(rs[k])->getAllocationSize(DL);
      if (!sz || sz->isScalable() || (bytes && bytes != sz->getFixedValue()))
        unimplemented("fatptr: an object table across a call over slot objects of different sizes (M7)", at);
      bytes = sz->getFixedValue();
    }
    IRBuilder<> EB(&ctx.out().getEntryBlock(), ctx.out().getEntryBlock().getFirstInsertionPt());
    Type *ptrTy = PointerType::getUnqual(C);
    AllocaInst *table = EB.CreateAlloca(ArrayType::get(ptrTy, rs.size()));
    table->setAlignment(Align(8));
    IRBuilder<> &B = ctx.B();
    for (unsigned k = 0; k < rs.size(); ++k) {
      Operand base = ctx.operand(rs[k]);
      if (base.handle)
        internalError("fatptr: a slot object bound to a rail", rs[k]);
      B.CreateAlignedStore(base.v, k ? B.CreateConstInBoundsGEP1_64(ptrTy, table, k) : table, Align(8));
    }
    // The cell count in cells of the access type the callee uses (its one load, calleeCellUpdate).
    uint64_t cell = 0;
    for (const User *u : ptr->users())
      if (auto *CB = dyn_cast<CallBase>(u); CB && CB->getCalledFunction())
        for (unsigned i = 0; i < CB->arg_size(); ++i)
          if (CB->getArgOperand(i) == ptr)
            if (auto cu = calleeCellUpdate(*CB->getCalledFunction(), i))
              cell = DL.getTypeAllocSize(cu->ty).getFixedValue();
    if (!cell || bytes % cell)
      unimplemented("fatptr: an object table across a call whose callee's cell is not known (M7)", at);
    return Triple{table, f.tag.v, ConstantInt::get(i32(ctx), 0), ConstantInt::get(i32(ctx), bytes / cell)};
  }
  ArrayRef<ObjectId> objs = ctx.T.provenance(ptr, ctx.S);
  bool classical = !isQ(ctx, ptr) && !ctx.T.isFatPointer(ptr, ctx.S);
  if (objs.size() == 1 && ctx.T.classOf(objs.front()) != ObjClass::Qram) {
    const Instruction *at = dyn_cast<Instruction>(ptr);
    if (!at)
      for (const User *u : ptr->users())
        if (auto *I = dyn_cast<Instruction>(u); I && I->getFunction() == ctx.S.F) {
          at = I;
          break;
        }
    if (!at)
      internalError("fatptr: passAcrossCall of a pointer this function does not use", ptr);
    if (!classical)
      unimplemented("fatptr: a quantum pointer into a slot or host object crossing a clone boundary (rule 21 "
                    "object table or guarded cells)",
                    ptr);
    mem::HostTriple h = mem::hostTriple(ctx, ptr, *at);
    checkCalleeCells(ctx, ptr, h.cellBytes, nullptr);
    Operand base = ctx.operand(h.root);
    if (base.handle)
      internalError("fatptr: a slot or host object bound to a rail", h.root);
    crossings()[&ctx.out()][ptr] = Crossed{h.root, h.cellBytes};
    return Triple{base.v, ConstantInt::get(i32(ctx), rootNumber(ctx, h.root)), h.idx, h.cellCount};
  }
  Fat f = derive(ctx, ptr, /*emit=*/false);
  if (f.roots.size() != 1 || !mem::isQramRoot(ctx, f.roots[0]))
    unimplemented("fatptr: a pointer crossing a clone boundary that is not into one QRAM, slot or host object "
                  "(rule 21 object table)",
                  ptr);
  if (boundOf(ctx, f.roots[0]))
    unimplemented("fatptr: a triple formal passed on to another clone (its stores would be the outer clone's, "
                  "rule 18)",
                  ptr);
  const Instruction *at = dyn_cast<Instruction>(ptr);
  if (!at)
    unimplemented("fatptr: a constant pointer into a QRAM crossing a clone boundary", ptr);
  uint64_t E = mem::qramElemBytes(ctx, f.roots[0], *at);
  if (f.cell && f.cell != E)
    unimplemented("fatptr: a pointer into a QRAM crossing a clone boundary whose cell is not the object's element "
                  "(a field or a bit view)",
                  ptr);
  Value *bus = mem::qramBusOf(ctx, f.roots[0], *at);
  checkCalleeCells(ctx, ptr, E, mem::qramCellType(ctx, f.roots[0], *at));
  // A clone's fat-pointer result derived from this triple names the QRAM root in this table (85, rule 21).
  crossings()[&ctx.out()][ptr] = Crossed{f.roots[0], E};
  auto [tag, idx] = storedFields(ctx, ptr);
  return Triple{bus, tag.v, idx.v, nullptr};
}

// P1 (cq-arch 2026-11-01, CR rule 21, §1.4; 190, 191). At a clone's entry, a T4 triple formal is bound
// to the clone's (object, tag, idx[, cellCount]) parameters; lower() of the formal and of every pointer
// derived from it is then the caller's fat pointer (tag, idx), in cells of the clone's access type.
//  - Qram pointee: the object is the caller's bus. The formal is registered with mem-qram as a
//    one-column QRAM over it (loads: QRAM loads at the derived idx; stores: M2b's deferred copy-out).
//    The clone's uses of the formal are checked first (M2's contract, mem::calleeQramStoreCount).
//  - Slot pointee (TripleCount): the object is the caller's handle cells, every cell the clone may
//    reach holding a handle at the call (the formal's cell digits all 1). A load at classical cell j is
//    checked against cellCount and reads the clone's shared |0> seed beyond it (boundSlotLoad); the seed
//    is minted at the clone's entry on the first such load. The formal itself is left unbound: an access that does not go through fatptr (a
//    mem-slots plain load, whose cut trips could read past the object) stops at the unbound formal.
//  - A quantum tag (an object table across the call), a quantum idx into slot cells, a cell count onto a
//    QRAM, and a host-object pointee are unimplemented.
void bindFormal(LoweringContext &ctx, const Argument &formal, Value *object, Operand tag, Operand idx,
                Value *cellCount) {
  const TaintInfo &T = ctx.T;
  const Specialization &S = ctx.S;
  PtrFormal pf = T.pointerFormal(S, formal.getArgNo());
  if (pf.abi == PtrAbi::Raw)
    internalError("fatptr: bindFormal of a raw pointer formal", &formal);
  if ((pf.abi == PtrAbi::TripleCount) != (cellCount != nullptr))
    internalError("fatptr: bindFormal's cell count does not match the formal's T4 ABI", &formal);
  if (tag.handle && pf.pointee != ObjClass::Slot)
    unimplemented("fatptr: a triple formal with a quantum tag (an object table across the call, rule 21)", &formal);
  const DataLayout &DL = ctx.M.getDataLayout();
  Bound b;
  b.object = object;
  b.tag = tag;
  b.cellCount = cellCount;
  b.pointee = pf.pointee;
  if (!idx.v->getType()->isIntegerTy(32))
    internalError("fatptr: a triple formal's idx that is not an i32", &formal);
  b.idx = idx;
  switch (pf.pointee) {
  case ObjClass::Qram:
    // A cell count (the uniform ABI passes it whenever the callee loads through the pointer, rule 21) is unused:
    // a QRAM's extent is its bus, an out-of-range index reads 0 (§2).
    (void)mem::calleeQramStoreCount(T, S);   // M2's contract over the clone's uses of the formal
    b.cellTy = mem::formalCellType(formal);
    mem::registerFormalQram(ctx, formal, object);
    break;
  case ObjClass::Slot: {
    // A rail idx is bound as it is: a load through it would be a quantum-offset load of memory that may hold a
    // handle, which makes the caller's object a QRAM (rule 20), so only non-accessing uses (a compare, a
    // ptrtoint, a return) meet it.
    if (tag.handle) {
      // M7 (129): an object table of slot objects, one cell digit each (the clone reads and writes the one
      // cell idx of each, calleeCellUpdate); they all hold handles at the call.
      std::optional<CellUpdate> u = calleeCellUpdate(*S.F, formal.getArgNo());
      if (!u)
        unimplemented("fatptr: a slot object table formal the clone accesses other than by one load and at most "
                      "one read-modify-write store through the formal in its entry block (M7)",
                      &formal);
      size_t d = 0;
      for (const Argument &A : S.F->args()) {
        if (&A == &formal)
          break;
        d += A.getType()->isPointerTy() ? T.pointerFormal(S, A.getArgNo()).digits : T.fieldMask(&A, S).size();
      }
      if (pf.digits < 4 || d + pf.digits > S.mask.size())
        unimplemented("fatptr: a slot object table formal over fewer than two objects (M7)", &formal);
      for (unsigned k = 2; k < pf.digits; ++k)
        if (S.mask[d + k] != '1')
          unimplemented("fatptr: a slot object table whose cells do not all hold handles at the call (M7)", &formal);
      b.table = pf.digits - 2;
      b.cellTy = u->ty;
      break;
    }
    size_t d = 0;
    for (const Argument &A : S.F->args()) {
      if (&A == &formal)
        break;
      d += A.getType()->isPointerTy() ? T.pointerFormal(S, A.getArgNo()).digits : T.fieldMask(&A, S).size();
    }
    if (pf.digits < 2 || d + pf.digits > S.mask.size())
      internalError("fatptr: a slot triple formal's digits past the clone's mask", &formal);
    // Rule 20: a slot cell is homogeneous: a cell of an object of one scalar type holds a handle on every path,
    // so a digit 0 (no handle written before the call: the clone writes it, 31's y[2] for __rem_pio2) is a
    // handle cell too. A record's cell digit 0 is a classical field (163's per-field kinds) at the record's own
    // layout, which the triple's handle cells do not carry.
    bool uniform = true;
    for (ObjectId o : T.provenance(&formal, S))
      uniform = uniform && T.uniformCells(o);
    for (unsigned k = 2; k < pf.digits; ++k)
      if (S.mask[d + k] != '1' && !uniform)
        unimplemented("fatptr: a slot triple formal into a record whose fields are not all handle cells at the "
                      "call (rule 20 per-field kinds, 163, across a rule 21 triple)",
                      &formal);
    b.cellTy = mem::formalCellType(formal);
    break;
  }
  case ObjClass::Classical:
    // 85: a host object's pointer the clone derives and returns. Its loads and stores stay unimplemented
    // (lowerLoad, lowerStore: a load beyond the cell count, rule 21).
    b.cell = hostFormalCellBytes(formal);
    break;
  }
  if (b.cellTy)
    b.cell = DL.getTypeAllocSize(b.cellTy).getFixedValue();
  if (!boundFormals()[&ctx.out()].try_emplace(&formal, b).second)
    internalError("fatptr: a triple formal bound twice", &formal);
}

// R1 (cq-r7-91, CR rules 14, 20, 21; 91). Trip tags lie past the object table's root numbers.
unsigned reserveTripTags(LoweringContext &ctx, unsigned n) {
  TripState &t = tripStates()[&ctx.out()];
  if (t.next == 0) {
    unsigned roots = 0;
    SmallPtrSet<const Value *, 32> seen;
    auto visit = [&](const Value *v) {
      if (v->getType()->isPointerTy() && seen.insert(v).second)
        ++roots;
    };
    for (const Argument &a : ctx.S.F->args())
      visit(&a);
    for (const BasicBlock &bb : *ctx.S.F)
      for (const Instruction &I : bb) {
        for (const Use &u : I.operands())
          if (isa<Constant>(u.get()) && !isa<BasicBlock>(u.get()))
            visit(u.get());
        visit(&I);
      }
    t.next = roots + 1;
  }
  unsigned first = t.next;
  t.next += n;
  return first;
}

// R2 (cq-z6q1, CR rules 14, 21; 189).
void registerCarried(LoweringContext &ctx, const PHINode &P) {
  carriedPhis()[&ctx.out()].insert(&P);
  (void)derive(ctx, &P, /*emit=*/false);   // its shape: every incoming at the start of its objects
}

Operand carriedTag(LoweringContext &ctx, const Value *ptr) {
  Fat f = derive(ctx, ptr, /*emit=*/true);
  auto *ci = f.idx.handle ? nullptr : dyn_cast<ConstantInt>(f.idx.v);
  if (f.trips || f.nullMoved || !ci || !ci->isZero())
    unimplemented("fatptr: a K-loop's carried pointer value that is not at the start of its objects (a carried "
                  "idx, rule 21)",
                  ptr);
  return f.tag;
}

unsigned rootTag(LoweringContext &ctx, const Value *root) {
  if (!isRoot(ctx, root))
    internalError("fatptr: rootTag of a value that is not a root", root);
  return rootNumber(ctx, root);
}

void bindTripPointer(LoweringContext &ctx, const PHINode &P, Operand tag, ArrayRef<TripObject> objs) {
  if (!tag.handle || !tag.v->getType()->isIntegerTy(32))
    internalError("fatptr: a trip pointer's tag that is not an i32 rail", &P);
  const Value *site = nullptr;
  for (const Value *in : P.incoming_values()) {
    if (isa<ConstantPointerNull>(in))
      continue;
    if (site && site != in)
      internalError("fatptr: a trip pointer phi with two non-null incomings", &P);
    site = in;
  }
  if (!site)
    internalError("fatptr: a trip pointer phi with no trip object", &P);
  TripPtr t;
  t.tag = tag;
  t.objs.assign(objs.begin(), objs.end());
  tripStates()[&ctx.out()].phis[&P] = std::move(t);
}

} // namespace cq::fatptr
