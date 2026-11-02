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
// The trips are UNROLLED (cq-arch V1: "one per unrolled iteration of a cutoff loop"): trip j is the
// loop body lowered once more through the spine's per-instruction dispatch (lowerInstruction), its
// values rebound to trip j's rails. Every trip's rails are then ordinary Uncompute records, so the
// mirror is the uncompute spine's own reverse dependency order: exit values read by a merge or a
// measurement after the loop are uncomputed after their readers (53, 153) with no copy-out, and a
// measured exit value is kept as the measured rail (05, 150). §6 compares semantics, never CFG shape
// (CR §6, rule 14 "Irreducible control flow"); the references' rolled push/pop loops are one
// spelling of the same gate sequence.
//
// Two trip shapes, by the header's test region (the C oracle's definition, cq-arch T1.2 and CR rule
// 14 for header-tested loops 09, 37, 54, 189): the header plus the blocks it reaches through single-
// predecessor in-loop edges that are pure, exiting and no latch.
//  - Region form (the region holds an exit and the header is no latch): trip 0's test is the region
//    evaluated on the initial state; each of the c trips is body then test. q_j = q_{j-1} & cont(R_j),
//    cont = the region continues into the body; c bodies, c + 1 region evaluations; q_c is a_K. Every
//    exit leaves from the region; the state is frozen once the loop has exited (q = 0), so the last
//    region evaluation holds every exit value.
//  - Body form (otherwise): trip j is the whole body under q_j, cont_j its back-edge predicate. Every
//    exit leaves from the single latch; a value read after the loop is the latch incoming of a quantum
//    header phi, so its exit value is that phi's final state (the state advances on q_j, the trip ran).
//    An exit-block phi whose every incoming is that header phi's (its latch incoming on the exit edge,
//    or an equal value by SCEV: -O1's folded exit value, 149; its pre-header incoming on a guard edge
//    that excludes entering the loop) IS the final state and is bound to it here.
// Nested K-loops are lowered the same way inside each trip, seeded by the trip predicate & the inner
// header's predicate within the trip (68, 153).
//
// An instruction with effects in the body (a call, a store, an allocation, a phase or a rotation) is
// lowered under the trip predicate q_j & its block's trip-local predicate (rule 14 case 2, cq-99f7's
// tripFlag); a pure instruction or a load is computed in every trip.
// A trip is any acyclic code (cq-b58q): classical and quantum branches and switches are its predicates (a
// classical term seeded, rule 8), a classical phi a classical select (rule 9), several latches end a trip on
// one back edge, several header entries merge a quantum start (rule 9). A read after a top-level loop that
// the single-exit forms cannot express takes the multi-exit form's GENERAL EXIT CAPTURE.
// Not built yet (each stop names its bead): nested loops in the general forms, a classical-bound sub-loop,
// pointer and aggregate values across the loop, the unit shapes exits::unitOf rejects.
#include "cq/Loops.h"

#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <vector>

#include "Exits.h"
#include "cq/FatPtr.h"
#include "cq/Memory.h"
#include "cq/Predicate.h"
#include "cq/Uncompute.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
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
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/TargetParser/Triple.h"

using namespace llvm;

namespace {
// CR rule 13 (b137e75): a carried or merged code address is an i64 handle (a data pointer never reaches a rail
// here: it is a fat pointer, rule 21).
cq::RailType railOf(Type *t) { return t->isPointerTy() ? cq::RailType{cq::Kind::Int, 64} : cq::railTypeOf(t); }
} // namespace

namespace cq::loops {

namespace {

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
          !exiting(S))
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

private:
  LoweringContext &ctx;
  Analyses &A;
  DenseSet<const Value *> mine;   // values this module has bound (bind, then rebind per trip)
  // Classical values that differ from trip to trip: a classical header phi (an affine induction, CR
  // rule 14 f981c89) and every classical value computed from one. Trips the C program does not run
  // are computed too, so their copies carry no poison-generating flags (start + j*step may wrap past
  // the exit trip) and a division by one is not built.
  DenseSet<const Value *> perTrip;
  DenseMap<const PHINode *, uint64_t> walkedTrip;   // walked pointer phi -> its trip index (cq-9w75)
  DenseSet<const PHINode *> carriedPtr;             // quantum pointer phi carried as its tag (cq-z6q1, fatptr R2)
  Value *chainEnd = nullptr;                        // the last lowerLoop's last chain predicate (its a_K)

  bool nonClassicalMemory(const Value *p) {
    if (ctx.T.isFatPointer(p, ctx.S))
      return true;
    for (ObjectId o : ctx.T.provenance(p, ctx.S))
      if (ctx.T.classOf(o) != ObjClass::Classical)
        return true;
    return false;
  }

