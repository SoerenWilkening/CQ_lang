// Module eff-invert (cq-w1-eff-invert): cq_invert regions, CR rule 17.
//
// Rule 17: the bracketed region's gate list is emitted reversed with each gate inverted: angles
// negated, compute/uncompute pairs reverse into themselves (flags are recomputed inside the adjoint),
// loop trips in reverse order, clones as _adj. The markers and the asm fences are consumed.
//
// CONSTRUCTION
//
//  1. The region. begin and end are the __cq_invert_begin/end calls the spine hands over (the spine
//     skips every original instruction from begin to end). begin dominates end and end's block
//     post-dominates begin's. The region's blocks are those reachable from begin's block without
//     passing through end's block, then end's block; inside it every branch is quantum or
//     unconditional (a classical branch, a loop, a phi past begin's block, a return: unimplemented).
//     A quantum branch emits nothing (pred's lowerBranch emits no terminator), so the region's
//     lowered forward body is one straight run of the output block.
//  2. The empty memory-clobber asm fence right after begin and the one right before end (CQ.h's
//     barriers, no operands) are consumed (cq-arch note). Nothing else is.
//  3. Forward. Inside an Uncompute scope, every original instruction of the region is lowered in
//     order with lowerInstruction (block predicate of its own block, so a phase in an arm is rz_i1 on
//     the arm's flag); then emitMirror(scope) uncomputes and frees every rail the region made. This is
//     the region's full forward gate list U = g_1 ... g_n: computes, gates, uncomputes, frees. A
//     quantum value of the region read after it is unimplemented (the adjoint of a region with an
//     output is not defined by rule 17).
//  4. Adjoint. U^-1 = g_n^-1 ... g_1^-1. Classical instructions of the run carry no gate; they are
//     hoisted, in order, in front of the adjoint (with the fneg of every negated angle). Each gate's
//     inverse is placed at the mirror position of the gate, reusing the forward call objects, so every
//     Uncompute record still names its own calls:
//       - r = T(args) (a template; it allocates r from |0> and computes) and its T_unc(r, args),
//         cqrt_free(r): T^-1 is T_unc(r, args); free(r) at T's mirror, and (T_unc; free)^-1 is
//         r = T(args) at T_unc's mirror. The pair reverses into itself (CR: "compute/uncompute pairs
//         reverse into themselves").
//       - r = alloc_<W>(lit) ... free(r) (a seed): alloc^-1 is free(r) at alloc's mirror, and free^-1
//         is r = alloc_<W>(v) at free's mirror, v the basis value r held when freed: lit XOR every
//         uncontrolled xorc literal on r in the run (the other writes are undone pairwise by Uncompute
//         before the free, so they cancel; CR §0: free sees a known basis state).
//       - an involution (not_i1, and_i1, or_i1, xor_i1, copy, xorc, controlled forms): itself.
//       - ry_<W>[_controlled](.., h, θ) and rz_i1(f, θ): the same gate at -θ (a classical fneg).
//       - ry_<W>_qangle[_controlled](.., h, A), rz_qangle[_controlled]([c,] A) (rule 15): the same gate
//         on t = cq_template_fneg_f64(A), then fneg_f64_unc(t, A) and free(t). These calls are not
//         Uncompute records: the triple is balanced where it is emitted.
//       - anything else (a measurement, QRAM, tape, abort, push/pop, a clone call,
//         a template rail freed without its _unc, a rail made before the region uncomputed inside
//         it): unimplemented.
//     Reversing a valid gate sequence keeps it valid: every rail is (re)made before its last-mirrored
//     use, and an operand rail still outlives every _unc that reads it (rule 5).
//
// References: Bennett.jl 824458d src/bennett_transform.jl:_bennett_default (lines 337-381) replays the
// forward gate list in reverse order, each gate by its inverse (a self-inverse Toffoli/CNOT/NOT),
// which is step 4; rule 17 adds the rotations' angle negation, which Bennett.jl (classical
// reversible) has no counterpart for.
#include "cq/Effects.h"

#include <map>
#include <optional>
#include <vector>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Lowering.h"
#include "cq/Uncompute.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/ConstantFold.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"

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

