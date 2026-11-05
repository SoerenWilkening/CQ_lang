// Module eff-conc (CR rule 24, 101): setjmp/longjmp made explicit control flow before the final taint.
// Private to eff-conc; the scaffold (Plugin.cpp) runs it. Contract at the top of Setjmp.cpp.
#pragma once

#include "cq/Taint.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"

namespace cq::conc {

// Rewrites every tainted function holding a setjmp (on the preliminary taint T), and every function
// through which a longjmp may escape to it, into explicit control flow: the escape becomes a result
// (escaped flag, jmp_buf, value) returned beside the function's own, the setjmp's second return a
// continuation reached from each escape point. Returns the functions it changed or created (empty:
// the module is unchanged). Originals left with no use are erased; T is not read afterwards.
llvm::SmallVector<llvm::Function *, 8> explicitSetjmp(llvm::Module &M, const TaintInfo &T);


// Rule 24 (106): pthread_create / pthread_join / the mutex calls of tainted functions collapsed to the
// sequential schedule in the IR (Conc.cpp). Returns the functions it changed.
llvm::SmallVector<llvm::Function *, 8> collapseThreads(llvm::Module &M, const TaintInfo &T);

} // namespace cq::conc
