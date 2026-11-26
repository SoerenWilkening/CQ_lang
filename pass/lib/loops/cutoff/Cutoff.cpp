// Module loops-cutoff (cq-w1-loops-cutoff): rule 14 case 2, quantum-exit loops with cutoff K, and K
// resolution (CLAUDE.md "K per loop").
//
// Construction (CR rule 14, "Quantum-dependent exit, cutoff K"). The loop runs exactly c = min(K, B)
// trips under the predicate chain q_{j+1} = q_j & cont_j, q_0 the loop's seed: the arm flag when the
// header sits under a quantum predicate (a pre-header guard is such an arm: its test is trip 0's, CR
// "the pre-header guard is trip 0 of the latch test"), else a |1> seed. Every quantum carried value
// (header phi) advances by select(q_j, next_j, state_j); a classical carried value advances
// classically. q_c is kept as the output rail (Role::KeptOverflow) iff B > K or no bound is known.
//
// The trips are ROLLED (cq-9kcq; CR rule 14: "one rolled body, classical trip counter, K a run-time value"): one
// emission of the trip, lowered through the spine's per-instruction dispatch, inside a classical loop H .. latch with an
// i32 trip counter j and the latch test `j + 1 < n` (rolledBody). n = umin(Krt, B), or Krt with no bound known, where Krt
// is the loop's own K, or the K received at run time: a table clone's K parameter, and in a function a table clone of the
// module reaches by name, select(@__cq_k == -1, own K, @__cq_k) (CR §1.4 "Received K", rule 27 "Cutoff"; owner ruling Q2 as
// corrected 2026-11-15: the received K replaces the own one, smaller or larger). Where n is not a constant of at least 1
// (K = 0 is legal: no trip runs) or trip 0's test has a classical conjunct, the entry branches on it to H or straight to
// the exit block X (the zero-trip guard). H holds phis of j, of the chain predicate (a handle), of every carried value and
// of every accumulator; X merges the state over its exit edges. a_K is a copy of the chain's last predicate into a fresh
// rail made at X (alloc_i1(0) + copy_i1), kept where Krt < B or no bound is known (a classical branch at X when that is not
// constant). The trip is one segment of a rolled::Region (loops/rolled/Rolled.h): a rail made and last read in the trip is
// undone in its trip (flushTrips), every other record of the trip is mirrored by the region's reverse loop, which pops what
// the forward trips pushed and replays the path each trip took through a come-from index; it runs at X or, deferred, after
// the readers of the exit values (wireExits, finishExits). A measured exit value is kept as the measured rail (05, 150).
// §6 compares semantics, never CFG shape (CR §6, rule 14 "Irreducible control flow").
//
// Two trip shapes, by the header's test region (the C oracle's definition, cq-arch T1.2 and CR rule
// 14 for header-tested loops 09, 37, 54, 189): the header plus the blocks it reaches through single-
// predecessor in-loop edges that are pure, exiting and no latch.
//  - Region form (the region holds an exit and the header is no latch): trip 0's test is the region
//    evaluated on the initial state, before the loop; each trip is body then test. q_j = q_{j-1} & cont(R_j),
//    cont = the region continues into the body; n bodies, n + 1 region evaluations; q_n is a_K. A value of the
//    region the body or the code after the loop reads is carried in a phi of H (regionOut). Every
//    exit leaves from the region; the state is frozen once the loop has exited (q = 0), so the last
//    region evaluation holds every exit value not computed from an induction or a bus load (those take the
//    general exit capture). With an exit from the body too (two exit tests per trip, 189) a_K is the
//    predicate after the K-th latch test: n bodies, n region evaluations (the counter test sits between the
//    latch test and the region).
//  - Body form (otherwise): trip j is the whole body under q_j, cont_j its back-edge predicate. Every
//    exit leaves from the single latch; a value read after the loop is the latch incoming of a quantum
//    header phi, so its exit value is that phi's final state (the state advances on q_j, the trip ran).
//    An exit-block phi whose every incoming is that header phi's (its latch incoming on the exit edge,
//    or an equal value by SCEV: -O1's folded exit value, 149; its pre-header incoming on a guard edge
//    that excludes entering the loop) IS the final state and is bound to it here.
// Nested K-loops roll inside the enclosing trip, seeded by the trip predicate & the inner header's predicate within
// the trip (68, 153): no region of their own, their header and trip blocks segments of the enclosing region, one a_K
// copy per outer trip. A K-loop in a classically bounded loop's trip rolls inside that loop's region the same way
// (lowerNestedCutoff); a classically bounded loop in a K-trip is a sub-unit of the K-loop's region (classicalSub).
//
// An instruction with effects in the body (a call, a bus access, an allocation, a phase or a rotation) is
// lowered under the trip predicate q_j & its block's trip-local predicate (rule 14 case 2, cq-99f7's
// tripFlag); a pure instruction is computed in every trip.
// A trip is any acyclic code (cq-b58q): its quantum branches and switches are its predicates, a classical phi a
// classical select (rule 9), several latches end a trip on one back edge, several header entries merge a quantum
// start (rule 9). A purely classical condition stays a classical branch in the trip (rule 8, cq-jws5r:
// underClassical; a mixed condition's classical factor too, cq-kbygn: tripEdgeFactored): the part of the trip behind it (a block, a sub-loop's unit, a noreturn arm) runs under a real `br`
// on the classical paths that reach it, its effects under the quantum part of its predicate alone. What stays a seed
// rail (rule 7) is a classical term of a predicate read as data outside such a branch: an exit edge's flag, a
// merge's select condition and a term rule 8 cannot factor out (`c || q`). The chain's test branches on its classical
// factor at each test (owner ruling Q10): where it is false the trip leaves for X, a_{j+1} a |0> seed minted on that
// edge. Each block a classical branch of the trip makes (Run, Skip, Join) is a segment of the region (segHook): its own
// Uncompute scope, mirrored by the reverse loop on the path that ran it (come-from), and the skip path's |0> seeds are
// minted in Skip, a record of the Skip segment. A read after a top-level loop that
// the single-exit forms cannot express takes the multi-exit form's GENERAL EXIT CAPTURE.
// Not built yet (each site names itself in a note): an aggregate value carried by the rolled trip or read after it, the
// unit shapes exits::unitOf rejects.
#include "cq/Loops.h"

#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <vector>

#include "Exits.h"
#include "../rolled/Rolled.h"
#include "../../eff/invert/Split.h"
#include "cq/Aggregates.h"
#include "cq/Bus.h"
#include "cq/Predicate.h"
#include "cq/Uncompute.h"
#include "cq/Calls.h"
#include "cq/FenvCarry.h"
#include "cq/Order.h"
#include "../../spine/SpineInternal.h"

#include "llvm/ADT/ScopeExit.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/TargetParser/Triple.h"

using namespace llvm;

namespace {
cq::RailType railOf(Type *t) { return t->isPointerTy() ? cq::RailType{cq::Kind::Int, 64} : cq::railTypeOf(t); }
} // namespace

namespace cq::loops {

namespace {

// cq-jinnf (CR rule 14 "Irreducible control flow"): S branched to fix-irreducible's guard, a latch of the loop the rule's
// cases apply to, before Plugin.cpp oneBackEdge sent its back edge through the one back-edge block (marked cq.backedge).
bool oneBackEdgeLatch(const BasicBlock *S) {
  return any_of(successors(S), [](const BasicBlock *x) { return x->getTerminator()->getMetadata("cq.backedge"); });
}

// The oracle's header test region (checker/oracle/OracleInstr.cpp, cq-arch T1.2): returns whether a
// header run can leave through it, and the region's blocks.
// Only a live exit counts (Exits.h): an edge into an effect-free dead end is never taken (UB to reach,
// 131's switch default), so a header whose only exit goes there tests nothing.
bool testRegion(const Loop &L, SmallPtrSetImpl<const BasicBlock *> &region) {
  BasicBlock *H = L.getHeader();
  exits::Unit U = exits::unitOf(L);
  auto exiting = [&](const BasicBlock *B) {
    return any_of(successors(B), [&](const BasicBlock *s) { return !L.contains(s) && is_contained(U.live, s); });
  };
  bool exits = false;
  SmallVector<BasicBlock *, 4> work{H};
  region.insert(H);
  while (!work.empty()) {
    BasicBlock *B = work.pop_back_val();
    if (exiting(B))
      exits = true;
    for (BasicBlock *S : successors(B)) {
      if (!L.contains(S) || S == H || region.count(S) || S->getSinglePredecessor() != B || L.isLoopLatch(S) ||
          oneBackEdgeLatch(S) || !exiting(S))
        continue;
      bool pure = true;
      for (Instruction &I : *S)
        if (I.mayWriteToMemory() || isa<CallBase>(I) || isa<PHINode>(I))
          pure = false;
      if (pure) {
        region.insert(S);
        work.push_back(S);
      }
    }
  }
  if (L.isLoopLatch(H))
    exits = false;
  return exits;
}

// The analyses the module asks of the original function: its own, so that the inner loops and SCEV
// queries are consistent with each other (the walker's LoopInfo is private to the spine).
struct Analyses {
  DominatorTree DT;
  LoopInfo LI;
  TargetLibraryInfoImpl TLII;
  TargetLibraryInfo TLI;
  AssumptionCache AC;
  ScalarEvolution SE;
  explicit Analyses(Function &F)
      : DT(F), LI(DT), TLII(Triple(F.getParent()->getTargetTriple())), TLI(TLII, &F), AC(F),
        SE(F, TLI, AC, DT, LI) {}
};

class Cutoff {
public:
  Cutoff(LoweringContext &ctx, Analyses &A) : ctx(ctx), A(A) {}
  void lowerLoop(Loop &L, Value *seed, unsigned c, bool keep, bool top);
  std::optional<Pred> seedPred;   // the predicate of the top loop's seed, which every trip rail implies (rule 14)
  // cq-kk46l: the unit is one node of a classically bounded loop's trip (lowerNestedCutoff from loops-classical), whose
  // reverse replays its trip segment by segment: called with each block a classical branch of this unit makes (Run,
  // Skip, Join) before any code goes into it, while the builder is still at the end of the code before it.
  std::function<void(BasicBlock *)> segHook;
  // cq-9kcq (CR rule 27 "Cutoff", §1.4): in a table clone the K the clone received (its trailing classical i32), else
  // nullptr. Every K-loop of the clone, nested ones included, runs that many trips (rolledBody's run-time bound).
  Value *receivedK = nullptr;
  // The loop's bound B (cutoffBound), when known: with a received K the rolled driver cuts at umin(K, B) at run time.
  std::optional<uint64_t> bound;
  Value *stopRail() const { return stopped; }   // the last lowerLoop's XOR of its noreturn arms' flags
  // Owner ruling Q10 (CR rule 14, rule 8): the classical conjunct of the next lowerLoop's trip-0 test (its pre-header
  // guard) that its caller did not branch on, or nullptr. rolledBody's zero-trip guard branches on it before trip 0;
  // taken by that call alone, not by the K-loops nested in its trips.
  Value *test0 = nullptr;

  // cq-9kcq S10 (CR rule 14: "nested inner loops keep one a_K per outer trip"): the rolled region whose trip rolledBody is
  // lowering, or nullptr (a top-level K-loop). A K-loop nested in that trip adds its header and segments to it (no region of
  // its own). S11: set by lowerNestedCutoff to the classically bounded loop's region whose trip holds the loop.
  rolled::Region *rolledTrip = nullptr;
  // cq-9kcq S11: while rolledBody lowers a trip, the output header of the innermost rolled loop (a trip-local classically
  // bounded loop of the trip is a sub-unit of rolledTrip reset there); nullptr outside a rolled trip.
  BasicBlock *tripHead = nullptr;
  // cq-9kcq S11f: the classically bounded loops of a rolled K-trip whose quantum values outlive the trip (not tripLocalSub):
  // sub-units of the region whose reverse runs in the region's reverse (Region::addSub inReverse).
  DenseSet<const Loop *> reverseSubs;

private:
  LoweringContext &ctx;
  Analyses &A;
  DenseSet<const Value *> mine;   // values this module has bound (bind, then rebind per trip)
  // Classical values that differ from trip to trip: a classical header phi (an affine induction, CR
  // rule 14 f981c89) and every classical value computed from one. Trips the C program does not run
  // are computed too, so their copies carry no poison-generating flags (start + j*step may wrap past
  // the exit trip) and a division by one is not built.
  DenseSet<const Value *> perTrip;
  // Rule 9: the phis of a continuation that the loop unit just lowered bound itself. `mine` does not say so: a phi the trip merged
  // on an earlier trip is in it too, and that phi is merged again on this trip (cq-uang6: printf_core's %275).
  DenseSet<const PHINode *> unitBound;
  void forgetUnitBound(const BasicBlock *cont) {
    if (cont)
      for (const PHINode &P : cont->phis())
        unitBound.erase(&P);
  }
  Value *chainEnd = nullptr;                        // the last lowerLoop's last chain predicate (its a_K)
  Value *stopped = nullptr;                         // the last lowerLoop's stop rail (nullptr when none), see stopAcc
  std::vector<std::pair<Loop *, exits::Unit>> enclosing;   // the units being lowered, outermost first


  bool isQ(const Value *v) {
    if (isa<Constant>(v) || isa<BasicBlock>(v) || isa<MetadataAsValue>(v))
      return false;
    return ctx.T.isQuantum(v, ctx.S);
  }
  void set(const Value *orig, Operand op) {
    // A value loops-classical lowers in a trip (cq-h5uj) is bound there first, or forgotten again per trip.
    mine.insert(orig);
    if (!ctx.bound(orig))
      ctx.bindFields(orig, {op});
    else
      ctx.rebind(orig, {op});
  }
  Value *andRail(Value *x, Value *y) {
    LLVMContext &C = ctx.M.getContext();
    abi::CoreSpec as{abi::Core::Alloc, RailType{Kind::Int, 1}};
    CallInst *t = ctx.emitCore(as, {ConstantInt::getFalse(C)});
    RailId id = ctx.unc().recordSeed(t);
    abi::CoreSpec spec{abi::Core::AndI1, RailType{Kind::Int, 1}};
    CallInst *g = ctx.emitCore(spec, {x, y, t});
    ctx.unc().recordCore(g, spec, {Operand{x, true}, Operand{y, true}, Operand{t, true}}, id);
    (void)id;
    return t;
  }
  static bool isAggr(const Value *v) { return v->getType()->isAggregateType() || v->getType()->isVectorTy(); }
  Value *seedRail(Value *classical, Type *ty) {
    RailType w = railOf(ty);
    CallInst *s = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {classical});
    ctx.unc().recordSeed(s);
    return s;
  }
  struct XAcc {
    Instruction *V;
    SmallVector<Operand, 2> acc;
    SmallVector<RailType, 2> rails;
    bool ptr = false;
    bool shaped = false;
  };
  // CR rule 14 (the exit value is quantum: it depends on which trip exited) with rules 21 and 26: the capture
  // rails of a value V of the unit read after it, seeded with V's value where no trip exits (0, NULL's (0, 0)).
  XAcc exitCapture(Instruction &I) {
    XAcc xa;
    xa.V = &I;
    Type *ty = I.getType();
    LLVMContext &C = ctx.M.getContext();
    auto seed = [&](RailType w, Type *t) {
      xa.rails.push_back(w);
      xa.acc.push_back(Operand{seedRail(Constant::getNullValue(t), t), true});
    };
    if (ty->isPointerTy()) {
      seed(RailType{Kind::Int, 64}, Type::getInt64Ty(C));   // rule 3: a pointer is an i64
    } else if (ty->isAggregateType() || ty->isVectorTy()) {
      SmallVector<Type *, 8> tys;
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
          tys.push_back(t);
      };
      leaves(ty);
      for (Type *t : tys)
        if (t->isPointerTy())
          seed(RailType{Kind::Int, 64}, Type::getInt64Ty(C));
        else
          seed(railTypeOf(t), t);
    } else {
      seed(railOf(ty), ty);
    }
    return xa;
  }
  // V's fields in this trip, one per capture rail, at the builder.
  SmallVector<Operand, 4> tripFields(XAcc &xa) {
    Type *ty = xa.V->getType();
    if (ty->isAggregateType() || ty->isVectorTy())
      return aggr::flattenResult(ctx, xa.V);
    Operand v = ctx.operand(xa.V);
    if (ty->isPointerTy() && !v.handle)
      v = Operand{ctx.B().CreatePtrToInt(v.v, Type::getInt64Ty(ctx.M.getContext())), false};
    return {v};
  }
  // After the loop: V is its capture rails.
  void bindCapture(const XAcc &xa) {
    ctx.rebind(xa.V, xa.acc);
  }

  // q & flag(p): the conjunction of a trip predicate with a predicate local to the trip.
  // `care`: the classical facts where the conjunction is read (the flag is a don't-care outside them).
  Value *conj(Value *q, const Pred &p, const Instruction *at, const Pred &care = Pred::top()) {
    if (p.isBottom())
      internalError("loops-cutoff: a trip predicate conjoined with false", at);
    // A classical term still in p (underClassical branches on the classical paths and hands the quantum part on;
    // an exit edge's flag and a merge keep theirs) is seeded by pred's flag synthesis from its
    // classical value in this trip (rule 7) and joined by and_i1/or_i1, as rule 8 does for a classical term it
    // cannot factor out. The conjunction with the trip predicate is quantum, so the effects under it are the
    // quantum-predicate forms of rules 16 and 19.
    (void)at;
    Value *f = ctx.preds().flag(ctx, p, care);
    if (!f)
      return q;
    return andRail(q, f);
  }

  // A terminator inside a trip or an exit arm: a br, a switch, or a computed goto (rules 8, 13). An
  // asm goto is inline asm (rule 27, waiting for its example); an invoke is IR the pinned pipeline
  // cannot emit (rule 25, §0).
  static void checkTerminator(const Instruction *t) {
    if (isa<BranchInst>(t) || isa<SwitchInst>(t))
      return;
    if (isa<IndirectBrInst>(t))
      return;   // rule 13 (b137e75): a switch on the address
    if (isa<CallBrInst>(t))
      unimplemented("loops-cutoff: asm goto (callbr) inside a rule-14 loop: inline asm with a quantum operand "
                    "(rule 27) waits for its CQ_spec example (build step 3)",
                    t);
    internalError("loops-cutoff: a terminator the pinned pipeline cannot emit (CR rule 25, §0: C, x86-64, "
                  "clang -O1; invoke, landingpad and resume come from no C translation unit)",
                  t);
  }
  // The condition under which a trip goes from p to its successor b (rule 8 atoms for a br, rule 13
  // case atoms for a switch: a case edge is its value's equality, the default edge the complement of
  // every case; a computed goto is the switch over its destinations).
  static Pred tripEdge(const BasicBlock *p, const BasicBlock *b) { return exits::tripEdge(p, b); }
  // cq-kbygn (CR rule 8: "A mixed condition is first factored as `C && Q` on its Boolean function (not its syntax) ...
  // `C` stays a classical branch around the quantum part"): a quantum condition expanded through and/or/not/select on
  // i1 into its leaves, each an atom (pred's own expansion of a branch condition).
  Pred expandCond(const Value *x) {
    if (auto *ci = dyn_cast<ConstantInt>(x))
      return ci->isOne() ? Pred::top() : Pred::bottom();
    if (!isQ(x))
      return Pred::atom(x);
    if (auto *bo = dyn_cast<BinaryOperator>(x); bo && bo->getType()->isIntegerTy(1)) {
      switch (bo->getOpcode()) {
      case Instruction::And:
        return expandCond(bo->getOperand(0)) & expandCond(bo->getOperand(1));
      case Instruction::Or:
        return expandCond(bo->getOperand(0)) | expandCond(bo->getOperand(1));
      case Instruction::Xor:
        if (auto *k = dyn_cast<ConstantInt>(bo->getOperand(1)); k && k->isOne())
          return !expandCond(bo->getOperand(0));
        if (auto *k = dyn_cast<ConstantInt>(bo->getOperand(0)); k && k->isOne())
          return !expandCond(bo->getOperand(1));
        break;
      default:
        break;
      }
    }
    if (auto *si = dyn_cast<SelectInst>(x);
        si && si->getType()->isIntegerTy(1) && si->getCondition()->getType()->isIntegerTy(1)) {
      Pred c = expandCond(si->getCondition());
      return (c & expandCond(si->getTrueValue())) | (!c & expandCond(si->getFalseValue()));
    }
    return Pred::atom(x);
  }
  // The expansion of a quantum br condition when one of its edges has a classical conjunct (rule 8 factors it), else
  // nothing: the condition is one atom, its own rail the flag (as pred reads a branch condition).
  std::optional<Pred> factoredCond(const BranchInst *br) {
    if (!br->isConditional() || br->getSuccessor(0) == br->getSuccessor(1) || !isQ(br->getCondition()))
      return std::nullopt;
    Pred f = expandCond(br->getCondition());
    if (f.classicalFactor(ctx.T, ctx.S).isTop() && (!f).classicalFactor(ctx.T, ctx.S).isTop())
      return std::nullopt;
    return f;
  }
  // The condition under which a trip goes from p to its successor b: a br with a factorable mixed condition is read on
  // its Boolean function, so its classical factor is a classical term of the trip's predicates, which underClassical
  // makes a real branch (rule 8); every other edge is tripEdge's. A loop test too (owner ruling Q10, 2026-11-11; CR rule
  // 14: "A classical conjunct `C` of the exit test (`while (c && q)`) is a classical branch AT EACH TEST (rule 8)"): the
  // chain's test (chainTest in lowerLoop) branches on the classical factor of the predicate of going on.
  Pred tripEdgeFactored(const BasicBlock *p, const BasicBlock *b) {
    auto *br = dyn_cast<BranchInst>(p->getTerminator());
    if (!br)
      return tripEdge(p, b);
    std::optional<Pred> f = factoredCond(br);
    if (!f)
      return tripEdge(p, b);
    return br->getSuccessor(0) == b ? *f : !*f;
  }
  // Is the quantum i1 I read whole by a br of the unit (an atom of its trip predicates, computed as data)?
  bool readWhole(const BranchInst *br) { return !factoredCond(br); }
  // The classical part of tripEdge as a classical i1 of the current trip: a quantum condition counts
  // as true. A classical phi's incoming edge is chosen by classical conditions alone (taint: a phi
  // whose choice depends on a quantum condition is quantum), so among edges whose classical part
  // holds, every one carries the merged value.
  Value *classicalEdge(const BasicBlock *p, const BasicBlock *b) { return exits::classicalEdge(ctx, p, b); }
  // A classical select chain over (condition, value): the first arm whose condition holds, the last
  // arm where none does (rule 9's classical select, ruling 2026-10-27).
  Value *classicalChain(ArrayRef<std::pair<Value *, Value *>> arms) {
    if (arms.empty())
      internalError("loops-cutoff: a classical select chain with no arms");
    Value *r = arms.back().second;
    for (size_t i = arms.size() - 1; i-- > 0;)
      r = ctx.B().CreateSelect(arms[i].first, arms[i].second, r);
    return r;
  }
  // The merge of a quantum phi of a trip over its arms (trip-local edge predicate, value). cq-o5tjh (CR rule 9: "A
  // `select` or `phi` whose condition (or choice of incoming edge) is purely classical is a classical `select`/`phi`
  // over the handles, no gate; ... a literal incoming of a classical `phi` over handles is a seed"): where the choice
  // among the arms is classical, the classical select chain over the handles (each select a merge, Uncompute U1), its
  // conditions read from this trip's classical values; else rule 9's select chain, a classical term a seed (rule 8).
  Value *mergeArms(ArrayRef<std::pair<Pred, Operand>> arms, Type *ty) {
    RailType w = railOf(ty);
    // The choice is classical when, at the merge (where some arm's predicate holds, M), every arm's predicate is M & a
    // classical condition: its classical projection. Where M is false the merge is never read.
    Pred M = Pred::bottom();
    for (auto &a : arms)
      M = M | a.first;
    std::vector<Pred> cls;
    for (auto &a : arms) {
      Pred c = a.first.classicalProjection(ctx.T, ctx.S);
      Pred d = M & c;
      if (!((d & !a.first) | (!d & a.first)).isBottom())
        return selectChain(ctx, arms, w);
      cls.push_back(c);
    }
    if (arms.empty())
      return selectChain(ctx, arms, w);
    Value *r = nullptr;
    for (size_t i = arms.size(); i-- > 0;) {
      Operand v = arms[i].second;
      if (!v.handle)
        v = Operand{seedRail(v.v->getType()->isPointerTy() ? ctx.B().CreatePtrToInt(v.v, ctx.B().getInt64Ty()) : v.v,
                             v.v->getType()->isPointerTy() ? ctx.B().getInt64Ty() : ty),
                    true};
      if (!r) {
        r = v.v;
        continue;
      }
      if (v.v == r)
        continue;
      Value *cond = classicalValue(ctx, cls[i]);
      if (auto *k = dyn_cast<ConstantInt>(cond)) {
        if (k->isOne())
          r = v.v;
        continue;
      }
      Value *sel = ctx.B().CreateSelect(cond, v.v, r);
      if (auto *si = dyn_cast<Instruction>(sel))
        ctx.unc().recordMerge(si);
      r = sel;
    }
    return r;
  }
};

