// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include "cq/Lowering.h"
#include "llvm/IR/Instructions.h"

// Rotation.h  (rules 10, 11, 15)
namespace cq::rot {
void lowerControlledTheta(LoweringContext &, llvm::CallInst &cqTheta, llvm::Value *flag);
void lowerStatePrepMerge(LoweringContext &, llvm::PHINode &);
void lowerQuantumAngleTheta(LoweringContext &, llvm::CallInst &cqTheta, llvm::Value *flagOrNull);
void lowerQuantumAnglePhase(LoweringContext &, llvm::CallInst &cqPhi, llvm::Value *flagOrNull);
}
