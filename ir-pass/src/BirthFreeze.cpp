// BirthFreeze.cpp — see header. Clause (a) of the record-freeze invariant.

#include "BirthFreeze.h"

#include "ChainWalk.h"      // isTemplateProducer
#include "CloneProducer.h"  // isCloneProducer (bd p3kd.13)
#include "DagTraversal.h"   // DataDag

#include "llvm/IR/Constant.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

bool railBornZero(const Value *R, const TaintSet &taint) {
  const auto *CI = dyn_cast<CallInst>(R);
  if (!CI)
    return false;  // a phi / select / argument root: born as another rail's state
  if (isTemplateProducer(CI))
    return true;  // a fresh |0⟩ rail the template computes into
  // bd p3kd.13: a clone producer's result is the wrap's `cqq.out =
  // cqrt_alloc_<W>(0)`, copied into from a |0⟩ birth (BennettWrap.cpp (b)/(c)).
  if (isCloneProducer(CI, taint))
    return true;
  const Function *Callee = CI->getCalledFunction();
  if (!Callee || !Callee->getName().starts_with("cqrt_alloc_") ||
      CI->arg_size() != 1)
    return false;
  const auto *Seed = dyn_cast<Constant>(CI->getArgOperand(0));
  return Seed && Seed->isNullValue();
}

void freezeUnprovenBirths(DataDag &D, const TaintSet &taint) {
  for (Value *R : D.Rails)
    if (!railBornZero(R, taint) && !isQramArrayHandle(R))
      D.FrozenRails.insert(R);
}

}  // namespace cq
