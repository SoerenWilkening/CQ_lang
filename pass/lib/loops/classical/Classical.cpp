// Module loops-classical (cq-w1-loops-classical): CR rule 14, case 1 (classical bound, quantum body)
// and case 3 (classical bound with a quantum exit, `c || q`).
//
// Reference for the reverse replay: BennettVM.jl src/history/Replay.jl:unrun! (a history tape of the
// forward run, replayed last-in-first-out), and Bennett.jl src/bennett_transform.jl:_bennett_default
// (forward, copy-out, every forward gate replayed in reverse order).
//
// CONSTRUCTION. loops::lowerClassical(ctx, L, case) is called by the spine at L's header with the
// builder in a fresh block E (the loop entry; it runs once per activation of the loop).
//
//  Forward. The loop stays a classical loop over fresh output blocks. A quantum header phi becomes a
//  phi over handles (recordExternal, a kept role: it aliases the seed or the previous trip's rail and
//  is never resolved itself); a classical incoming becomes a seed rail allocated in E. The body is
//  walked in reverse post-order: a classical branch stays a classical branch, a quantum branch is
//  linearized (pred's lowerBranch / sw::lowerSwitch, the arms fall through, a quantum join is
//  pred's lowerMerge), a classical join of handles is a phi over handles (recordMerge, U1). Each
//  original non-phi instruction goes through the spine's lowerInstruction. A sub-loop (case 1 or
//  3) is lowered the same way inside its parent's trip, with no copy-out and no mirror of its own:
//  its reverse runs inside the parent's reverse trip (27, 139).
//  Case 3: the trip predicate a_{-1} is the flag of the header's quantum predicate (the loop sits in
//  an arm; the guard test re-rolled, 26) or a |1> seed; the exit test's quantum disjunct q gives
//  a_j = a_{j-1} & NOT q (as a_{j-1} ^ (a_{j-1} & q), for a positive q); every quantum carried value advances by
//  select(a_{j-1}, next, prev); a quantum value read after the loop that is no carried value's next
//  gets its own capture rail cap_j = select(a_{j-1}, v_j, cap_{j-1}); the loop branches on the
//  classical disjuncts only. Every body instruction is lowered under the trip rail a_{j-1}
//  (lowerInstruction's tripFlag, cq-99f7): a cq_theta / cq_phi in the trip is controlled by it. No predicate is kept: the mirror uncomputes every a_j, the last included.
//
//  Rule 6 on carried values (cq-b13w, outermost loop, Unit::planRuleSix). A carried value read only
//  by a chain of bijective updates in the header (the next value the chain's last rail, perhaps rotated
//  in place) cleans each old rail in its trip, the previous trip's register included, so the trip's
//  last rail is the register (kept, never mirrored nor copied out). Trip 0 cleans the initial rail: a
//  seed minted for the loop, this function's own rail when nothing reads it once the loop is entered
//  (lcw-h2 c2: the register before the loop), or else a copy of it. Case 3 cleans through the advancing
//  select (125). An unrotated chain is a register only when its final value is live after the loop as something
//  never uncomputed (owner 2026-11-11 Q4, liveAfterLoop); else it is garbage, undone by the reverse loop. A final value
//  an outermost loop in an open cq_invert region copies out because it is read after the region's end is no such register
//  (cq-8zz4v, copiedAtEnd).
//  An update chain may sit past a quantum arm's merge, and a merge of an arm's update with the carried value
//  itself is cleaned with the composite inverse, under the same Q4 condition; a bus load copy as
//  the initial rail is excepted on trip 0 under a classical branch (planRuleSixMerges, 109).
//
//  Per-trip uncompute, the deferred reverse and the segments: pass/lib/loops/rolled/Rolled.h (rolled::Region).
#include "cq/Loops.h"
#include "cq/Order.h"
#include "../cutoff/Exits.h"
#include "../rolled/Rolled.h"

#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <tuple>
#include <vector>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Aggregates.h"
#include "cq/Bus.h"
#include "cq/FenvCarry.h"
#include "cq/Predicate.h"
#include "cq/Switch.h"
#include "../../spine/SpineInternal.h"

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IntrinsicInst.h"

using namespace llvm;

namespace {
cq::RailType railOf(Type *t) { return t->isPointerTy() ? cq::RailType{cq::Kind::Int, 64} : cq::railTypeOf(t); }
} // namespace

namespace cq::loops {

namespace {


bool samePred(const Pred &a, const Pred &b) { return (a & !b).isBottom() && (b & !a).isBottom(); }

// CR rule 6's bijections in y (the list of rule 6, but a select of updates and a controlled swap,
// which a carried value's single reader cannot be): add, sub, xor with an operand other than y, mul
// by an odd literal, fneg, bswap, bitreverse, fshl/fshr with y in both value slots.
bool bijectiveIn(const Instruction &U, const Value *Y) {
  if (auto *bo = dyn_cast<BinaryOperator>(&U); bo && bo->getType()->isIntegerTy()) {
    Value *a0 = bo->getOperand(0), *a1 = bo->getOperand(1);
    if (a0 == a1 || (a0 != Y && a1 != Y))
      return false;
    auto opc = bo->getOpcode();
    if (opc == Instruction::Add || opc == Instruction::Sub || opc == Instruction::Xor)
      return true;
    if (opc == Instruction::Mul) {
      auto *k = dyn_cast<ConstantInt>(a0 == Y ? a1 : a0);
      return k && k->getValue()[0];
    }
    return false;
  }
  if (auto *un = dyn_cast<UnaryOperator>(&U))
    return un->getOpcode() == Instruction::FNeg && un->getOperand(0) == Y;
  if (auto *g = dyn_cast<GetElementPtrInst>(&U)) {   // rule 3: a pointer is an i64, a constant gep an add
    APInt off(64, 0);
    return g->getPointerOperand() == Y && g->accumulateConstantOffset(g->getDataLayout(), off);
  }
  if (auto *II = dyn_cast<IntrinsicInst>(&U)) {
    Intrinsic::ID id = II->getIntrinsicID();
    if (id == Intrinsic::bswap || id == Intrinsic::bitreverse)
      return II->getArgOperand(0) == Y;
    if (id == Intrinsic::fshl || id == Intrinsic::fshr)
      return II->getArgOperand(0) == Y && II->getArgOperand(1) == Y && II->getArgOperand(2) != Y;
  }
  return false;
}

struct Inv {
  abi::TemplateSpec spec;
  SmallVector<Operand, 3> ops;
};

// The template spelling of an inverse (CR §1.2 shapes): binary "" / "hl" / "lh", a literal first
// operand of a commutative op swapped behind the rail.
Inv normalized(abi::TemplateSpec spec, SmallVector<Operand, 3> ops) {
  if (ops.size() == 2) {
    if (ops[0].handle && ops[1].handle) {
      spec.shape = "";
    } else if (ops[0].handle) {
      spec.shape = "hl";
    } else if (spec.op == "add" || spec.op == "xor" || spec.op == "mul") {
      std::swap(ops[0], ops[1]);
      spec.shape = "hl";
    } else {
      spec.shape = "lh";
    }
  } else if (ops.size() == 3) {
    std::string sh;
    bool all = true;
    for (const Operand &o : ops) {
      sh += o.handle ? 'q' : 'l';
      all &= o.handle;
    }
    spec.shape = all ? "" : sh;
  }
  return Inv{std::move(spec), std::move(ops)};
}

APInt oddInverse(const APInt &k) {
  APInt x(k.getBitWidth(), 1);
  for (int i = 0; i < 7; ++i)   // Newton: x <- x (2 - k x), doubling the correct bits
    x = x * (APInt(k.getBitWidth(), 2) - k * x);
  return x;
}

// The inverse of U = f(Y, z) in Y, read from yp (U's value): the template and its operands.
Inv inverseOf(LoweringContext &ctx, Instruction &U, const Value *Y, Operand yp) {
  if (!bijectiveIn(U, Y))
    internalError("loops-classical: rule 6 inverse of an update that is no bijection in the carried value", &U);
  abi::TemplateSpec spec;
  spec.w = railOf(U.getType());
  if (auto *bo = dyn_cast<BinaryOperator>(&U)) {
    unsigned i = bo->getOperand(0) == Y ? 0 : 1;
    Value *Z = bo->getOperand(1 - i);
    switch (bo->getOpcode()) {
    case Instruction::Add:
      spec.op = "sub";
      return normalized(spec, {yp, ctx.operand(Z)});   // y = y' - z
    case Instruction::Xor:
      spec.op = "xor";
      return normalized(spec, {yp, ctx.operand(Z)});   // y = y' ^ z
    case Instruction::Sub:
      if (i == 0) {
        spec.op = "add";
        return normalized(spec, {yp, ctx.operand(Z)}); // y' = y - z: y = y' + z
      }
      spec.op = "sub";
      return normalized(spec, {ctx.operand(Z), yp});   // y' = z - y: y = z - y'
    default: {                                         // mul by an odd literal k: y = y' * k^-1
      auto *k = cast<ConstantInt>(Z);
      spec.op = "mul";
      return normalized(spec, {yp, Operand{ConstantInt::get(k->getType(), oddInverse(k->getValue())), false}});
    }
    }
  }
  if (isa<UnaryOperator>(U)) {
    spec.op = "fneg";
    return normalized(spec, {yp});
  }
  if (auto *g = dyn_cast<GetElementPtrInst>(&U)) {
    APInt off(64, 0);
    g->accumulateConstantOffset(g->getDataLayout(), off);
    spec.op = "sub";
    return normalized(spec, {yp, Operand{ConstantInt::get(ctx.M.getContext(), off), false}});
  }
  auto *II = cast<IntrinsicInst>(&U);
  if (II->getIntrinsicID() == Intrinsic::bswap || II->getIntrinsicID() == Intrinsic::bitreverse) {
    spec.op = II->getIntrinsicID() == Intrinsic::bswap ? "bswap" : "bitreverse";   // an involution
    return normalized(spec, {yp});
  }
  spec.op = II->getIntrinsicID() == Intrinsic::fshl ? "fshr" : "fshl";   // a rotation's inverse
  return normalized(spec, {yp, yp, ctx.operand(II->getArgOperand(2))});
}

struct Disj {
  const Value *v;
  bool pos;   // the loop exits when v == pos
};

class Unit : public rolled::Region, public std::enable_shared_from_this<Unit> {
public:
  Unit(LoweringContext &ctx, Loop &top)
      : Region(ctx, ctx.out()), top(top), F(*top.getHeader()->getParent()) {
    diagAt = top.getHeader()->getTerminator();
    ReversePostOrderTraversal<Function *> rpot(&F);
    for (BasicBlock *b : rpot)
      rpo.push_back(b);
  }

  void run(Case c);
  // cq-h5uj (CR rule 14, case 1 or 3 under a trip rail): the loop runs under a trip of an
  // enclosing loop, under that trip's rail `trip` (its effects controlled by it, a case-3 chain
  // seeded by it), on the classical path loops-cutoff branched on. Its reverse is deferred after the readers
  // of its exit values, guarded by "the loop's exit was passed" (the trip may skip the loop classically).
  Value *runInTrip(Case c, Value *trip, bool starts = false) {
    startsBound = starts;
    outerTrip = trip;
    inTrip = true;
    run(c);
    return stopFinal;
  }
  // cq-9kcq S11 (ROLLED_DESIGN.md §3 step 7): as runInTrip, in a rolled K-trip: the unit is a trip-local
  // sub-unit of the K-loop's region (nested, as 176's sub-loops of a classically bounded trip), its reverse placed in the
  // trip by that region's flushTrips; resetAt is the K-loop's output header (where "the sub-loop ran" is false again).
  Value *runSubInTrip(Case c, Value *trip, BasicBlock *reset) {
    nested = true;
    resetAt = reset;
    return runInTrip(c, trip);
  }
  Value *stopFinal = nullptr;   // the XOR of the arm flags of this unit, for the enclosing K-loop (nullptr: none)

private:
  Loop &top;
  Function &F;
  std::vector<BasicBlock *> rpo;

  DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, BasicBlock *> edgeFrom;
  DenseMap<const BasicBlock *, BasicBlock *> obMap;
  Value *outerTrip = nullptr;
  bool inTrip = false;     // cq-h5uj: lowered inside a K-loop trip (runInTrip)
  bool startsBound = false;   // the walker of an exit arm bound the merged starts of the header phis (lowerClassicalInTrip)
  Value *stopCur = nullptr;   // the stop rail at the builder (see the mint in lowerLoop), nullptr when this unit has none
  bool deferred = false;   // the outermost loop's reverse is an Uncompute deferred item   // while a sub-loop of a case-3 trip is walked: that trip's rail a_{j-1}
  bool tripLocal(Loop &sl, Loop &L);
  // The seeds minted for classical incomings of phis of handles, per (phi, edge source), and a mixed
  // join's value per real edge: shared by the walks of a loop and its sub-loops (a sub-loop's exit edge
  // enters a block of its parent).
  DenseMap<std::pair<const PHINode *, const BasicBlock *>, Value *> edgeSeedM, edgeValM;
  // cq-pfpy: a composite phi's value per field at a mixed join's real edge (rule 26 over rule 9).
  DenseMap<std::pair<const PHINode *, const BasicBlock *>, SmallVector<Operand, 4>> edgeFieldsM;

  bool readersKeep(const Value *v);
  bool isQ(const Value *v) {
    if (isa<Constant>(v) || isa<BasicBlock>(v) || isa<MetadataAsValue>(v))
      return false;
    return ctx.T.isQuantum(v, ctx.S);
  }
  Pred qp(const BasicBlock *b) { return ctx.preds().block(b).quantumPart(ctx.T, ctx.S); }
  // Rule 8 / P1 (cq-pkjc): the classical facts the output path into the block being walked
  // establishes, and those of every walked original block.
  Pred curFact = Pred::top();
  DenseMap<const BasicBlock *, Pred> factOf;
  Pred cfOf(const Pred &p) { return p.isBottom() ? Pred::top() : p.classicalFactor(ctx.T, ctx.S); }
  // The classical factor of b's predicate must hold wherever b's code runs: the trip builds no
  // classical guard, so a factor the path does not establish (a classical conjunct of a quantum arm's
  // condition, select(i != 0, q, false)) would run the arm, a slot load at its classical offset
  // included, outside its classical domain and drop the conjunct from every control.
  void requireFact(const BasicBlock *b) {
    if (!(curFact & !cfOf(ctx.preds().block(b))).isBottom())
      unimplemented("loops-classical: a block of a classically bounded loop body whose classical guard (rule 8: "
                    "the classical factor of its predicate, a classical conjunct of a quantum arm condition) the "
                    "trip does not establish (a classical guard inside a trip is not built yet)",
                    &*b->getFirstNonPHIOrDbg());
    factOf[b] = curFact;
  }

  BasicBlock *ob(const BasicBlock *b) {
    auto it = obMap.find(b);
    if (it != obMap.end())
      return it->second;
    return obMap[b] = newBlock();
  }

  Value *seed(Value *classical, RailType w) {
    CallInst *call = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {classical});
    ctx.unc().recordSeed(call);
    return call;
  }
  Value *asHandle(Operand o, Type *ty) {
    if (o.handle)
      return o.v;
    return seed(o.v, railOf(ty));
  }
  Value *select(Value *cond, Operand t, Operand f, RailType w) {
    abi::TemplateSpec spec;
    spec.op = "select";
    spec.w = w;
    std::string shape = std::string(t.handle ? "h" : "l") + (f.handle ? "h" : "l");
    spec.shape = shape == "hh" ? "" : shape;
    return ctx.emitTemplate(spec, {Operand{cond, true}, t, f});
  }
  void gate(abi::Core op, ArrayRef<Value *> args) {
    abi::CoreSpec spec{op, RailType{Kind::Int, 1}};
    CallInst *call = ctx.emitCore(spec, args);
    SmallVector<Operand, 3> ops;
    for (Value *a : args)
      ops.push_back(Operand{a, true});
    ctx.unc().recordCore(call, spec, ops, ctx.unc().idOf(args.back()));
  }

  void resolvePreheader();

  // CR rule 6 on a carried value (cq-b13w). A quantum header phi p read only by a chain of updates
  // U_1 = f_1(p, z_1), U_2 = f_2(U_1, z_2), ... in the header, each a bijection in its predecessor and
  // its predecessor's only reader (so no z_i reads p), whose next value is the last U or it rotated in
  // place (cq_theta chain), is cleaned in its trip: each old rail (U_{i-1}; p's, which is the previous
  // trip's last U or the initial value in trip 0) is recomputed by t = f_i^-1(U_i, z_i) and cleaned
  // (Uncompute::cleanupBijective), so the trip's last U is the carried register itself (kept, never
  // undone by the reverse loop, never copied out). Case 3 asks the same of the select advancing it:
  // y'' = a ? F(y) : y, t = a ? F^-1(y'') : y'' (125), the trip-local U_i uncomputed first.
  // A garbage U (no rotation) is a register only when the loop's final value is live after the loop as
  // something never uncomputed (owner Q4): else rule 5 uncomputes the whole chain and the old value is never dead
  // (rule 6, 42).
  struct R6 {
    PHINode *p;
    SmallVector<Instruction *, 2> U;   // the update chain, U.back() the next value's rail
    bool rotated;
    bool initDirect;   // the initial rail is this function's own and dead after the loop entry: trip 0 cleans it
    // A merge of an arm's update with p itself (109's overflow_arg_area): the next value is the merge, cleaned with the
    // composite inverse a ? y' : U^-1(y'). Rule 6's rolled-loop clause: the trip predicate does not read p, the final
    // rail is live after the loop as something never uncomputed (owner Q4), and a bus load copy as the initial rail is
    // excepted on trip 0.
    bool merge = false;
    bool initLoad = false;
  };
  std::vector<R6> plan6;
  DenseSet<const Value *> keptFinal;   // the final rails of cleaned chains: read after the loop in place
  const R6 *r6Of(const PHINode *p) const {
    for (const R6 &r : plan6)
      if (r.p == p)
        return &r;
    return nullptr;
  }
  void planRuleSix(Loop &L, Case c);
  void planRuleSixMerges(Loop &L);
  bool liveAfterLoop(Loop &L, const Value *fin);
  // cq-8zz4v (CR rules 6, 14, 17): inside an open cq_invert region the outermost loop copies out a final value read after
  // the region's end (wireExits' afterEnd, cq-037u2), so that final rail is undone by the reverse loop inside the region:
  // it is no register kept past the loop, and its chain is not cleaned per trip.
  // cq-oyirf (CR rule 17 "A value made in the region and read after its end"): nor is a final value read in the region only
  // by what does not keep it (a computation: its rail crosses the end only where a rule keeps it, and is uncomputed inside
  // the region after its last reader there).
  bool copiedAtEnd(const Value *fin) {
    return !nested && !inTrip && U.invertOpen() &&
           (rolled::readAfterInvertEnd(top, fin) || !rolled::keptByReader(ctx, top, fin));
  }
  void cleanInvariantOnExit(Loop &L);
  BasicBlock *unitExit = nullptr;   // the outermost loop's T
  bool initDead(Loop &L, const Value *init, const PHINode *p);
  void disjuncts(const Value *v, bool pos, SmallVectorImpl<Disj> &out, SmallPtrSetImpl<const Value *> &inner);
  // Lowers L with the builder at `cur`; its exit edge goes to T. Returns the exit operand of every
  // value of L read after it (quantum ones only).
  std::vector<std::pair<const Value *, Operand>> lowerLoop(Loop &L, Case c, BasicBlock *T, bool outermost);
};

void Unit::disjuncts(const Value *c, bool positive, SmallVectorImpl<Disj> &out,
                     SmallPtrSetImpl<const Value *> &inner) {
  // cq-bea6 (as the spine's loops::classify, cq-dtvp): select c, t, true is !c | t, select c, false, f
  // is !c & f (the condition enters negated), and xor x, true is !x; -O1 writes `i + 1 >= n || q` as
  // select(i + 1 < n, q, true).
  const Value *a = nullptr, *b = nullptr;
  bool isOr = false, isAnd = false, negA = false;
  auto isTrue = [](const Value *v) {
    auto *k = dyn_cast<ConstantInt>(v);
    return k && k->isOne();
  };
  auto isFalse = [](const Value *v) {
    auto *k = dyn_cast<ConstantInt>(v);
    return k && k->isZero();
  };
  if (auto *bo = dyn_cast<BinaryOperator>(c); bo && bo->getType()->isIntegerTy(1)) {
    if (bo->getOpcode() == Instruction::Or) { isOr = true; a = bo->getOperand(0); b = bo->getOperand(1); }
    if (bo->getOpcode() == Instruction::And) { isAnd = true; a = bo->getOperand(0); b = bo->getOperand(1); }
    if (bo->getOpcode() == Instruction::Xor)
      for (unsigned i = 0; i < 2; ++i)
        if (isTrue(bo->getOperand(i))) {
          inner.insert(c);
          return disjuncts(bo->getOperand(1 - i), !positive, out, inner);
        }
  } else if (auto *sel = dyn_cast<SelectInst>(c); sel && sel->getType()->isIntegerTy(1)) {
    const Value *t = sel->getTrueValue(), *f = sel->getFalseValue();
    if (isTrue(t)) {
      isOr = true; a = sel->getCondition(); b = f;
    } else if (isFalse(f)) {
      isAnd = true; a = sel->getCondition(); b = t;
    } else if (isTrue(f)) {
      isOr = true; negA = true; a = sel->getCondition(); b = t;
    } else if (isFalse(t)) {
      isAnd = true; negA = true; a = sel->getCondition(); b = f;
    }
  }
  if ((isOr && positive) || (isAnd && !positive)) {
    inner.insert(c);
    disjuncts(a, negA ? !positive : positive, out, inner);
    disjuncts(b, positive, out, inner);
    return;
  }
  out.push_back({c, positive});
}

bool Unit::initDead(Loop &L, const Value *init, const PHINode *p) { return exits::initDead(ctx, L, init, p); }

void Unit::planRuleSix(Loop &L, Case c) {
  BasicBlock *header = L.getHeader(), *latch = L.getLoopLatch(), *pre = L.getLoopPredecessor();
  if (!pre)
    return;   // several entries: the initial value is a merge of them, undone by the reverse like any record
  if (!latch || exits::liveExiting(L) != latch || !exits::unitOf(L).abort.empty())
    return;   // a trip may end before the update: the exit value is not the chain's (no latch: several back edges after
              // fix-irreducible, where liveExiting is nullptr too when several blocks exit: __gmpn_hgcd2_jacobi)
  const bool c3 = c == Case::ClassicalBoundQuantumExit;
  if (!c3 && !qp(header).isTop())
    return;
  DominatorTree &DT = spine::shared(ctx).dt(F);
  for (PHINode &p : header->phis()) {
    if (!isQ(&p) || !(p.getType()->isIntegerTy() || p.getType()->isFloatingPointTy()) || !p.hasOneUse())
      continue;
    // The next value: the last update, or it rotated in place by unconditional cq_theta calls with
    // classical angles.
    SmallVector<const Instruction *, 4> chain;
    const Value *nx = p.getIncomingValueForBlock(latch);
    bool rotated = false, ok = true;
    while (auto *CB = dyn_cast<CallInst>(nx)) {
      if (calls::classify(*CB, ctx.T, ctx.S) != calls::Class::Theta)
        break;
      nx = CB->getArgOperand(0);
    }
    SmallVector<Instruction *, 2> ups;
    for (const Value *x = &p;;) {
      if (!x->hasOneUse()) {
        ok = false;
        break;
      }
      auto *W = dyn_cast<Instruction>(const_cast<User *>(*x->user_begin()));
      // Run on every trip at the header's predicate: the header, or a block past a quantum arm's merge (109's s).
      if (!W || !L.contains(W) || !DT.dominates(W->getParent(), latch) || !samePred(qp(W->getParent()), qp(header)) ||
          !bijectiveIn(*W, x) || !isQ(W)) {
        ok = false;
        break;
      }
      ups.push_back(W);
      if (W == nx)
        break;
      x = W;
    }
    if (!ok)
      continue;
    Instruction *U = ups.back();
    nx = p.getIncomingValueForBlock(latch);
    while (nx != U) {
      auto *CB = dyn_cast<CallInst>(nx);
      if (!CB || !L.contains(CB) || calls::classify(*CB, ctx.T, ctx.S) != calls::Class::Theta ||
          isQ(CB->getArgOperand(1)) || !samePred(qp(CB->getParent()), qp(header))) {
        ok = false;
        break;
      }
      chain.push_back(CB);
      rotated = true;
      nx = CB->getArgOperand(0);
    }
    if (!ok || (c3 && rotated))
      continue;
    chain.push_back(U);
    // Nothing else in the loop reads the chain (the clean-up of the next trip frees it); a reader after
    // the loop reads the final rail.
    for (const Instruction *x : chain)
      for (const User *usr : x->users()) {
        if (usr == &p || is_contained(chain, usr))
          continue;
        auto *ui = dyn_cast<Instruction>(usr);
        if (!ui || L.contains(ui))
          ok = false;
      }
    // Owner 2026-11-11 Q4 (cq-padp): an unrotated chain is cleaned per trip only when its final value is live after the
    // loop as something never uncomputed; else it is garbage, undone by the reverse loop after its last reader.
    if (!ok || (!rotated && (!liveAfterLoop(L, U) || copiedAtEnd(U))))
      continue;
    plan6.push_back({&p, ups, rotated, initDead(L, p.getIncomingValueForBlock(pre), &p)});
  }
}

// Rule 6's rolled-loop clause on a carried value whose update is a merge in the trip: p' = phi [p, arm], [U(p), arm'] past
// a quantum branch whose condition does not read p. The other readers of p in the trip must not feed a carried value or
// anything else the reverse loop would undo: each is a kept store's value, or reaches only a chain planned above.
void Unit::planRuleSixMerges(Loop &L) {
  BasicBlock *header = L.getHeader(), *latch = L.getLoopLatch(), *pre = L.getLoopPredecessor();
  if (!pre || !latch || !qp(header).isTop() || exits::liveExiting(L) != latch || !exits::unitOf(L).abort.empty())
    return;
  DominatorTree &DT = spine::shared(ctx).dt(F);
  auto chainEnd = [&](const Value *v) {
    return any_of(plan6, [&](const R6 &r) { return r.U.back() == v; });
  };
  for (PHINode &p : header->phis()) {
    if (!isQ(&p) || r6Of(&p) || !(p.getType()->isIntegerTy() || p.getType()->isPointerTy()))
      continue;
    auto *M = dyn_cast<PHINode>(p.getIncomingValueForBlock(latch));
    if (!M || M->getParent() == header || !L.contains(M) || M->getNumIncomingValues() != 2 ||
        !DT.dominates(M->getParent(), latch) || !samePred(qp(M->getParent()), qp(header)))
      continue;
    unsigned self = M->getIncomingValue(0) == &p ? 0 : 1;
    auto *Up = dyn_cast<Instruction>(M->getIncomingValue(1 - self));
    if (M->getIncomingValue(self) != &p || !Up || !L.contains(Up) || !isQ(Up) || !bijectiveIn(*Up, &p))
      continue;
    // The branch deciding the merge.
    auto *node = DT.getNode(M->getParent());
    auto *br = node && node->getIDom() ? dyn_cast<BranchInst>(node->getIDom()->getBlock()->getTerminator()) : nullptr;
    if (!br || !br->isConditional() || !isQ(br->getCondition()))
      continue;
    // Does a value depend on p, inside the trip? A load or call in the way counts as a dependence.
    bool ok = true;
    DenseSet<const Value *> seen;
    SmallVector<const Value *, 8> work{br->getCondition()};
    while (ok && !work.empty()) {
      const Value *v = work.pop_back_val();
      auto *I = dyn_cast<Instruction>(v);
      if (!I || !L.contains(I) || !seen.insert(v).second)
        continue;
      if (v == &p || I->mayReadOrWriteMemory())
        ok = false;
      else
        work.append(I->op_begin(), I->op_end());
    }
    // Who p reaches: nothing carried but through M, nothing past the loop.
    seen.clear();
    work.assign({&p});
    while (ok && !work.empty()) {
      const Value *v = work.pop_back_val();
      if (!seen.insert(v).second)
        continue;
      for (const User *usr : v->users()) {
        auto *ui = dyn_cast<Instruction>(usr);
        if (ui == M || chainEnd(ui))
          continue;
        if (auto *st = dyn_cast_or_null<StoreInst>(ui); st && st->getValueOperand() == v && L.contains(st))
          continue;   // a kept store's value rail: no _unc reads p
        if (!ui || !L.contains(ui) || isa<CallBase>(ui) || (isa<PHINode>(ui) && ui->getParent() == header) ||
            isa<StoreInst>(ui)) {
          ok = false;
          break;
        }
        work.push_back(ui);
      }
    }
    // Owner 2026-11-11 Q4: only a final value live after the loop as something never uncomputed (95, 109's
    // overflow_arg_area is not: its chain is garbage, undone by the reverse loop).
    if (!ok || !liveAfterLoop(L, M) || copiedAtEnd(M))
      continue;
    const Value *init = p.getIncomingValueForBlock(pre);
    R6 r{&p, {Up}, false, initDead(L, init, &p)};
    r.merge = true;
    r.initLoad = isa<LoadInst>(init) && isQ(init);
    plan6.push_back(std::move(r));
  }
}

// Owner 2026-11-11 Q4 (CR rule 6, "In a rolled loop"): is the final carried value `fin` live after L as something never
// uncomputed (measured, returned, stored, rotated, an operand of a kept rail)? Forward over the values computed from fin
// outside L: a return, a store, a load (an address rail), a call other than cq_phi or a template/libm intrinsic (measured,
// rotated, or handed to a callee that may keep it) is such a use. Arithmetic, casts, compares, selects and phis pass the
// question on to their result. A conditional branch or switch on such a value passes it on to the merges its region
// feeds, and is a use itself when its region (up to its immediate post-dominator) holds a store, a load, a return or such
// a call: a flag controlling a kept store or a measurement is kept. A flag read by phases alone is uncomputed (cq-padp).
bool Unit::liveAfterLoop(Loop &L, const Value *fin) {
  std::unique_ptr<PostDominatorTree> PDT;
  SmallPtrSet<const Value *, 16> seen;
  SmallVector<const Value *, 16> work{fin};
  auto keeps = [&](const Instruction &I) {
    if (isa<ReturnInst>(I) || isa<StoreInst>(I) || isa<LoadInst>(I) || isa<ResumeInst>(I) || I.isAtomic())
      return true;
    auto *CB = dyn_cast<CallBase>(&I);
    if (!CB || isa<DbgInfoIntrinsic>(CB))
      return false;
    if (auto *II = dyn_cast<IntrinsicInst>(CB); II && II->isAssumeLikeIntrinsic())
      return false;
    switch (calls::classify(*CB, ctx.T, ctx.S)) {
    case calls::Class::Phi:
    case calls::Class::TemplateIntrinsic:
    case calls::Class::LibmIntrinsic:
      return false;
    default:
      return true;
    }
  };
  while (!work.empty()) {
    const Value *v = work.pop_back_val();
    if (!seen.insert(v).second)
      continue;
    for (const User *usr : v->users()) {
      auto *I = dyn_cast<Instruction>(usr);
      if (!I)
        return true;
      if (L.contains(I))
        continue;   // the chain itself (the caller checked that nothing else in L reads it)
      if (keeps(*I))
        return true;
      // A void call keeps() lets pass (a cq_phi, its angle a rail or not, Q4: a phase is no rotation of its angle; an
      // assume-like or debug intrinsic) reads the value and leaves nothing behind that could keep it.
      if (isa<CallBase>(I) && I->getType()->isVoidTy())
        continue;
      if (I->isTerminator()) {
        if (!isa<BranchInst>(I) && !isa<SwitchInst>(I))
          return true;
        // The region the branch decides: blocks reached from it before its immediate post-dominator.
        if (!PDT)
          PDT = std::make_unique<PostDominatorTree>(F);
        BasicBlock *B = const_cast<BasicBlock *>(I->getParent());
        auto *node = PDT->getNode(B);
        BasicBlock *J = node && node->getIDom() ? node->getIDom()->getBlock() : nullptr;
        if (!J)
          return true;
        SmallPtrSet<BasicBlock *, 8> region;
        SmallVector<BasicBlock *, 8> bw(succ_begin(B), succ_end(B));
        while (!bw.empty()) {
          BasicBlock *x = bw.pop_back_val();
          if (x == J || x == B || !region.insert(x).second)
            continue;
          for (Instruction &y : *x)
            if (keeps(y))
              return true;
          bw.append(succ_begin(x), succ_end(x));
        }
        // The merges fed by the region or by the branch's own edges depend on the condition.
        region.insert(B);
        for (BasicBlock *x : region)
          for (BasicBlock *s : successors(x))
            for (PHINode &ph : s->phis())
              if (any_of(ph.blocks(), [&](BasicBlock *pb) { return region.contains(pb); }))
                work.push_back(&ph);
        continue;
      }
      if (I->getType()->isVoidTy())
        return true;
      work.push_back(I);
    }
  }
  return false;
}

// CR rule 6 in a rolled loop (75): a loop-invariant kept rail x (a rotated register) whose only reader is an update
// y = f(x, z) run in every trip, a bijection in x, with y kept in every trip (a kept store's value rail): nothing will
// ever uncompute through x, so it is cleaned from the last trip's image on the exit edge, at T. A zero-trip path never
// reaches T: x stays the live register there.
void Unit::cleanInvariantOnExit(Loop &L) {
  BasicBlock *latch = L.getLoopLatch();
  if (!latch || exits::liveExiting(L) != latch || !exits::unitOf(L).abort.empty())
    return;
  DominatorTree DT(F);
  Module &M = Mod;
  for (BasicBlock *b : L.blocks()) {
    if (!DT.dominates(b, latch) || !qp(b).isTop())
      continue;
    for (Instruction &Y : *b) {
      if (!isQ(&Y) || !ctx.bound(&Y) || isa<PHINode>(Y))
        continue;
      for (Value *X : Y.operands()) {
        if (isa<Constant>(X) || !isQ(X) || !bijectiveIn(Y, X) || !ctx.bound(X))
          continue;
        if (auto *XI = dyn_cast<Instruction>(X); XI && L.contains(XI))
          continue;
        if (!all_of(X->users(), [&](const User *u) { return u == &Y; }))
          continue;
        Operand xo = ctx.operand(X), yo = ctx.operand(&Y);
        if (!xo.handle || !yo.handle || !isa<CallInst>(xo.v))
          continue;
        std::optional<Role> xr = U.liveRole(U.idOf(xo.v)), yr = U.liveRole(U.idOf(yo.v));
        if (!xr || !yr || (*xr != Role::UserRegister && *xr != Role::Frozen) || *yr != Role::Kept)
          continue;
        Inv inv = inverseOf(ctx, Y, X, yo);
        SmallVector<Value *, 3> args;
        for (const Operand &o : inv.ops)
          args.push_back(o.v);
        IRBuilder<> &B = ctx.B();
        Value *t = B.CreateCall(abi::declare(M, inv.spec, false), args);
        B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Copy, railOf(Y.getType())}), {t, xo.v});
        SmallVector<Value *, 4> uargs{t};
        uargs.append(args.begin(), args.end());
        B.CreateCall(abi::declare(M, inv.spec, true), uargs);
        FunctionCallee fr = abi::declare(M, abi::CoreSpec{abi::Core::Free});
        B.CreateCall(fr, {t});
        B.CreateCall(fr, {xo.v});
        for (const Operand &o : inv.ops)
          if (o.handle)
            U.noteUse(U.idOf(o.v), cast<Instruction>(t));
      }
    }
  }
}

