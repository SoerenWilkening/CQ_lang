// Module-internal interface of mem-qrom for fatptr (both stream C's, not frozen): rule 21's per-object
// load of a fat pointer whose provenance holds classical memory at a quantum idx (a QROM, rule 20).
#pragma once

#include "cq/Common.h"
#include "cq/Lowering.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"

namespace cq::mem {
// cq_template_qrom_load_<W>(root, n, idx): element i at root + i * size(ty), idx a rail (the logical
// cell index), n the cells of root's object from root to its end (a static object only). Recorded and
// returned as a fresh rail.
llvm::Value *qromLoadAt(LoweringContext &, const llvm::Value *root, Operand idx, llvm::Type *ty,
                        const llvm::Instruction &at);
}
