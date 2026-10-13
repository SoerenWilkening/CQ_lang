// StaleReadRegion.h — WHERE a stale read may be placed, and WHAT it then crosses
// (bd test_C_libtooling-57ch.1, batch 053; owner ruling bd 57ch (A), 2026-10-01).
// The legality of crossing each instruction is StaleReadPlacement.h's; this file
// owns the CONTROL-FLOW half: the slot, the span between the slot and the read,
// and the termination proof a crossed or moved call needs (bd 57ch.4, partial).
//
// THE SLOT. Let `D` be the nearest common dominator of the read's block and every
// staling gate's block. The slot is the earliest staler in `D`, or `D`'s
// terminator when no staler lies in `D` (the stalers are then all in blocks `D`
// strictly dominates — a gate in a classical or tainted ARM with the read after
// the merge). Every staler is after the slot on every path that runs it, and the
// read is placed before the slot, so before all of them.
//
// WHY THE MOVE KEEPS THE PROGRAM (cross-block, `D` is not the read's block `B`):
//   * `B` post-dominates `D`, and the span (every block on a path from `D` to `B`
//     that does not pass `B`) is ACYCLIC, closed (each span block ends in a `br` /
//     `switch` whose successors are span blocks or `B`) and never re-enters `D`;
//   * `B` cannot run again without passing `D` (no path from `B` back to `B` that
//     avoids `D`).
// So each execution of `D` is followed by exactly one execution of `B` before
// the next execution of `D`, and the read moved to `D` runs exactly once per
// execution it had in `B`: the same dynamic instances, earlier. (Dominance plus
// post-dominance alone is not enough: `D: br c, X, B; X: br D` runs `D` twice per
// `B`.) An inner loop in the span is refused even when it would terminate. The
// 57ch.4 ruling (2026-10-13) admits crossing a CALL that may not return
// (`callTerminationCrossable`); a loop in the read's own function would also need
// the execution-count argument above re-made for a cyclic span, which is not built.
//
// Bennett.jl orders gates only by their wire dependences (src/dep_dag.jl:28-60
// @824458d: a gate depends on the last writer of every wire it reads), so a read
// may run anywhere its inputs are current; Bennett.jl's predicated lowering
// requires the same acyclic, closed region shape (src/lowering/cfg.jl:51-116,
// `_check_predication_cfg`, `find_back_edges`).

#ifndef CQ_IRPASS_STALE_READ_REGION_H_
#define CQ_IRPASS_STALE_READ_REGION_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
class BasicBlock;
class CallBase;
class CallInst;
class DominatorTree;
class Function;
class Instruction;
class PostDominatorTree;
}  // namespace llvm

namespace cq {

struct PlacementSpan {
  llvm::Instruction *At = nullptr;   // the slot: the read goes before it
  llvm::Instruction *Read = nullptr;
  // Span blocks strictly between `At`'s block and the read's block, in a
  // topological order (empty when the two coincide or are adjacent).
  llvm::SmallVector<llvm::BasicBlock *, 8> Blocks;
  // Index of each span block, `At`'s block (0) and the read's block (last).
  llvm::DenseMap<const llvm::BasicBlock *, unsigned> Order;
  // Reach[i] has bit j set iff span-order block j is reachable from block i
  // inside the span (reflexive). At most 64 span blocks; more refuses.
  llvm::SmallVector<uint64_t, 10> Reach;

  bool sameBlock() const;
  // Does `X` execute between the slot and the read (excluding both)?
  bool inSpan(const llvm::Instruction *X) const;
  // May `J` run before `M` on some path through the span? Both in the span, or
  // `M` the read.
  bool mayRunBefore(const llvm::Instruction *J, const llvm::Instruction *M) const;
  // Every instruction that executes between the slot and the read, in an order
  // consistent with every path (the slot and the read excluded).
  void crossed(llvm::SmallVectorImpl<llvm::Instruction *> &Out) const;
};

// The slot and span for the stale read `I` staled by `Stalers` (non-empty), or
// false when no single slot exists per the header (no common dominator slot the
// read post-dominates, a cyclic or open span, a staler outside the span).
bool stalePlacementSpan(llvm::Instruction &I,
                        llvm::ArrayRef<llvm::CallInst *> Stalers,
                        const llvm::DominatorTree &DT,
                        const llvm::PostDominatorTree &PDT, PlacementSpan &S);

// EXACT CFG reachability (batch 053 round-1 F1). LLVM 19's `isPotentiallyReachable`
// family caps its search at 32 blocks (`-dom-tree-reachability-max-bbs-to-explore`)
// and answers "reachable" past the cap, dropping the dominator tree whenever an
// exclusion set is given; a placement legality or a stale grant asked that way
// refuses a valid program once the CFG grows (a long classical tail after the
// read). These walks are linear and uncapped.
// Does a path from some block in `Starts` reach `Target` without entering `Avoid`
// (nullptr: no block avoided)? A start equal to `Target` counts.
bool blockReachesAvoiding(llvm::ArrayRef<const llvm::BasicBlock *> Starts,
                          const llvm::BasicBlock *Target,
                          const llvm::BasicBlock *Avoid);
// May `To` execute after `From` (`isPotentiallyReachable(From, To)` without the
// cap): `From` before `To` in one block, or `To`'s block reachable from a
// successor of `From`'s block.
bool instructionMayReach(const llvm::Instruction *From, const llvm::Instruction *To);

// bd 57ch.4 (the proof a MOVED call needs; a crossed one is asked the ruling
// below, `callTerminationCrossable`): does
// call `CB` provably RETURN NORMALLY? True when LLVM proves it
// (`isGuaranteedToTransferExecutionToSuccessor`: `willreturn` + no unwind), or
// when it is a `nounwind` direct call to a body the linked call runs
// (`calleeBodyTrusted`, AssumeOfLinkedCall) whose CFG is acyclic, whose
// terminators are only `br`/`switch`/`ret`, and whose every instruction returns
// normally by the same test, calls included (memoized; recursion refuses). A
// call that may loop, `exit`, `longjmp` or trap stays unproven.
struct ReturnMemo {
  llvm::DenseMap<const llvm::Function *, bool> Bodies;  // bodyProvablyReturns
  int ModuleReturnsTwice = -1;  // -1 unknown; else whether a returns_twice call exists
};
bool callProvablyReturns(const llvm::CallBase &CB, ReturnMemo &Memo);

// OWNER RULING 2026-10-13 (bd 57ch.4; bd memory owner-ruling-57ch4-maynot-return-
// 2026-10-13): may a placed read be moved ABOVE call `CB`, as far as termination
// goes? Yes when `callProvablyReturns`, or when `CB` is `nounwind` and the module
// holds no `returns_twice` call (no `setjmp`, `__builtin_setjmp`'s
// `llvm.eh.sjlj.setjmp` included): non-return is then `exit` or a hang,
// after which no measurement exists (quantum state cannot reach an atexit handler:
// the taint-escape fence guards globals). An unwinding call, or any call in a module
// with a `returns_twice` landing point (a `longjmp` can resume before later
// measurements, leaving the placed read's copy entangled), stays refused. Asked of
// a CROSSED call only; a MOVED call must still `callProvablyReturns`, since what it
// is moved above would otherwise be skipped. Termination only: the ordered-event
// test (`callCrossable`) is asked on top, so `puts` is still not crossed.
bool callTerminationCrossable(const llvm::CallBase &CB, ReturnMemo &Memo);

}  // namespace cq

#endif  // CQ_IRPASS_STALE_READ_REGION_H_
