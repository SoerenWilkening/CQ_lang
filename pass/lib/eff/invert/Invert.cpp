// Module eff-invert (cq-w1-eff-invert, cq-w2b-invert): cq_invert regions, CR rule 17.
//
// Rule 17: the bracketed region's gate list is emitted reversed with each gate inverted: angles
// negated, compute/uncompute pairs reverse into themselves (flags are recomputed inside the adjoint),
// loop trips in reverse order, clones as _adj. The markers and the asm fences are consumed.
//
// CONSTRUCTION. A region is a single-entry single-exit piece of the original CFG: from right after
// __cq_invert_begin in block bb to right before __cq_invert_end in block eb (bb dominates eb, eb
// post-dominates bb), or, for an _adj clone (lowerAdjointBody), a whole function body up to its
// return. Its forward gate list U = g_1 ... g_n runs under the region's classical control flow; the
// adjoint is U^-1 = g_n^-1 ... g_1^-1 along the same classical path, played backwards.
//
//  1. Segments (original IR). A quantum branch is linearized: its arms, up to its immediate
//     post-dominator j, join the segment of the branch, and so does j (its phis are quantum merges,
//     pred::lowerMerge, or one rail on every arm). An unconditional edge to a block with a single
//     predecessor continues the segment. Every other edge is a classical edge between segments (a
//     classical br or switch, a classical join, a loop back edge). Inside a quantum arm a classical
//     branch, a loop or a side entry is unimplemented. The segment graph has the region's first
//     segment as root and the segment of eb as its end SE; dominance and cycles are computed on it.
//  2. Seeds. A quantum phi of the region whose incoming is a classical value from before the region
//     takes the seed rail alloc(v), minted once per value right before the region: a register the
//     region prepares from a classical value (rule 20's classical start, 126's r). Every incoming of
//     a quantum phi at a classical join must name one rail (a register rotated in place); else
//     unimplemented.
//  3. Forward lowering into the skeleton. Each segment F gets one output block S(F) (the first is the
//     current output block). Its original instructions are lowered in order with the spine's
//     lowerInstruction under their block predicates, inside one Uncompute scope; a classical phi of a
//     segment head is a phi of S(F). After the region, emitMirror(scope) yields the uncompute Z of
//     every rail the region made (reverse dependency order). The gate calls of S(F) are F's forward
//     gate list; everything else in S(F) is classical and stays there: the skeleton runs the region's
//     classical code forward, with its own control flow, and emits no gate.
//  4. Where the forward gate list cleans a rail. A rail made in segment F lives on the part of the
//     segment graph F dominates, D(F). It is cleaned (its Z calls) on every edge u -> v leaving it:
//     u in D(F) and v not in D(F) or v = F (a back edge re-making it), and at the region's end when F
//     dominates SE. Every use is dominated by the maker, so it lies in D(F) before such an edge.
//     A rail made and freed inside one segment is paired there (T with its _unc and free).
//  5. The adjoint. After S(SE) the reverse runs: RE(exit), then for each segment R(F), whose gates are
//     F's forward gates reversed and inverted, then the reverse of the classical edge F was entered
//     by, RE(u -> F), which re-makes the rails cleaned on u -> F (Z's calls reversed and inverted),
//     then R(u); R of the first segment continues where the region ends. Inverses:
//       - r = T(args) [and its T_unc(r, args), cqrt_free(r)]: T^-1 is T_unc(r, args); free(r) and
//         (T_unc; free)^-1 is r = T(args): each compute/uncompute pair reverses into itself.
//       - r = alloc_<W>(lit) ... free(r) (a seed): alloc^-1 is free(r), free^-1 is r = alloc_<W>(v),
//         v the basis value r held when freed: lit XOR every uncontrolled xorc literal on r (the
//         recorded writes are undone pairwise before the free; CR §0: free sees a known basis state).
//         A seed with no free (a register the region prepares, kept) is allocated before the reverse.
//       - an involution (not_i1, and_i1, or_i1, xor_i1, copy, xorc, controlled forms): itself.
//       - ry_<W>[_controlled](.., h, θ) and rz_i1(f, θ): the same gate at -θ (a classical fneg).
//       - ry_<W>_qangle[_controlled](.., h, A), rz_qangle[_controlled]([c,] A) (rule 15): the same gate
//         on t = cq_template_fneg_f64(A), then fneg_f64_unc(t, A) and free(t), balanced in place.
//       - a clone call: the call of the clone's _adj specialization (taint gives every call of the
//         region one), already the inverse; it stays as is. Its body is lowerAdjointBody's.
//       - anything else (a measurement, QRAM, tape, abort, a clone with results or a twin, a rail made
//         before the region uncomputed or freed inside it): unimplemented.
//     Classical values. A gate of R(F) or RE(u -> v) reads the classical value its forward instance
//     read. A value from before the region, or one of a segment that runs once and dominates SE, is
//     read directly; any other is pushed (cqrt_push, i32 words low word first, CR §1.3) at the end of
//     S(F), resp. on the forward edge block E(u -> v), and popped at the head of R(F), resp. RE. An edge
//     into a segment with several region predecessors pushes the predecessor's index last; R(v) pops
//     it and branches to the reverse of that edge: the reverse replays the forward path backwards,
//     loop trips in reverse order (BennettVM.jl's history tape, src/history/Replay.jl:unrun!).
//     Rails. Each re-making of a rail in an RE block is a definition; every use in the reverse is
//     rewritten to the definition that reaches it (SSAUpdater). The uses lie in reverse blocks of
//     D(F)'s segments, which every reverse path enters through such an edge (step 4).
//  6. Shapes left unimplemented: a quantum value of the region read after it whose rail the region
//     made (rule 17 defines no adjoint of a region with an output); a classical instruction reading a
//     rail the region made; a non-diagonal gate or an in-place write in the region on a rail that a
//     template of the region reads, at a point between that template and its uncompute (rule 5's
//     invariant; cq-ja5h); a gate reading memory (a pointer operand) in a region whose skeleton
//     writes memory (the adjoint runs every classical write first; cq-wvq3); a recorded write on a
//     seed outside the seed's segment.
//
// References: Bennett.jl 824458d src/bennett_transform.jl:_bennett_default (lines 337-381) replays the
// forward gate list in reverse order, each gate by its inverse (a self-inverse Toffoli/CNOT/NOT);
// rule 17 adds the rotations' angle negation, which Bennett.jl (classical reversible) has no
// counterpart for. BennettVM.jl 23d28e6 src/history/Replay.jl:unrun! replays a recorded forward path
// last-in-first-out, which is the reverse walk of step 5.
#include "cq/Effects.h"

#include <map>
#include <optional>
#include <vector>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Lowering.h"
#include "cq/Predicate.h"
#include "cq/Uncompute.h"

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/ConstantFold.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/SSAUpdater.h"

using namespace llvm;

