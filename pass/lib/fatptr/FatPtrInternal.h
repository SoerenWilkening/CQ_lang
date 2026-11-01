// Module-internal interface of fatptr for mem-qram (both stream C's, not frozen): pointers held in a
// QRAM of pointers (rule 21, 88).
#pragma once

#include <utility>

#include "cq/Common.h"
#include "cq/Lowering.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"

namespace cq::fatptr {
// The fat pointer (tag, idx) of ptr as two i32 operands (each a rail or a classical i32): what a QRAM
// of pointers stores. The tag is ptr's root number in its function's object table; the idx a cell index.
std::pair<Operand, Operand> storedFields(LoweringContext &, const llvm::Value *ptr);
// Rule 21 (85): the fat pointer a clone returns as its two i32 fields (tag, idx) in the caller's table (its
// roots are triple formals onto host or slot objects, whose tag is the caller's, and NULL, tag 0).
std::pair<Operand, Operand> resultFields(LoweringContext &, const llvm::ReturnInst &ret);
// Rule 22 with a quantum source pointer (90): the n cells of cellTy at the fat pointer src, a classical
// constant idx over classical host roots. Cell j of root r is a host load at byte (idx * cell + j * size)
// only when j * size < bound(r), the length's upper bound in bytes on the paths that select r (a host
// byte is never speculated past it); the roots reaching cell j merge by select on tag == k, the first
// root innermost (rule 21's load). A cell no root reaches is an internal error (n is the largest bound).
llvm::SmallVector<Operand, 8> loadHostCells(LoweringContext &, const llvm::Value *src, llvm::Type *cellTy,
                                            uint64_t n, llvm::function_ref<uint64_t(const llvm::Value *root)> bound,
                                            const llvm::Instruction &at);
// cq-oocu (107): the cell size of the fat pointer ptr (0 while its idx is the constant 0 and no access fixed
// it); and, in a clone, the caller's handle cells a Slot-pointee triple formal A is bound to (nullptr when A is
// no such bound formal).
uint64_t storedCell(LoweringContext &, const llvm::Value *ptr);
llvm::Value *boundSlotObject(LoweringContext &, const llvm::Argument &A);
// A pointer loaded from a QRAM of pointers (or through a fat pointer over such QRAMs) is bound by its
// loader with ctx.bindFields(load, {tag, idx}), two i32 rails; fatptr's derivation reads them back.
}
