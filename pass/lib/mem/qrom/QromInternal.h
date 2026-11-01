// Module-internal interface of mem-qrom for fatptr (both stream C's, not frozen): rule 21's per-object
// load of a fat pointer whose provenance holds classical memory at a quantum idx (a QROM, rule 20).
#pragma once

#include "cq/Common.h"
#include "cq/Lowering.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"

namespace cq::mem {
// cq_template_qrom_load_<W>(root, n, idx): element i at root + i * size(ty), idx a rail (the logical
// cell index), n the cells of root's object from root to its end (a static object only). Recorded and
// returned as a fresh rail.
llvm::Value *qromLoadAt(LoweringContext &, const llvm::Value *root, Operand idx, llvm::Type *ty,
                        const llvm::Instruction &at);
}

// Rule 19 (97). Proposed for Memory.h (consumer calls::lowerIndirect); declared here until main moves it.
namespace cq::mem {
// The candidates of a function pointer that lowerQromLoad bound to a callee-tag rail (a load at a quantum
// offset of a constant table of function pointers): the distinct functions the QROM's cells hold, with
// their tags, ascending by tag (null cells excluded). Empty when fp is not such a load.
llvm::SmallVector<std::pair<llvm::Function *, unsigned>, 4> qromCallees(LoweringContext &, const llvm::Value *fp);
// The callee tag of F: 1 + F's position among the module's address-taken functions in module order (the
// pass's __cq_ clones excluded); 0 is the null pointer.
unsigned calleeTag(const llvm::Module &, const llvm::Function &);
}