namespace cq::invert {

namespace {

// CQ.h's barrier: an empty asm with a memory clobber and no operands.
bool isFence(const Instruction *I) {
  auto *C = dyn_cast_or_null<CallInst>(I);
  if (!C || !C->isInlineAsm() || C->arg_size() != 0)
    return false;
  auto *IA = cast<InlineAsm>(C->getCalledOperand());
  return IA->getAsmString().empty() && IA->getConstraintString().find("~{memory}") != std::string::npos;
}

// ------------------------------------------------------------------------------------------------
// Step 1: the region and its segments, on the original IR.

struct Seg {
  std::vector<BasicBlock *> blocks;   // linear order; blocks.back() ends the segment
  SmallVector<unsigned, 2> pred;      // edge ids into it
  BasicBlock *exitTo = nullptr;       // set: the segment's quantum arms join at exitTo, a classical join
};
struct Edge {
  unsigned from, to;
};

struct Region {
  BasicBlock *bb = nullptr, *eb = nullptr;
  Instruction *begin = nullptr;   // the begin marker; nullptr for a whole function body
  Instruction *stop = nullptr;    // the end marker, or the return of a whole function body
  std::vector<BasicBlock *> rpo;
  DenseSet<const BasicBlock *> blocks;
  DenseMap<const BasicBlock *, unsigned> segOf;
  std::vector<Seg> segs;
  std::vector<Edge> edges;
  std::map<std::pair<unsigned, unsigned>, unsigned> edgeId;
  unsigned SE = 0;
  std::vector<BitVector> dom;     // dom[a].test(b): a dominates b
  std::vector<BitVector> reach;   // reach[a].test(b): b is reached from a by one edge or more
  bool once(unsigned s) const { return !reach[s].test(s); }
  bool sameCycle(unsigned a, unsigned b) const { return reach[a].test(b) && reach[b].test(a); }

