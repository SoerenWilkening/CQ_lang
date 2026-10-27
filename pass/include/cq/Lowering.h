// Frozen interface (cq-arch, with freeze bead cq-k1w). Changes only under cq-arch's freeze rule.
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
class LoweringContext {
public:
  llvm::Module &M; const TaintInfo &T; const Specialization &S;
  LoweringContext(llvm::Module &, const TaintInfo &, const Specialization &);
  llvm::Function &out(); llvm::IRBuilder<> &B();
  Operand operand(const llvm::Value *orig);
  llvm::Value *rail(const llvm::Value *orig);                     // internalError if classical
  llvm::SmallVector<Operand, 4> fields(const llvm::Value *orig);
  void bind(const llvm::Value *orig, llvm::Value *v);
  void bindFields(const llvm::Value *orig, llvm::ArrayRef<Operand>);
  llvm::BasicBlock *block(const llvm::BasicBlock *orig);
  llvm::Value *emitTemplate(const abi::TemplateSpec &, llvm::ArrayRef<Operand>, const llvm::Value *orig = nullptr);
  llvm::CallInst *emitCore(const abi::CoreSpec &, llvm::ArrayRef<llvm::Value *>);
  PathPredicates &preds(); Uncompute &unc();
  const Pred &currentPredicate() const;   // quantum part of the current block's predicate
  llvm::Value *currentFlag();             // its flag rail, nullptr when classical-true
  unsigned beginGateLog(); std::vector<llvm::CallInst *> endGateLog(unsigned);
  unsigned K(const llvm::Loop *) const;
  // K1: storage owned by module spine.
private:
  struct Impl; std::shared_ptr<Impl> impl;
};
void construct(llvm::Module &, const TaintInfo &, const Specialization &);
void lowerOpcode(LoweringContext &, llvm::Instruction &);
void lowerTheta(LoweringContext &, llvm::CallInst &);
void lowerMeasure(LoweringContext &, llvm::CallInst &);
}
