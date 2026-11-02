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
#include "../fatptr/FatPtrInternal.h"
#include "../eff/conc/Setjmp.h"

#include "cq/Aggregates.h"
#include "cq/Effects.h"
#include "cq/FatPtr.h"
#include "cq/Memory.h"
#include "cq/Rotation.h"
#include "cq/Switch.h"

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/AttributeMask.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/TargetParser/Triple.h"

using namespace llvm;

namespace cq {

namespace {

struct PendingEntry {
  Function *F, *NF;
  Type *retType;   // rule 19: the i32 handle replacing a C return type that cannot hold it, or null
};
thread_local std::map<const Module *, std::vector<PendingEntry>> pendingEntries;

// Move each lowered entry body into its function. The original bodies are dropped here, after the
// last construct() of the module, when nothing reads them any more.
void finishEntries(Module &M) {
  auto it = pendingEntries.find(&M);
  if (it == pendingEntries.end())
    return;
  for (PendingEntry &p : it->second) {
    Function &F = *p.F, &NF = *p.NF;
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

bool isQuantumTerm(LoweringContext &ctx, const Instruction *t) {
  if (auto *br = dyn_cast<BranchInst>(t))
    return br->isConditional() && spine::isQ(ctx, br->getCondition());
  if (auto *sw = dyn_cast<SwitchInst>(t))
    return spine::isQ(ctx, sw->getCondition());
  return false;
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
  DenseMap<const BasicBlock *, SmallVector<BasicBlock *, 2>> outEdges;
  DenseMap<const BasicBlock *, unsigned> outPreds;
  DenseSet<const BasicBlock *> merged;
  DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, BasicBlock *> edgeOut;
  std::vector<std::pair<PHINode *, PHINode *>> classicalPhis;
  DenseSet<const Instruction *> visited;
  const Instruction *regionEnd = nullptr;               // a cq_invert region spanning blocks in progress
  // cq-lx8f: quantum phis of a unit's exit blocks that the loop module bound (rule 14 case 2: an exit
  // phi identified with a carried value's final state). The walker does not merge them again.
  DenseSet<const PHINode *> unitBoundPhis;
  std::vector<const Instruction *> blockDefs;           // original quantum defs in the current output block
  // CR rule 24 (101): setjmp diamonds on a quantum test (conc::setjmpDiamond), by head; their normal arms
  // and joins, to the head.
  DenseMap<const BasicBlock *, conc::SetjmpDiamond> sjByHead;
  DenseMap<const BasicBlock *, const BasicBlock *> sjArmHead, sjJoinHead;
  void lowerSetjmpJoin(PHINode &phi, const conc::SetjmpDiamond &d);
  SmallVector<const BasicBlock *, 4> openRegions;       // ipdoms of quantum terminators not yet reached
  std::unique_ptr<TargetLibraryInfoImpl> tlii;
  std::unique_ptr<TargetLibraryInfo> tli;
  std::unique_ptr<AssumptionCache> ac;
  std::unique_ptr<ScalarEvolution> se;

  bool pureClassical(const Loop &lp);
  BasicBlock *next(const BasicBlock *x, const BasicBlock *s);
  void plan();
  void planGuards();

  struct Lit {
    const Value *v;
    bool neg;
    bool eq;
    APInt val;
    Pred p;
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
  void emitBlock(BasicBlock *b);
  void emitGuard(BasicBlock *b);
  void emitBody(BasicBlock *b, const Instruction *resume);
  void emitTerminator(BasicBlock *b);
  void emitCloneReturn(ReturnInst *ret);
  bool emitCloneFields(ReturnInst *ret, Value *rv, StructType *st, unsigned extra, SmallVectorImpl<Value *> &vals);
  void resultFields(ReturnInst *ret, Value *rv, StructType *st, unsigned extra, SmallVectorImpl<Value *> &vals);
  Value *returnCopyOut(PHINode &phi);
  DenseSet<const Value *> copiedOut;                    // return phis copied out per edge (cq-mjwb)
  void lowerUnit(Loop &lp);
  void maybeFlush(Instruction *term);
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
      if (auto *ld = dyn_cast<LoadInst>(&I))
        if (ctx.T.offsetKind(ld, ctx.S) == OffsetKind::Quantum)
          return false;
      // A write into a QRAM or slot object (cq-dxii) is recorded per dynamic store, so the loop is not
      // walked inline: it goes to rule 14's classical-bound construction (loops-classical).
      const Value *dst = nullptr;
      if (auto *st = dyn_cast<StoreInst>(&I))
        dst = st->getPointerOperand();
      else if (auto *mi = dyn_cast<MemIntrinsic>(&I))
        dst = mi->getRawDest();
      else if (auto *rmw = dyn_cast<AtomicRMWInst>(&I))
        dst = rmw->getPointerOperand();
      else if (auto *cx = dyn_cast<AtomicCmpXchgInst>(&I))
        dst = cx->getPointerOperand();
      if (dst)
        for (ObjectId o : ctx.T.provenance(dst, ctx.S))
          if (ctx.T.classOf(o) != ObjClass::Classical)
            return false;
    }
  return true;
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
    if (reach[i].test(j))
      continue;
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
  // then arm) comes first in L and its arm is linearized before the else arm (cq-746v).
  {
    std::vector<BasicBlock *> post;
    DenseSet<BasicBlock *> seen;
    std::vector<std::pair<BasicBlock *, unsigned>> stack;   // block, successors still to visit
    seen.insert(&F.getEntryBlock());
    stack.push_back({&F.getEntryBlock(), F.getEntryBlock().getTerminator()->getNumSuccessors()});
    while (!stack.empty()) {
      auto &[b, k] = stack.back();
      if (k == 0) {
        post.push_back(b);
        stack.pop_back();
        continue;
      }
      BasicBlock *s = b->getTerminator()->getSuccessor(--k);
      if (seen.insert(s).second)
        stack.push_back({s, s->getTerminator()->getNumSuccessors()});
    }
    // CR rule 24 (101): an escaping clone returns the escaped flag its longjmp arms copy out, so its
    // return blocks come after every other block (a return has no successor: still a topological order).
    if (conc::cloneEscapes(ctx.T, ctx.S))
      std::stable_partition(post.begin(), post.end(),
                            [](BasicBlock *b) { return isa<ReturnInst>(b->getTerminator()); });
    for (auto it = post.rbegin(); it != post.rend(); ++it) {
      idx[*it] = L.size();
      L.push_back(*it);
    }
  }
  // CR rule 24 (101): a setjmp diamond. Its test is quantum (taint: a longjmp under a quantum predicate
  // makes the setjmp's result quantum); nothing of the test is emitted (emitBody, lowerSetjmpJoin).
  for (BasicBlock *b : L)
    if (isQuantumTerm(ctx, b->getTerminator()))
      if (std::optional<conc::SetjmpDiamond> d = conc::setjmpDiamond(ctx, *b)) {
        sjByHead.insert({b, *d});
        sjArmHead[d->normal] = b;
        sjJoinHead[d->join] = b;
      }
  for (Loop *lp : LI.getTopLevelLoops()) {
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
      unitOf[b] = lp;
    for (BasicBlock *b : U.dead)
      unitOf[b] = lp;   // never run (UB to reach): nothing of it is lowered
    units.insert({lp, std::move(U)});
  }
  // Forward reachability (edges to a later block of L; back edges excluded).
  reach.assign(L.size(), BitVector(L.size()));
  for (unsigned i = L.size(); i-- > 0;) {
    reach[i].set(i);
    for (BasicBlock *s : successors(L[i])) {
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
      // to run comes first).
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
    if (isa<IndirectBrInst>(t) || isa<CallBrInst>(t))
      unimplemented("spine: a computed goto or asm goto in a lowered function: awaiting owner ruling: SPEC_ISSUES "
                    "label addresses (blockaddress) in a lowered or cloned function",
                    t);
    if (!isa<BranchInst>(t) && !isa<SwitchInst>(t))
      unimplemented("spine: an exception handling terminator (C compiled with -fexceptions): awaiting owner "
                    "ruling: SPEC_ISSUES unwinding (invoke, landingpad, resume) in a lowered C function",
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
      if (uncond && outPreds.lookup(b) == 1 && !classicalPhi && !pureHeaders.count(b) && !unitOf.count(b))
        merged.insert(b);
      // A unit's exit continues where the loop module leaves the builder when the unit is its only
      // way in and it comes next; otherwise (a zero-trip guard's skip edge also reaches it, 41, 177)
      // the unit ends in a jump to it (emitBlock).
      if (unitOf.count(prev) && pe != outEdges.end() && pe->second.front() == b && outPreds.lookup(b) == 1)
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
    Choice ch{e.out, {}};
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
        ops.push_back(ctx.operand(ch.arms.front().second));
        continue;
      }
      // Rule 9 on this edge alone: the merge's quantum rest, a select chain where the edge leaves.
      std::vector<std::pair<Pred, Operand>> arms;
      for (auto &[p, v] : ch.arms)
        arms.push_back({p, ctx.operand(v)});
      ops.push_back(Operand{selectChain(ctx, arms, w), true});
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
void Walker::joinUnitPhi(PHINode &phi, ArrayRef<InEdge> in) {
  const BasicBlock *b = phi.getParent();
  BasicBlock *join = out(b);
  Operand unitVal = ctx.operand(&phi);
  RailType w = railTypeOf(phi.getType());
  std::vector<std::pair<BasicBlock *, Value *>> inc;
  for (const InEdge &e : in) {
    if (e.unit) {
      inc.push_back({e.out, unitVal.v});
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
    Operand o;
    if (cands.empty()) {
      // No original edge into b meets the facts: the output edge is never taken (its path is one the
      // classical branches exclude); any rail serves, a |0> seed.
      o = Operand{ConstantInt::get(irTypeOf(ctx.M.getContext(), w), 0), false};
    } else if (cands.size() == 1) {
      o = ctx.operand(phi.getIncomingValue(cands.front()));
    } else {
      std::vector<std::pair<Pred, Operand>> arms;
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
        arms.push_back({p.quantumPart(ctx.T, ctx.S), ctx.operand(phi.getIncomingValue(k))});
      }
      o = Operand{selectChain(ctx, arms, w), true};
    }
    if (!o.handle) {
      CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {o.v});
      ctx.unc().recordSeed(a);
      o = Operand{a, true};
    }
    inc.push_back({e.out, o.v});
  }
  PHINode *np = PHINode::Create(unitVal.v->getType(), unsigned(inc.size()), phi.getName());
  np->insertInto(join, join->getFirstNonPHIIt());
  for (auto &[from, v] : inc)
    np->addIncoming(v, from);
  ctx.unc().recordMerge(np);
  ctx.rebind(&phi, {Operand{np, true}});
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
  bool fat = rty->isPointerTy() && ctx.T.resultQuantum(ctx.S, 0);   // rule 21 (85): {tag, idx}
  SmallVector<unsigned, 4> pcuts = rty->isIntegerTy() ? spine::packedCuts(rv) : SmallVector<unsigned, 4>{};
  if (fat) {
    pcuts.clear();
    nLeaves = 2;
    fieldwise = true;
  } else if (pcuts.size() > 2 && st) {
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
    if (fat) {
      auto [tag, idx] = fatptr::resultFields(ctx, *ret);
      leaves = {tag, idx};
    } else {
      leaves = pcuts.size() > 2 ? spine::packFields(ctx, rv, pcuts) : aggr::flattenResult(ctx, rv);
    }
    auto leafTy = [&](unsigned k) -> Type * {
      if (fat)
        return Type::getInt32Ty(ctx.M.getContext());
      if (pcuts.size() > 2)
        return IntegerType::get(ctx.M.getContext(), pcuts[k + 1] - pcuts[k]);
      return spine::resultFieldTypes(*ctx.S.F)[k];
    };
    if (!st || st->getNumElements() != leaves.size() + extra)
      internalError("spine: a clone's field-wise result type does not match its result's fields", ret);
    for (unsigned k = 0; k < leaves.size(); ++k) {
      const Operand &o = leaves[k];
      Value *v = o.v;
      bool rq = fat || ctx.T.resultQuantum(ctx.S, k);
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

// The result's fields as a clone returns them before its trailing extras (the flags of E1, the escaped
// flag of rule 24, the stored rails of M2): a field-wise or fat-pointer result's leaves (emitCloneFields,
// `extra` trailing fields in st), else the one value: a return phi copied out per edge as it is, a
// handle copied out into a fresh Result rail (rule 18), a classical value as it is.
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

// Rule 18 copy-out at a clone's return (cq-b0w, orchestrator decision: the spine owns it). A
// quantum result r is copied into a fresh rail f = cqrt_alloc_<W>(0); cqrt_copy_<W>(r, f), f is kept
// (Role::Result: the caller frees it after the twin) and returned; flushAtExit then uncomputes the
// body, which the copy reads, after it (06, 07, 33, 34). The copy is made even for a one-template
// body (CR allows returning that rail directly; the corpus always copies). A classical result (a
// callee that measures, or a mask under which the result does not depend on a quantum value) is
// returned as is.
void Walker::emitCloneReturn(ReturnInst *ret) {
  IRBuilder<> &B = ctx.B();
  Function *C = ctx.B().GetInsertBlock()->getParent();
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
    auto *st = dyn_cast<StructType>(C->getReturnType());
    Value *rv = ret->getReturnValue();
    if (rv) {
      // cq-xhv4: the result's fields (a field-wise result's leaves, or the one value) then the flags.
      resultFields(ret, rv, st, 1, vals);
      if (!st || st->getNumElements() != vals.size() + 1 || st->getElementType(0) != vals[0]->getType())
        internalError("spine: a clone carrying the environment whose result type is not {fields..., flags}", ret);
    } else if (C->getReturnType() != handleTy(LC)) {
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
  if (conc::cloneEscapes(ctx.T, ctx.S)) {
    // CR rule 24 (101): the result (copied out as below) then the escaped flag lowerLongjmp copied out
    // (calls::materialize: {result, escaped}, or escaped alone for a void clone).
    Value *esc = conc::cloneEscapedFlag(ctx);
    if (!esc)
      internalError("spine: an escaping clone's return reached before its longjmp (plan orders returns last)", ret);
    Value *v = esc;
    if (Value *rv = ret->getReturnValue()) {
      // The result's fields (a field-wise or fat-pointer result's leaves, or the one value) then the flag.
      auto *st = dyn_cast<StructType>(C->getReturnType());
      SmallVector<Value *, 4> vals;
      resultFields(ret, rv, st, 1, vals);
      if (!st || st->getNumElements() != vals.size() + 1)
        internalError("spine: an escaping clone whose return type is not {fields..., escaped}", ret);
      vals.push_back(esc);
      v = PoisonValue::get(st);
      for (unsigned k = 0; k < vals.size(); ++k) {
        if (vals[k]->getType() != st->getElementType(k))
          internalError("spine: an escaping clone's return field of another type than its result's", ret);
        v = B.CreateInsertValue(v, vals[k], {k});
      }
    }
    if (v->getType() != C->getReturnType())
      internalError("spine: an escaping clone's return value is not of its return type", ret);
    ReturnInst *nr = B.CreateRet(v);
    ctx.unc().flushAtExit(nr);
    return;
  }
  // M2/M2b (191): the clone's stores through triple formals onto a QRAM object are emitted after the
  // body's uncompute and their copied-out rails returned after the result (calls::cloneResultType).
  unsigned stores = 0;
  for (Argument &A : ctx.S.F->args())
    if (A.getType()->isPointerTy()) {
      PtrFormal pf = ctx.T.pointerFormal(ctx.S, A.getArgNo());
      if (pf.abi != PtrAbi::Raw && pf.pointee == ObjClass::Qram) {
        stores = mem::calleeQramStoreCount(ctx.T, ctx.S);
        break;
      }
    }
  if (stores) {
    // M2 (calls::cloneResultType): the result's leaves (handles where quantum), then one handle per store.
    SmallVector<Value *, 4> res;
    if (Value *rv = ret->getReturnValue())
      resultFields(ret, rv, dyn_cast<StructType>(C->getReturnType()), stores, res);
    ReturnInst *nr = B.CreateRet(PoisonValue::get(C->getReturnType()));
    ctx.unc().flushAtExit(nr);
    B.SetInsertPoint(nr);
    SmallVector<Value *, 2> rails = mem::emitCalleeQramStores(ctx);
    if (rails.size() != stores)
      internalError("spine: emitCalleeQramStores returned another count than calleeQramStoreCount", ret);
    Value *v;
    if (res.empty() && stores == 1) {
      v = rails[0];
    } else {
      auto *st = dyn_cast<StructType>(C->getReturnType());
      if (!st || st->getNumElements() != res.size() + stores)
        internalError("spine: a clone's result type does not match its result and QRAM stores", ret);
      v = PoisonValue::get(st);
      unsigned k = 0;
      for (Value *r : res)
        v = B.CreateInsertValue(v, r, {k++});
      for (Value *h : rails)
        v = B.CreateInsertValue(v, h, {k++});
    }
    if (v->getType() != C->getReturnType())
      internalError("spine: a clone's return value with QRAM stores is not of its return type", ret);
    nr->setOperand(0, v);
    return;
  }
  ReturnInst *nr;
  if (Value *rv = ret->getReturnValue()) {
    SmallVector<Value *, 4> vals;
    if (emitCloneFields(ret, rv, dyn_cast<StructType>(C->getReturnType()), 0, vals)) {
      Value *agg = PoisonValue::get(C->getReturnType());
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
      if (!op.handle || C->getReturnType() != handleTy(ctx.M.getContext()))
        internalError("spine: a return phi copied out per edge that is not a handle of the clone's type", ret);
    } else if (op.handle) {
      if (C->getReturnType() != handleTy(ctx.M.getContext()))
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
    } else if (v->getType() != C->getReturnType()) {
      internalError("spine: a clone's classical result does not have the clone's return type", ret);
    }
    nr = B.CreateRet(v);
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
  if (C->getReturnType() != handleTy(ctx.M.getContext()))
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

void Walker::emitTerminator(BasicBlock *b) {
  Instruction *t = b->getTerminator();
  sh.cur = t;
  visited.insert(t);
  IRBuilder<> &B = ctx.B();

  if (auto *ret = dyn_cast<ReturnInst>(t)) {
    if (ctx.T.controlTainted(b, ctx.S))
      unimplemented("spine: a return under a quantum predicate", t);
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
      nr = B.CreateRet(agg);
    } else if (Value *rv = ret->getReturnValue()) {
      Operand op = ctx.operand(rv);
      Value *v = op.v;
      if (op.handle) {
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
    else {
      sh.switchSnap.erase(cast<SwitchInst>(t)->getCondition());   // cq-0hhk: its atoms read the rail anew
      sw::lowerSwitch(ctx, *cast<SwitchInst>(t));
    }
    BasicBlock *ip = PDT.getNode(b) && PDT.getNode(b)->getIDom() ? PDT.getNode(b)->getIDom()->getBlock() : nullptr;
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
  if (regionEnd) {
    // Inside a cq_invert region spanning blocks (eff-invert lowered it): b emits nothing of its own and
    // continues in the current output block; the end's block resumes after the end marker.
    if (sh.blocks.count(b))
      internalError("spine: a block of a cq_invert region with an output block of its own", b->getTerminator());
    // A loop or a classical guard of the region is eff-invert's too (rule 17; cq-xjw2).
    sh.blocks[b] = ctx.B().GetInsertBlock();
    for (Instruction &I : *b) {
      visited.insert(&I);
      if (&I == regionEnd)
        break;
    }
    if (regionEnd->getParent() != b)
      return;
    const Instruction *resume = regionEnd;
    regionEnd = nullptr;
    while (!openRegions.empty() && openRegions.back() == b)
      openRegions.pop_back();
    sh.curPred = ctx.preds().block(b).quantumPart(ctx.T, ctx.S);
    emitBody(b, resume);
    return;
  }
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
  // Rule 24 (101): a setjmp's first-return arm always runs (an escape happens inside its call): the
  // head's predicate, not the test's.
  if (auto a = sjArmHead.find(b); a != sjArmHead.end())
    sh.curPred = ctx.preds().block(a->second).quantumPart(ctx.T, ctx.S);

  if (unitOf.count(b)) {
    // The header's guard comes first: the unit runs only under it (cq-uevr).
    emitGuard(b);
    Loop &lp = *unitOf.lookup(b);
    const loops::exits::Unit &U = units.find(&lp)->second;
    // The unit's exit edges: the edges into its continuation from the loop or its exit arm (an exit
    // into an effect-free dead end is none: UB to take).
    SmallVector<std::pair<BasicBlock *, BasicBlock *>, 4> exits;
    {
      SmallVector<BasicBlock *, 16> from(lp.blocks().begin(), lp.blocks().end());
      from.append(U.arm.begin(), U.arm.end());
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
        if (spine::isQ(ctx, &phi) && !sh.binds.count(&phi) && !is_contained(exitPhis, &phi))
          exitPhis.push_back(&phi);
    lowerUnit(lp);
    for (const PHINode *phi : exitPhis)
      if (sh.binds.count(phi))
        unitBoundPhis.insert(phi);
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
        unimplemented("spine: a loop unit with more than one exit edge into an exit block with a phi (the "
                      "loop contract does not say which exit edge was taken; cq-qjm9)",
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
    if (auto j = sjJoinHead.find(b); j != sjJoinHead.end()) {
      lowerSetjmpJoin(phi, sjByHead.find(j->second)->second);
      blockDefs.push_back(&phi);
      continue;
    }
    if (unitBoundPhis.count(&phi)) {
      if (auto ie = inEdges.find(b); ie != inEdges.end() && ie->second.size() > 1)
        joinUnitPhi(phi, ie->second);
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
      if (phi.getType()->isPointerTy()) {
        // Rule 21: a quantum pointer merge is a fat pointer (tag, idx) merged over the edge predicates,
        // fatptr's like the select's (cq-xb7r): it binds the phi's fields here.
        fatptr::lower(ctx, &phi);
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
  emitBody(b, nullptr);
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
      Value *v = l.eq ? B.CreateICmpEQ(op.v, ConstantInt::get(op.v->getType(), l.val)) : op.v;
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

// The instructions of b after its phis (after resume when set: the end marker of a cq_invert region
// begun in an earlier block), then its terminator.
void Walker::emitBody(BasicBlock *b, const Instruction *resume) {
  for (BasicBlock::iterator it = resume ? std::next(const_cast<Instruction *>(resume)->getIterator())
                                        : b->getFirstNonPHIIt(),
                            end = b->getTerminator()->getIterator();
       it != end; ++it) {
    Instruction &I = *it;
    sh.cur = &I;
    visited.insert(&I);
    if (auto d = sjByHead.find(b); d != sjByHead.end() && (&I == d->second.setjmp || &I == d->second.cmp))
      continue;   // rule 24 (101): the host setjmp is not executed; its test is the escaped flag
    if (auto *CB = dyn_cast<CallInst>(&I);
        CB && calls::classify(*CB, ctx.T, ctx.S) == calls::Class::InvertBegin) {
      // Rule 17: eff-invert owns the bracketed region, up to and including its end marker.
      auto e = std::next(it);
      for (; e != end; ++e)
        if (auto *E = dyn_cast<CallInst>(&*e);
            E && calls::classify(*E, ctx.T, ctx.S) == calls::Class::InvertEnd)
          break;
      if (e == end) {
        // The region spans blocks: its end is the first __cq_invert_end of a later block of L. The
        // blocks between are the region's interior; they emit nothing of their own (eff-invert lowers
        // them) and continue in the current output block; the end's block resumes after the end.
        CallInst *E = nullptr;
        for (unsigned j = idx.lookup(b) + 1; j < L.size() && !E; ++j)
          for (Instruction &J : *L[j])
            if (auto *C = dyn_cast<CallInst>(&J);
                C && calls::classify(*C, ctx.T, ctx.S) == calls::Class::InvertEnd) {
              E = C;
              break;
            }
        if (!E)
          internalError("spine: a __cq_invert_begin with no __cq_invert_end after it", CB);
        invert::lowerRegion(ctx, *CB, *E);
        for (auto r = it; r != b->end(); ++r)
          visited.insert(&*r);
        regionEnd = E;
        return;
      }
      invert::lowerRegion(ctx, *CB, *cast<CallInst>(&*e));
      for (auto r = it; r != std::next(e); ++r)
        visited.insert(&*r);
      it = e;
      continue;
    }
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

// CR rule 24 (101): a phi of a setjmp diamond's join is select(escaped, value on setjmp's second return,
// value from the first-return arm), escaped the flag the arm's escaping call returned.
void Walker::lowerSetjmpJoin(PHINode &phi, const conc::SetjmpDiamond &d) {
  Value *esc = conc::escapedOut(ctx, *d.call);
  if (!esc)
    internalError("spine: a setjmp join reached before its escaping call was lowered", &phi);
  if (!spine::isQ(ctx, &phi))
    unimplemented("spine: a classical phi at a setjmp join (rule 24)", &phi);
  Operand e = ctx.operand(phi.getIncomingValueForBlock(d.head));
  Operand n = ctx.operand(phi.getIncomingValueForBlock(d.normal));
  abi::TemplateSpec spec;
  spec.op = "select";
  spec.w = railTypeOf(phi.getType());
  std::string shape = std::string(e.handle ? "h" : "l") + (n.handle ? "h" : "l");
  spec.shape = shape == "hh" ? "" : shape;
  Value *m = ctx.emitTemplate(spec, {Operand{esc, true}, e, n});
  spine::bindOperand(ctx, &phi, Operand{m, true});
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
    for (unsigned i = 0; i < op->getNumIncomingValues(); ++i) {
      BasicBlock *u = op->getIncomingBlock(i);
      auto e = edgeOut.find({u, blk});
      if (e == edgeOut.end())
        continue;
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
        if (!idx.count(u) || (ie && ie->facts && (ctx.preds().edge(u, blk) & *ie->facts).isBottom()))
          continue;
        if (v && v != op->getIncomingValue(i))
          unimplemented("spine: a classical phi whose output edge the linearization made stands for several "
                        "original edges with different incomings (cq-mtt, cq-bq0)",
                        op);
        v = op->getIncomingValue(i);
        vu = u;
      }
      if (!v)
        internalError("spine: a classical phi's output edge admits no original edge", op);
      sh.cur = vu->getTerminator();
      Operand o = ctx.operand(v);
      if (o.handle)
        internalError("spine: a classical phi with a rail incoming", op);
      for (BasicBlock *s2 : successors(P))
        if (s2 == ob)
          np->addIncoming(o.v, P);
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
  bool last = !inList || &S == &all.back();
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
      if (A->getType()->isPointerTy()) {
        PtrFormal pf = T.pointerFormal(S, i);
        if (pf.abi != PtrAbi::Raw) {
          // T4/P1 (CR rule 21, §1.4): (object, tag, idx[, cell count]); the bus of a Qram pointee and a
          // quantum tag or idx are the caller's rails, never freed here.
          unsigned n = pf.abi == PtrAbi::TripleCount ? 4 : 3;
          if (p + n > C->arg_size())
            internalError("spine: a clone with fewer parameters than its triple formal's", C);
          Argument *obj = C->getArg(p), *tag = C->getArg(p + 1), *idx = C->getArg(p + 2);
          Argument *cnt = n == 4 ? C->getArg(p + 3) : nullptr;
          p += n;
          bool objH = pf.pointee == ObjClass::Qram;
          // The digits before this formal's: its tag and idx digits are the first two of its own.
          size_t d = 0;
          for (unsigned j = 0; j < i; ++j) {
            Argument *Aj = F.getArg(j);
            SmallVector<unsigned, 4> cj = Aj->getType()->isIntegerTy() ? spine::unpackCuts(Aj) : SmallVector<unsigned, 4>{};
            d += Aj->getType()->isPointerTy() ? T.pointerFormal(S, j).digits
                 : cj.size() > 2              ? cj.size() - 1
                                              : T.fieldMask(Aj, S).size();
          }
          if (d + 2 > S.mask.size())
            internalError("spine: a triple formal past the clone's mask", A);
          bool tagH = S.mask[d] == '1', idxH = S.mask[d + 1] == '1';
          if (objH)
            ctx.unc().recordExternal(obj, Role::UserRegister);
          if (tagH)
            ctx.unc().recordExternal(tag, Role::UserRegister);
          if (idxH)
            ctx.unc().recordExternal(idx, Role::UserRegister);
          fatptr::bindFormal(ctx, *A, obj, Operand{tag, tagH}, Operand{idx, idxH}, cnt);
          continue;
        }
      }
      SmallVector<bool, 4> fm = T.fieldMask(A, S);
      bool composite = A->getType()->isStructTy() || A->getType()->isArrayTy() || A->getType()->isVectorTy();
      // cq-0umd (rule 26): an integer formal the callee unpacks is the coerced struct's fields, one
      // parameter each, a handle where the mask's digit is 1.
      if (SmallVector<unsigned, 4> cuts = A->getType()->isIntegerTy() ? spine::unpackCuts(A)
                                                                       : SmallVector<unsigned, 4>{};
          cuts.size() > 2) {
        size_t d = 0;
        for (unsigned j = 0; j < i; ++j) {
          Argument *Aj = F.getArg(j);
          SmallVector<unsigned, 4> cj = Aj->getType()->isIntegerTy() ? spine::unpackCuts(Aj) : SmallVector<unsigned, 4>{};
          d += Aj->getType()->isPointerTy() ? T.pointerFormal(S, j).digits
               : cj.size() > 2              ? cj.size() - 1
                                            : T.fieldMask(Aj, S).size();
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
    if (F.isVarArg()) {
      // CR §1.4 (95, 109): the variadic actuals, one parameter each after the fixed formals' fields,
      // their digits the mask's last.
      unsigned nv = C->arg_size() - p - (fenv::cloneCarriesEnv(ctx.T, S) ? 2 : 0);
      if (nv > S.mask.size())
        internalError("spine: a variadic clone with more variadic parameters than mask digits", C);
      for (unsigned k = 0; k < nv; ++k) {
        Argument *P = C->getArg(p++);
        bool q = S.mask[S.mask.size() - nv + k] == '1';
        if (q)
          ctx.unc().recordExternal(P, Role::UserRegister);   // the caller's rail: never freed here
        sh.varargs.push_back(Operand{P, q});
      }
    }
    if (fenv::cloneCarriesEnv(ctx.T, S)) {
      // E1 (CR rule 23, 82): the caller's mode and flags, the two trailing parameters.
      if (p + 2 > C->arg_size())
        internalError("spine: a clone carrying the environment without its mode and flags parameters", C);
      fenv::bindCloneEnv(ctx, C->getArg(p), C->getArg(p + 1));
      p += 2;
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
  if (S.adj)
    invert::lowerAdjointBody(ctx, F);   // rule 17: the _adj clone's body is the adjoint of the clone's (cq-xjw2)
  else
    Walker(ctx, F, DT, LI).run();
  llvm::erase_if(sh.ruleSixPending, [&](const spine::Shared::PendingSix &p) { return p.ctx == &ctx; });
  mem::finishSlots(ctx);   // M8: register arrays' readers against their rule-6 clean-ups (114)

  if (last) {
    finishEntries(M);
    dropDeadSurface(M);
  }
}

} // namespace cq
