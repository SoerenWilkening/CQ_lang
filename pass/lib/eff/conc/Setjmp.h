// Module eff-conc (CR rule 24, 101): the escaped-flag construction of a longjmp under a quantum predicate.
// Private to eff-conc; spine (the walker's diamond and the clone's return) and calls (the clone's ABI and
// its call) consume it. Contract at the top of Setjmp.cpp.
#pragma once

#include <optional>

#include "cq/Lowering.h"
#include "cq/Taint.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

namespace cq::conc {

// The setjmp diamond: head ends in br (icmp eq|ne (setjmp(jb), 0)), normal (the first return's arm) is
// a block of its own whose one call of an escaping clone is `call`, join is reached from normal and
// directly from head (setjmp's second return).
struct SetjmpDiamond {
  const llvm::CallBase *setjmp;
  const llvm::ICmpInst *cmp;
  const llvm::BasicBlock *head, *normal, *join;
  const llvm::CallBase *call;
};

// Does the clone S escape: a longjmp in its body under a quantum predicate (calls::Class::Longjmp)?
// Its result is then {result, escaped} ({escaped} alone, an i32 handle, for a void clone).
bool cloneEscapes(const TaintInfo &, const Specialization &);
// nullopt when head does not end in a test of a returns_twice call's result; a test of one in any
// other shape than SetjmpDiamond's is unimplemented.
std::optional<SetjmpDiamond> setjmpDiamond(LoweringContext &, const llvm::BasicBlock &head);
// Is CB the call of a setjmp diamond's normal arm?
bool isSetjmpArmCall(LoweringContext &, const llvm::CallBase &CB);
// The escaped-flag rail of a lowered call of an escaping clone (calls records it, the walker's join reads
// it); nullptr when none was recorded for CB in this output function.
void noteEscapedOut(LoweringContext &, const llvm::CallBase &CB, llvm::Value *rail);
llvm::Value *escapedOut(LoweringContext &, const llvm::CallBase &CB);
// In an escaping clone: the copied-out escaped rail lowerLongjmp made (Role::Result), nullptr before it.
llvm::Value *cloneEscapedFlag(LoweringContext &);

} // namespace cq::conc
