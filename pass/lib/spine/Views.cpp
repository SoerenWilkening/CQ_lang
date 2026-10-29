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
#include "SpineInternal.h"

#include "cq/Abi.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
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
    if (n && !isa<Constant>(n) && (n == assume || registerState(sh, n)))
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

  Value *R = nullptr;
  SmallVector<std::pair<unsigned, const ConstantInt *>, 2> consts;
  for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
    const Value *u = P.getIncomingValue(i);
    if (auto *c = dyn_cast<ConstantInt>(u)) {
      consts.push_back({i, c});
      continue;
    }
    Operand o;
    if (auto it = sh.views.find(u); it != sh.views.end())
      o = Operand{it->second.rail, true};
    else
      o = ctx.operand(intZext(u)->getOperand(0));   // read as a phi edge (sh.cur is P)
    if (!o.handle)
      unimplemented("spine: a rule 10 merge through a representation change with a classical non-constant "
                    "incoming (" + describe(u) + ")",
                    &P);
    if (R && o.v != R)
      unimplemented("spine: a rule 10 merge through a representation change whose incomings name different "
                    "rails (" + describe(u) + ")",
                    &P);
    R = o.v;
  }
  if (!R)
    internalError("spine: a view phi with no rail incoming", &P);

  // A constant incoming is R's value on its edge only where no prep of R ran: R was minted with that
  // literal and every cq_theta bound to R lies off the edge.
  if (!consts.empty()) {
    auto h = sh.hist.find(R);
    const ConstantInt *seed = h == sh.hist.end() ? nullptr : dyn_cast_or_null<ConstantInt>(h->second.seed);
    for (auto &[i, c] : consts) {
      if (!seed || seed->getBitWidth() != M || seed->getValue() != c->getValue().trunc(M))
        unimplemented("spine: a rule 10 merge through a representation change whose constant incoming " +
                          describe(c) + " is not its register's initial value",
                      &P);
      const Pred &e = ctx.preds().edge(P.getIncomingBlock(i), P.getParent());
      for (auto &[w, ops] : sh.binds) {
        auto *T = dyn_cast<CallInst>(w);
        const Function *F = T ? T->getCalledFunction() : nullptr;
        if (!F || !F->getName().starts_with("cq_theta_") || ops.size() != 1 || !ops.front().handle ||
            ops.front().v != R)
          continue;
        if (!(ctx.preds().block(T->getParent()) & e).isBottom())
          unimplemented("spine: a rule 10 merge through a representation change whose constant incoming " +
                            describe(c) + " arrives on an edge where " + describe(T) + " may have rotated the register",
                        &P);
      }
    }
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
    if (!narrowValue(sh, w, m))
      return false;
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
  // Narrow only what has no wide rail: a view or a skipped zext among the operands.
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
    sh.narrowXor[&I] = {sh.views.count(a) ? a : (isa<Constant>(a) ? a : intZext(a)->getOperand(0)),
                        sh.views.count(b) ? b : (isa<Constant>(b) ? b : intZext(b)->getOperand(0))};
  } else {
    spec.op = "icmp";
    spec.pred = CmpInst::getPredicateName(cmp->getPredicate()).str();
  }
  Value *r = ctx.emitTemplate(spec, {x, y}, nullptr);
  bindOperand(ctx, &I, Operand{r, true});
  return true;
}

} // namespace cq::spine