void Cutoff::lowerLoop(Loop &L, Value *seed, unsigned c, bool keep, bool top) {
  // cq-oyirf (CR rule 17, owner ruling 2026-11-16): a loop run again after a cq_invert region's end keeps no a_K; the
  // in-region loop's is the kept rail.
  const bool repeat = invert::repeatedLoop(L);
  if (repeat)
    keep = false;
  Value *t0 = test0;
  test0 = nullptr;
  BasicBlock *H = L.getHeader();
  // The latches (rule 14: a `continue` is one more back edge of the same chain). A trip ends on one
  // back edge or one exit edge; `latch` is the latch the body form's exits leave from (the one live
  // exiting latch, else the first latch: then the body form does not apply and `multi` is set below).
  SmallVector<BasicBlock *, 4> latches;
  L.getLoopLatches(latches);
  BasicBlock *latch = latches.front();
  if (latches.size() > 1) {
    exits::Unit U0 = exits::unitOf(L);
    BasicBlock *one = nullptr;
    bool several = false;
    for (BasicBlock *b : L.blocks())
      for (BasicBlock *s : successors(b))
        if (!L.contains(s) && is_contained(U0.live, s)) {
          several |= one && one != b;
          one = b;
        }
    if (one && !several && is_contained(latches, one))
      latch = one;
  }
  // The header's predecessors outside the loop (-O1 may fold the preheader into a join before the
  // loop). A carried value's start is its one incoming from them, or, where they differ, their merge.
  SmallVector<BasicBlock *, 2> outside;
  for (BasicBlock *p : predecessors(H))
    if (!L.contains(p) && !is_contained(outside, p))
      outside.push_back(p);
  if (outside.empty())
    internalError("loops-cutoff: a loop header with no predecessor outside the loop", H->getTerminator());
  auto startOf = [&](const PHINode *h) -> Value * {
    Value *v = h->getIncomingValueForBlock(outside.front());
    for (BasicBlock *u : outside)
      if (h->getIncomingValueForBlock(u) != v)
        return nullptr;
    return v;
  };
  // The unit (Exits.h): its continuation and exit arm; an exit into an effect-free dead end is no exit.
  exits::Unit U = exits::unitOf(L);
  // The units this one is lowered inside of (a loop of an exit arm, a sub-loop), itself last.
  enclosing.push_back({&L, U});
  auto leaveUnit = make_scope_exit([&] { enclosing.pop_back(); });
  auto liveEdge = [&](const BasicBlock *s) { return !L.contains(s) && is_contained(U.live, s); };
  BasicBlock *X = U.multi() ? nullptr : U.cont;

  // Sub-loops: a quantum-exit loop is a nested K-loop (its chain seeded by the trip predicate), a classically
  // bounded one (rule 14 case 1 or 3) a rolled classical loop inside each trip (cq-h5uj, classicalSub below).

  // The body's terminators: every branch and switch of a trip, quantum or classical, is a predicate of
  // the trip (edgeCond); the trip is straight-line code under those predicates.
  bool classicalTerms = false;   // a classical branch or switch in a trip
  for (BasicBlock *b : L.blocks()) {
    Instruction *t = b->getTerminator();
    checkTerminator(t);
    if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional() && !isQ(br->getCondition()))
      classicalTerms = true;
    if (auto *br = dyn_cast<BranchInst>(t); br && factoredCond(br))
      classicalTerms = true;   // cq-kbygn: a mixed condition's classical factor
    if (auto *sw = dyn_cast<SwitchInst>(t); sw && !isQ(sw->getCondition()))
      classicalTerms = true;
    if (auto *ib = dyn_cast<IndirectBrInst>(t); ib && !isQ(ib->getAddress()))
      classicalTerms = true;
  }

  SmallPtrSet<const BasicBlock *, 8> region;
  bool regionForm = testRegion(L, region);
  SmallVector<BasicBlock *, 4> exiting;
  L.getExitingBlocks(exiting);
  // MULTI-EXIT form (several live exit blocks, or a live exit outside the trip shape's single exit
  // point): every exit edge of a trip is taken under q_j & its block's trip-local predicate & its
  // condition, the exit arm runs per trip under those predicates (rule 9 inside the trip, as the
  // body's own arms), and each phi of the continuation C that has an incoming from the unit is a rail
  // that takes this trip's value where the trip exits: acc' = select(q_j & E_j, v_j, acc), v_j the
  // select chain over C's unit incomings, E_j their union (190's memcmp: "next %22 = H ? this trip's
  // exit value : so far"). Nothing else of the unit is read after it. The state is frozen once the
  // loop has exited (q = 0), so a later trip's v_j never reaches acc.
  bool multi = U.multi();
  for (BasicBlock *e : exiting) {
    if (none_of(successors(e), liveEdge))
      continue;   // only into dead ends (UB to reach)
    if (regionForm ? !region.count(e) : e != latch)
      multi = true;
  }
  if (multi)
    for (BasicBlock *e : exiting)
      if (A.LI.getLoopFor(e) != &L && any_of(successors(e), liveEdge))
        unimplemented("loops-cutoff: a multi-exit K-loop with an exit from inside a sub-loop (cq-lgkx)", e->getTerminator());

  // The trip order: reverse post-order of the loop's blocks, back edges dropped.
  std::vector<BasicBlock *> order;
  {
    std::vector<BasicBlock *> post;
    SmallPtrSet<BasicBlock *, 16> seen;
    std::function<void(BasicBlock *)> dfs = [&](BasicBlock *b) {
      seen.insert(b);
      for (BasicBlock *s : successors(b)) {
        if (!L.contains(s) || seen.count(s))
          continue;
        Loop *sl = A.LI.getLoopFor(s);
        if (sl && sl->getHeader() == s && sl->contains(b))
          continue;   // a back edge
        dfs(s);
      }
      post.push_back(b);
    };
    dfs(H);
    order.assign(post.rbegin(), post.rend());
  }
  // The outermost sub-loop of L holding b, or nullptr. For a block of the unit outside L (the exit arm,
  // a noreturn arm): the outermost loop of the arm holding it (a loop not containing L's header).
  // A sub-loop with several live exits (cq-lgkx) is a unit with an exit arm of its own (Exits.h): the arm
  // blocks inside L belong to that unit, one node of the trip that ends at its continuation.
  // Its TAIL (Exits.h, cq-t30vh) is not: the sub-unit lowers it for its own paths, and on the paths that enter it from outside
  // that unit it is a block of this trip like any other, whose edges into the continuation are selected in over the unit's value.
  DenseMap<const BasicBlock *, Loop *> subArm, subTail;
  SmallVector<std::pair<Loop *, exits::Unit>, 4> subUnits;
  for (Loop *S : L.getSubLoops())
    subUnits.push_back({S, exits::unitOf(*S)});
  for (auto &[S, SU] : subUnits) {
    // cq-6wzf3 (TinyCC tcc_assemble_internal): a sub-loop inside another sub-loop's exit arm (not its tail) is a block of that
    // unit, its own arm too (the arm runs up to C), whichever sub-loop comes first.
    if (any_of(subUnits, [&, S = S](const auto &o) {
          return o.first != S && is_contained(o.second.arm, S->getHeader()) && !is_contained(o.second.tail, S->getHeader());
        }))
      continue;
    for (BasicBlock *b : SU.arm)
      if (L.contains(b)) {
        if (is_contained(SU.tail, b))
          subTail[b] = S;
        else
          subArm[b] = S;
      }
  }
  auto subLoopOf = [&](const BasicBlock *b) -> Loop * {
    if (Loop *S = subArm.lookup(b))
      return S;
    Loop *l = A.LI.getLoopFor(b), *last = nullptr;
    if (!L.contains(b)) {
      while (l && !l->contains(H)) {
        last = l;
        l = l->getParentLoop();
      }
      return last;
    }
    while (l && l != &L) {
      last = l;
      l = l->getParentLoop();
    }
    return last;
  };

  // Predicates local to one trip (relative to the header), over the body's own branch conditions.
  DenseMap<const BasicBlock *, Pred> local;
  auto edgeCond = [&](BasicBlock *p, BasicBlock *b) -> Pred { return tripEdgeFactored(p, b); };
  // r7 (glpk glp_ios_driver, glp_mir_gen): a block inside a sub-loop of the trip, other than its header, has a predicate only
  // the sub-loop's own blocks read (and a latch of L inside one, cq-iaz30): the sub-loop is a unit, its exit taken where its
  // header ran. Built over the sub-loop's inner exits that never rejoin it, that predicate grows with every inner loop
  // (millions of BDD nodes), so it is made on demand (localOf) and not for every block of the trip.
  auto inSub = [&](const BasicBlock *b) {
    Loop *S = subLoopOf(b);
    return S && S->getHeader() != b;
  };
  std::function<const Pred &(BasicBlock *)> localOf;
  // r8 (glpk glp_ios_driver; CR rules 14, 16, taint's dead-end rule cq-820w): an edge of a body block into a noreturn arm
  // does not restrict its live siblings in the trip predicates; the share falls to the last successor that is neither a
  // noreturn arm nor a dead end (`receiver`). The trip leaves on that edge instead: right after the block, q_j is narrowed
  // by the edge's flag (lowerBlocks, abortEdges), as after a sub-loop with a noreturn arm (afterSub), and the arm runs
  // under that flag. Every block, exit and arm flag is then the one the restricted predicates gave, without carrying
  // every earlier abort test into every later block's predicate (78 asserts: thousands of BDD nodes per block). Only
  // where no classical path through p is certain to abort (rule 8: such a path keeps its real branch) and never in the
  // header test region (its evaluation leaves q_j as it found it).
  // A body block whose edges into noreturn arms leave the trip right after it (lowerBlocks): with or without a receiver.
  auto narrows = [&](BasicBlock *p) {
    return L.contains(p) && !subLoopOf(p) && !(regionForm && region.count(p)) &&
           any_of(successors(p), [&](BasicBlock *s) { return is_contained(U.abort, s); });
  };
  DenseMap<const BasicBlock *, BasicBlock *> receiverMemo;
  auto receiver = [&](BasicBlock *p) -> BasicBlock * {
    if (auto it = receiverMemo.find(p); it != receiverMemo.end())
      return it->second;
    BasicBlock *r = nullptr;
    if (narrows(p)) {
      for (BasicBlock *s : successors(p))
        if (!is_contained(U.abort, s) && !is_contained(U.dead, s))
          r = s;
      if (r) {
        Pred A = Pred::bottom();
        for (BasicBlock *s : successors(p))
          if (is_contained(U.abort, s))
            A = A | edgeCond(p, s);
        const Pred &Lp = localOf(p);
        Pred c0 = Lp.classicalProjection(ctx.T, ctx.S), c1 = (Lp & !A).classicalProjection(ctx.T, ctx.S);
        if (!((c0 & !c1) | (!c0 & c1)).isBottom())
          r = nullptr;
      }
    }
    receiverMemo[p] = r;
    return r;
  };
  auto contribution = [&](BasicBlock *p, BasicBlock *b) -> Pred {
    if (Loop *S = subLoopOf(p); S && !S->contains(b)) {
      exits::Unit SU = exits::unitOf(*S);
      if (SU.contains(*S, b) || is_contained(SU.dead, b))
        return Pred::bottom();   // inside the sub-unit (its exit arm, its noreturn arm: its own trips) or dead
      if (SU.cont != b)
        unimplemented("loops-cutoff: a nested K-loop with more than one exit block (cq-lgkx)", p->getTerminator());
      return local.find(S->getHeader())->second;   // the sub-loop as a unit always ends at its exit
    }
    if (!is_contained(U.abort, b) && receiver(p) == b) {
      Pred others = Pred::bottom();
      SmallPtrSet<BasicBlock *, 4> seen;
      for (BasicBlock *s : successors(p))
        if (s != b && !is_contained(U.abort, s) && seen.insert(s).second)
          others = others | edgeCond(p, s);
      return localOf(p) & !others;
    }
    return localOf(p) & edgeCond(p, b);
  };
  auto predOfBlock = [&](BasicBlock *b) {
    Pred acc = Pred::bottom();
    for (BasicBlock *p : predecessors(b)) {
      if (!L.contains(p))
        continue;
      Loop *bl = A.LI.getLoopFor(b);
      if (bl && bl->getHeader() == b && bl->contains(p))
        continue;   // back edge of a sub-loop
      if (!local.count(p) && !inSub(p))
        internalError("loops-cutoff: a predecessor after its successor in the trip order", p->getTerminator());
      acc = acc | contribution(p, b);
    }
    return acc;
  };
  localOf = [&](BasicBlock *b) -> const Pred & {
    if (auto it = local.find(b); it != local.end())
      return it->second;
    Pred acc = predOfBlock(b);
    return local.insert({b, acc}).first->second;
  };
  for (BasicBlock *b : order) {
    if (b == H) {
      local.insert({b, Pred::top()});
      continue;
    }
    if (inSub(b))
      continue;
    local.insert({b, predOfBlock(b)});
  }
  Pred cont = Pred::bottom();   // body form: some back edge is taken
  std::vector<Pred> contParts, regionParts;   // cont and regionCont as unions of their edges' predicates (cq-m16f6)
  // cq-iaz30 (CR rule 14): a latch inside a sub-loop whose exit edge is the back edge (sqlite exprAnalyzeOrTerm: the inner
  // scan's `if (!p) continue outer`) is that sub-loop's exit; as a unit the sub-loop always ends there (contribution). Its
  // exit test's atom is a rail of the sub-loop's rolled trip, which does not reach the end of this trip.
  for (BasicBlock *l : latches) {
    Pred c = contribution(l, H);
    cont = cont | c;
    // A plain latch's contribution is its block predicate (the union of its incoming edges') and its back edge's
    // condition: one part per incoming edge, so a latch many paths join is no one large flag (cq-m16f6).
    bool plain = l != H && !subLoopOf(l) && (is_contained(U.abort, H) || receiver(l) != H);
    if (!plain) {
      contParts.push_back(c);
      continue;
    }
    SmallPtrSet<BasicBlock *, 8> seen;
    for (BasicBlock *p : predecessors(l)) {
      Loop *bl = A.LI.getLoopFor(l);
      if (!L.contains(p) || (bl && bl->getHeader() == l && bl->contains(p)) || !seen.insert(p).second)
        continue;   // predOfBlock's edges
      if (Pred e = contribution(p, l) & edgeCond(l, H); !e.isBottom())
        contParts.push_back(e);
    }
  }
  Pred regionCont = Pred::bottom();                               // region form
  if (regionForm)
    for (const BasicBlock *r : L.blocks()) {   // the loop's order: a first edgeCond may number an atom
      if (!region.count(r))
        continue;
      SmallPtrSet<const BasicBlock *, 8> seen;   // a switch lists a successor once per case
      for (BasicBlock *s : successors(const_cast<BasicBlock *>(r)))
        if (L.contains(s) && !region.count(s) && seen.insert(s).second) {
          regionParts.push_back(localOf(const_cast<BasicBlock *>(r)) & edgeCond(const_cast<BasicBlock *>(r), s));
          regionCont = regionCont | regionParts.back();
        }
    }

  // Values of the loop read after it, and the exit-block phis identified with a header phi.
  std::vector<PHINode *> hphis;
  for (PHINode &h : H->phis())
    hphis.push_back(&h);
  auto headerPhiWithNext = [&](const Value *v) -> PHINode * {
    for (PHINode *h : hphis)
      if (h->getIncomingValueForBlock(latch) == v)
        return h;
    return nullptr;
  };
  // CR rule 14 (f981c89): an affine induction with a quantum loop-invariant start (a quantum header
  // phi whose latch incoming is the phi plus or minus classical invariants, each step in a block that
  // dominates the latch) is not carried either: in trip j it is ONE template from the start rail and
  // the classical offset j*step (190: n - j). Only a read after the loop keeps a carried rail, the
  // exit value, advancing by select on the trip predicate.
  struct QInduction {
    Operand start;                                   // the invariant start rail
    std::vector<std::pair<bool, const Value *>> steps;  // (add?, classical invariant) from the phi out
    Value *off = nullptr;                            // the classical offset of the current trip
    std::optional<Operand> exitRail;                 // set when the value is read after the loop
  };
  MapVector<PHINode *, QInduction> qind;   // cq-aeroi: walked to seed rails, in insertion order
  DominatorTree &DT = A.DT;
  for (PHINode *h : hphis) {
    if (!isQ(h) || !h->getType()->isIntegerTy())
      continue;
    Value *st = startOf(h);
    if (!st)
      continue;   // several starts: carried
    if (auto *SI = dyn_cast<Instruction>(st); SI && L.contains(SI))
      continue;
    auto invariant = [&](const Value *X) {
      if (isa<Constant>(X))
        return true;
      auto *XI = dyn_cast<Instruction>(X);
      return !(XI && L.contains(XI)) && !isQ(X);
    };
    std::vector<std::pair<bool, const Value *>> steps;
    const Value *V = h->getIncomingValueForBlock(latch);
    // An unconditional step: one next value on every back edge, computed where every latch passes.
    bool ok = all_of(latches, [&](BasicBlock *l) { return h->getIncomingValueForBlock(l) == V; });
    auto domAll = [&](const BasicBlock *b) {
      return all_of(latches, [&](BasicBlock *l) { return DT.dominates(b, l); });
    };
    while (ok && V != h) {
      auto *BO = dyn_cast<BinaryOperator>(V);
      if (!BO || !L.contains(BO) || !domAll(BO->getParent()) ||
          (BO->getOpcode() != Instruction::Add && BO->getOpcode() != Instruction::Sub)) {
        ok = false;
        break;
      }
      if (BO->getOpcode() == Instruction::Add && invariant(BO->getOperand(0)) && !invariant(BO->getOperand(1))) {
        steps.push_back({true, BO->getOperand(0)});
        V = BO->getOperand(1);
      } else if (invariant(BO->getOperand(1))) {
        steps.push_back({BO->getOpcode() == Instruction::Add, BO->getOperand(1)});
        V = BO->getOperand(0);
      } else {
        ok = false;
      }
    }
    if (!ok || steps.empty())
      continue;
    std::reverse(steps.begin(), steps.end());
    QInduction qi;
    qi.steps = std::move(steps);
    qi.off = ConstantInt::get(h->getType(), 0);
    qind.insert({h, std::move(qi)});
  }
  std::vector<std::pair<const Value *, PHINode *>> exitRebinds;   // body form: value -> its header phi
  // CR rules 14, 16 (taint's dead-end rule, as loops-classical's noLiveQ): every quantum exit goes into a noreturn arm and
  // every live exit is a classical test no quantum branch of the trip leads to. The trip that leaves for the continuation
  // is then the one its classical tests give, so a classical value of the loop keeps its classical exit value there:
  // taint reads it as classical after the loop (GMP mpn_mu_divappr_q), and no exit rail is made for it.
  bool noLiveQ = !U.abort.empty();
  for (BasicBlock *u : L.blocks()) {
    if (none_of(successors(u), [&](BasicBlock *s) { return !L.contains(s) && is_contained(U.live, s); }))
      continue;
    const Instruction *t = u->getTerminator();
    const Value *c = nullptr;
    if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional())
      c = br->getCondition();
    else if (auto *sw = dyn_cast<SwitchInst>(t))
      c = sw->getCondition();
    else if (auto *ib = dyn_cast<IndirectBrInst>(t))
      c = ib->getAddress();
    if ((c && isQ(c)) || ctx.T.controlTainted(u, ctx.S))
      noLiveQ = false;
  }
  // CR rule 14 (f981c89): an affine induction (a classical header phi, taint) is not carried; when the
  // program reads its exit value after the loop, a rail seeded with the start advances by
  // select(q_j, rail + step, rail) for that read alone (never used in the loop).
  MapVector<PHINode *, Operand> exitRail;   // cq-aeroi: walked to seed rails, in insertion order
  std::vector<Instruction *> regionQReads;   // region form: quantum values read after the loop
  // GENERAL EXIT CAPTURE. The single-exit forms read an exit value from the final state (body form:
  // a header phi's latch incoming; region form: the last region evaluation, the state being frozen
  // once the loop exited). A read they cannot express that way (a body value of a header-tested loop,
  // a value computed from an induction, whose trip value is not frozen, a classical value other than
  // an affine induction, several exit edges into one phi) takes the multi-exit form's capture: each
  // such value is a rail that takes this trip's value where the trip exits (rule 14: the exit value
  // is quantum, it depends on which trip exited).
  bool general = false;
  // A nested loop takes it too (cq-lgkx): its capture binds through set(), once per outer trip, and the
  // outer trip reads the unit as one node ending at its continuation.
  auto takeGeneral = [&](const char *what, const Instruction *at) {
    (void)what;
    (void)at;
    general = true;
  };
  // A value whose slice inside the loop reaches an induction or a bus load: its trip value is not frozen after the
  // exit (the address advances; a load under a predicate that is 0 reads nothing, rule 14).
  auto fromInduction = [&](const Instruction *I) {
    SmallVector<const Value *, 8> work{I};
    SmallPtrSet<const Value *, 16> seen;
    while (!work.empty()) {
      const Value *V = work.pop_back_val();
      auto *VI = dyn_cast<Instruction>(V);
      if (!VI || !L.contains(VI) || !seen.insert(V).second)
        continue;
      if (isa<LoadInst>(VI))
        return true;
      if (auto *h = dyn_cast<PHINode>(VI)) {
        if (h->getParent() == H && VI != I && (!isQ(h) || qind.count(const_cast<PHINode *>(h))))
          return true;
        if (h->getParent() == H)
          continue;
      }
      for (const Use &U : VI->operands())
        work.push_back(U.get());
    }
    return false;
  };
  for (BasicBlock *b : L.blocks())
    for (Instruction &I : *b) {
      if (multi || general)
        break;   // multi-exit form: read below
      bool outside = false;
      for (const Use &U : I.uses()) {
        auto *ui = cast<Instruction>(U.getUser());
        const BasicBlock *at = ui->getParent();
        if (auto *phi = dyn_cast<PHINode>(ui))
          at = phi->getIncomingBlock(U);
        if (!L.contains(at) || (isa<PHINode>(ui) && !L.contains(ui->getParent())))
          outside = true;
      }
      // cq-hmxd5 (CR rule 14 "No live exit"): with no live exit nothing runs after the loop; a reader outside it is in a
      // noreturn arm, which runs per trip on that trip's values, or in a dead end.
      if (U.live.empty())
        outside = false;
      if (!outside)
        continue;
      if (regionForm) {
        if (!region.count(b)) {
          takeGeneral("loops-cutoff: a value of a nested header-tested K-loop's body read after the loop (cq-lgkx)", &I);
          continue;
        }
        if (!isQ(&I)) {
          // A classical value is the last region evaluation's, not the exit trip's: an affine
          // induction's exit value is its exit rail (CR rule 14), any other the general capture.
          auto *h = dyn_cast<PHINode>(&I);
          if (!h || h->getParent() != H || !h->getType()->isIntegerTy()) {
            takeGeneral("loops-cutoff: a classical value of a nested K-loop's test region read after the loop that "
                        "is not an affine induction's exit value (cq-lgkx)",
                        &I);
            continue;
          }
          exitRail.insert({h, Operand{nullptr, false}});
          exitRebinds.push_back({&I, h});
        } else if (fromInduction(&I) || isAggr(&I)) {
          // cq-9kcq S21: an aggregate value takes the general capture too (one rail per field, rule 26)
          takeGeneral("loops-cutoff: a value of a nested K-loop's test region computed from an induction, read "
                      "after the loop (cq-lgkx)",
                      &I);
        } else {
          regionQReads.push_back(&I);
        }
        continue;   // the last region evaluation holds it (frozen state)
      }
      PHINode *h = headerPhiWithNext(&I);
      if (h && !isQ(h) && noLiveQ) {
        exitRebinds.push_back({&I, h});   // its classical final state
        continue;
      }
      if (h && !isQ(h) && h->getType()->isIntegerTy())
        exitRail.insert({h, Operand{nullptr, false}});   // CR rule 14: an affine induction's exit value
      if (!h || (!isQ(h) && !exitRail.count(h))) {
        takeGeneral("loops-cutoff: a value read after a nested K-loop that is not the latch incoming of a "
                    "header phi (cq-lgkx)",
                    &I);
        continue;
      }
      exitRebinds.push_back({&I, h});
    }
  // Region form: a quantum phi of the exit block over several exit edges of the region.
  if (regionForm && X && !multi)
    for (PHINode &P : X->phis())
      if (isQ(&P) && count_if(P.blocks(), [&](const BasicBlock *u) { return L.contains(u); }) > 1)
        takeGeneral("loops-cutoff: a phi of a nested header-tested K-loop's exit block over several exit edges (cq-lgkx)", &P);
  if (general) {
    multi = true;
    exitRebinds.clear();
    exitRail.clear();
    regionQReads.clear();
  }
  std::vector<std::pair<PHINode *, PHINode *>> exitPhis;   // exit phi -> header phi it denotes
  if (!regionForm && !multi && X) {
    const Pred &pH = ctx.preds().block(H);
    for (PHINode &P : X->phis()) {
      if (!isQ(&P))
        continue;
      PHINode *id = nullptr;
      bool ok = true, foreign = false;
      for (unsigned i = 0; i < P.getNumIncomingValues() && ok; ++i) {
        BasicBlock *u = P.getIncomingBlock(i);
        Value *v = P.getIncomingValue(i);
        PHINode *h = nullptr;
        if (L.contains(u)) {
          h = headerPhiWithNext(v);
          if (!h && !(isa<Instruction>(v) && L.contains(cast<Instruction>(v)->getParent()))) {
            // -O1 folded the exit value (indvars): equal by SCEV to a carried value's exit value.
            const SCEV *sv = A.SE.getSCEV(v);
            for (PHINode *c : hphis) {
              Value *nx = c->getIncomingValueForBlock(latch);
              if (A.SE.isSCEVable(nx->getType()) && nx->getType() == v->getType() &&
                  A.SE.getSCEVAtScope(nx, L.getParentLoop()) == sv) {
                h = c;
                break;
              }
            }
            if (!h)
              foreign = true;
          }
        } else {
          // An edge the paths this loop is lowered for exclude (the tail of an earlier unit, whose own path binds the phi
          // on its edge): the general capture binds the phi for these paths.
          if (ctx.preds().edge(u, X).isBottom())
            foreign = true;
          for (PHINode *c : hphis)
            if (startOf(c) == v &&
                (ctx.preds().edge(u, X) & pH).isBottom()) {
              h = c;
              break;
            }
        }
        if (h && !isQ(h) && h->getType()->isIntegerTy() && L.contains(u))
          exitRail.insert({h, Operand{nullptr, false}});
        if (!h || (id && id != h) || (!isQ(h) && !exitRail.count(h)))
          ok = false;
        else
          id = h;
      }
      // cq-xec3y (jnf): an earlier loop unit exiting into X already bound P (an exit edge of that loop reads this one's
      // start); the general capture's `earlier` form merges this unit's exit value into that binding.
      if (ok && !foreign && id && top && ctx.bound(&P)) {
        takeGeneral("loops-cutoff: an exit phi an earlier unit bound (cq-xec3y)", &P);
        continue;
      }
      // A loop nested in a trip's arm is run under that arm's flag: what its classical factor skips is the arm's own business.
      if (ok && !foreign && id && (!top || ctx.preds().block(H).classicalFactor(ctx.T, ctx.S).isTop())) {
        exitPhis.push_back({&P, id});
        continue;
      }
      if (foreign)
        takeGeneral("loops-cutoff: an exit phi of a nested K-loop reading a value from outside the loop on an exit "
                    "edge that is not the exit value of a carried value (cq-lgkx)",
                    &P);
    }
    if (general) {   // the multi-exit form's capture binds every phi of the exit block
      multi = true;
      exitPhis.clear();
      exitRebinds.clear();
      exitRail.clear();
      }
  }

  // Multi-exit form: what the unit gives C. A value of the loop or the arm is read outside the unit
  // only by a phi of C on an edge from the unit; each such phi is quantum. Its incomings from outside
  // the unit (the pre-header guard's skip edge, 190's `n == 0`) are its initial value: they must be
  // taken only where the header is not reached, and agree.
  struct CPhi {
    PHINode *P;
    Operand acc;
    bool ptr = false;
    bool shaped = false;
    SmallVector<Operand, 2> accs;
  };
  std::vector<CPhi> cphis;
  // A value of the unit read after it other than by a phi of C: its exit value, a rail that takes this
  // trip's value where the trip leaves the loop (acc' = select(q_j & X_j, v_j, acc), X_j the trip's
  // exit edges). SSA dominance makes v defined on every path to the reader, so where the reader runs
  // the exit that was taken passed v's definition in that trip. Rebound to the reader after the loop.
  std::vector<XAcc> xaccs;
  if (multi) {
    BasicBlock *C = U.cont;
    auto inUnit = [&](const BasicBlock *b) { return U.contains(L, b); };
    SmallVector<BasicBlock *, 16> unitBlocks(L.blocks().begin(), L.blocks().end());
    unitBlocks.append(U.arm.begin(), U.arm.end());
    for (BasicBlock *b : unitBlocks)
      for (Instruction &I : *b)
        for (const Use &Us : I.uses()) {
          auto *ui = cast<Instruction>(Us.getUser());
          if (inUnit(ui->getParent()))
            continue;
          auto *phi = dyn_cast<PHINode>(ui);
          if (phi && phi->getParent() == C && inUnit(phi->getIncomingBlock(Us)))
            continue;
          if (any_of(xaccs, [&](const XAcc &x) { return x.V == &I; }))
            continue;
          if (noLiveQ && !isQ(&I))
            continue;   // its classical exit value (noLiveQ above)
          xaccs.push_back(exitCapture(I));
        }
    for (BasicBlock *a : U.arm)
      checkTerminator(a->getTerminator());
    const Pred &pH = ctx.preds().block(H);
    for (PHINode &P : C->phis()) {
      bool fromUnit = false;
      for (BasicBlock *u : P.blocks())
        fromUnit |= inUnit(u);
      if (!fromUnit)
        continue;
      // cq-xuaam (rule 9): every exit gives the same value from outside the unit (both returns 0), so taint holds P
      // classical: P is that value wherever the unit leaves, no rail of the exits.
      if (Value *same = P.hasConstantValue(); same && !isQ(&P)) {
        auto *si = dyn_cast<Instruction>(same);
        if (!si || !inUnit(si->getParent())) {
          if (!ctx.bound(&P))
            ctx.bindFields(&P, {ctx.operand(same)});
          continue;
        }
      }
      if (!isQ(&P))
        unimplemented("loops-cutoff: a classical phi joining a multi-exit K-loop's exits (cq-uytx)", &P);
      if (!(P.getType()->isPointerTy() || P.getType()->isIntegerTy() || P.getType()->isFloatingPointTy()))
        unimplemented("loops-cutoff: a non-scalar phi joining a multi-exit K-loop's exits (cq-p45s)", &P);
      // The value where the unit does not run. Its incomings from outside the unit are taken only where the
      // header is not reached (mutually exclusive with every trip's exit). Several differing ones are rule 9's
      // select chain over their edge predicates, built before the loop. A phi a unit lowered earlier already
      // bound (two loops exiting into one join, each skipping the other: jnf) holds that unit's value where it
      // ran and the outside values it could see: it is this unit's initial value, and an incoming of a later
      // unit (a loop not lowered yet) is that unit's to select in when it is lowered.
      Pred cH = pH.classicalFactor(ctx.T, ctx.S);
      std::vector<std::pair<Pred, Operand>> outside;
      bool earlier = ctx.bound(&P);
      // A loop of an earlier unit's tail runs under the assumption of its header's paths, and an incoming that skips the loop
      // (stpcpy: a pre-header guard where the first word already holds the zero) lies outside it. That edge is read under the
      // assumption's classical part only: the classical facts of the tail's paths, not the quantum branches into the header.
      auto outsideEdge = [&](BasicBlock *u) {
        std::optional<Pred> was = ctx.preds().assume(std::nullopt, ctx.T, ctx.S);
        Pred e = ctx.preds().edge(u, C);
        ctx.preds().assume(was, ctx.T, ctx.S);
        return was ? e & was->classicalFactor(ctx.T, ctx.S) : e;
      };
      for (unsigned i = 0; i < P.getNumIncomingValues() && !earlier; ++i) {
        BasicBlock *u = P.getIncomingBlock(i);
        if (inUnit(u))
          continue;
        // A classical skip of the loop (its edge excludes the classical condition the unit runs under):
        // the walker joins it with the unit's value classically (joinUnitPhi, rule 9 at a58c3a4).
        if ((outsideEdge(u) & cH).isBottom())
          continue;
        if (!(outsideEdge(u) & pH).isBottom())
          unimplemented("loops-cutoff: a phi joining a multi-exit K-loop's exits with an incoming from outside the "
                        "loop on an edge that does not exclude the loop (cq-uytx)",
                        &P);
        Value *v = P.getIncomingValue(i);
        // r7 (rules 9, 14; GMP __gmpz_congruent_2exp_p): u in the exit arm, not the tail, of another quantum-exit loop that does
        // not hold L in its own arm is that unit's: its value is one of its trips' rails, which never reaches here; that unit
        // binds C's phi for its edge. (L nested in a classically bounded loop's arm, the phi forgotten for L's binding.)
        if (ctx.bound(v) && !A.LI.getLoopFor(u))
          if (any_of(A.LI.getLoopsInPreorder(), [&](Loop *O) {
                if (O == &L || O->contains(H))
                  return false;
                exits::Unit OU = exits::unitOf(*O);
                const Case oc = classify(*O, ctx.T, ctx.S);
                return (oc == Case::QuantumExit || oc == Case::ClassicalBoundQuantumExit) && is_contained(OU.arm, u) &&
                       !is_contained(OU.tail, u) && !is_contained(OU.arm, H);
              }))
            continue;
        if (!ctx.bound(v) || !predReadable(ctx, outsideEdge(u))) {
          const Loop *vl = A.LI.getLoopFor(u);
          // cq-iaz30 (rules 9, 14): u in the exit arm of another quantum-exit loop into C is that unit's, whether it is lowered
          // later (GSL gsl_ran_hypergeometric) or around this one, L in its arm (SQLite sqlite3ExprAffinity). On its own paths
          // its trips merge u's edge (their atoms are one trip's); only a tail block's paths from outside it are the walker's,
          // under its tail predicate (as that unit gives them, unless it is lowered earlier).
          std::optional<Pred> ownArm;
          if (!vl)
            for (Loop *O : A.LI.getLoopsInPreorder()) {
              if (O == &L || O->contains(H) || !is_contained(exits::unitOf(*O).arm, u))
                continue;
              const Case oc = classify(*O, ctx.T, ctx.S);
              if (oc != Case::QuantumExit && oc != Case::ClassicalBoundQuantumExit)
                continue;
              exits::Unit OU = exits::unitOf(*O);
              ownArm = is_contained(OU.tail, u) ? exits::tailPred(ctx, *O, OU, u, A.DT) & ctx.preds().edge(u, C)
                                                : Pred::bottom();
              break;
            }
          if (ownArm && !ownArm->isBottom())
            ctx.addJoinArm(&P, *ownArm, v);
          else if (!ownArm && (!vl || vl->contains(H)))
            ctx.addJoinArm(&P, outsideEdge(u), v);   // lowered after the loop: the walker selects it in
          continue;   // or another loop unit's exit: it selects its value in over this binding when lowered
        }
        Pred e = outsideEdge(u);
        auto same = find_if(outside, [&](const std::pair<Pred, Operand> &a) { return a.second.v == ctx.operand(v).v; });
        if (same != outside.end())
          same->first = same->first | e;
        else
          outside.push_back({e, ctx.operand(v)});
      }
      // cq-h8y6: an incoming from a tail block (Exits.h) on the outside paths: the walker lowers the tail after the
      // unit; where those paths are not classically excluded from the unit (a quantum choice) it selects their
      // value in under their predicate (tailPred & the edge) over this binding, a classical one it joins
      // (joinUnitPhi).
      if (!earlier)
        for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
          BasicBlock *u = P.getIncomingBlock(i);
          if (!is_contained(U.tail, u) || exits::inTailLoopUnit(L, U, u, A.LI))
            continue;
          Pred e = exits::tailPred(ctx, L, U, u, A.DT) & ctx.preds().edge(u, C);
          if (e.isBottom() || (e & cH).isBottom())
            continue;
          ctx.addJoinArm(&P, e, P.getIncomingValue(i));
        }
      // With no incoming from outside, the value where no trip exits (the cutoff reached first) is 0.
      Operand acc;
      if (earlier) {
        // A loop of an earlier unit's tail runs on classical paths that unit never took too (cq-mk4ty, stpcpy's word
        // loop): where their facts exclude its exit edges into C the binding is a don't-care, a |0> seed at the join.
        Pred ran = Pred::bottom();
        for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
          if (BasicBlock *u = P.getIncomingBlock(i);
              A.LI.getLoopFor(u) && none_of(enclosing, [&](auto &e) { return e.second.contains(*e.first, u); }))
            ran = ran | outsideEdge(u);   // a unit still being lowered around this one has bound nothing yet
        acc = ctx.operand(&P);
        Value *boundRail = acc.v;
        if (acc.handle && !ran.isBottom())
          acc = reachingOperand(ctx, acc, railOf(P.getType()), ran, Pred::top());
        // The earlier unit ran on classical paths that exclude this one, so its binding saw none of this path's incomings
        // (mbsrtowcs: the pre-header's quantum skip, the tail's edges). They are this unit's, as with no earlier unit.
        if (acc.v != boundRail) {
          std::vector<std::pair<Pred, Operand>> mineOut;
          Pred E = Pred::bottom();
          for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
            BasicBlock *u = P.getIncomingBlock(i);
            const Pred &e = ctx.preds().edge(u, C);
            if (inUnit(u) || A.LI.getLoopFor(u) || (e & cH).isBottom() || !(e & pH).isBottom())
              continue;
            Value *v = P.getIncomingValue(i);
            if (!ctx.bound(v) || !predReadable(ctx, e)) {
              ctx.addJoinArm(&P, e, v);
              continue;
            }
            E = E | e;
            mineOut.push_back({e, ctx.operand(v)});
          }
          for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
            BasicBlock *u = P.getIncomingBlock(i);
            if (!is_contained(U.tail, u) || exits::inTailLoopUnit(L, U, u, A.LI))
              continue;
            Pred e = exits::tailPred(ctx, L, U, u, A.DT) & ctx.preds().edge(u, C);
            if (!e.isBottom() && !(e & cH).isBottom())
              ctx.addJoinArm(&P, e, P.getIncomingValue(i));
          }
          if (!mineOut.empty()) {
            mineOut.push_back({!E, acc});
            acc = Operand{selectChain(ctx, mineOut, railOf(P.getType())), true};
          }
        }
      } else if (outside.empty())
        acc = Operand{Constant::getNullValue(P.getType()), false};
      else if (outside.size() == 1)
        acc = outside.front().second;
      else
        acc = Operand{selectChain(ctx, outside, railOf(P.getType())), true};
      if (!acc.handle)
        acc = Operand{seedRail(acc.v, P.getType()), true};
      cphis.push_back({&P, acc});
    }
  }

  // Region form: the state is frozen once the loop exited, but an induction's trip value is not, so a
  // read of a quantum-start induction after the loop is its exit rail (a region value computed from an
  // induction is read through the general exit capture: `general` above).
  for (Instruction *I : regionQReads)
    if (auto *h = dyn_cast<PHINode>(I); h && qind.count(h))
      exitRebinds.push_back({I, h});
  for (auto &[v, h] : exitRebinds)
    if (auto it = qind.find(h); it != qind.end())
      it->second.exitRail = Operand{};
  for (auto &[P, h] : exitPhis)
    if (auto it = qind.find(h); it != qind.end())
      it->second.exitRail = Operand{};

  // A header phi's initial value: its start, or, entered from several blocks outside the loop with
  // different values, the merge of those (rule 9's select chain over the entry edges' predicates,
  // evaluated here where the walker has reached the header). A classical phi with several starts is
  // a classical choice at a classical join the walker owns.
  auto initOf = [&](PHINode *h, bool tag) -> Operand {
    auto opOf = [&](Value *v) { return ctx.operand(v); };
    // The header is the continuation of a loop just before this one: that unit bound h on its exit edge (the exit value
    // of the trip that left, not its carried state).
    if (isQ(h) && exits::boundByLoopBefore(ctx, *h, A.LI))
      return ctx.operand(h);
    if (Value *v = startOf(h))
      return opOf(v);
    if (!isQ(h)) {
      // cq-kldr: the walker made the classical choice at its join before the loop (a phi of its edges
      // into the header's output block) and bound h to it: that is the start.
      Operand v = ctx.operand(h);
      if (v.handle)
        internalError("loops-cutoff: a classical carried value's start bound to a rail", h);
      mine.insert(h);
      return v;
    }
    std::vector<std::pair<Pred, Operand>> arms;
    for (BasicBlock *u : outside)
      arms.push_back({ctx.preds().edge(u, H), opOf(h->getIncomingValueForBlock(u))});
    return Operand{selectChain(ctx, arms, tag ? RailType{Kind::Int, 32} : railOf(h->getType())), true};
  };
  // Rule 6's rolled-loop clause (203's x, 05's n): a carried value read in the loop only by its bijective update, which
  // runs on every trip and is the next value, is cleaned in each trip with the composite inverse a ? U^-1(y') : y'; its
  // trip predicate cannot read it. Trip 0's old rail is the incoming rail. As in loops-classical, the chain is a register
  // only when its final value is read after the loop.
  DenseSet<const PHINode *> six;
  DenseSet<const Value *> sixSeeds;   // a seed as trip 0's old rail is freed directly, not cleaned (rule 6, rule 7)
  // cq-njnmt (CR rules 6, 14, 16): a noreturn arm behind a classical condition of the trip (an assert on a measured outcome)
  // is entered by a real branch, after which the trip leaves the loop without its latch segment: the clean-up placed at the
  // latch block's end would not run there, and the reverse loop's mirror of the trip finds the old rail still read (the
  // select taking the new value). The old rail is undone by the reverse loop like any carried rail.
  bool classicalAbort = any_of(U.abort, [&](BasicBlock *b) {
    return any_of(predecessors(b), [&](BasicBlock *p) {
      if (!L.contains(p))
        return false;
      const Instruction *t = p->getTerminator();
      if (auto *br = dyn_cast<BranchInst>(t))
        return br->isConditional() && !isQ(br->getCondition());
      if (auto *sw = dyn_cast<SwitchInst>(t))
        return !isQ(sw->getCondition());
      return false;
    });
  });
  if (top && !multi && latches.size() == 1 && !classicalAbort) {
    BasicBlock *pre = L.getLoopPredecessor();
    for (PHINode *h : hphis) {
      if (!pre || !isQ(h) || !(h->getType()->isIntegerTy() || h->getType()->isFloatingPointTy()) || !h->hasOneUse() ||
          exitRail.count(h) || qind.count(h))
        continue;
      auto *Up = dyn_cast<Instruction>(h->getIncomingValueForBlock(latch));
      // cq-9kcq (rolled form): the clean-up is placed in the trip at the latch block's end, after U's own undo; both read
      // the old rail, whose every use must lie in that block (Uncompute's flush places an item in one block). U in an
      // earlier block of the trip (a classical branch between U and the latch) leaves the old rail to the reverse loop.
      if (!Up || !L.contains(Up) || *h->user_begin() != Up || Up->getParent() != latch ||
          !spine::inverseStep(
              *Up, h, Operand{Up, true}, [](Value *z) { return Operand{z, false}; }, [](Value *) { return false; }))
        continue;
      bool live = false, ok = true;
      for (const User *usr : Up->users()) {
        auto *ui = dyn_cast<Instruction>(usr);
        if (usr == h)
          continue;
        if (!ui || L.contains(ui))
          ok = false;
        else
          live = true;
      }
      // cq-8zz4v (CR rules 6, 14, 17): inside an open cq_invert region a final value read after the region's end is copied
      // out (wireExits' afterEnd, cq-037u2) and its rail undone by the reverse loop inside the region: no register is kept
      // past the loop, so the chain is not cleaned per trip.
      // cq-oyirf (CR rule 17): nor is a final value read in the region only by what does not keep it (a computation).
      if (ok && live && ctx.unc().invertOpen() &&
          (rolled::readAfterInvertEnd(L, Up) || !rolled::keptByReader(ctx, L, Up)))
        live = false;
      if (ok && live && exits::initDead(ctx, L, h->getIncomingValueForBlock(pre), h))
        six.insert(h);
    }
  }
  // The state: header phis bound to their initial values (a classical initial value of a quantum phi
  // becomes a seed rail).
  for (PHINode *h : hphis) {
    // A classical pointer header phi is an affine induction (taint, CR rule 14: a walked pointer with a
    // classical start): a classical value in each trip, nothing carried.
    if (!h->getType()->isIntegerTy() && !h->getType()->isFloatingPointTy() && (isQ(h) || !h->getType()->isPointerTy()) &&
        !h->getType()->isPointerTy())   // rule 3: a pointer is carried as an i64 handle
      unimplemented("loops-cutoff: a carried value that is not a scalar (aggregates, pointers) (cq-p45s)", h);
    Operand init = initOf(h, false);
    if (isQ(h) && !init.handle) {
      init = Operand{seedRail(init.v, h->getType()), true};
      if (six.count(h))
        sixSeeds.insert(init.v);
    }
    if (!isQ(h) && init.handle)
      internalError("loops-cutoff: a classical header phi with a rail initial value", h);
    if (auto it = exitRail.find(h); it != exitRail.end())
      it->second = Operand{seedRail(init.v, h->getType()), true};
    if (!isQ(h))
      perTrip.insert(h);
    if (auto it = qind.find(h); it != qind.end()) {
      it->second.start = init;
      if (it->second.exitRail)
        it->second.exitRail = init;   // select is out of place: the start rail is the trip-0 state
    }
    if (six.count(h) && !sixSeeds.count(init.v))
      ctx.unc().setRole(ctx.unc().idOf(init.v), Role::UserRegister);
    set(h, init);
  }

  DenseSet<const PHINode *> boundThisTrip;
  // Classical reachability inside the current trip (classicalEdge: quantum conditions count as true),
  // for the classical phis of the trip and of the exit arm; made on first need, forgotten when the
  // header runs again. `evaluated` holds the blocks lowered since: a block not among them is not
  // reached by this evaluation.
  DenseMap<const BasicBlock *, Value *> creach;
  SmallPtrSet<const BasicBlock *, 16> evaluated;
  const std::function<bool(const BasicBlock *)> *armPick = nullptr;   // capture's evaluation, while it runs
  std::function<Value *(const BasicBlock *)> creachOf = [&](const BasicBlock *b) -> Value * {
    LLVMContext &Cx = ctx.M.getContext();
    if (b == H)
      return ConstantInt::getTrue(Cx);
    if (!evaluated.count(b))
      return ConstantInt::getFalse(Cx);
    if (auto it = creach.find(b); it != creach.end())
      return it->second;
    Value *acc = ConstantInt::getFalse(Cx);
    for (const BasicBlock *p : predecessors(b)) {
      if (!U.contains(L, p) || !evaluated.count(p))
        continue;
      if (Loop *bl = A.LI.getLoopFor(b); bl && bl->getHeader() == b && bl->contains(p) && bl != &L)
        continue;   // back edge of a sub-loop or of a loop of the arm
      Value *e;
      if (Loop *S = subLoopOf(p); S && !S->contains(b))
        e = creachOf(S->getHeader());   // the sub-loop as a unit always ends at its exit
      else
        e = ctx.B().CreateAnd(creachOf(p), classicalEdge(p, b));
      acc = ctx.B().CreateOr(acc, e);
    }
    return creach[b] = acc;
  };
  // A classical phi of the trip or the exit arm: the classical select chain over its incoming edges
  // reached in this evaluation (rule 9, a classical choice is a classical select).
  auto classicalPhi = [&](PHINode &P) {
    std::vector<std::pair<Value *, Value *>> arms;
    for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
      BasicBlock *u = P.getIncomingBlock(i);
      if (!U.contains(L, u) || !evaluated.count(u) || (armPick && L.contains(u) && !(*armPick)(u)))
        continue;
      Value *e;
      if (Loop *S = subLoopOf(u); S && !S->contains(P.getParent()))
        e = creachOf(S->getHeader());
      else
        e = ctx.B().CreateAnd(creachOf(u), classicalEdge(u, P.getParent()));
      Operand v = ctx.operand(P.getIncomingValue(i));
      if (v.handle)
        internalError("loops-cutoff: a classical phi with a rail incoming", &P);
      arms.push_back({e, v.v});
    }
    if (arms.empty())
      internalError("loops-cutoff: a classical phi with no incoming in this evaluation", &P);
    set(&P, Operand{classicalChain(arms), false});
    perTrip.insert(&P);
  };
  // cq-h5uj (CR rule 14 case 1 or 3 inside a case-2 trip): a classically bounded loop S of a trip (a sub-loop,
  // or a loop of the exit arm) stays a classical loop over its classical bound, lowered once per trip by
  // loops-classical under the trip's predicate `trip` (q & S's header predicate within the trip): its effects
  // are controlled by it, a case-3 chain is seeded by it. The trip's code is straight-line, but S runs only
  // where the trip's classical path reaches its header (creachOf: a classical guard, -O1's `m > 0` before a
  // rotated loop, false there would run S over an unbounded count): a real classical branch around S, its
  // values read after it joined with |0> seeds (a classical value: 0) minted before the branch on the skip
  // path, where the trip reads them under a false classical edge only. Its reverse is deferred after their
  // readers, guarded by "S's exit was passed". unitPhi: the phis of S's continuation S binds itself (a
  // multi-exit case-3 loop), their value where S ran, joined the same way; the trip's merge reads that value
  // on S's edges into the continuation.
  DenseMap<const PHINode *, Operand> unitPhi;
  auto classicalSub = [&](Loop &S, Value *q, const Pred &lp, const Instruction *at) {
    exits::Unit SU = exits::unitOf(S);
    Case sc = classify(S, ctx.T, ctx.S);
    auto inSub = [&](const BasicBlock *b) { return SU.contains(S, b); };
    SmallVector<PHINode *, 4> cBound;
    if (sc == Case::ClassicalBoundQuantumExit && SU.cont &&
        (SU.multi() || exits::liveExiting(S) != S.getLoopLatch() || !SU.abort.empty()))
      for (PHINode &P : SU.cont->phis()) {
        if (!any_of(P.blocks(), inSub))
          continue;
        // A classical phi whose every incoming is one value from outside S's unit is that value wherever S exits:
        // loops-classical leaves it to the code around S (GLPK mpl_fn_str2time's all-poison hub phis), the trip here.
        const Value *v0 = P.getIncomingValue(0);
        auto *vi = dyn_cast<Instruction>(v0);
        if (!isQ(&P) && all_of(P.incoming_values(), [&](const Value *v) { return v == v0; }) &&
            !(vi && inSub(vi->getParent())))
          continue;
        cBound.push_back(&P);
      }
    // The values of S's unit read after it (a phi of the continuation on an edge from the unit included,
    // unless S binds that phi itself).
    SmallVector<Instruction *, 8> outs;
    SmallVector<BasicBlock *, 16> blocks(S.blocks().begin(), S.blocks().end());
    blocks.append(SU.arm.begin(), SU.arm.end());
    for (BasicBlock *bb : blocks)
      for (Instruction &I : *bb)
        for (const Use &Us : I.uses()) {
          auto *ui = cast<Instruction>(Us.getUser());
          if (inSub(ui->getParent()) || is_contained(cBound, ui))
            continue;
          if (!is_contained(outs, &I))
            outs.push_back(&I);
        }
    // cq-o5tjh (rule 8, as underClassical): lp's classical part is the branch around S, its quantum part alone the
    // trip rail's conjunct (no seed of a classical term).
    Pred cg = lp.isBottom() ? Pred::top() : lp.classicalProjection(ctx.T, ctx.S);
    // cq-3630b: read only where cg holds (the branch around S below; TinyCC decl: lp's quantum part reads an atom minted
    // only on cg's paths of the trip).
    Value *trip = conj(q, cg.isTop() ? lp : lp.quantumPart(ctx.T, ctx.S), at, cg);
    Value *g = creachOf(S.getHeader());
    if (!cg.isTop()) {
      Value *cv = classicalValue(ctx, cg);
      auto *g0 = dyn_cast<ConstantInt>(g);
      g = g0 && g0->isOne() ? cv : ctx.B().CreateAnd(g, cv);
    }
    auto *gc = dyn_cast<ConstantInt>(g);
    if (gc && gc->isZero())
      internalError("loops-cutoff: a sub-loop lowered where the trip's classical path never reaches it", at);
    // cq-9kcq S11 (ROLLED_DESIGN.md §3 step 7): in a rolled trip S is a sub-unit of the K-loop's region, entered from the
    // open segment; the trip goes on in a fresh segment after it (the reverse passes the sub-unit through its come-from).
    auto lowerSub = [&]() -> Value * {
      if (!tripHead)
        return exits::lowerClassicalInTrip(ctx, S, trip);
      IRBuilder<> &B = ctx.B();
      BasicBlock *entry = B.GetInsertBlock();
      Function &Of = ctx.out();
      BasicBlock *last = &Of.back();
      Value *st = nullptr;
      std::shared_ptr<rolled::Region> sub = exits::lowerClassicalSubInTrip(ctx, S, trip, tripHead, st);
      std::vector<BasicBlock *> made;
      for (auto it = std::next(last->getIterator()); it != Of.end(); ++it)
        made.push_back(&*it);
      BasicBlock *cont = B.GetInsertBlock();
      BasicBlock *nx = BasicBlock::Create(ctx.M.getContext(), "", &Of);
      B.CreateBr(nx);
      const bool inReverse = reverseSubs.count(&S) != 0;
      rolledTrip->addSub(sub, entry, cont, made, inReverse);
      rolledTrip->startSeg(nx);
      if (inReverse) {
        // cq-9kcq S11f: S's values outlive the trip (a carried value, a value read after the K-loop): its reverse runs in the
        // K-loop's reverse, in the mirror of the segment nx starts, after the records of the trip that read its exit rails.
        // A |0> seed of nx's scope that S's deferred reverse reads anchors it there (Region::addExtraRead).
        CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}},
                                   {ConstantInt::getFalse(ctx.M.getContext())});
        sub->addExtraRead(ctx.unc().recordSeed(z));
      }
      return st;
    };
    if (gc) {
      // No classical guard: S runs wherever the trip runs.
      stopped = lowerSub();
      for (PHINode *P : cBound) {
        unitPhi.erase(P);
        boundThisTrip.insert(P);
        unitBound.insert(P);
        mine.insert(P);
      }
      for (Instruction *I : outs)
        if (!isQ(I))
          perTrip.insert(I);
      return;
    }
    // The values on the skip path: a |0> seed per rail field (minted before the branch), 0 per classical one.
    LLVMContext &Cx = ctx.M.getContext();
    auto skipFields = [&](Type *ty, bool rails) {
      SmallVector<Type *, 4> leaves;
      std::function<void(Type *)> walk = [&](Type *t) {
        if (auto *st = dyn_cast<StructType>(t)) {
          for (Type *e : st->elements())
            walk(e);
        } else if (auto *a = dyn_cast<ArrayType>(t)) {
          for (uint64_t k = 0; k < a->getNumElements(); ++k)
            walk(a->getElementType());
        } else if (auto *vt = dyn_cast<FixedVectorType>(t)) {
          for (unsigned k = 0; k < vt->getNumElements(); ++k)
            leaves.push_back(vt->getElementType());
        } else {
          leaves.push_back(t);
        }
      };
      walk(ty);
      SmallVector<Operand, 4> f;
      if (!rails) {
        f.push_back(Operand{Constant::getNullValue(ty), false});
        return f;
      }
      for (Type *t : leaves) {
        RailType w = railOf(t);
        CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(Cx, w))});
        ctx.unc().recordSeed(z);
        f.push_back(Operand{z, true});
      }
      return f;
    };
    std::vector<SmallVector<Operand, 4>> skipOut, skipPhi;
    for (Instruction *I : outs)
      skipOut.push_back(skipFields(I->getType(), isQ(I)));
    for (PHINode *P : cBound)
      skipPhi.push_back(skipFields(P->getType(), isQ(P)));
    BasicBlock *Run = BasicBlock::Create(Cx, "", &ctx.out()), *Skip = BasicBlock::Create(Cx, "", &ctx.out()),
               *Join = BasicBlock::Create(Cx, "", &ctx.out());
    // Where S is skipped it took no noreturn arm.
    Value *noStop = nullptr;
    if (exits::hasNoreturnArm(S)) {
      CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}}, {ConstantInt::getFalse(Cx)});
      ctx.unc().recordSeed(z);
      noStop = z;
    }
    BranchInst *br = ctx.B().CreateCondBr(g, Run, Skip);
    if (segHook)
      segHook(Run);
    ctx.B().SetInsertPoint(Run);
    Value *subStop = lowerSub();
    BasicBlock *ran = ctx.B().GetInsertBlock();
    ctx.B().CreateBr(Join);
    BranchInst::Create(Join, Skip);
    if (segHook)
      segHook(Skip);
    // cq-lv2ba: a value classical by taint that the run path binds to a rail (a header phi of S read after S whose only
    // way on is its quantum exit: its value there is a rail) is a |0> seed per field on the skip path too. Known only
    // now, so minted where the branch leaves from; in a segment of a classically bounded loop's trip (segHook), in Skip,
    // a record of the scope its reverse undoes on the skip path only (as the classical-part branch below does).
    auto railAfterRun = [&](const Value *v, SmallVector<Operand, 4> &skip) {
      if (skip.size() != 1 || skip.front().handle)
        return;
      SmallVector<Operand, 4> run = ctx.fields(v);
      if (run.empty() || !all_of(run, [](const Operand &o) { return o.handle; }))
        return;
      IRBuilderBase::InsertPointGuard keep(ctx.B());
      if (segHook)
        ctx.B().SetInsertPoint(Skip->getTerminator());
      else
        ctx.B().SetInsertPoint(br);
      skip = skipFields(v->getType(), true);
    };
    for (size_t k = 0; k < outs.size(); ++k)
      railAfterRun(outs[k], skipOut[k]);
    for (size_t k = 0; k < cBound.size(); ++k)
      railAfterRun(cBound[k], skipPhi[k]);
    if (segHook)
      segHook(Join);
    ctx.B().SetInsertPoint(Join);
    if (subStop && noStop) {
      PHINode *ph = ctx.B().CreatePHI(subStop->getType(), 2);
      ph->addIncoming(subStop, ran);
      ph->addIncoming(noStop, Skip);
      ctx.unc().recordMerge(ph);
      stopped = ph;
    }
    auto join = [&](const Value *v, ArrayRef<Operand> skip) {
      SmallVector<Operand, 4> run = ctx.fields(v), out;
      if (run.size() != skip.size())
        internalError("loops-cutoff: a value read after a loop of a trip with fields that do not match its type", at);
      for (size_t k = 0; k < run.size(); ++k) {
        if (run[k].handle != skip[k].handle)
          internalError("loops-cutoff: a value read after a loop of a trip that is a rail on one path only", at);
        PHINode *ph = ctx.B().CreatePHI(run[k].v->getType(), 2);
        ph->addIncoming(run[k].v, ran);
        ph->addIncoming(skip[k].v, Skip);
        if (run[k].handle)
          ctx.unc().recordMerge(ph);
        out.push_back(Operand{ph, run[k].handle});
      }
      return out;
    };
    for (size_t k = 0; k < outs.size(); ++k) {
      ctx.rebind(outs[k], join(outs[k], skipOut[k]));
      if (!isQ(outs[k]))
        perTrip.insert(outs[k]);
    }
    for (size_t k = 0; k < cBound.size(); ++k) {
      SmallVector<Operand, 4> j = join(cBound[k], skipPhi[k]);
      if (j.size() != 1)
        internalError("loops-cutoff: a phi of a multi-exit loop's continuation with several fields", cBound[k]);
      unitPhi[cBound[k]] = j.front();
    }
  };
  // A noreturn arm is outside every loop around it, so an edge into one from this loop is an exit edge of each
  // enclosing K-loop too (CR rule 14: a_K reads 1 iff the loop would run another trip; rule 16). stopAcc is the XOR
  // of this activation's arm flags (at most one reads 1: a chain dies at the edge it takes), handed to the enclosing
  // trip as `stopped`, whose predicate from there on excludes it. Made only inside a K-loop.
  bool inKLoop = false;
  for (Loop *P = L.getParentLoop(); P && !inKLoop; P = P->getParentLoop())
    inKLoop = classify(*P, ctx.T, ctx.S) == Case::QuantumExit;
  Value *stopAcc = nullptr;
  bool stopCarried = false;   // cq-9kcq S11e: the rolled trip carries stopAcc in a header phi (rolledBody)
  auto noteStop = [&](Value *f) {
    if (!inKLoop)
      return;
    RailType i1{Kind::Int, 1};
    if (stopCarried) {
      // as loops-classical's noteStop: a fresh rail n = stop ^ f, the trip's new stop rail (an in-place XOR would put a
      // record of the rail minted before the header into the trip)
      CallInst *n = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(ctx.M.getContext())});
      RailId nid = ctx.unc().recordSeed(n);
      abi::CoreSpec x{abi::Core::XorI1, i1};
      CallInst *g1 = ctx.emitCore(x, {stopAcc, n});
      ctx.unc().recordCore(g1, x, {Operand{stopAcc, true}, Operand{n, true}}, nid);
      CallInst *g2 = ctx.emitCore(x, {f, n});
      ctx.unc().recordCore(g2, x, {Operand{f, true}, Operand{n, true}}, nid);
      stopAcc = n;
      return;
    }
    if (!stopAcc) {
      CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(ctx.M.getContext())});
      ctx.unc().recordSeed(z);
      stopAcc = z;
    }
    abi::CoreSpec x{abi::Core::XorI1, i1};
    CallInst *g = ctx.emitCore(x, {f, stopAcc});
    ctx.unc().recordCore(g, x, {Operand{f, true}, Operand{stopAcc, true}}, ctx.unc().idOf(stopAcc));
  };
  // q & !s for the sub-loop just lowered, when it has a noreturn arm.
  auto andNot = [&](Value *q, Value *s) {
    RailType i1{Kind::Int, 1};
    CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(ctx.M.getContext())});
    RailId id = ctx.unc().recordSeed(z);
    abi::CoreSpec no{abi::Core::NotI1, i1};
    CallInst *n = ctx.emitCore(no, {z});
    ctx.unc().recordCore(n, no, {Operand{z, true}}, id);
    abi::CoreSpec x{abi::Core::XorI1, i1};
    CallInst *g = ctx.emitCore(x, {s, z});
    ctx.unc().recordCore(g, x, {Operand{s, true}, Operand{z, true}}, id);
    return andRail(q, z);
  };
  auto afterSub = [&](Value *q) {
    if (!stopped)
      return q;
    Value *s = stopped;
    stopped = nullptr;
    noteStop(s);
    return andNot(q, s);
  };
  // A fresh rail holding the XOR of `terms` (exclusive flags: their OR).
  auto xorRail = [&](ArrayRef<Value *> terms) {
    RailType i1{Kind::Int, 1};
    CallInst *n = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(ctx.M.getContext())});
    RailId id = ctx.unc().recordSeed(n);
    abi::CoreSpec x{abi::Core::XorI1, i1};
    for (Value *t : terms) {
      CallInst *g = ctx.emitCore(x, {t, n});
      ctx.unc().recordCore(g, x, {Operand{t, true}, Operand{n, true}}, id);
    }
    return static_cast<Value *>(n);
  };
  // q & flag(E) for E the union of parts (cq-m16f6). Pairwise exclusive parts (the edges of one trip into a block): the
  // XOR of their flags, each a flag of its own small predicate; the union of many such edges can be a far larger BDD
  // than all of them together (riscv_cpu_interp_x32: 138 edges of at most 118 nodes, a union of 228k).
  // within: the parts may read atoms E does not (the edges of one trip into the exit block, whose atoms are this trip's).
  // Otherwise (a latch's incoming edges) such an atom is quantified away: its rail need not be live where E is read (ksub:
  // both sides of a quantum branch after a classical sub-loop join at the latch, the branch's condition cancelling), and
  // parts that then meet are merged.
  auto unionFlag = [&](Value *q, const Pred &E, ArrayRef<Pred> given, const Instruction *at, bool within) -> Value * {
    std::vector<Pred> parts;
    if (given.size() > 1 && !E.isTop()) {
      if (!within)
        parts = exclusiveParts(E, given);
      else if (predsExclusive(given))   // case atoms of one switch exclude each other, as their rails do
        parts.assign(given.begin(), given.end());
    }
    bool exclusive = parts.size() > 1;
    if (!exclusive)
      return conj(q, E, at);
    SmallVector<Value *, 16> terms;
    for (const Pred &p : parts)
      if (!p.isBottom())
        terms.push_back(ctx.preds().flag(ctx, p));
    return andRail(q, xorRail(terms));
  };
  // r8 (receiver above): the flags of this evaluation's edges into noreturn arms from blocks with a receiver, each
  // minted right after its block under q_j as it stood there; the arms read them (abortArms).
  DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, Value *> abortEdge;
  // cq-jws5r (CR rule 8: "A purely classical condition is always a classical branch, also inside a clone"; NORTHSTAR
  // principle 2: a branch not taken emits no gates). A part of a trip copy (a block, a sub-loop's unit) whose trip-local
  // predicate lp has a classical condition runs under a real branch on it: g is lp with its quantum atoms quantified
  // away (the classical paths of this trip that reach the part), read from this trip's classical values, and inside the
  // branch the part's predicate is lp's quantum part alone (g implies lp's classical factor), so with a purely classical
  // lp the effects sit under the trip predicate itself. The trip stays straight-line code around it, as around a
  // classically bounded sub-loop (classicalSub): each value the part binds that is read outside it is joined by a phi
  // with a |0> seed (a classical value: 0) minted before the branch, which the trip reads on a false classical edge
  // only. `phis`: phis outside the part it may bind (a sub-loop's continuation); `flags`: i1 rails the body leaves for
  // the code after it (nullptr where none), |0> on the skip path. The reverse needs no record of the branch: the
  // uncompute spine places each item of the part under its block's run flag; in a classically bounded loop's trip
  // (segHook) each block is a segment, mirrored on the path that ran it (cq-kk46l).
  auto underClassical = [&](const Pred &lp, ArrayRef<BasicBlock *> blocks, ArrayRef<PHINode *> phis,
                            ArrayRef<Value **> flags, const std::function<void(const Pred &)> &body) {
    Pred cg = lp.isBottom() ? Pred::top() : lp.classicalProjection(ctx.T, ctx.S);
    if (cg.isTop()) {
      body(lp);
      return;
    }
    LLVMContext &Cx = ctx.M.getContext();
    Value *g = classicalValue(ctx, cg);
    SmallPtrSet<const BasicBlock *, 8> in(blocks.begin(), blocks.end());
    SmallVector<Instruction *, 16> outs;
    for (BasicBlock *bb : blocks)
      for (Instruction &I : *bb) {
        if (I.getType()->isVoidTy())
          continue;
        if (any_of(I.users(), [&](const User *u) {
              auto *ui = cast<Instruction>(u);
              return ui->isTerminator() || !in.count(ui->getParent());
            }))
          outs.push_back(&I);
      }
    for (PHINode *P : phis)
      outs.push_back(P);
    auto fieldsOf = [&](const Value *v) -> std::optional<SmallVector<Operand, 4>> {
      if (!ctx.bound(v))
        return std::nullopt;
      return ctx.fields(v);
    };
    auto same = [](const std::optional<SmallVector<Operand, 4>> &a, const std::optional<SmallVector<Operand, 4>> &b) {
      if (!a || !b || a->size() != b->size())
        return !a && !b;
      for (size_t k = 0; k < a->size(); ++k)
        if ((*a)[k].v != (*b)[k].v || (*a)[k].handle != (*b)[k].handle)
          return false;
      return true;
    };
    std::vector<std::optional<SmallVector<Operand, 4>>> before;
    for (Instruction *I : outs)
      before.push_back(fieldsOf(I));
    // cq-bxikv: the rails the part's outputs are computed from that are bound before the branch (its operands outside the
    // part, through the part's own instructions). A part that updates one of them in place (a cq_theta of a carried
    // register) binds its output to that rail: the rail is live on both paths, so its join is that rail itself, not a phi
    // with a fresh |0> seed (which made the carried register look like a new value each trip and copied it per trip).
    SmallPtrSet<const Value *, 8> priorRails;
    {
      SmallPtrSet<const Value *, 16> seen;
      SmallVector<const Value *, 16> work(outs.begin(), outs.end());
      while (!work.empty()) {
        const Value *v = work.pop_back_val();
        if (!seen.insert(v).second)
          continue;
        auto *I = dyn_cast<Instruction>(v);
        if (I && in.count(I->getParent())) {
          for (const Use &U : I->operands())
            work.push_back(U.get());
          continue;
        }
        if (isa<Constant>(v) || isa<BasicBlock>(v) || isa<MetadataAsValue>(v))
          continue;
        if (auto f = fieldsOf(v))
          for (const Operand &o : *f)
            if (o.handle)
              priorRails.insert(o.v);
      }
    }
    BasicBlock *Run = BasicBlock::Create(Cx, "", &ctx.out()), *Skip = BasicBlock::Create(Cx, "", &ctx.out()),
               *Join = BasicBlock::Create(Cx, "", &ctx.out());
    // The branch first: the uncompute spine reads the output CFG where the part is lowered (a store a classical branch can
    // bypass keeps its rails only where it ran, rule 5).
    BranchInst *br = ctx.B().CreateCondBr(g, Run, Skip);
    BranchInst::Create(Join, Skip);
    ctx.unc().noteClassicalArm(Join, Skip);
    if (segHook)
      segHook(Run);
    ctx.B().SetInsertPoint(Run);
    {
      // A classical reachability value made inside the branch does not reach the code after it: forgotten again.
      DenseMap<const BasicBlock *, Value *> reachBefore = creach;
      body(lp.quantumPart(ctx.T, ctx.S));
      creach = std::move(reachBefore);
    }
    BasicBlock *ran = ctx.B().GetInsertBlock();
    ctx.B().CreateBr(Join);
    // The skip path's values, minted where the branch leaves from; in a segment of a classically bounded loop's trip
    // (segHook), in Skip: a record of the scope its reverse undoes on the skip path only.
    if (segHook) {
      segHook(Skip);
      ctx.B().SetInsertPoint(Skip->getTerminator());
    } else {
      ctx.B().SetInsertPoint(br);
    }
    auto zero = [&](RailType w) -> Value * {
      CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(Cx, w))});
      ctx.unc().recordSeed(z);
      return z;
    };
    struct J {
      Instruction *I;
      SmallVector<Operand, 4> run, skip;
    };
    std::vector<J> joins;
    for (size_t k = 0; k < outs.size(); ++k) {
      auto now = fieldsOf(outs[k]);
      if (!now || same(before[k], now))
        continue;
      SmallVector<Type *, 4> leaves;
      std::function<void(Type *)> walk = [&](Type *t) {
        if (auto *st = dyn_cast<StructType>(t)) {
          for (Type *e : st->elements())
            walk(e);
        } else if (auto *a = dyn_cast<ArrayType>(t)) {
          for (uint64_t n = 0; n < a->getNumElements(); ++n)
            walk(a->getElementType());
        } else if (auto *vt = dyn_cast<FixedVectorType>(t)) {
          for (unsigned n = 0; n < vt->getNumElements(); ++n)
            leaves.push_back(vt->getElementType());
        } else {
          leaves.push_back(t);
        }
      };
      walk(outs[k]->getType());
      J j{outs[k], *now, {}};
      bool ok = true;
      for (size_t f = 0; f < now->size() && ok; ++f) {
        const Operand &r = (*now)[f];
        if (!r.handle)
          j.skip.push_back(Operand{Constant::getNullValue(r.v->getType()), false});
        else if (priorRails.count(r.v))
          j.skip.push_back(r);   // cq-bxikv: the same rail on both paths
        else if (now->size() == leaves.size())
          j.skip.push_back(Operand{zero(railOf(leaves[f])), true});
        else if (now->size() == 1 && (outs[k]->getType()->isIntegerTy() || outs[k]->getType()->isFloatingPointTy() ||
                                      outs[k]->getType()->isPointerTy()))
          j.skip.push_back(Operand{zero(railOf(outs[k]->getType())), true});
        else
          ok = false;
      }
      if (ok)
        joins.push_back(std::move(j));
    }
    SmallVector<Value *, 2> flagSkip;
    for (Value **f : flags)
      flagSkip.push_back(*f ? zero(RailType{Kind::Int, 1}) : nullptr);
    if (segHook)
      segHook(Join);
    ctx.B().SetInsertPoint(Join);
    auto phiOf = [&](Value *run, Value *skip, bool rail) -> Value * {
      if (rail && run == skip)
        return run;   // cq-bxikv: one rail on both paths is that rail
      PHINode *ph = ctx.B().CreatePHI(run->getType(), 2);
      ph->addIncoming(run, ran);
      ph->addIncoming(skip, Skip);
      if (rail && ctx.unc().recorded(run) && ctx.unc().recorded(skip))
        ctx.unc().recordMerge(ph);
      return ph;
    };
    std::vector<SmallVector<Operand, 4>> joined;
    for (J &j : joins) {
      SmallVector<Operand, 4> out;
      for (size_t f = 0; f < j.run.size(); ++f)
        out.push_back(Operand{phiOf(j.run[f].v, j.skip[f].v, j.run[f].handle), j.run[f].handle});
      joined.push_back(std::move(out));
    }
    for (size_t k = 0; k < flags.size(); ++k)
      if (flagSkip[k])
        *flags[k] = phiOf(*flags[k], flagSkip[k], true);
    for (size_t k = 0; k < joins.size(); ++k) {
      ctx.rebind(joins[k].I, joined[k]);
      if (!isQ(joins[k].I))
        perTrip.insert(joins[k].I);
    }
  };
  std::function<void(BasicBlock *, Value *, const Pred &)> lowerInsts;   // one block's non-phi instructions
  auto lowerBlocks = [&](Value *&q, const std::function<bool(const BasicBlock *)> &pick) {
    boundThisTrip.clear();
    abortEdge.clear();
    for (BasicBlock *b : order) {
      if (!pick(b))
        continue;
      if (b == H) {
        creach.clear();
        evaluated.clear();
      }
      evaluated.insert(b);
      if (Loop *S = subLoopOf(b)) {
        if (S->getHeader() != b)
          continue;
        Loop *mS = A.LI.getLoopFor(b);
        if (classify(*mS, ctx.T, ctx.S) != Case::QuantumExit) {
          classicalSub(*mS, q, local.find(b)->second, b->getTerminator());
          q = afterSub(q);
          continue;
        }
        unsigned K = ctx.K(S);
        std::optional<uint64_t> B = exits::cutoffBound(*mS, A.SE, ctx.S);
        unsigned cs = B ? unsigned(std::min<uint64_t>(K, *B)) : K;
        exits::Unit SU = exits::unitOf(*mS);
        SmallVector<BasicBlock *, 16> unitBlocks(mS->blocks().begin(), mS->blocks().end());
        unitBlocks.append(SU.arm.begin(), SU.arm.end());
        SmallVector<PHINode *, 4> contPhis;
        if (SU.cont)
          for (PHINode &P : SU.cont->phis())
            contPhis.push_back(&P);
        const Pred &lpS = local.find(b)->second;
        // cq-jws5r: behind a classical condition of the trip the sub-loop is skipped by a real branch. Its continuation's
        // phis are then the unit's value only where it ran: the trip's merge selects it in on the unit's edges (unitPhi,
        // as for a classically bounded sub-loop) over the phi's other incomings.
        bool branched = !lpS.isBottom() && !lpS.classicalProjection(ctx.T, ctx.S).isTop() && SU.cont &&
                        L.contains(SU.cont);
        stopped = nullptr;
        underClassical(branched ? lpS : Pred::top(), unitBlocks, contPhis, {&stopped}, [&](const Pred &lp) {
          Value *s = conj(q, branched ? lp : lpS, b->getTerminator());
          // The sub-loop binds the phis of its exit block it identifies; they are not merged again.
          forgetUnitBound(SU.cont);
          lowerLoop(*mS, s, cs, !B || *B > K, false);
        });
        q = afterSub(q);
        for (PHINode *P : contPhis)
          if (unitBound.count(P)) {
            if (branched) {
              unitPhi[P] = ctx.operand(P);
              unitBound.erase(P);
            } else {
              unitPhi.erase(P);
              boundThisTrip.insert(P);
            }
          }
        continue;
      }
      // cq-jws5r: a block behind a classical condition of the trip runs under a real branch on it (rule 8).
      underClassical(local.find(b)->second, {b}, {}, {}, [&](const Pred &lpb) {
      if (b != H)
        for (PHINode &P : b->phis()) {
          if (boundThisTrip.count(&P)) {
            // cq-t30vh: the sub-unit bound P on its own paths; its tail's edges into its continuation hold on the others.
            std::vector<std::pair<Pred, Operand>> tailArms;
            Pred E = Pred::bottom();
            for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
              BasicBlock *u = P.getIncomingBlock(i);
              if (!subTail.count(u) || subLoopOf(u))
                continue;
              Pred e = contribution(u, b);
              if (e.isBottom())
                continue;
              E = E | e;
              tailArms.push_back({e, ctx.operand(P.getIncomingValue(i))});
            }
            if (!tailArms.empty()) {
              for (auto &[e, v] : ctx.takeJoinArms(&P))
                if (none_of(P.blocks(), [&, v = v](const BasicBlock *u) {
                      return subTail.count(u) && P.getIncomingValueForBlock(u) == v;
                    }))
                  ctx.addJoinArm(&P, e, v);
              tailArms.push_back({!E, ctx.operand(&P)});
              set(&P, Operand{selectChain(ctx, tailArms, railOf(P.getType())), true});
            }
            continue;
          }
          if (!isQ(&P)) {
            classicalPhi(P);
            continue;
          }
          if (!classicalTerms && !subTail.count(b)) {
            if (P.getType()->isAggregateType() || P.getType()->isVectorTy()) {
              // cq-pfpy: a composite merges field by field (rule 26), bound or rebound per trip.
              bool first = mine.insert(&P).second;
              lowerMergeFields(ctx, P, /*rebind=*/!first);
            } else {
              set(&P, Operand{lowerMerge(ctx, P), true});
            }
            continue;
          }
          // A trip with a classical branch or switch has no output blocks to join classically (it is
          // straight-line code): the merge is rule 9's select chain over the trip-local edge
          // predicates, a classical term of them a seed rail (rule 8), or, where the choice is purely
          // classical, a classical select over the handles (mergeArms, cq-o5tjh).
          std::vector<std::pair<Pred, Operand>> arms;
          auto up = unitPhi.find(&P);
          bool unitArm = false;
          for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
            BasicBlock *u = P.getIncomingBlock(i);
            Pred e = contribution(u, b);
            if (e.isBottom())
              continue;
            if (up != unitPhi.end() && subLoopOf(u) && !subLoopOf(u)->contains(b)) {
              // the classically bounded sub-loop's own value of P where it ran (cq-h5uj)
              if (!unitArm)
                arms.push_back({e, up->second});
              unitArm = true;
              continue;
            }
            arms.push_back({e, ctx.operand(P.getIncomingValue(i))});
          }
          set(&P, Operand{mergeArms(arms, P.getType()), true});
        }
      lowerInsts(b, q, lpb);
      });
      // r8: b's edges into noreturn arms leave the trip here (receiver). Also where they restrict b's live successors: in
      // the region form the next header test reads q_j and the region's predicates only (asrt5: a classical assert of
      // the body went on to the next trip).
      if (narrows(b)) {
        SmallVector<Value *, 2> taken;
        SmallPtrSet<BasicBlock *, 4> seen;
        for (BasicBlock *a : successors(b)) {
          if (!is_contained(U.abort, a) || !seen.insert(a).second)
            continue;
          Pred e = local.find(b)->second & edgeCond(b, a);
          if (e.isBottom())
            continue;
          Value *f = nullptr;
          underClassical(e, {}, {}, {&f}, [&](const Pred &lp) {
            f = conj(q, lp, b->getTerminator());
            if (f == q)
              f = xorRail({q});   // a rail of its own: q goes on narrowed
          });
          abortEdge[{b, a}] = f;
          taken.push_back(f);
        }
        if (!taken.empty())
          q = andNot(q, taken.size() == 1 ? taken.front() : xorRail(taken));
      }
    }
  };
  // A loop of the exit arm runs once in the C program (after the trip that exits into the arm), but once per
  // trip here, under that trip's arm flag: its a_K is the one of the trip whose arm ran, the XOR of the
  // per-trip chain ends (at most one arm flag is 1). Kept as one rail (CR rule 14: a_K is kept when B > K).
  Value *armKept = nullptr;
  // The exit arm and C's phis after one evaluation of the blocks `pick` chose (multi-exit form).
  auto capture = [&](Value *q, const std::function<bool(const BasicBlock *)> &pick) {
    armPick = &pick;
    DenseMap<const BasicBlock *, Pred> armLocal;
    auto srcPred = [&](const BasicBlock *u) -> std::optional<Pred> {
      if (L.contains(u)) {
        if (!pick(u) || subLoopOf(u))
          return std::nullopt;
        return local.find(u)->second;
      }
      auto it = armLocal.find(u);
      if (it == armLocal.end())
        return std::nullopt;
      return it->second;
    };
    // The condition of the edge u -> b in this evaluation. A loop of the arm (cq-0dvv) is a unit inside
    // the arm, like a sub-loop of a trip: it always ends at its continuation, so the edge out of it is
    // taken where its header ran; an edge into its noreturn arm or a dead end is its own (its trips).
    // Rule 14: the exit arm of a multi-exit K-loop of this arm is that loop's: it runs in that loop's own trips, where the
    // loop's values are that trip's (musl wcsrtombs' `N-n` on the second loop's exit). Run once more here it would read
    // them after the loop's last trip.
    auto nestedArmOwner = [&](const BasicBlock *x) -> Loop * {
      for (BasicBlock *h : U.arm)
        if (Loop *S = subLoopOf(h); S && S->getHeader() == h && !S->contains(x) &&
                                    (classify(*S, ctx.T, ctx.S) == Case::QuantumExit ||
                                     classify(*S, ctx.T, ctx.S) == Case::ClassicalBoundQuantumExit) &&
                                    is_contained(exits::unitOf(*S).arm, x))
          return S;
      return nullptr;
    };
    // cq-quhmu (rules 9, 14, as cq-t30vh for a sub-loop of the trip): the TAIL of such a loop's unit (Exits.h) is that loop's on its
    // own paths only. On the paths that enter it from this evaluation (an exit of the trip into a block that a loop of the arm also
    // exits into: printf_core's `inval`, reached from the format scan and from the nl_type scan after it) it is a block of this
    // evaluation like any other, under their predicate, its edges into the continuation selected in over that loop's binding. The
    // loop leaves those paths to the walker (addJoinArm), which would read the predicate after the K-loop's last trip.
    auto nestedTailOwner = [&](const BasicBlock *x) -> Loop * {
      Loop *S = nestedArmOwner(x);
      return S && !subLoopOf(x) && is_contained(exits::unitOf(*S).tail, x) ? S : nullptr;
    };
    // The walker's arms S left for its tail's outside paths (the loops modules' addJoinArm): those paths are this evaluation's.
    auto reclaimTail = [&](Loop &S) {
      const Case sc = classify(S, ctx.T, ctx.S);
      if (sc != Case::QuantumExit && sc != Case::ClassicalBoundQuantumExit)
        return;
      exits::Unit SU = exits::unitOf(S);
      if (!SU.cont)
        return;
      auto ours = [&](const BasicBlock *u) {
        return is_contained(SU.tail, u) && is_contained(U.arm, u) && !is_contained(U.tail, u);
      };
      for (PHINode &P : SU.cont->phis())
        for (auto &[e, v] : ctx.takeJoinArms(&P))
          if (none_of(P.blocks(), [&, v = v](const BasicBlock *u) { return ours(u) && P.getIncomingValueForBlock(u) == v; }))
            ctx.addJoinArm(&P, e, v);
    };
    auto edgeIn = [&](const BasicBlock *u, const BasicBlock *b) -> std::optional<Pred> {
      if (!L.contains(u) && !nestedTailOwner(u))
        if (Loop *S = subLoopOf(u) ? subLoopOf(u) : nestedArmOwner(u)) {
          if (S->contains(b) || nestedArmOwner(b) == S)
            return std::nullopt;
          auto it = armLocal.find(S->getHeader());
          if (it == armLocal.end())
            return std::nullopt;
          exits::Unit SU = exits::unitOf(*S);
          if (is_contained(SU.abort, b) || is_contained(SU.dead, b))
            return std::nullopt;
          if (SU.cont != b)
            unimplemented("loops-cutoff: a loop of a K-loop's exit arm with more than one live exit block "
                          "(nested general forms, cq-lgkx)",
                          u->getTerminator());
          return it->second;
        }
      auto sp = srcPred(u);
      if (!sp)
        return std::nullopt;
      return *sp & edgeCond(const_cast<BasicBlock *>(u), const_cast<BasicBlock *>(b));
    };
    DenseSet<const PHINode *> armBound;   // exit phis a loop of the arm bound
    for (BasicBlock *b : U.arm) {
      Loop *S = subLoopOf(b);
      if (S && S->getHeader() != b)
        continue;   // inside a loop of the arm: lowered with it
      if (nestedArmOwner(b) && !nestedTailOwner(b))
        continue;
      Pred acc = Pred::bottom();
      for (BasicBlock *p : predecessors(b)) {
        if (S && S->contains(p))
          continue;   // the back edge of the arm loop
        if (auto e = edgeIn(p, b))
          acc = acc | *e;
      }
      if (acc.isBottom())
        continue;   // not reached from the blocks of this evaluation
      armLocal.insert({b, acc});
      evaluated.insert(b);
      creach.erase(b);
      if (S) {
        // A loop of the arm: rule 14 inside this trip's arm, seeded by the arm's flag (nested K-loops), or a
        // classically bounded loop of the arm under that flag (cq-h5uj).
        forgetUnitBound(exits::unitOf(*S).cont);
        if (classify(*S, ctx.T, ctx.S) != Case::QuantumExit) {
          classicalSub(*S, q, acc, b->getTerminator());
          if (stopped) {
            noteStop(stopped);
            stopped = nullptr;
          }
          reclaimTail(*S);
          if (BasicBlock *SX = exits::unitOf(*S).cont)
            for (PHINode &P : SX->phis())
              if (unitBound.count(&P))
                armBound.insert(&P);
          continue;
        }
        unsigned K = ctx.K(S);
        std::optional<uint64_t> Bs = exits::cutoffBound(*S, A.SE, ctx.S);
        unsigned cs = Bs ? unsigned(std::min<uint64_t>(K, *Bs)) : K;
        // cq-o5tjh (rule 8, as for a sub-loop of the trip, cq-jws5r): behind a classical condition of this evaluation
        // the loop of the arm is skipped by a real branch, its chain seeded by the quantum part of the arm's predicate
        // alone. What it leaves for the code after it (its continuation's phis, its stop rail and chain end) reads |0>
        // where it was skipped, where every predicate that selects it is false.
        exits::Unit SU = exits::unitOf(*S);
        bool branched = !acc.classicalProjection(ctx.T, ctx.S).isTop() && SU.cont;
        SmallVector<BasicBlock *, 16> unitBlocks(S->blocks().begin(), S->blocks().end());
        unitBlocks.append(SU.arm.begin(), SU.arm.end());
        SmallVector<PHINode *, 4> contPhis;
        if (branched)
          for (PHINode &P : SU.cont->phis())
            contPhis.push_back(&P);
        stopped = nullptr;
        underClassical(branched ? acc : Pred::top(), unitBlocks, contPhis, {&stopped, &chainEnd}, [&](const Pred &lp) {
          lowerLoop(*S, conj(q, branched ? lp : acc, b->getTerminator()), cs, false, false);
        });
        if (stopped) {
          noteStop(stopped);
          stopped = nullptr;
        }
        reclaimTail(*S);
        if (!Bs || *Bs > K) {
          RailType i1{Kind::Int, 1};
          if (!armKept) {
            CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(ctx.M.getContext())});
            ctx.unc().recordSeed(z);
            armKept = z;
          }
          abi::CoreSpec x{abi::Core::XorI1, i1};
          CallInst *g = ctx.emitCore(x, {chainEnd, armKept});
          ctx.unc().recordCore(g, x, {Operand{chainEnd, true}, Operand{armKept, true}}, ctx.unc().idOf(armKept));
        }
        if (BasicBlock *SX = exits::unitOf(*S).cont)
          for (PHINode &P : SX->phis())
            if (unitBound.count(&P))
              armBound.insert(&P);
        continue;
      }
      underClassical(acc, {b}, {}, {}, [&](const Pred &lpb) {   // cq-jws5r
      for (PHINode &P : b->phis()) {
        if (armBound.count(&P)) {
          // cq-quhmu: the loop bound P on its own paths; its tail's edges into its continuation hold on this evaluation's.
          std::vector<std::pair<Pred, Operand>> tailArms;
          Pred E = Pred::bottom();
          for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
            BasicBlock *u = P.getIncomingBlock(i);
            if (!nestedTailOwner(u))
              continue;
            auto e = edgeIn(u, b);
            if (!e || e->isBottom())
              continue;
            E = E | *e;
            tailArms.push_back({*e, ctx.operand(P.getIncomingValue(i))});
          }
          // Rule 9: P's edges from this evaluation's own arm blocks around the loop (pe_arm: a classical branch of the arm
          // skips it) hold where they are taken; the loop's binding is P's value only on the loop's edges, under the
          // predicate of reaching its header.
          std::vector<std::pair<Pred, Operand>> outArms;
          Loop *own = nullptr;
          for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
            BasicBlock *u = P.getIncomingBlock(i);
            if (nestedTailOwner(u))
              continue;
            Loop *S = L.contains(u) ? nullptr : (subLoopOf(u) ? subLoopOf(u) : nestedArmOwner(u));
            if (S && !S->contains(b)) {
              own = S;
              continue;
            }
            auto e = edgeIn(u, b);
            if (!e || e->isBottom())
              continue;
            outArms.push_back({*e, ctx.operand(P.getIncomingValue(i))});
          }
          if (own && !outArms.empty()) {
            auto it = armLocal.find(own->getHeader());
            if (it == armLocal.end())
              internalError("loops-cutoff: a loop of the arm bound a phi it was not lowered for", &P);
            outArms.insert(outArms.end(), tailArms.begin(), tailArms.end());
            outArms.push_back({it->second, ctx.operand(&P)});
            set(&P, Operand{mergeArms(outArms, P.getType()), true});
          } else if (!tailArms.empty()) {
            tailArms.push_back({!E, ctx.operand(&P)});
            set(&P, Operand{selectChain(ctx, tailArms, railOf(P.getType())), true});
          }
          continue;
        }
        if (!isQ(&P)) {
          classicalPhi(P);
          continue;
        }
        std::vector<std::pair<Pred, Operand>> arms;
        auto up = unitPhi.find(&P);
        bool unitArm = false;
        for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
          BasicBlock *u = P.getIncomingBlock(i);
          auto e = edgeIn(u, b);
          if (!e)
            continue;
          if (up != unitPhi.end() && !L.contains(u) && subLoopOf(u) && !subLoopOf(u)->contains(b)) {
            if (!unitArm)
              arms.push_back({*e, up->second});   // a classically bounded loop of the arm (cq-h5uj)
            unitArm = true;
            continue;
          }
          arms.push_back({*e, ctx.operand(P.getIncomingValue(i))});
        }
        set(&P, Operand{mergeArms(arms, P.getType()), true});
      }
      lowerInsts(b, q, lpb);
      });
    }
    // cq-m16f6: q & E per key of E's parts, shared by the phis whose E is made of the same parts.
    std::map<std::vector<std::pair<const BasicBlock *, bool>>, Value *> exitFlags;
    for (CPhi &cp : cphis) {
      std::vector<std::pair<Pred, Operand>> arms;
      Pred E = Pred::bottom();
      std::vector<Pred> parts;   // E is their union
      std::vector<std::pair<const BasicBlock *, bool>> key;   // each part: an edge from u, or the arm of loop header u
      auto addPart = [&](const Pred &p, std::pair<const BasicBlock *, bool> k) {
        if (is_contained(key, k))
          return;   // a phi lists a block once per edge (a switch's cases into one block): one part
        parts.push_back(p);
        key.push_back(k);
      };
      int nestedArm = -1;
      for (unsigned i = 0; i < cp.P->getNumIncomingValues(); ++i) {
        BasicBlock *u = cp.P->getIncomingBlock(i);
        // cq-quhmu: a tail block's edge holds on this evaluation's paths into the tail (its own arm, below); the loop's paths
        // through it are the loop's, the nested arm under the predicate of reaching its header.
        if (Loop *S = nestedTailOwner(u); S && armBound.count(cp.P))
          if (auto it = armLocal.find(S->getHeader()); it != armLocal.end() && !it->second.isBottom()) {
            E = E | it->second;
            addPart(it->second, {S->getHeader(), true});
            if (nestedArm < 0) {
              nestedArm = int(arms.size());
              arms.push_back({it->second, ctx.operand(cp.P)});
            } else {
              arms[nestedArm].first = arms[nestedArm].first | it->second;
            }
          }
        auto ei = edgeIn(u, U.cont);
        if (!ei)
          continue;
        Pred e = *ei;
        if (e.isBottom())
          continue;
        E = E | e;
        addPart(e, {u, false});
        // Rule 14: a K-loop of the arm exits into C too and bound P over all its exit edges this evaluation: one
        // arm, under the predicate of reaching its header, whichever of its exit edges was taken.
        if (!L.contains(u) && (subLoopOf(u) || (nestedArmOwner(u) && !nestedTailOwner(u))) && armBound.count(cp.P)) {
          if (nestedArm < 0) {
            nestedArm = int(arms.size());
            arms.push_back({e, ctx.operand(cp.P)});
          } else {
            arms[nestedArm].first = arms[nestedArm].first | e;
          }
          continue;
        }
        arms.push_back({e, ctx.operand(cp.P->getIncomingValue(i))});
      }
      if (arms.empty())
        continue;
      RailType w = railOf(cp.P->getType());
      Value *v = selectChain(ctx, arms, w);
      Value *&f = exitFlags[key];
      if (!f)
        f = unionFlag(q, E, parts, U.cont->getFirstNonPHI(), true);
      abi::TemplateSpec sel;
      sel.op = "select";
      sel.w = w;
      cp.acc = Operand{ctx.emitTemplate(sel, {Operand{f, true}, Operand{v, true}, cp.acc}), true};
    }
    for (XAcc &xa : xaccs) {
      // X_v: this evaluation's exits that pass v's definition. A loop value: the exit edges out of the
      // loop from blocks its block dominates. An arm value: its block reached in this evaluation.
      const BasicBlock *vb = xa.V->getParent();
      Pred X = Pred::bottom();
      if (L.contains(vb)) {
        for (BasicBlock *u : L.blocks()) {
          auto sp = srcPred(u);
          if (!sp || !A.DT.dominates(vb, u))
            continue;
          for (BasicBlock *sx : successors(u))
            if (liveEdge(sx))
              X = X | (*sp & edgeCond(u, sx));
        }
      } else {
        // A value of a loop of the arm is read after it as that loop's exit value (the nested unit
        // rebinds it): it is defined where the loop's header ran.
        const BasicBlock *at = vb;
        if (Loop *S = subLoopOf(vb))
          at = S->getHeader();
        if (auto it = armLocal.find(at); it != armLocal.end())
          X = it->second;
      }
      if (X.isBottom())
        continue;
      Value *f = conj(q, X, U.cont->getFirstNonPHI());
      SmallVector<Operand, 4> vs = tripFields(xa);
      for (unsigned k = 0; k < xa.acc.size() && k < vs.size(); ++k) {
        abi::TemplateSpec sel;
        sel.op = "select";
        sel.w = xa.rails[k];
        sel.shape = vs[k].handle ? "" : "lh";
        xa.acc[k] = Operand{ctx.emitTemplate(sel, {Operand{f, true}, vs[k], xa.acc[k]}), true};
      }
    }
    armPick = nullptr;
  };
  // The noreturn arms (CR rule 14 "No live exit", rule 16): each exit edge into one is taken in this
  // evaluation under q & its block's trip-local predicate & its condition; the arm's blocks run under
  // that flag (rule 9 inside the arm), its noreturn call is rule 16's abort_i1 on it. An exit from a
  // sub-loop's block is the sub-loop's own (its trips lower its arm).
  auto abortArms = [&](Value *q, const std::function<bool(const BasicBlock *)> &pick) {
    DenseMap<const BasicBlock *, Pred> abortLocal;
    DenseMap<const BasicBlock *, Value *> armFlag;   // each arm block's flag in this evaluation
    DenseSet<const BasicBlock *> armByEdges;
    auto srcPred = [&](const BasicBlock *u) -> std::optional<Pred> {
      if (L.contains(u)) {
        if (!pick(u) || subLoopOf(u))
          return std::nullopt;
        return local.find(u)->second;
      }
      auto it = abortLocal.find(u);
      if (it == abortLocal.end())
        return std::nullopt;
      return it->second;
    };
    for (BasicBlock *b : U.abort) {
      Pred acc = Pred::bottom();
      for (BasicBlock *p : predecessors(b))
        if (auto sp = srcPred(p))
          acc = acc | (*sp & edgeCond(p, b));
      if (acc.isBottom())
        continue;
      abortLocal.insert({b, acc});
      evaluated.insert(b);
      creach.erase(b);
      // cq-3630b (as 06ba00c1 for lowerInsts): the arm's flag f is exactly where this evaluation reaches b, so it implies
      // b's own predicate, which may read an atom of a trip path this evaluation did not take (TinyCC rt_exit).
      Pred own = ctx.preds().block(b).quantumPart(ctx.T, ctx.S);
      // cq-jws5r: an arm behind a classical condition of the trip is entered by a real branch (rule 8); its flag reads
      // |0> where the branch skips it.
      Value *f = nullptr;
      BasicBlock *before = ctx.B().GetInsertBlock();
      // r8 (receiver): an arm entered on an edge whose flag lowerBlocks minted (q_j narrowed after it) runs under the XOR of
      // its in-edges' flags (one path takes one edge), each edge's own: that flag, q_j & a restricted block's predicate & the
      // edge, or an earlier arm block's flag & the edge. Its phis select on them. acc (over the unrestricted predicates)
      // only gives the classical paths into the arm (a real branch, rule 8).
      bool viaEdges = any_of(predecessors(b), [&](BasicBlock *p) {
        return L.contains(p) ? pick(p) && !subLoopOf(p) && narrows(p) : armByEdges.count(p) != 0;
      });
      if (viaEdges) {
        armByEdges.insert(b);
        underClassical(acc, {b}, {}, {&f}, [&](const Pred &) {
          DenseMap<const BasicBlock *, Value *> in;
          SmallVector<Value *, 4> terms;
          for (BasicBlock *p : predecessors(b)) {
            if (in.count(p))
              continue;
            Value *t = nullptr;
            if (L.contains(p)) {
              if (!pick(p) || subLoopOf(p))
                continue;
              if (narrows(p)) {
                t = abortEdge.lookup({p, b});
              } else if (Pred e = local.find(p)->second & edgeCond(p, b); !e.isBottom()) {
                t = conj(q, e, p->getTerminator());
              }
            } else if (Value *Fp = armFlag.lookup(p)) {
              if (Pred e = edgeCond(p, b); !e.isBottom())
                t = conj(Fp, e, p->getTerminator());
            }
            if (!t)
              continue;
            in[p] = t;
            terms.push_back(t);
          }
          for (PHINode &P : b->phis()) {
            if (!isQ(&P)) {
              classicalPhi(P);
              continue;
            }
            std::vector<std::pair<Value *, Operand>> arms;
            for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
              if (Value *t = in.lookup(P.getIncomingBlock(i)))
                arms.push_back({t, ctx.operand(P.getIncomingValue(i))});
            if (arms.empty())
              internalError("loops-cutoff: a phi of a noreturn arm with no incoming in this evaluation", &P);
            RailType w = railOf(P.getType());
            auto asRail = [&](Operand v) {
              if (v.handle)
                return v;
              bool ptr = v.v->getType()->isPointerTy();
              return Operand{seedRail(ptr ? ctx.B().CreatePtrToInt(v.v, ctx.B().getInt64Ty()) : v.v,
                                      ptr ? ctx.B().getInt64Ty() : P.getType()),
                             true};
            };
            Operand r = asRail(arms.back().second);
            for (size_t k = arms.size() - 1; k-- > 0;) {
              Operand v = arms[k].second;
              if (v.v == r.v)
                continue;
              if (!v.handle && v.v->getType()->isPointerTy())
                v = Operand{ctx.B().CreatePtrToInt(v.v, ctx.B().getInt64Ty()), false};
              abi::TemplateSpec sel;
              sel.op = "select";
              sel.w = w;
              sel.shape = v.handle ? "" : "lh";
              r = Operand{ctx.emitTemplate(sel, {Operand{arms[k].first, true}, v, r}), true};
            }
            set(&P, r);
          }
          f = xorRail(terms);
          for (Instruction &I : *b)
            if (!isa<PHINode>(I) && !I.isTerminator())
              lowerInstruction(ctx, I, f, &own);
        });
        armFlag[b] = f;
        if (none_of(predecessors(b), [&](BasicBlock *p) { return abortLocal.count(p) != 0; }))
          noteStop(f);
        continue;
      }
      underClassical(acc, {b}, {}, {&f}, [&](const Pred &lpb) {
      for (PHINode &P : b->phis()) {
        if (!isQ(&P)) {
          classicalPhi(P);
          continue;
        }
        std::vector<std::pair<Pred, Operand>> arms;
        for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
          if (auto sp = srcPred(P.getIncomingBlock(i)))
            arms.push_back({*sp & edgeCond(P.getIncomingBlock(i), b), ctx.operand(P.getIncomingValue(i))});
        set(&P, Operand{mergeArms(arms, P.getType()), true});
      }
      // Every instruction of the arm runs only where the arm is taken: under the flag.
      f = conj(q, lpb, b->getTerminator());
      if (f == q && ctx.B().GetInsertBlock() != before) {
        // Rule 16 keeps the arm's flag (abort_i1 never frees it). Behind the branch the flag is the trip predicate itself,
        // which the paths that skip the arm still uncompute: the kept flag is a copy made where the arm runs (as the
        // no-live-exit form's copy of the seed, 45).
        RailType i1{Kind::Int, 1};
        CallInst *k = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(ctx.M.getContext())});
        RailId kid = ctx.unc().recordSeed(k);
        abi::CoreSpec cp{abi::Core::Copy, i1};
        CallInst *cpy = ctx.emitCore(cp, {q, k});
        ctx.unc().recordCore(cpy, cp, {Operand{q, true}, Operand{k, true}}, kid);
        f = k;
      }
      for (Instruction &I : *b)
        if (!isa<PHINode>(I) && !I.isTerminator())
          lowerInstruction(ctx, I, f, &own);
      });
      armFlag[b] = f;
      // An arm's later block is entered from its earlier ones: the flag of its entry is noted once.
      if (none_of(predecessors(b), [&](BasicBlock *p) { return abortLocal.count(p) != 0; }))
        noteStop(f);
    }
  };
  lowerInsts = [&](BasicBlock *b, Value *q, const Pred &lp) {
    {
      Value *tripFlag = nullptr;   // q & the block's trip-local predicate, made on first need
      for (Instruction &I : *b) {
        if (isa<PHINode>(I) || I.isTerminator())
          continue;
        // Rule 14 case 2: an instruction with effects (a call, a bus access, an allocation, a phase) runs in
        // trip j only where the trip runs, so it is lowered under the trip predicate (cq-99f7's
        // tripFlag: the spine conjoins the block's own quantum predicate). A pure instruction
        // is computed in every trip; its value only reaches state through the select on q. A bus load is an
        // access (rule 14): a trip C would not run touches no cell and no host byte. Under q & the block's trip
        // predicate, which for a load an exit test reads is the predicate of reaching that test, and the load's
        // _unc takes the same rail.
        bool effects = isa<CallBase>(I) || I.mayHaveSideEffects() || I.mayWriteToMemory() ||
                       (isa<LoadInst>(I) && !bus::hostAccess(ctx, I));
        if (auto *II = dyn_cast<IntrinsicInst>(&I); II && (II->isLifetimeStartOrEnd() || isa<DbgInfoIntrinsic>(II)))
          effects = false;
        if (!effects) {
          bool varies = !isQ(&I) && any_of(I.operands(), [&](const Use &U) { return perTrip.count(U.get()); });
          // cq-nzlq: a classical division computed in a trip the C program may not run gets a safe
          // divisor (the spine's copyClassical guards every non-speculatable copy in a K-loop trip).
          // cq-s7c4: a quantum i1 the trip's branches read is one atom of the trip predicates here
          // (edgeCond), so it is computed whole even where pred factored its condition (`stop || q`).
          bool tripAtom = I.getType()->isIntegerTy(1) && isQ(&I) && any_of(I.users(), [&](const User *u) {
                            auto *br = dyn_cast<BranchInst>(u);
                            // an arm's edge conditions too; a factored one (cq-kbygn) is read through its leaves
                            return br && br->isConditional() && br->getCondition() == &I &&
                                   U.contains(L, br->getParent()) && readWhole(br);
                          });
          if (tripAtom)
            lowerConditionAsData(ctx, I);
          else
            lowerInstruction(ctx, I);
          // Rule 14: a value of a trip C may not run is arithmetic without inbounds, nuw or nsw (an address past the
          // object is a value like any other, rule 21), whatever it was computed from.
          bool gep = isa<GetElementPtrInst>(I) && !isQ(&I);
          if (varies)
            perTrip.insert(&I);
          if (varies || gep)
            if (auto *NI = dyn_cast<Instruction>(ctx.operand(&I).v); NI && NI != &I) {
              NI->dropPoisonGeneratingFlags();
              NI->dropPoisonGeneratingMetadata();
            }
          continue;
        }
        if (!tripFlag)
          tripFlag = conj(q, lp, b->getTerminator());
        // q & lp is exactly where this evaluation reaches b, so it implies b's own predicate: nothing to conjoin. That
        // predicate may read an atom this evaluation never lowered (a tail block's phi on a path it did not take; strstr).
        Pred own = ctx.preds().block(b).quantumPart(ctx.T, ctx.S);
        lowerInstruction(ctx, I, tripFlag, &own);
      }
    }
  };
  // The next value of a header phi after one trip. With several latches it is the incoming of the
  // latch the trip ended at: on its back edge, or, for the latch the exits leave from, on an exit
  // edge (the trip that exits there ends there, so the final state is the exit value). A quantum phi
  // merges them by rule 9's select chain; a classical one (an invariant or a value the classical
  // exit test drives: taint) by the classical select over the classical parts of those ends.
  auto nextOf = [&](PHINode *h) -> Operand {
    auto opOf = [&](Value *v) {
      return ctx.operand(v);
    };
    Value *v0 = h->getIncomingValueForBlock(latches.front());
    if (all_of(latches, [&](BasicBlock *l) { return h->getIncomingValueForBlock(l) == v0; }))
      return opOf(v0);
    if (!isQ(h)) {
      std::vector<std::pair<Value *, Value *>> arms;
      for (BasicBlock *l : latches) {
        Value *e = classicalEdge(l, H);
        for (BasicBlock *s : successors(l))
          if (liveEdge(s))
            e = ctx.B().CreateOr(e, classicalEdge(l, s));
        Operand v = opOf(h->getIncomingValueForBlock(l));
        if (v.handle)
          internalError("loops-cutoff: a classical carried value with a rail next value", h);
        arms.push_back({ctx.B().CreateAnd(creachOf(l), e), v.v});
      }
      return Operand{classicalChain(arms), false};
    }
    std::vector<std::pair<Pred, Operand>> arms;
    for (BasicBlock *l : latches) {
      Pred e = edgeCond(l, H);
      for (BasicBlock *s : successors(l))
        if (liveEdge(s))
          e = e | edgeCond(l, s);
      arms.push_back({localOf(l) & e, opOf(h->getIncomingValueForBlock(l))});
    }
    RailType w = railOf(h->getType());
    return Operand{selectChain(ctx, arms, w), true};
  };
  // cq-9kcq S4: the rolled trip's region (set while rolledBody lowers the trip) and the final rails of its cleaned rule-6
  // chains (read after the loop in place: wireExits' keptFinal).
  rolled::Region *rTrip = nullptr;
  DenseSet<const Value *> rKeptFinal;
  auto advance = [&](Value *q) {
    // This trip's state: a rule-6 inverse reads the trip's operands, and the loop below advances them one by one.
    DenseMap<const Value *, Operand> tripState;
    if (!six.empty())
      for (PHINode *h : hphis)
        if (isQ(h))
          tripState[h] = ctx.operand(h);
    std::vector<Operand> next;
    for (PHINode *h : hphis)
      next.push_back(nextOf(h));
    for (size_t i = 0; i < hphis.size(); ++i) {
      PHINode *h = hphis[i];
      Operand nx = next[i];
      if (!isQ(h)) {
        if (nx.handle)
          internalError("loops-cutoff: a classical carried value with a rail next value", h);
        if (auto it = exitRail.find(h); it != exitRail.end()) {
          // ex' = select(q, ex + (next - cur), ex): on every trip that ran, ex is the induction's value.
          Operand cur = ctx.operand(h);
          Value *step = ctx.B().CreateSub(nx.v, cur.v);
          abi::TemplateSpec add;
          add.op = "add";
          add.w = railOf(h->getType());
          add.shape = "hl";
          Value *inc = ctx.emitTemplate(add, {it->second, Operand{step, false}});
          abi::TemplateSpec sel;
          sel.op = "select";
          sel.w = railOf(h->getType());
          it->second = Operand{ctx.emitTemplate(sel, {Operand{q, true}, Operand{inc, true}, it->second}), true};
        }
        set(h, nx);
        continue;
      }
      if (auto it = qind.find(h); it != qind.end()) {
        QInduction &qi = it->second;
        if (qi.exitRail) {
          abi::TemplateSpec sel;
          sel.op = "select";
          sel.w = railOf(h->getType());
          sel.shape = nx.handle ? "" : "lh";
          qi.exitRail = Operand{ctx.emitTemplate(sel, {Operand{q, true}, nx, *qi.exitRail}), true};
        }
        for (auto &[isAdd, c] : qi.steps) {
          Value *cv = ctx.operand(c).v;
          qi.off = isAdd ? ctx.B().CreateAdd(qi.off, cv) : ctx.B().CreateSub(qi.off, cv);
        }
        abi::TemplateSpec add;
        add.op = "add";
        add.w = railOf(h->getType());
        add.shape = "hl";
        set(h, Operand{ctx.emitTemplate(add, {qi.start, Operand{qi.off, false}}), true});
        continue;
      }
      Operand cur = ctx.operand(h);
      // A carried value this trip measured reads as its outcome (rule 2; owner, cq-2z29a: once per trip): where the trip predicate is 0 it
      // keeps that literal.
      if (nx.handle && nx.v == cur.v)
        continue;
      abi::TemplateSpec spec;
      spec.op = "select";
      spec.w = railOf(h->getType());   // R2: the tag rail
      std::string shape = std::string(nx.handle ? "h" : "l") + (cur.handle ? "h" : "l");
      spec.shape = shape == "hh" ? "" : shape;
      Value *sel = ctx.emitTemplate(spec, {Operand{q, true}, nx, cur});
      set(h, Operand{sel, true});
      if (six.count(h) && nx.handle) {
        // t = q ? U^-1(y') : y'. The arm's U^-1(y') is garbage the clean-up reads, noted as a use of the old rail so the
        // clean-up follows it; U itself is uncomputed first (its _unc reads the old rail).
        ctx.unc().setRole(ctx.unc().idOf(sel), Role::UserRegister);
        if (sixSeeds.count(cur.v))
          continue;
        RailId old = ctx.unc().idOf(cur.v);
        auto *Up = cast<Instruction>(h->getIncomingValueForBlock(latch));
        auto inv = spine::inverseStep(
            *Up, h, Operand{sel, true},
            [&](Value *z) {
              auto ts = tripState.find(z);
              return ts != tripState.end() ? ts->second : ctx.operand(z);
            },
            [](Value *) { return false; });
        Value *inner = ctx.emitTemplate(inv->spec, inv->ops);
        ctx.unc().noteUse(old, cast<Instruction>(inner));
        abi::TemplateSpec ss;
        ss.op = "select";
        ss.w = railOf(h->getType());
        ctx.unc().cleanupBijective(old, ss, {Operand{q, true}, Operand{inner, true}, Operand{sel, true}});
        // As loops-classical's latchNexts: the old rail is the header phi, cleaned in its trip where flushTrips places the
        // clean-up (after the inverse it reads); the chain's last select is the register after the loop.
        rTrip->addLateR6(old, cast<Instruction>(inner));
        rKeptFinal.insert(sel);
        spine::shared(ctx).carriedFinal.insert(sel);
      }
    }
  };

  const Instruction *at = H->getTerminator();
  Value *q = seed;
  // cq-9kcq (ROLLED_DESIGN.md §3 steps 3-5; CR rule 14, owner 2026-11-15): the trips are ONE emission of the trip inside a
  // classical loop H .. latch with a trip counter j: `j' = j + 1; br (j' < n), H, X` (rolledBody). H holds a phi of j, of the
  // chain predicate q (a handle, noteCarried), of every carried header phi's binding and of every accumulator (an exit rail,
  // an affine induction's offset and exit rail). X merges the state over the exit edges into it. a_K is a copy of the
  // chain's last predicate into a fresh rail (alloc_i1(0) + copy_i1), the one kept (CR rule 14, owner 2026-11-15: both
  // forms). The region and the reverse loop: below.
  // cq-9kcq S7: the region form's values of the header test region (other than the header phis) that the body or the code
  // after the loop reads: the rolled trip carries them across the back edge (the body of trip j reads the region evaluation
  // made at the end of trip j-1, or before the loop).
  std::vector<Instruction *> regionOut;
  if (regionForm)
    for (BasicBlock *b : L.blocks())
      if (region.count(b))
        for (Instruction &I : *b) {
          if ((b == H && isa<PHINode>(I)) || I.getType()->isVoidTy())
            continue;
          // An i1 of the region (a test, a factored condition's atom) or a switch's condition is an atom of the predicates
          // of the body's blocks: the body's flags read it.
          if (I.getType()->isIntegerTy(1) || any_of(I.users(), [](const User *u) { return isa<SwitchInst>(u); })) {
            regionOut.push_back(&I);
            continue;
          }
          if (any_of(I.uses(), [&](const Use &U) {
                // a phi of the body reads it there (on its edge from the region); a header phi on its latch's edge
                auto *ui = cast<Instruction>(U.getUser());
                if (!region.count(ui->getParent()))
                  return true;
                auto *phi = dyn_cast<PHINode>(ui);
                return phi && !region.count(phi->getIncomingBlock(U));
              }))
            regionOut.push_back(&I);
        }
  // cq-9kcq S10: the loops a trip of L lowers (its sub-loops and the loops of its exit arm, nested ones included).
  std::vector<Loop *> innerLoops;
  for (Loop *S : L.getLoopsInPreorder())
    if (S != &L)
      innerLoops.push_back(S);
  for (BasicBlock *b : U.arm) {
    Loop *l = A.LI.getLoopFor(b);
    if (!l || l->contains(H))
      continue;
    while (l->getParentLoop() && !l->getParentLoop()->contains(H))
      l = l->getParentLoop();
    if (l->getHeader() == b)
      for (Loop *S : l->getLoopsInPreorder())
        innerLoops.push_back(S);
  }
  // cq-9kcq S11 (as loops-classical's Unit::tripLocal, 176): a classically bounded loop S of a trip of the innermost K-loop
  // P around it whose quantum values read after S die within P's trip (read only by code of P's trip: no header phi of P,
  // no call, store or return, nothing outside P), with one exiting block, no noreturn arm, no loop inside it, no quantum
  // store and no call with an effect: a sub-unit of the rolled region, its reverse placed in the trip.
  auto tripLocalSub = [&](Loop &S) -> bool {
    Loop *P = S.getParentLoop();
    if (!P || classify(*P, ctx.T, ctx.S) != Case::QuantumExit || classify(S, ctx.T, ctx.S) != Case::ClassicalBound ||
        !S.getSubLoops().empty() || !S.getExitingBlock() || !exits::unitOf(S).abort.empty() || exits::hasNoreturnArm(S))
      return false;
    for (BasicBlock *b : S.blocks())
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
          if (auto *ui = dyn_cast<Instruction>(u); ui && !S.contains(ui))
            work.push_back(ui);
        while (!work.empty()) {
          const Instruction *x = work.pop_back_val();
          if (!seen.insert(x).second)
            continue;
          if (!P->contains(x) || (x->getParent() == P->getHeader() && isa<PHINode>(x)) || isa<StoreInst>(x) ||
              isa<CallBase>(x) || isa<ReturnInst>(x))
            return false;
          for (Loop *o : P->getSubLoops())
            if (o != &S && o->contains(x))
              return false;
          // P's exit test: the chain's predicate a_j, carried, reads it (a branch inside the trip is rule 8's flag, as in
          // loops-classical's trip-local sub-loops)
          if (x->isTerminator()) {
            if (P->isLoopExiting(x->getParent()))
              return false;
            continue;
          }
          for (const User *u : x->users())
            if (auto *ui = dyn_cast<Instruction>(u))
              work.push_back(ui);
        }
      }
    return true;
  };
  // The rolled trip carries an aggregate value one field per header phi (cq-9kcq S21: the general exit capture's rails, a
  // value of the header test region); an aggregate carried header phi runs on as an unbuilt shape, named by a note.
  auto noteAggregates = [&]() {
    const char *why = nullptr;
    if (any_of(hphis, [&](PHINode *h) { return !ctx.bound(h) || ctx.fields(h).size() != 1; }))
      why = "an aggregate carried value";
    if (why)
      noteUnbuilt(std::string("loops-cutoff: the rolled K-loop carries one field per value: ") + why, H->getTerminator());
  };
  // cq-9kcq S3b (step 6): the trip is the one segment of a rolled::Region (its records are the segment's Uncompute scope; the
  // seeds of the entry are its own seed scope, released at the reverse's end Z); after the a_K copy at X, flushTrips (a rail
  // made and last read in the trip is undone in its trip), then the exit values are read in place or copied out and the
  // reverse loop runs at X or, deferred, after their readers (Region::wireExits, finishExits). The reverse pops the trips
  // the come-from index replays (the header's entry edge ends it).
  std::shared_ptr<rolled::Region> rreg;
  unsigned rSeedScope = ~0u;
  // S10: a K-loop of the exit arm runs in every trip under that trip's arm flag; its a_K is the XOR of the trips' chain
  // ends (armKept, capture). Rolled, that XOR is an accumulator over the trips: minted before the loop (outside the
  // region's seed scope: the reverse never undoes it) and changed in place in each trip, kept.
  auto mintArmKept = [&]() {
    if (!armKept)
      for (BasicBlock *b : U.arm) {
        Loop *S = subLoopOf(b);
        if (!S || S->getHeader() != b || classify(*S, ctx.T, ctx.S) != Case::QuantumExit)
          continue;
        std::optional<uint64_t> Bs = exits::cutoffBound(*S, A.SE, ctx.S);
        if (Bs && *Bs <= ctx.K(S))
          continue;
        RailType i1{Kind::Int, 1};
        CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(ctx.M.getContext())});
        ctx.unc().recordSeed(z);
        armKept = z;
        break;
      }
  };
  BasicBlock *rX = nullptr, *rHead = nullptr, *rCont = nullptr;
  // cq-9kcq S12c (CR rules 14, 23; cq/FenvCarry.h): the pieces of the quantum floating-point environment the trips change,
  // carried as header phis over handles; their values at X (rolledBody's put), wired out with the exit values.
  std::vector<std::pair<unsigned, Operand>> rFenv;
  bool rKeptRt = false;   // rolledBody made a_K's copy under a run-time branch on K < B (and set its role)
  bool preRegion = false;   // S11e: the region form's trip 0 opened the region (its first segments)
  DenseSet<const BasicBlock *> preBlocks;   // S11e: the output blocks made before that region
  // cq-9kcq S7: rolledBody's state at X for the region values read after the loop (regionOut, rebound after wireExits).
  auto rolledBody = [&](Value *q0, Value *gR) -> Value * {
    LLVMContext &Cx = ctx.M.getContext();
    IRBuilder<> &B = ctx.B();
    Type *i32 = Type::getInt32Ty(Cx);
    // cq-9kcq S10 (CR rule 14: "nested inner loops keep one a_K per outer trip"; ROLLED_DESIGN.md §3 step 7): a nested
    // K-loop (top false, rolledTrip set) is no region of its own: its header and its trip's blocks are segments of the
    // enclosing loop's region, its seeds are records of the enclosing trip's segment (undone by the enclosing reverse per
    // outer trip), its exit block X is the segment the enclosing trip goes on in, and the come-from index of X and of its
    // header replays its trips in the enclosing reverse. Its a_K copy is made at X in every outer trip, kept.
    rolled::Region *RG = rolledTrip;
    mintArmKept();
    // cq-9kcq S11e (CR rules 14, 16): the stop rail (stopAcc, the XOR of the noreturn arm flags this loop's trips take, read
    // by the enclosing K-trip as `stopped`) is an accumulator over the trips: minted before the header (a record of the
    // enclosing trip's segment, undone by the enclosing reverse after its readers) and changed in place in each trip.
    if (inKLoop && !stopAcc && exits::hasNoreturnArm(L)) {
      RailType i1{Kind::Int, 1};
      CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(Cx)});
      ctx.unc().recordSeed(z);
      stopAcc = z;
    }
    BasicBlock *seedHead = B.GetInsertBlock();
    if (top && rreg) {
      RG = rreg.get();   // S11e: the region form's trip 0 opened the region (preRegion)
    } else if (top) {
      rreg = std::make_shared<rolled::Region>(ctx, ctx.out());
      RG = rreg.get();
      rreg->setDiagAt(H->getTerminator());
      rSeedScope = ctx.unc().openScope();
      rreg->setOwnSeedScope(rSeedScope);
    }
    // Every carried quantum value enters as a handle: a literal start is seeded first.
    for (PHINode *h : hphis)
      if (isQ(h) && !ctx.operand(h).handle && !qind.count(h))
        set(h, Operand{seedRail(ctx.operand(h).v, h->getType()), true});
    for (auto &[h, r] : exitRail)
      if (!r.handle)
        r = Operand{seedRail(r.v, h->getType()), true};
    for (auto &[h, qi] : qind)
      if (qi.exitRail && !qi.exitRail->handle)
        qi.exitRail = Operand{seedRail(qi.exitRail->v, h->getType()), true};
    // cq-9kcq S7: a quantum value of the header test region the evaluation before the loop folded to a literal enters the
    // rolled trip as a seed too (a carried handle, below).
    for (Instruction *I : regionOut)
      if (ctx.bound(I) && isQ(I) && !isAggr(I) && !ctx.operand(I).handle)
        set(I, Operand{seedRail(ctx.operand(I).v, I->getType()), true});
    // cq-9kcq S6 (ROLLED_DESIGN.md §3 step 1; CR §1.4 "Received K", rule 27 "Cutoff"; owner 2026-11-15): the trips run
    // to the run-time bound n = umin(Krt, B) (Krt when no bound is known), Krt the received K (a table clone's K
    // parameter; in a function a table clone reaches, select(@__cq_k == -1, own K, @__cq_k)) in place of the own K,
    // smaller or larger. a_K is kept where Krt < B (always where no bound is known): a classical branch at X when that
    // is not constant. With no received K both are the constants c and keep.
    Value *nRt = ConstantInt::get(i32, c);
    Value *keepRt = nullptr;
    bool keepAny = keep;
    if (receivedK) {
      Value *Krt = receivedK;
      if (Krt->getType() != i32)
        internalError("loops-cutoff: a received K that is not an i32", H->getTerminator());
      // S10: a K-loop nested in the rolled trip has a bound of its own (the member is the loop lowerCutoff was given)
      std::optional<uint64_t> bnd = rolledTrip && !top ? exits::cutoffBound(L, A.SE, ctx.S) : bound;
      if (bnd && *bnd <= 0xFFFFFFFFull) {
        Constant *Bc = ConstantInt::get(i32, *bnd);
        nRt = B.CreateBinaryIntrinsic(Intrinsic::umin, Krt, Bc);
        keepRt = B.CreateICmpULT(Krt, Bc);
      } else {
        nRt = Krt;
      }
      keepAny = !repeat;
    }
    // cq-9kcq S6b, S6c (owner ruling Q2 of 2026-11-15, CR §0: K = 0 is legal, no trip runs, every carried value keeps its
    // entry value, a_K is the predicate of reaching trip 0): where the bound is not a constant of at least 1 (a received K,
    // a table clone's K), or the trip-0 test has a classical conjunct t0 (owner ruling Q10), the counter test is made
    // before trip 0 too: the entry E branches on `0 < n` (and t0) to H or straight to X (the zero-trip guard), and the latch
    // keeps its bottom test `j + 1 < n`. X's phis merge the entry values (the guard edge: no trip ran) with the last trip's
    // (rule 6, 75: a cleaned register is its incoming rail on a zero-trip path, kept); a_K is the chain's predicate there
    // (q0 where no trip ran: the seed, or the predicate of reaching the first test). Where t0 is false the chain ends before
    // trip 0 with a_0 a |0> seed (minted here, in the seed scope, freed at 0 at the end). The guard edge is an exit edge of
    // the region whose reverse is Z alone (Region::reverse).
    auto *nK = dyn_cast<ConstantInt>(nRt);
    Value *g0 = nullptr;
    if (t0)
      if (auto *k = dyn_cast<ConstantInt>(t0); !(k && k->isOne()))
        g0 = t0;
    // cq-9kcq S7: the region form's trip-0 test (lowered before the loop) with a classical conjunct gR ends the chain before
    // trip 0 where gR is false, as a trip-0 test's conjunct t0 does.
    if (gR)
      if (auto *k = dyn_cast<ConstantInt>(gR); !(k && k->isOne()))
        g0 = g0 ? B.CreateAnd(g0, gR) : gR;
    bool zeroGuard = !nK || nK->isZero() || g0;
    if (g0 && (!top || preRegion)) {
      // S10: the branch's blocks are segments of the enclosing region (as test's Skip below); the |0> seed is minted in Zb
      RailType i1{Kind::Int, 1};
      BasicBlock *At = B.GetInsertBlock();
      BasicBlock *Zb = BasicBlock::Create(Cx, "", &ctx.out());
      BasicBlock *Jb = BasicBlock::Create(Cx, "", &ctx.out());
      B.CreateCondBr(g0, Jb, Zb);
      RG->branchSeg(Zb);
      CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(Cx)});
      ctx.unc().recordSeed(z);
      B.CreateBr(Jb);
      RG->branchSeg(Jb);
      PHINode *q0p = B.CreatePHI(handleTy(Cx), 2);
      q0p->addIncoming(q0, At);
      q0p->addIncoming(z, Zb);
      ctx.unc().recordMerge(q0p);
      q0 = q0p;
    } else if (g0) {
      RailType i1{Kind::Int, 1};
      CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(Cx)});
      ctx.unc().recordSeed(z);
      BasicBlock *At = B.GetInsertBlock();
      BasicBlock *Zb = BasicBlock::Create(Cx, "", &ctx.out());
      BasicBlock *Jb = BasicBlock::Create(Cx, "", &ctx.out());
      B.CreateCondBr(g0, Jb, Zb);
      BranchInst::Create(Jb, Zb);
      ctx.unc().noteClassicalArm(Jb, Zb);
      B.SetInsertPoint(Jb);
      PHINode *q0p = B.CreatePHI(handleTy(Cx), 2);
      q0p->addIncoming(q0, At);
      q0p->addIncoming(z, Zb);
      ctx.unc().recordMerge(q0p);
      q0 = q0p;
    }
    BasicBlock *E = B.GetInsertBlock();
    // cq-9kcq S12c: every piece of the environment a trip may change, its rail at E (step 1 of cq/FenvCarry.h)
    SmallVector<BasicBlock *, 8> perTrip(U.arm.begin(), U.arm.end());   // cq-6zudr: lowered with each trip
    perTrip.append(U.abort.begin(), U.abort.end());
    std::vector<fenv::CarriedPiece> pieces = fenv::loopCarried(ctx, L, perTrip);
    BasicBlock *Hd = BasicBlock::Create(Cx, "", &ctx.out());
    BasicBlock *Xb = nullptr;
    if (zeroGuard) {
      Xb = BasicBlock::Create(Cx, "", &ctx.out());
      Value *go = B.CreateICmpULT(ConstantInt::get(i32, 0), nRt);
      if (g0)
        go = B.CreateAnd(go, g0);
      B.CreateCondBr(go, Hd, Xb);
    } else {
      B.CreateBr(Hd);
    }
    if (top && preRegion) {
      rreg->branchSeg(Hd);   // S11e: the trip-0 segments end at E
    } else if (top) {
      ctx.unc().closeScope(rSeedScope);
      ctx.unc().leaveScope(rSeedScope, seedHead);
      rreg->startSeg(Hd);
    } else {
      RG->branchSeg(Hd);   // E ends the enclosing trip's open segment
    }
    RG->addHead(Hd, E);
    rHead = Hd;
    // (value, its phi in H, how the latch value is read)
    struct Carry {
      PHINode *phi;
      Value *init;   // the entry value (its value at X on the zero-trip guard's edge)
      std::function<Value *()> now;
      std::function<void(Value *)> put;   // binds the value after the loop (with the zero-trip guard: its value at X)
      bool handle;
    };
    std::vector<Carry> carry;
    DenseMap<const PHINode *, size_t> carryOfH;   // a header phi's carry entry
    auto phiFor = [&](Value *init, bool handle) {
      PHINode *p = B.CreatePHI(handle ? handleTy(Cx) : init->getType(), 2);
      p->addIncoming(init, E);
      if (handle) {
        // a nested loop's entry value is a rail of the enclosing trip; S11e: so is one trip 0's segments made
        auto *ii = dyn_cast<Instruction>(init);
        if (top && !(preRegion && ii && !preBlocks.count(ii->getParent())))
          rreg->addExternalInit(init);
        ctx.unc().recordExternal(p, Role::UserRegister);
        ctx.unc().noteCarried(p);
      }
      return p;
    };
    PHINode *j = B.CreatePHI(i32, 2);
    j->addIncoming(ConstantInt::get(i32, 0), E);
    // cq-9kcq S9 (CR rule 14 "No live exit"): a loop with no exit edge at all keeps its chain at q0 in every trip (every
    // trip runs where the loop runs); it is no carried value, and after the K trips the caller aborts on it.
    bool frozen = U.live.empty() && U.abort.empty() && !exits::hasNoreturnArm(L);
    PHINode *qp = frozen ? nullptr : phiFor(q0, true);
    // cq-wuzt3 (rules 5, 8, 14; 55): a_0 is an arm's false-edge flag (a guard that is not trip 0 of the latch test seeds
    // the chain; guardIsTripZero); a kept store under the chain closes its bracket in trip 0 (bus::emitKeptStore). Read by
    // stores of this trip only (a nested K-loop's chain is its own phi); lowerCutoff restores it.
    if (top && qp && q0 == seed && q0 != spine::shared(ctx).tripZeroRail && ctx.unc().negatedAtomOf(q0)) {
      spine::shared(ctx).rolledZeroQ = qp;
      spine::shared(ctx).rolledZeroJ = j;
    }
    for (PHINode *h : hphis) {
      Operand o = ctx.operand(h);
      PHINode *p;
      if (six.count(h)) {
        // cq-9kcq S4, rule 6 (as loops-classical's r6Of): the phi is the old rail each trip cleans (trip 0: the initial
        // rail, a seed or a dead rail, a register the clean-up frees), no carried rail the reverse undoes.
        if (!o.handle)
          internalError("loops-cutoff: a rule-6 carried value with a classical initial value in the rolled trip", h);
        p = B.CreatePHI(handleTy(Cx), 2);
        p->addIncoming(o.v, E);
        ctx.unc().recordExternal(p, Role::UserRegister);
        if (sixSeeds.count(o.v))
          ctx.unc().setRole(ctx.unc().idOf(o.v), Role::UserRegister);
      } else {
        p = phiFor(o.v, o.handle);
      }
      set(h, Operand{p, o.handle});
      carryOfH[h] = carry.size();
      carry.push_back({p, o.v, [&, h, hd = o.handle]() -> Value * {
                         Operand n = ctx.operand(h);
                         if (n.handle != hd)
                           internalError("loops-cutoff: a carried value changes between rail and classical in the rolled trip", h);
                         return n.v;
                       },
                       [&, h, hd = o.handle, r6 = six.count(h) != 0](Value *v) {
                         set(h, Operand{v, hd});
                         if (r6) {
                           // the register after the loop: no trip after it cleans it (as the chain's last select)
                           rKeptFinal.insert(v);
                           spine::shared(ctx).carriedFinal.insert(v);
                         }
                       },
                       o.handle});
    }
    for (PHINode *h : hphis) {
      if (auto it = exitRail.find(h); it != exitRail.end()) {
        Value *in = it->second.v;
        PHINode *p = phiFor(in, true);
        it->second = Operand{p, true};
        carry.push_back({p, in, [&, h]() -> Value * { return exitRail.find(h)->second.v; },
                         [&, h](Value *v) { exitRail.find(h)->second = Operand{v, true}; }, true});
      }
      if (auto it = qind.find(h); it != qind.end()) {
        QInduction &qi = it->second;
        Value *in = qi.off;
        PHINode *p = phiFor(in, false);
        qi.off = p;
        carry.push_back({p, in, [&, h]() -> Value * { return qind.find(h)->second.off; },
                         [&, h](Value *v) { qind.find(h)->second.off = v; }, false});
        if (qi.exitRail) {
          Value *in = qi.exitRail->v;
          PHINode *x = phiFor(in, true);
          qi.exitRail = Operand{x, true};
          carry.push_back({x, in, [&, h]() -> Value * { return qind.find(h)->second.exitRail->v; },
                           [&, h](Value *v) { qind.find(h)->second.exitRail = Operand{v, true}; }, true});
        }
      }
    }
    // cq-9kcq S7 (ROLLED_DESIGN.md §3 step 2, CR rule 14 "a header test with no guard is trip 0, made before the loop, and
    // each trip is body then test"): in the region form a trip is the body, the state's advance, then the header test region
    // lowered again on the advanced state and its test. A region value the body or the code after the loop reads is carried
    // in a phi of H: its entry value is the evaluation before the loop, its latch value the trip's.
    for (Instruction *I : regionOut) {
      if (!ctx.bound(I))
        continue;   // not lowered (a value of a block the region evaluation did not reach)
      if (isAggr(I)) {
        // cq-9kcq S21 (CR rules 14, 26): an aggregate value is carried one field per phi of H, each as a scalar value of the
        // region (a classical field of a quantum value stays classical: the evaluation's fields are what the trip reads).
        SmallVector<Operand, 4> fs = ctx.fields(I);
        for (size_t k = 0; k < fs.size(); ++k) {
          Operand o = fs[k];
          PHINode *p = phiFor(o.v, o.handle);
          fs[k] = Operand{p, o.handle};
          carry.push_back({p, o.v, [&, I, k, hd = o.handle]() -> Value * {
                             Operand n = ctx.fields(I)[k];
                             if (n.handle == hd)
                               return n.v;
                             if (!hd)
                               internalError("loops-cutoff: a classical field of the header test region becomes a rail in the rolled trip", I);
                             return seedRail(n.v, n.v->getType());   // the trip's evaluation folded it
                           },
                           [&, I, k, hd = o.handle](Value *v) {
                             SmallVector<Operand, 4> now = ctx.fields(I);
                             now[k] = Operand{v, hd};
                             mine.insert(I);
                             ctx.rebind(I, now);
                           },
                           o.handle});
        }
        mine.insert(I);
        ctx.rebind(I, fs);
        continue;
      }
      Operand o = ctx.operand(I);
      // cq-9kcq (p38_cutx; CR rules 10, 14): a region value that is a header phi's latch value and enters on that phi's
      // rail (a carried register rotated in place, `x = theta(x)` in the header) is that phi's rail in every trip: it shares
      // the phi (the advance's select of a rail with itself folds), where a second phi made a fresh select rail per trip
      // that the rotation then made a register, left as garbage.
      if (o.handle) {
        PHINode *h = nullptr;
        for (PHINode *x : hphis)
          if (!h && L.getLoopLatch() && x->getIncomingValueForBlock(L.getLoopLatch()) == I)
            h = x;
        if (auto it = h ? carryOfH.find(h) : carryOfH.end(); it != carryOfH.end() && carry[it->second].handle &&
                                                            carry[it->second].init == o.v && !six.count(h)) {
          Carry &k = carry[it->second];
          set(I, Operand{k.phi, true});
          k.put = [&, I, prev = k.put](Value *v) {
            prev(v);
            set(I, Operand{v, true});
          };
          continue;
        }
      }
      PHINode *p = phiFor(o.v, o.handle);
      set(I, Operand{p, o.handle});
      carry.push_back({p, o.v, [&, I, hd = o.handle]() -> Value * {
                         Operand n = ctx.operand(I);
                         if (n.handle == hd)
                           return n.v;
                         if (!hd)
                           internalError("loops-cutoff: a classical value of the header test region becomes a rail in the rolled trip", I);
                         return seedRail(n.v, I->getType());   // the trip's evaluation folded it
                       },
                       [&, I, hd = o.handle](Value *v) { set(I, Operand{v, hd}); }, o.handle});
    }
    // cq-9kcq S8: the multi-exit form's accumulators (a phi of the continuation, a value of the unit read after it) take
    // the trip's value where it exits: carried in phis of H as the exit rails are.
    for (size_t i = 0; i < cphis.size(); ++i) {
      Value *in = cphis[i].acc.v;
      PHINode *p = phiFor(in, true);
      cphis[i].acc = Operand{p, true};
      carry.push_back({p, in, [&, i]() -> Value * { return cphis[i].acc.v; },
                       [&, i](Value *v) { cphis[i].acc = Operand{v, true}; }, true});
    }
    // cq-9kcq S21 (CR rules 14, 26): an aggregate value's capture is one rail per field, each carried in a phi of H.
    for (size_t i = 0; i < xaccs.size(); ++i)
      for (size_t k = 0; k < xaccs[i].acc.size(); ++k) {
        Value *in = xaccs[i].acc[k].v;
        PHINode *p = phiFor(in, true);
        xaccs[i].acc[k] = Operand{p, true};
        carry.push_back({p, in, [&, i, k]() -> Value * { return xaccs[i].acc[k].v; },
                         [&, i, k](Value *v) { xaccs[i].acc[k] = Operand{v, true}; }, true});
      }
    // cq-9kcq S11e: the stop rail, minted before the header, is carried like the accumulators above.
    if (stopAcc && inKLoop) {
      Value *in = stopAcc;
      PHINode *p = phiFor(in, true);
      stopAcc = p;
      stopCarried = true;
      carry.push_back({p, in, [&]() -> Value * { return stopAcc; }, [&](Value *v) { stopAcc = v; }, true});
    }
    // cq-9kcq S12c (cq/FenvCarry.h steps 2-4): each piece of the environment is a carried handle phi the trip reads; its
    // latch value is the piece at the end of the trip, its value at X is bound and wired out after the loop.
    for (const fenv::CarriedPiece &pc : pieces) {
      PHINode *p = phiFor(pc.init, true);
      fenv::bindPiece(ctx, pc.id, p);
      size_t slot = rFenv.size();
      rFenv.push_back({pc.id, Operand{p, true}});
      carry.push_back({p, pc.init, [&, id = pc.id]() -> Value * { return fenv::pieceNow(ctx, id); },
                       [&, id = pc.id, slot](Value *v) {
                         fenv::bindPiece(ctx, id, v);
                         rFenv[slot].second = Operand{v, true};
                       },
                       true});
    }
    // The classical reachability the evaluation before the loop computed reads its values; the trip reads the phis.
    creach.clear();
    Value *qc = qp ? static_cast<Value *>(qp) : q0;
    auto all = [](const BasicBlock *) { return true; };
    auto inRegion = [&](const BasicBlock *b) { return region.count(b) != 0; };
    auto inBody = [&](const BasicBlock *b) { return region.count(b) == 0; };
    rTrip = RG;
    rolled::Region *outerTrip = rolledTrip;
    BasicBlock *outerHead = tripHead;
    std::function<void(BasicBlock *)> outerHook = segHook;
    rolledTrip = RG;
    tripHead = Hd;
    // cq-9kcq S4b: a classical branch of the trip makes its blocks (Run, Skip, Join) segments of the region, as in a
    // classically bounded loop's trip (cq-kk46l); the reverse replays the path a trip took through its come-from index.
    segHook = RG->segHook();
    if (regionForm)
      lowerBlocks(qc, inBody);
    else
      lowerBlocks(qc, all);
    // cq-9kcq S9: the noreturn arms the trip's blocks exit into run under their edge flags, each an abort_i1 (rule 16).
    abortArms(qc, regionForm ? std::function<bool(const BasicBlock *)>(inBody) : std::function<bool(const BasicBlock *)>(all));
    // cq-9kcq S8: the exit arm runs in the trip under the trip's exit flags; the accumulators take its values.
    if (multi)
      capture(qc, regionForm ? std::function<bool(const BasicBlock *)>(inBody) : std::function<bool(const BasicBlock *)>(all));
    if (!Xb)
      Xb = BasicBlock::Create(Cx, "", &ctx.out());
    // The tests of the trip and the exit edges into X (cq-9kcq S5, S7, S8). Each edge carries the state X reads on it: the
    // zero-trip guard's (E) the entry values and q0; a classical exit conjunct's Skip (owner ruling Q10, CR rule 14: `br C,
    // Run, Skip` after the trip's state advanced; Skip mints a_{j+1} as a |0> seed) the state at that test; the counter's the
    // state where the trip count is reached, and a_K. X's phi `ix` names the edge taken and the reverse starts at that edge's
    // segment (Region's exitIndex).
    struct XEdge {
      BasicBlock *from;
      std::vector<Value *> state;   // per carry
      Value *q;
    };
    std::vector<XEdge> xe;
    if (zeroGuard) {
      std::vector<Value *> st;
      for (Carry &k : carry)
        st.push_back(k.init);
      xe.push_back({E, st, q0});
    }
    auto snap = [&]() {
      std::vector<Value *> st;
      for (Carry &k : carry)
        st.push_back(k.now());
      return st;
    };
    // One test of the chain: go is the predicate of going on; `between` runs after its operands are read (the advance).
    auto test = [&](Value *qin, const Pred &go, ArrayRef<Pred> parts, const Instruction *tat,
                    const std::function<void()> &between) -> Value * {
      Pred Cc = go.isBottom() ? Pred::top() : go.classicalFactor(ctx.T, ctx.S);
      if (Cc.isTop()) {
        Value *qn = unionFlag(qin, go, parts, tat, false);
        between();
        return qn;
      }
      Pred Q = go.quantumPart(ctx.T, ctx.S);
      Value *g = classicalValue(ctx, Cc);
      // Read only where Cc holds: the branch on g below skips the rest (cq-3630b: Q reads a classical atom minted only on
      // Cc's paths of the trip, TinyCC decl).
      Value *fQ = Q.isTop() ? nullptr : ctx.preds().flag(ctx, Q, Cc);
      between();
      if (auto *k = dyn_cast<ConstantInt>(g); !(k && k->isOne())) {
        std::vector<Value *> st = snap();
        BasicBlock *Run = BasicBlock::Create(Cx, "", &ctx.out());
        BasicBlock *skipB = BasicBlock::Create(Cx, "", &ctx.out());
        B.CreateCondBr(g, Run, skipB);
        RG->branchSeg(skipB);
        RailType i1{Kind::Int, 1};
        CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(Cx)});
        ctx.unc().recordSeed(z);
        B.CreateBr(Xb);
        xe.push_back({skipB, st, z});
        RG->branchSeg(Run);
      }
      return fQ ? andRail(qin, fQ) : qin;
    };
    auto none = [] {};
    auto adv = [&] { advance(qc); };
    // cq-9kcq S7: two tests per trip (189: a header test region and an exit from the body): the trip is the body, the latch
    // test, the counter test, then the region lowered again and its header test. a_K is the predicate after the K-th latch
    // test; no (K+1)-th header test is made (CR rule 14, ruling Q15).
    bool bodyExits = regionForm && multi && any_of(exiting, [&](BasicBlock *e) {
                       return !region.count(e) && any_of(successors(e), liveEdge);
                     });
    Value *qn;
    BasicBlock *Lt, *back;
    Value *j1;
    if (!regionForm || bodyExits) {
      qn = test(qc, cont, contParts, latch->getTerminator(), adv);
    } else {
      advance(qc);
      Value *qr = qc;
      lowerBlocks(qr, inRegion);
      abortArms(qr, inRegion);
      if (multi)
        capture(qr, inRegion);
      if (qr != qc)
        internalError("loops-cutoff: the header test region changed the trip predicate in the rolled trip", at);
      qn = test(qc, regionCont, regionParts, at, none);
    }
    Lt = B.GetInsertBlock();
    j1 = B.CreateAdd(j, ConstantInt::get(i32, 1));
    xe.push_back({Lt, snap(), qn});
    if (!bodyExits) {
      B.CreateCondBr(B.CreateICmpULT(j1, nRt), Hd, Xb);
      back = Lt;
    } else {
      BasicBlock *R = BasicBlock::Create(Cx, "", &ctx.out());
      B.CreateCondBr(B.CreateICmpULT(j1, nRt), R, Xb);
      RG->branchSeg(R);
      Value *qr = qn;
      lowerBlocks(qr, inRegion);
      abortArms(qr, inRegion);
      if (multi)
        capture(qr, inRegion);
      if (qr != qn)
        internalError("loops-cutoff: the header test region changed the trip predicate in the rolled trip", at);
      qn = test(qn, regionCont, regionParts, at, none);
      back = B.GetInsertBlock();
      B.CreateBr(Hd);
    }
    // cq-mysin: the latch values are read at the end of `back`, before a nested loop's RG->branchSeg(Xb) moves the builder
    // into X. A carried value read through the builder's block (a piece of the environment: fenv::pieceNow reads the state
    // at the builder) read in X is X's merge over the exit edges, which does not dominate the back edge (reachDefs then read
    // it through the outer header, the previous outer trip's rail, poison in outer trip 0).
    std::vector<Value *> latchVals = snap();
    segHook = outerHook;
    rTrip = nullptr;
    rolledTrip = outerTrip;
    tripHead = outerHead;
    if (top)
      rreg->endSeg();
    else
      RG->branchSeg(Xb);   // S10: X is the segment the enclosing trip goes on in (its come-from replays the exit edge)
    rX = Xb;
    j->addIncoming(j1, back);
    if (qp)
      qp->addIncoming(qn, back);
    else if (qn != q0)
      internalError("loops-cutoff: a loop with no exit edge changed its chain in the rolled trip", at);
    for (size_t i = 0; i < carry.size(); ++i)
      carry[i].phi->addIncoming(latchVals[i], back);
    B.SetInsertPoint(Xb);
    if (xe.size() == 1) {
      for (size_t i = 0; i < carry.size(); ++i)
        carry[i].put(xe[0].state[i]);
      qn = xe[0].q;
    } else {
      // phis of X over the edges; a value equal on every edge (no trip changes it: a register rotated in place, rule 10) is
      // read as it is
      if (top) {
        PHINode *ix = B.CreatePHI(i32, xe.size());
        for (size_t e = 0; e < xe.size(); ++e) {
          ix->addIncoming(ConstantInt::get(i32, e), xe[e].from);
          rreg->addExitEdge(ix, xe[e].from);
        }
      }
      for (size_t i = 0; i < carry.size(); ++i) {
        Carry &k = carry[i];
        if (all_of(xe, [&](const XEdge &x) { return x.state[i] == xe[0].state[i]; })) {
          k.put(xe[0].state[i]);
          continue;
        }
        PHINode *x = B.CreatePHI(k.phi->getType(), xe.size());
        for (XEdge &x0 : xe)
          x->addIncoming(x0.state[i], x0.from);
        if (k.handle)
          ctx.unc().recordMerge(x);
        k.put(x);
      }
      if (all_of(xe, [&](const XEdge &x) { return x.q == xe[0].q; })) {
        qn = xe[0].q;
      } else {
        PHINode *qx = B.CreatePHI(handleTy(Cx), xe.size());
        for (XEdge &x0 : xe)
          qx->addIncoming(x0.q, x0.from);
        ctx.unc().recordMerge(qx);
        qn = qx;
      }
    }
    if (!keepAny || frozen)
      return qn;
    BasicBlock *Jn = nullptr;
    if (keepRt) {
      // cq-9kcq S6: a_K is kept only where K < B (CR rule 14): Run makes the copy, kept; the reverse follows at Jn.
      BasicBlock *Run = BasicBlock::Create(Cx, "", &ctx.out());
      BasicBlock *Skip = BasicBlock::Create(Cx, "", &ctx.out());
      Jn = BasicBlock::Create(Cx, "", &ctx.out());
      B.CreateCondBr(keepRt, Run, Skip);
      if (top) {
        BranchInst::Create(Jn, Skip);
        ctx.unc().noteClassicalArm(Jn, Skip);
        B.SetInsertPoint(Run);
      } else {
        RG->branchSeg(Skip);
        B.CreateBr(Jn);
        RG->branchSeg(Run);
      }
    }
    RailType i1{Kind::Int, 1};
    CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(Cx)});
    RailId fid = ctx.unc().recordSeed(f);
    abi::CoreSpec cp{abi::Core::Copy, i1};
    CallInst *cpy = ctx.emitCore(cp, {qn, f});
    ctx.unc().recordCore(cpy, cp, {Operand{qn, true}, Operand{f, true}}, fid);
    if (!Jn)
      return f;
    ctx.unc().setRole(fid, Role::KeptOverflow);
    B.CreateBr(Jn);
    if (top)
      B.SetInsertPoint(Jn);
    else
      RG->branchSeg(Jn);
    rCont = Jn;
    rKeptRt = true;
    return qn;
  };

  noteAggregates();
  // S10 rolls the nested K-loops and the K-loops of the exit arm; S11 a trip-local classically bounded loop of a trip (a
  // sub-unit of the region, its reverse in the trip); S11f one whose values outlive the trip, or of the exit arm (a sub-unit
  // whose reverse runs in the region's reverse).
  for (Loop *S : innerLoops)
    if (classify(*S, ctx.T, ctx.S) != Case::QuantumExit && !tripLocalSub(*S))
      reverseSubs.insert(S);
  // cq-9kcq (CR rules 2, 14): a cq_measure of a carried value in the rolled trip measures a kept basis copy (lowerMeasure)
  spine::shared(ctx).rolledHeaders.insert(L.getHeader());
  // cq-9kcq S11c (CR rules 9, 14; join_units, musl wcsrtombs): a unit lowered before this one left this unit's incomings of a
  // continuation phi to the walker's join (addJoinArm: "lowered after the loop"). The incomings from this unit's own blocks
  // other than its tail are this unit's binding (the cphis accumulator selects each trip's value in where the trip leaves on
  // that edge). Rolled, that value is a rail of the trip, read at the join where it does not reach (and its edge predicate
  // reads the trip's atoms): those arms are this unit's and dropped. The tail's arms stay the walker's (its outside paths).
  if (multi)
    for (CPhi &cp : cphis) {
      PHINode &P = *cp.P;
      std::vector<std::pair<Pred, const Value *>> ja = ctx.takeJoinArms(&P);
      for (auto &[e, v] : ja) {
        bool mine = false;
        for (unsigned i = 0; i < P.getNumIncomingValues() && !mine; ++i) {
          BasicBlock *u = P.getIncomingBlock(i);
          mine = P.getIncomingValue(i) == v && U.contains(L, u) && !is_contained(U.tail, u) &&
                 (e & !ctx.preds().edge(u, U.cont)).isBottom();
        }
        if (!mine)
          ctx.addJoinArm(&P, e, v);
      }
    }
  {
    // cq-9kcq S7: the region form's trip 0 is its header test region, lowered and tested before the loop (a_0); a classical
    // conjunct of that test (owner ruling Q10) goes to rolledBody's zero-trip guard.
    Value *gR = nullptr;
    if (regionForm) {
      auto inRegion = [&](const BasicBlock *b) { return region.count(b) != 0; };
      // cq-9kcq S11e (CR rule 14, ROLLED_DESIGN.md §3 step 7): trip 0's test region is lowered before the header, and its
      // exit arm may hold a K-loop (capture). That loop rolls inside this loop's region: the region opens here, its seed
      // scope empty, and trip 0's blocks are its first segments (each run once, mirrored by the reverse after the trips,
      // before Z). The arm's a_K accumulator is minted before the region (never undone).
      rolled::Region *outerTrip0 = rolledTrip;
      std::function<void(BasicBlock *)> outerHook0 = segHook;
      if (top && multi && any_of(U.arm, [&](BasicBlock *b) {
            Loop *S = subLoopOf(b);
            return S && S->getHeader() == b && classify(*S, ctx.T, ctx.S) == Case::QuantumExit;
          })) {
        mintArmKept();
        IRBuilder<> &B = ctx.B();
        rreg = std::make_shared<rolled::Region>(ctx, ctx.out());
        rreg->setDiagAt(H->getTerminator());
        rSeedScope = ctx.unc().openScope();
        rreg->setOwnSeedScope(rSeedScope);
        ctx.unc().closeScope(rSeedScope);
        ctx.unc().leaveScope(rSeedScope, B.GetInsertBlock());
        for (const BasicBlock &ob : ctx.out())
          preBlocks.insert(&ob);
        BasicBlock *P0 = BasicBlock::Create(ctx.M.getContext(), "", &ctx.out());
        B.CreateBr(P0);
        rreg->startSeg(P0);
        preRegion = true;
        rolledTrip = rreg.get();
        segHook = rreg->segHook();
      }
      lowerBlocks(q, inRegion);
      abortArms(q, inRegion);
      if (multi)
        capture(q, inRegion);
      rolledTrip = outerTrip0;
      segHook = outerHook0;
      if (Pred C = regionCont.isBottom() ? Pred::top() : regionCont.classicalFactor(ctx.T, ctx.S); C.isTop()) {
        q = conj(q, regionCont, at);
      } else {
        Pred Q = regionCont.quantumPart(ctx.T, ctx.S);
        gR = classicalValue(ctx, C);
        Value *fQ = Q.isTop() ? nullptr : ctx.preds().flag(ctx, Q);
        q = fQ ? andRail(q, fQ) : q;
      }
    }
    q = rolledBody(q, gR);
  }
  if (q == seed) {
    // CR rule 14 "No live exit": a loop with no exit edge runs K trips and then abort_i1 on its seed (the
    // program's continuation is unreachable). The flag is a copy of the seed, kept (rule 16, 45).
    if (!U.live.empty() || !U.abort.empty())
      internalError("loops-cutoff: the chain's last predicate is its seed in a loop with an exit", at);
    RailType i1{Kind::Int, 1};
    CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(ctx.M.getContext())});
    RailId fid = ctx.unc().recordSeed(f);
    abi::CoreSpec cp{abi::Core::Copy, i1};
    CallInst *cpy = ctx.emitCore(cp, {seed, f});
    ctx.unc().recordCore(cpy, cp, {Operand{seed, true}, Operand{f, true}}, fid);
    ctx.emitCore(abi::CoreSpec{abi::Core::AbortI1, i1}, {f});
    ctx.unc().setRole(fid, Role::Abort);
  } else if (rKeptRt) {
    // the rolled driver kept a_K's copy where K < B (its role set there)
  } else if (keep) {
    ctx.unc().setRole(ctx.unc().idOf(q), Role::KeptOverflow);
  }
  if (armKept)
    ctx.unc().setRole(ctx.unc().idOf(armKept), Role::KeptOverflow);

  chainEnd = q;
  stopped = stopAcc;
  // Exit values (body form): the final state of the header phi.
  auto exitOf = [&](PHINode *h) {
    if (auto qt = qind.find(h); qt != qind.end()) {
      if (!qt->second.exitRail)
        internalError("loops-cutoff: an affine induction's exit value with no exit rail", h);
      return *qt->second.exitRail;
    }
    auto it = exitRail.find(h);
    return it != exitRail.end() ? it->second : ctx.operand(h);
  };
  // Every exit value is read before any is rebound (cq-pntr): a value read after the loop may itself be a header phi
  // another carried value takes as its latch value (`p = x; x = f(x)`: p's exit value is x's header phi of the exit trip),
  // and rebinding it first would make x's exit value read p's.
  // The exit block's phis read theirs before the rebinds too.
  std::vector<Operand> exitVals, exitPhiVals;
  exitVals.reserve(exitRebinds.size());
  for (auto &[v, h] : exitRebinds)
    exitVals.push_back(exitOf(h));
  exitPhiVals.reserve(exitPhis.size());
  for (auto &[P, h] : exitPhis)
    exitPhiVals.push_back(exitOf(h));
  // cq-9kcq S7: the region form's quantum values read after the loop (the last region evaluation, frozen once the loop
  // exited) are X's state in the rolled form: rails of the region, wired out with the exit values.
  std::vector<std::pair<Instruction *, Operand>> regionVals;
  if (rreg && regionForm)
    for (Instruction *I : regionQReads)
      if (ctx.bound(I) && none_of(exitRebinds, [&](const std::pair<const Value *, PHINode *> &e) { return e.first == I; }))
        regionVals.push_back({I, ctx.operand(I)});
  if (rreg) {
    // cq-9kcq S3b: the rolled loop's exit (the builder at its exit block X).
    std::vector<std::pair<const Value *, Operand>> out;
    std::vector<RailType> outW;
    DenseMap<const Value *, Operand *> slot;
    // cq-9kcq S6c: a rail read after the loop under several names (an exit rebind and an exit phi of one carried value) is
    // wired once: with the zero-trip guard it is X's merge, which is copied out, and a second copy would be left live.
    DenseMap<const Value *, const Value *> firstOf;
    std::vector<std::pair<Operand *, const Value *>> dups;
    // cq-9kcq S21: a field of an aggregate value is wired under its own key (its rail at X), which names the value
    DenseMap<const Value *, const Value *> fieldOf;
    auto valueOf = [&](const Value *v) { return fieldOf.lookup(v) ? fieldOf.lookup(v) : v; };
    auto add = [&](const Value *v, Operand &o, std::optional<RailType> w = std::nullopt) {
      if (!o.handle)
        return;
      if (auto it = firstOf.find(o.v); it != firstOf.end()) {
        dups.push_back({&o, it->second});
        return;
      }
      // A carried value no trip changes (a register rotated in place, rule 10: its header phi names its entry rail on every
      // edge) is that rail after the loop, read in place: the reverse never touches a rail from before the loop. One the
      // seed scope minted is the region's (wireExits keeps it as the register).
      if (auto *ph = dyn_cast<PHINode>(o.v); ph && ph->getParent() == rHead) {
        Value *one = nullptr;
        bool single = true;
        for (Value *in : ph->incoming_values())
          if (in != ph && in != one)
            single = single && !one, one = in;
        if (single && one && none_of(ctx.unc().scopeRecords(rSeedScope), [&](const Record &r) { return r.forward == one; })) {
          o = Operand{one, true};
          return;
        }
      }
      firstOf[o.v] = v;
      out.push_back({v, o});
      outW.push_back(w ? *w : railOf(v->getType()));
      slot[v] = &o;
    };
    for (size_t k = 0; k < exitRebinds.size(); ++k)
      add(exitRebinds[k].first, exitVals[k]);
    for (size_t k = 0; k < exitPhis.size(); ++k)
      add(exitPhis[k].first, exitPhiVals[k]);
    for (auto &[I, o] : regionVals)
      add(I, o);
    // cq-9kcq S8: the multi-exit accumulators, read after the loop (bound below from the wired operands).
    for (CPhi &cp : cphis)
      add(cp.P, cp.acc);
    for (XAcc &xa : xaccs)
      if (!xa.V->getType()->isAggregateType() && !xa.V->getType()->isVectorTy())
        add(xa.V, xa.acc[0]);
      else
        for (size_t k = 0; k < xa.acc.size(); ++k) {
          fieldOf[xa.acc[k].v] = xa.V;
          add(xa.acc[k].v, xa.acc[k], xa.rails[k]);
        }
    // cq-9kcq S12c: the environment's pieces at X, named by eff-fenv's keys (i32 rails: FLAGS, MODE)
    for (auto &[id, o] : rFenv)
      add(fenv::pieceKey(ctx, id), o, RailType{Kind::Int, 32});
    auto afterEnd = [&](const Value *v) { return rolled::readAfterInvertEnd(L, valueOf(v)); };
    rolled::Region::ExitWiring wiring = rreg->wireExits(
        rSeedScope, out, outW, nullptr, rKeptFinal,
        [&](const Value *v) {
          v = valueOf(v);
          // cq-9kcq S12c: the environment after the loop is read by eff-fenv until it is replaced; rule 5 uncomputes a copy
          // after that reader, as any value only computed from
          if (any_of(rFenv, [&](const std::pair<unsigned, Operand> &p) { return fenv::pieceKey(ctx, p.first) == v; }))
            return true;
          // cq-9kcq S6c (as loops-classical's `undone`, rule 5, rule 18): a clone's result is copied out once more at the
          // return, and its twin needs that copy: the loop's copy is no output, undone by the reverse after its readers.
          if (!ctx.S.isEntry()) {
            SmallVector<const Value *, 4> work{v};
            SmallPtrSet<const Value *, 8> seen{v};
            while (!work.empty()) {
              const Value *x = work.pop_back_val();
              for (const User *u : x->users()) {
                if (isa<ReturnInst>(u))
                  return true;
                if (isa<PHINode>(u) && !L.contains(cast<Instruction>(u)) && seen.insert(u).second)
                  work.push_back(u);
              }
            }
          }
          // cq-shndm (CR rules 5, 14, 19): an entry's return of a continuation phi the walker joins classically with an
          // incoming from outside the unit (joinUnitPhi: the classical skip of a K-loop behind `n == 0`, a phi over
          // handles) returns a copy of that join (emitReturn's rule-14 copy-out): the loop's copy is no output either.
          if (auto *P = dyn_cast<PHINode>(v);
              P && any_of(cphis, [&](const CPhi &cp) { return cp.P == P; }) &&
              any_of(P->users(), [](const User *u) { return isa<ReturnInst>(u); }) &&
              any_of(P->blocks(), [&](BasicBlock *u) { return !U.contains(L, u) && A.DT.isReachableFromEntry(u); }))
            return true;
          return !rolled::readersKeep(ctx, L, v);
        },
        [&](const Value *v, Operand op) { *slot.lookup(v) = op; },
        // cq-n1hy7 (CR rules 6, 14): an exit value the trip makes (a capture rail, a carried value's latch value, a region
        // value) that the code after the loop may clean by rule 6 is copied out: the reverse undoes every trip's instance.
        [&](const Value *v) {
          if (any_of(rFenv, [&](const std::pair<unsigned, Operand> &p) { return fenv::pieceKey(ctx, p.first) == v; }))
            return false;
          return rolled::cleanedAfter(L, valueOf(v));
        },
        // cq-037u2 (CR rule 17 with rule 14): inside an open cq_invert region, a value read after its end is a kept copy
        ctx.unc().invertOpen() ? function_ref<bool(const Value *)>(afterEnd) : function_ref<bool(const Value *)>());
    for (auto &[o, first] : dups)
      *o = *slot.lookup(first);
    for (auto &[id, o] : rFenv)
      fenv::bindPiece(ctx, id, o.v);
    auto isFenvKey = [&](const Value *v) {
      return any_of(rFenv, [&](const std::pair<unsigned, Operand> &p) { return fenv::pieceKey(ctx, p.first) == v; });
    };
    bool keptInPlace = rreg->hasCopyScope() && any_of(out, [&](const std::pair<const Value *, Operand> &o) {
      return o.second.handle && !rKeptFinal.count(o.second.v) && wiring.ownedH.count(o.second.v) && !isFenvKey(o.first) &&
             rolled::readersKeep(ctx, L, valueOf(o.first));
    });
    rreg->finishExits(rCont ? rCont : rX, rSeedScope, wiring, keptInPlace, latch->getTerminator(), rreg, rX);
  } else if (!top) {
    // cq-9kcq S11 (CR rules 2, 5, 14): a nested rolled K-loop's exit value is a rail of one record of its trip, made again in
    // every trip, which the enclosing reverse mirrors per trip. A reader after the loop that keeps the rail it reads (a
    // measurement in place, a stored value, a return: rolled::readersKeep's keepers) would keep that record in every trip
    // (me_outer: the K-1 earlier trips' selects left as garbage). Such a value is copied at X (alloc + copy, a record of the
    // enclosing trip's segment): the reader keeps the copy and the loop's records are undone as any other.
    auto keeps = [&](const Value *v) {
      SmallVector<const Value *, 4> work{v};
      SmallPtrSet<const Value *, 8> seen{v};
      while (!work.empty()) {
        const Value *x = work.pop_back_val();
        for (const User *u : x->users()) {
          auto *ui = dyn_cast<Instruction>(u);
          if (!ui || L.contains(ui))
            continue;
          if (auto *P = dyn_cast<PHINode>(ui)) {
            if (seen.insert(P).second)
              work.push_back(P);
            continue;
          }
          if (isa<ReturnInst>(ui))
            return true;
          if (auto *st = dyn_cast<StoreInst>(ui); st && st->getValueOperand() == x)
            return true;
          if (auto *CB = dyn_cast<CallBase>(ui); CB && calls::classify(*CB, ctx.T, ctx.S) == calls::Class::Measure &&
                                                 !ctx.S.table && !ctx.S.ctl &&
                                                 spine::measuredOnEveryPath(ctx, CB->getArgOperand(0)))
            return true;
        }
      }
      return false;
    };
    DenseMap<Value *, Value *> copyOf;
    auto copyOut = [&](const Value *v, Operand &o, std::optional<RailType> fw = std::nullopt) {
      if (!o.handle || rKeptFinal.count(o.v) || !keeps(v))
        return;
      if (Value *c = copyOf.lookup(o.v)) {
        o = Operand{c, true};
        return;
      }
      RailType w = fw ? *fw : railOf(v->getType());
      CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                 {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
      RailId fid = ctx.unc().recordSeed(f);
      abi::CoreSpec cp{abi::Core::Copy, w};
      CallInst *cpy = ctx.emitCore(cp, {o.v, f});
      ctx.unc().recordCore(cpy, cp, {o, Operand{f, true}}, fid);
      copyOf[o.v] = f;
      o = Operand{f, true};
    };
    for (size_t k = 0; k < exitRebinds.size(); ++k)
      copyOut(exitRebinds[k].first, exitVals[k]);
    for (size_t k = 0; k < exitPhis.size(); ++k)
      copyOut(exitPhis[k].first, exitPhiVals[k]);
    for (auto &[I, o] : regionVals)
      copyOut(I, o);
    for (CPhi &cp : cphis)
      copyOut(cp.P, cp.acc);
    for (XAcc &xa : xaccs)
      if (!xa.V->getType()->isAggregateType() && !xa.V->getType()->isVectorTy())
        copyOut(xa.V, xa.acc[0]);
      else
        for (size_t k = 0; k < xa.acc.size(); ++k)
          copyOut(xa.V, xa.acc[k], xa.rails[k]);   // cq-9kcq S21: one copy per field
  }
  for (auto &[I, o] : regionVals)
    ctx.rebind(I, {o});
  for (size_t k = 0; k < exitRebinds.size(); ++k) {
    const Value *v = exitRebinds[k].first;
    // A value only the trips bind (not bound before the loop) is bound here for the first time.
    if (ctx.bound(v))
      ctx.rebind(v, {exitVals[k]});
    else
      ctx.bindFields(v, {exitVals[k]});
  }
  for (size_t k = 0; k < exitPhis.size(); ++k) {
    PHINode *P = exitPhis[k].first;
    Operand f = exitPhiVals[k];
    unitBound.insert(P);
    if (top)
      ctx.bindFields(P, {f});
    else
      set(P, f);
  }
  for (CPhi &cp : cphis) {
    unitBound.insert(cp.P);
    if (!top)
      set(cp.P, cp.acc);   // a nested unit: bound once per outer trip
    else if (ctx.bound(cp.P))
      ctx.rebind(cp.P, {cp.acc});   // an earlier unit's binding, its value the initial of this one's
    else
      ctx.bindFields(cp.P, {cp.acc});
  }
  for (XAcc &xa : xaccs)
    bindCapture(xa);
}

} // namespace

