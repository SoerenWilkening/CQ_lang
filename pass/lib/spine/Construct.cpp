// Module spine (cq-w0-construct): construct(), the general construction for one specialization
// (cq-arch "construct()"). Contract of LoweringContext and of the walk: SpineInternal.h.
//
// Output function. An entry function keeps its C signature and is rewritten in place (rule 1: its
// formals stay classical, a quantum value it returns is the handle, §1.1 / 162). Its new body is
// built in a temporary function and moved into it once every specialization of the module is
// constructed, so that every construct() of the run reads original bodies only (a later clone, or
// a rule 19 inline of the entry, reads the original). A clone is made by calls::materialize.
//
// Walk. The original blocks are visited in one reverse post-order L. A loop that is not purely
// classical is dispatched as a unit at its header (rule 14). Every other block is lowered
// instruction by instruction under its block predicate. A br or switch on a quantum condition emits
// no control flow: both arms run, linearized along L, each under its predicate (rules 8, 9, 13).
// A classical terminator stays a classical branch; its edge to s is redirected to next(x, s): the
// first block y after x in L with y == s, or y not reachable from x whose nearest common dominator
// with x ends in a quantum terminator (y heads a quantum arm still to run). A quantum terminator
// falls through to the first such y that is a successor or an arm head.
//
// Classical guards (rule 8 at CQ_spec a46894a, P1). A block's predicate is classicalFactor &
// quantumPart. The factor stays a classical branch: the walker tracks, per block, the classical facts
// every output path into it establishes (the classical factors of the real classical edges taken),
// and where the factor is not yet established it emits `br <missing literals>, block, skip` at the
// block's start, skip being the first later block that may run when the guard is false. The literals
// are branch-condition terms of the function (a classical condition, a classical term of a quantum
// condition, a classical switch case), chosen by implication on pred's predicates; the factoring
// itself is pred's.
#include "SpineInternal.h"
#include "../loops/cutoff/Exits.h"
#include "../taint/DeadEnd.h"
#include "../eff/invert/Split.h"

#include "cq/Aggregates.h"
#include "cq/Bus.h"
#include "cq/Effects.h"
#include "cq/Rotation.h"
#include "cq/Switch.h"

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/AttributeMask.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Transforms/Utils/SSAUpdater.h"
#include "llvm/TargetParser/Triple.h"

#include <deque>
#include <functional>

using namespace llvm;

namespace cq {

namespace {

struct PendingEntry {
  Function *F, *NF;
  Type *retType;   // rule 19: the i32 handle replacing a C return type that cannot hold it, or null
  // Rule 13 (b137e75): each address-taken block of F and the distinct block of NF its blockaddress
  // constants denote after the lowering.
  std::vector<std::pair<BasicBlock *, BasicBlock *>> addressed;
};
thread_local std::map<const Module *, std::vector<PendingEntry>> pendingEntries;
// cq-i9wk: per module, the specializations constructed so far (the epilogue runs after the last one), and
// the in-place lowerings' return records (spine::entryReturn).
thread_local std::map<const Module *, size_t> constructedCount;
thread_local std::map<const Function *, spine::EntryReturn> entryReturns;

// Move each lowered entry body into its function. The original bodies are dropped here, after the
// last construct() of the module, when nothing reads them any more.
void finishEntries(Module &M) {
  for (Function &F : M)
    entryReturns.erase(&F);
  auto it = pendingEntries.find(&M);
  if (it == pendingEntries.end())
    return;
  for (PendingEntry &p : it->second) {
    Function &F = *p.F, &NF = *p.NF;
    // Rule 13: every blockaddress constant in the module, initializers included, denotes the lowered block.
    for (auto &[orig, low] : p.addressed)
      orig->replaceAllUsesWith(low);
    for (BasicBlock &BB : F)
      BB.dropAllReferences();
    while (!F.empty())
      F.begin()->eraseFromParent();
    F.splice(F.end(), &NF);
    for (unsigned i = 0; i < F.arg_size(); ++i) {
      NF.getArg(i)->replaceAllUsesWith(F.getArg(i));
      if (F.getArg(i)->getName().empty())
        F.getArg(i)->takeName(NF.getArg(i));
    }
    NF.replaceAllUsesWith(&F);
    NF.eraseFromParent();
  }
  // Rule 19 (193): an entry whose return type the lowering replaced by the i32 handle. Its lowered
  // body moves into a function of the new type that takes the entry's name, attributes (parameter
  // list as in C; no return attributes: the C ones describe the narrow type) and place in the module.
  // Remaining uses of the entry are calls in original bodies the lowering replaced; with opaque
  // pointers they are redirected as they stand.
  for (PendingEntry &p : it->second) {
    if (!p.retType)
      continue;
    Function &F = *p.F;
    FunctionType *FT = FunctionType::get(p.retType, F.getFunctionType()->params(), F.isVarArg());
    Function *F2 = Function::Create(FT, F.getLinkage(), F.getAddressSpace(), "");
    M.getFunctionList().insert(F.getIterator(), F2);
    F2->copyAttributesFrom(&F);
    AttributeList AL = F2->getAttributes();
    F2->setAttributes(AL.removeRetAttributes(F.getContext(), AttributeMask(AL.getRetAttrs())));
    F2->copyMetadata(&F, 0);
    F2->splice(F2->end(), &F);
    for (unsigned i = 0; i < F.arg_size(); ++i) {
      F2->getArg(i)->takeName(F.getArg(i));
      F.getArg(i)->replaceAllUsesWith(F2->getArg(i));
    }
    F2->takeName(&F);
    F.replaceAllUsesWith(F2);
    F.eraseFromParent();
  }
  pendingEntries.erase(it);
}

// The CQ.h surface is consumed by the lowering; its declarations with no use left are dropped.
void dropDeadSurface(Module &M) {
  SmallVector<Function *, 8> dead;
  for (Function &F : M) {
    StringRef n = F.getName();
    bool surface = n.starts_with("cq_theta_") || n.starts_with("cq_measure_") || n == "cq_phi" ||
                   n == "__cq_invert_begin" || n == "__cq_invert_end";
    if (surface && F.isDeclaration() && F.use_empty())
      dead.push_back(&F);
  }
  for (Function *F : dead)
    F->eraseFromParent();
}

// cq-pfpy (rule 9: arm code is computed unguarded, its value reaches every reader). The walk runs a block
// on every output path whose classical facts its predicate meets (Walker::next), so a value minted in a
// classical arm is computed on every path that reaches a reader of it; the output CFG may still route a
// path the classical facts exclude (an edge into a join whose branch condition a later classical branch
// repeats) around its definition. Each such use reads the value through phis at the joins above it,
// the never-taken path's incoming poison (SSAUpdater): the value where the path is feasible.
void reachDefs(Function &OF) {
  DominatorTree DT(OF);
  std::vector<std::pair<Instruction *, SmallVector<Use *, 4>>> bad;
  for (BasicBlock &BB : OF)
    for (Instruction &I : BB) {
      if (I.getType()->isVoidTy() || !DT.isReachableFromEntry(&BB))
        continue;
      SmallVector<Use *, 4> us;
      for (Use &U : I.uses()) {
        auto *UI = dyn_cast<Instruction>(U.getUser());
        if (!UI || !DT.isReachableFromEntry(UI->getParent()))
          continue;
        if (UI->getParent() == &BB && !isa<PHINode>(UI))
          continue;   // an order within one block is no reach of the walk's
        if (!DT.dominates(&I, U))
          us.push_back(&U);
      }
      if (!us.empty())
        bad.push_back({&I, us});
    }
  for (auto &[I, us] : bad) {
    SSAUpdater up;
    up.Initialize(I->getType(), I->getName());
    up.AddAvailableValue(I->getParent(), I);
    for (Use *U : us)
      up.RewriteUse(*U);
  }
}


bool isQuantumTerm(LoweringContext &ctx, const Instruction *t) {
  if (auto *br = dyn_cast<BranchInst>(t))
    return br->isConditional() && spine::isQ(ctx, br->getCondition());
  if (auto *sw = dyn_cast<SwitchInst>(t))
    return spine::isQ(ctx, sw->getCondition());
  if (auto *ib = dyn_cast<IndirectBrInst>(t))
    return spine::isQ(ctx, ib->getAddress());   // rule 13: a switch on the address
  return false;
}

// Rule 13 (b137e75): the distinct destinations of a computed goto, in its destination list's order.
SmallVector<BasicBlock *, 4> computedGotoDestinations(const IndirectBrInst &ib) {
  SmallVector<BasicBlock *, 4> d;
  for (BasicBlock *s : successors(const_cast<IndirectBrInst *>(&ib)))
    if (!is_contained(d, s))
      d.push_back(s);
  return d;
}

// Rule 19 (193): does the entry being lowered return a handle (some return of it is quantum)?
bool returnsHandle(LoweringContext &ctx) {
  for (BasicBlock &BB : *ctx.S.F)
    if (auto *r = dyn_cast<ReturnInst>(BB.getTerminator()))
      if (Value *v = r->getReturnValue(); v && spine::isQ(ctx, v))
        return true;
  return false;
}

// Rule 19 with rule 26 (CR §1.1): the leaves of an entry's aggregate or vector C return type (struct and
// array fields, vector lanes, in order) and whether any return makes each one quantum. The entry returns
// the literal struct of those leaves, the i32 handle where quantum.
void entryLeaves(LoweringContext &ctx, SmallVectorImpl<Type *> &types, SmallVectorImpl<bool> &q) {
  std::function<void(Type *)> walk = [&](Type *Ty) {
    if (auto *ST = dyn_cast<StructType>(Ty))
      for (Type *E : ST->elements())
        walk(E);
    else if (auto *AT = dyn_cast<ArrayType>(Ty))
      for (uint64_t k = 0; k < AT->getNumElements(); ++k)
        walk(AT->getElementType());
    else if (auto *VT = dyn_cast<FixedVectorType>(Ty))
      for (unsigned k = 0; k < VT->getNumElements(); ++k)
        walk(VT->getElementType());
    else
      types.push_back(Ty);
  };
  walk(ctx.S.F->getReturnType());
  q.assign(types.size(), false);
  for (BasicBlock &BB : *ctx.S.F)
    if (auto *r = dyn_cast<ReturnInst>(BB.getTerminator()))
      if (Value *v = r->getReturnValue()) {
        SmallVector<bool, 4> fm = ctx.T.fieldMask(v, ctx.S);
        if (fm.size() != types.size())
          internalError("spine: an entry's return value whose field mask does not match its leaves", r);
        for (unsigned k = 0; k < fm.size(); ++k)
          q[k] = q[k] || fm[k];
      }
}

class Walker {
public:
  Walker(LoweringContext &ctx, Function &F, DominatorTree &DT, LoopInfo &LI)
      : ctx(ctx), sh(spine::shared(ctx)), F(F), DT(DT), LI(LI), PDT(F) {}

  void run();

private:
  LoweringContext &ctx;
  spine::Shared &sh;
  Function &F;
  DominatorTree &DT;
  LoopInfo &LI;
  PostDominatorTree PDT;

  std::vector<BasicBlock *> L;
  DenseMap<const BasicBlock *, unsigned> idx;
  std::vector<BitVector> reach;                         // reach[i][j]: L[j] reachable from L[i], forward edges
  DenseMap<const BasicBlock *, Loop *> unitOf;          // blocks of loops dispatched as units
  DenseSet<const BasicBlock *> pureHeaders;             // headers of purely classical loops walked inline
  DenseMap<const Loop *, loops::exits::Unit> units;     // per unit: continuation and exit arm
  // cq-h8y6: a unit's tail blocks (arm blocks also entered from outside the loop, Exits.h): the loop module
  // lowers them per trip for the unit's paths, the walker once more for the outside paths, under tailPred.
  DenseMap<const BasicBlock *, Loop *> tailOf;
  DenseMap<const BasicBlock *, Pred> tailPreds;
  const Pred &tailPredOf(const BasicBlock *b);
  void tailMerge(PHINode &phi);
  DenseMap<const BasicBlock *, SmallVector<BasicBlock *, 2>> outEdges;
  DenseMap<const BasicBlock *, unsigned> outPreds;
  DenseSet<const BasicBlock *> merged;
  DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, BasicBlock *> edgeOut;
  std::vector<std::pair<PHINode *, PHINode *>> classicalPhis;
  DenseMap<const PHINode *, Value *> unitClassical;   // cq-j5mq: a classical phi's value on its loop unit's output edge
  DenseSet<const Instruction *> visited;
  // cq-lx8f: quantum phis of a unit's exit blocks that the loop module bound (rule 14 case 2: an exit
  // phi identified with a carried value's final state). The walker does not merge them again.
  DenseSet<const PHINode *> unitBoundPhis;
  std::vector<const Instruction *> blockDefs;           // original quantum defs in the current output block
  SmallVector<const BasicBlock *, 4> openRegions;       // ipdoms of quantum terminators not yet reached
  std::unique_ptr<TargetLibraryInfoImpl> tlii;
  std::unique_ptr<TargetLibraryInfo> tli;
  std::unique_ptr<AssumptionCache> ac;
  std::unique_ptr<ScalarEvolution> se;

  bool pureClassical(const Loop &lp);
  BasicBlock *next(const BasicBlock *x, const BasicBlock *s);
  bool classicalEdgeMeets(const BasicBlock *x, const BasicBlock *s, const BasicBlock *y);
  void plan();
  void planGuards();

