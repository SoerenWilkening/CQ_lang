// Module eff-invert: cq_invert regions, CR rule 17 (CQ_spec f684858; cq-4593).
//
// Rule 17: the markers are the run-time primitives cqrt_invert_begin() / cqrt_invert_end() (CR §1.3,
// BACKEND_ABI 1.13). The code between them is lowered exactly as it would be anywhere else; the backend,
// which builds the circuit as the host program runs (§0), emits the gates recorded between the two calls
// reversed, each inverted (allocations keep their place, frees move after the reversed list, a
// measurement inside flushes the gates before it forward). No _adj clone exists (§1.4).
//
// CONSTRUCTION. Each __cq_invert_begin / __cq_invert_end call becomes the call of cqrt_invert_begin /
// cqrt_invert_end at the point the walker reaches it; CQ.h's asm fence next to it (the empty asm with a
// memory clobber the macros place after begin and before end) is consumed. Since begin and end are
// events of the host execution, a region that a classical branch opens, that spans loops or blocks, that
// returns inside, or that nests needs no analysis.
//
// Uncompute placement (rule 5, placement is free; rule 17: "the compiler places no uncompute of a rail
// allocated before the region inside it"). Every rail pending at begin is held while the region is open
// (Uncompute::openInvert); at end (closeInvert) its item follows the end marker when the region used it,
// else it goes after its last use before the begin. A rail the region makes is placed by the ordinary
// rules: right after its last use, inside the region when every use is (the backend then reverses a
// compute/uncompute pair into itself); a rail the region makes and the program reads after it outlives
// the region, as rule 17 says.
//
// A MARKER UNDER A QUANTUM PREDICATE (CR rule 17, 2026-11-02, cq-asfn; CQ.h makes the markers noduplicate,
// so -O1 never copies one into the arms of a branch). A marker is a host call: it is executed on every path,
// at its position in the arm's lowered code, whose gates carry the arm flag (rule 8). A pair in one arm needs
// nothing more (the region holds the arm's controlled gates; the inverse of a controlled gate is the
// controlled inverse). When the match is outside the arm, the region's extent differs per path:
// splitMarkerPaths (before the final taint) makes the CFG say so. The host paths into a block carry a region
// DEPTH (the begins minus the ends since the function's entry); a block that paths of different depths reach,
// where a quantum terminator separates them, is cloned once per depth, each copy reached by the paths of its
// depth (a product of the CFG with the depth). In a copy of depth <= 0 an __cq_invert_end that another copy
// executes at depth > 0 is dropped with its CQ.h fence (its begin is on the other paths: the one end call is
// the other copy's). So for a begin in arm A with its end after the join, the tail T is lowered twice, under
// f with the end and under not f without it; for an end in arm A whose begin is before the branch, the tail
// after the join (to the returns) is lowered under not f inside the region and under f after it. The walker
// linearizes the arms of a quantum terminator that reach no end first (blocksReachingInvertEnd), so the other arm's
// not-f gates fall inside the bracket of an end in arm A: `begin, prefix, B|not f, T|not f, A1|f, end, A2|f,
// T|f`, and for a begin in arm A, `B|not f, T|not f, A1|f, begin, A2|f, T|f, end` (the other arm outside the
// bracket; rule 17's order up to commuting not-f gates past f gates). A function whose depths do not stay
// within kMaxDepth (a marker in a loop that does not pair within the trip) and the paths on which the
// markers do not pair are lowered as they stand: the calls are made where they fall (rule 17).
//
// References: Bennett.jl 824458d src/bennett_transform.jl:_bennett_default replays a gate list in reverse
// order, each gate by its inverse; BACKEND_ABI 1.13 cites src/circuit.jl:adjoint for the backend's half.
#include "cq/Effects.h"
#include "cq/Order.h"
#include "Split.h"

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Lowering.h"
#include "cq/Uncompute.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/SSAUpdater.h"
#include "llvm/Transforms/Utils/ValueMapper.h"

#include <map>
#include <set>

using namespace llvm;