// Rule 14: is v of the guard the latch test's operand w one step before the test of trip 0, "the same expression
// over SCEV-equal operands, a load equal to a load of the same type at a SCEV-equal address when no memory version
// change lies between the guard and the loop header"?
static bool equalAtTripZero(const Value *v, const Value *w, const Loop &L, ScalarEvolution &SE, BasicBlock *guard) {
  if (v == w)
    return true;
  if (v->getType() != w->getType())
    return false;
  auto *lv = dyn_cast<LoadInst>(v);
  auto *lw = dyn_cast<LoadInst>(w);
  if (lv && lw) {
    if (lv->getParent() != guard || !equalAtTripZero(lv->getPointerOperand(), lw->getPointerOperand(), L, SE, guard))
      return false;
    BasicBlock *h = L.getHeader();
    for (const BasicBlock *b = guard; b && b != h; b = b->getSingleSuccessor())
      for (const Instruction &I : *b)
        if (I.mayWriteToMemory() && (b != guard || cq::comesBefore(lv, &I)))
          return false;
    return true;
  }
  if (!SE.isSCEVable(v->getType()))
    return false;
  const SCEV *sw = SE.getSCEV(const_cast<Value *>(w));
  if (auto *ar = dyn_cast<SCEVAddRecExpr>(sw); ar && ar->getLoop() == &L && ar->isAffine()) {
    const SCEV *step = ar->getStepRecurrence(SE);
    if (!SE.isLoopInvariant(step, &L))
      return false;
    sw = SE.getMinusSCEV(ar->getStart(), step);
  } else if (!SE.isLoopInvariant(sw, &L)) {
    return false;
  }
  return SE.getSCEV(const_cast<Value *>(v)) == sw;
}