  // The original instructions of b that belong to the region, fences at its two ends excluded.
  std::pair<BasicBlock::iterator, BasicBlock::iterator> body(BasicBlock *b) const {
    BasicBlock::iterator it = b == bb && begin ? std::next(begin->getIterator()) : b->getFirstNonPHIIt();
    BasicBlock::iterator end = b == eb ? stop->getIterator() : b->getTerminator()->getIterator();
    if (b == bb && begin && it != end && isFence(&*it))
      ++it;
    if (b == eb && begin && it != end && isFence(&*std::prev(end)))
      --end;
    return {it, end};
  }
  bool contains(const Instruction *I) const {
    const BasicBlock *b = I->getParent();
    if (!blocks.count(b))
      return false;
    if (b == bb && begin && !begin->comesBefore(I))
      return false;
    if (b == eb && !I->comesBefore(stop) && I != stop)
      return false;
    return true;
  }
  // A value of the original function defined before the region (it dominates the region's start).
  bool before(const Value *v) const {
    auto *I = dyn_cast<Instruction>(v);
    if (!I)
      return true;   // a constant or an argument
    if (!blocks.count(I->getParent()))
      return true;   // bb dominates the region and no region block reaches outside it but at eb
    return I->getParent() == bb && begin && I->comesBefore(begin);
  }
};

bool quantumTerm(LoweringContext &ctx, const BasicBlock *b) {
  const Instruction *t = b->getTerminator();
  if (auto *br = dyn_cast<BranchInst>(t))
    return br->isConditional() && ctx.T.isQuantum(br->getCondition(), ctx.S);
  if (auto *sw = dyn_cast<SwitchInst>(t))
    return ctx.T.isQuantum(sw->getCondition(), ctx.S);
  return false;
}

Region analyze(LoweringContext &ctx, BasicBlock *bb, Instruction *begin, BasicBlock *eb, Instruction *stop) {
  Region R;
  R.bb = bb;
  R.eb = eb;
  R.begin = begin;
  R.stop = stop;
  Function &F = *bb->getParent();
  if (bb == eb) {
    if (begin && !begin->comesBefore(stop))
      unimplemented("eff-invert: __cq_invert_end before its __cq_invert_begin", stop);
    R.rpo = {bb};
    R.blocks.insert(bb);
    R.segs.emplace_back();
    R.segs[0].blocks = {bb};
    R.segOf[bb] = 0;
    R.dom.assign(1, BitVector(1, true));
    R.reach.assign(1, BitVector(1, false));
    return R;
  }
  DominatorTree DT(F);
  PostDominatorTree PDT(F);
  if (!DT.dominates(bb, eb) || !PDT.dominates(eb, bb))
    unimplemented("eff-invert: a cq_invert region that is not single-entry single-exit (begin's block must "
                  "dominate end's, end's must post-dominate begin's)",
                  begin ? begin : stop);
  // Blocks reachable from bb without passing through eb, and eb; reverse post-order.
  {
    DenseSet<BasicBlock *> seen{bb};
    std::vector<BasicBlock *> post;
    std::vector<std::pair<BasicBlock *, unsigned>> stack{{bb, 0}};
    while (!stack.empty()) {
      auto &[b, k] = stack.back();
      Instruction *t = b->getTerminator();
      if (b == eb || k == t->getNumSuccessors()) {
        post.push_back(b);
        stack.pop_back();
        continue;
      }
      BasicBlock *s = t->getSuccessor(k++);
      if (s == bb)
        unimplemented("eff-invert: a loop through the first block of a cq_invert region", t);
      if (seen.insert(s).second)
        stack.push_back({s, 0});
    }
    R.rpo.assign(post.rbegin(), post.rend());
    R.blocks.insert(R.rpo.begin(), R.rpo.end());
  }
  if (!R.blocks.count(eb))
    internalError("eff-invert: the end block is not reached from the begin block", stop);
  DenseMap<const BasicBlock *, unsigned> pos;
  for (unsigned i = 0; i < R.rpo.size(); ++i)
    pos[R.rpo[i]] = i;
  for (BasicBlock *b : R.rpo) {
    if (b != bb)
      for (BasicBlock *p : predecessors(b))
        if (!R.blocks.count(p) || p == eb)
          unimplemented("eff-invert: a block of a cq_invert region entered from outside it", &*b->begin());
    if (b == eb)
      continue;
    Instruction *t = b->getTerminator();
    if (!isa<BranchInst>(t) && !isa<SwitchInst>(t))
      unimplemented("eff-invert: a terminator inside a cq_invert region", t);
  }

  // Segments, from bb.
  std::vector<BasicBlock *> heads{bb};
  DenseMap<const BasicBlock *, unsigned> headSeg{{bb, 0}};
  R.segs.emplace_back();
  for (unsigned s = 0; s < R.segs.size(); ++s) {
    auto claim = [&](BasicBlock *b) {
      if (!R.segOf.insert({b, s}).second)
        unimplemented("eff-invert: a block of a cq_invert region on two linear segments (a classical edge into "
                      "a quantum arm)",
                      &*b->begin());
      R.segs[s].blocks.push_back(b);
    };
    BasicBlock *x = heads[s];
    claim(x);
    while (true) {
      if (x == eb) {
        R.SE = s;
        break;
      }
      Instruction *t = x->getTerminator();
      if (quantumTerm(ctx, x)) {
        auto *nd = PDT.getNode(x);
        BasicBlock *j = nd && nd->getIDom() ? nd->getIDom()->getBlock() : nullptr;
        if (!j || !R.blocks.count(j))
          internalError("eff-invert: a quantum branch of a cq_invert region with no join inside it", t);
        std::vector<BasicBlock *> arms, work;
        DenseSet<BasicBlock *> in;
        for (BasicBlock *a : successors(x))
          if (a != j && in.insert(a).second)
            work.push_back(a);
        while (!work.empty()) {
          BasicBlock *a = work.back();
          work.pop_back();
          arms.push_back(a);
          if (a == eb)
            internalError("eff-invert: the end block inside a quantum arm", t);
          Instruction *ta = a->getTerminator();
          if (auto *br = dyn_cast<BranchInst>(ta); (br && br->isConditional()) || isa<SwitchInst>(ta))
            if (!quantumTerm(ctx, a))
              unimplemented("eff-invert: a classical branch inside a quantum arm of a cq_invert region", ta);
          for (BasicBlock *a2 : successors(a))
            if (a2 != j && in.insert(a2).second)
              work.push_back(a2);
        }
        llvm::sort(arms, [&](BasicBlock *a, BasicBlock *b) { return pos.lookup(a) < pos.lookup(b); });
        for (BasicBlock *a : arms) {
          for (BasicBlock *p : predecessors(a))
            if (p != x && !in.count(p))
              unimplemented("eff-invert: a quantum arm of a cq_invert region entered from outside its branch",
                            &*a->begin());
          for (BasicBlock *a2 : successors(a))
            if (a2 != j && pos.lookup(a2) <= pos.lookup(a))
              unimplemented("eff-invert: a loop inside a quantum arm of a cq_invert region", a->getTerminator());
        }
        bool closed = true;
        for (BasicBlock *p : predecessors(j))
          if (p != x && !in.count(p))
            closed = false;
        for (BasicBlock *a : arms)
          claim(a);
        if (closed) {
          claim(j);
          x = j;
          continue;
        }
        // The join is also a classical join (-O1 merges them): the segment ends with an edge to it.
        R.segs[s].exitTo = j;
      }
      if (auto *br = dyn_cast<BranchInst>(t); br && !br->isConditional()) {
        BasicBlock *n = br->getSuccessor(0);
        if (n->getSinglePredecessor() == x && pos.lookup(n) > pos.lookup(x)) {
          claim(n);
          x = n;
          continue;
        }
      }
      // Classical edges: the segment ends at x (or jumps to its arms' join).
      SmallVector<BasicBlock *, 2> succs;
      if (BasicBlock *j = R.segs[s].exitTo)
        succs.push_back(j);
      else
        succs.append(succ_begin(x), succ_end(x));
      for (BasicBlock *n : succs) {
        auto h = headSeg.find(n);
        unsigned v;
        if (h == headSeg.end()) {
          v = R.segs.size();
          headSeg[n] = v;
          heads.push_back(n);
          R.segs.emplace_back();
        } else {
          v = h->second;
        }
        if (R.edgeId.emplace(std::make_pair(s, v), R.edges.size()).second)
          R.edges.push_back({s, v});
      }
      break;
    }
  }
  for (BasicBlock *b : R.rpo)
    if (!R.segOf.count(b))
      internalError("eff-invert: a block of a cq_invert region on no segment", &*b->begin());
  // Rule 8: a linearized block runs under its segment's classical facts only, so its predicate's
  // classical factor must be its segment head's (a classical conjunct of a quantum arm condition would
  // need a classical guard inside the segment; cq-pkjc's shape).
  for (const Seg &sg : R.segs) {
    const Pred &ph = ctx.preds().block(sg.blocks.front());
    if (ph.isBottom())
      continue;
    Pred hf = ph.classicalFactor(ctx.T, ctx.S);
    for (BasicBlock *b : sg.blocks) {
      const Pred &p = ctx.preds().block(b);
      if (p.isBottom())
        continue;
      Pred f = p.classicalFactor(ctx.T, ctx.S);
      if (!(f & !hf).isBottom() || !(hf & !f).isBottom())
        unimplemented("eff-invert: a quantum arm inside a cq_invert region whose block predicate has a classical "
                      "conjunct its branch does not establish (rule 8: a classical guard inside a linearized "
                      "segment)",
                      &*b->begin());
    }
  }
  if (R.segOf.lookup(eb) != R.SE || R.segs[R.SE].blocks.back() != eb || R.segs[R.SE].exitTo)
    internalError("eff-invert: the end block does not end its segment", stop);
  for (unsigned e = 0; e < R.edges.size(); ++e)
    R.segs[R.edges[e].to].pred.push_back(e);

  const unsigned n = R.segs.size();
  // Dominance over the segment graph (root: segment 0).
  R.dom.assign(n, BitVector(n, true));
  R.dom[0] = BitVector(n, false);
  R.dom[0].set(0);
  for (bool changed = true; changed;) {
    changed = false;
    for (unsigned i = 1; i < n; ++i) {
      BitVector d(n, true);
      for (unsigned e : R.segs[i].pred)
        d &= R.dom[R.edges[e].from];
      d.set(i);
      if (d != R.dom[i]) {
        R.dom[i] = d;
        changed = true;
      }
    }
  }
  // Transpose: dom[a].test(b) is "a dominates b".
  {
    std::vector<BitVector> t(n, BitVector(n, false));
    for (unsigned b = 0; b < n; ++b)
      for (unsigned a : R.dom[b].set_bits())
        t[a].set(b);
    R.dom = std::move(t);
  }
  R.reach.assign(n, BitVector(n, false));
  for (unsigned a = 0; a < n; ++a) {
    std::vector<unsigned> work;
    for (const Edge &e : R.edges)
      if (e.from == a && !R.reach[a].test(e.to)) {
        R.reach[a].set(e.to);
        work.push_back(e.to);
      }
    while (!work.empty()) {
      unsigned x = work.back();
      work.pop_back();
      for (const Edge &e : R.edges)
        if (e.from == x && !R.reach[a].test(e.to)) {
          R.reach[a].set(e.to);
          work.push_back(e.to);
        }
    }
  }
  return R;
}

// ------------------------------------------------------------------------------------------------
// Gates of the output.

enum class GK : uint8_t { TmplFwd, TmplUnc, Alloc, Free, Involution, Rotation, QAngle, Xorc, Clone };

struct Gate {
  CallInst *call;
  GK kind;
  abi::CoreSpec core{};
};

// What a call of the output is: a gate (cqrt_*, cq_template_*, a clone) or classical (nullopt).
std::optional<Gate> gateOf(Instruction *I) {
  auto *C = dyn_cast<CallInst>(I);
  if (!C)
    return std::nullopt;
  Function *f = C->getCalledFunction();
  if (!f)
    return std::nullopt;
  StringRef n = f->getName();
  if (n.starts_with("cq_template_")) {
    bool unc = false;
    if (!abi::parseTemplate(n, &unc))
      internalError("eff-invert: an unparseable template symbol " + n.str(), C);
    return Gate{C, unc ? GK::TmplUnc : GK::TmplFwd};
  }
  if (n.starts_with("cqrt_")) {
    std::optional<abi::CoreSpec> cs = abi::parseCore(n);
    if (!cs)
      internalError("eff-invert: an unparseable core symbol " + n.str(), C);
    using abi::Core;
    if (cs->unc && cs->op != Core::QramStore)
      internalError("eff-invert: an _unc core gate in a forward run", C);
    switch (cs->op) {
    case Core::Alloc:
      return Gate{C, GK::Alloc, *cs};
    case Core::Free:
      return Gate{C, GK::Free, *cs};
    case Core::Ry:
    case Core::RzI1:
      return Gate{C, GK::Rotation, *cs};
    case Core::RyQAngle:
    case Core::RzQAngle:
      return Gate{C, GK::QAngle, *cs};
    case Core::Xorc:
      return Gate{C, GK::Xorc, *cs};
    case Core::NotI1:
    case Core::AndI1:
    case Core::OrI1:
    case Core::XorI1:
    case Core::Copy:
      return Gate{C, GK::Involution, *cs};
    default:
      unimplemented("eff-invert: the adjoint of " + n.str() + " inside a cq_invert region (rule 17)", C);
    }
  }
  if (std::optional<abi::CloneSpec> cl = abi::parseClone(n)) {
    if (cl->unc)
      unimplemented("eff-invert: a clone twin inside a cq_invert region (a clone call with results)", C);
    if (!cl->adj)
      unimplemented("eff-invert: a clone call inside a cq_invert region that is not its _adj specialization "
                    "(rule 17: clones as _adj)",
                    C);
    if (!C->getType()->isVoidTy())
      unimplemented("eff-invert: an _adj clone call with results inside a cq_invert region (rule 17 defines no "
                    "adjoint of a region with an output)",
                    C);
    return Gate{C, GK::Clone};
  }
  return std::nullopt;
}

// The rail an in-place gate writes, or nullptr (a diagonal phase, a clone call).
Value *writeTarget(const Gate &g) {
  CallInst *c = g.call;
  switch (g.kind) {
  case GK::Involution:
    return c->getArgOperand(c->arg_size() - 1);
  case GK::Xorc:
    return c->getArgOperand(g.core.ctl ? 1 : 0);
  case GK::Rotation:
  case GK::QAngle:
    if (g.core.op == abi::Core::Ry || g.core.op == abi::Core::RyQAngle)
      return c->getArgOperand(c->arg_size() - 2);
    return nullptr;
  default:
    return nullptr;
  }
}
bool nonDiagonal(const Gate &g) {
  return (g.kind == GK::Rotation || g.kind == GK::QAngle) &&
         (g.core.op == abi::Core::Ry || g.core.op == abi::Core::RyQAngle);
}

// Push/pop of classical values as i32 words, low word first (CR §1.3).
Value *asInt(IRBuilder<> &B, Value *v, const Instruction *at) {
  Type *t = v->getType();
  if (t->isIntegerTy())
    return v;
  if (t->isPointerTy())
    return B.CreatePtrToInt(v, B.getInt64Ty());
  if (t->isHalfTy() || t->isBFloatTy() || t->isFloatTy() || t->isDoubleTy() || t->isX86_FP80Ty())
    return B.CreateBitCast(v, B.getIntNTy(t->getPrimitiveSizeInBits()));
  unimplemented("eff-invert: a classical value of this type on the push/pop stack", at);
}
void pushValue(IRBuilder<> &B, FunctionCallee push, Value *v, const Instruction *at) {
  Value *x = asInt(B, v, at);
  unsigned bits = x->getType()->getIntegerBitWidth();
  for (unsigned w = 0; w * 32 < bits; ++w) {
    Value *s = w ? B.CreateLShr(x, w * 32) : x;
    B.CreateCall(push, {B.CreateZExtOrTrunc(s, B.getInt32Ty())});
  }
}
Value *popValue(IRBuilder<> &B, FunctionCallee pop, Type *t, const Instruction *at) {
  Type *it = t;
  if (t->isPointerTy())
    it = B.getInt64Ty();
  else if (!t->isIntegerTy())
    it = B.getIntNTy(t->getPrimitiveSizeInBits());
  if (!it->isIntegerTy() || it->getIntegerBitWidth() == 0)
    unimplemented("eff-invert: a classical value of this type on the push/pop stack", at);
  unsigned bits = it->getIntegerBitWidth();
  unsigned words = (bits + 31) / 32;
  Value *x = nullptr;
  for (unsigned w = words; w-- > 0;) {
    Value *word = B.CreateZExtOrTrunc(B.CreateCall(pop), it);
    if (w)
      word = B.CreateShl(word, w * 32);
    x = x ? B.CreateOr(x, word) : word;
  }
  if (t->isPointerTy())
    return B.CreateIntToPtr(x, t);
  if (!t->isIntegerTy())
    return B.CreateBitCast(x, t);
  return x;
}

// ------------------------------------------------------------------------------------------------
// Steps 2 to 5.

struct Maker {
  CallInst *call;
  unsigned seg, idx;
  bool tmpl;
  int localUnc = -1, localFree = -1;
  std::vector<unsigned> z;    // indices into Z naming this rail, Z order
  bool kept = false;          // a seed with no free: allocated before the reverse
  Value *freed = nullptr;     // a seed: the basis value it holds when freed
};

void lowerRegion(LoweringContext &ctx, const Region &R) {
  IRBuilder<> &B = ctx.B();
  BasicBlock *cb = B.GetInsertBlock();
  if (!cb || B.GetInsertPoint() != cb->end())
    internalError("eff-invert: the builder is not at the end of an output block", R.begin ? R.begin : R.stop);
  Function &OF = *cb->getParent();
  Module &M = *OF.getParent();
  LLVMContext &C = M.getContext();
  Uncompute &U = ctx.unc();
  auto isQ = [&](const Value *v) { return ctx.T.isQuantum(v, ctx.S); };
  const unsigned nS = R.segs.size();

  for (BasicBlock *b : R.rpo) {
    auto [it, end] = R.body(b);
    for (; it != end; ++it)
      if (auto *CB = dyn_cast<CallBase>(&*it)) {
        calls::Class k = calls::classify(*CB, ctx.T, ctx.S);
        if (k == calls::Class::InvertBegin || k == calls::Class::InvertEnd)
          unimplemented("eff-invert: a nested cq_invert region", &*it);
      }
  }

  // Step 2: seeds of the classical incomings of quantum phis.
  DenseMap<const Value *, Value *> seedOf;
  for (BasicBlock *b : R.rpo) {
    if (b == R.bb)
      continue;
    for (PHINode &phi : b->phis()) {
      if (!isQ(&phi))
        continue;
      for (Value *v : phi.incoming_values()) {
        if (isQ(v) || seedOf.count(v))
          continue;
        if (!R.before(v))
          unimplemented("eff-invert: a classical value made inside a cq_invert region joining a quantum value",
                        &phi);
        Type *t = phi.getType();
        if (!t->isIntegerTy() && !t->isFloatingPointTy())
          unimplemented("eff-invert: a quantum phi of this type inside a cq_invert region", &phi);
        Operand o = ctx.operand(v);
        if (o.handle)
          internalError("eff-invert: a classical incoming bound to a rail", &phi);
        CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(t)}, {o.v});
        U.recordSeed(a);
        seedOf[v] = a;
      }
    }
  }

