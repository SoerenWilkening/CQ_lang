// Module-internal interface of mem-qrom for fatptr (both stream C's, not frozen): rule 21's per-object
// load of a fat pointer whose provenance holds classical memory at a quantum idx (a QROM, rule 20).
#pragma once

#include "cq/Common.h"
#include "cq/Lowering.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"

namespace cq::mem {
// cq_template_qrom_load_<W>(base, n, idx'): idx a rail of idxBits (the logical cell index relative to
// root, read with sext when idxSext); through a signed idx, a root inside its static object reaches the k
// cells before it at negative indices (cq-b244), so the table starts at base = root - k cells and
// idx' = idx + k (widened to cover the n cells); n the cells of root's object from base to its end. Recorded and returned as a fresh
// rail. Memory of unknown extent: every cell idx can reach (from -2^(W-1) when signed). ty is a scalar; a
// composite is split by the caller per leaf: leafOff the leaf's byte offset in the cell, cellBytes the cell's
// size (0: ty's alloc size).
llvm::Value *qromLoadAt(LoweringContext &, const llvm::Value *root, Operand idx, unsigned idxBits, bool idxSext,
                        llvm::Type *ty, const llvm::Instruction &at, uint64_t leafOff = 0, uint64_t cellBytes = 0);
}