// Rule 14: "the pre-header guard is trip 0 of the latch test": the guard's test for entering is the latch's test for
// another trip at the trip before the first. Else the guard stays an arm flag that seeds the chain (55).
static bool guardIsTripZero(const Loop &L, ScalarEvolution &SE) {
  BasicBlock *h = L.getHeader(), *latch = L.getLoopLatch(), *gb = L.getLoopPredecessor();
  if (!latch || !gb)
    return false;
  BasicBlock *entry = h;
  if (auto *ub = dyn_cast<BranchInst>(gb->getTerminator()); ub && ub->isUnconditional() && gb->getSinglePredecessor()) {
    entry = gb;
    gb = gb->getSinglePredecessor();
  }
  auto *gbr = dyn_cast<BranchInst>(gb->getTerminator());
  auto *lbr = dyn_cast<BranchInst>(latch->getTerminator());
  if (!gbr || !lbr || !gbr->isConditional() || !lbr->isConditional())
    return false;
  auto *gc = dyn_cast<ICmpInst>(gbr->getCondition());
  auto *lc = dyn_cast<ICmpInst>(lbr->getCondition());
  if (!gc || !lc)
    return false;
  bool gTrue = gbr->getSuccessor(0) == entry, lTrue = lbr->getSuccessor(0) == h;
  if (gTrue == (gbr->getSuccessor(1) == entry) || lTrue == (lbr->getSuccessor(1) == h))
    return false;
  CmpInst::Predicate pg = gTrue ? gc->getPredicate() : gc->getInversePredicate();
  CmpInst::Predicate pl = lTrue ? lc->getPredicate() : lc->getInversePredicate();
  if (pg == pl && equalAtTripZero(gc->getOperand(0), lc->getOperand(0), L, SE, gb) &&
      equalAtTripZero(gc->getOperand(1), lc->getOperand(1), L, SE, gb))
    return true;
  return pg == CmpInst::getSwappedPredicate(pl) && equalAtTripZero(gc->getOperand(0), lc->getOperand(1), L, SE, gb) &&
         equalAtTripZero(gc->getOperand(1), lc->getOperand(0), L, SE, gb);
}

