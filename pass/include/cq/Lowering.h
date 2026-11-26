// Frozen interface (cq-arch, with freeze beads cq-k1w, cq-sml, cq-ofn6 and cq-99f7). Changes only under cq-arch's freeze rule.
#pragma once

#include <memory>
#include <vector>

#include "cq/Abi.h"
#include "cq/Common.h"
#include "cq/Taint.h"
#include "cq/Uncompute.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

namespace llvm { class Loop; }

// Lowering.h  (spine)
namespace cq {
class PathPredicates; struct Pred;
namespace loops { struct KOptions; }
class LoweringContext {
public:
  llvm::Module &M; const TaintInfo &T; const Specialization &S;
  LoweringContext(llvm::Module &, const TaintInfo &, const Specialization &, const loops::KOptions &);
  llvm::Function &out(); llvm::IRBuilder<> &B();
  Operand operand(const llvm::Value *orig);
  llvm::Value *rail(const llvm::Value *orig);                     // internalError if classical
  // cq-0hhk: the rail a quantum switch's case atom reads for its scrutinee: the scrutinee's value at
  // the switch (a copy taken before an in-place rotation of its rail inside the switch's region), else
  // rail(scrutinee).
  llvm::Value *switchRail(const llvm::Value *scrutinee);
  llvm::SmallVector<Operand, 4> fields(const llvm::Value *orig);
  void bind(const llvm::Value *orig, llvm::Value *v);
  void bindFields(const llvm::Value *orig, llvm::ArrayRef<Operand>);
  void rebind(const llvm::Value *orig, llvm::ArrayRef<Operand>);   // replaces a binding; internalError if unbound
  // cq-mgkr: has orig a value in the new IR yet (a constant always)?
  bool bound(const llvm::Value *orig) const;
  // cq-dcw0i: is br a classical guard's branch (rule 8: a block's classical condition, its false edge the skip)?
  bool guardBranch(const llvm::Instruction *br) const;
  // cq-mgkr (rule 9 at a unit's join, CR rule 14): v is P's incoming on an edge whose predicate is `edge`,
  // which a loop unit binding P could not read (lowered after the loop): the walker selects v in for P
  // where `edge` holds when it lowers P's block, over the unit's binding elsewhere.
  void addJoinArm(const llvm::PHINode *P, const Pred &edge, const llvm::Value *v);
  // cq-l56v: removes and returns P's join arms (a loop module walking a trip joins a nested unit's phis).
  std::vector<std::pair<Pred, const llvm::Value *>> takeJoinArms(const llvm::PHINode *P);
  llvm::BasicBlock *block(const llvm::BasicBlock *orig);
  llvm::Value *emitTemplate(const abi::TemplateSpec &, llvm::ArrayRef<Operand>, const llvm::Value *orig = nullptr);
  llvm::CallInst *emitCore(const abi::CoreSpec &, llvm::ArrayRef<llvm::Value *>);
  PathPredicates &preds(); Uncompute &unc();
  const Pred &currentPredicate() const;   // quantum part of the current block's predicate
  llvm::Value *currentFlag();             // its flag rail, nullptr when classical-true
  // cq-8un4: the innermost loop of the original function whose lowering the spine dispatched as a unit
  // (loops::lowerClassical / loops::lowerCutoff) and that is running now; nullptr outside any.
  const llvm::Loop *loopUnit() const;
  unsigned beginGateLog(); std::vector<llvm::CallInst *> endGateLog(unsigned);
  unsigned K(const llvm::Loop *) const;
  unsigned K(const llvm::Function &) const;   // F's K, F may be a declaration (rule 27 trailing K)
  // K1: storage owned by module spine.
private:
  struct Impl; std::shared_ptr<Impl> impl;
};
void construct(llvm::Module &, const TaintInfo &, const Specialization &, const loops::KOptions &);
// CR rule 6, in-place update (cq-2h7xa): after every construction, each clean-up of a plain add/xor's dead operand that
// Uncompute placed right after the update becomes one core gate on the old rail; the !cq.r6 tags are dropped.
void fuseInPlaceUpdates(llvm::Module &);
void lowerOpcode(LoweringContext &, llvm::Instruction &);
void lowerInstruction(LoweringContext &, llvm::Instruction &);   // the spine's dispatch of one non-phi, non-terminator
void lowerInstruction(LoweringContext &, llvm::Instruction &, llvm::Value *tripFlag);   // cq-99f7: under a loop trip's i1 rail
// The same where tripFlag implies `seedPred`, the predicate of the loop's seed (rule 14: a K-loop's chain starts at the
// arm flag): a block predicate seedPred implies adds nothing, and the control is the trip rail itself (55: a_j).
void lowerInstruction(LoweringContext &, llvm::Instruction &, llvm::Value *tripFlag, const Pred *seedPred);
// cq-s7c4: lowerInstruction(ctx, I) for a quantum i1 that a K-loop reads whole as its trip's exit atom: I is
// computed as data (its rail bound) even where pred factored its branch's condition (`c || q`, rule 8).
void lowerConditionAsData(LoweringContext &, llvm::Instruction &);
void lowerTheta(LoweringContext &, llvm::CallInst &);
void lowerMeasure(LoweringContext &, llvm::CallInst &);
}