  bool isQ(const Value *v) {
    if (isa<Constant>(v) || isa<BasicBlock>(v) || isa<MetadataAsValue>(v))
      return false;
    return ctx.T.isQuantum(v, ctx.S);
  }
  void set(const Value *orig, Operand op) {
    if (mine.insert(orig).second)
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
  Value *seedRail(Value *classical, Type *ty) {
    RailType w = railOf(ty);
    CallInst *s = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {classical});
    ctx.unc().recordSeed(s);
    return s;
  }
  // q & flag(p): the conjunction of a trip predicate with a predicate local to the trip.
  Value *conj(Value *q, const Pred &p, const Instruction *at) {
    if (p.isBottom())
      internalError("loops-cutoff: a trip predicate conjoined with false", at);
    // The trip is unrolled into straight-line code, so a classical term of p (a classical branch or
    // switch inside the trip, rules 8 and 13) is no classical branch here: pred's flag synthesis
    // seeds it from its classical value in this trip (rule 7) and joins it by and_i1/or_i1, as rule 8
    // does for a classical term it cannot factor out. The conjunction with the trip predicate is
    // quantum, so the effects under it are the quantum-predicate forms of rules 16 and 19.
    (void)at;
    Value *f = ctx.preds().flag(ctx, p);
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
  static Pred tripEdge(const BasicBlock *p, const BasicBlock *b) {
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
    checkTerminator(t);
    internalError("loops-cutoff: a trip edge from a terminator checkTerminator accepted", t);
  }
  // The classical part of tripEdge as a classical i1 of the current trip: a quantum condition counts
  // as true. A classical phi's incoming edge is chosen by classical conditions alone (taint: a phi
  // whose choice depends on a quantum condition is quantum), so among edges whose classical part
  // holds, every one carries the merged value.
  Value *classicalEdge(const BasicBlock *p, const BasicBlock *b) {
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
};

void Cutoff::lowerLoop(Loop &L, Value *seed, unsigned c, bool keep, bool top) {
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
  auto liveEdge = [&](const BasicBlock *s) { return !L.contains(s) && is_contained(U.live, s); };
  BasicBlock *X = U.multi() ? nullptr : U.cont;
  if (c == 0)
    internalError("loops-cutoff: a cutoff of 0 trips", H->getTerminator());

  // Sub-loops: each is a quantum-exit loop of its own (nested K-loops).
  for (Loop *S : L.getSubLoops())
    if (classify(*S, ctx.T, ctx.S) != Case::QuantumExit)
      unimplemented("loops-cutoff: a sub-loop of a K-loop that is not itself a quantum-exit loop (cq-h5uj)",
                    S->getHeader()->getTerminator());

  // The body's terminators: every branch and switch of a trip, quantum or classical, is a predicate of
  // the trip (edgeCond); the trip is straight-line code under those predicates.
  bool classicalTerms = false;   // a classical branch or switch in a trip
  for (BasicBlock *b : L.blocks()) {
    Instruction *t = b->getTerminator();
    checkTerminator(t);
    if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional() && !isQ(br->getCondition()))
      classicalTerms = true;
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
  DenseMap<const BasicBlock *, Loop *> subArm;
  for (Loop *S : L.getSubLoops())
    for (BasicBlock *b : exits::unitOf(*S).arm)
      if (L.contains(b))
        subArm[b] = S;
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
  auto edgeCond = [&](BasicBlock *p, BasicBlock *b) -> Pred { return tripEdge(p, b); };
  auto contribution = [&](BasicBlock *p, BasicBlock *b) -> Pred {
    if (Loop *S = subLoopOf(p); S && !S->contains(b)) {
      exits::Unit SU = exits::unitOf(*S);
      if (SU.contains(*S, b) || is_contained(SU.dead, b))
        return Pred::bottom();   // inside the sub-unit (its exit arm, its noreturn arm: its own trips) or dead
      if (SU.cont != b)
        unimplemented("loops-cutoff: a nested K-loop with more than one exit block (cq-lgkx)", p->getTerminator());
      return local.find(S->getHeader())->second;   // the sub-loop as a unit always ends at its exit
    }
    return local.find(p)->second & edgeCond(p, b);
  };
  for (BasicBlock *b : order) {
    if (b == H) {
      local.insert({b, Pred::top()});
      continue;
    }
    Pred acc = Pred::bottom();
    for (BasicBlock *p : predecessors(b)) {
      if (!L.contains(p))
        continue;
      Loop *bl = A.LI.getLoopFor(b);
      if (bl && bl->getHeader() == b && bl->contains(p))
        continue;   // back edge of a sub-loop
      if (!local.count(p))
        internalError("loops-cutoff: a predecessor after its successor in the trip order", p->getTerminator());
      acc = acc | contribution(p, b);
    }
    local.insert({b, acc});
  }
  Pred cont = Pred::bottom();   // body form: some back edge is taken
  for (BasicBlock *l : latches)
    cont = cont | (local.find(l)->second & edgeCond(l, H));
  Pred regionCont = Pred::bottom();                               // region form
  if (regionForm)
    for (const BasicBlock *r : region)
      for (BasicBlock *s : successors(const_cast<BasicBlock *>(r)))
        if (L.contains(s) && !region.count(s))
          regionCont = regionCont | (local.find(r)->second & edgeCond(const_cast<BasicBlock *>(r), s));

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
  DenseMap<PHINode *, QInduction> qind;
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
  // CR rule 14 (f981c89): an affine induction (a classical header phi, taint) is not carried; when the
  // program reads its exit value after the loop, a rail seeded with the start advances by
  // select(q_j, rail + step, rail) for that read alone (never used in the loop).
  DenseMap<PHINode *, Operand> exitRail;
  std::vector<Instruction *> regionQReads;   // region form: quantum values read after the loop
  // TRIP OBJECTS (cq-r7-91, CR rules 14, 20, 21; 91): a malloc-like allocation in the loop whose pointer is
  // read after the loop is one object per (site, trip). It is read only by phis P of the exit block on the
  // latch's exit edge (the last trip's object) whose other incomings are null on edges that skip the loop.
  // P is a fat pointer (fatptr R1) over null and the trip objects: its tag rail starts at null's tag and
  // advances by select(q_j, tag of trip j, tag); the cells read through P after the loop are captured at the
  // end of each trip. Built for a slot object (a block of handle cells), in a single-exit body-form K-loop at
  // the top level, whose site's block dominates the latch and dereferences it (so the object is non-null in
  // the domain), with P used after the loop only by eq/ne compares with null and loads at constant offsets.
  struct TripPhi {
    PHINode *P;
    Instruction *site;
    std::vector<std::pair<int64_t, Type *>> cells;   // (byte offset, type) read through P after the loop
    unsigned tag0 = 0;
    Operand tag{nullptr, true};
    std::vector<fatptr::TripObject> objs;
  };
  std::vector<TripPhi> tripPhis;
  auto tripSite = [&](Instruction &I) {
    auto *CB = dyn_cast<CallBase>(&I);
    if (!CB || !I.getType()->isPointerTy())
      return false;
    Attribute k = CB->getFnAttr(Attribute::AllocKind);
    if (!k.isValid() || (AllocFnKind(k.getValueAsInt()) & AllocFnKind::Alloc) == AllocFnKind::Unknown)
      return false;
    return true;
  };
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
  // A value whose slice inside the loop reaches an induction: its trip value advances after the exit.
  auto fromInduction = [&](const Instruction *I) {
    SmallVector<const Value *, 8> work{I};
    SmallPtrSet<const Value *, 16> seen;
    while (!work.empty()) {
      const Value *V = work.pop_back_val();
      auto *VI = dyn_cast<Instruction>(V);
      if (!VI || !L.contains(VI) || !seen.insert(V).second)
        continue;
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
      if (tripSite(I) && any_of(I.users(), [&](const User *u) {
            return !L.contains(cast<Instruction>(u)->getParent());
          })) {
        if (regionForm || !top || !X)
          unimplemented("loops-cutoff: an allocation of a K-loop read after the loop, outside a top-level single-exit "
                        "body-form K-loop (rule 14 trip objects) (cq-p45s)",
                        &I);
        ArrayRef<ObjectId> objs = ctx.T.provenance(&I, ctx.S);
        if (objs.size() != 1 || ctx.T.classOf(objs.front()) != ObjClass::Slot)
          unimplemented("loops-cutoff: a K-loop trip object read after the loop that is not one slot object (a QRAM or "
                        "host object per trip) (cq-p45s)",
                        &I);
        if (!A.DT.dominates(I.getParent(), latch))
          unimplemented("loops-cutoff: a K-loop trip object whose allocation does not dominate the latch (cq-p45s)", &I);
        bool deref = false;
        for (auto it = std::next(I.getIterator()); it != I.getParent()->end(); ++it)
          if (const Value *ap = getLoadStorePointerOperand(&*it); ap && ap->stripInBoundsConstantOffsets() == &I)
            deref = true;
        if (!deref)
          unimplemented("loops-cutoff: a K-loop trip object not dereferenced in its allocation's block (it may be "
                        "null: rule 21's tag compare needs distinct non-null objects) (cq-p45s)",
                        &I);
        for (const Use &U : I.uses()) {
          auto *P = dyn_cast<PHINode>(U.getUser());
          if (L.contains(cast<Instruction>(U.getUser())->getParent()))
            continue;
          if (!P || P->getParent() != X || P->getIncomingBlock(U) != latch)
            unimplemented("loops-cutoff: a K-loop trip object read after the loop other than by a phi of the exit "
                          "block on the latch's exit edge (cq-p45s)",
                          &I);
          if (any_of(tripPhis, [&](const TripPhi &t) { return t.P == P; }))
            continue;
          TripPhi tp;
          tp.P = P;
          tp.site = &I;
          tripPhis.push_back(std::move(tp));
        }
        continue;
      }
      bool outside = false;
      for (const Use &U : I.uses()) {
        auto *ui = cast<Instruction>(U.getUser());
        const BasicBlock *at = ui->getParent();
        if (auto *phi = dyn_cast<PHINode>(ui))
          at = phi->getIncomingBlock(U);
        if (!L.contains(at) || (isa<PHINode>(ui) && !L.contains(ui->getParent())))
          outside = true;
      }
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
        } else if (fromInduction(&I)) {
          takeGeneral("loops-cutoff: a value of a nested K-loop's test region computed from an induction, read "
                      "after the loop (cq-lgkx)",
                      &I);
        } else {
          regionQReads.push_back(&I);
        }
        continue;   // the last region evaluation holds it (frozen state)
      }
      PHINode *h = headerPhiWithNext(&I);
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
    tripPhis.clear();
  }
  for (TripPhi &tp : tripPhis) {
    PHINode *P = tp.P;
    const Pred &pH = ctx.preds().block(H);
    if (!isQ(P))
      unimplemented("loops-cutoff: a phi of K-loop trip objects that taint calls classical (cq-p45s)", P);
    if (!pH.classicalFactor(ctx.T, ctx.S).isTop())
      unimplemented("loops-cutoff: a phi of K-loop trip objects of a loop under a classical condition (cq-p45s)", P);
    for (unsigned i = 0; i < P->getNumIncomingValues(); ++i) {
      BasicBlock *u = P->getIncomingBlock(i);
      Value *v = P->getIncomingValue(i);
      if (L.contains(u)) {
        if (u != latch || v != tp.site)
          unimplemented("loops-cutoff: a phi of K-loop trip objects with another incoming from the loop (cq-p45s)", P);
        continue;
      }
      if (!isa<ConstantPointerNull>(v) || !(ctx.preds().edge(u, X) & pH).isBottom())
        unimplemented("loops-cutoff: a phi of K-loop trip objects whose incoming from outside the loop is not null on "
                      "an edge that skips the loop (cq-p45s)",
                      P);
    }
    // Its uses after the loop: eq/ne with null, loads at constant offsets (through constant GEPs).
    const DataLayout &DL = ctx.M.getDataLayout();
    SmallVector<std::pair<const Value *, int64_t>, 8> work{{P, 0}};
    while (!work.empty()) {
      auto [v, off] = work.pop_back_val();
      for (const User *u : v->users()) {
        if (auto *ld = dyn_cast<LoadInst>(u); ld && ld->getPointerOperand() == v && ld->isSimple()) {
          std::pair<int64_t, Type *> c{off, ld->getType()};
          if (!is_contained(tp.cells, c))
            tp.cells.push_back(c);
          continue;
        }
        if (auto *cmp = dyn_cast<ICmpInst>(u); cmp && v == P && cmp->isEquality() &&
                                              (isa<ConstantPointerNull>(cmp->getOperand(0)) ||
                                               isa<ConstantPointerNull>(cmp->getOperand(1))))
          continue;
        if (auto *g = dyn_cast<GEPOperator>(u); g && g->getPointerOperand() == v && g->isInBounds()) {
          APInt o(64, 0);
          if (g->accumulateConstantOffset(DL, o)) {
            work.push_back({g, off + o.getSExtValue()});
            continue;
          }
        }
        unimplemented("loops-cutoff: a phi of K-loop trip objects used after the loop other than by an eq/ne compare "
                      "with null or a load at a constant offset (cq-p45s)",
                      cast<Instruction>(u));
      }
    }
  }
  std::vector<std::pair<PHINode *, PHINode *>> exitPhis;   // exit phi -> header phi it denotes
  if (!regionForm && !multi && X) {
    const Pred &pH = ctx.preds().block(H);
    for (PHINode &P : X->phis()) {
      if (!isQ(&P) || any_of(tripPhis, [&](const TripPhi &t) { return t.P == &P; }))
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
      if (ok && id && ctx.preds().block(H).classicalFactor(ctx.T, ctx.S).isTop()) {
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
      tripPhis.clear();
    }
  }

  // Multi-exit form: what the unit gives C. A value of the loop or the arm is read outside the unit
  // only by a phi of C on an edge from the unit; each such phi is quantum. Its incomings from outside
  // the unit (the pre-header guard's skip edge, 190's `n == 0`) are its initial value: they must be
  // taken only where the header is not reached, and agree.
  struct CPhi {
    PHINode *P;
    Operand acc;
  };
  std::vector<CPhi> cphis;
  // A value of the unit read after it other than by a phi of C: its exit value, a rail that takes this
  // trip's value where the trip leaves the loop (acc' = select(q_j & X_j, v_j, acc), X_j the trip's
  // exit edges). SSA dominance makes v defined on every path to the reader, so where the reader runs
  // the exit that was taken passed v's definition in that trip. Rebound to the reader after the loop.
  struct XAcc {
    Instruction *V;
    Operand acc;
  };
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
          Type *ty = I.getType();
          if (!(ty->isIntegerTy() || ty->isFloatingPointTy()))
            unimplemented("loops-cutoff: the exit value of a pointer or aggregate computed in a K-loop (rules 21, 26: "
                          "a fat pointer or per-field rails; cq-p45s)",
                          &I);
          xaccs.push_back({&I, Operand{seedRail(Constant::getNullValue(ty), ty), true}});
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
      if (!isQ(&P))
        unimplemented("loops-cutoff: a classical phi joining a multi-exit K-loop's exits (cq-uytx)", &P);
      if (!(P.getType()->isIntegerTy() || P.getType()->isFloatingPointTy()))
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
      for (unsigned i = 0; i < P.getNumIncomingValues() && !earlier; ++i) {
        BasicBlock *u = P.getIncomingBlock(i);
        if (inUnit(u))
          continue;
        // A classical skip of the loop (its edge excludes the classical condition the unit runs under):
        // the walker joins it with the unit's value classically (joinUnitPhi, rule 9 at a58c3a4).
        if ((ctx.preds().edge(u, C) & cH).isBottom())
          continue;
        if (!(ctx.preds().edge(u, C) & pH).isBottom())
          unimplemented("loops-cutoff: a phi joining a multi-exit K-loop's exits with an incoming from outside the "
                        "loop on an edge that does not exclude the loop (cq-uytx)",
                        &P);
        Value *v = P.getIncomingValue(i);
        if (!ctx.bound(v)) {
          const Loop *vl = A.LI.getLoopFor(u);
          if (!vl || vl->contains(H))
            ctx.addJoinArm(&P, ctx.preds().edge(u, C), v);   // lowered after the loop: the walker selects it in
          continue;   // or another loop unit's exit: it selects its value in over this binding when lowered
        }
        Pred e = ctx.preds().edge(u, C);
        auto same = find_if(outside, [&](const std::pair<Pred, Operand> &a) { return a.second.v == ctx.operand(v).v; });
        if (same != outside.end())
          same->first = same->first | e;
        else
          outside.push_back({e, ctx.operand(v)});
      }
      // With no incoming from outside, the value where no trip exits (the cutoff reached first) is 0.
      Operand acc;
      if (earlier)
        acc = ctx.operand(&P);
      else if (outside.empty())
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
    auto opOf = [&](Value *v) { return tag ? fatptr::carriedTag(ctx, v) : ctx.operand(v); };
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
  // The state: header phis bound to their initial values (a classical initial value of a quantum phi
  // becomes a seed rail).
  for (PHINode *h : hphis) {
    // cq-9w75 (CR rule 14 f981c89): a classical pointer into slot, QRAM or fat-pointer memory walked by
    // a constant step is no operand: memory reads it as start + j*step (LoweringContext::walkedPointer),
    // the phi bound to the trip index j, a constant of the unrolled trip.
    if (!isQ(h) && h->getType()->isPointerTy() && nonClassicalMemory(h)) {
      const Value *nx = h->getIncomingValueForBlock(latch);
      auto *g = dyn_cast<GEPOperator>(nx);
      APInt off(64, 0);
      const Value *start = startOf(h);
      if (!start)
        unimplemented("loops-cutoff: a classical pointer into slot or QRAM memory entering a K-loop with several "
                      "starts (a classical phi at the walker's join before the loop; cq-kldr)",
                      h);
      auto *si = dyn_cast<Instruction>(start);
      bool sameNext = all_of(latches, [&](BasicBlock *l) { return h->getIncomingValueForBlock(l) == nx; });
      // A loop-invariant pointer (every back edge carries the phi itself or its start) is walked by 0.
      bool invariant = all_of(latches, [&](BasicBlock *l) {
        const Value *v = h->getIncomingValueForBlock(l);
        return v == h || v == start;
      });
      if (invariant && !(si && L.contains(si)))
        g = nullptr;
      else if (!sameNext || !g || g->getPointerOperand() != h ||
               !g->accumulateConstantOffset(ctx.M.getDataLayout(), off) || (si && L.contains(si)))
        unimplemented("loops-cutoff: a pointer into slot or QRAM memory carried by a K-loop that is not walked by a "
                      "constant step from a loop-invariant start (cq-p45s)",
                      h);
      for (const User *u : h->users()) {
        bool ok = u == g || isa<GetElementPtrInst>(u) || (isa<LoadInst>(u) && cast<LoadInst>(u)->getPointerOperand() == h) ||
                  (isa<StoreInst>(u) && cast<StoreInst>(u)->getPointerOperand() == h);
        if (!ok)
          unimplemented("loops-cutoff: a walked pointer of a K-loop used other than as an address (cq-p45s)", cast<Instruction>(u));
      }
      ctx.bindWalkedPointer(h, WalkedPtr{start, off.getSExtValue()});
      walkedTrip[h] = 0;
      set(h, Operand{ConstantInt::get(Type::getInt64Ty(ctx.M.getContext()), 0), false});
      continue;
    }
    // cq-z6q1 (CR rules 14, 21; 189): a quantum pointer header phi is carried as its fat pointer's tag rail
    // (fatptr R2: every incoming at the start of its objects, so idx is the classical 0 and not carried).
    if (isQ(h) && h->getType()->isPointerTy() && !isCodeAddress(h)) {
      if (exitRail.count(h) || qind.count(h))
        unimplemented("loops-cutoff: a K-loop's carried pointer read after the loop (cq-p45s)", h);
      fatptr::registerCarried(ctx, *h);
      Operand init = initOf(h, true);
      if (!init.handle)
        init = Operand{seedRail(init.v, Type::getInt32Ty(ctx.M.getContext())), true};
      carriedPtr.insert(h);
      set(h, init);
      continue;
    }
    // A classical pointer header phi is an affine induction (taint, CR rule 14: a walked pointer with a
    // classical start): a classical value in each trip, nothing carried.
    if (!h->getType()->isIntegerTy() && !h->getType()->isFloatingPointTy() && (isQ(h) || !h->getType()->isPointerTy()) &&
        !(h->getType()->isPointerTy() && isCodeAddress(h)))   // rule 13: a code address is carried as an i64 handle
      unimplemented("loops-cutoff: a carried value that is not a scalar (aggregates, pointers) (cq-p45s)", h);
    Operand init = initOf(h, false);
    if (isQ(h) && !init.handle)
      init = Operand{seedRail(init.v, h->getType()), true};
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
    set(h, init);
  }

  for (TripPhi &tp : tripPhis) {
    tp.tag0 = fatptr::reserveTripTags(ctx, c);
    const Value *null = nullptr;
    for (const Value *v : tp.P->incoming_values())
      if (isa<ConstantPointerNull>(v))
        null = v;
    unsigned t0 = null ? fatptr::rootTag(ctx, null) : 0;
    tp.tag = Operand{seedRail(ConstantInt::get(Type::getInt32Ty(ctx.M.getContext()), t0),
                              Type::getInt32Ty(ctx.M.getContext())),
                     true};
  }
  // The end of trip j (q its predicate): each trip object's captured cells, and the tag's advance.
  auto captureTrips = [&](Value *q, unsigned j) {
    for (TripPhi &tp : tripPhis) {
      fatptr::TripObject o;
      o.tag = tp.tag0 + j;
      for (auto &[off, ty] : tp.cells) {
        SmallVector<Operand, 8> h = mem::readSlotCells(ctx, tp.site, ty, 1, *latch->getTerminator(), off);
        o.cells.push_back(fatptr::TripCell{off, ty, h.front()});
      }
      tp.objs.push_back(std::move(o));
      abi::TemplateSpec sel;
      sel.op = "select";
      sel.w = RailType{Kind::Int, 32};
      sel.shape = "lh";
      tp.tag = Operand{ctx.emitTemplate(sel, {Operand{q, true},
                                              Operand{ConstantInt::get(Type::getInt32Ty(ctx.M.getContext()), o.tag), false},
                                              tp.tag}),
                       true};
    }
  };

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
  std::function<void(BasicBlock *, Value *, const Pred &)> lowerInsts;   // one block's non-phi instructions
  auto lowerBlocks = [&](Value *q, const std::function<bool(const BasicBlock *)> &pick) {
    boundThisTrip.clear();
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
        unsigned K = ctx.K(S);
        Loop *mS = A.LI.getLoopFor(b);
        std::optional<uint64_t> B = exits::cutoffBound(*mS, A.SE, ctx.T, ctx.S);
        unsigned cs = B ? unsigned(std::min<uint64_t>(K, *B)) : K;
        Value *s = conj(q, local.find(b)->second, b->getTerminator());
        // The sub-loop binds the phis of its exit block it identifies; they are not merged again.
        lowerLoop(*mS, s, cs, !B || *B > K, false);
        if (BasicBlock *SX = exits::unitOf(*mS).cont)
          for (PHINode &P : SX->phis())
            if (mine.count(&P))
              boundThisTrip.insert(&P);
        continue;
      }
      if (b != H)
        for (PHINode &P : b->phis()) {
          if (boundThisTrip.count(&P))
            continue;
          if (!isQ(&P)) {
            classicalPhi(P);
            continue;
          }
          if (!classicalTerms) {
            if (P.getType()->isPointerTy() && !isCodeAddress(&P)) {
              fatptr::lower(ctx, &P);   // rule 21: a quantum pointer merge is a fat pointer
            } else if (P.getType()->isAggregateType() || P.getType()->isVectorTy()) {
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
          // predicates, a classical term of them a seed rail (rule 8).
          std::vector<std::pair<Pred, Operand>> arms;
          for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
            BasicBlock *u = P.getIncomingBlock(i);
            Pred e = contribution(u, b);
            if (!e.isBottom())
              arms.push_back({e, ctx.operand(P.getIncomingValue(i))});
          }
          set(&P, Operand{selectChain(ctx, arms, railOf(P.getType())), true});
        }
      lowerInsts(b, q, local.find(b)->second);
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
    auto edgeIn = [&](const BasicBlock *u, const BasicBlock *b) -> std::optional<Pred> {
      if (!L.contains(u))
        if (Loop *S = subLoopOf(u)) {
          if (S->contains(b))
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
        // A loop of the arm: rule 14 inside this trip's arm, seeded by the arm's flag (nested K-loops).
        if (classify(*S, ctx.T, ctx.S) != Case::QuantumExit)
          unimplemented("loops-cutoff: a loop of a K-loop's exit arm that is not itself a quantum-exit loop "
                        "(cq-h5uj)",
                        b->getTerminator());
        unsigned K = ctx.K(S);
        std::optional<uint64_t> Bs = exits::cutoffBound(*S, A.SE, ctx.T, ctx.S);
        unsigned cs = Bs ? unsigned(std::min<uint64_t>(K, *Bs)) : K;
        lowerLoop(*S, conj(q, acc, b->getTerminator()), cs, false, false);
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
            if (mine.count(&P))
              armBound.insert(&P);
        continue;
      }
      for (PHINode &P : b->phis()) {
        if (armBound.count(&P))
          continue;
        if (!isQ(&P)) {
          classicalPhi(P);
          continue;
        }
        std::vector<std::pair<Pred, Operand>> arms;
        for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
          if (auto e = edgeIn(P.getIncomingBlock(i), b))
            arms.push_back({*e, ctx.operand(P.getIncomingValue(i))});
        set(&P, Operand{selectChain(ctx, arms, railOf(P.getType())), true});
      }
      lowerInsts(b, q, acc);
    }
    for (CPhi &cp : cphis) {
      std::vector<std::pair<Pred, Operand>> arms;
      Pred E = Pred::bottom();
      for (unsigned i = 0; i < cp.P->getNumIncomingValues(); ++i) {
        BasicBlock *u = cp.P->getIncomingBlock(i);
        auto ei = edgeIn(u, U.cont);
        if (!ei)
          continue;
        Pred e = *ei;
        if (e.isBottom())
          continue;
        E = E | e;
        arms.push_back({e, ctx.operand(cp.P->getIncomingValue(i))});
      }
      if (arms.empty())
        continue;
      RailType w = railOf(cp.P->getType());
      Value *v = selectChain(ctx, arms, w);
      Value *f = conj(q, E, U.cont->getFirstNonPHI());
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
      Operand v = ctx.operand(xa.V);
      abi::TemplateSpec sel;
      sel.op = "select";
      sel.w = railOf(xa.V->getType());
      sel.shape = v.handle ? "" : "lh";
      xa.acc = Operand{ctx.emitTemplate(sel, {Operand{f, true}, v, xa.acc}), true};
    }
    armPick = nullptr;
  };
  // The noreturn arms (CR rule 14 "No live exit", rule 16): each exit edge into one is taken in this
  // evaluation under q & its block's trip-local predicate & its condition; the arm's blocks run under
  // that flag (rule 9 inside the arm), its noreturn call is rule 16's abort_i1 on it. An exit from a
  // sub-loop's block is the sub-loop's own (its trips lower its arm).
  auto abortArms = [&](Value *q, const std::function<bool(const BasicBlock *)> &pick) {
    DenseMap<const BasicBlock *, Pred> abortLocal;
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
      for (PHINode &P : b->phis()) {
        if (!isQ(&P)) {
          classicalPhi(P);
          continue;
        }
        std::vector<std::pair<Pred, Operand>> arms;
        for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
          if (auto sp = srcPred(P.getIncomingBlock(i)))
            arms.push_back({*sp & edgeCond(P.getIncomingBlock(i), b), ctx.operand(P.getIncomingValue(i))});
        set(&P, Operand{selectChain(ctx, arms, railOf(P.getType())), true});
      }
      // Every instruction of the arm runs only where the arm is taken: under the flag.
      Value *f = conj(q, acc, b->getTerminator());
      for (Instruction &I : *b)
        if (!isa<PHINode>(I) && !I.isTerminator())
          lowerInstruction(ctx, I, f);
    }
  };
  lowerInsts = [&](BasicBlock *b, Value *q, const Pred &lp) {
    {
      Value *tripFlag = nullptr;   // q & the block's trip-local predicate, made on first need
      for (Instruction &I : *b) {
        if (isa<PHINode>(I) || I.isTerminator())
          continue;
        // Rule 14 case 2: an instruction with effects (a call, a store, an allocation, a phase) runs in
        // trip j only where the trip runs, so it is lowered under the trip predicate (cq-99f7's
        // tripFlag: the spine conjoins the block's own quantum predicate). A pure instruction or a load
        // is computed in every trip; its value only reaches state through the select on q.
        bool effects = isa<CallBase>(I) || I.mayHaveSideEffects() || I.mayWriteToMemory();
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
                            return br && br->isConditional() && br->getCondition() == &I && L.contains(br->getParent());
                          });
          if (tripAtom)
            lowerConditionAsData(ctx, I);
          else
            lowerInstruction(ctx, I);
          if (varies) {
            perTrip.insert(&I);
            // A pointer is no operand of its own (memory resolves it per access: rules 20, 21).
            if (auto *NI = I.getType()->isPointerTy() ? nullptr : dyn_cast<Instruction>(ctx.operand(&I).v);
                NI && NI != &I) {
              NI->dropPoisonGeneratingFlags();
              NI->dropPoisonGeneratingMetadata();
            }
          }
          continue;
        }
        if (!tripFlag)
          tripFlag = conj(q, lp, b->getTerminator());
        lowerInstruction(ctx, I, tripFlag);
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
      return carriedPtr.count(h) ? fatptr::carriedTag(ctx, v) : ctx.operand(v);
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
      arms.push_back({local.find(l)->second & e, opOf(h->getIncomingValueForBlock(l))});
    }
    RailType w = carriedPtr.count(h) ? RailType{Kind::Int, 32} : railOf(h->getType());
    return Operand{selectChain(ctx, arms, w), true};
  };
  auto advance = [&](Value *q) {
    std::vector<Operand> next;
    for (PHINode *h : hphis)
      next.push_back(walkedTrip.count(h) ? Operand{nullptr, false} : nextOf(h));
    for (size_t i = 0; i < hphis.size(); ++i) {
      PHINode *h = hphis[i];
      Operand nx = next[i];
      if (auto wt = walkedTrip.find(h); wt != walkedTrip.end()) {
        set(h, Operand{ConstantInt::get(Type::getInt64Ty(ctx.M.getContext()), ++wt->second), false});
        continue;
      }
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
      if (!cur.handle)
        internalError("loops-cutoff: a quantum carried value with no rail", h);
      if (nx.handle && nx.v == cur.v)
        continue;
      abi::TemplateSpec spec;
      spec.op = "select";
      spec.w = carriedPtr.count(h) ? RailType{Kind::Int, 32} : railOf(h->getType());   // R2: the tag rail
      std::string shape = std::string(nx.handle ? "h" : "l") + "h";
      spec.shape = shape == "hh" ? "" : shape;
      set(h, Operand{ctx.emitTemplate(spec, {Operand{q, true}, nx, cur}), true});
    }
  };

  const Instruction *at = H->getTerminator();
  Value *q = seed;
  if (regionForm) {
    auto inRegion = [&](const BasicBlock *b) { return region.count(b) != 0; };
    auto inBody = [&](const BasicBlock *b) { return region.count(b) == 0; };
    // Multi-exit form: an exit from the body ends the trip there, so the next test runs under the
    // body's back-edge predicate too.
    bool bodyExits = multi && any_of(exiting, [&](BasicBlock *e) {
                       return !region.count(e) && any_of(successors(e), liveEdge);
                     });
    lowerBlocks(q, inRegion);
    abortArms(q, inRegion);
    if (multi)
      capture(q, inRegion);
    q = conj(q, regionCont, at);
    for (unsigned j = 0; j < c; ++j) {
      lowerBlocks(q, inBody);
      abortArms(q, inBody);
      if (multi)
        capture(q, inBody);
      Value *qb = bodyExits ? conj(q, cont, latch->getTerminator()) : q;
      advance(q);
      lowerBlocks(qb, inRegion);
      abortArms(qb, inRegion);
      if (multi)
        capture(qb, inRegion);
      q = conj(qb, regionCont, at);
    }
  } else {
    auto all = [](const BasicBlock *) { return true; };
    for (unsigned j = 0; j < c; ++j) {
      lowerBlocks(q, all);
      abortArms(q, all);
      if (multi)
        capture(q, all);
      captureTrips(q, j);
      // With no exit edge at all (CR rule 14 "No live exit": every path of a trip takes a back edge) the
      // predicate stays q: every trip runs where the loop runs.
      Value *qn = conj(q, cont, latch->getTerminator());
      advance(q);
      q = qn;
    }
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
  } else if (keep) {
    ctx.unc().setRole(ctx.unc().idOf(q), Role::KeptOverflow);
  }
  if (armKept)
    ctx.unc().setRole(ctx.unc().idOf(armKept), Role::KeptOverflow);

  chainEnd = q;
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
  for (auto &[v, h] : exitRebinds)
    ctx.rebind(v, {exitOf(h)});
  for (auto &[P, h] : exitPhis) {
    Operand f = exitOf(h);
    if (top)
      ctx.bindFields(P, {f});
    else
      set(P, f);
  }
  for (CPhi &cp : cphis) {
    if (!top)
      set(cp.P, cp.acc);   // a nested unit: bound once per outer trip
    else if (ctx.bound(cp.P))
      ctx.rebind(cp.P, {cp.acc});   // an earlier unit's binding, its value the initial of this one's
    else
      ctx.bindFields(cp.P, {cp.acc});
  }
  for (XAcc &xa : xaccs)
    ctx.rebind(xa.V, {xa.acc});
  for (TripPhi &tp : tripPhis) {
    fatptr::bindTripPointer(ctx, *tp.P, tp.tag, tp.objs);
    ctx.bindFields(tp.P, {tp.tag});
  }
}

} // namespace

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
  Cutoff(ctx, A).lowerLoop(*mL, seed, c, !B || *B > K, true);
}

