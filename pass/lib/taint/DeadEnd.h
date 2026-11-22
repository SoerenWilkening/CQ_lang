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

#include "cq/Common.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/IntrinsicInst.h"
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

// cq-wskg (rule 16): a function with a body that aborts on every path with nothing before: its CFG is
// acyclic, it has no return, every `unreachable` follows a terminal noreturn call (a bodiless noreturn
// callee other than longjmp/_longjmp/siglongjmp and setjmp, llvm.trap, llvm.ubsantrap, or a defined
// callee of this same class), and every other instruction is side-effect free (no other call but
// debug and lifetime intrinsics). Its call is the noreturn call it ends in: abort_i1(pred) (`static
// void die(void) { abort(); }`). `onStack` breaks recursion (a recursive callee is not of the class).
// Here as the one definition taint (which lifts a defined noreturn callee otherwise, cq-gk1ki) and the spine's classify
// use.
bool abortsOnEveryPath(const llvm::Function &G, llvm::SmallPtrSetImpl<const llvm::Function *> &onStack);

inline bool terminalNoreturn(const llvm::CallBase &CB, llvm::SmallPtrSetImpl<const llvm::Function *> &onStack) {
  using namespace llvm;
  const Function *F = dyn_cast<Function>(CB.getCalledOperand()->stripPointerCasts());
  if (!F || CB.isInlineAsm())
    return false;
  if (F->isIntrinsic())
    return F->getIntrinsicID() == Intrinsic::trap || F->getIntrinsicID() == Intrinsic::ubsantrap;
  if (CB.hasFnAttr(Attribute::ReturnsTwice) || F->hasFnAttribute(Attribute::ReturnsTwice))
    return false;
  if (!hostCallee(*F))
    return abortsOnEveryPath(*F, onStack);
  StringRef n = F->getName();
  if (n == "longjmp" || n == "_longjmp" || n == "siglongjmp")
    return false;
  return CB.doesNotReturn() || F->doesNotReturn();
}

inline bool abortsOnEveryPath(const llvm::Function &G, llvm::SmallPtrSetImpl<const llvm::Function *> &onStack) {
  using namespace llvm;
  if (G.isDeclaration() || !onStack.insert(&G).second)
    return false;
  // Acyclic: no back edge on a depth-first walk from the entry.
  SmallVector<std::pair<const BasicBlock *, const BasicBlock *>, 4> backEdges;
  FindFunctionBackedges(G, backEdges);
  bool ok = backEdges.empty();
  for (const BasicBlock &BB : G) {
    for (const Instruction &I : BB) {
      if (!ok)
        break;
      if (isa<UnreachableInst>(I)) {
        auto *c = dyn_cast_or_null<CallBase>(I.getPrevNode());
        ok = c && terminalNoreturn(*c, onStack);
        continue;
      }
      if (I.isTerminator()) {
        ok = isa<BranchInst>(I) || isa<SwitchInst>(I);
        continue;
      }
      if (auto *c = dyn_cast<CallBase>(&I)) {
        if (isa<UnreachableInst>(c->getNextNode()))
          continue;   // checked at the unreachable
        if (auto *ii = dyn_cast<IntrinsicInst>(c))
          if (isa<DbgInfoIntrinsic>(ii) || ii->getIntrinsicID() == Intrinsic::lifetime_start ||
              ii->getIntrinsicID() == Intrinsic::lifetime_end)
            continue;
        ok = false;
        continue;
      }
      ok = !I.mayHaveSideEffects();
    }
  }
  onStack.erase(&G);
  return ok;
}

inline bool abortsOnEveryPath(const llvm::Function &G) {
  llvm::SmallPtrSet<const llvm::Function *, 8> onStack;
  return abortsOnEveryPath(G, onStack);
}

// cq-rb96s (CR rule 14): post-dominance inside ONE TRIP of loop L. Each trip runs under its own predicate a_j, so a
// back edge to L's header ends the trip like an exit edge: X post-dominates b in the trip when every path from b inside
// L reaches X before it returns to the header or leaves L (successors `skip` names, dead ends, are never taken). A block
// the function's post-dominance puts on every path (the loop's only way out lies behind a quantum branch, GMP
// block_resieve) is then control dependent on that branch per trip. Greatest fixpoint: an inner cycle that never
// leaves is no path out. Returns the blocks of L that X post-dominates in the trip (X included).
template <class Skip>
llvm::SmallPtrSet<const llvm::BasicBlock *, 16> tripPostDominated(const llvm::Loop &L, const llvm::BasicBlock *X,
                                                                  Skip skip) {
  llvm::SmallPtrSet<const llvm::BasicBlock *, 16> pd(L.block_begin(), L.block_end());
  // cq-i61ms: by a worklist (a removed block re-checks its predecessors), not passes over the loop until none drops:
  // the same greatest fixpoint, linear in the loop's edges.
  auto fails = [&](const llvm::BasicBlock *b) {
    for (const llvm::BasicBlock *s : llvm::successors(b))
      if (s != X && !skip(s) && (s == L.getHeader() || !pd.count(s)))
        return true;
    return false;
  };
  llvm::SmallVector<const llvm::BasicBlock *, 32> work;
  for (const llvm::BasicBlock *b : L.blocks())
    if (b != X && fails(b))
      work.push_back(b);
  for (const llvm::BasicBlock *b : work)
    pd.erase(b);
  while (!work.empty()) {
    const llvm::BasicBlock *b = work.pop_back_val();
    for (const llvm::BasicBlock *p : llvm::predecessors(b))
      if (p != X && pd.count(p) && fails(p)) {
        pd.erase(p);
        work.push_back(p);
      }
  }
  return pd;
}

} // namespace cq::taint_detail
