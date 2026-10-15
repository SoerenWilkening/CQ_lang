// MergeStreamPlan.h — the analysis half of `MergeRailDischarge` (bd
// test_C_libtooling-r2j3.32): recover a merge rail's closed emitted stream and
// prove its reverse-replay sound. Pure analysis — it mutates nothing. The
// contract is stated in MergeRailDischarge.h; this header only splits the
// file (CLAUDE.md: maintained files <= 400 lines).

#ifndef CQ_IRPASS_MERGE_STREAM_PLAN_H_
#define CQ_IRPASS_MERGE_STREAM_PLAN_H_

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
class CallInst;
class DominatorTree;
class Instruction;
class LoopInfo;
class PostDominatorTree;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

struct MergePlan {
  llvm::CallInst *Out = nullptr;
  // The closed emitted stream, inclusive (one block).
  llvm::Instruction *Lo = nullptr, *Hi = nullptr;
  // Admitted in-place permutations on %out after the stream, program order.
  llvm::SmallVector<llvm::CallInst *, 2> InPlace;
  // The REPLAYED subsequence of the core, forward order: every write of %out
  // (controlled / uncontrolled basis copies) and the `cqrt_x` brackets on the
  // stream's flags between them. Re-emitted reversed, it is the core's adjoint.
  llvm::SmallVector<llvm::CallInst *, 8> Replay;
  // The flag strip after the core, moved to the replay point.
  llvm::SmallVector<llvm::Instruction *, 8> Post;
  // The group is inserted immediately BEFORE `At` (in the post-dominating
  // block of the stream's single-entry/single-exit region).
  llvm::Instruction *At = nullptr;
  // Non-null when %out is born holding a classical seed (the 4.5 data-mux
  // preload): `cqrt_xorc_<W>(%out, Seed)` returns it to |0> after the replay.
  llvm::Value *Seed = nullptr;
};

struct PlanContext {
  const TaintSet &taint;
  llvm::DominatorTree &DT;
  llvm::PostDominatorTree &PDT;
  llvm::LoopInfo &LI;
  // Every instruction of an already-emitted replay group -> that group's last
  // instruction, so a reader inside one is passed by the whole group (LIFO).
  const llvm::DenseMap<const llvm::Instruction *, llvm::Instruction *> &GroupEnd;
};

// Recover the closed stream around the merge rail `Out` and prove the replay
// sound (MergeRailDischarge.h, "WHEN THE PROOF HOLDS").
// False => leave `Out` allocated; `P` is then meaningless.
bool planMerge(llvm::CallInst *Out, const PlanContext &Ctx, MergePlan &P);

}  // namespace cq

#endif  // CQ_IRPASS_MERGE_STREAM_PLAN_H_
