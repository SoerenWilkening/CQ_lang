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
// cq-a63l (rule 16 fields over rule 21): the fat pointer ptr's address as an i64 (ptrtoint's value: the root's
// base plus idx * cell, a rail when the tag or idx is one), at the builder; and its constant byte offset into
// its roots (idx * cell), when idx is a classical constant.
Operand addressOf(LoweringContext &, const llvm::Value *ptr);
std::optional<int64_t> constantByteOffset(LoweringContext &, const llvm::Value *ptr);
llvm::SmallVector<const llvm::Value *, 4> rootsOf(LoweringContext &, const llvm::Value *ptr);
llvm::Value *boundSlotObject(LoweringContext &, const llvm::Argument &A);
// M7 (cq-g1ty, CR rules 6, 18, 20, 21; 129): fat pointers over whole local slot objects, a quantum select
// tree of their allocas (each at cell 0).
//  - writesSlotCell (consumer mem-slots sourceOf, structural): X writes the cell at byte `byte` (size bytes)
//    of slot root `root`: a store through such a pointer naming root, or a clone call handed one whose callee
//    applies a read-modify-write through the formal (the cell is written on every path: (tag == k) ? new : old).
//  - slotTableActual: ptr is such a pointer (passAcrossCall then builds the object table).
//  - afterSlotTableCall (consumer calls, right after the clone call fwd standing for orig, formal argNo): the
//    handles the clone left in each object's cell (the call's slot results), the dead old cells cleaned by
//    rule 6 (emitted by finishSlotTableCall). A clone that only loads: nothing written, the old cells noted as read by the call.
bool writesSlotCell(LoweringContext &, const llvm::Instruction &X, const llvm::Value *root, int64_t byte,
                    uint64_t size);
bool slotTableActual(LoweringContext &, const llvm::Value *ptr);
llvm::SmallVector<llvm::Value *, 4> afterSlotTableCall(LoweringContext &, const llvm::CallBase &orig, unsigned argNo,
                                                       const Specialization &callee, llvm::CallInst *fwd);
// Right after calls' recordCall of fwd: the rule 6 clean-ups afterSlotTableCall deferred (they read the call's
// slot results). A call with none: nothing.
void finishSlotTableCall(LoweringContext &, llvm::CallInst *fwd);
// A pointer loaded from a QRAM of pointers (or through a fat pointer over such QRAMs) is bound by its
// loader with ctx.bindFields(load, {tag, idx}), two i32 rails; fatptr's derivation reads them back.
}
