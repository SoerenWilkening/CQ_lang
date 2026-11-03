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
// Rule 21 (P1): in a clone, the triple a host- or slot-pointee triple formal came with (a classical tag and
// idx): the caller's object (its host object, or its handle cells), the tag, the i32 idx, the i32 cell count
// (null for a formal without one) and the formal's cell size in bytes. False when formal is no such bound formal.
struct FormalTriple {
  llvm::Value *object = nullptr, *tag = nullptr, *idx = nullptr, *cellCount = nullptr;
  uint64_t cell = 0;
};
bool boundTriple(LoweringContext &, const llvm::Value *formal, FormalTriple &out);
// Rule 21 with rule 20: the triple of a classical pointer whose place in its object this function does not hold
// statically: the object starting at the pointer (its root number the tag, idx 0), its cell count the extent from
// the pointer on when it derives from one allocation, else 0 (unknown extent, n = 0).
void ownPlaceTriple(LoweringContext &, const llvm::Value *ptr, FormalTriple &out);
// Rule 21 (P1): a QRAM triple formal with a classical tag and idx is, as a classical pointer, its object's address
// in the QRAM address space (the caller's object's base, qramObjectBase of the formal's object, plus idx cells):
// what a classical walk, compare, ptrtoint or return of it reads. Null when the formal is no such one. And the
// formal's classical i32 idx.
llvm::Value *boundQramAddress(LoweringContext &, const llvm::Argument &formal);
llvm::Value *boundFormalIdx(LoweringContext &, const llvm::Argument &formal);
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
//
// cq-h8y6 (CR rules 14, 21): the EXIT VALUE of a pointer computed in a loop with a quantum exit (a K-loop, or a
// case-3 loop) and read after it depends on which trip exited, so it is a fat pointer (rule 21) whose fields are
// capture rails: each trip's (tag, idx) selected in where that trip exits. `as` is the value after the loop (the
// loop value itself, or a phi of the loop's continuation merging several values over its exit edges and skip
// edges). exitShape records its shape before the first fields are read: the roots of every value it merges and
// NULL (its value where no trip exits: the cutoff ran out, CR rule 14's 0), all loop-invariant (a classical pointer
// into classical memory that the loop redefines per trip, `inLoop` naming the loop's blocks, is its loop-invariant
// base moved by the trip's byte offset), in cells of the greatest common divisor of theirs. exitFields gives one
// merged value's fields at that shape (tag an i32, idx an i64), at the builder: in a trip for a loop value, where
// the edge leaves for a value from outside the loop. After the loop, `as` is bound to its two fields (tag, idx)
// and bindExit marks it: every derivation after the loop (a GEP of it, a phi or select reading it, an access, a
// compare, ptrtoint) reads that fat pointer. isExitPointer(p): p is such a value, or an address computed from one
// by GEPs and casts.
void exitShape(LoweringContext &, const llvm::Value *as, llvm::ArrayRef<const llvm::Value *> values,
               llvm::function_ref<bool(const llvm::BasicBlock *)> inLoop);
std::pair<Operand, Operand> exitFields(LoweringContext &, const llvm::Value *ptr,
                                       llvm::function_ref<bool(const llvm::BasicBlock *)> inLoop,
                                       const llvm::Value *as);
void bindExit(LoweringContext &, const llvm::Value *as);
bool isExitPointer(LoweringContext &, const llvm::Value *p);
// Before a loop is lowered again (a nested loop, once per outer trip): its values are the trip's own until its
// exit binds them again.
void forgetExits(LoweringContext &, llvm::function_ref<bool(const llvm::BasicBlock *)> inLoop);
}