namespace exits {

void lowerNestedCutoff(LoweringContext &ctx, Loop &L, Value *seed) {
  Function &F = *L.getHeader()->getParent();
  Analyses A(F);
  Loop *mL = A.LI.getLoopFor(L.getHeader());
  if (!mL || mL->getHeader() != L.getHeader())
    internalError("loops-cutoff: the loop is not a natural loop of the function's LoopInfo", L.getHeader());
  if (!seed)
    internalError("loops-cutoff: a nested K-loop with no seed", L.getHeader());
  unsigned K = ctx.K(mL);
  std::optional<uint64_t> B = cutoffBound(*mL, A.SE, ctx.T, ctx.S);
  unsigned c = B ? unsigned(std::min<uint64_t>(K, *B)) : K;
  Cutoff(ctx, A).lowerLoop(*mL, seed, c, !B || *B > K, false);
}

bool Unit::contains(const Loop &L, const BasicBlock *b) const {
  return L.contains(b) || is_contained(arm, b) || is_contained(abort, b);
}

Unit unitOf(const Loop &L) {
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
    SmallPtrSet<BasicBlock *, 8> seen{x};
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
        if (seen.insert(s).second)
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
  for (BasicBlock *x : U.live) {
    c = PDT.findNearestCommonDominator(c, x);
    if (!c)
      unimplemented("loops-cutoff: a rule-14 loop whose live exits have no common post-dominator (cq-0dvv)", x->getTerminator());
  }
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
  for (BasicBlock *b : arm)
    for (BasicBlock *p : predecessors(b))
      if (!L.contains(p) && !arm.count(p))
        unimplemented("loops-cutoff: a block between a rule-14 loop's exits and their join that is also entered from "
                      "outside the loop (cq-0dvv)",
                      b->getTerminator());
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
  for (auto it = post.rbegin(); it != post.rend(); ++it)
    U.arm.push_back(*it);
  return U;
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

std::optional<uint64_t> cutoffBound(const Loop &L, ScalarEvolution &SE, const TaintInfo &T, const Specialization &S) {
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
  if (minusOne)
    --*n;
  if (*n == 0)
    return std::nullopt;
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
    --n;
  if (n == 0)
    return std::nullopt;
  return n;
}

// CLAUDE.md "K per loop", first match wins: the per-function flag, CQ_K(f, k) (the `used` constant
// __cq_k_<f>), the global flag, 4.
unsigned resolveK(const Function &F, const KOptions &KO) {
  auto it = KO.perFunction.find(F.getName().str());
  if (it != KO.perFunction.end() && it->second > 0)
    return it->second;
  if (const GlobalVariable *GV = F.getParent()->getGlobalVariable(("__cq_k_" + F.getName()).str(), true))
    if (GV->hasInitializer())
      if (auto *CI = dyn_cast<ConstantInt>(GV->getInitializer()))
        if (CI->getZExtValue() > 0)
          return unsigned(CI->getZExtValue());
  if (KO.global && *KO.global > 0)
    return *KO.global;
  return 4;
}

// Rule 14, recursion with quantum depth (98): one clone per level _d1.._dC (taint publishes them), C =
// min(K, B); the recursive call at level C is CUT: its value is a fresh |0> rail per quantum scalar field
// (a seed, rule 7: freed directly once its readers are uncomputed; a classical field is the constant 0), a
// void cut call is nothing. The overflow predicate "the cut level would recurse once more" is kept iff
// B > K or no bound is known; with B <= K the call never runs and nothing is kept (98).
void lowerQuantumDepthRecursion(LoweringContext &ctx, llvm::CallBase &CB, unsigned K, std::optional<uint64_t> B) {
  LLVMContext &C = ctx.M.getContext();
  if (!B || *B > K)
    unimplemented("loops-cutoff: a quantum-depth recursion cut at K with B > K or no bound: the kept overflow "
                  "predicate (rule 14) is a rail kept inside a level clone, which calls does not return to the "
                  "caller nor the checker count as kept (cq-ew5z)",
                  &CB);
  if (CB.getType()->isVoidTy())
    return;
  // The scalar leaves of the result (rules 25, 26: struct and array elements, vector lanes).
  SmallVector<Type *, 4> leaves;
  std::function<void(Type *)> walk = [&](Type *t) {
    if (auto *st = dyn_cast<StructType>(t)) {
      for (Type *e : st->elements())
        walk(e);
    } else if (auto *a = dyn_cast<ArrayType>(t)) {
      for (uint64_t k = 0; k < a->getNumElements(); ++k)
        walk(a->getElementType());
    } else if (auto *v = dyn_cast<FixedVectorType>(t)) {
      for (unsigned k = 0; k < v->getNumElements(); ++k)
        leaves.push_back(v->getElementType());
    } else {
      leaves.push_back(t);
    }
  };
  walk(CB.getType());
  SmallVector<bool, 4> mask = ctx.T.fieldMask(&CB, ctx.S);
  if (mask.size() != leaves.size())
    internalError("loops-cutoff: a cut recursive call whose field mask does not match its leaves", &CB);
  SmallVector<Operand, 4> fields;
  for (size_t k = 0; k < leaves.size(); ++k) {
    Type *t = leaves[k];
    if (!mask[k]) {
      fields.push_back(Operand{Constant::getNullValue(t), false});
      continue;
    }
    if (!(t->isIntegerTy() || t->isFloatingPointTy()))
      unimplemented("loops-cutoff: a cut recursive call with a quantum pointer field (rule 21: the null fat pointer; "
                    "fatptr has no entry binding a call result; cq-p45s)",
                    &CB);
    RailType w = railOf(t);
    CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(C, w))});
    ctx.unc().recordSeed(z);
    fields.push_back(Operand{z, true});
  }
  if (leaves.size() == 1 && !isa<StructType>(CB.getType()) && !isa<ArrayType>(CB.getType()) &&
      !isa<VectorType>(CB.getType()) && fields[0].handle)
    ctx.bind(&CB, fields[0].v);
  else
    ctx.bindFields(&CB, fields);
}

} // namespace cq::loops
