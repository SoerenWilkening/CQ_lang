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
// M4 (cq-arch amendment, 2026-11-01). mem-slots (CR rule 24, 94): atomicrmw or cmpxchg on a slot cell is
// the plain op single-threaded: read the cell, the op as templates (rmw: op(old, v); cmpxchg:
// f = icmp eq(old, cmp), new = select(f, v, old)), the new rail stored into the cell; binds I (rmw: old;
// cmpxchg: the fields {old, f}).
void lowerSlotAtomic(LoweringContext &, llvm::Instruction &rmwOrCmpxchg);
// M4. mem-slots (CR rule 16, 99): the contents of n consecutive cells of type cellTy of the slot object at
// ptr, as they are at `at` (a call the caller lowers in place of the host call): a handle, or a classical
// value for a cell no handle reaches. Nothing is written; reading does not change roles.
llvm::SmallVector<Operand, 8> readSlotCells(LoweringContext &, const llvm::Value *ptr, llvm::Type *cellTy,
                                            uint64_t n, llvm::Instruction &at);
void allocateSlots(LoweringContext &, llvm::Instruction &site);   // mem-slots
void endSlotLifetime(LoweringContext &, ObjectId, llvm::Instruction *at);  // mem-slots
void lowerQromLoad(LoweringContext &, llvm::LoadInst &);          // mem-qrom
void lowerQramLoad(LoweringContext &, llvm::LoadInst &);          // mem-qram
void lowerQramStore(LoweringContext &, llvm::StoreInst &);        // mem-qram
void allocateQram(LoweringContext &, llvm::Instruction &site);    // mem-qram
void endQramLifetime(LoweringContext &, ObjectId, llvm::Instruction *at);  // mem-qram
void lowerMemIntrinsic(LoweringContext &, llvm::MemIntrinsic &);  // mem-qram
}