// Owner ruling Q2 of 2026-11-14 (cq-9kcq; CR 1.4 "Received K", rule 27 "Cutoff": "calls inside the library are rule 18's
// and pass the received K down"). Can a table clone of this module reach the function being lowered by name? Decided per
// function, conservatively: every defined function a direct call reaches, transitively, from the body of a function taint
// gives a table clone (a function reached from elsewhere as well loads @__cq_k too, and reads -1 = no cut there). The
// table function itself is reached only through a call by name of it.
// The set is walked once per module's constructions (keyed as calls::mintSites keys its memo): it reads original bodies
// only, which no construct() edits (an entry's lowered body replaces it after the last one, spine finishEntries).
static bool reachedFromTable(LoweringContext &ctx) {
  static thread_local struct {
    const Module *M = nullptr;
    const void *specs = nullptr;
    DenseSet<const Function *> reached;
  } memo;
  if (memo.M == &ctx.M && memo.specs == ctx.T.specializations().data())
    return memo.reached.count(ctx.S.F) != 0;
  DenseSet<const Function *> reached;
  SmallVector<const Function *, 32> work;
  for (const Specialization &S : ctx.T.specializations())
    if (S.table && S.F)
      work.push_back(S.F);
  SmallPtrSet<const Function *, 32> walked;
  while (!work.empty()) {
    const Function *F = work.pop_back_val();
    if (!walked.insert(F).second || F->isDeclaration())
      continue;
    for (const Instruction &I : instructions(*F))
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (const Function *G = CB->getCalledFunction(); G && !G->isDeclaration() && reached.insert(G).second)
          work.push_back(G);
  }
  memo.M = &ctx.M;
  memo.specs = ctx.T.specializations().data();
  memo.reached = std::move(reached);
  return memo.reached.count(ctx.S.F) != 0;
}