  struct Lit {
    const Value *v;
    bool neg;
    bool eq;
    APInt val;
    Pred p;
    const BasicBlock *dest = nullptr;   // rule 13: the computed goto case v == blockaddress(dest)
  };
  std::vector<Lit> cands;
  // A guard's condition is a disjunction of cubes, each a conjunction of literals (indices into cands).
  DenseMap<const BasicBlock *, std::pair<std::vector<std::vector<unsigned>>, BasicBlock *>> guards;
  // cq-174f: the classical facts each planned output edge establishes (planGuards), and per original
  // block the output edges actually emitted into its output block, with their facts (and the loop
  // when the edge is a unit's exit). A quantum phi of a block reached by several output edges is
  // factored by them first (factoredMerge).
  DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, Pred> edgeFacts;
  DenseMap<const BasicBlock *, Pred> guardFacts;
  struct InEdge {
    BasicBlock *out;
    std::optional<Pred> facts;
    Loop *unit;
  };
  DenseMap<const BasicBlock *, SmallVector<InEdge, 2>> inEdges;
  void noteIn(const BasicBlock *from, const BasicBlock *to, Loop *unit = nullptr);
  Value *factoredMerge(PHINode &phi);
  void joinUnitPhi(PHINode &phi, ArrayRef<InEdge> in);
  bool eligible(const BasicBlock *y, const BasicBlock *from) const;
  BasicBlock *out(const BasicBlock *b);
  SmallVector<Operand, 4> aggregateFields(ReturnInst *ret, Value *rv);
  void emitBlock(BasicBlock *b);
  void emitGuard(BasicBlock *b);
  void emitBody(BasicBlock *b);
  void emitTerminator(BasicBlock *b);
  void noteEntryReturn(bool frozen, Instruction *t);   // rule 19 (cq-i9wk)
  void emitCloneReturn(ReturnInst *ret);
  bool emitCloneFields(ReturnInst *ret, Value *rv, StructType *st, unsigned extra, SmallVectorImpl<Value *> &vals);
  void resultFields(ReturnInst *ret, Value *rv, StructType *st, unsigned extra, SmallVectorImpl<Value *> &vals);
  Value *returnCopyOut(PHINode &phi);
  DenseSet<const Value *> copiedOut;                    // return phis copied out per edge (cq-mjwb)
  void lowerUnit(Loop &lp);
  void maybeFlush(Instruction *term);
  BasicBlock *regionEndOf(BasicBlock *b);
  void jump(const BasicBlock *from, const BasicBlock *to);
};

bool Walker::pureClassical(const Loop &lp) {
  for (const BasicBlock *b : lp.blocks())
    for (const Instruction &I : *b) {
      if ((!I.getType()->isVoidTy() && spine::isQ(ctx, &I)) || spine::anyQuantumOperand(ctx, I))
        return false;
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (!isa<DbgInfoIntrinsic>(CB) && calls::classify(*CB, ctx.T, ctx.S) != calls::Class::Classical)
          return false;
      // Rules 5, 20: a bus access or a write into the bus is recorded per dynamic access, so the loop is not walked
      // inline: it goes to rule 14's classical-bound construction (loops-classical).
      if (isa<LoadInst>(I) || isa<StoreInst>(I) || isa<MemIntrinsic>(I) || isa<AtomicRMWInst>(I) ||
          isa<AtomicCmpXchgInst>(I) || isa<AllocaInst>(I))
        if (!bus::hostAccess(ctx, I) && !(isa<AllocaInst>(I) && ctx.T.hostResident(&I, ctx.S)))
          return false;
    }
  return true;
}

// Can y run on an output path that takes the classical edge x -> s? The edge fixes the classical factor
// of its predicate; y may run there when its own predicate meets it.
bool Walker::classicalEdgeMeets(const BasicBlock *x, const BasicBlock *s, const BasicBlock *y) {
  if (isQuantumTerm(ctx, x->getTerminator()) || !is_contained(successors(x), s))
    return false;
  // A classical edge into a dead end (`if (c) exit(c);`) ends the path: y's predicate meets it only because a dead
  // end does not restrict its siblings (rules 8, 16).
  if (taint_detail::DeadEnds(F).isDeadEnd(s))
    return false;
  const Pred &e = ctx.preds().edge(x, s), &py = ctx.preds().block(y);
  if (e.isBottom() || py.isBottom())
    return false;
  return predsMeet(py, e.classicalFactor(ctx.T, ctx.S));
}

BasicBlock *Walker::next(const BasicBlock *x, const BasicBlock *s) {
  unsigned i = idx.lookup(x);
  const Loop *xl = LI.getLoopFor(x);
  for (unsigned j = i + 1; j < L.size(); ++j) {
    BasicBlock *y = L[j];
    if (s ? y == s : is_contained(successors(x), y))
      return y;
    // Arm heads only: a block inside a loop the edge does not enter is reached through its header.
    const Loop *yl = LI.getLoopFor(y);
    if (yl && yl->getHeader() != y && !(xl && yl->contains(xl)))
      continue;
    if (unitOf.count(y) && unitOf.lookup(y)->getHeader() != y)
      continue;
    if (reach[i].test(j)) {
      // cq-pfpy (rules 8, 9): y lies downstream of x's other edge, but the classical edge x -> s fixes
      // only its classical facts; the quantum branches above stay linearized. y still runs on this path
      // when its predicate meets those facts (a block also reached through a quantum edge: musl's
      // `isnan(x) || isnan(y)` arm, reached from the quantum test of x and the classical test of y), so
      // the walk visits it here too: its code runs under its own predicate, its pure value arms reach
      // the merge on every path that reads them (rule 9: arm code is computed unguarded).
      if (s && classicalEdgeMeets(x, s, y))
        return y;
      continue;
    }
    BasicBlock *d = DT.findNearestCommonDominator(const_cast<BasicBlock *>(x), y);
    if (d && isQuantumTerm(ctx, d->getTerminator()))
      return y;
    // cq-v11y: y is also an arm still to run when some quantum branch before x reaches both x and y
    // without dominating them (y joins a classical arm not containing x and a quantum edge out of the
    // arm that contains x: 169's __divdc3 block %45, reached from %35's classical false edge and from
    // %37's quantum false edge inside the true arm).
    for (unsigned q = 0; q < i; ++q)
      if (reach[q].test(i) && reach[q].test(j) && isQuantumTerm(ctx, L[q]->getTerminator()) &&
          !(unitOf.count(L[q]) && unitOf.lookup(L[q])->getHeader() != L[q]))
        return y;
  }
  return const_cast<BasicBlock *>(s);
}

void Walker::plan() {
  // Reverse post-order with successors visited last to first, so a branch's first successor (the
  // then arm) comes first in L and its arm is linearized before the else arm (cq-746v). Rule 17
  // (2026-11-02, cq-asfn): of a quantum terminator's successors, those from which no __cq_invert_end is
  // reachable come first, so the other arm's gates run inside the region an end in one arm closes
  // (eff-invert's splitMarkerPaths has split the tail per region depth).
  {
    SmallPtrSet<const BasicBlock *, 16> toEnd = invert::blocksReachingInvertEnd(F);
    auto order = [&](BasicBlock *b) {
      SmallVector<BasicBlock *, 4> o(successors(b));
      if (!toEnd.empty() && o.size() > 1 && isQuantumTerm(ctx, b->getTerminator()))
        std::stable_partition(o.begin(), o.end(), [&](BasicBlock *x) { return !toEnd.count(x); });
      return o;
    };
    std::vector<BasicBlock *> post;
    DenseSet<BasicBlock *> seen;
    std::vector<std::pair<BasicBlock *, SmallVector<BasicBlock *, 4>>> stack;   // block, successors still to visit
    seen.insert(&F.getEntryBlock());
    stack.push_back({&F.getEntryBlock(), order(&F.getEntryBlock())});
    while (!stack.empty()) {
      auto &[b, k] = stack.back();
      if (k.empty()) {
        post.push_back(b);
        stack.pop_back();
        continue;
      }
      BasicBlock *s = k.pop_back_val();
      if (seen.insert(s).second)
        stack.push_back({s, order(s)});
    }
    for (auto it = post.rbegin(); it != post.rend(); ++it) {
      idx[*it] = L.size();
      L.push_back(*it);
    }
  }
  // A loop inside another unit's exit arm or noreturn arm (cq-0dvv: __rem_pio2_large's `while (iq[jz] == 0)`
  // between its recompute loop's exits and their join) is that unit's: the loop module lowers it with the arm.
  DenseSet<const BasicBlock *> inOtherUnit;
  for (Loop *lp : LI.getTopLevelLoops())
    if (!pureClassical(*lp)) {
      loops::exits::Unit U = loops::exits::unitOf(*lp);
      for (auto *list : {&U.arm, &U.dead, &U.abort})
        for (BasicBlock *b : *list)
          if (!is_contained(U.tail, b))   // a loop of the tail runs on the outside paths as a unit of its own
            inOtherUnit.insert(b);
    }
  for (Loop *lp : LI.getTopLevelLoops()) {
    if (inOtherUnit.count(lp->getHeader()))
      continue;
    if (pureClassical(*lp)) {
      for (Loop *sub : lp->getLoopsInPreorder())
        pureHeaders.insert(sub->getHeader());
      continue;
    }
    for (BasicBlock *b : lp->blocks())
      unitOf[b] = lp;
    // A unit with several live exits also holds its exit arm (loops-cutoff Exits.h): the loop module
    // lowers it with the loop, and the unit continues at the exits' join.
    loops::exits::Unit U = loops::exits::unitOf(*lp);
    for (BasicBlock *b : U.arm)
      if (is_contained(U.tail, b))
        tailOf[b] = lp;   // the walker's too (cq-h8y6)
      else
        unitOf[b] = lp;
    for (BasicBlock *b : U.dead)
      unitOf[b] = lp;   // never run (UB to reach): nothing of it is lowered
    for (BasicBlock *b : U.abort)
      unitOf[b] = lp;   // the loop's noreturn arms: the loop module lowers them per trip
    units.insert({lp, std::move(U)});
  }
  // Forward reachability (edges to a later block of L; back edges excluded).
  reach.assign(L.size(), BitVector(L.size()));
  for (unsigned i = L.size(); i-- > 0;) {
    reach[i].set(i);
    for (BasicBlock *s : successors(L[i])) {
      // A unit's own paths into its tail are the loop module's: the unit continues at C (cq-h8y6).
      if (Loop *t = tailOf.lookup(s); t && unitOf.lookup(L[i]) == t)
        continue;
      unsigned j = idx.lookup(s);
      if (j > i)
        reach[i] |= reach[j];
    }
  }

  for (BasicBlock *b : L) {
    if (unitOf.count(b)) {
      Loop *lp = unitOf.lookup(b);
      if (lp->getHeader() != b)
        continue;
      BasicBlock *exit = units.find(lp)->second.cont;
      // The loop as a unit ends at its continuation (its exit block, or the join of its live exits);
      // like any edge leaving b, it continues at the next block of the walk that may run (an arm still
      // to run comes first). With no live exit (CR rule 14 "No live exit") the continuation is
      // unreachable: like an `unreachable` under a quantum predicate, the walk goes on at an arm still
      // to run, if any (next(b, b) matches no later block itself: it returns b when none may run).
      if (!exit) {
        if (BasicBlock *n = next(b, b); n != b)
          outEdges[b].push_back(n);
        continue;
      }
      outEdges[b].push_back(next(b, exit));
      continue;
    }
    Instruction *t = b->getTerminator();
    if (isa<ReturnInst>(t))
      continue;
    if (isa<UnreachableInst>(t)) {
      if (ctx.T.controlTainted(b, ctx.S))
        if (BasicBlock *n = next(b, nullptr))
          outEdges[b].push_back(n);
      continue;
    }
    if (isQuantumTerm(ctx, t)) {
      BasicBlock *n = next(b, nullptr);
      if (!n)
        internalError("spine: a quantum branch with nothing to fall through to", t);
      outEdges[b].push_back(n);
      continue;
    }
    if (isa<CallBrInst>(t))
      unimplemented("spine: asm goto (callbr) in a lowered function: inline asm (rule 27) waits for its CQ_spec "
                    "example (build step 3)",
                    t);
    if (auto *ib = dyn_cast<IndirectBrInst>(t)) {
      // Rule 13: a classical computed goto is a classical switch on its address, one out edge per distinct
      // destination (emitTerminator's compare chain).
      for (BasicBlock *s : computedGotoDestinations(*ib)) {
        bool back = idx.lookup(s) <= idx.lookup(b);
        outEdges[b].push_back(back ? s : next(b, s));
      }
      continue;
    }
    if (!isa<BranchInst>(t) && !isa<SwitchInst>(t))
      internalError("spine: an exception handling terminator (invoke, resume, catchswitch, cleanupret, "
                    "catchret): IR the pinned pipeline cannot emit (CR §0, rule 25)",
                    t);
    for (BasicBlock *s : successors(b)) {
      bool back = idx.lookup(s) <= idx.lookup(b);
      outEdges[b].push_back(back ? s : next(b, s));
    }
  }
  planGuards();
  for (auto &e : outEdges)
    for (BasicBlock *t : e.second)
      ++outPreds[t];
  for (auto &g : guards)
    ++outPreds[g.second.second];

  // A block reached only by an unconditional jump from the block emitted just before it continues
  // in that output block (no classical phi, not a loop header).
  const BasicBlock *prev = nullptr;
  for (BasicBlock *b : L) {
    if (unitOf.count(b) && unitOf.lookup(b)->getHeader() != b)
      continue;
    if (prev) {
      auto pe = outEdges.find(prev);
      bool uncond = pe != outEdges.end() && pe->second.size() == 1 && pe->second.front() == b;
      bool classicalPhi = false;
      for (PHINode &phi : b->phis())
        classicalPhi |= !spine::isQ(ctx, &phi);
      // Rule 13 (b137e75): an address-taken block keeps its identity, an output block of its own.
      if (uncond && outPreds.lookup(b) == 1 && !classicalPhi && !pureHeaders.count(b) && !unitOf.count(b) &&
          !b->hasAddressTaken())
        merged.insert(b);
      // A unit's exit continues where the loop module leaves the builder when the unit is its only
      // way in and it comes next; otherwise (a zero-trip guard's skip edge also reaches it, 41, 177)
      // the unit ends in a jump to it (emitBlock).
      if (unitOf.count(prev) && pe != outEdges.end() && !pe->second.empty() && pe->second.front() == b &&
          outPreds.lookup(b) == 1 && !b->hasAddressTaken())
        merged.insert(b);
    }
    prev = b;
  }
}

// Can the walk continue at y after leaving `from`? Blocks inside a loop are entered by its header.
bool Walker::eligible(const BasicBlock *y, const BasicBlock *from) const {
  const Loop *yl = LI.getLoopFor(y);
  const Loop *fl = LI.getLoopFor(from);
  if (yl && yl->getHeader() != y && !(fl && yl->contains(fl)))
    return false;
  if (unitOf.count(y) && unitOf.lookup(y)->getHeader() != y)
    return false;
  return true;
}

void Walker::planGuards() {
  // Candidate literals: classical branch conditions, classical terms of quantum conditions, cases of
  // classical switches.
  DenseSet<const Value *> seen;
  std::function<void(const Value *)> terms = [&](const Value *c) {
    if (!c->getType()->isIntegerTy(1) || isa<Constant>(c) || !seen.insert(c).second)
      return;
    if (!spine::isQ(ctx, c))
      cands.push_back(Lit{c, false, false, APInt(), Pred::atom(c)});
    if (auto *bo = dyn_cast<BinaryOperator>(c)) {
      if (bo->getOpcode() == Instruction::And || bo->getOpcode() == Instruction::Or ||
          bo->getOpcode() == Instruction::Xor) {
        terms(bo->getOperand(0));
        terms(bo->getOperand(1));
      }
    } else if (auto *sel = dyn_cast<SelectInst>(c)) {
      terms(sel->getCondition());
      terms(sel->getTrueValue());
      terms(sel->getFalseValue());
    }
  };
  for (BasicBlock *b : L) {
    Instruction *t = b->getTerminator();
    if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional())
      terms(br->getCondition());
    if (auto *sw = dyn_cast<SwitchInst>(t); sw && !spine::isQ(ctx, sw->getCondition()))
      for (auto &cs : sw->cases())
        cands.push_back(Lit{sw->getCondition(), false, true, cs.getCaseValue()->getValue(),
                            Pred::eqAtom(sw->getCondition(), cs.getCaseValue()->getValue())});
    if (auto *ib = dyn_cast<IndirectBrInst>(t); ib && !spine::isQ(ctx, ib->getAddress())) {
      SmallVector<BasicBlock *, 4> ds = computedGotoDestinations(*ib);
      for (unsigned k = 0; k + 1 < ds.size(); ++k)
        cands.push_back(Lit{ib->getAddress(), false, false, APInt(), computedGotoEdge(*ib, ds[k]), ds[k]});
    }
  }
  {
    size_t n = cands.size();
    for (size_t i = 0; i < n; ++i) {
      Lit l = cands[i];
      l.neg = true;
      l.p = !l.p;
      cands.push_back(l);
    }
  }