// The original instructions of the region, in an order that respects the region's DAG.
// terms receives the region's own terminators (every region block's but end's): they emit nothing.
std::vector<Instruction *> regionBody(LoweringContext &ctx, CallInst &begin, CallInst &end,
                                      std::vector<Instruction *> &terms) {
  BasicBlock *bb = begin.getParent(), *eb = end.getParent();
  Function &F = *bb->getParent();
  std::vector<Instruction *> body;
  if (bb == eb) {
    if (!begin.comesBefore(&end))
      unimplemented("eff-invert: __cq_invert_end before its __cq_invert_begin", &end);
    for (auto it = std::next(begin.getIterator()); &*it != &end; ++it)
      body.push_back(&*it);
    return body;
  }
  DominatorTree DT(F);
  PostDominatorTree PDT(F);
  if (!DT.dominates(bb, eb) || !PDT.dominates(eb, bb))
    unimplemented("eff-invert: a cq_invert region that is not single-entry single-exit (begin's block must "
                  "dominate end's, end's must post-dominate begin's)",
                  &begin);
  // Blocks reachable from bb without passing through eb, in reverse post-order; eb last.
  DenseSet<BasicBlock *> seen{bb, eb};
  std::vector<BasicBlock *> post;
  std::vector<std::pair<BasicBlock *, unsigned>> stack{{bb, 0}};
  while (!stack.empty()) {
    auto &[b, k] = stack.back();
    Instruction *t = b->getTerminator();
    if (k == t->getNumSuccessors()) {
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
  std::vector<BasicBlock *> order(post.rbegin(), post.rend());
  DenseMap<BasicBlock *, unsigned> pos;
  for (unsigned i = 0; i < order.size(); ++i)
    pos[order[i]] = i;
  order.push_back(eb);
  pos[eb] = order.size() - 1;
  for (BasicBlock *b : order) {
    if (b != bb)
      for (PHINode &phi : b->phis())
        unimplemented("eff-invert: a phi inside a cq_invert region", &phi);
    if (b == eb)
      break;
    Instruction *t = b->getTerminator();
    terms.push_back(t);
    for (BasicBlock *s : successors(b))
      if (pos.lookup(s) <= pos.lookup(b))
        unimplemented("eff-invert: a loop inside a cq_invert region (rule 17: trips in reverse order)", t);
    if (auto *br = dyn_cast<BranchInst>(t)) {
      if (br->isConditional() && !ctx.T.isQuantum(br->getCondition(), ctx.S))
        unimplemented("eff-invert: a classical branch inside a cq_invert region", t);
    } else if (auto *sw = dyn_cast<SwitchInst>(t)) {
      if (!ctx.T.isQuantum(sw->getCondition(), ctx.S))
        unimplemented("eff-invert: a classical switch inside a cq_invert region", t);
    } else {
      unimplemented("eff-invert: a terminator inside a cq_invert region", t);
    }
  }
  for (BasicBlock *b : order) {
    auto it = b == bb ? std::next(begin.getIterator()) : b->getFirstNonPHIIt();
    auto stop = b == eb ? end.getIterator() : b->getTerminator()->getIterator();
    for (; it != stop; ++it)
      body.push_back(&*it);
  }
  return body;
}

enum class GK : uint8_t { TmplFwd, TmplUnc, Alloc, Free, Involution, Rotation, QAngle, Xorc };

struct Gate {
  CallInst *call;
  GK kind;
  abi::CoreSpec core{};
};

// What a call of the output run is: a gate (cqrt_*, cq_template_*) or classical (nullopt).
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
  if (abi::parseClone(n))
    unimplemented("eff-invert: a clone call inside a cq_invert region (rule 17: _adj)", C);
  return std::nullopt;
}

// The forward run [first, ob->end()) of the output block, replaced in place by its adjoint.
void adjoint(BasicBlock *ob, Instruction *first) {
  std::vector<Instruction *> run;
  for (auto it = first ? first->getIterator() : ob->end(); it != ob->end(); ++it)
    run.push_back(&*it);
  std::vector<Gate> G;
  std::vector<Instruction *> classical;
  DenseMap<const Value *, unsigned> gateIdx;
  for (Instruction *I : run) {
    if (std::optional<Gate> g = gateOf(I)) {
      gateIdx[I] = G.size();
      G.push_back(*g);
    } else {
      if (I->isTerminator())
        internalError("eff-invert: a terminator in the lowered run of a cq_invert region", I);
      classical.push_back(I);
    }
  }
  for (Instruction *I : classical)
    for (Value *op : I->operands())
      if (gateIdx.count(op))
        unimplemented("eff-invert: a classical instruction reading a rail made inside a cq_invert region", I);

  const unsigned n = G.size();
  std::vector<std::vector<CallInst *>> slot(n);
  std::vector<bool> done(n, false);
  // Rails made in the run: the free of each, and every gate reading it.
  DenseMap<const Value *, unsigned> freeOf;
  for (unsigned i = 0; i < n; ++i)
    if (G[i].kind == GK::Free) {
      Value *r = G[i].call->getArgOperand(0);
      auto c = gateIdx.find(r);
      if (c == gateIdx.end())
        unimplemented("eff-invert: a rail made before a cq_invert region is freed inside it", G[i].call);
      if (!freeOf.insert({r, i}).second)
        internalError("eff-invert: a rail freed twice", G[i].call);
    }
  auto freeIdx = [&](CallInst *r) -> unsigned {
    auto f = freeOf.find(r);
    if (f == freeOf.end())
      unimplemented("eff-invert: a rail made inside a cq_invert region is not freed inside it (it stays live: "
                    "rule 17 defines no adjoint of a region with an output)",
                    r);
    if (f->second < gateIdx.lookup(r))
      internalError("eff-invert: a rail freed before it is made", r);
    return f->second;
  };

  // Negated angles and seed literals are classical values placed in front of the adjoint.
  IRBuilder<> CB(ob);
  std::map<Value *, Value *> negated;
  std::vector<std::pair<CallInst *, std::pair<unsigned, Value *>>> argFix;   // (gate, (arg, value))

  for (unsigned i = 0; i < n; ++i) {
    Gate &g = G[i];
    CallInst *c = g.call;
    switch (g.kind) {
    case GK::TmplFwd: {
      unsigned f = freeIdx(c);
      int u = -1;
      for (unsigned j = i + 1; j < f; ++j)
        if (G[j].kind == GK::TmplUnc && G[j].call->getArgOperand(0) == c) {
          if (u >= 0)
            internalError("eff-invert: a template rail uncomputed twice", G[j].call);
          u = j;
        }
      if (u < 0)
        unimplemented("eff-invert: a template rail inside a cq_invert region freed without its _unc (rule 6 "
                      "clean-up)",
                      c);
      for (unsigned j = u + 1; j < f; ++j)
        for (Value *op : G[j].call->args())
          if (op == c)
            unimplemented("eff-invert: a rail read between its _unc and its free", G[j].call);
      slot[i] = {G[u].call, G[f].call};
      slot[u] = {c};
      done[i] = done[u] = done[f] = true;
      break;
    }
    case GK::TmplUnc:
      if (!done[i])
        unimplemented("eff-invert: a rail made before a cq_invert region is uncomputed inside it", c);
      break;
    case GK::Alloc: {
      unsigned f = freeIdx(c);
      Value *v = c->getArgOperand(0);
      for (unsigned j = i + 1; j < f; ++j)
        if (G[j].kind == GK::Xorc && !G[j].core.ctl && G[j].call->getArgOperand(0) == c) {
          Value *lit = G[j].call->getArgOperand(1);
          v = isa<Constant>(v) && isa<Constant>(lit) ? ConstantFoldBinaryInstruction(Instruction::Xor,
                                                                                    cast<Constant>(v),
                                                                                    cast<Constant>(lit))
                                                     : nullptr;
          if (!v)
            unimplemented("eff-invert: a seed whose freed value is not a constant", G[j].call);
        }
      slot[i] = {G[f].call};
      slot[f] = {c};
      if (v != c->getArgOperand(0))
        argFix.push_back({c, {0, v}});
      done[i] = done[f] = true;
      break;
    }
    case GK::Free:
      if (!done[i])
        internalError("eff-invert: a free not paired with its rail's maker", c);
      break;
    case GK::Rotation: {
      unsigned a = c->arg_size() - 1;
      Value *theta = c->getArgOperand(a);
      if (!theta->getType()->isDoubleTy())
        internalError("eff-invert: a rotation whose angle is not f64", c);
      Value *&neg = negated[theta];
      if (!neg)
        neg = CB.CreateFNeg(theta);
      argFix.push_back({c, {a, neg}});
      slot[i] = {c};
      done[i] = true;
      break;
    }
    case GK::QAngle: {
      // Rule 15's angle rail A: the inverse is the same gate on -val(A), a fresh f64 rail computed
      // by the fneg template around it and uncomputed after it (compute, gate, uncompute, free).
      unsigned a = c->arg_size() - 1;
      Value *A = c->getArgOperand(a);
      abi::TemplateSpec fneg;
      fneg.op = "fneg";
      fneg.w = RailType{Kind::Fp, 64};
      Module &M = *ob->getModule();
      CallInst *t = CB.CreateCall(abi::declare(M, fneg, false), {A});
      CallInst *tu = CB.CreateCall(abi::declare(M, fneg, true), {t, A});
      CallInst *tf = CB.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Free}), {t});
      argFix.push_back({c, {a, t}});
      slot[i] = {t, c, tu, tf};
      done[i] = true;
      break;
    }
    case GK::Xorc:
    case GK::Involution:
      slot[i] = {c};
      done[i] = true;
      break;
    }
  }
  for (unsigned i = 0; i < n; ++i)
    if (!done[i])
      internalError("eff-invert: a gate with no place in the adjoint", G[i].call);

  // Rebuild: classical instructions (in order), the negations, then the mirrored slots.
  std::vector<Instruction *> negs;
  for (auto &[k, v] : negated)
    if (auto *I = dyn_cast<Instruction>(v))
      negs.push_back(I);
  for (Instruction *I : classical)
    I->moveBefore(*ob, ob->end());
  for (Instruction *I : negs)
    I->moveBefore(*ob, ob->end());
  for (unsigned s = n; s-- > 0;)
    for (CallInst *c : slot[s])
      c->moveBefore(*ob, ob->end());
  for (auto &[c, fix] : argFix)
    c->setArgOperand(fix.first, fix.second);
  // Dominance inside the block: every operand made in the block comes before its use.
  for (Instruction &I : *ob)
    for (Value *op : I.operands())
      if (auto *d = dyn_cast<Instruction>(op); d && d->getParent() == ob && !d->comesBefore(&I))
        internalError("eff-invert: the adjoint uses a value before it is made", &I);
}

} // namespace