// A clone call that has a twin (U2): a quantum result field, or a caller cell it stores a handle into.
// A sub-loop sl of L (case 1) is trip-local when the quantum values of sl read after it are read, through
// their forward slice, only by instructions of L's trip outside every sub-loop of L (no header phi of L,
// no store, no call, nothing after L), sl writes no quantum value to memory, makes no non-diagonal gate
// and calls nothing but the CQ.h surface: its rails are dead before the trip ends, so its reverse runs in
// the trip, before any later gate of the trip on the rails it read (rule 5; 176's value(x) loops before
// A^dag / A).
bool Unit::tripLocal(Loop &sl, Loop &L) {
  if (!qp(sl.getHeader()).isTop() || !sl.getSubLoops().empty())
    return false;
  bool any = false;
  for (BasicBlock *b : sl.blocks())
    for (Instruction &I : *b) {
      if (auto *si = dyn_cast<StoreInst>(&I); si && isQ(si->getValueOperand()))
        return false;
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        if (isa<DbgInfoIntrinsic>(CB))
          continue;
        calls::Class k = calls::classify(*CB, ctx.T, ctx.S);
        if (k != calls::Class::Classical && k != calls::Class::TemplateIntrinsic && k != calls::Class::Phi)
          return false;
        if (k == calls::Class::Classical && CB->mayWriteToMemory())
          return false;
      }
      if (!isQ(&I))
        continue;
      SmallVector<const Instruction *, 8> work;
      SmallPtrSet<const Instruction *, 16> seen;
      for (const User *u : I.users())
        if (auto *ui = dyn_cast<Instruction>(u); ui && !sl.contains(ui))
          work.push_back(ui);
      while (!work.empty()) {
        const Instruction *x = work.pop_back_val();
        if (!seen.insert(x).second)
          continue;
        any = true;
        if (!L.contains(x) || (x->getParent() == L.getHeader() && isa<PHINode>(x)) || isa<StoreInst>(x) ||
            isa<CallBase>(x) || isa<ReturnInst>(x))
          return false;
        for (Loop *o : L.getSubLoops())
          if (o->contains(x))
            return false;
        if (x->isTerminator())
          continue;
        for (const User *u : x->users())
          if (auto *ui = dyn_cast<Instruction>(u))
            work.push_back(ui);
      }
    }
  return any;
}

