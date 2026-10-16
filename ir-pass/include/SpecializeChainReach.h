// SpecializeChainReach.h — which parameters a lifted callee's return passes
// through (chainReachSlots) and whether its body is effect-free
// (consumableBody); split out of SpecializeTailPlan.h (400-line rule). bd
// test_C_libtooling-r2j3.37.1/.3/.4.
#ifndef CQ_IRPASS_SPECIALIZE_CHAIN_REACH_H_
#define CQ_IRPASS_SPECIALIZE_CHAIN_REACH_H_

#include "InPlaceQQ.h"  // isQQStemOpcode

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"

#include <cstdint>

namespace cq {
namespace tailhoist {

using namespace llvm;

// bd r2j3.37.1 R11 r1 (rL1C-F2 / rL1A-F2): may a consuming clone stand for `F`?
// Its body applies ONLY the return chain, and each source clone re-runs `F`; so
// `F` must have no effect but its return value: no cycle (termination), no
// instruction that may have a side effect, and every call either side-effect
// free itself or to a defined callee that satisfies this too (the hand IR
// `-O1`'s attribute inference never saw). Asked at candidate build; a body that
// fails is not consumed (loud when owed).
inline bool consumableBody(const Function &F,
                           SmallPtrSetImpl<const Function *> &Stack) {
  if (F.isDeclaration() || !Stack.insert(&F).second)
    return false;
  SmallVector<std::pair<const BasicBlock *, const BasicBlock *>, 2> Back;
  FindFunctionBackedges(F, Back);
  bool OK = Back.empty();
  for (const Instruction &I : instructions(F)) {
    if (!OK || !I.mayHaveSideEffects())
      continue;
    const auto *CI = dyn_cast<CallInst>(&I);
    const Function *G = CI ? CI->getCalledFunction() : nullptr;
    OK = G && !G->isIntrinsic() && consumableBody(*G, Stack);
  }
  Stack.erase(&F);
  return OK;
}

// bd r2j3.37.1 R11 r1 (rL1B-F1): the parameters `F`'s returned value reaches
// through xor/add/sub (the opcodes the in-place rounds convert) and through
// EVERY arm of the muxes a classical branch makes of them (select, φ), across nested
// calls whose own return reaches the parameter they bind (bit i = parameter i).
// A PROPERTY OF THE SITE, independent of whether a plan exists: such a slot,
// filled by a dead user register beside a kept result, is OWED in place — built
// when the plan covers it, LOUD otherwise. Not through a cast: `(int)t ^ a`
// reads `t` through a widening, which no in-place gate overwrites (as for the
// inlined op, whose QQ round never sees `t` as an operand).
inline uint64_t chainReachSlots(const Function &F,
                                SmallPtrSetImpl<const Function *> &Stack);
// Memoised per value (`Memo`; a value on the current walk reads 0, so a φ cycle
// contributes nothing): the slots `V` passes through on every path.
inline uint64_t chainReachValue(const Value *V,
                                DenseMap<const Value *, uint64_t> &Memo,
                                SmallPtrSetImpl<const Function *> &Stack) {
  if (auto It = Memo.find(V); It != Memo.end())
    return It->second;
  Memo[V] = 0;  // in progress
  uint64_t M = 0;
  if (const auto *A = dyn_cast<Argument>(V)) {
    M = A->getArgNo() < 64 ? uint64_t(1) << A->getArgNo() : 0;
  } else if (const auto *BO = dyn_cast<BinaryOperator>(V);
             BO && isQQStemOpcode(BO->getOpcode()) &&
             BO->getType()->isIntegerTy() &&
             BO->getType()->getIntegerBitWidth() <= 64) {
    M = chainReachValue(BO->getOperand(0), Memo, Stack) |
        chainReachValue(BO->getOperand(1), Memo, Stack);
  } else if (const auto *SI = dyn_cast<SelectInst>(V)) {
    // bd r2j3.37.3: a mux of chains: the parameter must pass through EVERY arm
    // (an arm returning something else is no permutation of it).
    M = chainReachValue(SI->getTrueValue(), Memo, Stack) &
        chainReachValue(SI->getFalseValue(), Memo, Stack);
  } else if (const auto *PN = dyn_cast<PHINode>(V)) {
    M = PN->getNumIncomingValues() ? ~uint64_t(0) : 0;
    for (const Value *In : PN->incoming_values())
      M &= chainReachValue(In, Memo, Stack);
  } else if (const auto *CI = dyn_cast<CallInst>(V)) {
    const Function *H = CI->getCalledFunction();
    if (H && !H->isIntrinsic() && !H->isDeclaration() &&
        CI->getFunctionType() == H->getFunctionType()) {
      const uint64_t Inner = chainReachSlots(*H, Stack);
      for (unsigned J = 0; J < CI->arg_size() && J < 64; ++J)
        if (Inner >> J & 1)
          M |= chainReachValue(CI->getArgOperand(J), Memo, Stack);
    }
  }
  Memo[V] = M;
  return M;
}
inline uint64_t chainReachSlots(const Function &F,
                                SmallPtrSetImpl<const Function *> &Stack) {
  if (F.isDeclaration() || !Stack.insert(&F).second)
    return 0;
  // EVERY return must pass the parameter through: a path returning something
  // else (`return 10;`) makes the result no permutation of it, so no in-place
  // form exists and keeping the old register is the program (as inlined).
  uint64_t M = ~uint64_t(0);
  bool Any = false;
  DenseMap<const Value *, uint64_t> Memo;
  for (const BasicBlock &BB : F)
    if (const auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
      if (const Value *V = R->getReturnValue()) {
        M &= chainReachValue(V, Memo, Stack);
        Any = true;
      }
  Stack.erase(&F);
  return Any ? M : 0;
}


}  // namespace tailhoist
}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_CHAIN_REACH_H_
