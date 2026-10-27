// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include "cq/Lowering.h"
#include "cq/Taint.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"

// Memory.h  (rules 20, 22)
namespace cq::mem {
void lowerSlotLoad(LoweringContext &, llvm::LoadInst &);          // mem-slots
void lowerSlotStore(LoweringContext &, llvm::StoreInst &);        // mem-slots
void allocateSlots(LoweringContext &, llvm::Instruction &site);   // mem-slots
void endSlotLifetime(LoweringContext &, ObjectId, llvm::Instruction *at);  // mem-slots
void lowerQromLoad(LoweringContext &, llvm::LoadInst &);          // mem-qrom
void lowerQramLoad(LoweringContext &, llvm::LoadInst &);          // mem-qram
void lowerQramStore(LoweringContext &, llvm::StoreInst &);        // mem-qram
void allocateQram(LoweringContext &, llvm::Instruction &site);    // mem-qram
void endQramLifetime(LoweringContext &, ObjectId, llvm::Instruction *at);  // mem-qram
void lowerMemIntrinsic(LoweringContext &, llvm::MemIntrinsic &);  // mem-qram
}