  DenseMap<const BasicBlock *, Pred> in;
  auto add = [&](const BasicBlock *to, const Pred &f) {
    auto it = in.find(to);
    if (it == in.end())
      in.insert({to, f});
    else
      it->second = it->second | f;
  };
  in.insert({L.front(), Pred::top()});
  auto fact = [&](const BasicBlock *from, const BasicBlock *to, const Pred &f) {
    auto it = edgeFacts.find({from, to});
    if (it == edgeFacts.end())
      edgeFacts.insert({{from, to}, f});
    else
      it->second = it->second | f;
  };
  for (BasicBlock *b : L) {
    if (unitOf.count(b) && unitOf.lookup(b)->getHeader() != b)
      continue;
    const Loop *bl = LI.getLoopFor(b);
    bool inPure = bl && !unitOf.count(b);
    auto ii = in.find(b);
    Pred inB = ii == in.end() ? Pred::top() : ii->second;
    const Pred &p = ctx.preds().block(b);
    Pred cf = p.isBottom() ? Pred::top() : p.classicalFactor(ctx.T, ctx.S);

    // A purely classical loop keeps its CFG exactly: its classical facts are the CFG's.
    if (!inPure && !(inB & !cf).isBottom()) {
      std::vector<unsigned> sel;
      Pred conj = Pred::top();
      for (unsigned k = 0; k < cands.size(); ++k) {
        const Lit &l = cands[k];
        if (!(cf & !l.p).isBottom() || (inB & conj & !l.p).isBottom())
          continue;
        if (auto *def = dyn_cast<Instruction>(l.v); def && !DT.dominates(def, b))
          continue;
        sel.push_back(k);
        conj = conj & l.p;
      }
      std::vector<std::vector<unsigned>> cubes{sel};
      if (!(inB & conj & !cf).isBottom()) {
        // The factor is no conjunction of literals here (c1 || c2): a disjunction of cubes over the
        // literals that dominate b, found by splitting on one literal at a time until each cube implies
        // the factor (or contradicts it) on the facts established here (rule 8: the factor is a function
        // of classical branch-condition terms; the cover is that function, evaluated at b).
        size_t half = cands.size() / 2;   // cands[k + half] is cands[k] negated
        std::vector<unsigned> atoms;
        for (unsigned k = 0; k < half; ++k) {
          const Lit &l = cands[k];
          if (auto *def = dyn_cast<Instruction>(l.v); def && !DT.dominates(def, b))
            continue;
          if ((inB & cf & l.p).isBottom() && (inB & cf & !l.p).isBottom())
            continue;
          atoms.push_back(k);
        }
        cubes.clear();
        bool ok = true;
        std::function<void(std::vector<unsigned> &, const Pred &, size_t)> cover =
            [&](std::vector<unsigned> &cube, const Pred &c, size_t next) {
              if (!ok || (inB & c).isBottom() || (inB & c & cf).isBottom())
                return;
              if ((inB & c & !cf).isBottom()) {
                cubes.push_back(cube);
                return;
              }
              if (next == atoms.size() || cubes.size() > 64) {
                ok = false;
                return;
              }
              unsigned k = atoms[next];
              for (unsigned lit : {k, unsigned(k + half)}) {
                cube.push_back(lit);
                cover(cube, c & cands[lit].p, next + 1);
                cube.pop_back();
              }
            };
        std::vector<unsigned> cube;
        cover(cube, Pred::top(), 0);
        if (!ok)
          unimplemented("spine: the classical factor of a block predicate depends on a branch condition that does "
                        "not dominate the block (rule 8)",
                        b->getTerminator());
        conj = Pred::bottom();
        for (const std::vector<unsigned> &cb : cubes) {
          Pred q = Pred::top();
          for (unsigned lit : cb)
            q = q & cands[lit].p;
          conj = conj | q;
        }
        if (!(inB & conj & !cf).isBottom() || !(inB & cf & !conj).isBottom())
          internalError("spine: a classical guard cover that is not the block's factor", b->getTerminator());
      }
      BasicBlock *skip = nullptr;
      for (unsigned j = idx.lookup(b) + 1; j < L.size() && !skip; ++j) {
        BasicBlock *y = L[j];
        if (!eligible(y, b))
          continue;
        const Pred &py = ctx.preds().block(y);
        Pred cfy = py.isBottom() ? Pred::bottom() : py.classicalFactor(ctx.T, ctx.S);
        if (!(cfy & !conj).isBottom())
          skip = y;
      }
      if (!skip)
        internalError("spine: a classical guard with nothing to skip to", b->getTerminator());
      // A classical phi of skip takes the skip edge's value from the original edges its facts admit
      // (run(): classical phis are completed per output edge).
      guards[b] = {cubes, skip};
      add(skip, inB & !conj);
      guardFacts.insert({b, inB & !conj});
    }
    Pred outB = inB & cf;

    if (unitOf.count(b)) {
      if (outEdges.lookup(b).empty())
        continue;   // a unit with no live exit and nothing after it (CR rule 14 "No live exit")
      add(outEdges[b].front(), outB);
      fact(b, outEdges[b].front(), outB);
      continue;
    }
    Instruction *t = b->getTerminator();
    auto oe = outEdges.find(b);
    if (oe == outEdges.end())
      continue;
    if (isQuantumTerm(ctx, t) || isa<UnreachableInst>(t)) {
      for (BasicBlock *n : oe->second) {
        add(n, outB);
        fact(b, n, outB);
      }
      continue;
    }
    for (unsigned k = 0; k < t->getNumSuccessors(); ++k) {
      BasicBlock *s = t->getSuccessor(k), *tg = oe->second[k];
      if (idx.lookup(s) <= idx.lookup(b))
        continue;   // a back edge of a purely classical loop
      Pred f = tg == s ? outB & ctx.preds().edge(b, s).classicalFactor(ctx.T, ctx.S) : outB;
      add(tg, f);
      fact(b, tg, f);
    }
  }
}

BasicBlock *Walker::out(const BasicBlock *b) {
  auto it = sh.blocks.find(b);
  if (it != sh.blocks.end())
    return it->second;
  if (merged.count(b))
    internalError("spine: a branch to a block merged into its predecessor");
  BasicBlock *nb = BasicBlock::Create(ctx.M.getContext(), "", &ctx.out());
  sh.blocks[b] = nb;
  return nb;
}

// The block where the region of b's quantum terminator ends: its immediate post-dominator, over the
// paths that return (rules 8, 16: an edge into a dead end, a noreturn or `unreachable` arm, does not
// restrict its siblings, so a quantum `switch` whose default is `unreachable` or a branch with a
// noreturn arm still has its arms' predicates read up to the join of its live arms; the flag rails
// they read stay live until then). nullptr when no path from b returns.
BasicBlock *Walker::regionEndOf(BasicBlock *b) {
  if (PDT.getNode(b) && PDT.getNode(b)->getIDom() && PDT.getNode(b)->getIDom()->getBlock())
    return PDT.getNode(b)->getIDom()->getBlock();
  taint_detail::DeadEnds DE(F);
  if (DE.isDeadEnd(b))
    return nullptr;
  // Does some path from b reach a return without passing x (over blocks that return)?
  auto avoids = [&](const BasicBlock *x) {
    SmallPtrSet<const BasicBlock *, 32> seen{b};
    std::vector<const BasicBlock *> work{b};
    while (!work.empty()) {
      const BasicBlock *u = work.back();
      work.pop_back();
      if (taint_detail::DeadEnds::returns(u))
        return true;
      for (const BasicBlock *s : successors(u))
        if (s != x && !DE.isDeadEnd(s) && seen.insert(s).second)
          work.push_back(s);
    }
    return false;
  };
  for (unsigned j = idx.lookup(b) + 1; j < L.size(); ++j)
    if (reach[idx.lookup(b)].test(j) && !DE.isDeadEnd(L[j]) && !avoids(L[j]))
      return L[j];
  return nullptr;
}

void Walker::maybeFlush(Instruction *term) {
  if (!openRegions.empty())
    return;
  for (const Instruction *d : blockDefs) {
    SmallVector<const Use *, 8> uses;
    spine::readingUses(sh, d, uses);   // through skipped zexts (cq-su3p)
    for (const Use *U : uses)
      if (auto *ui = dyn_cast<Instruction>(U->getUser()); ui && !visited.count(ui))
        return;
  }
  // cq-nqa6 (U7): the handles a later instruction may still read (every binding of an original value
  // with a reading use not lowered yet), so arm-local rails nothing reads any more are resolved here.
  std::vector<Value *> liveLater;
  for (auto &[orig, ops] : sh.binds) {
    SmallVector<const Use *, 8> uses;
    spine::readingUses(sh, orig, uses);
    bool later = any_of(uses, [&](const Use *U) {
      auto *ui = dyn_cast<Instruction>(U->getUser());
      return ui && !visited.count(ui);
    });
    if (later)
      for (const Operand &o : ops)
        if (o.handle)
          liveLater.push_back(o.v);
  }
  ArrayRef<Value *> live(liveLater);
  ctx.unc().flushBefore(term, &live);
}

void Walker::jump(const BasicBlock *from, const BasicBlock *to) {
  if (merged.count(to))
    return;
  BranchInst *br = ctx.B().CreateBr(out(to));
  edgeOut[{from, to}] = br->getParent();
  noteIn(from, to);
  maybeFlush(br);
}

void Walker::noteIn(const BasicBlock *from, const BasicBlock *to, Loop *unit) {
  auto f = edgeFacts.find({from, to});
  inEdges[to].push_back(
      {ctx.B().GetInsertBlock(), f == edgeFacts.end() ? std::nullopt : std::optional<Pred>(f->second), unit});
}

// cq-174f: a quantum phi whose output block is reached by several output edges (a classical guard's
// skip edge, a unit's exit, a classical branch) is factored by the classical facts of those edges
// first (rule 8 / P1: the classical factor stays a classical branch). On each output edge e with facts
// F the incomings whose edge predicate meets F are the candidates; a candidate edge u -> b from
// outside a rule-14 case-3 unit whose exit e is, is absorbed by the unit when, under F, u -> b is
// taken only when the header's predicate is false and its value is the initial value of the carried
// value whose next the unit's own incoming is: the unit's trip predicate starts at the flag of the
// header's quantum predicate (loops-classical's contract), so no trip runs and the carried value
// leaves the unit as that initial value (26 break_with_body: the pre-header test n < 1 || x == k is
// trip -1 of the latch test). An edge keeping one candidate takes its value; an edge keeping several
// takes rule 9's select chain over them, emitted where the edge leaves, each arm under the quantum
// part of its predicate restricted to F (only when that restriction is exact: the arm's classical
// factor is F; g6 of review cq-hqk5, a case-1 loop in an arm `q && c`). The phi is then chosen
// classically: a phi over handles on the output edges, each value read where its edge leaves (a
// classical one seeded there), recorded as a merge (rule 9 at a58c3a4, then cq-bv91's kept arms).
// Otherwise (an output edge with no facts, a non-scalar phi, an inexact restriction) nullptr: the
// merge stays pred's lowerMerge.
Value *Walker::factoredMerge(PHINode &phi) {
  const BasicBlock *b = phi.getParent();
  auto ie = inEdges.find(b);
  if (ie == inEdges.end() || ie->second.size() < 2)
    return nullptr;
  BasicBlock *join = out(b);
  {
    SmallPtrSet<BasicBlock *, 4> outs, preds;
    for (const InEdge &e : ie->second) {
      if (!e.facts || !outs.insert(e.out).second)
        return nullptr;
    }
    for (BasicBlock *p : predecessors(join))
      preds.insert(p);
    if (preds != outs)
      return nullptr;
  }
  RailType w = railTypeOf(phi.getType());
  if (!(phi.getType()->isIntegerTy() || phi.getType()->isFloatingPointTy()))
    return nullptr;
  // Per output edge: one incoming value, or a select chain over several, each arm under the quantum
  // part of its edge predicate restricted to the edge's facts.
  struct Choice {
    BasicBlock *out;
    Pred facts;
    SmallVector<std::pair<Pred, const Value *>, 2> arms;
  };
  std::vector<Choice> chosen;
  for (const InEdge &e : ie->second) {
    const Pred &F = *e.facts;
    SmallVector<unsigned, 2> cands;
    for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
      const BasicBlock *u = phi.getIncomingBlock(i);
      if (!idx.count(u))
        continue;   // an unreachable predecessor never selects
      if ((ctx.preds().edge(u, b) & F).isBottom())
        continue;
      if (none_of(cands, [&](unsigned k) { return phi.getIncomingValue(k) == phi.getIncomingValue(i); }))
        cands.push_back(i);
    }
    if (e.unit && cands.size() > 1 && loops::classify(*e.unit, ctx.T, ctx.S) == loops::Case::ClassicalBoundQuantumExit) {
      Loop &lp = *e.unit;
      const BasicBlock *header = lp.getHeader(), *pre = lp.getLoopPredecessor(), *latch = lp.getLoopLatch();
      const Value *inLoop = nullptr;
      unsigned nIn = 0;
      for (unsigned k : cands)
        if (lp.contains(phi.getIncomingBlock(k))) {
          inLoop = phi.getIncomingValue(k);
          ++nIn;
        }
      const Value *init = nullptr;
      if (nIn == 1 && pre && latch)
        for (const PHINode &h : header->phis())
          if (h.getIncomingValueForBlock(latch) == inLoop && spine::isQ(ctx, &h))
            init = h.getIncomingValueForBlock(pre);
      if (init) {
        const Pred &hp = ctx.preds().block(header);
        SmallVector<unsigned, 2> kept;
        for (unsigned k : cands) {
          const BasicBlock *u = phi.getIncomingBlock(k);
          bool absorbed = !lp.contains(u) && phi.getIncomingValue(k) == init;
          if (absorbed)
            for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i)
              if (phi.getIncomingValue(i) == init && !lp.contains(phi.getIncomingBlock(i)) &&
                  !(ctx.preds().edge(phi.getIncomingBlock(i), b) & F & hp).isBottom())
                absorbed = false;
          if (!absorbed)
            kept.push_back(k);
        }
        cands = kept;
      }
    }
    if (cands.empty())
      return nullptr;
    Choice ch{e.out, F, {}};
    for (unsigned k : cands) {
      // The arm's predicate under F: every incoming edge carrying the same value.
      Pred p = Pred::bottom();
      for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i)
        if (phi.getIncomingValue(i) == phi.getIncomingValue(k) && idx.count(phi.getIncomingBlock(i)))
          p = p | ctx.preds().edge(phi.getIncomingBlock(i), b);
      p = p & F;
      // Its quantum part stands for it under F only when its classical factor is F itself.
      if (cands.size() > 1 && !(F & !p.classicalFactor(ctx.T, ctx.S)).isBottom())
        return nullptr;
      ch.arms.push_back({p.quantumPart(ctx.T, ctx.S), phi.getIncomingValue(k)});
    }
    chosen.push_back(std::move(ch));
  }

  // Each value is read where its edge leaves.
  IRBuilder<> &B = ctx.B();
  std::vector<Operand> ops;
  {
    IRBuilderBase::InsertPointGuard g(B);
    for (Choice &ch : chosen) {
      Instruction *t = ch.out->getTerminator();
      if (!t)
        internalError("spine: the output block of an incoming edge has no terminator yet", &phi);
      B.SetInsertPoint(t);
      if (ch.arms.size() == 1) {
        // cq-pfpy: the one arm may be minted in a block the walk ran on a classical path that joins
        // this edge's path above it.
        const Value *v = ch.arms.front().second;
        Pred p = Pred::bottom();
        for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i)
          if (phi.getIncomingValue(i) == v && idx.count(phi.getIncomingBlock(i)))
            p = p | ctx.preds().edge(phi.getIncomingBlock(i), b);
        ops.push_back(reachingOperand(ctx, ctx.operand(v), w, p, ch.facts));
        continue;
      }
      // Rule 9 on this edge alone: the merge's quantum rest, a select chain where the edge leaves.
      std::vector<std::pair<Pred, Operand>> arms;
      for (auto &[p, v] : ch.arms)
        arms.push_back({p, ctx.operand(v)});
      ops.push_back(Operand{selectChain(ctx, arms, w, ch.facts), true});
    }
    bool anyHandle = any_of(ops, [](const Operand &o) { return o.handle; });
    bool same = all_of(ops, [&](const Operand &o) { return o.v == ops.front().v; });
    if (anyHandle && !same)
      for (unsigned k = 0; k < ops.size(); ++k)
        if (!ops[k].handle) {
          B.SetInsertPoint(chosen[k].out->getTerminator());
          CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {ops[k].v});
          ctx.unc().recordSeed(a);
          ops[k] = Operand{a, true};
        }
  }
  auto seedHere = [&](Value *c) {
    CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {c});
    ctx.unc().recordSeed(a);
    return a;
  };
  if (all_of(ops, [&](const Operand &o) { return o.v == ops.front().v; }))
    return ops.front().handle ? ops.front().v : seedHere(ops.front().v);
  Type *ty = ops.front().v->getType();
  PHINode *np = PHINode::Create(ty, unsigned(ops.size()), phi.getName());
  np->insertInto(join, join->getFirstNonPHIIt());
  for (unsigned k = 0; k < ops.size(); ++k)
    np->addIncoming(ops[k].v, chosen[k].out);
  if (!ops.front().handle)
    return seedHere(np);   // every arm read classically: one value, one rail
  ctx.unc().recordMerge(np);
  return np;
}

