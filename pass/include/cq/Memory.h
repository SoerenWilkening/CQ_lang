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
// M4b (cq-r7-91, CR rules 14, 20, 21; 91): the cells start firstByte bytes past ptr (consumer loops-cutoff:
// a K-loop trip object's cells, read at the trip's end).
llvm::SmallVector<Operand, 8> readSlotCells(LoweringContext &, const llvm::Value *ptr, llvm::Type *cellTy,
                                            uint64_t n, llvm::Instruction &at, int64_t firstByte = 0);
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
// recordCall's `slotOuts`. M1b (cq-arch 2026-11-01): argNo is the callee's formal index; the site operand is
// argMap.empty() ? argNo : argMap[argNo] (a call lowered as a call of another function, rule 24's
// pthread_create(t, attr, f, p) -> f(p): argMap {3}).
llvm::SmallVector<llvm::Value *, 4> slotCellsBeforeCall(LoweringContext &, const llvm::CallBase &orig, unsigned argNo,
                                                        llvm::ArrayRef<unsigned> argMap = {});
llvm::SmallVector<llvm::Value *, 4> slotCellsAfterCall(LoweringContext &, const llvm::CallBase &orig, unsigned argNo,
                                                       llvm::CallInst *lowered, llvm::ArrayRef<unsigned> argMap = {});
// T3c (cq-budv, CR rules 5, 18, 20; 117). mem-slots, consumer calls noteRotatedCells: the rails the cells of
// the slot object ptr points to may hold at `at` (a clone call rotating any of its cells in place,
// TaintInfo::kAnyCell). A dynamic local or heap slot array only; any other object is unimplemented.
llvm::SmallVector<llvm::Value *, 8> slotRailsMayHold(LoweringContext &, const llvm::Value *ptr, llvm::Instruction &at);
// M7 (cq-z6q1, CR rules 20, 21; 189). mem-slots, consumer fatptr: hostRecord: root is the allocation call of a
// heap slot RECORD (a heap block accessed at several types at constant offsets: one cell per field, a handle
// field an i32 cell, a classical field, a pointer field among them, its C value; the block keeps its host
// layout, so its host address is its base). loadSlotCellAt: the field of such a record at byte `byte` read
// as ty at `at` (a load through a fat pointer naming it): the handle the cell holds there, or the classical
// value of a classical field (a host load). Anything else is unimplemented.
bool hostRecord(LoweringContext &, const llvm::Value *root);
Operand loadSlotCellAt(LoweringContext &, const llvm::Value *root, int64_t byte, llvm::Type *ty, llvm::Instruction &at);
// M8 (cq-arch 2026-11-01, CR rules 5, 6, 20; 114). mem-slots, consumer spine construct: called once a
// specialization's body is lowered (every item placed). A register array's rails (a slot array whose cells
// rule 6 cleans at each register update y' = y ^ z, the old rail freed right after the store) are read by
// no item that may run after such a clean-up freed them; anything else is unimplemented.
void finishSlots(LoweringContext &);
// M8. mem-slots, consumer loops-classical: handle is a register of a slot cell (kept, never resolved by
// Uncompute: a seed or cq_theta register of a dynamic object, a register update's new rail, an alias load).
bool isSlotRegister(LoweringContext &, const llvm::Value *handle);
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
// Q1 (cq-arch 2026-11-01, CR rules 19, 20, 21; 97). mem-qrom, consumer calls lowerIndirect: a function pointer
// loaded at a quantum index from a constant table is a QROM over the derived table <global>.cqtag of callee tags;
// lowerQromLoad binds the load to the i32 tag rail. qromCallees: the distinct functions the QROM's cells hold, with
// their tags, ascending by tag (null cells excluded); empty when fp is not such a load. calleeTag: 1 + F's position
// among the module's address-taken functions in module order (the pass's __cq_ clones excluded); 0 is null.
llvm::SmallVector<std::pair<llvm::Function *, unsigned>, 4> qromCallees(LoweringContext &, const llvm::Value *fp);
unsigned calleeTag(const llvm::Module &, const llvm::Function &);
}