// Owner ruling Q2 as corrected 2026-11-15 (CR §1.4 "Received K": a value other than all ones is the K of that
// activation, in place of its own, whether smaller or larger): in a function a table clone can reach by name, the K its
// K-loops are cut at: @__cq_k loaded once on entry (the first block of the function lowered), then
// select(ld == -1, K, ld) with K the loop's own.
static Value *loadedReceivedK(LoweringContext &ctx, unsigned K) {
  GlobalVariable *g = exits::receivedKGlobal(ctx.M);
  Type *i32 = Type::getInt32Ty(ctx.M.getContext());
  BasicBlock &E = ctx.out().getEntryBlock();
  LoadInst *ld = nullptr;
  for (Instruction &I : E)
    if (auto *l = dyn_cast<LoadInst>(&I); l && l->getPointerOperand() == g) {
      ld = l;
      break;
    }
  if (!ld) {
    BasicBlock::iterator at = E.getFirstInsertionPt();
    while (at != E.end() && isa<AllocaInst>(*at))
      ++at;
    IRBuilder<> EB(&E, at);
    ld = EB.CreateLoad(i32, g);
  }
  Constant *k = ConstantInt::get(i32, K);
  Constant *none = ConstantInt::getAllOnesValue(i32);
  ICmpInst *is = nullptr;
  for (User *u : ld->users())
    if (auto *c = dyn_cast<ICmpInst>(u);
        c && c->getPredicate() == ICmpInst::ICMP_EQ && c->getOperand(0) == ld && c->getOperand(1) == none) {
      is = c;
      break;
    }
  if (is)
    for (User *u : is->users())
      if (auto *S = dyn_cast<SelectInst>(u);
          S && S->getCondition() == is && S->getTrueValue() == k && S->getFalseValue() == ld)
        return S;
  if (!is) {
    IRBuilder<> EB(ld->getParent(), std::next(ld->getIterator()));   // cq-bh7xh: the entry block may still be open
    is = cast<ICmpInst>(EB.CreateICmpEQ(ld, none));
  }
  IRBuilder<> EB(is->getParent(), std::next(is->getIterator()));
  return EB.CreateSelect(is, k, ld);
}