// A phi of a unit's continuation that the loop module bound (its value where the unit
// ran: loops-classical's case-3 multi-exit form, 121) and that a classical skip of the unit also
// reaches (the zero-trip guard): a classical phi over handles on the output edges, the unit's binding
// on the unit's edge, on each other edge the one incoming its facts admit (a classical value seeded
// where the edge leaves), recorded as a merge (rule 9 at a58c3a4).
const Pred &Walker::tailPredOf(const BasicBlock *b) {
  auto tp = tailPreds.find(b);
  if (tp == tailPreds.end()) {
    Loop *t = tailOf.lookup(b);
    tp = tailPreds.insert({b, loops::exits::tailPred(ctx, *t, units.find(t)->second, b, DT)}).first;
  }
  return tp->second;
}

// cq-h8y6 (rule 9 at a tail block, CR rule 14): a quantum phi of a unit's tail block on the outside paths merges
// the incomings of those paths only, each under its edge's predicate on them (tailPred & the edge): the unit's own
// edges into the block are the loop module's (its trips' exit flags), and their values do not reach here. One
// value is that value (a classical one seeded, rule 7); several are rule 9's select chain, field by field (a data
// pointer's fat (tag, idx) at their common shape, rule 21; a composite's leaves, rule 26).
void Walker::tailMerge(PHINode &phi) {
  const BasicBlock *b = phi.getParent();
  Loop &lp = *tailOf.lookup(b);
  const loops::exits::Unit &U = units.find(&lp)->second;
  std::vector<std::pair<Pred, const Value *>> kept;
  for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
    const BasicBlock *u = phi.getIncomingBlock(i);
    if (lp.contains(u) || DT.dominates(b, u) || !idx.count(u))
      continue;
    Pred e = Pred::bottom();
    if (is_contained(U.arm, u)) {
      if (!tailOf.count(u))
        continue;   // the unit's path
      e = tailPredOf(u) & ctx.preds().edge(u, b);
    } else {
      e = ctx.preds().edge(u, b);
    }
    if (e.isBottom())
      continue;
    const Value *v = phi.getIncomingValue(i);
    auto same = find_if(kept, [&](const auto &k) { return k.second == v; });
    if (same != kept.end())
      same->first = same->first | e;
    else
      kept.push_back({e, v});
  }
    bool composite = phi.getType()->isAggregateType() || phi.getType()->isVectorTy();
  SmallVector<RailType, 4> ws;
  if (composite) {
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
        ws.push_back(t->isPointerTy() ? RailType{Kind::Int, 64} : railTypeOf(t));
    };
    leaves(phi.getType());
  } else {
    ws = {phi.getType()->isPointerTy() ? RailType{Kind::Int, 64} : railTypeOf(phi.getType())};
  }
  auto fieldsOf = [&](const Value *v) -> SmallVector<Operand, 4> {
    if (composite)
      return aggr::flattenResult(ctx, v);
    Operand o = ctx.operand(v);
    if (phi.getType()->isPointerTy() && !o.handle)   // rule 13: a code address is an i64
      o = Operand{ctx.B().CreatePtrToInt(o.v, ctx.B().getInt64Ty()), false};
    return {o};
  };
  SmallVector<Operand, 4> out;
  if (kept.empty()) {
    // No outside path reaches the block (it runs on none): a don't-care, the null value.
    for (RailType w : ws)
      out.push_back(Operand{ConstantInt::get(irTypeOf(ctx.M.getContext(), w), 0), false});
  } else if (kept.size() == 1) {
    out = fieldsOf(kept.front().second);
  } else {
    std::vector<std::vector<std::pair<Pred, Operand>>> arms(ws.size());
    for (auto &[e, v] : kept) {
      SmallVector<Operand, 4> fv = fieldsOf(v);
      for (unsigned f = 0; f < ws.size() && f < fv.size(); ++f)
        arms[f].push_back({e, fv[f]});
    }
    for (unsigned f = 0; f < ws.size(); ++f)
      out.push_back(Operand{selectChain(ctx, arms[f], ws[f]), true});
  }
  for (unsigned f = 0; f < out.size() && f < ws.size(); ++f)
    if (!out[f].handle) {
      CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, ws[f]}, {out[f].v});
      ctx.unc().recordSeed(a);
      out[f] = Operand{a, true};
    }
  if (composite)
    aggr::bindLeafFields(ctx, &phi, out, SmallVector<unsigned, 8>(out.size(), 1));
  else
    ctx.bindFields(&phi, out);
}

void Walker::joinUnitPhi(PHINode &phi, ArrayRef<InEdge> in) {
  const BasicBlock *b = phi.getParent();
  BasicBlock *join = out(b);
  // CR rules 9, 26: the unit may bind phi as several fields, joined field by field: a composite's scalar leaves; a
  // scalar is one field.
  SmallVector<Operand, 4> unitVals = ctx.fields(&phi);
  bool composite = phi.getType()->isAggregateType() || phi.getType()->isVectorTy();
  SmallVector<RailType, 4> ws;
  if (composite) {
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
        ws.push_back(t->isPointerTy() ? RailType{Kind::Int, 64} : railTypeOf(t));
    };
    leaves(phi.getType());
  } else {
    unitVals = {ctx.operand(&phi)};
    ws = {phi.getType()->isPointerTy() ? RailType{Kind::Int, 64} : railTypeOf(phi.getType())};
  }
  auto fieldsOf = [&](const Value *v) -> SmallVector<Operand, 4> {
    if (composite)
      return aggr::flattenResult(ctx, v);
    return {ctx.operand(v)};
  };
  std::vector<std::pair<BasicBlock *, SmallVector<Value *, 4>>> inc;
  for (const InEdge &e : in) {
    if (e.unit) {
      SmallVector<Value *, 4> vs;
      for (const Operand &o : unitVals)
        vs.push_back(o.v);
      inc.push_back({e.out, vs});
      continue;
    }
    // The original incomings this output edge stands for: those whose edge predicate meets its classical
    // facts (every incoming when it has none). One value is taken as it is; several are rule 9's select
    // chain where the edge leaves, each arm under the quantum part of its edge predicate (as factoredMerge),
    // which stands for it under the facts only when its classical factor is the facts themselves.
    Pred F = e.facts ? *e.facts : Pred::top();
    SmallVector<unsigned, 2> cands;
    for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
      const BasicBlock *u = phi.getIncomingBlock(i);
      if (!idx.count(u) || unitOf.count(u) || (ctx.preds().edge(u, b) & F).isBottom())
        continue;
      if (none_of(cands, [&](unsigned k) { return phi.getIncomingValue(k) == phi.getIncomingValue(i); }))
        cands.push_back(i);
    }
    IRBuilderBase::InsertPointGuard g(ctx.B());
    Instruction *t = e.out->getTerminator();
    if (!t)
      internalError("spine: the output block of an incoming edge has no terminator yet", &phi);
    ctx.B().SetInsertPoint(t);
    SmallVector<Operand, 4> os;
    if (cands.empty()) {
      // No original edge into b meets the facts: the output edge is never taken (its path is one the
      // classical branches exclude); any rail serves, a |0> seed.
      for (RailType w : ws)
        os.push_back(Operand{ConstantInt::get(irTypeOf(ctx.M.getContext(), w), 0), false});
    } else if (cands.size() == 1) {
      const Value *v = phi.getIncomingValue(cands.front());
      Pred p = Pred::bottom();
      for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i)
        if (phi.getIncomingValue(i) == v && idx.count(phi.getIncomingBlock(i)) && !unitOf.count(phi.getIncomingBlock(i)))
          p = p | ctx.preds().edge(phi.getIncomingBlock(i), b);
      SmallVector<Operand, 4> fv = fieldsOf(v);
      for (unsigned k = 0; k < ws.size(); ++k)
        os.push_back(reachingOperand(ctx, fv[k], ws[k], p, F));   // cq-pfpy
    } else {
      std::vector<std::vector<std::pair<Pred, Operand>>> arms(ws.size());
      for (unsigned k : cands) {
        Pred p = Pred::bottom();
        for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i)
          if (phi.getIncomingValue(i) == phi.getIncomingValue(k) && idx.count(phi.getIncomingBlock(i)) &&
              !unitOf.count(phi.getIncomingBlock(i)))
            p = p | ctx.preds().edge(phi.getIncomingBlock(i), b);
        p = p & F;
        if (!(F & !p.classicalFactor(ctx.T, ctx.S)).isBottom())
          unimplemented("spine: a unit-bound phi whose output edge stands for several original edges that the edge's "
                        "classical facts do not tell apart (cq-mtt)",
                        &phi);
        SmallVector<Operand, 4> fv = fieldsOf(phi.getIncomingValue(k));
        for (unsigned f = 0; f < ws.size(); ++f)
          arms[f].push_back({p.quantumPart(ctx.T, ctx.S), fv[f]});
      }
      for (unsigned f = 0; f < ws.size(); ++f)
        os.push_back(Operand{selectChain(ctx, arms[f], ws[f], F), true});
    }
    SmallVector<Value *, 4> vs;
    for (unsigned f = 0; f < ws.size(); ++f) {
      Operand o = os[f];
      if (!o.handle) {
        CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, ws[f]}, {o.v});
        ctx.unc().recordSeed(a);
        o = Operand{a, true};
      }
      vs.push_back(o.v);
    }
    inc.push_back({e.out, vs});
  }
  SmallVector<Operand, 4> merged;
  for (unsigned f = 0; f < ws.size(); ++f) {
    PHINode *np = PHINode::Create(unitVals[f].v->getType(), unsigned(inc.size()), phi.getName());
    np->insertInto(join, join->getFirstNonPHIIt());
    for (auto &[from, vs] : inc)
      np->addIncoming(vs[f], from);
    ctx.unc().recordMerge(np);
    merged.push_back(Operand{np, true});
  }
  ctx.rebind(&phi, merged);
}

void Walker::lowerUnit(Loop &lp) {
  loops::Case c = loops::classify(lp, ctx.T, ctx.S);
  spine::pushLoopUnit(ctx, lp);   // cq-8un4: loopUnit() while the loop module runs
  if (c == loops::Case::QuantumExit) {
    if (!se) {
      tlii = std::make_unique<TargetLibraryInfoImpl>(Triple(F.getParent()->getTargetTriple()));
      tli = std::make_unique<TargetLibraryInfo>(*tlii, &F);
      ac = std::make_unique<AssumptionCache>(F);
      se = std::make_unique<ScalarEvolution>(F, *tli, *ac, DT, LI);
    }
    loops::lowerCutoff(ctx, lp, ctx.K(&lp), loops::exits::cutoffBound(lp, *se, ctx.T, ctx.S));
  } else {
    loops::lowerClassical(ctx, lp, c);
  }
  spine::popLoopUnit(ctx, lp);
  for (BasicBlock *b : lp.blocks())
    for (Instruction &I : *b)
      visited.insert(&I);
  for (auto *list : {&units.find(&lp)->second.arm, &units.find(&lp)->second.dead})
    for (BasicBlock *b : *list)
      for (Instruction &I : *b)
        visited.insert(&I);
}

// The field-wise result of a clone's return (CR §1.4, rule 18), when rv is one: vals gets one value per
// leaf (the copied-out rail where quantum, the classical value otherwise), the clone's return type st
// having `extra` more fields after them (E1's flags, cq-xhv4). False when rv is returned as one value.
bool Walker::emitCloneFields(ReturnInst *ret, Value *rv, StructType *st, unsigned extra,
                             SmallVectorImpl<Value *> &vals) {
  Type *rty = rv->getType();
  bool fieldwise = false;
  unsigned nLeaves = 0;
  // Rule 26 (cq-jkq8): the fields are the union of the returns' packings, this return's value split there.
  SmallVector<unsigned, 4> pcuts = rty->isIntegerTy() && !ctx.S.table ? spine::resultIntCuts(*ctx.S.F) : SmallVector<unsigned, 4>{};
  if (pcuts.size() > 2 && st) {
    nLeaves = pcuts.size() - 1;   // cq-0umd: a packed integer result's fields
    fieldwise = true;
  } else if (rty->isAggregateType() || rty->isVectorTy()) {
    pcuts.clear();
    // The result's fields: its leaves, a packed integer leaf split (cq-0umd, 166).
    nLeaves = unsigned(spine::resultFieldTypes(*ctx.S.F).size());
    for (unsigned k = 0; k < nLeaves; ++k)
      fieldwise |= ctx.T.resultQuantum(ctx.S, k);
  } else {
    pcuts.clear();
  }
  if (!fieldwise)
    return false;
  {
    // CR §1.4: a literal struct of the result's leaves, handles where quantum; each quantum leaf is
    // copied out into a fresh rail (rule 18) like a scalar result.
    SmallVector<Operand, 4> leaves;
    leaves = pcuts.size() > 2 ? spine::packFields(ctx, rv, pcuts) : aggregateFields(ret, rv);
    auto leafTy = [&](unsigned k) -> Type * {
      if (pcuts.size() > 2)
        return IntegerType::get(ctx.M.getContext(), pcuts[k + 1] - pcuts[k]);
      return spine::resultFieldTypes(*ctx.S.F)[k];
    };
    if (!st || st->getNumElements() != leaves.size() + extra)
      internalError("spine: a clone's field-wise result type does not match its result's fields", ret);
    for (unsigned k = 0; k < leaves.size(); ++k) {
      const Operand &o = leaves[k];
      Value *v = o.v;
      bool rq = ctx.T.resultQuantum(ctx.S, k);
      if (o.handle && !rq)
        internalError("spine: a clone result field that is a rail where taint records it classical", ret);
      if (!o.handle && rq) {
        // A classical value on this path of a field taint records quantum: a seed rail holding it.
        RailType w = railTypeOf(leafTy(k));
        CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {o.v});
        ctx.unc().setRole(ctx.unc().recordSeed(f), Role::Result);
        v = f;
      } else if (o.handle) {
        RailType w = railTypeOf(leafTy(k));
        CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                   {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
        RailId fid = ctx.unc().recordSeed(f);
        abi::CoreSpec cp{abi::Core::Copy, w};
        CallInst *c = ctx.emitCore(cp, {o.v, f});
        ctx.unc().recordCore(c, cp, {o, Operand{f, true}}, fid);
        ctx.unc().setRole(fid, Role::Result);
        v = f;
      }
      if (v->getType() != st->getElementType(k))
        internalError("spine: a clone result field of another type than the clone's field", ret);
      vals.push_back(v);
    }
  }
  return true;
}

