// Module spine (cq-su3p): CR rule 3 representation views of a narrow register.
//
// CONTRACT
//
//  CR rule 3: "Casts ... are representation changes and emit no gate for lane moves." -O1 widens a
//  bool register to a byte around a merge (113: %22 = phi i8 [zext(%19 = cq_theta_i1(false)), %16],
//  [0, %9]; %30 = phi i8 [zext(%27 = cq_theta_i1(trunc %22)), %25], [%22, %21]). Orchestrator
//  decision on cq-su3p under NORTHSTAR p2 and CR rule 3 (owner may override): the register stays one
//  rail of its narrow width and the wide ops narrow to it, never a select over copies of the rotated
//  rail (rule 10: the merge is the register).
//
//  - Narrow value. Of an original iN value v, at width M < N: a zext from iM (its source), a view
//    phi of width M (itself), or a ConstantInt whose value fits M bits.
//  - View phi (viewMerge). A quantum integer phi whose every incoming has a narrow value of one
//    width M, at least one of them a register state (a value in Shared::statePreps: a rule 10
//    cq_theta or state-prep merge, or another view phi). Every non-constant incoming must name one
//    rail R (read as a phi edge: atPhiEdge); a constant incoming c is R's value on its edge only when
//    R was minted by an alloc of c and every cq_theta bound to R has a block predicate disjoint from
//    that edge (no prep ran there). Anything else is cq::unimplemented. The phi is a view of R
//    (Shared::views). When some use of the phi does not narrow, a zext_<M>_to_<N> template of R is
//    taken at the phi and bound as its wide value (a copy at the merge point).
//  - Skipped zext. A quantum zext from iM whose every use narrows (below) is not emitted and has no
//    binding (Shared::narrowSkipped); its readers read its source. Code that walks original uses for
//    liveness sees through it (readingUses).
//  - Narrowing uses. A trunc to iM; an icmp eq/ne whose other operand is a constant fitting M, a view
//    phi, a classical zext from iM, or a quantum zext from iM that is (or will be) skipped; a phi that
//    becomes a view phi (all incomings narrow at M, one of them a register state).
//  - lowerNarrow. A skipped zext binds nothing. A trunc to iM of a view phi or a skipped zext binds
//    the narrow operand (no gate). An icmp eq/ne whose operands are views, skipped or classical zexts
//    or constants is lowered at width M: ne at i1 is xor_i1 (113's `q2 ^= q1`), any other is
//    icmp_<pred>_iM; rule 6 reads a narrowed xor's narrow operands (Shared::narrowXor).
//
//  Packed integers (cq-0umd; CR rules 26 and 3: -O1's ABI coercion of struct { int, int } to one i64
//  in 159 and 166 is classical arithmetic on the coercion and emits no gate).
//  - A packed value is bound field-wise (Shared::packs: its bit boundaries {0, ..., N}; one Operand
//    per field, low bits first: a handle, or a classical value of the field's width, the constant 0
//    where the packing leaves the bits zero).
//  - Packing (lowerPack). A quantum or disjoint whose every use is a packing or disjoint, an unpacking
//    read (trunc, lshr by a constant) or a field consumer (a call argument whose callee unpacks the
//    formal into several fields, a ret, an insertvalue's inserted value); a quantum zext or shl by a
//    constant whose every use is a packing shl or or, or such a call argument. zext of x: (x, 0); shl
//    by C: the fields moved up, the bits shifted out dropped; or disjoint: the union, a quantum field
//    taken whole where the other side is zero across it (any other overlap of a quantum field is
//    unimplemented), classical pieces or'ed classically. A classical operand is seen through its own
//    zext / shl / or-disjoint structure. A call argument takes its callee formal's boundaries
//    (unpackCuts); reshaping splits zero and classical fields only, never a quantum one.
//  - Unpacking. A trunc to M of a field-wise value is its field [0, M); an lshr by C its fields moved
//    down (the result packed again, one field bound as that field). A result with only classical
//    fields is one classical iN rebuilt from them (bindPacked).
//  - A value another module binds field-wise (a clone's formal, a clone call's result) gets its
//    boundaries from its readers at the first read (unpackCuts: taint's intFields rule); a different
//    field count is unimplemented.
#include "SpineInternal.h"

#include "cq/Abi.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq::spine {

