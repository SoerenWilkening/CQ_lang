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
// P1 (cq-arch 2026-11-01, CR rule 21, §1.4; 190, 191): at a clone's entry, pointer formal `formal` (T4 abi
// Triple or TripleCount) is bound to the clone's parameters object (ptr, or the i32 bus of a Qram pointee),
// tag, idx (handles iff their mask digits are 1) and cellCount (nullptr unless TripleCount). lower() of the
// formal and of every pointer derived from it then yields the bound fat pointer; a Slot-pointee load is
// checked against cellCount and reads the clone's shared |0> seed beyond it (190). Consumer: spine
// Construct clone entry.
void bindFormal(LoweringContext &, const llvm::Argument &formal, llvm::Value *object, Operand tag, Operand idx,
                llvm::Value *cellCount);
}
