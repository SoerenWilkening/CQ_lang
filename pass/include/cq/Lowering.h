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
// cq-9w75 (CR rule 14 at f981c89: an affine induction is not carried; a walked pointer with a classical
// start indexes a slot array at the classical index start + j*step). A classical pointer header phi of a
// K-loop into slot, QRAM or fat-pointer memory, walked by a constant byte step from a loop-invariant
// start: in trip j it addresses start + j*step bytes. The loop module registers it and binds the phi to
// the constant i64 j per trip (such a pointer is never an operand of its own: memory re-derives every
// address, rules 20, 21); mem-slots and fatptr read an address through it.
struct WalkedPtr { const llvm::Value *start; int64_t step; };
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
  void bindWalkedPointer(const llvm::PHINode *, WalkedPtr);      // cq-9w75
  const WalkedPtr *walkedPointer(const llvm::Value *) const;     // nullptr unless registered
  unsigned K(const llvm::Loop *) const;
  unsigned K(const llvm::Function &) const;   // F's K, F may be a declaration (rule 27 trailing K)
  // K1: storage owned by module spine.
private:
  struct Impl; std::shared_ptr<Impl> impl;
};
void construct(llvm::Module &, const TaintInfo &, const Specialization &, const loops::KOptions &);
void lowerOpcode(LoweringContext &, llvm::Instruction &);
void lowerInstruction(LoweringContext &, llvm::Instruction &);   // the spine's dispatch of one non-phi, non-terminator
void lowerInstruction(LoweringContext &, llvm::Instruction &, llvm::Value *tripFlag);   // cq-99f7: under a loop trip's i1 rail
void lowerTheta(LoweringContext &, llvm::CallInst &);
void lowerMeasure(LoweringContext &, llvm::CallInst &);
}
