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
//        rail widened by its own extension, then add templates; idx is then an unsigned rail.
//      * a select: the spine calls lower(sel) once, at the select (patch spine-dispatch-ptrselect);
//        lower computes tag and idx there and binds them as the select's two fields. A quantum
//        condition gives tag = select_i32(cond, tag_t, tag_f) (a classical tag when both arms have
//        the same one), idx = the select of the arms' idx (the same classical value stays classical);
//        a classical condition is a classical select of classical fields. Later derivations reaching
//        the select read its fields (its shape is re-derived from the IR without emitting).
//      * anything else quantum (a phi, a loaded pointer (189), a clone parameter (the clone-boundary
//        triple), inttoptr, a call result) is unimplemented.
//  - Compare (lowerCompare). eq/ne where every root of both pointers is a distinct alloca of this
//    function: tags, then indices (tag == tag' and idx == idx', a data conjunction: and_i1 / or_i1 for
//    ne). Every other compare is over addresses base[tag] + size * idx as i64 (rule 21): base[tag] is
//    the root's ptrtoint when the tag is a classical constant, else a select chain over the pointer's
//    roots on the flags tag == k, the first root innermost (the complement); the idx is widened by its
//    own extension and scaled by shl (power-of-two cell size) or mul. The result is always a rail (a
//    classical outcome becomes an i1 seed rail).
//  - Loads, stores, ptrtoint, inttoptr and the clone boundary are unimplemented in this module (the
//    rule's other witnesses, wave-2 integration beads).
#include "cq/FatPtr.h"

#include <optional>
#include <string>

#include "cq/Abi.h"
#include "../mem/qram/QramInternal.h"
#include "../mem/qrom/QromInternal.h"
#include "FatPtrInternal.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Operator.h"
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
  bool tagRail() const { return tag.handle; }
  bool idxRail() const { return idx.handle; }
};

// ---- object table ----------------------------------------------------------------------------

