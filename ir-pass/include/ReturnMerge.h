// ReturnMerge.h — multi-exit `ret` normalization (bd test_C_libtooling-dm7f.5).
//
// Two entry points, one mechanism (Rule 14 / CLAUDE.md R12):
//
//   * `mergeReturnBlocks` — THE spelling of "turn N `ret`s into `br` to one new
//     block that returns a φ of their values". Extracted VERBATIM from
//     `Specialization.cpp`'s `normalizeReturnMerge` (bd 5po2 I2 / 79ag), which now
//     calls it with its own names and no debug locations, so a Phase-6 clone's
//     body is byte-identical to the pre-extraction binary's. Extended to `ret
//     void` (no φ) for the module-level caller below; the clone caller keeps its
//     own "every `ret` carries a value of the return type" guard and never asks.
//
//   * `unifyTaintedReturns` — the MODULE-LEVEL normalization. `clang -O1`
//     reconverges an ordinary early return into ONE `ret` fed by a merge φ, which
//     the control emitters already lower; two populations keep a `ret` per arm:
//     a `musttail` call (it must be immediately followed by `ret`) and hand IR.
//     For every defined function that has a NON-RECONVERGING tainted-condition
//     `br`/`switch` — two or more `ret` blocks reachable from it, and no block on
//     every path from it to a `ret` (LLVM's `PostDominatorTree`, re-asked over
//     the `ret` exits alone where its virtual root hides an `unreachable` or
//     infinite-loop exit) — not on a CFG cycle, this rewrites the function into
//     the shape `clang -O1` emits for the same program written with ordinary
//     returns, and nothing else. "Those `ret`s" are the ones such a terminator
//     reaches; any other `ret` (a classical tail recursion ahead of the quantum
//     part) is neither merged nor asked about (review round 1 F2):
//       1. every `musttail` call that precedes one of those `ret`s is demoted to
//          `tail` — or, where its tail position is LOAD-BEARING, the function is
//          refused with a loud, source-located diagnostic and left untouched
//          (`mustTailDemotionRefusal` in the .cpp names each case);
//       2. each of those `ret`s becomes a `br` to one new block `cq.retmerge`
//          holding `φ cq.ret` (value functions) and the one `ret`; the
//          `lifetime.end` markers of static entry-block allocas that closed a
//          former `ret` block move into `cq.retmerge`, where clang puts the one
//          copy in the twin (`sinkLifetimeEnds`, review round 1 F1);
//       3. a φ whose incoming values are all ONE value (`PHINode::
//          hasConstantValue`) is replaced by that value — `-O1`'s InstSimplify
//          does the same to the twin;
//       4. a former `ret` block left EMPTY (only the new `br`) is folded into its
//          predecessors with `TryToSimplifyUncondBranchFromEmptyBlock` (SimplifyCFG's
//          own empty-block removal) — but only when none of its predecessors is
//          already a predecessor of the merge, so no conditional branch ever
//          ends up with two identical successors.
//     A function with a tainted multi-exit terminator ON A CYCLE is left
//     untouched entirely (multi-exit loops are bd 8h7d's row; they keep today's
//     loud declines). A function with no tainted multi-exit terminator is never
//     touched, so a classical multi-`ret` function stays byte-identical.
//
// TAINT BOOKKEEPING. The new φ is inserted into `taint.Tainted` iff one of its
// incoming values is tainted, and its forward closure is taken through
// `propagateFromSeeds` — the shipped walk (Rule 14). When `Delta` is non-null it
// receives that whole growth, and the caller MUST adjudicate it
// (`adjudicateTaintDelta`), exactly as for `MergePhiPeel`. `Delta == nullptr` is
// legal only where the caller re-`propagate`s from scratch (the EARLY slot, before
// any guard has run) or where its own caller already adjudicates `Tainted −
// before` (the round-2 loop in `detectAndLowerOnwardControl`). Erased `ret`s and
// folded blocks leave no dangling key: every `TaintSet` table is a
// `ScrubOnDelete` container.
//
// SLOTS (CLAUDE.md L1 — control detection runs twice). Called (a) EARLY, right
// after the pass-through early-out in BOTH entry points, so every pre-detection
// stage (PredMux, the I/O-sink and guarded-store pre-peels, `lowerLoops`, the
// specialization detector and the escape guards) sees the twin's IR; and (b)
// immediately before EVERY `detectControlRegions` call — both round-1 call sites
// and the round-2 fixpoint — beside `peelIndependentMergePhis`, because a branch
// whose condition reads a 6.5/4.5 `%out` rail is classical at slot (a) and
// tainted only at round 2. Idempotent: a normalized function has one `ret`.

#ifndef CQ_IRPASS_RETURNMERGE_H
#define CQ_IRPASS_RETURNMERGE_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/StringRef.h"

namespace llvm {
class BasicBlock;
class Function;
class Module;
class PHINode;
class ReturnInst;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

struct MergedReturn {
  llvm::BasicBlock *Merge = nullptr;  // the new single-`ret` block
  llvm::PHINode *Phi = nullptr;       // the return-value φ; null for `ret void`
};

// Replace every `ret` in `Rets` (in layout order: all of `F`'s for the clone
// caller, the needing subset for `unifyTaintedReturns`) with a `br` to a
// new block named `BlockName` appended to `F`; for a non-void `F` the block holds
// `PhiName` = φ(ret value, ret block) feeding its `ret`. `CarryDebugLoc` copies
// each `ret`'s location onto its `br` and gives the new `ret` the merged location
// (`DILocation::getMergedLocations`); the clone caller passes false. Requires
// `Rets.size() >= 2` and, for a non-void `F`, a return value of `F`'s type on each.
MergedReturn mergeReturnBlocks(llvm::Function &F,
                               llvm::ArrayRef<llvm::ReturnInst *> Rets,
                               llvm::StringRef BlockName,
                               llvm::StringRef PhiName, bool CarryDebugLoc);

// The module-level normalization described above. Returns true iff the module
// was mutated. Refusals are diagnosed here (loud, `!dbg`-located, through
// `diagnoseUnderControl`); the refusal predicate is `mustTailDemotionRefusal` in
// ReturnMerge.cpp, whose comment names each case.
bool unifyTaintedReturns(llvm::Module &M, TaintSet &taint,
                         llvm::SmallPtrSetImpl<llvm::Value *> *Delta);

}  // namespace cq

#endif  // CQ_IRPASS_RETURNMERGE_H
