// TEST DOUBLE (tests/spine, cq-w0-construct). NOT the pred module. Stands in for pass/lib/pred while
// it is a stub. Straight-line only: every block predicate is top; anything that needs a real
// predicate (a quantum branch, a merge, a flag, a phase under a predicate) is an internal error.
#include "cq/Predicate.h"

using namespace llvm;

namespace cq {

struct Pred::Impl {
  bool top;
};
struct PathPredicates::Impl {};


Pred Pred::top() {
  Pred p;
  p.impl = std::make_shared<const Impl>(Impl{true});
  return p;
}
Pred Pred::bottom() {
  Pred p;
  p.impl = std::make_shared<const Impl>(Impl{false});
  return p;
}
Pred Pred::atom(const Value *) { internalError("pred double: atom"); }
Pred Pred::eqAtom(const Value *, const APInt &) { internalError("pred double: eqAtom"); }
Pred Pred::operator&(const Pred &o) const { return impl->top && o.impl->top ? top() : bottom(); }
Pred Pred::operator|(const Pred &o) const { return impl->top || o.impl->top ? top() : bottom(); }
Pred Pred::operator!() const { return impl->top ? bottom() : top(); }
bool Pred::isTop() const { return impl->top; }
bool Pred::isBottom() const { return !impl->top; }
Pred Pred::quantumPart(const TaintInfo &, const Specialization &) const { return *this; }
bool Pred::isClassical(const TaintInfo &, const Specialization &) const { return true; }

PathPredicates::PathPredicates() : impl(std::make_shared<Impl>()) {}
void PathPredicates::compute(Function &, const LoopInfo &, const TaintInfo &, const Specialization &, Value *) {}
const Pred &PathPredicates::block(const BasicBlock *) const {
  static const Pred t = Pred::top();
  return t;
}
const Pred &PathPredicates::edge(const BasicBlock *, const BasicBlock *) const { return block(nullptr); }
Value *PathPredicates::flag(LoweringContext &, const Pred &) { internalError("pred double: flag"); }
void lowerBranch(LoweringContext &, BranchInst &b) { internalError("pred double: lowerBranch", &b); }
Value *lowerMerge(LoweringContext &, PHINode &p) { internalError("pred double: lowerMerge", &p); }
Value *lowerSelect(LoweringContext &, SelectInst &s) { internalError("pred double: lowerSelect", &s); }
Value *selectChain(LoweringContext &, ArrayRef<std::pair<Pred, Operand>>, RailType) {
  internalError("pred double: selectChain");
}
void lowerPhase(LoweringContext &, CallInst &c) {
  // Rule 12 at top level with every predicate top: a global phase, deleted.
  (void)c;
}

} // namespace cq