  // Step 3: forward lowering into the skeleton.
  Instruction *lastBefore = cb->empty() ? nullptr : &cb->back();
  unsigned scope = U.openScope();
  std::vector<BasicBlock *> S(nS, nullptr);
  S[0] = cb;
  BasicBlock *anchor = cb;
  auto newBlock = [&]() {
    BasicBlock *b = BasicBlock::Create(C, "", &OF, anchor->getNextNode());
    anchor = b;
    return b;
  };
  for (unsigned s = 1; s < nS; ++s)
    S[s] = newBlock();

  DenseSet<const BasicBlock *> done;
  std::vector<std::pair<PHINode *, PHINode *>> classicalPhis;
  std::vector<std::pair<PHINode *, Value *>> carried;   // quantum phis with a back-edge incoming
  auto railOfIncoming = [&](Value *v, const PHINode &phi) -> Value * {
    if (!isQ(v))
      return seedOf.lookup(v);
    Operand o = ctx.operand(v);
    if (!o.handle)
      unimplemented("eff-invert: a quantum incoming that is not a rail (a measured value) inside a cq_invert "
                    "region",
                    &phi);
    return o.v;
  };
  for (BasicBlock *b : R.rpo) {
    unsigned s = R.segOf.lookup(b);
    B.SetInsertPoint(S[s]);
    bool head = b == R.segs[s].blocks.front() && b != R.bb;
    if (b != R.bb)
      for (PHINode &phi : b->phis()) {
        if (isQ(&phi)) {
          Value *h = nullptr;
          bool same = true, later = false, intra = !head;
          for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
            BasicBlock *from = phi.getIncomingBlock(i);
            if (R.segOf.lookup(from) != s)
              intra = false;
            if (!done.count(from)) {
              later = true;
              continue;
            }
            Value *hv = railOfIncoming(phi.getIncomingValue(i), phi);
            if (!h)
              h = hv;
            else if (h != hv)
              same = false;
          }
          if (!h)
            internalError("eff-invert: a quantum phi with no lowered incoming", &phi);
          if (same) {
            ctx.bind(&phi, h);
            if (later)
              carried.push_back({&phi, h});
            continue;
          }
          if (!intra || later)
            unimplemented("eff-invert: a classical join of different rails inside a cq_invert region", &phi);
          ctx.bind(&phi, lowerMerge(ctx, phi));
          continue;
        }
        if (head) {
          PHINode *np = B.CreatePHI(phi.getType(), phi.getNumIncomingValues());
          ctx.bind(&phi, np);
          classicalPhis.push_back({&phi, np});
          continue;
        }
        Value *v = phi.getIncomingValue(0);
        for (Value *w : phi.incoming_values())
          if (w != v)
            unimplemented("eff-invert: a classical phi at a quantum join inside a cq_invert region", &phi);
        ctx.bind(&phi, ctx.operand(v).v);
      }
    auto [it, end] = R.body(b);
    for (; it != end; ++it) {
      lowerInstruction(ctx, *it);
      if (B.GetInsertBlock() != S[s] || B.GetInsertPoint() != S[s]->end())
        unimplemented("eff-invert: control flow in the lowered body of a cq_invert region", &*it);
    }
    done.insert(b);
  }
  for (auto &[phi, h] : carried)
    for (Value *v : phi->incoming_values())
      if (railOfIncoming(v, *phi) != h)
        unimplemented("eff-invert: a loop-carried quantum value of a cq_invert region that is not one rail "
                      "across trips",
                      phi);

  // The uncompute of every rail the region made (step 3's Z).
  BasicBlock *Zb = BasicBlock::Create(C, "", &OF);
  B.SetInsertPoint(Zb);
  U.emitMirror(scope, B);
  U.closeScope(scope);

  // The skeleton's instructions and the gates of each segment.
  DenseMap<const BasicBlock *, unsigned> segOfOut;
  for (unsigned s = 0; s < nS; ++s)
    segOfOut[S[s]] = s;
  std::vector<std::vector<Gate>> G(nS);
  DenseMap<const Value *, std::pair<unsigned, unsigned>> gatePos;   // gate call -> (segment, index)
  DenseMap<const Instruction *, unsigned> skel;                      // classical instruction -> segment
  for (unsigned s = 0; s < nS; ++s) {
    auto it = s == 0 ? (lastBefore ? std::next(lastBefore->getIterator()) : cb->begin()) : S[s]->begin();
    for (; it != S[s]->end(); ++it) {
      Instruction &I = *it;
      if (I.isTerminator())
        internalError("eff-invert: a terminator in the lowered skeleton of a cq_invert region", &I);
      if (std::optional<Gate> g = gateOf(&I)) {
        gatePos[&I] = {s, (unsigned)G[s].size()};
        G[s].push_back(*g);
      } else {
        skel[&I] = s;
      }
    }
  }
  std::vector<Gate> Z;
  for (Instruction &I : *Zb) {
    std::optional<Gate> g = gateOf(&I);
    if (!g || g->kind == GK::TmplFwd || g->kind == GK::Alloc || g->kind == GK::Clone || g->kind == GK::Rotation ||
        g->kind == GK::QAngle)
      unimplemented("eff-invert: an uncompute of a cq_invert region that is not an _unc, a free or an involution",
                    &I);
    Z.push_back(*g);
  }

  // A classical instruction may not read a rail the region made.
  for (auto &[I, s] : skel)
    for (const Value *op : I->operands())
      if (gatePos.count(op))
        unimplemented("eff-invert: a classical instruction reading a rail made inside a cq_invert region", I);

  // Memory: the skeleton runs every classical write before any reversed gate.
  {
    const Instruction *writer = nullptr, *reader = nullptr;
    for (auto &[I, s] : skel)
      if (I->mayWriteToMemory() && !I->isLifetimeStartOrEnd())
        writer = I;
    auto readsMemory = [](CallInst *c) {
      for (Value *a : c->args())
        if (a->getType()->isPointerTy())
          return true;
      return false;
    };
    for (unsigned s = 0; s < nS; ++s)
      for (const Gate &g : G[s])
        if (readsMemory(g.call))
          reader = g.call;
    if (writer && reader)
      unimplemented("eff-invert: a gate reading memory in a cq_invert region whose classical code writes memory "
                    "(the adjoint runs every classical write first)",
                    reader);
  }

  // Makers and their cleaning.
  std::vector<Maker> makers;
  DenseMap<const Value *, unsigned> makerOf;
  for (unsigned s = 0; s < nS; ++s)
    for (unsigned i = 0; i < G[s].size(); ++i)
      if (G[s][i].kind == GK::TmplFwd || G[s][i].kind == GK::Alloc) {
        makerOf[G[s][i].call] = makers.size();
        makers.push_back({G[s][i].call, s, i, G[s][i].kind == GK::TmplFwd});
      }
  auto makerNamed = [&](Value *r, CallInst *at, const char *what) -> Maker & {
    auto m = makerOf.find(r);
    if (m == makerOf.end())
      unimplemented(std::string("eff-invert: a rail made before a cq_invert region is ") + what + " inside it", at);
    return makers[m->second];
  };
  for (unsigned s = 0; s < nS; ++s)
    for (unsigned i = 0; i < G[s].size(); ++i) {
      const Gate &g = G[s][i];
      if (g.kind != GK::Free && g.kind != GK::TmplUnc)
        continue;
      Maker &m = makerNamed(g.call->getArgOperand(0), g.call, g.kind == GK::Free ? "freed" : "uncomputed");
      if (m.seg != s)
        unimplemented("eff-invert: a rail of a cq_invert region freed in another segment than the one making it",
                      g.call);
      if (i < m.idx)
        internalError("eff-invert: a rail freed before it is made", g.call);
      int &slot = g.kind == GK::Free ? m.localFree : m.localUnc;
      if (slot >= 0)
        internalError("eff-invert: a rail freed or uncomputed twice", g.call);
      slot = i;
    }
  auto targetOfZ = [&](const Gate &g) -> Value * {
    if (g.kind == GK::TmplUnc || g.kind == GK::Free)
      return g.call->getArgOperand(0);
    return writeTarget(g);
  };
  for (unsigned k = 0; k < Z.size(); ++k)
    makerNamed(targetOfZ(Z[k]), Z[k].call, "uncomputed").z.push_back(k);

  // The basis value of a seed at its free: lit XOR the uncontrolled xorc literals on it.
  auto foldXorc = [&](Value *v, CallInst *c) -> Value * {
    Value *lit = c->getArgOperand(1);
    Value *r = isa<Constant>(v) && isa<Constant>(lit)
                   ? ConstantFoldBinaryInstruction(Instruction::Xor, cast<Constant>(v), cast<Constant>(lit))
                   : nullptr;
    if (!r)
      unimplemented("eff-invert: a seed whose freed value is not a constant", c);
    return r;
  };
  for (Maker &m : makers) {
    std::vector<Gate> &Gs = G[m.seg];
    if (m.localFree >= 0 && !m.z.empty())
      internalError("eff-invert: a rail freed in its segment and uncomputed again after the region", m.call);
    // Writes on the rail in other segments (their undo would run where they did not).
    for (unsigned s = 0; s < nS; ++s)
      for (const Gate &g : G[s])
        if (writeTarget(g) == m.call && s != m.seg)
          unimplemented("eff-invert: a write on a rail of a cq_invert region outside the segment making it", g.call);
    if (m.tmpl) {
      if (m.localFree >= 0) {
        if (m.localUnc < 0 || m.localUnc > m.localFree)
          unimplemented("eff-invert: a template rail inside a cq_invert region freed without its _unc (rule 6 "
                        "clean-up)",
                        m.call);
        for (int j = m.localUnc + 1; j < m.localFree; ++j)
          for (Value *op : Gs[j].call->args())
            if (op == m.call)
              unimplemented("eff-invert: a rail read between its _unc and its free", Gs[j].call);
      } else if (!m.z.empty()) {
        if (m.localUnc >= 0 || m.z.size() != 2 || Z[m.z[0]].kind != GK::TmplUnc || Z[m.z[1]].kind != GK::Free)
          unimplemented("eff-invert: a template rail of a cq_invert region not uncomputed as _unc then free", m.call);
      } else {
        unimplemented("eff-invert: a rail made inside a cq_invert region is not freed inside it (it stays live: "
                      "rule 17 defines no adjoint of a region with an output)",
                      m.call);
      }
      continue;
    }
    // A seed.
    if (m.localUnc >= 0)
      internalError("eff-invert: an _unc of a seed", m.call);
    for (const Gate &g : Gs)
      if (g.kind == GK::Xorc && g.core.ctl && writeTarget(g) == m.call)
        unimplemented("eff-invert: a controlled xorc on a seed made inside a cq_invert region", g.call);
    Value *v = m.call->getArgOperand(0);
    unsigned endIdx = m.localFree >= 0 ? m.localFree : Gs.size();
    for (unsigned j = m.idx + 1; j < endIdx; ++j)
      if (Gs[j].kind == GK::Xorc && writeTarget(Gs[j]) == m.call)
        v = foldXorc(v, Gs[j].call);
    if (m.localFree < 0) {
      if (m.z.empty()) {
        m.kept = true;
        continue;
      }
      if (Z[m.z.back()].kind != GK::Free)
        unimplemented("eff-invert: a seed of a cq_invert region not freed last", m.call);
      for (unsigned k : m.z)
        if (Z[k].kind == GK::Xorc)
          v = foldXorc(v, Z[k].call);
    }
    m.freed = v;
  }

  // Values a reversed gate may read directly: from before the region, or of a segment that runs once
  // and dominates the end.
  auto needPop = [&](Value *v) {
    auto *I = dyn_cast<Instruction>(v);
    if (!I)
      return false;
    auto k = skel.find(I);
    if (k == skel.end())
      return false;
    return !(R.once(k->second) && R.dom[k->second].test(R.SE));
  };

  // Kept seeds: allocated before the reverse; their literal must be readable there.
  for (Maker &m : makers)
    if (m.kept) {
      if (!R.once(m.seg) || !R.dom[m.seg].test(R.SE) || needPop(m.call->getArgOperand(0)))
        unimplemented("eff-invert: a register a cq_invert region prepares on some paths or trips only", m.call);
    }

  // Rule 5's invariant (step 6): no non-diagonal gate or in-place write on a rail a template of the region
  // reads, between that template and its uncompute.
  for (const Maker &m : makers) {
    if (!m.tmpl)
      continue;
    for (Value *op : m.call->args()) {
      if (isa<Constant>(op))
        continue;
      for (unsigned s = 0; s < nS; ++s)
        for (unsigned i = 0; i < G[s].size(); ++i) {
          const Gate &g = G[s][i];
          if (g.call == m.call || writeTarget(g) != op)
            continue;
          bool safe;
          if (s == m.seg)
            safe = i < m.idx || (m.localFree >= 0 && (int)i > m.localUnc);
          else
            safe = R.dom[s].test(m.seg) && !R.sameCycle(s, m.seg);
          if (!safe)
            unimplemented(std::string("eff-invert: a ") + (nonDiagonal(g) ? "non-diagonal gate" : "write") +
                              " inside a cq_invert region on a rail a template of the region reads (rule 5)",
                          g.call);
        }
    }
  }

  // Step 6: a quantum value of the region read after it.
  {
    DenseSet<const Value *> regionRail;
    for (const Maker &m : makers)
      if (!m.kept)
        regionRail.insert(m.call);
    auto check = [&](Instruction &I) {
      if (I.getType()->isVoidTy() || !isQ(&I))
        return;
      bool after = false;
      for (const User *u : I.users())
        if (auto *ui = dyn_cast<Instruction>(u); ui && !R.contains(ui))
          after = true;
      if (!after)
        return;
      for (const Operand &o : ctx.fields(&I))
        if (o.handle && regionRail.count(o.v))
          unimplemented("eff-invert: a quantum value of a cq_invert region read after it (rule 17 defines no "
                        "adjoint of a region with an output)",
                        &I);
    };
    for (BasicBlock *b : R.rpo) {
      if (b != R.bb)
        for (PHINode &phi : b->phis())
          check(phi);
      auto [it, end] = R.body(b);
      for (; it != end; ++it)
        check(*it);
    }
  }

  // Step 4: frontiers. fr[s]: the edges leaving D(s); exitFr[s]: s dominates the end.
  std::vector<std::vector<unsigned>> fr(nS);
  std::vector<bool> exitFr(nS);
  for (unsigned s = 0; s < nS; ++s) {
    for (unsigned e = 0; e < R.edges.size(); ++e) {
      const Edge &E = R.edges[e];
      if (R.dom[s].test(E.from) && (!R.dom[s].test(E.to) || E.to == s))
        fr[s].push_back(e);
    }
    exitFr[s] = R.dom[s].test(R.SE);
  }

  // Step 5: the reverse.
  const unsigned nE = R.edges.size();
  std::vector<BasicBlock *> Eb(nE), REb(nE), Rb(nS);
  for (unsigned e = 0; e < nE; ++e)
    Eb[e] = newBlock();
  BasicBlock *REexit = newBlock();
  for (unsigned s = nS; s-- > 0;) {
    Rb[s] = newBlock();
    for (unsigned e : R.segs[s].pred)
      REb[e] = newBlock();
  }
  BasicBlock *K = newBlock();

  // The placed instances of each reverse block, in order.
  DenseMap<BasicBlock *, std::vector<CallInst *>> placed;
  std::vector<CallInst *> rotations;          // instances whose last argument is negated
  DenseMap<const Value *, std::vector<CallInst *>> defs;   // region rail -> its re-makings
  DenseMap<const CallInst *, const Value *> instanceOf;    // a re-making's instance -> the rail it re-makes

  for (unsigned s = 0; s < nS; ++s) {
    std::vector<Gate> &Gs = G[s];
    const unsigned n = Gs.size();
    std::vector<std::vector<CallInst *>> slot(n);
    for (unsigned i = 0; i < n; ++i) {
      Gate &g = Gs[i];
      CallInst *c = g.call;
      switch (g.kind) {
      case GK::TmplFwd:
      case GK::Alloc: {
        Maker &m = makers[makerOf.lookup(c)];
        if (m.kept)
          break;
        if (m.localFree >= 0) {
          if (m.tmpl) {
            slot[i] = {Gs[m.localUnc].call, Gs[m.localFree].call};
            slot[m.localUnc] = {c};
          } else {
            slot[i] = {Gs[m.localFree].call};
            slot[m.localFree] = {c};
            if (m.freed != c->getArgOperand(0))
              c->setArgOperand(0, m.freed);
          }
        } else if (m.tmpl) {
          slot[i] = {Z[m.z[0]].call, Z[m.z[1]].call};
        } else {
          slot[i] = {Z[m.z.back()].call};
        }
        break;
      }
      case GK::TmplUnc:
      case GK::Free:
        break;   // placed with their maker
      case GK::Rotation:
        if (!c->getArgOperand(c->arg_size() - 1)->getType()->isDoubleTy())
          internalError("eff-invert: a rotation whose angle is not f64", c);
        rotations.push_back(c);
        slot[i] = {c};
        break;
      case GK::QAngle: {
        // Rule 15's angle rail A: the inverse is the same gate on -val(A), a fresh f64 rail computed by
        // the fneg template around it and uncomputed after it (compute, gate, uncompute, free).
        unsigned a = c->arg_size() - 1;
        Value *A = c->getArgOperand(a);
        abi::TemplateSpec fneg;
        fneg.op = "fneg";
        fneg.w = RailType{Kind::Fp, 64};
        CallInst *t = CallInst::Create(abi::declare(M, fneg, false), {A});
        CallInst *tu = CallInst::Create(abi::declare(M, fneg, true), {t, A});
        CallInst *tf = CallInst::Create(abi::declare(M, abi::CoreSpec{abi::Core::Free}), {t});
        c->setArgOperand(a, t);
        slot[i] = {t, c, tu, tf};
        break;
      }
      case GK::Xorc:
      case GK::Involution:
      case GK::Clone:
        slot[i] = {c};
        break;
      }
    }
    for (unsigned i = n; i-- > 0;)
      for (CallInst *c : slot[i])
        placed[Rb[s]].push_back(c);
  }
  // The re-makings on the reverse edges: Z reversed, each call inverted, where its rail's frontier is.
  {
    DenseMap<const Value *, bool> usedMaker;
    DenseSet<const CallInst *> usedZ;
    auto instanceFor = [&](unsigned k) -> CallInst * {
      const Gate &z = Z[k];
      Maker &m = makers[makerOf.lookup(targetOfZ(z))];
      if (z.kind == GK::TmplUnc || (z.kind == GK::Free && !m.tmpl)) {
        CallInst *c = usedMaker.lookup(m.call) ? cast<CallInst>(m.call->clone()) : m.call;
        usedMaker[m.call] = true;
        if (!m.tmpl)
          c->setArgOperand(0, m.freed);
        defs[m.call].push_back(c);
        instanceOf[c] = m.call;
        return c;
      }
      if (z.kind == GK::Free)
        return nullptr;   // a template rail: its T re-makes it
      CallInst *c = usedZ.count(z.call) ? cast<CallInst>(z.call->clone()) : z.call;
      usedZ.insert(z.call);
      return c;
    };
    for (unsigned k = Z.size(); k-- > 0;) {
      const Maker &m = makers[makerOf.lookup(targetOfZ(Z[k]))];
      bool any = false;
      for (unsigned e : fr[m.seg])
        if (CallInst *c = instanceFor(k)) {
          placed[REb[e]].push_back(c);
          any = true;
        } else {
          any = true;
        }
      if (exitFr[m.seg]) {
        any = true;
        if (CallInst *c = instanceFor(k))
          placed[REexit].push_back(c);
      }
      if (!any)
        internalError("eff-invert: a rail of a cq_invert region with no place to be re-made", Z[k].call);
    }
    // Z's _unc and free of a Z-cleaned rail went to R(maker); its involutions to the reverse edges.
    for (const Gate &z : Z)
      if (z.kind != GK::TmplUnc && z.kind != GK::Free && !usedZ.count(z.call))
        internalError("eff-invert: an uncompute of a cq_invert region with no place", z.call);
  }

  // Classical values: pops at the head of R(F) and RE(e), pushes at the end of S(F) and on E(e).
  // Declared on first use: a region with no classical control flow uses no stack.
  auto push = [&]() { return abi::declare(M, abi::CoreSpec{abi::Core::Push}); };
  auto pop = [&]() { return abi::declare(M, abi::CoreSpec{abi::Core::Pop}); };
  auto popList = [&](BasicBlock *X) {
    SetVector<Value *> vs;
    for (CallInst *c : placed[X])
      for (Value *a : c->args())
        if (!instanceOf.count(dyn_cast<CallInst>(a)) && !defs.count(a) && needPop(a))
          vs.insert(a);
    return vs;
  };
  std::vector<SetVector<Value *>> PS(nS), PE(nE);
  for (unsigned s = 0; s < nS; ++s)
    PS[s] = popList(Rb[s]);
  for (unsigned e = 0; e < nE; ++e)
    PE[e] = popList(REb[e]);

  // Kept seeds go before the reverse (the end of S(SE)).
  for (Maker &m : makers)
    if (m.kept)
      m.call->moveBefore(*S[R.SE], S[R.SE]->end());

  IRBuilder<> XB(C);
  // Pushes and the skeleton's classical terminators.
  for (unsigned s = 0; s < nS; ++s) {
    XB.SetInsertPoint(S[s]);
    for (Value *v : PS[s])
      pushValue(XB, push(), v, cast<Instruction>(v));
    if (s == R.SE) {
      XB.CreateBr(REexit);
      continue;
    }
    Instruction *t = R.segs[s].blocks.back()->getTerminator();
    auto target = [&](BasicBlock *orig) { return Eb[R.edgeId.at({s, R.segOf.lookup(orig)})]; };
    if (BasicBlock *j = R.segs[s].exitTo) {
      XB.CreateBr(target(j));
    } else if (auto *br = dyn_cast<BranchInst>(t)) {
      if (!br->isConditional()) {
        XB.CreateBr(target(br->getSuccessor(0)));
      } else {
        Operand c = ctx.operand(br->getCondition());
        if (c.handle)
          internalError("eff-invert: a classical branch on a rail", t);
        XB.CreateCondBr(c.v, target(br->getSuccessor(0)), target(br->getSuccessor(1)));
      }
    } else {
      auto *sw = cast<SwitchInst>(t);
      Operand c = ctx.operand(sw->getCondition());
      if (c.handle)
        internalError("eff-invert: a classical switch on a rail", t);
      SwitchInst *ns = XB.CreateSwitch(c.v, target(sw->getDefaultDest()), sw->getNumCases());
      for (auto &cs : sw->cases())
        ns->addCase(cs.getCaseValue(), target(cs.getCaseSuccessor()));
    }
  }
  for (unsigned e = 0; e < nE; ++e) {
    const Edge &E = R.edges[e];
    XB.SetInsertPoint(Eb[e]);
    for (Value *v : PE[e])
      pushValue(XB, push(), v, cast<Instruction>(v));
    const auto &preds = R.segs[E.to].pred;
    if (preds.size() > 1)
      XB.CreateCall(push(), {XB.getInt32(std::find(preds.begin(), preds.end(), e) - preds.begin())});
    XB.CreateBr(S[E.to]);
  }
  // Classical phis of segment heads: one incoming per edge block.
  for (auto &[orig, np] : classicalPhis) {
    unsigned v = R.segOf.lookup(orig->getParent());
    for (unsigned e : R.segs[v].pred) {
      // Every incoming from the edge's segment carries one value (else taint makes the phi quantum).
      Value *val = nullptr;
      for (unsigned i = 0; i < orig->getNumIncomingValues(); ++i)
        if (R.segOf.lookup(orig->getIncomingBlock(i)) == R.edges[e].from) {
          if (val && val != orig->getIncomingValue(i))
            internalError("eff-invert: a classical phi whose incomings from one segment differ", orig);
          val = orig->getIncomingValue(i);
        }
      if (!val)
        internalError("eff-invert: a classical phi with no incoming from a predecessor segment", orig);
      Operand o = ctx.operand(val);
      if (o.handle)
        internalError("eff-invert: a classical phi with a rail incoming", orig);
      np->addIncoming(o.v, Eb[e]);
    }
  }

  // Reverse blocks: pops, the placed gates (operands remapped), the reverse branch.
  std::vector<std::pair<CallInst *, unsigned>> railUses;   // (instance, argument) reading a re-made rail
  auto fill = [&](BasicBlock *X, const SetVector<Value *> &pops) {
    XB.SetInsertPoint(X);
    DenseMap<Value *, Value *> popped;
    for (unsigned i = pops.size(); i-- > 0;)
      popped[pops[i]] = popValue(XB, pop(), pops[i]->getType(), cast<Instruction>(pops[i]));
    for (CallInst *c : placed[X]) {
      if (c->getParent())
        c->removeFromParent();
      c->insertInto(X, X->end());
      for (unsigned a = 0; a < c->arg_size(); ++a) {
        Value *v = c->getArgOperand(a);
        if (defs.count(v)) {
          railUses.push_back({c, a});
          continue;
        }
        if (Value *p = popped.lookup(v))
          c->setArgOperand(a, p);
        else if (X != REexit && needPop(v))
          internalError("eff-invert: a reversed gate reading a classical value that was not pushed", c);
      }
    }
    XB.SetInsertPoint(X);
  };
  fill(REexit, {});
  XB.CreateBr(Rb[R.SE]);
  for (unsigned s = 0; s < nS; ++s) {
    fill(Rb[s], PS[s]);
    const auto &preds = R.segs[s].pred;
    if (preds.empty()) {
      if (s != 0)
        internalError("eff-invert: a segment with no predecessor that is not the first", R.stop);
      XB.CreateBr(K);
    } else if (preds.size() == 1) {
      XB.CreateBr(REb[preds[0]]);
    } else {
      SwitchInst *sw = XB.CreateSwitch(XB.CreateCall(pop()), REb[preds.back()], preds.size() - 1);
      for (unsigned k = 0; k + 1 < preds.size(); ++k)
        sw->addCase(XB.getInt32(k), REb[preds[k]]);
    }
  }
  for (unsigned e = 0; e < nE; ++e) {
    fill(REb[e], PE[e]);
    XB.CreateBr(Rb[R.edges[e].from]);
  }
  if (!Zb->empty())
    internalError("eff-invert: an uncompute of a cq_invert region left unplaced", &Zb->front());
  for (unsigned s = 0; s < nS; ++s)
    for (const Gate &g : G[s])
      if (g.call->getParent() == S[s] && !(g.kind == GK::Alloc && makers[makerOf.lookup(g.call)].kept))
        internalError("eff-invert: a forward gate of a cq_invert region left in the skeleton", g.call);
  Zb->eraseFromParent();

  // Negated angles: a classical fneg right before each rotation.
  for (CallInst *c : rotations) {
    unsigned a = c->arg_size() - 1;
    XB.SetInsertPoint(c);
    c->setArgOperand(a, XB.CreateFNeg(c->getArgOperand(a)));
  }

  // Rails re-made on the reverse edges: every use reads the re-making that reaches it.
  {
    std::map<const Value *, std::unique_ptr<SSAUpdater>> ssa;
    for (auto &[r, ds] : defs) {
      auto up = std::make_unique<SSAUpdater>();
      up->Initialize(r->getType(), "");
      for (CallInst *d : ds)
        up->AddAvailableValue(d->getParent(), d);
      ssa[r] = std::move(up);
    }
    for (auto &[c, a] : railUses) {
      Value *r = c->getArgOperand(a);
      Value *v = nullptr;
      for (CallInst *d : defs[r])
        if (d->getParent() == c->getParent() && d->comesBefore(c))
          v = d;
      if (!v)
        v = ssa[r]->GetValueInMiddleOfBlock(c->getParent());
      c->setArgOperand(a, v);
    }
  }

  // Tidy: fold the blocks a straight chain leaves.
  for (BasicBlock *b : std::vector<BasicBlock *>(Eb.begin(), Eb.end()))
    MergeBlockIntoPredecessor(b);
  std::vector<BasicBlock *> rest(S.begin() + 1, S.end());
  rest.push_back(REexit);
  rest.insert(rest.end(), Rb.begin(), Rb.end());
  rest.insert(rest.end(), REb.begin(), REb.end());
  for (BasicBlock *b : rest)
    MergeBlockIntoPredecessor(b);
  BasicBlock *kp = K->getSinglePredecessor();
  if (kp && kp->getSingleSuccessor() == K) {
    kp->getTerminator()->eraseFromParent();
    K->eraseFromParent();
    K = kp;
  }
  B.SetInsertPoint(K);
}

} // namespace