// An aggregate result's fields as the clone returns them (rule 26, cq-jkq8): each packed integer leaf at the
// union of the returns' packings (resultLeafCuts); a leaf this return packs coarser is split here, from the
// value inserted there or from its one bound field.
SmallVector<Operand, 4> Walker::aggregateFields(ReturnInst *ret, Value *rv) {
  SmallVector<Operand, 4> bound = aggr::flattenResult(ctx, rv);
  SmallVector<SmallVector<unsigned, 4>, 4> cuts = spine::resultLeafCuts(*ctx.S.F);
  SmallVector<unsigned, 4> per = aggr::leafFieldCounts(ctx, rv);
  if (per.size() != cuts.size())
    return bound;   // not a field-wise aggregate (resultLeafCuts is empty): as bound
  SmallVector<Operand, 4> out;
  unsigned at = 0;
  for (unsigned k = 0; k < per.size(); ++k) {
    ArrayRef<Operand> mine = ArrayRef<Operand>(bound).slice(at, per[k]);
    at += per[k];
    unsigned want = cuts[k].size() > 2 ? unsigned(cuts[k].size() - 1) : 1u;
    if (per[k] == want) {
      out.append(mine.begin(), mine.end());
      continue;
    }
    // The value inserted at leaf k last (a later insert of the same leaf wins).
    const Value *X = nullptr;
    for (const Value *v = rv; auto *iv = dyn_cast<InsertValueInst>(v); v = iv->getAggregateOperand())
      if (spine::resultLeafIndex(rv->getType(), iv->getIndices()) == k) {
        X = iv->getInsertedValueOperand();
        break;
      }
    unsigned W = cuts[k].back();
    SmallVector<Operand, 4> f;
    if (X && X->getType()->isIntegerTy(W))
      f = spine::packFields(ctx, X, cuts[k]);
    else if (mine.size() == 1)
      f = spine::packFieldsOf(ctx, mine.front(), W, cuts[k], ret);
    else
      internalError("spine: a returned aggregate's leaf bound at other fields than its returns' packings, with no "
                    "inserted value to split",
                    ret);
    out.append(f.begin(), f.end());
  }
  if (at != bound.size())
    internalError("spine: a returned aggregate's fields do not match its leaves", ret);
  return out;
}

void Walker::resultFields(ReturnInst *ret, Value *rv, StructType *st, unsigned extra, SmallVectorImpl<Value *> &vals) {
  if (emitCloneFields(ret, rv, st, extra, vals))
    return;
  Operand op = ctx.operand(rv);
  if (copiedOut.count(rv)) {
    if (!op.handle)
      internalError("spine: a return phi copied out per edge that is not a handle", ret);
    vals.push_back(op.v);
    return;
  }
  if (!op.handle) {
    vals.push_back(op.v);
    return;
  }
  RailType w = railTypeOf(rv->getType());
  CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
  RailId fid = ctx.unc().recordSeed(f);
  abi::CoreSpec cp{abi::Core::Copy, w};
  CallInst *c = ctx.emitCore(cp, {op.v, f});
  ctx.unc().recordCore(c, cp, {op, Operand{f, true}}, fid);
  ctx.unc().setRole(fid, Role::Result);
  vals.push_back(f);
}


void Walker::emitCloneReturn(ReturnInst *ret) {
  IRBuilder<> &B = ctx.B();
  Function *C = ctx.B().GetInsertBlock()->getParent();
  Type *CRT = C->getReturnType();
  if (fenv::cloneCarriesEnv(ctx.T, ctx.S)) {
    // E1 (CR rule 23, 82): the final flags are copied out into a fresh rail (Role::Result, as the
    // result's) and returned as the last field, after the result's (calls::materialize).
    LLVMContext &LC = ctx.M.getContext();
    auto copyOut = [&](Operand op, RailType w) {
      CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                 {Constant::getNullValue(irTypeOf(LC, w))});
      RailId fid = ctx.unc().recordSeed(f);
      abi::CoreSpec cp{abi::Core::Copy, w};
      CallInst *c = ctx.emitCore(cp, {op.v, f});
      ctx.unc().recordCore(c, cp, {op, Operand{f, true}}, fid);
      ctx.unc().setRole(fid, Role::Result);
      return f;
    };
    SmallVector<Value *, 4> vals;
    auto *st = dyn_cast<StructType>(CRT);
    Value *rv = ret->getReturnValue();
    if (rv) {
      // cq-xhv4: the result's fields (a field-wise result's leaves, or the one value) then the flags.
      resultFields(ret, rv, st, 1, vals);
      if (!st || st->getNumElements() != vals.size() + 1 || st->getElementType(0) != vals[0]->getType())
        internalError("spine: a clone carrying the environment whose result type is not {fields..., flags}", ret);
    } else if (CRT != handleTy(LC)) {
      internalError("spine: a void clone carrying the environment that does not return the flags handle", ret);
    }
    Value *flags = copyOut(Operand{fenv::cloneExitFlags(ctx, *ret), true}, RailType{Kind::Int, 32});
    Value *v = flags;
    if (rv) {
      vals.push_back(flags);
      if (vals.size() != st->getNumElements())
        internalError("spine: a clone carrying the environment whose result type is not {fields..., flags}", ret);
      v = PoisonValue::get(st);
      for (unsigned k = 0; k < vals.size(); ++k)
        v = B.CreateInsertValue(v, vals[k], {k});
    }
    ReturnInst *nr = B.CreateRet(v);
    ctx.unc().flushAtExit(nr);
    return;
  }
  ReturnInst *nr;
  ArrayRef<calls::MintSlot> mints = calls::mintSites(ctx.T, ctx.S);
  if (ctx.S.table) {
    // §1.4: a table clone pushes the registers it minted, its twin pops them.
    for (const calls::MintSlot &site : mints) {
      CallInst *p = ctx.emitCore(abi::CoreSpec{abi::Core::Push}, {calls::mintHandle(ctx, site)});
      p->setMetadata("cq.mint.push", MDNode::get(ctx.M.getContext(), {}));
    }
  } else if (Value *rv = ret->getReturnValue(); rv && !mints.empty()) {
    // Rule 19: the handle of each register after the results.
    SmallVector<Value *, 4> vals;
    auto *st = cast<StructType>(CRT);
    if (!rv->getType()->isAggregateType() && !rv->getType()->isVectorTy() && ctx.T.resultQuantum(ctx.S, 0) &&
        !ctx.operand(rv).handle) {
      // A classical value on this path of a result taint records quantum: a seed rail holding it (rule 7).
      Value *lit = ctx.operand(rv).v;
      if (lit->getType()->isPointerTy())
        lit = B.CreatePtrToInt(lit, Type::getInt64Ty(ctx.M.getContext()));
      CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(lit->getType())}, {lit});
      ctx.unc().setRole(ctx.unc().recordSeed(f), Role::Result);
      vals.push_back(f);
    } else {
      resultFields(ret, rv, st, unsigned(mints.size()), vals);
    }
    for (const calls::MintSlot &site : mints)
      vals.push_back(calls::mintHandle(ctx, site));
    if (vals.size() != st->getNumElements())
      internalError("spine: a clone's result type does not have its results and the registers it minted", ret);
    Value *agg = PoisonValue::get(CRT);
    for (unsigned k = 0; k < vals.size(); ++k)
      agg = B.CreateInsertValue(agg, vals[k], {k});
    nr = B.CreateRet(agg);
    ctx.unc().flushAtExit(nr);
    return;
  }
  if (Value *rv = ret->getReturnValue()) {
    SmallVector<Value *, 4> vals;
    if (emitCloneFields(ret, rv, dyn_cast<StructType>(CRT), 0, vals)) {
      Value *agg = PoisonValue::get(CRT);
      for (unsigned k = 0; k < vals.size(); ++k)
        agg = B.CreateInsertValue(agg, vals[k], {k});
      nr = B.CreateRet(agg);
      ctx.unc().flushAtExit(nr);
      return;
    }
    Operand op = ctx.operand(rv);
    Value *v = op.v;
    if (copiedOut.count(rv)) {
      // Copied out on each incoming edge already (returnCopyOut): v is the phi of the result rails.
      if (!op.handle || CRT != handleTy(ctx.M.getContext()))
        internalError("spine: a return phi copied out per edge that is not a handle of the clone's type", ret);
    } else if (!op.handle && CRT == handleTy(ctx.M.getContext()) && ctx.T.resultQuantum(ctx.S, 0)) {
      // A classical value on this path of a result taint records quantum: a seed rail holding it (rule 7).
      Value *lit = v;
      if (lit->getType()->isPointerTy())
        lit = B.CreatePtrToInt(lit, Type::getInt64Ty(ctx.M.getContext()));
      CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(lit->getType())}, {lit});
      ctx.unc().setRole(ctx.unc().recordSeed(f), Role::Result);
      v = f;
    } else if (op.handle && sh.ctlMeasured.count(op.v)) {
      // Rule 19, §1.4: the controlled-copy rail is returned as that rail, not copied (211).
      if (CRT != handleTy(ctx.M.getContext()))
        internalError("spine: a clone with a quantum result whose return type is not the handle type", ret);
    } else if (op.handle && spine::ruleSixImage(sh, op.v) && !calls::hasTwin(ctx.T, ctx.S)) {
      // 204: a result that is a rule-6 image cannot be uncomputed: it is returned directly (no twin reads it).
      if (CRT != handleTy(ctx.M.getContext()))
        internalError("spine: a clone with a quantum result whose return type is not the handle type", ret);
      ctx.unc().setRole(ctx.unc().idOf(op.v), Role::Result);
    } else if (op.handle) {
      if (CRT != handleTy(ctx.M.getContext()))
        internalError("spine: a clone with a quantum result whose return type is not the handle type", ret);
      RailType w = railTypeOf(rv->getType());
      CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                 {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
      RailId fid = ctx.unc().recordSeed(f);
      abi::CoreSpec cp{abi::Core::Copy, w};
      CallInst *c = ctx.emitCore(cp, {op.v, f});
      ctx.unc().recordCore(c, cp, {op, Operand{f, true}}, fid);
      ctx.unc().setRole(fid, Role::Result);
      v = f;
    } else if (v->getType() != CRT) {
      internalError("spine: a clone's classical result does not have the clone's return type", ret);
    }
    nr = B.CreateRet(v);
  } else if (!C->getReturnType()->isVoidTy()) {
    internalError("spine: a void return in a clone that returns a value", ret);
  } else {
    nr = B.CreateRetVoid();
  }
  ctx.unc().flushAtExit(nr);
}


// Rule 18 copy-out of a return phi chosen classically (cq-mjwb, 119). A clone's return value that
// is a phi of the return's own block, read by the return alone, whose every incoming edge is chosen
// classically, names on each path the arm of the edge taken. Copying out of the merged handle at the
// return would read an arm (garbage of its own branch) at a return its definition does not dominate.
// So the copy-out is made on each incoming edge, where the edge leaves: f_e = cqrt_alloc_<W>(0),
// cqrt_copy_<W>(arm_e, f_e) (an arm that is classical on that edge: f_e = cqrt_alloc_<W>(arm_e)), f_e
// kept as Role::Result; the return returns the phi of the f_e, recorded as a merge whose arms are all
// kept (U1, cq-bv91: nothing changes). The arm's garbage is then resolved in its own arm: the edge
// block flushes (flushBefore its terminator) once nothing lowered later reads a rail defined there,
// as maybeFlush does at a jump (119: the reference's per-arm alloc + copy, the base case copying the
// formal, and the arm's uncompute inside the arm). An edge leaving a block that branches elsewhere
// too gets a block of its own on that edge (as a classical guard's skip edge does), so the copy runs
// on that edge only. nullptr when the shape is not this one (an entry, other users, a merged or
// guarded join, an output edge the walk did not record, a quantum phi of the block after this one):
// the merge is lowered as any other phi.
Value *Walker::returnCopyOut(PHINode &phi) {
  BasicBlock *b = phi.getParent();
  auto *ret = dyn_cast<ReturnInst>(b->getTerminator());
  if (ctx.S.isEntry() || !ret || ret->getReturnValue() != &phi || !phi.hasOneUse() || merged.count(b) ||
      guards.count(b) || unitOf.count(b))
    return nullptr;
  if (!phi.getType()->isIntegerTy() && !phi.getType()->isFloatingPointTy())
    return nullptr;
  for (const PHINode &o : b->phis())
    if (&o != &phi && !visited.count(&o) && spine::isQ(ctx, &o))
      return nullptr;
  Function *C = ctx.B().GetInsertBlock()->getParent();
  Type *CRT = C->getReturnType();
  if (CRT != handleTy(ctx.M.getContext()))
    return nullptr;
  BasicBlock *ob = out(b);
  // One value per output edge block; every output edge into ob is one of them.
  SmallVector<std::pair<BasicBlock *, const Value *>, 4> edges;
  for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
    BasicBlock *u = phi.getIncomingBlock(i);
    if (!idx.count(u))
      continue;   // an unreachable predecessor never chooses
    if (!ctx.preds().edge(u, b).isClassical(ctx.T, ctx.S))
      return nullptr;
    auto e = edgeOut.find({u, b});
    if (e == edgeOut.end())
      return nullptr;
    const Value *v = phi.getIncomingValue(i);
    auto it = find_if(edges, [&](const auto &x) { return x.first == e->second; });
    if (it == edges.end())
      edges.push_back({e->second, v});
    else if (it->second != v)
      return nullptr;
  }
  if (edges.empty())
    return nullptr;
  for (BasicBlock *p : predecessors(ob))
    if (none_of(edges, [&](const auto &x) { return x.first == p; }))
      return nullptr;
  for (auto &[E, v] : edges) {
    Instruction *t = E->getTerminator();
    if (!t || count(successors(E), ob) != 1)
      return nullptr;
  }

  IRBuilder<> &B = ctx.B();
  RailType w = railTypeOf(phi.getType());
  PHINode *np;
  {
    IRBuilderBase::InsertPointGuard g(B);
    SmallVector<std::pair<BasicBlock *, Value *>, 4> fs;
    for (auto &[E, v] : edges) {
      BasicBlock *at = E;
      if (E->getTerminator()->getNumSuccessors() > 1) {
        // The edge's own block: the copy runs on this edge only.
        BasicBlock *n = BasicBlock::Create(ctx.M.getContext(), "", &ctx.out(), ob);
        E->getTerminator()->replaceSuccessorWith(ob, n);
        BranchInst::Create(ob, n);
        ob->replacePhiUsesWith(E, n);
        for (auto &[k, o] : edgeOut)
          if (k.second == b && o == E)
            o = n;
        for (InEdge &ie : inEdges[b])
          if (ie.out == E)
            ie.out = n;
        at = n;
      }
      Instruction *t = at->getTerminator();
      B.SetInsertPoint(t);
      sh.cur = &phi;
      Operand op = ctx.operand(v);
      CallInst *f;
      if (op.handle) {
        f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
        RailId fid = ctx.unc().recordSeed(f);
        abi::CoreSpec cp{abi::Core::Copy, w};
        CallInst *c = ctx.emitCore(cp, {op.v, f});
        ctx.unc().recordCore(c, cp, {op, Operand{f, true}}, fid);
        ctx.unc().setRole(fid, Role::Result);
      } else {
        f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {op.v});
        ctx.unc().setRole(ctx.unc().recordSeed(f), Role::Result);
      }
      fs.push_back({at, f});
      // The arm's garbage is resolved in its own arm once nothing lowered later reads it.
      if (at == E && openRegions.empty()) {
        bool later = false;
        for (auto &[orig, ops] : sh.binds) {
          auto *oi = dyn_cast<Instruction>(orig);
          if (!oi || none_of(ops, [&](const Operand &o) {
                return o.handle && isa<Instruction>(o.v) && cast<Instruction>(o.v)->getParent() == E;
              }))
            continue;
          for (const User *us : oi->users())
            if (auto *ui = dyn_cast<Instruction>(us); ui && ui != &phi && !visited.count(ui))
              later = true;
        }
        if (!later)
          ctx.unc().flushBefore(t);
      }
    }
    np = PHINode::Create(handleTy(ctx.M.getContext()), unsigned(fs.size()), phi.getName());
    np->insertInto(ob, ob->getFirstNonPHIIt());
    for (auto &[at, f] : fs)
      np->addIncoming(f, at);
  }
  ctx.unc().recordMerge(np);
  copiedOut.insert(&phi);
  sh.cur = &phi;
  return np;
}