unsigned rootNumber(LoweringContext &ctx, const Value *root) {
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
bool isRoot(LoweringContext &ctx, const Value *p) {
  if (isQ(ctx, p) || ctx.T.isFatPointer(p, ctx.S))
    return false;
  if (classicalMemoryOnly(ctx, p))
    return true;
  if (isa<GEPOperator>(p) || isa<BitCastOperator>(p) || isa<AddrSpaceCastOperator>(p))
    return false;
  return mem::isQramRoot(ctx, p);
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

// The width of a summed rail cell index (cq-qf4c): the C index width (at least int, 32), or the
// widest summand. LLVM sums at i64; the sum's low W bits are exact, and so is its unsigned reading at W
// whenever every in-domain cell index is below 2^W: always for a QRAM (qram_alloc takes an i32 cell
// count, BACKEND_ABI), and for a classical object whose static cell count is below 2^W. Otherwise 64.
unsigned sumWidth(LoweringContext &ctx, const Fat &f, unsigned widest) {
  unsigned W = std::max(32u, widest);
  if (W >= 64)
    return 64;
  const DataLayout &DL = ctx.M.getDataLayout();
  for (const Value *r : f.roots) {
    if (mem::isQramRoot(ctx, r))
      continue;
    APInt off(64, 0);
    const Value *obj = r->stripAndAccumulateConstantOffsets(DL, off, /*AllowNonInbounds=*/true);
    std::optional<uint64_t> bytes;
    if (auto *gv = dyn_cast<GlobalVariable>(obj))
      bytes = DL.getTypeAllocSize(gv->getValueType()).getFixedValue();
    else if (auto *ai = dyn_cast<AllocaInst>(obj))
      if (auto sz = ai->getAllocationSize(DL); sz && !sz->isScalable())
        bytes = sz->getFixedValue();
    if (!bytes || f.cell == 0 || *bytes / f.cell >= (uint64_t(1) << W))
      return 64;
  }
  return W;
}

Fat deriveGEP(LoweringContext &ctx, const GEPOperator &g, bool emit) {
  const DataLayout &DL = ctx.M.getDataLayout();
  Fat f = derive(ctx, g.getPointerOperand(), emit);
  MapVector<Value *, APInt> vars;
  APInt cst(64, 0);
  if (!g.collectOffset(DL, 64, vars, cst))
    unimplemented("fatptr: a GEP whose offset is not linear in its indices", &g);
  // The cell size: the scale of the variable terms, one per fat pointer.
  auto fixCell = [&](uint64_t s) {
    if (s == 0)
      unimplemented("fatptr: a GEP index of scale 0", &g);
    if (f.cell == 0)
      f.cell = s;
    else if (f.cell != s)
      unimplemented("fatptr: a GEP whose index scale differs from the pointer's cell size (" +
                        std::to_string(s) + " vs " + std::to_string(f.cell) + ")",
                    &g);
  };
  const Value *qTerm = nullptr;
  SmallVector<Value *, 2> cTerms;
  for (auto &[v, scale] : vars) {
    int64_t s = scale.getSExtValue();
    if (s < 0)
      unimplemented("fatptr: a GEP index with a negative scale", &g);
    fixCell(uint64_t(s));
    if (isQ(ctx, v)) {
      if (qTerm)
        unimplemented("fatptr: a GEP with two quantum indices", &g);
      qTerm = v;
    } else {
      cTerms.push_back(v);
    }
  }
  int64_t c = cst.getSExtValue();
  if (c != 0) {
    if (f.cell == 0)
      f.cell = DL.getTypeAllocSize(g.getResultElementType()).getFixedValue();
    if (f.cell == 0 || c % int64_t(f.cell) != 0)
      unimplemented("fatptr: a constant GEP offset that is not a whole number of cells", &g);
  }
  if (!qTerm && !f.idxRail()) {
    if (cTerms.empty() && c == 0)
      return f;
    if (!emit) {
      f.idx = Operand{nullptr, false};
      return f;
    }
    IRBuilder<> &B = ctx.B();
    Value *idx = f.idx.v;
    for (Value *v : cTerms) {
      Operand o = ctx.operand(v);
      if (o.handle)
        internalError("fatptr: a classical GEP index bound to a rail", v);
      Value *x = B.CreateSExtOrTrunc(o.v, i64(ctx));
      idx = B.CreateAdd(idx, x);
    }
    if (c != 0)
      idx = B.CreateAdd(idx, ConstantInt::get(i64(ctx), c / int64_t(f.cell)));
    f.idx = Operand{idx, false};
    return f;
  }
  // A rail cell index (rule 21): the base's rail idx and/or the quantum term's logical index, plus the
  // classical part (the base's classical idx, the classical terms, the constant). A lone rail stays at
  // its own width (the widening is address arithmetic, never emitted, rule 20); a sum is computed at
  // sumWidth: each rail widened by its own extension (zext, or sext for a signed index), then added (an
  // index past the object is undefined, outside the domain). The widenings and adds are templates.
  const Value *ix = nullptr;
  bool qsext = false;
  if (qTerm) {
    ix = stripIndexCast(ctx, qTerm, qsext);
    if (!ix->getType()->isIntegerTy() || ix->getType()->getIntegerBitWidth() > 64)
      unimplemented("fatptr: a quantum GEP index wider than 64 bits", &g);
  }
  bool classicalPart = !cTerms.empty() || c != 0 ||
                       (!f.idxRail() && !(isa<ConstantInt>(f.idx.v) && cast<ConstantInt>(f.idx.v)->isZero()));
  bool sum = classicalPart || (f.idxRail() && ix);
  unsigned ixW = ix ? ix->getType()->getIntegerBitWidth() : 0;
  bool ixSext = qsext && ixW < 64;
  unsigned W = sum ? sumWidth(ctx, f, std::max(f.idxRail() ? f.idxBits : 0u, ixW)) : f.idxRail() ? f.idxBits : ixW;
  bool sext = sum ? false : f.idxRail() ? f.idxSext : ixSext;
  if (!emit) {
    f.idxBits = W;
    f.idxSext = sext;
    f.idx = Operand{nullptr, true};
    return f;
  }
  IRBuilder<> &B = ctx.B();
  auto widen = [&](Operand r, unsigned w, bool sx) -> Operand {
    if (!sum || w >= W)
      return r;
    return Operand{tmpl(ctx, sx ? "sext" : "zext", intRail(w), {r}, "", "", intRail(W)), true};
  };
  Operand rail{nullptr, true};
  if (f.idxRail())
    rail = widen(f.idx, f.idxBits, f.idxSext);
  if (ix) {
    Operand r = ctx.operand(ix);
    if (!r.handle)
      internalError("fatptr: the logical index of a quantum GEP index is not a rail", ix);
    r = widen(r, ixW, ixSext);
    rail = rail.v ? Operand{tmpl(ctx, "add", intRail(W), {rail, r}, ""), true} : r;
  }
  if (classicalPart) {
    Value *cs = f.idxRail() ? ConstantInt::get(i64(ctx), 0) : f.idx.v;
    for (Value *v : cTerms) {
      Operand o = ctx.operand(v);
      if (o.handle)
        internalError("fatptr: a classical GEP index bound to a rail", v);
      cs = B.CreateAdd(cs, B.CreateSExtOrTrunc(o.v, i64(ctx)));
    }
    if (c != 0)
      cs = B.CreateAdd(cs, ConstantInt::get(i64(ctx), c / int64_t(f.cell)));
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
  Fat f;
  addRoots(f, t.roots);
  addRoots(f, e.roots);
  llvm::sort(f.roots, [&](const Value *x, const Value *y) { return rootNumber(ctx, x) < rootNumber(ctx, y); });
  if (t.cell && e.cell && t.cell != e.cell)
    unimplemented("fatptr: a select of pointers with different cell sizes", &sel);
  f.cell = t.cell ? t.cell : e.cell;
  if (t.idxRail() && e.idxRail() && (t.idxBits != e.idxBits || t.idxSext != e.idxSext))
    unimplemented("fatptr: a select of pointers whose index rails differ in width or extension", &sel);
  if (t.idxRail() || e.idxRail()) {
    const Fat &r = t.idxRail() ? t : e;
    f.idxBits = r.idxBits;
    f.idxSext = r.idxSext;
  }
  Operand c = emit ? ctx.operand(sel.getCondition()) : Operand{nullptr, isQ(ctx, sel.getCondition())};
  auto choose = [&](unsigned w, Operand x, Operand y) -> Operand {
    if (!c.handle && (x.handle || y.handle))
      unimplemented("fatptr: a classical-condition select of fat pointers with rail fields (rule 9 merge)", &sel);
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
    // One rail arm and one classical arm: the classical one as a literal at the rail's width.
    auto lit = [&](Operand o) -> Operand {
      if (o.handle)
        return o;
      auto *ci = dyn_cast_or_null<ConstantInt>(o.v);
      if (!ci)
        unimplemented("fatptr: a select of a rail cell index with a non-constant classical one", &sel);
      bool fits = f.idxSext ? ci->getValue().isSignedIntN(f.idxBits) : ci->getValue().isIntN(f.idxBits);
      if (!fits)
        unimplemented("fatptr: a select of a rail cell index with a constant outside its width", &sel);
      return Operand{ConstantInt::get(ctx.M.getContext(), ci->getValue().trunc(f.idxBits)), false};
    };
    f.idx = choose(f.idxBits, lit(t.idx), lit(e.idx));
  }
  return f;
}

// A pointer loaded from a QRAM of pointers (rule 21, 88): its (tag, idx) are the two i32 rails its
// loader bound. Its roots are the roots of the pointers this function stores into the objects the load
// reads, restricted to the load's provenance; its cell size their common one.
Fat deriveLoaded(LoweringContext &ctx, const LoadInst &ld, bool emit) {
  static unsigned depth = 0;
  struct Guard {
    Guard() { ++depth; }
    ~Guard() { --depth; }
  } guard;
  if (depth > 8)
    unimplemented("fatptr: pointers loaded from a QRAM of pointers nested more than 8 deep", &ld);
  ArrayRef<ObjectId> src = ctx.T.provenance(ld.getPointerOperand(), ctx.S);
  if (src.empty())
    unimplemented("fatptr: a pointer loaded through a pointer with no known object (rule 21)", &ld);
  for (ObjectId o : src)
    if (ctx.T.classOf(o) != ObjClass::Qram)
      unimplemented("fatptr: a pointer loaded through a fat pointer from slot or classical memory (rule 21, 189)",
                    &ld);
  SmallVector<ObjectId, 4> mine(ctx.T.provenance(&ld, ctx.S).begin(), ctx.T.provenance(&ld, ctx.S).end());
  auto intersects = [](ArrayRef<ObjectId> a, ArrayRef<ObjectId> b) {
    for (ObjectId x : a)
      if (llvm::is_contained(b, x))
        return true;
    return false;
  };
  Fat f;
  for (const Instruction &I : instructions(*ctx.S.F)) {
    auto *st = dyn_cast<StoreInst>(&I);
    if (!st || !st->getValueOperand()->getType()->isPointerTy() ||
        !intersects(ctx.T.provenance(st->getPointerOperand(), ctx.S), src))
      continue;
    Fat s = derive(ctx, st->getValueOperand(), /*emit=*/false);
    for (const Value *r : s.roots)
      if (intersects(ctx.T.provenance(r, ctx.S), mine))
        addRoots(f, {r});
    if (s.cell) {
      if (f.cell && f.cell != s.cell)
        unimplemented("fatptr: a QRAM of pointers holding pointers of two cell sizes", &ld);
      f.cell = s.cell;
    }
  }
  if (f.roots.empty())
    unimplemented("fatptr: a pointer loaded from a QRAM into which this function stores no pointer of its "
                  "provenance",
                  &ld);
  llvm::sort(f.roots, [&](const Value *x, const Value *y) { return rootNumber(ctx, x) < rootNumber(ctx, y); });
  f.idxBits = 32;
  f.idxSext = false;
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

Fat derive(LoweringContext &ctx, const Value *p, bool emit, bool eager) {
  if (!p->getType()->isPointerTy())
    internalError("fatptr: derive of a non-pointer", p);
  if (auto *bc = dyn_cast<BitCastOperator>(p))
    return derive(ctx, bc->getOperand(0), emit);
  if (auto *ac = dyn_cast<AddrSpaceCastOperator>(p))
    return derive(ctx, ac->getPointerOperand(), emit);
  if (isRoot(ctx, p))
    return deriveRoot(ctx, p, emit);
  if (auto *g = dyn_cast<GEPOperator>(p))
    return deriveGEP(ctx, *g, emit);
  if (auto *sel = dyn_cast<SelectInst>(p))
    return deriveSelect(ctx, *sel, emit, eager);
  if (isa<PHINode>(p))
    unimplemented("fatptr: a phi of fat pointers (rule 21 merge over edge predicates)", p);
  if (auto *ld = dyn_cast<LoadInst>(p))
    return deriveLoaded(ctx, *ld, emit);
  if (isa<Argument>(p))
    unimplemented("fatptr: a fat pointer parameter (rule 21 clone-boundary triple)", p);
  if (isa<IntToPtrInst>(p))
    unimplemented("fatptr: inttoptr of a quantum integer (rule 21 provenance decoding)", p);
  if (isa<CallBase>(p))
    unimplemented("fatptr: a fat pointer returned by a call (rule 21 clone-boundary triple)", p);
  if (classicalMemoryOnly(ctx, p) == false && !isQ(ctx, p))
    unimplemented("fatptr: a root pointer into slot or QRAM memory", p);
  unimplemented("fatptr: a quantum pointer of this kind", p);
}

// ---- addresses -------------------------------------------------------------------------------

// The root's classical base address (rule 21: a host object's base is its real host address).
using Bases = DenseMap<const Value *, Value *>;   // root -> its ptrtoint, one per compare

Value *rootBase(LoweringContext &ctx, const Value *root, Bases &bases) {
  if (Value *b = bases.lookup(root))
    return b;
  for (ObjectId o : ctx.T.provenance(root, ctx.S))
    if (ctx.T.classOf(o) == ObjClass::Slot)
      unimplemented("fatptr: the address of a slot object (rule 21)", root);
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

// base[tag] + size * idx.
Operand address(LoweringContext &ctx, const Fat &f, Bases &cache) {
  Operand base = baseOf(ctx, f, cache);
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

// Every root of both pointers a distinct alloca of this function (rule 21's tag reduction).
bool distinctLocalAllocas(LoweringContext &ctx, const Fat &a, const Fat &b) {
  for (const Fat *f : {&a, &b})
    for (const Value *r : f->roots) {
      auto *ai = dyn_cast<AllocaInst>(r);
      if (!ai || ai->getFunction() != ctx.S.F)
        return false;
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

FatPtr lower(LoweringContext &ctx, const Value *ptr) {
  Fat f;
  if (auto *sel = dyn_cast<SelectInst>(ptr)) {
    // The spine's call at the select (patch spine-dispatch-ptrselect): compute and bind its fields.
    f = derive(ctx, ptr, /*emit=*/true, /*eager=*/true);
    ctx.bindFields(sel, {f.tag, f.idx});
  } else {
    f = derive(ctx, ptr, /*emit=*/true);
  }
  FatPtr out{f.tag.v, f.tag.handle, f.idx.v, f.idx.handle, {}};
  for (const Value *r : f.roots)
    for (ObjectId o : ctx.T.provenance(r, ctx.S))
      if (llvm::find(out.objects, o) == out.objects.end())
        out.objects.push_back(o);
  return out;
}

namespace {
// The fat pointer's roots, each a QRAM object of cell size f.cell (rule 21 over QRAM objects).
void checkQramRoots(LoweringContext &ctx, const Fat &f, const Instruction &I) {
  for (const Value *r : f.roots) {
    if (!mem::isQramRoot(ctx, r))
      unimplemented("fatptr: a load or store through a fat pointer into a slot or host object (rule 21 guarded "
                    "slot select / host access)",
                    &I);
    if (f.cell && f.cell != mem::qramElemBytes(ctx, r, I))
      unimplemented("fatptr: a fat pointer whose cell size is not its QRAM object's element size", &I);
  }
}

// Whether the fat pointer may name root (a classical tag names one root only).
bool mayName(LoweringContext &ctx, const Fat &f, const Value *r) {
  if (f.tag.handle)
    return true;
  auto *k = dyn_cast<ConstantInt>(f.tag.v);
  if (!k)
    internalError("fatptr: a classical tag that is not a constant");
  return k->getZExtValue() == rootNumber(ctx, r);
}

// The guard of root r: tag == r's number, conjoined with the current flag (a fresh i1 rail,
// alloc_i1(false) + and_i1(flag, eq, g), 84). nullptr = unguarded.
Value *guardOf(LoweringContext &ctx, const Fat &f, const Value *r, Value *flag) {
  if (!f.tag.handle)
    return flag;
  Operand eq = icmp(ctx, CmpInst::ICMP_EQ, 32, f.tag, Operand{ConstantInt::get(i32(ctx), rootNumber(ctx, r)), false});
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
} // namespace

// Rule 21: a load through a fat pointer is one pure access per object of its provenance, executed
// unguarded at idx (a QRAM load; a QROM of a classical object at a rail idx), merged by a select chain
// on the flags tag == k (the first root innermost, the complement), like any multi-way merge (rule 9).
// A pointer load (a QRAM of pointers, 88) merges its tag and idx halves alike and binds them as the
// load's two fields.
void lowerLoad(LoweringContext &ctx, LoadInst &ld) {
  Fat f = derive(ctx, ld.getPointerOperand(), /*emit=*/true);
  Type *ty = ld.getType();
  bool ptr = ty->isPointerTy();
  if (!ptr && !ty->isIntegerTy() && !ty->isFloatingPointTy())
    unimplemented("fatptr: a load of an aggregate or vector through a fat pointer (rules 21, 25, 26)", &ld);
  SmallVector<const Value *, 4> roots;
  for (const Value *r : f.roots)
    if (mayName(ctx, f, r))
      roots.push_back(r);
  if (roots.empty())
    internalError("fatptr: a fat pointer naming none of its roots", &ld);
  SmallVector<std::pair<Value *, Value *>, 4> hs;   // per root: the value (ptr: tag, idx)
  for (const Value *r : roots) {
    if (mem::isQramRoot(ctx, r)) {
      if (f.cell && f.cell != mem::qramElemBytes(ctx, r, ld))
        unimplemented("fatptr: a fat pointer whose cell size is not its QRAM object's element size", &ld);
      if (ptr)
        hs.push_back(mem::qramLoadPtrAt(ctx, r, f.idx, ld));
      else
        hs.push_back({mem::qramLoadAt(ctx, r, f.idx, ty, ld), nullptr});
      continue;
    }
    if (!ptr && classicalMemoryOnly(ctx, r) && f.idxRail()) {
      uint64_t size = ctx.M.getDataLayout().getTypeAllocSize(ty).getFixedValue();
      if (f.cell && f.cell != size)
        unimplemented("fatptr: a fat-pointer QROM whose cell size is not the loaded type's size", &ld);
      hs.push_back({mem::qromLoadAt(ctx, r, f.idx, ty, ld), nullptr});
      continue;
    }
    unimplemented("fatptr: a load through a fat pointer from a slot object, a host object at a classical idx, or "
                  "a pointer from classical memory (rule 21 guarded slot select / host access, 189)",
                  &ld);
  }
  auto merge = [&](RailType w, auto pick) {
    Operand acc{pick(hs[0]), true};
    for (unsigned i = 1; i < roots.size(); ++i) {
      Operand eq = icmp(ctx, CmpInst::ICMP_EQ, 32, f.tag,
                        Operand{ConstantInt::get(i32(ctx), rootNumber(ctx, roots[i])), false});
      acc = Operand{tmpl(ctx, "select", w, {eq, Operand{pick(hs[i]), true}, acc}, ""), true};
    }
    return acc;
  };
  if (ptr) {
    Operand tag = merge(intRail(32), [](auto &p) { return p.first; });
    Operand idx = merge(intRail(32), [](auto &p) { return p.second; });
    ctx.bindFields(&ld, {tag, idx});
    return;
  }
  ctx.bind(&ld, merge(railTypeOf(ty), [](auto &p) { return p.first; }).v);
}

SmallVector<Operand, 8> loadHostCells(LoweringContext &ctx, const Value *src, Type *cellTy, uint64_t n,
                                      function_ref<uint64_t(const Value *root)> bound, const Instruction &at) {
  Fat f = derive(ctx, src, /*emit=*/true);
  if (f.idxRail())
    unimplemented("fatptr: a memory intrinsic's fat source pointer at a quantum cell index (a QROM per cell, rules "
                  "20, 22)",
                  &at);
  auto *ci = dyn_cast<ConstantInt>(f.idx.v);
  if (!ci)
    unimplemented("fatptr: a memory intrinsic's fat source pointer at a run-time classical cell index", &at);
  if (!cellTy->isIntegerTy() && !cellTy->isFloatingPointTy())
    unimplemented("fatptr: a memory intrinsic copying cells that are not integers or floating point through a fat "
                  "source pointer",
                  &at);
  const DataLayout &DL = ctx.M.getDataLayout();
  uint64_t size = DL.getTypeAllocSize(cellTy).getFixedValue();
  int64_t base = ci->getSExtValue() * int64_t(f.cell);
  SmallVector<const Value *, 4> roots;
  SmallVector<uint64_t, 4> bounds;
  for (const Value *r : f.roots) {
    if (!mayName(ctx, f, r))
      continue;
    if (!classicalMemoryOnly(ctx, r))
      unimplemented("fatptr: a memory intrinsic's fat source pointer into a slot or QRAM object (rules 21, 22)", &at);
    roots.push_back(r);
    bounds.push_back(bound(r));
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
  SmallVector<Operand, 8> out;
  for (uint64_t j = 0; j < n; ++j) {
    std::optional<Operand> acc;
    for (unsigned i = 0; i < roots.size(); ++i) {
      if (j * size >= bounds[i])
        continue;
      Operand r = ctx.operand(roots[i]);
      if (r.handle)
        internalError("fatptr: a root pointer bound to a rail", roots[i]);
      int64_t off = base + int64_t(j * size);
      Value *p = off ? B.CreateInBoundsGEP(Type::getInt8Ty(C), r.v, ConstantInt::get(i64(ctx), off)) : r.v;
      Operand v{B.CreateLoad(cellTy, p), false};
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

std::pair<Operand, Operand> storedFields(LoweringContext &ctx, const Value *ptr) {
  Fat f = derive(ctx, ptr, /*emit=*/true);
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
  checkQramRoots(ctx, f, st);
  Value *val = st.getValueOperand();
  Type *ty = val->getType();
  if (!ty->isIntegerTy() && !ty->isFloatingPointTy())
    unimplemented("fatptr: a store of a pointer or aggregate through a fat pointer (rule 21)", &st);
  Value *flag = ctx.currentFlag();
  Operand v = ctx.operand(val);
  if (!v.handle) {
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(ty)}, {v.v});
    ctx.unc().recordSeed(seed);
    v = Operand{seed, true};
  }
  for (const Value *r : f.roots) {
    if (!mayName(ctx, f, r))
      continue;
    mem::qramStoreAt(ctx, r, f.idx, ty, v.v, guardOf(ctx, f, r, flag), st);
  }
}

Value *lowerCompare(LoweringContext &ctx, ICmpInst &cmp) {
  Fat a = derive(ctx, cmp.getOperand(0), /*emit=*/true);
  Fat b = derive(ctx, cmp.getOperand(1), /*emit=*/true);
  CmpInst::Predicate p = cmp.getPredicate();
  bool eq = p == CmpInst::ICMP_EQ, ne = p == CmpInst::ICMP_NE;
  bool sameCell = a.cell == 0 || b.cell == 0 || a.cell == b.cell;
  if ((eq || ne) && sameCell && distinctLocalAllocas(ctx, a, b)) {
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

void lowerPtrToInt(LoweringContext &, Instruction &I) {
  unimplemented("fatptr: ptrtoint of a fat pointer (rule 21 address)", &I);
}

void lowerIntToPtr(LoweringContext &, Instruction &I) {
  unimplemented("fatptr: inttoptr of a quantum integer (rule 21 provenance decoding)", &I);
}

// Rule 21 at a clone boundary (191): a pointer into ONE QRAM object crosses as (object, tag, idx): the
// object's bus handle, its i32 tag (the root number; classical for a single object) and its i32 cell
// index (a rail or a classical value, as storedFields). cellCount is null (a QRAM's extent is its bus).
// Several objects (an object table) or slot/host provenance are unimplemented.
Triple passAcrossCall(LoweringContext &ctx, const Value *ptr) {
  Fat f = derive(ctx, ptr, /*emit=*/false);
  if (f.roots.size() != 1 || !mem::isQramRoot(ctx, f.roots[0]))
    unimplemented("fatptr: a pointer crossing a clone boundary that is not into one QRAM object (rule 21 object "
                  "table, slot or host triple)",
                  ptr);
  const Instruction *at = dyn_cast<Instruction>(ptr);
  if (!at)
    unimplemented("fatptr: a constant pointer into a QRAM crossing a clone boundary", ptr);
  auto [tag, idx] = storedFields(ctx, ptr);
  Value *bus = mem::qramBusOf(ctx, f.roots[0], *at);
  return Triple{bus, tag.v, idx.v, nullptr};
}

} // namespace cq::fatptr

namespace cq::fatptr {
// P1 (cq-arch 2026-11-01): stub until fatptr builds it.
void bindFormal(LoweringContext &, const llvm::Argument &formal, llvm::Value *, Operand, Operand, llvm::Value *) {
  unimplemented("fatptr: bindFormal (P1: a clone's triple pointer formal, rule 21, 190, 191)", &formal);
}
} // namespace cq::fatptr