namespace {

std::string describe(const Value *v) {
  std::string s;
  raw_string_ostream os(s);
  v->printAsOperand(os, false);
  return os.str();
}

unsigned widthOf(const Value *v) {
  auto *t = dyn_cast<IntegerType>(v->getType());
  return t ? t->getBitWidth() : 0;
}

bool fits(const ConstantInt *c, unsigned M) { return c->getValue().getActiveBits() <= M; }

// A zext from an integer iM of an integer value.
const ZExtInst *intZext(const Value *v) {
  auto *z = dyn_cast<ZExtInst>(v);
  if (!z || !z->getSrcTy()->isIntegerTy() || !z->getDestTy()->isIntegerTy())
    return nullptr;
  return z;
}

bool registerState(Shared &sh, const Value *n) { return sh.statePreps.count(n) || sh.views.count(n); }



// Every incoming of P has a narrow value of one width M < N (constants fit it). 0: no.
unsigned phiWidth(Shared &sh, const PHINode &P) {
  unsigned N = widthOf(&P);
  if (!N)
    return 0;
  unsigned M = 0;
  for (const Value *u : P.incoming_values()) {
    unsigned b = 0;
    if (auto it = sh.views.find(u); it != sh.views.end() && it->second.cell)
      return 0;
    if (!narrowValue(sh, u, b))
      return 0;
    if (!b)
      continue;   // a constant: checked below
    if (M && M != b)
      return 0;
    M = b;
  }
  if (!M || M >= N)
    return 0;
  for (const Value *u : P.incoming_values())
    if (auto *c = dyn_cast<ConstantInt>(u); c && !fits(c, M))
      return 0;
  return M;
}

// P becomes a view phi of width M when lowered (assume: a narrow value taken as a register state).
bool willView(Shared &sh, const PHINode &P, unsigned M, const Value *assume) {
  if (sh.views.count(&P))
    return true;
  if (phiWidth(sh, P) != M)
    return false;
  for (const Value *u : P.incoming_values()) {
    unsigned b = 0;
    const Value *n = narrowValue(sh, u, b);
    // The assumption holds only for a value not lowered yet: a lowered one is a register state or not
    // (cq-r7-91: 91's phi [zext(load), 7], whose load is no register state, is no view at the phi).
    if (n && !isa<Constant>(n) && ((n == assume && !sh.binds.count(n)) || registerState(sh, n)))
      return true;
  }
  return false;
}

bool zextSkippable(LoweringContext &ctx, const ZExtInst &z, SmallPtrSetImpl<const Value *> &visiting);

// Can the operand w of a narrowed icmp at width M be read narrow?
bool icmpOperandNarrows(LoweringContext &ctx, const Value *w, unsigned M,
                        SmallPtrSetImpl<const Value *> &visiting) {
  Shared &sh = shared(ctx);
  if (auto *c = dyn_cast<ConstantInt>(w))
    return fits(c, M);
  if (auto it = sh.views.find(w); it != sh.views.end())
    return it->second.bits == M;
  const ZExtInst *z = intZext(w);
  if (!z || widthOf(z->getOperand(0)) != M)
    return false;
  if (!isQ(ctx, z->getOperand(0)))
    return true;   // a classical zext: its source is a classical value
  if (sh.narrowSkipped.count(z))
    return true;
  if (sh.binds.count(z))
    return false;  // lowered as a wide template already
  return zextSkippable(ctx, *z, visiting);
}

bool narrowUseOf(LoweringContext &ctx, const Use &U, unsigned M, const Value *self,
                 SmallPtrSetImpl<const Value *> &visiting) {
  Shared &sh = shared(ctx);
  const User *u = U.getUser();
  if (auto *t = dyn_cast<TruncInst>(u))
    return widthOf(t) == M;
  if (auto *cmp = dyn_cast<ICmpInst>(u)) {
    if (!cmp->isEquality())
      return false;
    return icmpOperandNarrows(ctx, cmp->getOperand(1 - U.getOperandNo()), M, visiting);
  }
  if (auto *P = dyn_cast<PHINode>(u))
    return willView(sh, *P, M, self);
  return false;
}

bool zextSkippable(LoweringContext &ctx, const ZExtInst &z, SmallPtrSetImpl<const Value *> &visiting) {
  if (!visiting.insert(&z).second)
    return true;   // a cycle of zexts read only by each other's compares: all narrow together
  const Value *x = z.getOperand(0);
  unsigned M = widthOf(x);
  if (!M || M >= widthOf(&z) || z.use_empty() || !isQ(ctx, x))
    return false;
  for (const Use &U : z.uses())
    if (!narrowUseOf(ctx, U, M, x, visiting))
      return false;
  return true;
}

// The narrow operand of a narrowing use: a view's rail, a skipped or classical zext's source, a
// constant at width M.
Operand narrowOperand(LoweringContext &ctx, const Value *w, unsigned M) {
  Shared &sh = shared(ctx);
  if (auto *c = dyn_cast<ConstantInt>(w))
    return Operand{ConstantInt::get(IntegerType::get(ctx.M.getContext(), M), c->getValue().trunc(M)), false};
  if (auto it = sh.views.find(w); it != sh.views.end())
    return Operand{it->second.rail, true};
  if (const ZExtInst *z = intZext(w))
    return ctx.operand(z->getOperand(0));
  internalError("spine: narrowOperand of a value with no narrow form", w);
}

// Does the operand w narrow (lowerNarrow's icmp test, on the state at the icmp)?
bool narrowsNow(LoweringContext &ctx, const Value *w, unsigned M) {
  Shared &sh = shared(ctx);
  if (auto *c = dyn_cast<ConstantInt>(w))
    return fits(c, M);
  if (auto it = sh.views.find(w); it != sh.views.end())
    return it->second.bits == M;
  const ZExtInst *z = intZext(w);
  if (!z || widthOf(z->getOperand(0)) != M)
    return false;
  return sh.narrowSkipped.count(z) || !isQ(ctx, z->getOperand(0));
}

} // namespace

const Value *narrowValue(Shared &sh, const Value *v, unsigned &bits) {
  bits = 0;
  if (const ZExtInst *z = intZext(v)) {
    bits = widthOf(z->getOperand(0));
    return z->getOperand(0);
  }
  if (auto it = sh.views.find(v); it != sh.views.end()) {
    bits = it->second.bits;
    return v;
  }
  if (isa<ConstantInt>(v))
    return v;
  return nullptr;
}

void readingUses(Shared &sh, const Value *v, SmallVectorImpl<const Use *> &out) {
  for (const Use &U : v->uses()) {
    if (sh.narrowSkipped.count(U.getUser()))
      readingUses(sh, U.getUser(), out);
    else
      out.push_back(&U);
  }
}

bool narrowUse(LoweringContext &ctx, const Use &U, unsigned M) {
  SmallPtrSet<const Value *, 8> visiting;
  return narrowUseOf(ctx, U, M, U.get(), visiting);
}