// Rule 19 (cq-i9wk): one return of an in-place lowering returning a quantum value: whether it is frozen,
// how many registers stay allocated, the lowered return type (spine::entryReturn).
void Walker::noteEntryReturn(bool frozen, Instruction *t) {
  auto [er, fresh] = entryReturns.try_emplace(sh.orig);
  DenseMap<const Value *, unsigned> pos;
  {
    unsigned n = 0;
    for (Argument &A : sh.orig->args())
      pos[&A] = n++;
    for (Instruction &I : instructions(*sh.orig))
      pos[&I] = n++;
  }
  SmallVector<const Value *, 4> &mints = er->second.mints;
  for (Value *r : spine::liveRegisters(ctx)) {
    const Value *m = spine::registerMintSite(ctx, r);
    if (!is_contained(mints, m))
      mints.push_back(m);
  }
  llvm::sort(mints, [&](const Value *a, const Value *b) { return pos.lookup(a) < pos.lookup(b); });
  er->second.frozen = (fresh || er->second.frozen) && frozen;
  er->second.registers = unsigned(mints.size());
  er->second.ret = sh.out->getReturnType();
}

void Walker::emitTerminator(BasicBlock *b) {
  Instruction *t = b->getTerminator();
  sh.cur = t;
  visited.insert(t);
  IRBuilder<> &B = ctx.B();

  if (auto *ret = dyn_cast<ReturnInst>(t)) {
    // A return under a quantum predicate: the plugin gave every tainted function one return block
    // (unifyReturns), so this is the function's only return and the paths outside its predicate never
    // return (they abort, rule 16, or never end, rule 14 "No live exit"): it is lowered as the return.
    if (ctx.T.controlTainted(b, ctx.S) &&
        count_if(*ctx.S.F, [](const BasicBlock &x) { return isa<ReturnInst>(x.getTerminator()); }) > 1)
      internalError("spine: a return under a quantum predicate beside another return (the plugin unifies the "
                    "returns of every tainted function)",
                    t);
    if (!ctx.S.isEntry())
      return emitCloneReturn(ret);
    fenv::atEntryReturn(ctx, *ret);   // cq-hzji: the final rule 23 state is kept (Effects.h)
    ReturnInst *nr;
    if (Value *rv = ret->getReturnValue(); rv && (rv->getType()->isAggregateType() || rv->getType()->isVectorTy()) &&
                                           returnsHandle(ctx)) {
      // Rule 19 with rule 26: the literal struct of the leaves, each quantum leaf's rail escaped (a
      // classical value of a leaf another return makes quantum: a seed rail of it, rule 7).
      SmallVector<Type *, 4> types;
      SmallVector<bool, 4> q;
      entryLeaves(ctx, types, q);
      SmallVector<Operand, 4> leaves = aggr::flattenResult(ctx, rv);
      auto *st = dyn_cast<StructType>(sh.out->getReturnType());
      if (!st || leaves.size() != types.size() || st->getNumElements() != types.size())
        internalError("spine: an entry's aggregate return does not match its leaves", t);
      Value *agg = PoisonValue::get(st);
      for (unsigned k = 0; k < leaves.size(); ++k) {
        Value *v = leaves[k].v;
        if (leaves[k].handle) {
          if (!q[k])
            internalError("spine: an entry's return leaf that is a rail where taint records it classical", t);
          ctx.unc().setRole(ctx.unc().idOf(v), Role::Escaped);
        } else if (q[k]) {
          CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(types[k])}, {v});
          ctx.unc().setRole(ctx.unc().recordSeed(a), Role::Escaped);
          v = a;
        }
        if (v->getType() != st->getElementType(k))
          internalError("spine: an entry's return leaf of another type than its field", t);
        agg = B.CreateInsertValue(agg, v, {k});
      }
      // Rule 19 (cq-i9wk): frozen when every quantum leaf is a frozen rail (a seeded classical leaf is not).
      {
        bool frozen = true;
        for (unsigned k = 0; k < leaves.size(); ++k)
          if (q[k])
            frozen = frozen && leaves[k].handle && spine::frozenRail(sh, leaves[k].v);
        noteEntryReturn(frozen, t);
        entryReturns[sh.orig].leafQ.assign(q.begin(), q.end());
      }
      nr = B.CreateRet(agg);
    } else if (Value *rv = ret->getReturnValue()) {
      Operand op = ctx.operand(rv);
      Value *v = op.v;
      if (op.handle && sh.orig->getName() == "main") {
        // Rule 19: a main that returns a rail makes the effect entry exit with it as its field under an alloc_i1(true)
        // seed, then returns 0.
        tape::lowerMainExit(ctx, op, rv->getType());
        v = ConstantInt::get(sh.out->getReturnType(), 0);
      } else if (op.handle) {
        // Rule 19 (cq-i9wk): an in-module caller keeps a frozen result as its own register; any other
        // result is a clone's, cleaned by its twin.
        noteEntryReturn(spine::frozenRail(sh, op.v), t);
        // Rule 14: a value read in place whose reverse loop is deferred until after its readers (the return is the last):
        // the handle that escapes is a copy, the reverse runs before the return.
        if (ctx.unc().deferredExit(ctx.unc().idOf(op.v))) {
          RailType w = railTypeOf(rv->getType());
          CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
          RailId fid = ctx.unc().recordSeed(f);
          abi::CoreSpec cp{abi::Core::Copy, w};
          CallInst *c = ctx.emitCore(cp, {op.v, f});
          ctx.unc().recordCore(c, cp, {op, Operand{f, true}}, fid);
          op.v = f;
          v = f;
        }
        // §1.1: an entry returns an unmeasured quantum value as its handle; the rail escapes.
        ctx.unc().setRole(ctx.unc().idOf(op.v), Role::Escaped);
        Type *rt = sh.out->getReturnType();
        if (!rt->isIntegerTy())
          internalError("spine: an entry returning a handle in a non-integer return type", t);
        // Rule 19: the entry's return type is the C one of 32 bits or more, or the i32 handle (set
        // where the entry is created); a narrower one here is a return the taint did not see.
        if (rt->getIntegerBitWidth() < 32)
          internalError("spine: an entry returns a handle in a return type narrower than i32 (rule 19)", t);
        v = B.CreateZExt(op.v, rt);
      } else if (v->getType() != sh.out->getReturnType()) {
        // Rule 19: the entry's C return type cannot hold a handle, so it returns the i32 handle on every
        // path. A classical value returned on this one is a seed rail of its value (rule 7: alloc_<W>(v),
        // a known basis state), escaped like any returned rail; the caller reads it as the handle it
        // reads on the other paths.
        Type *ct = rv->getType();
        if (!ct->isIntegerTy() && !ct->isFloatingPointTy())
          internalError("spine: a classical return of a handle-returning entry that is no scalar", t);
        CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(ct)}, {v});
        noteEntryReturn(false, t);   // rule 19: a seed is no register (cq-i9wk)
        ctx.unc().setRole(ctx.unc().recordSeed(a), Role::Escaped);
        if (sh.out->getReturnType() != a->getType())
          internalError("spine: an entry returns a classical value of another type than its return type", t);
        v = a;
      }
      nr = B.CreateRet(v);
    } else {
      nr = B.CreateRetVoid();
    }
    ctx.unc().flushAtExit(nr);
    return;
  }

  if (isa<UnreachableInst>(t)) {
    auto it = outEdges.find(b);
    if (it != outEdges.end() && !it->second.empty())
      return jump(b, it->second.front());
    B.CreateUnreachable();
    return;
  }

  if (isQuantumTerm(ctx, t)) {
    if (auto *br = dyn_cast<BranchInst>(t))
      lowerBranch(ctx, *br);
    else if (auto *ib = dyn_cast<IndirectBrInst>(t))
      sh.switchSnap.erase(ib->getAddress());   // rule 13: its edges are pred's address cases; nothing to emit
    else {
      sh.switchSnap.erase(cast<SwitchInst>(t)->getCondition());   // cq-0hhk: its atoms read the rail anew
      sw::lowerSwitch(ctx, *cast<SwitchInst>(t));
    }
    BasicBlock *ip = regionEndOf(b);
    if (ip)
      openRegions.push_back(ip);
    BasicBlock *n = outEdges.lookup(b).front();
    if (!merged.count(n)) {
      B.CreateBr(out(n));
      noteIn(b, n);
    }
    return;
  }

  ArrayRef<BasicBlock *> targets = outEdges[b];
  if (auto *br = dyn_cast<BranchInst>(t)) {
    if (!br->isConditional())
      return jump(b, targets[0]);
    Operand c = ctx.operand(br->getCondition());
    if (c.handle)
      internalError("spine: a classical branch on a rail", t);
    BranchInst *nb = B.CreateCondBr(c.v, out(targets[0]), out(targets[1]));
    noteIn(b, targets[0]);
    if (targets[1] != targets[0])
      noteIn(b, targets[1]);
    for (unsigned k = 0; k < 2; ++k)
      if (targets[k] == br->getSuccessor(k))
        edgeOut[{b, br->getSuccessor(k)}] = nb->getParent();
    maybeFlush(nb);
    return;
  }
  if (auto *ib = dyn_cast<IndirectBrInst>(t)) {
    // Rule 13 (b137e75): a classical computed goto is a classical switch on its address: the compares
    // against the distinct destinations' blockaddress constants give the destination's position (the
    // last destination the complement: the default is unreachable), and a switch on it goes to their
    // lowered blocks. No indirectbr is kept.
    Operand a = ctx.operand(ib->getAddress());
    if (a.handle)
      internalError("spine: a classical computed goto on a rail", t);
    SmallVector<BasicBlock *, 4> ds = computedGotoDestinations(*ib);
    Value *pos = computedGotoPosition(B, a.v, *ib);
    SwitchInst *ns = B.CreateSwitch(pos, out(targets[ds.size() - 1]), ds.size() - 1);
    for (unsigned k = 0; k + 1 < ds.size(); ++k)
      ns->addCase(B.getInt32(k), out(targets[k]));
    SmallVector<const BasicBlock *, 4> done;
    for (BasicBlock *tg : targets)
      if (!is_contained(done, tg)) {
        done.push_back(tg);
        noteIn(b, tg);
      }
    for (unsigned k = 0; k < ds.size(); ++k)
      if (targets[k] == ds[k])
        edgeOut[{b, ds[k]}] = ns->getParent();
    maybeFlush(ns);
    return;
  }
  auto *sw = cast<SwitchInst>(t);
  Operand c = ctx.operand(sw->getCondition());
  if (c.handle)
    internalError("spine: a classical switch on a rail", t);
  // successors(b) order: default first, then the cases (SwitchInst successor order).
  SwitchInst *ns = B.CreateSwitch(c.v, out(targets[0]), sw->getNumCases());
  unsigned k = 1;
  for (auto &cs : sw->cases())
    ns->addCase(cs.getCaseValue(), out(targets[k++]));
  {
    SmallVector<const BasicBlock *, 4> done;
    for (BasicBlock *t : targets)
      if (!is_contained(done, t)) {
        done.push_back(t);
        noteIn(b, t);
      }
  }
  for (unsigned s = 0; s < sw->getNumSuccessors(); ++s)
    if (targets[s] == sw->getSuccessor(s))
      edgeOut[{b, sw->getSuccessor(s)}] = ns->getParent();
  maybeFlush(ns);
}

