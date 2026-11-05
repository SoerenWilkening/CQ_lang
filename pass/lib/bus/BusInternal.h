// Private to the one bus (pass/lib/bus): what Bus.cpp, InPlace.cpp, Version.cpp, Intrinsics.cpp and Alloc.cpp share.
#pragma once

#include "cq/Bus.h"
#include "llvm/ADT/SmallVector.h"

namespace cq::bus {

// Rule 5: the predicate a bus access is `_controlled` under at the instruction being lowered (an arm flag, a trip
// predicate, a _ctl clone's formal); nullptr when none is in scope.
llvm::Value *accessControl(LoweringContext &);

// Rule 20 Store size: one access per scalar leaf (vector lane, aggregate scalar field) at its DataLayout offset.
struct Leaf { llvm::Type *type; uint64_t offset; };
void scalarLeaves(const llvm::DataLayout &, llvm::Type *, uint64_t offset, llvm::SmallVectorImpl<Leaf> &);

// `addr` + off: the classical sum, or add_i64_hl into a fresh address rail (rule-5 garbage). No add at off 0.
Operand offsetAddress(LoweringContext &, Operand addr, uint64_t off);

// One qram_load_<W>[_hl][_controlled] at addr, recorded (Uncompute::recordBusLoad). T is the leaf's type (a ptr is i64).
llvm::CallInst *emitLoad(LoweringContext &, llvm::Type *T, Operand addr);
// One kept qram_store_<W>[_hl][_controlled] of `value` at addr (a classical value first the seed alloc_<W>), noted
// (Uncompute::noteKeptStore). Rule 5 sentence 3.
void emitKeptStore(LoweringContext &, llvm::Type *T, Operand addr, Operand value);

// Rule 5 In-place form (InPlace.cpp): is this store the end of the form? A store that is lowers there; every other
// store is the kept store.
bool isInPlaceForm(LoweringContext &, const llvm::StoreInst &);
void lowerInPlace(LoweringContext &, llvm::StoreInst &);
}
