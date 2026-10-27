// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include "cq/Lowering.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"

// Effects.h  (rules 16, 17, 23, 24)
namespace cq::tape   { void lowerHostEffect(LoweringContext &, llvm::CallBase &);
                       void lowerNoreturn(LoweringContext &, llvm::CallBase &); }
namespace cq::invert { void lowerRegion(LoweringContext &, llvm::CallInst &begin, llvm::CallInst &end); }
namespace cq::fenv   { void lowerConstrained(LoweringContext &, llvm::CallBase &);
                       void lowerFenvCall(LoweringContext &, llvm::CallBase &); }
namespace cq::conc   { void lowerAtomic(LoweringContext &, llvm::Instruction &);
                       void lowerVolatile(LoweringContext &, llvm::Instruction &);
                       void lowerThreadCall(LoweringContext &, llvm::CallBase &);
                       void lowerSetjmp(LoweringContext &, llvm::CallBase &);
                       void lowerLongjmp(LoweringContext &, llvm::CallBase &); }
