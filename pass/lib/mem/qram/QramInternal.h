// Module-internal interface of mem-qram for fatptr (both stream C's, not frozen): rule 21's per-object
// accesses of a fat pointer whose provenance holds QRAM objects.
#pragma once

#include "cq/Common.h"
#include "cq/Lowering.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"

namespace cq::mem {
// True when root (an original pointer root: alloca, global, heap call, realloc result) is a QRAM site
// this output function has allocated (or a global QRAM).
bool isQramRoot(LoweringContext &, const llvm::Value *root);
// The element size of the QRAM object at root (cell index 1 = elemBytes bytes).
uint64_t qramElemBytes(LoweringContext &, const llvm::Value *root, const llvm::Instruction &at);
// One load of type ty at cell idx of the QRAM at root (column at offset 0), unguarded: a quantum idx
// is the logical index rail, a classical one an i64 cell index. Returns the fresh recorded rail.
llvm::Value *qramLoadAt(LoweringContext &, const llvm::Value *root, Operand idx, llvm::Type *ty,
                        const llvm::Instruction &at);
// One store of the handle v (type ty) at cell idx of the QRAM at root, _controlled on flag when not null.
void qramStoreAt(LoweringContext &, const llvm::Value *root, Operand idx, llvm::Type *ty, llvm::Value *v,
                 llvm::Value *flag, const llvm::Instruction &at);
}
