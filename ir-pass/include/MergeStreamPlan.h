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
class Instruction;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

struct MergePlan {
  llvm::CallInst *Out = nullptr;
  // The closed emitted stream, inclusive.
  llvm::Instruction *Lo = nullptr, *Hi = nullptr;
  // Classical copy-source loads inside the core: reused, never re-emitted.
  llvm::SmallPtrSet<llvm::Value *, 4> SrcAllocs;
  // Admitted in-place permutations on %out after the stream, program order.
  llvm::SmallVector<llvm::CallInst *, 2> InPlace;
  // First writer .. the closing `cqrt_x` brackets (an involution on %out).
  llvm::SmallVector<llvm::CallInst *, 8> Core;
  // The flag strip after the core, moved to the replay point.
  llvm::SmallVector<llvm::Instruction *, 8> Post;
  // The replay point: %out's last reader (or a whole earlier replay group).
  llvm::Instruction *Last = nullptr;
};


// Recover the closed stream around the merge rail `Out` and prove the replay
// sound (MergeRailDischarge.h, "WHEN THE PROOF HOLDS"). `GroupEnd` maps every
// instruction of an already-emitted replay group to that group's last
// instruction, so a reader inside one is passed by the whole group (LIFO).
// False => leave `Out` allocated; `P` is then meaningless.
bool planMerge(
    llvm::CallInst *Out, const TaintSet &taint,
    const llvm::DenseMap<const llvm::Instruction *, llvm::Instruction *> &GroupEnd,
    MergePlan &P);

}  // namespace cq

#endif  // CQ_IRPASS_MERGE_STREAM_PLAN_H_