bool viewMerge(LoweringContext &ctx, PHINode &P) {
  Shared &sh = shared(ctx);
  unsigned M = phiWidth(sh, P);
  if (!M || !willView(sh, P, M, nullptr))
    return false;

  // Each incoming's narrow value: a view's rail, the zext's source read as a phi edge (sh.cur is P), or
  // a literal.
  SmallVector<Operand, 4> ins;
  for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
    const Value *u = P.getIncomingValue(i);
    if (auto *c = dyn_cast<ConstantInt>(u))
      ins.push_back(Operand{ConstantInt::get(IntegerType::get(ctx.M.getContext(), M), c->getValue().trunc(M)), false});
    else if (auto it = sh.views.find(u); it != sh.views.end())
      ins.push_back(Operand{it->second.rail, true});
    else
      ins.push_back(ctx.operand(intZext(u)->getOperand(0)));
  }

  // The register view: every non-constant incoming names one rail R, and every constant incoming is R's
  // value on its edge (R was minted with that literal and nothing changed R on the edge).
  auto registerView = [&]() -> Value * {
    Value *R = nullptr;
    SmallVector<std::pair<unsigned, const ConstantInt *>, 2> consts;
    for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
      if (auto *c = dyn_cast<ConstantInt>(P.getIncomingValue(i))) {
        consts.push_back({i, c});
        continue;
      }
      if (!ins[i].handle || (R && ins[i].v != R))
        return nullptr;
      R = ins[i].v;
    }
    if (!R)
      internalError("spine: a view phi with no rail incoming", &P);
    // A constant incoming is R's value on its edge only where nothing changed R since its mint: R was
    // minted with that literal, and every gate emitted on R so far (a non-diagonal gate, Shared::rotations,
    // or an in-place write, RailHist::writes) stands for an original instruction off the edge. The gates
    // themselves are read, not the cq_theta bindings: an in-place cq_theta's operand is rebound to its
    // pre-rotation copy (finishPreRotation), so the cq_theta that minted and rotated R names R nowhere
    // (cq-5ajv).
    if (!consts.empty()) {
      auto h = sh.hist.find(R);
      const ConstantInt *seed = h == sh.hist.end() ? nullptr : dyn_cast_or_null<ConstantInt>(h->second.seed);
      SmallVector<CallInst *, 4> gates;
      if (auto rt = sh.rotations.find(R); rt != sh.rotations.end())
        gates.append(rt->second.begin(), rt->second.end());
      if (h != sh.hist.end())
        for (const RailHist::Write &w : h->second.writes)
          gates.push_back(w.call);
      for (auto &[i, c] : consts) {
        if (!seed || seed->getBitWidth() != M || seed->getValue() != c->getValue().trunc(M))
          return nullptr;
        const Pred &e = ctx.preds().edge(P.getIncomingBlock(i), P.getParent());
        for (CallInst *g : gates) {
          const Instruction *at = nullptr;
          if (auto ga = sh.gateAt.find(g); ga != sh.gateAt.end())
            for (const Instruction *a : ga->second)
              if (a->getFunction() == P.getFunction()) {
                at = a;
                break;
              }
          if (!at || !(ctx.preds().block(at->getParent()) & e).isBottom())
            return nullptr;
        }
      }
    }
    return R;
  };
  Value *R = registerView();
  if (!R) {
    // CR rule 9 (rule 10, f684858: two registers, or a register and a value that is not its state on an
    // edge, merge by rule 9 over their handles): the merge at the view's width M, one arm per distinct
    // narrow incoming under its edges' predicate, into a fresh rail the view names.
    std::vector<std::pair<Pred, Operand>> arms;
    for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
      Pred e = ctx.preds().edge(P.getIncomingBlock(i), P.getParent());
      if (e.isBottom())
        continue;
      auto it = find_if(arms, [&](const auto &a) { return a.second.v == ins[i].v; });
      if (it == arms.end())
        arms.push_back({e, ins[i]});
      else
        it->first = it->first | e;
    }
    if (arms.empty())
      internalError("spine: a view phi with no reachable incoming", &P);
    R = arms.size() == 1 && arms.front().second.handle
            ? arms.front().second.v
            : selectChain(ctx, arms, RailType{Kind::Int, M}, ctx.preds().block(P.getParent()));
  }

  sh.views[&P] = Shared::View{R, M};
  bool wide = false;
  for (const Use &U : P.uses())
    wide |= !narrowUse(ctx, U, M);
  if (wide) {
    abi::TemplateSpec spec;
    spec.op = "zext";
    spec.w = RailType{Kind::Int, M};
    spec.to = RailType{Kind::Int, widthOf(&P)};
    Value *r = ctx.emitTemplate(spec, {Operand{R, true}}, nullptr);
    bindOperand(ctx, &P, Operand{r, true});
  }
  return true;
}

bool lowerNarrow(LoweringContext &ctx, Instruction &I) {
  Shared &sh = shared(ctx);
  if (lowerPack(ctx, I))
    return true;   // rule 26: a packed integer's fields (cq-0umd)
  if (auto *z = dyn_cast<ZExtInst>(&I)) {
    if (!intZext(z))
      return false;
    SmallPtrSet<const Value *, 8> visiting;
    if (!zextSkippable(ctx, *z, visiting))
      return false;
    sh.narrowSkipped.insert(z);
    return true;
  }

  if (auto *t = dyn_cast<TruncInst>(&I)) {
    const Value *w = t->getOperand(0);
    unsigned M = widthOf(t);
    if (!M)
      return false;
    if (auto it = sh.views.find(w); it != sh.views.end() && it->second.bits == M) {
      bindOperand(ctx, &I, Operand{it->second.rail, true});
      return true;
    }
    if (sh.narrowSkipped.count(w)) {
      if (widthOf(cast<ZExtInst>(w)->getOperand(0)) != M)
        internalError("spine: a skipped zext read by a trunc to another width", &I);
      bindOperand(ctx, &I, ctx.operand(cast<ZExtInst>(w)->getOperand(0)));
      return true;
    }
    return false;
  }

  auto *cmp = dyn_cast<ICmpInst>(&I);
  if (!cmp || !cmp->isEquality())
    return false;
  const Value *a = cmp->getOperand(0), *b = cmp->getOperand(1);
  unsigned M = 0;
  for (const Value *w : {a, b}) {
    unsigned m = 0;
    if (!narrowValue(sh, w, m)) {
      return false;
    }
    if (m && M && m != M)
      return false;
    if (m)
      M = m;
  }
  bool skipped = sh.narrowSkipped.count(a) || sh.narrowSkipped.count(b);
  if (!M || !narrowsNow(ctx, a, M) || !narrowsNow(ctx, b, M)) {
    if (skipped)
      internalError("spine: a skipped zext read by a compare that does not narrow", &I);
    return false;
  }
  // Narrow only what has no wide rail: a view, a skipped zext or a _Bool cell load among the operands.
  if (!skipped && !sh.views.count(a) && !sh.views.count(b))
    return false;
  Operand x = narrowOperand(ctx, a, M), y = narrowOperand(ctx, b, M);
  if (!x.handle && y.handle)
    std::swap(x, y);   // eq/ne are symmetric: the handle first
  if (!x.handle)
    internalError("spine: a narrowed compare of two classical operands", &I);
  abi::TemplateSpec spec;
  spec.w = RailType{Kind::Int, M};
  spec.shape = y.handle ? "" : "hl";
  if (M == 1 && cmp->getPredicate() == CmpInst::ICMP_NE) {
    spec.op = "xor";   // a != b on bits is a ^ b
    // A constant operand is recorded at the narrow width M (cq-b26g).
    auto narrowOf = [&](const Value *w) -> const Value * {
      if (sh.views.count(w))
        return w;
      if (auto *c = dyn_cast<ConstantInt>(w))
        return ConstantInt::get(c->getContext(), c->getValue().trunc(M));
      return intZext(w)->getOperand(0);
    };
    sh.narrowXor[&I] = {narrowOf(a), narrowOf(b)};
  } else {
    spec.op = "icmp";
    spec.pred = CmpInst::getPredicateName(cmp->getPredicate()).str();
  }
  Value *r = ctx.emitTemplate(spec, {x, y}, nullptr);
  bindOperand(ctx, &I, Operand{r, true});
  return true;
}

} // namespace cq::spine

