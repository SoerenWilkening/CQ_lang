// mem-slots internal interface (not frozen): pointer-kind cells (cq-oocu; CR rules 20, 21; 107).
#pragma once

#include "cq/Lowering.h"
#include "llvm/IR/Argument.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Instructions.h"

#include <utility>

namespace cq::mem {
// In a clone: formal A is a T4 triple (with or without its cell count) onto a caller's slot object whose cells
// the clone accesses are all of pointer kind (two mask digits per accessed cell, CR §1.4). mem-slots lowers its
// accesses (spine dispatch routes them there, not to fatptr's bound slot loads).
bool isPointerKindFormal(LoweringContext &, const llvm::Argument &A);
// 102 (program slots, Slots.cpp programSlot; CR rules 16, 19, 20, 2): called by calls right after it emitted
// `lowered`, the clone call of orig with callee `callee`. A callee writing a program slot by its guarded store
// (a _ctl clone) records the slot as written in the caller (loading the slot's old handle before the call);
// any other access of a program slot by the callee is unimplemented; nothing otherwise.
// cq-8101 (CR rule 7; Slots.cpp): seeds a constant-length memset (mem-qram lowerSlotMemset) wrote into the cells
// of object o, released at o's lifetime end when they are never written; nothing otherwise.
// of object o (each at its byte offset in o), released at o's lifetime end when they are never written, and
// named as the memset's cells (M6) for the run-time reads; nothing otherwise.
void noteMemsetSeeds(LoweringContext &, const llvm::MemSetInst &MS, ObjectId o,
                     llvm::ArrayRef<std::pair<int64_t, llvm::Value *>> seeds);
// CR rules 20, 22 (cq-366o): a local's cell type: the one scalar type the whole program accesses it as (directly
// or through the formals of the functions it is handed to) when that differs in size from its declared element,
// otherwise the declared scalar element. mem-slots, mem-qram and rule 21's triples agree on it.
llvm::Type *localCellType(const llvm::AllocaInst &ai);
// cq-dd3q (CR rules 20, 21, 22): mem-slots' cells of the slot object o rooted at root (its objInfo, in the
// function of `at`), so that mem-qram's rule-22 writes and rule 21's triples classify an object exactly as
// mem-slots lays it out. record: one cell per field of its own type (cellBytes 0; pointerField when a field is a
// pointer); otherwise cells of cellBytes bytes and C type cellTy (_Bool cells: boolCells), view a bit view (63),
// split byte cells whose wider classical stores are split (90, 120), colStride a field column's (129). fields: the
// record's field kinds are decided (decideFields) and handleCellBytes is set when every field is a handle cell of
// one C size (no pointer field): the record is then laid out as a slot array of that cell size (4-byte handles).
struct SlotLayout {
  bool record = false, pointerField = false, boolCells = false, view = false, split = false;
  uint64_t cellBytes = 0, colStride = 0, handleCellBytes = 0;
  llvm::Type *cellTy = nullptr;
};
SlotLayout slotLayout(LoweringContext &, const llvm::Value *root, ObjectId o, const llvm::Instruction &at,
                      bool fields = false);
void noteProgramSlotCall(LoweringContext &, const llvm::CallBase &orig, const Specialization &callee,
                         llvm::CallInst *lowered);
}