// cq-9kcq: the K a K-loop of the function being lowered is cut at, or nullptr: a table clone's received K (its trailing
// classical i32, CR §1.4), or in a function a table clone reaches by name the loaded one (owner ruling Q2).
static Value *receivedKOf(LoweringContext &ctx, unsigned K) {
  if (ctx.S.table)
    return spine::shared(ctx).tableK;
  return exits::receivedKBelow(ctx, K);
}

void lowerCutoff(LoweringContext &ctx, Loop &L, unsigned K, std::optional<uint64_t> B) {
  Function &F = *L.getHeader()->getParent();
  Analyses A(F);
  Loop *mL = A.LI.getLoopFor(L.getHeader());
  if (!mL || mL->getHeader() != L.getHeader())
    internalError("loops-cutoff: the loop is not a natural loop of the function's LoopInfo", L.getHeader());
  unsigned c = B ? unsigned(std::min<uint64_t>(K, *B)) : K;
  Value *seed = ctx.currentFlag();
  if (!seed) {
    LLVMContext &C = ctx.M.getContext();
    CallInst *s = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}}, {ConstantInt::getTrue(C)});
    ctx.unc().recordSeed(s);
    seed = s;
  }
  Cutoff U(ctx, A);
  U.seedPred = ctx.currentPredicate();
  U.receivedK = receivedKOf(ctx, K);   // cq-9kcq: CR rule 27 "Cutoff", §1.4, owner ruling Q2
  U.bound = B;
  spine::Shared &sh = spine::shared(ctx);
  Value *savedZero = sh.tripZeroRail, *savedZQ = sh.rolledZeroQ, *savedZJ = sh.rolledZeroJ;
  if (guardIsTripZero(*mL, A.SE))
    sh.tripZeroRail = seed;   // the chain's a_0 stays as the control of a kept store of trip 0 (rule 14, 91)
  U.lowerLoop(*mL, seed, c, !B || *B > K, true);
  sh.tripZeroRail = savedZero;
  sh.rolledZeroQ = savedZQ;
  sh.rolledZeroJ = savedZJ;
}

namespace exits {

Value *receivedKBelow(LoweringContext &ctx, unsigned K) {
  if (ctx.S.table || !reachedFromTable(ctx))
    return nullptr;
  return loadedReceivedK(ctx, K);
}

GlobalVariable *receivedKGlobal(Module &M) {
  constexpr const char *name = "__cq_k";
  if (GlobalVariable *g = M.getGlobalVariable(name, /*AllowInternal=*/true))
    return g;
  Type *i32 = Type::getInt32Ty(M.getContext());
  auto *g = new GlobalVariable(M, i32, false, GlobalValue::InternalLinkage, ConstantInt::get(i32, -1, true), name);
  g->setAlignment(Align(4));
  return g;
}

// Is the initial value of p a rail this function made for itself (a template result, or a classical
// value cq_theta minted, rotated in place any number of times) that nothing reads once the loop is
// entered? Its readers other than p and its own rotations must be phi incomings on edges no path
// from the loop reaches (the zero-trip edge of the loop's guard).
bool initDead(LoweringContext &ctx, Loop &L, const Value *init, const PHINode *p) {
  auto isQ = [&](const Value *v) { return !isa<Constant>(v) && ctx.T.isQuantum(v, ctx.S); };
  if (!isQ(init))
    return true;   // a seed minted for the loop
  SmallVector<const Instruction *, 4> A;
  for (const Value *x = init;;) {
    auto *I = dyn_cast<Instruction>(x);
    if (!I)
      return false;
    A.push_back(I);
    if (auto *CB = dyn_cast<CallInst>(I); CB && calls::classify(*CB, ctx.T, ctx.S) == calls::Class::Theta) {
      if (isQ(CB->getArgOperand(1)))
        return false;
      x = CB->getArgOperand(0);
      if (!isQ(x))
        break;   // minted by this cq_theta
      continue;
    }
    if (isa<BinaryOperator>(I) || isa<UnaryOperator>(I))
      break;
    return false;
  }
  DenseSet<const BasicBlock *> reach;
  SmallVector<const BasicBlock *, 16> work{L.getHeader()};
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    if (!reach.insert(b).second)
      continue;
    for (const BasicBlock *s : successors(b))
      work.push_back(s);
  }
  for (const Instruction *a : A)
    for (const Use &u : a->uses()) {
      const User *usr = u.getUser();
      if (usr == p || is_contained(A, usr))
        continue;
      auto *phi = dyn_cast<PHINode>(usr);
      if (!phi || reach.count(phi->getIncomingBlock(u)))
        return false;
    }
  return true;
}