namespace cq::invert {

namespace {

const Function *calleeOf(const Instruction *I) {
  auto *C = dyn_cast_or_null<CallBase>(I);
  return C ? C->getCalledFunction() : nullptr;
}

bool isMarker(const Instruction *I, StringRef name) {
  const Function *F = calleeOf(I);
  return F && F->getName() == name;
}

// CQ.h's barrier: an empty asm with a memory clobber and no operands.
bool isFence(const Instruction &I) {
  auto *C = dyn_cast<CallInst>(&I);
  if (!C || !C->isInlineAsm() || C->arg_size() != 0 || !C->getType()->isVoidTy())
    return false;
  auto *IA = cast<InlineAsm>(C->getCalledOperand());
  return IA->getAsmString().empty() && IA->getConstraintString().find("~{memory}") != std::string::npos;
}

} // namespace

bool isMarkerFence(const Instruction &I) {
  if (!isFence(I))
    return false;
  const Instruction *prev = I.getPrevNonDebugInstruction();
  const Instruction *next = I.getNextNonDebugInstruction();
  return isMarker(prev, "__cq_invert_begin") || isMarker(next, "__cq_invert_end");
}

void lowerMarker(LoweringContext &ctx, CallInst &marker) {
  bool begin = isMarker(&marker, "__cq_invert_begin");
  if (!begin && !isMarker(&marker, "__cq_invert_end"))
    internalError("eff-invert: lowerMarker on a call that is no cq_invert marker", &marker);
  Module &M = *ctx.B().GetInsertBlock()->getModule();
  abi::CoreSpec spec{begin ? abi::Core::InvertBegin : abi::Core::InvertEnd};
  CallInst *c = ctx.B().CreateCall(abi::declare(M, spec));
  if (begin)
    ctx.unc().openInvert(c);
  else
    ctx.unc().closeInvert(c);
}

namespace {

constexpr int kMaxDepth = 16;

int delta(const Instruction &I) {
  if (isMarker(&I, "__cq_invert_begin"))
    return 1;
  if (isMarker(&I, "__cq_invert_end"))
    return -1;
  return 0;
}

// The region depth after one instruction: an end at depth 0 closes no region of this function's paths (the
// caller's, or the program's own unpaired end) and leaves the count at 0.
int step(int d, const Instruction &I) { return std::max(0, d + delta(I)); }

int outDepth(const BasicBlock &b, int s) {
  for (const Instruction &I : b)
    s = step(s, I);
  return s;
}

bool quantumTerm(const BasicBlock &b, const TaintInfo &T) {
  const Instruction *t = b.getTerminator();
  const Value *c = nullptr;
  if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional())
    c = br->getCondition();
  else if (auto *sw = dyn_cast<SwitchInst>(t))
    c = sw->getCondition();
  else if (auto *ib = dyn_cast<IndirectBrInst>(t))
    c = ib->getAddress();
  if (!c)
    return false;
  for (const Specialization &S : T.specializations())
    if (S.F == b.getParent() && T.isQuantum(c, S))
      return true;
  return false;
}

// The depths each block is reached with; false when they exceed kMaxDepth.
bool depths(Function &F, std::map<BasicBlock *, std::set<int>> &in) {
  SmallVector<std::pair<BasicBlock *, int>, 16> work{{&F.getEntryBlock(), 0}};
  in[&F.getEntryBlock()].insert(0);
  while (!work.empty()) {
    auto [b, s] = work.pop_back_val();
    int o = outDepth(*b, s);
    if (o > kMaxDepth)
      return false;
    for (BasicBlock *v : successors(b))
      if (in[v].insert(o).second)
        work.push_back({v, o});
  }
  return true;
}

// A block of several depths whose incoming paths a quantum terminator separates: the nearest common
// dominator of its predecessors, or a block it dominates that reaches the block, ends in one.
bool quantumMixed(BasicBlock *J, const DominatorTree &DT, const TaintInfo &T) {
  BasicBlock *D = nullptr;
  for (BasicBlock *p : predecessors(J))
    if (DT.isReachableFromEntry(p))
      D = D ? DT.findNearestCommonDominator(D, p) : p;
  if (!D)
    return false;
  // The blocks D dominates from which J is reached (backwards from J, staying under D).
  SmallPtrSet<BasicBlock *, 16> seen;
  SmallVector<BasicBlock *, 16> work;
  for (BasicBlock *p : predecessors(J))
    if (DT.dominates(D, p) && seen.insert(p).second)
      work.push_back(p);
  while (!work.empty()) {
    BasicBlock *x = work.pop_back_val();
    if (quantumTerm(*x, T))
      return true;
    if (x == D)
      continue;
    for (BasicBlock *p : predecessors(x))
      if (DT.dominates(D, p) && seen.insert(p).second)
        work.push_back(p);
  }
  return false;
}

bool splitFunction(Function &F, const TaintInfo &T) {
  DominatorTree DT(F);
  std::map<BasicBlock *, std::set<int>> in;
  if (!depths(F, in))
    return false;   // markers that do not pair within a trip: lowered as they stand
  bool need = false;
  for (auto &[b, ss] : in)
    if (ss.size() > 1 && quantumMixed(b, DT, T)) {
      need = true;
      break;
    }
  if (!need)
    return false;
  // The paths' depths meet again right after an end: a block boundary there, so the copies stop at it.
  SmallVector<Instruction *, 4> ends;
  for (Instruction &I : instructions(F))
    if (delta(I) < 0 && !I.isTerminator() && !I.getNextNode()->isTerminator())
      ends.push_back(&I);
  if (!ends.empty()) {
    for (Instruction *e : ends)
      SplitBlock(e->getParent(), e->getNextNode());
    in.clear();
    if (!depths(F, in))
      internalError("eff-invert: region depths changed by splitting a block", &F.getEntryBlock().front());
  }

  // One copy per (block, depth): the smallest depth keeps the original block.
  std::map<std::pair<BasicBlock *, int>, BasicBlock *> copy;
  std::map<BasicBlock *, DenseMap<const Value *, Value *>> vmaps;   // per copy block: original instruction -> clone
  SmallVector<BasicBlock *, 16> orig;
  for (BasicBlock &b : F)
    if (in.count(&b))
      orig.push_back(&b);
  for (BasicBlock *b : orig) {
    bool first = true;
    for (int s : in[b]) {
      if (first) {
        copy[{b, s}] = b;
        first = false;
        continue;
      }
      ValueToValueMapTy local;
      BasicBlock *c = CloneBasicBlock(b, local, ".cqd" + std::to_string(s + kMaxDepth), &F);
      for (Instruction &I : *c)
        RemapInstruction(&I, local, RF_NoModuleLevelChanges | RF_IgnoreMissingLocals);
      DenseMap<const Value *, Value *> &mine = vmaps[c];
      for (Instruction &I : *b)
        mine[&I] = local.lookup(&I);
      copy[{b, s}] = c;
    }
  }
  auto cloneOf = [&](BasicBlock *cb, Instruction *I) -> Instruction * {
    if (cb == I->getParent())
      return I;
    auto it = vmaps.find(cb);
    return it == vmaps.end() ? nullptr : cast_or_null<Instruction>(it->second.lookup(I));
  };

  // Phis first, from the original incoming lists (each entry an edge), then the edges.
  for (BasicBlock *v : orig) {
    SmallVector<PHINode *, 4> phis;
    std::map<PHINode *, SmallVector<std::pair<Value *, BasicBlock *>, 4>> origInc;   // before any rewrite
    for (PHINode &P : v->phis()) {
      phis.push_back(&P);
      for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
        origInc[&P].push_back({P.getIncomingValue(i), P.getIncomingBlock(i)});
    }
    for (int s : in[v]) {
      BasicBlock *cv = copy[{v, s}];
      for (PHINode *P : phis) {
        PHINode *CP = cast<PHINode>(cloneOf(cv, P));
        SmallVector<std::pair<Value *, BasicBlock *>, 4> inc;
        for (auto &[val, p] : origInc[P]) {
          if (!in.count(p))
            continue;   // an unreachable predecessor
          for (int sp : in[p])
            if (outDepth(*p, sp) == s)
              inc.push_back({val, copy[{p, sp}]});
        }
        // Only now rewrite (CP may be P itself).
        while (CP->getNumIncomingValues())
          CP->removeIncomingValue(CP->getNumIncomingValues() - 1, /*DeletePHIIfEmpty=*/false);
        for (auto &[val, blk] : inc)
          CP->addIncoming(val, blk);
      }
    }
  }
  for (BasicBlock *b : orig) {
    SmallVector<BasicBlock *, 4> succ(successors(b));
    for (int s : in[b]) {
      Instruction *t = copy[{b, s}]->getTerminator();
      int o = outDepth(*b, s);
      for (unsigned k = 0; k < succ.size(); ++k)
        t->setSuccessor(k, copy[{succ[k], o}]);
    }
  }

  // Values defined in a block with copies, read elsewhere: the copy on the path (SSAUpdater).
  for (BasicBlock *b : orig) {
    if (in[b].size() < 2)
      continue;
    for (Instruction &I : *b) {
      if (I.getType()->isVoidTy() || I.use_empty())
        continue;
      SSAUpdater up;
      up.Initialize(I.getType(), I.getName());
      SmallPtrSet<BasicBlock *, 4> defs;
      for (int s : in[b]) {
        BasicBlock *cb = copy[{b, s}];
        up.AddAvailableValue(cb, cloneOf(cb, &I));
        defs.insert(cb);
      }
      SmallVector<Use *, 8> uses;
      for (Use &U : I.uses())
        uses.push_back(&U);
      for (Use *U : uses) {
        auto *user = cast<Instruction>(U->getUser());
        if (!isa<PHINode>(user) && defs.count(user->getParent()))
          continue;   // the copy's own (remapped clones never read I; the original block's reads follow I)
        up.RewriteUse(*U);
      }
    }
  }

  // Phis left with one incoming value (a copy reached from one predecessor, SSAUpdater's own) are that
  // value: the walker then sees the original merges (a register view stays a view, rule 10).
  for (bool changed = true; changed;) {
    changed = false;
    for (BasicBlock &bb : F)
      for (PHINode &P : make_early_inc_range(bb.phis()))
        if (Value *v = P.hasConstantValue(); v && v != &P) {
          P.replaceAllUsesWith(v);
          P.eraseFromParent();
          changed = true;
        }
  }

  // A return block with copies: the copies meet in one return (no marker follows a return; the spine
  // lowers one return under the merged value, rule 9).
  for (BasicBlock *b : orig) {
    auto *ret = dyn_cast<ReturnInst>(b->getTerminator());
    if (!ret || in[b].size() < 2)
      continue;
    BasicBlock *R = BasicBlock::Create(F.getContext(), "cqd.ret", &F);
    PHINode *P = nullptr;
    if (Value *v = ret->getReturnValue())
      P = PHINode::Create(v->getType(), in[b].size(), "", R);
    ReturnInst::Create(F.getContext(), P, R);
    for (int s : in[b]) {
      BasicBlock *cb = copy[{b, s}];
      auto *r = cast<ReturnInst>(cb->getTerminator());
      if (P)
        P->addIncoming(r->getReturnValue(), cb);
      BranchInst::Create(R, r);
      r->eraseFromParent();
    }
  }

  // An end a copy executes at depth <= 0 while another executes it at depth > 0: dropped with its fence.
  for (BasicBlock *b : orig) {
    if (in[b].size() < 2)
      continue;
    MapVector<Instruction *, std::vector<std::pair<int, Instruction *>>> ends;   // orig end -> (depth, copy), in program order
    for (int s : in[b]) {
      BasicBlock *cb = copy[{b, s}];
      int d = s;
      for (Instruction &I : *b) {
        if (isMarker(&I, "__cq_invert_end"))
          ends[&I].push_back({d, cloneOf(cb, &I)});
        d = step(d, I);
      }
    }
    for (auto &[e, cs] : ends) {
      bool paired = false;
      for (auto &[d, c] : cs)
        paired |= d > 0;
      if (!paired)
        continue;
      for (auto &[d, c] : cs)
        if (d <= 0) {
          Instruction *prev = c->getPrevNonDebugInstruction();
          if (prev && isFence(*prev))
            prev->eraseFromParent();
          c->eraseFromParent();
        }
    }
  }
  return true;
}

} // namespace