std::vector<std::pair<const Value *, Operand>> Unit::lowerLoop(Loop &L, Case c, BasicBlock *T, bool outermost) {
  const bool c3 = c == Case::ClassicalBoundQuantumExit;
  BasicBlock *header = L.getHeader(), *pre = L.getLoopPredecessor(), *latch = L.getLoopLatch();
  BasicBlock *exitB = exits::liveExit(L);

  // CASE-3 MULTI-EXIT form (121: `n < cap && s[n] != 0`; strcmp's two quantum tests): quantum exits
  // leave from blocks before the latch, the latch's test is the classical bound. Each quantum exit edge
  // u -> x of a trip is taken under e = a & f, f the flag of u's quantum predicate & the exit condition;
  // the trip goes on under a' = a & NOT f (a ^ (a & f): gates on fresh rails only, so the mirror's undo
  // reads f as the forward did). The exit arm (Exits.h; pure instructions only) is computed in the trip,
  // under the OR of its exit edges' e; each phi P of the continuation C carries a capture rail cap =
  // select(g, v, cap) per unit edge into C (g its e or its arm block's flag), and the latch's classical
  // exit edge gives res = select(a, v_latch, cap), the trip's value of P were the bound reached now: the
  // last trip's res is P's exit value (the reference 121's r_i chain and its final select). Every rail is
  // a record of its trip, uncomputed by the mirror (nothing kept, case 3). The walker joins P with a
  // classical skip edge of the loop (its zero-trip guard) itself.
  // A quantum exit into a noreturn arm (rule 16) has this form too: e = a & f is the arm's flag, its abort_i1 made at the
  // exit test (the arm is no part of the continuation), the trip going on under a' = a & NOT f.
  exits::Unit UX = exits::unitOf(L);
  const bool mx = c3 && (UX.multi() || exits::liveExiting(L) != latch || !UX.abort.empty());
  // With every quantum exit into a noreturn arm the trip that leaves for C is the last one the classical bound gives, so a
  // classical value of the loop keeps its classical exit value (taint's dead-end rule, 45): no capture.
  bool noLiveQ = true;
  {
    SmallVector<BasicBlock *, 4> exiting;
    L.getExitingBlocks(exiting);
    for (BasicBlock *u : exiting) {
      const Instruction *t = u->getTerminator();
      const Value *cnd = nullptr;
      if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional())
        cnd = br->getCondition();
      else if (auto *sw = dyn_cast<SwitchInst>(t))
        cnd = sw->getCondition();
      else if (auto *ib = dyn_cast<IndirectBrInst>(t))
        cnd = ib->getAddress();
      if (cnd && isQ(cnd) && any_of(successors(u), [&](BasicBlock *x) { return !L.contains(x) && is_contained(UX.live, x); }))
        noLiveQ = false;
    }
  }
  if (!mx && (!exits::liveExiting(L) || !exitB))
    unimplemented("loops-classical: a rule-14 loop with more than one exiting block or exit block",
                  header->getTerminator());
  if (c3 && !mx && exits::liveExiting(L) != latch)
    unimplemented("loops-classical: a quantum exit test that is not the latch's (rule 14 case 3)",
                  exits::liveExiting(L)->getTerminator());
  auto inUnit = [&](const BasicBlock *b) { return UX.contains(L, b); };
  // cq-j5mq: several classical exit edges into one exit block (a `break` on a classical test): each edge is a real
  // branch to T. The exit block's phis are bound at T, over the edges. Several live exit blocks are this form too when one
  // block leaves for all of them (a classical switch; unifySubLoopExits' hub, GMP __gmpn_jacobi_base, cq-9ch5t): the edge
  // into the exit arm runs the arm (c1Arm below), which no other form lowers for the unit's paths.
  const bool cx = !c3 && outermost && (!exits::liveExiting(L) || UX.multi());
  // A sub-loop's classical edges are real branches to wherever they go, in its parent or out of the unit.
  if (outermost)
    unitExit = T;

  // Values of L read after it. Multi-exit (cq-nqa6, 117's is_marked): a scalar loop value read by a
  // non-phi in C or a block C dominates is the exit value of the trip that left, as a phi of C with that
  // value on every unit edge into C would be (SSA: the value dominates C, so each unit edge into C
  // carries its latest trip's value); it is a capture of its own (xreads), bound after the loop.
  std::unique_ptr<DominatorTree> mxDT = mx ? std::make_unique<DominatorTree>(*header->getParent()) : nullptr;
  std::vector<const Instruction *> liveOut, xreads;
  for (BasicBlock *b : L.blocks())
    for (Instruction &I : *b)
      for (const Use &us : I.uses())
        if (auto *ui = dyn_cast<Instruction>(us.getUser()); ui && !L.contains(ui)) {
          if (auto *xp = dyn_cast<PHINode>(ui); cx && xp && xp->getParent() == exitB && L.contains(xp->getIncomingBlock(us)))
            continue;   // read by the exit block's phi on its edge: bound at T
          if (auto *xp = dyn_cast<PHINode>(ui);
              cx && UX.multi() &&
              (UX.contains(L, ui->getParent()) || (xp && xp->getParent() == UX.cont && inUnit(xp->getIncomingBlock(us)))))
            continue;   // read by the exit arm (it runs in the exit edge's segment) or by C's phi on a unit edge
          if (mx) {
            if (noLiveQ && !isQ(&I))
              continue;
            auto *phi = dyn_cast<PHINode>(ui);
            if (UX.contains(L, ui->getParent()) ||
                (phi && phi->getParent() == UX.cont && inUnit(phi->getIncomingBlock(us))))
              continue;   // read by the exit arm or by C's phi on a unit edge
            if (!phi && mxDT->dominates(UX.cont, ui->getParent()) &&
                (I.getType()->isIntegerTy() || I.getType()->isFloatingPointTy())) {
              if (!is_contained(xreads, &I))
                xreads.push_back(&I);
              continue;
            }
            unimplemented("loops-classical: a value of a multi-exit case-3 loop read after it other than by a "
                          "phi of its continuation or a scalar read C dominates",
                          &I);
          }
          // A classical pointer read after the loop stays classical (taint cq-1v3i: an address is evaluated per
          // trip, never a rail); a classical scalar of a case-3 loop is captured below.
          if (!c3 || isQ(&I) || !I.getType()->isPointerTy())
            liveOut.push_back(&I);
          break;
        }
  struct CPhi {
    PHINode *P;                     // a phi of C, or nullptr for a read after the loop (xreads)
    const Instruction *x = nullptr; // that read's loop value: its incoming on every unit edge into C
    SmallVector<PHINode *, 2> cap;  // the carried capture rails, one per field
    SmallVector<Value *, 2> res;    // this trip's res, one per field
    SmallVector<Value *, 2> atCx;   // the captures as cxb's classical exit into the arm sees them (cxArm)
    SmallVector<RailType, 2> rails; // the fields' rail types
    // cq-11qhg: the captures on the walk's open flow (cap, with the exits taken early, below, selected in) and at the end of
    // each walked block; joined at a classical join of the trip as the trip predicate is.
    SmallVector<Value *, 2> run;
    SmallVector<DenseMap<const BasicBlock *, Value *>, 2> runOut;
    bool ptr = false;
    bool shaped = false;
    const Value *orig() const { return P ? static_cast<const Value *>(P) : x; }
    Type *type() const { return orig()->getType(); }
    // The unit edges into C and their values.
    SmallVector<std::pair<BasicBlock *, const Value *>, 4> incomings(const std::function<bool(const BasicBlock *)> &in,
                                                                     BasicBlock *C) const {
      SmallVector<std::pair<BasicBlock *, const Value *>, 4> r;
      if (P) {
        for (unsigned i = 0; i < P->getNumIncomingValues(); ++i)
          if (in(P->getIncomingBlock(i)))
            r.push_back({P->getIncomingBlock(i), P->getIncomingValue(i)});
      } else {
        for (BasicBlock *u : predecessors(C))
          if (in(u) && none_of(r, [&](const auto &e) { return e.first == u; }))
            r.push_back({u, x});
      }
      return r;
    }
  };
  std::vector<CPhi> cphis;
  DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, Value *> exitFlag;   // quantum exit edge -> e
  // Multi-exit: the one block whose classical test leaves the loop (the bound): the latch (121), or the
  // header with the quantum exit at the latch (cq-nqa6, 117's is_marked: `k + 1 == n` at the header,
  // `v == m[k + 1]` at the latch). Its exit edge gives res; it enters C directly.
  BasicBlock *cxb = nullptr;
  BasicBlock *cxArm = nullptr;                      // the arm block cxb's classical exit edge enters (nullptr: C itself)
  SmallVector<BasicBlock *, 2> cxAll, cxExtra;      // the classical exit tests; those besides cxb that enter C only
  std::unique_ptr<LoopInfo> mxLI;
  DenseMap<const BasicBlock *, Loop *> armUnit;     // a block of a loop of the exit arm's unit -> that loop
  // Classical exit edges into the exit arm (case 3: cxb's; case 1, cq-y7kw: each classical exit edge not into C): each
  // runs the arm once, in a segment of its own after the trips.
  struct ArmExit {
    ArmExit(BasicBlock *u, BasicBlock *x, BasicBlock *Y) : u(u), x(x), Y(Y) {}
    BasicBlock *u, *x, *Y;
    BasicBlock *end = nullptr;                      // where that segment leaves for T
    DenseMap<const PHINode *, Operand> contVal;     // case 1: C's phis on this edge
    std::vector<SmallVector<Value *, 2>> res;       // case 3: each cphi's res on this edge
  };
  SmallVector<ArmExit, 2> armExits;
  BasicBlock *tgtFrom = nullptr;                    // the block whose terminator is being emitted
  SmallVector<Disj, 4> mixedDs;   // cq-h8y6: the classical disjuncts of a mixed exit test at cxb (empty: cxb is classical)
  bool midCxb = false;            // cq-iaz30: cxb is a classical test into C inside the trip (neither header nor latch)
  auto buildArmUnits = [&]() {
    if ((UX.arm.empty() && UX.abort.empty()) || mxLI)
      return;
    mxLI = std::make_unique<LoopInfo>(*mxDT);
    for (auto *blocks : {&UX.arm, &UX.abort})
      for (BasicBlock *a : *blocks) {
        Loop *l = mxLI->getLoopFor(a), *last = nullptr;
        for (; l && !l->contains(header); l = l->getParentLoop())
          last = l;
        if (!last || armUnit.count(last->getHeader()))
          continue;
        exits::Unit SU = exits::unitOf(*last);
        for (BasicBlock *b : last->blocks())
          armUnit[b] = last;
        for (auto *list : {&SU.arm, &SU.abort, &SU.dead})
          for (BasicBlock *b : *list)
            if (is_contained(*blocks, b) && b != UX.cont)
              armUnit[b] = last;
      }
  };
  // cq-y7kw (CR rule 14 case 1 with rules 8, 9): a classically bounded loop whose classical exits reach several exit
  // blocks. Each exit edge is a real branch; an exit into the arm runs the arm in a segment of its own, under the loop's
  // predicate, and C's phis take that edge's value (the cx form's copy-out at T).
  const bool c1Arm = cx && UX.multi();
  if (c1Arm) {
    mxDT = std::make_unique<DominatorTree>(*header->getParent());
    buildArmUnits();
    SmallVector<BasicBlock *, 4> exiting;
    L.getExitingBlocks(exiting);
    for (BasicBlock *u : exiting)
      for (BasicBlock *x : successors(u))
        if (!L.contains(x) && x != UX.cont && is_contained(UX.live, x) &&
            none_of(armExits, [&](const ArmExit &e) { return e.u == u && e.x == x; }))
          armExits.emplace_back(u, x, newBlock());
  }
  if (mx) {
    SmallVector<BasicBlock *, 4> exiting;
    L.getExitingBlocks(exiting);
    SmallVector<BasicBlock *, 2> abortTests;   // purely classical tests with an edge into a noreturn arm
    for (BasicBlock *u : exiting) {
      if (none_of(successors(u), [&](BasicBlock *s) { return !L.contains(s) && is_contained(UX.live, s); })) {
        // Only into dead ends: an effect-free one is UB to reach; a noreturn arm on a classical test is below.
        const Instruction *ut = u->getTerminator();
        auto *ubr = dyn_cast<BranchInst>(ut);
        const Value *uc = ubr ? (ubr->isConditional() ? ubr->getCondition() : nullptr)
                              : isa<SwitchInst>(ut) ? cast<SwitchInst>(ut)->getCondition() : nullptr;
        if (uc && !isQ(uc) && any_of(successors(u), [&](BasicBlock *s) { return is_contained(UX.abort, s); }))
          abortTests.push_back(u);
        continue;
      }
      auto *br = dyn_cast<BranchInst>(u->getTerminator());
      if (br && br->isConditional() && isQ(br->getCondition()))
        continue;
      if (auto *sw = dyn_cast<SwitchInst>(u->getTerminator()); sw && isQ(sw->getCondition()))
        continue;
      if (auto *ib = dyn_cast<IndirectBrInst>(u->getTerminator()); ib && isQ(ib->getAddress()))
        continue;   // rule 13: a quantum computed goto is a quantum exit test
      cxAll.push_back(u);
    }
    // cq-2xl5 (CR rule 14 case 3 with rule 8): several classical exit tests. The bound is the latch's test (else the
    // header's, else the last); every other one whose exit edges all enter C is a real branch out of the trip that
    // leaves under the trip predicate at it (cxExtra): its edge gives its own res, and T joins the res of every exit edge.
    if (!cxAll.empty()) {
      cxb = is_contained(cxAll, latch) ? latch : is_contained(cxAll, header) ? header : cxAll.back();
      for (BasicBlock *u : cxAll) {
        if (u == cxb)
          continue;
        if (all_of(successors(u), [&](BasicBlock *x) { return L.contains(x) || x == UX.cont; }))
          cxExtra.push_back(u);
        else
          noteUnbuilt("loops-classical: a multi-exit case-3 loop with a classical exit test besides its bound into its "
                      "exit arm",
                      u->getTerminator());
      }
    }
    // cq-h8y6 (CR rule 14 case 3, "a mixed exit c_classical || q"): with no purely classical exit test, the bound is
    // a classical disjunct of a quantum exit test (strncmp: `n && *r && *l == *r` at the header). That block is the
    // classical exit test for its classical disjuncts (the loop branches on them) and a quantum exit for the whole
    // test: e = a & f, f the flag of the exit condition with its classical terms seeded (rule 8), so where a
    // classical disjunct holds the trip exits through it under a and the captures take its value. The header is
    // preferred, then the latch; another mixed exit stays a quantum exit (its classical terms seeded in its flag).
    SmallVector<BasicBlock *, 4> byPref{header, latch};
    for (BasicBlock *u : exiting)
      if (!is_contained(byPref, u))
        byPref.push_back(u);
    // A mixed test into a noreturn arm is the bound only where no mixed test into a live exit is.
    for (bool intoAbort : {false, true})
      for (BasicBlock *u : byPref) {
          if (cxb || !is_contained(exiting, u))
            continue;
          auto *br = dyn_cast<BranchInst>(u->getTerminator());
          if (!br || !br->isConditional() || !isQ(br->getCondition()) ||
              L.contains(br->getSuccessor(0)) == L.contains(br->getSuccessor(1)) ||
              none_of(successors(u), [&](BasicBlock *x) {
                return !L.contains(x) && (is_contained(UX.live, x) || (intoAbort && is_contained(UX.abort, x)));
              }))
            continue;
          SmallVector<Disj, 4> d;
          SmallPtrSet<const Value *, 8> inner;
          disjuncts(br->getCondition(), !L.contains(br->getSuccessor(0)), d, inner);
          SmallVector<Disj, 4> c;
          for (const Disj &x : d)
            if (!isQ(x.v))
              c.push_back(x);
          if (c.empty())
            continue;
          cxb = u;
          mixedDs = c;
        }
    // With no other classical exit a classical test into a noreturn arm is the bound itself (rule 14 "No live exit"): the
    // arm is the segment after the trips on that real edge. Any other such test is abortTest below, inside the trip.
    if (!cxb)
      for (BasicBlock *u : byPref)
        if (!cxb && is_contained(abortTests, u)) {
          cxb = u;
          for (BasicBlock *x : successors(u))
            if (is_contained(UX.abort, x))
              cxArm = x;
        }
    auto *lbr = dyn_cast<BranchInst>(latch->getTerminator());
    if (!lbr)
      unimplemented("loops-classical: a multi-exit case-3 loop whose latch test is quantum", latch->getTerminator());
    // A quantum latch test is a quantum exit of the trip (e = a & f, the back edge taken under a & NOT f): the
    // classical bound is tested at the header (cq-nqa6, 117), or is a classical disjunct of the latch's own test or
    // of the header's (mixedDs above). Its back edge is the classical branch on the bound's disjuncts (at the latch)
    // or unconditional (the bound tested at the header).
    // The classical exit test may leave into the exit arm (strlen's alignment loop, strcpy's): a classical exit runs
    // once per activation, so the arm on that edge is no part of a trip. It is one more segment after the trips,
    // entered by the real branch and run under the trip predicate at that test (lowerClassicalExitArm below).
    // A mixed test at the header into the arm likewise (`while (q && m < N)`): where a classical disjunct holds the loop
    // leaves at the test, before the latch where the trip's quantum exits walk the arm.
    if (cxb && (mixedDs.empty() || (cxb == header && cxb != latch)))
      for (BasicBlock *x : successors(cxb))
        if (!L.contains(x) && x != UX.cont && is_contained(UX.live, x))
          cxArm = x;
    // The loops of the exit arm (Exits.h): each unit one node of the arm. armUnit: its blocks and its own arm's -> it.
    buildArmUnits();
    // cq-zueka: a classical switch at cxb may leave into the arm by several exit blocks (TinyEMU main's getopt loop): an arm
    // exit per edge, each with its own res, which T joins (cq-2xl5's join below).
    if (cxArm && !is_contained(UX.live, cxArm))
      armExits.emplace_back(cxb, cxArm, newBlock());   // a noreturn arm's (rule 14 "No live exit")
    else if (cxArm)
      for (BasicBlock *x : successors(cxb))
        if (!L.contains(x) && x != UX.cont && is_contained(UX.live, x) &&
            none_of(armExits, [&](const ArmExit &e) { return e.x == x; }))
          armExits.emplace_back(cxb, x, newBlock());
    // cq-iaz30 (CR rule 14 case 3 with rule 8): a classical bound tested mid-trip (gsl_min_find_bracket: `i == max` before the
    // latch's quantum test; broyden_iterate: the mixed test `q && i < 9 && q'`) into C leaves where the trip stands at it, as a
    // classical exit test besides the bound does (cq-2xl5): its res is made at its branch (extraRes: the trip predicate there
    // selects its own edge's value over the exits taken before it), not at the latch, which the trip that leaves never reaches.
    midCxb = cxb && cxb != latch && cxb != header && !cxArm;
    for (BasicBlock *a : UX.arm)
      for (Instruction &I : *a) {
        // The arm's branches are flags of its blocks and edges, its phis rule 9 selects, its effects run
        // under its flag (latchExits).
        if (I.isTerminator() && !isa<BranchInst>(I) && !isa<SwitchInst>(I) && !isa<IndirectBrInst>(I))
          internalError("loops-classical: an exit arm block ending in other than a branch, switch or computed goto", &I);
        // A value of the arm read after the loop other than by C's phi: its block dominates the reader and so C
        // (SSA), every unit edge into C passes it in the exiting trip: a capture of its own (xreads), as a
        // loop value's.
        for (const Use &us : I.uses())
          if (auto *ui = cast<Instruction>(us.getUser()); !inUnit(ui->getParent()) &&
                                                         !(isa<PHINode>(ui) && ui->getParent() == UX.cont)) {
            if (isa<PHINode>(ui) || !mxDT->dominates(UX.cont, ui->getParent()) ||
                !(I.getType()->isIntegerTy() || I.getType()->isFloatingPointTy()))
              unimplemented("loops-classical: a value of a case-3 loop's exit arm read after the loop other than by a "
                            "phi of its continuation or a scalar read C dominates",
                            &I);
            if (!is_contained(xreads, &I))
              xreads.push_back(&I);
          }
      }
    const Pred hb = ctx.preds().block(header);
    if (UX.cont)
    for (PHINode &P : UX.cont->phis()) {
      bool fromUnit = any_of(P.blocks(), [&](const BasicBlock *u) { return inUnit(u); });
      if (!fromUnit)
        continue;
      if (noLiveQ && !isQ(&P))
        continue;   // its classical exit value: the walker binds it
      // A classical phi whose every incoming is one value from before the loop is that value wherever the loop exits
      // (the walker binds it); any other phi joining the exits holds the value of the edge the exiting trip took,
      // which depends on the quantum exit (rule 14: quantum), whatever its type: captured per field below.
      if (!isQ(&P)) {
        const Value *v0 = P.getIncomingValue(0);
        auto *vi = dyn_cast<Instruction>(v0);
        if (all_of(P.incoming_values(), [&](const Value *v) { return v == v0; }) && !(vi && inUnit(vi->getParent())))
          continue;
      }
      // cq-h8y6: an incoming from a tail block (Exits.h) on the outside paths, not classically excluded from the
      // unit: the walker selects it in over this binding (the unit's capture), a classical one it joins.
      for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
        if (BasicBlock *u = P.getIncomingBlock(i); is_contained(UX.tail, u) && !exits::inTailLoopUnit(L, UX, u, LoopInfo(*mxDT))) {
          Pred e = exits::tailPred(ctx, L, UX, u, *mxDT) & ctx.preds().edge(u, UX.cont);
          if (!e.isBottom() && !(e & hb.classicalFactor(ctx.T, ctx.S)).isBottom())
            ctx.addJoinArm(&P, e, P.getIncomingValue(i));
        }
      for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
        if (!inUnit(P.getIncomingBlock(i)) && !(ctx.preds().edge(P.getIncomingBlock(i), UX.cont) & hb).isBottom())
          unimplemented("loops-classical: a phi joining a case-3 loop's exits with an incoming from outside the loop "
                        "on an edge that does not exclude the loop",
                        &P);
      cphis.push_back({&P});
    }
    for (const Instruction *x : xreads)
      cphis.push_back({nullptr, x});
  }

  // Case 3: the exit test.
  SmallVector<Disj, 4> ds;
  SmallPtrSet<const Value *, 8> skip;
  // The quantum disjuncts: one leaf q (exit when q == qPos), or several, whose disjunction qExitP is one
  // flag (rule 8: a disjunction of flags is or_i1).
  const Value *qLeaf = nullptr;
  bool qPos = false;
  Pred qExitP = Pred::bottom();
  unsigned nQ = 0;
  if (c3 && !mx) {
    auto *br = dyn_cast<BranchInst>(latch->getTerminator());
    if (!br || !br->isConditional() || !isQ(br->getCondition()))
      internalError("loops-classical: a case-3 loop whose latch is no quantum conditional branch",
                    latch->getTerminator());
    bool exitOnTrue = !L.contains(br->getSuccessor(0));
    disjuncts(br->getCondition(), exitOnTrue, ds, skip);
    bool anyClassical = false;
    for (const Disj &d : ds) {
      if (!isQ(d.v)) {
        anyClassical = true;
        continue;
      }
      qExitP = qExitP | (d.pos ? Pred::atom(d.v) : !Pred::atom(d.v));
      ++nQ;
      qLeaf = d.v;
      qPos = d.pos;
    }
    if (!anyClassical || !qLeaf)
      internalError("loops-classical: a case-3 exit test without a classical and a quantum disjunct", br);
    // An inner node of the test is not lowered when nothing but the test reads it.
    for (bool changed = true; changed;) {
      changed = false;
      for (const Value *n : SmallVector<const Value *, 8>(skip.begin(), skip.end()))
        for (const User *u : n->users())
          if (u != br && !skip.count(u)) {
            skip.erase(n);
            changed = true;
            break;
          }
    }
    // CR rule 14 (ruling 2026-11-02, cq-w3cd): a classical value of the loop read after it has a quantum exit
    // value (it depends on which trip the quantum exit ended; taint reads it as quantum there, cq-1v3i): it
    // takes a capture rail like a quantum value, cap_j = select(a_{j-1}, v_j, cap_{j-1}) with v_j the trip's
    // classical value, a record of the trip uncomputed by the reverse after its readers (nothing kept).
  }

  plan6.clear();
  // cq-h5uj: inside a K-loop trip the loop's final value is a value of that trip (the K-loop selects it into
  // its state and its mirror undoes the trip), never a register of the program: no rule 6 chain keeps it.
  if (outermost && !inTrip)
    planRuleSix(L, c);
    if (c != Case::ClassicalBoundQuantumExit)
      planRuleSixMerges(L);

  // Entry: the trip predicate, the seeds.
  unsigned seedScope = 0;
  Value *aInit = nullptr;
  BasicBlock *seedHead = ctx.B().GetInsertBlock();
  if (outermost)
    ownSeedScope = seedScope = ctx.unc().openScope();
  // a_{-1} is minted inside the outermost loop's seed scope, so Z tears it down after the reverse (cq-t71u): under
  // a classical guard its definition does not dominate the return and no exit flush could free it. An atom rail
  // flag() returns has no record in the scope and is untouched.
  if (c3) {
    Pred hp = qp(header);
    if (!hp.isTop())
      aInit = ctx.preds().flag(ctx, hp);
  }
  // CR rule 14 (`continue`, `return` inside a K-loop, nested loops: "same chain, inner chain seeded by the
  // outer trip predicate"): a case-3 loop nested in a case-3 trip seeds its chain with the outer trip rail
  // (and its header's arm flag): a_{-1} = a_outer & F, a fresh rail (gates on fresh rails only).
  if (c3 && outerTrip) {
    if (!aInit) {
      aInit = outerTrip;
    } else {
      Value *both = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
      gate(abi::Core::AndI1, {outerTrip, aInit, both});
      aInit = both;
    }
  }
  if (c3 && !aInit)
    aInit = seed(ConstantInt::getTrue(ctx.M.getContext()), RailType{Kind::Int, 1});
  // CR rules 14, 16: inside a K-loop's trip an edge into a noreturn arm is an exit edge of that K-loop too (a_K, cq-9isy0).
  // The stop rail is the XOR of this unit's arm flags (at most one reads 1), an exit rail handed to the K-loop: carried like
  // the trip predicate, a fresh rail per arm flag (gates on fresh rails only).
  if (outermost && inTrip && exits::hasNoreturnArm(L)) {
    stopCur = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
    externalInits.push_back(stopCur);
  }
  else if (aInit && outermost)
    externalInits.push_back(aInit);
  BasicBlock *entryFrom = cur;
  struct Carried {
    PHINode *orig;
    PHINode *np;
    bool q;
    bool walked = false;   // cq-e6ky: a walked pointer carried as its trip index (walkedStep)
  };
  std::vector<Carried> carried;
  std::vector<std::pair<Value *, bool>> inits;
  // A header phi's start: its incoming from the preheader, or, with several blocks outside the loop entering
  // the header (no preheader), the one value they agree on, else their merge: the walker's classical phi of
  // its edges into the header (the spine's, bound before the unit, for the outermost loop; this walk's real
  // edges for a sub-loop), and for a quantum phi rule 9's select chain over the entry edges' predicates
  // (outermost) or a phi of handles over the real entry edges, a classical incoming seeded at the end of its
  // edge's output block (rule 7).
  SmallVector<BasicBlock *, 4> outsideP;
  for (BasicBlock *u : predecessors(header))
    if (!L.contains(u) && !is_contained(outsideP, u))
      outsideP.push_back(u);
  std::unique_ptr<DominatorTree> sDT = std::make_unique<DominatorTree>(*header->getParent());
  std::unique_ptr<LoopInfo> sLI = std::make_unique<LoopInfo>(*sDT);
  auto startOf = [&](PHINode &p) -> Operand {
    // The continuation of a loop just before this one: that unit bound p on its exit edge.
    if (isQ(&p) && exits::boundByLoopBefore(ctx, p, *sLI))
      return ctx.operand(&p);
    if (pre)
      return ctx.operand(p.getIncomingValueForBlock(pre));
    Value *v0 = p.getIncomingValueForBlock(outsideP.front());
    if (all_of(outsideP, [&](BasicBlock *u) { return p.getIncomingValueForBlock(u) == v0; }))
      return ctx.operand(v0);
    const bool q = isQ(&p);
    // An exit arm's loop entered by several arm edges: the arm walk's rule 9 merge over its own edge flags.
    if (outermost && startsBound)
      return ctx.operand(&p);
    if (outermost) {
      if (!q) {
        Operand v = ctx.operand(&p);
        if (v.handle)
          internalError("loops-classical: a classical carried value's start bound to a rail", &p);
        return v;
      }
      std::vector<std::pair<Pred, Operand>> arms;
      for (BasicBlock *u : outsideP)
        arms.push_back({ctx.preds().edge(u, header), ctx.operand(p.getIncomingValueForBlock(u))});
      return Operand{selectChain(ctx, arms, railOf(p.getType())), true};
    }
    PHINode *np = PHINode::Create(q ? handleTy(ctx.M.getContext()) : p.getType(), outsideP.size(), p.getName());
    np->insertInto(cur, cur->getFirstNonPHIIt());
    for (BasicBlock *u : outsideP) {
      auto it = edgeFrom.find({u, header});
      if (it == edgeFrom.end() || pred_size(cur) != outsideP.size() || !is_contained(predecessors(cur), it->second))
        internalError("loops-classical: a sub-loop entered by several edges that are not real edges into its "
                      "entry block",
                      &p);
      Operand o = ctx.operand(p.getIncomingValueForBlock(u));
      if (q && !o.handle) {
        IRBuilderBase::InsertPointGuard g(ctx.B());
        ctx.B().SetInsertPoint(it->second->getTerminator());
        o = Operand{seed(o.v, railOf(p.getType())), true};
      }
      np->addIncoming(o.v, it->second);
    }
    if (q)
      ctx.unc().recordMerge(np);
    return Operand{np, q};
  };
  for (PHINode &p : header->phis()) {
    Operand o = startOf(p);
    bool q = isQ(&p);
    if (const R6 *r = q ? r6Of(&p) : nullptr) {
      // Trip 0 cleans the rail its phi names: a fresh seed, this function's own dead rail, or else a
      // copy of the initial value (which then stays as it is, as in straight-line code). Each is kept
      // for Uncompute: the trip's clean-up frees it.
      Value *h;
      if (!o.handle) {
        h = asHandle(o, p.getType());
      } else if (r->initLoad) {
        // Rule 5 sentence 1 decides the load copy: the phi names it, trip 0 does not clean it.
        externalInits.push_back(o.v);
        inits.push_back({o.v, true});
        continue;
      } else if (r->initDirect) {
        h = o.v;
      } else {
        RailType w = railOf(p.getType());
        CallInst *c0 = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                    {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
        CallInst *cc = ctx.emitCore(abi::CoreSpec{abi::Core::Copy, w}, {o.v, c0});
        ctx.unc().noteUse(ctx.unc().idOf(o.v), cc);
        ctx.unc().recordExternal(c0, Role::UserRegister);
        h = c0;
      }
      ctx.unc().setRole(ctx.unc().idOf(h), Role::UserRegister);
      inits.push_back({h, true});
    } else if (q) {
      Value *h = asHandle(o, p.getType());
      if (o.handle && outermost)
        externalInits.push_back(h);
      inits.push_back({h, true});
    } else {
      if (o.handle)
        internalError("loops-classical: a classical carried value with a rail as its initial value", &p);
      inits.push_back({o.v, false});
    }
  }
  // Case 3: capture rails for values read after the loop that are no carried value's next.
  std::vector<std::pair<const Instruction *, PHINode *>> caps;
  std::vector<Value *> capInits;
  DenseMap<const Value *, PHINode *> nextOf;   // a carried value's next -> its header phi (orig)
  if (c3) {
    for (PHINode &p : header->phis())
      if (isQ(&p))
        nextOf[p.getIncomingValueForBlock(latch)] = &p;
    for (const Instruction *v : liveOut)
      if (!nextOf.count(v)) {
        if (!(v->getType()->isIntegerTy() || v->getType()->isFloatingPointTy()))
          unimplemented("loops-classical: a non-scalar value read after a case-3 loop", v);
        RailType w = railOf(v->getType());
        capInits.push_back(seed(Constant::getNullValue(irTypeOf(ctx.M.getContext(), w)), w));
      }
    for (CPhi &cp : cphis) {
      Type *ty = cp.type();
      LLVMContext &C = ctx.M.getContext();
      if (ty->isAggregateType() || ty->isVectorTy()) {
        std::function<void(Type *)> leaves = [&](Type *t) {
          if (auto *st = dyn_cast<StructType>(t))
            for (Type *e : st->elements())
              leaves(e);
          else if (auto *at = dyn_cast<ArrayType>(t))
            for (uint64_t k = 0; k < at->getNumElements(); ++k)
              leaves(at->getElementType());
          else if (auto *vt = dyn_cast<FixedVectorType>(t))
            for (unsigned k = 0; k < vt->getNumElements(); ++k)
              leaves(vt->getElementType());
          else
            cp.rails.push_back(railOf(t));
        };
        leaves(ty);
      } else {
        cp.rails = {railOf(ty)};
      }
      // The capture's start: the value where no trip exits. A phi's incomings from outside the unit on a quantum edge
      // that excludes the loop (a pre-header guard, strlen's `!*s`) are taken exactly where the trip predicate is 0 from
      // the start: rule 9's select chain over those edges, built here; a classical skip is the walker's join.
      std::vector<std::pair<Pred, Operand>> outside;
      // Rules 9, 14: a phi an earlier unit bound (this loop lies in that unit's tail): where no trip exits it keeps that unit's value.
      // Its incomings from other loops are that unit's: read here they would give those loops' values after their last trip.
      if (cp.P && cp.rails.size() == 1 && outermost && !inTrip && ctx.bound(cp.P)) {
        Operand acc = ctx.operand(cp.P);
        if (acc.handle) {
          LoopInfo LI(*mxDT);
          Pred ran = Pred::bottom();
          for (unsigned i = 0; i < cp.P->getNumIncomingValues(); ++i)
            if (BasicBlock *u = cp.P->getIncomingBlock(i); !inUnit(u) && LI.getLoopFor(u))
              ran = ran | ctx.preds().edge(u, UX.cont);
          // A sibling on classically exclusive paths (tail_phis) has its own value: the walker joins the two.
          if (predsMeet(ran, ctx.preds().block(header).classicalFactor(ctx.T, ctx.S))) {
            capInits.push_back(reachingOperand(ctx, acc, cp.rails.front(), ran, Pred::top()).v);
            continue;
          }
        }
      }
      if (cp.P && cp.rails.size() == 1) {
        const Pred hb = ctx.preds().block(header);
        const Pred cH = hb.classicalFactor(ctx.T, ctx.S);
        for (unsigned i = 0; i < cp.P->getNumIncomingValues(); ++i) {
          BasicBlock *u = cp.P->getIncomingBlock(i);
          const Pred &e = ctx.preds().edge(u, UX.cont);
          // predsMeet: two case atoms of one scrutinee exclude each other (clang's cleanup-dest switch after a loop).
          if (inUnit(u) || !predsMeet(e, cH) || predsMeet(e, hb))
            continue;
          Value *v = cp.P->getIncomingValue(i);
          if ((!ctx.bound(v) && !isa<Constant>(v)) || !predReadable(ctx, e)) {
            ctx.addJoinArm(cp.P, e, v);   // lowered after the loop: the walker selects it in
            continue;
          }
          Operand o = ctx.operand(v);
          if (ty->isPointerTy() && !o.handle)
            o = Operand{ctx.B().CreatePtrToInt(o.v, Type::getInt64Ty(C)), false};
          outside.push_back({e, o});
        }
      }
      if (outside.size() == 1) {
        capInits.push_back(asHandle(outside.front().second, ty->isPointerTy() ? Type::getInt64Ty(C) : ty));
        continue;
      }
      if (outside.size() > 1) {
        capInits.push_back(selectChain(ctx, outside, cp.rails.front()));
        continue;
      }
      for (RailType w : cp.rails)
        capInits.push_back(seed(Constant::getNullValue(irTypeOf(C, w)), w));
    }
  }
  // cq-v1fu, cq-03rdt (CR rules 14, 23; cq/FenvCarry.h step 1): every piece of the environment a trip may change, its rail at
  // the entry. The reverse reads it as it reads a quantum header phi's initial rail.
  std::vector<fenv::CarriedPiece> fenvPieces = fenv::loopCarried(ctx, L);
  if (outermost)
    for (const fenv::CarriedPiece &pc : fenvPieces)
      externalInits.push_back(pc.init);
  BasicBlock *H = newBlock();
  ctx.B().CreateBr(H);
  if (outermost) {
    ctx.unc().closeScope(seedScope);
    // Rules 5, 9, 14: a rail the entry's predicate minted on an edge into a join above the loop (a don't-care seed of a carried
    // flag: mbsrtowcs) exists on that edge's paths only, which the reverse's end does not imply; a flush frees it under its run flag.
    ctx.unc().leaveScope(seedScope, seedHead);
    segOpen = false;
  }
  startSeg(H);
  addHead(H, entryFrom);
  {
    unsigned k = 0;
    for (PHINode &p : header->phis()) {
      auto [v, q] = inits[k++];
      PHINode *np = ctx.B().CreatePHI(q ? handleTy(ctx.M.getContext()) : v->getType(), 2, p.getName());
      np->addIncoming(v, entryFrom);
      if (q) {
        ctx.unc().recordExternal(np, Role::UserRegister);
        if (!r6Of(&p))
          ctx.unc().noteCarried(np);
      }
      if (ctx.bound(&p))
        ctx.rebind(&p, {Operand{np, q}});   // the spine's classical choice of several starts (its operand above)
      else
        ctx.bind(&p, np);
      carried.push_back({&p, np, q, false});
    }
  }
  // Steps 2-3: each piece is a carried handle phi the trip reads; its back-edge incoming is the piece at the end of the trip.
  std::vector<std::pair<unsigned, PHINode *>> fenvPhis;
  for (const fenv::CarriedPiece &pc : fenvPieces) {
    PHINode *np = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), 2, "cq.fenv");
    np->addIncoming(pc.init, entryFrom);
    ctx.unc().recordExternal(np, Role::UserRegister);
    ctx.unc().noteCarried(np);
    fenv::bindPiece(ctx, pc.id, np);
    fenvPhis.push_back({pc.id, np});
  }
  PHINode *notFirst = nullptr;
  if (any_of(plan6, [&](const R6 &r) { return r.initLoad && L.contains(r.p); })) {
    notFirst = ctx.B().CreatePHI(Type::getInt1Ty(ctx.M.getContext()), 2, "nfirst");
    notFirst->addIncoming(ConstantInt::getFalse(ctx.M.getContext()), entryFrom);
  }
  PHINode *aPhi = nullptr;
  Value *aCur = nullptr;   // multi-exit: the trip predicate after the quantum exits so far
  if (c3) {
    aPhi = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), 2, "trip");
    aPhi->addIncoming(aInit, entryFrom);
    ctx.unc().recordExternal(aPhi, Role::UserRegister);
    aCur = aPhi;
    unsigned nf = 0;
    for (const CPhi &cp : cphis)
      nf += unsigned(cp.rails.size());
    unsigned at = unsigned(capInits.size()) - nf;
    for (CPhi &c : cphis)
      for (unsigned f = 0; f < c.rails.size(); ++f) {
        PHINode *cp = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), 2, "xcap");
        cp->addIncoming(capInits[at++], entryFrom);
        ctx.unc().recordExternal(cp, Role::UserRegister);
        c.cap.push_back(cp);
        c.run.push_back(cp);
        c.runOut.emplace_back();
      }
    unsigned k = 0;
    for (const Instruction *v : liveOut)
      if (!nextOf.count(v)) {
        PHINode *cp = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), 2, "cap");
        cp->addIncoming(capInits[k++], entryFrom);
        ctx.unc().recordExternal(cp, Role::UserRegister);
        caps.push_back({v, cp});
      }
  }

  PHINode *stopPhi = nullptr;
  if (stopCur) {
    stopPhi = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), 2, "stop");
    stopPhi->addIncoming(stopCur, entryFrom);
    ctx.unc().recordExternal(stopPhi, Role::UserRegister);
    stopCur = stopPhi;
  }

  // cq-h8y6: a value's fields as the continuation phi (or read after the loop) cp takes it, at the builder: a data
  // pointer's fat (tag, idx) at cp's exit shape (rule 21), an aggregate's or vector's scalar leaves (rule 26), a
  // scalar itself (a classical code address as its i64, rule 13).
  auto fieldsOf = [&](CPhi &cp, const Value *val) -> SmallVector<Operand, 2> {
    Type *ty = cp.type();
    if (ty->isAggregateType() || ty->isVectorTy()) {
      SmallVector<Operand, 4> fs = aggr::flattenResult(ctx, val);
      return SmallVector<Operand, 2>(fs.begin(), fs.end());
    }
    Operand o = ctx.operand(val);
    if (ty->isPointerTy() && !o.handle)
      o = Operand{ctx.B().CreatePtrToInt(o.v, Type::getInt64Ty(ctx.M.getContext())), false};
    return {o};
  };

  // The body walk.
  const Pred hq = qp(header);
  // Multi-exit: a block on every path of a trip that goes on (it dominates the latch) is in no arm: its
  // predicate's extra conjuncts are the negated quantum exits, which the trip predicate a carries.
  // cq-t30vh (CR rule 14 with rules 8, 9; the spine's cq-h8y6 inside a trip): a sub-unit's TAIL (Exits.h). The unit lowers it per
  // trip for its own paths. On the paths that enter it from outside the unit it is a part of this trip like any other block,
  // walked after the unit under those paths' predicate (kTailPred), its values this walk's. inTail: that assumption is on.
  DenseMap<const BasicBlock *, Loop *> kTail;
  DenseMap<const BasicBlock *, Pred> kTailPred;
  std::optional<Pred> baseAssumed;
  bool inTail = false;
  auto armed = [&](const BasicBlock *u) {
    if (mx && mxDT->dominates(u, latch))
      return false;
    if (auto tp = kTailPred.find(u); tp != kTailPred.end()) {
      std::optional<Pred> was = ctx.preds().assume(tp->second, ctx.T, ctx.S);
      bool r = !samePred(qp(u), hq);
      ctx.preds().assume(was, ctx.T, ctx.S);
      return r;
    }
    return !samePred(qp(u), hq);
  };
  auto subOf = [&](const BasicBlock *b) -> Loop * {
    for (Loop *s : L.getSubLoops())
      if (s->contains(b))
        return s;
    return nullptr;
  };
  // CR rule 14 (nested K-loops, "inner chain seeded by the outer trip predicate"): a quantum-exit sub-loop
  // is one node of the trip, lowered by loops-cutoff (exits::lowerNestedCutoff) as a K-loop nested in a
  // K-loop is: one rolled trip inside this walk's region at the trip's open block under its seed (a classical branch of a trip a real
  // branch whose blocks are segments of this walk, cq-kk46l: branchSeg), its unit (the loop, its exit
  // arm, its noreturn and dead arms) always ending at its continuation C, every phi of C with an incoming
  // from the unit bound by it. kOf: the unit's blocks inside L -> the sub-loop.
  DenseMap<const BasicBlock *, Loop *> kOf;
  // A case-3 sub-loop with several exits (its exit arm, lowered with it) is such a unit too: its classical
  // exit is a real branch into C, its C phis bound by it. "Several exits" is lowerLoop's multi-exit form (mx): several live
  // exit blocks, a noreturn arm, or a live exit edge from a block other than the latch (cq-aqr5v: two exiting blocks into one
  // hub).
  auto c3Multi = [&](Loop &s) {
    exits::Unit SU = exits::unitOf(s);
    return SU.multi() || exits::liveExiting(s) != s.getLoopLatch() || !SU.abort.empty();
  };
  for (Loop *s : L.getSubLoops())
    if (Case sc = classify(*s, ctx.T, ctx.S);
        sc == Case::QuantumExit || (sc == Case::ClassicalBoundQuantumExit && c3Multi(*s))) {
      exits::Unit SU = exits::unitOf(*s);
      for (BasicBlock *b : s->blocks())
        kOf[b] = s;
      for (auto *list : {&SU.arm, &SU.abort, &SU.dead})
        for (BasicBlock *b : *list)
          if (L.contains(b))
            kOf[b] = s;
    }
  {
    SmallVector<Loop *, 4> kLoops;
    for (Loop *s : L.getSubLoops())
      if (any_of(s->blocks(), [&](const BasicBlock *b) { return kOf.count(b) != 0; }))
        kLoops.push_back(s);
    for (Loop *s : kLoops) {
      exits::Unit SU = exits::unitOf(*s);
      for (BasicBlock *b : SU.tail) {
        if (!L.contains(b))
          continue;
        if (kTailPred.empty()) {
          baseAssumed = ctx.preds().assume(std::nullopt, ctx.T, ctx.S);
          ctx.preds().assume(baseAssumed, ctx.T, ctx.S);
        }
        kTail.try_emplace(b, s);
        kTailPred.try_emplace(b, exits::tailPred(ctx, *s, SU, b, spine::shared(ctx).dt(*header->getParent())));
        // A loop of the tail (or its exit arm) stays a unit of its own; any other tail block is a block of this trip.
        kOf.erase(b);
        for (Loop *o : kLoops)
          if (o != s && exits::unitOf(*o).contains(*o, b))
            kOf[b] = o;
      }
    }
  }
  auto kunit = [&](const BasicBlock *b) -> Loop * { return kOf.lookup(b); };
  // The unit's own edge into its tail block s: no edge of this walk (the unit's trips took it).
  auto unitEdgeIntoTail = [&](const BasicBlock *p, const BasicBlock *s) {
    Loop *t = kTail.lookup(s);
    return t && kunit(p) == t;
  };
  // The classical fact on the edge p -> b where p's flow ran (rule 8): p's fact and the edge's classical
  // factor; a K-unit's edge into its continuation holds wherever the unit ran (it always ends there).
  auto edgeFact = [&](const BasicBlock *p, const BasicBlock *b) {
    auto it = factOf.find(p);
    Pred f = it == factOf.end() ? Pred::top() : it->second;
    if (Loop *k = kunit(p); k && kunit(b) != k)
      return f;
    // cq-zueka (CR rule 8): a classical terminator's edge is a real branch, taken exactly where its condition holds, also a
    // disjunction (several switch cases into b), which the factor of the edge's predicate (its classical literals) drops under
    // a quantum arm: the edge's classical projection is its fact.
    const Pred e = ctx.preds().edge(p, b);
    const Instruction *t = p->getTerminator();
    const Value *c = nullptr;
    if (auto *sw = dyn_cast<SwitchInst>(t))
      c = sw->getCondition();
    else if (auto *ib = dyn_cast<IndirectBrInst>(t))
      c = ib->getAddress();
    else if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional())
      c = br->getCondition();
    return f & (c && !isQ(c) && !e.isBottom() ? e.classicalProjection(ctx.T, ctx.S) : cfOf(e));
  };
  // The phis of a K-unit's continuation that the unit bound (their value where the unit ran), and the
  // output block each unit's flow leaves from with the edge that stands for its exits (real form).
  DenseSet<const PHINode *> kBound;
  DenseMap<const Loop *, const BasicBlock *> kRep;
  auto fwdPreds = [&](const BasicBlock *s) {
    SmallVector<const BasicBlock *, 4> ps;
    Loop *sl = subOf(s);
    Loop *ks = kunit(s);
    for (const BasicBlock *p : predecessors(s))
      if (!(sl && sl->contains(p)) && !(ks && kunit(p) == ks) && !unitEdgeIntoTail(p, s) && !is_contained(ps, p))
        ps.push_back(p);
    return ps;
  };
  enum class EK { Linear, Merge, Real };
  // cq-vs1eo (CR rule 14 with rules 8, 9): a classical region nested in a quantum arm whose arms leave straight for a join
  // that other linearized code of the trip still has to reach (`if (q) { if (c) a; else b; } else { ... }` meeting at one
  // block). The walk rejoins the region in a block of its own (rejoin, below): its real edges into the join end there, and
  // the open flow goes on from it. Such an edge is a linearized incoming of the join from then on, with the rejoin's fact
  // and, per phi of the join, the rejoin's value.
  DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, Pred> rejoinFact;
  DenseMap<std::pair<const PHINode *, const BasicBlock *>, Operand> rejoinVal;
  // cq-11qhg: linearized edges into a classical join whose open flow ended in a real branch into it (flowInto, below).
  DenseSet<std::pair<const BasicBlock *, const BasicBlock *>> flowReal;
  auto termQ = [&](const Instruction *t) {
    if (auto *br = dyn_cast<BranchInst>(t))
      return br->isConditional() && isQ(br->getCondition());
    if (auto *sw = dyn_cast<SwitchInst>(t))
      return isQ(sw->getCondition());
    if (auto *ib = dyn_cast<IndirectBrInst>(t))
      return isQ(ib->getAddress());   // rule 13: a switch on the address
    return false;
  };
  // A K-unit's edges into its continuation C: one linearized edge (the unit's code runs in the open block,
  // under its seed), unless C is also entered by a real edge from outside the unit (a classical skip of the
  // loop): then the unit ends in a real branch to C, a classical join.
  // A classical test with an edge into a noreturn arm that is not the bound (cxb): the arm runs in the trip, at the test,
  // and the test leaves no other trace (abortTest): its one other successor continues the trip.
  auto isAbortTest = [&](const BasicBlock *u) {
    return !termQ(u->getTerminator()) && !(u == cxb && cxArm && is_contained(UX.abort, cxArm)) &&
           any_of(successors(u), [&](const BasicBlock *x) { return is_contained(UX.abort, x); });
  };
  auto abortTestNext = [&](const BasicBlock *u) -> BasicBlock * {
    auto *br = dyn_cast<BranchInst>(u->getTerminator());
    if (!br || !br->isConditional() || !isAbortTest(u))
      return nullptr;
    BasicBlock *a = br->getSuccessor(0), *b = br->getSuccessor(1);
    if (is_contained(UX.abort, a) == is_contained(UX.abort, b))
      return nullptr;
    return is_contained(UX.abort, a) ? b : a;
  };
  // A quantum exit test of a multi-exit trip before the latch (emitTerminator's qExit): its exit is the flags e and a', so the
  // trip goes on into its one successor inside the loop on every path, as through an unconditional branch (cq-11qhg).
  auto qExitNext = [&](const BasicBlock *u) -> BasicBlock * {
    auto *br = dyn_cast<BranchInst>(u->getTerminator());
    if (!mx || u == latch || !br || !br->isConditional() || !termQ(br))
      return nullptr;
    BasicBlock *a = br->getSuccessor(0), *b = br->getSuccessor(1);
    if (L.contains(a) == L.contains(b) || a == header || b == header)
      return nullptr;
    return L.contains(a) ? a : b;
  };
  std::function<EK(const BasicBlock *, const BasicBlock *)> edgeKind;
  // A tail block entered from outside the unit both by a linearized edge (a quantum skip of the loop, in the unit's classical
  // arm) and by a real one: the open flow runs on through it, so the K-unit ends in a real branch to it, not to C.
  auto kInto = [&](Loop *k) -> BasicBlock * {
    if (classify(*k, ctx.T, ctx.S) != Case::QuantumExit)
      return nullptr;
    for (BasicBlock *tb : exits::unitOf(*k).tail) {
      if (kTail.lookup(tb) != k)
        continue;
      bool anyReal = false, anyLin = false;
      for (const BasicBlock *p : fwdPreds(tb))
        if (kTail.lookup(p) != k)
          (edgeKind(p, tb) == EK::Real ? anyReal : anyLin) = true;
      if (anyReal && anyLin)
        return tb;
    }
    return nullptr;
  };
  auto kReal = [&](Loop *k) {
    if (classify(*k, ctx.T, ctx.S) != Case::QuantumExit)
      return true;   // a classically bounded unit leaves by its classical exit
    if (kInto(k))
      return false;   // its flow reaches C through the tail
    BasicBlock *C = exits::unitOf(*k).cont;
    for (const BasicBlock *p : fwdPreds(C))
      if (!kunit(p) && edgeKind(p, C) == EK::Real) {   // another K-unit's edge into C never makes this one real
        // Its tail's edge on paths that share the unit's classical facts: a mixed join, the unit's edge linearized.
        if (auto tp = kTailPred.find(p); tp != kTailPred.end() && kTail.lookup(p) == k &&
                                         !(cfOf(tp->second) & cfOf(ctx.preds().block(k->getHeader()))).isBottom())
          continue;
        return true;
      }
    // A classical edge into the unit's tail: the unit's paths leave by a real branch past the tail.
    for (BasicBlock *tb : exits::unitOf(*k).tail)
      if (kTail.lookup(tb) == k)
        for (const BasicBlock *p : fwdPreds(tb))
          if (kTail.lookup(p) != k && edgeKind(p, tb) == EK::Real)
            return true;
    return false;
  };
  // r8 (CR rules 8, 14; SQLite isDate): the classical fact the classical branches of the trip establish at u. A classical
  // conjunct of a block's predicate that comes from a quantum test (the false edge of `c || q`, one flag under rule 8; the C
  // of `C && Q`, on which the trip builds no branch) is in its predicate but opens no classical region: the block's flow is
  // the open flow, not an output block of its own, and its edge into a join is linearized (GSL gsl_cdf_tdist_Pinv).
  DenseMap<const BasicBlock *, Pred> estMemo;
  std::function<Pred(const BasicBlock *)> estFact = [&](const BasicBlock *u) -> Pred {
    if (u == header || !L.contains(u))
      return cfOf(ctx.preds().block(u));
    if (Loop *n = subOf(u) ? subOf(u) : kunit(u); n && n->getHeader() != u)
      return estFact(n->getHeader());
    if (auto it = estMemo.find(u); it != estMemo.end())
      return it->second;
    Pred f = Pred::bottom();
    for (const BasicBlock *p : fwdPreds(u)) {
      Pred fp = estFact(p);
      // An abort test runs its noreturn arm in the trip and leaves no branch (emitTerminator): it establishes nothing either.
      const bool lin = (termQ(p->getTerminator()) && !(p == cxb && !mixedDs.empty())) || isAbortTest(p);
      // A sub-loop's exit edge stands for the loop as a unit (its function-wide edge, as in edgeFact); a K-unit's holds
      // wherever the unit ran.
      f = f | (lin || kunit(p) ? fp : fp & cfOf(subOf(p) ? ctx.preds().edge(p, u) : exits::tripEdge(p, u)));
    }
    return estMemo[u] = f;
  };
  std::function<EK(const BasicBlock *, const BasicBlock *)> edgeKindAt;
  // The form of an edge is one fact of the program, whichever block's walk asks: never read under a tail's assumption.
  edgeKind = [&](const BasicBlock *u, const BasicBlock *s) {
    if (!inTail)
      return edgeKindAt(u, s);
    inTail = false;
    std::optional<Pred> was = ctx.preds().assume(baseAssumed, ctx.T, ctx.S);
    EK k = edgeKindAt(u, s);
    ctx.preds().assume(was, ctx.T, ctx.S);
    inTail = true;
    return k;
  };
  edgeKindAt = [&](const BasicBlock *u, const BasicBlock *s) {
    if (rejoinFact.count({u, s}))
      return EK::Linear;
    if (flowReal.count({u, s}))
      return EK::Real;
    if (Loop *k = kunit(u); k && kunit(s) != k)
      return kReal(k) ? EK::Real : EK::Linear;
    if (subOf(u))
      return EK::Real;   // a sub-loop always ends in a real branch
    if (u == cxb && !mixedDs.empty())
      return EK::Real;   // cq-h8y6: a mixed exit test branches classically on its classical disjuncts
    const Instruction *t = u->getTerminator();
    if (termQ(t) && !qExitNext(u))
      return EK::Linear;
    if (auto *br = dyn_cast<BranchInst>(t); br && (!br->isConditional() || abortTestNext(u) || qExitNext(u))) {
      // A classical join inside a quantum arm (rule 8: the classical branch nested in the arm stays a
      // classical branch, and its arms meet again under the same quantum predicate) is a real join.
      if (armed(u)) {
        SmallVector<const BasicBlock *, 4> ps = fwdPreds(s);
        if (ps.size() > 1 && all_of(ps, [&](const BasicBlock *p) {
              return !termQ(p->getTerminator()) && samePred(qp(p), qp(s));
            }))
          return EK::Real;
        // An exit of a classical branch nested in the arm (u's classical factor is stronger than s's):
        // the classical arms' flows are distinct output blocks and meet at s by a real edge (a mixed
        // join when s is also a quantum join).
        // (A tail block's flow here is its outside paths'.)
        auto tu = kTailPred.find(u);
        const Pred uFact = tu != kTailPred.end() ? tu->second.classicalProjection(ctx.T, ctx.S) : estFact(u);
        if (!(estFact(s) & !uFact).isBottom()) {
          // Quantum arms under one classical fact that meet at s (strtod's `if (i < 7) { q ? a : b; }`): the code of the
          // later arm runs in the same open block, so only the last arm walked leaves by the real edge; the earlier ones
          // are its linearized incomings (the mixed join).
          const Pred uc = uFact;
          auto at = find(rpo, u);
          for (const BasicBlock *p : fwdPreds(s))
            if (p != u && !termQ(p->getTerminator()) && armed(p) && find(rpo, p) > at) {
              const Pred pc = estFact(p);
              if ((pc & !uc).isBottom() && (uc & !pc).isBottom())
                return EK::Linear;
            }
          return EK::Real;
        }
        return EK::Linear;
      }
      return fwdPreds(s).size() == 1 ? EK::Merge : EK::Real;
    }
    return EK::Real;
  };
  auto target = [&](const BasicBlock *s) -> BasicBlock * {
    if (s == header)
      return H;
    for (const ArmExit &e : armExits)
      if (e.u == tgtFrom && e.x == s)
        return e.Y;
    if (L.contains(s) || top.contains(s))
      return ob(s);
    // A classical switch's edge into a noreturn arm: abortTest ran the arm; the switch stands for its other edges.
    if (tgtFrom && is_contained(UX.abort, s) && isa<SwitchInst>(tgtFrom->getTerminator()))
      for (BasicBlock *o : successors(tgtFrom))
        if (!is_contained(UX.abort, o))
          return o == header ? H : (L.contains(o) || top.contains(o)) ? ob(o) : unitExit;
    return unitExit;   // cq-j5mq: an edge out of the whole unit, also from a sub-loop
  };

  // Next values of the carried phis, computed at the latch before its terminator.
  std::vector<Value *> nexts;
  auto latchNexts = [&]() {
    Value *notFirstNow = notFirst;
    for (Carried &cv : carried) {
      if (cv.walked) {
        // Rule 14 (affine induction, cq-e6ky): the walked pointer's trip index advances by one per trip.
        nexts.push_back(ctx.B().CreateAdd(cv.np, ConstantInt::get(cv.np->getType(), 1)));
        continue;
      }
      Operand o = ctx.operand(cv.orig->getIncomingValueForBlock(latch));
      if (!cv.q) {
        if (o.handle)
          internalError("loops-classical: a classical carried value whose next is a rail", cv.orig);
        nexts.push_back(o.v);
      } else if (const R6 *r = r6Of(cv.orig); r && r->merge) {
        // y' = select(c, a, b), one arm the old rail: t = c ? y' : U^-1(y') (or the arms swapped). U^-1(y') is garbage
        // the clean-up reads (noted as a use of y so the clean-up follows it).
        auto *sc = o.handle ? dyn_cast<CallInst>(o.v) : nullptr;
        const unsigned nargs = sc ? sc->arg_size() : 0;
        if (nargs != 3 || (sc->getArgOperand(1) != cv.np && sc->getArgOperand(2) != cv.np)) {
          noteUnbuilt("loops-classical: rule 6 on a merge that is no select of the old rail", cv.orig);
          nexts.push_back(asHandle(o, cv.orig->getType()));
          continue;
        }
        bool selfTrue = sc->getArgOperand(1) == cv.np;
        RailId old = ctx.unc().idOf(cv.np);
        ctx.unc().setRole(ctx.unc().idOf(o.v), Role::UserRegister);
        Inv inv = inverseOf(ctx, *r->U[0], r->p, o);
        Value *inner = ctx.emitTemplate(inv.spec, inv.ops);
        ctx.unc().noteUse(old, cast<Instruction>(inner));
        abi::TemplateSpec ss;
        ss.op = "select";
        ss.w = railOf(cv.orig->getType());
        Operand c{sc->getArgOperand(0), true}, y{o.v, true}, in{inner, true};
        SmallVector<Operand, 3> ops{c, selfTrue ? y : in, selfTrue ? in : y};
        if (r->initLoad)
          ctx.unc().cleanupBijectiveUnder(old, notFirstNow, ss, ops, /*everyPath=*/false);
        else
          ctx.unc().cleanupBijective(old, ss, ops);
        keptFinal.insert(o.v);
        spine::shared(ctx).carriedFinal.insert(o.v);
        nexts.push_back(o.v);
      } else if (const R6 *r = r6Of(cv.orig)) {
        Operand u = ctx.operand(r->U.back());
        if (!o.handle || !u.handle || o.v != u.v || !isa<Instruction>(o.v))
          internalError("loops-classical: rule 6 on a carried value whose update is not its next rail", cv.orig);
        RailType w = railOf(cv.orig->getType());
        RailId old = ctx.unc().idOf(cv.np);
        // cq-bqbty: the update may lie past a classical join of the trip (planRuleSix: a block dominating the latch at
        // the header's quantum predicate), in a later segment than the header's, and code after it in its segment may
        // branch (a memory intrinsic's loop, rule 5's Readers test). The clean-up of the old rail reads the update (case
        // 3: also the inverses emitted here), so flushTrips places it in the block that holds them.
        const bool inH = cast<Instruction>(o.v)->getParent() == H;
        if (!c3)
          for (unsigned i = 0; i < r->U.size(); ++i)   // the old rail and each intermediate rail of the chain
            lateR6.push_back({i ? ctx.unc().idOf(ctx.operand(r->U[i - 1]).v) : old, cast<Instruction>(o.v)});
        if (!c3) {
          if (!r->rotated)
            ctx.unc().setRole(ctx.unc().idOf(o.v), Role::UserRegister);
          for (unsigned i = r->U.size(); i-- > 0;) {
            const Value *prev = i ? r->U[i - 1] : r->p;
            Inv inv = inverseOf(ctx, *r->U[i], prev, ctx.operand(r->U[i]));
            ctx.unc().cleanupBijective(i ? ctx.unc().idOf(ctx.operand(prev).v) : old, inv.spec, inv.ops);
          }
          keptFinal.insert(o.v);
          spine::shared(ctx).carriedFinal.insert(o.v);
          nexts.push_back(o.v);
        } else {
          // y'' = a ? f(y) : y; t = a ? f^-1(y'') : y''. The inner f^-1(y'') is garbage the clean-up
          // reads (noted as a use of y so the clean-up follows it); f(y) is uncomputed first (rule 5).
          Value *sel = select(aPhi, o, Operand{cv.np, true}, w);
          ctx.unc().setRole(ctx.unc().idOf(sel), Role::UserRegister);
          Value *inner = sel;
          for (unsigned i = r->U.size(); i-- > 0;) {
            Inv inv = inverseOf(ctx, *r->U[i], i ? r->U[i - 1] : r->p, Operand{inner, true});
            inner = ctx.emitTemplate(inv.spec, inv.ops);
            ctx.unc().noteUse(old, cast<Instruction>(inner));
          }
          abi::TemplateSpec ss;
          ss.op = "select";
          ss.w = w;
          ctx.unc().cleanupBijective(old, ss, {Operand{aPhi, true}, Operand{inner, true}, Operand{sel, true}});
          if (!inH)
            lateR6.push_back({old, cast<Instruction>(inner)});
          keptFinal.insert(sel);
          spine::shared(ctx).carriedFinal.insert(sel);
          nexts.push_back(sel);
        }
      } else if (c3) {
        nexts.push_back(select(aCur, o, Operand{cv.np, true}, railOf(cv.orig->getType())));
      } else {
        nexts.push_back(asHandle(o, cv.orig->getType()));
      }
    }
    for (auto &[v, cp] : caps)
      cp->addIncoming(select(aPhi, ctx.operand(v), Operand{cp, true}, railOf(v->getType())), cur);
  };

  // The seeds minted for classical incomings of phis of handles (mintEdgeSeeds below), per (phi, edge source).
  DenseMap<std::pair<const PHINode *, const BasicBlock *>, Value *> &edgeSeed = edgeSeedM;
  // Mixed joins: the value of each phi of b on the real edge u -> b (mintEdgeSeeds).
  DenseMap<std::pair<const PHINode *, const BasicBlock *>, Value *> &edgeVal = edgeValM;
  // The value of a tail phi on the open flow a K-unit's real branch carries into it (kInto).
  DenseMap<const PHINode *, std::pair<BasicBlock *, Value *>> kFlowVal;
  auto emitPhis = [&](BasicBlock *b, bool real) {
    Loop *tk = kTail.lookup(b);
    for (PHINode &p : b->phis()) {
      bool q = isQ(&p);
      if (tk && !kBound.count(&p) && !real) {
        // cq-t30vh (the spine's tailMerge): a tail phi on the outside paths merges those paths' incomings only, each under its
        // edge's predicate on them.
        std::vector<std::pair<Pred, const Value *>> kept;
        for (unsigned i = 0; i < p.getNumIncomingValues(); ++i) {
          const BasicBlock *u = p.getIncomingBlock(i);
          if (kunit(u) == tk)
            continue;
          auto tu = kTailPred.find(u);
          Pred e = kTail.lookup(u) == tk && tu != kTailPred.end() ? tu->second & ctx.preds().edge(u, b) : ctx.preds().edge(u, b);
          const Value *v = p.getIncomingValue(i);
          auto same = find_if(kept, [&](const auto &k) { return k.second == v; });
          if (same != kept.end())
            same->first = same->first | e;
          else
            kept.push_back({e, v});
        }
        const bool composite = p.getType()->isAggregateType() || p.getType()->isVectorTy();
        if (kept.size() == 1 && composite) {
          ctx.bindFields(&p, aggr::flattenResult(ctx, kept.front().second));
          continue;
        }
        if (kept.size() == 1) {
          Operand o = ctx.operand(kept.front().second);
          ctx.bind(&p, q ? asHandle(o, p.getType()) : o.v);
          continue;
        }
        if (!composite && q && !kept.empty()) {
          std::vector<std::pair<Pred, Operand>> arms;
          for (auto &[e, v] : kept)
            arms.push_back({e, ctx.operand(v)});
          ctx.bind(&p, selectChain(ctx, arms, railOf(p.getType())));
          continue;
        }
        noteUnbuilt("loops-classical: a phi of a sub-unit's tail that merges a composite on the outside paths", &p);
      }
      if (kBound.count(&p)) {
        // A phi a nested K-unit bound: its value where the unit ran (rule 14), with the incomings it could
        // not read (lowered after it, on edges that exclude the loop) selected in where their edges hold
        // (rule 9, as the spine's cq-mgkr join arms). At a classical join (the unit's real form) each real
        // edge from outside the unit carries its own incoming (a seed where classical, rule 7).
        std::vector<std::pair<Pred, const Value *>> ja = ctx.takeJoinArms(&p);
        Operand uo = ctx.operand(&p);
        RailType w = railOf(p.getType());
        // At a mixed join each real edge's value already holds them (mixedEdge).
        if (!ja.empty() && !real) {
          std::vector<std::pair<Pred, Operand>> arms;
          Pred E = Pred::bottom();
          for (auto &[e, v] : ja) {
            Pred eq = e.quantumPart(ctx.T, ctx.S);
            E = E | eq;
            arms.push_back({eq, ctx.operand(v)});
          }
          arms.push_back({!E, uo});
          uo = Operand{selectChain(ctx, arms, w), true};
          ctx.rebind(&p, {uo});
        }
        if (!real)
          continue;
        if (!uo.handle)
          internalError("loops-classical: a K-unit bound a phi of its continuation to no rail", &p);
        // cq-aqr5v (cq-2xl5 in a trip): a case-3 sub-loop with classical exit tests besides its bound joined its exit edges'
        // values at ob(b) itself: uo is that join, the value on every edge of the unit.
        auto *unitJoin = dyn_cast<PHINode>(uo.v);
        if (unitJoin && unitJoin->getParent() != ob(b))
          unitJoin = nullptr;
        DenseSet<const Loop *> doneUnit;
        SmallVector<std::pair<BasicBlock *, Value *>, 4> ins;
        for (unsigned i = 0; i < p.getNumIncomingValues(); ++i) {
          BasicBlock *u = p.getIncomingBlock(i);
          if (edgeKind(u, b) != EK::Real)
            continue;
          Loop *k = kunit(u);
          if (k && (!doneUnit.insert(k).second || unitJoin))
            continue;
          const BasicBlock *ru = k ? kRep.lookup(k) : u;
          auto it = edgeFrom.find({ru, b});
          if (it == edgeFrom.end())
            internalError("loops-classical: a join edge with no output block", &p);
          Value *v;
          if (k) {
            v = uo.v;
          } else if (auto e = edgeVal.find({&p, u}); e != edgeVal.end()) {
            v = e->second;
          } else if (auto e2 = edgeSeed.find({&p, u}); e2 != edgeSeed.end()) {
            v = e2->second;
          } else {
            Operand o = ctx.operand(p.getIncomingValue(i));
            if (!o.handle)
              internalError("loops-classical: a classical incoming of a phi of handles with no edge seed", &p);
            v = o.v;
          }
          ins.push_back({it->second, v});
        }
        if (auto kf = kFlowVal.find(&p); kf != kFlowVal.end())
          ins.push_back(kf->second);
        if (unitJoin && ins.empty())
          continue;   // p is bound to the unit's join already
        PHINode *np = PHINode::Create(handleTy(ctx.M.getContext()), 2, p.getName());
        np->insertInto(ob(b), ob(b)->getFirstNonPHIIt());
        for (auto &[from, v] : ins)
          np->addIncoming(v, from);
        ctx.unc().recordMerge(np);
        ctx.rebind(&p, {Operand{np, true}});
        continue;
      }
      if (p.getNumIncomingValues() == 1 || all_of(p.incoming_values(), [&](const Value *v) {
            return v == p.getIncomingValue(0);
          })) {
        Operand o = ctx.operand(p.getIncomingValue(0));
        ctx.bind(&p, q ? asHandle(o, p.getType()) : o.v);
        continue;
      }
      if (!real) {
        if (!q)
          internalError("loops-classical: a classical phi at a linearized join", &p);
        // Every arm names one rail (a register rotated in place on one arm, rule 10; 126): the merge is
        // that rail, no choice to make (the spine's state-prep merge).
        Value *one = ctx.operand(p.getIncomingValue(0)).v;
        bool code = p.getType()->isPointerTy();   // rule 3: an i64 integer
        if (!p.getType()->isVectorTy() && !p.getType()->isAggregateType() && (!p.getType()->isPointerTy() || code) &&
            all_of(p.incoming_values(), [&](Value *v) { return ctx.operand(v).v == one; })) {
          ctx.bind(&p, asHandle(ctx.operand(p.getIncomingValue(0)), p.getType()));
          continue;
        }
        // cq-pfpy: a composite merges field by field (rule 26).
        if (p.getType()->isAggregateType() || p.getType()->isVectorTy())
          lowerMergeFields(ctx, p);
        else
          ctx.bind(&p, lowerMerge(ctx, p));
        continue;
      }
      // A classical join over handles (rule 9: a classical phi over the handles, no gate), field-wise for
      // a composite (rule 26: one phi per scalar leaf; a quantum leaf a phi of handles, a classical leaf a
      // classical phi). One incoming per output edge: a terminator with several edges to b (a switch's
      // cases) has one entry per edge in the original phi and in the output terminator alike, with the
      // same value (LLVM's rule). A real edge ends its output block, so an output block names one
      // original block. At a mixed join (a quantum join that classical branches nested in an arm also
      // reach) the edges absorbed by the linearization carry nothing: each real edge carries its value
      // (edgeVal, mintEdgeSeeds).
      const bool composite = p.getType()->isAggregateType() || p.getType()->isVectorTy();
      struct In {
        BasicBlock *from;
        SmallVector<Operand, 4> f;
      };
      SmallVector<In, 4> ins;
      DenseMap<BasicBlock *, BasicBlock *> from;
      for (unsigned i = 0; i < p.getNumIncomingValues(); ++i) {
        BasicBlock *u = p.getIncomingBlock(i);
        if (unitEdgeIntoTail(u, b) || edgeKind(u, b) != EK::Real)
          continue;   // absorbed by the linearization: its flow reaches b through a real edge
        auto it = edgeFrom.find({u, b});
        if (it == edgeFrom.end())
          internalError("loops-classical: a join edge with no output block", &p);
        if (auto [f, fresh] = from.insert({it->second, u}); !fresh && f->second != u)
          internalError("loops-classical: two original blocks leave through one output block on real edges", &p);
        In in{it->second, {}};
        if (auto e = edgeVal.find({&p, u}); e != edgeVal.end())
          in.f.push_back(Operand{e->second, true});
        else if (auto ef = edgeFieldsM.find({&p, u}); ef != edgeFieldsM.end())
          in.f = ef->second;
        else if (composite)
          in.f = aggr::flattenResult(ctx, p.getIncomingValue(i));
        else
          in.f.push_back(ctx.operand(p.getIncomingValue(i)));
        if (q && !composite && !in.f[0].handle)
          if (auto e = edgeSeed.find({&p, u}); e != edgeSeed.end())
            in.f[0] = Operand{e->second, true};
        ins.push_back(std::move(in));
      }
      if (auto kf = kFlowVal.find(&p); kf != kFlowVal.end())
        ins.push_back(In{kf->second.first, {Operand{kf->second.second, isQ(&p)}}});
      if (ins.empty())
        internalError("loops-classical: a real join with no real edge", &p);
      const unsigned nf = ins[0].f.size();
      SmallVector<Operand, 4> outF;
      for (unsigned k = 0; k < nf; ++k) {
        bool fq = false;
        for (In &in : ins) {
          if (in.f.size() != nf)
            internalError("loops-classical: incomings of one phi with different field counts", &p);
          fq |= in.f[k].handle;
        }
        if (fq && !q)
          internalError("loops-classical: a classical phi with a rail incoming", &p);
        if (fq) {
          // A classical leaf on some edge of a quantum leaf: a seed minted at the end of that edge's
          // output block (rule 7). Only composite leaves get here: a scalar's seed is mintEdgeSeeds'.
          for (In &in : ins)
            if (!in.f[k].handle) {
              if (!composite)
                internalError("loops-classical: a classical incoming of a phi of handles with no edge seed", &p);
              IRBuilderBase::InsertPointGuard g(ctx.B());
              ctx.B().SetInsertPoint(in.from->getTerminator());
              in.f[k] = Operand{seed(in.f[k].v, railOf(in.f[k].v->getType())), true};
            }
        }
        Type *ty = fq ? handleTy(ctx.M.getContext()) : ins[0].f[k].v->getType();
        PHINode *np = PHINode::Create(ty, ins.size(), p.getName());
        np->insertInto(ob(b), ob(b)->getFirstNonPHIIt());
        for (In &in : ins)
          np->addIncoming(in.f[k].v, in.from);
        if (fq)
          ctx.unc().recordMerge(np);
        outF.push_back(Operand{np, fq});
      }
      if (composite)
        ctx.bindFields(&p, outF);
      else
        ctx.bind(&p, outF[0].v);
    }
  };

  // A MIXED JOIN (rules 8, 9): s is a quantum join of arms one of which holds a classical branch whose arms
  // reach s directly (`if (q) { if (c) a; else b; }`): the linearized edges into s (from the quantum
  // branch, from arm blocks) carry no flow of their own, it went on through the classical branch; the
  // classical arms meet at s as a real join. On the real edge u -> s each phi of s is the rule-9 merge of
  // the incomings that edge's path can carry: u's own, and each linearized incoming whose classical fact
  // holds wherever u's edge is taken (an incoming whose fact excludes u's is not on that path), each under
  // its edge's quantum part (u's classical fact holds on that path). One select chain per edge, made at
  // the end of u's output block (rule 9: one select per distinct incoming, a fresh rail).
  auto mixedEdge = [&](BasicBlock *u, BasicBlock *s) {
    auto factAt = [&](const BasicBlock *p) {
      auto r = rejoinFact.find({p, s});
      return r != rejoinFact.end() ? r->second : edgeFact(p, s);
    };
    const Pred uf = factAt(u);
    for (PHINode &p : s->phis()) {
      if (edgeVal.count({&p, u}) || edgeFieldsM.count({&p, u}))
        continue;
      // A phi a K-unit bound, whose real edges are all from outside it: the unit's value where none of this edge's arms holds.
      Loop *kp = nullptr;
      if (kBound.count(&p)) {
        for (const BasicBlock *pi : p.blocks())
          if (Loop *k = kunit(pi) ? kunit(pi) : kTail.lookup(pi); k && !kp && !kReal(k))
            kp = k;
        if (!kp)
          continue;
      }
      const bool composite = p.getType()->isAggregateType() || p.getType()->isVectorTy();
      std::vector<std::pair<Pred, Operand>> arms;
      SmallVector<const Value *, 4> vals;
      std::optional<Pred> partFact;
      for (unsigned i = 0; i < p.getNumIncomingValues(); ++i) {
        BasicBlock *pi = p.getIncomingBlock(i);
        if (unitEdgeIntoTail(pi, s) || (kp && kunit(pi) == kp))
          continue;
        if (pi != u) {
          if (edgeKind(pi, s) == EK::Real)
            continue;   // another classical arm: not on u's path
          // cq-vs1eo (rules 8, 9, 14): an incoming from the other quantum arm, not walked yet (no fact), whose value does
          // not exist here: that flow runs after this region, which rejoin() closes into a block of its own; s then
          // joins it with the region's value as linearized incomings. On u's real edge only the region's flow.
          // r7: whatever its value (a literal, or one bound before: SQLite jsonExtractFunc), its edge's predicate reads that
          // arm's atoms, lowered only when it is walked.
          if (!factOf.count(pi))
            continue;
          Pred pf = factAt(pi);
          if ((uf & pf).isBottom())
            continue;
          // cq-ad51l (rule 9): pi's flow is on u's path only where its fact holds (sqlite jsonExtractFunc: `c2 ? J : q ? ..`
          // beside a region under `p != 0` in another quantum arm): its arm is chosen under that fact too.
          if (!(uf & !pf).isBottom())
            partFact = pf;
        }
        Pred e = ctx.preds().edge(pi, s).quantumPart(ctx.T, ctx.S);
        if (partFact) {
          e = e & *partFact;
          partFact.reset();
        }
        if (auto tp = kTailPred.find(pi); kp && tp != kTailPred.end())
          e = tp->second & ctx.preds().edge(pi, s);   // its classical atoms too: the unit's value is read where they exclude it
        const Value *v = p.getIncomingValue(i);
        auto rj = rejoinVal.find({&p, pi});
        if (rj != rejoinVal.end())
          v = rj->second.v;   // the rejoin's value of the region (cq-vs1eo)
        if (auto k = find(vals, v); k != vals.end()) {
          arms[k - vals.begin()].first = arms[k - vals.begin()].first | e;
          continue;
        }
        vals.push_back(v);
        arms.push_back({e, composite ? Operand{nullptr, false} : rj != rejoinVal.end() ? rj->second : ctx.operand(v)});
      }
      if (kp) {
        Pred E = Pred::bottom();
        for (auto &a : arms)
          E = E | a.first;
        if (!E.isTop())
          arms.push_back({!E, ctx.operand(&p)});
      }
      if (arms.empty())
        internalError("loops-classical: a real edge into a mixed join carries no incoming", &p);
      if (!isQ(&p)) {
        if (arms.size() > 1)
          internalError("loops-classical: a classical phi at a mixed join chosen by a quantum edge", &p);
        continue;   // the classical incoming of u's own edge (emitPhis)
      }
      if (p.getType()->isAggregateType() || p.getType()->isVectorTy()) {
        if (arms.size() == 1)
          continue;   // u's own incoming, field-wise (emitPhis)
        // cq-pfpy (rules 9, 26): a quantum choice of a composite is rule 9's select chain per field, made
        // at the end of u's output block like a scalar's.
        std::vector<SmallVector<Operand, 4>> fields;
        for (const Value *v : vals)
          fields.push_back(aggr::flattenResult(ctx, v));
        SmallVector<Type *, 8> leafTys;
        std::function<void(Type *)> leaves = [&](Type *t) {
          if (auto *st = dyn_cast<StructType>(t))
            for (Type *e : st->elements())
              leaves(e);
          else if (auto *at = dyn_cast<ArrayType>(t))
            for (uint64_t i = 0; i < at->getNumElements(); ++i)
              leaves(at->getElementType());
          else if (auto *vt = dyn_cast<FixedVectorType>(t))
            for (unsigned i = 0; i < vt->getNumElements(); ++i)
              leafTys.push_back(vt->getElementType());
          else
            leafTys.push_back(t);
        };
        leaves(p.getType());
        if (leafTys.size() != fields[0].size())
          unimplemented("pred: a merge of a composite with a packed integer leaf (cq-0umd: its field widths are not "
                        "recorded)", &p);
        SmallVector<Operand, 4> out;
        for (unsigned k = 0; k < fields[0].size(); ++k) {
          bool same = true;
          for (auto &f : fields) {
            if (f.size() != fields[0].size())
              internalError("loops-classical: incomings of one composite phi with different field counts", &p);
            same &= f[k].v == fields[0][k].v;
          }
          if (same) {
            out.push_back(fields[0][k]);
            continue;
          }
          std::vector<std::pair<Pred, Operand>> fa;
          for (size_t a = 0; a < arms.size(); ++a)
            fa.push_back({arms[a].first, fields[a][k]});
          Type *lt = leafTys[k];
          out.push_back(Operand{selectChain(ctx, fa, lt->isPointerTy() ? RailType{Kind::Int, 64} : railOf(lt)), true});
        }
        edgeFieldsM[{&p, u}] = out;
        continue;
      }
      Value *h = arms.size() == 1 ? asHandle(arms[0].second, p.getType())
                                  : selectChain(ctx, arms, railOf(p.getType()));
      edgeVal[{&p, u}] = h;
    }
  };

  // Rule 7 (176): a classical incoming of a phi of handles at a classical join of the body (the value on
  // the edge u -> s, e.g. -O1's zero-trip skip of an inner accumulator loop) is a seed rail minted at the
  // end of u's output block, in u's segment, before u's branch: its item (a direct release) follows the
  // merge's readers, and u's segment runs on every path through s's edge from u.
  // A sub-loop's exit edge enters a block of its parent (an exit phi with a classical incoming): the seed is
  // minted here, in the sub-loop's segment, and read by the parent's join.
  auto mintEdgeSeeds = [&](BasicBlock *u, BasicBlock *s) {
    if (s == header || !top.contains(s) || subOf(s))
      return;
    for (Loop *x : top.getLoopsInPreorder())
      if (x->getHeader() == s)
        return;   // a loop header's phis are its carried values (lowerLoop)
    if (L.contains(s) && edgeKind(u, s) == EK::Real) {
      bool lin = false;
      for (const BasicBlock *p : fwdPreds(s))
        lin |= edgeKind(p, s) != EK::Real;
      // A K-unit's flow that went through its tail (kInto) has no edge of its own here: its value comes in the same way.
      for (const BasicBlock *p : fwdPreds(s))
        if (Loop *k = kTail.lookup(p); k && exits::unitOf(*k).cont == s && !kReal(k))
          lin = true;
      if (lin)
        mixedEdge(u, s);
    }
    for (PHINode &p : s->phis()) {
      if (!isQ(&p) || edgeSeed.count({&p, u}) || edgeVal.count({&p, u}) || (kBound.count(&p) && kunit(u)))
        continue;   // (a phi a K-unit bound takes the unit's value on its edges)
      Value *v = p.getIncomingValueForBlock(u);
      Operand o = ctx.operand(v);
      if (o.handle)
        continue;
      if (!(p.getType()->isIntegerTy() || p.getType()->isFloatingPointTy()))
        continue;   // emitPhis refuses the phi itself
      edgeSeed[{&p, u}] = seed(o.v, railOf(p.getType()));
    }
  };

  auto noteStop = [&](Value *f) {
    if (!f || !stopCur)
      return;
    Value *n = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
    gate(abi::Core::XorI1, {stopCur, n});
    gate(abi::Core::XorI1, {f, n});
    stopCur = n;
  };
  // One evaluation of the exit arm: the flags of the edges it enters by (a quantum exit edge's e in a trip, the trip
  // predicate on a classical exit), of its blocks and of their edges.
  struct ArmEval {
    DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, Value *> entry;
    DenseMap<const BasicBlock *, Value *> flag;
    DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, Value *> edge;
    DenseMap<const BasicBlock *, Value *> creach;   // the classical path to a reached arm block, as a classical i1
    DenseSet<const PHINode *> bound;                // phis a loop of the arm bound
    Value *plain = nullptr;                         // case 1: the |1> rail that marks a reached edge, no predicate of its own
  };
  // The flag of the edge u -> x in this evaluation (nullptr: not taken in it): an entry edge's, a loop of the arm's
  // edge into its continuation (it always ends there) its header's flag, or, from an arm block u, u's flag & the
  // edge's own condition when u branches (rule 8 inside the arm: a quantum or classical condition, a classical term
  // seeded), once per edge.
  auto flagOfEdge = [&](ArmEval &ev, const BasicBlock *u, const BasicBlock *x) -> Value * {
    if (L.contains(u)) {
      auto it = ev.entry.find({u, x});
      return it == ev.entry.end() ? nullptr : it->second;
    }
    if (Loop *S = armUnit.lookup(u)) {
      if (armUnit.lookup(x) == S)
        return nullptr;
      return exits::unitOf(*S).cont == x ? ev.flag.lookup(S->getHeader()) : nullptr;
    }
    Value *fu = ev.flag.lookup(u);
    if (!fu || u->getSingleSuccessor())
      return fu;
    if (Value *e = ev.edge.lookup({u, x}))
      return e;
    Pred ep = exits::tripEdge(u, x);
    if (ep.isBottom())
      return nullptr;
    Value *g = ctx.preds().flag(ctx, ep);
    Value *e = fu;
    if (g && fu == ev.plain) {
      e = g;
    } else if (g) {
      e = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
      gate(abi::Core::AndI1, {fu, g, e});
    }
    ev.edge[{u, x}] = e;
    return e;
  };
  // The classical path of u -> x in this evaluation, as a classical i1 (a quantum condition counts as true): a
  // classical phi's incoming edge is chosen by classical conditions alone (taint).
  auto creachEdge = [&](ArmEval &ev, const BasicBlock *u, const BasicBlock *x) -> Value * {
    LLVMContext &Cx = ctx.M.getContext();
    if (L.contains(u))
      return ConstantInt::getTrue(Cx);
    if (Loop *S = armUnit.lookup(u))
      return ev.creach.lookup(S->getHeader());
    return ctx.B().CreateAnd(ev.creach.lookup(u), exits::classicalEdge(ctx, u, x));
  };
  auto rebindPhi = [&](PHINode &P, Operand o) {
    if (ctx.bound(&P))
      ctx.rebind(&P, {o});
    else
      ctx.bindFields(&P, {o});
  };
  // Rule 9: a phi of a reached arm block, entered by the edges ins of this evaluation: its incoming on the edge taken.
  auto bindArmPhi = [&](ArmEval &ev, PHINode &P, BasicBlock *b, ArrayRef<unsigned> ins) {
    const bool q = isQ(&P);
    if (P.getType()->isAggregateType() || P.getType()->isVectorTy()) {
      noteUnbuilt("loops-classical: a composite phi of a case-3 loop's exit arm", &P);
      return;
    }
    auto opOf = [&](unsigned i) {
      Operand o = ctx.operand(P.getIncomingValue(i));
      if (P.getType()->isPointerTy() && !o.handle && q)
        o = Operand{ctx.B().CreatePtrToInt(o.v, Type::getInt64Ty(ctx.M.getContext())), false};
      return o;
    };
    if (ins.size() == 1 ||
        all_of(ins, [&](unsigned i) { return P.getIncomingValue(i) == P.getIncomingValue(ins[0]); })) {
      Operand o = opOf(ins[0]);
      rebindPhi(P, q ? Operand{asHandle(o, P.getType()), true} : o);
      return;
    }
    if (!q) {
      // Rule 9: a classical choice is a classical select over the edges' classical paths.
      Operand o = opOf(ins.back());
      if (o.handle)
        internalError("loops-classical: a classical phi of an exit arm with a rail incoming", &P);
      Value *r = o.v;
      for (unsigned k = unsigned(ins.size()) - 1; k-- > 0;) {
        Operand ok = opOf(ins[k]);
        if (ok.handle)
          internalError("loops-classical: a classical phi of an exit arm with a rail incoming", &P);
        r = ctx.B().CreateSelect(creachEdge(ev, P.getIncomingBlock(ins[k]), b), ok.v, r);
      }
      rebindPhi(P, Operand{r, false});
      return;
    }
    // A quantum phi (rule 9): its incoming on the edge taken, a select chain over the edges' flags.
    RailType w = railOf(P.getType());
    Value *acc = nullptr;
    for (unsigned k = unsigned(ins.size()); k-- > 0;) {
      unsigned i = ins[k];
      Operand o = opOf(i);
      if (!acc) {
        acc = asHandle(o, P.getType());
        continue;
      }
      acc = select(flagOfEdge(ev, P.getIncomingBlock(i), b), o, Operand{acc, true}, w);
    }
    rebindPhi(P, Operand{acc, true});
  };
  // The exit arm under one evaluation's entry flags: every block some entered edge reaches, in the arm's topological
  // order, its phis rule 9's selects over the edges taken, its instructions under its flag, a loop of the arm one node
  // (rule 14 nested in this evaluation: its chain seeded by the block's flag). A block no entered edge reaches is no
  // part of this evaluation.
  auto walkArm = [&](ArmEval &ev, const SmallVectorImpl<BasicBlock *> &armBlocks) {
    LLVMContext &Cx = ctx.M.getContext();
    // The lowering branched inside the arm (a loop of the arm, rule 5's Readers test): the segment goes on where it joined.
    auto followBuilder = [&]() {
      if (BasicBlock *now = ctx.B().GetInsertBlock(); now != cur) {
        segIdx[now] = segs.size() - 1;
        segs.back().bb = now;
        cur = now;
      }
    };
    for (BasicBlock *b : armBlocks) {
      Loop *S = armUnit.lookup(b);
      if (S && S->getHeader() != b)
        continue;   // lowered with its loop
      SmallVector<Value *, 2> in;
      Value *cr = ConstantInt::getFalse(Cx);
      for (BasicBlock *p : predecessors(b)) {
        if (S && S->contains(p))
          continue;   // the back edge of the arm's loop
        if (Value *f = flagOfEdge(ev, p, b)) {
          if (!is_contained(in, f))
            in.push_back(f);
          cr = ctx.B().CreateOr(cr, creachEdge(ev, p, b));
        }
      }
      if (in.empty())
        continue;
      Value *f = in.front();
      if (in.size() > 1) {
        // Disjoint edges (one evaluation leaves through one): their OR is their XOR.
        f = seed(ConstantInt::getFalse(Cx), RailType{Kind::Int, 1});
        for (Value *x : in)
          gate(abi::Core::XorI1, {x, f});
      }
      ev.flag[b] = f;
      ev.creach[b] = cr;
      if (S) {
        spine::Shared &sh = spine::shared(ctx);
        exits::Unit SU = exits::unitOf(*S);
        SmallVector<PHINode *, 4> contPhis;
        if (SU.cont)
          for (PHINode &P : SU.cont->phis())
            if (any_of(P.blocks(), [&](const BasicBlock *u) { return armUnit.lookup(u) == S; })) {
              sh.binds.erase(&P);
              contPhis.push_back(&P);
            }
        Value *sf = f;
        if (f == ev.plain)
          if (Pred hp = qp(b); !hp.isTop())
            sf = ctx.preds().flag(ctx, hp);
        if (classify(*S, ctx.T, ctx.S) == Case::QuantumExit) {
          noteStop(exits::lowerNestedCutoff(ctx, *S, sf, segHook(), nullptr, this));
          followBuilder();
        } else {
          // cq (GMP hgcd2_jacobi): S entered from several arm blocks with different starts (fix-irreducible's guard): a
          // header phi's start is their merge (rule 9), over this evaluation's edges, bound here for S's unit (startOf).
          for (PHINode &P : b->phis()) {
            sh.binds.erase(&P);
            SmallVector<unsigned, 4> outside, ins;
            for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
              if (!S->contains(P.getIncomingBlock(i)))
                outside.push_back(i);
            if (all_of(outside, [&](unsigned i) { return P.getIncomingValue(i) == P.getIncomingValue(outside[0]); }))
              continue;
            for (unsigned i : outside)
              if (flagOfEdge(ev, P.getIncomingBlock(i), b))
                ins.push_back(i);
            bindArmPhi(ev, P, b, ins);
          }
          noteStop(exits::lowerClassicalInTrip(ctx, *S, sf, /*startsBound=*/true));
          followBuilder();
        }
        for (PHINode *P : contPhis)
          if (ctx.bound(P))
            ev.bound.insert(P);
        continue;
      }
      for (PHINode &P : b->phis()) {
        if (ev.bound.count(&P))
          continue;
        SmallVector<unsigned, 4> ins;
        for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
          if (flagOfEdge(ev, P.getIncomingBlock(i), b))
            ins.push_back(i);
        if (ins.empty())
          internalError("loops-classical: a phi of a reached exit arm block with no incoming in this evaluation", &P);
        bindArmPhi(ev, P, b, ins);
      }
      // The arm's flag is the block's whole predicate here: its instructions run under it, its effects controlled by it.
      const Pred bq = qp(b);
      for (Instruction &I : *b)
        if (!isa<PHINode>(I) && !I.isTerminator()) {
          if (f == ev.plain)
            lowerInstruction(ctx, I, nullptr);   // no predicate but the block's own (case 1)
          else
            lowerInstruction(ctx, I, f, &bq);
          followBuilder();
        }
    }
  };
  // A value cp takes on the unit edge u -> C: the incoming, or the phi itself where a loop of the arm bound it.
  auto contFields = [&](ArmEval &ev, CPhi &cp, const Value *val) {
    return fieldsOf(cp, cp.P && ev.bound.count(cp.P) ? static_cast<const Value *>(cp.P) : val);
  };
  // Multi-exit, at the latch: the exit arm, the captures, res, and the trip predicate's back edge.
  auto latchExits = [&]() {
    ArmEval ev;
    for (auto &[e, f] : exitFlag)
      ev.entry[e] = f;
    walkArm(ev, UX.arm);
    for (CPhi &cp : cphis) {
      SmallVector<Value *, 2> c(cp.run.begin(), cp.run.end());
      SmallVector<Operand, 2> vl;
      for (auto &[u, val] : cp.incomings(inUnit, UX.cont)) {
        if (u == cxb && mixedDs.empty()) {
          if (u == latch)
            vl = fieldsOf(cp, val);
          continue;   // the classical exit: res (at the header, headerRes)
        }
        Value *g = flagOfEdge(ev, u, UX.cont);
        if (!g)
          continue;   // an edge of the arm this trip's exits do not reach (the classical exit's)
        SmallVector<Operand, 2> fv = contFields(ev, cp, val);
        for (unsigned f = 0; f < c.size(); ++f)
          c[f] = select(g, fv[f], Operand{c[f], true}, cp.rails[f]);
      }
      for (unsigned f = 0; f < c.size(); ++f)
        cp.cap[f]->addIncoming(c[f], cur);
      if (cxArm && cxb == latch)
        cp.atCx.assign(c.begin(), c.end());
      else if ((cxb != header && !midCxb) || cxb == latch) {
        cp.res.clear();
        for (unsigned f = 0; f < c.size(); ++f)
          cp.res.push_back(!vl.empty() ? select(aCur, vl[f], Operand{c[f], true}, cp.rails[f]) : c[f]);
      }
    }
    aPhi->addIncoming(aCur, cur);
  };
  // Multi-exit with the classical bound tested at the header (cxb): its exit edge is taken before any
  // quantum exit of the trip, so res = select(a, v, cap) over the captures of the earlier trips.
  auto headerRes = [&]() {
    for (CPhi &cp : cphis) {
      if (cxArm) {
        cp.atCx.assign(cp.cap.begin(), cp.cap.end());
        continue;
      }
      const Value *val = nullptr;
      for (auto &[u, v] : cp.incomings(inUnit, UX.cont))
        if (u == header)
          val = v;
      if (!val)
        internalError("loops-classical: a case-3 loop's classical exit edge with no value for its continuation",
                      cp.orig());
      SmallVector<Operand, 2> fv = fieldsOf(cp, val);
      cp.res.clear();
      for (unsigned f = 0; f < cp.cap.size(); ++f)
        cp.res.push_back(select(aCur, fv[f], Operand{cp.cap[f], true}, cp.rails[f]));
    }
  };

  // The noreturn arm on the edge u -> x under its flag e: rule 16's abort arm, here in the trip.
  auto noreturnArm = [&](BasicBlock *u, BasicBlock *x, Value *e) {
    ArmEval ev;
    ev.entry[{u, x}] = e;
    walkArm(ev, UX.abort);
    noteStop(e);
  };
  auto followInsert = [&]() {
    if (BasicBlock *now = ctx.B().GetInsertBlock(); now != cur) {
      segIdx[now] = segs.size() - 1;
      segs.back().bb = now;
      cur = now;
    }
  };
  // Rule 16 on a classical test with an edge into a noreturn arm, in the trip. Under a quantum predicate (the trip's chain,
  // an enclosing trip, the block's own): e = trip & the edge's flag, its classical terms seeded (rule 8). With none: the
  // real branch to the arm, the ordinary call (cq-o75xb); the segment goes on where it rejoins.
  auto abortTest = [&](BasicBlock *u) {
    SmallVector<BasicBlock *, 2> xs;
    for (BasicBlock *x : successors(u))
      if (is_contained(UX.abort, x) && !is_contained(xs, x))
        xs.push_back(x);
    LLVMContext &Cx = ctx.M.getContext();
    Value *trip = aCur ? aCur : outerTrip;
    const bool noExit = cx && UX.live.empty();   // nothing else ends the classical loop: this edge leaves it as well
    for (BasicBlock *x : xs) {
      Value *cnd = exits::classicalEdge(ctx, u, x);
      Pred qu = qp(u);
      BasicBlock *N = nullptr;
      if (trip || !qu.isTop()) {
        Value *f = ctx.preds().flag(ctx, qu & exits::tripEdge(u, x));
        if (!f)
          internalError("loops-classical: a noreturn arm's classical test with no flag", u->getTerminator());
        Value *e = seed(ConstantInt::getFalse(Cx), RailType{Kind::Int, 1});
        if (trip)
          gate(abi::Core::AndI1, {trip, f, e});
        else
          gate(abi::Core::XorI1, {f, e});
        noreturnArm(u, x, e);
        followInsert();
        if (!noExit)
          continue;
        N = newBlock();
        ctx.B().CreateCondBr(cnd, unitExit, N);
        edgeFrom[{u, x}] = cur;
      } else {
        BasicBlock *Y = newBlock();
        N = newBlock();
        ctx.B().CreateCondBr(cnd, Y, N);
        ctx.B().SetInsertPoint(Y);
        followInsert();
        std::optional<Pred> wasAssumed = ctx.preds().assume(ctx.preds().edge(u, x), ctx.T, ctx.S);
        ArmEval ev;
        ev.plain = ConstantInt::getTrue(Cx);
        ev.entry[{u, x}] = ev.plain;
        walkArm(ev, UX.abort);
        ctx.preds().assume(wasAssumed, ctx.T, ctx.S);
        if (noExit) {
          ctx.B().CreateBr(unitExit);
          edgeFrom[{u, x}] = ctx.B().GetInsertBlock();
        } else {
          ctx.B().CreateBr(N);
        }
      }
      ctx.B().SetInsertPoint(N);
      followInsert();
    }
  };

  Value *aAtCx = nullptr;   // the trip predicate at cxb's classical exit test
  // cq-2xl5: a classical exit test besides the bound (cxExtra), at its branch: the trip leaves through it under the trip
  // predicate there, so its res is select(a, v_u, cap'), cap' the captures with this trip's quantum exits so far (those
  // whose test dominates u) taken in, as latchExits takes them all.
  struct ExtraExit {
    BasicBlock *u;
    std::vector<SmallVector<Value *, 2>> res;   // per cphi
  };
  std::vector<ExtraExit> extraExits;
  auto extraRes = [&](BasicBlock *u) {
    ArmEval ev;
    // The quantum exits this trip has tested before u: a test that reaches u in the trip (a linearized quantum arm's runs in
    // the open flow; one in a classical arm of its own took its edge in run already, and left exitFlag).
    DenseSet<const BasicBlock *> before;
    {
      SmallVector<const BasicBlock *, 8> work{u};
      while (!work.empty())
        for (const BasicBlock *p : predecessors(work.pop_back_val()))
          if (L.contains(p) && p != latch && before.insert(p).second)
            work.push_back(p);
    }
    for (auto &[e, f] : exitFlag)
      if (mxDT->dominates(e.first, u) || before.count(e.first))
        ev.entry[e] = f;
    walkArm(ev, UX.arm);
    ExtraExit xx{u, {}};
    for (CPhi &cp : cphis) {
      SmallVector<Value *, 2> c(cp.run.begin(), cp.run.end());
      SmallVector<Operand, 2> vl;
      for (auto &[w, val] : cp.incomings(inUnit, UX.cont)) {
        if (w == u) {
          vl = fieldsOf(cp, val);
          continue;
        }
        Value *g = flagOfEdge(ev, w, UX.cont);
        if (!g)
          continue;
        SmallVector<Operand, 2> fv = contFields(ev, cp, val);
        for (unsigned f = 0; f < c.size(); ++f)
          c[f] = select(g, fv[f], Operand{c[f], true}, cp.rails[f]);
      }
      SmallVector<Value *, 2> r;
      for (unsigned f = 0; f < c.size(); ++f)
        r.push_back(!vl.empty() ? select(aCur, vl[f], Operand{c[f], true}, cp.rails[f]) : c[f]);
      xx.res.push_back(std::move(r));
    }
    extraExits.push_back(std::move(xx));
  };
  auto emitTerminator = [&](BasicBlock *u) {
    tgtFrom = u;
    Instruction *t = u->getTerminator();
    if (isAbortTest(u))
      abortTest(u);
    if (mx && (is_contained(cxExtra, u) || (midCxb && u == cxb)))
      extraRes(u);
    const bool qExit = mx && termQ(t) && any_of(successors(u), [&](const BasicBlock *s) { return !L.contains(s); });
    if (u == latch && !qExit)
      latchNexts();
    if (mx && u == latch && !qExit)
      latchExits();
    if (mx && u == cxb && u == header && u != latch)
      headerRes();
    if (u == cxb)
      aAtCx = aCur;
    if (u == cxb && cxArm && u != header && u != latch) {
      noteUnbuilt("loops-classical: a case-3 loop whose only classical exit, into its exit or noreturn arm, is mid-trip", t);
      for (CPhi &cp : cphis)
        cp.atCx.assign(cp.cap.begin(), cp.cap.end());
    }
    if (qExit) {
      // A quantum exit before the latch: e = a & f, a' = a & NOT f; the trip goes on in the loop. A quantum
      // switch with exit cases (rule 13) is one such exit per exit block x: f_x the flag of its edge's quantum
      // predicate, e_x = a & f_x, a' = a ^ sum_x (a & f_x) (its edges are disjoint). An edge into an
      // effect-free dead end is UB to take: no exit.
      SmallVector<BasicBlock *, 4> xs;
      SmallVector<std::pair<BasicBlock *, Value *>, 2> intoArm;   // the noreturn arms' edges (rule 16) and their e
      for (BasicBlock *s : successors(u))
        if (!L.contains(s) && (is_contained(UX.live, s) || UX.contains(L, s)) && !is_contained(xs, s))
          xs.push_back(s);
      for (BasicBlock *s : successors(u))
        if (s == header && u != latch)
          internalError("loops-classical: a back edge from a block that is not the loop's latch", t);
      auto *br = dyn_cast<BranchInst>(t);
      Value *a2 = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
      gate(abi::Core::XorI1, {aCur, a2});
      // The exit condition read whole as the exit's atom (cq-s7c4): computed as data even where pred factored the
      // branch (a mixed test `c && q`, rule 8).
      if (br)
        if (auto *ci = dyn_cast<Instruction>(br->getCondition()); ci && !ctx.bound(ci))
          lowerConditionAsData(ctx, *ci);
      for (BasicBlock *x : xs) {
        Pred ex;
        if (br) {
          bool onTrue = br->getSuccessor(0) == x;
          ex = qp(u) & (onTrue ? Pred::atom(br->getCondition()) : !Pred::atom(br->getCondition()));
        } else if (auto *ib = dyn_cast<IndirectBrInst>(t)) {
          ex = qp(u) & computedGotoEdge(*ib, x);   // rule 13: the address cases into x
        } else {
          // Rule 13: the function-wide edge stands for the loop as a unit: with one live exit block its quantum part is
          // the loop's own (true outside any arm), no test of this trip. The trip's test is the cases into x.
          ex = ctx.preds().edge(u, x).quantumPart(ctx.T, ctx.S);
          if (!UX.abort.empty() || ex.isTop())
            ex = qp(u) & exits::tripEdge(u, x);
        }
        Value *f = ctx.preds().flag(ctx, ex);
        if (!f)
          internalError("loops-classical: a quantum exit condition with no flag", t);
        Value *e = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
        gate(abi::Core::AndI1, {aCur, f, e});
        gate(abi::Core::AndI1, {aCur, f, a2});
        if (is_contained(UX.abort, x))
          intoArm.push_back({x, e});
        else
          exitFlag[{u, x}] = e;
      }
      aCur = a2;
      if (br)
        lowerBranch(ctx, *br);
      else if (auto *sw = dyn_cast<SwitchInst>(t))
        sw::lowerSwitch(ctx, *sw);
      else if (!isa<IndirectBrInst>(t))   // rule 13: a quantum computed goto's edges are pred's; nothing to emit
        internalError("loops-classical: a quantum exit terminator other than br, switch or computed goto", t);
      for (auto &[x, e] : intoArm)
        noreturnArm(u, x, e);
      followInsert();
      // cq-11qhg (CR rule 14 case 3 with rules 8, 9): an exit test in a classical arm of the trip (its classical fact stronger
      // than the latch's) makes e where the latch's flow does not see it: the captures take its edge here, and the open flow
      // carries them to the classical join (run), as it carries the trip predicate.
      if (UX.cont && !(cfOf(ctx.preds().block(latch)) & !cfOf(ctx.preds().block(u))).isBottom())
        for (BasicBlock *x : xs) {
          auto ef = exitFlag.find({u, x});
          if (x != UX.cont || ef == exitFlag.end())
            continue;
          for (CPhi &cp : cphis)
            for (auto &[w, val] : cp.incomings(inUnit, UX.cont))
              if (w == u) {
                SmallVector<Operand, 2> fv = fieldsOf(cp, val);
                for (unsigned f = 0; f < cp.run.size(); ++f)
                  cp.run[f] = select(ef->second, fv[f], Operand{cp.run[f], true}, cp.rails[f]);
              }
          exitFlag.erase(ef);
        }
      // cq-h8y6: a mixed exit test (cxb with classical disjuncts) leaves the loop classically where one of them
      // holds: there its flag is 1, so this trip's exit took its value under a (the captures, or res).
      Value *cExit = nullptr;
      if (u == cxb)
        for (const Disj &d : mixedDs) {
          Operand o = ctx.operand(d.v);
          Value *x = d.pos ? o.v : ctx.B().CreateNot(o.v);
          cExit = cExit ? ctx.B().CreateOr(cExit, x) : x;
        }
      if (u == latch) {
        // The quantum exit at the latch (cq-nqa6): the next values and captures under a', then the back edge.
        latchNexts();
        latchExits();
        for (BasicBlock *s : successors(u))
          edgeFrom[{u, s}] = cur;
        if (cExit)
          ctx.B().CreateCondBr(cExit, T, H);
        else
          ctx.B().CreateBr(H);
        cur = nullptr;
        return;
      }
      for (BasicBlock *s : successors(u))
        edgeFrom[{u, s}] = cur;
      if (cExit) {
        BasicBlock *in = nullptr;
        for (BasicBlock *s : successors(u))
          if (L.contains(s))
            in = s;
        for (BasicBlock *s : successors(u))
          mintEdgeSeeds(u, s);
        ctx.B().CreateCondBr(cExit, cxArm ? target(cxArm) : T, target(in));
        cur = nullptr;
      } else if (BasicBlock *in = qExitNext(u); in && edgeKind(u, in) == EK::Real) {
        // The trip goes on into a classical join (the exit test sat in a classical arm of the trip): a real edge.
        mintEdgeSeeds(u, in);
        ctx.B().CreateBr(target(in));
        cur = nullptr;
      }
      return;
    }
    if (c3 && !mx && u == latch) {
      IRBuilder<> &B = ctx.B();
      Value *cExit = nullptr;
      for (const Disj &d : ds) {
        if (isQ(d.v))
          continue;
        Operand o = ctx.operand(d.v);
        if (o.handle)
          internalError("loops-classical: a classical exit disjunct that is a rail", d.v);
        Value *x = d.pos ? o.v : B.CreateNot(o.v);
        cExit = cExit ? B.CreateOr(cExit, x) : x;
      }
      Value *q = nQ == 1 ? ctx.rail(qLeaf) : ctx.preds().flag(ctx, qExitP);
      if (!q)
        internalError("loops-classical: a case-3 exit test's quantum disjunction with no flag", latch->getTerminator());
      const bool qExit = nQ == 1 ? qPos : true;
      Value *a = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
      // a = a_prev & q, or a_prev & NOT q = a_prev ^ (a_prev & q): gates on a alone, so the mirror's
      // undo of a reads q in the state the forward read it (no bracket on q).
      if (qExit)
        gate(abi::Core::XorI1, {aPhi, a});
      gate(abi::Core::AndI1, {aPhi, q, a});
      aPhi->addIncoming(a, cur);
      B.CreateCondBr(cExit, T, H);
      edgeFrom[{u, exitB}] = cur;
      edgeFrom[{u, header}] = cur;
      cur = nullptr;
      return;
    }
    if (auto *br = dyn_cast<BranchInst>(t)) {
      if (BasicBlock *next = abortTestNext(u); next || !br->isConditional()) {
        BasicBlock *s = next ? next : br->getSuccessor(0);
        EK k = (s == header || !L.contains(s)) ? EK::Real : edgeKind(u, s);
        edgeFrom[{u, s}] = cur;
        if (k != EK::Real)
          return;
        mintEdgeSeeds(u, s);
        ctx.B().CreateBr(target(s));
        cur = nullptr;
        return;
      }
      if (termQ(t)) {
        // A quantum edge out of the trip is a case-3 exit (the latch test, or the multi-exit form's qExit
        // above): here only an edge into an effect-free dead end can leave, UB to take (no exit).
        for (BasicBlock *s : successors(u))
          if (s == header || (!L.contains(s) && (is_contained(UX.live, s) || UX.contains(L, s))))
            internalError("loops-classical: a quantum edge out of the trip outside the case-3 exit forms", t);
        lowerBranch(ctx, *br);
        for (BasicBlock *s : successors(u))
          edgeFrom[{u, s}] = cur;
        return;
      }
      Operand cnd = ctx.operand(br->getCondition());
      if (cnd.handle)
        internalError("loops-classical: a classical branch on a rail", t);
      for (BasicBlock *s : successors(u))
        mintEdgeSeeds(u, s);
      ctx.B().CreateCondBr(cnd.v, target(br->getSuccessor(0)), target(br->getSuccessor(1)));
      for (BasicBlock *s : successors(u))
        edgeFrom[{u, s}] = cur;
      cur = nullptr;
      return;
    }
    if (auto *sw = dyn_cast<SwitchInst>(t)) {
      if (termQ(t)) {
        for (BasicBlock *s : successors(u))
          if (s == header || (!L.contains(s) && (is_contained(UX.live, s) || UX.contains(L, s))))
            internalError("loops-classical: a quantum switch edge out of the trip outside the case-3 exit forms", t);
        sw::lowerSwitch(ctx, *sw);
        for (BasicBlock *s : successors(u))
          edgeFrom[{u, s}] = cur;
        return;
      }
      Operand cnd = ctx.operand(sw->getCondition());
      if (cnd.handle)
        internalError("loops-classical: a classical switch on a rail", t);
      for (BasicBlock *s : successors(u))
        mintEdgeSeeds(u, s);
      SwitchInst *ns = ctx.B().CreateSwitch(cnd.v, target(sw->getDefaultDest()), sw->getNumCases());
      for (auto &cs : sw->cases())
        ns->addCase(cs.getCaseValue(), target(cs.getCaseSuccessor()));
      for (BasicBlock *s : successors(u))
        edgeFrom[{u, s}] = cur;
      cur = nullptr;
      return;
    }
    if (auto *ib = dyn_cast<IndirectBrInst>(t)) {
      // CR rule 13 (b137e75): a computed goto is a switch on its address. A quantum one emits nothing (its
      // edges are pred's address cases); a classical one is the switch on the address's position among its
      // destinations.
      if (termQ(t)) {
        for (BasicBlock *s : successors(u))
          if (s == header || (!L.contains(s) && (is_contained(UX.live, s) || UX.contains(L, s))))
            internalError("loops-classical: a quantum computed goto edge out of the trip outside the case-3 exit forms",
                          t);
        for (BasicBlock *s : successors(u))
          edgeFrom[{u, s}] = cur;
        return;
      }
      Operand a = ctx.operand(ib->getAddress());
      if (a.handle)
        internalError("loops-classical: a classical computed goto on a rail", t);
      for (BasicBlock *s : successors(u))
        mintEdgeSeeds(u, s);
      SmallVector<BasicBlock *, 4> ds = computedGotoDestinations(*ib);
      Value *pos = computedGotoPosition(ctx.B(), a.v, *ib);
      SwitchInst *ns = ctx.B().CreateSwitch(pos, target(ds.back()), ds.size() - 1);
      for (unsigned k = 0; k + 1 < ds.size(); ++k)
        ns->addCase(ctx.B().getInt32(k), target(ds[k]));
      for (BasicBlock *s : successors(u))
        edgeFrom[{u, s}] = cur;
      cur = nullptr;
      return;
    }
    // An invoke is a call first: the spine's dispatch lowers it (its own construction, CR rule 18).
    if (isa<InvokeInst>(t)) {
      lowerInstruction(ctx, *t, aPhi);
      internalError("loops-classical: the spine's dispatch returned from an invoke", t);
    }
    // ret and unreachable end no block of a loop (no successor); callbr is inline asm (rule 27); the EH pads
    // come from no C translation unit.
    if (isa<CallBrInst>(t))
      unimplemented("loops-classical: asm goto (callbr) in a loop: inline asm (rule 27) waits for its CQ_spec example "
                    "(build step 3)",
                    t);
    internalError("loops-classical: a loop body terminator other than br, switch or computed goto", t);
  };

  auto emitInstructions = [&](BasicBlock *b) {
    for (Instruction &I : *b) {
      if (isa<PHINode>(I) || I.isTerminator() || skip.count(&I))
        continue;
      // case 3: the body runs under a_{j-1}; case 1: under the enclosing case-3 trip's rail, if any
      lowerInstruction(ctx, I, aPhi ? aPhi : outerTrip);
      // Rule 5 Readers: the lowering branched on a classical test inside the trip; the segment goes on where it joined.
      if (BasicBlock *now = ctx.B().GetInsertBlock(); cur && now != cur) {
        segIdx[now] = segs.size() - 1;
        segs.back().bb = now;
        cur = now;
      }
    }
  };

  // The trip predicate and the stop rail at the end of each walked block.
  DenseMap<const BasicBlock *, Value *> aOut, stopOut;
  auto joinTrip = [&](BasicBlock *b, DenseMap<const BasicBlock *, Value *> &outOf, Value *&var, Value *fallback) {
    SmallVector<std::pair<BasicBlock *, Value *>, 4> in;
    bool differ = false;
    for (const BasicBlock *p : fwdPreds(b)) {
      if (rejoinFact.count({p, b}))
        continue;   // its flow went on from the rejoin (cq-vs1eo)
      Value *v = outOf.lookup(p);
      if (!v)
        v = fallback;   // the exit of a sub-loop, whose walk had no entry here
      auto ef = edgeFrom.find({p, b});
      if (ef == edgeFrom.end())
        continue;
      differ |= !in.empty() && in.front().second != v;
      in.push_back({ef->second, v});
    }
    if (!in.empty())
      var = in.front().second;
    if (!differ)
      return;
    PHINode *ph = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), unsigned(in.size()));
    for (BasicBlock *pb : predecessors(ob(b)))
      for (auto &[from, v] : in)
        if (from == pb) {
          ph->addIncoming(v, pb);
          break;
        }
    ctx.unc().recordMerge(ph);
    var = ph;
  };
  // The header (its phis are the carried values above). The outermost header runs under the spine's
  // guard; a sub-loop's header fact is set by its parent's walk.
  if (outermost)
    curFact = cfOf(ctx.preds().block(header));
  requireFact(header);
  emitInstructions(header);
  emitTerminator(header);
  auto noteRun = [&](const BasicBlock *b) {
    for (CPhi &cp : cphis)
      for (unsigned f = 0; f < cp.run.size(); ++f)
        cp.runOut[f][b] = cp.run[f];
  };
  aOut[header] = aCur;
  stopOut[header] = stopCur;
  noteRun(header);
  // The walk order (rule 8 inside a trip). A block entered by classical edges only starts a segment of
  // its own and needs no open block; a block entered by linearized edges only continues the open block,
  // which must run exactly where the block's classical factor holds (a quantum arm's code runs on every
  // path its classical guard admits, no fewer: an arm block reached in RPO while a classical branch
  // nested in another arm is open waits for that branch's join). A block whose turn comes before its
  // place exists waits (pending) and is walked as soon as it can be, in RPO among the waiting ones.
  auto entryKinds = [&](BasicBlock *b) {
    bool anyReal = false, anyLin = false;
    for (const BasicBlock *p : fwdPreds(b))
      (edgeKind(p, b) == EK::Real ? anyReal : anyLin) = true;
    return std::make_pair(anyReal, anyLin);
  };
  std::vector<BasicBlock *> pending;
  DenseSet<const BasicBlock *> pendSet;
  DenseSet<const Loop *> walkedUnits;
  // The unit's trips left their own bindings on its tail's values: on the outside paths they are unlowered (a phi another unit
  // bound keeps that unit's value, restored by the caller of the snapshot).
  auto tailBindsOf = [&](Loop *k) {
    std::vector<std::pair<const PHINode *, SmallVector<Operand, 4>>> keep;
    spine::Shared &sh = spine::shared(ctx);
    for (BasicBlock *tb : exits::unitOf(*k).tail)
      for (const PHINode &phi : tb->phis())
        if (auto bi = sh.binds.find(&phi); bi != sh.binds.end() && kBound.count(&phi))
          keep.push_back({&phi, SmallVector<Operand, 4>(bi->second.begin(), bi->second.end())});
    return keep;
  };
  auto clearTail = [&](Loop *k, const std::vector<std::pair<const PHINode *, SmallVector<Operand, 4>>> &keep) {
    spine::Shared &sh = spine::shared(ctx);
    walkedUnits.insert(k);
    for (BasicBlock *tb : exits::unitOf(*k).tail)
      for (Instruction &I : *tb)
        sh.binds.erase(&I);
    for (auto &[phi, fields] : keep)
      sh.binds[phi].assign(fields.begin(), fields.end());
  };
  // r7 (cq-vs1eo, rules 8, 9): a join entered by real edges and by linearized ones runs where its real edges enter it (its
  // output block). When a rejoined region's edge into it holds where no real edge enters (the region was rejoined before the
  // other quantum arm, whose own classical branch then leaves toward several joins), the join waits for a rejoin of the real
  // edges too (rejoin), after which it is walked in the open flow.
  auto linUncovered = [&](const BasicBlock *b) {
    Pred real = Pred::bottom(), lin = Pred::bottom();
    for (const BasicBlock *p : fwdPreds(b)) {
      if (edgeKind(p, b) == EK::Real) {
        // A sub-loop or K-unit is one node of the walk: its edge out is taken wherever it was walked.
        Loop *node = subOf(p) ? subOf(p) : kunit(p);
        const BasicBlock *at = node ? node->getHeader() : p;
        auto it = factOf.find(at);
        Pred fp = it == factOf.end() ? Pred::top() : it->second;
        real = real | (node ? fp : fp & cfOf(exits::tripEdge(p, b)));
      } else if (auto r = rejoinFact.find({p, b}); r != rejoinFact.end()) {
        lin = lin | r->second;   // a rejoined region's edge: its flow went on from the rejoin block
      }
    }
    return !(lin & !real).isBottom();
  };
  // A walked predecessor is walked with its sub-loop or K-unit, at that one's header (r7, SQLite isDate: a sub-loop's exit
  // hub waits for the sub-loop).
  auto pendingPred = [&](const BasicBlock *p) {
    if (Loop *sl = subOf(p))
      p = sl->getHeader();
    else if (Loop *k = kunit(p))
      p = k->getHeader();
    return pendSet.count(p) != 0;
  };
  auto mustWait = [&](BasicBlock *b) {
    if (Loop *t = kTail.lookup(b); t && (pendSet.count(t->getHeader()) || !walkedUnits.count(t)))
      return true;
    for (const BasicBlock *p : fwdPreds(b))
      if (p != b && pendingPred(p))
        return true;
    auto [anyReal, anyLin] = entryKinds(b);
    if (anyReal)
      return cur != nullptr || (anyLin && linUncovered(b));
    if (!cur)
      return true;
    // Where b runs: where one of its walked predecessors ran and the edge's classical factor held.
    Pred need = Pred::bottom();
    for (const BasicBlock *p : fwdPreds(b))
      need = need | edgeFact(p, b);
    return !(need & !curFact).isBottom();
  };
  auto visit = [&](BasicBlock *b) {
    Loop *sl = subOf(b);
    auto [anyReal, anyLin] = entryKinds(b);
    if (anyReal) {
      if (cur)
        internalError("loops-classical: a classical join walked while a block is open", &*b->begin());
      startSeg(ob(b));
      Pred f = Pred::bottom();
      for (const BasicBlock *p : fwdPreds(b))
        f = f | edgeFact(p, b);
      curFact = f;
      // The trip predicate and the stop rail at a classical join: an exit taken in one classical arm of the trip is in that
      // arm's only.
      if (aPhi)
        joinTrip(b, aOut, aCur, aPhi);
      if (stopPhi)
        joinTrip(b, stopOut, stopCur, stopCur);
      for (CPhi &cp : cphis)
        for (unsigned f = 0; f < cp.run.size(); ++f)
          joinTrip(b, cp.runOut[f], cp.run[f], cp.run[f]);
    } else if (!cur) {
      internalError("loops-classical: a linearized block walked with no open block", &*b->begin());
    }
    // A tail block runs here for the paths from outside its unit only: every predicate under them.
    struct TailScope {
      LoweringContext &C;
      bool &in;
      std::optional<Pred> was;
      bool on, wasIn;
      ~TailScope() {
        if (on) {
          C.preds().assume(was, C.T, C.S);
          in = wasIn;
        }
      }
    } tailScope{ctx, inTail, std::nullopt, false, inTail};
    if (auto tp = kTailPred.find(b); tp != kTailPred.end()) {
      tailScope.was = ctx.preds().assume(tp->second, ctx.T, ctx.S);
      tailScope.on = true;
      inTail = true;
    }
    if (!sl)
      requireFact(b);
    if (sl) {
      // A sub-loop takes no exit of this loop: the captures leave its blocks as they enter them.
      for (const BasicBlock *x : sl->blocks())
        noteRun(x);
      for (auto &[x, k] : kOf)
        if (k == sl)
          noteRun(x);
      Case sc = classify(*sl, ctx.T, ctx.S);
      if (sc == Case::QuantumExit) {
        // CR rule 14, nested K-loops: the chain's seed is this trip's predicate (case 3: a_{j-1}; a case-1
        // trip inside a case-3 trip: that trip's rail) & the sub-loop header's quantum predicate within the
        // trip, a fresh rail (gates on fresh rails only); |1> when both are true. Its a_K is kept once per
        // trip of this loop (B > K or no bound), every other rail is a record of the segment it is made in (this
        // one, or one its classical branches open), mirrored by the reverse loop per trip.
        exits::Unit SU = exits::unitOf(*sl);
        BasicBlock *C = SU.cont;
        if (!C || !L.contains(C))
          unimplemented("loops-classical: a sub-loop that leaves its parent loop", sl->getHeader()->getTerminator());
        Value *trip = c3 ? static_cast<Value *>(aPhi) : outerTrip;
        Pred hp = qp(b);
        Value *f = hp.isTop() ? nullptr : ctx.preds().flag(ctx, hp);
        Value *sd;
        if (trip && f) {
          sd = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
          gate(abi::Core::AndI1, {trip, f, sd});
        } else if (trip || f) {
          sd = trip ? trip : f;
        } else {
          sd = seed(ConstantInt::getTrue(ctx.M.getContext()), RailType{Kind::Int, 1});
        }
        DenseSet<const PHINode *> was;
        for (PHINode &P : C->phis())
          if (ctx.bound(&P))
            was.insert(&P);
        auto keepTail = tailBindsOf(sl);
        // cq-kk46l: its classical branches are segments of this walk (segHook); the walk goes on where the last joined.
        // Owner ruling Q10 (CR rule 14, rule 8): the classical conjunct of the edge into the sub-loop (its pre-header
        // guard, `(m & 1) && y > 2`, is trip 0's test) that this walk has not established is a classical branch before
        // trip 0, not dropped from the seed.
        Value *t0 = nullptr;
        if (Pred cf = cfOf(ctx.preds().block(b)); !(curFact & !cf).isBottom())
          t0 = classicalValue(ctx, cf);
        noteStop(exits::lowerNestedCutoff(ctx, *sl, sd, segHook(), t0, this));
        clearTail(sl, keepTail);
        followInsert();
        for (PHINode &P : C->phis())
          if (!was.count(&P) && ctx.bound(&P))
            kBound.insert(&P);
        for (auto &[blk, k] : kOf)
          if (k == sl)
            factOf[blk] = curFact;
        const BasicBlock *rep = nullptr;
        for (const BasicBlock *p : predecessors(C))
          if (kunit(p) == sl) {
            edgeFrom[{p, C}] = cur;
            if (!rep)
              rep = p;
          }
        if (BasicBlock *tb = kInto(sl)) {
          // The open flow goes on through the tail: a tail phi's value on it is its linearized incomings (the quantum skip).
          for (PHINode &P : tb->phis()) {
            if (kBound.count(&P))
              continue;
            std::vector<std::pair<Pred, const Value *>> kept;
            for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
              const BasicBlock *u = P.getIncomingBlock(i);
              if (unitEdgeIntoTail(u, tb) || edgeKind(u, tb) == EK::Real || (edgeFact(u, tb) & curFact).isBottom())
                continue;
              Pred e = ctx.preds().edge(u, tb).quantumPart(ctx.T, ctx.S);
              const Value *v = P.getIncomingValue(i);
              auto same = find_if(kept, [&](const auto &k) { return k.second == v; });
              if (same != kept.end())
                same->first = same->first | e;
              else
                kept.push_back({e, v});
            }
            Value *fv;
            if (kept.size() == 1 && isQ(&P)) {
              fv = asHandle(ctx.operand(kept.front().second), P.getType());
            } else if (kept.size() == 1) {
              fv = ctx.operand(kept.front().second).v;
            } else if (kept.empty()) {
              fv = isQ(&P) ? seed(Constant::getNullValue(irTypeOf(ctx.M.getContext(), railOf(P.getType()))), railOf(P.getType()))
                           : static_cast<Value *>(Constant::getNullValue(P.getType()));
            } else {
              std::vector<std::pair<Pred, Operand>> arms;
              for (auto &[e, v] : kept)
                arms.push_back({e, ctx.operand(v)});
              fv = selectChain(ctx, arms, railOf(P.getType()));
            }
            kFlowVal[&P] = {cur, fv};
          }
          ctx.B().CreateBr(ob(tb));
          cur = nullptr;
          return;
        }
        if (!rep) {
          // Every edge of the unit into C leaves from its tail, whose walk continues this block.
          if (none_of(SU.tail, [&](const BasicBlock *t) { return kTail.lookup(t) == sl; }))
            internalError("loops-classical: a K-unit with no edge into its continuation", sl->getHeader()->getTerminator());
          if (kReal(sl))
            noteUnbuilt("loops-classical: a K-unit under a classical skip whose every edge into its continuation is its tail's",
                        sl->getHeader()->getTerminator());
          return;
        }
        kRep[sl] = rep;
        if (edgeKind(rep, C) == EK::Real) {
          // cq-a0x8d (gmp __gmpn_mu_bdiv_q): a phi of C the unit did not bind (a literal on its exit edge) takes the unit's real
          // edge like any real edge: a seed of the literal (rule 7), the select over the linearized incomings at a mixed join.
          mintEdgeSeeds(const_cast<BasicBlock *>(rep), C);
          ctx.B().CreateBr(ob(C));
          cur = nullptr;
        }
        return;
      }
      exits::Unit SU = exits::unitOf(*sl);
      BasicBlock *sx = SU.multi() ? SU.cont : exits::liveExit(*sl);
      if (!sx || !L.contains(sx))
        unimplemented("loops-classical: a sub-loop that leaves its parent loop", sl->getHeader()->getTerminator());
      if (!c3 && sc == Case::ClassicalBound && anyReal && sl->getExitingBlock() && SU.abort.empty() && tripLocal(*sl, L)) {
        // A trip-local sub-loop (176): its own unit, entered from the segment just opened at its header.
        BasicBlock *entry = cur;
        size_t nb = Out.size();
        auto sub = std::make_shared<Unit>(ctx, *sl);
        sub->nested = true;
        sub->resetAt = H;
        sub->run(sc);
        unsigned k = 0;
        for (BasicBlock &ob2 : Out)
          if (k++ >= nb)
            subBlocks.insert(&ob2);
        subBlocks.insert(sub->subBlocks.begin(), sub->subBlocks.end());
        BasicBlock *bk = ctx.B().GetInsertBlock();
        ctx.B().CreateBr(ob(sx));
        edgeFrom[{sl->getExitingBlock(), sx}] = bk;
        throughSub[bk] = entry;
        subs.push_back({sub, unsigned(segs.size() - 1), bk});
        cur = nullptr;
        return;
      }
      Value *savedTrip = outerTrip;
      if (c3)
        outerTrip = aPhi;   // the sub-loop's trips run inside this trip: under a_{j-1}
      DenseSet<const PHINode *> was;
      for (PHINode &P : sx->phis())
        if (ctx.bound(&P))
          was.insert(&P);
      auto keepTail = tailBindsOf(sl);
      // A case-1 sub-loop's continuation may lie outside this loop (cq-j5mq): its edges are real branches (target).
      auto subOut = lowerLoop(*sl, sc, sx && L.contains(sx) ? ob(sx) : nullptr, false);
      outerTrip = savedTrip;
      clearTail(sl, keepTail);
      for (size_t i = 0; i < subOut.size();) {
        const Value *v = subOut[i].first;
        SmallVector<Operand, 2> ops;
        for (; i < subOut.size() && subOut[i].first == v; ++i)
          ops.push_back(subOut[i].second);
        if (ctx.bound(v))
          ctx.rebind(v, ops);
        else
          ctx.bindFields(v, ops);   // a phi of the multi-exit sub-loop's continuation (its exit value)
      }
      if (sc == Case::ClassicalBoundQuantumExit && c3Multi(*sl)) {
        for (PHINode &P : sx->phis())
          if (!was.count(&P) && ctx.bound(&P))
            kBound.insert(&P);
        // Its real edge into sx: a classical exit test's branch (a quantum exit's edge is the flags of its test's block).
        for (const BasicBlock *p : predecessors(sx))
          if (auto ef = edgeFrom.find({p, sx}); kunit(p) == sl && ef != edgeFrom.end() && ef->second->getTerminator() &&
                                                is_contained(successors(ef->second), ob(sx)))
            kRep[sl] = p;
        if (!kRep.count(sl))
          internalError("loops-classical: a multi-exit sub-loop with no real edge into its continuation",
                        sl->getHeader()->getTerminator());
        for (auto &[blk, k] : kOf)
          if (k == sl && !factOf.count(blk))
            factOf[blk] = curFact;
      }
      return;
    }
    emitPhis(b, anyReal);
    emitInstructions(b);
    emitTerminator(b);
    aOut[b] = aCur;
    stopOut[b] = stopCur;
    noteRun(b);
  };
  auto drain = [&]() {
    for (unsigned k = 0; k < pending.size();) {
      BasicBlock *w = pending[k];
      if (!pendSet.count(w) || mustWait(w)) {
        ++k;
        continue;
      }
      pendSet.erase(w);
      visit(w);
      k = 0;
    }
  };
  // cq-a0x8d: the joins rejoin took real edges from; one left with no real edge is walked in the open flow only.
  SmallVector<const BasicBlock *, 2> rejoined;
  // cq-vs1eo (CR rule 14 with rules 8, 9): the walk waits with no open block for a linearized block w (the other quantum
  // arm) while a classical region nested in an earlier arm has left for a join s still to walk. Where the region's real
  // edges into s hold on every path w runs on, they end in a rejoin block R instead: R's phis join the region's values of
  // s's phis (rule 9: a classical join of the arm's values, a phi of handles), the open flow goes on from R under the
  // region's fact, and s takes those edges as linearized incomings carrying R's values (a mixed join, mixedEdge). The region
  // may be a sub-loop's exit edge (cq-a0x8d: a sub-loop always ends in a real branch).
  // cq-a0x8d (glpk glp_analyze_bound): with an open flow, the same rejoin joins the flow too, where the region's edges and
  // the flow's fact together cover where w runs (`if (c) { if (q) W; }  if (d) { if (q2) W; } else S;`: c's arm already
  // flowed into d's test). The flow ends in R as well, with a |0> seed for each phi of s (s's edge is not its path: rules 7, 9).
  // One region exit set: a pending join s, the walked blocks whose real edges into s the rejoin takes, and their facts.
  struct RegionJoin {
    BasicBlock *s;
    SmallVector<BasicBlock *, 4> rs;
    Pred f;
  };
  // The rejoin block R for the joins js: their region edges end in R, the open flow (if any) too; R's phis carry each join's
  // phi values on its edges (a |0> seed, or a classical 0, on every other edge into R: that edge is not the join's path).
  // single: one join, its fact the whole of R's (the flow's included); else each join's edges keep their own fact.
  auto buildRejoin = [&](ArrayRef<RegionJoin> js, Pred f, bool single) {
    BasicBlock *R = newBlock();
    // The block each region edge enters R from: its own output block (one join), or a block of its own per output edge
    // (several joins: one output block may leave for two of them, and each edge carries the |0>s of the other joins' phis).
    // Two region edges may leave from one output block for one join (linearized arms walked in one flow): one output edge.
    DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, BasicBlock *> via;
    SmallVector<BasicBlock *, 4> edgeBlocks;
    {
      DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, BasicBlock *> perOut;
      for (const RegionJoin &j : js)
        for (BasicBlock *p : j.rs) {
          BasicBlock *from = edgeFrom[{p, j.s}];
          BasicBlock *&T = perOut[{from, j.s}];
          if (!T) {
            T = single ? R : newBlock();
            from->getTerminator()->replaceSuccessorWith(ob(j.s), T);
            if (!single)
              edgeBlocks.push_back(T);
          }
          via[{p, j.s}] = single ? from : T;
        }
    }
    for (const RegionJoin &j : js)
      rejoined.push_back(j.s);
    // The open flow's trip predicate, stop rail and captures, and its |0> seed per phi of the joins.
    BasicBlock *flow = cur ? ctx.B().GetInsertBlock() : nullptr;
    SmallVector<Value *, 8> flowAt;
    auto zeroOf = [&](PHINode &P) -> Value * {
      return isQ(&P) ? seed(Constant::getNullValue(irTypeOf(ctx.M.getContext(), railOf(P.getType()))), railOf(P.getType()))
                     : static_cast<Value *>(Constant::getNullValue(P.getType()));
    };
    DenseMap<const PHINode *, Value *> flowSeed;
    if (flow) {
      flowAt.push_back(aCur);
      flowAt.push_back(stopCur);
      for (CPhi &cp : cphis)
        flowAt.append(cp.run.begin(), cp.run.end());
      for (const RegionJoin &j : js)
        for (PHINode &P : j.s->phis())
          if (!P.getType()->isAggregateType() && !P.getType()->isVectorTy())
            flowSeed[&P] = zeroOf(P);
      ctx.B().CreateBr(R);
      cur = nullptr;
    }
    // r7 (cq-vs1eo, several joins): each edge's block is a segment of its own, entered on that edge only, where the |0> of
    // every other join's phi is minted (that edge is not the other join's path: rules 7, 9).
    DenseMap<std::pair<const PHINode *, const BasicBlock *>, Value *> otherSeed;
    for (BasicBlock *T : edgeBlocks) {
      startSeg(T);
      const BasicBlock *mine = nullptr;
      for (const RegionJoin &j : js)
        for (BasicBlock *p : j.rs)
          if (via[{p, j.s}] == T)
            mine = j.s;
      for (const RegionJoin &j : js)
        if (j.s != mine)
          for (PHINode &P : j.s->phis())
            if (!P.getType()->isAggregateType() && !P.getType()->isVectorTy())
              otherSeed[{&P, T}] = zeroOf(P);
      ctx.B().CreateBr(R);
    }
    startSeg(R);
    curFact = f;
    for (const RegionJoin &j : js) {
      BasicBlock *s = j.s;
      for (PHINode &P : s->phis()) {
        const bool q = isQ(&P);
        if (P.getType()->isAggregateType() || P.getType()->isVectorTy()) {
          noteUnbuilt("loops-classical: a composite phi of a join a classical region nested in a quantum arm rejoins", &P);
          continue;
        }
        SmallVector<std::pair<BasicBlock *, Operand>, 4> in;
        if (flow)
          in.push_back({flow, Operand{flowSeed.lookup(&P), q}});
        for (BasicBlock *p : j.rs) {
          Operand o;
          if (auto e = edgeVal.find({&P, p}); e != edgeVal.end())
            o = Operand{e->second, true};
          else
            o = ctx.operand(P.getIncomingValueForBlock(p));
          if (q && !o.handle) {
            if (auto e = edgeSeed.find({&P, p}); e != edgeSeed.end())
              o = Operand{e->second, true};
            else
              internalError("loops-classical: a classical incoming of a phi of handles with no edge seed", &P);
          }
          in.push_back({via[{p, s}], o});
        }
        for (BasicBlock *T : edgeBlocks)
          if (Value *z = otherSeed.lookup({&P, T}))
            in.push_back({T, Operand{z, q}});
        Operand v = in.front().second;
        if (any_of(in, [&](const auto &x) { return x.second.v != v.v; })) {
          PHINode *np = ctx.B().CreatePHI(q ? handleTy(ctx.M.getContext()) : P.getType(), unsigned(in.size()));
          for (BasicBlock *pb : predecessors(R))
            for (auto &[from, o] : in)
              if (from == pb) {
                np->addIncoming(o.v, pb);
                break;
              }
          if (q)
            ctx.unc().recordMerge(np);
          v = Operand{np, q};
        }
        for (BasicBlock *p : j.rs)
          rejoinVal[{&P, p}] = v;
      }
      for (BasicBlock *p : j.rs)
        rejoinFact[{p, s}] = single ? f : j.f;
    }
    // The trip predicate and the stop rail at R: the region's, joined as at any classical join.
    SmallVector<std::pair<DenseMap<const BasicBlock *, Value *> *, Value **>, 4> vars{{&aOut, &aCur}, {&stopOut, &stopCur}};
    for (CPhi &cp : cphis)
      for (unsigned f = 0; f < cp.run.size(); ++f)
        vars.push_back({&cp.runOut[f], &cp.run[f]});
    for (unsigned vi = 0; vi < vars.size(); ++vi) {
      auto [outOf, var] = vars[vi];
      if (!*var)
        continue;
      SmallVector<std::pair<BasicBlock *, Value *>, 4> in;
      if (flow)
        in.push_back({flow, flowAt[vi]});
      for (const RegionJoin &j : js)
        for (BasicBlock *p : j.rs)
          if (Value *x = outOf->lookup(p))
            in.push_back({via[{p, j.s}], x});
      if (in.empty())
        continue;
      *var = in.front().second;
      if (all_of(in, [&](const auto &x) { return x.second == in.front().second; }))
        continue;
      PHINode *ph = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), unsigned(in.size()));
      for (BasicBlock *pb : predecessors(R))
        for (auto &[from, x] : in)
          if (from == pb) {
            ph->addIncoming(x, pb);
            break;
          }
      ctx.unc().recordMerge(ph);
      *var = ph;
    }
  };
  auto rejoin = [&]() -> bool {
    BasicBlock *w = nullptr;
    for (BasicBlock *b : pending)
      if (pendSet.count(b)) {
        auto [anyReal, anyLin] = entryKinds(b);
        if (!anyReal && anyLin && none_of(fwdPreds(b), [&](const BasicBlock *p) { return pendSet.count(p) != 0; })) {
          w = b;
          break;
        }
      }
    // r7: with no open block, a join some linearized incoming of which holds where none of its real edges enters (mustWait)
    // stands for w: the rejoin of the real edges lets it be walked in the open flow.
    bool mixedW = false;
    if (!w && !cur)
      for (BasicBlock *b : pending)
        if (pendSet.count(b) && none_of(fwdPreds(b), [&](const BasicBlock *p) { return p != b && pendingPred(p); })) {
          auto [anyReal, anyLin] = entryKinds(b);
          if (anyReal && anyLin && linUncovered(b)) {
            w = b;
            mixedW = true;
            break;
          }
        }
    if (!w)
      return false;
    Pred need = Pred::bottom();
    for (const BasicBlock *p : fwdPreds(w))
      need = need | edgeFact(p, w);
    SmallVector<RegionJoin, 4> all;
    Pred fAll = cur ? curFact : Pred::bottom();
    for (BasicBlock *s : pending) {
      if (!pendSet.count(s) || (s == w && !mixedW))
        continue;
      RegionJoin j{s, {}, Pred::bottom()};
      for (const BasicBlock *p : fwdPreds(s))
        if (factOf.count(p) && !pendSet.count(p) && edgeKind(p, s) == EK::Real && edgeFrom.count({p, s}) && armed(p) &&
            !kunit(p)) {
          j.rs.push_back(const_cast<BasicBlock *>(p));
          j.f = j.f | edgeFact(p, s);
        }
      if (j.rs.empty())
        continue;
      Pred f = (cur ? curFact : Pred::bottom()) | j.f;
      if (!mixedW && (need & !f).isBottom()) {
        buildRejoin({j}, f, true);
        return true;
      }
      fAll = fAll | j.f;
      all.push_back(std::move(j));
    }
    // r7 (cq-vs1eo, SQLite isDate and jsonExtractFunc): no one join covers where w runs, but the region leaves toward several
    // joins whose real edges together do (`if (q) { if (c) J1; else { if (q2) a; J2; } } else { if (d) J1; else J2; }`): one
    // rejoin block for all of them, each join's edges keeping their own fact and values; the other arm's code then runs once
    // in the flow from R, and each join takes the region's edges as linearized incomings (mixedEdge).
    if ((all.size() > 1 || mixedW) && (need & !fAll).isBottom()) {
      buildRejoin(all, fAll, false);
      return true;
    }
    return false;
  };
  for (BasicBlock *b : rpo) {
    if (b == header || !L.contains(b))
      continue;
    if (Loop *sl = subOf(b); sl && sl->getHeader() != b)
      continue;
    if (Loop *k = kunit(b); k && k->getHeader() != b)
      continue;   // a K-unit's exit arm: lowered with the unit
    if (mustWait(b)) {
      pending.push_back(b);
      pendSet.insert(b);
    } else {
      visit(b);
    }
    drain();
  }
  // cq-11qhg (CR rule 14 with rules 8, 9): the walk waits with an open block for a classical join s that the open flow
  // also enters by linearized edges (a quantum branch in one classical arm of the trip with an edge into the join of that
  // arm: `if (c || !q) J;`). Where everything the open flow still has to run lies at s or after it in the trip, the flow
  // ends in a real branch into s: those edges are real edges of s from then on, and the code past them runs once, after s.
  auto flowInto = [&]() -> bool {
    if (!cur)
      return false;
    const unsigned now = unsigned(segs.size() - 1);
    auto inFlow = [&](const BasicBlock *p, const BasicBlock *b) {
      auto ef = edgeFrom.find({p, b});
      return ef != edgeFrom.end() && segIdx.count(ef->second) && segIdx.lookup(ef->second) == now;
    };
    // The blocks of the trip reached from s without the back edge.
    auto after = [&](BasicBlock *s) {
      DenseSet<const BasicBlock *> r{s};
      SmallVector<BasicBlock *, 8> work{s};
      while (!work.empty())
        for (BasicBlock *t : successors(work.pop_back_val()))
          if (t != header && L.contains(t) && r.insert(t).second)
            work.push_back(t);
      return r;
    };
    for (BasicBlock *s : pending) {
      if (!pendSet.count(s) || !entryKinds(s).first)
        continue;
      SmallVector<const BasicBlock *, 4> lin;
      for (const BasicBlock *p : fwdPreds(s))
        if (!pendSet.count(p) && edgeKind(p, s) != EK::Real && inFlow(p, s))
          lin.push_back(p);
      if (lin.empty())
        continue;
      // Every edge the open flow has yet to follow leads to s or past it.
      DenseSet<const BasicBlock *> r = after(s);
      bool ok = true;
      for (auto &[e, from] : edgeFrom)
        if (segIdx.count(from) && segIdx.lookup(from) == now && L.contains(e.second) && e.second != header &&
            !factOf.count(e.second) && !r.count(e.second))
          ok = false;
      if (!ok)
        continue;
      for (const BasicBlock *p : lin) {
        mintEdgeSeeds(const_cast<BasicBlock *>(p), s);
        flowReal.insert({p, s});
        edgeFrom[{p, s}] = cur;
      }
      ctx.B().CreateBr(ob(s));
      cur = nullptr;
      return true;
    }
    return false;
  };
  // cq-a0x8d (CR rule 14 with rules 8, 9; glpk _glp_wclique, glp_analyze_coef): the arms of a classical branch of the trip
  // each hold a quantum branch whose linearized edges meet at a block W before the arms' classical join (`if (c) { if (q1)
  // W; } else { if (q2) W; }`). W runs where either arm ran, so the arms' flows join first: an open flow that waits while
  // another classical arm is still to walk ends in a real branch into a join block R (collect), the arm is walked, and
  // once nothing else can be walked R starts a segment under the union of the flows' facts, the trip predicate, stop rail
  // and captures joined as at any classical join (openJoin). W and the code after it run there.
  struct FlowIn {
    BasicBlock *from;
    SmallVector<Value *, 8> at;
  };
  BasicBlock *joinR = nullptr;
  Pred joinFact = Pred::bottom();
  SmallVector<FlowIn, 4> joinIns;
  auto flowVars = [&]() {
    SmallVector<Value **, 8> v{&aCur, &stopCur};
    for (CPhi &cp : cphis)
      for (unsigned f = 0; f < cp.run.size(); ++f)
        v.push_back(&cp.run[f]);
    return v;
  };
  auto closeFlow = [&]() {
    if (!joinR)
      joinR = newBlock();
    FlowIn in{ctx.B().GetInsertBlock(), {}};
    for (Value **v : flowVars())
      in.at.push_back(*v);
    joinIns.push_back(std::move(in));
    joinFact = joinFact | curFact;
    ctx.B().CreateBr(joinR);
    cur = nullptr;
  };
  auto collect = [&]() -> bool {
    if (!cur)
      return false;
    for (BasicBlock *b : pending) {
      if (!pendSet.count(b))
        continue;
      if (Loop *t = kTail.lookup(b); t && (pendSet.count(t->getHeader()) || !walkedUnits.count(t)))
        continue;
      if (any_of(fwdPreds(b), [&](const BasicBlock *p) { return p != b && pendSet.count(p); }))
        continue;
      if (auto [anyReal, anyLin] = entryKinds(b); anyReal && !anyLin) {
        closeFlow();
        return true;
      }
    }
    return false;
  };
  auto openJoin = [&]() -> bool {
    if (!joinR)
      return false;
    if (cur)
      closeFlow();
    BasicBlock *R = joinR;
    joinR = nullptr;
    startSeg(R);
    curFact = joinFact;
    joinFact = Pred::bottom();
    SmallVector<Value **, 8> vars = flowVars();
    for (unsigned vi = 0; vi < vars.size(); ++vi) {
      Value *v0 = joinIns.front().at[vi];
      if (!v0)
        continue;
      *vars[vi] = v0;
      if (all_of(joinIns, [&](const FlowIn &in) { return in.at[vi] == v0; }))
        continue;
      PHINode *ph = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), unsigned(joinIns.size()));
      for (const FlowIn &in : joinIns)
        ph->addIncoming(in.at[vi], in.from);
      ctx.unc().recordMerge(ph);
      *vars[vi] = ph;
    }
    joinIns.clear();
    return true;
  };
  // A flow into its join first (flowInto); an open flow closes for a classical arm still to walk before it rejoins.
  while (!pendSet.empty() && ((!cur && rejoin()) || flowInto() || collect() || (cur && rejoin()) || openJoin()))
    drain();
  openJoin();   // a flow closed with nothing left to walk goes on from R (and then ends open: the check below)
  // cq-a0x8d (gmp __gmpn_brootinv): a join whose real edges all went to rejoin blocks (a sub-loop's exit edge in one quantum
  // arm, linearized code in the other) was walked in the open flow; its output block was made for those edges and is dead.
  for (const BasicBlock *s : rejoined)
    if (BasicBlock *o = obMap.lookup(s); o && o->empty() && pred_empty(o)) {
      obMap.erase(s);
      o->eraseFromParent();
    }
  if (!pendSet.empty())
    unimplemented("loops-classical: a classical branch nested in a quantum arm of a trip whose region does not close at one join before other linearized code of the trip runs (its arms leave toward several blocks, or the other quantum arm holds code still to walk): the rejoin of a classical region inside an arm is not built", &*(*pendSet.begin())->begin());  if (cur)
    internalError("loops-classical: the trip walk ended with an open block", latch ? latch->getTerminator() : header->getTerminator());

  // Back edges.
  {
    auto it = edgeFrom.find({latch, header});
    if (it == edgeFrom.end())
      internalError("loops-classical: no back edge out of the latch", latch->getTerminator());
    for (unsigned k = 0; k < carried.size(); ++k)
      carried[k].np->addIncoming(nexts[k], it->second);
    if (notFirst)
      notFirst->addIncoming(ConstantInt::getTrue(ctx.M.getContext()), it->second);
    if (stopPhi)
      stopPhi->addIncoming(stopOut.lookup(latch), it->second);
    for (auto &[id, np] : fenvPhis) {
      IRBuilderBase::InsertPointGuard g(ctx.B());
      ctx.B().SetInsertPoint(it->second->getTerminator());
      np->addIncoming(fenv::pieceNow(ctx, id), it->second);
    }
  }
  // CR rule 14 case 3 with rules 8, 9: the classical exit test left into the exit arm. It holds once per activation, on
  // a real branch, so the arm on that edge runs once, in a segment of its own, under the trip predicate at the test (a
  // loop of the arm seeded by it); the phis of C take the arm's value where its edges into C hold over the captures of
  // the quantum exits. Its records are mirrored first by the reverse (the segment precedes the exit).
  for (ArmExit &ax : armExits) {
    startSeg(ax.Y);
    if (stopPhi)
      stopCur = stopOut.lookup(ax.u);
    ArmEval ev;
    if (mx) {
      if (!aAtCx)
        internalError("loops-classical: a classical exit into the arm with no trip predicate at its test",
                      ax.u->getTerminator());
      // A copy of the trip rail: rule 5 keeps the control of a kept store of the arm, this one activation's rail, never the
      // rail every trip's a_j has as its one SSA value.
      Value *armCtl = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
      gate(abi::Core::XorI1, {aAtCx, armCtl});
      ev.entry[{ax.u, ax.x}] = armCtl;
    } else {
      ev.plain = seed(ConstantInt::getTrue(ctx.M.getContext()), RailType{Kind::Int, 1});
      ev.entry[{ax.u, ax.x}] = ev.plain;
    }
    // The arm runs here for this edge's paths only: every predicate under it.
    std::optional<Pred> wasAssumed = ctx.preds().assume(ctx.preds().edge(ax.u, ax.x), ctx.T, ctx.S);
    const bool intoAbort = is_contained(UX.abort, ax.x);
    walkArm(ev, intoAbort ? UX.abort : UX.arm);
    ctx.preds().assume(wasAssumed, ctx.T, ctx.S);
    if (intoAbort && mx)
      noteStop(ev.entry[{ax.u, ax.x}]);
    for (CPhi &cp : cphis) {
      SmallVector<Value *, 2> c(cp.atCx.begin(), cp.atCx.end());
      if (UX.cont)
        for (auto &[u, val] : cp.incomings(inUnit, UX.cont)) {
          Value *g = flagOfEdge(ev, u, UX.cont);
          if (!g)
            continue;
          SmallVector<Operand, 2> fv = contFields(ev, cp, val);
          for (unsigned f = 0; f < c.size(); ++f)
            c[f] = select(g, fv[f], Operand{c[f], true}, cp.rails[f]);
        }
      cp.res.assign(c.begin(), c.end());
      ax.res.push_back(cp.res);
    }
    if (!mx && UX.cont)
      for (PHINode &P : UX.cont->phis()) {
        // Case 1: the value on this edge: its one reached incoming, or rule 9's select chain over their flags.
        std::vector<std::pair<const Value *, Value *>> in;
        for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
          if (Value *g = flagOfEdge(ev, P.getIncomingBlock(i), UX.cont))
            in.push_back({P.getIncomingValue(i), g});
        if (in.empty())
          continue;
        if (ev.bound.count(&P)) {
          ax.contVal[&P] = ctx.operand(&P);
          continue;
        }
        Operand o = ctx.operand(in.back().first);
        const bool q = isQ(&P);
        if (q && P.getType()->isPointerTy() && !o.handle)
          o = Operand{ctx.B().CreatePtrToInt(o.v, Type::getInt64Ty(ctx.M.getContext())), false};
        for (unsigned k = unsigned(in.size()) - 1; k-- > 0;) {
          if (!q) {
            noteUnbuilt("loops-classical: a classical phi of a case-1 loop's continuation chosen inside its exit arm", &P);
            break;
          }
          Operand ok = ctx.operand(in[k].first);
          if (P.getType()->isPointerTy() && !ok.handle)
            ok = Operand{ctx.B().CreatePtrToInt(ok.v, Type::getInt64Ty(ctx.M.getContext())), false};
          o = Operand{select(in[k].second, ok, o, railOf(P.getType())), true};
        }
        ax.contVal[&P] = o;
      }
    if (UX.cont)
      for (BasicBlock *p : predecessors(UX.cont))
        if (inUnit(p) && !L.contains(p))
          edgeFrom[{p, UX.cont}] = cur;
    ax.end = cur;
    ctx.B().CreateBr(T ? T : unitExit);
    cur = nullptr;
  }
  closeSeg();
  // The stop rail where the loop leaves for T.
  if (stopPhi && (cx || armExits.size() > 1 || (armExits.empty() && !(mx ? cxb : exits::liveExiting(L))))) {
    noteUnbuilt("loops-classical: the stop rail of a loop with several exit edges misses the leaving trip's arm flags", header->getTerminator());
    stopCur = stopPhi;
  } else if (stopPhi && armExits.empty()) {
    stopCur = stopOut.lookup(mx ? cxb : exits::liveExiting(L));
  }

  std::vector<std::pair<const Value *, Operand>> out;
  std::vector<RailType> outW;
  DenseSet<const Value *> unbound;   // multi-exit: C's phis, bound here for the first time
  DenseMap<const Value *, unsigned> nFields;
  DenseSet<const Value *> fat;
  // cq-2xl5: with classical exit tests besides the bound, T joins each exit edge's res (a phi per field), and the reverse
  // starts at the segment of the edge taken (exitIndex, as cq-j5mq's).
  const bool multiArm = mx && armExits.size() > 1;
  if (!extraExits.empty() || multiArm) {
    LLVMContext &Cx = ctx.M.getContext();
    SmallVector<std::pair<BasicBlock *, const std::vector<SmallVector<Value *, 2>> *>, 4> from;
    std::vector<SmallVector<Value *, 2>> bound;
    for (CPhi &cp : cphis)
      bound.push_back(cp.res);
    auto leave = [&](BasicBlock *u) {
      auto ef = edgeFrom.find({u, UX.cont});
      return ef == edgeFrom.end() ? nullptr : ef->second;
    };
    if (BasicBlock *lb = midCxb || multiArm ? nullptr : leave(cxb))
      from.push_back({lb, &bound});
    for (ExtraExit &xx : extraExits)
      if (BasicBlock *lb = leave(xx.u))
        from.push_back({lb, &xx.res});
    if (multiArm)
      for (ArmExit &ax : armExits)
        from.push_back({ax.end, &ax.res});
    if (!T || (!multiArm && (cxArm || !armExits.empty())) ||
        any_of(predecessors(T), [&](BasicBlock *p) { return none_of(from, [&](const auto &e) { return e.first == p; }); })) {
      noteUnbuilt("loops-classical: a case-3 loop with several classical exit tests whose exit edges do not all enter "
                  "its continuation from the trip",
                  header->getTerminator());
    } else {
      for (size_t k = 0; k < cphis.size(); ++k) {
        CPhi &cp = cphis[k];
        SmallVector<Value *, 2> merged;
        for (unsigned f = 0; f < cp.rails.size(); ++f) {
          PHINode *ph = PHINode::Create(handleTy(Cx), unsigned(from.size()), "xres");
          ph->insertInto(T, T->end());
          for (BasicBlock *p : predecessors(T))
            for (auto &[lb, rs] : from)
              if (lb == p) {
                ph->addIncoming((*rs)[k][f], p);
                break;
              }
          ctx.unc().recordMerge(ph);
          merged.push_back(ph);
        }
        cp.res.assign(merged.begin(), merged.end());
      }
      // A sub-loop's T is a block of the parent's trip: the parent's reverse comes back through the edge taken (its
      // come-from); the exit index is the outermost loop's alone.
      if (outermost) {
        exitIndex = PHINode::Create(Type::getInt32Ty(Cx), unsigned(from.size()), "exit");
        exitIndex->insertInto(T, T->end());
        for (BasicBlock *p : predecessors(T))
          for (unsigned j = 0; j < from.size(); ++j)
            if (from[j].first == p) {
              exitIndex->addIncoming(ConstantInt::get(Type::getInt32Ty(Cx), j), p);
              break;
            }
        for (auto &[lb, rs] : from)
          exitSegs.push_back(lb);
      }
    }
  }
  for (CPhi &cp : cphis) {
    if (cp.res.empty())
      internalError("loops-classical: a continuation phi of a case-3 loop with no exit value", cp.orig());
    for (unsigned f = 0; f < cp.res.size(); ++f) {
      out.push_back({cp.orig(), Operand{cp.res[f], true}});
      outW.push_back(cp.rails[f]);
    }
    if (cp.res.size() != 1 || cp.ptr || cp.type()->isAggregateType() || cp.type()->isVectorTy())
      nFields[cp.orig()] = unsigned(cp.res.size());
    if (cp.ptr)
      fat.insert(cp.orig());
    if (cp.P)
      unbound.insert(cp.P);
  }
  DenseMap<const Value *, SmallVector<Operand, 2>> pend;
  auto put = [&](const Value *v, Operand op) {
    SmallVector<Operand, 2> ops{op};
    if (auto nf = nFields.find(v); nf != nFields.end()) {
      SmallVector<Operand, 2> &p = pend[v];
      p.push_back(op);
      if (p.size() < nf->second)
        return;
      ops = p;
      pend.erase(v);
    }
    // A unit lowered once per trip of an enclosing K-loop (cq-h5uj) binds its continuation's phis again.
    if (unbound.erase(v) && !ctx.bound(v))
      ctx.bindFields(v, ops);
    else
      ctx.rebind(v, ops);
  };
  for (const Instruction *v : liveOut) {
    if (!isQ(v) && !c3)
      continue;
    if (c3) {
      if (auto n = nextOf.find(v); n != nextOf.end()) {
        unsigned k = 0;
        while (carried[k].orig != n->second)
          ++k;
        out.push_back({v, Operand{nexts[k], true}});
        outW.push_back(railOf(v->getType()));
      } else {
        for (auto &[cv, cp] : caps)
          if (cv == v) {
            out.push_back({v, Operand{cp->getIncomingValueForBlock(edgeFrom[{latch, header}]), true}});
            outW.push_back(railOf(v->getType()));
          }
      }
    } else {
      out.push_back({v, ctx.operand(v)});
      outW.push_back(railOf(v->getType()));
    }
  }
  if (outermost) {
    ctx.B().SetInsertPoint(T);
    // Rules 5, 14: a rail a segment's predicate minted on an edge into a join above the loop (a flag seed) runs once; no
    // trip undoes it (calloc).
    closeSeg();
    if (!segs.empty())
      for (const Seg &sg : segs)
        U.leaveScope(sg.scope, segs.front().bb);
    if (c == Case::ClassicalBound && !nested && !inTrip)
      cleanInvariantOnExit(L);
    if (cx) {
      // One fresh block per exit edge, where the edge's value of each exit phi is read: a classical one by a phi of T,
      // a rail copied out (alloc + copy; a classical incoming the seed itself), the copy an output of the loop.
      LLVMContext &Cx = ctx.M.getContext();
      SmallVector<PHINode *, 4> xphis;
      if (BasicBlock *xb = exitB ? exitB : (c1Arm ? UX.cont : nullptr))
        for (PHINode &P : xb->phis())
          if (any_of(P.blocks(), [&](const BasicBlock *u) { return inUnit(u); }))
            xphis.push_back(&P);
      SmallVector<PHINode *, 4> nps;
      // Rule 5, rule 14 case 1: an exit value something still computes from, or a clone's result (rule 18 copies it out once
      // more at the return, and its twin needs that copy), is no output of the loop: rule 5 uncomputes it after its readers.
      DenseSet<const PHINode *> undone;
      for (PHINode *P : xphis) {
        SmallVector<const Value *, 4> work{P};
        SmallPtrSet<const Value *, 8> seen{P};
        bool returned = false;
        while (!work.empty()) {
          const Value *x = work.pop_back_val();
          for (const User *u : x->users()) {
            returned |= isa<ReturnInst>(u);
            if (isa<PHINode>(u) && !top.contains(cast<Instruction>(u)) && seen.insert(u).second)
              work.push_back(u);
          }
        }
        // An entry's return of P itself copies out the walker's value of P (the unit's phi below, joined or not: Construct.cpp
        // emitReturn, rule 14), and the copy escapes: P's rail is no output either (cq-9ch5t).
        const bool retCopied = ctx.S.isEntry() && any_of(P->users(), [](const User *u) { return isa<ReturnInst>(u); });
        if (isQ(P) && (!readersKeep(P) || (returned && !ctx.S.isEntry()) || retCopied))
          undone.insert(P);
      }
      for (PHINode *P : xphis) {
        PHINode *np = PHINode::Create(isQ(P) ? handleTy(Cx) : P->getType(), 2, P->getName(), T->begin());
        nps.push_back(np);
        // Rule 9: an incoming from outside the unit on a quantum edge that excludes the loop (a pre-header guard): the
        // walker selects it in over this binding, where its edge holds; a classical skip is its classical join.
        if (isQ(P)) {
          const Pred hb = ctx.preds().block(header);
          const Pred cH = hb.classicalFactor(ctx.T, ctx.S);
          for (unsigned i = 0; i < P->getNumIncomingValues(); ++i) {
            BasicBlock *u = P->getIncomingBlock(i);
            const Pred &e = ctx.preds().edge(u, P->getParent());
            if (!inUnit(u) && predsMeet(e, cH) && !predsMeet(e, hb))
              ctx.addJoinArm(P, e, P->getIncomingValue(i));
          }
        }
      }
      exitIndex = PHINode::Create(Type::getInt32Ty(Cx), 2, "exit", T->begin());
      unsigned k = 0;
      // One real edge into T: the phis' values on it, and the segment the reverse starts at.
      auto exitEdge = [&](BasicBlock *from, const std::function<Operand(PHINode *)> &valueOf) {
        BasicBlock *Eb = newBlock();
        from->getTerminator()->replaceSuccessorWith(T, Eb);
        ctx.B().SetInsertPoint(Eb);
        unsigned edgeScope = undone.empty() ? ~0u : U.openScope();
        for (unsigned j = 0; j < xphis.size(); ++j) {
          Operand o = valueOf(xphis[j]);
          if (!isQ(xphis[j])) {
            if (o.handle)
              internalError("loops-classical: a classical exit phi with a rail incoming", xphis[j]);
            nps[j]->addIncoming(o.v, Eb);
            continue;
          }
          RailType w = railOf(xphis[j]->getType());
          CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                     {o.handle ? Constant::getNullValue(irTypeOf(Cx, w)) : o.v});
          if (undone.count(xphis[j])) {
            RailId fid = U.recordSeed(f);
            if (o.handle) {
              abi::CoreSpec cp{abi::Core::Copy, w};
              CallInst *cc = ctx.emitCore(cp, {o.v, f});
              U.recordCore(cc, cp, {o, Operand{f, true}}, fid);
            }
            exitEdgeRails.push_back(fid);
            nps[j]->addIncoming(f, Eb);
            continue;
          }
          if (o.handle)
            U.noteUse(U.idOf(o.v), ctx.emitCore(abi::CoreSpec{abi::Core::Copy, w}, {o.v, f}));
          U.recordExternal(f, Role::Output);
          nps[j]->addIncoming(f, Eb);
        }
        if (edgeScope != ~0u)
          U.closeScope(edgeScope);
        exitEdgeScope.push_back(edgeScope);
        exitIndex->addIncoming(ConstantInt::get(Type::getInt32Ty(Cx), k++), Eb);
        exitSegs.push_back(from);
        ctx.B().CreateBr(T);
      };
      for (BasicBlock *u : L.blocks()) {
        BasicBlock *xs = nullptr;
        for (BasicBlock *y : successors(u))
          if (!top.contains(y))
            xs = y;
        auto ef = edgeFrom.find({u, xs});
        if (!xs || ef == edgeFrom.end() || exitIndex->getBasicBlockIndex(ef->second) >= 0 ||
            !is_contained(predecessors(T), ef->second))
          continue;   // no real edge out of the unit from here (an edge into a dead end needs none)
        exitEdge(ef->second, [&](PHINode *P) {
          // An edge into another exit block than this phi's (its exit arm): any value serves.
          return P->getBasicBlockIndex(u) >= 0 ? ctx.operand(P->getIncomingValueForBlock(u))
                                               : Operand{Constant::getNullValue(P->getType()), false};
        });
      }
      for (ArmExit &ax : armExits)
        exitEdge(ax.end, [&](PHINode *P) {
          auto it = ax.contVal.find(P);
          return it != ax.contVal.end() ? it->second : Operand{Constant::getNullValue(P->getType()), false};
        });
      ctx.B().SetInsertPoint(T);
      for (unsigned j = 0; j < xphis.size(); ++j) {
        bool q = isQ(xphis[j]);
        if (q && undone.count(xphis[j]))
          U.recordMerge(nps[j]);
        else if (q)
          U.recordExternal(nps[j], Role::Output);
        if (ctx.bound(xphis[j]))
          ctx.rebind(xphis[j], {Operand{nps[j], q}});
        else
          ctx.bindFields(xphis[j], {Operand{nps[j], q}});
      }
    }
    // cq-fx3s: a value read after the loop whose exit rail is made by a record of the loop (a trip's
    // template, a seed of the entry) is read in place, and the reverse loop is deferred until after its
    // readers (Uncompute::recordDeferred, CR rule 14: 153, 178); any other (an alias of a carried value,
    // a rail from before the loop) is copied out first, as before.
    if (stopCur)
      stopFinal = stopCur;
    // cq-v1fu, cq-03rdt (CR rules 14, 23; cq/FenvCarry.h step 4): each piece at T is an exit value of the loop, wired as one
    // (read in place or copied out before the reverse undoes the trips), never a trip's rail read after the reverse freed it.
    std::vector<std::pair<unsigned, Operand>> fenvOut;
    for (auto &[id, np] : fenvPhis) {
      fenvOut.push_back({id, Operand{fenv::pieceNow(ctx, id), true}});
      out.push_back({fenv::pieceKey(ctx, id), fenvOut.back().second});
      outW.push_back(RailType{Kind::Int, 32});
    }
    auto fenvSlot = [&](const Value *v) -> Operand * {
      for (auto &[id, o] : fenvOut)
        if (fenv::pieceKey(ctx, id) == v)
          return &o;
      return nullptr;
    };
    // cq-037u2 (CR rule 17 with rule 14): an outermost loop inside an open cq_invert region keeps a copy of each value read
    // after the region's end, made before its reverse, which then runs inside the region.
    auto afterEnd = [&](const Value *v) { return rolled::readAfterInvertEnd(top, v); };
    rolled::Region::ExitWiring wiring = wireExits(
        seedScope, out, outW, stopCur, keptFinal,
        // the environment after the loop is read by eff-fenv until it is replaced: a copy, uncomputed after that reader
        [&](const Value *v) { return fenvSlot(v) || nested || inTrip || !extraExits.empty() || !readersKeep(v); },
        [&](const Value *v, Operand op) {
          if (Operand *o = fenvSlot(v))
            *o = op;
          else
            put(v, op);
        },
        nullptr,
        !nested && !inTrip && !stopCur && U.invertOpen() ? function_ref<bool(const Value *)>(afterEnd)
                                                          : function_ref<bool(const Value *)>());
    for (auto &[id, o] : fenvOut)
      fenv::bindPiece(ctx, id, o.v);
    std::vector<unsigned> &scs = wiring.scs;
    DenseSet<const Value *> &ownedH = wiring.ownedH;
    std::vector<RailId> &exits = wiring.exits;
    if (nested) {
      // Finished by the parent (Unit::flushTrips): the reverse runs in the parent's trip.
      Instruction *xt = nullptr;
      for (BasicBlock *p : predecessors(T))
        xt = p->getTerminator();
      if (!xt)
        internalError("loops-classical: the loop's exit block has no predecessor", latch->getTerminator());
      for (RailId x : exits)
        U.noteUse(x, xt);
      BasicBlock *Cont = newBlock();
      BranchInst::Create(Cont, T);
      std::weak_ptr<Unit> wself = shared_from_this();
      finish = [wself, T, Cont, seedScope, scs, exits, ownedH]() {
        auto self = wself.lock();
        self->flushTrips();
        if (exits.empty()) {
          T->getTerminator()->eraseFromParent();
          IRBuilder<> B(T);
          self->reverse(B, T, seedScope, false);
          B.CreateBr(Cont);
          return;
        }
        std::vector<RailId> reads;
        for (unsigned sc : scs)
          for (const Record &r : self->U.scopeRecords(sc))
            for (const Operand &o : r.ops)
              if (o.handle && !ownedH.count(o.v))
                if (RailId x = self->U.idOf(o.v); !is_contained(reads, x))
                  reads.push_back(x);
        // cq-odo1: the initial rails from before the loop the header phis name are read by the reverse (its anchor
    // notes them); one the loop's own seed scope minted is the item's.
        for (Value *h : self->externalInits)
          if (RailId x = self->U.idOf(h); !ownedH.count(h) && !is_contained(reads, x))
            reads.push_back(x);
        // cq-9kcq S11f: a sub-unit of a rolled K-trip reversed in that K-loop's reverse (Region::addExtraRead).
        for (RailId x : self->extraReadsOf())
          if (!is_contained(reads, x))
            reads.push_back(x);
        self->U.recordDeferred(scs, exits,
                               [self, T, seedScope](IRBuilder<> &B) { self->reverse(B, T, seedScope, !self->U.mirroring()); },
                               reads, self->hostScopes);
      };
      ctx.B().SetInsertPoint(Cont);
      return {};
    }
    bool keptInPlace = copyScope != ~0u && any_of(out, [&](const std::pair<const Value *, Operand> &o) {
      return o.second.handle && !keptFinal.count(o.second.v) && ownedH.count(o.second.v) && readersKeep(o.first);
    });
    if (finishExits(T, seedScope, wiring, keptInPlace, latch->getTerminator(), shared_from_this()))
      deferred = true;
    return {};
  }
  return out;
}

