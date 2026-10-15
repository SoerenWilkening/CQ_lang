// RailWindowAlias.h — bd `test_C_libtooling-01po.19` S3/S7: THE alias
// question of the window model and S7's versioning entry points (split out of
// RailWindow.h for the 400-line budget). Contract of the model: RailWindow.h.

#ifndef CQ_IRPASS_RAIL_WINDOW_ALIAS_H_
#define CQ_IRPASS_RAIL_WINDOW_ALIAS_H_

#include "RailWindow.h"

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"

#include <optional>

namespace llvm {
class BasicBlock;
class DominatorTree;
class Function;
class ICmpInst;
class Instruction;
class PostDominatorTree;
class SCEV;
class ScalarEvolution;
class Value;
}  // namespace llvm

namespace cq {

// Are the two cell addresses provably DIFFERENT cells (S3/S7's one question,
// review round 1 F1: asked before promotion as well as for the needs list)?
// Without `Ctx`, everywhere (SCEV `isKnownNonZero(A - B)`); with it, at that
// instruction, also under a dominating `A != B`: S7's versioning guard, or a
// user test that `railWindowCompareIsCellEquality` accepts as exactly the
// cell test (same address difference, or index difference times a power of
// two that cannot wrap to 0 — an unmasked i64 `i != j` over 4-byte cells is
// NOT one). `isKnownPredicateAt` first, then the dominating-edge walk over
// `DT` (a dominating `!=` edge wins over an `==` one: such a context is dead).
bool railWindowDistinct(llvm::ScalarEvolution &SE, const llvm::SCEV *A,
                        const llvm::SCEV *B,
                        const llvm::Instruction *Ctx = nullptr,
                        llvm::DominatorTree *DT = nullptr);
// Does the equality compare `C` test exactly "the two cells are one" for the
// cell-address difference `AB` (pointer offsets, or integer indices scaled by
// a power of two that cannot wrap)?
bool railWindowCompareIsCellEquality(llvm::ScalarEvolution &SE,
                                     const llvm::ICmpInst *C,
                                     const llvm::SCEV *AB);
// The dominating-equality fact on two cell addresses at `Ctx`: true when an
// edge asserting `A != B` dominates it, false when one asserting `A == B`
// does, none otherwise (the one dominating-edge walk of S7).
std::optional<bool> railWindowEdgeFact(llvm::ScalarEvolution &SE,
                                       llvm::DominatorTree &DT,
                                       const llvm::Instruction *Ctx,
                                       const llvm::SCEV *A,
                                       const llvm::SCEV *B);
// Two cell classes of one window may be promoted side by side iff they are
// distinct everywhere, or at every access of one of them.
bool railWindowPairProven(llvm::ScalarEvolution &SE, llvm::DominatorTree &DT,
                          const llvm::SCEV *A, const llvm::SCEV *B,
                          llvm::ArrayRef<llvm::Instruction *> AccA,
                          llvm::ArrayRef<llvm::Instruction *> AccB);
// S3's promotion plan for ONE class (accesses `Uses`, region `Entry`): the one
// dominating address, the seed point `At` and the exiting blocks that get the
// write-back. False (and `At` null) when the class is not promoted.
struct RailWindowClassPlan {
  llvm::Value *Addr = nullptr;
  llvm::Instruction *At = nullptr;
  llvm::SmallVector<llvm::BasicBlock *, 4> Exiting;
  bool HasStores = false;
  llvm::BasicBlock *Entry = nullptr;
  bool Inside = false;  // the address is defined inside the region
};
// The plan's seed insertion point, asked on the IR as it is now.
llvm::Instruction *railWindowPlanSeedPoint(const RailWindowClassPlan &P);
bool railWindowClassPlan(
    llvm::Function &F, llvm::DominatorTree &DT,
    const llvm::DenseMap<llvm::BasicBlock *, llvm::BasicBlock *> &R,
    llvm::BasicBlock *Entry, llvm::ArrayRef<llvm::Instruction *> Uses,
    RailWindowClassPlan &P);
// The program points the plan itself touches the cell at (the seed and each
// write-back): the alias proof must hold there too (R11 S7 A-F1).
void railWindowPlanPoints(const RailWindowClassPlan &P,
                          llvm::SmallVectorImpl<llvm::Instruction *> &Out);
// One unproven pair: two classes of window region `E` (address SCEVs `A`,
// `B`; their accesses in instruction order).
struct RailWindowPair {
  llvm::BasicBlock *E = nullptr;
  const llvm::SCEV *A = nullptr, *B = nullptr;
  llvm::SmallVector<llvm::Instruction *, 8> AccA, AccB;
};
// THE alias question of S3/S7 (the one spelling): the first pair of classes
// in one window region that `railWindowPairProven` cannot prove distinct.
bool railWindowUnprovenPair(llvm::Function &F, const RailWindowAccesses &Acc,
                            llvm::DominatorTree &DT, llvm::LoopInfo &LI,
                            llvm::ScalarEvolution &SE, RailWindowPair &Out);
// CONTROL == TARGET (S7, RailWindowAlias.cpp): a quantum branch/switch/select
// condition (`QD`) reading one class of `P` that controls a store to the
// other. In the aliased copy that gate is controlled by its own target, which
// is not unitary (owner Q2 ruling: loud). Returns the store, or null.
llvm::Instruction *
railWindowSelfControl(llvm::Function &F, const RailWindowAccesses &Acc,
                      const llvm::SmallPtrSetImpl<llvm::Value *> &QD,
                      const RailWindowPair &P, llvm::ScalarEvolution &SE,
                      llvm::DominatorTree &DT, llvm::PostDominatorTree &PDT);

// One S7 versioning of pair `P` (RailWindowVersionPair.cpp): the aliased-copy
// blocks join `Alias`, every block it creates or copies gets `Origin` = `O`
// (the copy count is per ORIGINAL window). False after a loud diagnostic.
bool railWindowVersionPair(
    llvm::Function &F, llvm::AllocaInst *W, const RailWindowPair &P,
    llvm::SmallPtrSetImpl<llvm::BasicBlock *> &Alias,
    llvm::DenseMap<llvm::BasicBlock *, llvm::BasicBlock *> &Origin,
    llvm::BasicBlock *O);

}  // namespace cq

#endif  // CQ_IRPASS_RAIL_WINDOW_ALIAS_H_
