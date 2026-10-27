// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module pred (cq-w0-pred).
#include "cq/Predicate.h"

namespace cq {
Pred Pred::top() { unimplemented("pred: Pred::top"); }
Pred Pred::bottom() { unimplemented("pred: Pred::bottom"); }
Pred Pred::atom(const llvm::Value *) { unimplemented("pred: Pred::atom"); }
Pred Pred::eqAtom(const llvm::Value *, const llvm::APInt &) { unimplemented("pred: Pred::eqAtom"); }
Pred Pred::operator&(const Pred &) const { unimplemented("pred: Pred::operator&"); }
Pred Pred::operator|(const Pred &) const { unimplemented("pred: Pred::operator|"); }
Pred Pred::operator!() const { unimplemented("pred: Pred::operator!"); }
bool Pred::isTop() const { unimplemented("pred: Pred::isTop"); }
bool Pred::isBottom() const { unimplemented("pred: Pred::isBottom"); }
Pred Pred::quantumPart(const TaintInfo &, const Specialization &) const { unimplemented("pred: Pred::quantumPart"); }
bool Pred::isClassical(const TaintInfo &, const Specialization &) const { unimplemented("pred: Pred::isClassical"); }
void PathPredicates::compute(llvm::Function &, const llvm::LoopInfo &, const TaintInfo &, const Specialization &, llvm::Value *) { unimplemented("pred: PathPredicates::compute"); }
const Pred &PathPredicates::block(const llvm::BasicBlock *) const { unimplemented("pred: PathPredicates::block"); }
const Pred &PathPredicates::edge(const llvm::BasicBlock *, const llvm::BasicBlock *) const { unimplemented("pred: PathPredicates::edge"); }
llvm::Value *PathPredicates::flag(LoweringContext &, const Pred &) { unimplemented("pred: PathPredicates::flag"); }
void lowerBranch(LoweringContext &, llvm::BranchInst &) { unimplemented("pred: lowerBranch"); }
llvm::Value *lowerMerge(LoweringContext &, llvm::PHINode &) { unimplemented("pred: lowerMerge"); }
llvm::Value *lowerSelect(LoweringContext &, llvm::SelectInst &) { unimplemented("pred: lowerSelect"); }
llvm::Value *selectChain(LoweringContext &, llvm::ArrayRef<std::pair<Pred, Operand>>, RailType) { unimplemented("pred: selectChain"); }
void lowerPhase(LoweringContext &, llvm::CallInst &) { unimplemented("pred: lowerPhase"); }
} // namespace cq
