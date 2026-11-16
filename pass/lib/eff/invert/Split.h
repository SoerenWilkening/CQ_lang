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

namespace llvm { class Loop; }

namespace cq::invert {

// cq-oyirf (CR rule 17 "A value made in the region and read after its end", owner ruling 2026-11-16; Repeat.cpp): in each
// tainted function, a use after a cq_invert region's end of a quantum value the region made, through a computation whose
// pure cone in the region reaches a loop, reads instead the same value of a copy of the region's pure remainder placed
// right after the end (the loop runs again there); a loop value read by what keeps its rail (a measurement, a call, a
// return, a store, a phi) still crosses the end. The repeated loops' headers carry `cq.repeat` (repeatedLoop). Run after
// the final taint, which it reads; returns the functions it changed (the scaffold re-taints them).
llvm::SmallVector<llvm::Function *, 4> repeatAfterEnd(llvm::Module &M, const TaintInfo &T);

// Is L a loop repeatAfterEnd placed after a region's end? It keeps no a_K (the in-region loop's is the kept rail).
bool repeatedLoop(const llvm::Loop &L);

} // namespace cq::invert
