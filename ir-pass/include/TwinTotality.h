// TwinTotality.h — bd dm7f.27 / dm7f.29 / dm7f.30 / dm7f.26: can the 6.5 hoist's
// speculation-safe twin of a callee be made TOTAL and TERMINATING on every
// defined argument tuple, and which structural edits make it so?
//
// The twin (SpeculationTwin.h) runs on basis states the source's guard
// excluded, so it must never trap, reach UB the poison dataflow cannot freeze
// away, or fail to return. Owner ruling 2026-10-08 (bd memory
// owner-ruling-hoist-callee-ub-sound-2026-10-08) built it for acyclic straight
// bodies; batch 053 widens the shape, each widening with its own edit:
//   * a conditional `br`/`switch` (dm7f.29): its condition is a sink, frozen by
//     the poison plan (PoisonFlow.cpp), so a poison condition is never UB;
//   * a division whose divisor is not a provably safe constant (dm7f.30): a
//     GUARD replaces the divisor by `select(bad, 1, freeze(d))`, `bad` being
//     `d == 0` (and `d == -1` for sdiv/srem, whose result is then rebuilt as
//     `0 - n` / `0`), so the twin is total on states the source's guard excluded;
//   * a natural loop whose maximum backedge-taken count ScalarEvolution proves
//     (dm7f.27): a COUNTER phi in the header exits to `ret <zero>` once it
//     exceeds that bound, so the twin terminates within ScalarEvolution's
//     constant max trip count whatever its frozen values are. That can be long:
//     a helper that diverges on a classical input under a zero-amplitude guard
//     runs to the bound (measured 2^31 iterations, 16 s), accepted by owner
//     ruling owner-ruling-twin-divergence-bounded-2026-10-13;
//   * an `unreachable` (round-1 A-F3, e.g. an -O1 switch default): the twin
//     returns zero there (reaching it is UB in the source);
//   * a bodyless `speculatable` root callee (dm7f.26): the twin is a wrapper
//     body (`ret freeze(call F(...))`), see SpeculationTwin.cpp.
// Memory, an indirect or recursive call, an inner declaration, a vector, an
// irreducible cycle and an unbounded loop stay refused (loud, R1 gaps).
//
// EXACTNESS (R2, analytic): on a basis state where the source runs the call
// without UB, (1) a guarded divisor is defined and non-zero (and not -1 with an
// INT_MIN dividend), so the guard selects it and the -1 fix-up computes the same
// value (an i1 sdiv/srem has 0 as its only UB-free result, and the twin emits
// 0); (2) ScalarEvolution's bound holds on every UB-free execution (its facts
// are modulo poison and UB: a wrapped `nsw` IV feeding an exit is a branch on
// poison; a violated `range` is poison), so the counter never exceeds it and its
// exit is never taken. It is computed with every `returned` attribute stripped
// (round-1 A-F2: SCEV reads a call as its `returned` argument, and a false one
// is not UB, so it is not a modulo-UB fact; the twin drops it); (3) an
// `unreachable` is never reached. The twin therefore computes the callee's value
// there. Off those states it returns SOME defined value, never merged by the
// controlled copy.
#ifndef CQ_TWIN_TOTALITY_H
#define CQ_TWIN_TOTALITY_H

#include "llvm/ADT/APInt.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Transforms/Utils/ValueMapper.h"  // ValueToValueMapTy

#include <utility>

namespace llvm {
class BasicBlock;
class BinaryOperator;
class Function;
class Instruction;
}  // namespace llvm

namespace cq {

// One body's structural edits, keyed by its own instructions and blocks.
struct TwinShape {
  llvm::SmallVector<const llvm::BinaryOperator *, 2> Guards;
  // A loop header and its maximum backedge-taken count.
  llvm::SmallVector<std::pair<const llvm::BasicBlock *, llvm::APInt>, 2> Bounds;
  // An `unreachable` the twin turns into `ret <zero>` (round-1 A-F3).
  llvm::SmallVector<const llvm::Instruction *, 1> Unreachables;
};

// True when division `I` is total on every defined operand value as written: a
// constant divisor LLVM proves safe (`isSafeToSpeculativelyExecute`), or a
// divisor already in the guard shape this file emits (any body holding that
// shape is total, so it is recognised by structure, never by a tag).
bool divisionIsTotal(const llvm::Instruction &I);

// dm7f.26: does the twin of bodyless `F` (the wrapper `ret freeze(F(args))`,
// SpeculationTwin.cpp) exist? Its twin-mode walk (PoisonFlow.cpp, the call
// branch), predicted with every argument possibly poison: each `noundef`
// argument is frozen; the result is possibly poison when a non-`noundef`
// argument or an unproven return constraint can make it so, which is UB only
// under `F`'s own `noundef` return; a parameter contract beyond the inert set is
// UB no wrapper edit sheds. The builder re-walks the real wrapper, so a
// disagreement fails loudly there (an internal invariant), never silently.
bool declarationWrapperExists(const llvm::Function &F);

// Memoized over one query (a claim, an emitter question, one twin build).
class TwinTotality {
public:
  // Can a total, terminating twin of `F` be built, with every function its
  // twin may call (transitively) itself admitted?
  bool admits(const llvm::Function &F);
  // `F`'s own structural edits; meaningful only when `admits(F)`.
  const TwinShape &shape(const llvm::Function &F);
  // `F`'s ORIGINAL body is already total and terminating (no structural edit
  // anywhere in its call tree), so a twin may call it un-redirected. A verified
  // twin is total by construction.
  bool originalTotal(const llvm::Function &F);

private:
  struct Entry {
    bool Admitted = false;
    bool Total = false;
    TwinShape Shape;
  };
  const Entry &get(const llvm::Function &F);
  llvm::DenseMap<const llvm::Function *, Entry> Memo;
};

// Apply `S` (planned on the body `VMap` cloned into `T`) to `T`.
void applyTwinShape(llvm::Function &T, const TwinShape &S,
                    llvm::ValueToValueMapTy &VMap);

}  // namespace cq

#endif  // CQ_TWIN_TOTALITY_H
