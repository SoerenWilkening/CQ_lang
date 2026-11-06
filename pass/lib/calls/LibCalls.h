// Library calls that are memory accesses in disguise, rewritten before the first taint (rules 16, 22, 24). The pass and the
// C oracle run the same rewrite, so taint sees the same program on both sides. Contract at the top of LibCalls.cpp.
#pragma once

#include "llvm/IR/Module.h"

namespace llvm {
class CallBase;
}

namespace cq::calls {

// Returns whether the module changed; a compare-exchange's diamond is a CFG change.
bool canonicalizeLibCalls(llvm::Module &M);

// The source period of a `memset_pattern` written as `llvm.memcpy`: byte j of the destination is byte j % period of the
// source. 0 for every other call.
unsigned patternPeriod(const llvm::CallBase &CB);

// A tagged `llvm.memcpy` that stayed the instruction (a host-resident destination, rule 22) is the call it was again.
void restoreHostPatterns(llvm::Module &M);

} // namespace cq::calls