void Walker::emitBlock(BasicBlock *b) {
  if (merged.count(b)) {
    sh.blocks[b] = ctx.B().GetInsertBlock();
  } else {
    BasicBlock *ob = out(b);
    ctx.B().SetInsertPoint(ob);
    blockDefs.clear();
  }
  while (!openRegions.empty() && openRegions.back() == b)
    openRegions.pop_back();
  sh.curPred = ctx.preds().block(b).quantumPart(ctx.T, ctx.S);
  if (Loop *t = tailOf.lookup(b)) {
    // cq-h8y6 (rules 8, 9): a tail block on the paths that enter it from outside its unit (the unit lowered it per
    // trip for its own paths): it runs under those paths' predicate, the loop's exit flags no part of it, and its
    // values are this lowering's (each trip's binding replaced).
    (void)t;
    sh.curPred = tailPredOf(b).quantumPart(ctx.T, ctx.S);
    for (Instruction &I : *b)
      sh.binds.erase(&I);
  }

  if (unitOf.count(b)) {
    Loop &lp = *unitOf.lookup(b);
    // cq-kldr: a classical header phi entered from several blocks outside the loop with different values
    // is a classical choice at this join (rule 9: a classical select is a classical phi): a phi of the
    // output block over the walker's edges into it, completed with the other classical phis from the
    // incomings outside the loop (run()). The loop module reads it as the carried value's start.
    for (PHINode &h : b->phis()) {
      if (spine::isQ(ctx, &h))
        continue;
      const Value *v0 = nullptr;
      bool differ = false;
      for (unsigned i = 0; i < h.getNumIncomingValues(); ++i) {
        if (lp.contains(h.getIncomingBlock(i)))
          continue;
        if (v0 && v0 != h.getIncomingValue(i))
          differ = true;
        v0 = h.getIncomingValue(i);
      }
      if (!differ)
        continue;
      BasicBlock *ob = ctx.B().GetInsertBlock();
      PHINode *np = PHINode::Create(h.getType(), h.getNumIncomingValues(), h.getName(), ob->getFirstNonPHIIt());
      classicalPhis.push_back({&h, np});
      spine::bindOperand(ctx, &h, Operand{np, false});
    }
    // The header's guard comes first: the unit runs only under it (cq-uevr).
    emitGuard(b);
    const loops::exits::Unit &U = units.find(&lp)->second;
    // The unit's exit edges: the edges into its continuation from the loop or its exit arm (an exit
    // into an effect-free dead end is none: UB to take).
    SmallVector<std::pair<BasicBlock *, BasicBlock *>, 4> exits;
    {
      SmallVector<BasicBlock *, 16> from(lp.blocks().begin(), lp.blocks().end());
      for (BasicBlock *a : U.arm)
        if (!is_contained(U.tail, a))   // a tail block's edge into C is the walker's (cq-h8y6)
          from.push_back(a);
      for (BasicBlock *f : from)
        for (BasicBlock *s : successors(f))
          if (s == U.cont)
            exits.push_back({f, s});
    }
    // The exit blocks' quantum phis not yet bound: those bound once the unit returns, the loop module
    // bound (cq-lx8f). A phi bound before the unit is not the loop module's and stays an error below.
    SmallVector<const PHINode *, 4> exitPhis;
    for (auto &x : exits)
      for (PHINode &phi : x.second->phis())
        if (!sh.binds.count(&phi) && !is_contained(exitPhis, &phi))
          exitPhis.push_back(&phi);
    lowerUnit(lp);
    for (const PHINode *phi : exitPhis)
      if (sh.binds.count(phi))
        unitBoundPhis.insert(phi);
    if (!U.cont && outEdges.lookup(b).empty()) {
      // No live exit and nothing after it may run (CR rule 14 "No live exit"): the program's continuation
      // is unreachable, the shot aborts on the loop's abort flags. The lowered function still ends: its
      // rails are torn down and it returns no value (poison: no caller reads a result the C program never
      // returns).
      Type *rt = ctx.B().GetInsertBlock()->getParent()->getReturnType();
      ReturnInst *nr = rt->isVoidTy() ? ctx.B().CreateRetVoid() : ctx.B().CreateRet(PoisonValue::get(rt));
      ctx.unc().flushAtExit(nr);
      return;
    }
    BasicBlock *n = outEdges.lookup(b).front();
    // All of the unit's exit edges leave from one output block, so a phi of an exit block cannot
    // tell them apart: it would get one incoming per exit edge from the same block (cq-qjm9). It
    // stays unimplemented until the loop contract says which exit edge was taken. The count is over
    // the loop's own exit blocks, not n: a unit in a quantum arm continues at next(b, exit), which
    // need not be the block its exit edges target, and n may be merged (cq-9us4).
    for (auto &x : exits) {
      BasicBlock *to = x.second;
      // A join whose every phi the loop module bound (several live exits, Exits.h; loops-classical's
      // case-3 multi-exit form) needs no exit edge told apart.
      if (all_of(to->phis(), [&](const PHINode &phi) {
            return !any_of(phi.blocks(), [&](const BasicBlock *u) { return U.contains(lp, u); }) ||
                   unitBoundPhis.count(&phi);
          }))
        continue;
      if (count_if(exits, [&](const auto &e) { return e.second == to; }) > 1 && !to->phis().empty())
        noteUnbuilt("spine: a loop unit with more than one exit edge into an exit block with a phi the loop module did "
                    "not bind (the loop contract does not say which exit edge was taken; cq-qjm9)",
                    &*to->phis().begin());
    }
    // Every exiting block's output block is where the loop module left the builder, the block the
    // exit edges leave from (cq-qctz): a phi of an exit block the loop module did not bind (a
    // classically chosen merge of the zero-trip edge and the loop edge) finds its loop incoming
    // there through ctx.block(exiting). Set before the merged return, which also continues there.
    for (auto &x : exits)
      sh.blocks[x.first] = ctx.B().GetInsertBlock();
    if (merged.count(n))
      return;
    // The unit's exit edges all leave from where the loop module left the builder (a classical phi
    // of the exit block takes its incoming values there). The jump flushes only once no rail the loop
    // bound to an original value is still read after it.
    BasicBlock *at = ctx.B().GetInsertBlock();
    for (auto &[from, to] : exits)
      if (to == n)
        edgeOut[{from, to}] = at;
    blockDefs.clear();
    for (BasicBlock *lb : lp.blocks())
      for (Instruction &I : *lb) {
        auto bi = sh.binds.find(&I);
        if (bi != sh.binds.end() && any_of(bi->second, [](const Operand &o) { return o.handle; }))
          blockDefs.push_back(&I);
      }
    BranchInst *br = ctx.B().CreateBr(out(n));
    noteIn(b, n, &lp);
    maybeFlush(br);
    return;
  }

  for (PHINode &phi : b->phis()) {
    sh.cur = &phi;
    visited.insert(&phi);
    if (tailOf.count(b) && spine::isQ(ctx, &phi)) {
      tailMerge(phi);
      blockDefs.push_back(&phi);
      continue;
    }
    if (unitBoundPhis.count(&phi) && !spine::isQ(ctx, &phi)) {
      // cq-j5mq: a classical phi the loop module bound over its exit edges: its one value on the unit's output edge.
      Operand uv = ctx.operand(&phi);
      PHINode *np = ctx.B().CreatePHI(phi.getType(), phi.getNumIncomingValues(), phi.getName());
      classicalPhis.push_back({&phi, np});
      unitClassical[&phi] = uv.v;
      ctx.rebind(&phi, {Operand{np, false}});
      continue;
    }
    if (unitBoundPhis.count(&phi)) {
      if (auto ie = inEdges.find(b); ie != inEdges.end() && ie->second.size() > 1)
        joinUnitPhi(phi, ie->second);
      // cq-mgkr: incomings the unit could not read (lowered after the loop), selected in where their edges
      // hold (rule 9); they exclude the loop, so the unit's binding stands elsewhere.
      if (auto ja = sh.joinArms.find(&phi); ja != sh.joinArms.end()) {
        std::vector<std::pair<Pred, Operand>> arms;
        Pred E = Pred::bottom();
        for (auto &[e, v] : ja->second) {
          E = E | e;
          arms.push_back({e, ctx.operand(v)});
        }
        arms.push_back({!E, ctx.operand(&phi)});
        Value *m = selectChain(ctx, arms, railTypeOf(phi.getType()));
        sh.joinArms.erase(ja);
        ctx.rebind(&phi, {Operand{m, true}});
      }
      blockDefs.push_back(&phi);
      continue;
    }
    if (spine::isQ(ctx, &phi)) {
      // Rule 10 through rule 3 (cq-su3p): a merge of zexts of one register's states is a view of the
      // register's narrow rail, never a select over wide copies of it.
      if (spine::viewMerge(ctx, phi)) {
        blockDefs.push_back(&phi);
        continue;
      }
      // A phi whose every incoming edge predicate is classical chooses its incoming value
      // classically: pred's lowerMerge emits a classical phi over handles (rule 9 at a58c3a4).
      // Rule 10: a phi with a state prep (or a merge of one) among its incomings merges the
      // register's states; it is the register, never a select of the rotated rail (no label copy).
      if (any_of(phi.incoming_values(), [&](const Value *u) { return sh.statePreps.count(u); })) {
        sh.statePreps.insert(&phi);
        rot::lowerStatePrepMerge(ctx, phi);
        blockDefs.push_back(&phi);
        continue;
      }
      // Rules 9, 25, 26 (cq-oa67): a vector, struct or array phi merges field by field.
      if (phi.getType()->isVectorTy() || phi.getType()->isAggregateType()) {
        lowerMergeFields(ctx, phi);
        blockDefs.push_back(&phi);
        continue;
      }
      if (Value *r = returnCopyOut(phi)) {
        spine::bindOperand(ctx, &phi, Operand{r, true});
        blockDefs.push_back(&phi);
        continue;
      }
      Value *m = merged.count(b) ? nullptr : factoredMerge(phi);
      spine::bindOperand(ctx, &phi, Operand{m ? m : lowerMerge(ctx, phi), true});
      // CR rule 6: a merge of bijective updates of a dead y and y itself cleans the old y (125).
      spine::ruleSixAfter(ctx, phi);
      spine::ruleSixRetry(ctx);
      blockDefs.push_back(&phi);
      continue;
    }
    PHINode *np = ctx.B().CreatePHI(phi.getType(), phi.getNumIncomingValues(), phi.getName());
    classicalPhis.push_back({&phi, np});
    spine::bindOperand(ctx, &phi, Operand{np, false});
  }

  emitGuard(b);
  emitBody(b);
}

// Rule 8 / P1: the classical factor of b's predicate not yet established on every path here is a
// classical branch at b's start, to b's own code or to the planned skip block (cq-uevr: a loop unit's
// header too, before the unit is lowered).
void Walker::emitGuard(BasicBlock *b) {
  auto g = guards.find(b);
  if (g == guards.end())
    return;
  IRBuilder<> &B = ctx.B();
  sh.cur = &*b->getFirstNonPHIIt();
  Value *cond = nullptr;
  for (const std::vector<unsigned> &cube : g->second.first) {
    Value *cc = nullptr;
    for (unsigned k : cube) {
      const Lit &l = cands[k];
      Operand op = ctx.operand(l.v);
      if (op.handle)
        internalError("spine: a classical guard literal that is a rail", l.v);
      Value *v = l.dest ? B.CreateICmpEQ(B.CreatePtrToInt(op.v, B.getInt64Ty()), caseAddress(l.dest))
                 : l.eq ? B.CreateICmpEQ(op.v, ConstantInt::get(op.v->getType(), l.val))
                        : op.v;
      if (l.neg)
        v = B.CreateNot(v);
      cc = cc ? B.CreateAnd(cc, v) : v;
    }
    if (!cc)
      cc = B.getTrue();
    cond = cond ? B.CreateOr(cond, cc) : cc;
  }
  if (!cond)
    cond = B.getFalse();
  BasicBlock *cont = BasicBlock::Create(ctx.M.getContext(), "", &ctx.out());
  const BasicBlock *skip = g->second.second;
  // cq-174f: when the skip block has a quantum phi, the skip edge gets a block of its own, where the
  // phi's value on that edge is read (and seeded) on the skip path only.
  BasicBlock *from = B.GetInsertBlock();
  bool split = any_of(skip->phis(), [&](const PHINode &p) { return spine::isQ(ctx, &p); });
  if (split) {
    BasicBlock *e = BasicBlock::Create(ctx.M.getContext(), "", &ctx.out());
    B.CreateCondBr(cond, cont, e);
    BranchInst::Create(out(skip), e);
    from = e;
  } else {
    B.CreateCondBr(cond, cont, out(skip));
  }
  {
    auto gf = guardFacts.find(b);
    inEdges[skip].push_back({from, gf == guardFacts.end() ? std::nullopt : std::optional<Pred>(gf->second), nullptr});
  }
  B.SetInsertPoint(cont);
  blockDefs.clear();
}

// The instructions of b after its phis, then its terminator.
void Walker::emitBody(BasicBlock *b) {
  for (BasicBlock::iterator it = b->getFirstNonPHIIt(), end = b->getTerminator()->getIterator();
       it != end; ++it) {
    Instruction &I = *it;
    sh.cur = &I;
    visited.insert(&I);
    if (sh.hoisted.count(&I))
      continue;   // lowered before an in-place rotation that -O1 placed it after (cq-su3p)
    spine::dispatch(ctx, I);
    spine::ruleSixAfter(ctx, I);
    spine::ruleSixRetry(ctx);
    for (const Instruction *h : sh.hoistedDefs)
      blockDefs.push_back(h);
    sh.hoistedDefs.clear();
    if (!I.getType()->isVoidTy()) {
      auto bi = sh.binds.find(&I);
      if (bi != sh.binds.end())
        for (const Operand &o : bi->second)
          if (o.handle) {
            blockDefs.push_back(&I);
            break;
          }
    }
  }
  emitTerminator(b);
}

void Walker::run() {
  plan();
  // The first block of L is the entry; its output block must be the output function's first.
  for (BasicBlock *b : L) {
    if (unitOf.count(b) && unitOf.lookup(b)->getHeader() != b)
      continue;
    emitBlock(b);
  }
  // A classical phi takes, on each output edge into its block, the value of the original edge that
  // edge stands for: a real classical edge (edgeOut) its own incoming; an edge the linearization
  // redirected (a classical branch joining with a quantum arm still to run, cq-mtt, cq-bq0) or a classical
  // guard's skip edge (rule 8) the incoming of the original edges its classical facts admit (they all
  // carry one value: the facts are the classical branches taken, which choose the original edge).
  for (auto &[op, np] : classicalPhis) {
    const BasicBlock *blk = op->getParent();
    // A unit header's start phi (cq-kldr) takes only the incomings from outside its loop.
    const Loop *unitLoop = unitOf.count(blk) ? unitOf.lookup(blk) : nullptr;
    auto inUnit = [&](const BasicBlock *u) { return unitLoop && unitLoop->contains(u); };
    for (unsigned i = 0; i < op->getNumIncomingValues(); ++i) {
      BasicBlock *u = op->getIncomingBlock(i);
      if (inUnit(u))
        continue;
      auto e = edgeOut.find({u, blk});
      if (e == edgeOut.end())
        continue;
      if (auto uc = unitClassical.find(op); uc != unitClassical.end() && unitOf.count(u)) {
        if (np->getBasicBlockIndex(e->second) < 0)
          np->addIncoming(uc->second, e->second);
        continue;
      }
      sh.cur = u->getTerminator();
      Operand v = ctx.operand(op->getIncomingValue(i));
      if (v.handle)
        internalError("spine: a classical phi with a rail incoming", op);
      np->addIncoming(v.v, e->second);
    }
    BasicBlock *ob = np->getParent();
    SmallVector<BasicBlock *, 4> preds(predecessors(ob));
    for (BasicBlock *P : preds) {
      if (np->getBasicBlockIndex(P) >= 0)
        continue;
      const InEdge *ie = nullptr;
      if (auto ies = inEdges.find(blk); ies != inEdges.end())
        for (const InEdge &x : ies->second)
          if (x.out == P)
            ie = &x;
      const Value *v = nullptr;
      const BasicBlock *vu = nullptr;
      for (unsigned i = 0; i < op->getNumIncomingValues(); ++i) {
        const BasicBlock *u = op->getIncomingBlock(i);
        if (!idx.count(u) || inUnit(u) || (ie && ie->facts && (ctx.preds().edge(u, blk) & *ie->facts).isBottom()))
          continue;
        if (v && v != op->getIncomingValue(i))
          unimplemented("spine: a classical phi whose output edge the linearization made stands for several "
                        "original edges with different incomings (cq-mtt, cq-bq0)",
                        op);
        v = op->getIncomingValue(i);
        vu = u;
      }
      Value *nv;
      if (!v) {
        // An output edge whose classical facts admit no original edge into blk: under those facts the C
        // program never reaches blk (a linearized region whose quantum arms all left it, e.g. by an
        // early return under a _ctl clone's entry predicate), so the block's quantum predicate is false
        // there and every effect in it is guarded off. The phi is a don't-care on that edge: the null
        // value, as reachingOperand's don't-care (cq-366o).
        if (!ie || !ie->facts || !(ctx.preds().block(blk) & *ie->facts).isBottom())
          internalError("spine: a classical phi's output edge admits no original edge", op);
        nv = Constant::getNullValue(np->getType());
      } else {
        sh.cur = vu->getTerminator();
        Operand o = ctx.operand(v);
        if (o.handle)
          internalError("spine: a classical phi with a rail incoming", op);
        nv = o.v;
      }
      for (BasicBlock *s2 : successors(P))
        if (s2 == ob)
          np->addIncoming(nv, P);
    }
  }
  sh.cur = nullptr;
}

} // namespace