void lowerRegion(LoweringContext &ctx, CallInst &begin, CallInst &end) {
  Region R = analyze(ctx, begin.getParent(), &begin, end.getParent(), &end);
  lowerRegion(ctx, R);
}

// The body of an _adj clone (rule 17: clones as _adj): the whole body of F, entry to return, as one
// region. Called with F's formals bound and the builder at the end of the clone's entry block; emits
// the clone's return.
void lowerAdjointBody(LoweringContext &ctx, Function &F) {
  ReturnInst *ret = nullptr;
  for (BasicBlock &BB : F)
    if (auto *r = dyn_cast<ReturnInst>(BB.getTerminator())) {
      if (ret)
        unimplemented("eff-invert: an _adj clone of a function with more than one return", r);
      ret = r;
    }
  if (!ret)
    unimplemented("eff-invert: an _adj clone of a function that never returns", &F);
  if (ret->getReturnValue())
    unimplemented("eff-invert: an _adj clone of a function with a result (rule 17 defines no adjoint of a region "
                  "with an output)",
                  ret);
  Region R = analyze(ctx, &F.getEntryBlock(), nullptr, ret->getParent(), ret);
  lowerRegion(ctx, R);
  ReturnInst *nr = ctx.B().CreateRetVoid();
  ctx.unc().flushAtExit(nr);
}

} // namespace cq::invert