void lowerRegion(LoweringContext &ctx, CallInst &begin, CallInst &end) {
  std::vector<Instruction *> terms;
  std::vector<Instruction *> body = regionBody(ctx, begin, end, terms);
  if (!body.empty() && isFence(body.front()))
    body.erase(body.begin());
  if (!body.empty() && isFence(body.back()))
    body.pop_back();

  DenseSet<const Instruction *> inBody(body.begin(), body.end());
  inBody.insert(terms.begin(), terms.end());
  for (Instruction *I : body) {
    if (auto *CB = dyn_cast<CallBase>(I)) {
      calls::Class k = calls::classify(*CB, ctx.T, ctx.S);
      if (k == calls::Class::InvertBegin || k == calls::Class::InvertEnd)
        unimplemented("eff-invert: a nested cq_invert region", I);
    }
    if (I->getType()->isVoidTy() || !ctx.T.isQuantum(I, ctx.S))
      continue;
    for (const User *u : I->users())
      if (auto *ui = dyn_cast<Instruction>(u); ui && !inBody.count(ui))
        unimplemented("eff-invert: a quantum value of a cq_invert region read after it (rule 17 defines no "
                      "adjoint of a region with an output)",
                      I);
  }

  IRBuilder<> &B = ctx.B();
  BasicBlock *ob = B.GetInsertBlock();
  if (!ob || B.GetInsertPoint() != ob->end())
    internalError("eff-invert: the builder is not at the end of an output block", &begin);
  Instruction *last = ob->empty() ? nullptr : &ob->back();

  Uncompute &U = ctx.unc();
  unsigned scope = U.openScope();
  for (Instruction *I : body)
    lowerInstruction(ctx, *I);
  if (B.GetInsertBlock() != ob || B.GetInsertPoint() != ob->end())
    unimplemented("eff-invert: control flow in the lowered body of a cq_invert region", &begin);
  U.emitMirror(scope, B);
  U.closeScope(scope);

  Instruction *first = last ? last->getNextNode() : (ob->empty() ? nullptr : &ob->front());
  if (first)
    adjoint(ob, first);
}

} // namespace cq::invert