Value *lowerNestedCutoff(LoweringContext &ctx, Loop &L, Value *seed, const std::function<void(BasicBlock *)> &segHook,
                         Value *test0, rolled::Region *region) {
  Function &F = *L.getHeader()->getParent();
  Analyses A(F);
  Loop *mL = A.LI.getLoopFor(L.getHeader());
  if (!mL || mL->getHeader() != L.getHeader())
    internalError("loops-cutoff: the loop is not a natural loop of the function's LoopInfo", L.getHeader());
  if (!seed)
    internalError("loops-cutoff: a nested K-loop with no seed", L.getHeader());
  unsigned K = ctx.K(mL);
  std::optional<uint64_t> B = cutoffBound(*mL, A.SE, ctx.S);
  unsigned c = B ? unsigned(std::min<uint64_t>(K, *B)) : K;
  Cutoff C(ctx, A);
  C.segHook = segHook;
  C.rolledTrip = region;   // cq-9kcq S11: L rolls inside the classically bounded loop's region
  C.test0 = test0;
  C.receivedK = receivedKOf(ctx, K);   // cq-9kcq: CR rule 27 "Cutoff", §1.4, owner ruling Q2
  C.bound = B;
  C.lowerLoop(*mL, seed, c, !B || *B > K, false);
  return C.stopRail();
}

namespace {
// A loop's unit and hasNoreturnArm depend only on the natural loop of its header in F: during construct()'s run over F
// (frozenEpoch) they are kept per header (callers make their own LoopInfo objects, so never per Loop*).
template <typename V> struct HeaderMemo {
  uint64_t epoch = 0;
  DenseMap<const BasicBlock *, V> m;
  template <typename Fn> V get(const Loop &L, Fn compute) {
    const BasicBlock *h = L.getHeader();
    uint64_t e = frozenEpoch(*h->getParent());
    if (!e)
      return compute();
    if (epoch != e) {
      m.clear();
      epoch = e;
    }
    if (auto it = m.find(h); it != m.end())
      return it->second;
    V v = compute();
    m.try_emplace(h, v);
    return v;
  }
};
thread_local HeaderMemo<Unit> unitMemo;
thread_local HeaderMemo<bool> noreturnMemo;
Unit computeUnit(const Loop &L);
bool computeNoreturnArm(const Loop &L);
} // namespace

bool hasNoreturnArm(const Loop &L) { return noreturnMemo.get(L, [&] { return computeNoreturnArm(L); }); }

Unit unitOf(const Loop &L) { return unitMemo.get(L, [&] { return computeUnit(L); }); }

namespace {
bool computeNoreturnArm(const Loop &L) {
  BasicBlock *h = L.getHeader();
  DominatorTree DT(*h->getParent());
  LoopInfo LI(DT);
  SmallVector<BasicBlock *, 16> blocks(L.blocks().begin(), L.blocks().end());
  Unit top = unitOf(L);
  blocks.append(top.arm.begin(), top.arm.end());
  for (BasicBlock *b : blocks)
    for (Loop *l = LI.getLoopFor(b); l; l = l->getParentLoop()) {
      if (l->contains(h) && l->getHeader() != h)
        break;
      if (!unitOf(*l).abort.empty())
        return true;
      if (l->getHeader() == h)
        break;
    }
  return false;
}
} // namespace

Pred tripEdge(const BasicBlock *p, const BasicBlock *b) {
  const Instruction *t = p->getTerminator();
  if (auto *br = dyn_cast<BranchInst>(t)) {
    if (!br->isConditional() || br->getSuccessor(0) == br->getSuccessor(1))
      return Pred::top();
    Pred a = Pred::atom(br->getCondition());
    return br->getSuccessor(0) == b ? a : !a;
  }
  if (auto *sw = dyn_cast<SwitchInst>(t)) {
    Pred e = Pred::bottom(), none = Pred::top();
    for (auto &c : sw->cases()) {
      Pred a = Pred::eqAtom(sw->getCondition(), c.getCaseValue()->getValue());
      none = none & !a;
      if (c.getCaseSuccessor() == b)
        e = e | a;
    }
    if (sw->getDefaultDest() == b)
      e = e | none;
    return e;
  }
  if (auto *ib = dyn_cast<IndirectBrInst>(t))
    return computedGotoEdge(*ib, b);
  (void)t;
  internalError("loops-cutoff: a trip edge from a terminator that is no br, switch or computed goto", t);
}

Value *classicalEdge(LoweringContext &ctx, const BasicBlock *p, const BasicBlock *b) {
  auto isQ = [&](const Value *v) { return !isa<Constant>(v) && ctx.T.isQuantum(v, ctx.S); };
  IRBuilder<> &Bd = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  const Instruction *t = p->getTerminator();
  if (auto *br = dyn_cast<BranchInst>(t)) {
    if (!br->isConditional() || br->getSuccessor(0) == br->getSuccessor(1) || isQ(br->getCondition()))
      return ConstantInt::getTrue(C);
    Value *c = ctx.operand(br->getCondition()).v;
    return br->getSuccessor(0) == b ? c : Bd.CreateNot(c);
  }
  if (auto *ib = dyn_cast<IndirectBrInst>(t)) {
    // Rule 13: the address against each destination's blockaddress; the last distinct destination is
    // the complement of the others.
    if (isQ(ib->getAddress()))
      return ConstantInt::getTrue(C);
    Value *a = ctx.operand(ib->getAddress()).v;
    Value *x = a->getType()->isPointerTy() ? Bd.CreatePtrToInt(a, Bd.getInt64Ty()) : a;
    SmallVector<const BasicBlock *, 4> ds;
    for (const BasicBlock *d : successors(ib))
      if (!is_contained(ds, d))
        ds.push_back(d);
    Value *others = ConstantInt::getFalse(C);
    for (const BasicBlock *d : ds) {
      if (d == ds.back())
        return d == b ? Bd.CreateNot(others) : ConstantInt::getFalse(C);
      Value *e = Bd.CreateICmpEQ(x, caseAddress(d));
      if (d == b)
        return e;
      others = Bd.CreateOr(others, e);
    }
    return ConstantInt::getFalse(C);
  }
  auto *sw = cast<SwitchInst>(t);
  if (isQ(sw->getCondition()))
    return ConstantInt::getTrue(C);
  Value *x = ctx.operand(sw->getCondition()).v;
  Value *e = ConstantInt::getFalse(C), *none = ConstantInt::getTrue(C);
  for (auto &c : sw->cases()) {
    Value *a = Bd.CreateICmpEQ(x, const_cast<ConstantInt *>(c.getCaseValue()));
    none = Bd.CreateAnd(none, Bd.CreateNot(a));
    if (c.getCaseSuccessor() == b)
      e = Bd.CreateOr(e, a);
  }
  if (sw->getDefaultDest() == b)
    e = Bd.CreateOr(e, none);
  return e;
}

bool boundByLoopBefore(LoweringContext &ctx, const PHINode &h, const LoopInfo &LI) {
  if (!ctx.bound(&h))
    return false;
  const Loop *own = LI.getLoopFor(h.getParent());
  for (const BasicBlock *u : h.blocks()) {
    if (own && own->contains(u))
      continue;
    for (const Loop *l = LI.getLoopFor(u); l && !l->contains(h.getParent()); l = l->getParentLoop())
      if (unitOf(*l).cont == h.getParent())
        return true;
  }
  return false;
}

bool Unit::contains(const Loop &L, const BasicBlock *b) const {
  return L.contains(b) || is_contained(arm, b) || is_contained(abort, b);
}

// cq-fi2wc: the nearest block every path from each of xs to a return passes, paths into a dead end (no return reachable)
// set aside; nullptr when there is none. Iterative post-dominator sets over the blocks that reach a return.
// cq-1jev3: a block of `ends` ends a path as a return does (an enclosing loop's header: the end of its trip).
static BasicBlock *nearestPostDomPastDeadEnds(Function &F, ArrayRef<BasicBlock *> xs,
                                              const SmallPtrSetImpl<const BasicBlock *> &ends = SmallPtrSet<const BasicBlock *, 1>()) {
  auto isEnd = [&](const BasicBlock *b) { return isa<ReturnInst>(b->getTerminator()) || ends.count(b); };
  DenseMap<const BasicBlock *, unsigned> idx;
  std::vector<BasicBlock *> alive;
  SmallVector<BasicBlock *, 16> work;
  for (BasicBlock &b : F)
    if (isEnd(&b)) {
      idx[&b] = alive.size();
      alive.push_back(&b);
      work.push_back(&b);
    }
  while (!work.empty())
    for (BasicBlock *p : predecessors(work.pop_back_val()))
      if (idx.try_emplace(p, alive.size()).second) {
        alive.push_back(p);
        work.push_back(p);
      }
  for (BasicBlock *x : xs)
    if (!idx.count(x))
      return nullptr;
  const unsigned n = alive.size();
  std::vector<BitVector> pd(n, BitVector(n, true));
  for (unsigned i = 0; i < n; ++i)
    if (isEnd(alive[i])) {
      pd[i].reset();
      pd[i].set(i);
    }
  for (bool changed = true; changed;) {
    changed = false;
    for (unsigned i = 0; i < n; ++i) {   // found order, from the returns backwards: mostly successors first
      if (isEnd(alive[i]))
        continue;
      BitVector v(n, true);
      for (BasicBlock *s : successors(alive[i]))
        if (auto it = idx.find(s); it != idx.end())
          v &= pd[it->second];
      v.set(i);
      if (v != pd[i]) {
        pd[i] = std::move(v);
        changed = true;
      }
    }
  }
  BitVector common(n, true);
  for (BasicBlock *x : xs)
    common &= pd[idx.lookup(x)];
  // The post-dominators common to all of xs form a chain: the nearest has the most post-dominators of its own.
  int best = -1;
  for (int i = common.find_first(); i >= 0; i = common.find_next(i))
    if (best < 0 || pd[i].count() > pd[best].count())
      best = i;
  return best < 0 ? nullptr : alive[best];
}

namespace {
Unit computeUnit(const Loop &L) {
  Unit U;
  SmallVector<BasicBlock *, 4> exitBlocks;
  L.getUniqueExitBlocks(exitBlocks);
  // The noreturn arm blocks, collected from each effectful dead end.
  SmallPtrSet<BasicBlock *, 8> abortSet;
  for (BasicBlock *x : exitBlocks) {
    // A dead end: no path from x reaches a return or the loop again. One with no effect is UB to reach;
    // one with an effect is a noreturn arm (rule 16), run per trip under its exit flag.
    bool live = false, effect = false;
    SmallVector<BasicBlock *, 8> work{x};
    SmallSetVector<BasicBlock *, 8> seen;   // found order: U.dead comes out in it
    seen.insert(x);
    while (!work.empty() && !live) {
      BasicBlock *b = work.pop_back_val();
      if (L.contains(b) || isa<ReturnInst>(b->getTerminator())) {
        live = true;
        break;
      }
      for (Instruction &I : *b) {
        if (isa<DbgInfoIntrinsic>(I))
          continue;
        if (auto *II = dyn_cast<IntrinsicInst>(&I); II && II->isLifetimeStartOrEnd())
          continue;
        if (isa<CallBase>(I) || I.mayHaveSideEffects() || I.mayWriteToMemory())
          effect = true;
      }
      for (BasicBlock *s : successors(b))
        if (seen.insert(s))
          work.push_back(s);
    }
    if (live) {
      U.live.push_back(x);
      continue;
    }
    if (effect) {
      abortSet.insert(seen.begin(), seen.end());
      continue;
    }
    for (BasicBlock *b : seen)
      if (!is_contained(U.dead, b))
        U.dead.push_back(b);
  }
  if (!abortSet.empty()) {
    // A dead block reached from a noreturn arm too is part of that arm (it runs only after its effect).
    for (BasicBlock *b : abortSet)
      if (auto it = find(U.dead, b); it != U.dead.end())
        U.dead.erase(it);
    // Topological order over the arm's blocks (an arm runs once per exit: a cycle in it is a loop of the
    // arm, a natural loop the walker would dispatch; the arm's own blocks come in DFS reverse post-order,
    // back edges dropped, and the loop module lowers a block once per trip).
    SmallPtrSet<BasicBlock *, 8> done;
    std::vector<BasicBlock *> post;
    std::function<void(BasicBlock *)> dfs = [&](BasicBlock *b) {
      done.insert(b);
      for (BasicBlock *s : successors(b))
        if (abortSet.count(s) && !done.count(s))
          dfs(s);
      post.push_back(b);
    };
    for (BasicBlock *x : exitBlocks)
      if (abortSet.count(x) && !done.count(x))
        dfs(x);
    for (auto it = post.rbegin(); it != post.rend(); ++it)
      U.abort.push_back(*it);
  }
  if (U.live.empty())
    return U;   // no live exit: no continuation (CR rule 14 "No live exit")
  if (U.live.size() == 1) {
    U.cont = U.live.front();
    return U;
  }
  Function &F = *L.getHeader()->getParent();
  PostDominatorTree PDT(F);
  BasicBlock *c = U.live.front();
  for (BasicBlock *x : U.live)
    if (!(c = PDT.findNearestCommonDominator(c, x)))
      break;
  // cq-fi2wc: LLVM's post-dominators end a path at an `unreachable` too, so a dead end between the exits and their meeting
  // point (pow_equals: an ASSERT's noreturn call in the code after the loop) leaves them none. A path into a dead end is no
  // path of the program's continuation (as an exit into one is no exit above): C is their nearest common post-dominator
  // over the paths that reach a return.
  if (!c)
    c = nearestPostDomPastDeadEnds(F, U.live);
  // cq-1jev3 (CR rule 14, nested loops): C lies on every exit's way on, never past the loop itself. Where an exit reaches the
  // post-dominator only through the loop again (an exit that is an enclosing loop's back edge; in an enclosing loop with no
  // exit LLVM's post-dominators run through the loop), the exits meet at the end of the enclosing trip: C is the nearest
  // block every path passes up to a return or an enclosing loop's header (that header when they meet only there).
  auto onWay = [&](BasicBlock *x) {
    SmallVector<BasicBlock *, 8> work{x};
    SmallPtrSet<BasicBlock *, 8> seen{x};
    while (!work.empty()) {
      BasicBlock *b = work.pop_back_val();
      if (b == c)
        return true;
      for (BasicBlock *s : successors(b))
        if (!L.contains(s) && seen.insert(s).second)
          work.push_back(s);
    }
    return false;
  };
  if (c && L.getParentLoop() && !all_of(U.live, onWay)) {
    SmallPtrSet<const BasicBlock *, 4> heads;
    for (Loop *P = L.getParentLoop(); P; P = P->getParentLoop())
      heads.insert(P->getHeader());
    if (BasicBlock *t = nearestPostDomPastDeadEnds(F, U.live, heads))
      c = t;
  }
  if (!c)
    unimplemented("loops-cutoff: a rule-14 loop whose live exits have no common post-dominator (cq-0dvv)",
                  U.live.front()->getTerminator());
  if (L.contains(c))
    internalError("loops-cutoff: a loop's exits post-dominated by a block of the loop", c);
  U.cont = c;
  // The exit arm: every block from a live exit up to C, entered only from the loop or the arm, acyclic.
  SmallPtrSet<BasicBlock *, 8> arm;
  SmallVector<BasicBlock *, 8> work;
  for (BasicBlock *x : U.live)
    if (x != c && arm.insert(x).second)
      work.push_back(x);
  while (!work.empty()) {
    BasicBlock *b = work.pop_back_val();
    for (BasicBlock *s : successors(b))
      if (s != c && !L.contains(s) && arm.insert(s).second)
        work.push_back(s);
  }
  // cq-h8y6 (rule 9 at the join): an arm block also entered from outside the loop is a join of the unit's paths
  // and the outside ones; it and every arm block it reaches are the TAIL (Exits.h), lowered per trip for the
  // unit's paths and by the walker for the outside paths, under their own predicate.
  SmallPtrSet<BasicBlock *, 8> tail;
  SmallVector<BasicBlock *, 8> twork;
  for (BasicBlock *b : arm)
    for (BasicBlock *p : predecessors(b))
      if (!L.contains(p) && !arm.count(p) && tail.insert(b).second)
        twork.push_back(b);
  while (!twork.empty()) {
    BasicBlock *b = twork.pop_back_val();
    for (BasicBlock *s : successors(b))
      if (arm.count(s) && tail.insert(s).second)
        twork.push_back(s);
  }
  // Topological order (DFS post-order reversed), back edges dropped: every cycle is a natural loop
  // (fix-irreducible runs first, CR rule 14 "Irreducible control flow"), a loop OF THE ARM that the loop
  // module lowers inside each trip's evaluation of the arm, like a sub-loop of a trip.
  SmallPtrSet<BasicBlock *, 8> done, onStack;
  std::vector<BasicBlock *> post;
  std::function<void(BasicBlock *)> dfs = [&](BasicBlock *b) {
    onStack.insert(b);
    for (BasicBlock *s : successors(b)) {
      if (!arm.count(s))
        continue;
      if (onStack.count(s))
        continue;   // the back edge of a loop of the arm
      if (!done.count(s))
        dfs(s);
    }
    onStack.erase(b);
    done.insert(b);
    post.push_back(b);
  };
  for (BasicBlock *x : U.live)
    if (arm.count(x) && !done.count(x))
      dfs(x);
  for (auto it = post.rbegin(); it != post.rend(); ++it) {
    U.arm.push_back(*it);
    if (tail.count(*it))
      U.tail.push_back(*it);
  }
  return U;
}
} // namespace

bool inTailLoopUnit(const Loop &L, const Unit &U, const BasicBlock *u, const LoopInfo &LI) {
  for (const BasicBlock *t : U.tail) {
    const Loop *l = LI.getLoopFor(t);
    if (!l || l->contains(L.getHeader()))
      continue;
    while (l->getParentLoop() && !l->getParentLoop()->contains(L.getHeader()))
      l = l->getParentLoop();
    Unit tu = unitOf(*l);
    SmallVector<BasicBlock *, 4> exiting;
    l->getExitingBlocks(exiting);
    // A one-exit loop with no arm reads its exit value as an edge: nothing else binds the phi, and its values after the loop are that value.
    if (tu.contains(*l, u) && (!tu.arm.empty() || exiting.size() > 1))
      return true;
  }
  return false;
}

static Pred tailPredIn(LoweringContext &ctx, const LoopInfo &LI, const Loop &L, const Unit &U, const BasicBlock *b,
                       const DominatorTree &DT) {
  Pred acc = Pred::bottom();
  for (const BasicBlock *p : predecessors(b)) {
    if (L.contains(p) || DT.dominates(b, p))
      continue;   // the unit's own edge, or a back edge (a loop of the tail)
    if (is_contained(U.arm, p)) {
      if (is_contained(U.tail, p))
        acc = acc | (tailPredIn(ctx, LI, L, U, p, DT) & ctx.preds().edge(p, b));
      continue;   // an arm block not entered from outside: the unit's path
    }
    // cq-iaz30 for the tail (CR rules 9, 14; GLPK npp_sat_is_pack_ineq: two K-loops whose exit arms share a tail): an edge
    // from another quantum-exit loop's unit (its loop or its exit arm) is that unit's, which merges it over its trips (its
    // atoms are one trip's, unreadable after the loop); only that unit's own tail paths from outside it remain.
    bool other = false;
    for (const Loop *O : LI.getLoopsInPreorder()) {
      if (O == &L || O->contains(L.getHeader()))
        continue;
      Unit OU = unitOf(*O);
      if (!O->contains(p) && !is_contained(OU.arm, p))
        continue;
      const Case oc = classify(*O, ctx.T, ctx.S);
      if (oc != Case::QuantumExit && oc != Case::ClassicalBoundQuantumExit)
        continue;
      // cq-56kjj: b is O's continuation, where O's unit ends: every path into O reaches it (rule 14, the unit always ends),
      // so O's paths enter the tail here under O's header predicate, made before the loop and readable after it.
      if (b == OU.cont)
        acc = acc | ctx.preds().block(O->getHeader());
      if (is_contained(OU.tail, p))
        acc = acc | (tailPredIn(ctx, LI, *O, OU, p, DT) & ctx.preds().edge(p, b));
      other = true;
      break;
    }
    if (!other)
      acc = acc | ctx.preds().edge(p, b);
  }
  return acc;
}

Pred tailPred(LoweringContext &ctx, const Loop &L, const Unit &U, const BasicBlock *b, const DominatorTree &DT) {
  // Any tree of the frozen original is its shared one's twin: the shared loops then serve.
  const Function &F = *L.getHeader()->getParent();
  if (frozenEpoch(F))
    return tailPredIn(ctx, spine::shared(ctx).li(F), L, U, b, DT);
  LoopInfo LI(DT);
  return tailPredIn(ctx, LI, L, U, b, DT);
}

BasicBlock *liveExiting(const Loop &L) {
  Unit U = unitOf(L);
  BasicBlock *one = nullptr;
  for (BasicBlock *b : L.blocks())
    for (BasicBlock *s : successors(b))
      if (!L.contains(s) && is_contained(U.live, s)) {
        if (one && one != b)
          return nullptr;
        one = b;
      }
  return one;
}

BasicBlock *liveExit(const Loop &L) {
  Unit U = unitOf(L);
  return U.multi() ? nullptr : U.cont;
}

std::optional<uint64_t> cutoffBound(const Loop &L, ScalarEvolution &SE, const Specialization &S) {
  SmallPtrSet<const BasicBlock *, 8> region;
  bool regionForm = testRegion(L, region);
  SmallVector<BasicBlock *, 4> exiting;
  L.getExitingBlocks(exiting);
  // The header-tested "minus one" (its last header run only tests) holds when every exit is the region's.
  bool minusOne = regionForm && all_of(exiting, [&](const BasicBlock *e) { return region.count(e) != 0; });
  // B is the least of every known bound: SCEV's constant maximum and, in a clone with `_b` bounds, the
  // trip count's maximum over the bounded formals (cq-zge7: an unsigned i32 trip count has the constant
  // maximum 0xFFFFFFFF, which must not hide a smaller `_b` bound).
  std::optional<uint64_t> n;
  if (unsigned c = SE.getSmallConstantMaxTripCount(&L))
    n = c;
  if (!S.bounds.empty()) {
    // CR §1.4: one bound per quantum integer formal whose call-site range bounded it, in formal order.
    const SCEV *btc = SE.getSymbolicMaxBackedgeTakenCount(&L);
    if (!isa<SCEVCouldNotCompute>(btc)) {
      const SCEV *tc = SE.getAddExpr(btc, SE.getOne(btc->getType()));
      // CR §1.4: one bound per quantum integer formal whose call-site range bounded it; taint names the
      // formal of each (Specialization::boundFormals).
      Function &F = *L.getHeader()->getParent();
      if (S.boundFormals.size() != S.bounds.size())
        internalError("loops-cutoff: a clone's bounds without their formals", L.getHeader());
      SmallVector<std::pair<const Argument *, uint64_t>, 4> bounded;
      for (size_t i = 0; i < S.bounds.size(); ++i) {
        if (S.boundFormals[i] >= F.arg_size())
          internalError("loops-cutoff: a bound of a formal the clone does not have", L.getHeader());
        bounded.push_back({F.getArg(S.boundFormals[i]), S.bounds[i]});
      }
      bool uses = any_of(bounded, [&](const auto &ab) {
        return SCEVExprContains(tc, [&](const SCEV *x) {
          auto *u = dyn_cast<SCEVUnknown>(x);
          return u && u->getValue() == ab.first;
        });
      });
      if (uses) {
        ValueToSCEVMapTy map;
        for (auto &[A, b] : bounded)
          map[A] = SE.getUMinExpr(SE.getSCEV(const_cast<Argument *>(A)), SE.getConstant(A->getType(), b));
        const SCEV *tcb = SCEVParameterRewriter::rewrite(tc, SE, map);
        if (tcb->getType() != tc->getType())
          internalError("loops-cutoff: a bounded trip count changed type", L.getHeader());
        // TC = BTC + 1 wraps to 0 only where BTC is all ones; the loop entry excluding TC == 0 (the
        // pre-header guard), or a bounded TC never 0, rules that out, so the bounded maximum is the
        // trip count's maximum.
        bool exact = SE.isLoopEntryGuardedByCond(&L, ICmpInst::ICMP_NE, tc, SE.getZero(tc->getType())) ||
                     !SE.getUnsignedRangeMin(tcb).isZero();
        APInt mx = SE.getUnsignedRangeMax(tcb);
        if (exact && !mx.isMaxValue() && mx.getActiveBits() <= 32 && !mx.isZero())
          n = n ? std::min<uint64_t>(*n, mx.getZExtValue()) : mx.getZExtValue();
      }
    }
  }
  if (!n)
    return std::nullopt;
  // cq-tntm (CR rule 14: "The cutoff is min(K, B) ... `a_K` is kept only when B > K or no bound is known"): a header-tested
  // loop whose header runs at most once runs no body, B = 0, a known bound (no a_K kept), not "no bound".
  if (minusOne)
    --*n;
  return n;
}

} // namespace exits

// B: an upper bound of the trip count from LLVM's range facts (SCEV's constant maximum). A trip is
// a header execution, except in a header-tested loop (its last header run only tests).
std::optional<uint64_t> tripBound(const Loop &L, ScalarEvolution &SE) {
  unsigned n = SE.getSmallConstantMaxTripCount(&L);
  if (n == 0)
    return std::nullopt;
  SmallPtrSet<const BasicBlock *, 8> region;
  if (testRegion(L, region))
    --n;   // cq-tntm: 0 is a bound (no body runs)
  return n;
}

// The C name -cq-k=<fn>=<k> names (CR §0: "The per-function flag names every function of that C name"): the function's
// own name, and for a static llvm-link renamed (`helper.3`) also the name without the suffix.
static std::optional<unsigned> perFunctionK(const Function &F, const std::map<std::string, unsigned> &flags) {
  auto it = flags.find(F.getName().str());
  if (it == flags.end() && F.hasLocalLinkage()) {
    auto [base, sfx] = F.getName().rsplit('.');
    unsigned n;
    if (!sfx.empty() && !base.empty() && !sfx.getAsInteger(10, n))
      it = flags.find(base.str());
  }
  if (it != flags.end())
    return it->second;   // owner ruling Q2 of 2026-11-15: K = 0 is legal
  return std::nullopt;
}

// CR §0, owner ruling 2026-11-15 (cq-z9vt): the CQ_K line of f. In a module of several units cqcc bound each line per
// unit, before the link, onto the function it names as the string attribute "cq-k"="k" ("none": no line names it); a
// line naming a function no unit defines stays the `used` constant __cq_k_<f>, llvm-link's copies __cq_k_<f>.N with it,
// and the largest k counts. A single unit has only the constant. K = 0 is legal (owner ruling Q2 of 2026-11-15, CR §0):
// a 0, as the attribute or the constant, is a line.
static std::optional<unsigned> lineK(const Function &F, StringRef attr, StringRef prefix) {
  if (F.hasFnAttribute(attr)) {
    unsigned v = 0;
    if (!F.getFnAttribute(attr).getValueAsString().getAsInteger(10, v))
      return v;
    return std::nullopt;   // "none"
  }
  std::string name = (prefix + F.getName()).str();
  std::optional<uint64_t> best;
  auto take = [&](const GlobalVariable &GV) {
    if (GV.hasInitializer())
      if (auto *CI = dyn_cast<ConstantInt>(GV.getInitializer()))
        best = std::max(best.value_or(0), CI->getZExtValue());
  };
  if (const GlobalVariable *GV = F.getParent()->getGlobalVariable(name, true))
    take(*GV);
  for (const GlobalVariable &GV : F.getParent()->globals()) {
    StringRef n = GV.getName();
    unsigned d;
    if (n.size() > name.size() + 1 && n.starts_with(name) && n[name.size()] == '.' &&
        !n.drop_front(name.size() + 1).getAsInteger(10, d))
      take(GV);
  }
  if (best)
    return unsigned(*best);
  return std::nullopt;
}

// CLAUDE.md "K per loop", first match wins: the per-function flag, CQ_K(f, k) (lineK), the global flag, 4.
unsigned resolveK(const Function &F, const KOptions &KO) {
  if (auto k = perFunctionK(F, KO.perFunction))
    return *k;
  if (auto k = lineK(F, "cq-k", "__cq_k_"))
    return *k;
  if (KO.global)
    return *KO.global;
  return 4;
}

// §0 K2 resolves as K does (bus::K2).
unsigned resolveK2(const Function &F, const KOptions &KO) {
  if (auto k = perFunctionK(F, KO.k2PerFunction))
    return *k;
  if (auto k = lineK(F, "cq-k2", "__cq_k2_"))
    return *k;
  if (KO.k2Global)
    return *KO.k2Global;
  return 4096;
}


} // namespace cq::loops