SmallVector<Function *, 4> splitMarkerPaths(Module &M, const TaintInfo &T) {
  SmallVector<Function *, 4> changed;
  Function *b = M.getFunction("__cq_invert_begin"), *e = M.getFunction("__cq_invert_end");
  if (!b && !e)
    return changed;
  SmallPtrSet<Function *, 8> withMarkers;
  for (Function *m : {b, e})
    if (m)
      for (User *u : m->users())
        if (auto *C = dyn_cast<CallBase>(u))
          withMarkers.insert(C->getFunction());
  for (Function &F : M)
    if (withMarkers.count(&F) && !F.isDeclaration() && T.isTainted(F) && splitFunction(F, T))
      changed.push_back(&F);
  return changed;
}

SmallPtrSet<const BasicBlock *, 16> blocksReachingInvertEnd(const Function &F) {
  // Backwards from every block holding an end, over every edge (a loop's body reaches its own end).
  SmallPtrSet<const BasicBlock *, 16> r;
  SmallVector<const BasicBlock *, 8> work;
  for (const BasicBlock &x : F)
    for (const Instruction &I : x)
      if (isMarker(&I, "__cq_invert_end") && r.insert(&x).second)
        work.push_back(&x);
  while (!work.empty())
    for (const BasicBlock *p : predecessors(work.pop_back_val()))
      if (r.insert(p).second)
        work.push_back(p);
  return r;
}

} // namespace cq::invert
