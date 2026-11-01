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
// Not built yet (internal errors, never a fallback): a classical branch or a switch in the body, a classical-
// bound sub-loop, several latches or pre-header incomings, an exit value that is not as described.
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
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/TargetParser/Triple.h"

using namespace llvm;

namespace cq::loops {

namespace {

// The oracle's header test region (checker/oracle/OracleInstr.cpp, cq-arch T1.2): returns whether a
// header run can leave through it, and the region's blocks.
bool testRegion(const Loop &L, SmallPtrSetImpl<const BasicBlock *> &region) {
  BasicBlock *H = L.getHeader();
  bool exits = false;
  SmallVector<BasicBlock *, 4> work{H};
  region.insert(H);
  while (!work.empty()) {
    BasicBlock *B = work.pop_back_val();
    if (L.isLoopExiting(B))
      exits = true;
    for (BasicBlock *S : successors(B)) {
      if (!L.contains(S) || S == H || region.count(S) || S->getSinglePredecessor() != B || L.isLoopLatch(S) ||
          !L.isLoopExiting(S))
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
    RailType w = railTypeOf(ty);
    CallInst *s = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {classical});
    ctx.unc().recordSeed(s);
    return s;
  }
  // q & flag(p): the conjunction of a trip predicate with a predicate local to the trip.
  Value *conj(Value *q, const Pred &p, const Instruction *at) {
    if (p.isBottom())
      internalError("loops-cutoff: a trip predicate conjoined with false", at);
    Value *f = ctx.preds().flag(ctx, p.quantumPart(ctx.T, ctx.S));
    if (!p.classicalFactor(ctx.T, ctx.S).isTop())
      unimplemented("loops-cutoff: a classical condition inside a K-loop trip", at);
    if (!f)
      return q;
    return andRail(q, f);
  }
};

void Cutoff::lowerLoop(Loop &L, Value *seed, unsigned c, bool keep, bool top) {
  BasicBlock *H = L.getHeader();
  BasicBlock *latch = L.getLoopLatch();
  if (!latch)
    unimplemented("loops-cutoff: a K-loop with more than one latch", H->getTerminator());
  BasicBlock *pre = L.getLoopPredecessor();
  if (!pre)
    unimplemented("loops-cutoff: a K-loop header with more than one predecessor outside the loop", H->getTerminator());
  // The unit (Exits.h): its continuation and exit arm; an exit into an effect-free dead end is no exit.
  exits::Unit U = exits::unitOf(L);
  auto liveEdge = [&](const BasicBlock *s) { return !L.contains(s) && is_contained(U.live, s); };
  BasicBlock *X = U.multi() ? nullptr : U.cont;
  if (U.multi() && !top)
    unimplemented("loops-cutoff: a nested K-loop with more than one live exit block", H->getTerminator());
  if (c == 0)
    internalError("loops-cutoff: a cutoff of 0 trips", H->getTerminator());

  // Sub-loops: each is a quantum-exit loop of its own (nested K-loops).
  for (Loop *S : L.getSubLoops())
    if (classify(*S, ctx.T, ctx.S) != Case::QuantumExit)
      unimplemented("loops-cutoff: a sub-loop of a K-loop that is not itself a quantum-exit loop",
                    S->getHeader()->getTerminator());

  // The body: pure instructions, quantum or unconditional branches only.
  for (BasicBlock *b : L.blocks()) {
    for (Instruction &I : *b) {
      if (isa<PHINode>(I) || isa<DbgInfoIntrinsic>(I))
        continue;
      if (auto *br = dyn_cast<BranchInst>(&I)) {
        if (br->isConditional() && !isQ(br->getCondition()))
          unimplemented("loops-cutoff: a classical branch inside a K-loop body", br);
        continue;
      }
      if (I.isTerminator())
        unimplemented("loops-cutoff: a terminator other than br inside a K-loop body", &I);
    }
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
  if (multi && !top)
    unimplemented(regionForm ? "loops-cutoff: a nested header-tested K-loop with an exit outside its test region"
                             : "loops-cutoff: a nested K-loop exiting from a block other than its latch",
                  H->getTerminator());
  if (multi)
    for (BasicBlock *e : exiting)
      if (A.LI.getLoopFor(e) != &L && any_of(successors(e), liveEdge))
        unimplemented("loops-cutoff: a multi-exit K-loop with an exit from inside a sub-loop", e->getTerminator());

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
  // The outermost sub-loop of L holding b, or nullptr.
  auto subLoopOf = [&](const BasicBlock *b) -> Loop * {
    Loop *l = A.LI.getLoopFor(b), *last = nullptr;
    while (l && l != &L) {
      last = l;
      l = l->getParentLoop();
    }
    return last;
  };

  // Predicates local to one trip (relative to the header), over the body's own branch conditions.
  DenseMap<const BasicBlock *, Pred> local;
  auto edgeCond = [&](BasicBlock *p, BasicBlock *b) -> Pred {
    auto *br = dyn_cast<BranchInst>(p->getTerminator());
    if (!br)
      unimplemented("loops-cutoff: a K-loop edge from a terminator other than br", p->getTerminator());
    if (!br->isConditional() || br->getSuccessor(0) == br->getSuccessor(1))
      return Pred::top();
    Pred a = Pred::atom(br->getCondition());
    return br->getSuccessor(0) == b ? a : !a;
  };
  auto contribution = [&](BasicBlock *p, BasicBlock *b) -> Pred {
    if (Loop *S = subLoopOf(p); S && !S->contains(b)) {
      if (S->getUniqueExitBlock() != b)
        unimplemented("loops-cutoff: a nested K-loop with more than one exit block", p->getTerminator());
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
  Pred cont = local.find(latch)->second & edgeCond(latch, H);   // body form
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
  for (BasicBlock *b : L.blocks())
    for (Instruction &I : *b) {
      if (multi)
        break;   // multi-exit form: read below, through C's phis only
      if (tripSite(I) && any_of(I.users(), [&](const User *u) {
            return !L.contains(cast<Instruction>(u)->getParent());
          })) {
        if (regionForm || !top || !X)
          unimplemented("loops-cutoff: an allocation of a K-loop read after the loop, outside a top-level single-exit "
                        "body-form K-loop (rule 14 trip objects)",
                        &I);
        ArrayRef<ObjectId> objs = ctx.T.provenance(&I, ctx.S);
        if (objs.size() != 1 || ctx.T.classOf(objs.front()) != ObjClass::Slot)
          unimplemented("loops-cutoff: a K-loop trip object read after the loop that is not one slot object (a QRAM or "
                        "host object per trip)",
                        &I);
        if (!A.DT.dominates(I.getParent(), latch))
          unimplemented("loops-cutoff: a K-loop trip object whose allocation does not dominate the latch", &I);
        bool deref = false;
        for (auto it = std::next(I.getIterator()); it != I.getParent()->end(); ++it)
          if (const Value *ap = getLoadStorePointerOperand(&*it); ap && ap->stripInBoundsConstantOffsets() == &I)
            deref = true;
        if (!deref)
          unimplemented("loops-cutoff: a K-loop trip object not dereferenced in its allocation's block (it may be "
                        "null: rule 21's tag compare needs distinct non-null objects)",
                        &I);
        for (const Use &U : I.uses()) {
          auto *P = dyn_cast<PHINode>(U.getUser());
          if (L.contains(cast<Instruction>(U.getUser())->getParent()))
            continue;
          if (!P || P->getParent() != X || P->getIncomingBlock(U) != latch)
            unimplemented("loops-cutoff: a K-loop trip object read after the loop other than by a phi of the exit "
                          "block on the latch's exit edge",
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
        if (!region.count(b))
          unimplemented("loops-cutoff: a value of a header-tested K-loop's body read after the loop", &I);
        if (!isQ(&I)) {
          // A classical value is the last region evaluation's, not the exit trip's: only an affine
          // induction's exit value is built (its exit rail, CR rule 14).
          auto *h = dyn_cast<PHINode>(&I);
          if (!h || h->getParent() != H || !h->getType()->isIntegerTy())
            unimplemented("loops-cutoff: a classical value of a K-loop's test region read after the loop that is "
                          "not an affine induction's exit value",
                          &I);
          exitRail.insert({h, Operand{nullptr, false}});
          exitRebinds.push_back({&I, h});
        } else {
          regionQReads.push_back(&I);
        }
        continue;   // the last region evaluation holds it (frozen state)
      }
      PHINode *h = headerPhiWithNext(&I);
      if (h && !isQ(h) && h->getType()->isIntegerTy())
        exitRail.insert({h, Operand{nullptr, false}});   // CR rule 14: an affine induction's exit value
      if (!h || (!isQ(h) && !exitRail.count(h)))
        unimplemented("loops-cutoff: a value read after a K-loop that is not the latch incoming of a quantum "
                      "header phi",
                      &I);
      exitRebinds.push_back({&I, h});
    }
  for (TripPhi &tp : tripPhis) {
    PHINode *P = tp.P;
    const Pred &pH = ctx.preds().block(H);
    if (!isQ(P))
      unimplemented("loops-cutoff: a phi of K-loop trip objects that taint calls classical", P);
    if (!pH.classicalFactor(ctx.T, ctx.S).isTop())
      unimplemented("loops-cutoff: a phi of K-loop trip objects of a loop under a classical condition", P);
    for (unsigned i = 0; i < P->getNumIncomingValues(); ++i) {
      BasicBlock *u = P->getIncomingBlock(i);
      Value *v = P->getIncomingValue(i);
      if (L.contains(u)) {
        if (u != latch || v != tp.site)
          unimplemented("loops-cutoff: a phi of K-loop trip objects with another incoming from the loop", P);
        continue;
      }
      if (!isa<ConstantPointerNull>(v) || !(ctx.preds().edge(u, X) & pH).isBottom())
        unimplemented("loops-cutoff: a phi of K-loop trip objects whose incoming from outside the loop is not null on "
                      "an edge that skips the loop",
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
                      "with null or a load at a constant offset",
                      cast<Instruction>(u));
      }
    }
  }
  std::vector<std::pair<PHINode *, PHINode *>> exitPhis;   // exit phi -> header phi it denotes
  if (!regionForm && !multi) {
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
            if (c->getIncomingValueForBlock(pre) == v &&
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
        unimplemented("loops-cutoff: an exit phi reading a value from outside the K-loop on an exit edge that is "
                      "not the exit value of a carried value",
                      &P);
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
          if (!phi || phi->getParent() != C || !inUnit(phi->getIncomingBlock(Us)))
            unimplemented("loops-cutoff: a value of a multi-exit K-loop read after the loop other than by a phi of "
                          "its continuation",
                          &I);
        }
    for (BasicBlock *a : U.arm)
      for (Instruction &I : *a) {
        if (auto *br = dyn_cast<BranchInst>(&I)) {
          if (br->isConditional() && !isQ(br->getCondition()))
            unimplemented("loops-cutoff: a classical branch between a K-loop's exits and their join", br);
          continue;
        }
        if (I.isTerminator())
          unimplemented("loops-cutoff: a terminator other than br between a K-loop's exits and their join", &I);
      }
    const Pred &pH = ctx.preds().block(H);
    for (PHINode &P : C->phis()) {
      bool fromUnit = false;
      for (BasicBlock *u : P.blocks())
        fromUnit |= inUnit(u);
      if (!fromUnit)
        continue;
      if (!isQ(&P))
        unimplemented("loops-cutoff: a classical phi joining a multi-exit K-loop's exits", &P);
      if (!(P.getType()->isIntegerTy() || P.getType()->isFloatingPointTy()))
        unimplemented("loops-cutoff: a non-scalar phi joining a multi-exit K-loop's exits", &P);
      const Value *init = nullptr;
      bool outside = false;
      for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) {
        BasicBlock *u = P.getIncomingBlock(i);
        if (inUnit(u))
          continue;
        outside = true;
        if (!(ctx.preds().edge(u, C) & pH).isBottom())
          unimplemented("loops-cutoff: a phi joining a multi-exit K-loop's exits with an incoming from outside the "
                        "loop on an edge that does not exclude the loop",
                        &P);
        if (init && init != P.getIncomingValue(i))
          unimplemented("loops-cutoff: a phi joining a multi-exit K-loop's exits with several incomings from outside "
                        "the loop",
                        &P);
        init = P.getIncomingValue(i);
      }
      if (outside && !pH.classicalFactor(ctx.T, ctx.S).isTop())
        unimplemented("loops-cutoff: a phi joining a multi-exit K-loop's exits and a classical skip of the loop", &P);
      // With no incoming from outside, the value where no trip exits (the cutoff reached first) is 0.
      Operand acc = init ? ctx.operand(init) : Operand{Constant::getNullValue(P.getType()), false};
      if (!acc.handle)
        acc = Operand{seedRail(acc.v, P.getType()), true};
      cphis.push_back({&P, acc});
    }
  }

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
    Value *st = h->getIncomingValueForBlock(pre);
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
    bool ok = true;
    while (ok && V != h) {
      auto *BO = dyn_cast<BinaryOperator>(V);
      if (!BO || !L.contains(BO) || !DT.dominates(BO->getParent(), latch) ||
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
  // Region form: the state is frozen once the loop exited, but an induction's trip value is not, so a
  // read of one after the loop is its exit rail, and a region value computed from one is not built.
  for (Instruction *I : regionQReads) {
    if (auto *h = dyn_cast<PHINode>(I); h && qind.count(h)) {
      exitRebinds.push_back({I, h});
      continue;
    }
    SmallVector<const Value *, 8> work{I};
    SmallPtrSet<const Value *, 16> seen;
    while (!work.empty()) {
      const Value *V = work.pop_back_val();
      auto *VI = dyn_cast<Instruction>(V);
      if (!VI || !L.contains(VI) || !seen.insert(V).second)
        continue;
      if (auto *h = dyn_cast<PHINode>(VI); h && qind.count(const_cast<PHINode *>(h)))
        unimplemented("loops-cutoff: a value of a K-loop's test region computed from an affine induction with a "
                      "quantum start, read after the loop",
                      I);
      if (isa<PHINode>(VI))
        continue;
      for (const Use &U : VI->operands())
        work.push_back(U.get());
    }
  }
  for (auto &[v, h] : exitRebinds)
    if (auto it = qind.find(h); it != qind.end())
      it->second.exitRail = Operand{};
  for (auto &[P, h] : exitPhis)
    if (auto it = qind.find(h); it != qind.end())
      it->second.exitRail = Operand{};

  // The state: header phis bound to their initial values (a classical initial value of a quantum phi
  // becomes a seed rail).
  for (PHINode *h : hphis) {
    // cq-9w75 (CR rule 14 f981c89): a classical pointer into slot, QRAM or fat-pointer memory walked by
    // a constant step is no operand: memory reads it as start + j*step (LoweringContext::walkedPointer),
    // the phi bound to the trip index j, a constant of the unrolled trip.
    if (!isQ(h) && h->getType()->isPointerTy() && nonClassicalMemory(h)) {
      auto *g = dyn_cast<GEPOperator>(h->getIncomingValueForBlock(latch));
      APInt off(64, 0);
      const Value *start = h->getIncomingValueForBlock(pre);
      auto *si = dyn_cast<Instruction>(start);
      if (!g || g->getPointerOperand() != h || !g->accumulateConstantOffset(ctx.M.getDataLayout(), off) ||
          (si && L.contains(si)))
        unimplemented("loops-cutoff: a pointer into slot or QRAM memory carried by a K-loop that is not walked by a "
                      "constant step from a loop-invariant start",
                      h);
      for (const User *u : h->users()) {
        bool ok = u == g || isa<GetElementPtrInst>(u) || (isa<LoadInst>(u) && cast<LoadInst>(u)->getPointerOperand() == h) ||
                  (isa<StoreInst>(u) && cast<StoreInst>(u)->getPointerOperand() == h);
        if (!ok)
          unimplemented("loops-cutoff: a walked pointer of a K-loop used other than as an address", cast<Instruction>(u));
      }
      ctx.bindWalkedPointer(h, WalkedPtr{start, off.getSExtValue()});
      walkedTrip[h] = 0;
      set(h, Operand{ConstantInt::get(Type::getInt64Ty(ctx.M.getContext()), 0), false});
      continue;
    }
    // cq-z6q1 (CR rules 14, 21; 189): a quantum pointer header phi is carried as its fat pointer's tag rail
    // (fatptr R2: every incoming at the start of its objects, so idx is the classical 0 and not carried).
    if (isQ(h) && h->getType()->isPointerTy()) {
      if (exitRail.count(h) || qind.count(h))
        unimplemented("loops-cutoff: a K-loop's carried pointer read after the loop", h);
      fatptr::registerCarried(ctx, *h);
      Operand init = fatptr::carriedTag(ctx, h->getIncomingValueForBlock(pre));
      if (!init.handle)
        init = Operand{seedRail(init.v, Type::getInt32Ty(ctx.M.getContext())), true};
      carriedPtr.insert(h);
      set(h, init);
      continue;
    }
    // A classical pointer header phi is an affine induction (taint, CR rule 14: a walked pointer with a
    // classical start): a classical value in each trip, nothing carried.
    if (!h->getType()->isIntegerTy() && !h->getType()->isFloatingPointTy() && (isQ(h) || !h->getType()->isPointerTy()))
      unimplemented("loops-cutoff: a carried value that is not a scalar (aggregates, pointers)", h);
    Operand init = ctx.operand(h->getIncomingValueForBlock(pre));
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
  std::function<void(BasicBlock *, Value *, const Pred &)> lowerInsts;   // one block's non-phi instructions
  auto lowerBlocks = [&](Value *q, const std::function<bool(const BasicBlock *)> &pick) {
    boundThisTrip.clear();
    for (BasicBlock *b : order) {
      if (!pick(b))
        continue;
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
        if (BasicBlock *SX = mS->getUniqueExitBlock())
          for (PHINode &P : SX->phis())
            if (mine.count(&P))
              boundThisTrip.insert(&P);
        continue;
      }
      if (b != H)
        for (PHINode &P : b->phis()) {
          if (boundThisTrip.count(&P))
            continue;
          if (!isQ(&P))
            unimplemented("loops-cutoff: a classical phi inside a K-loop body", &P);
          set(&P, Operand{lowerMerge(ctx, P), true});
        }
      lowerInsts(b, q, local.find(b)->second);
    }
  };
  // The exit arm and C's phis after one evaluation of the blocks `pick` chose (multi-exit form).
  auto capture = [&](Value *q, const std::function<bool(const BasicBlock *)> &pick) {
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
    for (BasicBlock *b : U.arm) {
      Pred acc = Pred::bottom();
      for (BasicBlock *p : predecessors(b))
        if (auto sp = srcPred(p))
          acc = acc | (*sp & edgeCond(p, b));
      if (acc.isBottom())
        continue;   // not reached from the blocks of this evaluation
      armLocal.insert({b, acc});
      for (PHINode &P : b->phis()) {
        if (!isQ(&P))
          unimplemented("loops-cutoff: a classical phi between a K-loop's exits and their join", &P);
        std::vector<std::pair<Pred, Operand>> arms;
        for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
          if (auto sp = srcPred(P.getIncomingBlock(i)))
            arms.push_back({*sp & edgeCond(P.getIncomingBlock(i), b), ctx.operand(P.getIncomingValue(i))});
        set(&P, Operand{selectChain(ctx, arms, railTypeOf(P.getType())), true});
      }
      lowerInsts(b, q, acc);
    }
    for (CPhi &cp : cphis) {
      std::vector<std::pair<Pred, Operand>> arms;
      Pred E = Pred::bottom();
      for (unsigned i = 0; i < cp.P->getNumIncomingValues(); ++i) {
        BasicBlock *u = cp.P->getIncomingBlock(i);
        auto sp = srcPred(u);
        if (!sp)
          continue;
        Pred e = *sp & edgeCond(u, U.cont);
        if (e.isBottom())
          continue;
        E = E | e;
        arms.push_back({e, ctx.operand(cp.P->getIncomingValue(i))});
      }
      if (arms.empty())
        continue;
      RailType w = railTypeOf(cp.P->getType());
      Value *v = selectChain(ctx, arms, w);
      Value *f = conj(q, E, U.cont->getFirstNonPHI());
      abi::TemplateSpec sel;
      sel.op = "select";
      sel.w = w;
      cp.acc = Operand{ctx.emitTemplate(sel, {Operand{f, true}, Operand{v, true}, cp.acc}), true};
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
          if (varies && (I.getOpcode() == Instruction::UDiv || I.getOpcode() == Instruction::SDiv ||
                         I.getOpcode() == Instruction::URem || I.getOpcode() == Instruction::SRem))
            unimplemented("loops-cutoff: a classical division by a per-trip value of an affine induction in a K-loop "
                          "(computed in trips the C program may not run)",
                          &I);
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
  auto advance = [&](Value *q) {
    std::vector<Operand> next;
    for (PHINode *h : hphis)
      next.push_back(walkedTrip.count(h)    ? Operand{nullptr, false}
                     : carriedPtr.count(h) ? fatptr::carriedTag(ctx, h->getIncomingValueForBlock(latch))
                                           : ctx.operand(h->getIncomingValueForBlock(latch)));
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
          add.w = railTypeOf(h->getType());
          add.shape = "hl";
          Value *inc = ctx.emitTemplate(add, {it->second, Operand{step, false}});
          abi::TemplateSpec sel;
          sel.op = "select";
          sel.w = railTypeOf(h->getType());
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
          sel.w = railTypeOf(h->getType());
          sel.shape = nx.handle ? "" : "lh";
          qi.exitRail = Operand{ctx.emitTemplate(sel, {Operand{q, true}, nx, *qi.exitRail}), true};
        }
        for (auto &[isAdd, c] : qi.steps) {
          Value *cv = ctx.operand(c).v;
          qi.off = isAdd ? ctx.B().CreateAdd(qi.off, cv) : ctx.B().CreateSub(qi.off, cv);
        }
        abi::TemplateSpec add;
        add.op = "add";
        add.w = railTypeOf(h->getType());
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
      spec.w = carriedPtr.count(h) ? RailType{Kind::Int, 32} : railTypeOf(h->getType());   // R2: the tag rail
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
    if (multi)
      capture(q, inRegion);
    q = conj(q, regionCont, at);
    for (unsigned j = 0; j < c; ++j) {
      lowerBlocks(q, inBody);
      if (multi)
        capture(q, inBody);
      Value *qb = bodyExits ? conj(q, cont, latch->getTerminator()) : q;
      advance(q);
      lowerBlocks(qb, inRegion);
      if (multi)
        capture(qb, inRegion);
      q = conj(qb, regionCont, at);
    }
  } else {
    auto all = [](const BasicBlock *) { return true; };
    for (unsigned j = 0; j < c; ++j) {
      lowerBlocks(q, all);
      if (multi)
        capture(q, all);
      captureTrips(q, j);
      Value *qn = conj(q, cont, latch->getTerminator());
      if (qn == q)
        unimplemented("loops-cutoff: a K-loop whose back edge is taken on every path of a trip", latch->getTerminator());
      advance(q);
      q = qn;
    }
  }
  if (q == seed)
    internalError("loops-cutoff: the chain's last predicate is its seed", at);
  if (keep)
    ctx.unc().setRole(ctx.unc().idOf(q), Role::KeptOverflow);

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
  for (CPhi &cp : cphis)
    ctx.bindFields(cp.P, {cp.acc});
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

bool Unit::contains(const Loop &L, const BasicBlock *b) const {
  return L.contains(b) || is_contained(arm, b);
}

Unit unitOf(const Loop &L) {
  Unit U;
  SmallVector<BasicBlock *, 4> exitBlocks;
  L.getUniqueExitBlocks(exitBlocks);
  if (exitBlocks.size() == 1) {
    // One exit block: the unit as before (live or not, a noreturn exit included).
    U.live.push_back(exitBlocks.front());
    U.cont = exitBlocks.front();
    return U;
  }
  for (BasicBlock *x : exitBlocks) {
    // A dead end: no path from x reaches a return or the loop again. One with no effect is UB to reach.
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
    if (effect)
      unimplemented("loops-cutoff: a rule-14 loop exit into a dead end with an effect (a noreturn call: the exit "
                    "is live and the unit has no continuation)",
                    x->getTerminator());
    for (BasicBlock *b : seen)
      if (!is_contained(U.dead, b))
        U.dead.push_back(b);
  }
  if (U.live.empty())
    unimplemented("loops-cutoff: a rule-14 loop with no live exit", L.getHeader()->getTerminator());
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
      unimplemented("loops-cutoff: a rule-14 loop whose live exits have no common post-dominator", x->getTerminator());
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
                      "outside the loop",
                      b->getTerminator());
  // Topological order (DFS post-order reversed); a cycle in the arm is not built.
  SmallPtrSet<BasicBlock *, 8> done, onStack;
  std::vector<BasicBlock *> post;
  std::function<void(BasicBlock *)> dfs = [&](BasicBlock *b) {
    onStack.insert(b);
    for (BasicBlock *s : successors(b)) {
      if (!arm.count(s))
        continue;
      if (onStack.count(s))
        unimplemented("loops-cutoff: a cycle between a rule-14 loop's exits and their join", s->getTerminator());
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
  std::optional<uint64_t> n;
  if (unsigned c = SE.getSmallConstantMaxTripCount(&L))
    n = c;
  else if (!S.bounds.empty()) {
    // CR §1.4: one bound per quantum integer formal whose call-site range bounded it, in formal order.
    const SCEV *btc = SE.getSymbolicMaxBackedgeTakenCount(&L);
    if (!isa<SCEVCouldNotCompute>(btc)) {
      const SCEV *tc = SE.getAddExpr(btc, SE.getOne(btc->getType()));
      Function &F = *L.getHeader()->getParent();
      SmallVector<const Argument *, 4> qints;
      for (const Argument &A : F.args())
        if (A.getType()->isIntegerTy() && A.getType()->getIntegerBitWidth() > 1 && T.isQuantum(&A, S))
          qints.push_back(&A);
      bool uses = any_of(qints, [&](const Argument *A) {
        return SCEVExprContains(tc, [&](const SCEV *x) {
          auto *u = dyn_cast<SCEVUnknown>(x);
          return u && u->getValue() == A;
        });
      });
      if (uses) {
        if (qints.size() != S.bounds.size())
          unimplemented("loops-cutoff: a K-loop in a clone with _b bounds whose bounds cannot be matched to its "
                        "quantum integer formals (some formal had no call-site bound)",
                        L.getHeader()->getTerminator());
        ValueToSCEVMapTy map;
        for (size_t i = 0; i < qints.size(); ++i)
          map[qints[i]] = SE.getUMinExpr(SE.getSCEV(const_cast<Argument *>(qints[i])),
                                         SE.getConstant(qints[i]->getType(), S.bounds[i]));
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
          n = mx.getZExtValue();
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
// min(K, B); the recursive call at level C is CUT: its value is a fresh |0> rail (a seed, rule 7: freed
// directly once its readers are uncomputed), a void cut call is nothing. The overflow predicate "the cut
// level would recurse once more" is kept iff B > K or no bound is known; that kept rail is not built yet
// (unimplemented): with B <= K it is |0> on every branch and nothing is kept (98).
void lowerQuantumDepthRecursion(LoweringContext &ctx, llvm::CallBase &CB, unsigned K, std::optional<uint64_t> B) {
  if (!B || *B > K)
    unimplemented("loops-cutoff: a quantum-depth recursion cut at K with B > K or no bound (the kept overflow "
                  "predicate \"the cut level would recurse once more\", rule 14)",
                  &CB);
  if (CB.getType()->isVoidTy())
    return;
  Type *t = CB.getType();
  if (!(t->isIntegerTy() || t->isFloatingPointTy()))
    unimplemented("loops-cutoff: a cut recursive call with an aggregate, vector or pointer result (rule 14)", &CB);
  RailType w = railTypeOf(t);
  CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                             {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
  ctx.unc().recordSeed(z);
  ctx.bind(&CB, z);
}

} // namespace cq::loops
