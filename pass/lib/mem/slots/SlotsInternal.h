// mem-slots internal interface (not frozen): pointer-kind cells (cq-oocu; CR rules 20, 21; 107).
#pragma once

#include "cq/Lowering.h"
#include "llvm/IR/Argument.h"
#include "llvm/IR/IntrinsicInst.h"

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
void noteProgramSlotCall(LoweringContext &, const llvm::CallBase &orig, const Specialization &callee,
                         llvm::CallInst *lowered);
}
