// Module eff-invert (CR rule 17, 2026-11-02, cq-asfn): a cq_invert marker inside a quantum arm whose match lies
// outside the arm. Private to eff-invert; the scaffold (Plugin.cpp) runs it before the final taint. Contract at
// splitMarkerPaths in Invert.cpp.
#pragma once

#include "cq/Taint.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"

namespace cq::invert {

// The tail between a quantum arm and its marker's match lowered under both arm flags (rule 17): every block
// of a tainted function that host paths of different region depths reach is split into one copy per depth
// (the preliminary taint T decides whether a quantum terminator separates them). Returns the functions it
// changed (empty: the module is unchanged).
llvm::SmallVector<llvm::Function *, 4> splitMarkerPaths(llvm::Module &M, const TaintInfo &T);

// The blocks of F from which an __cq_invert_end is reachable (the walker linearizes the arms of a quantum
// terminator that reach none first: rule 17's "B|not f ... before the bracket's end").
llvm::SmallPtrSet<const llvm::BasicBlock *, 16> blocksReachingInvertEnd(const llvm::Function &F);

} // namespace cq::invert
