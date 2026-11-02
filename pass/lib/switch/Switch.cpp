// Module switch (cq-w1-switch): a switch over a quantum scrutinee, CR rule 13.
//
// Rule 13: one equality flag per reachable case on the scrutinee; a shared or fallthrough block gets
// or_i1 of its edge flags; an `unreachable` default gets no flag, and then the last case needs none
// either (it is the complement of the others and becomes the innermost select arm); a reachable
// default is the complement of the case flags. Value arms merge per rule 9, phase arms per rule 8.
//
// The construction is entirely in the edge predicates (A3): switchEdges gives each successor the
// Boolean function under which the switch transfers control to it, over Pred::eqAtom(scrutinee, v)
// atoms. PathPredicates (pred) turns those into block predicates; a block reached by several edges
// (shared case, fallthrough) is their disjunction, which pred materialises as or_i1 into a fresh
// flag; a value merge is pred's rule-9 select chain, in which a complement arm is taken last with no
// flag; a phase is rz_i1 on the block's flag. An eqAtom becomes cq_template_icmp_eq_<W>_hl on the
// scrutinee rail when, and only when, a flag or a select reads it.
//
// The flags are disjoint (the scrutinee holds one value). The BDD treats each eqAtom as a free
// variable, so the complement is spelled exactly as the negated disjunction of the other case atoms;
// on every input in the domain it equals the rule's "the remaining case".
//
// A case or default whose destination is an `unreachable` block is never taken in the domain (LLVM:
// reaching `unreachable` is undefined), so it is not a reachable case: its edge predicate is false
// and it mints no flag.
#include "cq/Switch.h"

#include "cq/Common.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq::sw {
namespace {

// A block whose execution is undefined on entry: its first real instruction is `unreachable`.
bool isUnreachableBlock(const BasicBlock *bb) {
  const Instruction *i = bb->getFirstNonPHIOrDbg();
  return i && isa<UnreachableInst>(i);
}

} // namespace

EdgePreds switchEdges(const SwitchInst &si, const TaintInfo &T, const Specialization &S) {
  const Value *x = si.getCondition();
  if (!T.isQuantum(x, S))
    internalError("switch: sw::switchEdges on a classical scrutinee (it stays a classical switch)", &si);
  if (!x->getType()->isIntegerTy())
    internalError("switch: a switch scrutinee that is not an integer", &si);

  // The reachable cases, in the switch's case order.
  struct Case { APInt v; const BasicBlock *to; };
  SmallVector<Case, 8> cases;
  for (const auto &c : si.cases())
    if (!isUnreachableBlock(c.getCaseSuccessor()))
      cases.push_back({c.getCaseValue()->getValue(), c.getCaseSuccessor()});
  const BasicBlock *def = si.getDefaultDest();
  bool defaultReachable = !isUnreachableBlock(def);
  // With no reachable destination, executing the switch is undefined (LLVM): every edge predicate is
  // false below, as for any unreachable destination, and nothing is minted.

  // Each reachable case's edge condition. With an unreachable default the last reachable case is the
  // complement of the others (no flag of its own).
  SmallVector<Pred, 8> cond;
  Pred others = Pred::bottom();
  for (unsigned i = 0; i < cases.size(); ++i) {
    bool complement = !defaultReachable && i + 1 == cases.size();
    if (complement) {
      cond.push_back(!others);
    } else {
      Pred eq = Pred::eqAtom(x, cases[i].v);
      cond.push_back(eq);
      others = others | eq;
    }
  }

  // One entry per distinct successor, in successor order (default first): the disjunction of its
  // edges' conditions. A reachable default is the complement of every reachable case flag.
  EdgePreds out;
  DenseMap<const BasicBlock *, unsigned> slot;
  auto add = [&](const BasicBlock *to, const Pred &p) {
    auto it = slot.find(to);
    if (it == slot.end()) {
      slot[to] = out.succ.size();
      out.succ.push_back({to, p});
    } else {
      out.succ[it->second].second = out.succ[it->second].second | p;
    }
  };
  if (defaultReachable) {
    Pred none = Pred::top();
    for (const Pred &c : cond)
      none = none & !c;
    add(def, none);
  } else {
    add(def, Pred::bottom());
  }
  unsigned k = 0;
  for (const auto &c : si.cases()) {
    const BasicBlock *to = c.getCaseSuccessor();
    if (isUnreachableBlock(to)) {
      add(to, Pred::bottom());
      continue;
    }
    add(to, cond[k++]);
  }
  return out;
}

// The switch itself emits nothing: its edges are absorbed into PathPredicates (switchEdges), and the
// spine linearizes the arms under their block predicates, exactly as pred's lowerBranch for a br.
void lowerSwitch(LoweringContext &ctx, SwitchInst &si) {
  if (!ctx.T.isQuantum(si.getCondition(), ctx.S))
    internalError("switch: sw::lowerSwitch on a classical scrutinee (it stays a classical switch)", &si);
  // Every successor's edge predicate must have been computed for this function (pred's edge() is an
  // internal error otherwise); asking here pins the contract at the switch, not at a later merge.
  for (const BasicBlock *to : successors(&si))
    (void)ctx.preds().edge(si.getParent(), to);
}

} // namespace cq::sw
