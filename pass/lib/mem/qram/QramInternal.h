// Module-internal interface of mem-qram for fatptr (both stream C's, not frozen): rule 21's per-object
// accesses of a fat pointer whose provenance holds QRAM objects.
#pragma once

#include <utility>

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
// idxBits: a rail idx's width (a triple formal's loads after its deferred stores compare indices, M2b).
llvm::Value *qramLoadAt(LoweringContext &, const llvm::Value *root, Operand idx, llvm::Type *ty,
                        const llvm::Instruction &at, unsigned idxBits = 32);
// The (tag, idx) halves of the pointer cell idx of the QRAM of pointers at root, loaded unguarded.
std::pair<llvm::Value *, llvm::Value *> qramLoadPtrAt(LoweringContext &, const llvm::Value *root, Operand idx,
                                                      const llvm::Instruction &at);
// One store of the handle v (type ty) at cell idx of the QRAM at root, _controlled on flag when not null.
void qramStoreAt(LoweringContext &, const llvm::Value *root, Operand idx, llvm::Type *ty, llvm::Value *v,
                 llvm::Value *flag, const llvm::Instruction &at);
// The bus handle of the single-column QRAM at root (a pointer crossing a clone boundary as a rule 21
// triple, 191); a multi-column (struct) QRAM is unimplemented.
llvm::Value *qramBusOf(LoweringContext &, const llvm::Value *root, const llvm::Instruction &at);
// The cell type of that single column.
llvm::Type *qramCellType(LoweringContext &, const llvm::Value *root, const llvm::Instruction &at);

// ---- triple formals (P1, M2, M2b, U3; rule 21, §1.4, 190, 191) ------------------------------------
// The one scalar type every load and store through pointer formal A (and the GEPs, bitcasts, phis and
// selects derived from it) accesses, in A's function. Any other use of a pointer derived from A (a call,
// a memory intrinsic, free, realloc, a compare, ptrtoint, the pointer stored as a value), two access
// types, a pointer or aggregate access, or no access at all are unimplemented. (A Qram-pointee formal
// allows no phi or select either: M2, registerFormalQram.)
llvm::Type *formalCellType(const llvm::Argument &A);
// The rule 21 triple's fields of a one-object, classical pointer `ptr` into a slot or host object (a
// local or global plus classical GEPs): the root, the classical cell index (i32), the object's cell
// count (i32) and its cell size in bytes (mem-slots' cells: the scalar element). Any other root, an
// offset that is not a whole number of cells, or an object accessed at another width, is unimplemented.
struct HostTriple { const llvm::Value *root; llvm::Value *idx; llvm::Value *cellCount; uint64_t cellBytes; };
HostTriple hostTriple(LoweringContext &, const llvm::Value *ptr, const llvm::Instruction &at);
// In a clone: the Qram-pointee triple formal A crosses as the caller's bus `bus` (P1). Registers A as a
// one-column QRAM object of cell type formalCellType(A) over that bus; the clone neither pops nor frees it.
void registerFormalQram(LoweringContext &, const llvm::Argument &A, llvm::Value *bus);
// True when root is a triple formal registered by registerFormalQram in this output function.
bool isFormalQram(LoweringContext &, const llvm::Value *root);
// M2b, a store through a registered formal at cell idx (the formal's own idx rail, a classical i64 cell
// index, or a computed rail idx of idxBits bits) under flag (the current predicate, or null): the rule 18
// copy-out of v (a fresh rail, alloc 0 + copy, Role::Result), of a computed or offset index (M2's index rail),
// and of the flag; the store itself (_controlled under the flag's copy) emitted by emitCalleeQramStores after
// the clone's body uncompute.
void deferFormalStore(LoweringContext &, const llvm::Value *root, Operand idx, unsigned idxBits, llvm::Type *ty,
                      llvm::Value *v, llvm::Value *flag, const llvm::Instruction &at);
}
