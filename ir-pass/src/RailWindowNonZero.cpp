// RailWindowNonZero.cpp — bd `test_C_libtooling-01po.19.34.4` / `.7` (R11
// rounds 1-2): is a window cell difference nonzero on every iteration of the
// loop it recurs in? Split out of RailWindowAlias.cpp (400-line rule); its one
// caller is `railWindowDistinct`. Contract in RailWindowAlias.h.

#include "RailWindowAlias.h"

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

// bd 01po.19.34.4 (R11 round 1 C-F1) — is the cell difference D nonzero on
// EVERY iteration of the loop it recurs in? `isKnownNonZero` asks about all
// values of the recurrence's type and so cannot see a TRIANGULAR nest
// (`for i { for j < i { if (q[j]) Ry(q[i]) } }`: D = {-i,+,1}<j-loop> runs
// -i .. -1, never 0). Answered with SCEV's own machinery, not a shape.
//
// THE END-POINT ARGUMENT (one spelling, `monotoneEnds`): an affine recurrence
// {S,+,c}<L> with a constant step whose whole walk |c| * maxBTC is shorter
// than half its ring cannot wrap (flags or not), so every value it takes on an
// iteration of L lies between S and its value End at L's symbolic-max
// backedge-taken count (the real last iteration ends no further). The trip
// bound is read UNDER L's guards (`applyLoopGuards`), and the signs of S and
// End are asked AT L's ENTRY (`isLoopEntryGuardedByCond`, bd 01po.19.34.7, R11
// round 2 rN2-F1): the values only matter on trips that enter L, so an outer
// trip whose guard skips L (`for i = 0..` with `j < i`: S = -i is 0 there) is
// not asked.
namespace {

bool signAtEntry(ScalarEvolution &SE, const Loop *L, const SCEV *X,
                 ICmpInst::Predicate P, const SCEV *K);

// `X != 0` at L's entry, asked of X and of -X: a guard spelled on the outer
// counter (`i == 0` skips the inner loop) speaks about i, not about -i, and
// the implication engine does not negate through `ne`.
bool nonZeroAtEntry(ScalarEvolution &SE, const Loop *L, const SCEV *X) {
  const SCEV *Z = SE.getZero(X->getType());
  return signAtEntry(SE, L, X, ICmpInst::ICMP_NE, Z) ||
         signAtEntry(SE, L, SE.getNegativeSCEV(X), ICmpInst::ICMP_NE, Z);
}

bool signAtEntry(ScalarEvolution &SE, const Loop *L, const SCEV *X,
                 ICmpInst::Predicate P, const SCEV *K) {
  // Three readings of the same fact, all LLVM's: unconditionally; implied by
  // a condition guarding L's entry; and with L's guards folded INTO X
  // (`applyLoopGuards` turns the guard `i != 0` on `i >= 0` into umax(1, i),
  // which the implication engine does not derive from `ne`).
  return SE.isKnownPredicate(P, X, K) ||
         SE.isLoopEntryGuardedByCond(L, P, X, K) ||
         SE.isKnownPredicate(P, SE.applyLoopGuards(X, L), K);
}

// The UPPER BOUND on L's backedge-taken count the end-point argument walks to:
// SCEV's symbolic max (a list, so a further bound can be added without
// touching the callers; per-exit counts were tried for bd 01po.19.34.8 and
// were not needed — the at-use peel below covers the top-tested `break` loop).
SmallVector<const SCEV *, 4> tripBounds(ScalarEvolution &SE, const Loop *L) {
  SmallVector<const SCEV *, 4> Out;
  const SCEV *Max = SE.getSymbolicMaxBackedgeTakenCount(L);
  if (!isa<SCEVCouldNotCompute>(Max))
    Out.push_back(Max);
  return Out;
}

// (S, End) of an affine, constant-step recurrence whose walk to the trip bound
// `Max` cannot wrap, or {nullptr, nullptr}.
std::pair<const SCEV *, const SCEV *> monotoneEnds(ScalarEvolution &SE,
                                                   const SCEVAddRecExpr *AR,
                                                   const SCEV *Max) {
  if (!AR->isAffine() || !AR->getType()->isIntegerTy())
    return {nullptr, nullptr};
  const auto *C = dyn_cast<SCEVConstant>(AR->getStepRecurrence(SE));
  if (!C || C->getAPInt().isZero())
    return {nullptr, nullptr};
  const Loop *L = AR->getLoop();
  unsigned W = AR->getType()->getIntegerBitWidth();
  APInt MaxU = SE.getUnsignedRangeMax(SE.applyLoopGuards(Max, L));
  // The symbolic max is only ever USED on trips that enter L; on the others
  // (`for i = 0..`, `j < i` at i = 0: max = i - 1 = -1) it may be anything.
  // So bound it AT ENTRY too: 0 <= max <= SCEV's constant max, both asked
  // under L's entry guards (bd 01po.19.34.7, rN2-F1).
  if (const auto *CM =
          dyn_cast<SCEVConstant>(SE.getConstantMaxBackedgeTakenCount(L)))
    if (CM->getType() == Max->getType() &&
        CM->getAPInt().getBitWidth() == MaxU.getBitWidth() &&
        CM->getAPInt().ult(MaxU) &&
        signAtEntry(SE, L, Max, ICmpInst::ICMP_SGE, SE.getZero(Max->getType())) &&
        signAtEntry(SE, L, Max, ICmpInst::ICMP_SLE, CM))
      MaxU = CM->getAPInt();
  if (MaxU.getActiveBits() > W)
    return {nullptr, nullptr};
  bool Ov = false;
  APInt Walk = MaxU.zextOrTrunc(W).umul_ov(C->getAPInt().abs(), Ov);
  if (Ov || Walk.isNegative())  // |c| * max >= 2^(W-1)
    return {nullptr, nullptr};
  const SCEV *End =
      AR->evaluateAtIteration(SE.getTruncateOrZeroExtend(Max, AR->getType()), SE);
  if (isa<SCEVCouldNotCompute>(End))
    return {nullptr, nullptr};
  return {AR->getStart(), End};
}

// Both ends of the walk inside [Lo, Hi] (signed) at L's entry: every value is.
bool walkWithin(ScalarEvolution &SE, const SCEVAddRecExpr *AR, const SCEV *Lo,
                const SCEV *Hi) {
  const Loop *L = AR->getLoop();
  for (const SCEV *Max : tripBounds(SE, L)) {
    auto [S, End] = monotoneEnds(SE, AR, Max);
    if (S && signAtEntry(SE, L, S, ICmpInst::ICMP_SGE, Lo) &&
        signAtEntry(SE, L, End, ICmpInst::ICMP_SGE, Lo) &&
        signAtEntry(SE, L, S, ICmpInst::ICMP_SLE, Hi) &&
        signAtEntry(SE, L, End, ICmpInst::ICMP_SLE, Hi))
      return true;
  }
  return false;
}

// bd 01po.19.34.7 (R11 round 2 rN2-F2) — the down-counting inner loop: -O1
// spells the cell index `and i64 %j, 4294967295`, i.e. zext(trunc(j)), and
// SCEV folds the trunc into a NARROW recurrence, so D is not an addrec. A
// zero-extension is the identity on the values its operand takes when a WIDE
// recurrence W with trunc(W) == operand (SCEV's own uniqued fold, so W names
// the same bits) stays in [0, 2^w - 1] on every entered trip of its loop (the
// end-point argument, `walkWithin`): zext(trunc W) == W there. The cast is
// replaced by W; anything unproven is kept and the caller fails closed.
const SCEV *wideCounterpart(ScalarEvolution &SE, const SCEV *N, Type *WideT,
                            unsigned Depth = 0) {
  if (Depth > 4)
    return nullptr;
  if (const auto *T = dyn_cast<SCEVTruncateExpr>(N))
    return T->getOperand()->getType() == WideT ? T->getOperand() : nullptr;
  if (isa<SCEVConstant>(N))
    return SE.getSignExtendExpr(N, WideT);
  if (const auto *AR = dyn_cast<SCEVAddRecExpr>(N)) {
    if (!AR->isAffine() || !isa<SCEVConstant>(AR->getStepRecurrence(SE)))
      return nullptr;
    const SCEV *St = wideCounterpart(SE, AR->getStart(), WideT, Depth + 1);
    if (!St)
      return nullptr;
    return SE.getAddRecExpr(St, SE.getSignExtendExpr(AR->getStepRecurrence(SE), WideT),
                            AR->getLoop(), SCEV::FlagAnyWrap);
  }
  return nullptr;
}

class PeelIdentityZext : public SCEVRewriteVisitor<PeelIdentityZext> {
  const Instruction *Ctx;

public:
  PeelIdentityZext(ScalarEvolution &SE, const Instruction *Ctx)
      : SCEVRewriteVisitor(SE), Ctx(Ctx) {}
  const SCEV *visitZeroExtendExpr(const SCEVZeroExtendExpr *Z) {
    const SCEV *Op = Z->getOperand();
    unsigned w = Op->getType()->getIntegerBitWidth();
    Type *WideT = Z->getType();
    if (w >= 63)
      return Z;
    const SCEV *W = wideCounterpart(SE, Op, WideT);
    if (!W || SE.getTruncateExpr(W, Op->getType()) != Op)
      return Z;  // not provably the same bits
    const SCEV *Zero = SE.getZero(WideT);
    const SCEV *Top = SE.getConstant(WideT, (1ull << w) - 1);
    if (const auto *AR = dyn_cast<SCEVAddRecExpr>(W))
      if (walkWithin(SE, AR, Zero, Top))
        return AR;
    // bd 01po.19.34.8 (N1): AT the use. A top-tested loop (`for (j = i - 1;
    // j >= 0; j--) { …; if (j == 2) break; }` keeps its exit test in the
    // header) computes the index once more than the body uses it, so the walk
    // over the whole trip count reaches -1; the body block, though, runs only
    // under the header's `j > 0`. SCEV's dominating-condition query at the use
    // proves W in [0, 2^w - 1] there.
    // `W >= 0` is also asked as `W + 1 > 0` (the header's `j > 0` speaks of
    // W + 1; no overflow, W <= Top is asked too).
    if (Ctx && SE.isKnownPredicateAt(ICmpInst::ICMP_SLE, W, Top, Ctx) &&
        (SE.isKnownPredicateAt(ICmpInst::ICMP_SGE, W, Zero, Ctx) ||
         SE.isKnownPredicateAt(ICmpInst::ICMP_SGT,
                               SE.getAddExpr(W, SE.getOne(WideT)), Zero, Ctx)))
      return W;
    return Z;
  }
};

}  // namespace

