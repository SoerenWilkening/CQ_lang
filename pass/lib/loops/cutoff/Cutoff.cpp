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

#include "cq/Predicate.h"
#include "cq/Uncompute.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
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
  BasicBlock *X = L.getUniqueExitBlock();
  if (!X)
    unimplemented("loops-cutoff: a K-loop with more than one exit block", H->getTerminator());
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
  for (BasicBlock *e : exiting)
    if (regionForm ? !region.count(e) : e != latch)
      unimplemented(regionForm ? "loops-cutoff: a header-tested K-loop with an exit outside its test region"
                               : "loops-cutoff: a K-loop exiting from a block other than its latch",
                    e->getTerminator());

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
  for (BasicBlock *b : L.blocks())
    for (Instruction &I : *b) {
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
        continue;   // the last region evaluation holds it (frozen state)
      }
      PHINode *h = headerPhiWithNext(&I);
      if (!h || !isQ(h))
        unimplemented("loops-cutoff: a value read after a K-loop that is not the latch incoming of a quantum "
                      "header phi",
                      &I);
      exitRebinds.push_back({&I, h});
    }
  std::vector<std::pair<PHINode *, PHINode *>> exitPhis;   // exit phi -> header phi it denotes
  if (!regionForm) {
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
          for (PHINode *c : hphis)
            if (c->getIncomingValueForBlock(pre) == v &&
                (ctx.preds().edge(u, X) & pH).isBottom()) {
              h = c;
              break;
            }
        }
        if (!h || (id && id != h) || !isQ(h))
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

  // The state: header phis bound to their initial values (a classical initial value of a quantum phi
  // becomes a seed rail).
  for (PHINode *h : hphis) {
    if (!h->getType()->isIntegerTy() && !h->getType()->isFloatingPointTy())
      unimplemented("loops-cutoff: a carried value that is not a scalar (aggregates, pointers)", h);
    Operand init = ctx.operand(h->getIncomingValueForBlock(pre));
    if (isQ(h) && !init.handle)
      init = Operand{seedRail(init.v, h->getType()), true};
    if (!isQ(h) && init.handle)
      internalError("loops-cutoff: a classical header phi with a rail initial value", h);
    set(h, init);
  }

  DenseSet<const PHINode *> boundThisTrip;
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
        std::optional<uint64_t> B = tripBound(*mS, A.SE);
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
          lowerInstruction(ctx, I);
          continue;
        }
        if (!tripFlag)
          tripFlag = conj(q, local.find(b)->second, b->getTerminator());
        lowerInstruction(ctx, I, tripFlag);
      }
    }
  };
  auto advance = [&](Value *q) {
    std::vector<Operand> next;
    for (PHINode *h : hphis)
      next.push_back(ctx.operand(h->getIncomingValueForBlock(latch)));
    for (size_t i = 0; i < hphis.size(); ++i) {
      PHINode *h = hphis[i];
      Operand nx = next[i];
      if (!isQ(h)) {
        if (nx.handle)
          internalError("loops-cutoff: a classical carried value with a rail next value", h);
        set(h, nx);
        continue;
      }
      Operand cur = ctx.operand(h);
      if (!cur.handle)
        internalError("loops-cutoff: a quantum carried value with no rail", h);
      if (nx.handle && nx.v == cur.v)
        continue;
      abi::TemplateSpec spec;
      spec.op = "select";
      spec.w = railTypeOf(h->getType());
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
    lowerBlocks(q, inRegion);
    q = conj(q, regionCont, at);
    for (unsigned j = 0; j < c; ++j) {
      lowerBlocks(q, inBody);
      advance(q);
      lowerBlocks(q, inRegion);
      q = conj(q, regionCont, at);
    }
  } else {
    auto all = [](const BasicBlock *) { return true; };
    for (unsigned j = 0; j < c; ++j) {
      lowerBlocks(q, all);
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
  for (auto &[v, h] : exitRebinds)
    ctx.rebind(v, {ctx.operand(h)});
  for (auto &[P, h] : exitPhis) {
    Operand f = ctx.operand(h);
    if (top)
      ctx.bindFields(P, {f});
    else
      set(P, f);
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