// ---------------------------------------------------------------------------------------------------
// cq-0umd: rule 26 packed integers (contract at the top of this file).

namespace cq::spine {

namespace {

using namespace llvm::PatternMatch;

// One field of a packed value: bits [lo, hi), its operand (a handle, or a classical i(hi-lo)).
struct Seg {
  unsigned lo = 0, hi = 0;
  Operand op;
  bool zero() const {
    auto *c = dyn_cast<ConstantInt>(op.v);
    return !op.handle && c && c->isZero();
  }
};
using Segs = SmallVector<Seg, 4>;

IntegerType *iTy(LoweringContext &ctx, unsigned bits) { return IntegerType::get(ctx.M.getContext(), bits); }

Seg zeroSeg(LoweringContext &ctx, unsigned lo, unsigned hi) {
  return Seg{lo, hi, Operand{ConstantInt::get(iTy(ctx, hi - lo), 0), false}};
}

bool packed(Shared &sh, const Value *v) { return sh.packs.count(v) > 0; }

unsigned leafIndexOf(Type *t, ArrayRef<unsigned> idx);

// The field boundaries another module bound v at: a clone call's packed integer result (its callee's
// packing, packedCuts of its returns), a leaf of a clone call's aggregate result (resultLeafCuts), a
// formal (its unpacking, the clone's ABI). {} when none applies.
SmallVector<unsigned, 4> binderCuts(const Value *v) {
  if (auto *A = dyn_cast<Argument>(v))
    return unpackCuts(A);
  const Value *call = v;
  SmallVector<unsigned, 4> idx;
  if (auto *ev = dyn_cast<ExtractValueInst>(v)) {
    call = ev->getAggregateOperand();
    idx.assign(ev->idx_begin(), ev->idx_end());
  }
  auto *CB = dyn_cast<CallBase>(call);
  const Function *F = CB ? CB->getCalledFunction() : nullptr;
  if (!F || hostCallee(*F))
    return {};
  if (idx.empty())
    return resultIntCuts(*F);   // the union of the returns' packings (cq-jkq8)
  SmallVector<SmallVector<unsigned, 4>, 4> leaves = resultLeafCuts(*F);
  unsigned k = leafIndexOf(F->getReturnType(), idx);
  return k < leaves.size() ? leaves[k] : SmallVector<unsigned, 4>{};
}

// A value bound field-wise by another module (a formal, a call result, an extractvalue) whose readers
// unpack it is registered with unpackCuts at its first read; the field count must agree.
bool fieldwise(LoweringContext &ctx, const Value *v) {
  Shared &sh = shared(ctx);
  if (packed(sh, v))
    return true;
  auto it = sh.binds.find(v);
  if (it == sh.binds.end() || it->second.size() < 2 || !v->getType()->isIntegerTy())
    return false;
  SmallVector<unsigned, 4> cuts = unpackCuts(v);
  if (cuts.size() != it->second.size() + 1) {
    // The readers unpack it at other fields than its binder packed: the binder's layout is the clone's
    // packing of the result (a call's result, or a leaf of its aggregate result); the readers reshape it.
    cuts = binderCuts(v);
    if (cuts.size() != it->second.size() + 1)
      internalError("spine: a value bound field-wise at a layout neither its readers nor its binder give", v);
  }
  sh.packs[v] = cuts;
  return true;
}

Segs segsOfPacked(LoweringContext &ctx, const Value *v) {
  Shared &sh = shared(ctx);
  const SmallVector<unsigned, 4> &cuts = sh.packs.find(v)->second;
  const SmallVector<Operand, 4> &ops = sh.binds.find(v)->second;
  if (ops.size() + 1 != cuts.size())
    internalError("spine: a packed integer whose binding does not have one operand per field", v);
  Segs s;
  for (unsigned k = 0; k + 1 < cuts.size(); ++k)
    s.push_back(Seg{cuts[k], cuts[k + 1], ops[k]});
  return s;
}

// Shifts a field list left (shl) or right (lshr) by C within N bits; the fields shifted out are dropped
// and the bits shifted in are a zero field. A quantum field cut by the edge is unimplemented (piece).
Segs shiftSegs(LoweringContext &ctx, const Segs &in, unsigned C, unsigned N, bool left, const Value *at);

// The fields of an operand of a packing instruction: a packed value, a constant, or a classical value
// seen through its own zext / shl / or-disjoint structure (159's classical p.b), else one classical field.
Segs orSegs(LoweringContext &ctx, const Segs &a, const Segs &b, const Value *at);

Segs segsOf(LoweringContext &ctx, const Value *w, unsigned depth = 0) {
  unsigned N = widthOf(w);
  if (auto *c = dyn_cast<ConstantInt>(w))
    return {Seg{0, N, Operand{const_cast<ConstantInt *>(c), false}}};
  if (fieldwise(ctx, w))
    return segsOfPacked(ctx, w);
  if (isQ(ctx, w))
    return {Seg{0, N, ctx.operand(w)}};
  if (depth < 16) {
    if (const ZExtInst *z = intZext(w)) {
      unsigned M = widthOf(z->getOperand(0));
      return {Seg{0, M, ctx.operand(z->getOperand(0))}, zeroSeg(ctx, M, N)};
    }
    const APInt *C;
    const Value *x;
    if (match(w, m_Shl(m_Value(x), m_APInt(C))) && C->ult(N))
      return shiftSegs(ctx, segsOf(ctx, x, depth + 1), unsigned(C->getZExtValue()), N, true, w);
    const Value *y;
    if (match(w, m_DisjointOr(m_Value(x), m_Value(y))))
      return orSegs(ctx, segsOf(ctx, x, depth + 1), segsOf(ctx, y, depth + 1), w);
  }
  return {Seg{0, N, ctx.operand(w)}};
}

// The piece [lo, hi) of the field s: s itself, a zero, or a classical lshr/trunc of it.
Operand piece(LoweringContext &ctx, const Seg &s, unsigned lo, unsigned hi, const Value *at) {
  if (lo == s.lo && hi == s.hi)
    return s.op;
  if (lo < s.lo || hi > s.hi)
    internalError("spine: a piece outside its packed field", at);
  if (s.zero())
    return Operand{ConstantInt::get(iTy(ctx, hi - lo), 0), false};
  if (s.op.handle) {
    // A quantum field read in part (the program's lshr / trunc of the coercion, rule 4): lshr_hl by the
    // offset, then trunc to the piece's width, each a fresh rail.
    Operand v = s.op;
    unsigned W = s.hi - s.lo;
    if (lo > s.lo) {
      abi::TemplateSpec sh;
      sh.op = "lshr";
      sh.w = RailType{Kind::Int, W};
      sh.shape = "hl";
      v = Operand{ctx.emitTemplate(sh, {v, Operand{ConstantInt::get(iTy(ctx, W), lo - s.lo), false}}), true};
    }
    if (hi - lo < W) {
      abi::TemplateSpec tr;
      tr.op = "trunc";
      tr.w = RailType{Kind::Int, W};
      tr.to = RailType{Kind::Int, hi - lo};
      v = Operand{ctx.emitTemplate(tr, {v}), true};
    }
    return v;
  }
  IRBuilder<> &B = shared(ctx).B;
  Value *v = s.op.v;
  if (lo > s.lo)
    v = B.CreateLShr(v, lo - s.lo);
  if (hi - lo < s.hi - s.lo)
    v = B.CreateTrunc(v, iTy(ctx, hi - lo));
  return Operand{v, false};
}

// The classical i(hi-lo) of classical fields within [lo, hi): or of each non-zero field shifted to its place.
Value *join(LoweringContext &ctx, ArrayRef<Seg> parts, unsigned lo, unsigned hi) {
  IRBuilder<> &B = shared(ctx).B;
  IntegerType *T = iTy(ctx, hi - lo);
  Value *acc = nullptr;
  for (const Seg &t : parts) {
    if (t.op.handle)
      internalError("spine: a quantum field joined classically", t.op.v);
    if (t.zero())
      continue;
    Value *p = t.op.v;
    if (p->getType() != T)
      p = B.CreateZExt(p, T);
    if (t.lo > lo)
      p = B.CreateShl(p, t.lo - lo);
    acc = acc ? B.CreateOr(acc, p) : p;
  }
  return acc ? acc : ConstantInt::get(T, 0);
}

// The i(hi-lo) of fields within [lo, hi) of which some are quantum (rule 4 on the coercion's bit moves):
// the classical ones joined classically, each quantum one zext'ed to the width and shl'ed to its place,
// all or'ed (disjoint bits) into fresh rails.
Operand joinQuantum(LoweringContext &ctx, ArrayRef<Seg> parts, unsigned lo, unsigned hi) {
  unsigned W = hi - lo;
  SmallVector<Seg, 4> cls;
  Operand acc{nullptr, false};
  auto orIn = [&](Operand x) {
    if (!acc.v) {
      acc = x;
      return;
    }
    abi::TemplateSpec o;
    o.op = "or";
    o.w = RailType{Kind::Int, W};
    if (!acc.handle)
      std::swap(acc, x);
    o.shape = x.handle ? "" : "hl";
    acc = Operand{ctx.emitTemplate(o, {acc, x}), true};
  };
  for (const Seg &t : parts) {
    if (!t.op.handle) {
      cls.push_back(t);
      continue;
    }
    Operand v = t.op;
    if (t.hi - t.lo < W) {
      abi::TemplateSpec z;
      z.op = "zext";
      z.w = RailType{Kind::Int, t.hi - t.lo};
      z.to = RailType{Kind::Int, W};
      v = Operand{ctx.emitTemplate(z, {v}), true};
    }
    if (t.lo > lo) {
      abi::TemplateSpec sh;
      sh.op = "shl";
      sh.w = RailType{Kind::Int, W};
      sh.shape = "hl";
      v = Operand{ctx.emitTemplate(sh, {v, Operand{ConstantInt::get(iTy(ctx, W), t.lo - lo), false}}), true};
    }
    orIn(v);
  }
  if (any_of(cls, [](const Seg &t) { return !t.zero(); }))
    orIn(Operand{join(ctx, cls, lo, hi), false});
  if (!acc.v)
    internalError("spine: joinQuantum of no quantum field");
  return acc;
}

// The bits [lo, hi) of the fields `in`: a piece of one field, or the join of the pieces it spans.
Operand rangeOf(LoweringContext &ctx, const Segs &in, unsigned lo, unsigned hi, const Value *at) {
  const Seg *s = nullptr;
  for (const Seg &t : in)
    if (t.lo <= lo && lo < t.hi)
      s = &t;
  if (!s)
    internalError("spine: packed fields that do not cover the value", at);
  if (hi <= s->hi)
    return piece(ctx, *s, lo, hi, at);
  SmallVector<Seg, 4> parts;
  for (const Seg &t : in) {
    if (t.hi <= lo || t.lo >= hi)
      continue;
    unsigned a = std::max(t.lo, lo), b = std::min(t.hi, hi);
    parts.push_back(Seg{a, b, piece(ctx, t, a, b, at)});
  }
  if (any_of(parts, [](const Seg &t) { return t.op.handle; }))
    return joinQuantum(ctx, parts, lo, hi);
  return Operand{join(ctx, parts, lo, hi), false};
}

// The fields at the boundaries `cuts` (each piece of one field of `in`, or the join of the pieces).
Segs reshape(LoweringContext &ctx, const Segs &in, ArrayRef<unsigned> cuts, const Value *at) {
  Segs out;
  for (unsigned k = 0; k + 1 < cuts.size(); ++k)
    out.push_back(Seg{cuts[k], cuts[k + 1], rangeOf(ctx, in, cuts[k], cuts[k + 1], at)});
  return out;
}

SmallVector<unsigned, 4> cutsOf(const Segs &s) {
  SmallVector<unsigned, 4> c;
  for (const Seg &t : s)
    c.push_back(t.lo);
  if (!s.empty())
    c.push_back(s.back().hi);
  return c;
}

Segs shiftSegs(LoweringContext &ctx, const Segs &in, unsigned C, unsigned N, bool left, const Value *at) {
  if (C == 0)
    return in;
  // Split the field that straddles the shifted-out boundary (N - C for shl, C for lshr).
  unsigned edge = left ? N - C : C;
  SmallVector<unsigned, 4> cuts = cutsOf(in);
  if (!is_contained(cuts, edge)) {
    cuts.push_back(edge);
    llvm::sort(cuts);
  }
  Segs split = reshape(ctx, in, cuts, at);
  Segs out;
  if (left)
    out.push_back(zeroSeg(ctx, 0, C));
  for (const Seg &t : split) {
    bool kept = left ? t.hi <= N - C : t.lo >= C;
    if (!kept)
      continue;   // shifted out: the result does not read it
    out.push_back(left ? Seg{t.lo + C, t.hi + C, t.op} : Seg{t.lo - C, t.hi - C, t.op});
  }
  if (!left)
    out.push_back(zeroSeg(ctx, N - C, N));
  return out;
}

// Adjacent zero fields merged into one.
Segs coalesce(LoweringContext &ctx, const Segs &in) {
  Segs out;
  for (const Seg &t : in) {
    if (!out.empty() && out.back().zero() && t.zero()) {
      out.back() = zeroSeg(ctx, out.back().lo, t.hi);
      continue;
    }
    out.push_back(t);
  }
  return out;
}

// or disjoint: the union of two field lists (no bit set in both). Where one side is zero the other
// side's field is taken; two classical pieces are or'ed classically; two non-zero pieces of which one
// is quantum overlap and are unimplemented.
Segs orSegs(LoweringContext &ctx, const Segs &a, const Segs &b, const Value *at) {
  SmallVector<unsigned, 8> cuts;
  for (unsigned c : cutsOf(a))
    cuts.push_back(c);
  for (unsigned c : cutsOf(b))
    cuts.push_back(c);
  llvm::sort(cuts);
  cuts.erase(std::unique(cuts.begin(), cuts.end()), cuts.end());
  // Pieces of zero or classical fields only: a quantum field must not be cut by the other side's
  // boundaries unless the other side is zero across it (then take it whole).
  Segs out;
  auto findSeg = [&](const Segs &s, unsigned lo) -> const Seg & {
    for (const Seg &t : s)
      if (t.lo <= lo && lo < t.hi)
        return t;
    internalError("spine: packed fields that do not cover the value", at);
  };
  unsigned lo = 0, N = cuts.back();
  while (lo < N) {
    const Seg &x = findSeg(a, lo), &y = findSeg(b, lo);
    // Take a quantum field whole when the other side is zero across it.
    const Seg *q = x.op.handle ? &x : y.op.handle ? &y : nullptr;
    if (q && q->lo == lo) {
      const Segs &other = q == &x ? b : a;
      bool clear = none_of(other, [&](const Seg &t) { return t.hi > q->lo && t.lo < q->hi && !t.zero(); });
      if (clear) {
        out.push_back(*q);
        lo = q->hi;
        continue;
      }
    }
    // Piece by piece: a zero side takes the other; two classical pieces or classically; a quantum piece
    // with a non-zero other side is the or template (rule 4; disjoint bits, so the or is their union).
    unsigned hi = std::min(x.hi, y.hi);
    Operand px = piece(ctx, x, lo, hi, at), py = piece(ctx, y, lo, hi, at);
    Seg s{lo, hi, px};
    if (Seg{lo, hi, px}.zero())
      s.op = py;
    else if (!Seg{lo, hi, py}.zero())
      s.op = px.handle || py.handle ? joinQuantum(ctx, {Seg{lo, hi, px}, Seg{lo, hi, py}}, lo, hi)
                                    : Operand{shared(ctx).B.CreateOr(px.v, py.v), false};
    out.push_back(s);
    lo = hi;
  }
  return coalesce(ctx, out);
}

// Is U a reader that takes a packed value field-wise: a call argument whose callee unpacks the formal
// into several fields (taint's mask splits it the same way), a return whose clone returns fields (rule 26:
// the returns' packings give more than one field and the clone is no table clone, which returns one rail;
// any other return reads one rail, and its or disjoint is rule 4's template: 113's `_t_ctl`, where the measured
// bits are rails; so does an own symbol's, rule 19: one handle in the C return type, cq-stmvu), an aggregate insert
// (the returned { i64, double } of 166)?
bool fieldConsumer(LoweringContext &ctx, const Use &U, bool orRooted) {
  const User *u = U.getUser();
  if (auto *CB = dyn_cast<CallBase>(u)) {
    const Function *F = CB->getCalledFunction();
    if (!F || F->isIntrinsic() || hostCallee(*F) || !CB->isArgOperand(&U))
      return false;
    unsigned i = CB->getArgOperandNo(&U);
    return i < F->arg_size() && unpackCuts(F->getArg(i)).size() > 2;
  }
  if (isa<ReturnInst>(u))
    return orRooted && !ctx.S.table && !ctx.S.wholeIntResult() && resultIntCuts(*ctx.S.F).size() > 2;
  if (isa<InsertValueInst>(u) && U.getOperandNo() == 1)
    return orRooted;
  return false;
}

// Does the quantum integer instruction I pack fields (it is not lowered as a template)? An or
// disjoint whose every use is a packing or-disjoint, a field consumer, or an unpacking read (a trunc,
// an lshr by a constant); a zext or a shl by a constant whose every use is a packing shl / or
// disjoint or a call argument the callee unpacks.
bool packs(LoweringContext &ctx, const Instruction &I, unsigned depth = 0) {
  if (!I.getType()->isIntegerTy() || depth > 16)
    return false;
  unsigned N = widthOf(&I);
  bool isOr = false;
  if (auto *bo = dyn_cast<PossiblyDisjointInst>(&I); bo && bo->getOpcode() == Instruction::Or)
    isOr = bo->isDisjoint();
  bool isShl = false;
  const APInt *C;
  if (match(&I, m_Shl(m_Value(), m_APInt(C))))
    isShl = C->ult(N);
  bool isZext = intZext(&I) != nullptr;
  if (!isOr && !isShl && !isZext)
    return false;
  if (I.use_empty())
    return false;
  for (const Use &U : I.uses()) {
    auto *u = dyn_cast<Instruction>(U.getUser());
    if (!u)
      return false;
    if (fieldConsumer(ctx, U, isOr))
      continue;
    if (auto *ob = dyn_cast<PossiblyDisjointInst>(u); ob && ob->getOpcode() == Instruction::Or && ob->isDisjoint()) {
      if (!packs(ctx, *u, depth + 1))
        return false;
      continue;
    }
    if (U.getOperandNo() == 0 && match(u, m_Shl(m_Value(), m_APInt(C))) && C->ult(N)) {
      if (!packs(ctx, *u, depth + 1))
        return false;
      continue;
    }
    if (isOr && isa<TruncInst>(u))
      continue;
    if (isOr && U.getOperandNo() == 0 && match(u, m_LShr(m_Value(), m_APInt(C))))
      continue;
    return false;
  }
  return true;
}

// Binds the result of an unpacking read: one field, or a packed value, or a classical whole.
void bindSegs(LoweringContext &ctx, const Value *orig, const Segs &s) {
  SmallVector<Operand, 4> ops;
  for (const Seg &t : s)
    ops.push_back(t.op);
  bindPacked(ctx, orig, cutsOf(s), ops);
}

} // namespace

SmallVector<unsigned, 4> unpackCuts(const Value *v) {
  unsigned W = widthOf(v);
  SmallVector<unsigned, 4> b{0};
  if (!W)
    return {};
  SmallVector<unsigned, 4> cuts, truncs, shifts;
  bool other = false;
  for (const User *U : v->users()) {
    const APInt *C;
    if (auto *T = dyn_cast<TruncInst>(U))
      truncs.push_back(widthOf(T));
    else if (match(U, m_LShr(m_Specific(v), m_APInt(C))) || match(U, m_AShr(m_Specific(v), m_APInt(C))))
      shifts.push_back(unsigned(C->getZExtValue()));
    else
      other = true;
  }
  // As taint's mask splits an integer formal (Taint.cpp intFields): a cut at C when both a trunc to C
  // bits and a shift by C read the value, C a whole number of bytes.
  if (!other)
    for (unsigned s : shifts)
      if (s % 8 == 0 && s > 0 && s < W && is_contained(truncs, s))
        cuts.push_back(s);
  llvm::sort(cuts);
  cuts.erase(std::unique(cuts.begin(), cuts.end()), cuts.end());
  b.append(cuts.begin(), cuts.end());
  b.push_back(W);
  return b;
}

void bindPacked(LoweringContext &ctx, const Value *orig, ArrayRef<unsigned> cuts, ArrayRef<Operand> fields) {
  Shared &sh = shared(ctx);
  if (cuts.size() != fields.size() + 1 || fields.empty())
    internalError("spine: bindPacked with another field count than its boundaries", orig);
  if (fields.size() == 1) {
    bindOperand(ctx, orig, fields.front());
    return;
  }
  if (none_of(fields, [](const Operand &o) { return o.handle; })) {
    // Every field classical: the value is one classical iN.
    SmallVector<Seg, 4> s;
    for (unsigned k = 0; k < fields.size(); ++k)
      s.push_back(Seg{cuts[k], cuts[k + 1], fields[k]});
    bindOperand(ctx, orig, Operand{join(ctx, s, 0, cuts.back()), false});
    return;
  }
  ctx.bindFields(orig, fields);
  sh.packs[orig] = SmallVector<unsigned, 4>(cuts.begin(), cuts.end());
}

// Rule 26: a reader that takes the packed integer whole (cq_measure of musl div's coerced result): the fields joined,
// by ordinary templates (rule 4).
Operand packedWhole(LoweringContext &ctx, const Value *v) {
  if (!fieldwise(ctx, v))
    internalError("spine: a whole read of a value that is not packed", v);
  Shared &sh = shared(ctx);
  if (auto m = sh.packedForPhi.find(v); m != sh.packedForPhi.end()) {
    auto b = sh.binds.find(v);
    if (b != sh.binds.end() && b->second.size() == m->second.first.size() &&
        equal(b->second, m->second.first, [](const Operand &o, Value *f) { return o.v == f; }))
      return m->second.second;
  }
  return rangeOf(ctx, segsOfPacked(ctx, v), 0, widthOf(v), v);
}

// Rule 26 (cq-zo7ja): a classical merge reads its incoming values at the join (merge clean-ups, rule 6's stops), where an arm's
// fields do not reach. A single rail read there is only looked at; a whole read would emit its joining templates over the phis
// of the fields, poison on the other arm. So the whole a phi reads is made once, right after the value.
void mintPackedForPhi(LoweringContext &ctx, const Instruction &I) {
  Shared &sh = shared(ctx);
  auto b = sh.binds.find(&I);
  if (!I.getType()->isIntegerTy() || b == sh.binds.end() || b->second.size() < 2 || !fieldwise(ctx, &I) ||
      none_of(I.users(), [](const User *U) { return isa<PHINode>(U); }))
    return;
  sh.packedForPhi.erase(&I);
  Operand whole = packedWhole(ctx, &I);
  SmallVector<Value *, 2> fields;
  for (const Operand &o : sh.binds.find(&I)->second)
    fields.push_back(o.v);
  sh.packedForPhi[&I] = {fields, whole};
}

SmallVector<Operand, 4> packFieldsOf(LoweringContext &ctx, Operand whole, unsigned W, ArrayRef<unsigned> cuts,
                                     const Value *at) {
  if (cuts.size() < 2 || cuts.front() != 0 || cuts.back() != W)
    internalError("spine: packFieldsOf at boundaries that are not the value's", at);
  Segs s = reshape(ctx, Segs{Seg{0, W, whole}}, cuts, at);
  SmallVector<Operand, 4> ops;
  for (const Seg &t : s)
    ops.push_back(t.op);
  return ops;
}

SmallVector<Operand, 4> packFields(LoweringContext &ctx, const Value *v, ArrayRef<unsigned> cuts) {
  if (!v->getType()->isIntegerTy() || cuts.size() < 2 || cuts.front() != 0 || cuts.back() != widthOf(v))
    internalError("spine: packFields at boundaries that are not the value's", v);
  Segs s = reshape(ctx, segsOf(ctx, v), cuts, v);
  SmallVector<Operand, 4> ops;
  for (const Seg &t : s)
    ops.push_back(t.op);
  return ops;
}

bool lowerPack(LoweringContext &ctx, Instruction &I) {
  if (!I.getType()->isIntegerTy())
    return false;
  unsigned N = widthOf(&I);
  const APInt *C;

  // Unpacking reads of a packed value.
  if (auto *t = dyn_cast<TruncInst>(&I)) {
    const Value *w = t->getOperand(0);
    if (!fieldwise(ctx, w))
      return false;
    bindOperand(ctx, &I, rangeOf(ctx, segsOfPacked(ctx, w), 0, N, &I));
    return true;
  }
  if (match(&I, m_LShr(m_Value(), m_APInt(C)))) {
    const Value *w = I.getOperand(0);
    if (!fieldwise(ctx, w))
      return false;
    if (!C->ult(N))
      return false;   // poison (outside the domain): the template's
    bindSegs(ctx, &I, coalesce(ctx, shiftSegs(ctx, segsOfPacked(ctx, w), unsigned(C->getZExtValue()), N, false, &I)));
    return true;
  }

  // Packing instructions.
  if (!packs(ctx, I))
    return false;
  Segs s;
  if (const ZExtInst *z = intZext(&I)) {
    unsigned M = widthOf(z->getOperand(0));
    s = {Seg{0, M, ctx.operand(z->getOperand(0))}, zeroSeg(ctx, M, N)};
  } else if (match(&I, m_Shl(m_Value(), m_APInt(C)))) {
    s = shiftSegs(ctx, segsOf(ctx, I.getOperand(0)), unsigned(C->getZExtValue()), N, true, &I);
  } else {
    s = orSegs(ctx, segsOf(ctx, I.getOperand(0)), segsOf(ctx, I.getOperand(1)), &I);
  }
  s = coalesce(ctx, s);
  // A call argument the callee unpacks takes the callee's fields (taint's mask digits).
  for (const Use &U : I.uses()) {
    auto *CB = dyn_cast<CallBase>(U.getUser());
    if (!CB || !fieldConsumer(ctx, U, true))
      continue;
    SmallVector<unsigned, 4> want = unpackCuts(CB->getCalledFunction()->getArg(CB->getArgOperandNo(&U)));
    // One reader: bound at its layout. Several readers at several layouts: bound at the packing's own,
    // and each reader takes its fields at its layout (packFields reshapes at the read).
    if (cutsOf(s) != want && I.getNumUses() == 1)
      s = reshape(ctx, s, want, &I);
  }
  bindSegs(ctx, &I, s);
  return true;
}

} // namespace cq::spine