// Is v read after the loop only by what keeps its rail (rule 5, §6 item 1): a measurement, a return, the value of a store?
bool Unit::readersKeep(const Value *v) { return rolled::readersKeep(ctx, top, v); }

void Unit::run(Case c) {
  E = ctx.B().GetInsertBlock();
  cur = E;
  BasicBlock *X = newBlock();
  lowerLoop(top, c, X, true);
  // cq-h5uj: inside a K-loop trip the preheader's rails are the trip's (lowered before the classical branch
  // around the loop): the spine places them after every reader, the deferred reverse included.
  if (!inTrip)
    resolvePreheader();
}

// cq-ot39 (CR rule 5, U5): -O1's LICM hoists a quantum loop invariant into the loop's guarded preheader
// (179's x[j] view, a shift or mul of a register). When the preheader does not dominate the loop's exit
// block (the guard's skip edge joins there), no flush can place the rail's item: it is resolved here, on
// the loop's own exit path, once the loop (and its reverse) has read it. Only template results defined in
// the preheader and read nowhere but there and in the loop.
void Unit::resolvePreheader() {
  BasicBlock *pre = top.getLoopPredecessor();
  BasicBlock *exitB = exits::liveExit(top);
  if (!pre || !exitB)
    return;
  DominatorTree DT(*pre->getParent());
  if (DT.dominates(pre, exitB))
    return;
  std::vector<RailId> rails;
  // GSL ode-initval rk4imp (CR rule 5: a rail is uncomputed before every rail its producer read, so resolving one here resolves its
  // readers too): read nowhere but there and in the loop, transitively. A rail of the preheader read by one that is read
  // after the loop (`q & 2` read by its `lshr`, a value of the exit merge) waits with that one. A quantum guard's atoms are
  // read after the loop too: the exit merge's arms are under the guard's edge predicates (rules 8, 9).
  DenseSet<const Instruction *> outside;
  // The preheader's own terminator, a quantum switch as well as a guard branch (SQLite sqlite3Pragma: a load at an address
  // made here is the scrutinee, read by the flags of the other cases after the loop).
  outside.insert(pre->getTerminator());
  for (bool changed = true; changed;) {
    changed = false;
    for (Instruction &I : *pre)
      if (!outside.count(&I))
        for (const User *u : I.users()) {
          auto *ui = dyn_cast<Instruction>(u);
          if (!ui || (ui->getParent() != pre && !top.contains(ui)) || outside.count(ui)) {
            outside.insert(&I);
            changed = true;
            break;
          }
        }
  }
  for (Instruction &I : *pre) {
    if (I.isTerminator() || !isQ(&I) || isa<CallBase>(I) || isa<PHINode>(I))
      continue;
    bool inside = !outside.count(&I);
    // A guard condition read by the branch alone has no rail of its own (rule 8: its predicate is its atoms' flags).
    if (!inside || !ctx.bound(&I))
      continue;
    Operand op = ctx.operand(&I);
    auto *ci = op.handle ? dyn_cast<CallInst>(op.v) : nullptr;
    if (!ci || !ci->getCalledFunction() || !ci->getCalledFunction()->getName().starts_with("cq_template_"))
      continue;   // a view naming its operand's rail, or a value that is not a fresh template result
    RailId r = ctx.unc().idOf(op.v);
    if (!is_contained(rails, r))
      rails.push_back(r);
  }
  // A deferred reverse (cq-fx3s) reads the hoisted rails after the loop's exit: their items wait for it
  // (Uncompute::recordDeferred's reads) and follow it wherever it is placed.
  if (rails.empty() || deferred)
    return;
  IRBuilder<> &B = ctx.B();
  BasicBlock *Cont = newBlock();
  BranchInst *br = B.CreateBr(Cont);
  ctx.unc().resolveAt(br, rails);
  B.SetInsertPoint(Cont);
}

} // namespace

