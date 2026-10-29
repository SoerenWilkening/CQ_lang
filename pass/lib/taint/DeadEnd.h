// Private to module taint (cq-820w); pred consumes it through its Oracle (taint's answer, A1).
//
// A DEAD END is a block from which no return to the caller is reachable: every path from it ends in
// `unreachable` (a noreturn call such as abort/exit/llvm.trap followed by `unreachable`, or a bare
// __builtin_unreachable). CR rule 16: after a noreturn arm the program continues uncontrolled, so for
// control dependence (taint) and path predicates (pred) an edge into a dead end does not restrict its
// siblings. The dead end itself keeps the predicate of its own edge (its noreturn call is classified
// under it). This is the one definition both modules use. Header-only: the C oracle links taint as
// the single unit Taint.cpp (checker/cqcheck/oracle.py PASS_SOURCES).
#pragma once

#include <vector>

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

namespace cq::taint_detail {

class DeadEnds {
public:
  DeadEnds() = default;
  explicit DeadEnds(const llvm::Function &F) {
    std::vector<const llvm::BasicBlock *> work;
    for (const llvm::BasicBlock &BB : F)
      if (returns(&BB) && live.insert(&BB).second)
        work.push_back(&BB);
    while (!work.empty()) {
      const llvm::BasicBlock *B = work.back();
      work.pop_back();
      for (const llvm::BasicBlock *P : llvm::predecessors(B))
        if (live.insert(P).second)
          work.push_back(P);
    }
  }
  // A block of F (reachable or not) from which no return is reachable.
  bool isDeadEnd(const llvm::BasicBlock *BB) const { return !live.count(BB); }
  // Is BB a successor-less terminator's block that returns to the caller (ret, resume, ...)?
  static bool returns(const llvm::BasicBlock *BB) {
    const llvm::Instruction *T = BB->getTerminator();
    return T && T->getNumSuccessors() == 0 && !llvm::isa<llvm::UnreachableInst>(T);
  }

private:
  llvm::SmallPtrSet<const llvm::BasicBlock *, 16> live;   // blocks that reach a return
};

} // namespace cq::taint_detail