namespace cq::spine {

SmallVector<unsigned, 4> packedCuts(const Value *v) {
  unsigned W = widthOf(v);
  if (!W)
    return {};
  // As taint's resultQuantum splits a packed result: or disjoint (shl (zext X), C), (zext Y), C a whole
  // number of bytes.
  const Value *X, *Y;
  const APInt *C;
  if ((match(v, m_DisjointOr(m_Shl(m_ZExt(m_Value(X)), m_APInt(C)), m_ZExt(m_Value(Y)))) ||
       match(v, m_DisjointOr(m_ZExt(m_Value(Y)), m_Shl(m_ZExt(m_Value(X)), m_APInt(C))))) &&
      C->ult(W) && C->getZExtValue() % 8 == 0 && C->getZExtValue() > 0)
    return {0, unsigned(C->getZExtValue()), W};
  return {0, W};
}

} // namespace cq::spine

namespace cq::spine {

namespace {
void scalarLeaves(Type *t, SmallVectorImpl<Type *> &out) {
  if (auto *st = dyn_cast<StructType>(t)) {
    for (Type *e : st->elements())
      scalarLeaves(e, out);
  } else if (auto *a = dyn_cast<ArrayType>(t)) {
    for (uint64_t j = 0; j < a->getNumElements(); ++j)
      scalarLeaves(a->getElementType(), out);
  } else if (auto *v = dyn_cast<FixedVectorType>(t)) {
    for (unsigned j = 0; j < v->getNumElements(); ++j)
      out.push_back(v->getElementType());
  } else {
    out.push_back(t);
  }
}

// The first flattened leaf of the index path idx into t.
unsigned leafIndexOf(Type *t, ArrayRef<unsigned> idx) {
  unsigned first = 0;
  for (unsigned i : idx) {
    for (unsigned j = 0; j < i; ++j) {
      Type *e = t->isStructTy() ? t->getStructElementType(j) : t->getArrayElementType();
      SmallVector<Type *, 4> l;
      scalarLeaves(e, l);
      first += unsigned(l.size());
    }
    t = t->isStructTy() ? t->getStructElementType(i) : t->getArrayElementType();
  }
  return first;
}
} // namespace

SmallVector<SmallVector<unsigned, 4>, 4> resultLeafCuts(const Function &F) {
  Type *rt = F.getReturnType();
  SmallVector<SmallVector<unsigned, 4>, 4> out;
  if (!rt->isStructTy() && !rt->isArrayTy())
    return out;
  SmallVector<Type *, 4> leaves;
  scalarLeaves(rt, leaves);
  for (Type *t : leaves)
    out.push_back(t->isIntegerTy() ? SmallVector<unsigned, 4>{0, t->getIntegerBitWidth()} : SmallVector<unsigned, 4>{});
  // CR rule 26 (cq-jkq8): one rail per field of every packing a return makes, the union of the returns'
  // boundaries; a return that packs a leaf coarser (or not at all) is split there (emitCloneFields).
  for (const BasicBlock &BB : F) {
    auto *RI = dyn_cast<ReturnInst>(BB.getTerminator());
    if (!RI || !RI->getReturnValue())
      continue;
    SmallVector<bool, 8> seen(leaves.size(), false);
    for (const Value *v = RI->getReturnValue(); auto *iv = dyn_cast<InsertValueInst>(v); v = iv->getAggregateOperand()) {
      const Value *ins = iv->getInsertedValueOperand();
      if (!ins->getType()->isIntegerTy())
        continue;
      unsigned k = leafIndexOf(rt, iv->getIndices());
      if (k >= leaves.size() || seen[k])
        continue;   // a later insert of the same leaf wins
      seen[k] = true;
      out[k] = unionCuts(out[k], packedCuts(ins));
    }
  }
  return out;
}

unsigned resultLeafIndex(Type *t, ArrayRef<unsigned> idx) { return leafIndexOf(t, idx); }

SmallVector<unsigned, 4> unionCuts(ArrayRef<unsigned> a, ArrayRef<unsigned> b) {
  if (a.empty())
    return SmallVector<unsigned, 4>(b.begin(), b.end());
  SmallVector<unsigned, 4> c(a.begin(), a.end());
  for (unsigned x : b)
    if (!is_contained(c, x))
      c.push_back(x);
  llvm::sort(c);
  return c;
}

SmallVector<unsigned, 4> resultIntCuts(const Function &F) {
  SmallVector<unsigned, 4> c;
  for (const BasicBlock &BB : F)
    if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator()); RI && RI->getReturnValue())
      c = unionCuts(c, packedCuts(RI->getReturnValue()));
  return c;
}

SmallVector<Type *, 4> resultFieldTypes(const Function &F) {
  SmallVector<Type *, 4> leaves, out;
  scalarLeaves(F.getReturnType(), leaves);
  SmallVector<SmallVector<unsigned, 4>, 4> cuts = resultLeafCuts(F);
  for (unsigned k = 0; k < leaves.size(); ++k) {
    if (k < cuts.size() && cuts[k].size() > 2) {
      for (unsigned j = 0; j + 1 < cuts[k].size(); ++j)
        out.push_back(IntegerType::get(F.getContext(), cuts[k][j + 1] - cuts[k][j]));
      continue;
    }
    out.push_back(leaves[k]);
  }
  return out;
}

} // namespace cq::spine