void construct(Module &M, const TaintInfo &T, const Specialization &S, const loops::KOptions &KO) {
  if (!S.F)
    internalError("spine: construct of a specialization with no function");
  ArrayRef<Specialization> all = T.specializations();
  bool inList = !all.empty() && &S >= all.begin() && &S < all.end();
  // The plugin may construct callees before callers (rule 19's frozen results, cq-i9wk): the epilogue
  // runs after the last specialization constructed, whichever it is.
  bool last = (!inList || ++constructedCount[&M] == all.size());
  if (last)
    constructedCount.erase(&M);
  // Rule 27 (161): a declared specialization has no body to construct. The compiler only emits
  // declarations, and calls emits the declared clone (and its _ctl and twin declarations) at each
  // call site. The module-wide epilogue still runs when it is the last specialization.
  if (S.F->isDeclaration()) {
    if (last) {
      finishEntries(M);
      dropDeadSurface(M);
    }
    return;
  }
  Function &F = *S.F;

  LoweringContext ctx(M, T, S, KO);
  spine::Shared &sh = spine::shared(ctx);
  sh.orig = &F;
  calls::noteRun(ctx);

  Value *entryFlag = nullptr;
  SmallVector<std::pair<Argument *, SmallVector<Operand, 4>>, 2> classicalComposites;
  if (S.isEntry()) {
    // Rule 19 (193): an entry returning an unmeasured quantum value returns its handle. The return
    // type stays the C one when it is an integer of 32 bits or more (the handle as is or
    // zero-extended) and is i32 otherwise (_Bool, char, short, floating, pointer). An aggregate
    // return (rule 26) keeps its type here and is refused at the return.
    FunctionType *FT = F.getFunctionType();
    Type *retType = nullptr;
    Type *crt = FT->getReturnType();
    bool qRet = false;
    for (BasicBlock &BB : F)
      if (auto *r = dyn_cast<ReturnInst>(BB.getTerminator()))
        if (Value *v = r->getReturnValue())
          qRet |= spine::isQ(ctx, v);
    if (qRet && !crt->isAggregateType() && !crt->isVectorTy() &&
        !(crt->isIntegerTy() && crt->getIntegerBitWidth() >= 32)) {
      retType = Type::getInt32Ty(M.getContext());
      FT = FunctionType::get(retType, FT->params(), FT->isVarArg());
    } else if (qRet && (crt->isAggregateType() || crt->isVectorTy())) {
      // Rule 19 with rule 26: an aggregate or vector return is the literal struct of its leaves, the i32
      // handle where quantum, the C type where classical (CR §1.1).
      SmallVector<Type *, 4> types;
      SmallVector<bool, 4> q;
      entryLeaves(ctx, types, q);
      for (unsigned k = 0; k < types.size(); ++k)
        if (q[k])
          types[k] = Type::getInt32Ty(M.getContext());
      retType = StructType::get(M.getContext(), types);
      FT = FunctionType::get(retType, FT->params(), FT->isVarArg());
    }
    Function *NF = Function::Create(FT, GlobalValue::InternalLinkage, F.getName() + ".cq.entry", &M);
    sh.out = NF;
    for (unsigned i = 0; i < F.arg_size(); ++i) {
      if (spine::isQ(ctx, F.getArg(i)))   // an entry's mask is all classical; a formal's taint is its digit
        internalError("spine: an entry function with a quantum formal", F.getArg(i));
      spine::bindOperand(ctx, F.getArg(i), Operand{NF->getArg(i), false});
    }
    pendingEntries[&M].push_back({&F, NF, retType});
  } else {
    Function *C = calls::materialize(M, S);
    sh.out = C;
    unsigned off = S.ctl ? 1 : 0;
    if (S.ctl) {
      entryFlag = C->getArg(0);
      // The caller's control flag: a rail the clone reads (a flag composed from it, 124), never freed here.
      ctx.unc().recordExternal(entryFlag, Role::UserRegister);
    }
    // CR §1.4 (calls::materialize's ABI): one parameter per scalar leaf of each formal, a handle where
    // taint's field mask is quantum; a composite formal is bound field-wise (rules 25, 26).
    unsigned p = off;
    for (unsigned i = 0; i < F.arg_size(); ++i) {
      Argument *A = F.getArg(i);
      SmallVector<bool, 4> fm = T.fieldMask(A, S);
      bool composite = A->getType()->isStructTy() || A->getType()->isArrayTy() || A->getType()->isVectorTy();
      // cq-0umd (rule 26): an integer formal the callee unpacks is the coerced struct's fields, one
      // parameter each, a handle where the mask's digit is 1.
      if (SmallVector<unsigned, 4> cuts = A->getType()->isIntegerTy() && !S.table ? spine::unpackCuts(A)
                                                                                   : SmallVector<unsigned, 4>{};
          cuts.size() > 2) {
        size_t d = 0;
        for (unsigned j = 0; j < i; ++j) {
          Argument *Aj = F.getArg(j);
          SmallVector<unsigned, 4> cj = Aj->getType()->isIntegerTy() ? spine::unpackCuts(Aj) : SmallVector<unsigned, 4>{};   // !S.table here
          d += cj.size() > 2 ? cj.size() - 1 : T.fieldMask(Aj, S).size();
        }
        unsigned n = cuts.size() - 1;
        if (d + n > S.mask.size() || p + n > C->arg_size())
          internalError("spine: a packed formal past the clone's mask or parameters", A);
        SmallVector<Operand, 4> ops;
        for (unsigned k = 0; k < n; ++k) {
          Argument *P = C->getArg(p++);
          bool q = S.mask[d + k] == '1';
          if (q)
            ctx.unc().recordExternal(P, Role::UserRegister);
          ops.push_back(Operand{P, q});
        }
        spine::bindPacked(ctx, A, cuts, ops);
        continue;
      }
      if (p + fm.size() > C->arg_size())
        internalError("spine: a clone with fewer parameters than its formals' fields", C);
      if (!composite) {
        Argument *P = C->getArg(p++);
        bool q = spine::isQ(ctx, A);
        if (q)
          ctx.unc().recordExternal(P, Role::UserRegister);   // the caller's rail: never freed here
        spine::bindOperand(ctx, A, Operand{P, q});
        continue;
      }
      SmallVector<Operand, 4> ops;
      for (bool q : fm) {
        Argument *P = C->getArg(p++);
        if (q != P->getType()->isIntegerTy(32) && q)
          internalError("spine: a quantum field parameter that is not a handle", C);
        if (q)
          ctx.unc().recordExternal(P, Role::UserRegister);
        ops.push_back(Operand{P, q});
      }
      if (any_of(ops, [](const Operand &o) { return o.handle; }))
        ctx.bindFields(A, ops);
      else
        classicalComposites.push_back({A, ops});   // rebuilt as one value in the entry block (below)
    }
    if (S.plain && F.isVarArg()) {
      // CR §1.4: the block's classical ptr, after the fixed formals (calls::lowerVarargs reads it at va_start).
      if (p >= C->arg_size())
        internalError("spine: a variadic clone with no block parameter", C);
      sh.varargs.push_back(Operand{C->getArg(p++), false});
    }
    if (fenv::cloneCarriesEnv(ctx.T, S)) {
      // E1 (CR rule 23, 82): the caller's mode and flags, the two trailing parameters.
      if (p + 2 > C->arg_size())
        internalError("spine: a clone carrying the environment without its mode and flags parameters", C);
      fenv::bindCloneEnv(ctx, C->getArg(p), C->getArg(p + 1));
      p += 2;
    }
    if (S.table) {
      // §1.4: the cutoff K, the table clone's last parameter (a classical i32).
      if (p >= C->arg_size())
        internalError("spine: a table clone with no K parameter", C);
      sh.tableK = C->getArg(p++);
    }
    if (p != C->arg_size())   // calls::materialize gives one parameter per formal field, varargs and env
      internalError("spine: a clone with more parameters than its formals' fields", C);
  }

  DominatorTree &DT = sh.dt(F);
  LoopInfo LI(DT);
  ctx.preds().compute(F, LI, T, S, entryFlag);
  ctx.B().SetInsertPoint(BasicBlock::Create(M.getContext(), "", sh.out));
  // CR §1.4: a composite formal crosses as one parameter per leaf; with no quantum leaf it is a classical
  // value of its own type, rebuilt from its leaves (struct and array fields, vector lanes, in order).
  for (auto &[A, ops] : classicalComposites) {
    unsigned k = 0;
    std::function<Value *(Type *)> build = [&](Type *Ty) -> Value * {
      if (auto *ST = dyn_cast<StructType>(Ty)) {
        Value *agg = PoisonValue::get(ST);
        for (unsigned e = 0; e < ST->getNumElements(); ++e)
          agg = ctx.B().CreateInsertValue(agg, build(ST->getElementType(e)), {e});
        return agg;
      }
      if (auto *AT = dyn_cast<ArrayType>(Ty)) {
        Value *agg = PoisonValue::get(AT);
        for (unsigned e = 0; e < AT->getNumElements(); ++e)
          agg = ctx.B().CreateInsertValue(agg, build(AT->getElementType()), {e});
        return agg;
      }
      if (auto *VT = dyn_cast<FixedVectorType>(Ty)) {
        Value *vec = PoisonValue::get(VT);
        for (unsigned e = 0; e < VT->getNumElements(); ++e)
          vec = ctx.B().CreateInsertElement(vec, build(VT->getElementType()), ctx.B().getInt32(e));
        return vec;
      }
      if (k >= ops.size() || ops[k].v->getType() != Ty)
        internalError("spine: a classical composite formal whose leaves do not match its parameters", A);
      return ops[k++].v;
    };
    Value *v = build(A->getType());
    if (k != ops.size())
      internalError("spine: a classical composite formal with parameters left over", A);
    spine::bindOperand(ctx, A, Operand{v, false});
  }
  // The walker creates blocks on demand; the entry block made here is L[0]'s.
  {
    BasicBlock *entry = &sh.out->getEntryBlock();
    sh.blocks[&F.getEntryBlock()] = entry;
  }
  Walker(ctx, F, DT, LI).run();
  llvm::erase_if(sh.ruleSixPending, [&](const spine::Shared::PendingSix &p) { return p.ctx == &ctx; });
  reachDefs(*sh.out);   // cq-pfpy: rule 9's hoisted arm values reach every point that reads them
  calls::insertActivationCounter(ctx);   // rule 14, §1.4

  // Rule 13 (b137e75): the lowered entry keeps every address-taken block under its identity: the block its
  // walk lowered it into when that block is its own (not the entry, not shared with another address-taken
  // block, holding code of its own), else a distinct block that stands for it. No indirectbr is kept (a
  // computed goto compares addresses), so such a block only has to be a distinct block that the function
  // reaches and that has code of its own: they are chained on the entry's way out, each a jump to the next,
  // placed at the end of the function in reverse order so that no jump falls through.
  if (auto pit = pendingEntries.find(&M); pit != pendingEntries.end() && !pit->second.empty() &&
                                          pit->second.back().F == &F) {
    PendingEntry &pe = pit->second.back();
    DenseMap<BasicBlock *, unsigned> uses;
    for (BasicBlock &BB : F)
      if (BB.hasAddressTaken())
        if (BasicBlock *o = sh.blocks.lookup(&BB))
          ++uses[o];
    SmallVector<BasicBlock *, 4> stand;
    for (BasicBlock &BB : F) {
      if (!BB.hasAddressTaken())
        continue;
      BasicBlock *o = sh.blocks.lookup(&BB);
      if (!o || o->getParent() != sh.out || o->isEntryBlock() || uses.lookup(o) != 1 ||
          &o->front() == o->getTerminator()) {
        o = BasicBlock::Create(M.getContext(), "", sh.out);
        stand.push_back(o);
      }
      pe.addressed.push_back({&BB, o});
    }
    if (!stand.empty()) {
      BasicBlock *entry = &sh.out->getEntryBlock();
      BasicBlock *tail = entry->splitBasicBlock(entry->getTerminator());
      entry->getTerminator()->eraseFromParent();
      BranchInst::Create(stand.front(), entry);
      for (size_t k = 0; k < stand.size(); ++k)
        BranchInst::Create(k + 1 < stand.size() ? stand[k + 1] : tail, stand[k]);
      for (size_t k = stand.size(); k-- > 0;)   // reverse order at the end: every jump is taken
        stand[k]->moveAfter(&sh.out->back());
    }
  }

  if (last) {
    finishEntries(M);
    dropDeadSurface(M);
  }
}

} // namespace cq

namespace cq::spine {

bool ruleSixImage(Shared &sh, Value *h) {
  auto it = sh.hist.find(h);
  if (it == sh.hist.end() || !it->second.tmpl)
    return false;
  return any_of(it->second.ops, [&](const Operand &o) { return o.handle && sh.ruleSixCleaned.count(o.v); });
}

bool frozenRail(Shared &sh, Value *h) {
  SmallPtrSet<Value *, 8> seen;
  std::function<bool(Value *)> frozen = [&](Value *r) {
    if (!seen.insert(r).second)
      return false;
    if (sh.rotations.count(r) || sh.frozenResults.count(r))
      return true;
    auto it = sh.hist.find(r);
    if (it == sh.hist.end() || !it->second.tmpl)
      return false;
    for (const Operand &o : it->second.ops)
      if (o.handle && sh.ruleSixCleaned.count(o.v) && frozen(o.v))
        return true;
    return false;
  };
  return frozen(h);
}

SmallVector<Value *, 4> liveRegisters(LoweringContext &ctx) {
  Shared &sh = shared(ctx);
  SmallVector<Value *, 4> regs;
  for (BasicBlock &BB : *sh.out)
    for (Instruction &I : BB) {
      if (!sh.rotations.count(&I) && !sh.frozenResults.count(&I))
        continue;
      if (sh.ruleSixCleaned.count(&I))
        continue;
      std::optional<Role> role = ctx.unc().liveRole(ctx.unc().idOf(&I));
      if (role && (*role == Role::UserRegister || *role == Role::Frozen))
        regs.push_back(&I);
    }
  return regs;
}

const Value *registerMintSite(LoweringContext &ctx, Value *rail) {
  Shared &sh = shared(ctx);
  const Value *best = nullptr;
  unsigned bestPos = ~0u, n = 0;
  DenseMap<const Value *, unsigned> pos;
  for (Argument &A : sh.orig->args())
    pos[&A] = n++;
  for (Instruction &I : instructions(*sh.orig))
    pos[&I] = n++;
  for (auto &[orig, ops] : sh.binds) {
    if (none_of(ops, [&](const Operand &o) { return o.handle && o.v == rail; }))
      continue;
    auto p = pos.find(orig);
    if (p != pos.end() && p->second < bestPos) {
      best = orig;
      bestPos = p->second;
    }
  }
  if (!best)
    internalError("spine: a live register bound to no original value of its function (rule 19 mint site)",
                  dyn_cast<Instruction>(rail));
  return best;
}







const EntryReturn *entryReturn(const Function &F) {
  auto it = entryReturns.find(&F);
  return it == entryReturns.end() ? nullptr : &it->second;
}

} // namespace cq::spine