bool railWindowNonZeroOverLoop(ScalarEvolution &SE, const SCEV *D,
                               const Instruction *Ctx) {
  if (const auto *AR0 = dyn_cast<SCEVAddRecExpr>(D); !AR0)
    D = PeelIdentityZext(SE, Ctx).visit(D);
  // At the use: the peeled difference is strictly on one side there (SCEV's
  // dominating conditions plus its induction reasoning on the recurrence).
  const SCEV *Zero0 = SE.getZero(D->getType());
  if (Ctx && (SE.isKnownPredicateAt(ICmpInst::ICMP_SLT, D, Zero0, Ctx) ||
              SE.isKnownPredicateAt(ICmpInst::ICMP_SGT, D, Zero0, Ctx)))
    return true;
  const auto *AR = dyn_cast<SCEVAddRecExpr>(D);
  if (!AR)
    return false;
  const Loop *L = AR->getLoop();
  const SCEV *Zero = SE.getZero(D->getType());
  // Strictly on one side: `< 0` directly, or `<= 0` and `!= 0` (each at entry).
  auto strict = [&](const SCEV *X, ICmpInst::Predicate Strict,
                    ICmpInst::Predicate Weak) {
    return signAtEntry(SE, L, X, Strict, Zero) ||
           (signAtEntry(SE, L, X, Weak, Zero) && nonZeroAtEntry(SE, L, X));
  };
  for (const SCEV *Max : tripBounds(SE, L)) {
    auto [S, End] = monotoneEnds(SE, AR, Max);
    if (S && ((strict(S, ICmpInst::ICMP_SLT, ICmpInst::ICMP_SLE) &&
               strict(End, ICmpInst::ICMP_SLT, ICmpInst::ICMP_SLE)) ||
              (strict(S, ICmpInst::ICMP_SGT, ICmpInst::ICMP_SGE) &&
               strict(End, ICmpInst::ICMP_SGT, ICmpInst::ICMP_SGE))))
      return true;
  }
  return false;
}

}  // namespace cq
