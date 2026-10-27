// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include "cq/Lowering.h"
#include "cq/Taint.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Instructions.h"

// FatPtr.h  (rule 21)
namespace cq::fatptr {
struct FatPtr { llvm::Value *tag; bool tagQuantum; llvm::Value *idx; bool idxQuantum;
                llvm::SmallVector<ObjectId, 4> objects; };
struct Triple { llvm::Value *object, *tag, *idx, *cellCount; };
FatPtr lower(LoweringContext &, const llvm::Value *ptr);
void lowerLoad(LoweringContext &, llvm::LoadInst &);
void lowerStore(LoweringContext &, llvm::StoreInst &);
llvm::Value *lowerCompare(LoweringContext &, llvm::ICmpInst &);
void lowerPtrToInt(LoweringContext &, llvm::Instruction &);
void lowerIntToPtr(LoweringContext &, llvm::Instruction &);
Triple passAcrossCall(LoweringContext &, const llvm::Value *ptr);
}
