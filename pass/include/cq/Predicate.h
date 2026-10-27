// Frozen interface (cq-arch, with owner amendment A3 of 2026-10-27). Changes only under cq-arch's
// freeze rule.
#pragma once

#include <utility>

#include "cq/Common.h"
#include "cq/Lowering.h"
#include "cq/Taint.h"
#include "llvm/ADT/APInt.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instructions.h"

namespace llvm { class LoopInfo; }

// Predicate.h  (rules 8, 9, 12)
namespace cq {
struct Pred {   // canonical Boolean function over condition atoms
  static Pred top(); static Pred bottom(); static Pred atom(const llvm::Value *cond);
  // A3: a switch case atom `scrutinee == v` (rule 13), no i1 Value in the input IR.
  static Pred eqAtom(const llvm::Value *scrutinee, const llvm::APInt &v);
  Pred operator&(const Pred &) const; Pred operator|(const Pred &) const; Pred operator!() const;
  bool isTop() const; bool isBottom() const;
  Pred quantumPart(const TaintInfo &, const Specialization &) const;
  bool isClassical(const TaintInfo &, const Specialization &) const;
};
struct EdgePreds { llvm::SmallVector<std::pair<const llvm::BasicBlock *, Pred>, 4> succ; };
class PathPredicates {
public:
  void compute(llvm::Function &, const llvm::LoopInfo &, const TaintInfo &, const Specialization &,
               llvm::Value *entryFlag /* _ctl clones */);
  const Pred &block(const llvm::BasicBlock *) const;
  const Pred &edge(const llvm::BasicBlock *from, const llvm::BasicBlock *to) const;
  llvm::Value *flag(LoweringContext &, const Pred &);
};
void lowerBranch(LoweringContext &, llvm::BranchInst &);
llvm::Value *lowerMerge(LoweringContext &, llvm::PHINode &);
llvm::Value *lowerSelect(LoweringContext &, llvm::SelectInst &);
llvm::Value *selectChain(LoweringContext &, llvm::ArrayRef<std::pair<Pred, Operand>> arms, RailType);
void lowerPhase(LoweringContext &, llvm::CallInst &cqPhi);
}
