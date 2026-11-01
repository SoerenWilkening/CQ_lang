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
// M6 (cq-arch 2026-11-01). mem-slots, consumer mem-qram (CR rules 6, 7, 9, 20, 22; 190, 90): the n =
// vals.size() consecutive cells of type cellTy at ptr take vals[i] at `at` (a memory intrinsic the caller
// lowers in place), each with lowerSlotStore's semantics (a classical value is a seed, rule 7; a handle is a
// basis copy into the cell); guards empty or guards[i] null = unguarded, else cell i = select(guards[i],
// vals[i], old) into a fresh rail (the old handle comes back on uncompute, rule 22). Later loads, M3 cell
// reads and slotCellsBefore/AfterCall see `at` as a named store of each cell.
void writeSlotCells(LoweringContext &, const llvm::Value *ptr, llvm::Type *cellTy, llvm::ArrayRef<Operand> vals,
                    llvm::ArrayRef<llvm::Value *> guards, llvm::Instruction &at);
// M1 (cq-arch 2026-11-01). mem-slots, consumer calls (CR rules 18, 20, §1.4): a pointer to a caller's slot
// object passed as argNo of a quantum clone call. Before: the old contents of the cells the clone may write
// (TaintInfo::cellsWritten), ascending by cell, at the cell's C type (a handle, a classical value, or poison
// where never written); calls passes them as recordCall's `extra`. After (called right after `lowered`): emits
// the handle loads of those cells and binds the original's later loads of them; calls passes them as
// recordCall's `slotOuts`.
llvm::SmallVector<llvm::Value *, 4> slotCellsBeforeCall(LoweringContext &, const llvm::CallBase &orig, unsigned argNo);
llvm::SmallVector<llvm::Value *, 4> slotCellsAfterCall(LoweringContext &, const llvm::CallBase &orig, unsigned argNo,
                                                       llvm::CallInst *lowered);
void allocateSlots(LoweringContext &, llvm::Instruction &site);   // mem-slots
void endSlotLifetime(LoweringContext &, ObjectId, llvm::Instruction *at);  // mem-slots
void lowerQromLoad(LoweringContext &, llvm::LoadInst &);          // mem-qrom
void lowerQramLoad(LoweringContext &, llvm::LoadInst &);          // mem-qram
void lowerQramStore(LoweringContext &, llvm::StoreInst &);        // mem-qram
void allocateQram(LoweringContext &, llvm::Instruction &site);    // mem-qram
void endQramLifetime(LoweringContext &, ObjectId, llvm::Instruction *at);  // mem-qram
void reallocQram(LoweringContext &, llvm::CallBase &realloc);   // mem-qram (M5, cq-arch 2026-11-01)
void lowerMemIntrinsic(LoweringContext &, llvm::MemIntrinsic &);  // mem-qram
// M2 (cq-arch 2026-11-01, CR rules 18, 20, 21; 191). mem-qram: the number of the clone's stores through
// Qram-pointee formals (T4), in program order (a store under a branch, in a loop or under a quantum
// predicate: unimplemented). Consumer calls resultLayout: that many i32 handles after the result's leaves
// (void with one store: i32; otherwise a literal struct {result leaves..., i32 x N}).
unsigned calleeQramStoreCount(const TaintInfo &, const Specialization &callee);
// M2b. mem-qram, in a clone: a store through a bound Qram formal is lowered as the rule-18 copy-out (alloc
// 0, copy, Role::Result), no store. Called by Construct emitCloneReturn after flushAtExit, with the builder
// before the ret: emits cqrt_qram_store_<W>[_hl](bus, idx, copy) in program order, records nothing, returns
// the copies (appended to the return). Finalize drops these trailing stores from the twin.
llvm::SmallVector<llvm::Value *, 2> emitCalleeQramStores(LoweringContext &);
// U3. mem-qram, caller side: called by calls right after recordCall for every call with a Qram-pointee
// triple formal (storedRails possibly empty): Uncompute::noteCallBusRead(fwd, bus) per bus the call reads,
// then per stored rail in order recordCore(fwd, QramStore[_hl], {bus, idx, v}, bus) with idx the actual's
// idx plus the store's constant offset in the clone.
void noteCalleeQramStores(LoweringContext &, const llvm::CallBase &orig, const Specialization &callee,
                          llvm::CallInst *fwd, llvm::ArrayRef<llvm::Value *> storedRails);
}