void lowerClassical(LoweringContext &ctx, Loop &L, Case c) {
  if (c == Case::QuantumExit)
    internalError("loops-classical: lowerClassical of a quantum-exit loop (loops-cutoff)", L.getHeader()->getTerminator());
  std::make_shared<Unit>(ctx, L)->run(c);
}

namespace exits {

namespace {
// CR rule 14 with rules 8, 9 (cq-h8y6): a loop of a K-loop's tail runs in that K-loop's trips for the unit's paths only
// (Exits.h Unit::tail); the walker lowers the tail again for the paths that enter it from outside. Its blocks' predicates
// over the whole function also hold those outside paths, whose atoms may lie in a quantum arm the walk has not reached
// (GMP's mpz_scan0: the tail's join with the other arm). The trip's paths: the assumption, beside any in force, under
// which the loop is lowered in the trip. nullopt when L's header is in no K-loop's tail.
std::optional<Pred> tripPaths(LoweringContext &ctx, const Loop &L) {
  BasicBlock *h = L.getHeader();
  Function &F = *h->getParent();
  DominatorTree DT(F);
  LoopInfo LI(DT);
  for (Loop *O : LI.getLoopsInPreorder()) {
    if (O->contains(h) || classify(*O, ctx.T, ctx.S) != Case::QuantumExit)
      continue;
    Unit U = unitOf(*O);
    if (is_contained(U.tail, h))
      return !tailPred(ctx, *O, U, h, DT);
  }
  return std::nullopt;
}

// Runs f under tripPaths(L) (restored after).
template <typename Fn> auto underTripPaths(LoweringContext &ctx, const Loop &L, Fn f) {
  std::optional<Pred> P = tripPaths(ctx, L);
  if (!P)
    return f();
  std::optional<Pred> was = ctx.preds().assume(std::nullopt, ctx.T, ctx.S);
  ctx.preds().assume(was ? *was & *P : *P, ctx.T, ctx.S);
  auto r = f();
  ctx.preds().assume(was, ctx.T, ctx.S);
  return r;
}
} // namespace

Value *lowerClassicalInTrip(LoweringContext &ctx, Loop &L, Value *trip, bool startsBound) {
  Case c = classify(L, ctx.T, ctx.S);
  if (c == Case::QuantumExit)
    internalError("loops-classical: lowerClassicalInTrip of a quantum-exit loop (loops-cutoff)", L.getHeader()->getTerminator());
  if (!trip)
    internalError("loops-classical: a loop in a K-loop trip with no trip rail", L.getHeader()->getTerminator());
  // The unit may be lowered more than once (an enclosing loop's code lowered again): its phis (and the continuation phis a
  // multi-exit case-3 unit binds) may still name an earlier lowering, which this one replaces (as lowerInstruction does,
  // cq-lx8f).
  spine::Shared &sh = spine::shared(ctx);
  Unit SU = unitOf(L);
  auto forget = [&](BasicBlock *b) {
    for (PHINode &p : b->phis())
      sh.binds.erase(&p);
  };
  for (BasicBlock *b : L.blocks())
    if (!startsBound || b != L.getHeader())   // the caller bound the header phis' starts anew
      forget(b);
  for (BasicBlock *b : SU.arm)
    forget(b);
  if (c == Case::ClassicalBoundQuantumExit && SU.cont &&
      (SU.multi() || liveExiting(L) != L.getLoopLatch() || !SU.abort.empty()))
    for (PHINode &p : SU.cont->phis())
      if (any_of(p.blocks(), [&](const BasicBlock *u) { return SU.contains(L, u); }))
        sh.binds.erase(&p);
  return underTripPaths(ctx, L, [&] { return std::make_shared<cq::loops::Unit>(ctx, L)->runInTrip(c, trip, startsBound); });
}

std::shared_ptr<rolled::Region> lowerClassicalSubInTrip(LoweringContext &ctx, Loop &L, Value *trip, BasicBlock *resetAt,
                                                         Value *&stop) {
  Case c = classify(L, ctx.T, ctx.S);
  if (c == Case::QuantumExit)
    internalError("loops-classical: lowerClassicalSubInTrip of a quantum-exit loop (loops-cutoff)", L.getHeader()->getTerminator());
  if (!trip)
    internalError("loops-classical: a loop in a K-loop trip with no trip rail", L.getHeader()->getTerminator());
  // As lowerClassicalInTrip: the phis of the unit (and the continuation phis a multi-exit case-3 unit binds) are bound anew.
  spine::Shared &sh = spine::shared(ctx);
  Unit SU = unitOf(L);
  auto forget = [&](BasicBlock *b) {
    for (PHINode &p : b->phis())
      sh.binds.erase(&p);
  };
  for (BasicBlock *b : L.blocks())
    forget(b);
  for (BasicBlock *b : SU.arm)
    forget(b);
  if (c == Case::ClassicalBoundQuantumExit && SU.cont &&
      (SU.multi() || liveExiting(L) != L.getLoopLatch() || !SU.abort.empty()))
    for (PHINode &p : SU.cont->phis())
      if (any_of(p.blocks(), [&](const BasicBlock *u) { return SU.contains(L, u); }))
        sh.binds.erase(&p);
  auto sub = std::make_shared<cq::loops::Unit>(ctx, L);
  stop = underTripPaths(ctx, L, [&] { return sub->runSubInTrip(c, trip, resetAt); });
  return sub;
}

} // namespace exits

} // namespace cq::loops
